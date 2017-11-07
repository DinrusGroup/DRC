module dmd.PtrExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.backend.elem;
import dmd.UnaExp;
import dmd.InterState;
import dmd.Type;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.GlobalExpressions;
import dmd.SymOffExp;
import dmd.AddrExp;
import dmd.PREC;
import dmd.VarDeclaration;
import dmd.StructLiteralExp;
import dmd.TypePointer;
import dmd.TypeArray;
import dmd.ErrorExp;
import dmd.TY;
import dmd.expression.Ptr;
import dmd.expression.Util;

import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.mTY;
import dmd.backend.OPER;

import dmd.DDMDExtensions;

class PtrExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		register();
		super(loc, TOK.TOKstar, PtrExp.sizeof, e);
		//    if (e.type)
		//		type = ((TypePointer *)e.type).next;
	}

	this(Loc loc, Expression e, Type t)
	{
		register();
		super(loc, TOKstar, PtrExp.sizeof, e);
		type = t;
	}

	override Expression semantic(Scope sc)
	{
	version (LOGSEMANTIC) {
		printf("PtrExp::semantic('%s')\n", toChars());
	}
		if (!type)
		{
			UnaExp.semantic(sc);
			e1 = resolveProperties(sc, e1);
			if (!e1.type)
				writef("PtrExp.semantic('%s')\n", toChars());
			Expression e = op_overload(sc);
			if (e)
				return e;
			Type tb = e1.type.toBasetype();
			switch (tb.ty)
			{
				case Tpointer:
					type = (cast(TypePointer)tb).next;
					break;

				case Tsarray:
				case Tarray:
					type = (cast(TypeArray)tb).next;
					e1 = e1.castTo(sc, type.pointerTo());
					break;

				default:
					error("can only * a pointer, not a '%s'", e1.type.toChars());
					return new ErrorExp();
			}
			rvalue();
		}
		return this;
	}

	override bool isLvalue()
	{
		return true;
	}

    override void checkEscapeRef()
    {
        e1.checkEscape();
    }

	override Expression toLvalue(Scope sc, Expression e)
	{
static if (false) {
		tym = tybasic(e1.ET.Tty);
		if (!(tyscalar(tym) ||
		  tym == TYstruct ||
		  tym == TYarray && e.Eoper == TOKaddr)
		)
			synerr(EM_lvalue);	// lvalue expected
}
		return this;
	}

version (DMDV2) {
	override Expression modifiableLvalue(Scope sc, Expression e)
	{
		//printf("PtrExp.modifiableLvalue() %s, type %s\n", toChars(), type.toChars());

		if (e1.op == TOKsymoff)
		{
			SymOffExp se = cast(SymOffExp)e1;
			se.var.checkModify(loc, sc, type);
			//return toLvalue(sc, e);
		}

		return Expression.modifiableLvalue(sc, e);
	}
}
	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writeByte('*');
		expToCBuffer(buf, hgs, e1, precedence[op]);
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;

		//printf("PtrExp::toElem() %s\n", toChars());
		e = e1.toElem(irs);
		e = el_una(OPER.OPind, type.totym(), e);

		if (tybasic(e.Ety) == TYM.TYstruct)
		{
			e.Enumbytes = cast(uint)type.size();
		}

		el_setLoc(e,loc);
		return e;
	}

	override Expression optimize(int result)
	{
		//printf("PtrExp.optimize(result = x%x) %s\n", result, toChars());
		e1 = e1.optimize(result);
		// Convert *&ex to ex
		if (e1.op == TOK.TOKaddress)
		{
			Expression e;
			Expression ex;

			ex = (cast(AddrExp)e1).e1;
			if (type.equals(ex.type))
				e = ex;
			else
			{
				e = ex.copy();
				e.type = type;
			}
			return e;
		}
		// Constant fold *(&structliteral + offset)
		if (e1.op == TOK.TOKadd)
		{
			Expression e;
			e = Ptr(type, e1);
			if (e !is EXP_CANT_INTERPRET)
				return e;
		}

		if (e1.op == TOK.TOKsymoff)
		{
			SymOffExp se = cast(SymOffExp)e1;
			VarDeclaration v = se.var.isVarDeclaration();
			Expression e = expandVar(result, v);
			if (e && e.op == TOK.TOKstructliteral)
			{
				StructLiteralExp sle = cast(StructLiteralExp)e;
				e = sle.getField(type, se.offset);
				if (e && e !is EXP_CANT_INTERPRET)
					return e;
			}
		}
		return this;
	}

	override Expression interpret(InterState istate)
	{
		assert(false);
	}

	override Identifier opId()
	{
		assert(false);
	}
}

