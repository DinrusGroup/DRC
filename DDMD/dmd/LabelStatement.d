module dmd.LabelStatement;

import dmd.common;
import dmd.Statement;
import dmd.Identifier;
import dmd.TryFinallyStatement;
import dmd.Scope;
import dmd.Loc;
import dmd.ExpStatement;
import dmd.ArrayTypes;
import dmd.Expression;
import dmd.InterState;
import dmd.InlineScanState;
import dmd.LabelDsymbol;
import dmd.FuncDeclaration;
import dmd.CSX;
import dmd.IRState;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.BE;

import dmd.backend.block;
import dmd.backend.Blockx;
import dmd.backend.Util;
import dmd.backend.BC;

import dmd.DDMDExtensions;

class LabelStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Identifier ident;
    Statement statement;
    TryFinallyStatement tf = null;
    block* lblock = null;		// back end
    int isReturnLabel = 0;

    this(Loc loc, Identifier ident, Statement statement)
	{
		register();
		super(loc);
		this.ident = ident;
		this.statement = statement;
	}

    override Statement syntaxCopy()
	{
		LabelStatement s = new LabelStatement(loc, ident, statement.syntaxCopy());
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		LabelDsymbol ls;
		FuncDeclaration fd = sc.parent.isFuncDeclaration();

		//printf("LabelStatement.semantic()\n");
		ls = fd.searchLabel(ident);
		if (ls.statement)
			error("Label '%s' already defined", ls.toChars());
		else
			ls.statement = this;
		tf = sc.tf;
		sc = sc.push();
		sc.scopesym = sc.enclosing.scopesym;
		sc.callSuper |= CSXlabel;
		sc.slabel = this;
		if (statement)
			statement = statement.semantic(sc);
		sc.pop();
		return this;
	}

    override Statements flatten(Scope sc)
	{
		Statements a = null;

		if (statement)
		{
			a = statement.flatten(sc);
			if (a)
			{
				if (!a.dim)
					a.push(new ExpStatement(loc, null));

				Statement s = a[0];

				s = new LabelStatement(loc, ident, s);
				a[0] = s;
			}
		}

		return a;
	}
	
    override bool usesEH()
	{
		return statement ? statement.usesEH() : false;
	}
	
    override BE blockExit()
	{
		//printf("LabelStatement.blockExit(%p)\n", this);
		return statement ? statement.blockExit() : BE.BEfallthru;
	}
	
    override bool comeFrom()
	{
		//printf("LabelStatement.comeFrom()\n");
		return true;
	}
	
    override Expression interpret(InterState istate)
	{
		assert(false);
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring(ident.toChars());
		buf.writebyte(':');
		buf.writenl();
		if (statement)
			statement.toCBuffer(buf, hgs);
	}
	
    override Statement inlineScan(InlineScanState* iss)
	{
		if (statement)
			statement = statement.inlineScan(iss);
		return this;
	}

    override void toIR(IRState* irs)
	{
		//printf("LabelStatement.toIR() %p, statement = %p\n", this, statement);
		Blockx* blx = irs.blx;
		block* bc = blx.curblock;
		IRState mystate = IRState(irs,this);
		mystate.ident = ident;

		if (lblock)
		{
			// We had made a guess about which tryblock the label is in.
			// Error if we guessed wrong.
			// BUG: should fix this
			if (lblock.Btry != blx.tryblock)
				error("cannot goto forward into different try block level");
		}
		else
			lblock = block_calloc(blx);

		block_next(blx,BCgoto,lblock);
		list_append(&bc.Bsucc,blx.curblock);
		if (statement)
			statement.toIR(&mystate);
	}
}
