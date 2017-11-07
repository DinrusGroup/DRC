module dmd.CondExp;

import dmd.common;
import dmd.BinExp;
import dmd.Loc;
import dmd.PtrExp;
import dmd.MATCH;
import dmd.Expression;
import dmd.GlobalExpressions;
import dmd.Scope;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Type;
import dmd.InlineCostState;
import dmd.InlineDoState;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.TOK;
import dmd.TY;
import dmd.WANT;
import dmd.PREC;
import dmd.Global;

import dmd.backend.elem;
import dmd.backend.Util;
import dmd.backend.OPER;
import dmd.backend.mTY;
import dmd.backend.TYM;
import dmd.codegen.Util;

import dmd.expression.Util;

import dmd.DDMDExtensions;

class CondExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    Expression econd;

    this(Loc loc, Expression econd, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKquestion, CondExp.sizeof, e1, e2);
		this.econd = econd;
	}
	
    override Expression syntaxCopy()
	{
		return new CondExp(loc, econd.syntaxCopy(), e1.syntaxCopy(), e2.syntaxCopy());
	}

    override Expression semantic(Scope sc)
	{
		Type t1;
		Type t2;
		uint cs0;
		uint cs1;

	version (LOGSEMANTIC) {
		printf("CondExp.semantic('%s')\n", toChars());
	}
		if (type)
			return this;

		econd = econd.semantic(sc);
		econd = resolveProperties(sc, econd);
		econd = econd.checkToPointer();
		econd = econd.checkToBoolean();

	static if (false) {
		/* this cannot work right because the types of e1 and e2
		 * both contribute to the type of the result.
		 */
		if (sc.flags & SCOPEstaticif)
		{
			/* If in static if, don't evaluate what we don't have to.
			 */
			econd = econd.optimize(WANTflags);
			if (econd.isBool(TRUE))
			{
				e1 = e1.semantic(sc);
				e1 = resolveProperties(sc, e1);
				return e1;
			}
			else if (econd.isBool(FALSE))
			{
				e2 = e2.semantic(sc);
				e2 = resolveProperties(sc, e2);
				return e2;
			}
		}
	}

		cs0 = sc.callSuper;
		e1 = e1.semantic(sc);
		e1 = resolveProperties(sc, e1);
		cs1 = sc.callSuper;
		sc.callSuper = cs0;
		e2 = e2.semantic(sc);
		e2 = resolveProperties(sc, e2);
		sc.mergeCallSuper(loc, cs1);

		// If either operand is void, the result is void
		t1 = e1.type;
		t2 = e2.type;
		if (t1.ty == Tvoid || t2.ty == Tvoid)
			type = Type.tvoid;
		else if (t1 == t2)
			type = t1;
		else
		{
			typeCombine(sc);
			switch (e1.type.toBasetype().ty)
			{
				case Tcomplex32:
				case Tcomplex64:
				case Tcomplex80:
					e2 = e2.castTo(sc, e1.type);
					break;
				default:
					break;
			}
			switch (e2.type.toBasetype().ty)
			{
				case Tcomplex32:
				case Tcomplex64:
				case Tcomplex80:
					e1 = e1.castTo(sc, e2.type);
					break;
				default:
					break;
			}
			if (type.toBasetype().ty == Tarray)
			{
				e1 = e1.castTo(sc, type);
				e2 = e2.castTo(sc, type);
			}
		}
	static if (false) {
		printf("res: %s\n", type.toChars());
		printf("e1 : %s\n", e1.type.toChars());
		printf("e2 : %s\n", e2.type.toChars());
	}
		return this;
	}

    override Expression optimize(int result)
	{
		Expression e;

		econd = econd.optimize(WANTflags | (result & WANTinterpret));
		if (econd.isBool(true))
			e = e1.optimize(result);
		else if (econd.isBool(false))
			e = e2.optimize(result);
		else
		{	
			e1 = e1.optimize(result);
			e2 = e2.optimize(result);
			e = this;
		}

		return e;
	}
	
    override Expression interpret(InterState istate)
	{
version (LOG) {
		printf("CondExp.interpret() %.*s\n", toChars());
}
		Expression e = econd.interpret(istate);
		if (e !is EXP_CANT_INTERPRET)
		{
			if (e.isBool(true))
				e = e1.interpret(istate);
			else if (e.isBool(false))
				e = e2.interpret(istate);
			else
				e = EXP_CANT_INTERPRET;
		}
		return e;
	}

    override void checkEscape()
	{
		e1.checkEscape();
		e2.checkEscape();
	}

    override void checkEscapeRef()
    {
        e1.checkEscapeRef();
        e2.checkEscapeRef();
    }
    
    override bool isLvalue()
	{
		return e1.isLvalue() && e2.isLvalue();
	}

    override Expression toLvalue(Scope sc, Expression ex)
	{
		PtrExp e;

		// convert (econd ? e1 : e2) to *(econd ? &e1 : &e2)
		e = new PtrExp(loc, this, type);

		e1 = e1.addressOf(sc);
		//e1 = e1.toLvalue(sc, null);

		e2 = e2.addressOf(sc);
		//e2 = e2.toLvalue(sc, null);

		typeCombine(sc);

		type = e2.type;
		return e;
	}

    override Expression modifiableLvalue(Scope sc, Expression e)
	{
        //error("conditional expression %s is not a modifiable lvalue", toChars());
        e1 = e1.modifiableLvalue(sc, e1);
        e2 = e2.modifiableLvalue(sc, e1);
        return toLvalue(sc, this);
	}

    override Expression checkToBoolean()
	{
		e1 = e1.checkToBoolean();
		e2 = e2.checkToBoolean();
		return this;
	}

    override bool checkSideEffect(int flag)
	{
		if (flag == 2)
		{
			return econd.checkSideEffect(2) || e1.checkSideEffect(2) || e2.checkSideEffect(2);
		}
		else
		{
			econd.checkSideEffect(1);
			e1.checkSideEffect(flag);
			return e2.checkSideEffect(flag);
		}
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		expToCBuffer(buf, hgs, econd, PREC_oror);
		buf.writestring(" ? ");
		expToCBuffer(buf, hgs, e1, PREC_expr);
		buf.writestring(" : ");
		expToCBuffer(buf, hgs, e2, PREC_cond);
	}

    override MATCH implicitConvTo(Type t)
	{
		MATCH m1 = e1.implicitConvTo(t);
		MATCH m2 = e2.implicitConvTo(t);
		//printf("CondExp: m1 %d m2 %d\n", m1, m2);

		// Pick the worst match
		return (m1 < m2) ? m1 : m2;
	}

    override Expression castTo(Scope sc, Type t)
	{
		Expression e = this;

		if (type !is t)
		{
			if (1 || e1.op == TOKstring || e2.op == TOKstring)
			{   
				e = new CondExp(loc, econd, e1.castTo(sc, t), e2.castTo(sc, t));
				e.type = t;
			}
			else
				e = Expression.castTo(sc, t);
		}
		return e;
	}

    override void scanForNestedRef(Scope sc)
	{
		assert(false);
	}

    override bool canThrow()
	{
		return econd.canThrow() || e1.canThrow() || e2.canThrow();
	}

    override int inlineCost(InlineCostState* ics)
	{
		return 1 + e1.inlineCost(ics) + e2.inlineCost(ics) + econd.inlineCost(ics);
	}
	
    override Expression doInline(InlineDoState ids)
	{
		CondExp ce = cast(CondExp)copy();

		ce.econd = econd.doInline(ids);
		ce.e1 = e1.doInline(ids);
		ce.e2 = e2.doInline(ids);
		return ce;
	}
	
    override Expression inlineScan(InlineScanState* iss)
	{
		econd = econd.inlineScan(iss);
		e1 = e1.inlineScan(iss);
		e2 = e2.inlineScan(iss);
		return this;
	}

    override elem* toElem(IRState* irs)
	{
		elem* eleft;
		elem* eright;

		elem* ec = econd.toElem(irs);

		eleft = e1.toElem(irs);
		tym_t ty = eleft.Ety;
		if (global.params.cov && e1.loc.linnum)
			eleft = el_combine(incUsageElem(irs, e1.loc), eleft);

		eright = e2.toElem(irs);
		if (global.params.cov && e2.loc.linnum)
			eright = el_combine(incUsageElem(irs, e2.loc), eright);

		elem* e = el_bin(OPcond, ty, ec, el_bin(OPcolon, ty, eleft, eright));
		if (tybasic(ty) == TYstruct)
			e.Enumbytes = cast(uint)e1.type.size();

		el_setLoc(e, loc);
		return e;
	}
}
