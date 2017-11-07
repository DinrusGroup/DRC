module dmd.CallExp;

import dmd.common;
import dmd.ErrorExp;
import dmd.Expression;
import dmd.Cast;
import dmd.WANT;
import dmd.BUILTIN;
import dmd.TypeFunction;
import dmd.ScopeDsymbol;
import dmd.CastExp;
import dmd.FuncExp;
import dmd.SymOffExp;
import dmd.GlobalExpressions;
import dmd.TypePointer;
import dmd.ThisExp;
import dmd.OverExp;
import dmd.Dsymbol;
import dmd.CSX;
import dmd.AggregateDeclaration;
import dmd.TypeDelegate;
import dmd.ClassDeclaration;
import dmd.DsymbolExp;
import dmd.DotExp;
import dmd.TemplateExp;
import dmd.TypeStruct;
import dmd.TypeClass;
import dmd.Identifier;
import dmd.Lexer;
import dmd.VarDeclaration;
import dmd.DeclarationExp;
import dmd.CtorDeclaration;
import dmd.PtrExp;
import dmd.TemplateDeclaration;
import dmd.StructLiteralExp;
import dmd.StructDeclaration;
import dmd.DotTemplateExp;
import dmd.CommaExp;
import dmd.AggregateDeclaration;
import dmd.FuncDeclaration;
import dmd.Type;
import dmd.ScopeExp;
import dmd.VarExp;
import dmd.STC;
import dmd.LINK;
import dmd.Global;
import dmd.DotTemplateInstanceExp;
import dmd.TemplateInstance;
import dmd.DelegateExp;
import dmd.IdentifierExp;
import dmd.DotVarExp;
import dmd.DotIdExp;
import dmd.TY;
import dmd.TRUST;
import dmd.Id;
import dmd.TypeAArray;
import dmd.RemoveExp;
import dmd.backend.elem;
import dmd.UnaExp;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.InlineCostState;
import dmd.IRState;
import dmd.InlineDoState;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.ArrayTypes;
import dmd.TOK;
import dmd.PREC;
import dmd.expression.Util;
import dmd.backend.Symbol;
import dmd.backend.TYPE;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.codegen.Util;

import std.stdio;

import dmd.DDMDExtensions;

class CallExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	Expressions arguments;

	this(Loc loc, Expression e, Expressions exps)
	{
		register();

		super(loc, TOK.TOKcall, CallExp.sizeof, e);
		this.arguments = exps;
	}

	this(Loc loc, Expression e)
	{
		register();

		super(loc, TOK.TOKcall, CallExp.sizeof, e);
	}

	this(Loc loc, Expression e, Expression earg1)
	{
		register();

		super(loc, TOK.TOKcall, CallExp.sizeof, e);
		
		auto arguments = new Expressions();
		if (earg1)
		{	
			arguments.setDim(1);
			arguments[0] = earg1;
		}
		this.arguments = arguments;
	}

	this(Loc loc, Expression e, Expression earg1, Expression earg2)
	{
		register();

		super(loc, TOK.TOKcall, CallExp.sizeof, e);
		
		auto arguments = new Expressions();
		arguments.setDim(2);
		arguments[0] = earg1;
		arguments[1] = earg2;

		this.arguments = arguments;
	}

	override Expression syntaxCopy()
	{
		return new CallExp(loc, e1.syntaxCopy(), arraySyntaxCopy(arguments));
	}

	override Expression semantic(Scope sc)
	{
		TypeFunction tf;
		FuncDeclaration f;
		Type t1;
		int istemp;
		Objects targsi;	// initial list of template arguments
		TemplateInstance tierror;

version (LOGSEMANTIC)
{
		printf("CallExp.semantic() %s\n", toChars());
}
		if (type)
			return this;		// semantic() already run

static if (false)
{
		if (arguments && arguments.dim)
		{
			Expression earg = cast(Expression)arguments.data[0];
			earg.print();
			if (earg.type) earg.type.print();
		}
}

		if (e1.op == TOK.TOKdelegate)
		{	
			DelegateExp de = cast(DelegateExp)e1;

			e1 = new DotVarExp(de.loc, de.e1, de.func);
			return semantic(sc);
		}

		/* Transform:
		 *	array.id(args) into .id(array,args)
		 *	aa.remove(arg) into delete aa[arg]
		 */
		if (e1.op == TOK.TOKdot)
		{
			// BUG: we should handle array.a.b.c.e(args) too

			DotIdExp dotid = cast(DotIdExp)(e1);
			dotid.e1 = dotid.e1.semantic(sc);
			assert(dotid.e1);
			if (dotid.e1.type)
			{
				TY e1ty = dotid.e1.type.toBasetype().ty;
				if (e1ty == TY.Taarray && dotid.ident == Id.remove)
				{
					if (!arguments || arguments.dim != 1)
					{  
						error("expected key as argument to aa.remove()");
						goto Lagain;
					}
					auto key = arguments[0];
					key = key.semantic(sc);
					key = resolveProperties(sc, key);
					key.rvalue();

					auto taa = cast(TypeAArray)dotid.e1.type.toBasetype();
					key = key.implicitCastTo(sc, taa.index);

					return new RemoveExp(loc, dotid.e1, key);
				}
				else if (e1ty == TY.Tarray || e1ty == TY.Tsarray ||
				         (e1ty == Taarray && dotid.ident != Id.apply && dotid.ident != Id.applyReverse))
				{
					if (!arguments)
						arguments = new Expressions();
					arguments.shift(dotid.e1);
version (DMDV2) {
					e1 = new DotIdExp(dotid.loc, new IdentifierExp(dotid.loc, Id.empty), dotid.ident);
} else {
					e1 = new IdentifierExp(dotid.loc, dotid.ident);
}
				}
			}
		}

static if (true) {
		/* This recognizes:
		 *	foo!(tiargs)(funcargs)
		 */
		if (e1.op == TOK.TOKimport && !e1.type)
		{	
			ScopeExp se = cast(ScopeExp)e1;
			TemplateInstance ti = se.sds.isTemplateInstance();
			if (ti && !ti.semanticRun)
			{
				/* Attempt to instantiate ti. If that works, go with it.
				 * If not, go with partial explicit specialization.
				 */
				ti.semanticTiargs(sc);
				if (ti.needsTypeInference(sc))
				{
					/* Go with partial explicit specialization
					 */
					targsi = ti.tiargs;
					tierror = ti;			// for error reporting
					e1 = new IdentifierExp(loc, ti.name);
				}
				else
				{
					ti.semantic(sc);
				}
			}
		}

		/* This recognizes:
		 *	expr.foo!(tiargs)(funcargs)
		 */
Ldotti:
		if (e1.op == TOK.TOKdotti && !e1.type)
		{	
			DotTemplateInstanceExp se = cast(DotTemplateInstanceExp)e1;
			TemplateInstance ti = se.ti;
			if (!ti.semanticRun)
			{
				/* Attempt to instantiate ti. If that works, go with it.
				 * If not, go with partial explicit specialization.
				 */
				ti.semanticTiargs(sc);
static if (false) {
				Expression etmp = e1.trySemantic(sc);
				if (etmp)
					e1 = etmp;	// it worked
				else		// didn't work
				{
					targsi = ti.tiargs;
					tierror = ti;		// for error reporting
					e1 = new DotIdExp(loc, se.e1, ti.name);
				}
} else {
				if (!ti.tempdecl)
				{
					se.getTempdecl(sc);
				}
				if (ti.tempdecl && ti.needsTypeInference(sc))
				{
				/* Go with partial explicit specialization
				 */
					targsi = ti.tiargs;
					tierror = ti;			// for error reporting
					e1 = new DotIdExp(loc, se.e1, ti.name);
				}
				else
				{
					e1 = e1.semantic(sc);
				}
}
			}
		}
}

		istemp = 0;
	Lagain:
		//printf("Lagain: %s\n", toChars());
		f = null;
		if (e1.op == TOK.TOKthis || e1.op == TOK.TOKsuper)
		{
			// semantic() run later for these
		}
		else
		{
			if (e1.op == TOK.TOKdot)
			{
				auto die = cast(DotIdExp)e1;
				e1 = die.semantic(sc, 1);
				/* Look for e1 having been rewritten to expr.opDispatch!(string)
				 * We handle such earlier, so go back.
				 * Note that in the rewrite, we carefully did not run semantic() on e1
				 */
				if (e1.op == TOK.TOKdotti && !e1.type)
				{
					goto Ldotti;
				}
			}
			else
				UnaExp.semantic(sc);

			/* Look for e1 being a lazy parameter
			 */
			if (e1.op == TOK.TOKvar)
			{   
				VarExp ve = cast(VarExp)e1;

				if (ve.var.storage_class & STC.STClazy)
				{
					TypeFunction tff = new TypeFunction(null, ve.var.type, 0, LINK.LINKd);
					TypeDelegate t = new TypeDelegate(tff);
					ve.type = t.semantic(loc, sc);
				}
			}

			if (e1.op == TOK.TOKimport)
			{   
				// Perhaps this should be moved to ScopeExp.semantic()
				ScopeExp se = cast(ScopeExp)e1;
				e1 = new DsymbolExp(loc, se.sds);
				e1 = e1.semantic(sc);
			}
///static if (true) {	// patch for #540 by Oskar Linde
			else if (e1.op == TOK.TOKdotexp)
			{
				DotExp de = cast(DotExp)e1;

				if (de.e2.op == TOK.TOKimport)
				{   
					// This should *really* be moved to ScopeExp.semantic()
					ScopeExp se = cast(ScopeExp)de.e2;
					de.e2 = new DsymbolExp(loc, se.sds);
					de.e2 = de.e2.semantic(sc);
				}

				if (de.e2.op == TOK.TOKtemplate)
				{   
					TemplateExp te = cast(TemplateExp)de.e2;
					e1 = new DotTemplateExp(loc,de.e1,te.td);
				}
			}
///}
		}

		if (e1.op == TOK.TOKcomma)
		{
			CommaExp ce = cast(CommaExp)e1;

			e1 = ce.e2;
			e1.type = ce.type;
			ce.e2 = this;
			ce.type = null;
			return ce.semantic(sc);
		}

		t1 = null;
		if (e1.type)
		t1 = e1.type.toBasetype();

		// Check for call operator overload
		if (t1)
		{	
			AggregateDeclaration ad;

			if (t1.ty == TY.Tstruct)
			{
				ad = (cast(TypeStruct)t1).sym;
version (DMDV2) {
				// First look for constructor
				if (ad.ctor && arguments && arguments.dim)
				{
					// Create variable that will get constructed
					Identifier idtmp = Lexer.uniqueId("__ctmp");
					VarDeclaration tmp = new VarDeclaration(loc, t1, idtmp, null);
					tmp.storage_class |= STCctfe;		
					Expression av = new DeclarationExp(loc, tmp);
					av = new CommaExp(loc, av, new VarExp(loc, tmp));

					Expression e;
					CtorDeclaration cf = ad.ctor.isCtorDeclaration();
					if (cf)
						e = new DotVarExp(loc, av, cf, 1);
					else
					{   
						TemplateDeclaration td = ad.ctor.isTemplateDeclaration();
						assert(td);
						e = new DotTemplateExp(loc, av, td);
					}
					e = new CallExp(loc, e, arguments);
			version (STRUCTTHISREF) {
			} else {
					/* Constructors return a pointer to the instance
					 */
					e = new PtrExp(loc, e);
			}
					e = e.semantic(sc);
					return e;
				}
}
				// No constructor, look for overload of opCall
				if (search_function(ad, Id.call))
					goto L1;	// overload of opCall, therefore it's a call

				if (e1.op != TOK.TOKtype)
					error("%s %s does not overload ()", ad.kind(), ad.toChars());
				
				/* It's a struct literal
				 */
				Expression e = new StructLiteralExp(loc, cast(StructDeclaration)ad, arguments);
				e = e.semantic(sc);
				e.type = e1.type;		// in case e1.type was a typedef
				return e;
			}
			else if (t1.ty == TY.Tclass)
			{
				ad = (cast(TypeClass)t1).sym;
				goto L1;
			L1:
				// Rewrite as e1.call(arguments)
				Expression e = new DotIdExp(loc, e1, Id.call);
				e = new CallExp(loc, e, arguments);
				e = e.semantic(sc);
				return e;
			}
		}

		arrayExpressionSemantic(arguments, sc);
		preFunctionParameters(loc, sc, arguments);

		if (e1.op == TOK.TOKdotvar && t1.ty == TY.Tfunction ||
			e1.op == TOK.TOKdottd)
		{
			DotVarExp dve;
			DotTemplateExp dte;
			AggregateDeclaration ad;
			UnaExp ue = cast(UnaExp)e1;

			if (e1.op == TOK.TOKdotvar)
			{   
				// Do overload resolution
				dve = cast(DotVarExp)e1;

				f = dve.var.isFuncDeclaration();
				assert(f);
				f = f.overloadResolve(loc, ue.e1, arguments);

				ad = f.toParent().isAggregateDeclaration();
			}
			else
			{   
				dte = cast(DotTemplateExp)e1;
				TemplateDeclaration td = dte.td;
				assert(td);

				if (!arguments)
					// Should fix deduceFunctionTemplate() so it works on null argument
					arguments = new Expressions();

				f = td.deduceFunctionTemplate(sc, loc, targsi, ue.e1, arguments);
				if (!f)
				{	
					type = Type.terror;
					return this;
				}
				ad = td.toParent().isAggregateDeclaration();
			}

			if (f.needThis())
			{
				ue.e1 = getRightThis(loc, sc, ad, ue.e1, f);
			}

			/* Cannot call public functions from inside invariant
			 * (because then the invariant would have infinite recursion)
			 */
			if (sc.func && sc.func.isInvariantDeclaration() &&
				ue.e1.op == TOK.TOKthis && f.addPostInvariant())
			{
				error("cannot call public/export function %s from invariant", f.toChars());
			}

			checkDeprecated(sc, f);
	version (DMDV2) {
			checkPurity(sc, f);
			checkSafety(sc, f);
	}
			accessCheck(loc, sc, ue.e1, f);
			if (!f.needThis())
			{
				VarExp ve = new VarExp(loc, f);
				e1 = new CommaExp(loc, ue.e1, ve);
				e1.type = f.type;
			}
			else
			{
				if (e1.op == TOK.TOKdotvar)		
					dve.var = f;
				else
					e1 = new DotVarExp(loc, dte.e1, f);

				e1.type = f.type;
static if (false) {
				printf("ue.e1 = %s\n", ue.e1.toChars());
				printf("f = %s\n", f.toChars());
				printf("t = %s\n", t.toChars());
				printf("e1 = %s\n", e1.toChars());
				printf("e1.type = %s\n", e1.type.toChars());
}
				// Const member function can take const/immutable/mutable/inout this
				if (!(f.type.isConst()))
				{
					// Check for const/immutable compatibility
					Type tthis = ue.e1.type.toBasetype();
					if (tthis.ty == TY.Tpointer)
						tthis = tthis.nextOf().toBasetype();

	static if (false) {	// this checking should have been already done
					if (f.type.isImmutable())
					{
						if (tthis.mod != MOD.MODimmutable)
							error("%s can only be called with an immutable object", e1.toChars());
					}
					else if (f.type.isShared())
					{
						if (tthis.mod != MOD.MODimmutable && tthis.mod != MOD.MODshared && tthis.mod != (MOD.MODshared | MOD.MODconst))
							error("shared %s can only be called with a shared or immutable object", e1.toChars());
					}
					else
					{
						if (tthis.mod != MOD.MODundefined)
						{	
							//printf("mod = %x\n", tthis.mod);
							error("%s can only be called with a mutable object, not %s", e1.toChars(), tthis.toChars());
						}
					}
	}
					/* Cannot call mutable method on a final struct
					 */
					if (tthis.ty == TY.Tstruct &&
						ue.e1.op == TOK.TOKvar)
					{
						VarExp v = cast(VarExp)ue.e1;
						if (v.var.storage_class & STC.STCfinal)
							error("cannot call mutable method on final struct");
					}
				}

				// See if we need to adjust the 'this' pointer
				AggregateDeclaration add = f.isThis();
				ClassDeclaration cd = ue.e1.type.isClassHandle();
				if (add && cd && add.isClassDeclaration() && add != cd && ue.e1.op != TOK.TOKsuper)
				{
					ue.e1 = ue.e1.castTo(sc, add.type); //new CastExp(loc, ue.e1, add.type);
					ue.e1 = ue.e1.semantic(sc);
				}
			}
			t1 = e1.type;
		}
		else if (e1.op == TOK.TOKsuper)
		{
			// Base class constructor call
			ClassDeclaration cd = null;

			if (sc.func)
				cd = sc.func.toParent().isClassDeclaration();
			if (!cd || !cd.baseClass || !sc.func.isCtorDeclaration())
			{
				error("super class constructor call must be in a constructor");
				type = Type.terror;
				return this;
			}
			else
			{
				if (!cd.baseClass.ctor)
				{	
					error("no super class constructor for %s", cd.baseClass.toChars());
					type = Type.terror;
					return this;
				}
				else
				{
					if (!sc.intypeof)
					{
static if (false) {
						if (sc.callSuper & (CSX.CSXthis | CSX.CSXsuper))
							error("reference to this before super()");
}
						if (sc.noctor || sc.callSuper & CSX.CSXlabel)
							error("constructor calls not allowed in loops or after labels");
						if (sc.callSuper & (CSX.CSXsuper_ctor | CSX.CSXthis_ctor))
							error("multiple constructor calls");
						sc.callSuper |= CSX.CSXany_ctor | CSX.CSXsuper_ctor;
					}

					f = resolveFuncCall(sc, loc, cd.baseClass.ctor, null, null, arguments, 0);
					checkDeprecated(sc, f);
version (DMDV2) {
					checkPurity(sc, f);
					checkSafety(sc, f);
}
					e1 = new DotVarExp(e1.loc, e1, f);
					e1 = e1.semantic(sc);
					t1 = e1.type;
				}
			}
		}
		else if (e1.op == TOK.TOKthis)
		{
			// same class constructor call
			AggregateDeclaration cd = null;

			if (sc.func)
				cd = sc.func.toParent().isAggregateDeclaration();
			if (!cd || !sc.func.isCtorDeclaration())
			{
				error("constructor call must be in a constructor");
				type = Type.terror;
				return this;
			}
			else
			{
				if (!sc.intypeof)
				{
static if (false) {
					if (sc.callSuper & (CSXthis | CSXsuper))
						error("reference to this before super()");
}
					if (sc.noctor || sc.callSuper & CSX.CSXlabel)
						error("constructor calls not allowed in loops or after labels");
					if (sc.callSuper & (CSX.CSXsuper_ctor | CSX.CSXthis_ctor))
						error("multiple constructor calls");
					sc.callSuper |= CSX.CSXany_ctor | CSX.CSXthis_ctor;
				}

				f = resolveFuncCall(sc, loc, cd.ctor, null, null, arguments, 0);
				checkDeprecated(sc, f);
version (DMDV2) {
				checkPurity(sc, f);
				checkSafety(sc, f);
}
				e1 = new DotVarExp(e1.loc, e1, f);
				e1 = e1.semantic(sc);
				t1 = e1.type;

				// BUG: this should really be done by checking the static
				// call graph
				if (f == sc.func)
					error("cyclic constructor call");
			}
		}
		else if (e1.op == TOK.TOKoverloadset)
		{
			OverExp eo = cast(OverExp)e1;
			FuncDeclaration ff = null;
			Dsymbol s = null;
			for(size_t i = 0; i<eo.vars.a.dim; i++)
			{
				s = eo.vars.a[i];
				FuncDeclaration f2 = s.isFuncDeclaration();
				if (f2)
				{
					f2 = f2.overloadResolve(loc, null, arguments, 1);
				}
				else
				{	
					TemplateDeclaration td = s.isTemplateDeclaration();
					assert(td);
					f2 = td.deduceFunctionTemplate(sc, loc, targsi, null, arguments, 1);
				}
				if (f2)
				{	
					if (ff)
						/* Error if match in more than one overload set,
						 * even if one is a 'better' match than the other.
						 */
						ScopeDsymbol.multiplyDefined(loc, ff, f2);
					else
						ff = f2;
				}
			}
			if (!ff)
			{
				// No overload matches
				error("no overload matches for %s", s.toChars());
				return new ErrorExp();
			}
			e1 = new VarExp(loc, ff);
			goto Lagain;
		}
		else if (!t1)
		{
			error("function expected before (), not '%s'", e1.toChars());
			type = Type.terror;
			return this;
		}
		else if (t1.ty != TY.Tfunction)
		{
			if (t1.ty == TY.Tdelegate)
			{   
				TypeDelegate td = cast(TypeDelegate)t1;
				assert(td.next.ty == TY.Tfunction);
				tf = cast(TypeFunction)(td.next);
				if (sc.func && sc.func.isPure() && !tf.ispure)
				{
					error("pure function '%s' cannot call impure delegate '%s'", sc.func.toChars(), e1.toChars());
				}
				if (sc.func && sc.func.isSafe() && tf.trust <= TRUST.TRUSTsystem)
				{
					error("safe function '%s' cannot call system delegate '%s'", sc.func.toChars(), e1.toChars());
				}
				goto Lcheckargs;
			}
			else if (t1.ty == TY.Tpointer && (cast(TypePointer)t1).next.ty == TY.Tfunction)
			{   
				Expression e = new PtrExp(loc, e1);
				t1 = (cast(TypePointer)t1).next;
				if (sc.func && sc.func.isPure() && !(cast(TypeFunction)t1).ispure)
				{
					error("pure function '%s' cannot call impure function pointer '%s'", sc.func.toChars(), e1.toChars());
				}
				if (sc.func && sc.func.isSafe() && !(cast(TypeFunction)t1).trust <= TRUST.TRUSTsystem)
				{
					error("safe function '%s' cannot call system function pointer '%s'", sc.func.toChars(), e1.toChars());
				}
				e.type = t1;
				e1 = e;
			}
			else if (e1.op == TOK.TOKtemplate)
			{
				TemplateExp te = cast(TemplateExp)e1;
				f = te.td.deduceFunctionTemplate(sc, loc, targsi, null, arguments);
				if (!f)
				{	
					if (tierror)
						tierror.error("errors instantiating template");	// give better error message
					type = Type.terror;
					return this;
				}
				if (f.needThis() && hasThis(sc))
				{
					// Supply an implicit 'this', as in
					//	  this.ident

					e1 = new DotTemplateExp(loc, (new ThisExp(loc)).semantic(sc), te.td);
					goto Lagain;
				}

				e1 = new VarExp(loc, f);
				goto Lagain;
			}
			else
			{   
				error("function expected before (), not %s of type %s", e1.toChars(), e1.type.toChars());
				return new ErrorExp();
			}
		}
		else if (e1.op == TOK.TOKvar)
		{
			// Do overload resolution
			VarExp ve = cast(VarExp)e1;

			f = ve.var.isFuncDeclaration();
			assert(f);

			if (ve.hasOverloads)
				f = f.overloadResolve(loc, null, arguments);

			checkDeprecated(sc, f);
version (DMDV2) {
			checkPurity(sc, f);
			checkSafety(sc, f);
}

			if (f.needThis() && hasThis(sc))
			{
				// Supply an implicit 'this', as in
				//	  this.ident

				e1 = new DotVarExp(loc, new ThisExp(loc), f);
				goto Lagain;
			}

			accessCheck(loc, sc, null, f);

			ve.var = f;
		//	ve.hasOverloads = false;
			ve.type = f.type;
			t1 = f.type;
		}
		assert(t1.ty == TY.Tfunction);
		tf = cast(TypeFunction)t1;

	Lcheckargs:
		assert(tf.ty == TY.Tfunction);

		if (!arguments)
			arguments = new Expressions();

		type = functionParameters(loc, sc, tf, arguments);

		if (!type)
		{
			error("forward reference to inferred return type of function call %s", toChars());
			type = Type.terror;
		}

		if (f && f.tintro)
		{
			Type t = type;
			int offset = 0;
			TypeFunction tff = cast(TypeFunction)f.tintro;

			if (tff.next.isBaseOf(t, &offset) && offset)
			{
				type = tff.next;
				return castTo(sc, t);
			}
		}

		return this;
	}

	override Expression optimize(int result)
	{
		// writef("CallExp::optimize(result = %d) %s\n", result, toChars());
		Expression e = this;

		// Optimize parameters
		if (arguments)
		{
			foreach (ref Expression ee; arguments)
			{   
				ee = ee.optimize(WANT.WANTvalue);
			}
		}

		e1 = e1.optimize(result);
static if (true) {
		if (result & WANTinterpret)
		{
			Expression eresult = interpret(null);
			if (eresult is EXP_CANT_INTERPRET)
				return e;
			if (eresult && eresult !is EXP_VOID_INTERPRET)
				e = eresult;
			else
				error("cannot evaluate %s at compile time", toChars());
		}
} else {
		if (e1.op == TOK.TOKvar)
		{
			FuncDeclaration fd = (cast(VarExp)e1).var.isFuncDeclaration();
			if (fd)
			{
				BUILTIN b = fd.isBuiltin();
				if (b)
				{
					e = eval_builtin(b, arguments);
					if (!e)			// failed
						e = this;		// evaluate at runtime
				}
				else if (result & WANT.WANTinterpret)
				{
					Expression eresult = fd.interpret(null, arguments);
					if (eresult && eresult !is EXP_VOID_INTERPRET)
						e = eresult;
					else
						error("cannot evaluate %s at compile time", toChars());
				}
			}
		}
		else if (e1.op == TOKdotvar && result & WANTinterpret)
		{
			DotVarExp dve = cast(DotVarExp) e1;
			FuncDeclaration fd = dve.var.isFuncDeclaration();
			if (fd)
			{
				Expression eresult = fd.interpret(null, arguments, dve.e1);
				if (eresult && eresult != EXP_VOID_INTERPRET)
					e = eresult;
				else
					error("cannot evaluate %s at compile time", toChars());
			}
		}
}
		return e;
	}

	override Expression interpret(InterState istate)
	{
		Expression e = EXP_CANT_INTERPRET;

version (LOG) {
		printf("CallExp.interpret() %.*s\n", toChars());
}
		Expression pthis = null; 
		FuncDeclaration fd = null;
		Expression ecall = e1;
		if (ecall.op == TOKindex)
			ecall = e1.interpret(istate);
		if (ecall.op == TOKdotvar && !(cast(DotVarExp)ecall).var.isFuncDeclaration())
			ecall = e1.interpret(istate);
	   
		if (ecall.op == TOKdotvar)
		{   // Calling a member function    
			pthis = (cast(DotVarExp)e1).e1;
			fd = (cast(DotVarExp)e1).var.isFuncDeclaration();
		}
		else if (ecall.op == TOKvar)
		{
			VarDeclaration vd = (cast(VarExp)ecall).var.isVarDeclaration();
			if (vd && vd.value) 
				ecall = vd.value;
			else // Calling a function
				fd = (cast(VarExp)e1).var.isFuncDeclaration();
		}    
		if (ecall.op == TOKdelegate)
		{   
			// Calling a delegate
			fd = (cast(DelegateExp)ecall).func;
			pthis = (cast(DelegateExp)ecall).e1;
		}
		else if (ecall.op == TOKfunction)
		{	// Calling a delegate literal
			fd = (cast(FuncExp)ecall).fd;
		}
		else if (ecall.op == TOKstar && (cast(PtrExp)ecall).e1.op == TOKfunction)
		{	// Calling a function literal
			fd = (cast(FuncExp)(cast(PtrExp)ecall).e1).fd;
		}	
		else if (ecall.op == TOKstar && (cast(PtrExp*)ecall).e1.op==TOKvar)
		{	// Calling a function pointer
			VarDeclaration vd = (cast(VarExp)(cast(PtrExp*)ecall).e1).var.isVarDeclaration();
			if (vd && vd.value && vd.value.op == TOKsymoff) 
				fd = (cast(SymOffExp)vd.value).var.isFuncDeclaration();
		}

		TypeFunction tf = fd ? cast(TypeFunction)(fd.type) : null;
		if (!tf)
		{   
			// DAC: I'm not sure if this ever happens
			//printf("ecall=%s %d %d\n", ecall->toChars(), ecall->op, TOKcall);
			error("cannot evaluate %s at compile time", toChars());
			return EXP_CANT_INTERPRET;
		}
		if (pthis && fd)
		{   
			// Member function call
			if (pthis.op == TOKthis)
				pthis = istate.localThis;
			else if (pthis.op == TOKcomma)
				pthis = pthis.interpret(istate);
			Expression eresult = fd.interpret(istate, arguments, pthis);
			if (eresult)
				e = eresult;
			else if (fd.type.toBasetype().nextOf().ty == Tvoid && !global.errors)
				e = EXP_VOID_INTERPRET;
			else
				error("cannot evaluate %s at compile time", toChars());
			return e;
		}
		else if (fd)
		{    // function call

///version (DMDV2) {
			BUILTIN b = fd.isBuiltin();
			if (b)
			{	
				scope Expressions args = new Expressions();
				args.setDim(arguments.dim);
				for (size_t i = 0; i < args.dim; i++)
				{
					auto earg = arguments[i];
					earg = earg.interpret(istate);
					if (earg == EXP_CANT_INTERPRET)
						return earg;
					args[i] = earg;
				}
				e = eval_builtin(b, args);
				if (!e)
					e = EXP_CANT_INTERPRET;
			}
			else
///}
			// Inline .dup
			if (fd.ident == Id.adDup && arguments && arguments.dim == 2)
			{
				e = arguments[1];
				e = e.interpret(istate);
				if (e !is EXP_CANT_INTERPRET)
				{
					e = expType(type, e);
				}
			}
			else
			{
				Expression eresult = fd.interpret(istate, arguments);
				if (eresult)
					e = eresult;
				else if (fd.type.toBasetype().nextOf().ty == Tvoid && !global.errors)
					e = EXP_VOID_INTERPRET;
				else
					error("cannot evaluate %s at compile time", toChars());
			}
		}
		else
		{
			error("cannot evaluate %s at compile time", toChars());
			return EXP_CANT_INTERPRET;
		}

		return e;
	}

	override bool checkSideEffect(int flag)
	{
version (DMDV2) {
		if (flag != 2)
			return true;

		if (e1.checkSideEffect(2))
			return true;

		/* If any of the arguments have side effects, this expression does
		 */
		foreach (e; arguments)
		{   
			if (e.checkSideEffect(2))
				return true;
		}

		/* If calling a function or delegate that is typed as pure,
		 * then this expression has no side effects.
		 */
		Type t = e1.type.toBasetype();
		if (t.ty == TY.Tfunction && (cast(TypeFunction)t).ispure)
			return false;
		if (t.ty == TY.Tdelegate && (cast(TypeFunction)(cast(TypeDelegate)t).next).ispure)
			return false;
}
		return true;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		int i;
		expToCBuffer(buf, hgs, e1, precedence[op]);
		buf.writeByte('(');
		argsToCBuffer(buf, arguments, hgs);
		buf.writeByte(')');
	}

	override void dump(int indent)
	{
		assert(false);
	}

	override elem* toElem(IRState* irs)
	{
		//printf("CallExp::toElem('%s')\n", toChars());
		assert(e1.type);
		elem* ec;
		int directcall;
		FuncDeclaration fd;
		Type t1 = e1.type.toBasetype();
		Type ectype = t1;

		elem* ehidden = irs.ehidden;
		irs.ehidden = null;

		directcall = 0;
		fd = null;
		if (e1.op == TOK.TOKdotvar && t1.ty != TY.Tdelegate)
		{	
			DotVarExp dve = cast(DotVarExp)e1;

			fd = dve.var.isFuncDeclaration();
			Expression ex = dve.e1;
			while (1)
			{
				switch (ex.op)
				{
				case TOK.TOKsuper:		// super.member() calls directly
				case TOK.TOKdottype:	// type.member() calls directly
					directcall = 1;
					break;

				case TOK.TOKcast:
					ex = (cast(CastExp)ex).e1;
					continue;

				default:
					//ex.dump(0);
					break;
				}
				break;
			}
			ec = dve.e1.toElem(irs);
			ectype = dve.e1.type.toBasetype();
		}
		else if (e1.op == TOK.TOKvar)
		{
			fd = (cast(VarExp)e1).var.isFuncDeclaration();

			if (fd && fd.ident == Id.alloca && !fd.fbody && fd.linkage == LINK.LINKc && arguments && arguments.dim == 1)
			{   
				auto arg = arguments[0];
				arg = arg.optimize(WANT.WANTvalue);
				if (arg.isConst() && arg.type.isintegral())
				{	
					long sz = arg.toInteger();
					if (sz > 0 && sz < 0x40000)
					{
						// It's an alloca(sz) of a fixed amount.
						// Replace with an array allocated on the stack
						// of the same size: char[sz] tmp;

						Symbol* stmp;
						.type* t;

						assert(!ehidden);
						t = type_allocn(TYM.TYarray, tschar);
						t.Tdim = cast(uint)sz;
						stmp = symbol_genauto(t);
						ec = el_ptr(stmp);
						el_setLoc(ec,loc);
						return ec;
					}
				}
			}

			ec = e1.toElem(irs);
		}
		else
		{
			ec = e1.toElem(irs);
		}
		ec = callfunc(loc, irs, directcall, type, ec, ectype, fd, t1, ehidden, arguments);
		el_setLoc(ec,loc);
		return ec;
	}

	override void scanForNestedRef(Scope sc)
	{
		//printf("CallExp.scanForNestedRef(Scope *sc): %s\n", toChars());
		e1.scanForNestedRef(sc);
		arrayExpressionScanForNestedRef(sc, arguments);
	}
	
version (DMDV2) {
	override bool isLvalue()
	{
		//	if (type.toBasetype().ty == Tstruct)
		//	return 1;
		Type tb = e1.type.toBasetype();
		if (tb.ty == Tfunction && (cast(TypeFunction)tb).isref)
			return true;		// function returns a reference
		return false;
	}
}
	override Expression toLvalue(Scope sc, Expression e)
	{
		if (isLvalue())
			return this;
		return Expression.toLvalue(sc, e);
	}

version (DMDV2) {
	override bool canThrow()
	{
		//printf("CallExp::canThrow() %s\n", toChars());
		if (e1.canThrow())
			return true;

		/* If any of the arguments can throw, then this expression can throw
		 */
		foreach (e; arguments)
		{   
			if (e && e.canThrow())
				return true;
		}

		if (global.errors && !e1.type)
			return false;			// error recovery

		/* If calling a function or delegate that is typed as nothrow,
		 * then this expression cannot throw.
		 * Note that pure functions can throw.
		 */
		Type t = e1.type.toBasetype();
		if (t.ty == TY.Tfunction && (cast(TypeFunction)t).isnothrow)
			return false;
		if (t.ty == TY.Tdelegate && (cast(TypeFunction)(cast(TypeDelegate)t).next).isnothrow)
			return false;

		return true;
	}
}
	override int inlineCost(InlineCostState* ics)
	{
		return 1 + e1.inlineCost(ics) + arrayInlineCost(ics, arguments);
	}

	override Expression doInline(InlineDoState ids)
	{
		CallExp ce = cast(CallExp)copy();
		ce.e1 = e1.doInline(ids);
		ce.arguments = arrayExpressiondoInline(arguments, ids);
		return ce;
	}

	override Expression inlineScan(InlineScanState* iss)
	{
		Expression e = this;

		//printf("CallExp.inlineScan()\n");
		e1 = e1.inlineScan(iss);
		arrayInlineScan(iss, arguments);

		if (e1.op == TOKvar)
		{
			VarExp ve = cast(VarExp)e1;
			FuncDeclaration fd = ve.var.isFuncDeclaration();

			if (fd && fd != iss.fd && fd.canInline(0))
			{
				e = fd.doInline(iss, null, arguments);
			}
		}
		else if (e1.op == TOKdotvar)
		{
			DotVarExp dve = cast(DotVarExp)e1;
			FuncDeclaration fd = dve.var.isFuncDeclaration();

			if (fd && fd != iss.fd && fd.canInline(1))
			{
				if (dve.e1.op == TOKcall &&
					dve.e1.type.toBasetype().ty == Tstruct)
				{
					/* To create ethis, we'll need to take the address
					 * of dve.e1, but this won't work if dve.e1 is
					 * a function call.
					 */
					//;
				}
				else
					e = fd.doInline(iss, dve.e1, arguments);
			}
		}

		return e;
	}
}

