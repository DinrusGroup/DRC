module dmd.ThrowStatement;

import dmd.common;
import dmd.Statement;
import dmd.Expression;
import dmd.Loc;
import dmd.IRState;
import dmd.InlineScanState;
import dmd.HdrGenState;
import dmd.OutBuffer;
import dmd.Scope;
import dmd.Expression;
import dmd.FuncDeclaration;
import dmd.BE;

import dmd.backend.Util;
import dmd.backend.Blockx;
import dmd.backend.elem;
import dmd.backend.RTLSYM;
import dmd.backend.OPER;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

class ThrowStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;

    this(Loc loc, Expression exp)
	{
		register();
		super(loc);
		this.exp = exp;
	}
	
    override Statement syntaxCopy()
	{
		ThrowStatement s = new ThrowStatement(loc, exp.syntaxCopy());
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		//printf("ThrowStatement::semantic()\n");

		FuncDeclaration fd = sc.parent.isFuncDeclaration();
		fd.hasReturnExp |= 2;

version(DMDV1) {
        // See bugzilla 3388. Should this be or not?
		if (sc.incontract)
			error("Throw statements cannot be in contracts");
}
		exp = exp.semantic(sc);
		exp = resolveProperties(sc, exp);
		if (!exp.type.toBasetype().isClassHandle())
			error("can only throw class objects, not type %s", exp.type.toChars());
		return this;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.printf("throw ");
		exp.toCBuffer(buf, hgs);
		buf.writeByte(';');
		buf.writenl();
	}
	
    override BE blockExit()
	{
		return BE.BEthrow;  // obviously
	}

    override Statement inlineScan(InlineScanState* iss)
	{
		if (exp)
			exp = exp.inlineScan(iss);
		return this;
	}

    override void toIR(IRState* irs)
	{
		// throw(exp)

		Blockx *blx = irs.blx;

		incUsage(irs, loc);
		elem *e = exp.toElem(irs);
	static if (false) {
		e = el_bin(OPcall, TYvoid, el_var(rtlsym[RTLSYM_LTHROW]),e);
	} else {
		e = el_bin(OPcall, TYvoid, el_var(rtlsym[RTLSYM_THROW]),e);
	}
		block_appendexp(blx.curblock, e);
	}
}
