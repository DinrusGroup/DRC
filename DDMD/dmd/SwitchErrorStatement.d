module dmd.SwitchErrorStatement;

import dmd.common;
import dmd.Statement;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.BE;

import dmd.backend.elem;
import dmd.backend.Blockx;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.OPER;
import dmd.backend.RTLSYM;

import dmd.DDMDExtensions;

class SwitchErrorStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc)
	{
		register();
		super(loc);
	}

	override BE blockExit()
	{
		return BE.BEthrow;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("SwitchErrorStatement.toCBuffer()");
		buf.writenl();
	}

	override void toIR(IRState* irs)
	{
		elem* e;
		elem* elinnum;
		elem* efilename;
		Blockx* blx = irs.blx;

		//printf("SwitchErrorStatement.toIR()\n");

		efilename = blx.module_.toEmodulename();
		elinnum = el_long(TYM.TYint, loc.linnum);
		e = el_bin(OPER.OPcall, TYM.TYvoid, el_var(rtlsym[RTLSYM_DSWITCHERR]), el_param(elinnum, efilename));
		block_appendexp(blx.curblock, e);
	}
}

