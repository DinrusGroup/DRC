module dmd.AddExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.backend.elem;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Id;
import dmd.Scope;
import dmd.IRState;
import dmd.ArrayTypes;
import dmd.BinExp;
import dmd.Type;
import dmd.TOK;
import dmd.TY;

import dmd.expression.Add;
import dmd.backend.Util;
import dmd.backend.OPER;

import dmd.DDMDExtensions;

class AddExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKadd, AddExp.sizeof, e1, e2);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

version (LOGSEMANTIC) {
		printf("AddExp.semantic('%s')\n", toChars());
}
		if (!type)
		{
			BinExp.semanticp(sc);

			e = op_overload(sc);
			if (e)
				return e;

			Type tb1 = e1.type.toBasetype();
			Type tb2 = e2.type.toBasetype();

			if ((tb1.ty == TY.Tarray || tb1.ty == TY.Tsarray) &&
				(tb2.ty == TY.Tarray || tb2.ty == TY.Tsarray) &&
				tb1.nextOf().equals(tb2.nextOf())
			   )
			{
				type = e1.type;
				e = this;
			}
			else if (tb1.ty == TY.Tpointer && e2.type.isintegral() ||
				tb2.ty == TY.Tpointer && e1.type.isintegral())
				e = scaleFactor(sc);
			else if (tb1.ty == TY.Tpointer && tb2.ty == TY.Tpointer)
			{
				incompatibleTypes();
				type = e1.type;
				e = this;
			}
			else
			{
				typeCombine(sc);
				if ((e1.type.isreal() && e2.type.isimaginary()) ||
				(e1.type.isimaginary() && e2.type.isreal()))
				{
					switch (type.toBasetype().ty)
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
					}
				}
				e = this;
			}
			return e;
		}
		return this;
	}

	override Expression optimize(int result)
	{
		Expression e;

		//printf("AddExp::optimize(%s)\n", toChars());
		e1 = e1.optimize(result);
		e2 = e2.optimize(result);
		if (e1.isConst() && e2.isConst())
		{
			if (e1.op == TOK.TOKsymoff && e2.op == TOK.TOKsymoff)
				return this;
			e = Add(type, e1, e2);
		}
		else
			e = this;

		return e;
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon(istate, &Add);
	}

	override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		Exp_buildArrayIdent(buf, arguments, "Add");
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
		return Id.add;
	}

	override Identifier opId_r()
	{
		return Id.add_r;
	}

	override elem* toElem(IRState* irs)
	{
		elem *e;
		Type tb1 = e1.type.toBasetype();
		Type tb2 = e2.type.toBasetype();

		if ((tb1.ty == TY.Tarray || tb1.ty == TY.Tsarray) && (tb2.ty == TY.Tarray || tb2.ty == TY.Tsarray))
		{
			error("Array operation %s not implemented", toChars());
			e = el_long(type.totym(), 0);	// error recovery
		}
		else
			e = toElemBin(irs, OPER.OPadd);

		return e;
	}
}

