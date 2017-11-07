module dmd.Lstring;

import dmd.common;
import dmd.Dchar;

struct Lstring
{
    immutable(dchar_t)[] string_;

    __gshared static const(Lstring) zero;	// 0 length string

    // No constructors because we want to be able to statically
    // initialize Lstring's, and Lstrings are of variable size.

version (M_UNICODE) {
    ///#define LSTRING(p,length) { length, L##p }
} else {
    ///#define LSTRING(p,length) { length, p }
}

///#if __GNUC__
///    #define LSTRING_EMPTY() { 0 }
///#else
///    #define LSTRING_EMPTY() LSTRING("", 0)
///#endif

    static Lstring* ctor(const(dchar_t)* p) { return ctor(p, Dchar.len(p)); }
    
	static Lstring* ctor(const(dchar_t)* p, uint length)
	{
		assert(false);
	}
	
    static uint size(uint length) { return Lstring.sizeof + (length + 1) * dchar_t.sizeof; }
	
    static Lstring* alloc(uint length)
	{
		assert(false);
	}
	
    Lstring* clone()
	{
		assert(false);
	}

    uint len() { return string_.length; }

    const(dchar_t)[] toDchars() { return string_; }

    hash_t hash() { return Dchar.calcHash(string_.ptr, string_.length); }
    hash_t ihash() { return Dchar.icalcHash(string_.ptr, string_.length); }

    static int cmp(const(Lstring)* s1, const(Lstring)* s2)
    {
		int c = s2.string_.length - s1.string_.length;
		return c ? c : Dchar.memcmp(s1.string_.ptr, s2.string_.ptr, s1.string_.length);
    }

    static int icmp(const(Lstring)* s1, const(Lstring)* s2)
    {
		int c = s2.string_.length - s1.string_.length;
		return c ? c : Dchar.memicmp(s1.string_.ptr, s2.string_.ptr, s1.string_.length);
    }

    Lstring* append(const(Lstring)* s)
	{
		assert(false);
	}
	
    Lstring* substring(int start, int end)
	{
		assert(false);
	}
}