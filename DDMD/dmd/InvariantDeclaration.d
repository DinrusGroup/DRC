module dmd.InvariantDeclaration;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.Loc;
import dmd.Dsymbol;
import dmd.Id;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.LINK;
import dmd.STC;
import dmd.TypeFunction;
import dmd.Type;
import dmd.AggregateDeclaration;

import dmd.DDMDExtensions;

class InvariantDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Loc endloc)
	{
		register();
		super(loc, endloc, Id.classInvariant, STCundefined, null);
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		InvariantDeclaration id = new InvariantDeclaration(loc, endloc);
		FuncDeclaration.syntaxCopy(id);
		return id;
	}

    override void semantic(Scope sc)
	{
		parent = sc.parent;
		Dsymbol parent = toParent();
		AggregateDeclaration ad = parent.isAggregateDeclaration();
		if (!ad)
		{
			error("invariants are only for struct/union/class definitions");
			return;
		}
	    else if (ad.inv && ad.inv != this && semanticRun < PASSsemantic)
		{
			error("more than one invariant for %s", ad.toChars());
		}
		ad.inv = this;
	    if (!type)
			type = new TypeFunction(null, Type.tvoid, false, LINKd);

		sc = sc.push();
		sc.stc &= ~STCstatic;		// not a static invariant
		sc.incontract++;
		sc.linkage = LINK.LINKd;

		FuncDeclaration.semantic(sc);

		sc.pop();
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
		return false;
	}

    override void emitComment(Scope sc)
	{
		assert(false);
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		if (hgs.hdrgen)
			return;
		buf.writestring("invariant");
		bodyToCBuffer(buf, hgs);
	}

	override void toJsonBuffer(OutBuffer buf)
	{
	}

	override InvariantDeclaration isInvariantDeclaration() { return this; }
}
