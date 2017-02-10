/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.win32.memory_region : ...
*/
module kong.win32.memory_protect;

version(Windows):
import kong.internal.memory_region;

version (Phobos){
import std.c.windows.windows;}

version (Rulada){
import os.windows;}
extern (Windows) BOOL VirtualProtect(LPVOID lpAddress, size_t dwSize, DWORD, PDWORD);


enum {
    PAGE_EXECUTE           = 0x10,
    PAGE_EXECUTE_READ      = 0x20,
    PAGE_EXECUTE_READWRITE = 0x40,
    PAGE_EXECUTE_WRITECOPY = 0x80,
    PAGE_NOACCESS          = 0x01,
    PAGE_READONLY          = 0x02,
    PAGE_READWRITE         = 0x04,
    PAGE_WRITECOPY         = 0x08
}


bool
memory_protect(uint mode, void* base, size_t size)
{
    uint mode_r = PAGE_NOACCESS;
    uint old;

    with (memory_region)
    {
        if (mode & ACCESS.EXEC)
        {
            if (mode & ACCESS.READ|ACCESS.WRITE|ACCESS.EXEC)
                mode_r = PAGE_EXECUTE_READWRITE;

            else if (mode & ACCESS.READ|ACCESS.EXEC)
                mode_r = PAGE_EXECUTE_READ;

            else
                mode_r = PAGE_EXECUTE;
        }
        else
        {
            if (mode & ACCESS.READ|ACCESS.WRITE)
                mode_r = PAGE_READWRITE;

            else if (mode & ACCESS.READ)
                mode_r = PAGE_READONLY;
        }
    }

    if (VirtualProtect(base, size, mode_r, &old) != 0)
        return true;

    return false;
}



