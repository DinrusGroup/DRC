module dmd.backend.dt_t;

import dmd.common;
import dmd.backend.targ_types;
import dmd.backend.Symbol;

struct dt_t
{
	dt_t* DTnext;			// next in list
    char dt;				// type (DTxxxx)
    ubyte Dty;			// pointer type

    union
    {
		struct				// DTibytes
		{
			char DTn;			// number of bytes
			char[7] DTdata;		// data
		}

		char DTonebyte;		// DT1byte

		targ_size_t DTazeros;		// DTazeros,DTcommon,DTsymsize

		struct				// DTabytes
		{
			char* DTpbytes;		// pointer to the bytes
			uint DTnbytes;		// # of bytes
version (TX86) {
			int DTseg;			// segment it went into
}
			targ_size_t DTabytes;		// offset of abytes for DTabytes
		}

		struct				// DTxoff
		{
			Symbol* DTsym;		// symbol pointer
			targ_size_t DToffset;	// offset from symbol
		}
    }
}

extern (C++) extern uint dt_size(dt_t* dtstart);

import std.stdio;

void dumpDt(dt_t* foo)
{
	foreach (a, b; foo.tupleof)
	{
		std.stdio.writeln(foo.tupleof[a].stringof, " ", cast(char*)&foo.tupleof[a] - cast(char*)foo, " = ", foo.tupleof[a]);
		//std.stdio.writeln("printf(\"", foo.tupleof[a].stringof, " %d = %d\\n\",(char*)(&", foo.tupleof[a].stringof, ")-(char*)foo, ", foo.tupleof[a].stringof, ");");
	}
}