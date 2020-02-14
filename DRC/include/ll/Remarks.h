
extern "C" {

#include "Header.h"

/**
 * Returns the buffer holding the string.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT const char *ЛЛТкстРемарки_ДайДанные(ЛЛТкстРемарки String);

/**
 * Returns the size of the string.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT uint32_t ЛЛТкстРемарки_ДайДлину(ЛЛТкстРемарки String);

/**
 * Return the path to the source file for a debug location.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT ЛЛТкстРемарки
ЛЛОтладЛокРемарки_ДайПутьКИсходнику(ЛЛОтладЛокРемарки DL);

/**
 * Return the line in the source file for a debug location.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT uint32_t ЛЛОтладЛокРемарки_ДайСтрокуИсходника(ЛЛОтладЛокРемарки DL);

/**
 * Return the column in the source file for a debug location.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT uint32_t ЛЛОтладЛокРемарки_ДайСтолбецИсходника(ЛЛОтладЛокРемарки DL);

/**
 * Returns the key of an argument. The key defines what the value is, and the
 * same key can appear multiple times in the list of arguments.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT ЛЛТкстРемарки ЛЛАргРемарки_ДайКлюч(ЛЛАргРемарки Arg);

/**
 * Returns the value of an argument. This is a string that can contain newlines.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT ЛЛТкстРемарки ЛЛАргРемарки_ДайЗначение(ЛЛАргРемарки Arg);

/**
 * Returns the debug location that is attached to the value of this argument.
 *
 * If there is no debug location, the return value will be `NULL`.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT ЛЛОтладЛокРемарки ЛЛАргРемарки_ДайОтладЛок(ЛЛАргРемарки Arg);


/**
 * Free the resources used by the remark entry.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT void ЛЛЗаписьРемарки_Вымести(ЛЛЗаписьРемарки Remark);

/**
 * The type of the remark. For example, it can allow users to only keep the
 * missed optimizations from the compiler.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT enum LLVMRemarkType ЛЛЗаписьРемарки_ДайТип(ЛЛЗаписьРемарки Remark);

/**
 * Get the name of the pass that emitted this remark.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT ЛЛТкстРемарки
ЛЛЗаписьРемарки_ДайИмяПроходки(ЛЛЗаписьРемарки Remark);

/**
 * Get an identifier of the remark.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT ЛЛТкстРемарки
ЛЛЗаписьРемарки_ДайИмяРемарки(ЛЛЗаписьРемарки Remark);
/**
 * Get the name of the function being processed when the remark was emitted.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT ЛЛТкстРемарки
ЛЛЗаписьРемарки_ДайИмяФункции(ЛЛЗаписьРемарки Remark);

/**
 * Returns the debug location that is attached to this remark.
 *
 * If there is no debug location, the return value will be `NULL`.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT ЛЛОтладЛокРемарки
ЛЛЗаписьРемарки_ДайОтладЛок(ЛЛЗаписьРемарки Remark);

/**
 * Return the hotness of the remark.
 *
 * A hotness of `0` means this value is not set.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT uint64_t ЛЛЗаписьРемарки_ДайАктуальность(ЛЛЗаписьРемарки Remark);

/**
 * The number of arguments the remark holds.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT uint32_t ЛЛЗаписьРемарки_ДайЧлоАргов(ЛЛЗаписьРемарки Remark);

/**
 * Get a new iterator to iterate over a remark's argument.
 *
 * If there are no arguments in \p Remark, the return value will be `NULL`.
 *
 * The lifetime of the returned value is bound to the lifetime of \p Remark.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT ЛЛАргРемарки ЛЛЗаписьРемарки_ДайПервАрг(ЛЛЗаписьРемарки Remark);

/**
 * Get the next argument in \p Remark from the position of \p It.
 *
 * Returns `NULL` if there are no more arguments available.
 *
 * The lifetime of the returned value is bound to the lifetime of \p Remark.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT ЛЛАргРемарки ЛЛЗаписьРемарки_ДайСледщАрг(ЛЛАргРемарки It,
                                                  ЛЛЗаписьРемарки Remark);


/**
 * Creates a remark parser that can be used to parse the buffer located in \p
 * Buf of size \p Size bytes.
 *
 * \p Buf cannot be `NULL`.
 *
 * This function should be paired with LLVMRemarkParserDispose() to avoid
 * leaking resources.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT ЛЛПарсерРемарок ЛЛПарсерРемарок_СоздайЙАМЛ(const void *Buf,
                                                      uint64_t Size);

/**
 * Returns the next remark in the file.
 *
 * The value pointed to by the return value needs to be disposed using a call to
 * LLVMRemarkEntryDispose().
 *
 * All the entries in the returned value that are of ЛЛТкстРемарки type
 * will become invalidated once a call to LLVMRemarkParserDispose is made.
 *
 * If the parser reaches the end of the buffer, the return value will be `NULL`.
 *
 * In the case of an error, the return value will be `NULL`, and:
 *
 * 1) LLVMRemarkParserHasError() will return `1`.
 *
 * 2) LLVMRemarkParserGetErrorMessage() will return a descriptive error
 *    message.
 *
 * An error may occur if:
 *
 * 1) An argument is invalid.
 *
 * 2) There is a parsing error. This can occur on things like malformed YAML.
 *
 * 3) There is a Remark semantic error. This can occur on well-formed files with
 *    missing or extra fields.
 *
 * Here is a quick example of the usage:
 *
 * ```
 * ЛЛПарсерРемарок Parser = LLVMRemarkParserCreateYAML(Buf, Size);
 * ЛЛЗаписьРемарки Remark = NULL;
 * while ((Remark = LLVMRemarkParserGetNext(Parser))) {
 *    // use Remark
 *    LLVMRemarkEntryDispose(Remark); // Release memory.
 * }
 * bool HasError = LLVMRemarkParserHasError(Parser);
 * LLVMRemarkParserDispose(Parser);
 * ```
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT ЛЛЗаписьРемарки ЛЛПарсерРемарок_ДайСледщ(ЛЛПарсерРемарок Parser);

/**
 * Returns `1` if the parser encountered an error while parsing the buffer.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT LLVMBool ЛЛПарсерРемарок_ЕстьОш_ли(ЛЛПарсерРемарок Parser);

/**
 * Returns a null-terminated string containing an error message.
 *
 * In case of no error, the result is `NULL`.
 *
 * The memory of the string is bound to the lifetime of \p Parser. If
 * LLVMRemarkParserDispose() is called, the memory of the string will be
 * released.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT const char *ЛЛПарсерРемарок_ДайОшСооб(ЛЛПарсерРемарок Parser);

/**
 * Releases all the resources used by \p Parser.
 *
 * \since REMARKS_API_VERSION=0
 */
LLEXPORT void ЛЛПарсерРемарок_Вымести(ЛЛПарсерРемарок Parser);

/**
 * Returns the version of the remarks library.
 *
 * \since REMARKS_API_VERSION=0
 */
/*
LLEXPORT uint32_t LLRemarkVersion(void){
return LLVMRemarkVersion();
}
*/
/**
 * @} // endgoup LLVMCREMARKS
 */

}

