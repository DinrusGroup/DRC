module dmd.backend.con_t;

import dmd.common;
import dmd.backend.cse_t;
import dmd.backend.immed_t;
import dmd.backend.regm_t;

struct con_t
{
	cse_t cse;			// CSEs in registers
    immed_t immed;		// immediate values in registers
    regm_t mvar;		// mask of register variables
    regm_t mpvar;		// mask of SCfastpar register variables
    regm_t indexregs;		// !=0 if more than 1 uncommitted index register
    regm_t used;		// mask of registers used
    regm_t params;		// mask of registers which still contain register
				// function parameters
}