module dmd.BE;

/* How a statement exits; this is returned by blockExit()
 */
enum BE
{
	BEnone =	 0,
    BEfallthru = 1,
    BEthrow =    2,
    BEreturn =   4,
    BEgoto =     8,
    BEhalt =	 0x10,
    BEbreak =	 0x20,
    BEcontinue = 0x40,
    BEany = (BEfallthru | BEthrow | BEreturn | BEgoto | BEhalt),
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(BE));