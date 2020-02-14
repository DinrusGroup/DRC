/*===-- llvm-c/Support.h - Декларации типов Си интерфейса ---------*- к -*-===*\
|*                                                                            *|
|* Part of the LLVM Project, under the Apache License v2.0 with LLVM          *|
|* Exceptions.                                                                *|
|* See https://llvm.org/LICENSE.txt for license information.                  *|
|* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    *|
|*                                                                            *|
|*===----------------------------------------------------------------------===*|
|*                                                                            *|
|* В этом файле определены типы, используемые Си интерфейсом LLVM.            *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

module ll.Types;
public import ll.DataTypes;


extern (C)
{


/**
 * @defgroup LLVMCSupportTypes Типы и Перечни
 *
 * @{
 */

alias цел ЛЛБул;

/* Opaque types. */

/**
 * LLVM использует полиморфную иерархию типов, которую нельзя представить в Си,
 * поэтому параметры следует передавать как базовые типы. Несмотря на объявленные
 * типы, большинство представленных функций оперирует только над ветвями 
 * иерархии типов. Декларированные имена параметров описательны (дескриптивны)
 * и определяют требуемый тип. В дополнение каждая иерархия типов документирована
 * вместе с функциями, оперирующими над ней. Для большей ясности обращайтесь к
 * Си++ коду LLVM. В случае сомнений, обращайтесь к Core.cpp, который выполняет
 * даункаст параметров в форме unwrap<ТребуемыйТип>(Парам).
 */

/**
 * Используется для передачи регионов памяти через интерфейсы LLVM.
 *
 * @see llvm::MemoryBuffer
 */
struct LLVMOpaqueMemoryBuffer{}
alias LLVMOpaqueMemoryBuffer *ЛЛБуферПамяти;

/**
 * Верхнеуровневый контейнер для всех глобальных данных LLVM. См. класс LLVMContext.
 */
struct LLVMOpaqueContext{}
alias LLVMOpaqueContext *ЛЛКонтекст;

/**
 * Верхнеуровневый контейнер для всех иных объектов LLVM Intermediate Representation (IR).
 *
 * @see llvm::Module
 */
struct LLVMOpaqueModule{}
alias LLVMOpaqueModule *ЛЛМодуль;

/**
 * Каждое значение в LLVM IR имеет тип, некий ЛЛТип.
 *
 * @see llvm::Type
 */
struct LLVMOpaqueType{}
alias LLVMOpaqueType *ЛЛТип;

/**
 * Представляет индивидуальное значение в LLVM IR.
 *
 * Моделирует llvm::знач.
 */
struct LLVMOpaqueValue{}
alias LLVMOpaqueValue *ЛЛЗначение;

/**
 * Педставляет базовый блок инструкций в LLVM IR.
 *
 * Моделирует llvm::BasicBlock.
 */
struct LLVMOpaqueBasicBlock{}
alias LLVMOpaqueBasicBlock *ЛЛБазовыйБлок;

/**
 * Представляет Метаданные LLVM.
 *
 * Моделирует llvm::Metadata.
 */
struct LLVMOpaqueMetadata{}
alias LLVMOpaqueMetadata *ЛЛМетаданные;

/**
 * Представляет Именованный Узел Метаданных LLVM.
 *
 * Моделирует llvm::имУзелМД.
 */
struct LLVMOpaqueNamedMDNode{}
alias LLVMOpaqueNamedMDNode *ЛЛИменованыйУзелМД;

/**
 * Представляет запись в приложениях метаданных Глобального Объекта.
 *
 * Моделирует std::pair<бцел, MDNode *>
 */
struct LLVMOpaqueValueMetadataEntry{}
alias LLVMOpaqueValueMetadataEntry ЛЛЗаписьМетаданныхЗначения;

/**
 * Представляет базовый построитель блоков LLVM.
 *
 * Моделирует llvm::IRBuilder.
 */
struct LLVMOpaqueBuilder{}
alias LLVMOpaqueBuilder *ЛЛПостроитель;

/**
 * Представляет построитель отладочной информации LLVM.
 *
 * Моделирует llvm::DIBuilder.
 */
struct LLVMOpaqueDIBuilder{}
alias LLVMOpaqueDIBuilder *ЛЛПостроительОИ;

/**
 * Интерфейс, используемый для предоставления модуля интерпретатору или JIT-отладчику.
 * Сейчас это просто синоним llvm::Module, но нам придётся использовать разные типы,
 * чтобы сохранить бинарную совместимость.
 */
struct LLVMOpaqueModuleProvider{}
alias LLVMOpaqueModuleProvider *ЛЛМодульПровайдер;

/** @see llvm::PassManagerBase */
struct LLVMOpaquePassManager{}
alias LLVMOpaquePassManager *ЛЛМенеджерПроходок;


struct LLVMOpaquePassRegistry{}
alias LLVMOpaquePassRegistry *ЛЛРеестрПроходок;

/**
 * Применяется для получения пользователей и пользуемых Значения.
 *
 * @see llvm::Use */
struct LLVMOpaqueUse{}
alias LLVMOpaqueUse *ЛЛИспользование;

/**
 * Используется для представления атрибутов.
 *
 * @see llvm::Attribute
 */
struct LLVMOpaqueAttributeRef{}
alias LLVMOpaqueAttributeRef *ЛЛАтрибут;

/**
 * @see llvm::DiagnosticInfo
 */
struct LLVMOpaqueDiagnosticInfo{}
alias LLVMOpaqueDiagnosticInfo *ЛЛИнфоДиагностики;

/**
 * @see llvm::Comdat
 */
struct LLVMComdat{}
alias LLVMComdat *ЛЛКомдат;

/**
 * @see llvm::Module::ModuleFlagEntry
 */
struct LLVMOpaqueModuleFlagEntry{}
alias LLVMOpaqueModuleFlagEntry ЛЛЗаписьФлагаМодуля;

/**
 * @see llvm::JITEventListener
 */
struct LLVMOpaqueJITEventListener{}
alias LLVMOpaqueJITEventListener *ЛЛДатчикСобытийДжит;

/**
 * @see llvm::object::Binary
 */
struct LLVMOpaqueBinary{}
alias LLVMOpaqueBinary *ЛЛБинарник;

}