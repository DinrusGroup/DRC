/****************************  cmdline.cpp  **********************************
* Author:        Agner Fog
* Changed by	 Vit Klich
* Date created:  2006-07-25
* Last modified: 2009-08-10
* Project:       objconv
* Module:        cmdline.cpp
* Description:
* Этот модуль предназначен для интерпретации параметров командной строки
* Также содержит функции по изменению символов
*
* Copyright 2006-2009 GNU General Public License http://www.gnu.org/licenses
*****************************************************************************/

#include "stdafx.h"
#include <string>
#include <iostream>



// Список распознаваемых параметров типа выводного файла
static SIntTxt TypeOptionNames[] = {
   {CMDL_OUTPUT_ELF,   "elf"},
   {CMDL_OUTPUT_PE,    "pe"},
   {CMDL_OUTPUT_PE,    "cof"},
   {CMDL_OUTPUT_PE,    "coff"},
   {CMDL_OUTPUT_PE,    "win"},
   {CMDL_OUTPUT_OMF,   "omf"},
   {CMDL_OUTPUT_MACHO, "mac"},
   {CMDL_OUTPUT_MACHO, "mach"},
   {CMDL_OUTPUT_MACHO, "macho"},
   {CMDL_OUTPUT_MACHO, "mach-o"},
   {CMDL_OUTPUT_MASM,  "asm"},
   {CMDL_OUTPUT_MASM,  "masm"},
   {CMDL_OUTPUT_MASM,  "tasm"},
   {CMDL_OUTPUT_MASM,  "nasm"},
   {CMDL_OUTPUT_MASM,  "yasm"},
   {CMDL_OUTPUT_MASM,  "gasm"},
   {CMDL_OUTPUT_MASM,  "gas"}
};

// Список названий подтипов
static SIntTxt SubtypeNames[] = {
   {SUBTYPE_MASM,  "asm"},
   {SUBTYPE_MASM,  "masm"},
   {SUBTYPE_MASM,  "tasm"},
   {SUBTYPE_YASM,  "nasm"},
   {SUBTYPE_YASM,  "yasm"},
   {SUBTYPE_GASM,  "gasm"},
   {SUBTYPE_GASM,  "gas"}
};

// Список стандартных названий, которые всегда транслируются
const uint32 MaxType = FILETYPE_MACHO_LE;

// Стандартные названия в 32-битном режиме
const char * StandardNames32[][MaxType+1] = {
//  0,    COFF,          OMF,           ELF,                MACHO
   {0,"___ImageBase","___ImageBase","__executable_start","__mh_execute_header"}
};

// Стандартные названия в 64-битном режиме
// COFF удаляет подчеркивание в 32-битном. Не существует OMF 64-битного.
const char * StandardNames64[][MaxType+1] = {
//  0,    COFF,       OMF,         ELF,                MACHO
   {0,"__ImageBase",  "",    "__executable_start","__mh_execute_header"}
};

const int NumStandardNames = sizeof(StandardNames32) / sizeof(StandardNames32[0]);


// Интерпретатор командной строки
CCommandLineInterpreter cmd;                  // Создать экземпляр интерпретатора

CCommandLineInterpreter::CCommandLineInterpreter() {
   // Дефолтный конструктор
   memset(this, 0, sizeof(*this));            // Установить всё на ноль
   Verbose        = CMDL_VERBOSE_YES;         // Сколько диагностики выводить на экран
   DumpOptions    = DUMP_NONE;                // Опции демпирования
   DebugInfo      = CMDL_DEBUG_DEFAULT;       // Снять или преобразовать отладочную информацию
   ExeptionInfo   = CMDL_EXCEPTION_DEFAULT;   // Снять или сохранить информацию по обработке исключений
   SegmentDot     = CMDL_SECTIONDOT_NOCHANGE; // Изменить подчеркивание/точки в начале названий сегментов
   Underscore     = CMDL_UNDERSCORE_NOCHANGE; // Добавить/удалить подчеркивания в названиях символов
   LibraryOptions = CMDL_LIBRARY_DEFAULT;     // Библиотечные опции
}


CCommandLineInterpreter::~CCommandLineInterpreter() { // Деструктор
}


void CCommandLineInterpreter::ReadCommandLine(int argc, char * argv[]) {

   // Прочесть командную строку
   for (int i = 1; i < argc; i++) {
      ReadCommandItem(argv[i]);
   }
   if (ShowHelp || (InputFile == 0 && OutputFile == 0) || !OutputType) {
	  // Не найдено команды. Вывести помощь
      Help();  ShowHelp = 1;
      return;
   }
   // Проверить опции файлов
   FileOptions = CMDL_FILE_INPUT;
   if (LibraryOptions == CMDL_LIBRARY_ADDMEMBER) {
	  // Добавление файлов объектов в библиотеку. Библиотека может не существовать
      FileOptions = CMDL_FILE_IN_IF_EXISTS;
   }
   if (DumpOptions || ((LibraryOptions & CMDL_LIBRARY_EXTRACTMEM) && !(LibraryOptions & CMDL_LIBRARY_ADDMEMBER))) {
	  // Демпирование или извлечение. Выводной файл не используется
	  if (OutputFile) err.submit(1103); // Название файла вывода игнорируется
      OutputFile = 0;
   }
   else {
	  // Требуется фаай вывода
      FileOptions |= CMDL_FILE_OUTPUT;
   }
   if ((LibraryOptions & CMDL_LIBRARY_ADDMEMBER) && !(LibraryOptions & CMDL_LIBRARY_CONVERT)) {
	  // Добавление только членов библиотеки. Файл вывода может иметь то же название, что и ввода
      FileOptions |= CMDL_FILE_IN_OUT_SAME;
   }
   // Проверить файл вывода
   if (!OutputType) {
	  // Тип вывода еще не указан
      if (LibraryOptions & (CMDL_LIBRARY_CONVERT | CMDL_LIBRARY_ADDMEMBER)) {
         OutputType = FILETYPE_LIBRARY;
      }
   }
}


void CCommandLineInterpreter::ReadCommandItem(char * string) {
   // Прочесть одну опцию из командной строки
   // Пропустить пробелы в начале
   while (*string != 0 && *string <= ' ') string++;
   if (*string == 0) return;  // Пустая строка

   // Искать префикс опций и префикс файла ответа
   const char OptionPrefix1 = '-';  // Опция должна начинаться с '-'
#if defined (_WIN32) || defined (__WINDOWS__)
   const char OptionPrefix2 = '/';  // '/' допускается вместо '-' только в Windows
#else
   const char OptionPrefix2 = '-';
#endif
   const char ResponseFilePrefix = '@';  // Название файла-ответа с префиксом '@'
   if (*string == OptionPrefix1 || *string == OptionPrefix2) {
	  // Найден префикс опции. Ото опция командной строки
      InterpretCommandOption(string+1);
   }
   else if (*string == ResponseFilePrefix) {
	  // Префикс файла-ответа найден. Прочесть другие опции из него
      ReadCommandFile(string+1);
   }
   else {
	  // Не найдено префикса. Это название вводного или выводного файла
      InterpretFileName(string);
   }
}


void CCommandLineInterpreter::ReadCommandFile(char * filename) {
   // прочесть команду из файла
   if (*filename <= ' ') {
	  err.submit(1001); return;    // Предупреждение: пустое название файла
   }

   // Проверить, не много ли буферов для файла-ответа (возможно, что файл включает самого себя)
   if (++NumBuffers > MAX_COMMAND_FILES) {err.submit(2107); return;}

   // Выделить буфер под файлы ответа.
   if (ResponseFiles.GetNumEntries() == 0) {
      ResponseFiles.SetNum(MAX_COMMAND_FILES);
	  ResponseFiles.SetZero();
   }

   // Прочесть файл-ответа в новый буфер
   ResponseFiles[NumBuffers-1].FileName = filename;
   ResponseFiles[NumBuffers-1].Read();

   // Получить буфер с содержимым файла
   char * buffer = ResponseFiles[NumBuffers-1].Buf();
   char * ItemBegin, * ItemEnd;  // Пометить начало и конец лексемы в буфере

   // Проверить, выделен ли буфер
   if (buffer) {

	  // Парсировать содержимое файла-ответа на наличие лексем
      while (*buffer) {

		 // Пропустить пробелы
         while (*buffer != 0 && uint8(*buffer) <= uint8(' ')) buffer++;
		 if (*buffer == 0) break; // Найден конец буфера
         ItemBegin = buffer;

		 // Найти конец лексемы
         ItemEnd = buffer+1;
         while (uint8(*ItemEnd) > uint8(' ')) ItemEnd++;
         if (*ItemEnd == 0) {
            buffer = ItemEnd;
         }
         else {
            buffer = ItemEnd + 1;
			*ItemEnd = 0;    // Пометить конец лексемы
         }
		 // Найти лексему.
		 // Проверить, является ли это началом комментария '#' или '//'
         if (ItemBegin[0] == '#' || (ItemBegin[0] == '/' && ItemBegin[1] == '/' )) {
			// это комментарий. Пропустить строку до самого конца
            ItemEnd = buffer;
            while (*ItemEnd != 0 && *ItemEnd != '\n') {
               ItemEnd++;
            }
			if (*ItemEnd == 0) {
               buffer = ItemEnd;
            }
            else {
               buffer = ItemEnd + 1;
            }
            continue;
         }
		 // Не комментарий. Интерпретировать лексему
         ReadCommandItem(ItemBegin);
      }
   }
}


void CCommandLineInterpreter::InterpretFileName(char * string) {
   // Интерпретировать название вводного или выводимого файла для ком. строки

   switch (libmode) {
   case 1:            // Первое название файла после -lib = inputfile and outputfile
      InputFile = string;
      libmode = 2;
      return;

   case 2:            // Второе или далее название после -lib = файл объекта, добавляемого в библиотеку
      AddObjectToLibrary(string, string);
      return;
   }
   // libmode = 0: Ординарный файл ввода или вывода

   if (!InputFile) {
      // Файл ввода еще не задан
      InputFile = string;
   }
   else if (!OutputFile) {
      // Файл вывода еще не указан
      OutputFile = string;
   }
   else {
      // Оба файла - ввода и вывода - уже заданы
      err.submit(2001);
   }
}


void CCommandLineInterpreter::InterpretCommandOption(char * string) {
   // Интерпретировать одну опцию из ком. строки
   if (*string <= ' ') {
      err.submit(1001); return;    // Предупреждение: пустой параметр
   }

   // Определить тип параметра
   switch(string[0]) {
   case 'f': case 'F':   // формат файла вывода
      if (string[1] == 'd') {
         // -fd == депрекированная опция демпинга
         InterpretDumpOption(string+2);  break;
      }
      InterpretOutputTypeOption(string+1);  break;

   case 'v': case 'V':   // verbose/silent
      InterpretVerboseOption(string+1);  break;

   case 'd': case 'D':   // dump option
      InterpretDumpOption(string+1);  break;
      // Debug info option
      //InterpretDebugInfoOption(string+1);  break;

   case 'x': case 'X':   // Exception handler info option
      InterpretExceptionInfoOption(string+1);  break;

   case 'h': case 'H': case '?':  // Help
      ShowHelp = 1;  break;

   case 'e': case 'E':   // Error option
   case 'w': case 'W':   // Warning option
      InterpretErrorOption(string);  break;

   case 'n': case 'N':   // Symbol name change option
   case 'a': case 'A':   // Symbol name alias option
      InterpretSymbolNameChangeOption(string);  break;

   case 'i': case 'I':   // Imagebase
      if ((string[1] | 0x20) == 'm') {
         InterpretImagebaseOption(string);
      }
      break;

   case 'l': case 'L':   // Library option
      InterpretLibraryOption(string);  break;

   case 'c':  // Count instruction codes supported
      // This is an easter egg: You can only get it if you know it's there
      if (strncmp(string,"countinstructions", 17) == 0) {
         CDisassembler::CountInstructions();
         exit(0);
      }

   default:    // Неизвестная опция
      err.submit(1002, string);
   }
}


void CCommandLineInterpreter::InterpretLibraryOption(char * string) {
   // Интерпретировать опции для манипуляции файлами библиотки/архива

   // Проверить наличие команды -lib
   if (stricmp(string, "lib") == 0) {  // Найдена команда -lib
      if (InputFile) {
         libmode = 2;                  // Вводный файл уже назначен. Остальные названия - файлы объектов
      }
      else {
         libmode = 1;                  // Остаток командной строки можно интерпретировать как название библиотеки или файлов объектов
      }
      return;
   }

   SSymbolChange sym = {0,0,0,0};      // Symbol change record
   int i;                              // Счетчик циклов

   // Проверить наличие имени члена и необязательного нового названия в этой команде
   char * name1 = 0, * name2 = 0, separator;
   if ((string[2] == ':' || string[2] == '|') && string[3]) {
      // найдено name1
      separator = string[2];
      name1 = string+3;
      // Искать второй разделитель или конец
      name2 = name1 + 1;
      while (name2[0] != 0) {
         if (name2[0] == separator) {
            *name2 = 0;  // Пометить конец name1
            if (name2[1]) {
               // найдено name2
               name2++;     // Name2 начинается здесь
               break;
            }
         }
         name2++;
      }
      if (name2 == 0 || name2[0] == 0 || name2[0] == separator) {
         // name 2 пустое, установить на name1
         name2 = name1;
      }
      else {
         // Проверить, заканчивается ли name2 сепаратором
         for (i = 0; i < (int)strlen(name2); i++) {
            if (name2[i] == separator) name2[i] = 0;
         }
      }
   }
   // Проверить на названия-дубликаты
   if (SymbolIsInList(name1)) {
      // Этот символ уже есть в списке
      err.submit(2017, name1);
      return;
   }

   sym.Name1 = name1;     // Сохранить наименования в записи изменения символов
   sym.Name2 = name2;     

   switch (string[1]) {
   case 'a': case 'A':      // Добавить в библиотеку файл с ввода
      if (name1) {
         AddObjectToLibrary(name1, name2);
      }
      else err.submit(2004, string);
      break;

   case 'x': case 'X':      // Извлечь из библиотеки член(-ы)
      if (name1) {
         // Извлечь заданный член
         cmd.LibraryOptions = CMDL_LIBRARY_EXTRACTMEM;
         sym.Action  = SYMA_EXTRACT_MEMBER;
         SymbolList.Push(&sym, sizeof(sym));
      }
      else {
         // Извлечь все члены
         cmd.LibraryOptions = CMDL_LIBRARY_EXTRACTALL;
      }
      break;

   case 'd': case 'D':  // Удалить член из библиотеки
      if (name1) {
         // Удалить заданный член
         cmd.LibraryOptions = CMDL_LIBRARY_CONVERT;
         sym.Action  = SYMA_DELETE_MEMBER;
         SymbolList.Push(&sym, sizeof(sym));
      }
      else err.submit(2004, string);
      break;

   default:
      err.submit(2004, string);  // Неизвестная опция
   }
}


void CCommandLineInterpreter::AddObjectToLibrary(char * filename, char * membername) {
   // Добавить в библиотеку объектный файл 
   if (!filename || !*filename) {          
      err.submit(2004, filename-1);  return;     // Пустая строка
   }

   if (!membername || !*membername) membername = filename;

   SSymbolChange Sym = {0,0,0,0};                // Запись изменения символов

   Sym.Name2 = filename;                         // Название файла объекта

   if (!MemberNamesAllocated) {
      // Распределить пространство под наименования урезанных (truncated) членов
      const int SafetySpace = 1024;

      // Получить размер файлов response
      if (ResponseFiles.GetNumEntries()) {
         MemberNamesAllocated = ResponseFiles[0].GetDataSize() + ResponseFiles[1].GetDataSize();
      }
      // Выделить этот размер + SafetySpace
      MemberNames.SetSize(MemberNamesAllocated + SafetySpace);

      // Запомнить размер выделенного буфера
      MemberNamesAllocated = MemberNames.GetBufferSize();
   }

   // Урезать наименование и сохранить его в MemberNames
   uint32 Name1Offset = MemberNames.PushString(CLibrary::TruncateMemberName(membername));
   Sym.Name1 = (char*)(MemberNames.Buf() + Name1Offset);

   // Примечание: Sym.Name1 указывает на выделенную память, нарушая практику хорошего программирования.
   // Check that it is not reallocated:
   if (MemberNames.GetBufferSize() != MemberNamesAllocated) {
      err.submit(2506); // MemberNames нельзя реалоцировать из-за наличия на них указателей в SymbolList
      return;
   }

   // Проверить наименование-дубликат
   if (SymbolIsInList(Sym.Name1)) {
      // Этот символ уже в списке
      err.submit(2017, Sym.Name1);
      return;
   }

   // Сохранить опции
   cmd.LibraryOptions |= CMDL_LIBRARY_ADDMEMBER;
   Sym.Action  = SYMA_ADD_MEMBER;

   // Сохранить в списке символов запись SYMA_ADD_MEMBER
   SymbolList.Push(&Sym, sizeof(Sym));
}


void CCommandLineInterpreter::InterpretOutputTypeOption(char * string) {
   // Интерпретировать опцию формата файла вывода из командной строки

   int opt;
   for (opt = 0; opt < TableSize(TypeOptionNames); opt++) {
      int len = (int)strlen(TypeOptionNames[opt].b);
      if (strncmp(string, TypeOptionNames[opt].b, len) == 0) {
         // Найдено совпадение
         if (OutputType)  err.submit(2003, string);  // Указан не единственный тип вывода
         if (DumpOptions) err.submit(2007);          // Указано и демпировать, и преобразовать
         // Сохранить желаемый тип вывода
         OutputType = TypeOptionNames[opt].a;

         // Проверить, допустимо ли название по размеру слова
         int wordsize = 0;
         if (string[len]) wordsize = atoi(string+len);
         switch (wordsize) {
         case 0:  // Не задано никакого размера слова
            break;

         case 32: case 64:  // Приемлемый размер слова
            DesiredWordSize = wordsize;
            break;

         default:  // Неприемлемый размер слова
            err.submit(2002, wordsize);
         }
         break;   // Поиск окончен
      }
   }

   // Проверить найденное
   if (opt >= TableSize(TypeOptionNames)) err.submit(2004, string-1);

   if (OutputType == CMDL_OUTPUT_MASM) {
      // Получить подтип
      for (opt = 0; opt < TableSize(SubtypeNames); opt++) {
         int len = (int)strlen(SubtypeNames[opt].b);
         if (strncmp(string, SubtypeNames[opt].b, len) == 0) {
            // Сопоставить с найденным
            SubType = SubtypeNames[opt].a;  break;
         }
      }
   }
}


void CCommandLineInterpreter::InterpretVerboseOption(char * string) {
   // Интерпретировать опцию из комстроки silent/verbose
   Verbose = atoi(string);
}


void CCommandLineInterpreter::InterpretDumpOption(char * string) {
   // Интерпретировать опцию dump
   if (OutputType || DumpOptions) err.submit(2007);          // Both dump and convert specified

   char * s1 = string;
   while (*s1) {
      switch (*(s1++)) {
      case 'f': case 'F':  // демпировать заголовок файла
         DumpOptions |= DUMP_FILEHDR;  break;
      case 'h': case 'H':  // демпировать заголовки секций
         DumpOptions |= DUMP_SECTHDR;  break;
      case 's': case 'S':  // демпировать таблицу символов
         DumpOptions |= DUMP_SYMTAB;  break;
      case 'r': case 'R':  // демпировать релокации
         DumpOptions |= DUMP_RELTAB;  break;
      case 'n': case 'N':  // демпировать таблицу строк
         DumpOptions |= DUMP_STRINGTB;  break;
      case 'c': case 'C':  // демпировать записи комментариев (на данный момент только для OMF)
         DumpOptions |= DUMP_COMMENT;  break;         
      default:
         err.submit(2004, string-1);  // Неизвестная опция
      }
   }
   if (DumpOptions == 0) DumpOptions = DUMP_FILEHDR;
   OutputType = CMDL_OUTPUT_DUMP;
   if (OutputType && OutputType != CMDL_OUTPUT_DUMP) err.submit(2007); // Both dump and convert specified
   OutputType = CMDL_OUTPUT_DUMP;
}


void CCommandLineInterpreter::InterpretDebugInfoOption(char * string) {
   // Интерпретировать опцию debug info
   if (strlen(string) > 1) err.submit(2004, string-1);  // Неизвестная опция
   switch (*string) {
      case 's': case 'S': case 'r': case 'R':  // Strip (удалить)
         DebugInfo = CMDL_DEBUG_STRIP;  break;
      case 'p': case 'P':                      // Сохранить
         DebugInfo = CMDL_DEBUG_PRESERVE;  break;
      case 'l': case 'L':                      // (Не поддерживается)
         DebugInfo = CMDL_DEBUG_LINNUM;  break;
      case 'c': case 'C':                      // (Не поддерживается)
         DebugInfo = CMDL_DEBUG_SYMBOLS;  break;
      default:
         err.submit(2004, string-1);  // Неизвестная опция
   }
}


void CCommandLineInterpreter::InterpretExceptionInfoOption(char * string) {
   // Интерпретировать опцию информации обработчика исключений
   if (strlen(string) > 1) err.submit(2004, string-1);  // Неизвестная опция
   switch (*string) {
      case 's': case 'S': case 'r': case 'R':  // Strip (remove)
         ExeptionInfo = CMDL_EXCEPTION_STRIP;  break;
      case 'p': case 'P':                      // Preserve
         ExeptionInfo = CMDL_EXCEPTION_PRESERVE;  break;
      default:
         err.submit(2004, string-1);  // Неизвестная опция
   }
}


void CCommandLineInterpreter::InterpretErrorOption(char * string) {
   // Интерпретировать опцию warning/error из командной строки
   if (strlen(string) < 3) {
      err.submit(2004, string); return; // Неизвестная опция
   } 
   int newstatus;   // Новый статус для данного номера ошибки

   switch (string[1]) {
   case 'd': case 'D':  // Отключить
      newstatus = 0;  break;

   case 'w': case 'W':  // Считать предупреждением (warning)
      newstatus = 1;  break;

   case 'e': case 'E':  // Считать ошибкой
      newstatus = 2;  break;

   default:
      err.submit(2004, string);  // Неизвестная опция
      return;
   }
   if (string[2] == 'x' || string[2] == 'X') {
      // Применить новый статус ко всем нефатальным сообщениям
      for (SErrorText * ep = ErrorTexts; ep->Status < 9; ep++) {
         ep->Status = newstatus;  // Изменить статус всех ошибок
      }
   }
   else {
      int ErrNum = atoi(string+2);
      if (ErrNum == 0 && string[2] != '0') {
         err.submit(2004, string);  return; // Неизвестная опция
      }
      // Искать данный номер ошибки
      SErrorText * ep = err.FindError(ErrNum);
      if (ep->Status & 0x100) {
         // Номер ошибки не найден
         err.submit(1003, ErrNum);  return; // Неизвестный номер ошибки
      }
      // Изменить состояние данной ошибки
      ep->Status = newstatus;
   }
}

void CCommandLineInterpreter::InterpretSymbolNameChangeOption(char * string) {
   // Интерпретировать различные опции для изменения названий символов
   SSymbolChange sym = {0,0,0,0};   // Запись изменения символа

   // Проверить в данной команде наличие названий символов
   char * name1 = 0, * name2 = 0;
   if (string[2] == ':' && string[3]) {
      // найдено name1
      name1 = string+3;
      // Искать второе ':' или конец
      name2 = name1 + 1;
      while (name2[0] != 0) {
         if (name2[0] == ':') {
            *name2 = 0;  // Отметить конец name1
            if (name2[1]) {
               // name2 найдено
               name2++;     // Name2 начинается здесь
               break;
            }
         }
         name2++;
      }
      if (name2 && name2[0]) {
         // name2 найдено. Проверить, оканчивается ли оно на ':'
         for (uint32 i = 0; i < (uint32)strlen(name2); i++) {
            if (name2[i] == ':') name2[i] = 0;
         }
      }
      if (name2[0] == 0) name2 = 0;
   }
   // Проверить на имя-дубликат
   if (name1 && SymbolIsInList(name1)) {
      // Этот символ уже есть в списке
      err.submit(2015, name1);
      return;
   }

   switch (string[1]) {
   case 'u': case 'U':  // опция подчеркивания
      switch (string[2]) {
      case 0:
         Underscore = CMDL_UNDERSCORE_CHANGE; 
         if (string[0] == 'a') Underscore |= CMDL_KEEP_ALIAS;
         break;
      case '+': case 'a': case 'A': 
         Underscore = CMDL_UNDERSCORE_ADD; 
         if (string[0] == 'a') Underscore |= CMDL_KEEP_ALIAS;
         break;
      case '-': case 'r': case 'R': 
         Underscore = CMDL_UNDERSCORE_REMOVE; 
         if (string[0] == 'a') Underscore |= CMDL_KEEP_ALIAS;
         break;
      default:
         err.submit(2004, string);  // Неизвестная опция
      }
      break;

   case 'd': case 'D':  // section name dot option
      SegmentDot = CMDL_SECTIONDOT_CHANGE; 
      break;

   case 'r': case 'R':  // опция замены названия
      if (name1 == 0 || name2 == 0 || *name1 == 0 || *name2 == 0) {
         err.submit(2008, string); return;
      }
      sym.Name1 = name1;
      sym.Name2 = name2;
      sym.Action  = SYMA_CHANGE_NAME;
      if (string[0] == 'a') sym.Action = SYMA_CHANGE_ALIAS;
      SymbolList.Push(&sym, sizeof(sym));  SymbolChangeEntries++;
      break;

   case 'p': case 'P':  // опция замены префикса
      if (name1 == 0 || *name1 == 0) {
         err.submit(2008, string); return;
      }
      if (name2 == 0) name2 = (char*)"";
      sym.Name1 = name1;
      sym.Name2 = name2;
      sym.Action  = SYMA_CHANGE_PREFIX;
      SymbolList.Push(&sym, sizeof(sym));  SymbolChangeEntries++;
      break;

   case 'w': case 'W':  // Weaken symbol
      if (name1 == 0 || *name1 == 0 || name2) {
         err.submit(2009, string); return;
      }
      sym.Name1 = name1;
      sym.Action  = SYMA_MAKE_WEAK;
      SymbolList.Push(&sym, sizeof(sym));  SymbolChangeEntries++;
      break;

   case 'l': case 'L':  // Сделать символ локальным или скрытым
      if (name1 == 0 || *name1 == 0 || name2) {
         err.submit(2009, string); return;
      }
      sym.Name1 = name1;
      sym.Action  = SYMA_MAKE_LOCAL;
      SymbolList.Push(&sym, sizeof(sym));  SymbolChangeEntries++;
      break;

   default:
      err.submit(2004, string);  // Неизвестная опция
   }
}

void CCommandLineInterpreter::InterpretImagebaseOption(char * string) {
   // Интерпретировать опцию основания имиджа
   char * p = strchr(string, '=');
   if ((strnicmp(string, "imagebase", 9) && strnicmp(string, "image_base", 10)) || !p) {
      // Неизвестная опция
      err.submit(1002, string);
      return;
   }
   if (ImageBase) err.submit(2330); // Imagebase задано более раза

   p++;  // указать на число, следующее за '='
   // Проход по строке для интерпретации 16-ричного числа
   while (*p) {
      char letter = *p | 0x20; // буква нижнего регистра
      if (*p >= '0' && *p <= '9') {
         // 0 - 9 16-ричное число
         ImageBase = (ImageBase << 4) + *p - '0';
      }
      else if (letter >= 'a' && letter <= 'f') {
         // A - F 16-ричное число
         ImageBase = (ImageBase << 4) + letter - 'a' + 10;
      }
      else if (letter == 'h') {
         // 16-ричное число может оканчиваться на 'H'
         break;
      }
      else if (letter == 'x' || letter == ' ') {
         // Hexadecimal number may begin with 0x
         if (ImageBase) {
            // 'x' preceded by number other than 0
            err.submit(1002, string); break;
         }
      }
      else {
         // Any other character not allowed
         err.submit(1002, string); break;
      }
      // next character
      p++;
   }
   if (ImageBase & 0xFFF) {
      // Must be divisible by page size
      err.submit(2331, string);
   }
   if ((int32)ImageBase <= 0) {
      // Cannot be zero or > 2^31
      err.submit(2332, string);
   }
}


SSymbolChange const * CCommandLineInterpreter::GetMemberToAdd() {
   // Get names of object files to add to library
   // replaced will be set to 1 if a member with the same name is replaced

   // Search through SymbolList, continuing from last CurrentSymbol
   while (CurrentSymbol < SymbolList.GetDataSize()) {
      // Get pointer to current symbol record
      SSymbolChange * Sym = (SSymbolChange *)(SymbolList.Buf() + CurrentSymbol);
      // Increment pointer
      CurrentSymbol += sizeof(SSymbolChange);
      // Check record type
      if (Sym->Action == SYMA_ADD_MEMBER) {
         // Name found
         return Sym;
      }
   }
   // No more names found
   return 0;
}


void CCommandLineInterpreter::CheckExtractSuccess() {
   // Check if library members to extract were found

   // Search through SymbolList for extract records
   for (uint32 i = 0; i < SymbolList.GetDataSize(); i += sizeof(SSymbolChange)) {
      SSymbolChange * Sym = (SSymbolChange *)(SymbolList.Buf() + i);
      if (Sym->Action == SYMA_EXTRACT_MEMBER && Sym->Done == 0) {
         // Member has not been extracted
         err.submit(1104, Sym->Name1);
      }
   }
}


void CCommandLineInterpreter::CheckSymbolModifySuccess() {
   // Check if symbols to modify were found

   // Search through SymbolList for symbol change records
   for (uint32 i = 0; i < SymbolList.GetDataSize(); i += sizeof(SSymbolChange)) {
      SSymbolChange * Sym = (SSymbolChange *)(SymbolList.Buf() + i);
      if (Sym->Action >= SYMA_MAKE_WEAK && Sym->Action <= SYMA_CHANGE_ALIAS && Sym->Done == 0) {
         // Member has not been extracted
         err.submit(1106, Sym->Name1);
      }
   }
}


int CCommandLineInterpreter::SymbolIsInList(char const * name) {
   // Check if name is already in symbol list
   int isym, nsym = SymbolList.GetNumEntries();
   SSymbolChange * List = (SSymbolChange *)SymbolList.Buf(), * psym;

   // Search for name in list of names specified by user on command line
   for (isym = 0, psym = List; isym < nsym; isym++, psym++) {
      if (strcmp(name, psym->Name1) == 0) return 1;  // Matching name found
   }
   return 0;
}


int CCommandLineInterpreter::SymbolChange(char const * oldname, char const ** newname, int symtype) {
   // Check if symbol has to be changed
   int action, i, isym;
   int nsym = SymbolList.GetNumEntries();

   // Convert standard names if type conversion
   if (cmd.InputType != cmd.OutputType 
   && uint32(cmd.InputType) <= MaxType && uint32(cmd.OutputType) <= MaxType) {
      if (DesiredWordSize == 32) {
         // Look for standard names to translate, 32-bit
         for (i = 0; i < NumStandardNames; i++) {
            if (strcmp(oldname, StandardNames32[i][cmd.InputType]) == 0) {
               // Match found
               *newname = StandardNames32[i][cmd.OutputType];
               CountSymbolNameChanges++;
               return SYMA_CHANGE_NAME; // Change name of symbol
            }
         }
      }
      else {
         // Look for standard names to translate, 64-bit
         for (i = 0; i < NumStandardNames; i++) {
            if (strcmp(oldname, StandardNames64[i][cmd.InputType]) == 0) {
               // Match found
               *newname = StandardNames64[i][cmd.OutputType];
               CountSymbolNameChanges++;
               return SYMA_CHANGE_NAME; // Change name of symbol
            }
         }
      }
   }

   // See if there are other conversions to do
   if (Underscore == 0 && SegmentDot == 0 && nsym == 0) return SYMA_NOCHANGE;  // Nothing to do
   if (oldname == 0 || *oldname == 0) return SYMA_NOCHANGE;                    // No name

   static char NameBuffer[MAXSYMBOLLENGTH];

   SSymbolChange * List = (SSymbolChange *)SymbolList.Buf(), * psym;
   // search for name in list of names specified by user on command line
   for (isym = 0, psym = List; isym < nsym; isym++, psym++) {
      if (strcmp(oldname, psym->Name1) == 0) break;  // Matching name found
      if (psym->Action == SYMA_CHANGE_PREFIX && strncmp(oldname, psym->Name1, strlen(psym->Name1))==0) break; // matching prefix found
   }
   if (isym < nsym) {
      // A matching name was found.
      action = psym->Action;
      // Whatever action is specified here is overriding any general option
      // Statistics counting
      switch (action) {
      case SYMA_MAKE_WEAK: // Make public symbol weak
         if (symtype == SYMT_PUBLIC) {
            CountSymbolsWeakened++;  psym->Done++;
         }
         else { // only public symbols can be weakened
            err.submit(1020, oldname); // cannot make weak
            action = SYMA_NOCHANGE;
         }
         break;
      case SYMA_MAKE_LOCAL: // Hide public or external symbol
         if (symtype == SYMT_PUBLIC || symtype == SYMT_EXTERNAL) {
            CountSymbolsMadeLocal++;  psym->Done++;
            if (symtype == SYMT_EXTERNAL) err.submit(1023, oldname);
         }
         else { // only public and external symbols can be made local
            err.submit(1021, oldname); // cannot make local
            action = SYMA_NOCHANGE;
         }
         break;
      case SYMA_CHANGE_NAME: // Change name of symbol or segment or library member
         CountSymbolNameChanges++;  psym->Done++;  
         break;
      case SYMA_CHANGE_ALIAS: // Make alias for public symbol
         if (symtype == SYMT_PUBLIC) {
            CountSymbolNameAliases++;  psym->Done++;
         }
         else { // only public symbols can have aliases
            err.submit(1022, oldname); // cannot make alias
            action = SYMA_NOCHANGE;
         }
         break;
      case SYMA_CHANGE_PREFIX: // Change beginning of symbol name
         if (symtype == SYMT_PUBLIC || symtype == SYMT_EXTERNAL || symtype == SYMT_LOCAL || symtype == SYMT_SECTION) {
            if (strlen(oldname) - strlen(psym->Name1) + strlen(psym->Name2) >= MAXSYMBOLLENGTH) {
               err.submit(2202, oldname);  // Name too long
               action = SYMA_NOCHANGE;  break;
            }
            strcpy_s(NameBuffer,sizeof(NameBuffer), psym->Name2);
            strcpy_s(NameBuffer + strlen(psym->Name2), sizeof(NameBuffer + strlen(psym->Name2)), oldname + strlen(psym->Name1));
            action = SYMA_CHANGE_NAME;
            *newname = NameBuffer;
            CountSymbolNameChanges++;  psym->Done++;
            return action;
         }
         else { // only symbols and segments can change prefix
            err.submit(1024, oldname);
            action = SYMA_NOCHANGE;
         }
         break;
      case SYMA_DELETE_MEMBER: case SYMA_EXTRACT_MEMBER: case SYMA_ADD_MEMBER:
         if (symtype == SYMT_LIBRARYMEMBER) {
            // Change to library member
            psym->Done++;
         }
         else {
            // Ignore action for symbols that have the same name as a library member
            action = SYMA_NOCHANGE;
         }
      }

      // New symbol name
      *newname = psym->Name2;
      // Action to take
      return action;
   }

   // Not found in list. Check for section options
   if (symtype == SYMT_SECTION) {
      if (!strncmp(oldname, ".rela", 5)) {
         // ELF relocation section must have same name change as mother section
         const char * name2;
         int action2 = SymbolChange(oldname+5, &name2, symtype);
         if (action2 == SYMA_CHANGE_NAME && strlen(name2) + 6 < MAXSYMBOLLENGTH) {
            sprintf_s(NameBuffer, sizeof(NameBuffer), ".rela%s", name2);
            *newname = NameBuffer;
            return action2;
         }
      }
      if (!strncmp(oldname, ".rel", 4)) {
         // ELF relocation section must have same name change as mother section
         const char * name2;
         int action2 = SymbolChange(oldname+4, &name2, symtype);
         if (action2 == SYMA_CHANGE_NAME && strlen(name2) + 5 < MAXSYMBOLLENGTH) {
            sprintf_s(NameBuffer, sizeof(NameBuffer), ".rel%s", name2);
            *newname = NameBuffer;
            return action2;
         }
      }
      if (SegmentDot) {
         // Change section name

         if (SegmentDot == CMDL_SECTIONDOT_U2DOT && oldname[0] == '_') {
            // replace '_' by '.'
            strncpy_s(NameBuffer, sizeof(NameBuffer), oldname, MAXSYMBOLLENGTH-1);
            NameBuffer[MAXSYMBOLLENGTH-1] = 0;  // Terminate string
            NameBuffer[0] = '.';
            *newname = NameBuffer;
            CountSectionDotConversions++;
            return SYMA_CHANGE_NAME;
         }
         if (SegmentDot == CMDL_SECTIONDOT_DOT2U && oldname[0] == '.') {
            // replace '.' by '_'
            // Note: Microsoft and Intel compilers have . on standard names
            // and _ on nonstandard names in COFF files
            // Borland requires _ on all segment names in OMF files
            /* 
            // Standard section names that should not be changed
            static char const * StandardSectionNames[] = {
               ".text", ".data", ".bss", ".comment", ".lib"
            };
            for (uint32 i = 0; i < sizeof(StandardSectionNames)/sizeof(StandardSectionNames[0]); i++) {
               if (stricmp(oldname,StandardSectionNames[i]) == 0) {
                  // Standard name. Don't change
                  return SYMA_NOCHANGE;
               }
            }*/
            strncpy_s(NameBuffer, sizeof(NameBuffer), oldname, MAXSYMBOLLENGTH-1);
            NameBuffer[MAXSYMBOLLENGTH-1] = 0;  // Terminate string
            NameBuffer[0] = '_';
            *newname = NameBuffer;
            CountSectionDotConversions++;
            return SYMA_CHANGE_NAME;
         }
      }
   }

   // Check for underscore options
   if ((Underscore & 0x0F) == CMDL_UNDERSCORE_REMOVE && oldname[0] == '_') {
      // Remove underscore
      if ((Underscore & CMDL_KEEP_ALIAS) && symtype == SYMT_PUBLIC) {
         // Alias only applicable to public symbols
         // Make alias without underscore
         *newname = oldname + 1;
         CountUnderscoreConversions++;  CountSymbolNameAliases++;
         return SYMA_CHANGE_ALIAS;
      }
      // Change name applicable to public and external symbols
      if (symtype == SYMT_PUBLIC || symtype == SYMT_EXTERNAL) {
         // Make new name without underscore
         *newname = oldname + 1;
         CountUnderscoreConversions++;
         return SYMA_CHANGE_NAME;
      }
   }
   if ((Underscore & 0x0F) == CMDL_UNDERSCORE_ADD) {
      // Add underscore even if it already has one
      if ((Underscore & CMDL_KEEP_ALIAS) && symtype == SYMT_PUBLIC) {
         // Alias only applicable to public symbols
         // Make alias with underscore
         strncpy_s(NameBuffer+1, sizeof(NameBuffer+1), oldname, MAXSYMBOLLENGTH-2);
         NameBuffer[MAXSYMBOLLENGTH-1] = 0;  // Terminate string
         NameBuffer[0] = '_';
         *newname = NameBuffer;
         CountUnderscoreConversions++;  CountSymbolNameAliases++;
         return SYMA_CHANGE_ALIAS;
      }
      // Change name applicable to public and external symbols
      if (symtype == SYMT_PUBLIC || symtype == SYMT_EXTERNAL) {
         // Make new name with underscore
         strncpy_s(NameBuffer+1,sizeof(NameBuffer+1), oldname, MAXSYMBOLLENGTH-2);
         NameBuffer[MAXSYMBOLLENGTH-1] = 0;  // Terminate string
         NameBuffer[0] = '_';
         *newname = NameBuffer;
         CountUnderscoreConversions++;
         return SYMA_CHANGE_NAME;
      }
   }
   return SYMA_NOCHANGE;
}


int CCommandLineInterpreter::SymbolChangesRequested() {
   // Any kind of symbol change requested on command line
   return (Underscore != 0) 
        | (SegmentDot != 0) << 1 
        | (SymbolChangeEntries != 0) << 2;
}


void CCommandLineInterpreter::CountDebugRemoved() {
   // Count debug sections removed
   CountDebugSectionsRemoved++;
}


void CCommandLineInterpreter::CountExceptionRemoved() {
   // Count exception handler sections removed
   CountExceptionSectionsRemoved++;
}


void CCommandLineInterpreter::CountSymbolsHidden() {
   // Count unused external references hidden
   CountUnusedSymbolsHidden++;
}


void CCommandLineInterpreter::ReportStatistics() {
   // Report statistics about name changes etc.
   if (DebugInfo == CMDL_DEBUG_STRIP || ExeptionInfo == CMDL_EXCEPTION_STRIP 
   || Underscore || SegmentDot || SymbolList.GetNumEntries()) {
      printf ("\n");
   }
   if (DebugInfo == CMDL_DEBUG_STRIP) {
      printf ("\n%3i Debug sections removed", CountDebugSectionsRemoved);
   }
   if (ExeptionInfo == CMDL_EXCEPTION_STRIP) {
      printf ("\n%3i Exception sections removed", CountExceptionSectionsRemoved);
   }
   if ((DebugInfo == CMDL_DEBUG_STRIP || ExeptionInfo == CMDL_EXCEPTION_STRIP) 
   && CountUnusedSymbolsHidden) {
      printf ("\n%3i Unused external symbol references hidden", CountUnusedSymbolsHidden);
   }

   if (Underscore || SegmentDot || SymbolList.GetNumEntries()) {
      if (CountUnderscoreConversions || Underscore) {
         printf ("\n%3i Changes in leading underscores on symbol names", CountUnderscoreConversions);
      }
      if (CountSectionDotConversions || SegmentDot) {
         printf ("\n%3i Changes in leading characters on section names", CountSectionDotConversions);
      }
      if (CountSymbolNameChanges) {
         printf ("\n%3i Symbol names changed", CountSymbolNameChanges);
      }
      if (CountSymbolNameAliases) {
         printf ("\n%3i Public symbol names aliased", CountSymbolNameAliases);
      }
      if (CountSymbolsWeakened) {
         printf ("\n%3i Public symbol names made weak", CountSymbolsWeakened);
      }
      if (CountSymbolsMadeLocal) {
         printf ("\n%3i Public or external symbol names made local", CountSymbolsMadeLocal);
      }
      if (SymbolChangeEntries && !CountSymbolNameChanges && !CountSymbolNameAliases && !CountSymbolsWeakened && !CountSymbolsMadeLocal) {
         printf ("\n    No symbols to change were found");
      }
   }
}


void CCommandLineInterpreter::Help() {
   // Print help message
   //String oc =NFormat("\n Преобразователь Объектов версии %.2f для платформ x86 и x86-64.", OBJCONV_VERSION);
   //puts(NFormat("ЛЯ_ЛЯ_ЛЯ"));
   printf("\nObject file converter version %.2f for x86 and x86-64 platforms.", OBJCONV_VERSION);
   printf("\nCopyright (c) 2008 by Agner Fog. Gnu General Public License.");
   printf("\n\nUsage: oc options inputfile [outputfile]");
   printf("\n\nOptions:");
   printf("\n-fXXX[SS]  Output file format XXX, word size SS. Supported formats:");
   printf("\n           PE, COFF, ELF, OMF, MACHO\n");
   printf("\n-fasm      Disassemble file (-fmasm, -fnasm, -fyasm, -fgasm)\n");
   printf("\n-dXXX      Dump file contents to console.");
   printf("\n           Values of XXX (can be combined):");
   printf("\n           f: File header, h: section Headers, s: Symbol table,");
   printf("\n           r: Relocation table, n: string table.\n");
   //printf("\n-ds        Strip Debug info.");    // default if input and output are different formats
   //printf("\n-dp        Preserve Debug info, even if it is incompatible.");
   printf("\n-xs        Strip exception handling info and other incompatible info.");  // default if input and output are different formats. Hides unused symbols
   printf("\n-xp        Preserve exception handling info and other incompatible info.\n");
  
   printf("\n-nu        change symbol Name Underscores to the default for the target format.");
   printf("\n-nu-       remove Underscores from symbol Names.");
   printf("\n-nu+       add Underscores to symbol Names.");
   printf("\n-nd        replace Dot/underscore in section names.");
   printf("\n-nr:N1:N2  Replace symbol Name N1 with N2.");
   printf("\n-ar:N1:N2  make Alias N2 for existing public name N1.");
   printf("\n-np:N1:N2  Replace symbol Prefix N1 with N2.");
   printf("\n-nw:N1     make public symbol Name N1 Weak (ELF and MAC64 only).");
   printf("\n-nl:N1     make public symbol Name N1 Local (invisible).\n");

   printf("\n-lx        eXtract all members from Library.");
   printf("\n-lx:N1:N2  eXtract member N1 from Library to file N2.");
   printf("\n-ld:N1     Delete member N1 from Library.");
   printf("\n-la:N1:N2  Add object file N1 to Library as member N2.");
   printf("\n           Alternative: -lib LIBRARYNAME OBJECTFILENAMES.\n");

   printf("\n-vN        Verbose options. Values of N:");
   printf("\n           0: Silent, 1: Print file names and types, 2: Tell about conversions.\n");

   printf("\n-wdNNN     Disable Warning NNN.");
   printf("\n-weNNN     treat Warning NNN as Error. -wex: treat all warnings as errors.");
   printf("\n-edNNN     Disable Error number NNN.");
   printf("\n-ewNNN     treat Error number NNN as Warning.\n");

   printf("\n-h         Print this help screen.\n");

   printf("\n@RFILE     Read additional options from response file RFILE.\n");
   printf("\n\nExample:");
   printf("\noc -felf32 -nu filename.obj filename.o\n\n");
}
