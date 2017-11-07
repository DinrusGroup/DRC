module dmd.DivExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.backend.elem;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IntRange;
import dmd.IRState;
import dmd.ArrayTypes;
import dmd.BinExp;
import dmd.TOK;
import dmd.Type;
import dmd.NegExp;
import dmd.TY;
import dmd.Id;

import dmd.expression.Div;
import dmd.backend.OPER;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class DivExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKdiv, DivExp.sizeof, e1, e2);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

		if (type)
			return this;

		super.semanticp(sc);
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
				if (t2.isimaginary())
				{
					// x/iv = i(-x/v)
					e2.type = t1;
					Expression ee = new NegExp(loc, this);
					ee = ee.semantic(sc);
					return e;
				}
			}
			else if (t2.isreal())
			{
				type = t1;
			}
			else if (t1.isimaginary())
			{
				if (t2.isimaginary()) {
					switch (t1.ty)
					{
						case TY.Timaginary32:	type = Type.tfloat32;	break;
						case TY.Timaginary64:	type = Type.tfloat64;	break;
						case TY.Timaginary80:	type = Type.tfloat80;	break;
						default:		assert(0);
					}
				} else {
					type = t2;	// t2 is complex
				}
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

		//printf("DivExp.optimize(%s)\n", toChars());
		e1 = e1.optimize(result);
		e2 = e2.optimize(result);
		if (e1.isConst() == 1 && e2.isConst() == 1)
		{
			e = Div(type, e1, e2);
		}
		else
			e = this;
		return e;
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon(istate, &Div);
	}

	override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		Exp_buildArrayIdent(buf, arguments, "Div");
	}

	override Expression buildArrayLoop(Parameters fparams)
	{
		return Exp_buildArrayLoop!(typeof(this))(fparams);
	}

	override IntRange getIntRange()
	{
		assert(false);
	}

	override Identifier opId()
	{
		return Id.div;
	}

	override Identifier opId_r()
	{
		return Id.div_r;
	}

	override elem* toElem(IRState* irs)
	{
		return toElemBin(irs,OPdiv);
	}
}

