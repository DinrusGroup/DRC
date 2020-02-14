﻿// Written in the D programming language
// written by Walter Bright
// www.digitalmars.com
// Placed into the public domain

/** These functions are built-in intrinsics to the compiler.
 *
	Intrinsic functions are functions built in to the compiler,
	usually to take advantage of specific CPU features that
	are inefficient to хэндл via external functions.
	The compiler's optimizer and code generator are fully
	integrated in with intrinsic functions, bringing to bear
	their full power on them.
	This can результат in some surprising speedups.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Walter Bright
 * Macros:
 *	WIKI=Phobos/StdIntrinsic
 */

module std.intrinsic;

/**
 * Scans the bits in v starting with bit 0, looking
 * for the first set bit.
 * Returns:
 *	The bit number of the first bit set.
 *	The return value is undefined if v is zero.
 */
int bsf(uint v);

/**
 * Scans the bits in v from the most significant bit
 * to the least significant bit, looking
 * for the first set bit.
 * Returns:
 *	The bit number of the first bit set.
 *	The return value is undefined if v is zero.
 * Example:
 * ---
 * import std.io;
 * import std.intrinsic;
 *
 * int main()
 * {   
 *     uint v;
 *     int x;
 *
 *     v = 0x21;
 *     x = bsf(v);
 *     writefln("bsf(x%x) = %d", v, x);
 *     x = bsr(v);
 *     writefln("bsr(x%x) = %d", v, x);
 *     return 0;
 * } 
 * ---
 * Output:
 *  bsf(x21) = 0<br>
 *  bsr(x21) = 5
 */
int bsr(uint v);

/**
 * Tests the bit.
 */
int bt(in uint *p, uint bitnum);

/**
 * Tests and complements the bit.
 */
int btc(uint *p, uint bitnum);

/**
 * Tests and resets (sets to 0) the bit.
 */
int btr(uint *p, uint bitnum);

/**
 * Tests and sets the bit.
 * Параметры:
 * p = a non-NULL pointer to an array of uints.
 * index = a bit number, starting with bit 0 of p[0],
 * and progressing. It addresses bits like the expression:
---
p[index / (uint.sizeof*8)] & (1 << (index & ((uint.sizeof*8) - 1)))
---
 * Returns:
 * 	A non-zero value if the bit was set, and a zero
 *	if it was clear.
 *
 * Example: 
 * ---
import std.io;
import std.intrinsic;

int main()
{   
    uint array[2];

    array[0] = 2;
    array[1] = 0x100;

    writefln("btc(array, 35) = %d", <b>btc</b>(array, 35));
    writefln("array = [0]:x%x, [1]:x%x", array[0], array[1]);

    writefln("btc(array, 35) = %d", <b>btc</b>(array, 35));
    writefln("array = [0]:x%x, [1]:x%x", array[0], array[1]);

    writefln("bts(array, 35) = %d", <b>bts</b>(array, 35));
    writefln("array = [0]:x%x, [1]:x%x", array[0], array[1]);

    writefln("btr(array, 35) = %d", <b>btr</b>(array, 35));
    writefln("array = [0]:x%x, [1]:x%x", array[0], array[1]);

    writefln("bt(array, 1) = %d", <b>bt</b>(array, 1));
    writefln("array = [0]:x%x, [1]:x%x", array[0], array[1]);

    return 0;
} 
 * ---
 * Output:
<pre>
btc(array, 35) = 0
array = [0]:x2, [1]:x108
btc(array, 35) = -1
array = [0]:x2, [1]:x100
bts(array, 35) = 0
array = [0]:x2, [1]:x108
btr(array, 35) = -1
array = [0]:x2, [1]:x100
bt(array, 1) = -1
array = [0]:x2, [1]:x100
</pre>
 */
int bts(uint *p, uint bitnum);


/**
 * Swaps bytes in a 4 byte uint end-to-end, i.e. byte 0 becomes
	byte 3, byte 1 becomes byte 2, byte 2 becomes byte 1, byte 3
	becomes byte 0.
 */
uint bswap(uint v);


/**
 * Reads I/O port at port_address.
 */
ubyte  inp(uint port_address);

/**
 * ditto
 */
ushort inpw(uint port_address);

/**
 * ditto
 */
uint   inpl(uint port_address);


/**
 * Writes and returns value to I/O port at port_address.
 */
ubyte  outp(uint port_address, ubyte value);

/**
 * ditto
 */
ushort outpw(uint port_address, ushort value);

/**
 * ditto
 */
uint   outpl(uint port_address, uint value);


