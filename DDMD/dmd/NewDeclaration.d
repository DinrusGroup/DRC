module dmd.NewDeclaration;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.Loc;
import dmd.ArrayTypes;
import dmd.Dsymbol;
import dmd.Parameter;
import dmd.ClassDeclaration;
import dmd.Type;
import dmd.TypeFunction;
import dmd.LINK;
import dmd.TY;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.STC;
import dmd.Id;

import dmd.DDMDExtensions;

class NewDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	Parameters arguments;
    int varargs;

    this(Loc loc, Loc endloc, Parameters arguments, int varargs)
	{
		register();
		super(loc, endloc, Id.classNew, STCstatic, null);
		this.arguments = arguments;
		this.varargs = varargs;
	}

    override Dsymbol syntaxCopy(Dsymbol)
	{
		NewDeclaration f;

		f = new NewDeclaration(loc, endloc, null, varargs);

		FuncDeclaration.syntaxCopy(f);

		f.arguments = Parameter.arraySyntaxCopy(arguments);

		return f;
	}

    override void semantic(Scope sc)
	{
		//printf("NewDeclaration.semantic()\n");

		parent = sc.parent;
		Dsymbol parent = toParent();
	    ClassDeclaration cd = parent.isClassDeclaration();
		if (!cd && !parent.isStructDeclaration())
		{
			error("new allocators only are for class or struct definitions");
		}
	    Type tret = Type.tvoid.pointerTo();
		if (!type)
			type = new TypeFunction(arguments, tret, varargs, LINKd);

		type = type.semantic(loc, sc);
		assert(type.ty == Tfunction);

		// Check that there is at least one argument of type size_t
		TypeFunction tf = cast(TypeFunction)type;
		if (Parameter.dim(tf.parameters) < 1)
		{
			error("at least one argument of type size_t expected");
		}
		else
		{
			auto a = Parameter.getNth(tf.parameters, 0);
			if (!a.type.equals(Type.tsize_t))
				error("first argument must be type size_t, not %s", a.type.toChars());
		}

		FuncDeclaration.semantic(sc);
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("new");
		Parameter.argsToCBuffer(buf, hgs, arguments, varargs);
		bodyToCBuffer(buf, hgs);
	}

    override string kind()
	{
		return "allocator";
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

    override NewDeclaration isNewDeclaration() { return this; }
}
