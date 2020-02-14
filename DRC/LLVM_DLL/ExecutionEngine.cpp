extern "C"
{
#include "Header.h"
    /**
 * @defgroup LLVMCExecutionEngine Движок Выполнения
 * @ingroup LLVMC
 *
 * @{
 */

 LLEXPORT  проц LLLinkInMCJIT(проц){
         LLVMLinkInMCJIT();
    }
 LLEXPORT    проц LLLinkInInterpreter(проц){
         LLVMLinkInInterpreter();
    }

    /*===-- Операции над генерными значениями --------------------------------------===*/

 LLEXPORT    ЛЛГенерноеЗначение ЛЛСоздайГенЗначЦел(ЛЛТип Ty, бдол N, ЛЛБул IsSigned){
        return LLVMCreateGenericValueOfInt( Ty, N, IsSigned);
    }
 LLEXPORT    ЛЛГенерноеЗначение ЛЛСоздайГенЗначУк(ук P){
        return LLVMCreateGenericValueOfPointer( P);
    }
  LLEXPORT   ЛЛГенерноеЗначение ЛЛСоздайГенЗначПлав(ЛЛТип Ty, double N){
        return LLVMCreateGenericValueOfFloat( Ty,  N);
    }
  LLEXPORT   unsigned ЛЛШиринаГенЗначЦел(ЛЛГенерноеЗначение GenValRef){
        return LLVMGenericValueIntWidth(GenValRef);
    }
  LLEXPORT   бдол ЛЛГенЗначВЦел(ЛЛГенерноеЗначение GenVal,
        ЛЛБул IsSigned){
        return LLVMGenericValueToInt(GenVal, IsSigned);
    }
 LLEXPORT    ук ЛЛГенЗначВУк(ЛЛГенерноеЗначение GenVal){
        return LLVMGenericValueToPointer(GenVal);
    }
 LLEXPORT    double ЛЛГенЗначВПлав(ЛЛТип TyRef, ЛЛГенерноеЗначение GenVal){
        return LLVMGenericValueToFloat( TyRef, GenVal);
    }
  LLEXPORT   проц ЛЛВыместиГенЗнач(ЛЛГенерноеЗначение GenVal){
         LLVMDisposeGenericValue(GenVal);
    }
    /*===-- Операции над движками выполнения -----------------------------------===*/

  LLEXPORT   ЛЛБул ЛЛСоздайДвижВыпДляМодуля(ЛЛДвижокВыполнения  *OutEE,
        ЛЛМодуль M, char** OutError){
        return LLVMCreateExecutionEngineForModule(OutEE, M,  OutError);
    }
  LLEXPORT   ЛЛБул ЛЛСоздайИнтерпретаторДляМодуля(ЛЛДвижокВыполнения  *OutInterp,
        ЛЛМодуль M, char** OutError){
        return LLVMCreateInterpreterForModule(OutInterp, M, OutError);
    }
 LLEXPORT    ЛЛБул ЛЛСоздайДжИТКомпиляторДляМодуля(ЛЛДвижокВыполнения  *OutJIT,
        ЛЛМодуль M, unsigned OptLevel, char** OutError){
        return LLVMCreateJITCompilerForModule( OutJIT, M, OptLevel, OutError);
    }
 LLEXPORT    проц ЛЛИнициализуйОпцииМЦДжИТКомпилятора(
         ЛЛОпцииКомпиляцииМЦДжИТ опции, size_t размОпц){
         LLVMInitializeMCJITCompilerOptions( опции,  размОпц);
    }
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
        char** OutError){
        return LLVMCreateMCJITCompilerForModule( OutJIT, M, опции,  размОпц, OutError);
    }
   LLEXPORT  проц ЛЛВыместиДвижВып(ЛЛДвижокВыполнения дв){
         LLVMDisposeExecutionEngine(дв);
    }
LLEXPORT     проц ЛЛВыполниСтатичКонструкторы(ЛЛДвижокВыполнения дв){
         LLVMRunStaticConstructors(дв);
    }
LLEXPORT     проц ЛЛВыполниСтатичДеструкторы(ЛЛДвижокВыполнения дв){
         LLVMRunStaticDestructors( дв);
    }
 LLEXPORT    int ЛЛВыполниФункцКакГлавную(ЛЛДвижокВыполнения дв, ЛЛЗначение F,
        unsigned ArgC, ткст0 const* ArgV,
        ткст0 const* EnvP){
        return LLVMRunFunctionAsMain( дв,  F, ArgC,  ArgV, EnvP);
    }
LLEXPORT     ЛЛГенерноеЗначение ЛЛВыполниФункц(ЛЛДвижокВыполнения дв, ЛЛЗначение F,
        unsigned NumArgs, ЛЛГенерноеЗначение * Args){
        return LLVMRunFunction(дв,  F, NumArgs,  Args);
    }
  LLEXPORT   проц ЛЛОсвободиМашКодДляФункции(ЛЛДвижокВыполнения дв, ЛЛЗначение F){
         LLVMFreeMachineCodeForFunction( дв, F);
    }
   LLEXPORT  проц ЛЛДобавьМодуль(ЛЛДвижокВыполнения дв, ЛЛМодуль M){
         LLVMAddModule( дв,  M);
    }
 LLEXPORT    ЛЛБул ЛЛУдалиМодуль(ЛЛДвижокВыполнения дв, ЛЛМодуль M,
        ЛЛМодуль * OutMod, char** OutError){
        return LLVMRemoveModule(дв, M, OutMod, OutError);
    }
  LLEXPORT   ЛЛБул ЛЛНайдиФункцию(ЛЛДвижокВыполнения дв, ткст0 Name,
        ЛЛЗначение * OutFn){
        return LLVMFindFunction(дв, Name, OutFn);
    }
   LLEXPORT  ук ЛЛРекомпилИРекомпонуйФункц(ЛЛДвижокВыполнения дв,
        ЛЛЗначение Fn){
        return LLVMRecompileAndRelinkFunction( дв, Fn);
    }
  LLEXPORT   LLVMTargetDataRef ЛЛДайДанОЦелиДвижВыпа(ЛЛДвижокВыполнения дв){
                return LLVMGetExecutionEngineTargetData( дв);
    }
LLEXPORT     ЛЛЦелеваяМашина
        ЛЛДайЦелМашДвигВыпа(ЛЛДвижокВыполнения дв){
        return LLVMGetExecutionEngineTargetMachine(дв);
    }
 LLEXPORT    проц ЛЛДобавьГлобМаппинг(ЛЛДвижокВыполнения дв, ЛЛЗначение Global,
        ук Addr){
        LLVMAddGlobalMapping( дв, Global, Addr) ;
    }
LLEXPORT     ук ЛЛДайУкзНаГлоб(ЛЛДвижокВыполнения дв, ЛЛЗначение Global){
        return LLVMGetPointerToGlobal( дв, Global);
    }
LLEXPORT     uint64_t ЛЛДайАдрГлобЗнач(ЛЛДвижокВыполнения дв, ткст0 Name){
        return LLVMGetGlobalValueAddress(дв, Name);
    }
 LLEXPORT    uint64_t ЛЛДайАдрФункц(ЛЛДвижокВыполнения дв, ткст0 Name){
        return LLVMGetFunctionAddress( дв,  Name);
    }
    /*===-- Operations on memory managers -------------------------------------===*/

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
        ЛЛОбрвызМенеджерПамРазрушь Destroy){
        return LLVMCreateSimpleMCJITMemoryManager( Opaque, AllocateCodeSection,
         AllocateDataSection, FinalizeMemory, Destroy);
    }
LLEXPORT     проц ЛЛВыместиМенеджерПамМЦДжИТ(ЛЛМенеджерПамятиМЦДжИТ MM){
        return LLVMDisposeMCJITMemoryManager(MM);
    }
    /*===-- JIT Event Listener functions -------------------------------------===*/

  LLEXPORT   LLVMJITEventListenerRef ЛЛСоздайДатчикРегистрацииГДБ(проц){
                return LLVMCreateGDBRegistrationListener();
    }
 LLEXPORT    LLVMJITEventListenerRef ЛЛСоздайДатчикДжИТСобытийИнтел(проц){
                return LLVMCreateIntelJITEventListener();
    }
  LLEXPORT   LLVMJITEventListenerRef ЛЛСоздайДатчикДжИТСобытийОПрофайл(проц){
                return LLVMCreateOProfileJITEventListener();
    }
   LLEXPORT  LLVMJITEventListenerRef ЛЛСоздайДатчикДжИТСобытийПерф(проц){
                return LLVMCreatePerfJITEventListener();
    }
}