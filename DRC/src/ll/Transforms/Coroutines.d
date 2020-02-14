/*===-- Coroutines.h - Coroutines Library к Interface -----------*- C++ -*-===*\
|*                                                                            *|
|* Part of the LLVM Project, under the Apache License v2.0 with LLVM          *|
|* Exceptions.                                                                *|
|* See https://llvm.org/LICENSE.txt for license information.                  *|
|* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    *|
|*                                                                            *|
|*===----------------------------------------------------------------------===*|
|*                                                                            *|
|* This header declares the к interface to libLLVMCoroutines.a, which         *|
|* implements various scalar transformations of the LLVM IR.                  *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

module ll.Transforms.Coroutines;
import ll.Types;
extern (C) {

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

}
