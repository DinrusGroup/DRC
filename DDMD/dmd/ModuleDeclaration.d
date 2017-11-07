module dmd.ModuleDeclaration;

import dmd.common;
import dmd.Identifier;
import dmd.ArrayTypes;
import dmd.OutBuffer;

import dmd.TObject;

import dmd.DDMDExtensions;

class ModuleDeclaration : TObject
{
	mixin insertMemberExtension!(typeof(this));

    Identifier id;
    Identifiers packages;		// array of Identifier's representing packages
    bool safe;

    this(Identifiers packages, Identifier id, bool safe)
	{
		register();
		this.packages = packages;
		this.id = id;
		this.safe = safe;
	}

    string toChars()
	{
		scope OutBuffer buf = new OutBuffer();
		if (packages)
		{
			foreach (pid; packages)
			{
                buf.writestring(pid.toChars());
				buf.writeByte('.');
			}
		}
		buf.writestring(id.toChars());
		buf.writeByte(0);
		return buf.extractString();
	}
}
