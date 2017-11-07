module dmd.TypeInfoStaticArrayDeclaration;

import dmd.common;
import dmd.Type;
import dmd.Global;
import dmd.TypeInfoDeclaration;
import dmd.TypeSArray;
import dmd.TY;

import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.dt_t;

import dmd.DDMDExtensions;

class TypeInfoStaticArrayDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Type tinfo)
	{
		register();
		super(tinfo, 0);
	    type = global.typeinfostaticarray.type;
	}

    override void toDt(dt_t** pdt)
	{
		//printf("TypeInfoStaticArrayDeclaration.toDt()\n");
		dtxoff(pdt, global.typeinfostaticarray.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfo_StaticArray
		dtdword(pdt, 0);			    // monitor

		assert(tinfo.ty == Tsarray);

		TypeSArray tc = cast(TypeSArray)tinfo;

		tc.next.getTypeInfo(null);
		dtxoff(pdt, tc.next.vtinfo.toSymbol(), 0, TYnptr); // TypeInfo for array of type

		dtdword(pdt, cast(int)tc.dim.toInteger());		// length
	}
}
