module dmd.expression.Index;

import dmd.common;
import dmd.Type;
import dmd.Loc;
import dmd.StringExp;
import dmd.TOK;
import dmd.Expression;
import dmd.GlobalExpressions;
import dmd.IntegerExp;
import dmd.TY;
import dmd.TypeSArray;
import dmd.ArrayLiteralExp;
import dmd.AssocArrayLiteralExp;

import dmd.expression.Equal;

/* Also return EXP_CANT_INTERPRET if this fails
 */
Expression Index(Type type, Expression e1, Expression e2)
{   
	Expression e = EXP_CANT_INTERPRET;
    Loc loc = e1.loc;

    //printf("Index(e1 = %s, e2 = %s)\n", e1.toChars(), e2.toChars());
    assert(e1.type);
    if (e1.op == TOKstring && e2.op == TOKint64)
    {	
		StringExp es1 = cast(StringExp)e1;
		ulong i = e2.toInteger();

		if (i >= es1.len)
			e1.error("string index %ju is out of bounds [0 .. %zu]", i, es1.len);
		else
		{   
			uint value = es1.charAt(cast(uint)i);
			e = new IntegerExp(loc, value, type);
		}
    }
    else if (e1.type.toBasetype().ty == Tsarray && e2.op == TOKint64)
    {	
		TypeSArray tsa = cast(TypeSArray)e1.type.toBasetype();
		ulong length = tsa.dim.toInteger();
		ulong i = e2.toInteger();

		if (i >= length)
		{   
			e2.error("array index %ju is out of bounds %s[0 .. %ju]", i, e1.toChars(), length);
		}
		else if (e1.op == TOKarrayliteral && !e1.checkSideEffect(2))
		{   
			auto ale = cast(ArrayLiteralExp)e1;
			e = ale.elements[cast(uint)i];
			e.type = type;
		}
    }
    else if (e1.type.toBasetype().ty == Tarray && e2.op == TOKint64)
    {
		ulong i = e2.toInteger();

		if (e1.op == TOKarrayliteral && !e1.checkSideEffect(2))
		{   
			auto ale = cast(ArrayLiteralExp)e1;
			if (i >= ale.elements.dim)
			{   
				e2.error("array index %ju is out of bounds %s[0 .. %u]", i, e1.toChars(), ale.elements.dim);
			}
			else
			{	
				e = ale.elements[cast(uint)i];
				e.type = type;
			}
		}
    }
    else if (e1.op == TOKassocarrayliteral && !e1.checkSideEffect(2))
    {
		AssocArrayLiteralExp ae = cast(AssocArrayLiteralExp)e1;
		/* Search the keys backwards, in case there are duplicate keys
		 */
		for (size_t i = ae.keys.dim; i;)
		{
			i--;
			auto ekey = ae.keys[i];
			Expression ex = Equal(TOKequal, Type.tbool, ekey, e2);
			if (ex is EXP_CANT_INTERPRET)
				return ex;
			if (ex.isBool(true))
			{	
				e = ae.values[i];
				e.type = type;
				break;
			}
		}
    }

    return e;
}