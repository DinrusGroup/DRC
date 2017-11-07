module dmd.backend.FL;

/**************************************
 * Element types.
 * These should be combined with storage classes.
 */

enum FL
{
	FLunde,
	FLconst,	// numerical constant
	FLoper,		// operator node
	FLfunc,		// function symbol
	FLdata,		// ref to data segment variable
	FLreg,		// ref to register variable
	FLpseudo,	// pseuodo register variable
	FLauto,		// ref to automatic variable
	FLpara,		// ref to function parameter variable
	FLextern,	// ref to external variable
	FLtmp,		// ref to a stack temporary, int contains temp number
	FLcode,		// offset to code
	FLblock,	// offset to block
	FLudata,	// ref to udata segment variable
	FLcs,		// ref to common subexpression number
	FLswitch,	// ref to offset of switch data block
	FLfltreg,	// ref to floating reg on stack, int contains offset
	FLoffset,	// offset (a variation on constant, needed so we
			// can add offsets (different meaning for FLconst))
	FLdatseg,	// ref to data segment offset
	FLctor,		// constructed object
	FLdtor,		// destructed object
///#if TX86
	FLndp,		// saved 8087 register
	FLfardata,	// ref to far data segment
	FLlocalsize,	// replaced with # of locals in the stack frame
	FLcsdata,	// ref to code segment variable
	FLtlsdata,	// thread local storage
	FLbprel,	// ref to variable at fixed offset from frame pointer
	FLframehandler,	// ref to C++ frame handler for NT EH
	FLasm,		// (code) an ASM code
	FLblockoff,	// address of block
	FLallocatmp,	// temp for built-in alloca()
	FLstack,	// offset from ESP rather than EBP
	FLdsymbol,	// it's a Dsymbol
///#if TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
	// Change this, update debug.c too
///	FLgot,		// global offset table entry outside this object file
///	FLgotoff,	// global offset table entry inside this object file
	//FLoncedata,	// link once data
	//FLoncecode,	// link once code
///#endif
///#else
///	TARGET_enumFL
///#endif
	FLMAX
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(FL));