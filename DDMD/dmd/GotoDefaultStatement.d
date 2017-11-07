module dmd.GotoDefaultStatement;

import dmd.common;
import dmd.Statement;
import dmd.SwitchStatement;
import dmd.Loc;
import dmd.Scope;
import dmd.Expression;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.IRState;
import dmd.BE;

import dmd.backend.block;
import dmd.backend.Blockx;
import dmd.backend.Util;
import dmd.backend.BC;

import dmd.DDMDExtensions;

class GotoDefaultStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    SwitchStatement sw;

    this(Loc loc)
	{
		register();
		super(loc);
		sw = null;
	}

    override Statement syntaxCopy()
	{
		GotoDefaultStatement s = new GotoDefaultStatement(loc);
		return s;
	}

    override Statement semantic(Scope sc)
	{
		sw = sc.sw;
		if (!sw)
			error("goto default not in switch statement");
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
		buf.writestring("goto default;\n");
	}

    override void toIR(IRState *irs)
	{
		block *b;
		Blockx *blx = irs.blx;
		block *bdest = irs.getDefaultBlock();

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
		block_next(blx,BCgoto,null);
	}
}
