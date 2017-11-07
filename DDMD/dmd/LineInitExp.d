module dmd.LineInitExp;

import dmd.common;
import dmd.Expression;
import dmd.Loc;
import dmd.Scope;
import dmd.DefaultInitExp;
import dmd.IntegerExp;
import dmd.TOK;
import dmd.Type;

import dmd.DDMDExtensions;

class LineInitExp : DefaultInitExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc)
	{
		register();
		super(loc, TOK.TOKline, this.sizeof);
	}

	override Expression semantic(Scope sc)
	{
		type = Type.tint32;
		return this;
	}

	override Expression resolveLoc(Loc loc, Scope sc)
	{
		Expression e = new IntegerExp(loc, loc.linnum, Type.tint32);
		e = e.castTo(sc, type);
		return e;
	}
}
