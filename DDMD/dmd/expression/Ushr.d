module dmd.expression.Ushr;

import dmd.common;
import dmd.Type;
import dmd.Expression;
import dmd.Loc;
import dmd.TY;
import dmd.IntegerExp;

Expression Ushr(Type type, Expression e1, Expression e2)
{   
	Expression e;
    Loc loc = e1.loc;
    uint count;
    ulong value;

    value = e1.toInteger();
    count = cast(uint)e2.toInteger();

	switch (e1.type.toBasetype().ty)
    {
		case Tint8:
		case Tuns8:
			assert(0);		// no way to trigger this
			value = (value & 0xFF) >> count;
			break;

		case Tint16:
		case Tuns16:
			assert(0);		// no way to trigger this
			value = (value & 0xFFFF) >> count;
			break;

		case Tint32:
		case Tuns32:
			value = (value & 0xFFFFFFFF) >> count;
			break;

		case Tint64:
		case Tuns64:
			value = cast(ulong)(value) >> count;
			break;

		default:
			assert(0);
    }

    e = new IntegerExp(loc, value, type);

    return e;
}