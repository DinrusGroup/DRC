/*===-- llvm-c/IRReader.h - Си интерфейс IR Reader----------------*- к -*-===*\
|*                                                                            *|
|* Part of the LLVM Project, under the Apache License v2.0 with LLVM          *|
|* Exceptions.                                                                *|
|* See https://llvm.org/LICENSE.txt for license information.                  *|
|* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    *|
|*                                                                            *|
|*===----------------------------------------------------------------------===*|
|*                                                                            *|
|* This file defines the к interface to the IR Reader.                        *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

module ll.IRReader;
import ll.Types;

extern (C){

/**
 * Прочитать LLVM IR из буфера памяти и преобразовать его в объект Модуль
 * в памяти. При успехе возвращает 0.
 * Дополнительно возвращает описание любых ошибок, происходящих при
 * разборе промежуточного представления. выхСооб должно быть вымещено
 * с помощью LLVMDisposeMessage.
 *
 * @see llvm::ParseIR()
 */
ЛЛБул ЛЛПарсируйППВКонтексте(ЛЛКонтекст кткст,
                              ЛЛБуферПамяти буфПам, ЛЛМодуль *выхМ,
                              ткст0 *выхСооб);

}
