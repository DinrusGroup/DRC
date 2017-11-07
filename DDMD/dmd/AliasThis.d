module dmd.AliasThis;

import dmd.common;
import dmd.Dsymbol;
import dmd.Identifier;
import dmd.Loc;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.AggregateDeclaration;

import dmd.DDMDExtensions;

class AliasThis : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));

   // alias Identifier this;
    Identifier ident;

    this(Loc loc, Identifier ident)
	{
		register();
		super(null);		// it's anonymous (no identifier)
		this.loc = loc;
		this.ident = ident;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		/* Since there is no semantic information stored here,
		 * we don't need to copy it.
		 */
		return this;
	}
	
    override void semantic(Scope sc)
	{
		Dsymbol parent = sc.parent;
		if (parent)
			parent = parent.pastMixin();
		AggregateDeclaration ad = null;
		if (parent)
			ad = parent.isAggregateDeclaration();
		if (ad)
		{
			if (ad.aliasthis)
				error("there can be only one alias this");
			assert(ad.members);
			Dsymbol s = ad.search(loc, ident, 0);
			ad.aliasthis = s;
		}
		else
			error("alias this can only appear in struct or class declaration, not %s", parent ? parent.toChars() : "nowhere");
	}
	
    override string kind()
	{
		assert(false);
	}
		
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
	
    AliasThis isAliasThis() { return this; }
}
