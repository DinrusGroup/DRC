module dmd.Condition;

import dmd.common;
import dmd.Loc;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.OutBuffer;
import dmd.HdrGenState;

import dmd.TObject;

import dmd.DDMDExtensions;

class Condition : TObject
{
	mixin insertMemberExtension!(typeof(this));

    Loc loc;
    int inc = 0;// 0: not computed yet
				// 1: include
				// 2: do not include

    this(Loc loc)
	{
		register();
		this.loc = loc;
	}

    abstract Condition syntaxCopy();
    abstract bool include(Scope sc, ScopeDsymbol s);
    abstract void toCBuffer(OutBuffer buf, HdrGenState* hgs);
}