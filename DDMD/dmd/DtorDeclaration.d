module dmd.DtorDeclaration;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.Loc;
import dmd.Global;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.LINK;
import dmd.AggregateDeclaration;
import dmd.TypeFunction;
import dmd.Type;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.STC;
import dmd.Id;

import dmd.DDMDExtensions;

class DtorDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Loc endloc)
	{
		register();
		super(loc, endloc, Id.dtor, STCundefined, null);
	}

	this(Loc loc, Loc endloc, Identifier id)
	{
		register();
		super(loc, endloc, id, STCundefined, null);
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		DtorDeclaration dd = new DtorDeclaration(loc, endloc, ident);
		return super.syntaxCopy(dd);
	}
	
	override void semantic(Scope sc)
	{
		//printf("DtorDeclaration::semantic() %s\n", toChars());
		//printf("ident: %s, %s, %p, %p\n", ident.toChars(), Id::dtor.toChars(), ident, Id::dtor);
		parent = sc.parent;
		Dsymbol parent = toParent();
		AggregateDeclaration ad = parent.isAggregateDeclaration();
		if (!ad)
		{
			error("destructors are only for class/struct/union definitions, not %s %s", parent.kind(), parent.toChars());
		}
	    else if (ident == Id.dtor && semanticRun < PASSsemantic)
			ad.dtors.push(this);

	    if (!type)
			type = new TypeFunction(null, Type.tvoid, false, LINK.LINKd);

		sc = sc.push();
		sc.stc &= ~STCstatic;		// not a static destructor
		sc.linkage = LINK.LINKd;

		super.semantic(sc);

		sc.pop();
	}
	
	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("~this()");
		bodyToCBuffer(buf, hgs);
	}
	
	override void toJsonBuffer(OutBuffer buf)
	{
		// intentionally empty
	}
	
	override string kind()
	{
		return "destructor";
	}
	
	override string toChars()
	{
		return "~this";
	}
	
	override bool isVirtual()
	{
		/* This should be FALSE so that dtor's don't get put into the vtbl[],
		 * but doing so will require recompiling everything.
		 */
	version (BREAKABI) {
		return false;
	} else {
		return super.isVirtual();
	}
	}
	
	override bool addPreInvariant()
	{
		return (isThis() && vthis && global.params.useInvariants);
	}
	
	override bool addPostInvariant()
	{
		return false;
	}
	
	override bool overloadInsert(Dsymbol s)
	{
		return false;	   // cannot overload destructors
	}
	
	override void emitComment(Scope sc)
	{
		// intentionally empty
	}

	override DtorDeclaration isDtorDeclaration() { return this; }
}
