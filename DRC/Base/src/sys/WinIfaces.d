/**
Модуль интерфейсов WIN API для языка Динрус.
Разработчик Виталий Кулич.
*/
module sys.WinIfaces;
import sys.WinStructs, sys.WinConsts;
import tpl.com;

/**
 * Ассоциирует ГУИД с интерфейсом.
 * Параметры: g = Строка, представляющая ГУИД в нормальном реестровом формате с/без разграничителей { }.
 * Примеры:
 * ---
 * interface IXMLDOMDocument2 : ИДиспетчер {
 *   mixin(ууид("2933bf95-7b36-11d2-b20e-00c04f983e60"));
 * }
 *
 * // Раскрывается в следующий код:
 * //
 * // interface IXMLDOMDocument2 : ИДиспетчер {
 * //   static ГУИД ИИД = { 0x2933bf95, 0x7b36, 0x11d2, 0xb2, 0x0e, 0x00, 0xc0, 0x4f, 0x98, 0x3e, 0x60 };
 * // }
 * ---
 */
 
ткст ууид(ткст g) {

  if (g.length == 38) 
  {
    if(g[0] == '{' && g[$-1] == '}')	
  return ууид(g[1..$-1]);
  }
  else  if (g.length == 36)
  {
    if(g[8] == '-' && g[13] == '-' && g[18] == '-' && g[23] == '-')
	  return "static const ГУИД ИИД = { 0x" ~ g[0..8] ~ ",0x" ~ g[9..13] ~ ",0x" ~ g[14..18] ~ ",0x" ~ g[19..21] ~ ",0x" ~ g[21..23] ~ ",0x" ~ g[24..26] ~ ",0x" ~ g[26..28] ~ ",0x" ~ g[28..30] ~ ",0x" ~ g[30..32] ~ ",0x" ~ g[32..34] ~ ",0x" ~ g[34..36] ~ " };";
  }
  else  throw new Исключение("Неправильный формат для ГУИД.");
  return null;
}
/////////////////////////////////////////////////////////////////////////////////
interface ПотокВвода{  

  проц читайРовно(ук буфер, т_мера размер);
  т_мера читай(ббайт[] буфер);
  проц читай(out байт x);
  проц читай(out ббайт x);	
  проц читай(out крат x);	
  проц читай(out бкрат x);	
  проц читай(out цел x);		
  проц читай(out бцел x);	
  проц читай(out дол x);	
  проц читай(out бдол x);	
  проц читай(out плав x);	
  проц читай(out дво x);	
  проц читай(out реал x);	
  проц читай(out вплав x);	
  проц читай(out вдво x);	
  проц читай(out вреал x);	
  проц читай(out кплав x);	
  проц читай(out кдво x);	
  проц читай(out креал x);	
  проц читай(out сим x);	
  проц читай(out шим x);	
  проц читай(out дим x);	
  проц читай(out ткст s);	
  проц читай(out шим[] s);	
  ткст читайСтр();
  ткст читайСтр(ткст результат);	
  шим[] читайСтрШ();			
  шим[] читайСтрШ(шим[] результат);	
  цел opApply(цел delegate(inout ткст строка) дг);
  цел opApply(цел delegate(inout бдол n, inout ткст строка) дг);  
  цел opApply(цел delegate(inout шим[] строка) дг);		   
  цел opApply(цел delegate(inout бдол n, inout шим[] строка) дг); 
  ткст читайТкст(т_мера length);
  шим[]читайТкстШ(т_мера length);
  сим берис();
  шим бериш(); 
  сим отдайс(сим c);
  шим отдайш(шим c);
  цел вчитайф(ИнфОТипе[] arguments, ук арги);
  цел читайф(...); 
  т_мера доступно();
  бул кф();
  бул открыт_ли();
}

interface ПотокВывода {

проц пишиРовно(ук буфер, т_мера размер);
  т_мера пиши(ббайт[] буфер);
  проц пиши(байт x);
  проц пиши(ббайт x);		
  проц пиши(крат x);		
  проц пиши(бкрат x);		
  проц пиши(цел x);		
  проц пиши(бцел x);		
  проц пиши(дол x);		
  проц пиши(бдол x);		
  проц пиши(плав x);		
  проц пиши(дво x);		
  проц пиши(реал x);		
  проц пиши(вплав x);		
  проц пиши(вдво x);	
  проц пиши(вреал x);		
  проц пиши(кплав x);		
  проц пиши(кдво x);	
  проц пиши(креал x);		
  проц пиши(сим x);		
  проц пиши(шим x);		
  проц пиши(дим x);		
  проц пиши(ткст s);
  проц пиши(шим[] s);	
  проц пишиСтр(ткст s);
  проц пишиСтрШ(шим[] s);
  проц пишиТкст(ткст s);
  проц пишиТкстШ(шим[] s);
  т_мера ввыводф(ткст format, спис_ва арги);
  т_мера выводф(ткст format, ...);	
  ПотокВывода пишиф(...);
  ПотокВывода пишифнс(...); 
  ПотокВывода пишификс(ИнфОТипе[] arguments, ук аргук, цел newline = 0);  

  проц слей();	
  проц закрой(); 
  бул открыт_ли(); 
}
////////////////////////////////////////////////////
interface ИПровайдерФормата {

  Объект GetFormat(ИнфОТипе типФормата); 
  
  /****************************************
  * Объект ДайФормат(ИнфОТипе типФормата);
  *****************************************/
  
}

extern(Windows):

interface IUnknown
 {
  mixin(ууид("00000000-0000-0000-c000-000000000046"));

  цел QueryInterface(ref ГУИД riid, ук* ppvObject);
  бцел AddRef();
  бцел Release();
  
  /*****************Инкогнито*************************
  *
  * цел ОпросиИнтерфейс(ref ГУИД riid, ук* ppvObject);
  * бцел ДобСсыл();
  * бцел Отпусти();
  **************************************************/
  
}
alias IUnknown Инкогнито;
//////////////////////////////////////////////////////
interface IDispatch : Инкогнито {
  mixin(ууид("00020400-0000-0000-c000-000000000046"));

  цел GetTypeInfoCount(out бцел pctinfo);
  цел GetTypeInfo(бцел iTInfo, бцел лкид, out ИИнфОТипе ppTInfo);
  цел GetIDsOfNames(ref ГУИД riid, шим** rgszNames, бцел cNames, бцел лкид, цел* rgDispId);
  цел Invoke(цел dispIdMember, ref ГУИД riid, бцел лкид, бкрат wFlags, ДИСППАРАМЫ* pDispParams, ВАРИАНТ* pVarResult, ИСКЛИНФО* pExcepInfo, бцел* puArgError);
  
  /***********************ИДиспетчер**************************************
  *
  *  цел ДайСчётИнфОТипов(out бцел pctinfo);
  *  цел ДайИнфОТип(бцел iTInfo, бцел лкид, out ИИнфОТипе ppTInfo);
  *  цел ДайИдыИмён(ref ГУИД riid, шим** rgszNames, бцел cNames, бцел лкид, цел* rgDispId);
  *  цел Вызови(цел dispIdMember, ref ГУИД riid, бцел лкид, бкрат wFlags, ДИСППАРАМЫ* pDispParams, ВАРИАНТ* pVarResult, ИСКЛИНФО* pExcepInfo, бцел* puArgError);
  *******************************************************************/
}
alias IDispatch ИДиспетчер;
//////////////////////////////////////
interface ITypeInfo : Инкогнито {
  mixin(ууид("00020401-0000-0000-c000-000000000046"));

  цел GetTypeAttr(out ТИПАТР* ppTypeAttr);
  цел GetTypeComp(out ITypeComp ppTComp);
  цел GetFuncDesc(бцел индекс, out ФУНКЦДЕСКР* ppFuncDesc);
  цел GetVarDesc(бцел индекс, out ПЕРЕМДЕСКР* ppVarDesc);
  цел GetNames(цел memid, шим** rgBstrNames, бцел cMaxNames, out бцел pcNames);
  цел GetRefTypeOfImplType(бцел индекс, out бцел pRefType);
  цел GetImplTypeFlag(бцел индекс, out цел pImplTypeFlag);
  цел GetIDsOfNames(шим** rgszNames, бцел cNames, цел* pMemId);
  цел Invoke(ук pvInstance, цел memid, бкрат wFlags, ДИСППАРАМЫ* pDispParams, ВАРИАНТ* pVarResult, ИСКЛИНФО* pExcepInfo, бцел* puArgErr);
  цел GetDocumentation(цел memid, шим** pBstrName, шим** pBstrDocString, бцел* pКонтекстСправки, шим** pBstrHelpFile);
  цел GetDllEntry(цел memid, ПВидВызова invKind, шим** pBstrDllName, шим** pBstrName, бкрат* pwOrdinal);
  цел GetRefTypeInfo(бцел hRefType, out ИИнфОТипе ppTInfo);
  цел AddressOfMember(цел memid, ПВидВызова invKind, ук* ppv);
  цел CreateInstance(Инкогнито pUnkOuter, ref ГУИД riid, ук* ppvObj);
  цел GetMops(цел memid, шим** pBstrMops);
  цел GetContainingTypeLib(out ITypeLib ppTLib, out бцел pIndex);
  цел ReleaseTypeAttr(ТИПАТР* pTypeAttr);
  цел ReleaseFuncDesc(ФУНКЦДЕСКР* pFuncDesc);
  цел ReleaseVarDesc(ПЕРЕМДЕСКР* pVarDesc);
  
  /****************************ИИнфОТипе*********************************
  *
  * цел ДайАтрТипа(out ТИПАТР* ppTypeAttr);
  * цел GetTypeComp(out ITypeComp ppTComp);
  * цел ДайДескрФункц(бцел индекс, out ФУНКЦДЕСКР* ppFuncDesc);
  * цел ДайДескрПер(бцел индекс, out ПЕРЕМДЕСКР* ppVarDesc);
  * цел ДайИмена(цел memid, шим** rgBstrNames, бцел cMaxNames, out бцел pcNames);
  * цел ДайСсылТипРеализТипа(бцел индекс, out бцел pRefType);
  * цел ДайФлагиРеализТипа(бцел индекс, out цел pImplTypeFlag);
  * цел ДайИдыИмён(шим** rgszNames, бцел cNames, цел* pMemId);
  * цел Вызови(ук pvInstance, цел memid, бкрат wFlags, ДИСППАРАМЫ* pDispParams, ВАРИАНТ* pVarResult, ИСКЛИНФО* pExcepInfo, бцел* puArgErr);
  * цел ДайДокументацию(цел memid, шим** pBstrName, шим** pBstrDocString, бцел* pКонтекстСправки, шим** pBstrHelpFile);
  * цел ДайЗапДлл(цел memid, ПВидВызова invKind, шим** pBstrDllName, шим** pBstrName, бкрат* pwOrdinal);
  * цел ДайИнфСсылТипа(бцел hRefType, out ИИнфОТипе ppTInfo);
  * цел АдресЧлена(цел memid, ПВидВызова invKind, ук* ppv);
  * цел СоздайЭкземпл(Инкогнито pUnkOuter, ref ГУИД riid, ук* ppvObj);
  * цел ДайОпПы(цел memid, шим** pBstrMops);
  * цел ДайВключБибТипов(out ITypeLib ppTLib, out бцел pIndex);
  * цел СбросьАтрТипа(ТИПАТР* pTypeAttr);
  * цел СбросьДескрФункц(ФУНКЦДЕСКР* pFuncDesc);
  * цел СбросьДескрПер(ПЕРЕМДЕСКР* pVarDesc);
  *****************************************************************/
}
alias ITypeInfo ИИнфОТипе;
///////////////////////////////////////////
interface IClassFactory : Инкогнито
 {
  mixin(ууид("00000001-0000-0000-c000-000000000046"));

  цел CreateInstance(Инкогнито pUnkOuter, ref ГУИД riid, ук* ppvObject);
  цел LockServer(цел fLock);
  
 /************************ИФабрикаКласса***********************************
  *
  * цел СоздайЭкземпляр(Инкогнито pUnkOuter, ref ГУИД riid, ук* ppvObject);
  * цел БлокируйСервер(цел fLock);
  *************************************************************************/
}
alias IClassFactory ИФабрикаКласса;
////////////////////////////////////////////////////////
interface IMalloc : Инкогнито {
  mixin(ууид("00000002-0000-0000-c000-000000000046"));

  ук Alloc(т_мера кб);
  ук Realloc(ук pv, т_мера кб);
  проц Free(ук pv);
  т_мера GetSize(ук pv);
  цел DidAlloc(ук pv);
  проц HeapMinimize();
  
  /************ИОператорПамяти**************
  *
  *  ук Размести(т_мера кб);
  *  ук Перемести(ук pv, т_мера кб);
  *  проц Освободи(ук pv);
  *  т_мера ДайРазмер(ук pv);
  *  цел Разместил(ук pv);
  *  проц УменьшиКучу();
  **********************************/
}
alias IMalloc ИОператорПамяти;
/////////////////////////////////////////////////////
interface IMarshal : Инкогнито {
  mixin(ууид("00000003-0000-0000-c000-000000000046"));

  цел GetUnmarshalClass(ref ГУИД riid, ук pv, бцел контекстЦели, ук укНаКонтекстЦели, бцел mshlflags, out ГУИД pCid);
  цел GetMarshalSizeMax(ref ГУИД riid, ук pv, бцел контекстЦели, ук укНаКонтекстЦели, бцел mshlflags, out бцел pSize);
  цел MarshalInterface(ИПоток pStm, ref ГУИД riid, ук pv, бцел контекстЦели, ук укНаКонтекстЦели, бцел mshlflags);
  цел UnmarshalInterface(ИПоток pStm, ref ГУИД riid, ук* ppv);
  цел ReleaseMarshalData(ИПоток pStm);
  цел DisconnectObject(бцел резерв);
  
  /**************************************ИМаршал***********************************************
  *
  *  цел ДайРазмаршКласс(ref ГУИД riid, ук pv, бцел контекстЦели, ук укНаКонтекстЦели, бцел mshlflags, out ГУИД pCid);
  * цел ДайМаксМаршРазм(ref ГУИД riid, ук pv, бцел контекстЦели, ук укНаКонтекстЦели, бцел mshlflags, out бцел pSize);
  * цел МаршИнтерфейс(ИПоток pStm, ref ГУИД riid, ук pv, бцел контекстЦели, ук укНаКонтекстЦели, бцел mshlflags);
  * цел РазмаршИнтерфейс(ИПоток pStm, ref ГУИД riid, ук* ppv);
  * цел СбросьДанные(ИПоток pStm);
  * цел ОтключиОбъект(бцел резерв);
  *****************************************************************************************/

}
alias IMarshal ИМаршал;
/////////////////////////////////////////////////////
interface ISequentialStream : Инкогнито {
  mixin(ууид("0c733a30-2a1c-11ce-ade5-00aa0044773d"));

  цел Read(ук pv, бцел кб, ref бцел кбЧтен);
  цел Write(in ук pv, бцел кб, ref бцел кбСчитанных);
  
  /*******************ИПоследоватнПоток*********************
  *
  * цел Читай(ук pv, бцел кб, ref бцел кбЧтен);
  * цел Пиши(in ук pv, бцел кб, ref бцел кбСчитанных);
  ***************************************************/
}
alias ISequentialStream ИПоследоватнПоток;
///////////////////////////////////////////////

/////////////////////////////////////////////////
interface ILockBytes : Инкогнито {
  mixin(ууид("0000000a-0000-0000-c000-000000000046"));

  цел ReadAt(бдол смещение, ук pv, бцел кб, ref бцел кбЧтен);
  цел WriteAt(бдол смещение, in ук pv, бцел кб, ref бцел кбСчитанных);
  цел Flush();
  цел SetSize(бдол кб);
  цел LockRegion(бдол смещБиб, бдол кб, бцел типБлокир);
  цел UnlockRegion(бдол смещБиб, бдол кб, бцел типБлокир);
  цел Stat(out ОТКРПМБ pstatstg, бцел grfStatFlag);
  
  /***********************ИБайтБлокер***********************************
  *
  *  цел ЧитайВ(бдол смещение, ук pv, бцел кб, ref бцел кбЧтен);
  *  цел ПишиВ(бдол смещение, in ук pv, бцел кб, ref бцел кбСчитанных);
  *  цел Слей();
  *  цел УстановиРазм(бдол кб);
  *  цел БлокируйРгн(бдол смещБиб, бдол кб, бцел типБлокир);
  *  цел РазблокируйРгн(бдол смещБиб, бдол кб, бцел типБлокир);
  *  цел Стат(out ОТКРПМБ pstatstg, бцел grfStatFlag);
  ********************************************************************/
  }
alias ILockBytes ИБайтБлокер;
////////////////////////////////////////////////////////
interface IStorage : Инкогнито {
  mixin(ууид("0000000b-0000-0000-c000-000000000046"));

  цел CreateStream(шим* укНаШ0Имя, бцел послРежДост, бцел reserved1, бцел reserved2, out ИПоток ppstm);
  цел OpenStream(шим* укНаШ0Имя, ук reserved1, бцел послРежДост, бцел reserved2, out ИПоток ppstm);
  цел CreateStorage(шим* укНаШ0Имя, бцел послРежДост, бцел reserved1, бцел reserved2, out ИХранилище ppstg);
  цел OpenStorage(шим* укНаШ0Имя, ИХранилище psrgPriority, бцел послРежДост, шим** snbExclude, бцел резерв, out ИХранилище ppstg);
  цел CopyTo(бцел ciidExclude, ГУИД* rgiidExclude, шим** snbExclude, ИХранилище pstgDest);
  цел MoveElementTo(шим* укНаШ0Имя, ИХранилище pstgDest, шим* pwcsNewName, бцел мсоФлаги);
  цел Commit(бцел grfCommitFlags);
  цел Revert();
  цел EnumElements(бцел reserved1, ук reserved2, бцел reserved3, out ИОТКРПМБПеречень ppenum);
  цел DestroyElement(шим* укНаШ0Имя);
  цел RenameElement(шим* pwcsOldName, шим* pwcsNewName);
  цел SetElementTimes(шим* укНаШ0Имя, ref ФВРЕМЯ pctime, ref ФВРЕМЯ patime, ref ФВРЕМЯ pmtime);
  цел SetClass(ref ГУИД клсид);
  цел SetStateBits(бцел битыТекСостХр, бцел grfMask);
  цел Stat(out ОТКРПМБ pstatstg, бцел grfStatFlag);  
  
  /***********************************ИХранилище**********************************************
  *
  *  цел СоздайПоток(шим* укНаШ0Имя, бцел послРежДост, бцел reserved1, бцел reserved2, out ИПоток ppstm);
  *  цел ОткройПоток(шим* укНаШ0Имя, ук reserved1, бцел послРежДост, бцел reserved2, out ИПоток ppstm);
  *  цел СоздайХранилище(шим* укНаШ0Имя, бцел послРежДост, бцел reserved1, бцел reserved2, out ИХранилище ppstg);
  *  цел ОткройХранилище(шим* укНаШ0Имя, ИХранилище psrgPriority, бцел послРежДост, шим** snbExclude, бцел резерв, out ИХранилище ppstg);
  *  цел Копируй_в(бцел ciidExclude, ГУИД* rgiidExclude, шим** snbExclude, ИХранилище pstgDest);
  *  цел ПереместиЭлт_в(шим* укНаШ0Имя, ИХранилище pstgDest, шим* pwcsNewName, бцел мсоФлаги);
  *  цел Подай(бцел grfCommitFlags);
  *  цел Обрати();
  *  цел ПеречислиЭлты(бцел reserved1, ук reserved2, бцел reserved3, out ИОТКРПМБПеречень ppenum);
  *  цел УдалиЭлт(шим* укНаШ0Имя);
  *  цел ПереименуйЭлт(шим* pwcsOldName, шим* pwcsNewName);
  *  цел УстановиВремяЭлта(шим* укНаШ0Имя, ref ФВРЕМЯ pctime, ref ФВРЕМЯ patime, ref ФВРЕМЯ pmtime);
  *  цел УстановиКласс(ref ГУИД клсид);
  *  цел УстановиБитыСостояния(бцел битыТекСостХр, бцел grfMask);
  *  цел Стат(out ОТКРПМБ pstatstg, бцел grfStatFlag);
  ****************************************************************************************/
}
alias IStorage ИХранилище;
//////////////////////////////////////////////////////////////
interface IStream : ИПоследоватнПоток {
  mixin(ууид("0000000c-0000-0000-c000-000000000046"));

  цел Seek(дол dlibMove, бцел dwOrigin, ref бдол plibNewPosition);
  цел SetSize(бдол libNewSize);
  цел CopyTo(ИПоток stm, бдол кб, ref бдол кбЧтен, ref бдол кбСчитанных);
  цел Commit(бцел hrfCommitFlags);
  цел Revert();
  цел LockRegion(бдол смещБиб, бдол кб, бцел типБлокир);
  цел UnlockRegion(бдол смещБиб, бдол кб, бцел типБлокир);
  цел Stat(out ОТКРПМБ pstatstg, бцел grfStatFlag);
  цел Clone(out ИПоток ppstm);  
  
  /***************************ИПоток**********************************
  *
  *  цел Сместись(дол dlibMove, бцел dwOrigin, ref бдол plibNewPosition);
  *  цел УстановиРазм(бдол libNewSize);
  *  цел Копируй_в(ИПоток stm, бдол кб, ref бдол кбЧтен, ref бдол кбСчитанных);
  *  цел Подай(бцел hrfCommitFlags);
  *  цел Обрати();
  *  цел БлокируйРгн(бдол смещБиб, бдол кб, бцел типБлокир);
  *  цел РазблокируйРгн(бдол смещБиб, бдол кб, бцел типБлокир);
  *  цел Стат(out ОТКРПМБ pstatstg, бцел grfStatFlag);
  *  цел Клонируй(out ИПоток ppstm);
  ***********************************************************************/
}
alias IStream ИПоток;
//////////////////////////////////////////////////////////////////
interface IEnumSTATSTG : Инкогнито {
  mixin(ууид("0000000d-0000-0000-c000-000000000046"));

  цел Next(бцел celt, ОТКРПМБ* rgelt, out бцел pceltFetched);
  цел Skip(бцел celt);
  цел Reset();
  цел Clone(out ИОТКРПМБПеречень ppenum);  
  
  /***********************ИОТКРПМБПеречень***************************
  *
  *  цел Следщ(бцел celt, ОТКРПМБ* rgelt, out бцел pceltFetched);
  *  цел Пропусти(бцел celt);
  *  цел Переустанови();
  *  цел Клонируй(out ИОТКРПМБПеречень ppenum);
  **************************************************************/
}
alias IEnumSTATSTG ИОТКРПМБПеречень;
/////////////////////////////////////////////////////////////////
interface IRecordInfo : Инкогнито {
  mixin(ууид("0000002f-0000-0000-c000-000000000046"));

  цел RecordInit(ук pvNew);
  цел RecordClear(ук pvExisting);
  цел RecordCopy(ук pvExisting, ук pvNew);
  цел GetGuid(out ГУИД pguid);
  цел GetName(out шим* pbstrName);
  цел GetSize(out бцел pразмер);
  цел GetTypeInfo(out ИИнфОТипе ppTypeInfo);
  цел GetField(ук pvData, шим* szFieldName, out ВАРИАНТ pvarField);
  цел GetFieldNoCopy(ук pvData, шим* szFieldName, out ВАРИАНТ pvarField, ук* ppvDataCArray);
  цел PutField(бцел wFlags, ук pvData, шим* szFieldName, ref ВАРИАНТ pvarField);
  цел PutFieldNoCopy(бцел wFlags, ук pvData, шим* szFieldName, ref ВАРИАНТ pvarField);
  цел GetFieldNames(out бцел pcNames, шим** rgBstrNames);
  бул IsMatchingType(IRecordInfo pRecordInfo);
  ук RecordCreate();
  цел RecordCreateCopy(ук pvSource, out ук ppvDest);
  цел RecordDestroy(ук запись);  
  
  /*****************************ИИнфОЗаписи****************************
  *
  *  цел ИницЗап(ук pvNew);
  *  цел СотриЗап(ук pvExisting);
  *  цел КопируйЗап(ук pvExisting, ук pvNew);
  *  цел ДайГуид(out ГУИД pguid);
  *  цел ДайИмя(out шим* pbstrName);
  *  цел ДайРазм(out бцел pразмер);
  *  цел ДайИнфОТипе(out ИИнфОТипе ppTypeInfo);
  *  цел ДайПоле(ук pvData, шим* szFieldName, out ВАРИАНТ pvarField);
  *  цел ДайПолеНеКопируя(ук pvData, шим* szFieldName, out ВАРИАНТ pvarField, ук* ppvDataCArray);
  *  цел ВставьПоле(бцел wFlags, ук pvData, шим* szFieldName, ref ВАРИАНТ pvarField);
  *  цел ВставьПолеНеКопируя(бцел wFlags, ук pvData, шим* szFieldName, ref ВАРИАНТ pvarField);
  *  цел ДайИменаПолей(out бцел pcNames, шим** rgBstrNames);
  *  бул ТипСовпадает(IRecordInfo pRecordInfo);
  *  ук СоздайЗап();
  *  цел СоздайКопиюЗап(ук pvSource, out ук ppvDest);
  *  цел УдалиЗап(ук запись);
  ********************************************************/
}
alias IRecordInfo ИИнфОЗаписи;
////////////////////////////////////////////////////////////
interface IBindCtx : Инкогнито {
  mixin(ууид("0000000e-0000-0000-c000-000000000046"));

  цел RegisterObjectBound(Инкогнито punk);
  цел RevokeObjectBound(Инкогнито punk);
  цел ReleaseBoundObjects();
  цел SetBindOptions(СВЯЗОПЦИИ* pbindopts);
  цел GetBindOptions(СВЯЗОПЦИИ* pbindopts);
  цел GetRunningObjectTable(out IRunningObjectTable pprot);
  цел RegisterObjectParam(шим* pszKey, Инкогнито punk);
  цел GetObjectParam(шим* pszKey, out Инкогнито ppunk);
  цел EnumObjectParam(out IEnumString ppenum);
  цел RemoveObjectParam(шим* pszKey);
  
  /************ИКонкстСвязки***************
   *
   * цел РегистрируйСвязанныйОбъект(Инкогнито punk);
   * цел ПеревызовиСвязанныйОбъект(Инкогнито punk);
   * цел СбросьСвязанныеОбъекты();
   * цел УстановиОпцииСвязки(СВЯЗ_ОПЦИИ* pbindopts);
   * цел ДайОпцииСвязки(СВЯЗ_ОПЦИИ* pbindopts);
   * цел ДайТаблицуВыполняемогоОбъекта(out IRunningObjectTable pprot);
   * цел РегистрируйПарамОбъекта(шим* pszKey, Инкогнито punk);
   * цел ДайПарамОбъекта(шим* pszKey, out Инкогнито ppunk);
   * цел ПеречислиПарамОбъекта(out IEnumString ppenum);
   * цел УдалиПарамОбъекта(шим* pszKey);
  ************************************************/
}
alias IBindCtx ИКонкстСвязки;
////////////////////////////////////////////
interface IMoniker : IPersistStream {
  mixin(ууид("0000000f-0000-0000-c000-000000000046"));

  цел BindToObject(ИКонкстСвязки pbc, IMoniker pmkToLeft, ref ГУИД riidResult, ук* ppvResult);
  цел BindToStorage(ИКонкстСвязки pbc, IMoniker pmkToLeft, ref ГУИД riid, ук* ppv);
  цел Reduce(ИКонкстСвязки pbc, бцел dwReduceHowFar, ref IMoniker ppmkToLeft, out IMoniker ppmkReduced);
  цел ComposeWith(IMoniker pmkRight, бул fOnlyIfNotGeneric, out IMoniker ppmkComposite);
  цел Enum(бул fForward, out IEnumMoniker ppenumMoniker);
  цел IsEqual(IMoniker pmkOtherMoniker);
  цел Hash(out бцел pdwHash);
  цел IsRunning(ИКонкстСвязки pbc, IMoniker pmkToLeft, IMoniker pmkNewlyRunning);
  цел GetTimeOfLastChange(ИКонкстСвязки pbc, IMoniker pmkToLeft, out ФВРЕМЯ pFileTime);
  цел Inverse(out IMoniker ppmk);
  цел CommonPrefixWith(IMoniker pmkOther, out IMoniker ppmkPrefix);
  цел RelativePathTo(IMoniker pmkOther, out IMoniker ppmkRelPath);
  цел GetDisplayName(ИКонкстСвязки pbc, IMoniker pmkToLeft, out шим* ppszDisplayName);
  цел ParseDisplayName(ИКонкстСвязки pbc, IMoniker pmkToLeft, шим* pszDisplayName, out бцел pchEaten, out IMoniker ppmkOut);
  цел IsSystemMoniker(out бцел pswMkSys);
}

///////////////////////////////////
interface IRunningObjectTable : Инкогнито {
  mixin(ууид("00000010-0000-0000-c000-000000000046"));

  цел Register(бцел мсоФлаги, Инкогнито punkObject, IMoniker pmkObjectName, out бцел pdwRegister);
  цел Revoke(бцел dwRegister);
  цел IsRunning(IMoniker pmkObjectName);
  цел GetObject(IMoniker pmkObjectName, out Инкогнито ppunkObject);
  цел NoteChangeTime(бцел dwRegister, ref ФВРЕМЯ pfiletime);
  цел GetTimeOfLastChange(IMoniker pmkObjectName, out ФВРЕМЯ pfiletime);
  цел EnumRunning(out IEnumMoniker ppenumMoniker);
}
///////////////////////////////////
interface IMultiQI : Инкогнито
 {
  mixin(ууид("00000020-0000-0000-c000-000000000046"));

  цел QueryMultipleInterfaces(бцел cMQIs, МУЛЬТИ_ОИ* pMQIs);
}
/////////////////////////////////////
interface IEnumUnknown : Инкогнито {
  mixin(ууид("00000100-0000-0000-c000-000000000046"));

  цел Next(бцел celt, Инкогнито* rgelt, out бцел pceltFetched);
  цел Skip(бцел celt);
  цел Reset();
  цел Clone(out IEnumUnknown ppenum);
}
////////////////////////////////////
interface IEnumString : Инкогнито {
  mixin(ууид("00000101-0000-0000-c000-000000000046"));

  цел Next(бцел celt, шим** rgelt, бцел* pceltFetched);
  цел Skip(бцел celt);
  цел Reset();
  цел Clone(out IEnumString ppenum);
}
/////////////////////////////////////
interface IEnumMoniker : Инкогнито {
  mixin(ууид("00000102-0000-0000-c000-000000000046"));

  цел Next(бцел celt, IMoniker* rgelt, out бцел pceltFetched);
  цел Skip(бцел celt);
  цел Reset();
  цел Clone(out IEnumMoniker ppenum);
}
//////////////////////////////////
interface IEnumFORMATETC : Инкогнито {
  mixin(ууид("00000103-0000-0000-c000-000000000046"));

  цел Next(бцел celt, ФОРМАТИТД* rgelt, ref бцел pceltFetched);
  цел Skip(бцел celt);
  цел Reset();
  цел Clone(out IEnumFORMATETC ppenum);
}
///////////////////////////////
interface IEnumOLEVERB : Инкогнито {
  mixin(ууид("00000104-0000-0000-c000-000000000046"));

  цел Next(бцел celt, ОЛЕВЕРБ* rgelt, out бцел pceltFetched);
  цел Skip(бцел celt);
  цел Reset();
  цел Clone(out IEnumOLEVERB ppenum);
}
////////////////////////////
interface IEnumSTATDATA : Инкогнито {
  mixin(ууид("00000105-0000-0000-c000-000000000046"));

  цел Next(бцел celt, СТАТДАННЫЕ* rgelt, out бцел pceltFetched);
  цел Skip(бцел celt);
  цел Reset();
  цел Clone(out IEnumSTATDATA ppenum);
}

interface IPersist : Инкогнито {
  mixin(ууид("0000010c-0000-0000-c000-000000000046"));

  цел GetClassID(out ГУИД pClassID);
}

//////////////////////////////
interface IPersistStream : IPersist {
  mixin(ууид("00000109-0000-0000-c000-000000000046"));

  цел IsDirty();
  цел Load(ИПоток pStm);
  цел Save(ИПоток pStm, цел fClearDirty);
  цел GetSizeMax(out бдол pразмер);
}

interface IPersistStreamInit : IPersist {
  mixin(ууид("7FD52380-4E07-101B-AE2D-08002B2EC713"));

  цел IsDirty();
  цел Load(ИПоток pStm);
  цел Save(ИПоток pStm, цел fClearDirty);
  цел GetSizeMax(out бдол pразмер);
  цел InitNew();
}

////////////////////////////////
interface IDataObject : Инкогнито {
  mixin(ууид("0000010e-0000-0000-c000-000000000046"));

  цел GetData(ref ФОРМАТИТД pformatetcIn, out НОСИТЕЛЬПАМ pmedium);
  цел GetDataHere(ref ФОРМАТИТД pformatetc, ref НОСИТЕЛЬПАМ pmedium);
  цел QueryGetData(ref ФОРМАТИТД pformatetc);
  цел GetCanonicalFormatEtc(ref ФОРМАТИТД pformatetcIn, out ФОРМАТИТД pformatetcOut);
  цел SetData(ref ФОРМАТИТД pformatetc, ref НОСИТЕЛЬПАМ pmedium, цел fRelease);
  цел EnumFormatEtc(бцел dwDirection, out IEnumFORMATETC ppenumFormatEtc);
  цел DAdvise(ref ФОРМАТИТД pformatetc, бцел advf, IAdviseSink pAdvSink, out бцел pdwConnection);
  цел DUnadvise(бцел dwConnection);
  цел EnumDAdvise(out IEnumSTATDATA ppenumAdvise);
}
////////////////////////////
interface IAdviseSink : Инкогнито {
  mixin(ууид("0000010f-0000-0000-c000-000000000046"));

  цел OnDataChange(ref ФОРМАТИТД pFormatetc, ref НОСИТЕЛЬПАМ pStgmed);
  цел OnViewChange(бцел dwAspect, цел lindex);
  цел OnRename(IMoniker pmk);
  цел OnSave();
  цел OnClose();
}
////////////////////////////
interface IDropSource : Инкогнито {
  mixin(ууид("00000121-0000-0000-c000-000000000046"));

  цел QueryContinueDrag(цел fEscapePressed, бцел grfKeyState);
  цел GiveFeedback(бцел dwEffect);
}
//////////////////////////
interface IDropTarget : Инкогнито {
  mixin(ууид("00000122-0000-0000-c000-000000000046"));

  цел DragEnter(IDataObject pDataObj, бцел grfKeyState, ТОЧКА тчк, ref бцел pdwEffect);
  цел DragOver(бцел grfKeyState, ТОЧКА тчк, ref бцел pdwEffect);
  цел DragLeave();
  цел Drop(IDataObject pDataObj, бцел grfKeyState, ТОЧКА тчк, ref бцел pdwEffect);
}
/////////////////////////////
interface ITypeLib : Инкогнито {
  mixin(ууид("00020402-0000-0000-c000-000000000046"));

  бцел GetTypeInfoCount();
  цел GetTypeInfo(бцел индекс, out ИИнфОТипе ppTInfo);
  цел GetTypeInfoType(бцел индекс, out ПВидТипа pTKind);
  цел GetTypeInfoOfGuid(ref ГУИД гуид, out ИИнфОТипе ppTInfo);
  цел GetLibAttr(out АТРТБИБ* ppTLibAttr);
  цел GetTypeComp(out ITypeComp ppTComp);
  цел GetDocumentation(цел индекс, шим** pBstrName, шим** pBstrDocString, бцел* pBstrHelpContext, шим** pBstrHelpFile);
  цел IsName(шим* szNameBuf, бцел lHashVal, out бул pfName);
  цел FindName(шим* szNameBuf, бцел lHashVal, ИИнфОТипе* ppTInfo, цел* rgMemId, ref бкрат pcFound);
  цел ReleaseTLibAttr(АТРТБИБ* pTLibAttr);
}
///////////////////////////
interface ITypeComp : Инкогнито {
  mixin(ууид("00020403-0000-0000-c000-000000000046"));

  цел Bind(шим* szName, бцел lHashVal, бкрат wFlags, out ИИнфОТипе ppTInfo, out ПВидДескр pПВидДеск, out УКПРИВЯЗ pBindPtr);
  цел BindType(шим* szName, бцел lHashVal, out ИИнфОТипе ppTInfo, out ITypeComp ppTComp);
}

interface IEnumVARIANT : Инкогнито {
  mixin(ууид("00020404-0000-0000-c000-000000000046"));

  цел Next(бцел celt, ВАРИАНТ* rgelt, out бцел pceltFetched);
  цел Skip(бцел celt);
  цел Reset();
  цел Clone(out IEnumVARIANT ppenum);
}
////////////////////////
interface ICreateTypeInfo : Инкогнито {
  mixin(ууид("00020405-0000-0000-c000-000000000046"));

  цел SetGuid(ref ГУИД гуид);
  цел SetTypeFlag(бцел uTypeFlag);
  цел SetDocString(шим* szStrDoc);
  цел SetHelpContext(бцел КонтекстСправки);
  цел SetVersion(бкрат wMajorVerNum, бкрат wMinorVerNum);
  цел AddRefTypeInfo(ИИнфОТипе pTInfo, ref бцел phRefType);
  цел AddFuncDesc(бцел индекс, ФУНКЦДЕСКР* pFuncDesc);
  цел AddImplType(бцел индекс, бцел hRefType);
  цел SetTypeImplFlags(бцел индекс, цел implTypeFlag);
  цел SetAlignment(бкрат cbAlignment);
  цел SetSchema(шим* pStrSchema);
  цел AddVarDesc(бцел индекс, ПЕРЕМДЕСКР* pVarDesc);
  цел SetFuncAndParamNames(бцел индекс, шим** rgszNames, бцел cNames);
  цел SetVarName(бцел индекс, шим* szName);
  цел SetTypeDescAlias(ТИПДЕСКР* pTDescAlias);
  цел DefineFuncAsDllEntry(бцел индекс, шим* szDllName, шим* szProcName);
  цел SetFuncDocString(бцел индекс, шим* szDocString);
  цел SetVarDocString(бцел индекс, шим* szDocString);
  цел SetFuncHelpContext(бцел индекс, бцел КонтекстСправки);
  цел SetVarHelpContext(бцел индекс, бцел КонтекстСправки);
  цел SetMops(бцел индекс, шим* bstrMops);
  цел SetTypeIdldesc(ИДЛДЕСКР* pIdlDesc);
  цел LayOut();
}
///////////////////////////
interface ICreateTypeLib : Инкогнито {
  mixin(ууид("00020406-0000-0000-c000-000000000046"));

  цел CreateTypeInfo(шим* szName, ПВидТипа tkind, out ICreateTypeInfo ppCTInfo);
  цел SetName(шим* szName);
  цел SetVersion(бкрат wMajorVerNum, бкрат wMinorVerNum);
  цел SetGuid(ref ГУИД гуид);
  цел SetDocString(шим* szDoc);
  цел SetHelpFileName(шим* szHelpFileName);
  цел SetHelpContext(бцел КонтекстСправки);
  цел SetLcid(бцел лкид);
  цел SetLibFlags(бцел uLibFlags);
  цел SaveAllChanges();
}
/////////////////////////////
interface ICreateTypeInfo2 : ICreateTypeInfo {
  mixin(ууид("0002040e-0000-0000-c000-000000000046"));

  цел DeleteFuncDesc(бцел индекс);
  цел DeleteFuncDescByMemId(цел memid, ПВидВызова invKind);
  цел DeleteVarDesc(бцел индекс);
  цел DeleteVarDescByMemId(цел memid);
  цел DeleteImplType(бцел индекс);
  цел SetCustData(ref ГУИД гуид, ref ВАРИАНТ pVarVal);
  цел SetFuncCustData(бцел индекс, ref ГУИД гуид, ref ВАРИАНТ pVarVal);
  цел SetParamCustData(бцел indexFunc, бцел indexParam, ref ГУИД гуид, ref ВАРИАНТ pVarVal);
  цел SetVarCustData(бцел индекс, ref ГУИД гуид, ref ВАРИАНТ pVarVal);
  цел SetImplTypeCustData(бцел индекс, ref ГУИД гуид, ref ВАРИАНТ pVarVal);
  цел SetHelpStringContext(бцел dwHelpStringContext);
  цел SetFuncHelpStringContext(бцел индекс, бцел dwHelpStringContext);
  цел SetVarHelpStringContext(бцел индекс, бцел dwHelpStringContext);
  цел Invalidate();
}

interface ICreateTypeLib2 : ICreateTypeLib {
  mixin(ууид("0002040f-0000-0000-c000-000000000046"));

  цел DeleteTypeInfo(шим* szName);
  цел SetCustData(ref ГУИД гуид, ref ВАРИАНТ pVarVal);
  цел SetHelpStringContext(бцел dwHelpStringContext);
  цел SetHelpStringDll(шим* szFileName);
}
///////////////////////
interface ITypeChangeEvents : Инкогнито {
  mixin(ууид("00020410-0000-0000-c000-000000000046"));

  цел RequestTypeChange(ПВидИзм changeKind, ИИнфОТипе pTInfoBefore, шим* pStrName, out цел pfCancel);
  цел AfterTypeChange(ПВидИзм changeKind, ИИнфОТипе pTInfoAfter, шим* pStrName);
}
///////////////////
interface ITypeLib2 : ITypeLib {
  mixin(ууид("00020411-0000-0000-c000-000000000046"));

  цел GetCustData(ref ГУИД гуид, out ВАРИАНТ pVarVal);
  цел GetLibStatistics(out бцел pcUniqueNames, out бцел pcchUniqueNames);
  цел GetDocumentation2(цел индекс, бцел лкид, шим** pBstrHelpString, бцел* pКонтекстСправки, шим** pBstrHelpStringDll);
  цел GetAllCustData(out ОСОБДАН pCustData);
}

interface ITypeInfo2 : ИИнфОТипе {
  mixin(ууид("00020412-0000-0000-c000-000000000046"));

  цел GetПВидТипа(out ПВидТипа pПВидТипа);
  цел GetTypeFlag(out бцел pTypeFlag);
  цел GetFuncИндекс_уMemId(цел memid, ПВидВызова invKind, out бцел pFuncIndex);
  цел GetVarИндекс_уMemId(цел memid, out бцел pVarIndex);
  цел GetCustData(ref ГУИД гуид, out ВАРИАНТ pVarVal);
  цел GetFuncCustData(бцел индекс, ref ГУИД гуид, out ВАРИАНТ pVarVal);
  цел GetParamCustData(бцел indexFunc, бцел indexParam, ref ГУИД гуид, out ВАРИАНТ pVarVal);
  цел GetVarCustData(бцел индекс, ref ГУИД гуид, out ВАРИАНТ pVarVal);
  цел GetImplTypeCustData(бцел индекс, ref ГУИД гуид, out ВАРИАНТ pVarVal);
  цел GetDocumentation2(цел memid, бцел лкид, шим** pBstrHelpString, бцел* pКонтекстСправки, шим** pBstrHelpStringDll);
  цел GetAllCustData(out ОСОБДАН pCustData);
  цел GetAllFuncCustData(бцел индекс, out ОСОБДАН pCustData);
  цел GetAllParamCustData(бцел indexFunc, бцел indexParam, out ОСОБДАН pCustData);
  цел GetAllVarCustData(бцел индекс, out ОСОБДАН pCustData);
  цел GetAllTypeImplCustData(бцел индекс, out ОСОБДАН pCustData);
}

interface IEnumGUID : Инкогнито {
  mixin(ууид("0002E000-0000-0000-c000-000000000046"));

  цел Next(бцел celt, ГУИД* rgelt, out бцел pceltFetched);
  цел Skip(бцел celt);
  цел Reset();
  цел Clone(out IEnumGUID ppenum);
}

////////////////////////////
interface IEnumCATEGORYINFO : Инкогнито {
  mixin(ууид("0002E011-0000-0000-c000-000000000046"));

  цел Next(бцел celt, ИНФ_О_КАТЕГОРИИ* rgelt, out бцел pceltFetched);
  цел Skip(бцел celt);
  цел Reset();
  цел Clone(out IEnumGUID ppenum);
}

interface ICatInformation : Инкогнито {
  mixin(ууид("0002E013-0000-0000-c000-000000000046"));

  цел EnumCategories(бцел лкид, out IEnumCATEGORYINFO ppenumCategoryInfo);
  цел GetCategoryDesc(inout ГУИД rcatid, бцел лкид, out шим* pszDesc);
  цел EnumClassesOfCategories(бцел cImplemented, ГУИД* rgcatidImpl, бцел cRequired, ГУИД* rgcatidReq, out IEnumGUID ppenumClsid);
  цел IsClassOfCategories(inout ГУИД rclsid, бцел cImplemented, ГУИД* rgcatidImpl, бцел cRequired, ГУИД* rgcatidReq);
  цел EnumImplCategoriesOfClass(inout ГУИД rclsid, out IEnumGUID ppenumCatid);
  цел EnumReqCategoriesOfClass(inout ГУИД rclsid, out IEnumGUID ppenumCatid);
}
///////////////////////////
interface IConnectionPointContainer : Инкогнито {
  mixin(ууид("b196b284-bab4-101a-b69c-00aa00341d07"));

  цел EnumConnectionPoints(out IEnumConnectionPoints ppEnum);
  цел FindConnectionPoint(ref ГУИД riid, out IConnectionPoint ppCP);
}
////////////////////////

interface IEnumConnectionPoints : Инкогнито {
  mixin(ууид("b196b285-bab4-101a-b69c-00aa00341d07"));

  цел Next(бцел cConnections, IConnectionPoint* ppCP, out бцел pcFetched);
  цел Skip(бцел cConnections);
  цел Reset();
  цел Clone(out IEnumConnectionPoints ppEnum);
}
////////////////////////////
interface IConnectionPoint : Инкогнито {
  mixin(ууид("b196b286-bab4-101a-b69c-00aa00341d07"));

  цел GetConnectionInterface(out ГУИД укНаИИд);
  цел GetConnectionPointContainer(out IConnectionPointContainer ppCPC);
  цел Advise(Инкогнито pUnkSink, out бцел pdwCookie);
  цел Unadvise(бцел dwCookie);
  цел EnumConnections(out IEnumConnections ppEnum);
}
///////////////////
interface IEnumConnections : Инкогнито {
  mixin(ууид("b196b287-bab4-101a-b69c-00aa00341d07"));

  цел Next(бцел cConnections, СОЕДДАН* rgcd, out бцел pcFetched);
  цел Skip(бцел cConnections);
  цел Reset();
  цел Clone(out IEnumConnections ppEnum);
}

interface IErrorInfo : Инкогнито {
  mixin(ууид("1cf2b120-547d-101b-8e65-08002b2bd119"));

  цел GetGUID(out ГУИД гуид);
  цел GetSource(out шим* pBstrSource);
  цел GetDescription(out шим* pBstrDescription);
  цел GetHelpFile(out шим* pBstrHelpFile);
  цел GetHelpContext(out бцел pКонтекстСправки);
}
alias IErrorInfo ИИнфОбОш;
////////////////////////////
interface ISupportErrorInfo : Инкогнито {
  mixin(ууид("df0b3d60-548f-101b-8e65-08002b2bd119"));

  цел InterfaceSupportsErrorInfo(ref ГУИД riid);
}
//////////////////////////
interface IClassFactory2 : IClassFactory {
  mixin(ууид("b196b28f-bab4-101a-b69c-00aa00341d07"));

  цел GetLicInfo(out ИНФОЛИЦ pLicInfo);
  цел RequestLicKey(бцел резерв, out шим* pBstrKey);
  цел CreateInstanceLic(Инкогнито pUnkOuter, Инкогнито pUnkReserved, ref ГУИД riid, шим* bstrKey, ук* ppvObj);
}
/////////////////////
interface IFont : Инкогнито {
  mixin(ууид("BEF6E002-A874-101A-8BBA-00AA00300CAB"));

  цел get_Name(out шим* pName);
  цел set_Name(шим* имя);
  цел get_Size(out дол pSize);
  цел set_Size(дол размер);
  цел get_Bold(out цел pBold);
  цел set_Bold(цел bold);
  цел get_Italic(out цел pItalic);
  цел set_Italic(цел italic);
  цел get_Underline(out цел pUnderline);
  цел set_Underline(цел underline);
  цел get_Strikethrough(out цел pStrikethrough);
  цел set_Strikethrough(цел strikethrough);
  цел get_Weight(out крат pWeight);
  цел set_Weight(крат weight);
  цел get_Charset(out крат pCharset);
  цел set_Charset(крат charset);
  цел get_hFont(out ук phFont);
  цел Clone(out IFont ppFont);
  цел IsEqual(IFont pFontOther);
  цел SetRatio(цел cyLogical, цел cyHimetric);
  цел QueryTextMetrics(out МЕТРИКА_ОЛЕ_ТЕКСТА pTM);
  цел AddRefHfont(ук hFont);
  цел ReleaseHfont(ук hFont);
  цел SetHdc(ук hDC);
}
////////////////////////
interface IPicture : Инкогнито {
  mixin(ууид("7BF80980-BF32-101A-8BBB-00AA00300CAB"));

  цел get_Handle(out бцел pHandle);
  цел get_hPal(out бцел phPal);
  цел get_Type(out крат pType);
  цел get_Width(out цел pWidth);
  цел get_Height(out цел pHeight);
  цел Render(ук hDC, цел x, цел y, цел cx, цел cy, цел xSrc, цел ySrc, цел cxSrc, цел cySrc, ПРЯМ* pRcBounds);
  цел set_hPal(бцел hPal);
  цел get_CurDC(out ук phDC);
  цел SelectPicture(ук hDCIn, out ук phDCOut, out бцел phBmpOut);
  цел get_KeepOriginalFormat(out цел pKeep);
  цел put_KeepOriginalFormat(цел keep);
  цел PictureChanged();
  цел SaveAsFile(ИПоток pПоток, цел fSaveMemCopy, out цел pCbSize);
  цел get_Attributes(out бцел pDwAttr);
}

interface IFontEventsDisp : ИДиспетчер {
  mixin(ууид("4EF6100A-AF88-11D0-9846-00C04FC29993"));
}

interface IFontDisp : ИДиспетчер {
  mixin(ууид("BEF6E003-A874-101A-8BBA-00AA00300CAB"));
}

interface IPictureDisp : ИДиспетчер {
  mixin(ууид("7BF80981-BF32-101A-8BBB-00AA00300CAB"));
}
////////////////////////////////////////////////
abstract final class StdComponentCategoriesMgr
 {
  mixin(ууид("0002E005-0000-0000-c000-000000000046"));

  mixin Интерфейсы!(ICatInformation);
}
////////////////////////////////////////


