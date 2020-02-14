
extern "C" {
#include "Header.h"


/**
 * Returns the type id for the given error instance, which must be a failure
 * value (i.e. non-null).
 */
LLEXPORT ЛЛИдТипаОшибки ЛЛДайИдТипаОшибки(ЛЛОшибка Err);

/**
 * Dispose of the given error without handling it. This operation consumes the
 * error, and the given ЛЛОшибка value is not usable once this call returns.
 * Note: This method *only* needs to be called if the error is not being passed
 * to some other consuming operation, e.g. LLVMGetErrorMessage.
 */
LLEXPORT void ЛЛКонсуммируйОш(ЛЛОшибка Err);

/**
 * Returns the given string's error message. This operation consumes the error,
 * and the given ЛЛОшибка value is not usable once this call returns.
 * The caller is responsible for disposing of the string by calling
 * LLVMDisposeErrorMessage.
 */
LLEXPORT char *ЛЛДайОшСооб(ЛЛОшибка Err);

/**
 * Dispose of the given error message.
 */
LLEXPORT void ЛЛВыместиОшСооб(char *ErrMsg);

/**
 * Returns the type id for llvm StringError.
 */
LLEXPORT ЛЛИдТипаОшибки ЛЛДайТкстИдаТипаОш(void);

/**
 * Install a fatal error handler. By default, if LLVM detects a fatal error, it
 * will call exit(1). This may not be appropriate in many contexts. For example,
 * doing exit(1) will bypass many crash reporting/tracing system tools. This
 * function allows you to install a callback that will be invoked prior to the
 * call to exit(1).
 */
void ЛЛУстановиОбрФатОш(ЛЛОбработчикФатальнойОшибки Handler);

/**
 * Reset the fatal error handler. This resets LLVM's fatal error handling
 * behavior to the default.
 */
void ЛЛСбросьОбрФатОш(void);

/**
 * Enable LLVM's built-in stack trace code. This intercepts the OS's crash
 * signals and prints which component of LLVM you were in at the time if the
 * crash.
 */
void ЛЛАктивируйТрассировкуСтека(void) ;

}

