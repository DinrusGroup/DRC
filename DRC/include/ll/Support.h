
extern "C" {
#include "Header.h"

/**
 * This function permanently loads the dynamic library at the given path.
 * It is safe to call this function multiple times for the same library.
 *
 * @see sys::DynamicLibrary::LoadLibraryPermanently()
  */
LLEXPORT ЛЛБул ЛЛГрузиБибПерманентно(const char* Filename);

/**
 * This function parses the given arguments using the LLVM command line parser.
 * Note that the only stable thing about this function is its signature; you
 * cannot rely on any particular set of command line arguments being interpreted
 * the same way across LLVM versions.
 *
 * @see llvm::cl::ParseCommandLineOptions()
 */
LLEXPORT void ЛЛРазбериОпцКомСтроки(int argc, const char *const *argv,
                                 const char *Overview);

/**
 * This function will search through all previously loaded dynamic
 * libraries for the symbol \p symbolName. If it is found, the address of
 * that symbol is returned. If not, null is returned.
 *
 * @see sys::DynamicLibrary::SearchForAddressOfSymbol()
 */
LLEXPORT void *ЛЛНайдиАдресСимвола(const char *symbolName);

/**
 * This functions permanently adds the symbol \p symbolName with the
 * value \p symbolValue.  These symbols are searched before any
 * libraries.
 *
 * @see sys::DynamicLibrary::AddSymbol()
 */
LLEXPORT void ЛЛДобавьСимвол(const char *symbolName, void *symbolValue);


}

