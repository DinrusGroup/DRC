module dmd.PragmaStatement;

import dmd.common;
import dmd.expression.Util;
import dmd.Statement;
import dmd.StringExp;
import dmd.Id;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Loc;
import dmd.Identifier;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.IRState;
import dmd.BE;
import dmd.TOK;
import dmd.WANT;

import dmd.DDMDExtensions;

class PragmaStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

	Identifier ident;
	Expressions args;		// array of Expression's
	Statement body_;

	this(Loc loc, Identifier ident, Expressions args, Statement body_)
	{
		register();
		super(loc);
		this.ident = ident;
		this.args = args;
		this.body_ = body_;
	}
	
	override Statement syntaxCopy()
	{
		Statement b = null;
		if (body_)
		b = body_.syntaxCopy();
		PragmaStatement s = new PragmaStatement(loc,
			ident, Expression.arraySyntaxCopy(args), b);
		return s;

	}
	
	override Statement semantic(Scope sc)
	{
		// Should be merged with PragmaDeclaration
		//writef("PragmaStatement.semantic() %s\n", toChars());
		//writef("body = %p\n", body_);
		if (ident == Id.msg)
		{
			if (args)
			{
				foreach (Expression e; args)
				{
					e = e.semantic(sc);
					e = e.optimize(WANTvalue | WANTinterpret);
					if (e.op == TOK.TOKstring)
					{
						StringExp se = cast(StringExp)e;
						writef("%.*s", se.len, cast(char*)se.string_);
					}
					else
						writef(e.toChars());
				}
				writef("\n");
			}
		}
		else if (ident == Id.lib)
		{
static if (true)
{
			/* Should this be allowed?
			 */
			error("pragma(lib) not allowed as statement");
}
else
{
			if (!args || args.dim != 1)
				error("string expected for library name");
			else
			{
				Expression e = args[0];
	
				e = e.semantic(sc);
				e = e.optimize(WANTvalue | WANTinterpret);
				args[0] = e;
				if (e.op != TOKstring)
					error("string expected for library name, not '%s'", e.toChars());
				else if (global.params.verbose)
				{
					StringExp se = cast(StringExp)e;
					writef("library   %.*s\n", se.len, se.string_);
				}
			}
}
		}
//version(DMDV2) // TODO:
//{
		else if (ident == Id.startaddress)
		{
			if (!args || args.dim != 1)
				error("function name expected for start address");
			else
			{
				Expression e = args[0];
				e = e.semantic(sc);
				e = e.optimize(WANTvalue | WANTinterpret);
				args[0] = e;
				Dsymbol sa = getDsymbol(e);
				if (!sa || !sa.isFuncDeclaration())
					error("function name expected for start address, not '%s'", e.toChars());
				if (body_)
				{
					body_ = body_.semantic(sc);
				}
				return this;
			}
		}
//}
		else
			error("unrecognized pragma(%s)", ident.toChars());

		if (body_)
		{
		body_ = body_.semantic(sc);
		}
		return body_;
	}
	
	override bool usesEH()
	{
		return body_ && body_.usesEH();
	}
	
	override BE blockExit()
	{
		BE result = BEfallthru;
static if (false) // currently, no code is generated for Pragma's, so it's just fallthru
{
		if (arrayExpressionCanThrow(args))
			result |= BEthrow;
		if (body_)
			result |= body_.blockExit();
}
			return result;
	}
	
	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("pragma (");
		buf.writestring(ident.toChars());
		if (args && args.dim)
		{
			buf.writestring(", ");
			argsToCBuffer(buf, args, hgs);
		}
		buf.writeByte(')');
		if (body_)
		{
			buf.writenl();
			buf.writeByte('{');
			buf.writenl();
	
			body_.toCBuffer(buf, hgs);
	
			buf.writeByte('}');
			buf.writenl();
		}
		else
		{
			buf.writeByte(';');
			buf.writenl();
		}

	}
	
	override void toIR(IRState* irs)
	{
		assert(false);
	}
}
