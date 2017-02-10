/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.PE.hook_api : IAT hooking.
*/

version (Phobos){
import std.stdint;
import std.string;
import std.io;
import std.c.windows.windows;
import std.c.string;
import std.path;}

version (Rulada){
import std.string;
import std.io;
import os.windows;
import std.c;
import std.path;}

version (Dinrus){
import std.string;
import cidrus;
import winapi;
//import std.c;
import std.path;}

import kong.PE.PE;
import kong.internal.hook_interface;
import kong.internal.dynamic_object;


version(X86)          alias PE_platform!(IMAGE_FILE_MACHINE_I386)  PE_native;
else version(X86_64)  alias PE_platform!(IMAGE_FILE_MACHINE_AMD64) PE_native;
else                  static assert(0);

class apihook_chain : hook_chain
{
    private:

    uintptr_t[]  saved;
    uintptr_t* funcptr;
    uintptr_t  original;

    public:

    this(void* callback, string symbol, dynamic_object* obj)
    {
        size_t offset, size;

        uintptr_t base        = cast(uintptr_t)       obj.address;
        PE_native.image image = cast(PE_native.image) obj.image;

        with (image.NT.OptionalHeader){
        offset = DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;
        size   = DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].Size;
        }

        foreach (ref imp; cast(IMAGE_IMPORT_DESCRIPTOR[])(cast(ubyte*)(base+offset))[0..size])
        {
            uintptr_t* thunk;
            uintptr_t* func;

            if (imp.OriginalFirstThunk)
            {
                thunk = cast(uintptr_t*) (base + imp.OriginalFirstThunk);
                func  = cast(uintptr_t*) (base + imp.FirstThunk);

            } else // no hint table
            {
                thunk = cast(uintptr_t*) (base + imp.FirstThunk);
                func  = cast(uintptr_t*) (base + imp.FirstThunk);
            }

            for (; *thunk; thunk++, func++)
            {
                if (IMAGE_SNAP_BY_ORDINAL(*thunk))
                    continue;

                IMAGE_IMPORT_BY_NAME* thunk_data = cast(IMAGE_IMPORT_BY_NAME*)(base + *thunk);
                char* cstr = cast(char*) &thunk_data.Name;

                if (icmp(symbol, cast(string) cstr[0 .. strlen(cstr)]) == 0)
                {
                    MEMORY_BASIC_INFORMATION mbi;

                    VirtualQuery(func, &mbi, mbi.sizeof);
                    kong.internal.image_interface.enforce(VirtualProtect(mbi.BaseAddress, mbi.RegionSize, PAGE_READWRITE, &mbi.Protect) == FALSE, "VirtualProtect");

                    funcptr  = func;
                    original = *func;
                    *func = cast(uintptr_t) callback;

                    // TODO: probably should restore this here and in push / pop
                    // VirtualProtect(mbi.BaseAddress, mbi.RegionSize, mbi.Protect, &saved);

                    saved ~= original;
                    return;
                }
            }
        }

        throw new hook_exception(hook_exception.ERROR.NOTFOUND);
    }

    void*
    original_function()
    {
        return cast(void*) original;
    }

    void*
    push(void* callback)
    {
        uintptr_t entry = *funcptr;
        saved          ~= entry;
        *funcptr        = cast(uintptr_t) callback;

        return cast(void*) entry;
    }

    bool pop()
    in { assert(saved.length != 0); }
    body
    {
        *funcptr     = saved[$ - 1];
        saved.length = saved.length - 1;

        return (saved.length != 0);
    }

}


extern (Windows) void* GetModuleHandleA(char*);

