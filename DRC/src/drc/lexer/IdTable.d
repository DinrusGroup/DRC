/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.lexer.IdTable;

import drc.lexer.TokensEnum,
       drc.lexer.IdentsGenerator,
       drc.lexer.Keywords;
import common;

public import drc.lexer.Identifier,
              drc.lexer.IdentsEnum;

/// Неймспейс для предопределенных идентификаторов.
struct Идент
{
  const static
  {
    mixin(генерируйЧленыИдент());
  }

  /// Возвращает массив предопределенных идентификаторов.
  static Идентификатор*[] всеИды()
  {
    return __allIds;
  }
}

/// Глобальная таблица для размещения и получения идентификаторов.
struct ТаблицаИд
{
static:
  /// Набор общих, предопределенных идентификаторов для быстрых поисков.
  private Идентификатор*[ткст] статическаяТаблица;
  /// Таблица, растущая с каждым новым уникальным идентификатором.
  private Идентификатор*[ткст] растущаяТаблица;

  /// Загружает ключевые слова и предопределенные идентификаторы в статическую таблицу.
  static this()
  {
    foreach (ref k; g_reservedIds)
      статическаяТаблица[k.ткт] = &k;
    foreach (ид; Идент.всеИды())
      статическаяТаблица[ид.ткт] = ид;
    статическаяТаблица.rehash;
  }

  /// Ищет ткстИда в обеих таблицах.
  Идентификатор* сыщи(ткст ткстИда)
  {
    auto ид = вСтатической(ткстИда);
    if (ид)
      return ид;
    return вРастущей(ткстИда);
  }

  /// Ищет ткстИда в статической таблице.
  Идентификатор* вСтатической(ткст ткстИда)
  {
    auto ид = ткстИда in статическаяТаблица;
    return ид ? *ид : null;
  }

  alias Идентификатор* function(ткст ткстИда) ФункцияПоиска;
  /// Ищет ткстИда в растущей таблице.
  ФункцияПоиска вРастущей = &_inGrowing_unsafe; // Дефолт на небезопасную функцию.

  /// Устанавливает режим безопасности нити для растущей таблицы.
  проц  установиНитебезопасность(бул b)
  {
    if (b)
      вРастущей = &_inGrowing_safe;
    else
      вРастущей = &_inGrowing_unsafe;
  }

  /// Возвращает да, если доступ к растущей таблице нитебезопасен.
  бул нитебезопасно_ли()
  {
    return вРастущей is &_inGrowing_safe;
  }

  /// Ищет ткстИда в таблице.
  ///
  /// Adds ткстИда в the таблица if not found.
  private Идентификатор* _inGrowing_unsafe(ткст ткстИда)
  out(ид)
  { assert(ид !is null); }
  body
  {
    auto ид = ткстИда in растущаяТаблица;
    if (ид)
      return *ид;
    auto newID = Идентификатор(ткстИда, TOK.Идентификатор);
    растущаяТаблица[ткстИда] = newID;
    return newID;
  }

  /// Looks up ткстИда in the таблица.
  ///
  /// Adds ткстИда в the таблица if not found.
  /// Access в the данные structure is synchronized.
  private Идентификатор* _inGrowing_safe(ткст ткстИда)
  {
    synchronized
      return _inGrowing_unsafe(ткстИда);
  }

  /+
  Идентификатор* addIdentifiers(сим[][] idStrings)
  {
    auto ids = new Идентификатор*[idStrings.length];
    foreach (i, ткстИда; idStrings)
    {
      Идентификатор** ид = ткстИда in tabulatedIds;
      if (!ид)
      {
        auto newID = Идентификатор(TOK.Идентификатор, ткстИда);
        tabulatedIds[ткстИда] = newID;
        ид = &newID;
      }
      ids[i] = *ид;
    }
  }
  +/

  static бцел anonCount; /// Counter for anonymous identifiers.

  /// Generates an anonymous identifier.
  ///
  /// Concatenates prefix with anonCount.
  /// The identifier is not inserted into the таблица.
  Идентификатор* genAnonymousID(ткст prefix)
  {
    ++anonCount;
    auto x = anonCount;
    // Convert счёт в a ткст and добавь it в ткт.
    сим[] чис;
    do
      чис = cast(сим)('0' + (x % 10)) ~ чис;
    while (x /= 10)
    return Идентификатор(prefix ~ чис, TOK.Идентификатор);
  }

  /// Generates an identifier for an anonymous enum.
  Идентификатор* генИДАнонПеречня()
  {
    return genAnonymousID("__anonenum");
  }

  /// Generates an identifier for an anonymous class.
  Идентификатор* genAnonClassID()
  {
    return genAnonymousID("__anonclass");
  }

  /// Generates an identifier for an anonymous struct.
  Идентификатор* genAnonStructID()
  {
    return genAnonymousID("__anonstruct");
  }

  /// Generates an identifier for an anonymous union.
  Идентификатор* genAnonUnionID()
  {
    return genAnonymousID("__anonunion");
  }

  /// Generates an identifier for a module which has got no valid имя.
  Идентификатор* генИдМодуля()
  {
    return genAnonymousID("__module");
  }
}

unittest
{
  // TODO: пиши benchmark.
  // Single таблица

  // Single таблица. synchronized

  // Two tables.

  // Two tables. synchronized
}
