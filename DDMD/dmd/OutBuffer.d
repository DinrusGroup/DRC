module dmd.OutBuffer;

import dmd.common;
import core.vararg;
import std.exception;
static import std.string;

import core.stdc.stdlib;
import core.stdc.string;

import core.memory;
import core.stdc.stdlib;

import dmd.TObject;

class OutBuffer : TObject
{
    ubyte* data;
    uint offset;
    uint size;

    this()
	{
		register();
		// do nothing
	}

    final void* extractData()
	{
		void* p = cast(void*)data;

		data = null;
		offset = 0;
		size = 0;

		return p;
	}

    void mark()
	{
		assert(false);
	}

    final void reserve(uint nbytes)
	{
		//printf("OutBuffer::reserve: size = %d, offset = %d, nbytes = %d\n", size, offset, nbytes);
		if (size - offset < nbytes)
		{
			size = (offset + nbytes) * 2;
			data = cast(ubyte*)realloc(data, size);
		}
	}
	
    final void setsize(uint size)
	{
		assert(false);
	}
	
    final void reset()
	{
		offset = 0;
	}
	
    final void write(const(void)* data, uint nbytes)
	{
		reserve(nbytes);
		memcpy(this.data + offset, data, nbytes);
		offset += nbytes;
	}
	
    final void writebstring(ubyte* string_)
	{
		assert(false);
	}
	
    final void writestring(const(char)[] string_)
	{
		write(string_.ptr , string_.length);
	}
	
    final void writedstring(const(char)* string_)
	{
		assert(false);
	}
	
    final void writedstring(const(wchar)* string_)
	{
		assert(false);
	}
	
    final void prependstring(const(char)[] string_)
	{
		uint len = string_.length;
		reserve(len);
		memmove(data + len, data, offset);
		memcpy(data, string_.ptr, len);
		offset += len;
	}
	
    final void writenl()			// write newline
	{
version (Windows)
{
	version (M_UNICODE)
	{
		write4(0x000A000D);		// newline is CR,LF on Microsoft OS's
	}
	else
	{
		writeword(0x0A0D);		// newline is CR,LF on Microsoft OS's
	}
}
else
{
	version (M_UNICODE)
	{
		writeword('\n');
	}
	else
	{
		writeByte('\n');
	}
}
	}
	
    final void writeByte(uint b)
	{
		reserve(1);
		this.data[offset] = cast(ubyte)b;
		offset++;
	}
	
    final void writebyte(uint b) { writeByte(b); }
    
	final void writeUTF8(uint b)
	{
		reserve(6);
		if (b <= 0x7F)
		{
			this.data[offset] = cast(ubyte)b;
			offset++;
		}
		else if (b <= 0x7FF)
		{
			this.data[offset + 0] = cast(ubyte)((b >> 6) | 0xC0);
			this.data[offset + 1] = cast(ubyte)((b & 0x3F) | 0x80);
			offset += 2;
		}
		else if (b <= 0xFFFF)
		{
			this.data[offset + 0] = cast(ubyte)((b >> 12) | 0xE0);
			this.data[offset + 1] = cast(ubyte)(((b >> 6) & 0x3F) | 0x80);
			this.data[offset + 2] = cast(ubyte)((b & 0x3F) | 0x80);
			offset += 3;
		}
		else if (b <= 0x1FFFFF)
		{
			this.data[offset + 0] = cast(ubyte)((b >> 18) | 0xF0);
			this.data[offset + 1] = cast(ubyte)(((b >> 12) & 0x3F) | 0x80);
			this.data[offset + 2] = cast(ubyte)(((b >> 6) & 0x3F) | 0x80);
			this.data[offset + 3] = cast(ubyte)((b & 0x3F) | 0x80);
			offset += 4;
		}
		else if (b <= 0x3FFFFFF)
		{
			this.data[offset + 0] = cast(ubyte)((b >> 24) | 0xF8);
			this.data[offset + 1] = cast(ubyte)(((b >> 18) & 0x3F) | 0x80);
			this.data[offset + 2] = cast(ubyte)(((b >> 12) & 0x3F) | 0x80);
			this.data[offset + 3] = cast(ubyte)(((b >> 6) & 0x3F) | 0x80);
			this.data[offset + 4] = cast(ubyte)((b & 0x3F) | 0x80);
			offset += 5;
		}
		else if (b <= 0x7FFFFFFF)
		{
			this.data[offset + 0] = cast(ubyte)((b >> 30) | 0xFC);
			this.data[offset + 1] = cast(ubyte)(((b >> 24) & 0x3F) | 0x80);
			this.data[offset + 2] = cast(ubyte)(((b >> 18) & 0x3F) | 0x80);
			this.data[offset + 3] = cast(ubyte)(((b >> 12) & 0x3F) | 0x80);
			this.data[offset + 4] = cast(ubyte)(((b >> 6) & 0x3F) | 0x80);
			this.data[offset + 5] = cast(ubyte)((b & 0x3F) | 0x80);
			offset += 6;
		}
		else
			assert(0);
	}
	
    final void writedchar(uint b)
	{
		assert(false);
	}
	
    final void prependbyte(uint b)
	{
		assert(false);
	}

    final void writeword(uint w)
	{
		reserve(2);
		*cast(ushort*)(this.data + offset) = cast(ushort)w;
		offset += 2;
	}
	
    final void writeUTF16(uint w)
	{
		reserve(4);
		if (w <= 0xFFFF)
		{
			*cast(ushort*)(this.data + offset) = cast(ushort)w;
			offset += 2;
		}
		else if (w <= 0x10FFFF)
		{
			*cast(ushort*)(this.data + offset) = cast(ushort)((w >> 10) + 0xD7C0);
			*cast(ushort*)(this.data + offset + 2) = cast(ushort)((w & 0x3FF) | 0xDC00);
			offset += 4;
		}
		else
			assert(0);
	}
	
    final void write4(uint w)
	{
		reserve(4);
		*cast(uint*)(this.data + offset) = w;
		offset += 4;
	}
	
    final void write(OutBuffer buf)
	{
		if (buf)
		{	
			reserve(buf.offset);
			memcpy(data + offset, buf.data, buf.offset);
			offset += buf.offset;
		}
	}
	
    final void write(Object obj)
	{
		assert(false);
	}
	
    final void fill0(uint nbytes)
	{
		reserve(nbytes);
		memset(data + offset, 0, nbytes);
		offset += nbytes;
	}
	
    final void align_(uint size)
	{
		assert(false);
	}
	
	void vprintf(const(char)* format, va_list args)
	{
		assert(false);
	}

	void printf(T...)(string format, T t)
	{
		string s = std.string.format(format, t);
		writestring(s);
	}

version (M_UNICODE) {
///    void vprintf(const uint short *format, va_list args);
///    void printf(const uint short *format, ...);
}
    final void bracket(char left, char right)
	{
		assert(false);
	}
	
    final uint bracket(uint i, const(char)* left, uint j, const(char)* right)
	{
		assert(false);
	}
	
    final void spread(uint offset, uint nbytes)
	{
		assert(false);
	}
	
    final uint insert(uint offset, const(void)* data, uint nbytes)
	{
		assert(false);
	}
	
    final void remove(uint offset, uint nbytes)
	{
		assert(false);
	}
	
    string toChars()
	{
	   char[] s = getString();
	   char* copy = cast(char*)GC.malloc(s.length);
	   memcpy(copy, s.ptr, s.length);
	   return assumeUnique(copy[0..s.length]);

		//return getString().idup;
	}

    final string extractString()
	{
		char[] s = getString();
		data = null;
		offset = 0;
		size = 0;

		return assumeUnique(s);
	}

	final char[] getString()
	{
		char* s = cast(char*)data;
		return s[0..offset];
	}
}