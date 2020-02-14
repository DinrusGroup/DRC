﻿/***********************
 * Macros:
 *	WIKI = StdBitarray
 */

module std.bitarray;

//debug = bitarray;		// uncomment to turn on debugging эхо's

private import std.intrinsic;

/**
 * An array of bits.
 */
alias BitArray МассивБит;

struct BitArray
{
alias len длин;
alias ptr укз;

    size_t len;
    uint* ptr;

	т_мера разм()
	{
	return cast(т_мера) dim();
	}
	
    size_t dim()
    {
	return (len + 31) / 32;
    }
	
	т_мера длина()
	{
	return cast(т_мера) len;
	}
	
    size_t length()
    {
	return len;
    }

	проц длина(т_мера новдлин)
	{
	return length(cast(size_t) новдлин);
	}
	
    void length(size_t newlen)
    {
	if (newlen != len)
	{
	    size_t olddim = dim();
	    size_t newdim = (newlen + 31) / 32;

	    if (newdim != olddim)
	    {
		// Create a fake array so we can use D's realloc machinery
		uint[] b = ptr[0 .. olddim];
		b.length = newdim;		// realloc
		ptr = b.ptr;
		if (newdim & 31)
		{   // Set any pad bits to 0
		    ptr[newdim - 1] &= ~(~0 << (newdim & 31));
		}
	    }

	    len = newlen;
	}
    }

    /**********************************************
     * Support for [$(I index)] operation for BitArray.
     */
    bool opIndex(size_t i)
    in
    {
	assert(i < len);
    }
    body
    {
	return cast(bool)bt(ptr, i);
    }

    /** ditto */
    bool opIndexAssign(bool b, size_t i)
    in
    {
	assert(i < len);
    }
    body
    {
	if (b)
	    bts(ptr, i);
	else
	    btr(ptr, i);
	return b;
    }

    /**********************************************
     * Support for array.dup property for BitArray.
     */
	 МассивБит дубль()
	 {
	 return dup();
	 }
	 
    BitArray dup()
    {
	BitArray ba;

	uint[] b = ptr[0 .. dim].dup;
	ba.len = len;
	ba.ptr = b.ptr;
	return ba;
    }

    unittest
    {
	BitArray a;
	BitArray b;
	int i;

	debug(bitarray) эхо("BitArray.dup.unittest\n");

	a.length = 3;
	a[0] = 1; a[1] = 0; a[2] = 1;
	b = a.dup;
	assert(b.length == 3);
	for (i = 0; i < 3; i++)
	{   debug(bitarray) эхо("b[%d] = %d\n", i, b[i]);
	    assert(b[i] == (((i ^ 1) & 1) ? true : false));
	}
    }

    /**********************************************
     * Support for foreach loops for BitArray.
     */
    int opApply(int delegate(inout bool) дг)
    {
	int результат;

	for (size_t i = 0; i < len; i++)
	{   bool b = opIndex(i);
	    результат = дг(b);
	    (*this)[i] = b;
	    if (результат)
		break;
	}
	return результат;
    }

    /** ditto */
    int opApply(int delegate(inout size_t, inout bool) дг)
    {
	int результат;

	for (size_t i = 0; i < len; i++)
	{   bool b = opIndex(i);
	    результат = дг(i, b);
	    (*this)[i] = b;
	    if (результат)
		break;
	}
	return результат;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opApply unittest\n");

	static bool[] ba = [1,0,1];

	BitArray a; a.init(ba);

	int i;
	foreach (b;a)
	{
	    switch (i)
	    {	case 0: assert(b == true); break;
		case 1: assert(b == false); break;
		case 2: assert(b == true); break;
		default: assert(0);
	    }
	    i++;
	}

	foreach (j,b;a)
	{
	    switch (j)
	    {	case 0: assert(b == true); break;
		case 1: assert(b == false); break;
		case 2: assert(b == true); break;
		default: assert(0);
	    }
	}
    }


    /**********************************************
     * Support for array.reverse property for BitArray.
     */
	МассивБит реверсни()
	{
	return  reverse();
	}
	
    BitArray reverse()
	out (результат)
	{
	    assert(результат == *this);
	}
	body
	{
	    if (len >= 2)
	    {
		bool t;
		size_t lo, hi;

		lo = 0;
		hi = len - 1;
		for (; lo < hi; lo++, hi--)
		{
		    t = (*this)[lo];
		    (*this)[lo] = (*this)[hi];
		    (*this)[hi] = t;
		}
	    }
	    return *this;
	}

    unittest
    {
	debug(bitarray) эхо("BitArray.reverse.unittest\n");

	BitArray b;
	static bool[5] data = [1,0,1,1,0];
	int i;

	b.init(data);
	b.reverse;
	for (i = 0; i < data.length; i++)
	{
	    assert(b[i] == data[4 - i]);
	}
    }


    /**********************************************
     * Support for array.sort property for BitArray.
     */
	МассивБит сортируй()
	{
	return sort();
	}
	
    BitArray sort()
	out (результат)
	{
	    assert(результат == *this);
	}
	body
	{
	    if (len >= 2)
	    {
		size_t lo, hi;

		lo = 0;
		hi = len - 1;
		while (1)
		{
		    while (1)
		    {
			if (lo >= hi)
			    goto Ldone;
			if ((*this)[lo] == true)
			    break;
			lo++;
		    }

		    while (1)
		    {
			if (lo >= hi)
			    goto Ldone;
			if ((*this)[hi] == false)
			    break;
			hi--;
		    }

		    (*this)[lo] = false;
		    (*this)[hi] = true;

		    lo++;
		    hi--;
		}
	    Ldone:
		;
	    }
	    return *this;
	}

    unittest
    {
	debug(bitarray) эхо("BitArray.sort.unittest\n");

	static uint x = 0b1100011000;
	static BitArray ba = { 10, &x };
	ba.sort;
	for (size_t i = 0; i < 6; i++)
	    assert(ba[i] == false);
	for (size_t i = 6; i < 10; i++)
	    assert(ba[i] == true);
    }


    /***************************************
     * Support for operators == and != for bit arrays.
     */

    int opEquals(BitArray a2)
    {   int i;

	if (this.length != a2.length)
	    return 0;		// not equal
	byte *p1 = cast(byte*)this.ptr;
	byte *p2 = cast(byte*)a2.ptr;
	uint n = this.length / 8;
	for (i = 0; i < n; i++)
	{
	    if (p1[i] != p2[i])
		return 0;		// not equal
	}

	ubyte маска;

	n = this.length & 7;
	маска = cast(ubyte)((1 << n) - 1);
	//эхо("i = %d, n = %d, маска = %x, %x, %x\n", i, n, маска, p1[i], p2[i]);
	return (маска == 0) || (p1[i] & маска) == (p2[i] & маска);
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opEquals unittest\n");

	static bool[] ba = [1,0,1,0,1];
	static bool[] bb = [1,0,1];
	static bool[] bc = [1,0,1,0,1,0,1];
	static bool[] bd = [1,0,1,1,1];
	static bool[] be = [1,0,1,0,1];

	BitArray a; a.init(ba);
	BitArray b; b.init(bb);
	BitArray c; c.init(bc);
	BitArray d; d.init(bd);
	BitArray e; e.init(be);

	assert(a != b);
	assert(a != c);
	assert(a != d);
	assert(a == e);
    }

    /***************************************
     * Implement comparison operators.
     */

    int opCmp(BitArray a2)
    {
	uint len;
	uint i;

	len = this.length;
	if (a2.length < len)
	    len = a2.length;
	ubyte* p1 = cast(ubyte*)this.ptr;
	ubyte* p2 = cast(ubyte*)a2.ptr;
	uint n = len / 8;
	for (i = 0; i < n; i++)
	{
	    if (p1[i] != p2[i])
		break;		// not equal
	}
	for (uint j = i * 8; j < len; j++)
	{   ubyte маска = cast(ubyte)(1 << j);
	    int c;

	    c = cast(int)(p1[i] & маска) - cast(int)(p2[i] & маска);
	    if (c)
		return c;
	}
	return cast(int)this.len - cast(int)a2.length;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opCmp unittest\n");

	static bool[] ba = [1,0,1,0,1];
	static bool[] bb = [1,0,1];
	static bool[] bc = [1,0,1,0,1,0,1];
	static bool[] bd = [1,0,1,1,1];
	static bool[] be = [1,0,1,0,1];

	BitArray a; a.init(ba);
	BitArray b; b.init(bb);
	BitArray c; c.init(bc);
	BitArray d; d.init(bd);
	BitArray e; e.init(be);

	assert(a >  b);
	assert(a >= b);
	assert(a <  c);
	assert(a <= c);
	assert(a <  d);
	assert(a <= d);
	assert(a == e);
	assert(a <= e);
	assert(a >= e);
    }

    /***************************************
     * Set BitArray to contents of ba[]
     */
	проц иниц(бул[] бм)
	{
	init(cast(bool[]) бм);
	}
	
    void init(bool[] ba)
    {
	length = ba.length;
	foreach (i, b; ba)
	{
	    (*this)[i] = b;
	}
    }


    /***************************************
     * Map BitArray onto v[], with numbits being the number of bits
     * in the array. Does not copy the data.
     *
     * This is the inverse of opCast.
     */
	 проц иниц(проц[] в, т_мера члобит)
	{
	init(cast(void[]) в, cast(size_t) члобит);
	}
	
    void init(void[] v, size_t numbits)
    in
    {
	assert(numbits <= v.length * 8);
	assert((v.length & 3) == 0);
    }
    body
    {
	ptr = cast(uint*)v.ptr;
	len = numbits;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.init unittest\n");

	static bool[] ba = [1,0,1,0,1];

	BitArray a; a.init(ba);
	BitArray b;
	void[] v;

	v = cast(void[])a;
	b.init(v, a.length);

	assert(b[0] == 1);
	assert(b[1] == 0);
	assert(b[2] == 1);
	assert(b[3] == 0);
	assert(b[4] == 1);

	a[0] = 0;
	assert(b[0] == 0);

	assert(a == b);
    }

    /***************************************
     * Convert to void[].
     */
    void[] opCast()
    {
	return cast(void[])ptr[0 .. dim];
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opCast unittest\n");

	static bool[] ba = [1,0,1,0,1];

	BitArray a; a.init(ba);
	void[] v = cast(void[])a;

	assert(v.length == a.dim * uint.sizeof);
    }

    /***************************************
     * Support for unary operator ~ for bit arrays.
     */
    BitArray opCom()
    {
	auto dim = this.dim();

	BitArray результат;

	результат.length = len;
	for (size_t i = 0; i < dim; i++)
	    результат.ptr[i] = ~this.ptr[i];
	if (len & 31)
	    результат.ptr[dim - 1] &= ~(~0 << (len & 31));
	return результат;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opCom unittest\n");

	static bool[] ba = [1,0,1,0,1];

	BitArray a; a.init(ba);
	BitArray b = ~a;

	assert(b[0] == 0);
	assert(b[1] == 1);
	assert(b[2] == 0);
	assert(b[3] == 1);
	assert(b[4] == 0);
    }


    /***************************************
     * Support for binary operator & for bit arrays.
     */
    BitArray opAnd(BitArray e2)
    in
    {
	assert(len == e2.length);
    }
    body
    {
	auto dim = this.dim();

	BitArray результат;

	результат.length = len;
	for (size_t i = 0; i < dim; i++)
	    результат.ptr[i] = this.ptr[i] & e2.ptr[i];
	return результат;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opAnd unittest\n");

	static bool[] ba = [1,0,1,0,1];
	static bool[] bb = [1,0,1,1,0];

	BitArray a; a.init(ba);
	BitArray b; b.init(bb);

	BitArray c = a & b;

	assert(c[0] == 1);
	assert(c[1] == 0);
	assert(c[2] == 1);
	assert(c[3] == 0);
	assert(c[4] == 0);
    }


    /***************************************
     * Support for binary operator | for bit arrays.
     */
    BitArray opOr(BitArray e2)
    in
    {
	assert(len == e2.length);
    }
    body
    {
	auto dim = this.dim();

	BitArray результат;

	результат.length = len;
	for (size_t i = 0; i < dim; i++)
	    результат.ptr[i] = this.ptr[i] | e2.ptr[i];
	return результат;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opOr unittest\n");

	static bool[] ba = [1,0,1,0,1];
	static bool[] bb = [1,0,1,1,0];

	BitArray a; a.init(ba);
	BitArray b; b.init(bb);

	BitArray c = a | b;

	assert(c[0] == 1);
	assert(c[1] == 0);
	assert(c[2] == 1);
	assert(c[3] == 1);
	assert(c[4] == 1);
    }


    /***************************************
     * Support for binary operator ^ for bit arrays.
     */
    BitArray opXor(BitArray e2)
    in
    {
	assert(len == e2.length);
    }
    body
    {
	auto dim = this.dim();

	BitArray результат;

	результат.length = len;
	for (size_t i = 0; i < dim; i++)
	    результат.ptr[i] = this.ptr[i] ^ e2.ptr[i];
	return результат;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opXor unittest\n");

	static bool[] ba = [1,0,1,0,1];
	static bool[] bb = [1,0,1,1,0];

	BitArray a; a.init(ba);
	BitArray b; b.init(bb);

	BitArray c = a ^ b;

	assert(c[0] == 0);
	assert(c[1] == 0);
	assert(c[2] == 0);
	assert(c[3] == 1);
	assert(c[4] == 1);
    }


    /***************************************
     * Support for binary operator - for bit arrays.
     *
     * $(I a - b) for BitArrays means the same thing as $(I a &amp; ~b).
     */
    BitArray opSub(BitArray e2)
    in
    {
	assert(len == e2.length);
    }
    body
    {
	auto dim = this.dim();

	BitArray результат;

	результат.length = len;
	for (size_t i = 0; i < dim; i++)
	    результат.ptr[i] = this.ptr[i] & ~e2.ptr[i];
	return результат;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opSub unittest\n");

	static bool[] ba = [1,0,1,0,1];
	static bool[] bb = [1,0,1,1,0];

	BitArray a; a.init(ba);
	BitArray b; b.init(bb);

	BitArray c = a - b;

	assert(c[0] == 0);
	assert(c[1] == 0);
	assert(c[2] == 0);
	assert(c[3] == 0);
	assert(c[4] == 1);
    }


    /***************************************
     * Support for operator &= bit arrays.
     */
    BitArray opAndAssign(BitArray e2)
    in
    {
	assert(len == e2.length);
    }
    body
    {
	auto dim = this.dim();

	for (size_t i = 0; i < dim; i++)
	    ptr[i] &= e2.ptr[i];
	return *this;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opAndAssign unittest\n");

	static bool[] ba = [1,0,1,0,1];
	static bool[] bb = [1,0,1,1,0];

	BitArray a; a.init(ba);
	BitArray b; b.init(bb);

	a &= b;
	assert(a[0] == 1);
	assert(a[1] == 0);
	assert(a[2] == 1);
	assert(a[3] == 0);
	assert(a[4] == 0);
    }


    /***************************************
     * Support for operator |= for bit arrays.
     */
    BitArray opOrAssign(BitArray e2)
    in
    {
	assert(len == e2.length);
    }
    body
    {
	auto dim = this.dim();

	for (size_t i = 0; i < dim; i++)
	    ptr[i] |= e2.ptr[i];
	return *this;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opOrAssign unittest\n");

	static bool[] ba = [1,0,1,0,1];
	static bool[] bb = [1,0,1,1,0];

	BitArray a; a.init(ba);
	BitArray b; b.init(bb);

	a |= b;
	assert(a[0] == 1);
	assert(a[1] == 0);
	assert(a[2] == 1);
	assert(a[3] == 1);
	assert(a[4] == 1);
    }

    /***************************************
     * Support for operator ^= for bit arrays.
     */
    BitArray opXorAssign(BitArray e2)
    in
    {
	assert(len == e2.length);
    }
    body
    {
	auto dim = this.dim();

	for (size_t i = 0; i < dim; i++)
	    ptr[i] ^= e2.ptr[i];
	return *this;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opXorAssign unittest\n");

	static bool[] ba = [1,0,1,0,1];
	static bool[] bb = [1,0,1,1,0];

	BitArray a; a.init(ba);
	BitArray b; b.init(bb);

	a ^= b;
	assert(a[0] == 0);
	assert(a[1] == 0);
	assert(a[2] == 0);
	assert(a[3] == 1);
	assert(a[4] == 1);
    }

    /***************************************
     * Support for operator -= for bit arrays.
     *
     * $(I a -= b) for BitArrays means the same thing as $(I a &amp;= ~b).
     */
    BitArray opSubAssign(BitArray e2)
    in
    {
	assert(len == e2.length);
    }
    body
    {
	auto dim = this.dim();

	for (size_t i = 0; i < dim; i++)
	    ptr[i] &= ~e2.ptr[i];
	return *this;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opSubAssign unittest\n");

	static bool[] ba = [1,0,1,0,1];
	static bool[] bb = [1,0,1,1,0];

	BitArray a; a.init(ba);
	BitArray b; b.init(bb);

	a -= b;
	assert(a[0] == 0);
	assert(a[1] == 0);
	assert(a[2] == 0);
	assert(a[3] == 0);
	assert(a[4] == 1);
    }

    /***************************************
     * Support for operator ~= for bit arrays.
     */

    BitArray opCatAssign(bool b)
    {
	length = len + 1;
	(*this)[len - 1] = b;
	return *this;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opCatAssign unittest\n");

	static bool[] ba = [1,0,1,0,1];

	BitArray a; a.init(ba);
	BitArray b;

	b = (a ~= true);
	assert(a[0] == 1);
	assert(a[1] == 0);
	assert(a[2] == 1);
	assert(a[3] == 0);
	assert(a[4] == 1);
	assert(a[5] == 1);

	assert(b == a);
    }

    /***************************************
     * ditto
     */

    BitArray opCatAssign(BitArray b)
    {
	auto istart = len;
	length = len + b.length;
	for (auto i = istart; i < len; i++)
	    (*this)[i] = b[i - istart];
	return *this;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opCatAssign unittest\n");

	static bool[] ba = [1,0];
	static bool[] bb = [0,1,0];

	BitArray a; a.init(ba);
	BitArray b; b.init(bb);
	BitArray c;

	c = (a ~= b);
	assert(a.length == 5);
	assert(a[0] == 1);
	assert(a[1] == 0);
	assert(a[2] == 0);
	assert(a[3] == 1);
	assert(a[4] == 0);

	assert(c == a);
    }

    /***************************************
     * Support for binary operator ~ for bit arrays.
     */
    BitArray opCat(bool b)
    {
	BitArray r;

	r = this.dup;
	r.length = len + 1;
	r[len] = b;
	return r;
    }

    /** ditto */
    BitArray opCat_r(bool b)
    {
	BitArray r;

	r.length = len + 1;
	r[0] = b;
	for (size_t i = 0; i < len; i++)
	    r[1 + i] = (*this)[i];
	return r;
    }

    /** ditto */
    BitArray opCat(BitArray b)
    {
	BitArray r;

	r = this.dup();
	r ~= b;
	return r;
    }

    unittest
    {
	debug(bitarray) эхо("BitArray.opCat unittest\n");

	static bool[] ba = [1,0];
	static bool[] bb = [0,1,0];

	BitArray a; a.init(ba);
	BitArray b; b.init(bb);
	BitArray c;

	c = (a ~ b);
	assert(c.length == 5);
	assert(c[0] == 1);
	assert(c[1] == 0);
	assert(c[2] == 0);
	assert(c[3] == 1);
	assert(c[4] == 0);

	c = (a ~ true);
	assert(c.length == 3);
	assert(c[0] == 1);
	assert(c[1] == 0);
	assert(c[2] == 1);

	c = (false ~ a);
	assert(c.length == 3);
	assert(c[0] == 0);
	assert(c[1] == 1);
	assert(c[2] == 0);
    }
}
