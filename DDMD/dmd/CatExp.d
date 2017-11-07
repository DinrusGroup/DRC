module dmd.CatExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.InterState;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.BinExp;
import dmd.TOK;
import dmd.Type;
import dmd.TY;
import dmd.MATCH;
import dmd.ArrayLiteralExp;
import dmd.StringExp;
import dmd.ErrorExp;
import dmd.WANT;
import dmd.Id;
import dmd.GlobalExpressions;

import dmd.backend.elem;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.OPER;
import dmd.backend.RTLSYM;
import dmd.codegen.Util;
import dmd.expression.Cat;

import dmd.DDMDExtensions;

class CatExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();

		super(loc, TOK.TOKcat, CatExp.sizeof, e1, e2);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

		//printf("CatExp.semantic() %s\n", toChars());
		if (!type)
		{
			BinExp.semanticp(sc);
			e = op_overload(sc);
			if (e)
				return e;

			Type tb1 = e1.type.toBasetype();
			Type tb2 = e2.type.toBasetype();


			/* BUG: Should handle things like:
			 *	char c;
			 *	c ~ ' '
			 *	' ' ~ c;
			 */

static if (false) {
			e1.type.print();
			e2.type.print();
}
        	Type tb1next = tb1.nextOf();
	        Type tb2next = tb2.nextOf();
            
			if ((tb1.ty == Tsarray || tb1.ty == Tarray) &&
				e2.implicitConvTo(tb1next) >= MATCHconvert)
			{
				e2 = e2.implicitCastTo(sc, tb1next);
                type = tb1next.arrayOf();
				if (tb2.ty == Tarray)
				{	
					// Make e2 into [e2]
					e2 = new ArrayLiteralExp(e2.loc, e2);
					e2.type = type;
				}
				return this;
			}
			else if ((tb2.ty == Tsarray || tb2.ty == Tarray) &&
				e1.implicitConvTo(tb2next) >= MATCHconvert)
			{
				e1 = e1.implicitCastTo(sc, tb2next);
                type = tb2next.arrayOf();
				if (tb1.ty == Tarray)
				{	
					// Make e1 into [e1]
					e1 = new ArrayLiteralExp(e1.loc, e1);
					e1.type = type;
				}
				return this;
			}

			if ((tb1.ty == Tsarray || tb1.ty == Tarray) &&
				(tb2.ty == Tsarray || tb2.ty == Tarray) &&
	            (tb1next.mod || tb2next.mod) &&
	            (tb1next.mod != tb2next.mod)
			   )
			{
        	    Type t1 = tb1next.mutableOf().constOf().arrayOf();
        	    Type t2 = tb2next.mutableOf().constOf().arrayOf();
				if (e1.op == TOKstring && !(cast(StringExp)e1).committed)
					e1.type = t1;
				else
					e1 = e1.castTo(sc, t1);
				if (e2.op == TOKstring && !(cast(StringExp)e2).committed)
					e2.type = t2;
				else
					e2 = e2.castTo(sc, t2);
			}

			typeCombine(sc);
			type = type.toHeadMutable();

			Type tb = type.toBasetype();
			if (tb.ty == Tsarray)
				type = tb.nextOf().arrayOf();
	        if (type.ty == Tarray && tb1next && tb2next &&
	            tb1next.mod != tb2next.mod)
			{
				type = type.nextOf().toHeadMutable().arrayOf();
			}
static if (false) {
			e1.type.print();
			e2.type.print();
			type.print();
			print();
}
			Type t1 = e1.type.toBasetype();
			Type t2 = e2.type.toBasetype();
			if (e1.op == TOKstring && e2.op == TOKstring)
				e = optimize(WANTvalue);
			else if ((t1.ty == Tarray || t1.ty == Tsarray) &&
				 (t2.ty == Tarray || t2.ty == Tsarray))
			{
				e = this;
			}
			else
			{
				//printf("(%s) ~ (%s)\n", e1.toChars(), e2.toChars());
				error("Can only concatenate arrays, not (%s ~ %s)",
				e1.type.toChars(), e2.type.toChars());
				return new ErrorExp();
			}
			e.type = e.type.semantic(loc, sc);
			return e;
		}
		return this;
	}

	override Expression optimize(int result)
	{
		//printf("CatExp::optimize(%d) %s\n", result, toChars());
		e1 = e1.optimize(result);
		e2 = e2.optimize(result);
		Expression e = Cat(type, e1, e2);
		if (e is EXP_CANT_INTERPRET)
			e = this;

		return e;
	}

	override Expression interpret(InterState istate)
	{
		Expression e;
		Expression e1;
		Expression e2;

version (LOG) {
		printf("CatExp.interpret() %.*s\n", toChars());
}
		e1 = this.e1.interpret(istate);
		if (e1 is EXP_CANT_INTERPRET)
		{
			goto Lcant;
		}
		e2 = this.e2.interpret(istate);
		if (e2 is EXP_CANT_INTERPRET)
			goto Lcant;
		return Cat(type, e1, e2);

	Lcant:
version (LOG) {
		printf("CatExp.interpret() %.*s CANT\n", toChars());
}
		return EXP_CANT_INTERPRET;
	}

	override Identifier opId()
	{
		return Id.cat;
	}

	override Identifier opId_r()
	{
		return Id.cat_r;
	}

	override elem* toElem(IRState* irs)
	{
		elem *e;

static if (false) {
		printf("CatExp::toElem()\n");
		print();
}

		Type tb1 = e1.type.toBasetype();
		Type tb2 = e2.type.toBasetype();
		Type tn;

///static if (false) {
///		if ((tb1.ty == Tarray || tb1.ty == Tsarray) &&
///			(tb2.ty == Tarray || tb2.ty == Tsarray)
///		   )
///}

		Type ta = tb1.nextOf() ? e1.type : e2.type;
		tn = tb1.nextOf() ? tb1.nextOf() : tb2.nextOf();
		{
		if (e1.op == TOKcat)
		{
			elem* ep;
			CatExp ce = this;
			int n = 2;

			ep = eval_Darray(irs, ce.e2);
			do
			{
				n++;
				ce = cast(CatExp)ce.e1;
				ep = el_param(ep, eval_Darray(irs, ce.e2));
			} while (ce.e1.op == TOKcat);

			ep = el_param(ep, eval_Darray(irs, ce.e1));
	static if (true) {
			ep = el_params(
				   ep,
				   el_long(TYint, n),
				   ta.getTypeInfo(null).toElem(irs),
				   null);
			e = el_bin(OPcall, TYdarray, el_var(rtlsym[RTLSYM_ARRAYCATNT]), ep);
	} else {
			ep = el_params(
				   ep,
				   el_long(TYint, n),
				   el_long(TYint, tn.size()),
				   null);
			e = el_bin(OPcall, TYdarray, el_var(rtlsym[RTLSYM_ARRAYCATN]), ep);
	}
		}
		else
		{
			elem *e1;
			elem *e2;
			elem *ep;

			e1 = eval_Darray(irs, this.e1);
			e2 = eval_Darray(irs, this.e2);
	static if (true) {
			ep = el_params(e2, e1, ta.getTypeInfo(null).toElem(irs), null);
			e = el_bin(OPcall, TYdarray, el_var(rtlsym[RTLSYM_ARRAYCATT]), ep);
	} else {
			ep = el_params(el_long(TYint, tn.size()), e2, e1, null);
			e = el_bin(OPcall, TYdarray, el_var(rtlsym[RTLSYM_ARRAYCAT]), ep);
	}
		}
		el_setLoc(e,loc);
		}
///	static if (false) {
///		else if ((tb1.ty == Tarray || tb1.ty == Tsarray) &&
///			e2.type.equals(tb1.next))
///		{
///			error("array cat with element not implemented");
///			e = el_long(TYint, 0);
///		}
///		else
///			assert(0);
///	}
		return e;
	}
}

