module dmd.CmpExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.backend.elem;
import dmd.InterState;
import dmd.Loc;
import dmd.TOK;
import dmd.Scope;
import dmd.IRState;
import dmd.Type;
import dmd.Id;
import dmd.TY;
import dmd.ErrorExp;
import dmd.IntegerExp;
import dmd.MATCH;
import dmd.BinExp;
import dmd.WANT;
import dmd.GlobalExpressions;

import dmd.expression.Util;
import dmd.codegen.Util;
import dmd.expression.Cmp;

import dmd.backend.Util;
import dmd.backend.RTLSYM;
import dmd.backend.TYM;
import dmd.backend.OPER;
import dmd.backend.rel;

import dmd.DDMDExtensions;

class CmpExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(TOK op, Loc loc, Expression e1, Expression e2)
	{
		register();

		super(loc, op, CmpExp.sizeof, e1, e2);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

	version (LOGSEMANTIC) {
		printf("CmpExp.semantic('%s')\n", toChars());
	}
		if (type)
			return this;

		BinExp.semanticp(sc);

		Type t1 = e1.type.toBasetype();
		Type t2 = e2.type.toBasetype();
		if (t1.ty == Tclass && e2.op == TOKnull ||
			t2.ty == Tclass && e1.op == TOKnull)
		{
			error("do not use null when comparing class types");
		}

		e = op_overload(sc);
		if (e)
		{
			if (!e.type.isscalar() && e.type.equals(e1.type))
			{
				error("recursive opCmp expansion");
				e = new ErrorExp();
			}
			else
			{   
				e = new CmpExp(op, loc, e, new IntegerExp(loc, 0, Type.tint32));
				e = e.semantic(sc);
			}
			return e;
		}

	    // Disallow comparing T[]==T and T==T[]
	    if (e1.op == TOKslice && t1.ty == Tarray && e2.implicitConvTo(t1.nextOf()) ||
	        e2.op == TOKslice && t2.ty == Tarray && e1.implicitConvTo(t2.nextOf()))
	    {
			incompatibleTypes();
			return new ErrorExp();
	    }

		typeCombine(sc);
		type = Type.tboolean;

		// Special handling for array comparisons
		t1 = e1.type.toBasetype();
		t2 = e2.type.toBasetype();
		if ((t1.ty == Tarray || t1.ty == Tsarray || t1.ty == Tpointer) &&
			(t2.ty == Tarray || t2.ty == Tsarray || t2.ty == Tpointer))
		{
			if (t1.nextOf().implicitConvTo(t2.nextOf()) < MATCHconst &&
				t2.nextOf().implicitConvTo(t1.nextOf()) < MATCHconst &&
				(t1.nextOf().ty != Tvoid && t2.nextOf().ty != Tvoid))
				error("array comparison type mismatch, %s vs %s", t1.nextOf().toChars(), t2.nextOf().toChars());
			e = this;
		}
		else if (t1.ty == Tstruct || t2.ty == Tstruct ||
			 (t1.ty == Tclass && t2.ty == Tclass))
		{
			if (t2.ty == Tstruct)
				error("need member function opCmp() for %s %s to compare", t2.toDsymbol(sc).kind(), t2.toChars());
			else
				error("need member function opCmp() for %s %s to compare", t1.toDsymbol(sc).kind(), t1.toChars());
			e = this;
		}
///	static if (true) {
		else if (t1.iscomplex() || t2.iscomplex())
		{
			error("compare not defined for complex operands");
			e = new ErrorExp();
		}
///	}
		else
		{	
			e1.rvalue();
			e2.rvalue();
			e = this;
		}

		//printf("CmpExp: %s, type = %s\n", e.toChars(), e.type.toChars());
		return e;
	}

	override Expression optimize(int result)
	{
		Expression e;

		//printf("CmpExp::optimize() %s\n", toChars());
		e1 = e1.optimize(WANTvalue | (result & WANTinterpret));
		e2 = e2.optimize(WANTvalue | (result & WANTinterpret));

		Expression e1 = fromConstInitializer(result, this.e1);
		Expression e2 = fromConstInitializer(result, this.e2);

		e = Cmp(op, type, e1, e2);
		if (e is EXP_CANT_INTERPRET)
			e = this;
		return e;
	}

	override Expression interpret(InterState istate)
	{
		return interpretCommon2(istate, &Cmp);
	}

	override bool isBit()
	{
		assert(false);
	}

	override bool isCommutative()
	{
		return true;
	}

	override Identifier opId()
	{
		return Id.cmp;
	}

	override elem* toElem(IRState* irs)
	{
		elem *e;
		OPER eop;
		Type t1 = e1.type.toBasetype();
		Type t2 = e2.type.toBasetype();

		switch (op)
		{
		case TOKlt:	eop = OPlt;	break;
		case TOKgt:	eop = OPgt;	break;
		case TOKle:	eop = OPle;	break;
		case TOKge:	eop = OPge;	break;
		case TOKequal:	eop = OPeqeq;	break;
		case TOKnotequal: eop = OPne;	break;

		// NCEG floating point compares
		case TOKunord:	eop = OPunord;	break;
		case TOKlg:	eop = OPlg;	break;
		case TOKleg:	eop = OPleg;	break;
		case TOKule:	eop = OPule;	break;
		case TOKul:	eop = OPul;	break;
		case TOKuge:	eop = OPuge;	break;
		case TOKug:	eop = OPug;	break;
		case TOKue:	eop = OPue;	break;
		default:
			dump(0);
			assert(0);
		}
		if (!t1.isfloating())
		{
		// Convert from floating point compare to equivalent
		// integral compare
		eop = cast(OPER)rel_integral(eop);
		}
		if (cast(int)eop > 1 && t1.ty == Tclass && t2.ty == Tclass)
		{
	static if (true) {
		assert(0);
	} else {
		elem *ec1;
		elem *ec2;

		ec1 = e1.toElem(irs);
		ec2 = e2.toElem(irs);
		e = el_bin(OPcall,TYint,el_var(rtlsym[RTLSYM_OBJ_CMP]),el_param(ec1, ec2));
		e = el_bin(eop, TYint, e, el_long(TYint, 0));
	}
		}
		else if (cast(int)eop > 1 &&
			 (t1.ty == Tarray || t1.ty == Tsarray) &&
			 (t2.ty == Tarray || t2.ty == Tsarray))
		{
			elem* ea1;
			elem* ea2;
			elem* ep;
			Type telement = t1.nextOf().toBasetype();
			int rtlfunc;

			ea1 = e1.toElem(irs);
			ea1 = array_toDarray(t1, ea1);
			ea2 = e2.toElem(irs);
			ea2 = array_toDarray(t2, ea2);

		version (DMDV2) {
			ep = el_params(telement.arrayOf().getInternalTypeInfo(null).toElem(irs),
				ea2, ea1, null);
			rtlfunc = RTLSYM_ARRAYCMP2;
		} else {
			ep = el_params(telement.getInternalTypeInfo(null).toElem(irs), ea2, ea1, null);
			rtlfunc = RTLSYM_ARRAYCMP;
		}
			e = el_bin(OPcall, TYint, el_var(rtlsym[rtlfunc]), ep);
			e = el_bin(eop, TYint, e, el_long(TYint, 0));
			el_setLoc(e,loc);
		}
		else
		{
			if (cast(int)eop <= 1)
			{
				/* The result is determinate, create:
				 *   (e1 , e2) , eop
				 */
				e = toElemBin(irs,OPcomma);
				e = el_bin(OPcomma,e.Ety,e,el_long(e.Ety,cast(int)eop));
			}
			else
				e = toElemBin(irs,eop);
		}
		return e;
	}
}

