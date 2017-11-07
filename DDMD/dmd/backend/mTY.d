module dmd.backend.mTY;

enum mTY
{
	/* Linkage type			*/
	mTYnear = 0x100,
	mTYfar = 0x200,
	mTYcs = 0x400,		// in code segment
	mTYthread = 0x800,
	mTYLINK = 0xF00,		// all linkage bits

	mTYloadds = 0x1000,
	mTYexport = 0x2000,
	mTYweak	= 0x0000,
	mTYimport = 0x4000,
	mTYnaked = 0x8000,
	mTYMOD = 0xF000,		// all modifier bits
	
	mTYbasic = 0x3F,	/* bit mask for basic types	*/
	
	/* Modifiers to basic types	*/
///	#ifdef JHANDLE
///	mTYarrayhandle = 0x80,
///	#else
	mTYarrayhandle = 0x0,
///	#endif
	mTYconst = 0x40,
	mTYvolatile = 0x80,
	mTYrestrict = 0,		// BUG: add for C99
	mTYmutable = 0,		// need to add support
	mTYunaligned = 0,		// non-zero for PowerPC

	mTYimmutable = 0x1000000,	// immutable data
	mTYshared = 0x2000000,	// shared data
	mTYnothrow = 0x4000000,	// nothrow function
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(mTY));

uint tybasic(ulong ty) {
	return ((ty) & mTY.mTYbasic);
}
