module dmd.FileInitExp;

import dmd.common;
import dmd.Expression;
import dmd.Loc;
import dmd.Scope;
import dmd.DefaultInitExp;
import dmd.StringExp;
import dmd.TOK;
import dmd.Util;
import dmd.Type;

import dmd.DDMDExtensions;

class FileInitExp : DefaultInitExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc)
	{
		register();
		super(loc, TOK.TOKfile, this.sizeof);
	}

	override Expression semantic(Scope sc)
	{
		type = Type.tchar.invariantOf().arrayOf();
		return this;
	}

	override Expression resolveLoc(Loc loc, Scope sc)
	{
		//printf("FileInitExp::resolve() %.*s\n", toChars());
		string s = loc.filename ? loc.filename : sc.module_.ident.toChars();
		Expression e = new StringExp(loc, s);
		e = e.semantic(sc);
		e = e.castTo(sc, type);
		return e;
	}
}
