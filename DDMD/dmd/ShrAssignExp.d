module dmd.ShrAssignExp;

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
import dmd.CastExp;

import dmd.backend.elem;
import dmd.backend.OPER;

import dmd.expression.Shr;
import dmd.expression.Util;

import dmd.DDMDExtensions;

class ShrAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKshrass, ShrAssignExp.sizeof, e1, e2);
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
    	return interpretAssignCommon(istate, &Shr);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.shrass;
	}

    override elem* toElem(IRState* irs)
	{
	    //printf("ShrAssignExp::toElem() %s, %s\n", e1->type->toChars(), e1->toChars());
		Type t1 = e1.type;
		if (e1.op == TOK.TOKcast)
		{
			// Use the type before it was integrally promoted to int
			auto ce = cast(CastExp)e1;
			t1 = ce.e1.type;
		}
		return toElemBin(irs, t1.isunsigned() ? OPER.OPshrass : OPER.OPashrass);

	}
}
