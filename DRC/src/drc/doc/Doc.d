/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.doc.Doc;

import drc.doc.Parser;
import drc.ast.Node;
import drc.lexer.Funcs;
import drc.Unicode;
import common;

import tango.text.Ascii : icompare;

alias drc.doc.Parser.ПарсерЗначенияИдентификатора.телоТекста телоТекста;

/// Represents a sanitized and parsed DDoc comment.
class КомментарийДДок
{
  Раздел[] резделы; /// The резделы of this comment.
  Раздел сводка; /// Optional сводка раздел.
  Раздел описание; /// Optional описание раздел.

  this(Раздел[] резделы, Раздел сводка, Раздел описание)
  {
    this.резделы = резделы;
    this.сводка = сводка;
    this.описание = описание;
  }

  /// Removes the first авторское_право раздел and returns it.
  Раздел взятьАвторскоеПраво()
  {
    foreach (i, раздел; резделы)
      if (раздел.Является("авторское_право"))
      {
        резделы = резделы[0..i] ~ резделы[i+1..$];
        return раздел;
      }
    return null;
  }

  /// Returns да if "определено" is the only текст in this comment.
  бул дитто_ли()
  {
    return сводка && резделы.length == 1 &&
           icompare(сводка.текст, "определено") == 0;
  }
}

/// A namespace for some utility functions.
struct УтилитыДДок
{
static:
  /// Returns a узел's КомментарийДДок.
  КомментарийДДок дайКомментарийДДок(Узел узел)
  {
    ПарсерДДок p;
    auto семыДок = дайСемыДокум(узел);
    if (!семыДок.length)
      return null;
    p.разбор(дайТекстДДок(семыДок));
    return new КомментарийДДок(p.резделы, p.сводка, p.описание);
  }

  /// Returns a КомментарийДДок created из a текст.
  КомментарийДДок дайКомментарийДДок(ткст текст)
  {
    текст = санитируй(текст, '\0'); // May be unnecessary.
    ПарсерДДок p;
    p.разбор(текст);
    return new КомментарийДДок(p.резделы, p.сводка, p.описание);
  }

  /// Returns да if сема is a Doxygen comment.
  бул комментДоксигена_ли(Сема* сема)
  { // Doxygen: '/+!' '/*!' '//!'
    return сема.вид == TOK.Комментарий && сема.старт[2] == '!';
  }

  /// Returns да if сема is a DDoc comment.
  бул комментДДока_ли(Сема* сема)
  { // DDOC: '/++' '/**' '///'
    return сема.вид == TOK.Комментарий && сема.старт[1] == сема.старт[2];
  }

  /// Returns the surrounding documentation comment семы.
  /// Параметры:
  ///   узел = the узел в find doc comments for.
  ///   isDocComment = a function predicate that checks for doc comment семы.
  /// Note: this function works correctly only if
  ///       the source текст is syntactically correct.
  Сема*[] дайСемыДокум(Узел узел, бул function(Сема*) isDocComment = &комментДДока_ли)
  {
    Сема*[] comments;
    auto isEnumMember = узел.вид == ВидУзла.ДекларацияЧленаПеречня;
    // Get preceding comments.
    auto сема = узел.начало;
    // Scan backwards until we hit another declaration.
  Loop:
    for (; сема; сема = сема.предш)
    {
      if (сема.вид == TOK.ЛФСкобка ||
          сема.вид == TOK.ПФСкобка ||
          сема.вид == TOK.ТочкаЗапятая ||
          /+сема.вид == TOK.ГОЛОВА ||+/
          (isEnumMember && сема.вид == TOK.Запятая))
        break;

      if (сема.вид == TOK.Комментарий)
      { // Check that this comment doesn't belong в the предшious declaration.
        switch (сема.предш.вид)
        {
        case TOK.ТочкаЗапятая, TOK.ПФСкобка, TOK.Запятая:
          break Loop;
        default:
          if (isDocComment(сема))
            comments = [сема] ~ comments;
        }
      }
    }
    // Get single comment в the правый.
    сема = узел.конец.следщ;
    if (сема.вид == TOK.Комментарий && isDocComment(сема))
      comments ~= сема;
    else if (isEnumMember)
    {
      сема = узел.конец.следщНепроб;
      if (сема.вид == TOK.Запятая)
      {
        сема = сема.следщ;
        if (сема.вид == TOK.Комментарий && isDocComment(сема))
          comments ~= сема;
      }
    }
    return comments;
  }

  бул isLineComment(Сема* t)
  {
    assert(t.вид == TOK.Комментарий);
    return t.старт[1] == '/';
  }

  /// Extracts the текст body of the comment семы.
  ткст дайТекстДДок(Сема*[] семы)
  {
    if (семы.length == 0)
      return null;
    ткст результат;
    foreach (сема; семы)
    { // Determine how many characters в slice off из the конец of the comment.
      // 0 for "//", 2 for "+/" and "*/".
      auto n = isLineComment(сема) ? 0 : 2;
      результат ~= санитируй(сема.исхТекст[3 .. $-n], сема.старт[1]);
      assert(сема.следщ);
      результат ~= (сема.следщ.вид == TOK.Новстр) ? '\n' : ' ';
    }
    return результат[0..$-1]; // Срез off last '\n' or ' '.
  }

  /// Sanitizes a DDoc comment ткст.
  ///
  /// Leading "commentChar"s are removed из the lines.
  /// The various новстр types are converted в '\n'.
  /// Параметры:
  ///   comment = the ткст в be sanitized.
  ///   commentChar = '/', '+', or '*'
  ткст санитируй(ткст comment, сим commentChar)
  {
    alias comment результат;

    бул новстр = да; // Истина when at the beginning of a new line.
    бцел i, j;
    auto len = результат.length;
    for (; i < len; i++, j++)
    {
      if (новстр)
      { // Ignore commentChars at the beginning of each new line.
        новстр = нет;
        auto начало = i;
        while (i < len && пбел_ли(результат[i]))
          i++;
        if (i < len && результат[i] == commentChar)
          while (++i < len && результат[i] == commentChar)
          {}
        else
          i = начало; // Reset. No commentChar found.
        if (i >= len)
          break;
      }
      // Check for Новстр.
      switch (результат[i])
      {
      case '\r':
        if (i+1 < len && результат[i+1] == '\n')
          i++;
      case '\n':
        результат[j] = '\n'; // Copy Новстр as '\n'.
        новстр = да;
        continue;
      default:
        if (!аски_ли(результат[i]) && i+2 < len && новСтрЮ_ли(результат.ptr + i))
        {
          i += 2;
          goto case '\n';
        }
      }
      // Copy character.
      результат[j] = результат[i];
    }
    результат.length = j; // Adjust length.
    // Lastly, тктip trailing commentChars.
    if (!результат.length)
      return null;
    i = результат.length;
    for (; i && результат[i-1] == commentChar; i--)
    {}
    результат.length = i;
    return результат;
  }

  /// Unindents all lines in текст by the maximum amount possible.
  /// Note: counts tabulators the same as single spaces.
  /// Возвращает: the unindented текст or the original текст.
  сим[] unindentText(сим[] текст)
  {
    сим* p = текст.ptr, конец = p + текст.length;
    бцел отступ = бцел.max; // Start with the largest число.
    сим* lbegin = p; // The beginning of a line.
    // First determine the maximum amount we may remove.
    while (p < конец)
    {
      while (p < конец && пбел_ли(*p)) // Skip leading whitespace.
        p++;
      if (p < конец && *p != '\n') // Don't счёт blank lines.
        if (p - lbegin < отступ)
        {
          отступ = p - lbegin;
          if (отступ == 0)
            return текст; // Nothing в unindent;
        }
      // Skip в the конец of the line.
      while (p < конец && *p != '\n')
        p++;
      while (p < конец && *p == '\n')
        p++;
      lbegin = p;
    }

    p = текст.ptr, конец = p + текст.length;
    lbegin = p;
    сим* q = p; // Writer.
    // Remove the determined amount.
    while (p < конец)
    {
      while (p < конец && пбел_ли(*p)) // Skip leading whitespace.
        *q++ = *p++;
      if (p < конец && *p == '\n') // Strip empty lines.
        q -= p - lbegin; // Back up q by the amount of spaces on this line.
      else {//if (отступ <= p - lbegin)
        assert(отступ <= p - lbegin);
        q -= отступ; // Back up q by the отступ amount.
      }
      // Skip в the конец of the line.
      while (p < конец && *p != '\n')
        *q++ = *p++;
      while (p < конец && *p == '\n')
        *q++ = *p++;
      lbegin = p;
    }
    текст.length = q - текст.ptr;
    return текст;
  }
}

/// Parses a DDoc comment ткст.
struct ПарсерДДок
{
  сим* p; /// Current character pointer.
  сим* конецТекста; /// Points one character past the конец of the текст.
  Раздел[] резделы; /// Parsed резделы.
  Раздел сводка; /// Optional сводка раздел.
  Раздел описание; /// Optional описание раздел.

  /// Parses the DDoc текст into резделы.
  /// All newlines in the текст must be converted в '\n'.
  Раздел[] разбор(ткст текст)
  {
    if (!текст.length)
      return null;
    p = текст.ptr;
    конецТекста = p + текст.length;

    сим* началоСводки;
    ткст идент, следщИдент;
    сим* началоТела, началоСледщТела;

    while (p < конецТекста && (пбел_ли(*p) || *p == '\n'))
      p++;
    началоСводки = p;

    if (найдиСледщИдДвоеточие(идент, началоТела))
    { // Check that this is not an explicit раздел.
      if (началоСводки != идент.ptr)
        сканируйСводкуИОписание(началоСводки, идент.ptr);
    }
    else // There are no explicit резделы.
    {
      сканируйСводкуИОписание(началоСводки, конецТекста);
      return резделы;
    }

    assert(идент.length);
    // Далее parsing.
    while (найдиСледщИдДвоеточие(следщИдент, началоСледщТела))
    {
      резделы ~= new Раздел(идент, телоТекста(началоТела, следщИдент.ptr));
      идент = следщИдент;
      началоТела = началоСледщТела;
    }
    // Add last раздел.
    резделы ~= new Раздел(идент, телоТекста(началоТела, конецТекста));
    return резделы;
  }

  /// Separates the текст between p and конец
  /// into a сводка and an optional описание раздел.
  проц  сканируйСводкуИОписание(сим* p, сим* конец)
  {
    assert(p <= конец);
    сим* началоРаздела = p;
    // Search for the конец of the first paragraph.
    while (p < конец && !(*p == '\n' && p+1 < конец && p[1] == '\n'))
      if (пропустиСекциюКода(p, конец) == нет)
        p++;
    assert(p == конец || (*p == '\n' && p[1] == '\n'));
    // The first paragraph is the сводка.
    сводка = new Раздел("", телоТекста(началоРаздела, p));
    резделы ~= сводка;
    // The rest is the описание раздел.
    if (auto descText = телоТекста(p, конец))
      резделы ~= (описание = new Раздел("", descText));
    assert(описание ? описание.текст !is null : да);
  }

  /// Returns да if p points в "$(DDD)".
  static бул секцияКода_ли(сим* p, сим* конец)
  {
    return p < конец && *p == '-' && p+2 < конец && p[1] == '-' && p[2] == '-';
  }

  /// Skips over a код раздел and sets p one character past it.
  ///
  /// Note: apparently DMD doesn't пропусти over код резделы when
  /// parsing DDoc резделы. However, из experience it seems
  /// в be a good idea в do that.
  /// Возвращает: да if a код раздел was пропустиped.
  static бул пропустиСекциюКода(ref сим* p, сим* конец)
  {
    if (!секцияКода_ли(p, конец))
      return нет;
    p += 3; // Skip "---".
    while (p < конец && *p == '-')
      p++;
    while (p < конец && !(*p == '-' && p+2 < конец && p[1] == '-' && p[2] == '-'))
      p++;
    while (p < конец && *p == '-')
      p++;
    assert(p is конец || p[-1] == '-');
    return да;
  }

  /// Find следщ "Идентификатор:".
  /// Параметры:
  ///   идент = установи в the Идентификатор.
  ///   началоТела = установи в the beginning of the текст body (whitespace пропустиped.)
  /// Возвращает: да if found.
  бул найдиСледщИдДвоеточие(ref сим[] идент, ref сим* началоТела)
  {
    while (p < конецТекста)
    {
      пропустиПробельные();
      if (p is конецТекста)
        break;
      if (пропустиСекциюКода(p, конецТекста))
        continue;
      assert(p < конецТекста && (аски_ли(*p) || ведущийБайт_ли(*p)));
      идент = сканируйИдентификатор(p, конецТекста);
      if (идент && p < конецТекста && *p == ':')
      {
        началоТела = ++p;
        пропустиСтроку();
        return да;
      }
      пропустиСтроку();
    }
    assert(p is конецТекста);
    return нет;
  }

  проц  пропустиПробельные()
  {
    while (p < конецТекста && пбел_ли(*p))
      p++;
  }

  проц  пропустиСтроку()
  {
    while (p < конецТекста && *p != '\n')
      p++;
    while (p < конецТекста && *p == '\n')
      p++;
  }
}

/// Represents a DDoc раздел.
class Раздел
{
  ткст имя;
  ткст текст;
  this(ткст имя, ткст текст)
  {
    this.имя = имя;
    this.текст = текст;
  }

  /// Реле-insensitively compares the раздел's имя with name2.
  бул Является(сим[] name2)
  {
    return icompare(имя, name2) == 0;
  }

  /// Returns the раздел's текст including its имя.
  сим[] весьТекст()
  {
    if (имя.length == 0)
      return текст;
    return сделайТекст(имя.ptr, текст.ptr+текст.length);
  }
}

class РазделПараметров : Раздел
{
  ткст[] paramNames; /// Параметр имена.
  ткст[] paramDescs; /// Параметр descriptions.
  this(ткст имя, ткст текст)
  {
    super(имя, текст);
    ПарсерЗначенияИдентификатора парсер;
    auto идзначения = парсер.разбор(текст);
    this.paramNames = new ткст[идзначения.length];
    this.paramDescs = new ткст[идзначения.length];
    foreach (i, идзначение; идзначения)
    {
      this.paramNames[i] = идзначение.идент;
      this.paramDescs[i] = идзначение.значение;
    }
  }
}

class РазделМакросов : Раздел
{
  ткст[] именаМакросов; /// Макрос имена.
  ткст[] текстыМакросов; /// Макрос тексты.
  this(ткст имя, ткст текст)
  {
    super(имя, текст);
    ПарсерЗначенияИдентификатора парсер;
    auto идзначения = парсер.разбор(текст);
    this.именаМакросов = new ткст[идзначения.length];
    this.текстыМакросов = new ткст[идзначения.length];
    foreach (i, идзначение; идзначения)
    {
      this.именаМакросов[i] = идзначение.идент;
      this.текстыМакросов[i] = идзначение.значение;
    }
  }
}
