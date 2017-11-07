module dmd.ContinueStatement;

import dmd.common;
import dmd.interpret.Util;
import dmd.Statement;
import dmd.FuncDeclaration;
import dmd.GlobalExpressions;
import dmd.IntegerExp;
import dmd.ReturnStatement;
import dmd.LabelStatement;
import dmd.Identifier;
import dmd.Loc;
import dmd.Scope;
import dmd.Expression;
import dmd.InterState;
import dmd.HdrGenState;
import dmd.OutBuffer;
import dmd.IRState;
import dmd.BE;

import dmd.backend.Util;
import dmd.backend.BC;
import dmd.backend.block;
import dmd.backend.Blockx;

import dmd.DDMDExtensions;

class ContinueStatement : Statement
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
		ContinueStatement s = new ContinueStatement(loc, ident);
		return s;
	}

    override Statement semantic(Scope sc)
	{
		//printf("ContinueStatement.semantic() %p\n", this);
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
						for (; scx; scx = scx.enclosing)
						{
							ls = scx.slabel;
							if (ls && ls.ident == ident && ls.statement == sc.fes)
							{
								// Replace continue ident; with return 0;
								return new ReturnStatement(Loc(0), new IntegerExp(0));
							}
						}

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
					break;			// can't continue to it
				}

				ls = scx.slabel;
				if (ls && ls.ident == ident)
				{
					Statement s = ls.statement;

					if (!s.hasContinue())
						error("label '%s' has no continue", ident.toChars());
					if (ls.tf != sc.tf)
						error("cannot continue out of finally block");
					return this;
				}
			}
			error("enclosing label '%s' for continue not found", ident.toChars());
		}
		else if (!sc.scontinue)
		{
			if (sc.fes)
			{   
				Statement s;

				// Replace continue; with return 0;
				s = new ReturnStatement(Loc(0), new IntegerExp(0));
				return s;
			}
			error("continue is not inside a loop");
		}
		return this;
	}
	
    override Expression interpret(InterState istate)
	{
version(LOG)
        writef("ContinueStatement::interpret()\n");

        mixin(START);
        if (ident)
            return EXP_CANT_INTERPRET;
        else
            return EXP_CONTINUE_INTERPRET;
	}

    override BE blockExit()
	{
		return ident ? BE.BEgoto : BE.BEcontinue;
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("continue");
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
		block* bcont;
		block* b;
		Blockx* blx = irs.blx;

		//printf("ContinueStatement.toIR() %p\n", this);
		bcont = irs.getContBlock(ident);
		assert(bcont);
		b = blx.curblock;
		incUsage(irs, loc);

		// Adjust exception handler scope index if in different try blocks
		if (b.Btry != bcont.Btry)
		{
			//setScopeIndex(blx, b, bcont.Btry ? bcont.Btry.Bscope_index : -1);
		}

		/* Nothing more than a 'goto' to the current continue destination
		 */
		list_append(&b.Bsucc, bcont);
		block_next(blx, BCgoto, null);
	}
}
