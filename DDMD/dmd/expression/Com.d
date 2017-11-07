module dmd.expression.Com;

import dmd.common;
import dmd.Expression;
import dmd.Type;
import dmd.IntegerExp;
import dmd.Loc;

Expression Com(Type type, Expression e1)
{
    Loc loc = e1.loc;
    return new IntegerExp(loc, ~e1.toInteger(), type);
}