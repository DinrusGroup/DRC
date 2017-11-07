module dmd.ShrExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Loc;
import dmd.Scope;
import dmd.IntRange;
import dmd.IRState;
import dmd.BinExp;
import dmd.TOK;
import dmd.Type;
import dmd.Id;

import dmd.backend.elem;
import dmd.backend.OPER;

import dmd.expression.shift_optimize;
import dmd.expression.Shr;

import dmd.DDMDExtensions;

class ShrExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKshr, ShrExp.sizeof, e1, e2);
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
		//printf("ShrExp::optimize(result = %d) %s\n", result, toChars());
		return shift_optimize(result, this, &Shr);
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon(istate, &Shr);
	}

	override IntRange getIntRange()
	{
		assert(false);
	}

	override Identifier opId()
	{
		return Id.shr;
	}

	override Identifier opId_r()
	{
		return Id.shr_r;
	}

	override elem* toElem(IRState* irs)
	{
		return toElemBin(irs, e1.type.isunsigned() ? OPER.OPshr : OPER.OPashr);
	}
}

