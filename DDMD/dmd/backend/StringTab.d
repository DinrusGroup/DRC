module dmd.backend.StringTab;

import dmd.common;
import dmd.Module;
import dmd.backend.Symbol;

struct StringTab
{
    Module m;		// module we're generating code for
    Symbol* si;
    void* string_;
    size_t sz;
    size_t len;
}

enum STSIZE = 16;