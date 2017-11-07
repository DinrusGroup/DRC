module dmd.NegExp;

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
import dmd.Id;

import dmd.expression.Neg;

import dmd.backend.Util;
import dmd.backend.OPER;

import dmd.DDMDExtensions;

class NegExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		register();
		super(loc, TOKneg, NegExp.sizeof, e);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

	version (LOGSEMANTIC) {
		printf("NegExp::semantic('%s')\n", toChars());
	}
		if (!type)
		{
			UnaExp.semantic(sc);
			e1 = resolveProperties(sc, e1);
			e = op_overload(sc);
			if (e)
				return e;

			e1.checkNoBool();
			if (!e1.isArrayOperand())
				e1.checkArithmetic();

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
			e = Neg(type, e1);
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
		buf.writestring("Neg");
	}

	override Expression buildArrayLoop(Parameters fparams)
	{
		Expression ex1 = e1.buildArrayLoop(fparams);
		Expression e = new NegExp(Loc(0), ex1);
		return e;
	}

	override Identifier opId()
	{
		return Id.neg;
	}

	override elem* toElem(IRState* irs)
	{
		elem *e = el_una(OPneg, type.totym(), e1.toElem(irs));
		el_setLoc(e,loc);
		return e;
	}
}

