module dmd.expression.Neg;

import dmd.common;
import dmd.Type;
import dmd.Loc;
import dmd.RealExp;
import dmd.Expression;
import dmd.ComplexExp;
import dmd.IntegerExp;
import dmd.Complex;

Expression Neg(Type type, Expression e1)
{   
	Expression e;
    Loc loc = e1.loc;

    if (e1.type.isreal())
    {
		e = new RealExp(loc, -e1.toReal(), type);
    }
    else if (e1.type.isimaginary())
    {
		e = new RealExp(loc, -e1.toImaginary(), type);
    }
    else if (e1.type.iscomplex())
    {
		Complex!(real) c = e1.toComplex();
		e = new ComplexExp(loc, Complex!(real)(-c.re, -c.im), type);
    }
    else
		e = new IntegerExp(loc, -e1.toInteger(), type);

    return e;
}