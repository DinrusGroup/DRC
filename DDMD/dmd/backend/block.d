module dmd.backend.block;

import dmd.common;
import dmd.backend.elem;
import dmd.backend.LIST;
import dmd.backend.regm_t;
import dmd.backend.Symbol;
import dmd.backend.Srcpos;
import dmd.backend.code;
import dmd.backend.SYMIDX;
import dmd.backend.vec_t;
import dmd.backend.targ_types;
import dmd.backend.con_t;
static import std.stdio;

struct block
{
    union
    {
		elem* Belem;		// pointer to elem tree
		list_t	Blist;		// list of expressions
    };

    block* Bnext;		// pointer to next block in list
    list_t	  Bsucc;	// linked list of pointers to successors
				//     of this block
    list_t	  Bpred;	// and the predecessor list

    int Bindex;			// into created object stack
    int Bendindex;		// index at end of block
    block* Btry;		// BCtry,BC_try: enclosing try block, if any
				// BC???: if in try-block, points to BCtry or BC_try
				// note that can't have a BCtry and BC_try in
				// the same function.
    union
    {	
		targ_llong	*Bswitch;	// BCswitch: pointer to switch data
		struct
		{
			regm_t usIasmregs;		// Registers modified
			ubyte bIasmrefparam;   // References parameters?
		}

		struct
		{
			Symbol* catchvar;		// __throw() fills in this
		}

		struct
		{   
			Symbol* catchtype;		// one type for each catch block
		}

		struct
		{
			Symbol* jcatchvar;		// __j_throw() fills in this
			int Bscope_index;		// index into scope table
			int Blast_index;		// enclosing index into scope table
		}
    }
	
	public alias catchtype Bcatchtype;

    Srcpos	Bsrcpos;	// line number (0 if not known)
    ubyte BC;		// exit condition (enum BC)
// NEW
    ubyte Balign;	// alignment

    ushort Bflags;		// flags (BFLxxxx)
    code* Bcode;		// code generated for this block

    uint Bweight;		// relative number of times this block
				// is executed (optimizer and codegen)

    uint	Bdfoidx;	// index of this block in dfo[]
    union
    {
		// CPP
		struct
		{
			SYMIDX	symstart;	// (symstart <= symnum < symend) Symbols
			SYMIDX	symend;		// are declared in this block
			block* endscope;	// block that forms the end of the
						// scope for the declared Symbols
			uint blknum;		// position of block from startblock
			Symbol* Binitvar;	// !=NULL points to an auto variable with
						// an explicit or implicit initializer
			block* gotolist;	// BCtry, BCcatch: backward list of try scopes
			block* gotothread;	// BCgoto: threaded list of goto's to
						// unknown labels
		}

		// OPTIMIZER
		struct
		{
			vec_t	Bdom;		// mask of dominators for this block
			vec_t	Binrd;
			vec_t	Boutrd;		// IN and OUT for reaching definitions
			vec_t	Binlv;
			vec_t	Boutlv;		// IN and OUT for live variables
			vec_t	Bin;
			vec_t	Bout;		// IN and OUT for other flow analyses
			vec_t	Bgen;
			vec_t	Bkill;		// pointers to bit vectors used by data
						// flow analysis

			// BCiftrue can have different vectors for the 2nd successor:
			vec_t	Bout2;
			vec_t	Bgen2;
			vec_t	Bkill2;
		}

		// CODGEN
		struct
		{
			targ_size_t	Btablesize;	// BCswitch, BCjmptab
			targ_size_t	Btableoffset;	// BCswitch, BCjmptab
			targ_size_t	Boffset;	// code offset of start of this block
			targ_size_t	Bsize;		// code size of this block
			con_t	Bregcon;	// register state at block exit
			targ_size_t Btryoff;	// BCtry: offset of try block data
		}
    }
}

enum BFL
{
	BFLvisited = 1,		// set if block is visited
	BFLmark = 2,		// set if block is visited
	BFLjmpoptdone = 4,		// set when no more jump optimizations
				   	//  are possible for this block
	BFLnostackopt = 8,		// set when stack elimination should not
					// be done
///version (NTEXCEPTIONS) {
	BFLehcode = 0x10,	// set when we need to load exception code
	BFLunwind = 0x1000,	// do local_unwind following block
///}
///version (TARGET_POWERPC) {
///	BFLstructret = 0x10,	/* Set if a struct return is changed to
///					   block type BCret.  This is done to avoid
///					   error messages */
///}
	BFLnomerg = 0x20,	// do not merge with other blocks
///version (TX86) {
	BFLprolog = 0x80,	// generate function prolog
	BFLepilog = 0x100,	// generate function epilog
	BFLrefparam = 0x200,	// referenced parameter
	BFLreflocal = 0x400,	// referenced local
	BFLoutsideprolog = 0x800,	// outside function prolog/epilog
    BFLlabel = 0x2000,	// block preceded by label
///} else {
///	BFLlooprt = 0x40,	// set if looprotate() changes it's Bnext
///}
	BFLvolatile = 0x4000,	// block is volatile
}

void dump_block(block* foo)
{

	block *foo1 = foo;
	foreach (a, b; foo1.tupleof)
	{
		std.stdio.writeln(foo1.tupleof[a].stringof, " ", cast(char*)&foo1.tupleof[a] - cast(char*)foo1, " = ", foo1.tupleof[a]);
		//std.stdio.writeln("printf(\"", foo.tupleof[a].stringof, " %d = %d\\n\",(char*)(&", foo.tupleof[a].stringof, ")-(char*)foo, ", foo.tupleof[a].stringof, ");");
	}
}