module dmd.backend.cse_t;

import dmd.common;
import dmd.backend.elem;
import dmd.backend.regm_t;

enum REGMAX = 10;

struct cse_t
{   
	elem*[REGMAX] value;	// expression values in registers
    regm_t mval;		// mask of which values in value[] are valid
    regm_t mops;		// subset of mval that contain common subs that need
				// to be stored in csextab[] if they are destroyed
};