module dmd.ModAssignExp;

import dmd.common;
import dmd.expression.Mod;
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
import dmd.backend.OPER;
import dmd.Id;

import dmd.backend.elem;

import dmd.DDMDExtensions;

class ModAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKmodass, this.sizeof, e1, e2);
	}
	
    override Expression semantic(Scope sc)
	{
	    BinExp.semantic(sc);
		checkComplexMulAssign();
   		return commonSemanticAssign(sc);
	}
	
    override Expression interpret(InterState istate)
	{
    	return interpretAssignCommon(istate, &Mod);
	}
	
    override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		AssignExp_buildArrayIdent(buf, arguments, "Mod");
	}
	
    override Expression buildArrayLoop(Parameters fparams)
	{
		return AssignExp_buildArrayLoop!(typeof(this))(fparams);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.modass;
	}

    override elem* toElem(IRState* irs)
	{
		return toElemBin(irs,OPmodass);
	}
}
