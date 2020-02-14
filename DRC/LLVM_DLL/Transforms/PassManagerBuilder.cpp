extern "C" {
#include "../Header.h"

/**
 * @defgroup LLVMCTransformsPassManagerBuilder Pass manager builder
 * @ingroup LLVMCTransforms
 *
 * @{
 */

/** See llvm::PassManagerBuilder. */
LLEXPORT ЛЛПостроительМенеджеровПроходок ЛЛПМП_Создай(void){
return LLVMPassManagerBuilderCreate();
}
LLEXPORT void ЛЛПМП_Вымести(ЛЛПостроительМенеджеровПроходок PMB){
LLVMPassManagerBuilderDispose(PMB);
}

/** See llvm::PassManagerBuilder::OptLevel. */
LLEXPORT void
ЛЛПМП_УстановиУровеньОпц(ЛЛПостроительМенеджеровПроходок PMB,
                                  unsigned OptLevel){
LLVMPassManagerBuilderSetOptLevel( PMB, OptLevel);
}

/** See llvm::PassManagerBuilder::SizeLevel. */
LLEXPORT void
ЛЛПМП_УстановиУровеньРазм(ЛЛПостроительМенеджеровПроходок PMB,
                                   unsigned SizeLevel){
LLVMPassManagerBuilderSetSizeLevel(PMB, SizeLevel);
}

/** See llvm::PassManagerBuilder::DisableUnitAtATime. */
LLEXPORT void
ЛЛПМП_УстановиОтклЮнитВНВремя(ЛЛПостроительМенеджеровПроходок PMB,
                                            ЛЛБул Value){
LLVMPassManagerBuilderSetDisableUnitAtATime( PMB, Value);
}

/** See llvm::PassManagerBuilder::DisableUnrollLoops. */
LLEXPORT void
ЛЛПМП_УстОтклРазмоткуЦиклов(ЛЛПостроительМенеджеровПроходок PMB,
                                            ЛЛБул Value){
LLVMPassManagerBuilderSetDisableUnrollLoops( PMB, Value);
}
/** See llvm::PassManagerBuilder::DisableSimplifyLibCalls */
LLEXPORT void
ЛЛПМП_УстОтклУпроститьВызовБиб(ЛЛПостроительМенеджеровПроходок PMB,
                                                 ЛЛБул Value){
LLVMPassManagerBuilderSetDisableSimplifyLibCalls( PMB, Value);
}
/** See llvm::PassManagerBuilder::Inliner. */
LLEXPORT void
ЛЛПМП_ИспользуйИнлайнерСПорогом(ЛЛПостроительМенеджеровПроходок PMB,
                                              unsigned Threshold){
LLVMPassManagerBuilderUseInlinerWithThreshold( PMB, Threshold);
}

/** See llvm::PassManagerBuilder::populateFunctionPassManager. */
LLEXPORT void
ЛЛПМП_НаполниМенеджерПроходокФункций(ЛЛПостроительМенеджеровПроходок PMB,
                                                  ЛЛМенеджерПроходок PM){
LLVMPassManagerBuilderPopulateFunctionPassManager( PMB, PM);
}

/** See llvm::PassManagerBuilder::populateModulePassManager. */
LLEXPORT void
ЛЛПМП_НаполниМенеджерПроходокМодулей(ЛЛПостроительМенеджеровПроходок PMB,
                                                ЛЛМенеджерПроходок PM){
  LLVMPassManagerBuilderPopulateModulePassManager( PMB, PM);
}
/** See llvm::PassManagerBuilder::populateLTOPassManager. */
LLEXPORT void ЛЛПМП_НаполниМенеджерПроходокОВК(ЛЛПостроительМенеджеровПроходок PMB,
                                                  ЛЛМенеджерПроходок PM,
                                                  ЛЛБул Internalize,
                                                  ЛЛБул RunInliner){
  LLVMPassManagerBuilderPopulateLTOPassManager(PMB, PM, Internalize, RunInliner);
}
/**
 * @}
 */

}

