module dmd.CatAssignExp;

import dmd.common;
import dmd.BinExp;
import dmd.Loc;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.SliceExp;
import dmd.ErrorExp;
import dmd.Identifier;
import dmd.IRState;
import dmd.TOK;
import dmd.TY;
import dmd.Id;
import dmd.Type;
import dmd.backend.elem;
import dmd.backend.RTLSYM;
import dmd.backend.Util;
import dmd.backend.OPER;
import dmd.backend.TYM;
import dmd.backend.mTY;

import dmd.expression.Cat;
import dmd.expression.Util;

import dmd.DDMDExtensions;

class CatAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		register();

		super(loc, TOK.TOKcatass, CatAssignExp.sizeof, e1, e2);
	}
	
    override Expression semantic(Scope sc)
	{
		Expression e;

		BinExp.semantic(sc);
		e2 = resolveProperties(sc, e2);

		e = op_overload(sc);
		if (e)
			return e;

		if (e1.op == TOKslice)
		{	
			SliceExp se = cast(SliceExp)e1;

			if (se.e1.type.toBasetype().ty == Tsarray)
				error("cannot append to static array %s", se.e1.type.toChars());
		}

		e1 = e1.modifiableLvalue(sc, e1);

		Type tb1 = e1.type.toBasetype();
		Type tb2 = e2.type.toBasetype();

		e2.rvalue();

        Type tb1next = tb1.nextOf();

		if ((tb1.ty == Tarray) &&
			(tb2.ty == Tarray || tb2.ty == Tsarray) &&
			(e2.implicitConvTo(e1.type) ||
//version(DMDV2) {
			tb2.nextOf().implicitConvTo(tb1next)
//}
            )

		   )
		{	// Append array
			e2 = e2.castTo(sc, e1.type);
			type = e1.type;
			e = this;
		}
		else if ((tb1.ty == Tarray) &&
			e2.implicitConvTo(tb1next)
		   )
		{	// Append element
			e2 = e2.castTo(sc, tb1next);
			type = e1.type;
			e = this;
		}
        else if (tb1.ty == Tarray &&
	        (tb1next.ty == Tchar || tb1next.ty == Twchar) &&
	        e2.implicitConvTo(Type.tdchar)
           )
        {	// Append dchar to char[] or wchar[]
	        e2 = e2.castTo(sc, Type.tdchar);
	        type = e1.type;
	        e = this;

	        /* Do not allow appending wchar to char[] because if wchar happens
	         * to be a surrogate pair, nothing good can result.
	         */
        }
        else
        {
	        error("cannot append type %s to type %s", tb2.toChars(), tb1.toChars());
	        e = new ErrorExp();
        }
		return e;
	}
	
    override Expression interpret(InterState istate)
	{
    	return interpretAssignCommon(istate, &Cat);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.catass;
	}

    override elem* toElem(IRState* irs)
	{
		//printf("CatAssignExp.toElem('%s')\n", toChars());
		elem* e;
		Type tb1 = e1.type.toBasetype();
		Type tb2 = e2.type.toBasetype();

		if (tb1.ty == Tarray && tb2.ty == Tdchar &&
			(tb1.nextOf().ty == Tchar || tb1.nextOf().ty == Twchar))
		{	// Append dchar to char[] or wchar[]

			auto e1 = this.e1.toElem(irs);
			e1 = el_una(OPaddr, TYnptr, e1);

			auto e2 = this.e2.toElem(irs);

			auto ep = el_params(e2, e1, null);
			int rtl = (tb1.nextOf().ty == Tchar)
				? RTLSYM_ARRAYAPPENDCD
				: RTLSYM_ARRAYAPPENDWD;
			e = el_bin(OPcall, TYdarray, el_var(rtlsym[rtl]), ep);
			el_setLoc(e,loc);
		}
		else if (tb1.ty == Tarray || tb2.ty == Tsarray)
		{
			auto e1 = this.e1.toElem(irs);
			e1 = el_una(OPaddr, TYnptr, e1);

			auto e2 = this.e2.toElem(irs);
		
			if (tybasic(e2.Ety) == TYstruct || tybasic(e2.Ety) == TYarray)
			{
				e2 = el_una(OPstrpar, TYstruct, e2);
				e2.Enumbytes = e2.E1.Enumbytes;
				assert(e2.Enumbytes);
			}

			Type tb1n = tb1.nextOf().toBasetype();
			if ((tb2.ty == Tarray || tb2.ty == Tsarray) &&
				tb1n.equals(tb2.nextOf().toBasetype()))
			{   // Append array
				auto ep = el_params(e2, e1, this.e1.type.getTypeInfo(null).toElem(irs), null);
				e = el_bin(OPcall, TYdarray, el_var(rtlsym[RTLSYM_ARRAYAPPENDT]), ep);
			}
			else
			{   // Append element
				auto ep = el_params(e2, e1, this.e1.type.getTypeInfo(null).toElem(irs), null);
				e = el_bin(OPcall, TYdarray, el_var(rtlsym[RTLSYM_ARRAYAPPENDCT]), ep);
			}
			el_setLoc(e,loc);
		}
		else
			assert(0);

		return e;
	}
}
