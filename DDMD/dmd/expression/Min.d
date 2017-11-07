module dmd.expression.Min;

import dmd.common;
import dmd.Expression;
import dmd.Type;
import dmd.Loc;
import dmd.RealExp;
import dmd.ComplexExp;
import dmd.IntegerExp;
import dmd.TOK;
import dmd.SymOffExp;
import dmd.Complex;

Expression Min(Type type, Expression e1, Expression e2)
{   
	Expression e;
    Loc loc = e1.loc;

    if (type.isreal())
    {
		e = new RealExp(loc, e1.toReal() - e2.toReal(), type);
    }
    else if (type.isimaginary())
    {
		e = new RealExp(loc, e1.toImaginary() - e2.toImaginary(), type);
    }
    else if (type.iscomplex())
    {
		// This rigamarole is necessary so that -0.0 doesn't get
		// converted to +0.0 by doing an extraneous add with +0.0
		Complex!(real) c1;
		real r1;
		real i1;

		Complex!(real) c2;
		real r2;
		real i2;

		Complex!(real) v;
		int x;

		if (e1.type.isreal())
		{
			r1 = e1.toReal();
			x = 0;
		}
		else if (e1.type.isimaginary())
		{   
			i1 = e1.toImaginary();
			x = 3;
		}
		else
		{   
			c1 = e1.toComplex();
			x = 6;
		}

		if (e2.type.isreal())
		{   
			r2 = e2.toReal();
		}
		else if (e2.type.isimaginary())
		{   
			i2 = e2.toImaginary();
			x += 1;
		}
		else
		{   
			c2 = e2.toComplex();
			x += 2;
		}

		switch (x)
		{
			case 0+0:	v = Complex!(real)(r1 - r2, 0);	break;
			case 0+1:	v = Complex!(real)(r1, -i2);	break;
			case 0+2:	v = Complex!(real)(r1 - c2.re, -c2.im);		break;
			case 3+0:	v = Complex!(real)(-r2, i1);		break;
			case 3+1:	v = Complex!(real)(0, i1 - i2);	break;
			case 3+2:	v = Complex!(real)(c2.re, i1 - c2.im);		break;
			case 6+0:	v = Complex!(real)(c1.re - r2, c1.im);		break;
			case 6+1:	v = Complex!(real)(c1.re, c1.im - i2);		break;
			case 6+2:	v = Complex!(real)(c1.re - c2.re, c1.im - c2.im);		break;
			default:
		}
		e = new ComplexExp(loc, v, type);
    }
    else if (e1.op == TOK.TOKsymoff)
    {
		SymOffExp soe = cast(SymOffExp)e1;
		e = new SymOffExp(loc, soe.var, soe.offset - cast(uint)e2.toInteger());
		e.type = type;
    }
    else
    {
		e = new IntegerExp(loc, e1.toInteger() - e2.toInteger(), type);
    }
    return e;
}