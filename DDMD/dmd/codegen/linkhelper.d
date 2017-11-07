module dmd.codegen.linkhelper;

import dmd.Loc;
import dmd.Util;

import core.stdc.stdarg;
import std.conv;

// help resolve some linker dependencies from the backend back into the frontend

extern(C++)
{
	// msc.c wants to access global from out_config_init(), but it should never be called
	struct Global {}
	__gshared Global global;

	void error(const char *filename, uint linnum, const char *format, ...)
	{
		Loc loc;
		loc.filename = to!string(filename);
		loc.linnum = linnum;

		va_list ap;
		va_start(ap, format);
		
		char[1024] buf;
		int len = vsprintf(buf.ptr, format, ap);
		va_end( ap );
		
		dmd.Util.error(loc, buf[0..len].idup);
	}
}
