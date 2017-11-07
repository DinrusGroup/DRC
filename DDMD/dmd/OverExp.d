module dmd.OverExp;

import dmd.common;
import dmd.Expression;
import dmd.OverloadSet;
import dmd.Scope;
import dmd.Loc;
import dmd.TOK;
import dmd.Type;

import dmd.DDMDExtensions;

//! overload set
version(DMDV2)
class OverExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	OverloadSet vars;

	this(OverloadSet s)
	{
		register();
		super(loc, TOKoverloadset, OverExp.sizeof);
		//printf("OverExp(this = %p, '%s')\n", this, var.toChars());
		vars = s;
		type = Type.tvoid;
	}

	override bool isLvalue()
	{
		return true;
	}

	override Expression toLvalue(Scope sc, Expression e)
	{
		return this;
	}
}

