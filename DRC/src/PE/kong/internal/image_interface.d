module kong.internal.image_interface;
import kong.internal.stdlib;


extern (C) alias void* function(void*, void*, size_t) copy_callback;


// endian swap
extern (C)
void*
swpcpy(void* dst, void* src, size_t n)
{
    for (int i = 0; i < n; ++i)
        (cast(ubyte*)dst)[i] = (cast(ubyte*)src)[n - i - 1];

    return dst;
}


void
reflect_init(alias a)(int type, bool endian)
{
    a.type    = type;
    a.address = пусто;

    if (endian)
         a.copy = cast(copy_callback) &swpcpy;
    else a.copy = cast(copy_callback) &cidrus.memcpy;
}


class image_interface
{
    io_stream file;
    bool endian = false;
    int  type;

    this(io_stream file)
    {
        //TODO: if (!file.readable || !file.seekable)
        //    throw new image_exception("Invalid file access mode");

        this.file = file;
    }





    string
    read_stringz(size_t pos = size_t.max)
    {
        char[] name;
        char c;

        if (pos != size_t.max)
            file.позиция(pos);

        while ((c = file.getc()) != 0x00 && c != char.init)
            name ~= c;

        return cast(string) name;
    }


    T
    link_b(T, U...)(ref T t, U u)
    {
        static assert(u.length == 1 || u.length == 2);

        static if (is(typeof((*t).__R3FL3CTtyp31d__) == void*))
        {
            u[0] = u[0] / (*t).t_size[type];
            return link(t, u);
        }
        else
            return t = cast(T) file.map(u);
    }

    T
    link(T, U...)(ref T t, U u)
    in
    {
        static assert(u.length >= 1);
        static assert(u.length <= 2);

    } body
    {
        static if (is(typeof(t) : void[]))
        {
            static if (is(typeof((*t).__R3FL3CTtyp31d__) == void*))
            {
                if (u.length == 2)
                    file.позиция(u[1]);

                t.length = u[0];

                foreach (ref entry; t)
                {
                    reflect_init!(entry)(type, endian);
                    entry.address = file.map(entry.tsize).ptr;
                }
                return t;
            }
            else
            {
                u[0] *= (*T).sizeof;
                return t = cast(T) file.map(u);
            }
        }
        else
        {
            static if (is(typeof(t.__R3FL3CTtyp31d__) == void*))
            {
                reflect_init!(t)(type, endian);
                u[0] *= t.tsize;
                t.address = file.map(u).ptr;
                return t;
            }
            else
            {
                static assert (is(T : void*));

                u[0] *= (*T).sizeof;
                return t = cast(T) file.map(u);
            }
        }
    }

    void
    copy(T, U...)(ref T t, U u)
    {
        size_t size;
        void *address;

        static if (is(typeof(t) : void[]))
        {
            static if (is(typeof((*t).__R3FL3CTtyp31d__) == void*))
            {
                static if (u.length)
                    file.позиция(u[0]);

                foreach (ref e; t)
                {
                    reflect_init!(e)(type, endian);

                    e.endian  = endian;
                    e.mode    = mode;
                    e.address = new ubyte[e.tsize];

                    file.copy(e.address, e.tsize);
                }

                return;

            } else
            {
                address = t.ptr;
                size    = t.length * (*t).sizeof;
            }
        }
        else
        {
            static if (is(typeof(t.__R3FL3CTtyp31d__) == void*))
            {
                reflect_init!(t)(type, endian);

                size    = t.tsize;
                address = t.address = (new ubyte[size]).ptr;
            }
            else static if (is(T : void*))
                { address = t; size = (*T).sizeof; }
            else
                { address = &t; size = t.sizeof; }
        }

        static if (u.length)
             file.copy(address, size, u[0]);
        else file.copy(address, size);
    }


    void
    write(void[] data, size_t offset = size_t.max)
    {
        if (offset != size_t.max)
             file.write(data.ptr, data.length, offset);
        else file.write(data.ptr, data.length);
    }

    void
    commit()
    {
        file.commit();
    }


    static uintptr_t
    align_to(uintptr_t a, uintptr_t b)
    {
        return ((a + b - 1) / b) * b;
    }


    aligned_block
    aligned_extend(size_t size, size_t alignment)
    {
        aligned_block block;

        block.offset = align_to(file.size(), alignment);
        block.size   = align_to(size, alignment);
        long padding = cast(long)(block.offset+size) - cast(long)file.size();
        block.growth = padding;

        if (padding > 0)
        {
            ubyte[] pad  = new ubyte[padding];
            file.write(pad.ptr, pad.length, file.size());
        }

        return block;
    }
}


T enforce(T)(T value, lazy string msg = "I/O failure")
{
    if (value)
        throw new image_exception(msg);

    return value;
}


class image_exception : Exception
{
    this(string msg)
    {
        super(msg);
    }
}

