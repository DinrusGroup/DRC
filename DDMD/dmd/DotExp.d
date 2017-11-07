module dmd.DotExp;

import dmd.common;
import dmd.Expression;
import dmd.Loc;
import dmd.Scope;
import dmd.ScopeExp;
import dmd.TemplateDeclaration;
import dmd.DotTemplateExp;
import dmd.BinExp;
import dmd.TOK;

import dmd.DDMDExtensions;

class DotExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOKdotexp, DotExp.sizeof, e1, e2);
	}

	override Expression semantic(Scope sc)
	{
version (LOGSEMANTIC) {
		printf("DotExp.semantic('%s')\n", toChars());
		if (type) printf("\ttype = %s\n", type.toChars());
}
		e1 = e1.semantic(sc);
		e2 = e2.semantic(sc);
		if (e2.op == TOKimport)
		{
			ScopeExp se = cast(ScopeExp)e2;
			TemplateDeclaration td = se.sds.isTemplateDeclaration();
			if (td)
			{   
				Expression e = new DotTemplateExp(loc, e1, td);
				e = e.semantic(sc);
				return e;
			}
		}
		if (!type)
			type = e2.type;
		return this;
	}
}

