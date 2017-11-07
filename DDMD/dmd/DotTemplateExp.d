module dmd.DotTemplateExp;

import dmd.common;
import dmd.Expression;
import dmd.UnaExp;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.TOK;
import dmd.PREC;
import dmd.HdrGenState;
import dmd.TemplateDeclaration;

import dmd.expression.Util;

import dmd.DDMDExtensions;

class DotTemplateExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	TemplateDeclaration td;

	this(Loc loc, Expression e, TemplateDeclaration td)
	{
		register();
		super(loc, TOK.TOKdottd, this.sizeof, e);
		this.td = td;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
	    expToCBuffer(buf, hgs, e1, PREC.PREC_primary);
	    buf.writeByte('.');
	    buf.writestring(td.toChars());
	}
}

