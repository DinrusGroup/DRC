module dmd.TRUST;

enum TRUST
{
    TRUSTdefault = 0,
    TRUSTsystem = 1,	// @system (same as TRUSTdefault)
    TRUSTtrusted = 2,	// @trusted
    TRUSTsafe = 3,	// @safe
};

import dmd.EnumUtils;
mixin(BringToCurrentScope!(TRUST));