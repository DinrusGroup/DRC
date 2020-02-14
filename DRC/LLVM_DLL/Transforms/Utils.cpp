
extern "C" {

#include "../Header.h"
/**
 * @defgroup LLVMCTransformsUtils Transformation Utilities
 * @ingroup LLVMCTransforms
 *
 * @{
 */

/** See llvm::createLowerSwitchPass function. */
LLEXPORT void ЛЛДобавьПроходкуЛоверСвитч(ЛЛМенеджерПроходок PM){
	LLVMAddLowerSwitchPass(PM);
}

/** See llvm::createPromoteMemoryToRegisterPass function. */
LLEXPORT void ЛЛДобавьПроходкуПамятьВРегистр(ЛЛМенеджерПроходок PM){
	LLVMAddPromoteMemoryToRegisterPass(PM);
}

/** See llvm::createAddDiscriminatorsPass function. */
LLEXPORT void ЛЛДобавьПроходкуДобавкиДискриминаторов(ЛЛМенеджерПроходок PM){
	LLVMAddAddDiscriminatorsPass(PM);
}

/**
 * @}
 */

}


