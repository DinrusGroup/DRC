module dmd.ForStatement;

import dmd.common;
import dmd.Statement;
import dmd.Expression;
import dmd.GlobalExpressions;
import dmd.Loc;
import dmd.Scope;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.WANT;
import dmd.ScopeDsymbol;
import dmd.IRState;
import dmd.BE;

import dmd.backend.Blockx;
import dmd.backend.block;
import dmd.backend.Util;
import dmd.backend.BC;

import dmd.DDMDExtensions;

class ForStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement init;
    Expression condition;
    Expression increment;
    Statement body_;

    this(Loc loc, Statement init, Expression condition, Expression increment, Statement body_)
	{
		register();
		super(loc);
		
		this.init = init;
		this.condition = condition;
		this.increment = increment;
		this.body_ = body_;
	}

    override Statement syntaxCopy()
	{
		Statement i = null;
		if (init)
			i = init.syntaxCopy();
		Expression c = null;
		if (condition)
			c = condition.syntaxCopy();
		Expression inc = null;
		if (increment)
			inc = increment.syntaxCopy();
		ForStatement s = new ForStatement(loc, i, c, inc, body_.syntaxCopy());
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		ScopeDsymbol sym = new ScopeDsymbol();
		sym.parent = sc.scopesym;
		sc = sc.push(sym);
		if (init)
			init = init.semantic(sc);
		sc.noctor++;
		if (condition)
		{
			condition = condition.semantic(sc);
			condition = resolveProperties(sc, condition);
			condition = condition.optimize(WANTvalue);
			condition = condition.checkToBoolean();
		}
		if (increment)
		{
			increment = increment.semantic(sc);
			increment = resolveProperties(sc, increment);
			increment = increment.optimize(0);
		}

		sc.sbreak = this;
		sc.scontinue = this;
		if (body_)
			body_ = body_.semantic(sc);
		sc.noctor--;

		sc.pop();
		return this;
	}
	
    override void scopeCode(Scope sc, Statement* sentry, Statement* sexception, Statement* sfinally)
	{
		//printf("ForStatement::scopeCode()\n");
		//print();
		if (init)
			init.scopeCode(sc, sentry, sexception, sfinally);
		else
			Statement.scopeCode(sc, sentry, sexception, sfinally);
	}
	
    override bool hasBreak()
	{
		//printf("ForStatement.hasBreak()\n");
		return true;
	}
	
    override bool hasContinue()
	{
		return true;
	}
	
    override bool usesEH()
	{
		return (init && init.usesEH()) || body_.usesEH();
	}
	
    override BE blockExit()
	{
		BE result = BE.BEfallthru;

		if (init)
		{	
			result = init.blockExit();
			if (!(result & BE.BEfallthru))
				return result;
		}
		if (condition)
		{	
			if (condition.canThrow())
				result |= BE.BEthrow;
			if (condition.isBool(true))
				result &= ~BE.BEfallthru;
			else if (condition.isBool(false))
				return result;
		}
		else
			result &= ~BE.BEfallthru;	// the body must do the exiting
		if (body_)
		{	
			int r = body_.blockExit();
			if (r & (BE.BEbreak | BE.BEgoto))
				result |= BE.BEfallthru;
			result |= r & ~(BE.BEfallthru | BE.BEbreak | BE.BEcontinue);
		}
		if (increment && increment.canThrow())
			result |= BE.BEthrow;
		return result;
	}
	
    override bool comeFrom()
	{
		//printf("ForStatement.comeFrom()\n");
		if (body_)
		{	
			bool result = body_.comeFrom();
			//printf("result = %d\n", result);
			return result;
		}
		return false;
	}
	
    override Expression interpret(InterState istate)
	{
version (LOG) {
		printf("ForStatement.interpret()\n");
}
		if (istate.start == this)
			istate.start = null;
		
		Expression e;

		if (init)
		{
			e = init.interpret(istate);
			if (e is EXP_CANT_INTERPRET)
				return e;
			assert(!e);
		}

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

		while (true)
		{
			if (!condition)
				goto Lhead;
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
			Lhead:
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
				if (increment)
				{
					e = increment.interpret(istate);
					if (e is EXP_CANT_INTERPRET)
						break;
				}
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
		buf.writestring("for (");
		if (init)
		{
			hgs.FLinit.init++;
			init.toCBuffer(buf, hgs);
			hgs.FLinit.init--;
		}
		else
			buf.writebyte(';');
		if (condition)
		{   buf.writebyte(' ');
			condition.toCBuffer(buf, hgs);
		}
		buf.writebyte(';');
		if (increment)
		{   
			buf.writebyte(' ');
			increment.toCBuffer(buf, hgs);
		}
		buf.writebyte(')');
		buf.writenl();
		buf.writebyte('{');
		buf.writenl();
		body_.toCBuffer(buf, hgs);
		buf.writebyte('}');
		buf.writenl();
	}
	
    override Statement inlineScan(InlineScanState* iss)
	{
		if (init)
			init = init.inlineScan(iss);
		if (condition)
			condition = condition.inlineScan(iss);
		if (increment)
			increment = increment.inlineScan(iss);
		if (body_)
			body_ = body_.inlineScan(iss);
		return this;
	}
	
    override void toIR(IRState* irs)
	{
		Blockx* blx = irs.blx;

		IRState mystate = IRState(irs,this);
		mystate.breakBlock = block_calloc(blx);
		mystate.contBlock = block_calloc(blx);

		if (init)
			init.toIR(&mystate);
		block* bpre = blx.curblock;
		block_next(blx,BCgoto,null);
		block* bcond = blx.curblock;
		list_append(&bpre.Bsucc, bcond);
		list_append(&mystate.contBlock.Bsucc, bcond);
		if (condition)
		{
			incUsage(irs, condition.loc);
			block_appendexp(bcond, condition.toElem(&mystate));
			block_next(blx,BCiftrue,null);
			list_append(&bcond.Bsucc, blx.curblock);
			list_append(&bcond.Bsucc, mystate.breakBlock);
		}
		else
		{
			/* No conditional, it's a straight goto
			 */
			block_next(blx,BCgoto,null);
			list_append(&bcond.Bsucc, blx.curblock);
		}

		if (body_)
			body_.toIR(&mystate);
		/* End of the body goes to the continue block
		 */
		list_append(&blx.curblock.Bsucc, mystate.contBlock);
		block_next(blx, BCgoto, mystate.contBlock);

		if (increment)
		{
			incUsage(irs, increment.loc);
			block_appendexp(mystate.contBlock, increment.toElem(&mystate));
		}

		/* The 'break' block follows the for statement.
		 */
		block_next(blx,BCgoto, mystate.breakBlock);
	}
}
