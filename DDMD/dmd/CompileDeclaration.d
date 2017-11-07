module dmd.CompileDeclaration;

import dmd.common;
import dmd.AttribDeclaration;
import dmd.WANT;
import dmd.TOK;
import dmd.StringExp;
import dmd.Parser;
import dmd.Expression;
import dmd.ScopeDsymbol;
import dmd.Dsymbol;
import dmd.Loc;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.WANT;
import dmd.StringExp;
import dmd.Parser;

import dmd.DDMDExtensions;

// Mixin declarations

class CompileDeclaration : AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;
    ScopeDsymbol sd;
    bool compiled;

	this(Loc loc, Expression exp)
	{
		register();

		super(null);
		//printf("CompileDeclaration(loc = %d)\n", loc.linnum);
		this.loc = loc;
		this.exp = exp;
		this.sd = null;
		this.compiled = false;
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		//printf("CompileDeclaration.syntaxCopy('%s')\n", toChars());
		CompileDeclaration sc = new CompileDeclaration(loc, exp.syntaxCopy());
		return sc;
	}

    override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
	{
		//printf("CompileDeclaration.addMember(sc = %p, memnum = %d)\n", sc, memnum);
		bool m = false;
		this.sd = sd;
		if (!memnum)
		{	/* No members yet, so parse the mixin now
			 */
			compileIt(sc);
			memnum = AttribDeclaration.addMember(sc, sd, memnum);
			compiled = true;
		}
		return memnum;
	}

	void compileIt(Scope sc)
	{
		//printf("CompileDeclaration.compileIt(loc = %d)\n", loc.linnum);
		exp = exp.semantic(sc);
		exp = resolveProperties(sc, exp);
		exp = exp.optimize(WANT.WANTvalue | WANT.WANTinterpret);
		if (exp.op != TOK.TOKstring)
		{	exp.error("argument to mixin must be a string, not (%s)", exp.toChars());
		}
		else
		{
			StringExp se = cast(StringExp)exp;
			se = se.toUTF8(sc);
			scope Parser p = new Parser(sc.module_, cast(ubyte*)se.string_, se.len, 0);
			p.loc = loc;
			p.nextToken();
			decl = p.parseDeclDefs(0);
			if (p.token.value != TOK.TOKeof)
				exp.error("incomplete mixin declaration (%s)", se.toChars());
		}
	}

	override void semantic(Scope sc)
	{
		//printf("CompileDeclaration.semantic()\n");

		if (!compiled)
		{
			compileIt(sc);
			AttribDeclaration.addMember(sc, sd, 0);
			compiled = 1;
		}
		AttribDeclaration.semantic(sc);
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("mixin(");
		exp.toCBuffer(buf, hgs);
		buf.writestring(");");
		buf.writenl();
	}
}
