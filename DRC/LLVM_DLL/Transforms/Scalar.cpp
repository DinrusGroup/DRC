
extern "C" {
#include "../Header.h"
#include <llvm-c/Transforms/Scalar.h>

/**
 * @defgroup LLVMCTransformsScalar Scalar transformations
 * @ingroup LLVMCTransforms
 *
 * @{
 */

/** See llvm::createAggressiveDCEPass function. */
LLEXPORT void ЛЛДобавьПроходкуАгрессивДЦЕ(ЛЛМенеджерПроходок PM){
  LLVMAddAggressiveDCEPass(PM);
}

/** See llvm::createBitTrackingDCEPass function. */
LLEXPORT void ЛЛДобавьПроходкуБитТрэкингДЦЕ(ЛЛМенеджерПроходок PM){
  LLVMAddBitTrackingDCEPass(PM);
}

/** See llvm::createAlignmentFromAssumptionsPass function. */
LLEXPORT void ЛЛДобавьПроходкуРаскладкаИзАссумпций(ЛЛМенеджерПроходок PM){
  LLVMAddAlignmentFromAssumptionsPass(PM);
}

/** See llvm::createCFGSimplificationPass function. */
LLEXPORT void ЛЛДобавьПроходкуКФГУпрощения(ЛЛМенеджерПроходок PM){
  LLVMAddCFGSimplificationPass(PM);
}

/** See llvm::createDeadStoreEliminationPass function. */
LLEXPORT void ЛЛДобавьПроходкуУдаленияМёртвыхХранилищ(ЛЛМенеджерПроходок PM){
  LLVMAddDeadStoreEliminationPass(PM);
}
/** See llvm::createScalarizerPass function. */
LLEXPORT void ЛЛДобавьПроходкуСкаляризатора(ЛЛМенеджерПроходок PM){
  LLVMAddScalarizerPass(PM);
}

/** See llvm::createMergedLoadStoreMotionPass function. */
LLEXPORT void ЛЛДобавьПроходкуМёрдждЛоудСторМоушн(ЛЛМенеджерПроходок PM){
  LLVMAddMergedLoadStoreMotionPass(PM);
}

/** See llvm::createGVNPass function. */
LLEXPORT void ЛЛДобавьПроходкуГВН(ЛЛМенеджерПроходок PM){
  LLVMAddGVNPass(PM);
}

/** See llvm::createGVNPass function. */
LLEXPORT void ЛЛДобавьПроходкуНовГВН(ЛЛМенеджерПроходок PM){
  LLVMAddNewGVNPass(PM);
}

/** See llvm::createIndVarSimplifyPass function. */
LLEXPORT void ЛЛДобавьПроходкуИндВарУпрощения(ЛЛМенеджерПроходок PM){
  LLVMAddIndVarSimplifyPass(PM);
}

/** See llvm::createInstructionCombiningPass function. */
/*
LLEXPORT void LLAddInstructionCombiningPass(ЛЛМенеджерПроходок PM){
  LLVMAddInstructionCombiningPass(PM);
}
*/
/** See llvm::createJumpThreadingPass function. */
LLEXPORT void ЛЛДобавьПроходкуДжампПоточности(ЛЛМенеджерПроходок PM){
  LLVMAddJumpThreadingPass(PM);
}

/** See llvm::createLICMPass function. */
LLEXPORT void ЛЛДобавьПроходкуЛИЦМ(ЛЛМенеджерПроходок PM){
  LLVMAddLICMPass(PM);
}

/** See llvm::createLoopDeletionPass function. */
LLEXPORT void ЛЛДобавьПроходкуЛупДелешн(ЛЛМенеджерПроходок PM){
  LLVMAddLoopDeletionPass(PM);
}

/** See llvm::createLoopIdiomPass function */
LLEXPORT void ЛЛДобавьПроходкуЛупИдиом(ЛЛМенеджерПроходок PM){
  LLVMAddLoopIdiomPass(PM);
}

/** See llvm::createLoopRotatePass function. */
LLEXPORT void ЛЛДобавьПроходкуЛупРотейт(ЛЛМенеджерПроходок PM){
  LLVMAddLoopRotatePass(PM);
}

/** See llvm::createLoopRerollPass function. */
LLEXPORT void ЛЛДобавьПроходкуЛупРеролл(ЛЛМенеджерПроходок PM){
  LLVMAddLoopRerollPass(PM);
}

/** See llvm::createLoopUnrollPass function. */
LLEXPORT void ЛЛДобавьПроходкуЛупАнролл(ЛЛМенеджерПроходок PM){
  LLVMAddLoopUnrollPass(PM);
}

/** See llvm::createLoopUnrollAndJamPass function. */
LLEXPORT void ЛЛДобавьПроходкуЛупАнроллЭндДжем(ЛЛМенеджерПроходок PM){
  LLVMAddLoopUnrollAndJamPass(PM);
}

/** See llvm::createLoopUnswitchPass function. */
LLEXPORT void ЛЛДобавьПроходкуЛупАнСвитч(ЛЛМенеджерПроходок PM){
  LLVMAddLoopUnswitchPass(PM);
}

/** See llvm::createLowerAtomicPass function. */
LLEXPORT void ЛЛДобавьПроходкуЛоверАтомик(ЛЛМенеджерПроходок PM){
  LLVMAddLowerAtomicPass(PM);
}

/** See llvm::createMemCpyOptPass function. */
LLEXPORT void ЛЛДобавьПроходкуКопирПамОпц(ЛЛМенеджерПроходок PM){
  LLVMAddMemCpyOptPass(PM);
}

/** See llvm::createPartiallyInlineLibCallsPass function. */
LLEXPORT void ЛЛДобавьПроходкуЧастичнИнлайнВызБиб(ЛЛМенеджерПроходок PM){
  LLVMAddPartiallyInlineLibCallsPass(PM);
}

/** See llvm::createReassociatePass function. */
LLEXPORT void ЛЛДобавьПроходкуРеассоциации(ЛЛМенеджерПроходок PM){
  LLVMAddReassociatePass(PM);
}

/** See llvm::createSCCPPass function. */
LLEXPORT void ЛЛДобавьПроходкуСЦЦП(ЛЛМенеджерПроходок PM){
  LLVMAddSCCPPass(PM);
}

/** See llvm::createSROAPass function. */
LLEXPORT void ЛЛДобавьПроходкуСкалярРеплАгрегаты(ЛЛМенеджерПроходок PM){
  LLVMAddScalarReplAggregatesPass(PM);
}

/** See llvm::createSROAPass function. */
LLEXPORT void ЛЛДобавьССАПроходкиСкалярРеплАгрегаты(ЛЛМенеджерПроходок PM){
  LLVMAddScalarReplAggregatesPassSSA(PM);
}

/** See llvm::createSROAPass function. */
LLEXPORT void ЛЛДобавьПроходкуСкалярРеплАгрегатыСПорогом(ЛЛМенеджерПроходок PM,
                                                  int Threshold){
  LLVMAddScalarReplAggregatesPassWithThreshold(PM, Threshold);
}

/** See llvm::createSimplifyLibCallsPass function. */
LLEXPORT void ЛЛДобавьПроходкуУпроститьВызовыБиб(ЛЛМенеджерПроходок PM){
  LLVMAddSimplifyLibCallsPass(PM);
}

/** See llvm::createTailCallEliminationPass function. */
LLEXPORT void ЛЛДобавьПроходкуИскоренениеТейлВызовов(ЛЛМенеджерПроходок PM){
  LLVMAddTailCallEliminationPass(PM);
}

/** See llvm::createConstantPropagationPass function. */
LLEXPORT void ЛЛДобавьПроходкуПропагацияКонстант(ЛЛМенеджерПроходок PM){
  LLVMAddConstantPropagationPass(PM);
}

/** See llvm::demotePromoteMemoryToRegisterPass function. */
LLEXPORT void ЛЛДобавьПроходкуДемотПамВРегистр(ЛЛМенеджерПроходок PM){
  LLVMAddDemoteMemoryToRegisterPass(PM);
}

/** See llvm::createVerifierPass function. */
LLEXPORT void ЛЛДобавьПроходкуВерификатора(ЛЛМенеджерПроходок PM){
  LLVMAddVerifierPass(PM);
}

/** See llvm::createCorrelatedValuePropagationPass function */
LLEXPORT void ЛЛДобавьПроходкуПропагацииКоррелирЗначений(ЛЛМенеджерПроходок PM){
  LLVMAddCorrelatedValuePropagationPass(PM);
}

/** See llvm::createEarlyCSEPass function */
LLEXPORT void ЛЛДобавьПроходкуЁлиЦСЕ(ЛЛМенеджерПроходок PM){
  LLVMAddEarlyCSEPass(PM);
}

/** See llvm::createEarlyCSEPass function */
LLEXPORT void ЛЛДобавьПроходкуЁлиЦСЕПамССА(ЛЛМенеджерПроходок PM){
  LLVMAddEarlyCSEMemSSAPass(PM);
}

/** See llvm::createLowerExpectIntrinsicPass function */
LLEXPORT void ЛЛДобавьПроходкуЛоверЭкпектИнтринсик(ЛЛМенеджерПроходок PM){
  LLVMAddLowerExpectIntrinsicPass(PM);
}

/** See llvm::createTypeBasedAliasAnalysisPass function */
LLEXPORT void ЛЛДобавьПроходкуАнализАлиасаНаОвеТипа(ЛЛМенеджерПроходок PM){
  LLVMAddTypeBasedAliasAnalysisPass(PM);
}

/** See llvm::createScopedNoAliasAAPass function */
LLEXPORT void ЛЛДобавьПроходкуМасштбнБезАлиасАА(ЛЛМенеджерПроходок PM){
  LLVMAddScopedNoAliasAAPass(PM);
}

/** See llvm::createBasicAliasAnalysisPass function */
LLEXPORT void ЛЛДобавьПроходкуБазовыйАнализАлиаса(ЛЛМенеджерПроходок PM){
  LLVMAddBasicAliasAnalysisPass(PM);
}

/** See llvm::createUnifyFunctionExitNodesPass function */
LLEXPORT void ЛЛДобавьПроходкуУнификацииУзловВыходаИзФункц(ЛЛМенеджерПроходок PM){
  LLVMAddUnifyFunctionExitNodesPass(PM);
}

/**
 * @}
 */


}

