module dmd.BoolExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.UnaExp;
import dmd.InterState;
import dmd.Type;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.TOK;

import dmd.expression.Bool;
import dmd.backend.OPER;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class BoolExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e, Type t)
	{
		register();

		super(loc, TOKtobool, BoolExp.sizeof, e);
		type = t;
	}

	override Expression semantic(Scope sc)
	{
		super.semantic(sc);
		e1 = resolveProperties(sc, e1);
		e1 = e1.checkToBoolean();
		type = Type.tboolean;
		return this;
	}

	override Expression optimize(int result)
	{
		Expression e;

	    e1 = e1.optimize(result);
	    if (e1.isConst() == 1)
	    {
	        e = Bool(type, e1);
	    }
	    else
	        e = this;
	    return e;
	}

	override Expression interpret(InterState istate)
	{
		assert(false);
	}

	override bool isBit()
	{
		return true;
	}

	override elem* toElem(IRState* irs)
	{
		elem* e1 = this.e1.toElem(irs);
		return el_una(OPbool,type.totym(),e1);
	}
}

