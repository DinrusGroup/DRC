/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity average)
module drc.semantic.Package;

import drc.semantic.Symbol,
       drc.semantic.Symbols,
       drc.semantic.Module;
import drc.lexer.IdTable;
import common;

/// A package groups модули and другой пакеты.
class Пакет : СимволМасштаба
{
  ткст имяПкт;    /// The имя of the package. E.g.: 'dil'.
  Пакет[] пакеты; /// The sub-пакеты contained in this package.
  Модуль[] модули;   /// The модули contained in this package.

  /// Строит Пакет объект.
  this(ткст имяПкт)
  {
    auto идент = ТаблицаИд.сыщи(имяПкт);
    super(СИМ.Пакет, идент, null);
    this.имяПкт = имяПкт;
  }

  /// Возвращает да, если из_ the корень package.
  бул корень_ли()
  {
    return родитель is null;
  }

  /// Возвращает родитель package or null if this is the корень.
  Пакет пакетРодитель()
  {
    if (корень_ли())
      return null;
    assert(родитель.Пакет_ли);
    return родитель.в!(Пакет);
  }

  /// Добавляет module в this package.
  проц  добавь(Модуль модуль)
  {
    модуль.родитель = this;
    модули ~= модуль;
    вставь(модуль, модуль.имя);
  }

  /// Добавляет package в this package.
  проц  добавь(Пакет пкт)
  {
    пкт.родитель = this;
    пакеты ~= пкт;
    вставь(пкт, пкт.имя);
  }
}
