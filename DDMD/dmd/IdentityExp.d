module dmd.IdentityExp;

import dmd.common;
import dmd.Expression;
import dmd.InterState;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.BinExp;
import dmd.TOK;
import dmd.Type;
import dmd.WANT;
import dmd.TY;
import dmd.GlobalExpressions;
import dmd.expression.Identity;

import dmd.backend.elem;
import dmd.backend.TYM;
import dmd.backend.OPER;
import dmd.backend.Util;
import dmd.codegen.Util;

import dmd.DDMDExtensions;

class IdentityExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(TOK op, Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, op, IdentityExp.sizeof, e1, e2);
	}

	override Expression semantic(Scope sc)
	{
		 if (type)
			return this;

		BinExp.semanticp(sc);
		type = Type.tboolean;
		typeCombine(sc);

		if (e1.type != e2.type && e1.type.isfloating() && e2.type.isfloating())
		{
			// Cast both to complex
			e1 = e1.castTo(sc, Type.tcomplex80);
			e2 = e2.castTo(sc, Type.tcomplex80);
		}

		return this;
	}

	override bool isBit()
	{
		assert(false);
	}

	override Expression optimize(int result)
	{
		//printf("IdentityExp.optimize(result = %d) %s\n", result, toChars());
		e1 = e1.optimize(WANT.WANTvalue | (result & WANT.WANTinterpret));
		e2 = e2.optimize(WANT.WANTvalue | (result & WANT.WANTinterpret));
		Expression e = this;

		if ((this.e1.isConst() && this.e2.isConst()) || (this.e1.op == TOK.TOKnull && this.e2.op == TOK.TOKnull))
		{
			e = Identity(op, type, this.e1, this.e2);
			if (e is EXP_CANT_INTERPRET)
				e = this;
		}

		return e;
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon2(istate, &Identity);
	}

	override elem* toElem(IRState* irs)
	{
		elem *e;
		OPER eop;
		Type t1 = e1.type.toBasetype();
		Type t2 = e2.type.toBasetype();

		switch (op)
		{
			case TOK.TOKidentity:		eop = OPER.OPeqeq;	break;
			case TOK.TOKnotidentity:	eop = OPER.OPne;	break;
			default:
				dump(0);
				assert(0);
		}

		//printf("IdentityExp.toElem() %s\n", toChars());

		if (t1.ty == TY.Tstruct)
		{	
			// Do bit compare of struct's
			elem* es1;
			elem* es2;
			elem* ecount;

			es1 = e1.toElem(irs);
			es1 = addressElem(es1, e1.type);
			//es1 = el_una(OPaddr, TYnptr, es1);
			es2 = e2.toElem(irs);
			es2 = addressElem(es2, e2.type);
			//es2 = el_una(OPaddr, TYnptr, es2);
			e = el_param(es1, es2);
			ecount = el_long(TYM.TYint, t1.size());
			e = el_bin(OPER.OPmemcmp, TYM.TYint, e, ecount);
			e = el_bin(eop, TYM.TYint, e, el_long(TYM.TYint, 0));
			el_setLoc(e,loc);
		}
		else if ((t1.ty == TY.Tarray || t1.ty == TY.Tsarray) && (t2.ty == TY.Tarray || t2.ty == TY.Tsarray))
		{
			elem* ea1;
			elem* ea2;

			ea1 = e1.toElem(irs);
			ea1 = array_toDarray(t1, ea1);
			ea2 = e2.toElem(irs);
			ea2 = array_toDarray(t2, ea2);

			e = el_bin(eop, type.totym(), ea1, ea2);
			el_setLoc(e,loc);
		}
		else
			e = toElemBin(irs, eop);

		return e;
	}
}

