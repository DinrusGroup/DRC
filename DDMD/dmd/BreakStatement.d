module dmd.BreakStatement;

import dmd.common;
import dmd.Statement;
import dmd.Loc;
import dmd.Identifier;
import dmd.Scope;
import dmd.Expression;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.IRState;
import dmd.BE;
import dmd.FuncDeclaration;
import dmd.LabelStatement;
import dmd.ReturnStatement;
import dmd.IntegerExp;

import dmd.backend.Util;
import dmd.backend.block;
import dmd.backend.Blockx;
import dmd.backend.BC;

import dmd.DDMDExtensions;

class BreakStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Identifier ident;

    this(Loc loc, Identifier ident)
	{
		register();

		super(loc);
		this.ident = ident;
	}
	
    override Statement syntaxCopy()
	{
		BreakStatement s = new BreakStatement(loc, ident);
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		//printf("BreakStatement::semantic()\n");
		// If:
		//	break Identifier;
		if (ident)
		{
			Scope scx;
			FuncDeclaration thisfunc = sc.func;

			for (scx = sc; scx; scx = scx.enclosing)
			{
				LabelStatement ls;

				if (scx.func != thisfunc)	// if in enclosing function
				{
					if (sc.fes)		// if this is the body of a foreach
					{
						/* Post this statement to the fes, and replace
						 * it with a return value that caller will put into
						 * a switch. Caller will figure out where the break
						 * label actually is.
						 * Case numbers start with 2, not 0, as 0 is continue
						 * and 1 is break.
						 */
						Statement s;
						sc.fes.cases.push(cast(void*)this);
						s = new ReturnStatement(Loc(0), new IntegerExp(sc.fes.cases.dim + 1));
						return s;
					}
					break;			// can't break to it
				}

				ls = scx.slabel;
				if (ls && ls.ident == ident)
				{
					Statement s = ls.statement;

					if (!s.hasBreak())
						error("label '%s' has no break", ident.toChars());
					if (ls.tf != sc.tf)
						error("cannot break out of finally block");
					return this;
				}
			}
			error("enclosing label '%s' for break not found", ident.toChars());
		}
		else if (!sc.sbreak)
		{
			if (sc.fes)
			{   
				Statement s;

				// Replace break; with return 1;
				s = new ReturnStatement(Loc(0), new IntegerExp(1));
				return s;
			}
			error("break is not inside a loop or switch");
		}
		return this;
	}

    override Expression interpret(InterState istate)
	{
		assert(false);
	}
	
    override BE blockExit()
	{
		//printf("BreakStatement::blockExit(%p) = x%x\n", this, ident ? BEgoto : BEbreak);
		return ident ? BE.BEgoto : BE.BEbreak;
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("break");
		if (ident)
		{   
			buf.writebyte(' ');
			buf.writestring(ident.toChars());
		}
		buf.writebyte(';');
		buf.writenl();
	}

    override void toIR(IRState* irs)
	{
		block* bbreak;
		block* b;
		Blockx* blx = irs.blx;

		bbreak = irs.getBreakBlock(ident);
		assert(bbreak);
		b = blx.curblock;
		incUsage(irs, loc);

		// Adjust exception handler scope index if in different try blocks
		if (b.Btry != bbreak.Btry)
		{
			//setScopeIndex(blx, b, bbreak.Btry ? bbreak.Btry.Bscope_index : -1);
		}

		/* Nothing more than a 'goto' to the current break destination
		 */
		list_append(&b.Bsucc, bbreak);
		block_next(blx, BCgoto, null);
	}
}
