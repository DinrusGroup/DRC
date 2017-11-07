module dmd.backend.Config;

import dmd.common;
import dmd.backend.LINKAGE;
import dmd.EnumUtils;

extern (C) {
	void cod3_set64();
	void cod3_set386();
}


debug {

version (Windows) {
	extern (C++) extern
	{
		__gshared char debuga;		/* cg - watch assignaddr()		*/
		__gshared char debugb;		/* watch block optimization		*/
		__gshared char debugc;		/* watch code generated			*/
		__gshared char debugd;		/* watch debug information generated	*/
		__gshared char debuge;		// dump eh info
		__gshared char debugf;		/* trees after dooptim			*/
		__gshared char debugg;		/* trees for code generator		*/
		__gshared char debugo;		// watch optimizer
		__gshared char debugr;		// watch register allocation
		__gshared char debugs;		/* watch common subexp eliminator	*/
		__gshared char debugt;		/* do test points			*/
		__gshared char debugu;
		__gshared char debugw;		/* watch progress			*/
		__gshared char debugx;		/* suppress predefined CPP stuff	*/
		__gshared char debugy;		/* watch output to il buffer		*/
	}
} else {
	extern (C) extern
	{
		__gshared char debuga;		/* cg - watch assignaddr()		*/
		__gshared char debugb;		/* watch block optimization		*/
		__gshared char debugc;		/* watch code generated			*/
		__gshared char debugd;		/* watch debug information generated	*/
		__gshared char debuge;		// dump eh info
		__gshared char debugf;		/* trees after dooptim			*/
		__gshared char debugg;		/* trees for code generator		*/
		__gshared char debugo;		// watch optimizer
		__gshared char debugr;		// watch register allocation
		__gshared char debugs;		/* watch common subexp eliminator	*/
		__gshared char debugt;		/* do test points			*/
		__gshared char debugu;
		__gshared char debugw;		/* watch progress			*/
		__gshared char debugx;		/* suppress predefined CPP stuff	*/
		__gshared char debugy;		/* watch output to il buffer		*/
	}
}

}

// This part of the configuration is saved in the precompiled header for use
// in comparing to make sure it hasn't changed.

enum CFG2
{
	CFG2comdat = 1,	// use initialized common blocks
	CFG2nodeflib = 2,	// no default library imbedded in OBJ file
	CFG2browse = 4,	// generate browse records
	CFG2dyntyping = 8,	// generate dynamic typing information
	CFG2fulltypes = 0x10,	// don't optimize CV4 class info
	CFG2warniserr = 0x20,	// treat warnings as errors
	CFG2phauto = 0x40,	// automatic precompiled headers
	CFG2phuse = 0x80,	// use precompiled headers
	CFG2phgen = 0x100,	// generate precompiled header
	CFG2once = 0x200,	// only include header files once
	CFG2hdrdebug = 0x400,	// generate debug info for header
	CFG2phautoy = 0x800,	// fast build precompiled headers
	CFG2noobj = 0x1000,	// we are not generating a .OBJ file
	CFG2noerrmax = 0x4000,	// no error count maximum
	CFG2expand = 0x8000,	// expanded output to list file
	CFG2seh	= 0x10000,	// use Win32 SEH to support any exception handling
	CFGX2 = (CFG2warniserr | CFG2phuse | CFG2phgen | CFG2phauto | CFG2once | CFG2hdrdebug | CFG2noobj | CFG2noerrmax | CFG2expand | CFG2nodeflib),
}

enum CFG3ju = 1;	// char == unsigned char
enum CFG3eh = 4;	// generate exception handling stuff
enum CFG3strcod = 8;	// strings are placed in code segment
enum CFG3eseqds = 0x10;	// ES == DS at all times
enum CFG3ptrchk = 0x20;	// generate pointer validation code
enum CFG3strictproto = 0x40;	// strict prototyping
enum CFG3autoproto = 0x80;	// auto prototyping
enum CFG3rtti = 0x100;	// add RTTI support
enum CFG3relax = 0x200;	// relaxed type checking (C only)
enum CFG3cpp = 0x400;	// C++ compile
enum CFG3igninc = 0x800;	// ignore standard include directory
version (POSIX) {///TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS) {
enum CFG3mars = 0x1000;	// use mars libs and headers
enum NO_FAR	= true;	// always ignore __far and __huge keywords
} else {
enum CFG3nofar = 0x1000;	// ignore __far and __huge keywords
///enum NO_FAR = (config.flags3 & CFG3nofar);
}
enum CFG3noline = 0x2000;	// do not output #line directives
enum CFG3comment = 0x4000;	// leave comments in preprocessed output
enum CFG3cppcomment = 0x8000;	// allow C++ style comments
enum CFG3wkfloat = 0x10000;	// make floating point references weak externs
enum CFG3digraphs = 0x20000;	// support ANSI C++ digraphs
///#if TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
enum CFG3semirelax = 0x40000;	// moderate relaxed type checking
///#endif
enum CFG3pic = 0x80000;	// position independent code
enum CFGX3 = (CFG3strcod | CFG3ptrchk);

enum CFG4speed = 1;	// optimized for speed
enum CFG4space = 2;	// optimized for space
enum CFG4optimized = (CFG4speed | CFG4space);
enum CFG4allcomdat = 4;	// place all functions in COMDATs
enum CFG4fastfloat = 8;	// fast floating point (-ff)
enum CFG4fdivcall = 0x10;	// make function call for FDIV opcodes
enum CFG4tempinst = 0x20;	// instantiate templates for undefined functions
enum CFG4oldstdmangle = 0x40;	// do stdcall mangling without @
enum CFG4pascal = 0x80;	// default to pascal linkage
enum CFG4stdcall = 0x100;	// default to std calling convention
enum CFG4cacheph = 0x200;	// cache precompiled headers in memory
enum CFG4alternate = 0x400;	// if alternate digraph tokens
enum CFG4bool = 0x800;	// support 'bool' as basic type
enum CFG4wchar_t = 0x1000;	// support 'wchar_t' as basic type
enum CFG4notempexp = 0x2000;	// no instantiation of template functions
enum CFG4anew = 0x4000;	// allow operator new[] and delete[] overloading
enum CFG4oldtmangle = 0x8000;	// use old template name mangling
enum CFG4dllrtl = 0x10000;	// link with DLL RTL
enum CFG4noemptybaseopt = 0x40000;	// turn off empty base class optimization
enum CFG4stackalign = CFG4speed;	// align stack to 8 bytes
enum CFG4nowchar_t = 0x80000;	// use unsigned short name mangling for wchar_t
enum CFG4forscope = 0x100000; // new C++ for scoping rules
enum CFG4warnccast = 0x200000; // warn about C style casts
enum CFG4adl = 0x400000; // argument dependent lookup
enum CFG4enumoverload = 0x800000; // enum overloading
enum CFG4implicitfromvoid = 0x1000000;	// allow implicit cast from void* to T*
enum CFG4dependent = 0x2000000;	// dependent / non-dependent lookup
enum CFG4wchar_is_long = 0x4000000;	// wchar_t is 4 bytes
enum CFG4underscore = 0x8000000;	// prepend _ for C mangling
enum CFGX4 = (CFG4optimized | CFG4fastfloat | CFG4fdivcall | CFG4tempinst | CFG4cacheph | CFG4notempexp | CFG4stackalign | CFG4dependent);
enum CFGY4 = (CFG4nowchar_t | CFG4noemptybaseopt | CFG4adl | CFG4enumoverload | CFG4implicitfromvoid | CFG4wchar_is_long | CFG4underscore);

mixin(BringToCurrentScope!(CFG2));

enum TARGET
{
	TARGET_8086=		0,
	TARGET_80286=		2,
	TARGET_80386=		3,
	TARGET_80486=		4,
	TARGET_Pentium=		5,
	TARGET_PentiumMMX=	6,
	TARGET_PentiumPro=	7,
	TARGET_PentiumII=	8,
	TARGET_AMD64=		9,	//(32 or 64 bit mode)
}

mixin(BringToCurrentScope!(TARGET));

struct Config
{
    char language;		// 'C' = C, 'D' = C++
//#define CPP (config.language == 'D')
    char[8] version_;		// = VERSION
    char[3] exetype;		// distinguish exe types so PH
				// files are distinct (= SUFFIX)

    char target_cpu;		// instruction selection
    char target_scheduler;	// instruction scheduling (normally same as selection)

    short versionint;		// intermediate file version (= VERSIONINT)
    int defstructalign;		// struct alignment specified by command line
    short hxversion;		// HX version number
    char fulltypes;
    uint wflags;		// flags for Windows code generation

    char inline8087;		/* 0:	emulator
				   1:	IEEE 754 inline 8087 code
				   2:	fast inline 8087 code
				 */
    short memmodel;		// 0:S,X,N,F, 1:M, 2:C, 3:L, 4:V
    uint exe;		// target operating system

///#define EX_flat		(EX_OS2 | EX_NT | EX_LINUX | EX_WIN64 | EX_LINUX64 | \
///			 EX_OSX | EX_OSX64 | EX_FREEBSD | EX_FREEBSD64 | \
///			 EX_SOLARIS | EX_SOLARIS64)
///#define EX_dos		(EX_DOSX | EX_ZPM | EX_RATIONAL | EX_PHARLAP | \
///			 EX_COM | EX_MZ /*| EX_WIN16*/)

/* CFGX: flags ignored in precompiled headers
 * CFGY: flags copied from precompiled headers into current config
 */
    uint flags;
    uint flags2;
    uint flags3;
    uint flags4;
    uint flags5;
///#define CFG5debug	1	// compile in __debug code
///#define CFG5in		2	// compile in __in code
///#define CFG5out		4	// compile in __out code
///#define CFG5invariant	8	// compile in __invariant code

///#if HTOD
///    unsigned htodFlags;		// configuration for htod
///#define HTODFinclude	1	// -hi drill down into #include files
///#define HTODFsysinclude	2	// -hs drill down into system #include files
///#define HTODFtypedef	4	// -ht drill down into typedefs
///#define HTODFcdecl	8	// -hc skip C declarations as comments
///#endif
    char ansi_c;		// strict ANSI C
				// 89 for ANSI C89, 99 for ANSI C99
    char asian_char;		/* 0: normal, 1: Japanese, 2: Chinese	*/
				/* and Taiwanese, 3: Korean		*/
    uint threshold;		// data larger than threshold is assumed to
				// be far (16 bit models only)
///#define THRESHMAX 0xFFFF	// if threshold == THRESHMAX, all data defaults
				// to near
    LINKAGE linkage;	// default function call linkage
}

version (Windows) {
	extern (C++) extern __gshared Config config;
} else {
	extern (C) extern __gshared Config config;
}

enum CVNONE = 0;		// No symbolic info
enum CVOLD = 1;		// Codeview 1 symbolic info
enum CV4 = 2;		// Codeview 4 symbolic info
enum CVSYM = 3;		// Symantec format
enum CVTDB = 4;		// Symantec format written to file
enum CVDWARF_C = 5;		// Dwarf in C format
enum CVDWARF_D = 6;		// Dwarf in D format
enum CVSTABS = 7;		// Elf Stabs in C format

enum CFGuchar = 1;	// chars are unsigned
enum CFGsegs = 2;	// new code seg for each far func
enum CFGtrace = 4;	// output trace functions
enum CFGglobal = 8;	// make all static functions global
enum CFGstack = 0x20;	// add stack overflow checking
enum CFGalwaysframe = 0x40;	// always generate stack frame
enum CFGnoebp = 0x80;	// do not use EBP as general purpose register
enum CFGromable = 0x100;	// put switch tables in code segment
enum CFGeasyomf = 0x200;	// generate Pharlap Easy-OMF format
enum CFGfarvtbls = 0x800;	// store vtables in far segments
enum CFGnoinlines = 0x1000;	// do not inline functions
enum CFGnowarning = 0x8000;	// disable warnings
enum CFGX = (CFGnowarning);

enum EX_DOSX = 1;	// DOSX 386 program
enum EX_ZPM = 2;	// ZPM 286 program
enum EX_RATIONAL = 4;	// RATIONAL 286 program
enum EX_PHARLAP = 8;	// PHARLAP 386 program
enum EX_COM = 0x10;	// MSDOS .COM program
//#define EX_WIN16	0x20	// Windows 3.x 16 bit program
enum EX_OS2 = 0x40;	// OS/2 2.0 32 bit program
enum EX_OS1 = 0x80;	// OS/2 1.x 16 bit program
enum EX_NT = 0x100;	// NT
enum EX_MZ = 0x200;	// MSDOS real mode program
enum EX_XENIX = 0x400;
enum EX_SCOUNIX = 0x800;
enum EX_UNIXSVR4 = 0x1000;
enum EX_LINUX = 0x2000;
enum EX_WIN64 = 0x4000;	// AMD64 and Windows (64 bit mode)
enum EX_LINUX64 = 0x8000;	// AMD64 and Linux (64 bit mode)
enum EX_OSX = 0x10000;
enum EX_OSX64 = 0x20000;
enum EX_FREEBSD = 0x40000;
enum EX_FREEBSD64 = 0x80000;
enum EX_SOLARIS = 0x100000;
enum EX_SOLARIS64 = 0x200000;

enum WFwindows = 1;	// generating code for Windows app or DLL
enum WFdll = 2;	// generating code for Windows DLL
enum WFincbp = 4;	// mark far stack frame with inc BP / dec BP
enum WFloadds = 8;	// assume __loadds for all functions
enum WFexpdef = 0x10;	// generate export definition records for
				// exported functions
enum WFss = 0x20;	// load DS from SS
enum WFreduced = 0x40;	// skip DS load for non-exported functions
enum WFdgroup = 0x80;	// load DS from DGROUP
enum WFexport = 0x100;	// assume __export for all far functions
enum WFds = 0x200;	// load DS from DS
enum WFmacros = 0x400;	// define predefined windows macros
enum WFssneds = 0x800;	// SS != DS
enum WFthunk = 0x1000;	// use fixups instead of direct ref to CS
enum WFsaveds = 0x2000;	// use push/pop DS for far functions
enum WFdsnedgroup = 0x4000;	// DS != DGROUP
enum WFexe = 0x8000;	// generating code for Windows EXE
