module dmd.MOD;

public enum MOD
{
	MODundefined = 0,
	MODconst = 1,	// type is const
	MODshared = 2,	// type is shared
	MODimmutable = 4,	// type is immutable
	MODwild	= 8,	// type is wild
	MODmutable = 0x10,	// type is mutable (only used in wildcard matching)
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(MOD));
