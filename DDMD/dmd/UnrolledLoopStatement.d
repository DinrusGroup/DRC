module dmd.UnrolledLoopStatement;

import dmd.common;
import dmd.GlobalExpressions;
import dmd.Expression;
import dmd.Statement;
import dmd.InterState;
import dmd.ArrayTypes;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.InlineCostState;
import dmd.InlineDoState;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.BE;

import dmd.backend.BC;
import dmd.backend.Blockx;
import dmd.backend.block;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class UnrolledLoopStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

	Statements statements;

	this(Loc loc, Statements s)
	{
		register();
		super(loc);
		statements = s;
	}

	override Statement syntaxCopy()
	{
		assert(false);
	}

	override Statement semantic(Scope sc)
	{
		//printf("UnrolledLoopStatement.semantic(this = %p, sc = %p)\n", this, sc);

		sc.noctor++;
		Scope scd = sc.push();
		scd.sbreak = this;
		scd.scontinue = this;

		foreach(ref Statement s; statements)
		{
			if (s)
			{
				s = s.semantic(scd);
			}
		}

		scd.pop();
		sc.noctor--;
		return this;
	}

	override bool hasBreak()
	{
		assert(false);
	}

	override bool hasContinue()
	{
		assert(false);
	}

	override bool usesEH()
	{
		assert(false);
	}

	override BE blockExit()
	{
		BE result = BEfallthru;
		foreach (s; statements)
		{	
			if (s)
			{
				int r = s.blockExit();
				result |= r & ~(BEbreak | BEcontinue);
			}
		}
		return result;
	}

	override bool comeFrom()
	{
		assert(false);
	}

	override Expression interpret(InterState istate)
	{
		Expression e = null;

	version (LOG) {
		printf("UnrolledLoopStatement.interpret()\n");
	}
		if (istate.start == this)
			istate.start = null;
		if (statements)
		{
			for (size_t i = 0; i < statements.dim; i++)
			{   
				Statement s = statements[i];

				e = s.interpret(istate);
				if (e is EXP_CANT_INTERPRET)
					break;
				if (e is EXP_CONTINUE_INTERPRET)
				{	
					e = null;
					continue;
				}
				if (e is EXP_BREAK_INTERPRET)
				{	
					e = null;
					break;
				}
				if (e)
					break;
			}
		}
		return e;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

	override int inlineCost(InlineCostState* ics)
	{
		int cost = 0;

		foreach (Statement s; statements)
		{	
			if (s)
			{
				cost += s.inlineCost(ics);
				if (cost >= COST_MAX)
					break;
			}
		}
		return cost;
	}

	override Expression doInline(InlineDoState ids)
	{
		assert(false);
	}

	override Statement inlineScan(InlineScanState* iss)
	{
		foreach (ref Statement s; statements)
		{	
			if (s)
				s = s.inlineScan(iss);
		}
		return this;
	}

	override void toIR(IRState* irs)
	{
		Blockx* blx = irs.blx;

		IRState mystate = IRState(irs, this);
		mystate.breakBlock = block_calloc(blx);

		block* bpre = blx.curblock;
		block_next(blx, BCgoto, null);

		block* bdo = blx.curblock;
		list_append(&bpre.Bsucc, bdo);

		block* bdox;

		foreach (s; statements)
		{
			if (s !is null)
			{
				mystate.contBlock = block_calloc(blx);

				s.toIR(&mystate);

				bdox = blx.curblock;
				block_next(blx, BCgoto, mystate.contBlock);
				list_append(&bdox.Bsucc, mystate.contBlock);
			}
		}

		bdox = blx.curblock;
		block_next(blx, BCgoto, mystate.breakBlock);
		list_append(&bdox.Bsucc, mystate.breakBlock);
	}
}

