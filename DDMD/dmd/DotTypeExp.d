module dmd.DotTypeExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.UnaExp;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.Dsymbol;
import dmd.TOK;
import dmd.PREC;
import dmd.expression.Util;

import dmd.backend.Util;

import dmd.DDMDExtensions;

class DotTypeExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	Dsymbol sym;

	this(Loc loc, Expression e, Dsymbol s)
	{
		register();
		super(loc, TOK.TOKdottype, DotTypeExp.sizeof, e);
		this.sym = s;
		this.type = s.getType();
	}

	override Expression semantic(Scope sc)
	{
	version (LOGSEMANTIC) {
		printf("DotTypeExp.semantic('%s')\n", toChars());
	}
		UnaExp.semantic(sc);
		return this;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC.PREC_primary);
		buf.writeByte('.');
		buf.writestring(sym.toChars());
	}

	override elem* toElem(IRState* irs)
	{
		// Just a pass-thru to e1
		elem *e;

		//printf("DotTypeExp.toElem() %s\n", toChars());
		e = e1.toElem(irs);
		el_setLoc(e,loc);
		return e;
	}
}

