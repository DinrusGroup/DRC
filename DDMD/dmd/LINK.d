module dmd.LINK;

enum LINK
{
    LINKdefault,
    LINKd,
    LINKc,
    LINKcpp,
    LINKwindows,
    LINKpascal,
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(LINK));