module dmd.backend.SFL;

enum SFL
{
	SFLmark	= 0x08,	// temporary marker
	SFLvalue = 0x01,	// Svalue contains const expression
	SFLimplem = 0x02,	// if seen implementation of Symbol
					// (function body for functions,
					// initializer for variables)
	SFLdouble = 0x02,	// SCregpar or SCparameter, where float
					// is really passed as a double
	SFLfree = 0x04,	// if we can symbol_free() a Symbol in
					// a Symbol table[]
	SFLexit = 0x10,	// tyfunc: function does not return
					// (ex: exit,abort,_assert,longjmp)
	SFLtrue = 0x200,	// value of Symbol != 0
	SFLreplace = SFLmark,	// variable gets replaced in inline expansion
	SFLskipinit = 0x10000,	// SCfield, SCmember: initializer is skipped
	SFLnodebug = 0x20000,	// don't generate debug info
	SFLwasstatic = 0x800000, // was an uninitialized static
	SFLweak	= 0x1000000, // resolve to NULL if not found

	// CPP
	SFLnodtor = 0x10,	// set if destructor for Symbol is already called
	SFLdtorexp = 0x80,	// Svalue has expression to tack onto dtor
	SFLmutable = 0x100000,	// SCmember or SCfield is mutable
	SFLdyninit = 0x200000,	// symbol has dynamic initializer
	SFLtmp = 0x400000,	// symbol is a generated temporary

///version (POSIX) {///TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
///    SFLthunk = 0x40000, // symbol is temporary for thunk
///}

	// Possible values for protection bits
	SFLprivate = 0x60,
	SFLprotected = 0x40,
	SFLpublic = 0x20,
	SFLnone	= 0x00,
	SFLpmask = 0x60,	// mask for the protection bits
///version (VEC_VTBL_LIST) {
///	SFLvtbl	= 0x2000,	// Symbol is a vtable or vbtable
///}

	// OPTIMIZER and CODGEN
	SFLdead	= 0x800,	// this variable is dead
	
	// OPTIMIZER only
	SFLunambig = 0x400,	// only accessible by unambiguous reference,
					// i.e. cannot be addressed via pointer
					// (GTregcand is a subset of this)
					// P.S. code generator turns off this
					// flag if any reads are done from it.
					// This is to eliminate stores to it
					// that are never read.
					
	SFLlivexit = 0x1000,	// live on exit from function
	SFLnotbasiciv = 0x4000,	// not a basic induction variable
	SFLnord	= SFLdouble, // SCauto,SCregister,SCtmp: disallow redundant warnings
	
	// CODGEN only
	SFLread	= 0x40000,	// variable is actually read from
					// (to eliminate dead stores)
	SFLspill = 0x80000,	// only in register part of the time
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(SFL));
