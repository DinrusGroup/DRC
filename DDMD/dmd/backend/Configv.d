module dmd.backend.Configv;

import dmd.common;
import dmd.backend.LANG;

// Configuration that is not saved in precompiled header

struct Configv
{
    char addlinenumbers;	// put line number info in .OBJ file
    char verbose;		// 0: compile quietly (no messages)
				// 1: show progress to DLL (default)
				// 2: full verbosity
    char* csegname;		// code segment name
    char* deflibname;		// default library name
    LANG language;		// message language
    int errmax;			// max error count
}

__gshared Configv configv;