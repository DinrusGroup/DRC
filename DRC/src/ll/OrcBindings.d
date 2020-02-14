
module ll.OrcBindings;
import ll.Error, ll.Object, ll.TargetMachine;
import ll.Types;

extern (C){

struct LLVMOrcOpaqueJITStack;
alias LLVMOrcOpaqueJITStack *LLVMOrcJITStackRef;
alias uint64_t LLVMOrcModuleHandle;
alias uint64_t LLVMOrcTargetAddress;

alias uint64_t function(ткст0 Name, ук LookupCtx)
	LLVMOrcSymbolResolverFn;

alias uint64_t function(LLVMOrcJITStackRef JITStack,  ук CallbackCtx)
	LLVMOrcLazyCompileCallbackFn;

/**
 * Create an ORC JIT stack.
 *
 * The client owns the resulting stack, and must call OrcDisposeInstance(...)
 * to destroy it and free its memory. The JIT stack will take ownership of the
 * TargetMachine, which will be destroyed when the stack is destroyed. The
 * client should not attempt to dispose of the Target Machine, or it will result
 * in a дво-free.
 */
LLVMOrcJITStackRef ЛЛОрк_СоздайЭкземпляр(ЛЛЦелеваяМашина TM);

/**
 * Get the error message for the most recent error (if any).
 *
 * This message is owned by the ORC JIT Stack and will be freed when the stack
 * is disposed of by LLVMOrcDisposeInstance.
 */
ткст0 ЛЛОрк_ДайОшСооб(LLVMOrcJITStackRef JITStack);

/**
 * Mangle the given symbol.
 * Memory will be allocated for MangledSymbol to hold the result. The client
 */
проц ЛЛОрк_ДайДекорирСимвол(LLVMOrcJITStackRef JITStack, ткст0 *MangledSymbol,
                             ткст0 Symbol);

/**
 * Dispose of a mangled symbol.
 */
проц ЛЛОрк_ВыместиДекорирСимвол(ткст0 MangledSymbol);

/**
 * Create a lazy compile callback.
 */
ЛЛОшибка ЛЛОрк_ОбрВызЛенивКомпиляции(
    LLVMOrcJITStackRef JITStack, LLVMOrcTargetAddress *RetAddr,
    LLVMOrcLazyCompileCallbackFn обрвыз, ук CallbackCtx);

/**
 * Create a named indirect call stub.
 */
ЛЛОшибка ЛЛОрк_СоздайНепрямСтаб(LLVMOrcJITStackRef JITStack,
                                       ткст0 StubName,
                                       LLVMOrcTargetAddress InitAddr);

/**
 * Set the pointer for the given indirect stub.
 */
ЛЛОшибка ЛЛОрк_УстУкзНаНепрямСтаб(LLVMOrcJITStackRef JITStack,
                                           ткст0 StubName,
                                           LLVMOrcTargetAddress NewAddr);

/**
 * Add module to be eagerly compiled.
 */
ЛЛОшибка ЛЛОрк_ДобавьАктивноКомпилирПП(LLVMOrcJITStackRef JITStack,
                                         LLVMOrcModuleHandle *RetHandle,
                                         ЛЛМодуль мод,
                                         LLVMOrcSymbolResolverFn SymbolResolver,
                                         ук SymbolResolverCtx);

/**
 * Add module to be lazily compiled one function at a time.
 */
ЛЛОшибка ЛЛОрк_ДобавьЛенивоКомпилирПП(LLVMOrcJITStackRef JITStack,
                                        LLVMOrcModuleHandle *RetHandle,
                                        ЛЛМодуль мод,
                                        LLVMOrcSymbolResolverFn SymbolResolver,
                                        ук SymbolResolverCtx);

/**
 * Add an object file.
 *
 * This method takes ownership of the given memory buffer and attempts to add
 * it to the JIT as an object file.
 * Clients should *not* dispose of the 'Obj' argument: the JIT will manage it
 * from this call onwards.
 */
ЛЛОшибка ЛЛОрк_ДобавьФайлОбъекта(LLVMOrcJITStackRef JITStack,
                                  LLVMOrcModuleHandle *RetHandle,
                                  ЛЛБуферПамяти Obj,
                                  LLVMOrcSymbolResolverFn SymbolResolver,
                                  ук SymbolResolverCtx);

/**
 * Remove a module set from the JIT.
 *
 * This works for all modules that can be added via OrcAdd*, including object
 * files.
 */
ЛЛОшибка ЛЛОрк_УдалиМодуль(LLVMOrcJITStackRef JITStack,
                                 LLVMOrcModuleHandle H);

/**
 * Get symbol address from JIT instance.
 */
ЛЛОшибка ЛЛОрк_ДайАдресСимвола(LLVMOrcJITStackRef JITStack,
                                     LLVMOrcTargetAddress *RetAddr,
                                     ткст0 SymbolName);

/**
 * Get symbol address from JIT instance, searching only the specified
 * handle.
 */
ЛЛОшибка ЛЛОрк_ДайАдресСимволаЭкз(LLVMOrcJITStackRef JITStack,
                                       LLVMOrcTargetAddress *RetAddr,
                                       LLVMOrcModuleHandle H,
                                       ткст0 SymbolName);

/**
 * Dispose of an ORC JIT stack.
 */
ЛЛОшибка ЛЛОрк_ВыместиЭкземпляр(LLVMOrcJITStackRef JITStack);

/**
 * Register a JIT Event Listener.
 *
 * атр NULL listener is ignored.
 */
проц ЛЛОрк_ЗарегистрируйДатчикСобытийДжИТ(LLVMOrcJITStackRef JITStack, ЛЛДатчикСобытийДжит L);

/**
 * Unegister a JIT Event Listener.
 *
 * атр NULL listener is ignored.
 */
проц ЛЛОрк_ОтрегистрируйДатчикСобытийДжИТ(LLVMOrcJITStackRef JITStack, ЛЛДатчикСобытийДжит L);


}