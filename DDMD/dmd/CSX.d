module dmd.CSX;

enum CSX
{
	CSXthis_ctor = 1,	// called this()
	CSXsuper_ctor = 2,	// called super()
	CSXthis	= 4,	// referenced this
	CSXsuper = 8,	// referenced super
	CSXlabel = 0x10,	// seen a label
	CSXreturn = 0x20,	// seen a return statement
	CSXany_ctor = 0x40,	// either this() or super() was called
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(CSX));