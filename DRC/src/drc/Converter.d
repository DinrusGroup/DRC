/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module drc.Converter;

import drc.lexer.Funcs;
import drc.Diagnostics;
import drc.Location;
import drc.Unicode;
import drc.FileBOM;
import drc.Messages;
import common;

/// Преобразует различные форматы кодировки Unicode в UTF-8.
struct Преобразователь
{
  сим[] путьКФайлу; /// Для сообщений об ошибках.
  Диагностика диаг;

  static Преобразователь opCall(сим[] путьКФайлу, Диагностика диаг)
  {
    Преобразователь конв;
    конв.путьКФайлу = путьКФайлу;
    конв.диаг = диаг;
    return конв;
  }

  /// Байт-swaps c.
  дим инвертироватьБайты(дим c)
  {
    return c = (c << 24) |
               (c >> 24) |
              ((c >> 8) & 0xFF00) |
              ((c << 8) & 0xFF0000);
  }

  /// Байт-swaps c.
  шим инвертироватьБайты(шим c)
  {
    return (c << 8) | (c >> 8);
  }

  /// Swaps the bytes of c on a little-endian machine.
  дим БЕВМашинноеДслово(дим c)
  {
    version(LittleEndian)
      return инвертироватьБайты(c);
    else
      return c;
  }

  /// Swaps the bytes of c on a big-endian machine.
  дим ЛЕВМашинноеДслово(дим c)
  {
    version(LittleEndian)
      return c;
    else
      return инвертироватьБайты(c);
  }

  /// Swaps the bytes of c on a little-endian machine.
  шим БЕВМашинноеСлово(шим c)
  {
    version(LittleEndian)
      return инвертироватьБайты(c);
    else
      return c;
  }

  /// Swaps the bytes of c on a big-endian machine.
  шим ЛЕВМашинноеСлово(шим c)
  {
    version(LittleEndian)
      return c;
    else
      return инвертироватьБайты(c);
  }

  /// Преобразует текст в UTF-32 в UTF-8.
  сим[] УТФ32вУТФ8(бул БЕ_ли)(ббайт[] данные)
  {
    if (данные.length == 0)
      return null;

    сим[] результат;
    бцел номСтр = 1;
    дим[] текст = cast(дим[]) данные[0 .. $-($%4)]; // Trim в multiple of 4.
    foreach (дим c; текст)
    {
      static if (БЕ_ли)
        c = БЕВМашинноеДслово(c);
      else
        c = ЛЕВМашинноеДслово(c);

      if (!верноСимвол_ли(c))
      {
        диаг ~= new ОшибкаЛексера(
          new Положение(путьКФайлу, номСтр),
          Формат(сооб.НеверныйСимволУТФ32, c)
        );
        c = СИМ_ЗАМЕНЫ;
      }

      if (новСтр_ли(c))
        ++номСтр;
      drc.Unicode.кодируй(результат, c);
    }

    if (данные.length % 4)
      диаг ~= new ОшибкаЛексера(
        new Положение(путьКФайлу, номСтр),
        сооб.ФайлУТФ32ДолженДелитьсяНа4
      );

    return результат;
  }

  alias УТФ32вУТФ8!(да) UTF32BEtoUTF8; /// Instantiation for UTF-32 BE.
  alias УТФ32вУТФ8!(нет) UTF32LEtoUTF8; /// Instantiation for UTF-32 LE.

  /// Converts a UTF-16 текст в UTF-8.
  сим[] УТФ16вУТФ8(бул БЕ_ли)(ббайт[] данные)
  {
    if (данные.length == 0)
      return null;

    шим[] текст = cast(шим[]) данные[0 .. $-($%2)]; // Trim в multiple of two.
    шим* p = текст.ptr,
         конец = текст.ptr + текст.length;
    сим[] результат;
    бцел номСтр = 1;

    for (; p < конец; p++)
    {
      дим c = *p;
      static if (БЕ_ли)
        c = БЕВМашинноеСлово(c);
      else
        c = ЛЕВМашинноеСлово(c);

      if (0xD800 > c || c > 0xDFFF)
      {}
      else if (c <= 0xDBFF && p+1 < конец)
      { // Decode surrogate пары.
        шим c2 = p[1];
        static if (БЕ_ли)
          c2 = БЕВМашинноеСлово(c2);
        else
          c2 = ЛЕВМашинноеСлово(c2);

        if (0xDC00 <= c2 && c2 <= 0xDFFF)
        {
          c = (c - 0xD7C0) << 10;
          c |= (c2 & 0x3FF);
          ++p;
        }
      }
      else
      {
        диаг ~= new ОшибкаЛексера(
          new Положение(путьКФайлу, номСтр),
          Формат(сооб.НеверныйСимволУТФ16, c)
        );
        c = СИМ_ЗАМЕНЫ;
      }

      if (новСтр_ли(c))
        ++номСтр;
      drc.Unicode.кодируй(результат, c);
    }

    if (данные.length % 2)
      диаг ~= new ОшибкаЛексера(
        new Положение(путьКФайлу, номСтр),
        сооб.ФайлУТФ16ДолженДелитьсяНа2
      );
    return результат;
  }

  alias УТФ16вУТФ8!(да) UTF16BEtoUTF8; /// Instantiation for UTF-16 BE.
  alias УТФ16вУТФ8!(нет) UTF16LEtoUTF8; /// Instantiation for UTF-16 LE.

  /// Converts the текст in данные в UTF-8.
  /// Leaves данные unchanged if it is in UTF-8 already.
  сим[] данныеВУТФ8(ббайт[] данные)
  {
    if (данные.length == 0)
      return "";

    сим[] текст;
    МПБ мпб = опишиМПБ(данные);

    switch (мпб)
    {
    case МПБ.Нет:
      // No МПБ found. According в the specs the first character
      // must be an ASCII character.
      if (данные.length >= 4)
      {
        if (данные[0..3] == cast(ббайт[3])x"00 00 00")
        {
          текст = UTF32BEtoUTF8(данные); // UTF-32BE: 00 00 00 XX
          break;
        }
        else if (данные[1..4] == cast(ббайт[3])x"00 00 00")
        {
          текст = UTF32LEtoUTF8(данные); // UTF-32LE: XX 00 00 00
          break;
        }
      }
      if (данные.length >= 2)
      {
        if (данные[0] == 0) // UTF-16BE: 00 XX
        {
          текст = UTF16BEtoUTF8(данные);
          break;
        }
        else if (данные[1] == 0) // UTF-16LE: XX 00
        {
          текст = UTF16LEtoUTF8(данные);
          break;
        }
      }
      текст = cast(сим[])данные; // UTF-8
      break;
    case МПБ.UTF8:
      текст = cast(сим[])данные[3..$];
      break;
    case МПБ.UTF16BE:
      текст = UTF16BEtoUTF8(данные[2..$]);
      break;
    case МПБ.UTF16LE:
      текст = UTF16LEtoUTF8(данные[2..$]);
      break;
    case МПБ.UTF32BE:
      текст = UTF32BEtoUTF8(данные[4..$]);
      break;
    case МПБ.UTF32LE:
      текст = UTF32LEtoUTF8(данные[4..$]);
      break;
    default:
      assert(0);
    }
    return текст;
  }
}

/// Replaces invalid UTF-8 sequences with U+FFFD (if there's enough space,)
/// and Newlines with '\n'.
сим[] обеззаразьТекст(сим[] текст)
{
  if (!текст.length)
    return null;

  сим* p = текст.ptr; // Reader.
  сим* конец = p + текст.length;
  сим* q = p; // Writer.

  for (; p < конец; p++, q++)
  {
    assert(q <= p);
    if (аски_ли(*p)) {
      *q = *p; // Just копируй ASCII characters.
      continue;
    }
    switch (*p)
    {
    case '\r':
      if (p+1 < конец && p[1] == '\n')
        p++;
    case '\n':
      *q = '\n'; // Copy newlines as '\n'.
      continue;
    default:
      if (p+2 < конец && новСтрЮ_ли(p))
      {
        p += 2;
        goto case '\n';
      }

      auto p2 = p; // Remember beginning of the UTF-8 sequence.
      дим c = раскодируй(p, конец);

      if (c == СИМ_ОШИБКИ)
      { // Skip в следщ ASCII character or valid UTF-8 sequence.
        while (++p < конец && ведомыйБайт_ли(*p))
        {}
        alias СТР_ЗАМЕНЫ R;
        if (q+2 < p) // Copy replacement сим if there is enough space.
          (*q = R[0]), (*++q = R[1]), (*++q = R[2]);
        p--;
      }
      else
      { // Copy the valid UTF-8 sequence.
        while (p2 < p) // p points в one past the last trail байт.
          *q++ = *p2++; // Copy код units.
        q--;
        p--;
      }
    }
  }
  assert(p == конец);
  текст.length = q - текст.ptr;
  return текст;
}

unittest
{
  выдай("Testing function Преобразователь.\n");
  struct Data2Text
  {
    сим[] текст;
    сим[] ожидаемое = "source";
    ббайт[] данные()
    { return cast(ббайт[])текст; }
  }
  const Data2Text[] карта = [
    // Without МПБ
    {"source"},
    {"s\0o\0u\0r\0c\0e\0"},
    {"\0s\0o\0u\0r\0c\0e"},
    {"s\0\0\0o\0\0\0u\0\0\0r\0\0\0c\0\0\0e\0\0\0"},
    {"\0\0\0s\0\0\0o\0\0\0u\0\0\0r\0\0\0c\0\0\0e"},
    // Для МПБ
    {"\xEF\xBB\xBFsource"},
    {"\xFE\xFF\0s\0o\0u\0r\0c\0e"},
    {"\xFF\xFEs\0o\0u\0r\0c\0e\0"},
    {"\x00\x00\xFE\xFF\0\0\0s\0\0\0o\0\0\0u\0\0\0r\0\0\0c\0\0\0e"},
    {"\xFF\xFE\x00\x00s\0\0\0o\0\0\0u\0\0\0r\0\0\0c\0\0\0e\0\0\0"},
  ];
  auto конвертер = Преобразователь("", new Диагностика);
  foreach (i, пара; карта)
    assert(конвертер.данныеВУТФ8(пара.данные) == пара.ожидаемое, Формат("failed at item {}", i));
}
