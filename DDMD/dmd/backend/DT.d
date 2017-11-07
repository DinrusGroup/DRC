module dmd.backend.DT;

import dmd.common;
import dmd.backend.dt_t;

enum DT
{
    DT_abytes,
    DT_azeros,  // 1
    DT_xoff,
    DT_1byte,
    DT_nbytes,
    DT_common,
    DT_symsize,
    DT_coff,
    DT_ibytes, // 8
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(DT));