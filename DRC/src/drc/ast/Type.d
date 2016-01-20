/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module drc.ast.Type;

import drc.ast.Node;
import drc.semantic.Types,
       drc.semantic.Symbol;

/// Корневой класс узлов всех типов.
abstract class УзелТипа : Узел
{
  УзелТипа следщ; /// Следующий тип в цепочке типов.
  Тип тип; /// Семантический тип данного узлового типа.
  Символ символ;

  this()
  {
    this(null);
  }

  this(УзелТипа следщ)
  {
    super(КатегорияУзла.Тип);
    добавьОпцОтпрыск(следщ);
    this.следщ = следщ;
  }

  /// Возвращает корневой тип цепочки типов.
  УзелТипа типОснова()
  {
    auto тип = this;
    while (тип.следщ)
      тип = тип.следщ;
    return тип;
  }

  /// Возвращает да, если член 'тип' не null.
  бул естьТип()
  {
    return тип !is null;
  }

  /// Returns да if the член 'символ' is not null.
  бул естьСимвол()
  {
    return символ !is null;
  }

  override abstract УзелТипа копируй();
}
