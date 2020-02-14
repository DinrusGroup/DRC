
extern "C" {
#include "Header.h"

/** Returns the first llvm::Target in the registered targets list. */
LLEXPORT ЛЛЦель ЛЛДайПервЦель(void){
return LLVMGetFirstTarget();
}
/** Returns the next llvm::Target given a previous one (or null if there's none) */
LLEXPORT ЛЛЦель ЛЛДайСледщЦель(ЛЛЦель T){
return LLVMGetNextTarget(T);
}

/*===-- Target ------------------------------------------------------------===*/
/** Finds the target corresponding to the given name and stores it in \p T.
  Returns 0 on success. */
LLEXPORT ЛЛЦель ЛЛДайЦельИзИмени(const char *Name){
return LLVMGetTargetFromName(Name);
}

/** Finds the target corresponding to the given triple and stores it in \p T.
  Returns 0 on success. Optionally returns any error in ErrorMessage.
  Use LLVMDisposeMessage to dispose the message. */
LLEXPORT LLVMBool ЛЛДайЦельИзТриады(const char* Triple, ЛЛЦель *T,
                                 char **ErrorMessage){
return LLVMGetTargetFromTriple(Triple,T, ErrorMessage);
}

/** Returns the name of a target. See llvm::Target::getName */
LLEXPORT const char *ЛЛДайИмяЦели(ЛЛЦель T){
return LLVMGetTargetName(T);
}

/** Returns the description  of a target. See llvm::Target::getDescription */
LLEXPORT const char *ЛЛДайОписаниеЦели(ЛЛЦель T){
return LLVMGetTargetDescription(T);
}

/** Returns if the target has a JIT */
LLEXPORT LLVMBool ЛЛЦель_ЕстьДжИТ_ли(ЛЛЦель T){
return LLVMTargetHasJIT(T);
}

/** Returns if the target has a TargetMachine associated */
LLEXPORT LLVMBool ЛЛЦель_ЕстьЦелМаш_ли(ЛЛЦель T){
return LLVMTargetHasTargetMachine(T);
}

/** Returns if the target as an ASM backend (required for emitting output) */
LLEXPORT LLVMBool ЛЛЦель_ЕстьАсмБэкэнд_ли(ЛЛЦель T){
return LLVMTargetHasAsmBackend(T);
}

/*===-- Target Machine ----------------------------------------------------===*/
/** Creates a new llvm::TargetMachine. See llvm::Target::createTargetMachine */
LLEXPORT ЛЛЦелеваяМашина ЛЛСоздайЦелМаш(ЛЛЦель T,
  const char *Triple, const char *CPU, const char *Features,
  LLVMCodeGenOptLevel Level, LLVMRelocMode Reloc, LLVMCodeModel CodeModel){
return LLVMCreateTargetMachine( T,Triple,CPU, Features, Level, Reloc, CodeModel);
}

/** Dispose the ЛЛЦелеваяМашина instance generated by
  LLVMCreateTargetMachine. */
LLEXPORT void ЛЛВыместиЦелМаш(ЛЛЦелеваяМашина T){
return LLVMDisposeTargetMachine(T);
}

/** Returns the Target used in a TargetMachine */
LLEXPORT ЛЛЦель ЛЛДайЦельЦелМаш(ЛЛЦелеваяМашина T){
return LLVMGetTargetMachineTarget(T);
}

/** Returns the triple used creating this target machine. See
  llvm::TargetMachine::getTriple. The result needs to be disposed with
  LLVMDisposeMessage. */
LLEXPORT char *ЛЛДайТриадуЦелМаш(ЛЛЦелеваяМашина T){
return LLVMGetTargetMachineTriple(T);
}

/** Returns the cpu used creating this target machine. See
  llvm::TargetMachine::getCPU. The result needs to be disposed with
  LLVMDisposeMessage. */
LLEXPORT char *ЛЛДайЦПБЦелМаш(ЛЛЦелеваяМашина T){
return LLVMGetTargetMachineCPU(T);
}

/** Returns the feature string used creating this target machine. See
  llvm::TargetMachine::getFeatureString. The result needs to be disposed with
  LLVMDisposeMessage. */
LLEXPORT char *ЛЛДайТкстФичЦелМаш(ЛЛЦелеваяМашина T){
return LLVMGetTargetMachineFeatureString(T);
}

/** Create a DataLayout based on the targetMachine. */
LLEXPORT LLVMTargetDataRef ЛЛСоздайРаскладкуДанЦели(ЛЛЦелеваяМашина T){
return LLVMCreateTargetDataLayout(T);
}

/** Set the target machine's ASM verbosity. */
LLEXPORT void ЛЛУстЦелМашАсмВербозность(ЛЛЦелеваяМашина T,
                                      LLVMBool VerboseAsm){
return LLVMSetTargetMachineAsmVerbosity( T, VerboseAsm);
}

/** Emits an asm or object file for the given module to the filename. This
  wraps several c++ only classes (among them a file stream). Returns any
  error in ErrorMessage. Use LLVMDisposeMessage to dispose the message. */
LLEXPORT LLVMBool ЛЛЦелМашГенерируйВФайл(ЛЛЦелеваяМашина T, LLVMModuleRef M,
  char *Filename, LLVMCodeGenFileType codegen, char **ErrorMessage){
return LLVMTargetMachineEmitToFile(T, M,Filename, codegen, ErrorMessage);
}

/** Compile the LLVM IR stored in \p M and store the result in \p OutMemBuf. */
LLEXPORT LLVMBool ЛЛЦелМашГенерируйВБуфПам(ЛЛЦелеваяМашина T, LLVMModuleRef M,
  LLVMCodeGenFileType codegen, char** ErrorMessage, LLVMMemoryBufferRef *OutMemBuf){
return LLVMTargetMachineEmitToMemoryBuffer( T,  M, codegen, ErrorMessage, OutMemBuf);
}

/*===-- Triple ------------------------------------------------------------===*/
/** Get a triple for the host machine as a string. The result needs to be
  disposed with LLVMDisposeMessage. */
LLEXPORT char* ЛЛДайДефТриадуЦели(void){
return LLVMGetDefaultTargetTriple();
}

/** Normalize a target triple. The result needs to be disposed with
  LLVMDisposeMessage. */
LLEXPORT char* ЛЛНормализуйТриадуЦели(const char* triple){
return LLVMNormalizeTargetTriple(triple);
}

/** Get the host CPU as a string. The result needs to be disposed with
  LLVMDisposeMessage. */
LLEXPORT char* ЛЛДайИмяЦПБХоста(void){
return LLVMGetHostCPUName();
}

/** Get the host CPU's features as a string. The result needs to be disposed
  with LLVMDisposeMessage. */
LLEXPORT char* ЛЛДайФичиЦПБХоста(void){
return LLVMGetHostCPUFeatures();
}

/** Adds the target-specific analysis passes to the pass manager. */
LLEXPORT void ЛЛДобавьПроходкуАнализа(ЛЛЦелеваяМашина T, LLVMPassManagerRef PM){
return LLVMAddAnalysisPasses( T, PM);
}

}

