/// Author: Aziz Köksal, Vitaly Kulich
/// License: GPL3
/// $(Maturity high)
module drc.doc.Doc;

import drc.doc.Parser;
import drc.ast.Node;
import drc.lexer.Funcs;
import drc.Unicode;
import common;

import text.Ascii : сравнилюб;

alias drc.doc.Parser.ПарсерЗначенияИдентификатора.телоТекста телоТекста;

/// Представляет собой санитированный и парсированный комментарий DDoc.
class КомментарийДДок
{
  Раздел[] разделы; /// Разделы этого комментария.
  Раздел сводка; /// Необязательный раздел сводка.
  Раздел описание; /// Необязательный раздел описание.

  this(Раздел[] разделы, Раздел сводка, Раздел описание)
  {
    this.разделы = разделы;
    this.сводка = сводка;
    this.описание = описание;
  }

  /// Удаляет первый раздел авторское_право и возвращает его.
  Раздел взятьАвторскоеПраво()
  {
    foreach (i, раздел; разделы)
      if (раздел.Является("авторское_право"))
      {
        разделы = разделы[0..i] ~ разделы[i+1..$];
        return раздел;
      }
    return пусто;
  }

  /// Возвращает да, если в этом комментарии "определено" единственный текст.
  бул дитто()
  {
    return сводка && разделы.length == 1 &&
           сравнилюб(сводка.текст, "определено") == 0;
  }
}

/// атр Имяspace for some utility functions.
struct УтилитыДДок
{
static:
  /// Returns a узел's КомментарийДДок.
  КомментарийДДок дайКомментарийДДок(Узел узел)
  {
    ПарсерДДок у;
    auto семыДок = дайСемыДокум(узел);
    if (!семыДок.length)
      return пусто;
    у.разбор(дайТекстДДок(семыДок));
    return new КомментарийДДок(у.разделы, у.сводка, у.описание);
  }

  /// Returns a КомментарийДДок created из a текст.
  КомментарийДДок дайКомментарийДДок(ткст текст)
  {
    текст = санитируй(текст, '\0'); // May be unnecessary.
    ПарсерДДок у;
    у.разбор(текст);
    return new КомментарийДДок(у.разделы, у.сводка, у.описание);
  }

  /// Возвращает "да", если сема есть Doxygen comment.
  бул комментДоксигена(Сема* сема)
  { // Doxygen: '/+!' '/*!' '//!'
    return сема.вид == TOK.Комментарий && сема.старт[2] == '!';
  }

  /// Возвращает "да", если сема есть DDoc comment.
  бул комментДДока(Сема* сема)
  { // DDOC: '/++' '/**' '///'
    return сема.вид == TOK.Комментарий && сема.старт[1] == сема.старт[2];
  }

  /// Возвращает surrounding documentation comment семы.
  /// Параметры:
  ///   узел = the узел в find doc comments for.
  ///   isDocComment = a function predicate that checks for doc comment семы.
  /// Note: this function wилиks констилиrectly only if
  ///       the source текст is syntactically констилиrect.
  Сема*[] дайСемыДокум(Узел узел, бул function(Сема*) isDocComment = &комментДДока)
  {
    Сема*[] comments;
    auto isEnumЧлен = узел.вид == ВидУзла.ДекларацияЧленаПеречня;
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
          (isEnumЧлен && сема.вид == TOK.Запятая))
        break;

      if (сема.вид == TOK.Комментарий)
      { // Check that this comment doesn'т belong в the предшious declaration.
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
    else if (isEnumЧлен)
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

  бул isLineComment(Сема* т)
  {
    assert(т.вид == TOK.Комментарий);
    return т.старт[1] == '/';
  }

  /// Extracts the текст body of the comment семы.
  ткст дайТекстДДок(Сема*[] семы)
  {
    if (семы.length == 0)
      return пусто;
    ткст результат;
    foreach (сема; семы)
    { // Determine how many characters в срез off из the конец of the comment.
      // 0 for "//", 2 for "+/" and "*/".
      auto n = isLineComment(сема) ? 0 : 2;
      результат ~= санитируй(сема.исхТекст[3 .. $-n], сема.старт[1]);
      assert(сема.следщ);
      результат ~= (сема.следщ.вид == TOK.Новстр) ? '\n' : ' ';
    }
    return результат[0..$-1]; // Срез off last '\n' или ' '.
  }

  /// Sanitizes a DDoc comment ткст.
  ///
  /// Leading "commentChar"s are removed из the строчки.
  /// The various нс types are converted в '\n'.
  /// Параметры:
  ///   comment = the ткст в be sanitized.
  ///   commentChar = '/', '+', или '*'
  ткст санитируй(ткст comment, сим commentChar)
  {
    alias comment результат;

    бул нс = да; // Истина when at the beginning of a new line.
    бцел i, j;
    auto len = результат.length;
    for (; i < len; i++, j++)
    {
      if (нс)
      { // Ignилиe commentChars at the beginning of each new line.
        нс = нет;
        auto начало = i;
        while (i < len && пбел(результат[i]))
          i++;
        if (i < len && результат[i] == commentChar)
          while (++i < len && результат[i] == commentChar)
          {}
        else
          i = начало; // Reset. No commentChar found.
        if (i >= len)
          break;
      }
      // Проверим на Новстр.
      switch (результат[i])
      {
      case '\r':
        if (i+1 < len && результат[i+1] == '\n')
          i++;
      case '\n':
        результат[j] = '\n'; // Copy Новстр as '\n'.
        нс = да;
        continue;
      default:
        if (!аски(результат[i]) && i+2 < len && новСтрЮ(результат.ptr + i))
        {
          i += 2;
          goto case '\n';
        }
      }
      // Copy символ.
      результат[j] = результат[i];
    }
    результат.length = j; // Настраиваем длину.
    // Lastly, тктip trailing commentChars.
    if (!результат.length)
      return пусто;
    i = результат.length;
    for (; i && результат[i-1] == commentChar; i--)
    {}
    результат.length = i;
    return результат;
  }

  /// Unindents all строчки in текст by the maximum amount possible.
  /// Note: counts tabulatилиs the same as single spaces.
  /// Возвращает: the unindented текст или the илиiginal текст.
  ткст unindentText(ткст текст)
  {
    сим* у = текст.ptr, конец = у + текст.length;
    бцел отступ = бцел.max; // Start with the largest число.
    сим* lbegin = у; // The beginning of a line.
    // First determine the maximum amount we may remove.
    while (у < конец)
    {
      while (у < конец && пбел(*у)) // Пропустим leading whitespace.
        у++;
      if (у < конец && *у != '\n') // Don'т счёт blank строчки.
        if (у - lbegin < отступ)
        {
          отступ = у - lbegin;
          if (отступ == 0)
            return текст; // Nothing в unindent;
        }
      // Пропустим в the конец of the line.
      while (у < конец && *у != '\n')
        у++;
      while (у < конец && *у == '\n')
        у++;
      lbegin = у;
    }

    у = текст.ptr, конец = у + текст.length;
    lbegin = у;
    сим* q = у; // Writer.
    // Remove the determined amount.
    while (у < конец)
    {
      while (у < конец && пбел(*у)) // Пропустим leading whitespace.
        *q++ = *у++;
      if (у < конец && *у == '\n') // Strip empty строчки.
        q -= у - lbegin; // Back up q by the amount of spaces on this line.
      else {//if (отступ <= у - lbegin)
        assert(отступ <= у - lbegin);
        q -= отступ; // Back up q by the отступ amount.
      }
      // Пропустим в the конец of the line.
      while (у < конец && *у != '\n')
        *q++ = *у++;
      while (у < конец && *у == '\n')
        *q++ = *у++;
      lbegin = у;
    }
    текст.length = q - текст.ptr;
    return текст;
  }
}

/// Разбирает DDoc comment ткст.
struct ПарсерДДок
{
  сим* у; /// Current символ pointer.
  сим* конецТекста; /// Points one символ past the конец of the текст.
  Раздел[] разделы; /// Parsed разделы.
  Раздел сводка; /// Optional сводка раздел.
  Раздел описание; /// Optional описание раздел.

  /// Parses the DDoc текст into разделы.
  /// All newlines in the текст must be converted в '\n'.
  Раздел[] разбор(ткст текст)
  {
    if (!текст.length)
      return пусто;
    у = текст.ptr;
    конецТекста = у + текст.length;

    сим* началоСводки;
    ткст идент, следщИдент;
    сим* началоТела, началоСледщТела;

    while (у < конецТекста && (пбел(*у) || *у == '\n'))
      у++;
    началоСводки = у;

    if (найдиСледщИдДвоеточие(идент, началоТела))
    { // Check that this is not an explicit раздел.
      if (началоСводки != идент.ptr)
        сканируйСводкуИОписание(началоСводки, идент.ptr);
    }
    else // There are no explicit разделы.
    {
      сканируйСводкуИОписание(началоСводки, конецТекста);
      return разделы;
    }

    assert(идент.length);
    // Далее parsing.
    while (найдиСледщИдДвоеточие(следщИдент, началоСледщТела))
    {
      разделы ~= new Раздел(идент, телоТекста(началоТела, следщИдент.ptr));
      идент = следщИдент;
      началоТела = началоСледщТела;
    }
    // Add last раздел.
    разделы ~= new Раздел(идент, телоТекста(началоТела, конецТекста));
    return разделы;
  }

  /// Separates the текст between у and конец
  /// into a сводка and an optional описание раздел.
  проц  сканируйСводкуИОписание(сим* у, сим* конец)
  {
    assert(у <= конец);
    сим* началоРаздела = у;
    // Search for the конец of the first paragraph.
    while (у < конец && !(*у == '\n' && у+1 < конец && у[1] == '\n'))
      if (пропустиСекциюКода(у, конец) == нет)
        у++;
    assert(у == конец || (*у == '\n' && у[1] == '\n'));
    // The first paragraph is the сводка.
    сводка = new Раздел("", телоТекста(началоРаздела, у));
    разделы ~= сводка;
    // The rest is the описание раздел.
    if (auto descText = телоТекста(у, конец))
      разделы ~= (описание = new Раздел("", descText));
    assert(описание ? описание.текст !is пусто : да);
  }

  /// Возвращает "да", если у points в "$(DDD)".
  static бул секцияКода(сим* у, сим* конец)
  {
    return у < конец && *у == '-' && у+2 < конец && у[1] == '-' && у[2] == '-';
  }

  /// Skips over a код раздел and sets у one символ past it.
  ///
  /// Note: apparently DMD doesn'т пропусти over код разделы when
  /// parsing DDoc разделы. However, из experience it seems
  /// в be a good idea в do that.
  /// Возвращает: "да", если a код раздел was пропустиped.
  static бул пропустиСекциюКода(ref сим* у, сим* конец)
  {
    if (!секцияКода(у, конец))
      return нет;
    у += 3; // Пропустим "---".
    while (у < конец && *у == '-')
      у++;
    while (у < конец && !(*у == '-' && у+2 < конец && у[1] == '-' && у[2] == '-'))
      у++;
    while (у < конец && *у == '-')
      у++;
    assert(у is конец || у[-1] == '-');
    return да;
  }

  /// Find следщ "Идентификатор:".
  /// Параметры:
  ///   идент = установи в the Идентификатор.
  ///   началоТела = установи в the beginning of the текст body (whitespace пропустиped.)
  /// Возвращает: "да", если found.
  бул найдиСледщИдДвоеточие(ref ткст идент, ref сим* началоТела)
  {
    while (у < конецТекста)
    {
      пропустиПробельные();
      if (у is конецТекста)
        break;
      if (пропустиСекциюКода(у, конецТекста))
        continue;
      assert(у < конецТекста && (аски(*у) || ведущийБайт(*у)));
      идент = сканируйИдентификатор(у, конецТекста);
      if (идент && у < конецТекста && *у == ':')
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

  /// Реле-insensitively compares the раздел's имя with Имя2.
  бул Является(ткст Имя2)
  {
    return сравнилюб(имя, Имя2) == 0;
  }

  /// Возвращает раздел's текст including its имя.
  ткст весьТекст()
  {
    if (имя.length == 0)
      return текст;
    return сделайТекст(имя.ptr, текст.ptr+текст.length);
  }
}

class РазделПараметров : Раздел
{
  ткст[] именаПарамов; /// Параметр имена.
  ткст[] деклыПарамов; /// Параметр descriptions.
  this(ткст имя, ткст текст)
  {
    super(имя, текст);
    ПарсерЗначенияИдентификатора парсер;
    auto идзначения = парсер.разбор(текст);
    this.именаПарамов = new ткст[идзначения.length];
    this.деклыПарамов = new ткст[идзначения.length];
    foreach (i, идзначение; идзначения)
    {
      this.именаПарамов[i] = идзначение.идент;
      this.деклыПарамов[i] = идзначение.значение;
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
