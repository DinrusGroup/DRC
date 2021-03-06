module dmd.backend.struct_t;

import dmd.common;
import dmd.backend.targ_types;
import dmd.backend.LIST;
import dmd.backend.Symbol;

/***********************************
 * Special information for structs.
 */

struct struct_t
{
    targ_size_t Sstructsize;	// size of struct
    symlist_t Sfldlst;		// all members of struct (list freeable)
    Symbol* Sroot;		// root of binary tree Symbol table
    uint Salignsize;	// size of struct for alignment purposes
    ubyte Sstructalign;	// struct member alignment in effect
    uint Sflags;
/+
#define STRanonymous	0x01	// set for unions with no tag names
#define STRglobal	0x02	// defined at file scope
#define STRnotagname	0x04	// struct/class with no tag name
#define STRoutdef	0x08	// we've output the debug definition
#define STRbitfields    0x10	// set if struct contains bit fields
#define STRpredef	0x1000 // a predefined struct
#define STRunion	0x4000	// actually, it's a union

#define STRabstract	0x20	// abstract class
#define STRbitcopy	0x40	// set if operator=() is merely a bit copy
#define STRanyctor	0x80	// set if any constructors were defined
				// by the user
#define STRnoctor	0x100	// no constructors allowed
#define STRgen		0x200	// if struct is an instantiation of a
				// template class, and was generated by
				// that template
#define STRvtblext	0x400	// generate vtbl[] only when first member function
				// definition is encountered (see Fvtblgen)
#define STRexport	0x800	// all member functions are to be _export
#define STRclass	0x8000	// it's a class, not a struct
#if TX86
#define STRimport	0x40000	// imported class
#define STRstaticmems	0x80000	// class has static members
#endif
#define	STR0size	0x100000	// zero sized struct
#define STRinstantiating 0x200000	// if currently being instantiated
#define STRexplicit	0x400000	// if explicit template instantiation
#define STRgenctor0	0x800000	// need to gen X::X()
    tym_t ptrtype;		// type of pointer to refer to classes by
    unsigned short access;	// current access privilege, here so
				// enum declarations can get at it
    targ_size_t Snonvirtsize;	// size of struct excluding virtual classes
    list_t Svirtual;		// freeable list of mptrs
				// that go into vtbl[]
#if TX86
    list_t *Spvirtder;		// pointer into Svirtual that points to start
				// of virtual functions for this (derived) class
    symlist_t Sopoverload;	// overloaded operator funcs (list freeable)
#endif
    symlist_t Scastoverload;	// overloaded cast funcs (list freeable)
    symlist_t Sclassfriends;	// list of classes of which this is a friend
				// (list is freeable)
    symlist_t Sfriendclass;	// classes which are a friend to this class
				// (list is freeable)
    symlist_t Sfriendfuncs;	// functions which are a friend to this class
				// (list is freeable)
    symlist_t Sinlinefuncs;	// list of tokenized functions
    baseclass_t *Sbase;		// list of direct base classes
    baseclass_t *Svirtbase;	// list of all virtual base classes
    baseclass_t *Smptrbase;	// list of all base classes that have
				// their own vtbl[]
    baseclass_t *Sprimary;	// if not NULL, then points to primary
				// base class
    Funcsym *Svecctor;		// constructor for use by vec_new()
    Funcsym *Sctor;		// constructor function

    Funcsym *Sdtor;		// basic destructor
#if VBTABLES
    Funcsym *Sprimdtor;		// primary destructor
    Funcsym *Spriminv;		// primary invariant
    Funcsym *Sscaldeldtor;	// scalar deleting destructor
#endif

    Funcsym *Sinvariant;	// basic invariant function

    Symbol *Svptr;		// Symbol of vptr
    Symbol *Svtbl;		// Symbol of vtbl[]
#if VBTABLES
    Symbol *Svbptr;		// Symbol of pointer to vbtbl[]
    Symbol *Svbptr_parent;	// base class for which Svbptr is a member.
				// NULL if Svbptr is a member of this class
    targ_size_t Svbptr_off;	// offset of Svbptr member
    Symbol *Svbtbl;		// virtual base offset table
    baseclass_t *Svbptrbase;	// list of all base classes in canonical
				// order that have their own vbtbl[]
#endif
    Funcsym *Sopeq;		// X& X::operator =(X&)
    Funcsym *Sopeq2;		// Sopeq, but no copy of virtual bases
    Funcsym *Scpct;		// copy constructor
    Funcsym *Sveccpct;		// vector copy constructor
    Symbol *Salias;		// pointer to identifier S to use if
				// struct was defined as:
				//	typedef struct { ... } S;

    Symbol *Stempsym;		// if this struct is an instantiation
				// of a template class, this is the
				// template class Symbol

    /* For:
     *	template<class T> struct A { };
     *	template<class T> struct A<T *> { };
     *
     *  A<int> a;		// primary
     * Gives:
     *	Sarglist = <int>
     *	Spr_arglist = NULL;
     *
     *  A<int*> a;		// specialization
     * Gives:
     *	Sarglist = <int>
     *	Spr_arglist = <int*>;
     */

    param_t *Sarglist;		// if this struct is an instantiation
				// of a template class, this is the
				// actual arg list used
    param_t *Spr_arglist;	// if this struct is an instantiation
				// of a specialized template class, this is the
				// actual primary arg list used.
				// It is NULL for the
				// primary template class (since it would be
				// identical to Sarglist).
    TARGET_structSTRUCT
+/
}