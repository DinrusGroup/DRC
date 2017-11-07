module dmd.TypeInfoConstDeclaration;

import dmd.common;
import dmd.Type;
import dmd.TypeInfoDeclaration;
import dmd.Global;
import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

version(DMDV2)
class TypeInfoConstDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		register();
		super(tinfo, 0);
	    type = global.typeinfoconst.type;
	}

	override void toDt(dt_t** pdt)
	{
		//printf("TypeInfoConstDeclaration.toDt() %s\n", toChars());
		dtxoff(pdt, global.typeinfoconst.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfo_Const
		dtdword(pdt, 0);			    // monitor
		Type tm = tinfo.mutableOf();
		tm = tm.merge();
		tm.getTypeInfo(null);
		dtxoff(pdt, tm.vtinfo.toSymbol(), 0, TYnptr);
	}
}

