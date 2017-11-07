module dmd.DebugCondition;

import dmd.common;
import dmd.DVCondition;
import dmd.Module;
import dmd.Identifier;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Array;
import dmd.String;
import dmd.Global;

import dmd.condition.util.findCondition;

import dmd.DDMDExtensions;

class DebugCondition : DVCondition
{
	mixin insertMemberExtension!(typeof(this));

    static void setGlobalLevel(uint level)
	{
		assert(false);
	}
	
    static void addGlobalIdent(const(char)* ident)
	{
		assert(false);
	}
	
    static void addPredefinedGlobalIdent(const(char)* ident)
	{
		assert(false);
	}

    this(Module mod, uint level, Identifier ident)
	{
		register();
		super(mod, level, ident);
	}

    override bool include(Scope sc, ScopeDsymbol s)
	{
		//printf("DebugCondition::include() level = %d, debuglevel = %d\n", level, global.params.debuglevel);
		if (inc == 0)
		{
			inc = 2;

			if (ident)
			{
				if (findCondition(mod.debugids, ident))
					inc = 1;
				else if (findCondition(global.params.debugids, ident))
					inc = 1;
				else
				{	
					if (!mod.debugidsNot)
						mod.debugidsNot = new Vector!string();

					mod.debugidsNot.push(ident.toChars());
				}
			}
			else if (level <= global.params.debuglevel || level <= mod.debuglevel)
				inc = 1;
		}

		return (inc == 1);
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
}
