module dmd.StaticAssert;

import dmd.common;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.ScopeDsymbol;
import dmd.Loc;
import dmd.Scope;
import dmd.Id;
import dmd.WANT;
import dmd.Global;
import dmd.Util;

import dmd.DDMDExtensions;

class StaticAssert : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));

	Expression exp;
	Expression msg;

	this(Loc loc, Expression exp, Expression msg)
	{
		register();
		super(Id.empty);

		this.loc = loc;
		this.exp = exp;
		this.msg = msg;
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		StaticAssert sa;

		assert(!s);
		sa = new StaticAssert(loc, exp.syntaxCopy(), msg ? msg.syntaxCopy() : null);
		return sa;
	}

	override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
	{
		return false;		// we didn't add anything
	}

	override void semantic(Scope sc)
	{
	}

	override void semantic2(Scope sc)
	{
		Expression e;

		//printf("StaticAssert::semantic2() %s\n", toChars());
		e = exp.semantic(sc);
		e = e.optimize(WANT.WANTvalue | WANT.WANTinterpret);
		if (e.isBool(false))
		{
			if (msg)
			{   
				HdrGenState hgs;
				scope OutBuffer buf = new OutBuffer();

				msg = msg.semantic(sc);
				msg = msg.optimize(WANT.WANTvalue | WANT.WANTinterpret);
				hgs.console = 1;
				msg.toCBuffer(buf, &hgs);
				error("%s", buf.toChars());
			}
			else
				error("(%s) is false", exp.toChars());

			if (sc.tinst)
				sc.tinst.printInstantiationTrace();

			if (!global.gag)
				fatal();
		}
		else if (!e.isBool(true))
		{
			error("(%s) is not evaluatable at compile time", exp.toChars());
		}
	}

	override void inlineScan()
	{
	}

	override bool oneMember(Dsymbol* ps)
	{
		//printf("StaticAssert.oneMember())\n");
		*ps = null;
		return true;
	}

	override void toObjFile(int multiobj)
	{
	}

	override string kind()
	{
		return "static assert";
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring(kind());
		buf.writeByte('(');
		exp.toCBuffer(buf, hgs);
		if (msg)
		{
			buf.writeByte(',');
			msg.toCBuffer(buf, hgs);
		}
		buf.writestring(");");
		buf.writenl();
	}
}
