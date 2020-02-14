
module ll.Transforms.Scalar;
import ll.Types;

extern (C){


/**
 * @defgroup LLVMCTransformsScalar Scalar transformations
 * @ingroup LLVMCTransforms
 *
 * @{
 */

/** See llvm::createAggressiveDCEPass function. */
проц ЛЛДобавьПроходкуАгрессивДЦЕ(ЛЛМенеджерПроходок пм);

/** See llvm::createBitTrackingDCEPass function. */
проц ЛЛДобавьПроходкуБитТрэкингДЦЕ(ЛЛМенеджерПроходок пм);

/** See llvm::createAlignmentFromAssumptionsPass function. */
проц ЛЛДобавьПроходкуРаскладкаИзАссумпций(ЛЛМенеджерПроходок пм);

/** See llvm::createCFGSimplificationPass function. */
проц ЛЛДобавьПроходкуКФГУпрощения(ЛЛМенеджерПроходок пм);

/** See llvm::createDeadStoreEliminationPass function. */
проц ЛЛДобавьПроходкуУдаленияМёртвыхХранилищ(ЛЛМенеджерПроходок пм);

/** See llvm::createScalarizerPass function. */
проц ЛЛДобавьПроходкуСкаляризатора(ЛЛМенеджерПроходок пм);

/** See llvm::createMergedLoadStoreMotionPass function. */
проц ЛЛДобавьПроходкуМёрдждЛоудСторМоушн(ЛЛМенеджерПроходок пм);

/** See llvm::createGVNPass function. */
проц ЛЛДобавьПроходкуГВН(ЛЛМенеджерПроходок пм);

/** See llvm::createGVNPass function. */
проц ЛЛДобавьПроходкуНовГВН(ЛЛМенеджерПроходок пм);

/** See llvm::createIndVarSimplifyPass function. */
проц ЛЛДобавьПроходкуИндВарУпрощения(ЛЛМенеджерПроходок пм);

/** See llvm::createJumpThreadingPass function. */
проц ЛЛДобавьПроходкуДжампПоточности(ЛЛМенеджерПроходок пм);

/** See llvm::createLICMPass function. */
проц ЛЛДобавьПроходкуЛИЦМ(ЛЛМенеджерПроходок пм);

/** See llvm::createLoopDeletionPass function. */
проц ЛЛДобавьПроходкуЛупДелешн(ЛЛМенеджерПроходок пм);

/** See llvm::createLoopIdiomPass function */
проц ЛЛДобавьПроходкуЛупИдиом(ЛЛМенеджерПроходок пм);

/** See llvm::createLoopRotatePass function. */
проц ЛЛДобавьПроходкуЛупРотейт(ЛЛМенеджерПроходок пм);

/** See llvm::createLoopRerollPass function. */
проц ЛЛДобавьПроходкуЛупРеролл(ЛЛМенеджерПроходок пм);

/** See llvm::createLoopUnrollPass function. */
проц ЛЛДобавьПроходкуЛупАнролл(ЛЛМенеджерПроходок пм);

/** See llvm::createLoopUnrollAndJamPass function. */
проц ЛЛДобавьПроходкуЛупАнроллЭндДжем(ЛЛМенеджерПроходок пм);

/** See llvm::createLoopUnswitchPass function. */
проц ЛЛДобавьПроходкуЛупАнСвитч(ЛЛМенеджерПроходок пм);

/** See llvm::createLowerAtomicPass function. */
проц ЛЛДобавьПроходкуЛоверАтомик(ЛЛМенеджерПроходок пм);

/** See llvm::createMemCpyOptPass function. */
проц ЛЛДобавьПроходкуКопирПамОпц(ЛЛМенеджерПроходок пм);

/** See llvm::createPartiallyInlineLibCallsPass function. */
проц ЛЛДобавьПроходкуЧастичнИнлайнВызБиб(ЛЛМенеджерПроходок пм);

/** See llvm::createReassociatePass function. */
проц ЛЛДобавьПроходкуРеассоциации(ЛЛМенеджерПроходок пм);

/** See llvm::createSCCPPass function. */
проц ЛЛДобавьПроходкуСЦЦП(ЛЛМенеджерПроходок пм);

/** See llvm::createSROAPass function. */
проц ЛЛДобавьПроходкуСкалярРеплАгрегаты(ЛЛМенеджерПроходок пм);

/** See llvm::createSROAPass function. */
проц ЛЛДобавьССАПроходкиСкалярРеплАгрегаты(ЛЛМенеджерПроходок пм);

/** See llvm::createSROAPass function. */
проц ЛЛДобавьПроходкуСкалярРеплАгрегатыСПорогом(ЛЛМенеджерПроходок пм,
                                                  цел Threshold);

/** See llvm::createSimplifyLibCallsPass function. */
проц ЛЛДобавьПроходкуУпроститьВызовыБиб(ЛЛМенеджерПроходок пм);

/** See llvm::createTailCallEliminationPass function. */
проц ЛЛДобавьПроходкуИскоренениеТейлВызовов(ЛЛМенеджерПроходок пм);

/** See llvm::createConstantPropagationPass function. */
проц ЛЛДобавьПроходкуПропагацияКонстант(ЛЛМенеджерПроходок пм);

/** See llvm::demotePromoteMemoryToRegisterPass function. */
проц ЛЛДобавьПроходкуДемотПамВРегистр(ЛЛМенеджерПроходок пм);

/** See llvm::createVerifierPass function. */
проц ЛЛДобавьПроходкуВерификатора(ЛЛМенеджерПроходок пм);

/** See llvm::createCorrelatedValuePropagationPass function */
проц ЛЛДобавьПроходкуПропагацииКоррелирЗначений(ЛЛМенеджерПроходок пм);

/** See llvm::createEarlyCSEPass function */
проц ЛЛДобавьПроходкуЁлиЦСЕ(ЛЛМенеджерПроходок пм);

/** See llvm::createEarlyCSEPass function */
проц ЛЛДобавьПроходкуЁлиЦСЕПамССА(ЛЛМенеджерПроходок пм);

/** See llvm::createLowerExpectIntrinsicPass function */
проц ЛЛДобавьПроходкуЛоверЭкпектИнтринсик(ЛЛМенеджерПроходок пм);

/** See llvm::createTypeBasedAliasAnalysisPass function */
проц ЛЛДобавьПроходкуАнализАлиасаНаОвеТипа(ЛЛМенеджерПроходок пм);

/** See llvm::createScopedNoAliasAAPass function */
проц ЛЛДобавьПроходкуМасштбнБезАлиасАА(ЛЛМенеджерПроходок пм);

/** See llvm::createBasicAliasAnalysisPass function */
проц ЛЛДобавьПроходкуБазовыйАнализАлиаса(ЛЛМенеджерПроходок пм);

/** See llvm::createUnifyFunctionExitNodesPass function */
проц ЛЛДобавьПроходкуУнификацииУзловВыходаИзФункц(ЛЛМенеджерПроходок пм);


}