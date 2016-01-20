/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module  drc.ast.Visitor;

import drc.ast.Node,
       drc.ast.Declarations,
       drc.ast.Expressions,
       drc.ast.Statements,
       drc.ast.Types,
       drc.ast.Parameters;

/// Generate посети methods.
///
/// E.g.:
/// ---
/// Декларация посети(ДекларацияКласса){return null;};
/// Выражение посети(ВыражениеЗапятая){return null;};
/// ---
сим[] генерируйМетодыВизита()
{
  сим[] текст;
  foreach (имяКласса; г_именаКлассов)
    текст ~= "типВозврата!(\""~имяКласса~"\") посети("~имяКласса~" узел){return узел;}\n";
  return текст;
}
// pragma(сооб, generateAbтктactVisitMethods());

/// Получает соответствующий тип возврата для предложенного класса.
template типВозврата(сим[] имяКласса)
{
  static if (is(typeof(mixin(имяКласса)) : Декларация))
    alias Декларация типВозврата;
  else
  static if (is(typeof(mixin(имяКласса)) : Инструкция))
    alias Инструкция типВозврата;
  else
  static if (is(typeof(mixin(имяКласса)) : Выражение))
    alias Выражение типВозврата;
  else
  static if (is(typeof(mixin(имяКласса)) : УзелТипа))
    alias УзелТипа типВозврата;
  else
    alias Узел типВозврата;
}

/// Generate functions which do the second отправь.
///
/// E.g.:
/// ---
/// Выражение visitCommaExpression(Визитёр визитёр, ВыражениеЗапятая c)
/// { визитёр.посети(c); /* Second отправь. */ }
/// ---
/// The equivalent in the traditional визитёр pattern would be:
/// ---
/// class ВыражениеЗапятая : Выражение
/// {
///   проц  accept(Визитёр визитёр)
///   { визитёр.посети(this); }
/// }
/// ---
сим[] генерируйФункцииОтправки()
{
  сим[] текст;
  foreach (имяКласса; г_именаКлассов)
    текст ~= "типВозврата!(\""~имяКласса~"\") посети"~имяКласса~"(Визитёр визитёр, "~имяКласса~" c)\n"
            "{ return визитёр.посети(c); }\n";
  return текст;
}
// pragma(сооб, генерируйФункцииОтправки());

/++
 Generates an массив of function pointers.

 ---
 [
   cast(проц *)&visitCommaExpression,
   // etc.
 ]
 ---
+/
сим[] генерируйВТаблицу()
{
  сим[] текст = "[";
  foreach (имяКласса; г_именаКлассов)
    текст ~= "cast(ук)&посети"~имяКласса~",\n";
  return текст[0..$-2]~"]"; // slice away last ",\n"
}
// pragma(сооб, генерируйВТаблицу());

/// Implements a variation of the визитёр pattern.
///
/// Inherited by classes that need в traverse a D syntax tree
/// and do computations, transformations and другой things on it.
abstract class Визитёр
{
  mixin(генерируйМетодыВизита());

  static
    mixin(генерируйФункцииОтправки());

  // Это необходимо, поскольку компилятор помещает
  // данный массив в сегмент статических данных.
  mixin("private const _dispatch_vtable = " ~ генерируйВТаблицу() ~ ";");
  /// The таблица holding function pointers в the second отправь functions.
  static const отправь_втаблицу = _dispatch_vtable;
  static assert(отправь_втаблицу.length == г_именаКлассов.length,
                "длина втаблицы не соответствует числу классов");

  /// Looks up the second отправь function for n and returns that.
  Узел function(Визитёр, Узел) дайФункциюОтправки()(Узел n)
  {
    return cast(Узел function(Визитёр, Узел))отправь_втаблицу[n.вид];
  }

  /// The main and first отправь function.
  Узел отправь(Узел n)
  { // Second отправь is done in the called function.
    return дайФункциюОтправки(n)(this, n);
  }

final:
  Декларация посети(Декларация n)
  { return посетиД(n); }
  Инструкция посети(Инструкция n)
  { return посетиИ(n); }
  Выражение посети(Выражение n)
  { return посетиВ(n); }
  УзелТипа посети(УзелТипа n)
  { return посетиТ(n); }
  Узел посети(Узел n)
  { return посетиУ(n); }

  Декларация посетиД(Декларация n)
  {
    return cast(Декларация)cast(ук)отправь(n);
  }

  Инструкция посетиИ(Инструкция n)
  {
    return cast(Инструкция)cast(ук)отправь(n);
  }

  Выражение посетиВ(Выражение n)
  {
    return cast(Выражение)cast(ук)отправь(n);
  }

  УзелТипа посетиТ(УзелТипа n)
  {
    return cast(УзелТипа)cast(ук)отправь(n);
  }

  Узел посетиУ(Узел n)
  {
    return отправь(n);
  }
}
