/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module drc.FileBOM;

import common;

//МПБ имеется в base. Но порядок несколько иной.
//Предполагается, что ничего неприятного от этого не будет(???)
/*
/// Перечень меток порядка байтов (BOM).
enum МПБ
{
  Нет,    /// Nет МПБ
  Ю8,    /// UTF-8: EF BB BF
  Ю16БЕ, /// UTF-16 Big Endian: FE FF
  Ю16ЛЕ, /// UTF-16 Little Endian: FF FE
  Ю32БЕ, /// UTF-32 Big Endian: 00 00 FE FF
  Ю32ЛЕ  /// UTF-32 Little Endian: FF FE 00 00
}
*/
/// Просматривает первые байты данных и возвращает соответствующую МПБ.
МПБ опишиМПБ(ббайт[] данные)
{
  МПБ мпб = МПБ.Нет;
  if (данные.length < 2)
    return мпб;

  if (данные[0..2] == cast(ббайт[2])x"FE FF")
  {
    мпб = МПБ.Ю16БЕ; // FE FF
  }
  else if (данные[0..2] == cast(ббайт[2])x"FF FE")
  {
    if (данные.length >= 4 && данные[2..4] == cast(ббайт[2])x"00 00")
      мпб = МПБ.Ю32ЛЕ; // FF FE 00 00
    else
      мпб = МПБ.Ю16ЛЕ; // FF FE XX XX
  }
  else if (данные[0..2] == cast(ббайт[2])x"00 00")
  {
    if (данные.length >= 4 && данные[2..4] == cast(ббайт[2])x"FE FF")
      мпб = МПБ.Ю32БЕ; // 00 00 FE FF
  }
  else if (данные[0..2] ==  cast(ббайт[2])x"EF BB")
  {
    if (данные.length >= 3 && данные[2] == '\xBF')
      мпб =  МПБ.Ю8; // EF BB BF
  }
  return мпб;
}

unittest
{
  выдай("Testing function опишиМПБ().\n");

  struct Data2МПБ
  {
    ббайт[] данные;
    МПБ мпб;
  }
  alias ббайт[] бб;
  const Data2МПБ[] карта = [
    {cast(бб)x"12",          МПБ.Нет},
    {cast(бб)x"12 34",       МПБ.Нет},
    {cast(бб)x"00 00 FF FE", МПБ.Нет},
    {cast(бб)x"EF BB FF",    МПБ.Нет},

    {cast(бб)x"EF",          МПБ.Нет},
    {cast(бб)x"EF BB",       МПБ.Нет},
    {cast(бб)x"FE",          МПБ.Нет},
    {cast(бб)x"FF",          МПБ.Нет},
    {cast(бб)x"00",          МПБ.Нет},
    {cast(бб)x"00 00",       МПБ.Нет},
    {cast(бб)x"00 00 FE",    МПБ.Нет},

    {cast(бб)x"FE FF 00",    МПБ.Ю16БЕ},
    {cast(бб)x"FE FF 00 FF", МПБ.Ю16БЕ},

    {cast(бб)x"EF BB BF",    МПБ.Ю8},
    {cast(бб)x"FE FF",       МПБ.Ю16БЕ},
    {cast(бб)x"FF FE",       МПБ.Ю16ЛЕ},
    {cast(бб)x"00 00 FE FF", МПБ.Ю32БЕ},
    {cast(бб)x"FF FE 00 00", МПБ.Ю32ЛЕ}
  ];

  foreach (пара; карта)
    assert(опишиМПБ(пара.данные) == пара.мпб, Формат("Сбой на {0}", пара.данные));
}
