/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module drc.Unicode;

import util.uni : униАльфа_ли;

/// U+FFFD = �. Используется для замены неверных символов Unicode.
const дим СИМ_ЗАМЕНЫ = '\uFFFD';
const сим[3] СТР_ЗАМЕНЫ = \uFFFD; /// Ditto
/// Неверный символ, возвращается при ошибке.
const дим СИМ_ОШИБКИ = 0xD800;

/// Возвращает: да if this character is not a surrogate
/// код point and not higher than 0x10FFFF.
бул верноСимвол_ли(дим d)
{
  return d < 0xD800 || d > 0xDFFF && d <= 0x10FFFF;
}

/// There are a всего of 66 noncharacters.
/// Возвращает: да if this is one of them.
/// See_also: Chapter 16.7 Noncharacters in Unicode 5.0
бул неСимвол_ли(дим d)
{
  return 0xFDD0 <= d && d <= 0xFDEF || // 32
         d <= 0x10FFFF && (d & 0xFFFF) >= 0xFFFE; // 34
}

/// Возвращает: да if this is a trail байт of a UTF-8 sequence.
бул ведомыйБайт_ли(ббайт b)
{
  return (b & 0xC0) == 0x80; // 10xx_xxxx
}

/// Возвращает: да if this is a lead байт of a UTF-8 sequence.
бул ведущийБайт_ли(ббайт b)
{
  return (b & 0xC0) == 0xC0; // 11xx_xxxx
}

/// Advances ref_p only if this is a valid Unicode alpha character.
/// Параметры:
///   ref_p = установи в the last trail байт of the valid UTF-8 sequence.
бул юАльфа_ли(ref сим* ref_p, сим* конец)
in { assert(ref_p && ref_p < конец); }
body
{
  if (*ref_p < 0x80)
    return нет;
  auto p = ref_p;
  auto c = раскодируй(p, конец);
  if (!униАльфа_ли(c))
    return нет;
  ref_p = p-1; // Subtract 1 because of раскодируй().
  return да;
}

/// Decodes a character из ткт at индекс.
/// Параметры:
///   индекс = установи в one past the ASCII сим or one past the last trail байт
///           of the valid UTF-8 sequence.
дим раскодируй(сим[] ткт, ref т_мера индекс)
in { assert(ткт.length && индекс < ткт.length); }
out { assert(индекс <= ткт.length); }
body
{
  сим* p = ткт.ptr + индекс;
  сим* конец = ткт.ptr + ткт.length;
  дим c = раскодируй(p, конец);
  if (c != СИМ_ОШИБКИ)
    индекс = p - ткт.ptr;
  return c;
}

/// Decodes a character starting at ref_p.
/// Параметры:
///   ref_p = установи в one past the ASCII сим or one past the last trail байт
///           of the valid UTF-8 sequence.
дим раскодируй(ref сим* ref_p, сим* конец)
in { assert(ref_p && ref_p < конец); }
out(c) { assert(ref_p <= конец && (верноСимвол_ли(c) || c == СИМ_ОШИБКИ)); }
body
{
  сим* p = ref_p;
  дим c = *p;

  if (c < 0x80)
    return ref_p++, c;

  p++; // Move в second байт.
  if (!(p < конец))
    return СИМ_ОШИБКИ;

  // Ошибка if second байт is not a trail байт.
  if (!ведомыйБайт_ли(*p))
    return СИМ_ОШИБКИ;

  // Check for overlong sequences.
  switch (c)
  {
  case 0xE0, // 11100000 100xxxxx
       0xF0, // 11110000 1000xxxx
       0xF8, // 11111000 10000xxx
       0xFC: // 11111100 100000xx
    if ((*p & c) == 0x80)
      return СИМ_ОШИБКИ;
  default:
    if ((c & 0xFE) == 0xC0) // 1100000x
      return СИМ_ОШИБКИ;
  }

  const сим[] проверьСледующийБайт = "if (!(++p < конец && ведомыйБайт_ли(*p)))"
                                "  return СИМ_ОШИБКИ;";
  const сим[] добавьШестьБит = "c = (c << 6) | *p & 0b0011_1111;";

  // Decode
  if ((c & 0b1110_0000) == 0b1100_0000)
  {
    // 110xxxxx 10xxxxxx
    c &= 0b0001_1111;
    mixin(добавьШестьБит);
  }
  else if ((c & 0b1111_0000) == 0b1110_0000)
  {
    // 1110xxxx 10xxxxxx 10xxxxxx
    c &= 0b0000_1111;
    mixin(добавьШестьБит ~
          проверьСледующийБайт ~ добавьШестьБит);
  }
  else if ((c & 0b1111_1000) == 0b1111_0000)
  {
    // 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
    c &= 0b0000_0111;
    mixin(добавьШестьБит ~
          проверьСледующийБайт ~ добавьШестьБит ~
          проверьСледующийБайт ~ добавьШестьБит);
  }
  else
    // 5 and 6 байт UTF-8 sequences are not allowed yet.
    // 111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
    // 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
    return СИМ_ОШИБКИ;

  assert(ведомыйБайт_ли(*p));

  if (!верноСимвол_ли(c))
    return СИМ_ОШИБКИ;
  ref_p = p+1;
  return c;
}

/// Кодирует символ и прибавляет его к ткт.
проц  кодируй(ref сим[] ткт, дим c)
{
  assert(верноСимвол_ли(c), "check if character is valid before calling кодируй().");

  сим[6] b = void;
  if (c < 0x80)
    ткт ~= c;
  else if (c < 0x800)
  {
    b[0] = 0xC0 | (c >> 6);
    b[1] = 0x80 | (c & 0x3F);
    ткт ~= b[0..2];
  }
  else if (c < 0x10000)
  {
    b[0] = 0xE0 | (c >> 12);
    b[1] = 0x80 | ((c >> 6) & 0x3F);
    b[2] = 0x80 | (c & 0x3F);
    ткт ~= b[0..3];
  }
  else if (c < 0x200000)
  {
    b[0] = 0xF0 | (c >> 18);
    b[1] = 0x80 | ((c >> 12) & 0x3F);
    b[2] = 0x80 | ((c >> 6) & 0x3F);
    b[3] = 0x80 | (c & 0x3F);
    ткт ~= b[0..4];
  }
  /+ // There are no 5 and 6 байт UTF-8 sequences yet.
  else if (c < 0x4000000)
  {
    b[0] = 0xF8 | (c >> 24);
    b[1] = 0x80 | ((c >> 18) & 0x3F);
    b[2] = 0x80 | ((c >> 12) & 0x3F);
    b[3] = 0x80 | ((c >> 6) & 0x3F);
    b[4] = 0x80 | (c & 0x3F);
    ткт ~= b[0..5];
  }
  else if (c < 0x80000000)
  {
    b[0] = 0xFC | (c >> 30);
    b[1] = 0x80 | ((c >> 24) & 0x3F);
    b[2] = 0x80 | ((c >> 18) & 0x3F);
    b[3] = 0x80 | ((c >> 12) & 0x3F);
    b[4] = 0x80 | ((c >> 6) & 0x3F);
    b[5] = 0x80 | (c & 0x3F);
    ткт ~= b[0..6];
  }
  +/
  else
    assert(0);
}

/// Кодирует символ и прибавляет его к ткт.
проц  кодируй(ref шим[] ткт, дим c)
in { assert(верноСимвол_ли(c)); }
body
{
  if (c < 0x10000)
    ткт ~= cast(шим)c;
  else
  { // Encode with surrogate пара.
    шим[2] пара = void;
    c -= 0x10000; // c'
    // higher10bits(c') | 0b1101_10xx_xxxx_xxxx
    пара[0] = (c >> 10) | 0xD800;
    // lower10bits(c') | 0b1101_11yy_yyyy_yyyy
    пара[1] = (c & 0x3FF) | 0xDC00;
    ткт ~= пара;
  }
}

/// Decodes a character из a UTF-16 sequence.
/// Параметры:
///   ткт = the UTF-16 sequence.
///   индекс = where в старт из.
/// Возвращает: СИМ_ОШИБКИ in case of an ошибка in the sequence.
дим раскодируй(шим[] ткт, ref т_мера индекс)
{
  assert(ткт.length && индекс < ткт.length);
  дим c = ткт[индекс];
  if (0xD800 > c || c > 0xDFFF)
  {
    ++индекс;
    return c;
  }
  if (c <= 0xDBFF && индекс+1 != ткт.length)
  {
    шим c2 = ткт[индекс+1];
    if (0xDC00 <= c2 && c2 <= 0xDFFF)
    { // Decode surrogate пара.
      // (c - 0xD800) << 10 + 0x10000 ->
      // (c - 0xD800 + 0x40) << 10 ->
      c = (c - 0xD7C0) << 10;
      c |= (c2 & 0x3FF);
      индекс += 2;
      return c;
    }
  }
  return СИМ_ОШИБКИ;
}

/// Decodes a character из a UTF-16 sequence.
/// Параметры:
///   p = старт of the UTF-16 sequence.
///   конец = one past the конец of the sequence.
/// Возвращает: СИМ_ОШИБКИ in case of an ошибка in the sequence.
дим раскодируй(ref шим* p, шим* конец)
{
  assert(p && p < конец);
  дим c = *p;
  if (0xD800 > c || c > 0xDFFF)
  {
    ++p;
    return c;
  }
  if (c <= 0xDBFF && p+1 != конец)
  {
    шим c2 = p[1];
    if (0xDC00 <= c2 && c2 <= 0xDFFF)
    {
      c = (c - 0xD7C0) << 10;
      c |= (c2 & 0x3FF);
      p += 2;
      return c;
    }
  }
  return СИМ_ОШИБКИ;
}

/// Decodes a character из a zero-terminated UTF-16 ткст.
/// Параметры:
///   p = старт of the UTF-16 sequence.
/// Возвращает: СИМ_ОШИБКИ in case of an ошибка in the sequence.
дим раскодируй(ref шим* p)
{
  assert(p);
  дим c = *p;
  if (0xD800 > c || c > 0xDFFF)
  {
    ++p;
    return c;
  }
  if (c <= 0xDBFF)
  {
    шим c2 = p[1];
    if (0xDC00 <= c2 && c2 <= 0xDFFF)
    {
      c = (c - 0xD7C0) << 10;
      c |= (c2 & 0x3FF);
      p += 2;
      return c;
    }
  }
  return СИМ_ОШИБКИ;
}

/// Преобразует текст в UTF-8 в UTF-16 ткст.
шим[] вЮ16(сим[] ткт)
{
  шим[] результат;
  т_мера idx;
  while (idx < ткт.length)
  {
    auto c = раскодируй(ткт, idx);
    if (c == СИМ_ОШИБКИ)
    { // Skip trail bytes.
      while (++idx < ткт.length && ведомыйБайт_ли(ткт[idx]))
      {}
      c = СИМ_ЗАМЕНЫ;
    }
    кодируй(результат, c);
  }
  return результат;
}

/// Преобразует текст в UTF-8 в UTF-32 ткст.
дим[] вЮ32(сим[] ткт)
{
  дим[] результат;
  т_мера idx;
  while (idx < ткт.length)
  {
    auto c = раскодируй(ткт, idx);
    if (c == СИМ_ОШИБКИ)
    { // Skip trail bytes.
      while (++idx < ткт.length && ведомыйБайт_ли(ткт[idx]))
      {}
      c = СИМ_ЗАМЕНЫ;
    }
    результат ~= c;
  }
  return результат;
}
