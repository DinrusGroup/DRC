module dmd.TypeInfoArrayDeclaration;

import dmd.common;
import dmd.Type;
import dmd.TypeInfoDeclaration;
import dmd.Type;
import dmd.TY;
import dmd.TypeDArray;
import dmd.Global;

import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

class TypeInfoArrayDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		register();
		super(tinfo, 0);
	    type = global.typeinfoarray.type;
	}

	override void toDt(dt_t** pdt)
	{
		//printf("TypeInfoArrayDeclaration::toDt()\n");
		dtxoff(pdt, global.typeinfoarray.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfo_Array
		dtdword(pdt, 0);			    // monitor

		assert(tinfo.ty == Tarray);

		TypeDArray tc = cast(TypeDArray)tinfo;

		tc.next.getTypeInfo(null);
		dtxoff(pdt, tc.next.vtinfo.toSymbol(), 0, TYnptr); // TypeInfo for array of type
	}
}

