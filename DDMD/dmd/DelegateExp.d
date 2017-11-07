module dmd.DelegateExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.AggregateDeclaration;
import dmd.UnaExp;
import dmd.TypeDelegate;
import dmd.FuncDeclaration;
import dmd.InterState;
import dmd.MATCH;
import dmd.Type;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.TY;
import dmd.Scope;
import dmd.InlineCostState;
import dmd.IRState;
import dmd.PREC;
import dmd.HdrGenState;
import dmd.TOK;

import dmd.expression.Util;
import dmd.codegen.Util;
import dmd.backend.Util;
import dmd.backend.Symbol;
import dmd.backend.TYM;
import dmd.backend.OPER;

import dmd.DDMDExtensions;

class DelegateExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	FuncDeclaration func;
	bool hasOverloads;

	this(Loc loc, Expression e, FuncDeclaration f, bool hasOverloads = false)
	{
		register();
		super(loc, TOK.TOKdelegate, DelegateExp.sizeof, e);
		this.func = f;
		this.hasOverloads = hasOverloads;
	}

	override Expression semantic(Scope sc)
	{
	version (LOGSEMANTIC) {
		printf("DelegateExp.semantic('%s')\n", toChars());
	}
		if (!type)
		{
			e1 = e1.semantic(sc);
			type = new TypeDelegate(func.type);
			type = type.semantic(loc, sc);
			AggregateDeclaration ad = func.toParent().isAggregateDeclaration();
			if (func.needThis())
				e1 = getRightThis(loc, sc, ad, e1, func);
		}
		return this;
	}
	
    override Expression interpret(InterState istate)
	{
version (LOG) {
		printf("DelegateExp::interpret() %s\n", toChars());
}
		return this;
	}

	override MATCH implicitConvTo(Type t)
	{
	static if (false) {
		printf("DelegateExp.implicitConvTo(this=%s, type=%s, t=%s)\n",
			toChars(), type.toChars(), t.toChars());
	}
		MATCH result;

		result = type.implicitConvTo(t);

		if (result == MATCHnomatch)
		{
			// Look for pointers to functions where the functions are overloaded.
			FuncDeclaration f;

			t = t.toBasetype();
			if (type.ty == Tdelegate && type.nextOf().ty == Tfunction &&
				t.ty == Tdelegate && t.nextOf().ty == Tfunction)
			{
				if (func && func.overloadExactMatch(t.nextOf()))
					result = MATCHexact;
			}
		}
		return result;
	}

	override Expression castTo(Scope sc, Type t)
	{
	static if (false) {
		printf("DelegateExp.castTo(this=%s, type=%s, t=%s)\n",
			toChars(), type.toChars(), t.toChars());
	}
		enum string msg = "cannot form delegate due to covariant return type";

		Expression e = this;
		Type tb = t.toBasetype();
		Type typeb = type.toBasetype();
		if (tb != typeb)
		{
			// Look for delegates to functions where the functions are overloaded.
			FuncDeclaration f;

			if (typeb.ty == Tdelegate && typeb.nextOf().ty == Tfunction &&
				tb.ty == Tdelegate && tb.nextOf().ty == Tfunction)
			{
				if (func)
				{
					f = func.overloadExactMatch(tb.nextOf());
					if (f)
					{   
						int offset;
						if (f.tintro && f.tintro.nextOf().isBaseOf(f.type.nextOf(), &offset) && offset)
							error("%s", msg);
						f.tookAddressOf++;
						e = new DelegateExp(loc, e1, f);
						e.type = t;
						return e;
					}
					if (func.tintro)
						error("%s", msg);
				}
			}
			e = Expression.castTo(sc, t);
		}
		else
		{	
			int offset;

			func.tookAddressOf++;
			if (func.tintro && func.tintro.nextOf().isBaseOf(func.type.nextOf(), &offset) && offset)
				error("%s", msg);
			e = copy();
			e.type = t;
		}
		return e;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writeByte('&');
		if (!func.isNested())
		{
			expToCBuffer(buf, hgs, e1, PREC.PREC_primary);
			buf.writeByte('.');
		}
		buf.writestring(func.toChars());
	}

	override void dump(int indent)
	{
		assert(false);
	}

	override int inlineCost(InlineCostState* ics)
	{
		assert(false);
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;
		elem* ethis;
		elem* ep;
		Symbol* sfunc;
		int directcall = 0;

		//printf("DelegateExp.toElem() '%s'\n", toChars());
		sfunc = func.toSymbol();
		if (func.isNested())
		{
			ep = el_ptr(sfunc);
			ethis = getEthis(loc, irs, func);
		}
		else
		{
			ethis = e1.toElem(irs);
			if (e1.type.ty != Tclass && e1.type.ty != Tpointer)
				ethis = addressElem(ethis, e1.type);

			if (e1.op == TOKsuper)
				directcall = 1;

			if (!func.isThis())
				error("delegates are only for non-static functions");

			if (!func.isVirtual() ||
				directcall ||
				func.isFinal())
			{
				ep = el_ptr(sfunc);
			}
			else
			{
				// Get pointer to function out of virtual table
				assert(ethis);
				ep = el_same(&ethis);
				ep = el_una(OPind, TYnptr, ep);
				uint vindex = func.vtblIndex;

				// Build *(ep + vindex * 4)
				ep = el_bin(OPadd,TYnptr,ep,el_long(TYint, vindex * 4));
				ep = el_una(OPind,TYnptr,ep);
			}

		//	if (func.tintro)
		//	    func.error(loc, "cannot form delegate due to covariant return type");
		}

		if (ethis.Eoper == OPcomma)
		{
			ethis.E2() = el_pair(TYullong, ethis.E2, ep);
			ethis.Ety = TYullong;
			e = ethis;
		}
		else
			e = el_pair(TYullong, ethis, ep);

		el_setLoc(e,loc);

		return e;
	}
}
