module dmd.ComplexExp;

import dmd.common;
import dmd.Expression;
import dmd.InterState;
import dmd.Type;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.Type;
import dmd.TOK;
import dmd.TY;
import dmd.Port;
import dmd.Complex;
import dmd.expression.Util;

import dmd.backend.dt_t;
import dmd.backend.elem;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.mTY;

import dmd.DDMDExtensions;

class ComplexExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Complex!(real) value;

	this(Loc loc, Complex!(real) value, Type type)
	{
		register();
		super(loc, TOK.TOKcomplex80, ComplexExp.sizeof);
		this.value = value;
		this.type = type;
		//printf("ComplexExp.ComplexExp(%s)\n", toChars());
	}

	override bool equals(Object o)
	{
		assert(false);
	}

	override Expression semantic(Scope sc)
	{
		if (!type)
			type = Type.tcomplex80;
		else
			type = type.semantic(loc, sc);
		return this;
	}

	override Expression interpret(InterState istate)
	{
		assert(false);
	}

	override string toChars()
	{
		assert(false);
	}

	override ulong toInteger()
	{
		return cast(ulong) toReal();
	}

	override ulong toUInteger()
	{
		return cast(long) toReal();
	}

	override real toReal()
	{
		return value.re;
	}

	override real toImaginary()
	{
		return value.im;
	}

	override Complex!(real) toComplex()
	{
		return value;
	}

	override Expression castTo(Scope sc, Type t)
	{
		Expression e = this;
		if (type != t)
		{
			if (type.iscomplex() && t.iscomplex())
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
		if (result)
			return value != Complex!(real).zero;
		else
			return value == Complex!(real).zero;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		/* Print as:
		 *  (re+imi)
		 */
version (IN_GCC) {
		char[sizeof(value) * 3 + 8 + 1] buf1;
		char[sizeof(value) * 3 + 8 + 1] buf2;
		creall(value).format(buf1, sizeof(buf1));
		cimagl(value).format(buf2, sizeof(buf2));
		buf.printf("(%s+%si)", buf1, buf2);
} else {
		buf.writeByte('(');
		floatToBuffer(buf, type, value.re);
		buf.writeByte('+');
		floatToBuffer(buf, type, value.im);
		buf.writestring("i)");
}
	}

	override void toMangleBuffer(OutBuffer buf)
	{
		buf.writeByte('c');
		real r = toReal();
		realToMangleBuffer(buf, r);
		buf.writeByte('c');	// separate the two
		r = toImaginary();
		realToMangleBuffer(buf, r);
	}

version (_DH) {
	OutBuffer hexp;
}

	override elem* toElem(IRState* irs)
	{
		eve c;
		tym_t ty;

		//printf("ComplexExp.toElem(%p) %s\n", this, toChars());

		///memset(&c, 0, c.sizeof);

		ty = type.totym();
		switch (tybasic(ty))
		{
		case TYcfloat:
		{
			c.Vcfloat.re = cast(float) value.re;
			if (Port.isSignallingNan(value.re)) {
				(cast(uint*)&c.Vcfloat.re)[0] &= 0xFFBFFFFFL;
				std.stdio.writeln("float.re is snan");
			}
			c.Vcfloat.im = cast(float) value.im;
			if (Port.isSignallingNan(value.im)) {
				(cast(uint*)&c.Vcfloat.im)[0] &= 0xFFBFFFFFL;
				std.stdio.writeln("float.im is snan");
			}
			break;
		}

		case TYcdouble:
		{
			c.Vcdouble.re = cast(double) value.re;
			if (Port.isSignallingNan(value.re)) {
				std.stdio.writeln("double.re is snan");
				(cast(uint*)&c.Vcdouble.re)[1] &= 0xFFF7FFFFL;
			}
			c.Vcdouble.im = cast(double) value.im;
			if (Port.isSignallingNan(value.im)) {
				(cast(uint*)&c.Vcdouble.im)[1] &= 0xFFF7FFFFL;
				std.stdio.writeln("double.im is snan");
			}
			break;
		}

		case TYcldouble:
		{
	static if (true) {
			c.Vcldouble = value;
	} else {
			{
				ushort* p = cast(ushort*)&c.Vcldouble;
				for (int i = 0; i < (LNGDBLSIZE*2)/2; i++) printf("%04x ", p[i]);
					printf("\n");
			}
				c.Vcldouble.im = im;
			{
				ushort* p = cast(ushort*)&c.Vcldouble;
				for (int i = 0; i < (LNGDBLSIZE*2)/2; i++) printf("%04x ", p[i]);
					printf("\n");
			}
			c.Vcldouble.re = re;
			{
				ushort* p = cast(ushort*)&c.Vcldouble;
				for (int i = 0; i < (LNGDBLSIZE*2)/2; i++) printf("%04x ", p[i]);
					printf("\n");
			}
	}
			break;
		}

			default:
				assert(0);
		}
		return el_const(ty, &c);
	}

	static private __gshared char[6] zeropad;

	override dt_t** toDt(dt_t** pdt)
	{
		//printf("ComplexExp.toDt() '%s'\n", toChars());
		float fvalue;
		double dvalue;
		real evalue;

		switch (type.toBasetype().ty)
		{
		case Tcomplex32:
			fvalue = value.re;
			pdt = dtnbytes(pdt,4,cast(char*)&fvalue);
			fvalue = value.im;
			pdt = dtnbytes(pdt,4,cast(char*)&fvalue);
			break;

		case Tcomplex64:
			dvalue = value.re;
			pdt = dtnbytes(pdt,8,cast(char*)&dvalue);
			dvalue = value.im;
			pdt = dtnbytes(pdt,8,cast(char*)&dvalue);
			break;

		case Tcomplex80:
			evalue = value.re;
			pdt = dtnbytes(pdt,REALSIZE - REALPAD,cast(char*)&evalue);
			pdt = dtnbytes(pdt,REALPAD,zeropad.ptr);
			evalue = value.im;
			pdt = dtnbytes(pdt,REALSIZE - REALPAD, cast(char*)&evalue);
			pdt = dtnbytes(pdt,REALPAD,zeropad.ptr);
			break;

		default:
			assert(0);
			break;
		}
		return pdt;
	}
}

