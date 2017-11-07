module dmd.DsymbolTable;

import dmd.common;
import dmd.StringTable;
import dmd.Dsymbol;
import dmd.Identifier;
import dmd.StringValue;

import std.stdio;

import dmd.TObject;

import dmd.DDMDExtensions;

class DsymbolTable : TObject
{
	mixin insertMemberExtension!(typeof(this));

    StringTable tab;

    this()
	{
		register();
	}

    // Look up Identifier. Return Dsymbol if found, NULL if not.
    Dsymbol lookup(Identifier ident)
	{
debug {
		assert(ident);
}
		Object* sv = tab.lookup(ident.string_);
		return (sv ? cast(Dsymbol)*sv : null);
	}

    // Insert Dsymbol in table. Return NULL if already there.
    Dsymbol insert(Dsymbol s)
	{
		Identifier ident = s.ident;
debug {
		assert(ident);
}

		return insert(ident, s);
	}

    // Look for Dsymbol in table. If there, return it. If not, insert s and return that.
    Dsymbol update(Dsymbol s)
	{
		assert(false);
	}

    Dsymbol insert(Identifier ident, Dsymbol s)	// when ident and s are not the same
	{
		Object* sv = tab.insert(ident.toChars());
		if (sv is null) {
			return null;		// already in table
		}

		*sv = s;
		return s;
	}
}
