module dmd.String;

import dmd.common;
import dmd.Array;

import core.stdc.string : strlen;
import std.string : cmp;

import std.stdio : writefln;

import dmd.TObject;

class String : TObject
{
    string str;

    this(string str)
	{
		register();
		this.str = str;
	}

    static hash_t calcHash(const(char)* str, size_t len)
	{
		hash_t hash = 0;

		for (;;)
		{
			switch (len)
			{
				case 0:
					return hash;

				case 1:
					hash *= 37;
					hash += *cast(ubyte*)str;
					return hash;

				case 2:
					hash *= 37;
					hash += *cast(ushort*)str;
					return hash;

				case 3:
					hash *= 37;
					hash += (*(cast(ushort*)str) << 8) +
						(cast(ubyte*)str)[2];
					return hash;

				default:
					hash *= 37;
					hash += *cast(uint*)str;
					str += 4;
					len -= 4;
					break;
			}
		}
	}
	
    static hash_t calcHash(string str)
	{
		return calcHash(str.ptr, str.length);
	}
	
    hash_t hashCode()
	{
		return calcHash(str.ptr, str.length);
	}
    
	uint len()
	{
		return str.length;
	}

    bool equals(Object obj)
	{
		return str == (cast(String)obj).str;
	}

    override int opCmp(Object obj)
	{
		return cmp(str, (cast(String)obj).str);
	}
	
    string toChars()
	{
		return str;
	}

    void print()
	{
		writefln("String '%s'", str);
	}
}
