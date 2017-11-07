module dmd.StringEntry;

import dmd.common;
import dmd.StringValue;
import dmd.Dchar;
import dmd.Lstring;

import core.stdc.stdlib;

struct StringEntry
{
    StringEntry* left;
    StringEntry* right;
    hash_t hash;

    StringValue value;

	this(immutable(dchar_t)[] s)
	{
		hash = Dchar.calcHash(s.ptr, s.length);
	}
}
