module dmd.expression.Shr;

import dmd.common;
import dmd.Expression;
import dmd.Type;
import dmd.Loc;
import dmd.IntegerExp;
import dmd.TY;

Expression Shr(Type type, Expression e1, Expression e2)
{   
    Loc loc = e1.loc;

    long value = e1.toInteger();
    uint  count = cast(uint)e2.toInteger();

    switch (e1.type.toBasetype().ty)
    {
		case TY.Tint8:
			value = cast(byte)(value) >> count;
			break;

		case TY.Tuns8:
			value = cast(ubyte)(value) >> count;
			break;

		case TY.Tint16:
			value = cast(short)(value) >> count;
			break;

		case TY.Tuns16:
			value = cast(ushort)(value) >> count;
			break;

		case TY.Tint32:
			value = cast(int)(value) >> count;
			break;

		case TY.Tuns32:
			value = cast(uint)(value) >> count;
			break;

		case TY.Tint64:
			value = cast(long)(value) >> count;
			break;

		case TY.Tuns64:
			value = cast(ulong)(value) >> count;
			break;

		default:
			assert(0);
    }

    return new IntegerExp(loc, value, type);
}