

extern "C" {

#include "Header.h"

    /*===-- Operations on modules ---------------------------------------------===*/

    LLEXPORT int ЛЛПишиБиткодВФайл(ЛЛМодуль M, const char* Path) {
        return LLVMWriteBitcodeToFile(M, Path);
    }

    LLEXPORT int ЛЛПишиБиткодВФД(ЛЛМодуль M, int FD, int ShouldClose,
        int Unbuffered) {

        return LLVMWriteBitcodeToFD(M, FD, ShouldClose, Unbuffered);
    }

    LLEXPORT int ЛЛПишиБиткодВФайлУк(ЛЛМодуль M, int FileHandle) {
        return LLVMWriteBitcodeToFD(M, FileHandle, true, false);
    }

    LLEXPORT ЛЛБуферПамяти ЛЛПишиБиткодВБуфПамяти(ЛЛМодуль M) {
        return LLVMWriteBitcodeToMemoryBuffer(M);
    }
}