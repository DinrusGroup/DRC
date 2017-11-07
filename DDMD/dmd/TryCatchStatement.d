module dmd.TryCatchStatement;

import dmd.common;
import dmd.Statement;
import dmd.Array;
import dmd.Loc;
import dmd.Id;
import dmd.Identifier;
import dmd.Scope;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.OutBuffer;
import dmd.Catch;
import dmd.HdrGenState;
import dmd.BE;

import dmd.backend.BC;
import dmd.codegen.Util;
import dmd.backend.Util;
import dmd.backend.Blockx;
import dmd.backend.block;
import dmd.backend.mTY;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

class TryCatchStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Statement body_;
    Array catches;

    this(Loc loc, Statement body_, Array catches)
	{
		register();
		super(loc);
		this.body_ = body_;
		this.catches = catches;
	}
	
    override Statement syntaxCopy()
	{
		Array a = new Array();
		a.setDim(catches.dim);
		for (int i = 0; i < a.dim; i++)
		{   
			Catch c;

			c = cast(Catch)catches.data[i];
			c = c.syntaxCopy();
			a.data[i] = cast(void*)c;
		}
		TryCatchStatement s = new TryCatchStatement(loc, body_.syntaxCopy(), a);
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		body_ = body_.semanticScope(sc, null /*this*/, null);

		/* Even if body is null, still do semantic analysis on catches
		 */
		for (size_t i = 0; i < catches.dim; i++)
		{   
			Catch c = cast(Catch)catches.data[i];
			c.semantic(sc);

			// Determine if current catch 'hides' any previous catches
			for (size_t j = 0; j < i; j++)
			{   
				Catch cj = cast(Catch)catches.data[j];
				string si = c.loc.toChars();
				string sj = cj.loc.toChars();

				if (c.type.toBasetype().implicitConvTo(cj.type.toBasetype()))
					error("catch at %s hides catch at %s", sj, si);
			}
		}

		if (!body_ || body_.isEmpty())
		{
			return null;
		}
		return this;
	}
	
    override bool hasBreak()
	{
		assert(false);
	}
	
    override bool usesEH()
	{
		assert(false);
	}
	
    override BE blockExit()
	{
		assert(body_);
		BE result = body_.blockExit();

		BE catchresult = BE.BEnone;
		for (size_t i = 0; i < catches.dim; i++)
		{
			Catch c = cast(Catch)catches.data[i];
			catchresult |= c.blockExit();

		/* If we're catching Object, then there is no throwing
		 */
		Identifier id = c.type.toBasetype().isClassHandle().ident;
		if (i == 0 &&
			(id is Id.Object_ || id is Id.Throwable || id is Id.Exception))
		{
			result &= ~BE.BEthrow;
		}
		}
		return result | catchresult;
	}

    override Statement inlineScan(InlineScanState* iss)
	{
		if (body_)
			body_ = body_.inlineScan(iss);
		if (catches)
		{
			for (int i = 0; i < catches.dim; i++)
			{   
				Catch c = cast(Catch)catches.data[i];

				if (c.handler)
					c.handler = c.handler.inlineScan(iss);
			}
		}
		return this;
	}

	/***************************************
	 * Builds the following:
	 *	_try
	 *	block
	 *	jcatch
	 *	handler
	 * A try-catch statement.
	 */
    override void toIR(IRState *irs)
	{
		Blockx *blx = irs.blx;

	version (SEH) {
		nteh_declarvars(blx);
	}

		IRState mystate = IRState(irs, this);

		block* tryblock = block_goto(blx,BCgoto,null);

		int previndex = blx.scope_index;
		tryblock.Blast_index = previndex;
		blx.scope_index = tryblock.Bscope_index = blx.next_index++;

		// Set the current scope index
		setScopeIndex(blx,tryblock,tryblock.Bscope_index);

		// This is the catch variable
		tryblock.jcatchvar = symbol_genauto(type_fake(mTYvolatile | TYnptr));

		blx.tryblock = tryblock;
		block *breakblock = block_calloc(blx);
		block_goto(blx,BC_try,null);
		if (body_)
		{
			body_.toIR(&mystate);
		}
		blx.tryblock = tryblock.Btry;

		// break block goes here
		block_goto(blx, BCgoto, breakblock);

		setScopeIndex(blx,blx.curblock, previndex);
		blx.scope_index = previndex;

		// create new break block that follows all the catches
		breakblock = block_calloc(blx);

		list_append(&blx.curblock.Bsucc, breakblock);
		block_next(blx,BCgoto,null);
	 
		assert(catches);
		for (int i = 0 ; i < catches.dim; i++)
		{
			Catch cs = cast(Catch)(catches.data[i]);
			if (cs.var)
				cs.var.csym = tryblock.jcatchvar;
			block* bcatch = blx.curblock;
			if (cs.type)
				bcatch.Bcatchtype = cs.type.toBasetype().toSymbol();
			list_append(&tryblock.Bsucc,bcatch);
			block_goto(blx,BCjcatch,null);
			if (cs.handler !is null)
			{
				IRState catchState = IRState(irs, this);
				cs.handler.toIR(&catchState);
			}
			list_append(&blx.curblock.Bsucc, breakblock);
			block_next(blx, BCgoto, null);
		}

		block_next(blx,cast(BC)blx.curblock.BC, breakblock);
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("try");
		buf.writenl();
		if (body_)
			body_.toCBuffer(buf, hgs);
		for (size_t i = 0; i < catches.dim; i++)
		{
			Catch c = cast(Catch)catches.data[i];
			c.toCBuffer(buf, hgs);
		}
	}
	
    override TryCatchStatement isTryCatchStatement() { return this; }
}
