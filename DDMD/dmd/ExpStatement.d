module dmd.ExpStatement;

import dmd.common;
import dmd.Loc;
import dmd.Statement;
import dmd.AssertExp;
import dmd.Expression;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Scope;
import dmd.InterState;
import dmd.InlineCostState;
import dmd.InlineDoState;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.BE;
import dmd.TOK;
import dmd.GlobalExpressions;
import dmd.DeclarationStatement;
import dmd.Util : printf;

import dmd.backend.Blockx;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class ExpStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;

    this(Loc loc, Expression exp)
	{
		register();
		super(loc);
		this.exp = exp;
	}
	
	/*
	~this()
	{
		delete exp;
	}
	*/
    override Statement syntaxCopy()
	{
		Expression e = exp ? exp.syntaxCopy() : null;
		ExpStatement es = new ExpStatement(loc, e);
		return es;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		if (exp)
			exp.toCBuffer(buf, hgs);
		buf.writeByte(';');
		if (!hgs.FLinit.init)
			buf.writenl();
	}
	
    override Statement semantic(Scope sc)
	{
		if (exp)
		{
			//printf("ExpStatement::semantic() %s\n", exp->toChars());
			exp = exp.semantic(sc);
			exp = resolveProperties(sc, exp);
			exp.checkSideEffect(0);
			exp = exp.optimize(0);
			if (exp.op == TOK.TOKdeclaration && !isDeclarationStatement())
			{   
				Statement s = new DeclarationStatement(loc, exp);
				return s;
			}
			//exp = exp.optimize(isDeclarationStatement() ? WANT.WANTvalue : 0);
		}
		return this;
	}

    override Expression interpret(InterState istate)
	{
version (LOG)
{
		printf("ExpStatement.interpret(%s)\n", exp ? exp.toChars() : "");
}
		mixin(START);
		if (exp)
		{
			Expression e = exp.interpret(istate);
			if (e is EXP_CANT_INTERPRET)
			{
				//printf("-ExpStatement.interpret(): %p\n", e);
				return EXP_CANT_INTERPRET;
			}
		}
		return null;
	}

    override BE blockExit()
	{
		BE result = BE.BEfallthru;

		if (exp)
		{
			if (exp.op == TOK.TOKhalt)
				return BE.BEhalt;
			if (exp.op == TOK.TOKassert)
			{   	
				AssertExp a = cast(AssertExp)exp;

				if (a.e1.isBool(false))	// if it's an assert(0)
					return BE.BEhalt;
			}
			if (exp.canThrow())
				result |= BE.BEthrow;
		}
		return result;
	}
    
    override bool isEmpty()
    {
    	return (exp is null);
    }

    override int inlineCost(InlineCostState* ics)
	{
		return exp ? exp.inlineCost(ics) : 0;
	}

    override Expression doInline(InlineDoState ids)
	{
	version (LOG)
	{
		if (exp) writef("ExpStatement.doInline() '%s'\n", exp.toChars());
	}
		return exp ? exp.doInline(ids) : null;
	}

    override Statement inlineScan(InlineScanState* iss)
	{
	version (LOG) {
		printf("ExpStatement.inlineScan(%s)\n", toChars());
	}
		if (exp)
			exp = exp.inlineScan(iss);
		return this;
	}

    override void toIR(IRState* irs)
	{
		Blockx* blx = irs.blx;

		//printf("ExpStatement.toIR(), exp = %s\n", exp ? exp.toChars() : "");
		incUsage(irs, loc);
		if (exp) 
			block_appendexp(blx.curblock, exp.toElem(irs));
	}
}
