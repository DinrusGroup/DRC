/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.IA32.hook_code : 6byte JMP overwrite.
*/
module kong.IA32.hook_code;

version (X86):
import kong.internal.stdlib;
import kong.IA32.X86IL;
import kong.process;
import kong.internal.hook_interface;


align(1) struct JMP // 6 byte jmp [mem]
{
    enum { OPCODE = 0x25ff };

    short opcode;
    ubyte** address;
}




class codehook_chain : hook_chain
{
    ubyte*[]  list;
    ubyte*    hook;
    ubyte*    reentry_point;
    ubyte[]   trampoline;

    void* dl_handle = пусто;

    this(void* callback, string symbol, string library)
    {
        void* target = DSO_resolve(symbol, library, dl_handle);
        enforce(!target, hook_exception.ERROR.NOTFOUND);

        this(callback, target);
    }

    this(void* callback, void* target)
    {
        ubyte* data = cast(ubyte*) target;

        uint n;
        uint size;

        force_access(data, memory_region.ACCESS.WRITE|memory_region.ACCESS.READ);

        for (size = 0; size < JMP.sizeof; size += n)
            n = X86IL(&data[size], MODE.X32);

        reentry_point         = &data[size];
        trampoline.length     = size + JMP.sizeof;
        trampoline[0 .. size] = data[0 .. size];
        trampoline[size .. $] = (cast(ubyte*) &JMP(JMP.OPCODE, &reentry_point))[0 .. 6];
        data[0 .. 6]          = (cast(ubyte*) &JMP(JMP.OPCODE, &hook))[0 .. 6];

        hook = cast(ubyte*) callback;
    }

    void* original_function()
    {
        return trampoline.ptr;
    }

    void*
    push(void* callback)
    {
        ubyte* next = hook;
        hook  = cast(ubyte*) callback;
        list ~= cast(ubyte*) next;

        return cast(void*) next;
    }

    bool
    pop()
    {
        if (list.length == 0)
        {
            uint   len = trampoline.length - JMP.sizeof;
            ubyte* ptr = reentry_point - len;

            force_access(ptr, memory_region.ACCESS.WRITE);

            ptr[0 .. len] = trampoline[0 .. len];

            if (dl_handle)
                DSO_free(dl_handle);

            return 0;
        }

        hook = list[$ - 1];
        list.length = list.length - 1;

        return 1;
    }
}


