/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module drc.ast.Statement;

import drc.ast.Node;

/// The корень class of all инструкции.
abstract class Инструкция : Узел
{
  this()
  {
    super(КатегорияУзла.Инструкция);
  }

  override abstract Инструкция копируй();
}
