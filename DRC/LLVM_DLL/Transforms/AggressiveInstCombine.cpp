extern "C" {
#include "../Header.h"
/**
 * @defgroup LLVMCTransformsAggressiveInstCombine Aggressive Instruction Combining transformations
 * @ingroup LLVMCTransforms
 *
 * @{
 */

/** See llvm::createAggressiveInstCombinerPass function. */
LLEXPORT void ЛЛДобавьПроходкуАгрессивИнстКомбайнера(ЛЛМенеджерПроходок PM){
	LLVMAddAggressiveInstCombinerPass(PM);
}

/**
 * @}
 */


}

