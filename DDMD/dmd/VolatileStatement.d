module dmd.VolatileStatement;

import dmd.common;
import dmd.Statement;
import dmd.ArrayTypes;
import dmd.Scope;
import dmd.Loc;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.BE;

import dmd.backend.block;
import dmd.backend.Blockx;
import dmd.backend.Util;
import dmd.backend.BC;
import dmd.backend.elem;
import dmd.backend.OPER;
import dmd.backend.mTY;
//import dmd.backend.BFL;

import dmd.DDMDExtensions;

class VolatileStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement statement;

    this(Loc loc, Statement statement)
	{
		register();
		super(loc);
		this.statement = statement;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
    override Statement semantic(Scope sc)
	{
		if (statement)
			statement = statement.semantic(sc);
		return this;
	}
	
    override Statements flatten(Scope sc)
	{
		Statements a = statement ? statement.flatten(sc) : null;
		if (a)
		{	
			foreach (ref Statement s; a)
			{   
				s = new VolatileStatement(loc, s);
			}
		}

		return a;
	}
	
    override BE blockExit()
	{
		return statement ? statement.blockExit() : BE.BEfallthru;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("volatile");
		if (statement)
		{   
			if (statement.isScopeStatement())
				buf.writenl();
			else
				buf.writebyte(' ');
			statement.toCBuffer(buf, hgs);
		}
	}

    override Statement inlineScan(InlineScanState* iss)
	{
		if (statement)
			statement = statement.inlineScan(iss);
		return this;
	}

    static void el_setVolatile(elem* e)
	{
		while (1)
		{
			e.Ety |= mTYvolatile;
			if (OTunary(e.Eoper))
				e = e.E1;
			else if (OTbinary(e.Eoper))
			{
				el_setVolatile(e.E2);
				e = e.E1;
			}
			else
				break;
		}
	}

    override void toIR(IRState* irs)
	{
		block* b;

		if (statement)
		{
			Blockx* blx = irs.blx;

			block_goto(blx, BCgoto, null);
			b = blx.curblock;

			statement.toIR(irs);

			block_goto(blx, BCgoto, null);

			// Mark the blocks generated as volatile
			for (; b != blx.curblock; b = b.Bnext)
			{   
				b.Bflags |= BFL.BFLvolatile;
				if (b.Belem)
					el_setVolatile(b.Belem);
			}
		}
	}
}
