/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity average)
module drc.semantic.Scope;

import drc.semantic.Symbol,
       drc.semantic.Symbols;
import drc.lexer.Identifier;
import common;


/// Выполняет построение иерархии сред.
class Масштаб
{
  Масштаб родитель; /// The surrounding Масштаб, or null if this is the корень Масштаб.

  СимволМасштаба символ; /// The current символ with the символ таблица.

  this(Масштаб родитель, СимволМасштаба символ)
  {
    this.родитель = родитель;
    this.символ = символ;
  }

  /// Find a символ in this Масштаб.
  /// Параметры:
  ///   имя = the имя of the символ.
  Символ сыщи(Идентификатор* имя)
  {
    return символ.сыщи(имя);
  }

  /// Searches for a символ in this Масштаб and all включающий scopes.
  /// Параметры:
  ///   имя = the имя of the символ.
  Символ ищи(Идентификатор* имя)
  {
    Символ символ;
    for (auto sc = this; sc; sc = sc.родитель)
    {
      символ = sc.сыщи(имя);
      if (символ !is null)
        break;
    }
    return символ;
  }

  /// Searches for a символ in this Масштаб and all включающий scopes.
  /// Параметры:
  ///   имя = the имя of the символ.
  ///   ignoreSymbol = the символ that must be пропустиped.
  Символ ищи(Идентификатор* имя, Символ ignoreSymbol)
  {
    Символ символ;
    for (auto sc = this; sc; sc = sc.родитель)
    {
      символ = sc.сыщи(имя);
      if (символ !is null && символ !is ignoreSymbol)
        break;
    }
    return символ;
  }

  /// Create a new inner Масштаб and return that.
  Масштаб войдиВ(СимволМасштаба символ)
  {
    return new Масштаб(this, символ);
  }

  /// Destroy this Масштаб and return the outer Масштаб.
  Масштаб выход()
  {
    auto sc = родитель;
    // delete this;
    return sc;
  }

  /// Находит Масштаб включающего Класса.
  Масштаб масштабКласса()
  {
    auto масш = this;
    do
    {
      if (масш.символ.Класс_ли)
        return масш;
      масш = масш.родитель;
    } while (масш)
    return null;
  }

  /// Находит Масштаб включающего Модуля.
  Масштаб масштабМодуля()
  {
    auto масш = this;
    do
    {
      if (масш.символ.Модуль_ли)
        return масш;
      масш = масш.родитель;
    } while (масш)
    return null;
  }
}
