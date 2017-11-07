module dmd.AssignExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.backend.elem;
import dmd.InterState;
import dmd.Parameter;
import dmd.IndexExp;
import dmd.CallExp;
import dmd.CastExp;
import dmd.TypeSArray;
import dmd.StructLiteralExp;
import dmd.ArrayLengthExp;
import dmd.TypeStruct;
import dmd.StructDeclaration;
import dmd.VarExp;
import dmd.TY;
import dmd.SliceExp;
import dmd.CommaExp;
import dmd.ArrayExp;
import dmd.AggregateDeclaration;
import dmd.CondExp;
import dmd.DotVarExp;
import dmd.WANT;
import dmd.Id;
import dmd.TypeClass;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.TypeNext;
import dmd.TupleExp;
import dmd.VarDeclaration;
import dmd.Scope;
import dmd.IRState;
import dmd.ArrayTypes;
import dmd.BinExp;
import dmd.TOK;
import dmd.Global;
import dmd.Declaration;
import dmd.TypeFunction;
import dmd.Type;
import dmd.RET;
import dmd.STC;
import dmd.DotIdExp;

import dmd.backend.Util;
import dmd.backend.Symbol;
import dmd.backend.OPER;
import dmd.backend.TYM;
import dmd.backend.RTLSYM;
import dmd.codegen.Util;
import dmd.expression.Util;

import dmd.DDMDExtensions;

class AssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	int ismemset = 0;

	this(Loc loc, Expression e1, Expression e2)
	{
		register();

		super(loc, TOK.TOKassign, AssignExp.sizeof, e1, e2);
	}

	override Expression semantic(Scope sc)
	{
		Expression e1old = e1;

version (LOGSEMANTIC) {
		printf("AssignExp.semantic('%s')\n", toChars());
}
		//printf("e1.op = %d, '%s'\n", e1.op, Token.toChars(e1.op));
		//printf("e2.op = %d, '%s'\n", e2.op, Token.toChars(e2.op));

		if (type)
			return this;

		if (e2.op == TOK.TOKcomma)
		{	
			/* Rewrite to get rid of the comma from rvalue
			 */
			AssignExp ea = new AssignExp(loc, e1, (cast(CommaExp)e2).e2);
			ea.op = op;
			Expression e = new CommaExp(loc, (cast(CommaExp)e2).e1, ea);
			return e.semantic(sc);
		}

		/* Look for operator overloading of a[i]=value.
		 * Do it before semantic() otherwise the a[i] will have been
		 * converted to a.opIndex() already.
		 */
		if (e1.op == TOK.TOKarray)
		{
			ArrayExp ae = cast(ArrayExp)e1;
			AggregateDeclaration ad;
			Identifier id = Id.index;

			ae.e1 = ae.e1.semantic(sc);
			Type t1 = ae.e1.type.toBasetype();
			if (t1.ty == TY.Tstruct)
			{
				ad = (cast(TypeStruct)t1).sym;
				goto L1;
			}
			else if (t1.ty == TY.Tclass)
			{
				ad = (cast(TypeClass)t1).sym;
			  L1:
				// Rewrite (a[i] = value) to (a.opIndexAssign(value, i))
				if (search_function(ad, Id.indexass))
				{	
					Expression e = new DotIdExp(loc, ae.e1, Id.indexass);
					auto a = ae.arguments.copy();

					a.insert(0, e2);
					e = new CallExp(loc, e, a);
					e = e.semantic(sc);
					return e;
				}
				else
				{
					// Rewrite (a[i] = value) to (a.opIndex(i, value))
					if (search_function(ad, id))
					{   
						Expression e = new DotIdExp(loc, ae.e1, id);

						if (1 || !global.params.useDeprecated)
							error("operator [] assignment overload with opIndex(i, value) illegal, use opIndexAssign(value, i)");

						e = new CallExp(loc, e, ae.arguments[0], e2);
						e = e.semantic(sc);
						return e;
					}
				}
			}
		}
		/* Look for operator overloading of a[i..j]=value.
		 * Do it before semantic() otherwise the a[i..j] will have been
		 * converted to a.opSlice() already.
		 */
		if (e1.op == TOK.TOKslice)
		{
			Type t1;
			SliceExp ae = cast(SliceExp)e1;
			AggregateDeclaration ad;
			Identifier id = Id.index;

			ae.e1 = ae.e1.semantic(sc);
			ae.e1 = resolveProperties(sc, ae.e1);
			t1 = ae.e1.type.toBasetype();
			if (t1.ty == TY.Tstruct)
			{
				ad = (cast(TypeStruct)t1).sym;
				goto L2;
			}
			else if (t1.ty == TY.Tclass)
			{
				ad = (cast(TypeClass)t1).sym;
			  L2:
				// Rewrite (a[i..j] = value) to (a.opIndexAssign(value, i, j))
				if (search_function(ad, Id.sliceass))
				{	
					Expression e = new DotIdExp(loc, ae.e1, Id.sliceass);
					Expressions a = new Expressions();

					a.push(e2);
					if (ae.lwr)
					{   
						a.push(ae.lwr);
						assert(ae.upr);
						a.push(ae.upr);
					}
					else
						assert(!ae.upr);

					e = new CallExp(loc, e, a);
					e = e.semantic(sc);
					return e;
				}
			}
		}

		BinExp.semantic(sc);

		if (e1.op == TOK.TOKdottd)
		{	
			// Rewrite a.b=e2, when b is a template, as a.b(e2)
			Expression e = new CallExp(loc, e1, e2);
			e = e.semantic(sc);
			return e;
		}

		e2 = resolveProperties(sc, e2);
		assert(e1.type);

		/* Rewrite tuple assignment as a tuple of assignments.
		 */
		if (e1.op == TOK.TOKtuple && e2.op == TOK.TOKtuple)
		{	
			TupleExp tup1 = cast(TupleExp)e1;
			TupleExp tup2 = cast(TupleExp)e2;
			size_t dim = tup1.exps.dim;
			if (dim != tup2.exps.dim)
			{
				error("mismatched tuple lengths, %d and %d", cast(int)dim, cast(int)tup2.exps.dim);
			}
			else
			{   
				auto exps = new Expressions;
				exps.setDim(dim);

				for (int i = 0; i < dim; i++)
				{	
					auto ex1 = tup1.exps[i];
					auto ex2 = tup2.exps[i];
					exps[i] = new AssignExp(loc, ex1, ex2);
				}
				Expression e = new TupleExp(loc, exps);
				e = e.semantic(sc);
				return e;
			}
		}

		// Determine if this is an initialization of a reference
		int refinit = 0;
		if (op == TOK.TOKconstruct && e1.op == TOK.TOKvar)
		{	
			VarExp ve = cast(VarExp)e1;
			VarDeclaration v = ve.var.isVarDeclaration();
			if (v.storage_class & (STC.STCout | STC.STCref))
				refinit = 1;
		}

		Type t1 = e1.type.toBasetype();

		if (t1.ty == TY.Tfunction)
		{	
			// Rewrite f=value to f(value)
			Expression e = new CallExp(loc, e1, e2);
			e = e.semantic(sc);
			return e;
		}

		/* If it is an assignment from a 'foreign' type,
		 * check for operator overloading.
		 */
		if (t1.ty == TY.Tstruct)
		{
			StructDeclaration sd = (cast(TypeStruct)t1).sym;
			if (op == TOK.TOKassign)
			{
				Expression e = op_overload(sc);
				if (e)
					return e;
			}
			else if (op == TOK.TOKconstruct && !refinit)
			{   
				Type t2 = e2.type.toBasetype();
				if (t2.ty == TY.Tstruct && sd == (cast(TypeStruct)t2).sym && sd.cpctor)
				{	
					/* We have a copy constructor for this
					 */
					if (e2.op == TOK.TOKquestion)
					{   /* Write as:
						 *	a ? e1 = b : e1 = c;
						 */
						CondExp ec = cast(CondExp)e2;
						AssignExp ea1 = new AssignExp(ec.e1.loc, e1, ec.e1);
						ea1.op = op;
						AssignExp ea2 = new AssignExp(ec.e1.loc, e1, ec.e2);
						ea2.op = op;
						Expression e = new CondExp(loc, ec.econd, ea1, ea2);
						return e.semantic(sc);
					}
					else if (e2.op == TOK.TOKvar || e2.op == TOK.TOKdotvar || e2.op == TOK.TOKstar || e2.op == TOK.TOKindex)
					{   /* Write as:
						 *	e1.cpctor(e2);
						 */
						Expression e = new DotVarExp(loc, e1, sd.cpctor, 0);
						e = new CallExp(loc, e, e2);
						return e.semantic(sc);
					}
				}
			}
		}
		else if (t1.ty == TY.Tclass)
		{	
			// Disallow assignment operator overloads for same type
			if (!e2.type.implicitConvTo(e1.type))
			{
				Expression e = op_overload(sc);
				if (e)
					return e;
			}
		}

		if (t1.ty == TY.Tsarray && !refinit)
		{	
			// Convert e1 to e1[]
			Expression e = new SliceExp(e1.loc, e1, null, null);
			e1 = e.semantic(sc);
			t1 = e1.type.toBasetype();
		}

		e2.rvalue();

		if (e1.op == TOK.TOKarraylength)
		{
			// e1 is not an lvalue, but we let code generator handle it
			ArrayLengthExp ale = cast(ArrayLengthExp)e1;
			ale.e1 = ale.e1.modifiableLvalue(sc, e1);
		}
		else if (e1.op == TOK.TOKslice)
		{
			Type tn = e1.type.nextOf();
			if (tn && !tn.isMutable() && op != TOK.TOKconstruct)
				error("slice %s is not mutable", e1.toChars());
		}
		else
		{	
			// Try to do a decent error message with the expression
			// before it got constant folded
			if (e1.op != TOK.TOKvar)
				e1 = e1.optimize(WANT.WANTvalue);

			if (op != TOK.TOKconstruct)
				e1 = e1.modifiableLvalue(sc, e1old);
		}

		Type t2 = e2.type;
		if (e1.op == TOK.TOKslice && t1.nextOf() && e2.implicitConvTo(t1.nextOf()))
		{	
			// memset
			ismemset = 1;	// make it easy for back end to tell what this is
			e2 = e2.implicitCastTo(sc, t1.nextOf());
		}
		else if (t1.ty == TY.Tsarray)
		{
			/* Should have already converted e1 => e1[]
			 */
			assert(op == TOK.TOKconstruct);
			//error("cannot assign to static array %s", e1.toChars());
		}
		else if (e1.op == TOK.TOKslice)
		{
			e2 = e2.implicitCastTo(sc, e1.type.constOf());
		}
		else
		{
			e2 = e2.implicitCastTo(sc, e1.type);
		}

		/* Look for array operations
		 */
		if (e1.op == TOK.TOKslice && !ismemset &&
			(e2.op == TOK.TOKadd || e2.op == TOK.TOKmin ||
			 e2.op == TOK.TOKmul || e2.op == TOK.TOKdiv ||
			 e2.op == TOK.TOKmod || e2.op == TOK.TOKxor ||
			 e2.op == TOK.TOKand || e2.op == TOK.TOKor  ||
			 e2.op == TOK.TOKtilde || e2.op == TOK.TOKneg))
		{
			type = e1.type;
			return arrayOp(sc);
		}

		type = e1.type;
		assert(type);
		return this;
	}

	override Expression checkToBoolean()
	{
		assert(false);
	}

	override Expression interpret(InterState istate)
	{
		return interpretAssignCommon(istate, null);
	}

	override Identifier opId()
	{
		return Id.assign;
	}

	override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		/* Evaluate assign expressions right to left
		 */
		e2.buildArrayIdent(buf, arguments);
		e1.buildArrayIdent(buf, arguments);
		buf.writestring("Assign");
	}

	override Expression buildArrayLoop(Parameters fparams)
	{
		/* Evaluate assign expressions right to left
		 */
		Expression ex2 = e2.buildArrayLoop(fparams);
	version (DMDV2) {
		/* Need the cast because:
		 *   b = c + p[i];
		 * where b is a byte fails because (c + p[i]) is an int
		 * which cannot be implicitly cast to byte.
		 */
		ex2 = new CastExp(Loc(0), ex2, e1.type.nextOf());
	}
		Expression ex1 = e1.buildArrayLoop(fparams);
		auto param = fparams[0];
		param.storageClass = STCundefined;
		Expression e = new AssignExp(Loc(0), ex1, ex2);
		return e;
	}

	override elem* toElem(IRState* irs)
	{
		Type t1b;

		//printf("AssignExp.toElem('%s')\n", toChars());
		t1b = e1.type.toBasetype();

		// Look for array.length = n
		if (e1.op == TOK.TOKarraylength)
		{
			// Generate:
			//	_d_arraysetlength(e2, sizeelem, &ale.e1);

			ArrayLengthExp ale = cast(ArrayLengthExp)e1;

			auto p1 = e2.toElem(irs);
			auto p3 = ale.e1.toElem(irs);
			p3 = addressElem(p3, null);
			Type t1 = ale.e1.type.toBasetype();

			// call _d_arraysetlengthT(ti, e2, &ale.e1);
			auto p2 = t1.getTypeInfo(null).toElem(irs);
			auto ep = el_params(p3, p1, p2, null);	// c function
			int r = t1.nextOf().isZeroInit(Loc(0)) ? RTLSYM.RTLSYM_ARRAYSETLENGTHT : RTLSYM.RTLSYM_ARRAYSETLENGTHIT;

			auto e = el_bin(OPER.OPcall, type.totym(), el_var(rtlsym[r]), ep);
			el_setLoc(e, loc);
			return e;
		}
		
		elem *e;
		IndexExp ae;
		
		// Look for array[]=n
		if (e1.op == TOK.TOKslice)
		{
			Type t1 = t1b;
			Type t2 = e2.type.toBasetype();

			// which we do if the 'next' types match
			if (ismemset)
			{   
				// Do a memset for array[]=v
				//printf("Lpair %s\n", toChars());
				SliceExp are = cast(SliceExp)e1;
				elem* elwr;
				elem* eupr;
				elem* n1;
				elem* evalue;
				elem* enbytes;
				elem* elength;
				elem* einit;
				long value;
				Type ta = are.e1.type.toBasetype();
				Type tb = ta.nextOf().toBasetype();
				int sz = cast(uint)tb.size();
				tym_t tym = type.totym();

				n1 = are.e1.toElem(irs);
				elwr = are.lwr ? are.lwr.toElem(irs) : null;
				eupr = are.upr ? are.upr.toElem(irs) : null;

				elem* n1x = n1;

				// Look for array[]=n
				if (ta.ty == TY.Tsarray)
				{
					TypeSArray ts = cast(TypeSArray)ta;
					n1 = array_toPtr(ta, n1);
					enbytes = ts.dim.toElem(irs);
					n1x = n1;
					n1 = el_same(&n1x);
					einit = resolveLengthVar(are.lengthVar, &n1, ta);
				}
				else if (ta.ty == TY.Tarray)
				{
					n1 = el_same(&n1x);
					einit = resolveLengthVar(are.lengthVar, &n1, ta);
					enbytes = el_copytree(n1);
					n1 = array_toPtr(ta, n1);
					enbytes = el_una(OPER.OP64_32, TYM.TYint, enbytes);
				}
				else if (ta.ty == TY.Tpointer)
				{
					n1 = el_same(&n1x);
					enbytes = el_long(TYM.TYint, -1);	// largest possible index
					einit = null;
				}

				// Enforce order of evaluation of n1[elwr..eupr] as n1,elwr,eupr
				elem* elwrx = elwr;
				if (elwr) elwr = el_same(&elwrx);
				elem* euprx = eupr;
				if (eupr) eupr = el_same(&euprx);

	static if (false) {
				printf("sz = %d\n", sz);
				printf("n1x\n");
				elem_print(n1x);
				printf("einit\n");
				elem_print(einit);
				printf("elwrx\n");
				elem_print(elwrx);
				printf("euprx\n");
				elem_print(euprx);
				printf("n1\n");
				elem_print(n1);
				printf("elwr\n");
				elem_print(elwr);
				printf("eupr\n");
				elem_print(eupr);
				printf("enbytes\n");
				elem_print(enbytes);
	}
				einit = el_combine(n1x, einit);
				einit = el_combine(einit, elwrx);
				einit = el_combine(einit, euprx);

				evalue = this.e2.toElem(irs);

	static if (false) {
				printf("n1\n");
				elem_print(n1);
				printf("enbytes\n");
				elem_print(enbytes);
	}

				if (irs.arrayBoundsCheck() && eupr && ta.ty != TY.Tpointer)
				{
					elem *c1;
					elem *c2;
					elem *ea;
					elem *eb;
					elem *enbytesx;

					assert(elwr);
					enbytesx = enbytes;
					enbytes = el_same(&enbytesx);
					c1 = el_bin(OPER.OPle, TYM.TYint, el_copytree(eupr), enbytesx);
					c2 = el_bin(OPER.OPle, TYM.TYint, el_copytree(elwr), el_copytree(eupr));
					c1 = el_bin(OPER.OPandand, TYM.TYint, c1, c2);

					// Construct: (c1 || ModuleArray(line))
					Symbol *sassert;

					sassert = irs.blx.module_.toModuleArray();
					ea = el_bin(OPER.OPcall,TYM.TYvoid,el_var(sassert), el_long(TYM.TYint, loc.linnum));
					eb = el_bin(OPER.OPoror,TYM.TYvoid,c1,ea);
					einit = el_combine(einit, eb);
				}

				if (elwr)
				{   
					elem *elwr2;

					el_free(enbytes);
					elwr2 = el_copytree(elwr);
					elwr2 = el_bin(OPER.OPmul, TYM.TYint, elwr2, el_long(TYM.TYint, sz));
					n1 = el_bin(OPER.OPadd, TYM.TYnptr, n1, elwr2);
					enbytes = el_bin(OPER.OPmin, TYM.TYint, eupr, elwr);
					elength = el_copytree(enbytes);
				}
				else
					elength = el_copytree(enbytes);

				e = setArray(n1, enbytes, tb, evalue, irs, op);
			Lpair:
				e = el_pair(TYM.TYullong, elength, e);
			Lret2:
				e = el_combine(einit, e);
				//elem_print(e);
				goto Lret;
			}
///static if (false) {
///			else if (e2.op == TOK.TOKadd || e2.op == TOK.TOKmin)
///			{
///				/* It's ea[] = eb[] +- ec[]
///				 */
///				BinExp e2a = cast(BinExp)e2;
///				Type t = e2.type.toBasetype().nextOf().toBasetype();
///				if (t.ty != TY.Tfloat32 && t.ty != TY.Tfloat64 && t.ty != TY.Tfloat80)
///				{
///					e2.error("array add/min for %s not supported", t.toChars());
///					return el_long(TYM.TYint, 0);
///				}
///				elem* ea = e1.toElem(irs);
///				ea = array_toDarray(e1.type, ea);
///				elem* eb = e2a.e1.toElem(irs);
///				eb = array_toDarray(e2a.e1.type, eb);
///				elem* ec = e2a.e2.toElem(irs);
///				ec = array_toDarray(e2a.e2.type, ec);
///
///				int rtl = RTLSYM.RTLSYM_ARRAYASSADDFLOAT;
///				if (t.ty == Tfloat64)
///				rtl = RTLSYM.RTLSYM_ARRAYASSADDDOUBLE;
///				else if (t.ty == Tfloat80)
///				rtl = RTLSYM.RTLSYM_ARRAYASSADDREAL;
///				if (e2.op == TOK.TOKmin)
///				{
///				rtl = RTLSYM.RTLSYM_ARRAYASSMINFLOAT;
///				if (t.ty == Tfloat64)
///					rtl = RTLSYM.RTLSYM_ARRAYASSMINDOUBLE;
///				else if (t.ty == Tfloat80)
///					rtl = RTLSYM.RTLSYM_ARRAYASSMINREAL;
///				}
///
///				/* Set parameters so the order of evaluation is eb, ec, ea
///				 */
///				elem* ep = el_params(eb, ec, ea, null);
///				e = el_bin(OPER.OPcall, type.totym(), el_var(rtlsym[rtl]), ep);
///				goto Lret;
///			}
///}
			else
			{
				/* It's array1[]=array2[]
				 * which is a memcpy
				 */
				elem* ep;

				auto eto = e1.toElem(irs);
				auto efrom = e2.toElem(irs);

				uint size = cast(uint)t1.nextOf().size();
				auto esize = el_long(TYM.TYint, size);

				/* Determine if we need to do postblit
				 */
				int postblit = 0;
				if (needsPostblit(t1))
					postblit = 1;

				assert(e2.type.ty != TY.Tpointer);

				if (!postblit && !irs.arrayBoundsCheck())
				{	
					auto ex = el_same(&eto);

					// Determine if elen is a constant
					elem *elen;
					if (eto.Eoper == OPER.OPpair && eto.E1.Eoper == OPER.OPconst)
					{
						elen = el_copytree(eto.E1);
					}
					else
					{
						// It's not a constant, so pull it from the dynamic array
						elen = el_una(OPER.OP64_32, TYM.TYint, el_copytree(ex));
					}

					esize = el_bin(OPER.OPmul, TYM.TYint, elen, esize);
					auto epto = array_toPtr(e1.type, ex);
					auto epfr = array_toPtr(e2.type, efrom);
	static if (true) {
					// memcpy() is faster, so if we can't beat 'em, join 'em
					e = el_params(esize, epfr, epto, null);
					e = el_bin(OPER.OPcall, TYM.TYnptr, el_var(rtlsym[RTLSYM.RTLSYM_MEMCPY]), e);
	} else {
					e = el_bin(OPER.OPmemcpy, TYM.TYnptr, epto, el_param(epfr, esize));
	}
					e = el_pair(eto.Ety, el_copytree(elen), e);
					e = el_combine(eto, e);
				}
///version (DMDV2) {
				else if (postblit && op != TOK.TOKblit)
				{
					/* Generate:
					 *	_d_arrayassign(ti, efrom, eto)
					 * or:
					 *	_d_arrayctor(ti, efrom, eto)
					 */
					el_free(esize);
					Expression ti = t1.nextOf().toBasetype().getTypeInfo(null);
					ep = el_params(eto, efrom, ti.toElem(irs), null);
					int rtl = (op == TOK.TOKconstruct) ? RTLSYM.RTLSYM_ARRAYCTOR : RTLSYM.RTLSYM_ARRAYASSIGN;
					e = el_bin(OPER.OPcall, type.totym(), el_var(rtlsym[rtl]), ep);
				}
///}
				else
				{
					// Generate:
					//	_d_arraycopy(eto, efrom, esize)

					ep = el_params(eto, efrom, esize, null);
					e = el_bin(OPER.OPcall, type.totym(), el_var(rtlsym[RTLSYM.RTLSYM_ARRAYCOPY]), ep);
				}
				el_setLoc(e, loc);
				return e;
			}
		}

		if (e1.op == TOK.TOKindex)
		{
			elem* eb;
			elem* ei;
			elem* ev;
			TY ty;
			Type ta;

			ae = cast(IndexExp)e1;
			ta = ae.e1.type.toBasetype();
			ty = ta.ty;
		}

version (DMDV2) {
		/* Look for reference initializations
		 */
		if (op == TOK.TOKconstruct && e1.op == TOK.TOKvar)
		{
			VarExp ve = cast(VarExp)e1;
			Declaration s = ve.var;
			if (s.storage_class & STC.STCref)
			{
static if (false) {
				Expression ae = e2.addressOf(null);
				e = ae.toElem(irs);
} else {
				e = e2.toElem(irs);
				e = addressElem(e, e2.type);
}
				elem* es = el_var(s.toSymbol());
				es.Ety = TYM.TYnptr;
				e = el_bin(OPER.OPeq, TYM.TYnptr, es, e);
				// BUG: type is struct, and e2 is TOKint64
				goto Lret;
			}
		}
}

static if (true) {
		/* This will work if we can distinguish an assignment from
		 * an initialization of the lvalue. It'll work if the latter.
		 * If the former, because of aliasing of the return value with
		 * function arguments, it'll fail.
		 */
		if (op == TOK.TOKconstruct && e2.op == TOK.TOKcall)
		{	
			CallExp ce = cast(CallExp)e2;

			Type t = ce.e1.type.toBasetype();
			if (t.ty == TY.Tfunction) {
				TypeFunction tf = cast(TypeFunction)t;
				if (tf.retStyle() == RET.RETstack)
				{
					elem* ehidden = e1.toElem(irs);
					ehidden = el_una(OPER.OPaddr, TYM.TYnptr, ehidden);
					assert(!irs.ehidden);
					irs.ehidden = ehidden;
					e = e2.toElem(irs);
					goto Lret;
				}
			}
		}
}
	//printf("test2 %d\n", op);
	//if (op == TOK.TOKconstruct) printf("construct\n");
		if (t1b.ty == TY.Tstruct)
		{
			elem* eleft = e1.toElem(irs);

			if (e2.op == TOK.TOKint64)
			{   
				/* Implement:
				 *	(struct = 0)
				 * with:
				 *	memset(&struct, 0, struct.sizeof)
				 */
				elem* ey = null;
				int sz = cast(int)e1.type.size();
				StructDeclaration sd = (cast(TypeStruct)t1b).sym;
				if (sd.isnested && op == TOK.TOKconstruct)
				{
					ey = el_una(OPER.OPaddr, TYM.TYnptr, eleft);
					eleft = el_same(&ey);
					ey = setEthis(loc, irs, ey, sd);
					sz = sd.vthis.offset;
				}

				elem *el = eleft;
				elem *enbytes = el_long(TYM.TYint, sz);
				elem *evalue = el_long(TYM.TYint, 0);

				if (!(sd.isnested && op == TOK.TOKconstruct))
					el = el_una(OPER.OPaddr, TYM.TYnptr, el);

				e = el_param(enbytes, evalue);
				e = el_bin(OPER.OPmemset, TYM.TYnptr,el,e);
				e = el_combine(ey, e);
				el_setLoc(e, loc);
				//e = el_una(OPER.OPind, TYM.TYstruct, e);
			}
			else
			{
				//printf("toElemBin() '%s'\n", toChars());

				tym_t tym = type.totym();

				elem* e1 = eleft;
				elem* ex = e1;
				if (e1.Eoper == OPER.OPind)
					ex = e1.E1;

				if (this.e2.op == TOK.TOKstructliteral && ex.Eoper == OPER.OPvar && ex.EV.sp.Voffset == 0)
				{	
					StructLiteralExp se = cast(StructLiteralExp)this.e2;

					Symbol* symSave = se.sym;
					size_t soffsetSave = se.soffset;
					int fillHolesSave = se.fillHoles;

					se.sym = ex.EV.sp.Vsym;
					se.soffset = 0;
					se.fillHoles = (op == TOK.TOKconstruct || op == TOK.TOKblit) ? 1 : 0;

					el_free(e1);
					e = this.e2.toElem(irs);

					se.sym = symSave;
					se.soffset = soffsetSave;
					se.fillHoles = fillHolesSave;
				}
				else
				{
					elem* e2 = this.e2.toElem(irs);
					e = el_bin(OPER.OPstreq,tym,e1,e2);
					e.Enumbytes = cast(uint)this.e1.type.size();
				}
				goto Lret;
			}
		}
		else
			e = toElemBin(irs,OPER.OPeq);

		return e;

	  Lret:
		el_setLoc(e,loc);
		return e;
	}
}

