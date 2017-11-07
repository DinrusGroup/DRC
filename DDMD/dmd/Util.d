module dmd.Util;

import dmd.common;
import dmd.Loc;
import dmd.Library;
import dmd.File;
import dmd.String;
import dmd.OutBuffer;
import dmd.FileName;
import dmd.Global;
import dmd.PREC;
import dmd.TOK;

import std.process : getenv;
import core.stdc.string;
import std.stdio : writef, writefln, write;

import core.memory;

version (Windows)
{
    static import std.stdio ;//: spawnl, spawnlp;
}
version (POSIX)
{
    import core.sys.posix.unistd;
}
import core.stdc.stdlib;
import core.stdc.ctype;
import core.stdc.stdarg;
public import core.stdc.stdio;
version (Bug4054) import core.memory;

extern(C) int putenv(char*);
/+version (LOG)
{
	static if( !is(typeof(printf)) )
		extern (C) int printf(const char*,...);
}+/
//version = LOG;

version (TARGET_OSX)
{
	version = TARGET_FOS; // FreeBSD, OS X, Solaris
}
version (TARGET_FREEBSD)
{
	version = TARGET_FOS; // FreeBSD, OS X, Solaris
}
version (TARGET_SOLARIS)
{
	version = TARGET_FOS; // FreeBSD, OS X, Solaris
}

version (POSIX)
{
	import dmd.Array;
	import dmd.Gnuc;
	import core.sys.posix.stdlib;
	version (TARGET_FOS) import core.stdc.limits;

	enum PATH_MAX = 1024;
}

enum MAX_PATH = 256; ///

version (Windows) {
	import core.sys.windows.windows : GetModuleFileNameA;
}

string fromStringz(const(char)* s)
{
	return s[0..strlen(s)].idup;
}

void warning(T...)(string format, T t)
{
	assert(false);
}

void warning(T...)(Loc loc, string format, T t)
{
	if (global.params.warnings && !global.gag)
    {
		write("warning - ");
		error(loc, format, t);
    }
}

void error(T...)(Loc loc, string format, T t)
{
	if (!global.gag)
    {
		string p = loc.toChars();

		if (p.length != 0)
			writef("%s: ", p);

		write("Error: ");
		writefln(format, t);

		//halt();
    }
    global.errors++;
}

T cloneThis(T)(T ptr)
{
	size_t size = ptr.classinfo.init.length;
	void* mem = GC.malloc(size);
	memcpy(mem, cast(void*)ptr, size);

	auto result = cast(T)mem;

	result.forceRegister();

	return result;
}

extern (C++) char* strupr(char* s)
{
    char* t = s;

    while (*s)
    {
		*s = cast(char)toupper(*s);
		s++;
    }

    return t;
}

char[] skipspace(char[] p)
{
	foreach (i, c; p) {
		if (!isspace(c)) {
			return p[i..$];
		}
	}

	return null;
}

char* skipspace(char* p)
{
    while (isspace(*p))
		p++;

	return p;
}

void inifile(string argv0, string inifile)
{
    char *path;		// need path for @P macro
    string filename;
    int i;
    int k;
    int envsection = 0;

version (LOG) {
    writef("inifile(argv0 = '%s', inifile = '%s')\n", argv0, inifile);
}
    if (FileName.absolute(inifile)) {
		filename = inifile;
    } else {
		/* Look for inifile in the following sequence of places:
		 *	o current directory
		 *	o home directory
		 *	o directory off of argv0
		 *	o /etc/
		 */
		if (FileName.exists(inifile)) {
			filename = inifile;
		} else {
			filename = FileName.combine(getenv("HOME"), inifile);
			if (!FileName.exists(filename)) {
version (_WIN32) { // This fix by Tim Matthews
				char[MAX_PATH + 1] resolved_name_b;
				auto resolved_name = resolved_name_b[].idup;
				if (GetModuleFileNameA(null, resolved_name_b.ptr, MAX_PATH + 1) && FileName.exists(resolved_name))
				{
					filename = FileName.replaceName(resolved_name, inifile);
					if (FileName.exists(filename)) {
						goto Ldone;
					}
				}
}
				filename = FileName.replaceName(argv0, inifile);
				if (!FileName.exists(filename)) {
version (POSIX) { /// linux || __APPLE__ || __FreeBSD__ || __sun&&__SVR4
	version (POSIX) { /// __GLIBC__ || __APPLE__ || __FreeBSD__ || __sun&&__SVR4   // This fix by Thomas Kuehne
					/* argv0 might be a symbolic link,
					* so try again looking past it to the real path
					*/
		version (TARGET_FOS) {/// #if __APPLE__ || __FreeBSD__ || __sun&&__SVR4
					char[PATH_MAX + 1] resolved_name;
					char* real_argv0 = realpath(toStringz(argv0), resolved_name.ptr);
		} else {
					char* real_argv0 = realpath(toStringz(argv0), null);
		}
					//printf("argv0 = %s, real_argv0 = %p\n", argv0, real_argv0);
					if (real_argv0) {
						filename = FileName.replaceName(fromStringz(real_argv0), inifile);
		version (linux) {
						///free(real_argv0);
		}
						if (FileName.exists(filename)) {
							goto Ldone;
						}
					}
	} else {
					static assert (false, "use of glibc non-standard extension realpath(char*, null)");
	}
					if (true) {
						// Search PATH for argv0
						const(char)* p = toStringz(getenv("PATH"));
	version (LOG) {
						writef("\tPATH='%s'\n", p);
	}
						auto paths = FileName.splitPath(fromStringz(p));
						filename = FileName.searchPath(paths, argv0, 0);
						if (!filename) {
							goto Letc;		// argv0 not found on path
						}

						filename = FileName.replaceName(filename, inifile);
						if (FileName.exists(filename)) {
							goto Ldone;
						}
					}
}
					// Search /etc/ for inifile
		Letc:
					filename = FileName.combine("/etc/", inifile);

		Ldone:
		    ;
				}
			}
		}
    }

    path = cast(char*)toStringz(FileName.path(filename));

version (LOG) {
    writef("\tpath = '%s', filename = '%s'\n", fromStringz(path), filename);
}

    scope File file = new File(filename);

    if (file.read()) {
		return;			// error reading file
	}

	scope OutBuffer buf = new OutBuffer();

    // Parse into lines
    int eof = 0;
    for (i = 0; i < file.len && !eof; i++)
    {
		int linestart = i;

		for (; i < file.len; i++)
		{
			switch (file.buffer[i])
			{
				case '\r':
					break;

				case '\n':
					// Skip if it was preceded by '\r'
					if (i && file.buffer[i - 1] == '\r')
						goto Lskip;
					break;

				case 0:
				case 0x1A:
					eof = 1;
					break;

				default:
					continue;
				}
				break;
		}

		// The line is file.buffer[linestart..i]
		char *line;
		int len;
		char *p;
		char* pn;

		line = cast(char*)&file.buffer[linestart];
		len = i - linestart;

		buf.reset();

		// First, expand the macros.
		// Macros are bracketed by % characters.

		for (k = 0; k < len; k++)
		{
			if (line[k] == '%')
			{
				int j;

				for (j = k + 1; j < len; j++)
				{
					if (line[j] == '%')
					{
						if (j - k == 3 && memicmp(&line[k + 1], "@P", 2) == 0)
						{
							// %@P% is special meaning the path to the .ini file
							p = path;
							if (!*p)
								p = cast(char*)".";
						}
						else
						{
							int l = j - k;
							char[10] tmp;	// big enough most of the time

							if (l <= tmp.sizeof)
								p = tmp.ptr;
							else
							{
							version (Bug4054)
								p = cast(char*)GC.malloc(l);
							else
								p = cast(char*)alloca(l);
							}
							l--;
							memcpy(p, &line[k + 1], l);
							p[l] = 0;
							strupr(p);
							p = core.stdc.stdlib.getenv(p);
							if (!p)
								p = cast(char*)"";
						}
						buf.writestring(p[0..strlen(p)]);	///
						k = j;
						goto L1;
					}
				}
			}
			buf.writeByte(line[k]);
		 L1:
			;
		}

		// Remove trailing spaces
		while (buf.offset && isspace(buf.data[buf.offset - 1]))
			buf.offset--;

		char[] pp = buf.getString();

		// The expanded line is in p.
		// Now parse it for meaning.

		pp = skipspace(pp);
		if (pp.length != 0) {
			switch (pp[0])
			{
				case ';':		// comment
					break;

				case '[':		// look for [Environment]
					pp = skipspace(pp[1..$]);
					for (pn = pp.ptr; isalnum(*pn); pn++) {
						//;
					}

					if (pn - pp.ptr == 11 &&
						memicmp(pp.ptr, "Environment", 11) == 0 &&
						*skipspace(pn) == ']'
					   )
						envsection = 1;
					else
						envsection = 0;
					break;

				default:
					if (envsection)
					{
						pn = pp.ptr;

						// Convert name to upper case;
						// remove spaces bracketing =
						auto p2 = pn;
						for ( ; *p2; p2++)
						{   if (islower(*p2))
								*p2 &= ~0x20;
							else if (isspace(*p2))
								memmove(p2, p2 + 1, strlen(p2));
							else if (*p2 == '=')
							{
								p2++;
								while (isspace(*p2))
									memmove(p2, p2 + 1, strlen(p2));
								break;
							}
						}

						//putenv(pn);
						putenv(cast(char*)toStringz(pp));

version (LOG) {
						writef("\tputenv('%s')\n", pn[0..strlen(pn)]);
						//printf("getenv(\"TEST\") = '%s'\n",getenv("TEST"));
}
					}
					break;
			}
		}

	Lskip:
		;
    }
}

///int response_expand(int *pargc, char ***pargv);
void browse(const(char)* url)
{
	assert(false);
}

string[] getenv_setargv(string envvar, string[] args)
{
    char *p;

    string[] argv = args.dup;
    int argc = args.length;

    int instring;
    int slash;
    char c;

    string ienv = getenv(envvar);
    if (ienv is null)
		return args;

    char[] env = ienv.dup;	// create our own writable copy

    int j = 1;			// leave argv[0] alone
	char* e = env.ptr;
    while (1)
    {
		int wildcard = 1; // do wildcard expansion
		switch (*e)
		{
			case ' ':
			case '\t':
			e++;
			break;

			case 0:
			goto Ldone;

			case '"':
			wildcard = 0;
			default:
			argv ~= assumeUnique(e[0..strlen(e)]);		// append
			//argv.insert(j, env);		// insert at position j
			j++;
			argc++;
			p = e;
			slash = 0;
			instring = 0;
			c = 0;

			char* ecopy = e;

			while (1)
			{
				c = *e++;
				switch (c)
				{
				case '"':
					p -= (slash >> 1);
					if (slash & 1)
					{
						p--;
						goto Laddc;
					}
					instring ^= 1;
					slash = 0;
					continue;

				case '\\':
					slash++;
					*p++ = c;
					continue;

				case ' ':
				case '\t':
					if (instring)
						goto Laddc;
				case 0:
					*p = 0;
					if (argv.length != 0) {
						argv[$-1].length = p - argv[$-1].ptr;
					}
					//if (wildcard)
					//wildcardexpand();	// not implemented
					if (c == 0) goto Ldone;
					break;

				default:
				Laddc:
					slash = 0;
					*p++ = c;
					continue;
				}
				break;
			}
		}
    }

Ldone:
    return argv;
}

void error(T...)(string format, T t)
{
	writefln(format, t);
    exit(EXIT_FAILURE);
}

void usage()
{
	writef("Digital Mars D Compiler %s\n%s %s\n", global.version_, global.copyright, global.written);
    writef(
"Documentation: http://www.digitalmars.com/d/2.0/index.html\n"~
"Usage:\n"~
"  ddmd files.d ... { -switch }\n"~
"\n"~
"  files.d        D source files\n"~
"  @cmdfile       read arguments from cmdfile\n"~
"  -c             do not link\n"~
"  -cov           do code coverage analysis\n"~
"  -D             generate documentation\n"~
"  -Dddocdir      write documentation file to docdir directory\n"~
"  -Dffilename    write documentation file to filename\n"~
"  -d             allow deprecated features\n"~
"  -debug         compile in debug code\n"~
"  -debug=level   compile in debug code <= level\n"~
"  -debug=ident   compile in debug code identified by ident\n"~
"  -debuglib=name    set symbolic debug library to name\n"~
"  -defaultlib=name  set default library to name\n"~
"  -deps=filename write module dependencies to filename\n"~
"  -g             add symbolic debug info\n"~
"  -gc            add symbolic debug info, pretend to be C\n"~
"  -H             generate 'header' file\n"~
"  -Hddirectory   write 'header' file to directory\n"~
"  -Hffilename    write 'header' file to filename\n"~
"  --help         print help\n"~
"  -Ipath         where to look for imports\n"~
"  -ignore        ignore unsupported pragmas\n"~
"  -inline        do function inlining\n"~
"  -Jpath         where to look for string imports\n"~
"  -Llinkerflag   pass linkerflag to link\n"~
"  -lib           generate library rather than object files\n"~
"  -man           open web browser on manual page\n"~
"  -map           generate linker .map file\n"~
"  -noboundscheck turns off array bounds checking for all functions\n"~
"  -nofloat       do not emit reference to floating point\n"~
"  -O             optimize\n"~
"  -o-            do not write object file\n"~
"  -odobjdir      write object & library files to directory objdir\n"~
"  -offilename	 name output file to filename\n"~
"  -op            do not strip paths from source file\n"~
"  -profile	 profile runtime performance of generated code\n"~
"  -quiet         suppress unnecessary messages\n"~
"  -release	 compile release version\n"~
"  -run srcfile args...   run resulting program, passing args\n"~
"  -unittest      compile in unit tests\n"~
"  -v             verbose\n"~
"  -version=level compile in version code >= level\n"~
"  -version=ident compile in version code identified by ident\n"~
"  -vtls          list all variables going into thread local storage\n"~
"  -w             enable warnings\n"~
"  -X             generate JSON file\n"~
"  -Xffilename    write JSON file to filename\n"
);
}

void fatal()
{
static if (false) {
    halt();
} else {
    exit(EXIT_FAILURE);
}
}

extern (C++) void halt()
{
	assert(false);
}

void initPrecedence()
{
	precedence[TOK.TOKdotvar] = PREC.PREC_primary;
    precedence[TOK.TOKimport] = PREC.PREC_primary;
    precedence[TOK.TOKidentifier] = PREC.PREC_primary;
    precedence[TOK.TOKthis] = PREC.PREC_primary;
    precedence[TOK.TOKsuper] = PREC.PREC_primary;
    precedence[TOK.TOKint64] = PREC.PREC_primary;
    precedence[TOK.TOKfloat64] = PREC.PREC_primary;
    precedence[TOK.TOKnull] = PREC.PREC_primary;
    precedence[TOK.TOKstring] = PREC.PREC_primary;
    precedence[TOK.TOKarrayliteral] = PREC.PREC_primary;
    precedence[TOK.TOKtypeid] = PREC.PREC_primary;
    precedence[TOK.TOKis] = PREC.PREC_primary;
    precedence[TOK.TOKassert] = PREC.PREC_primary;
    precedence[TOK.TOKfunction] = PREC.PREC_primary;
    precedence[TOK.TOKvar] = PREC.PREC_primary;
version (DMDV2) {
    precedence[TOK.TOKdefault] = PREC.PREC_primary;
}

    // post
    precedence[TOK.TOKdotti] = PREC.PREC_primary;
    precedence[TOK.TOKdot] = PREC.PREC_primary;
//  precedence[TOK.TOKarrow] = PREC.PREC_primary;
    precedence[TOK.TOKplusplus] = PREC.PREC_primary;
    precedence[TOK.TOKminusminus] = PREC.PREC_primary;
    precedence[TOK.TOKcall] = PREC.PREC_primary;
    precedence[TOK.TOKslice] = PREC.PREC_primary;
    precedence[TOK.TOKarray] = PREC.PREC_primary;

    precedence[TOK.TOKaddress] = PREC.PREC_unary;
    precedence[TOK.TOKstar] = PREC.PREC_unary;
    precedence[TOK.TOKneg] = PREC.PREC_unary;
    precedence[TOK.TOKuadd] = PREC.PREC_unary;
    precedence[TOK.TOKnot] = PREC.PREC_unary;
    precedence[TOK.TOKtobool] = PREC.PREC_add;
    precedence[TOK.TOKtilde] = PREC.PREC_unary;
    precedence[TOK.TOKdelete] = PREC.PREC_unary;
    precedence[TOK.TOKnew] = PREC.PREC_unary;
    precedence[TOK.TOKcast] = PREC.PREC_unary;

    precedence[TOK.TOKpow] = PREC.PREC_pow;

    precedence[TOK.TOKmul] = PREC.PREC_mul;
    precedence[TOK.TOKdiv] = PREC.PREC_mul;
    precedence[TOK.TOKmod] = PREC.PREC_mul;
    precedence[TOKpow]     = PREC.PREC_mul;

    precedence[TOK.TOKadd] = PREC.PREC_add;
    precedence[TOK.TOKmin] = PREC.PREC_add;
    precedence[TOK.TOKcat] = PREC.PREC_add;

    precedence[TOK.TOKshl] = PREC.PREC_shift;
    precedence[TOK.TOKshr] = PREC.PREC_shift;
    precedence[TOK.TOKushr] = PREC.PREC_shift;

    precedence[TOK.TOKlt] = PREC.PREC_rel;
    precedence[TOK.TOKle] = PREC.PREC_rel;
    precedence[TOK.TOKgt] = PREC.PREC_rel;
    precedence[TOK.TOKge] = PREC.PREC_rel;
    precedence[TOK.TOKunord] = PREC.PREC_rel;
    precedence[TOK.TOKlg] = PREC.PREC_rel;
    precedence[TOK.TOKleg] = PREC.PREC_rel;
    precedence[TOK.TOKule] = PREC.PREC_rel;
    precedence[TOK.TOKul] = PREC.PREC_rel;
    precedence[TOK.TOKuge] = PREC.PREC_rel;
    precedence[TOK.TOKug] = PREC.PREC_rel;
    precedence[TOK.TOKue] = PREC.PREC_rel;
    precedence[TOK.TOKin] = PREC.PREC_rel;

static if (false) {
    precedence[TOK.TOKequal] = PREC.PREC_equal;
    precedence[TOK.TOKnotequal] = PREC.PREC_equal;
    precedence[TOK.TOKidentity] = PREC.PREC_equal;
    precedence[TOK.TOKnotidentity] = PREC.PREC_equal;
} else {
    /* Note that we changed precedence, so that < and != have the same
     * precedence. This change is in the parser, too.
     */
    precedence[TOK.TOKequal] = PREC.PREC_rel;
    precedence[TOK.TOKnotequal] = PREC.PREC_rel;
    precedence[TOK.TOKidentity] = PREC.PREC_rel;
    precedence[TOK.TOKnotidentity] = PREC.PREC_rel;
}

    precedence[TOK.TOKand] = PREC.PREC_and;

    precedence[TOK.TOKxor] = PREC.PREC_xor;

    precedence[TOK.TOKor] = PREC.PREC_or;

    precedence[TOK.TOKandand] = PREC.PREC_andand;

    precedence[TOK.TOKoror] = PREC.PREC_oror;

    precedence[TOK.TOKquestion] = PREC.PREC_cond;

    precedence[TOK.TOKassign] = PREC.PREC_assign;
    precedence[TOK.TOKconstruct] = PREC.PREC_assign;
    precedence[TOK.TOKblit] = PREC.PREC_assign;
    precedence[TOK.TOKaddass] = PREC.PREC_assign;
    precedence[TOK.TOKminass] = PREC.PREC_assign;
    precedence[TOK.TOKcatass] = PREC.PREC_assign;
    precedence[TOK.TOKmulass] = PREC.PREC_assign;
    precedence[TOK.TOKdivass] = PREC.PREC_assign;
    precedence[TOK.TOKmodass] = PREC.PREC_assign;
    precedence[TOK.TOKpowass]   = PREC.PREC_assign;
    precedence[TOK.TOKshlass] = PREC.PREC_assign;
    precedence[TOK.TOKshrass] = PREC.PREC_assign;
    precedence[TOK.TOKushrass] = PREC.PREC_assign;
    precedence[TOK.TOKandass] = PREC.PREC_assign;
    precedence[TOK.TOKorass] = PREC.PREC_assign;
    precedence[TOK.TOKxorass] = PREC.PREC_assign;

    precedence[TOK.TOKcomma] = PREC.PREC_expr;
}

int runLINK()
{
version (_WIN32)
{
    string p;
    int i;
    int status;
    scope OutBuffer cmdbuf = new OutBuffer();

    global.params.libfiles.push(cast(void*)new String("user32"));
    global.params.libfiles.push(cast(void*)new String("kernel32"));

    for (i = 0; i < global.params.objfiles.dim; i++)
    {
		if (i)
			cmdbuf.writeByte('+');
		p = (cast(String)global.params.objfiles.data[i]).str;
		string ext = FileName.ext(p);
		if (ext)
			// Write name sans extension
			writeFilename(cmdbuf, p[0..p.length - ext.length - 1]);
		else
			writeFilename(cmdbuf, p);
    }
    cmdbuf.writeByte(',');
    if (global.params.exefile)
		writeFilename(cmdbuf, global.params.exefile);
    else
    {
		/* Generate exe file name from first obj name.
		 * No need to add it to cmdbuf because the linker will default to it.
		 */
		string n = (cast(String)global.params.objfiles.data[0]).str;
		n = FileName.name(n);
		FileName fn = FileName.forceExt(n, "exe");
		global.params.exefile = fn.toChars();
    }

    // Make sure path to exe file exists
    {
		string pp = FileName.path(global.params.exefile);
		FileName.ensurePathExists(pp);
    }

    cmdbuf.writeByte(',');

    if (global.params.mapfile)
		cmdbuf.writestring(global.params.mapfile);
    else if (global.params.run)
		cmdbuf.writestring("nul");

    cmdbuf.writeByte(',');

    for (i = 0; i < global.params.libfiles.dim; i++)
    {
		if (i)
			cmdbuf.writeByte('+');
		writeFilename(cmdbuf, (cast(String)global.params.libfiles.data[i]).str);
    }

    if (global.params.deffile)
    {
		cmdbuf.writeByte(',');
		writeFilename(cmdbuf, global.params.deffile);
    }

    /* Eliminate unnecessary trailing commas	*/
    while (1)
    {
		i = cmdbuf.offset;
		if (!i || cmdbuf.data[i - 1] != ',')
			break;
		cmdbuf.offset--;
    }

    if (global.params.resfile)
    {
		cmdbuf.writestring("/RC:");
		writeFilename(cmdbuf, global.params.resfile);
    }

    if (global.params.map || global.params.mapfile)
		cmdbuf.writestring("/m");
	
static if (false) {
    if (debuginfo)
		cmdbuf.writestring("/li");
    if (codeview)
    {
		cmdbuf.writestring("/co");
		if (codeview3)
			cmdbuf.writestring(":3");
    }
} else {
    if (global.params.symdebug)
		cmdbuf.writestring("/co");
}

    cmdbuf.writestring("/noi");
    for (i = 0; i < global.params.linkswitches.dim; i++)
    {
		cmdbuf.writestring((cast(String)global.params.linkswitches.data[i]).str);
    }
    cmdbuf.writeByte(';');

    p = cmdbuf.toChars();

    FileName lnkfilename = null;
    size_t plen = p.length;
    if (plen > 7000)
    {
		lnkfilename = FileName.forceExt(global.params.exefile, "lnk");
		scope File flnk = new File(lnkfilename);
		flnk.setbuffer(cast(void*)p.ptr, plen);
		flnk.ref_ = 1;
		if (flnk.write())
			error("error writing file %s", lnkfilename);
		if (lnkfilename.len() < plen)
			p = std.string.format("@%s", lnkfilename.toChars());
    }

    string linkcmd = getenv("LINKCMD");
    if (!linkcmd)
		linkcmd = "link";

    status = executecmd(linkcmd, p, 1);
    if (lnkfilename)
    {
		remove(toStringz(lnkfilename.toChars()));
		///delete lnkfilename;
    }
    return status;
} else version (POSIX) {/// linux || __APPLE__ || __FreeBSD__ || __sun&&__SVR4
    pid_t childpid;
    int i;
    int status;

    // Build argv[]
    Array argv = new Array();

    const(char)* cc = core.stdc.stdlib.getenv("CC");
    if (!cc)
	cc = "gcc";
    argv.push(cast(void *)cc);
    Array objfiles = new Array;
    for( i = 0; i < global.params.objfiles.dim; i++ )
    {   string str = (cast(String)global.params.objfiles.data[i]).str;
    	objfiles.push(cast(void*)toStringz(str));
    }
    argv.insert(1, objfiles);

    // None of that a.out stuff. Use explicit exe file name, or
    // generate one from name of first source file.
    argv.push(cast(void *)cast(char*)"-o");
    if (global.params.exefile)
    {
		argv.push(cast(void*)toStringz(global.params.exefile));
    }
    else
    {	
		// Generate exe file name from first obj name
		string n = (cast(String)global.params.objfiles.data[0]).str;
		n = FileName.name(n);
		string e = FileName.ext(n);
		string ex = e ? n[0..$-(e.length+1)] : "a.out";

		argv.push(cast(void*)toStringz(ex));
		global.params.exefile = ex;
    }

    // Make sure path to exe file exists
    {	
		string p = FileName.path(global.params.exefile);
		FileName.ensurePathExists(p);
    }

    if (global.params.symdebug)
		argv.push(cast(void*)"-g".ptr);

    if (global.params.isX86_64)
		argv.push(cast(void*)"-m64".ptr);
    else
		argv.push(cast(void*)"-m32".ptr);
	
	if (global.params.map || global.params.mapfile)
    {
		argv.push(cast(void*)"-Xlinker".ptr);
version (__APPLE__) {
		argv.push(cast(void*)"-map".ptr);
} else {
		argv.push(cast(void *)"-Map".ptr);
}
		if (!global.params.mapfile)
		{
			size_t elen = global.params.exefile.length;
			size_t extlen = global.map_ext.length;
			size_t mlen = elen + 1 + extlen;
			char* m = cast(char*)GC.malloc(mlen + 1);
			memcpy(m, global.params.exefile.ptr, elen);
			m[elen] = '.';
			memcpy(m + elen + 1, global.map_ext.ptr, extlen);
			m[mlen] = 0;
			global.params.mapfile = cast(string)m[0..mlen];
		}
		argv.push(cast(void*)"-Xlinker".ptr);
		argv.push(cast(void*)global.params.mapfile.ptr);
    }

    if (0 && global.params.exefile)
    {
		/* This switch enables what is known as 'smart linking'
		 * in the Windows world, where unreferenced sections
		 * are removed from the executable. It eliminates unreferenced
		 * functions, essentially making a 'library' out of a module.
		 * Although it is documented to work with ld version 2.13,
		 * in practice it does not, but just seems to be ignored.
		 * Thomas Kuehne has verified that it works with ld 2.16.1.
		 * BUG: disabled because it causes exception handling to fail
		 * because EH sections are "unreferenced" and elided
		 */
		argv.push(cast(void *)"-Xlinker".ptr);
		argv.push(cast(void *)"--gc-sections".ptr);
    }

    for (i = 0; i < global.params.linkswitches.dim; i++)
    {	
		char* p = cast(char*)global.params.linkswitches.data[i];
		if (!p || !p[0] || !(p[0] == '-' && p[1] == 'l'))
			// Don't need -Xlinker if switch starts with -l
			argv.push(cast(void *)"-Xlinker".ptr);
		argv.push(cast(void*)p);
    }

    /* Add each library, prefixing it with "-l".
     * The order of libraries passed is:
     *  1. any libraries passed with -L command line switch
     *  2. libraries specified on the command line
     *  3. libraries specified by pragma(lib), which were appended
     *     to global.params.libfiles.
     *  4. standard libraries.
     */
    for (i = 0; i < global.params.libfiles.dim; i++)
    {	
		char* p = cast(char*)global.params.libfiles.data[i];
		size_t plen = strlen(p);
		if (plen > 2 && p[plen - 2] == '.' && p[plen -1] == 'a')
			argv.push(cast(void *)p);
		else
		{
			char *s = cast(char *)GC.malloc(plen + 3);
			s[0] = '-';
			s[1] = 'l';
			memcpy(s + 2, p, plen + 1);
			argv.push(cast(void *)s);
		}
    }

    /* Standard libraries must go after user specified libraries
     * passed with -l.
     */
    const char* libname = (global.params.symdebug)
				? global.params.debuglibname
				: global.params.defaultlibname;
    char* buf = cast(char*)GC.malloc(2 + strlen(libname) + 1);
    strcpy(buf, "-l");
    strcpy(buf + 2, libname);
    argv.push(cast(void *)buf);		// turns into /usr/lib/libphobos2.a

//    argv.push((void *)"-ldruntime");
    argv.push(cast(void *)"-lpthread".ptr);
    argv.push(cast(void *)"-lm".ptr);

    if (!global.params.quiet || global.params.verbose)
    {
		// Print it
		for (i = 0; i < argv.dim; i++)
			printf("%s ", cast(char *)argv.data[i]);
		printf("\n");
		fflush(stdout);
    }

    argv.push(null);
    childpid = fork();
    if (childpid == 0)
    {
		execvp(cast(char *)argv.data[0], cast(char **)argv.data);
		perror(cast(char *)argv.data[0]);		// failed to execute
		return -1;
    }

    waitpid(childpid, &status, 0);

    status=WEXITSTATUS(status);
    if (status)
		printf("--- errorlevel %d\n", status);
    return status;

} else {
    writef ("Linking is not yet supported for this version of DMD.\n");
    return -1;
}
}

int runProgram()
{
	assert(false);
}

void deleteExeFile()
{
	assert(false);
}

/****************************************
 * Write filename to cmdbuf, quoting if necessary.
 */

void writeFilename(OutBuffer buf, string filename)
{
	auto len = filename.length;
    /* Loop and see if we need to quote
     */
    for (size_t i = 0; i < len; i++)
    {
		char c = filename[i];

		if (isalnum(c) || c == '_')
			continue;

		/* Need to quote
		 */
		buf.writeByte('"');
		buf.writestring(filename);
		buf.writeByte('"');
		return;
    }

    /* No quoting necessary
     */
    buf.writestring(filename);
}

/******************************
 * Execute a rule.  Return the status.
 *	cmd	program to run
 *	args	arguments to cmd, as a string
 *	useenv	if cmd knows about _CMDLINE environment variable
 */

version (_WIN32) {
int executecmd(string cmd, string args, int useenv)
{
    int status;
    size_t len = args.length;

    if (!global.params.quiet || global.params.verbose)
    {
		printf("%s %s\n", cmd, args);
		fflush(stdout);
    }

    if (len > 255)
    {
		char* q;
		char[9] envname = "@_CMDLINE";

		envname[0] = '@';
		switch (useenv)
		{
			case 0:	goto L1;
			case 2: envname[0] = '%';	break;
			default: break;	///
		}
		version (Bug4054)
		q = cast(char*) GC.malloc(envname.sizeof + len + 1);
		else
		q = cast(char*) alloca(envname.sizeof + len + 1);
		sprintf(q, "%s=%s", envname.ptr + 1, args);
		status = putenv(q);
		if (status == 0)
			args = envname[].idup;
		else
		{
		L1:
			error("command line length of %d is too long",len);
		}
    }

    status = executearg0(cmd, args);
version (Windows) {
    if (status == -1) {
		auto cmdZ = toStringz(cmd);
		auto argsZ = toStringz(args);
		status = spawnlp(0, cmdZ, cmdZ, argsZ, null);
	}
}
//    if (global.params.verbose)
//	printf("\n");
    if (status)
    {
	if (status == -1)
	    printf("Can't run '%.*s', check PATH\n", cmd);
	else
	    printf("--- errorlevel %d\n", status);
    }
    return status;
}
}

/**************************************
 * Attempt to find command to execute by first looking in the directory
 * where DMD was run from.
 * Returns:
 *	-1	did not find command there
 *	!=-1	exit status from command
 */

version (_WIN32) {
int executearg0(string cmd, string args)
{
    string file;
    string argv0 = global.params.argv0;

    //printf("argv0='%s', cmd='%s', args='%s'\n",argv0,cmd,args);

    // If cmd is fully qualified, we don't do this
    if (FileName.absolute(cmd))
		return -1;

    file = FileName.replaceName(argv0, cmd);

    //printf("spawning '%s'\n",file);
version (_WIN32) {
	auto fileZ = toStringz(file);
	auto argsZ = toStringz(args);
    return spawnl(0, fileZ, fileZ, argsZ, null);
} else version (Posix) { ///#elif linux || __APPLE__ || __FreeBSD__ || __sun&&__SVR4
	assert(false);
	/+
    char *full;
    int cmdl = strlen(cmd);

    full = (char*) mem.malloc(cmdl + strlen(args) + 2);
    if (full == null)
	return 1;
    strcpy(full, cmd);
    full [cmdl] = ' ';
    strcpy(full + cmdl + 1, args);

    int result = system(full);

    mem.free(full);
    return result;
	+/
} else {
    static assert(false);
}
}
}

extern(C++) void util_assert(char* file,int line)
{
    fflush(stdout);
    printf("Internal error: %s %d\n",file,line);
    throw new Exception("Internal error");
}
/*
extern (C++) {
	void* mem_malloc(uint size)
	{
		return GC.malloc(size);
	}

	void* mem_calloc(uint size)
	{
		return GC.calloc(size);
	}

	void* mem_realloc(void* ptr, uint size)
	{
		return GC.realloc(ptr, size);
	}

	void mem_free(void* ptr)
	{
		GC.free(ptr);
	}

	void* mem_fmalloc(uint size)
	{
		return mem_malloc(size);
	}

	void* mem_fcalloc(uint size)
	{
		return mem_calloc(size);
	}
}
*/