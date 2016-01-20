/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity low)
/// Description: Этот module is here for testing
/// a different algorithm в do semantic analysis
/// compared в СемантическаяПроходка1 and СемантическаяПроходка2!
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
private alias Декларация D;
private alias Выражение E; /// определено
private alias Инструкция S; /// определено
private alias УзелТипа T; /// определено
private alias Параметр P; /// определено
private alias Узел N; /// определено

/// Base class of all другой semantic pass classes.
abstract class СемантическаяПроходка : ДефолтныйВизитёр
{
  Масштаб масш; /// The current Масштаб.
  Модуль модуль; /// The module в be semantically checked.
  КонтекстКомпиляции контекст; /// The compilation контекст.

  /// Constructs a СемантическаяПроходка object.
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

  /// Возвращает да, если это the module Масштаб.
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
  /// E.g.:
  /// ---
  /// object.method(); // *) object is looked up in the current Масштаб.
  ///                  // *) идМасштаб is установи if object is a СимволМасштаба.
  ///                  // *) method will be looked up in идМасштаб.
  /// drc.ast.Node.Узел узел; // A fully qualified тип.
  /// ---
  СимволМасштаба идМасштаб;

  /// Этот object is assigned в идМасштаб when a символ сыщи
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
  проц  ошибка(Сема* сема, сим[] форматирСооб, ...)
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

  /// Constructs a СемантическаяПроходка object.
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
  D посети(СложнаяДекларация d)
  {
    foreach (декл; d.деклы)
      посетиД(декл);
    return d;
  }

  D посети(НелегальнаяДекларация)
  { assert(0, "semantic pass on invalid AST"); return null; }

  // D посети(ПустаяДекларация ed)
  // { return ed; }

  // D посети(ДекларацияМодуля)
  // { return null; }

  D посети(ДекларацияИмпорта d)
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

  D посети(ДекларацияАлиаса ad)
  {
    return ad;
  }

  D посети(ДекларацияТипдефа td)
  {
    return td;
  }

  D посети(ДекларацияПеречня d)
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

  D посети(ДекларацияЧленаПеречня d)
  {
    d.символ = new ЧленПеречня(d.имя, защита, классХранения, типКомпоновки, d);
    вставь(d.символ);
    return d;
  }

  D посети(ДекларацияКласса d)
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

  D посети(ДекларацияИнтерфейса d)
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

  D посети(ДекларацияСтруктуры d)
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

  D посети(ДекларацияСоюза d)
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

  D посети(ДекларацияКонструктора d)
  {
    auto func = new Функция(Идент.Ктор, d);
    вставьПерегрузку(func);
    return d;
  }

  D посети(ДекларацияСтатическогоКонструктора d)
  {
    auto func = new Функция(Идент.Ктор, d);
    вставьПерегрузку(func);
    return d;
  }

  D посети(ДекларацияДеструктора d)
  {
    auto func = new Функция(Идент.Дтор, d);
    вставьПерегрузку(func);
    return d;
  }

  D посети(ДекларацияСтатическогоДеструктора d)
  {
    auto func = new Функция(Идент.Дтор, d);
    вставьПерегрузку(func);
    return d;
  }

  D посети(ДекларацияФункции d)
  {
    auto func = new Функция(d.имя, d);
    вставьПерегрузку(func);
    return d;
  }

  D посети(ДекларацияПеременных vd)
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

  D посети(ДекларацияИнварианта d)
  {
    auto func = new Функция(Идент.Инвариант, d);
    вставь(func);
    return d;
  }

  D посети(ДекларацияЮниттеста d)
  {
    auto func = new Функция(Идент.Юниттест, d);
    вставьПерегрузку(func);
    return d;
  }

  D посети(ДекларацияОтладки d)
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
      if (debugBranchChoice(d.услов, контекст))
        d.компилированныеДеклы = d.деклы;
      else
        d.компилированныеДеклы = d.деклыИначе;
      d.компилированныеДеклы && посетиД(d.компилированныеДеклы);
    }
    return d;
  }

  D посети(ДекларацияВерсии d)
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
      if (versionBranchChoice(d.услов, контекст))
        d.компилированныеДеклы = d.деклы;
      else
        d.компилированныеДеклы = d.деклыИначе;
      d.компилированныеДеклы && посетиД(d.компилированныеДеклы);
    }
    return d;
  }

  D посети(ДекларацияШаблона d)
  {
    if (d.символ)
      return d;
    // Create the символ.
    d.символ = new Шаблон(d.имя, d);
    // Insert into current Масштаб.
    вставьПерегрузку(d.символ);
    return d;
  }

  D посети(ДекларацияНов d)
  {
    auto func = new Функция(Идент.Нов, d);
    вставь(func);
    return d;
  }

  D посети(ДекларацияУдали d)
  {
    auto func = new Функция(Идент.Удалить, d);
    вставь(func);
    return d;
  }

  // Attributes:

  D посети(ДекларацияЗащиты d)
  {
    auto saved = защита; // Save.
    защита = d.защ; // Set.
    посетиД(d.деклы);
    защита = saved; // Restore.
    return d;
  }

  D посети(ДекларацияКлассаХранения d)
  {
    auto saved = классХранения; // Save.
    классХранения = d.классХранения; // Set.
    посетиД(d.деклы);
    классХранения = saved; // Restore.
    return d;
  }

  D посети(ДекларацияКомпоновки d)
  {
    auto saved = типКомпоновки; // Save.
    типКомпоновки = d.типКомпоновки; // Set.
    посетиД(d.деклы);
    типКомпоновки = saved; // Restore.
    return d;
  }

  D посети(ДекларацияРазложи d)
  {
    auto saved = размерРаскладки; // Save.
    размерРаскладки = d.размер; // Set.
    посетиД(d.деклы);
    размерРаскладки = saved; // Restore.
    return d;
  }

  D посети(ДекларацияСтатическогоПодтверди d)
  {
    return d;
  }

  D посети(ДекларацияСтатическогоЕсли d)
  {
    return d;
  }

  D посети(ДекларацияСмеси d)
  {
    return d;
  }

  D посети(ДекларацияПрагмы d)
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
  S breakableStatement;

  S setBS(S s)
  {
    auto old = breakableStatement;
    breakableStatement = s;
    return old;
  }

  проц  restoreBS(S s)
  {
    breakableStatement = s;
  }

override
{
  S посети(СложнаяИнструкция s)
  {
    foreach (stmnt; s.инстрции)
      посетиИ(stmnt);
    return s;
  }

  S посети(НелегальнаяИнструкция)
  { assert(0, "semantic pass on invalid AST"); return null; }

  S посети(ПустаяИнструкция s)
  {
    return s;
  }

  S посети(ИнструкцияТелаФункции s)
  {
    return s;
  }

  S посети(ИнструкцияМасштаб s)
  {
//     войдиВМасштаб();
    посетиИ(s.s);
//     выйдиИзМасштаба();
    return s;
  }

  S посети(ИнструкцияСМеткой s)
  {
    return s;
  }

  S посети(ИнструкцияВыражение s)
  {
    return s;
  }

  S посети(ИнструкцияДекларация s)
  {
    return s;
  }

  S посети(ИнструкцияЕсли s)
  {
    return s;
  }

  S посети(ИнструкцияПока s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  S посети(ИнструкцияДелайПока s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  S посети(ИнструкцияПри s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  S посети(ИнструкцияСКаждым s)
  {
    auto saved = setBS(s);
    // TODO:
    // find overload opApply or opApplyReverse.
    restoreBS(saved);
    return s;
  }

  // D2.0
  S посети(ИнструкцияДиапазонСКаждым s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  S посети(ИнструкцияЩит s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  S посети(ИнструкцияРеле s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  S посети(ИнструкцияДефолт s)
  {
    auto saved = setBS(s);
    // TODO:
    restoreBS(saved);
    return s;
  }

  S посети(ИнструкцияДалее s)
  {
    return s;
  }

  S посети(ИнструкцияВсё s)
  {
    return s;
  }

  S посети(ИнструкцияИтог s)
  {
    return s;
  }

  S посети(ИнструкцияПереход s)
  {
    return s;
  }

  S посети(ИнструкцияДля s)
  {
    return s;
  }

  S посети(ИнструкцияСинхр s)
  {
    return s;
  }

  S посети(ИнструкцияПробуй s)
  {
    return s;
  }

  S посети(ИнструкцияЛови s)
  {
    return s;
  }

  S посети(ИнструкцияИтожь s)
  {
    return s;
  }

  S посети(ИнструкцияСтражМасштаба s)
  {
    return s;
  }

  S посети(ИнструкцияБрось s)
  {
    return s;
  }

  S посети(ИнструкцияЛетучее s)
  {
    return s;
  }

  S посети(ИнструкцияБлокАсм s)
  {
    foreach (stmnt; s.инструкции.инстрции)
      посетиИ(stmnt);
    return s;
  }

  S посети(ИнструкцияАсм s)
  {
    return s;
  }

  S посети(ИнструкцияАсмРасклад s)
  {
    return s;
  }

  S посети(ИнструкцияНелегальныйАсм)
  { assert(0, "semantic pass on invalid AST"); return null; }

  S посети(ИнструкцияПрагма s)
  {
    return s;
  }

  S посети(ИнструкцияСмесь s)
  {
    return s;
  }

  S посети(ИнструкцияСтатическоеЕсли s)
  {
    return s;
  }

  S посети(ИнструкцияСтатическоеПодтверди s)
  {
    return s;
  }

  S посети(ИнструкцияОтладка s)
  {
    return s;
  }

  S посети(ИнструкцияВерсия s)
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
    ошибка(в.начало, "the operation is not defined for the тип бул");
  }

  /// Returns a call expression if 'e' overrides
  /// an operatorwith the имя 'ид'.
  /// Параметры:
  ///   в = the binary expression в be checked.
  ///   ид = the имя of the overload function.
  Выражение findOverload(УнарноеВыражение в, Идентификатор* ид)
  {
    // TODO:
    // check в for struct or class
    // ищи for function named ид
    // return call expression: в.opXYZ()
    return null;
  }

  /// Returns a call expression if 'e' overrides
  /// an operator with the имя 'ид' or 'id_r'.
  /// Параметры:
  ///   в = the binary expression в be checked.
  ///   ид = the имя of the overload function.
  ///   id_r = the имя of the reverse overload function.
  Выражение findOverload(БинарноеВыражение в, Идентификатор* ид, Идентификатор* id_r)
  {
    // TODO:
    return null;
  }

override
{
  E посети(НелегальноеВыражение)
  { assert(0, "semantic pass on invalid AST"); return null; }

  E посети(ВыражениеУсловия в)
  {
    return в;
  }

  E посети(ВыражениеЗапятая в)
  {
    if (!в.естьТип)
    {
      в.лв = посетиВ(в.лв);
      в.пв = посетиВ(в.пв);
      в.тип = в.пв.тип;
    }
    return в;
  }

  E посети(ВыражениеИлиИли в)
  {
    return в;
  }

  E посети(ВыражениеИИ в)
  {
    return в;
  }

  E посети(ВыражениеИли в)
  {
    if (auto o = findOverload(в, Идент.opOr, Идент.opOr_r))
      return o;
    return в;
  }

  E посети(ВыражениеИИли в)
  {
    if (auto o = findOverload(в, Идент.opXor, Идент.opXor_r))
      return o;
    return в;
  }

  E посети(ВыражениеИ в)
  {
    if (auto o = findOverload(в, Идент.opAnd, Идент.opAnd_r))
      return o;
    return в;
  }

  E посети(ВыражениеРавно в)
  {
    if (auto o = findOverload(в, Идент.opEquals, null))
      return o;
    return в;
  }

  E посети(ВыражениеРавенство в)
  {
    return в;
  }

  E посети(ВыражениеОтнош в)
  {
    if (auto o = findOverload(в, Идент.opCmp, null))
      return o;
    return в;
  }

  E посети(ВыражениеВхо в)
  {
    if (auto o = findOverload(в, Идент.opIn, Идент.opIn_r))
      return o;
    return в;
  }

  E посети(ВыражениеЛСдвиг в)
  {
    if (auto o = findOverload(в, Идент.opShl, Идент.opShl_r))
      return o;
    return в;
  }

  E посети(ВыражениеПСдвиг в)
  {
    if (auto o = findOverload(в, Идент.opShr, Идент.opShr_r))
      return o;
    return в;
  }

  E посети(ВыражениеБПСдвиг в)
  {
    if (auto o = findOverload(в, Идент.opUShr, Идент.opUShr_r))
      return o;
    return в;
  }

  E посети(ВыражениеПлюс в)
  {
    if (auto o = findOverload(в, Идент.opAdd, Идент.opAdd_r))
      return o;
    return в;
  }

  E посети(ВыражениеМинус в)
  {
    if (auto o = findOverload(в, Идент.opSub, Идент.opSub_r))
      return o;
    return в;
  }

  E посети(ВыражениеСоедини в)
  {
    if (auto o = findOverload(в, Идент.opCat, Идент.opCat_r))
      return o;
    return в;
  }

  E посети(ВыражениеУмножь в)
  {
    if (auto o = findOverload(в, Идент.opMul, Идент.opMul_r))
      return o;
    return в;
  }

  E посети(ВыражениеДели в)
  {
    if (auto o = findOverload(в, Идент.opDiv, Идент.opDiv_r))
      return o;
    return в;
  }

  E посети(ВыражениеМод в)
  {
    if (auto o = findOverload(в, Идент.opMod, Идент.opMod_r))
      return o;
    return в;
  }

  E посети(ВыражениеПрисвой в)
  {
    if (auto o = findOverload(в, Идент.opAssign, null))
      return o;
    // TODO: also check for opIndexAssign and opSliceAssign.
    return в;
  }

  E посети(ВыражениеПрисвойЛСдвиг в)
  {
    if (auto o = findOverload(в, Идент.opShlAssign, null))
      return o;
    return в;
  }

  E посети(ВыражениеПрисвойПСдвиг в)
  {
    if (auto o = findOverload(в, Идент.opShrAssign, null))
      return o;
    return в;
  }

  E посети(ВыражениеПрисвойБПСдвиг в)
  {
    if (auto o = findOverload(в, Идент.opUShrAssign, null))
      return o;
    return в;
  }

  E посети(ВыражениеПрисвойИли в)
  {
    if (auto o = findOverload(в, Идент.opOrAssign, null))
      return o;
    return в;
  }

  E посети(ВыражениеПрисвойИ в)
  {
    if (auto o = findOverload(в, Идент.opAndAssign, null))
      return o;
    return в;
  }

  E посети(ВыражениеПрисвойПлюс в)
  {
    if (auto o = findOverload(в, Идент.opAddAssign, null))
      return o;
    return в;
  }

  E посети(ВыражениеПрисвойМинус в)
  {
    if (auto o = findOverload(в, Идент.opSubAssign, null))
      return o;
    return в;
  }

  E посети(ВыражениеПрисвойДел в)
  {
    auto o = findOverload(в, Идент.opDivAssign, null);
    if (o)
      return o;
    return в;
  }

  E посети(ВыражениеПрисвойУмн в)
  {
    auto o = findOverload(в, Идент.opMulAssign, null);
    if (o)
      return o;
    return в;
  }

  E посети(ВыражениеПрисвойМод в)
  {
    auto o = findOverload(в, Идент.opModAssign, null);
    if (o)
      return o;
    return в;
  }

  E посети(ВыражениеПрисвойИИли в)
  {
    auto o = findOverload(в, Идент.opXorAssign, null);
    if (o)
      return o;
    return в;
  }

  E посети(ВыражениеПрисвойСоед в)
  {
    auto o = findOverload(в, Идент.opCatAssign, null);
    if (o)
      return o;
    return в;
  }

  E посети(ВыражениеАдрес в)
  {
    if (в.естьТип)
      return в;
    в.в = посетиВ(в.в);
    в.тип = в.в.тип.укНа();
    return в;
  }

  E посети(ВыражениеПреИнкр в)
  {
    if (в.естьТип)
      return в;
    // TODO: rewrite в в+=1
    в.в = посетиВ(в.в);
    в.тип = в.в.тип;
    errorЕслиBool(в.в);
    return в;
  }

  E посети(ВыражениеПреДекр в)
  {
    if (в.естьТип)
      return в;
    // TODO: rewrite в в-=1
    в.в = посетиВ(в.в);
    в.тип = в.в.тип;
    errorЕслиBool(в.в);
    return в;
  }

  E посети(ВыражениеПостИнкр в)
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

  E посети(ВыражениеПостДекр в)
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

  E посети(ВыражениеДереф в)
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
        "dereference operator '*x' not defined for expression of тип '{}'",
        в.в.тип.вТкст());
      в.тип = Типы.Ошибка;
    }
    // TODO:
    // if (в.в.тип.isVoid)
    //   ошибка();
    return в;
  }

  E посети(ВыражениеЗнак в)
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

  E посети(ВыражениеНе в)
  {
    if (в.естьТип)
      return в;
    в.в = посетиВ(в.в);
    в.тип = Типы.Бул;
    // TODO: в.в must be convertible в бул.
    return в;
  }

  E посети(ВыражениеКомп в)
  {
    if (в.естьТип)
      return в;
    if (auto o = findOverload(в, Идент.opCom))
      return o;
    в.в = посетиВ(в.в);
    в.тип = в.в.тип;
    if (в.тип.плавающий_ли || в.тип.бул_ли)
    {
      ошибка(в.начало, "the operator '~x' is not defined for the тип '{}'", в.тип.вТкст());
      в.тип = Типы.Ошибка;
    }
    return в;
  }

  E посети(ВыражениеВызов в)
  {
    if (auto o = findOverload(в, Идент.opCall))
      return o;
    return в;
  }

  E посети(ВыражениеНов в)
  {
    return в;
  }

  E посети(ВыражениеНовАнонКласс в)
  {
    return в;
  }

  E посети(ВыражениеУдали в)
  {
    return в;
  }

  E посети(ВыражениеКаст в)
  {
    if (auto o = findOverload(в, Идент.opCast))
      return o;
    return в;
  }

  E посети(ВыражениеИндекс в)
  {
    if (auto o = findOverload(в, Идент.opIndex))
      return o;
    return в;
  }

  E посети(ВыражениеСрез в)
  {
    if (auto o = findOverload(в, Идент.opSlice))
      return o;
    return в;
  }

  E посети(ВыражениеТочка в)
  {
    if (в.естьТип)
      return в;
    бул resetIdScope = идМасштаб is null;
    // TODO:
    resetIdScope && (идМасштаб = null);
    return в;
  }

  E посети(ВыражениеМасштабМодуля в)
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

  E посети(ВыражениеИдентификатор в)
  {
    if (в.естьТип)
      return в;
    debug(sema) выдай.formatln("", в);
    auto идСема = в.идСема();
    в.символ = ищи(идСема);
    return в;
  }

  E посети(ВыражениеЭкземплярШаблона в)
  {
    if (в.естьТип)
      return в;
    debug(sema) выдай.formatln("", в);
    auto идСема = в.идСема();
    в.символ = ищи(идСема);
    return в;
  }

  E посети(ВыражениеСпецСема в)
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

  E посети(ВыражениеЭтот в)
  {
    return в;
  }

  E посети(ВыражениеСупер в)
  {
    return в;
  }

  E посети(ВыражениеНуль в)
  {
    if (!в.естьТип)
      в.тип = Типы.Проц_ук;
    return в;
  }

  E посети(ВыражениеДоллар в)
  {
    if (в.естьТип)
      return в;
    в.тип = Типы.Т_мера;
    // if (!inArraySubscript)
    //   ошибка("$ can only be in an массив subscript.");
    return в;
  }

  E посети(БулевоВыражение в)
  {
    assert(в.естьТип);
    return в.значение;
  }

  E посети(ЦелВыражение в)
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

  E посети(ВыражениеРеал в)
  {
    if (!в.естьТип)
      в.тип = Типы.Дво;
    return в;
  }

  E посети(ВыражениеКомплекс в)
  {
    if (!в.естьТип)
      в.тип = Типы.Кдво;
    return в;
  }

  E посети(ВыражениеСим в)
  {
    assert(в.естьТип);
    return в.значение;
  }

  E посети(ТекстовоеВыражение в)
  {
    assert(в.естьТип);
    return в;
  }

  E посети(ВыражениеЛитералМассива в)
  {
    return в;
  }

  E посети(ВыражениеЛитералАМассива в)
  {
    return в;
  }

  E посети(ВыражениеПодтверди в)
  {
    return в;
  }

  E посети(ВыражениеСмесь в)
  {
    return в;
  }

  E посети(ВыражениеИмпорта в)
  {
    return в;
  }

  E посети(ВыражениеТипа в)
  {
    return в;
  }

  E посети(ВыражениеИдТипаТочка в)
  {
    return в;
  }

  E посети(ВыражениеИдТипа в)
  {
    return в;
  }

  E посети(ВыражениеЯвляется в)
  {
    return в;
  }

  E посети(ВыражениеРодит в)
  {
    if (!в.естьТип)
    {
      в.следщ = посетиВ(в.следщ);
      в.тип = в.следщ.тип;
    }
    return в;
  }

  E посети(ВыражениеЛитералФункции в)
  {
    return в;
  }

  E посети(ВыражениеТрактовки в) // D2.0
  {
    return в;
  }

  E посети(ВыражениеИницПроц в)
  {
    return в;
  }

  E посети(ВыражениеИницМассива в)
  {
    return в;
  }

  E посети(ВыражениеИницСтрукуры в)
  {
    return в;
  }

  E посети(ВыражениеТипАсм в)
  {
    return в;
  }

  E посети(ВыражениеСмещениеАсм в)
  {
    return в;
  }

  E посети(ВыражениеСегАсм в)
  {
    return в;
  }

  E посети(ВыражениеАсмПослеСкобки в)
  {
    return в;
  }

  E посети(ВыражениеАсмСкобка в)
  {
    return в;
  }

  E посети(ВыражениеЛокальногоРазмераАсм в)
  {
    return в;
  }

  E посети(ВыражениеАсмРегистр в)
  {
    return в;
  }
} // override

  /+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  |                                   Типы                                   |
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+/

override
{
  T посети(НелегальныйТип)
  { assert(0, "semantic pass on invalid AST"); return null; }

  T посети(ИнтегральныйТип t)
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

  T посети(КвалифицированныйТип t)
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

  T посети(ТипМасштабаМодуля t)
  {
    идМасштаб = модуль;
    return t;
  }

  T посети(ТипИдентификатор t)
  {
    auto идСема = t.начало;
    auto символ = ищи(идСема);
    // TODO: save символ or its тип in t.
    return t;
  }

  T посети(ТипТипа t)
  {
    t.в = посетиВ(t.в);
    t.тип = t.в.тип;
    return t;
  }

  T посети(ТипЭкземплярШаблона t)
  {
    auto идСема = t.начало;
    auto символ = ищи(идСема);
    // TODO: save символ or its тип in t.
    return t;
  }

  T посети(ТипУказатель t)
  {
    t.тип = посетиТ(t.следщ).тип.укНа();
    return t;
  }

  T посети(ТипМассив t)
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

  T посети(ТипФункция t)
  {
    return t;
  }

  T посети(ТипДелегат t)
  {
    return t;
  }

  T посети(ТипУказателяНаФункСи t)
  {
    return t;
  }

  T посети(ТипКлассОснова t)
  {
    return t;
  }

  T посети(ТипКонст t) // D2.0
  {
    return t;
  }

  T посети(ТипИнвариант t) // D2.0
  {
    return t;
  }
} // override

  /+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  |                                 Параметры                                |
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~+/

override
{
  N посети(Параметр p)
  {
    return p;
  }

  N посети(Параметры p)
  {
    return p;
  }

  N посети(ПараметрАлиасШаблона p)
  {
    return p;
  }

  N посети(ПараметрТипаШаблона p)
  {
    return p;
  }

  N посети(ПараметрЭтотШаблона p) // D2.0
  {
    return p;
  }

  N посети(ПараметрШаблонЗначения p)
  {
    return p;
  }

  N посети(ПараметрКортежШаблона p)
  {
    return p;
  }

  N посети(ПараметрыШаблона p)
  {
    return p;
  }

  N посети(АргументыШаблона p)
  {
    return p;
  }
} // override
}
