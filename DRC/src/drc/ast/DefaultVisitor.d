/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module drc.ast.DefaultVisitor;

import  drc.ast.Visitor,
       drc.ast.NodeMembers,
       drc.ast.Node,
       drc.ast.Declarations,
       drc.ast.Expressions,
       drc.ast.Statements,
       drc.ast.Types,
       drc.ast.Parameters;
import common;

/// Генерирует рабочий код для посещения предоставленных членов.
private ткст создайКод(ВидУзла видУзла)
{
  ткст[] члены; // Массив из имен членов, которые будут посещаться.

  // Поиск членов для узла данного вида в таблице.
  члены = г_таблицаЧленов[видУзла];

  if (!члены.length)
    return "";

  ткст[2][] список = разборЧленов(члены);
  ткст код;
  foreach (m; список)
  {
    auto имя = m[0], тип = m[1];
    switch (тип)
    {
    case "": // Посетить узел.
      код ~= "посетиУ(n."~имя~");"\n; // посетиУ(n.член);
      break;
    case "?": // Посетить узел, м.б. null.
      // n.член && посетиУ(n.член);
      код ~= "n."~имя~" && посетиУ(n."~имя~");"\n;
      break;
    case "[]": // Посетить узлы из массива.
      код ~= "foreach (x; n."~имя~")"\n // foreach (x; n.член)
              "  посетиУ(x);\n";           //   посетиУ(x);
      break;
    case "[?]": // Посетить узлы из массива, элементы м.б. null.
      код ~= "foreach (x; n."~имя~")"\n // foreach (x; n.член)
              "  x && посетиУ(x);\n";      //   x && посетиУ(x);
      break;
    case "%": // Копировать код дословно.
      код ~= имя ~ \n;
      break;
    default:
      assert(0, "неизвестный тип члена.");
    }
  }
  return код;
}

/// Generates the default посети methods.
///
/// E.g.:
/// ---
/// override типВозврата!("ДекларацияКласса") посети(ДекларацияКласса n)
/// { /* Code that посетиИ the subnodes... */ return n; }
/// ---
ткст генерируйДефМетодыВизита()
{
  ткст код;
  foreach (i, имяКласса; г_именаКлассов)
    код ~= "override типВозврата!(`"~имяКласса~"`) посети("~имяКласса~" n)"
            "{"
            "  "~создайКод(cast(ВидУзла)i)~
            "  return n;"
            "}\n";
  return код;
}
// pragma(сооб, генерируйДефМетодыВизита());

/// Этот class provides default methods for
/// traversing nodes and their subnodes.
class ДефолтныйВизитёр : Визитёр
{
  // Комментарий out if too many ошибки are shown.
  mixin(генерируйДефМетодыВизита());
}
