module dmd.FuncAliasDeclaration;

import dmd.common;
import dmd.FuncDeclaration;

import dmd.backend.Symbol;
import dmd.backend.Symbol;

import dmd.Loc;
import dmd.STC;

import dmd.DDMDExtensions;

class FuncAliasDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    FuncDeclaration funcalias;

    this(FuncDeclaration funcalias)
	{
		register();
		super(funcalias.loc, funcalias.endloc, funcalias.ident, funcalias.storage_class, funcalias.type);
		assert(funcalias !is this);
		this.funcalias = funcalias;
	}

    override FuncAliasDeclaration isFuncAliasDeclaration() { return this; }
	
    override string kind()
	{
		return "function alias";
	}
	
    override Symbol* toSymbol()
	{
		assert(false);
	}
}
