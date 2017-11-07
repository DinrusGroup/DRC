module dmd.CastExp;

import dmd.common;
import dmd.Expression;
import dmd.GlobalExpressions;
import dmd.TY;
import dmd.TypeStruct;
import dmd.ErrorExp;
import dmd.TypeExp;
import dmd.DotIdExp;
import dmd.CallExp;
import dmd.Global;
import dmd.Id;
import dmd.Identifier;
import dmd.BinExp;
import dmd.UnaExp;
import dmd.VarExp;
import dmd.Token;
import dmd.VarDeclaration;
import dmd.InterState;
import dmd.MATCH;
import dmd.Type;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IntRange;
import dmd.IRState;
import dmd.ArrayTypes;
import dmd.HdrGenState;
import dmd.MOD;
import dmd.TOK;
import dmd.WANT;
import dmd.ClassDeclaration;

import dmd.Optimize;
import dmd.PREC;
import dmd.Cast;

import dmd.codegen.Util;
import dmd.backend.elem;
import dmd.backend.mTY;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.OPER;
import dmd.backend.RTLSYM;
import dmd.expression.Util;

import dmd.DDMDExtensions;

class CastExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	// Possible to cast to one type while painting to another type
	Type to;				// type to cast to
	MOD mod;				// MODxxxxx

	this(Loc loc, Expression e, Type t)
	{
		register();

		super(loc, TOK.TOKcast, CastExp.sizeof, e);
		to = t;
		this.mod = cast(MOD)~0;
	}

	this(Loc loc, Expression e, MOD mod)
	{
		register();

		super(loc, TOK.TOKcast, CastExp.sizeof, e);
		to = null;
		this.mod = mod;
	}

	override Expression syntaxCopy()
	{
		return to ? new CastExp(loc, e1.syntaxCopy(), to.syntaxCopy())
	      : new CastExp(loc, e1.syntaxCopy(), mod);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;
		BinExp b;
		UnaExp u;

version (LOGSEMANTIC) {
		printf("CastExp.semantic('%s')\n", toChars());
}

		//static int x; assert(++x < 10);

		if (type)
			return this;
		super.semantic(sc);
		if (e1.type)		// if not a tuple
		{
			e1 = resolveProperties(sc, e1);

			if (!to)
			{
				/* Handle cast(const) and cast(immutable), etc.
				 */
				to = e1.type.castMod(mod);
			}
			else
				to = to.semantic(loc, sc);

			if (!to.equals(e1.type))
			{
				e = op_overload(sc);
				if (e)
				{
				return e.implicitCastTo(sc, to);
				}
			}

			if (e1.op == TOKtemplate)
			{
			    error("cannot cast template %s to type %s", e1.toChars(), to.toChars());
			    return new ErrorExp();
			}

			Type t1b = e1.type.toBasetype();
			Type tob = to.toBasetype();
			if (tob.ty == TY.Tstruct &&
				!tob.equals(t1b) &&
				(cast(TypeStruct)tob).sym.search(Loc(0), Id.call, 0)
			   )
			{
				/* Look to replace:
				 *	cast(S)t
				 * with:
				 *	S(t)
				 */

				// Rewrite as to.call(e1)
				e = new TypeExp(loc, to);
				e = new DotIdExp(loc, e, Id.call);
				e = new CallExp(loc, e, e1);
				e = e.semantic(sc);
				return e;
			}
			
			// Struct casts are possible only when the sizes match
			if (tob.ty == Tstruct || t1b.ty == Tstruct)
			{
				size_t fromsize = cast(size_t)t1b.size(loc);
				size_t tosize = cast(size_t)tob.size(loc);
				if (fromsize != tosize)
				{
					error("cannot cast from %s to %s", e1.type.toChars(), to.toChars());
					return new ErrorExp();
				}
			}
		}
		else if (!to)
		{	
			error("cannot cast tuple");
			to = Type.terror;
		}

//static if (true) {
		if (sc.func && sc.func.isSafe() && !sc.intypeof)
//} else {
//		if (global.params.safe && !sc.module_.safe && !sc.intypeof)
//}
		{	// Disallow unsafe casts
			Type tob = to.toBasetype();
			Type t1b = e1.type.toBasetype();
			if (!t1b.isMutable() && tob.isMutable())
			{   // Cast not mutable to mutable
			  Lunsafe:
				error("cast from %s to %s not allowed in safe code", e1.type.toChars(), to.toChars());
			}
			else if (t1b.isShared() && !tob.isShared())
				// Cast away shared
				goto Lunsafe;
			else if (tob.ty == TY.Tpointer)
			{   if (t1b.ty != TY.Tpointer)
				goto Lunsafe;
				Type tobn = tob.nextOf().toBasetype();
				Type t1bn = t1b.nextOf().toBasetype();

				if (!t1bn.isMutable() && tobn.isMutable())
					// Cast away pointer to not mutable
					goto Lunsafe;

				if (t1bn.isShared() && !tobn.isShared())
					// Cast away pointer to shared
					goto Lunsafe;

        	    if (t1bn.isWild() && !tobn.isConst() && !tobn.isWild())
            		// Cast wild to anything but const | wild
		            goto Lunsafe;

				if (tobn.isTypeBasic() && tobn.size() < t1bn.size()) {
					// Allow things like casting a long* to an int*
					//;
				} else if (tobn.ty != TY.Tvoid) {
					// Cast to a pointer other than void*
					goto Lunsafe;
				}
			}

			// BUG: Check for casting array types, such as void[] to int*[]
		}

		e = e1.castTo(sc, to);
		return e;
	}

	override MATCH implicitConvTo(Type t)
	{
	static if (false) {
		printf("CastExp::implicitConvTo(this=%s, type=%s, t=%s)\n", toChars(), type.toChars(), t.toChars());
	}
		MATCH result = type.implicitConvTo(t);

		if (result == MATCHnomatch)
		{
			if (t.isintegral() &&
				e1.type.isintegral() &&
				e1.implicitConvTo(t) != MATCHnomatch)
				result = MATCHconvert;
			else
				result = Expression.implicitConvTo(t);
		}
		return result;
	}

	override IntRange getIntRange()
	{
		IntRange ir;
		ir = e1.getIntRange();
		// Do sign extension
		switch (e1.type.toBasetype().ty)
		{
		case Tint8:
			if (ir.imax & 0x80)
			ir.imax |= 0xFFFFFFFFFFFFFF00UL;
			break;
		case Tint16:
			if (ir.imax & 0x8000)
			ir.imax |= 0xFFFFFFFFFFFF0000UL;
			break;
		case Tint32:
			if (ir.imax & 0x80000000)
			ir.imax |= 0xFFFFFFFF00000000UL;
			break;
		default:
		}
		
		if (type.isintegral())
		{
			ir.imin &= type.sizemask();
			ir.imax &= type.sizemask();
		}

		//printf("CastExp: imin = x%llx, imax = x%llx\n", ir.imin, ir.imax);
		return ir;
	}

	override Expression optimize(int result)
	{
		//printf("CastExp.optimize(result = %d) %s\n", result, toChars());
		//printf("from %s to %s\n", type.toChars(), to.toChars());
		//printf("from %s\n", type.toChars());
		//printf("e1.type %s\n", e1.type.toChars());
		//printf("type = %p\n", type);
		assert(type);
		TOK op1 = e1.op;

		Expression e1old = e1;
		e1 = e1.optimize(result);
		e1 = fromConstInitializer(result, e1);

		if (e1 == e1old &&
		e1.op == TOK.TOKarrayliteral &&
		type.toBasetype().ty == TY.Tpointer &&
		e1.type.toBasetype().ty != TY.Tsarray)
		{
		// Casting this will result in the same expression, and
		// infinite loop because of Expression.implicitCastTo()
		return this;		// no change
		}

		if ((e1.op == TOK.TOKstring || e1.op == TOK.TOKarrayliteral) &&
		(type.ty == TY.Tpointer || type.ty == TY.Tarray) &&
		e1.type.nextOf().size() == type.nextOf().size()
		   )
		{
		Expression e = e1.castTo(null, type);

static if (false) {
		printf(" returning1 %s\n", e.toChars());
}
		return e;
		}

		if (e1.op == TOK.TOKstructliteral &&
		e1.type.implicitConvTo(type) >= MATCH.MATCHconst)
		{
		e1.type = type;
static if (false) {
		printf(" returning2 %s\n", e1.toChars());
}
		return e1;
		}

		/* The first test here is to prevent infinite loops
		 */
		if (op1 != TOK.TOKarrayliteral && e1.op == TOK.TOKarrayliteral)
		return e1.castTo(null, to);
		if (e1.op == TOK.TOKnull &&
		(type.ty == TY.Tpointer || type.ty == TY.Tclass || type.ty == TY.Tarray))
		{
		e1.type = type;
static if (false) {
		printf(" returning3 %s\n", e1.toChars());
}
		return e1;
		}

		if (result & WANT.WANTflags && type.ty == TY.Tclass && e1.type.ty == TY.Tclass)
		{
		// See if we can remove an unnecessary cast
		ClassDeclaration cdfrom;
		ClassDeclaration cdto;
		int offset;

		cdfrom = e1.type.isClassHandle();
		cdto   = type.isClassHandle();
		if (cdto.isBaseOf(cdfrom, &offset) && offset == 0)
		{
			e1.type = type;
static if (false) {
			printf(" returning4 %s\n", e1.toChars());
}
			return e1;
		}
		}

		// We can convert 'head const' to mutable
		if (to.constOf().equals(e1.type.constOf()))
	//    if (to.constConv(e1.type) >= MATCHconst)
		{
		e1.type = type;
static if (false) {
		printf(" returning5 %s\n", e1.toChars());
}
		return e1;
		}

		Expression e;

		if (e1.isConst())
		{
		if (e1.op == TOK.TOKsymoff)
		{
			if (type.size() == e1.type.size() &&
			type.toBasetype().ty != TY.Tsarray)
			{
			e1.type = type;
			return e1;
			}
			return this;
		}
		if (to.toBasetype().ty == TY.Tvoid)
			e = this;
		else
			e = Cast(type, to, e1);
		}
		else
		e = this;
static if (false) {
		printf(" returning6 %s\n", e.toChars());
}
		return e;
	}

	override Expression interpret(InterState istate)
	{
		Expression e;
		Expression e1;

version (LOG) {
		printf("CastExp.interpret() %.*s\n", toChars());
}
		e1 = this.e1.interpret(istate);
		if (e1 is EXP_CANT_INTERPRET)
			goto Lcant;
		return Cast(type, to, e1);

	Lcant:
version (LOG) {
		printf("CastExp.interpret() %.*s CANT\n", toChars());
}
		return EXP_CANT_INTERPRET;
	}

	override bool checkSideEffect(int flag)
	{
		/* if not:
		 *  cast(void)
		 *  cast(classtype)func()
		 */
		if (!to.equals(Type.tvoid) && !(to.ty == Tclass && e1.op == TOKcall && e1.type.ty == Tclass))
			return Expression.checkSideEffect(flag);
			
		return true;
	}

	override void checkEscape()
	{
		Type tb = type.toBasetype();
		if (tb.ty == TY.Tarray && e1.op == TOK.TOKvar && e1.type.toBasetype().ty ==TY.Tsarray)
		{	
			VarExp ve = cast(VarExp)e1;
			VarDeclaration v = ve.var.isVarDeclaration();
			if (v)
			{
				if (!v.isDataseg() && !v.isParameter())
					error("escaping reference to local %s", v.toChars());
			}
		}
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("cast(");
	version (DMDV1) {
		to.toCBuffer(buf, null, hgs);
	} else {
		if (to)
			to.toCBuffer(buf, null, hgs);
		else
		{
			MODtoBuffer(buf, mod);
		}
	}
		buf.writeByte(')');
		expToCBuffer(buf, hgs, e1, precedence[op]);
	}

	override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		Type tb = type.toBasetype();
		if (tb.ty == Tarray || tb.ty == Tsarray)
		{
			e1.buildArrayIdent(buf, arguments);
		}
		else
			Expression.buildArrayIdent(buf, arguments);
	}

	override Expression buildArrayLoop(Parameters fparams)
	{
		Type tb = type.toBasetype();
		if (tb.ty == Tarray || tb.ty == Tsarray)
		{
			return e1.buildArrayLoop(fparams);
		}
		else
			return Expression.buildArrayLoop(fparams);
	}
	
	static int X(int fty, int tty) {
		return ((fty) * TY.TMAX + (tty));
	}

	override elem* toElem(IRState* irs)
	{
		TY fty;
		TY tty;
		tym_t ftym;
		tym_t ttym;
		OPER eop;

static if (false)
{
		printf("CastExp::toElem()\n");
		print();
		printf("\tfrom: %s\n", e1.type.toChars());
		printf("\tto  : %s\n", to.toChars());
}

		elem* e = e1.toElem(irs);
		Type tfrom = e1.type.toBasetype();
		Type t = to.toBasetype();		// skip over typedef's
		if (t.equals(tfrom))
			goto Lret;

		fty = tfrom.ty;
		//printf("fty = %d\n", fty);
		tty = t.ty;

		if (tty == TY.Tpointer && fty == TY.Tarray
///static if (false) {
///		&& (t.next.ty == Tvoid || t.next.equals(e1.type.next))
///}
		   )
		{
			if (e.Eoper == OPER.OPvar)
			{
				// e1 . *(&e1 + 4)
				e = el_una(OPER.OPaddr, TYM.TYnptr, e);
				e = el_bin(OPER.OPadd, TYM.TYnptr, e, el_long(TYM.TYint, 4));
				e = el_una(OPER.OPind, t.totym(),e);
			}
			else
			{
				// e1 . (unsigned)(e1 >> 32)
				e = el_bin(OPER.OPshr, TYM.TYullong, e, el_long(TYM.TYint, 32));
				e = el_una(OPER.OP64_32, t.totym(), e);
			}
			goto Lret;
		}

		if (tty == TY.Tpointer && fty == TY.Tsarray
///static if (false) {
///		&& (t.next.ty == Tvoid || t.next.equals(e1.type.next))
///}
		)
		{
			// e1 . &e1
			e = el_una(OPER.OPaddr, TYM.TYnptr, e);
			goto Lret;
		}

		// Convert from static array to dynamic array
		if (tty == TY.Tarray && fty == TY.Tsarray)
		{
			e = sarray_toDarray(loc, tfrom, t, e);
			goto Lret;
		}

		// Convert from dynamic array to dynamic array
		if (tty == TY.Tarray && fty == TY.Tarray)
		{
			uint fsize = cast(uint)tfrom.nextOf().size();
			uint tsize = cast(uint)t.nextOf().size();

			if (fsize != tsize)
			{
				elem* ep = el_params(e, el_long(TYM.TYint, fsize), el_long(TYM.TYint, tsize), null);
				e = el_bin(OPER.OPcall, type.totym(), el_var(rtlsym[RTLSYM.RTLSYM_ARRAYCAST]), ep);
			}
			goto Lret;
		}

static if (false)
{
		// Convert from dynamic array string literal to static array
		if (tty == TY.Tsarray && fty == TY.Tarray && e1.op == TOK.TOKstring)
		{
			goto Lret;	// treat as a 'paint'
		}
}

		// Casting from base class to derived class requires a runtime check
		if (fty == TY.Tclass && tty == TY.Tclass)
		{
			// Casting from derived class to base class is a no-op
			ClassDeclaration cdfrom;
			ClassDeclaration cdto;
			int offset;
			int rtl = RTLSYM.RTLSYM_DYNAMIC_CAST;

			cdfrom = tfrom.isClassHandle();
			cdto   = t.isClassHandle();
			if (cdfrom.isInterfaceDeclaration())
			{
				rtl = RTLSYM.RTLSYM_INTERFACE_CAST;
				if (cdfrom.isCPPinterface())
				{
					if (cdto.isCPPinterface())
					{
						/* Casting from a C++ interface to a C++ interface
						 * is always a 'paint' operation
						 */
						goto Lret;			// no-op
					}

					/* Casting from a C++ interface to a class
					 * always results in null because there is no runtime
					 * information available to do it.
					 *
					 * Casting from a C++ interface to a non-C++ interface
					 * always results in null because there's no way one
					 * can be derived from the other.
					 */
					e = el_bin(OPER.OPcomma, TYM.TYnptr, e, el_long(TYM.TYnptr, 0));
					goto Lret;
				}
			}
			if (cdto.isBaseOf(cdfrom, &offset) && offset != OFFSET_RUNTIME)
			{
				/* The offset from cdfrom=>cdto is known at compile time.
				 */
			
				//printf("offset = %d\n", offset);
				if (offset)
				{
					/* Rewrite cast as (e ? e + offset : null)
					 */
					elem* etmp;
					elem* ex;

					if (e1.op == TOK.TOKthis)
					{   
						// Assume 'this' is never null, so skip null check
						e = el_bin(OPER.OPadd, TYM.TYnptr, e, el_long(TYM.TYint, offset));
					}
					else
					{
						etmp = el_same(&e);
						ex = el_bin(OPER.OPadd, TYM.TYnptr, etmp, el_long(TYM.TYint, offset));
						ex = el_bin(OPER.OPcolon, TYM.TYnptr, ex, el_long(TYM.TYnptr, 0));
						e = el_bin(OPER.OPcond, TYM.TYnptr, e, ex);
					}
				}
				goto Lret;			// no-op
			}

			/* The offset from cdfrom=>cdto can only be determined at runtime.
			 */
			elem* ep;

			ep = el_param(el_ptr(cdto.toSymbol()), e);
			e = el_bin(OPER.OPcall, TYM.TYnptr, el_var(rtlsym[rtl]), ep);
			goto Lret;
		}

		ftym = tybasic(e.Ety);
		ttym = tybasic(t.totym());
		if (ftym == ttym)
		goto Lret;

		switch (tty)
		{
			case TY.Tpointer:
				if (fty == TY.Tdelegate)
					goto Lpaint;
				tty = TY.Tuns32;
				break;

			case TY.Tchar:
				tty = TY.Tuns8;	
				break;
			case TY.Twchar:
				tty = TY.Tuns16;	
				break;
			case TY.Tdchar:	
				tty = TY.Tuns32;	
				break;
			case TY.Tvoid:	
				goto Lpaint;

			case TY.Tbool:
			{
				// Construct e?true:false
				elem* eq;

				e = el_una(OPER.OPbool, ttym, e);
				goto Lret;
			}
			
			default:
				break;	///
		}

		switch (fty)
		{
			case TY.Tpointer:	fty = TY.Tuns32;	break;
			case TY.Tchar:		fty = TY.Tuns8;		break;
			case TY.Twchar:		fty = TY.Tuns16;	break;
			case TY.Tdchar:		fty = TY.Tuns32;	break;
			default:	break;	///
		}

	Lagain:
		switch (X(fty,tty))
		{
static if (false)
{
			case X(TY.Tbit,TY.Tint8):
			case X(TY.Tbit,TY.Tuns8):
				goto Lpaint;
			case X(TY.Tbit,TY.Tint16):
			case X(TY.Tbit,TY.Tuns16):
			case X(TY.Tbit,TY.Tint32):
			case X(TY.Tbit,TY.Tuns32):	
				eop = OPu8_16;
				goto Leop;
			case X(TY.Tbit,TY.Tint64):
			case X(TY.Tbit,TY.Tuns64):
			case X(TY.Tbit,TY.Tfloat32):
			case X(TY.Tbit,TY.Tfloat64):
			case X(TY.Tbit,TY.Tfloat80):
			case X(TY.Tbit,TY.Tcomplex32):
			case X(TY.Tbit,TY.Tcomplex64):
			case X(TY.Tbit,TY.Tcomplex80):
				e = el_una(OPER.OPu8_16, TYM.TYuint, e);
				fty = TY.Tuns32;
				goto Lagain;
			case X(Tbit,Timaginary32):
			case X(Tbit,Timaginary64):
			case X(Tbit,Timaginary80):
				goto Lzero;
}
		/* ============================= */

		case X(TY.Tbool,TY.Tint8):
		case X(TY.Tbool,TY.Tuns8):
			goto Lpaint;
		case X(TY.Tbool,TY.Tint16):
		case X(TY.Tbool,TY.Tuns16):
		case X(TY.Tbool,TY.Tint32):
		case X(TY.Tbool,TY.Tuns32):
			eop = OPER.OPu8_16;
			goto Leop;
		case X(TY.Tbool,TY.Tint64):
		case X(TY.Tbool,TY.Tuns64):
		case X(TY.Tbool,TY.Tfloat32):
		case X(TY.Tbool,TY.Tfloat64):
		case X(TY.Tbool,TY.Tfloat80):
		case X(TY.Tbool,TY.Tcomplex32):
		case X(TY.Tbool,TY.Tcomplex64):
		case X(TY.Tbool,TY.Tcomplex80):
			e = el_una(OPER.OPu8_16, TYM.TYuint, e);
			fty = TY.Tuns32;
			goto Lagain;
		case X(TY.Tbool,TY.Timaginary32):
		case X(TY.Tbool,TY.Timaginary64):
		case X(TY.Tbool,TY.Timaginary80):
			goto Lzero;

		/* ============================= */

		case X(TY.Tint8,TY.Tuns8):
			goto Lpaint;
		case X(TY.Tint8,TY.Tint16):
		case X(TY.Tint8,TY.Tuns16):
		case X(TY.Tint8,TY.Tint32):
		case X(TY.Tint8,TY.Tuns32):
			eop = OPER.OPs8_16;
			goto Leop;
		case X(TY.Tint8,TY.Tint64):
		case X(TY.Tint8,TY.Tuns64):
		case X(TY.Tint8,TY.Tfloat32):
		case X(TY.Tint8,TY.Tfloat64):
		case X(TY.Tint8,TY.Tfloat80):
		case X(TY.Tint8,TY.Tcomplex32):
		case X(TY.Tint8,TY.Tcomplex64):
		case X(TY.Tint8,TY.Tcomplex80):
			e = el_una(OPER.OPs8_16, TYM.TYint, e);
			fty = TY.Tint32;
			goto Lagain;
		case X(TY.Tint8,TY.Timaginary32):
		case X(TY.Tint8,TY.Timaginary64):
		case X(TY.Tint8,TY.Timaginary80):
			goto Lzero;

		/* ============================= */

		case X(TY.Tuns8,TY.Tint8):
			goto Lpaint;
		case X(TY.Tuns8,TY.Tint16):
		case X(TY.Tuns8,TY.Tuns16):
		case X(TY.Tuns8,TY.Tint32):
		case X(TY.Tuns8,TY.Tuns32):
			eop = OPER.OPu8_16;
			goto Leop;
		case X(TY.Tuns8,TY.Tint64):
		case X(TY.Tuns8,TY.Tuns64):
		case X(TY.Tuns8,TY.Tfloat32):
		case X(TY.Tuns8,TY.Tfloat64):
		case X(TY.Tuns8,TY.Tfloat80):
		case X(TY.Tuns8,TY.Tcomplex32):
		case X(TY.Tuns8,TY.Tcomplex64):
		case X(TY.Tuns8,TY.Tcomplex80):
			e = el_una(OPER.OPu8_16, TYM.TYuint, e);
			fty = TY.Tuns32;
			goto Lagain;
		case X(TY.Tuns8,TY.Timaginary32):
		case X(TY.Tuns8,TY.Timaginary64):
		case X(TY.Tuns8,TY.Timaginary80):
			goto Lzero;

		/* ============================= */

		case X(TY.Tint16,TY.Tint8):
		case X(TY.Tint16,TY.Tuns8):
			eop = OPER.OP16_8;
			goto Leop;
		case X(TY.Tint16,TY.Tuns16):
			goto Lpaint;
		case X(TY.Tint16,TY.Tint32):
		case X(TY.Tint16,TY.Tuns32):
			eop = OPER.OPs16_32;
			goto Leop;
		case X(TY.Tint16,TY.Tint64):
		case X(TY.Tint16,TY.Tuns64):
			e = el_una(OPER.OPs16_32, TYM.TYint, e);
			fty = TY.Tint32;
			goto Lagain;
		case X(TY.Tint16,TY.Tfloat32):
		case X(TY.Tint16,TY.Tfloat64):
		case X(TY.Tint16,TY.Tfloat80):
		case X(TY.Tint16,TY.Tcomplex32):
		case X(TY.Tint16,TY.Tcomplex64):
		case X(TY.Tint16,TY.Tcomplex80):
			e = el_una(OPER.OPs16_d, TYM.TYdouble, e);
			fty = TY.Tfloat64;
			goto Lagain;
		case X(TY.Tint16,TY.Timaginary32):
		case X(TY.Tint16,TY.Timaginary64):
		case X(TY.Tint16,TY.Timaginary80):
			goto Lzero;

		/* ============================= */

		case X(TY.Tuns16,TY.Tint8):
		case X(TY.Tuns16,TY.Tuns8):
			eop = OPER.OP16_8;
			goto Leop;
		case X(TY.Tuns16,TY.Tint16):
			goto Lpaint;
		case X(TY.Tuns16,TY.Tint32):
		case X(TY.Tuns16,TY.Tuns32):
			eop = OPER.OPu16_32;
			goto Leop;
		case X(TY.Tuns16,TY.Tint64):
		case X(TY.Tuns16,TY.Tuns64):
		case X(TY.Tuns16,TY.Tfloat64):
		case X(TY.Tuns16,TY.Tfloat32):
		case X(TY.Tuns16,TY.Tfloat80):
		case X(TY.Tuns16,TY.Tcomplex32):
		case X(TY.Tuns16,TY.Tcomplex64):
		case X(TY.Tuns16,TY.Tcomplex80):
			e = el_una(OPER.OPu16_32, TYM.TYuint, e);
			fty = TY.Tuns32;
			goto Lagain;
		case X(TY.Tuns16,TY.Timaginary32):
		case X(TY.Tuns16,TY.Timaginary64):
		case X(TY.Tuns16,TY.Timaginary80):
			goto Lzero;

		/* ============================= */

		case X(TY.Tint32,TY.Tint8):
		case X(TY.Tint32,TY.Tuns8):	
			e = el_una(OPER.OP32_16, TYM.TYshort, e);
			fty = TY.Tint16;
			goto Lagain;
		case X(TY.Tint32,TY.Tint16):
		case X(TY.Tint32,TY.Tuns16):
			eop = OPER.OP32_16;
			goto Leop;
		case X(TY.Tint32,TY.Tuns32):
			goto Lpaint;
		case X(TY.Tint32,TY.Tint64):
		case X(TY.Tint32,TY.Tuns64):
			eop = OPER.OPs32_64;
			goto Leop;
		case X(TY.Tint32,TY.Tfloat32):
		case X(TY.Tint32,TY.Tfloat64):
		case X(TY.Tint32,TY.Tfloat80):
		case X(TY.Tint32,TY.Tcomplex32):
		case X(TY.Tint32,TY.Tcomplex64):
		case X(TY.Tint32,TY.Tcomplex80):
			e = el_una(OPER.OPs32_d, TYM.TYdouble, e);
			fty = TY.Tfloat64;
			goto Lagain;
		case X(TY.Tint32,TY.Timaginary32):
		case X(TY.Tint32,TY.Timaginary64):
		case X(TY.Tint32,TY.Timaginary80):
			goto Lzero;

		/* ============================= */

		case X(TY.Tuns32,TY.Tint8):
		case X(TY.Tuns32,TY.Tuns8):
			e = el_una(OPER.OP32_16, TYM.TYshort, e);
			fty = TY.Tuns16;
			goto Lagain;
		case X(TY.Tuns32,TY.Tint16):
		case X(TY.Tuns32,TY.Tuns16):
			eop = OPER.OP32_16;
			goto Leop;
		case X(TY.Tuns32,TY.Tint32):
			goto Lpaint;
		case X(TY.Tuns32,TY.Tint64):
		case X(TY.Tuns32,TY.Tuns64):
			eop = OPER.OPu32_64;
			goto Leop;
		case X(TY.Tuns32,TY.Tfloat32):
		case X(TY.Tuns32,TY.Tfloat64):
		case X(TY.Tuns32,TY.Tfloat80):
		case X(TY.Tuns32,TY.Tcomplex32):
		case X(TY.Tuns32,TY.Tcomplex64):
		case X(TY.Tuns32,TY.Tcomplex80):
			e = el_una(OPER.OPu32_d, TYM.TYdouble, e);
			fty = TY.Tfloat64;
			goto Lagain;
		case X(TY.Tuns32,TY.Timaginary32):
		case X(TY.Tuns32,TY.Timaginary64):
		case X(TY.Tuns32,TY.Timaginary80):
			goto Lzero;

		/* ============================= */

		case X(TY.Tint64,TY.Tint8):
		case X(TY.Tint64,TY.Tuns8):
		case X(TY.Tint64,TY.Tint16):
		case X(TY.Tint64,TY.Tuns16):
			e = el_una(OPER.OP64_32, TYM.TYint, e);
			fty = TY.Tint32;
			goto Lagain;
		case X(TY.Tint64,TY.Tint32):
		case X(TY.Tint64,TY.Tuns32):
			eop = OPER.OP64_32;
			goto Leop;
		case X(TY.Tint64,TY.Tuns64):
			goto Lpaint;
		case X(TY.Tint64,TY.Tfloat32):
		case X(TY.Tint64,TY.Tfloat64):
		case X(TY.Tint64,TY.Tfloat80):
		case X(TY.Tint64,TY.Tcomplex32):
		case X(TY.Tint64,TY.Tcomplex64):
		case X(TY.Tint64,TY.Tcomplex80):
			e = el_una(OPER.OPs64_d, TYM.TYdouble, e);
			fty = TY.Tfloat64;
			goto Lagain;
		case X(TY.Tint64,TY.Timaginary32):
		case X(TY.Tint64,TY.Timaginary64):
		case X(TY.Tint64,TY.Timaginary80):
			goto Lzero;

		/* ============================= */

		case X(TY.Tuns64,TY.Tint8):
		case X(TY.Tuns64,TY.Tuns8):
		case X(TY.Tuns64,TY.Tint16):
		case X(TY.Tuns64,TY.Tuns16):
			e = el_una(OPER.OP64_32, TYM.TYint, e);
			fty = TY.Tint32;
			goto Lagain;
		case X(TY.Tuns64,TY.Tint32):
		case X(TY.Tuns64,TY.Tuns32):
			eop = OPER.OP64_32;
			goto Leop;
		case X(TY.Tuns64,TY.Tint64):
			goto Lpaint;
		case X(TY.Tuns64,TY.Tfloat32):
		case X(TY.Tuns64,TY.Tfloat64):
		case X(TY.Tuns64,TY.Tfloat80):
		case X(TY.Tuns64,TY.Tcomplex32):
		case X(TY.Tuns64,TY.Tcomplex64):
		case X(TY.Tuns64,TY.Tcomplex80):
			 e = el_una(OPER.OPu64_d, TYM.TYdouble, e);
			 fty = TY.Tfloat64;
			 goto Lagain;
		case X(TY.Tuns64,TY.Timaginary32):
		case X(TY.Tuns64,TY.Timaginary64):
		case X(TY.Tuns64,TY.Timaginary80):
			goto Lzero;

		/* ============================= */

		case X(TY.Tfloat32,TY.Tint8):
		case X(TY.Tfloat32,TY.Tuns8):
		case X(TY.Tfloat32,TY.Tint16):
		case X(TY.Tfloat32,TY.Tuns16):
		case X(TY.Tfloat32,TY.Tint32):
		case X(TY.Tfloat32,TY.Tuns32):
		case X(TY.Tfloat32,TY.Tint64):
		case X(TY.Tfloat32,TY.Tuns64):
		case X(TY.Tfloat32,TY.Tfloat80):
			e = el_una(OPER.OPf_d, TYM.TYdouble, e);
			fty = TY.Tfloat64;
			goto Lagain;
		case X(TY.Tfloat32,TY.Tfloat64):
			eop = OPER.OPf_d;
			goto Leop;
		case X(TY.Tfloat32,TY.Timaginary32):
			goto Lzero;
		case X(TY.Tfloat32,TY.Timaginary64):
			goto Lzero;
		case X(TY.Tfloat32,TY.Timaginary80):
			goto Lzero;
		case X(TY.Tfloat32,TY.Tcomplex32):
		case X(TY.Tfloat32,TY.Tcomplex64):
		case X(TY.Tfloat32,TY.Tcomplex80):
			e = el_bin(OPER.OPadd,TYM.TYcfloat,el_long(TYM.TYifloat,0),e);
			fty = TY.Tcomplex32;
			goto Lagain;

		/* ============================= */

		case X(TY.Tfloat64,TY.Tint8):
		case X(TY.Tfloat64,TY.Tuns8):
			e = el_una(OPER.OPd_s16, TYM.TYshort, e);
			fty = TY.Tint16;
			goto Lagain;
		case X(TY.Tfloat64,TY.Tint16):  
			eop = OPER.OPd_s16;
			goto Leop;
		case X(TY.Tfloat64,TY.Tuns16):  
			eop = OPER.OPd_u16;
			goto Leop;
		case X(TY.Tfloat64,TY.Tint32):   
			eop = OPER.OPd_s32; 
			goto Leop;
		case X(TY.Tfloat64,TY.Tuns32):   
			eop = OPER.OPd_u32; 
			goto Leop;
		case X(TY.Tfloat64,TY.Tint64):   
			eop = OPER.OPd_s64; 
			goto Leop;
		case X(TY.Tfloat64,TY.Tuns64):   
			eop = OPER.OPd_u64; 
			goto Leop;
		case X(TY.Tfloat64,TY.Tfloat32): 
			eop = OPER.OPd_f;   
			goto Leop;
		case X(TY.Tfloat64,TY.Tfloat80): 
			eop = OPER.OPd_ld;  
			goto Leop;
		case X(TY.Tfloat64,TY.Timaginary32):	
			goto Lzero;
		case X(TY.Tfloat64,TY.Timaginary64):	
			goto Lzero;
		case X(TY.Tfloat64,TY.Timaginary80):	
			goto Lzero;
		case X(TY.Tfloat64,TY.Tcomplex32):
		case X(TY.Tfloat64,TY.Tcomplex64):
		case X(TY.Tfloat64,TY.Tcomplex80):
			e = el_bin(OPER.OPadd,TYM.TYcfloat,el_long(TYM.TYidouble,0),e);
			fty = TY.Tcomplex64;
			goto Lagain;

		/* ============================= */

		case X(TY.Tfloat80,TY.Tint8):
		case X(TY.Tfloat80,TY.Tuns8):
		case X(TY.Tfloat80,TY.Tint16):
		case X(TY.Tfloat80,TY.Tuns16):
		case X(TY.Tfloat80,TY.Tint32):
		case X(TY.Tfloat80,TY.Tuns32):
		case X(TY.Tfloat80,TY.Tint64):
		case X(TY.Tfloat80,TY.Tfloat32):
			e = el_una(OPER.OPld_d, TYM.TYdouble, e);
			fty = TY.Tfloat64;
			goto Lagain;
		case X(TY.Tfloat80,TY.Tuns64):
			eop = OPER.OPld_u64;
			goto Leop;
		case X(TY.Tfloat80,TY.Tfloat64):
			eop = OPER.OPld_d;
			goto Leop;
		case X(TY.Tfloat80,TY.Timaginary32):
			goto Lzero;
		case X(TY.Tfloat80,TY.Timaginary64):
			goto Lzero;
		case X(TY.Tfloat80,TY.Timaginary80):
			goto Lzero;
		case X(TY.Tfloat80,TY.Tcomplex32):
		case X(TY.Tfloat80,TY.Tcomplex64):
		case X(TY.Tfloat80,TY.Tcomplex80):
			e = el_bin(OPER.OPadd,TYM.TYcldouble,e,el_long(TYM.TYildouble,0));
			fty = TY.Tcomplex80;
			goto Lagain;

		/* ============================= */

		case X(TY.Timaginary32,TY.Tint8):
		case X(TY.Timaginary32,TY.Tuns8):
		case X(TY.Timaginary32,TY.Tint16):
		case X(TY.Timaginary32,TY.Tuns16):
		case X(TY.Timaginary32,TY.Tint32):
		case X(TY.Timaginary32,TY.Tuns32):
		case X(TY.Timaginary32,TY.Tint64):
		case X(TY.Timaginary32,TY.Tuns64):
		case X(TY.Timaginary32,TY.Tfloat32):
		case X(TY.Timaginary32,TY.Tfloat64):
		case X(TY.Timaginary32,TY.Tfloat80):
			goto Lzero;
		case X(TY.Timaginary32,TY.Timaginary64):
			eop = OPER.OPf_d;
			goto Leop;
		case X(TY.Timaginary32,TY.Timaginary80):
			e = el_una(OPER.OPf_d, TYM.TYidouble, e);
			fty = TY.Timaginary64;
			goto Lagain;
		case X(TY.Timaginary32,TY.Tcomplex32):
		case X(TY.Timaginary32,TY.Tcomplex64):
		case X(TY.Timaginary32,TY.Tcomplex80):
			e = el_bin(OPER.OPadd,TYM.TYcfloat,el_long(TYM.TYfloat,0),e);
			fty = TY.Tcomplex32;
			goto Lagain;

		/* ============================= */

		case X(TY.Timaginary64,TY.Tint8):
		case X(TY.Timaginary64,TY.Tuns8):
		case X(TY.Timaginary64,TY.Tint16):
		case X(TY.Timaginary64,TY.Tuns16):
		case X(TY.Timaginary64,TY.Tint32):
		case X(TY.Timaginary64,TY.Tuns32):
		case X(TY.Timaginary64,TY.Tint64):
		case X(TY.Timaginary64,TY.Tuns64):
		case X(TY.Timaginary64,TY.Tfloat32):
		case X(TY.Timaginary64,TY.Tfloat64):
		case X(TY.Timaginary64,TY.Tfloat80):
			goto Lzero;
		case X(TY.Timaginary64,TY.Timaginary32):
			eop = OPER.OPd_f;  
			goto Leop;
		case X(TY.Timaginary64,TY.Timaginary80):
			eop = OPER.OPd_ld; 
			goto Leop;
		case X(TY.Timaginary64,TY.Tcomplex32):
		case X(TY.Timaginary64,TY.Tcomplex64):
		case X(TY.Timaginary64,TY.Tcomplex80):
			e = el_bin(OPER.OPadd, TYM.TYcdouble, el_long(TYM.TYdouble,0), e);
			fty = TY.Tcomplex64;
			goto Lagain;

		/* ============================= */

		case X(TY.Timaginary80,TY.Tint8):
		case X(TY.Timaginary80,TY.Tuns8):
		case X(TY.Timaginary80,TY.Tint16):
		case X(TY.Timaginary80,TY.Tuns16):
		case X(TY.Timaginary80,TY.Tint32):
		case X(TY.Timaginary80,TY.Tuns32):
		case X(TY.Timaginary80,TY.Tint64):
		case X(TY.Timaginary80,TY.Tuns64):
		case X(TY.Timaginary80,TY.Tfloat32):
		case X(TY.Timaginary80,TY.Tfloat64):
		case X(TY.Timaginary80,TY.Tfloat80):
			goto Lzero;
		case X(TY.Timaginary80,TY.Timaginary32):
			e = el_una(OPER.OPf_d, TYM.TYidouble, e);
			fty = TY.Timaginary64;
			goto Lagain;
		case X(TY.Timaginary80,TY.Timaginary64):
			eop = OPER.OPld_d;
			goto Leop;
		case X(TY.Timaginary80,TY.Tcomplex32):
		case X(TY.Timaginary80,TY.Tcomplex64):
		case X(TY.Timaginary80,TY.Tcomplex80):
			e = el_bin(OPER.OPadd, TYM.TYcldouble, el_long(TYM.TYldouble,0), e);
			fty = TY.Tcomplex80;
			goto Lagain;

		/* ============================= */

		case X(TY.Tcomplex32,TY.Tint8):
		case X(TY.Tcomplex32,TY.Tuns8):
		case X(TY.Tcomplex32,TY.Tint16):
		case X(TY.Tcomplex32,TY.Tuns16):
		case X(TY.Tcomplex32,TY.Tint32):
		case X(TY.Tcomplex32,TY.Tuns32):
		case X(TY.Tcomplex32,TY.Tint64):
		case X(TY.Tcomplex32,TY.Tuns64):
		case X(TY.Tcomplex32,TY.Tfloat32):
		case X(TY.Tcomplex32,TY.Tfloat64):
		case X(TY.Tcomplex32,TY.Tfloat80):
			e = el_una(OPER.OPc_r, TYM.TYfloat, e);
			fty = TY.Tfloat32;
			goto Lagain;
		case X(TY.Tcomplex32,TY.Timaginary32):
		case X(TY.Tcomplex32,TY.Timaginary64):
		case X(TY.Tcomplex32,TY.Timaginary80):
			e = el_una(OPER.OPc_i, TYM.TYifloat, e);
			fty = TY.Timaginary32;
			goto Lagain;
		case X(TY.Tcomplex32,TY.Tcomplex64):
		case X(TY.Tcomplex32,TY.Tcomplex80):
			e = el_una(OPER.OPf_d, TYM.TYcdouble, e);
			fty = TY.Tcomplex64;
			goto Lagain;

		/* ============================= */

		case X(TY.Tcomplex64,TY.Tint8):
		case X(TY.Tcomplex64,TY.Tuns8):
		case X(TY.Tcomplex64,TY.Tint16):
		case X(TY.Tcomplex64,TY.Tuns16):
		case X(TY.Tcomplex64,TY.Tint32):
		case X(TY.Tcomplex64,TY.Tuns32):
		case X(TY.Tcomplex64,TY.Tint64):
		case X(TY.Tcomplex64,TY.Tuns64):
		case X(TY.Tcomplex64,TY.Tfloat32):
		case X(TY.Tcomplex64,TY.Tfloat64):
		case X(TY.Tcomplex64,TY.Tfloat80):
			e = el_una(OPER.OPc_r, TYM.TYdouble, e);
			fty = TY.Tfloat64;
			goto Lagain;
		case X(TY.Tcomplex64,TY.Timaginary32):
		case X(TY.Tcomplex64,TY.Timaginary64):
		case X(TY.Tcomplex64,TY.Timaginary80):
			e = el_una(OPER.OPc_i, TYM.TYidouble, e);
			fty = TY.Timaginary64;
			goto Lagain;
		case X(TY.Tcomplex64,TY.Tcomplex32):
			eop = OPER.OPd_f;
			goto Leop;
		case X(TY.Tcomplex64,TY.Tcomplex80):
			eop = OPER.OPd_ld;
			goto Leop;

		/* ============================= */

		case X(TY.Tcomplex80,TY.Tint8):
		case X(TY.Tcomplex80,TY.Tuns8):
		case X(TY.Tcomplex80,TY.Tint16):
		case X(TY.Tcomplex80,TY.Tuns16):
		case X(TY.Tcomplex80,TY.Tint32):
		case X(TY.Tcomplex80,TY.Tuns32):
		case X(TY.Tcomplex80,TY.Tint64):
		case X(TY.Tcomplex80,TY.Tuns64):
		case X(TY.Tcomplex80,TY.Tfloat32):
		case X(TY.Tcomplex80,TY.Tfloat64):
		case X(TY.Tcomplex80,TY.Tfloat80):
			e = el_una(OPER.OPc_r, TYM.TYldouble, e);
			fty = TY.Tfloat80;
			goto Lagain;
		case X(TY.Tcomplex80,TY.Timaginary32):
		case X(TY.Tcomplex80,TY.Timaginary64):
		case X(TY.Tcomplex80,TY.Timaginary80):
			e = el_una(OPER.OPc_i, TYM.TYildouble, e);
			fty = TY.Timaginary80;
			goto Lagain;
		case X(TY.Tcomplex80,TY.Tcomplex32):
		case X(TY.Tcomplex80,TY.Tcomplex64):
			e = el_una(OPER.OPld_d, TYM.TYcdouble, e);
			fty = TY.Tcomplex64;
			goto Lagain;

		/* ============================= */

		default:
			if (fty == tty)
				goto Lpaint;
			//dump(0);
			//writef("fty = %d, tty = %d, %d\n", fty, tty, t.ty);
			error("e2ir: cannot cast %s of type %s to type %s", e1.toChars(), e1.type.toChars(), t.toChars());
			goto Lzero;

		Lzero:
			e = el_long(ttym, 0);
			break;

		Lpaint:
			e.Ety = ttym;
			break;

		Leop:
			e = el_una(eop, ttym, e);
			break;
		}
	Lret:
		// Adjust for any type paints
		t = type.toBasetype();
		e.Ety = t.totym();

		el_setLoc(e,loc);
		return e;
	}

	override Identifier opId()
	{
		return Id.cast_;
	}
}

