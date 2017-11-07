module dmd.TypeInfoFunctionDeclaration;

import dmd.common;
import dmd.Type;
import dmd.Global;
import dmd.TypeInfoDeclaration;
import dmd.TypeFunction;
import dmd.TY;

import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

class TypeInfoFunctionDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		register();
		super(tinfo, 0);
        type = global.typeinfofunction.type;
	}

	override void toDt(dt_t** pdt)
	{
		//printf("TypeInfoFunctionDeclaration.toDt()\n");
		dtxoff(pdt, global.typeinfofunction.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfo_Function
		dtdword(pdt, 0);			    // monitor

		assert(tinfo.ty == Tfunction);

		TypeFunction tc = cast(TypeFunction)tinfo;

		tc.next.getTypeInfo(null);
		dtxoff(pdt, tc.next.vtinfo.toSymbol(), 0, TYnptr); // TypeInfo for function return value
	}
}

