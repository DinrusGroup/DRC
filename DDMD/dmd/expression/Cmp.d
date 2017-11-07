module dmd.expression.Cmp;

import dmd.common;
import dmd.IntegerExp;
import dmd.Loc;
import dmd.TOK;
import dmd.Type;
import dmd.Expression;
import dmd.StringExp;
import dmd.GlobalExpressions;

import core.stdc.string;

Expression Cmp(TOK op, Type type, Expression e1, Expression e2)
{   
	Expression e;
    Loc loc = e1.loc;
    ulong n;
    real r1;
    real r2;

    //printf("Cmp(e1 = %s, e2 = %s)\n", e1.toChars(), e2.toChars());

    if (e1.op == TOKstring && e2.op == TOKstring)
    {	
		StringExp es1 = cast(StringExp)e1;
		StringExp es2 = cast(StringExp)e2;
		size_t sz = es1.sz;
		assert(sz == es2.sz);

		size_t len = es1.len;
		if (es2.len < len)
			len = es2.len;

		int cmp = memcmp(es1.string_, es2.string_, sz * len);
		if (cmp == 0)
			cmp = es1.len - es2.len;

		switch (op)
		{
			case TOKlt:	n = cmp <  0;	break;
			case TOKle:	n = cmp <= 0;	break;
			case TOKgt:	n = cmp >  0;	break;
			case TOKge:	n = cmp >= 0;	break;

			case TOKleg:   n = 1;		break;
			case TOKlg:	   n = cmp != 0;	break;
			case TOKunord: n = 0;		break;
			case TOKue:	   n = cmp == 0;	break;
			case TOKug:	   n = cmp >  0;	break;
			case TOKuge:   n = cmp >= 0;	break;
			case TOKul:	   n = cmp <  0;	break;
			case TOKule:   n = cmp <= 0;	break;

			default:
			assert(0);
		}
    }
    else if (e1.isConst() != 1 || e2.isConst() != 1)
		return EXP_CANT_INTERPRET;
    else if (e1.type.isreal())
    {
		r1 = e1.toReal();
		r2 = e2.toReal();
		goto L1;
    }
    else if (e1.type.isimaginary())
    {
		r1 = e1.toImaginary();
		r2 = e2.toImaginary();
	L1:

		// DMC is the only compiler I know of that handles NAN arguments
		// correctly in comparisons.
		switch (op)
		{
			case TOKlt:	   n = r1 <  r2;	break;
			case TOKle:	   n = r1 <= r2;	break;
			case TOKgt:	   n = r1 >  r2;	break;
			case TOKge:	   n = r1 >= r2;	break;
			case TOKleg:   n = r1 <>=  r2;	break;
			case TOKlg:	   n = r1 <>   r2;	break;
			case TOKunord: n = r1 !<>= r2;	break;
			case TOKue:	   n = r1 !<>  r2;	break;
			case TOKug:	   n = r1 !<=  r2;	break;
			case TOKuge:   n = r1 !<   r2;	break;
			case TOKul:	   n = r1 !>=  r2;	break;
			case TOKule:   n = r1 !>   r2;	break;

			default: assert(0);
		}
    }
    else if (e1.type.iscomplex())
    {
		assert(0);
    }
    else
    {   
		long n1;
		long n2;

		n1 = e1.toInteger();
		n2 = e2.toInteger();

		if (e1.type.isunsigned() || e2.type.isunsigned())
		{
			switch (op)
			{
				case TOKlt:		n = (cast(ulong) n1) <  (cast(ulong) n2);		break;
				case TOKle:		n = (cast(ulong) n1) <= (cast(ulong) n2);		break;
				case TOKgt:		n = (cast(ulong) n1) >  (cast(ulong) n2);		break;
				case TOKge:		n = (cast(ulong) n1) >= (cast(ulong) n2);		break;
				case TOKleg:	n = 1;									break;
				case TOKlg:		n = (cast(ulong) n1) != (cast(ulong) n2);		break;
				case TOKunord:	n = 0;									break;
				case TOKue:		n = (cast(ulong) n1) == (cast(ulong) n2);		break;
				case TOKug:		n = (cast(ulong) n1) >  (cast(ulong) n2);		break;
				case TOKuge:	n = (cast(ulong) n1) >= (cast(ulong) n2);	break;
				case TOKul:		n = (cast(ulong) n1) <  (cast(ulong) n2);		break;
				case TOKule:	n = (cast(ulong) n1) <= (cast(ulong) n2);	break;

				default: assert(0);
			}
		}
		else
		{
			switch (op)
			{
				case TOKlt:	n = n1 <  n2;		break;
				case TOKle:	n = n1 <= n2;		break;
				case TOKgt:	n = n1 >  n2;		break;
				case TOKge:	n = n1 >= n2;		break;
				case TOKleg:	n = 1;			break;
				case TOKlg:	n = n1 != n2;		break;
				case TOKunord:	n = 0;			break;
				case TOKue:	n = n1 == n2;		break;
				case TOKug:	n = n1 >  n2;		break;
				case TOKuge:	n = n1 >= n2;	break;
				case TOKul:	n = n1 <  n2;		break;
				case TOKule:	n = n1 <= n2;	break;
				default: assert(0);
			}
		}
    }

    e = new IntegerExp(loc, n, type);

    return e;
}