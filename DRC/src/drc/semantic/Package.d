/// Author: Aziz Köksal, Vitaly Kulich
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
  ткст имяПкт;    /// The имя of the package. Напр.: 'dil'.
  Пакет[] пакеты; /// The sub-пакеты contained in this package.
  Модуль[] модули;   /// The модули contained in this package.

  /// Строит Пакет объект.
  this(ткст имяПкт)
  {
    auto идент = ТаблицаИд.сыщи(имяПкт);
    super(СИМ.Пакет, идент, пусто);
    this.имяПкт = имяПкт;
  }

  /// Возвращает да, если является the корень package.
  бул корень()
  {
    return родитель is пусто;
  }

  /// Возвращает родитель package или пусто if this is the корень.
  Пакет пакетРодитель()
  {
    if (корень())
      return пусто;
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
