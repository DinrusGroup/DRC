/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity average)
module drc.translator.German;

import drc.ast.DefaultVisitor,
       drc.ast.Node,
       drc.ast.Declarations,
       drc.ast.Statements,
       drc.ast.Types,
       drc.ast.Parameters;
import tango.io.Print;

private alias Декларация D;

/// Translates a syntax tree into German.
class НемецкийПереводчик : ДефолтныйВизитёр
{
  Print put; /// Буфер вывода.

  сим[] отступ; /// Текущий ткст индентации.
  сим[] шагОтступа; /// Добавляется к отступу на каждом уровне индентации.

  Декларация вхАгрегат; /// Текущий агрегат.
  Декларация вхФунк; /// Текущая функция.

  бул pluralize; /// Whether в use the plural when printing the следщ types.
  бул pointer; /// Whether следщ types should conсторонаr the предшious pointer.

  /// Конструировать НемецкийПереводчик.
  /// Параметры:
  ///   put = буфер для вывода.
  ///   шагОтступа = добавляется на каждом шагу индентации.
  this(Print put, сим[] шагОтступа)
  {
    this.put = put;
    this.шагОтступа = шагОтступа;
  }

  /// Начало перевода.
  проц  переведи(Узел корень)
  {
    посетиУ(корень);
  }

  /// Increases the indentation when instantiated.
  /// The indentation is restored when the instance goes out of Масштаб.
  scope class Отступ
  {
    сим[] old_indent;
    this()
    {
      old_indent = this.outer.отступ;
      this.outer.отступ ~= this.outer.шагОтступа;
    }

    ~this()
    { this.outer.отступ = old_indent; }

    сим[] вТкст()
    { return this.outer.отступ; }
  }

  /// Saves an outer член when instantiated.
  /// It is restored when the instance goes out of Масштаб.
  scope class Enter(T)
  {
    T t_save;
    this(T t)
    {
      auto t_save = t;
      static if (is(T == ДекларацияКласса) ||
                 is(T == ДекларацияИнтерфейса) ||
                 is(T == ДекларацияСтруктуры) ||
                 is(T == ДекларацияСоюза))
        this.outer.вхАгрегат = t;
      static if (is(T == ДекларацияФункции) ||
                 is(T == ДекларацияКонструктора))
        this.outer.вхФунк = t;
    }

    ~this()
    {
      static if (is(T == ДекларацияКласса) ||
                 is(T == ДекларацияИнтерфейса) ||
                 is(T == ДекларацияСтруктуры) ||
                 is(T == ДекларацияСоюза))
        this.outer.вхАгрегат = t_save;
      static if (is(T == ДекларацияФункции) ||
                 is(T == ДекларацияКонструктора))
        this.outer.вхФунк = t_save;
    }
  }

  alias Enter!(ДекларацияКласса) EnteredClass;
  alias Enter!(ДекларацияИнтерфейса) EnteredЦелerface;
  alias Enter!(ДекларацияСтруктуры) EnteredStruct;
  alias Enter!(ДекларацияСоюза) EnteredUnion;
  alias Enter!(ДекларацияФункции) EnteredFunction;
  alias Enter!(ДекларацияКонструктора) EnteredConstructor;

  /// Prints the положение of a узел: @(lin,столб)
  проц  printLoc(Узел узел)
  {
    auto место = узел.начало.getRealLocation();
    put(отступ).formatln("@({},{})",/+ место.путьКФайлу,+/ место.номСтр, место.номСтолб);
  }

override:
  D посети(ДекларацияМодуля n)
  {
    printLoc(n);
    put.format("Dies ist das Modul '{}'", n.имяМодуля.ткт);
    if (n.пакеты.length)
      put.format(" im Paket '{}'", n.дайИмяПакета('.'));
    put(".").nl;
    return n;
  }

  D посети(ДекларацияИмпорта n)
  {
    printLoc(n);
    put("Importiert Symbole aus einem anderen Modul bzw. Модуль.").nl;
    return n;
  }

  D посети(ДекларацияКласса n)
  {
    printLoc(n);
    scope E = new EnteredClass(n);
    put(отступ).formatln("'{}' is eine Klasse mit den Eigenschaften:", n.имя.ткт);
    scope I = new Отступ();
    n.деклы && посетиД(n.деклы);
    return n;
  }

  D посети(ДекларацияИнтерфейса n)
  {
    printLoc(n);
    scope E = new EnteredЦелerface(n);
    put(отступ).formatln("'{}' is ein Интерфейс mit den Eigenschaften:", n.имя.ткт);
    scope I = new Отступ();
    n.деклы && посетиД(n.деклы);
    return n;
  }

  D посети(ДекларацияСтруктуры n)
  {
    printLoc(n);
    scope E = new EnteredStruct(n);
    put(отступ).formatln("'{}' is eine Datenтктuktur mit den Eigenschaften:", n.имя.ткт);
    scope I = new Отступ();
    n.деклы && посетиД(n.деклы);
    return n;
  }

  D посети(ДекларацияСоюза n)
  {
    printLoc(n);
    scope E = new EnteredUnion(n);
    put(отступ).formatln("'{}' is eine Datenunion mit den Eigenschaften:", n.имя.ткт);
    scope I = new Отступ();
    n.деклы && посетиД(n.деклы);
    return n;
  }

  D посети(ДекларацияПеременных n)
  {
    printLoc(n);
    сим[] was;
    if (вхАгрегат)
      was = "Membervariable";
    else if (вхФунк)
      was = "lokale Переменная";
    else
      was = "globale Переменная";
    foreach (имя; n.имена)
    {
      put(отступ).format("'{}' ist eine {} des Typs: ", имя.ткт, was);
      if (n.узелТипа)
        посетиТ(n.узелТипа);
      else
        put("auto");
      put.nl;
    }
    return n;
  }

  D посети(ДекларацияФункции n)
  {
    printLoc(n);
    сим[] was;
    if (вхАгрегат)
      was = "Methode";
    else if(вхФунк)
      was = "geschachtelte Funktion";
    else
      was = "Funktion";
    scope E = new EnteredFunction(n);
    put(отступ).format("'{}' ist eine {} ", n.имя.ткт, was);
    if (n.парамы.length == 1)
      put("mit dem Argument "), посетиУ(n.парамы);
    else if (n.парамы.length > 1)
      put("mit den Argumenten "), посетиУ(n.парамы);
    else
      put("ohne Argumente");
    put(".").nl;
    scope I = new Отступ();
    return n;
  }

  D посети(ДекларацияКонструктора n)
  {
    printLoc(n);
    scope E = new EnteredConstructor(n);
    put(отступ)("Ein Konтктuktor ");
    if (n.парамы.length == 1)
      put("mit dem Argument "), посетиУ(n.парамы);
    else if (n.парамы.length > 1)
      put("mit den Argumenten "), посетиУ(n.парамы);
    else
      put("ohne Argumente");
    put(".").nl;
    return n;
  }

  D посети(ДекларацияСтатическогоКонструктора n)
  {
    printLoc(n);
    put(отступ)("Ein statischer Konтктuktor.").nl;
    return n;
  }

  D посети(ДекларацияДеструктора n)
  {
    printLoc(n);
    put(отступ)("Ein Deтктuktor.").nl;
    return n;
  }

  D посети(ДекларацияСтатическогоДеструктора n)
  {
    printLoc(n);
    put(отступ)("Ein statischer Deтктuktor.").nl;
    return n;
  }

  D посети(ДекларацияИнварианта n)
  {
    printLoc(n);
    put(отступ)("Eine Unveränderliche.").nl;
    return n;
  }

  D посети(ДекларацияЮниттеста n)
  {
    printLoc(n);
    put(отступ)("Ein Komponententest.").nl;
    return n;
  }

  Узел посети(Параметр n)
  {
    put.format("'{}' des Typs \"", n.имя ? n.имя.ткт : "unbenannt");
    n.тип && посетиУ(n.тип);
    put("\\");
    return n;
  }

  Узел посети(Параметры n)
  {
    if (n.length > 1)
    {
      посетиУ(n.отпрыски[0]);
      foreach (узел; n.отпрыски[1..$])
        put(", "), посетиУ(узел);
    }
    else
      super.посети(n);
    return n;
  }

  УзелТипа посети(ТипМассив n)
  {
    сим[] c1 = "s", c2 = "";
    if (pluralize)
      (c1 = pointer ? ""[] : "n"), (c2 = "s");
    pointer = нет;
    if (n.ассоцТип)
      put.format("assoziative{} Array{} von ", c1, c2);
//       посетиТ(n.ассоцТип);
    else if (n.e1)
    {
      if (n.e2)
        put.format("gescheibte{} Array{} von ", c1, c2);
      else
        put.format("statische{} Array{} von ", c1, c2);
//       посетиВ(n.в), n.e2 && посетиВ(n.e2);
    }
    else
      put.format("dynamische{} Array{} von ", c1, c2);
    // Типы following массивs should be in plural.
    pluralize = да;
    посетиТ(n.следщ);
    pluralize = нет;
    return n;
  }

  УзелТипа посети(ТипУказатель n)
  {
    сим[] c = pluralize ? (pointer ? ""[] : "n") : "";
    pointer = да;
    put.format("Zeiger{} auf ", c), посетиТ(n.следщ);
    return n;
  }

  УзелТипа посети(КвалифицированныйТип n)
  {
    посетиТ(n.лв);
    put(".");
    посетиТ(n.пв);
    return n;
  }

  УзелТипа посети(ТипИдентификатор n)
  {
    put(n.идент.ткт);
    return n;
  }

  УзелТипа посети(ИнтегральныйТип n)
  {
    сим[] c = pluralize ? "s"[] : "";
    if (n.лекс == TOK.Проц) // Avoid pluralizing "проц "
      c = "";
    put.format("{}{}", n.начало.исхТекст, c);
    return n;
  }
}
