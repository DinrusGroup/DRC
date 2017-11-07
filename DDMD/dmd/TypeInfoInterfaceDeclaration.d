module dmd.TypeInfoInterfaceDeclaration;

import dmd.common;
import dmd.Type;
import dmd.TypeInfoDeclaration;
import dmd.ClassInfoDeclaration;
import dmd.TypeClass;
import dmd.TY;
import dmd.Global;
import dmd.TypeInfoClassDeclaration;

import dmd.backend.dt_t;
import dmd.backend.Symbol;
import dmd.backend.Util;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

class TypeInfoInterfaceDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	this(Type tinfo)
	{
		register();
		super(tinfo, 0);
	    type = global.typeinfointerface.type;
	}

	override void toDt(dt_t** pdt)
	{
		//printf("TypeInfoInterfaceDeclaration.toDt() %s\n", tinfo.toChars());
		dtxoff(pdt, global.typeinfointerface.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfoInterface
		dtdword(pdt, 0);			    // monitor

		assert(tinfo.ty == Tclass);

		TypeClass tc = cast(TypeClass)tinfo;
		Symbol *s;

		if (!tc.sym.vclassinfo)
			tc.sym.vclassinfo = new TypeInfoClassDeclaration(tc);
		s = tc.sym.vclassinfo.toSymbol();
		dtxoff(pdt, s, 0, TYnptr);		// ClassInfo for tinfo
	}
}

