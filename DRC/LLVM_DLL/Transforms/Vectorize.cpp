
extern "C" {
#include "../Header.h"


/**
 * @defgroup LLVMCTransformsVectorize Vectorization transformations
 * @ingroup LLVMCTransforms
 *
 * @{
 */

/** See llvm::createLoopVectorizePass function. */
LLEXPORT void ЛЛДобавьПроходкуВекторизацЦикла(ЛЛМенеджерПроходок PM){
	LLVMAddLoopVectorizePass(PM);
}

/** See llvm::createSLPVectorizerPass function. */
LLEXPORT void ЛЛДобавьПроходкуВекторизацСЛП(ЛЛМенеджерПроходок PM){
	LLVMAddSLPVectorizePass( PM);
}

/**
 * @}
 */


}

