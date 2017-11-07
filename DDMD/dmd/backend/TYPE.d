module dmd.backend.TYPE;

import dmd.common;
import dmd.backend.Util;
import dmd.backend.Srcpos;
import dmd.backend.elem;
import dmd.backend.LIST;
import dmd.backend.TYM;
import dmd.backend.PARAM;
import dmd.backend.targ_types;
import dmd.backend.Classsym;

struct TYPE
{
debug {
    ushort	id;
	enum IDtype = 0x1234;
///#define type_debug(t) assert((t)->id == IDtype)
} else {
///#define type_debug(t)
}

    tym_t	Tty;		/* mask (TYxxx)				*/
    ushort Tflags;	// TFxxxxx

version (TX86) {
version (POSIX) { ///TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
///#define mTYnoret	0x010000	// function has no return
///#define mTYtransu	0x010000	// transparent union
} else {
///#define mTYfar16	0x010000
}
///#define mTYstdcall	0x020000
///#define mTYfastcall	0x040000
///#define mTYinterrupt	0x080000
///#define mTYcdecl	0x100000
///#define mTYpascal	0x200000
///#define mTYsyscall	0x400000
///#define mTYjava		0x800000

version (POSIX) { ///TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
///#define mTYTFF		0xFE0000
} else {
///#define mTYTFF		0xFF0000
}


///#define TARGET_strucTYPE
    mangle_t Tmangle;		// name mangling
// Return name mangling of type
///#define type_mangle(t)	((t)->Tmangle)
}

    uint Tcount;		// # pointing to this type
    TYPE* Tnext;		// next in list
				// TYenum: gives base type
    union
    {
		targ_size_t Tdim;	// TYarray: # of elements in array
		elem* Tel;	// TFvla: gives dimension (NULL if '*')
		PARAM* Tparamtypes; // TYfunc, TYtemplate: types of function parameters
		Classsym* Ttag;	// TYstruct,TYmemptr: tag symbol
				// TYenum,TYvtshape: tag symbol
		char* Tident;		// TYident: identifier
version (SCPP) {
		TYPE* Talternate;	// typtr: type of parameter before converting
}
version (MARS) {
		TYPE* Tkey;	// typtr: key type for associative arrays
}
    }

    list_t Texcspec;		// tyfunc(): list of types of exception specification

static if (false) {
    ushort Tstabidx;	// Index into stab types
}
///    TARGET_strucTYPE
version (SOURCE_4TYPES) {
    Srcpos Tsrcpos;		/* position of type definition */
}
version (HTOD) {
    Symbol* Ttypedef;		// if this type came from a typedef, this is
				// the typedef symbol
}
}

void dumpTYPE(TYPE* foo)
{
	foreach (a, b; foo.tupleof)
	{
		std.stdio.writeln(foo.tupleof[a].stringof, " ", cast(char*)&foo.tupleof[a] - cast(char*)foo, " = ", foo.tupleof[a]);
		//std.stdio.writeln("printf(\"", foo.tupleof[a].stringof, " %d = %d\\n\",(char*)(&", foo.tupleof[a].stringof, ")-(char*)foo, ", foo.tupleof[a].stringof, ");");
	}
}

alias TYPE type;

alias type* typep_t;

version (Windows) {
	extern(C++) extern __gshared typep_t[TYM.TYMAX] tstypes;
	extern(C++) extern __gshared typep_t[TYM.TYMAX] tsptr2types;
} else {
	extern(C) extern __gshared typep_t[TYM.TYMAX] tstypes;
	extern(C) extern __gshared typep_t[TYM.TYMAX] tsptr2types;
}

ref type* tsbool	  () { return tstypes[TYM.TYbool]; }
ref type* tschar    () { return tstypes[TYM.TYchar]; }
ref type* tsschar   () { return tstypes[TYM.TYschar]; }
ref type* tsuchar   () { return tstypes[TYM.TYuchar]; }
ref type* tsshort   () { return tstypes[TYM.TYshort]; }
ref type* tsushort  () { return tstypes[TYM.TYushort]; }
ref type* tswchar_t () { return tstypes[TYM.TYwchar_t]; }
ref type* tsint     () { return tstypes[TYM.TYint]; }
ref type* tsuns     () { return tstypes[TYM.TYuint]; }
ref type* tslong    () { return tstypes[TYM.TYlong]; }
ref type* tsulong   () { return tstypes[TYM.TYulong]; }
ref type* tsdchar   () { return tstypes[TYM.TYdchar]; }
ref type* tsllong   () { return tstypes[TYM.TYllong]; }
ref type* tsullong  () { return tstypes[TYM.TYullong]; }
ref type* tsfloat   () { return tstypes[TYM.TYfloat]; }
ref type* tsdouble  () { return tstypes[TYM.TYdouble]; }
ref type* tsreal64  () { return tstypes[TYM.TYdouble_alias]; }
ref type* tsldouble () { return tstypes[TYM.TYldouble]; }
ref type* tsvoid    () { return tstypes[TYM.TYvoid]; }
ref type* tsifloat   () { return tstypes[TYM.TYifloat]; }
ref type* tsidouble  () { return tstypes[TYM.TYidouble]; }
ref type* tsildouble () { return tstypes[TYM.TYildouble]; }
ref type* tscfloat   () { return tstypes[TYM.TYcfloat]; }
ref type* tscdouble  () { return tstypes[TYM.TYcdouble]; }
ref type* tscldouble () { return tstypes[TYM.TYcldouble]; }
