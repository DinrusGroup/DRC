module dmd.TypeInfoInvariantDeclaration;

import dmd.common;
import dmd.Type;
import dmd.Global;
import dmd.TypeInfoDeclaration;
import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

version(DMDV2)
class TypeInfoInvariantDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		register();
		super(tinfo, 0);
	    type = global.typeinfoinvariant.type;
	}

	override void toDt(dt_t** pdt)
	{
		//printf("TypeInfoInvariantDeclaration.toDt() %s\n", toChars());
		dtxoff(pdt, global.typeinfoinvariant.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfo_Invariant
		dtdword(pdt, 0);			    // monitor
		Type tm = tinfo.mutableOf();
		tm = tm.merge();
		tm.getTypeInfo(null);
		dtxoff(pdt, tm.vtinfo.toSymbol(), 0, TYnptr);
	}
}

