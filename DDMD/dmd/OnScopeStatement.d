module dmd.OnScopeStatement;

import dmd.common;
import dmd.Statement;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Scope;
import dmd.IRState;
import dmd.TOK;
import dmd.Loc;
import dmd.BE;
import dmd.Identifier;
import dmd.ExpInitializer;
import dmd.Token;
import dmd.IntegerExp;
import dmd.VarDeclaration;
import dmd.Type;
import dmd.AssignExp;
import dmd.VarExp;
import dmd.NotExp;
import dmd.IfStatement;
import dmd.DeclarationStatement;
import dmd.ExpStatement;
import dmd.Expression;
import dmd.Lexer;

import dmd.DDMDExtensions;

class OnScopeStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    TOK tok;
    Statement statement;

    this(Loc loc, TOK tok, Statement statement)
	{
		register();
		super(loc);

		this.tok = tok;
		this.statement = statement;
	}

    override Statement syntaxCopy()
	{
		OnScopeStatement s = new OnScopeStatement(loc,
			tok, statement.syntaxCopy());
		return s;
	}

    override BE blockExit()
	{
		// At this point, this statement is just an empty placeholder
		return BE.BEfallthru;
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring(Token.toChars(tok));
		buf.writebyte(' ');
		statement.toCBuffer(buf, hgs);
	}

    override Statement semantic(Scope sc)
	{
		/* semantic is called on results of scopeCode() */
		return this;
	}

    override bool usesEH()
	{
		assert(false);
	}

    override void scopeCode(Scope sc, Statement* sentry, Statement* sexception, Statement* sfinally)
	{
		//printf("OnScopeStatement::scopeCode()\n");
		//print();
		*sentry = null;
		*sexception = null;
		*sfinally = null;
		switch (tok)
		{
			case TOKon_scope_exit:
				*sfinally = statement;
				break;

			case TOKon_scope_failure:
				*sexception = statement;
				break;

			case TOKon_scope_success:
			{
				/* Create:
				 *	sentry:   int x = 0;
				 *	sexception:    x = 1;
				 *	sfinally: if (!x) statement;
				 */
				Identifier id = Lexer.uniqueId("__os");

				ExpInitializer ie = new ExpInitializer(loc, new IntegerExp(0));
				VarDeclaration v = new VarDeclaration(loc, Type.tint32, id, ie);
				*sentry = new DeclarationStatement(loc, v);

				Expression e = new IntegerExp(1);
				e = new AssignExp(Loc(0), new VarExp(Loc(0), v), e);
				*sexception = new ExpStatement(Loc(0), e);

				e = new VarExp(Loc(0), v);
				e = new NotExp(Loc(0), e);
				*sfinally = new IfStatement(Loc(0), null, e, statement, null);

				break;
			}

			default:
				assert(0);
		}
	}

    override void toIR(IRState* irs)
	{
	}
}
