module dmd.DeleteDeclaration;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.ArrayTypes;
import dmd.Loc;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.STC;
import dmd.Id;
import dmd.Parameter;
import dmd.ClassDeclaration;
import dmd.TypeFunction;
import dmd.Type;
import dmd.LINK;
import dmd.TY;

import dmd.DDMDExtensions;

class DeleteDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	Parameters arguments;

    this(Loc loc, Loc endloc, Parameters arguments)
	{
		register();
		super(loc, endloc, Id.classDelete, STCstatic, null);
		this.arguments = arguments;
	}
	
    override Dsymbol syntaxCopy(Dsymbol)
	{
		DeleteDeclaration f;

		f = new DeleteDeclaration(loc, endloc, null);

		FuncDeclaration.syntaxCopy(f);

		f.arguments = Parameter.arraySyntaxCopy(arguments);

		return f;
	}
	
    override void semantic(Scope sc)
	{
		//printf("DeleteDeclaration.semantic()\n");

		parent = sc.parent;
		Dsymbol parent = toParent();
	    ClassDeclaration cd = parent.isClassDeclaration();
		if (!cd && !parent.isStructDeclaration())
		{
			error("new allocators only are for class or struct definitions");
		}
	    if (!type)
			type = new TypeFunction(arguments, Type.tvoid, 0, LINKd);

		type = type.semantic(loc, sc);
		assert(type.ty == Tfunction);

		// Check that there is only one argument of type void*
		TypeFunction tf = cast(TypeFunction)type;
		if (Parameter.dim(tf.parameters) != 1)
		{
			error("one argument of type void* expected");
		}
		else
		{
			auto a = Parameter.getNth(tf.parameters, 0);
			if (!a.type.equals(Type.tvoid.pointerTo()))
				error("one argument of type void* expected, not %s", a.type.toChars());
		}

		FuncDeclaration.semantic(sc);
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("delete");
		Parameter.argsToCBuffer(buf, hgs, arguments, 0);
		bodyToCBuffer(buf, hgs);
	}
	
    override string kind()
	{
		return "deallocator";
	}

    override bool isDelete()
	{
		return true;
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
	
version (_DH) {
    DeleteDeclaration isDeleteDeclaration() { return this; }
}
}
