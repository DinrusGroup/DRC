module dmd.IRState;

import dmd.common;
import dmd.Statement;
import dmd.Module;
import dmd.Dsymbol;
import dmd.Identifier;
import dmd.Array;
import dmd.FuncDeclaration;
import dmd.Global;
import dmd.Loc;
import dmd.TRUST;
import dmd.TY;
import dmd.TypeFunction;
import dmd.Type;

import dmd.backend.Symbol;
import dmd.backend.Blockx;
import dmd.backend.block;
import dmd.backend.elem;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.OPER;

struct IRState
{
    IRState* prev;
    Statement statement;
    Module m;			// module
    Dsymbol symbol;
    Identifier ident;
    Symbol* shidden;		// hidden parameter to function
    Symbol* sthis;		// 'this' parameter to function (member and nested)
    Symbol* sclosure;		// pointer to closure instance
    Blockx* blx;
    Array deferToObj;		// array of Dsymbol's to run toObjFile(int multiobj) on later
    elem* ehidden;		// transmit hidden pointer to CallExp::toElem()
    Symbol* startaddress;

    block* breakBlock;
    block* contBlock;
    block* switchBlock;
    block* defaultBlock;

    this(IRState* irs, Statement s)
	{
	    prev = irs;
		statement = s;
		if (irs)
		{
			m = irs.m;
			shidden = irs.shidden;
			sclosure = irs.sclosure;
			sthis = irs.sthis;
			blx = irs.blx;
			deferToObj = irs.deferToObj;
		}
	}

    this(IRState* irs, Dsymbol s)
	{
		assert(false);
	}

    this(Module m, Dsymbol s)
	{
		this.m = m;
		symbol = s;
	}

    block* getBreakBlock(Identifier ident)
	{
		for (IRState* bc = &this; bc; bc = bc.prev)
		{
			if (ident)
			{
				if (bc.prev && bc.prev.ident == ident)
					return bc.breakBlock;
			}
			else if (bc.breakBlock)
				return bc.breakBlock;
		}
		return null;
	}

    block* getContBlock(Identifier ident)
	{
		IRState* bc;

		for (bc = &this; bc; bc = bc.prev)
		{
			if (ident)
			{
				if (bc.prev && bc.prev.ident == ident)
					return bc.contBlock;
			}
			else if (bc.contBlock)
				return bc.contBlock;
		}
		return null;
	}

    block* getSwitchBlock()
	{
		for (IRState* bc = &this; bc; bc = bc.prev)
		{
			if (bc.switchBlock)
				return bc.switchBlock;
		}
		return null;
	}

    block* getDefaultBlock()
	{
		for (IRState* bc = &this; bc; bc = bc.prev)
		{
			if (bc.defaultBlock)
				return bc.defaultBlock;
		}
		return null;
	}

    FuncDeclaration getFunc()
	{
		IRState* bc;
		for (bc = &this; bc.prev; bc = bc.prev)
		{
		}
		return cast(FuncDeclaration)(bc.symbol);
	}

    /**********************
     * Return !=0 if do array bounds checking
     */
    int arrayBoundsCheck()
    {
        int result = global.params.useArrayBounds;

        if (result == 1)
        {
            // For safe functions only
	        result = 0;
	        FuncDeclaration fd = getFunc();
	        if (fd)
	        {
                Type t = fd.type;
	            if (t.ty == TY.Tfunction && (cast(TypeFunction)t).trust == TRUST.TRUSTsafe)
		        result = 1;
	        }
        }
        return result;
    }
}

/*********************************************
 * Produce elem which increments the usage count for a particular line.
 * Used to implement -cov switch (coverage analysis).
 */

elem *incUsageElem(IRState *irs, Loc loc)
{
    uint linnum = loc.linnum;

    if (!irs.blx.module_.cov || !linnum || loc.filename != irs.blx.module_.srcfile.toChars())
		return null;

    //printf("cov = %p, covb = %p, linnum = %u\n", irs->blx->module->cov, irs->blx->module->covb, p, linnum);

    linnum--;		// from 1-based to 0-based

    /* Set bit in covb[] indicating this is a valid code line number
     */
    uint* p = irs.blx.module_.covb;
    if (p)	// covb can be NULL if it has already been written out to its .obj file
    {
		p += linnum / ((*p).sizeof * 8);
		*p |= 1 << (linnum & ((*p).sizeof * 8 - 1));
    }

    elem* e;
    e = el_ptr(irs.blx.module_.cov);
    e = el_bin(OPER.OPadd, TYM.TYnptr, e, el_long(TYM.TYuint, linnum * 4));
    e = el_una(OPER.OPind, TYM.TYuint, e);
    e = el_bin(OPER.OPaddass, TYM.TYuint, e, el_long(TYM.TYuint, 1));

    return e;
}

/**************************************
 * Add in code to increment usage count for linnum.
 */
void incUsage(IRState* irs, Loc loc)
{
    if (global.params.cov && loc.linnum)
    {
		block_appendexp(irs.blx.curblock, incUsageElem(irs, loc));
    }
}
