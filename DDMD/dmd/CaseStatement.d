module dmd.CaseStatement;

import dmd.common;
import dmd.Statement;
import dmd.Expression;
import dmd.Statement;
import dmd.Scope;
import dmd.Loc;
import dmd.IRState;
import dmd.InlineScanState;
import dmd.HdrGenState;
import dmd.OutBuffer;
import dmd.InterState;
import dmd.BE;
import dmd.SwitchStatement;
import dmd.WANT;
import dmd.TOK;
import dmd.VarExp;
import dmd.VarDeclaration;
import dmd.Type;
import dmd.TY;
import dmd.IntegerExp;
import dmd.GotoCaseStatement;

import dmd.backend.block;
import dmd.backend.Blockx;
import dmd.backend.Util;
import dmd.backend.BC;

import dmd.DDMDExtensions;

class CaseStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;
    Statement statement;

    int index = 0;			// which case it is (since we sort this)
    block* cblock = null;	// back end: label for the block

    this(Loc loc, Expression exp, Statement s)
	{
		register();

		super(loc);
		
		this.exp = exp;
		this.statement = s;
	}
	
    override Statement syntaxCopy()
	{
		CaseStatement s = new CaseStatement(loc, exp.syntaxCopy(), statement.syntaxCopy());
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		SwitchStatement sw = sc.sw;

		//printf("CaseStatement.semantic() %s\n", toChars());
		exp = exp.semantic(sc);
		if (sw)
		{
			exp = exp.implicitCastTo(sc, sw.condition.type);
			exp = exp.optimize(WANTvalue | WANTinterpret);

			/* This is where variables are allowed as case expressions.
			 */
			if (exp.op == TOKvar)
			{   VarExp ve = cast(VarExp)exp;
				VarDeclaration v = ve.var.isVarDeclaration();
				Type t = exp.type.toBasetype();
				if (v && (t.isintegral() || t.ty == Tclass))
				{
					/* Flag that we need to do special code generation
					 * for this, i.e. generate a sequence of if-then-else
					 */
					sw.hasVars = 1;
					if (sw.isFinal)
						error("case variables not allowed in final switch statements");
					goto L1;
				}
			}

			if (exp.op != TOKstring && exp.op != TOKint64)
			{
				error("case must be a string or an integral constant, not %s", exp.toChars());
				exp = new IntegerExp(0);
			}

			L1:
			for (int i = 0; i < sw.cases.dim; i++)
			{
				CaseStatement cs = cast(CaseStatement)sw.cases.data[i];

				//printf("comparing '%s' with '%s'\n", exp.toChars(), cs.exp.toChars());
				if (cs.exp.equals(exp))
				{	
					error("duplicate case %s in switch statement", exp.toChars());
					break;
				}
			}

			sw.cases.push(cast(void*)this);

			// Resolve any goto case's with no exp to this case statement
			for (int i = 0; i < sw.gotoCases.dim; i++)
			{
				GotoCaseStatement gcs = cast(GotoCaseStatement)sw.gotoCases.data[i];

				if (!gcs.exp)
				{
					gcs.cs = this;
					sw.gotoCases.remove(i);	// remove from array
				}
			}

			if (sc.sw.tf !is sc.tf)
				error("switch and case are in different finally blocks");
		}
		else
			error("case not in switch statement");
		statement = statement.semantic(sc);
		return this;
	}
	
    override int opCmp(Object obj)
	{
		// Sort cases so we can do an efficient lookup
		CaseStatement cs2 = cast(CaseStatement)obj;

		return exp.opCmp(cs2.exp);
	}
	
    override bool usesEH()
	{
		assert(false);
	}
	
    override BE blockExit()
	{
		return statement.blockExit();
	}
	
    override bool comeFrom()
	{
		return true;
	}
	
    override Expression interpret(InterState istate)
	{
	version (LOG) {
		printf("CaseStatement.interpret(%s) this = %p\n", exp.toChars(), this);
	}
		if (istate.start is this)
			istate.start = null;
		if (statement)
			return statement.interpret(istate);
		else
			return null;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
	    buf.writestring("case ");
		exp.toCBuffer(buf, hgs);
		buf.writebyte(':');
		buf.writenl();
		statement.toCBuffer(buf, hgs);
	}

    override Statement inlineScan(InlineScanState* iss)
	{
		//printf("CaseStatement.inlineScan()\n");
		exp = exp.inlineScan(iss);
		if (statement)
			statement = statement.inlineScan(iss);
		return this;
	}

    override void toIR(IRState *irs)
	{
		Blockx* blx = irs.blx;
		block* bcase = blx.curblock;
		if (!cblock)
			cblock = block_calloc(blx);
		block_next(blx,BCgoto,cblock);
		block* bsw = irs.getSwitchBlock();
		if (bsw.BC == BCswitch)
			list_append(&bsw.Bsucc,cblock);	// second entry in pair
		list_append(&bcase.Bsucc,cblock);
		if (blx.tryblock != bsw.Btry)
			error("case cannot be in different try block level from switch");
		incUsage(irs, loc);
		if (statement)
			statement.toIR(irs);
	}
}
