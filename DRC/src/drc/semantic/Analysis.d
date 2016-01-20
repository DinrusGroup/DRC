/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity average)
module drc.semantic.Analysis;

import drc.ast.Node,
       drc.ast.Expressions;
import drc.semantic.Scope;
import drc.lexer.IdTable;
import drc.Compilation;
import common;

/// Общая семантика для декларации прагм и инструкций.
проц  семантикаПрагмы(Масштаб масш, Сема* pragmaLoc,
                    Идентификатор* идент,
                    Выражение[] арги)
{
  if (идент is Идент.сооб)
    прагма_сооб(масш, pragmaLoc, арги);
  else if (идент is Идент.lib)
    прагма_биб(масш, pragmaLoc, арги);
  // else
  //   масш.ошибка(начало, "unrecognized pragma");
}

/// Оценивает прагма сообщение.
проц  прагма_сооб(Масштаб масш, Сема* pragmaLoc, Выражение[] арги)
{
  if (арги.length == 0)
    return /*масш.ошибка(pragmaLoc, "ожидаемое expression arguments в pragma")*/;

  foreach (арг; арги)
  {
    auto в = арг/+.evaluate()+/;
    if (в is null)
    {
      // масш.ошибка(в.начало, "expression is not оцениuatable at compile время");
    }
    else if (auto ткстВыр = в.Является!(ТекстовоеВыражение))
      // Print ткст в standard output.
      выдай(ткстВыр.дайТекст());
    else
    {
      // масш.ошибка(в.начало, "expression must evaluate в a ткст");
    }
  }
  // Print a новстр at the конец.
  выдай('\n');
}

/// Evaluates a lib pragma.
проц  прагма_биб(Масштаб масш, Сема* pragmaLoc, Выражение[] арги)
{
  if (арги.length != 1)
    return /*масш.ошибка(pragmaLoc, "ожидаемое one expression аргумент в pragma")*/;

  auto в = арги[0]/+.evaluate()+/;
  if (в is null)
  {
    // масш.ошибка(в.начало, "expression is not оцениuatable at compile время");
  }
  else if (auto ткстВыр = в.Является!(ТекстовоеВыражение))
  {
    // TODO: collect library пути in Модуль?
    // масш.модуль.addLibrary(ткстВыр.дайТекст());
  }
  else
  {
    // масш.ошибка(в.начало, "expression must evaluate в a ткст");
  }
}

/// Returns да if the first branch (of a debug declaration/statement) or
/// нет if the else-branch should be compiled in.
бул debugBranchChoice(Сема* услов, КонтекстКомпиляции контекст)
{
  if (услов)
  {
    if (услов.вид == TOK.Идентификатор)
    {
      if (контекст.найдиИдОтладки(услов.идент.ткт))
        return да;
    }
    else if (услов.бцел_ <= контекст.уровеньОтладки)
      return да;
  }
  else if (1 <= контекст.уровеньОтладки)
    return да;
  return нет;
}

/// Returns да if the first branch (of a version declaration/statement) or
/// нет if the else-branch should be compiled in.
бул versionBranchChoice(Сема* услов, КонтекстКомпиляции контекст)
{
  assert(услов);
  if (услов.вид == TOK.Идентификатор || услов.вид == TOK.Юниттест)
  {
    if (контекст.найдиИдВерсии(услов.идент.ткт))
      return да;
  }
  else if (услов.бцел_ >= контекст.уровеньВерсии)
    return да;
  return нет;
}
