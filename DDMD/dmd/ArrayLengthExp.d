module dmd.ArrayLengthExp;

import dmd.common;
import dmd.Expression;
import dmd.GlobalExpressions;
import dmd.IntegerExp;
import dmd.BinExp;
import dmd.backend.elem;
import dmd.UnaExp;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.Type;
import dmd.WANT;
import dmd.VarExp;
import dmd.PREC;
import dmd.VarDeclaration;
import dmd.PtrExp;
import dmd.Lexer;
import dmd.Identifier;
import dmd.ExpInitializer;
import dmd.DeclarationExp;
import dmd.CommaExp;
import dmd.AssignExp;
import dmd.AddrExp;

import dmd.expression.ArrayLength;
import dmd.expression.Util;

import dmd.backend.Util;
import dmd.backend.OPER;

import dmd.DDMDExtensions;

class ArrayLengthExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1)
	{
		register();
		super(loc, TOK.TOKarraylength, ArrayLengthExp.sizeof, e1);
	}

	override Expression semantic(Scope sc)
	{
	version (LOGSEMANTIC) {
		printf("ArrayLengthExp::semantic('%s')\n", toChars());
	}
		if (!type)
		{
			UnaExp.semantic(sc);
			e1 = resolveProperties(sc, e1);

			type = Type.tsize_t;
		}
		return this;
	}

	static Expression rewriteOpAssign(BinExp exp)
	{
		Expression e;

		assert(exp.e1.op == TOKarraylength);
		auto ale = cast(ArrayLengthExp)exp.e1;
		if (ale.e1.op == TOK.TOKvar)
		{
		    e = opAssignToOp(exp.loc, exp.op, ale, exp.e2);
		    e = new AssignExp(exp.loc, ale.syntaxCopy(), e);
		}
		else
		{
		    /*    auto tmp = &array;
		     *    (*tmp).length = (*tmp).length op e2
		     */
		    Identifier id = Lexer.uniqueId("__arraylength");
		    ExpInitializer ei = new ExpInitializer(ale.loc, new AddrExp(ale.loc, ale.e1));
		    VarDeclaration tmp = new VarDeclaration(ale.loc, ale.e1.type.pointerTo(), id, ei);

		    Expression e1 = new ArrayLengthExp(ale.loc, new PtrExp(ale.loc, new VarExp(ale.loc, tmp)));
		    Expression elvalue = e1.syntaxCopy();
		    e = opAssignToOp(exp.loc, exp.op, e1, exp.e2);
		    e = new AssignExp(exp.loc, elvalue, e);
		    e = new CommaExp(exp.loc, new DeclarationExp(ale.loc, tmp), e);
		}
		return e;
	}
    
	override Expression optimize(int result)
	{
		//printf("ArrayLengthExp::optimize(result = %d) %s\n", result, toChars());
		e1 = e1.optimize(WANTvalue | (result & WANTinterpret));
		Expression e = this;
		if (e1.op == TOKstring || e1.op == TOKarrayliteral || e1.op == TOKassocarrayliteral)
		{
			e = ArrayLength(type, e1);
		}
		return e;
	}

	override Expression interpret(InterState istate)
	{
		Expression e;
		Expression e1;

version (LOG) {
		printf("ArrayLengthExp.interpret() %s\n", toChars());
}
		e1 = this.e1.interpret(istate);
		if (e1 is EXP_CANT_INTERPRET)
			goto Lcant;
		if (e1.op == TOKstring || e1.op == TOKarrayliteral || e1.op == TOKassocarrayliteral)
		{
			e = ArrayLength(type, e1);
		}
		else if (e1.op == TOKnull)
		{
			e = new IntegerExp(loc, 0, type);
		}
		else
			goto Lcant;
		return e;

	Lcant:
		return EXP_CANT_INTERPRET;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.writestring(".length");
	}

	override elem* toElem(IRState* irs)
	{
		elem *e = e1.toElem(irs);
		e = el_una(OP64_32, type.totym(), e);
		el_setLoc(e,loc);
		return e;
	}
}

