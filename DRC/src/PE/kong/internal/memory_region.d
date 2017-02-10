/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.internal.memory_region : ...
*/
module kong.internal.memory_region;
import kong.internal.stdlib;


version(linux)          import platform = kong.linux.memory_protect;
else version(Windows)   import platform = kong.win32.memory_protect;
else static assert(0);


struct
memory_region
{
    enum ACCESS { READ = 0b0001, WRITE = 0b0010, EXEC = 0b0100, NONE = 0 }

    ACCESS access = ACCESS.NONE;

    uintptr_t base;
    uintptr_t size;

    string path;

    bool
    access_set(ACCESS mode)
    {
        return platform.memory_protect(mode, cast(void*) base, size);
    }

    ubyte[]
    opSlice()
    {
        return (cast(ubyte*)base)[0 .. size];
    }


    void
    print()
    {
        char rwx[3] = ['-','-','-'];


        if (access & ACCESS.READ)
            rwx[0] = 'r';

        if (access & ACCESS.WRITE)
            rwx[1] = 'w';

        if (access & ACCESS.EXEC)
            rwx[2] = 'x';

        .print!("%08x-%08x %s %s")(base, base + size, rwx, path);
    }

}




