module dmd.backend.symtab_t;

import dmd.common;
import dmd.backend.Symbol;
import dmd.backend.Util;
import dmd.backend.SYMIDX;

struct SYMTAB_S
{
    SYMIDX top;			// 1 past end
    SYMIDX symmax;		// max # of entries in tab[] possible
    Symbol** tab;		// local Symbol table
}

alias SYMTAB_S symtab_t;