module dmd.Import;

import dmd.common;
import dmd.Dsymbol;
import dmd.Array;
import dmd.ArrayTypes;
import dmd.DsymbolTable;
import dmd.PROT;
import dmd.Identifier;
import dmd.Module;
import dmd.Package;
import dmd.Loc;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Scope;
import dmd.TypeIdentifier;
import dmd.AliasDeclaration;
import dmd.ScopeDsymbol;
import dmd.StorageClassDeclaration;
import dmd.STC;
import dmd.ProtDeclaration;
import dmd.Global;

import dmd.DDMDExtensions;

import std.stdio;

void escapePath(OutBuffer buf, string fname)
{
	foreach (char c; fname)
	{
		switch (c)
		{
			case '(':
			case ')':
			case '\\':
				buf.writebyte('\\');
			default:
				buf.writebyte(c);
				break;
		}
	}
}

class Import : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));
	
	Identifiers packages;		// array of Identifier's representing packages
	Identifier id;		// module Identifier
	Identifier aliasId;
	int isstatic;		// !=0 if static import

	// Pairs of alias=name to bind into current namespace
	Array names;
	Array aliases;

	Array aliasdecls;		// AliasDeclarations for names/aliases

	Module mod;
	Package pkg;		// leftmost package/module

	this(Loc loc, Identifiers packages, Identifier id, Identifier aliasId, int isstatic)
	{
		register();
		super(id);
		
		names = new Array();
		aliases = new Array();
		aliasdecls = new Array();
		
		assert(id);
		this.loc = loc;
		this.packages = packages;
		this.id = id;
		this.aliasId = aliasId;
		this.isstatic = isstatic;

		if (aliasId)
			this.ident = aliasId;
		// Kludge to change Import identifier to first package
		else if (packages && packages.dim)
			this.ident = packages[0];
	}
	
	void addAlias(Identifier name, Identifier alias_)
	{
		if (isstatic)
			error("cannot have an import bind list");

		if (!aliasId)
			this.ident = null;	// make it an anonymous import

		names.push(cast(void*)name);
		aliases.push(cast(void*)alias_);
	}

	override string kind()
	{
		return isstatic ? "static import" : "import";
	}
	
	override Dsymbol syntaxCopy(Dsymbol s)	// copy only syntax trees
	{
		assert(false);
	}
	
	void load(Scope sc)
	{
		//writefln("Import::load('%s')", id.toChars());

		// See if existing module
		DsymbolTable dst = Package.resolve(packages, null, &pkg);

		Dsymbol s = dst.lookup(id);
		if (s)
		{
version (TARGET_NET)
{
			mod = cast(Module)s;
}
else
{
			if (s.isModule())
				mod = cast(Module)s;
			else
				error("package and module have the same name");
}
		}
		
		if (!mod)
		{
			// Load module
			mod = Module.load(loc, packages, id);
			dst.insert(id, mod);		// id may be different from mod.ident,
							// if so then insert alias
			if (!mod.importedFrom)
				mod.importedFrom = sc ? sc.module_.importedFrom : global.rootModule;
		}

		if (!pkg)
			pkg = mod;

		//writef("-Import::load('%s'), pkg = %p\n", toChars(), pkg);
	}
	
	override void importAll(Scope sc)
	{
		if (!mod)
		{
		   load(sc);
		   mod.importAll(null);

		   if (!isstatic && !aliasId && !names.dim)
		   {
			   /* Default to private importing
				*/
			   PROT prot = sc.protection;
			   if (!sc.explicitProtection)
				   prot = PROT.PROTprivate;
			   sc.scopesym.importScope(mod, prot);
		   }
		}
	}

	override void semantic(Scope sc)
	{
		//writef("Import.semantic('%s')\n", toChars());

		// Load if not already done so
		if (!mod)
		{
			load(sc);
			mod.importAll(null);
		}
		
		if (mod)
		{
static if (false)
{
			if (mod.loc.linnum != 0)
			{   /* If the line number is not 0, then this is not
				 * a 'root' module, i.e. it was not specified on the command line.
				 */
				mod.importedFrom = sc.module_.importedFrom;
				assert(mod.importedFrom);
			}
}

			// Modules need a list of each imported module
			//printf("%s imports %s\n", sc.module.toChars(), mod.toChars());
			sc.module_.aimports.push(cast(void*)mod);

			if (!isstatic && !aliasId && !names.dim)
			{
				/* Default to private importing
				 */
				PROT prot = sc.protection;
				if (!sc.explicitProtection)
					prot = PROT.PROTprivate;

				sc.scopesym.importScope(mod, prot);
			}

			mod.semantic();

			if (mod.needmoduleinfo)
			{
				// writef("module4 %s because of %s\n", sc.module.toChars(), mod.toChars());
				sc.module_.needmoduleinfo = 1;
			}

			sc = sc.push(mod);
			for (size_t i = 0; i < aliasdecls.dim; i++)
			{
				Dsymbol s = cast(Dsymbol)aliasdecls.data[i];

				//writef("\tImport alias semantic('%s')\n", s.toChars());
				if (!mod.search(loc, cast(Identifier)names.data[i], 0))
				error("%s not found", (cast(Identifier)names.data[i]).toChars());

				s.semantic(sc);
			}
			sc = sc.pop();
		}

		if (global.params.moduleDeps !is null)
		{
		/* The grammar of the file is:
		 *	ImportDeclaration
		 *		.= BasicImportDeclaration [ " : " ImportBindList ] [ " . "
		 *	ModuleAliasIdentifier ] "\n"
		 *
		 *	BasicImportDeclaration
		 *		.= ModuleFullyQualifiedName " (" FilePath ") : " Protection
		 *		" [ " static" ] : " ModuleFullyQualifiedName " (" FilePath ")"
		 *
		 *	FilePath
		 *		- any string with '(', ')' and '\' escaped with the '\' character
		 */

		OutBuffer ob = global.params.moduleDeps;

		ob.writestring(sc.module_.toPrettyChars());
		ob.writestring(" (");
		escapePath(ob, sc.module_.srcfile.toChars());
		ob.writestring(") : ");

		ProtDeclaration.protectionToCBuffer(ob, sc.protection);
		if (isstatic)
			StorageClassDeclaration.stcToCBuffer(ob, STC.STCstatic);
		ob.writestring(": ");

		if (packages)
		{
			foreach (pid; packages)
			{
			ob.printf("%s.", pid.toChars());
			}
		}

		ob.writestring(id.toChars());
		ob.writestring(" (");
		if (mod)
			escapePath(ob, mod.srcfile.toChars());
		else
			ob.writestring("???");
		ob.writebyte(')');

		for (size_t i = 0; i < names.dim; i++)
		{
			if (i == 0)
			ob.writebyte(':');
			else
			ob.writebyte(',');

			Identifier name = cast(Identifier)names.data[i];
			Identifier alias_ = cast(Identifier)aliases.data[i];

			if (!alias_)
			{
				ob.printf("%s", name.toChars());
				alias_ = name;
			}
			else
				ob.printf("%s=%s", alias_.toChars(), name.toChars());
		}

		if (aliasId)
			ob.printf(" . %s", aliasId.toChars());

		ob.writenl();
		}

		//printf("-Import.semantic('%s'), pkg = %p\n", toChars(), pkg);
	}
	
	override void semantic2(Scope sc)
	{
		//printf("Import::semantic2('%s')\n", toChars());
		mod.semantic2();
		if (mod.needmoduleinfo)
		{
			// writef("module5 %s because of %s\n", sc.module.toChars(), mod.toChars());
			sc.module_.needmoduleinfo = 1;
		}
	}
	
	override Dsymbol toAlias()
	{
		if (aliasId)
			return mod;
		return this;
	}
	
	/*****************************
	 * Add import to sd's symbol table.
	 */
	override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
	{
		bool result = false;

		if (names.dim == 0)
			return Dsymbol.addMember(sc, sd, memnum);

		if (aliasId)
			result = Dsymbol.addMember(sc, sd, memnum);

		/* Instead of adding the import to sd's symbol table,
		 * add each of the alias=name pairs
		 */
		for (size_t i = 0; i < names.dim; i++)
		{
			Identifier name = cast(Identifier)names.data[i];
			Identifier alias_ = cast(Identifier)aliases.data[i];

			if (!alias_)
				alias_ = name;

			TypeIdentifier tname = new TypeIdentifier(loc, name);
			AliasDeclaration ad = new AliasDeclaration(loc, alias_, tname);
			result |= ad.addMember(sc, sd, memnum);

			aliasdecls.push(cast(void*)ad);
		}

		return result;
	}
	
	override Dsymbol search(Loc loc, Identifier ident, int flags)
	{
		//printf("%s.Import.search(ident = '%s', flags = x%x)\n", toChars(), ident.toChars(), flags);

		if (!pkg)
		{	
			load(null);
			mod.semantic();
		}

		// Forward it to the package/module
		return pkg.search(loc, ident, flags);
	}
	
	override bool overloadInsert(Dsymbol s)
	{
		// Allow multiple imports of the same name
		return s.isImport() !is null;
	}
	
	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

	override Import isImport() { return this; }
}
