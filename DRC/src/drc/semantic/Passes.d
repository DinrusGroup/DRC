/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity low)
/// Описание: Этот модуль присутствует в целях тестирования
/// иного алгоритма проведения семантического анализа,
/// для сравнения с СемантическаяПроходка1 и СемантическаяПроходка2!
module drc.semantic.Passes;

import drc.ast.DefaultVisitor,
       drc.ast.Node,
       drc.ast.Declarations,
       drc.ast.Expressions,
       drc.ast.Statements,
       drc.ast.Types,
       drc.ast.Parameters;
import drc.lexer.IdTable;
import drc.parser.Parser;
import drc.semantic.Symbol,
       drc.semantic.Symbols,
       drc.semantic.Types,
       drc.semantic.Scope,
       drc.semantic.Module,
       drc.semantic.Analysis;
import drc.code.Interpreter;
import drc.Compilation;
import drc.SourceText;
import drc.Diagnostics;
import drc.Messages;
import drc.Enums;
import drc.CompilerInfo;
import common;

/// Some handy aliases.
private alias Декларация Д;
private alias Выражение В; /// определено
private alias Инструкция И; /// определено
private alias УзелТипа Т; /// определено
private alias Параметр П; /// определено
private alias Узел У; /// определено

/// Base class of all другой semantic pass classes.
abstract class СемантическаяПроходка : ДефолтныйВизитёр
{
  Масштаб масш; /// The current Масштаб.
  Модуль модуль; /// The module в be semantically checked.
  КонтекстКомпиляции контекст; /// The compilation контекст.

  /// Строит СемантическаяПроходка объект.
  /// Параметры:
  ///   модуль = the module в be processed.
  ///   контекст = the compilation контекст.
  this(Модуль модуль, КонтекстКомпиляции контекст)
  {
    this.модуль = модуль;
    this.контекст = контекст;
  }

  проц  пуск()
  {

  }

  /// Enters a new Масштаб.
  проц  войдиВМасштаб(СимволМасштаба s)
  {
    масш = масш.войдиВ(s);
  }

  /// Exits the current Масштаб.
  проц  выйдиИзМасштаба()
  {
    масш = масш.выход();
  }

  /// Возвращает да, если из_ the module Масштаб.
  бул масштабМодуля_ли()
  {
    return масш.символ.Модуль_ли();
  }

  /// Inserts a символ into the current Масштаб.
  проц  вставь(Символ символ)
  {
    вставь(символ, символ.имя);
  }

  /// Inserts a символ into the current Масштаб.
  проц  вставь(Символ символ, Идентификатор* имя)
  {
    auto symX = масш.символ.сыщи(имя);
    if (symX)
      сообщиОКонфликтеСимволов(символ, symX, имя);
    else
      масш.символ.вставь(символ, имя);
    // Set the current Масштаб символ as the родитель.
    символ.родитель = масш.символ;
  }

  /// Inserts a символ into симМасшт.
  проц  вставь(Символ символ, СимволМасштаба симМасшт)
  {
    auto symX = симМасшт.сыщи(символ.имя);
    if (symX)
      сообщиОКонфликтеСимволов(символ, symX, символ.имя);
    else
      симМасшт.вставь(символ, символ.имя);
    // Set the current Масштаб символ as the родитель.
    символ.родитель = симМасшт;
  }

  /// Inserts a символ, overloading on the имя, into the current Масштаб.
  проц  вставьПерегрузку(Символ сим)
  {
    auto имя = сим.имя;
    auto сим2 = масш.символ.сыщи(имя);
    if (сим2)
    {
      if (сим2.НаборПерегрузки_ли)
        (cast(НаборПерегрузки)cast(ук)сим2).добавь(сим);
      else
        сообщиОКонфликтеСимволов(сим, сим2, имя);
    }
    else
      // Create a new overload установи.
      масш.символ.вставь(new НаборПерегрузки(имя, сим.узел), имя);
    // Set the current Масштаб символ as the родитель.
    сим.родитель = масш.символ;
  }

  /// Reports an ошибка: new символ s1 conflicts with existing символ s2.
  проц  сообщиОКонфликтеСимволов(Символ s1, Символ s2, Идентификатор* имя)
  {
    auto место = s2.узел.начало.дайПоложениеОшибки();
    auto locString = Формат("{}({},{})", место.путьКФайлу, место.номСтр, место.номСтолб);
    ошибка(s1.узел.начало, сооб.ДеклКонфликтуетСДекл, имя.ткт, locString);
  }

  /// Ошибка сообщения are reported for undefined identifiers if да.
  бул reportUndefinedIds;

  /// Incremented when an undefined identifier was found.
  бцел undefinedIdsCount;

  /// The символ that must be ignored an пропустиped during a символ ищи.
  Символ ignoreSymbol;

  /// The current Масштаб символ в use for looking up identifiers.
  /// В.g.:
  /// ---
  /// объект.method(); // *) объект is looked up in the current Масштаб.
  ///                  // *) идМасштаб is установи if объект is a СимволМасштаба.
  ///                  // *) method will be looked up in идМасштаб.
  /// drc.ast.Node.Узел узел; // A fully qualified тип.
  /// ---
  СимволМасштаба идМасштаб;

  /// Этот объект is assigned в идМасштаб when a символ сыщи
  /// returned no valid символ.
  static const СимволМасштаба emptyIdScope;
  static this()
  {
    this.emptyIdScope = new СимволМасштаба();
  }

  // Sets a new идМасштаб символ.
  проц  setIdScope(Символ символ)
  {
    if (символ)
      if (auto масшСимвол = cast(СимволМасштаба)символ)
        return идМасштаб = масшСимвол;
    идМасштаб = emptyIdScope;
  }

  /// Searches for a символ.
  Символ ищи(Сема* идСем)
  {
    assert(идСем.вид == TOK.Идентификатор);
    auto ид = идСем.идент;
    Символ символ;

    if (идМасштаб is null)
      // Search in the таблица of another символ.
      символ = ignoreSymbol ?
               масш.ищи(ид, ignoreSymbol) :
               масш.ищи(ид);
    else
      символ = идМасштаб.сыщи(ид);

    if (символ)
      return символ;

    if (reportUndefinedIds)
      ошибка(идСем, сооб.НеопределенныйИдентификатор, ид.ткт);
    undefinedIdsCount++;
    return null;
  }

  /// Creates an ошибка report.
  проц  ошибка(Сема* сема, ткст форматирСооб, ...)
  {
    if (!модуль.диаг)
      return;
    auto положение = сема.дайПоложениеОшибки();
    auto сооб = Формат(_arguments, _argptr, форматирСооб);
    модуль.диаг ~= new ОшибкаСемантики(положение, сооб);
  }
}

class ПерваяСемантическаяПроходка : СемантическаяПроходка
{
  Модуль delegate(ткст) импортируйМодуль; /// Called when importing a module.

  // Attributes:
  ТипКомпоновки типКомпоновки; /// Current linkage тип.
  Защита защита; /// Current защита attribute.
  КлассХранения классХранения; /// Current storage classes.
  бцел размерРаскладки; /// Current align размер.

  /// Строит СемантическаяПроходка объект.
  /// Параметры:
  ///   модуль = the module в be processed.
  ///   контекст = the compilation контекст.
  this(Модуль модуль, КонтекстКомпиляции контекст)
  {
    super(модуль, new КонтекстКомпиляции(контекст));
    this.размерРаскладки = контекст.раскладкаСтруктуры;
  }

  override проц  пуск()
  {
    assert(модуль.корень !is null);
    // Create module Масштаб.
    масш = new Масштаб(null, модуль);
    модуль.семантическийПроходка = 1;
    посетиУ(модуль.корень);
  }

  /+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  |                                Declarations                               |
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+/

override
{
  Д посети(СложнаяДекларация d)
  {
    foreach (декл; d.деклы)
      посетиД(декл);
    return d;
  }

  Д посети(НелегальнаяДекларация)
  { assert(0, "semantic pass on invalid AST"); return null; }

  // Д посети(ПустаяДекларация ed)
  // { return ed; }

  // Д посети(ДекларацияМодуля)
  // { return null; }

  Д посети(ДекларацияИмпорта d)
  {
    if (импортируйМодуль is null)
      return d;
    foreach (путьПоПКНМодуля; d.дайПКНМодуля(папРазд))
    {
      auto importedModule = импортируйМодуль(путьПоПКНМодуля);
      if (importedModule is null)
        ошибка(d.начало, сооб.МодульНеЗагружен, путьПоПКНМодуля ~ ".d");
      модуль.модули ~= importedModule;
    }
    return d;
  }

  Д посети(ДекларацияАлиаса ad)
  {
    return ad;
  }

  Д посети(ДекларацияТипдефа td)
  {
    return td;
  }

  Д посети(ДекларацияПеречня d)
  {
    if (d.символ)
      return d;

    // Create the символ.
    d.символ = new Перечень(d.имя, d);

    бул анонимен_ли = d.символ.анонимен_ли;
    if (анонимен_ли)
      d.символ.имя = ТаблицаИд.генИДАнонПеречня();

    вставь(d.символ);

    auto parentScopeSymbol = масш.символ;
    auto enumSymbol = d.символ;
    войдиВМасштаб(d.символ);
    // Declare члены.
    foreach (член; d.члены)
    {
      посетиД(член);

      if (анонимен_ли) // Also вставь into родитель Масштаб if enum is anonymous.
        вставь(член.символ, parentScopeSymbol);

      член.символ.тип = enumSymbol.тип; // Присвоить ТипПеречень.
    }
    выйдиИзМасштаба();
    return d;
  }

  Д посети(ДекларацияЧленаПеречня d)
  {
    d.символ = new ЧленПеречня(d.имя, защита, классХранения, типКомпоновки, d);
    вставь(d.символ);
    return d;
  }

  Д посети(ДекларацияКласса d)
  {
    if (d.символ)
      return d;
    // Create the символ.
    d.символ = new Класс(d.имя, d);
    // Insert into current Масштаб.
    вставь(d.символ);
    войдиВМасштаб(d.символ);
    // Далее semantic analysis.
    d.деклы && посетиД(d.деклы);
    выйдиИзМасштаба();
    return d;
  }

  Д посети(ДекларацияИнтерфейса d)
  {
    if (d.символ)
      return d;
    // Create the символ.
    d.символ = new drc.semantic.Symbols.Интерфейс(d.имя, d);
    // Insert into current Масштаб.
    вставь(d.символ);
    войдиВМасштаб(d.символ);
      // Далее semantic analysis.
      d.деклы && посетиД(d.деклы);
    выйдиИзМасштаба();
    return d;
  }

  Д посети(ДекларацияСтруктуры d)
  {
    if (d.символ)
      return d;
    // Create the символ.
    d.символ = new Структура(d.имя, d);

    if (d.символ.анонимен_ли)
      d.символ.имя = ТаблицаИд.genAnonStructID();
    // Insert into current Масштаб.
    вставь(d.символ);

    войдиВМасштаб(d.символ);
      // Далее semantic analysis.
      d.деклы && посетиД(d.деклы);
    выйдиИзМасштаба();

    if (d.символ.анонимен_ли)
      // Insert члены into родитель Масштаб as well.
      foreach (член; d.символ.члены)
        вставь(член);
    return d;
  }

  Д посети(ДекларацияСоюза d)
  {
    if (d.символ)
      return d;
    // Create the символ.
    d.символ = new Союз(d.имя, d);

    if (d.символ.анонимен_ли)
      d.символ.имя = ТаблицаИд.genAnonUnionID();

    // Insert into current Масштаб.
    вставь(d.символ);

    войдиВМасштаб(d.символ);
      // Далее semantic analysis.
      d.деклы && посетиД(d.деклы);
    выйдиИзМасштаба();

    if (d.символ.анонимен_ли)
      // Insert члены into родитель Масштаб as well.
      foreach (член; d.символ.члены)
        вставь(член);
    return d;
  }

  Д посети(ДекларацияКонструктора d)
  {
    auto func = new Функция(Идент.Ктор, d);
    вставьПерегрузку(func);
    return d;
  }

  Д посети(ДекларацияСтатическогоКонструктора d)
  {
    auto func = new Функция(Идент.Ктор, d);
    вставьПерегрузку(func);
    return d;
  }

  Д посети(ДекларацияДеструктора d)
  {
    auto func = new Функция(Идент.Дтор, d);
    вставьПерегрузку(func);
    return d;
  }

  Д посети(ДекларацияСтатическогоДеструктора d)
  {
    auto func = new Функция(Идент.Дтор, d);
    вставьПерегрузку(func);
    return d;
  }

  Д посети(ДекларацияФункции d)
  {
    auto func = new Функция(d.имя, d);
    вставьПерегрузку(func);
    return d;
  }

  Д посети(ДекларацияПеременных vd)
  {
    // Ошибка if we are in an interface.
    if (масш.символ.Интерфейс_ли && !vd.статический_ли)
      return ошибка(vd.начало, сооб.УИнтерфейсаНеДолжноБытьПеременных), vd;

    // Insert переменная символы in this declaration into the символ таблица.
    foreach (i, имя; vd.имена)
    {
      auto переменная = new Переменная(имя, защита, классХранения, типКомпоновки, vd);
      переменная.значение = vd.иниты[i];
      vd.переменные ~= переменная;
      вставь(переменная);
    }
    return vd;
  }

  Д посети(ДекларацияИнварианта d)
  {
    auto func = new Функция(Идент.Инвариант, d);
    вставь(func);
    return d;
  }

  Д посети(ДекларацияЮниттеста d)
  {
    auto func = new Функция(Идент.Юниттест, d);
    вставьПерегрузку(func);
    return d;
  }

  Д посети(ДекларацияОтладки d)
  {
    if (d.определение_ли)
    { // debug = Id | Цел
      if (!масштабМодуля_ли())
        ошибка(d.начало, сооб.DebugSpecModuleLevel, d.спец.исхТекст);
      else if (d.спец.вид == TOK.Идентификатор)
        контекст.добавьИдОтладки(d.спец.идент.ткт);
      else
        контекст.уровеньОтладки = d.спец.бцел_;
    }
    else
    { // debug ( Condition )
      if (выборОтладВетви(d.услов, контекст))
        d.компилированныеДеклы = d.деклы;
      else
        d.компилированныеДеклы = d.деклыИначе;
      d.компилированныеДеклы && посетиД(d.компилированныеДеклы);
    }
    return d;
  }

  Д посети(ДекларацияВерсии d)
  {
    if (d.определение_ли)
    { // version = Id | Цел
      if (!масштабМодуля_ли())
        ошибка(d.начало, сооб.VersionSpecModuleLevel, d.спец.исхТекст);
      else if (d.спец.вид == TOK.Идентификатор)
        контекст.добавьИдВерсии(d.спец.идент.ткт);
      else
        контекст.уровеньВерсии = d.спец.бцел_;
    }
    else
    { // version ( Condition )
      if (выборВерсионВетви(d.услов, контекст))
        d.компилированныеДеклы = d.деклы;
      else
        d.компилированныеДеклы = d.деклыИначе;
      d.компилированныеДеклы && посетиД(d.компилированныеДеклы);
    }
    return d;
  }

  Д посети(ДекларацияШаблона d)
  {
    if (d.символ)
      return d;
    // Create the символ.
    d.символ = new Шаблон(d.имя, d);
    // Insert into current Масштаб.
    вставьПерегрузку(d.символ);
    return d;
  }

  Д посети(ДекларацияНов d)
  {
    auto func = new Функция(Идент.Нов, d);
    вставь(func);
    return d;
  }

  Д посети(ДекларацияУдали d)
  {
    auto func = new Функция(Идент.Удалить, d);
    вставь(func);
    return d;
  }

  // Attributes:

  Д посети(ДекларацияЗащиты d)
  {
    auto saved = защита; // Save.
    защита = d.защ; // Set.
    посетиД(d.деклы);
    защита = saved; // Restore.
    return d;
  }

  Д посети(ДекларацияКлассаХранения d)
  {
    auto saved = классХранения; // Save.
    классХранения = d.классХранения; // Set.
    посетиД(d.деклы);
    классХранения = saved; // Restore.
    return d;
  }

  Д посети(ДекларацияКомпоновки d)
  {
    auto saved = типКомпоновки; // Save.
    типКомпоновки = d.типКомпоновки; // Set.
    посетиД(d.деклы);
    типКомпоновки = saved; // Restore.
    return d;
  }

  Д посети(ДекларацияРазложи d)
  {
    auto saved = размерРаскладки; // Save.
    размерРаскладки = d.размер; // Set.
    посетиД(d.деклы);
    размерРаскладки = saved; // Restore.
    return d;
  }

  Д посети(ДекларацияСтатическогоПодтверди d)
  {
    return d;
  }

  Д посети(ДекларацияСтатическогоЕсли d)
  {
    return d;
  }

  Д посети(ДекларацияСмеси d)
  {
    return d;
  }

  Д посети(ДекларацияПрагмы d)
  {
    if (d.идент is Идент.сооб)
    {
      // TODO
    }
    else
    {
      семантикаПрагмы(масш, d.начало, d.идент, d.арги);
      посетиД(d.деклы);
    }
    return d;
  }
} // override

  /+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  |                                 Statements                                |
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+/

  /// The current surrounding, breakable statement.
  И breakableStatement;

  И setBS(И s)
  {
    auto old = breakableStatement;
    breakableStatement = s;
    return old;
  }

  проц  restoreBS(И s)
  {
    breakableStatement = s;
  }

override
{
  И посети(СложнаяИнструкция s)
  {
    foreach (stmnt; s.инстрции)
      посетиИ(stmnt);
    return s;
  }

  И посети(НелегальнаяИнструкция)
  { assert(0, "semantic pass on invalid AST"); return null; }

  И посети(ПустаяИнструкция s)
  {
    return s;
  }

  И посети(ИнструкцияТелаФункции s)
  {
    return s;
  }

  И посети(ИнструкцияМасштаб s)
  {
//     войдиВМасштаб();
    посетиИ(s.s);
//     выйдиИзМасштаба();
    return s;
  }

  И посети(ИнструкцияСМеткой s)
  {
    return s;
  }

  И посети(ИнструкцияВыражение s)
  {
    return s;
  }

  И посети(ИнструкцияДекларация s)
  {
    return s;
  }

  И посети(ИнструкцияЕсли s)
  {
    return s;
  }

  И посети(ИнструкцияПока s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  И посети(ИнструкцияДелайПока s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  И посети(ИнструкцияПри s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  И посети(ИнструкцияСКаждым s)
  {
    auto saved = setBS(s);
    // TODO:
    // find overload opApply or opApplyReverse.
    restoreBS(saved);
    return s;
  }

  // D2.0
  И посети(ИнструкцияДиапазонСКаждым s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  И посети(ИнструкцияЩит s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  И посети(ИнструкцияРеле s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  И посети(ИнструкцияДефолт s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  И посети(ИнструкцияДалее s)
  {
    return s;
  }

  И посети(ИнструкцияВсё s)
  {
    return s;
  }

  И посети(ИнструкцияИтог s)
  {
    return s;
  }

  И посети(ИнструкцияПереход s)
  {
    return s;
  }

  И посети(ИнструкцияДля s)
  {
    return s;
  }

  И посети(ИнструкцияСинхр s)
  {
    return s;
  }

  И посети(ИнструкцияПробуй s)
  {
    return s;
  }

  И посети(ИнструкцияЛови s)
  {
    return s;
  }

  И посети(ИнструкцияИтожь s)
  {
    return s;
  }

  И посети(ИнструкцияСтражМасштаба s)
  {
    return s;
  }

  И посети(ИнструкцияБрось s)
  {
    return s;
  }

  И посети(ИнструкцияЛетучее s)
  {
    return s;
  }

  И посети(ИнструкцияБлокАсм s)
  {
    foreach (stmnt; s.инструкции.инстрции)
      посетиИ(stmnt);
    return s;
  }

  И посети(ИнструкцияАсм s)
  {
    return s;
  }

  И посети(ИнструкцияАсмРасклад s)
  {
    return s;
  }

  И посети(ИнструкцияНелегальныйАсм)
  { assert(0, "semantic pass on invalid AST"); return null; }

  И посети(ИнструкцияПрагма s)
  {
    return s;
  }

  И посети(ИнструкцияСмесь s)
  {
    return s;
  }

  И посети(ИнструкцияСтатическоеЕсли s)
  {
    return s;
  }

  И посети(ИнструкцияСтатическоеПодтверди s)
  {
    return s;
  }

  И посети(ИнструкцияОтладка s)
  {
    return s;
  }

  И посети(ИнструкцияВерсия s)
  {
    return s;
  }
} // override

  /+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  |                                Expressions                                |
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+/

  /// Determines whether в issue an ошибка when a символ couldn't be found.
  бул errorOnUndefinedSymbol;
  //бул errorOnUnknownSymbol;

  /// Reports an ошибка if 'e' is of тип бул.
  проц  errorЕслиBool(Выражение в)
  {
    ошибка(в.начало, "такая операция для типа бул не определена");
  }

  /// Returns a call выражение if 'e' overrides
  /// an operatorwith the имя 'ид'.
  /// Параметры:
  ///   в = the binary выражение в be checked.
  ///   ид = the имя of the overload function.
  Выражение findOverload(УнарноеВыражение в, Идентификатор* ид)
  {
    // TODO:
    // check в for struct or class
    // ищи for function named ид
    // return call выражение: в.opXYZ()
    return null;
  }

  /// Returns a call выражение if 'e' overrides
  /// an operator with the имя 'ид' or 'id_r'.
  /// Параметры:
  ///   в = the binary выражение в be checked.
  ///   ид = the имя of the overload function.
  ///   id_r = the имя of the reverse overload function.
  Выражение findOverload(БинарноеВыражение в, Идентификатор* ид, Идентификатор* id_r)
  {
    // TODO:
    return null;
  }

override
{
  В посети(НелегальноеВыражение)
  { assert(0, "semantic pass on invalid AST"); return null; }

  В посети(ВыражениеУсловия в)
  {
    return в;
  }

  В посети(ВыражениеЗапятая в)
  {
    if (!в.естьТип)
    {
      в.лв = посетиВ(в.лв);
      в.пв = посетиВ(в.пв);
      в.тип = в.пв.тип;
    }
    return в;
  }

  В посети(ВыражениеИлиИли в)
  {
    return в;
  }

  В посети(ВыражениеИИ в)
  {
    return в;
  }

  В посети(ВыражениеИли в)
  {
    if (auto o = findOverload(в, Идент.opOr, Идент.opOr_r))
      return o;
    return в;
  }

  В посети(ВыражениеИИли в)
  {
    if (auto o = findOverload(в, Идент.opXor, Идент.opXor_r))
      return o;
    return в;
  }

  В посети(ВыражениеИ в)
  {
    if (auto o = findOverload(в, Идент.opAnd, Идент.opAnd_r))
      return o;
    return в;
  }

  В посети(ВыражениеРавно в)
  {
    if (auto o = findOverload(в, Идент.opEquals, null))
      return o;
    return в;
  }

  В посети(ВыражениеРавенство в)
  {
    return в;
  }

  В посети(ВыражениеОтнош в)
  {
    if (auto o = findOverload(в, Идент.opCmp, null))
      return o;
    return в;
  }

  В посети(ВыражениеВхо в)
  {
    if (auto o = findOverload(в, Идент.opIn, Идент.opIn_r))
      return o;
    return в;
  }

  В посети(ВыражениеЛСдвиг в)
  {
    if (auto o = findOverload(в, Идент.opShl, Идент.opShl_r))
      return o;
    return в;
  }

  В посети(ВыражениеПСдвиг в)
  {
    if (auto o = findOverload(в, Идент.opShr, Идент.opShr_r))
      return o;
    return в;
  }

  В посети(ВыражениеБПСдвиг в)
  {
    if (auto o = findOverload(в, Идент.opUShr, Идент.opUShr_r))
      return o;
    return в;
  }

  В посети(ВыражениеПлюс в)
  {
    if (auto o = findOverload(в, Идент.opAdd, Идент.opAdd_r))
      return o;
    return в;
  }

  В посети(ВыражениеМинус в)
  {
    if (auto o = findOverload(в, Идент.opSub, Идент.opSub_r))
      return o;
    return в;
  }

  В посети(ВыражениеСоедини в)
  {
    if (auto o = findOverload(в, Идент.opCat, Идент.opCat_r))
      return o;
    return в;
  }

  В посети(ВыражениеУмножь в)
  {
    if (auto o = findOverload(в, Идент.opMul, Идент.opMul_r))
      return o;
    return в;
  }

  В посети(ВыражениеДели в)
  {
    if (auto o = findOverload(в, Идент.opDiv, Идент.opDiv_r))
      return o;
    return в;
  }

  В посети(ВыражениеМод в)
  {
    if (auto o = findOverload(в, Идент.opMod, Идент.opMod_r))
      return o;
    return в;
  }

  В посети(ВыражениеПрисвой в)
  {
    if (auto o = findOverload(в, Идент.opAssign, null))
      return o;
    // TODO: also check for opIndexAssign and opSliceAssign.
    return в;
  }

  В посети(ВыражениеПрисвойЛСдвиг в)
  {
    if (auto o = findOverload(в, Идент.opShlAssign, null))
      return o;
    return в;
  }

  В посети(ВыражениеПрисвойПСдвиг в)
  {
    if (auto o = findOverload(в, Идент.opShrAssign, null))
      return o;
    return в;
  }

  В посети(ВыражениеПрисвойБПСдвиг в)
  {
    if (auto o = findOverload(в, Идент.opUShrAssign, null))
      return o;
    return в;
  }

  В посети(ВыражениеПрисвойИли в)
  {
    if (auto o = findOverload(в, Идент.opOrAssign, null))
      return o;
    return в;
  }

  В посети(ВыражениеПрисвойИ в)
  {
    if (auto o = findOverload(в, Идент.opAndAssign, null))
      return o;
    return в;
  }

  В посети(ВыражениеПрисвойПлюс в)
  {
    if (auto o = findOverload(в, Идент.opAddAssign, null))
      return o;
    return в;
  }

  В посети(ВыражениеПрисвойМинус в)
  {
    if (auto o = findOverload(в, Идент.opSubAssign, null))
      return o;
    return в;
  }

  В посети(ВыражениеПрисвойДел в)
  {
    auto o = findOverload(в, Идент.opDivAssign, null);
    if (o)
      return o;
    return в;
  }

  В посети(ВыражениеПрисвойУмн в)
  {
    auto o = findOverload(в, Идент.opMulAssign, null);
    if (o)
      return o;
    return в;
  }

  В посети(ВыражениеПрисвойМод в)
  {
    auto o = findOverload(в, Идент.opModAssign, null);
    if (o)
      return o;
    return в;
  }

  В посети(ВыражениеПрисвойИИли в)
  {
    auto o = findOverload(в, Идент.opXorAssign, null);
    if (o)
      return o;
    return в;
  }

  В посети(ВыражениеПрисвойСоед в)
  {
    auto o = findOverload(в, Идент.opCatAssign, null);
    if (o)
      return o;
    return в;
  }

  В посети(ВыражениеАдрес в)
  {
    if (в.естьТип)
      return в;
    в.в = посетиВ(в.в);
    в.тип = в.в.тип.укНа();
    return в;
  }

  В посети(ВыражениеПреИнкр в)
  {
    if (в.естьТип)
      return в;
    // TODO: rewrite в в+=1
    в.в = посетиВ(в.в);
    в.тип = в.в.тип;
    errorЕслиBool(в.в);
    return в;
  }

  В посети(ВыражениеПреДекр в)
  {
    if (в.естьТип)
      return в;
    // TODO: rewrite в в-=1
    в.в = посетиВ(в.в);
    в.тип = в.в.тип;
    errorЕслиBool(в.в);
    return в;
  }

  В посети(ВыражениеПостИнкр в)
  {
    if (в.естьТип)
      return в;
    if (auto o = findOverload(в, Идент.opPostInc))
      return o;
    в.в = посетиВ(в.в);
    в.тип = в.в.тип;
    errorЕслиBool(в.в);
    return в;
  }

  В посети(ВыражениеПостДекр в)
  {
    if (в.естьТип)
      return в;
    if (auto o = findOverload(в, Идент.opPostDec))
      return o;
    в.в = посетиВ(в.в);
    в.тип = в.в.тип;
    errorЕслиBool(в.в);
    return в;
  }

  В посети(ВыражениеДереф в)
  {
    if (в.естьТип)
      return в;
  version(D2)
    if (auto o = findOverload(в, Идент.opStar))
      return o;
    в.в = посетиВ(в.в);
    в.тип = в.в.тип.следщ;
    if (!в.в.тип.указатель_ли)
    {
      ошибка(в.в.начало,
        "dereference оператор '*x' не определён для выражения типа '{}'",
        в.в.тип.вТкст());
      в.тип = Типы.Ошибка;
    }
    // TODO:
    // if (в.в.тип.isVoid)
    //   ошибка();
    return в;
  }

  В посети(ВыражениеЗнак в)
  {
    if (в.естьТип)
      return в;
    if (auto o = findOverload(в, в.отриц_ли ? Идент.opNeg : Идент.opPos))
      return o;
    в.в = посетиВ(в.в);
    в.тип = в.в.тип;
    errorЕслиBool(в.в);
    return в;
  }

  В посети(ВыражениеНе в)
  {
    if (в.естьТип)
      return в;
    в.в = посетиВ(в.в);
    в.тип = Типы.Бул;
    // TODO: в.в must be convertible в бул.
    return в;
  }

  В посети(ВыражениеКомп в)
  {
    if (в.естьТип)
      return в;
    if (auto o = findOverload(в, Идент.opCom))
      return o;
    в.в = посетиВ(в.в);
    в.тип = в.в.тип;
    if (в.тип.плавающий_ли || в.тип.бул_ли)
    {
      ошибка(в.начало, "ОПЕРАТОР '~x' не определён для типа '{}'",  в.тип.вТкст());
      в.тип = Типы.Ошибка;
    }
    return в;
  }

  В посети(ВыражениеВызов в)
  {
    if (auto o = findOverload(в, Идент.opCall))
      return o;
    return в;
  }

  В посети(ВыражениеНов в)
  {
    return в;
  }

  В посети(ВыражениеНовАнонКласс в)
  {
    return в;
  }

  В посети(ВыражениеУдали в)
  {
    return в;
  }

  В посети(ВыражениеКаст в)
  {
    if (auto o = findOverload(в, Идент.opCast))
      return o;
    return в;
  }

  В посети(ВыражениеИндекс в)
  {
    if (auto o = findOverload(в, Идент.opIndex))
      return o;
    return в;
  }

  В посети(ВыражениеСрез в)
  {
    if (auto o = findOverload(в, Идент.opSlice))
      return o;
    return в;
  }

  В посети(ВыражениеТочка в)
  {
    if (в.естьТип)
      return в;
    бул resetIdScope = идМасштаб is null;
    // TODO:
    resetIdScope && (идМасштаб = null);
    return в;
  }

  В посети(ВыражениеМасштабМодуля в)
  {
    if (в.естьТип)
      return в;
    бул resetIdScope = идМасштаб is null;
    идМасштаб = модуль;
    в.в = посетиВ(в.в);
    в.тип = в.в.тип;
    resetIdScope && (идМасштаб = null);
    return в;
  }

  В посети(ВыражениеИдентификатор в)
  {
    if (в.естьТип)
      return в;
    debug(sema) выдай.форматнс("", в);
    auto идСема = в.идСема();
    в.символ = ищи(идСема);
    return в;
  }

  В посети(ВыражениеЭкземплярШаблона в)
  {
    if (в.естьТип)
      return в;
    debug(sema) выдай.форматнс("", в);
    auto идСема = в.идСема();
    в.символ = ищи(идСема);
    return в;
  }

  В посети(ВыражениеСпецСема в)
  {
    if (в.естьТип)
      return в.значение;
    switch (в.особаяСема.вид)
    {
    case TOK.СТРОКА, TOK.ВЕРСИЯ:
      в.значение = new ЦелВыражение(в.особаяСема.бцел_, Типы.Бцел);
      break;
    case TOK.ФАЙЛ, TOK.ДАТА, TOK.ВРЕМЯ, TOK.ШТАМПВРЕМЕНИ, TOK.ПОСТАВЩИК:
      в.значение = new ТекстовоеВыражение(в.особаяСема.ткт);
      break;
    default:
      assert(0);
    }
    в.тип = в.значение.тип;
    return в.значение;
  }

  В посети(ВыражениеЭтот в)
  {
    return в;
  }

  В посети(ВыражениеСупер в)
  {
    return в;
  }

  В посети(ВыражениеНуль в)
  {
    if (!в.естьТип)
      в.тип = Типы.Проц_ук;
    return в;
  }

  В посети(ВыражениеДоллар в)
  {
    if (в.естьТип)
      return в;
    в.тип = Типы.Т_мера;
    // if (!inArraySubscript)
    //   ошибка("$ can only be in an массив subscript.");
    return в;
  }

  В посети(БулевоВыражение в)
  {
    assert(в.естьТип);
    return в.значение;
  }

  В посети(ЦелВыражение в)
  {
    if (в.естьТип)
      return в;

    if (в.число & 0x8000_0000_0000_0000)
      в.тип = Типы.Бдол; // 0xFFFF_FFFF_FFFF_FFFF
    else if (в.число & 0xFFFF_FFFF_0000_0000)
      в.тип = Типы.Дол; // 0x7FFF_FFFF_FFFF_FFFF
    else if (в.число & 0x8000_0000)
      в.тип = Типы.Бцел; // 0xFFFF_FFFF
    else
      в.тип = Типы.Цел; // 0x7FFF_FFFF
    return в;
  }

  В посети(ВыражениеРеал в)
  {
    if (!в.естьТип)
      в.тип = Типы.Дво;
    return в;
  }

  В посети(ВыражениеКомплекс в)
  {
    if (!в.естьТип)
      в.тип = Типы.Кдво;
    return в;
  }

  В посети(ВыражениеСим в)
  {
    assert(в.естьТип);
    return в.значение;
  }

  В посети(ТекстовоеВыражение в)
  {
    assert(в.естьТип);
    return в;
  }

  В посети(ВыражениеЛитералМассива в)
  {
    return в;
  }

  В посети(ВыражениеЛитералАМассива в)
  {
    return в;
  }

  В посети(ВыражениеПодтверди в)
  {
    return в;
  }

  В посети(ВыражениеСмесь в)
  {
    return в;
  }

  В посети(ВыражениеИмпорта в)
  {
    return в;
  }

  В посети(ВыражениеТипа в)
  {
    return в;
  }

  В посети(ВыражениеИдТипаТочка в)
  {
    return в;
  }

  В посети(ВыражениеИдТипа в)
  {
    return в;
  }

  В посети(ВыражениеЯвляется в)
  {
    return в;
  }

  В посети(ВыражениеРодит в)
  {
    if (!в.естьТип)
    {
      в.следщ = посетиВ(в.следщ);
      в.тип = в.следщ.тип;
    }
    return в;
  }

  В посети(ВыражениеЛитералФункции в)
  {
    return в;
  }

  В посети(ВыражениеТрактовки в) // D2.0
  {
    return в;
  }

  В посети(ВыражениеИницПроц в)
  {
    return в;
  }

  В посети(ВыражениеИницМассива в)
  {
    return в;
  }

  В посети(ВыражениеИницСтруктуры в)
  {
    return в;
  }

  В посети(ВыражениеТипАсм в)
  {
    return в;
  }

  В посети(ВыражениеСмещениеАсм в)
  {
    return в;
  }

  В посети(ВыражениеСегАсм в)
  {
    return в;
  }

  В посети(ВыражениеАсмПослеСкобки в)
  {
    return в;
  }

  В посети(ВыражениеАсмСкобка в)
  {
    return в;
  }

  В посети(ВыражениеЛокальногоРазмераАсм в)
  {
    return в;
  }

  В посети(ВыражениеАсмРегистр в)
  {
    return в;
  }
} // override

  /+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  |                                   Типы                                   |
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+/

override
{
  Т посети(НелегальныйТип)
  { assert(0, "semantic pass on invalid AST"); return null; }

  Т посети(ИнтегральныйТип t)
  {
    // A таблица mapping the вид of a сема в its corresponding semantic Тип.
    ТипБазовый[TOK] семВТип = [
      TOK.Сим : Типы.Сим,   TOK.Шим : Типы.Шим,   TOK.Дим : Типы.Дим, TOK.Бул : Типы.Бул,
      TOK.Байт : Типы.Байт,   TOK.Ббайт : Типы.Ббайт,   TOK.Крат : Типы.Крат, TOK.Бкрат : Типы.Бкрат,
      TOK.Цел : Типы.Цел,    TOK.Бцел : Типы.Бцел,    TOK.Дол : Типы.Дол,  TOK.Бдол : Типы.Бдол,
      TOK.Цент : Типы.Цент,   TOK.Бцент : Типы.Бцент,
      TOK.Плав : Типы.Плав,  TOK.Дво : Типы.Дво,  TOK.Реал : Типы.Реал,
      TOK.Вплав : Типы.Вплав, TOK.Вдво : Типы.Вдво, TOK.Вреал : Типы.Вреал,
      TOK.Кплав : Типы.Кплав, TOK.Кдво : Типы.Кдво, TOK.Креал : Типы.Креал, TOK.Проц : Типы.Проц
    ];
    assert(t.лекс in семВТип);
    t.тип = семВТип[t.лекс];
    return t;
  }

  Т посети(КвалифицированныйТип t)
  {
    // Reset идМасштаб at the конец if this the корень КвалифицированныйТип.
    бул resetIdScope = идМасштаб is null;
//     if (t.лв.Является!(КвалифицированныйТип) is null)
//       идМасштаб = null; // Reset at левый-most тип.
    посетиТ(t.лв);
    // Присвоить the символ of the левый-hand сторона в идМасштаб.
    setIdScope(t.лв.символ);
    посетиТ(t.пв);
//     setIdScope(t.пв.символ);
    // Присвоить члены of the правый-hand сторона в this тип.
    t.тип = t.пв.тип;
    t.символ = t.пв.символ;
    // Reset идМасштаб.
    resetIdScope && (идМасштаб = null);
    return t;
  }

  Т посети(ТМасштабМодуля t)
  {
    идМасштаб = модуль;
    return t;
  }

  Т посети(ТИдентификатор t)
  {
    auto идСема = t.начало;
    auto символ = ищи(идСема);
    // TODO: save символ or its тип in t.
    return t;
  }

  Т посети(ТТип t)
  {
    t.в = посетиВ(t.в);
    t.тип = t.в.тип;
    return t;
  }

  Т посети(ТЭкземплярШаблона t)
  {
    auto идСема = t.начало;
    auto символ = ищи(идСема);
    // TODO: save символ or its тип in t.
    return t;
  }

  Т посети(ТУказатель t)
  {
    t.тип = посетиТ(t.следщ).тип.укНа();
    return t;
  }

  Т посети(ТМассив t)
  {
    auto типОснова = посетиТ(t.следщ).тип;
    if (t.ассоциативный_ли)
      t.тип = типОснова.массивИз(посетиТ(t.ассоцТип).тип);
    else if (t.динамический_ли)
      t.тип = типОснова.массивИз();
    else if (t.статический_ли)
    {}
    else
      assert(t.срез_ли);
    return t;
  }

  Т посети(ТФункция t)
  {
    return t;
  }

  Т посети(ТДелегат t)
  {
    return t;
  }

  Т посети(ТУказательНаФункСи t)
  {
    return t;
  }

  Т посети(ТипКлассОснова t)
  {
    return t;
  }

  Т посети(ТКонст t) // D2.0
  {
    return t;
  }

  Т посети(ТИнвариант t) // D2.0
  {
    return t;
  }
} // override

  /+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  |                                 Параметры                                |
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+/

override
{
  У посети(Параметр p)
  {
    return p;
  }

  У посети(Параметры p)
  {
    return p;
  }

  У посети(ПараметрАлиасШаблона p)
  {
    return p;
  }

  У посети(ПараметрТипаШаблона p)
  {
    return p;
  }

  У посети(ПараметрЭтотШаблона p) // D2.0
  {
    return p;
  }

  У посети(ПараметрШаблонЗначения p)
  {
    return p;
  }

  У посети(ПараметрКортежШаблона p)
  {
    return p;
  }

  У посети(ПараметрыШаблона p)
  {
    return p;
  }

  У посети(АргументыШаблона p)
  {
    return p;
  }
} // override
}
