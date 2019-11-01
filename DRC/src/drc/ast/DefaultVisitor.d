module drc.ast.DefaultVisitor;

import  drc.ast.Visitor,
       drc.ast.NodeЧленs,
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
    case "?": // Посетить узел, м.б. пусто.
      // n.член && посетиУ(n.член);
      код ~= "n."~имя~" && посетиУ(n."~имя~");"\n;
      break;
    case "[]": // Посетить узлы из массива.
      код ~= "foreach (x; n."~имя~")"\n // foreach (x; n.член)
              "  посетиУ(x);\n";           //   посетиУ(x);
      break;
    case "[?]": // Посетить узлы из массива, элементы м.б. пусто.
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

/// Генерирует дефолтные методы посещения "посети".
///
/// Напр.:
/// ---
/// override типВозврата!("ДекларацияКласса") посети(ДекларацияКласса n)
/// { /* Код посещения субмодулей... */ return n; }
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

/// Этот класс предоставляет дефолтные методы для
/// обхода узлов и их субузлов.
class ДефолтныйВизитёр : Визитёр
{
  // Закомментируйте, если выводится слишком много ошибок.
  mixin(генерируйДефМетодыВизита());
}
