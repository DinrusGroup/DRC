module dmd.TemplateExp;

import dmd.common;
import dmd.Expression;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.HdrGenState;
import dmd.TemplateDeclaration;
import dmd.TOK;

import dmd.DDMDExtensions;

class TemplateExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	TemplateDeclaration td;

	this(Loc loc, TemplateDeclaration td)
	{
		register();
		super(loc, TOK.TOKtemplate, TemplateExp.sizeof);
		//printf("TemplateExp(): %s\n", td.toChars());
		this.td = td;
	}

	override void rvalue()
	{
		error("template %s has no value", toChars());
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring(td.toChars());
	}
}

