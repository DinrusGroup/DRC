module dmd.FileExp;

import dmd.common;
import dmd.Expression;
import dmd.File;
import dmd.UnaExp;
import dmd.StringExp;
import dmd.WANT;
import dmd.Global;
import dmd.FileName;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.TOK;

import core.stdc.stdio;

import dmd.DDMDExtensions;

class FileExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		register();
		super(loc, TOKmixin, FileExp.sizeof, e);
	}

	override Expression semantic(Scope sc)
	{
		StringExp se;

	version (LOGSEMANTIC) {
		printf("FileExp.semantic('%.*s')\n", toChars());
	}
		UnaExp.semantic(sc);
		e1 = resolveProperties(sc, e1);
		e1 = e1.optimize(WANTvalue);
		if (e1.op != TOKstring)
		{	
			error("file name argument must be a string, not (%s)", e1.toChars());
			goto Lerror;
		}
		se = cast(StringExp)e1;
		se = se.toUTF8(sc);

		string name = (cast(immutable(char)*)se.string_)[0..se.len];

		if (!global.params.fileImppath)
		{	
			error("need -Jpath switch to import text file %s", name);
			goto Lerror;
		}

		if (name != FileName.name(name))
		{	
			error("use -Jpath switch to provide path for filename %s", name);
			goto Lerror;
		}

		name = FileName.searchPath(global.filePath, name, 0);
		if (!name)
		{	
			error("file %s cannot be found, check -Jpath", se.toChars());
			goto Lerror;
		}

		if (global.params.verbose)
			printf("file      %s\t(%s)\n", cast(char*)se.string_, name);

		{	
			scope File f = new File(name);
			if (f.read())
			{   
				error("cannot read file %s", f.toChars());
				goto Lerror;
			}
			else
			{
				f.ref_ = 1;
				se = new StringExp(loc, (cast(immutable(char)*)f.buffer)[0..f.len]);
			}
		}
	  Lret:
		return se.semantic(sc);

	  Lerror:
		se = new StringExp(loc, "");
		goto Lret;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
}

