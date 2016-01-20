/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.doc.Macro;

import drc.doc.Parser;
import drc.lexer.Funcs;
import drc.Unicode;
import drc.Diagnostics;
import drc.Messages;
import common;

/// The DDoc macro class.
class Макрос
{
  ткст имя; /// The имя of the macro.
  ткст текст; /// The substitution текст.
  бцел callLevel;  /// Recursive call уровень.
  /// Constructs a Макрос object.
  this (ткст имя, ткст текст)
  {
    this.имя = имя;
    this.текст = текст;
  }
}

/// Maps macro имена в Макрос objects.
///
/// ТаблицаМакросовs can be chained so that they build a linear hierarchy.
/// Макрос definitions in the current таблица override the ones in the родитель tables.
class ТаблицаМакросов
{
  /// The родитель in the hierarchy. Or null if this is the корень.
  ТаблицаМакросов родитель;
  Макрос[ткст] таблица; /// The associative массив that holds the macro definitions.

  /// Constructs a ТаблицаМакросов instance.
  this(ТаблицаМакросов родитель = null)
  {
    this.родитель = родитель;
  }

  /// Inserts the macro m into the таблица.
  /// Overwrites the current macro if one exists.
  проц  вставь(Макрос m)
  {
    таблица[m.имя] = m;
  }

  /// Inserts an массив of макрос into the таблица.
  проц  вставь(Макрос[] макрос)
  {
    foreach (m; макрос)
      вставь(m);
  }

  /// Creates a macro using имя and текст and inserts that into the таблица.
  проц  вставь(ткст имя, ткст текст)
  {
    вставь(new Макрос(имя, текст));
  }

  /// Creates a macro using имя[n] and текст[n] and inserts that into the таблица.
  проц  вставь(ткст[] имена, ткст[] тексты)
  {
    assert(имена.length == тексты.length);
    foreach (i, имя; имена)
      вставь(имя, тексты[i]);
  }

  /// Searches for a macro.
  ///
  /// Если the macro isn't found in this таблица the ищи
  /// continues upwards in the таблица hierarchy.
  /// Возвращает: the macro if found, or null if not.
  Макрос ищи(ткст имя)
  {
    auto pmacro = имя in таблица;
    if (pmacro)
      return *pmacro;
    if (!корень_ли())
      return родитель.ищи(имя);
    return null;
  }

  /// Возвращает: да if this is the корень of the hierarchy.
  бул корень_ли()
  { return родитель is null; }
}

/// Parses a текст with macro definitions.
struct ПарсерМакросов
{
  Макрос[] разбор(ткст текст)
  {
    ПарсерЗначенияИдентификатора парсер;
    auto идзначения = парсер.разбор(текст);
    auto макрос = new Макрос[идзначения.length];
    foreach (i, идзначение; идзначения)
      макрос[i] = new Макрос(идзначение.идент, идзначение.значение);
    return макрос;
  }

  /// Scans for a macro invocation. E.g.: &#36;(DDOC)
  /// Возвращает: a pointer установи в one сим past the закрывающий parenthesis,
  /// or null if this isn't a macro invocation.
  static сим* сканируйМакрос(сим* p, сим* конецТекста)
  {
    assert(*p == '$');
    if (p+2 < конецТекста && p[1] == '(')
    {
      p += 2;
      if (сканируйИдентификатор(p, конецТекста))
      {
        РаскрывательМакросов.сканируйАргументы(p, конецТекста);
        p != конецТекста && p++; // Skip ')'.
        return p;
      }
    }
    return null;
  }
}

/// Expands DDoc макрос in a текст.
struct РаскрывательМакросов
{
  ТаблицаМакросов мтаблица; /// Used в look up макрос.
  Диагностика диаг; /// Collects предупреждение сообщения.
  сим[] путьКФайлу; /// Used in предупреждение сообщения.

  /// Starts expanding the макрос.
  static сим[] раскрой(ТаблицаМакросов мтаблица, сим[] текст, сим[] путьКФайлу,
                       Диагностика диаг = null)
  {
    РаскрывательМакросов me;
    me.мтаблица = мтаблица;
    me.диаг = диаг;
    me.путьКФайлу = путьКФайлу;
    return me.раскройМакрос(текст);
  }

  /// Reports a предупреждение сообщение.
  проц  предупреждение(сим[] сооб, сим[] macroName)
  {
    сооб = Формат(сооб, macroName);
    if (диаг)
      диаг ~= new Предупреждение(new Положение(путьКФайлу, 0), сооб);
  }

  /// Expands the макрос из the таблица in the текст.
  сим[] раскройМакрос(сим[] текст, сим[] предшArg0 = null/+, бцел depth = 1000+/)
  {
    // if (depth == 0)
    //   return  текст;
    // depth--;
    сим[] результат;
    сим* p = текст.ptr;
    сим* конецТекста = p + текст.length;
    сим* конецМакроса = p;
    while (p+3 < конецТекста) // minimum 4 chars: $(x)
    {
      if (*p == '$' && p[1] == '(')
      {
        // Copy ткст between макрос.
        if (конецМакроса != p)
          результат ~= сделайТекст(конецМакроса, p);
        p += 2;
        if (auto macroName = сканируйИдентификатор(p, конецТекста))
        {
          // Get arguments.
          auto аргиМакроса = сканируйАргументы(p, конецТекста);
          if (p == конецТекста)
          {
            предупреждение(сооб.НеоконченныйМакросДДок, macroName);
            результат ~= "$(" ~ macroName ~ " ";
          }
          else
            p++;
          конецМакроса = p; // Point past ')'.

          auto macro_ = мтаблица.ищи(macroName);
          if (macro_)
          { // Ignore recursive macro if:
            auto macroArg0 = аргиМакроса.length ? аргиМакроса[0] : null;
            if (macro_.callLevel != 0 &&
                (аргиМакроса.length == 0/+ || // Макрос has no arguments.
                 предшArg0 == macroArg0+/)) // macroArg0 equals предшious arg0.
            { continue; }
            macro_.callLevel++;
            // Expand the arguments in the macro текст.
            auto развёрнутыйТекст = разверниАргументы(macro_.текст, аргиМакроса);
            результат ~= раскройМакрос(развёрнутыйТекст, macroArg0/+, depth+/);
            macro_.callLevel--;
          }
          else
          {
            предупреждение(сооб.НезаданныйМакросДДок, macroName);
            //результат ~= сделайТекст(macroName.ptr-2, конецМакроса);
          }
          continue;
        }
      }
      p++;
    }
    if (конецМакроса == текст.ptr)
      return текст; // No макрос found. Итог original текст.
    if (конецМакроса < конецТекста)
      результат ~= сделайТекст(конецМакроса, конецТекста);
    return результат;
  }

  /// Scans until the закрывающий parenthesis is found. Sets p в one сим past it.
  /// Возвращает: [arg0, arg1, arg2 ...].
  static сим[][] сканируйАргументы(ref сим* p, сим* конецТекста)
  out(арги) { assert(арги.length != 1); }
  body
  {
    // D specs: "The аргумент текст can contain nested parentheses,
    //           "" or '' тксты, comments, or tags."
    бцел уровень = 1; // Nesting уровень of the parentheses.
    сим[][] арги;

    // Skip leading spaces.
    while (p < конецТекста && пбел_ли(*p))
      p++;

    сим* arg0Begin = p; // Whole аргумент список.
    сим* началоАрга = p;
  ГлавныйЦикл:
    while (p < конецТекста)
    {
      switch (*p)
      {
      case ',':
        if (уровень != 1) // Ignore comma if внутри ().
          break;
        // Add a new аргумент.
        арги ~= сделайТекст(началоАрга, p);
        while (++p < конецТекста && пбел_ли(*p)) // Skip spaces.
        {}
        началоАрга = p;
        continue;
      case '(':
        уровень++;
        break;
      case ')':
        if (--уровень == 0)
          break ГлавныйЦикл;
        break;
      // Commented out: causes too many problems in the expansion pass.
      // case '"', '\'':
      //   auto c = *p;
      //   while (++p < конецТекста && *p != c) // Scan в следщ " or '.
      //   {}
      //   assert(*p == c || p == конецТекста);
      //   if (p == конецТекста)
      //     break ГлавныйЦикл;
      //   break;
      case '<':
        p++;
        if (p+2 < конецТекста && *p == '!' && p[1] == '-' && p[2] == '-') // <!--
        {
          p += 2; // Point в 2nd '-'.
          // Scan в закрывающий "-->".
          while (++p < конецТекста)
            if (p+2 < конецТекста && *p == '-' && p[1] == '-' && p[2] == '>') {
              p += 2; // Point в '>'.
              break;
            }
        } // <tag ...> or </tag>
        else if (p < конецТекста && (буква_ли(*p) || *p == '/'))
          while (++p < конецТекста && *p != '>') // Skip в закрывающий '>'.
          {}
        else
          continue ГлавныйЦикл;
        assert(p <= конецТекста);
        if (p == конецТекста)
          break ГлавныйЦикл;
        assert(*p == '>');
        break;
      default:
      }
      p++;
    }
    assert(*p == ')' && уровень == 0 || p == конецТекста);
    if (arg0Begin == p)
      return null;
    // arg0 spans the whole аргумент список.
    auto arg0 = сделайТекст(arg0Begin, p);
    // Add last аргумент.
    арги ~= сделайТекст(началоАрга, p);
    return arg0 ~ арги;
  }

  /// Expands "&#36;+", "&#36;0" - "&#36;9" with арги[n] in текст.
  /// Параметры:
  ///   текст = the текст в сканируй for аргумент placeholders.
  ///   арги = the first element, арги[0], is the whole аргумент ткст and
  ///          the following elements are slices into it.$(BR)
  ///          The массив is empty if there are no arguments.
  сим[] разверниАргументы(сим[] текст, сим[][] арги)
  in { assert(арги.length != 1, "ожидалось нуль или больше 1 аргумента"); }
  body
  {
    сим[] результат;
    сим* p = текст.ptr;
    сим* конецТекста = p + текст.length;
    сим* конецМестодержателя = p;

    while (p+1 < конецТекста)
    {
      if (*p == '$' && (*++p == '+' || цифра_ли(*p)))
      {
        // Copy ткст between аргумент placeholders.
        if (конецМестодержателя != p-1)
          результат ~= сделайТекст(конецМестодержателя, p-1);
        конецМестодержателя = p+1; // Set new placeholder конец.

        if (арги.length == 0)
          continue;

        if (*p == '+')
        { // $+ = $2 в $n
          if (арги.length > 2)
            результат ~= сделайТекст(арги[2].ptr, арги[0].ptr + арги[0].length);
        }
        else
        { // 0 - 9
          бцел nthArg = *p - '0';
          if (nthArg < арги.length)
            результат ~= арги[nthArg];
        }
      }
      p++;
    }
    if (конецМестодержателя == текст.ptr)
      return текст; // No placeholders found. Итог original текст.
    if (конецМестодержателя < конецТекста)
      результат ~= сделайТекст(конецМестодержателя, конецТекста);
    return результат;
  }
}
