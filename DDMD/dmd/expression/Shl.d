module dmd.expression.Shl;

import dmd.common;
import dmd.Expression;
import dmd.Type;
import dmd.IntegerExp;

Expression Shl(Type type, Expression e1, Expression e2)
{   
    return new IntegerExp(e1.loc, e1.toInteger() << e2.toInteger(), type);
}