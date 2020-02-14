
module ll.Remarks;
import ll.Types;

extern (C){

/**
 * @defgroup LLVMCREMARKS Remarks
 * @ingroup LLVMC
 *
 * @{
 */

const REMARKS_API_VERSION = 0;

/**
 * The type of the emitted remark.
 */
enum LLVMRemarkType {
  Unknown,
  Passed,
  Missed,
  Analysis,
  AnalysisFPCommute,
  AnalysisAliasing,
  Failure
};

/**
 * текст containing a buffer and a length. The buffer is not guaranteed to be
 * zero-terminated.
 *
 * \since REMARKS_API_VERSION=0
 */
struct LLVMRemarkOpaqueтекст;
alias LLVMRemarkOpaqueтекст *ЛЛТкстРемарки;

/**
 * Returns the buffer holding the string.
 *
 * \since REMARKS_API_VERSION=0
 */
 ткст0 ЛЛТкстРемарки_ДайДанные(ЛЛТкстРемарки текст);

/**
 * Returns the size of the string.
 *
 * \since REMARKS_API_VERSION=0
 */
 uint32_t ЛЛТкстРемарки_ДайДлину(ЛЛТкстРемарки текст);

/**
 * DebugLoc containing File, Line and Column.
 *
 * \since REMARKS_API_VERSION=0
 */
struct LLVMRemarkOpaqueDebugLoc;
alias LLVMRemarkOpaqueDebugLoc *ЛЛОтладЛокРемарки;

/**
 * Return the path to the source file for a debug location.
 *
 * \since REMARKS_API_VERSION=0
 */
 ЛЛТкстРемарки
ЛЛОтладЛокРемарки_ДайПутьКИсходнику(ЛЛОтладЛокРемарки DL);

/**
 * Return the line in the source file for a debug location.
 *
 * \since REMARKS_API_VERSION=0
 */
 uint32_t ЛЛОтладЛокРемарки_ДайСтрокуИсходника(ЛЛОтладЛокРемарки DL);

/**
 * Return the column in the source file for a debug location.
 *
 * \since REMARKS_API_VERSION=0
 */
 uint32_t ЛЛОтладЛокРемарки_ДайСтолбецИсходника(ЛЛОтладЛокРемарки DL);

/**
 * Element of the "арги" list. The key might give more information about what
 * the semantics of the знач are, e.g. "Callee" will tell you that the знач
 * is a symbol that names a function.
 *
 * \since REMARKS_API_VERSION=0
 */
struct LLVMRemarkOpaqueArg{}
alias LLVMRemarkOpaqueArg *ЛЛАргРемарки;

/**
 * Returns the key of an argument. The key defines what the знач is, and the
 * same key can appear multiple times in the list of arguments.
 *
 * \since REMARKS_API_VERSION=0
 */
 ЛЛТкстРемарки ЛЛАргРемарки_ДайКлюч(ЛЛАргРемарки арг);

/**
 * Returns the знач of an argument. This is a string that can contain newlines.
 *
 * \since REMARKS_API_VERSION=0
 */
 ЛЛТкстРемарки ЛЛАргРемарки_ДайЗначение(ЛЛАргРемарки арг);

/**
 * Returns the debug location that is attached to the знач of this argument.
 *
 * If there is no debug location, the return знач will be `NULL`.
 *
 * \since REMARKS_API_VERSION=0
 */
 ЛЛОтладЛокРемарки ЛЛАргРемарки_ДайОтладЛок(ЛЛАргРемарки арг);

/**
 * атр remark emitted by the compiler.
 *
 * \since REMARKS_API_VERSION=0
 */
struct LLVMRemarkOpaqueEntry{}
alias LLVMRemarkOpaqueEntry *ЛЛЗаписьРемарки;

/**
 * Free the resources used by the remark entry.
 *
 * \since REMARKS_API_VERSION=0
 */
 проц ЛЛЗаписьРемарки_Вымести(ЛЛЗаписьРемарки Remark);

/**
 * The type of the remark. For example, it can allow users to only keep the
 * missed optimizations from the compiler.
 *
 * \since REMARKS_API_VERSION=0
 */
 LLVMRemarkType ЛЛЗаписьРемарки_ДайТип(ЛЛЗаписьРемарки Remark);

/**
 * Get the name of the pass that emitted this remark.
 *
 * \since REMARKS_API_VERSION=0
 */
 ЛЛТкстРемарки
ЛЛЗаписьРемарки_ДайИмяПроходки(ЛЛЗаписьРемарки Remark);

/**
 * Get an identifier of the remark.
 *
 * \since REMARKS_API_VERSION=0
 */
 ЛЛТкстРемарки
ЛЛЗаписьРемарки_ДайИмяРемарки(ЛЛЗаписьРемарки Remark);

/**
 * Get the name of the function being processed when the remark was emitted.
 *
 * \since REMARKS_API_VERSION=0
 */
 ЛЛТкстРемарки
ЛЛЗаписьРемарки_ДайИмяФункции(ЛЛЗаписьРемарки Remark);

/**
 * Returns the debug location that is attached to this remark.
 *
 * If there is no debug location, the return знач will be `NULL`.
 *
 * \since REMARKS_API_VERSION=0
 */
 ЛЛОтладЛокРемарки
ЛЛЗаписьРемарки_ДайОтладЛок(ЛЛЗаписьРемарки Remark);

/**
 * Return the hotness of the remark.
 *
 * атр hotness of `0` means this знач is not set.
 *
 * \since REMARKS_API_VERSION=0
 */
 uint64_t ЛЛЗаписьРемарки_ДайАктуальность(ЛЛЗаписьРемарки Remark);

/**
 * The number of arguments the remark holds.
 *
 * \since REMARKS_API_VERSION=0
 */
 uint32_t ЛЛЗаписьРемарки_ДайЧлоАргов(ЛЛЗаписьРемарки Remark);

/**
 * Get a new iterator to iterate over a remark's argument.
 *
 * If there are no arguments in \p Remark, the return знач will be `NULL`.
 *
 * The lifetime of the returned знач is bound to the lifetime of \p Remark.
 *
 * \since REMARKS_API_VERSION=0
 */
 ЛЛАргРемарки ЛЛЗаписьРемарки_ДайПервАрг(ЛЛЗаписьРемарки Remark);

/**
 * Get the next argument in \p Remark from the position of \p It.
 *
 * Returns `NULL` if there are no more arguments available.
 *
 * The lifetime of the returned знач is bound to the lifetime of \p Remark.
 *
 * \since REMARKS_API_VERSION=0
 */
 ЛЛАргРемарки ЛЛЗаписьРемарки_ДайСледщАрг(ЛЛАргРемарки It,
                                                  ЛЛЗаписьРемарки Remark);

struct LLVMRemarkOpaqueпарсер;
alias LLVMRemarkOpaqueпарсер *ЛЛПарсерРемарок;

/**
 * Creates a remark parser that can be used to parse the buffer located in \p
 * Buf of size \p разм bytes.
 *
 * \p Buf cannot be `NULL`.
 *
 * This function should be paired with LLVMRemarkпарсерDispose() to avoid
 * leaking resources.
 *
 * \since REMARKS_API_VERSION=0
 */
 ЛЛПарсерРемарок ЛЛПарсерРемарок_СоздайЙАМЛ(ук Buf,
                                                      uint64_t разм);

/**
 * Returns the next remark in the file.
 *
 * The знач pointed to by the return знач needs to be disposed using a call to
 * LLVMRemarkEntryDispose().
 *
 * All the entries in the returned знач that are of ЛЛТкстРемарки type
 * will become invalidated once a call to LLVMRemarkпарсерDispose is made.
 *
 * If the parser reaches the end of the buffer, the return знач will be `NULL`.
 *
 * In the case of an error, the return знач will be `NULL`, and:
 *
 * 1) LLVMRemarkпарсерHasError() will return `1`.
 *
 * 2) LLVMRemarkпарсерGetErrorMessage() will return a descriptive error
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
 * ЛЛПарсерРемарок парсер = LLVMRemarkParserCreateYAML(Buf, разм);
 * ЛЛЗаписьРемарки Remark = NULL;
 * while ((Remark = LLVMRemarkParserGetNext(парсер))) {
 *    // use Remark
 *    LLVMRemarkEntryDispose(Remark); // Release memory.
 * }
 * bool HasError = LLVMRemarkParserHasError(парсер);
 * LLVMRemarkParserDispose(парсер);
 * ```
 *
 * \since REMARKS_API_VERSION=0
 */
 ЛЛЗаписьРемарки ЛЛПарсерРемарок_ДайСледщ(ЛЛПарсерРемарок парсер);

/**
 * Returns `1` if the parser encountered an error while parsing the buffer.
 *
 * \since REMARKS_API_VERSION=0
 */
 ЛЛБул ЛЛПарсерРемарок_ЕстьОш_ли(ЛЛПарсерРемарок парсер);

/**
 * Returns a null-terminated string containing an error message.
 *
 * In case of no error, the result is `NULL`.
 *
 * The memory of the string is bound to the lifetime of \p парсер. If
 * LLVMRemarkпарсерDispose() is called, the memory of the string will be
 * released.
 *
 * \since REMARKS_API_VERSION=0
 */
 ткст0 ЛЛПарсерРемарок_ДайОшСооб(ЛЛПарсерРемарок парсер);

/**
 * Releases all the resources used by \p парсер.
 *
 * \since REMARKS_API_VERSION=0
 */
 проц ЛЛПарсерРемарок_Вымести(ЛЛПарсерРемарок парсер);

}
