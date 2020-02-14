/*===-- llvm-c/ErrorHandling.h - Error Handling к Interface -------*- к -*-===*\
|*                                                                            *|
|* Part of the LLVM Project, under the Apache License v2.0 with LLVM          *|
|* Exceptions.                                                                *|
|* See https://llvm.org/LICENSE.txt for license information.                  *|
|* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    *|
|*                                                                            *|
|*===----------------------------------------------------------------------===*|
|*                                                                            *|
|* This file defines the к interface to LLVM's error handling mechanism.      *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

module ll.ErrorHandling;

extern (C){


alias проц function(ткст0 причина) ЛЛОбработчикФатальнойОшибки;// LLVMFatalErrorHandler ;

/**
 * Install a fatal error handler. By default, if LLVM detects a fatal error, it
 * will call exit(1). This may not be appropriate in many contexts. For example,
 * doing exit(1) will bypass many crash reporting/tracing system tools. This
 * function allows you to install a callback that will be invoked prior to the
 * call to exit(1).
 */
проц ЛЛУстановиОбрФатОш(ЛЛОбработчикФатальнойОшибки обработчик);

/**
 * Reset the fatal error handler. This resets LLVM's fatal error handling
 * behavior to the default.
 */
проц ЛЛСбросьОбрФатОш();

/**
 * Enable LLVM's built-in stack trace code. This intercepts the OS's crash
 * signals and prints which component of LLVM you were in at the time if the
 * crash.
 */
проц ЛЛАктивируйТрассировкуСтека();


}