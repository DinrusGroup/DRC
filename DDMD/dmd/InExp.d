module dmd.InExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.BinExp;
import dmd.TOK;
import dmd.Type;
import dmd.Id;
import dmd.TY;
import dmd.TypeAArray;

import dmd.expression.util.arrayTypeCompatible;

import dmd.backend.elem;
import dmd.backend.TYM;
import dmd.backend.mTY;
import dmd.backend.OPER;
import dmd.backend.Symbol;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class InExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOKin, InExp.sizeof, e1, e2);
	}

	override Expression semantic(Scope sc)
	{
		if (type)
			return this;

		super.semanticp(sc);

		Expression e = op_overload(sc);
		if (e)
			return e;

		//type = Type.tboolean;
		Type t2b = e2.type.toBasetype();
		if (t2b.ty != TY.Taarray)
		{
			error("rvalue of in expression must be an associative array, not %s", e2.type.toChars());
			type = Type.terror;
		}
		else
		{
			TypeAArray ta = cast(TypeAArray)t2b;

			// Special handling for array keys
			if (!arrayTypeCompatible(e1.loc, e1.type, ta.index))
			{
				// Convert key to type of key
				e1 = e1.implicitCastTo(sc, ta.index);
			}

			// Return type is pointer to value
			type = ta.nextOf().pointerTo();
		}
		return this;
	}

	override bool isBit()
	{
		return false;
	}

	override Identifier opId()
	{
		return Id.opIn;
	}

	override Identifier opId_r()
	{
		return Id.opIn_r;
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;
		elem* key = e1.toElem(irs);
		elem* aa = e2.toElem(irs);
		elem* ep;
		elem* keyti;
		TypeAArray taa = cast(TypeAArray)e2.type.toBasetype();
		

		// set to:
		//	aaIn(aa, keyti, key);

		if (tybasic(key.Ety) == TYstruct)
		{
			key = el_una(OPstrpar, TYstruct, key);
			key.Enumbytes = key.E1.Enumbytes;
			assert(key.Enumbytes);
		}
		else if (tybasic(key.Ety) == TYarray && taa.index.ty == Tsarray)
	    {
			// e2.elem() turns string literals into a TYarray, so the
			// length is lost. Restore it.
			key = el_una(OPstrpar, TYstruct, key);
			assert(e1.type.size() == taa.index.size());
			key.Enumbytes = cast(size_t) taa.index.size();
	    }

		Symbol* s = taa.aaGetSymbol("In", 0);
		keyti = taa.index.getInternalTypeInfo(null).toElem(irs);
		ep = el_params(key, keyti, aa, null);
		e = el_bin(OPcall, type.totym(), el_var(s), ep);

		el_setLoc(e,loc);
		return e;
	}
}

