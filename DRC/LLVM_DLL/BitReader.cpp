
extern "C" {

#include "Header.h"


    /* Builds a module from the bitcode in the specified memory buffer, returning a
       reference to the module via the OutModule parameter. Returns 0 on success.
       Optionally returns a human-readable error message via OutMessage. */
    LLEXPORT ЛЛБул ЛЛРазбериБиткод(ЛЛБуферПамяти MemBuf, ЛЛМодуль* OutModule,
        char** OutMessage) {
        return LLVMParseBitcode(MemBuf, OutModule, OutMessage);
    }

    LLEXPORT ЛЛБул ЛЛРазбериБиткод2(ЛЛБуферПамяти MemBuf,
        ЛЛМодуль* OutModule) {
        return LLVMParseBitcode2(MemBuf, OutModule);
    }

    LLEXPORT ЛЛБул ЛЛРазбериБиткодВКонтексте(ЛЛКонтекст ContextRef,
        ЛЛБуферПамяти MemBuf, ЛЛМодуль* OutModule,  char** OutMessage) {
        return LLVMParseBitcodeInContext(ContextRef, MemBuf, OutModule, OutMessage);
    }

    LLEXPORT ЛЛБул ЛЛРазбериБиткодВКонтексте2(ЛЛКонтекст ContextRef,
        ЛЛБуферПамяти MemBuf, ЛЛМодуль* OutModule) {
        return LLVMParseBitcodeInContext2(ContextRef, MemBuf, OutModule);
    }

    /* Reads a module from the specified path, returning via the OutModule parameter
       a module provider which performs lazy deserialization. Returns 0 on success.
       Optionally returns a human-readable error message via OutMessage. */
    LLEXPORT ЛЛБул ЛЛДайБиткодМодульВКонтексте(ЛЛКонтекст ContextRef,
        ЛЛБуферПамяти MemBuf,
        ЛЛМодуль* OutM, char** OutMessage) {
        return LLVMGetBitcodeModuleInContext(ContextRef, MemBuf, OutM, OutMessage);
    }

    LLEXPORT ЛЛБул ЛЛДайБиткодМодульВКонтексте2(ЛЛКонтекст ContextRef,
        ЛЛБуферПамяти MemBuf,
        ЛЛМодуль* OutM) {
        return LLVMGetBitcodeModuleInContext2(ContextRef, MemBuf, OutM);
    }

    LLEXPORT ЛЛБул ЛЛДайБиткодМодуль(ЛЛБуферПамяти MemBuf, ЛЛМодуль* OutM,
        char** OutMessage) {
        return LLVMGetBitcodeModule(MemBuf, OutM, OutMessage);
    }

    LLEXPORT ЛЛБул ЛЛДайБиткодМодуль2(ЛЛБуферПамяти MemBuf,
        ЛЛМодуль* OutM) {
        return LLVMGetBitcodeModule2(MemBuf, OutM);
    }
}