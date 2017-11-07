module dmd.Cast;

import dmd.common;
import dmd.Expression;
import dmd.Type;
import dmd.Loc;
import dmd.MATCH;
import dmd.IntegerExp;
import dmd.RealExp;
import dmd.ComplexExp;
import dmd.StructDeclaration;
import dmd.ArrayTypes;
import dmd.Dsymbol;
import dmd.VarDeclaration;
import dmd.StructLiteralExp;
import dmd.Util;
import dmd.TY;
import dmd.TOK;
import dmd.GlobalExpressions;

import dmd.Complex;

Expression expType(Type type, Expression e)
{
    if (type !is e.type)
    {
		e = e.copy();
		e.type = type;
    }
    return e;
}

/* Also returns EXP_CANT_INTERPRET if cannot be computed.
 *  to:	type to cast to
 *  type: type to paint the result
 */

Expression Cast(Type type, Type to, Expression e1)
{   
	Expression e = EXP_CANT_INTERPRET;
    Loc loc = e1.loc;

    //printf("Cast(type = %s, to = %s, e1 = %s)\n", type.toChars(), to.toChars(), e1.toChars());
    //printf("\te1.type = %s\n", e1.type.toChars());
    if (e1.type.equals(type) && type.equals(to))
		return e1;
    if (e1.type.implicitConvTo(to) >= MATCH.MATCHconst || to.implicitConvTo(e1.type) >= MATCH.MATCHconst)
		return expType(to, e1);

    Type tb = to.toBasetype();
    Type typeb = type.toBasetype();

    /* Allow casting from one string type to another
     */
    if (e1.op == TOK.TOKstring)
    {
		if (tb.ty == TY.Tarray && typeb.ty == TY.Tarray &&
			tb.nextOf().size() == typeb.nextOf().size())
		{
			return expType(to, e1);
		}
    }

    if (e1.op == TOK.TOKarrayliteral && typeb == tb)
        return e1;

    if (e1.isConst() != 1)
		return EXP_CANT_INTERPRET;

    if (tb.ty == TY.Tbool)
		e = new IntegerExp(loc, e1.toInteger() != 0, type);
    else if (type.isintegral())
    {
		if (e1.type.isfloating())
		{   
			long result;
			real r = e1.toReal();

			switch (typeb.ty)
			{
				case TY.Tint8:	result = cast(byte)r;	break;
				case TY.Tchar:
				case TY.Tuns8:	result = cast(ubyte)r;	break;
				case TY.Tint16:	result = cast(short)r;	break;
				case TY.Twchar:
				case TY.Tuns16:	result = cast(ushort)r;	break;
				case TY.Tint32:	result = cast(int)r;	break;
				case TY.Tdchar:
				case TY.Tuns32:	result = cast(uint)r;	break;
				case TY.Tint64:	result = cast(long)r;	break;
				case TY.Tuns64:	result = cast(ulong)r;	break;
				default: assert(false);
			}

			e = new IntegerExp(loc, result, type);
		}
		else if (type.isunsigned())
			e = new IntegerExp(loc, e1.toUInteger(), type);
		else
			e = new IntegerExp(loc, e1.toInteger(), type);
    }
    else if (tb.isreal())
    {
		real value = e1.toReal();
		e = new RealExp(loc, value, type);
    }
    else if (tb.isimaginary())
    {   
		real value = e1.toImaginary();
		e = new RealExp(loc, value, type);
    }
    else if (tb.iscomplex())
    {   
		Complex!(real) value = e1.toComplex();
		e = new ComplexExp(loc, value, type);
    }
    else if (tb.isscalar())
		e = new IntegerExp(loc, e1.toInteger(), type);
    else if (tb.ty == TY.Tvoid)
		e = EXP_CANT_INTERPRET;
    else if (tb.ty == TY.Tstruct && e1.op == TOK.TOKint64)
    {	
		// Struct = 0;
		StructDeclaration sd = tb.toDsymbol(null).isStructDeclaration();
		assert(sd);
		Expressions elements = new Expressions;
		foreach (VarDeclaration v; sd.fields)
		{
			assert(v);

			Expression exp = new IntegerExp(0);
			exp = Cast(v.type, v.type, exp);
			if (exp is EXP_CANT_INTERPRET)
				return exp;
			elements.push(exp);
		}
		e = new StructLiteralExp(loc, sd, elements);
		e.type = type;
    }
    else
    {
		error(loc, "cannot cast %s to %s", e1.type.toChars(), type.toChars());
		e = new IntegerExp(loc, 0, Type.tint32);
    }
    return e;
}