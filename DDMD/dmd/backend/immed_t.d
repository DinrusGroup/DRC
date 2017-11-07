module dmd.backend.immed_t;

import dmd.common;
import dmd.backend.targ_types;
import dmd.backend.regm_t;
import dmd.backend.REGMAX;

struct immed_t
{
	targ_int[REGMAX] value;	// immediate values in registers
    regm_t mval;		// Mask of which values in regimmed.value[] are valid
}