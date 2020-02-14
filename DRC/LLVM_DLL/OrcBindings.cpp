
extern "C" {
#include "Header.h"

/**
 * Create an ORC JIT stack.
 *
 * The client owns the resulting stack, and must call OrcDisposeInstance(...)
 * to destroy it and free its memory. The JIT stack will take ownership of the
 * TargetMachine, which will be destroyed when the stack is destroyed. The
 * client should not attempt to dispose of the Target Machine, or it will result
 * in a double-free.
 */
LLEXPORT LLVMOrcJITStackRef ЛЛОрк_СоздайЭкземпляр(LLVMTargetMachineRef TM){
return LLVMOrcCreateInstance(TM);
}

/**
 * Get the error message for the most recent error (if any).
 *
 * This message is owned by the ORC JIT Stack and will be freed when the stack
 * is disposed of by LLVMOrcDisposeInstance.
 */
LLEXPORT const char *ЛЛОрк_ДайОшСооб(LLVMOrcJITStackRef JITStack){
return LLVMOrcGetErrorMsg(JITStack);
}

/**
 * Mangle the given symbol.
 * Memory will be allocated for MangledSymbol to hold the result. The client
 */
LLEXPORT void ЛЛОрк_ДайДекорирСимвол(LLVMOrcJITStackRef JITStack, char **MangledSymbol,
                             const char *Symbol){
return LLVMOrcGetMangledSymbol(JITStack, MangledSymbol, Symbol);
}

/**
 * Dispose of a mangled symbol.
 */
LLEXPORT void ЛЛОрк_ВыместиДекорирСимвол(char *MangledSymbol){
 LLVMOrcDisposeMangledSymbol(MangledSymbol);
}

/**
 * Create a lazy compile callback.
 */
LLEXPORT LLVMErrorRef ЛЛОрк_ОбрВызЛенивКомпиляции(
    LLVMOrcJITStackRef JITStack, LLVMOrcTargetAddress *RetAddr,
    LLVMOrcLazyCompileCallbackFn Callback, void *CallbackCtx){
return LLVMOrcCreateLazyCompileCallback(
     JITStack, RetAddr, Callback, CallbackCtx);
}
/**
 * Create a named indirect call stub.
 */
LLEXPORT LLVMErrorRef ЛЛОрк_СоздайНепрямСтаб(LLVMOrcJITStackRef JITStack,
                                       const char *StubName,
                                       LLVMOrcTargetAddress InitAddr){
return LLVMOrcCreateIndirectStub( JITStack,StubName, InitAddr);
}
/**
 * Set the pointer for the given indirect stub.
 */
LLEXPORT LLVMErrorRef ЛЛОрк_УстУкзНаНепрямСтаб(LLVMOrcJITStackRef JITStack,
                                           const char *StubName,
                                           LLVMOrcTargetAddress NewAddr){
return LLVMOrcSetIndirectStubPointer(JITStack, StubName, NewAddr);
}

/**
 * Add module to be eagerly compiled.
 */
LLEXPORT LLVMErrorRef ЛЛОрк_ДобавьАктивноКомпилирПП(LLVMOrcJITStackRef JITStack,
                                         LLVMOrcModuleHandle *RetHandle,
                                         LLVMModuleRef Mod,
                                         LLVMOrcSymbolResolverFn SymbolResolver,
                                         void *SymbolResolverCtx){
return LLVMOrcAddEagerlyCompiledIR( JITStack,RetHandle, Mod,SymbolResolver,
                                         SymbolResolverCtx);
}
/**
 * Add module to be lazily compiled one function at a time.
 */
LLEXPORT LLVMErrorRef ЛЛОрк_ДобавьЛенивоКомпилирПП(LLVMOrcJITStackRef JITStack,
                                        LLVMOrcModuleHandle *RetHandle,
                                        LLVMModuleRef Mod,
                                        LLVMOrcSymbolResolverFn SymbolResolver,
                                        void *SymbolResolverCtx){
return LLVMOrcAddLazilyCompiledIR(JITStack,RetHandle, Mod, SymbolResolver,
                                        SymbolResolverCtx);
}

/**
 * Add an object file.
 *
 * This method takes ownership of the given memory buffer and attempts to add
 * it to the JIT as an object file.
 * Clients should *not* dispose of the 'Obj' argument: the JIT will manage it
 * from this call onwards.
 */
LLEXPORT LLVMErrorRef ЛЛОрк_ДобавьФайлОбъекта(LLVMOrcJITStackRef JITStack,
                                  LLVMOrcModuleHandle *RetHandle,
                                  LLVMMemoryBufferRef Obj,
                                  LLVMOrcSymbolResolverFn SymbolResolver,
                                  void *SymbolResolverCtx){
return LLVMOrcAddObjectFile(JITStack,RetHandle, Obj, SymbolResolver,SymbolResolverCtx);
}

/**
 * Remove a module set from the JIT.
 *
 * This works for all modules that can be added via OrcAdd*, including object
 * files.
 */
LLEXPORT LLVMErrorRef ЛЛОрк_УдалиМодуль(LLVMOrcJITStackRef JITStack,
                                 LLVMOrcModuleHandle H){
return LLVMOrcRemoveModule( JITStack, H);
}
/**
 * Get symbol address from JIT instance.
 */
LLEXPORT LLVMErrorRef ЛЛОрк_ДайАдресСимвола(LLVMOrcJITStackRef JITStack,
                                     LLVMOrcTargetAddress *RetAddr,
                                     const char *SymbolName){
return LLVMOrcGetSymbolAddress(JITStack, RetAddr, SymbolName);
}
/**
 * Get symbol address from JIT instance, searching only the specified
 * handle.
 */
LLEXPORT LLVMErrorRef ЛЛОрк_ДайАдресСимволаЭкз(LLVMOrcJITStackRef JITStack,
                                       LLVMOrcTargetAddress *RetAddr,
                                       LLVMOrcModuleHandle H,
                                       const char *SymbolName){
return LLVMOrcGetSymbolAddressIn( JITStack, RetAddr, H, SymbolName);
}

/**
 * Dispose of an ORC JIT stack.
 */
LLEXPORT LLVMErrorRef ЛЛОрк_ВыместиЭкземпляр(LLVMOrcJITStackRef JITStack){
return LLVMOrcDisposeInstance(JITStack);
}
/**
 * Register a JIT Event Listener.
 *
 * A NULL listener is ignored.
 */
LLEXPORT void ЛЛОрк_ЗарегистрируйДатчикСобытийДжИТ(LLVMOrcJITStackRef JITStack,
                                             LLVMJITEventListenerRef L){
return LLVMOrcRegisterJITEventListener( JITStack, L);
}

/**
 * Unegister a JIT Event Listener.
 *
 * A NULL listener is ignored.
 */
LLEXPORT void ЛЛОрк_ОтрегистрируйДатчикСобытийДжИТ(LLVMOrcJITStackRef JITStack,
                                           LLVMJITEventListenerRef L){
return LLVMOrcUnregisterJITEventListener( JITStack, L);
}

}

