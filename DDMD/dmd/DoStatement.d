module dmd.DoStatement;

import dmd.common;
import dmd.Statement;
import dmd.Expression;
import dmd.Loc;
import dmd.Scope;
import dmd.InterState;
import dmd.GlobalExpressions;
import dmd.HdrGenState;
import dmd.OutBuffer;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.BE;
import dmd.WANT;

import dmd.backend.block;
import dmd.backend.Blockx;
import dmd.backend.Util;
import dmd.backend.BC;

import dmd.DDMDExtensions;

class DoStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement body_;
    Expression condition;

    this(Loc loc, Statement b, Expression c)
	{
		register();
		super(loc);
		body_ = b;
		condition = c;
	}
	
    override Statement syntaxCopy()
	{
		DoStatement s = new DoStatement(loc, body_ ? body_.syntaxCopy() : null, condition.syntaxCopy());
		return s;
	}

    override Statement semantic(Scope sc)
	{
		sc.noctor++;
		if (body_)
			body_ = body_.semanticScope(sc, this, this);
		sc.noctor--;
		condition = condition.semantic(sc);
		condition = resolveProperties(sc, condition);
		condition = condition.optimize(WANTvalue);

		condition = condition.checkToBoolean();

		return this;
	}

    override bool hasBreak()
	{
		return true;
	}

    override bool hasContinue()
	{
		return true;
	}

    override bool usesEH()
	{
		return body_ ? body_.usesEH() : false;
	}

    override BE blockExit()
	{
		BE result;

		if (body_)
		{	
			result = body_.blockExit();
			if (result == BE.BEbreak)
				return BE.BEfallthru;
			if (result & BE.BEcontinue)
				result |= BE.BEfallthru;
		}
		else
			result = BE.BEfallthru;

		if (result & BE.BEfallthru)
		{	
			if (condition.canThrow())
				result |= BE.BEthrow;
			if (!(result & BE.BEbreak) && condition.isBool(true))
				result &= ~BE.BEfallthru;
		}
		result &= ~(BE.BEbreak | BE.BEcontinue);

		return result;
	}

    override bool comeFrom()
	{
		assert(false);
	}

    override Expression interpret(InterState istate)
	{
version(LOG)
		writef("DoStatement::interpret()\n");

		if (istate.start == this)
			istate.start = null;
		Expression e;

		if (istate.start)
		{
			e = body_ ? body_.interpret(istate) : null;
			if (istate.start)
				return null;
			if (e is EXP_CANT_INTERPRET)
				return e;
			if (e is EXP_BREAK_INTERPRET)
				return null;
			if (e is EXP_CONTINUE_INTERPRET)
				goto Lcontinue;
			if (e)
				return e;
		}

		while (1)
		{
			e = body_ ? body_.interpret(istate) : null;
			if (e is EXP_CANT_INTERPRET)
				break;
			if (e is EXP_BREAK_INTERPRET)
			{
				e = null;
				break;
			}
			if (e && e !is EXP_CONTINUE_INTERPRET)
				break;

		Lcontinue:
			e = condition.interpret(istate);
			if (e is EXP_CANT_INTERPRET)
				break;
			if (!e.isConst())
			{
				e = EXP_CANT_INTERPRET;
				break;
			}
			if (e.isBool(true))
			{
			}
			else if (e.isBool(false))
			{
				e = null;
				break;
			}
			else
				assert(0);
		}
		return e;
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
	    buf.writestring("do");
		buf.writenl();
		if (body_)
			body_.toCBuffer(buf, hgs);
		buf.writestring("while (");
		condition.toCBuffer(buf, hgs);
		buf.writebyte(')');
	}

    override Statement inlineScan(InlineScanState* iss)
	{
		body_ = body_ ? body_.inlineScan(iss) : null;
		condition = condition.inlineScan(iss);
		return this;
	}

    override void toIR(IRState* irs)
	{
		Blockx *blx = irs.blx;

		IRState mystate = IRState(irs,this);
		mystate.breakBlock = block_calloc(blx);
		mystate.contBlock = block_calloc(blx);

		block* bpre = blx.curblock;
		block_next(blx, BCgoto, null);
		list_append(&bpre.Bsucc, blx.curblock);

		list_append(&mystate.contBlock.Bsucc, blx.curblock);
		list_append(&mystate.contBlock.Bsucc, mystate.breakBlock);

		if (body_)
			body_.toIR(&mystate);
		list_append(&blx.curblock.Bsucc, mystate.contBlock);

		block_next(blx, BCgoto, mystate.contBlock);
		incUsage(irs, condition.loc);
		block_appendexp(mystate.contBlock, condition.toElem(&mystate));
		block_next(blx, BCiftrue, mystate.breakBlock);
	}
}
