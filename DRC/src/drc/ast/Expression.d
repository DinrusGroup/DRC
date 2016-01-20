/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module drc.ast.Expression;

import drc.ast.Node;
import drc.semantic.Types,
       drc.semantic.Symbol;
import common;

/// Корневой классс всех выражений.
abstract class Выражение : Узел
{
  Тип тип; /// Семантический тип данного выражения.
  Символ символ;

  this()
  {
    super(КатегорияУзла.Выражение);
  }

  /// Returns да if the член 'тип' is not null.
  бул естьТип()
  {
    return тип !is null;
  }

  /// Returns да if the член 'символ' is not null.
  бул естьСимвол()
  {
    return символ !is null;
  }

  override abstract Выражение копируй();
}
