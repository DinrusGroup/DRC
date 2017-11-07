module dmd.TypeInfoClassDeclaration;

import dmd.common;
import dmd.Type;
import dmd.TypeInfoDeclaration;
import dmd.ClassInfoDeclaration;
import dmd.TypeClass;
import dmd.Global;
import dmd.TY;
import dmd.Util;
import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.Symbol;

import dmd.DDMDExtensions;

class TypeInfoClassDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		register();
		super(tinfo, 0);
	    type = global.typeinfoclass.type;
	}

	override Symbol* toSymbol()
	{
	    //printf("TypeInfoClassDeclaration::toSymbol(%s), linkage = %d\n", toChars(), linkage);
	    assert(tinfo.ty == TY.Tclass);
	    auto tc = cast(TypeClass)tinfo;
	    return tc.sym.toSymbol();
	}

	override void toDt(dt_t** pdt)
	{
		//printf("TypeInfoClassDeclaration::toDt() %s\n", tinfo->toChars());
        assert(0);
static if(false) {
		dtxoff(pdt, global.typeinfoclass.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfoClass
		dtdword(pdt, 0);			    // monitor

		assert(tinfo.ty == Tclass);

		TypeClass tc = cast(TypeClass)tinfo;

		if (!tc.sym.vclassinfo)
			tc.sym.vclassinfo = new ClassInfoDeclaration(tc.sym);

		Symbol* s = tc.sym.vclassinfo.toSymbol();
		assert(s.Sxtrnnum == 0);

		dtxoff(pdt, s, 0, TYnptr);		// ClassInfo for tinfo
}
	}
}

