

extern "C" {
#include "Header.h"
/**
 * @defgroup LLVMCTarget Target information
 * @ingroup LLVMC
 *
 * @{
 */
/*
enum LLVMByteOrdering { LLVMBigEndian, LLVMLittleEndian };

typedef struct LLVMOpaqueTargetData *‹‹„анныеЋ–ели;
typedef struct LLVMOpaqueTargetLibraryInfotData *‹‹€нфо–елевойЃиблиотеки;

// Declare all of the target-initialization functions that are available. 
#define LLVM_TARGET(TargetName) \
  void LLVMInitialize##TargetName##TargetInfo(void);
#include "llvm/Config/Targets.def"
#undef LLVM_TARGET  // Explicit undef to make SWIG happier 

#define LLVM_TARGET(TargetName) void LLVMInitialize##TargetName##Target(void);
#include "llvm/Config/Targets.def"
#undef LLVM_TARGET  // Explicit undef to make SWIG happier 

#define LLVM_TARGET(TargetName) \
  void LLVMInitialize##TargetName##TargetMC(void);
#include "llvm/Config/Targets.def"
#undef LLVM_TARGET  // Explicit undef to make SWIG happier 

// Declare all of the available assembly printer initialization functions. 
#define LLVM_ASM_PRINTER(TargetName) \
  void LLVMInitialize##TargetName##AsmPrinter(void);
#include "llvm/Config/AsmPrinters.def"
#undef LLVM_ASM_PRINTER  // Explicit undef to make SWIG happier 

// Declare all of the available assembly parser initialization functions. 
#define LLVM_ASM_PARSER(TargetName) \
  void LLVMInitialize##TargetName##AsmParser(void);
#include "llvm/Config/AsmParsers.def"
#undef LLVM_ASM_PARSER  // Explicit undef to make SWIG happier 

// Declare all of the available disassembler initialization functions. 
#define LLVM_DISASSEMBLER(TargetName) \
  void LLVMInitialize##TargetName##Disassembler(void);
#include "llvm/Config/Disassemblers.def"
#undef LLVM_DISASSEMBLER  // Explicit undef to make SWIG happier 
  
*/

/** LLVMInitializeAllTargetInfos - The main program should call this function if
    it wants access to all available targets that LLVM is configured to
    support. */
LLEXPORT void ЛЛНициализуйВсеИнфОЦели(void) {
LLVMInitializeAllTargetInfos();
}

/** LLVMInitializeAllTargets - The main program should call this function if it
    wants to link in all available targets that LLVM is configured to
    support. */
LLEXPORT void ЛЛНициализуйВсеЦели(void) {
LLVMInitializeAllTargets();
}

/** LLVMInitializeAllTargetMCs - The main program should call this function if
    it wants access to all available target MC that LLVM is configured to
    support. */
LLEXPORT void ЛЛНициализуйВсеЦелевыеМК(void) {
LLVMInitializeAllTargetMCs();
}

/** LLVMInitializeAllAsmPrinters - The main program should call this function if
    it wants all asm printers that LLVM is configured to support, to make them
    available via the TargetRegistry. */
LLEXPORT void ЛЛНициализуйВсеАсмПринтеры(void) {
LLVMInitializeAllAsmPrinters();
}

/** LLVMInitializeAllAsmParsers - The main program should call this function if
    it wants all asm parsers that LLVM is configured to support, to make them
    available via the TargetRegistry. */
LLEXPORT void ЛЛНициализуйВсеАсмПарсеры(void) {
LLVMInitializeAllAsmParsers();
}

/** LLVMInitializeAllDisassemblers - The main program should call this function
    if it wants all disassemblers that LLVM is configured to support, to make
    them available via the TargetRegistry. */
LLEXPORT void ЛЛНициализуйВсеДизассемблеры(void) {
LLVMInitializeAllDisassemblers();
}

/** LLVMInitializeNativeTarget - The main program should call this function to
    initialize the native target corresponding to the host.  This is useful
    for JIT applications to ensure that the target gets linked in correctly. */
LLEXPORT LLVMBool ЛЛИнициализуйНативныйТаргет(void) {
return LLVMInitializeNativeTarget();
}

/** LLVMInitializeNativeTargetAsmParser - The main program should call this
    function to initialize the parser for the native target corresponding to the
    host. */
LLEXPORT LLVMBool ЛЛИнициализуйНативныйАсмПарсер(void) {
return LLVMInitializeNativeAsmParser();
}

/** LLVMInitializeNativeTargetAsmPrinter - The main program should call this
    function to initialize the printer for the native target corresponding to
    the host. */
LLEXPORT LLVMBool ЛЛИнициализуйНативныйАсмПринтер(void) {
return LLVMInitializeNativeAsmPrinter();
}

/** LLVMInitializeNativeTargetDisassembler - The main program should call this
    function to initialize the disassembler for the native target corresponding
    to the host. */
LLEXPORT LLVMBool ЛЛИнициализуйНативныйДизассемблер(void) {
return LLVMInitializeNativeDisassembler();
}

/*===-- Target Data -------------------------------------------------------===*/

/**
 * Obtain the data layout for a module.
 *
 * @see Module::getDataLayout()
 */
LLEXPORT ЛЛДанныеОЦели ЛЛДайРаскладкуДанныхМодуля(ЛЛМодуль M) {
    return LLVMGetModuleDataLayout(M);
}

/**
 * Set the data layout for a module.
 *
 * @see Module::setDataLayout()
 */
LLEXPORT void ЛЛУстРаскладкуДанныхМодуля(ЛЛМодуль M, ЛЛДанныеОЦели DL) {
     LLVMSetModuleDataLayout(M, DL);
}

/** Creates target data from a target layout string.
    See the constructor llvm::DataLayout::DataLayout. */
LLEXPORT ЛЛДанныеОЦели ЛЛСоздайДанОЦели(const char *StringRep) {
    return LLVMCreateTargetData(StringRep);
}

/** Deallocates a TargetData.
    See the destructor llvm::DataLayout::~DataLayout. */
LLEXPORT void ЛЛВыместиДанОЦели(ЛЛДанныеОЦели TD) {
    LLVMDisposeTargetData(TD);
}

/** Adds target library information to a pass manager. This does not take
    ownership of the target library info.
    See the method llvm::PassManagerBase::add. */
LLEXPORT void ЛЛДобавьИнфОЦБиб(ЛЛИнфоЦелевойБиблиотеки TLI,
                              ЛЛМенеджерПроходок PM) {
    LLVMAddTargetLibraryInfo( (LLVMTargetLibraryInfoRef) TLI, PM);
}
/** Converts target data to a target layout string. The string must be disposed
    with LLVMDisposeMessage.
    See the constructor llvm::DataLayout::DataLayout. */
LLEXPORT char *ЛЛКопируйТкстПредстДанОЦели(ЛЛДанныеОЦели TD) {
    return LLVMCopyStringRepOfTargetData(TD);
}

/** Returns the byte order of a target, either LLVMBigEndian or
    LLVMLittleEndian.
    See the method llvm::DataLayout::isLittleEndian. */
LLEXPORT enum LLVMByteOrdering ЛЛПорядокБайт(ЛЛДанныеОЦели TD) {
    return LLVMByteOrder(TD);
}

/** Returns the pointer size in bytes for a target.
    See the method llvm::DataLayout::getPointerSize. */
LLEXPORT unsigned ЛЛРазмУкз(ЛЛДанныеОЦели TD) {
    return LLVMPointerSize(TD);
}

/** Returns the pointer size in bytes for a target for a specified
    address space.
    See the method llvm::DataLayout::getPointerSize. */
LLEXPORT unsigned ЛЛРазмУкзДляАП(ЛЛДанныеОЦели TD, unsigned AS) {
    return LLVMPointerSizeForAS( TD,  AS);
}
/** Returns the integer type that is the same size as a pointer on a target.
    See the method llvm::DataLayout::getIntPtrType. */
LLEXPORT ЛЛТип ЛЛТипЦелУкз(ЛЛДанныеОЦели  TD) {
    return LLVMIntPtrType(TD);
}
/** Returns the integer type that is the same size as a pointer on a target.
    This version allows the address space to be specified.
    See the method llvm::DataLayout::getIntPtrType. */
LLEXPORT ЛЛТип ЛЛТипЦелУкзДляАП(ЛЛДанныеОЦели  TD, unsigned AS) {
    return LLVMIntPtrTypeForAS( TD, AS);
}
/** Returns the integer type that is the same size as a pointer on a target.
    See the method llvm::DataLayout::getIntPtrType. */
LLEXPORT ЛЛТип ЛЛТипЦелУкзВКонтексте(ЛЛКонтекст C, ЛЛДанныеОЦели TD) {
    return LLVMIntPtrTypeInContext(C, TD);
}
/** Returns the integer type that is the same size as a pointer on a target.
    This version allows the address space to be specified.
    See the method llvm::DataLayout::getIntPtrType. */
ЛЛТип ЛЛТипЦелУкзДляАПВКонтексте(ЛЛКонтекст C, ЛЛДанныеОЦели TD,
                                         unsigned AS) {
    return LLVMIntPtrTypeForASInContext(C,  TD, AS);
}

/** Computes the size of a type in bytes for a target.
    See the method llvm::DataLayout::getTypeSizeInBits. */
LLEXPORT unsigned long long ЛЛРазмТипаВБитах(ЛЛДанныеОЦели  TD,ЛЛТип Ty) {
    return LLVMSizeOfTypeInBits(TD, Ty);
}
/** Computes the storage size of a type in bytes for a target.
    See the method llvm::DataLayout::getTypeStoreSize. */
LLEXPORT unsigned long long ЛЛРазмХранТипа(ЛЛДанныеОЦели TD, ЛЛТип Ty) {
    return LLVMStoreSizeOfType( TD, Ty) ;
}

/** Computes the ABI size of a type in bytes for a target.
    See the method llvm::DataLayout::getTypeAllocSize. */
LLEXPORT unsigned long long ЛЛДИПРазмТипа(ЛЛДанныеОЦели TD, ЛЛТип Ty) {
    return LLVMABISizeOfType(TD, Ty);
}
/** Computes the ABI alignment of a type in bytes for a target.
    See the method llvm::DataLayout::getTypeABISize. */
LLEXPORT unsigned ЛЛДИПРаскладкаТипа(ЛЛДанныеОЦели TD, ЛЛТип Ty) {
    return LLVMABIAlignmentOfType( TD, Ty);
}

/** Computes the call frame alignment of a type in bytes for a target.
    See the method llvm::DataLayout::getTypeABISize. */
LLEXPORT unsigned ЛЛРаскладкаФреймаВызДляТипа(ЛЛДанныеОЦели TD, ЛЛТип Ty) {
    return LLVMCallFrameAlignmentOfType( TD,  Ty);
}
/** Computes the preferred alignment of a type in bytes for a target.
    See the method llvm::DataLayout::getTypeABISize. */
LLEXPORT unsigned ЛЛПредпочтРаскладкаТипа(ЛЛДанныеОЦели TD,ЛЛТип Ty) {
    return LLVMPreferredAlignmentOfType( TD,  Ty);
}

/** Computes the preferred alignment of a global variable in bytes for a target.
    See the method llvm::DataLayout::getPreferredAlignment. */
LLEXPORT unsigned ЛЛПредпочтРаскладкаГлоба(ЛЛДанныеОЦели  TD,
                                        ЛЛЗначение GlobalVar) {
    return LLVMPreferredAlignmentOfGlobal( TD, GlobalVar);
}

/** Computes the structure element that contains the byte offset for a target.
    See the method llvm::StructLayout::getElementContainingOffset. */
LLEXPORT unsigned ЛЛЭлтПоСмещ(ЛЛДанныеОЦели TD, ЛЛТип StructTy,
                             unsigned long long Offset) {
    return LLVMElementAtOffset(TD,  StructTy, Offset);
}
/** Computes the byte offset of the indexed struct element for a target.
    See the method llvm::StructLayout::getElementContainingOffset. */
LLEXPORT unsigned long long ЛЛСМещЭлта(ЛЛДанныеОЦели TD,
                                       ЛЛТип StructTy, unsigned Element) {
    return LLVMOffsetOfElement(TD, StructTy,  Element);
}

/**
 * @}
 */


}

