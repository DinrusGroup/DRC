module dmd.Utf;

import dmd.common;
import dmd.Dchar;

import std.utf;

string utf_decodeChar(const(char)[] s, size_t* pidx, dchar* presult)
{
	try {
		*presult = decode(s, *pidx);
	} catch (Exception e) {
		return e.toString();
	}

	return null;
}

string utf_decodeWchar(const(wchar)[] s, size_t* pidx, dchar* presult)
{
	try {
		*presult = decode(s, *pidx);
	} catch (Exception e) {
		return e.toString();
	}

	return null;
}

bool utf_isValidDchar(uint c)
{
	return isValidDchar(c);
}

extern (C++) extern int HtmlNamedEntity(ubyte* p, int length);
