/*===-- include/llvm-c/DataTypes.h - Define fixed size types ------*- к -*-===*\
|*                                                                            *|
|* Part of the LLVM Project, under the Apache License v2.0 with LLVM          *|
|* Exceptions.                                                                *|
|* See https://llvm.org/LICENSE.txt for license information.                  *|
|* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    *|
|*                                                                            *|
|*===----------------------------------------------------------------------===*|
|*                                                                            *|
|* This file contains definitions to figure out the size of _HOST_ data types.*|
|* This file is important because different host OS's define different macros,*|
|* which makes portability tough.  This file exports the following            *|
|* definitions:                                                               *|
|*                                                                            *|
|*   [u]цел(32|64)_t : typedefs for signed and бцел 32/64 bit system types*|
|*   [U]INT(8|16|32|64)_(MIN|MAX) : Constants for the min and max values.     *|
|*                                                                            *|
|* No library is required when using these functions.                         *|
|*                                                                            *|
|*===----------------------------------------------------------------------===*/

module ll.DataTypes;
import cidrus: ДВОБЕСК;

//version(_WIN64)
//alias signed __int64 ssize_t;
//else
alias бцел ssize_t;
alias int64_t off_t;

/* Set defaults for constants which we cannot find. */
const плав HUGE_VALF = ДВОБЕСК;

// Can't be `private` because of @@@BUG11173@@@.
T _typify(T)(T знач){ return знач; }

extern (C):

/+
static if (is(ucent))
{
    alias cent int128_t ;   ///
    alias ucent uint128_t; ///
}

version (Windows)
{
    alias byte int8_t ;   ///
    alias short int16_t;  ///
    alias ubyte uint8_t;  ///
    alias ushort uint16_t; ///
    alias цел int32_t;  ///
    alias бцел uint32_t; ///
    alias long int64_t;   ///
    alias бдол uint64_t;  ///

    alias byte int_least8_t;     ///
    alias ubyte uint_least8_t;    ///
    alias short int_least16_t;    ///
    alias ushort uint_least16_t;   ///
    alias int32_t int_least32_t;  ///
    alias uint32_t uint_least32_t; ///
    alias long int_least64_t;     ///
    alias бдол uint_least64_t;    ///

    alias byte int_fast8_t ;     ///
    alias ubyte uint_fast8_t ;    ///
    alias цел int_fast16_t;      ///
    alias бцел uint_fast16_t;     ///
    alias int32_t int_fast32_t ;  ///
    alias uint32_t uint_fast32_t; ///
    alias long int_fast64_t;     ///
    alias бдол uint_fast64_t;    ///

    alias ptrdiff_t intptr_t; ///
    alias т_мера uintptr_t;    ///
    alias long intmax_t;      ///
    alias бдол uintmax_t;     ///
}
+/
///
const int8_t   INT8_MIN  = int8_t.min;
///
const int8_t   INT8_MAX  = int8_t.max;
///
const int16_t  INT16_MIN = int16_t.min;
///
const int16_t  INT16_MAX = int16_t.max;
///
const int32_t  INT32_MIN = int32_t.min;
///
const int32_t  INT32_MAX = int32_t.max;
///
const int64_t  INT64_MIN = int64_t.min;
///
const int64_t  INT64_MAX = int64_t.max;

///
const uint8_t  UINT8_MAX  = uint8_t.max;
///
const uint16_t UINT16_MAX = uint16_t.max;
///
const uint32_t UINT32_MAX = uint32_t.max;
///
const uint64_t UINT64_MAX = uint64_t.max;

///
const int_least8_t    INT_LEAST8_MIN   = int_least8_t.min;
///
const int_least8_t    INT_LEAST8_MAX   = int_least8_t.max;
///
const int_least16_t   INT_LEAST16_MIN  = int_least16_t.min;
///
const int_least16_t   INT_LEAST16_MAX  = int_least16_t.max;
///
const int_least32_t   INT_LEAST32_MIN  = int_least32_t.min;
///
const int_least32_t   INT_LEAST32_MAX  = int_least32_t.max;
///
const int_least64_t   INT_LEAST64_MIN  = int_least64_t.min;
///
const int_least64_t   INT_LEAST64_MAX  = int_least64_t.max;

///
const uint_least8_t   UINT_LEAST8_MAX  = uint_least8_t.max;
///
const uint_least16_t  UINT_LEAST16_MAX = uint_least16_t.max;
///
const uint_least32_t  UINT_LEAST32_MAX = uint_least32_t.max;
///
const uint_least64_t  UINT_LEAST64_MAX = uint_least64_t.max;

///
const int_fast8_t   INT_FAST8_MIN   = int_fast8_t.min;
///
const int_fast8_t   INT_FAST8_MAX   = int_fast8_t.max;
///
const int_fast16_t  INT_FAST16_MIN  = int_fast16_t.min;
///
const int_fast16_t  INT_FAST16_MAX  = int_fast16_t.max;
///
const int_fast32_t  INT_FAST32_MIN  = int_fast32_t.min;
///
const int_fast32_t  INT_FAST32_MAX  = int_fast32_t.max;
///
const int_fast64_t  INT_FAST64_MIN  = int_fast64_t.min;
///
const int_fast64_t  INT_FAST64_MAX  = int_fast64_t.max;

///
const uint_fast8_t  UINT_FAST8_MAX  = uint_fast8_t.max;
///
const uint_fast16_t UINT_FAST16_MAX = uint_fast16_t.max;
///
const uint_fast32_t UINT_FAST32_MAX = uint_fast32_t.max;
///
const uint_fast64_t UINT_FAST64_MAX = uint_fast64_t.max;

///
const intptr_t  INTPTR_MIN  = intptr_t.min;
///
const intptr_t  INTPTR_MAX  = intptr_t.max;

///
const uintptr_t UINTPTR_MIN = uintptr_t.min;
///
const uintptr_t UINTPTR_MAX = uintptr_t.max;

///
const intmax_t  INTMAX_MIN  = intmax_t.min;
///
const intmax_t  INTMAX_MAX  = intmax_t.max;

///
const uintmax_t UINTMAX_MAX = uintmax_t.max;

///
const ptrdiff_t PTRDIFF_MIN = ptrdiff_t.min;
///
const ptrdiff_t PTRDIFF_MAX = ptrdiff_t.max;

///
//const sig_atomic_t SIG_ATOMIC_MIN = sig_atomic_t.min;
///
//const sig_atomic_t SIG_ATOMIC_MAX = sig_atomic_t.max;

///
const т_мера  SIZE_MAX  = т_мера.max;

///
//const wchar_t WCHAR_MIN = wchar_t.min;
///
//const wchar_t WCHAR_MAX = wchar_t.max;

///
//const wint_t  WINT_MIN  = wint_t.min;
///
//const wint_t  WINT_MAX  = wint_t.max;

///
alias _typify!(int8_t) INT8_C;
///
alias _typify!(int16_t) INT16_C;
///
alias _typify!(int32_t) INT32_C;
///
alias _typify!(int64_t) INT64_C;

///
alias _typify!(uint8_t) UINT8_C;
///
alias _typify!(uint16_t) UINT16_C;
///
alias _typify!(uint32_t) UINT32_C;
///
alias _typify!(uint64_t) UINT64_C;

///
alias _typify!(intmax_t) INTMAX_C;
///
alias _typify!(uintmax_t) UINTMAX_C;
