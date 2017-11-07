module dmd.ModExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.backend.elem;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.ArrayTypes;
import dmd.BinExp;
import dmd.TOK;
import dmd.Id;
import dmd.ErrorExp;

import dmd.expression.Util;
import dmd.expression.Mod;
import dmd.backend.RTLSYM;
import dmd.backend.OPER;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class ModExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKmod, ModExp.sizeof, e1, e2);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

		if (type)
			return this;

		BinExp.semanticp(sc);
		e = op_overload(sc);
		if (e)
			return e;

		typeCombine(sc);
		if (!e1.isArrayOperand())
			e1.checkArithmetic();
		if (!e2.isArrayOperand())
			e2.checkArithmetic();

		if (type.isfloating())
		{	
			type = e1.type;
			if (e2.type.iscomplex())
			{   
				error("cannot perform modulo complex arithmetic");
				return new ErrorExp();
			}
		}
		return this;
	}

	override Expression optimize(int result)
	{
		Expression e;

		e1 = e1.optimize(result);
		e2 = e2.optimize(result);
		if (e1.isConst() == 1 && e2.isConst() == 1)
		{
			e = Mod(type, e1, e2);
		}
		else
			e = this;
		return e;
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon(istate, &Mod);
	}

	override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		Exp_buildArrayIdent(buf, arguments, "Mod");
	}

	override Expression buildArrayLoop(Parameters fparams)
	{
		return Exp_buildArrayLoop!(typeof(this))(fparams);
	}

	override Identifier opId()
	{
		return Id.mod;
	}

	override Identifier opId_r()
	{
		return Id.mod_r;
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;
		elem* e1;
		elem* e2;
		tym_t tym;

		tym = type.totym();

		e1 = this.e1.toElem(irs);
		e2 = this.e2.toElem(irs);

	static if (false) { // Now inlined
		if (this.e1.type.isfloating())
		{	
			elem* ep;

			switch (this.e1.type.ty)
			{
				case Tfloat32:
				case Timaginary32:
					e1 = el_una(OPf_d, TYdouble, e1);
					e2 = el_una(OPf_d, TYdouble, e2);
				case Tfloat64:
				case Timaginary64:
					e1 = el_una(OPd_ld, TYldouble, e1);
					e2 = el_una(OPd_ld, TYldouble, e2);
					break;
				case Tfloat80:
				case Timaginary80:
					break;
				default:
					assert(0);
					break;
			}
			ep = el_param(e2,e1);
			e = el_bin(OPcall,tym,el_var(rtlsym[RTLSYM_MODULO]),ep);
		}
		else
		{
			e = el_bin(OPmod,tym,e1,e2);
			el_setLoc(e,loc);
		}
	} else {
		e = el_bin(OPmod,tym,e1,e2);
		el_setLoc(e,loc);
	}
		return e;
	}
}

