/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity average)
module drc.semantic.Symbol;

import drc.ast.Node;
import drc.lexer.Identifier;
import common;

/// Enumeration of Символ IDs.
enum СИМ
{
  Модуль,
  Пакет,
  Класс,
  Интерфейс,
  Структура,
  Союз,
  Перечень,
  ЧленПеречня,
  Шаблон,
  Переменная,
  Функция,
  Алиас,
  НаборПерегрузки,
  Масштаб,
//   Тип,
}

/// A символ represents an object with semantic код information.
class Символ
{ /// Enumeration of символ statuses.
  enum Состояние : бкрат
  {
    Объявлен,   /// The символ has been declared.
    Обрабатывается, /// The символ is being processed.
    Обработан    /// The символ is complete.
  }

  СИМ сид; /// The ID of this символ.
  Состояние состояние; /// The semantic состояние of this символ.
  Символ родитель; /// The родитель this символ belongs в.
  Идентификатор* имя; /// The имя of this символ.
  /// The syntax tree узел that produced this символ.
  /// Useful for source код положение инфо and retriоцени of doc comments.
  Узел узел;

  /// Constructs a Символ object.
  /// Параметры:
  ///   сид = the символ's ID.
  ///   имя = the символ's имя.
  ///   узел = the символ's узел.
  this(СИМ сид, Идентификатор* имя, Узел узел)
  {
    this.сид = сид;
    this.имя = имя;
    this.узел = узел;
  }

  /// Change the состояние в Состояние.Обрабатывается.
  проц  устОбрабатывается()
  { состояние = Состояние.Обрабатывается; }

  /// Change the состояние в Состояние.Обработан.
  проц  устОбработан()
  { состояние = Состояние.Обработан; }

  /// Returns да if the символ is being completed.
  бул обрабатывается_ли()
  { return состояние == Состояние.Обрабатывается; }

  /// Returns да if the символы is complete.
  бул обработан_ли()
  { return состояние == Состояние.Обработан; }

  /// A template macro for building isXYZ() methods.
  private template isX(сим[] вид)
  {
    const сим[] isX = `бул `~вид~`_ли(){ return сид == СИМ.`~вид~`; }`;
  }
  mixin(isX!("Модуль"));
  mixin(isX!("Пакет"));
  mixin(isX!("Класс"));
  mixin(isX!("Интерфейс"));
  mixin(isX!("Структура"));
  mixin(isX!("Союз"));
  mixin(isX!("Перечень"));
  mixin(isX!("ЧленПеречня"));
  mixin(isX!("Шаблон"));
  mixin(isX!("Переменная"));
  mixin(isX!("Функция"));
  mixin(isX!("Алиас"));
  mixin(isX!("НаборПерегрузки"));
  mixin(isX!("Масштаб"));
//   mixin(isX!("Тип"));

  /// Casts the символ в Класс.
  Класс в(Класс)()
  {
    assert(mixin(`this.сид == mixin("СИМ." ~ Класс.stringof)`));
    return cast(Класс)cast(ук)this;
  }

  /// Возвращает: the fully qualified имя of this символ.
  /// E.g.: drc.semantic.Symbol.Символ.дайПКН
  сим[] дайПКН()
  {
    if (!имя)
      return родитель ? родитель.дайПКН() : "";
    if (родитель)
      return родитель.дайПКН() ~ '.' ~ имя.ткт;
    return имя.ткт;
  }
}
