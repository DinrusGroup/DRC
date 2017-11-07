module dmd.PostBlitDeclaration;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.Global;
import dmd.LINK;
import dmd.LinkDeclaration;
import dmd.Loc;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.StructDeclaration;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.STC;
import dmd.Type;
import dmd.TypeFunction;
import dmd.Id;

import dmd.DDMDExtensions;

version(DMDV2)
class PostBlitDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Loc endloc)
	{
		register();
		super(loc, endloc, Id._postblit, STCundefined, null);
	}
	
	this(Loc loc, Loc endloc, Identifier id)
	{
		register();
		super(loc, loc, id, STCundefined, null);
	}
	
	override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		PostBlitDeclaration dd = new PostBlitDeclaration(loc, endloc, ident);
		return super.syntaxCopy(dd);
	}
	
	override void semantic(Scope sc)
	{
		//writef("PostBlitDeclaration.semantic() %s\n", toChars());
		//writef("ident: %s, %s, %p, %p\n", ident.toChars(), Id.dtor.toChars(), ident, Id.dtor);
	    //writef("stc = x%llx\n", sc.stc);
		parent = sc.parent;
		Dsymbol parent = toParent();
		StructDeclaration ad = parent.isStructDeclaration();
		if (!ad)
		{
			error("post blits are only for struct/union definitions, not %s %s", parent.kind(), parent.toChars());
		}
		else if (ident == Id._postblit && semanticRun < PASSsemantic)
			ad.postblits.push(this);

		if (!type)
			type = new TypeFunction(null, Type.tvoid, false, LINKd);

		sc = sc.push();
		sc.stc &= ~STCstatic;			  // not static
		sc.linkage = LINKd;

		FuncDeclaration.semantic(sc);

		sc.pop();
	}
	
	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("this(this)");
		bodyToCBuffer(buf, hgs);
	}
	
	override void toJsonBuffer(OutBuffer buf)
	{
		// intentionally empty
	}

	override bool isVirtual()
	{
		return false;
	}
	
	override bool addPreInvariant()
	{
		return false;
	}
	
	override bool addPostInvariant()
	{
		return (isThis() && vthis && global.params.useInvariants);
	}
	
	override bool overloadInsert(Dsymbol s)
	{
		return false;	   // cannot overload postblits
	}
	
	override void emitComment(Scope sc)
	{
		// intentionally empty
	}

	override PostBlitDeclaration isPostBlitDeclaration() { return this; }
}