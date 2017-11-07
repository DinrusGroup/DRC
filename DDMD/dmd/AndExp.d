module dmd.AndExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IntRange;
import dmd.IRState;
import dmd.BinExp;
import dmd.TOK;
import dmd.ArrayTypes;
import dmd.TY;
import dmd.Type;
import dmd.Id;
import dmd.Global;

import dmd.backend.elem;
import dmd.backend.Util;
import dmd.backend.OPER;
import dmd.expression.Util;
import dmd.expression.And;

import dmd.DDMDExtensions;

class AndExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKand, AndExp.sizeof, e1, e2);
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

			if (e1.type.toBasetype().ty == TY.Tbool && e2.type.toBasetype().ty == TY.Tbool)
			{
				type = e1.type;
				e = this;
			}
			else
			{
				typeCombine(sc);
				if (!e1.isArrayOperand())
					e1.checkIntegral();
				if (!e2.isArrayOperand())
					e2.checkIntegral();
			}
		}
		return this;
	}

	override Expression optimize(int result)
	{
		Expression e;

		e1 = e1.optimize(result);
		e2 = e2.optimize(result);
		if (e1.isConst() == 1 && e2.isConst() == 1)
			e = And(type, e1, e2);
		else
			e = this;

		return e;
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon(istate, &And);
	}

	override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		Exp_buildArrayIdent(buf, arguments, "And");
	}

	override Expression buildArrayLoop(Parameters fparams)
	{
		return Exp_buildArrayLoop!(typeof(this))(fparams);
	}

	override IntRange getIntRange()
	{
		IntRange ir;
		IntRange ir1 = e1.getIntRange();
		IntRange ir2 = e2.getIntRange();

		ir.imin = ir1.imin;
		if (ir2.imin < ir.imin)
		ir.imin = ir2.imin;

		ir.imax = ir1.imax;
		if (ir2.imax > ir.imax)
		ir.imax = ir2.imax;

		ulong u;

		u = getMask(ir1.imax);
		ir.imin &= u;
		ir.imax &= u;

		u = getMask(ir2.imax);
		ir.imin &= u;
		ir.imax &= u;

		ir.imin &= type.sizemask();
		ir.imax &= type.sizemask();

	//printf("AndExp: imin = x%llx, imax = x%llx\n", ir.imin, ir.imax);
	//e1.dump(0);

		return ir;
	}

	override bool isCommutative()
	{
		return true;
	}

	override Identifier opId()
	{
		return Id.iand;
	}

	override Identifier opId_r()
	{
		return Id.iand_r;
	}

	override elem* toElem(IRState* irs)
	{
		return toElemBin(irs, OPER.OPand);
	}
}

