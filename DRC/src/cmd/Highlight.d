/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity average)
module cmd.Highlight;

import drc.ast.DefaultVisitor,
       drc.ast.Node,
       drc.ast.Declaration,
       drc.ast.Statement,
       drc.ast.Expression,
       drc.ast.Types;
import drc.lexer.Lexer;
import drc.parser.Parser;
import drc.semantic.Module;
import drc.SourceText;
import drc.Diagnostics;
import SettingsLoader;
import Settings;
import common;

import tango.io.Buffer;
import tango.io.Print;
import tango.io.FilePath;

/// The highlight команда.
struct КомандаВыделить
{
  /// Опции for the команда.
  enum Опция
  {
    Нет        = 0,
    Токены      = 1,
    Синтаксис      = 1<<1,
    ГЯР        = 1<<2,
    РЯР         = 1<<3,
    ВыводСтрок  = 1<<4
  }
  alias Опция Опции;

  Опции опции; /// команда опции.
  ткст путьКФайлу; /// File путь в the module в be highlighted.
  Диагностика диаг;

  /// Adds o в the опции.
  проц  добавь(Опция o)
  {
    опции |= o;
  }

  /// Executes the команда.
  проц  пуск()
  {
    добавь(КомандаВыделить.Опция.Токены);
    if (!(опции & (Опция.РЯР | Опция.ГЯР)))
      добавь(Опция.РЯР); // Дефолт в РЯР.

    auto mapFilePath = опции & Опция.ГЯР ? ГлобальныеНастройки.файлКартыГЯР
                                             : ГлобальныеНастройки.файлКартыРЯР;
    auto карта = ЗагрузчикКартыТегов(диаг).загрузи(mapFilePath);
    auto tags = new КартаТегов(карта);

    if (диаг.естьИнфо_ли)
      return;

    if (опции & Опция.Синтаксис)
      highlightSyntax(путьКФайлу, tags, выдай, опции);
    else
      highlightTokens(путьКФайлу, tags, выдай, опции);
  }
}

/// Escapes the characters '<', '>' and '&' with named character entities.
сим[] xml_escape(сим[] текст)
{
  сим[] результат;
  foreach(c; текст)
    switch(c)
    {
      case '<': результат ~= "&lt;";  break;
      case '>': результат ~= "&gt;";  break;
      case '&': результат ~= "&amp;"; break;
      default:  результат ~= c;
    }
  if (результат.length != текст.length)
    return результат;
  // Nothing escaped. Итог original текст.
  delete результат;
  return текст;
}

/// Maps семы в (format) тксты.
class КартаТегов
{
  ткст[ткст] таблица;
  ткст[TOK.МАКС] tokenTable;

  this(ткст[ткст] таблица)
  {
    this.таблица = таблица;
    Идентификатор   = this["Идентификатор", "{0}"];
    Ткст       = this["Ткст", "{0}"];
    Сим         = this["Сим", "{0}"];
    Число       = this["Число", "{0}"];
    КСлово      = this["КСлово", "{0}"];
    LineC        = this["LineC", "{0}"];
    BlockC       = this["BlockC", "{0}"];
    NestedC      = this["NestedC", "{0}"];
    Шебанг      = this["Шебанг", "{0}"];
    HLine        = this["HLine", "{0}"];
    Filespec     = this["Filespec", "{0}"];
    Нелегал      = this["Нелегал", "{0}"];
    Новстр      = this["НовСтр", "{0}"];
    ОсобаяСема = this["ОсобаяСема", "{0}"];
    Декларация  = this["Декларация", "d"];
    Инструкция    = this["Инструкция", "s"];
    Выражение   = this["Выражение", "в"];
    Тип         = this["Тип", "t"];
    Иное        = this["Иное", "o"];
    КФ          = this["КФ", ""];

    foreach (i, tokStr; семаВТкст)
      if (auto pStr = tokStr in this.таблица)
        tokenTable[i] = *pStr;
  }

  /// Returns the значение for ткт, or 'fallback' if ткт is not in the таблица.
  ткст opIndex(ткст ткт, ткст fallback = "")
  {
    auto p = ткт in таблица;
    if (p)
      return *p;
    return fallback;
  }

  /// Returns the значение for лекс in O(1) время.
  ткст opIndex(TOK лекс)
  {
    return tokenTable[лекс];
  }

  /// Shortcuts for quick access.
  ткст Идентификатор, Ткст, Сим, Число, КСлово, LineC, BlockC,
         NestedC, Шебанг, HLine, Filespec, Нелегал, Новстр, ОсобаяСема,
         Декларация, Инструкция, Выражение, Тип, Иное, КФ;

  /// Returns the tag for the категория 'nc'.
  ткст getTag(КатегорияУзла nc)
  {
    ткст tag;
    switch (nc)
    { alias КатегорияУзла NC;
    case NC.Декларация: tag = Декларация; break;
    case NC.Инструкция:   tag = Инструкция; break;
    case NC.Выражение:  tag = Выражение; break;
    case NC.Тип:        tag = Тип; break;
    case NC.Иное:       tag = Иное; break;
    default: assert(0);
    }
    return tag;
  }
}

/// Find the last occurrence of object in subject.
/// Возвращает: the индекс if found, or -1 if not.
цел rfind(сим[] subject, сим object)
{
  foreach_reverse(i, c; subject)
    if (c == object)
      return i;
  return -1;
}

/// Returns the крат class имя of a class descending из Узел.$(BR)
/// E.g.: drc.ast.Declarations.ДекларацияКласса -> Класс
сим[] getShortClassName(Узел узел)
{
  static сим[][] name_table;
  if (name_table is null)
    name_table = new сим[][ВидУзла.max+1]; // Create a new таблица.
  // Look up in таблица.
  сим[] имя = name_table[узел.вид];
  if (имя !is null)
    return имя; // Итог cached имя.

  имя = узел.classinfo.name; // Get the fully qualified имя of the class.
  имя = имя[rfind(имя, '.')+1 .. $]; // Remove package and module имя.

  бцел suffixLength;
  switch (узел.категория)
  {
  alias КатегорияУзла NC;
  case NC.Декларация:
    suffixLength = "Декларация".length;
    break;
  case NC.Инструкция:
    suffixLength = "Инструкция".length;
    break;
  case NC.Выражение:
    suffixLength = "Выражение".length;
    break;
  case NC.Тип:
    suffixLength = "Тип".length;
    break;
  case NC.Иное:
    break;
  default:
    assert(0);
  }
  // Remove common suffix.
  имя = имя[0 .. $ - suffixLength];
  // Store the имя in the таблица.
  name_table[узел.вид] = имя;
  return имя;
}

/// Extended сема structure.
struct TokenEx
{
  Сема* сема; /// The лексер сема.
  Узел[] beginNodes; /// beginNodes[n].начало == сема
  Узел[] endNodes; /// endNodes[n].конец == сема
}

/// Builds an массив of TokenEx элементы.
class TokenExBuilder : ДефолтныйВизитёр
{
  private TokenEx*[Сема*] tokenTable;

  TokenEx[] build(Узел корень, Сема* first)
  {
    auto сема = first;

    бцел счёт; // Count семы.
    for (; сема; сема = сема.следщ)
      счёт++;
    // Creat the exact число of TokenEx instances.
    auto toks = new TokenEx[счёт];
    сема = first;
    foreach (ref tokEx; toks)
    {
      tokEx.сема = сема;
      if (!сема.пробел_ли)
        tokenTable[сема] = &tokEx;
      сема = сема.следщ;
    }

    super.посетиУ(корень);
    tokenTable = null;
    return toks;
  }

  TokenEx* getTokenEx()(Сема* t)
  {
    auto p = t in tokenTable;
    assert(p, t.исхТекст~" is not in tokenTable");
    return *p;
  }

  // Перепись отправь function.
  override Узел отправь(Узел n)
  { assert(n !is null);
    auto начало = n.начало;
    if (начало)
    { assert(n.конец);
      auto txbegin = getTokenEx(начало);
      auto txend = getTokenEx(n.конец);
      txbegin.beginNodes ~= n;
      txend.endNodes ~= n;
    }
    return super.отправь(n);
  }
}

проц  выведиОшибки(Лексер lx, КартаТегов tags, Print print)
{
  foreach (в; lx.ошибки)
    print.format(tags["ОшибкаЛексера"], в.путьКФайлу, в.место, в.столб, xml_escape(в.дайСооб));
}

проц  выведиОшибки(Парсер парсер, КартаТегов tags, Print print)
{
  foreach (в; парсер.ошибки)
    print.format(tags["ОшибкаПарсера"], в.путьКФайлу, в.место, в.столб, xml_escape(в.дайСооб));
}

проц  printLines(бцел lines, КартаТегов tags, Print print)
{
  auto lineNumberFormat = tags["НомерСтроки"];
  for (auto номСтр = 1; номСтр <= lines; номСтр++)
    print.format(lineNumberFormat, номСтр);
}

/// Highlights the syntax in a source file.
проц  highlightSyntax(ткст путьКФайлу, КартаТегов tags,
                     Print print,
                     КомандаВыделить.Опции опции)
{
  auto парсер = new Парсер(new ИсходныйТекст(путьКФайлу, да));
  auto корень = парсер.старт();
  auto lx = парсер.лексер;

  auto builder = new TokenExBuilder();
  auto tokenExList = builder.build(корень, lx.перваяСема());

  print.format(tags["ЗаголовокДок"], (new FilePath(путьКФайлу)).name());
  if (lx.ошибки.length || парсер.ошибки.length)
  { // Output ошибка сообщения.
    print(tags["НачалоКомп"]);
    выведиОшибки(lx, tags, print);
    выведиОшибки(парсер, tags, print);
    print(tags["КонецКомп"]);
  }

  if (опции & КомандаВыделить.Опция.ВыводСтрок)
  {
    print(tags["НачалоНомераСтроки"]);
    printLines(lx.номСтр, tags, print);
    print(tags["КонецНомераСтроки"]);
  }

  print(tags["НачалоИсходника"]);

  auto tagNodeBegin = tags["НачалоУзла"];
  auto tagNodeEnd = tags["КонецУзла"];

  // Iterate over список of семы.
  foreach (ref tokenEx; tokenExList)
  {
    auto сема = tokenEx.сема;

    сема.пп && print(сема.пробСимволы); // Print preceding whitespace.
    if (сема.пробел_ли) {
      printToken(сема, tags, print);
      continue;
    }
    // <узел>
    foreach (узел; tokenEx.beginNodes)
      print.format(tagNodeBegin, tags.getTag(узел.категория), getShortClassName(узел));
    // Сема текст.
    printToken(сема, tags, print);
    // </узел>
    if (опции & КомандаВыделить.Опция.ГЯР)
      foreach_reverse (узел; tokenEx.endNodes)
        print(tagNodeEnd);
    else
      foreach_reverse (узел; tokenEx.endNodes)
        print.format(tagNodeEnd, tags.getTag(узел.категория));
  }
  print(tags["КонецИсходника"]);
  print(tags["КонецДок"]);
}

/// Highlights all семы of a source file.
проц  highlightTokens(ткст путьКФайлу, КартаТегов tags,
                     Print print,
                     КомандаВыделить.Опции опции)
{
  auto lx = new Лексер(new ИсходныйТекст(путьКФайлу, да));
  lx.сканируйВсе();

  print.format(tags["ЗаголовокДок"], (new FilePath(путьКФайлу)).name());
  if (lx.ошибки.length)
  {
    print(tags["НачалоКомп"]);
    выведиОшибки(lx, tags, print);
    print(tags["КонецКомп"]);
  }

  if (опции & КомандаВыделить.Опция.ВыводСтрок)
  {
    print(tags["НачалоНомераСтроки"]);
    printLines(lx.номСтр, tags, print);
    print(tags["КонецНомераСтроки"]);
  }

  print(tags["НачалоИсходника"]);
  // Traverse linked список and print семы.
  for (auto сема = lx.перваяСема(); сема; сема = сема.следщ) {
    сема.пп && print(сема.пробСимволы); // Print preceding whitespace.
    printToken(сема, tags, print);
  }
  print(tags["КонецИсходника"]);
  print(tags["КонецДок"]);
}

/// A сема highlighter designed for DDoc.
class ПодсветчикСем
{
  КартаТегов tags;
  this(Диагностика диаг, бул useHTML = да)
  {
    ткст путьКФайлу = ГлобальныеНастройки.файлКартыГЯР;
    if (!useHTML)
      путьКФайлу = ГлобальныеНастройки.файлКартыРЯР;
    auto карта = ЗагрузчикКартыТегов(диаг).загрузи(путьКФайлу);
    tags = new КартаТегов(карта);
  }

  /// Highlights семы in a DDoc код раздел.
  /// Возвращает: a ткст with the highlighted семы (in ГЯР tags.)
  ткст highlight(ткст текст, ткст путьКФайлу)
  {
    auto буфер = new GrowBuffer(текст.length);
    auto print = new Print(Формат, буфер);

    auto lx = new Лексер(new ИсходныйТекст(путьКФайлу, текст));
    lx.сканируйВсе();

    // Traverse linked список and print семы.
    print("$(D_CODE\n");
    if (lx.ошибки.length)
    { // Output ошибка сообщения.
      // FIXME: CompBegin and CompEnd break the таблица layout.
//       print(tags["НачалоКомп"]);
      выведиОшибки(lx, tags, print);
//       print(tags["КонецКомп"]);
    }
    // Traverse linked список and print семы.
    for (auto сема = lx.перваяСема(); сема; сема = сема.следщ) {
      сема.пп && print(сема.пробСимволы); // Print preceding whitespace.
      printToken(сема, tags, print);
    }
    print("\n)");
    return cast(сим[])буфер.slice();
  }
}

/// Prints a сема в the тктeam print.
проц  printToken(Сема* сема, КартаТегов tags, Print print)
{
  switch(сема.вид)
  {
  case TOK.Идентификатор:
    print.format(tags.Идентификатор, сема.исхТекст);
    break;
  case TOK.Комментарий:
    ткст formatStr;
    switch (сема.старт[1])
    {
    case '/': formatStr = tags.LineC; break;
    case '*': formatStr = tags.BlockC; break;
    case '+': formatStr = tags.NestedC; break;
    default: assert(0);
    }
    print.format(formatStr, xml_escape(сема.исхТекст));
    break;
  case TOK.Ткст:
    print.format(tags.Ткст, xml_escape(сема.исхТекст));
    break;
  case TOK.СимЛитерал:
    print.format(tags.Сим, xml_escape(сема.исхТекст));
    break;
  case TOK.Цел32, TOK.Цел64, TOK.Бцел32, TOK.Бцел64,
       TOK.Плав32, TOK.Плав64, TOK.Плав80,
       TOK.Мнимое32, TOK.Мнимое64, TOK.Мнимое80:
    print.format(tags.Число, сема.исхТекст);
    break;
  case TOK.Шебанг:
    print.format(tags.Шебанг, xml_escape(сема.исхТекст));
    break;
  case TOK.HashLine:
    auto formatStr = tags.HLine;
    // The текст в be inserted into formatStr.
    auto буфер = new GrowBuffer;
    auto print2 = new Print(Формат, буфер);

    проц  printWS(сим* старт, сим* конец)
    {
      старт != конец && print2(старт[0 .. конец - старт]);
    }

    auto чис = сема.tokLineNum;
    if (чис is null)
    { // Malformed #line
      print.format(formatStr, сема.исхТекст);
      break;
    }

    // Print whitespace between #line and число.
    printWS(сема.старт, чис.старт); // Prints "#line" as well.
    printToken(чис, tags, print2); // Print the число.

    if (auto filespec = сема.tokLineFilespec)
    { // Print whitespace between число and filespec.
      printWS(чис.конец, filespec.старт);
      print2.format(tags.Filespec, xml_escape(filespec.исхТекст));
    }
    // Finally print the whole сема.
    print.format(formatStr, cast(сим[])буфер.slice());
    break;
  case TOK.Нелегал:
    print.format(tags.Нелегал, сема.исхТекст());
    break;
  case TOK.Новстр:
    print.format(tags.Новстр, сема.исхТекст());
    break;
  case TOK.КФ:
    print(tags.КФ);
    break;
  default:
    if (сема.кслово_ли())
      print.format(tags.КСлово, сема.исхТекст);
    else if (сема.спецСема_ли)
      print.format(tags.ОсобаяСема, сема.исхТекст);
    else
      print(tags[сема.вид]);
  }
}
