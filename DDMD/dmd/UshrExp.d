module dmd.UshrExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Loc;
import dmd.Scope;
import dmd.Id;
import dmd.IntRange;
import dmd.IRState;
import dmd.BinExp;
import dmd.TOK;
import dmd.Type;

import dmd.backend.elem;
import dmd.backend.OPER;
import dmd.backend.TYFL;
import dmd.backend.Util;
import dmd.expression.Util;
import dmd.expression.Ushr;
import dmd.expression.shift_optimize;

import dmd.DDMDExtensions;

class UshrExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKushr, UshrExp.sizeof, e1, e2);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

		if (!type)
		{	
			BinExp.semanticp(sc);
			e = op_overload(sc);
			if (e)
				return e;
			e1 = e1.checkIntegral();
			e2 = e2.checkIntegral();
			e1 = e1.integralPromotions(sc);
			e2 = e2.castTo(sc, Type.tshiftcnt);
			type = e1.type;
		}
		return this;
	}

	override Expression optimize(int result)
	{
		//printf("UshrExp.optimize(result = %d) %s\n", result, toChars());
		return shift_optimize(result, this, &Ushr);
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon(istate, &Ushr);
	}

	override IntRange getIntRange()
	{
		assert(false);
	}

	override Identifier opId()
	{
		return Id.ushr;
	}

	override Identifier opId_r()
	{
		return Id.ushr_r;
	}

	override elem* toElem(IRState* irs)
	{
		//return toElemBin(irs, OPER.OPshr);
        elem *eleft = e1.toElem(irs);
        eleft.Ety = touns(eleft.Ety);
        elem *eright = e2.toElem(irs);
        elem *e = el_bin(OPER.OPshr, type.totym(), eleft, eright);
        el_setLoc(e, loc);
        return e;
	}
}