module dmd.backend.Cstate;

import dmd.common;
import dmd.backend.Symbol;
import dmd.backend.LIST;
import dmd.backend.symtab_t;

struct BLKLST;
 
struct Cstate
{
    BLKLST* CSfilblk;	// current source file we are parsing
    Symbol* CSlinkage;		// table of forward referenced linkage pragmas
    list_t CSlist_freelist;	// free list for list package
    symtab_t* CSpsymtab;	// pointer to current Symbol table
version (MEMORYHX) {
    void** CSphx;		// pointer to HX data block
}
    char* modname;		// module unique identifier
}

version (Windows) {
	extern (C++) extern __gshared Cstate cstate;		// compiler state
	extern (C++) extern __gshared symtab_t globsym;		/* global symbol table			*/
	extern (C++) extern void symtab_free(Symbol** tab);
} else {
	extern (C) extern __gshared Cstate cstate;
}
