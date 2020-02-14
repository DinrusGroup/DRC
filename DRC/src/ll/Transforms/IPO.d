
module ll.Transforms.IPO;
import ll.Types;
extern (C) {


/**
 * @defgroup LLVMCTransformsIPO Interprocedural transformations
 * @ingroup LLVMCTransforms
 *
 * @{
 */

/** See llvm::createArgumentPromotionPass function. */
проц ЛЛДобавьПроходкуПродвиженияАргументов(ЛЛМенеджерПроходок пм);

/** See llvm::createConstantMergePass function. */
проц ЛЛДобавьПроходкуМёрджКонстант(ЛЛМенеджерПроходок пм);

/** See llvm::createCalledValuePropagationPass function. */
проц ЛЛДобавьПроходкуПропагацииВызванногоЗначения(ЛЛМенеджерПроходок пм);

/** See llvm::createDeadArgEliminationPass function. */
проц ЛЛДобавьПроходкуИскорененияНенужныхАргов(ЛЛМенеджерПроходок пм);

/** See llvm::createFunctionAttrsPass function. */
проц ЛЛДобавьПроходкуАтрибутовФункций(ЛЛМенеджерПроходок пм);

/** See llvm::createFunctionInliningPass function. */
проц ЛЛДобавьПроходкуИнлайнингаФункций(ЛЛМенеджерПроходок пм);

/** See llvm::createAlwaysInlinerPass function. */
проц ЛЛДобавьПроходкуИнлайнВсегда(ЛЛМенеджерПроходок пм);

/** See llvm::createGlobalDCEPass function. */
проц LLAddGloЛЛДобавьПроходкуГлобДЦЕ(ЛЛМенеджерПроходок пм);

/** See llvm::createGlobalOptimizerPass function. */
проц ЛЛДобавьПроходкуГлобОптимизатора(ЛЛМенеджерПроходок пм);

/** See llvm::createIPConstantPropagationPass function. */
проц ЛЛДобавьПроходкуПропагацииИПКонстант(ЛЛМенеджерПроходок пм);

/** See llvm::createPruneEHPass function. */
проц ЛЛДобавьПроходкуПрюнЕХ(ЛЛМенеджерПроходок пм);

/** See llvm::createIPSCCPPass function. */
проц ЛЛДобавьПроходкуИПСЦЦ(ЛЛМенеджерПроходок пм);

/** See llvm::createInternalizePass function. */
проц ЛЛДобавьПроходкуИнтернализации(ЛЛМенеджерПроходок, бцел AllButMain);

/** See llvm::createStripDeadPrototypesPass function. */
проц ЛЛДобавьПроходкуОчисткиНенужныхПрототипов(ЛЛМенеджерПроходок пм);

/** See llvm::createStripSymbolsPass function. */
проц ЛЛДобавьПроходкуОчисткиСимволов(ЛЛМенеджерПроходок пм);


}
