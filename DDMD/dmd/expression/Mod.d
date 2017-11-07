module dmd.expression.Mod;

import dmd.common;
import dmd.Loc;
import dmd.Type;
import dmd.Expression;
import dmd.IntegerExp;
import dmd.RealExp;
import dmd.ComplexExp;
import dmd.Complex;

import core.stdc.math;

Expression Mod(Type type, Expression e1, Expression e2)
{   
	Expression e;
    Loc loc = e1.loc;

    if (type.isfloating())
    {
		Complex!(real) c;

		if (e2.type.isreal())
		{   
			real r2 = e2.toReal();
			c = Complex!(real)(fmodl(e1.toReal(), r2), fmodl(e1.toImaginary(), r2));
		}
		else if (e2.type.isimaginary())
		{   
			real i2 = e2.toImaginary();
			c = Complex!(real)(fmodl(e1.toReal(), i2), fmodl(e1.toImaginary(), i2));
		}
		else
			assert(0);

		if (type.isreal())
			e = new RealExp(loc, c.re, type);
		else if (type.isimaginary())
			e = new RealExp(loc, c.im, type);
		else if (type.iscomplex())
			e = new ComplexExp(loc, c, type);
		else
			assert(0);
    }
    else
    {   
		long n1;
		long n2;
		long n;

		n1 = e1.toInteger();
		n2 = e2.toInteger();
		if (n2 == 0)
		{   
			e2.error("divide by 0");
			e2 = new IntegerExp(loc, 1, e2.type);
			n2 = 1;
		}

		if (e1.type.isunsigned() || e2.type.isunsigned())
			n = (cast(ulong) n1) % (cast(ulong) n2);
		else
			n = n1 % n2;

		e = new IntegerExp(loc, n, type);
    }
    return e;
}