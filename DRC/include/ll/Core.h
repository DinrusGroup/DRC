

extern "C"{
#include "Header.h"

LLEXPORT void ЛЛШатдаун(void);

// Обработка ошибок

LLEXPORT char* ЛЛCоздайCообщение(const char* Message);
LLEXPORT void ЛЛВыместиСообщение(char* Message);

// Операции над контекстом 

//static ManagedStatic<LLContext> GlobalContext;

LLEXPORT ЛЛКонтекст ЛЛКонтекстСоздай(void);
LLEXPORT ЛЛКонтекст ЛЛДайГлобКонтекст(void);
LLEXPORT void ЛЛКонтекстУстОбработчикДиагностики(ЛЛКонтекст C,
    ЛЛОбработчикДиагностики Handler, void* DiagnosticContext);
LLEXPORT ЛЛОбработчикДиагностики ЛЛКонтекстДайОбработчикДиагностики(ЛЛКонтекст C);
LLEXPORT void* ЛЛКонтекстДайКонтекстДиагностики(ЛЛКонтекст C); 
LLEXPORT void ЛЛКонтекстУстОбрвызовЖни(ЛЛКонтекст C, ЛЛОбрвызовЖни Callback,
    void* OpaqueHandle);	
LLEXPORT LLVMBool ЛЛКонтекстСбрасыватьИменаЗначений_ли(ЛЛКонтекст C);
LLEXPORT void ЛЛКонтекстУстСбросИмёнЗначений(ЛЛКонтекст C, LLVMBool Discard);
LLEXPORT void ЛЛКонтекстВымести(ЛЛКонтекст C);
LLEXPORT unsigned ЛЛДайИДТипаМДВКонтексте(ЛЛКонтекст C, const char* Name,
    unsigned SLen);	
LLEXPORT unsigned ЛЛДайИДТипаМД(const char* Name, unsigned SLen);
LLEXPORT unsigned ЛЛДайТипАтрибутаПеречняДляИмени(const char* Name, size_t SLen);
LLEXPORT unsigned ЛЛДайТипПоследнАтрибутаПеречня(void);
LLEXPORT ЛЛАтрибут ЛЛСоздайАтрибутПеречня(ЛЛКонтекст C, unsigned KindID, uint64_t Val);	
LLEXPORT unsigned ЛЛДайТипАтрибутаПеречня(ЛЛАтрибут A);
LLEXPORT uint64_t ЛЛДайЗначениеАтрибутаПеречня(ЛЛАтрибут A);
LLEXPORT ЛЛАтрибут ЛЛСоздайТкстАтрибут(ЛЛКонтекст C,
                                           const char *K, unsigned KLength,
                                           const char *V, unsigned VLength);

LLEXPORT const char* ЛЛДайТипТкстАтрибута(ЛЛАтрибут A, unsigned* Length);
LLEXPORT const char* ЛЛДайЗначениеТкстАтрибута(ЛЛАтрибут A,  unsigned* Length);
LLEXPORT LLVMBool ЛЛАтрибутПеречня_ли(ЛЛАтрибут A);
LLEXPORT LLVMBool ЛЛТкстАтрибут_ли(ЛЛАтрибут A);
LLEXPORT char* ЛЛДайОписаниеДиагИнфо(ЛЛИнфоДиагностики DI);
LLEXPORT LLVMDiagnosticSeverity ЛЛДайСтрогостьДиагИнфо(ЛЛИнфоДиагностики DI);

// Операции над модулями 

LLEXPORT ЛЛМодуль ЛЛМодуль_СоздайСИменем(const char *ModuleID) ;
LLEXPORT ЛЛМодуль ЛЛМодуль_СоздайСИменемВКонтексте(const char* ModuleID,
    ЛЛКонтекст C) ;
LLEXPORT void ЛЛВыместиМодуль(ЛЛМодуль M);
LLEXPORT const char *ЛЛДайИдентификаторМодуля(ЛЛМодуль M, size_t *Len);
LLEXPORT void ЛЛУстИдентификаторМодуля(ЛЛМодуль M, const char* Ident, size_t Len);
LLEXPORT const char *ЛЛДайИмяИсходника(ЛЛМодуль M, size_t *Len) ;
LLEXPORT void ЛЛУстИмяИсходника(ЛЛМодуль M, const char* Name, size_t Len) ;

// Раскладка данных 
LLEXPORT const char *ЛЛДайСтрРаскладкиДанных(ЛЛМодуль M);
LLEXPORT const char *ЛЛДайРаскладкуДанных(ЛЛМодуль M) ;
LLEXPORT void ЛЛУстРаскладкуДанных(ЛЛМодуль M, const char* DataLayoutStr) ;

// Целевая триада
LLEXPORT const char * ЛЛДайЦель(ЛЛМодуль M);
LLEXPORT void ЛЛУстЦель(ЛЛМодуль M, const char* Triple);

// Флаги модуля

LLEXPORT ЛЛЗаписьФлагаМодуля *ЛЛКопируйМетаданныеФлаговМодуля(ЛЛМодуль M, size_t *Len);
LLEXPORT void ЛЛВыместиМетаданныеФлаговМодуля(ЛЛЗаписьФлагаМодуля* Entries);
LLEXPORT LLVMModuleFlagBehavior
ЛЛЗаписиФлаговМодуля_ДайПоведениеФлага(ЛЛЗаписьФлагаМодуля *Entries,
                                     unsigned Index);
LLEXPORT const char* ЛЛЗаписиФлаговМодуля_ДайКлюч(ЛЛЗаписьФлагаМодуля* Entries,
    unsigned Index, size_t* Len);
LLEXPORT ЛЛМетаданные ЛЛЗаписиФлаговМодуля_ДайМетаданные(ЛЛЗаписьФлагаМодуля *Entries,
                                                 unsigned Index);
LLEXPORT ЛЛМетаданные ЛЛДайФлагМодуля(ЛЛМодуль M,
                                  const char *Key, size_t KeyLen);
LLEXPORT void ЛЛДобавьФлагМодуля(ЛЛМодуль M, LLVMModuleFlagBehavior Behavior,
    const char* Key, size_t KeyLen,
    ЛЛМетаданные Val) ;

// Вывод модулей

    LLEXPORT void ЛЛДампМодуля(ЛЛМодуль M);
LLEXPORT LLVMBool ЛЛВыведиМодульВФайл(ЛЛМодуль M, const char *Filename,
                               char **ErrorMessage) ;
LLEXPORT char *ЛЛВыведиМодульВСтроку(ЛЛМодуль M);

// Операции над инлайн-ассемблером 
LLEXPORT void ЛЛУстИнлайнАсмМодуля2(ЛЛМодуль M, const char* Asm, size_t Len) ;
    LLEXPORT void ЛЛУстИнлайнАсмМодуля(ЛЛМодуль M, const char* Asm) ;
    LLEXPORT void ЛЛПриставьИнлайнАсмМодуля(ЛЛМодуль M, const char* Asm, size_t Len) ;
LLEXPORT const char *ЛЛДайИнлайнАсмМодуля(ЛЛМодуль M, size_t *Len);
LLEXPORT ЛЛЗначение ЛЛДайИнлайнАсм(ЛЛТип Ty,
                              char *AsmString, size_t AsmStringSize,
                              char *Constraints, size_t ConstraintsSize,
                              LLVMBool HasSideEffects, LLVMBool IsAlignStack,
                              LLVMInlineAsmDialect Dialect);

// Операции над модульными контекстами
LLEXPORT ЛЛКонтекст ЛЛДайКонтекстМодуля(ЛЛМодуль M);

// Операции над всеми типами (в основном)

LLEXPORT LLVMTypeKind ЛЛДайРодТипа(ЛЛТип Ty) ;
LLEXPORT LLVMBool ЛЛТипСРазмером_ли(ЛЛТип Ty);
LLEXPORT ЛЛКонтекст ЛЛДайКонтекстТипа(ЛЛТип Ty) ;
LLEXPORT void ЛЛДампТипа(ЛЛТип Ty);
LLEXPORT char *ЛЛВыведиТипВСтроку(ЛЛТип Ty);

// Операции над целочисленными типами

LLEXPORT ЛЛТип ЛЛТипЦел1ВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛТипЦел8ВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛТипЦел16ВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛТипЦел32Контексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛТипЦел64ВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛТипЦел128ВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛТипЦелВКонтексте(ЛЛКонтекст C, unsigned NumBits);
LLEXPORT ЛЛТип ЛЛТипЦел1(void) ;
LLEXPORT ЛЛТип ЛЛТипЦел8(void)  ;
LLEXPORT ЛЛТип  ЛЛТипЦел16(void);
LLEXPORT ЛЛТип  ЛЛТипЦел32(void) ;
LLEXPORT ЛЛТип  ЛЛТипЦел64(void);
LLEXPORT ЛЛТип  ЛЛТипЦел128(void) ;
LLEXPORT ЛЛТип  ЛЛТипЦел(unsigned NumBits);
LLEXPORT unsigned ЛДайШиринуЦелТипа(ЛЛТип IntegerTy);

// Операции над реальными типам 

LLEXPORT ЛЛТип ЛЛПолутипВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛТипПлавВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛТипДвоВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛТипХ86ФП80ВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛТипХ86ФП128ВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛТипППЦФП128ВКонтексте(ЛЛКонтекст C) ;
LLEXPORT ЛЛТип ЛЛТипХ86ММХВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛПолутип(void) ;
LLEXPORT ЛЛТип ЛЛТипПлав(void) ;
LLEXPORT ЛЛТип ЛЛТипДво(void) ;
LLEXPORT ЛЛТип ЛЛТипХ86ФП80(void);
LLEXPORT ЛЛТип ЛЛТипФП128(void);
LLEXPORT ЛЛТип ЛЛТипППЦФП128(void);
LLEXPORT ЛЛТип ЛЛТипХ86ММХ(void) ;

// Операциями над типами функций

LLEXPORT ЛЛТип ЛЛТипФункция(ЛЛТип ReturnType,
                             ЛЛТип *ParamTypes, unsigned ParamCount,
                             LLVMBool IsVarArg) ;
LLEXPORT LLVMBool ЛЛВараргФункц_ли(ЛЛТип FunctionTy);
LLEXPORT ЛЛТип ЛЛДайТипВозврата(ЛЛТип FunctionTy);
LLEXPORT unsigned ЛЛСчётТиповПарам(ЛЛТип FunctionTy);
LLEXPORT void ЛЛДайТипыПарам(ЛЛТип FunctionTy, ЛЛТип *Dest);

// Операции над типами структур 

LLEXPORT ЛЛТип ЛЛТипСтруктВКонтексте(ЛЛКонтекст C, ЛЛТип *ElementTypes,
                           unsigned ElementCount, LLVMBool Packed);
LLEXPORT ЛЛТип ЛЛТипСтрукт(ЛЛТип *ElementTypes,
                           unsigned ElementCount, LLVMBool Packed);
LLEXPORT ЛЛТип ЛЛСтруктСоздайСИменем(ЛЛКонтекст C, const char *Name);
LLEXPORT const char *ЛЛДайИмяСтрукт(ЛЛТип Ty);
LLEXPORT void ЛЛСтруктУстТело(ЛЛТип StructTy, ЛЛТип *ElementTypes,
                       unsigned ElementCount, LLVMBool Packed);
LLEXPORT unsigned ЛЛПосчитайТипыЭлементовСтрукт(ЛЛТип StructTy);
LLEXPORT void ЛЛДайТипыЭлементовСтрукт(ЛЛТип StructTy, ЛЛТип *Dest);
LLEXPORT ЛЛТип ЛЛСтруктДайТипНаИндексе(ЛЛТип StructTy, unsigned i);
LLEXPORT LLVMBool ЛЛУпакованнаяСтруктура_ли(ЛЛТип StructTy) ;
LLEXPORT LLVMBool ЛЛОпакСтрукт_ли(ЛЛТип StructTy) ;
LLEXPORT LLVMBool ЛЛЛитералСтрукт_ли(ЛЛТип StructTy);
LLEXPORT ЛЛТип ЛЛДайТипПоИмени(ЛЛМодуль M, const char *Name);

// Операции над типами массивов, указателей и векторов (типами последовательностей)

LLEXPORT void ЛЛДайПодтипы(ЛЛТип Tp, ЛЛТип *Arr);
LLEXPORT ЛЛТип ЛЛТипМассив(ЛЛТип ElementType, unsigned ElementCount);
LLEXPORT ЛЛТип ЛЛТипУказатель(ЛЛТип ElementType, unsigned AddressSpace);
LLEXPORT ЛЛТип ЛЛТипВектор(ЛЛТип ElementType, unsigned ElementCount);
LLEXPORT ЛЛТип ЛЛДайТипЭлемента(ЛЛТип WrappedTy);
LLEXPORT unsigned ЛЛдайЧлоКонтТипов(ЛЛТип Tp);
LLEXPORT unsigned ЛЛДайДлинуМассива(ЛЛТип ArrayTy);
LLEXPORT unsigned ЛЛДАйАдрПрострУказателя(ЛЛТип PointerTy);
LLEXPORT unsigned ЛЛДайРазмерВектора(ЛЛТип VectorTy) ;

// Операции над прочими типами

LLEXPORT ЛЛТип ЛЛТипПроцВКонтексте(ЛЛКонтекст C) ;
LLEXPORT ЛЛТип ЛЛТипЯрлыкВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛТипСемаВКонтексте(ЛЛКонтекст C) ;
LLEXPORT ЛЛТип ЛЛТипМетаданныеВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛТип ЛЛТипПроц(void) ;
LLEXPORT ЛЛТип ЛЛТипЯрлык(void);

// Операции над значениями

// Операции над всеми значениями 

LLEXPORT ЛЛТип ЛЛТипУ(ЛЛЗначение Val);
LLEXPORT LLVMValueKind ЛЛДайРодЗначения(ЛЛЗначение Val);
LLEXPORT const char *ЛЛДайИмяЗначения2(ЛЛЗначение Val, size_t *Length) ;
LLEXPORT void ЛЛУстИмяЗначения2(ЛЛЗначение Val, const char *Name, size_t NameLen) ;
LLEXPORT const char *ЛЛДайИмяЗначения(ЛЛЗначение Val) ;
LLEXPORT void ЛЛУстИмяЗначения(ЛЛЗначение Val, const char *Name) ;
LLEXPORT void ЛЛЗначениеДампа(ЛЛЗначение Val);
LLEXPORT char* ЛЛВыведиЗначениеВСтроку(ЛЛЗначение Val);
LLEXPORT void ЛЛЗамениВсеИспользованияНа(ЛЛЗначение OldVal, ЛЛЗначение NewVal);
LLEXPORT int ЛЛЕстьМетаданные_ли(ЛЛЗначение Inst);
LLEXPORT ЛЛЗначение ЛЛДайМетаданные(ЛЛЗначение Inst, unsigned KindID);
LLEXPORT void ЛЛУстМетаданные(ЛЛЗначение Inst, unsigned KindID, ЛЛЗначение Val);
LLEXPORT ЛЛЗаписьМетаданныхЗначения *
ЛЛИнструкцияДайВсеМетаданныеКромеЛокОтлад(ЛЛЗначение Value, size_t *NumEntries);

// Функции преобразования

LLEXPORT ЛЛЗначение ЛЛАМДУзел_ли(ЛЛЗначение Val);
LLEXPORT ЛЛЗначение ЛЛАМДТкст_ли(ЛЛЗначение Val);

// Операции над использованиями

LLEXPORT ЛЛИспользование ЛЛДайПервоеИспользование(ЛЛЗначение Val);
LLEXPORT ЛЛИспользование ЛЛДайСледщИспользование(ЛЛИспользование U) ;
LLEXPORT ЛЛЗначение ЛЛДайПользователя(ЛЛИспользование U) ;
LLEXPORT ЛЛЗначение ЛЛДайИспользованноеЗначение(ЛЛИспользование U) ;

// Операции над Пользователями 

LLEXPORT ЛЛЗначение ЛЛДайОперанд(ЛЛЗначение Val, unsigned Index);
LLEXPORT ЛЛИспользование ЛЛДайИспользованиеОперанда(ЛЛЗначение Val, unsigned Index);
LLEXPORT void ЛЛУстОперанд(ЛЛЗначение Val, unsigned Index, ЛЛЗначение Op);
LLEXPORT unsigned ЛЛДайЧлоОперандовМДУзла(ЛЛЗначение V) ;
LLEXPORT int ЛЛДайЧлоОперандов(ЛЛЗначение Val) ;

// Операции над константами любого типа 

LLEXPORT ЛЛЗначение ЛЛКонстПусто(ЛЛТип Ty) ;
LLEXPORT ЛЛЗначение ЛЛКонстВсеЕд(ЛЛТип Ty) ;
LLEXPORT ЛЛЗначение ЛЛДайНеопр(ЛЛТип Ty) ;
LLEXPORT LLVMBool ЛЛКонстанта_ли(ЛЛЗначение Ty);
LLEXPORT LLVMBool ЛЛПусто_ли(ЛЛЗначение Val);
LLEXPORT LLVMBool ЛЛНеопр_ли(ЛЛЗначение Val) ;
LLEXPORT ЛЛЗначение ЛЛКонстУкПусто(ЛЛТип Ty);

// Операции над узлами метаданных

LLEXPORT ЛЛМетаданные ЛЛМДТкстВКонтексте2(ЛЛКонтекст C, const char *Str, size_t SLen);
LLEXPORT ЛЛМетаданные ЛЛМДУзелВКонтексте2(ЛЛКонтекст C, ЛЛМетаданные *MDs, size_t Count);
LLEXPORT ЛЛЗначение ЛЛМДТкстВКонтексте(ЛЛКонтекст C, const char *Str, unsigned SLen) ;
LLEXPORT ЛЛЗначение ЛЛМДТкст(const char *Str, unsigned SLen);
LLEXPORT ЛЛЗначение ЛЛМДУзелВКонтексте(ЛЛКонтекст C, ЛЛЗначение *Vals, unsigned Count);
LLEXPORT ЛЛЗначение ЛЛМДУзел(ЛЛЗначение *Vals, unsigned Count);
LLEXPORT ЛЛЗначение ЛЛМетаданныеКакЗначение(ЛЛКонтекст C, ЛЛМетаданные MD);
LLEXPORT ЛЛМетаданные ЛЛЗначениеКакМетаданные(ЛЛЗначение Val);
LLEXPORT const char *ЛЛДайМДТкст(ЛЛЗначение V, unsigned *Length);
LLEXPORT ЛЛИменованыйУзелМД ЛЛДайПервыеИменованныеМетаданные(ЛЛМодуль M);
LLEXPORT ЛЛИменованыйУзелМД ЛЛДайПоследниеИменованныеМетаданные(ЛЛМодуль M);
LLEXPORT ЛЛИменованыйУзелМД ЛЛДайСледщИменованныеМетаданные(ЛЛИменованыйУзелМД NMD);
LLEXPORT ЛЛИменованыйУзелМД ЛЛДайПредшИменованныеМетаданные(ЛЛИменованыйУзелМД NMD) ;
LLEXPORT ЛЛИменованыйУзелМД ЛЛДайИменованныеМетаданные(ЛЛМодуль M,
                                        const char *Name, size_t NameLen) ;
LLEXPORT ЛЛИменованыйУзелМД ЛЛДайИлиВставьИменованныеМетаданные(ЛЛМодуль M,
                                                const char *Name, size_t NameLen);
LLEXPORT const char *ЛЛДайИмяИменованныхМетаданных(ЛЛИменованыйУзелМД NMD, size_t *NameLen);
LLEXPORT void ЛЛДайОперандыМДУзла(ЛЛЗначение V, ЛЛЗначение *Dest);
LLEXPORT unsigned ЛЛДайЧлоОперандовИменованныхМетаданных(ЛЛМодуль M, const char *Name);
LLEXPORT void ЛЛДайОперандыИменованныхМетаданных(ЛЛМодуль M, const char *Name,
                                  ЛЛЗначение *Dest);
LLEXPORT void ЛЛДобавьОперандИменованныхМетаданных(ЛЛМодуль M, const char *Name,
                                 ЛЛЗначение Val);
LLEXPORT const char *ЛЛДайОтладЛокПапку(ЛЛЗначение Val, unsigned *Length);
LLEXPORT const char *ЛЛДайОтладЛокИмяф(ЛЛЗначение Val, unsigned *Length);
LLEXPORT unsigned ЛЛДайОтладЛокСтроку(ЛЛЗначение Val) ;
LLEXPORT unsigned ЛЛДайОтладЛокКолонку(ЛЛЗначение Val);

//Операции над скалярными константами 

LLEXPORT ЛЛЗначение ЛЛКонстЦел(ЛЛТип IntTy, unsigned long long N,
                          LLVMBool SignExtend);
LLEXPORT ЛЛЗначение ЛЛКонстЦелПроизвольнойТочности(ЛЛТип IntTy,
                                              unsigned NumWords,
                                              const uint64_t Words[]);
LLEXPORT ЛЛЗначение ЛЛКонстЦелИзТкста(ЛЛТип IntTy, const char Str[],
                                  uint8_t Radix);
LLEXPORT ЛЛЗначение ЛЛКонстЦелИзТкстаСРазмером(ЛЛТип IntTy, const char Str[],
                                         unsigned SLen, uint8_t Radix);
LLEXPORT ЛЛЗначение ЛЛКонстРеал(ЛЛТип RealTy, double N);
LLEXPORT ЛЛЗначение ЛЛКонстРеалИзТкста(ЛЛТип RealTy, const char *Text);
LLEXPORT ЛЛЗначение ЛЛКонстРеалИзТкстаСРазмером(ЛЛТип RealTy, const char Str[],
                                          unsigned SLen);
LLEXPORT unsigned long long ЛЛКонстЦелДайНРасшЗначение(ЛЛЗначение ConstantVal);
LLEXPORT long long ЛЛКонстЦелДайЗРасшЗначение(ЛЛЗначение ConstantVal);
LLEXPORT double ЛЛКонстРеалДайДво(ЛЛЗначение ConstantVal, LLVMBool *LosesInfo);

// Операции над составными константами 

LLEXPORT ЛЛЗначение ЛЛКонстТкстВКонтексте(ЛЛКонтекст C, const char *Str,
                                      unsigned Length,
                                      LLVMBool DontNullTerminate);
LLEXPORT ЛЛЗначение ЛЛКонстТкст(const char *Str, unsigned Length,
                             LLVMBool DontNullTerminate);
LLEXPORT ЛЛЗначение ЛЛДайЭлтКакКонст(ЛЛЗначение C, unsigned idx) ;
LLEXPORT LLVMBool ЛЛКонстТкст_ли(ЛЛЗначение C);
LLEXPORT const char *ЛЛДайКакТкст(ЛЛЗначение C, size_t *Length);
LLEXPORT ЛЛЗначение ЛЛКонстМассив(ЛЛТип ElementTy,
                            ЛЛЗначение *ConstantVals, unsigned Length);
LLEXPORT ЛЛЗначение ЛЛКонстСтруктВКонтексте(ЛЛКонтекст C,
                                      ЛЛЗначение *ConstantVals,
                                      unsigned Count, LLVMBool Packed);
LLEXPORT ЛЛЗначение ЛЛКонстСтрукт(ЛЛЗначение *ConstantVals, unsigned Count,
                             LLVMBool Packed) ;
LLEXPORT ЛЛЗначение ЛЛИменованнаяКонстСтрукт(ЛЛТип StructTy,
                                  ЛЛЗначение *ConstantVals,
                                  unsigned Count);
LLEXPORT ЛЛЗначение ЛЛКонстВектор(ЛЛЗначение *ScalarConstantVals, unsigned Size);

// Константные выражения

LLEXPORT LLVMOpcode ЛЛДайКонстОпкод(ЛЛЗначение ConstantVal);
LLEXPORT ЛЛЗначение ЛЛРаскладУ(ЛЛТип Ty);
LLEXPORT ЛЛЗначение ЛЛРазмерУ(ЛЛТип Ty);
LLEXPORT ЛЛЗначение ЛЛКонстОтр(ЛЛЗначение ConstantVal);
LLEXPORT ЛЛЗначение LLConstNSWNeg(ЛЛЗначение ConstantVal);
LLEXPORT ЛЛЗначение LLConstNUWNeg(ЛЛЗначение ConstantVal) ;
LLEXPORT ЛЛЗначение ЛЛКонстПОтриц(ЛЛЗначение ConstantVal);
LLEXPORT ЛЛЗначение ЛЛКонстНе(ЛЛЗначение ConstantVal);
LLEXPORT ЛЛЗначение ЛЛКонстДобавь(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение LLConstNSWAdd(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение LLConstNUWAdd(ЛЛЗначение LHSConstant,  ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстПСложи(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстОтними(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение LLConstNSWSub(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение LLConstNUWSub(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстПОтними(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстУмножь(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение LLConstNSWMul(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение LLConstNUWMul(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстПУмножь(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстБДели(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстТочноБДели(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстЗДели(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстТочноЗДели(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);

LLEXPORT ЛЛЗначение ЛЛКонстПДели(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение LLConstURem(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение LLConstSRem(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение LLConstFRem(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстИ(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстИли(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстИИли(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстЦСравн(LLVMIntPredicate Predicate,ЛЛЗначение LHSConstant,
 ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстПСравн(LLVMRealPredicate Predicate, ЛЛЗначение LHSConstant, 
    ЛЛЗначение RHSConstant) ;
LLEXPORT ЛЛЗначение ЛЛКонстСдвл(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение ЛЛКонстСдвп(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant);
LLEXPORT ЛЛЗначение LLConstAShr(ЛЛЗначение LHSConstant, ЛЛЗначение RHSConstant) ;
LLEXPORT ЛЛЗначение LLConstGEP(ЛЛЗначение ConstantVal,
ЛЛЗначение *ConstantIndices, unsigned NumIndices);
LLEXPORT ЛЛЗначение LLConstInBoundsGEP(ЛЛЗначение ConstantVal, ЛЛЗначение *ConstantIndices,
                                  unsigned NumIndices);
LLEXPORT ЛЛЗначение ЛЛКонстОбрежь(ЛЛЗначение ConstantVal, ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстЗРасш(ЛЛЗначение ConstantVal, ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстНРасш(ЛЛЗначение ConstantVal, ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстПЗОбрежь(ЛЛЗначение ConstantVal, ЛЛТип ToType) ;
LLEXPORT ЛЛЗначение ЛЛКонстПЗРасш(ЛЛЗначение ConstantVal, ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстБЦвПЗ(ЛЛЗначение ConstantVal, ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстЗЦвПЗ(ЛЛЗначение ConstantVal, ЛЛТип ToType) ;
LLEXPORT ЛЛЗначение ЛЛКонстПЗвБЦ(ЛЛЗначение ConstantVal, ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстПЗвЗЦ(ЛЛЗначение ConstantVal, ЛЛТип ToType) ;
LLEXPORT ЛЛЗначение ЛЛКонстУкзВЦел(ЛЛЗначение ConstantVal, ЛЛТип ToType) ;
LLEXPORT ЛЛЗначение ЛЛКонстЦелВУкз(ЛЛЗначение ConstantVal, ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстБитКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстАдрПрострКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстНРасшИлиБитКаст(ЛЛЗначение ConstantVal,ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстЗРасшИлиБитКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстОбрежьИлиБитКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстУказательКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстЦелКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType, LLVMBool isSigned);
LLEXPORT ЛЛЗначение ЛЛКонстПЗКаст(ЛЛЗначение ConstantVal, ЛЛТип ToType);
LLEXPORT ЛЛЗначение ЛЛКонстВыбор(ЛЛЗначение ConstantCondition, ЛЛЗначение ConstantIfTrue,
 ЛЛЗначение ConstantIfFalse) ;
LLEXPORT ЛЛЗначение ЛЛКонстИзвлекиЭлемент(ЛЛЗначение VectorConstant, ЛЛЗначение IndexConstant);
LLEXPORT ЛЛЗначение ЛЛКонстВставьЭлемент(ЛЛЗначение VectorConstant,
  ЛЛЗначение ElementValueConstant, ЛЛЗначение IndexConstant);
LLEXPORT ЛЛЗначение ЛЛКонстШафлВектор(ЛЛЗначение VectorAConstant,
                                    ЛЛЗначение VectorBConstant,
                                    ЛЛЗначение MaskConstant);
LLEXPORT ЛЛЗначение ЛЛКонстИзвлекиЗначение(ЛЛЗначение AggConstant, unsigned *IdxList,
                                   unsigned NumIdx);
LLEXPORT ЛЛЗначение ЛЛКонстВставьЗначение(ЛЛЗначение AggConstant,
                                  ЛЛЗначение ElementValueConstant,
                                  unsigned *IdxList, unsigned NumIdx);
LLEXPORT ЛЛЗначение ЛЛКонстИнлайнАсм(ЛЛТип Ty, const char *AsmString,
                                const char *Constraints,
                                LLVMBool HasSideEffects,
                                LLVMBool IsAlignStack);
LLEXPORT ЛЛЗначение ЛЛАдрБлока(ЛЛЗначение F, ЛЛБазовыйБлок BB);

// Операции над глобальными переменными, функциями и псевдонимами (глобалы) 

LLEXPORT ЛЛМодуль ЛЛДайГлобРодителя(ЛЛЗначение Global);
LLEXPORT LLVMBool ЛЛДекларация_ли(ЛЛЗначение Global);
LLEXPORT LLVMLinkage ЛЛДайКомпоновку(ЛЛЗначение Global);
LLEXPORT void ЛЛУстКомпоновку(ЛЛЗначение Global, LLVMLinkage Linkage);
LLEXPORT const char *ЛЛДайСекцию(ЛЛЗначение Global) ;
LLEXPORT void ЛЛУстСекцию(ЛЛЗначение Global, const char *Section);
LLEXPORT LLVMVisibility ЛЛДайВидимость(ЛЛЗначение Global) ;
LLEXPORT void ЛЛУстВидимость(ЛЛЗначение Global, LLVMVisibility Viz) ;
LLEXPORT LLVMDLLStorageClass ЛЛДайКлассХраненияДЛЛ(ЛЛЗначение Global);
LLEXPORT void ЛЛУстКлассХраненияДЛЛ(ЛЛЗначение Global, LLVMDLLStorageClass Class);
LLEXPORT LLVMUnnamedAddr ЛЛДайБезымянныйАдрес(ЛЛЗначение Global) ;
LLEXPORT void ЛЛУстБезымянныйАдрес(ЛЛЗначение Global, LLVMUnnamedAddr UnnamedAddr);
LLEXPORT LLVMBool ЛЛЕстьБезымянныйАдр(ЛЛЗначение Global) ;
LLEXPORT void ЛЛУстБезымянныйАдр(ЛЛЗначение Global, LLVMBool HasUnnamedAddr);
LLEXPORT ЛЛТип ЛЛГлобДайТипЗначения(ЛЛЗначение Global);

// Операции над глобальными переменными, инструкциями загрузки и хранения

LLEXPORT unsigned ЛЛДайРаскладку(ЛЛЗначение V) ;
LLEXPORT void ЛЛУстРаскладку(ЛЛЗначение V, unsigned Bytes);
LLEXPORT ЛЛЗаписьМетаданныхЗначения *ЛЛГлоб_КопируйВсеМетаданные(ЛЛЗначение Value,
                                                  size_t *NumEntries);
LLEXPORT unsigned ЛЛЗначение_ЗаписиМетаданных_ДайРод(ЛЛЗаписьМетаданныхЗначения *Entries,
                                         unsigned Index) ;
LLEXPORT ЛЛМетаданные
ЛЛЗначение_ЗаписиМетаданных_ДайМетаданные(ЛЛЗаписьМетаданныхЗначения *Entries,
                                    unsigned Index);
LLEXPORT void ЛЛВыместиЗаписиМетаданныхЗначения(ЛЛЗаписьМетаданныхЗначения *Entries);
LLEXPORT void ЛЛГлоб_УстановиМетаданные(ЛЛЗначение Global, unsigned Kind,
                           ЛЛМетаданные MD);
LLEXPORT void ЛЛГлоб_СотриМетаданные(ЛЛЗначение Global, unsigned Kind);
LLEXPORT void ЛЛГлоб_СбросьМетаданные(ЛЛЗначение Global);

// Операции над глобальными переменными 

LLEXPORT ЛЛЗначение ЛЛДобавьГлоб(ЛЛМодуль M, ЛЛТип Ty, const char *Name);
LLEXPORT ЛЛЗначение ЛЛДобавьГлобВАдрПрострво(ЛЛМодуль M, ЛЛТип Ty,
                                         const char *Name,
                                         unsigned AddressSpace);
LLEXPORT ЛЛЗначение ЛЛДайИменованныйГлоб(ЛЛМодуль M, const char *Name);
LLEXPORT ЛЛЗначение ЛЛДайПервыйГлоб(ЛЛМодуль M);
LLEXPORT ЛЛЗначение ЛЛДайПоследнийГлоб(ЛЛМодуль M);
LLEXPORT ЛЛЗначение ЛЛДайСледщГлоб(ЛЛЗначение GlobalVar);
LLEXPORT ЛЛЗначение ЛЛДайПредшГлоб(ЛЛЗначение GlobalVar);
LLEXPORT void ЛЛУдалиГлоб(ЛЛЗначение GlobalVar);
LLEXPORT ЛЛЗначение ЛЛДайИнициализатор(ЛЛЗначение GlobalVar);
LLEXPORT void ЛЛУстИнициализатор(ЛЛЗначение GlobalVar, ЛЛЗначение ConstantVal);
LLEXPORT LLVMBool ЛЛНителок_ли(ЛЛЗначение GlobalVar) ;
LLEXPORT void ЛЛУстНителок(ЛЛЗначение GlobalVar, LLVMBool IsThreadLocal);
LLEXPORT LLVMBool ЛЛГлобКонст_ли(ЛЛЗначение GlobalVar);
LLEXPORT void ЛЛУстГлобКонст(ЛЛЗначение GlobalVar, LLVMBool IsConstant);
LLEXPORT LLVMThreadLocalMode ЛЛДайНителокРежим(ЛЛЗначение GlobalVar);
LLEXPORT void ЛЛУстНителокРежим(ЛЛЗначение GlobalVar, LLVMThreadLocalMode Mode);
LLEXPORT LLVMBool ЛЛИзвнеИнициализуем_ли(ЛЛЗначение GlobalVar);
LLEXPORT void ЛЛУстИзвнеИнициализуем(ЛЛЗначение GlobalVar, LLVMBool IsExtInit);

// Операции над псевдонимами 

LLEXPORT ЛЛЗначение ЛЛДобавьНик(ЛЛМодуль M, ЛЛТип Ty, ЛЛЗначение Aliasee,
                          const char *Name);
LLEXPORT ЛЛЗначение ЛЛДайИменованГлобНик(ЛЛМодуль M,
                                     const char *Name, size_t NameLen) ;
LLEXPORT ЛЛЗначение ЛЛДайПервыйГлобНик(ЛЛМодуль M);
LLEXPORT ЛЛЗначение ЛЛДайПоследнийГлобНик(ЛЛМодуль M);
LLEXPORT ЛЛЗначение ЛЛДайСледщГлобНик(ЛЛЗначение GA);
LLEXPORT ЛЛЗначение ЛЛДайПредшГлобНик(ЛЛЗначение GA);
LLEXPORT ЛЛЗначение ЛЛАлиас_ДайНики(ЛЛЗначение Alias);
LLEXPORT void ЛЛАлиас_УстНики(ЛЛЗначение Alias, ЛЛЗначение Aliasee);

// Операции над функциями

LLEXPORT ЛЛЗначение ЛЛДобавьФункц(ЛЛМодуль M, const char *Name,
                             ЛЛТип FunctionTy);
LLEXPORT ЛЛЗначение ЛЛДайИменованФункц(ЛЛМодуль M, const char *Name);
LLEXPORT ЛЛЗначение ЛЛДайПервФункц(ЛЛМодуль M);
LLEXPORT ЛЛЗначение ЛЛДайПоследнФункц(ЛЛМодуль M);
LLEXPORT ЛЛЗначение ЛЛДайСледщФункц(ЛЛЗначение Fn);
LLEXPORT ЛЛЗначение ЛЛДайПредшФункц(ЛЛЗначение Fn);
LLEXPORT void ЛЛУдалиФункц(ЛЛЗначение Fn);
LLEXPORT LLVMBool ЛЛЕстьПерсоналФн_ли(ЛЛЗначение Fn);
LLEXPORT ЛЛЗначение ЛЛДайПерсоналФн(ЛЛЗначение Fn);
LLEXPORT void ЛЛУстПерсоналФн(ЛЛЗначение Fn, ЛЛЗначение PersonalityFn);
LLEXPORT unsigned ЛЛДАйИнтринсикИД(ЛЛЗначение Fn);
LLEXPORT ЛЛЗначение ЛЛДАйИнтринсикДекл(ЛЛМодуль Mod,
                                         unsigned ID,
                                         ЛЛТип *ParamTypes,
                                         size_t ParamCount);
LLEXPORT const char *ЛЛИнтринсик_ДайИмя(unsigned ID, size_t *NameLength);
LLEXPORT ЛЛТип ЛЛИнтринсик_ДайТип(ЛЛКонтекст Ctx, unsigned ID,
                                 ЛЛТип *ParamTypes, size_t ParamCount);
LLEXPORT const char *ЛЛИнтринсик_КопируйПерегруженИмя(unsigned ID,
                                            ЛЛТип *ParamTypes,
                                            size_t ParamCount,
                                            size_t *NameLength);
LLEXPORT unsigned ЛЛИщиИнтринсикИД(const char *Name, size_t NameLen);
LLEXPORT LLVMBool ЛЛИнтринсик_Перегружен_ли(unsigned ID);
LLEXPORT unsigned ЛЛДайКонвВызФунции(ЛЛЗначение Fn);
LLEXPORT void ЛЛУстКонвВызФунции(ЛЛЗначение Fn, unsigned CC);
LLEXPORT const char *ЛЛДайСМ(ЛЛЗначение Fn);
LLEXPORT void ЛЛУстСМ(ЛЛЗначение Fn, const char *GC);
LLEXPORT void ЛЛДобавьАтрПоИндексу(ЛЛЗначение F, LLVMAttributeIndex Idx,
                             ЛЛАтрибут A);
LLEXPORT unsigned ЛЛДайСчётАтровПоИндексу(ЛЛЗначение F, LLVMAttributeIndex Idx);
LLEXPORT void ЛЛДайАтрыПоИндексу(ЛЛЗначение F, LLVMAttributeIndex Idx,
                              ЛЛАтрибут *Attrs);
LLEXPORT ЛЛАтрибут ЛЛДайАтрПеречняПоИндексу(ЛЛЗначение F,
                                             LLVMAttributeIndex Idx,
                                             unsigned KindID);
LLEXPORT ЛЛАтрибут ЛЛДайТкстАтрПоИндексу(ЛЛЗначение F,
                                               LLVMAttributeIndex Idx,
                                               const char *K, unsigned KLen);
LLEXPORT void ЛЛУдалиАтрПеречняПоИндексу(ЛЛЗначение F, LLVMAttributeIndex Idx, unsigned KindID);
LLEXPORT void ЛЛУдалиТкстАтрПоИндексу(ЛЛЗначение F, LLVMAttributeIndex Idx,
                                      const char *K, unsigned KLen);
LLEXPORT void ЛЛДобавьЦелеЗависимАтрФции(ЛЛЗначение Fn, const char *A,
                                        const char *V);

// Операции над параметрами 

LLEXPORT unsigned ЛЛПосчитайПарамы(ЛЛЗначение FnRef);
LLEXPORT void ЛЛДайПарамы(ЛЛЗначение FnRef, ЛЛЗначение *ParamRefs);
LLEXPORT ЛЛЗначение ЛЛДайПарам(ЛЛЗначение FnRef, unsigned index);
LLEXPORT ЛЛЗначение ЛЛДайПредкаПарам(ЛЛЗначение V);
LLEXPORT ЛЛЗначение ЛЛДайПервПарам(ЛЛЗначение Fn);
LLEXPORT ЛЛЗначение ЛЛДайПоследнПарам(ЛЛЗначение Fn);
LLEXPORT ЛЛЗначение ЛЛДайСледщПарам(ЛЛЗначение Arg);
LLEXPORT ЛЛЗначение ЛЛДайПредшПарам(ЛЛЗначение Arg);
LLEXPORT void ЛЛУстРаскладПарама(ЛЛЗначение Arg, unsigned align) ;

// Операции над ifuncs

LLEXPORT ЛЛЗначение ЛЛДобавьГлобИФункц(ЛЛМодуль M,
                                const char *Name, size_t NameLen,
                                ЛЛТип Ty, unsigned AddrSpace,
                                ЛЛЗначение Resolver);
LLEXPORT ЛЛЗначение ЛЛДайИменованГлобИФункц(ЛЛМодуль M,
                                     const char *Name, size_t NameLen);
LLEXPORT ЛЛЗначение ЛЛДайПервГлобИФункц(ЛЛМодуль M);
LLEXPORT ЛЛЗначение ЛЛДайПоследнГлобИФункц(ЛЛМодуль M);
LLEXPORT ЛЛЗначение ЛЛДайСледщГлобИФункц(ЛЛЗначение IFunc);
LLEXPORT ЛЛЗначение ЛЛДайПредшГлобИФункц(ЛЛЗначение IFunc);
LLEXPORT ЛЛЗначение ЛЛДайРезольверГлобИФункц(ЛЛЗначение IFunc);
LLEXPORT void ЛЛУстРезольверГлобИФункц(ЛЛЗначение IFunc, ЛЛЗначение Resolver);
LLEXPORT void ЛЛСотриГлобИФункц(ЛЛЗначение IFunc);
LLEXPORT void ЛЛУдалиГлобИФункц(ЛЛЗначение IFunc);

// Операции над базовыми блоками 

LLEXPORT ЛЛЗначение ЛЛБазБлокКакЗначение(ЛЛБазовыйБлок BB);
LLEXPORT LLVMBool ЛЛЗначение_БазБлок_ли(ЛЛЗначение Val);
LLEXPORT ЛЛБазовыйБлок ЛЛЗначениеКакБазБлок(ЛЛЗначение Val);
LLEXPORT const char *ЛЛДайИмяБазБлока(ЛЛБазовыйБлок BB);
LLEXPORT ЛЛЗначение ЛЛДайРодителяБазБлока(ЛЛБазовыйБлок BB);
LLEXPORT ЛЛЗначение ЛЛДайТерминаторБазБлока(ЛЛБазовыйБлок BB);
LLEXPORT unsigned ЛЛПосчитайБазБлоки(ЛЛЗначение FnRef) ;
LLEXPORT void ЛЛДайБазБлоки(ЛЛЗначение FnRef, ЛЛБазовыйБлок *BasicBlocksRefs);
LLEXPORT ЛЛБазовыйБлок ЛЛДайВводнБазБлок(ЛЛЗначение Fn);
LLEXPORT ЛЛБазовыйБлок ЛЛДайПервБазБлок(ЛЛЗначение Fn);
LLEXPORT ЛЛБазовыйБлок ЛЛДайПоследнБазБлок(ЛЛЗначение Fn);
LLEXPORT ЛЛБазовыйБлок ЛЛДайСледщБазБлок(ЛЛБазовыйБлок BB);
LLEXPORT ЛЛБазовыйБлок ЛЛДайПредшБазБлок(ЛЛБазовыйБлок BB);
LLEXPORT ЛЛБазовыйБлок ЛЛСоздайБазБлокВКонтексте(ЛЛКонтекст C, const char *Name);
LLEXPORT void ЛЛВставьСущБазБлокПослеБлокаВставки(ЛЛПостроитель Builder, ЛЛБазовыйБлок BB);
LLEXPORT void ЛЛПриставьСущБазБлок(ЛЛЗначение Fn,
                                  ЛЛБазовыйБлок BB);
LLEXPORT ЛЛБазовыйБлок ЛЛПриставьБазБлокВКонтексте(ЛЛКонтекст C, ЛЛЗначение FnRef, const char *Name);
LLEXPORT ЛЛБазовыйБлок ЛЛПриставьБазБлок(ЛЛЗначение FnRef, const char *Name);
LLEXPORT ЛЛБазовыйБлок ЛЛВставьБазБлокВКонтекст(ЛЛКонтекст C,
                                                ЛЛБазовыйБлок BBRef,
                                                const char *Name);
LLEXPORT ЛЛБазовыйБлок ЛЛВставьБазБлок(ЛЛБазовыйБлок BBRef,
                                       const char *Name);
LLEXPORT void ЛЛУдалиБазБлок(ЛЛБазовыйБлок BBRef) ;
LLEXPORT void ЛЛУдалиБазБлокИзРодителя(ЛЛБазовыйБлок BBRef);
LLEXPORT void ЛЛПоставьБазБлокПеред(ЛЛБазовыйБлок BB, ЛЛБазовыйБлок MovePos);
LLEXPORT void ЛЛПоставьБазБлокПосле(ЛЛБазовыйБлок BB, ЛЛБазовыйБлок MovePos);

// Операции над инструкциями 

LLEXPORT ЛЛБазовыйБлок ЛЛДайРодителяИнстр(ЛЛЗначение Inst);
LLEXPORT ЛЛЗначение ЛЛДайПервИнстр(ЛЛБазовыйБлок BB) ;
LLEXPORT ЛЛЗначение ЛЛДайПоследнИнстр(ЛЛБазовыйБлок BB);
LLEXPORT ЛЛЗначение ЛЛДайСледщИнстр(ЛЛЗначение Inst);
LLEXPORT ЛЛЗначение ЛЛДайПредшИнстр(ЛЛЗначение Inst);
LLEXPORT void ЛЛИнструкция_УдалиИзРодителя(ЛЛЗначение Inst);
LLEXPORT void ЛЛИнструкция_СотриИзРодителя(ЛЛЗначение Inst);
LLEXPORT LLVMIntPredicate ЛЛДайПредикатЦСравн(ЛЛЗначение Inst);
LLEXPORT LLVMRealPredicate ЛЛДайПредикатПСравн(ЛЛЗначение Inst);
LLEXPORT LLVMOpcode ЛЛДайОпкодИнстр(ЛЛЗначение Inst) ;
LLEXPORT ЛЛЗначение ЛЛИнструкция_Клонируй(ЛЛЗначение Inst);
LLEXPORT ЛЛЗначение ЛЛИнстрТерминатор_ли(ЛЛЗначение Inst);
LLEXPORT unsigned ЛЛДайЧлоАргОперандов(ЛЛЗначение Instr);

// Вызов и выполнение инструкций 

LLEXPORT unsigned ЛЛДайКонвВызИнстр(ЛЛЗначение Instr);
LLEXPORT void ЛЛУстКонвВызИнстр(ЛЛЗначение Instr, unsigned CC);
LLEXPORT void ЛЛУстРаскладПарамовИнстр(ЛЛЗначение Instr, unsigned index,
                                unsigned align);
LLEXPORT void ЛЛДобавьАтрМестаВызова(ЛЛЗначение C, LLVMAttributeIndex Idx,
                              ЛЛАтрибут A);
LLEXPORT unsigned ЛЛДайЧлоАтровМестаВызова(ЛЛЗначение C,
                                       LLVMAttributeIndex Idx);
LLEXPORT void ЛЛДайАтрыМестаВызова(ЛЛЗначение C, LLVMAttributeIndex Idx,
                               ЛЛАтрибут *Attrs);
LLEXPORT ЛЛАтрибут ЛЛДайАтрыПеречняМестаВызова(ЛЛЗначение C, LLVMAttributeIndex Idx,
  unsigned KindID);
LLEXPORT ЛЛАтрибут ЛЛДайТкстАтрыМестаВызова(ЛЛЗначение C, LLVMAttributeIndex Idx,
   const char *K, unsigned KLen) ;
LLEXPORT void ЛЛУдалиАтрПеречняМестаВызова(ЛЛЗначение C, LLVMAttributeIndex Idx, unsigned KindID) ;
LLEXPORT void ЛЛУдалиТкстАтрМестаВызова(ЛЛЗначение C, LLVMAttributeIndex Idx, const char *K, 
    unsigned KLen);
LLEXPORT ЛЛЗначение ЛЛДайВызванноеЗнач(ЛЛЗначение Instr) ;
LLEXPORT ЛЛТип ЛЛДайТипВызваннойФункц(ЛЛЗначение Instr) ;

// Операции над инструкциями вызова (только call) 

LLEXPORT LLVMBool ЛЛТейлВызов_ли(ЛЛЗначение Call);
LLEXPORT void ЛЛУстТейлВызов(ЛЛЗначение Call, LLVMBool isTailCall);

// Операции над инструкциями выполнения (только invoke) 

LLEXPORT ЛЛБазовыйБлок ЛЛДайНормальнПриёмник(ЛЛЗначение Invoke);
LLEXPORT ЛЛБазовыйБлок ЛЛДайПриёмникОтмотки(ЛЛЗначение Invoke);
LLEXPORT void ЛЛУстНормальнПриёмник(ЛЛЗначение Invoke, ЛЛБазовыйБлок B) ;
LLEXPORT void ЛЛУстПриёмникОтмотки(ЛЛЗначение Invoke, ЛЛБазовыйБлок B) ;

// Операции над терминаторами 

LLEXPORT unsigned ЛЛДайЧлоПоследователей(ЛЛЗначение Term);
LLEXPORT ЛЛБазовыйБлок ЛЛДайПоследователи(ЛЛЗначение Term, unsigned i);
LLEXPORT void ЛЛУстПоследователь(ЛЛЗначение Term, unsigned i, ЛЛБазовыйБлок block);

// Операции над инструкциями ветвления (только) 

LLEXPORT LLVMBool ЛЛУсловн_ли(ЛЛЗначение Branch);
LLEXPORT ЛЛЗначение ЛЛДайУсловие(ЛЛЗначение Branch);
LLEXPORT void ЛЛУстУсловие(ЛЛЗначение Branch, ЛЛЗначение Cond);

// Операции над инструкциями переключения (только) 

LLEXPORT ЛЛБазовыйБлок ЛЛДайДефПриёмникРеле(ЛЛЗначение Switch);

// Операции над инструкциями alloca (только)

LLEXPORT ЛЛТип ЛЛДайРазмещТип(ЛЛЗначение Alloca) ;

// Операции над инструкциями gep (только) 

LLEXPORT LLVMBool ЛЛвПределах_ли(ЛЛЗначение GEP);
LLEXPORT void ЛЛУстВПределах(ЛЛЗначение GEP, LLVMBool InBounds);

// Операции над узлами phi 

LLEXPORT void ЛЛДобавьВходящ(ЛЛЗначение PhiNode, ЛЛЗначение *IncomingValues,
                     ЛЛБазовыйБлок *IncomingBlocks, unsigned Count);
LLEXPORT unsigned ЛЛПосчитайВходящ(ЛЛЗначение PhiNode);
LLEXPORT ЛЛЗначение ЛЛДайВходящЗнач(ЛЛЗначение PhiNode, unsigned Index);
LLEXPORT ЛЛБазовыйБлок ЛЛДайВходящБлок(ЛЛЗначение PhiNode, unsigned Index);

// Операции над узлами extractvalue и insertvalue 

LLEXPORT unsigned ЛЛДайЧлоИндексов(ЛЛЗначение Inst);
LLEXPORT const unsigned *ЛЛДайИндексы(ЛЛЗначение Inst);

// Построители инструкций 

LLEXPORT ЛЛПостроитель ЛЛСоздайПостроительВКонтексте(ЛЛКонтекст C);
LLEXPORT ЛЛПостроитель ЛЛСоздайПостроитель(void);
LLEXPORT void ЛЛПостроительПозиции(ЛЛПостроитель Builder, ЛЛБазовыйБлок Block,
                         ЛЛЗначение Instr) ;
LLEXPORT void ЛЛПостроительПозицииПеред(ЛЛПостроитель Builder, ЛЛЗначение Instr) ;
LLEXPORT void ЛЛПостроительПозицииВКонце(ЛЛПостроитель Builder, ЛЛБазовыйБлок Block);
LLEXPORT ЛЛБазовыйБлок ЛЛДайБлокВставки(ЛЛПостроитель Builder) ;
LLEXPORT void ЛЛОчистиПозициюВставки(ЛЛПостроитель Builder) ;
LLEXPORT void ЛЛВставьВПостроитель(ЛЛПостроитель Builder, ЛЛЗначение Instr) ;
LLEXPORT void ЛЛВставьВПостроительСИменем(ЛЛПостроитель Builder, ЛЛЗначение Instr, 
  const char *Name) ;
LLEXPORT void ЛЛВыместиПостроитель(ЛЛПостроитель Builder);

// Построители метаданных 

LLEXPORT ЛЛМетаданные ЛЛДайТекЛокОтладки2(ЛЛПостроитель Builder);
LLEXPORT void ЛЛУстТекЛокОтладки2(ЛЛПостроитель Builder, ЛЛМетаданные Loc);
LLEXPORT void ЛЛУстТекЛокОтладки(ЛЛПостроитель Builder, ЛЛЗначение L);
LLEXPORT ЛЛЗначение ЛЛДайТекЛокОтладки(ЛЛПостроитель Builder);
LLEXPORT void ЛЛУстТекЛокОтладкиИнстр(ЛЛПостроитель Builder, ЛЛЗначение Inst);
LLEXPORT void ЛЛПостроитель_УстДефПЗМатТег(ЛЛПостроитель Builder,
                                    ЛЛМетаданные FPMathTag);
LLEXPORT ЛЛМетаданные ЛЛПостроитель_ДайДефПЗМатТег(ЛЛПостроитель Builder);

// Построители инструкций

LLEXPORT ЛЛЗначение ЛЛСтройВозврПроц(ЛЛПостроитель B);
LLEXPORT ЛЛЗначение ЛЛСтройВозвр(ЛЛПостроитель B, ЛЛЗначение V);
LLEXPORT ЛЛЗначение ЛЛСтройАгрегатВозвр(ЛЛПостроитель B, ЛЛЗначение *RetVals, unsigned N);
LLEXPORT ЛЛЗначение ЛЛСтройБр(ЛЛПостроитель B, ЛЛБазовыйБлок Dest);
LLEXPORT ЛЛЗначение ЛЛСтройУсловнБр(ЛЛПостроитель B, ЛЛЗначение If,
                             ЛЛБазовыйБлок Then, ЛЛБазовыйБлок Else);
LLEXPORT ЛЛЗначение ЛЛСтройЩит(ЛЛПостроитель B, ЛЛЗначение V,
                             ЛЛБазовыйБлок Else, unsigned NumCases);
LLEXPORT ЛЛЗначение ЛЛСтройНепрямБр(ЛЛПостроитель B, ЛЛЗначение Addr,
                                 unsigned NumDests);
LLEXPORT ЛЛЗначение ЛЛСтройИнвок(ЛЛПостроитель B, ЛЛЗначение Fn,
                             ЛЛЗначение *Args, unsigned NumArgs,
                             ЛЛБазовыйБлок Then, ЛЛБазовыйБлок Catch,
                             const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройИнвок2(ЛЛПостроитель B, ЛЛТип Ty, ЛЛЗначение Fn,
                              ЛЛЗначение *Args, unsigned NumArgs,
                              ЛЛБазовыйБлок Then, ЛЛБазовыйБлок Catch,
                              const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтойЛэндингПад(ЛЛПостроитель B, ЛЛТип Ty,
                                 ЛЛЗначение PersFn, unsigned NumClauses,
                                 const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройКэчПад(ЛЛПостроитель B, ЛЛЗначение ParentPad,
                               ЛЛЗначение *Args, unsigned NumArgs,
                               const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройОчистиПад(ЛЛПостроитель B, ЛЛЗначение ParentPad,
                                 ЛЛЗначение *Args, unsigned NumArgs,
                                 const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройВозобнови(ЛЛПостроитель B, ЛЛЗначение Exn);
LLEXPORT ЛЛЗначение ЛЛСтройКэчЩит(ЛЛПостроитель B, ЛЛЗначение ParentPad, 
    ЛЛБазовыйБлок UnwindBB, unsigned NumHandlers, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройКэчВозвр(ЛЛПостроитель B, ЛЛЗначение CatchPad,
                               ЛЛБазовыйБлок BB) ;
LLEXPORT ЛЛЗначение ЛЛСтройОчистиВозвр(ЛЛПостроитель B, ЛЛЗначение CatchPad,
                                 ЛЛБазовыйБлок BB) ;
LLEXPORT ЛЛЗначение ЛЛСтройНедоступный(ЛЛПостроитель B);
LLEXPORT void ЛЛДобавьРеле(ЛЛЗначение Switch, ЛЛЗначение OnVal,
                 ЛЛБазовыйБлок Dest);
LLEXPORT void ЛЛДобавьПриёмник(ЛЛЗначение IndirectBr, ЛЛБазовыйБлок Dest);
LLEXPORT unsigned ЛЛДайЧлоКлоз(ЛЛЗначение LandingPad);
LLEXPORT ЛЛЗначение ЛЛДайКлоз(ЛЛЗначение LandingPad, unsigned Idx);
LLEXPORT void ЛЛДобавьКлоз(ЛЛЗначение LandingPad, ЛЛЗначение ClauseVal);
LLEXPORT LLVMBool ЛЛОчистка_ли(ЛЛЗначение LandingPad);
LLEXPORT void ЛЛУстОчистку(ЛЛЗначение LandingPad, LLVMBool Val);
LLEXPORT void ЛЛДобавьОбработчик(ЛЛЗначение CatchSwitch, ЛЛБазовыйБлок Dest);
LLEXPORT unsigned ЛЛДайЧлоОбработчиков(ЛЛЗначение CatchSwitch);
LLEXPORT void ЛЛДайОбработчики(ЛЛЗначение CatchSwitch, ЛЛБазовыйБлок *Handlers);
LLEXPORT ЛЛЗначение ЛЛДайРодительскКэчЩит(ЛЛЗначение CatchPad) ;
LLEXPORT void ЛЛУстРодительскКэчЩит(ЛЛЗначение CatchPad, ЛЛЗначение CatchSwitch);

// Функлеты 

LLEXPORT ЛЛЗначение ЛЛДайАргОперанд(ЛЛЗначение Funclet, unsigned i);
LLEXPORT void ЛЛУстАргОперанд(ЛЛЗначение Funclet, unsigned i, ЛЛЗначение value) ;

// Арифметика 

LLEXPORT ЛЛЗначение ЛЛСтройСложи(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name);
LLEXPORT ЛЛЗначение LLBuildNSWAdd(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name);
LLEXPORT ЛЛЗначение LLBuildNUWAdd(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройПСложи(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройОтними(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение LLBuildNSWSub(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name);
LLEXPORT ЛЛЗначение LLBuildNUWSub(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройПОтними(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name) ;
LLEXPORT ЛЛЗначение ЛЛСтройУмножь(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name);
LLEXPORT ЛЛЗначение LLBuildNSWMul(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,   const char *Name);
LLEXPORT ЛЛЗначение LLBuildNUWMul(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройПУмножь(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,   const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройБДели(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройТочноБДели(ЛЛПостроитель B, ЛЛЗначение LHS,
                                ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройЗДели(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройТочноЗДели(ЛЛПостроитель B, ЛЛЗначение LHS,
                                ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройПДели(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение LLBuildURem(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name);
LLEXPORT ЛЛЗначение LLBuildSRem(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение LLBuildFRem(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение LLBuildShl(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение LLBuildLShr(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение LLBuildAShr(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройИ(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS,  const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройИли(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройИИли(ЛЛПостроитель B, ЛЛЗначение LHS, ЛЛЗначение RHS, const char *Name) ;
LLEXPORT ЛЛЗначение ЛЛСтройБинОп(ЛЛПостроитель B, LLVMOpcode Op,
                            ЛЛЗначение LHS, ЛЛЗначение RHS,
                            const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройОтриц(ЛЛПостроитель B, ЛЛЗначение V, const char *Name);
LLEXPORT ЛЛЗначение LLBuildNSWNeg(ЛЛПостроитель B, ЛЛЗначение V,
                             const char *Name) ;
LLEXPORT ЛЛЗначение LLBuildNUWNeg(ЛЛПостроитель B, ЛЛЗначение V,
                             const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройПОтриц(ЛЛПостроитель B, ЛЛЗначение V, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройНе(ЛЛПостроитель B, ЛЛЗначение V, const char *Name);

// Память 

LLEXPORT ЛЛЗначение ЛЛСтройРазместПам(ЛЛПостроитель B, ЛЛТип Ty,
                             const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройРазместПамМасс(ЛЛПостроитель B, ЛЛТип Ty,
                                  ЛЛЗначение Val, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройУстПам(ЛЛПостроитель B, ЛЛЗначение Ptr, 
                             ЛЛЗначение Val, ЛЛЗначение Len,
                             unsigned Align);
LLEXPORT ЛЛЗначение ЛЛСтройКопирПам(ЛЛПостроитель B, 
                             ЛЛЗначение Dst, unsigned DstAlign,
                             ЛЛЗначение Src, unsigned SrcAlign,
                             ЛЛЗначение Size);
LLEXPORT ЛЛЗначение ЛЛСтройПреместПам(ЛЛПостроитель B,
                              ЛЛЗначение Dst, unsigned DstAlign,
                              ЛЛЗначение Src, unsigned SrcAlign,
                              ЛЛЗначение Size);
LLEXPORT ЛЛЗначение ЛЛСтройАллока(ЛЛПостроитель B, ЛЛТип Ty,
                             const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройАллокаМасс(ЛЛПостроитель B, ЛЛТип Ty,
                                  ЛЛЗначение Val, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройОсвободи(ЛЛПостроитель B, ЛЛЗначение PointerVal);
LLEXPORT ЛЛЗначение ЛЛСтройЗагрузи(ЛЛПостроитель B, ЛЛЗначение PointerVal,
                           const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройЗагрузи2(ЛЛПостроитель B, ЛЛТип Ty,
                            ЛЛЗначение PointerVal, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройСохрани(ЛЛПостроитель B, ЛЛЗначение Val,
                            ЛЛЗначение PointerVal);
LLEXPORT ЛЛЗначение ЛЛСтройЗабор(ЛЛПостроитель B, LLVMAtomicOrdering Ordering,
                            LLVMBool isSingleThread, const char *Name);
LLEXPORT ЛЛЗначение LLBuildGEP(ЛЛПостроитель B, ЛЛЗначение Pointer,
                          ЛЛЗначение *Indices, unsigned NumIndices,
                          const char *Name);
LLEXPORT ЛЛЗначение LLBuildGEP2(ЛЛПостроитель B, ЛЛТип Ty,
                           ЛЛЗначение Pointer, ЛЛЗначение *Indices,
                           unsigned NumIndices, const char *Name);
LLEXPORT ЛЛЗначение LLBuildInBoundsGEP(ЛЛПостроитель B, ЛЛЗначение Pointer,
                                  ЛЛЗначение *Indices, unsigned NumIndices,
                                  const char *Name);
LLEXPORT ЛЛЗначение LLBuildInBoundsGEP2(ЛЛПостроитель B, ЛЛТип Ty,
                                   ЛЛЗначение Pointer, ЛЛЗначение *Indices,
                                   unsigned NumIndices, const char *Name);
LLEXPORT ЛЛЗначение LLBuildStructGEP(ЛЛПостроитель B, ЛЛЗначение Pointer,
                                unsigned Idx, const char *Name) ;
LLEXPORT ЛЛЗначение LLBuildStructGEP2(ЛЛПостроитель B, ЛЛТип Ty,
                                 ЛЛЗначение Pointer, unsigned Idx,
                                 const char *Name) ;
LLEXPORT ЛЛЗначение ЛЛСтройГлобТкст(ЛЛПостроитель B, const char *Str,
                                   const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройГлобТкстУкз(ЛЛПостроитель B, const char *Str,
                                      const char *Name);
LLEXPORT LLVMBool ЛЛДайВолатил(ЛЛЗначение MemAccessInst);
LLEXPORT void ЛЛУстВолатил(ЛЛЗначение MemAccessInst, LLVMBool isVolatile);
LLEXPORT LLVMAtomicOrdering ЛЛДайПорядок(ЛЛЗначение MemAccessInst);
LLEXPORT void ЛЛУстПорядок(ЛЛЗначение MemAccessInst, LLVMAtomicOrdering Ordering);

// Приведение к типу (касты)

LLEXPORT ЛЛЗначение ЛЛСтройОбрежь(ЛЛПостроитель B, ЛЛЗначение Val,
                            ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройНРасш(ЛЛПостроитель B, ЛЛЗначение Val,
                           ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройЗРасш(ЛЛПостроитель B, ЛЛЗначение Val,
                           ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройПЗвБЦ(ЛЛПостроитель B, ЛЛЗначение Val,
                             ЛЛТип DestTy, const char *Name) ;
LLEXPORT ЛЛЗначение ЛЛСтройПЗвЗЦ(ЛЛПостроитель B, ЛЛЗначение Val,
                             ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройБЦвПЗ(ЛЛПостроитель B, ЛЛЗначение Val,
                             ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройЗЦвПЗ(ЛЛПостроитель B, ЛЛЗначение Val,
                             ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройПЗОбрежь(ЛЛПостроитель B, ЛЛЗначение Val,
                              ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройПЗРасш(ЛЛПостроитель B, ЛЛЗначение Val,
                            ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройУкзВЦел(ЛЛПостроитель B, ЛЛЗначение Val,
                               ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройЦелВУкз(ЛЛПостроитель B, ЛЛЗначение Val,
                               ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройБитКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                              ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройАдрПрострКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                                    ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройНРасшИлиБитКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                                    ЛЛТип DestTy, const char *Name) ;
LLEXPORT ЛЛЗначение ЛЛСтройЗРасшИлиБитКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                                    ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройОбрежьИлиБитКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                                     ЛЛТип DestTy, const char *Name) ;
LLEXPORT ЛЛЗначение ЛЛСтройКаст(ЛЛПостроитель B, LLVMOpcode Op, ЛЛЗначение Val, 
    ЛЛТип DestTy, const char *Name) ;
LLEXPORT ЛЛЗначение ЛЛСтройУказательКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                                  ЛЛТип DestTy, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройЦелКаст2(ЛЛПостроитель B, ЛЛЗначение Val,
                               ЛЛТип DestTy, LLVMBool IsSigned,
                               const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройЦелКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                              ЛЛТип DestTy, const char *Name) ;
LLEXPORT ЛЛЗначение ЛЛСтройПЗКаст(ЛЛПостроитель B, ЛЛЗначение Val,
                             ЛЛТип DestTy, const char *Name) ;

// Сравнения 

LLEXPORT ЛЛЗначение ЛЛСтройЦСравн(ЛЛПостроитель B, LLVMIntPredicate Op,
                           ЛЛЗначение LHS, ЛЛЗначение RHS,
                           const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройПСравн(ЛЛПостроитель B, LLVMRealPredicate Op,
                           ЛЛЗначение LHS, ЛЛЗначение RHS,
                           const char *Name);

// Различные инструкции 

LLEXPORT ЛЛЗначение LLBuildPhi(ЛЛПостроитель B, ЛЛТип Ty, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройВызов(ЛЛПостроитель B, ЛЛЗначение Fn,
                           ЛЛЗначение *Args, unsigned NumArgs,
                           const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройВызов2(ЛЛПостроитель B, ЛЛТип Ty, ЛЛЗначение Fn,
 ЛЛЗначение *Args, unsigned NumArgs, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройВыбери(ЛЛПостроитель B, ЛЛЗначение If,
                             ЛЛЗначение Then, ЛЛЗначение Else,
                             const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройВААрг(ЛЛПостроитель B, ЛЛЗначение List,
                            ЛЛТип Ty, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройИзвлекиЭлт(ЛЛПостроитель B, ЛЛЗначение VecVal, 
    ЛЛЗначение Index, const char *Name) ;
LLEXPORT ЛЛЗначение ЛЛСтройВставьЭлт(ЛЛПостроитель B, ЛЛЗначение VecVal,
                                    ЛЛЗначение EltVal, ЛЛЗначение Index,
                                    const char *Name) ;
LLEXPORT ЛЛЗначение ЛЛСтройШафлВектор(ЛЛПостроитель B, ЛЛЗначение V1,
                                    ЛЛЗначение V2, ЛЛЗначение Mask,
                                    const char *Name) ;
LLEXPORT ЛЛЗначение ЛЛСтройИзвлекиЗначение(ЛЛПостроитель B, ЛЛЗначение AggVal,
                                   unsigned Index, const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройВставьЗначение(ЛЛПостроитель B, ЛЛЗначение AggVal,
                                  ЛЛЗначение EltVal, unsigned Index,
                                  const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройПусто(ЛЛПостроитель B, ЛЛЗначение Val,
                             const char *Name);
LLEXPORT ЛЛЗначение ЛЛСтройНеПусто(ЛЛПостроитель B, ЛЛЗначение Val,
                                const char *Name);
LLEXPORT ЛЛЗначение ЛСтройУкзДифф(ЛЛПостроитель B, ЛЛЗначение LHS,
                              ЛЛЗначение RHS, const char *Name);
LLEXPORT ЛЛЗначение LLBuildAtomicRMW(ЛЛПостроитель B, LLVMAtomicRMWBinOp op,
                               ЛЛЗначение PTR, ЛЛЗначение Val,
                               LLVMAtomicOrdering ordering,
                               LLVMBool singleThread);
LLEXPORT ЛЛЗначение LLBuildAtomicCmpXchg(ЛЛПостроитель B, ЛЛЗначение Ptr,
                                    ЛЛЗначение Cmp, ЛЛЗначение New,
                                    LLVMAtomicOrdering SuccessOrdering,
                                    LLVMAtomicOrdering FailureOrdering,
                                    LLVMBool singleThread) ;
LLEXPORT LLVMBool ЛЛАтомнОднонить_ли(ЛЛЗначение AtomicInst);
LLEXPORT void ЛЛУстАтомнОднонить(ЛЛЗначение AtomicInst, LLVMBool NewValue);
LLEXPORT LLVMAtomicOrdering LLGetCmpXchgSuccessOrdering(ЛЛЗначение CmpXchgInst);
LLEXPORT void LLSetCmpXchgSuccessOrdering(ЛЛЗначение CmpXchgInst,
                                   LLVMAtomicOrdering Ordering);
LLEXPORT LLVMAtomicOrdering LLGetCmpXchgFailureOrdering(ЛЛЗначение CmpXchgInst);
LLEXPORT void LLSetCmpXchgFailureOrdering(ЛЛЗначение CmpXchgInst,
                                   LLVMAtomicOrdering Ordering);

// Модуль-провайдеры 

LLEXPORT ЛЛМодульПровайдер
ЛЛСоздайМодульПровайдерДляСущМодуля(ЛЛМодуль M);
LLEXPORT void ЛЛвыместиМодульПровайдер(ЛЛМодульПровайдер MP) ;

// Буферы памяти 

LLEXPORT LLVMBool ЛЛСоздайБуфПамССодержимымФайла(const char *Path, ЛЛБуферПамяти *OutMemBuf,
 char **OutMessage);
LLEXPORT LLVMBool ЛЛСоздайБуфПамСоСТДВХО(ЛЛБуферПамяти *OutMemBuf,
                                         char **OutMessage) ;
LLEXPORT ЛЛБуферПамяти ЛЛСоздайБуфПамСДиапазономПам(
    const char *InputData,  size_t InputDataLength,  const char *BufferName,
    LLVMBool RequiresNullTerminator);
LLEXPORT ЛЛБуферПамяти ЛЛСоздайБуфПамСКопиейДиапазонаПам(
    const char *InputData,  size_t InputDataLength, const char *BufferName);
LLEXPORT const char *ЛЛДайНачалоБуфера(ЛЛБуферПамяти MemBuf);
LLEXPORT size_t ЛЛДайРазмерБуфера(ЛЛБуферПамяти MemBuf);
LLEXPORT void ЛЛВыместиБуферПамяти(ЛЛБуферПамяти MemBuf);

// Реестр Проходок 

LLEXPORT ЛЛРеестрПроходок ЛЛДайГлобРеестрПроходок(void);

// Менеджер Проходок 

LLEXPORT ЛЛМенеджерПроходок ЛЛСоздайМенеджерПроходок(void);
LLEXPORT ЛЛМенеджерПроходок ЛЛСоздайМенеджерФукнцПроходокДляМодуля(ЛЛМодуль M);
LLEXPORT ЛЛМенеджерПроходок ЛЛСоздайМенеджерФукнцПроходок(ЛЛМодульПровайдер P);
LLEXPORT LLVMBool ЛЛЗапустиМенеджерПроходок(ЛЛМенеджерПроходок PM, ЛЛМодуль M) ;
LLEXPORT LLVMBool ЛЛИнициализуйМенеджерФукнцПроходок(ЛЛМенеджерПроходок FPM);
LLEXPORT LLVMBool ЛЛЗапустиМенеджерФукнцПроходок(ЛЛМенеджерПроходок FPM, ЛЛЗначение F) ;
LLEXPORT LLVMBool ЛЛФинализуйМенеджерФукнцПроходок(ЛЛМенеджерПроходок FPM);
LLEXPORT void ЛЛВыместиМенеджерПроходок(ЛЛМенеджерПроходок PM);

// Управление потоками выполнения

LLEXPORT void ЛЛСтопМультинить();
LLEXPORT LLVMBool ЛЛМультинить_ли();
LLEXPORT LLVMBool ЛЛСтартМультинить() ;

}