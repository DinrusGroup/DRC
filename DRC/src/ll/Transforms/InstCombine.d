/*===-- Scalar.h - Scalar Transformation Library к Interface ----*- C++ -*-===*\
|*                                                                            *|
|* Part of the LLVM Project, under the Apache License v2.0 with LLVM          *|
|* Exceptions.                                                                *|
|* See https://llvm.org/LICENSE.txt for license information.                  *|
|* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    *|
|*                                                                            *|
|*===----------------------------------------------------------------------===*|
|*                                                                            *|
|* This header declares the к interface to libLLVMInstCombine.a, which        *|
|* combines instructions to form fewer, simple IR instructions.               *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

module ll.Transforms.InstCombine;
import ll.Types;
extern (C) {

/**
 * @defgroup LLVMCTransformsInstCombine Instruction Combining transformations
 * @ingroup LLVMCTransforms
 *
 * @{
 */

/** See llvm::createInstructionCombiningPass function. */
проц ЛЛДобавьПроходкуКомбинированияИнструкций(ЛЛМенеджерПроходок пм);

}

