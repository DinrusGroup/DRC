module dmd.IntegerExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.TY;
import dmd.TypeEnum;
import dmd.TypeTypedef;
import dmd.Global;
import dmd.InterState;
import dmd.MATCH;
import dmd.Type;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IntRange;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.Complex;

import dmd.backend.dt_t;
import dmd.backend.Util;

import core.stdc.ctype : isprint;
import std.stdio;

import dmd.DDMDExtensions;

class IntegerExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	ulong value;

	this(Loc loc, ulong value, Type type)
	{
		register();
		super(loc, TOK.TOKint64, IntegerExp.sizeof);
		
		//printf("IntegerExp(value = %lld, type = '%s')\n", value, type ? type.toChars() : "");
		if (type && !type.isscalar())
		{
			//printf("%s, loc = %d\n", toChars(), loc.linnum);
			error("integral constant must be scalar type, not %s", type.toChars());
			type = Type.terror;
		}
		this.type = type;
		this.value = value;
	}

	this(ulong value)
	{
		register();
		super(Loc(0), TOK.TOKint64, IntegerExp.sizeof);
		this.type = Type.tint32;
		this.value = value;
	}

	override bool equals(Object o)
	{
		IntegerExp ne;

		if (this == o ||
			((cast(Expression)o).op == TOKint64 &&
			((ne = cast(IntegerExp)o), type.toHeadMutable().equals(ne.type.toHeadMutable())) &&
			value == ne.value)
		  )
			return 1;

		return 0;
	}

	override Expression semantic(Scope sc)
	{
		if (!type)
		{
			// Determine what the type of this number is
			ulong number = value;

			if (number & 0x8000000000000000)
				type = Type.tuns64;
			else if (number & 0xFFFFFFFF80000000)
				type = Type.tint64;
			else
				type = Type.tint32;
		}
		else
		{	if (!type.deco)
				type = type.semantic(loc, sc);
		}
		return this;
	}

	override Expression interpret(InterState istate)
	{
version (LOG) {
		printf("IntegerExp.interpret() %s\n", toChars());
}
		return this;
	}

	override string toChars()
	{
static if (true) {
		return Expression.toChars();
} else {
		static char[value.sizeof * 3 + 1] buffer;
		int len = sprintf(buffer.ptr, "%jd", value);
		return buffer[0..len].idup;
}
	}

	override void dump(int indent)
	{
		assert(false);
	}

	override IntRange getIntRange()
	{
		IntRange ir;
		ir.imin = value & type.sizemask();
		ir.imax = ir.imin;
		return ir;
	}

	override ulong toInteger()
	{
		Type t;

		t = type;
		while (t)
		{
			switch (t.ty)
			{
				case TY.Tbit:
				case TY.Tbool:	value = (value != 0);		break;
				case TY.Tint8:	value = cast(byte)  value;	break;
				case TY.Tchar:
				case TY.Tuns8:	value = cast(ubyte) value;	break;
				case TY.Tint16:	value = cast(short) value;	break;
				case TY.Twchar:
				case TY.Tuns16:	value = cast(ushort)value;	break;
				case TY.Tint32:	value = cast(int)   value;	break;
				case TY.Tdchar:
				case TY.Tuns32:	value = cast(uint)  value;	break;
				case TY.Tint64:	value = cast(long)  value;	break;
				case TY.Tuns64:	value = cast(ulong) value;	break;
				case TY.Tpointer:
						if (PTRSIZE == 4)
							value = cast(uint) value;
						else if (PTRSIZE == 8)
							value = cast(ulong) value;
						else
							assert(0);
						break;

				case TY.Tenum:
				{
					TypeEnum te = cast(TypeEnum)t;
					t = te.sym.memtype;
					continue;
				}

				case TY.Ttypedef:
				{
					TypeTypedef tt = cast(TypeTypedef)t;
					t = tt.sym.basetype;
					continue;
				}

				default:
					/* This can happen if errors, such as
					 * the type is painted on like in fromConstInitializer().
					 */
					if (!global.errors)
					{
						writef("%s %p\n", type.toChars(), type);
						assert(0);
					}
					break;

			}
			break;
		}
		return value;
	}

	override real toReal()
	{
		Type t;

		toInteger();
		t = type.toBasetype();
		if (t.ty == Tuns64)
			return cast(real)cast(ulong)value;
		else
			return cast(real)cast(long)value;
	}

	override real toImaginary()
	{
		assert(false);
	}

	override Complex!(real) toComplex()
	{
		assert(false);
	}

	override int isConst()
	{
		return 1;
	}

	override bool isBool(bool result)
	{
        int r = toInteger() != 0;
        return cast(bool)(result ? r : !r);
	}

	override MATCH implicitConvTo(Type t)
	{
static if (false) {
		printf("IntegerExp.implicitConvTo(this=%s, type=%s, t=%s)\n",
		toChars(), type.toChars(), t.toChars());
}

		MATCH m = type.implicitConvTo(t);
		if (m >= MATCH.MATCHconst)
			return m;

		TY ty = type.toBasetype().ty;
		TY toty = t.toBasetype().ty;

		if (m == MATCH.MATCHnomatch && t.ty == TY.Tenum)
			goto Lno;

		switch (ty)
		{
			case TY.Tbit:
			case TY.Tbool:
				value &= 1;
				ty = TY.Tint32;
				break;

			case TY.Tint8:
				value = cast(byte)value;
				ty = TY.Tint32;
				break;

			case TY.Tchar:
			case TY.Tuns8:
				value &= 0xFF;
				ty = TY.Tint32;
				break;

			case TY.Tint16:
				value = cast(short)value;
				ty = TY.Tint32;
				break;

			case TY.Tuns16:
			case TY.Twchar:
				value &= 0xFFFF;
				ty = TY.Tint32;
				break;

			case TY.Tint32:
				value = cast(int)value;
				break;

			case TY.Tuns32:
			case TY.Tdchar:
				value &= 0xFFFFFFFF;
				ty = TY.Tuns32;
				break;

			default:
				break;
		}

		// Only allow conversion if no change in value
		switch (toty)
		{
			case TY.Tbit:
			case TY.Tbool:
				if ((value & 1) != value)
					goto Lno;
				goto Lyes;

			case TY.Tint8:
				if (cast(byte)value != value)
					goto Lno;
				goto Lyes;

			case TY.Tchar:
			case TY.Tuns8:
				//printf("value = %llu %llu\n", (dinteger_t)(unsigned char)value, value);
				if (cast(ubyte)value != value)
					goto Lno;
				goto Lyes;

			case TY.Tint16:
				if (cast(short)value != value)
					goto Lno;
				goto Lyes;

			case TY.Tuns16:
				if (cast(ushort)value != value)
				goto Lno;
				goto Lyes;

			case TY.Tint32:
				if (ty == TY.Tuns32) {
					//;
				}
				else if (cast(int)value != value) {
					goto Lno;
				}
				goto Lyes;

			case TY.Tuns32:
				if (ty == TY.Tint32) {
				} else if (cast(uint)value != value) {
					goto Lno;
				}
				goto Lyes;

			case TY.Tdchar:
				if (value > 0x10FFFF) {
					goto Lno;
				}
				goto Lyes;

			case TY.Twchar:
				if (cast(ushort)value != value) {
					goto Lno;
				}
				goto Lyes;

			case TY.Tfloat32:
			{
				/*volatile*/ float f;	///
				if (type.isunsigned()) {
					f = cast(float)value;
					if (f != value) {
						goto Lno;
					}
				} else {
					f = cast(float)cast(long)value;
					if (f != cast(long)value) {
						goto Lno;
					}
				}
				goto Lyes;
			}

			case TY.Tfloat64:
			{
				/*volatile*/ double f;	///
				if (type.isunsigned()) {
					f = cast(double)value;
					if (f != value)
						goto Lno;
				} else {
					f = cast(double)cast(long)value;
					if (f != cast(long)value)
						goto Lno;
				}
				goto Lyes;
			}

			case TY.Tfloat80:
			{
				/*volatile*/ real f;	///
				if (type.isunsigned()) {
					f = cast(real)value;
					if (f != value)
						goto Lno;
				} else {
					f = cast(real)cast(long)value;
					if (f != cast(long)value)
						goto Lno;
				}
				goto Lyes;
			}

			case TY.Tpointer:
		//printf("type = %s\n", type.toBasetype().toChars());
		//printf("t = %s\n", t.toBasetype().toChars());
				if (ty == TY.Tpointer && type.toBasetype().nextOf().ty == t.toBasetype().nextOf().ty)
				{
					/* Allow things like:
					 *	const char* P = cast(char *)3;
					 *	char* q = P;
					 */
					goto Lyes;
				}
				break;
				
			default:
				break;	///
		}

		return Expression.implicitConvTo(t);

	Lyes:
		//printf("MATCHconvert\n");
		return MATCH.MATCHconvert;

	Lno:
		//printf("MATCHnomatch\n");
		return MATCH.MATCHnomatch;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		long v = toInteger();

		if (type)
		{	
			Type t = type;

		  L1:
			switch (t.ty)
			{
				case TY.Tenum:
				{   
					TypeEnum te = cast(TypeEnum)t;
					buf.printf("cast(%s)", te.sym.toChars());
					t = te.sym.memtype;
					goto L1;
				}

				case TY.Ttypedef:
				{	
					TypeTypedef tt = cast(TypeTypedef)t;
					buf.printf("cast(%s)", tt.sym.toChars());
					t = tt.sym.basetype;
					goto L1;
				}

				case TY.Twchar:	// BUG: need to cast(wchar)
				case TY.Tdchar:	// BUG: need to cast(dchar)
					if (cast(ulong)v > 0xFF)
					{
						 buf.printf("'\\U%08x'", v);
						 break;
					}
				case TY.Tchar:
					if (v == '\'')
						buf.writestring("'\\''");
					else if (isprint(cast(int)v) && v != '\\')
						buf.printf("'%s'", cast(char)v);	/// !
					else
						buf.printf("'\\x%02x'", cast(int)v);
					break;

				case TY.Tint8:
					buf.writestring("cast(byte)");
					goto L2;

				case TY.Tint16:
					buf.writestring("cast(short)");
					goto L2;

				case TY.Tint32:
				L2:
					buf.printf("%d", cast(int)v);
					break;

				case TY.Tuns8:
					buf.writestring("cast(ubyte)");
					goto L3;

				case TY.Tuns16:
					buf.writestring("cast(ushort)");
					goto L3;

				case TY.Tuns32:
				L3:
					buf.printf("%du", cast(uint)v);
					break;

				case TY.Tint64:
					//buf.printf("%jdL", v);
					buf.printf("%sL", v);
					break;

				case TY.Tuns64:
				L4:
					//buf.printf("%juLU", v);
					buf.printf("%sLU", v);
					break;

				case TY.Tbit:
				case TY.Tbool:
					buf.writestring(v ? "true" : "false");
					break;

				case TY.Tpointer:
					buf.writestring("cast(");
					buf.writestring(t.toChars());
					buf.writeByte(')');
					if (PTRSIZE == 4)
						goto L3;
					else if (PTRSIZE == 8)
						goto L4;
					else
						assert(0);

				default:
					/* This can happen if errors, such as
					 * the type is painted on like in fromConstInitializer().
					 */
					if (!global.errors)
					{
						debug {
							writef("%s\n", t.toChars());
						}
						assert(0);
					}
					break;
			}
		}
		else if (v & 0x8000000000000000L)
			buf.printf("0x%jx", v);
		else
			buf.printf("%jd", v);
	}

	override void toMangleBuffer(OutBuffer buf)
	{
	    if (cast(long)value < 0)
		buf.printf("N%d", -value);
	    else
		buf.printf("%d", value);
	}

	override Expression toLvalue(Scope sc, Expression e)
	{
		if (!e)
			e = this;
		else if (!loc.filename)
			loc = e.loc;
		e.error("constant %s is not an lvalue", e.toChars());
		return this;
	}

	override elem* toElem(IRState* irs)
	{
		elem* e = el_long(type.totym(), value);
		el_setLoc(e,loc);
		return e;
	}

	override dt_t** toDt(dt_t** pdt)
	{
		//printf("IntegerExp.toDt() %d\n", op);
		uint sz = cast(uint)type.size();
		if (value == 0)
			pdt = dtnzeros(pdt, sz);
		else
			pdt = dtnbytes(pdt, sz, cast(char*)&value);

		return pdt;
	}
}

