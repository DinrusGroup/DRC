module dmd.AttribDeclaration;

import dmd.common;
import dmd.Dsymbol;
import dmd.Array;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.LINK;
import dmd.STC;
import dmd.PROT;
import dmd.ArrayTypes;
import dmd.OutBuffer;
import dmd.HdrGenState;

import dmd.DDMDExtensions;

class AttribDeclaration : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));

    Dsymbols decl;	// array of Dsymbol's

    this(Dsymbols decl)
	{
		register();

		this.decl = decl;
	}
	
    Dsymbols include(Scope sc, ScopeDsymbol sd)
	{
		return decl;
	}
	
    override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
	{
		bool m = false;
		auto d = include(sc, sd);

		if (d)
		{
            foreach(s; d)
                m |= s.addMember(sc, sd, m | memnum);
		}

		return m;
	}
	
    void setScopeNewSc(Scope sc, StorageClass stc, LINK linkage, PROT protection, int explicitProtection, uint structalign)
	{
		if (decl)
		{
			Scope newsc = sc;
			if (stc != sc.stc || linkage != sc.linkage || protection != sc.protection || explicitProtection != sc.explicitProtection || structalign != sc.structalign)
			{
				// create new one for changes
				newsc = sc.clone();				
				newsc.flags &= ~SCOPE.SCOPEfree;
				newsc.stc = stc;
				newsc.linkage = linkage;
				newsc.protection = protection;
				newsc.explicitProtection = explicitProtection;
				newsc.structalign = structalign;
			}
			foreach(Dsymbol s; decl)
				s.setScope(newsc);	// yes, the only difference from semanticNewSc()
			if (newsc != sc)
			{
				sc.offset = newsc.offset;
				newsc.pop();
			}
		}
	}
	
    void semanticNewSc(Scope sc, StorageClass stc, LINK linkage, PROT protection, int explicitProtection, uint structalign)
	{
		if (decl)
		{
			Scope newsc = sc;
			if (stc != sc.stc || linkage != sc.linkage || protection != sc.protection || explicitProtection != sc.explicitProtection || structalign != sc.structalign)
			{
				// create new one for changes
				newsc = sc.clone();
				newsc.flags &= ~SCOPE.SCOPEfree;
				newsc.stc = stc;
				newsc.linkage = linkage;
				newsc.protection = protection;
				newsc.explicitProtection = explicitProtection;
				newsc.structalign = structalign;
			}
			foreach(Dsymbol s; decl)
				s.semantic(newsc);
			if (newsc != sc)
			{
				sc.offset = newsc.offset;
				newsc.pop();
			}
		}
	}
	
    override void semantic(Scope sc)
	{
		auto d = include(sc, null);

		//printf("\tAttribDeclaration::semantic '%s', d = %p\n",toChars(), d);
		if (d)
		{
			foreach(s; d)
				s.semantic(sc);
		}
	}
	
    override void semantic2(Scope sc)
	{
		auto d = include(sc, null);

		if (d)
		{
			foreach(s; d)
				s.semantic2(sc);
		}
	}
	
    override void semantic3(Scope sc)
	{
		auto d = include(sc, null);

		if (d)
		{
			foreach(s; d)
				s.semantic3(sc);
		}
	}
	
    override void inlineScan()
	{
		auto d = include(null, null);

		if (d)
		{
			foreach(s; d)
			{   
				//printf("AttribDeclaration.inlineScan %s\n", s.toChars());
				s.inlineScan();
			}
		}
	}
	
    override void addComment(string comment)
	{
		if (comment !is null)
		{
			auto d = include(null, null);
			if (d)
			{
				foreach(s; d)
				{  
					//printf("AttribDeclaration::addComment %s\n", s.toChars());
					s.addComment(comment);
				}
			}
		}
	}
	
    override void emitComment(Scope sc)
	{
		assert(false);
	}
	
    override string kind()
	{
		assert(false);
	}
	
    override bool oneMember(Dsymbol* ps)
	{
		auto d = include(null, null);

		return Dsymbol.oneMembers(d, ps);
	}
	
    override bool hasPointers()
	{
		auto d = include(null, null);

		if (d)
		{
			foreach(s; d)
			{
				if (s.hasPointers())
					return true;
			}
		}

		return false;
	}
	
    override void checkCtorConstInit()
	{
		auto d = include(null, null);
		if (d)
		{
			foreach(s; d)
				s.checkCtorConstInit();
		}
	}
	
    override void addLocalClass(ClassDeclarations aclasses)
	{
		auto d = include(null, null);
		if (d)
		{
			foreach(s; d)
				s.addLocalClass(aclasses);
		}
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
    
	override void toJsonBuffer(OutBuffer buf)
	{
		//writef("AttribDeclaration.toJsonBuffer()\n");

		Dsymbols d = include(null, null);

		if (d)
		{
			foreach (Dsymbol s; d)
			{
				//writef("AttribDeclaration.toJsonBuffer %s\n", s.toChars());
				s.toJsonBuffer(buf);
			}
		}	
	}
    	
    override AttribDeclaration isAttribDeclaration() { return this; }

    override void toObjFile(int multiobj)			// compile to .obj file
	{
		auto d = include(null, null);

		if (d)
		{
			foreach(s; d)
				s.toObjFile(multiobj);
		}
	}
	
    override int cvMember(ubyte* p)
	{
		assert(false);
	}
}
