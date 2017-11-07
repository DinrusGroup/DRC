module dmd.backend.Symbol;

import dmd.common;
import dmd.backend.dt_t;
import dmd.backend.TYPE;
import dmd.backend.LIST;
import dmd.backend.block;
import dmd.backend.func_t;
import dmd.backend.enum_t;
import dmd.backend.elem;
import dmd.backend.struct_t;
import dmd.backend.template_t;
import dmd.backend.targ_types;
import dmd.backend.vec_t;
import dmd.backend.SYMIDX;
import dmd.backend.regm_t;
import dmd.backend.Util;

struct Symbol
{
    ushort	id;

    Symbol* Sl;
	Symbol* Sr;		// left, right child

    Symbol *Snext;		// next in threaded list

    dt_t* Sdt;			// variables: initializer
    type* Stype;		// type of Symbol

    tym_t ty()
	{
		return Stype.Tty;
	}

    union			// variants for different Symbol types
    {
		enum_t* Senum;		// SCenum
		struct
		{    
			func_t* Sfunc;	// tyfunc
			list_t Spath1;	// SCfuncalias member functions: same as Spath
					// and in same position
					// SCadl: list of associated functions for ADL lookup
		}
		struct			// SClabel
		{   
			int Slabel;		// TRUE if label was defined
			block* Slabelblk;	// label block
		}
///		#define Senumlist Senum->SEenumlist

		struct			// SClinkage
		{
			int Slinkage;	// tym linkage bits
			uint Smangle;
		}

		struct
		{
			char Sbit;		// SCfield: bit position of start of bit field
			char Swidth;	// SCfield: width in bits of bit field
			targ_size_t Smemoff; // SCmember,SCfield: offset from start of struct
		}

		elem* Svalue;		/* SFLvalue: value of const
				   SFLdtorexp: for objects with destructor,
				   conditional expression to precede dtor call
				 */

		struct_t* Sstruct;	// SCstruct
		template_t* Stemplate;	// SCtemplate
		Symbol* Simport;	// SCextern: if dllimport Symbol, this is the
				// Symbol it was imported from

		ubyte Spreg;	// SCfastpar: register parameter is passed in
    }

    Symbol* Sscope;		// enclosing scope (could be struct tag,
				// enclosing inline function for statics,
				// or namespace)
///#define isclassmember(s)	((s)->Sscope && (s)->Sscope->Sclass == SCstruct)

    const(char)* prettyIdent;	// the symbol identifer as the user sees it

version (ELFOBJ_OR_MACHOBJ)
{
    ptrdiff_t     obj_si;       // Symbol index of coff or elf symbol
    size_t        dwarf_off;    // offset into .debug section
    targ_size_t   code_off;	// rel. offset from start of block where var is initialized
    targ_size_t   last_off;	// last offset using var
}
version (TARGET_OSX)
{
    targ_size_t Slocalgotoffset;
}

    enum_SC Sclass;		// storage class (SCxxxx)
    char Sfl;			// flavor (FLxxxx)
    SYMFLGS Sflags;		// flag bits (SFLxxxx)

    vec_t	Srange;		// live range, if any
    vec_t	Slvreg;		// when symbol is in register
    targ_size_t Ssize;		// tyfunc: size of function
    targ_size_t Soffset;	// variables: offset of Symbol in its storage class

    SYMIDX Ssymnum;		// Symbol number (index into globsym.tab[])
				// SCauto,SCparameter,SCtmp,SCregpar,SCregister

    short Sseg;			// segment index

    int Sweight;		// usage count, the higher the number,
				// the more worthwhile it is to put in
				// a register
    union
    {
		uint Sxtrnnum;	// SCcomdef,SCextern,SCcomdat: external symbol # (starting from 1)
		uint Stypidx;	// SCstruct,SCunion,SCclass,SCenum,SCtypedef: debug info type index

		struct
		{ 
			ubyte Sreglsw;
			ubyte Sregmsw;
			regm_t Sregm;	// mask of registers
		}
    }

    regm_t	Sregsaved;	// mask of registers not affected by this func

    char[35] Sident;	// identifier string (dynamic array)
				// (the size is for static Symbols)

    bool needThis()	// true if symbol needs a 'this' pointer
	{
		assert(false);
	}
}

void dumpSymbol(Symbol* foo)
{
	foreach (a, b; foo.tupleof)
	{
		static if (typeof(foo.tupleof[a]).stringof != "char[35u]") {
			std.stdio.writeln(foo.tupleof[a].stringof, " ", cast(char*)&foo.tupleof[a] - cast(char*)foo, " = ", cast(int)foo.tupleof[a]);
			//std.stdio.writeln("printf(\"", foo.tupleof[a].stringof, " %d = %d\\n\",(char*)(&", foo.tupleof[a].stringof, ")-(char*)foo, ", foo.tupleof[a].stringof, ");");
		}
	}
	
	std.stdio.writefln("(*foo).Sclass %d = %d", (cast(char*)&foo.Sclass - cast(char*)foo), cast(int)foo.Sclass);
	//std.stdio.writeln("printf(\"(*foo).Sclass %d %d\\n\", ((char*)&foo->Sclass - (char*)foo), (int)foo->Sclass);");
}