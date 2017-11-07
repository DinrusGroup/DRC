module dmd.TypeInfoAssociativeArrayDeclaration;

import dmd.common;
import dmd.Type;
import dmd.Global;
import dmd.TypeAArray;
import dmd.TY;
import dmd.TypeInfoDeclaration;
import dmd.backend.dt_t;
import dmd.backend.TYM;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class TypeInfoAssociativeArrayDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		register();
		super(tinfo, 0);
	    type = global.typeinfoassociativearray.type;
	}

	override void toDt(dt_t** pdt)
	{
		//printf("TypeInfoAssociativeArrayDeclaration.toDt()\n");
		dtxoff(pdt, global.typeinfoassociativearray.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfo_AssociativeArray
		dtdword(pdt, 0);			    // monitor

		assert(tinfo.ty == Taarray);

		TypeAArray tc = cast(TypeAArray)tinfo;

		tc.next.getTypeInfo(null);
		dtxoff(pdt, tc.next.vtinfo.toSymbol(), 0, TYnptr); // TypeInfo for array of type

		tc.index.getTypeInfo(null);
		dtxoff(pdt, tc.index.vtinfo.toSymbol(), 0, TYnptr); // TypeInfo for array of type

		tc.getImpl().type.getTypeInfo(null);
	    dtxoff(pdt, tc.getImpl().type.vtinfo.toSymbol(), 0, TYnptr); // impl
	}
}

