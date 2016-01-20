/****************************   coff.cpp   ***********************************
* Author:        Agner Fog
* Date created:  2006-07-15
* Last modified: 2009-01-22
* Project:       objconv
* Module:        coff.cpp
* Description:
* Module for reading PE/COFF files
*
* Класс CCOFF используется для чтения, интерпретации и демпинга файлов PE/COFF.
*
* Copyright 2006-2009 GNU General Public License http://www.gnu.org/licenses
*****************************************************************************/
#include "stdafx.h"

// Наименования типов релокации

SIntTxt COFF32RelNames[] = {
   {COFF32_RELOC_ABS,     "Absolute"},         // Игнорируемый
   {COFF32_RELOC_DIR32,   "Direct32"},         // 32-битный абсолютный виртуальный адрес
   {COFF32_RELOC_IMGREL,  "Image relative"},   // 32-битный виртуальный адрес относительно имиджа
   {COFF32_RELOC_SECTION, "Section16"},        // 16-битный индекс секции в файле
   {COFF32_RELOC_SECREL,  "Section relative"}, // 32-битный, относительно секции
   {COFF32_RELOC_SECREL7, "7 bit section relative"}, // 7-битный, относительно секции
   {COFF32_RELOC_TOKEN,   "CLR token"},        // лексема CLR
   {COFF32_RELOC_REL32,   "EIP relative"}      // 32-битный, относительно конца поля адреса
};

SIntTxt COFF64RelNames[] = {
   {COFF64_RELOC_ABS,     "Ignore"},           // Игнорируется
   {COFF64_RELOC_ABS64,   "64 bit absolute"},  // 64-битный абсолютный виртуальный адрес
   {COFF64_RELOC_ABS32,   "32 bit absolute"},  // 32-битный абсолютный виртуальный адрес
   {COFF64_RELOC_IMGREL,  "Image relative"},   // 32-битный, относительно имиджа
   {COFF64_RELOC_REL32,   "RIP relative"},     // 32-битный, относительно RIP
   {COFF64_RELOC_REL32_1, "RIP relative-1"},   // 3битный, относительно RIP - 1. Для инструкции с непосредственным байтовым операндом
   {COFF64_RELOC_REL32_2, "RIP relative-2"},   // 3битный, относительно RIP - 2. Для инструкции с непосредственным операндом word
   {COFF64_RELOC_REL32_3, "RIP relative-3"},   // 3битный, относительно RIP - 3. Неиспользуемое 
   {COFF64_RELOC_REL32_4, "RIP relative-4"},   // 3битный, относительно RIP - 4. Для инструкции с непосредственным операндом dword
   {COFF64_RELOC_REL32_5, "RIP relative-5"},   // 3битный, относительно RIP - 5. Неиспользуемое
   {COFF32_RELOC_SECTION, "Section index"},    // 16-битный индекс секции в файле
   {COFF64_RELOC_SECREL,  "Section relative"}, // 32-битный, относительно секции
   {COFF64_RELOC_SECREL7, "7 bit section rel"},//  7-битный, относительно секции
   {COFF64_RELOC_TOKEN,   "CLR token"},        // 64-битный абсолютный виртуальный адрес без inline addend
   {COFF64_RELOC_SREL32,  "32b span dependent"},        // 
   {COFF64_RELOC_PAIR,    "pair after span dependent"}, // 
   {COFF64_RELOC_PPC_REFHI,"high 16 of 32 bit abs"},    // 
   {COFF64_RELOC_PPC_REFLO,"low 16 of 32 bit abs"},     // 
   {COFF64_RELOC_PPC_PAIR, "pair after high 16"},       // 
   {COFF64_RELOC_PPC_SECRELO,"low 16 of 32 bit section relative"},
   {COFF64_RELOC_PPC_GPREL,  "16 bit GP relative"},     // 
   {COFF64_RELOC_PPC_TOKEN,  "CLR token"}               // 
};
// Машинные имена

SIntTxt COFFMachineNames[] = {
   {0,     "Any/unknown"},     // Любая машина/неизвестная
   {0x184, "Alpha"},           // Alpha AXP
   {0x1C0, "Arm"},             // Arm
   {0x284, "Alpha 64 bit"},    // Alpha AXP 64 bit
   {0x14C, "I386"},            // x86, 32 bit
   {0x200, "IA64"},            // Intel Itanium
   {0x268, "Motorola68000"},   // Motorola 68000 series
   {0x266, "MIPS16"},  
   {0x366, "MIPSwFPU"},
   {0x466, "MIPS16wFPU"},
   {0x1F0, "PowerPC"},
   {0x1F1, "PowerPC"},
   {0x162, "R3000"},
   {0x166, "R4000MIPS"},
   {0x168, "R10000"},
   {0x1A2, "SH3"},
   {0x1A6, "SH4"},
   {0x1C2, "Thumb"},
   {0x8664, "x86-64"}      // x86-64 / AMD64 / Intel EM64T
};

// Наименование классов сохранения
SIntTxt COFFStorageClassNames[] = {
   {COFF_CLASS_END_OF_FUNCTION, "EndOfFunc"},
   {COFF_CLASS_AUTOMATIC, "AutoVariable"},
   {COFF_CLASS_EXTERNAL, "External/Public"},
   {COFF_CLASS_STATIC, "Static/Nonpublic"},
   {COFF_CLASS_REGISTER, "Register"},
   {COFF_CLASS_EXTERNAL_DEF, "ExternalDef"},
   {COFF_CLASS_LABEL, "Label"},
   {COFF_CLASS_UNDEFINED_LABEL, "UndefLabel"},
   {COFF_CLASS_MEMBER_OF_STRUCTURE, "StructMem"},
   {COFF_CLASS_ARGUMENT, "FuncArgument"},
   {COFF_CLASS_STRUCTURE_TAG, "StructTag"},
   {COFF_CLASS_MEMBER_OF_UNION, "UnionMember"},
   {COFF_CLASS_UNION_TAG, "UnionTag"},
   {COFF_CLASS_TYPE_DEFINITION, "TypeDef"},
   {COFF_CLASS_UNDEFINED_STATIC, "UndefStatic"},
   {COFF_CLASS_ENUM_TAG, "EnumTag"},
   {COFF_CLASS_MEMBER_OF_ENUM, "EnumMem"},
   {COFF_CLASS_REGISTER_PARAM, "RegisterParameter"},
   {COFF_CLASS_BIT_FIELD, "BitField"},
   {COFF_CLASS_AUTO_ARGUMENT, "AutoArgument"},
   {COFF_CLASS_LASTENTRY, "DummyLastEntry"},
   {COFF_CLASS_BLOCK, "bb/eb_block"},
   {COFF_CLASS_FUNCTION, "Function_bf/ef"},
   {COFF_CLASS_END_OF_STRUCT, "EndOfStruct"},
   {COFF_CLASS_FILE, "FileName"},
   {COFF_CLASS_LINE, "LineNumber"},
   {COFF_CLASS_SECTION, "SectionLineNumber"},
   {COFF_CLASS_ALIAS, "Alias"},
   {COFF_CLASS_WEAK_EXTERNAL, "WeakExternal"},
   {COFF_CLASS_HIDDEN, "Hidden"}
};

// Наименования характеристик секции
SIntTxt COFFSectionFlagNames[] = {
   {PE_SCN_CNT_CODE,        "Text"},
   {PE_SCN_CNT_INIT_DATA,   "Data"},
   {PE_SCN_CNT_UNINIT_DATA, "BSS"},
   {PE_SCN_LNK_INFO,        "Comments"},
   {PE_SCN_LNK_REMOVE,      "Remove"},
   {PE_SCN_LNK_COMDAT,      "Comdat"},
/* {PE_SCN_ALIGN_1,         "Align by 1"},
   {PE_SCN_ALIGN_2,         "Align by 2"},
   {PE_SCN_ALIGN_4,         "Align by 4"},
   {PE_SCN_ALIGN_8,         "Align by 8"},
   {PE_SCN_ALIGN_16,        "Align by 16"},
   {PE_SCN_ALIGN_32,        "Align by 32"},
   {PE_SCN_ALIGN_64,        "Align by 64"},
   {PE_SCN_ALIGN_128,       "Align by 128"},
   {PE_SCN_ALIGN_256,       "Align by 256"},
   {PE_SCN_ALIGN_512,       "Align by 512"},
   {PE_SCN_ALIGN_1024,      "Align by 1024"},
   {PE_SCN_ALIGN_2048,      "Align by 2048"},
   {PE_SCN_ALIGN_4096,      "Align by 4096"},
   {PE_SCN_ALIGN_8192,      "Align by 8192"}, */
   {PE_SCN_LNK_NRELOC_OVFL, "extended relocations"},
   {PE_SCN_MEM_DISCARDABLE, "Discardable"},
   {PE_SCN_MEM_NOT_CACHED,  "Cannot be cached"},
   {PE_SCN_MEM_NOT_PAGED,   "Not pageable"},
   {PE_SCN_MEM_SHARED,      "Can be shared"},
   {PE_SCN_MEM_EXECUTE,     "Executable"},
   {PE_SCN_MEM_READ,        "Readable"},
   {PE_SCN_MEM_WRITE,       "Writeable"}
};

// Названия папок с данными об имидже, из опционного заголовка
SIntTxt COFFImageDirNames[] = {
   {0,   "Export_table"},
   {1,   "Import_table"},
   {2,   "Resource_table"},
   {3,   "Exception_table"},
   {4,   "Certificate_table"},
   {5,   "Base_relocation_table"},
   {6,   "Debug_table"},
   {7,   "Architecture_table"},
   {8,   "Global_pointer"},
   {9,   "Thread_local_storage_table"},
   {10,  "Load_configuration_table"},
   {11,  "Bound_import_table"},
   {12,  "Import_address_table"},
   {13,  "Delay_import_descriptor"},
   {14,  "Common_language_runtime_header"},
   {15,  "Reserved_table"}
};

// Члены класса CCOFF:
// Конструктор
CCOFF::CCOFF() {
   // Установить всё на ноль
   memset(this, 0, sizeof(*this));
}

void CCOFF::ParseFile(){
   // Загрузить и парсировать файловый буфер
   // Получить смещение к заголовку файла
   uint32 FileHeaderOffset = 0;
   if ((Get<uint16>(0) & 0xFFF9) == 0x5A49) {
      // У файла есть DOS stub
      uint32 Signature = Get<uint32>(0x3C);
      if (Signature + 8 < DataSize && Get<uint16>(Signature) == 0x4550) {
         // Исполнимый файл PE
         FileHeaderOffset = Signature + 4;
      }
      else {
         err.submit(9000);
         return;
      }
   }
   // Найти заголовок файла
   FileHeader = &Get<SCOFF_FileHeader>(FileHeaderOffset);
   NSections = FileHeader->NumberOfSections;

   // Найти опционный заголовок, если файл исполнимый
   if (FileHeader->SizeOfOptionalHeader && FileHeaderOffset) {
      OptionalHeader = &Get<SCOFF_OptionalHeader>(FileHeaderOffset + sizeof(SCOFF_FileHeader));
      // Найти папки данных имиджа
      if (OptionalHeader) {
         if (OptionalHeader->h64.Magic == COFF_Magic_PE64) {
            // 64-битная версия
            pImageDirs = &(OptionalHeader->h64.ExportTable);
            NumImageDirs = OptionalHeader->h64.NumberOfRvaAndSizes;
            EntryPoint = OptionalHeader->h64.AddressOfEntryPoint;
            ImageBase = OptionalHeader->h64.ImageBase;
         }
         else {
            // 32-битная версия
            pImageDirs = &(OptionalHeader->h32.ExportTable);
            NumImageDirs = OptionalHeader->h32.NumberOfRvaAndSizes;
            EntryPoint = OptionalHeader->h32.AddressOfEntryPoint;
            ImageBase = OptionalHeader->h32.ImageBase;
         }
      }
   }

   // Выделить в памяти буфер под заголовки секций
   SectionHeaders.SetNum(NSections);
   SectionHeaders.SetZero();

   // Найти заголовки секций
   uint32 SectionOffset = FileHeaderOffset + sizeof(SCOFF_FileHeader) + FileHeader->SizeOfOptionalHeader;
   for (int i = 0; i < NSections; i++) {
      SectionHeaders[i] = Get<SCOFF_SectionHeader>(SectionOffset);
      SectionOffset += sizeof(SCOFF_SectionHeader);
      // Проверить наличии секции _ILDATA
      if (strcmp(SectionHeaders[i].Name, "_ILDATA") == 0) {
         // Это intermediate file для компилятора Intel
         err.submit(2114);
      }
   }
   if (SectionOffset > GetDataSize()) {
      err.submit(2110);  return;             // Таблица секций указывает на внешний файл
   }
   // Найти таблицу символов
   SymbolTable = &Get<SCOFF_SymTableEntry>(FileHeader->PSymbolTable);
   NumberOfSymbols = FileHeader->NumberOfSymbols;

   // Найти таблицу строк
   StringTable = (Buf() + FileHeader->PSymbolTable + NumberOfSymbols * SIZE_SCOFF_SymTableEntry);
   StringTableSize = *(int*)StringTable; // Первые 4 байта таблицы строк содержат ее размер
}

// Отладочный демпинг
void CCOFF::Dump(int options) {
   uint32 i, j;

   if (options & DUMP_FILEHDR) {
      // Заголовок файла
      printf("\nDump of PE/COFF file %s", FileName);
      printf("\n-----------------------------------------------");
      printf("\nFile size: %i", GetDataSize());
      printf("\nFile header:");
      printf("\nMachine: %s", Lookup(COFFMachineNames,FileHeader->Machine));
      printf("\nTimeDate: 0x%08X", FileHeader->TimeDateStamp);
      printf(" - %s", timestring(FileHeader->TimeDateStamp));
      printf("\nNumber of sections: %2i", FileHeader->NumberOfSections);
      printf("\nNumber of symbols:  %2i", FileHeader->NumberOfSymbols);
      printf("\nOptional header size: %i", FileHeader->SizeOfOptionalHeader);
      printf("\nFlags: 0x%04X", FileHeader->Flags);

      // Можно удалить:
      printf("\nSymbol table offset: %i", FileHeader->PSymbolTable);
      printf("\nString table offset: %i", FileHeader->PSymbolTable + FileHeader->NumberOfSymbols * SIZE_SCOFF_SymTableEntry);
      printf("\nSection headers offset: %i", (uint32)sizeof(SCOFF_FileHeader) + FileHeader->SizeOfOptionalHeader);

      // Опционный заголовок
      if (OptionalHeader) {
         printf("\n\nOptional header:");
         if (OptionalHeader->h32.Magic != COFF_Magic_PE64) {
            // 32 bit optional header
            printf("\nMagic number: 0x%X", OptionalHeader->h32.Magic);
            printf("\nSize of code: 0x%X", OptionalHeader->h32.SizeOfCode);
            printf("\nSize of uninitialized data: 0x%X", OptionalHeader->h32.SizeOfInitializedData);
            printf("\nAddress of entry point: 0x%X", OptionalHeader->h32.AddressOfEntryPoint);
            printf("\nBase of code: 0x%X", OptionalHeader->h32.BaseOfCode);
            printf("\nBase of data: 0x%X", OptionalHeader->h32.BaseOfData);
            printf("\nImage base: 0x%X", OptionalHeader->h32.ImageBase);
            printf("\nSection alignment: 0x%X", OptionalHeader->h32.SectionAlignment);
            printf("\nFile alignment: 0x%X", OptionalHeader->h32.FileAlignment);
            printf("\nSize of image: 0x%X", OptionalHeader->h32.SizeOfImage);
            printf("\nSize of headers: 0x%X", OptionalHeader->h32.SizeOfHeaders);
            printf("\nDll characteristics: 0x%X", OptionalHeader->h32.DllCharacteristics);
            printf("\nSize of stack reserve: 0x%X", OptionalHeader->h32.SizeOfStackReserve);
            printf("\nSize of stack commit: 0x%X", OptionalHeader->h32.SizeOfStackCommit);
            printf("\nSize of heap reserve: 0x%X", OptionalHeader->h32.SizeOfHeapReserve);
            printf("\nSize of heap commit: 0x%X", OptionalHeader->h32.SizeOfHeapCommit);
         }
         else {
            // 64-битный опционный заголовок
            printf("\nMagic number: 0x%X", OptionalHeader->h64.Magic);
            printf("\nSize of code: 0x%X", OptionalHeader->h64.SizeOfCode);
            printf("\nSize of uninitialized data: 0x%X", OptionalHeader->h64.SizeOfInitializedData);
            printf("\nAddress of entry point: 0x%X", OptionalHeader->h64.AddressOfEntryPoint);
            printf("\nBase of code: 0x%X", OptionalHeader->h64.BaseOfCode);
            printf("\nImage base: 0x%08X%08X", HighDWord(OptionalHeader->h64.ImageBase), uint32(OptionalHeader->h64.ImageBase));
            printf("\nSection alignment: 0x%X", OptionalHeader->h64.SectionAlignment);
            printf("\nFile alignment: 0x%X", OptionalHeader->h64.FileAlignment);
            printf("\nSize of image: 0x%X", OptionalHeader->h64.SizeOfImage);
            printf("\nSize of headers: 0x%X", OptionalHeader->h64.SizeOfHeaders);
            printf("\nDll characteristics: 0x%X", OptionalHeader->h64.DllCharacteristics);
            printf("\nSize of stack reserve: 0x%08X%08X", HighDWord(OptionalHeader->h64.SizeOfStackReserve), uint32(OptionalHeader->h64.SizeOfStackReserve));
            printf("\nSize of stack commit: 0x%08X%08X", HighDWord(OptionalHeader->h64.SizeOfStackCommit), uint32(OptionalHeader->h64.SizeOfStackCommit));
            printf("\nSize of heap reserve: 0x%08X%08X", HighDWord(OptionalHeader->h64.SizeOfHeapReserve), uint32(OptionalHeader->h64.SizeOfHeapReserve));
            printf("\nSize of heap commit: 0x%08X%08X", HighDWord(OptionalHeader->h64.SizeOfHeapCommit), uint32(OptionalHeader->h64.SizeOfHeapCommit));
         }
         // Папки с данными
         SCOFF_ImageDirAddress dir;

         for (i = 0; i < NumImageDirs; i++) {
            if (GetImageDir(i, &dir)) {
               printf("\nDirectory %2i, %s:\n  Address 0x%04X, Size 0x%04X, Section %i, Offset 0x%04X", 
                  i, dir.Name,
                  dir.VirtualAddress, dir.Size, dir.Section, dir.SectionOffset);
            }
         }
      }
   }

   if ((options & DUMP_STRINGTB) && FileHeader->PSymbolTable && StringTableSize > 4) {
      // Таблица строк
      char * p = StringTable + 4;
      uint32 nread = 4, len;
      printf("\n\nString table:");
      while (nread < StringTableSize) {
         len = (int)strlen(p);
         if (len > 0) {
            printf("\n>>%s<<", p);
            nread += len + 1;
            p += len + 1;
         }
      }
   }
   // Таблицы символов
   if (options & DUMP_SYMTAB) {
      // Таблица символов (файл объекта)
      if (NumberOfSymbols) PrintSymbolTable(-1);

      // Таблицы импорта и экспорта (исполнимый файл)
      if (OptionalHeader) PrintImportExport();
   }

   // Заголовки секций
   if (options & (DUMP_SECTHDR | DUMP_SYMTAB | DUMP_RELTAB)) {
      for (j = 0; j < (uint32)NSections; j++) {
         SCOFF_SectionHeader * SectionHeader = &SectionHeaders[j];
         printf("\n\n%2i Section %s", j+1, GetSectionName(SectionHeader->Name));

         //printf("\nFile offset of header: 0x%X", (int)((int8*)SectionHeader-buffer));
         printf("\nVirtual size: 0x%X", SectionHeader->VirtualSize);
         if (SectionHeader->VirtualAddress) {
            printf("\nVirtual address: 0x%X", SectionHeader->VirtualAddress);}
         if (SectionHeader->PRawData || SectionHeader->SizeOfRawData) {
            printf("\nSize of raw data: 0x%X", SectionHeader->SizeOfRawData);
            printf("\nRaw data pointer: 0x%X", SectionHeader->PRawData);
         }
         printf("\nCharacteristics: ");
         PrintSegmentCharacteristics(SectionHeader->Flags);

         // напечатать релокации
         if ((options & DUMP_RELTAB) && SectionHeader->NRelocations > 0) {
            printf("\nRelocation entries: %i", SectionHeader->NRelocations);
            printf("\nRelocation entries pointer: 0x%X", SectionHeader->PRelocations);

            // Указатель на запись о релокации
            union {
               SCOFF_Relocation * p;  // указатель на запись
               int8 * b;              // используется для вычисления адреса и имкрементации
            } Reloc;
            Reloc.b = Buf() + SectionHeader->PRelocations;

            printf("\nRelocations:");
            for (i = 0; i < SectionHeader->NRelocations; i++) {
               printf("\nAddr: 0x%X, symi: %i, type: %s",
                  Reloc.p->VirtualAddress,
                  Reloc.p->SymbolTableIndex,
                  (WordSize == 32) ? Lookup(COFF32RelNames,Reloc.p->Type) : Lookup(COFF64RelNames,Reloc.p->Type));
               if (Reloc.p->Type < COFF32_RELOC_SEG12) 
               {
                  // Проверить, в файле ли адрес
                  if (SectionHeader->PRawData + Reloc.p->VirtualAddress < GetDataSize()) {
                     int32 addend = *(int32*)(Buf() + SectionHeader->PRawData + Reloc.p->VirtualAddress);
                     if (addend) printf(", Implicit addend: %i", addend);
                  }
                  else {
                     printf(". Error: Address is outside file");
                  }
               }
               
               PrintSymbolTable(Reloc.p->SymbolTableIndex);
               Reloc.b += SIZE_SCOFF_Relocation; // Следующая запись о релокации
            }
         }
         // напечатеть номера строк
         if (SectionHeader->NLineNumbers > 0) {
            printf("\nLine number entries: %i", SectionHeader->NLineNumbers);
            printf("  Line number pointer: %i\nLines:", SectionHeader->PLineNumbers);
            
            // Указатель на запись с номером строки
            union {
               SCOFF_LineNumbers * p;  // указатель на запись
               int8 * b;              // используется для вычисления адреса и имкрементации
            } Linnum;
            Linnum.b = Buf() + SectionHeader->PLineNumbers;
            for (i = 0; i < SectionHeader->NLineNumbers; i++) {
               if (Linnum.p->Line) {  // Запись содержит номер строки
                  printf(" %i:%i", Linnum.p->Line, Linnum.p->Addr);
               }
               else { // Запись содержит название функции
               }
               Linnum.b += SIZE_SCOFF_LineNumbers;  // Следующая запись с номером строки
            }         
         }
      }
   }
}


char const * CCOFF::GetSymbolName(int8* Symbol) {
   // Получить название символа из 8-байтной записи
   static char text[16];
   if (*(uint32*)Symbol != 0) {
      // Название символа не превышает 8 байт
      memcpy(text, Symbol, 8);   // Скопировать в локальный буфер
      text[8] = 0;                    // Добавить в конце ноль
      return text;                    // Вернуть текст
   }
   else {
      // Длинее 8-и байт. Получить офсет в таблицу строк
      uint32 offset = *(uint32*)(Symbol + 4);
      char * s = StringTable + offset;
      if (*s) return s;               // Вернуть запись в таблице строк
   }
   return "NULL";                     // Запись в таблице строк оказалась пустой
}


char const * CCOFF::GetSectionName(int8* Symbol) {
   // Получить название секции из 8-байтной записи
   static char text[16];
   memcpy(text, Symbol, 8);        // Скопировать в локальный буфер
   text[8] = 0;                    // Добавить в конце ноль
   if (text[0] == '/') {
      // В таблице строк длинное название. 
      // Преобразовать десятичное число ASCII в индекс таблицы строк
      uint32 sindex = atoi(text + 1);
      // Получить название из таблицы строк
      if (sindex < StringTableSize) {
         char * s = StringTable + sindex;
         if (*s) return s;}                 // Вернуть запись в таблице строк
   }
   else {
      // В текстовом буфере короткое название
      return text;
   }
   return "NULL";                           // На случай ошибки
}

char const * CCOFF::GetStorageClassName(uint8 sc) {
   // Получить название класса сохранения
   return Lookup(COFFStorageClassNames, sc);
}

void CCOFF::PrintSegmentCharacteristics(uint32 flags) {
   // Напечатать характеристики сегмента
   int n = 0;
   // Просмотреть все биты целого числа
   for (uint32 i = 1; i != 0; i <<= 1) {
      if (i & flags & ~PE_SCN_ALIGN_MASK) {
         if (n++) printf(", ");
         printf("%s", Lookup(COFFSectionFlagNames, i));
      }
   }
   if (flags & PE_SCN_ALIGN_MASK) {
      int a = 1 << (((flags & PE_SCN_ALIGN_MASK) / PE_SCN_ALIGN_1) - 1);
      printf(", Align by 0x%X", a); n++;
   }
   if (n == 0) printf("None");
}

const char * CCOFF::GetFileName(SCOFF_SymTableEntry * syme) {
   // Получить название файла из записей в таблице символов
   if (syme->s.NumAuxSymbols < 1 || syme->s.StorageClass != COFF_CLASS_FILE) {
      return ""; // Названия файла не найдено
   }
   // Установить ограничение на длину названия файла = 576
   const uint32 MAXCOFFFILENAMELENGTH = 32 * SIZE_SCOFF_SymTableEntry;
   // Буфер для созранения названия файла. Должен быть статическим
   static char text[MAXCOFFFILENAMELENGTH+1];
   // длина названия в записи
   uint32 len = syme->s.NumAuxSymbols * SIZE_SCOFF_SymTableEntry;
   if (len > MAXCOFFFILENAMELENGTH) len = MAXCOFFFILENAMELENGTH;
   // скопировать название из вспомогательных записей
   memcpy(text, (int8*)syme + SIZE_SCOFF_SymTableEntry, len);
   // Завершить строку
   text[len] = 0;
   // Вернуть название
   return text;
}

const char * CCOFF::GetShortFileName(SCOFF_SymTableEntry * syme) {
   // То же, что и выше. Убирает перед название файла маршрут к нему
   // Полное название файла
   const char * fullname = GetFileName(syme);
   // Длина
   uint32 len = (uint32)strlen(fullname);
   if (len < 1) return fullname;
   // Сканировать обратно, ища '/', '\', ':'
   for (int scan = len-2; scan >= 0; scan--) {
      char c = fullname[scan];
      if (c == '/' || c == '\\' || c == ':') {
         // Путь установлен. После этого символа начинается краткое название
         return fullname + scan + 1;
      }
   }
   // Путь не установлен. Вернуть полное название
   return fullname;
}

void CCOFF::PrintSymbolTable(int symnum) {
   // Напечатать один или все публичные символы для файла объекта.
   // Демпировать таблицу символов, если symnum = -1, или
   // Демпировать символ номер symnum (с нулевым основанием), когда symnum >= 0
   int isym = 0;  // текущая запись в таблице символов
   int jsym = 0;  // номер вспомогательной записи
   union {        // Указатель на таблицу символов
      SCOFF_SymTableEntry * p;  // Нормальный указатель
      int8 * b;                 // Используется для вычисления адреса
   } Symtab;

   Symtab.p = SymbolTable;      // Установить указатель на начало SymbolTable
   if (symnum == -1) printf("\n\nSymbol table:");
   if (symnum >= 0) {
      // Напечатать только один символ
      if (symnum >= NumberOfSymbols) {
         printf("\nSymbol %i not found", symnum);
         return;
      }
      isym = symnum;
      Symtab.b += SIZE_SCOFF_SymTableEntry * isym;
   }
   while (isym < NumberOfSymbols) {
      // Напечатать запись в таблице символов
      SCOFF_SymTableEntry *s0;
      printf("\n");
      if (symnum >= 0) printf("  ");
      printf("Symbol %i - Name: %s\n  Value=%i, ", 
         isym, GetSymbolName(Symtab.p->s.Name), Symtab.p->s.Value);
      if (Symtab.p->s.SectionNumber > 0) {
         printf("Section=%i", Symtab.p->s.SectionNumber);
      }
      else { // Номера особых секций
         switch (Symtab.p->s.SectionNumber) {
         case COFF_SECTION_UNDEF:
            printf("External"); break;
         case COFF_SECTION_ABSOLUTE:
            printf("Absolute"); break;
         case COFF_SECTION_DEBUG:
            printf("Debug"); break;
         case COFF_SECTION_N_TV:
            printf("Preload transfer"); break;
         case COFF_SECTION_P_TV:
            printf("Postload transfer"); break;
         }
      }
      printf(", Type=0x%X, StorClass=%s, NumAux=%i",
         Symtab.p->s.Type,
         GetStorageClassName(Symtab.p->s.StorageClass), Symtab.p->s.NumAuxSymbols);
      if (Symtab.p->s.StorageClass == COFF_CLASS_FILE && Symtab.p->s.NumAuxSymbols > 0) {
         printf("\n  File name: %s", GetFileName(Symtab.p));
      }
      // Инкрементировать точку
      s0 = Symtab.p;
      Symtab.b += SIZE_SCOFF_SymTableEntry;
      isym++;  jsym = 0;
      // Получить вспомогательные записи
      while (jsym < s0->s.NumAuxSymbols && isym + jsym < NumberOfSymbols) {
         // Напечатать запись вспомогательной таблицы символов
         SCOFF_SymTableEntry * sa = Symtab.p;
         // Определить тип вспомогательной записи
         if (s0->s.StorageClass == COFF_CLASS_EXTERNAL
            && s0->s.Type == COFF_TYPE_FUNCTION
            && s0->s.SectionNumber > 0) {
            // Это запись дефиниции функции aux
            printf("\n  Aux function definition:");
            printf("\n  .bf_tag_index: 0x%X, code_size: %i, PLineNumRec: %i, PNext: %i",
               sa->func.TagIndex, sa->func.TotalSize, sa->func.PointerToLineNumber,
               sa->func.PointerToNextFunction);
         }
         else if (strcmp(s0->s.Name,".bf")==0 || strcmp(s0->s.Name,".ef")==0) {
            // Это запись .bf или .ef aux
            printf("\n  Aux .bf/.ef definition:");
            printf("\n  Source line number: %i",
               sa->bfef.SourceLineNumber);
            if (strcmp(s0->s.Name,".bf")==0 ) {
               printf(", PNext: %i", sa->bfef.PointerToNextFunction);
            }
         }
         else if (s0->s.StorageClass == COFF_CLASS_EXTERNAL && 
            s0->s.SectionNumber == COFF_SECTION_UNDEF &&
            s0->s.Value == 0) {
            // This is a Weak external aux record
            printf("\n  Aux Weak external definition:");
            printf("\n  Symbol2 index: %i, Characteristics: 0x%X",
               sa->weak.TagIndex, sa->weak.Characteristics);
            }
         else if (s0->s.StorageClass == COFF_CLASS_FILE) {
            // Это вспомогательная запись filename. Содержимое уже распечатано
         }
         else if (s0->s.StorageClass == COFF_CLASS_STATIC) {
            // Это вспомогательная запись определения секции
            printf("\n  Aux section definition record:");
            printf("\n  Length: %i, Num. relocations: %i, Num linenums: %i, checksum 0x%X,"
               "\n  Number: %i, Selection: %i",
               sa->section.Length, sa->section.NumberOfRelocations, sa->section.NumberOfLineNumbers, 
               sa->section.CheckSum, sa->section.Number, sa->section.Selection);
         }
         else {
            // Неизвестный тип вспомогательной записи
            printf("\n  Unknown Auxiliary record type.");
         }
         Symtab.b += SIZE_SCOFF_SymTableEntry;
         jsym++;
      }
      isym += jsym;
      if (symnum >= 0) break;
   }
}

void CCOFF::PublicNames(CMemoryBuffer * Strings, CSList<SStringEntry> * Index, int m) {
   // Составить список публичных имен из файла объекта
   // В строки будут передаваться строки ASCIIZ
   // В индекс будут переданы записи типа SStringEntry с Member = m

   // Интерпретировать заголовок:
   ParseFile();

   int isym = 0;  // текущая запись в таблице символов
   union {        // Указатель на таблицу символов
      SCOFF_SymTableEntry * p;  // Нормальный указатель
      int8 * b;                 // Ипользууется для вычисления адреса
   } Symtab;

   // Цикл по таблице символов
   Symtab.p = SymbolTable;
   while (isym < NumberOfSymbols) {
      // Проверить в буфере
      if (Symtab.b >= Buf() + DataSize) {
         err.submit(2040);
         break;
      }

      // Искать публичный символ
      if (Symtab.p->s.SectionNumber > 0 && Symtab.p->s.StorageClass == COFF_CLASS_EXTERNAL) {
         // Публичный символ найден
         SStringEntry se;
         se.Member = m;

         // Сохранить название
         se.String = Strings->PushString(GetSymbolName(Symtab.p->s.Name));
         // Сохранить индекс названия
         Index->Push(se);
      }
      if ((int8)Symtab.p->s.NumAuxSymbols < 0) Symtab.p->s.NumAuxSymbols = 0;

      // Инкрементировать точку
      isym += Symtab.p->s.NumAuxSymbols + 1;
      Symtab.b += (1 + Symtab.p->s.NumAuxSymbols) * SIZE_SCOFF_SymTableEntry;
   }
}

int CCOFF::GetImageDir(uint32 n, SCOFF_ImageDirAddress * dir) {
   // Найти адрес папки образа для исполнимых файлов
   int32  Section;
   uint32 FileOffset;

   if (pImageDirs == 0 || n >= NumImageDirs || dir == 0) {
      // Неудача
      return 0;
   }
   // Получить виртуальный адрес и размер папки
   dir->VirtualAddress = pImageDirs[n].VirtualAddress;
   dir->Size           = pImageDirs[n].Size;
   dir->Name           = Lookup(COFFImageDirNames, n);

   // Проверить, что не нуль
   if (dir->VirtualAddress == 0 || dir->Size == 0) {
      // Пусто
      return 0;
   }

   // Искать секцию, содержащую данный адрес
   for (Section = 0; Section < NSections; Section++) {
      if (dir->VirtualAddress >= SectionHeaders[Section].VirtualAddress
      && dir->VirtualAddress < SectionHeaders[Section].VirtualAddress + SectionHeaders[Section].SizeOfRawData) {
         // Секция найдена
         dir->Section = Section + 1;
         // Смещение относительно секции
         dir->SectionOffset = dir->VirtualAddress - SectionHeaders[Section].VirtualAddress;
         // Вычислить смещение в файле
         FileOffset = SectionHeaders[Section].PRawData + dir->SectionOffset;
         if (FileOffset == 0 || FileOffset >= DataSize) {
            // указывает за пределы файла
            err.submit(2035);
            return 0;
         }
         // FileOffset в приемлемых рамках
         dir->FileOffset = FileOffset;

         // Максимально допустимое смещение
         dir->MaxOffset = SectionHeaders[Section].SizeOfRawData - dir->SectionOffset;

         // Вернуть успех
         return Section;
      }
   }
   // Секция с импортом не найдена
   return 0;
}

void CCOFF::PrintImportExport() {
   // Напечатать импортируемые и экспортируемые символы

   // Адрес таблицы каталога
   SCOFF_ImageDirAddress dir;

   uint32 i;                                     // Index into OrdinalTable and NamePointerTable
   uint32 Ordinal;                               // Index into ExportAddressTable
   uint32 Address;                               // Virtual address of exported symbol
   uint32 NameOffset;                            // Section offset of symbol name
   uint32 SectionOffset;                         // Section offset of table
   const char * Name;                            // Name of symbol

   // Check if 64 bit
   int Is64bit = OptionalHeader->h64.Magic == COFF_Magic_PE64;

   // Exported names
   if (GetImageDir(0, &dir)) {

      // Beginning of export section is export directory
      SCOFF_ExportDirectory * pExportDirectory = &Get<SCOFF_ExportDirectory>(dir.FileOffset);

      // Find ExportAddressTable
      SectionOffset = pExportDirectory->ExportAddressTableRVA - dir.VirtualAddress;
      if (SectionOffset == 0 || SectionOffset >= dir.MaxOffset) {
         // Points outside section
         err.submit(2035);  return;
      }
      uint32 * pExportAddressTable = &Get<uint32>(dir.FileOffset + SectionOffset);

      // Find ExportNameTable
      SectionOffset = pExportDirectory->NamePointerTableRVA - dir.VirtualAddress;
      if (SectionOffset == 0 || SectionOffset >= dir.MaxOffset) {
         // Points outside section
         err.submit(2035);  return;
      }
      uint32 * pExportNameTable = &Get<uint32>(dir.FileOffset + SectionOffset);

      // Find ExportOrdinalTable
      SectionOffset = pExportDirectory->OrdinalTableRVA - dir.VirtualAddress;
      if (SectionOffset == 0 || SectionOffset >= dir.MaxOffset) {
         // Points outside section
         err.submit(2035);  return;
      }
      uint16 * pExportOrdinalTable = &Get<uint16>(dir.FileOffset + SectionOffset);

      // Get further properties
      uint32 NumExports = pExportDirectory->AddressTableEntries;
      uint32 NumExportNames = pExportDirectory->NamePointerEntries;
      uint32 OrdinalBase = pExportDirectory->OrdinalBase;

      // Print exported names
      printf("\n\nExported symbols:");

      // Loop through export tables
      for (i = 0; i < NumExports; i++) {

         Address = 0;
         Name = "(None)";

         // Get ordinal from table
         Ordinal = pExportOrdinalTable[i];
         // Address table is indexed by ordinal
         if (Ordinal < NumExports) {
            Address = pExportAddressTable[Ordinal];
         }
         // Find name if there is a name list entry
         if (i < NumExportNames) {
            NameOffset = pExportNameTable[i] - dir.VirtualAddress;
            if (NameOffset && NameOffset < dir.MaxOffset) {
               Name = &Get<char>(dir.FileOffset + NameOffset);
            }
         }
         // Print ordinal, address and name
         printf("\n  Ordinal %3i, Address %6X, Name %s",
            Ordinal + OrdinalBase, Address, Name);
      }
   }
   // Imported names
   if (GetImageDir(1, &dir)) {

      // Print imported names
      printf("\n\nImported symbols:");

      // Pointer to current import directory entry
      SCOFF_ImportDirectory * ImportEntry = &Get<SCOFF_ImportDirectory>(dir.FileOffset);
      // Pointer to current import lookup table entry
      int32 * LookupEntry = 0;
      // Pointer to current hint/name table entry
      SCOFF_ImportHintName * HintNameEntry;

      // Loop through import directory until null entry
      while (ImportEntry->DLLNameRVA) {
         // Get DLL name
         NameOffset = ImportEntry->DLLNameRVA - dir.VirtualAddress;
         if (NameOffset < dir.MaxOffset) {
            Name = &Get<char>(dir.FileOffset + NameOffset);
         }
         else {
            Name = "Error";
         }
         // Print DLL name
         printf("\nFrom %s", Name);

         // Get lookup table
         SectionOffset = ImportEntry->ImportLookupTableRVA;
         if (SectionOffset == 0) SectionOffset = ImportEntry->ImportAddressTableRVA;
         if (SectionOffset == 0) continue;
         SectionOffset -= dir.VirtualAddress;
         if (SectionOffset >= dir.MaxOffset) break;  // Out of range
         LookupEntry = &Get<int32>(dir.FileOffset + SectionOffset);

         // Loop through lookup table
         while (LookupEntry[0]) {
            if (LookupEntry[Is64bit] < 0) {
               // Imported by ordinal
               printf("\n  Ordinal %i", uint16(LookupEntry[0]));
            }
            else {
               // Find entry in hint/name table
               SectionOffset = (LookupEntry[0] & 0x7FFFFFFF) - dir.VirtualAddress;;
               if (SectionOffset >= dir.MaxOffset) continue;  // Out of range
               HintNameEntry = &Get<SCOFF_ImportHintName>(dir.FileOffset + SectionOffset);

               // Print name
               printf("\n  %04X  %s", HintNameEntry->Hint, HintNameEntry->Name);

               // Check if exported
               if (HintNameEntry->Hint) {
                 // printf(",  Export entry %i", HintNameEntry->Hint);
               }
            }
            // Loop next
            LookupEntry += Is64bit ? 2 : 1;
         }

         // Loop next
         ImportEntry++;
      }   
   }
}

// Functions for manipulating COFF files

uint32 COFF_PutNameInSymbolTable(SCOFF_SymTableEntry & sym, const char * name, CMemoryBuffer & StringTable) {
   // Function to put a name into SCOFF_SymTableEntry. 
   // Put name in string table if longer than 8 characters.
   // Returns index into StringTable if StringTable used
   int len = (int)strlen(name);                  // Length of name
   if (len <= 8) {
      // Short name. store in section header
      memcpy(sym.s.Name, name, len);
      // Pad with zeroes
      for (; len < 8; len++) sym.s.Name[len] = 0;
   }
   else {
      // Long name. store in string table
      sym.stringindex.zeroes = 0;
      sym.stringindex.offset = StringTable.PushString(name);     // Second integer = entry into string table
      return sym.stringindex.offset;
   }
   return 0;
}

void COFF_PutNameInSectionHeader(SCOFF_SectionHeader & sec, const char * name, CMemoryBuffer & StringTable) {
   // Function to put a name into SCOFF_SectionHeader. 
   // Put name in string table if longer than 8 characters
   int len = (int)strlen(name);                  // Length of name
   if (len <= 8) {
      // Short name. store in section header
      memcpy(sec.Name, name, len);
      // Pad with zeroes
      for (; len < 8; len++) sec.Name[len] = 0;
   }
   else {
      // Long name. store in string table
      sprintf(sec.Name, "/%i", StringTable.PushString(name));
   }
}
