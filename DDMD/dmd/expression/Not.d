module dmd.expression.Not;

import dmd.common;
import dmd.Type;
import dmd.Expression;
import dmd.IntegerExp;

Expression Not(Type type, Expression e1)
{   
    return new IntegerExp(e1.loc, e1.isBool(false), type);
}