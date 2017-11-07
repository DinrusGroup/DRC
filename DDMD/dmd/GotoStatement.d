module dmd.GotoStatement;

import dmd.common;
import dmd.Loc;
import dmd.Scope;
import dmd.Statement;
import dmd.Identifier;
import dmd.CompoundStatement;
import dmd.LabelDsymbol;
import dmd.TryFinallyStatement;
import dmd.FuncDeclaration;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.InterState;
import dmd.IRState;
import dmd.ArrayTypes;
import dmd.BE;

import dmd.codegen.Util;
import dmd.backend.Util;
import dmd.backend.block;
import dmd.backend.Blockx;
import dmd.backend.BC;

import dmd.DDMDExtensions;

class GotoStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Identifier ident;
    LabelDsymbol label = null;
    TryFinallyStatement tf = null;

    this(Loc loc, Identifier ident)
	{
		register();
		super(loc);
		this.ident = ident;
	}
	
    override Statement syntaxCopy()
	{
		GotoStatement s = new GotoStatement(loc, ident);
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		FuncDeclaration fd = sc.parent.isFuncDeclaration();

		//printf("GotoStatement.semantic()\n");
		tf = sc.tf;
		label = fd.searchLabel(ident);
		if (!label.statement && sc.fes)
		{
			/* Either the goto label is forward referenced or it
			 * is in the function that the enclosing foreach is in.
			 * Can't know yet, so wrap the goto in a compound statement
			 * so we can patch it later, and add it to a 'look at this later'
			 * list.
			 */
			auto a = new Statements();
			Statement s;

			a.push(this);
			s = new CompoundStatement(loc, a);
			sc.fes.gotos.push(cast(void*)s);		// 'look at this later' list
			return s;
		}

		if (label.statement && label.statement.tf != sc.tf)
			error("cannot goto in or out of finally block");
		return this;
	}

    override BE blockExit()
	{
		//printf("GotoStatement.blockExit(%p)\n", this);
		return BE.BEgoto;
	}
	
    override Expression interpret(InterState istate)
	{
		assert(false);
	}

    override void toIR(IRState* irs)
	{
		block* b;
		block* bdest;
		Blockx* blx = irs.blx;

		if (!label.statement)
		{	
			error("label %s is undefined", label.toChars());
			return;
		}
		if (tf !is label.statement.tf)
			error("cannot goto forward out of or into finally block");

		bdest = labelToBlock(loc, blx, label);
		if (!bdest)
			return;
		b = blx.curblock;
		incUsage(irs, loc);

		// Adjust exception handler scope index if in different try blocks
		if (b.Btry != bdest.Btry)
		{
			// Check that bdest is in an enclosing try block
			for (block* bt = b.Btry; bt != bdest.Btry; bt = bt.Btry)
			{
				if (!bt)
				{
					//printf("b.Btry = %p, bdest.Btry = %p\n", b.Btry, bdest.Btry);
					error("cannot goto into try block");
					break;
				}
			}

			//setScopeIndex(blx, b, bdest.Btry ? bdest.Btry.Bscope_index : -1);
		}

		list_append(&b.Bsucc,bdest);
		block_next(blx,BCgoto,null);
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("goto ");
		buf.writestring(ident.toChars());
		buf.writebyte(';');
		buf.writenl();
	}
	
    override GotoStatement isGotoStatement() { return this; }
}
