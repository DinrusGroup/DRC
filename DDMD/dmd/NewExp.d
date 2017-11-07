module dmd.NewExp;

import dmd.common;
import dmd.Expression;
import dmd.GlobalExpressions;
import dmd.NewDeclaration;
import dmd.CtorDeclaration;
import dmd.ClassDeclaration;
import dmd.InterState;
import dmd.Type;
import dmd.OutBuffer;
import dmd.PREC;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.InlineDoState;
import dmd.HdrGenState;
import dmd.ArrayTypes;
import dmd.TOK;
import dmd.TY;
import dmd.TypeFunction;
import dmd.TypeClass;
import dmd.TypeStruct;
import dmd.StructDeclaration;
import dmd.FuncDeclaration;
import dmd.TypeDArray;
import dmd.Dsymbol;
import dmd.ThisExp;
import dmd.DotIdExp;
import dmd.Id;
import dmd.WANT;
import dmd.Global;
import dmd.IntegerExp;
import dmd.TypePointer;

import dmd.interpret.Util;
import dmd.expression.Util;

import dmd.backend.elem;
import dmd.backend.TYM;
import dmd.backend.SC;
import dmd.backend.TYPE;
import dmd.backend.TYM;
import dmd.backend.Symbol;
import dmd.backend.Classsym;
import dmd.backend.Util;
import dmd.backend.OPER;
import dmd.backend.RTLSYM;
import dmd.codegen.Util;

import std.string : toStringz;

import dmd.DDMDExtensions;

class NewExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	/* thisexp.new(newargs) newtype(arguments)
     */
    Expression thisexp;	// if !null, 'this' for class being allocated
    Expressions newargs;	// Array of Expression's to call new operator
    Type newtype;
    Expressions arguments;	// Array of Expression's

    CtorDeclaration member;	// constructor function
    NewDeclaration allocator;	// allocator function
    int onstack;		// allocate on stack

	this(Loc loc, Expression thisexp, Expressions newargs, Type newtype, Expressions arguments)
	{
		register();
		super(loc, TOK.TOKnew, NewExp.sizeof);
		this.thisexp = thisexp;
		this.newargs = newargs;
		this.newtype = newtype;
		this.arguments = arguments;
	}

	override Expression syntaxCopy()
	{
		return new NewExp(loc,
			thisexp ? thisexp.syntaxCopy() : null,
			arraySyntaxCopy(newargs),
			newtype.syntaxCopy(), arraySyntaxCopy(arguments));
	}

	override Expression semantic(Scope sc)
	{
		int i;
		Type tb;
		ClassDeclaration cdthis = null;

	version (LOGSEMANTIC) {
		printf("NewExp.semantic() %s\n", toChars());
		if (thisexp)
		printf("\tthisexp = %s\n", thisexp.toChars());
		printf("\tnewtype: %s\n", newtype.toChars());
	}
		if (type)			// if semantic() already run
			return this;

	Lagain:
		if (thisexp)
		{
			thisexp = thisexp.semantic(sc);
			cdthis = thisexp.type.isClassHandle();
			if (cdthis)
			{
				sc = sc.push(cdthis);
				type = newtype.semantic(loc, sc);
				sc = sc.pop();
			}
			else
			{
				error("'this' for nested class must be a class type, not %s", thisexp.type.toChars());
				type = newtype.semantic(loc, sc);
			}
		}
		else
			type = newtype.semantic(loc, sc);
		newtype = type;		// in case type gets cast to something else
		tb = type.toBasetype();
		//printf("tb: %s, deco = %s\n", tb.toChars(), tb.deco);

		arrayExpressionSemantic(newargs, sc);
		preFunctionParameters(loc, sc, newargs);
		arrayExpressionSemantic(arguments, sc);
		preFunctionParameters(loc, sc, arguments);

		if (thisexp && tb.ty != Tclass)
			error("e.new is only for allocating nested classes, not %s", tb.toChars());

		if (tb.ty == Tclass)
		{
			TypeFunction tf;

			TypeClass tc = cast(TypeClass)tb;
			ClassDeclaration cd = tc.sym.isClassDeclaration();
			if (cd.isInterfaceDeclaration())
				error("cannot create instance of interface %s", cd.toChars());
			else if (cd.isAbstract())
			{
				error("cannot create instance of abstract class %s", cd.toChars());
				for (int j = 0; j < cd.vtbl.dim; j++)
				{
					FuncDeclaration fd = (cast(Dsymbol)cd.vtbl.data[j]).isFuncDeclaration();
					if (fd && fd.isAbstract())
						error("function %s is abstract", fd.toChars());
				}
			}
			checkDeprecated(sc, cd);
			if (cd.isNested())
			{   /* We need a 'this' pointer for the nested class.
				 * Ensure we have the right one.
				 */
				Dsymbol s = cd.toParent2();
				ClassDeclaration cdn = s.isClassDeclaration();
				FuncDeclaration fdn = s.isFuncDeclaration();

				//printf("cd isNested, cdn = %s\n", cdn ? cdn.toChars() : "null");
				if (cdn)
				{
					if (!cdthis)
					{
						// Supply an implicit 'this' and try again
						thisexp = new ThisExp(loc);
						for (Dsymbol sp = sc.parent; 1; sp = sp.parent)
						{
							if (!sp)
							{
								error("outer class %s 'this' needed to 'new' nested class %s", cdn.toChars(), cd.toChars());
								break;
							}
							ClassDeclaration cdp = sp.isClassDeclaration();
							if (!cdp)
								continue;
							if (cdp == cdn || cdn.isBaseOf(cdp, null))
								break;
							// Add a '.outer' and try again
							thisexp = new DotIdExp(loc, thisexp, Id.outer);
						}
						if (!global.errors)
							goto Lagain;
					}
					if (cdthis)
					{
						//printf("cdthis = %s\n", cdthis.toChars());
						if (cdthis != cdn && !cdn.isBaseOf(cdthis, null))
						error("'this' for nested class must be of type %s, not %s", cdn.toChars(), thisexp.type.toChars());
					}
					else
					{
			static if (false) {
						for (Dsymbol *sf = sc.func; 1; sf= sf.toParent2().isFuncDeclaration())
						{
							if (!sf)
							{
								error("outer class %s 'this' needed to 'new' nested class %s", cdn.toChars(), cd.toChars());
								break;
							}
							printf("sf = %s\n", sf.toChars());
							AggregateDeclaration *ad = sf.isThis();
							if (ad && (ad == cdn || cdn.isBaseOf(ad.isClassDeclaration(), null)))
								break;
						}
			}
					}
				}
	///static if (true) {
				else if (thisexp)
					error("e.new is only for allocating nested classes");
				else if (fdn)
				{
					// make sure the parent context fdn of cd is reachable from sc
					for (Dsymbol sp = sc.parent; 1; sp = sp.parent)
					{
						if (fdn is sp)
							break;
						FuncDeclaration fsp = sp ? sp.isFuncDeclaration() : null;
						if (!sp || (fsp && fsp.isStatic()))
						{
						error("outer function context of %s is needed to 'new' nested class %s", fdn.toPrettyChars(), cd.toPrettyChars());
						break;
						}
					}
				}
	///} else {
	///			else if (fdn)
	///			{
	///				/* The nested class cd is nested inside a function,
	///				 * we'll let getEthis() look for errors.
	///				 */
	///				//printf("nested class %s is nested inside function %s, we're in %s\n", cd.toChars(), fdn.toChars(), sc.func.toChars());
	///				if (thisexp)
	///					// Because thisexp cannot be a function frame pointer
	///					error("e.new is only for allocating nested classes");
	///			}
	///}
				else
					assert(0);
			}
			else if (thisexp)
				error("e.new is only for allocating nested classes");

			FuncDeclaration f = null;
			if (cd.ctor)
				f = resolveFuncCall(sc, loc, cd.ctor, null, null, arguments, 0);
			if (f)
			{
				checkDeprecated(sc, f);
				member = f.isCtorDeclaration();
				assert(member);

				cd.accessCheck(loc, sc, member);

				tf = cast(TypeFunction)f.type;

				if (!arguments)
					arguments = new Expressions();
				functionParameters(loc, sc, tf, arguments);
			}
			else
			{
				if (arguments && arguments.dim)
					error("no constructor for %s", cd.toChars());
			}

			if (cd.aggNew)
			{
				// Prepend the size argument to newargs[]
				Expression e = new IntegerExp(loc, cd.size(loc), Type.tsize_t);
				if (!newargs)
					newargs = new Expressions();
				newargs.shift(e);

				f = cd.aggNew.overloadResolve(loc, null, newargs);
				allocator = f.isNewDeclaration();
				assert(allocator);

				tf = cast(TypeFunction)f.type;
				functionParameters(loc, sc, tf, newargs);
			}
			else
			{
				if (newargs && newargs.dim)
					error("no allocator for %s", cd.toChars());
			}
		}
		else if (tb.ty == Tstruct)
		{
			TypeStruct ts = cast(TypeStruct)tb;
			StructDeclaration sd = ts.sym;
			TypeFunction tf;

			FuncDeclaration f = null;
			if (sd.ctor)
				f = resolveFuncCall(sc, loc, sd.ctor, null, null, arguments, 0);
			if (f)
			{
				checkDeprecated(sc, f);
				member = f.isCtorDeclaration();
				assert(member);

				sd.accessCheck(loc, sc, member);

				tf = cast(TypeFunction)f.type;
		//	    type = tf.next;

				if (!arguments)
					arguments = new Expressions();
				functionParameters(loc, sc, tf, arguments);
			}
			else
			{
				if (arguments && arguments.dim)
					error("no constructor for %s", sd.toChars());
			}

			if (sd.aggNew)
			{
				// Prepend the uint size argument to newargs[]
				Expression e = new IntegerExp(loc, sd.size(loc), Type.tuns32);
				if (!newargs)
					newargs = new Expressions();
				newargs.shift(e);

				f = sd.aggNew.overloadResolve(loc, null, newargs);
				allocator = f.isNewDeclaration();
				assert(allocator);

				tf = cast(TypeFunction)f.type;
				functionParameters(loc, sc, tf, newargs);
		static if (false) {
				e = new VarExp(loc, f);
				e = new CallExp(loc, e, newargs);
				e = e.semantic(sc);
				e.type = type.pointerTo();
				return e;
		}
			}
			else
			{
				if (newargs && newargs.dim)
				error("no allocator for %s", sd.toChars());
			}

			type = type.pointerTo();
		}
		else if (tb.ty == Tarray && (arguments && arguments.dim))
		{
			for (size_t j = 0; j < arguments.dim; j++)
			{
				if (tb.ty != Tarray)
				{
					error("too many arguments for array");
					arguments.dim = i;
					break;
				}

				auto arg = arguments[j];
				arg = resolveProperties(sc, arg);
				arg = arg.implicitCastTo(sc, Type.tsize_t);
				arg = arg.optimize(WANTvalue);
				if (arg.op == TOKint64 && cast(long)arg.toInteger() < 0)
					error("negative array index %s", arg.toChars());
				arguments[j] =  arg;
				tb = (cast(TypeDArray)tb).next.toBasetype();
			}
		}
		else if (tb.isscalar())
		{
			if (arguments && arguments.dim)
				error("no constructor for %s", type.toChars());

			type = type.pointerTo();
		}
		else
		{
			error("new can only create structs, dynamic arrays or class objects, not %s's", type.toChars());
			type = type.pointerTo();
		}

	//printf("NewExp: '%s'\n", toChars());
	//printf("NewExp:type '%s'\n", type.toChars());

		return this;
	}
	
    override Expression interpret(InterState istate)
	{
version (LOG) {
		writef("NewExp::interpret() %s\n", toChars());
}
		if (newtype.ty == Tarray && arguments && arguments.dim == 1)
		{
			Expression lenExpr = arguments[0].interpret(istate);
			if (lenExpr is EXP_CANT_INTERPRET)
				return EXP_CANT_INTERPRET;
			return createBlockDuplicatedArrayLiteral(newtype, newtype.defaultInitLiteral(Loc(0)), cast(uint)lenExpr.toInteger());
		}
		error("Cannot interpret %s at compile time", toChars());
		return EXP_CANT_INTERPRET;

	}

	override Expression optimize(int result)
	{
		if (thisexp)
			thisexp = thisexp.optimize(WANTvalue);

		// Optimize parameters
		if (newargs)
		{
			foreach (ref Expression e; newargs)
			{
				e = e.optimize(WANTvalue);
			}
		}

		if (arguments)
		{
			foreach (ref Expression e; arguments)
			{
				e = e.optimize(WANTvalue);
			}
		}
		return this;
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;
		Type t;
		Type ectype;

		//printf("NewExp.toElem() %s\n", toChars());
		t = type.toBasetype();
		//printf("\ttype = %s\n", t.toChars());
		//if (member)
		//printf("\tmember = %s\n", member.toChars());
		if (t.ty == Tclass)
		{
			Symbol* csym;

			t = newtype.toBasetype();
			assert(t.ty == Tclass);
			TypeClass tclass = cast(TypeClass)t;
			ClassDeclaration cd = tclass.sym;

			/* Things to do:
			 * 1) ex: call allocator
			 * 2) ey: set vthis for nested classes
			 * 3) ez: call constructor
			 */

			elem *ex = null;
			elem *ey = null;
			elem *ez = null;

			if (allocator || onstack)
			{
				elem *ei;
				Symbol *si;

				if (onstack)
				{
					/* Create an instance of the class on the stack,
					 * and call it stmp.
					 * Set ex to be the &stmp.
					 */
					Symbol* s = symbol_calloc(toStringz(tclass.sym.toChars()));
					s.Sclass = SCstruct;
					s.Sstruct = struct_calloc();
					s.Sstruct.Sflags |= 0;
					s.Sstruct.Salignsize = tclass.sym.alignsize;
					s.Sstruct.Sstructalign = cast(ubyte)tclass.sym.structalign;
					s.Sstruct.Sstructsize = tclass.sym.structsize;

					.type* tc = type_alloc(TYstruct);
					tc.Ttag = cast(Classsym*)s;                // structure tag name
					tc.Tcount++;
					s.Stype = tc;

					Symbol *stmp = symbol_genauto(tc);
					ex = el_ptr(stmp);
				}
				else
				{
					ex = el_var(allocator.toSymbol());
					ex = callfunc(loc, irs, 1, type, ex, allocator.type,
						allocator, allocator.type, null, newargs);
				}

				si = tclass.sym.toInitializer();
				ei = el_var(si);

				if (cd.isNested())
				{
					ey = el_same(&ex);
					ez = el_copytree(ey);
				}
				else if (member)
					ez = el_same(&ex);

				ex = el_una(OPind, TYstruct, ex);
				ex = el_bin(OPstreq, TYnptr, ex, ei);
				ex.Enumbytes = cd.size(loc);
				ex = el_una(OPaddr, TYnptr, ex);
				ectype = tclass;
			}
			else
			{
				csym = cd.toSymbol();
				ex = el_bin(OPcall,TYnptr,el_var(rtlsym[RTLSYM_NEWCLASS]),el_ptr(csym));
				ectype = null;

				if (cd.isNested())
				{
					ey = el_same(&ex);
					ez = el_copytree(ey);
				}
				else if (member)
					ez = el_same(&ex);
				//elem_print(ex);
				//elem_print(ey);
				//elem_print(ez);
			}

			if (thisexp)
			{
				ClassDeclaration cdthis = thisexp.type.isClassHandle();
				assert(cdthis);
				//printf("cd = %s\n", cd.toChars());
				//printf("cdthis = %s\n", cdthis.toChars());
				assert(cd.isNested());
				int offset = 0;
				Dsymbol cdp = cd.toParent2();	// class we're nested in
				elem* ethis;

				//printf("member = %p\n", member);
				//printf("cdp = %s\n", cdp.toChars());
				//printf("cdthis = %s\n", cdthis.toChars());
				if (cdp != cdthis)
				{
					int i = cdp.isClassDeclaration().isBaseOf(cdthis, &offset);
					assert(i);
				}
				ethis = thisexp.toElem(irs);
				if (offset)
					ethis = el_bin(OPadd, TYnptr, ethis, el_long(TYint, offset));

				if (!cd.vthis)
				{
					error("forward reference to %s", cd.toChars());
				}
				else
				{
					ey = el_bin(OPadd, TYnptr, ey, el_long(TYint, cd.vthis.offset));
					ey = el_una(OPind, TYnptr, ey);
					ey = el_bin(OPeq, TYnptr, ey, ethis);
				}
				//printf("ex: "); elem_print(ex);
				//printf("ey: "); elem_print(ey);
				//printf("ez: "); elem_print(ez);
			}
			else if (cd.isNested())
			{
				/* Initialize cd.vthis:
				 *	*(ey + cd.vthis.offset) = this;
				 */
				ey = setEthis(loc, irs, ey, cd);
			}

			if (member)
				// Call constructor
				ez = callfunc(loc, irs, 1, type, ez, ectype, member, member.type, null, arguments);

			e = el_combine(ex, ey);
			e = el_combine(e, ez);
		}
		else if (t.ty == Tpointer && t.nextOf().toBasetype().ty == Tstruct)
		{
			Symbol* csym;

			t = newtype.toBasetype();
			assert(t.ty == Tstruct);
			TypeStruct tclass = cast(TypeStruct)t;
			StructDeclaration cd = tclass.sym;

			/* Things to do:
			 * 1) ex: call allocator
			 * 2) ey: set vthis for nested classes
			 * 3) ez: call constructor
			 */

			elem* ex = null;
			elem* ey = null;
			elem* ez = null;

			if (allocator)
			{
				elem *ei;
				Symbol *si;

				ex = el_var(allocator.toSymbol());
				ex = callfunc(loc, irs, 1, type, ex, allocator.type,
					allocator, allocator.type, null, newargs);

				si = tclass.sym.toInitializer();
				ei = el_var(si);

				if (cd.isNested())
				{
					ey = el_same(&ex);
					ez = el_copytree(ey);
				}
				else if (member)
					ez = el_same(&ex);

				if (!member)
				{
					/* Statically intialize with default initializer
					 */
					ex = el_una(OPind, TYstruct, ex);
					ex = el_bin(OPstreq, TYnptr, ex, ei);
					ex.Enumbytes = cd.size(loc);
					ex = el_una(OPaddr, TYnptr, ex);
				}
				ectype = tclass;
			}
			else
			{
				ulong elemsize = cd.size(loc);

				// call _d_newarrayT(ti, 1)
				e = el_long(TYsize_t, 1);
				e = el_param(e, type.getTypeInfo(null).toElem(irs));

				int rtl = t.isZeroInit(Loc(0)) ? RTLSYM_NEWARRAYT : RTLSYM_NEWARRAYIT;
				e = el_bin(OPcall,TYdarray,el_var(rtlsym[rtl]),e);

				// The new functions return an array, so convert to a pointer
				// ex . (unsigned)(e >> 32)
				e = el_bin(OPshr, TYdarray, e, el_long(TYint, 32));
				ex = el_una(OP64_32, TYnptr, e);

				ectype = null;

				if (cd.isNested())
				{
					ey = el_same(&ex);
					ez = el_copytree(ey);
				}
				else if (member)
					ez = el_same(&ex);
				//elem_print(ex);
				//elem_print(ey);
				//elem_print(ez);
			}

			if (cd.isNested())
			{
				/* Initialize cd.vthis:
				 *	*(ey + cd.vthis.offset) = this;
				 */
				ey = setEthis(loc, irs, ey, cd);
			}

			if (member)
			{
				// Call constructor
				ez = callfunc(loc, irs, 1, type, ez, ectype, member, member.type, null, arguments);
		version (STRUCTTHISREF) {
				/* Structs return a ref, which gets automatically dereferenced.
				 * But we want a pointer to the instance.
				 */
				ez = el_una(OPaddr, TYnptr, ez);
		}
			}

			e = el_combine(ex, ey);
			e = el_combine(e, ez);
		}
		else if (t.ty == Tarray)
		{
			TypeDArray tda = cast(TypeDArray)t;

			assert(arguments && arguments.dim >= 1);
			if (arguments.dim == 1)
			{
				// Single dimension array allocations
				auto arg = arguments[0];	// gives array length
				e = arg.toElem(irs);
				ulong elemsize = tda.next.size();

				// call _d_newT(ti, arg)
				e = el_param(e, type.getTypeInfo(null).toElem(irs));
				int rtl = tda.next.isZeroInit(Loc(0)) ? RTLSYM_NEWARRAYT : RTLSYM_NEWARRAYIT;
				e = el_bin(OPcall,TYdarray,el_var(rtlsym[rtl]),e);
			}
			else
			{
				// Multidimensional array allocations
				e = el_long(TYint, arguments.dim);
				foreach (Expression arg; arguments)
				{
					e = el_param(arg.toElem(irs), e);
					assert(t.ty == Tarray);
					t = t.nextOf();
					assert(t);
				}

				e = el_param(e, type.getTypeInfo(null).toElem(irs));

				int rtl = t.isZeroInit(Loc(0)) ? RTLSYM_NEWARRAYMT : RTLSYM_NEWARRAYMIT;
				e = el_bin(OPcall,TYdarray,el_var(rtlsym[rtl]),e);
			}
		}
		else if (t.ty == Tpointer)
		{
			TypePointer tp = cast(TypePointer)t;
			ulong elemsize = tp.next.size();
			Expression di = tp.next.defaultInit(Loc(0));
			ulong disize = di.type.size();

			// call _d_newarrayT(ti, 1)
			e = el_long(TYsize_t, 1);
			e = el_param(e, type.getTypeInfo(null).toElem(irs));

			int rtl = tp.next.isZeroInit(Loc(0)) ? RTLSYM_NEWARRAYT : RTLSYM_NEWARRAYIT;
			e = el_bin(OPcall,TYdarray,el_var(rtlsym[rtl]),e);

			// The new functions return an array, so convert to a pointer
			// e . (unsigned)(e >> 32)
			e = el_bin(OPshr, TYdarray, e, el_long(TYint, 32));
			e = el_una(OP64_32, t.totym(), e);
		}
		else
		{
			assert(0);
		}

		el_setLoc(e,loc);
		return e;
	}

	override bool checkSideEffect(int flag)
	{
		return true;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		int i;

		if (thisexp)
		{
			expToCBuffer(buf, hgs, thisexp, PREC.PREC_primary);
			buf.writeByte('.');
		}
		buf.writestring("new ");
		if (newargs && newargs.dim)
		{
			buf.writeByte('(');
			argsToCBuffer(buf, newargs, hgs);
			buf.writeByte(')');
		}
		newtype.toCBuffer(buf, null, hgs);
		if (arguments && arguments.dim)
		{
			buf.writeByte('(');
			argsToCBuffer(buf, arguments, hgs);
			buf.writeByte(')');
		}
	}

	override void scanForNestedRef(Scope sc)
	{
	    //printf("NewExp.scanForNestedRef(Scope *sc): %s\n", toChars());

		if (thisexp)
			thisexp.scanForNestedRef(sc);
		arrayExpressionScanForNestedRef(sc, newargs);
		arrayExpressionScanForNestedRef(sc, arguments);
	}

version (DMDV2) {
	override bool canThrow()
	{
		return 1;
	}
}

	//int inlineCost(InlineCostState *ics);

	override Expression doInline(InlineDoState ids)
	{
		//printf("NewExp.doInline(): %s\n", toChars());
		NewExp ne = cast(NewExp)copy();

		if (thisexp)
			ne.thisexp = thisexp.doInline(ids);
		ne.newargs = arrayExpressiondoInline(ne.newargs, ids);
		ne.arguments = arrayExpressiondoInline(ne.arguments, ids);
		return ne;
	}

	//Expression inlineScan(InlineScanState *iss);
}

