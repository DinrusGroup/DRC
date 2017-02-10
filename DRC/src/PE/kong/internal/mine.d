/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.mine : extract data from ELF images
*/
module kong.internal.mine;

import kong.internal.stdlib;

class mine(T, T2 = uint)
{
    void delegate(inout T)[T2]  table;
    T[]                         data;

    abstract T2 index(ref T);

    void finalize()
    {

    }

    void
    reduceto(T2[] list)
    {
        L0: foreach (key, ref value; table)
        {
            foreach(index; list)
                if (index == key)
                    continue L0;

            table.remove(key);
        }
    }

    bool
    process(inout T entry)
    {
        auto proc = index(entry) in table;

        if (proc)
            (*proc)(entry);

        return true;
    };


    void analyze(T)(T[] mapping)
    {
        if (table.length != 0)
        {
            foreach (ref entry; mapping)
            {
                if (process(entry) == false)
                    break;
            }
        }

        finalize();
    }
}

