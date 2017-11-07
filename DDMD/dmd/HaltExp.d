module dmd.HaltExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.Type;
import dmd.HdrGenState;
import dmd.Loc;
import dmd.TOK;

import dmd.backend.Util;
import dmd.backend.OPER;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

class HaltExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc)
	{
		register();
		super(loc, TOK.TOKhalt, HaltExp.sizeof);
	}

	override Expression semantic(Scope sc)
	{
version (LOGSEMANTIC) {
		printf("HaltExp.semantic()\n");
}
		type = Type.tvoid;
		return this;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("halt");
	}

	override bool checkSideEffect(int flag)
	{
		return true;
	}

	override elem* toElem(IRState* irs)
	{
		elem *e;

		e = el_calloc();
		e.Ety = TYvoid;
		e.Eoper = OPhalt;
		el_setLoc(e,loc);
		return e;
	}
}

