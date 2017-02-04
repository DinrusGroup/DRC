/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.semantic.SymbolTable;

import drc.semantic.Symbol;
import drc.lexer.Identifier;
import common;

/// Помещает идентификатор типа ткст в Символ.
struct ТаблицаСимволов
{
  Символ[сим[]] таблица; /// Структура таблицы данных.

  /// Ищет идент в таблице.
  /// Возвращает: символ, если он там имеется, либо null.
  Символ сыщи(Идентификатор* идент)
  {
    assert(идент !is null);
    auto psym = идент.ткт in таблица;
    return psym ? *psym : null;
  }

  /// Вставляет символ в таблицу.
  проц  вставь(Символ символ, Идентификатор* идент)
  {
    таблица[идент.ткт] = символ;
  }
}
