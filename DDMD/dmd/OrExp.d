module dmd.OrExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.MATCH;
import dmd.Type;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IntRange;
import dmd.IRState;
import dmd.ArrayTypes;
import dmd.BinExp;
import dmd.TOK;
import dmd.TY;
import dmd.Id;

import dmd.backend.elem;
import dmd.backend.OPER;

import dmd.expression.Or;

import dmd.DDMDExtensions;

class OrExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKor, OrExp.sizeof, e1, e2);
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
			e = Or(type, e1, e2);
		else
			e = this;

		return e;
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon(istate, &Or);
	}

	override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		Exp_buildArrayIdent(buf, arguments, "Or");
	}

	override Expression buildArrayLoop(Parameters fparams)
	{
		return Exp_buildArrayLoop!(typeof(this))(fparams);
	}

	override MATCH implicitConvTo(Type t)
	{
		MATCH result = Expression.implicitConvTo(t);

		if (result == MATCH.MATCHnomatch)
		{
			MATCH m1 = e1.implicitConvTo(t);
			MATCH m2 = e2.implicitConvTo(t);

			// Pick the worst match
			result = (m1 < m2) ? m1 : m2;
		}

		return result;
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

		ir.imin &= type.sizemask();
		ir.imax &= type.sizemask();

	//printf("OrExp: imin = x%llx, imax = x%llx\n", ir.imin, ir.imax);
	//e1.dump(0);

		return ir;
	}

	override bool isCommutative()
	{
		return true;
	}

	override Identifier opId()
	{
		return Id.ior;
	}

	override Identifier opId_r()
	{
		return Id.ior_r;
	}

	override elem* toElem(IRState* irs)
	{
		return toElemBin(irs, OPER.OPor);
	}
}

