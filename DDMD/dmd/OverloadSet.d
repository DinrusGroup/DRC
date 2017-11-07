module dmd.OverloadSet;

import dmd.common;
import dmd.Dsymbol;
import dmd.ArrayTypes;

import dmd.DDMDExtensions;

class OverloadSet : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));

    Dsymbols a;		// array of Dsymbols

    this()
	{
		register();
		a = new Dsymbols();
	}
	
    void push(Dsymbol s)
	{
		a.push(s);
	}
	
    override OverloadSet isOverloadSet() { return this; }

    override string kind()
	{
		return "overloadset";
	}
}
