module dmd.MATCH;

version (DMDV2) {
	enum MATCH
	{
		MATCHnomatch,	// no match
		MATCHconvert,	// match with conversions

		MATCHconst,		// match with conversion to const

		MATCHexact		// exact match
	}
} else {
	enum MATCH
	{
		MATCHnomatch,	// no match
		MATCHconvert,	// match with conversions

		MATCHexact		// exact match
	}
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(MATCH));