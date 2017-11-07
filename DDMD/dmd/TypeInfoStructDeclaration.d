module dmd.TypeInfoStructDeclaration;

import dmd.common;
import dmd.Type;
import dmd.TY;
import dmd.MOD;
import dmd.Loc;
import dmd.Parameter;
import dmd.STC;
import dmd.TypeStruct;
import dmd.TypeFunction;
import dmd.StructDeclaration;
import dmd.FuncDeclaration;
import dmd.Dsymbol;
import dmd.ArrayTypes;
import dmd.Scope;
import dmd.LINK;
import dmd.Id;
import dmd.Global;
import dmd.TypeInfoDeclaration;
import dmd.backend.dt_t;
import dmd.backend.TYM;
import dmd.backend.Util;
import dmd.expression.Util;

import std.string : toStringz;

import dmd.DDMDExtensions;

class TypeInfoStructDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		register();
		super(tinfo, 0);
	    type = global.typeinfostruct.type;
	}

	override void toDt(dt_t** pdt)
	{
		//printf("TypeInfoStructDeclaration.toDt() '%s'\n", toChars());

		uint offset = global.typeinfostruct.structsize;

		dtxoff(pdt, global.typeinfostruct.toVtblSymbol(), 0, TYM.TYnptr); // vtbl for TypeInfo_Struct
		dtdword(pdt, 0);			    // monitor

		assert(tinfo.ty == TY.Tstruct);

		TypeStruct tc = cast(TypeStruct)tinfo;
		StructDeclaration sd = tc.sym;

		/* Put out:
		 *	char[] name;
		 *	void[] init;
		 *	hash_t function(in void*) xtoHash;
		 *	bool function(in void*, in void*) xopEquals;
		 *	int function(in void*, in void*) xopCmp;
		 *	string function(const(void)*) xtoString;
		 *	uint m_flags;
		 *  xgetMembers;
		 *	xdtor;
		 *	xpostblit;
		 *
		 *	name[]
		 */

		string name = sd.toPrettyChars();
		size_t namelen = name.length;
		dtdword(pdt, namelen);

		//dtabytes(pdt, TYnptr, 0, namelen + 1, name);
		dtxoff(pdt, toSymbol(), offset, TYM.TYnptr);
		offset += namelen + 1;

		// void[] init;
		dtdword(pdt, sd.structsize);	// init.length
		if (sd.zeroInit)
			dtdword(pdt, 0);		// null for 0 initialization
		else
			dtxoff(pdt, sd.toInitializer(), 0, TYM.TYnptr);	// init.ptr
		FuncDeclaration fd;
		FuncDeclaration fdx;
		TypeFunction tf;
		Type ta;
		Dsymbol s;

		TypeFunction tfeqptr;
		{
			// bool opEqual(const T*) const;
			scope sc = new Scope();
			auto arguments = new Parameters;
		version (STRUCTTHISREF) {
			// arg type is ref const T
			auto arg = new Parameter(STC.STCref, tc.constOf(), null, null);
		} else {
			// arg type is const T*
			auto arg = new Parameter(STC.STCin, tc.pointerTo(), null, null);
		}

	        arguments.push(arg);
	        tfeqptr = new TypeFunction(arguments, Type.tbool, 0, LINK.LINKd);
	        tfeqptr.mod = MODconst;
	        tfeqptr = cast(TypeFunction)tfeqptr.semantic(Loc(0), sc);
        }

        {
	        scope sc = new Scope;
	        auto arguments = new Parameters;
version(STRUCTTHISREF) {
	        // arg type is ref const T
	        auto arg = new Parameter(STC.STCref, tc.constOf(), null, null);
} else {
	    // arg type is const T*
	        auto arg = new Parameter(STC.STCin, tc.pointerTo(), null, null);
}

			arguments.push(arg);
			tfeqptr = new TypeFunction(arguments, Type.tbool, 0, LINK.LINKd);
			tfeqptr.mod = MOD.MODconst;
			tfeqptr = cast(TypeFunction)tfeqptr.semantic(Loc(0), sc);
		}

        TypeFunction tfcmpptr;
		{
			scope Scope sc = new Scope();
			auto arguments = new Parameters;
		version (STRUCTTHISREF) {
			// arg type is ref const T
			auto arg = new Parameter(STC.STCref, tc.constOf(), null, null);
		} else {
			// arg type is const T*
			auto arg = new Parameter(STC.STCin, tc.pointerTo(), null, null);
		}

			arguments.push(arg);
			tfcmpptr = new TypeFunction(arguments, Type.tint32, 0, LINK.LINKd);
			tfcmpptr.mod = MOD.MODconst;
			tfcmpptr = cast(TypeFunction)tfcmpptr.semantic(Loc(0), sc);
		}

		s = search_function(sd, Id.tohash);
		fdx = s ? s.isFuncDeclaration() : null;
		if (fdx)
		{
			fd = fdx.overloadExactMatch(global.tftohash);
			if (fd)
				dtxoff(pdt, fd.toSymbol(), 0, TYM.TYnptr);
			else
				//fdx.error("must be declared as extern (D) uint toHash()");
				dtdword(pdt, 0);
		}
		else
			dtdword(pdt, 0);

		if (sd.eq)
	        dtxoff(pdt, sd.eq.toSymbol(), 0, TYnptr);
		else
			dtdword(pdt, 0);

		s = search_function(sd, Id.cmp);
		fdx = s ? s.isFuncDeclaration() : null;
		if (fdx)
		{
			//printf("test1 %s, %s, %s\n", fdx.toChars(), fdx.type.toChars(), tfeqptr.toChars());
			fd = fdx.overloadExactMatch(tfcmpptr);
			if (fd)
			{
				dtxoff(pdt, fd.toSymbol(), 0, TYM.TYnptr);
				//printf("test2\n");
			}
			else
				//fdx.error("must be declared as extern (D) int %s(%s*)", fdx.toChars(), sd.toChars());
				dtdword(pdt, 0);
		}
		else
			dtdword(pdt, 0);

		s = search_function(sd, Id.tostring);
		fdx = s ? s.isFuncDeclaration() : null;
		if (fdx)
		{
			fd = fdx.overloadExactMatch(global.tftostring);
			if (fd)
				dtxoff(pdt, fd.toSymbol(), 0, TYM.TYnptr);
			else
				//fdx.error("must be declared as extern (D) char[] toString()");
				dtdword(pdt, 0);
		}
		else
			dtdword(pdt, 0);

		// uint m_flags;
		dtdword(pdt, tc.hasPointers());

version (DMDV2) {
		// xgetMembers
		FuncDeclaration sgetmembers = sd.findGetMembers();
		if (sgetmembers)
			dtxoff(pdt, sgetmembers.toSymbol(), 0, TYM.TYnptr);
		else
			dtdword(pdt, 0);			// xgetMembers

		// xdtor
		FuncDeclaration sdtor = sd.dtor;
		if (sdtor)
			dtxoff(pdt, sdtor.toSymbol(), 0, TYM.TYnptr);
		else
			dtdword(pdt, 0);			// xdtor

		// xpostblit
		FuncDeclaration spostblit = sd.postblit;
		if (spostblit)
			dtxoff(pdt, spostblit.toSymbol(), 0, TYM.TYnptr);
		else
			dtdword(pdt, 0);			// xpostblit
}
		// name[]
		dtnbytes(pdt, namelen + 1, toStringz(name));
	}
}

