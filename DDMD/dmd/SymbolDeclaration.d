module dmd.SymbolDeclaration;

import dmd.common;
import dmd.Declaration;
import dmd.StructDeclaration;
import dmd.Loc;
import dmd.TOK;
import dmd.STC;
import dmd.Identifier;

import dmd.backend.Symbol;

import core.stdc.string;
import std.stdio;

import dmd.DDMDExtensions;

// This is a shell around a back end symbol

class SymbolDeclaration : Declaration
{
	mixin insertMemberExtension!(typeof(this));

    Symbol* sym;
    StructDeclaration dsym;

    this(Loc loc, Symbol* s, StructDeclaration dsym)
	{
		register();
		int len = strlen(s.Sident.ptr);
		string name = s.Sident.ptr[0..len].idup;

		super(new Identifier(name, TOK.TOKidentifier));
		
		this.loc = loc;
		sym = s;
		this.dsym = dsym;
		storage_class |= STCconst;
	}

    override Symbol* toSymbol()
	{
		return sym;
	}

    // Eliminate need for dynamic_cast
    override SymbolDeclaration isSymbolDeclaration() { return this; }
}
