/*===-- llvm-c/Object.h - Object Lib к Iface --------------------*- C++ -*-===*/
/*                                                                            */
/* Part of the LLVM Project, under the Apache License v2.0 with LLVM          */
/* Exceptions.                                                                */
/* See https://llvm.org/LICENSE.txt for license information.                  */
/* SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception                    */
/*                                                                            */
/*===----------------------------------------------------------------------===*/
/*                                                                            */
/* This header declares the к interface to libLLVMObject.a, which             */
/* implements object file reading and writing.                                */
/*                                                                            */
/* Many exotic languages can interoperate with к code but have a harder time  */
/* with C++ due to name mangling. So in addition to к, this interface enables */
/* tools written in such languages.                                           */
/*                                                                            */
/*===----------------------------------------------------------------------===*/

module ll.Object;
import ll.Types;
//#include "llvm/Config/llvm-config.h"

extern (C){

/**
 * @defgroup LLVMCObject Object file reading and writing
 * @ingroup LLVMC
 *
 * @{
 */
struct LLVMOpaqueSectionIterator;
struct LLVMOpaqueSymbolIterator;
struct LLVMOpaqueRelocationIterator;
// Opaque type wrappers
alias LLVMOpaqueSectionIterator *ЛЛИтераторСекций;
alias LLVMOpaqueSymbolIterator *ЛЛСимвИтератор;
alias LLVMOpaqueRelocationIterator *ЛЛИтераторРелокаций;

/** Deprecated: Use ЛЛБинарник instead. */
struct LLVMOpaqueфлОбъ;
alias LLVMOpaqueфлОбъ *ЛЛФайлОбъекта;

enum LLVMBinaryType {
  Archive,                /**< Archive file. */
  MachOUniversalBinary,   /**< Mach-O Universal Binary file. */
  COFFImportFile,         /**< COFF Import file. */
  IR,                     /**< LLVM IR. */
  WinRes,                 /**< Windows resource (.res) file. */
  COFF,                   /**< COFF Object file. */
  ELF32L,                 /**< ELF 32-bit, little endian. */
  ELF32B,                 /**< ELF 32-bit, big endian. */
  ELF64L,                 /**< ELF 64-bit, little endian. */
  ELF64B,                 /**< ELF 64-bit, big endian. */
  MachO32L,               /**< MachO 32-bit, little endian. */
  MachO32B,               /**< MachO 32-bit, big endian. */
  MachO64L,               /**< MachO 64-bit, little endian. */
  MachO64B,               /**< MachO 64-bit, big endian. */
  Wasm,                   /**< Web Assembly. */
} ;

/**
 * Create a binary file from the given memory buffer.
 *
 * The exact type of the binary file will be inferred automatically, and the
 * appropriate implementation selected.  The context may be NULL except if
 * the resulting file is an LLVM IR file.
 *
 * The memory buffer is not consumed by this function.  It is the responsibilty
 * of the caller to free it with \конст LLVMDisposeMemoryBuffer.
 *
 * If NULL is returned, the \p ошСооб parameter is populated with the
 * error's description.  It is then the caller's responsibility to free this
 * message by calling \конст LLVMDisposeMessage.
 *
 * @see llvm::object::createBinary
 */
ЛЛБинарник ЛЛСоздайБин(ЛЛБуферПамяти буфПам,
                               ЛЛКонтекст Context,
                               ткст0 *ошСооб);

/**
 * Dispose of a binary file.
 *
 * The binary file does not own its backing buffer.  It is the responsibilty
 * of the caller to free it with \конст LLVMDisposeMemoryBuffer.
 */
проц ЛЛВыместиБин(ЛЛБинарник BR);

/**
 * Retrieves a copy of the memory buffer associated with this object file.
 *
 * The returned buffer is merely a shallow copy and does not own the actual
 * backing buffer of the binary. Nevertheless, it is the responsibility of the
 * caller to free it with \конст LLVMDisposeMemoryBuffer.
 *
 * @see llvm::object::getMemoryBufferRef
 */
ЛЛБуферПамяти ЛЛБИинКопируйБуфПам(ЛЛБинарник BR);

/**
 * Retrieve the specific type of a binary.
 *
 * @see llvm::object::Binary::getType
 */
LLVMBinaryType ЛЛБинДайТип(ЛЛБинарник BR);

/*
 * For a Mach-O universal binary file, retrieves the object file corresponding
 * to the given architecture if it is present as a slice.
 *
 * If NULL is returned, the \p ошСооб parameter is populated with the
 * error's description.  It is then the caller's responsibility to free this
 * message by calling \конст LLVMDisposeMessage.
 *
 * It is the responsiblity of the caller to free the returned object file by
 * calling \конст LLVMDisposeBinary.
 */
ЛЛБинарник ЛЛМакхО_УнивБин_КопируйОбъДляАрх(ЛЛБинарник BR,
                                                        ткст0 Arch,
                                                        т_мера ArchLen,
                                                        ткст0 *ошСооб);

/**
 * Retrieve a copy of the section iterator for this object file.
 *
 * If there are no sections, the result is NULL.
 *
 * The returned iterator is merely a shallow copy. Nevertheless, it is
 * the responsibility of the caller to free it with
 * \конст LLVMDisposeSectionIterator.
 *
 * @see llvm::object::sections()
 */
ЛЛИтераторСекций ЛЛОбъФайл_КопируйИтераторВыборки(ЛЛБинарник BR);

/**
 * Returns whether the given section iterator is at the end.
 *
 * @see llvm::object::section_end
 */
ЛЛБул ЛЛОбъФайл_ИтераторВыборкиВКонце_ли(ЛЛБинарник BR,
                                              ЛЛИтераторСекций SI);

/**
 * Retrieve a copy of the symbol iterator for this object file.
 *
 * If there are no symbols, the result is NULL.
 *
 * The returned iterator is merely a shallow copy. Nevertheless, it is
 * the responsibility of the caller to free it with
 * \конст LLVMDisposeSymbolIterator.
 *
 * @see llvm::object::symbols()
 */
ЛЛСимвИтератор ЛЛОбъФайл_КопируйСимвИтератор(ЛЛБинарник BR);

/**
 * Returns whether the given symbol iterator is at the end.
 *
 * @see llvm::object::symbol_end
 */
ЛЛБул ЛЛОбъФайл_СимвИтераторВКонце_ли(ЛЛБинарник BR,
                                             ЛЛСимвИтератор SI);

проц ЛЛВыместиИтераторСекций(ЛЛИтераторСекций SI);

проц ЛЛПереместисьКСледщСекции(ЛЛИтераторСекций SI);
проц ЛЛПерместисьКСодержащСекции(ЛЛИтераторСекций Sect,
                                 ЛЛСимвИтератор Sym);

// флОбъ Symbol iterators
проц ЛЛВыместиСимвИтератор(ЛЛСимвИтератор SI);
проц ЛЛПереместисьКСледщСимволу(ЛЛСимвИтератор SI);

// SectionRef accessors
ткст0 ЛЛДайИмяСекции(ЛЛИтераторСекций SI);
uint64_t ЛЛДАйРазмСекции(ЛЛИтераторСекций SI);
ткст0 ЛЛДайСодержимоеСекции(ЛЛИтераторСекций SI);
uint64_t ЛЛДайАдресСекции(ЛЛИтераторСекций SI);
ЛЛБул ЛЛСодержитСекцияСимвол_ли(ЛЛИтераторСекций SI,
                                 ЛЛСимвИтератор Sym);

// секция Relocation iterators
ЛЛИтераторРелокаций ЛЛДайРелокации(ЛЛИтераторСекций секция);
проц ЛЛВыместиИтераторРелокаций(ЛЛИтераторРелокаций RI);
ЛЛБул ЛЛИтераторРелокацийВКонце_ли(ЛЛИтераторСекций секция,
                                       ЛЛИтераторРелокаций RI);
проц ЛЛПереместисьКСледщРелокации(ЛЛИтераторРелокаций RI);


// SymbolRef accessors
ткст0 ЛЛДайИмяСимвола(ЛЛСимвИтератор SI);
uint64_t ЛЛДайАдресСимвола(ЛЛСимвИтератор SI);
uint64_t ЛЛДайРазмСимвола(ЛЛСимвИтератор SI);

// RelocationRef accessors
uint64_t ЛЛДайСмещениеРелокации(ЛЛИтераторРелокаций RI);
ЛЛСимвИтератор ЛЛДайСимволРелокации(ЛЛИтераторРелокаций RI);
uint64_t ЛЛДайТипРелокации(ЛЛИтераторРелокаций RI);
// NOTE: Caller takes ownership of returned string of the two
// following functions.
ткст0 ЛЛДайИмяТипаРелокации(ЛЛИтераторРелокаций RI);
ткст0 ЛЛДайТкстЗначенияРелокации(ЛЛИтераторРелокаций RI);


/** Deprecated: Use LLVMCreateBinary instead. */
ЛЛФайлОбъекта ЛЛСоздайФайлОбъекта(ЛЛБуферПамяти буфПам);

/** Deprecated: Use LLVMDisposeBinary instead. */
проц ЛЛВыместиФайлОбъекта(ЛЛФайлОбъекта флОбъ);

/** Deprecated: Use LLVMфлОбъCopySectionIterator instead. */
ЛЛИтераторСекций ЛЛДайСекции(ЛЛФайлОбъекта флОбъ);

/** Deprecated: Use LLVMфлОбъIsSectionIteratorAtEnd instead. */
ЛЛБул ЛЛИтераторСекцииВКонце_ли(ЛЛФайлОбъекта флОбъ,
                                    ЛЛИтераторСекций SI);

/** Deprecated: Use LLVMфлОбъCopySymbolIterator instead. */
ЛЛСимвИтератор ЛЛДайСимволы(ЛЛФайлОбъекта флОбъ);

/** Deprecated: Use LLVMфлОбъIsSymbolIteratorAtEnd instead. */
ЛЛБул ЛЛСимвИтераторВКонце_ли(ЛЛФайлОбъекта флОбъ,
                                   ЛЛСимвИтератор SI);

}
