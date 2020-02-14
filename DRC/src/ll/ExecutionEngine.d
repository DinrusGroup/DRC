
module ll.ExecutionEngine;

import ll.Target, ll.TargetMachine, ll.Types;


extern (C){

/**
 * @defgroup LLVMCExecutionEngine Движок Выполнения
 * @ingroup LLVMC
 *
 * @{
 */

проц LLVMLinkInMCJIT();
проц LLVMLinkInInterpreter();

struct LLVMOpaqueGenericValue{}
struct LLVMOpaqueExecutionEngine{}
struct LLVMOpaqueMCJITMemoryManager{}
alias LLVMOpaqueGenericValue *ЛЛГенерноеЗначение;
alias LLVMOpaqueExecutionEngine *ЛЛДвижокВыполнения;
alias LLVMOpaqueMCJITMemoryManager *ЛЛМенеджерПамятиМЦДжИТ;

struct ЛЛОпцииКомпиляцииМЦДжИТ {
  бцел урОпц;
  LLVMCodeModel CodeModel;
  ЛЛБул NoFramePointerElim;
  ЛЛБул EnableFastISel;
  ЛЛМенеджерПамятиМЦДжИТ MCJMM;
};

/*===-- Операции над генерными значениями--------------------------------------===*/

ЛЛГенерноеЗначение ЛЛСоздайГенЗначЦел(ЛЛТип тип, бдол чло, ЛЛБул соЗнаком_ли);
ЛЛГенерноеЗначение ЛЛСоздайГенЗначУк(ук укз);
ЛЛГенерноеЗначение ЛЛСоздайГенЗначПлав(ЛЛТип тип, дво чло);
бцел ЛЛШиринаГенЗначЦел(ЛЛГенерноеЗначение генЗнач);
бдол ЛЛГенЗначВЦел(ЛЛГенерноеЗначение генЗнач, ЛЛБул соЗнаком_ли);
ук ЛЛГенЗначВУк(ЛЛГенерноеЗначение генЗнач);
дво ЛЛГенЗначВПлав(ЛЛТип тип, ЛЛГенерноеЗначение генЗнач);
проц ЛЛВыместиГенЗнач(ЛЛГенерноеЗначение генЗнач);

/*===-- Операции над движками выполнения -----------------------------------===*/

ЛЛБул ЛЛСоздайДвижВыпДляМодуля(ЛЛДвижокВыполнения *OutEE, ЛЛМодуль мод, ткст0 *выхОш);
ЛЛБул ЛЛСоздайИнтерпретаторДляМодуля(ЛЛДвижокВыполнения *OutInterp, ЛЛМодуль мод, ткст0 *выхОш);
ЛЛБул ЛЛСоздайДжИТКомпиляторДляМодуля(ЛЛДвижокВыполнения *выхДжИТ, ЛЛМодуль мод,бцел урОпц, ткст0 *выхОш);
проц ЛЛИнициализуйОпцииМЦДжИТКомпилятора(ЛЛОпцииКомпиляцииМЦДжИТ *опции,т_мера размОпц);

/**
 * Create an MCJIT execution engine for a module, with the given options. It is
 * the responsibility of the caller to ensure that all fields in опции up to
 * the given размОпц are initialized. It is correct to pass a smaller
 * знач of размОпц that omits some fields. The canonical way of using
 * this is:
 *
 * ЛЛОпцииКомпиляцииМЦДжИТ options;
 * LLVMInitializeMCJITCompilerOptions(&options, sizeof(options));
 * ... fill in those options you care about
 * LLVMCreateMCJITCompilerForModule(&jit, mod, &options, sizeof(options),
 *                                  &error);
 *
 * Note that this is also correct, though possibly suboptimal:
 *
 * LLVMCreateMCJITCompilerForModule(&jit, mod, 0, 0, &error);
 */
ЛЛБул ЛЛСоздайМЦДжИТКомпиляторДляМодуля( ЛЛДвижокВыполнения *выхДжИТ, ЛЛМодуль мод,
  ЛЛОпцииКомпиляцииМЦДжИТ *опции, т_мера размОпц, ткст0 *выхОш);

проц ЛЛВыместиДвижВып(ЛЛДвижокВыполнения движВып);
проц ЛЛВыполниСтатичКонструкторы(ЛЛДвижокВыполнения движВып);
проц ЛЛВыполниСтатичДеструкторы(ЛЛДвижокВыполнения движВып);

цел ЛЛВыполниФункцКакГлавную(ЛЛДвижокВыполнения движВып, ЛЛЗначение ф,
                          бцел ArgC, ткст0 *ArgV, ткст0 *EnvP);

ЛЛГенерноеЗначение ЛЛВыполниФункц(ЛЛДвижокВыполнения движВып, ЛЛЗначение ф,
                                    бцел члоАргов,
                                    ЛЛГенерноеЗначение *арги);

проц ЛЛОсвободиМашКодДляФункции(ЛЛДвижокВыполнения движВып, ЛЛЗначение ф);

проц ЛЛДобавьМодуль(ЛЛДвижокВыполнения движВып, ЛЛМодуль мод);

ЛЛБул ЛЛУдалиМодуль(ЛЛДвижокВыполнения движВып, ЛЛМодуль мод,
                          ЛЛМодуль *выхМод, ткст0 *выхОш);

ЛЛБул ЛЛНайдиФункцию(ЛЛДвижокВыполнения движВып, ткст0 имя,
                          ЛЛЗначение *выхФн);

ук ЛЛРекомпилИРекомпонуйФункц(ЛЛДвижокВыполнения движВып,
                                     ЛЛЗначение фн);

ЛЛДанныеОЦели ЛЛДайДанОЦелиДвижВыпа(ЛЛДвижокВыполнения движВып);
ЛЛЦелеваяМашина
ЛЛДайЦелМашДвигВыпа(ЛЛДвижокВыполнения движВып);

проц ЛЛДобавьГлобМаппинг(ЛЛДвижокВыполнения движВып, ЛЛЗначение глоб,
                          ук адр);

ук ЛЛДайУкзНаГлоб(ЛЛДвижокВыполнения движВып, ЛЛЗначение глоб);

бдол ЛЛДайАдрГлобЗнач(ЛЛДвижокВыполнения движВып, ткст0 имя);

бдол ЛЛДайАдрФункц(ЛЛДвижокВыполнения движВып, ткст0 имя);

/*===-- Операции над менеджерами памяти-------------------------------------===*/


    //LLVMMemoryManagerAllocateCodeSectionCallback
    alias ббайт* function(
        ук опак, uintptr_t разм, бцел расклад, бцел идСекц,
        ткст0 имяСекц) ЛЛОбрвызМенеджерПамРазместиСекциюКода;

    //LLVMMemoryManagerAllocateDataSectionCallback
    alias ббайт* function(
        ук опак, uintptr_t разм, бцел расклад, бцел идСекц,
        ткст0 имяСекц, ЛЛБул толькоЧтен_ли) ЛЛОбрвызМенеджерПамРазместиСекциюДанных;

    //LLVMMemoryManagerFinalizeMemoryCallback
    alias ЛЛБул function(ук опак, char** ошСооб) ЛЛОбрвызМенеджерПамФинализуйПам;

    //LLVMMemoryManagerDestroyCallback
    alias проц function(ук опак) ЛЛОбрвызМенеджерПамРазрушь;

/**
 * Create a simple custom MCJIT memory manager. This memory manager can
 * intercept allocations in a module-oblivious way. This will return NULL
 * if any of the passed functions are NULL.
 *
 * @param Opaque An opaque client object to pass back to the callbacks.
 * @param AllocateCodeSection Allocate a блок of memory for executable code.
 * @param AllocateDataSection Allocate a блок of memory for data.
 * @param FinalizeMemory Set page permissions and flush cache. Return 0 on
 *   success, 1 on error.
 */
ЛЛМенеджерПамятиМЦДжИТ ЛЛСоздайПростойМенеджерПамМЦДжИТ(
  ук опак,
  ЛЛОбрвызМенеджерПамРазместиСекциюКода разместСекцКода,
  ЛЛОбрвызМенеджерПамРазместиСекциюДанных разместСекцДан,
  ЛЛОбрвызМенеджерПамФинализуйПам финализПам,
  ЛЛОбрвызМенеджерПамРазрушь разруш);

проц ЛЛВыместиМенеджерПамМЦДжИТ(ЛЛМенеджерПамятиМЦДжИТ MM);

/*===-- JIT Event Listener functions -------------------------------------===*/

ЛЛДатчикСобытийДжит ЛЛСоздайДатчикРегистрацииГДБ();
ЛЛДатчикСобытийДжит ЛЛСоздайДатчикДжИТСобытийИнтел();
ЛЛДатчикСобытийДжит ЛЛСоздайДатчикДжИТСобытийОПрофайл();
ЛЛДатчикСобытийДжит ЛЛСоздайДатчикДжИТСобытийПерф();


}