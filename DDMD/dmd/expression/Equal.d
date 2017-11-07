module dmd.expression.Equal;

import dmd.common;
import dmd.Expression;
import dmd.Type;
import dmd.TOK;
import dmd.TY;
import dmd.Loc;
import dmd.StringExp;
import dmd.GlobalExpressions;
import dmd.ArrayLiteralExp;
import dmd.StructLiteralExp;
import dmd.Global;
import dmd.IntegerExp;

import core.stdc.string;

/* Also returns EXP_CANT_INTERPRET if cannot be computed.
 */
Expression Equal(TOK op, Type type, Expression e1, Expression e2)
{   
	Expression e;
    Loc loc = e1.loc;
    bool cmp;
    real r1;
    real r2;

    //printf("Equal(e1 = %s, e2 = %s)\n", e1.toChars(), e2.toChars());

    assert(op == TOK.TOKequal || op == TOK.TOKnotequal);

    if (e1.op == TOK.TOKnull)
    {
		if (e2.op == TOK.TOKnull)
			cmp = true;
		else if (e2.op == TOK.TOKstring)
		{   StringExp es2 = cast(StringExp)e2;
			cmp = (0 == es2.len);
		}
		else if (e2.op == TOK.TOKarrayliteral)
		{   
			ArrayLiteralExp es2 = cast(ArrayLiteralExp)e2;
			cmp = !es2.elements || (0 == es2.elements.dim);
		}
		else
			return EXP_CANT_INTERPRET;
    }
    else if (e2.op == TOK.TOKnull)
    {
		if (e1.op == TOK.TOKstring)
		{   
			StringExp es1 = cast(StringExp)e1;
			cmp = (0 == es1.len);
		}
		else if (e1.op == TOK.TOKarrayliteral)
		{   
			ArrayLiteralExp es1 = cast(ArrayLiteralExp)e1;
			cmp = !es1.elements || (0 == es1.elements.dim);
		}
		else
			return EXP_CANT_INTERPRET;
    }
    else if (e1.op == TOK.TOKstring && e2.op == TOK.TOKstring)
    {	
		StringExp es1 = cast(StringExp)e1;
		StringExp es2 = cast(StringExp)e2;

		if (es1.sz != es2.sz)
		{
			assert(global.errors);
			return EXP_CANT_INTERPRET;
		}
		if (es1.len == es2.len && memcmp(es1.string_, es2.string_, es1.sz * es1.len) == 0)
			cmp = true;
		else
			cmp = false;
    }
    else if (e1.op == TOK.TOKarrayliteral && e2.op == TOK.TOKarrayliteral)
    {   
		ArrayLiteralExp es1 = cast(ArrayLiteralExp)e1;
		ArrayLiteralExp es2 = cast(ArrayLiteralExp)e2;

		if ((!es1.elements || !es1.elements.dim) && (!es2.elements || !es2.elements.dim))
			cmp = true;		// both arrays are empty
		else if (!es1.elements || !es2.elements)
			cmp = false;
		else if (es1.elements.dim != es2.elements.dim)
			cmp = false;
		else
		{
			for (size_t i = 0; i < es1.elements.dim; i++)
			{   
				auto ee1 = es1.elements[i];
				auto ee2 = es2.elements[i];

				auto v = Equal(TOK.TOKequal, Type.tint32, ee1, ee2);
				if (v is EXP_CANT_INTERPRET)
					return EXP_CANT_INTERPRET;
				long tmp = v.toInteger();
				cmp = (tmp != 0);
				if (!cmp)
					break;
			}
		}
    }
    else if (e1.op == TOK.TOKarrayliteral && e2.op == TOK.TOKstring)
    {	
		// Swap operands and use common code
		Expression ee = e1;
		e1 = e2;
		e2 = ee;
		goto Lsa;
    }
    else if (e1.op == TOK.TOKstring && e2.op == TOK.TOKarrayliteral)
    {
     Lsa:
		StringExp es1 = cast(StringExp)e1;
		ArrayLiteralExp es2 = cast(ArrayLiteralExp)e2;
		size_t dim1 = es1.len;
		size_t dim2 = es2.elements ? es2.elements.dim : 0;
		if (dim1 != dim2)
			cmp = false;
		else
		{
			for (size_t i = 0; i < dim1; i++)
			{
				ulong c = es1.charAt(i);
				auto ee2 = es2.elements[i];
				if (ee2.isConst() != 1)
					return EXP_CANT_INTERPRET;
				cmp = (c == ee2.toInteger());
				if (!cmp)
					break;
			}
		}
    }
    else if (e1.op == TOK.TOKstructliteral && e2.op == TOK.TOKstructliteral)
    {   
		StructLiteralExp es1 = cast(StructLiteralExp)e1;
		StructLiteralExp es2 = cast(StructLiteralExp)e2;

		if (es1.sd != es2.sd)
			cmp = false;
		else if ((!es1.elements || !es1.elements.dim) && (!es2.elements || !es2.elements.dim))
			cmp = true;		// both arrays are empty
		else if (!es1.elements || !es2.elements)
			cmp = false;
		else if (es1.elements.dim != es2.elements.dim)
			cmp = false;
		else
		{
			cmp = true;
			for (size_t i = 0; i < es1.elements.dim; i++)
			{   
				auto ee1 = es1.elements[i];
				auto ee2 = es2.elements[i];

				if (ee1 == ee2)
					continue;
				if (!ee1 || !ee2)
				{   
					cmp = false;
					break;
				}
				Expression v = Equal(TOK.TOKequal, Type.tint32, ee1, ee2);
				if (v is EXP_CANT_INTERPRET)
					return EXP_CANT_INTERPRET;
				long tmp = v.toInteger();
				cmp = (tmp != 0);
				if (!cmp)
					break;
			}
		}
    }
///static if (false) {
///    else if (e1.op == TOKarrayliteral && e2.op == TOKstring)
///    {
///    }
///}
    else if (e1.isConst() != 1 || e2.isConst() != 1)
		return EXP_CANT_INTERPRET;
    else if (e1.type.isreal())
    {
		r1 = e1.toReal();
		r2 = e2.toReal();
		goto L1;
    }
    else if (e1.type.isimaginary())
    {
		r1 = e1.toImaginary();
		r2 = e2.toImaginary();
	L1:
		cmp = (r1 == r2);
    }
    else if (e1.type.iscomplex())
    {
		cmp = (e1.toComplex() == e2.toComplex());
    }
    else if (e1.type.isintegral() || e1.type.ty == Tpointer)
    {
		cmp = (e1.toInteger() == e2.toInteger());
    }
    else
		return EXP_CANT_INTERPRET;
    if (op == TOK.TOKnotequal)
		cmp = !cmp;

    e = new IntegerExp(loc, cmp, type);

    return e;
}