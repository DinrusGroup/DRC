module dmd.CompileExp;

import dmd.common;
import dmd.Expression;
import dmd.UnaExp;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.PREC;
import dmd.WANT;
import dmd.StringExp;
import dmd.Type;
import dmd.Parser;

import dmd.expression.Util;

import dmd.DDMDExtensions;

class CompileExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		register();
		super(loc, TOK.TOKmixin, this.sizeof, e);
	}

	override Expression semantic(Scope sc)
	{
		version (LOGSEMANTIC) {
			printf("CompileExp.semantic('%s')\n", toChars());
		}
		UnaExp.semantic(sc);
		e1 = resolveProperties(sc, e1);
		e1 = e1.optimize(WANT.WANTvalue | WANT.WANTinterpret);
		if (e1.op != TOK.TOKstring)
		{	error("argument to mixin must be a string, not (%s)", e1.toChars());
			type = Type.terror;
			return this;
		}
		StringExp se = cast(StringExp)e1;
		se = se.toUTF8(sc);
		Parser p = new Parser(sc.module_, cast(ubyte*)se.string_, se.len, 0);
		p.loc = loc;
		p.nextToken();
		//printf("p.loc.linnum = %d\n", p.loc.linnum);
		Expression e = p.parseExpression();
		if (p.token.value != TOK.TOKeof)
			error("incomplete mixin expression (%s)", se.toChars());
		return e.semantic(sc);
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("mixin(");
		expToCBuffer(buf, hgs, e1, PREC.PREC_assign);
		buf.writeByte(')');
	}
}
