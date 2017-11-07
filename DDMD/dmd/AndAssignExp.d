module dmd.AndAssignExp;

import dmd.common;
import dmd.expression.And;
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
import dmd.Id;

import dmd.backend.elem;
import dmd.backend.OPER;

import dmd.DDMDExtensions;

class AndAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKandass, AndAssignExp.sizeof, e1, e2);
	}
	
    override Expression semantic(Scope sc)
	{
		return commonSemanticAssignIntegral(sc);
	}
	
    override Expression interpret(InterState istate)
	{
    	return interpretAssignCommon(istate, &And);
	}
	
    override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		AssignExp_buildArrayIdent(buf, arguments, "And");
	}
	
    override Expression buildArrayLoop(Parameters fparams)
	{
		return AssignExp_buildArrayLoop!(typeof(this))(fparams);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.andass;
	}

    override elem* toElem(IRState* irs)
	{
		return toElemBin(irs, OPER.OPandass);
	}
}
