module dmd.RealExp;

import dmd.common;
import dmd.Complex;
import dmd.Expression;
import dmd.backend.elem;
import dmd.InterState;
import dmd.Type;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.TOK;
import dmd.Scope;
import dmd.IRState;
import dmd.Type;
import dmd.HdrGenState;
import dmd.Port;
import dmd.TY;

import dmd.expression.Util;

import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.mTY;

import std.stdio;
import std.string;

import dmd.DDMDExtensions;

class RealExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	real value;

	this(Loc loc, real value, Type type)
	{
		register();
		super(loc, TOK.TOKfloat64, RealExp.sizeof);
		//printf("RealExp.RealExp(%Lg)\n", value);
		this.value = value;
		this.type = type;
	}

	override bool equals(Object o)
	{
		if (this is o)
			return true;
		
		Expression e = cast(Expression)o;
		if (e.op == TOKfloat64) {
			RealExp ne = cast(RealExp)e;
			if (type.toHeadMutable().equals(ne.type.toHeadMutable())) {
				if (RealEquals(value, ne.value)) {
					return true;
				}
			}
		}
		
		return false;
	}

	override Expression semantic(Scope sc)
	{
		if (!type)
			type = Type.tfloat64;
		else
			type = type.semantic(loc, sc);
		return this;
	}

	override Expression interpret(InterState istate)
	{
version(LOG)
		writef("RealExp::interpret() %s\n", toChars());

		return this;
	}

	override string toChars()
	{
		return format(type.isimaginary() ? "%gi" : "%g", value);
	}

	override ulong toInteger()
	{
version(IN_GCC)
		return toReal().toInt();
else
		return cast(ulong) toReal();
	}

	override ulong toUInteger()
	{
version(IN_GCC)
		return cast(ulong) toReal().toInt();
else
		return cast(ulong) toReal();
	}

	override real toReal()
	{
		return type.isreal() ? value : 0;
	}

	override real toImaginary()
	{
		return type.isreal() ? 0 : value;
	}

	override Complex!(real) toComplex()
	{
		return Complex!(real)(toReal(), toImaginary());
	}

	override Expression castTo(Scope sc, Type t)
	{
		Expression e = this;
		if (type != t)
		{
			if ((type.isreal() && t.isreal()) ||
				(type.isimaginary() && t.isimaginary())
			   )
			{   
				e = copy();
				e.type = t;
			}
			else
				e = Expression.castTo(sc, t);
		}
		return e;
	}

	override int isConst()
	{
		return 1;
	}

	override bool isBool(bool result)
	{
		return result ? (value != 0) : (value == 0);
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		floatToBuffer(buf, type, value);
	}

	override void toMangleBuffer(OutBuffer buf)
	{
		buf.writeByte('e');
		realToMangleBuffer(buf, value);
	}

	override elem* toElem(IRState* irs)
	{
		eve c;
		tym_t ty;

		//printf("RealExp.toElem(%p) %s\n", this, toChars());
		///memset(&c, 0, sizeof(c));
		ty = type.toBasetype().totym();
		switch (tybasic(ty))
		{
			case TYfloat:
			case TYifloat:
				c.Vfloat = value;
				if (Port.isSignallingNan(value)) {
					std.stdio.writeln("signalling float");
					(cast(uint*)&c.Vfloat)[0] &= 0xFFBFFFFFL;
				}
				break;

			case TYdouble:
			case TYidouble:
				c.Vdouble = value;	// unfortunately, this converts SNAN to QNAN
				if (Port.isSignallingNan(value)) {
					std.stdio.writeln("signalling double");
					// Put SNAN back
					(cast(uint*)&c.Vdouble)[1] &= 0xFFF7FFFFL;
				}
				break;

			case TYldouble:
			case TYildouble:
				c.Vldouble = value;
				break;

			default:
				print();
				///type.print();
				///type.toBasetype().print();
				printf("ty = %d, tym = %lx\n", type.ty, ty);
				assert(0);
		}
		return el_const(ty, &c);
	}
	
	private enum char[6] zeropad = [0];

	override dt_t** toDt(dt_t** pdt)
	{
		float fvalue;
		double dvalue;
		real evalue;

		//printf("RealExp.toDt(%Lg)\n", value);
		switch (type.toBasetype().ty)
		{
			case Tfloat32:
			case Timaginary32:
				fvalue = value;
				pdt = dtnbytes(pdt,4,cast(char*)&fvalue);
				break;

			case Tfloat64:
			case Timaginary64:
				dvalue = value;
				pdt = dtnbytes(pdt,8,cast(char*)&dvalue);
				break;

			case Tfloat80:
			case Timaginary80:
				evalue = value;
				pdt = dtnbytes(pdt,REALSIZE - REALPAD,cast(char*)&evalue);
				pdt = dtnbytes(pdt,REALPAD,zeropad.ptr);
				assert(REALPAD <= zeropad.sizeof);
				break;

			default:
				writef("%s\n", toChars());
				///type.print();
				assert(0);
		}
		return pdt;
	}
}