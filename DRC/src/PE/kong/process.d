/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.process : examine memory-regions/runtime-libraries.
*/
module kong.process;

import kong.internal.stdlib;
public import kong.internal.dynamic_object;
public import kong.internal.memory_region;

version(linux){
import platform_MEM = kong.linux.memory_layout;
import platform_DSO = kong.linux.DSO;
}
else version(Windows){
import platform_MEM = kong.win32.memory_layout;
import platform_DSO = kong.win32.DSO;
}

else static assert(0);



public memory_list              process_map;
public platform_DSO.DSO_list    process_modules;


struct
memory_list
{
    memory_region[] cached;

    memory_region[] opSlice()
    {
        return cached = platform_MEM.memory_layout();
    }

    memory_region* opIn_r(void* p)
    {
        return lookup_pointer(p);
    }

    /*
    memory_region*
    opIndex(name)
    {
        cached = platform_MEM.memory_layout(name);
        return (cached.length) ? &cached[0] : пусто;
    }
    */

    memory_region*
    lookup_pointer(void* ptr, memory_region[] map = пусто)
    {
        uintptr_t address = cast(uintptr_t) ptr;

        if (!map)
            map = cached = platform_MEM.memory_layout();

        foreach (ref memory_region mem; map)
        {
            if (address >= mem.base && address < mem.base + mem.size)
                return &mem;
        }

        return пусто;
    }
}


