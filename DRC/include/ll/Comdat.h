
extern "C" {

#include "Header.h"

    LLEXPORT ЛЛКомдат ЛЛДайИлиВставьКомдат(ЛЛМодуль M, const char* Name) ;
    LLEXPORT ЛЛКомдат ЛЛДайКомдат(ЛЛЗначение V) ;
    LLEXPORT void ЛЛУстКомдат(ЛЛЗначение V, ЛЛКомдат C);
    LLEXPORT LLVMComdatSelectionKind ЛЛДайТипВыбораКомдат(ЛЛКомдат C);
    LLEXPORT void ЛЛУстТипВыбораКомдат(ЛЛКомдат C, LLVMComdatSelectionKind kind);
}