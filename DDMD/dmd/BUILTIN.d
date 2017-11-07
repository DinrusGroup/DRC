module dmd.BUILTIN;

enum BUILTIN
{
    BUILTINunknown = -1,	// not known if this is a builtin
    BUILTINnot,			// this is not a builtin
    BUILTINsin,			// std.math.sin
    BUILTINcos,			// std.math.cos
    BUILTINtan,			// std.math.tan
    BUILTINsqrt,		// std.math.sqrt
    BUILTINfabs,		// std.math.fabs
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(BUILTIN));