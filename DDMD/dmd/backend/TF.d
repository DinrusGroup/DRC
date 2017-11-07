module dmd.backend.TF;

enum TF
{
	TFprototype	 = 1,	/* if this function is prototyped	*/
	TFfixed	= 2,	/* if prototype has a fixed # of parameters */
	TFforward = 8,	// TYstruct: if forward reference of tag name
	TFsizeunknown = 0x10,	// TYstruct,TYarray: if size of type is unknown
					// TYmptr: the Stag is TYident type
	TFfuncret = 0x20,	// C++,tyfunc(): overload based on function return value
	TFfuncparam	= 0x20,	// TYarray: top level function parameter
	TFstatic = 0x40,	// TYarray: static dimension
	TFvla = 0x80,	// TYarray: variable length array
	TFemptyexc = 0x100,	// tyfunc(): empty exception specification

	// C
	TFgenerated = 4,	// if we generated the prototype ourselves

	// CPP
	TFdependent = 4,	// template dependent type

///version (TX86) {
///} else {
///	TFhydrated = 0x20,	// type data already hydrated
///	TFbasicrev = 0x80,	// if basic reserved type
///}
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(TF));