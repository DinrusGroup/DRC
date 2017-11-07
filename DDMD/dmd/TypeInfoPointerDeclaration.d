module dmd.TypeInfoPointerDeclaration;

import dmd.common;
import dmd.Type;
import dmd.TypeInfoDeclaration;
import dmd.TypePointer;
import dmd.TY;
import dmd.Global;
import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

class TypeInfoPointerDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		register();
		super(tinfo, 0);
	    type = global.typeinfopointer.type;
	}

	override void toDt(dt_t** pdt)
	{
		//printf("TypeInfoPointerDeclaration::toDt()\n");
		dtxoff(pdt, global.typeinfopointer.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfo_Pointer
		dtdword(pdt, 0);			    // monitor

		assert(tinfo.ty == Tpointer);

		TypePointer tc = cast(TypePointer)tinfo;

		tc.next.getTypeInfo(null);
		dtxoff(pdt, tc.next.vtinfo.toSymbol(), 0, TYnptr); // TypeInfo for type being pointed to
	}
}

