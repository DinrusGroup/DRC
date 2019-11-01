/// Author: Aziz Köksal, Vitaly Kulich
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
  /// Возвращает: символ, если он там имеется, либо пусто.
  Символ сыщи(Идентификатор* идент)
  {
    assert(идент !is пусто);
    auto psym = идент.ткт in таблица;
    return psym ? *psym : пусто;
  }

  /// Вставляет символ в таблицу.
  проц  вставь(Символ символ, Идентификатор* идент)
  {
    таблица[идент.ткт] = символ;
  }
}
