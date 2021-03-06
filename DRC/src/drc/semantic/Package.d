/// Author: Aziz Köksal, Vitaly Kulich
/// License: GPL3
/// $(Maturity average)
module drc.semantic.Package;

import drc.semantic.Symbol,
       drc.semantic.Symbols,
       drc.semantic.Module;
import drc.lexer.IdTable;
import common;

/// Пакет группирует модули и другие пакеты.
class Пакет : СимволМасштаба
{
  ткст имяПкт;    /// Имя данного пакета. Напр.: 'drc'.
  Пакет[] пакеты; /// Суб-пакеты, входящие в этот пакет.
  Модуль[] модули;   /// Модули, входящие в этот пакет.

  /// Строит Пакет объект.
  this(ткст имяПкт)
  {
    auto идент = ТаблицаИд.сыщи(имяПкт);
    super(СИМ.Пакет, идент, пусто);
    this.имяПкт = имяПкт;
  }

  /// Возвращает да, если является корневым пакетом.
  бул корень()
  {
    return родитель is пусто;
  }

  /// Возвращает родительский пакет или пусто, если это корень.
  Пакет пакетРодитель()
  {
    if (корень())
      return пусто;
    assert(родитель.Пакет_ли);
    return родитель.в!(Пакет);
  }

  /// Добавляет модуль в этот пакет.
  проц  добавь(Модуль модуль)
  {
    модуль.родитель = this;
    модули ~= модуль;
    вставь(модуль, модуль.имя);
  }

  /// Добавляет пакет в этот пакет.
  проц  добавь(Пакет пкт)
  {
    пкт.родитель = this;
    пакеты ~= пкт;
    вставь(пкт, пкт.имя);
  }
}
