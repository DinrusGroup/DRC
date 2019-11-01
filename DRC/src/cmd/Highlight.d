/// Author: Aziz Köksal, Vitaly Kulich
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

import io.Buffer;
import io.FilePath;
import io.stream.Format;

public alias ФормВывод!(сим) Print;
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
  ткст путьКФайлу; /// Файл путь в the module в be highlighted.
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
    auto тэги = new КартаТегов(карта);

    if (диаг.естьИнфо)
      return;

    if (опции & Опция.Синтаксис)
      highlightSyntax(путьКФайлу, тэги, выдай, опции);
    else
      highlightTokens(путьКФайлу, тэги, выдай, опции);
  }
}

/// Escapes the characters '<', '>' and '&' with Имяd символ entities.
ткст xml_escape(ткст текст)
{
  ткст результат;
  foreach(с; текст)
    switch(с)
    {
      case '<': результат ~= "&тк;";  break;
      case '>': результат ~= "&gt;";  break;
      case '&': результат ~= "&amp;"; break;
      default:  результат ~= с;
    }
  if (результат.length != текст.length)
    return результат;
  // Nothing escaped. Итог илиiginal текст.
  delete результат;
  return текст;
}

/// Maps семы в (форматируй) тксты.
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
    Файлспец     = this["Файлспец", "{0}"];
    Нелегал      = this["Нелегал", "{0}"];
    Новстр      = this["НовСтр", "{0}"];
    ОсобаяСема = this["ОсобаяСема", "{0}"];
    Декларация  = this["Декларация", "d"];
    Инструкция    = this["Инструкция", "s"];
    Выражение   = this["Выражение", "в"];
    Тип         = this["Тип", "т"];
    Иное        = this["Иное", "o"];
    КФ          = this["КФ", ""];

    foreach (i, tokStr; семаВТкст)
      if (auto pStr = tokStr in this.таблица)
        tokenTable[i] = *pStr;
  }

  /// Возвращает значение for ткт, или 'fallback' if ткт is not in the таблица.
  ткст opIndex(ткст ткт, ткст fallback = "")
  {
    auto у = ткт in таблица;
    if (у)
      return *у;
    return fallback;
  }

  /// Возвращает значение for лекс in O(1) время.
  ткст opIndex(TOK лекс)
  {
    return tokenTable[лекс];
  }

  /// Shилиtcuts for quick access.
  ткст Идентификатор, Ткст, Сим, Число, КСлово, LineC, BlockC,
         NestedC, Шебанг, HLine, Файлспец, Нелегал, Новстр, ОсобаяСема,
         Декларация, Инструкция, Выражение, Тип, Иное, КФ;

  /// Возвращает тэг for the категория 'nc'.
  ткст дайТэг(КатегорияУзла nc)
  {
    ткст тэг;
    switch (nc)
    { alias КатегорияУзла NC;
    case NC.Декларация: тэг = Декларация; break;
    case NC.Инструкция:   тэг = Инструкция; break;
    case NC.Выражение:  тэг = Выражение; break;
    case NC.Тип:        тэг = Тип; break;
    case NC.Иное:       тэг = Иное; break;
    default: assert(0);
    }
    return тэг;
  }
}

/// Find the last occurrence of объект in субъект.
/// Возвращает: the индекс if found, или -1 if not.
цел rfind(ткст субъект, сим объект)
{
  foreach_reverse(i, с; субъект)
    if (с == объект)
      return i;
  return -1;
}

/// Возвращает крат class имя of a class descending из Узел.$(BR)
/// Напр.: drc.ast.Declarations.ДекларацияКласса -> Класс
ткст дайКраткоеИмяКласса(Узел узел)
{
  static сим[][] Имя_table;
  if (Имя_table is пусто)
    Имя_table = new сим[][ВидУзла.max+1]; // Create a new таблица.
  // Look up in таблица.
  ткст имя = Имя_table[узел.вид];
  if (имя !is пусто)
    return имя; // Итог cached имя.

  имя = узел.classinfo.имя; // Get the fully qualified имя of the class.
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
  // Remove common суффикс.
  имя = имя[0 .. $ - suffixLength];
  // Stилиe the имя in the таблица.
  Имя_table[узел.вид] = имя;
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
      if (!сема.пробел)
        tokenTable[сема] = &tokEx;
      сема = сема.следщ;
    }

    super.посетиУ(корень);
    tokenTable = пусто;
    return toks;
  }

  TokenEx* getTokenEx()(Сема* т)
  {
    auto у = т in tokenTable;
    assert(у, т.исхТекст~" is not in tokenTable");
    return *у;
  }

  // Перепись отправь function.
  override Узел отправь(Узел n)
  { assert(n !is пусто);
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

проц  выведиОшибки(Лексер lx, КартаТегов тэги, Print print)
{
  foreach (в; lx.ошибки)
    print.форматируй(тэги["ОшибкаЛексера"], в.путьКФайлу, в.место, в.столб, xml_escape(в.дайСооб));
}

проц  выведиОшибки(Парсер парсер, КартаТегов тэги, Print print)
{
  foreach (в; парсер.ошибки)
    print.форматируй(тэги["ОшибкаПарсера"], в.путьКФайлу, в.место, в.столб, xml_escape(в.дайСооб));
}

проц  printLines(бцел lines, КартаТегов тэги, Print print)
{
  auto lineNumberFилиmat = тэги["НомерСтроки"];
  for (auto номерСтроки = 1; номерСтроки <= lines; номерСтроки++)
    print.форматируй(lineNumberFилиmat, номерСтроки);
}

/// Highlights the syntax in a source file.
проц  highlightSyntax(ткст путьКФайлу, КартаТегов тэги,
                     Print print,
                     КомандаВыделить.Опции опции)
{
  auto парсер = new Парсер(new ИсходныйТекст(путьКФайлу, да));
  auto корень = парсер.старт();
  auto lx = парсер.лексер;

  auto builder = new TokenExBuilder();
  auto tokenExList = builder.build(корень, lx.перваяСема());

  print.форматируй(тэги["ЗаголовокДок"], (new ФПуть(путьКФайлу)).имя());
  if (lx.ошибки.length || парсер.ошибки.length)
  { // Output ошибка сообщения.
    print(тэги["НачалоКомп"]);
    выведиОшибки(lx, тэги, print);
    выведиОшибки(парсер, тэги, print);
    print(тэги["КонецКомп"]);
  }

  if (опции & КомандаВыделить.Опция.ВыводСтрок)
  {
    print(тэги["НачалоНомераСтроки"]);
    printLines(lx.номерСтроки, тэги, print);
    print(тэги["КонецНомераСтроки"]);
  }

  print(тэги["НачалоИсходника"]);

  auto tagNodeBegin = тэги["НачалоУзла"];
  auto tagNodeEnd = тэги["КонецУзла"];

  // Iterate over список of семы.
  foreach (ref tokenEx; tokenExList)
  {
    auto сема = tokenEx.сема;

    сема.пп && print(сема.пробСимволы); // Print preceding whitespace.
    if (сема.пробел) {
      printToken(сема, тэги, print);
      continue;
    }
    // <узел>
    foreach (узел; tokenEx.beginNodes)
      print.форматируй(tagNodeBegin, тэги.дайТэг(узел.категория), дайКраткоеИмяКласса(узел));
    // Сема текст.
    printToken(сема, тэги, print);
    // </узел>
    if (опции & КомандаВыделить.Опция.ГЯР)
      foreach_reverse (узел; tokenEx.endNodes)
        print(tagNodeEnd);
    else
      foreach_reverse (узел; tokenEx.endNodes)
        print.форматируй(tagNodeEnd, тэги.дайТэг(узел.категория));
  }
  print(тэги["КонецИсходника"]);
  print(тэги["КонецДок"]);
}

/// Highlights all семы of a source file.
проц  highlightTokens(ткст путьКФайлу, КартаТегов тэги,
                     Print print,
                     КомандаВыделить.Опции опции)
{
  auto lx = new Лексер(new ИсходныйТекст(путьКФайлу, да));
  lx.сканируйВсе();

  print.форматируй(тэги["ЗаголовокДок"], (new ФПуть(путьКФайлу)).имя());
  if (lx.ошибки.length)
  {
    print(тэги["НачалоКомп"]);
    выведиОшибки(lx, тэги, print);
    print(тэги["КонецКомп"]);
  }

  if (опции & КомандаВыделить.Опция.ВыводСтрок)
  {
    print(тэги["НачалоНомераСтроки"]);
    printLines(lx.номерСтроки, тэги, print);
    print(тэги["КонецНомераСтроки"]);
  }

  print(тэги["НачалоИсходника"]);
  // Traverse linked список and print семы.
  for (auto сема = lx.перваяСема(); сема; сема = сема.следщ) {
    сема.пп && print(сема.пробСимволы); // Print preceding whitespace.
    printToken(сема, тэги, print);
  }
  print(тэги["КонецИсходника"]);
  print(тэги["КонецДок"]);
}

/// A сема highlighter designed for DDoc.
class ПодсветчикСем
{
  КартаТегов тэги;
  this(Диагностика диаг, бул useHTML = да)
  {
    ткст путьКФайлу = ГлобальныеНастройки.файлКартыГЯР;
    if (!useHTML)
      путьКФайлу = ГлобальныеНастройки.файлКартыРЯР;
    auto карта = ЗагрузчикКартыТегов(диаг).загрузи(путьКФайлу);
    тэги = new КартаТегов(карта);
  }

  /// Highlights семы in a DDoc код раздел.
  /// Возвращает: a ткст with the highlighted семы (in ГЯР тэги.)
  ткст highlight(ткст текст, ткст путьКФайлу)
  {
    auto буфер = объБуферРоста(текст.length);
    auto print = new Print(Формат, буфер);

    auto lx = new Лексер(new ИсходныйТекст(путьКФайлу, текст));
    lx.сканируйВсе();

    // Traverse linked список and print семы.
    print("$(D_Код\n");
    if (lx.ошибки.length)
    { // Output ошибка сообщения.
      // FIXME: CompBegin and CompEnd break the таблица layout.
//       print(тэги["НачалоКомп"]);
      выведиОшибки(lx, тэги, print);
//       print(тэги["КонецКомп"]);
    }
    // Traverse linked список and print семы.
    for (auto сема = lx.перваяСема(); сема; сема = сема.следщ) {
      сема.пп && print(сема.пробСимволы); // Print preceding whitespace.
      printToken(сема, тэги, print);
    }
    print("\n)");
    return cast(сим[])буфер.срез();
  }
}

/// Prints a сема в the тктeam print.
проц  printToken(Сема* сема, КартаТегов тэги, Print print)
{
  switch(сема.вид)
  {
  case TOK.Идентификатор:
    print.форматируй(тэги.Идентификатор, сема.исхТекст);
    break;
  case TOK.Комментарий:
    ткст formatStr;
    switch (сема.старт[1])
    {
    case '/': formatStr = тэги.LineC; break;
    case '*': formatStr = тэги.BlockC; break;
    case '+': formatStr = тэги.NestedC; break;
    default: assert(0);
    }
    print.форматируй(formatStr, xml_escape(сема.исхТекст));
    break;
  case TOK.Ткст:
    print.форматируй(тэги.Ткст, xml_escape(сема.исхТекст));
    break;
  case TOK.СимЛитерал:
    print.форматируй(тэги.Сим, xml_escape(сема.исхТекст));
    break;
  case TOK.Цел32, TOK.Цел64, TOK.Бцел32, TOK.Бцел64,
       TOK.Плав32, TOK.Плав64, TOK.Плав80,
       TOK.Мнимое32, TOK.Мнимое64, TOK.Мнимое80:
    print.форматируй(тэги.Число, сема.исхТекст);
    break;
  case TOK.Шебанг:
    print.форматируй(тэги.Шебанг, xml_escape(сема.исхТекст));
    break;
  case TOK.ХэшСтрочка:
    auto formatStr = тэги.HLine;
    // The текст в be inserted into formatStr.
    auto буфер = объБуферРоста;
    auto print2 = new Print(Формат, буфер);

    проц  выводитьШС(сим* старт, сим* конец)
    {
      старт != конец && print2(старт[0 .. конец - старт]);
    }

    auto чис = сема.номСтрокиСем;
    if (чис is пусто)
    { // Malfилиmed #line
      print.форматируй(formatStr, сема.исхТекст);
      break;
    }

    // Print whitespace between #line and число.
    выводитьШС(сема.старт, чис.старт); // Prints "#line" также.
    printToken(чис, тэги, print2); // Print the число.

    if (auto filespec = сема.семаФайлспецСтроки)
    { // Print whitespace between число and filespec.
      выводитьШС(чис.конец, filespec.старт);
      print2.форматируй(тэги.Файлспец, xml_escape(filespec.исхТекст));
    }
    // ВИтоге print the whole сема.
    print.форматируй(formatStr, cast(сим[])буфер.срез());
    break;
  case TOK.Нелегал:
    print.форматируй(тэги.Нелегал, сема.исхТекст());
    break;
  case TOK.Новстр:
    print.форматируй(тэги.Новстр, сема.исхТекст());
    break;
  case TOK.КФ:
    print(тэги.КФ);
    break;
  default:
    if (сема.кслово())
      print.форматируй(тэги.КСлово, сема.исхТекст);
    else if (сема.спецСема)
      print.форматируй(тэги.ОсобаяСема, сема.исхТекст);
    else
      print(тэги[сема.вид]);
  }
}
