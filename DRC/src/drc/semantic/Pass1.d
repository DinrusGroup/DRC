/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity low)
module drc.semantic.Pass1;

import  drc.ast.Visitor,
       drc.ast.Node,
       drc.ast.Declarations,
       drc.ast.Expressions,
       drc.ast.Statements,
       drc.ast.Types,
       drc.ast.Parameters;
import drc.lexer.IdTable;
import drc.semantic.Symbol,
       drc.semantic.Symbols,
       drc.semantic.Types,
       drc.semantic.Scope,
       drc.semantic.Module,
       drc.semantic.Analysis;
import drc.Compilation;
import drc.Diagnostics;
import drc.Messages;
import drc.Enums;
import drc.CompilerInfo;
import common;

import tango.io.model.IFile;
alias FileConst.PathSeparatorChar папРазд;

/// The first pass is the declaration pass.
///
/// The basic task of this class is в traverse the разбор tree,
/// find all kinds of declarations and добавь them
/// в the символ tables of their respective scopes.
class СемантическаяПроходка1 : Визитёр
{
  Масштаб масш; /// The current Масштаб.
  Модуль модуль; /// The module в be semantically checked.
  КонтекстКомпиляции контекст; /// The compilation контекст.
  Модуль delegate(ткст) импортируйМодуль; /// Called when importing a module.

  // Attributes:
  ТипКомпоновки типКомпоновки; /// Current linkage тип.
  Защита защита; /// Current защита attribute.
  КлассХранения классХранения; /// Current storage classes.
  бцел размерРаскладки; /// Current align размер.

  /// Constructs a СемантическаяПроходка1 object.
  /// Параметры:
  ///   модуль = the module в be processed.
  ///   контекст = the compilation контекст.
  this(Модуль модуль, КонтекстКомпиляции контекст)
  {
    this.модуль = модуль;
    this.контекст = new КонтекстКомпиляции(контекст);
    this.размерРаскладки = контекст.раскладкаСтруктуры;
  }

  /// Starts processing the module.
  проц  пуск()
  {
    assert(модуль.корень !is null);
    // Create module Масштаб.
    масш = new Масштаб(null, модуль);
    модуль.семантическийПроходка = 1;
    посети(модуль.корень);
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

  /// Creates an ошибка report.
  проц  ошибка(Сема* сема, сим[] форматирСооб, ...)
  {
    if (!модуль.диаг)
      return;
    auto положение = сема.дайПоложениеОшибки();
    auto сооб = Формат(_arguments, _argptr, форматирСооб);
    модуль.диаг ~= new ОшибкаСемантики(положение, сооб);
  }


  /// Collects инфо about nodes which have в be evaluated later.
  static class Иной
  {
    Узел узел;
    СимволМасштаба символ;
    // Saved attributes.
    ТипКомпоновки типКомпоновки;
    Защита защита;
    КлассХранения классХранения;
    бцел размерРаскладки;
  }

  /// List of mixin, static if, static assert and pragma(сооб,...) declarations.
  ///
  /// Their analysis must be deferred because they entail
  /// оцениuation of expressions.
  Иной[] deferred;

  /// Adds a deferred узел в the список.
  проц  добавьИной(Узел узел)
  {
    auto d = new Иной;
    d.узел = узел;
    d.символ = масш.символ;
    d.типКомпоновки = типКомпоновки;
    d.защита = защита;
    d.классХранения = классХранения;
    d.размерРаскладки = размерРаскладки;
    deferred ~= d;
  }

  private alias Декларация D; /// A handy alias. Saves typing.

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

  // Иной declarations:

  D посети(ДекларацияСтатическогоПодтверди d)
  {
    добавьИной(d);
    return d;
  }

  D посети(ДекларацияСтатическогоЕсли d)
  {
    добавьИной(d);
    return d;
  }

  D посети(ДекларацияСмеси d)
  {
    добавьИной(d);
    return d;
  }

  D посети(ДекларацияПрагмы d)
  {
    if (d.идент is Идент.сооб)
      добавьИной(d);
    else
    {
      семантикаПрагмы(масш, d.начало, d.идент, d.арги);
      посетиД(d.деклы);
    }
    return d;
  }
} // override
}
