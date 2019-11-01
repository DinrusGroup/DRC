/// Author: Aziz Köksal, Vitaly Kulich
/// License: GPL3
/// $(Maturity very high)
module drc.ast.Statement;

import drc.ast.Node;

/// Корневой класс всех инструкций.
abstract class Инструкция : Узел
{
  this()
  {
    super(КатегорияУзла.Инструкция);
  }

  override abstract Инструкция копируй();
}
