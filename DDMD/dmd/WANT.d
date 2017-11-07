module dmd.WANT;

enum WANT
{
	WANTflags = 1,
    WANTvalue = 2,
    WANTinterpret = 4,
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(WANT));