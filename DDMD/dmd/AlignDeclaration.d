module dmd.AlignDeclaration;

import dmd.common;
import dmd.AttribDeclaration;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.Array;

import dmd.DDMDExtensions;

class AlignDeclaration : AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    uint salign;

    this(uint sa, Dsymbols decl)
	{
		register();
		super(decl);
		salign = sa;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(false);
	}
	
    override void setScope(Scope sc)
	{
		//printf("\tAlignDeclaration::setScope '%s'\n",toChars());
		if (decl)
		{
			setScopeNewSc(sc, sc.stc, sc.linkage, sc.protection, sc.explicitProtection, salign);
		}
	}
	
    override void semantic(Scope sc)
	{
		//printf("\tAlignDeclaration::semantic '%s'\n",toChars());
		if (decl)
		{
			semanticNewSc(sc, sc.stc, sc.linkage, sc.protection, sc.explicitProtection, salign);
		}
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
}
