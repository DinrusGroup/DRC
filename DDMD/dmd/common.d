/**
 * this module is imported in all modules in the dmd package
 * and thus can be used for commonly used aliases etc.
 */
module dmd.common;

// versions specified in a module are local to that module even if the module is imported by another one, see code at the bottom
// until a solution is found, at least check the given versions for consistency

pragma(msg, "checking predefined versions for consistency...");

version(DMDV1)
	version(DMDV2)
		static assert(false, "DMDV1 and DMDV2 can't be set both");

version(DMDV2)
{
	version(STRUCTTHISREF) {} else
		static assert(false, "DMDV2 requires STRUCTTHISREF. 'this' for struct is a reference");
	version(SNAN_DEFAULT_INIT) {} else
		static assert(false, "DMDV2 requires SNAN_DEFAULT_INIT. floats are default initialized to signalling NaN");
	version(SARRAYVALUE) {} else
		static assert(false, "DMDV2 requires SARRAYVALUE. static arrays are value types");
}

version(DMDV2)
	version(Posix) // TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS // TODO:
		version(CPP_MANGLE) {} else
			static assert(false, "CPP_MANGLE must be set if DMDV2 and a Posix target is specified. C++ mangling is done by the front end");

version(Win32)
{
	version(_WIN32) {} else
		static assert(false, "Set _WIN32 on Win32");
	version(TARGET_WINDOS) {} else
		static assert(false, "TARGET_WINDOS must be specified on Windows");
	version(OMFOBJ) {} else
		static assert(false, "OMFOBJ must be used on Windows");
}
else version(Win64)
{
	static assert(false, "now we need Win64 support");
}

version(Posix)
	version(POSIX) {} else
		static assert(false, "POSIX must be set on Posix");

version(TARGET_LINUX)
	version(ELFOBJ) {} else
		static assert(false, "TARGET_LINUX requires ELFOBJ");
version(TARGET_FREEBSD)
	version(ELFOBJ) {} else
		static assert(false, "TARGET_FREEBSD requires ELFOBJ");
version(TARGET_SOLARIS)
	version(ELFOBJ) {} else
		static assert(false, "TARGET_SOLARIS requires ELFOBJ");

version(TARGET_OSX)
	version(MACHOBJ) {} else
		static assert(false, "TARGET_OSX requires MACHOBJ");

version(CCASTSYNTAX) {} else
	static assert(false, `CCASTSYNTAX is needed for code like "(void*).sizeof"`);

version(CARRAYDECL) {} else
	static assert(false, "C array declarations are used in phobos so we still need CARRAYDECL");


version(IN_GCC) // Changes for the GDC compiler by David Friedman
{
	static assert(false, "IN_GCC is not supported");
}

/+
/*
It is very important to use version control macros correctly - the
idea is that host and target are independent. If these are done
correctly, cross compilers can be built.
The host compiler and host operating system are also different,
and are predefined by the host compiler. The ones used in
dmd are:

Macros defined by the compiler, not the code:

    Compiler:
	__DMC__		Digital Mars compiler
	_MSC_VER	Microsoft compiler
	__GNUC__	Gnu compiler

    Host operating system:
	_WIN32		Microsoft NT, Windows 95, Windows 98, Win32s,
			Windows 2000, Win XP, Vista
	_WIN64		Windows for AMD64
	linux		Linux
	__APPLE__	Mac OSX
	__FreeBSD__	FreeBSD
	__sun&&__SVR4	Solaris, OpenSolaris (yes, both macros are necessary)

For the target systems, there are the target operating system and
the target object file format:

    Target operating system:
	TARGET_WINDOS	Covers 32 bit windows and 64 bit windows
	TARGET_LINUX	Covers 32 and 64 bit linux
	TARGET_OSX	Covers 32 and 64 bit Mac OSX
	TARGET_FREEBSD	Covers 32 and 64 bit FreeBSD
	TARGET_SOLARIS	Covers 32 and 64 bit Solaris
	TARGET_NET	Covers .Net

    It is expected that the compiler for each platform will be able
    to generate 32 and 64 bit code from the same compiler binary.

    Target object module format:
	OMFOBJ		Intel Object Module Format, used on Windows
	ELFOBJ		Elf Object Module Format, used on linux, FreeBSD and Solaris
	MACHOBJ		Mach-O Object Module Format, used on Mac OSX

    There are currently no macros for byte endianness order.
 */
//version definitions from mars.h

pragma(msg, "setting up versions...");

// default to DMDV2
version(DMDV1) {} else
version = DMDV2; // Version 2.0 features
version = BREAKABI;	// 0 if not ready to break the ABI just yet
version(DMDV2)
{
	version = STRUCTTHISREF;	// if 'this' for struct is a reference, not a pointer
	version = SNAN_DEFAULT_INIT;// if floats are default initialized to signalling NaN
	version = SARRAYVALUE;		// static arrays are value types
}

// Set if C++ mangling is done by the front end
version(DMDV2)
{
	version(Posix) // TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
		version = CPP_MANGLE;
}

/* Other targets are TARGET_LINUX, TARGET_OSX, TARGET_FREEBSD and
 * TARGET_SOLARIS, which are
 * set on the command line via the compiler makefile.
 */

version(Win32)
{
	version = _WIN32;
	version = TARGET_WINDOS;		// Windows dmd generates Windows targets
	version = OMFOBJ;
}
else version(Win64)
{
	static assert(false, "now we need Win64 support");
}

version(Posix)
	version = POSIX;

version(TARGET_LINUX)
	version = ELFOBJ;
version(TARGET_FREEBSD)
	version = ELFOBJ;
version(TARGET_SOLARIS)
	version = ELFOBJ;


version(TARGET_OSX)
	version = MACHOBJ;

/* TODO:
//Modify OutBuffer::writewchar to write the correct size of wchar
#if _WIN32
#define writewchar writeword
#else
//This needs a configuration test...
#define writewchar write4
#endif

#define INTERFACE_OFFSET	0	// if 1, put classinfo as first entry
//in interface vtbl[]'s
#define INTERFACE_VIRTUAL	0	// 1 means if an interface appears
//in the inheritance graph multiple
//times, only one is used
*/
+/