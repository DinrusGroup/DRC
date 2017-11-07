module dmd.CppMangleState;

import dmd.common;
import dmd.Array;
import dmd.OutBuffer;

struct CppMangleState
{
	/**
	 * Get rid of it or move to CompilerState
	 */
    // static __gshared Array components;

    int substitute(OutBuffer buf, void* p)
	{
		assert(false);
	}
}