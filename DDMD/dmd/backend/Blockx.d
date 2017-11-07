module dmd.backend.Blockx;

import dmd.common;
import dmd.Module;
import dmd.Declaration;
import dmd.ClassDeclaration;

import dmd.backend.Symbol;
import dmd.backend.block;
import dmd.backend.elem;

alias Symbol Funcsym;

struct Blockx
{
    block* startblock;
    block* curblock;
    Funcsym* funcsym;
    Symbol* context;		// eh frame context variable
    int scope_index;		// current scope index
    int next_index;		// value for next scope index
    uint flags;		// value to OR into Bflags
    block* tryblock;		// current enclosing try block
    elem* init;			// static initializer
    ClassDeclaration classdec;
    Declaration member;	// member we're compiling for
    Module module_;		// module we're in
}