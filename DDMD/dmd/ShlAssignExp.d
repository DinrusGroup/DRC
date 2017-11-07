module dmd.ShlAssignExp;

import dmd.common;
import dmd.BinExp;
import dmd.Loc;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.Identifier;
import dmd.IRState;
import dmd.TOK;
import dmd.Id;
import dmd.Type;
import dmd.ArrayLengthExp;
import dmd.backend.elem;
import dmd.backend.OPER;
import dmd.expression.Shl;
import dmd.expression.Util;

import dmd.DDMDExtensions;

class ShlAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKshlass, ShlAssignExp.sizeof, e1, e2);
	}
	
    override Expression semantic(Scope sc)
	{
		Expression e;

		//printf("ShlAssignExp.semantic()\n");
		BinExp.semantic(sc);
		e2 = resolveProperties(sc, e2);

		e = op_overload(sc);
		if (e)
			return e;

        if (e1.op == TOK.TOKarraylength)
        {
	        e = ArrayLengthExp.rewriteOpAssign(this);
	        e = e.semantic(sc);
	        return e;
        }

		e1 = e1.modifiableLvalue(sc, e1);
		e1.checkScalar();
		e1.checkNoBool();
		type = e1.type;
		typeCombine(sc);
		e1.checkIntegral();
		e2 = e2.checkIntegral();
		e2 = e2.castTo(sc, Type.tshiftcnt);
		return this;
	}
	
    override Expression interpret(InterState istate)
	{
    	return interpretAssignCommon(istate, &Shl);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.shlass;
	}

    override elem* toElem(IRState* irs)
	{
		return toElemBin(irs,OPshlass);
	}
}
