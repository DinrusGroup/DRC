module dmd.expression.Or;

import dmd.common;
import dmd.Type;
import dmd.Expression;
import dmd.IntegerExp;

Expression Or(Type type, Expression e1, Expression e2)
{
    return new IntegerExp(e1.loc, e1.toInteger() | e2.toInteger(), type);
}