module dmd.MulAssignExp;

import dmd.common;
import dmd.BinExp;
import dmd.Loc;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Id;
import dmd.ArrayTypes;
import dmd.Identifier;
import dmd.IRState;
import dmd.TOK;
import dmd.Type;
import dmd.TY;
import dmd.ArrayLengthExp;

import dmd.backend.elem;
import dmd.backend.OPER;
import dmd.expression.Mul;
import dmd.expression.Util;

import dmd.DDMDExtensions;

class MulAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKmulass, MulAssignExp.sizeof, e1, e2);
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
		if (e2.type.isfloating())
		{	
			Type t1;
			Type t2;

			t1 = e1.type;
			t2 = e2.type;
			if (t1.isreal())
			{
				if (t2.isimaginary() || t2.iscomplex())
				{
					e2 = e2.castTo(sc, t1);
				}
			}
			else if (t1.isimaginary())
			{
				if (t2.isimaginary() || t2.iscomplex())
				{
					switch (t1.ty)
					{
						case Timaginary32: t2 = Type.tfloat32; break;
						case Timaginary64: t2 = Type.tfloat64; break;
						case Timaginary80: t2 = Type.tfloat80; break;
						default:
							assert(0);
					}
					e2 = e2.castTo(sc, t2);
				}
			}
		}
		return this;
	}
	
    override Expression interpret(InterState istate)
	{
    	return interpretAssignCommon(istate, &Mul);
	}
	
    override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		AssignExp_buildArrayIdent(buf, arguments, "Mul");
	}
	
    override Expression buildArrayLoop(Parameters fparams)
	{
		return AssignExp_buildArrayLoop!(typeof(this))(fparams);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.mulass;
	}

    override elem* toElem(IRState* irs)
	{
		return toElemBin(irs,OPmulass);
	}
}
