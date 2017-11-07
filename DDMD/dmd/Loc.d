module dmd.Loc;

import dmd.common;
import dmd.Module;
import dmd.OutBuffer;

struct Loc
{
    string filename;
    uint linnum;

    this(int x)
    {
		linnum = x;
		filename = null;
    }

    this(Module mod, uint linnum)
	{
		this.linnum = linnum;
		this.filename = mod ? mod.srcfile.toChars() : null;
	}

    string toChars()
	{
		scope OutBuffer buf = new OutBuffer();

		if (filename !is null) {
			buf.printf("%s", filename);
		}

		if (linnum) {
			buf.printf("(%d)", linnum);
			buf.writeByte(0);
		}

		return buf.extractString();
	}

    bool equals(ref const(Loc) loc)
	{
		assert(false);
	}
}
