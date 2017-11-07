module dmd.expression.Bool;

import dmd.IntegerExp;
import dmd.Loc;
import dmd.Type;
import dmd.Expression;

Expression Bool(Type type, Expression e1)
{
	return new IntegerExp(e1.loc, e1.isBool(1), type);
}