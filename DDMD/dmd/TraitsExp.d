module dmd.TraitsExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.ArrayTypes;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.TY;
import dmd.STC;
import dmd.WANT;
import dmd.Id;
import dmd.Global;
import dmd.Lexer;
import dmd.ArrayLiteralExp;
import dmd.VarExp;
import dmd.StringExp;
import dmd.DotIdExp;
import dmd.DotVarExp;
import dmd.IntegerExp;
import dmd.TupleExp;
import dmd.Type;
import dmd.Dsymbol;
import dmd.DsymbolExp;
import dmd.ScopeDsymbol;
import dmd.FuncDeclaration;
import dmd.ClassDeclaration;
import dmd.TemplateDeclaration;
import dmd.TemplateInstance;
import dmd.TypeClass;
import dmd.Declaration;
import dmd.Util;
import dmd.expression.Util;

import core.stdc.string : strcmp;

import dmd.DDMDExtensions;

/************************************************
 * Delegate to be passed to overloadApply() that looks
 * for functions matching a trait.
 */

struct Ptrait
{
	Expression e1;
	Expressions exps;		// collected results
	Identifier ident;		// which trait we're looking for
	
	bool visit(FuncDeclaration f)
	{
		if (ident == Id.getVirtualFunctions && !f.isVirtual())
			return false;

		Expression e;

		if (e1.op == TOKdotvar)
		{   
			DotVarExp dve = cast(DotVarExp)e1;
			e = new DotVarExp(Loc(0), dve.e1, f);
		}
		else
			e = new DsymbolExp(Loc(0), f);
		exps.push(e);

		return false;
	}
}

class TraitsExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Identifier ident;

	Objects args;

	this(Loc loc, Identifier ident, Objects args)
	{
		register();
		super(loc, TOK.TOKtraits, this.sizeof);
		this.ident = ident;
		this.args = args;
	}

	override Expression syntaxCopy()
	{
		return new TraitsExp(loc, ident, TemplateInstance.arraySyntaxCopy(args));
	}

	override Expression semantic(Scope sc)
	{
		version (LOGSEMANTIC) {
			printf("TraitsExp.semantic() %s\n", toChars());
		}
		if (ident != Id.compiles && ident != Id.isSame)
			TemplateInstance.semanticTiargs(loc, sc, args, 1);
		size_t dim = args ? args.dim : 0;
        Declaration d;
		FuncDeclaration f;

		string ISTYPE(string cond)
		{
			return `
				for (size_t i = 0; i < dim; i++)
				{   Type t = getType(args[i]);
					if (!t)
						goto Lfalse;
					if (!(`~cond~`))
						goto Lfalse;
				}
			if (!dim)
				goto Lfalse;
			goto Ltrue;
			`;
		}

		string ISDSYMBOL(string cond)
		{
			return `for (size_t i = 0; i < dim; i++)
			{   Dsymbol s = getDsymbol(args[i]);
				if (!s)
					goto Lfalse;
				if (!(`~cond~`))
					goto Lfalse;
			}
			if (!dim)
				goto Lfalse;
			goto Ltrue;`;
		}

		if (ident == Id.isArithmetic)
		{
			mixin(ISTYPE(`t.isintegral() || t.isfloating()`));
		}
		else if (ident == Id.isFloating)
		{
			mixin(ISTYPE(q{t.isfloating()}));
		}
		else if (ident == Id.isIntegral)
		{
			mixin(ISTYPE(q{t.isintegral()}));
		}
		else if (ident == Id.isScalar)
		{
			mixin(ISTYPE(q{t.isscalar()}));
		}
		else if (ident == Id.isUnsigned)
		{
			mixin(ISTYPE(q{t.isunsigned()}));
		}
		else if (ident == Id.isAssociativeArray)
		{
			mixin(ISTYPE(q{t.toBasetype().ty == TY.Taarray}));
		}
		else if (ident == Id.isStaticArray)
		{
			mixin(ISTYPE(q{t.toBasetype().ty == TY.Tsarray}));
		}
		else if (ident == Id.isAbstractClass)
		{
			mixin(ISTYPE(q{t.toBasetype().ty == TY.Tclass && (cast(TypeClass)t.toBasetype()).sym.isAbstract()}));
		}
		else if (ident == Id.isFinalClass)
		{
			mixin(ISTYPE(q{t.toBasetype().ty == TY.Tclass && (cast(TypeClass)t.toBasetype()).sym.storage_class & STC.STCfinal}));
		}
		else if (ident == Id.isAbstractFunction)
		{
			mixin(ISDSYMBOL(q{(f = s.isFuncDeclaration()) !is null && f.isAbstract()}));
		}
		else if (ident == Id.isVirtualFunction)
		{
			mixin(ISDSYMBOL(q{(f = s.isFuncDeclaration()) !is null && f.isVirtual()}));
		}
		else if (ident == Id.isFinalFunction)
		{
			mixin(ISDSYMBOL(q{(f = s.isFuncDeclaration()) !is null && f.isFinal()}));
		}
//version(DMDV2) {
	    else if (ident == Id.isStaticFunction)
		{
			mixin(ISDSYMBOL(q{(f = s.isFuncDeclaration()) !is null && !f.needThis()}));
		}
        else if (ident == Id.isRef)
        {
	        mixin(ISDSYMBOL(q{(d = s.isDeclaration()) !is null && d.isRef()}));
        }
        else if (ident == Id.isOut)
        {
            mixin(ISDSYMBOL(q{(d = s.isDeclaration()) !is null && d.isOut()}));
        }
        else if (ident == Id.isLazy)
        {
	        mixin(ISDSYMBOL(q{(d = s.isDeclaration()) !is null && d.storage_class & STClazy}));
        }
		else if (ident == Id.identifier)
		{	
			// Get identifier for symbol as a string literal
			if (dim != 1)
				goto Ldimerror;
			auto o = args[0];
			Dsymbol s = getDsymbol(o);
			if (!s || !s.ident)
			{
				error("argument %s has no identifier", ident.toChars());	///< CHANGED o to ident!!!
				goto Lfalse;
			}
			StringExp se = new StringExp(loc, s.ident.toChars());
			return se.semantic(sc);
		}
//}
		else if (ident == Id.hasMember ||
				ident == Id.getMember ||
			    ident == Id.getOverloads ||
				ident == Id.getVirtualFunctions)
		{
			if (dim != 2)
				goto Ldimerror;
			auto o = args[0];
			Expression e = isExpression(args[1]);
			if (!e)
			{   error("expression expected as second argument of __traits %s", ident.toChars());
				goto Lfalse;
			}
			e = e.optimize(WANT.WANTvalue | WANT.WANTinterpret);
			if (e.op != TOKstring)
			{   error("string expected as second argument of __traits %s instead of %s", ident.toChars(), e.toChars());
				goto Lfalse;
			}
			auto se = cast(StringExp)e;
			se = se.toUTF8(sc);
			if (se.sz != 1)
			{   error("string must be chars");
				goto Lfalse;
			}
			Identifier id = Lexer.idPool(fromStringz(cast(char*)se.string_));

			Type t = isType(o);
			e = isExpression(o);
			Dsymbol s = isDsymbol(o);
			if (t)
				e = typeDotIdExp(loc, t, id);
			else if (e)
				e = new DotIdExp(loc, e, id);
			else if (s)
			{   e = new DsymbolExp(loc, s);
				e = new DotIdExp(loc, e, id);
			}
			else
			{   error("invalid first argument");
				goto Lfalse;
			}

			if (ident == Id.hasMember)
			{   /* Take any errors as meaning it wasn't found
			     */
				e = e.trySemantic(sc);
				if (!e)
				{	if (global.gag)
					global.errors++;
					goto Lfalse;
				}
				else
					goto Ltrue;
			}
			else if (ident == Id.getMember)
			{
				e = e.semantic(sc);
				return e;
			}
			else if (ident == Id.getVirtualFunctions || ident == Id.getOverloads)
			{
				uint errors = global.errors;
				Expression ex = e;
				e = e.semantic(sc);
				if (errors < global.errors)
					error("%s cannot be resolved", ex.toChars());

			    /* Create tuple of virtual function overloads of e
				 */
				//e.dump(0);
				Expressions exps = new Expressions();
				FuncDeclaration f_;
				if (e.op == TOKvar)
				{	
					VarExp ve = cast(VarExp)e;
					f_ = ve.var.isFuncDeclaration();
				}
				else if (e.op == TOKdotvar)
				{	
					DotVarExp dve = cast(DotVarExp)e;
					f_ = dve.var.isFuncDeclaration();
				}
				else
					f_ = null;
					
			    Ptrait p;
				p.exps = exps;
				p.e1 = e;
				p.ident = ident;
				overloadApply(f_, p);

				TupleExp tup = new TupleExp(loc, exps);
				return tup.semantic(sc);
			}
			else
				assert(0);
		}
		else if (ident == Id.classInstanceSize)
		{
			if (dim != 1)
				goto Ldimerror;
			Object o = args[0];
			Dsymbol s = getDsymbol(o);
			ClassDeclaration cd;
			if (!s || (cd = s.isClassDeclaration()) is null)
			{
				error("first argument is not a class");
				goto Lfalse;
			}
			return new IntegerExp(loc, cd.structsize, Type.tsize_t);
		}
		else if (ident == Id.allMembers || ident == Id.derivedMembers)
		{
			if (dim != 1)
				goto Ldimerror;
			Object o = args[0];
			Dsymbol s = getDsymbol(o);
			ScopeDsymbol sd;
			if (!s)
			{
				error("argument has no members");
				goto Lfalse;
			}
			if ((sd = s.isScopeDsymbol()) is null)
			{
				error("%s %s has no members", s.kind(), s.toChars());
				goto Lfalse;
			}
			Expressions exps = new Expressions;
			while (1)
			{   size_t dim_ = ScopeDsymbol.dim(sd.members);
				for (size_t i = 0; i < dim_; i++)
				{
					Dsymbol sm = ScopeDsymbol.getNth(sd.members, i);
					//printf("\t[%i] %s %s\n", i, sm.kind(), sm.toChars());
					if (sm.ident)
					{
						//printf("\t%s\n", sm.ident.toChars());
						auto str = sm.ident.toChars();

						/* Skip if already present in exps[]
						 */
						for (size_t j = 0; j < exps.dim; j++)
						{   auto se2 = cast(StringExp)exps[j];
							if (strcmp(toStringz(str), cast(char*)se2.string_) == 0)
								goto Lnext;
						}

						auto se = new StringExp(loc, str);
						exps.push(se);
					}
Lnext:
					;
				}
				ClassDeclaration cd = sd.isClassDeclaration();
				if (cd && cd.baseClass && ident == Id.allMembers)
					sd = cd.baseClass;	// do again with base class
				else
					break;
			}
			Expression e = new ArrayLiteralExp(loc, exps);
			e = e.semantic(sc);
			return e;
		}
		else if (ident == Id.compiles)
		{
			/* Determine if all the objects - types, expressions, or symbols -
			 * compile without error
			 */
			if (!dim)
				goto Lfalse;

			for (size_t i = 0; i < dim; i++)
			{   Object o = args[i];
				Expression e;

				uint errors = global.errors;
				global.gag++;

				Type t = isType(o);
				if (t)
				{	Dsymbol s;
					t.resolve(loc, sc, &e, &t, &s);
					if (t)
						t.semantic(loc, sc);
					else if (e)
						e.semantic(sc);
				}
				else
				{	e = isExpression(o);
					if (e)
						e.semantic(sc);
				}

				global.gag--;
				if (errors != global.errors)
				{   if (global.gag == 0)
					global.errors = errors;
					goto Lfalse;
				}
			}
			goto Ltrue;
		}
		else if (ident == Id.isSame)
		{	/* Determine if two symbols are the same
			 */
			if (dim != 2)
				goto Ldimerror;
			TemplateInstance.semanticTiargs(loc, sc, args, 0);
			Object o1 = args[0];
			Object o2 = args[1];
			Dsymbol s1 = getDsymbol(o1);
			Dsymbol s2 = getDsymbol(o2);

			// writef("isSame: %s, %s\n", o1.toChars(), o2.toChars());
			static if (0)
			{
				writef("o1: %p\n", o1);
				writef("o2: %p\n", o2);
				if (!s1)
				{   Expression ea = isExpression(o1);
					if (ea)
						printf("%s\n", ea.toChars());
					Type ta = isType(o1);
					if (ta)
						printf("%s\n", ta.toChars());
					goto Lfalse;
				}
				else
					printf("%s %s\n", s1.kind(), s1.toChars());
			}
			if (!s1 && !s2)
			{   Expression ea1 = isExpression(o1);
				Expression ea2 = isExpression(o2);
				if (ea1 && ea2 && ea1.equals(ea2))
					goto Ltrue;
			}

			if (!s1 || !s2)
				goto Lfalse;

			s1 = s1.toAlias();
			s2 = s2.toAlias();

			if (s1 == s2)
				goto Ltrue;
			else
				goto Lfalse;
		}
		else
		{
			error("unrecognized trait %s", ident.toChars());
			goto Lfalse;
		}

		return null;

// Not used
//Lnottype:
//		error("%s is not a type", o.toChars());
//		goto Lfalse;

Ldimerror:
		error("wrong number of arguments %d", dim);
		goto Lfalse;


Lfalse:
		return new IntegerExp(loc, 0, Type.tbool);

Ltrue:
		return new IntegerExp(loc, 1, Type.tbool);
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("__traits(");
		buf.writestring(ident.toChars());
		if (args)
		{
			for (int i = 0; i < args.dim; i++)
			{
				buf.writeByte(',');
				Object oarg = args[i];
				ObjectToCBuffer(buf, hgs, oarg);
			}
		}
		buf.writeByte(')');
	}
}
