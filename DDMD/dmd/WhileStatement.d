module dmd.WhileStatement;

import dmd.common;
import dmd.Statement;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.HdrGenState;
import dmd.OutBuffer;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.Loc;
import dmd.BE;
import dmd.ForStatement;

import dmd.DDMDExtensions;

class WhileStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression condition;
    Statement body_;

    this(Loc loc, Expression c, Statement b)
	{
		register();
		super(loc);
		condition = c;
		body_ = b;
	}
	
    override Statement syntaxCopy()
	{
		WhileStatement s = new WhileStatement(loc, condition.syntaxCopy(), body_ ? body_.syntaxCopy() : null);
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		/* Rewrite as a for(;condition;) loop
		 */

		Statement s = new ForStatement(loc, null, condition, null, body_);
		s = s.semantic(sc);
		return s;
	}
	
    override bool hasBreak()
	{
		return true;
	}
	
    override bool hasContinue()
	{
		return true;
	}
	
    override bool usesEH()
	{
		assert(false);
	}
	
    override BE blockExit()
	{
		assert(false);
	}
	
    override bool comeFrom()
	{
		assert(false);
	}
	
    override Expression interpret(InterState istate)
	{
version(LOG) {
       printf("WhileStatement::interpret()\n");
}
        assert(false);			// rewritten to ForStatement
        return null;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

    override Statement inlineScan(InlineScanState* iss)
	{
		assert(false);
	}
	
    override void toIR(IRState* irs)
	{
		assert(false);
	}
}
