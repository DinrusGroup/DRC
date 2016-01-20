/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity average)
module cmd.ImportGraph;

import drc.ast.Node,
       drc.ast.Declarations;
import drc.semantic.Module;
import drc.parser.ImportParser;
import drc.SourceText;
import drc.Compilation;
import drc.ModuleManager;
import Settings;
import common;

import tango.text.Regex : RegExp = Regex;
import tango.io.FilePath;
import tango.io.model.IFile;
import tango.text.Util;

alias FileConst.PathSeparatorChar папРазд;

/// The importgraph команда.
struct ИКомандаГрафа
{
  /// Опции for the команда.
  enum Опция
  {
    Нет,
    ВключатьНеопределённыеМодули = 1,
    ВыводитьДот                  = 1<<1,
    ВыделитьЦиклическиеКрая      = 1<<2,
    ВыделитьЦиклическиеВершины   = 1<<3,
    ГруппироватьПоИменамПакетов       = 1<<4,
    ГруппироватьПоПолномуИмениПакета    = 1<<5,
    ВывестиПути                = 1<<6,
    ВывестиСписок                 = 1<<7,
    ПометитьЦиклическиеМодули         = 1<<8,
  }
  alias Опция Опции;

  Опции опции; /// команда опции.
  ткст путьКФайлу; /// File путь в the корень module.
  ткст[] регвыры; /// Regular expressions.
  ткст siStyle = "dashed"; /// Статический import style.
  ткст piStyle = "bold";   /// Публичный import style.
  бцел уровни; /// How many уровни в print.

  КонтекстКомпиляции контекст;

  /// Adds o в the опции.
  проц  добавь(Опция o)
  {
    опции |= o;
  }

  проц  пуск()
  {
    // Init regular expressions.
    RegExp[] регвыры;
    foreach (тктRegexp; this.регвыры)
      регвыры ~= new RegExp(тктRegexp);

    // Add the directory of the file в the import пути.
    auto путьКФайлу = new FilePath(this.путьКФайлу);
    контекст.путиИмпорта ~= путьКФайлу.folder();

    auto gbuilder = new ГрафоПостроитель;

    gbuilder.путиИмпорта = контекст.путиИмпорта;
    gbuilder.опции = опции;
    gbuilder.предикатФильтра = (ткст путьПоПКНМодуля) {
      foreach (rx; регвыры)
        // Replace slashes: dil/ast/Узел -> drc.ast.Node
        if (rx.test(replace(путьПоПКНМодуля.dup, папРазд, '.')))
          return да;
      return нет;
    };

    auto граф = gbuilder.старт(путьКФайлу.name());

    if (опции & (Опция.ВывестиСписок | Опция.ВывестиПути))
    {
      if (опции & Опция.ПометитьЦиклическиеМодули)
        граф.обнаружьЦиклы();

      if (опции & Опция.ВывестиПути)
        выведиПутиКМодулям(граф.вершины, уровни+1, "");
      else
        выведиСписокМодулей(граф.вершины, уровни+1, "");
    }
    else
      выведиДокументДот(граф, siStyle, piStyle, опции);
  }
}

/// Represents a module dependency граф.
class Граф
{
  Вершина[] вершины; /// The вершины or модули.
  Край[] края; /// The края or import инструкции.

  проц  добавьВершину(Вершина вершина)
  {
    вершина.ид = вершины.length;
    вершины ~= вершина;
  }

  Край добавьКрай(Вершина из, Вершина в)
  {
    auto край = new Край(из, в);
    края ~= край;
    из.исходящий ~= в;
    в.входящий ~= из;
    return край;
  }

  /// Walks the граф and marks cyclic вершины and края.
  проц  обнаружьЦиклы()
  { // Cycles could also be detected in the ГрафоПостроитель,
    // but having the код here makes things much clearer.

    // Commented out because this algorithm doesn't work.
    // Returns да if the вершина is in состояние Посещаемое.
    /+бул посети(Вершина вершина)
    {
      switch (вершина.состояние)
      {
      case Вершина.Состояние.Посещаемое:
        вершина.цикличн_ли = да;
        return да;
      case Вершина.Состояние.Нет:
        вершина.состояние = Вершина.Состояние.Посещаемое; // Flag as visiting.
        foreach (outVertex; вершина.исходящий)    // Visit successors.
          вершина.цикличн_ли |= посети(outVertex);
        вершина.состояние = Вершина.Состояние.Посещённое;  // Flag as visited.
        break;
      case Вершина.Состояние.Посещённое:
        break;
      default:
        assert(0, "unknown вершина состояние");
      }
      return нет; // return (вершина.состояние == Вершина.Состояние.Посещаемое);
    }
    // Start visiting вершины.
    посети(вершины[0]);+/

    //foreach (край; края)
    //  if (край.из.цикличн_ли && край.в.цикличн_ли)
    //    край.цикличн_ли = да;

    // Use functioning algorithm.
    анализируйГраф(вершины, края);
  }
}

/// Represents a directed connection between two вершины.
class Край
{
  Вершина из;   /// Coming из вершина.
  Вершина в;     /// Going в вершина.
  бул цикличн_ли; /// Край connects cyclic вершины.
  бул публичный_ли; /// Публичный import.
  бул статический_ли; /// Статический import.

  this(Вершина из, Вершина в)
  {
    this.из = из;
    this.в = в;
  }
}

/// Represents a module in the граф.
class Вершина
{
  Модуль модуль;      /// The module represented by this вершина.
  бцел ид;           /// The nth вершина in the граф.
  Вершина[] входящий; /// Also called predecessors.
  Вершина[] исходящий; /// Also called successors.
  бул цикличн_ли;     /// Whether this вершина is in a cyclic relationship with другой вершины.

  enum Состояние : ббайт
  { Нет, Посещаемое, Посещённое }
  Состояние состояние; /// Used by the cycle detection algorithm.
}

/// Builds a module dependency граф.
class ГрафоПостроитель
{
  Граф граф;
  ИКомандаГрафа.Опции опции;
  ткст[] путиИмпорта; /// Where в look for модули.
  Вершина[ткст] таблицаЗагруженныхМодулей; /// Maps ПКИ пути в модули.
  бул delegate(ткст) предикатФильтра;

  this()
  {
    this.граф = new Граф;
  }

  /// Start building the граф and return that.
  /// Параметры:
  ///   имяФайла = the file имя of the корень module.
  Граф старт(ткст имяФайла)
  {
    загрузиМодуль(имяФайла);
    return граф;
  }

  /// Loads all модули recursively and builds the граф at the same время.
  /// Параметры:
  ///   путьПоПКНМодуля = the путь version of the module ПКИ.$(BR)
  ///                   E.g.: ПКИ = drc.ast.Node -> FQNPath = dil/ast/Узел
  Вершина загрузиМодуль(ткст путьПоПКНМодуля)
  {
    // Look up in таблица if the module is already loaded.
    auto pVertex = путьПоПКНМодуля in таблицаЗагруженныхМодулей;
    if (pVertex !is null)
      return *pVertex; // Returns null for filtered or unlocatable модули.

    // Filter out модули.
    if (предикатФильтра && предикатФильтра(путьПоПКНМодуля))
    { // Store null for filtered модули.
      таблицаЗагруженныхМодулей[путьПоПКНМодуля] = null;
      return null;
    }

    // Locate the module in the file system.
    auto путьКФайлуМодуля = МодульМенеджер.найдиПутьКФайлуМодуля(
      путьПоПКНМодуля,
      путиИмпорта
    );

    Вершина вершина;

    if (путьКФайлуМодуля is null)
    { // Модуль not found.
      if (опции & ИКомандаГрафа.Опция.ВключатьНеопределённыеМодули)
      { // Include module nevertheless.
        вершина = new Вершина;
        вершина.модуль = new Модуль("");
        вершина.модуль.установиПКН(replace(путьПоПКНМодуля, папРазд, '.'));
        граф.добавьВершину(вершина);
      }
      // Store вершина in the таблица (вершина may be null.)
      таблицаЗагруженныхМодулей[путьПоПКНМодуля] = вершина;
    }
    else
    {
      auto модуль = new Модуль(путьКФайлуМодуля);
      // Use lightweight ПарсерИмпорта.
      модуль.установиПарсер(new ПарсерИмпорта(модуль.исходныйТекст));
      модуль.разбор();

      вершина = new Вершина;
      вершина.модуль = модуль;

      граф.добавьВершину(вершина);
      таблицаЗагруженныхМодулей[модуль.дайПутьПКН()] = вершина;

      // Load the модули which this module depends on.
      foreach (importDecl; модуль.импорты)
      {
        foreach (moduleFQNPath2; importDecl.дайПКНМодуля(папРазд))
        {
          auto loaded = загрузиМодуль(moduleFQNPath2);
          if (loaded !is null)
          {
            auto край = граф.добавьКрай(вершина, loaded);
            край.публичный_ли = importDecl.публичный_ли();
            край.статический_ли = importDecl.статический_ли();
          }
        }
      }
    }
    return вершина;
  }
}

/// Prints the file пути в the модули.
проц  выведиПутиКМодулям(Вершина[] вершины, бцел уровень, сим[] отступ)
{
  if (уровень == 0)
    return;
  foreach (вершина; вершины)
  {
    выдай(отступ)((вершина.цикличн_ли?"*":"")~вершина.модуль.путьКФайлу).nl;
    if (вершина.исходящий.length)
      выведиПутиКМодулям(вершина.исходящий, уровень-1, отступ~"  ");
  }
}

/// Prints a список of module ПКИм_ч.
проц  выведиСписокМодулей(Вершина[] вершины, бцел уровень, сим[] отступ)
{
  if (уровень == 0)
    return;
  foreach (вершина; вершины)
  {
    выдай(отступ)((вершина.цикличн_ли?"*":"")~вершина.модуль.дайПКН()).nl;
    if (вершина.исходящий.length)
      выведиСписокМодулей(вершина.исходящий, уровень-1, отступ~"  ");
  }
}

/// Prints the граф as a graphviz dot document.
проц  выведиДокументДот(Граф граф, ткст siStyle, ткст piStyle,
                      ИКомандаГрафа.Опции опции)
{
  Вершина[][ткст] вершиныПоИмПакета;
  if (опции & ИКомандаГрафа.Опция.ГруппироватьПоПолномуИмениПакета)
    foreach (вершина; граф.вершины)
      вершиныПоИмПакета[вершина.модуль.имяПакета] ~= вершина;

  if (опции & (ИКомандаГрафа.Опция.ВыделитьЦиклическиеВершины |
                 ИКомандаГрафа.Опция.ВыделитьЦиклическиеКрая))
    граф.обнаружьЦиклы();

  // Output header of the dot document.
  выдай("Digraph ImportGraph\n{\n");
  // Output nodes.
  // 'i' and вершина.ид should be the same.
  foreach (i, вершина; граф.вершины)
    выдай.formatln(`  n{} [лейбл="{}"{}];`, i, вершина.модуль.дайПКН(), (вершина.цикличн_ли ? ",style=filled,fillcolor=tomato" : ""));

  // Output края.
  foreach (край; граф.края)
  {
    ткст стилиКрая = "";
    if (край.статический_ли || край.публичный_ли)
    {
      стилиКрая = `[style="`;
      край.статический_ли && (стилиКрая ~= siStyle ~ ",");
      край.публичный_ли && (стилиКрая ~= piStyle);
      стилиКрая[$-1] == ',' && (стилиКрая = стилиКрая[0..$-1]); // Remove last comma.
      стилиКрая ~= `"]`;
    }
    край.цикличн_ли && (стилиКрая ~= "[color=red]");
    выдай.formatln(`  n{} -> n{} {};`, край.из.ид, край.в.ид, стилиКрая);
  }

  if (опции & ИКомандаГрафа.Опция.ГруппироватьПоПолномуИмениПакета)
    foreach (имяПакета, вершины; вершиныПоИмПакета)
    { // Output nodes in a cluster.
      выдай.format(`  subgraph "cluster_{}" {`\n`    лейбл="{}";color=blue;`"\n    ", имяПакета, имяПакета);
      foreach (вершина; вершины)
        выдай.format(`n{};`, вершина.ид);
      выдай("\n  }\n");
    }

  выдай("}\n");
}

// Этот is the old algorithm that was used в detect cycles in a directed граф.
проц  анализируйГраф(Вершина[] vertices_init, Край[] края)
{
  края = края.dup;
  проц  recursive(Вершина[] вершины)
  {
    foreach (idx, вершина; вершины)
    {
      бцел исходящий, входящий;
      foreach (j, край; края)
      {
        if (край.из is вершина)
          исходящий++;
        if (край.в is вершина)
          входящий++;
      }

      if (исходящий == 0)
      {
        if (входящий != 0)
        {
          // Вершина is a sink.
          alias исходящий i; // Reuse
          alias входящий j; // Reuse
          // Remove края.
          for (i=j=0; i < края.length; i++)
            if (края[i].в !is вершина)
              края[j++] = края[i];
          края.length = j;
          вершины = вершины[0..idx] ~ вершины[idx+1..$];
          recursive(вершины);
          return;
        }
        else
        {
          // Edges в this вершина were removed предшiously.
          // Only remove вершина now.
          вершины = вершины[0..idx] ~ вершины[idx+1..$];
          recursive(вершины);
          return;
        }
      }
      else if (входящий == 0)
      {
        // Вершина is a source
        alias исходящий i; // Reuse
        alias входящий j; // Reuse
        // Remove края.
        for (i=j=0; i < края.length; i++)
          if (края[i].из !is вершина)
            края[j++] = края[i];
        края.length = j;
        вершины = вершины[0..idx] ~ вершины[idx+1..$];
        recursive(вершины);
        return;
      }
//       else
//       {
//         // source && sink
//         // continue loop.
//       }
    }

    // When reaching this point it means only cylic края and вершины are левый.
    foreach (вершина; вершины)
      вершина.цикличн_ли = да;
    foreach (край; края)
      if (край)
        край.цикличн_ли = да;
  }
  recursive(vertices_init);
}
