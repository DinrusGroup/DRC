module dmd.NotExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.UnaExp;
import dmd.InterState;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.TOK;
import dmd.Type;

import dmd.expression.Not;

import dmd.backend.OPER;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class NotExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		register();
		super(loc, TOK.TOKnot, NotExp.sizeof, e);
	}

	override Expression semantic(Scope sc)
	{
		UnaExp.semantic(sc);
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
			e = Not(type, e1);
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
		assert(false);
	}

	override elem* toElem(IRState* irs)
	{
		elem* e = el_una(OPnot, type.totym(), e1.toElem(irs));
		el_setLoc(e,loc);
		return e;
	}
}
