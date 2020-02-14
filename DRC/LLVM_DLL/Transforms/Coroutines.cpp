
extern "C" {
#include "../Header.h"

/**
 * @defgroup LLVMCTransformsCoroutines Coroutine transformations
 * @ingroup LLVMCTransforms
 *
 * @{
 */

/** See llvm::createCoroEarlyPass function. */
LLEXPORT void ЛЛДобавьПроходкуКороЁли(ЛЛМенеджерПроходок PM){
	LLVMAddCoroEarlyPass(PM);
}

/** See llvm::createCoroSplitPass function. */
LLEXPORT void ЛЛДобавьПроходкуКороСплит(ЛЛМенеджерПроходок PM){
	LLVMAddCoroSplitPass(PM);
}
/** See llvm::createCoroElidePass function. */
LLEXPORT void ЛЛДобавьПроходкуКороЭлайд(ЛЛМенеджерПроходок PM){
	LLVMAddCoroElidePass(PM);
}

/** See llvm::createCoroCleanupPass function. */
LLEXPORT void ЛЛДобавьПроходкуКороКлинап(ЛЛМенеджерПроходок PM){
	LLVMAddCoroCleanupPass(PM);
}

/**
 * @}
 */

}
