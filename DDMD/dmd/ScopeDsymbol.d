module dmd.ScopeDsymbol;

import dmd.common;
import dmd.Dsymbol;
import dmd.Declaration;
import dmd.Array;
import dmd.OverloadSet;
import dmd.Import;
import dmd.DsymbolTable;
import dmd.Identifier;
import dmd.Loc;
import dmd.PROT;
import dmd.FuncDeclaration;
import dmd.Scope;
import dmd.Util;
import dmd.Id;
import dmd.expression.Util;

import dmd.DDMDExtensions;

import std.stdio : writef;
//core.stdc.stdlib;
import core.memory;

class ScopeDsymbol : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));
	
    Dsymbols members;		// all Dsymbol's in this scope
    DsymbolTable symtab;	// members[] sorted into table

    Array imports;		// imported ScopeDsymbol's
    PROT* prots;	// array of PROT, one for each import

    this()
	{
		register();
		// do nothing
	}
	
    this(Identifier id)
	{
		register();
		super(id);
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
	    //printf("ScopeDsymbol.syntaxCopy('%s')\n", toChars());

	    ScopeDsymbol sd;
	    if (s)
		sd = cast(ScopeDsymbol)s;
	    else
		sd = new ScopeDsymbol(ident);
	    sd.members = arraySyntaxCopy(members);
	    return sd;
	}
	
    override Dsymbol search(Loc loc, Identifier ident, int flags)
	{
		//printf("%s.ScopeDsymbol.search(ident='%s', flags=x%x)\n", toChars(), ident.toChars(), flags);
		//if (strcmp(ident.toChars(),"c") == 0) *(char*)0=0;

		// Look in symbols declared in this module
		Dsymbol s = symtab ? symtab.lookup(ident) : null;
		// writef("\ts = %p, imports = %p, %d\n", s, imports, imports ? imports->dim : 0);
		if (s)
		{
			//printf("\ts = '%s.%s'\n",toChars(),s.toChars());
		}
		else if (imports)
		{
			OverloadSet a = null;

			// Look in imported modules
			for (int i = 0; i < imports.dim; i++)
			{   
				ScopeDsymbol ss = cast(ScopeDsymbol)imports.data[i];
				Dsymbol s2;

				// If private import, don't search it
				if (flags & 1 && prots[i] == PROT.PROTprivate)
					continue;

				//printf("\tscanning import '%s', prots = %d, isModule = %p, isImport = %p\n", ss.toChars(), prots[i], ss.isModule(), ss.isImport());
				/* Don't find private members if ss is a module
				 */
				s2 = ss.search(loc, ident, ss.isModule() ? 1 : 0);
				if (!s)
					s = s2;
				else if (s2 && s != s2)
				{
				if (s.toAlias() == s2.toAlias())
				{
					/* After following aliases, we found the same symbol,
					 * so it's not an ambiguity.
					 * But if one alias is deprecated, prefer the other.
					 */
					if (s.isDeprecated())
					s = s2;
				}
				else
				{
					/* Two imports of the same module should be regarded as
					 * the same.
					 */
					Import i1 = s.isImport();
					Import i2 = s2.isImport();
					if (!(i1 && i2 &&
					  (i1.mod == i2.mod ||
					   (!i1.parent.isImport() && !i2.parent.isImport() &&
						i1.ident.equals(i2.ident))
					  )
					 )
					   )
					{
					/* If both s2 and s are overloadable (though we only
					 * need to check s once)
					 */
					if (s2.isOverloadable() && (a || s.isOverloadable()))
					{   if (!a)
						a = new OverloadSet();
						/* Don't add to a[] if s2 is alias of previous sym
						 */
						foreach (size_t j, Dsymbol s3; a.a)
						{	
							if (s2.toAlias() == s3.toAlias())
							{
								if (s3.isDeprecated())
									a.a[j] = s2;
								goto Lcontinue;
							}
						}
						a.push(s2);
					Lcontinue:
						continue;
					}
					if (flags & 4)		// if return null on ambiguity
						return null;
					if (!(flags & 2))
						ss.multiplyDefined(loc, s, s2);
					break;
					}
				}
				}
			}

			/* Build special symbol if we had multiple finds
			 */
			if (a)
			{
				assert(s);
				a.push(s);
				s = a;
			}

			if (s)
			{
				Declaration d = s.isDeclaration();
				if (d && d.protection == PROT.PROTprivate && !d.parent.isTemplateMixin() && !(flags & 2))
					error("%s is private", d.toPrettyChars());
			}
		}
		return s;
	}
	
    void importScope(ScopeDsymbol s, PROT protection)
	{
		//writef("%s.ScopeDsymbol.importScope(%s, %d)\n", toChars(), s.toChars(), protection);

		// No circular or redundant import's
		if (s !is this)
		{
			if (!imports)
				imports = new Array();
			else
			{
				for (int i = 0; i < imports.dim; i++)
				{   
					ScopeDsymbol ss = cast(ScopeDsymbol)imports.data[i];
					if (ss is s)			// if already imported
					{
						if (protection > prots[i])
							prots[i] = protection;	// upgrade access
						return;
					}
				}
			}
			imports.push(cast(void*)s);
			prots = cast(PROT*)GC.realloc(prots, imports.dim * prots[0].sizeof);
			prots[imports.dim - 1] = protection;
		}
	}

    override int isforwardRef()
	{
		return (members is null);
	}
	
    override void defineRef(Dsymbol s)
	{
		ScopeDsymbol ss = s.isScopeDsymbol();
		members = ss.members;
		ss.members = null;
	}

    static void multiplyDefined(Loc loc, Dsymbol s1, Dsymbol s2)
	{
static if (false) {
		printf("ScopeDsymbol::multiplyDefined()\n");
		printf("s1 = %p, '%s' kind = '%s', parent = %s\n", s1, s1.toChars(), s1.kind(), s1.parent ? s1.parent.toChars() : "");
		printf("s2 = %p, '%s' kind = '%s', parent = %s\n", s2, s2.toChars(), s2.kind(), s2.parent ? s2.parent.toChars() : "");
}
		if (loc.filename)
		{
			.error(loc, "%s at %s conflicts with %s at %s",
			s1.toPrettyChars(),
			s1.locToChars(),
			s2.toPrettyChars(),
			s2.locToChars());
		}
		else
		{
			s1.error(loc, "conflicts with %s %s at %s", s2.kind(), s2.toPrettyChars(), s2.locToChars());
		}
	}

    Dsymbol nameCollision(Dsymbol s)
	{
		assert(false);
	}
	
    override string kind()
	{
		assert(false);
	}

version(DMDV2)
{
	/*******************************************
	 * Look for member of the form:
	 *	const(MemberInfo)[] getMembers(string);
	 * Returns NULL if not found
	 */
    FuncDeclaration findGetMembers()
	{
		Dsymbol s = search_function(this, Id.getmembers);
		FuncDeclaration fdx = s ? s.isFuncDeclaration() : null;

static if (false) {  // Finish
		static __gshared TypeFunction tfgetmembers;

		if (!tfgetmembers)
		{
			Scope sc;
			auto arguments = new Arguments();
			auto arg = new Argument(STCin, Type.tchar.constOf().arrayOf(), null, null);
			arguments.push(arg);

			Type tret = null;
			tfgetmembers = new TypeFunction(arguments, tret, 0, LINK.LINKd);
			tfgetmembers = cast(TypeFunction)tfgetmembers.semantic(0, &sc);
		}
		if (fdx)
			fdx = fdx.overloadExactMatch(tfgetmembers);
}
		if (fdx && fdx.isVirtual()) {
			fdx = null;
		}

		return fdx;
	}
}

    Dsymbol symtabInsert(Dsymbol s)
    {
    	return symtab.insert(s);
    }

    void emitMemberComments(Scope sc)
	{
		assert(false);
	}

version(DMDV2)
{
    static size_t dim(Dsymbols members)
	{
		assert(false);
	}


    static Dsymbol getNth(Dsymbols members, size_t nth, size_t* pn = null)
	{
		assert(false);
	}
}
    override ScopeDsymbol isScopeDsymbol() { return this; }
}
