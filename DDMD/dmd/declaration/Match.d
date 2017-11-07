module dmd.declaration.Match;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.MATCH;

struct Match
{
	int count;			// number of matches found
    MATCH last;			// match level of lastf
    FuncDeclaration lastf;	// last matching function we found
    FuncDeclaration nextf;	// current matching function
    FuncDeclaration anyf;	// pick a func, any func, to use for error recovery
}

