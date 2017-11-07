module dmd.TypeInfoTypedefDeclaration;

import dmd.common;
import dmd.Type;
import dmd.TypeInfoDeclaration;
import dmd.TypedefDeclaration;
import dmd.TypeTypedef;
import dmd.TY;
import dmd.Global;
import dmd.Loc;
import dmd.backend.dt_t;
import dmd.backend.TYM;
import dmd.backend.Util;

import std.string;

import dmd.DDMDExtensions;

class TypeInfoTypedefDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		register();
		super(tinfo, 0);
	    type = global.typeinfotypedef.type;
	}

	override void toDt(dt_t** pdt)
	{
		//printf("TypeInfoTypedefDeclaration.toDt() %s\n", toChars());

		dtxoff(pdt, global.typeinfotypedef.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfo_Typedef
		dtdword(pdt, 0);			    // monitor

		assert(tinfo.ty == Ttypedef);

		TypeTypedef tc = cast(TypeTypedef)tinfo;
		TypedefDeclaration sd = tc.sym;
		//printf("basetype = %s\n", sd.basetype.toChars());

		/* Put out:
		 *	TypeInfo base;
		 *	char[] name;
		 *	void[] m_init;
		 */

		sd.basetype = sd.basetype.merge();
		sd.basetype.getTypeInfo(null);		// generate vtinfo
		assert(sd.basetype.vtinfo);
		dtxoff(pdt, sd.basetype.vtinfo.toSymbol(), 0, TYnptr);	// TypeInfo for basetype

		string name = sd.toPrettyChars();
		size_t namelen = name.length;
		dtdword(pdt, namelen);
		dtabytes(pdt, TYnptr, 0, namelen + 1, toStringz(name));

		// void[] init;
		if (tinfo.isZeroInit(Loc(0)) || !sd.init)
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

