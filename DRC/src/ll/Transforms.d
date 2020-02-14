module ll.Transforms;
import ll.Types, ll.PassManagerBuilder;

extern (C) {


	/**
	* @defgroup LLVMCTransformsAggressiveInstCombine Aggressive Instruction Combining transformations
	* @ingroup LLVMCTransforms
	*
	* @{
	*/

	/** See llvm::createAggressiveInstCombinerPass function. */
	проц ЛЛДобавьПроходкуАгрессивИнстКомбайнера(ЛЛМенеджерПроходок пм);

	/**
	* @defgroup LLVMCTransformsCoroutines Coroutine transformations
	* @ingroup LLVMCTransforms
	*
	* @{
	*/

	/** See llvm::createCoroEarlyPass function. */
	проц ЛЛДобавьПроходкуКороЁли(ЛЛМенеджерПроходок пм);

	/** See llvm::createCoroSplitPass function. */
	проц ЛЛДобавьПроходкуКороСплит(ЛЛМенеджерПроходок пм);

	/** See llvm::createCoroElidePass function. */
	проц ЛЛДобавьПроходкуКороЭлайд(ЛЛМенеджерПроходок пм);

	/** See llvm::createCoroCleanupPass function. */
	проц ЛЛДобавьПроходкуКороКлинап(ЛЛМенеджерПроходок пм);

	/**
	* @defgroup LLVMCTransformsInstCombine Instruction Combining transformations
	* @ingroup LLVMCTransforms
	*
	* @{
	*/

	/** See llvm::createInstructionCombiningPass function. */
	проц ЛЛДобавьПроходкуКомбинированияИнструкций(ЛЛМенеджерПроходок пм);

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

	/**
	* @defgroup LLVMCTransformsUtils Transformation Utilities
	* @ingroup LLVMCTransforms
	*
	* @{
	*/

	/** See llvm::createLowerSwitchPass function. */
	проц ЛЛДобавьПроходкуЛоверСвитч(ЛЛМенеджерПроходок пм);

	/** See llvm::createPromoteMemoryToRegisterPass function. */
	проц ЛЛДобавьПроходкуПамятьВРегистр(ЛЛМенеджерПроходок пм);

	/** See llvm::createAddDiscriminatorsPass function. */
	проц ЛЛДобавьПроходкуДобавкиДискриминаторов(ЛЛМенеджерПроходок пм);

	/**
	* @defgroup LLVMCTransformsVectorize Vectorization transformations
	* @ingroup LLVMCTransforms
	*
	* @{
	*/

	/** See llvm::createLoopVectorizePass function. */
	проц ЛЛДобавьПроходкуВекторизацЦикла(ЛЛМенеджерПроходок пм);

	/** See llvm::createSLPVectorizerPass function. */
	проц ЛЛДобавьПроходкуВекторизацСЛП(ЛЛМенеджерПроходок пм);


}
