module dmd.backend.enum_t;

import dmd.common;
import dmd.backend.SEN;
import dmd.backend.Symbol;
import dmd.backend.LIST;

struct enum_t
{
    uint SEflags;

    Symbol* SEalias;		// pointer to identifier E to use if
				/* enum was defined as:			*/
				/*	typedef enum { ... } E;		*/
    symlist_t SEenumlist;	// all members of enum
}