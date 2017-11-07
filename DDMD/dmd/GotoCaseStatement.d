module dmd.GotoCaseStatement;

import dmd.common;
import dmd.Statement;
import dmd.Expression;
import dmd.CaseStatement;
import dmd.IRState;
import dmd.Scope;
import dmd.Loc;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.BE;
import dmd.WANT;

import dmd.backend.Util;
import dmd.backend.block;
import dmd.backend.BC;
import dmd.backend.Blockx;

import dmd.DDMDExtensions;

class GotoCaseStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;		// NULL, or which case to goto
    CaseStatement cs;		// case statement it resolves to

    this(Loc loc, Expression exp)
	{
		register();
		super(loc);
		cs = null;
		this.exp = exp;
	}
	
    override Statement syntaxCopy()
	{
		Expression e = exp ? exp.syntaxCopy() : null;
		GotoCaseStatement s = new GotoCaseStatement(loc, e);
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		if (exp)
			exp = exp.semantic(sc);

		if (!sc.sw)
			error("goto case not in switch statement");
		else
		{
			sc.sw.gotoCases.push(cast(void*)this);
			if (exp)
			{
				exp = exp.implicitCastTo(sc, sc.sw.condition.type);
				exp = exp.optimize(WANTvalue);
			}
		}
		return this;
	}
	
    override Expression interpret(InterState istate)
	{
		assert(false);
	}
	
    override BE blockExit()
	{
		return BEgoto;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("goto case");
		if (exp)
		{   
			buf.writebyte(' ');
			exp.toCBuffer(buf, hgs);
		}
		buf.writebyte(';');
		buf.writenl();
	}

    override void toIR(IRState* irs)
	{
		block* b;
		Blockx* blx = irs.blx;
		block* bdest = cs.cblock;

		if (!bdest)
		{
			bdest = block_calloc(blx);
			cs.cblock = bdest;
		}

		b = blx.curblock;

		// The rest is equivalent to GotoStatement

		// Adjust exception handler scope index if in different try blocks
		if (b.Btry != bdest.Btry)
		{
			// Check that bdest is in an enclosing try block
			for (block* bt = b.Btry; bt != bdest.Btry; bt = bt.Btry)
			{
				if (!bt)
				{
					//printf("b.Btry = %p, bdest.Btry = %p\n", b.Btry, bdest.Btry);
					error("cannot goto into try block");
					break;
				}
			}

			//setScopeIndex(blx, b, bdest.Btry ? bdest.Btry.Bscope_index : -1);
		}

		list_append(&b.Bsucc,bdest);
		incUsage(irs, loc);
		block_next(blx, BC.BCgoto, null);
	}
}
