/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module drc.ast.NodeCopier;

import drc.ast.NodesEnum,
       drc.ast.NodeMembers;

import common;

/// Внедряется в тело класса, наследующего от Узел.
const ткст методКопирования =
  "override typeof(this) копируй()"
  "{"
  "  alias typeof(this) т_этот;"
  "  mixin(генКодКопию(mixin(`ВидУзла.`~т_этот.stringof)));"
  "  return n;"
  "}";

/// Внедряется в тело абстрактного класса БинарноеВыражение.
const ткст бинарноеВыражениеМетодаКопирования =
  "override typeof(this) копируй()"
  "{"
  "  alias typeof(this) т_этот;"
  "  assert(is(ВыражениеЗапятая : БинарноеВыражение), `ВыражениеЗапятая не наследует от БинарноеВыражение`);"
  "  mixin(генКодКопию(ВидУзла.ВыражениеЗапятая));"
  "  return n;"
  "}";

///  Внедряется в тело абстрактного класса УнарноеВыражение.
const ткст унарноеВыражениеМетодаКопирования =
  "override typeof(this) копируй()"
  "{"
  "  alias typeof(this) т_этот;"
  "  assert(is(ВыражениеАдрес : УнарноеВыражение), `ВыражениеАдрес не наследует от УнарноеВыражение`);"
  "  mixin(генКодКопию(ВидУзла.ВыражениеАдрес));"
  "  return n;"
  "}";

/// Генерирует рабочий код для копирования предоставленных членов.
private ткст создайКод(ткст[] члены)
{
  ткст[2][] список = разборЧленов(члены);
  ткст код;
  foreach (m; список)
  {
    auto имя = m[0], тип = m[1];
    switch (тип)
    {
    case "": // Copy a член, must not be null.
      // n.член = n.член.копируй();
      код ~= "n."~имя~" = n."~имя~".копируй();"\n;
      break;
    case "?": // Copy a член, may be null.
      // n.член && (n.член = n.член.копируй());
      код ~= "n."~имя~" && (n."~имя~" = n."~имя~".копируй());"\n;
      break;
    case "[]": // Copy an массив of nodes.
      код ~= "n."~имя~" = n."~имя~".dup;"\n // n.член = n.член.dup;
              "foreach (ref x; n."~имя~")"\n  // foreach (ref x; n.член)
              "  x = x.копируй();\n";             //   x = x.копируй();
      break;
    case "[?]": // Copy an массив of nodes, элементы may be null.
      код ~= "n."~имя~" = n."~имя~".dup;"\n // n.член = n.член.dup;
              "foreach (ref x; n."~имя~")"\n  // foreach (ref x; n.член)
              "  x && (x = x.копируй());\n";      //   x && (x = x.копируй());
      break;
    case "%": // Copy код verbatim.
      код ~= имя ~ \n;
      break;
    default:
      assert(0, "член неизвестного типа.");
    }
  }
  return код;
}

// pragma(сооб, создайКод(["выр?", "деклы[]", "тип"]));

/// Generates код for copying a узел.
ткст генКодКопию(ВидУзла видУзла)
{
  ткст[] m; // Array of член имена в be copied.

  // Handle special cases.
  if (видУзла == ВидУзла.ТекстовоеВыражение)
    m = ["%n.ткт = n.ткт.dup;"];
  else
    // Look up члены for this вид of узел in the таблица.
    m = г_таблицаЧленов[видУзла];

  сим[] код =
  // First do a shallow копируй.
  "auto n = cast(т_этот)cast(ук)this.dup;\n";

  // Then копируй the члены.
  if (m.length)
    код ~= создайКод(m);

  return код;
}

// pragma(сооб, генКодКопию("ТипМассив"));
