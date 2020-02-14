
extern "C" {

#include "Header.h"


    LLEXPORT ЛЛКомдат ЛЛДайИлиВставьКомдат(ЛЛМодуль M, const char* Name) {
        return LLVMGetOrInsertComdat(M, Name);
    }

    LLEXPORT ЛЛКомдат ЛЛДайКомдат(ЛЛЗначение V) {
        return LLVMGetComdat(V);
    }

    LLEXPORT void ЛЛУстКомдат(ЛЛЗначение V, ЛЛКомдат C) {
        LLVMSetComdat(V, C);
    }

    LLEXPORT LLVMComdatSelectionKind ЛЛДайТипВыбораКомдат(ЛЛКомдат C) {
        return LLVMGetComdatSelectionKind(C);
    }

    LLEXPORT void ЛЛУстТипВыбораКомдат(ЛЛКомдат C, LLVMComdatSelectionKind kind) {
        LLVMSetComdatSelectionKind(C, kind);
    }
}