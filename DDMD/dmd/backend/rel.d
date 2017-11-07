module dmd.backend.rel;

import dmd.common;
import dmd.backend.OPER;

extern (C++) extern
{
	ubyte* get_rel_not();
	ubyte* get_rel_swap();
	ubyte* get_rel_integral();
	ubyte* get_rel_exception();
	ubyte* get_rel_unord();
}

ubyte rel_not(OPER op) {
	return get_rel_not[cast(int)(op) - RELOPMIN];
}

ubyte rel_swap(OPER op) {
	return get_rel_swap[cast(int)(op) - RELOPMIN];
}

ubyte rel_integral(OPER op){
	return get_rel_integral[cast(int)(op) - RELOPMIN];
}

ubyte rel_exception(OPER op) {
	return get_rel_exception[cast(int)(op) - RELOPMIN];
}

ubyte rel_unord(OPER op) {
	return get_rel_unord[cast(int)(op) - RELOPMIN];
}