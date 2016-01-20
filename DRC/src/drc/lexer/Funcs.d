/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module drc.lexer.Funcs;

import drc.Unicode : юАльфа_ли;

const сим[3] РС = \u2028; /// Разделитель строк Unicode.
const дим РСд = 0x2028;  /// определено
const сим[3] РА = \u2029; /// Разделитель абзацев Unicode.
const дим РАд = 0x2029;  /// определено
static assert(РС[0] == РА[0] && РС[1] == РА[1]);

const дим _Z_ = 26; /// Control+Z.

/// Возвращает: да if d is a Unicode line or paragraph разделитель.
бул симНовСтрЮ_ли(дим d)
{
  return d == РСд || d == РАд;
}

/// Возвращает: да if p points в a line or paragraph разделитель.
бул новСтрЮ_ли(сим* p)
{
  return *p == РС[0] && p[1] == РС[1] && (p[2] == РС[2] || p[2] == РА[2]);
}

/// Возвращает: да if p points в the старт of a Новстр.
/// $(PRE
/// Новстр := "\n" | "\r" | "\r\n" | РС | РА
/// РС := "\u2028"
/// РА := "\u2029"
/// )
бул новСтр_ли(сим* p)
{
  return *p == '\n' || *p == '\r' || новСтрЮ_ли(p);
}

/// Возвращает: да if c is a Новстр character.
бул новСтр_ли(дим c)
{
  return c == '\n' || c == '\r' || симНовСтрЮ_ли(c);
}

/// Возвращает: да if p points в an КФ character.
/// $(PRE
/// КФ := "\0" | _Z_
/// _Z_ := "\x1A"
/// )
бул кф_ли(дим c)
{
  return c == 0 || c == _Z_;
}

/// Возвращает: да if p points в the first character of an EndOfLine.
/// $(PRE EndOfLine := Новстр | КФ)
бул конецСтроки_ли(сим* p)
{
  return новСтр_ли(p) || кф_ли(*p);
}

/// Сканирует символ Новстр и устанавливает p на символ после него.
/// Возвращает: да if found or нет otherwise.
бул сканируйНовСтр(ref сим* p)
in { assert(p); }
body
{
  switch (*p)
  {
  case '\r':
    if (p[1] == '\n')
      ++p;
  case '\n':
    ++p;
    break;
  default:
    if (новСтрЮ_ли(p))
      p += 3;
    else
      return нет;
  }
  return да;
}

/// Сканирует символ Новстр и устанавливает p на символ после него.
/// Возвращает: да if found or нет otherwise.
бул сканируйНовСтр(ref сим* p, сим* конец)
in { assert(p && p < конец); }
body
{
  switch (*p)
  {
  case '\r':
    if (p+1 < конец && p[1] == '\n')
      ++p;
  case '\n':
    ++p;
    break;
  default:
    if (p+2 < конец && новСтрЮ_ли(p))
      p += 3;
    else
      return нет;
  }
  return да;
}

/// Scans a Новстр in reverse direction and sets конец
/// on the first character of the новстр.
/// Возвращает: да if found or нет otherwise.
бул сканируйНовСтрРеверс(сим* начало, ref сим* конец)
{
  switch (*конец)
  {
  case '\n':
    if (начало <= конец-1 && конец[-1] == '\r')
      конец--;
  case '\r':
    break;
  case РС[2], РА[2]:
    if (начало <= конец-2 && конец[-1] == РС[1] && конец[-2] == РС[0]) {
      конец -= 2;
      break;
    }
  // fall through
  default:
    return нет;
  }
  return да;
}

/// Scans a D identifier.
/// Параметры:
///   ref_p = where в старт.
///   конец = where it ends.
/// Возвращает: the identifier if valid (sets ref_p one past the ид,) or
///          null if invalid (leaves ref_p unchanged.)
сим[] сканируйИдентификатор(ref сим* ref_p, сим* конец)
in { assert(ref_p && ref_p < конец); }
body
{
  auto p = ref_p;
  if (начсим_ли(*p) || юАльфа_ли(p, конец)) // IdStart
  {
    do // IdChar*
      p++;
    while (p < конец && (идент_ли(*p) || юАльфа_ли(p, конец)))
    auto identifier = ref_p[0 .. p-ref_p];
    ref_p = p;
    return identifier;
  }
  return null;
}

/// ASCII character properties таблица.
static const цел ptable[256] = [
 0, 0, 0, 0, 0, 0, 0, 0, 0,32, 0,32,32, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
32, 0, 0x2200, 0, 0, 0, 0, 0x2700, 0, 0, 0, 0, 0, 0, 0, 0,
 7, 7, 7, 7, 7, 7, 7, 7, 6, 6, 0, 0, 0, 0, 0, 0x3f00,
 0,12,12,12,12,12,12, 8, 8, 8, 8, 8, 8, 8, 8, 8,
 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0, 0x5c00, 0, 0,16,
 0, 0x70c, 0x80c,12,12,12, 0xc0c, 8, 8, 8, 8, 8, 8, 8, 0xa08, 8,
 8, 8, 0xd08, 8, 0x908, 8, 0xb08, 8, 8, 8, 8, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
];

/// Enumeration of character property флаги.
enum СвойствоС
{
       Восмиричный = 1,    /// 0-7
       Десятичный = 1<<1, /// 0-9
         Гекс = 1<<2, /// 0-9a-fA-F
       Буква = 1<<3, /// a-zA-Z
  Подчерк = 1<<4, /// _
  Пробельный = 1<<5  /// ' ' \t \v \f
}

const бцел EVMask = 0xFF00; // Bit mask for escape значение.

private alias СвойствоС CP;
/// Возвращает: да if c is an octal digit.
цел восмир_ли(сим c) { return ptable[c] & CP.Восмиричный; }
/// Возвращает: да if c is a decimal digit.
цел цифра_ли(сим c) { return ptable[c] & CP.Десятичный; }
/// Возвращает: да if c is a hexadecimal digit.
цел гекс_ли(сим c) { return ptable[c] & CP.Гекс; }
/// Возвращает: да if c is a letter.
цел буква_ли(сим c) { return ptable[c] & CP.Буква; }
/// Возвращает: да if c is an alphanumeric.
цел цифробукв_ли(сим c) { return ptable[c] & (CP.Буква | CP.Десятичный); }
/// Возвращает: да if c is the beginning of a D identifier (only ASCII.)
цел начсим_ли(сим c) { return ptable[c] & (CP.Буква | CP.Подчерк); }
/// Возвращает: да if c is a D identifier character (only ASCII.)
цел идент_ли(сим c) { return ptable[c] & (CP.Буква | CP.Подчерк | CP.Десятичный); }
/// Возвращает: да if c is a whitespace character.
цел пбел_ли(сим c) { return ptable[c] & CP.Пробельный; }
/// Возвращает: the escape значение for c.
цел сим8еск(сим c) { return ptable[c] >> 8; /*(ptable[c] & EVMask) >> 8;*/ }
/// Возвращает: да if c is an ASCII character.
цел аски_ли(бцел c) { return c < 128; }

version(gen_ptable)
static this()
{
  alias ptable p;
  assert(p.length == 256);
  // Initialize character properties таблица.
  for (цел i; i < p.length; ++i)
  {
    p[i] = 0; // Reset
    if ('0' <= i && i <= '7')
      p[i] |= CP.Восмиричный;
    if ('0' <= i && i <= '9')
      p[i] |= CP.Десятичный | CP.Гекс;
    if ('a' <= i && i <= 'f' || 'A' <= i && i <= 'F')
      p[i] |= CP.Гекс;
    if ('a' <= i && i <= 'z' || 'A' <= i && i <= 'Z')
      p[i] |= CP.Буква;
    if (i == '_')
      p[i] |= CP.Подчерк;
    if (i == ' ' || i == '\t' || i == '\v' || i == '\f')
      p[i] |= CP.Пробельный;
  }
  // Store escape sequence значения in second байт.
  assert(СвойствоС.max <= ббайт.max, "character property флаги and escape значение байт overlap.");
  p['\''] |= 39 << 8;
  p['"'] |= 34 << 8;
  p['?'] |= 63 << 8;
  p['\\'] |= 92 << 8;
  p['a'] |= 7 << 8;
  p['b'] |= 8 << 8;
  p['f'] |= 12 << 8;
  p['n'] |= 10 << 8;
  p['r'] |= 13 << 8;
  p['t'] |= 9 << 8;
  p['v'] |= 11 << 8;
  // Print a formatted массив literal.
  сим[] массив = "[\n";
  foreach (i, c; ptable)
  {
    массив ~= Формат((c>255?" 0x{0:x},":"{0,2},"), c) ~ (((i+1) % 16) ? "":"\n");
  }
  массив[$-2..$] = "\n]";
  выдай(массив).новстр;
}
