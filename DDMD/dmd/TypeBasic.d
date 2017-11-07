module dmd.TypeBasic;

import dmd.common;
import dmd.Type;
import dmd.Id;
import dmd.MOD;
import dmd.TOK;
import dmd.Token;
import dmd.TFLAGS;
import dmd.TY;
import dmd.Loc;
import dmd.Scope;
import dmd.Expression;
import dmd.IntegerExp;
import dmd.Identifier;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.CppMangleState;
import dmd.MATCH;
import dmd.RealExp;
import dmd.ComplexExp;
import dmd.Util;
import dmd.Port;
import dmd.Complex;

import dmd.DDMDExtensions;

class TypeBasic : Type
{
	mixin insertMemberExtension!(typeof(this));

    string dstring;
    uint flags;

    this(TY ty)
	{
		register();
		super(ty);

		enum TFLAGSintegral	= 1;
		enum TFLAGSfloating = 2;
		enum TFLAGSunsigned = 4;
		enum TFLAGSreal = 8;
		enum TFLAGSimaginary = 0x10;
		enum TFLAGScomplex = 0x20;

		string d;

		uint flags = 0;
		switch (ty)
		{
		case TY.Tvoid:	d = Token.toChars(TOK.TOKvoid);
				break;

		case TY.Tint8:	d = Token.toChars(TOK.TOKint8);
				flags |= TFLAGSintegral;
				break;

		case TY.Tuns8:	d = Token.toChars(TOK.TOKuns8);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case TY.Tint16:	d = Token.toChars(TOK.TOKint16);
				flags |= TFLAGSintegral;
				break;

		case TY.Tuns16:	d = Token.toChars(TOK.TOKuns16);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case TY.Tint32:	d = Token.toChars(TOK.TOKint32);
				flags |= TFLAGSintegral;
				break;

		case TY.Tuns32:	d = Token.toChars(TOK.TOKuns32);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case TY.Tfloat32:	d = Token.toChars(TOK.TOKfloat32);
				flags |= TFLAGSfloating | TFLAGSreal;
				break;

		case TY.Tint64:	d = Token.toChars(TOK.TOKint64);
				flags |= TFLAGSintegral;
				break;

		case TY.Tuns64:	d = Token.toChars(TOK.TOKuns64);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case TY.Tfloat64:	d = Token.toChars(TOK.TOKfloat64);
				flags |= TFLAGSfloating | TFLAGSreal;
				break;

		case TY.Tfloat80:	d = Token.toChars(TOK.TOKfloat80);
				flags |= TFLAGSfloating | TFLAGSreal;
				break;

		case TY.Timaginary32: d = Token.toChars(TOK.TOKimaginary32);
				flags |= TFLAGSfloating | TFLAGSimaginary;
				break;

		case TY.Timaginary64: d = Token.toChars(TOK.TOKimaginary64);
				flags |= TFLAGSfloating | TFLAGSimaginary;
				break;

		case TY.Timaginary80: d = Token.toChars(TOK.TOKimaginary80);
				flags |= TFLAGSfloating | TFLAGSimaginary;
				break;

		case TY.Tcomplex32: d = Token.toChars(TOK.TOKcomplex32);
				flags |= TFLAGSfloating | TFLAGScomplex;
				break;

		case TY.Tcomplex64: d = Token.toChars(TOK.TOKcomplex64);
				flags |= TFLAGSfloating | TFLAGScomplex;
				break;

		case TY.Tcomplex80: d = Token.toChars(TOK.TOKcomplex80);
				flags |= TFLAGSfloating | TFLAGScomplex;
				break;

		case TY.Tbool:	d = "bool";
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case TY.Tascii:	d = Token.toChars(TOK.TOKchar);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case TY.Twchar:	d = Token.toChars(TOK.TOKwchar);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;

		case TY.Tdchar:	d = Token.toChars(TOK.TOKdchar);
				flags |= TFLAGSintegral | TFLAGSunsigned;
				break;
		default:
		}

		this.dstring = d;
		this.flags = flags;
		merge();
	}

    override Type syntaxCopy()
	{
		// No semantic analysis done on basic types, no need to copy
		return this;
	}
	
    override ulong size(Loc loc)
	{
		uint size;

		//printf("TypeBasic.size()\n");
		switch (ty)
		{
			case TY.Tint8:
			case TY.Tuns8:	size = 1;	break;
			case TY.Tint16:
			case TY.Tuns16:	size = 2;	break;
			case TY.Tint32:
			case TY.Tuns32:
			case TY.Tfloat32:
			case TY.Timaginary32:
					size = 4;	break;
			case TY.Tint64:
			case TY.Tuns64:
			case TY.Tfloat64:
			case TY.Timaginary64:
					size = 8;	break;
			case TY.Tfloat80:
			case TY.Timaginary80:
					size = REALSIZE;	break;
			case TY.Tcomplex32:
					size = 8;		break;
			case TY.Tcomplex64:
					size = 16;		break;
			case TY.Tcomplex80:
					size = REALSIZE * 2;	break;

			case TY.Tvoid:
				//size = Type.size();	// error message
				size = 1;
				break;

			case TY.Tbool:	size = 1;		break;
			case TY.Tascii:	size = 1;		break;
			case TY.Twchar:	size = 2;		break;
			case TY.Tdchar:	size = 4;		break;

			default:
				assert(0);
		}

		//printf("TypeBasic.size() = %d\n", size);
		return size;
	}
	
    override uint alignsize()
	{
		uint sz;

		switch (ty)
		{
		case TY.Tfloat80:
		case TY.Timaginary80:
		case TY.Tcomplex80:
			sz = REALALIGNSIZE;
			break;

version (POSIX) { ///TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
		case TY.Tint64:
		case TY.Tuns64:
		case TY.Tfloat64:
		case TY.Timaginary64:
		case TY.Tcomplex32:
		case TY.Tcomplex64:
			sz = 4;
			break;
}

		default:
			sz = cast(uint)size(Loc(0));	///
			break;
		}

		return sz;
	}
	
    override Expression getProperty(Loc loc, Identifier ident)
	{
		Expression e;
		long ivalue;
		real fvalue;

		//printf("TypeBasic.getProperty('%s')\n", ident.toChars());
		if (ident is Id.max)
		{
			switch (ty)
			{
				case TY.Tint8:	ivalue = byte.max;		goto Livalue;
				case TY.Tuns8:	ivalue = ubyte.max;		goto Livalue;
				case TY.Tint16:	ivalue = short.max;		goto Livalue;
				case TY.Tuns16:	ivalue = ushort.max;	goto Livalue;
				case TY.Tint32:	ivalue = int.max;		goto Livalue;
				case TY.Tuns32:	ivalue = uint.max;		goto Livalue;
				case TY.Tint64:	ivalue = long.max;		goto Livalue;
				case TY.Tuns64:	ivalue = ulong.max;		goto Livalue;
				case TY.Tbool:	ivalue = bool.max;		goto Livalue;
				case TY.Tchar:	ivalue = char.max;		goto Livalue;
				case TY.Twchar:	ivalue = wchar.max;		goto Livalue;
				case TY.Tdchar:	ivalue = 0x10FFFF;		goto Livalue;
				case TY.Tcomplex32:
				case TY.Timaginary32:
				case TY.Tfloat32:	fvalue = float.max;	goto Lfvalue;
				case TY.Tcomplex64:
				case TY.Timaginary64:
				case TY.Tfloat64:	fvalue = double.max;goto Lfvalue;
				case TY.Tcomplex80:
				case TY.Timaginary80:
				case TY.Tfloat80:	fvalue = real.max;	goto Lfvalue;
				default:
			}
		}
		else if (ident is Id.min)
		{
			switch (ty)
			{
				case TY.Tint8:		ivalue = byte.min;		goto Livalue;
				case TY.Tuns8:		ivalue = ubyte.min;		goto Livalue;
				case TY.Tint16:		ivalue = short.min;		goto Livalue;
				case TY.Tuns16:		ivalue = ushort.min;	goto Livalue;
				case TY.Tint32:		ivalue = int.min;		goto Livalue;
				case TY.Tuns32:		ivalue = uint.min;		goto Livalue;
				case TY.Tint64:		ivalue = long.min;		goto Livalue;
				case TY.Tuns64:		ivalue = ulong.min;		goto Livalue;
				case TY.Tbool:		ivalue = bool.min;		goto Livalue;
				case TY.Tchar:		ivalue = char.min;		goto Livalue;
				case TY.Twchar:		ivalue = wchar.min;		goto Livalue;
				case TY.Tdchar:		ivalue = dchar.min;		goto Livalue;
				case TY.Tcomplex32:
				case TY.Timaginary32:
				case Tfloat32:
				case Tcomplex64:
				case Timaginary64:
				case Tfloat64:
				case Tcomplex80:
				case Timaginary80:
				case Tfloat80:
						// For backwards compatibility - eventually, deprecate
						goto Lmin_normal;
				default:
			}
		}
		else if (ident == Id.min_normal)
		{
	Lmin_normal:
			switch (ty)
			{
				case Tcomplex32:
				case Timaginary32:
				case TY.Tfloat32:	fvalue = float.min;		goto Lfvalue;
				case TY.Tcomplex64:
				case TY.Timaginary64:
				case TY.Tfloat64:	fvalue = double.min;		goto Lfvalue;
				case TY.Tcomplex80:
				case TY.Timaginary80:
				case TY.Tfloat80:	fvalue = real.min;		goto Lfvalue;
                default:
			}
		}
		else if (ident is Id.nan)
		{
			switch (ty)
			{
				case TY.Tcomplex32:
				case TY.Tcomplex64:
				case TY.Tcomplex80:
				case TY.Timaginary32:
				case TY.Timaginary64:
				case TY.Timaginary80:
				case TY.Tfloat32:
				case TY.Tfloat64:
				case TY.Tfloat80:
				{
					fvalue = real.nan;
					goto Lfvalue;
				}
				default:
			}
		}
		else if (ident is Id.infinity)
		{
			switch (ty)
			{
				case TY.Tcomplex32:
				case TY.Tcomplex64:
				case TY.Tcomplex80:
				case TY.Timaginary32:
				case TY.Timaginary64:
				case TY.Timaginary80:
				case TY.Tfloat32:
				case TY.Tfloat64:
				case TY.Tfloat80:
					fvalue = real.infinity;
					goto Lfvalue;
				default:
			}
		}
		else if (ident is Id.dig)
		{
			switch (ty)
			{
				case TY.Tcomplex32:
				case TY.Timaginary32:
				case TY.Tfloat32:	ivalue = float.dig;	goto Lint;
				case TY.Tcomplex64:
				case TY.Timaginary64:
				case TY.Tfloat64:	ivalue = double.dig;	goto Lint;
				case TY.Tcomplex80:
				case TY.Timaginary80:
				case TY.Tfloat80:	ivalue = real.dig;	goto Lint;
				default:
			}
		}
		else if (ident is Id.epsilon)
		{
			switch (ty)
			{
				case TY.Tcomplex32:
				case TY.Timaginary32:
				case TY.Tfloat32:	fvalue = float.epsilon;	goto Lfvalue;
				case TY.Tcomplex64:
				case TY.Timaginary64:
				case TY.Tfloat64:	fvalue = double.epsilon;	goto Lfvalue;
				case TY.Tcomplex80:
				case TY.Timaginary80:
				case TY.Tfloat80:	fvalue = real.epsilon;	goto Lfvalue;
				default:
			}
		}
		else if (ident is Id.mant_dig)
		{
			switch (ty)
			{
				case TY.Tcomplex32:
				case TY.Timaginary32:
				case TY.Tfloat32:	ivalue = float.mant_dig;	goto Lint;
				case TY.Tcomplex64:
				case TY.Timaginary64:
				case TY.Tfloat64:	ivalue = double.mant_dig;	goto Lint;
				case TY.Tcomplex80:
				case TY.Timaginary80:
				case TY.Tfloat80:	ivalue = real.mant_dig; goto Lint;
				default:
			}
		}
		else if (ident is Id.max_10_exp)
		{
			switch (ty)
			{
				case TY.Tcomplex32:
				case TY.Timaginary32:
				case TY.Tfloat32:	ivalue = float.max_10_exp;	goto Lint;
				case TY.Tcomplex64:
				case TY.Timaginary64:
				case TY.Tfloat64:	ivalue = double.max_10_exp;	goto Lint;
				case TY.Tcomplex80:
				case TY.Timaginary80:
				case TY.Tfloat80:	ivalue = real.max_10_exp;	goto Lint;
				default:
			}
		}
		else if (ident is Id.max_exp)
		{
			switch (ty)
			{
				case TY.Tcomplex32:
				case TY.Timaginary32:
				case TY.Tfloat32:	ivalue = float.max_exp;	goto Lint;
				case TY.Tcomplex64:
				case TY.Timaginary64:
				case TY.Tfloat64:	ivalue = double.max_exp;	goto Lint;
				case TY.Tcomplex80:
				case TY.Timaginary80:
				case TY.Tfloat80:	ivalue = real.max_exp;	goto Lint;
				default:
			}
		}
		else if (ident is Id.min_10_exp)
		{
			switch (ty)
			{
				case TY.Tcomplex32:
				case TY.Timaginary32:
				case TY.Tfloat32:	ivalue = float.min_10_exp;	goto Lint;
				case TY.Tcomplex64:
				case TY.Timaginary64:
				case TY.Tfloat64:	ivalue = double.min_10_exp;	goto Lint;
				case TY.Tcomplex80:
				case TY.Timaginary80:
				case TY.Tfloat80:	ivalue = real.min_10_exp;	goto Lint;
				default:
			}
		}
		else if (ident is Id.min_exp)
		{
			switch (ty)
			{
				case TY.Tcomplex32:
				case TY.Timaginary32:
				case TY.Tfloat32:	ivalue = float.min_exp;	goto Lint;
				case TY.Tcomplex64:
				case TY.Timaginary64:
				case TY.Tfloat64:	ivalue = double.min_exp;	goto Lint;
				case TY.Tcomplex80:
				case TY.Timaginary80:
				case TY.Tfloat80:	ivalue = real.min_exp;	goto Lint;
				default:
			}
		}

	Ldefault:
		return Type.getProperty(loc, ident);

	Livalue:
		e = new IntegerExp(loc, ivalue, this);
		return e;

	Lfvalue:
		if (isreal() || isimaginary())
			e = new RealExp(loc, fvalue, this);
		else
		{
			Complex!(real) cvalue;
			cvalue.re = fvalue;
			cvalue.im = fvalue;

			//for (int i = 0; i < 20; i++)
			//	printf("%02x ", ((unsigned char *)&cvalue)[i]);
			//printf("\n");
			e = new ComplexExp(loc, cvalue, this);
		}
		return e;

	Lint:
		e = new IntegerExp(loc, ivalue, Type.tint32);
		return e;
	}
	
    override Expression dotExp(Scope sc, Expression e, Identifier ident)
	{
version (LOGDOTEXP) {
		printf("TypeBasic.dotExp(e = '%s', ident = '%s')\n", e.toChars(), ident.toChars());
}
		Type t;

		if (ident is Id.re)
		{
			switch (ty)
			{
				case TY.Tcomplex32:	t = tfloat32;		goto L1;
				case TY.Tcomplex64:	t = tfloat64;		goto L1;
				case TY.Tcomplex80:	t = tfloat80;		goto L1;
				L1:
					e = e.castTo(sc, t);
					break;

				case TY.Tfloat32:
				case TY.Tfloat64:
				case TY.Tfloat80:
					break;

				case TY.Timaginary32:	t = tfloat32;		goto L2;
				case TY.Timaginary64:	t = tfloat64;		goto L2;
				case TY.Timaginary80:	t = tfloat80;		goto L2;
				L2:
					e = new RealExp(Loc(0), 0.0, t);
					break;

				default:
		            e = Type.getProperty(e.loc, ident);
		            break;
			}
		}
		else if (ident is Id.im)
		{	
			Type t2;

			switch (ty)
			{
				case TY.Tcomplex32:	t = timaginary32;	t2 = tfloat32;	goto L3;
				case TY.Tcomplex64:	t = timaginary64;	t2 = tfloat64;	goto L3;
				case TY.Tcomplex80:	t = timaginary80;	t2 = tfloat80;	goto L3;
				L3:
					e = e.castTo(sc, t);
					e.type = t2;
					break;

				case TY.Timaginary32:	t = tfloat32;	goto L4;
				case TY.Timaginary64:	t = tfloat64;	goto L4;
				case TY.Timaginary80:	t = tfloat80;	goto L4;
				L4:
					e = e.copy();
					e.type = t;
					break;

				case TY.Tfloat32:
				case TY.Tfloat64:
				case TY.Tfloat80:
					e = new RealExp(Loc(0), 0.0, this);
					break;

				default:
		            e = Type.getProperty(e.loc, ident);
		            break;
			}
		}
		else
		{
			return Type.dotExp(sc, e, ident);
		}
        e = e.semantic(sc);
		return e;
	}
	
    override string toChars()
	{
		return Type.toChars();
	}
	
    override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		//printf("TypeBasic.toCBuffer2(mod = %d, this.mod = %d)\n", mod, this.mod);
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		buf.writestring(dstring);
	}
	
version (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState* cms)
	{
		assert(false);
	}
}
    override bool isintegral()
	{
		//printf("TypeBasic.isintegral('%s') x%x\n", toChars(), flags);
		return (flags & TFLAGS.TFLAGSintegral) != 0;
	}
	
    bool isbit()
	{
		assert(false);
	}
	
    override bool isfloating()
	{
		return (flags & TFLAGS.TFLAGSfloating) != 0;
	}
	
    override bool isreal()
	{
		return (flags & TFLAGS.TFLAGSreal) != 0;
	}
	
    override bool isimaginary()
	{
		return (flags & TFLAGS.TFLAGSimaginary) != 0;
	}
	
    override bool iscomplex()
	{
		return (flags & TFLAGS.TFLAGScomplex) != 0;
	}

    override bool isscalar()
	{
		return (flags & (TFLAGS.TFLAGSintegral | TFLAGS.TFLAGSfloating)) != 0;
	}
	
    override bool isunsigned()
	{
		return (flags & TFLAGS.TFLAGSunsigned) != 0;
	}
	
    override MATCH implicitConvTo(Type to)
	{
		//printf("TypeBasic.implicitConvTo(%s) from %s\n", to.toChars(), toChars());
		if (this is to)
			return MATCH.MATCHexact;

version (DMDV2) {
		if (ty is to.ty)
		{
			return (mod == to.mod) ? MATCH.MATCHexact : MATCH.MATCHconst;
		}
}

		if (ty == TY.Tvoid || to.ty == TY.Tvoid)
			return MATCH.MATCHnomatch;
		if (to.ty == TY.Tbool)
			return MATCH.MATCHnomatch;
		if (!to.isTypeBasic())
			return MATCH.MATCHnomatch;

		TypeBasic tob = cast(TypeBasic)to;
		if (flags & TFLAGS.TFLAGSintegral)
		{
		// Disallow implicit conversion of integers to imaginary or complex
		if (tob.flags & (TFLAGS.TFLAGSimaginary | TFLAGS.TFLAGScomplex))
			return MATCH.MATCHnomatch;

version (DMDV2) {
		// If converting from integral to integral
		if (1 && tob.flags & TFLAGS.TFLAGSintegral)
		{   ulong sz = size(Loc(0));
			ulong tosz = tob.size(Loc(0));

			/* Can't convert to smaller size
			 */
			if (sz > tosz)
			return MATCH.MATCHnomatch;

			/* Can't change sign if same size
			 */
			/*if (sz == tosz && (flags ^ tob.flags) & TFLAGSunsigned)
			return MATCH.MATCHnomatch;*/
		}
}
		}
		else if (flags & TFLAGS.TFLAGSfloating)
		{
		// Disallow implicit conversion of floating point to integer
		if (tob.flags & TFLAGS.TFLAGSintegral)
			return MATCH.MATCHnomatch;

		assert(tob.flags & TFLAGS.TFLAGSfloating);

		// Disallow implicit conversion from complex to non-complex
		if (flags & TFLAGS.TFLAGScomplex && !(tob.flags & TFLAGS.TFLAGScomplex))
			return MATCH.MATCHnomatch;

		// Disallow implicit conversion of real or imaginary to complex
		if (flags & (TFLAGS.TFLAGSreal | TFLAGS.TFLAGSimaginary) &&
			tob.flags & TFLAGS.TFLAGScomplex)
			return MATCH.MATCHnomatch;

		// Disallow implicit conversion to-from real and imaginary
		if ((flags & (TFLAGS.TFLAGSreal | TFLAGS.TFLAGSimaginary)) !=
			(tob.flags & (TFLAGS.TFLAGSreal | TFLAGS.TFLAGSimaginary)))
			return MATCH.MATCHnomatch;
		}
		return MATCH.MATCHconvert;
	}
	
    override Expression defaultInit(Loc loc)
	{
		long value = 0;

version (SNAN_DEFAULT_INIT) {
		/*
		 * Use a payload which is different from the machine NaN,
		 * so that uninitialised variables can be
		 * detected even if exceptions are disabled.
		 */
		ushort[8] snan = [ 0, 0, 0, 0xA000, 0x7FFF, 0, 0, 0 ];
		/*
		 * Although long doubles are 10 bytes long, some
		 * C ABIs pad them out to 12 or even 16 bytes, so
		 * leave enough space in the snan array.
		 */
		assert(REALSIZE <= snan.sizeof);
		real fvalue = *cast(real*)snan.ptr;
}

	version (LOGDEFAULTINIT) {
		printf("TypeBasic.defaultInit() '%s'\n", toChars());
	}
		switch (ty)
		{
			case TY.Tchar:
				value = 0xFF;
				break;

			case TY.Twchar:
			case TY.Tdchar:
				value = 0xFFFF;
				break;

			case TY.Timaginary32:
			case TY.Timaginary64:
			case TY.Timaginary80:
			case TY.Tfloat32:
			case TY.Tfloat64:
			case TY.Tfloat80:
	version (SNAN_DEFAULT_INIT) {
				return new RealExp(loc, fvalue, this);
	} else {
				return getProperty(loc, Id.nan);
	}

			case TY.Tcomplex32:
			case TY.Tcomplex64:
			case TY.Tcomplex80:
	version (SNAN_DEFAULT_INIT) {
			{   
				// Can't use fvalue + I*fvalue (the im part becomes a quiet NaN).
				Complex!(real) cvalue;
				cvalue.re = fvalue;
				cvalue.im = fvalue;

				return new ComplexExp(loc, cvalue, this);
			}
	} else {
				return getProperty(loc, Id.nan);
	}

			case TY.Tvoid:
				error(loc, "void does not have a default initializer");

			default:
				break;		///
		}
		return new IntegerExp(loc, value, this);
	}
	
    override bool isZeroInit(Loc loc)
	{
		switch (ty)
		{
			case TY.Tchar:
			case TY.Twchar:
			case TY.Tdchar:
			case TY.Timaginary32:
			case TY.Timaginary64:
			case TY.Timaginary80:
			case TY.Tfloat32:
			case TY.Tfloat64:
			case TY.Tfloat80:
			case TY.Tcomplex32:
			case TY.Tcomplex64:
			case TY.Tcomplex80:
				return false;		// no
			default:
				break;
		}

		return true;			// yes
	}
	
    override bool builtinTypeInfo()
	{
	version (DMDV2) {
		return mod ? false : true;
	} else {
		return true;
	}
	}
	
    // For eliminating dynamic_cast
    override TypeBasic isTypeBasic()
	{
		return this;
	}
}
