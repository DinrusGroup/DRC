module dmd.CompoundStatement;

import dmd.common;
import dmd.Loc;
import dmd.Statement;
import dmd.Array;
import dmd.TryCatchStatement;
import dmd.TryFinallyStatement;
import dmd.Catch;
import dmd.ScopeStatement;
import dmd.Identifier;
import dmd.Lexer;
import dmd.ThrowStatement;
import dmd.IdentifierExp;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.ArrayTypes;
import dmd.ReturnStatement;
import dmd.Expression;
import dmd.InterState;
import dmd.InlineDoState;
import dmd.InlineCostState;
import dmd.InlineScanState;
import dmd.IfStatement;
import dmd.IRState;
import dmd.BE;
import dmd.Util;

import dmd.DDMDExtensions;

class CompoundStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statements statements;

    this(Loc loc, Statements s)
	{
		register();
		super(loc);
		statements = s;
	}
	
    this(Loc loc, Statement s1, Statement s2)
	{
		register();
		super(loc);
		
		statements = new Statements();
		statements.reserve(2);
		statements.push(s1);
		statements.push(s2);
	}
	
    override Statement syntaxCopy()
	{
		Statements a = new Statements();
		a.setDim(statements.dim);

		foreach (size_t i, Statement s; statements)
		{	
			if (s)
				s = s.syntaxCopy();
			a[i] = s;
		}

		return new CompoundStatement(loc, a);
	}
	
	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		foreach (s; statements)
		{
			if (s)
				s.toCBuffer(buf, hgs);
		}
	}
	
	override Statement semantic(Scope sc)
	{
		Statement s;

		//printf("CompoundStatement.semantic(this = %p, sc = %p)\n", this, sc);

		for (size_t i = 0; i < statements.dim; )
		{
			s = statements[i];
			if (s)
			{   
				Statements a = s.flatten(sc);

				if (a)
				{
					statements.remove(i);
					statements.insert(i, a);
					continue;
				}
				
				s = s.semantic(sc);

				statements[i] = s;
				if (s)
				{
					Statement sentry;
					Statement sexception;
					Statement sfinally;

					s.scopeCode(sc, &sentry, &sexception, &sfinally);
					if (sentry)
					{
						sentry = sentry.semantic(sc);
						if (s.isDeclarationStatement())
						{	
							statements.insert(i, sentry);
							i++;
						}
						else
							statements[i] = sentry;
					}
					if (sexception)
					{
						if (i + 1 == statements.dim && !sfinally)
						{
		static if (true) {
						sexception = sexception.semantic(sc);
		} else {
						statements.push(sexception);
						if (sfinally)
							// Assume sexception does not throw
							statements.push(sfinally);
		}
						}
						else
						{
							/* Rewrite:
							 *	s; s1; s2;
							 * As:
							 *	s;
							 *	try { s1; s2; }
							 *	catch (Object __o)
							 *	{ sexception; throw __o; }
							 */
							Statement body_;
							Statements aa = new Statements();

							for (int j = i + 1; j < statements.dim; j++)
							{
								aa.push(statements[j]);
							}
							body_ = new CompoundStatement(Loc(0), aa);
							body_ = new ScopeStatement(Loc(0), body_);

							Identifier id = Lexer.uniqueId("__o");

							Statement handler = new ThrowStatement(Loc(0), new IdentifierExp(Loc(0), id));
							handler = new CompoundStatement(Loc(0), sexception, handler);

							Array catches = new Array();
							Catch ctch = new Catch(Loc(0), null, id, handler);
							catches.push(cast(void*)ctch);
							s = new TryCatchStatement(Loc(0), body_, catches);

							if (sfinally)
								s = new TryFinallyStatement(Loc(0), s, sfinally);
							s = s.semantic(sc);
							statements.setDim(i + 1);
							statements.push(s);
							break;
						}
					}
					else if (sfinally)
					{
						if (0 && i + 1 == statements.dim)
						{
							statements.push(sfinally);
						}
						else
						{
							/* Rewrite:
							 *	s; s1; s2;
							 * As:
							 *	s; try { s1; s2; } finally { sfinally; }
							 */
							Statement body_;
							Statements aa = new Statements();

							for (int j = i + 1; j < statements.dim; j++)
							{
								aa.push(statements[j]);
							}
							body_ = new CompoundStatement(Loc(0), aa);
							s = new TryFinallyStatement(Loc(0), body_, sfinally);
							s = s.semantic(sc);
							statements.setDim(i + 1);
							statements.push(s);
							break;
						}
					}
				}
			}
			i++;
		}
		if (statements.dim == 1)
		{
			return statements[0];
		}
		return this;
	}
	
    override bool usesEH()
	{
		foreach (Statement s; statements)
		{	
			if (s && s.usesEH())
				return true;
		}
		
		return false;
	}
	
    override BE blockExit()
	{
		//printf("CompoundStatement::blockExit(%p) %d\n", this, statements->dim);
		BE result = BE.BEfallthru;
		foreach (s; statements)
		{
			if (s)
			{
				//printf("result = x%x\n", result);
				//printf("%s\n", s->toChars());
				if (!(result & BE.BEfallthru) && !s.comeFrom())
				{
					if (s.blockExit() != BE.BEhalt && !s.isEmpty())
						s.warning("statement is not reachable");
				}
				else
				{
					result &= ~BE.BEfallthru;
					result |= s.blockExit();
				}
			}
		}

		return result;
	}
	
    override bool comeFrom()
	{
		assert(false);
	}
	
    override bool isEmpty()
	{
		foreach (s; statements)
		{	
			if (s && !s.isEmpty())
				return false;
		}
		return true;
	}

    override Statements flatten(Scope sc)
	{
		return statements;
	}

    override ReturnStatement isReturnStatement()
	{
		ReturnStatement rs = null;

		foreach(s; statements)
		{	
			if (s)
			{
				rs = s.isReturnStatement();
				if (rs)
					break;
			}
		}
		return rs;
	}

    override Expression interpret(InterState istate)
	{
		Expression e = null;

version (LOG) {
		printf("CompoundStatement.interpret()\n");
}
		if (istate.start == this)
			istate.start = null;
		if (statements)
		{
			foreach(s; statements)
			{   
				if (s)
				{
					e = s.interpret(istate);
					if (e)
						break;
				}
			}
		}
version (LOG) {
		printf("-CompoundStatement.interpret() %p\n", e);
}
		return e;
	}

    override int inlineCost(InlineCostState* ics)
	{
		int cost = 0;

		foreach(s; statements)
		{	
			if (s)
			{
				cost += s.inlineCost(ics);
				if (cost >= COST_MAX)
					break;
			}
		}

		return cost;
	}

    override Expression doInline(InlineDoState ids)
	{
		Expression e = null;

		//printf("CompoundStatement.doInline() %d\n", statements.dim);
		foreach(s; statements)
		{	
			if (s)
			{
				Expression e2 = s.doInline(ids);
				e = Expression.combine(e, e2);
				if (s.isReturnStatement())
					break;

				/* Check for:
				 *	if (condition)
				 *	    return exp1;
				 *	else
				 *	    return exp2;
				 */
				IfStatement ifs = s.isIfStatement();
				if (ifs && ifs.elsebody && ifs.ifbody &&
					ifs.ifbody.isReturnStatement() &&
					ifs.elsebody.isReturnStatement()
				)
					break;
			}
		}
		return e;
	}
	
    override Statement inlineScan(InlineScanState* iss)
	{
		foreach(ref Statement s; statements)
		{	
			if (s)
				s = s.inlineScan(iss);
		}

		return this;
	}

    override void toIR(IRState* irs)
	{
		if (statements)
		{
			foreach(s; statements)
			{
				if (s !is null)
				{
					//writeln(s.classinfo.name);
					s.toIR(irs);
				}
			}
		}
	}

    override CompoundStatement isCompoundStatement() { return this; }
}
