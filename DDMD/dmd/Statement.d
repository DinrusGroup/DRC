module dmd.Statement;

import dmd.common;
import dmd.TryCatchStatement;
import dmd.GotoStatement;
import dmd.AsmStatement;
import dmd.ScopeStatement;
import dmd.DeclarationStatement;
import dmd.CompoundStatement;
import dmd.ReturnStatement;
import dmd.IfStatement;
import dmd.Scope;
import dmd.Loc;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.ArrayTypes;
import dmd.Expression;
import dmd.InterState;
import dmd.InlineCostState;
import dmd.InlineDoState;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.BE;
import dmd.Global;
import dmd.GlobalExpressions;
import dmd.Util;

import std.stdio;

import dmd.DDMDExtensions;

//! startup code used in *Statement.interpret() functions
enum START = `
	if (istate.start)
	{
		if (istate.start !is this)
			return null;
		istate.start = null;
	}
`;

import dmd.TObject;

class Statement  : TObject
{
	mixin insertMemberExtension!(typeof(this));

    Loc loc;

    this(Loc loc)
	{
		register();
		this.loc = loc;
	}

    Statement syntaxCopy()
	{
		assert(false);
	}

    void print()
	{
		assert(false);
	}

    string toChars()
	{
		/*scope*/ OutBuffer buf = new OutBuffer();
		HdrGenState hgs;

		toCBuffer(buf, &hgs);
		return buf.toChars();
	}

    void error(T...)(string format, T t)
	{
		.error(loc, format, t);
	}

    void warning(T...)(string format, T t)
	{
		if (global.params.warnings && !global.gag)
		{
			writef("warning - ");
			.error(loc, format, t);
		}
	}

	void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

    TryCatchStatement isTryCatchStatement() { return null; }

    GotoStatement isGotoStatement() { return null; }

    AsmStatement isAsmStatement() { return null; }

version (_DH) {
    int incontract;
}
    ScopeStatement isScopeStatement() { return null; }

    Statement semantic(Scope sc)
	{
		assert(false);
	}

    Statement semanticScope(Scope sc, Statement sbreak, Statement scontinue)
	{
		Scope scd;
		Statement s;

		scd = sc.push();
		if (sbreak)
			scd.sbreak = sbreak;
		if (scontinue)
			scd.scontinue = scontinue;
		s = semantic(scd);
		scd.pop();
		return s;
	}

    bool hasBreak()
	{
		assert(false);
	}

    bool hasContinue()
	{
		assert(false);
	}

	// TRUE if statement uses exception handling

    bool usesEH()
	{
		return false;
	}

    BE blockExit()
	{
		assert(false);
	}

	// true if statement 'comes from' somewhere else, like a goto
    bool comeFrom()
	{
		//printf("Statement::comeFrom()\n");
		return false;
	}

	// Return TRUE if statement has no code in it
    bool isEmpty()
	{
		//printf("Statement::isEmpty()\n");
		return false;
	}

	/****************************************
	 * If this statement has code that needs to run in a finally clause
	 * at the end of the current scope, return that code in the form of
	 * a Statement.
	 * Output:
	 *	*sentry		code executed upon entry to the scope
	 *	*sexception	code executed upon exit from the scope via exception
	 *	*sfinally	code executed in finally block
	 */
    void scopeCode(Scope sc, Statement* sentry, Statement* sexception, Statement* sfinally)
	{
		//printf("Statement::scopeCode()\n");
		//print();
		*sentry = null;
		*sexception = null;
		*sfinally = null;
	}

	/*********************************
	 * Flatten out the scope by presenting the statement
	 * as an array of statements.
	 * Returns NULL if no flattening necessary.
	 */
    Statements flatten(Scope sc)
	{
		return null;
	}

	/***********************************
	 * Interpret the statement.
	 * Returns:
	 *	null				continue to next statement
	 *	EXP_CANT_INTERPRET	cannot interpret statement at compile time
	 *	!null				expression from return statement
	 */
	Expression interpret(InterState istate)
	{
version(LOG)
		writef("Statement::interpret()\n");

		mixin(START);
		error("Statement %s cannot be interpreted at compile time", this.toChars());
		return EXP_CANT_INTERPRET;
	}

    int inlineCost(InlineCostState* ics)
	{
		return COST_MAX;		// default is we can't inline it
	}

    Expression doInline(InlineDoState ids)
	{
		assert(false);
	}

    Statement inlineScan(InlineScanState* iss)
	{
		return this;
	}

    // Back end
    void toIR(IRState* irs)
	{
		assert(false);
	}

    // Avoid dynamic_cast
    DeclarationStatement isDeclarationStatement() { return null; }
    CompoundStatement isCompoundStatement() { return null; }
    ReturnStatement isReturnStatement() { return null; }
    IfStatement isIfStatement() { return null; }
}
