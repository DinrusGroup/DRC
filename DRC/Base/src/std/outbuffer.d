﻿// Written in the D programming language

/**
 * Boilerplate:
 *	$(std_boilerplate.html)
 * Macros:
 *	WIKI = Phobos/StdOutbuffer
 * Copyright:
 *	Copyright (c) 2001-2005 by Digital Mars
 *	All Rights Reserved
 *	www.digitalmars.com
 */


// Written by Walter Bright

module std.outbuffer;

private
{
    import std.string;
    import runtime;
    import cidrus;	
}

/*********************************************
 * OutBuffer provides a way to build up an array of bytes out
 * of raw data. It is useful for things like preparing an
 * array of bytes to write out to a file.
 * OutBuffer's byte order is the format native to the computer.
 * To control the byte order (endianness), use a class derived
 * from OutBuffer.
 */
alias OutBuffer БуферВывода;

class OutBuffer
{
alias data данные;
alias offset смещение;
alias toBytes вБайты;
alias reserve врезерв;
alias write пиши;
alias fill0 занули;
alias alignSize раскладиРазм;
alias align2 расклад2;
alias align4 расклад4;
alias toString вТкст;
alias vprintf ввыводф;
alias эхо выводф;
alias spread простели;

    ubyte data[];
    uint offset;

    invariant
    {
	//эхо("this = %p, offset = %x, data.length = %u\n", this, offset, data.length);
	assert(offset <= data.length);
	assert(data.length <= runtime.capacity(data.ptr));
    }

    this()
    {
	//эхо("in OutBuffer constructor\n");
    }

    /*********************************
     * Convert to array of bytes.
     */

    ubyte[] toBytes() { return data[0 .. offset]; }

    /***********************************
     * Preallocate nbytes more to the size of the internal buffer.
     *
     * This is a
     * speed optimization, a good guess at the maximum size of the resulting
     * buffer will improve performance by eliminating reallocations and copying.
     */


    void reserve(uint nbytes)
	in
	{
	    assert(offset + nbytes >= offset);
	}
	out
	{
	    assert(offset + nbytes <= data.length);
	    assert(data.length <= runtime.capacity(data.ptr));
	}
	body
	{
	    if (data.length < offset + nbytes)
	    {
		//cidrus.эхо("OutBuffer.reserve: ptr = %p, length = %d, offset = %d, nbytes = %d, capacity = %d\n", data.ptr, data.length, offset, nbytes, runtime.capacity(data.ptr));
		data.length = (offset + nbytes) * 2;
		//cidrus.эхо("OutBuffer.reserve: ptr = %p, length = %d, capacity = %d\n", data.ptr, data.length, runtime.capacity(data.ptr));
		runtime.hasPointers(data.ptr);
	    }
	}

    /*************************************
     * Append data to the internal buffer.
     */

    void write(ubyte[] bytes)
	{
	    reserve(bytes.length);
	    data[offset .. offset + bytes.length] = bytes;
	    offset += bytes.length;
	}

    void write(ubyte b)		/// ditto
	{
	    reserve(ubyte.sizeof);
	    this.data[offset] = b;
	    offset += ubyte.sizeof;
	}

    void write(byte b) { write(cast(ubyte)b); }		/// ditto
    void write(char c) { write(cast(ubyte)c); }		/// ditto

    void write(ushort w)		/// ditto
    {
	reserve(ushort.sizeof);
	*cast(ushort *)&data[offset] = w;
	offset += ushort.sizeof;
    }

    void write(short s) { write(cast(ushort)s); }		/// ditto

    void write(wchar c)		/// ditto
    {
	reserve(wchar.sizeof);
	*cast(wchar *)&data[offset] = c;
	offset += wchar.sizeof;
    }

    void write(uint w)		/// ditto
    {
	reserve(uint.sizeof);
	*cast(uint *)&data[offset] = w;
	offset += uint.sizeof;
    }

    void write(int i) { write(cast(uint)i); }		/// ditto

    void write(ulong l)		/// ditto
    {
	reserve(ulong.sizeof);
	*cast(ulong *)&data[offset] = l;
	offset += ulong.sizeof;
    }

    void write(long l) { write(cast(ulong)l); }		/// ditto

    void write(float f)		/// ditto
    {
	reserve(float.sizeof);
	*cast(float *)&data[offset] = f;
	offset += float.sizeof;
    }

    void write(double f)		/// ditto
    {
	reserve(double.sizeof);
	*cast(double *)&data[offset] = f;
	offset += double.sizeof;
    }

    void write(real f)		/// ditto
    {
	reserve(real.sizeof);
	*cast(real *)&data[offset] = f;
	offset += real.sizeof;
    }

    void write(string s)		/// ditto
    {
	write(cast(ubyte[])s);
    }

    void write(OutBuffer buf)		/// ditto
    {
	write(buf.toBytes());
    }

    /****************************************
     * Append nbytes of 0 to the internal buffer.
     */

    void fill0(uint nbytes)
    {
	reserve(nbytes);
	data[offset .. offset + nbytes] = 0;
	offset += nbytes;
    }

    /**********************************
     * 0-fill to align on power of 2 boundary.
     */

    void alignSize(uint alignsize)
    in
    {
	assert(alignsize && (alignsize & (alignsize - 1)) == 0);
    }
    out
    {
	assert((offset & (alignsize - 1)) == 0);
    }
    body
    {   uint nbytes;

	nbytes = offset & (alignsize - 1);
	if (nbytes)
	    fill0(alignsize - nbytes);
    }

    /****************************************
     * Optimize common special case alignSize(2)
     */

    void align2()
    {
	if (offset & 1)
	    write(cast(byte)0);
    }

    /****************************************
     * Optimize common special case alignSize(4)
     */

    void align4()
    {
	if (offset & 3)
	{   uint nbytes = (4 - offset) & 3;
	    fill0(nbytes);
	}
    }

    /**************************************
     * Convert internal buffer to array of chars.
     */

    char[] toString()
    {
	//эхо("OutBuffer.toString()\n");
	return cast(char[])data[0 .. offset];
    }

    /*****************************************
     * Append output of C's vprintf() to internal buffer.
     */
    void vprintf(string format, va_list args)
    {
	char[128] buffer;
	char* p;
	uint psize;
	int count;

	auto f = toStringz(format);
	p = buffer.ptr;
	psize = buffer.length;
	for (;;)
	{
	    version(Win32)
	    {
		count = _vsnprintf(p,psize,f,args);
		if (count != -1)
		    break;
		psize *= 2;
		p = cast(char *) cidrus.разместа(psize);	// buffer too small, try again with larger size
	    }
	    version(Posix)
	    {
		count = vsnprintf(p,psize,f,args);
		if (count == -1)
		    psize *= 2;
		else if (count >= psize)
		    psize = count + 1;
		else
		    break;
		/+
		if (p != buffer)
		    c.stdlib.free(p);
		p = (char *) c.stdlib.malloc(psize);	// buffer too small, try again with larger size
		+/
		p = cast(char *) разместа(psize);	// buffer too small, try again with larger size
	    }
	}
	write(p[0 .. count]);
	/+
	version (Posix)
	{
	    if (p != buffer)
		c.stdlib.free(p);
	}
	+/
    }

    /*****************************************
     * Append output of C's эхо() to internal buffer.
     */

    void эхо(string format, ...)
    {
	va_list ap;
	ap = cast(va_list)&format;
	ap += format.sizeof;
	vprintf(format, ap);
    }

    /*****************************************
     * At offset index into buffer, create nbytes of space by shifting upwards
     * all data past index.
     */

    void spread(uint index, uint nbytes)
	in
	{
	    assert(index <= offset);
	}
	body
	{
	    reserve(nbytes);

	    // This is an overlapping copy - should use memmove()
	    for (uint i = offset; i > index; )
	    {
		--i;
		data[i + nbytes] = data[i];
	    }
	    offset += nbytes;
	}
}

unittest
{
    //эхо("Starting OutBuffer test\n");

    OutBuffer buf = new OutBuffer();

    //эхо("buf = %p\n", buf);
    //эхо("buf.offset = %x\n", buf.offset);
    assert(buf.offset == 0);
    buf.write("hello");
    buf.write(cast(byte)0x20);
    buf.write("world");
    buf.эхо(" %d", 6);
    //эхо("buf = '%.*s'\n", buf.toString());
    assert(cmp(buf.toString(), "hello world 6") == 0);
}
