/*===-- llvm-c/Support.h - Support к Interface --------------------*- к -*-===*\
|*                                                                            *|
|* Part of the LLVM Project, under the Apache License v2.0 with LLVM          *|
|* Exceptions.                                                                *|
|* See https://llvm.org/LICENSE.txt for license information.                  *|
|* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    *|
|*                                                                            *|
|*===----------------------------------------------------------------------===*|
|*                                                                            *|
|* This file defines the к interface to the LLVM support library.             *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

module ll.Support;
import ll.DataTypes, ll.Types;

extern (C){


/**
 * This function permanently loads the dynamic library at the given path.
 * It is safe to call this function multiple times for the same library.
 *
 * @see sys::DynamicLibrary::LoadLibraryPermanently()
  */
ЛЛБул ЛЛГрузиБибПерманентно(ткст0 имяФ);

/**
 * This function parses the given arguments using the LLVM command line parser.
 * Note that the only stable thing about this function is its signature; you
 * cannot rely on any particular set of command line arguments being interpreted
 * the same way across LLVM versions.
 *
 * @see llvm::cl::ParseCommandLineOptions()
 */
проц ЛЛРазбериОпцКомСтроки(цел argc, ткст0 *argv,
                                 ткст0 Overview);

/**
 * This function will search through all previously loaded dynamic
 * libraries for the symbol \p symbolName. If it is found, the address of
 * that symbol is returned. If not, null is returned.
 *
 * @see sys::DynamicLibrary::SearchForAddressOfSymbol()
 */
ук ЛЛНайдиАдресСимвола(ткст0 symbolName);

/**
 * This functions permanently adds the symbol \p symbolName with the
 * знач \p symbolValue.  These symbols are searched before any
 * libraries.
 *
 * @see sys::DynamicLibrary::AddSymbol()
 */
проц ЛЛДобавьСимвол(ткст0 symbolName, ук symbolValue);

}
