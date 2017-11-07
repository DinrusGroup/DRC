module dmd.ComExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.backend.elem;
import dmd.UnaExp;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.ArrayTypes;
import dmd.TOK;
import dmd.TY;
import dmd.Id;

import dmd.backend.Util;
import dmd.backend.OPER;

import dmd.expression.Util;
import dmd.expression.Com;

import dmd.DDMDExtensions;

class ComExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		register();

		super(loc, TOKtilde, ComExp.sizeof, e);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

		if (!type)
		{
			UnaExp.semantic(sc);
			e1 = resolveProperties(sc, e1);
			e = op_overload(sc);
			if (e)
				return e;

			e1.checkNoBool();
			if (e1.op != TOKslice)
				e1 = e1.checkIntegral();
			type = e1.type;
		}
		return this;
	}

	override Expression optimize(int result)
	{
		Expression e;

		e1 = e1.optimize(result);
		if (e1.isConst() == 1)
		{
			e = Com(type, e1);
		}
		else
			e = this;

		return e;
	}

	override Expression interpret(InterState istate)
	{
		assert(false);
	}

	override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		e1.buildArrayIdent(buf, arguments);
		buf.writestring("Com");
	}

	override Expression buildArrayLoop(Parameters fparams)
	{
		Expression ex1 = e1.buildArrayLoop(fparams);
		Expression e = new ComExp(Loc(0), ex1);
		return e;
	}

	override Identifier opId()
	{
		return Id.com;
	}

	override elem* toElem(IRState* irs)
	{
		elem *e;

		elem *e1 = this.e1.toElem(irs);
		tym_t ty = type.totym();
		if (this.e1.type.toBasetype().ty == Tbool)
			e = el_bin(OPxor, ty, e1, el_long(ty, 1));
		else
			e = el_una(OPcom,ty,e1);
		el_setLoc(e,loc);
		return e;
	}
}

