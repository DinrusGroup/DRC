
extern "C" {
#include "Header.h"

/**
 * Read LLVM IR from a memory buffer and convert it into an in-memory Module
 * object. Returns 0 on success.
 * Optionally returns a human-readable description of any errors that
 * occurred during parsing IR. OutMessage must be disposed with
 * LLVMDisposeMessage.
 *
 * @see llvm::ParseIR()
 */
LLEXPORT LLVMBool ЛЛПарсируйППВКонтексте(ЛЛКонтекст ContextRef,
                              ЛЛБуферПамяти MemBuf, ЛЛМодуль *OutM,
                              char **OutMessage){
	return LLVMParseIRInContext(ContextRef,MemBuf, OutM, OutMessage);
}

}
