/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.linux.memory_layout : /proc dependant atm.
*/

module kong.linux.memory_layout;

version(linux):

import kong.internal.stdlib;
import kong.internal.memory_region;



static
memory_region[]
memory_layout()
{
    memory_region[] results;

    void handler(string raw_line)
    {
        string[] line;
        string[] range;

        line = split(squeeze(raw_line, " "), " ");
        memory_region r;

        if (line.length == 0)
            return;


        else if (line.length > 5)
            r.path = line[5];

        range    = split(line[0], "-");
        r.base   = strtoul(toStringz(range[0]), пусто, 16);
        r.size   = strtoul(toStringz(range[1]), пусто, 16) - r.base;
        r.access = memory_region.ACCESS.NONE;

        if (line[1][0] != '-')
            r.access |= memory_region.ACCESS.READ;

        if (line[1][1] != '-')
            r.access |= memory_region.ACCESS.WRITE;

        if (line[1][2] != '-')
            r.access |= memory_region.ACCESS.EXEC;

        results ~= r;
    }

    file_parse("/proc/self/maps", &handler);
    return results;
}



