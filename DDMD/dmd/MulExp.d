module dmd.MulExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.backend.elem;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.NegExp;
import dmd.Loc;
import dmd.Id;
import dmd.Scope;
import dmd.IRState;
import dmd.BinExp;
import dmd.ArrayTypes;
import dmd.TOK;
import dmd.Type;
import dmd.TY;

import dmd.expression.Util;
import dmd.expression.Mul;
import dmd.backend.OPER;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class MulExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKmul, MulExp.sizeof, e1, e2);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

	static if (false) {
		printf("MulExp.semantic() %s\n", toChars());
	}
		if (type)
		{
			return this;
		}

		BinExp.semanticp(sc);
		e = op_overload(sc);
		if (e)
			return e;

		typeCombine(sc);
		if (!e1.isArrayOperand())
			e1.checkArithmetic();
		if (!e2.isArrayOperand())
			e2.checkArithmetic();

		if (type.isfloating())
		{	
			Type t1 = e1.type;
			Type t2 = e2.type;

			if (t1.isreal())
			{
				type = t2;
			}
			else if (t2.isreal())
			{
				type = t1;
			}
			else if (t1.isimaginary())
			{
				if (t2.isimaginary())
				{
					switch (t1.ty)
					{
						case Timaginary32:	type = Type.tfloat32;	break;
						case Timaginary64:	type = Type.tfloat64;	break;
						case Timaginary80:	type = Type.tfloat80;	break;
						default:		assert(0);
					}

					// iy * iv = -yv
					e1.type = type;
					e2.type = type;
					Expression ee = new NegExp(loc, this);
					ee = ee.semantic(sc);
					return ee;
				}
				else
					type = t2;	// t2 is complex
			}
			else if (t2.isimaginary())
			{
				type = t1;	// t1 is complex
			}
		}
		return this;
	}

	override Expression optimize(int result)
	{
		Expression e;

		//printf("MulExp.optimize(result = %d) %s\n", result, toChars());
		e1 = e1.optimize(result);
		e2 = e2.optimize(result);
		if (e1.isConst() == 1 && e2.isConst() == 1)
		{
			e = Mul(type, e1, e2);
		}
		else
			e = this;
		return e;
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon(istate, &Mul);
	}

	override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		Exp_buildArrayIdent(buf, arguments, "Mul");
	}

	override Expression buildArrayLoop(Parameters fparams)
	{
		return Exp_buildArrayLoop!(typeof(this))(fparams);
	}

	override bool isCommutative()
	{
		return true;
	}

	override Identifier opId()
	{
		return Id.mul;
	}

	override Identifier opId_r()
	{
		return Id.mul_r;
	}

	override elem* toElem(IRState* irs)
	{
		return toElemBin(irs,OPmul);
	}
}

