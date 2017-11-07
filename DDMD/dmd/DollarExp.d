module dmd.DollarExp;

import dmd.common;
import dmd.IdentifierExp;
import dmd.Loc;
import dmd.Identifier;
import dmd.TOK;
import dmd.Id;

import dmd.DDMDExtensions;

class DollarExp : IdentifierExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc)
	{
		register();
		super(loc, Id.dollar);
	}
}

