module dmd.WithScopeSymbol;

import dmd.common;
import dmd.ScopeDsymbol;
import dmd.WithStatement;
import dmd.Loc;
import dmd.Identifier;
import dmd.Dsymbol;

import dmd.DDMDExtensions;

class WithScopeSymbol : ScopeDsymbol
{
	mixin insertMemberExtension!(typeof(this));

    WithStatement withstate;

    this(WithStatement withstate)
	{
		register();
		this.withstate = withstate;
	}
	
    override Dsymbol search(Loc loc, Identifier ident, int flags)
	{
		// Acts as proxy to the with class declaration
		return withstate.exp.type.toDsymbol(null).search(loc, ident, 0);
	}

    override WithScopeSymbol isWithScopeSymbol() { return this; }
}
