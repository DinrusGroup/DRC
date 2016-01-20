/* Converted to D from maindef.h by htod */
module maindef;
/****************************  maindef.h   **********************************
* Author:        Agner Fog
* Date created:  2006-08-26
* Last modified: 2009-07-16
* Project:       objconv
* Module:        maindef.h
* Description:
* Header file for type definitions and other main definitions.
*
* Copyright 2006-2009 GNU General Public License http://www.gnu.org/licenses
*****************************************************************************/
//C     #ifndef MAINDEF_H
//C     #define MAINDEF_H

// Program version
//C     #define OBJCONV_VERSION         2.09

const OBJCONV_VERSION = 2.09;

// Integer type definitions with platform-independent sizes:
//C     #if defined(__GNUC__)
  // Compilers supporting C99 or C++0x have inttypes.h defining these integer types
  // This is the preferred solution:
//C       #include <inttypes.h>
  //typedef int8_t         int8;       // Gnu compiler can't convert int8_t to char
//C       typedef char             int8;       // 8 bit  signed integer
//C       typedef uint8_t          uint8;      // 8 bit  unsigned integer
//C       typedef int16_t          int16;      // 16 bit signed integer
//C       typedef uint16_t         uint16;     // 16 bit unsigned integer
//C       typedef int32_t          int32;      // 32 bit signed integer
//C       typedef uint32_t         uint32;     // 32 bit unsigned integer
//C       typedef int64_t          int64;      // 64 bit signed integer
//C       typedef uint64_t         uint64;     // 64 bit unsigned integer

//C     #else

//C     typedef char               int8;       // 8 bit  signed integer
extern (C):
alias char int8;
//C     typedef unsigned char      uint8;      // 8 bit  unsigned integer
alias ubyte uint8;
//C     typedef short int          int16;      // 16 bit signed integer
alias short int16;
//C     typedef unsigned short int uint16;     // 16 bit unsigned integer
alias ushort uint16;
//C     typedef int                int32;      // 32 bit signed integer
alias int int32;
//C     typedef unsigned int       uint32;     // 32 bit unsigned integer
alias uint uint32;

// Definition of 64 bit integers depends on platform
//C     #if defined(_MSC_VER)
// Microsofts typenames:
//C     typedef __int64            int64;      // 64 bit signed integer
//C     typedef unsigned __int64   uint64;     // 64 bit unsigned integer

//C     #else
// This works with most compilers:
//C     typedef long long          int64;      // 64 bit signed integer
alias long int64;
//C     typedef unsigned long long uint64;     // 64 bit unsigned integer
alias ulong uint64;
//C     #endif
//C     #endif


// Get high part of a 64-bit integer
//C     static inline uint32 HighDWord (uint64 x) {
//C        return (uint32)(x >> 32);
//C     }

// Check if compiling for big-endian machine 
// (__BIG_ENDIAN__ may not be defined even on big endian systems, so this check is not 
// sufficient. A further check is done in CheckEndianness() in main.cpp)
//C     #if defined(__BIG_ENDIAN__) && (__BIG_ENDIAN__ != 4321)
//C        #error This machine has big-endian memory organization. Objconv program will not work
//C     #endif

// Max file name length
//C     #define MAXFILENAMELENGTH        256

const MAXFILENAMELENGTH = 256;

// File types 
//C     #define FILETYPE_COFF              1         // Windows COFF/PE file
//C     #define FILETYPE_OMF               2         // Windows OMF file
const FILETYPE_COFF = 1;
//C     #define FILETYPE_ELF               3         // Linux or BSD ELF file
const FILETYPE_OMF = 2;
//C     #define FILETYPE_MACHO_LE          4         // Mach-O file, little endian
const FILETYPE_ELF = 3;
//C     #define FILETYPE_MACHO_BE          5         // Mach-O file, big endian
const FILETYPE_MACHO_LE = 4;
//C     #define FILETYPE_DOS               6         // DOS file
const FILETYPE_MACHO_BE = 5;
//C     #define FILETYPE_WIN3X             7         // Windows 3.x file
const FILETYPE_DOS = 6;
//C     #define IMPORT_LIBRARY_MEMBER   0x10         // Member of import library, Windows
const FILETYPE_WIN3X = 7;
//C     #define FILETYPE_MAC_UNIVBIN    0x11         // Macintosh universal binary
const IMPORT_LIBRARY_MEMBER = 0x10;
//C     #define FILETYPE_MS_WPO         0x20         // Object file for whole program optimization, MS
const FILETYPE_MAC_UNIVBIN = 0x11;
//C     #define FILETYPE_INTEL_WPO      0x21         // Object file for whole program optimization, Intel
const FILETYPE_MS_WPO = 0x20;
//C     #define FILETYPE_WIN_UNKNOWN    0x29         // Unknown subtype, Windows
const FILETYPE_INTEL_WPO = 0x21;
//C     #define FILETYPE_ASM           0x100         // Disassembly output
const FILETYPE_WIN_UNKNOWN = 0x29;
//C     #define FILETYPE_LIBRARY      0x1000         // UNIX-style library/archive
const FILETYPE_ASM = 0x100;
//C     #define FILETYPE_OMFLIBRARY   0x2000         // OMF-style  library
const FILETYPE_LIBRARY = 0x1000;

const FILETYPE_OMFLIBRARY = 0x2000;

// Define constants for symbol scope
//C     #define S_LOCAL     0                        // Local symbol. Accessed only internally
//C     #define S_PUBLIC    1                        // Public symbol. Visible from other modules
const S_LOCAL = 0;
//C     #define S_EXTERNAL  2                        // External symbol. Defined in another module
const S_PUBLIC = 1;

const S_EXTERNAL = 2;

// Macro to calculate the size of an array
//C     #define TableSize(x) (sizeof(x)/sizeof(x[0]))


// Structures and functions used for lookup tables:

// Structure of integers and char *, used for tables of text strings
//C     struct SIntTxt {
uint32  HighDWord(uint64 );
//C        int a;
//C        const char * b;
//C     };
struct SIntTxt
{
    int a;
    char *b;
}

// Translate integer value to text string by looking up in table of SIntTxt.
// Parameters: p = table, n = length of table, x = value to find in table
//C     static inline char const * LookupText(SIntTxt const * p, int n, int x) {
//C        for (int i=0; i<n; i++, p++) {
//C           if (p->a == x) return p->b;
//C        }
   // Not found
//C        static char utext[32];
//C        sprintf_s(utext, sizeof(utext), "unknown(0x%X)", x);
//C        return utext;
