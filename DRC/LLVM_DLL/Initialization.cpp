extern "C" {
#include "Header.h"
/**
 * @defgroup LLVMCInitialization Initialization Routines
 * @ingroup LLVMC
 *
 * This module contains routines used to initialize the LLVM system.
 *
 * @{
 */

LLEXPORT void ЛЛИницЯдро(ЛЛРеестрПроходок R){
	LLVMInitializeCore(R);
}
LLEXPORT void ЛЛИницТрансформУтил(ЛЛРеестрПроходок R){
	LLVMInitializeTransformUtils(R);
}
LLEXPORT void ЛЛИницСкалярОпц(ЛЛРеестрПроходок R){
	LLVMInitializeScalarOpts(R);
}
LLEXPORT void ЛЛИницОпцОбджСиАРЦ(ЛЛРеестрПроходок R){
	LLVMInitializeObjCARCOpts(R);
}
LLEXPORT void ЛЛИницВекторизацию(ЛЛРеестрПроходок R){
	LLVMInitializeVectorization(R);
}
LLEXPORT void ЛЛИНицИнстКомбин(ЛЛРеестрПроходок R){
	LLVMInitializeInstCombine(R);
}
LLEXPORT void ЛЛИницАгрессивнИнстКомбайнер(ЛЛРеестрПроходок R){
	LLVMInitializeAggressiveInstCombiner(R);
}
LLEXPORT void ЛЛИницМПО(ЛЛРеестрПроходок R){
	LLVMInitializeIPO(R);
}
LLEXPORT void ЛЛИницИнструментацию(ЛЛРеестрПроходок R){
	LLVMInitializeInstrumentation(R);
}
LLEXPORT void ЛЛИницАнализ(ЛЛРеестрПроходок R){
	LLVMInitializeAnalysis(R);
}
LLEXPORT void ЛЛИницМПА(ЛЛРеестрПроходок R){
	LLVMInitializeIPA(R);
}
LLEXPORT void ЛЛИницКодГен(ЛЛРеестрПроходок R){
	LLVMInitializeCodeGen(R);
}
LLEXPORT void ЛЛИницЦель(ЛЛРеестрПроходок R){
	LLVMInitializeTarget(R);
}

/**
 * @}
 */


}

