module dmd.DefaultInitExp;

import dmd.common;
import dmd.Expression;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.Token;

import dmd.DDMDExtensions;

class DefaultInitExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	TOK subop;

	this(Loc loc, TOK subop, int size)
	{
		register();
		super(loc, TOKdefault, size);
		this.subop = subop;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring(Token.toChars(subop));
	}
}
