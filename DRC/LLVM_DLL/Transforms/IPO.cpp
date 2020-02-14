
extern "C" {
#include "../Header.h"

/**
 * @defgroup LLVMCTransformsIPO Interprocedural transformations
 * @ingroup LLVMCTransforms
 *
 * @{
 */

/** See llvm::createArgumentPromotionPass function. */
LLEXPORT void ЛЛДобавьПроходкуПродвиженияАргументов(LLVMPassManagerRef PM){
 LLVMAddArgumentPromotionPass(PM);
}

/** See llvm::createConstantMergePass function. */
LLEXPORT void ЛЛДобавьПроходкуМёрджКонстант(LLVMPassManagerRef PM){
 LLVMAddConstantMergePass(PM);
}

/** See llvm::createCalledValuePropagationPass function. */
LLEXPORT void ЛЛДобавьПроходкуПропагацииВызванногоЗначения(LLVMPassManagerRef PM){
 LLVMAddCalledValuePropagationPass(PM);
}
/** See llvm::createDeadArgEliminationPass function. */
LLEXPORT void ЛЛДобавьПроходкуИскорененияНенужныхАргов(LLVMPassManagerRef PM){
 LLVMAddDeadArgEliminationPass(PM);
}

/** See llvm::createFunctionAttrsPass function. */
LLEXPORT void ЛЛДобавьПроходкуАтрибутовФункций(LLVMPassManagerRef PM){
 LLVMAddFunctionAttrsPass(PM);
}

/** See llvm::createFunctionInliningPass function. */
LLEXPORT void ЛЛДобавьПроходкуИнлайнингаФункций(LLVMPassManagerRef PM){
 LLVMAddFunctionInliningPass(PM);
}

/** See llvm::createAlwaysInlinerPass function. */
LLEXPORT void ЛЛДобавьПроходкуИнлайнВсегда(LLVMPassManagerRef PM){
 LLVMAddAlwaysInlinerPass(PM);
}

/** See llvm::createGlobalDCEPass function. */
LLEXPORT void ЛЛДобавьПроходкуГлобДЦЕ(LLVMPassManagerRef PM){
 LLVMAddGlobalDCEPass(PM);
}

/** See llvm::createGlobalOptimizerPass function. */
LLEXPORT void ЛЛДобавьПроходкуГлобОптимизатора(LLVMPassManagerRef PM){
 LLVMAddGlobalOptimizerPass(PM);
}

/** See llvm::createIPConstantPropagationPass function. */
LLEXPORT void ЛЛДобавьПроходкуПропагацииИПКонстант(LLVMPassManagerRef PM){
 LLVMAddIPConstantPropagationPass(PM);
}
/** See llvm::createPruneEHPass function. */
LLEXPORT void ЛЛДобавьПроходкуПрюнЕХ(LLVMPassManagerRef PM){
 LLVMAddPruneEHPass(PM);
}

/** See llvm::createIPSCCPPass function. */
LLEXPORT void ЛЛДобавьПроходкуИПСЦЦ(LLVMPassManagerRef PM){
 LLVMAddIPSCCPPass(PM);
}

/** See llvm::createInternalizePass function. */
LLEXPORT void ЛЛДобавьПроходкуИнтернализации(LLVMPassManagerRef PM, unsigned AllButMain){
 LLVMAddInternalizePass(PM, AllButMain);
}
/** See llvm::createStripDeadPrototypesPass function. */
LLEXPORT void ЛЛДобавьПроходкуОчисткиНенужныхПрототипов(LLVMPassManagerRef PM){
 LLVMAddStripDeadPrototypesPass(PM);
}
/** See llvm::createStripSymbolsPass function. */
LLEXPORT void ЛЛДобавьПроходкуОчисткиСимволов(LLVMPassManagerRef PM){
 LLVMAddStripSymbolsPass(PM);
}

/**
 * @}
 */

}

