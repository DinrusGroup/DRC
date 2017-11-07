module dmd.Port;

import dmd.common;
import core.stdc.math;

struct Port
{
    static int isSignallingNan(double r)
	{
		/* A signalling NaN is a NaN with 0 as the most significant bit of
		 * its significand, which is bit 51 of 0..63 for 64 bit doubles.
		 */
		return isnan(r) && !(((cast(ubyte*)&r)[6]) & 8);
	}
	
    static int isSignallingNan(ref real r)
	{
		/* A signalling NaN is a NaN with 0 as the most significant bit of
		 * its significand, which is bit 62 of 0..79 for 80 bit reals.
		 */
		return isnan(r) && !(((cast(ubyte*)&r)[7]) & 0x40);
	}
}