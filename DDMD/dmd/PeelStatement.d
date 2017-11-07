module dmd.PeelStatement;

import dmd.common;
import dmd.Statement;
import dmd.Scope;
import dmd.Loc;

import dmd.DDMDExtensions;

class PeelStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

	Statement s;

	this(Statement s)
	{
		register();
		assert(false);
		super(Loc(0));
	}

	override Statement semantic(Scope sc)
	{
		assert(false);
	}
}

