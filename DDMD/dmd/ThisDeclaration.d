module dmd.ThisDeclaration;

import dmd.common;
import dmd.VarDeclaration;
import dmd.Dsymbol;
import dmd.Loc;
import dmd.Type;
import dmd.Id;

import dmd.DDMDExtensions;

// For the "this" parameter to member functions

class ThisDeclaration : VarDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Type t)
	{
		register();
		super(loc, t, Id.This, null);
		noauto = true;
	}
	
    override Dsymbol syntaxCopy(Dsymbol)
	{
		assert(false);
	}
	
    override ThisDeclaration isThisDeclaration() { return this; }
}
