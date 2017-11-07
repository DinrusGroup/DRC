module dmd.DVCondition;

import dmd.common;
import dmd.Condition;
import dmd.Identifier;
import dmd.Module;
import dmd.Loc;

class DVCondition : Condition
{
    uint level;
    Identifier ident;
    Module mod;

    this(Module mod, uint level, Identifier ident)
	{
		register();
		super(Loc(0));
		this.mod = mod;
		this.level = level;
		this.ident = ident;
	}

    override Condition syntaxCopy()
	{
		return this;	// don't need to copy
	}
}
