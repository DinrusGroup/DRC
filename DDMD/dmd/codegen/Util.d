module dmd.codegen.Util;

import dmd.common;
import dmd.Loc;
import dmd.Id;
import dmd.IRState;
import dmd.Type;
import dmd.Array;
import dmd.Declaration;
import dmd.Dsymbol;
import dmd.FuncDeclaration;
import dmd.Identifier;
import dmd.RET;
import dmd.TY;
import dmd.LINK;
import dmd.Expression;
import dmd.Parameter;
import dmd.STC;
import dmd.Global;
import dmd.Module;
import dmd.InterfaceDeclaration;
import dmd.AggregateDeclaration;
import dmd.AttribDeclaration;
import dmd.TupleDeclaration;
import dmd.StructDeclaration;
import dmd.VarDeclaration;
import dmd.ClassDeclaration;
import dmd.TemplateMixin;
import dmd.TypedefDeclaration;
import dmd.ExpInitializer;
import dmd.TypeFunction;
import dmd.TypeStruct;
import dmd.TypeSArray;
import dmd.TOK;
import dmd.Util;
import dmd.LabelStatement;
import dmd.DsymbolExp;
import dmd.LabelDsymbol;
import dmd.backend.elem;
import dmd.backend.TYPE;
import dmd.backend.Util;
import dmd.backend.Classsym;
import dmd.backend.SC;
import dmd.backend.FL;
import dmd.backend.SFL;
import dmd.backend.STR;
import dmd.backend.TYM;
import dmd.backend.TF;
import dmd.backend.OPER;
import dmd.backend.mTYman;
import dmd.backend.TYFL;
import dmd.backend.mTY;
import dmd.backend.Symbol;
import dmd.backend.Blockx;
import dmd.backend.RTLSYM;
import dmd.backend.block;
import dmd.backend.LIST;
import dmd.backend.iasm : binary;

import std.string;
import core.stdc.string;
import core.stdc.stdlib;

import core.memory;


/* If variable var of type typ is a reference
 */
version(SARRAYVALUE)
{
	bool ISREF(Declaration var, Type tb) {return var.isOut() || var.isRef();}
}
else
	bool ISREF(Declaration var, Type tb) {return (var.isParameter() && tb.ty == TY.Tsarray) || var.isOut() || var.isRef();}



/************************************
 * Call a function.
 */
elem* callfunc(Loc loc,
	IRState* irs,
	int directcall,		// 1: don't do virtual call
	Type tret,		// return type
	elem *ec,		// evaluates to function address
	Type ectype,		// original type of ec
	FuncDeclaration fd,	// if !=null, this is the function being called
	Type t,		// TypeDelegate or TypeFunction for this function
	elem* ehidden,		// if !=null, this is the 'hidden' argument
	Expressions arguments)
{
    elem* ep;
    elem* e;
    elem* ethis = null;
    elem* eside = null;
    int i;
    tym_t ty;
    tym_t tyret;
    RET retmethod;
    int reverse;
    TypeFunction tf;
    OPER op;

static if (false) {
    printf("callfunc(directcall = %d, tret = '%s', ec = %p, fd = %p)\n",
	directcall, tret.toChars(), ec, fd);
    printf("ec: "); elem_print(ec);
    if (fd)
		printf("fd = '%s'\n", fd.toChars());
}

    t = t.toBasetype();
    if (t.ty == TY.Tdelegate)
    {
		// A delegate consists of:
		//	{ Object *this; Function *funcptr; }
		assert(!fd);
		assert(t.nextOf().ty == TY.Tfunction);
		tf = cast(TypeFunction)t.nextOf();
		ethis = ec;
		ec = el_same(&ethis);
		ethis = el_una(OPER.OP64_32, TYM.TYnptr, ethis);	// get this
		ec = array_toPtr(t, ec);		// get funcptr
		ec = el_una(OPER.OPind, tf.totym(), ec);
    }
    else
    {
		assert(t.ty == TY.Tfunction);
		tf = cast(TypeFunction)t;
    }

    retmethod = tf.retStyle();
    ty = ec.Ety;
    if (fd)
		ty = fd.toSymbol().Stype.Tty;
    reverse = tyrevfunc(ty);
    ep = null;
    if (arguments)
    {
		// j=1 if _arguments[] is first argument
		int j = (tf.linkage == LINK.LINKd && tf.varargs == 1);

		foreach (size_t i, Expression arg; arguments)
		{
			elem* ea;

			//writef("\targ[%d]: %s\n", i, arg.toChars());

			size_t nparams = Parameter.dim(tf.parameters);
			if (i - j < nparams && i >= j)
			{
				auto p = Parameter.getNth(tf.parameters, i - j);

				if (p.storageClass & (STC.STCout | STC.STCref))
				{
					// Convert argument to a pointer,
					// use AddrExp.toElem()
					Expression ae = arg.addressOf(null);
					ea = ae.toElem(irs);
					goto L1;
				}
			}
			ea = arg.toElem(irs);
		L1:
			if (tybasic(ea.Ety) == TYM.TYstruct || tybasic(ea.Ety) == TYarray)
			{
				ea = el_una(OPER.OPstrpar, TYM.TYstruct, ea);
				ea.Enumbytes = ea.E1.Enumbytes;
				//assert(ea.Enumbytes);
			}
			if (reverse)
				ep = el_param(ep,ea);
			else
				ep = el_param(ea,ep);
		}
    }

    if (retmethod == RET.RETstack)
    {
		if (!ehidden)
		{
			// Don't have one, so create one
			type* tt;

			Type tret2 = tf.next; // in dmd tret is shadowed here, so -> tret2
			if (tret2.toBasetype().ty == Tstruct ||
				tret2.toBasetype().ty == Tsarray)
				tt = tret2.toCtype();
			else
				tt = type_fake(tret2.totym());

			Symbol* stmp = symbol_genauto(tt);
			ehidden = el_ptr(stmp);
		}
		if ((global.params.isLinux || global.params.isOSX || global.params.isFreeBSD || global.params.isSolaris) && tf.linkage != LINK.LINKd) {
			//;	// ehidden goes last on Linux/OSX C++
		} else {
			if (ep)
			{
static if (false) { // BUG: implement
				if (reverse && type_mangle(tfunc) == mTYman.mTYman_cpp) {
					ep = el_param(ehidden,ep);
				} else {
					ep = el_param(ep,ehidden);
				}
} else {
				ep = el_param(ep,ehidden);
}
			}
			else
			ep = ehidden;
			ehidden = null;
		}
    }

    if (fd && fd.isMember2())
    {
		InterfaceDeclaration intd;
		Symbol* sfunc;
		AggregateDeclaration ad;

		ad = fd.isThis();
		if (ad)
		{
			ethis = ec;
			if (ad.isStructDeclaration() && tybasic(ec.Ety) != TYM.TYnptr)
			{
				ethis = addressElem(ec, ectype);
			}
		}
		else
		{
			// Evaluate ec for side effects
			eside = ec;
		}
		sfunc = fd.toSymbol();

		if (!fd.isVirtual() ||
			directcall ||		// BUG: fix
			fd.isFinal())
		{
			// make static call
			ec = el_var(sfunc);
		}
		else
		{
			// make virtual call
			elem* ev;
			uint vindex;

			assert(ethis);
			ev = el_same(&ethis);
			ev = el_una(OPER.OPind, TYM.TYnptr, ev);
			vindex = fd.vtblIndex;

			// Build *(ev + vindex * 4)
			ec = el_bin(OPER.OPadd, TYM.TYnptr, ev, el_long(TYM.TYint, vindex * 4));
			ec = el_una(OPER.OPind, TYM.TYnptr, ec);
			ec = el_una(OPER.OPind, tybasic(sfunc.Stype.Tty), ec);
		}
    }
    else if (fd && fd.isNested())
    {
		assert(!ethis);
		ethis = getEthis(Loc(0), irs, fd);
    }

    ep = el_param(ep, ethis);
    if (ehidden)
		ep = el_param(ep, ehidden);	// if ehidden goes last

    tyret = tret.totym();

    // Look for intrinsic functions
    if (ec.Eoper == OPER.OPvar && (op = intrinsic_oper(ec.EV.sp.Vsym.Sident.ptr)) != OPER.OPMAX)
    {
		el_free(ec);
		if (OTbinary(op))
		{
			ep.Eoper = op;
			ep.Ety = tyret;
			e = ep;
			if (op == OPER.OPscale)
			{
				elem *et = e.E1;
				e.E1() = el_una(OPER.OPd_ld, TYM.TYldouble, e.E1);
				e.E1() = el_una(OPER.OPs32_d, TYM.TYdouble, e.E2);
				e.E2() = et;
			}
			else if (op == OPER.OPyl2x || op == OPER.OPyl2xp1)
			{
				elem *et = e.E1;
				e.E1() = e.E2;
				e.E2() = et;
			}
		}
		else
			e = el_una(op,tyret,ep);
    }
    else if (ep)
	    /* Do not do "no side effect" calls if a hidden parameter is passed,
	     * as the return value is stored through the hidden parameter, which
	     * is a side effect.
	     */
		e = el_bin((tf.ispure && tf.isnothrow && (retmethod != RET.RETstack)) ?
		            OPcallns : OPcall, tyret, ec, ep);
    else
		e = el_una((tf.ispure && tf.isnothrow && (retmethod != RET.RETstack)) ?
		            OPucallns : OPucall, tyret, ec);

    if (retmethod == RET.RETstack)
    {
		e.Ety = TYM.TYnptr;
		e = el_una(OPER.OPind, tyret, e);
    }

version (DMDV2) {
    if (tf.isref)
    {
		e.Ety = TYM.TYnptr;
		e = el_una(OPER.OPind, tyret, e);
    }
}

    if (tybasic(tyret) == TYM.TYstruct)
    {
		e.Enumbytes = cast(uint)tret.size();
    }

    e = el_combine(eside, e);
    return e;
}

/**************************************
 * Fake a struct symbol.
 */

Classsym* fake_classsym(Identifier id)
{
	TYPE* t;
    Classsym* scc;

    scc = cast(Classsym*)symbol_calloc(toStringz(id.toChars()));
    scc.Sclass = SC.SCstruct;
    scc.Sstruct = struct_calloc();
    scc.Sstruct.Sstructalign = 8;
    //scc.Sstruct.ptrtype = TYM.TYnptr;
    scc.Sstruct.Sflags = STR.STRglobal;

    t = type_alloc(TYM.TYstruct);
    t.Tflags |= TF.TFsizeunknown | TF.TFforward;
    t.Ttag = scc;		// structure tag name
    assert(t.Tmangle == 0);
    t.Tmangle = mTYman.mTYman_d;
    t.Tcount++;
    scc.Stype = t;
    slist_add(scc);
    return scc;
}

/******************************************
 * Return elem that evaluates to the static frame pointer for function fd.
 * If fd is a member function, the returned expression will compute the value
 * of fd's 'this' variable.
 * This routine is critical for implementing nested functions.
 */

elem* getEthis(Loc loc, IRState* irs, Dsymbol fd)
{
	elem* ethis;
    FuncDeclaration thisfd = irs.getFunc();
    Dsymbol fdparent = fd.toParent2();

    //printf("getEthis(thisfd = '%s', fd = '%s', fdparent = '%s')\n", thisfd.toChars(), fd.toChars(), fdparent.toChars());
    if (fdparent == thisfd ||
		/* These two are compiler generated functions for the in and out contracts,
		 * and are called from an overriding function, not just the one they're
		 * nested inside, so this hack is so they'll pass
		 */
		fd.ident == Id.require || fd.ident == Id.ensure)
    {
		/* Going down one nesting level, i.e. we're calling
		 * a nested function from its enclosing function.
		 */
///version (DMDV2) {
		if (irs.sclosure)
			ethis = el_var(irs.sclosure);
		else
///}
		if (irs.sthis)
		{
			// We have a 'this' pointer for the current function
			ethis = el_var(irs.sthis);

			/* If no variables in the current function's frame are
			 * referenced by nested functions, then we can 'skip'
			 * adding this frame into the linked list of stack
			 * frames.
			 */
version (DMDV2) {
			bool cond = (thisfd.closureVars.dim != 0);
} else {
			bool cond = thisfd.nestedFrameRef;
}
			if (cond)
			{
				/* Local variables are referenced, can't skip.
				 * Address of 'this' gives the 'this' for the nested
				 * function
				 */
				ethis = el_una(OPER.OPaddr, TYM.TYnptr, ethis);
			}
		}
		else
		{
			/* No 'this' pointer for current function,
			 * use null if no references to the current function's frame
			 */
			ethis = el_long(TYM.TYnptr, 0);
version (DMDV2) {
			bool cond = (thisfd.closureVars.dim != 0);
} else {
			bool cond = thisfd.nestedFrameRef;
}
			if (cond)
			{
				/* OPframeptr is an operator that gets the frame pointer
				 * for the current function, i.e. for the x86 it gets
				 * the value of EBP
				 */
				ethis.Eoper = OPER.OPframeptr;
			}
		}

		//if (fdparent != thisfd) ethis = el_bin(OPadd, TYnptr, ethis, el_long(TYint, 0x18));
    }
    else
    {
		if (!irs.sthis)		// if no frame pointer for this function
		{
			fd.error(loc, "is a nested function and cannot be accessed from %s", irs.getFunc().toChars());
			ethis = el_long(TYM.TYnptr, 0);	// error recovery
		}
		else
		{
			ethis = el_var(irs.sthis);
			Dsymbol s = thisfd;
			while (fd != s)
			{
				/* Go up a nesting level, i.e. we need to find the 'this'
				 * of an enclosing function.
				 * Our 'enclosing function' may also be an inner class.
				 */

				//printf("\ts = '%s'\n", s.toChars());
				thisfd = s.isFuncDeclaration();
				if (thisfd)
				{
					/* Enclosing function is a function.
					 */
					if (fdparent == s.toParent2())
						break;

					if (thisfd.isNested())
					{
						FuncDeclaration p = s.toParent2().isFuncDeclaration();
version (DMDV2) {
						bool cond = !p || p.closureVars.dim;
} else {
						bool cond = !p || p.nestedFrameRef;
}
						if (cond) {
							ethis = el_una(OPER.OPind, TYM.TYnptr, ethis);
						}
					}
					else if (thisfd.vthis)
					{
						//;
					}
					else
					{
						// Error should have been caught by front end
						assert(0);
					}
				}
				else
				{
					/* Enclosed by an aggregate. That means the current
					 * function must be a member function of that aggregate.
					 */
					ClassDeclaration cd;
					StructDeclaration sd;
					AggregateDeclaration ad = s.isAggregateDeclaration();

					if (!ad)
						goto Lnoframe;

					cd = s.isClassDeclaration();

					if (cd && fd.isClassDeclaration() && fd.isClassDeclaration().isBaseOf(cd, null))
						break;

					sd = s.isStructDeclaration();

					if (fd == sd)
						break;

					if (!ad.isNested() || !ad.vthis)
					{
					  Lnoframe:
						irs.getFunc().error(loc, "cannot get frame pointer to %s", fd.toChars());
						return el_long(TYM.TYnptr, 0);	// error recovery
					}

					ethis = el_bin(OPER.OPadd, TYM.TYnptr, ethis, el_long(TYM.TYint, ad.vthis.offset));
					ethis = el_una(OPER.OPind, TYM.TYnptr, ethis);

					if (fdparent == s.toParent2())
						break;

					if (auto fdd = s.toParent2().isFuncDeclaration())
					{
						/* Remember that frames for functions that have no
						 * nested references are skipped in the linked list
						 * of frames.
						 */
version (DMDV2) {
						bool cond = (fdd.closureVars.dim != 0);
} else {
						bool cond = fdd.nestedFrameRef;
}
						if (cond) {
							ethis = el_una(OPER.OPind, TYM.TYnptr, ethis);
						}
						break;
					}
				}
				s = s.toParent2();
				assert(s);
			}
		}
    }

static if (false) {
    printf("ethis:\n");
    elem_print(ethis);
    printf("\n");
}

    return ethis;
}

/*****************************************
 * Convert array to a pointer to the data.
 */

elem* array_toPtr(Type t, elem* e)
{
    //printf("array_toPtr()\n");
    //elem_print(e);
    t = t.toBasetype();
    switch (t.ty)
    {
	case TY.Tpointer:
	    break;

	case TY.Tarray:
	case TY.Tdelegate:
	    if (e.Eoper == OPER.OPcomma)
	    {
			e.Ety = TYM.TYnptr;
			e.E2() = array_toPtr(t, e.E2);
	    }
	    else if (e.Eoper == OPER.OPpair)
	    {
			e.Eoper = OPER.OPcomma;
			e.Ety = TYM.TYnptr;
	    }
	    else
	    {
static if (true) {
			e = el_una(OPER.OPmsw, TYM.TYnptr, e);
} else {
			e = el_una(OPER.OPaddr, TYM.TYnptr, e);
			e = el_bin(OPER.OPadd, TYM.TYnptr, e, el_long(TYM.TYint, 4));
			e = el_una(OPER.OPind, TYM.TYnptr, e);
}
	    }
	    break;

	case TY.Tsarray:
	    e = el_una(OPER.OPaddr, TYM.TYnptr, e);
	    break;

	default:
	    ///t.print();
	    assert(0);
    }
    return e;
}

/*******************************************
 * Take address of an elem.
 */

elem* addressElem(elem* e, Type t)
{
    elem** pe;

    //printf("addressElem()\n");

    for (pe = &e; (*pe).Eoper == OPER.OPcomma; pe = &(*pe).E2()) {
		//;
	}

    if ((*pe).Eoper != OPER.OPvar && (*pe).Eoper != OPER.OPind)
    {
		Symbol* stmp;
		elem* eeq;
		elem* ee = *pe;
		type* tx;

		// Convert to ((tmp=ee),tmp)
		TY ty;
		if (t && ((ty = t.toBasetype().ty) == TY.Tstruct || ty == TY.Tsarray))
			tx = t.toCtype();
		else
			tx = type_fake(ee.Ety);
		stmp = symbol_genauto(tx);
		eeq = el_bin(OPER.OPeq,ee.Ety,el_var(stmp),ee);

		if (tybasic(ee.Ety) == TYM.TYstruct)
		{
			eeq.Eoper = OPER.OPstreq;
			eeq.Enumbytes = ee.Enumbytes;
		}
		else if (tybasic(ee.Ety) == TYM.TYarray)
		{
			eeq.Eoper = OPER.OPstreq;
			eeq.Ety = TYM.TYstruct;
			eeq.Ejty = cast(ubyte)eeq.Ety;
			eeq.Enumbytes = cast(uint)t.size();
		}
		*pe = el_bin(OPER.OPcomma, ee.Ety, eeq, el_var(stmp));
    }

    e = el_una(OPER.OPaddr, TYM.TYnptr, e);
    return e;
}

/*******************************************
 * Convert intrinsic function to operator.
 * Returns that operator, -1 if not an intrinsic function.
 */

//extern (C++) extern int intrinsic_op(char* name);

OPER intrinsic_oper(const(char)* name)
{
	version(DMDV1)
	enum const(char)*[] namearray=
	[
		"4math3cosFeZe",
		"4math3sinFeZe",
		"4math4fabsFeZe",
		"4math4rintFeZe",
		"4math4sqrtFdZd",
		"4math4sqrtFeZe",
		"4math4sqrtFfZf",
		"4math4yl2xFeeZe",
		"4math5ldexpFeiZe",
		"4math6rndtolFeZl",
		"4math6yl2xp1FeeZe",

		"9intrinsic2btFPkkZi",
		"9intrinsic3bsfFkZi",
		"9intrinsic3bsrFkZi",
		"9intrinsic3btcFPkkZi",
		"9intrinsic3btrFPkkZi",
		"9intrinsic3btsFPkkZi",
		"9intrinsic3inpFkZh",
		"9intrinsic4inplFkZk",
		"9intrinsic4inpwFkZt",
		"9intrinsic4outpFkhZh",
		"9intrinsic5bswapFkZk",
		"9intrinsic5outplFkkZk",
		"9intrinsic5outpwFktZt",
	];
else
	enum const(char)*[] namearray =
	[
		/* The names are mangled differently because of the pure and
		 * nothrow attributes.
		 */
		"4math3cosFNaNbNfeZe",
		"4math3sinFNaNbNfeZe",
		"4math4fabsFNaNbNfeZe",
		"4math4rintFNaNbNfeZe",
		"4math4sqrtFNaNbNfdZd",
		"4math4sqrtFNaNbNfeZe",
		"4math4sqrtFNaNbNffZf",
		"4math4yl2xFNaNbNfeeZe",
		"4math5ldexpFNaNbNfeiZe",
		"4math6rndtolFNaNbNfeZl",
		"4math6yl2xp1FNaNbNfeeZe",

		"9intrinsic2btFNaNbxPkkZi",
		"9intrinsic3bsfFNaNbkZi",
		"9intrinsic3bsrFNaNbkZi",
		"9intrinsic3btcFNbPkkZi",
		"9intrinsic3btrFNbPkkZi",
		"9intrinsic3btsFNbPkkZi",
		"9intrinsic3inpFNbkZh",
		"9intrinsic4inplFNbkZk",
		"9intrinsic4inpwFNbkZt",
		"9intrinsic4outpFNbkhZh",
		"9intrinsic5bswapFNaNbkZk",
		"9intrinsic5outplFNbkkZk",
		"9intrinsic5outpwFNbktZt",
	];

	enum OPER[] ioptab =
	[
		OPcos,
		OPsin,
		OPabs,
		OPrint,
		OPsqrt,
		OPsqrt,
		OPsqrt,
		OPyl2x,
		OPscale,
		OPrndtol,
		OPyl2xp1,

		OPbt,
		OPbsf,
		OPbsr,
		OPbtc,
		OPbtr,
		OPbts,
		OPinp,
		OPinp,
		OPinp,
		OPoutp,
		OPbswap,
		OPoutp,
		OPoutp,
	];

	debug
	{
		assert(namearray.length == ioptab.length);
		// assume sorted namearray
		for (int i = 0; i < namearray.length - 1; i++)
		{
			if (strcmp(namearray[i], namearray[i + 1]) >= 0)
			{
				printf("namearray[%d] = '%s'\n", i, namearray[i]);
				assert(0);
			}
		}
	}

	size_t length = strlen(name);
	if (length < 11 || !(name[7] == 'm' || name[7] == 'i') || name[0..6] != "_D3std")
		return OPMAX;

	int p = binary(name + 6, namearray.ptr, namearray.length);
	if(p == -1)
		return OPMAX;
	return ioptab[p];
}

/**************************************
 */

elem* Dsymbol_toElem(Dsymbol s, IRState *irs)
{
    elem *e = null;
    Symbol* sp;
    AttribDeclaration ad;
    VarDeclaration vd;
    ClassDeclaration cd;
    StructDeclaration sd;
    FuncDeclaration fd;
    TemplateMixin tm;
    TupleDeclaration td;
    TypedefDeclaration tyd;

    //printf("Dsymbol_toElem() %s\n", s.toChars());
    ad = s.isAttribDeclaration();
    if (ad)
    {
		auto decl = ad.include(null, null);
		if (decl && decl.dim)
		{
			foreach(s; decl)
				e = el_combine(e, Dsymbol_toElem(s, irs));
		}
    }
    else if ((vd = s.isVarDeclaration()) !is null)
    {
		s = s.toAlias();
		if (s != vd)
			return Dsymbol_toElem(s, irs);
		if (vd.isStatic() || vd.storage_class & (STC.STCextern | STC.STCtls | STC.STCgshared))
			vd.toObjFile(0);
		else
		{
			sp = s.toSymbol();
			symbol_add(sp);
			//printf("\tadding symbol '%s'\n", sp.Sident);
			if (vd.init)
			{
				ExpInitializer ie = vd.init.isExpInitializer();
				if (ie) {
					e = ie.exp.toElem(irs);
				}
			}
		}
    }
    else if ((cd = s.isClassDeclaration()) !is null)
    {
		irs.deferToObj.push(cast(void*)s);
    }
    else if ((sd = s.isStructDeclaration()) !is null)
    {
		irs.deferToObj.push(cast(void*)sd);
    }
    else if ((fd = s.isFuncDeclaration()) !is null)
    {
		//printf("function %s\n", fd.toChars());
		irs.deferToObj.push(cast(void*)fd);
    }
    else if ((tm = s.isTemplateMixin()) !is null)
    {
		//printf("%s\n", tm.toChars());
		if (tm.members)
		{
			foreach(Dsymbol sm; tm.members)
				e = el_combine(e, Dsymbol_toElem(sm, irs));
		}
    }
    else if ((td = s.isTupleDeclaration()) !is null)
    {
		for (size_t i = 0; i < td.objects.dim; i++)
		{
			auto o = td.objects[i];
			///if (o.dyncast() == DYNCAST_EXPRESSION)
			if (auto eo = cast(Expression)o)
			{
				if (eo.op == TOK.TOKdsymbol)
				{
					auto se = cast(DsymbolExp)eo;
					e = el_combine(e, Dsymbol_toElem(se.s, irs));
				}
			}
		}
    }
    else if ((tyd = s.isTypedefDeclaration()) !is null)
    {
		irs.deferToObj.push(cast(void*)tyd);
    }

    return e;
}

/**************************************
 * Given an expression e that is an array,
 * determine and set the 'length' variable.
 * Input:
 *	lengthVar	Symbol of 'length' variable
 *	&e	expression that is the array
 *	t1	Type of the array
 * Output:
 *	e	is rewritten to avoid side effects
 * Returns:
 *	expression that initializes 'length'
 */

elem* resolveLengthVar(VarDeclaration lengthVar, elem** pe, Type t1)
{
    //printf("resolveLengthVar()\n");
    elem* einit = null;

    if (lengthVar && !(lengthVar.storage_class & STC.STCconst))
    {
		elem* elength;
		Symbol* slength;

		if (t1.ty == TY.Tsarray)
		{
			TypeSArray tsa = cast(TypeSArray)t1;
			long length = tsa.dim.toInteger();

			elength = el_long(TYM.TYuint, length);
			goto L3;
		}
		else if (t1.ty == TY.Tarray)
		{
			elength = *pe;
			*pe = el_same(&elength);
			elength = el_una(OP64_32, TYM.TYuint, elength);

		L3:
			slength = lengthVar.toSymbol();
			//symbol_add(slength);

			einit = el_bin(OPeq, TYM.TYuint, el_var(slength), elength);
		}
    }
    return einit;
}

/*******************************************
 * Set an array pointed to by eptr to evalue:
 *	eptr[0..edim] = evalue;
 * Input:
 *	eptr	where to write the data to
 *	evalue	value to write
 *	edim	number of times to write evalue to eptr[]
 *	tb	type of evalue
 */
elem* setArray(elem* eptr, elem* edim, Type tb, elem* evalue, IRState* irs, int op)
{
	int r;
    elem* e;
    int sz = cast(int)tb.size();

    if (tb.ty == TY.Tfloat80 || tb.ty == TY.Timaginary80)
		r = RTLSYM.RTLSYM_MEMSET80;
    else if (tb.ty == TY.Tcomplex80)
		r = RTLSYM.RTLSYM_MEMSET160;
    else if (tb.ty == TY.Tcomplex64)
		r = RTLSYM.RTLSYM_MEMSET128;
    else
    {
		switch (sz)
		{
			case 1:	 r = RTLSYM.RTLSYM_MEMSET8;		break;
			case 2:	 r = RTLSYM.RTLSYM_MEMSET16;	break;
			case 4:	 r = RTLSYM.RTLSYM_MEMSET32;	break;
			case 8:	 r = RTLSYM.RTLSYM_MEMSET64;	break;
			default: r = RTLSYM.RTLSYM_MEMSETN;		break;
		}

		/* Determine if we need to do postblit
		 */
		if (op != TOK.TOKblit)
		{
			StructDeclaration sd = needsPostblit(tb);
			if (sd)
			{
				/* Need to do postblit.
				 *   void *_d_arraysetassign(void *p, void *value, int dim, TypeInfo ti);
				 */
				r = (op == TOK.TOKconstruct) ? RTLSYM.RTLSYM_ARRAYSETCTOR : RTLSYM.RTLSYM_ARRAYSETASSIGN;
				evalue = el_una(OPER.OPaddr, TYM.TYnptr, evalue);
				Expression ti = tb.getTypeInfo(null);
				elem* eti = ti.toElem(irs);
				e = el_params(eti, edim, evalue, eptr, null);
				e = el_bin(OPER.OPcall, TYM.TYnptr, el_var(rtlsym[r]), e);
				return e;
			}
		}

		if (r == RTLSYM.RTLSYM_MEMSETN)
		{
			// void *_memsetn(void *p, void *value, int dim, int sizelem)
			evalue = el_una(OPER.OPaddr, TYM.TYnptr, evalue);
			elem *esz = el_long(TYM.TYint, sz);
			e = el_params(esz, edim, evalue, eptr, null);
			e = el_bin(OPER.OPcall, TYM.TYnptr, el_var(rtlsym[r]), e);
			return e;
		}
    }
    if (sz > 1 && sz <= 8 && evalue.Eoper == OPER.OPconst && el_allbits(evalue, 0))
    {
		r = RTLSYM.RTLSYM_MEMSET8;
		edim = el_bin(OPER.OPmul, TYM.TYuint, edim, el_long(TYM.TYuint, sz));
    }

    if (tybasic(evalue.Ety) == TYM.TYstruct || tybasic(evalue.Ety) == TYarray)
    {
		evalue = el_una(OPER.OPstrpar, TYM.TYstruct, evalue);
		evalue.Enumbytes = evalue.E1.Enumbytes;
		assert(evalue.Enumbytes);
    }

    // Be careful about parameter side effect ordering
    if (r == RTLSYM.RTLSYM_MEMSET8)
    {
		e = el_param(edim, evalue);
		e = el_bin(OPER.OPmemset, TYM.TYnptr, eptr, e);
    }
    else
    {
		e = el_params(edim, evalue, eptr, null);
		e = el_bin(OPER.OPcall, TYM.TYnptr, el_var(rtlsym[r]), e);
    }
    return e;
}

/*************************
 * Initialize the hidden aggregate member, vthis, with
 * the context pointer.
 * Returns:
 *	*(ey + ad.vthis.offset) = this;
 */
version (DMDV2) {
	elem* setEthis(Loc loc, IRState* irs, elem* ey, AggregateDeclaration ad)
	{
		elem* ethis;
		FuncDeclaration thisfd = irs.getFunc();
		int offset = 0;
		Dsymbol cdp = ad.toParent2();	// class/func we're nested in

		//printf("setEthis(ad = %s, cdp = %s, thisfd = %s)\n", ad.toChars(), cdp.toChars(), thisfd.toChars());

		if (cdp is thisfd)
		{
			/* Class we're new'ing is a local class in this function:
			 *	void thisfd() { class ad { } }
			 */
			if (irs.sclosure)
				ethis = el_var(irs.sclosure);
			else if (irs.sthis)
			{
///	version (DMDV2) {
				if (thisfd.closureVars.dim)
///	} else {
///				if (thisfd.nestedFrameRef)
///	}
				{
					ethis = el_ptr(irs.sthis);
				}
				else
					ethis = el_var(irs.sthis);
			}
			else
			{
				ethis = el_long(TYM.TYnptr, 0);
///	version (DMDV2) {
				if (thisfd.closureVars.dim)
///	} else {
///				if (thisfd.nestedFrameRef)
///	}
				{
					ethis.Eoper = OPER.OPframeptr;
				}
			}
		}
		else if (thisfd.vthis && (
					cdp == thisfd.toParent2() || (
								cdp.isClassDeclaration() && cdp.isClassDeclaration().isBaseOf(thisfd.toParent2().isClassDeclaration(), &offset)
							)
						)
				)
		{
			/* Class we're new'ing is at the same level as thisfd
			 */
			assert(offset == 0);	// BUG: should handle this case
			ethis = el_var(irs.sthis);
		}
		else
		{
			ethis = getEthis(loc, irs, ad.toParent2());
			ethis = el_una(OPER.OPaddr, TYM.TYnptr, ethis);
		}

		ey = el_bin(OPER.OPadd, TYM.TYnptr, ey, el_long(TYM.TYint, ad.vthis.offset));
		ey = el_una(OPER.OPind, TYM.TYnptr, ey);
		ey = el_bin(OPER.OPeq,  TYM.TYnptr, ey, ethis);

		return ey;
	}
}

/********************************************
 * Determine if t is an array of structs that need a postblit.
 */
StructDeclaration needsPostblit(Type t)
{
    t = t.toBasetype();

    while (t.ty == TY.Tsarray)
		t = t.nextOf().toBasetype();

    if (t.ty == TY.Tstruct)
    {
		StructDeclaration sd = (cast(TypeStruct)t).sym;
		if (sd.postblit)
			return sd;
    }

    return null;
}

/*****************************************
 * Convert array to a dynamic array.
 */

elem* array_toDarray(Type t, elem* e)
{
    uint dim;
    elem* ef = null;
    elem* ex;

    //printf("array_toDarray(t = %s)\n", t.toChars());
    //elem_print(e);
    t = t.toBasetype();
    switch (t.ty)
    {
		case TY.Tarray:
			break;

		case TY.Tsarray:
			e = addressElem(e, t);
			dim = cast(uint)(cast(TypeSArray)t).dim.toInteger();
			e = el_pair(TYM.TYullong, el_long(TYM.TYint, dim), e);
			break;

		default:
		L1:
			switch (e.Eoper)
			{
				case OPER.OPconst:
				{
					size_t len = tysize[tybasic(e.Ety)];
					elem* es = el_calloc();
					es.Eoper = OPER.OPstring;

					// Match MEM_PH_FREE for OPstring in ztc\el.c
					es.EV.ss.Vstring = cast(char*)malloc(len);
					memcpy(es.EV.ss.Vstring, &e.EV, len);

					es.EV.ss.Vstrlen = len;
					es.Ety = TYM.TYnptr;
					e = es;
					break;
				}

				case OPER.OPvar:
					e = el_una(OPER.OPaddr, TYM.TYnptr, e);
					break;

				case OPER.OPcomma:
					ef = el_combine(ef, e.E1);
					ex = e;
					e = e.E2;
					ex.E1() = null;
					ex.E2() = null;
					el_free(ex);
					goto L1;

				case OPER.OPind:
					ex = e;
					e = e.E1;
					ex.E1() = null;
					ex.E2() = null;
					el_free(ex);
					break;

				default:
				{
					// Copy expression to a variable and take the
					// address of that variable.
					Symbol* stmp;
					tym_t ty = tybasic(e.Ety);

					if (ty == TYM.TYstruct)
					{
						if (e.Enumbytes == 4)
							ty = TYM.TYint;
						else if (e.Enumbytes == 8)
							ty = TYM.TYllong;
					}
					e.Ety = ty;
					stmp = symbol_genauto(type_fake(ty));
					e = el_bin(OPER.OPeq, e.Ety, el_var(stmp), e);
					e = el_bin(OPER.OPcomma, TYM.TYnptr, e, el_una(OPER.OPaddr, TYM.TYnptr, el_var(stmp)));
					break;
				}
			}
			dim = 1;
			e = el_pair(TYM.TYullong, el_long(TYM.TYint, dim), e);
			break;
    }

    return el_combine(ef, e);
}

/************************************
 */
elem* sarray_toDarray(Loc loc, Type tfrom, Type tto, elem* e)
{
    //printf("sarray_toDarray()\n");
    //elem_print(e);

    uint dim = cast(uint)(cast(TypeSArray)tfrom).dim.toInteger();

    if (tto)
    {
		uint fsize = cast(uint)tfrom.nextOf().size();
		uint tsize = cast(uint)tto.nextOf().size();

		if ((dim * fsize) % tsize != 0)
		{
		  Lerr:
			error(loc, "cannot cast %s to %s since sizes don't line up", tfrom.toChars(), tto.toChars());
		}
		dim = (dim * fsize) / tsize;
	}

  L1:
    elem* elen = el_long(TYM.TYint, dim);
    e = addressElem(e, tfrom);
    e = el_pair(TYM.TYullong, elen, e);
    return e;
}

elem* eval_Darray(IRState* irs, Expression e)
{
    elem* ex = e.toElem(irs);
    return array_toDarray(e.type, ex);
}

/***********************************************
 * Generate code to set index into scope table.
 */

void setScopeIndex(Blockx* blx, block* b, int scope_index)
{
version (SEH) {
    block_appendexp(b, nteh_setScopeTableIndex(blx, scope_index));
}
}

/****************************************
 * Create a static symbol we can hang DT initializers onto.
 */

Symbol* static_sym()
{
    Symbol* s;
    type* t;

    t = type_alloc(TYint);
    t.Tcount++;
    s = symbol_calloc("internal");
    s.Sclass = SCstatic;
    s.Sfl = FLextern;
    s.Sflags |= SFLnodebug;
    s.Stype = t;
version (ELFOBJ_OR_MACHOBJ) {
    s.Sseg = Segment.DATA;
}
    slist_add(s);
    return s;
}

/**************************************
 * Convert label to block.
 */

block* labelToBlock(Loc loc, Blockx *blx, LabelDsymbol label)
{
    LabelStatement s;

    if (!label.statement)
    {
		error(loc, "undefined label %s", label.toChars());
		return null;
    }

    s = label.statement;
    if (!s.lblock)
    {
		s.lblock = block_calloc(blx);
		if (s.isReturnLabel)
			s.lblock.Btry = null;
    }
    return s.lblock;
}

/*******************************************
 * Generate elem to zero fill contents of Symbol stmp
 * from *poffset..offset2.
 * May store anywhere from 0..maxoff, as this function
 * tries to use aligned int stores whereever possible.
 * Update *poffset to end of initialized hole; *poffset will be >= offset2.
 */

elem* fillHole(Symbol* stmp, size_t* poffset, size_t offset2, size_t maxoff)
{
	elem* e = null;
    int basealign = 1;

    while (*poffset < offset2)
    {
		tym_t ty;
		elem* e1;

		if (tybasic(stmp.Stype.Tty) == TYnptr)
			e1 = el_var(stmp);
		else
			e1 = el_ptr(stmp);

		if (basealign)
			*poffset &= ~3;

		basealign = 1;
		size_t sz = maxoff - *poffset;
		switch (sz)
		{
			case 1: ty = TYchar;	break;
			case 2: ty = TYshort;	break;
			case 3:
				ty = TYshort;
				basealign = 0;
				break;
			default:
				ty = TYlong;
				break;
		}
		e1 = el_bin(OPadd, TYnptr, e1, el_long(TYsize_t, *poffset));
		e1 = el_una(OPind, ty, e1);
		e1 = el_bin(OPeq, ty, e1, el_long(ty, 0));
		e = el_combine(e, e1);
		*poffset += tysize[ty];
    }
    return e;
}
