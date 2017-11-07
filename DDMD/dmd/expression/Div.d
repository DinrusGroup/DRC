module dmd.expression.Div;

import dmd.common;
import dmd.Type;
import dmd.Expression;
import dmd.Loc;
import dmd.RealExp;
import dmd.ComplexExp;
import dmd.IntegerExp;
import dmd.Complex;

Expression Div(Type type, Expression e1, Expression e2)
{   
	Expression e;
    Loc loc = e1.loc;

    if (type.isfloating())
    {
		Complex!(real) c;
		real r;

		//e1.type.print();
		//e2.type.print();
		if (e2.type.isreal())
		{
			if (e1.type.isreal())
			{
				e = new RealExp(loc, e1.toReal() / e2.toReal(), type);
				return e;
			}

			//r = e2.toReal();
			//c = e1.toComplex();
			//printf("(%Lg + %Lgi) / %Lg\n", creall(c), cimagl(c), r);
			r = e2.toReal();
			c = e1.toComplex();
			c = Complex!(real)(c.re / r, c.im / r);
		}
		else if (e2.type.isimaginary())
		{
			//r = e2.toImaginary();
			//c = e1.toComplex();
			//printf("(%Lg + %Lgi) / %Lgi\n", creall(c), cimagl(c), r);
			r = e2.toImaginary();
			c = e1.toComplex();
			c = Complex!(real)(c.im / r, -c.re / r);
		}
		else
		{
			Complex!(real) c1 = e1.toComplex();
			Complex!(real) c2 = e2.toComplex();
			
			real denumerator = c2.re*c2.re + c2.im*c2.im;
			real numerator_re = c1.re*c2.re + c1.im*c2.im;
			real numerator_im = c1.im*c2.re - c1.re*c2.im;

			c = Complex!(real)(numerator_re / denumerator, numerator_im / denumerator);
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
			n = (cast(ulong) n1) / (cast(ulong) n2);
		else
			n = n1 / n2;

		e = new IntegerExp(loc, n, type);
    }

    return e;
}