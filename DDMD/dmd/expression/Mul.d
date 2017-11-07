module dmd.expression.Mul;

import dmd.common;
import dmd.Type;
import dmd.Expression;
import dmd.RealExp;
import dmd.IntegerExp;
import dmd.ComplexExp;
import dmd.Loc;
import dmd.Complex;

Expression Mul(Type type, Expression e1, Expression e2)
{   
	Expression e;
    Loc loc = e1.loc;

    if (type.isfloating())
    {   
		Complex!(real) c;
		real r;
		
		if (e1.type.isreal())
		{
			r = e1.toReal();
			c = e2.toComplex();
			c = Complex!(real)(r * c.re, r * c.im);
		}
		else if (e1.type.isimaginary())
		{
			r = e1.toImaginary();
			c = e2.toComplex();
			c = Complex!(real)(-r * c.im, r * c.re);
		}
		else if (e2.type.isreal())
		{
			r = e2.toReal();
			c = e1.toComplex();
			c = Complex!(real)(r * c.re, r * c.im);
		}
		else if (e2.type.isimaginary())
		{
			r = e2.toImaginary();
			c = e1.toComplex();
			c = Complex!(real)(-r * c.im, r * c.re);
		}
		else
		{
			Complex!(real) c1 = e1.toComplex();
			Complex!(real) c2 = e2.toComplex();
			c = Complex!(real)(c1.re * c2.re - c1.im * c2.im, c1.re * c2.im + c1.im * c2.re);
		}

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
		e = new IntegerExp(loc, e1.toInteger() * e2.toInteger(), type);
    }
    return e;
}