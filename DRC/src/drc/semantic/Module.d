/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.semantic.Module;

import drc.ast.Node,
       drc.ast.Declarations;
import drc.parser.Parser;
import drc.lexer.Lexer,
       drc.lexer.IdTable;
import drc.semantic.Symbol,
       drc.semantic.Symbols;
import drc.Location;
import drc.Messages;
import drc.Diagnostics;
import drc.SourceText;
import common;

import tango.io.FilePath;
import tango.io.model.IFile;

alias FileConst.PathSeparatorChar папРазд;

/// Represents a semantic D module and a source file.
class Модуль : СимволМасштаба
{
  ИсходныйТекст исходныйТекст; /// The source file of this module.
  ткст пкиМодуля; /// Fully qualified имя of the module. E.g.: drc.ast.Node
  ткст имяПакета; /// E.g.: drc.ast
  ткст имяМодуля; /// E.g.: Узел

  СложнаяДекларация корень; /// The корень of the разбор tree.
  ДекларацияИмпорта[] импорты; /// ДекларацииИмпорта found in this file.
  ДекларацияМодуля деклМодуля; /// The optional ДекларацияМодуля in this file.
  Парсер парсер; /// The парсер used в разбор this file.

  /// Indicates which passes have been пуск on this module.
  ///
  /// 0 = no pass$(BR)
  /// 1 = semantic pass 1$(BR)
  /// 2 = semantic pass 2
  бцел семантическийПроходка;
  Модуль[] модули; /// The imported модули.

  Диагностика диаг; /// Collects ошибка сообщения.

  this()
  {
    super(СИМ.Модуль, null, null);
  }

  /// Constructs a Модуль object.
  /// Параметры:
  ///   путьКФайлу = file путь в the source текст; loaded in the constructor.
  ///   диаг = used for collecting ошибка сообщения.
  this(ткст путьКФайлу, Диагностика диаг = null)
  {
    this();
    this.исходныйТекст = new ИсходныйТекст(путьКФайлу);
    this.диаг = диаг is null ? new Диагностика() : диаг;
    this.исходныйТекст.загрузи(диаг);
  }

  /// Returns the file путь of the source текст.
  ткст путьКФайлу()
  {
    return исходныйТекст.путьКФайлу;
  }

  /// Returns the file extension: "d" or "di".
  ткст расширениеФайла()
  {
    foreach_reverse(i, c; путьКФайлу)
      if (c == '.')
        return путьКФайлу[i+1..$];
    return "";
  }

  /// Sets the парсер в be used for parsing the source текст.
  проц  установиПарсер(Парсер парсер)
  {
    this.парсер = парсер;
  }

  /// Parses the module.
  /// Бросьs:
  ///   An Exception if the there's no ДекларацияМодуля and
  ///   the file имя is an invalid or reserved D identifier.
  проц  разбор()
  {
    if (this.парсер is null)
      this.парсер = new Парсер(исходныйТекст, диаг);

    this.корень = парсер.старт();
    this.импорты = парсер.импорты;

    // Set the fully qualified имя of this module.
    if (this.корень.отпрыски.length)
    { // деклМодуля will be null if first узел isn't a ДекларацияМодуля.
      this.деклМодуля = this.корень.отпрыски[0].Является!(ДекларацияМодуля);
      if (this.деклМодуля)
        this.установиПКН(деклМодуля.дайПКН()); // E.g.: drc.ast.Node
    }

    if (!this.пкиМодуля.length)
    { // Take the base имя of the file as the module имя.
      auto ткт = (new FilePath(путьКФайлу)).name(); // E.g.: Узел
      if (!Лексер.действитНерезИдентификатор_ли(ткт))
      {
        auto положение = this.перваяСема().дайПоложениеОшибки();
        auto сооб = Формат(сооб.НеверноеИмяМодуля, ткт);
        диаг ~= new ОшибкаЛексера(положение, сооб);
        ткт = ТаблицаИд.генИдМодуля().ткт;
      }
      this.пкиМодуля = this.имяМодуля = ткт;
    }
    assert(this.пкиМодуля.length);

    // Set the символ имя.
    this.имя = ТаблицаИд.сыщи(this.имяМодуля);
  }

  /// Returns the first сема of the module's source текст.
  Сема* перваяСема()
  {
    return парсер.лексер.перваяСема();
  }

  /// Returns the начало сема of the module declaration
  /// or, if it doesn't exist, the first сема in the source текст.
  Сема* дайСемуДеклМодуля()
  {
    return деклМодуля ? деклМодуля.начало : перваяСема();
  }

  /// Returns да if there are ошибки in the source file.
  бул естьОшибки()
  {
    return парсер.ошибки.length || парсер.лексер.ошибки.length;
  }

  /// Returns a список of import пути.
  /// E.g.: ["dil/ast/Узел", "dil/semantic/Модуль"]
  ткст[] дайПутиИмпорта()
  {
    ткст[] результат;
    foreach (import_; импорты)
      результат ~= import_.дайПКНМодуля(папРазд);
    return результат;
  }

  /// Returns the fully qualified имя of this module.
  /// E.g.: drc.ast.Node
  ткст дайПКН()
  {
    return пкиМодуля;
  }

  /// Set's the module's ПКИ.
  проц  установиПКН(ткст пкиМодуля)
  {
    бцел i = пкиМодуля.length;
    if (i != 0) // Don't decrement if ткст has zero length.
      i--;
    // Find last dot.
    for (; i != 0 && пкиМодуля[i] != '.'; i--)
    {}
    this.пкиМодуля = пкиМодуля;
    if (i == 0)
      this.имяМодуля = пкиМодуля; // No dot found.
    else
    {
      this.имяПакета = пкиМодуля[0..i];
      this.имяМодуля = пкиМодуля[i+1..$];
    }
  }

  /// Returns the module's ПКИ with slashes instead of dots.
  /// E.g.: dil/ast/Узел
  ткст дайПутьПКН()
  {
    ткст FQNPath = пкиМодуля.dup;
    foreach (i, c; FQNPath)
      if (c == '.')
        FQNPath[i] = папРазд;
    return FQNPath;
  }
}
