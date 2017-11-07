module dmd.DivAssignExp;

import dmd.common;
import dmd.BinExp;
import dmd.Loc;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.ArrayTypes;
import dmd.Identifier;
import dmd.IRState;
import dmd.TOK;
import dmd.Type;
import dmd.TY;
import dmd.Id;
import dmd.CommaExp;
import dmd.RealExp;
import dmd.AssignExp;
import dmd.ArrayLengthExp;

import dmd.backend.elem;
import dmd.backend.OPER;
import dmd.backend.Util;
import dmd.expression.Div;
import dmd.expression.Util;

import dmd.DDMDExtensions;

class DivAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKdivass, DivAssignExp.sizeof, e1, e2);
	}
	
    override Expression semantic(Scope sc)
	{
		Expression e;

		BinExp.semantic(sc);
		e2 = resolveProperties(sc, e2);

		e = op_overload(sc);
		if (e)
			return e;

version(DMDV2) {
    if (e1.op == TOK.TOKarraylength)
    {
	e = ArrayLengthExp.rewriteOpAssign(this);
	e = e.semantic(sc);
	return e;
    }
}

		if (e1.op == TOKslice)
		{	// T[] -= ...
			typeCombine(sc);
			type = e1.type;
			return arrayOp(sc);
		}

		e1 = e1.modifiableLvalue(sc, e1);
		e1.checkScalar();
		e1.checkNoBool();
		type = e1.type;
		typeCombine(sc);
		e1.checkArithmetic();
		e2.checkArithmetic();
	    checkComplexMulAssign();
		if (e2.type.isimaginary())
		{	
			Type t1;
			Type t2;

			t1 = e1.type;
			if (t1.isreal())
			{   
				// x/iv = i(-x/v)
				// Therefore, the result is 0
				e2 = new CommaExp(loc, e2, new RealExp(loc, 0, t1));
				e2.type = t1;
				e = new AssignExp(loc, e1, e2);
				e.type = t1;
				return e;
			}
			else if (t1.isimaginary())
			{   
				Expression e3;

				switch (t1.ty)
				{
					case Timaginary32: t2 = Type.tfloat32; break;
					case Timaginary64: t2 = Type.tfloat64; break;
					case Timaginary80: t2 = Type.tfloat80; break;
					default:
						assert(0);
				}
				e2 = e2.castTo(sc, t2);
				e3 = new AssignExp(loc, e1, e2);
				e3.type = t1;
				return e3;
			}
		}
		return this;
	}
	
    override Expression interpret(InterState istate)
	{
    	return interpretAssignCommon(istate, &Div);
	}
	
    override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		AssignExp_buildArrayIdent(buf, arguments, "Div");
	}
	
    override Expression buildArrayLoop(Parameters fparams)
	{
		return AssignExp_buildArrayLoop!(typeof(this))(fparams);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.divass;
	}

    override elem* toElem(IRState* irs)
	{
		return toElemBin(irs,OPdivass);
	}
}
