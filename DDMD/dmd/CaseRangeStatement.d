module dmd.CaseRangeStatement;

import dmd.common;
import dmd.Statement;
import dmd.ArrayTypes;
import dmd.Expression;
import dmd.ExpStatement;
import dmd.IntegerExp;
import dmd.CaseStatement;
import dmd.CompoundStatement;
import dmd.Statement;
import dmd.Loc;
import dmd.OutBuffer;
import dmd.WANT;
import dmd.SwitchStatement;
import dmd.HdrGenState;
import dmd.Scope;

import dmd.DDMDExtensions;

class CaseRangeStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression first;
    Expression last;
    Statement statement;

    this(Loc loc, Expression first, Expression last, Statement s)
	{
		register();

		super(loc);
		this.first = first;
		this.last = last;
		this.statement = s;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
    override Statement semantic(Scope sc)
	{
		SwitchStatement sw = sc.sw;

		//printf("CaseRangeStatement.semantic() %s\n", toChars());
		if (sw.isFinal)
			error("case ranges not allowed in final switch");

		first = first.semantic(sc);
		first = first.implicitCastTo(sc, sw.condition.type);
		first = first.optimize(WANTvalue | WANTinterpret);
		long fval = first.toInteger();

		last = last.semantic(sc);
		last = last.implicitCastTo(sc, sw.condition.type);
		last = last.optimize(WANTvalue | WANTinterpret);
		long lval = last.toInteger();

		if (lval - fval > 256)
		{	
			error("more than 256 cases in case range");
			lval = fval + 256;
		}

		/* This works by replacing the CaseRange with an array of Case's.
		 *
		 * case a: .. case b: s;
		 *    =>
		 * case a:
		 *   [...]
		 * case b:
		 *   s;
		 */

		Statements statements = new Statements();
		for (long i = fval; i <= lval; i++)
		{
			Statement s = statement;
			if (i != lval)
				s = new ExpStatement(loc, null);
			Expression e = new IntegerExp(loc, i, first.type);
			Statement cs = new CaseStatement(loc, e, s);
			statements.push(cs);
		}
		Statement s = new CompoundStatement(loc, statements);
		s = s.semantic(sc);
		return s;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("case ");
		first.toCBuffer(buf, hgs);
		buf.writestring(": .. case ");
		last.toCBuffer(buf, hgs);
		buf.writenl();
		statement.toCBuffer(buf, hgs);
	}
}
