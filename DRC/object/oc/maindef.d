module maindef;
import cidrus, stdrus;

alias char int8;
alias ubyte uint8;
alias short int16;
alias ushort uint16;
alias int int32;
alias uint uint32;
alias long int64;
alias ulong uint64;

// Get high part of a 64-bit integer
static uint32 HighDWord (uint64 x) {
   return cast(uint32)(x >> 32);
}

// Max file name length
const MAXFILENAMELENGTH   =    256;


// File types 
const FILETYPE_COFF    =          1 ;       // Windows COFF/PE file
const FILETYPE_OMF           =    2 ;        // Windows OMF file
const FILETYPE_ELF           =    3 ;       // Linux or BSD ELF file
const FILETYPE_MACHO_LE       =   4 ;        // Mach-O file, little endian
const FILETYPE_MACHO_BE         = 5 ;       // Mach-O file, big endian
const FILETYPE_DOS           =    6 ;       // DOS file
const FILETYPE_WIN3X          =   7 ;      // Windows 3.x file
const IMPORT_LIBRARY_MEMBER =  0x10 ;      // Member of import library, Windows
const FILETYPE_MAC_UNIVBIN   = 0x11 ;        // Macintosh universal binary
const FILETYPE_MS_WPO       =  0x20 ;       // Object file for whole program optimization, MS
const FILETYPE_INTEL_WPO   =   0x21 ;       // Object file for whole program optimization, Intel
const FILETYPE_WIN_UNKNOWN  =  0x29 ;      // Unknown subtype, Windows
const FILETYPE_ASM       =    0x100 ;        // Disassembly output
const FILETYPE_LIBRARY    =  0x1000 ;       // UNIX-style library/archive
const FILETYPE_OMFLIBRARY =  0x2000 ;       // OMF-style  library


// Define constants for symbol scope
const S_LOCAL   =  0 ;                    // Local symbol. Accessed only internally
const S_PUBLIC   = 1 ;                       // Public symbol. Visible from other modules
const S_EXTERNAL = 2 ;                       // External symbol. Defined in another module


// Structures and functions used for lookup tables:

// Structure of integers and char *, used for tables of text strings
struct SIntTxt {
 int a;
 char *b;
};
/+
// Translate integer value to text string by looking up in table of SIntTxt.
// Parameters: p = table, n = length of table, x = value to find in table
static char* LookupText(SIntTxt *p, int n, int x) {
   for (int i=0; i<n; i++, p++) {
      if (p.a == x) return p.b;
   }
   // Not found
   static char utext[32];
   sprintf(вТкст0(вЮ8(utext)), вТкст0("unknown(0x%X)"), utext.sizeof,  x);
   return utext;
}

// Macro to calculate the size of an array
template TableSize(A x) {return x.sizeof/x[0].sizeof;}

// Macro to get length of text list and call LookupText
template Lookup(L list,A x) { LookupText(list, list.sizeof/list[0].sizeof, x;}


// Function to convert powers of 2 to index
int FloorLog2(uint32 x);

// Convert 32 bit time stamp to string
char * timestring(uint32 t);
+/
