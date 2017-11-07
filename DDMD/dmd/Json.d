/**
 *	this implements the JSON capability
 */
module dmd.Json;

import dmd.common;
import dmd.String;
import std.stdio : write, writef;

import dmd.Array;
import dmd.File;
import dmd.FileName;
import dmd.Global;
import dmd.Module;
import dmd.OutBuffer;

immutable Pname		= "name";
immutable Pkind		= "kind";
immutable Pfile		= "file";
immutable Pline		= "line";
immutable Ptype		= "type";
immutable Pcomment	= "comment";
immutable Pmembers	= "members";

void json_generate(Array modules)
{
	OutBuffer buf = new OutBuffer();

	buf.writestring("[\n");
	for (int i = 0; i < modules.dim; i++)
	{
		Module m = cast(Module)modules.data[i];
		if (global.params.verbose)
			writef("json gen %s\n", m.toChars());
		m.toJsonBuffer(buf);
		buf.writestring(",\n");
	}
	JsonRemoveComma(buf);
	buf.writestring("]\n");

	// Write buf to file
	string arg = global.params.xfilename;
	if (arg is null || arg[0] == 0)
	{   // Generate lib file name from first obj name
		String n2 = cast(String) global.params.objfiles.data[0];

		string n = FileName.name(n2.toChars());
		FileName fn = FileName.forceExt(n, global.json_ext);
		arg = fn.toChars();
	}
	else if (arg[0] == '-' && arg[1] == 0)
	{
		// Write to stdout
		write(buf.data[0..buf.offset]);
		return;
	}
//	if (!FileName.absolute(arg))
//		arg = FileName.combine(dir, arg);
	FileName jsonfilename = FileName.defaultExt(arg, global.json_ext);
	File jsonfile = new File(jsonfilename);
	assert(jsonfile);
	jsonfile.setbuffer(buf.data, buf.offset);
	jsonfile.ref_ = 1;
	string pt = FileName.path(jsonfile.toChars());
	if (pt[0] != 0)
		FileName.ensurePathExists(pt);
//	mem.free(pt);
	jsonfile.writev();
}


/*********************************
 * Encode string into buf, and wrap it in double quotes.
 */
void JsonString(OutBuffer buf, const(char)[] s)
{
	buf.writeByte('\"');
	foreach (c; s)
	{
		switch (c)
		{
			case '\n':
			buf.writestring(`\n`);
			break;
	
			case '\r':
			buf.writestring(`\r`);
			break;
	
			case '\t':
			buf.writestring(`\t`);
			break;
	
			case '\"':
			buf.writestring(`\"`);
			break;
	
			case '\\':
			buf.writestring(`\\`);
			break;
	
			case '/':
			buf.writestring(`\/`);
			break;
	
			case '\b':
			buf.writestring(`\b`);
			break;
	
			case '\f':
			buf.writestring(`\f`);
			break;
	
			default:
			if (c < 0x20)
				buf.printf("\\u%04x", c);
			else
				// Note that UTF-8 chars pass through here just fine
				buf.writeByte(c);
			break;
		}
	}
	buf.writeByte('\"');
}

void JsonProperty(OutBuffer buf, const(char)[] name, const(char)[] value)
{
	JsonString(buf, name);
	buf.writestring(" : ");
	JsonString(buf, value);
	buf.writestring(",\n");
}

void JsonProperty(OutBuffer buf, const(char)[] name, int value)
{
	JsonString(buf, name);
	buf.writestring(" : ");
	buf.printf("%d", value);
	buf.writestring(",\n");
}

void JsonRemoveComma(OutBuffer buf)
{
	if (buf.offset >= 2 &&
	buf.data[buf.offset - 2] == ',' &&
	buf.data[buf.offset - 1] == '\n')
		buf.offset -= 2;
}