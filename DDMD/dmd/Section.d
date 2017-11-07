module dmd.Section;

import dmd.common;
import dmd.DocComment;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.OutBuffer;

import dmd.TObject;

class Section : TObject
{
    ubyte* name;
    uint namelen;

    ubyte* body_;
    uint bodylen;

    int nooutput;

    void write(DocComment dc, Scope sc, Dsymbol s, OutBuffer buf)
	{
		assert(false);
	}
}