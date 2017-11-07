module dmd.STC;

enum STC : ulong
{
    STCundefined    = 0,
    STCstatic	    = 1,
    STCextern	    = 2,
    STCconst	    = 4,
    STCfinal	    = 8,
    STCabstract     = 0x10,
    STCparameter    = 0x20,
    STCfield	    = 0x40,
    STCoverride	    = 0x80,
    STCauto         = 0x100,
    STCsynchronized = 0x200,
    STCdeprecated   = 0x400,
    STCin           = 0x800,		// in parameter
    STCout          = 0x1000,		// out parameter
    STClazy	    = 0x2000,		// lazy parameter
    STCforeach      = 0x4000,		// variable for foreach loop
    STCcomdat       = 0x8000,		// should go into COMDAT record
    STCvariadic     = 0x10000,		// variadic function argument
    STCctorinit     = 0x20000,		// can only be set inside constructor
    STCtemplateparameter = 0x40000,	// template parameter
    STCscope	    = 0x80000,		// template parameter
    STCimmutable    = 0x100000,
    STCref	    = 0x200000,
    STCinit	    = 0x400000,		// has explicit initializer
    STCmanifest	    = 0x800000,		// manifest constant
    STCnodtor	    = 0x1000000,	// don't run destructor
    STCnothrow	    = 0x2000000,	// never throws exceptions
    STCpure	    = 0x4000000,	// pure function
    STCtls	    = 0x8000000,	// thread local
    STCalias	    = 0x10000000,	// alias parameter
    STCshared       = 0x20000000,	// accessible from multiple threads
    STCgshared      = 0x40000000,	// accessible from multiple threads
					// but not typed as "shared"
    STCwild         = 0x80000000,	// for "wild" type constructor
    STC_TYPECTOR    = (STCconst | STCimmutable | STCshared | STCwild),

    // attributes
	STCproperty		= 0x100000000,
	STCsafe			= 0x200000000,
	STCtrusted		= 0x400000000,
	STCsystem		= 0x800000000,
	STCctfe			= 0x1000000000,	// can be used in CTFE, even if it is static
	STCdisable      = 0x2000000000,	// for functions that are not callable
}

alias STC StorageClass;

import dmd.EnumUtils;
mixin(BringToCurrentScope!(STC));