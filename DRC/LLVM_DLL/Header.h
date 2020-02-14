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
/*
#define LLVMErrorSuccess 0

typedef enum {
  // Terminator Instructions 
LLVMRet = 1,
LLVMBr = 2,
LLVMSwitch = 3,
LLVMIndirectBr = 4,
LLVMInvoke = 5,
// removed 6 due to API changes 
LLVMUnreachable = 7,
LLVMCallBr = 67,

// Standard Unary Operators 
LLVMFNeg = 66,

// Standard Binary Operators 
LLVMAdd = 8,
LLVMFAdd = 9,
LLVMSub = 10,
LLVMFSub = 11,
LLVMMul = 12,
LLVMFMul = 13,
LLVMUDiv = 14,
LLVMSDiv = 15,
LLVMFDiv = 16,
LLVMURem = 17,
LLVMSRem = 18,
LLVMFRem = 19,

// Logical Operators 
LLVMShl = 20,
LLVMLShr = 21,
LLVMAShr = 22,
LLVMAnd = 23,
LLVMOr = 24,
LLVMXor = 25,

// Memory Operators 
LLVMAlloca = 26,
LLVMLoad = 27,
LLVMStore = 28,
LLVMGetElementPtr = 29,

// Cast Operators
LLVMTrunc = 30,
LLVMZExt = 31,
LLVMSExt = 32,
LLVMFPToUI = 33,
LLVMFPToSI = 34,
LLVMUIToFP = 35,
LLVMSIToFP = 36,
LLVMFPTrunc = 37,
LLVMFPExt = 38,
LLVMPtrToInt = 39,
LLVMIntToPtr = 40,
LLVMBitCast = 41,
LLVMAddrSpaceCast = 60,

// Other Operators 
LLVMICmp = 42,
LLVMFCmp = 43,
LLVMPHI = 44,
LLVMCall = 45,
LLVMSelect = 46,
LLVMUserOp1 = 47,
LLVMUserOp2 = 48,
LLVMVAArg = 49,
LLVMExtractElement = 50,
LLVMInsertElement = 51,
LLVMShuffleVector = 52,
LLVMExtractValue = 53,
LLVMInsertValue = 54,

// Atomic operators 
LLVMFence = 55,
LLVMAtomicCmpXchg = 56,
LLVMAtomicRMW = 57,

// Exception Handling Operators
LLVMResume = 58,
LLVMLandingPad = 59,
LLVMCleanupRet = 61,
LLVMCatchRet = 62,
LLVMCatchPad = 63,
LLVMCleanupPad = 64,
LLVMCatchSwitch = 65
} LLVMOpcode;

typedef enum {
    LLVMVoidTypeKind,        //< type with no size 
    LLVMHalfTypeKind,        //< 16 bit floating point type 
    LLVMFloatTypeKind,       //< 32 bit floating point type 
    LLVMDoubleTypeKind,      //< 64 bit floating point type 
    LLVMX86_FP80TypeKind,    //< 80 bit floating point type (X87) 
    LLVMFP128TypeKind,       //< 128 bit floating point type (112-bit mantissa)
    LLVMPPC_FP128TypeKind,   //< 128 bit floating point type (two 64-bits) 
    LLVMLabelTypeKind,       //< Labels 
    LLVMIntegerTypeKind,     //< Arbitrary bit width integers 
    LLVMFunctionTypeKind,    //< Functions 
    LLVMStructTypeKind,      //< Structures 
    LLVMArrayTypeKind,       //< Arrays
    LLVMPointerTypeKind,     //< Pointers
    LLVMVectorTypeKind,      //< SIMD 'packed' format, or other vector type
    LLVMMetadataTypeKind,    //< Metadata
    LLVMX86_MMXTypeKind,     //< X86 MMX 
    LLVMTokenTypeKind        //< Tokens 
} LLVMTypeKind;

typedef enum {
    LLVMExternalLinkage,    //< Externally visible function
    LLVMAvailableExternallyLinkage,
    LLVMLinkOnceAnyLinkage, //< Keep one copy of function when linking (inline)
    LLVMLinkOnceODRLinkage, //< Same, but only replaced by something
                              equivalent. 
                              LLVMLinkOnceODRAutoHideLinkage, //< Obsolete 
                              LLVMWeakAnyLinkage,     //< Keep one copy of function when linking (weak) 
                              LLVMWeakODRLinkage,     //< Same, but only replaced by something
                                                        equivalent. 
                                                        LLVMAppendingLinkage,   //< Special purpose, only applies to global arrays 
                                                        LLVMInternalLinkage,    //< Rename collisions when linking (static
                                                                                     functions) 
                                                                                     LLVMPrivateLinkage,     //< Like Internal, but omit from symbol table 
                                                                                     LLVMDLLImportLinkage,   //< Obsolete 
                                                                                     LLVMDLLExportLinkage,   //< Obsolete 
                                                                                     LLVMExternalWeakLinkage,//< ExternalWeak linkage description 
                                                                                     LLVMGhostLinkage,       //< Obsolete 
                                                                                     LLVMCommonLinkage,      //< Tentative definitions 
                                                                                     LLVMLinkerPrivateLinkage, //< Like Private, but linker removes. 
                                                                                     LLVMLinkerPrivateWeakLinkage //< Like LinkerPrivate, but is weak. 
} LLVMLinkage;

typedef enum {
    LLVMDefaultVisibility,  //< The GV is visible 
    LLVMHiddenVisibility,   //< The GV is hidden 
    LLVMProtectedVisibility //< The GV is protected 
} LLVMVisibility;

typedef enum {
    LLVMNoUnnamedAddr,    //< Address of the GV is significant. 
    LLVMLocalUnnamedAddr, //< Address of the GV is locally insignificant. 
    LLVMGlobalUnnamedAddr //< Address of the GV is globally insignificant. 
} LLVMUnnamedAddr;

typedef enum {
    LLVMDefaultStorageClass = 0,
    LLVMDLLImportStorageClass = 1, //< Function to be imported from DLL. 
    LLVMDLLExportStorageClass = 2  //< Function to be accessible from DLL. 
} LLVMDLLStorageClass;

typedef enum {
    LLVMCCallConv = 0,
    LLVMFastCallConv = 8,
    LLVMColdCallConv = 9,
    LLVMGHCCallConv = 10,
    LLVMHiPECallConv = 11,
    LLVMWebKitJSCallConv = 12,
    LLVMAnyRegCallConv = 13,
    LLVMPreserveMostCallConv = 14,
    LLVMPreserveAllCallConv = 15,
    LLVMSwiftCallConv = 16,
    LLVMCXXFASTTLSCallConv = 17,
    LLVMX86StdcallCallConv = 64,
    LLVMX86FastcallCallConv = 65,
    LLVMARMAPCSCallConv = 66,
    LLVMARMAAPCSCallConv = 67,
    LLVMARMAAPCSVFPCallConv = 68,
    LLVMMSP430INTRCallConv = 69,
    LLVMX86ThisCallCallConv = 70,
    LLVMPTXKernelCallConv = 71,
    LLVMPTXDeviceCallConv = 72,
    LLVMSPIRFUNCCallConv = 75,
    LLVMSPIRKERNELCallConv = 76,
    LLVMIntelOCLBICallConv = 77,
    LLVMX8664SysVCallConv = 78,
    LLVMWin64CallConv = 79,
    LLVMX86VectorCallCallConv = 80,
    LLVMHHVMCallConv = 81,
    LLVMHHVMCCallConv = 82,
    LLVMX86INTRCallConv = 83,
    LLVMAVRINTRCallConv = 84,
    LLVMAVRSIGNALCallConv = 85,
    LLVMAVRBUILTINCallConv = 86,
    LLVMAMDGPUVSCallConv = 87,
    LLVMAMDGPUGSCallConv = 88,
    LLVMAMDGPUPSCallConv = 89,
    LLVMAMDGPUCSCallConv = 90,
    LLVMAMDGPUKERNELCallConv = 91,
    LLVMX86RegCallCallConv = 92,
    LLVMAMDGPUHSCallConv = 93,
    LLVMMSP430BUILTINCallConv = 94,
    LLVMAMDGPULSCallConv = 95,
    LLVMAMDGPUESCallConv = 96
} LLVMCallConv;

typedef enum {
    LLVMArgumentValueKind,
    LLVMBasicBlockValueKind,
    LLVMMemoryUseValueKind,
    LLVMMemoryDefValueKind,
    LLVMMemoryPhiValueKind,

    LLVMFunctionValueKind,
    LLVMGlobalAliasValueKind,
    LLVMGlobalIFuncValueKind,
    LLVMGlobalVariableValueKind,
    LLVMBlockAddressValueKind,
    LLVMConstantExprValueKind,
    LLVMConstantArrayValueKind,
    LLVMConstantStructValueKind,
    LLVMConstantVectorValueKind,

    LLVMUndefValueValueKind,
    LLVMConstantAggregateZeroValueKind,
    LLVMConstantDataArrayValueKind,
    LLVMConstantDataVectorValueKind,
    LLVMConstantIntValueKind,
    LLVMConstantFPValueKind,
    LLVMConstantPointerNullValueKind,
    LLVMConstantTokenNoneValueKind,

    LLVMMetadataAsValueValueKind,
    LLVMInlineAsmValueKind,

    LLVMInstructionValueKind,
} LLVMValueKind;

typedef enum {
    LLVMIntEQ = 32, //< equal 
    LLVMIntNE,      //< not equal 
    LLVMIntUGT,     //< unsigned greater than 
    LLVMIntUGE,     //< unsigned greater or equal 
    LLVMIntULT,     //< unsigned less than 
    LLVMIntULE,     //< unsigned less or equal 
    LLVMIntSGT,     //< signed greater than 
    LLVMIntSGE,     //< signed greater or equal 
    LLVMIntSLT,     //< signed less than 
    LLVMIntSLE      //< signed less or equal 
} LLVMIntPredicate;

typedef enum {
    LLVMRealPredicateFalse, //< Always false (always folded) 
    LLVMRealOEQ,            //< True if ordered and equal 
    LLVMRealOGT,            //< True if ordered and greater than 
    LLVMRealOGE,            //< True if ordered and greater than or equal 
    LLVMRealOLT,            //< True if ordered and less than 
    LLVMRealOLE,            //< True if ordered and less than or equal 
    LLVMRealONE,            //< True if ordered and operands are unequal 
    LLVMRealORD,            //< True if ordered (no nans) 
    LLVMRealUNO,            //< True if unordered: isnan(X) | isnan(Y) 
    LLVMRealUEQ,            //< True if unordered or equal 
    LLVMRealUGT,            //< True if unordered or greater than 
    LLVMRealUGE,            //< True if unordered, greater than, or equal 
    LLVMRealULT,            //< True if unordered or less than 
    LLVMRealULE,            //< True if unordered, less than, or equal 
    LLVMRealUNE,            //< True if unordered or not equal 
    LLVMRealPredicateTrue   //< Always true (always folded) 
} LLVMRealPredicate;

typedef enum {
    LLVMLandingPadCatch,    //< A catch clause   
    LLVMLandingPadFilter    //< A filter clause  
} LLVMLandingPadClauseTy;

typedef enum {
    LLVMNotThreadLocal = 0,
    LLVMGeneralDynamicTLSModel,
    LLVMLocalDynamicTLSModel,
    LLVMInitialExecTLSModel,
    LLVMLocalExecTLSModel
} LLVMThreadLocalMode;

typedef enum {
    LLVMAtomicOrderingNotAtomic = 0, //< A load or store which is not atomic 
    LLVMAtomicOrderingUnordered = 1, //< Lowest level of atomicity, guarantees
                                       somewhat sane results, lock free. 
                                       LLVMAtomicOrderingMonotonic = 2, //< guarantees that if you take all the
                                                                          operations affecting a specific address,
                                                                          a consistent ordering exists 
                                                                          LLVMAtomicOrderingAcquire = 4, //< Acquire provides a barrier of the sort
                                                                                                           necessary to acquire a lock to access other
                                                                                                           memory with normal loads and stores. 
                                                                                                           LLVMAtomicOrderingRelease = 5, //< Release is similar to Acquire, but with
                                                                                                                                            a barrier of the sort necessary to release
                                                                                                                                            a lock. 
                                                                                                                                            LLVMAtomicOrderingAcquireRelease = 6, //< provides both an Acquire and a
                                                                                                                                                                                    Release barrier (for fences and
                                                                                                                                                                                    operations which both read and write
                                                                                                                                                                                     memory). 
                                                                                                                                                                                     LLVMAtomicOrderingSequentiallyConsistent = 7 //< provides Acquire semantics
                                                                                                                                                                                                                                    for loads and Release
                                                                                                                                                                                                                                    semantics for stores.
                                                                                                                                                                                                                                    Additionally, it guarantees
                                                                                                                                                                                                                                    that a total ordering exists
                                                                                                                                                                                                                                    between all
                                                                                                                                                                                                                                    SequentiallyConsistent
                                                                                                                                                                                                                                    operations. 
} LLVMAtomicOrdering;

typedef enum {
    LLVMAtomicRMWBinOpXchg, //< Set the new value and return the one old 
    LLVMAtomicRMWBinOpAdd, //< Add a value and return the old one 
    LLVMAtomicRMWBinOpSub, //< Subtract a value and return the old one 
    LLVMAtomicRMWBinOpAnd, //< And a value and return the old one 
    LLVMAtomicRMWBinOpNand, //< Not-And a value and return the old one 
    LLVMAtomicRMWBinOpOr, //< OR a value and return the old one 
    LLVMAtomicRMWBinOpXor, //< Xor a value and return the old one 
    LLVMAtomicRMWBinOpMax, //< Sets the value if it's greater than the
                             original using a signed comparison and return
                             the old one 
                             LLVMAtomicRMWBinOpMin, //< Sets the value if it's Smaller than the
                                                      original using a signed comparison and return
                                                      the old one 
                                                      LLVMAtomicRMWBinOpUMax, //< Sets the value if it's greater than the
                                                                               original using an unsigned comparison and return
                                                                               the old one 
                                                                               LLVMAtomicRMWBinOpUMin //< Sets the value if it's greater than the
                                                                                                        original using an unsigned comparison  and return
                                                                                                        the old one 
} LLVMAtomicRMWBinOp;

typedef enum {
    LLVMDSError,
    LLVMDSWarning,
    LLVMDSRemark,
    LLVMDSNote
} LLVMDiagnosticSeverity;

typedef enum {
    LLVMInlineAsmDialectATT,
    LLVMInlineAsmDialectIntel
} LLVMInlineAsmDialect;

typedef enum {
  
    LLVMModuleFlagBehaviorError,
    LLVMModuleFlagBehaviorWarning,
    LLVMModuleFlagBehaviorRequire,
    LLVMModuleFlagBehaviorOverride,
    LLVMModuleFlagBehaviorAppendUnique,
} LLVMModuleFlagBehavior;

enum {
    LLVMAttributeReturnIndex = 0U,
    // ISO C restricts enumerator values to range of 'int'
    // (4294967295 is too large)
    // LLVMAttributeFunctionIndex = ~0U,
    LLVMAttributeFunctionIndex = -1,
};

typedef unsigned LLVMAttributeIndex;
*/
    typedef цел ЛЛБул;
    typedef struct LLVMOpaqueMemoryBuffer* ЛЛБуферПамяти;
    typedef struct LLVMOpaqueContext* ЛЛКонтекст;
    typedef struct LLVMOpaqueModule* ЛЛМодуль;
    typedef struct LLVMOpaqueType* ЛЛТип;
    typedef struct LLVMOpaqueValue* ЛЛЗначение;
    typedef struct LLVMOpaqueBasicBlock* ЛЛБазовыйБлок;
    typedef struct LLVMOpaqueMetadata* ЛЛМетаданные;
    typedef struct LLVMOpaqueNamedMDNode* ЛЛИменованыйУзелМД;
    typedef struct LLVMOpaqueValueMetadataEntry ЛЛЗаписьМетаданныхЗначения;
    typedef struct LLVMOpaqueBuilder* ЛЛПостроитель;
    typedef struct LLVMOpaqueDIBuilder* ЛЛПостроительОИ;
    typedef struct LLVMOpaqueModuleProvider* ЛЛМодульПровайдер;
    typedef struct LLVMOpaquePassManager* ЛЛМенеджерПроходок;
    typedef struct LLVMOpaquePassRegistry* ЛЛРеестрПроходок;
    typedef struct LLVMOpaqueUse* ЛЛИспользование;
    typedef struct LLVMOpaqueAttributeRef* ЛЛАтрибут;
    typedef struct LLVMOpaqueDiagnosticInfo* ЛЛИнфоДиагностики;
    typedef struct LLVMComdat* ЛЛКомдат;
    typedef struct LLVMOpaqueModuleFlagEntry ЛЛЗаписьФлагаМодуля;
    typedef struct LLVMOpaqueJITEventListener* ЛЛДатчикСобытийДжит;
    typedef struct LLVMOpaqueBinary* ЛЛБинарник;

    typedef struct LLVMOpaqueError* ЛЛОшибка;
    typedef const void* ЛЛИдТипаОшибки;

    typedef struct LLVMOpaqueTargetData* ЛЛДанныеОЦели;
    typedef struct LLVMOpaqueTargetLibraryInfo* ЛЛИнфоЦелевойБиблиотеки;
    typedef void* ЛЛКонтекстДизасма;

    typedef struct LLVMOpaqueGenericValue* ЛЛГенерноеЗначение;
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

typedef struct LLVMRemarkOpaqueDebugLoc *ЛЛОтладЛокРемарки;

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
    


