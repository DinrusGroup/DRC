module dmd.DocComment;

import dmd.common;
import dmd.Array;
import dmd.Section;
import dmd.Macro;
import dmd.Escape;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.OutBuffer;

import dmd.TObject;

import dmd.DDMDExtensions;

class DocComment : TObject
{
	mixin insertMemberExtension!(typeof(this));

    Array sections;		// Section*[]

    Section summary;
    Section copyright;
    Section macros;
    Macro** pmacrotable;
    Escape** pescapetable;

    this()
	{
		register();
		assert(false);
	}

    static DocComment parse(Scope sc, Dsymbol s, ubyte* comment)
	{
		assert(false);
	}
	
    static void parseMacros(Escape** pescapetable, Macro** pmacrotable, ubyte* m, uint mlen)
	{
		assert(false);
	}
	
    static void parseEscapes(Escape** pescapetable, ubyte* textstart, uint textlen)
	{
		assert(false);
	}

    void parseSections(ubyte* comment)
	{
		assert(false);
	}
	
    void writeSections(Scope sc, Dsymbol s, OutBuffer buf)
	{
		assert(false);
	}
}