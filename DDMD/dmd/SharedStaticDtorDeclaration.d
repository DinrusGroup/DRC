module dmd.SharedStaticDtorDeclaration;

import dmd.StaticDtorDeclaration;
import dmd.Loc;
import dmd.Dsymbol;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.FuncDeclaration;

import dmd.DDMDExtensions;

class SharedStaticDtorDeclaration : StaticDtorDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Loc endloc)
	{
	    super(loc, endloc, "_sharedStaticDtor");
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		SharedStaticDtorDeclaration sdd = new SharedStaticDtorDeclaration(loc, endloc);
		return FuncDeclaration.syntaxCopy(sdd);
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
	    if (!hgs.hdrgen)
		{
			buf.writestring("shared ");
			StaticDtorDeclaration.toCBuffer(buf, hgs);
		}
	}

    override SharedStaticDtorDeclaration isSharedStaticDtorDeclaration() { return this; }
}