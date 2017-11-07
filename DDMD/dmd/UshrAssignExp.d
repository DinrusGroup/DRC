module dmd.UshrAssignExp;

import dmd.common;
import dmd.BinExp;
import dmd.Loc;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.Identifier;
import dmd.IRState;
import dmd.Id;
import dmd.TOK;
import dmd.Type;
import dmd.ArrayLengthExp;
import dmd.backend.elem;
import dmd.expression.Ushr;
import dmd.expression.Util;

import dmd.backend.OPER;

import dmd.DDMDExtensions;

class UshrAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKushrass, UshrAssignExp.sizeof, e1, e2);
	}
	
    override Expression semantic(Scope sc)
	{
		Expression e;

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
    	return interpretAssignCommon(istate, &Ushr);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.ushrass;
	}

    override elem* toElem(IRState* irs)
	{
		return toElemBin(irs, OPER.OPshrass);
	}
}
