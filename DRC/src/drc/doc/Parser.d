/// Author: Aziz Köksal, Vitaly Kulich
/// License: GPL3
/// $(Maturity very high)
module drc.doc.Parser;

import drc.lexer.Funcs;
import drc.Unicode;
import common;

/// Пара из ткст.
class ЗначениеИдентификатора
{
  ткст идент;
  ткст значение;
  this (ткст идент, ткст значение)
  {
    this.идент = идент;
    this.значение = значение;
  }
}

/// Разбирает текст в форме:
/// <pre>
/// идент = значение
/// ident2 = значение2
///          ешё текст
/// </pre>
struct ПарсерЗначенияИдентификатора
{
  сим* у; /// Текущий указатель.
  сим* конецТекста;

  /// Разбирает текст на список из IdentValues.
  /// Все newlines в тексте должны быть преобразованы в '\n'.
  ЗначениеИдентификатора[] разбор(ткст текст)
  {
    if (!текст.length)
      return пусто;

    у = текст.ptr;
    конецТекста = у + текст.length;

    ЗначениеИдентификатора[] идзначения;

    ткст идент, следщИдент;
    сим* началоТела = у, началоСледщТела;

    // Init.
    найдиСледщИдент(идент, началоТела);
    // Далее.
    while (найдиСледщИдент(следщИдент, началоСледщТела))
    {
      идзначения ~= new ЗначениеИдентификатора(идент, телоТекста(началоТела, следщИдент.ptr));
      идент = следщИдент;
      началоТела = началоСледщТела;
    }
    // Add last идент значение.
    идзначения ~= new ЗначениеИдентификатора(идент, телоТекста(началоТела, конецТекста));
    return идзначения;
  }

  /// Убирает вводные и замыкающие пробельные символы.
  /// Возвращает: тело текста или пусто, если там пусто.
  static сим[] телоТекста(сим* начало, сим* конец)
  {
    while (начало < конец && (пбел(*начало) || *начало == '\n'))
      начало++;
    // Тело атр является пустым, когда напр.:
    // атр =
    // постр = какой-н. текст
    // ^- точка начала и конеца в постр (или в this.конецТекста во 2-м случае.)
    if (начало is конец)
      return пусто;
    // Убрать замыкающий пробел.
    while (пбел(*--конец) || *конец == '\n')
    {}
    конец++;
    return сделайТекст(начало, конец);
  }

  /// Находит следщ "Идентификатор =".
  /// Параметры:
  ///   идент = установка в Идентификатор.
  ///   началоТела = установка на начало тела текста (пробел пропускается.)
  /// Возвращает: да, если найден.
  бул найдиСледщИдент(ref ткст идент, ref сим* началоТела)
  {
    while (у < конецТекста)
    {
      пропустиПробельные();
      if (у is конецТекста)
        break;
      assert(у < конецТекста && (аски(*у) || ведущийБайт(*у)));
      идент = сканируйИдентификатор(у, конецТекста);
      пропустиПробельные();
      if (идент && у < конецТекста && *у == '=')
      {
        началоТела = ++у;
        пропустиСтроку();
        return да;
      }
      пропустиСтроку();
    }
    assert(у is конецТекста);
    return нет;
  }

  проц  пропустиПробельные()
  {
    while (у < конецТекста && пбел(*у))
      у++;
  }

  проц  пропустиСтроку()
  {
    while (у < конецТекста && *у != '\n')
      у++;
    while (у < конецТекста && *у == '\n')
      у++;
  }
}

/// Возвращает срез текста в диапазоне от начало до конец.
сим[] сделайТекст(сим* начало, сим* конец)
{
  assert(начало && конец && начало <= конец);
  return начало[0 .. конец - начало];
}

unittest
{
  выдай("Тестируем drc.doc.Parser.\n");
  сим[] текст = "атр =
постр = текст
к =
 <b>текст</b>
  D = $(LINK www.drc.com)
E=<
ф = G = H
Äş=??
A6İ=µ
Конец=";

  ЗначениеИдентификатора iv(ткст s1, ткст s2)
  {
    return new ЗначениеИдентификатора(s1, s2);
  }

  auto results = [
    iv("атр", ""),
    iv("постр", "текст"),
    iv("к", "<b>текст</b>"),
    iv("D", "$(LINK www.drc.com)"),
    iv("E", "<"),
    iv("ф", "G = H"),
    iv("Äş", "??"),
    iv("A6İ", "µ"),
    iv("Конец", ""),
  ];

  auto парсер = ПарсерЗначенияИдентификатора();
  foreach (i, parsed; парсер.разбор(текст))
  {
    auto ожидаемое = results[i];
    assert(parsed.идент == ожидаемое.идент,
           Формат("Парсирован идент '{}', но ожидался '{}'.",
                  parsed.идент, ожидаемое.идент));
    assert(parsed.значение == ожидаемое.значение,
           Формат("Парсировано значение '{}', но ожидался '{}'.",
                  parsed.значение, ожидаемое.значение));
  }
}
