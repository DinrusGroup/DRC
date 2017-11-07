module dmd.TryFinallyStatement;

import dmd.common;
import dmd.Statement;
import dmd.Loc;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Scope;
import dmd.InlineScanState;
import dmd.CompoundStatement;
import dmd.IRState;
import dmd.BE;

import dmd.backend.block;
import dmd.backend.Blockx;
import dmd.backend.BC;
import dmd.backend.Util;

import dmd.codegen.Util;

import dmd.DDMDExtensions;

class TryFinallyStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement body_;
    Statement finalbody;

    this(Loc loc, Statement body_, Statement finalbody)
	{
		register();
		super(loc);
		this.body_ = body_;
		this.finalbody = finalbody;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.printf("try\n{\n");
		body_.toCBuffer(buf, hgs);
		buf.printf("}\nfinally\n{\n");
		finalbody.toCBuffer(buf, hgs);
		buf.writeByte('}');
		buf.writenl();
	}
	
    override Statement semantic(Scope sc)
	{
		//printf("TryFinallyStatement::semantic()\n");
		body_ = body_.semantic(sc);
		sc = sc.push();
		sc.tf = this;
		sc.sbreak = null;
		sc.scontinue = null;	// no break or continue out of finally block
		finalbody = finalbody.semantic(sc);
		sc.pop();
		if (!body_)
			return finalbody;
		if (!finalbody)
			return body_;
		if (body_.blockExit() == BE.BEfallthru)
		{	
			Statement s = new CompoundStatement(loc, body_, finalbody);
			return s;
		}
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
		if (body_)
			return body_.blockExit();
		return BE.BEfallthru;
	}

    override Statement inlineScan(InlineScanState* iss)
	{
		if (body_)
			body_ = body_.inlineScan(iss);
		if (finalbody)
			finalbody = finalbody.inlineScan(iss);
		return this;
	}

	/****************************************
	 * A try-finally statement.
	 * Builds the following:
	 *	_try
	 *	block
	 *	_finally
	 *	finalbody
	 *	_ret
	 */
    override void toIR(IRState* irs)
	{
		//printf("TryFinallyStatement.toIR()\n");
		Blockx* blx = irs.blx;

	version (SEH) {
		nteh_declarvars(blx);
	}

		block* tryblock = block_goto(blx, BCgoto, null);

		int previndex = blx.scope_index;
		tryblock.Blast_index = previndex;
		tryblock.Bscope_index = blx.next_index++;
		blx.scope_index = tryblock.Bscope_index;

		// Current scope index
		setScopeIndex(blx,tryblock,tryblock.Bscope_index);

		blx.tryblock = tryblock;
		block_goto(blx,BC_try,null);

		IRState bodyirs = IRState(irs, this);
		block* breakblock = block_calloc(blx);
		block* contblock = block_calloc(blx);

		if (body_)
			body_.toIR(&bodyirs);
		blx.tryblock = tryblock.Btry;	// back to previous tryblock

		setScopeIndex(blx,blx.curblock,previndex);
		blx.scope_index = previndex;

		block_goto(blx,BCgoto, breakblock);
		block* finallyblock = block_goto(blx,BCgoto,contblock);

		list_append(&tryblock.Bsucc,finallyblock);

		block_goto(blx,BC_finally,null);

		IRState finallyState = IRState(irs, this);
		breakblock = block_calloc(blx);
		contblock = block_calloc(blx);

		setScopeIndex(blx, blx.curblock, previndex);
		if (finalbody)
			finalbody.toIR(&finallyState);
		block_goto(blx, BCgoto, contblock);
		block_goto(blx, BCgoto, breakblock);

		block* retblock = blx.curblock;
		block_next(blx,BC_ret,null);

		list_append(&finallyblock.Bsucc, blx.curblock);
		list_append(&retblock.Bsucc, blx.curblock);
	}
}
