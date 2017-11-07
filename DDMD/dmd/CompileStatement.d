module dmd.CompileStatement;

import dmd.common;
import dmd.Statement;
import dmd.Expression;
import dmd.Loc;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.ArrayTypes;
import dmd.TOK;
import dmd.WANT;
import dmd.ParseStatementFlags;
import dmd.Parser;
import dmd.CompoundStatement;
import dmd.StringExp;

import dmd.DDMDExtensions;

class CompileStatement : Statement
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
		Expression e = exp.syntaxCopy();
		CompileStatement es = new CompileStatement(loc, e);
		return es;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("mixin(");
		exp.toCBuffer(buf, hgs);
		buf.writestring(");");
		if (!hgs.FLinit.init)
			buf.writenl();
	}

	override Statements flatten(Scope sc)
	{
		//printf("CompileStatement::flatten() %s\n", exp->toChars());
		exp = exp.semantic(sc);
		exp = resolveProperties(sc, exp);
		exp = exp.optimize(WANT.WANTvalue | WANT.WANTinterpret);
		if (exp.op != TOK.TOKstring)
		{	error("argument to mixin must be a string, not (%s)", exp.toChars());
			return null;
		}
		StringExp se = cast(StringExp)exp;
		se = se.toUTF8(sc);
		Parser p = new Parser(sc.module_, cast(ubyte *)se.string_, se.len, 0);
		p.loc = loc;
		p.nextToken();

		Statements a = new Statements();
		while (p.token.value != TOK.TOKeof)
		{
			Statement s = p.parseStatement(ParseStatementFlags.PSsemi | ParseStatementFlags.PScurlyscope);
			a.push(s);
		}
		return a;
	}

	override Statement semantic(Scope sc)
	{
		//printf("CompileStatement::semantic() %s\n", exp->toChars());
		Statements a = flatten(sc);
		if (!a)
			return null;
		Statement s = new CompoundStatement(loc, a);
		return s.semantic(sc);
	}
}
