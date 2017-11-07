module dmd.BinExp;

import dmd.common;
import dmd.SliceExp;
import dmd.IndexExp;
import dmd.StructDeclaration;
import dmd.expression.ArrayLength;
import dmd.expression.Equal;
import dmd.expression.Index;
import dmd.ArrayLiteralExp;
import dmd.AssocArrayLiteralExp;
import dmd.StringExp;
import dmd.TypeSArray;
import dmd.PtrExp;
import dmd.SymOffExp;
import dmd.Declaration;
import dmd.StructLiteralExp;
import dmd.Expression;
import dmd.interpret.Util;
import dmd.GlobalExpressions;
import dmd.Global;
import dmd.Cast;
import dmd.CastExp;
import dmd.VarDeclaration;
import dmd.DotVarExp;
import dmd.Loc;
import dmd.ClassDeclaration;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.IRState;
import dmd.Scope;
import dmd.Type;
import dmd.InterState;
import dmd.InlineCostState;
import dmd.InlineScanState;
import dmd.InlineDoState;
import dmd.AggregateDeclaration;
import dmd.Identifier;
import dmd.MATCH;
import dmd.declaration.Match;
import dmd.ArrayTypes;
import dmd.TY;
import dmd.TypeClass;
import dmd.TypeStruct;
import dmd.Dsymbol;
import dmd.FuncDeclaration;
import dmd.TemplateDeclaration;
import dmd.DotIdExp;
import dmd.ErrorExp;
import dmd.WANT;
import dmd.IntegerExp;
import dmd.MulExp;
import dmd.Token;
import dmd.PREC;
import dmd.StringValue;
import dmd.StringTable;
import dmd.Parameter;
import dmd.Statement;
import dmd.ForeachRangeStatement;
import dmd.ArrayLengthExp;
import dmd.IdentifierExp;
import dmd.ExpStatement;
import dmd.CompoundStatement;
import dmd.TypeFunction;
import dmd.LINK;
import dmd.Lexer;
import dmd.ReturnStatement;
import dmd.Id;
import dmd.STC;
import dmd.PROT;
import dmd.VarExp;
import dmd.CallExp;

import dmd.expression.Util;

import dmd.backend.elem;
import dmd.backend.Util;

import dmd.backend.iasm : binary;

import std.exception : assumeUnique;
import core.stdc.stdlib : calloc;
import std.stdio : writef;

import dmd.DDMDExtensions;

/**************************************
 * Combine types.
 * Output:
 *	*pt	merged type, if *pt is not null
 *	*pe1	rewritten e1
 *	*pe2	rewritten e2
 * Returns:
 *	!=0	success
 *	0	failed
 */

/**************************************
 * Hash table of array op functions already generated or known about.
 */

int typeMerge(Scope sc, Expression e, Type* pt, Expression* pe1, Expression* pe2)
{
    //printf("typeMerge() %.*s op %.*s\n", (*pe1).toChars(), (*pe2).toChars());
    //dump(0);

    Expression e1 = (*pe1).integralPromotions(sc);
    Expression e2 = (*pe2).integralPromotions(sc);

    Type t1 = e1.type;
    Type t2 = e2.type;
    assert(t1);
    Type t = t1;

    //if (t1) printf("\tt1 = %s\n", t1.toChars());
    //if (t2) printf("\tt2 = %s\n", t2.toChars());
debug {
    if (!t2) writef("\te2 = '%s'\n", e2.toChars());
}
    assert(t2);

    Type t1b = t1.toBasetype();
    Type t2b = t2.toBasetype();

    TY ty = cast(TY)Type.impcnvResult[t1b.ty][t2b.ty];
    if (ty != TY.Terror)
    {
		auto ty1 = cast(TY)Type.impcnvType1[t1b.ty][t2b.ty];
		auto ty2 = cast(TY)Type.impcnvType2[t1b.ty][t2b.ty];

		if (t1b.ty == ty1)	// if no promotions
		{
			if (t1 == t2)
			{
				t = t1;
				goto Lret;
			}

			if (t1b == t2b)
			{
				t = t1b;
				goto Lret;
			}
		}

		t = Type.basic[ty];

		t1 = Type.basic[ty1];
		t2 = Type.basic[ty2];

		e1 = e1.castTo(sc, t1);
		e2 = e2.castTo(sc, t2);
		//printf("after typeCombine():\n");
		//dump(0);
		//printf("ty = %d, ty1 = %d, ty2 = %d\n", ty, ty1, ty2);
		goto Lret;
    }

    t1 = t1b;
    t2 = t2b;

Lagain:
    if (t1 == t2)
    {
    }
    else if (t1.ty == TY.Tpointer && t2.ty == TY.Tpointer)
    {
		// Bring pointers to compatible type
		Type t1n = t1.nextOf();
		Type t2n = t2.nextOf();

		if (t1n == t2n) {
			//;
		} else if (t1n.ty == TY.Tvoid)	{// pointers to void are always compatible
			t = t2;
		} else if (t2n.ty == TY.Tvoid) {
			//;
		} else if (t1n.mod != t2n.mod) {
			t1 = t1n.mutableOf().constOf().pointerTo();
			t2 = t2n.mutableOf().constOf().pointerTo();
			t = t1;
			goto Lagain;
		} else if (t1n.ty == TY.Tclass && t2n.ty == TY.Tclass) {
			ClassDeclaration cd1 = t1n.isClassHandle();
			ClassDeclaration cd2 = t2n.isClassHandle();
			int offset;

			if (cd1.isBaseOf(cd2, &offset))
			{
			if (offset)
				e2 = e2.castTo(sc, t);
			}
			else if (cd2.isBaseOf(cd1, &offset))
			{
			t = t2;
			if (offset)
				e1 = e1.castTo(sc, t);
			}
			else
			goto Lincompatible;
		} else {
			goto Lincompatible;
		}
    }
    else if ((t1.ty == TY.Tsarray || t1.ty == TY.Tarray) &&
	     (e2.op == TOK.TOKnull && t2.ty == TY.Tpointer && t2.nextOf().ty == TY.Tvoid ||
	      e2.op == TOK.TOKarrayliteral && t2.ty == TY.Tsarray && t2.nextOf().ty == TY.Tvoid && (cast(TypeSArray)t2).dim.toInteger() == 0)
	    )
    {	/*  (T[n] op void*)   => T[]
	 *  (T[]  op void*)   => T[]
	 *  (T[n] op void[0]) => T[]
	 *  (T[]  op void[0]) => T[]
	 */
		goto Lx1;
    }
    else if ((t2.ty == TY.Tsarray || t2.ty == TY.Tarray) &&
	     (e1.op == TOK.TOKnull && t1.ty == TY.Tpointer && t1.nextOf().ty == TY.Tvoid ||
	      e1.op == TOK.TOKarrayliteral && t1.ty == TY.Tsarray && t1.nextOf().ty == TY.Tvoid && (cast(TypeSArray)t1).dim.toInteger() == 0)
	    )
    {	/*  (void*   op T[n]) => T[]
	 *  (void*   op T[])  => T[]
	 *  (void[0] op T[n]) => T[]
	 *  (void[0] op T[])  => T[]
		 */
		goto Lx2;
    }
    else if ((t1.ty == TY.Tsarray || t1.ty == TY.Tarray) && t1.implicitConvTo(t2))
    {
		goto Lt2;
    }
    else if ((t2.ty == TY.Tsarray || t2.ty == TY.Tarray) && t2.implicitConvTo(t1))
    {
		goto Lt1;
    }
    /* If one is mutable and the other invariant, then retry
     * with both of them as const
     */
    else if ((t1.ty == TY.Tsarray || t1.ty == TY.Tarray || t1.ty == TY.Tpointer) &&
	     (t2.ty == TY.Tsarray || t2.ty == TY.Tarray || t2.ty == TY.Tpointer) &&
	     t1.nextOf().mod != t2.nextOf().mod
	    )
    {
		if (t1.ty == TY.Tpointer)
			t1 = t1.nextOf().mutableOf().constOf().pointerTo();
		else
			t1 = t1.nextOf().mutableOf().constOf().arrayOf();

		if (t2.ty == TY.Tpointer)
			t2 = t2.nextOf().mutableOf().constOf().pointerTo();
		else
			t2 = t2.nextOf().mutableOf().constOf().arrayOf();
		t = t1;
		goto Lagain;
    }
    else if (t1.ty == TY.Tclass || t2.ty == TY.Tclass)
    {
		while (1)
		{
			int i1 = e2.implicitConvTo(t1);
			int i2 = e1.implicitConvTo(t2);

			if (i1 && i2)
			{
			// We have the case of class vs. void*, so pick class
			if (t1.ty == TY.Tpointer)
				i1 = 0;
			else if (t2.ty == TY.Tpointer)
				i2 = 0;
			}

			if (i2)
			{
				goto Lt2;
			}
			else if (i1)
			{
				goto Lt1;
			}
			else if (t1.ty == TY.Tclass && t2.ty == TY.Tclass)
			{
				TypeClass tc1 = cast(TypeClass)t1;
				TypeClass tc2 = cast(TypeClass)t2;

				/* Pick 'tightest' type
				 */
				ClassDeclaration cd1 = tc1.sym.baseClass;
				ClassDeclaration cd2 = tc2.sym.baseClass;

				if (cd1 && cd2)
				{   t1 = cd1.type;
					t2 = cd2.type;
				}
				else if (cd1)
					t1 = cd1.type;
				else if (cd2)
					t2 = cd2.type;
				else
					goto Lincompatible;
			}
			else
				goto Lincompatible;
		}
    }
    else if (t1.ty == TY.Tstruct && t2.ty == TY.Tstruct)
    {
		if ((cast(TypeStruct)t1).sym != (cast(TypeStruct)t2).sym)
			goto Lincompatible;
    }
    else if ((e1.op == TOK.TOKstring || e1.op == TOK.TOKnull) && e1.implicitConvTo(t2))
    {
		goto Lt2;
    }
    else if ((e2.op == TOK.TOKstring || e2.op == TOK.TOKnull) && e2.implicitConvTo(t1))
    {
		goto Lt1;
    }
    else if (t1.ty == TY.Tsarray && t2.ty == TY.Tsarray &&
	     e2.implicitConvTo(t1.nextOf().arrayOf()))
    {
     Lx1:
		t = t1.nextOf().arrayOf();	// T[]
		e1 = e1.castTo(sc, t);
		e2 = e2.castTo(sc, t);
    }
    else if (t1.ty == TY.Tsarray && t2.ty == TY.Tsarray &&
	     e1.implicitConvTo(t2.nextOf().arrayOf()))
    {
     Lx2:
		t = t2.nextOf().arrayOf();
		e1 = e1.castTo(sc, t);
		e2 = e2.castTo(sc, t);
    }
    else if (t1.isintegral() && t2.isintegral())
    {
		assert(0);
    }
    else if (e1.isArrayOperand() && t1.ty == TY.Tarray &&
	     e2.implicitConvTo(t1.nextOf()))
    {	// T[] op T
		e2 = e2.castTo(sc, t1.nextOf());
		t = t1.nextOf().arrayOf();
    }
    else if (e2.isArrayOperand() && t2.ty == TY.Tarray &&
	     e1.implicitConvTo(t2.nextOf()))
    {	// T op T[]
		e1 = e1.castTo(sc, t2.nextOf());
		t = t2.nextOf().arrayOf();

		//printf("test %s\n", e.toChars());
		e1 = e1.optimize(WANT.WANTvalue);
		if (e && e.isCommutative() && e1.isConst())
		{   /* Swap operands to minimize number of functions generated
			 */
			//printf("swap %s\n", e.toChars());
			Expression tmp = e1;
			e1 = e2;
			e2 = tmp;
		}
    }
    else
    {
     Lincompatible:
		return 0;
    }
Lret:
    if (!*pt)
	*pt = t;
    *pe1 = e1;
    *pe2 = e2;
static if (false) {
    printf("-typeMerge() %s op %s\n", e1.toChars(), e2.toChars());
    if (e1.type) printf("\tt1 = %s\n", e1.type.toChars());
    if (e2.type) printf("\tt2 = %s\n", e2.type.toChars());
    printf("\ttype = %s\n", t.toChars());
}
    //dump(0);
    return 1;


Lt1:
    e2 = e2.castTo(sc, t1);
    t = t1;
    goto Lret;

Lt2:
    e1 = e1.castTo(sc, t2);
    t = t2;
    goto Lret;
}

class BinExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

    Expression e1;
    Expression e2;

    this(Loc loc, TOK op, int size, Expression e1, Expression e2)
	{
		register();

		super(loc, op, size);
		this.e1 = e1;
		this.e2 = e2;
	}

    override Expression syntaxCopy()
	{
		BinExp e = cast(BinExp)copy();
		e.type = null;
		e.e1 = e.e1.syntaxCopy();
		e.e2 = e.e2.syntaxCopy();

		return e;
	}

    override Expression semantic(Scope sc)
	{
version (LOGSEMANTIC) {
		printf("BinExp.semantic('%.*s')\n", toChars());
}
		e1 = e1.semantic(sc);
		if (!e1.type && !(op == TOK.TOKassign && e1.op == TOK.TOKdottd))	// a.template = e2
		{
			error("%s has no value", e1.toChars());
			e1.type = Type.terror;
		}
		e2 = e2.semantic(sc);
		if (!e2.type)
		{
			error("%s has no value", e2.toChars());
			e2.type = Type.terror;
		}
		return this;
	}

    Expression semanticp(Scope sc)
	{
		BinExp.semantic(sc);

		e1 = resolveProperties(sc, e1);
		e2 = resolveProperties(sc, e2);
		return this;
	}

	/***************************
	 * Common semantic routine for some xxxAssignExp's.
	 */
    Expression commonSemanticAssign(Scope sc)
	{
		Expression e;

		if (!type)
		{
			BinExp.semantic(sc);
			e2 = resolveProperties(sc, e2);

			e = op_overload(sc);
			if (e)
				return e;

			if (e1.op == TOK.TOKarraylength)
			{
				e = ArrayLengthExp.rewriteOpAssign(this);
				e = e.semantic(sc);
				return e;
			}

			if (e1.op == TOKslice)
			{
				// T[] op= ...
				typeCombine(sc);
				type = e1.type;
				return arrayOp(sc);
			}

			e1 = e1.modifiableLvalue(sc, e1);
			e1.checkScalar();
			type = e1.type;
			if (type.toBasetype().ty == Tbool)
			{
				error("operator not allowed on bool expression %s", toChars());
			}
			typeCombine(sc);
			e1.checkArithmetic();
			e2.checkArithmetic();

			if (op == TOKmodass && e2.type.iscomplex())
			{   error("cannot perform modulo complex arithmetic");
				return new ErrorExp();
			}
		}
		return this;
	}

    Expression commonSemanticAssignIntegral(Scope sc)
	{
		Expression e;

		if (!type)
		{
			BinExp.semantic(sc);
			e2 = resolveProperties(sc, e2);

			e = op_overload(sc);
			if (e)
				return e;

			if (e1.op == TOKarraylength)
			{
				e = ArrayLengthExp.rewriteOpAssign(this);
				e = e.semantic(sc);
				return e;
			}

			if (e1.op == TOK.TOKslice)
			{   // T[] op= ...
				typeCombine(sc);
				type = e1.type;
				return arrayOp(sc);
			}

			e1 = e1.modifiableLvalue(sc, e1);
			e1.checkScalar();
			type = e1.type;
			if (type.toBasetype().ty == TY.Tbool)
			{
				e2 = e2.implicitCastTo(sc, type);
			}

			typeCombine(sc);
			e1.checkIntegral();
			e2.checkIntegral();
		}

		return this;
	}

    override bool checkSideEffect(int flag)
	{
		switch (op) {
			case TOK.TOKplusplus:
			case TOK.TOKminusminus:
			case TOK.TOKassign:
			case TOK.TOKconstruct:
			case TOK.TOKblit:
			case TOK.TOKaddass:
			case TOK.TOKminass:
			case TOK.TOKcatass:
			case TOK.TOKmulass:
			case TOK.TOKdivass:
			case TOK.TOKmodass:
			case TOK.TOKshlass:
			case TOK.TOKshrass:
			case TOK.TOKushrass:
			case TOK.TOKandass:
			case TOK.TOKorass:
			case TOK.TOKxorass:
            case TOK.TOKpowass:
			case TOK.TOKin:
			case TOK.TOKremove:
				return true;

			default:
				return Expression.checkSideEffect(flag);
		}
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		expToCBuffer(buf, hgs, e1, precedence[op]);
		buf.writeByte(' ');
		buf.writestring(Token.toChars(op));
		buf.writeByte(' ');
		expToCBuffer(buf, hgs, e2, cast(PREC)(precedence[op] + 1));
	}

	/****************************************
	 * Scale addition/subtraction to/from pointer.
	 */
    Expression scaleFactor(Scope sc)
	{
		ulong stride;
		Type t1b = e1.type.toBasetype();
		Type t2b = e2.type.toBasetype();

		if (t1b.ty == Tpointer && t2b.isintegral())
		{
			// Need to adjust operator by the stride
			// Replace (ptr + int) with (ptr + (int * stride))
			Type t = Type.tptrdiff_t;

			stride = t1b.nextOf().size(loc);
			if (!t.equals(t2b))
				e2 = e2.castTo(sc, t);
			e2 = new MulExp(loc, e2, new IntegerExp(Loc(0), stride, t));
			e2.type = t;
			type = e1.type;
		}
		else if (t2b.ty == Tpointer && t1b.isintegral())
		{
			// Need to adjust operator by the stride
			// Replace (int + ptr) with (ptr + (int * stride))
			Type t = Type.tptrdiff_t;
			Expression e;

			stride = t2b.nextOf().size(loc);
			if (!t.equals(t1b))
				e = e1.castTo(sc, t);
			else
				e = e1;
			e = new MulExp(loc, e, new IntegerExp(Loc(0), stride, t));
			e.type = t;
			type = e2.type;
			e1 = e2;
			e2 = e;
		}
		return this;
	}

	/************************************
	 * Bring leaves to common type.
	 */
    Expression typeCombine(Scope sc)
	{
		Type t1 = e1.type.toBasetype();
		Type t2 = e2.type.toBasetype();

		if (op == TOK.TOKmin || op == TOK.TOKadd)
		{
			if (t1.ty == TY.Tstruct)
			{
				if (t2.ty == TY.Tstruct && (cast(TypeStruct)t1).sym is (cast(TypeStruct)t2).sym)
					goto Lerror;
			}
			else if (t1.ty == TY.Tclass)
			{
				if (t2.ty == TY.Tclass)
					goto Lerror;
			}
		}

		if (!typeMerge(sc, this, &type, &e1, &e2))
			goto Lerror;
		return this;

	Lerror:
		incompatibleTypes();
		type = Type.terror;
		e1 = new ErrorExp();
		e2 = new ErrorExp();
		return this;
	}

    override Expression optimize(int result)
	{
		//printf("BinExp.optimize(result = %d) %s\n", result, toChars());
		if (op != TOK.TOKconstruct && op != TOK.TOKblit)	// don't replace const variable with its initializer
			e1 = e1.optimize(result);

		e2 = e2.optimize(result);
		if (op == TOK.TOKshlass || op == TOK.TOKshrass || op == TOK.TOKushrass)
		{
			if (e2.isConst() == 1)
			{
				long  i2 = e2.toInteger();
				ulong sz = e1.type.size() * 8;

				if (i2 < 0 || i2 > sz)
				{
					error("shift assign by %jd is outside the range 0..%zu", i2, sz);
					e2 = new IntegerExp(0);
				}
			}
		}

		return this;
	}

    bool isunsigned()
	{
		return e1.type.isunsigned() || e2.type.isunsigned();
	}

    void incompatibleTypes()
	{
		error("incompatible types for ((%s) %s (%s)): '%s' and '%s'",
         e1.toChars(), Token.toChars(op), e2.toChars(),
         e1.type.toChars(), e2.type.toChars());
	}

    override void dump(int indent)
	{
		assert(false);
	}

    override void scanForNestedRef(Scope sc)
	{
		e1.scanForNestedRef(sc);
		e2.scanForNestedRef(sc);
	}

	Expression interpretCommon(InterState istate, Expression function(Type, Expression, Expression) fp)
	{
		Expression e;
		Expression e1;
		Expression e2;

version(LOG)
{
		writef("BinExp::interpretCommon() %s\n", toChars());
}
		e1 = this.e1.interpret(istate);
		if (e1 is EXP_CANT_INTERPRET)
			goto Lcant;
		if (e1.isConst() != 1)
			goto Lcant;

		e2 = this.e2.interpret(istate);
		if (e2 is EXP_CANT_INTERPRET)
			goto Lcant;
		if (e2.isConst() != 1)
			goto Lcant;

		e = fp(type, e1, e2);
		return e;

	Lcant:
		return EXP_CANT_INTERPRET;
	}

	Expression interpretCommon2(InterState istate, Expression function(TOK, Type, Expression, Expression) fp)
	{
		Expression e;
		Expression e1;
		Expression e2;

version(LOG)
{
		writef("BinExp::interpretCommon2() %s\n", toChars());
}
		e1 = this.e1.interpret(istate);
		if (e1 is EXP_CANT_INTERPRET)
			goto Lcant;
		if (e1.isConst() != 1 &&
			e1.op != TOKnull &&
			e1.op != TOKstring &&
			e1.op != TOKarrayliteral &&
			e1.op != TOKstructliteral)
			goto Lcant;

		e2 = this.e2.interpret(istate);
		if (e2 is EXP_CANT_INTERPRET)
			goto Lcant;
		if (e2.isConst() != 1 &&
			e2.op != TOKnull &&
			e2.op != TOKstring &&
			e2.op != TOKarrayliteral &&
			e2.op != TOKstructliteral)
			goto Lcant;

		e = fp(op, type, e1, e2);
		return e;

	Lcant:
		return EXP_CANT_INTERPRET;
	}

    Expression interpretAssignCommon(InterState istate, Expression function(Type, Expression, Expression) fp, int post = 0)
	{
version (LOG)
{
		writef("BinExp.interpretAssignCommon() %.*s\n", toChars());
}
		Expression e = EXP_CANT_INTERPRET;
		Expression e1 = this.e1;

		if (fp)
		{
			if (e1.op == TOKcast)
			{
				CastExp ce = cast(CastExp)e1;
				e1 = ce.e1;
			}
		}
		if (e1 is EXP_CANT_INTERPRET)
			return e1;
		Expression e2 = this.e2.interpret(istate);
		if (e2 is EXP_CANT_INTERPRET)
			return e2;

		// Chase down rebinding of out and ref.
		if (e1.op == TOKvar) 
		{
			VarExp ve = cast(VarExp)e1;
			VarDeclaration v = ve.var.isVarDeclaration();
			if (v && v.value && v.value.op == TOKvar)
			{
				VarExp ve2 = cast(VarExp)v.value;
				if (ve2.var.isSymbolDeclaration())
				{
					// This can happen if v is a struct initialized to
					// 0 using an __initZ SymbolDeclaration from
					// TypeStruct.defaultInit()
				}
				else
					e1 = v.value;
			}
			else if (v && v.value && (v.value.op==TOKindex || v.value.op == TOKdotvar))
			{
				// It is no longer a TOKvar, eg when a[4] is passed by ref.
				e1 = v.value;
			}
		}

		// To reduce code complexity of handling dotvar expressions,
		// extract the aggregate now.
		Expression aggregate;
		if (e1.op == TOKdotvar)
		{
			aggregate = (cast(DotVarExp)e1).e1;
		// Get rid of 'this'.
			if (aggregate.op == TOKthis && istate.localThis)
				aggregate = istate.localThis;
		}
	    if (e1.op == TOKthis && istate.localThis)
			e1 = istate.localThis;

		/* Assignment to variable of the form:
		 *	v = e2
		 */
		if (e1.op == TOKvar)
		{
			VarExp ve = cast(VarExp)e1;
			VarDeclaration v = ve.var.isVarDeclaration();
			assert(v);
			if (v && !v.isCTFE())
			{
				// Can't modify global or static data
				error("%s cannot be modified at compile time", v.toChars());
				return EXP_CANT_INTERPRET;
			}
			if (v && v.isCTFE())
			{
				Expression ev = v.value;
				if (fp && !ev)
				{
					error("variable %s is used before initialization", v.toChars());
					return e;
				}
				if (fp)
					e2 = (*fp)(v.type, ev, e2);
				else
				{
					/* Look for special case of struct being initialized with 0.
					 */
					if (v.type.toBasetype().ty == Tstruct && e2.op == TOKint64)
					{
						e2 = v.type.defaultInitLiteral(Loc(0));
					}
					e2 = Cast(v.type, v.type, e2);
				}
				if (e2 is EXP_CANT_INTERPRET)
					return e2;

			    if (istate)
					addVarToInterstate(istate, v);
				v.value = e2;
				e = Cast(type, type, post ? ev : e2);
			}
		}
		else if (e1.op == TOKdotvar && aggregate.op == TOKdotvar)
		{
			// eg  v.u.var = e2,  v[3].u.var = e2, etc.
			error("Nested struct assignment %s is not yet supported in CTFE", toChars());
		}
		/* Assignment to struct member of the form:
		 *   v.var = e2
		 */
		else if (e1.op == TOKdotvar && aggregate.op == TOKvar)
		{
			VarDeclaration v = (cast(VarExp)aggregate).var.isVarDeclaration();

			if (!v.isCTFE())
			{
				// Can't modify global or static data
				error("%s cannot be modified at compile time", v.toChars());
				return EXP_CANT_INTERPRET;
			} else {
				// Chase down rebinding of out and ref
				if (v.value && v.value.op == TOKvar)
				{
					VarExp ve2 = cast(VarExp)v.value;
					if (ve2.var.isSymbolDeclaration())
					{
						// This can happen if v is a struct initialized to
						// 0 using an __initZ SymbolDeclaration from
						// TypeStruct.defaultInit()
					}
					else
						v = ve2.var.isVarDeclaration();
					assert(v);
				}
			}
			if (fp && !v.value)
			{
				error("variable %s is used before initialization", v.toChars());
				return e;
			}
			if (v.value is null && v.init.isVoidInitializer())
			{
				/* Since a void initializer initializes to undefined
				 * values, it is valid here to use the default initializer.
				 * No attempt is made to determine if someone actually relies
				 * on the void value - to do that we'd need a VoidExp.
				 * That's probably a good enhancement idea.
				 */
			    v.value = v.type.defaultInitLiteral(Loc(0));
			}
			Expression vie = v.value;
			assert(vie !is EXP_CANT_INTERPRET);
			if (vie.op == TOKvar)
			{
				Declaration d = (cast(VarExp)vie).var;
				vie = getVarExp(e1.loc, istate, d);
			}
			if (vie.op != TOKstructliteral)
			{
				error("Cannot assign %s=%s in CTFE", v.toChars(), vie.toChars());
				return EXP_CANT_INTERPRET;
			}
			StructLiteralExp se = cast(StructLiteralExp)vie;
			VarDeclaration vf = (cast(DotVarExp)e1).var.isVarDeclaration();
			if (!vf)
				return EXP_CANT_INTERPRET;
			int fieldi = se.getFieldIndex(type, vf.offset);
			if (fieldi == -1)
				return EXP_CANT_INTERPRET;
			Expression ev = se.getField(type, vf.offset);
			if (fp)
				e2 = (*fp)(type, ev, e2);
			else
				e2 = Cast(type, type, e2);
			if (e2 is EXP_CANT_INTERPRET)
				return e2;

			addVarToInterstate(istate, v);

			/* Create new struct literal reflecting updated fieldi
			 */
			auto expsx = changeOneElement(se.elements, fieldi, e2);
			v.value = new StructLiteralExp(se.loc, se.sd, expsx);
			v.value.type = se.type;

			e = Cast(type, type, post ? ev : e2);
		}
		/* Assignment to struct member of the form:
		 *   *(symoffexp) = e2
		 */
		else if (e1.op == TOKstar && (cast(PtrExp)e1).e1.op == TOKsymoff)
		{
			SymOffExp soe = cast(SymOffExp)(cast(PtrExp)e1).e1;
			VarDeclaration v = soe.var.isVarDeclaration();

			if (!v.isCTFE())
			{
				error("%s cannot be modified at compile time", v.toChars());
				return EXP_CANT_INTERPRET;
			}
			if (fp && !v.value)
			{
				error("variable %s is used before initialization", v.toChars());
				return e;
			}
			Expression vie = v.value;
			if (vie.op == TOKvar)
			{
				Declaration d = (cast(VarExp)vie).var;
				vie = getVarExp(e1.loc, istate, d);
			}
			if (vie.op != TOKstructliteral)
				return EXP_CANT_INTERPRET;
			StructLiteralExp se = cast(StructLiteralExp)vie;
			int fieldi = se.getFieldIndex(type, soe.offset);
			if (fieldi == -1)
				return EXP_CANT_INTERPRET;
			Expression ev = se.getField(type, soe.offset);
			if (fp)
				e2 = (*fp)(type, ev, e2);
			else
				e2 = Cast(type, type, e2);
			if (e2 is EXP_CANT_INTERPRET)
				return e2;

			addVarToInterstate(istate, v);

			/* Create new struct literal reflecting updated fieldi
			 */
			auto expsx = changeOneElement(se.elements, fieldi, e2);
			v.value = new StructLiteralExp(se.loc, se.sd, expsx);
			v.value.type = se.type;

			e = Cast(type, type, post ? ev : e2);
		}
		/* Assignment to array element of the form:
		 *   a[i] = e2
		 */
		else if (e1.op == TOKindex && (cast(IndexExp)e1).e1.op == TOKvar)
		{
			IndexExp ie = cast(IndexExp)e1;
			VarExp ve = cast(VarExp)ie.e1;
			VarDeclaration v = ve.var.isVarDeclaration();
			if (!v || !v.isCTFE())
			{
				error("%s cannot be modified at compile time", v ? v.toChars(): "void");
				return EXP_CANT_INTERPRET;
			}
			if (v.value && v.value.op == TOKvar)
			{
				VarExp ve2 = cast(VarExp)v.value;
				if (ve2.var.isSymbolDeclaration())
				{
					// This can happen if v is a struct initialized to
					// 0 using an __initZ SymbolDeclaration from
					// TypeStruct.defaultInit()
				}
				else
					v = ve2.var.isVarDeclaration();
				assert(v);
			}
			if (!v.value)
			{
				if (fp)
				{
					error("variable %s is used before initialization", v.toChars());
					return e;
				}

				Type t = v.type.toBasetype();
				if (t.ty == Tsarray)
				{
					/* This array was void initialized. Create a
					 * default initializer for it.
					 * What we should do is fill the array literal with
					 * null data, so use-before-initialized can be detected.
					 * But we're too lazy at the moment to do it, as that
					 * involves redoing Index() and whoever calls it.
					 */

					size_t dim = cast(size_t)(cast(TypeSArray)t).dim.toInteger();
					v.value = createBlockDuplicatedArrayLiteral(v.type,
						v.type.defaultInit(Loc(0)), dim);
				}
				else
					return EXP_CANT_INTERPRET;
			}

			ArrayLiteralExp ae = null;
			AssocArrayLiteralExp aae = null;
			StringExp se = null;
			if (v.value.op == TOKarrayliteral)
				ae = cast(ArrayLiteralExp)v.value;
			else if (v.value.op == TOKassocarrayliteral)
				aae = cast(AssocArrayLiteralExp)v.value;
			else if (v.value.op == TOKstring)
				se = cast(StringExp)v.value;
			else if (v.value.op == TOKnull)
			{
				// This would be a runtime segfault
				error("Cannot index null array %.*s", v.toChars());
				return EXP_CANT_INTERPRET;
			}
			else
				return EXP_CANT_INTERPRET;

			/* Set the $ variable
			 */
			Expression ee = ArrayLength(Type.tsize_t, v.value);
			if (ee !is EXP_CANT_INTERPRET && ie.lengthVar)
				ie.lengthVar.value = ee;
			Expression index = ie.e2.interpret(istate);
			if (index is EXP_CANT_INTERPRET)
				return EXP_CANT_INTERPRET;
			Expression ev;
			if (fp || ae || se)	// not for aae, because key might not be there
			{
				ev = Index(type, v.value, index);
				if (ev is EXP_CANT_INTERPRET)
					return EXP_CANT_INTERPRET;
			}

			if (fp)
				e2 = (*fp)(type, ev, e2);
			else
				e2 = Cast(type, type, e2);
			if (e2 is EXP_CANT_INTERPRET)
				return e2;

			addVarToInterstate(istate, v);
			if (ae)
			{
				/* Create new array literal reflecting updated elem
				 */
				int elemi = cast(int)index.toInteger();
				auto expsx = changeOneElement(ae.elements, elemi, e2);
				v.value = new ArrayLiteralExp(ae.loc, expsx);
				v.value.type = ae.type;
			}
			else if (aae)
			{
				/* Create new associative array literal reflecting updated key/value
				 */
				Expressions keysx = aae.keys;
				Expressions valuesx = new Expressions();
				valuesx.setDim(aae.values.dim);
				int updated = 0;
				for (size_t j = valuesx.dim; j; )
				{
					j--;
					Expression ekey = aae.keys[j];
					Expression ex = Equal(TOKequal, Type.tbool, ekey, index);
					if (ex is EXP_CANT_INTERPRET)
						return EXP_CANT_INTERPRET;
					if (ex.isBool(true))
					{
						valuesx[j] = e2;
						updated = 1;
					}
					else
						valuesx[j] = aae.values[j];
				}
				if (!updated)
				{
					// Append index/e2 to keysx[]/valuesx[]
					valuesx.push(e2);
					keysx = keysx.copy();
					keysx.push(index);
				}
				v.value = new AssocArrayLiteralExp(aae.loc, keysx, valuesx);
				v.value.type = aae.type;
			}
			else if (se)
			{
				/* Create new string literal reflecting updated elem
				 */
				int elemi = cast(int)index.toInteger();
				char* s;
				s = cast(char*)calloc(se.len + 1, se.sz);
				memcpy(s, se.string_, se.len * se.sz);
				dchar value = cast(dchar)e2.toInteger();
				switch (se.sz)
				{
					case 1:	s[elemi] = cast(char)value; break;
					case 2:	(cast(wchar*)s)[elemi] = cast(wchar)value; break;
					case 4:	(cast(dchar*)s)[elemi] = value; break;
					default:
						assert(0);
						break;
				}
				StringExp se2 = new StringExp(se.loc, assumeUnique(s[0..se.len]));
				se2.committed = se.committed;
				se2.postfix = se.postfix;
				se2.type = se.type;
				v.value = se2;
			}
			else
				assert(0);

			e = Cast(type, type, post ? ev : e2);
		}

		/* Assignment to struct element in array, of the form:
		 *  a[i].var = e2
		 */
		else if (e1.op == TOKdotvar && aggregate.op == TOKindex &&
			 (cast(IndexExp)aggregate).e1.op == TOKvar)
		{
			IndexExp ie = cast(IndexExp)aggregate;
			VarExp ve = cast(VarExp)(ie.e1);
			VarDeclaration v = ve.var.isVarDeclaration();
			if (!v || !v.isCTFE())
			{
				error("%s cannot be modified at compile time", v ? v.toChars(): "void");
				return EXP_CANT_INTERPRET;
			}
			Type t = ve.type.toBasetype();
			ArrayLiteralExp ae = cast(ArrayLiteralExp)v.value;
			if (!ae)
			{
				// assignment to one element in an uninitialized (static) array.
				// This is quite difficult, because defaultInit() for a struct is a VarExp,
				// not a StructLiteralExp.
				Type t2 = v.type.toBasetype();
				if (t2.ty != Tsarray)
				{
					error("Cannot index an uninitialized variable");
					return EXP_CANT_INTERPRET;
				}

				Type telem = (cast(TypeSArray)t2).nextOf().toBasetype();
				if (telem.ty != Tstruct) { return EXP_CANT_INTERPRET; }

				// Create a default struct literal...
				Expression structinit = telem.defaultInitLiteral(v.loc);

				// ... and use to create a blank array literal
				size_t dim = cast(size_t)(cast(TypeSArray)t2).dim.toInteger();
				ae = createBlockDuplicatedArrayLiteral(v.type, structinit, dim);
				v.value = ae;
			}
			if (cast(Expression)(ae.elements) is EXP_CANT_INTERPRET)
			{
				// Note that this would be a runtime segfault
				error("Cannot index null array %s", v.toChars());
				return EXP_CANT_INTERPRET;
			}
			// Set the $ variable
			Expression ee = ArrayLength(Type.tsize_t, v.value);
			if (ee !is EXP_CANT_INTERPRET && ie.lengthVar)
				ie.lengthVar.value = ee;
			// Determine the index, and check that it's OK.
			Expression index = ie.e2.interpret(istate);
			if (index is EXP_CANT_INTERPRET)
				return EXP_CANT_INTERPRET;

			int elemi = cast(int)index.toInteger();
			if (elemi >= ae.elements.dim)
			{
				error("array index %d is out of bounds %s[0..%d]", elemi,
					v.toChars(), ae.elements.dim);
				return EXP_CANT_INTERPRET;
			}
			// Get old element
			auto vie = ae.elements[elemi];
			if (vie.op != TOKstructliteral)
				return EXP_CANT_INTERPRET;

			// Work out which field needs to be changed
			auto se = cast(StructLiteralExp)vie;
			auto vf = (cast(DotVarExp)e1).var.isVarDeclaration();
			if (!vf)
				return EXP_CANT_INTERPRET;

			int fieldi = se.getFieldIndex(type, vf.offset);
			if (fieldi == -1)
				return EXP_CANT_INTERPRET;

			Expression ev = se.getField(type, vf.offset);
			if (fp)
				e2 = (*fp)(type, ev, e2);
			else
				e2 = Cast(type, type, e2);
			if (e2 == EXP_CANT_INTERPRET)
				return e2;

			// Create new struct literal reflecting updated field
			auto expsx = changeOneElement(se.elements, fieldi, e2);
			Expression newstruct = new StructLiteralExp(se.loc, se.sd, expsx);

			// Create new array literal reflecting updated struct elem
			ae.elements = changeOneElement(ae.elements, elemi, newstruct);
			return ae;
		}
		/* Slice assignment, initialization of static arrays
		 *   a[] = e
		 */
		else if (e1.op == TOKslice && (cast(SliceExp)e1).e1.op == TOKvar)
		{
			SliceExp sexp = cast(SliceExp)e1;
			VarExp ve = cast(VarExp)(sexp.e1);
			VarDeclaration v = ve.var.isVarDeclaration();
			if (!v || !v.isCTFE())
			{
				error("%s cannot be modified at compile time", v.toChars());
				return EXP_CANT_INTERPRET;
			}
			// Chase down rebinding of out and ref
			if (v.value && v.value.op == TOKvar)
			{
				VarExp ve2 = cast(VarExp)v.value;
				if (ve2.var.isSymbolDeclaration())
				{
					// This can happen if v is a struct initialized to
					// 0 using an __initZ SymbolDeclaration from
					// TypeStruct.defaultInit()
				}
				else
					v = ve2.var.isVarDeclaration();
				assert(v);
			}
			/* Set the $ variable
			 */
			Expression ee = v.value ? ArrayLength(Type.tsize_t, v.value)
						  : EXP_CANT_INTERPRET;
			if (ee !is EXP_CANT_INTERPRET && sexp.lengthVar)
				sexp.lengthVar.value = ee;
			Expression upper = null;
			Expression lower = null;
			if (sexp.upr)
			{
				upper = sexp.upr.interpret(istate);
				if (upper is EXP_CANT_INTERPRET)
					return EXP_CANT_INTERPRET;
			}
			if (sexp.lwr)
			{
				lower = sexp.lwr.interpret(istate);
				if (lower is EXP_CANT_INTERPRET)
					return EXP_CANT_INTERPRET;
			}
			Type t = v.type.toBasetype();
			size_t dim;
			if (t.ty == Tsarray)
				dim = cast(size_t)(cast(TypeSArray)t).dim.toInteger();
			else if (t.ty == Tarray)
			{
				if (!v.value || v.value.op == TOKnull)
				{
					error("cannot assign to null array %s", v.toChars());
					return EXP_CANT_INTERPRET;
				}
				if (v.value.op == TOKarrayliteral)
					dim = (cast(ArrayLiteralExp)v.value).elements.dim;
				else if (v.value.op ==TOKstring)
					dim = (cast(StringExp)v.value).len;
			}
			else
			{
				error("%s cannot be evaluated at compile time", toChars());
				return EXP_CANT_INTERPRET;
			}
			int upperbound = upper ? cast(int)upper.toInteger() : dim;
			int lowerbound = lower ? cast(int)lower.toInteger() : 0;

			if ((cast(int)lowerbound < 0) || (upperbound > dim))
			{
				error("Array bounds [0..%d] exceeded in slice [%d..%d]", dim, lowerbound, upperbound);
				return EXP_CANT_INTERPRET;
			}
			// Could either be slice assignment (v[] = e[]), 
			// or block assignment (v[] = val). 
			// For the former, we check that the lengths match.
			bool isSliceAssignment = (e2.op == TOKarrayliteral)
				|| (e2.op == TOKstring);
			size_t srclen = 0;
			if (e2.op == TOKarrayliteral)
				srclen = (cast(ArrayLiteralExp)e2).elements.dim;
			else if (e2.op == TOKstring)
				srclen = (cast(StringExp)e2).len;
			if (isSliceAssignment && srclen != (upperbound - lowerbound))
			{
				error("Array length mismatch assigning [0..%d] to [%d..%d]", srclen, lowerbound, upperbound);
				return e;
			}
			if (e2.op == TOKarrayliteral)
			{
				// Static array assignment from literal
				ArrayLiteralExp ae = cast(ArrayLiteralExp)e2;
				if (upperbound - lowerbound == dim)
					v.value = ae;
				else
				{
					ArrayLiteralExp existing;
					// Only modifying part of the array. Must create a new array literal.
					// If the existing array is uninitialized (this can only happen
					// with static arrays), create it.
					if (v.value && v.value.op == TOKarrayliteral)
						existing = cast(ArrayLiteralExp)v.value;
					else // this can only happen with static arrays
						existing = createBlockDuplicatedArrayLiteral(v.type, v.type.defaultInit(Loc(0)), dim);

					// value[] = value[0..lower] ~ ae ~ value[upper..$]
					existing.elements = spliceElements(existing.elements, ae.elements, lowerbound);
					v.value = existing;
				}
				return e2;
			}
			else if (e2.op == TOKstring)
			{
				StringExp se = cast(StringExp)e2;
				if (upperbound-lowerbound == dim)
					v.value = e2;		
				else
				{
					if (!v.value)
						v.value = createBlockDuplicatedStringLiteral(se.type, cast(dchar)se.type.defaultInit(Loc(0)).toInteger(), dim, se.sz);
					if (v.value.op==TOKstring)
						v.value = spliceStringExp(cast(StringExp)v.value, se, lowerbound);
					else
						error("String slice assignment is not yet supported in CTFE");
				}
				return e2;
			}
			else if (t.nextOf().ty == e2.type.ty)
			{
				// Static array block assignment
				if (upperbound - lowerbound == dim)
					v.value = createBlockDuplicatedArrayLiteral(v.type, e2, dim);
				else
				{
					ArrayLiteralExp existing;
					// Only modifying part of the array. Must create a new array literal.
					// If the existing array is uninitialized (this can only happen
					// with static arrays), create it.
					if (v.value && v.value.op == TOKarrayliteral)
						existing = cast(ArrayLiteralExp)v.value;
					else // this can only happen with static arrays
						existing = createBlockDuplicatedArrayLiteral(v.type, v.type.defaultInit(Loc(0)), dim);
					// value[] = value[0..lower] ~ ae ~ value[upper..$]
					existing.elements = spliceElements(existing.elements, 
						createBlockDuplicatedArrayLiteral(v.type, e2, upperbound-lowerbound).elements,
						lowerbound);
					v.value = existing;
				}				

				return e2;
			}
			else
			{
				error("Slice operation %s cannot be evaluated at compile time", toChars());
				return e;
			}
		}
		else
		{
			error("%s cannot be evaluated at compile time", toChars());
version (DEBUG) {
			dump(0);
}
		}
		return e;
	}

	version(DMDV2)
    override bool canThrow()
	{
		return e1.canThrow() || e2.canThrow();
	}

	// generate an error if this is a nonsensical *=,/=, or %=, eg real *= imaginary
	void checkComplexMulAssign()
	{
		// Any multiplication by an imaginary or complex number yields a complex result.
		// r *= c, i*=c, r*=i, i*=i are all forbidden operations.
		string opstr = Token.toChars(op);
		if ( e1.type.isreal() && e2.type.iscomplex())
		{
			error("%s %s %s is undefined. Did you mean %s %s %s.re ?",
				e1.type.toChars(), opstr, e2.type.toChars(),
				e1.type.toChars(), opstr, e2.type.toChars());
		}
		else if (e1.type.isimaginary() && e2.type.iscomplex())
		{
			error("%s %s %s is undefined. Did you mean %s %s %s.im ?",
				e1.type.toChars(), opstr, e2.type.toChars(),
				e1.type.toChars(), opstr, e2.type.toChars());
		}
		else if ((e1.type.isreal() || e1.type.isimaginary()) && e2.type.isimaginary())
		{
			error("%s %s %s is an undefined operation", e1.type.toChars(),
			opstr, e2.type.toChars());
		}
	}

	// generate an error if this is a nonsensical += or -=, eg real += imaginary
	void checkComplexAddAssign()
	{
		// Addition or subtraction of a real and an imaginary is a complex result.
		// Thus, r+=i, r+=c, i+=r, i+=c are all forbidden operations.
		if ( (e1.type.isreal() && (e2.type.isimaginary() || e2.type.iscomplex())) ||
			 (e1.type.isimaginary() && (e2.type.isreal() || e2.type.iscomplex()))
			)
		{
			error("%s %s %s is undefined (result is complex)",
			e1.type.toChars(), Token.toChars(op), e2.type.toChars());
		}
	}


	/***********************************
	 * Construct the array operation expression.
	 */
    Expression arrayOp(Scope sc)
	{
		//printf("BinExp.arrayOp() %s\n", toChars());

		if (type.toBasetype().nextOf().toBasetype().ty == Tvoid)
		{
			error("Cannot perform array operations on void[] arrays");
			return new ErrorExp();
		}

		auto arguments = new Expressions();

		/* The expression to generate an array operation for is mangled
		 * into a name to use as the array operation function name.
		 * Mangle in the operands and operators in RPN order, and type.
		 */
		scope OutBuffer buf = new OutBuffer();
		buf.writestring("_array");
		buildArrayIdent(buf, arguments);
		buf.writeByte('_');

		/* Append deco of array element type
		 */
version (DMDV2) {
		buf.writestring(type.toBasetype().nextOf().toBasetype().mutableOf().deco);
} else {
		buf.writestring(type.toBasetype().nextOf().toBasetype().deco);
}

		size_t namelen = buf.offset;
		buf.writeByte(0);
		immutable(char)* name = cast(immutable(char)*)buf.extractData();

		/* Look up name in hash table
		 */
        auto s = name[0..namelen];
		Object* sv = global.arrayfuncs.update(s);
		FuncDeclaration fd = cast(FuncDeclaration)*sv;
		if (!fd)
		{
			/* Some of the array op functions are written as library functions,
			 * presumably to optimize them with special CPU vector instructions.
			 * List those library functions here, in alpha order.
			 */
			enum const(char)*[] libArrayopFuncs =
			[
				"_arrayExpSliceAddass_a",
				"_arrayExpSliceAddass_d",		// T[]+=T
				"_arrayExpSliceAddass_f",		// T[]+=T
				"_arrayExpSliceAddass_g",
				"_arrayExpSliceAddass_h",
				"_arrayExpSliceAddass_i",
				"_arrayExpSliceAddass_k",
				"_arrayExpSliceAddass_s",
				"_arrayExpSliceAddass_t",
				"_arrayExpSliceAddass_u",
				"_arrayExpSliceAddass_w",

				"_arrayExpSliceDivass_d",		// T[]/=T
				"_arrayExpSliceDivass_f",		// T[]/=T

				"_arrayExpSliceMinSliceAssign_a",
				"_arrayExpSliceMinSliceAssign_d",	// T[]=T-T[]
				"_arrayExpSliceMinSliceAssign_f",	// T[]=T-T[]
				"_arrayExpSliceMinSliceAssign_g",
				"_arrayExpSliceMinSliceAssign_h",
				"_arrayExpSliceMinSliceAssign_i",
				"_arrayExpSliceMinSliceAssign_k",
				"_arrayExpSliceMinSliceAssign_s",
				"_arrayExpSliceMinSliceAssign_t",
				"_arrayExpSliceMinSliceAssign_u",
				"_arrayExpSliceMinSliceAssign_w",

				"_arrayExpSliceMinass_a",
				"_arrayExpSliceMinass_d",		// T[]-=T
				"_arrayExpSliceMinass_f",		// T[]-=T
				"_arrayExpSliceMinass_g",
				"_arrayExpSliceMinass_h",
				"_arrayExpSliceMinass_i",
				"_arrayExpSliceMinass_k",
				"_arrayExpSliceMinass_s",
				"_arrayExpSliceMinass_t",
				"_arrayExpSliceMinass_u",
				"_arrayExpSliceMinass_w",

				"_arrayExpSliceMulass_d",		// T[]*=T
				"_arrayExpSliceMulass_f",		// T[]*=T
				"_arrayExpSliceMulass_i",
				"_arrayExpSliceMulass_k",
				"_arrayExpSliceMulass_s",
				"_arrayExpSliceMulass_t",
				"_arrayExpSliceMulass_u",
				"_arrayExpSliceMulass_w",

				"_arraySliceExpAddSliceAssign_a",
				"_arraySliceExpAddSliceAssign_d",	// T[]=T[]+T
				"_arraySliceExpAddSliceAssign_f",	// T[]=T[]+T
				"_arraySliceExpAddSliceAssign_g",
				"_arraySliceExpAddSliceAssign_h",
				"_arraySliceExpAddSliceAssign_i",
				"_arraySliceExpAddSliceAssign_k",
				"_arraySliceExpAddSliceAssign_s",
				"_arraySliceExpAddSliceAssign_t",
				"_arraySliceExpAddSliceAssign_u",
				"_arraySliceExpAddSliceAssign_w",

				"_arraySliceExpDivSliceAssign_d",	// T[]=T[]/T
				"_arraySliceExpDivSliceAssign_f",	// T[]=T[]/T

				"_arraySliceExpMinSliceAssign_a",
				"_arraySliceExpMinSliceAssign_d",	// T[]=T[]-T
				"_arraySliceExpMinSliceAssign_f",	// T[]=T[]-T
				"_arraySliceExpMinSliceAssign_g",
				"_arraySliceExpMinSliceAssign_h",
				"_arraySliceExpMinSliceAssign_i",
				"_arraySliceExpMinSliceAssign_k",
				"_arraySliceExpMinSliceAssign_s",
				"_arraySliceExpMinSliceAssign_t",
				"_arraySliceExpMinSliceAssign_u",
				"_arraySliceExpMinSliceAssign_w",

				"_arraySliceExpMulSliceAddass_d",	// T[] += T[]*T
				"_arraySliceExpMulSliceAddass_f",
				"_arraySliceExpMulSliceAddass_r",

				"_arraySliceExpMulSliceAssign_d",	// T[]=T[]*T
				"_arraySliceExpMulSliceAssign_f",	// T[]=T[]*T
				"_arraySliceExpMulSliceAssign_i",
				"_arraySliceExpMulSliceAssign_k",
				"_arraySliceExpMulSliceAssign_s",
				"_arraySliceExpMulSliceAssign_t",
				"_arraySliceExpMulSliceAssign_u",
				"_arraySliceExpMulSliceAssign_w",

				"_arraySliceExpMulSliceMinass_d",	// T[] -= T[]*T
				"_arraySliceExpMulSliceMinass_f",
				"_arraySliceExpMulSliceMinass_r",

				"_arraySliceSliceAddSliceAssign_a",
				"_arraySliceSliceAddSliceAssign_d",	// T[]=T[]+T[]
				"_arraySliceSliceAddSliceAssign_f",	// T[]=T[]+T[]
				"_arraySliceSliceAddSliceAssign_g",
				"_arraySliceSliceAddSliceAssign_h",
				"_arraySliceSliceAddSliceAssign_i",
				"_arraySliceSliceAddSliceAssign_k",
				"_arraySliceSliceAddSliceAssign_r",	// T[]=T[]+T[]
				"_arraySliceSliceAddSliceAssign_s",
				"_arraySliceSliceAddSliceAssign_t",
				"_arraySliceSliceAddSliceAssign_u",
				"_arraySliceSliceAddSliceAssign_w",

				"_arraySliceSliceAddass_a",
				"_arraySliceSliceAddass_d",		// T[]+=T[]
				"_arraySliceSliceAddass_f",		// T[]+=T[]
				"_arraySliceSliceAddass_g",
				"_arraySliceSliceAddass_h",
				"_arraySliceSliceAddass_i",
				"_arraySliceSliceAddass_k",
				"_arraySliceSliceAddass_s",
				"_arraySliceSliceAddass_t",
				"_arraySliceSliceAddass_u",
				"_arraySliceSliceAddass_w",

				"_arraySliceSliceMinSliceAssign_a",
				"_arraySliceSliceMinSliceAssign_d",	// T[]=T[]-T[]
				"_arraySliceSliceMinSliceAssign_f",	// T[]=T[]-T[]
				"_arraySliceSliceMinSliceAssign_g",
				"_arraySliceSliceMinSliceAssign_h",
				"_arraySliceSliceMinSliceAssign_i",
				"_arraySliceSliceMinSliceAssign_k",
				"_arraySliceSliceMinSliceAssign_r",	// T[]=T[]-T[]
				"_arraySliceSliceMinSliceAssign_s",
				"_arraySliceSliceMinSliceAssign_t",
				"_arraySliceSliceMinSliceAssign_u",
				"_arraySliceSliceMinSliceAssign_w",

				"_arraySliceSliceMinass_a",
				"_arraySliceSliceMinass_d",		// T[]-=T[]
				"_arraySliceSliceMinass_f",		// T[]-=T[]
				"_arraySliceSliceMinass_g",
				"_arraySliceSliceMinass_h",
				"_arraySliceSliceMinass_i",
				"_arraySliceSliceMinass_k",
				"_arraySliceSliceMinass_s",
				"_arraySliceSliceMinass_t",
				"_arraySliceSliceMinass_u",
				"_arraySliceSliceMinass_w",

				"_arraySliceSliceMulSliceAssign_d",	// T[]=T[]*T[]
				"_arraySliceSliceMulSliceAssign_f",	// T[]=T[]*T[]
				"_arraySliceSliceMulSliceAssign_i",
				"_arraySliceSliceMulSliceAssign_k",
				"_arraySliceSliceMulSliceAssign_s",
				"_arraySliceSliceMulSliceAssign_t",
				"_arraySliceSliceMulSliceAssign_u",
				"_arraySliceSliceMulSliceAssign_w",

				"_arraySliceSliceMulass_d",		// T[]*=T[]
				"_arraySliceSliceMulass_f",		// T[]*=T[]
				"_arraySliceSliceMulass_i",
				"_arraySliceSliceMulass_k",
				"_arraySliceSliceMulass_s",
				"_arraySliceSliceMulass_t",
				"_arraySliceSliceMulass_u",
				"_arraySliceSliceMulass_w",
			];

			int i = binary(name, libArrayopFuncs.ptr, libArrayopFuncs.length);
			if (i == -1)
			{
debug {			// Make sure our array is alphabetized
				for (i = 0; i < libArrayopFuncs.length; i++)
				{
					if (strcmp(name, libArrayopFuncs[i]) == 0)
						assert(false);
				}
}
				/* Not in library, so generate it.
				 * Construct the function body:
				 *	foreach (i; 0 .. p.length)    for (size_t i = 0; i < p.length; i++)
				 *	    loopbody;
				 *	return p;
				 */

				auto fparams = new Parameters();
				Expression loopbody = buildArrayLoop(fparams);
				auto p = fparams[0 /*fparams.dim - 1*/];
version (DMDV1) {
				// for (size_t i = 0; i < p.length; i++)
				Initializer init = new ExpInitializer(0, new IntegerExp(0, 0, Type.tsize_t));
				Dsymbol d = new VarDeclaration(0, Type.tsize_t, Id.p, init);
				Statement s1 = new ForStatement(0,
					new DeclarationStatement(0, d),
					new CmpExp(TOKlt, 0, new IdentifierExp(0, Id.p), new ArrayLengthExp(0, new IdentifierExp(0, p.ident))),
					new PostExp(TOKplusplus, 0, new IdentifierExp(0, Id.p)),
					new ExpStatement(0, loopbody));
} else {
				// foreach (i; 0 .. p.length)
				Statement s1 = new ForeachRangeStatement(Loc(0), TOKforeach,
					new Parameter(STC.STCundefined, null, Id.p, null),
					new IntegerExp(Loc(0), 0, Type.tint32),
					new ArrayLengthExp(Loc(0), new IdentifierExp(Loc(0), p.ident)),
					new ExpStatement(Loc(0), loopbody));
}
				Statement s2 = new ReturnStatement(Loc(0), new IdentifierExp(Loc(0), p.ident));
				//printf("s2: %s\n", s2.toChars());
				Statement fbody = new CompoundStatement(Loc(0), s1, s2);

				/* Construct the function
				 */
				TypeFunction ftype = new TypeFunction(fparams, type, 0, LINKc);
				//printf("ftype: %s\n", ftype.toChars());
				fd = new FuncDeclaration(Loc(0), Loc(0), Lexer.idPool(s), STCundefined, ftype);
				fd.fbody = fbody;
				fd.protection = PROT.PROTpublic;
				fd.linkage = LINKc;

				sc.module_.importedFrom.members.push(fd);

				sc = sc.push();
				sc.parent = sc.module_.importedFrom;
				sc.stc = STCundefined;
				sc.linkage = LINKc;
				fd.semantic(sc);
				fd.semantic2(sc);
				fd.semantic3(sc);
				sc.pop();
			}
			else
			{   /* In library, refer to it.
				 */
				fd = FuncDeclaration.genCfunc(type, s);
			}
			*sv = fd;	// cache symbol in hash table
		}

		/* Call the function fd(arguments)
		 */
		Expression ec = new VarExp(Loc(0), fd);
		Expression e = new CallExp(loc, ec, arguments);
		e.type = type;
		return e;
	}

    override int inlineCost(InlineCostState* ics)
	{
		return 1 + e1.inlineCost(ics) + e2.inlineCost(ics);
	}

    override Expression doInline(InlineDoState ids)
	{
		BinExp be = cast(BinExp)copy();

		be.e1 = e1.doInline(ids);
		be.e2 = e2.doInline(ids);
		return be;
	}

    override Expression inlineScan(InlineScanState* iss)
	{
		e1 = e1.inlineScan(iss);
		e2 = e2.inlineScan(iss);
		return this;
	}

    Expression op_overload(Scope sc)
	{
		//printf("BinExp.op_overload() (%s)\n", toChars());

		AggregateDeclaration ad;
		Type t1 = e1.type.toBasetype();
		Type t2 = e2.type.toBasetype();
		Identifier id = opId();
		Identifier id_r = opId_r();

		Match m;
		scope Expressions args1 = new Expressions();
		scope Expressions args2 = new Expressions();
		int argsset = 0;

		AggregateDeclaration ad1;
		if (t1.ty == TY.Tclass)
			ad1 = (cast(TypeClass)t1).sym;
		else if (t1.ty == TY.Tstruct)
			ad1 = (cast(TypeStruct)t1).sym;
		else
			ad1 = null;

		AggregateDeclaration ad2;
		if (t2.ty == TY.Tclass)
			ad2 = (cast(TypeClass)t2).sym;
		else if (t2.ty == TY.Tstruct)
			ad2 = (cast(TypeStruct)t2).sym;
		else
			ad2 = null;

		Dsymbol s = null;
		Dsymbol s_r = null;
		FuncDeclaration fd = null;
		TemplateDeclaration td = null;
		if (ad1 && id)
		{
			s = search_function(ad1, id);
		}
		if (ad2 && id_r)
		{
			s_r = search_function(ad2, id_r);
		}

		if (s || s_r)
		{
			/* Try:
			 *	a.opfunc(b)
			 *	b.opfunc_r(a)
			 * and see which is better.
			 */
			Expression e;
			FuncDeclaration lastf;

			args1.setDim(1);
			args1[0] = e1;
			args2.setDim(1);
			args2[0] = e2;
			argsset = 1;

			///memset(&m, 0, sizeof(m));
			m.last = MATCH.MATCHnomatch;

			if (s)
			{
				fd = s.isFuncDeclaration();
				if (fd)
				{
					overloadResolveX(&m, fd, null, args2);
				}
				else
				{
					td = s.isTemplateDeclaration();
					templateResolve(&m, td, sc, loc, null, null, args2);
				}
			}

			lastf = m.lastf;

			if (s_r)
			{
				fd = s_r.isFuncDeclaration();
				if (fd)
				{
					overloadResolveX(&m, fd, null, args1);
				}
				else
				{
					td = s_r.isTemplateDeclaration();
					templateResolve(&m, td, sc, loc, null, null, args1);
				}
			}

			if (m.count > 1)
			{
				// Error, ambiguous
				error("overloads %s and %s both match argument list for %s",
					m.lastf.type.toChars(),
					m.nextf.type.toChars(),
					m.lastf.toChars());
			}
			else if (m.last == MATCH.MATCHnomatch)
			{
				m.lastf = m.anyf;
			}

			if (op == TOK.TOKplusplus || op == TOK.TOKminusminus)
				// Kludge because operator overloading regards e++ and e--
				// as unary, but it's implemented as a binary.
				// Rewrite (e1 ++ e2) as e1.postinc()
				// Rewrite (e1 -- e2) as e1.postdec()
				e = build_overload(loc, sc, e1, null, id);
			else if (lastf && m.lastf == lastf || m.last == MATCH.MATCHnomatch)
				// Rewrite (e1 op e2) as e1.opfunc(e2)
				e = build_overload(loc, sc, e1, e2, id);
			else
				// Rewrite (e1 op e2) as e2.opfunc_r(e1)
				e = build_overload(loc, sc, e2, e1, id_r);
			return e;
		}

		if (isCommutative())
		{
			s = null;
			s_r = null;
			if (ad1 && id_r)
			{
				s_r = search_function(ad1, id_r);
			}
			if (ad2 && id)
			{
				s = search_function(ad2, id);
			}

			if (s || s_r)
			{
				/* Try:
				 *	a.opfunc_r(b)
				 *	b.opfunc(a)
				 * and see which is better.
				 */

				if (!argsset)
				{
					args1.setDim(1);
					args1[0] = e1;
					args2.setDim(1);
					args2[0] = e2;
				}

				///memset(&m, 0, sizeof(m));
				m.last = MATCH.MATCHnomatch;

				if (s_r)
				{
					fd = s_r.isFuncDeclaration();
					if (fd)
					{
						overloadResolveX(&m, fd, null, args2);
					}
					else
					{   td = s_r.isTemplateDeclaration();
						templateResolve(&m, td, sc, loc, null, null, args2);
					}
				}
				FuncDeclaration lastf = m.lastf;

				if (s)
				{
					fd = s.isFuncDeclaration();
					if (fd)
					{
						overloadResolveX(&m, fd, null, args1);
					}
					else
					{   td = s.isTemplateDeclaration();
						templateResolve(&m, td, sc, loc, null, null, args1);
					}
				}

				if (m.count > 1)
				{
					// Error, ambiguous
					error("overloads %s and %s both match argument list for %s",
						m.lastf.type.toChars(),
						m.nextf.type.toChars(),
						m.lastf.toChars());
				}
				else if (m.last == MATCH.MATCHnomatch)
				{
					m.lastf = m.anyf;
				}

				Expression e;
				if (lastf && m.lastf == lastf || id_r && m.last == MATCH.MATCHnomatch)
					// Rewrite (e1 op e2) as e1.opfunc_r(e2)
					e = build_overload(loc, sc, e1, e2, id_r);
				else
					// Rewrite (e1 op e2) as e2.opfunc(e1)
					e = build_overload(loc, sc, e2, e1, id);

				// When reversing operands of comparison operators,
				// need to reverse the sense of the op
				switch (op)
				{
					case TOK.TOKlt:		op = TOK.TOKgt;	break;
					case TOK.TOKgt:		op = TOK.TOKlt;	break;
					case TOK.TOKle:		op = TOK.TOKge;	break;
					case TOK.TOKge:		op = TOK.TOKle;	break;

					// Floating point compares
					case TOK.TOKule:	op = TOK.TOKuge; break;
					case TOK.TOKul:		op = TOK.TOKug;	 break;
					case TOK.TOKuge:	op = TOK.TOKule; break;
					case TOK.TOKug:		op = TOK.TOKul;	 break;

					// These are symmetric
					case TOK.TOKunord:
					case TOK.TOKlg:
					case TOK.TOKleg:
					case TOK.TOKue:
						break;
					default:
						break;	///
				}

				return e;
			}
		}

version (DMDV2) {
		// Try alias this on first operand
		if (ad1 && ad1.aliasthis)
		{
			/* Rewrite (e1 op e2) as:
			 *	(e1.aliasthis op e2)
			 */
			Expression e1 = new DotIdExp(loc, this.e1, ad1.aliasthis.ident);
			Expression e = copy();
			(cast(BinExp)e).e1 = e1;
			e = e.semantic(sc);
			return e;
		}

		// Try alias this on second operand
		if (ad2 && ad2.aliasthis)
		{
			/* Rewrite (e1 op e2) as:
			 *	(e1 op e2.aliasthis)
			 */
			Expression e2 = new DotIdExp(loc, this.e2, ad2.aliasthis.ident);
			Expression e = copy();
			(cast(BinExp)e).e2 = e2;
			e = e.semantic(sc);
			return e;
		}
}
		return null;
	}

    elem* toElemBin(IRState* irs, int op)
	{
		//printf("toElemBin() '%s'\n", toChars());

		tym_t tym = type.totym();

		elem* el = e1.toElem(irs);
		elem* er = e2.toElem(irs);
		elem* e = el_bin(op,tym,el,er);
		el_setLoc(e,loc);

		return e;
	}
	final void AssignExp_buildArrayIdent(OutBuffer buf, Expressions arguments, string Str)
	{
		/* Evaluate assign expressions right to left
		 */
		e2.buildArrayIdent(buf, arguments);
		e1.buildArrayIdent(buf, arguments);
		buf.writestring(Str);
		buf.writestring("ass");
	}

	final void Exp_buildArrayIdent(OutBuffer buf, Expressions arguments, string Str)
	{
		/* Evaluate assign expressions left to right
		 */
		e1.buildArrayIdent(buf, arguments);
		e2.buildArrayIdent(buf, arguments);
		buf.writestring(Str);
	}

	final Expression AssignExp_buildArrayLoop(AssignExpType)(Parameters fparams)// if (is (AssignExpType : AssignExp))
	{
		/* Evaluate assign expressions right to left
		 */
		Expression ex2 = e2.buildArrayLoop(fparams);
		Expression ex1 = e1.buildArrayLoop(fparams);
		auto param = fparams[0];
		param.storageClass = STCundefined;
		Expression e = new AssignExpType(Loc(0), ex1, ex2);
		return e;
	}

	final Expression Exp_buildArrayLoop(ExpType)(Parameters fparams) if (is (ExpType : BinExp))
	{
		/* Evaluate assign expressions left to right
		 */
		Expression ex1 = e1.buildArrayLoop(fparams);
		Expression ex2 = e2.buildArrayLoop(fparams);
		Expression e = new ExpType(Loc(0), ex1, ex2);
		return e;
	}
}
