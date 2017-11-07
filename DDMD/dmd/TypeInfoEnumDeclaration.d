module dmd.TypeInfoEnumDeclaration;

import dmd.common;
import dmd.TY;
import dmd.Type;
import dmd.Loc;
import dmd.TypeEnum;
import dmd.Type;
import dmd.Global;
import dmd.EnumDeclaration;
import dmd.TypeInfoDeclaration;
import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.backend.TYM;

import std.string : toStringz;

import dmd.DDMDExtensions;

class TypeInfoEnumDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		register();
		super(tinfo, 0);
	    type = global.typeinfoenum.type;
	}

	override void toDt(dt_t** pdt)
	{
		//printf("TypeInfoEnumDeclaration::toDt()\n");
		dtxoff(pdt, global.typeinfoenum.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfo_Enum
		dtdword(pdt, 0);			    // monitor

		assert(tinfo.ty == Tenum);

		TypeEnum tc = cast(TypeEnum)tinfo;
		EnumDeclaration sd = tc.sym;

		/* Put out:
		 *	TypeInfo base;
		 *	char[] name;
		 *	void[] m_init;
		 */

		if (sd.memtype)
		{
			sd.memtype.getTypeInfo(null);
			dtxoff(pdt, sd.memtype.vtinfo.toSymbol(), 0, TYnptr);	// TypeInfo for enum members
		}
		else
			dtdword(pdt, 0);

		string name = sd.toPrettyChars();
		size_t namelen = name.length;
		dtdword(pdt, namelen);
		dtabytes(pdt, TYnptr, 0, namelen + 1, toStringz(name));

		// void[] init;
		if (!sd.defaultval || tinfo.isZeroInit(Loc(0)))
		{
			// 0 initializer, or the same as the base type
			dtdword(pdt, 0);	// init.length
			dtdword(pdt, 0);	// init.ptr
		}
		else
		{
			dtdword(pdt, cast(int)sd.type.size());	// init.length
			dtxoff(pdt, sd.toInitializer(), 0, TYnptr);	// init.ptr
		}
	}
}

