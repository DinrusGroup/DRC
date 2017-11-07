module dmd.backend.TYFL;

import dmd.common;
import dmd.backend.Util;

extern(C++) ubyte* get_tytab();
ubyte* tytab() { return get_tytab(); }

extern(C++) ubyte* get_tytab2();
ubyte* tytab2() { return get_tytab2(); }

/* Array to give the size in bytes of a type, -1 means error	*/
extern(C++) byte* get_tysize();
byte* tysize() { return get_tysize(); }

enum TYFL
{
	/* Flags in tytab[] array	*/
	TYFLptr	= 1,
	TYFLreal = 2,
	TYFLintegral = 4,
	TYFLcomplex	= 8,
	TYFLimaginary = 0x10,
	TYFLuns	= 0x20,
	TYFLmptr = 0x40,
	TYFLfv = 0x80,	/* TYfptr || TYvptr	*/

	/* Flags in tytab2[] array	*/
///version (TX86) {
	TYFLfarfunc	= 1,
	TYFLpascal = 2,	/* callee cleans up stack		*/
	TYFLrevparam = 4,	/* function parameters are reversed	*/
///} else {
///	TYFLcallstkc = 1,	/* callee cleans up stack		*/
///	TYFLrevparam = 2,	/* function parameters are reversed	*/
///}
	TYFLshort = 0x10,
	TYFLaggregate = 0x20,
	TYFLfunc = 0x40,
	TYFLref	= 0x80,
}

/* Groupings of types	*/

ubyte tyintegral(uint ty) {
	return (tytab[(ty) & 0xFF] & TYFL.TYFLintegral);
}

ubyte tyarithmetic(uint ty) {
	return (tytab[(ty) & 0xFF] & (TYFL.TYFLintegral | TYFL.TYFLreal | TYFL.TYFLimaginary | TYFL.TYFLcomplex));
}

ubyte tyaggregate(uint ty) {
	return (tytab2[(ty) & 0xFF] & TYFL.TYFLaggregate);
}

ubyte tyscalar(uint ty) {
	return (tytab[(ty) & 0xFF] & (TYFL.TYFLintegral | TYFL.TYFLreal | TYFL.TYFLimaginary | TYFL.TYFLcomplex | TYFL.TYFLptr | TYFL.TYFLmptr));
}

ubyte tyfloating(uint ty) {
	return (tytab[(ty) & 0xFF] & (TYFL.TYFLreal | TYFL.TYFLimaginary | TYFL.TYFLcomplex));
}

ubyte tyimaginary(uint ty) {
	return (tytab[(ty) & 0xFF] & TYFL.TYFLimaginary);
}

ubyte tycomplex(uint ty) {
	return (tytab[(ty) & 0xFF] & TYFL.TYFLcomplex);
}

ubyte tyreal(uint ty) {
	return (tytab[(ty) & 0xFF] & TYFL.TYFLreal);
}

/* Types that are chars or shorts	*/
ubyte tyshort(uint ty) {
	return (tytab2[(ty) & 0xFF] & TYFL.TYFLshort);
}

/+
/* Detect TYlong or TYulong	*/
#define tylong(ty)	(tybasic(ty) == TYlong || tybasic(ty) == TYulong)
+/

/* Use to detect a pointer type	*/
ubyte typtr(uint ty) {
	return (tytab[(ty) & 0xFF] & TYFL.TYFLptr);
}

/* Use to detect a reference type */
ubyte tyref(uint ty) {
	return (tytab2[(ty) & 0xFF] & TYFL.TYFLref);
}

/* Use to detect a pointer type or a member pointer	*/
ubyte tymptr(uint ty) {
	return (tytab[(ty) & 0xFF] & (TYFL.TYFLptr | TYFL.TYFLmptr));
}

/* Detect TYfptr or TYvptr	*/
ubyte tyfv(uint ty)	{
	return (tytab[(ty) & 0xFF] & TYFL.TYFLfv);
}

/+
// Give size of type
char tysize(uint ty) {
	return tysize[(ty) & 0xFF];
}

/* All data types that fit in exactly 8 bits	*/
bool tybyte(uint ty) {
	return (tysize(ty) == 1);
}

/* Types that fit into a single machine register	*/
bool tyreg(TY ty) {
	return (tysize(ty) <= REGSIZE);
}
+/

/* Detect function type	*/
ubyte tyfunc(ulong ty) {
	return (tytab2[(ty) & 0xFF] & TYFL.TYFLfunc);
}

/* Detect function type where parameters are pushed in reverse order	*/
ubyte tyrevfunc(ulong ty) {
	return (tytab2[(ty) & 0xFF] & TYFL.TYFLrevparam);
}

/* Detect unsigned types */
ubyte tyuns(ulong ty) {
	return (tytab[(ty) & 0xFF] & (TYFL.TYFLuns | TYFL.TYFLptr));
}

/* Target dependent info	*/
version (TX86) {
///	#define TYoffset TYuint		/* offset to an address		*/

	/* Detect cpp function type (callee cleans up stack)	*/
	ubyte typfunc(uint ty) {
		return (tytab2[(ty) & 0xFF] & TYFL.TYFLpascal);
	}
} else {
	/* Detect cpp function type (callee cleans up stack)	*/
	ubyte typfunc(uint ty) {
		return (tytab2[(ty) & 0xFF] & TYFL.TYFLcallstkc);
	}
}

/* Array to convert a type to its unsigned equivalent	*/
extern(C++) extern tym_t* get_tytouns();

tym_t touns(ulong ty) {
	return get_tytouns[ty & 0xFF];
}

/* Determine if TYffunc or TYfpfunc (a far function) */
ubyte tyfarfunc(uint ty)	{
	return (tytab2[(ty) & 0xFF] & TYFL.TYFLfarfunc);
}

/+
// Determine if parameter can go in register for TYjfunc
#ifndef tyjparam
#define tyjparam(ty)	(tysize(ty) <= intsize && !tyfloating(ty) && tybasic(ty) != TYstruct)
#endif

/* Determine relaxed type	*/
#ifndef tyrelax
#define tyrelax(ty)	(_tyrelax[tybasic(ty)])
#endif
+/
