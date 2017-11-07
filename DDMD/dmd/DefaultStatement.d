module dmd.DefaultStatement;

import dmd.common;
import dmd.Statement;
import dmd.Loc;
import dmd.Scope;
import dmd.Expression;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.BE;

import dmd.backend.Util;
import dmd.backend.OPER;
import dmd.backend.Blockx;
import dmd.backend.block;
import dmd.backend.BC;

import dmd.DDMDExtensions;

class DefaultStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement statement;
version (IN_GCC) {
    block* cblock = null;	// back end: label for the block
}

    this(Loc loc, Statement s)
	{
		register();
		super(loc);
		this.statement = s;
	}
	
    override Statement syntaxCopy()
	{
		DefaultStatement s = new DefaultStatement(loc, statement.syntaxCopy());
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		//printf("DefaultStatement.semantic()\n");
		if (sc.sw)
		{
			if (sc.sw.sdefault)
			{
				error("switch statement already has a default");
			}
			sc.sw.sdefault = this;

			if (sc.sw.tf !is sc.tf)
				error("switch and default are in different finally blocks");

			if (sc.sw.isFinal)
				error("default statement not allowed in final switch statement");
		}
		else
			error("default not in switch statement");
		statement = statement.semantic(sc);
		return this;
	}
	
    override bool usesEH()
	{
		return statement.usesEH();
	}
	
    override BE blockExit()
	{
		return statement.blockExit();
	}
	
    override bool comeFrom()
	{
		return true;
	}
	
    override Expression interpret(InterState istate)
	{
		assert(false);
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("default:\n");
		statement.toCBuffer(buf, hgs);
	}

    override Statement inlineScan(InlineScanState* iss)
	{
		if (statement)
			statement = statement.inlineScan(iss);
		return this;
	}

    override void toIR(IRState* irs)
	{
		Blockx* blx = irs.blx;
		block* bcase = blx.curblock;
		block* bdefault = irs.getDefaultBlock();
		block_next(blx,BCgoto,bdefault);
		list_append(&bcase.Bsucc,blx.curblock);
		if (blx.tryblock != irs.getSwitchBlock().Btry)
			error("default cannot be in different try block level from switch");
		incUsage(irs, loc);
		if (statement)
			statement.toIR(irs);
	}
}
