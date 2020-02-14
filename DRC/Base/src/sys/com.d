module sys.com;

import tpl.com, tpl.args, exception; 
import std.utf, runtime, cidrus;
import std.string: format;
alias format фм;

бул КОМАктивен;

export extern(C) бул комАктивен(){ return КОМАктивен;}

export extern (D):

 проц откройКОМ() {  КОМАктивен = УД(ИнициализуйКоДоп(null, ПИницКо.Купейно));}
 проц закройКОМ() {
  // Before we shut down COM, give classes a chance to сбрось any COM resources.
  try {   
      _см.собери();    
      }
      finally 
	{
	КОМАктивен = нет;
    ДеинициализуйКо();
	}
  }


 ткст прогИдИзКлсид(ГУИД клсид) {
  шим* str;
  ПрогИДИзКЛСИД(клсид, str);
  return toUTF8(str[0 .. wcslen(str)]);
}

ГУИД клсидИзПрогИд(ткст прогИд){
 ГУИД клсид;
  КЛСИДИзПрогИД(toUTF16z(прогИд), клсид);
  return клсид;
}


 Исключение исклКомРез(цел кодОшибки) {
  switch (кодОшибки) {
    case ПКомРез.Нереализовано:
      throw new Исключение("КОМ: Нереализованная функция");
    case ПКомРез.НеИнтерфейс:
      throw new Исключение("КОМ: Неудачное преобразование типа");
    case ПКомРез.Ук:
      throw new Исключение("КОМ: Ссылка на пустое");
    case ПКомРез.НетДоступа:
     throw new Исключение("КОМ: Недостаточно право для доступа");
    case ПКомРез.ВнеПамяти:
       throw new ВнеПамИскл();
	  case ПКомРез.НевернАрг:
      throw new Исключение("КОМ: Использован неверный параметр");
    default:
  }
  return new ИсклКОМ(кодОшибки);
}

 проц ошибкаКомРез(цел кодОшибки)
in {
  assert(НЕУД(кодОшибки));
}
body {
  if (НЕУД(кодОшибки))
    throw исклКомРез(кодОшибки);
}

ДЕСЯТОК дес(ткст т)() {return ДЕСЯТОК.разбор(т);}



/////////////////////////////////////////

// Deprecate? You should really use the scope(exit) образец.
/**
 */
  проц высвободиПосле(Инкогнито объ, проц delegate() блокируй) {
  try {
    блокируй();
  }
  finally {
    if (объ)
      объ.Release();
  }
}

// Deprecate? You should really use the scope(exit) образец.
/**
 */
 проц сотриПосле(ВАРИАНТ var, проц delegate() блокируй) {
  try {
    блокируй();
  }
  finally {
    var.сотри();
  }
}

/**
 * Уменьшает счёт ссылок для объекта.
 */
  проц пробуйСброс(Инкогнито объ) {
  if (объ) {
    try {
      объ.Release();
    }
    catch {
    }
  }
}

/**
 * Уменьшает счёт ссылок для объекта, пока он не сравняется с 0.
 */
 проц финальныйСброс(Инкогнито объ) {
  if (объ) {
    while (объ.Release() > 0) {
    }
  }
}

/**
 * Размещает эквивалент BSTR в s.
 * Параметры: s = Текст, инициализирующий BSTR.
 * Возвращает: BSTR, эквивалентный s.
 */
 шим* вБткст(ткст s) {
  if (s == null)
    return null;

  return СисРазместиТкст(toUTF16z(s));
}

/**
 * Преобразует BSTR в ткст, дополнительно высвобождая исходный BSTR.
 * Параметры: бткст = преобразуемый BSTR.
 * Возвращает: ткст, эквивалентный бткст.
 */
 ткст бткстВТкст(шим* s, бул высвободить = true)
 {
  if (s == null)
    return null;

  бцел длин = СисТкстДлин(s);
  if (длин == 0)
    return null;

  ткст ret = toUTF8(s[0 .. длин]);
  /*цел кб = WideCharToMultiByte(CP_UTF8, 0, s, длин, null, 0, null, null);
  сим[] ret = new сим[кб];
  WideCharToMultiByte(CP_UTF8, 0, s, длин, ret.ptr, кб, null, null);*/

  if (высвободить)
    СисОсвободиТкст(s);
  return cast(ткст)ret;
}


/**
 * Освобождает память, занятую под указанный BSTR.
 * Параметры: бткст = Высвобождаемый BSTR.
 */
 проц высвободиБткст(шим* s)
 {
  if (s != null)
    СисОсвободиТкст(s);
}

 бцел длинаБткст(шим* s) 
{
  if (s == null)
    return 0;
  return СисТкстДлин(s);
}


/**
 * Создаёт объект класса, связанного с указанным ГУИДом.
 * Параметры:
 *   клсид = Класс, ассоциированный с объектом.
 *   внешний = Если null, это указывает на то, что объект не созtrueётся как часть агрегата.
 *   контекст = Контекст, в котором будет выполняться управляющий объектом код.
 *   iid = Идентификатор интерфейса, который будет использован для коммуникации с объектом.
 * Возвращает: Затребованный объект.
 * See_Also: $(LINK2 http://msdn.microsoft.com/en-us/library/ms686615.aspx, СоздайЭкземплярКо).
 */
Инкогнито создайЭкземплярКо(ГУИД клсид, Инкогнито внешний, ПКонтекстВып контекст,ГУИД iid) {
 Инкогнито ret;
  if (УД(СоздайЭкземплярКо(клсид, внешний, cast(бцел)контекст, iid, tpl.com.возврзнач(ret))))
    return ret;
  return null;
}

/**
 * Возвращает ссылку на выполняемый объект, зарегестрированный в OLE.
 * See_Also: $(LINK2 http://msdn2.microsoft.com/en-us/library/ms221467.aspx, ДайАктивныйОбъект).
 */
Инкогнито дайАктивныйОбъект(ткст прогИд) {
 ГУИД клсид = клсидИзПрогИд(прогИд);
 Инкогнито объ = null;
  if (УД(ДайАктивныйОбъект(клсид, null, объ)))
    return объ;

  return null;
}


/**
 * Показывает, представляет ли собой заtrueнный объект COM-объект.
 * Параметры: объ = Проверяемый объект.
 * Возвращает: true, если объект COM типа; в противном случае - false.
 */
 бул объектКОМ_ли(Объект объ)
 {
  ИнфОКлассе** ci = cast(ИнфОКлассе**)cast(ук)объ;
  if (*ci !is null) 
  {
    ИнфОКлассе c = **ci;
    if (c !is null)
      return ((c.флаги & 1) != 0);
  }
  return false;
}


/**
 * Оборачивает "вручную" рассчитывающий ссылки объект, производный от Инкогнито, 
 * при этом его памятью можно управлять автоматически рантаймным СМ Ди.
 */
final class КомОбъект
 {
  protected Инкогнито obj_;
  
export:
  /**
   * Инициализует новый экземпляр указанным призводным отИнкогнито объектом.
   * Параметры: объ = Оборачиваемый объект.
   */
  this(Инкогнито объ) {    obj_ = объ;  }

  ~this() 
   {
      if (obj_ !is null) 
		{
		  финальныйСброс(obj_);
		  obj_ = null;
		}
   }

  /**
   * Выводит исходный производный от Инкогнито объект.
   * Возвращает: Обернутый объект.
   */
 Инкогнито opCast() {
    return obj_;
  }

}


/**
 * Вызывает указанный член указанного объекта.
 * Параметры:
 *   dispId = Идентификатор вызываемого члена-метоtrue или - объекта.
 *   флаги = Тип вызываемого члена.
 *   цель = Объект, у которого trueнный член будет вызываться.
 *   арги = Список с аргументами, переtrueваемыми вызываемому члену.
 * Возвращает: Возвратное значение от вызываемого члена.
 * Выводит исключение: ИсклКОМ, если вызов не удался.
 */
ВАРИАНТ вызовиЧленПоИду(цел dispId, ПДиспачФлаг флаги, ИДиспетчер цель,ВАРИАНТ[] арги...) {
  арги.reverse;

  ДИСППАРАМЫ парамы;
  if (арги.length > 0) {
    парамы.ргварг = арги.ptr;
    парамы.арги = арги.length;

    if (флаги & ПДиспачФлаг.УстановитьСвойство) {
      цел dispIdNamed = ПИдДисп.ПоместиСвойство;
      парамы.ргдиспидИменованыеАрги = &dispIdNamed;
      парамы.именованыеАрги = 1;
    }
  }

 ВАРИАНТ результат;
  ИСКЛИНФО искл;
  цел хрез = цель.Invoke(dispId,ГУИД.пустой,  ДайЛокальНити(), cast(бкрат)флаги, &парамы, &результат, &искл, null);

  for (auto i = 0; i < парамы.арги; i++) {
    парамы.ргварг[i].сотри();
  }

  ткст ошСооб;
  if (хрез == ПОшДисп.Исключение && искл.скод != 0) {
    ошСооб = бткстВТкст(искл.описание);
    хрез = искл.скод;
  }

  switch (хрез) {
    case ПКомРез.Да, ПКомРез.Нет, ПКомРез.Аборт:
      return результат;
    default:
      if (auto supportErrorInfo = com_cast!(ISupportErrorInfo)(цель)) {
        scope(exit) supportErrorInfo.Release();

        if (УД(supportErrorInfo.InterfaceSupportsErrorInfo(ууид_у!(ИДиспетчер)))) {
          sys.WinIfaces.ИИнфОбОш errorInfo;
          ДайИнфОбОш(0, errorInfo);
          if (errorInfo !is null) {
            scope(exit) errorInfo.Release();

            шим* bstrDesc;
            if (УД(errorInfo.GetDescription(bstrDesc)))
              ошСооб = бткстВТкст(bstrDesc);
          }
        }
      }
      else if (ошСооб == null) {
        шим[256] буфер;
        бцел r = ФорматируйСооб(cast(ПФорматСооб)(0x00001000 | 0x00000200), null, хрез, 0, буфер, буфер.length + 1, null);
        if (r != 0)
          ошСооб = toUTF8(буфер[0 .. r]);
        else
          ошСооб = фм("Операция 0x%08X не удалась (0x%08X)", dispId, хрез);
      }

      throw new ИсклКОМ(ошСооб, хрез);
  }

  /*if (НЕУД(хрез)) {
    throw new ИсклКОМ(бткстВТкст(искл.бткстОписание), хрез);
  }*/

  //return результат;
}

/**
 * Invokes the specified member on the specified object.
 * Параметры:
 *   имя = The _name of the method or property member to invoke.
 *   флаги = The тип of member to invoke.
 *   цель = The object on which to invoke the specified member.
 *   арги = A список containing the arguments to pass to the member to invoke.
 * Возвращает: The return value of the invoked member.
 * Выводит исключение: ИсклНедостающЧлена if the member is not found.
 */
ВАРИАНТ вызовиЧлен(ткст имя, ПДиспачФлаг флаги, ИДиспетчер цель,ВАРИАНТ[] арги...) {
  цел dispId = ПИдДисп.Неизвестно;
  шим* bstrName = имя.вБткст();
  scope(exit) высвободиБткст(bstrName);

  if (УД(цель.GetIDsOfNames(ГУИД.пустой, &bstrName, 1,  ДайЛокальНити(), &dispId)) && dispId != ПИдДисп.Неизвестно) {
    return вызовиЧленПоИду(dispId, флаги, цель, арги);
  }

  ткст имяТипа;
  ИИнфОТипе инфОТипе;
  if (УД(цель.GetTypeInfo(0, 0, инфОТипе))) {
    scope(exit) пробуйСброс(инфОТипе);

    шим* bstrTypeName;
    инфОТипе.GetDocumentation(-1, &bstrTypeName, null, null, null);
    имяТипа = бткстВТкст(bstrTypeName);
  }

  throw new ИсклНедостающЧлена(имяТипа, имя);
}

ВАРИАНТ[] аргиВВариантСписок(ИнфОТипе[] типы, спис_ва аргук) {
 ВАРИАНТ[] список;

  foreach (тип; типы) {
    if (тип == typeid(бул)) список ~=ВАРИАНТ(ва_арг!(бул)(аргук));
    else if (тип == typeid(ббайт)) список ~=ВАРИАНТ(ва_арг!(ббайт)(аргук));
    else if (тип == typeid(байт)) список ~=ВАРИАНТ(ва_арг!(байт)(аргук));
    else if (тип == typeid(бкрат)) список ~=ВАРИАНТ(ва_арг!(бкрат)(аргук));
    else if (тип == typeid(крат)) список ~=ВАРИАНТ(ва_арг!(крат)(аргук));
    else if (тип == typeid(бцел)) список ~=ВАРИАНТ(ва_арг!(бцел)(аргук));
    else if (тип == typeid(цел)) список ~=ВАРИАНТ(ва_арг!(цел)(аргук));
    else if (тип == typeid(бдол)) список ~=ВАРИАНТ(ва_арг!(бдол)(аргук));
    else if (тип == typeid(дол)) список ~=ВАРИАНТ(ва_арг!(дол)(аргук));
    else if (тип == typeid(плав)) список ~=ВАРИАНТ(ва_арг!(плав)(аргук));
    else if (тип == typeid(дво)) список ~=ВАРИАНТ(ва_арг!(дво)(аргук));
    else if (тип == typeid(ткст)) список ~=ВАРИАНТ(ва_арг!(ткст)(аргук));
    else if (тип == typeid(ИДиспетчер)) список ~=ВАРИАНТ(ва_арг!(ИДиспетчер)(аргук));
    else if (тип == typeid(Инкогнито)) список ~=ВАРИАНТ(ва_арг!(Инкогнито)(аргук));
    else if (тип == typeid(ВАРИАНТ)) список ~= ва_арг!(ВАРИАНТ)(аргук);
    //else if (тип == typeid(ВАРИАНТ*)) список ~=ВАРИАНТ(ва_арг!(ВАРИАНТ*)(аргук));
    else if (тип == typeid(ВАРИАНТ*)) список ~= *ва_арг!(ВАРИАНТ*)(аргук);
  }

  return список;
}

проц фиксАрги(ref ИнфОТипе[] арги, ref спис_ва аргук) {
  if (арги[0] == typeid(ИнфОТипе[]) && арги[1] == typeid(спис_ва)) {
    арги = ва_арг!(ИнфОТипе[])(аргук);
    аргук = *cast(спис_ва*)(аргук);
  }
}

/**
 * Invokes the specified method on the specified object.
 * Параметры:
 *   цель = The object on which to invoke the specified method.
 *   имя = The _name of the method to invoke.
 *   _argptr = A список containing the arguments to pass to the method to invoke.
 * Возвращает: The return value of the invoked method.
 * Выводит исключение: ИсклНедостающЧлена if the method is not found.
 * Примеры:
 * ---
 * import com.com;
 *
 * проц main() {
 *   auto ieApp = создайКо!(ИДиспетчер)("InternetExplorer.Application");
 *   вызовиМетод(ieApp, "Navigate", "http://www.amazon.co.uk");
 * }
 * ---
 */
R вызовиМетод(R = ВАРИАНТ)(ИДиспетчер цель, ткст имя, ...) {
  auto арги = _arguments;
  auto аргук = _argptr;
  if (арги.length == 2) фиксАрги(арги, аргук);

 ВАРИАНТ ret = вызовиЧлен(имя, ПДиспачФлаг.ВызватьМетод, цель, аргиВВариантСписок(арги, аргук));
  static if (is(R == ВАРИАНТ)) {
    return ret;
  }
  else {
    return com_cast!(R)(ret);
  }
}

/**
 * Gets the value of the specified property on the specified object.
 * Параметры:
 *   цель = The object on which to invoke the specified property.
 *   имя = The _name of the property to invoke.
 *   _argptr = A список containing the arguments to pass to the property.
 * Возвращает: The return value of the invoked property.
 * Выводит исключение: ИсклНедостающЧлена if the property is not found.
 * Примеры:
 * ---
 * import com.com, stdrus;
 *
 * проц main() {
 *   // Create an экземпляр of the Microsoft Word automation object.
 *   ИДиспетчер wordApp = создайКо!(ИДиспетчер)("Word.Application");
 *
 *   // Invoke the Documents property 
 *   //   wordApp.Documents
 *   ИДиспетчер documents = дайСвойство!(ИДиспетчер)(цель, "Documents");
 *
 *   // Invoke the Count property on the Documents object
 *   //   documents.Count
 *  ВАРИАНТ посчитай = дайСвойство(documents, "Count");
 *
 *   // Display the value of the Count property.
 *   writefln("There are %s documents", посчитай);
 * }
 * ---
 */
R дайСвойство(R = ВАРИАНТ)(ИДиспетчер цель, ткст имя, ...)
 {
  auto арги = _arguments;
  auto аргук = _argptr;
  if (арги.length == 2) фиксАрги(арги, аргук);

 ВАРИАНТ ret = вызовиЧлен(имя, ПДиспачФлаг.ДатьСвойство, цель, аргиВВариантСписок(арги, аргук));
  static if (is(R == ВАРИАНТ))
    return ret;
  else
    return com_cast!(R)(ret);
}

/**
 * Sets the value of a specified property on the specified object.
 * Параметры:
 *   цель = The object on which to invoke the specified property.
 *   имя = The _name of the property to invoke.
 *   _argptr = A список containing the arguments to pass to the property.
 * Выводит исключение: ИсклНедостающЧлена if the property is not found.
 * Примеры:
 * ---
 * import com.com;
 *
 * проц main() {
 *   // Create an Excel automation object.
 *   ИДиспетчер excelApp = создайКо!(ИДиспетчер)("Excel.Application");
 *
 *   // Set the Visible property to true
 *   //   excelApp.Visible = true
 *   установиСвойство(excelApp, "Visible", true);
 *
 *   // Get the Workbooks property
 *   //   workbooks = excelApp.Workbooks
 *   ИДиспетчер workbooks = дайСвойство!(ИДиспетчер)(excelApp, "Workbooks");
 *
 *   // Invoke the Add method on the Workbooks property
 *   //   newWorkbook = workbooks.Add()
 *   ИДиспетчер newWorkbook = вызовиМетод!(ИДиспетчер)(workbooks, "Add");
 *
 *   // Get the Worksheets property and the Worksheet at индекс 1
 *   //   worksheet = excelApp.Worksheets[1]
 *   ИДиспетчер worksheet = дайСвойство!(ИДиспетчер)(excelApp, "Worksheets", 1);
 *
 *   // Get the Cells property and установи the Cell object at column 5, row 3 to a ткст
 *   //   worksheet.Cells[5, 3] = "data"
 *   установиСвойство(worksheet, "Cells", 5, 3, "data");
 * }
 * ---
 */
проц установиСвойство(ИДиспетчер цель, ткст имя, ...) {
  auto арги = _arguments;
  auto аргук = _argptr;
  if (арги.length == 2) фиксАрги(арги, аргук);

  if (арги.length > 1) {
   ВАРИАНТ v = вызовиЧлен(имя, ПДиспачФлаг.ДатьСвойство, цель);
    if (auto indexer = v.депЗнач) {
      scope(exit) indexer.Release();

      v = вызовиЧленПоИду(0, ПДиспачФлаг.ДатьСвойство, indexer, аргиВВариантСписок(арги[0 .. 1], аргук));
      if (auto value = v.депЗнач) {
        scope(exit) value.Release();

        вызовиЧленПоИду(0, ПДиспачФлаг.УстановитьСвойство, value, аргиВВариантСписок(арги[1 .. $], аргук + арги[0].tsize));
        return;
      }
    }
  }
  else {
    вызовиЧлен(имя, ПДиспачФлаг.УстановитьСвойство, цель, аргиВВариантСписок(арги, аргук));
  }
}

проц установиССылСвойство(ИДиспетчер цель, ткст имя, ...) 
{
  auto арги = _arguments;
  auto аргук = _argptr;
  if (арги.length == 2) фиксАрги(арги, аргук);

  вызовиЧлен(имя, ПДиспачФлаг.УстановитьСсылСвойство, цель, аргиВВариантСписок(арги, аргук));
}
//////////////////////////////////////////////////////////


/+
/**
 */
class EventCookie(T) {

  private IConnectionPoint cp_;
  private uint cookie_;

  /**
   */
  this(IUnknown source) {
    auto cpc = com_cast!(IConnectionPointContainer)(source);
    if (cpc !is null) {
      scope(exit) пробуйСброс(cpc);

      if (cpc.FindConnectionPoint(uuidof!(T), cp_) != S_OK)
        throw new АргИскл("Source object does not expose '" ~ T.stringof ~ "' event interface.");
    }
  }

  ~this() {
    disconnect();
  }

  /**
   */
  проц connect(IUnknown sink) {
    if (cp_.Advise(sink, cookie_) != S_OK) {
      cookie_ = 0;
      пробуйСброс(cp_);
      throw new ОпИскл("Could not Advise() the event interface '" ~ T.stringof ~ "'.");
    }

    if (cp_ is null || cookie_ == 0) {
      if (cp_ !is null)
        пробуйСброс(cp_);
      throw new АргИскл("Connection point for event interface '" ~ T.stringof ~ "' cannot be created.");
    }
  }

  /**
   */
  проц disconnect() {
    if (cp_ !is null && cookie_ != 0) {
      try {
        cp_.Unadvise(cookie_);
      }
      finally {
        пробуйСброс(cp_);
        cp_ = null;
        cookie_ = 0;
      }
    }
  }

}

private struct MethodProxy {

  int delegate() method;
  VARTYPE returnType;
  VARTYPE[] paramTypes;

  static MethodProxy opCall(R, T...)(R delegate(T) method) {
    MethodProxy self;
    self = method;
    return self;
  }

  проц opAssign(R, T...)(R delegate(T) dg) {
    alias КортежТипаПараметров!(dg) params;

    method = cast(int delegate())dg;
    returnType = VariantType!(R);
    paramTypes.length = params.length;
    foreach (i, paramType; params) {
      paramTypes[i] = VariantType!(paramType);
    }
  }

  int invoke(ВАРИАНТ*[] args, ВАРИАНТ* результат) {

    size_t variantSize(VARTYPE vt) {
      switch (vt) {
        case VT_UI8, VT_I8, VT_CY:
          return long.sizeof / int.sizeof;
        case VT_R8, VT_DATE:
          return double.sizeof / int.sizeof;
        case VT_ВАРИАНТ:
          return (ВАРИАНТ.sizeof + 3) / int.sizeof;
        default:
      }

      return 1;
    }

    // Like DispCallFunc, but using delegates

    size_t paramCount;
    for (int i = 0; i < paramTypes.length; i++) {
      paramCount += variantSize(paramTypes[i]);
    }

    auto argptr = cast(int*)HeapAlloc(GetProcessHeap(), 0, paramCount * int.sizeof);

    uint pos;
    for (int i = 0; i < paramTypes.length; i++) {
      ВАРИАНТ* p = args[i];
      if (paramTypes[i] == VT_ВАРИАНТ)
        memcpy(&argptr[pos], p, variantSize(paramTypes[i]) * int.sizeof);
      else
        memcpy(&argptr[pos], &p.lVal, variantSize(paramTypes[i]) * int.sizeof);
      pos += variantSize(paramTypes[i]);
    }

    int ret = 0;

    switch (paramCount) {
      case 0: ret = method(); break;
      case 1: ret = (cast(int delegate(int))method)(argptr[0]); break;
      case 2: ret = (cast(int delegate(int, int))method)(argptr[0], argptr[1]); break;
      case 3: ret = (cast(int delegate(int, int, int))method)(argptr[0], argptr[1], argptr[2]); break;
      case 4: ret = (cast(int delegate(int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3]); break;
      case 5: ret = (cast(int delegate(int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4]); break;
      case 6: ret = (cast(int delegate(int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5]); break;
      case 7: ret = (cast(int delegate(int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6]); break;
      case 8: ret = (cast(int delegate(int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7]); break;
      case 9: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8]); break;
      case 10: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9]); break;
      case 11: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10]); break;
      case 12: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11]); break;
      case 13: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12]); break;
      case 14: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13]); break;
      case 15: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13], argptr[14]); break;
      case 16: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13], argptr[14], argptr[15]); break;
      case 17: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13], argptr[14], argptr[15], argptr[16]); break;
      case 18: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13], argptr[14], argptr[15], argptr[16], argptr[17]); break;
      case 19: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13], argptr[14], argptr[15], argptr[16], argptr[17], argptr[18]); break;
      case 20: ret = (cast(int delegate(int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int, int))method)(argptr[0], argptr[1], argptr[2], argptr[3], argptr[4], argptr[5], argptr[6], argptr[7], argptr[8], argptr[9], argptr[10], argptr[11], argptr[12], argptr[13], argptr[14], argptr[15], argptr[16], argptr[17], argptr[18], argptr[19]); break;
      default:
        return DISP_E_BADPARAMCOUNT;
    }

    if (результат !is null && returnType != VT_VOID) {
      результат.vt = returnType;
      результат.lVal = ret;
    }

    HeapFree(GetProcessHeap(), 0, argptr);
    return S_OK;
  }

}

/**
 */
class EventProvider(T) : Implements!(T) {

  extern(D):

  private MethodProxy[int] methodTable_;
  private int[ткст] nameTable_;

  private IConnectionPoint connectionPoint_;
  private uint cookie_;

  /**
   */
  this(IUnknown source) {
    auto cpc = com_cast!(IConnectionPointContainer)(source);
    if (cpc !is null) {
      scope(exit) пробуйСброс(cpc);

      if (cpc.FindConnectionPoint(uuidof!(T), connectionPoint_) != S_OK)
        throw new АргИскл("Source object does not expose '" ~ T.stringof ~ "' event interface.");

      if (connectionPoint_.Advise(this, cookie_) != S_OK) {
        cookie_ = 0;
        пробуйСброс(connectionPoint_);
        throw new ОпИскл("Could not Advise() the event interface '" ~ T.stringof ~ "'.");
      }
    }

    if (connectionPoint_ is null || cookie_ == 0) {
      if (connectionPoint_ !is null)
        пробуйСброс(connectionPoint_);
      throw new АргИскл("Connection point for event interface '" ~ T.stringof ~ "' cannot be created.");
    }
  }

  ~this() {
    if (connectionPoint_ !is null && cookie_ != 0) {
      try {
        connectionPoint_.Unadvise(cookie_);
      }
      finally {
        пробуйСброс(connectionPoint_);
        connectionPoint_ = null;
        cookie_ = 0;
      }
    }
  }

  /**
   */
  проц bind(ID, R, P...)(ID member, R delegate(P) handler) {
    static if (is(ID : ткст)) {
      bool found;
      int dispId = DISPID_UNKNOWN;
      if (tryFindDispId(member, dispId))
        bind(dispId, handler);
      else
        throw new АргИскл("Member '" ~ member ~ "' not found in type '" ~ T.stringof ~ "'.");
    }
    else static if (is(ID : int)) {
      MethodProxy m = handler;
      methodTable_[member] = m;
    }
  }

  private bool tryFindDispId(ткст имя, out int dispId) {

    проц ensureNameTable() {
      if (nameTable_ == null) {
        scope клсидKey = RegistryKey.classesRoot.openSubKey("Interface\\" ~ uuidof!(T).toString("P"));
        if (клсидKey !is null) {
          scope typeLibRefKey = клсидKey.openSubKey("TypeLib");
          if (typeLibRefKey !is null) {
            ткст typeLibVersion = typeLibRefKey.getValue!(ткст)("Version");
            if (typeLibVersion == null) {
              scope versionKey = клсидKey.openSubKey("Version");
              if (versionKey !is null)
                typeLibVersion = versionKey.getValue!(ткст)(null);
            }

            scope typeLibKey = RegistryKey.classesRoot.openSubKey("TypeLib\\" ~ typeLibRefKey.getValue!(ткст)(null));
            if (typeLibKey !is null) {
              scope pathKey = typeLibKey.openSubKey(typeLibVersion ~ "\\0\\Win32");
              if (pathKey !is null) {
                ITypeLib typeLib;
                if (LoadTypeLib(pathKey.getValue!(ткст)(null).toUtf16z(), typeLib) == S_OK) {
                  scope(exit) пробуйСброс(typeLib);

                  ITypeInfo typeInfo;
                  if (typeLib.GetTypeInfoOfГУИД(uuidof!(T), typeInfo) == S_OK) {
                    scope(exit) пробуйСброс(typeInfo);

                    TYPEATTR* typeAttr;
                    if (typeInfo.GetTypeAttr(typeAttr) == S_OK) {
                      scope(exit) typeInfo.ReleaseTypeAttr(typeAttr);

                      for (uint i = 0; i < typeAttr.cFuncs; i++) {
                        FUNCDESC* funcDesc;
                        if (typeInfo.GetFuncDesc(i, funcDesc) == S_OK) {
                          scope(exit) typeInfo.ReleaseFuncDesc(funcDesc);

                          wchar* bstrName;
                          if (typeInfo.GetDocumentation(funcDesc.memid, &bstrName, null, null, null) == S_OK) {
                            ткст memberName = fromBstr(bstrName);
                            nameTable_[memberName.toLower()] = funcDesc.memid;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    dispId = DISPID_UNKNOWN;

    ensureNameTable();

    if (auto value = имя.toLower() in nameTable_) {
      dispId = *value;
      return true;
    }

    return false;
  }

  extern(Windows):

  override int Invoke(int dispIdMember, ref GUID riid, uint lcid, ushort wFlags, DISPPARAMS* pDispParams, ВАРИАНТ* pVarResult, EXCEPINFO* pExcepInfo, uint* puArgError) {
    if (riid != GUID.empty)
      return DISP_E_UNKNOWNINTERFACE;

    try {
      if (auto handler = dispIdMember in methodTable_) {
        ВАРИАНТ*[8] args;
        for (int i = 0; i < handler.paramTypes.length && i < 8; i++) {
          args[i] = &pDispParams.rgvarg[handler.paramTypes.length - i - 1];
        }

        ВАРИАНТ результат;
        if (pVarResult == null)
          pVarResult = &результат;

        int hr = handler.invoke(args, pVarResult);

        for (int i = 0; i < handler.paramTypes.length; i++) {
          if (args[i].vt == (VT_BYREF | VT_BOOL)) {
            // Fix bools to ВАРИАНТ_BOOL
            *args[i].pboolVal = (*args[i].pboolVal == 0) ? ВАРИАНТ_FALSE : ВАРИАНТ_TRUE;
          }
        }

        return hr;
      }
      else
        return DISP_E_MEMBERNOTFOUND;
    }
    catch {
      return E_FAIL;
    }

    return S_OK;
  }

}
+/