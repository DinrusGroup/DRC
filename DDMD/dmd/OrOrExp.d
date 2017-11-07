module dmd.OrOrExp;

import dmd.common;
import dmd.BinExp;
import dmd.Scope;
import dmd.InterState;
import dmd.TOK;
import dmd.Expression;
import dmd.Loc;
import dmd.IRState;
import dmd.TY;
import dmd.WANT;
import dmd.IntegerExp;
import dmd.Type;
import dmd.CommaExp;
import dmd.Global;
import dmd.BoolExp;

import dmd.expression.Util;

import dmd.backend.elem;
import dmd.backend.OPER;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class OrOrExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKoror, OrOrExp.sizeof, e1, e2);
	}
	
    override Expression semantic(Scope sc)
	{
		uint cs1;

		// same as for AndAnd
		e1 = e1.semantic(sc);
		e1 = resolveProperties(sc, e1);
		e1 = e1.checkToPointer();
		e1 = e1.checkToBoolean();
		cs1 = sc.callSuper;

		if (sc.flags & SCOPE.SCOPEstaticif)
		{
			/* If in static if, don't evaluate e2 if we don't have to.
			 */
			e1 = e1.optimize(WANTflags);
			if (e1.isBool(true))
			{
				return new IntegerExp(loc, 1, Type.tboolean);
			}
		}

		e2 = e2.semantic(sc);
		sc.mergeCallSuper(loc, cs1);
		e2 = resolveProperties(sc, e2);
		e2 = e2.checkToPointer();

		type = Type.tboolean;
		if (e2.type.ty == Tvoid)
			type = Type.tvoid;
		if (e2.op == TOKtype || e2.op == TOKimport)
			error("%s is not an expression", e2.toChars());
		return this;
	}

    override Expression checkToBoolean()
	{
		e2 = e2.checkToBoolean();
		return this;
	}
	
    override bool isBit()
	{
		assert(false);
	}
	
    override Expression optimize(int result)
	{
		Expression e;

		e1 = e1.optimize(WANTflags | (result & WANTinterpret));
		e = this;
		if (e1.isBool(true))
		{	
			// Replace with (e1, 1)
			e = new CommaExp(loc, e1, new IntegerExp(loc, 1, type));
			e.type = type;
			e = e.optimize(result);
		}
		else
		{
			e2 = e2.optimize(WANTflags | (result & WANTinterpret));
			if (result && e2.type.toBasetype().ty == Tvoid && !global.errors)
				error("void has no value");
			if (e1.isConst())
			{
				if (e2.isConst())
				{	
					int n1 = e1.isBool(1);
					int n2 = e2.isBool(1);

					e = new IntegerExp(loc, n1 || n2, type);
				}
				else if (e1.isBool(false))
					e = new BoolExp(loc, e2, type);
			}
		}
		return e;
	}
	
    override Expression interpret(InterState istate)
	{
		assert(false);
	}

    override bool checkSideEffect(int flag)
	{
		if (flag == 2)
		{
			return e1.checkSideEffect(2) || e2.checkSideEffect(2);
		}
		else
		{	
			e1.checkSideEffect(1);
			return e2.checkSideEffect(flag);
		}
	}

    override elem* toElem(IRState* irs)
	{
		elem* e = toElemBin(irs,OPoror);
		if (global.params.cov && e2.loc.linnum)
			e.E2() = el_combine(incUsageElem(irs, e2.loc), e.E2);
		return e;
	}
}
