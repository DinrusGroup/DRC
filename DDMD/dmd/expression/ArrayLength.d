module dmd.expression.ArrayLength;

import dmd.common;
import dmd.Type;
import dmd.Expression;
import dmd.StringExp;
import dmd.IntegerExp;
import dmd.ArrayLiteralExp;
import dmd.Loc;
import dmd.TOK;
import dmd.AssocArrayLiteralExp;
import dmd.GlobalExpressions;
import dmd.XorExp;
import dmd.UshrExp;
import dmd.ShrExp;
import dmd.ShlExp;
import dmd.OrExp;
import dmd.MulExp;
import dmd.ModExp;
import dmd.MinExp;
import dmd.AddExp;
import dmd.DivExp;
import dmd.AndExp;

Expression ArrayLength(Type type, Expression e1)
{
	Expression e;
    Loc loc = e1.loc;

    if (e1.op == TOKstring)
    {	
		StringExp es1 = cast(StringExp)e1;
		e = new IntegerExp(loc, es1.len, type);
    }
    else if (e1.op == TOKarrayliteral)
    {
		ArrayLiteralExp ale = cast(ArrayLiteralExp)e1;
		size_t dim = ale.elements ? ale.elements.dim : 0;
		e = new IntegerExp(loc, dim, type);
    }
    else if (e1.op == TOKassocarrayliteral)
    {	
		AssocArrayLiteralExp ale = cast(AssocArrayLiteralExp)e1;
		size_t dim = ale.keys.dim;
		e = new IntegerExp(loc, dim, type);
    }
    else
		e = EXP_CANT_INTERPRET;

    return e;
}