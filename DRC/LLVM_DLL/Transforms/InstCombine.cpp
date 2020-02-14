



extern "C" {
#include "../Header.h"

/**
 * @defgroup LLVMCTransformsInstCombine Instruction Combining transformations
 * @ingroup LLVMCTransforms
 *
 * @{
 */

/** See llvm::createInstructionCombiningPass function. */
LLEXPORT void ЛЛДобавьПроходкуКомбинированияИнструкций(LLVMPassManagerRef PM){
	LLVMAddInstructionCombiningPass(PM);
}

/**
 * @}
 */


}


