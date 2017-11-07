module dmd.MinExp;

import dmd.common;
import dmd.Expression;
import dmd.TY;
import dmd.ErrorExp;
import dmd.Identifier;
import dmd.IntegerExp;
import dmd.DivExp;
import dmd.Type;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.ArrayTypes;
import dmd.BinExp;
import dmd.TOK;
import dmd.Id;
import dmd.expression.Min;

import dmd.backend.elem;
import dmd.backend.Util;
import dmd.backend.OPER;

import dmd.DDMDExtensions;

class MinExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKmin, MinExp.sizeof, e1, e2);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;
		Type t1;
		Type t2;

version (LOGSEMANTIC) {
		printf("MinExp.semantic('%s')\n", toChars());
}
		if (type)
			return this;

		super.semanticp(sc);

		e = op_overload(sc);
		if (e)
			return e;

		e = this;
		t1 = e1.type.toBasetype();
		t2 = e2.type.toBasetype();
		if (t1.ty == TY.Tpointer)
		{
			if (t2.ty == TY.Tpointer)
			{   // Need to divide the result by the stride
				// Replace (ptr - ptr) with (ptr - ptr) / stride
				long stride;
				Expression ee;

				typeCombine(sc);		// make sure pointer types are compatible
				type = Type.tptrdiff_t;
				stride = t2.nextOf().size();
				if (stride == 0)
				{
					ee = new IntegerExp(loc, 0, Type.tptrdiff_t);
				}
				else
				{
					ee = new DivExp(loc, this, new IntegerExp(Loc(0), stride, Type.tptrdiff_t));
					ee.type = Type.tptrdiff_t;
				}
				return ee;
			}
			else if (t2.isintegral())
				e = scaleFactor(sc);
			else
			{   
				error("incompatible types for minus");
				return new ErrorExp();
			}
		}
		else if (t2.ty == TY.Tpointer)
		{
			type = e2.type;
			error("can't subtract pointer from %s", e1.type.toChars());
			return new ErrorExp();
		}
		else
		{
			typeCombine(sc);
			t1 = e1.type.toBasetype();
			t2 = e2.type.toBasetype();
			if ((t1.isreal() && t2.isimaginary()) ||
				(t1.isimaginary() && t2.isreal()))
			{
				switch (type.ty)
				{
					case TY.Tfloat32:
					case TY.Timaginary32:
						type = Type.tcomplex32;
						break;

					case TY.Tfloat64:
					case TY.Timaginary64:
						type = Type.tcomplex64;
						break;

					case TY.Tfloat80:
					case TY.Timaginary80:
						type = Type.tcomplex80;
						break;

					default:
						assert(0);
				}
			}
		}
		return e;
	}

	override Expression optimize(int result)
	{
		Expression e;

		e1 = e1.optimize(result);
		e2 = e2.optimize(result);
		if (e1.isConst() && e2.isConst())
		{
			if (e2.op == TOK.TOKsymoff)
				return this;
			e = Min(type, e1, e2);
		}
		else
			e = this;

		return e;
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon(istate, &Min);
	}

	override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		Exp_buildArrayIdent(buf, arguments, "Min");
	}

	override Expression buildArrayLoop(Parameters fparams)
	{
		return Exp_buildArrayLoop!(typeof(this))(fparams);
	}

	override Identifier opId()
	{
		return Id.sub;
	}

	override Identifier opId_r()
	{
		return Id.sub_r;
	}

	override elem* toElem(IRState* irs)
	{
		Type tb1 = e1.type.toBasetype();
		Type tb2 = e2.type.toBasetype();

		if ((tb1.ty == TY.Tarray || tb1.ty == TY.Tsarray) && (tb2.ty == TY.Tarray || tb2.ty == TY.Tsarray))
		{
			error("Array operation %s not implemented", toChars());
			return el_long(type.totym(), 0);	// error recovery
		}

		return toElemBin(irs, OPER.OPmin);
	}
}

