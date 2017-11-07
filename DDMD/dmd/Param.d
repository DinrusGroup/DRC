module dmd.Param;

import dmd.common;
import dmd.Array;
import dmd.OutBuffer;

// Put command line switches in here
struct Param
{
    bool obj;		// write object file
    bool link;		// perform link
    bool lib;		// write library file instead of object file(s)
    bool multiobj;	// break one object file into multiple ones
    bool oneobj;	// write one object file instead of multiple ones
    bool trace;		// insert profiling hooks
    bool quiet;		// suppress non-error messages
    bool verbose;	// verbose compile
    bool vtls;		// identify thread local variables
    byte symdebug;	// insert debug symbolic information
    bool optimize;	// run optimizer
    bool map;		// generate linker .map file
    bool cpu;		// target CPU
    bool isX86_64;	// generate X86_64 bit code
    bool isLinux;	// generate code for linux
    bool isOSX;		// generate code for Mac OSX
    bool isWindows;	// generate code for Windows
    bool isFreeBSD;	// generate code for FreeBSD
    bool isSolaris;	// generate code for Solaris
    bool scheduler;	// which scheduler to use
    bool useDeprecated;	// allow use of deprecated features
    bool useAssert;	// generate runtime code for assert()'s
    bool useInvariants;	// generate class invariant checks
    bool useIn;		// generate precondition checks
    bool useOut;	// generate postcondition checks
    byte useArrayBounds; // 0: no array bounds checks
			 // 1: array bounds checks for safe functions only
			 // 2: array bounds checks for all functions
    bool noboundscheck;	// no array bounds checking at all
    bool useSwitchError; // check for switches without a default
    bool useUnitTests;	// generate unittest code
    bool useInline;	// inline expand functions
    bool release;	// build release version
    bool preservePaths;	// !=0 means don't strip path from source file
    bool warnings;	// enable warnings
    bool pic;		// generate position-independent-code for shared libs
    bool cov;		// generate code coverage data
    bool nofloat;	// code should not pull in floating point support
    byte Dversion;	// D version number
    bool ignoreUnsupportedPragmas;	// rather than error on them

    string argv0;	// program name
    Array imppath;	// array of char*'s of where to look for import modules
    Array fileImppath;	// array of char*'s of where to look for file import modules
    string objdir;	// .obj/.lib file output directory
    string objname;	// .obj file output name
    string libname;	// .lib file output name

    bool doDocComments;	// process embedded documentation comments
    string docdir;	// write documentation file to docdir directory
    string docname;	// write documentation file to docname
    Array ddocfiles;	// macro include files for Ddoc

    bool doHdrGeneration;	// process embedded documentation comments
    string hdrdir;		// write 'header' file to docdir directory
    string hdrname;		// write 'header' file to docname

	bool doXGeneration; // write JSON file
	string xfilename;	// write JSON file to xfilename

    uint debuglevel;	// debug level
    Vector!string debugids;		// debug identifiers

    uint versionlevel;	// version level
    Vector!(string) versionids;		// version identifiers

    bool dump_source;

    const(char)* defaultlibname;	// default library for non-debug builds
    const(char)* debuglibname;	// default library for debug builds

    string moduleDepsFile;	// filename for deps output
    OutBuffer moduleDeps;	// contents to be written to deps file

    // Hidden debug switches
    bool debuga;
    bool debugb;
    bool debugc;
    bool debugf;
    bool debugr;
    bool debugw;
    bool debugx;
    bool debugy;

    bool run;		// run resulting executable
    size_t runargs_length;
    string[] runargs;	// arguments for executable

    // Linker stuff
    Array objfiles;
    Array linkswitches;
    Array libfiles;
    string deffile;
    string resfile;
    string exefile;
    string mapfile;
}
