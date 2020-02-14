#pragma once
#define LLEXPORT __declspec(dllexport)

#ifdef __cplusplus
#undef __cplusplus
#endif
#define _WCHAR_T
typedef bool _Bool;

typedef void проц;
typedef void* ук;

typedef bool бул;

typedef  signed char байт;   ///int8_t
typedef  unsigned char ббайт;  ///uint8_t

typedef  short крат;  ///int16_t
typedef  unsigned short бкрат; ///uint16_t

typedef  int цел;  ///int32_t
typedef  unsigned int бцел; ///uint32_t

typedef  long long дол;   ///int64_t
typedef  unsigned long long бдол;  ///uint64_t

typedef  size_t т_мера;

typedef const char* ткст0;

#include <llvm-c/Types.h>
#include <llvm-c/Support.h>
#include <llvm-c/DisassemblerTypes.h>
#include <llvm-c/Disassembler.h>
#include <llvm-c/Error.h>
#include <llvm-c/ErrorHandling.h>
#include <llvm-c/Target.h>
#include <llvm-c/TargetMachine.h>
#include <llvm-c/Core.h>
#include <llvm-c/DebugInfo.h>
#include <llvm-c/Analysis.h>
#include <llvm-c/Initialization.h>
#include <llvm-c/BitReader.h>
#include <llvm-c/BitWriter.h>
#include <llvm-c/IRReader.h>
#include <llvm-c/Linker.h>
#include <llvm-c/Comdat.h>
#include <llvm-c/ExecutionEngine.h>
#include <llvm-c/Object.h>
#include <llvm-c/LinkTimeOptimizer.h>
#include <llvm-c/OptRemarks.h>
#include <llvm-c/OrcBindings.h>
#include <llvm-c/Remarks.h>
#include <llvm-c/Transforms/Scalar.h>
#include <llvm-c/Transforms/Utils.h>
#include <llvm-c/Transforms/Vectorize.h>
#include <llvm-c/Transforms/PassManagerBuilder.h>
#include <llvm-c/Transforms/IPO.h>
#include <llvm-c/Transforms/InstCombine.h>
#include <llvm-c/Transforms/Coroutines.h>
#include <llvm-c/Transforms/AggressiveInstCombine.h>



    typedef LLVMBool ЛЛБул;
    typedef LLVMMemoryBufferRef ЛЛБуферПамяти;
    typedef LLVMContextRef ЛЛКонтекст;
    typedef LLVMModuleRef ЛЛМодуль;
    typedef LLVMTypeRef ЛЛТип;
    typedef LLVMValueRef ЛЛЗначение;
    typedef LLVMBasicBlockRef ЛЛБазовыйБлок;
    typedef LLVMMetadataRef ЛЛМетаданные;
    typedef LLVMNamedMDNodeRef ЛЛИменованыйУзелМД;
    typedef LLVMValueMetadataEntry ЛЛЗаписьМетаданныхЗначения;
    typedef LLVMBuilderRef ЛЛПостроитель;
    typedef LLVMDIBuilderRef ЛЛПостроительОИ;
    typedef LLVMModuleProviderRef ЛЛМодульПровайдер;
    typedef LLVMPassManagerRef ЛЛМенеджерПроходок;
    typedef LLVMPassRegistryRef ЛЛРеестрПроходок;
    typedef LLVMUseRef ЛЛИспользование;
    typedef LLVMAttributeRef ЛЛАтрибут;
    typedef LLVMDiagnosticInfoRef ЛЛИнфоДиагностики;
    typedef LLVMComdatRef ЛЛКомдат;
    typedef LLVMModuleFlagEntry ЛЛЗаписьФлагаМодуля;
    typedef LLVMJITEventListenerRef ЛЛДатчикСобытийДжит;
    typedef LLVMBinaryRef ЛЛБинарник;

    typedef LLVMErrorRef ЛЛОшибка;
    typedef LLVMErrorTypeId ЛЛИдТипаОшибки;

    typedef LLVMTargetDataRef ЛЛДанныеОЦели;
    typedef LLVMTargetLibraryInfoRef ЛЛИнфоЦелевойБиблиотеки;
    typedef LLVMDisasmContextRef ЛЛКонтекстДизасма;

    typedef LLVMGenericValueRef ЛЛГенерноеЗначение;
    typedef struct LLVMOpaqueExecutionEngine* ЛЛДвижокВыполнения;
    typedef struct LLVMOpaqueMCJITMemoryManager* ЛЛМенеджерПамятиМЦДжИТ;
    typedef struct LLVMMCJITCompilerOptions* ЛЛОпцииКомпиляцииМЦДжИТ;

    typedef struct LLVMOpaqueSectionIterator *ЛЛИтераторСекций;
    typedef struct LLVMOpaqueSymbolIterator *ЛЛСимвИтератор;
    typedef struct LLVMOpaqueRelocationIterator *ЛЛИтераторРелокаций;

    typedef struct LLVMRemarkOpaqueParser *ЛЛПарсерРемарок;
    typedef struct LLVMRemarkOpaqueEntry *ЛЛЗаписьРемарки;
    typedef struct LLVMRemarkOpaqueArg *ЛЛАргРемарки;

    typedef struct LLVMOpaquePassManagerBuilder *ЛЛПостроительМенеджеровПроходок;

    typedef struct LLVMOpaqueTargetMachine *ЛЛЦелеваяМашина;
    typedef struct LLVMTarget *ЛЛЦель;

    /**
 * DebugLoc containing File, Line and Column.
 *
 * \since REMARKS_API_VERSION=0
 */
typedef struct LLVMRemarkOpaqueDebugLoc *ЛЛОтладЛокРемарки;

    /** Deprecated: Use ЛЛБинарник instead. */
typedef struct LLVMOpaqueObjectFile *ЛЛФайлОбъекта;

typedef struct LLVMOrcOpaqueJITStack *LLVMOrcJITStackRef;
typedef uint64_t LLVMOrcModuleHandle;
typedef uint64_t LLVMOrcTargetAddress;
typedef uint64_t (*LLVMOrcSymbolResolverFn)(const char *Name, void *LookupCtx);
typedef uint64_t (*LLVMOrcLazyCompileCallbackFn)(LLVMOrcJITStackRef JITStack,
                                                 void *CallbackCtx);

    /*
    ЛЛОпцииКомпиляцииМЦДжИТ {
        unsigned OptLevel;
        LLVMCodeModel CodeModel;
        ЛЛБул NoFramePointerElim;
        ЛЛБул EnableFastISel;
        ЛЛМенеджерПамятиМЦДжИТ MCJMM;
    };



typedef struct {
  const char *Str;
  uint32_t Len;
} LLVMOptRemarkStringRef;

typedef struct {
  // File:
  LLVMOptRemarkStringRef SourceFile;
  // Line:
  uint32_t SourceLineNumber;
  // Column:
  uint32_t SourceColumnNumber;
} LLVMOptRemarkDebugLoc;

typedef struct {
  // e.g. "Callee"
  LLVMOptRemarkStringRef Key;
  // e.g. "malloc"
  LLVMOptRemarkStringRef Value;

  // "DebugLoc": Optional
  LLVMOptRemarkDebugLoc DebugLoc;
} LLVMOptRemarkArg;

typedef struct {
  // e.g. !Missed, !Passed
  LLVMOptRemarkStringRef RemarkType;
  // "Pass": Required
  LLVMOptRemarkStringRef PassName;
  // "Name": Required
  LLVMOptRemarkStringRef RemarkName;
  // "Function": Required
  LLVMOptRemarkStringRef FunctionName;

  // "DebugLoc": Optional
  LLVMOptRemarkDebugLoc DebugLoc;
  // "Hotness": Optional
  uint32_t Hotness;
  // "Args": Optional. It is an array of `num_args` elements.
  uint32_t NumArgs;
  LLVMOptRemarkArg *Args;
} LLVMOptRemarkEntry;
    */
typedef struct LLVMOptRemarkOpaqueParser *ЛЛПарсерОптРемарок;

typedef struct LLVMRemarkOpaqueString *ЛЛТкстРемарки;

////////////////////////////
//Функции обратного вызова//////
///////////////////////////////////

	// LLVMFatalErrorHandler
    typedef void (*ЛЛОбработчикФатальнойОшибки)(ткст0 причина);

    typedef void (*ЛЛОбработчикДиагностики)(ЛЛИнфоДиагностики, ук);

    typedef void (*ЛЛОбрвызовЖни)(ЛЛКонтекст, ук);

    typedef int (*ЛЛОбрвызОпИнфо)(ук инфОДиз, бдол ПК,
        бдол смещ, бдол разм, цел типТэга, ук буфТэгов);

    typedef ткст0 (*ЛЛОбрвызПоискСимвола)(ук инфОДиз, бдол значСсыл, 
        бдол* типСсыл, бдол сссылПК, ткст0* имяСсыл);
    
    //LLVMMemoryManagerAllocateCodeSectionCallback
    typedef ббайт* (*ЛЛОбрвызМенеджерПамРазместиСекциюКода)(
        ук опак, uintptr_t разм, бцел расклад, бцел идСекц,
        ткст0 имяСекц);

    //LLVMMemoryManagerAllocateDataSectionCallback
    typedef ббайт* (*ЛЛОбрвызМенеджерПамРазместиСекциюДанных)(
        ук опак, uintptr_t разм, бцел расклад, бцел идСекц,
        ткст0 имяСекц, ЛЛБул толькоЧтен_ли);

    //LLVMMemoryManagerFinalizeMemoryCallback
    typedef ЛЛБул(*ЛЛОбрвызМенеджерПамФинализуйПам)(ук опак, char** ошСооб);

    //LLVMMemoryManagerDestroyCallback
    typedef проц(*ЛЛОбрвызМенеджерПамРазрушь)(ук опак);
    


