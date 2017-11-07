module dmd.EqualExp;

import dmd.common;
import dmd.ErrorExp;
import dmd.Expression;
import dmd.Id;
import dmd.Identifier;
import dmd.InterState;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.BinExp;
import dmd.TOK;
import dmd.Type;
import dmd.AddrExp;
import dmd.VarExp;
import dmd.IntegerExp;
import dmd.TY;
import dmd.Token;
import dmd.NotExp;
import dmd.WANT;
import dmd.GlobalExpressions;

import dmd.backend.elem;
import dmd.backend.OPER;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.RTLSYM;

import dmd.codegen.Util;

import dmd.expression.util.arrayTypeCompatible;
import dmd.expression.Util;
import dmd.expression.Equal;

import dmd.DDMDExtensions;

class EqualExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(TOK op, Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, op, EqualExp.sizeof, e1, e2);
		assert(op == TOK.TOKequal || op == TOK.TOKnotequal);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

		//printf("EqualExp.semantic('%s')\n", toChars());
		if (type)
			return this;

		BinExp.semanticp(sc);

		/* Before checking for operator overloading, check to see if we're
		 * comparing the addresses of two statics. If so, we can just see
		 * if they are the same symbol.
		 */
		if (e1.op == TOK.TOKaddress && e2.op == TOK.TOKaddress)
		{	
			AddrExp ae1 = cast(AddrExp)e1;
			AddrExp ae2 = cast(AddrExp)e2;

			if (ae1.e1.op == TOK.TOKvar && ae2.e1.op == TOK.TOKvar)
			{   
				VarExp ve1 = cast(VarExp)ae1.e1;
				VarExp ve2 = cast(VarExp)ae2.e1;

				if (ve1.var == ve2.var /*|| ve1.var.toSymbol() == ve2.var.toSymbol()*/)
				{
					// They are the same, result is 'true' for ==, 'false' for !=
					e = new IntegerExp(loc, (op == TOK.TOKequal), Type.tboolean);
					return e;
				}
			}
		}

		Type t1 = e1.type.toBasetype();
		Type t2 = e2.type.toBasetype();
		if (t1.ty == TY.Tclass && e2.op == TOK.TOKnull || t2.ty == TY.Tclass && e1.op == TOK.TOKnull)
		{
			error("use '%s' instead of '%s' when comparing with null",
				Token.toChars(op == TOK.TOKequal ? TOK.TOKidentity : TOK.TOKnotidentity),
				Token.toChars(op));
		}

		//if (e2.op != TOKnull)
		{
			e = op_overload(sc);
			if (e)
			{
				if (op == TOK.TOKnotequal)
				{
					e = new NotExp(e.loc, e);
					e = e.semantic(sc);
				}

				return e;
			}
		}

		// Disallow comparing T[]==T and T==T[]
	    if (e1.op == TOKslice && t1.ty == Tarray && e2.implicitConvTo(t1.nextOf()) ||
	        e2.op == TOKslice && t2.ty == Tarray && e1.implicitConvTo(t2.nextOf()))
	    {
			incompatibleTypes();
			return new ErrorExp();
	    }

		e = typeCombine(sc);
		type = Type.tboolean;

		// Special handling for array comparisons
		if (!arrayTypeCompatible(loc, e1.type, e2.type))
		{
			if (e1.type != e2.type && e1.type.isfloating() && e2.type.isfloating())
			{
				// Cast both to complex
				e1 = e1.castTo(sc, Type.tcomplex80);
				e2 = e2.castTo(sc, Type.tcomplex80);
			}
		}

		return e;
	}

	override Expression optimize(int result)
	{
		Expression e;

		//printf("EqualExp::optimize(result = %x) %s\n", result, toChars());
		e1 = e1.optimize(WANTvalue | (result & WANTinterpret));
		e2 = e2.optimize(WANTvalue | (result & WANTinterpret));
		e = this;

		Expression e1 = fromConstInitializer(result, this.e1);
		Expression e2 = fromConstInitializer(result, this.e2);

		e = Equal(op, type, e1, e2);
		if (e is EXP_CANT_INTERPRET)
			e = this;
		return e;
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon2(istate, &Equal);
	}

	override bool isBit()
	{
		return true;
	}

	override bool isCommutative()
	{
		return true;
	}

	override Identifier opId()
	{
		return Id.eq;
	}

	override elem* toElem(IRState* irs)
	{
		//printf("EqualExp::toElem() %s\n", toChars());
		elem* e;
		OPER eop;
		Type t1 = e1.type.toBasetype();
		Type t2 = e2.type.toBasetype();

		switch (op)
		{
			case TOKequal:		eop = OPeqeq;	break;
			case TOKnotequal:	eop = OPne;	break;
			default:
				dump(0);
				assert(0);
		}

		//printf("EqualExp::toElem()\n");
		if (t1.ty == Tstruct)
		{	// Do bit compare of struct's

			auto es1 = e1.toElem(irs);
			auto es2 = e2.toElem(irs);
			es1 = addressElem(es1, t1);
			es2 = addressElem(es2, t2);
			e = el_param(es1, es2);
			auto ecount = el_long(TYint, t1.size());
			e = el_bin(OPmemcmp, TYint, e, ecount);
			e = el_bin(eop, TYint, e, el_long(TYint, 0));
			el_setLoc(e,loc);
		}
///	static if (false) {
///		else if (t1.ty == Tclass && t2.ty == Tclass)
///		{
///			elem *ec1;
///			elem *ec2;
///
///			ec1 = e1.toElem(irs);
///			ec2 = e2.toElem(irs);
///			e = el_bin(OPcall,TYint,el_var(rtlsym[RTLSYM_OBJ_EQ]),el_param(ec1, ec2));
///		}
///	}
		else if ((t1.ty == Tarray || t1.ty == Tsarray) &&
			 (t2.ty == Tarray || t2.ty == Tsarray))
		{
			Type telement = t1.nextOf().toBasetype();

			auto ea1 = e1.toElem(irs);
			ea1 = array_toDarray(t1, ea1);
			auto ea2 = e2.toElem(irs);
			ea2 = array_toDarray(t2, ea2);

		version (DMDV2) {
			auto ep = el_params(telement.arrayOf().getInternalTypeInfo(null).toElem(irs),
				ea2, ea1, null);
			int rtlfunc = RTLSYM_ARRAYEQ2;
		} else {
			auto ep = el_params(telement.getInternalTypeInfo(null).toElem(irs), ea2, ea1, null);
			int rtlfunc = RTLSYM_ARRAYEQ;
		}
			e = el_bin(OPcall, TYint, el_var(rtlsym[rtlfunc]), ep);
			if (op == TOKnotequal)
				e = el_bin(OPxor, TYint, e, el_long(TYint, 1));
			el_setLoc(e,loc);
		}
		else
			e = toElemBin(irs, eop);

		return e;
	}
}

