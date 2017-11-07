module dmd.LabelDsymbol;

import dmd.common;
import dmd.Dsymbol;
import dmd.LabelStatement;
import dmd.Identifier;

import dmd.DDMDExtensions;

class LabelDsymbol : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));

    LabelStatement statement;

version (IN_GCC) {
    uint asmLabelNum;       // GCC-specific
}

    this(Identifier ident)
	{
		register();
		super(ident);
	}
	
    override LabelDsymbol isLabel()
	{
		return this;
	}
}
