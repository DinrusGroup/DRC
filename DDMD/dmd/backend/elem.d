module dmd.backend.elem;

import dmd.common;
import dmd.Port;
import dmd.Complex;

import dmd.backend.targ_types;
import dmd.backend.Symbol;
import dmd.backend.PARAM;
import dmd.backend.LIST;
import dmd.backend.Classsym;
import dmd.backend.TYPE;
import dmd.backend.Util;
import dmd.backend.Srcpos;
import dmd.backend.OPER;

/*********************************
 * Union of all data types. Storage allocated must be the right
 * size of the data on the TARGET, not the host.
 */

union eve
{
	targ_char	Vchar;
	targ_schar	Vschar;
	targ_uchar	Vuchar;
	targ_short	Vshort;
	targ_ushort	Vushort;
	targ_int	Vint;	 // also used for tmp numbers (FLtmp)
	targ_uns	Vuns;
	targ_long	Vlong;
	targ_ulong	Vulong;
	targ_llong	Vllong;
	targ_ullong	Vullong;
	targ_float	Vfloat;
	targ_double	Vdouble;
    targ_ldouble	Vldouble;
	Complex!(float)	Vcfloat;
	Complex!(double)Vcdouble;
	Complex!(real)	Vcldouble;
	targ_size_t	Vpointer;
	targ_ptrdiff_t	Vptrdiff;
	targ_uchar Vreg;	// register number for OPreg elems

	struct VFP			// 48 bit 386 far pointer
	{   targ_long	Voff;
	    targ_ushort	Vseg;
	} VFP Vfp;

	struct SP
	{
	    targ_size_t Voffset;// offset from symbol
	    Symbol* Vsym;	// pointer to symbol table
	    union SPU
	    {	
			PARAM* Vtal;	// template-argument-list for SCfunctempl,
				// used only to transmit it to cpp_overload()
			LIST* Erd;	// OPvar: reaching definitions
	    } SPU spu;
	} SP sp;

	struct SM
	{
	    targ_size_t Voffset;// member pointer offset
	    Classsym* Vsym;	// struct tag
	    elem* ethis;	// OPrelconst: 'this' for member pointer
	} SM sm;

	struct SS
	{
	    targ_size_t	Voffset;// offset from string
	    char* Vstring;	// pointer to string (OPstring or OPasm)
	    targ_size_t	Vstrlen;// length of string
	} SS ss;

	struct EOP
	{   
	    elem* Eleft;	// left child for unary & binary nodes
	    elem* Eright;	// right child for binary nodes
	    Symbol* Edtor;	// OPctor: destructor
	} EOP eop;
}				// variants for each type of elem

/******************************************
 * Elems:
 *	Elems are the basic tree element. They can be either
 *	terminal elems (leaves), unary elems (left subtree exists)
 *	or binary elems (left and right subtrees exist).
 */
struct elem
{
debug {
    ushort	id;
}

    OPER	Eoper;	// operator (OPxxxx)
    ubyte	Ecount;	// # of parents of this elem - 1,
				// always 0 until CSE elimination is done
    eve EV;		// variants for each type of elem
	
	ref elem* E1()
	{
		return EV.eop.Eleft;		/* left child			*/
	}

	ref elem* E2()
	{
		return EV.eop.Eright;		/* right child			*/
	}

	ref LIST* Erd()
	{
		return EV.sp.spu.Erd;		// reaching definition
	}
	
    union
    {
		// PARSER
		struct
		{
			TYPE* ET;	// pointer to type of elem
			ubyte PEFflags;
		}

		// OPTIMIZER
		struct
		{
			tym_t Ety;			// data type (TYxxxx)
			uint Eexp;		// index into expnod[]

			// These flags are all temporary markers, used once and then
			// thrown away.
			ubyte Nflags;	// NFLxxx
version (MARS) {
			ubyte Ejty;		// original Jupiter/Mars type
}
		}

		// CODGEN
		struct
		{
			// Ety2: Must be in same position as Ety!
			tym_t Ety2;			// data type (TYxxxx)
			ubyte Ecomsub;	// number of remaining references to
						// this common subexp (used to determine
						// first, intermediate, and last references
						// to a CSE)

version (TARGET_POWERPC) {
			ubyte Gflags;
}
		}
    }

    targ_size_t Enumbytes;	// number of bytes for type if TYstruct | TYarray
//    TARGET_structELEM		// target specific additions
    Srcpos Esrcpos;		// source file position
}