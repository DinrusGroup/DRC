module dmd.Package;

import dmd.common;
import dmd.ScopeDsymbol;
import dmd.Identifier;
import dmd.ArrayTypes;
import dmd.DsymbolTable;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.Module;
import dmd.Global;
import dmd.Util;

import dmd.DDMDExtensions;

class Package : ScopeDsymbol
{
	mixin insertMemberExtension!(typeof(this));

    this(Identifier ident)
	{
		register();
		super(ident);
	}
	
    override string kind()
	{
		assert(false);
	}

    static DsymbolTable resolve(Identifiers packages, Dsymbol* pparent, Package* ppkg)
	{
		DsymbolTable dst = global.modules;
		Dsymbol parent = null;

		//printf("Package::resolve()\n");
		if (ppkg)
			*ppkg = null;

		if (packages)
		{
			foreach (pid; packages)
			{   
				Dsymbol p = dst.lookup(pid);
				if (!p)
				{
					p = new Package(pid);
					dst.insert(p);
					p.parent = parent;
					(cast(ScopeDsymbol)p).symtab = new DsymbolTable();
				}
				else
				{
					assert(p.isPackage());
version (TARGET_NET) {		//dot net needs modules and packages with same name
} else {
					if (p.isModule())
					{   
						p.error("module and package have the same name");
						fatal();
						break;
					}
}
				}
				parent = p;
				dst = (cast(Package)p).symtab;
				if (ppkg && !*ppkg)
					*ppkg = cast(Package)p;
			}
			if (pparent)
			{
				*pparent = parent;
			}
		}
		return dst;
	}

    override Package isPackage() { return this; }

    override void semantic(Scope sc) { }
}
