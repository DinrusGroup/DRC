module dmd.expression.shift_optimize;

import dmd.common;
import dmd.Expression;
import dmd.BinExp;
import dmd.Type;
import dmd.IntegerExp;

Expression shift_optimize(int result, BinExp e, Expression function(Type, Expression, Expression) shift)
{   
	Expression ex = e;

    e.e1 = e.e1.optimize(result);
    e.e2 = e.e2.optimize(result);

    if (e.e2.isConst() == 1)
    {
		long i2 = e.e2.toInteger();
		ulong sz = e.e1.type.size() * 8;

		if (i2 < 0 || i2 > sz)
		{   
			e.error("shift by %jd is outside the range 0..%zu", i2, sz);
			e.e2 = new IntegerExp(0);
		}

		if (e.e1.isConst() == 1) {
			ex = shift(e.type, e.e1, e.e2);
		}
    }

    return ex;
}