module dmd.ClassInfoDeclaration;

import dmd.common;
import dmd.VarDeclaration;
import dmd.ClassDeclaration;
import dmd.Global;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.Loc;
import dmd.OutBuffer;
import dmd.Id;
import dmd.STC;

import dmd.backend.Symbol;
import dmd.backend.Classsym;
import dmd.backend.FL;
import dmd.backend.SFL;
import dmd.codegen.Util;
import dmd.backend.SC;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class ClassInfoDeclaration : VarDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	ClassDeclaration cd;

	this(ClassDeclaration cd)
	{
		register();

		super(Loc(0), global.classinfo.type, cd.ident, null);
		
		this.cd = cd;
		storage_class = STC.STCstatic | STC.STCgshared;
	}
	
	override Dsymbol syntaxCopy(Dsymbol)
	{
		 assert(false);		// should never be produced by syntax
		 return null;
	}
	
	override void semantic(Scope sc)
	{
	}

	override void emitComment(Scope sc)
	{
	}

	override void toJsonBuffer(OutBuffer buf)
	{
	}
	
	override Symbol* toSymbol()
	{
		return cd.toSymbol();
	}
}
