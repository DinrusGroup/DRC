module dmd.ModuleInfoDeclaration;

import dmd.common;
import dmd.VarDeclaration;
import dmd.Module;
import dmd.Global;
import dmd.OutBuffer;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.Loc;

import dmd.backend.Symbol;

import dmd.DDMDExtensions;

class ModuleInfoDeclaration : VarDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	Module mod;

	this(Module mod)
	{
		register();
		super(Loc(0), global.moduleinfo.type, mod.ident, null);
	}
	
	override Dsymbol syntaxCopy(Dsymbol)
	{
		assert(false);		  // should never be produced by syntax
		return null;
	}
	
	override void semantic(Scope sc)
	{
	}

	void emitComment(Scope *sc)
	{
	}

	override void toJsonBuffer(OutBuffer buf)
	{
	}

	override Symbol* toSymbol()
	{
		assert(false);
	}
}
