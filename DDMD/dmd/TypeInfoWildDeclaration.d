module dmd.TypeInfoWildDeclaration;

import dmd.TY;
import dmd.Type;
import dmd.Global;
import dmd.TypeInfoDeclaration;

import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

class TypeInfoWildDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Type tinfo)
    {
		register();
        super(tinfo, 0);
        type = global.typeinfowild.type;
    }

    override void toDt(dt_t **pdt)
    {
        //printf("TypeInfoWildDeclaration::toDt() %s\n", toChars());
        dtxoff(pdt, global.typeinfowild.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfo_Wild
        dtdword(pdt, 0);			    // monitor
        Type tm = tinfo.mutableOf();
        tm = tm.merge();
        tm.getTypeInfo(null);
        dtxoff(pdt, tm.vtinfo.toSymbol(), 0, TYnptr);
    }
};
