module main;

import dmd.Macro;
import dmd.Array;
import dmd.Module;
import dmd.Global;
import dmd.VersionCondition;
import dmd.DebugCondition;
import dmd.Loc;
import dmd.Lexer;
import dmd.OutBuffer;
import dmd.FileName;
import dmd.Type;
import dmd.File;
import dmd.Id;
import dmd.Identifier;
import dmd.Json;
import dmd.Library;
import dmd.TOK;
import dmd.String;
import dmd.backend.glue;

import core.vararg;
import std.string : toStringz;
import std.exception;

import core.stdc.string;
import core.stdc.stdio;
import core.stdc.ctype;
import core.stdc.errno;
import core.stdc.stdlib;
import core.stdc.limits;

import core.memory;

version (Windows)
	import dbg.CallStackInfo;

import dmd.Util;

enum ExitCode
{
	EXIT_SUCCESS = 0,
}

//version = CrashHandler;

version (CrashHandler) {
version(Linux)
{
extern (C) extern __gshared bool rt_trapExceptions;

static this() {
	rt_trapExceptions = false;
}

}


version(Windows)
{

version (Windows)
{
    private import core.stdc.wchar_;

    extern (Windows) alias int function() FARPROC;
    extern (Windows) FARPROC    GetProcAddress(void*, in char*);
    extern (Windows) void*      LoadLibraryA(in char*);
    extern (Windows) int        FreeLibrary(void*);
    extern (Windows) void*      LocalFree(void*);
    extern (Windows) wchar_t*   GetCommandLineW();
    extern (Windows) wchar_t**  CommandLineToArgvW(wchar_t*, int*);
    extern (Windows) export int WideCharToMultiByte(uint, uint, wchar_t*, int, char*, int, char*, int);
    pragma(lib, "shell32.lib"); // needed for CommandLineToArgvW
}

shared bool _d_isHalting = false;
__gshared string[] _d_args = null;

version(Posix)
{
    extern (C) void _STI_monitor_staticctor();
    extern (C) void _STD_monitor_staticdtor();
    extern (C) void _STI_critical_init();
    extern (C) void _STD_critical_term();
}

extern (C) void gc_init();
extern (C) void gc_term();
extern (C) void _minit();
extern (C) void _moduleCtor();
extern (C) void _moduleDtor();
extern (C) bool runModuleUnitTests();
extern (C) void thread_joinAll();

import rt.memory;

extern (C) int main(int argc, char** argv)
{
    char[][] args;
    int result;

    version (OSX)
    {   /* OSX does not provide a way to get at the top of the
         * stack, except for the magic value 0xC0000000.
         * But as far as the gc is concerned, argv is at the top
         * of the main thread's stack, so save the address of that.
         */
        __osx_stack_end = cast(void*)&argv;
    }

    version (FreeBSD) version (D_InlineAsm_X86)
    {
        /*
         * FreeBSD/i386 sets the FPU precision mode to 53 bit double.
         * Make it 64 bit extended.
         */
        ushort fpucw;
        asm
        {
            fstsw   fpucw;
            or      fpucw, 0b11_00_111111; // 11: use 64 bit extended-precision
                                           // 111111: mask all FP exceptions
            fldcw   fpucw;
        }
    }

    version (Posix)
    {
        _STI_monitor_staticctor();
        _STI_critical_init();
    }

    version (Windows)
    {
        wchar_t*  wcbuf = GetCommandLineW();
        size_t    wclen = wcslen(wcbuf);
        int       wargc = 0;
        wchar_t** wargs = CommandLineToArgvW(wcbuf, &wargc);
        assert(wargc == argc);

        char*     cargp = null;
        size_t    cargl = WideCharToMultiByte(65001, 0, wcbuf, wclen, null, 0, null, 0);

        cargp = cast(char*) alloca(cargl);
        args  = ((cast(char[]*) alloca(wargc * (char[]).sizeof)))[0 .. wargc];

        for (size_t i = 0, p = 0; i < wargc; i++)
        {
            int wlen = wcslen(wargs[i]);
            int clen = WideCharToMultiByte(65001, 0, &wargs[i][0], wlen, null, 0, null, 0);
            args[i]  = cargp[p .. p+clen];
            p += clen; assert(p <= cargl);
            WideCharToMultiByte(65001, 0, &wargs[i][0], wlen, &args[i][0], clen, null, 0);
        }
        LocalFree(wargs);
        wargs = null;
        wargc = 0;
    }
    else version (Posix)
    {
        char[]* am = cast(char[]*) malloc(argc * (char[]).sizeof);
        scope(exit) free(am);

        for (size_t i = 0; i < argc; i++)
        {
            auto len = strlen(argv[i]);
            am[i] = argv[i][0 .. len];
        }
        args = am[0 .. argc];
    }
    _d_args = cast(string[]) args;
	
	void runMain()
    {
		CrashHandlerInit();
		//	while (true)
		{
			result = main(_d_args);
		}
    }

    void runAll()
    {
        gc_init();
        initStaticDataGC();
        version (Windows)
            _minit();
        _moduleCtor();
        _moduleTlsCtor();
        if (runModuleUnitTests())
            runMain();
        else
            result = EXIT_FAILURE;
        _moduleTlsDtor();
        thread_joinAll();
        _d_isHalting = true;
        _moduleDtor();
        gc_term();
    }

    runAll();

    version (Posix)
    {
        _STD_critical_term();
        _STD_monitor_staticdtor();
    }
    return result;
}

}
}

int main(string[] args)
{
	GC.disable();
	
    Array files = new Array();
    Array libmodules = new Array();
    Module m;
    int status = ExitCode.EXIT_SUCCESS;
    int argcstart = args.length;
    int setdebuglib = 0;
    byte noboundscheck = 0;
	
	global = new Global();

///    if (response_expand(&argc,&argv))        // expand response files
///        error("can't open response file");

    files.reserve(args.length - 1);

    // Set default values
    global.params.argv0 = args[0];
    global.params.link = 1;
    global.params.useAssert = 1;
    global.params.useInvariants = 1;
    global.params.useIn = 1;
    global.params.useOut = 1;
    global.params.useArrayBounds = 2;	// default to all functions
    global.params.useSwitchError = 1;
    global.params.useInline = 0;
    global.params.obj = 1;
    global.params.Dversion = 2;
    global.params.quiet = 1;

    global.params.linkswitches = new Array();
    global.params.libfiles = new Array();
    global.params.objfiles = new Array();
    global.params.ddocfiles = new Array();

version (TARGET_WINDOS) {
    global.params.defaultlibname = "phobos";
} else version (POSIX) { //#elif TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
    global.params.defaultlibname = "phobos2";
} else version (TARGET_NET) {
} else {
    static assert(false, "fix this");
}

    // Predefine version identifiers
    VersionCondition.addPredefinedGlobalIdent("DigitalMars");

version (TARGET_WINDOS) {
    VersionCondition.addPredefinedGlobalIdent("Windows");
    global.params.isWindows = 1;
version (TARGET_NET) {
    // TARGET_NET macro is NOT mutually-exclusive with TARGET_WINDOS
    VersionCondition.addPredefinedGlobalIdent("D_NET");
}
} else version (TARGET_LINUX) {
    VersionCondition.addPredefinedGlobalIdent("Posix");
    VersionCondition.addPredefinedGlobalIdent("linux");
    global.params.isLinux = 1;
} else version (TARGET_OSX) {
    VersionCondition.addPredefinedGlobalIdent("Posix");
    VersionCondition.addPredefinedGlobalIdent("OSX");
    global.params.isOSX = 1;

    // For legacy compatibility
    VersionCondition.addPredefinedGlobalIdent("darwin");
} else version (TARGET_FREEBSD) {
    VersionCondition.addPredefinedGlobalIdent("Posix");
    VersionCondition.addPredefinedGlobalIdent("FreeBSD");
    global.params.isFreeBSD = 1;
} else version (TARGET_SOLARIS) {
    VersionCondition.addPredefinedGlobalIdent("Posix");
    VersionCondition.addPredefinedGlobalIdent("Solaris");
    global.params.isSolaris = 1;
} else {
        static assert (false, "fix this");
}

    VersionCondition.addPredefinedGlobalIdent("LittleEndian");
    //VersionCondition.addPredefinedGlobalIdent("D_Bits");
version (DMDV2) {
    VersionCondition.addPredefinedGlobalIdent("D_Version2");
}
    VersionCondition.addPredefinedGlobalIdent("all");

version (Windows)
{
	inifile(args[0], "sc.ini");
}
 else version (Posix) ///linux || __APPLE__ || __FreeBSD__ || __sun&&__SVR4
{
	inifile(args[0], "dmd.conf");
}
else
{
	static assert (false, "fix this");
}
    args = getenv_setargv("DFLAGS", args);

version (disabled) {
    for (i = 0; i < argc; i++)
    {
        writef("argv[%d] = '%s'\n", i, argv[i]);
    }
}

    foreach(i; 1..args.length)
    {
		auto arg = args[i];
        auto p = arg.ptr;
        if (*p == '-')
        {
			arg = arg[1..$];
            if (arg == "d")
                global.params.useDeprecated = 1;
            else if (arg == "c")
                global.params.link = 0;
            else if (arg == "cov")
                global.params.cov = 1;
///version (XXX) {// TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
///            else if (arg == "fPIC")
///                global.params.pic = 1;
///}
			else if (arg == "map")
				global.params.map = 1;
            else if (arg == "multiobj")
                global.params.multiobj = 1;
            else if (arg == "g")
                global.params.symdebug = 1;
            else if (arg == "gc")
                global.params.symdebug = 2;
            else if (arg == "gt")
            {        error("use -profile instead of -gt\n");
                global.params.trace = 1;
            }
            else if (arg == "m64")
                global.params.isX86_64 = 1;
            else if (arg == "profile")
                global.params.trace = 1;
            else if (arg == "v")
                global.params.verbose = 1;
///version (DMDV2) {
            else if (arg == "vtls")
                global.params.vtls = 1;
///}
            else if (arg == "v1")
            {
version (DMDV1) {
                global.params.Dversion = 1;
} else {
                error("use DMD 1.0 series compilers for -v1 switch");
                break;
}
            }
            else if (arg == "w")
                global.params.warnings = 1;
            else if (arg == "O")
                global.params.optimize = 1;
            else if (p[1] == 'o')
            {
                switch (p[2])
                {
                    case '-':
                        global.params.obj = 0;
                        break;

                    case 'd':
                        if (!p[3])
                            goto Lnoarg;
                        global.params.objdir = arg[(p - arg.ptr) + 3..$];
                        break;

                    case 'f':
					{
                        if (!p[3])
                            goto Lnoarg;
							
                        global.params.objname = arg[(p - arg.ptr) + 3..$];
                        break;
					}

                    case 'p':
                        if (p[3])
                            goto Lerror;
                        global.params.preservePaths = 1;
                        break;

                    case 0:
                        error("-o no longer supported, use -of or -od");
                        break;

                    default:
                        goto Lerror;
                }
            }
            else if (p[1] == 'D')
            {        global.params.doDocComments = 1;
                switch (p[2])
                {
                    case 'd':
                        if (!p[3])
                            goto Lnoarg;
                        global.params.docdir = arg[(p - arg.ptr) + 3..$];
                        break;
                    case 'f':
                        if (!p[3])
                            goto Lnoarg;
                        global.params.docname = arg[(p - arg.ptr) + 3..$];
                        break;

                    case 0:
                        break;

                    default:
                        goto Lerror;
                }
            }
///version (_DH) {
            else if (p[1] == 'H')
            {        global.params.doHdrGeneration = 1;
                switch (p[2])
                {
                    case 'd':
                        if (!p[3])
                            goto Lnoarg;
                        global.params.hdrdir = arg[(p - arg.ptr) + 3..$];
                        break;

                    case 'f':
                        if (!p[3])
                            goto Lnoarg;
                        global.params.hdrname = arg[(p - arg.ptr) + 3..$];
                        break;

                    case 0:
                        break;

                    default:
                        goto Lerror;
                }
            }
///}
			else if (p[1] == 'X')
			{
				global.params.doXGeneration = 1;
				switch (p[2])
				{
					case 'f':
					if (!p[3])
						goto Lnoarg;
					global.params.xfilename = arg[(p - arg.ptr) + 3..$];
					break;
	
					case 0:
					break;
	
					default:
					goto Lerror;
				}
			}

            else if (arg == "ignore")
                global.params.ignoreUnsupportedPragmas = 1;
            else if (arg == "inline")
                global.params.useInline = 1;
            else if (arg == "lib")
                global.params.lib = 1;
            else if (arg == "nofloat")
                global.params.nofloat = 1;
            else if (arg == "quiet")
                global.params.quiet = 1;
            else if (arg == "release")
                global.params.release = 1;
///version (DMDV2) {
	        else if (arg == "noboundscheck")
		        noboundscheck = 1;
///}
            else if (arg == "unittest")
                global.params.useUnitTests = 1;
            else if (p[1] == 'I')
            {
                global.params.imppath.push(cast(void*)new String(arg[(p - arg.ptr) + 2..$]));	///
            }
            else if (p[1] == 'J')
            {
                if (!global.params.fileImppath)
                    global.params.fileImppath = new Array();
                global.params.fileImppath.push(cast(void*)new String(arg[(p - arg.ptr) + 2..$]));
            }
            else if (memcmp(p + 1, "debug".ptr, 5) == 0 && p[6] != 'l')
            {
                // Parse:
                //        -debug
                //        -debug=number
                //        -debug=identifier
                if (p[6] == '=')
                {
                    if (isdigit(p[7]))
                    {        long level;

                        errno = 0;
                        level = strtol(p + 7, cast(char**)&p, 10);
                        if (*p || errno || level > INT_MAX)
                            goto Lerror;
                        DebugCondition.setGlobalLevel(cast(int)level);
                    }
                    else if (Lexer.isValidIdentifier(arg[(p - arg.ptr) + 7..$]))		///
                        DebugCondition.addGlobalIdent(p + 7);
                    else
                        goto Lerror;
                }
                else if (p[6])
                    goto Lerror;
                else
                    global.params.debuglevel = 1;
            }
            else if (memcmp(p + 1, "version".ptr, 5) == 0)
            {
                // Parse:
                //        -version=number
                //        -version=identifier
                if (p[8] == '=')
                {
                    if (isdigit(p[9]))
                    {        long level;

                        errno = 0;
                        level = strtol(p + 9, cast(char**)&p, 10);	///
                        if (*p || errno || level > INT_MAX)
                            goto Lerror;
                        VersionCondition.setGlobalLevel(cast(int)level);
                    }
                    else if (Lexer.isValidIdentifier(arg[(p - arg.ptr) + 9..$]))	///
                        VersionCondition.addGlobalIdent(arg[(p - arg.ptr) + 9..$]);
                    else
                        goto Lerror;
                }
                else
                    goto Lerror;
            }
            else if (arg == "-b")
                global.params.debugb = 1;
            else if (arg == "-c")
                global.params.debugc = 1;
            else if (arg == "-f")
                global.params.debugf = 1;
            else if (arg == "-help")
            {        usage();
                exit(EXIT_SUCCESS);
            }
            else if (arg == "-r")
                global.params.debugr = 1;
            else if (arg == "-x")
                global.params.debugx = 1;
            else if (arg == "-y")
                global.params.debugy = 1;
            else if (p[1] == 'L')
            {
                global.params.linkswitches.push(cast(void*)p + 2);
            }
            else if (memcmp(p + 1, "defaultlib=".ptr, 11) == 0)
            {
                global.params.defaultlibname = p + 1 + 11;
            }
            else if (memcmp(p + 1, "debuglib=".ptr, 9) == 0)
            {
                setdebuglib = 1;
                global.params.debuglibname = p + 1 + 9;
            }
            else if (memcmp(p + 1, "deps=".ptr, 5) == 0)
            {
                global.params.moduleDepsFile = arg[(p - arg.ptr) + 1 + 5..$];
                if (!global.params.moduleDepsFile[0])
                    goto Lnoarg;
                global.params.moduleDeps = new OutBuffer;
            }
            else if (memcmp(p + 1, "man".ptr, 3) == 0)
            {
version (Windows) {
version (DMDV1) {
                browse("http://www.digitalmars.com/d/1.0/dmd-windows.html");
} else {
                browse("http://www.digitalmars.com/d/2.0/dmd-windows.html");
}
}
version (linux) {
version (DMDV1) {
                browse("http://www.digitalmars.com/d/1.0/dmd-linux.html");
} else {
                browse("http://www.digitalmars.com/d/2.0/dmd-linux.html");
}
}
version (__APPLE__) {
version (DMDV1) {
                browse("http://www.digitalmars.com/d/1.0/dmd-osx.html");
} else {
                browse("http://www.digitalmars.com/d/2.0/dmd-osx.html");
}
}
version (__FreeBSD__) {
version (DMDV1) {
                browse("http://www.digitalmars.com/d/1.0/dmd-freebsd.html");
} else {
                browse("http://www.digitalmars.com/d/2.0/dmd-freebsd.html");
}
}
                exit(EXIT_SUCCESS);
            }
            else if (arg == "run")
            {        global.params.run = 1;
                global.params.runargs_length = ((i >= argcstart) ? args.length : argcstart) - i - 1;
                if (global.params.runargs_length)
                {
                    files.push(cast(void*)args[i + 1].ptr);
                    global.params.runargs = args[i + 2..$];
                    i += global.params.runargs_length;
                    global.params.runargs_length--;
                }
                else
                {   global.params.run = 0;
                    goto Lnoarg;
                }
            }
            else
            {
             Lerror:
                error("unrecognized switch '%s'", args[i]);
                continue;

             Lnoarg:
                error("argument expected for switch '%s'", args[i]);
                continue;
            }
        }
        else
        {
version (TARGET_WINDOS) {
            string ext = FileName.ext(p[0..arg.length]);
            if (ext != null && FileName.compare(ext, "exe") == 0)
            {
                global.params.objname = arg[(p - arg.ptr)..$];
                continue;
            }
}
            files.push(cast(void*)new String(arg[(p - arg.ptr)..$]));
        }
    }
    if (global.errors)
    {
        fatal();
    }
    if (files.dim == 0)
    {        usage();
        return EXIT_FAILURE;
    }

    if (!setdebuglib)
        global.params.debuglibname = global.params.defaultlibname;

version (TARGET_OSX) {
    global.params.pic = 1;
}

    if (global.params.release)
    {
        global.params.useInvariants = 0;
        global.params.useIn = 0;
        global.params.useOut = 0;
        global.params.useAssert = 0;
        global.params.useArrayBounds = 0;
        global.params.useSwitchError = 0;
    }
    
    if (noboundscheck)
	    global.params.useArrayBounds = 0;
    
    if (global.params.run)
        global.params.quiet = 1;

    if (global.params.useUnitTests)
        global.params.useAssert = 1;

    if (!global.params.obj || global.params.lib)
        global.params.link = 0;

    if (global.params.link)
    {
        global.params.exefile = global.params.objname;
        global.params.oneobj = 1;
        if (global.params.objname)
        {
            /* Use this to name the one object file with the same
             * name as the exe file.
             */
            global.params.objname = FileName.forceExt(global.params.objname, global.obj_ext).toChars();

            /* If output directory is given, use that path rather than
             * the exe file path.
             */
            if (global.params.objdir)
            {
				string name = FileName.name(global.params.objname);
                global.params.objname = FileName.combine(global.params.objdir, name);
            }
        }
    }
    else if (global.params.lib)
    {
        global.params.libname = global.params.objname;
        global.params.objname = null;

        // Haven't investigated handling these options with multiobj
        if (!global.params.cov && !global.params.trace)
            global.params.multiobj = 1;
    }
    else if (global.params.run)
    {
        error("flags conflict with -run");
        fatal();
    }
    else
    {
        if (global.params.objname && files.dim > 1)
        {
            global.params.oneobj = 1;
            //error("multiple source files, but only one .obj name");
            //fatal();
        }
    }
    if (global.params.isX86_64)
    {
        VersionCondition.addPredefinedGlobalIdent("D_InlineAsm_X86_64");
        VersionCondition.addPredefinedGlobalIdent("X86_64");
        VersionCondition.addPredefinedGlobalIdent("D_LP64");
version (TARGET_WINDOS) {
        VersionCondition.addPredefinedGlobalIdent("Win64");
}
    }
    else
    {
        VersionCondition.addPredefinedGlobalIdent("D_InlineAsm");
        VersionCondition.addPredefinedGlobalIdent("D_InlineAsm_X86");
        VersionCondition.addPredefinedGlobalIdent("X86");
version (TARGET_WINDOS) {
        VersionCondition.addPredefinedGlobalIdent("Win32");
}
    }
    if (global.params.doDocComments)
        VersionCondition.addPredefinedGlobalIdent("D_Ddoc");
    if (global.params.cov)
        VersionCondition.addPredefinedGlobalIdent("D_Coverage");
    if (global.params.pic)
        VersionCondition.addPredefinedGlobalIdent("D_PIC");
version (DMDV2) {
    if (global.params.useUnitTests)
        VersionCondition.addPredefinedGlobalIdent("unittest");
}

    // Initialization
    Type.init();
    Id.initialize();
    initPrecedence();
	global.initClasssym();

    backend_init();

    //printf("%d source files\n",files.dim);

    // Build import search path
    if (global.params.imppath)
    {
        for (int i = 0; i < global.params.imppath.dim; i++)
        {
            string path = (cast(String)global.params.imppath.data[i]).str;
            string[] a = FileName.splitPath(path);

            global.path ~= a;
        }
    }

    // Build string import search path
    if (global.params.fileImppath)
    {
        for (int i = 0; i < global.params.fileImppath.dim; i++)
        {
            string path = (cast(String)global.params.fileImppath.data[i]).str;
            string[] a = FileName.splitPath(path);
			
            global.filePath ~= a;
        }
    }

    // Create Modules
    Array modules = new Array();
    modules.reserve(files.dim);
    int firstmodule = 1;
    for (int i = 0; i < files.dim; i++)
    {
        string ext;
        string name;

		String s = cast(String) files.data[i];
        string mp = s.str;

version (Windows) {
		char[] copy = null;
        // Convert / to \ so linker will work
        foreach (j, c; mp)
        {
            if (c == '/') {
				if (copy is null) copy = mp.dup;
                copy[j] = '\\';
			}
        }

		if (copy !is null) mp = assumeUnique(copy);
}
		string p = mp;
		
        p = FileName.name(p);                // strip path
        ext = FileName.ext(p);
		
        if (ext.length != 0)
        {   /* Deduce what to do with a file based on its extension
             */
            if (FileName.equals(ext, global.obj_ext))
            {
                global.params.objfiles.push(files.data[i]);
                libmodules.push(files.data[i]);
                continue;
            }

            if (FileName.equals(ext, global.lib_ext))
            {
                global.params.libfiles.push(files.data[i]);
                libmodules.push(files.data[i]);
                continue;
            }

            if (ext == global.ddoc_ext)
            {
                global.params.ddocfiles.push(files.data[i]);
                continue;
            }
            
			if (FileName.equals(ext, global.json_ext))
			{
				global.params.doXGeneration = 1;
				global.params.xfilename = (cast(String)files.data[i]).str;
				continue;
			}
			
		    if (FileName.equals(ext, global.map_ext))
			{
				global.params.mapfile = (cast(String)files.data[i]).str;
				continue;
			}

version (TARGET_WINDOS)
{
            if (FileName.equals(ext, "res"))
            {
                global.params.resfile = (cast(String)files.data[i]).str;
                continue;
            }

            if (FileName.equals(ext, "def"))
            {
                global.params.deffile = (cast(String)files.data[i]).str;
                continue;
            }

            if (FileName.equals(ext, "exe"))
            {
                assert(0);        // should have already been handled
            }
}

            /* Examine extension to see if it is a valid
             * D source file extension
             */
            if (FileName.equals(ext, global.mars_ext) ||
                FileName.equals(ext, global.hdr_ext) ||
                FileName.equals(ext, "dd") ||
                FileName.equals(ext, "htm") ||
                FileName.equals(ext, "html") ||
                FileName.equals(ext, "xhtml"))
            {
				immutable(char)* e = ext.ptr;
                e--;                        // skip onto '.'
                assert(*e == '.');
				
				immutable(char)* n = p.ptr;

                name = n[0..(e-n)];	// strip extension

                if (name.length == 0 || name == ".." || name == ".")
                {
                Linvalid:
                    error("invalid file name '%s'", (cast(String)files.data[i]).str);
                    fatal();
                }
            }
            else
            {        error("unrecognized file extension %s\n", ext);
                fatal();
            }
        }
        else
        {
			name = p;
            if (!*name.ptr)
                goto Linvalid;
        }

        /* At this point, name is the D source file name stripped of
         * its path and extension.
         */

        Identifier id = new Identifier(name, TOK.TOKreserved);
        m = new Module((cast(String) files.data[i]).str, id, global.params.doDocComments, global.params.doHdrGeneration);
        modules.push(cast(void*)m);

        if (firstmodule)
        {
			global.params.objfiles.push(cast(void*)m.objfile.name);
            firstmodule = 0;
        }
    }

    // Read files
//version = ASYNCREAD;
version (ASYNCREAD) {
    // Multi threaded
    AsyncRead *aw = AsyncRead.create(modules.dim);
    for (i = 0; i < modules.dim; i++)
    {
        m = cast(Module *)modules.data[i];
        aw.addFile(m.srcfile);
    }
    aw.start();
} else {
    // Single threaded
    for (int i = 0; i < modules.dim; i++)
    {
        m = cast(Module)modules.data[i];
        m.read(Loc(0));
    }
}

    // Parse files
    int anydocfiles = 0;
    for (int i = 0; i < modules.dim; i++)
    {
        m = cast(Module)modules.data[i];
        if (global.params.verbose)
            writef("parse     %s\n", m.toChars());
        if (!global.rootModule)
            global.rootModule = m;
        m.importedFrom = m;
        if (!global.params.oneobj || i == 0 || m.isDocFile)
            m.deleteObjFile();
version (ASYNCREAD) {
        if (aw.read(i))
        {
            error("cannot read file %s", m.srcfile.name.toChars());
        }
}

        m.parse();
        if (m.isDocFile)
        {
            anydocfiles = 1;
            m.gendocfile();

            // Remove m from list of modules
            modules.remove(i);
            i--;

            // Remove m's object file from list of object files
            for (int j = 0; j < global.params.objfiles.dim; j++)
            {
                if (m.objfile.name.str == (cast(FileName)global.params.objfiles.data[j]).str)
                {
                    global.params.objfiles.remove(j);
                    break;
                }
            }

            if (global.params.objfiles.dim == 0)
                global.params.link = 0;
        }
    }
version (ASYNCREAD) {
    AsyncRead.dispose(aw);
}

    if (anydocfiles && modules.dim &&
        (global.params.oneobj || global.params.objname))
    {
        error("conflicting Ddoc and obj generation options");
        fatal();
    }
    if (global.errors)
        fatal();
version (_DH)
{
    if (global.params.doHdrGeneration)
    {
        /* Generate 'header' import files.
         * Since 'header' import files must be independent of command
         * line switches and what else is imported, they are generated
         * before any semantic analysis.
         */
        for (i = 0; i < modules.dim; i++)
        {
            m = cast(Module)modules.data[i];
            if (global.params.verbose)
                writef("import    %s\n", m.toChars());
            m.genhdrfile();
        }
    }
    if (global.errors)
        fatal();
}
	//load all unconditional imports for better symbol resolving
	for (int i = 0; i < modules.dim; i++)
	{
		m = cast(Module)modules.data[i];
		if (global.params.verbose)
			writef("importall %s\n", m.toChars());
		m.importAll(null);
	}
	if (global.errors)
		fatal();
		
    // Do semantic analysis
    for (int i = 0; i < modules.dim; i++)
    {
        m = cast(Module)modules.data[i];
        if (global.params.verbose)
            writef("semantic  %s\n", m.toChars());
        m.semantic();
    }
    if (global.errors)
        fatal();
	
    global.dprogress = 1;
    Module.runDeferredSemantic();
	
    // Do pass 2 semantic analysis
    for (int i = 0; i < modules.dim; i++)
    {
        m = cast(Module)modules.data[i];
        if (global.params.verbose)
            writef("semantic2 %s\n", m.toChars());
        m.semantic2();
    }
    if (global.errors)
        fatal();

    // Do pass 3 semantic analysis
    for (int i = 0; i < modules.dim; i++)
    {
        m = cast(Module)modules.data[i];
        if (global.params.verbose)
            writef("semantic3 %s\n", m.toChars());
        m.semantic3();
    }
    if (global.errors)
        fatal();
	
    if (global.params.moduleDeps !is null)
    {
        assert(global.params.moduleDepsFile !is null);

        File deps = new File(global.params.moduleDepsFile);
        OutBuffer ob = global.params.moduleDeps;
        deps.setbuffer(cast(void*)ob.data, ob.offset);
        deps.writev();
    }


    // Scan for functions to inline
    if (global.params.useInline)
    {
        /* The problem with useArrayBounds and useAssert is that the
         * module being linked to may not have generated them, so if
         * we inline functions from those modules, the symbols for them will
         * not be found at link time.
         */
        if (!global.params.useArrayBounds && !global.params.useAssert)
        {
            // Do pass 3 semantic analysis on all imported modules,
            // since otherwise functions in them cannot be inlined
            for (int i = 0; i < global.amodules.dim; i++)
            {
                m = cast(Module)global.amodules.data[i];
                if (global.params.verbose)
                    writef("semantic3 %s\n", m.toChars());
                m.semantic3();
            }
            if (global.errors)
                fatal();
        }

        for (int i = 0; i < modules.dim; i++)
        {
            m = cast(Module)modules.data[i];
            if (global.params.verbose)
                writef("inline scan %s\n", m.toChars());
				
            m.inlineScan();
        }
    }
    if (global.errors)
        fatal();

    Library library = null;
    if (global.params.lib)
    {
        library = new Library();
        library.setFilename(global.params.objdir, global.params.libname);

        // Add input object and input library files to output library
        for (int i = 0; i < libmodules.dim; i++)
        {
            string p = (cast(String)libmodules.data[i]).str;
            library.addObject(p, null, 0);
        }
    }

    // Generate output files
	if (global.params.doXGeneration)
		json_generate(modules);
    
    if (global.params.oneobj)
    {
        for (int i = 0; i < modules.dim; i++)
        {
            m = cast(Module)modules.data[i];
            if (global.params.verbose)
                writef("code      %s\n", m.toChars());
            if (i == 0)
                obj_start(cast(char*)toStringz(m.srcfile.toChars()));
            m.genobjfile(0);
            if (!global.errors && global.params.doDocComments)
                m.gendocfile();
        }
        if (!global.errors && modules.dim)
        {
            obj_end(library, (cast(Module)modules.data[0]).objfile);
        }
    }
    else
    {
        for (int i = 0; i < modules.dim; i++)
        {
            m = cast(Module)modules.data[i];
            if (global.params.verbose)
                writef("code      %s\n", m.toChars());
            if (global.params.obj)
            {  
				obj_start(cast(char*)toStringz(m.srcfile.toChars()));
                m.genobjfile(global.params.multiobj);
                obj_end(library, m.objfile);
                obj_write_deferred(library);
            }
            if (global.errors)
            {
                if (!global.params.lib)
                    m.deleteObjFile();
            }
            else
            {
                if (global.params.doDocComments)
                    m.gendocfile();
            }
        }
    }		

    if (global.params.lib && !global.errors)
        library.write();

    backend_term();
    if (global.errors)
        fatal();

    if (!global.params.objfiles.dim)
    {
        if (global.params.link)
            error("no object files to link");
    }
    else
    {
        if (global.params.link)
            status = runLINK();

        if (global.params.run)
        {
            if (!status)
            {
                status = runProgram();

                /* Delete .obj files and .exe file
                 */
                for (int i = 0; i < modules.dim; i++)
                {
                    m = cast(Module)modules.data[i];
                    m.deleteObjFile();
                    if (global.params.oneobj)
                        break;
                }
                deleteExeFile();
            }
        }
    }

    return status;
}
