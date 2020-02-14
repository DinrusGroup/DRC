extern "C"
{
#include "Header.h"

LLEXPORT  проц LLLinkInMCJIT(проц);
LLEXPORT    проц LLLinkInInterpreter(проц);

    // Операции над генерными значениями

LLEXPORT    ЛЛГенерноеЗначение ЛЛСоздайГенЗначЦел(ЛЛТип Ty, бдол N, ЛЛБул IsSigned);
LLEXPORT    ЛЛГенерноеЗначение ЛЛСоздайГенЗначУк(ук P);
LLEXPORT   ЛЛГенерноеЗначение ЛЛСоздайГенЗначПлав(ЛЛТип Ty, double N);
LLEXPORT   unsigned ЛЛШиринаГенЗначЦел(ЛЛГенерноеЗначение GenValRef);
LLEXPORT   бдол ЛЛГенЗначВЦел(ЛЛГенерноеЗначение GenVal,
        ЛЛБул IsSigned);
LLEXPORT    ук ЛЛГенЗначВУк(ЛЛГенерноеЗначение GenVal);
LLEXPORT    double ЛЛГенЗначВПлав(ЛЛТип TyRef, ЛЛГенерноеЗначение GenVal);
LLEXPORT   проц ЛЛВыместиГенЗнач(ЛЛГенерноеЗначение GenVal);

    // Операции над движками выполнения 

LLEXPORT   ЛЛБул ЛЛСоздайДвижВыпДляМодуля(ЛЛДвижокВыполнения  *OutEE,
        ЛЛМодуль M, char** OutError);
LLEXPORT   ЛЛБул ЛЛСоздайИнтерпретаторДляМодуля(ЛЛДвижокВыполнения  *OutInterp,
        ЛЛМодуль M, char** OutError);
LLEXPORT    ЛЛБул ЛЛСоздайДжИТКомпиляторДляМодуля(ЛЛДвижокВыполнения  *OutJIT,
        ЛЛМодуль M, unsigned OptLevel, char** OutError);
LLEXPORT    проц ЛЛИнициализуйОпцииМЦДжИТКомпилятора(
         ЛЛОпцииКомпиляцииМЦДжИТ опции, size_t размОпц);

    /**
     * Создать движок выполнения MCJIT execution engine for a module, with the given опции. It is
     * the responsibility of the caller to ensure that all fields in опции up to
     * the given размОпц are initialized. It is correct to pass a smaller
     * value of размОпц that omits some fields. The canonical way of using
     * this is:
     *
     * ЛЛОпцииКомпиляцииМЦДжИТ опции;
     * LLVMInitializeMCJITCompilerопции(&опции, sizeof(опции));
     * ... fill in those опции you care about
     * LLVMCreateMCJITCompilerForModule(&jit, mod, &опции, sizeof(опции),
     *                                  &error);
     *
     * Note that this is also correct, though possibly suboptimal:
     *
     * LLVMCreateMCJITCompilerForModule(&jit, mod, 0, 0, &error);
     */
LLEXPORT    ЛЛБул ЛЛСоздайМЦДжИТКомпиляторДляМодуля(
        ЛЛДвижокВыполнения *OutJIT, ЛЛМодуль M,
         ЛЛОпцииКомпиляцииМЦДжИТ опции, size_t размОпц,
        char** OutError);
LLEXPORT  проц ЛЛВыместиДвижВып(ЛЛДвижокВыполнения дв);
LLEXPORT     проц ЛЛВыполниСтатичКонструкторы(ЛЛДвижокВыполнения дв);
LLEXPORT     проц ЛЛВыполниСтатичДеструкторы(ЛЛДвижокВыполнения дв);
LLEXPORT    int ЛЛВыполниФункцКакГлавную(ЛЛДвижокВыполнения дв, ЛЛЗначение F,
        unsigned ArgC, ткст0 const* ArgV,
        ткст0 const* EnvP);
LLEXPORT     ЛЛГенерноеЗначение ЛЛВыполниФункц(ЛЛДвижокВыполнения дв, ЛЛЗначение F,
        unsigned NumArgs, ЛЛГенерноеЗначение * Args);
LLEXPORT   проц ЛЛОсвободиМашКодДляФункции(ЛЛДвижокВыполнения дв, ЛЛЗначение F);
LLEXPORT  проц ЛЛДобавьМодуль(ЛЛДвижокВыполнения дв, ЛЛМодуль M);
LLEXPORT    ЛЛБул ЛЛУдалиМодуль(ЛЛДвижокВыполнения дв, ЛЛМодуль M,
        ЛЛМодуль * OutMod, char** OutError);
LLEXPORT   ЛЛБул ЛЛНайдиФункцию(ЛЛДвижокВыполнения дв, ткст0 Name,
        ЛЛЗначение * OutFn);
LLEXPORT  ук ЛЛРекомпилИРекомпонуйФункц(ЛЛДвижокВыполнения дв,
        ЛЛЗначение Fn);
LLEXPORT   LLVMTargetDataRef ЛЛДайДанОЦелиДвижВыпа(ЛЛДвижокВыполнения дв);
LLEXPORT     ЛЛЦелеваяМашина
        ЛЛДайЦелМашДвигВыпа(ЛЛДвижокВыполнения дв);
LLEXPORT    проц ЛЛДобавьГлобМаппинг(ЛЛДвижокВыполнения дв, ЛЛЗначение Global,
        ук Addr);
LLEXPORT     ук ЛЛДайУкзНаГлоб(ЛЛДвижокВыполнения дв, ЛЛЗначение Global);
LLEXPORT     uint64_t ЛЛДайАдрГлобЗнач(ЛЛДвижокВыполнения дв, ткст0 Name);
LLEXPORT    uint64_t ЛЛДайАдрФункц(ЛЛДвижокВыполнения дв, ткст0 Name);

    // Операции над менеджерами памяти

    /**
     * Create a simple custom MCJIT memory manager. This memory manager can
     * intercept allocations in a module-oblivious way. This will return NULL
     * if any of the passed functions are NULL.
     *
     * @param Opaque An opaque client object to pass back to the callbacks.
     * @param AllocateCodeSection Allocate a block of memory for executable code.
     * @param AllocateDataSection Allocate a block of memory for data.
     * @param FinalizeMemory Set page permissions and flush cache. Return 0 on
     *   success, 1 on error.
     */
LLEXPORT   ЛЛМенеджерПамятиМЦДжИТ ЛЛСоздайПростойМенеджерПамМЦДжИТ(
        ук Opaque,
        ЛЛОбрвызМенеджерПамРазместиСекциюКода AllocateCodeSection,
        ЛЛОбрвызМенеджерПамРазместиСекциюДанных AllocateDataSection,
        ЛЛОбрвызМенеджерПамФинализуйПам FinalizeMemory,
        ЛЛОбрвызМенеджерПамРазрушь Destroy);
LLEXPORT     проц ЛЛВыместиМенеджерПамМЦДжИТ(ЛЛМенеджерПамятиМЦДжИТ MM);

    //JIT Event Listener functions

LLEXPORT   LLVMJITEventListenerRef ЛЛСоздайДатчикРегистрацииГДБ(проц);
LLEXPORT    LLVMJITEventListenerRef ЛЛСоздайДатчикДжИТСобытийИнтел(проц);
LLEXPORT   LLVMJITEventListenerRef ЛЛСоздайДатчикДжИТСобытийОПрофайл(проц);
LLEXPORT  LLVMJITEventListenerRef ЛЛСоздайДатчикДжИТСобытийПерф(проц);

}