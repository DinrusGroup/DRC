/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.internal.stdlib : Tango <-> Phobos bridge.
*/

module kong.internal.stdlib;





interface io_stream
{
    void[] map(size_t);
    void[] map(size_t, size_t);

    void copy(void*, size_t);
    void copy(void*, size_t, size_t);
    void write(void*, size_t, size_t);
    void write(void*, size_t);

    size_t size();
    size_t позиция();
    void позиция(size_t);

    char getc();
    void commit();
    void close();
}

struct copy_block    { size_t offset; ubyte[] data; }
struct aligned_block { size_t offset; size_t size; size_t growth; }


class memory_stream : io_stream
{
    ubyte* base_address;  // current data
    ulong pos;  // current file позиция

    /// Create the stream for the the buffer buf. Non-copying.
    this(void* base_address)
    {
        if (base_address == пусто)
            throw new Exception("Invalid base address");

        this.base_address = cast(ubyte*) base_address;
    }

    void[] map(size_t A, size_t B){ pos = B; return this.map(A);}
    void   copy(void* A, size_t B, size_t C){ pos = C; this.copy(A, B); }
    void  write(void* A, size_t B, size_t C){ pos = C; this.write(A, B); }

    void[] map(size_t size)
    {
        void[] block = base_address[pos .. pos + size];
        pos += size;

        return block;
    }

    void
    copy(void* A, size_t size)
    {
        void* B = cast(void*) (cast(size_t) base_address + cast(size_t) pos);
        A[0 .. size] = B[0 .. size];
        pos += size;
    }

    void write(void* A, size_t size)
    {
        void* B = cast(void*) (cast(size_t) base_address + cast(size_t) pos);
        B[0 .. size] = A[0 .. size];
        pos += size;
        //return size;
    }

    size_t позиция(){ return pos; }
    void позиция(size_t pos){ this.pos = pos; }

    char getc()
    {
        return cast(char) base_address[pos];
    }

    void commit(){ return; }
    void close(){ return; }

    size_t size(){ throw new Exception("Operation not supported"); }
}



enum IO_MODE { R = 0b10, W = 0b11, RW = R|W };

class copy_stream : io_stream
{
    copy_block[void*] memory;

    void[] map(size_t size, size_t offset)
    {
        copy_block b;

        b.offset      = offset;
        b.data.length = size;

        this.copy(b.data.ptr, b.data.length, b.offset);

        memory[b.data.ptr] = b;
        return b.data;
    }

    void[] map(size_t size)
        { return this.map(size, позиция()); }


    void commit()
    {
        foreach (ref copy_block b; memory)
            this.write(b.data.ptr, b.data.length, b.offset);
    }

    abstract void close();
    abstract void copy(void*, size_t);
    abstract void copy(void*, size_t, size_t);
    abstract void write(void*, size_t, size_t);
    abstract void write(void*, size_t);
    abstract size_t size();
    abstract size_t позиция();
    abstract void позиция(size_t);
    abstract char getc();
}




version (Tango)
{
    //alias char[] string;

    public import tango.stdc.inttypes;
    public import tango.stdc.string;
    public import tango.text.convert.Integer;

    public import tango.util.PathUtil;
    public import tango.stdc.stringz;
    public import tango.text.convert.Sprint;
    public import tango.io.Stdout;
    public import tango.text.Util;
    public import tango.stdc.posix.stdlib;
    public import kong.internal.stdfmt;

    import tango.io.stream.LineStream;
    import tango.io.stream.FileStream;
    import tango.io.FileConduit;
    import tango.io.stream.GreedyStream;

    enum Endian { LittleEndian, BigEndian }

    version (BigEndian)         const int endian = Endian.BigEndian;
    else version (LittleEndian) const int endian = Endian.LittleEndian;



    alias tango.util.PathUtil.patternMatch path_match;

    template print(string fmt)
    {
        void print(T...)(T t){ Stdout.formatln(FMT!(fmt), t); }
    }


    class file_stream : copy_stream
    {
        FileConduit file;
        GreedyInput input;
        GreedyOutput output;

        this(string path, IO_MODE mode = IO_MODE.R)
        {
            FileConduit.Style settings;

            settings.open  = FileConduit.Open.Exists;
            settings.cache = FileConduit.Cache.Random;
            settings.share = FileConduit.Share.ReadWrite; // TODO: consider this.

            if (mode == IO_MODE.RW)
                settings.access = FileConduit.Access.ReadWrite;

            else if (mode == IO_MODE.R)
                settings.access = FileConduit.Access.Read;

            else if (mode == IO_MODE.W)
                settings.access = FileConduit.Access.Write;

            this.file = new FileConduit(path, settings);
            input     = new GreedyInput(file);
            output    = new GreedyOutput(file);
        }


        void copy(void* A, size_t B, size_t C)
            { file.seek(C); this.copy(A, B); }

        void write(void* A, size_t B, size_t C)
            { file.seek(C); this.write(A, B); }

        void copy(void* A, size_t size)
            { input.readExact(A[0..size]); }

        void write(void* A, size_t size)
            { output.writeExact(A[0..size]); }

        size_t позиция()
            { return file.позиция(); }

        void позиция(size_t pos)
            { file.seek(pos); }

        size_t size()
            { return file.length(); }

        void close()
            { return file.close(); }

        char getc()
        {
            // TODO: buffering
            char c;
            this.copy(&c, 1);

            return c;
        }

    }



    void
    file_parse(string path, void delegate(string) handler)
    {
        auto input = new LineInput(new FileInput(path));

        foreach (line; input)
            handler(line);

        input.close;
    }


    char[] squeeze(char[] s, char[] pattern = пусто)
    {
        char[] r = s;
        dchar lastc;
        size_t lasti;
        int run;
        bool changed;

        bool inPattern(dchar c, char[] pattern)
        {
            bool result = false;
            int range = 0;
            dchar lastc;

            foreach (size_t i, dchar p; pattern)
            {
            if (p == '^' && i == 0)
            {   result = true;
                if (i + 1 == pattern.length)
                return (c == p);    // or should this be an error?
            }
            else if (range)
            {
                range = 0;
                if (lastc <= c && c <= p || c == p)
                return !result;
            }
            else if (p == '-' && i > result && i + 1 < pattern.length)
            {
                range = 1;
                continue;
            }
            else if (c == p)
                return !result;
            lastc = p;
            }
            return result;
        }

        foreach (size_t i, dchar c; s)
        {
        if (run && lastc == c)
        {
            changed = true;
        }
        else if (pattern is пусто || inPattern(c, pattern))
        {
            run = 1;
            if (changed)
            {   if (r is s)
                r = s[0 .. lasti].dup;
            encode(r, c);
            }
            else
            lasti = i + stride(s, i);
            lastc = c;
        }
        else
        {
            run = 0;
            if (changed)
            {   if (r is s)
                r = s[0 .. lasti].dup;
            encode(r, c);
            }
        }
        }
        if (changed)
        {
        if (r is s)
            r = s[0 .. lasti];
        }
        return r;
    }

    void encode(inout char[] s, dchar c)
    {
        char[] r = s;

        if (c <= 0x7F)
        {
            r ~= cast(char) c;
        }
        else
        {
            char[4] buf;
            uint L;

            if (c <= 0x7FF)
            {
            buf[0] = cast(char)(0xC0 | (c >> 6));
            buf[1] = cast(char)(0x80 | (c & 0x3F));
            L = 2;
            }
            else if (c <= 0xFFFF)
            {
            buf[0] = cast(char)(0xE0 | (c >> 12));
            buf[1] = cast(char)(0x80 | ((c >> 6) & 0x3F));
            buf[2] = cast(char)(0x80 | (c & 0x3F));
            L = 3;
            }
            else if (c <= 0x10FFFF)
            {
            buf[0] = cast(char)(0xF0 | (c >> 18));
            buf[1] = cast(char)(0x80 | ((c >> 12) & 0x3F));
            buf[2] = cast(char)(0x80 | ((c >> 6) & 0x3F));
            buf[3] = cast(char)(0x80 | (c & 0x3F));
            L = 4;
            }
            else
            {
            assert(0);
            }
            r ~= buf[0 .. L];
        }
        s = r;
        }

    ubyte[256] UTF8stride =
    [
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
        0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
        0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
        0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
        0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
        3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
        4,4,4,4,4,4,4,4,5,5,5,5,6,6,0xFF,0xFF,
    ];


    uint stride(char[] s, size_t i)
    {
        return UTF8stride[s[i]];
    }

}
version (Phobos)
{
    public import std.stdint;
    public import std.system;
    public import std.string;
    public import std.c.string;

    import std.stream;
    import std.outbuffer;
    import std.stdarg;
    import std.io;
    import std.stdint;
    import std.path;
    import std.c.string;

    import std.stdint;

    import std.string;
    import std.c.string;
    import std.stream;
    import std.outbuffer;
    import std.io;
    import std.stdarg;
	
	alias std.c.stdlib.strtoul strtoul;
}
version (Rulada)
	{
    public import std.system;
    public import std.string;
    public import std.c;
    import std.stream;
    import std.outbuffer;
    import std.stdarg;
    import std.io;
    import std.path;
    import std.string;  

		alias std.c.strtoul strtoul;
    }

	version (Dinrus)
	{
	import std.path;
	import stdrus: Поток, вТкст, Файл, ПФРежим, пишифнс;
	import cidrus;
	alias Поток Stream;
	alias вТкст toString;
	alias Файл File;

	}
	
    alias std.path.fnmatch path_match;
    //alias std.string.toString toString;
    

    template print(string fmt)
    {
        void print(T...)(T t){ пишифнс(fmt, t); }
    }


    class file_stream : copy_stream
    {
        Stream file;

        this(string path, IO_MODE mode = IO_MODE.R)
        {
            if (mode == IO_MODE.RW)
                this.file = new File(path, ПФРежим.Ввод|ПФРежим.Вывод);

            else if (mode == IO_MODE.R)
                this.file = new File(path, ПФРежим.Ввод);

            else if (mode == IO_MODE.W)
                this.file = new File(path, ПФРежим.Вывод);
        }

        void copy(void* ptr, size_t len)
        {
            size_t n;

            while ((n = file.читайБлок(ptr, len)) != 0 && len > 0)
            {
                len -= n;
                ptr += n;
            }

            if (len != 0)
                throw new Exception("Incomplete read");
        }


        void write(void* ptr, size_t len)
        {
            size_t n;

            while ((n = file.пишиБлок(ptr, len)) != 0 && len > 0)
            {
                len -= n;
                ptr += n;
            }

            if (len != 0)
                throw new Exception("Incomplete write");
        }

        void copy(void* A, size_t B, size_t C)
            { позиция(C); this.copy(A, B); }

        void write(void* A, size_t B, size_t C)
            { позиция(C); this.write(A, B); }

        size_t позиция()
            { return file.позиция(); }

        void позиция(size_t pos)
        {
            if (file.измпозУст(pos) != pos)
                throw new Exception("Seek failed");
        }

        size_t size()
            { return file.размер(); }

        void close()
            { return file.закрой(); }

        char getc()
        {
            // TODO: buffering
            char c;
            this.copy(&c, 1);

            return c;
        }

    }

    void
    file_parse(string path, void delegate(char[]) handler)
    {
        auto input = new File(path, ПФРежим.Ввод);
        char[] line;

        while ((line = input.читайСтр()) != пусто)
            handler(line);

        input.закрой;
    }


