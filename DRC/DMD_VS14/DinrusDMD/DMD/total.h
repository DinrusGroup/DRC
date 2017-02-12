
// Compiler implementation of the D programming language
// Copyright (c) 1999-2006 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

#ifndef DMD_TOTAL_H
#define DMD_TOTAL_H

#include <stdio.h>
#include <stdlib.h>
#ifndef VAX11C
#include <string.h>
#endif
#include <assert.h>
#include <wchar.h>
#include <stdint.h>
#include <stdarg.h>
#ifndef assert
#include        <assert.h>
#endif

//#include "root.h"
//#include "stringtable.h"
//dchar.h
//lstring.h

//#include "arraytypes.h"
//#include "mars.h"
//#include "lexer.h"
//#include "parse.h"
//#include "identifier.h"
//#include "enum.h"
//#include "aggregate.h"
//#include "mtype.h"
//#include "expression.h"
//#include "declaration.h"
//#include "statement.h"
//#include "scope.h"
//#include "import.h"
//#include "module.h"
//#include "id.h"
//#include "cond.h"
//#include "version.h"
//#include "lib.h"
//init.h


#if __GNUC__ && !_WIN32
#include "gnuc.h"
#endif

#if BSDUNIX
#include        <pwd.h>
#endif

#if M_UNIX || M_XENIX || linux || __APPLE__ || __FreeBSD__ || __sun&&__SVR4
#include        <stdlib.h>
//#include        <unistd.h>
#endif

#if MSDOS || __OS2__ || __NT__ || _WIN32
#include        <direct.h>
#include        <ctype.h>
#endif

#if _MSC_VER
#pragma warning (disable : 4514)
#include <float.h> 
#include <malloc.h>
#endif

#ifdef __DMC__
#pragma once
 typedef _Complex long double complex_t;
#ifdef DEBUG
#undef assert
#define assert(e) (static_cast<void>((e) || (printf("assert %s(%d) %s\n", __FILE__, __LINE__, #e), halt())))
#endif
#endif

#ifdef IN_GCC
#include "d-gcc-complex_t.h"
#define stdmsg stderr
#else
  //#include "complex_t.h"
 // #include "d-gcc-real.h"
  #define stdmsg stderr
 #endif
 
 #ifdef __APPLE__
  #include "complex.h"
 #endif

#if _WIN32
#define TARGET_WINDOS 1		// Windows dmd generates Windows targets
#define OMFOBJ 1
#define writewchar writeword
#else
#define writewchar write4
#endif

/* Macro to determine if char is a path or drive delimiter      */
#if MSDOS || __OS2__ || __NT__ || _WIN32
#define ispathdelim(c)  ((c) == '\\' || (c) == ':' || (c) == '/')
#else
#ifdef VMS
#define ispathdelim(c)  ((c)==':' || (c)=='[' || (c)==']' )
#else
#ifdef MPW
#define ispathdelim(c)  ((c) == ':')
#else
#define ispathdelim(c)  ((c) == '/')
#endif /* MPW */
#endif /* VMS */
#endif


#if TARGET_LINUX || TARGET_FREEBSD || TARGET_SOLARIS
#ifndef ELFOBJ
#define ELFOBJ 1
#endif
#endif

#if TARGET_OSX
#ifndef MACHOBJ
#define MACHOBJ 1
#endif
#endif



////////////////////////////////////////////////////////////////////
#ifndef GCC_SAFE_DMD
#define TRUE	1
#define FALSE	0
#endif
#define INTERFACE_OFFSET	0
#define INTERFACE_VIRTUAL	0
#define DMDV1	0
#define DMDV2	1	
#define BREAKABI 1	
#define STRUCTTHISREF DMDV2	
#define SNAN_DEFAULT_INIT DMDV2	
#define WINDOWS_SEH	(_WIN32 && __DMC__)
#define CPP_MANGLE (DMDV2 && (TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS))

#undef TEXT
////////////////////////////////////////////////////////////////////

#ifdef M_UNICODE
typedef wchar_t dchar;
#define TEXT(x)		L##x
#define Dchar_mbmax	1
#elif MCBS
#include <limits.h>
#include <mbstring.h>
typedef char dchar;
#define TEXT(x)		x
#define Dchar_mbmax	MB_LEN_MAX
#elif UTF8
typedef char dchar;
#define TEXT(x)		x
#define Dchar_mbmax	6
#endif

// Definition of 64 bit integers depends on platform
#if defined(_MSC_VER)
// Microsofts typenames:
typedef __int64            int64_t;      // 64 bit signed integer
typedef unsigned __int64   uint64_t;     // 64 bit unsigned integer

#else
// This works with most compilers:
typedef long long          int64_t;      // 64 bit signed integer
typedef unsigned long long uint64_t;     // 64 bit unsigned integer
#endif
#endif

typedef long double real_t;
typedef uint64_t dinteger_t;
typedef int64_t sinteger_t;
typedef uint64_t uinteger_t;

typedef int8_t			d_int8;
typedef uint8_t			d_uns8;
typedef int16_t			d_int16;
typedef uint16_t		d_uns16;
typedef int32_t			d_int32;
typedef uint32_t		d_uns32;
typedef int64_t			d_int64;
typedef uint64_t		d_uns64;

typedef float			d_float32;
typedef double			d_float64;
typedef long double		d_float80;

typedef d_uns8			d_char;
typedef d_uns16			d_wchar;
typedef d_uns32			d_dchar;

typedef size_t hash_t;

#if _MSC_VER
#define strtold strtod
#define strtof  strtod
#define isnan   _isnan

typedef __int64 longlong;
typedef unsigned __int64 ulonglong;
#else
typedef long long longlong;
typedef unsigned long long ulonglong;
#endif

typedef unsigned dchar_t;

int utf_isValidDchar(dchar_t c);

const char *utf_decodeChar(unsigned char *s, size_t len, size_t *pidx, dchar_t *presult);
const char *utf_decodeWchar(unsigned short *s, size_t len, size_t *pidx, dchar_t *presult);

const char *utf_validateString(unsigned char *s, size_t len);

extern int isUniAlpha(dchar_t);


///////////////////////////////////////////////////

extern int PTRSIZE;
extern int REALSIZE;
extern int REALPAD;
extern int Tsize_t;
extern int Tptrdiff_t;


///////////////////////////////////////////////////
typedef void* Value;
typedef void* Key;

struct aaA
{
    aaA *next;
    Key key;
    Value value;
};


struct AA
{
    aaA* *b;
    size_t b_length;
    size_t nodes;       // total number of aaA nodes
    aaA* binit[4];      // initial value of b[]
};

size_t _aaLen(AA* aa);
Value* _aaGet(AA** aa, Key key);
Value _aaGetRvalue(AA* aa, Key key);
void _aaRehash(AA** paa);


struct Object
{
    Object();// { }
    virtual ~Object();// { }

    virtual int equals(Object *o);
    virtual hash_t hashCode();
    virtual int compare(Object *obj);
    virtual void print();
    virtual char *toChars();
    virtual dchar *toDchars();
    virtual void toBuffer(OutBuffer *buf);
    virtual int dyncast();
	void mark();
};

struct Array : Object
{
    unsigned dim;
    unsigned allocdim;
    void **data;

    Array();
    ~Array();
    void mark();
    char *toChars();

    void reserve(unsigned nentries);
    void setDim(unsigned newdim);
    void fixDim();
    void push(void *ptr);
    void *pop();
    void shift(void *ptr);
    void insert(unsigned index, void *ptr);
    void insert(unsigned index, Array *a);
    void append(Array *a);
    void remove(unsigned i);
    void zero();
    void *tos();
    void sort();
    Array *copy();
};

struct Param
{
    char obj;		// write object file
    char link;		// perform link
    char lib;		// write library file instead of object file(s)
    char multiobj;	// break one object file into multiple ones
    char oneobj;	// write one object file instead of multiple ones
    char trace;		// insert profiling hooks
    char quiet;		// suppress non-error messages
    char verbose;	// verbose compile
    char vtls;		// identify thread local variables
    char symdebug;	// insert debug symbolic information
    char optimize;	// run optimizer
    char cpu;		// target CPU
    char isX86_64;	// generate X86_64 bit code
    char isLinux;	// generate code for linux
    char isOSX;		// generate code for Mac OSX
    char isWindows;	// generate code for Windows
    char isFreeBSD;	// generate code for FreeBSD
    char isSolaris;	// generate code for Solaris
    char scheduler;	// which scheduler to use
    char useDeprecated;	// allow use of deprecated features
    char useAssert;	// generate runtime code for assert()'s
    char useInvariants;	// generate class invariant checks
    char useIn;		// generate precondition checks
    char useOut;	// generate postcondition checks
    char useArrayBounds; // generate array bounds checks
    char useSwitchError; // check for switches without a default
    char useUnitTests;	// generate unittest code
    char useInline;	// inline expand functions
    char release;	// build release version
    char preservePaths;	// !=0 means don't strip path from source file
    char warnings;	// enable warnings
    char pic;		// generate position-independent-code for shared libs
    char cov;		// generate code coverage data
    char nofloat;	// code should not pull in floating point support
    char Dversion;	// D version number
    char ignoreUnsupportedPragmas;	// rather than error on them
    char safe;		// enforce safe memory model

    char *argv0;	// program name
    Array *imppath;	// array of char*'s of where to look for import modules
    Array *fileImppath;	// array of char*'s of where to look for file import modules
    char *objdir;	// .obj/.lib file output directory
    char *objname;	// .obj file output name
    char *libname;	// .lib file output name

    char doDocComments;	// process embedded documentation comments
    char *docdir;	// write documentation file to docdir directory
    char *docname;	// write documentation file to docname
    Array *ddocfiles;	// macro include files for Ddoc

    char doHdrGeneration;	// process embedded documentation comments
    char *hdrdir;		// write 'header' file to docdir directory
    char *hdrname;		// write 'header' file to docname

    unsigned debuglevel;	// debug level
    Array *debugids;		// debug identifiers

    unsigned versionlevel;	// version level
    Array *versionids;		// version identifiers

    bool dump_source;

    const char *defaultlibname;	// default library for non-debug builds
    const char *debuglibname;	// default library for debug builds

    const char *xmlname;	// filename for XML output

    char *moduleDepsFile;	// filename for deps output
    OutBuffer *moduleDeps;	// contents to be written to deps file

    // Hidden debug switches
    char debuga;
    char debugb;
    char debugc;
    char debugf;
    char debugr;
    char debugw;
    char debugx;
    char debugy;

    char run;		// run resulting executable
    size_t runargs_length;
    char** runargs;	// arguments for executable

    // Linker stuff
    Array *objfiles;
    Array *linkswitches;
    Array *libfiles;
    char *deffile;
    char *resfile;
    char *exefile;
};

struct Global
{
    const char *mars_ext;
    const char *sym_ext;
    const char *obj_ext;
    const char *lib_ext;
    const char *doc_ext;	// for Ddoc generated files
    const char *ddoc_ext;	// for Ddoc macro include files
    const char *hdr_ext;	// for D 'header' import files
    const char *copyright;
    const char *written;
    Array *path;	// Array of char*'s which form the import lookup path
    Array *filePath;	// Array of char*'s which form the file import lookup path
    int structalign;
    const char *version;

    Param params;
    unsigned errors;	// number of errors reported so far
    unsigned gag;	// !=0 means gag reporting of errors

    Global();
};

extern Global global;

struct Loc
{
    const char *filename;
    unsigned linnum;

    Loc()
    {
	linnum = 0;
	filename = NULL;
    }

    Loc(int x)
    {
	linnum = x;
	filename = NULL;
    }

    Loc(Module *mod, unsigned linnum);

    char *toChars();
    bool equals(const Loc& loc);
};

enum LINK
{
    LINKdefault,
    LINKd,
    LINKc,
    LINKcpp,
    LINKwindows,
    LINKpascal,
};

enum DYNCAST
{
    DYNCAST_OBJECT,
    DYNCAST_EXPRESSION,
    DYNCAST_DSYMBOL,
    DYNCAST_TYPE,
    DYNCAST_IDENTIFIER,
    DYNCAST_TUPLE,
};

enum MATCH
{
    MATCHnomatch,	// no match
    MATCHconvert,	// match with conversions
#if DMDV2
    MATCHconst,		// match with conversion to const
#endif
    MATCHexact		// exact match
};

struct String : Object
{
    int ref;		
    char *str;	

    String(char *str, int ref = 1);

    ~String();

    static hash_t calcHash(const char *str, size_t len);
    static hash_t calcHash(const char *str);
    hash_t hashCode();
    unsigned len();
    int equals(Object *obj);
    int compare(Object *obj);
    char *toChars();
    void print();
    void mark();
};

class Macro
{
    Macro *next;                // next in list

    unsigned char *name;        // macro name
    size_t namelen;             // length of macro name

    unsigned char *text;        // macro replacement text
    size_t textlen;             // length of replacement text

    int inuse;                  // macro is in use (don't expand)

    Macro(unsigned char *name, size_t namelen, unsigned char *text, size_t textlen);
    Macro *search(unsigned char *name, size_t namelen);

  public:
    static Macro *define(Macro **ptable, unsigned char *name, size_t namelen, unsigned char *text, size_t textlen);

    void expand(OutBuffer *buf, unsigned start, unsigned *pend,
        unsigned char *arg, unsigned arglen);
};

struct FileName : String
{
    FileName(char *str, int ref);
    FileName(char *path, char *name);
    hash_t hashCode();
    int equals(Object *obj);
    static int equals(const char *name1, const char *name2);
    int compare(Object *obj);
    static int compare(const char *name1, const char *name2);
    static int absolute(const char *name);
    static char *ext(const char *);
    char *ext();
    static char *removeExt(const char *str);
    static char *name(const char *);
    char *name();
    static char *path(const char *);
    static const char *replaceName(const char *path, const char *name);

    static char *combine(const char *path, const char *name);
    static Array *splitPath(const char *path);
    static FileName *defaultExt(const char *name, const char *ext);
    static FileName *forceExt(const char *name, const char *ext);
    int equalsExt(const char *ext);

    void CopyTo(FileName *to);
    static char *searchPath(Array *path, const char *name, int cwd);
    static int exists(const char *name);
    static void ensurePathExists(const char *path);
};

struct File : Object
{
    int ref;
    unsigned char *buffer;	
    unsigned len;	
    void *touchtime;
    FileName *name;	

    File(char *);
    File(FileName *);
    ~File();
    void mark();
    char *toChars();
    int read();
    void readv();
    int mmread();
    void mmreadv();
    int write();
    void writev();
    int append();
    void appendv();
    int exists();
    static Array *match(char *);
    static Array *match(FileName *);
    int compareTime(File *f);
    void stat();
    void setbuffer(void *buffer, unsigned len)
    {
	this->buffer = (unsigned char *)buffer;
	this->len = len;
    }

    void checkoffset(size_t offset, size_t nbytes);

    void remove();
};

struct OutBuffer : Object
{
    unsigned char *data;
    unsigned offset;
    unsigned size;

    OutBuffer();
    ~OutBuffer();
    void *extractData();
    void mark();

    void reserve(unsigned nbytes);
    void setsize(unsigned size);
    void reset();
    void write(const void *data, unsigned nbytes);
    void writebstring(unsigned char *string);
    void writestring(const char *string);
    void writedstring(const char *string);
    void writedstring(const wchar_t *string);
    void prependstring(const char *string);
    void writenl();	
    void writeByte(unsigned b);
    void writebyte(unsigned b) { writeByte(b); }
    void writeUTF8(unsigned b);
    void writedchar(unsigned b);
    void prependbyte(unsigned b);
    void writeword(unsigned w);
    void writeUTF16(unsigned w);
    void write4(unsigned w);
    void write(OutBuffer *buf);
    void write(Object *obj);
    void fill0(unsigned nbytes);
    void align(unsigned size);
    void vprintf(const char *format, va_list args);
    void printf(const char *format, ...);
#ifdef M_UNICODE
    void vprintf(const unsigned short *format, va_list args);
    void printf(const unsigned short *format, ...);
#endif
    void bracket(char left, char right);
    unsigned bracket(unsigned i, const char *left, unsigned j, const char *right);
    void spread(unsigned offset, unsigned nbytes);
    unsigned insert(unsigned offset, const void *data, unsigned nbytes);
    void remove(unsigned offset, unsigned nbytes);
    char *toChars();
    char *extractString();
};

struct Bits : Object
{
    unsigned bitdim;
    unsigned allocdim;
    unsigned *data;

    Bits();
    ~Bits();
    void mark();

    void resize(unsigned bitdim);

    void set(unsigned bitnum);
    void clear(unsigned bitnum);
    int test(unsigned bitnum);

    void set();
    void clear();
    void copy(Bits *from);
    Bits *clone();

    void sub(Bits *b);
};

struct StringValue
{
    union
    {	int intvalue;
	void *ptrvalue;
	dchar *string;
    };
    Lstring lstring;
};

struct StringTable : Object
{
    void **table;
    unsigned count;
    unsigned tabledim;

    StringTable(unsigned size = 37);
    ~StringTable();

    StringValue *lookup(const dchar *s, unsigned len);
    StringValue *insert(const dchar *s, unsigned len);
    StringValue *update(const dchar *s, unsigned len);

private:
    void **search(const dchar *s, unsigned len);
};

struct Dchar
{
#ifdef M_UNICODE
    static dchar *inc(dchar *p) { return p + 1; }
    static dchar *dec(dchar *pstart, dchar *p) { (void)pstart; return p - 1; }
    static int len(const dchar *p) { return wcslen(p); }
    static dchar get(dchar *p) { return *p; }
    static dchar getprev(dchar *pstart, dchar *p) { (void)pstart; return p[-1]; }
    static dchar *put(dchar *p, dchar c) { *p = c; return p + 1; }
    static int cmp(dchar *s1, dchar *s2)
    {
#if __DMC__
	if (!*s1 && !*s2)	// wcscmp is broken
	    return 0;
#endif
	return wcscmp(s1, s2);
#if 0
	return (*s1 == *s2)
	    ? wcscmp(s1, s2)
	    : ((int)*s1 - (int)*s2);
#endif
    }
    static int memcmp(const dchar *s1, const dchar *s2, int nchars) { return ::memcmp(s1, s2, nchars * sizeof(dchar)); }
    static int isDigit(dchar c) { return '0' <= c && c <= '9'; }
    static int isAlpha(dchar c) { return iswalpha(c); }
    static int isUpper(dchar c) { return iswupper(c); }
    static int isLower(dchar c) { return iswlower(c); }
    static int isLocaleUpper(dchar c) { return isUpper(c); }
    static int isLocaleLower(dchar c) { return isLower(c); }
    static int toLower(dchar c) { return isUpper(c) ? towlower(c) : c; }
    static int toLower(dchar *p) { return toLower(*p); }
    static int toUpper(dchar c) { return isLower(c) ? towupper(c) : c; }
    static dchar *dup(dchar *p) { return ::_wcsdup(p); }	// BUG: out of memory?
    static dchar *dup(char *p);
    static dchar *chr(dchar *p, unsigned c) { return wcschr(p, (dchar)c); }
    static dchar *rchr(dchar *p, unsigned c) { return wcsrchr(p, (dchar)c); }
    static dchar *memchr(dchar *p, int c, int count);
    static dchar *cpy(dchar *s1, dchar *s2) { return wcscpy(s1, s2); }
    static dchar *str(dchar *s1, dchar *s2) { return wcsstr(s1, s2); }
    static hash_t calcHash(const dchar *str, size_t len);

    // Case insensitive versions
    static int icmp(dchar *s1, dchar *s2) { return wcsicmp(s1, s2); }
    static int memicmp(const dchar *s1, const dchar *s2, int nchars) { return ::wcsnicmp(s1, s2, nchars); }
    static hash_t icalcHash(const dchar *str, size_t len);
#endif	
#if UTF8

    static char mblen[256];

    static dchar *inc(dchar *p) { return p + mblen[*p & 0xFF]; }
    static dchar *dec(dchar *pstart, dchar *p);
    static int len(const dchar *p) { return strlen(p); }
    static int get(dchar *p);
    static int getprev(dchar *pstart, dchar *p)
	{ return *dec(pstart, p) & 0xFF; }
    static dchar *put(dchar *p, unsigned c);
    static int cmp(dchar *s1, dchar *s2) { return strcmp(s1, s2); }
    static int memcmp(const dchar *s1, const dchar *s2, int nchars) { return ::memcmp(s1, s2, nchars); }
    static int isDigit(dchar c) { return '0' <= c && c <= '9'; }
    static int isAlpha(dchar c) { return c <= 0x7F ? isalpha(c) : 0; }
    static int isUpper(dchar c) { return c <= 0x7F ? isupper(c) : 0; }
    static int isLower(dchar c) { return c <= 0x7F ? islower(c) : 0; }
    static int isLocaleUpper(dchar c) { return isUpper(c); }
    static int isLocaleLower(dchar c) { return isLower(c); }
    static int toLower(dchar c) { return isUpper(c) ? tolower(c) : c; }
    static int toLower(dchar *p) { return toLower(*p); }
    static int toUpper(dchar c) { return isLower(c) ? toupper(c) : c; }
    static dchar *dup(dchar *p) { return ::strdup(p); }	// BUG: out of memory?
    static dchar *chr(dchar *p, int c) { return strchr(p, c); }
    static dchar *rchr(dchar *p, int c) { return strrchr(p, c); }
    static dchar *memchr(dchar *p, int c, int count)
	{ return (dchar *)::memchr(p, c, count); }
    static dchar *cpy(dchar *s1, dchar *s2) { return strcpy(s1, s2); }
    static dchar *str(dchar *s1, dchar *s2) { return strstr(s1, s2); }
    static hash_t calcHash(const dchar *str, size_t len);

    // Case insensitive versions
    static int icmp(dchar *s1, dchar *s2) { return _mbsicmp(s1, s2); }
    static int memicmp(const dchar *s1, const dchar *s2, int nchars) { return ::_mbsnicmp(s1, s2, nchars); }
#else

    static dchar *inc(dchar *p) { return p + 1; }
    static dchar *dec(dchar *pstart, dchar *p) { return p - 1; }
    static int len(const dchar *p) { return strlen(p); }
    static int get(dchar *p) { return *p & 0xFF; }
    static int getprev(dchar *pstart, dchar *p) { return p[-1] & 0xFF; }
    static dchar *put(dchar *p, unsigned c) { *p = c; return p + 1; }
    static int cmp(dchar *s1, dchar *s2) { return strcmp(s1, s2); }
    static int memcmp(const dchar *s1, const dchar *s2, int nchars) { return ::memcmp(s1, s2, nchars); }
    static int isDigit(dchar c) { return '0' <= c && c <= '9'; }
#ifndef GCC_SAFE_DMD
    static int isAlpha(dchar c) { return isalpha(c); }
    static int isUpper(dchar c) { return isupper(c); }
    static int isLower(dchar c) { return islower(c); }
    static int isLocaleUpper(dchar c) { return isupper(c); }
    static int isLocaleLower(dchar c) { return islower(c); }
    static int toLower(dchar c) { return isupper(c) ? tolower(c) : c; }
    static int toLower(dchar *p) { return toLower(*p); }
    static int toUpper(dchar c) { return islower(c) ? toupper(c) : c; }
    static dchar *dup(dchar *p) { return ::strdup(p); }	// BUG: out of memory?
#endif
    static dchar *chr(dchar *p, int c) { return strchr(p, c); }
    static dchar *rchr(dchar *p, int c) { return strrchr(p, c); }
    static dchar *memchr(dchar *p, int c, int count)
	{ return (dchar *)::memchr(p, c, count); }
    static dchar *cpy(dchar *s1, dchar *s2) { return strcpy(s1, s2); }
    static dchar *str(dchar *s1, dchar *s2) { return strstr(s1, s2); }
    static hash_t calcHash(const dchar *str, size_t len);

    // Case insensitive versions
#ifdef __GNUC__
    static int icmp(dchar *s1, dchar *s2) { return strcasecmp(s1, s2); }
#else
    static int icmp(dchar *s1, dchar *s2) { return stricmp(s1, s2); }
#endif
    static int memicmp(const dchar *s1, const dchar *s2, int nchars) { return ::memicmp(s1, s2, nchars); }
    static hash_t icalcHash(const dchar *str, size_t len);
#endif
};

struct TemplateParameters : Array { };

struct Expressions : Array { };

struct Statements : Array { };

struct BaseClasses : Array { };

struct ClassDeclarations : Array { };

struct Dsymbols : Array { };

struct Objects : Array { };

struct FuncDeclarations : Array { };

struct Arguments : Array { };

struct Identifiers : Array { };

struct Initializers : Array { };

struct Lstring
{
    unsigned length;

    #pragma warning (disable : 4200)
    dchar string[];

    static Lstring zero;
    #ifdef M_UNICODE
    #define LSTRING(p,length) { length, L##p }
    #else
    #define LSTRING(p,length) { length, p }
    #endif

#if __GNUC__
    #define LSTRING_EMPTY() { 0 }
#else
    #define LSTRING_EMPTY() LSTRING("", 0)
#endif

    static Lstring *ctor(const dchar *p) { return ctor(p, Dchar::len(p)); }
    static Lstring *ctor(const dchar *p, unsigned length);
    static unsigned size(unsigned length) { return sizeof(Lstring) + (length + 1) * sizeof(dchar); }
    static Lstring *alloc(unsigned length);
    Lstring *clone();

    unsigned len() { return length; }

    dchar *toDchars() { return string; }

    hash_t hash() { return Dchar::calcHash(string, length); }
    hash_t ihash() { return Dchar::icalcHash(string, length); }

    static int cmp(const Lstring *s1, const Lstring *s2)
    {
	int c = s2->length - s1->length;
	return c ? c : Dchar::memcmp(s1->string, s2->string, s1->length);
    }

    static int icmp(const Lstring *s1, const Lstring *s2)
    {
	int c = s2->length - s1->length;
	return c ? c : Dchar::memicmp(s1->string, s2->string, s1->length);
    }

    Lstring *append(const Lstring *s);
    Lstring *substring(int start, int end);
};

enum TOK
{
	TOKreserved,
	// Other
	TOKlparen,	TOKrparen,
	TOKlbracket,	TOKrbracket,
	TOKlcurly,	TOKrcurly,
	TOKcolon,	TOKneg,
	TOKsemicolon,	TOKdotdotdot,
	TOKeof,		TOKcast,
	TOKnull,	TOKassert,
	TOKtrue,	TOKfalse,
	TOKarray,	TOKcall,
	TOKaddress,
	TOKtype,	TOKthrow,
	TOKnew,		TOKdelete,
	TOKstar,	TOKsymoff,
	TOKvar,		TOKdotvar,
	TOKdotti,	TOKdotexp,
	TOKdottype,	TOKslice,
	TOKarraylength,	TOKversion,
	TOKmodule,	TOKdollar,
	TOKtemplate,	TOKdottd,
	TOKdeclaration,	TOKtypeof,
	TOKpragma,	TOKdsymbol,
	TOKtypeid,	TOKuadd,
	TOKremove,
	TOKnewanonclass, TOKcomment,
	TOKarrayliteral, TOKassocarrayliteral,
	TOKstructliteral,

	// Operators
	TOKlt,		TOKgt,
	TOKle,		TOKge,
	TOKequal,	TOKnotequal,
	TOKidentity,	TOKnotidentity,
	TOKindex,	TOKis,
	TOKtobool,

// 60
	// NCEG floating point compares
	// !<>=     <>    <>=    !>     !>=   !<     !<=   !<>
	TOKunord,TOKlg,TOKleg,TOKule,TOKul,TOKuge,TOKug,TOKue,

	TOKshl,		TOKshr,
	TOKshlass,	TOKshrass,
	TOKushr,	TOKushrass,
	TOKcat,		TOKcatass,	// ~ ~=
	TOKadd,		TOKmin,		TOKaddass,	TOKminass,
	TOKmul,		TOKdiv,		TOKmod,
	TOKmulass,	TOKdivass,	TOKmodass,
	TOKand,		TOKor,		TOKxor,
	TOKandass,	TOKorass,	TOKxorass,
	TOKassign,	TOKnot,		TOKtilde,
	TOKplusplus,	TOKminusminus,	TOKconstruct,	TOKblit,
	TOKdot,		TOKarrow,	TOKcomma,
	TOKquestion,	TOKandand,	TOKoror,

// 104
	// Numeric literals
	TOKint32v, TOKuns32v,
	TOKint64v, TOKuns64v,
	TOKfloat32v, TOKfloat64v, TOKfloat80v,
	TOKimaginary32v, TOKimaginary64v, TOKimaginary80v,

	// Char constants
	TOKcharv, TOKwcharv, TOKdcharv,

	// Leaf operators
	TOKidentifier,	TOKstring,
	TOKthis,	TOKsuper,
	TOKhalt,	TOKtuple,

	// Basic types
	TOKvoid,
	TOKint8, TOKuns8,
	TOKint16, TOKuns16,
	TOKint32, TOKuns32,
	TOKint64, TOKuns64,
	TOKfloat32, TOKfloat64, TOKfloat80,
	TOKimaginary32, TOKimaginary64, TOKimaginary80,
	TOKcomplex32, TOKcomplex64, TOKcomplex80,
	TOKchar, TOKwchar, TOKdchar, TOKbit, TOKbool,
	TOKcent, TOKucent,

	// Aggregates
	TOKstruct, TOKclass, TOKinterface, TOKunion, TOKenum, TOKimport,
	TOKtypedef, TOKalias, TOKoverride, TOKdelegate, TOKfunction,
	TOKmixin,

	TOKalign, TOKextern, TOKprivate, TOKprotected, TOKpublic, TOKexport,
	TOKstatic, /*TOKvirtual,*/ TOKfinal, TOKconst, TOKabstract, TOKvolatile,
	TOKdebug, TOKdeprecated, TOKin, TOKout, TOKinout, TOKlazy,
	TOKauto, TOKpackage, TOKmanifest, TOKimmutable,

	// Statements
	TOKif, TOKelse, TOKwhile, TOKfor, TOKdo, TOKswitch,
	TOKcase, TOKdefault, TOKbreak, TOKcontinue, TOKwith,
	TOKsynchronized, TOKreturn, TOKgoto, TOKtry, TOKcatch, TOKfinally,
	TOKasm, TOKforeach, TOKforeach_reverse,
	TOKscope,
	TOKon_scope_exit, TOKon_scope_failure, TOKon_scope_success,

	// Contracts
	TOKbody, TOKinvariant,

	// Testing
	TOKunittest,

	// Added after 1.0
	TOKref,
	TOKmacro,
#if DMDV2
	TOKtraits,
	TOKoverloadset,
	TOKpure,
	TOKnothrow,
	TOKtls,
	TOKgshared,
	TOKline,
	TOKfile,
	TOKshared,
#endif

	TOKMAX
};

#define CASE_BASIC_TYPES			\
	case TOKwchar: case TOKdchar:		\
	case TOKbit: case TOKbool: case TOKchar:	\
	case TOKint8: case TOKuns8:		\
	case TOKint16: case TOKuns16:		\
	case TOKint32: case TOKuns32:		\
	case TOKint64: case TOKuns64:		\
	case TOKfloat32: case TOKfloat64: case TOKfloat80:		\
	case TOKimaginary32: case TOKimaginary64: case TOKimaginary80:	\
	case TOKcomplex32: case TOKcomplex64: case TOKcomplex80:	\
	case TOKvoid

#define CASE_BASIC_TYPES_X(t)					\
	case TOKvoid:	 t = Type::tvoid;  goto LabelX;		\
	case TOKint8:	 t = Type::tint8;  goto LabelX;		\
	case TOKuns8:	 t = Type::tuns8;  goto LabelX;		\
	case TOKint16:	 t = Type::tint16; goto LabelX;		\
	case TOKuns16:	 t = Type::tuns16; goto LabelX;		\
	case TOKint32:	 t = Type::tint32; goto LabelX;		\
	case TOKuns32:	 t = Type::tuns32; goto LabelX;		\
	case TOKint64:	 t = Type::tint64; goto LabelX;		\
	case TOKuns64:	 t = Type::tuns64; goto LabelX;		\
	case TOKfloat32: t = Type::tfloat32; goto LabelX;	\
	case TOKfloat64: t = Type::tfloat64; goto LabelX;	\
	case TOKfloat80: t = Type::tfloat80; goto LabelX;	\
	case TOKimaginary32: t = Type::timaginary32; goto LabelX;	\
	case TOKimaginary64: t = Type::timaginary64; goto LabelX;	\
	case TOKimaginary80: t = Type::timaginary80; goto LabelX;	\
	case TOKcomplex32: t = Type::tcomplex32; goto LabelX;	\
	case TOKcomplex64: t = Type::tcomplex64; goto LabelX;	\
	case TOKcomplex80: t = Type::tcomplex80; goto LabelX;	\
	case TOKbit:	 t = Type::tbit;     goto LabelX;	\
	case TOKbool:	 t = Type::tbool;    goto LabelX;	\
	case TOKchar:	 t = Type::tchar;    goto LabelX;	\
	case TOKwchar:	 t = Type::twchar; goto LabelX;	\
	case TOKdchar:	 t = Type::tdchar; goto LabelX;	\
	LabelX

struct Token
{
    Token *next;
    unsigned char *ptr;		// pointer to first character of this token within buffer
    enum TOK value;
    unsigned char *blockComment; // doc comment string prior to this token
    unsigned char *lineComment;	 // doc comment for previous token
    union
    {
	// Integers
	d_int32 int32value;
	d_uns32	uns32value;
	d_int64	int64value;
	d_uns64	uns64value;

	// Floats
#ifdef IN_GCC
	// real_t float80value; // can't use this in a union!
#else
	d_float80 float80value;
#endif

	struct
	{   unsigned char *ustring;	// UTF8 string
	    unsigned len;
	    unsigned char postfix;	// 'c', 'w', 'd'
	};

	Identifier *ident;
    };
#ifdef IN_GCC
    real_t float80value; // can't use this in a union!
#endif

    static const char *tochars[TOKMAX];
    static void *operator new(size_t sz);

    int isKeyword();
    void print();
    const char *toChars();
    static const char *toChars(enum TOK);
};

struct Lexer
{
    static StringTable stringtable;
    static OutBuffer stringbuffer;
    static Token *freelist;

    Loc loc;			// for error messages

    unsigned char *base;	// pointer to start of buffer
    unsigned char *end;		// past end of buffer
    unsigned char *p;		// current character
    Token token;
    Module *mod;
    int doDocComment;		// collect doc comment information
    int anyToken;		// !=0 means seen at least one token
    int commentToken;		// !=0 means comments are TOKcomment's

    Lexer(Module *mod,
	unsigned char *base, unsigned begoffset, unsigned endoffset,
	int doDocComment, int commentToken);

    static void initKeywords();
    static Identifier *idPool(const char *s);
    static Identifier *uniqueId(const char *s);
    static Identifier *uniqueId(const char *s, int num);

    TOK nextToken();
    TOK peekNext();
    TOK peekNext2();
    void scan(Token *t);
    Token *peek(Token *t);
    Token *peekPastParen(Token *t);
    unsigned escapeSequence();
    TOK wysiwygStringConstant(Token *t, int tc);
    TOK hexStringConstant(Token *t);
#if DMDV2
    TOK delimitedStringConstant(Token *t);
    TOK tokenStringConstant(Token *t);
#endif
    TOK escapeStringConstant(Token *t, int wide);
    TOK charConstant(Token *t, int wide);
    void stringPostfix(Token *t);
    unsigned wchar(unsigned u);
    TOK number(Token *t);
    TOK inreal(Token *t);
    void error(const char *format, ...);
    void error(Loc loc, const char *format, ...);
    void pragma();
    unsigned decodeUTF();
    void getDocComment(Token *t, unsigned lineComment);

    static int isValidIdentifier(char *p);
    static unsigned char *combineComments(unsigned char *c1, unsigned char *c2);
};


struct Initializer : Object
{
    Loc loc;

    Initializer(Loc loc);
    virtual Initializer *syntaxCopy();
    virtual Initializer *semantic(Scope *sc, Type *t);
    virtual Type *inferType(Scope *sc);
    virtual Expression *toExpression() = 0;
    virtual void toCBuffer(OutBuffer *buf, HdrGenState *hgs) = 0;
    char *toChars();

    static Initializers *arraySyntaxCopy(Initializers *ai);

    virtual dt_t *toDt();

    virtual VoidInitializer *isVoidInitializer() { return NULL; }
    virtual StructInitializer  *isStructInitializer()  { return NULL; }
    virtual ArrayInitializer  *isArrayInitializer()  { return NULL; }
    virtual ExpInitializer  *isExpInitializer()  { return NULL; }
};

struct VoidInitializer : Initializer
{
    Type *type;		// type that this will initialize to

    VoidInitializer(Loc loc);
    Initializer *syntaxCopy();
    Initializer *semantic(Scope *sc, Type *t);
    Expression *toExpression();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    dt_t *toDt();

    virtual VoidInitializer *isVoidInitializer() { return this; }
};

struct StructInitializer : Initializer
{
    Identifiers field;	// of Identifier *'s
    Initializers value;	// parallel array of Initializer *'s

    Array vars;		// parallel array of VarDeclaration *'s
    AggregateDeclaration *ad;	// which aggregate this is for

    StructInitializer(Loc loc);
    Initializer *syntaxCopy();
    void addInit(Identifier *field, Initializer *value);
    Initializer *semantic(Scope *sc, Type *t);
    Expression *toExpression();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    dt_t *toDt();

    StructInitializer *isStructInitializer() { return this; }
};

struct ArrayInitializer : Initializer
{
    Expressions index;	// indices
    Initializers value;	// of Initializer *'s
    unsigned dim;	// length of array being initialized
    Type *type;		// type that array will be used to initialize
    int sem;		// !=0 if semantic() is run

    ArrayInitializer(Loc loc);
    Initializer *syntaxCopy();
    void addInit(Expression *index, Initializer *value);
    Initializer *semantic(Scope *sc, Type *t);
    Type *inferType(Scope *sc);
    Expression *toExpression();
    Initializer *toAssocArrayInitializer();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    dt_t *toDt();
    dt_t *toDtBit();	// for bit arrays

    ArrayInitializer *isArrayInitializer() { return this; }
};

struct ExpInitializer : Initializer
{
    Expression *exp;

    ExpInitializer(Loc loc, Expression *exp);
    Initializer *syntaxCopy();
    Initializer *semantic(Scope *sc, Type *t);
    Type *inferType(Scope *sc);
    Expression *toExpression();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    dt_t *toDt();
	virtual ExpInitializer *isExpInitializer() { return this; }
};


/************************************
 * These control how parseStatement() works.
 */

enum ParseStatementFlags
{
    PSsemi = 1,		// empty ';' statements are allowed
    PSscope = 2,	// start a new scope
    PScurly = 4,	// { } statement is required
    PScurlyscope = 8,	// { } starts a new scope
};


struct Parser : Lexer
{
    ModuleDeclaration *md;
    enum LINK linkage;
    Loc endloc;			// set to location of last right curly
    int inBrackets;		// inside [] of array index or slice

    Parser(Module *module, unsigned char *base, unsigned length, int doDocComment);

    Array *parseModule();
    Array *parseDeclDefs(int once);
    Array *parseAutoDeclarations(unsigned storageClass, unsigned char *comment);
    Array *parseBlock();
    void composeStorageClass(unsigned stc);
    Expression *parseConstraint();
    TemplateDeclaration *parseTemplateDeclaration();
    TemplateParameters *parseTemplateParameterList(int flag = 0);
    Dsymbol *parseMixin();
    Objects *parseTemplateArgumentList();
    Objects *parseTemplateArgumentList2();
    Objects *parseTemplateArgument();
    StaticAssert *parseStaticAssert();
    TypeQualified *parseTypeof();
    enum LINK parseLinkage();
    Condition *parseDebugCondition();
    Condition *parseVersionCondition();
    Condition *parseStaticIfCondition();
    Dsymbol *parseCtor();
    PostBlitDeclaration *parsePostBlit();
    DtorDeclaration *parseDtor();
    StaticCtorDeclaration *parseStaticCtor();
    StaticDtorDeclaration *parseStaticDtor();
    InvariantDeclaration *parseInvariant();
    UnitTestDeclaration *parseUnitTest();
    NewDeclaration *parseNew();
    DeleteDeclaration *parseDelete();
    Arguments *parseParameters(int *pvarargs);
    EnumDeclaration *parseEnum();
    Dsymbol *parseAggregate();
    BaseClasses *parseBaseClasses();
    Import *parseImport(Array *decldefs, int isstatic);
    Type *parseType(Identifier **pident = NULL, TemplateParameters **tpl = NULL);
    Type *parseBasicType();
    Type *parseBasicType2(Type *t);
    Type *parseDeclarator(Type *t, Identifier **pident, TemplateParameters **tpl = NULL);
    Array *parseDeclarations(unsigned storage_class);
    void parseContracts(FuncDeclaration *f);
    Statement *parseStatement(int flags);
    Initializer *parseInitializer();
    Expression *parseDefaultInitExp();
    void check(Loc loc, enum TOK value);
    void check(enum TOK value);
    void check(enum TOK value, const char *string);
    int isDeclaration(Token *t, int needId, enum TOK endtok, Token **pt);
    int isBasicType(Token **pt);
    int isDeclarator(Token **pt, int *haveId, enum TOK endtok);
    int isParameters(Token **pt);
    int isExpression(Token **pt);
    int isTemplateInstance(Token *t, Token **pt);
    int skipParens(Token *t, Token **pt);

    Expression *parseExpression();
    Expression *parsePrimaryExp();
    Expression *parseUnaryExp();
    Expression *parsePostExp(Expression *e);
    Expression *parseMulExp();
    Expression *parseAddExp();
    Expression *parseShiftExp();
    Expression *parseRelExp();
    Expression *parseEqualExp();
    Expression *parseCmpExp();
    Expression *parseAndExp();
    Expression *parseXorExp();
    Expression *parseOrExp();
    Expression *parseAndAndExp();
    Expression *parseOrOrExp();
    Expression *parseCondExp();
    Expression *parseAssignExp();

    Expressions *parseArguments();

    Expression *parseNewExp(Expression *thisexp);

    void addComment(Dsymbol *s, unsigned char *blockComment);
};

struct Identifier : Object
{
    int value;
    const char *string;
    unsigned len;

    Identifier(const char *string, int value);
    int equals(Object *o);
    hash_t hashCode();
    int compare(Object *o);
    void print();
    char *toChars();
#ifdef _DH
    char *toHChars();
#endif
    const char *toHChars2();
    int dyncast();

    static Identifier *generateId(const char *prefix);
    static Identifier *generateId(const char *prefix, size_t i);
};


struct EnumDeclaration : ScopeDsymbol
{   /* enum ident : memtype { ... }
     */
    Type *type;			// the TypeEnum
    Type *memtype;		// type of the members

#if DMDV1
    dinteger_t maxval;
    dinteger_t minval;
    dinteger_t defaultval;	// default initializer
#else
    Expression *maxval;
    Expression *minval;
    Expression *defaultval;	// default initializer
#endif
    int isdeprecated;

    EnumDeclaration(Loc loc, Identifier *id, Type *memtype);
    Dsymbol *syntaxCopy(Dsymbol *s);
    void semantic(Scope *sc);
    int oneMember(Dsymbol **ps);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Type *getType();
    const char *kind();
#if DMDV2
    Dsymbol *search(Loc, Identifier *ident, int flags);
#endif
    int isDeprecated();			// is Dsymbol deprecated?

    void emitComment(Scope *sc);
    void toDocBuffer(OutBuffer *buf);

    EnumDeclaration *isEnumDeclaration() { return this; }

    void toObjFile(int multiobj);			// compile to .obj file
    void toDebug();
    int cvMember(unsigned char *p);

    Symbol *sinit;
    Symbol *toInitializer();
};

struct EnumMember : Dsymbol
{
    Expression *value;
    Type *type;

    EnumMember(Loc loc, Identifier *id, Expression *value, Type *type);
    Dsymbol *syntaxCopy(Dsymbol *s);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    const char *kind();

    void emitComment(Scope *sc);
    void toDocBuffer(OutBuffer *buf);

    EnumMember *isEnumMember() { return this; }
};

struct AggregateDeclaration : ScopeDsymbol
{
    Type *type;
    unsigned storage_class;
    enum PROT protection;
    Type *handle;		// 'this' type
    unsigned structsize;	// size of struct
    unsigned alignsize;		// size of struct for alignment purposes
    unsigned structalign;	// struct member alignment in effect
    int hasUnions;		// set if aggregate has overlapping fields
    Array fields;		// VarDeclaration fields
    unsigned sizeok;		// set when structsize contains valid data
				// 0: no size
				// 1: size is correct
				// 2: cannot determine size; fwd referenced
    int isdeprecated;		// !=0 if deprecated

    int isnested;		// !=0 if is nested
    VarDeclaration *vthis;	// 'this' parameter if this aggregate is nested

    // Special member functions
    InvariantDeclaration *inv;		// invariant
    NewDeclaration *aggNew;		// allocator
    DeleteDeclaration *aggDelete;	// deallocator

#if DMDV2
    //CtorDeclaration *ctor;
    Dsymbol *ctor;			// CtorDeclaration or TemplateDeclaration
    CtorDeclaration *defaultCtor;	// default constructor
    Dsymbol *aliasthis;			// forward unresolved lookups to aliasthis
#endif

    FuncDeclarations dtors;	// Array of destructors
    FuncDeclaration *dtor;	// aggregate destructor

#ifdef IN_GCC
    Array methods;              // flat list of all methods for debug information
#endif

    AggregateDeclaration(Loc loc, Identifier *id);
    void semantic2(Scope *sc);
    void semantic3(Scope *sc);
    void inlineScan();
    unsigned size(Loc loc);
    static void alignmember(unsigned salign, unsigned size, unsigned *poffset);
    Type *getType();
    void addField(Scope *sc, VarDeclaration *v);
    int isDeprecated();		// is aggregate deprecated?
    FuncDeclaration *buildDtor(Scope *sc);
    int isNested();

    void emitComment(Scope *sc);
    void toDocBuffer(OutBuffer *buf);

    // For access checking
    virtual PROT getAccess(Dsymbol *smember);	// determine access to smember
    int isFriendOf(AggregateDeclaration *cd);
    int hasPrivateAccess(Dsymbol *smember);	// does smember have private access to members of this class?
    void accessCheck(Loc loc, Scope *sc, Dsymbol *smember);

    enum PROT prot();

    // Back end
    Symbol *stag;		// tag symbol for debug data
    Symbol *sinit;
    Symbol *toInitializer();

    AggregateDeclaration *isAggregateDeclaration() { return this; }
};

struct AnonymousAggregateDeclaration : AggregateDeclaration
{
    AnonymousAggregateDeclaration()
	: AggregateDeclaration(0, NULL)
    {
    }

    AnonymousAggregateDeclaration *isAnonymousAggregateDeclaration() { return this; }
};

struct StructDeclaration : AggregateDeclaration
{
    int zeroInit;		// !=0 if initialize with 0 fill
#if DMDV2
    int hasIdentityAssign;	// !=0 if has identity opAssign
    FuncDeclaration *cpctor;	// generated copy-constructor, if any

    FuncDeclarations postblits;	// Array of postblit functions
    FuncDeclaration *postblit;	// aggregate postblit
#endif

    StructDeclaration(Loc loc, Identifier *id);
    Dsymbol *syntaxCopy(Dsymbol *s);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    char *mangle();
    const char *kind();
    int needOpAssign();
    FuncDeclaration *buildOpAssign(Scope *sc);
    FuncDeclaration *buildPostBlit(Scope *sc);
    FuncDeclaration *buildCpCtor(Scope *sc);
    void toDocBuffer(OutBuffer *buf);

    PROT getAccess(Dsymbol *smember);	// determine access to smember

    void toObjFile(int multiobj);			// compile to .obj file
    void toDt(dt_t **pdt);
    void toDebug();			// to symbolic debug info

    StructDeclaration *isStructDeclaration() { return this; }
};

struct UnionDeclaration : StructDeclaration
{
    UnionDeclaration(Loc loc, Identifier *id);
    Dsymbol *syntaxCopy(Dsymbol *s);
    const char *kind();

    UnionDeclaration *isUnionDeclaration() { return this; }
};

struct BaseClass
{
    Type *type;				// (before semantic processing)
    enum PROT protection;		// protection for the base interface

    ClassDeclaration *base;
    int offset;				// 'this' pointer offset
    Array vtbl;				// for interfaces: Array of FuncDeclaration's
					// making up the vtbl[]

    int baseInterfaces_dim;
    BaseClass *baseInterfaces;		// if BaseClass is an interface, these
					// are a copy of the InterfaceDeclaration::interfaces

    BaseClass();
    BaseClass(Type *type, enum PROT protection);

    int fillVtbl(ClassDeclaration *cd, Array *vtbl, int newinstance);
    void copyBaseInterfaces(BaseClasses *);
};

#if DMDV2
#define CLASSINFO_SIZE 	(0x3C+16+4)	// value of ClassInfo.size
#else
#define CLASSINFO_SIZE 	(0x3C+12+4)	// value of ClassInfo.size
#endif

struct ClassDeclaration : AggregateDeclaration
{
    static ClassDeclaration *object;
    static ClassDeclaration *classinfo;

    ClassDeclaration *baseClass;	// NULL only if this is Object
    FuncDeclaration *staticCtor;
    FuncDeclaration *staticDtor;
    Array vtbl;				// Array of FuncDeclaration's making up the vtbl[]
    Array vtblFinal;			// More FuncDeclaration's that aren't in vtbl[]

    BaseClasses baseclasses;		// Array of BaseClass's; first is super,
					// rest are Interface's

    int interfaces_dim;
    BaseClass **interfaces;		// interfaces[interfaces_dim] for this class
					// (does not include baseClass)

    BaseClasses *vtblInterfaces;	// array of base interfaces that have
					// their own vtbl[]

    ClassInfoDeclaration *vclassinfo;	// the ClassInfo object for this ClassDeclaration
    int com;				// !=0 if this is a COM class (meaning
					// it derives from IUnknown)
    int isauto;				// !=0 if this is an auto class
    int isabstract;			// !=0 if abstract class

    int inuse;				// to prevent recursive attempts

    ClassDeclaration(Loc loc, Identifier *id, BaseClasses *baseclasses);
    Dsymbol *syntaxCopy(Dsymbol *s);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    int isBaseOf2(ClassDeclaration *cd);

    #define OFFSET_RUNTIME 0x76543210
    virtual int isBaseOf(ClassDeclaration *cd, int *poffset);

    Dsymbol *search(Loc, Identifier *ident, int flags);
#if DMDV2
    int isFuncHidden(FuncDeclaration *fd);
#endif
    FuncDeclaration *findFunc(Identifier *ident, TypeFunction *tf);
    void interfaceSemantic(Scope *sc);
    int isCOMclass();
    virtual int isCOMinterface();
#if DMDV2
    virtual int isCPPinterface();
#endif
    int isAbstract();
    virtual int vtblOffset();
    const char *kind();
    char *mangle();
    void toDocBuffer(OutBuffer *buf);

    PROT getAccess(Dsymbol *smember);	// determine access to smember

    void addLocalClass(ClassDeclarations *);

    // Back end
    void toObjFile(int multiobj);			// compile to .obj file
    void toDebug();
    unsigned baseVtblOffset(BaseClass *bc);
    Symbol *toSymbol();
    Symbol *toVtblSymbol();
    void toDt(dt_t **pdt);
    void toDt2(dt_t **pdt, ClassDeclaration *cd);

    Symbol *vtblsym;

    ClassDeclaration *isClassDeclaration() { return (ClassDeclaration *)this; }
};

struct InterfaceDeclaration : ClassDeclaration
{
#if DMDV2
    int cpp;				// !=0 if this is a C++ interface
#endif
    InterfaceDeclaration(Loc loc, Identifier *id, BaseClasses *baseclasses);
    Dsymbol *syntaxCopy(Dsymbol *s);
    void semantic(Scope *sc);
    int isBaseOf(ClassDeclaration *cd, int *poffset);
    int isBaseOf(BaseClass *bc, int *poffset);
    const char *kind();
    int vtblOffset();
#if DMDV2
    int isCPPinterface();
#endif
    virtual int isCOMinterface();

    void toObjFile(int multiobj);			// compile to .obj file
    Symbol *toSymbol();

    InterfaceDeclaration *isInterfaceDeclaration() { return this; }
};







struct Type;
struct Scope;
struct TupleDeclaration;
struct VarDeclaration;
struct FuncDeclaration;
struct FuncLiteralDeclaration;
struct Declaration;
struct CtorDeclaration;
struct NewDeclaration;
struct Dsymbol;
struct Import;
struct Module;
struct ScopeDsymbol;
struct InlineCostState;
struct InlineDoState;
struct InlineScanState;
struct Declaration;
struct AggregateDeclaration;
struct StructDeclaration;
struct TemplateInstance;
struct TemplateDeclaration;
struct ClassDeclaration;
struct HdrGenState;
struct BinExp;
struct InterState;
struct Symbol;		// back end symbol
struct OverloadSet;

enum TOK;

// Back end
struct IRState;
struct dt_t;

#ifdef IN_GCC
union tree_node;
 typedef union tree_node elem;
#else
struct elem;
#endif

struct IntRange
{   uinteger_t imin;
    uinteger_t imax;
};

struct Expression : Object
{
    Loc loc;			// file location
    enum TOK op;		// handy to minimize use of dynamic_cast
    Type *type;			// !=NULL means that semantic() has been run
    int size;			// # of bytes in Expression so we can copy() it

    Expression(Loc loc, enum TOK op, int size);
    Expression *copy();
    virtual Expression *syntaxCopy();
    virtual Expression *semantic(Scope *sc);
    Expression *trySemantic(Scope *sc);

    int dyncast() { return DYNCAST_EXPRESSION; }	// kludge for template.isExpression()

    void print();
    char *toChars();
    virtual void dump(int indent);
    void error(const char *format, ...);
    void warning(const char *format, ...);
    virtual void rvalue();

    static Expression *combine(Expression *e1, Expression *e2);
    static Expressions *arraySyntaxCopy(Expressions *exps);

    virtual dinteger_t toInteger();
    virtual uinteger_t toUInteger();
    virtual real_t toReal();
    virtual real_t toImaginary();
    virtual complex_t toComplex();
    virtual void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    virtual void toMangleBuffer(OutBuffer *buf);
    virtual int isLvalue();
    virtual Expression *toLvalue(Scope *sc, Expression *e);
    virtual Expression *modifiableLvalue(Scope *sc, Expression *e);
    virtual Expression *implicitCastTo(Scope *sc, Type *t);
    virtual MATCH implicitConvTo(Type *t);
    virtual IntRange getIntRange();
    virtual Expression *castTo(Scope *sc, Type *t);
    virtual void checkEscape();
    void checkScalar();
    void checkNoBool();
    Expression *checkIntegral();
    Expression *checkArithmetic();
    void checkDeprecated(Scope *sc, Dsymbol *s);
    void checkPurity(Scope *sc, FuncDeclaration *f);
    virtual Expression *checkToBoolean();
    Expression *checkToPointer();
    Expression *addressOf(Scope *sc);
    Expression *deref();
    Expression *integralPromotions(Scope *sc);

    Expression *toDelegate(Scope *sc, Type *t);
    virtual void scanForNestedRef(Scope *sc);

    virtual Expression *optimize(int result);
    #define WANTflags	1
    #define WANTvalue	2
    #define WANTinterpret 4

    virtual Expression *interpret(InterState *istate);

    virtual int isConst();
    virtual int isBool(int result);
    virtual int isBit();
    virtual int checkSideEffect(int flag);
    virtual int canThrow();

    virtual int inlineCost(InlineCostState *ics);
    virtual Expression *doInline(InlineDoState *ids);
    virtual Expression *inlineScan(InlineScanState *iss);

    // For operator overloading
    virtual int isCommutative();
    virtual Identifier *opId();
    virtual Identifier *opId_r();

    // For array ops
    virtual void buildArrayIdent(OutBuffer *buf, Expressions *arguments);
    virtual Expression *buildArrayLoop(Arguments *fparams);

    // Back end
    virtual elem *toElem(IRState *irs);
    virtual dt_t **toDt(dt_t **pdt);
};

struct IntegerExp : Expression
{
    dinteger_t value;

    IntegerExp(Loc loc, dinteger_t value, Type *type);
    IntegerExp(dinteger_t value);
    int equals(Object *o);
    Expression *semantic(Scope *sc);
    Expression *interpret(InterState *istate);
    char *toChars();
    void dump(int indent);
    IntRange getIntRange();
    dinteger_t toInteger();
    real_t toReal();
    real_t toImaginary();
    complex_t toComplex();
    int isConst();
    int isBool(int result);
    MATCH implicitConvTo(Type *t);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer *buf);
    Expression *toLvalue(Scope *sc, Expression *e);
    elem *toElem(IRState *irs);
    dt_t **toDt(dt_t **pdt);
};

struct ErrorExp : IntegerExp
{
    ErrorExp();

    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct RealExp : Expression
{
    real_t value;

    RealExp(Loc loc, real_t value, Type *type);
    int equals(Object *o);
    Expression *semantic(Scope *sc);
    Expression *interpret(InterState *istate);
    char *toChars();
    dinteger_t toInteger();
    uinteger_t toUInteger();
    real_t toReal();
    real_t toImaginary();
    complex_t toComplex();
    Expression *castTo(Scope *sc, Type *t);
    int isConst();
    int isBool(int result);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer *buf);
    elem *toElem(IRState *irs);
    dt_t **toDt(dt_t **pdt);
};

struct ComplexExp : Expression
{
    complex_t value;

    ComplexExp(Loc loc, complex_t value, Type *type);
    int equals(Object *o);
    Expression *semantic(Scope *sc);
    Expression *interpret(InterState *istate);
    char *toChars();
    dinteger_t toInteger();
    uinteger_t toUInteger();
    real_t toReal();
    real_t toImaginary();
    complex_t toComplex();
    Expression *castTo(Scope *sc, Type *t);
    int isConst();
    int isBool(int result);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer *buf);
#ifdef _DH
    OutBuffer hexp;
#endif
    elem *toElem(IRState *irs);
    dt_t **toDt(dt_t **pdt);
};

struct IdentifierExp : Expression
{
    Identifier *ident;
    Declaration *var;

    IdentifierExp(Loc loc, Identifier *ident);
    IdentifierExp(Loc loc, Declaration *var);
    Expression *semantic(Scope *sc);
    char *toChars();
    void dump(int indent);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
};

struct DollarExp : IdentifierExp
{
    DollarExp(Loc loc);
};

struct DsymbolExp : Expression
{
    Dsymbol *s;
    int hasOverloads;

    DsymbolExp(Loc loc, Dsymbol *s, int hasOverloads = 0);
    Expression *semantic(Scope *sc);
    char *toChars();
    void dump(int indent);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
};

struct ThisExp : Expression
{
    Declaration *var;

    ThisExp(Loc loc);
    Expression *semantic(Scope *sc);
    int isBool(int result);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
    void scanForNestedRef(Scope *sc);

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    //Expression *inlineScan(InlineScanState *iss);

    elem *toElem(IRState *irs);
};

struct SuperExp : ThisExp
{
    SuperExp(Loc loc);
    Expression *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void scanForNestedRef(Scope *sc);

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    //Expression *inlineScan(InlineScanState *iss);
};

struct NullExp : Expression
{
    unsigned char committed;	// !=0 if type is committed

    NullExp(Loc loc);
    Expression *semantic(Scope *sc);
    int isBool(int result);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer *buf);
    MATCH implicitConvTo(Type *t);
    Expression *castTo(Scope *sc, Type *t);
    Expression *interpret(InterState *istate);
    elem *toElem(IRState *irs);
    dt_t **toDt(dt_t **pdt);
};

struct StringExp : Expression
{
    void *string;	// char, wchar, or dchar data
    size_t len;		// number of chars, wchars, or dchars
    unsigned char sz;	// 1: char, 2: wchar, 4: dchar
    unsigned char committed;	// !=0 if type is committed
    unsigned char postfix;	// 'c', 'w', 'd'

    StringExp(Loc loc, char *s);
    StringExp(Loc loc, void *s, size_t len);
    StringExp(Loc loc, void *s, size_t len, unsigned char postfix);
    //Expression *syntaxCopy();
    int equals(Object *o);
    char *toChars();
    Expression *semantic(Scope *sc);
    Expression *interpret(InterState *istate);
    size_t length();
    StringExp *toUTF8(Scope *sc);
    Expression *implicitCastTo(Scope *sc, Type *t);
    MATCH implicitConvTo(Type *t);
    Expression *castTo(Scope *sc, Type *t);
    int compare(Object *obj);
    int isBool(int result);
    unsigned charAt(size_t i);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer *buf);
    elem *toElem(IRState *irs);
    dt_t **toDt(dt_t **pdt);
};

// Tuple

struct TupleExp : Expression
{
    Expressions *exps;

    TupleExp(Loc loc, Expressions *exps);
    TupleExp(Loc loc, TupleDeclaration *tup);
    Expression *syntaxCopy();
    int equals(Object *o);
    Expression *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void scanForNestedRef(Scope *sc);
    void checkEscape();
    int checkSideEffect(int flag);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    Expression *castTo(Scope *sc, Type *t);
    elem *toElem(IRState *irs);
    int canThrow();

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Expression *inlineScan(InlineScanState *iss);
};

struct ArrayLiteralExp : Expression
{
    Expressions *elements;

    ArrayLiteralExp(Loc loc, Expressions *elements);
    ArrayLiteralExp(Loc loc, Expression *e);

    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    int isBool(int result);
    elem *toElem(IRState *irs);
    int checkSideEffect(int flag);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer *buf);
    void scanForNestedRef(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    MATCH implicitConvTo(Type *t);
    Expression *castTo(Scope *sc, Type *t);
    dt_t **toDt(dt_t **pdt);
    int canThrow();

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Expression *inlineScan(InlineScanState *iss);
};

struct AssocArrayLiteralExp : Expression
{
    Expressions *keys;
    Expressions *values;

    AssocArrayLiteralExp(Loc loc, Expressions *keys, Expressions *values);

    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    int isBool(int result);
    elem *toElem(IRState *irs);
    int checkSideEffect(int flag);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer *buf);
    void scanForNestedRef(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    MATCH implicitConvTo(Type *t);
    Expression *castTo(Scope *sc, Type *t);
    int canThrow();

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Expression *inlineScan(InlineScanState *iss);
};

struct StructLiteralExp : Expression
{
    StructDeclaration *sd;		// which aggregate this is for
    Expressions *elements;	// parallels sd->fields[] with
				// NULL entries for fields to skip

    Symbol *sym;		// back end symbol to initialize with literal
    size_t soffset;		// offset from start of s
    int fillHoles;		// fill alignment 'holes' with zero

    StructLiteralExp(Loc loc, StructDeclaration *sd, Expressions *elements);

    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    Expression *getField(Type *type, unsigned offset);
    int getFieldIndex(Type *type, unsigned offset);
    elem *toElem(IRState *irs);
    int checkSideEffect(int flag);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void toMangleBuffer(OutBuffer *buf);
    void scanForNestedRef(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    dt_t **toDt(dt_t **pdt);
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
    int canThrow();
    MATCH implicitConvTo(Type *t);

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Expression *inlineScan(InlineScanState *iss);
};

Expression *typeDotIdExp(Loc loc, Type *type, Identifier *ident);

struct TypeExp : Expression
{
    TypeExp(Loc loc, Type *type);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    void rvalue();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Expression *optimize(int result);
    elem *toElem(IRState *irs);
};

struct ScopeExp : Expression
{
    ScopeDsymbol *sds;

    ScopeExp(Loc loc, ScopeDsymbol *sds);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    elem *toElem(IRState *irs);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct TemplateExp : Expression
{
    TemplateDeclaration *td;

    TemplateExp(Loc loc, TemplateDeclaration *td);
    void rvalue();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct NewExp : Expression
{
    /* thisexp.new(newargs) newtype(arguments)
     */
    Expression *thisexp;	// if !NULL, 'this' for class being allocated
    Expressions *newargs;	// Array of Expression's to call new operator
    Type *newtype;
    Expressions *arguments;	// Array of Expression's

    CtorDeclaration *member;	// constructor function
    NewDeclaration *allocator;	// allocator function
    int onstack;		// allocate on stack

    NewExp(Loc loc, Expression *thisexp, Expressions *newargs,
	Type *newtype, Expressions *arguments);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    elem *toElem(IRState *irs);
    int checkSideEffect(int flag);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void scanForNestedRef(Scope *sc);
    int canThrow();

    //int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    //Expression *inlineScan(InlineScanState *iss);
};

struct NewAnonClassExp : Expression
{
    /* thisexp.new(newargs) class baseclasses { } (arguments)
     */
    Expression *thisexp;	// if !NULL, 'this' for class being allocated
    Expressions *newargs;	// Array of Expression's to call new operator
    ClassDeclaration *cd;	// class being instantiated
    Expressions *arguments;	// Array of Expression's to call class constructor

    NewAnonClassExp(Loc loc, Expression *thisexp, Expressions *newargs,
	ClassDeclaration *cd, Expressions *arguments);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    int checkSideEffect(int flag);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    int canThrow();
};

struct SymbolExp : Expression
{
    Declaration *var;
    int hasOverloads;

    SymbolExp(Loc loc, enum TOK op, int size, Declaration *var, int hasOverloads);

    elem *toElem(IRState *irs);
};

// Offset from symbol

struct SymOffExp : SymbolExp
{
    unsigned offset;

    SymOffExp(Loc loc, Declaration *var, unsigned offset, int hasOverloads = 0);
    Expression *semantic(Scope *sc);
    void checkEscape();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    int isConst();
    int isBool(int result);
    Expression *doInline(InlineDoState *ids);
    MATCH implicitConvTo(Type *t);
    Expression *castTo(Scope *sc, Type *t);
    void scanForNestedRef(Scope *sc);

    dt_t **toDt(dt_t **pdt);
};

// Variable

struct VarExp : SymbolExp
{
    VarExp(Loc loc, Declaration *var, int hasOverloads = 0);
    int equals(Object *o);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void dump(int indent);
    char *toChars();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void checkEscape();
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
    Expression *modifiableLvalue(Scope *sc, Expression *e);
    dt_t **toDt(dt_t **pdt);
    void scanForNestedRef(Scope *sc);

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    //Expression *inlineScan(InlineScanState *iss);
};

#if DMDV2
// Overload Set

struct OverExp : Expression
{
    OverloadSet *vars;

    OverExp(OverloadSet *s);
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
};
#endif

// Function/Delegate literal

struct FuncExp : Expression
{
    FuncLiteralDeclaration *fd;

    FuncExp(Loc loc, FuncLiteralDeclaration *fd);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    void scanForNestedRef(Scope *sc);
    char *toChars();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);

    int inlineCost(InlineCostState *ics);
    //Expression *doInline(InlineDoState *ids);
    //Expression *inlineScan(InlineScanState *iss);
};

// Declaration of a symbol

struct DeclarationExp : Expression
{
    Dsymbol *declaration;

    DeclarationExp(Loc loc, Dsymbol *declaration);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    Expression *interpret(InterState *istate);
    int checkSideEffect(int flag);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);
    void scanForNestedRef(Scope *sc);
    int canThrow();

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Expression *inlineScan(InlineScanState *iss);
};

struct TypeidExp : Expression
{
    Type *typeidType;

    TypeidExp(Loc loc, Type *typeidType);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

#if DMDV2
struct TraitsExp : Expression
{
    Identifier *ident;
    Objects *args;

    TraitsExp(Loc loc, Identifier *ident, Objects *args);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};
#endif

struct HaltExp : Expression
{
    HaltExp(Loc loc);
    Expression *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    int checkSideEffect(int flag);

    elem *toElem(IRState *irs);
};

struct IsExp : Expression
{
    /* is(targ id tok tspec)
     * is(targ id == tok2)
     */
    Type *targ;
    Identifier *id;	// can be NULL
    enum TOK tok;	// ':' or '=='
    Type *tspec;	// can be NULL
    enum TOK tok2;	// 'struct', 'union', 'typedef', etc.
    TemplateParameters *parameters;

    IsExp(Loc loc, Type *targ, Identifier *id, enum TOK tok, Type *tspec,
	enum TOK tok2, TemplateParameters *parameters);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

/****************************************************************/

struct UnaExp : Expression
{
    Expression *e1;

    UnaExp(Loc loc, enum TOK op, int size, Expression *e1);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Expression *optimize(int result);
    void dump(int indent);
    void scanForNestedRef(Scope *sc);
    Expression *interpretCommon(InterState *istate, Expression *(*fp)(Type *, Expression *));
    int canThrow();

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Expression *inlineScan(InlineScanState *iss);

    Expression *op_overload(Scope *sc);	// doesn't need to be virtual
};

struct BinExp : Expression
{
    Expression *e1;
    Expression *e2;

    BinExp(Loc loc, enum TOK op, int size, Expression *e1, Expression *e2);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    Expression *semanticp(Scope *sc);
    Expression *commonSemanticAssign(Scope *sc);
    Expression *commonSemanticAssignIntegral(Scope *sc);
    int checkSideEffect(int flag);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Expression *scaleFactor(Scope *sc);
    Expression *typeCombine(Scope *sc);
    Expression *optimize(int result);
    int isunsigned();
    void incompatibleTypes();
    void dump(int indent);
    void scanForNestedRef(Scope *sc);
    Expression *interpretCommon(InterState *istate, Expression *(*fp)(Type *, Expression *, Expression *));
    Expression *interpretCommon2(InterState *istate, Expression *(*fp)(TOK, Type *, Expression *, Expression *));
    Expression *interpretAssignCommon(InterState *istate, Expression *(*fp)(Type *, Expression *, Expression *), int post = 0);
    int canThrow();
    Expression *arrayOp(Scope *sc);

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Expression *inlineScan(InlineScanState *iss);

    Expression *op_overload(Scope *sc);

    elem *toElemBin(IRState *irs, int op);
};

struct BinAssignExp : BinExp
{
    BinAssignExp(Loc loc, enum TOK op, int size, Expression *e1, Expression *e2);
    int checkSideEffect(int flag);
};

/****************************************************************/

struct CompileExp : UnaExp
{
    CompileExp(Loc loc, Expression *e);
    Expression *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct FileExp : UnaExp
{
    FileExp(Loc loc, Expression *e);
    Expression *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct AssertExp : UnaExp
{
    Expression *msg;

    AssertExp(Loc loc, Expression *e, Expression *msg = NULL);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    Expression *interpret(InterState *istate);
    int checkSideEffect(int flag);
    int canThrow();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Expression *inlineScan(InlineScanState *iss);

    elem *toElem(IRState *irs);
};

struct DotIdExp : UnaExp
{
    Identifier *ident;

    DotIdExp(Loc loc, Expression *e, Identifier *ident);
    Expression *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void dump(int i);
};

struct DotTemplateExp : UnaExp
{
    TemplateDeclaration *td;
    
    DotTemplateExp(Loc loc, Expression *e, TemplateDeclaration *td);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct DotVarExp : UnaExp
{
    Declaration *var;
    int hasOverloads;

    DotVarExp(Loc loc, Expression *e, Declaration *var, int hasOverloads = 0);
    Expression *semantic(Scope *sc);
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
    Expression *modifiableLvalue(Scope *sc, Expression *e);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void dump(int indent);
    elem *toElem(IRState *irs);
};

struct DotTemplateInstanceExp : UnaExp
{
    TemplateInstance *ti;

    DotTemplateInstanceExp(Loc loc, Expression *e, TemplateInstance *ti);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void dump(int indent);
};

struct DelegateExp : UnaExp
{
    FuncDeclaration *func;
    int hasOverloads;

    DelegateExp(Loc loc, Expression *e, FuncDeclaration *func, int hasOverloads = 0);
    Expression *semantic(Scope *sc);
    MATCH implicitConvTo(Type *t);
    Expression *castTo(Scope *sc, Type *t);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void dump(int indent);

    int inlineCost(InlineCostState *ics);
    elem *toElem(IRState *irs);
};

struct DotTypeExp : UnaExp
{
    Dsymbol *sym;		// symbol that represents a type

    DotTypeExp(Loc loc, Expression *e, Dsymbol *sym);
    Expression *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);
};

struct CallExp : UnaExp
{
    Expressions *arguments;	// function arguments

    CallExp(Loc loc, Expression *e, Expressions *exps);
    CallExp(Loc loc, Expression *e);
    CallExp(Loc loc, Expression *e, Expression *earg1);
    CallExp(Loc loc, Expression *e, Expression *earg1, Expression *earg2);

    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    int checkSideEffect(int flag);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void dump(int indent);
    elem *toElem(IRState *irs);
    void scanForNestedRef(Scope *sc);
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
    int canThrow();

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Expression *inlineScan(InlineScanState *iss);
};

struct AddrExp : UnaExp
{
    AddrExp(Loc loc, Expression *e);
    Expression *semantic(Scope *sc);
    elem *toElem(IRState *irs);
    MATCH implicitConvTo(Type *t);
    Expression *castTo(Scope *sc, Type *t);
    Expression *optimize(int result);
};

struct PtrExp : UnaExp
{
    PtrExp(Loc loc, Expression *e);
    PtrExp(Loc loc, Expression *e, Type *t);
    Expression *semantic(Scope *sc);
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
    Expression *modifiableLvalue(Scope *sc, Expression *e);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);

    // For operator overloading
    Identifier *opId();
};

struct NegExp : UnaExp
{
    NegExp(Loc loc, Expression *e);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void buildArrayIdent(OutBuffer *buf, Expressions *arguments);
    Expression *buildArrayLoop(Arguments *fparams);

    // For operator overloading
    Identifier *opId();

    elem *toElem(IRState *irs);
};

struct UAddExp : UnaExp
{
    UAddExp(Loc loc, Expression *e);
    Expression *semantic(Scope *sc);

    // For operator overloading
    Identifier *opId();
};

struct ComExp : UnaExp
{
    ComExp(Loc loc, Expression *e);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void buildArrayIdent(OutBuffer *buf, Expressions *arguments);
    Expression *buildArrayLoop(Arguments *fparams);

    // For operator overloading
    Identifier *opId();

    elem *toElem(IRState *irs);
};

struct NotExp : UnaExp
{
    NotExp(Loc loc, Expression *e);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    int isBit();
    elem *toElem(IRState *irs);
};

struct BoolExp : UnaExp
{
    BoolExp(Loc loc, Expression *e, Type *type);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    int isBit();
    elem *toElem(IRState *irs);
};

struct DeleteExp : UnaExp
{
    DeleteExp(Loc loc, Expression *e);
    Expression *semantic(Scope *sc);
    Expression *checkToBoolean();
    int checkSideEffect(int flag);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);
};

struct CastExp : UnaExp
{
    // Possible to cast to one type while painting to another type
    Type *to;			// type to cast to
    unsigned mod;		// MODxxxxx

    CastExp(Loc loc, Expression *e, Type *t);
    CastExp(Loc loc, Expression *e, unsigned mod);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    MATCH implicitConvTo(Type *t);
    IntRange getIntRange();
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    int checkSideEffect(int flag);
    void checkEscape();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);

    // For operator overloading
    Identifier *opId();
};


struct SliceExp : UnaExp
{
    Expression *upr;		// NULL if implicit 0
    Expression *lwr;		// NULL if implicit [length - 1]
    VarDeclaration *lengthVar;

    SliceExp(Loc loc, Expression *e1, Expression *lwr, Expression *upr);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    void checkEscape();
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
    Expression *modifiableLvalue(Scope *sc, Expression *e);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void dump(int indent);
    elem *toElem(IRState *irs);
    void scanForNestedRef(Scope *sc);
    void buildArrayIdent(OutBuffer *buf, Expressions *arguments);
    Expression *buildArrayLoop(Arguments *fparams);

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Expression *inlineScan(InlineScanState *iss);
};

struct ArrayLengthExp : UnaExp
{
    ArrayLengthExp(Loc loc, Expression *e1);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    elem *toElem(IRState *irs);
};

// e1[a0,a1,a2,a3,...]

struct ArrayExp : UnaExp
{
    Expressions *arguments;		// Array of Expression's

    ArrayExp(Loc loc, Expression *e1, Expressions *arguments);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void scanForNestedRef(Scope *sc);

    // For operator overloading
    Identifier *opId();

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Expression *inlineScan(InlineScanState *iss);
};

/****************************************************************/

struct DotExp : BinExp
{
    DotExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
};

struct CommaExp : BinExp
{
    CommaExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    void checkEscape();
    IntRange getIntRange();
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
    Expression *modifiableLvalue(Scope *sc, Expression *e);
    int isBool(int result);
    int checkSideEffect(int flag);
    MATCH implicitConvTo(Type *t);
    Expression *castTo(Scope *sc, Type *t);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    elem *toElem(IRState *irs);
};

struct IndexExp : BinExp
{
    VarDeclaration *lengthVar;
    int modifiable;

    IndexExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
    Expression *modifiableLvalue(Scope *sc, Expression *e);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    Expression *doInline(InlineDoState *ids);
    void scanForNestedRef(Scope *sc);

    elem *toElem(IRState *irs);
};

/* For both i++ and i--
 */
struct PostExp : BinExp
{
    PostExp(enum TOK op, Loc loc, Expression *e);
    Expression *semantic(Scope *sc);
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Identifier *opId();    // For operator overloading
    elem *toElem(IRState *irs);
};

struct AssignExp : BinExp
{   int ismemset;	// !=0 if setting the contents of an array

    AssignExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *checkToBoolean();
    Expression *interpret(InterState *istate);
    Identifier *opId();    // For operator overloading
    void buildArrayIdent(OutBuffer *buf, Expressions *arguments);
    Expression *buildArrayLoop(Arguments *fparams);
    elem *toElem(IRState *irs);
};

#define ASSIGNEXP(op)	\
struct op##AssignExp : BinExp					\
{								\
    op##AssignExp(Loc loc, Expression *e1, Expression *e2);	\
    Expression *semantic(Scope *sc);				\
    Expression *interpret(InterState *istate);			\
    X(void buildArrayIdent(OutBuffer *buf, Expressions *arguments);) \
    X(Expression *buildArrayLoop(Arguments *fparams);)		\
								\
    Identifier *opId();    /* For operator overloading */	\
								\
    elem *toElem(IRState *irs);					\
};

#define X(a) a
ASSIGNEXP(Add)
ASSIGNEXP(Min)
ASSIGNEXP(Mul)
ASSIGNEXP(Div)
ASSIGNEXP(Mod)
ASSIGNEXP(And)
ASSIGNEXP(Or)
ASSIGNEXP(Xor)
#undef X

#define X(a)

ASSIGNEXP(Shl)
ASSIGNEXP(Shr)
ASSIGNEXP(Ushr)
ASSIGNEXP(Cat)

#undef X
#undef ASSIGNEXP

struct AddExp : BinExp
{
    AddExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void buildArrayIdent(OutBuffer *buf, Expressions *arguments);
    Expression *buildArrayLoop(Arguments *fparams);

    // For operator overloading
    int isCommutative();
    Identifier *opId();
    Identifier *opId_r();

    elem *toElem(IRState *irs);
};

struct MinExp : BinExp
{
    MinExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void buildArrayIdent(OutBuffer *buf, Expressions *arguments);
    Expression *buildArrayLoop(Arguments *fparams);

    // For operator overloading
    Identifier *opId();
    Identifier *opId_r();

    elem *toElem(IRState *irs);
};

struct CatExp : BinExp
{
    CatExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);

    // For operator overloading
    Identifier *opId();
    Identifier *opId_r();

    elem *toElem(IRState *irs);
};

struct MulExp : BinExp
{
    MulExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void buildArrayIdent(OutBuffer *buf, Expressions *arguments);
    Expression *buildArrayLoop(Arguments *fparams);

    // For operator overloading
    int isCommutative();
    Identifier *opId();
    Identifier *opId_r();

    elem *toElem(IRState *irs);
};

struct DivExp : BinExp
{
    DivExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void buildArrayIdent(OutBuffer *buf, Expressions *arguments);
    Expression *buildArrayLoop(Arguments *fparams);
    IntRange getIntRange();

    // For operator overloading
    Identifier *opId();
    Identifier *opId_r();

    elem *toElem(IRState *irs);
};

struct ModExp : BinExp
{
    ModExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void buildArrayIdent(OutBuffer *buf, Expressions *arguments);
    Expression *buildArrayLoop(Arguments *fparams);

    // For operator overloading
    Identifier *opId();
    Identifier *opId_r();

    elem *toElem(IRState *irs);
};

struct ShlExp : BinExp
{
    ShlExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    IntRange getIntRange();

    // For operator overloading
    Identifier *opId();
    Identifier *opId_r();

    elem *toElem(IRState *irs);
};

struct ShrExp : BinExp
{
    ShrExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    IntRange getIntRange();

    // For operator overloading
    Identifier *opId();
    Identifier *opId_r();

    elem *toElem(IRState *irs);
};

struct UshrExp : BinExp
{
    UshrExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    IntRange getIntRange();

    // For operator overloading
    Identifier *opId();
    Identifier *opId_r();

    elem *toElem(IRState *irs);
};

struct AndExp : BinExp
{
    AndExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void buildArrayIdent(OutBuffer *buf, Expressions *arguments);
    Expression *buildArrayLoop(Arguments *fparams);
    IntRange getIntRange();

    // For operator overloading
    int isCommutative();
    Identifier *opId();
    Identifier *opId_r();

    elem *toElem(IRState *irs);
};

struct OrExp : BinExp
{
    OrExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void buildArrayIdent(OutBuffer *buf, Expressions *arguments);
    Expression *buildArrayLoop(Arguments *fparams);
    MATCH implicitConvTo(Type *t);
    IntRange getIntRange();

    // For operator overloading
    int isCommutative();
    Identifier *opId();
    Identifier *opId_r();

    elem *toElem(IRState *irs);
};

struct XorExp : BinExp
{
    XorExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void buildArrayIdent(OutBuffer *buf, Expressions *arguments);
    Expression *buildArrayLoop(Arguments *fparams);
    MATCH implicitConvTo(Type *t);
    IntRange getIntRange();

    // For operator overloading
    int isCommutative();
    Identifier *opId();
    Identifier *opId_r();

    elem *toElem(IRState *irs);
};

struct OrOrExp : BinExp
{
    OrOrExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *checkToBoolean();
    int isBit();
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    int checkSideEffect(int flag);
    elem *toElem(IRState *irs);
};

struct AndAndExp : BinExp
{
    AndAndExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *checkToBoolean();
    int isBit();
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    int checkSideEffect(int flag);
    elem *toElem(IRState *irs);
};

struct CmpExp : BinExp
{
    CmpExp(enum TOK op, Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    int isBit();

    // For operator overloading
    int isCommutative();
    Identifier *opId();

    elem *toElem(IRState *irs);
};

struct InExp : BinExp
{
    InExp(Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    int isBit();

    // For operator overloading
    Identifier *opId();
    Identifier *opId_r();

    elem *toElem(IRState *irs);
};

struct RemoveExp : BinExp
{
    RemoveExp(Loc loc, Expression *e1, Expression *e2);
    elem *toElem(IRState *irs);
};

// == and !=

struct EqualExp : BinExp
{
    EqualExp(enum TOK op, Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    int isBit();

    // For operator overloading
    int isCommutative();
    Identifier *opId();

    elem *toElem(IRState *irs);
};

// === and !===

struct IdentityExp : BinExp
{
    IdentityExp(enum TOK op, Loc loc, Expression *e1, Expression *e2);
    Expression *semantic(Scope *sc);
    int isBit();
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    elem *toElem(IRState *irs);
};

/****************************************************************/

struct CondExp : BinExp
{
    Expression *econd;

    CondExp(Loc loc, Expression *econd, Expression *e1, Expression *e2);
    Expression *syntaxCopy();
    Expression *semantic(Scope *sc);
    Expression *optimize(int result);
    Expression *interpret(InterState *istate);
    void checkEscape();
    int isLvalue();
    Expression *toLvalue(Scope *sc, Expression *e);
    Expression *modifiableLvalue(Scope *sc, Expression *e);
    Expression *checkToBoolean();
    int checkSideEffect(int flag);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    MATCH implicitConvTo(Type *t);
    Expression *castTo(Scope *sc, Type *t);
    void scanForNestedRef(Scope *sc);
    int canThrow();

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Expression *inlineScan(InlineScanState *iss);

    elem *toElem(IRState *irs);
};

#if DMDV2
/****************************************************************/

struct DefaultInitExp : Expression
{
    enum TOK subop;		// which of the derived classes this is

    DefaultInitExp(Loc loc, enum TOK subop, int size);
    virtual Expression *resolve(Loc loc, Scope *sc) = 0;
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct FileInitExp : DefaultInitExp
{
    FileInitExp(Loc loc);
    Expression *semantic(Scope *sc);
    Expression *resolve(Loc loc, Scope *sc);
};

struct LineInitExp : DefaultInitExp
{
    LineInitExp(Loc loc);
    Expression *semantic(Scope *sc);
    Expression *resolve(Loc loc, Scope *sc);
};
#endif







// Back end
#if IN_GCC
union tree_node; typedef union tree_node TYPE;
typedef TYPE type;
#else
typedef struct TYPE type;
#endif
struct Symbol;

enum ENUMTY
{
    Tarray,		// dynamic array
    Tsarray,		// static array
    Taarray,		// associative array
    Tpointer,
    Treference,
    Tfunction,
    Tident,
    Tclass,
    Tstruct,
    Tenum,
    Ttypedef,
    Tdelegate,

    Tnone,
    Tvoid,
    Tint8,
    Tuns8,
    Tint16,
    Tuns16,
    Tint32,
    Tuns32,
    Tint64,
    Tuns64,
    Tfloat32,
    Tfloat64,
    Tfloat80,

    Timaginary32,
    Timaginary64,
    Timaginary80,

    Tcomplex32,
    Tcomplex64,
    Tcomplex80,

    Tbit,
    Tbool,
    Tchar,
    Twchar,
    Tdchar,

    Terror,
    Tinstance,
    Ttypeof,
    Ttuple,
    Tslice,
    Treturn,
    TMAX
};
typedef unsigned char TY;	// ENUMTY

#define Tascii Tchar

extern int Tsize_t;
extern int Tptrdiff_t;


struct Type : Object
{
    TY ty;
    unsigned char mod;	// modifiers MODxxxx
	/* pick this order of numbers so switch statements work better
	 */
	#define MODconst     1	// type is const
	#define MODinvariant 4	// type is invariant
	#define MODshared    2	// type is shared
    char *deco;

    /* Note that there is no "shared immutable", because that is just immutable
     */

    Type *cto;		// MODconst ? mutable version of this type : const version
    Type *ito;		// MODinvariant ? mutable version of this type : invariant version
    Type *sto;		// MODshared ? mutable version of this type : shared mutable version
    Type *scto;		// MODshared|MODconst ? mutable version of this type : shared const version

    Type *pto;		// merged pointer to this type
    Type *rto;		// reference to this type
    Type *arrayof;	// array of this type
    TypeInfoDeclaration *vtinfo;	// TypeInfo object for this Type

    type *ctype;	// for back end

    #define tvoid	basic[Tvoid]
    #define tint8	basic[Tint8]
    #define tuns8	basic[Tuns8]
    #define tint16	basic[Tint16]
    #define tuns16	basic[Tuns16]
    #define tint32	basic[Tint32]
    #define tuns32	basic[Tuns32]
    #define tint64	basic[Tint64]
    #define tuns64	basic[Tuns64]
    #define tfloat32	basic[Tfloat32]
    #define tfloat64	basic[Tfloat64]
    #define tfloat80	basic[Tfloat80]

    #define timaginary32 basic[Timaginary32]
    #define timaginary64 basic[Timaginary64]
    #define timaginary80 basic[Timaginary80]

    #define tcomplex32	basic[Tcomplex32]
    #define tcomplex64	basic[Tcomplex64]
    #define tcomplex80	basic[Tcomplex80]

    #define tbit	basic[Tbit]
    #define tbool	basic[Tbool]
    #define tchar	basic[Tchar]
    #define twchar	basic[Twchar]
    #define tdchar	basic[Tdchar]

    // Some special types
    #define tshiftcnt	tint32		// right side of shift expression
//    #define tboolean	tint32		// result of boolean expression
    #define tboolean	tbool		// result of boolean expression
    #define tindex	tint32		// array/ptr index
    static Type *tvoidptr;		// void*
    #define terror	basic[Terror]	// for error recovery

    #define tsize_t	basic[Tsize_t]		// matches size_t alias
    #define tptrdiff_t	basic[Tptrdiff_t]	// matches ptrdiff_t alias
    #define thash_t	tsize_t			// matches hash_t alias

    static ClassDeclaration *typeinfo;
    static ClassDeclaration *typeinfoclass;
    static ClassDeclaration *typeinfointerface;
    static ClassDeclaration *typeinfostruct;
    static ClassDeclaration *typeinfotypedef;
    static ClassDeclaration *typeinfopointer;
    static ClassDeclaration *typeinfoarray;
    static ClassDeclaration *typeinfostaticarray;
    static ClassDeclaration *typeinfoassociativearray;
    static ClassDeclaration *typeinfoenum;
    static ClassDeclaration *typeinfofunction;
    static ClassDeclaration *typeinfodelegate;
    static ClassDeclaration *typeinfotypelist;
    static ClassDeclaration *typeinfoconst;
    static ClassDeclaration *typeinfoinvariant;
    static ClassDeclaration *typeinfoshared;

    static Type *basic[TMAX];
    static unsigned char mangleChar[TMAX];
    static unsigned char sizeTy[TMAX];
    static StringTable stringtable;

    // These tables are for implicit conversion of binary ops;
    // the indices are the type of operand one, followed by operand two.
    static unsigned char impcnvResult[TMAX][TMAX];
    static unsigned char impcnvType1[TMAX][TMAX];
    static unsigned char impcnvType2[TMAX][TMAX];

    // If !=0, give warning on implicit conversion
    static unsigned char impcnvWarn[TMAX][TMAX];

    Type(TY ty);
    virtual Type *syntaxCopy();
    int equals(Object *o);
    int dyncast() { return DYNCAST_TYPE; } // kludge for template.isType()
    int covariant(Type *t);
    char *toChars();
    static char needThisPrefix();
    static void init();
    d_uns64 size();
    virtual d_uns64 size(Loc loc);
    virtual unsigned alignsize();
    virtual Type *semantic(Loc loc, Scope *sc);
    Type *trySemantic(Loc loc, Scope *sc);
    virtual void toDecoBuffer(OutBuffer *buf, int flag = 0);
    Type *merge();
    Type *merge2();
    virtual void toCBuffer(OutBuffer *buf, Identifier *ident, HdrGenState *hgs);
    virtual void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    void toCBuffer3(OutBuffer *buf, HdrGenState *hgs, int mod);
#if CPP_MANGLE
    virtual void toCppMangle(OutBuffer *buf, CppMangleState *cms);
#endif
    virtual int isintegral();
    virtual int isfloating();	// real, imaginary, or complex
    virtual int isreal();
    virtual int isimaginary();
    virtual int iscomplex();
    virtual int isscalar();
    virtual int isunsigned();
    virtual int isauto();
    virtual int isString();
    virtual int isAssignable();
    virtual int checkBoolean();	// if can be converted to boolean value
    virtual void checkDeprecated(Loc loc, Scope *sc);
    int isConst()	{ return mod & MODconst; }
    int isInvariant()	{ return mod & MODinvariant; }
    int isMutable()	{ return !(mod & (MODconst | MODinvariant)); }
    int isShared()	{ return mod & MODshared; }
    int isSharedConst()	{ return mod == (MODshared | MODconst); }
    Type *constOf();
    Type *invariantOf();
    Type *mutableOf();
    Type *sharedOf();
    Type *sharedConstOf();
    void fixTo(Type *t);
    void check();
    Type *castMod(unsigned mod);
    Type *addMod(unsigned mod);
    Type *addStorageClass(unsigned stc);
    Type *pointerTo();
    Type *referenceTo();
    Type *arrayOf();
    virtual Type *makeConst();
    virtual Type *makeInvariant();
    virtual Type *makeShared();
    virtual Type *makeSharedConst();
    virtual Dsymbol *toDsymbol(Scope *sc);
    virtual Type *toBasetype();
    virtual Type *toHeadMutable();
    virtual int isBaseOf(Type *t, int *poffset);
    virtual MATCH constConv(Type *to);
    virtual MATCH implicitConvTo(Type *to);
    virtual ClassDeclaration *isClassHandle();
    virtual Expression *getProperty(Loc loc, Identifier *ident);
    virtual Expression *dotExp(Scope *sc, Expression *e, Identifier *ident);
    virtual unsigned memalign(unsigned salign);
    virtual Expression *defaultInit(Loc loc = 0);
    virtual int isZeroInit(Loc loc = 0);		// if initializer is 0
    virtual dt_t **toDt(dt_t **pdt);
    Identifier *getTypeInfoIdent(int internal);
    virtual MATCH deduceType(Scope *sc, Type *tparam, TemplateParameters *parameters, Objects *dedtypes);
    virtual void resolve(Loc loc, Scope *sc, Expression **pe, Type **pt, Dsymbol **ps);
    Expression *getInternalTypeInfo(Scope *sc);
    Expression *getTypeInfo(Scope *sc);
    virtual TypeInfoDeclaration *getTypeInfoDeclaration();
    virtual int builtinTypeInfo();
    virtual Type *reliesOnTident();
    virtual Expression *toExpression();
    virtual int hasPointers();
    virtual Type *nextOf();
    uinteger_t sizemask();

    static void error(Loc loc, const char *format, ...);
    static void warning(Loc loc, const char *format, ...);

    // For backend
    virtual unsigned totym();
    virtual type *toCtype();
    virtual type *toCParamtype();
    virtual Symbol *toSymbol();

    // For eliminating dynamic_cast
    virtual TypeBasic *isTypeBasic();
};

struct TypeNext : Type
{
    Type *next;

    TypeNext(TY ty, Type *next);
    void toDecoBuffer(OutBuffer *buf, int flag);
    void checkDeprecated(Loc loc, Scope *sc);
    Type *reliesOnTident();
    Type *nextOf();
    Type *makeConst();
    Type *makeInvariant();
    Type *makeShared();
    Type *makeSharedConst();
    MATCH constConv(Type *to);
    void transitive();
};

struct TypeBasic : Type
{
    const char *dstring;
    unsigned flags;

    TypeBasic(TY ty);
    Type *syntaxCopy();
    d_uns64 size(Loc loc);
    unsigned alignsize();
    Expression *getProperty(Loc loc, Identifier *ident);
    Expression *dotExp(Scope *sc, Expression *e, Identifier *ident);
    char *toChars();
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
#if CPP_MANGLE
    void toCppMangle(OutBuffer *buf, CppMangleState *cms);
#endif
    int isintegral();
    int isbit();
    int isfloating();
    int isreal();
    int isimaginary();
    int iscomplex();
    int isscalar();
    int isunsigned();
    MATCH implicitConvTo(Type *to);
    Expression *defaultInit(Loc loc);
    int isZeroInit(Loc loc);
    int builtinTypeInfo();

    // For eliminating dynamic_cast
    TypeBasic *isTypeBasic();
};

struct TypeArray : TypeNext
{
    TypeArray(TY ty, Type *next);
    Expression *dotExp(Scope *sc, Expression *e, Identifier *ident);
};

// Static array, one with a fixed dimension
struct TypeSArray : TypeArray
{
    Expression *dim;

    TypeSArray(Type *t, Expression *dim);
    Type *syntaxCopy();
    d_uns64 size(Loc loc);
    unsigned alignsize();
    Type *semantic(Loc loc, Scope *sc);
    void resolve(Loc loc, Scope *sc, Expression **pe, Type **pt, Dsymbol **ps);
    void toDecoBuffer(OutBuffer *buf, int flag);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    Expression *dotExp(Scope *sc, Expression *e, Identifier *ident);
    int isString();
    int isZeroInit(Loc loc);
    unsigned memalign(unsigned salign);
    MATCH constConv(Type *to);
    MATCH implicitConvTo(Type *to);
    Expression *defaultInit(Loc loc);
    dt_t **toDt(dt_t **pdt);
    dt_t **toDtElem(dt_t **pdt, Expression *e);
    MATCH deduceType(Scope *sc, Type *tparam, TemplateParameters *parameters, Objects *dedtypes);
    TypeInfoDeclaration *getTypeInfoDeclaration();
    Expression *toExpression();
    int hasPointers();
#if CPP_MANGLE
    void toCppMangle(OutBuffer *buf, CppMangleState *cms);
#endif

    type *toCtype();
    type *toCParamtype();
};

// Dynamic array, no dimension
struct TypeDArray : TypeArray
{
    TypeDArray(Type *t);
    Type *syntaxCopy();
    d_uns64 size(Loc loc);
    unsigned alignsize();
    Type *semantic(Loc loc, Scope *sc);
    void toDecoBuffer(OutBuffer *buf, int flag);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    Expression *dotExp(Scope *sc, Expression *e, Identifier *ident);
    int isString();
    int isZeroInit(Loc loc);
    int checkBoolean();
    MATCH implicitConvTo(Type *to);
    Expression *defaultInit(Loc loc);
    int builtinTypeInfo();
    MATCH deduceType(Scope *sc, Type *tparam, TemplateParameters *parameters, Objects *dedtypes);
    TypeInfoDeclaration *getTypeInfoDeclaration();
    int hasPointers();
#if CPP_MANGLE
    void toCppMangle(OutBuffer *buf, CppMangleState *cms);
#endif

    type *toCtype();
};

struct TypeAArray : TypeArray
{
    Type *index;		// key type

    TypeAArray(Type *t, Type *index);
    Type *syntaxCopy();
    d_uns64 size(Loc loc);
    Type *semantic(Loc loc, Scope *sc);
    void resolve(Loc loc, Scope *sc, Expression **pe, Type **pt, Dsymbol **ps);
    void toDecoBuffer(OutBuffer *buf, int flag);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    Expression *dotExp(Scope *sc, Expression *e, Identifier *ident);
    Expression *defaultInit(Loc loc);
    MATCH deduceType(Scope *sc, Type *tparam, TemplateParameters *parameters, Objects *dedtypes);
    int isZeroInit(Loc loc);
    int checkBoolean();
    TypeInfoDeclaration *getTypeInfoDeclaration();
    int hasPointers();
    MATCH implicitConvTo(Type *to);
    MATCH constConv(Type *to);
#if CPP_MANGLE
    void toCppMangle(OutBuffer *buf, CppMangleState *cms);
#endif

    // Back end
    Symbol *aaGetSymbol(const char *func, int flags);

    type *toCtype();
};

struct TypePointer : TypeNext
{
    TypePointer(Type *t);
    Type *syntaxCopy();
    Type *semantic(Loc loc, Scope *sc);
    d_uns64 size(Loc loc);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    MATCH implicitConvTo(Type *to);
    int isscalar();
    Expression *defaultInit(Loc loc);
    int isZeroInit(Loc loc);
    TypeInfoDeclaration *getTypeInfoDeclaration();
    int hasPointers();
#if CPP_MANGLE
    void toCppMangle(OutBuffer *buf, CppMangleState *cms);
#endif

    type *toCtype();
};

struct TypeReference : TypeNext
{
    TypeReference(Type *t);
    Type *syntaxCopy();
    Type *semantic(Loc loc, Scope *sc);
    d_uns64 size(Loc loc);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    Expression *dotExp(Scope *sc, Expression *e, Identifier *ident);
    Expression *defaultInit(Loc loc);
    int isZeroInit(Loc loc);
#if CPP_MANGLE
    void toCppMangle(OutBuffer *buf, CppMangleState *cms);
#endif
};

enum RET
{
    RETregs	= 1,	// returned in registers
    RETstack	= 2,	// returned on stack
};

struct TypeFunction : TypeNext
{
    // .next is the return type

    Arguments *parameters;	// function parameters
    int varargs;	// 1: T t, ...) style for variable number of arguments
			// 2: T t ...) style for variable number of arguments
    bool isnothrow;	// true: nothrow
    bool ispure;	// true: pure
    bool isref;		// true: returns a reference
    enum LINK linkage;	// calling convention

    int inuse;

    TypeFunction(Arguments *parameters, Type *treturn, int varargs, enum LINK linkage);
    Type *syntaxCopy();
    Type *semantic(Loc loc, Scope *sc);
    void toDecoBuffer(OutBuffer *buf, int flag);
    void toCBuffer(OutBuffer *buf, Identifier *ident, HdrGenState *hgs);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    MATCH deduceType(Scope *sc, Type *tparam, TemplateParameters *parameters, Objects *dedtypes);
    TypeInfoDeclaration *getTypeInfoDeclaration();
    Type *reliesOnTident();
#if CPP_MANGLE
    void toCppMangle(OutBuffer *buf, CppMangleState *cms);
#endif
    bool parameterEscapes(Argument *p);

    int callMatch(Expression *ethis, Expressions *toargs);
    type *toCtype();
    enum RET retStyle();

    unsigned totym();
};

struct TypeDelegate : TypeNext
{
    // .next is a TypeFunction

    TypeDelegate(Type *t);
    Type *syntaxCopy();
    Type *semantic(Loc loc, Scope *sc);
    d_uns64 size(Loc loc);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    Expression *defaultInit(Loc loc);
    int isZeroInit(Loc loc);
    int checkBoolean();
    TypeInfoDeclaration *getTypeInfoDeclaration();
    Expression *dotExp(Scope *sc, Expression *e, Identifier *ident);
    int hasPointers();
#if CPP_MANGLE
    void toCppMangle(OutBuffer *buf, CppMangleState *cms);
#endif

    type *toCtype();
};

struct TypeQualified : Type
{
    Loc loc;
    Array idents;	// array of Identifier's representing ident.ident.ident etc.

    TypeQualified(TY ty, Loc loc);
    void syntaxCopyHelper(TypeQualified *t);
    void addIdent(Identifier *ident);
    void toCBuffer2Helper(OutBuffer *buf, HdrGenState *hgs);
    d_uns64 size(Loc loc);
    void resolveHelper(Loc loc, Scope *sc, Dsymbol *s, Dsymbol *scopesym,
	Expression **pe, Type **pt, Dsymbol **ps);
};

struct TypeIdentifier : TypeQualified
{
    Identifier *ident;

    TypeIdentifier(Loc loc, Identifier *ident);
    Type *syntaxCopy();
    //char *toChars();
    void toDecoBuffer(OutBuffer *buf, int flag);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    void resolve(Loc loc, Scope *sc, Expression **pe, Type **pt, Dsymbol **ps);
    Dsymbol *toDsymbol(Scope *sc);
    Type *semantic(Loc loc, Scope *sc);
    MATCH deduceType(Scope *sc, Type *tparam, TemplateParameters *parameters, Objects *dedtypes);
    Type *reliesOnTident();
    Expression *toExpression();
};

/* Similar to TypeIdentifier, but with a TemplateInstance as the root
 */
struct TypeInstance : TypeQualified
{
    TemplateInstance *tempinst;

    TypeInstance(Loc loc, TemplateInstance *tempinst);
    Type *syntaxCopy();
    //char *toChars();
    //void toDecoBuffer(OutBuffer *buf, int flag);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    void resolve(Loc loc, Scope *sc, Expression **pe, Type **pt, Dsymbol **ps);
    Type *semantic(Loc loc, Scope *sc);
    Dsymbol *toDsymbol(Scope *sc);
    MATCH deduceType(Scope *sc, Type *tparam, TemplateParameters *parameters, Objects *dedtypes);
};

struct TypeTypeof : TypeQualified
{
    Expression *exp;

    TypeTypeof(Loc loc, Expression *exp);
    Type *syntaxCopy();
    Dsymbol *toDsymbol(Scope *sc);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    Type *semantic(Loc loc, Scope *sc);
    d_uns64 size(Loc loc);
};

struct TypeReturn : TypeQualified
{
    TypeReturn(Loc loc);
    Type *syntaxCopy();
    Dsymbol *toDsymbol(Scope *sc);
    Type *semantic(Loc loc, Scope *sc);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
};

struct TypeStruct : Type
{
    StructDeclaration *sym;

    TypeStruct(StructDeclaration *sym);
    d_uns64 size(Loc loc);
    unsigned alignsize();
    char *toChars();
    Type *syntaxCopy();
    Type *semantic(Loc loc, Scope *sc);
    Dsymbol *toDsymbol(Scope *sc);
    void toDecoBuffer(OutBuffer *buf, int flag);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    Expression *dotExp(Scope *sc, Expression *e, Identifier *ident);
    unsigned memalign(unsigned salign);
    Expression *defaultInit(Loc loc);
    int isZeroInit(Loc loc);
    int isAssignable();
    int checkBoolean();
    dt_t **toDt(dt_t **pdt);
    MATCH deduceType(Scope *sc, Type *tparam, TemplateParameters *parameters, Objects *dedtypes);
    TypeInfoDeclaration *getTypeInfoDeclaration();
    int hasPointers();
    MATCH implicitConvTo(Type *to);
    MATCH constConv(Type *to);
    Type *toHeadMutable();
#if CPP_MANGLE
    void toCppMangle(OutBuffer *buf, CppMangleState *cms);
#endif

    type *toCtype();
};

struct TypeEnum : Type
{
    EnumDeclaration *sym;

    TypeEnum(EnumDeclaration *sym);
    Type *syntaxCopy();
    d_uns64 size(Loc loc);
    unsigned alignsize();
    char *toChars();
    Type *semantic(Loc loc, Scope *sc);
    Dsymbol *toDsymbol(Scope *sc);
    void toDecoBuffer(OutBuffer *buf, int flag);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    Expression *dotExp(Scope *sc, Expression *e, Identifier *ident);
    Expression *getProperty(Loc loc, Identifier *ident);
    int isintegral();
    int isfloating();
    int isscalar();
    int isunsigned();
    MATCH implicitConvTo(Type *to);
    MATCH constConv(Type *to);
    Type *toBasetype();
    Expression *defaultInit(Loc loc);
    int isZeroInit(Loc loc);
    MATCH deduceType(Scope *sc, Type *tparam, TemplateParameters *parameters, Objects *dedtypes);
    TypeInfoDeclaration *getTypeInfoDeclaration();
    int hasPointers();
#if CPP_MANGLE
    void toCppMangle(OutBuffer *buf, CppMangleState *cms);
#endif

    type *toCtype();
};

struct TypeTypedef : Type
{
    TypedefDeclaration *sym;

    TypeTypedef(TypedefDeclaration *sym);
    Type *syntaxCopy();
    d_uns64 size(Loc loc);
    unsigned alignsize();
    char *toChars();
    Type *semantic(Loc loc, Scope *sc);
    Dsymbol *toDsymbol(Scope *sc);
    void toDecoBuffer(OutBuffer *buf, int flag);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    Expression *dotExp(Scope *sc, Expression *e, Identifier *ident);
    Expression *getProperty(Loc loc, Identifier *ident);
    int isbit();
    int isintegral();
    int isfloating();
    int isreal();
    int isimaginary();
    int iscomplex();
    int isscalar();
    int isunsigned();
    int checkBoolean();
    int isAssignable();
    Type *toBasetype();
    MATCH implicitConvTo(Type *to);
    MATCH constConv(Type *to);
    Expression *defaultInit(Loc loc);
    int isZeroInit(Loc loc);
    dt_t **toDt(dt_t **pdt);
    MATCH deduceType(Scope *sc, Type *tparam, TemplateParameters *parameters, Objects *dedtypes);
    TypeInfoDeclaration *getTypeInfoDeclaration();
    int hasPointers();
    Type *toHeadMutable();
#if CPP_MANGLE
    void toCppMangle(OutBuffer *buf, CppMangleState *cms);
#endif

    type *toCtype();
    type *toCParamtype();
};

struct TypeClass : Type
{
    ClassDeclaration *sym;

    TypeClass(ClassDeclaration *sym);
    d_uns64 size(Loc loc);
    char *toChars();
    Type *syntaxCopy();
    Type *semantic(Loc loc, Scope *sc);
    Dsymbol *toDsymbol(Scope *sc);
    void toDecoBuffer(OutBuffer *buf, int flag);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    Expression *dotExp(Scope *sc, Expression *e, Identifier *ident);
    ClassDeclaration *isClassHandle();
    int isBaseOf(Type *t, int *poffset);
    MATCH implicitConvTo(Type *to);
    Expression *defaultInit(Loc loc);
    int isZeroInit(Loc loc);
    MATCH deduceType(Scope *sc, Type *tparam, TemplateParameters *parameters, Objects *dedtypes);
    int isauto();
    int checkBoolean();
    TypeInfoDeclaration *getTypeInfoDeclaration();
    int hasPointers();
    int builtinTypeInfo();
#if DMDV2
    Type *toHeadMutable();
    MATCH constConv(Type *to);
#if CPP_MANGLE
    void toCppMangle(OutBuffer *buf, CppMangleState *cms);
#endif
#endif

    type *toCtype();

    Symbol *toSymbol();
};

struct TypeTuple : Type
{
    Arguments *arguments;	// types making up the tuple

    TypeTuple(Arguments *arguments);
    TypeTuple(Expressions *exps);
    Type *syntaxCopy();
    Type *semantic(Loc loc, Scope *sc);
    int equals(Object *o);
    Type *reliesOnTident();
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
    void toDecoBuffer(OutBuffer *buf, int flag);
    Expression *getProperty(Loc loc, Identifier *ident);
    TypeInfoDeclaration *getTypeInfoDeclaration();
};

struct TypeSlice : TypeNext
{
    Expression *lwr;
    Expression *upr;

    TypeSlice(Type *next, Expression *lwr, Expression *upr);
    Type *syntaxCopy();
    Type *semantic(Loc loc, Scope *sc);
    void resolve(Loc loc, Scope *sc, Expression **pe, Type **pt, Dsymbol **ps);
    void toCBuffer2(OutBuffer *buf, HdrGenState *hgs, int mod);
};

/**************************************************************/

//enum InOut { None, In, Out, InOut, Lazy };

struct Argument : Object
{
    //enum InOut inout;
    unsigned storageClass;
    Type *type;
    Identifier *ident;
    Expression *defaultArg;

    Argument(unsigned storageClass, Type *type, Identifier *ident, Expression *defaultArg);
    Argument *syntaxCopy();
    Type *isLazyArray();
    void toDecoBuffer(OutBuffer *buf);
    static Arguments *arraySyntaxCopy(Arguments *args);
    static char *argsTypesToChars(Arguments *args, int varargs);
    static void argsCppMangle(OutBuffer *buf, CppMangleState *cms, Arguments *arguments, int varargs);
    static void argsToCBuffer(OutBuffer *buf, HdrGenState *hgs, Arguments *arguments, int varargs);
    static void argsToDecoBuffer(OutBuffer *buf, Arguments *arguments);
    static int isTPL(Arguments *arguments);
    static size_t dim(Arguments *arguments);
    static Argument *getNth(Arguments *arguments, size_t nth, size_t *pn = NULL);
};




enum STC
{
    STCundefined    = 0,
    STCstatic	    = 1,
    STCextern	    = 2,
    STCconst	    = 4,
    STCfinal	    = 8,
    STCabstract     = 0x10,
    STCparameter    = 0x20,
    STCfield	    = 0x40,
    STCoverride	    = 0x80,
    STCauto         = 0x100,
    STCsynchronized = 0x200,
    STCdeprecated   = 0x400,
    STCin           = 0x800,		// in parameter
    STCout          = 0x1000,		// out parameter
    STClazy	    = 0x2000,		// lazy parameter
    STCforeach      = 0x4000,		// variable for foreach loop
    STCcomdat       = 0x8000,		// should go into COMDAT record
    STCvariadic     = 0x10000,		// variadic function argument
    STCctorinit     = 0x20000,		// can only be set inside constructor
    STCtemplateparameter = 0x40000,	// template parameter
    STCscope	    = 0x80000,		// template parameter
    STCinvariant    = 0x100000,
    STCimmutable    = 0x100000,
    STCref	    = 0x200000,
    STCinit	    = 0x400000,		// has explicit initializer
    STCmanifest	    = 0x800000,		// manifest constant
    STCnodtor	    = 0x1000000,	// don't run destructor
    STCnothrow	    = 0x2000000,	// never throws exceptions
    STCpure	    = 0x4000000,	// pure function
    STCtls	    = 0x8000000,	// thread local
    STCalias	    = 0x10000000,	// alias parameter
    STCshared       = 0x20000000,	// accessible from multiple threads
    STCgshared      = 0x40000000,	// accessible from multiple threads
					// but not typed as "shared"
    STC_TYPECTOR    = (STCconst | STCimmutable | STCshared),
};

struct Match
{
    int count;			// number of matches found
    MATCH last;			// match level of lastf
    FuncDeclaration *lastf;	// last matching function we found
    FuncDeclaration *nextf;	// current matching function
    FuncDeclaration *anyf;	// pick a func, any func, to use for error recovery
};

void overloadResolveX(Match *m, FuncDeclaration *f,
	Expression *ethis, Expressions *arguments);
int overloadApply(FuncDeclaration *fstart,
	int (*fp)(void *, FuncDeclaration *),
	void *param);

/**************************************************************/

struct Declaration : Dsymbol
{
    Type *type;
    Type *originalType;		// before semantic analysis
    unsigned storage_class;
    enum PROT protection;
    enum LINK linkage;
    int inuse;			// used to detect cycles

    Declaration(Identifier *id);
    void semantic(Scope *sc);
    const char *kind();
    unsigned size(Loc loc);
    void checkModify(Loc loc, Scope *sc, Type *t);

    void emitComment(Scope *sc);
    void toDocBuffer(OutBuffer *buf);

    char *mangle();
    int isStatic() { return storage_class & STCstatic; }
    virtual int isStaticConstructor();
    virtual int isStaticDestructor();
    virtual int isDelete();
    virtual int isDataseg();
    virtual int isThreadlocal();
    virtual int isCodeseg();
    int isCtorinit()     { return storage_class & STCctorinit; }
    int isFinal()        { return storage_class & STCfinal; }
    int isAbstract()     { return storage_class & STCabstract; }
    int isConst()        { return storage_class & STCconst; }
    int isInvariant()    { return storage_class & STCinvariant; }
    int isAuto()         { return storage_class & STCauto; }
    int isScope()        { return storage_class & (STCscope | STCauto); }
    int isSynchronized() { return storage_class & STCsynchronized; }
    int isParameter()    { return storage_class & STCparameter; }
    int isDeprecated()   { return storage_class & STCdeprecated; }
    int isOverride()     { return storage_class & STCoverride; }

    int isIn()    { return storage_class & STCin; }
    int isOut()   { return storage_class & STCout; }
    int isRef()   { return storage_class & STCref; }

    enum PROT prot();

    Declaration *isDeclaration() { return this; }
};

/**************************************************************/

struct TupleDeclaration : Declaration
{
    Objects *objects;
    int isexp;			// 1: expression tuple

    TypeTuple *tupletype;	// !=NULL if this is a type tuple

    TupleDeclaration(Loc loc, Identifier *ident, Objects *objects);
    Dsymbol *syntaxCopy(Dsymbol *);
    const char *kind();
    Type *getType();
    int needThis();

    TupleDeclaration *isTupleDeclaration() { return this; }
};

/**************************************************************/

struct TypedefDeclaration : Declaration
{
    Type *basetype;
    Initializer *init;
    int sem;			// 0: semantic() has not been run
				// 1: semantic() is in progress
				// 2: semantic() has been run
				// 3: semantic2() has been run

    TypedefDeclaration(Loc loc, Identifier *ident, Type *basetype, Initializer *init);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    void semantic2(Scope *sc);
    char *mangle();
    const char *kind();
    Type *getType();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
#ifdef _DH
    Type *htype;
    Type *hbasetype;
#endif

    void toDocBuffer(OutBuffer *buf);

    void toObjFile(int multiobj);			// compile to .obj file
    void toDebug();
    int cvMember(unsigned char *p);

    TypedefDeclaration *isTypedefDeclaration() { return this; }

    Symbol *sinit;
    Symbol *toInitializer();
};

/**************************************************************/

struct AliasDeclaration : Declaration
{
    Dsymbol *aliassym;
    Dsymbol *overnext;		// next in overload list
    int inSemantic;

    AliasDeclaration(Loc loc, Identifier *ident, Type *type);
    AliasDeclaration(Loc loc, Identifier *ident, Dsymbol *s);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    int overloadInsert(Dsymbol *s);
    const char *kind();
    Type *getType();
    Dsymbol *toAlias();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
#ifdef _DH
    Type *htype;
    Dsymbol *haliassym;
#endif

    void toDocBuffer(OutBuffer *buf);

    AliasDeclaration *isAliasDeclaration() { return this; }
};

/**************************************************************/

struct VarDeclaration : Declaration
{
    Initializer *init;
    unsigned offset;
    int noauto;			// no auto semantics
    FuncDeclarations nestedrefs; // referenced by these lexically nested functions
    int ctorinit;		// it has been initialized in a ctor
    int onstack;		// 1: it has been allocated on the stack
				// 2: on stack, run destructor anyway
    int canassign;		// it can be assigned to
    Dsymbol *aliassym;		// if redone as alias to another symbol
    Expression *value;		// when interpreting, this is the value
				// (NULL if value not determinable)

    VarDeclaration(Loc loc, Type *t, Identifier *id, Initializer *init);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    void semantic2(Scope *sc);
    const char *kind();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
#ifdef _DH
    Type *htype;
    Initializer *hinit;
#endif
    int needThis();
    int isImportedSymbol();
    int isDataseg();
    int isThreadlocal();
    int hasPointers();
    int canTakeAddressOf();
    int needsAutoDtor();
    Expression *callAutoDtor(Scope *sc);
    ExpInitializer *getExpInitializer();
    Expression *getConstInitializer();
    void checkCtorConstInit();
    void checkNestedReference(Scope *sc, Loc loc);
    Dsymbol *toAlias();

    Symbol *toSymbol();
    void toObjFile(int multiobj);			// compile to .obj file
    int cvMember(unsigned char *p);

    // Eliminate need for dynamic_cast
    VarDeclaration *isVarDeclaration() { return (VarDeclaration *)this; }
};

/**************************************************************/

// This is a shell around a back end symbol

struct SymbolDeclaration : Declaration
{
    Symbol *sym;
    StructDeclaration *dsym;

    SymbolDeclaration(Loc loc, Symbol *s, StructDeclaration *dsym);

    Symbol *toSymbol();

    // Eliminate need for dynamic_cast
    SymbolDeclaration *isSymbolDeclaration() { return (SymbolDeclaration *)this; }
};

struct ClassInfoDeclaration : VarDeclaration
{
    ClassDeclaration *cd;

    ClassInfoDeclaration(ClassDeclaration *cd);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);

    void emitComment(Scope *sc);

    Symbol *toSymbol();
};

struct ModuleInfoDeclaration : VarDeclaration
{
    Module *mod;

    ModuleInfoDeclaration(Module *mod);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);

    void emitComment(Scope *sc);

    Symbol *toSymbol();
};

struct TypeInfoDeclaration : VarDeclaration
{
    Type *tinfo;

    TypeInfoDeclaration(Type *tinfo, int internal);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);

    void emitComment(Scope *sc);

    Symbol *toSymbol();
    void toObjFile(int multiobj);			// compile to .obj file
    virtual void toDt(dt_t **pdt);
};

struct TypeInfoStructDeclaration : TypeInfoDeclaration
{
    TypeInfoStructDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

struct TypeInfoClassDeclaration : TypeInfoDeclaration
{
    TypeInfoClassDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

struct TypeInfoInterfaceDeclaration : TypeInfoDeclaration
{
    TypeInfoInterfaceDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

struct TypeInfoTypedefDeclaration : TypeInfoDeclaration
{
    TypeInfoTypedefDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

struct TypeInfoPointerDeclaration : TypeInfoDeclaration
{
    TypeInfoPointerDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

struct TypeInfoArrayDeclaration : TypeInfoDeclaration
{
    TypeInfoArrayDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

struct TypeInfoStaticArrayDeclaration : TypeInfoDeclaration
{
    TypeInfoStaticArrayDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

struct TypeInfoAssociativeArrayDeclaration : TypeInfoDeclaration
{
    TypeInfoAssociativeArrayDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

struct TypeInfoEnumDeclaration : TypeInfoDeclaration
{
    TypeInfoEnumDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

struct TypeInfoFunctionDeclaration : TypeInfoDeclaration
{
    TypeInfoFunctionDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

struct TypeInfoDelegateDeclaration : TypeInfoDeclaration
{
    TypeInfoDelegateDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

struct TypeInfoTupleDeclaration : TypeInfoDeclaration
{
    TypeInfoTupleDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

#if DMDV2
struct TypeInfoConstDeclaration : TypeInfoDeclaration
{
    TypeInfoConstDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

struct TypeInfoInvariantDeclaration : TypeInfoDeclaration
{
    TypeInfoInvariantDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};

struct TypeInfoSharedDeclaration : TypeInfoDeclaration
{
    TypeInfoSharedDeclaration(Type *tinfo);

    void toDt(dt_t **pdt);
};
#endif

/**************************************************************/

struct ThisDeclaration : VarDeclaration
{
    ThisDeclaration(Loc loc, Type *t);
    Dsymbol *syntaxCopy(Dsymbol *);
    ThisDeclaration *isThisDeclaration() { return this; }
};

enum ILS
{
    ILSuninitialized,	// not computed yet
    ILSno,		// cannot inline
    ILSyes,		// can inline
};

/**************************************************************/
#if DMDV2

enum BUILTIN
{
    BUILTINunknown = -1,	// not known if this is a builtin
    BUILTINnot,			// this is not a builtin
    BUILTINsin,			// std.math.sin
    BUILTINcos,			// std.math.cos
    BUILTINtan,			// std.math.tan
    BUILTINsqrt,		// std.math.sqrt
    BUILTINfabs,		// std.math.fabs
};

Expression *eval_builtin(enum BUILTIN builtin, Expressions *arguments);

#endif

struct FuncDeclaration : Declaration
{
    Array *fthrows;			// Array of Type's of exceptions (not used)
    Statement *frequire;
    Statement *fensure;
    Statement *fbody;

    Identifier *outId;			// identifier for out statement
    VarDeclaration *vresult;		// variable corresponding to outId
    LabelDsymbol *returnLabel;		// where the return goes

    DsymbolTable *localsymtab;		// used to prevent symbols in different
					// scopes from having the same name
    VarDeclaration *vthis;		// 'this' parameter (member and nested)
    VarDeclaration *v_arguments;	// '_arguments' parameter
#if IN_GCC
    VarDeclaration *v_argptr;	        // '_argptr' variable
#endif
    Dsymbols *parameters;		// Array of VarDeclaration's for parameters
    DsymbolTable *labtab;		// statement label symbol table
    Declaration *overnext;		// next in overload list
    Loc endloc;				// location of closing curly bracket
    int vtblIndex;			// for member functions, index into vtbl[]
    int naked;				// !=0 if naked
    int inlineAsm;			// !=0 if has inline assembler
    ILS inlineStatus;
    int inlineNest;			// !=0 if nested inline
    int cantInterpret;			// !=0 if cannot interpret function
    int semanticRun;			// 1 semantic() run
					// 2 semantic2() run
					// 3 semantic3() started
					// 4 semantic3() done
					// 5 toObjFile() run
					// this function's frame ptr
    ForeachStatement *fes;		// if foreach body, this is the foreach
    int introducing;			// !=0 if 'introducing' function
    Type *tintro;			// if !=NULL, then this is the type
					// of the 'introducing' function
					// this one is overriding
    int inferRetType;			// !=0 if return type is to be inferred

    // Things that should really go into Scope
    int hasReturnExp;			// 1 if there's a return exp; statement
					// 2 if there's a throw statement
					// 4 if there's an assert(0)
					// 8 if there's inline asm

    // Support for NRVO (named return value optimization)
    int nrvo_can;			// !=0 means we can do it
    VarDeclaration *nrvo_var;		// variable to replace with shidden
    Symbol *shidden;			// hidden pointer passed to function

#if DMDV2
    enum BUILTIN builtin;		// set if this is a known, builtin
					// function we can evaluate at compile
					// time

    int tookAddressOf;			// set if someone took the address of
					// this function
    Dsymbols closureVars;		// local variables in this function
					// which are referenced by nested
					// functions
#else
    int nestedFrameRef;			// !=0 if nested variables referenced
#endif

    FuncDeclaration(Loc loc, Loc endloc, Identifier *id, enum STC storage_class, Type *type);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    void semantic2(Scope *sc);
    void semantic3(Scope *sc);
    // called from semantic3
    void varArgs(Scope *sc, TypeFunction*, VarDeclaration *&, VarDeclaration *&);

    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void bodyToCBuffer(OutBuffer *buf, HdrGenState *hgs);
    int overrides(FuncDeclaration *fd);
    int findVtblIndex(Array *vtbl, int dim);
    int overloadInsert(Dsymbol *s);
    FuncDeclaration *overloadExactMatch(Type *t);
    FuncDeclaration *overloadResolve(Loc loc, Expression *ethis, Expressions *arguments, int flags = 0);
    MATCH leastAsSpecialized(FuncDeclaration *g);
    LabelDsymbol *searchLabel(Identifier *ident);
    AggregateDeclaration *isThis();
    AggregateDeclaration *isMember2();
    int getLevel(Loc loc, FuncDeclaration *fd);	// lexical nesting level difference
    void appendExp(Expression *e);
    void appendState(Statement *s);
    char *mangle();
    int isMain();
    int isWinMain();
    int isDllMain();
    enum BUILTIN isBuiltin();
    int isExport();
    int isImportedSymbol();
    int isAbstract();
    int isCodeseg();
    int isOverloadable();
    int isPure();
    virtual int isNested();
    int needThis();
    virtual int isVirtual();
    virtual int isFinal();
    virtual int addPreInvariant();
    virtual int addPostInvariant();
    Expression *interpret(InterState *istate, Expressions *arguments);
    void inlineScan();
    int canInline(int hasthis, int hdrscan = 0);
    Expression *doInline(InlineScanState *iss, Expression *ethis, Array *arguments);
    const char *kind();
    void toDocBuffer(OutBuffer *buf);
    FuncDeclaration *isUnique();
    int needsClosure();

    static FuncDeclaration *genCfunc(Type *treturn, const char *name);
    static FuncDeclaration *genCfunc(Type *treturn, Identifier *id);

    Symbol *toSymbol();
    Symbol *toThunkSymbol(int offset);	// thunk version
    void toObjFile(int multiobj);			// compile to .obj file
    int cvMember(unsigned char *p);
    void buildClosure(IRState *irs);

    FuncDeclaration *isFuncDeclaration() { return this; }
};

FuncDeclaration *resolveFuncCall(Scope *sc, Loc loc, Dsymbol *s,
	Objects *tiargs,
	Expression *ethis,
	Expressions *arguments,
	int flags);


struct FuncAliasDeclaration : FuncDeclaration
{
    FuncDeclaration *funcalias;

    FuncAliasDeclaration(FuncDeclaration *funcalias);

    FuncAliasDeclaration *isFuncAliasDeclaration() { return this; }
    const char *kind();
    Symbol *toSymbol();
};

struct FuncLiteralDeclaration : FuncDeclaration
{
    enum TOK tok;			// TOKfunction or TOKdelegate

    FuncLiteralDeclaration(Loc loc, Loc endloc, Type *type, enum TOK tok,
	ForeachStatement *fes);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Dsymbol *syntaxCopy(Dsymbol *);
    int isNested();
    int isVirtual();

    FuncLiteralDeclaration *isFuncLiteralDeclaration() { return this; }
    const char *kind();
};

struct CtorDeclaration : FuncDeclaration
{   Arguments *arguments;
    int varargs;

    CtorDeclaration(Loc loc, Loc endloc, Arguments *arguments, int varargs);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    const char *kind();
    char *toChars();
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
    void toDocBuffer(OutBuffer *buf);

    CtorDeclaration *isCtorDeclaration() { return this; }
};

#if DMDV2
struct PostBlitDeclaration : FuncDeclaration
{
    PostBlitDeclaration(Loc loc, Loc endloc);
    PostBlitDeclaration(Loc loc, Loc endloc, Identifier *id);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
    int overloadInsert(Dsymbol *s);
    void emitComment(Scope *sc);

    PostBlitDeclaration *isPostBlitDeclaration() { return this; }
};
#endif

struct DtorDeclaration : FuncDeclaration
{
    DtorDeclaration(Loc loc, Loc endloc);
    DtorDeclaration(Loc loc, Loc endloc, Identifier *id);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    const char *kind();
    char *toChars();
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
    int overloadInsert(Dsymbol *s);
    void emitComment(Scope *sc);

    DtorDeclaration *isDtorDeclaration() { return this; }
};

struct StaticCtorDeclaration : FuncDeclaration
{
    StaticCtorDeclaration(Loc loc, Loc endloc);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    AggregateDeclaration *isThis();
    int isStaticConstructor();
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
    void emitComment(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    StaticCtorDeclaration *isStaticCtorDeclaration() { return this; }
};

struct StaticDtorDeclaration : FuncDeclaration
{   VarDeclaration *vgate;	// 'gate' variable

    StaticDtorDeclaration(Loc loc, Loc endloc);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    AggregateDeclaration *isThis();
    int isStaticDestructor();
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
    void emitComment(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    StaticDtorDeclaration *isStaticDtorDeclaration() { return this; }
};

struct InvariantDeclaration : FuncDeclaration
{
    InvariantDeclaration(Loc loc, Loc endloc);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
    void emitComment(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    InvariantDeclaration *isInvariantDeclaration() { return this; }
};


struct UnitTestDeclaration : FuncDeclaration
{
    UnitTestDeclaration(Loc loc, Loc endloc);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    AggregateDeclaration *isThis();
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    UnitTestDeclaration *isUnitTestDeclaration() { return this; }
};

struct NewDeclaration : FuncDeclaration
{   Arguments *arguments;
    int varargs;

    NewDeclaration(Loc loc, Loc endloc, Arguments *arguments, int varargs);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    const char *kind();
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();

    NewDeclaration *isNewDeclaration() { return this; }
};


struct DeleteDeclaration : FuncDeclaration
{   Arguments *arguments;

    DeleteDeclaration(Loc loc, Loc endloc, Arguments *arguments);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    const char *kind();
    int isDelete();
    int isVirtual();
    int addPreInvariant();
    int addPostInvariant();
#ifdef _DH
    DeleteDeclaration *isDeleteDeclaration() { return this; }
#endif
};



* How a statement exits; this is returned by blockExit()
 */
enum BE
{
    BEnone =	 0,
    BEfallthru = 1,
    BEthrow =    2,
    BEreturn =   4,
    BEgoto =     8,
    BEhalt =	 0x10,
    BEbreak =	 0x20,
    BEcontinue = 0x40,
    BEany = (BEfallthru | BEthrow | BEreturn | BEgoto | BEhalt),
};

struct Statement : Object
{
    Loc loc;

    Statement(Loc loc);
    virtual Statement *syntaxCopy();

    void print();
    char *toChars();

    void error(const char *format, ...);
    void warning(const char *format, ...);
    virtual void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    virtual TryCatchStatement *isTryCatchStatement() { return NULL; }
    virtual GotoStatement *isGotoStatement() { return NULL; }
    virtual AsmStatement *isAsmStatement() { return NULL; }
#ifdef _DH
    int incontract;
#endif
    virtual ScopeStatement *isScopeStatement() { return NULL; }
    virtual Statement *semantic(Scope *sc);
    Statement *semanticScope(Scope *sc, Statement *sbreak, Statement *scontinue);
    virtual int hasBreak();
    virtual int hasContinue();
    virtual int usesEH();
    virtual int blockExit();
    virtual int comeFrom();
    virtual int isEmpty();
    virtual void scopeCode(Scope *sc, Statement **sentry, Statement **sexit, Statement **sfinally);
    virtual Statements *flatten(Scope *sc);
    virtual Expression *interpret(InterState *istate);

    virtual int inlineCost(InlineCostState *ics);
    virtual Expression *doInline(InlineDoState *ids);
    virtual Statement *inlineScan(InlineScanState *iss);

    // Back end
    virtual void toIR(IRState *irs);

    // Avoid dynamic_cast
    virtual DeclarationStatement *isDeclarationStatement() { return NULL; }
    virtual CompoundStatement *isCompoundStatement() { return NULL; }
    virtual ReturnStatement *isReturnStatement() { return NULL; }
    virtual IfStatement *isIfStatement() { return NULL; }
};

struct ExpStatement : Statement
{
    Expression *exp;

    ExpStatement(Loc loc, Expression *exp);
    Statement *syntaxCopy();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Statement *semantic(Scope *sc);
    Expression *interpret(InterState *istate);
    int blockExit();

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct CompileStatement : Statement
{
    Expression *exp;

    CompileStatement(Loc loc, Expression *exp);
    Statement *syntaxCopy();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Statements *flatten(Scope *sc);
    Statement *semantic(Scope *sc);
};

struct DeclarationStatement : ExpStatement
{
    // Doing declarations as an expression, rather than a statement,
    // makes inlining functions much easier.

    DeclarationStatement(Loc loc, Dsymbol *s);
    DeclarationStatement(Loc loc, Expression *exp);
    Statement *syntaxCopy();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    void scopeCode(Scope *sc, Statement **sentry, Statement **sexit, Statement **sfinally);

    DeclarationStatement *isDeclarationStatement() { return this; }
};

struct CompoundStatement : Statement
{
    Statements *statements;

    CompoundStatement(Loc loc, Statements *s);
    CompoundStatement(Loc loc, Statement *s1, Statement *s2);
    Statement *syntaxCopy();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Statement *semantic(Scope *sc);
    int usesEH();
    int blockExit();
    int comeFrom();
    int isEmpty();
    Statements *flatten(Scope *sc);
    ReturnStatement *isReturnStatement();
    Expression *interpret(InterState *istate);

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);

    CompoundStatement *isCompoundStatement() { return this; }
};

struct CompoundDeclarationStatement : CompoundStatement
{
    CompoundDeclarationStatement(Loc loc, Statements *s);
    Statement *syntaxCopy();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

/* The purpose of this is so that continue will go to the next
 * of the statements, and break will go to the end of the statements.
 */
struct UnrolledLoopStatement : Statement
{
    Statements *statements;

    UnrolledLoopStatement(Loc loc, Statements *statements);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit();
    int comeFrom();
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct ScopeStatement : Statement
{
    Statement *statement;

    ScopeStatement(Loc loc, Statement *s);
    Statement *syntaxCopy();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    ScopeStatement *isScopeStatement() { return this; }
    Statement *semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit();
    int comeFrom();
    int isEmpty();
    Expression *interpret(InterState *istate);

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct WhileStatement : Statement
{
    Expression *condition;
    Statement *body;

    WhileStatement(Loc loc, Expression *c, Statement *b);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit();
    int comeFrom();
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct DoStatement : Statement
{
    Statement *body;
    Expression *condition;

    DoStatement(Loc loc, Statement *b, Expression *c);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit();
    int comeFrom();
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct ForStatement : Statement
{
    Statement *init;
    Expression *condition;
    Expression *increment;
    Statement *body;

    ForStatement(Loc loc, Statement *init, Expression *condition, Expression *increment, Statement *body);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    void scopeCode(Scope *sc, Statement **sentry, Statement **sexit, Statement **sfinally);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit();
    int comeFrom();
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct ForeachStatement : Statement
{
    enum TOK op;		// TOKforeach or TOKforeach_reverse
    Arguments *arguments;	// array of Argument*'s
    Expression *aggr;
    Statement *body;

    VarDeclaration *key;
    VarDeclaration *value;

    FuncDeclaration *func;	// function we're lexically in

    Array cases;	// put breaks, continues, gotos and returns here
    Array gotos;	// forward referenced goto's go here

    ForeachStatement(Loc loc, enum TOK op, Arguments *arguments, Expression *aggr, Statement *body);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    bool checkForArgTypes();
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit();
    int comeFrom();
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

#if DMDV2
struct ForeachRangeStatement : Statement
{
    enum TOK op;		// TOKforeach or TOKforeach_reverse
    Argument *arg;		// loop index variable
    Expression *lwr;
    Expression *upr;
    Statement *body;

    VarDeclaration *key;

    ForeachRangeStatement(Loc loc, enum TOK op, Argument *arg,
	Expression *lwr, Expression *upr, Statement *body);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit();
    int comeFrom();
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};
#endif

struct IfStatement : Statement
{
    Argument *arg;
    Expression *condition;
    Statement *ifbody;
    Statement *elsebody;

    VarDeclaration *match;	// for MatchExpression results

    IfStatement(Loc loc, Argument *arg, Expression *condition, Statement *ifbody, Statement *elsebody);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    int usesEH();
    int blockExit();
    IfStatement *isIfStatement() { return this; }

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct ConditionalStatement : Statement
{
    Condition *condition;
    Statement *ifbody;
    Statement *elsebody;

    ConditionalStatement(Loc loc, Condition *condition, Statement *ifbody, Statement *elsebody);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    Statements *flatten(Scope *sc);
    int usesEH();
    int blockExit();

    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct PragmaStatement : Statement
{
    Identifier *ident;
    Expressions *args;		// array of Expression's
    Statement *body;

    PragmaStatement(Loc loc, Identifier *ident, Expressions *args, Statement *body);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    int usesEH();
    int blockExit();

    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    void toIR(IRState *irs);
};

struct StaticAssertStatement : Statement
{
    StaticAssert *sa;

    StaticAssertStatement(StaticAssert *sa);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);

    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct SwitchStatement : Statement
{
    Expression *condition;
    Statement *body;
    bool isFinal;

    DefaultStatement *sdefault;
    TryFinallyStatement *tf;
    Array gotoCases;		// array of unresolved GotoCaseStatement's
    Array *cases;		// array of CaseStatement's
    int hasNoDefault;		// !=0 if no default statement
    int hasVars;		// !=0 if has variable case values

    SwitchStatement(Loc loc, Expression *c, Statement *b, bool isFinal);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    int hasBreak();
    int usesEH();
    int blockExit();
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct CaseStatement : Statement
{
    Expression *exp;
    Statement *statement;

    int index;		// which case it is (since we sort this)
    block *cblock;	// back end: label for the block

    CaseStatement(Loc loc, Expression *exp, Statement *s);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    int compare(Object *obj);
    int usesEH();
    int blockExit();
    int comeFrom();
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

#if DMDV2

struct CaseRangeStatement : Statement
{
    Expression *first;
    Expression *last;
    Statement *statement;

    CaseRangeStatement(Loc loc, Expression *first, Expression *last, Statement *s);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

#endif

struct DefaultStatement : Statement
{
    Statement *statement;
#if IN_GCC
    block *cblock;	// back end: label for the block
#endif

    DefaultStatement(Loc loc, Statement *s);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    int usesEH();
    int blockExit();
    int comeFrom();
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct GotoDefaultStatement : Statement
{
    SwitchStatement *sw;

    GotoDefaultStatement(Loc loc);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    Expression *interpret(InterState *istate);
    int blockExit();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    void toIR(IRState *irs);
};

struct GotoCaseStatement : Statement
{
    Expression *exp;		// NULL, or which case to goto
    CaseStatement *cs;		// case statement it resolves to

    GotoCaseStatement(Loc loc, Expression *exp);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    Expression *interpret(InterState *istate);
    int blockExit();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    void toIR(IRState *irs);
};

struct SwitchErrorStatement : Statement
{
    SwitchErrorStatement(Loc loc);
    int blockExit();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    void toIR(IRState *irs);
};

struct ReturnStatement : Statement
{
    Expression *exp;

    ReturnStatement(Loc loc, Expression *exp);
    Statement *syntaxCopy();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Statement *semantic(Scope *sc);
    int blockExit();
    Expression *interpret(InterState *istate);

    int inlineCost(InlineCostState *ics);
    Expression *doInline(InlineDoState *ids);
    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);

    ReturnStatement *isReturnStatement() { return this; }
};

struct BreakStatement : Statement
{
    Identifier *ident;

    BreakStatement(Loc loc, Identifier *ident);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    Expression *interpret(InterState *istate);
    int blockExit();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    void toIR(IRState *irs);
};

struct ContinueStatement : Statement
{
    Identifier *ident;

    ContinueStatement(Loc loc, Identifier *ident);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    Expression *interpret(InterState *istate);
    int blockExit();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    void toIR(IRState *irs);
};

struct SynchronizedStatement : Statement
{
    Expression *exp;
    Statement *body;

    SynchronizedStatement(Loc loc, Expression *exp, Statement *body);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    Statement *inlineScan(InlineScanState *iss);

// Back end
    elem *esync;
    SynchronizedStatement(Loc loc, elem *esync, Statement *body);
    void toIR(IRState *irs);
};

struct WithStatement : Statement
{
    Expression *exp;
    Statement *body;
    VarDeclaration *wthis;

    WithStatement(Loc loc, Expression *exp, Statement *body);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    int usesEH();
    int blockExit();

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct TryCatchStatement : Statement
{
    Statement *body;
    Array *catches;

    TryCatchStatement(Loc loc, Statement *body, Array *catches);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    int hasBreak();
    int usesEH();
    int blockExit();

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    TryCatchStatement *isTryCatchStatement() { return this; }
};

struct Catch : Object
{
    Loc loc;
    Type *type;
    Identifier *ident;
    VarDeclaration *var;
    Statement *handler;

    Catch(Loc loc, Type *t, Identifier *id, Statement *handler);
    Catch *syntaxCopy();
    void semantic(Scope *sc);
    int blockExit();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct TryFinallyStatement : Statement
{
    Statement *body;
    Statement *finalbody;

    TryFinallyStatement(Loc loc, Statement *body, Statement *finalbody);
    Statement *syntaxCopy();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Statement *semantic(Scope *sc);
    int hasBreak();
    int hasContinue();
    int usesEH();
    int blockExit();

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct OnScopeStatement : Statement
{
    TOK tok;
    Statement *statement;

    OnScopeStatement(Loc loc, TOK tok, Statement *statement);
    Statement *syntaxCopy();
    int blockExit();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Statement *semantic(Scope *sc);
    int usesEH();
    void scopeCode(Scope *sc, Statement **sentry, Statement **sexit, Statement **sfinally);

    void toIR(IRState *irs);
};

struct ThrowStatement : Statement
{
    Expression *exp;

    ThrowStatement(Loc loc, Expression *exp);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    int blockExit();

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct VolatileStatement : Statement
{
    Statement *statement;

    VolatileStatement(Loc loc, Statement *statement);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    Statements *flatten(Scope *sc);
    int blockExit();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct GotoStatement : Statement
{
    Identifier *ident;
    LabelDsymbol *label;
    TryFinallyStatement *tf;

    GotoStatement(Loc loc, Identifier *ident);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    int blockExit();
    Expression *interpret(InterState *istate);

    void toIR(IRState *irs);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    GotoStatement *isGotoStatement() { return this; }
};

struct LabelStatement : Statement
{
    Identifier *ident;
    Statement *statement;
    TryFinallyStatement *tf;
    block *lblock;		// back end
    int isReturnLabel;

    LabelStatement(Loc loc, Identifier *ident, Statement *statement);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    Statements *flatten(Scope *sc);
    int usesEH();
    int blockExit();
    int comeFrom();
    Expression *interpret(InterState *istate);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    Statement *inlineScan(InlineScanState *iss);

    void toIR(IRState *irs);
};

struct LabelDsymbol : Dsymbol
{
    LabelStatement *statement;
#if IN_GCC
    unsigned asmLabelNum;       // GCC-specific
#endif

    LabelDsymbol(Identifier *ident);
    LabelDsymbol *isLabel();
};

struct AsmStatement : Statement
{
    Token *tokens;
    code *asmcode;
    unsigned asmalign;		// alignment of this statement
    unsigned refparam;		// !=0 if function parameter is referenced
    unsigned naked;		// !=0 if function is to be naked
    unsigned regs;		// mask of registers modified

    AsmStatement(Loc loc, Token *tokens);
    Statement *syntaxCopy();
    Statement *semantic(Scope *sc);
    int blockExit();
    int comeFrom();

    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    virtual AsmStatement *isAsmStatement() { return this; }

    void toIR(IRState *irs);
};

struct Scope
{
    Scope *enclosing;		// enclosing Scope

    Module *module;		// Root module
    ScopeDsymbol *scopesym;	// current symbol
    ScopeDsymbol *sd;		// if in static if, and declaring new symbols,
				// sd gets the addMember()
    FuncDeclaration *func;	// function we are in
    Dsymbol *parent;		// parent to use
    LabelStatement *slabel;	// enclosing labelled statement
    SwitchStatement *sw;	// enclosing switch statement
    TryFinallyStatement *tf;	// enclosing try finally statement
    TemplateInstance *tinst;    // enclosing template instance
    Statement *sbreak;		// enclosing statement that supports "break"
    Statement *scontinue;	// enclosing statement that supports "continue"
    ForeachStatement *fes;	// if nested function for ForeachStatement, this is it
    unsigned offset;		// next offset to use in aggregate
    int inunion;		// we're processing members of a union
    int incontract;		// we're inside contract code
    int nofree;			// set if shouldn't free it
    int noctor;			// set if constructor calls aren't allowed
    int intypeof;		// in typeof(exp)
    int parameterSpecialization; // if in template parameter specialization
    int noaccesscheck;		// don't do access checks
    int mustsemantic;		// cannot defer semantic()

    unsigned callSuper;		// primitive flow analysis for constructors
#define	CSXthis_ctor	1	// called this()
#define CSXsuper_ctor	2	// called super()
#define CSXthis		4	// referenced this
#define CSXsuper	8	// referenced super
#define CSXlabel	0x10	// seen a label
#define CSXreturn	0x20	// seen a return statement
#define CSXany_ctor	0x40	// either this() or super() was called

    unsigned structalign;	// alignment for struct members
    enum LINK linkage;		// linkage for external functions

    enum PROT protection;	// protection for class members
    int explicitProtection;	// set if in an explicit protection attribute

    unsigned stc;		// storage class

    unsigned flags;
#define SCOPEctor	1	// constructor type
#define SCOPEstaticif	2	// inside static if
#define SCOPEfree	4	// is on free list

    AnonymousAggregateDeclaration *anonAgg;	// for temporary analysis

    DocComment *lastdc;		// documentation comment for last symbol at this scope
    unsigned lastoffset;	// offset in docbuf of where to insert next dec
    OutBuffer *docbuf;		// buffer for documentation output

    static Scope *freelist;
    static void *operator new(size_t sz);
    static Scope *createGlobal(Module *module);

    Scope();
    Scope(Module *module);
    Scope(Scope *enclosing);

    Scope *push();
    Scope *push(ScopeDsymbol *ss);
    Scope *pop();

    void mergeCallSuper(Loc loc, unsigned cs);

    Dsymbol *search(Loc loc, Identifier *ident, Dsymbol **pscopesym);
    Dsymbol *insert(Dsymbol *s);

    ClassDeclaration *getClassScope();
    AggregateDeclaration *getStructClassScope();
    void setNoFree();
};


struct Import : Dsymbol
{
    Array *packages;		// array of Identifier's representing packages
    Identifier *id;		// module Identifier
    Identifier *aliasId;
    int isstatic;		// !=0 if static import

    // Pairs of alias=name to bind into current namespace
    Array names;
    Array aliases;

    Array aliasdecls;		// AliasDeclarations for names/aliases

    Module *mod;
    Package *pkg;		// leftmost package/module

    Import(Loc loc, Array *packages, Identifier *id, Identifier *aliasId,
	int isstatic);
    void addAlias(Identifier *name, Identifier *alias);

    const char *kind();
    Dsymbol *syntaxCopy(Dsymbol *s);	// copy only syntax trees
    void load(Scope *sc);
    void semantic(Scope *sc);
    void semantic2(Scope *sc);
    Dsymbol *toAlias();
    int addMember(Scope *sc, ScopeDsymbol *s, int memnum);
    Dsymbol *search(Loc loc, Identifier *ident, int flags);
    int overloadInsert(Dsymbol *s);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    Import *isImport() { return this; }
};


struct Package : ScopeDsymbol
{
    Module* homonym;
    Package(Identifier *ident);
    const char *kind();

    static DsymbolTable *resolve(Array *packages, Dsymbol **pparent, Package **ppkg);

    Package *isPackage() { return this; }

    virtual void semantic(Scope *sc) { }
    virtual Dsymbol *search(Loc loc, Identifier *ident, int flags);
};

struct Module : Package
{
    static Module *rootModule;
    static DsymbolTable *modules;	// symbol table of all modules
    static Array amodules;		// array of all modules
    static Array deferred;	// deferred Dsymbol's needing semantic() run on them
    static unsigned dprogress;	// progress resolving the deferred list
    static void init();

    static ClassDeclaration *moduleinfo;


    const char *arg;	// original argument name
    ModuleDeclaration *md; // if !NULL, the contents of the ModuleDeclaration declaration
    File *srcfile;	// input source file
    File *objfile;	// output .obj file
    File *hdrfile;	// 'header' file
    File *symfile;	// output symbol file
    File *docfile;	// output documentation file
    unsigned errors;	// if any errors in file
    unsigned numlines;	// number of lines in source file
    int isHtml;		// if it is an HTML file
    int isDocFile;	// if it is a documentation input file, not D source
    int needmoduleinfo;
#ifdef IN_GCC
    int strictlyneedmoduleinfo;
#endif

    int selfimports;		// 0: don't know, 1: does not, 2: does
    int selfImports();		// returns !=0 if module imports itself

    int insearch;
    Identifier *searchCacheIdent;
    Dsymbol *searchCacheSymbol;	// cached value of search
    int searchCacheFlags;	// cached flags

    int semanticstarted;	// has semantic() been started?
    int semanticRun;		// has semantic() been done?
    int root;			// != 0 if this is a 'root' module,
				// i.e. a module that will be taken all the
				// way to an object file
    Module *importedFrom;	// module from command line we're imported from,
				// i.e. a module that will be taken all the
				// way to an object file

    Array *decldefs;		// top level declarations for this Module

    Array aimports;		// all imported modules

    ModuleInfoDeclaration *vmoduleinfo;

    unsigned debuglevel;	// debug level
    Array *debugids;		// debug identifiers
    Array *debugidsNot;		// forward referenced debug identifiers

    unsigned versionlevel;	// version level
    Array *versionids;		// version identifiers
    Array *versionidsNot;	// forward referenced version identifiers

    Macro *macrotable;		// document comment macros
    Escape *escapetable;	// document comment escapes
    bool safe;			// TRUE if module is marked as 'safe'

    Module(char *arg, Identifier *ident, int doDocComment, int doHdrGen);
    ~Module();

    static Module *load(Loc loc, Array *packages, Identifier *ident);

    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    const char *kind();
    void setDocfile();	// set docfile member
    void read(Loc loc);	// read file
#if IN_GCC
    void parse(bool dump_source = false);	// syntactic parse
#else
    void parse();	// syntactic parse
#endif
    void semantic();	// semantic analysis
    void semantic2();	// pass 2 semantic analysis
    void semantic3();	// pass 3 semantic analysis
    void inlineScan();	// scan for functions to inline
    void setHdrfile();	// set hdrfile member
#ifdef _DH
    void genhdrfile();  // generate D import file
#endif
    void genobjfile(int multiobj);
    void gensymfile();
    void gendocfile();
    int needModuleInfo();
    Dsymbol *search(Loc loc, Identifier *ident, int flags);
    void deleteObjFile();
    void addDeferredSemantic(Dsymbol *s);
    void runDeferredSemantic();
    int imports(Module *m);

    // Back end

    int doppelganger;		// sub-module
    Symbol *cov;		// private uint[] __coverage;
    unsigned *covb;		// bit array of valid code line numbers

    Symbol *sictor;		// module order independent constructor
    Symbol *sctor;		// module constructor
    Symbol *sdtor;		// module destructor
    Symbol *stest;		// module unit test

    Symbol *sfilename;		// symbol for filename

    Symbol *massert;		// module assert function
    Symbol *toModuleAssert();	// get module assert function

    Symbol *marray;		// module array bounds function
    Symbol *toModuleArray();	// get module array bounds function


    static Symbol *gencritsec();
    elem *toEfilename();
    elem *toEmodulename();

    Symbol *toSymbol();
    void genmoduleinfo();

    Module *isModule() { return this; }
};


struct ModuleDeclaration
{
    Identifier *id;
    Array *packages;		// array of Identifier's representing packages
    bool safe;

    ModuleDeclaration(Array *packages, Identifier *id, bool safe);

    char *toChars();
};


struct Id
{
    static Identifier *IUnknown;
    static Identifier *Object;
    static Identifier *object;
    static Identifier *max;
    static Identifier *min;
    static Identifier *This;
    static Identifier *ctor;
    static Identifier *dtor;
    static Identifier *cpctor;
    static Identifier *_postblit;
    static Identifier *classInvariant;
    static Identifier *unitTest;
    static Identifier *init;
    static Identifier *size;
    static Identifier *__sizeof;
    static Identifier *alignof;
    static Identifier *mangleof;
    static Identifier *stringof;
    static Identifier *tupleof;
    static Identifier *length;
    static Identifier *remove;
    static Identifier *ptr;
    static Identifier *funcptr;
    static Identifier *dollar;
    static Identifier *offset;
    static Identifier *offsetof;
    static Identifier *ModuleInfo;
    static Identifier *ClassInfo;
    static Identifier *classinfo;
    static Identifier *typeinfo;
    static Identifier *outer;
    static Identifier *Exception;
    static Identifier *Throwable;
    static Identifier *withSym;
    static Identifier *result;
    static Identifier *returnLabel;
    static Identifier *delegate;
    static Identifier *line;
    static Identifier *empty;
    static Identifier *p;
    static Identifier *coverage;
    static Identifier *__vptr;
    static Identifier *__monitor;
    static Identifier *system;
    static Identifier *TypeInfo;
    static Identifier *TypeInfo_Class;
    static Identifier *TypeInfo_Interface;
    static Identifier *TypeInfo_Struct;
    static Identifier *TypeInfo_Enum;
    static Identifier *TypeInfo_Typedef;
    static Identifier *TypeInfo_Pointer;
    static Identifier *TypeInfo_Array;
    static Identifier *TypeInfo_StaticArray;
    static Identifier *TypeInfo_AssociativeArray;
    static Identifier *TypeInfo_Function;
    static Identifier *TypeInfo_Delegate;
    static Identifier *TypeInfo_Tuple;
    static Identifier *TypeInfo_Const;
    static Identifier *TypeInfo_Invariant;
    static Identifier *TypeInfo_Shared;
    static Identifier *elements;
    static Identifier *_arguments_typeinfo;
    static Identifier *_arguments;
    static Identifier *_argptr;
    static Identifier *_match;
    static Identifier *destroy;
    static Identifier *postblit;
    static Identifier *LINE;
    static Identifier *FILE;
    static Identifier *DATE;
    static Identifier *TIME;
    static Identifier *TIMESTAMP;
    static Identifier *VENDOR;
    static Identifier *VERSIONX;
    static Identifier *EOFX;
    static Identifier *nan;
    static Identifier *infinity;
    static Identifier *dig;
    static Identifier *epsilon;
    static Identifier *mant_dig;
    static Identifier *max_10_exp;
    static Identifier *max_exp;
    static Identifier *min_10_exp;
    static Identifier *min_exp;
    static Identifier *re;
    static Identifier *im;
    static Identifier *C;
    static Identifier *D;
    static Identifier *Windows;
    static Identifier *Pascal;
    static Identifier *System;
    static Identifier *exit;
    static Identifier *success;
    static Identifier *failure;
    static Identifier *keys;
    static Identifier *values;
    static Identifier *rehash;
    static Identifier *sort;
    static Identifier *reverse;
    static Identifier *dup;
    static Identifier *idup;
    static Identifier *___out;
    static Identifier *___in;
    static Identifier *__int;
    static Identifier *__dollar;
    static Identifier *__LOCAL_SIZE;
    static Identifier *uadd;
    static Identifier *neg;
    static Identifier *com;
    static Identifier *add;
    static Identifier *add_r;
    static Identifier *sub;
    static Identifier *sub_r;
    static Identifier *mul;
    static Identifier *mul_r;
    static Identifier *div;
    static Identifier *div_r;
    static Identifier *mod;
    static Identifier *mod_r;
    static Identifier *eq;
    static Identifier *cmp;
    static Identifier *iand;
    static Identifier *iand_r;
    static Identifier *ior;
    static Identifier *ior_r;
    static Identifier *ixor;
    static Identifier *ixor_r;
    static Identifier *shl;
    static Identifier *shl_r;
    static Identifier *shr;
    static Identifier *shr_r;
    static Identifier *ushr;
    static Identifier *ushr_r;
    static Identifier *cat;
    static Identifier *cat_r;
    static Identifier *assign;
    static Identifier *addass;
    static Identifier *subass;
    static Identifier *mulass;
    static Identifier *divass;
    static Identifier *modass;
    static Identifier *andass;
    static Identifier *orass;
    static Identifier *xorass;
    static Identifier *shlass;
    static Identifier *shrass;
    static Identifier *ushrass;
    static Identifier *catass;
    static Identifier *postinc;
    static Identifier *postdec;
    static Identifier *index;
    static Identifier *indexass;
    static Identifier *slice;
    static Identifier *sliceass;
    static Identifier *call;
    static Identifier *cast;
    static Identifier *match;
    static Identifier *next;
    static Identifier *opIn;
    static Identifier *opIn_r;
    static Identifier *opStar;
    static Identifier *opDot;
    static Identifier *opImplicitCast;
    static Identifier *classNew;
    static Identifier *classDelete;
    static Identifier *apply;
    static Identifier *applyReverse;
    static Identifier *Fempty;
    static Identifier *Fhead;
    static Identifier *Ftoe;
    static Identifier *Fnext;
    static Identifier *Fretreat;
    static Identifier *adDup;
    static Identifier *adReverse;
    static Identifier *aaLen;
    static Identifier *aaKeys;
    static Identifier *aaValues;
    static Identifier *aaRehash;
    static Identifier *GNU_asm;
    static Identifier *lib;
    static Identifier *msg;
    static Identifier *startaddress;
    static Identifier *tohash;
    static Identifier *tostring;
    static Identifier *getmembers;
    static Identifier *alloca;
    static Identifier *main;
    static Identifier *WinMain;
    static Identifier *DllMain;
    static Identifier *tls_get_addr;
    static Identifier *std;
    static Identifier *math;
    static Identifier *sin;
    static Identifier *cos;
    static Identifier *tan;
    static Identifier *_sqrt;
    static Identifier *fabs;
    static Identifier *isAbstractClass;
    static Identifier *isArithmetic;
    static Identifier *isAssociativeArray;
    static Identifier *isFinalClass;
    static Identifier *isFloating;
    static Identifier *isIntegral;
    static Identifier *isScalar;
    static Identifier *isStaticArray;
    static Identifier *isUnsigned;
    static Identifier *isVirtualFunction;
    static Identifier *isAbstractFunction;
    static Identifier *isFinalFunction;
    static Identifier *hasMember;
    static Identifier *getMember;
    static Identifier *getVirtualFunctions;
    static Identifier *classInstanceSize;
    static Identifier *allMembers;
    static Identifier *derivedMembers;
    static Identifier *isSame;
    static Identifier *compiles;
    static void initialize();
};


struct Condition
{
    Loc loc;
    int inc;		// 0: not computed yet
			// 1: include
			// 2: do not include

    Condition(Loc loc);

    virtual Condition *syntaxCopy() = 0;
    virtual int include(Scope *sc, ScopeDsymbol *s) = 0;
    virtual void toCBuffer(OutBuffer *buf, HdrGenState *hgs) = 0;
};

struct DVCondition : Condition
{
    unsigned level;
    Identifier *ident;
    Module *mod;

    DVCondition(Module *mod, unsigned level, Identifier *ident);

    Condition *syntaxCopy();
};

struct DebugCondition : DVCondition
{
    static void setGlobalLevel(unsigned level);
    static void addGlobalIdent(const char *ident);
    static void addPredefinedGlobalIdent(const char *ident);

    DebugCondition(Module *mod, unsigned level, Identifier *ident);

    int include(Scope *sc, ScopeDsymbol *s);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct VersionCondition : DVCondition
{
    static void setGlobalLevel(unsigned level);
    static void checkPredefined(Loc loc, const char *ident);
    static void addGlobalIdent(const char *ident);
    static void addPredefinedGlobalIdent(const char *ident);

    VersionCondition(Module *mod, unsigned level, Identifier *ident);

    int include(Scope *sc, ScopeDsymbol *s);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct StaticIfCondition : Condition
{
    Expression *exp;

    StaticIfCondition(Loc loc, Expression *exp);
    Condition *syntaxCopy();
    int include(Scope *sc, ScopeDsymbol *s);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct IftypeCondition : Condition
{
    /* iftype (targ id tok tspec)
     */
    Type *targ;
    Identifier *id;	// can be NULL
    enum TOK tok;	// ':' or '=='
    Type *tspec;	// can be NULL

    IftypeCondition(Loc loc, Type *targ, Identifier *id, enum TOK tok, Type *tspec);
    Condition *syntaxCopy();
    int include(Scope *sc, ScopeDsymbol *s);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};

struct ObjModule;

struct ObjSymbol
{
    char *name;
    ObjModule *om;
};

struct Library
{
    File *libfile;
    Array objmodules;	// ObjModule[]
    Array objsymbols;	// ObjSymbol[]

    StringTable tab;

    Library();
    void setFilename(char *dir, char *filename);
    void addObject(const char *module_name, void *buf, size_t buflen);
    void addLibrary(void *buf, size_t buflen);
    void write();

  private:
    void addSymbol(ObjModule *om, char *name, int pickAny = 0);
    void scanObjModule(ObjModule *om);
    unsigned short numDictPages(unsigned padding);
    int FillDict(unsigned char *bucketsP, unsigned short uNumPages);
    void WriteLibToBuffer(OutBuffer *libbuf);
};

truct DebugSymbol : Dsymbol
{
    unsigned level;

    DebugSymbol(Loc loc, Identifier *ident);
    DebugSymbol(Loc loc, unsigned level);
    Dsymbol *syntaxCopy(Dsymbol *);

    int addMember(Scope *sc, ScopeDsymbol *s, int memnum);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    const char *kind();
};

struct VersionSymbol : Dsymbol
{
    unsigned level;

    VersionSymbol(Loc loc, Identifier *ident);
    VersionSymbol(Loc loc, unsigned level);
    Dsymbol *syntaxCopy(Dsymbol *);

    int addMember(Scope *sc, ScopeDsymbol *s, int memnum);
    void semantic(Scope *sc);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    const char *kind();
};

#if DMDV2

struct AliasThis : Dsymbol
{
   // alias Identifier this;
    Identifier *ident;

    AliasThis(Loc loc, Identifier *ident);

    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    const char *kind();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    AliasThis *isAliasThis() { return this; }
};

#endif


struct Tuple : Object
{
    Objects objects;

    int dyncast() { return DYNCAST_TUPLE; } // kludge for template.isType()
};


struct TemplateDeclaration : ScopeDsymbol
{
    TemplateParameters *parameters;     // array of TemplateParameter's

    TemplateParameters *origParameters; // originals for Ddoc
    Expression *constraint;
    Array instances;                    // array of TemplateInstance's

    TemplateDeclaration *overnext;      // next overloaded TemplateDeclaration
    TemplateDeclaration *overroot;      // first in overnext list

    int semanticRun;                    // 1 semantic() run

    Dsymbol *onemember;         // if !=NULL then one member of this template

    TemplateDeclaration(Loc loc, Identifier *id, TemplateParameters *parameters,
        Expression *constraint, Array *decldefs);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    int overloadInsert(Dsymbol *s);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    const char *kind();
    char *toChars();

    void emitComment(Scope *sc);
    void toJsonBuffer(OutBuffer *buf);
//    void toDocBuffer(OutBuffer *buf);

    MATCH matchWithInstance(TemplateInstance *ti, Objects *atypes, int flag);
    MATCH leastAsSpecialized(TemplateDeclaration *td2);

    MATCH deduceFunctionTemplateMatch(Loc loc, Objects *targsi, Expression *ethis, Expressions *fargs, Objects *dedargs);
    FuncDeclaration *deduceFunctionTemplate(Scope *sc, Loc loc, Objects *targsi, Expression *ethis, Expressions *fargs, int flags = 0);
    void declareParameter(Scope *sc, TemplateParameter *tp, Object *o);

    TemplateDeclaration *isTemplateDeclaration() { return this; }

    TemplateTupleParameter *isVariadic();
    int isOverloadable();

    void makeParamNamesVisibleInConstraint(Scope *paramscope);
};

struct TemplateParameter
{
    /* For type-parameter:
     *  template Foo(ident)             // specType is set to NULL
     *  template Foo(ident : specType)
     * For value-parameter:
     *  template Foo(valType ident)     // specValue is set to NULL
     *  template Foo(valType ident : specValue)
     * For alias-parameter:
     *  template Foo(alias ident)
     * For this-parameter:
     *  template Foo(this ident)
     */

    Loc loc;
    Identifier *ident;

    Declaration *sparam;

    TemplateParameter(Loc loc, Identifier *ident);

    virtual TemplateTypeParameter  *isTemplateTypeParameter();
    virtual TemplateValueParameter *isTemplateValueParameter();
    virtual TemplateAliasParameter *isTemplateAliasParameter();
#if DMDV2
    virtual TemplateThisParameter *isTemplateThisParameter();
#endif
    virtual TemplateTupleParameter *isTemplateTupleParameter();

    virtual TemplateParameter *syntaxCopy() = 0;
    virtual void declareParameter(Scope *sc) = 0;
    virtual void semantic(Scope *) = 0;
    virtual void print(Object *oarg, Object *oded) = 0;
    virtual void toCBuffer(OutBuffer *buf, HdrGenState *hgs) = 0;
    virtual Object *specialization() = 0;
    virtual Object *defaultArg(Loc loc, Scope *sc) = 0;

    /* If TemplateParameter's match as far as overloading goes.
     */
    virtual int overloadMatch(TemplateParameter *) = 0;

    /* Match actual argument against parameter.
     */
    virtual MATCH matchArg(Scope *sc, Objects *tiargs, int i, TemplateParameters *parameters, Objects *dedtypes, Declaration **psparam, int flags = 0) = 0;

    /* Create dummy argument based on parameter.
     */
    virtual void *dummyArg() = 0;
};

struct TemplateTypeParameter : TemplateParameter
{
    /* Syntax:
     *  ident : specType = defaultType
     */
    Type *specType;     // type parameter: if !=NULL, this is the type specialization
    Type *defaultType;

    TemplateTypeParameter(Loc loc, Identifier *ident, Type *specType, Type *defaultType);

    TemplateTypeParameter *isTemplateTypeParameter();
    TemplateParameter *syntaxCopy();
    void declareParameter(Scope *sc);
    void semantic(Scope *);
    void print(Object *oarg, Object *oded);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Object *specialization();
    Object *defaultArg(Loc loc, Scope *sc);
    int overloadMatch(TemplateParameter *);
    MATCH matchArg(Scope *sc, Objects *tiargs, int i, TemplateParameters *parameters, Objects *dedtypes, Declaration **psparam, int flags);
    void *dummyArg();
};

#if DMDV2
struct TemplateThisParameter : TemplateTypeParameter
{
    /* Syntax:
     *  this ident : specType = defaultType
     */
    Type *specType;     // type parameter: if !=NULL, this is the type specialization
    Type *defaultType;

    TemplateThisParameter(Loc loc, Identifier *ident, Type *specType, Type *defaultType);

    TemplateThisParameter *isTemplateThisParameter();
    TemplateParameter *syntaxCopy();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
};
#endif

struct TemplateValueParameter : TemplateParameter
{
    /* Syntax:
     *  valType ident : specValue = defaultValue
     */

    Type *valType;
    Expression *specValue;
    Expression *defaultValue;

    static Expression *edummy;

    TemplateValueParameter(Loc loc, Identifier *ident, Type *valType, Expression *specValue, Expression *defaultValue);

    TemplateValueParameter *isTemplateValueParameter();
    TemplateParameter *syntaxCopy();
    void declareParameter(Scope *sc);
    void semantic(Scope *);
    void print(Object *oarg, Object *oded);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Object *specialization();
    Object *defaultArg(Loc loc, Scope *sc);
    int overloadMatch(TemplateParameter *);
    MATCH matchArg(Scope *sc, Objects *tiargs, int i, TemplateParameters *parameters, Objects *dedtypes, Declaration **psparam, int flags);
    void *dummyArg();
};

struct TemplateAliasParameter : TemplateParameter
{
    /* Syntax:
     *  specType ident : specAlias = defaultAlias
     */

    Type *specAliasT;
    Dsymbol *specAlias;

    Type *defaultAlias;

    static Dsymbol *sdummy;

    TemplateAliasParameter(Loc loc, Identifier *ident, Type *specAliasT, Type *defaultAlias);

    TemplateAliasParameter *isTemplateAliasParameter();
    TemplateParameter *syntaxCopy();
    void declareParameter(Scope *sc);
    void semantic(Scope *);
    void print(Object *oarg, Object *oded);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Object *specialization();
    Object *defaultArg(Loc loc, Scope *sc);
    int overloadMatch(TemplateParameter *);
    MATCH matchArg(Scope *sc, Objects *tiargs, int i, TemplateParameters *parameters, Objects *dedtypes, Declaration **psparam, int flags);
    void *dummyArg();
};

struct TemplateTupleParameter : TemplateParameter
{
    /* Syntax:
     *  ident ...
     */

    TemplateTupleParameter(Loc loc, Identifier *ident);

    TemplateTupleParameter *isTemplateTupleParameter();
    TemplateParameter *syntaxCopy();
    void declareParameter(Scope *sc);
    void semantic(Scope *);
    void print(Object *oarg, Object *oded);
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Object *specialization();
    Object *defaultArg(Loc loc, Scope *sc);
    int overloadMatch(TemplateParameter *);
    MATCH matchArg(Scope *sc, Objects *tiargs, int i, TemplateParameters *parameters, Objects *dedtypes, Declaration **psparam, int flags);
    void *dummyArg();
};

struct TemplateInstance : ScopeDsymbol
{
    /* Given:
     *  foo!(args) =>
     *      name = foo
     *      tiargs = args
     */
    Identifier *name;
    //Array idents;
    Objects *tiargs;            // Array of Types/Expressions of template
                                // instance arguments [int*, char, 10*10]

    Objects tdtypes;            // Array of Types/Expressions corresponding
                                // to TemplateDeclaration.parameters
                                // [int, char, 100]

    TemplateDeclaration *tempdecl;      // referenced by foo.bar.abc
    TemplateInstance *inst;             // refer to existing instance
    TemplateInstance *tinst;            // enclosing template instance
    ScopeDsymbol *argsym;               // argument symbol table
    AliasDeclaration *aliasdecl;        // !=NULL if instance is an alias for its
                                        // sole member
    WithScopeSymbol *withsym;           // if a member of a with statement
    int semanticRun;    // has semantic() been done?
    int semantictiargsdone;     // has semanticTiargs() been done?
    int nest;           // for recursion detection
    int havetempdecl;   // 1 if used second constructor
    Dsymbol *isnested;  // if referencing local symbols, this is the context
    int errors;         // 1 if compiled with errors
#ifdef IN_GCC
    /* On some targets, it is necessary to know whether a symbol
       will be emitted in the output or not before the symbol
       is used.  This can be different from getModule(). */
    Module * objFileModule;
#endif

    TemplateInstance(Loc loc, Identifier *temp_id);
    TemplateInstance(Loc loc, TemplateDeclaration *tempdecl, Objects *tiargs);
    static Objects *arraySyntaxCopy(Objects *objs);
    Dsymbol *syntaxCopy(Dsymbol *);
    void semantic(Scope *sc);
    void semantic2(Scope *sc);
    void semantic3(Scope *sc);
    void inlineScan();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);
    Dsymbol *toAlias();                 // resolve real symbol
    const char *kind();
    int oneMember(Dsymbol **ps);
    int needsTypeInference(Scope *sc);
    char *toChars();
    char *mangle();
    void printInstantiationTrace();

    void toObjFile(int multiobj);                       // compile to .obj file

    // Internal
    static void semanticTiargs(Loc loc, Scope *sc, Objects *tiargs, int flags);
    void semanticTiargs(Scope *sc);
    TemplateDeclaration *findTemplateDeclaration(Scope *sc);
    TemplateDeclaration *findBestMatch(Scope *sc);
    void declareParameters(Scope *sc);
    int hasNestedArgs(Objects *tiargs);
    Identifier *genIdent();

    TemplateInstance *isTemplateInstance() { return this; }
    AliasDeclaration *isAliasDeclaration();
};

struct TemplateMixin : TemplateInstance
{
    Array *idents;
    Type *tqual;

    TemplateMixin(Loc loc, Identifier *ident, Type *tqual, Array *idents, Objects *tiargs);
    Dsymbol *syntaxCopy(Dsymbol *s);
    void semantic(Scope *sc);
    void semantic2(Scope *sc);
    void semantic3(Scope *sc);
    void inlineScan();
    const char *kind();
    int oneMember(Dsymbol **ps);
    int hasPointers();
    char *toChars();
    void toCBuffer(OutBuffer *buf, HdrGenState *hgs);

    void toObjFile(int multiobj);                       // compile to .obj file

    TemplateMixin *isTemplateMixin() { return this; }
};


struct complex_t
{
    long double re;
    long double im;    

    complex_t() { this->re = 0; this->im = 0; }
    complex_t(long double re) { this->re = re; this->im = 0; }
    complex_t(long double re, long double im) { this->re = re; this->im = im; }

    complex_t operator + (complex_t y) { complex_t r; r.re = re + y.re; r.im = im + y.im; return r; }
    complex_t operator - (complex_t y) { complex_t r; r.re = re - y.re; r.im = im - y.im; return r; }
    complex_t operator - () { complex_t r; r.re = -re; r.im = -im; return r; }
    complex_t operator * (complex_t y) { return complex_t(re * y.re - im * y.im, im * y.re + re * y.im); }
    
    complex_t operator / (complex_t y)
    {
	long double abs_y_re = y.re < 0 ? -y.re : y.re;
	long double abs_y_im = y.im < 0 ? -y.im : y.im;
	long double r, den;

	if (abs_y_re < abs_y_im)
	{
	    r = y.re / y.im;
	    den = y.im + r * y.re;
	    return complex_t((re * r + im) / den,
			     (im * r - re) / den);
	}
	else
	{
	    r = y.im / y.re;
	    den = y.re + r * y.im;
	    return complex_t((re + r * im) / den,
			     (im - r * re) / den);
	}
    }

    operator bool () { return re || im; }

    int operator == (complex_t y) { return re == y.re && im == y.im; }
    int operator != (complex_t y) { return re != y.re || im != y.im; }
};

inline complex_t operator * (long double x, complex_t y) { return complex_t(x) * y; }
inline complex_t operator * (complex_t x, long double y) { return x * complex_t(y); }
inline complex_t operator / (complex_t x, long double y) { return x / complex_t(y); }


inline long double creall(complex_t x)
{
    return x.re;
}

inline long double cimagl(complex_t x)
{
    return x.im;
}




///////////////////////////////////////

longlong randomx();
char *wchar2ascii(wchar_t *s, unsigned len);
int wcharIsAscii(wchar_t *s, unsigned len);
char *wchar2ascii(wchar_t *s);
int wcharIsAscii(wchar_t *s);

int bstrcmp(unsigned char *s1, unsigned char *s2);
char *bstr2str(unsigned char *b);
void error(const char *format, ...);
void error(const wchar_t *format, ...);
void warning(const char *format, ...);

void warning(Loc loc, const char *format, ...);
void error(Loc loc, const char *format, ...);
void error(Loc loc, const char *format, va_list);
void fatal();
void err_nomem();
int runLINK();
void deleteExeFile();
int runProgram();
void inifile(const char *argv0, const char *inifile);
void halt();
void util_progress();
void obj_start(char *srcfile);
void obj_end(Library *library, File *objfile);
void obj_append(Dsymbol *s);
void obj_write_deferred(Library *library);

void initPrecedence();

Expression *resolveProperties(Scope *sc, Expression *e);
void accessCheck(Loc loc, Scope *sc, Expression *e, Declaration *d);
Expression *build_overload(Loc loc, Scope *sc, Expression *ethis, Expression *earg, Identifier *id);
Dsymbol *search_function(ScopeDsymbol *ad, Identifier *funcid);
void inferApplyArgTypes(enum TOK op, Arguments *arguments, Expression *aggr);
void argExpTypesToCBuffer(OutBuffer *buf, Expressions *arguments, HdrGenState *hgs);
void argsToCBuffer(OutBuffer *buf, Expressions *arguments, HdrGenState *hgs);
void expandTuples(Expressions *exps);
FuncDeclaration *hasThis(Scope *sc);
Expression *fromConstInitializer(int result, Expression *e);
int arrayExpressionCanThrow(Expressions *exps);

/****************************************************************/

/* Special values used by the interpreter
 */
#define EXP_CANT_INTERPRET	((Expression *)1)
#define EXP_CONTINUE_INTERPRET	((Expression *)2)
#define EXP_BREAK_INTERPRET	((Expression *)3)
#define EXP_GOTO_INTERPRET	((Expression *)4)
#define EXP_VOID_INTERPRET	((Expression *)5)

Expression *expType(Type *type, Expression *e);

Expression *Neg(Type *type, Expression *e1);
Expression *Com(Type *type, Expression *e1);
Expression *Not(Type *type, Expression *e1);
Expression *Bool(Type *type, Expression *e1);
Expression *Cast(Type *type, Type *to, Expression *e1);
Expression *ArrayLength(Type *type, Expression *e1);
Expression *Ptr(Type *type, Expression *e1);

Expression *Add(Type *type, Expression *e1, Expression *e2);
Expression *Min(Type *type, Expression *e1, Expression *e2);
Expression *Mul(Type *type, Expression *e1, Expression *e2);
Expression *Div(Type *type, Expression *e1, Expression *e2);
Expression *Mod(Type *type, Expression *e1, Expression *e2);
Expression *Shl(Type *type, Expression *e1, Expression *e2);
Expression *Shr(Type *type, Expression *e1, Expression *e2);
Expression *Ushr(Type *type, Expression *e1, Expression *e2);
Expression *And(Type *type, Expression *e1, Expression *e2);
Expression *Or(Type *type, Expression *e1, Expression *e2);
Expression *Xor(Type *type, Expression *e1, Expression *e2);
Expression *Index(Type *type, Expression *e1, Expression *e2);
Expression *Cat(Type *type, Expression *e1, Expression *e2);

Expression *Equal(enum TOK op, Type *type, Expression *e1, Expression *e2);
Expression *Cmp(enum TOK op, Type *type, Expression *e1, Expression *e2);
Expression *Identity(enum TOK op, Type *type, Expression *e1, Expression *e2);

Expression *Slice(Type *type, Expression *e1, Expression *lwr, Expression *upr);


/*********************************
 * String compare of filenames.
 */

#if MSDOS || __OS2__ || _WIN32
#define filespeccmp(f1,f2)      stricmp((f1),(f2))
#define filespecmemcmp(f1,f2,n) memicmp((f1),(f2),(n))
#endif
#if BSDUNIX || M_UNIX || M_XENIX
#define filespeccmp(f1,f2)      strcmp((f1),(f2))
#define filespecmemcmp(f1,f2,n) memcmp((f1),(f2),(n))
#endif


char *filespecaddpath(const char *,const char *);
char *filespecrootpath(char *);
char *filespecdefaultext(const char *,const char *);
char *filespecdotext(const char *);
char *filespecforceext(const char *,const char *);
char *filespecgetroot(const char *);
char *filespecname(const char *);

#if MSDOS || __OS2__ || __NT__
#define filespectilde(f)        (f)
#else
char *filespectilde(char *);
#endif


#if MSDOS || __OS2__ || __NT__
#define filespecmultitilde(f)   (f)
#else
char *filespecmultitilde(char *);
#endif


char *filespecbackup(const char *);

int arrayTypeCompatible(Loc loc, Type *t1, Type *t2);

int findCondition(Array *ids, Identifier *ident);

Expression *isExpression(Object *o);
Dsymbol *isDsymbol(Object *o);
Type *isType(Object *o);
Tuple *isTuple(Object *o);
int arrayObjectIsError(Objects *args);
int isError(Object *o);
Type *getType(Object *o);
Dsymbol *getDsymbol(Object *o);

void ObjectToCBuffer(OutBuffer *buf, HdrGenState *hgs, Object *oarg);

elem *incUsageElem(IRState *irs, Loc loc);
elem *getEthis(Loc loc, IRState *irs, Dsymbol *fd);
int intrinsic_op(char *name);
elem *resolveLengthVar(VarDeclaration *lengthVar, elem **pe, Type *t1);


#endif