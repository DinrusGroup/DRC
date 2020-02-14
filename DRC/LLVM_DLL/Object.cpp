
extern "C" {
#include "Header.h"

/**
 * @defgroup LLVMCObject Object file reading and writing
 * @ingroup LLVMC
 *
 * @{
 */

/**
 * Create a binary file from the given memory buffer.
 *
 * The exact type of the binary file will be inferred automatically, and the
 * appropriate implementation selected.  The context may be NULL except if
 * the resulting file is an LLVM IR file.
 *
 * The memory buffer is not consumed by this function.  It is the responsibilty
 * of the caller to free it with \c LLVMDisposeMemoryBuffer.
 *
 * If NULL is returned, the \p ErrorMessage parameter is populated with the
 * error's description.  It is then the caller's responsibility to free this
 * message by calling \c LLVMDisposeMessage.
 *
 * @see llvm::object::createBinary
 */
LLEXPORT ЛЛБинарник ЛЛСоздайБин(LLVMMemoryBufferRef MemBuf,
                               LLVMContextRef Context,
                               char **ErrorMessage){
  return LLVMCreateBinary( MemBuf, Context, ErrorMessage);
}

/**
 * Dispose of a binary file.
 *
 * The binary file does not own its backing buffer.  It is the responsibilty
 * of the caller to free it with \c LLVMDisposeMemoryBuffer.
 */
LLEXPORT void ЛЛВыместиБин(ЛЛБинарник BR){
  return  LLVMDisposeBinary(BR);
}

/**
 * Retrieves a copy of the memory buffer associated with this object file.
 *
 * The returned buffer is merely a shallow copy and does not own the actual
 * backing buffer of the binary. Nevertheless, it is the responsibility of the
 * caller to free it with \c LLVMDisposeMemoryBuffer.
 *
 * @see llvm::object::getMemoryBufferRef
 */
LLEXPORT LLVMMemoryBufferRef ЛЛБИинКопируйБуфПам(ЛЛБинарник BR){
  return  LLVMBinaryCopyMemoryBuffer(BR);
}

/**
 * Retrieve the specific type of a binary.
 *
 * @see llvm::object::Binary::getType
 */
LLEXPORT LLVMBinaryType ЛЛБинДайТип(ЛЛБинарник BR){
  return  LLVMBinaryGetType(BR);
}

/*
 * For a Mach-O universal binary file, retrieves the object file corresponding
 * to the given architecture if it is present as a slice.
 *
 * If NULL is returned, the \p ErrorMessage parameter is populated with the
 * error's description.  It is then the caller's responsibility to free this
 * message by calling \c LLVMDisposeMessage.
 *
 * It is the responsiblity of the caller to free the returned object file by
 * calling \c LLVMDisposeBinary.
 */
LLEXPORT ЛЛБинарник ЛЛМакхО_УнивБин_КопируйОбъДляАрх(ЛЛБинарник BR,
                                                        const char *Arch,
                                                        size_t ArchLen,
                                                        char **ErrorMessage){
  return LLVMMachOUniversalBinaryCopyObjectForArch( BR, Arch, ArchLen, ErrorMessage);
}

/**
 * Retrieve a copy of the section iterator for this object file.
 *
 * If there are no sections, the result is NULL.
 *
 * The returned iterator is merely a shallow copy. Nevertheless, it is
 * the responsibility of the caller to free it with
 * \c LLVMDisposeSectionIterator.
 *
 * @see llvm::object::sections()
 */
LLEXPORT ЛЛИтераторСекций ЛЛОбъФайл_КопируйИтераторВыборки(ЛЛБинарник BR){
  return LLVMObjectFileCopySectionIterator(BR)  ;
}

/**
 * Returns whether the given section iterator is at the end.
 *
 * @see llvm::object::section_end
 */
LLEXPORT ЛЛБул ЛЛОбъФайл_ИтераторВыборкиВКонце_ли(ЛЛБинарник BR,
                                              ЛЛИтераторСекций SI){
  return LLVMObjectFileIsSectionIteratorAtEnd( BR, SI) ;
}

/**
 * Retrieve a copy of the symbol iterator for this object file.
 *
 * If there are no symbols, the result is NULL.
 *
 * The returned iterator is merely a shallow copy. Nevertheless, it is
 * the responsibility of the caller to free it with
 * \c LLVMDisposeSymbolIterator.
 *
 * @see llvm::object::symbols()
 */
LLEXPORT ЛЛСимвИтератор ЛЛОбъФайл_КопируйСимвИтератор(ЛЛБинарник BR){
  return  LLVMObjectFileCopySymbolIterator(BR);
}

/**
 * Returns whether the given symbol iterator is at the end.
 *
 * @see llvm::object::symbol_end
 */
LLEXPORT ЛЛБул ЛЛОбъФайл_СимвИтераторВКонце_ли(ЛЛБинарник BR,
                                             ЛЛСимвИтератор SI){
  return  LLVMObjectFileIsSymbolIteratorAtEnd( BR, SI);
}

LLEXPORT void ЛЛВыместиИтераторСекций(ЛЛИтераторСекций SI){
  return  LLVMDisposeSectionIterator(SI);
}

LLEXPORT void ЛЛПереместисьКСледщСекции(ЛЛИтераторСекций SI){
  return  LLVMMoveToNextSection(SI);
}
LLEXPORT void ЛЛПерместисьКСодержащСекции(ЛЛИтераторСекций Sect,
                                 ЛЛСимвИтератор Sym){
  return  LLVMMoveToContainingSection( Sect, Sym);
}

// ObjectFile Symbol iterators
LLEXPORT void ЛЛВыместиСимвИтератор(ЛЛСимвИтератор SI){
  return  LLVMDisposeSymbolIterator(SI);
}
LLEXPORT void ЛЛПереместисьКСледщСимволу(ЛЛСимвИтератор SI){
  return  LLVMMoveToNextSymbol(SI);
}

// SectionRef accessors
LLEXPORT const char *ЛЛДайИмяСекции(ЛЛИтераторСекций SI){
  return  LLVMGetSectionName(SI);
}
LLEXPORT uint64_t ЛЛДАйРазмСекции(ЛЛИтераторСекций SI){
  return  LLVMGetSectionSize(SI);
}
LLEXPORT const char *ЛЛДайСодержимоеСекции(ЛЛИтераторСекций SI){
  return  LLVMGetSectionContents(SI);
}
LLEXPORT uint64_t ЛЛДайАдресСекции(ЛЛИтераторСекций SI){
  return  LLVMGetSectionAddress(SI);
}
LLEXPORT ЛЛБул ЛЛСодержитСекцияСимвол_ли(ЛЛИтераторСекций SI,
                                 ЛЛСимвИтератор Sym){
  return  LLVMGetSectionContainsSymbol( SI, Sym);
}

// Section Relocation iterators
LLEXPORT ЛЛИтераторРелокаций ЛЛДайРелокации(ЛЛИтераторСекций Section){
  return  LLVMGetRelocations(Section);
}

LLEXPORT void ЛЛВыместиИтераторРелокаций(ЛЛИтераторРелокаций RI){
	LLVMDisposeRelocationIterator(RI);
}

LLEXPORT ЛЛБул ЛЛИтераторРелокацийВКонце_ли(ЛЛИтераторСекций Section,
                                       ЛЛИтераторРелокаций RI){
  return  LLVMIsRelocationIteratorAtEnd(Section, RI);
}
LLEXPORT void ЛЛПереместисьКСледщРелокации(ЛЛИтераторРелокаций RI){
  return  LLVMMoveToNextRelocation(RI);
}


// SymbolRef accessors
LLEXPORT const char *ЛЛДайИмяСимвола(ЛЛСимвИтератор SI){
  return  LLVMGetSymbolName(SI);
}
LLEXPORT uint64_t ЛЛДайАдресСимвола(ЛЛСимвИтератор SI){
  return  LLVMGetSymbolAddress(SI);
}
LLEXPORT uint64_t ЛЛДайРазмСимвола(ЛЛСимвИтератор SI){
  return  LLVMGetSymbolSize(SI);
}

// RelocationRef accessors
LLEXPORT uint64_t ЛЛДайСмещениеРелокации(ЛЛИтераторРелокаций RI){
  return  LLVMGetRelocationOffset(RI);
}
LLEXPORT ЛЛСимвИтератор ЛЛДайСимволРелокации(ЛЛИтераторРелокаций RI){
  return LLVMGetRelocationSymbol(RI);
}
LLEXPORT uint64_t ЛЛДайТипРелокации(ЛЛИтераторРелокаций RI){
  return LLVMGetRelocationType(RI);
}
// NOTE: Caller takes ownership of returned string of the two
// following functions.
LLEXPORT const char *ЛЛДайИмяТипаРелокации(ЛЛИтераторРелокаций RI){
  return  LLVMGetRelocationTypeName(RI);
}
LLEXPORT const char *ЛЛДайТкстЗначенияРелокации(ЛЛИтераторРелокаций RI){
  return  LLVMGetRelocationValueString(RI);
}

/** Deprecated: Use LLVMCreateBinary instead. */
LLEXPORT ЛЛФайлОбъекта ЛЛСоздайФайлОбъекта(LLVMMemoryBufferRef MemBuf){
  return LLVMCreateObjectFile(MemBuf) ;
}

/** Deprecated: Use LLVMDisposeBinary instead. */
LLEXPORT void ЛЛВыместиФайлОбъекта(ЛЛФайлОбъекта ObjectFile){
  return  LLVMDisposeObjectFile( ObjectFile);
}
/** Deprecated: Use LLVMObjectFileCopySectionIterator instead. */
LLEXPORT ЛЛИтераторСекций ЛЛДайСекции(ЛЛФайлОбъекта ObjectFile){
  return  LLVMGetSections(ObjectFile);
}
/** Deprecated: Use LLVMObjectFileIsSectionIteratorAtEnd instead. */
LLEXPORT ЛЛБул ЛЛИтераторСекцииВКонце_ли(ЛЛФайлОбъекта ObjectFile,
                                    ЛЛИтераторСекций SI){
  return  LLVMIsSectionIteratorAtEnd( ObjectFile, SI);
}

/** Deprecated: Use LLVMObjectFileCopySymbolIterator instead. */
LLEXPORT ЛЛСимвИтератор ЛЛДайСимволы(ЛЛФайлОбъекта ObjectFile){
  return  LLVMGetSymbols(ObjectFile);
}

/** Deprecated: Use LLVMObjectFileIsSymbolIteratorAtEnd instead. */
LLEXPORT ЛЛБул ЛЛСимвИтераторВКонце_ли(ЛЛФайлОбъекта ObjectFile,
                                   ЛЛСимвИтератор SI){
  return  LLVMIsSymbolIteratorAtEnd( ObjectFile, SI);
}
/**
 * @}
 */


}

