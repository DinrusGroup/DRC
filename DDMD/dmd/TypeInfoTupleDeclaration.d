module dmd.TypeInfoTupleDeclaration;

import dmd.common;
import dmd.Type;
import dmd.TypeInfoDeclaration;
import dmd.WANT;
import dmd.TypeTuple;
import dmd.Parameter;
import dmd.Expression;
import dmd.TY;
import dmd.Global;
import dmd.backend.TYM;
import dmd.backend.Symbol;
import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.codegen.Util;

import dmd.DDMDExtensions;

class TypeInfoTupleDeclaration : TypeInfoDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Type tinfo)
	{
		register();
		super(tinfo, 0);
	    type = global.typeinfotypelist.type;
	}

    override void toDt(dt_t **pdt)
	{
		//printf("TypeInfoTupleDeclaration.toDt() %s\n", tinfo.toChars());
		dtxoff(pdt, global.typeinfotypelist.toVtblSymbol(), 0, TYnptr); // vtbl for TypeInfoInterface
		dtdword(pdt, 0);			    // monitor

		assert(tinfo.ty == Ttuple);

		auto tu = cast(TypeTuple)tinfo;

		size_t dim = tu.arguments.dim;
		dtdword(pdt, dim);			    // elements.length

		dt_t* d = null;
		for (size_t i = 0; i < dim; i++)
		{
			auto arg = tu.arguments[i];
			Expression e = arg.type.getTypeInfo(null);
			e = e.optimize(WANTvalue);
			e.toDt(&d);
		}

		Symbol *s;
		s = static_sym();
		s.Sdt = d;
		outdata(s);

		dtxoff(pdt, s, 0, TYnptr);		    // elements.ptr
	}
}
