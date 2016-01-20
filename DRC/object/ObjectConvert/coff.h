/****************************   coff.h   *************************************
* Author:        Agner Fog
* Date created:  2006-07-15
* Last modified: 2008-06-04
* Project:       objconv
* Module:        coff.h
* Description:
* Файл-заголовок для определения структур в файловом формате объектов MS Windows COFF Intel x86 (PE).
*
* Copyright 2006-2008 GNU General Public License http://www.gnu.org/licenses
* Parts (c) 1995 DJ Delorie GNU General Public License
*****************************************************************************/

/*****************************************************************************
* Note: Структуры данных COFF не совпадают с дефолтной расстановкой современных
* компиляторов. Все структуры следует компилировать без каких-либо alignment padding.
* Спецификация упаковки структур для компиляторов не стандартизирована.
* Можно удалить или заменить директиву #pragma pack, если никогда не будет использоваться
* оператор sizeof() или арифметика указателей на какие-либо структуры, нуждающиеся в 
* упаковке. Пример смотрите в coff.cpp.
*****************************************************************************/

#ifndef PECOFF_H
#define PECOFF_H

/********************** ЗАГОЛОВОК ФАЙЛА **********************/

struct SCOFF_FileHeader {
 uint16 Machine;              // ИД машины (магическое число)
 uint16 NumberOfSections;     // число секций
 uint32 TimeDateStamp;        // штамп времени и даты 
 uint32 PSymbolTable;         // файловый указатель на таблицу символов
 uint32 NumberOfSymbols;      // число элементов таблицы символов 
 uint16 SizeOfOptionalHeader; // размер опционного заголовка
 uint16 Flags;                // Флаги, указывающие на атрибуты
};

// Значения Machine:
#define PE_MACHINE_I386       0x14c
#define PE_MACHINE_X8664     0x8664

// Биты для Флагов:
#define PE_F_RELFLG 0x0001   // информация о перемещении, убранная из файла
#define PE_F_EXEC   0x0002   // файл исполнимый (нет неопознанных внешних ссылок)
#define PE_F_LNNO   0x0004   // число убранных из файла строк
#define PE_F_LSYMS  0x0008   // число убранных из файла локальных символов


// Структуры, используемые в опционном заголовке
struct SCOFF_IMAGE_DATA_DIRECTORY {
   uint32 VirtualAddress;              // Адрес таблицы относительно имиджа
   uint32 Size;                        // Размер таблицы
};

// Расширенная структура, внутренне используемая с трансляцией виртуальных адресов в секция:офсет
struct SCOFF_ImageDirAddress : public SCOFF_IMAGE_DATA_DIRECTORY {
   int32  Section;                     // Секция, содержащая таблицу
   uint32 SectionOffset;               // офсет относительно секции
   uint32 FileOffset;                  // Офсет относительно файла
   uint32 MaxOffset;                   // Размер секции - SectionOffset
   const char * Name;                  // Название таблицы
};

// Опционный заголовок
union SCOFF_OptionalHeader {
   // 32-битная версия
   struct {
      uint16 Magic;                    // Магическое число
      uint8  LinkerMajorVersion;
      uint8  LinkerMinorVersion;
      uint32 SizeOfCode;
      uint32 SizeOfInitializedData;
      uint32 SizeOfUninitializedData;
      uint32 AddressOfEntryPoint;      // Точка входа относительно основания имиджа
      uint32 BaseOfCode;
      uint32 BaseOfData;
      // Поля, специфичные для Windows
      int32  ImageBase;                // Основание имиджа
      uint32 SectionAlignment;
      uint32 FileAlignment;
      uint16 MajorOperatingSystemVersion;
      uint16 MinorOperatingSystemVersion;
      uint16 MajorImageVersion;
      uint16 MinorImageVersion;
      uint16 MajorSubsystemVersion;
      uint16 MinorSubsystemVersion;
      uint32 Win32VersionValue;        // должно быть 0
      uint32 SizeOfImage;
      uint32 SizeOfHeaders;
      uint32 CheckSum;
      uint16 Subsystem;
      uint16 DllCharacteristics;
      uint32 SizeOfStackReserve;
      uint32 SizeOfStackCommit;
      uint32 SizeOfHeapReserve;
      uint32 SizeOfHeapCommit;
      uint32 LoaderFlags;              // 0
      uint32 NumberOfRvaAndSizes;
      // Каталоги данных
      SCOFF_IMAGE_DATA_DIRECTORY ExportTable;
      SCOFF_IMAGE_DATA_DIRECTORY ImportTable;
      SCOFF_IMAGE_DATA_DIRECTORY ResourceTable;
      SCOFF_IMAGE_DATA_DIRECTORY ExceptionTable;
      SCOFF_IMAGE_DATA_DIRECTORY CertificateTable;
      SCOFF_IMAGE_DATA_DIRECTORY BaseRelocationTable;
      SCOFF_IMAGE_DATA_DIRECTORY Debug;
      SCOFF_IMAGE_DATA_DIRECTORY Architecture;   // 0
      SCOFF_IMAGE_DATA_DIRECTORY GlobalPtr;      // 0
      SCOFF_IMAGE_DATA_DIRECTORY TLSTable;
      SCOFF_IMAGE_DATA_DIRECTORY LoadConfigTable;
      SCOFF_IMAGE_DATA_DIRECTORY BoundImportTable;
      SCOFF_IMAGE_DATA_DIRECTORY ImportAddressTable;
      SCOFF_IMAGE_DATA_DIRECTORY DelayImportDescriptor;
      SCOFF_IMAGE_DATA_DIRECTORY CLRRuntimeHeader;
      SCOFF_IMAGE_DATA_DIRECTORY Reserved;       // 0
   } h32;
   // 64-битная версия
   struct {
      uint16 Magic;                    // Магическое число
      uint8  LinkerMajorVersion;
      uint8  LinkerMinorVersion;
      uint32 SizeOfCode;
      uint32 SizeOfInitializedData;
      uint32 SizeOfUninitializedData;
      uint32 AddressOfEntryPoint;      // Точка входа относительно основания имиджа
      uint32 BaseOfCode;
      // Поля, специфичные для Windows
      int64  ImageBase;                // Основание имиджа
      uint32 SectionAlignment;
      uint32 FileAlignment;
      uint16 MajorOperatingSystemVersion;
      uint16 MinorOperatingSystemVersion;
      uint16 MajorImageVersion;
      uint16 MinorImageVersion;
      uint16 MajorSubsystemVersion;
      uint16 MinorSubsystemVersion;
      uint32 Win32VersionValue;        // должно равняться 0
      uint32 SizeOfImage;
      uint32 SizeOfHeaders;
      uint32 CheckSum;
      uint16 Subsystem;
      uint16 DllCharacteristics;
      uint64 SizeOfStackReserve;
      uint64 SizeOfStackCommit;
      uint64 SizeOfHeapReserve;
      uint64 SizeOfHeapCommit;
      uint32 LoaderFlags;              // 0
      uint32 NumberOfRvaAndSizes;
      // Data directories
      SCOFF_IMAGE_DATA_DIRECTORY ExportTable;
      SCOFF_IMAGE_DATA_DIRECTORY ImportTable;
      SCOFF_IMAGE_DATA_DIRECTORY ResourceTable;
      SCOFF_IMAGE_DATA_DIRECTORY ExceptionTable;
      SCOFF_IMAGE_DATA_DIRECTORY CertificateTable;
      SCOFF_IMAGE_DATA_DIRECTORY BaseRelocationTable;
      SCOFF_IMAGE_DATA_DIRECTORY Debug;
      SCOFF_IMAGE_DATA_DIRECTORY Architecture;   // 0
      SCOFF_IMAGE_DATA_DIRECTORY GlobalPtr;      // 0
      SCOFF_IMAGE_DATA_DIRECTORY TLSTable;
      SCOFF_IMAGE_DATA_DIRECTORY LoadConfigTable;
      SCOFF_IMAGE_DATA_DIRECTORY BoundImportTable;
      SCOFF_IMAGE_DATA_DIRECTORY ImportAddressTable;
      SCOFF_IMAGE_DATA_DIRECTORY DelayImportDescriptor;
      SCOFF_IMAGE_DATA_DIRECTORY CLRRuntimeHeader;
      SCOFF_IMAGE_DATA_DIRECTORY Reserved;       // 0
   } h64;
};

// Значение Magic для опционного заголовка
#define COFF_Magic_PE32  0x10B
#define COFF_Magic_PE64  0x20B

// Export directory table
struct SCOFF_ExportDirectory {
   uint32 Flags;
   uint32 DateTime;
   uint16 VersionMajor;
   uint16 VersionMinor;
   uint32 DLLNameRVA;                  // Адрес названия DLL, относительно имиджа
   uint32 OrdinalBase;                 // Порядковый номер первого экспорта
   uint32 AddressTableEntries;         // Число элементов в адресной таблице экспорта
   uint32 NamePointerEntries;          // Число элементов в таблице указателей на наименования
   uint32 ExportAddressTableRVA;       // Адрес адресной таблицы экспорта, относительно имиджа
   uint32 NamePointerTableRVA;         // Адрес таблицы указателей на экспортируемые наименования относительно имиджа
   uint32 OrdinalTableRVA;             // Адрес таблицы порядковых номеров, относительно имиджа
};

// Таблица каталогов импорта
struct SCOFF_ImportDirectory {
   uint32 ImportLookupTableRVA;        // Адрес таблицы просмотра импорта, относительно имиджа
   uint32 DateTime;
   uint32 ForwarderChain;
   uint32 DLLNameRVA;                  // Алрес строки названия DLL, относительно имиджа
   uint32 ImportAddressTableRVA;       // Адрес адресной таблицы импорта, относительно имиджа
};

// Элемент таблицы Import hint/name
struct SCOFF_ImportHintName {
   uint16 Hint;                        // Индекс в таблице указателей на экспортируемые наименования
   char   Name[2];                     // Переменная длина
};

// Базовый заголовок релокации блока
struct SCOFF_BaseRelocationBlock {
   uint32 PageRVA;                     // База, добавляемая к офсету, взятая относительно имиджа
   uint32 BlockSize;                   // Размер SCOFF_BaseRelocationBlock плюс все SCOFF_BaseRelocation
};

// Базовые элементы релокации блока
struct SCOFF_BaseRelocation {
   uint16 Offset:12;                   // Офсет относительно PageRVA
   uint16 Type:4;                      // Базовый тип релокации
};

// Базовые типы релокации
#define  COFF_REL_BASED_ABSOLUTE   0   // Игнорировать
#define  COFF_REL_BASED_HIGH       1   // Старшие 16 бит
#define  COFF_REL_BASED_LOW        2   // Младшие 16 бит
#define  COFF_REL_BASED_HIGHLOW    3   // 32 бита
#define  COFF_REL_BASED_HIGHADJ    4   // Две последовательные записи: 16 старших бит, 16 младших бит
#define  COFF_REL_BASED_DIR64     10   // 64 бита


/********************** ЗАГОЛОВОК СЕКЦИИ **********************/

struct SCOFF_SectionHeader {
 char    Name[8];        // название секции
 uint32  VirtualSize;    // размер секции при загрузке. (Должен быть 0 для объектных файлов, но, кажется, это общий размер всех секций)
 uint32  VirtualAddress; // отнимается от офсета при релокации. Предпочтительно 0
 uint32  SizeOfRawData;  // размер секции в файле
 uint32  PRawData;       // файловый указатель на необработанные данные для секции
 uint32  PRelocations;   // файловый указатель на элементы релокации
 uint32  PLineNumbers;   // файловый указатель на элементы номеров строк
 uint16  NRelocations;   // число элементов релокации
 uint16  NLineNumbers;   // число элементов номеров строк
 uint32  Flags;          // флаги   
};

// Значения флагов секции
#define PE_SCN_CNT_CODE         0x00000020  // раздел с исполняемым кодом
#define PE_SCN_CNT_INIT_DATA    0x00000040  // раздел с инициализованными данными
#define PE_SCN_CNT_UNINIT_DATA  0x00000080  // раздел с неинициализованными данными
#define PE_SCN_LNK_INFO         0x00000200  // раздел с комментариями или .drectve
#define PE_SCN_LNK_REMOVE       0x00000800  // не будет входить в имидж. Только файлы объектов
#define PE_SCN_LNK_COMDAT       0x00001000  // раздел с коммунальными данными
#define PE_SCN_ALIGN_1          0x00100000  // Расставить данные по 1
#define PE_SCN_ALIGN_2          0x00200000  // Расставить данные по 2
#define PE_SCN_ALIGN_4          0x00300000  // Расставить данные по 4
#define PE_SCN_ALIGN_8          0x00400000  // Расставить данные по 8
#define PE_SCN_ALIGN_16         0x00500000  // Расставить данные по 16
#define PE_SCN_ALIGN_32         0x00600000  // Расставить данные по 32
#define PE_SCN_ALIGN_64         0x00700000  // Расставить данные по 64
#define PE_SCN_ALIGN_128        0x00800000  // Расставить данные по 128
#define PE_SCN_ALIGN_256        0x00900000  // Расставить данные по 256
#define PE_SCN_ALIGN_512        0x00a00000  // Расставить данные по 512
#define PE_SCN_ALIGN_1024       0x00b00000  // Расставить данные по 1024
#define PE_SCN_ALIGN_2048       0x00c00000  // Расставить данные по 2048
#define PE_SCN_ALIGN_4096       0x00d00000  // Расставить данные по 4096
#define PE_SCN_ALIGN_8192       0x00e00000  // Расставить данные по 8192
#define PE_SCN_ALIGN_MASK       0x00f00000  // Маска для извлечения информации о расстановке
#define PE_SCN_LNK_NRELOC_OVFL  0x01000000  // раздел с расширенными релокациями (перемещениями)
#define PE_SCN_MEM_DISCARDABLE  0x02000000  // section is discardable
#define PE_SCN_MEM_NOT_CACHED   0x04000000  // некешируемый раздел
#define PE_SCN_MEM_NOT_PAGED    0x08000000  // section is not pageable
#define PE_SCN_MEM_SHARED       0x10000000  // разделяемая секция
#define PE_SCN_MEM_EXECUTE      0x20000000  // исполняемый раздел
#define PE_SCN_MEM_READ         0x40000000  // читаемый раздел
#define PE_SCN_MEM_WRITE        0x80000000  // записываемый раздел

/* названия "особых" разделов 
#define _TEXT ".text"
#define _DATA ".data"
#define _BSS ".bss"
#define _COMMENT ".comment"
#define _LIB ".lib"  */

/********************** НОМЕРА СТРОК **********************/

/* 1 line number entry for every "breakpointable" source line in a section.
 * Номера строк группируются по функциям; первый элемент в группировании
 * функций имеет l_lnno = 0, а вместо физического адреса применяется
 * индекс таблицы символов для названия функции.
 */
//#pragma pack(push, 1)
struct SCOFF_LineNumbers {
 union {
  uint32 Fname;    // function name symbol table index, if Line == 0
  uint32 Addr;     // section-relative address of code that corresponds to line
 };
 uint16 Line;      // номер строки
};

// Warning: Size does not fit standard alignment!
// Use SIZE_SCOFF_LineNumbers instead of sizeof(SCOFF_LineNumbers)
#define SIZE_SCOFF_LineNumbers  6  // Size of SCOFF_LineNumbers packed

//#pragma pack(pop)


/******** ЭЛЕМЕНТ ТАБЛИЦЫ СИМВОЛОВ И ВСПОМОГАТЕЛЬНЫЙ ЭЛЕМЕНТ ТАБЛИЦЫ СИМВОЛОВ ********/
//#pragma pack(push, 1)  //__attribute__((packed));

union SCOFF_SymTableEntry {
   // Normal symbol table entry
   struct {
      char   Name[8];
      uint32 Value;
      int16  SectionNumber;
      uint16 Type;
      uint8  StorageClass;
      uint8  NumAuxSymbols;
   } s;
   // Auxiliary symbol table entry types:

   // Function definition
   struct {
      uint32 TagIndex; // Index to .bf entry
      uint32 TotalSize; // Size of function code
      uint32 PointerToLineNumber; // Pointer to line number entry
      uint32 PointerToNextFunction; // Symbol table index of next function
      uint16 x_tvndx;      // Unused
   } func;

   // .bf abd .ef
   struct {
      uint32 Unused1;
      uint16 SourceLineNumber; // Line number in source file
      uint16 Unused2;
      uint32 Unused3; // Pointer to line number entry
      uint32 PointerToNextFunction; // Symbol table index of next function
      uint16 Unused4;      // Unused
   } bfef;

   // Weak external
   struct {
      uint32 TagIndex; // Symbol table index of alternative symbol2
      uint32 Characteristics; //
      uint32 Unused1; 
      uint32 Unused2; 
      uint16 Unused3;      // Unused
   } weak;

   // File name
   struct {
      char FileName[18];// File name
   } filename;

   // String table index
   struct {          // MS COFF uses multiple aux records rather than a string table entry!
      uint32 zeroes; // zeroes if name file name longer than 18
      uint32 offset; // string table entry
   } stringindex;

   // Section definition
   struct {
      uint32 Length;
      uint16 NumberOfRelocations;  // Line number in source file
      uint16 NumberOfLineNumbers;
      uint32 CheckSum;             // Pointer to line number entry
      uint16 Number;               // Symbol table index of next function
      uint8  Selection;            // Unused
      uint8  Unused1[3];
   } section;
};

// Warning: Size does not fit standard alignment!
// Use SIZE_SCOFF_SymTableEntry instead of sizeof(SCOFF_SymTableEntry)
#define SIZE_SCOFF_SymTableEntry  18  // Size of SCOFF_SymTableEntry packed

/*
#define N_BTMASK (0xf)
#define N_TMASK  (0x30)
#define N_BTSHFT (4)
#define N_TSHIFT (2)

  */

//#pragma pack(pop)

/********************** ЗНАЧЕНИЯ НОМЕРОВ СЕКЦИЙ ДЛЯ ЭЛЕМЕНТОВ ТАБЛИЦЫ СИМВОЛОВ **********************/
    
#define COFF_SECTION_UNDEF ((int16)0)      // external symbol
#define COFF_SECTION_ABSOLUTE ((int16)-1)  // value of symbol is absolute
#define COFF_SECTION_DEBUG ((int16)-2)     // debugging symbol - value is meaningless
#define COFF_SECTION_N_TV ((int16)-3)      // indicates symbol needs preload transfer vector
#define COFF_SECTION_P_TV ((int16)-4)      // indicates symbol needs postload transfer vector
#define COFF_SECTION_REMOVE_ME ((int16)-99)// Specific for objconv program: Debug or exception section being removed

/*
 * Type of a symbol, in low N bits of the word

#define T_NULL  0
#define T_VOID  1 // function argument (only used by compiler) 
#define T_CHAR  2 // character  
#define T_SHORT  3 // short integer 
#define T_INT  4 // integer  
#define T_LONG  5 // long integer  
#define T_FLOAT  6 // floating point 
#define T_DOUBLE 7 // double word  
#define T_STRUCT 8 // structure   
#define T_UNION  9 // union   
#define T_ENUM  10 // enumeration   
#define T_MOE  11 // member of enumeration
#define T_UCHAR  12 // unsigned character 
#define T_USHORT 13 // uint16 
#define T_UINT  14 // unsigned integer 
#define T_ULONG  15 // uint32 
#define T_LNGDBL 16 // long double  
 */
/*
 * derived types, in n_type

#define DT_NON  (0) // no derived type 
#define DT_PTR  (1) // pointer 
 #define DT_FCN  (2) // function 
#define DT_ARY  (3) // array 

#define BTYPE(x) ((x) & N_BTMASK)

#define ISPTR(x) (((x) & N_TMASK) == (DT_PTR << N_BTSHFT))
#define ISFCN(x) (((x) & N_TMASK) == (DT_FCN << N_BTSHFT))
#define ISARY(x) (((x) & N_TMASK) == (DT_ARY << N_BTSHFT))
#define ISTAG(x) ((x)==C_STRTAG||(x)==C_UNTAG||(x)==C_ENTAG)
#define DECREF(x) ((((x)>>N_TSHIFT)&~N_BTMASK)|((x)&N_BTMASK))
 */
/********************** КЛАССЫ ХРАНЕНИЯ ДЛЯ ЭЛЕМЕНТОВ ТАБЛИЦЫ СИМВОЛОВ **********************/

#define COFF_CLASS_NULL                    0
#define COFF_CLASS_AUTOMATIC               1 // automatic variable
#define COFF_CLASS_EXTERNAL                2 // external symbol 
#define COFF_CLASS_STATIC                  3 // static
#define COFF_CLASS_REGISTER                4 // register variable
#define COFF_CLASS_EXTERNAL_DEF            5 // external definition 
#define COFF_CLASS_LABEL                   6 // label
#define COFF_CLASS_UNDEFINED_LABEL         7 // undefined label
#define COFF_CLASS_MEMBER_OF_STRUCTURE     8 // member of structure
#define COFF_CLASS_ARGUMENT                9 // function argument
#define COFF_CLASS_STRUCTURE_TAG          10 // structure tag 
#define COFF_CLASS_MEMBER_OF_UNION        11 // member of union 
#define COFF_CLASS_UNION_TAG              12 // union tag 
#define COFF_CLASS_TYPE_DEFINITION        13 // type definition
#define COFF_CLASS_UNDEFINED_STATIC       14 // undefined static 
#define COFF_CLASS_ENUM_TAG               15 // enumeration tag 
#define COFF_CLASS_MEMBER_OF_ENUM         16 // member of enumeration
#define COFF_CLASS_REGISTER_PARAM         17 // register parameter
#define COFF_CLASS_BIT_FIELD              18 // bit field  
#define COFF_CLASS_AUTO_ARGUMENT          19 // auto argument 
#define COFF_CLASS_LASTENTRY              20 // dummy entry (end of block)
#define COFF_CLASS_BLOCK                 100 // ".bb" or ".eb" 
#define COFF_CLASS_FUNCTION              101 // ".bf" or ".ef" 
#define COFF_CLASS_END_OF_STRUCT         102 // end of structure 
#define COFF_CLASS_FILE                  103 // file name  
#define COFF_CLASS_LINE                  104 // line # reformatted as symbol table entry 
#define COFF_CLASS_SECTION               104 // line # reformatted as symbol table entry
#define COFF_CLASS_ALIAS                 105 // duplicate tag 
#define COFF_CLASS_WEAK_EXTERNAL         105 // duplicate tag  
#define COFF_CLASS_HIDDEN                106 // ext symbol in dmert public lib 
#define COFF_CLASS_END_OF_FUNCTION      0xff // physical end of function 

/********************** ТИП ДЛЯ ЭЛЕМЕНТОВ ТАБЛИЦЫ СИМВОЛОВ **********************/
#define COFF_TYPE_FUNCTION              0x20 // Symbol is function
#define COFF_TYPE_NOT_FUNCTION          0x00 // Symbol is not a function


/********************** ЭЛЕМЕНТ ТАБЛИЦЫ РЕЛОКАЦИИ **********************/
//#pragma pack(push, 1)  //__attribute__((packed));

struct SCOFF_Relocation {
  uint32 VirtualAddress;   // Section-relative address of relocation source
  uint32 SymbolTableIndex; // Zero-based index into symbol table
  uint16 Type;             // Relocation type
};
#define SIZE_SCOFF_Relocation  10  // Size of SCOFF_Relocation packed
//#pragma pack(pop)


/********************** ТИПЫ РЕЛОКАЦИИ ДЛЯ 32-БИТНОГО COFF **********************/

#define COFF32_RELOC_ABS         0x00   // Ignored
#define COFF32_RELOC_DIR16       0x01   // Not supported
#define COFF32_RELOC_REL16       0x02   // Not supported
#define COFF32_RELOC_DIR32       0x06   // 32-bit absolute virtual address
#define COFF32_RELOC_IMGREL      0x07   // 32-bit image relative virtual address
#define COFF32_RELOC_SEG12       0x09   // not supported
#define COFF32_RELOC_SECTION     0x0A   // 16-bit section index in file
#define COFF32_RELOC_SECREL      0x0B   // 32-bit section-relative
#define COFF32_RELOC_SECREL7     0x0D   // 7-bit section-relative
#define COFF32_RELOC_TOKEN       0x0C   // CLR token
#define COFF32_RELOC_REL32       0x14   // 32-bit EIP-relative

/********************** ТИПЫ РЕЛОКАЦИИ ДЛЯ 64-БИТНОГО COFF **********************/
// Note: These values are obtained by my own testing.
// I haven't found any official values 

#define COFF64_RELOC_ABS         0x00   // Ignored
#define COFF64_RELOC_ABS64       0x01   // 64 bit absolute virtual address
#define COFF64_RELOC_ABS32       0x02   // 32 bit absolute virtual address
#define COFF64_RELOC_IMGREL      0x03   // 32 bit image-relative
#define COFF64_RELOC_REL32       0x04   // 32 bit, RIP-relative
#define COFF64_RELOC_REL32_1     0x05   // 32 bit, relative to RIP - 1. For instruction with immediate byte operand
#define COFF64_RELOC_REL32_2     0x06   // 32 bit, relative to RIP - 2. For instruction with immediate word operand
#define COFF64_RELOC_REL32_3     0x07   // 32 bit, relative to RIP - 3. (useless)
#define COFF64_RELOC_REL32_4     0x08   // 32 bit, relative to RIP - 4. For instruction with immediate dword operand
#define COFF64_RELOC_REL32_5     0x09   // 32 bit, relative to RIP - 5. (useless)
#define COFF64_RELOC_SECTION     0x0A   // 16-bit section index in file. For debug purpose
#define COFF64_RELOC_SECREL      0x0B   // 32-bit section-relative
#define COFF64_RELOC_SECREL7     0x0C   //  7-bit section-relative
#define COFF64_RELOC_TOKEN       0x0D   // CLR token = 64 bit absolute virtual address. Inline addend ignored
#define COFF64_RELOC_SREL32      0x0E   // 32 bit signed span dependent
#define COFF64_RELOC_PAIR        0x0F   // pair after span dependent
#define COFF64_RELOC_PPC_REFHI   0x10   // high 16 bits of 32 bit abs addr
#define COFF64_RELOC_PPC_REFLO   0x11   // low  16 bits of 32 bit abs addr
#define COFF64_RELOC_PPC_PAIR    0x12   // pair after REFHI
#define COFF64_RELOC_PPC_SECRELO 0x13   // low 16 bits of section relative
#define COFF64_RELOC_PPC_GPREL   0x15   // 16 bit signed relative to GP
#define COFF64_RELOC_PPC_TOKEN   0x16   // CLR token

/********************** СТРОКИ **********************/
#define COFF_CONSTRUCTOR_NAME    ".CRT$XCU"   // Name of constructors segment


// Function prototypes

// Function to put a name into SCOFF_SymTableEntry. Put name in string table
// if longer than 8 characters
uint32 COFF_PutNameInSymbolTable(SCOFF_SymTableEntry & sym, const char * name, CMemoryBuffer & StringTable);

// Function to put a name into SCOFF_SectionHeader. Put name in string table
// if longer than 8 characters
void COFF_PutNameInSectionHeader(SCOFF_SectionHeader & sec, const char * name, CMemoryBuffer & StringTable);


#endif // #ifndef PECOFF_H
