module dmd.CtorDeclaration;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.ArrayTypes;
import dmd.Loc;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.STC;
import dmd.AggregateDeclaration;
import dmd.TypeFunction;
import dmd.Type;
import dmd.Global;
import dmd.LINK;
import dmd.Expression;
import dmd.ThisExp;
import dmd.Statement;
import dmd.ReturnStatement;
import dmd.CompoundStatement;
import dmd.Parameter;
import dmd.Id;

import dmd.DDMDExtensions;

class CtorDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	Parameters arguments;
    int varargs;

    this(Loc loc, Loc endloc, Parameters arguments, int varargs)
	{
		register();
		super(loc, endloc, Id.ctor, STC.STCundefined, null);
		
		this.arguments = arguments;
		this.varargs = varargs;
		//printf("CtorDeclaration(loc = %s) %s\n", loc.toChars(), toChars());
	}
	
    override Dsymbol syntaxCopy(Dsymbol)
	{
		CtorDeclaration f = new CtorDeclaration(loc, endloc, null, varargs);

		f.outId = outId;
		f.frequire = frequire ? frequire.syntaxCopy() : null;
		f.fensure  = fensure  ? fensure.syntaxCopy()  : null;
		f.fbody    = fbody    ? fbody.syntaxCopy()    : null;
		assert(!fthrows); // deprecated

		f.arguments = Parameter.arraySyntaxCopy(arguments);
		return f;
	}
	
    override void semantic(Scope sc)
	{
		//printf("CtorDeclaration.semantic() %s\n", toChars());
		sc = sc.push();
		sc.stc &= ~STCstatic;		// not a static constructor

		parent = sc.parent;
		Dsymbol parent = toParent2();
	    Type tret;
		AggregateDeclaration ad = parent.isAggregateDeclaration();
		if (!ad || parent.isUnionDeclaration())
		{
			error("constructors are only for class or struct definitions");
			tret = Type.tvoid;
		}
		else
		{	
			tret = ad.handle;
			assert(tret);
		}
	    if (!type)
			type = new TypeFunction(arguments, tret, varargs, LINKd);

version (STRUCTTHISREF) {
		if (ad && ad.isStructDeclaration())
			(cast(TypeFunction)type).isref = true;
}
		if (!originalType)
			originalType = type;

		sc.flags |= SCOPE.SCOPEctor;
		type = type.semantic(loc, sc);
		sc.flags &= ~SCOPE.SCOPEctor;

		// Append:
		//	return this;
		// to the function body
	    if (fbody && semanticRun < PASSsemantic)
		{
			Expression e = new ThisExp(loc);
			Statement s = new ReturnStatement(loc, e);
			fbody = new CompoundStatement(loc, fbody, s);
		}

		FuncDeclaration.semantic(sc);

		sc.pop();

		// See if it's the default constructor
		if (ad && varargs == 0 && Parameter.dim(arguments) == 0)
		{	if (ad.isStructDeclaration())
			error("default constructor not allowed for structs");
		else
			ad.defaultCtor = this;
		}
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

    override string kind()
	{
		return "constructor";
	}
	
    override string toChars()
	{
		return "this";
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
	
    override void toDocBuffer(OutBuffer buf)
	{
		assert(false);
	}

    override CtorDeclaration isCtorDeclaration() { return this; }
}
