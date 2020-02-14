

extern "C" {

#include "Header.h"

    LLEXPORT int ЛЛПишиБиткодВФайл(ЛЛМодуль M, const char* Path) ;
    LLEXPORT int ЛЛПишиБиткодВФД(ЛЛМодуль M, int FD, int ShouldClose,
        int Unbuffered) ;
    LLEXPORT int ЛЛПишиБиткодВФайлУк(ЛЛМодуль M, int FileHandle) ;
    LLEXPORT ЛЛБуферПамяти ЛЛПишиБиткодВБуфПамяти(ЛЛМодуль M);
}