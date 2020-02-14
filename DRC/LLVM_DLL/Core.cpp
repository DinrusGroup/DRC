

extern "C"{
#include "Header.h"



LLEXPORT void ЛЛШатдаун(void){
	LLVMShutdown();
}

// Обработка ошибок

LLEXPORT char* ЛЛCоздайCообщение(const char* Message){
return LLVMCreateMessage(Message);
}

LLEXPORT void ЛЛВыместиСообщение(char* Message){
	LLVMDisposeMessage(Message);
}

// Операции над контекстом 

//static ManagedStatic<LLContext> GlobalContext;

LLEXPORT ЛЛКонтекст ЛЛКонтекстСоздай(void){
	return LLVMContextCreate();
}

LLEXPORT ЛЛКонтекст ЛЛДайГлобКонтекст(void){
	return LLVMGetGlobalContext();
}

LLEXPORT void ЛЛКонтекстУстОбработчикДиагностики(ЛЛКонтекст C,
    ЛЛОбработчикДиагностики Handler,
    void* DiagnosticContext){
LLVMContextSetDiagnosticHandler	(C,Handler, DiagnosticContext)	;
}

LLEXPORT ЛЛОбработчикДиагностики ЛЛКонтекстДайОбработчикДиагностики(ЛЛКонтекст C){
return LLVMContextGetDiagnosticHandler(C);
}

LLEXPORT void* ЛЛКонтекстДайКонтекстДиагностики(ЛЛКонтекст C){
return LLVMContextGetDiagnosticContext(C);
}
 
LLEXPORT void ЛЛКонтекстУстОбрвызовЖни(ЛЛКонтекст C, ЛЛОбрвызовЖни Callback,
    void* OpaqueHandle){
LLVMContextSetYieldCallback(C, (LLVMYieldCallback) Callback, OpaqueHandle);
	}
	
LLEXPORT LLVMBool ЛЛКонтекстСбрасыватьИменаЗначений_ли(ЛЛКонтекст C){
return LLVMContextShouldDiscardValueNames(C);
}

LLEXPORT void ЛЛКонтекстУстСбросИмёнЗначений(ЛЛКонтекст C, LLVMBool Discard){
LLVMContextSetDiscardValueNames(C, Discard);
}

LLEXPORT void ЛЛКонтекстВымести(ЛЛКонтекст C){
LLVMContextDispose(C);
}

LLEXPORT unsigned ЛЛДайИДТипаМДВКонтексте(ЛЛКонтекст C, const char* Name,
    unsigned SLen){
	return LLVMGetMDKindIDInContext(C, Name, SLen);
}
	
LLEXPORT unsigned ЛЛДайИДТипаМД(const char* Name, unsigned SLen){
return LLVMGetMDKindID(Name, SLen);
}

LLEXPORT unsigned ЛЛДайТипАтрибутаПеречняДляИмени(const char* Name, size_t SLen){
return LLVMGetEnumAttributeKindForName(Name, SLen);
}

LLEXPORT unsigned ЛЛДайТипПоследнАтрибутаПеречня(void){
return LLVMGetLastEnumAttributeKind();
}

LLEXPORT ЛЛАтрибут ЛЛСоздайАтрибутПеречня(ЛЛКонтекст C, unsigned KindID, uint64_t Val){
return LLVMCreateEnumAttribute(C, KindID, Val);
}
	
LLEXPORT unsigned ЛЛДайТипАтрибутаПеречня(ЛЛАтрибут A){
return LLVMGetEnumAttributeKind(A);
}
LLEXPORT uint64_t ЛЛДайЗначениеАтрибутаПеречня(ЛЛАтрибут A){
	return LLVMGetEnumAttributeValue(A);
}

LLEXPORT ЛЛАтрибут ЛЛСоздайТкстАтрибут(ЛЛКонтекст C,
                                           const char *K, unsigned KLength,
                                           const char *V, unsigned VLength){
return LLVMCreateStringAttribute(C, K, KLength, V, VLength);
 }											   

LLEXPORT const char* ЛЛДайТипТкстАтрибута(ЛЛАтрибут A, unsigned* Length){
	return LLVMGetStringAttributeKind(A, Length);
}

LLEXPORT const char* ЛЛДайЗначениеТкстАтрибута(ЛЛАтрибут A,  unsigned* Length){
return LLVMGetStringAttributeValue(A, Length);
}

LLEXPORT LLVMBool ЛЛАтрибутПеречня_ли(ЛЛАтрибут A){return LLVMIsEnumAttribute(A);}

LLEXPORT LLVMBool ЛЛТкстАтрибут_ли(ЛЛАтрибут A){return LLVMIsStringAttribute(A);}

LLEXPORT char* ЛЛДайОписаниеДиагИнфо(ЛЛИнфоДиагностики DI){
	return LLVMGetDiagInfoDescription(DI);
}

LLEXPORT LLVMDiagnosticSeverity ЛЛДайСтрогостьДиагИнфо(ЛЛИнфоДиагностики DI){
	return LLVMGetDiagInfoSeverity(DI);
}

// Операции над модулями 

LLEXPORT ЛЛМодуль ЛЛМодуль_СоздайСИменем(const char *ModuleID) {
return LLVMModuleCreateWithName(ModuleID);
}

LLEXPORT ЛЛМодуль ЛЛМодуль_СоздайСИменемВКонтексте(const char* ModuleID,
    ЛЛКонтекст C) {
    return LLVMModuleCreateWithNameInContext(ModuleID, C);
}

LLEXPORT void ЛЛВыместиМодуль(ЛЛМодуль M) {
    LLVMDisposeModule(M);
}

LLEXPORT const char *ЛЛДайИдентификаторМодуля(ЛЛМодуль M, size_t *Len){
    return LLVMGetModuleIdentifier(M, Len);
}
LLEXPORT void ЛЛУстИдентификаторМодуля(ЛЛМодуль M, const char* Ident, size_t Len) {
    LLVMSetModuleIdentifier(M, Ident, Len);
}
LLEXPORT const char *ЛЛДайИмяИсходника(ЛЛМодуль M, size_t *Len) {
    return LLVMGetSourceFileName(M, Len);
}
LLEXPORT void ЛЛУстИмяИсходника(ЛЛМодуль M, const char* Name, size_t Len) {
    LLVMSetSourceFileName(M, Name, Len);
}
// Раскладка данных 
LLEXPORT const char *ЛЛДайСтрРаскладкиДанных(ЛЛМодуль M){
    return LLVMGetDataLayoutStr(M);
}
LLEXPORT const char *ЛЛДайРаскладкуДанных(ЛЛМодуль M) {
    return LLVMGetDataLayout(M);
}
LLEXPORT void ЛЛУстРаскладкуДанных(ЛЛМодуль M, const char* DataLayoutStr) {
    LLVMSetDataLayout(M, DataLayoutStr);
}
//--.. Target triple
LLEXPORT const char * ЛЛДайЦель(ЛЛМодуль M){
    return LLVMGetTarget(M);
}
LLEXPORT void ЛЛУстЦель(ЛЛМодуль M, const char* Triple) {
    LLVMSetTarget(M, Triple);
}

// Флаги модуля

LLEXPORT ЛЛЗаписьФлагаМодуля *ЛЛКопируйМетаданныеФлаговМодуля(ЛЛМодуль M, size_t *Len) {
    return LLVMCopyModuleFlagsMetadata(M, Len);
}
LLEXPORT void ЛЛВыместиМетаданныеФлаговМодуля(ЛЛЗаписьФлагаМодуля* Entries) {
    LLVMDisposeModuleFlagsMetadata(Entries);
}

LLEXPORT LLVMModuleFlagBehavior
ЛЛЗаписиФлаговМодуля_ДайПоведениеФлага(ЛЛЗаписьФлагаМодуля *Entries,
                                     unsigned Index){
    return LLVMModuleFlagEntriesGetFlagBehavior(Entries, Index);
}
LLEXPORT const char* ЛЛЗаписиФлаговМодуля_ДайКлюч(ЛЛЗаписьФлагаМодуля* Entries,
    unsigned Index, size_t* Len){
    return LLVMModuleFlagEntriesGetKey(Entries, Index, Len);
}
LLEXPORT ЛЛМетаданные ЛЛЗаписиФлаговМодуля_ДайМетаданные(ЛЛЗаписьФлагаМодуля *Entries,
                                                 unsigned Index) {
    return LLVMModuleFlagEntriesGetMetadata(Entries, Index);
}
LLEXPORT ЛЛМетаданные ЛЛДайФлагМодуля(ЛЛМодуль M,
                                  const char *Key, size_t KeyLen){
    return LLVMGetModuleFlag(M, Key, KeyLen);
}
LLEXPORT void ЛЛДобавьФлагМодуля(ЛЛМодуль M, LLVMModuleFlagBehavior Behavior,
    const char* Key, size_t KeyLen,
    ЛЛМетаданные Val) {
    LLVMAddModuleFlag( M, Behavior, Key, KeyLen, Val);
}

// Вывод модулей

    LLEXPORT void ЛЛДампМодуля(ЛЛМодуль M) {
        LLVMDumpModule(M);
    }

LLEXPORT LLVMBool ЛЛВыведиМодульВФайл(ЛЛМодуль M, const char *Filename,
                               char **ErrorMessage) {
    return LLVMPrintModuleToFile(M, Filename, ErrorMessage);
}
LLEXPORT char *ЛЛВыведиМодульВСтроку(ЛЛМодуль M){
    return LLVMPrintModuleToString(M);
}
// Операции над инлайн-ассемблером 
LLEXPORT void ЛЛУстИнлайнАсмМодуля2(ЛЛМодуль M, const char* Asm, size_t Len) {
    LLVMSetModuleInlineAsm2(M, Asm, Len);
}

    LLEXPORT void ЛЛУстИнлайнАсмМодуля(ЛЛМодуль M, const char* Asm) {
        LLVMSetModuleInlineAsm(M, Asm);
    }

    LLEXPORT void ЛЛПриставьИнлайнАсмМодуля(ЛЛМодуль M, const char* Asm, size_t Len) {
        LLVMAppendModuleInlineAsm(M, Asm, Len);
    }
LLEXPORT const char *ЛЛДайИнлайнАсмМодуля(ЛЛМодуль M, size_t *Len) {
    return LLVMGetModuleInlineAsm(M, Len);
}
LLEXPORT ЛЛЗначение ЛЛДайИнлайнАсм(ЛЛТип Ty,
                              char *AsmString, size_t AsmStringSize,
                              char *Constraints, size_t ConstraintsSize,
                              LLVMBool HasSideEffects, LLVMBool IsAlignStack,
                              LLVMInlineAsmDialect Dialect){
    return LLVMGetInlineAsm(Ty, AsmString, AsmStringSize,
        Constraints, ConstraintsSize, HasSideEffects, IsAlignStack, Dialect);
}

// Операции над модульными контекстами
LLEXPORT ЛЛКонтекст ЛЛДайКонтекстМодуля(ЛЛМодуль M){
    return LLVMGetModuleContext(M);
}
// Операции над всеми типами (в основном)

LLEXPORT LLVMTypeKind ЛЛДайРодТипа(ЛЛТип Ty) {
    return LLVMGetTypeKind(Ty);
}
LLEXPORT LLVMBool ЛЛТипСРазмером_ли(ЛЛТип Ty){
    return LLVMTypeIsSized(Ty);
}
LLEXPORT ЛЛКонтекст ЛЛДайКонтекстТипа(ЛЛТип Ty) {
    return LLVMGetTypeContext(Ty);
}
LLEXPORT void ЛЛДампТипа(ЛЛТип Ty) {
    LLVMDumpType(Ty);
}

LLEXPORT char *ЛЛВыведиТипВСтроку(ЛЛТип Ty){
    return LLVMPrintTypeToString(Ty);
}


// Операции над целочисленными типами

LLEXPORT ЛЛТип ЛЛТипЦел1ВКонтексте(ЛЛКонтекст C){
    return LLVMInt1TypeInContext(C);
}
LLEXPORT ЛЛТип ЛЛТипЦел8ВКонтексте(ЛЛКонтекст C) {
    return LLVMInt8TypeInContext(C);
}
LLEXPORT ЛЛТип ЛЛТипЦел16ВКонтексте(ЛЛКонтекст C){
    return LLVMInt16TypeInContext(C);
}
LLEXPORT ЛЛТип ЛЛТипЦел32Контексте(ЛЛКонтекст C){
    return LLVMInt32TypeInContext(C);
}
LLEXPORT ЛЛТип ЛЛТипЦел64ВКонтексте(ЛЛКонтекст C){
    return LLVMInt64TypeInContext(C);
}
LLEXPORT ЛЛТип ЛЛТипЦел128ВКонтексте(ЛЛКонтекст C){
    return LLVMInt128TypeInContext(C);
}
LLEXPORT ЛЛТип ЛЛТипЦелВКонтексте(ЛЛКонтекст C, unsigned NumBits){
    return LLVMIntTypeInContext(C, NumBits);
}

LLEXPORT ЛЛТип ЛЛТипЦел1(void) {
    return LLVMInt1Type();
}
LLEXPORT ЛЛТип ЛЛТипЦел8(void)  {
    return LLVMInt8Type();
}
LLEXPORT ЛЛТип  ЛЛТипЦел16(void){
    return LLVMInt16Type();
}
LLEXPORT ЛЛТип  ЛЛТипЦел32(void) {
    return LLVMInt32Type();
}
LLEXPORT ЛЛТип  ЛЛТипЦел64(void){
    return LLVMInt64Type();
}
LLEXPORT ЛЛТип  ЛЛТипЦел128(void) {
    return LLVMInt128Type();
}
LLEXPORT ЛЛТип  ЛЛТипЦел(unsigned NumBits) {
    return LLVMIntType(NumBits);
}
LLEXPORT unsigned ЛДайШиринуЦелТипа(ЛЛТип IntegerTy) {
    return LLVMGetIntTypeWidth(IntegerTy);
}

// Операции над реальными типам 

LLEXPORT ЛЛТип ЛЛПолутипВКонтексте(ЛЛКонтекст C){
	return LLVMHalfTypeInContext(C);
}
LLEXPORT ЛЛТип ЛЛТипПлавВКонтексте(ЛЛКонтекст C){
		return LLVMFloatTypeInContext(C);
}
LLEXPORT ЛЛТип ЛЛТипДвоВКонтексте(ЛЛКонтекст C){
		return LLVMDoubleTypeInContext(C);
}
LLEXPORT ЛЛТип ЛЛТипХ86ФП80ВКонтексте(ЛЛКонтекст C){
		return LLVMX86FP80TypeInContext(C);
}
LLEXPORT ЛЛТип ЛЛТипХ86ФП128ВКонтексте(ЛЛКонтекст C){
		return LLVMFP128TypeInContext(C);
}
LLEXPORT ЛЛТип ЛЛТипППЦФП128ВКонтексте(ЛЛКонтекст C) {
		return LLVMPPCFP128TypeInContext(C);
}
LLEXPORT ЛЛТип ЛЛТипХ86ММХВКонтексте(ЛЛКонтекст C){
		return LLVMX86MMXTypeInContext(C);
}

LLEXPORT ЛЛТип ЛЛПолутип(void) {
		return LLVMHalfType();
}
LLEXPORT ЛЛТип ЛЛТипПлав(void) {
		return LLVMFloatType();
}
LLEXPORT ЛЛТип ЛЛТипДво(void) {
		return LLVMDoubleType();
}
LLEXPORT ЛЛТип ЛЛТипХ86ФП80(void) {
		return LLVMX86FP80Type();
}
LLEXPORT ЛЛТип ЛЛТипФП128(void){
		return LLVMFP128Type();
}
LLEXPORT ЛЛТип ЛЛТипППЦФП128(void){
		return LLVMPPCFP128Type();
}
LLEXPORT ЛЛТип ЛЛТипХ86ММХ(void) {
		return LLVMX86MMXType();
}

// Операциями над типами функций

LLEXPORT ЛЛТип ЛЛТипФункция(ЛЛТип ReturnType,
                             ЛЛТип *ParamTypes, unsigned ParamCount,
                             LLVMBool IsVarArg) {
return LLVMFunctionType(ReturnType,ParamTypes,ParamCount, IsVarArg);
}

LLEXPORT LLVMBool ЛЛВараргФункц_ли(ЛЛТип FunctionTy){
		return LLVMIsFunctionVarArg(FunctionTy);
}

LLEXPORT ЛЛТип ЛЛДайТипВозврата(ЛЛТип FunctionTy){
		return LLVMGetReturnType(FunctionTy);
}

LLEXPORT unsigned ЛЛСчётТиповПарам(ЛЛТип FunctionTy){
		return LLVMCountParamTypes(FunctionTy);
}

LLEXPORT void ЛЛДайТипыПарам(ЛЛТип FunctionTy, ЛЛТип *Dest){
	LLVMGetParamTypes(FunctionTy, Dest);
}

// Операции над типами структур 

LLEXPORT ЛЛТип ЛЛТипСтруктВКонтексте(ЛЛКонтекст C, ЛЛТип *ElementTypes,
                           unsigned ElementCount, LLVMBool Packed){
	return LLVMStructTypeInContext(C, ElementTypes, ElementCount, Packed);
}

LLEXPORT ЛЛТип ЛЛТипСтрукт(ЛЛТип *ElementTypes,
                           unsigned ElementCount, LLVMBool Packed){
	return LLVMStructType(ElementTypes,ElementCount, Packed);
}

LLEXPORT ЛЛТип ЛЛСтруктСоздайСИменем(ЛЛКонтекст C, const char *Name){
		return LLVMStructCreateNamed(C,Name);
}

LLEXPORT const char *ЛЛДайИмяСтрукт(ЛЛТип Ty){
		return LLVMGetStructName(Ty);
}

LLEXPORT void ЛЛСтруктУстТело(ЛЛТип StructTy, ЛЛТип *ElementTypes,
                       unsigned ElementCount, LLVMBool Packed) {
LLVMStructSetBody(StructTy,ElementTypes, ElementCount, Packed);						   
}

LLEXPORT unsigned ЛЛПосчитайТипыЭлементовСтрукт(ЛЛТип StructTy){
return LLVMCountStructElementTypes( StructTy);
}

LLEXPORT void ЛЛДайТипыЭлементовСтрукт(ЛЛТип StructTy, ЛЛТип *Dest) {
	LLVMGetStructElementTypes(StructTy, Dest);
}

LLEXPORT ЛЛТип ЛЛСтруктДайТипНаИндексе(ЛЛТип StructTy, unsigned i) {
		return LLVMStructGetTypeAtIndex(StructTy, i);
}

LLEXPORT LLVMBool ЛЛУпакованнаяСтруктура_ли(ЛЛТип StructTy) {
		return LLVMIsPackedStruct(StructTy);
}

LLEXPORT LLVMBool ЛЛОпакСтрукт_ли(ЛЛТип StructTy) {
		return LLVMIsOpaqueStruct(StructTy);
}

LLEXPORT LLVMBool ЛЛЛитералСтрукт_ли(ЛЛТип StructTy) {
		return LLVMIsLiteralStruct(StructTy);
}

LLEXPORT ЛЛТип ЛЛДайТипПоИмени(ЛЛМодуль M, const char *Name){
		return LLVMGetTypeByName(M, Name);
}

// Операции над типами массивов, указателей и векторов (типами последовательностей)

LLEXPORT void ЛЛДайПодтипы(ЛЛТип Tp, ЛЛТип *Arr){
	LLVMGetSubtypes(Tp, Arr);
}

LLEXPORT ЛЛТип ЛЛТипМассив(ЛЛТип ElementType, unsigned ElementCount){
	return LLVMArrayType(ElementType, ElementCount) ;
}

LLEXPORT ЛЛТип ЛЛТипУказатель(ЛЛТип ElementType, unsigned AddressSpace){
	return LLVMPointerType(ElementType, AddressSpace) ;
}
LLEXPORT ЛЛТип ЛЛТипВектор(ЛЛТип ElementType, unsigned ElementCount){
	return LLVMVectorType(ElementType, ElementCount) ;
}
LLEXPORT ЛЛТип ЛЛДайТипЭлемента(ЛЛТип WrappedTy) {
	return LLVMGetElementType(WrappedTy) ;
}
LLEXPORT unsigned ЛЛдайЧлоКонтТипов(ЛЛТип Tp) {
	return LLVMGetNumContainedTypes(Tp) ;
}
LLEXPORT unsigned ЛЛДайДлинуМассива(ЛЛТип ArrayTy){
	return LLVMGetArrayLength(ArrayTy) ;
}
LLEXPORT unsigned ЛЛДАйАдрПрострУказателя(ЛЛТип PointerTy) {
	return LLVMGetPointerAddressSpace(PointerTy) ;
}
LLEXPORT unsigned ЛЛДайРазмерВектора(ЛЛТип VectorTy) {
	return LLVMGetVectorSize(VectorTy) ;
}
// Операции над прочими типами

LLEXPORT ЛЛТип ЛЛТипПроцВКонтексте(ЛЛКонтекст C) {
		return LLVMVoidTypeInContext(C) ;
}
LLEXPORT ЛЛТип ЛЛТипЯрлыкВКонтексте(ЛЛКонтекст C) {
		return LLVMLabelTypeInContext(C) ;
}
LLEXPORT ЛЛТип ЛЛТипСемаВКонтексте(ЛЛКонтекст C) {
		return LLVMTokenTypeInContext(C) ;
}
LLEXPORT ЛЛТип ЛЛТипМетаданныеВКонтексте(ЛЛКонтекст C) {
		return LLVMMetadataTypeInContext(C) ;
}

LLEXPORT ЛЛТип ЛЛТипПроц(void) {
		return LLVMVoidType() ;
}
LLEXPORT ЛЛТип ЛЛТипЯрлык(void) {
		return LLVMLabelType() ;
}

// Операции над значениями

// Операции над всеми значениями 

LLEXPORT ЛЛТип ЛЛТипУ(ЛЛЗначение Val){
		return LLVMTypeOf(Val) ;
}

LLEXPORT LLVMValueKind ЛЛДайРодЗначения(ЛЛЗначение Val) {
		return LLVMGetValueKind(Val) ;
}

LLEXPORT const char *ЛЛДайИмяЗначения2(ЛЛЗначение Val, size_t *Length) {
		return LLVMGetValueName2(Val, Length) ;
}

LLEXPORT void ЛЛУстИмяЗначения2(ЛЛЗначение Val, const char *Name, size_t NameLen) {
	LLVMSetValueName2(Val, Name, NameLen) ;
}
LLEXPORT const char *ЛЛДайИмяЗначения(ЛЛЗначение Val) {
	return LLVMGetValueName(Val) ;
}
LLEXPORT void ЛЛУстИмяЗначения(ЛЛЗначение Val, const char *Name) {
	
	LLVMSetValueName(Val, Name)  ;
}
LLEXPORT void ЛЛЗначениеДампа(ЛЛЗначение Val) {
	
	LLVMDumpValue(Val) ;
}
LLEXPORT char* ЛЛВыведиЗначениеВСтроку(ЛЛЗначение Val){
	return LLVMPrintValueToString(Val) ;
}
LLEXPORT void ЛЛЗамениВсеИспользованияНа(ЛЛЗначение OldVal, ЛЛЗначение NewVal){
	LLVMReplaceAllUsesWith(OldVal, NewVal) ;
}
LLEXPORT int ЛЛЕстьМетаданные_ли(ЛЛЗначение Inst){
	return LLVMHasMetadata(Inst) ;
}
LLEXPORT ЛЛЗначение ЛЛДайМетаданные(ЛЛЗначение Inst, unsigned KindID){
	return LLVMGetMetadata(Inst,  KindID) ;
}
// MetadataAsValue uses a canonical format which strips the actual MDNode for
// MDNode with just a single constant value, storing just a ConstantAsMetadata
// This undoes this canonicalization, reconstructing the MDNode.

LLEXPORT void ЛЛУстМетаданные(ЛЛЗначение Inst, unsigned KindID, ЛЛЗначение Val){
	LLVMSetMetadata(Inst, KindID, Val) ;
}
LLEXPORT ЛЛЗаписьМетаданныхЗначения *
ЛЛИнструкцияДайВсеМетаданныеКромеЛокОтлад(ЛЛЗначение Value, size_t *NumEntries){
	return LLVMInstructionGetAllMetadataOtherThanDebugLoc(Value, NumEntries);
}

// Функции преобразования

LLEXPORT ЛЛЗначение ЛЛАМДУзел_ли(ЛЛЗначение Val) {
    return LLVMIsAMDNode(Val);
}

LLEXPORT ЛЛЗначение ЛЛАМДТкст_ли(ЛЛЗначение Val) {
return LLVMIsAMDString(Val);
}

// Операции над использованиями

LLEXPORT ЛЛИспользование ЛЛДайПервоеИспользование(ЛЛЗначение Val) {
return LLVMGetFirstUse(Val);
}
LLEXPORT ЛЛИспользование ЛЛДайСледщИспользование(ЛЛИспользование U) {
return LLVMGetNextUse(U);
}
LLEXPORT ЛЛЗначение ЛЛДайПользователя(ЛЛИспользование U) {
return LLVMGetUser(U);
}
LLEXPORT ЛЛЗначение ЛЛДайИспользованноеЗначение(ЛЛИспользование U) {
return LLVMGetUsedValue(U);
}
// Операции над Пользователями 

LLEXPORT ЛЛЗначение ЛЛДайОперанд(ЛЛЗначение Val, unsigned Index){
return LLVMGetOperand(Val, Index);
}
LLEXPORT ЛЛИспользование ЛЛДайИспользованиеОперанда(ЛЛЗначение Val, unsigned Index){
return LLVMGetOperandUse(Val, Index);
}
LLEXPORT void ЛЛУстОперанд(ЛЛЗначение Val, unsigned Index, ЛЛЗначение Op){
    return LLVMSetOperand(Val, Index, Op);
}
LLEXPORT unsigned ЛЛДайЧлоОперандовМДУзла(ЛЛЗначение V) {
    return LLVMGetMDNodeNumOperands(V);
}
LLEXPORT int ЛЛДайЧлоОперандов(ЛЛЗначение Val) {
    return LLVMGetNumOperands(Val);
}

// Операции над константами любого типа 

LLEXPORT ЛЛЗначение ЛЛКонстПусто(ЛЛТип Ty) {
return LLVMConstNull(Ty);
}
LLEXPORT ЛЛЗначение ЛЛКонстВсеЕд(ЛЛТип Ty) {
return LLVMConstAllOnes(Ty);
}
LLEXPORT ЛЛЗначение ЛЛДайНеопр(ЛЛТип Ty) {
return LLVMGetUndef(Ty);
}
LLEXPORT LLVMBool ЛЛКонстанта_ли(ЛЛЗначение Ty){
return LLVMIsConstant(Ty);
}
LLEXPORT LLVMBool ЛЛПусто_ли(ЛЛЗначение Val){
return LLVMIsNull(Val);
}
LLEXPORT LLVMBool ЛЛНеопр_ли(ЛЛЗначение Val) {
return LLVMIsUndef(Val);
}
LLEXPORT ЛЛЗначение ЛЛКонстУкПусто(ЛЛТип Ty){
return LLVMConstPointerNull(Ty);
}
// Операции над узлами метаданных

LLEXPORT ЛЛМетаданные ЛЛМДТкстВКонтексте2(ЛЛКонтекст C, const char *Str,
                                       size_t SLen){
return LLVMMDStringInContext2(C, Str, SLen);
}
LLEXPORT ЛЛМетаданные ЛЛМДУзелВКонтексте2(ЛЛКонтекст C, ЛЛМетаданные *MDs,
                                     size_t Count){
return LLVMMDNodeInContext2(C, MDs, Count);
}
LLEXPORT ЛЛЗначение ЛЛМДТкстВКонтексте(ЛЛКонтекст C, const char *Str,
                                   unsigned SLen) {
    return LLVMMDStringInContext(C,  Str, SLen);
}
LLEXPORT ЛЛЗначение ЛЛМДТкст(const char *Str, unsigned SLen){
return LLVMMDString(Str, SLen);
}
LLEXPORT ЛЛЗначение ЛЛМДУзелВКонтексте(ЛЛКонтекст C, ЛЛЗначение *Vals,
                                 unsigned Count){
return LLVMMDNodeInContext(C,  Vals, Count);
}
LLEXPORT ЛЛЗначение ЛЛМДУзел(ЛЛЗначение *Vals, unsigned Count){
return LLVMMDNode( Vals,  Count);
}
LLEXPORT ЛЛЗначение ЛЛМетаданныеКакЗначение(ЛЛКонтекст C, ЛЛМетаданные MD){
return LLVMMetadataAsValue(C,  MD);
}
LLEXPORT ЛЛМетаданные ЛЛЗначениеКакМетаданные(ЛЛЗначение Val) {
return LLVMValueAsMetadata(Val);
}
LLEXPORT const char *ЛЛДайМДТкст(ЛЛЗначение V, unsigned *Length){
return LLVMGetMDString(V, Length);
}
LLEXPORT ЛЛИменованыйУзелМД ЛЛДайПервыеИменованныеМетаданные(ЛЛМодуль M){
return LLVMGetFirstNamedMetadata(M);
}
LLEXPORT ЛЛИменованыйУзелМД ЛЛДайПоследниеИменованныеМетаданные(ЛЛМодуль M){
return LLVMGetLastNamedMetadata(M);
}
LLEXPORT ЛЛИменованыйУзелМД ЛЛДайСледщИменованныеМетаданные(ЛЛИменованыйУзелМД NMD){
return LLVMGetNextNamedMetadata(NMD);
}
LLEXPORT ЛЛИменованыйУзелМД ЛЛДайПредшИменованныеМетаданные(ЛЛИменованыйУзелМД NMD) {
return LLVMGetPreviousNamedMetadata(NMD);
}
LLEXPORT ЛЛИменованыйУзелМД ЛЛДайИменованныеМетаданные(ЛЛМодуль M,
                                        const char *Name, size_t NameLen) {
return LLVMGetNamedMetadata(M, Name, NameLen);
}
LLEXPORT ЛЛИменованыйУзелМД ЛЛДайИлиВставьИменованныеМетаданные(ЛЛМодуль M,
                                                const char *Name, size_t NameLen){
return LLVMGetOrInsertNamedMetadata(M, Name, NameLen);
}
LLEXPORT const char *ЛЛДайИмяИменованныхМетаданных(ЛЛИменованыйУзелМД NMD, size_t *NameLen){
return LLVMGetNamedMetadataName(NMD, NameLen);
}
LLEXPORT void ЛЛДайОперандыМДУзла(ЛЛЗначение V, ЛЛЗначение *Dest) {
return LLVMGetMDNodeOperands(V, Dest);
}
LLEXPORT unsigned ЛЛДайЧлоОперандовИменованныхМетаданных(ЛЛМодуль M, const char *Name){
return LLVMGetNamedMetadataNumOperands(M, Name);
}
LLEXPORT void ЛЛДайОперандыИменованныхМетаданных(ЛЛМодуль M, const char *Name,
                                  ЛЛЗначение *Dest) {
return LLVMGetNamedMetadataOperands(M,  Name, Dest);
}
LLEXPORT void ЛЛДобавьОперандИменованныхМетаданных(ЛЛМодуль M, const char *Name,
                                 ЛЛЗначение Val) {
return LLVMAddNamedMetadataOperand(M,  Name, Val);
}

LLEXPORT const char *ЛЛДайОтладЛокПапку(ЛЛЗначение Val, unsigned *Length){
return LLVMGetDebugLocDirectory(Val, Length);
}
LLEXPORT const char *ЛЛДайОтладЛокИмяф(ЛЛЗначение Val, unsigned *Length){
return LLVMGetDebugLocFilename(Val, Length);
}
LLEXPORT unsigned ЛЛДайОтладЛокСтроку(ЛЛЗначение Val) {
return LLVMGetDebugLocLine(Val);
}

LLEXPORT unsigned ЛЛДайОтладЛокКолонку(ЛЛЗначение Val){
return LLVMGetDebugLocColumn(Val);
}

//Операции над скалярными константами 

LLEXPORT ЛЛЗначение ЛЛКонстЦел(ЛЛТип IntTy, unsigned long long N,
                          LLVMBool SignExtend) {
return LLVMConstInt(IntTy, N, SignExtend);
}
LLEXPORT ЛЛЗначение ЛЛКонстЦелПроизвольнойТочности(ЛЛТип IntTy,
                                              unsigned NumWords,
                                              const uint64_t Words[]){
return LLVMConstIntOfArbitraryPrecision(IntTy, NumWords, Words);
}
LLEXPORT ЛЛЗначение ЛЛКонстЦелИзТкста(ЛЛТип IntTy, const char Str[],
                                  uint8_t Radix){
return LLVMConstIntOfString(IntTy, Str, Radix);
}
LLEXPORT ЛЛЗначение ЛЛКонстЦелИзТкстаСРазмером(ЛЛТип IntTy, const char Str[],
                                         unsigned SLen, uint8_t Radix){
return LLVMConstIntOfStringAndSize(IntTy, Str, SLen, Radix);
}
LLEXPORT ЛЛЗначение ЛЛКонстРеал(ЛЛТип RealTy, double N) {
return LLVMConstReal(RealTy, N);
}
LLEXPORT ЛЛЗначение ЛЛКонстРеалИзТкста(ЛЛТип RealTy, const char *Text){
return LLVMConstRealOfString(RealTy, Text);
}
LLEXPORT ЛЛЗначение ЛЛКонстРеалИзТкстаСРазмером(ЛЛТип RealTy, const char Str[],
                                          unsigned SLen) {
return LLVMConstRealOfStringAndSize(RealTy, Str, SLen);
}
LLEXPORT unsigned long long ЛЛКонстЦелДайНРасшЗначение(ЛЛЗначение ConstantVal){
return LLVMConstIntGetZExtValue(ConstantVal);
}
LLEXPORT long long ЛЛКонстЦелДайЗРасшЗначение(ЛЛЗначение ConstantVal){
return LLVMConstIntGetSExtValue(ConstantVal);
}
LLEXPORT double ЛЛКонстРеалДайДво(ЛЛЗначение ConstantVal, LLVMBool *LosesInfo){
return LLVMConstRealGetDouble(ConstantVal, LosesInfo);
}

// Операции над составными константами 

LLEXPORT ЛЛЗначение ЛЛКонстТкстВКонтексте(ЛЛКонтекст C, const char *Str,
                                      unsigned Length,
                                      LLVMBool DontNullTerminate) {
return LLVMConstStringInContext(C, Str, Length, DontNullTerminate);
                        }
LLEXPORT ЛЛЗначение ЛЛКонстТкст(const char *Str, unsigned Length,
                             LLVMBool DontNullTerminate) {
return LLVMConstString(Str, Length, DontNullTerminate);
}
LLEXPORT ЛЛЗначение ЛЛДайЭлтКакКонст(ЛЛЗначение C, unsigned idx) {
return LLVMGetElementAsConstant(C, idx);
}
LLEXPORT LLVMBool ЛЛКонстТкст_ли(ЛЛЗначение C){
return LLVMIsConstantString(C);
}
LLEXPORT const char *ЛЛДайКакТкст(ЛЛЗначение C, size_t *Length){
return LLVMGetAsString(C, Length);
}
LLEXPORT ЛЛЗначение ЛЛКонстМассив(ЛЛТип ElementTy,
                            ЛЛЗначение *ConstantVals, unsigned Length) {
return LLVMConstArray(ElementTy, ConstantVals, Length);
}
LLEXPORT ЛЛЗначение ЛЛКонстСтруктВКонтексте(ЛЛКонтекст C,
                                      ЛЛЗначение *ConstantVals,
                                      unsigned Count, LLVMBool Packed){
return LLVMConstStructInContext(C, ConstantVals, Count, Packed);
}
LLEXPORT ЛЛЗначение ЛЛКонстСтрукт(ЛЛЗначение *ConstantVals, unsigned Count,
                             LLVMBool Packed) {
return LLVMConstStruct(ConstantVals, Count, Packed);
}
LLEXPORT ЛЛЗначение ЛЛИменованнаяКонстСтрукт(ЛЛТип StructTy,
                                  ЛЛЗначение *ConstantVals,
                                  unsigned Count) {
return LLVMConstNamedStruct(StructTy, ConstantVals, Count);
}
LLEXPORT ЛЛЗначение ЛЛКонстВектор(ЛЛЗначение *ScalarConstantVals, unsigned Size) {
return LLVMConstVector(ScalarConstantVals, Size);
}

// Константные выражения

LLEXPORT LLVMOpcode ЛЛДайКонстОпкод(ЛЛЗначение ConstantVal){
return LLVMGetConstOpcode(ConstantVal) ;
}
LLEXPORT ЛЛЗначение ЛЛРаскладУ(ЛЛТип Ty){
return LLVMAlignOf(Ty) ;
}
LLEXPORT ЛЛЗначение ЛЛРазмерУ(ЛЛТип Ty){
return LLVMSizeOf(Ty) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстОтр(ЛЛЗначение ConstantVal){
return LLVMConstNeg(ConstantVal) ;
}
LLEXPORT ЛЛЗначение LLConstNSWNeg(ЛЛЗначение ConstantVal){
return LLVMConstNSWNeg(ConstantVal) ;
}
LLEXPORT ЛЛЗначение LLConstNUWNeg(ЛЛЗначение ConstantVal) {
return LLVMConstNUWNeg(ConstantVal) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстПОтриц(ЛЛЗначение ConstantVal) {
return LLVMConstFNeg( ConstantVal) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстНе(ЛЛЗначение ConstantVal){
return LLVMConstNot(ConstantVal) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстДобавь(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant){
return LLVMConstAdd(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение LLConstNSWAdd(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant){
return LLVMConstNSWAdd(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение LLConstNUWAdd(ЛЛЗначение LHSConstant,  ЛЛЗначение RHSConstant){
return LLVMConstNUWAdd(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстПСложи(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant){
return LLVMConstFAdd(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстОтними(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant){
return LLVMConstSub(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение LLConstNSWSub(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstNSWSub( LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение LLConstNUWSub(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant){
return LLVMConstNUWSub(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстПОтними(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstFSub(LHSConstant, RHSConstant)  ;
}
LLEXPORT ЛЛЗначение ЛЛКонстУмножь(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstMul(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение LLConstNSWMul(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstNSWMul(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение LLConstNUWMul(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant){
return LLVMConstNUWMul(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстПУмножь(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstFMul(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстБДели(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant){
return LLVMConstUDiv(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстТочноБДели(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstExactUDiv(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстЗДели(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstSDiv(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстТочноЗДели(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant){
return LLVMConstExactSDiv(LHSConstant, RHSConstant) ;
}

LLEXPORT ЛЛЗначение ЛЛКонстПДели(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstFDiv(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение LLConstURem(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant){
return LLVMConstURem(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение LLConstSRem(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant){
return LLVMConstSRem(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение LLConstFRem(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstFRem(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстИ(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstAnd(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстИли(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstOr(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстИИли(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstXor(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстЦСравн(LLVMIntPredicate Predicate,ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant){
return LLVMConstICmp(Predicate, LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстПСравн(LLVMRealPredicate Predicate, ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstFCmp(Predicate, LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстСдвл(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
return LLVMConstShl(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстСдвп(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant){
return LLVMConstLShr(LHSConstant, RHSConstant) ;
}
LLEXPORT ЛЛЗначение LLConstAShr(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) {
	return LLVMConstAShr(LHSConstant, RHSConstant);
}
LLEXPORT ЛЛЗначение LLConstGEP(ЛЛЗначение ConstantVal,
ЛЛЗначение *ConstantIndices, unsigned NumIndices){
return LLVMConstGEP(ConstantVal,ConstantIndices,  NumIndices) ;
}
LLEXPORT ЛЛЗначение LLConstInBoundsGEP(ЛЛЗначение ConstantVal, ЛЛЗначение *ConstantIndices,
                                  unsigned NumIndices){
return LLVMConstInBoundsGEP(ConstantVal, ConstantIndices, NumIndices);
}
LLEXPORT ЛЛЗначение ЛЛКонстОбрежь(ЛЛЗначение ConstantVal, ЛЛТип ToType){
return LLVMConstTrunc(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстЗРасш(ЛЛЗначение ConstantVal, ЛЛТип ToType){
return LLVMConstSExt(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстНРасш(ЛЛЗначение ConstantVal, ЛЛТип ToType) {
return LLVMConstZExt(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстПЗОбрежь(ЛЛЗначение ConstantVal, ЛЛТип ToType) {
return LLVMConstFPTrunc(ConstantVal, ToType)  ;
}
LLEXPORT ЛЛЗначение ЛЛКонстПЗРасш(ЛЛЗначение ConstantVal, ЛЛТип ToType){
return LLVMConstFPExt(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстБЦвПЗ(ЛЛЗначение ConstantVal, ЛЛТип ToType){
return LLVMConstUIToFP(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстЗЦвПЗ(ЛЛЗначение ConstantVal, ЛЛТип ToType) {
return LLVMConstSIToFP(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстПЗвБЦ(ЛЛЗначение ConstantVal, ЛЛТип ToType){
return LLVMConstFPToUI(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстПЗвЗЦ(ЛЛЗначение ConstantVal, ЛЛТип ToType) {
return LLVMConstFPToSI(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстУкзВЦел(ЛЛЗначение ConstantVal, ЛЛТип ToType) {
return LLVMConstPtrToInt(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстЦелВУкз(ЛЛЗначение ConstantVal, ЛЛТип ToType){
return LLVMConstIntToPtr(ConstantVal, ToType);
}
LLEXPORT ЛЛЗначение ЛЛКонстБитКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType){
return LLVMConstBitCast(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстАдрПрострКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType){
return LLVMConstAddrSpaceCast(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстНРасшИлиБитКаст(ЛЛЗначение ConstantVal,ЛЛТип ToType) {
return LLVMConstZExtOrBitCast(ConstantVal,ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстЗРасшИлиБитКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType) {
return LLVMConstSExtOrBitCast(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстОбрежьИлиБитКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType){
return LLVMConstTruncOrBitCast(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстУказательКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType) {
return LLVMConstPointerCast(ConstantVal, ToType);
}
LLEXPORT ЛЛЗначение ЛЛКонстЦелКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType, LLVMBool isSigned){
return LLVMConstIntCast(ConstantVal, ToType, isSigned) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстПЗКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType){
return LLVMConstFPCast(ConstantVal, ToType) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстВыбор(ЛЛЗначение ConstantCondition, ЛЛЗначение ConstantIfTrue,
 ЛЛЗначение ConstantIfFalse) {
return LLVMConstSelect(ConstantCondition, ConstantIfTrue, ConstantIfFalse) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстИзвлекиЭлемент(ЛЛЗначение VectorConstant, ЛЛЗначение IndexConstant) {
return LLVMConstExtractElement( VectorConstant, IndexConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстВставьЭлемент(ЛЛЗначение VectorConstant,  ЛЛЗначение ElementValueConstant, ЛЛЗначение IndexConstant){
return LLVMConstInsertElement(VectorConstant, ElementValueConstant, IndexConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстШафлВектор(ЛЛЗначение VectorAConstant,
                                    ЛЛЗначение VectorBConstant,
                                    ЛЛЗначение MaskConstant) {
return LLVMConstShuffleVector(VectorAConstant, VectorBConstant, MaskConstant) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстИзвлекиЗначение(ЛЛЗначение AggConstant, unsigned *IdxList,
                                   unsigned NumIdx) {
return LLVMConstExtractValue(AggConstant, IdxList, NumIdx) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстВставьЗначение(ЛЛЗначение AggConstant,
                                  ЛЛЗначение ElementValueConstant,
                                  unsigned *IdxList, unsigned NumIdx){
return LLVMConstInsertValue(AggConstant, ElementValueConstant, IdxList, NumIdx) ;
}
LLEXPORT ЛЛЗначение ЛЛКонстИнлайнАсм(ЛЛТип Ty, const char *AsmString,
                                const char *Constraints,
                                LLVMBool HasSideEffects,
                                LLVMBool IsAlignStack){
return LLVMConstInlineAsm(Ty, AsmString, Constraints, HasSideEffects, IsAlignStack) ;
}
LLEXPORT ЛЛЗначение ЛЛАдрБлока(ЛЛЗначение F, ЛЛБазовыйБлок BB){
return LLVMBlockAddress(F, BB) ;
}

// Операции над глобальными переменными, функциями и псевдонимами (глобалы) 

LLEXPORT ЛЛМодуль ЛЛДайГлобРодителя(ЛЛЗначение Global){
return LLVMGetGlobalParent(Global) ;
}
LLEXPORT LLVMBool ЛЛДекларация_ли(ЛЛЗначение Global) {
return LLVMIsDeclaration (Global);
}
LLEXPORT LLVMLinkage ЛЛДайКомпоновку(ЛЛЗначение Global){
return LLVMGetLinkage (Global);
}
LLEXPORT void ЛЛУстКомпоновку(ЛЛЗначение Global, LLVMLinkage Linkage){
 LLVMSetLinkage(Global, Linkage) ;
}
LLEXPORT const char *ЛЛДайСекцию(ЛЛЗначение Global) {
return LLVMGetSection (Global);
}
LLEXPORT void ЛЛУстСекцию(ЛЛЗначение Global, const char *Section){
 LLVMSetSection(Global, Section) ;
}
LLEXPORT LLVMVisibility ЛЛДайВидимость(ЛЛЗначение Global) {
return LLVMGetVisibility(Global) ;
}
LLEXPORT void ЛЛУстВидимость(ЛЛЗначение Global, LLVMVisibility Viz) {
 LLVMSetVisibility( Global, Viz) ;
}
LLEXPORT LLVMDLLStorageClass ЛЛДайКлассХраненияДЛЛ(ЛЛЗначение Global) {
return LLVMGetDLLStorageClass(Global) ;
}
LLEXPORT void ЛЛУстКлассХраненияДЛЛ(ЛЛЗначение Global, LLVMDLLStorageClass Class){
 LLVMSetDLLStorageClass(Global, Class) ;
}
LLEXPORT LLVMUnnamedAddr ЛЛДайБезымянныйАдрес(ЛЛЗначение Global) {
return LLVMGetUnnamedAddress(Global) ;
}
LLEXPORT void ЛЛУстБезымянныйАдрес(ЛЛЗначение Global, LLVMUnnamedAddr UnnamedAddr){
 LLVMSetUnnamedAddress(Global, UnnamedAddr) ;
}
LLEXPORT LLVMBool ЛЛЕстьБезымянныйАдр(ЛЛЗначение Global) {
return LLVMHasUnnamedAddr(Global)  ;
}
LLEXPORT void ЛЛУстБезымянныйАдр(ЛЛЗначение Global, LLVMBool HasUnnamedAddr) {
 LLVMSetUnnamedAddr(Global, HasUnnamedAddr) ;
}
LLEXPORT ЛЛТип ЛЛГлобДайТипЗначения(ЛЛЗначение Global){
return LLVMGlobalGetValueType(Global) ;
}

// Операции над глобальными переменными, инструкциями загрузки и хранения

LLEXPORT unsigned ЛЛДайРаскладку(ЛЛЗначение V) {
return LLVMGetAlignment(V) ;
}
LLEXPORT void ЛЛУстРаскладку(ЛЛЗначение V, unsigned Bytes) {
 LLVMSetAlignment(V, Bytes) ;
}
LLEXPORT ЛЛЗаписьМетаданныхЗначения *ЛЛГлоб_КопируйВсеМетаданные(ЛЛЗначение Value,
                                                  size_t *NumEntries){
return LLVMGlobalCopyAllMetadata(Value, NumEntries) ;
}
LLEXPORT unsigned ЛЛЗначение_ЗаписиМетаданных_ДайРод(ЛЛЗаписьМетаданныхЗначения *Entries,
                                         unsigned Index) {
return LLVMValueMetadataEntriesGetKind(Entries, Index) ;
}
LLEXPORT ЛЛМетаданные
ЛЛЗначение_ЗаписиМетаданных_ДайМетаданные(ЛЛЗаписьМетаданныхЗначения *Entries,
                                    unsigned Index) {
return LLVMValueMetadataEntriesGetMetadata(Entries, Index) ;
}
LLEXPORT void ЛЛВыместиЗаписиМетаданныхЗначения(ЛЛЗаписьМетаданныхЗначения *Entries) {
 LLVMDisposeValueMetadataEntries(Entries) ;
}
LLEXPORT void ЛЛГлоб_УстановиМетаданные(ЛЛЗначение Global, unsigned Kind,
                           ЛЛМетаданные MD) {
LLVMGlobalSetMetadata(Global,  Kind, MD) ;
}
LLEXPORT void ЛЛГлоб_СотриМетаданные(ЛЛЗначение Global, unsigned Kind) {
LLVMGlobalEraseMetadata( Global, Kind) ;
}
LLEXPORT void ЛЛГлоб_СбросьМетаданные(ЛЛЗначение Global){
 LLVMGlobalClearMetadata(Global) ;
}

// Операции над глобальными переменными 

LLEXPORT ЛЛЗначение ЛЛДобавьГлоб(ЛЛМодуль M, ЛЛТип Ty, const char *Name){
return LLVMAddGlobal(M, Ty, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛДобавьГлобВАдрПрострво(ЛЛМодуль M, ЛЛТип Ty,
                                         const char *Name,
                                         unsigned AddressSpace) {
return LLVMAddGlobalInAddressSpace(M, Ty, Name, AddressSpace) ;
}
LLEXPORT ЛЛЗначение ЛЛДайИменованныйГлоб(ЛЛМодуль M, const char *Name){
return LLVMGetNamedGlobal( M, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПервыйГлоб(ЛЛМодуль M) {
return LLVMGetFirstGlobal(M) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПоследнийГлоб(ЛЛМодуль M){
return LLVMGetLastGlobal(M) ;
}
LLEXPORT ЛЛЗначение ЛЛДайСледщГлоб(ЛЛЗначение GlobalVar) {
return LLVMGetNextGlobal(GlobalVar) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПредшГлоб(ЛЛЗначение GlobalVar){
return LLVMGetPreviousGlobal(GlobalVar) ;
}
LLEXPORT void ЛЛУдалиГлоб(ЛЛЗначение GlobalVar) {
 LLVMDeleteGlobal(GlobalVar) ;
}
LLEXPORT ЛЛЗначение ЛЛДайИнициализатор(ЛЛЗначение GlobalVar) {
return LLVMGetInitializer(GlobalVar)  ;
}
LLEXPORT void ЛЛУстИнициализатор(ЛЛЗначение GlobalVar, ЛЛЗначение ConstantVal) {
 LLVMSetInitializer(GlobalVar, ConstantVal) ;
}
LLEXPORT LLVMBool ЛЛНителок_ли(ЛЛЗначение GlobalVar) {
return LLVMIsThreadLocal(GlobalVar) ;
}
LLEXPORT void ЛЛУстНителок(ЛЛЗначение GlobalVar, LLVMBool IsThreadLocal){
 LLVMSetThreadLocal(GlobalVar, IsThreadLocal) ;
}
LLEXPORT LLVMBool ЛЛГлобКонст_ли(ЛЛЗначение GlobalVar){
return LLVMIsGlobalConstant(GlobalVar) ;
}
LLEXPORT void ЛЛУстГлобКонст(ЛЛЗначение GlobalVar, LLVMBool IsConstant){
 LLVMSetGlobalConstant(GlobalVar, IsConstant) ;
}
LLEXPORT LLVMThreadLocalMode ЛЛДайНителокРежим(ЛЛЗначение GlobalVar) {
return LLVMGetThreadLocalMode(GlobalVar) ;
}
LLEXPORT void ЛЛУстНителокРежим(ЛЛЗначение GlobalVar, LLVMThreadLocalMode Mode){
LLVMSetThreadLocalMode(GlobalVar, Mode) ;
}
LLEXPORT LLVMBool ЛЛИзвнеИнициализуем_ли(ЛЛЗначение GlobalVar){
return LLVMIsExternallyInitialized(GlobalVar) ;
}
LLEXPORT void ЛЛУстИзвнеИнициализуем(ЛЛЗначение GlobalVar, LLVMBool IsExtInit){
 LLVMSetExternallyInitialized(GlobalVar, IsExtInit) ;
}

// Операции над псевдонимами 

LLEXPORT ЛЛЗначение ЛЛДобавьНик(ЛЛМодуль M, ЛЛТип Ty, ЛЛЗначение Aliasee,
                          const char *Name){
return LLVMAddAlias(M, Ty, Aliasee, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛДайИменованГлобНик(ЛЛМодуль M,
                                     const char *Name, size_t NameLen) {
return LLVMGetNamedGlobalAlias(M, Name, NameLen) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПервыйГлобНик(ЛЛМодуль M) {
return LLVMGetFirstGlobalAlias(M) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПоследнийГлобНик(ЛЛМодуль M){
return LLVMGetLastGlobalAlias(M) ;
}
LLEXPORT ЛЛЗначение ЛЛДайСледщГлобНик(ЛЛЗначение GA){
return LLVMGetNextGlobalAlias(GA) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПредшГлобНик(ЛЛЗначение GA){
return LLVMGetPreviousGlobalAlias(GA) ;
}
LLEXPORT ЛЛЗначение ЛЛАлиас_ДайНики(ЛЛЗначение Alias){
return LLVMAliasGetAliasee(Alias) ;
}
LLEXPORT void ЛЛАлиас_УстНики(ЛЛЗначение Alias, ЛЛЗначение Aliasee) {
 LLVMAliasSetAliasee(Alias, Aliasee)  ;
}

// Операции над функциями

LLEXPORT ЛЛЗначение ЛЛДобавьФункц(ЛЛМодуль M, const char *Name,
                             ЛЛТип FunctionTy){
return LLVMAddFunction(M, Name, FunctionTy) ;
}
LLEXPORT ЛЛЗначение ЛЛДайИменованФункц(ЛЛМодуль M, const char *Name) {
return LLVMGetNamedFunction(M, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПервФункц(ЛЛМодуль M){
return LLVMGetFirstFunction(M) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПоследнФункц(ЛЛМодуль M) {
return LLVMGetLastFunction(M);
}
LLEXPORT ЛЛЗначение ЛЛДайСледщФункц(ЛЛЗначение Fn) {
return LLVMGetNextFunction(Fn) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПредшФункц(ЛЛЗначение Fn){
return LLVMGetPreviousFunction(Fn) ;
}
LLEXPORT void ЛЛУдалиФункц(ЛЛЗначение Fn){
LLVMDeleteFunction(Fn) ;
}
LLEXPORT LLVMBool ЛЛЕстьПерсоналФн_ли(ЛЛЗначение Fn){
return LLVMHasPersonalityFn(Fn) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПерсоналФн(ЛЛЗначение Fn) {
return LLVMGetPersonalityFn(Fn) ;
}
LLEXPORT void ЛЛУстПерсоналФн(ЛЛЗначение Fn, ЛЛЗначение PersonalityFn){
 LLVMSetPersonalityFn(Fn, PersonalityFn) ;
}
LLEXPORT unsigned ЛЛДАйИнтринсикИД(ЛЛЗначение Fn){
return LLVMGetIntrinsicID(Fn) ;
}

LLEXPORT ЛЛЗначение ЛЛДАйИнтринсикДекл(ЛЛМодуль Mod,
                                         unsigned ID,
                                         ЛЛТип *ParamTypes,
                                         size_t ParamCount){
return LLVMGetIntrinsicDeclaration(Mod, ID, ParamTypes,ParamCount) ;
}
LLEXPORT const char *ЛЛИнтринсик_ДайИмя(unsigned ID, size_t *NameLength){
return LLVMIntrinsicGetName(ID, NameLength) ;
}
LLEXPORT ЛЛТип ЛЛИнтринсик_ДайТип(ЛЛКонтекст Ctx, unsigned ID,
                                 ЛЛТип *ParamTypes, size_t ParamCount) {
return LLVMIntrinsicGetType(Ctx, ID, ParamTypes, ParamCount) ;
}
LLEXPORT const char *ЛЛИнтринсик_КопируйПерегруженИмя(unsigned ID,
                                            ЛЛТип *ParamTypes,
                                            size_t ParamCount,
                                            size_t *NameLength){
return LLVMIntrinsicCopyOverloadedName(ID,ParamTypes, ParamCount, NameLength) ;
}
LLEXPORT unsigned ЛЛИщиИнтринсикИД(const char *Name, size_t NameLen){
return LLVMLookupIntrinsicID(Name, NameLen) ;
}
LLEXPORT LLVMBool ЛЛИнтринсик_Перегружен_ли(unsigned ID){
return LLVMIntrinsicIsOverloaded(ID) ;
}
LLEXPORT unsigned ЛЛДайКонвВызФунции(ЛЛЗначение Fn){
return LLVMGetFunctionCallConv(Fn) ;
}
LLEXPORT void ЛЛУстКонвВызФунции(ЛЛЗначение Fn, unsigned CC) {
 LLVMSetFunctionCallConv(Fn,  CC)  ;
}
LLEXPORT const char *ЛЛДайСМ(ЛЛЗначение Fn){
return LLVMGetGC(Fn) ;
}
LLEXPORT void ЛЛУстСМ(ЛЛЗначение Fn, const char *GC){
LLVMSetGC( Fn, GC) ;
}
LLEXPORT void ЛЛДобавьАтрПоИндексу(ЛЛЗначение F, LLVMAttributeIndex Idx,
                             ЛЛАтрибут A){
LLVMAddAttributeAtIndex(F, Idx, A) ;
}
LLEXPORT unsigned ЛЛДайСчётАтровПоИндексу(ЛЛЗначение F, LLVMAttributeIndex Idx){
return LLVMGetAttributeCountAtIndex(F, Idx) ;
}
LLEXPORT void ЛЛДайАтрыПоИндексу(ЛЛЗначение F, LLVMAttributeIndex Idx,
                              ЛЛАтрибут *Attrs) {
 LLVMGetAttributesAtIndex(F, Idx, Attrs) ;
}
LLEXPORT ЛЛАтрибут ЛЛДайАтрПеречняПоИндексу(ЛЛЗначение F,
                                             LLVMAttributeIndex Idx,
                                             unsigned KindID){
return LLVMGetEnumAttributeAtIndex(F, Idx,KindID) ;
}
LLEXPORT ЛЛАтрибут ЛЛДайТкстАтрПоИндексу(ЛЛЗначение F,
                                               LLVMAttributeIndex Idx,
                                               const char *K, unsigned KLen){
return LLVMGetStringAttributeAtIndex(F, Idx, K, KLen) ;
}
LLEXPORT void ЛЛУдалиАтрПеречняПоИндексу(ЛЛЗначение F, LLVMAttributeIndex Idx, unsigned KindID) {
LLVMRemoveEnumAttributeAtIndex(F, Idx, KindID) ;
}
LLEXPORT void ЛЛУдалиТкстАтрПоИндексу(ЛЛЗначение F, LLVMAttributeIndex Idx,
                                      const char *K, unsigned KLen){
	 LLVMRemoveStringAttributeAtIndex(F, Idx,K, KLen) ;
}								  
LLEXPORT void ЛЛДобавьЦелеЗависимАтрФции(ЛЛЗначение Fn, const char *A,
                                        const char *V){
 LLVMAddTargetDependentFunctionAttr(Fn, A, V) ;
}

// Операции над параметрами 

LLEXPORT unsigned ЛЛПосчитайПарамы(ЛЛЗначение FnRef) {
return LLVMCountParams(FnRef) ;
}
LLEXPORT void ЛЛДайПарамы(ЛЛЗначение FnRef, ЛЛЗначение *ParamRefs){
 LLVMGetParams(FnRef, ParamRefs) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПарам(ЛЛЗначение FnRef, unsigned index) {
return LLVMGetParam(FnRef, index) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПредкаПарам(ЛЛЗначение V){
return LLVMGetParamParent(V) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПервПарам(ЛЛЗначение Fn){
return LLVMGetFirstParam(Fn) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПоследнПарам(ЛЛЗначение Fn) {
return LLVMGetLastParam(Fn) ;
}
LLEXPORT ЛЛЗначение ЛЛДайСледщПарам(ЛЛЗначение Arg) {
return LLVMGetNextParam(Arg) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПредшПарам(ЛЛЗначение Arg){
return LLVMGetPreviousParam(Arg) ;
}
LLEXPORT void ЛЛУстРаскладПарама(ЛЛЗначение Arg, unsigned align) {
 LLVMSetParamAlignment(Arg, align) ;
}

// Операции над ifuncs

LLEXPORT ЛЛЗначение ЛЛДобавьГлобИФункц(ЛЛМодуль M,
                                const char *Name, size_t NameLen,
                                ЛЛТип Ty, unsigned AddrSpace,
                                ЛЛЗначение Resolver){
return LLVMAddGlobalIFunc(M,Name, NameLen, Ty, AddrSpace, Resolver) ;
}
LLEXPORT ЛЛЗначение ЛЛДайИменованГлобИФункц(ЛЛМодуль M,
                                     const char *Name, size_t NameLen) {
return LLVMGetNamedGlobalIFunc(M,Name, NameLen) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПервГлобИФункц(ЛЛМодуль M) {
return LLVMGetFirstGlobalIFunc(M) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПоследнГлобИФункц(ЛЛМодуль M) {
return LLVMGetLastGlobalIFunc(M) ;
}
LLEXPORT ЛЛЗначение ЛЛДайСледщГлобИФункц(ЛЛЗначение IFunc){
return LLVMGetNextGlobalIFunc(IFunc) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПредшГлобИФункц(ЛЛЗначение IFunc) {
return LLVMGetPreviousGlobalIFunc(IFunc) ;
}
LLEXPORT ЛЛЗначение ЛЛДайРезольверГлобИФункц(ЛЛЗначение IFunc) {
return LLVMGetGlobalIFuncResolver(IFunc) ;
}
LLEXPORT void ЛЛУстРезольверГлобИФункц(ЛЛЗначение IFunc, ЛЛЗначение Resolver) {
LLVMSetGlobalIFuncResolver(IFunc, Resolver) ;
}
LLEXPORT void ЛЛСотриГлобИФункц(ЛЛЗначение IFunc){
 LLVMEraseGlobalIFunc( IFunc) ;
}
LLEXPORT void ЛЛУдалиГлобИФункц(ЛЛЗначение IFunc){
 LLVMRemoveGlobalIFunc(IFunc) ;
}

// Операции над базовыми блоками 

LLEXPORT ЛЛЗначение ЛЛБазБлокКакЗначение(ЛЛБазовыйБлок BB){
return LLVMBasicBlockAsValue(BB) ;
}
LLEXPORT LLVMBool ЛЛЗначение_БазБлок_ли(ЛЛЗначение Val){
return LLVMValueIsBasicBlock(Val) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛЗначениеКакБазБлок(ЛЛЗначение Val){
return LLVMValueAsBasicBlock(Val) ;
}
LLEXPORT const char *ЛЛДайИмяБазБлока(ЛЛБазовыйБлок BB) {
return LLVMGetBasicBlockName(BB) ;
}
LLEXPORT ЛЛЗначение ЛЛДайРодителяБазБлока(ЛЛБазовыйБлок BB){
return LLVMGetBasicBlockParent(BB) ;
}
LLEXPORT ЛЛЗначение ЛЛДайТерминаторБазБлока(ЛЛБазовыйБлок BB){
return LLVMGetBasicBlockTerminator(BB) ;
}
LLEXPORT unsigned ЛЛПосчитайБазБлоки(ЛЛЗначение FnRef) {
return LLVMCountBasicBlocks(FnRef) ;
}
LLEXPORT void ЛЛДайБазБлоки(ЛЛЗначение FnRef, ЛЛБазовыйБлок *BasicBlocksRefs){
 LLVMGetBasicBlocks(FnRef, BasicBlocksRefs) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛДайВводнБазБлок(ЛЛЗначение Fn) {
return LLVMGetEntryBasicBlock(Fn) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛДайПервБазБлок(ЛЛЗначение Fn){
return LLVMGetFirstBasicBlock(Fn) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛДайПоследнБазБлок(ЛЛЗначение Fn){
return LLVMGetLastBasicBlock(Fn) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛДайСледщБазБлок(ЛЛБазовыйБлок BB) {
return LLVMGetNextBasicBlock(BB) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛДайПредшБазБлок(ЛЛБазовыйБлок BB){
return LLVMGetPreviousBasicBlock(BB) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛСоздайБазБлокВКонтексте(ЛЛКонтекст C, const char *Name){
return LLVMCreateBasicBlockInContext(C, Name) ;
}
LLEXPORT void ЛЛВставьСущБазБлокПослеБлокаВставки(ЛЛПостроитель Builder, ЛЛБазовыйБлок BB){
 LLVMInsertExistingBasicBlockAfterInsertBlock(Builder, BB) ;
}
LLEXPORT void ЛЛПриставьСущБазБлок(ЛЛЗначение Fn,
                                  ЛЛБазовыйБлок BB){
return LLVMAppendExistingBasicBlock(Fn, BB) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛПриставьБазБлокВКонтексте(ЛЛКонтекст C, ЛЛЗначение FnRef, const char *Name){
return LLVMAppendBasicBlockInContext(C, FnRef, Name) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛПриставьБазБлок(ЛЛЗначение FnRef, const char *Name){
return LLVMAppendBasicBlock(FnRef, Name) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛВставьБазБлокВКонтекст(ЛЛКонтекст C,
                                                ЛЛБазовыйБлок BBRef,
                                                const char *Name){
return LLVMInsertBasicBlockInContext(C, BBRef, Name) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛВставьБазБлок(ЛЛБазовыйБлок BBRef,
                                       const char *Name){
return LLVMInsertBasicBlock(BBRef, Name) ;
}
LLEXPORT void ЛЛУдалиБазБлок(ЛЛБазовыйБлок BBRef) {
 LLVMDeleteBasicBlock(BBRef) ;
}
LLEXPORT void ЛЛУдалиБазБлокИзРодителя(ЛЛБазовыйБлок BBRef){
 LLVMRemoveBasicBlockFromParent(BBRef) ;
}
LLEXPORT void ЛЛПоставьБазБлокПеред(ЛЛБазовыйБлок BB, ЛЛБазовыйБлок MovePos){
 LLVMMoveBasicBlockBefore(BB, MovePos) ;
}
LLEXPORT void ЛЛПоставьБазБлокПосле(ЛЛБазовыйБлок BB, ЛЛБазовыйБлок MovePos) {
 LLVMMoveBasicBlockAfter(BB, MovePos) ;
}

// Операции над инструкциями 

LLEXPORT ЛЛБазовыйБлок ЛЛДайРодителяИнстр(ЛЛЗначение Inst){
return LLVMGetInstructionParent(Inst) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПервИнстр(ЛЛБазовыйБлок BB) {
return LLVMGetFirstInstruction(BB) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПоследнИнстр(ЛЛБазовыйБлок BB){
return LLVMGetLastInstruction(BB) ;
}
LLEXPORT ЛЛЗначение ЛЛДайСледщИнстр(ЛЛЗначение Inst){
return LLVMGetNextInstruction(Inst) ;
}
LLEXPORT ЛЛЗначение ЛЛДайПредшИнстр(ЛЛЗначение Inst){
return LLVMGetPreviousInstruction(Inst) ;
}
LLEXPORT void ЛЛИнструкция_УдалиИзРодителя(ЛЛЗначение Inst){
 LLVMInstructionRemoveFromParent(Inst) ;
}
LLEXPORT void ЛЛИнструкция_СотриИзРодителя(ЛЛЗначение Inst){
 LLVMInstructionEraseFromParent(Inst) ;
}
LLEXPORT LLVMIntPredicate ЛЛДайПредикатЦСравн(ЛЛЗначение Inst) {
return LLVMGetICmpPredicate(Inst) ;
}
LLEXPORT LLVMRealPredicate ЛЛДайПредикатПСравн(ЛЛЗначение Inst){
return LLVMGetFCmpPredicate(Inst) ;
}
LLEXPORT LLVMOpcode ЛЛДайОпкодИнстр(ЛЛЗначение Inst) {
return LLVMGetInstructionOpcode(Inst) ;
}
LLEXPORT ЛЛЗначение ЛЛИнструкция_Клонируй(ЛЛЗначение Inst) {
return LLVMInstructionClone(Inst) ;
}
LLEXPORT ЛЛЗначение ЛЛИнстрТерминатор_ли(ЛЛЗначение Inst){
return LLVMIsATerminatorInst(Inst) ;
}
LLEXPORT unsigned ЛЛДайЧлоАргОперандов(ЛЛЗначение Instr){
return LLVMGetNumArgOperands(Instr) ;
}

// Вызов и выполнение инструкций 

LLEXPORT unsigned ЛЛДайКонвВызИнстр(ЛЛЗначение Instr){
return LLVMGetInstructionCallConv(Instr) ;
}
LLEXPORT void ЛЛУстКонвВызИнстр(ЛЛЗначение Instr, unsigned CC){
 LLVMSetInstructionCallConv(Instr, CC);
}
LLEXPORT void ЛЛУстРаскладПарамовИнстр(ЛЛЗначение Instr, unsigned index,
                                unsigned align){
 LLVMSetInstrParamAlignment(Instr, index, align) ;
}
LLEXPORT void ЛЛДобавьАтрМестаВызова(ЛЛЗначение C, LLVMAttributeIndex Idx,
                              ЛЛАтрибут A){
 LLVMAddCallSiteAttribute(C, Idx, A) ;
}
LLEXPORT unsigned ЛЛДайЧлоАтровМестаВызова(ЛЛЗначение C,
                                       LLVMAttributeIndex Idx) {
return LLVMGetCallSiteAttributeCount(C, Idx) ;
}
LLEXPORT void ЛЛДайАтрыМестаВызова(ЛЛЗначение C, LLVMAttributeIndex Idx,
                               ЛЛАтрибут *Attrs){
 LLVMGetCallSiteAttributes(C, Idx, Attrs) ;
}
LLEXPORT ЛЛАтрибут ЛЛДайАтрыПеречняМестаВызова(ЛЛЗначение C, LLVMAttributeIndex Idx,
  unsigned KindID){
return LLVMGetCallSiteEnumAttribute(C, Idx, KindID) ;
}
LLEXPORT ЛЛАтрибут ЛЛДайТкстАтрыМестаВызова(ЛЛЗначение C, LLVMAttributeIndex Idx,
   const char *K, unsigned KLen) {
return LLVMGetCallSiteStringAttribute(C, Idx, K, KLen) ;
}
LLEXPORT void ЛЛУдалиАтрПеречняМестаВызова(ЛЛЗначение C, LLVMAttributeIndex Idx, unsigned KindID) {
 LLVMRemoveCallSiteEnumAttribute(C,  Idx,  KindID) ;
}
LLEXPORT void ЛЛУдалиТкстАтрМестаВызова(ЛЛЗначение C, LLVMAttributeIndex Idx, const char *K, unsigned KLen){
 LLVMRemoveCallSiteStringAttribute(C, Idx,K, KLen) ;
}
LLEXPORT ЛЛЗначение ЛЛДайВызванноеЗнач(ЛЛЗначение Instr) {
return LLVMGetCalledValue(Instr) ;
}
LLEXPORT ЛЛТип ЛЛДайТипВызваннойФункц(ЛЛЗначение Instr) {
return LLVMGetCalledFunctionType(Instr) ;
}

// Операции над инструкциями вызова (только call) 

LLEXPORT LLVMBool ЛЛТейлВызов_ли(ЛЛЗначение Call) {
return LLVMIsTailCall(Call) ;
}
LLEXPORT void ЛЛУстТейлВызов(ЛЛЗначение Call, LLVMBool isTailCall){
 LLVMSetTailCall(Call, isTailCall) ;
}

// Операции над инструкциями выполнения (только invoke) 

LLEXPORT ЛЛБазовыйБлок ЛЛДайНормальнПриёмник(ЛЛЗначение Invoke){
return LLVMGetNormalDest(Invoke) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛДайПриёмникОтмотки(ЛЛЗначение Invoke) {
return LLVMGetUnwindDest(Invoke) ;
}
LLEXPORT void ЛЛУстНормальнПриёмник(ЛЛЗначение Invoke, ЛЛБазовыйБлок B) {
 LLVMSetNormalDest(Invoke, B)  ;
}
LLEXPORT void ЛЛУстПриёмникОтмотки(ЛЛЗначение Invoke, ЛЛБазовыйБлок B) {
 LLVMSetUnwindDest(Invoke, B) ;
}

// Операции над терминаторами 

LLEXPORT unsigned ЛЛДайЧлоПоследователей(ЛЛЗначение Term){
return LLVMGetNumSuccessors(Term);
}
LLEXPORT ЛЛБазовыйБлок ЛЛДайПоследователи(ЛЛЗначение Term, unsigned i){
return LLVMGetSuccessor(Term, i) ;
}
LLEXPORT void ЛЛУстПоследователь(ЛЛЗначение Term, unsigned i, ЛЛБазовыйБлок block){
	 LLVMSetSuccessor(Term, i, block) ;
}

// Операции над инструкциями ветвления (только) 

LLEXPORT LLVMBool ЛЛУсловн_ли(ЛЛЗначение Branch) {
return LLVMIsConditional(Branch) ;
}
LLEXPORT ЛЛЗначение ЛЛДайУсловие(ЛЛЗначение Branch){
return LLVMGetCondition(Branch) ;
}
LLEXPORT void ЛЛУстУсловие(ЛЛЗначение Branch, ЛЛЗначение Cond){
 LLVMSetCondition(Branch, Cond) ;
}

// Операции над инструкциями переключения (только) 

LLEXPORT ЛЛБазовыйБлок ЛЛДайДефПриёмникРеле(ЛЛЗначение Switch) {
return LLVMGetSwitchDefaultDest(Switch) ;
}

// Операции над инструкциями alloca (только)

LLEXPORT ЛЛТип ЛЛДайРазмещТип(ЛЛЗначение Alloca) {
return LLVMGetAllocatedType(Alloca) ;
}

// Операции над инструкциями gep (только) 

LLEXPORT LLVMBool ЛЛвПределах_ли(ЛЛЗначение GEP){
return LLVMIsInBounds(GEP) ;
}
LLEXPORT void ЛЛУстВПределах(ЛЛЗначение GEP, LLVMBool InBounds){
 LLVMSetIsInBounds(GEP, InBounds) ;
}

// Операции над узлами phi 

LLEXPORT void ЛЛДобавьВходящ(ЛЛЗначение PhiNode, ЛЛЗначение *IncomingValues,
                     ЛЛБазовыйБлок *IncomingBlocks, unsigned Count){
 LLVMAddIncoming(PhiNode, IncomingValues,IncomingBlocks,  Count) ;
}
LLEXPORT unsigned ЛЛПосчитайВходящ(ЛЛЗначение PhiNode){
return LLVMCountIncoming(PhiNode) ;
}
LLEXPORT ЛЛЗначение ЛЛДайВходящЗнач(ЛЛЗначение PhiNode, unsigned Index){
return LLVMGetIncomingValue(PhiNode, Index) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛДайВходящБлок(ЛЛЗначение PhiNode, unsigned Index){
return LLVMGetIncomingBlock(PhiNode, Index) ;
}

// Операции над узлами extractvalue и insertvalue 

LLEXPORT unsigned ЛЛДайЧлоИндексов(ЛЛЗначение Inst){
return LLVMGetNumIndices(Inst) ;
}
LLEXPORT const unsigned *ЛЛДайИндексы(ЛЛЗначение Inst){
return LLVMGetIndices(Inst) ;
}

// Построители инструкций 

LLEXPORT ЛЛПостроитель ЛЛСоздайПостроительВКонтексте(ЛЛКонтекст C) {
return LLVMCreateBuilderInContext(C) ;
}
LLEXPORT ЛЛПостроитель ЛЛСоздайПостроитель(void){
return LLVMCreateBuilder() ;
}
LLEXPORT void ЛЛПостроительПозиции(ЛЛПостроитель Builder, ЛЛБазовыйБлок Block,
                         ЛЛЗначение Instr) {
 LLVMPositionBuilder(Builder, Block, Instr) ;
}
LLEXPORT void ЛЛПостроительПозицииПеред(ЛЛПостроитель Builder, ЛЛЗначение Instr) {
 LLVMPositionBuilderBefore(Builder, Instr) ;
}
LLEXPORT void ЛЛПостроительПозицииВКонце(ЛЛПостроитель Builder, ЛЛБазовыйБлок Block){
 LLVMPositionBuilderAtEnd(Builder, Block) ;
}
LLEXPORT ЛЛБазовыйБлок ЛЛДайБлокВставки(ЛЛПостроитель Builder) {
return LLVMGetInsertBlock(Builder) ;
}
LLEXPORT void ЛЛОчистиПозициюВставки(ЛЛПостроитель Builder) {
 LLVMClearInsertionPosition(Builder)  ;
}
LLEXPORT void ЛЛВставьВПостроитель(ЛЛПостроитель Builder, ЛЛЗначение Instr) {
 LLVMInsertIntoBuilder(Builder, Instr) ;
}
LLEXPORT void ЛЛВставьВПостроительСИменем(ЛЛПостроитель Builder, ЛЛЗначение Instr,   const char *Name) {
 LLVMInsertIntoBuilderWithName(Builder, Instr, Name) ;
}
LLEXPORT void ЛЛВыместиПостроитель(ЛЛПостроитель Builder) {
 LLVMDisposeBuilder(Builder) ;
}

// Построители метаданных 

LLEXPORT ЛЛМетаданные ЛЛДайТекЛокОтладки2(ЛЛПостроитель Builder) {
return LLVMGetCurrentDebugLocation2(Builder) ;
}
LLEXPORT void ЛЛУстТекЛокОтладки2(ЛЛПостроитель Builder, ЛЛМетаданные Loc){
 LLVMSetCurrentDebugLocation2(Builder, Loc) ;
}
LLEXPORT void ЛЛУстТекЛокОтладки(ЛЛПостроитель Builder, ЛЛЗначение L){
 LLVMSetCurrentDebugLocation(Builder, L) ;
}
LLEXPORT ЛЛЗначение ЛЛДайТекЛокОтладки(ЛЛПостроитель Builder) {
return LLVMGetCurrentDebugLocation(Builder) ;
}
LLEXPORT void ЛЛУстТекЛокОтладкиИнстр(ЛЛПостроитель Builder, ЛЛЗначение Inst){
 LLVMSetInstDebugLocation(Builder, Inst) ;
}
LLEXPORT void ЛЛПостроитель_УстДефПЗМатТег(ЛЛПостроитель Builder,
                                    ЛЛМетаданные FPMathTag){
 LLVMBuilderSetDefaultFPMathTag(Builder, FPMathTag) ;
}
LLEXPORT ЛЛМетаданные ЛЛПостроитель_ДайДефПЗМатТег(ЛЛПостроитель Builder){
return LLVMBuilderGetDefaultFPMathTag(Builder) ;
}

// Построители инструкций

LLEXPORT ЛЛЗначение ЛЛСтройВозврПроц(ЛЛПостроитель B) {
return LLVMBuildRetVoid(B) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройВозвр(ЛЛПостроитель B, ЛЛЗначение V){
return LLVMBuildRet(B, V) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройАгрегатВозвр(ЛЛПостроитель B, ЛЛЗначение *RetVals, unsigned N){
return LLVMBuildAggregateRet(B, RetVals, N) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройБр(ЛЛПостроитель B, ЛЛБазовыйБлок Dest) {
return LLVMBuildBr(B, Dest) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройУсловнБр(ЛЛПостроитель B, ЛЛЗначение If,
                             ЛЛБазовыйБлок Then, ЛЛБазовыйБлок Else){
return LLVMBuildCondBr(B, If, Then, Else) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройЩит(ЛЛПостроитель B, ЛЛЗначение V,
                             ЛЛБазовыйБлок Else, unsigned NumCases){
return LLVMBuildSwitch(B, V, Else, NumCases) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройНепрямБр(ЛЛПостроитель B, ЛЛЗначение Addr,
                                 unsigned NumDests){
return LLVMBuildIndirectBr(B, Addr, NumDests) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройИнвок(ЛЛПостроитель B, ЛЛЗначение Fn,
                             ЛЛЗначение *Args, unsigned NumArgs,
                             ЛЛБазовыйБлок Then, ЛЛБазовыйБлок Catch,
                             const char *Name){
return LLVMBuildInvoke(B, Fn, Args, NumArgs, Then, Catch, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройИнвок2(ЛЛПостроитель B, ЛЛТип Ty, ЛЛЗначение Fn,
                              ЛЛЗначение *Args, unsigned NumArgs,
                              ЛЛБазовыйБлок Then, ЛЛБазовыйБлок Catch,
                              const char *Name){
return LLVMBuildInvoke2(B, Ty, Fn, Args, NumArgs, Then, Catch, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтойЛэндингПад(ЛЛПостроитель B, ЛЛТип Ty,
                                 ЛЛЗначение PersFn, unsigned NumClauses,
                                 const char *Name){
return LLVMBuildLandingPad(B, Ty, PersFn,  NumClauses, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройКэчПад(ЛЛПостроитель B, ЛЛЗначение ParentPad,
                               ЛЛЗначение *Args, unsigned NumArgs,
                               const char *Name){
return LLVMBuildCatchPad(B, ParentPad, Args,  NumArgs, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройОчистиПад(ЛЛПостроитель B, ЛЛЗначение ParentPad,
                                 ЛЛЗначение *Args, unsigned NumArgs,
                                 const char *Name){
return LLVMBuildCleanupPad(B, ParentPad, Args,  NumArgs, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройВозобнови(ЛЛПостроитель B, ЛЛЗначение Exn){
return LLVMBuildResume(B, Exn) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройКэчЩит(ЛЛПостроитель B, ЛЛЗначение ParentPad, ЛЛБазовыйБлок UnwindBB, unsigned NumHandlers, const char *Name){
return LLVMBuildCatchSwitch(B, ParentPad, UnwindBB, NumHandlers, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройКэчВозвр(ЛЛПостроитель B, ЛЛЗначение CatchPad,
                               ЛЛБазовыйБлок BB) {
return LLVMBuildCatchRet(B, CatchPad, BB)  ;
}
LLEXPORT ЛЛЗначение ЛЛСтройОчистиВозвр(ЛЛПостроитель B, ЛЛЗначение CatchPad,
                                 ЛЛБазовыйБлок BB) {
return LLVMBuildCleanupRet(B, CatchPad, BB) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройНедоступный(ЛЛПостроитель B){
return LLVMBuildUnreachable(B) ;
}
LLEXPORT void ЛЛДобавьРеле(ЛЛЗначение Switch, ЛЛЗначение OnVal,
                 ЛЛБазовыйБлок Dest){
 LLVMAddCase(Switch, OnVal, Dest) ;
}
LLEXPORT void ЛЛДобавьПриёмник(ЛЛЗначение IndirectBr, ЛЛБазовыйБлок Dest){
 LLVMAddDestination(IndirectBr, Dest) ;
}
LLEXPORT unsigned ЛЛДайЧлоКлоз(ЛЛЗначение LandingPad){
return LLVMGetNumClauses(LandingPad) ;
}
LLEXPORT ЛЛЗначение ЛЛДайКлоз(ЛЛЗначение LandingPad, unsigned Idx){
return LLVMGetClause(LandingPad, Idx) ;
}
LLEXPORT void ЛЛДобавьКлоз(ЛЛЗначение LandingPad, ЛЛЗначение ClauseVal) {
 LLVMAddClause(LandingPad, ClauseVal) ;
}
LLEXPORT LLVMBool ЛЛОчистка_ли(ЛЛЗначение LandingPad) {
return LLVMIsCleanup(LandingPad) ;
}
LLEXPORT void ЛЛУстОчистку(ЛЛЗначение LandingPad, LLVMBool Val) {
 LLVMSetCleanup(LandingPad, Val) ;
}
LLEXPORT void ЛЛДобавьОбработчик(ЛЛЗначение CatchSwitch, ЛЛБазовыйБлок Dest) {
 LLVMAddHandler(CatchSwitch, Dest) ;
}
LLEXPORT unsigned ЛЛДайЧлоОбработчиков(ЛЛЗначение CatchSwitch) {
return LLVMGetNumHandlers(CatchSwitch) ;
}
LLEXPORT void ЛЛДайОбработчики(ЛЛЗначение CatchSwitch, ЛЛБазовыйБлок *Handlers){
 LLVMGetHandlers(CatchSwitch, Handlers) ;
}
LLEXPORT ЛЛЗначение ЛЛДайРодительскКэчЩит(ЛЛЗначение CatchPad) {
return LLVMGetParentCatchSwitch(CatchPad) ;
}
LLEXPORT void ЛЛУстРодительскКэчЩит(ЛЛЗначение CatchPad, ЛЛЗначение CatchSwitch){
 LLVMSetParentCatchSwitch(CatchPad, CatchSwitch) ;
}

// Функлеты 

LLEXPORT ЛЛЗначение ЛЛДайАргОперанд(ЛЛЗначение Funclet, unsigned i) {
return LLVMGetArgOperand(Funclet, i) ;
}
LLEXPORT void ЛЛУстАргОперанд(ЛЛЗначение Funclet, unsigned i, ЛЛЗначение value) {
 LLVMSetArgOperand(Funclet, i, value) ;
}

// Арифметика 

LLEXPORT ЛЛЗначение ЛЛСтройСложи(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name) {
return LLVMBuildAdd(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildNSWAdd(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name){
return LLVMBuildNSWAdd(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildNUWAdd(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name){
return LLVMBuildNUWAdd(B, LHS, RHS, Name);
}
LLEXPORT ЛЛЗначение ЛЛСтройПСложи(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name) {
return LLVMBuildFAdd(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройОтними(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name) {
return LLVMBuildSub(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildNSWSub(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name){
return LLVMBuildNSWSub(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildNUWSub(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name) {
return LLVMBuildNUWSub(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройПОтними(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name) {
return LLVMBuildFSub(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройУмножь(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name) {
return LLVMBuildMul(B, LHS, RHS, Name);
}
LLEXPORT ЛЛЗначение LLBuildNSWMul(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,   const char *Name){
		return LLVMBuildNSWMul(B, LHS, RHS, Name) ;
}				  
LLEXPORT ЛЛЗначение LLBuildNUWMul(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name){
return LLVMBuildNUWMul(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройПУмножь(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,   const char *Name){
return LLVMBuildFMul(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройБДели(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name) {
return LLVMBuildUDiv(B, LHS, RHS, Name)  ;
}
LLEXPORT ЛЛЗначение ЛЛСтройТочноБДели(ЛЛПостроитель B, ЛЛЗначение LHS,
                                ЛЛЗначение RHS, const char *Name) {
return LLVMBuildExactUDiv(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройЗДели(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name) {
return LLVMBuildSDiv(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройТочноЗДели(ЛЛПостроитель B, ЛЛЗначение LHS,
                                ЛЛЗначение RHS, const char *Name){
return LLVMBuildExactSDiv(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройПДели(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name) {
return LLVMBuildFDiv(B, LHS, RHS,Name)  ;
}
LLEXPORT ЛЛЗначение LLBuildURem(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name) {
return LLVMBuildURem(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildSRem(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name){
return LLVMBuildSRem(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildFRem(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name) {
return LLVMBuildFRem(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildShl(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name) {
return LLVMBuildShl(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildLShr(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name) {
return LLVMBuildLShr(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildAShr(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name) {
return LLVMBuildAShr(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройИ(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name){
return LLVMBuildAnd(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройИли(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name){
return LLVMBuildOr(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройИИли(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name) {
return LLVMBuildXor(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройБинОп(ЛЛПостроитель B, LLVMOpcode Op,
                            ЛЛЗначение LHS, ЛЛЗначение RHS,
                            const char *Name){
return LLVMBuildBinOp(B, Op, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройОтриц(ЛЛПостроитель B, ЛЛЗначение V, const char *Name){
return LLVMBuildNeg(B, V, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildNSWNeg(ЛЛПостроитель B, ЛЛЗначение V,
                             const char *Name) {
return LLVMBuildNSWNeg(B, V, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildNUWNeg(ЛЛПостроитель B, ЛЛЗначение V,
                             const char *Name){
return LLVMBuildNUWNeg(B, V, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройПОтриц(ЛЛПостроитель B, ЛЛЗначение V, const char *Name){
return LLVMBuildFNeg(B, V, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройНе(ЛЛПостроитель B, ЛЛЗначение V, const char *Name){
return LLVMBuildNot(B, V, Name) ;
}

// Память 

LLEXPORT ЛЛЗначение ЛЛСтройРазместПам(ЛЛПостроитель B, ЛЛТип Ty,
                             const char *Name){
return LLVMBuildMalloc(B, Ty, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройРазместПамМасс(ЛЛПостроитель B, ЛЛТип Ty,
                                  ЛЛЗначение Val, const char *Name) {
return LLVMBuildArrayMalloc(B, Ty, Val, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройУстПам(ЛЛПостроитель B, ЛЛЗначение Ptr, 
                             ЛЛЗначение Val, ЛЛЗначение Len,
                             unsigned Align) {
return LLVMBuildMemSet(B, Ptr, Val, Len, Align) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройКопирПам(ЛЛПостроитель B, 
                             ЛЛЗначение Dst, unsigned DstAlign,
                             ЛЛЗначение Src, unsigned SrcAlign,
                             ЛЛЗначение Size){
return LLVMBuildMemCpy(B, Dst, DstAlign,Src, SrcAlign, Size) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройПреместПам(ЛЛПостроитель B,
                              ЛЛЗначение Dst, unsigned DstAlign,
                              ЛЛЗначение Src, unsigned SrcAlign,
                              ЛЛЗначение Size){
return LLVMBuildMemMove(B, Dst, DstAlign, Src, SrcAlign, Size) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройАллока(ЛЛПостроитель B, ЛЛТип Ty,
                             const char *Name){
return LLVMBuildAlloca(B, Ty, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройАллокаМасс(ЛЛПостроитель B, ЛЛТип Ty,
                                  ЛЛЗначение Val, const char *Name){
return LLVMBuildArrayAlloca(B, Ty,Val, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройОсвободи(ЛЛПостроитель B, ЛЛЗначение PointerVal){
return LLVMBuildFree(B, PointerVal) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройЗагрузи(ЛЛПостроитель B, ЛЛЗначение PointerVal,
                           const char *Name){
return LLVMBuildLoad(B, PointerVal, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройЗагрузи2(ЛЛПостроитель B, ЛЛТип Ty,
                            ЛЛЗначение PointerVal, const char *Name){
return LLVMBuildLoad2(B, Ty, PointerVal, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройСохрани(ЛЛПостроитель B, ЛЛЗначение Val,
                            ЛЛЗначение PointerVal) {
return LLVMBuildStore(B, Val, PointerVal) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройЗабор(ЛЛПостроитель B, LLVMAtomicOrdering Ordering,
                            LLVMBool isSingleThread, const char *Name){
return LLVMBuildFence(B, Ordering, isSingleThread, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildGEP(ЛЛПостроитель B, ЛЛЗначение Pointer,
                          ЛЛЗначение *Indices, unsigned NumIndices,
                          const char *Name) {
	return LLVMBuildGEP(B, Pointer, Indices, NumIndices, Name) ;
}					  
LLEXPORT ЛЛЗначение LLBuildGEP2(ЛЛПостроитель B, ЛЛТип Ty,
                           ЛЛЗначение Pointer, ЛЛЗначение *Indices,
                           unsigned NumIndices, const char *Name){
return LLVMBuildGEP2(B, Ty, Pointer, Indices, NumIndices, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildInBoundsGEP(ЛЛПостроитель B, ЛЛЗначение Pointer,
                                  ЛЛЗначение *Indices, unsigned NumIndices,
                                  const char *Name){
return LLVMBuildInBoundsGEP(B, Pointer, Indices, NumIndices, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildInBoundsGEP2(ЛЛПостроитель B, ЛЛТип Ty,
                                   ЛЛЗначение Pointer, ЛЛЗначение *Indices,
                                   unsigned NumIndices, const char *Name) {
return LLVMBuildInBoundsGEP2(B, Ty, Pointer, Indices, NumIndices, Name)  ;
}
LLEXPORT ЛЛЗначение LLBuildStructGEP(ЛЛПостроитель B, ЛЛЗначение Pointer,
                                unsigned Idx, const char *Name) {
return LLVMBuildStructGEP(B, Pointer, Idx, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildStructGEP2(ЛЛПостроитель B, ЛЛТип Ty,
                                 ЛЛЗначение Pointer, unsigned Idx,
                                 const char *Name) {
return LLVMBuildStructGEP2(B, Ty, Pointer, Idx, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройГлобТкст(ЛЛПостроитель B, const char *Str,
                                   const char *Name){
return LLVMBuildGlobalString(B, Str, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройГлобТкстУкз(ЛЛПостроитель B, const char *Str,
                                      const char *Name){
return LLVMBuildGlobalStringPtr(B, Str, Name) ;
}
LLEXPORT LLVMBool ЛЛДайВолатил(ЛЛЗначение MemAccessInst){
return LLVMGetVolatile(MemAccessInst) ;
}
LLEXPORT void ЛЛУстВолатил(ЛЛЗначение MemAccessInst, LLVMBool isVolatile){
 LLVMSetVolatile(MemAccessInst, isVolatile) ;
}
LLEXPORT LLVMAtomicOrdering ЛЛДайПорядок(ЛЛЗначение MemAccessInst) {
return LLVMGetOrdering(MemAccessInst) ;
}
LLEXPORT void ЛЛУстПорядок(ЛЛЗначение MemAccessInst, LLVMAtomicOrdering Ordering){
return LLVMSetOrdering(MemAccessInst, Ordering) ;
}

// Приведение к типу (касты)

LLEXPORT ЛЛЗначение ЛЛСтройОбрежь(ЛЛПостроитель B, ЛЛЗначение Val,
                            ЛЛТип DestTy, const char *Name) {
return LLVMBuildTrunc(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройНРасш(ЛЛПостроитель B, ЛЛЗначение Val,
                           ЛЛТип DestTy, const char *Name) {
return LLVMBuildZExt(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройЗРасш(ЛЛПостроитель B, ЛЛЗначение Val,
                           ЛЛТип DestTy, const char *Name) {
return LLVMBuildSExt(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройПЗвБЦ(ЛЛПостроитель B, ЛЛЗначение Val,
                             ЛЛТип DestTy, const char *Name) {
return LLVMBuildFPToUI(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройПЗвЗЦ(ЛЛПостроитель B, ЛЛЗначение Val,
                             ЛЛТип DestTy, const char *Name) {
return LLVMBuildFPToSI(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройБЦвПЗ(ЛЛПостроитель B, ЛЛЗначение Val,
                             ЛЛТип DestTy, const char *Name){
return LLVMBuildUIToFP(B, Val,DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройЗЦвПЗ(ЛЛПостроитель B, ЛЛЗначение Val,
                             ЛЛТип DestTy, const char *Name){
return LLVMBuildSIToFP(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройПЗОбрежь(ЛЛПостроитель B, ЛЛЗначение Val,
                              ЛЛТип DestTy, const char *Name){
return LLVMBuildFPTrunc(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройПЗРасш(ЛЛПостроитель B, ЛЛЗначение Val,
                            ЛЛТип DestTy, const char *Name){
return LLVMBuildFPExt(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройУкзВЦел(ЛЛПостроитель B, ЛЛЗначение Val,
                               ЛЛТип DestTy, const char *Name) {
return LLVMBuildPtrToInt(B, Val, DestTy, Name)  ;
}
LLEXPORT ЛЛЗначение ЛЛСтройЦелВУкз(ЛЛПостроитель B, ЛЛЗначение Val,
                               ЛЛТип DestTy, const char *Name){
return LLVMBuildIntToPtr(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройБитКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                              ЛЛТип DestTy, const char *Name){
return LLVMBuildBitCast(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройАдрПрострКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                                    ЛЛТип DestTy, const char *Name){
return LLVMBuildAddrSpaceCast(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройНРасшИлиБитКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                                    ЛЛТип DestTy, const char *Name) {
return LLVMBuildZExtOrBitCast(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройЗРасшИлиБитКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                                    ЛЛТип DestTy, const char *Name){
return LLVMBuildSExtOrBitCast(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройОбрежьИлиБитКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                                     ЛЛТип DestTy, const char *Name) {
return LLVMBuildTruncOrBitCast(B, Val,DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройКаст(ЛЛПостроитель B, LLVMOpcode Op, ЛЛЗначение Val, ЛЛТип DestTy, const char *Name) {
return LLVMBuildCast(B, Op, Val, DestTy, Name)  ;
}
LLEXPORT ЛЛЗначение ЛЛСтройУказательКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                                  ЛЛТип DestTy, const char *Name){
return LLVMBuildPointerCast(B, Val, DestTy, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройЦелКаст2(ЛЛПостроитель B, ЛЛЗначение Val,
                               ЛЛТип DestTy, LLVMBool IsSigned,
                               const char *Name){
return LLVMBuildIntCast2(B, Val, DestTy, IsSigned, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройЦелКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                              ЛЛТип DestTy, const char *Name) {
return LLVMBuildIntCast(B, Val, DestTy, Name)  ;
}
LLEXPORT ЛЛЗначение ЛЛСтройПЗКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                             ЛЛТип DestTy, const char *Name) {
return LLVMBuildFPCast(B, Val, DestTy, Name)  ;
}

// Сравнения 

LLEXPORT ЛЛЗначение ЛЛСтройЦСравн(ЛЛПостроитель B, LLVMIntPredicate Op,
                           ЛЛЗначение LHS, ЛЛЗначение RHS,
                           const char *Name) {
return LLVMBuildICmp(B, Op, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройПСравн(ЛЛПостроитель B, LLVMRealPredicate Op,
                           ЛЛЗначение LHS, ЛЛЗначение RHS,
                           const char *Name){
return LLVMBuildFCmp(B, Op, LHS, RHS, Name) ;
}

// Различные инструкции 

LLEXPORT ЛЛЗначение LLBuildPhi(ЛЛПостроитель B, ЛЛТип Ty, const char *Name){
return LLVMBuildPhi(B, Ty, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройВызов(ЛЛПостроитель B, ЛЛЗначение Fn,
                           ЛЛЗначение *Args, unsigned NumArgs,
                           const char *Name){
return LLVMBuildCall(B, Fn, Args, NumArgs, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройВызов2(ЛЛПостроитель B, ЛЛТип Ty, ЛЛЗначение Fn, ЛЛЗначение *Args, unsigned NumArgs,
                            const char *Name){
return LLVMBuildCall2(B, Ty, Fn, Args, NumArgs, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройВыбери(ЛЛПостроитель B, ЛЛЗначение If,
                             ЛЛЗначение Then, ЛЛЗначение Else,
                             const char *Name) {
return LLVMBuildSelect(B, If, Then, Else, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройВААрг(ЛЛПостроитель B, ЛЛЗначение List,
                            ЛЛТип Ty, const char *Name){
return LLVMBuildVAArg(B, List, Ty, Name);
}
LLEXPORT ЛЛЗначение ЛЛСтройИзвлекиЭлт(ЛЛПостроитель B, ЛЛЗначение VecVal, ЛЛЗначение Index, const char *Name) {
return LLVMBuildExtractElement(B, VecVal, Index, Name);
}
LLEXPORT ЛЛЗначение ЛЛСтройВставьЭлт(ЛЛПостроитель B, ЛЛЗначение VecVal,
                                    ЛЛЗначение EltVal, ЛЛЗначение Index,
                                    const char *Name) {
return LLVMBuildInsertElement(B, VecVal, EltVal, Index, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройШафлВектор(ЛЛПостроитель B, ЛЛЗначение V1,
                                    ЛЛЗначение V2, ЛЛЗначение Mask,
                                    const char *Name) {
return LLVMBuildShuffleVector(B, V1, V2, Mask, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройИзвлекиЗначение(ЛЛПостроитель B, ЛЛЗначение AggVal,
                                   unsigned Index, const char *Name){
return LLVMBuildExtractValue(B, AggVal, Index, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройВставьЗначение(ЛЛПостроитель B, ЛЛЗначение AggVal,
                                  ЛЛЗначение EltVal, unsigned Index,
                                  const char *Name) {
return LLVMBuildInsertValue(B, AggVal, EltVal, Index, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройПусто(ЛЛПостроитель B, ЛЛЗначение Val,
                             const char *Name){
return LLVMBuildIsNull(B, Val, Name) ;
}
LLEXPORT ЛЛЗначение ЛЛСтройНеПусто(ЛЛПостроитель B, ЛЛЗначение Val,
                                const char *Name){
return LLVMBuildIsNotNull(B, Val, Name) ;
}
LLEXPORT ЛЛЗначение ЛСтройУкзДифф(ЛЛПостроитель B, ЛЛЗначение LHS,
                              ЛЛЗначение RHS, const char *Name){
return LLVMBuildPtrDiff(B, LHS, RHS, Name) ;
}
LLEXPORT ЛЛЗначение LLBuildAtomicRMW(ЛЛПостроитель B, LLVMAtomicRMWBinOp op,
                               ЛЛЗначение PTR, ЛЛЗначение Val,
                               LLVMAtomicOrdering ordering,
                               LLVMBool singleThread){
return LLVMBuildAtomicRMW(B, op, PTR, Val, ordering, singleThread) ;
}
LLEXPORT ЛЛЗначение LLBuildAtomicCmpXchg(ЛЛПостроитель B, ЛЛЗначение Ptr,
                                    ЛЛЗначение Cmp, ЛЛЗначение New,
                                    LLVMAtomicOrdering SuccessOrdering,
                                    LLVMAtomicOrdering FailureOrdering,
                                    LLVMBool singleThread) {

return LLVMBuildAtomicCmpXchg(B, Ptr, Cmp, New, SuccessOrdering, FailureOrdering, singleThread) ;
}
LLEXPORT LLVMBool ЛЛАтомнОднонить_ли(ЛЛЗначение AtomicInst){
return LLVMIsAtomicSingleThread(AtomicInst) ;
}
LLEXPORT void ЛЛУстАтомнОднонить(ЛЛЗначение AtomicInst, LLVMBool NewValue) {
 LLVMSetAtomicSingleThread(AtomicInst, NewValue) ;
}
LLEXPORT LLVMAtomicOrdering LLGetCmpXchgSuccessOrdering(ЛЛЗначение CmpXchgInst) {
return LLVMGetCmpXchgSuccessOrdering(CmpXchgInst) ;
}
LLEXPORT void LLSetCmpXchgSuccessOrdering(ЛЛЗначение CmpXchgInst,
                                   LLVMAtomicOrdering Ordering){
 LLVMSetCmpXchgSuccessOrdering(CmpXchgInst, Ordering) ;
}
LLEXPORT LLVMAtomicOrdering LLGetCmpXchgFailureOrdering(ЛЛЗначение CmpXchgInst)  {
return LLVMGetCmpXchgFailureOrdering(CmpXchgInst)  ;
}
LLEXPORT void LLSetCmpXchgFailureOrdering(ЛЛЗначение CmpXchgInst,
                                   LLVMAtomicOrdering Ordering) {
 LLVMSetCmpXchgFailureOrdering(CmpXchgInst, Ordering)  ;
}

// Модуль-провайдеры 

LLEXPORT ЛЛМодульПровайдер
ЛЛСоздайМодульПровайдерДляСущМодуля(ЛЛМодуль M){
return LLVMCreateModuleProviderForExistingModule(M) ;
}
LLEXPORT void ЛЛвыместиМодульПровайдер(ЛЛМодульПровайдер MP) {
 LLVMDisposeModuleProvider(MP);
}

// Буферы памяти 

LLEXPORT LLVMBool ЛЛСоздайБуфПамССодержимымФайла(
    const char *Path, ЛЛБуферПамяти *OutMemBuf, char **OutMessage) {
return LLVMCreateMemoryBufferWithContentsOfFile(Path, OutMemBuf, OutMessage) ;
}
LLEXPORT LLVMBool ЛЛСоздайБуфПамСоСТДВХО(ЛЛБуферПамяти *OutMemBuf,
                                         char **OutMessage) {
return LLVMCreateMemoryBufferWithSTDIN(OutMemBuf, OutMessage) ;
}
LLEXPORT ЛЛБуферПамяти ЛЛСоздайБуфПамСДиапазономПам(
    const char *InputData,  size_t InputDataLength,  const char *BufferName,
    LLVMBool RequiresNullTerminator){
return LLVMCreateMemoryBufferWithMemoryRange(InputData, InputDataLength, BufferName, RequiresNullTerminator) ;
}
LLEXPORT ЛЛБуферПамяти ЛЛСоздайБуфПамСКопиейДиапазонаПам(
    const char *InputData,  size_t InputDataLength, const char *BufferName){
return LLVMCreateMemoryBufferWithMemoryRangeCopy(InputData,  InputDataLength, BufferName) ;
}
LLEXPORT const char *ЛЛДайНачалоБуфера(ЛЛБуферПамяти MemBuf){
return LLVMGetBufferStart(MemBuf) ;
}
LLEXPORT size_t ЛЛДайРазмерБуфера(ЛЛБуферПамяти MemBuf) {
return LLVMGetBufferSize(MemBuf) ;
}
LLEXPORT void ЛЛВыместиБуферПамяти(ЛЛБуферПамяти MemBuf){
 LLVMDisposeMemoryBuffer(MemBuf) ;
}

// Реестр Проходок 

LLEXPORT ЛЛРеестрПроходок ЛЛДайГлобРеестрПроходок(void){
return LLVMGetGlobalPassRegistry() ;
}

// Менеджер Проходок 

LLEXPORT ЛЛМенеджерПроходок ЛЛСоздайМенеджерПроходок(void){
return LLVMCreatePassManager() ;
}	

LLEXPORT ЛЛМенеджерПроходок ЛЛСоздайМенеджерФукнцПроходокДляМодуля(ЛЛМодуль M){
return LLVMCreateFunctionPassManagerForModule(M) ;
}
LLEXPORT ЛЛМенеджерПроходок ЛЛСоздайМенеджерФукнцПроходок(ЛЛМодульПровайдер P) {
return LLVMCreateFunctionPassManager(P) ;
}
LLEXPORT LLVMBool ЛЛЗапустиМенеджерПроходок(ЛЛМенеджерПроходок PM, ЛЛМодуль M) {
return LLVMRunPassManager(PM,  M) ;
}
LLEXPORT LLVMBool ЛЛИнициализуйМенеджерФукнцПроходок(ЛЛМенеджерПроходок FPM) {
return LLVMInitializeFunctionPassManager(FPM) ;
}
LLEXPORT LLVMBool ЛЛЗапустиМенеджерФукнцПроходок(ЛЛМенеджерПроходок FPM, ЛЛЗначение F) {
return LLVMRunFunctionPassManager(FPM, F) ;
}
LLEXPORT LLVMBool ЛЛФинализуйМенеджерФукнцПроходок(ЛЛМенеджерПроходок FPM) {
return LLVMFinalizeFunctionPassManager(FPM) ;
}
LLEXPORT void ЛЛВыместиМенеджерПроходок(ЛЛМенеджерПроходок PM){
	 LLVMDisposePassManager(PM) ;
}

// Управление потоками выполнения

LLEXPORT void ЛЛСтопМультинить(){
LLVMStopMultithreaded();
}
LLEXPORT LLVMBool ЛЛМультинить_ли(){
return LLVMIsMultithreaded();
}
LLEXPORT LLVMBool ЛЛСтартМультинить() {
	return LLVMStartMultithreaded();
}

}