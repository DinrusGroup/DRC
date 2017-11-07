module dmd.expression.Identity;

import dmd.common;
import dmd.Expression;
import dmd.Type;
import dmd.TOK;
import dmd.Loc;
import dmd.SymOffExp;
import dmd.IntegerExp;

import dmd.expression.Equal;

Expression Identity(TOK op, Type type, Expression e1, Expression e2)
{   
	Expression e;
    Loc loc = e1.loc;
    int cmp;

    if (e1.op == TOK.TOKnull)
    {
		cmp = (e2.op == TOK.TOKnull);
    }
    else if (e2.op == TOK.TOKnull)
    {
		cmp = 0;
    }
    else if (e1.op == TOK.TOKsymoff && e2.op == TOK.TOKsymoff)
    {
		SymOffExp es1 = cast(SymOffExp)e1;
		SymOffExp es2 = cast(SymOffExp)e2;

		cmp = (es1.var == es2.var && es1.offset == es2.offset);
    }
    else if (e1.isConst() == 1 && e2.isConst() == 1)
		return Equal((op == TOK.TOKidentity) ? TOK.TOKequal : TOK.TOKnotequal, type, e1, e2);
    else
		assert(0);

    if (op == TOK.TOKnotidentity)
		cmp ^= 1;

    return new IntegerExp(loc, cmp, type);
}