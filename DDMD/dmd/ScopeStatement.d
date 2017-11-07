module dmd.ScopeStatement;

import dmd.common;
import dmd.Statement;
import dmd.Loc;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.InterState;
import dmd.InlineScanState;
import dmd.ScopeDsymbol;
import dmd.ArrayTypes;
import dmd.CompoundStatement;
import dmd.IRState;
import dmd.BE;

import dmd.backend.Blockx;
import dmd.backend.BC;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class ScopeStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement statement;

    this(Loc loc, Statement s)
	{
		register();
		super(loc);
		this.statement = s;
	}
	
    override Statement syntaxCopy()
	{
		Statement s = statement ? statement.syntaxCopy() : null;
		s = new ScopeStatement(loc, s);
		return s;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writeByte('{');
		buf.writenl();

		if (statement)
			statement.toCBuffer(buf, hgs);

		buf.writeByte('}');
		buf.writenl();
	}
	
    override ScopeStatement isScopeStatement() { return this; }
	
    override Statement semantic(Scope sc)
	{
		ScopeDsymbol sym;

		//printf("ScopeStatement.semantic(sc = %p)\n", sc);
		if (statement)
		{	
			Statements a;

			sym = new ScopeDsymbol();
			sym.parent = sc.scopesym;
			sc = sc.push(sym);

			a = statement.flatten(sc);
			if (a)
			{
				statement = new CompoundStatement(loc, a);
			}

			statement = statement.semantic(sc);
			if (statement)
			{
				Statement sentry;
				Statement sexception;
				Statement sfinally;

				statement.scopeCode(sc, &sentry, &sexception, &sfinally);
				if (sfinally)
				{
					//printf("adding sfinally\n");
					statement = new CompoundStatement(loc, statement, sfinally);
				}
			}

			sc.pop();
		}
		return this;
	}
	
    override bool hasBreak()
	{
		//printf("ScopeStatement.hasBreak() %s\n", toChars());
		return statement ? statement.hasBreak() : false;
	}
	
    override bool hasContinue()
	{
		return statement ? statement.hasContinue() : false;
	}
	
    override bool usesEH()
	{
		return statement ? statement.usesEH() : false;
	}
	
    override BE blockExit()
	{
		//printf("ScopeStatement::blockExit(%p)\n", statement);
		return statement ? statement.blockExit() : BE.BEfallthru;
	}
	
    override bool comeFrom()
	{
		//printf("ScopeStatement.comeFrom()\n");
    return statement ? statement.comeFrom() : false;
	}
	
    override bool isEmpty()
	{
		//printf("ScopeStatement::isEmpty() %d\n", statement ? statement->isEmpty() : TRUE);
		return statement ? statement.isEmpty() : true;
	}
	
    override Expression interpret(InterState istate)
	{
version(LOG)
		writef("ScopeStatement::interpret()\n");

		if (istate.start is this)
			istate.start = null;
		return statement ? statement.interpret(istate) : null;
	}

    override Statement inlineScan(InlineScanState* iss)
	{
		if (statement)
			statement = statement.inlineScan(iss);
		return this;
	}

    override void toIR(IRState* irs)
	{
		if (statement)
		{
			Blockx* blx = irs.blx;
			IRState mystate = IRState(irs,this);

			if (mystate.prev.ident)
				mystate.ident = mystate.prev.ident;

			statement.toIR(&mystate);

			if (mystate.breakBlock)
				block_goto(blx, BC.BCgoto, mystate.breakBlock);
		}
	}
}
