module dmd.backend.func_t;

import dmd.common;
import dmd.backend.LIST;
import dmd.backend.block;
import dmd.backend.symtab_t;
import dmd.backend.Srcpos;
import dmd.backend.Symbol;
import dmd.backend.Classsym;
import dmd.backend.Funcsym;
import dmd.backend.elem;
import dmd.backend.token_t;
import dmd.backend.Thunk;
import dmd.backend.PARAM;

struct func_t
{
    symlist_t Fsymtree;		// local Symbol table
    block* Fstartblock;		// list of blocks comprising function
    symtab_t Flocsym;		// local Symbol table
    Srcpos Fstartline;		// starting line # of function
    Srcpos Fendline;		// line # of closing brace of function
    Symbol* F__func__;		// symbol for __func__[] string
    uint Fflags;
	uint Fflags3;
    ubyte Foper;	// operator number (OPxxxx) if Foperator

    Symbol* Fparsescope;	// use this scope to parse friend functions
				// which are defined within a class, so the
				// class is in scope, but are not members
				// of the class

    Classsym* Fclass;		// if member of a class, this is the class
				// (I think this is redundant with Sscope)
    Funcsym* Foversym;		// overloaded function at same scope
    symlist_t Fclassfriends;	/* Symbol list of classes of which this	*/
				/* function is a friend			*/
    block* Fbaseblock;		// block where base initializers get attached
    block* Fbaseendblock;	// block where member destructors get attached
    elem* Fbaseinit;		/* list of member initializers (meminit_t) */
				/* this field has meaning only for	*/
				/* functions which are constructors	*/
    token_t* Fbody;	/* if deferred parse, this is the list	*/
				/* of tokens that make up the function	*/
				/* body					*/
				// also used if SCfunctempl, SCftexpspec
    uint Fsequence;		// sequence number at point of definition
    union 
    {
		Symbol* Ftempl;		// if Finstance this is the template that generated it
		Thunk* Fthunk;	// !=NULL if this function is actually a thunk
    }
	
    Funcsym* Falias;		// SCfuncalias: function Symbol referenced
				// by using-declaration

    symlist_t Fthunks;		// list of thunks off of this function

    param_t* Farglist;		// SCfunctempl: the template-parameter-list
    param_t* Fptal;		// Finstance: this is the template-argument-list
				// SCftexpspec: for explicit specialization, this
				// is the template-argument-list
    list_t Ffwdrefinstances;	// SCfunctempl: list of forward referenced instances
    list_t Fexcspec;		// List of types in the exception-specification
				// (NULL if none or empty)
    Funcsym* Fexplicitspec;	// SCfunctempl, SCftexpspec: threaded list
				// of SCftexpspec explicit specializations
    Funcsym* Fsurrogatesym;	// Fsurrogate: surrogate cast function   
}