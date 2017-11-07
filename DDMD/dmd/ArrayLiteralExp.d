module dmd.ArrayLiteralExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.InterState;
import dmd.MATCH;
import dmd.Type;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.WANT;
import dmd.Scope;
import dmd.InlineCostState;
import dmd.IRState;
import dmd.InlineDoState;
import dmd.HdrGenState;
import dmd.backend.dt_t;
import dmd.InlineScanState;
import dmd.GlobalExpressions;
import dmd.Array;
import dmd.ArrayTypes;
import dmd.TOK;
import dmd.IntegerExp;
import dmd.TypeSArray;
import dmd.TY;
import dmd.StringExp;

import dmd.expression.Util;
import dmd.backend.Util;
import dmd.backend.RTLSYM;
import dmd.backend.OPER;
import dmd.backend.Symbol;
import dmd.backend.TYM;
import dmd.backend.mTY;
import dmd.codegen.Util;

import dmd.DDMDExtensions;

class ArrayLiteralExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Expressions elements;

	this(Loc loc, Expressions elements)
	{
		register();
		super(loc, TOK.TOKarrayliteral, ArrayLiteralExp.sizeof);
		this.elements = elements;
	}

	this(Loc loc, Expression e)
	{
		register();
		super(loc, TOK.TOKarrayliteral, ArrayLiteralExp.sizeof);
		elements = new Expressions();
		elements.push(e);
	}

	override Expression syntaxCopy()
	{
		return new ArrayLiteralExp(loc, arraySyntaxCopy(elements));
	}

	override Expression semantic(Scope sc)
	{
	version (LOGSEMANTIC) {
		printf("ArrayLiteralExp.semantic('%s')\n", toChars());
	}
		if (type)
			return this;

		arrayExpressionSemantic(elements, sc);    // run semantic() on each element

		expandTuples(elements);

		Type t0;
		elements = arrayExpressionToCommonType(sc, elements, &t0);
		
		type = new TypeSArray(t0, new IntegerExp(elements.dim));
		type = type.semantic(loc, sc);
		return this;
	}

	override bool isBool(bool result)
	{
		size_t dim = elements ? elements.dim : 0;
		return result ? (dim != 0) : (dim == 0);
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;
		size_t dim;

		//printf("ArrayLiteralExp.toElem() %s\n", toChars());
		if (elements)
		{
			scope args = new Array(); // ddmd was Expressions
			dim = elements.dim;
			args.setDim(dim + 1);		// +1 for number of args parameter
			e = el_long(TYint, dim);
			args.data[dim] = cast(void*)e;
			for (size_t i = 0; i < dim; i++)
			{   
				auto el = elements[i];
				elem* ep = el.toElem(irs);

				if (tybasic(ep.Ety) == TYstruct || tybasic(ep.Ety) == TYarray)
				{
					ep = el_una(OPstrpar, TYstruct, ep);
					ep.Enumbytes = cast(uint)el.type.size();
				}
				args.data[dim - (i + 1)] = cast(void *)ep;
			}

			/* Because the number of parameters can get very large, produce
			 * a balanced binary tree so we don't blow up the stack in
			 * the subsequent tree walking code.
			 */
			e = el_params(args.data, dim + 1);
		}
		else
		{	
			dim = 0;
			e = el_long(TYint, 0);
		}
		Type tb = type.toBasetype();
	static if (true) {
		e = el_param(e, type.getTypeInfo(null).toElem(irs));

		// call _d_arrayliteralT(ti, dim, ...)
		e = el_bin(OPcall,TYnptr,el_var(rtlsym[RTLSYM_ARRAYLITERALT]),e);
	} else {
		e = el_param(e, el_long(TYint, tb.next.size()));

		// call _d_arrayliteral(size, dim, ...)
		e = el_bin(OPcall,TYnptr,el_var(rtlsym[RTLSYM_ARRAYLITERAL]),e);
	}
		if (tb.ty == Tarray)
		{
			e = el_pair(TYullong, el_long(TYint, dim), e);
		}
		else if (tb.ty == Tpointer)
		{
		}
		else
		{
			e = el_una(OPind,TYstruct,e);
			e.Enumbytes = cast(uint)type.size();
		}

		el_setLoc(e,loc);
		return e;
	}

	override bool checkSideEffect(int flag)
	{
		bool f = false;

		foreach (e; elements)
		{	
			f |= e.checkSideEffect(2);
		}
		if (flag == 0 && f == false)
			Expression.checkSideEffect(0);

		return f;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writeByte('[');
		argsToCBuffer(buf, elements, hgs);
		buf.writeByte(']');
	}

	override void toMangleBuffer(OutBuffer buf)
	{
		size_t dim = elements ? elements.dim : 0;
		buf.printf("A%d", dim);	///
		for (size_t i = 0; i < dim; i++)
		{	
			auto e = elements[i];
			e.toMangleBuffer(buf);
		}
	}

	override void scanForNestedRef(Scope sc)
	{
		assert(false);
	}

	override Expression optimize(int result)
	{
		if (elements)
		{
			foreach (ref Expression e; elements)
			{   
				e = e.optimize(WANTvalue | (result & WANTinterpret));
			}
		}

		return this;
	}

	override Expression interpret(InterState istate)
	{
		Expressions expsx = null;

version (LOG) {
		printf("ArrayLiteralExp.interpret() %.*s\n", toChars());
}
		if (elements)
		{
			foreach (size_t i, Expression e; elements)
			{   
				Expression ex;

				ex = e.interpret(istate);
				if (ex is EXP_CANT_INTERPRET)
				    goto Lerror;

				/* If any changes, do Copy On Write
				 */
				if (ex != e)
				{
					if (!expsx)
					{
						expsx = new Expressions();
						expsx.setDim(elements.dim);
						for (size_t j = 0; j < elements.dim; j++)
						{
							expsx[j] = elements[j];
						}
					}
					expsx[i] = ex;
				}
			}
		}
		if (elements && expsx)
		{
			expandTuples(expsx);
			if (expsx.dim != elements.dim)
			    goto Lerror;
			
			ArrayLiteralExp ae = new ArrayLiteralExp(loc, expsx);
			ae.type = type;
			
			return ae;
		}
		return this;

    Lerror:
        if (expsx)
	        delete expsx;
        error("cannot interpret array literal");
        return EXP_CANT_INTERPRET;
	}

	override MATCH implicitConvTo(Type t)
	{
		MATCH result = MATCHexact;

	static if (false) {
		printf("ArrayLiteralExp.implicitConvTo(this=%s, type=%s, t=%s)\n",
		toChars(), type.toChars(), t.toChars());
	}
		Type typeb = type.toBasetype();
		Type tb = t.toBasetype();
		if ((tb.ty == Tarray || tb.ty == Tsarray) &&
			(typeb.ty == Tarray || typeb.ty == Tsarray))
		{
			if (tb.ty == Tsarray)
			{   
				TypeSArray tsa = cast(TypeSArray)tb;
				if (elements.dim != tsa.dim.toInteger())
					result = MATCHnomatch;
			}

			foreach (e; elements)
			{
				auto m = cast(MATCH)e.implicitConvTo(tb.nextOf());
				if (m < result)
					result = m;			// remember worst match
				if (result == MATCHnomatch)
					break;				// no need to check for worse
			}
			return result;
		}
		else
			return Expression.implicitConvTo(t);
	}

	override Expression castTo(Scope sc, Type t)
	{
	static if (false) {
		printf("ArrayLiteralExp.castTo(this=%s, type=%s, => %s)\n",
		toChars(), type.toChars(), t.toChars());
	}
		if (type == t)
			return this;
		ArrayLiteralExp e = this;
		Type typeb = type.toBasetype();
		Type tb = t.toBasetype();
		if ((tb.ty == Tarray || tb.ty == Tsarray) &&
			(typeb.ty == Tarray || typeb.ty == Tsarray) &&
			// Not trying to convert non-void[] to void[]
			!(tb.nextOf().toBasetype().ty == Tvoid && typeb.nextOf().toBasetype().ty != Tvoid))
		{
			if (tb.ty == Tsarray)
			{   
				TypeSArray tsa = cast(TypeSArray)tb;
				if (elements.dim != tsa.dim.toInteger())
					goto L1;
			}

			e = cast(ArrayLiteralExp)copy();
			e.elements = elements.copy();
			foreach (size_t i, Expression ex; elements)
			{   
				e.elements[i] = ex.castTo(sc, tb.nextOf());
			}
			e.type = t;
			return e;
		}
		if (tb.ty == Tpointer && typeb.ty == Tsarray)
		{
			Type tp = typeb.nextOf().pointerTo();
			if (!tp.equals(e.type))
			{   
				e = cast(ArrayLiteralExp)copy();
				e.type = tp;
			}
		}
	L1:
		return e.Expression.castTo(sc, t);
	}

	override dt_t** toDt(dt_t** pdt)
	{
		//printf("ArrayLiteralExp.toDt() '%s', type = %s\n", toChars(), type.toChars());

		dt_t *d;
		dt_t **pdtend;

		d = null;
		pdtend = &d;
		foreach (e; elements)
		{	
			pdtend = e.toDt(pdtend);
		}
		Type t = type.toBasetype();

		switch (t.ty)
		{
			case Tsarray:
				pdt = dtcat(pdt, d);
				break;

			case Tpointer:
			case Tarray:
				if (t.ty == Tarray)
					dtdword(pdt, elements.dim);
				if (d)
				{
					// Create symbol, and then refer to it
					Symbol* s;
					s = static_sym();
					s.Sdt = d;
					outdata(s);

					dtxoff(pdt, s, 0, TYnptr);
				}
				else
					dtdword(pdt, 0);

				break;

			default:
				assert(0);
		}
		return pdt;
	}

version (DMDV2) {
	override bool canThrow()
	{
		return 1;	// because it can fail allocating memory
	}
}
	override int inlineCost(InlineCostState* ics)
	{
		return 1 + arrayInlineCost(ics, elements);
	}

	override Expression doInline(InlineDoState ids)
	{
		ArrayLiteralExp ce = cast(ArrayLiteralExp)copy();
		ce.elements = arrayExpressiondoInline(elements, ids);
		return ce;
	}

	override Expression inlineScan(InlineScanState* iss)
	{
		Expression e = this;

		//printf("ArrayLiteralExp.inlineScan()\n");
		arrayInlineScan(iss, elements);

		return e;
	}
}

