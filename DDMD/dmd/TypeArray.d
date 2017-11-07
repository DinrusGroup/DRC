module dmd.TypeArray;

import dmd.common;
import dmd.Type;
import dmd.TypeNext;
import dmd.Id;
import dmd.Loc;
import dmd.ArrayTypes;
import dmd.CallExp;
import dmd.FuncDeclaration;
import dmd.VarExp;
import dmd.Expression;
import dmd.MATCH;
import dmd.Scope;
import dmd.Identifier;
import dmd.TY;
import dmd.IntegerExp;
import dmd.Global;

import dmd.DDMDExtensions;

// Allow implicit conversion of T[] to T*
bool IMPLICIT_ARRAY_TO_PTR()
{
	return global.params.useDeprecated;
}

class TypeArray : TypeNext
{
	mixin insertMemberExtension!(typeof(this));

    this(TY ty, Type next)
	{
		register();
		super(ty, next);
	}

    override Expression dotExp(Scope sc, Expression e, Identifier ident)
	{
		Type n = this.next.toBasetype();		// uncover any typedef's

	version (LOGDOTEXP) {
		printf("TypeArray.dotExp(e = '%s', ident = '%s')\n", e.toChars(), ident.toChars());
	}
		if (ident == Id.reverse && (n.ty == Tchar || n.ty == Twchar))
		{
			Expression ec;
			FuncDeclaration fd;
			Expressions arguments;
			string nm;
			
			enum string[2] name = [ "_adReverseChar", "_adReverseWchar" ];

			nm = name[n.ty == Twchar];
			fd = FuncDeclaration.genCfunc(Type.tindex, nm);
			ec = new VarExp(Loc(0), fd);
			e = e.castTo(sc, n.arrayOf());	// convert to dynamic array
			arguments = new Expressions();
			arguments.push(e);
			e = new CallExp(e.loc, ec, arguments);
			e.type = next.arrayOf();
		}
		else if (ident == Id.sort && (n.ty == Tchar || n.ty == Twchar))
		{
			Expression ec;
			FuncDeclaration fd;
			Expressions arguments;
			string nm;
			
			enum string[2] name2 = [ "_adSortChar", "_adSortWchar" ];

			nm = name2[n.ty == Twchar];
			fd = FuncDeclaration.genCfunc(Type.tindex, nm);
			ec = new VarExp(Loc(0), fd);
			e = e.castTo(sc, n.arrayOf());	// convert to dynamic array
			arguments = new Expressions();
			arguments.push(e);
			e = new CallExp(e.loc, ec, arguments);
			e.type = next.arrayOf();
		}
		else if (ident == Id.reverse || ident == Id.dup || ident == Id.idup)
		{
			Expression ec;
			FuncDeclaration fd;
			Expressions arguments;
			int size = cast(int)next.size(e.loc);
			int dup;

			assert(size);
			dup = (ident == Id.dup || ident == Id.idup);
			fd = FuncDeclaration.genCfunc(Type.tindex, dup ? Id.adDup : Id.adReverse);
			ec = new VarExp(Loc(0), fd);
			e = e.castTo(sc, n.arrayOf());	// convert to dynamic array
			arguments = new Expressions();
			if (dup)
				arguments.push(getTypeInfo(sc));
			arguments.push(e);
			if (!dup)
				arguments.push(new IntegerExp(Loc(0), size, Type.tsize_t));
			e = new CallExp(e.loc, ec, arguments);
			if (ident == Id.idup)
			{   
				Type einv = next.invariantOf();
				if (next.implicitConvTo(einv) < MATCHconst)
					error(e.loc, "cannot implicitly convert element type %s to immutable", next.toChars());
				e.type = einv.arrayOf();
			}
			else
				e.type = next.mutableOf().arrayOf();
		}
		else if (ident == Id.sort)
		{
			Expression ec;
			FuncDeclaration fd;
			Expressions arguments;

			fd = FuncDeclaration.genCfunc(tint32.arrayOf(), "_adSort");
			ec = new VarExp(Loc(0), fd);
			e = e.castTo(sc, n.arrayOf());	// convert to dynamic array
			arguments = new Expressions();
			arguments.push(e);
			arguments.push(n.ty == Tsarray
					? n.getTypeInfo(sc)	// don't convert to dynamic array
					: n.getInternalTypeInfo(sc));
			e = new CallExp(e.loc, ec, arguments);
			e.type = next.arrayOf();
		}
		else
		{
			e = Type.dotExp(sc, e, ident);
		}
        e = e.semantic(sc);
		return e;
	}
}
