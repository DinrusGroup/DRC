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

  /// Возвращает да, если член 'тип' не равен пусто.
  бул естьТип()
  {
    return тип !is пусто;
  }

  /// Возвращает да, если член 'символ' не равен пусто.
  бул естьСимвол()
  {
    return символ !is пусто;
  }

  override abstract Выражение копируй();
}
