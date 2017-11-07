module dmd.AssocArrayLiteralExp;

import dmd.common;
import dmd.Expression;
import dmd.GlobalExpressions;
import dmd.WANT;
import dmd.expression.Equal;
import dmd.backend.elem;
import dmd.InterState;
import dmd.MATCH;
import dmd.Type;
import dmd.TypeAArray;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.InlineCostState;
import dmd.IRState;
import dmd.TY;
import dmd.InlineDoState;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.ArrayTypes;
import dmd.TOK;
import dmd.PREC;
import dmd.expression.Util;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.mTY;
import dmd.backend.OPER;
import dmd.backend.RTLSYM;

import dmd.DDMDExtensions;

class AssocArrayLiteralExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Expressions keys;
	Expressions values;

	this(Loc loc, Expressions keys, Expressions values)
	{
		register();

		super(loc, TOK.TOKassocarrayliteral, this.sizeof);
		assert(keys.dim == values.dim);
		this.keys = keys;
		this.values = values;	
	}

	override Expression syntaxCopy()
	{
		return new AssocArrayLiteralExp(loc,
				arraySyntaxCopy(keys), arraySyntaxCopy(values));
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

		version (LOGSEMANTIC) {
			printf("AssocArrayLiteralExp.semantic('%s')\n", toChars());
		}

		if (type)
			return this;

		// Run semantic() on each element
		arrayExpressionSemantic(keys, sc);
		arrayExpressionSemantic(values, sc);
		expandTuples(keys);
		expandTuples(values);
		if (keys.dim != values.dim)
		{
			error("number of keys is %u, must match number of values %u", keys.dim, values.dim);
			keys.setDim(0);
			values.setDim(0);
		}
		
		Type tkey;
		Type tvalue;
		keys = arrayExpressionToCommonType(sc, keys, &tkey);
		values = arrayExpressionToCommonType(sc, values, &tvalue);
		
		type = new TypeAArray(tvalue, tkey);
		type = type.semantic(loc, sc);
		return this;
	}

	override bool isBool(bool result)
	{
		size_t dim = keys.dim;
		return result ? (dim != 0) : (dim == 0);
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;
		size_t dim;

		//printf("AssocArrayLiteralExp.toElem() %s\n", toChars());
		dim = keys.dim;
		e = el_long(TYint, dim);
		for (size_t i = 0; i < dim; i++)
		{   
			auto el = keys[i];

			for (int j = 0; j < 2; j++)
			{
				elem* ep = el.toElem(irs);

				if (tybasic(ep.Ety) == TYstruct || tybasic(ep.Ety) == TYarray)
				{
					ep = el_una(OPstrpar, TYstruct, ep);
					ep.Enumbytes = cast(uint)el.type.size();
				}
		//printf("[%d] %s\n", i, el.toChars());
		//elem_print(ep);
				e = el_param(ep, e);
				el = values[i];
			}
		}

		Type t = type.toBasetype().mutableOf();
		assert(t.ty == Taarray);
		auto ta = cast(TypeAArray)t;

static if(false)
{
		/* Unfortunately, the hash function for Aa (array of chars) is custom and
		 * different from Axa and Aya, which get the generic hash function.
		 * So, rewrite the type of the AArray so that if it's key type
		 * is an array of const or invariant, make it an array of mutable.
		 */
		Type tkey = ta.index.toBasetype();
		if (tkey.ty == Tarray)
		{
			tkey = tkey.nextOf().mutableOf().arrayOf();
			tkey = tkey.semantic(Loc(0), null);
			ta = new TypeAArray(ta.nextOf(), tkey);
			ta = cast(TypeAArray)ta.merge();
		}
}

		e = el_param(e, ta.getTypeInfo(null).toElem(irs));

		// call _d_assocarrayliteralT(ti, dim, ...)
		e = el_bin(OPcall,TYnptr,el_var(rtlsym[RTLSYM_ASSOCARRAYLITERALT]),e);

		el_setLoc(e,loc);
		return e;
	}

	override bool checkSideEffect(int flag)
	{
		bool f = false;

		for (size_t i = 0; i < keys.dim; i++)
		{	auto key = keys[i];
			auto value = values[i];

			f |= key.checkSideEffect(2);
			f |= value.checkSideEffect(2);
		}
		if (flag == 0 && f == 0)
			Expression.checkSideEffect(0);
		return f;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writeByte('[');
		for (size_t i = 0; i < keys.dim; i++)
		{	auto key = keys[i];
			auto value = values[i];

			if (i)
				buf.writeByte(',');
			expToCBuffer(buf, hgs, key, PREC.PREC_assign);
			buf.writeByte(':');
			expToCBuffer(buf, hgs, value, PREC.PREC_assign);
		}
		buf.writeByte(']');
	}

	override void toMangleBuffer(OutBuffer buf)
	{
		size_t dim = keys.dim;
		buf.printf("A%u", dim);
		for (size_t i = 0; i < dim; i++)
		{	auto key = keys[i];
			auto value = values[i];

			key.toMangleBuffer(buf);
			value.toMangleBuffer(buf);
		}
	}

	override void scanForNestedRef(Scope sc)
	{
		assert(false);
	}

	override Expression optimize(int result)
	{
		assert(keys.dim == values.dim);
		foreach (size_t i, Expression e; keys)
		{   
			e = e.optimize(WANTvalue | (result & WANTinterpret));
			keys[i] = e;

			e = values[i];
			e = e.optimize(WANTvalue | (result & WANTinterpret));
			values[i] = e;
		}
		return this;
	}

	override Expression interpret(InterState istate)
	{
		Expressions keysx = keys;
		Expressions valuesx = values;

version (LOG) {
		printf("AssocArrayLiteralExp.interpret() %s\n", toChars());
}
		for (size_t i = 0; i < keys.dim; i++)
		{   
			auto ekey = keys[i];
			auto evalue = values[i];
			Expression ex;

			ex = ekey.interpret(istate);
			if (ex is EXP_CANT_INTERPRET)
				goto Lerr;

			/* If any changes, do Copy On Write
			 */
			if (ex != ekey)
			{
				if (keysx == keys)
					keysx = cast(Expressions)keys.copy();
				keysx[i] = ex;
			}

			ex = evalue.interpret(istate);
			if (ex is EXP_CANT_INTERPRET)
				goto Lerr;

			/* If any changes, do Copy On Write
			 */
			if (ex != evalue)
			{
				if (valuesx == values)
				valuesx = values.copy();
				valuesx[i] = ex;
			}
		}
		
		if (keysx != keys)
			expandTuples(keysx);
		if (valuesx != values)
			expandTuples(valuesx);
		if (keysx.dim != valuesx.dim)
			goto Lerr;

		/* Remove duplicate keys
		 */
		for (size_t i = 1; i < keysx.dim; i++)
		{   
			auto ekey = keysx[i - 1];

			for (size_t j = i; j < keysx.dim; j++)
			{   
				auto ekey2 = keysx[j];
				Expression ex = Equal(TOKequal, Type.tbool, ekey, ekey2);
				if (ex is EXP_CANT_INTERPRET)
					goto Lerr;
				if (ex.isBool(true))	// if a match
				{
					// Remove ekey
					if (keysx == keys)
						keysx = cast(Expressions)keys.copy();
					if (valuesx == values)
						valuesx = cast(Expressions)values.copy();
					keysx.remove(i - 1);
					valuesx.remove(i - 1);
					i -= 1;		// redo the i'th iteration
					break;
				}
			}
		}

		if (keysx != keys || valuesx != values)
		{
			AssocArrayLiteralExp ae;
			ae = new AssocArrayLiteralExp(loc, keysx, valuesx);
			ae.type = type;
			return ae;
		}
		return this;

	Lerr:
		if (keysx != keys)
			delete keysx;
		if (valuesx != values)
			delete values;
		return EXP_CANT_INTERPRET;
	}

	override MATCH implicitConvTo(Type t)
	{
		MATCH result = MATCHexact;

		Type typeb = type.toBasetype();
		Type tb = t.toBasetype();
		if (tb.ty == Taarray && typeb.ty == Taarray)
		{
			for (size_t i = 0; i < keys.dim; i++)
			{   
				auto e = keys[i];
				auto m = cast(MATCH)e.implicitConvTo((cast(TypeAArray)tb).index);
				if (m < result)
					result = m;			// remember worst match
				if (result == MATCHnomatch)
					break;				// no need to check for worse
				e = values[i];
				m = cast(MATCH)e.implicitConvTo(tb.nextOf());
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
		if (type == t)
			return this;
		AssocArrayLiteralExp e = this;
		Type typeb = type.toBasetype();
		Type tb = t.toBasetype();
		if (tb.ty == Taarray && typeb.ty == Taarray && tb.nextOf().toBasetype().ty != Tvoid)
		{
			e = cast(AssocArrayLiteralExp)copy();
			e.keys = cast(Expressions)keys.copy();
			e.values = cast(Expressions)values.copy();
			assert(keys.dim == values.dim);
			for (size_t i = 0; i < keys.dim; i++)
			{   
				auto ex = values[i];
				ex = ex.castTo(sc, tb.nextOf());
				e.values[i] = ex;

				ex = keys[i];
				ex = ex.castTo(sc, (cast(TypeAArray)tb).index);
				e.keys[i] = ex;
			}
			e.type = t;
			return e;
		}
	L1:
		return e.Expression.castTo(sc, t);
	}

	override bool canThrow()
	{
		return true;
	}

	override int inlineCost(InlineCostState* ics)
	{
		assert(false);
	}

	override Expression doInline(InlineDoState ids)
	{
		assert(false);
	}

	override Expression inlineScan(InlineScanState* iss)
	{
		assert(false);
	}
}
