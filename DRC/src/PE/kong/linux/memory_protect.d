/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.linux.memory_region : ...
*/
module kong.linux.memory_protect;

version(linux):

import kong.internal.memory_region;


extern (C) int mprotect(void*, size_t, int);

enum {
PROT_READ   = 0x1,             /* Page can be read.  */
PROT_WRITE  = 0x2,             /* Page can be written.  */
PROT_EXEC   = 0x4,             /* Page can be executed.  */
PROT_NONE   = 0x0              /* Page can not be accessed.  */
}


bool
memory_protect(uint mode, void* base, size_t size)
{
    uint mode_r = 0;

    if (mode & memory_region.ACCESS.READ)
        mode_r |= PROT_READ;

    if (mode & memory_region.ACCESS.WRITE)
        mode_r |= PROT_WRITE;

    if (mode & memory_region.ACCESS.EXEC)
        mode_r |= PROT_EXEC;

    if (mprotect(cast(void*) base, size, mode_r) == 0)
        return true;

    return false;
}

