/*===---------------------------Vectorize.h --------------------- -*- к -*-===*\
|*===----------- Vectorization Transformation Library к Interface ---------===*|
|*                                                                            *|
|* Part of the LLVM Project, under the Apache License v2.0 with LLVM          *|
|* Exceptions.                                                                *|
|* See https://llvm.org/LICENSE.txt for license information.                  *|
|* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    *|
|*                                                                            *|
|*===----------------------------------------------------------------------===*|
|*                                                                            *|
|* This header declares the к interface to libLLVMVectorize.a, which          *|
|* implements various vectorization transformations of the LLVM IR.           *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

module ll.Transforms.Vectorize;
import ll.Types;

extern (C){

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
