module dmd.expression.And;

import dmd.common;
import dmd.Expression;
import dmd.Type;
import dmd.IntegerExp;

Expression And(Type type, Expression e1, Expression e2)
{
    return new IntegerExp(e1.loc, e1.toInteger() & e2.toInteger(), type);
}