
module ll.Target;
import ll.Types;
//#include "llvm/Config/llvm-config.h"


extern (C){


/**
 * @defgroup LLVMCTarget Информация о Цели
 * @ingroup LLVMC
 *
 * @{
 */

enum ЛЛППорядокБайт { LLVMBigEndian, LLVMLittleEndian };

struct LLVMOpaqueTargetData;
struct LLVMOpaqueTargetLibraryInfotData;
alias LLVMOpaqueTargetData *ЛЛДанныеОЦели;
alias LLVMOpaqueTargetLibraryInfotData *ЛЛИнфоЦелевойБиблиотеки;
/+

/* Declare all of the target-initialization functions that are available. */
#define LLVM_TARGET(TargetName) \
  проц LLVMInitialize##TargetName##TargetInfo();
#include "llvm/Config/Targets.def"
#undef LLVM_TARGET  /* Explicit undef to make SWIG happier */

#define LLVM_TARGET(TargetName) проц LLVMInitialize##TargetName##Target();
#include "llvm/Config/Targets.def"
#undef LLVM_TARGET  /* Explicit undef to make SWIG happier */

#define LLVM_TARGET(TargetName) \
  проц LLVMInitialize##TargetName##TargetMC();
#include "llvm/Config/Targets.def"
#undef LLVM_TARGET  /* Explicit undef to make SWIG happier */

/* Declare all of the available assembly printer initialization functions. */
#define LLVM_ASM_PRINTER(TargetName) \
  проц LLVMInitialize##TargetName##AsmPrinter();
#include "llvm/Config/AsmPrinters.def"
#undef LLVM_ASM_PRINTER  /* Explicit undef to make SWIG happier */

/* Declare all of the available assembly parser initialization functions. */
#define LLVM_ASM_PARSER(TargetName) \
  проц LLVMInitialize##TargetName##AsmParser();
#include "llvm/Config/AsmParsers.def"
#undef LLVM_ASM_PARSER  /* Explicit undef to make SWIG happier */

/* Declare all of the available disassembler initialization functions. */
#define LLVM_DISASSEMBLER(TargetName) \
  проц LLVMInitialize##TargetName##Disassembler();
#include "llvm/Config/Disassemblers.def"
#undef LLVM_DISASSEMBLER  /* Explicit undef to make SWIG happier */
+/
/** LLVMInitializeAllTargetInfos - The main program should call this function if
    it wants access to all available targets that LLVM is configured to
    support. */
проц ЛЛНициализуйВсеИнфОЦели();

/** LLVMInitializeAllTargets - The main program should call this function if it
    wants to link in all available targets that LLVM is configured to
    support. */
проц ЛЛНициализуйВсеЦели();

/** LLVMInitializeAllTargetMCs - The main program should call this function if
    it wants access to all available target MC that LLVM is configured to
    support. */
проц ЛЛНициализуйВсеЦелевыеМК();

/** LLVMInitializeAllAsmPrinters - The main program should call this function if
    it wants all asm printers that LLVM is configured to support, to make them
    available via the TargetRegistry. */
проц ЛЛНициализуйВсеАсмПринтеры() ;

/** LLVMInitializeAllAsmParsers - The main program should call this function if
    it wants all asm parsers that LLVM is configured to support, to make them
    available via the TargetRegistry. */
проц ЛЛНициализуйВсеАсмПарсеры() ;

/** LLVMInitializeAllDisassemblers - The main program should call this function
    if it wants all disassemblers that LLVM is configured to support, to make
    them available via the TargetRegistry. */
проц ЛЛНициализуйВсеДизассемблеры() ;

/** LLVMInitializeNativeTarget - The main program should call this function to
    initialize the native target corresponding to the host.  This is useful
    for JIT applications to ensure that the target gets linked in correctly. */
ЛЛБул ЛЛИнициализуйНативныйТаргет();

/** LLVMInitializeNativeTargetAsmParser - The main program should call this
    function to initialize the parser for the native target corresponding to the
    host. */
ЛЛБул ЛЛИнициализуйНативныйАсмПарсер();


/** LLVMInitializeNativeTargetAsmPrinter - The main program should call this
    function to initialize the printer for the native target corresponding to
    the host. */
ЛЛБул ЛЛИнициализуйНативныйАсмПринтер() ;

/** LLVMInitializeNativeTargetDisassembler - The main program should call this
    function to initialize the disassembler for the native target corresponding
    to the host. */
ЛЛБул ЛЛИнициализуйНативныйДизассемблер();


/*===-- Данные о Цели -------------------------------------------------------===*/

/**
 * Получить раскладку данных для модуля.
 *
 * @see Module::getDataLayout()
 */
ЛЛДанныеОЦели ЛЛДайРаскладкуДанныхМодуля(ЛЛМодуль M);

/**
 * Установить раскладку данных для модуля.
 *
 * @see Module::setDataLayout()
 */
проц ЛЛУстРаскладкуДанныхМодуля(ЛЛМодуль M, ЛЛДанныеОЦели DL);

/** Создаёт данные о цели из строки раскладки цели.
    Смотри конструктор llvm::DataLayout::DataLayout. */
ЛЛДанныеОЦели ЛЛСоздайДанОЦели(ткст0 стрРеп);

/** Вымещает TargetData.
    Смотри деструктор llvm::DataLayout::~DataLayout. */
проц ЛЛВыместиДанОЦели(ЛЛДанныеОЦели доц);

/** Добавляет инфу о целевой библиотеке в менеджер проходок. Владение инфой о целевой библиотеке не принимает.
    Смотри метод llvm::PassManagerBase::add. */
проц ЛЛДобавьИнфОЦБиб(ЛЛИнфоЦелевойБиблиотеки TLI,
                              ЛЛМенеджерПроходок пм);

/** Преобразует целевые данные в строку выкладки цели. Эту строку затем вымещает LLVMDisposeMessage.
    Смотри конструктор llvm::DataLayout::DataLayout. */
ткст0 ЛЛКопируйТкстПредстДанОЦели(ЛЛДанныеОЦели доц);

/** Возвращает целевой порядок байтов, либо LLVMBigEndian или
    LLVMLittleEndian.
    Смотри метод llvm::DataLayout::isLittleEndian. */
ЛЛППорядокБайт ЛЛПорядокБайт(ЛЛДанныеОЦели доц);

/** Возвращает размер указателя в байтах для цели.
    Смотри метод llvm::DataLayout::getPointerSize. */
бцел ЛЛРазмУкз(ЛЛДанныеОЦели доц);

/** Возвращает размер указателя в байтах для цели для заданного апресного пространства (АП).
    Смотри метод llvm::DataLayout::getPointerSize. */
бцел ЛЛРазмУкзДляАП(ЛЛДанныеОЦели доц, бцел AS);

/** Возвращает целочисленный тип того же размера, что и указатель у цели.
    Смотри метод llvm::DataLayout::getIntPtrType. */
ЛЛТип ЛЛТипЦелУкз(ЛЛДанныеОЦели доц);

/** Возвращает целочисленный тип того же размера, что и указатель у цели.
    Эта версия позволяет задать адресное пространство.
    Смотри метод llvm::DataLayout::getIntPtrType. */
ЛЛТип ЛЛТипЦелУкзДляАП(ЛЛДанныеОЦели доц, бцел AS);

/** Возвращает целочисленный тип того же размера, что и указатель у цели.
    Смотри метод llvm::DataLayout::getIntPtrType. */
ЛЛТип ЛЛТипЦелУкзВКонтексте(ЛЛКонтекст к, ЛЛДанныеОЦели доц);

/** Возвращает целочисленный тип того же размера, что и указатель у цели.
    Эта версия позволяет задать адресное пространство.
    Смотри метод llvm::DataLayout::getIntPtrType. */
ЛЛТип ЛЛТипЦелУкзДляАПВКонтексте(ЛЛКонтекст к, ЛЛДанныеОЦели доц,
                                         бцел AS);

/** Вычисляет размер типа в байтах для цели.
    Смотри метод llvm::DataLayout::getTypeSizeInBits. */
бдол ЛЛРазмТипаВБитах(ЛЛДанныеОЦели доц, ЛЛТип тип);

/** Вычисляет размер хранения типа в байтах для цели.
    Смотри метод llvm::DataLayout::getTypeStoreSize. */
бдол ЛЛРазмХранТипа(ЛЛДанныеОЦели доц, ЛЛТип тип);

/** Вычисляет размер ABI (ДИП) типа в байтах для цели.
    Смотри метод llvm::DataLayout::getTypeAllocSize. */
бдол ЛЛДИПРазмТипа(ЛЛДанныеОЦели доц, ЛЛТип тип);

/** Вычисляет ABI раскладку (alignment) типа в байтах для цели.
    Смотри метод llvm::DataLayout::getTypeABISize. */
бцел ЛЛДИПРаскладкаТипа(ЛЛДанныеОЦели доц, ЛЛТип тип);

/** Computes the call frame alignment of a type in bytes for a target.
    Смотри метод llvm::DataLayout::getTypeABISize. */
бцел ЛЛРаскладкаФреймаВызДляТипа(ЛЛДанныеОЦели доц, ЛЛТип тип);

/** Computes the preferred alignment of a type in bytes for a target.
    Смотри метод llvm::DataLayout::getTypeABISize. */
бцел ЛЛПредпочтРаскладкаТипа(ЛЛДанныеОЦели доц, ЛЛТип тип);

/** Computes the preferred alignment of a global variable in bytes for a target.
    Смотри метод llvm::DataLayout::getPreferredAlignment. */
бцел ЛЛПредпочтРаскладкаГлоба(ЛЛДанныеОЦели доц,
                                        ЛЛЗначение глобПеремн);

/** Computes the structure element that contains the byte offset for a target.
    Смотри метод llvm::StructLayout::getElementContainingOffset. */
бцел ЛЛЭлтПоСмещ(ЛЛДанныеОЦели доц, ЛЛТип типСтрукт,
                             бдол смещ);

/** Computes the byte offset of the indexed struct element for a target.
    Смотри метод llvm::StructLayout::getElementContainingOffset. */
бдол ЛЛСМещЭлта(ЛЛДанныеОЦели доц,
                                       ЛЛТип типСтрукт, бцел элт);
}