/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.win32.memory_layout : memory region enumeration.
*/
module kong.win32.memory_layout;
version (Windows):

import kong.internal.memory_region;

version (Phobos){
import std.c.windows.windows;
import std.stdint;
import std.utf;
alias std.c.stdlib.strtoul strtoul;
}

version (Rulada){
import os.windows;
import std.c;
import std.utf;
alias std.c.strtoul strtoul;
}

version (Dinrus){
import stdrus;
alias stdrus.вЮ8 toUTF8;
import winapi;
import cidrus;
alias cidrus.strtoul strtoul;
}


import kong.win32.DSO;
import kong.PE.types;

struct MEMORY_BASIC_INFORMATION
{
  PVOID BaseAddress;
  PVOID AllocationBase;
  DWORD AllocationProtect;
  size_t RegionSize;
  DWORD State;
  DWORD Protect;
  DWORD Type;
}


align(16) struct MEMORY_BASIC_INFORMATION64
{
    uint64_t  BaseAddress;
    uint64_t  AllocationBase;
    DWORD     AllocationProtect;
    DWORD     __alignment1;
    uint64_t  RegionSize;
    DWORD     State;
    DWORD     Protect;
    DWORD     Type;
    DWORD     __alignment2;
}

extern (Windows) size_t VirtualQuery(void*, MEMORY_BASIC_INFORMATION*, size_t);



enum {
    MEM_COMMIT  = 0x1000,
    MEM_FREE    = 0x10000,
    MEM_RESERVE = 0x2000,
    MEM_IMAGE   = 0x1000000,
    MEM_MAPPED  = 0x40000,
    MEM_PRIVATE = 0x20000,

    PAGE_EXECUTE           = 0x10,
    PAGE_EXECUTE_READ      = 0x20,
    PAGE_EXECUTE_READWRITE = 0x40,
    PAGE_EXECUTE_WRITECOPY = 0x80,
    PAGE_NOACCESS          = 0x01,
    PAGE_READONLY          = 0x02,
    PAGE_READWRITE         = 0x04,
    PAGE_WRITECOPY         = 0x08
}



static
memory_region[]
memory_layout(string match = пусто)
{
    memory_region[] results;
    LDR_MODULE*[void*] image_lu;

    MEMORY_BASIC_INFORMATION mbi;




    bool
    dll_process(LDR_MODULE* dll)
    {
        image_lu[dll.BaseAddress] = dll;
        return true;
    }

    enum_PEBDLL(&dll_process);

    bool      dll = false;
    uintptr_t dll_end;
    string    dll_name;


    for (uintptr_t start = 0x00010000; start < 0x7FFE0000; start += mbi.RegionSize)
    {
        int sz = VirtualQuery(cast(void *) start, &mbi, mbi.sizeof);

        if (sz == 0)
            return results;

        if (mbi.State == MEM_COMMIT)
        {
            memory_region r;

            r.base   = cast(uintptr_t) mbi.BaseAddress;
            r.size   = mbi.RegionSize;
            r.access = memory_region.ACCESS.NONE;

            switch (mbi.Protect & 0xff){
            case PAGE_EXECUTE_WRITECOPY :
            case PAGE_EXECUTE_READWRITE : r.access |= memory_region.ACCESS.WRITE;
            case PAGE_EXECUTE_READ      : r.access |= memory_region.ACCESS.READ;
            case PAGE_EXECUTE           : r.access |= memory_region.ACCESS.EXEC;
                                          break;
            case PAGE_WRITECOPY :
            case PAGE_READWRITE : r.access |= memory_region.ACCESS.WRITE;
            case PAGE_READONLY  : r.access |= memory_region.ACCESS.READ;
            case PAGE_NOACCESS  :
            default: break;
            }

            if (mbi.Type == MEM_IMAGE)
            {
                if (dll && start >= dll_end)
                    dll = false;

                if (dll)
                    r.path = dll_name;

                if (dll == false)
                {
                    LDR_MODULE**d = cast(void*) r.base in image_lu;

                    if (d)
                    {
                        dll      = true;
                        dll_name = toUTF8((*d).FullDllName.Buffer[0 .. (*d).FullDllName.Length / wchar.sizeof]);
                        dll_end  = r.base + (*d).SizeOfImage;
                        r.path   = dll_name;
                    }
                }
            }

            results ~= r;
        }

    }

    return results;
}

