
extern "C" {
#include "Header.h"


/**
 * @defgroup LLVMCOPTREMARKS OptRemarks
 * @ingroup LLVMC
 *
 * @{
 */


/**
 * Creates a remark parser that can be used to read and parse the buffer located
 * in \p Buf of size \p Size.
 *
 * \p Buf cannot be NULL.
 *
 * This function should be paired with LLVMOptRemarkParserDispose() to avoid
 * leaking resources.
 *
 * \since OPT_REMARKS_API_VERSION=0
 */
LLEXPORT  ЛЛПарсерОптРемарок ЛЛПарсерОптРемарок_Создай(const void *Buf,
                                                        uint64_t Size){
return LLVMOptRemarkParserCreate(Buf, Size);
}

/**
 * Returns the next remark in the file.
 *
 * The value pointed to by the return value is invalidated by the next call to
 * LLVMOptRemarkParserGetNext().
 *
 * If the parser reaches the end of the buffer, the return value will be NULL.
 *
 * In the case of an error, the return value will be NULL, and:
 *
 * 1) LLVMOptRemarkParserHasError() will return `1`.
 *
 * 2) LLVMOptRemarkParserGetErrorMessage() will return a descriptive error
 *    message.
 *
 * An error may occur if:
 *
 * 1) An argument is invalid.
 *
 * 2) There is a YAML parsing error. This type of error aborts parsing
 *    immediately and returns `1`. It can occur on malformed YAML.
 *
 * 3) Remark parsing error. If this type of error occurs, the parser won't call
 *    the handler and will continue to the next one. It can occur on malformed
 *    remarks, like missing or extra fields in the file.
 *
 * Here is a quick example of the usage:
 *
 * ```
 *  ЛЛПарсерОптРемарок Parser = LLVMOptRemarkParserCreate(Buf, Size);
 *  LLVMOptRemarkEntry *Remark = NULL;
 *  while ((Remark == LLVMOptRemarkParserGetNext(Parser))) {
 *    // use Remark
 *  }
 *  bool HasError = LLVMOptRemarkParserHasError(Parser);
 *  LLVMOptRemarkParserDispose(Parser);
 * ```
 *
 * \since OPT_REMARKS_API_VERSION=0
 */
LLEXPORT LLVMOptRemarkEntry *
ЛЛПарсерОптРемарок_ДайСледщ(ЛЛПарсерОптРемарок Parser){
return LLVMOptRemarkParserGetNext(Parser);
}

/**
 * Returns `1` if the parser encountered an error while parsing the buffer.
 *
 * \since OPT_REMARKS_API_VERSION=0
 */
LLEXPORT  ЛЛБул ЛЛПарсерОптРемарок_ЕстьОшибка(ЛЛПарсерОптРемарок Parser){
return LLVMOptRemarkParserHasError(Parser);
}
/**
 * Returns a null-terminated string containing an error message.
 *
 * In case of no error, the result is `NULL`.
 *
 * The memory of the string is bound to the lifetime of \p Parser. If
 * LLVMOptRemarkParserDispose() is called, the memory of the string will be
 * released.
 *
 * \since OPT_REMARKS_API_VERSION=0
 */
LLEXPORT const char *
ЛЛПарсерОптРемарок_ДайОшСооб(ЛЛПарсерОптРемарок Parser){
return LLVMOptRemarkParserGetErrorMessage(Parser) ;
}

/**
 * Releases all the resources used by \p Parser.
 *
 * \since OPT_REMARKS_API_VERSION=0
 */
LLEXPORT void ЛЛПарсерОптРемарок_Вымести(ЛЛПарсерОптРемарок Parser){
LLVMOptRemarkParserDispose( Parser);
}

/**
 * Returns the version of the opt-remarks dylib.
 *
 * \since OPT_REMARKS_API_VERSION=0
 */
LLEXPORT  uint32_t ЛЛВерсияОптРемарок(void){
return LLVMOptRemarkVersion();
}

/**
 * @} // endgoup LLVMCOPTREMARKS
 */


}

