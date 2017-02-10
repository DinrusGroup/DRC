module kong.PE.types;
import kong.internal.stdlib;
// windows header ----------------------------------------------------------


enum {
IMAGE_FILE_MACHINE_I386  = 0x014c,
IMAGE_FILE_MACHINE_IA64  = 0x0200,
IMAGE_FILE_MACHINE_AMD64 = 0x8664
}


template PE_types(int CLASS)
{
    static if (CLASS == IMAGE_FILE_MACHINE_I386)
    {
        alias IMAGE_NT_HEADERS32      IMAGE_NT_HEADERS;
        alias IMAGE_OPTIONAL_HEADER32 IMAGE_OPTIONAL_HEADER;
    }

    static if (CLASS == IMAGE_FILE_MACHINE_IA64 || CLASS == IMAGE_FILE_MACHINE_AMD64)
    {
        alias IMAGE_NT_HEADERS64        IMAGE_NT_HEADERS;
        alias IMAGE_OPTIONAL_HEADER64   IMAGE_OPTIONAL_HEADER;
    }
}

align(4) struct IMAGE_DATA_DIRECTORY
{
    uint   VirtualAddress;
    uint   Size;
}

static assert(IMAGE_DATA_DIRECTORY.sizeof == 8);


align(1) struct IMAGE_DOS_HEADER
{
    ushort   e_magic;                     // Magic number
    ushort   e_cblp;                      // Bytes on last page of file
    ushort   e_cp;                        // Pages in file
    ushort   e_crlc;                      // Relocations
    ushort   e_cparhdr;                   // Size of header in paragraphs
    ushort   e_minalloc;                  // Minimum extra paragraphs needed
    ushort   e_maxalloc;                  // Maximum extra paragraphs needed
    ushort   e_ss;                        // Initial (relative) SS value
    ushort   e_sp;                        // Initial SP value
    ushort   e_csum;                      // Checksum
    ushort   e_ip;                        // Initial IP value
    ushort   e_cs;                        // Initial (relative) CS value
    ushort   e_lfarlc;                    // File address of relocation table
    ushort   e_ovno;                      // Overlay number
    ushort   e_res[4];                    // Reserved words
    ushort   e_oemid;                     // OEM identifier (for e_oeminfo)
    ushort   e_oeminfo;                   // OEM information; e_oemid specific
    ushort   e_res2[10];                  // Reserved words
    int      e_lfanew;                    // File address of new exe header
}

align(4) struct IMAGE_FILE_HEADER
{
    ushort    Machine;
    ushort    NumberOfSections;
    uint      TimeDateStamp;
    uint      PointerToSymbolTable;
    uint      NumberOfSymbols;
    ushort    SizeOfOptionalHeader;
    ushort    Characteristics;
}

static assert(IMAGE_FILE_HEADER.sizeof == 20);


struct IMAGE_NT_HEADERS64
{
    uint Signature;
    IMAGE_FILE_HEADER FileHeader;
    IMAGE_OPTIONAL_HEADER64 OptionalHeader;
}

struct IMAGE_NT_HEADERS32
{
    uint Signature;
    IMAGE_FILE_HEADER FileHeader;
    IMAGE_OPTIONAL_HEADER32 OptionalHeader;
}

const IMAGE_NUMBEROF_DIRECTORY_ENTRIES = 16 ;

align(4) struct IMAGE_OPTIONAL_HEADER32
{
    //
    // Standard поля.
    //

    ushort Magic;
    ubyte  MajorLinkerVersion;
    ubyte  MinorLinkerVersion;
    uint   SizeOfCode;
    uint   SizeOfInitializedData;
    uint   SizeOfUninitializedData;
    uint   AddressOfEntryPoint;
    uint   BaseOfCode;
    uint   BaseOfData;

    //
    // NT additional поля.
    //

    uint   ImageBase;
    uint   SectionAlignment;
    uint   FileAlignment;
    ushort    MajorOperatingSystemVersion;
    ushort    MinorOperatingSystemVersion;
    ushort    MajorImageVersion;
    ushort    MinorImageVersion;
    ushort    MajorSubsystemVersion;
    ushort    MinorSubsystemVersion;
    uint   Win32VersionValue;
    uint   SizeOfImage;
    uint   SizeOfHeaders;
    uint   CheckSum;
    ushort    Subsystem;
    ushort    DllCharacteristics;
    uint   SizeOfStackReserve;
    uint   SizeOfStackCommit;
    uint   SizeOfHeapReserve;
    uint   SizeOfHeapCommit;
    uint   LoaderFlags;
    uint   NumberOfRvaAndSizes;
    IMAGE_DATA_DIRECTORY DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES];
}

align(4) struct IMAGE_OPTIONAL_HEADER64
{
    uint16_t   Magic;
    uint8_t    MajorLinkerVersion;
    uint8_t    MinorLinkerVersion;
    uint32_t   SizeOfCode;
    uint32_t   SizeOfInitializedData;
    uint32_t   SizeOfUninitializedData;
    uint32_t   AddressOfEntryPoint;
    uint32_t   BaseOfCode;
    uint64_t   ImageBase;
    uint32_t   SectionAlignment;
    uint32_t   FileAlignment;
    uint16_t   MajorOperatingSystemVersion;
    uint16_t   MinorOperatingSystemVersion;
    uint16_t   MajorImageVersion;
    uint16_t   MinorImageVersion;
    uint16_t   MajorSubsystemVersion;
    uint16_t   MinorSubsystemVersion;
    uint32_t   Win32VersionValue;
    uint32_t   SizeOfImage;
    uint32_t   SizeOfHeaders;
    uint32_t   CheckSum;
    uint16_t   Subsystem;
    uint16_t   DllCharacteristics;
    uint64_t   SizeOfStackReserve;
    uint64_t   SizeOfStackCommit;
    uint64_t   SizeOfHeapReserve;
    uint64_t   SizeOfHeapCommit;
    uint32_t   LoaderFlags;
    uint32_t   NumberOfRvaAndSizes;
    IMAGE_DATA_DIRECTORY DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES];
}

static assert(IMAGE_OPTIONAL_HEADER32.sizeof == 224);
static assert(IMAGE_OPTIONAL_HEADER64.sizeof == 240);



enum { IMAGE_SIZEOF_SHORT_NAME = 8 };

align(4) struct IMAGE_SECTION_HEADER
{
    ubyte    Name[IMAGE_SIZEOF_SHORT_NAME];
    union {
            uint   PhysicalAddress;
            uint   VirtualSize;
    }
    uint   VirtualAddress;
    uint   SizeOfRawData;
    uint   PointerToRawData;
    uint   PointerToRelocations;
    uint   PointerToLinenumbers;
    ushort    NumberOfRelocations;
    ushort    NumberOfLinenumbers;
    uint   Characteristics;
}

static assert(IMAGE_SECTION_HEADER.sizeof == 40);



align(4) struct IMAGE_BASE_RELOCATION
{
    uint   VirtualAddress;
    uint   SizeOfBlock;
//  WORD    TypeOffset[1];
}

static assert(IMAGE_BASE_RELOCATION.sizeof == 8);

struct IMAGE_IMPORT_BY_NAME
{
    ushort  Hint;
    char    Name[0];
}


align(4) struct IMAGE_IMPORT_DESCRIPTOR
{
    union {
        uint   Characteristics;            // 0 for terminating пусто import descriptor
        uint   OriginalFirstThunk;         // RVA to original unbound IAT (PIMAGE_THUNK_DATA)
    };
    uint   TimeDateStamp;                  // 0 if not bound,
                                           // -1 if bound, and real date\time stamp
                                           //     in IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT (new BIND)
                                           // O.W. date/time stamp of DLL bound to (Old BIND)

    uint   ForwarderChain;                 // -1 if no forwarders
    uint   Name;
    uint   FirstThunk;                     // RVA to IAT (if bound this IAT has actual addresses)
}


align(4) struct IMAGE_EXPORT_DIRECTORY
{
    uint   Characteristics;
    uint   TimeDateStamp;
    ushort MajorVersion;
    ushort MinorVersion;
    uint   Name;
    uint   Base;
    uint   NumberOfFunctions;
    uint   NumberOfNames;
    uint   AddressOfFunctions;     // RVA from base of image
    uint   AddressOfNames;         // RVA from base of image
    uint   AddressOfNameOrdinals;  // RVA from base of image
}


enum
{
IMAGE_SIZEOF_BASE_RELOCATION     = 8,
IMAGE_REL_BASED_ABSOLUTE         = 0,
IMAGE_REL_BASED_HIGH             = 1,
IMAGE_REL_BASED_LOW              = 2,
IMAGE_REL_BASED_HIGHLOW          = 3,
IMAGE_REL_BASED_HIGHADJ          = 4,
IMAGE_REL_BASED_MIPS_JMPADDR     = 5,
IMAGE_REL_BASED_MIPS_JMPADDR16   = 9,
IMAGE_REL_BASED_IA64_IMM64       = 9,
IMAGE_REL_BASED_DIR64            = 10,

IMAGE_SCN_LNK_NRELOC_OVFL        = 0x01000000,  // Section contains extended relocations.
IMAGE_SCN_MEM_DISCARDABLE        = 0x02000000,  // Section can be discarded.
IMAGE_SCN_MEM_NOT_CACHED         = 0x04000000,  // Section is not cachable.
IMAGE_SCN_MEM_NOT_PAGED          = 0x08000000,  // Section is not pageable.
IMAGE_SCN_MEM_SHARED             = 0x10000000,  // Section is shareable.
IMAGE_SCN_MEM_EXECUTE            = 0x20000000,  // Section is executable.
IMAGE_SCN_MEM_READ               = 0x40000000,  // Section is readable.
IMAGE_SCN_MEM_WRITE              = 0x80000000,  // Section is writeable.
IMAGE_SCN_CNT_CODE               = 0x00000020,  // Section contains code.
IMAGE_SCN_CNT_INITIALIZED_DATA   = 0x00000040,  // Section contains initialized data.
IMAGE_SCN_CNT_UNINITIALIZED_DATA = 0x00000080,  // Section contains uninitialized data.
IMAGE_DIRECTORY_ENTRY_EXPORT         = 0,   // Export Directory
IMAGE_DIRECTORY_ENTRY_IMPORT         = 1,   // Import Directory
IMAGE_DIRECTORY_ENTRY_RESOURCE       = 2,   // Resource Directory
IMAGE_DIRECTORY_ENTRY_EXCEPTION      = 3,   // Exception Directory
IMAGE_DIRECTORY_ENTRY_SECURITY       = 4,   // Security Directory
IMAGE_DIRECTORY_ENTRY_BASERELOC      = 5,   // Base Relocation Table
IMAGE_DIRECTORY_ENTRY_DEBUG          = 6,   // Debug Directory
IMAGE_DIRECTORY_ENTRY_COPYRIGHT      = 7,   // (X86 usage)
IMAGE_DIRECTORY_ENTRY_ARCHITECTURE   = 7,   // Architecture Specific Data
IMAGE_DIRECTORY_ENTRY_GLOBALPTR      = 8,   // RVA of GP
IMAGE_DIRECTORY_ENTRY_TLS            = 9,   // TLS Directory
IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG    = 10,  // Load Configuration Directory
IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT   = 11,  // Bound Import Directory in headers
IMAGE_DIRECTORY_ENTRY_IAT            = 12,  // Import Address Table
IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT   = 13,  // Delay Load Import Descriptors
IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR = 14,  // COM Runtime descriptor

IMAGE_DOS_SIGNATURE    = 0x5A4D,      // MZ
IMAGE_OS2_SIGNATURE    = 0x454E,      // NE
IMAGE_OS2_SIGNATURE_LE = 0x454C,      // LE
IMAGE_VXD_SIGNATURE    = 0x454C,      // LE
IMAGE_NT_SIGNATURE     = 0x00004550,  // PE00
}

//extern (Windows) void* GetProcAddress(void*, char*);
extern (Windows) int IsBadReadPtr(void*, uintptr_t);

alias void* PS_POST_PROCESS_INIT_ROUTINE;

struct UNICODE_STRING {
  ushort  Length;
  ushort  MaximumLength;
  wchar*  Buffer;
}

struct LIST_ENTRY
{
   LIST_ENTRY *Flink;
   LIST_ENTRY *Blink;
}

struct PEB_LDR_DATA
{
  uint                   Length;
  ubyte                    Initialized;
  void*                   SsHandle;
  LIST_ENTRY              InLoadOrderModuleList;
  LIST_ENTRY              InMemoryOrderModuleList;
  LIST_ENTRY              InInitializationOrderModuleList;

}

struct RTL_USER_PROCESS_PARAMETERS
{
  ubyte Reserved1[16];
  void* Reserved2[10];
  UNICODE_STRING ImagePathName;
  UNICODE_STRING CommandLine;
}

struct PEB
{
  ubyte Reserved1[2];
  ubyte BeingDebugged;
  ubyte Reserved2[1];
  void* Reserved3[2];
  PEB_LDR_DATA* Ldr;
  RTL_USER_PROCESS_PARAMETERS* ProcessParameters;
  ubyte Reserved4[104];
  void* Reserved5[52];
  PS_POST_PROCESS_INIT_ROUTINE* PostProcessInitRoutine;
  ubyte Reserved6[128];
  void* Reserved7[1];
  uint SessionId;
}

struct PROCESS_BASIC_INFORMATION {
    void* Reserved1;
    PEB* PebBaseAddress;
    void* Reserved2[2];
    uintptr_t UniqueProcessId;
    void* Reserved3;
}

struct LDR_MODULE
{
    LIST_ENTRY InLoadOrderModuleList;
    LIST_ENTRY InMemoryOrderModuleList;
    LIST_ENTRY InInitializationOrderModuleList;
    void* BaseAddress;
    void* EntryPoint;
    uint SizeOfImage;
    UNICODE_STRING FullDllName;
    UNICODE_STRING BaseDllName;
    uint Flags;
    short LoadCount;
    short TlsIndex;
    LIST_ENTRY HashTableEntry;
    uint TimeDateStamp;
}

