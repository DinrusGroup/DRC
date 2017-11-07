module dmd.TypeInfoDelegateDeclaration;

import dmd.common;
import dmd.Type;
import dmd.TypeInfoDeclaration;
import dmd.TypeDelegate;
import dmd.TY;
import dmd.Global;

import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

class TypeInfoDelegateDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		register();
		super(tinfo, 0);
	    type = global.typeinfodelegate.type;
	}

	override void toDt(dt_t** pdt)
	{
		//printf("TypeInfoDelegateDeclaration.toDt()\n");
		dtxoff(pdt, global.typeinfodelegate.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfo_Delegate
		dtdword(pdt, 0);			    // monitor

		assert(tinfo.ty == Tdelegate);

		TypeDelegate tc = cast(TypeDelegate)tinfo;

		tc.next.nextOf().getTypeInfo(null);
		dtxoff(pdt, tc.next.nextOf().vtinfo.toSymbol(), 0, TYnptr); // TypeInfo for delegate return value
	}
}

