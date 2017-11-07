module dmd.SharedStaticCtorDeclaration;

import dmd.StaticCtorDeclaration;
import dmd.Loc;
import dmd.Dsymbol;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.FuncDeclaration;

import dmd.DDMDExtensions;

class SharedStaticCtorDeclaration : StaticCtorDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Loc endloc)
	{
		super(loc, endloc, "_sharedStaticCtor");
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		SharedStaticCtorDeclaration scd = new SharedStaticCtorDeclaration(loc, endloc);
		return FuncDeclaration.syntaxCopy(scd);
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("shared ");
		StaticCtorDeclaration.toCBuffer(buf, hgs);
	}

    override SharedStaticCtorDeclaration isSharedStaticCtorDeclaration() { return this; }
}