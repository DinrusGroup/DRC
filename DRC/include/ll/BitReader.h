
extern "C" {

#include "Header.h"

    LLEXPORT ЛЛБул ЛЛРазбериБиткод(ЛЛБуферПамяти MemBuf, ЛЛМодуль* OutModule,
        char** OutMessage) ;

    LLEXPORT ЛЛБул ЛЛРазбериБиткод2(ЛЛБуферПамяти MemBuf,
        ЛЛМодуль* OutModule) ;

    LLEXPORT ЛЛБул ЛЛРазбериБиткодВКонтексте(ЛЛКонтекст ContextRef,
        ЛЛБуферПамяти MemBuf, ЛЛМодуль* OutModule,  char** OutMessage) ;

    LLEXPORT ЛЛБул ЛЛРазбериБиткодВКонтексте2(ЛЛКонтекст ContextRef,
        ЛЛБуферПамяти MemBuf, ЛЛМодуль* OutModule);

    /* Reads a module from the specified path, returning via the OutModule parameter
       a module provider which performs lazy deserialization. Returns 0 on success.
       Optionally returns a human-readable error message via OutMessage. */
    LLEXPORT ЛЛБул ЛЛДайБиткодМодульВКонтексте(ЛЛКонтекст ContextRef,
        ЛЛБуферПамяти MemBuf,
        ЛЛМодуль* OutM, char** OutMessage) ;

    LLEXPORT ЛЛБул ЛЛДайБиткодМодульВКонтексте2(ЛЛКонтекст ContextRef,
        ЛЛБуферПамяти MemBuf,
        ЛЛМодуль* OutM);

    LLEXPORT ЛЛБул ЛЛДайБиткодМодуль(ЛЛБуферПамяти MemBuf, ЛЛМодуль* OutM,
        char** OutMessage);

    LLEXPORT ЛЛБул ЛЛДайБиткодМодуль2(ЛЛБуферПамяти MemBuf,
        ЛЛМодуль* OutM);
}