module dmd.XorExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.MATCH;
import dmd.Id;
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

import dmd.backend.elem;
import dmd.backend.OPER;
import dmd.expression.Util;
import dmd.expression.Xor;

import dmd.DDMDExtensions;

class XorExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKxor, XorExp.sizeof, e1, e2);
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
			if (e1.type.toBasetype().ty == Tbool &&
				e2.type.toBasetype().ty == Tbool)
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
			e = Xor(type, e1, e2);
		else
			e = this;

		return e;
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon(istate, &Xor);
	}

	override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		Exp_buildArrayIdent(buf, arguments, "Xor");
	}

	override Expression buildArrayLoop(Parameters fparams)
	{
		return Exp_buildArrayLoop!(typeof(this))(fparams);
	}

	override MATCH implicitConvTo(Type t)
	{
		MATCH result = Expression.implicitConvTo(t);

		if (result == MATCHnomatch)
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
		assert(false);
	}

	override bool isCommutative()
	{
		return true;
	}

	override Identifier opId()
	{
		return Id.ixor;
	}

	override Identifier opId_r()
	{
		return Id.ixor_r;
	}

	override elem* toElem(IRState* irs)
	{
		return toElemBin(irs,OPxor);
	}
}

