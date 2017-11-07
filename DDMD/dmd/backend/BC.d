module dmd.backend.BC;

enum BC
{
    BCgoto	= 1,	// goto Bsucc block
    BCiftrue	= 2,	// if (Belem) goto Bsucc[0] else Bsucc[1]
    BCret	= 3,	// return (no return value)
    BCretexp	= 4,	// return with return value
    BCexit	= 5,	// never reaches end of block (like exit() was called)
    BCasm	= 6,	// inline assembler block (Belem is NULL, Bcode
			// contains code generated).
			// These blocks have one or more successors in Bsucc,
			// never 0
    BCswitch	= 7,	// switch statement
			// Bswitch points to switch data
			// Default is Bsucc
			// Cases follow in linked list
    BCifthen	= 8,	// a BCswitch is converted to if-then
			// statements
    BCjmptab	= 9,	// a BCswitch is converted to a jump
			// table (switch value is index into
			// the table)
    BCtry	= 10,	// C++ try block
			// first block in a try-block. The first block in
			// Bsucc is the next one to go to, subsequent
			// blocks are the catch blocks
    BCcatch	= 11,	// C++ catch block
    BCjump	= 12,	// Belem specifies (near) address to jump to
    BC_try	= 13,	// SEH: first block of try-except or try-finally
			// Jupiter, Mars: try-catch or try-finally
    BC_filter	= 14,	// SEH exception-filter (always exactly one block)
    BC_finally	= 15,	// first block of SEH termination-handler,
			// or finally block
    BC_ret	= 16,	// last block of SEH termination-handler or finally block
    BC_except	= 17,	// first block of SEH exception-handler
    BCjcatch	= 18,	// first block of Jupiter or Mars catch-block
    BCjplace	= 19,	// Jupiter: placeholder
    BCMAX
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(BC));