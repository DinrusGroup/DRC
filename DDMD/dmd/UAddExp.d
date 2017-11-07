module dmd.UAddExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.UnaExp;
import dmd.Loc;
import dmd.Scope;
import dmd.TOK;
import dmd.Id;

import dmd.DDMDExtensions;

class UAddExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		register();
		super(loc, TOK.TOKuadd, this.sizeof, e);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

		version (LOGSEMANTIC) {
			printf("UAddExp.semantic('%s')\n", toChars());
		}
		assert(!type);
		UnaExp.semantic(sc);
		e1 = resolveProperties(sc, e1);
		e = op_overload(sc);
		if (e)
			return e;
		e1.checkNoBool();
		e1.checkArithmetic();
		return e1;
	}

	override Identifier opId()
	{
		return Id.uadd;
	}
}
