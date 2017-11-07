module dmd.LinkDeclaration;

import dmd.common;
import dmd.AttribDeclaration;
import dmd.LINK;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.Array;

import dmd.DDMDExtensions;

class LinkDeclaration : AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    LINK linkage;

    this(LINK p, Dsymbols decl)
	{
		register();
		super(decl);
		//printf("LinkDeclaration(linkage = %d, decl = %p)\n", p, decl);
		linkage = p;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(false);
	}

    override void setScope(Scope sc)
	{
		//printf("LinkDeclaration::setScope(linkage = %d, decl = %p)\n", linkage, decl);
		if (decl)
		{
			setScopeNewSc(sc, sc.stc, linkage, sc.protection, sc.explicitProtection, sc.structalign);
		}
	}
	
    override void semantic(Scope sc)
	{
		//printf("LinkDeclaration::semantic(linkage = %d, decl = %p)\n", linkage, decl);
		if (decl)
		{
			semanticNewSc(sc, sc.stc, linkage, sc.protection, sc.explicitProtection, sc.structalign);
		}
	}
	
    override void semantic3(Scope sc)
	{
		//printf("LinkDeclaration::semantic3(linkage = %d, decl = %p)\n", linkage, decl);
		if (decl)
		{	
			LINK linkage_save = sc.linkage;

			sc.linkage = linkage;
			foreach(Dsymbol s; decl)
				s.semantic3(sc);
			sc.linkage = linkage_save;
		}
		else
		{
			sc.linkage = linkage;
		}
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
	
    override string toChars()
	{
		assert(false);
	}
}
