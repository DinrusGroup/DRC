module dmd.StaticAssertStatement;

import dmd.common;
import dmd.Statement;
import dmd.StaticAssert;
import dmd.OutBuffer;
import dmd.BE;
import dmd.HdrGenState;
import dmd.Scope;
import dmd.Loc;

import dmd.DDMDExtensions;

class StaticAssertStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    StaticAssert sa;

    this(StaticAssert sa)
	{
		register();
		super(sa.loc);
		this.sa = sa;
	}
	
    override Statement syntaxCopy()
	{
		StaticAssertStatement s = new StaticAssertStatement(cast(StaticAssert)sa.syntaxCopy(null));
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		sa.semantic2(sc);
		return null;
	}

    override BE blockExit()
    {
    	return BE.BEfallthru;
    }
    
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
}
