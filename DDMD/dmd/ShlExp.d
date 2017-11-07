module dmd.ShlExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.backend.elem;
import dmd.InterState;
import dmd.Loc;
import dmd.Scope;
import dmd.IntRange;
import dmd.IRState;
import dmd.BinExp;
import dmd.TOK;
import dmd.Id;
import dmd.Type;

import dmd.expression.shift_optimize;
import dmd.expression.Shl;
import dmd.expression.Util;

import dmd.backend.OPER;

import dmd.DDMDExtensions;

class ShlExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKshl, ShlExp.sizeof, e1, e2);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

		//printf("ShlExp.semantic(), type = %p\n", type);
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
		//printf("ShlExp::optimize(result = %d) %s\n", result, toChars());
		return shift_optimize(result, this, &Shl);
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon(istate, &Shl);
	}

	override IntRange getIntRange()
	{
		IntRange ir;
		IntRange ir1 = e1.getIntRange();
		IntRange ir2 = e2.getIntRange();

		ir.imin = getMask(ir1.imin) << ir2.imin;
		ir.imax = getMask(ir1.imax) << ir2.imax;

		ir.imin &= type.sizemask();
		ir.imax &= type.sizemask();

	//printf("ShlExp: imin = x%llx, imax = x%llx\n", ir.imin, ir.imax);
	//e1.dump(0);

		return ir;
	}

	override Identifier opId()
	{
		return Id.shl;
	}

	override Identifier opId_r()
	{
		return Id.shl_r;
	}

	override elem* toElem(IRState* irs)
	{
		return toElemBin(irs, OPER.OPshl);
	}
}

