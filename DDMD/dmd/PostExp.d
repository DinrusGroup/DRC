module dmd.PostExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.backend.elem;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.PREC;
import dmd.BinExp;
import dmd.HdrGenState;
import dmd.IntegerExp;
import dmd.TOK;
import dmd.Type;
import dmd.TY;
import dmd.Id;

import dmd.expression.Util;

import dmd.backend.Util;
import dmd.backend.OPER;

import dmd.DDMDExtensions;

class PostExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(TOK op, Loc loc, Expression e)
	{
		register();
		super(loc, op, PostExp.sizeof, e, new IntegerExp(loc, 1, Type.tint32));
	}

	override Expression semantic(Scope sc)
	{
		Expression e = this;

		if (!type)
		{
			BinExp.semantic(sc);
			e2 = resolveProperties(sc, e2);

			e = op_overload(sc);
			if (e)
				return e;

			e = this;
			e1 = e1.modifiableLvalue(sc, e1);
			e1.checkScalar();
			e1.checkNoBool();
			if (e1.type.ty == Tpointer)
				e = scaleFactor(sc);
			else
				e2 = e2.castTo(sc, e1.type);
			e.type = e1.type;
		}
		return e;
	}

	override Expression interpret(InterState istate)
	{
		assert(false);
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		expToCBuffer(buf, hgs, e1, precedence[op]);
		buf.writestring((op == TOKplusplus) ? "++" : "--");
	}

	override Identifier opId()
	{
		return (op == TOKplusplus) ? Id.postinc : Id.postdec;
	}

	override elem* toElem(IRState* irs)
	{
		auto e = e1.toElem(irs);
		auto einc = e2.toElem(irs);
		e = el_bin((op == TOKplusplus) ? OPpostinc : OPpostdec,
			e.Ety,e,einc);
		el_setLoc(e,loc);
		return e;
	}
}

