module dmd.RemoveExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.Loc;
import dmd.IRState;
import dmd.BinExp;
import dmd.TOK;
import dmd.Type;
import dmd.TypeAArray;
import dmd.TY;

import dmd.backend.Util;
import dmd.backend.OPER;
import dmd.backend.Symbol;
import dmd.backend.TYM;
import dmd.backend.mTY;

import dmd.DDMDExtensions;

/* This deletes the key e1 from the associative array e2
 */

class RemoveExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOKremove, RemoveExp.sizeof, e1, e2);
		type = Type.tvoid;
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;
		Type tb = e1.type.toBasetype();
		assert(tb.ty == Taarray);
		TypeAArray taa = cast(TypeAArray)tb;
		elem* ea = e1.toElem(irs);
		elem* ekey = e2.toElem(irs);
		elem* ep;
		elem* keyti;

		if (tybasic(ekey.Ety) == TYstruct || tybasic(ekey.Ety) == TYarray)
		{
			ekey = el_una(OPstrpar, TYstruct, ekey);
			ekey.Enumbytes = ekey.E1.Enumbytes;
			assert(ekey.Enumbytes);
		}

		Symbol* s = taa.aaGetSymbol("Del", 0);
		keyti = taa.index.getInternalTypeInfo(null).toElem(irs);
		ep = el_params(ekey, keyti, ea, null);
		e = el_bin(OPcall, TYnptr, el_var(s), ep);

		el_setLoc(e,loc);
		return e;
	}
}

