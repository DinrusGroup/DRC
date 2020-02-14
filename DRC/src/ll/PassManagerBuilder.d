/*===-- llvm-c/Transform/PassManagerBuilder.h - PMB к Interface ---*- к -*-===*\
|*                                                                            *|
|* Part of the LLVM Project, under the Apache License v2.0 with LLVM          *|
|* Exceptions.                                                                *|
|* See https://llvm.org/LICENSE.txt for license information.                  *|
|* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    *|
|*                                                                            *|
|*===----------------------------------------------------------------------===*|
|*                                                                            *|
|* This header declares the к interface to the PassManagerBuilder class.      *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

module ll.PassManagerBuilder;
import ll.Types;

struct LLVMOpaquePassManagerBuilder;
alias LLVMOpaquePassManagerBuilder *ЛЛПостроительМенеджеровПроходок;


extern (C){


/**
 * @defgroup LLVMCTransformsPassManagerBuilder Pass manager построитель
 * @ingroup LLVMCTransforms
 *
 * @{
 */

/** See llvm::PassManagerBuilder. */
ЛЛПостроительМенеджеровПроходок ЛЛПМП_Создай();
проц ЛЛПМП_Вымести(ЛЛПостроительМенеджеровПроходок PMB);

/** See llvm::PassManagerBuilder::OptLevel. */
проц
ЛЛПМП_УстановиУровеньОпц(ЛЛПостроительМенеджеровПроходок PMB,
                                  бцел OptLevel);

/** See llvm::PassManagerBuilder::SizeLevel. */
проц
ЛЛПМП_УстановиУровеньРазм(ЛЛПостроительМенеджеровПроходок PMB,
                                   бцел SizeLevel);

/** See llvm::PassManagerBuilder::DisableUnitAtATime. */
проц
ЛЛПМП_УстановиОтклЮнитВНВремя(ЛЛПостроительМенеджеровПроходок PMB,
                                            ЛЛБул знач);

/** See llvm::PassManagerBuilder::DisableUnrollLoops. */
проц
ЛЛПМП_УстОтклРазмоткуЦиклов(ЛЛПостроительМенеджеровПроходок PMB,
                                            ЛЛБул знач);

/** See llvm::PassManagerBuilder::DisableSimplifyLibCalls */
проц
ЛЛПМП_УстОтклУпроститьВызовБиб(ЛЛПостроительМенеджеровПроходок PMB,
                                                 ЛЛБул знач);

/** See llvm::PassManagerBuilder::Inliner. */
проц
ЛЛПМП_ИспользуйИнлайнерСПорогом(ЛЛПостроительМенеджеровПроходок PMB,
                                              бцел Threshold);

/** See llvm::PassManagerBuilder::populateFunctionPassManager. */
проц
ЛЛПМП_НаполниМенеджерПроходокФункций(ЛЛПостроительМенеджеровПроходок PMB,
                                                  ЛЛМенеджерПроходок пм);

/** See llvm::PassManagerBuilder::populateModulePassManager. */
проц
ЛЛПМП_НаполниМенеджерПроходокМодулей(ЛЛПостроительМенеджеровПроходок PMB,
                                                ЛЛМенеджерПроходок пм);

/** See llvm::PassManagerBuilder::populateLTOPassManager. */
проц ЛЛПМП_НаполниМенеджерПроходокОВК(ЛЛПостроительМенеджеровПроходок PMB,
                                                  ЛЛМенеджерПроходок пм,
                                                  ЛЛБул Internalize,
                                                  ЛЛБул RunInliner);


}
