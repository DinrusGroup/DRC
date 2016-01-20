/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module drc.lexer.Lexer;

import drc.lexer.Token,
       drc.lexer.Keywords,
       drc.lexer.Identifier,
       drc.lexer.IdTable;
import drc.Diagnostics;
import drc.Messages;
import drc.HtmlEntities;
import drc.CompilerInfo;
import drc.Unicode;
import drc.SourceText;
import drc.Time;
import common;

import tango.stdc.stdlib : strtof, strtod, strtold;
import tango.stdc.errno : errno, ERANGE;
import tango.core.Vararg;

public import drc.lexer.Funcs;

/// Лексер анализирует символы исходного текста и
/// производит дважды-линкованный список сем (токенов).
class Лексер
{
  ИсходныйТекст исхТекст; /// Исходный текст.
  сим* p;            /// Указывает на текущий символ в исходном тексте.
  сим* конец;          /// Указывает на символ после конца исходного текста.

  Сема* глава;  /// Глава дважды линкованного списка сем.
  Сема* хвост;  /// Хвост линкованного список. Set in сканируй().
  Сема* сема; /// Указывает на текущую сему в списке сем.

  // Members used for ошибка сообщения:
  Диагностика диаг;
  ОшибкаЛексера[] ошибки;
  /// Всегда указывает на первый символ текущей строки.
  сим* началоСтроки;
//   Сема* новстр;     /// Current новстр сема.
  бцел номСтр = 1;   /// Current, actual source текст line число.
  бцел lineNum_hline; /// Line число установи by #line.
  бцел inTokenString; /// > 0 if внутри q{ }
  /// Holds the original file путь and the modified one (by #line.)
  ДанныеНовСтр.ФПути* путиКФайлам;

  /// Конструировать Лексер object.
  /// Параметры:
  ///   исхТекст = the UTF-8 source код.
  ///   диаг = used for collecting ошибка сообщения.
  this(ИсходныйТекст исхТекст, Диагностика диаг = null)
  {
    this.исхТекст = исхТекст;
    this.диаг = диаг;

    assert(текст.length && текст[$-1] == 0, "в исходнике отсутствует символ sentinel");
    this.p = текст.ptr;
    this.конец = this.p + текст.length;
    this.началоСтроки = this.p;

    this.глава = new Сема;
    this.глава.вид = TOK.ГОЛОВА;
    this.глава.старт = this.глава.конец = this.p;
    this.сема = this.глава;
    // Initialize this.путиКФайлам.
    новыйПутьФ(this.исхТекст.путьКФайлу);
    // Add a новстр as the first сема after the глава.
    auto новстр = new Сема;
    новстр.вид = TOK.Новстр;
    новстр.установиФлагПробельные();
    новстр.старт = новстр.конец = this.p;
    новстр.новстр.путиКФайлам = this.путиКФайлам;
    новстр.новстр.oriLineNum = 1;
    новстр.новстр.setLineNum = 0;
    // Link in.
    this.сема.следщ = новстр;
    новстр.предш = this.сема;
    this.сема = новстр;
//     this.новстр = новстр;
    сканируйШебанг();
  }

  /// The destructor deletes the doubly-linked сема список.
  ~this()
  {
    auto сема = глава.следщ;
    while (сема !is null)
    {
      assert(сема.вид == TOK.КФ ? сема == хвост && сема.следщ is null : 1);
      delete сема.предш;
      сема = сема.следщ;
    }
    delete хвост;
  }

  сим[] текст()
  {
    return исхТекст.данные;
  }

  /// The "shebang" may optionally appear once at the beginning of a file.
  /// Regexp: #![^\EndOfLine]*
  проц  сканируйШебанг()
  {
    if (*p == '#' && p[1] == '!')
    {
      auto t = new Сема;
      t.вид = TOK.Шебанг;
      t.установиФлагПробельные();
      t.старт = p;
      ++p;
      while (!конецСтроки_ли(++p))
        аски_ли(*p) || раскодируйЮ8();
      t.конец = p;
      this.сема.следщ = t;
      t.предш = this.сема;
    }
  }

  /// Sets the значение of the special сема.
  проц  finalizeSpecialToken(ref Сема t)
  {
    assert(t.исхТекст[0..2] == "__");
    switch (t.вид)
    {
    case TOK.ФАЙЛ:
      t.ткт = this.путиКФайлам.setPath;
      break;
    case TOK.СТРОКА:
      t.бцел_ = this.номерСтрокиОшиб(this.номСтр);
      break;
    case TOK.ДАТА,
         TOK.ВРЕМЯ,
         TOK.ШТАМПВРЕМЕНИ:
      auto ткт_время = Время.вТкст();
      switch (t.вид)
      {
      case TOK.ДАТА:
        ткт_время = Время.день_месяца(ткт_время) ~ ' ' ~ Время.год(ткт_время); break;
      case TOK.ВРЕМЯ:
        ткт_время = Время.время(ткт_время); break;
      case TOK.ШТАМПВРЕМЕНИ:
        break; // ткт_время is the timestamp.
      default: assert(0);
      }
      ткт_время ~= '\0'; // Terminate with a zero.
      t.ткт = ткт_время;
      break;
    case TOK.ПОСТАВЩИК:
      t.ткт = ПОСТАВЩИК;
      break;
    case TOK.ВЕРСИЯ:
      t.бцел_ = VERSION_MAJOR*1000 + VERSION_MINOR;
      break;
    default:
      assert(0);
    }
  }

  /// Sets a new file путь.
  проц  новыйПутьФ(сим[] новПуть)
  {
    auto пути = new ДанныеНовСтр.ФПути;
    пути.oriPath = this.исхТекст.путьКФайлу;
    пути.setPath = новПуть;
    this.путиКФайлам = пути;
  }

  private проц  установиНачалоСтроки(сим* p)
  {
    // Check that we can look behind one character.
    assert((p-1) >= текст.ptr && p < конец);
    // Check that предшious character is a новстр.
    assert(конецНовСтроки_ли(p - 1));
    this.началоСтроки = p;
  }

  /// Scans the следщ сема in the source текст.
  ///
  /// Creates a new сема if t.следщ is null and appends it в the список.
  private проц  сканируйСледщ(ref Сема* t)
  {
    assert(t !is null);
    if (t.следщ)
    {
      t = t.следщ;
//       if (t.вид == TOK.Новстр)
//         this.новстр = t;
    }
    else if (t != this.хвост)
    {
      Сема* т_нов = new Сема;
      сканируй(*т_нов);
      т_нов.предш = t;
      t.следщ = т_нов;
      t = т_нов;
    }
  }

  /// Advance t one сема forward.
  проц  возьми(ref Сема* t)
  {
    сканируйСледщ(t);
  }

  /// Advance в the следщ сема in the source текст.
  TOK следщСема()
  {
    сканируйСледщ(this.сема);
    return this.сема.вид;
  }

  /// Returns да if p points в the last character of a Новстр.
  бул конецНовСтроки_ли(сим* p)
  {
    if (*p == '\n' || *p == '\r')
      return да;
    if (*p == РС[2] || *p == РА[2])
      if ((p-2) >= текст.ptr)
        if (p[-1] == РС[1] && p[-2] == РС[0])
          return да;
    return нет;
  }

  /// The main method which recognizes the characters that make up a сема.
  ///
  /// Complicated семы are scanned in separate methods.
  public проц  сканируй(ref Сема t)
  in
  {
    assert(текст.ptr <= p && p < конец);
  }
  out
  {
    assert(текст.ptr <= t.старт && t.старт < конец, Сема.вТкст(t.вид));
    assert(текст.ptr <= t.конец && t.конец <= конец, Сема.вТкст(t.вид));
  }
  body
  {
    // Scan whitespace.
    if (пбел_ли(*p))
    {
      t.пп = p;
      while (пбел_ли(*++p))
      {}
    }

    // Scan a сема.
    бцел c = *p;
    {
      t.старт = p;
      // Новстр.
      switch (*p)
      {
      case '\r':
        if (p[1] == '\n')
          ++p;
      case '\n':
        assert(конецНовСтроки_ли(p));
        ++p;
        ++номСтр;
        установиНачалоСтроки(p);
//         this.новстр = &t;
        t.вид = TOK.Новстр;
        t.установиФлагПробельные();
        t.новстр.путиКФайлам = this.путиКФайлам;
        t.новстр.oriLineNum = номСтр;
        t.новстр.setLineNum = lineNum_hline;
        t.конец = p;
        return;
      default:
        if (новСтрЮ_ли(p))
        {
          ++p; ++p;
          goto case '\n';
        }
      }
      // Идентификатор or ткст literal.
      if (начсим_ли(c))
      {
        if (c == 'r' && p[1] == '"' && ++p)
          return scanRawStringLiteral(t);
        if (c == 'x' && p[1] == '"')
          return scanHexStringLiteral(t);
      version(D2)
      {
        if (c == 'q' && p[1] == '"')
          return scanDelimitedStringLiteral(t);
        if (c == 'q' && p[1] == '{')
          return scanTokenStringLiteral(t);
      }
        // Scan identifier.
      Lidentifier:
        do
        { c = *++p; }
        while (идент_ли(c) || !аски_ли(c) && юАльфа_ли())

        t.конец = p;

        auto ид = ТаблицаИд.сыщи(t.исхТекст);
        t.вид = ид.вид;
        t.идент = ид;

        if (t.вид == TOK.Идентификатор || t.кслово_ли)
          return;
        else if (t.спецСема_ли)
          finalizeSpecialToken(t);
        else if (t.вид == TOK.КФ)
        {
          хвост = &t;
          assert(t.исхТекст == "__EOF__");
        }
        else
          assert(0, "неожидаемый тип семы: " ~ Сема.вТкст(t.вид));
        return;
      }

      if (цифра_ли(c))
        return scanNumber(t);

      if (c == '/')
      {
        c = *++p;
        switch(c)
        {
        case '=':
          ++p;
          t.вид = TOK.ДелениеПрисвой;
          t.конец = p;
          return;
        case '+':
          return scanNestedComment(t);
        case '*':
          return scanBlockComment(t);
        case '/':
          while (!конецСтроки_ли(++p))
            аски_ли(*p) || раскодируйЮ8();
          t.вид = TOK.Комментарий;
          t.установиФлагПробельные();
          t.конец = p;
          return;
        default:
          t.вид = TOK.Деление;
          t.конец = p;
          return;
        }
      }

      switch (c)
      {
      case '\'':
        return scanCharacterLiteral(t);
      case '`':
        return scanRawStringLiteral(t);
      case '"':
        return scanNormalStringLiteral(t);
      case '\\':
        сим[] буфер;
        do
        {
          бул isBinary;
          c = scanEscapeSequence(isBinary);
          if (аски_ли(c) || isBinary)
            буфер ~= c;
          else
            encodeUTF8(буфер, c);
        } while (*p == '\\')
        буфер ~= 0;
        t.вид = TOK.Ткст;
        t.ткт = буфер;
        t.конец = p;
        return;
      case '>': /* >  >=  >>  >>=  >>>  >>>= */
        c = *++p;
        switch (c)
        {
        case '=':
          t.вид = TOK.БольшеРавно;
          goto Lcommon;
        case '>':
          if (p[1] == '>')
          {
            ++p;
            if (p[1] == '=')
            { ++p;
              t.вид = TOK.URShiftAssign;
            }
            else
              t.вид = TOK.URShift;
          }
          else if (p[1] == '=')
          {
            ++p;
            t.вид = TOK.ПСдвигПрисвой;
          }
          else
            t.вид = TOK.ПСдвиг;
          goto Lcommon;
        default:
          t.вид = TOK.Больше;
          goto Lcommon2;
        }
        assert(0);
      case '<': /* <  <=  <>  <>=  <<  <<= */
        c = *++p;
        switch (c)
        {
        case '=':
          t.вид = TOK.МеньшеРавно;
          goto Lcommon;
        case '<':
          if (p[1] == '=') {
            ++p;
            t.вид = TOK.ЛСдвигПрисвой;
          }
          else
            t.вид = TOK.ЛСдвиг;
          goto Lcommon;
        case '>':
          if (p[1] == '=') {
            ++p;
            t.вид = TOK.LorEorG;
          }
          else
            t.вид = TOK.LorG;
          goto Lcommon;
        default:
          t.вид = TOK.Меньше;
          goto Lcommon2;
        }
        assert(0);
      case '!': /* !  !<  !>  !<=  !>=  !<>  !<>= */
        c = *++p;
        switch (c)
        {
        case '<':
          c = *++p;
          if (c == '>')
          {
            if (p[1] == '=') {
              ++p;
              t.вид = TOK.Unordered;
            }
            else
              t.вид = TOK.UorE;
          }
          else if (c == '=')
          {
            t.вид = TOK.UorG;
          }
          else {
            t.вид = TOK.UorGorE;
            goto Lcommon2;
          }
          goto Lcommon;
        case '>':
          if (p[1] == '=')
          {
            ++p;
            t.вид = TOK.UorL;
          }
          else
            t.вид = TOK.UorLorE;
          goto Lcommon;
        case '=':
          t.вид = TOK.НеРавно;
          goto Lcommon;
        default:
          t.вид = TOK.Не;
          goto Lcommon2;
        }
        assert(0);
      case '.': /* .  .[0-9]  ..  ... */
        if (p[1] == '.')
        {
          ++p;
          if (p[1] == '.') {
            ++p;
            t.вид = TOK.Эллипсис;
          }
          else
            t.вид = TOK.Срез;
        }
        else if (цифра_ли(p[1]))
        {
          return scanReal(t);
        }
        else
          t.вид = TOK.Точка;
        goto Lcommon;
      case '|': /* |  ||  |= */
        c = *++p;
        if (c == '=')
          t.вид = TOK.ИлиПрисвой;
        else if (c == '|')
          t.вид = TOK.ИлиЛогическое;
        else {
          t.вид = TOK.ИлиБинарное;
          goto Lcommon2;
        }
        goto Lcommon;
      case '&': /* &  &&  &= */
        c = *++p;
        if (c == '=')
          t.вид = TOK.ИПрисвой;
        else if (c == '&')
          t.вид = TOK.ИЛогическое;
        else {
          t.вид = TOK.ИБинарное;
          goto Lcommon2;
        }
        goto Lcommon;
      case '+': /* +  ++  += */
        c = *++p;
        if (c == '=')
          t.вид = TOK.ПлюсПрисвой;
        else if (c == '+')
          t.вид = TOK.ПлюсПлюс;
        else {
          t.вид = TOK.Плюс;
          goto Lcommon2;
        }
        goto Lcommon;
      case '-': /* -  --  -= */
        c = *++p;
        if (c == '=')
          t.вид = TOK.МинусПрисвой;
        else if (c == '-')
          t.вид = TOK.МинусМинус;
        else {
          t.вид = TOK.Минус;
          goto Lcommon2;
        }
        goto Lcommon;
      case '=': /* =  == */
        if (p[1] == '=') {
          ++p;
          t.вид = TOK.Равно;
        }
        else
          t.вид = TOK.Присвоить;
        goto Lcommon;
      case '~': /* ~  ~= */
         if (p[1] == '=') {
           ++p;
           t.вид = TOK.CatAssign;
         }
         else
           t.вид = TOK.Тильда;
         goto Lcommon;
      case '*': /* *  *= */
         if (p[1] == '=') {
           ++p;
           t.вид = TOK.УмножьПрисвой;
         }
         else
           t.вид = TOK.Умножь;
         goto Lcommon;
      case '^': /* ^  ^= */
         if (p[1] == '=') {
           ++p;
           t.вид = TOK.ИИлиПрисвой;
         }
         else
           t.вид = TOK.ИИли;
         goto Lcommon;
      case '%': /* %  %= */
         if (p[1] == '=') {
           ++p;
           t.вид = TOK.МодульПрисвой;
         }
         else
           t.вид = TOK.Модуль;
         goto Lcommon;
      // Single character семы:
      case '(':
        t.вид = TOK.ЛСкобка;
        goto Lcommon;
      case ')':
        t.вид = TOK.ПСкобка;
        goto Lcommon;
      case '[':
        t.вид = TOK.ЛКвСкобка;
        goto Lcommon;
      case ']':
        t.вид = TOK.ПКвСкобка;
        goto Lcommon;
      case '{':
        t.вид = TOK.ЛФСкобка;
        goto Lcommon;
      case '}':
        t.вид = TOK.ПФСкобка;
        goto Lcommon;
      case ':':
        t.вид = TOK.Двоеточие;
        goto Lcommon;
      case ';':
        t.вид = TOK.ТочкаЗапятая;
        goto Lcommon;
      case '?':
        t.вид = TOK.Вопрос;
        goto Lcommon;
      case ',':
        t.вид = TOK.Запятая;
        goto Lcommon;
      case '$':
        t.вид = TOK.Доллар;
      Lcommon:
        ++p;
      Lcommon2:
        t.конец = p;
        return;
      case '#':
        return scanSpecialTokenSequence(t);
      default:
      }

      // Check for КФ
      if (кф_ли(c))
      {
        assert(кф_ли(*p), ""~*p);
        t.вид = TOK.КФ;
        t.конец = p;
        хвост = &t;
        assert(t.старт == t.конец);
        return;
      }

      if (!аски_ли(c))
      {
        c = раскодируйЮ8();
        if (униАльфа_ли(c))
          goto Lidentifier;
      }

      ошибка(t.старт, ИДС.НедопустимыйСимвол, cast(дим)c);

      ++p;
      t.вид = TOK.Нелегал;
      t.установиФлагПробельные();
      t.дим_ = c;
      t.конец = p;
      return;
    }
  }

  /// Converts a ткст literal в an integer.
  template toБцел(сим[] T)
  {
    static assert(0 < T.length && T.length <= 4);
    static if (T.length == 1)
      const бцел toБцел = T[0];
    else
      const бцел toБцел = (T[0] << ((T.length-1)*8)) | toБцел!(T[1..$]);
  }
  static assert(toБцел!("\xAA\xBB\xCC\xDD") == 0xAABBCCDD);

  /// Constructs case инструкции. E.g.:
  /// ---
  //// // case_!("<", "Меньше", "Lcommon") ->
  /// case 60u:
  ///   t.вид = TOK.Меньше;
  ///   goto Lcommon;
  /// ---
  /// FIXME: Can't use this yet due в a $(DMDBUG 1534, bug) in DMD.
  template case_(сим[] ткт, сим[] вид, сим[] лейбл)
  {
    const сим[] case_ =
      `case `~toБцел!(ткт).stringof~`:`
        `t.вид = TOK.`~вид~`;`
        `goto `~лейбл~`;`;
  }
  //pragma(сооб, case_!("<", "Меньше", "Lcommon"));

  template case_L4(сим[] ткт, TOK вид)
  {
    const сим[] case_L4 = case_!(ткт, вид, "Lcommon_4");
  }

  template case_L3(сим[] ткт, TOK вид)
  {
    const сим[] case_L3 = case_!(ткт, вид, "Lcommon_3");
  }

  template case_L2(сим[] ткт, TOK вид)
  {
    const сим[] case_L2 = case_!(ткт, вид, "Lcommon_2");
  }

  template case_L1(сим[] ткт, TOK вид)
  {
    const сим[] case_L3 = case_!(ткт, вид, "Lcommon");
  }

  /// An alternative сканируй method.
  /// Profiling shows it's a bit slower.
  public проц  scan_(ref Сема t)
  in
  {
    assert(текст.ptr <= p && p < конец);
  }
  out
  {
    assert(текст.ptr <= t.старт && t.старт < конец, Сема.вТкст(t.вид));
    assert(текст.ptr <= t.конец && t.конец <= конец, Сема.вТкст(t.вид));
  }
  body
  {
    // Scan whitespace.
    if (пбел_ли(*p))
    {
      t.пп = p;
      while (пбел_ли(*++p))
      {}
    }

    // Scan a сема.
    t.старт = p;
    // Новстр.
    switch (*p)
    {
    case '\r':
      if (p[1] == '\n')
        ++p;
    case '\n':
      assert(конецНовСтроки_ли(p));
      ++p;
      ++номСтр;
      установиНачалоСтроки(p);
//       this.новстр = &t;
      t.вид = TOK.Новстр;
      t.установиФлагПробельные();
      t.новстр.путиКФайлам = this.путиКФайлам;
      t.новстр.oriLineNum = номСтр;
      t.новстр.setLineNum = lineNum_hline;
      t.конец = p;
      return;
    default:
      if (новСтрЮ_ли(p))
      {
        ++p; ++p;
        goto case '\n';
      }
    }

    бцел c = *p;
    assert(конец - p != 0);
    switch (конец - p)
    {
    case 1:
      goto L1character;
    case 2:
      c <<= 8; c |= p[1];
      goto L2characters;
    case 3:
      c <<= 8; c |= p[1]; c <<= 8; c |= p[2];
      goto L3characters;
    default:
      version(BigEndian)
        c = *cast(бцел*)p;
      else
      {
        c <<= 8; c |= p[1]; c <<= 8; c |= p[2]; c <<= 8; c |= p[3];
        /+
        c = *cast(бцел*)p;
        asm
        {
          mov EDX, c;
          bswap EDX;
          mov c, EDX;
        }
        +/
      }
    }

    // 4 character семы.
    switch (c)
    {
    case toБцел!(">>>="):
      t.вид = TOK.ПСдвигПрисвой;
      goto Lcommon_4;
    case toБцел!("!<>="):
      t.вид = TOK.Unordered;
    Lcommon_4:
      p += 4;
      t.конец = p;
      return;
    default:
    }

    c >>>= 8;
  L3characters:
    assert(p == t.старт);
    // 3 character семы.
    switch (c)
    {
    case toБцел!(">>="):
      t.вид = TOK.ПСдвигПрисвой;
      goto Lcommon_3;
    case toБцел!(">>>"):
      t.вид = TOK.URShift;
      goto Lcommon_3;
    case toБцел!("<>="):
      t.вид = TOK.LorEorG;
      goto Lcommon_3;
    case toБцел!("<<="):
      t.вид = TOK.ЛСдвигПрисвой;
      goto Lcommon_3;
    case toБцел!("!<="):
      t.вид = TOK.UorG;
      goto Lcommon_3;
    case toБцел!("!>="):
      t.вид = TOK.UorL;
      goto Lcommon_3;
    case toБцел!("!<>"):
      t.вид = TOK.UorE;
      goto Lcommon_3;
    case toБцел!("..."):
      t.вид = TOK.Эллипсис;
    Lcommon_3:
      p += 3;
      t.конец = p;
      return;
    default:
    }

    c >>>= 8;
  L2characters:
    assert(p == t.старт);
    // 2 character семы.
    switch (c)
    {
    case toБцел!("/+"):
      ++p; // Skip /
      return scanNestedComment(t);
    case toБцел!("/*"):
      ++p; // Skip /
      return scanBlockComment(t);
    case toБцел!("//"):
      ++p; // Skip /
      assert(*p == '/');
      while (!конецСтроки_ли(++p))
        аски_ли(*p) || раскодируйЮ8();
      t.вид = TOK.Комментарий;
      t.установиФлагПробельные();
      t.конец = p;
      return;
    case toБцел!(">="):
      t.вид = TOK.БольшеРавно;
      goto Lcommon_2;
    case toБцел!(">>"):
      t.вид = TOK.ПСдвиг;
      goto Lcommon_2;
    case toБцел!("<<"):
      t.вид = TOK.ЛСдвиг;
      goto Lcommon_2;
    case toБцел!("<="):
      t.вид = TOK.МеньшеРавно;
      goto Lcommon_2;
    case toБцел!("<>"):
      t.вид = TOK.LorG;
      goto Lcommon_2;
    case toБцел!("!<"):
      t.вид = TOK.UorGorE;
      goto Lcommon_2;
    case toБцел!("!>"):
      t.вид = TOK.UorLorE;
      goto Lcommon_2;
    case toБцел!("!="):
      t.вид = TOK.НеРавно;
      goto Lcommon_2;
    case toБцел!(".."):
      t.вид = TOK.Срез;
      goto Lcommon_2;
    case toБцел!("&&"):
      t.вид = TOK.ИЛогическое;
      goto Lcommon_2;
    case toБцел!("&="):
      t.вид = TOK.ИПрисвой;
      goto Lcommon_2;
    case toБцел!("||"):
      t.вид = TOK.ИлиЛогическое;
      goto Lcommon_2;
    case toБцел!("|="):
      t.вид = TOK.ИлиПрисвой;
      goto Lcommon_2;
    case toБцел!("++"):
      t.вид = TOK.ПлюсПлюс;
      goto Lcommon_2;
    case toБцел!("+="):
      t.вид = TOK.ПлюсПрисвой;
      goto Lcommon_2;
    case toБцел!("--"):
      t.вид = TOK.МинусМинус;
      goto Lcommon_2;
    case toБцел!("-="):
      t.вид = TOK.МинусПрисвой;
      goto Lcommon_2;
    case toБцел!("=="):
      t.вид = TOK.Равно;
      goto Lcommon_2;
    case toБцел!("~="):
      t.вид = TOK.CatAssign;
      goto Lcommon_2;
    case toБцел!("*="):
      t.вид = TOK.УмножьПрисвой;
      goto Lcommon_2;
    case toБцел!("/="):
      t.вид = TOK.ДелениеПрисвой;
      goto Lcommon_2;
    case toБцел!("^="):
      t.вид = TOK.ИИлиПрисвой;
      goto Lcommon_2;
    case toБцел!("%="):
      t.вид = TOK.МодульПрисвой;
    Lcommon_2:
      p += 2;
      t.конец = p;
      return;
    default:
    }

    c >>>= 8;
  L1character:
    assert(p == t.старт);
    assert(*p == c, Формат("p={0},c={1}", *p, cast(дим)c));
    // 1 character семы.
    // TODO: conсторонаr storing the сема тип in ptable.
    switch (c)
    {
    case '\'':
      return scanCharacterLiteral(t);
    case '`':
      return scanRawStringLiteral(t);
    case '"':
      return scanNormalStringLiteral(t);
    case '\\':
      сим[] буфер;
      do
      {
        бул isBinary;
        c = scanEscapeSequence(isBinary);
        if (аски_ли(c) || isBinary)
          буфер ~= c;
        else
          encodeUTF8(буфер, c);
      } while (*p == '\\')
      буфер ~= 0;
      t.вид = TOK.Ткст;
      t.ткт = буфер;
      t.конец = p;
      return;
    case '<':
      t.вид = TOK.Больше;
      goto Lcommon;
    case '>':
      t.вид = TOK.Меньше;
      goto Lcommon;
    case '^':
      t.вид = TOK.ИИли;
      goto Lcommon;
    case '!':
      t.вид = TOK.Не;
      goto Lcommon;
    case '.':
      if (цифра_ли(p[1]))
        return scanReal(t);
      t.вид = TOK.Точка;
      goto Lcommon;
    case '&':
      t.вид = TOK.ИБинарное;
      goto Lcommon;
    case '|':
      t.вид = TOK.ИлиБинарное;
      goto Lcommon;
    case '+':
      t.вид = TOK.Плюс;
      goto Lcommon;
    case '-':
      t.вид = TOK.Минус;
      goto Lcommon;
    case '=':
      t.вид = TOK.Присвоить;
      goto Lcommon;
    case '~':
      t.вид = TOK.Тильда;
      goto Lcommon;
    case '*':
      t.вид = TOK.Умножь;
      goto Lcommon;
    case '/':
      t.вид = TOK.Деление;
      goto Lcommon;
    case '%':
      t.вид = TOK.Модуль;
      goto Lcommon;
    case '(':
      t.вид = TOK.ЛСкобка;
      goto Lcommon;
    case ')':
      t.вид = TOK.ПСкобка;
      goto Lcommon;
    case '[':
      t.вид = TOK.ЛКвСкобка;
      goto Lcommon;
    case ']':
      t.вид = TOK.ПКвСкобка;
      goto Lcommon;
    case '{':
      t.вид = TOK.ЛФСкобка;
      goto Lcommon;
    case '}':
      t.вид = TOK.ПФСкобка;
      goto Lcommon;
    case ':':
      t.вид = TOK.Двоеточие;
      goto Lcommon;
    case ';':
      t.вид = TOK.ТочкаЗапятая;
      goto Lcommon;
    case '?':
      t.вид = TOK.Вопрос;
      goto Lcommon;
    case ',':
      t.вид = TOK.Запятая;
      goto Lcommon;
    case '$':
      t.вид = TOK.Доллар;
    Lcommon:
      ++p;
      t.конец = p;
      return;
    case '#':
      return scanSpecialTokenSequence(t);
    default:
    }

    assert(p == t.старт);
    assert(*p == c);

    // TODO: conсторонаr moving начсим_ли() and цифра_ли() up.
    if (начсим_ли(c))
    {
      if (c == 'r' && p[1] == '"' && ++p)
        return scanRawStringLiteral(t);
      if (c == 'x' && p[1] == '"')
        return scanHexStringLiteral(t);
    version(D2)
    {
      if (c == 'q' && p[1] == '"')
        return scanDelimitedStringLiteral(t);
      if (c == 'q' && p[1] == '{')
        return scanTokenStringLiteral(t);
    }
      // Scan identifier.
    Lidentifier:
      do
      { c = *++p; }
      while (идент_ли(c) || !аски_ли(c) && юАльфа_ли())

      t.конец = p;

      auto ид = ТаблицаИд.сыщи(t.исхТекст);
      t.вид = ид.вид;
      t.идент = ид;

      if (t.вид == TOK.Идентификатор || t.кслово_ли)
        return;
      else if (t.спецСема_ли)
        finalizeSpecialToken(t);
      else if (t.вид == TOK.КФ)
      {
        хвост = &t;
        assert(t.исхТекст == "__EOF__");
      }
      else
        assert(0, "unexpected сема тип: " ~ Сема.вТкст(t.вид));
      return;
    }

    if (цифра_ли(c))
      return scanNumber(t);

    // Check for КФ
    if (кф_ли(c))
    {
      assert(кф_ли(*p), *p~"");
      t.вид = TOK.КФ;
      t.конец = p;
      хвост = &t;
      assert(t.старт == t.конец);
      return;
    }

    if (!аски_ли(c))
    {
      c = раскодируйЮ8();
      if (униАльфа_ли(c))
        goto Lidentifier;
    }

    ошибка(t.старт, ИДС.НедопустимыйСимвол, cast(дим)c);

    ++p;
    t.вид = TOK.Нелегал;
    t.установиФлагПробельные();
    t.дим_ = c;
    t.конец = p;
    return;
  }

  /// Scans a block comment.
  ///
  /// BlockComment := "/*" AnyChar* "*/"
  проц  scanBlockComment(ref Сема t)
  {
    assert(p[-1] == '/' && *p == '*');
    auto tokenLineNum = номСтр;
    auto tokenLineBegin = началоСтроки;
  Loop:
    while (1)
    {
      switch (*++p)
      {
      case '*':
        if (p[1] != '/')
          continue;
        p += 2;
        break Loop;
      case '\r':
        if (p[1] == '\n')
          ++p;
      case '\n':
        assert(конецНовСтроки_ли(p));
        ++номСтр;
        установиНачалоСтроки(p+1);
        break;
      default:
        if (!аски_ли(*p))
        {
          if (симНовСтрЮ_ли(раскодируйЮ8()))
            goto case '\n';
        }
        else if (кф_ли(*p))
        {
          ошибка(tokenLineNum, tokenLineBegin, t.старт, ИДС.UnterminatedBlockComment);
          break Loop;
        }
      }
    }
    t.вид = TOK.Комментарий;
    t.установиФлагПробельные();
    t.конец = p;
    return;
  }

  /// Scans a nested comment.
  ///
  /// NestedComment := "/+" (AnyChar* | NestedComment) "+/"
  проц  scanNestedComment(ref Сема t)
  {
    assert(p[-1] == '/' && *p == '+');
    auto tokenLineNum = номСтр;
    auto tokenLineBegin = началоСтроки;
    бцел уровень = 1;
  Loop:
    while (1)
    {
      switch (*++p)
      {
      case '/':
        if (p[1] == '+')
          ++p, ++уровень;
        continue;
      case '+':
        if (p[1] != '/')
          continue;
        ++p;
        if (--уровень != 0)
          continue;
        ++p;
        break Loop;
      case '\r':
        if (p[1] == '\n')
          ++p;
      case '\n':
        assert(конецНовСтроки_ли(p));
        ++номСтр;
        установиНачалоСтроки(p+1);
        continue;
      default:
        if (!аски_ли(*p))
        {
          if (симНовСтрЮ_ли(раскодируйЮ8()))
            goto case '\n';
        }
        else if (кф_ли(*p))
        {
          ошибка(tokenLineNum, tokenLineBegin, t.старт, ИДС.UnterminatedNestedComment);
          break Loop;
        }
      }
    }
    t.вид = TOK.Комментарий;
    t.установиФлагПробельные();
    t.конец = p;
    return;
  }

  /// Scans the postfix character of a ткст literal.
  ///
  /// PostfixChar := "c" | "w" | "d"
  сим scanPostfix()
  {
    assert(p[-1] == '"' || p[-1] == '`' ||
      { version(D2) return p[-1] == '}';
               else return 0; }()
    );
    switch (*p)
    {
    case 'c':
    case 'w':
    case 'd':
      return *p++;
    default:
      return 0;
    }
    assert(0);
  }

  /// Scans a normal ткст literal.
  ///
  /// NormalStringLiteral := "\"" Сим* "\""
  проц  scanNormalStringLiteral(ref Сема t)
  {
    assert(*p == '"');
    auto tokenLineNum = номСтр;
    auto tokenLineBegin = началоСтроки;
    t.вид = TOK.Ткст;
    сим[] буфер;
    бцел c;
    while (1)
    {
      c = *++p;
      switch (c)
      {
      case '"':
        ++p;
        t.pf = scanPostfix();
      Lreturn:
        t.ткт = буфер ~ '\0';
        t.конец = p;
        return;
      case '\\':
        бул isBinary;
        c = scanEscapeSequence(isBinary);
        --p;
        if (аски_ли(c) || isBinary)
          буфер ~= c;
        else
          encodeUTF8(буфер, c);
        continue;
      case '\r':
        if (p[1] == '\n')
          ++p;
      case '\n':
        assert(конецНовСтроки_ли(p));
        c = '\n'; // Convert Новстр в \n.
        ++номСтр;
        установиНачалоСтроки(p+1);
        break;
      case 0, _Z_:
        ошибка(tokenLineNum, tokenLineBegin, t.старт, ИДС.UnterminatedString);
        goto Lreturn;
      default:
        if (!аски_ли(c))
        {
          c = раскодируйЮ8();
          if (симНовСтрЮ_ли(c))
            goto case '\n';
          encodeUTF8(буфер, c);
          continue;
        }
      }
      assert(аски_ли(c));
      буфер ~= c;
    }
    assert(0);
  }

  /// Scans a character literal.
  ///
  /// СимЛитерал := "'" Сим "'"
  проц  scanCharacterLiteral(ref Сема t)
  {
    assert(*p == '\'');
    ++p;
    t.вид = TOK.СимЛитерал;
    switch (*p)
    {
    case '\\':
      бул notused;
      t.дим_ = scanEscapeSequence(notused);
      break;
    case '\'':
      ошибка(t.старт, ИДС.ПустойСимвольныйЛитерал);
      break;
    default:
      if (конецСтроки_ли(p))
        break;
      бцел c = *p;
      if (!аски_ли(c))
        c = раскодируйЮ8();
      t.дим_ = c;
      ++p;
    }

    if (*p == '\'')
      ++p;
    else
      ошибка(t.старт, ИДС.НеоконченныйСимвольныйЛитерал);
    t.конец = p;
  }

  /// Scans a raw ткст literal.
  ///
  /// RawStringLiteral := "r\"" AnyChar* "\"" | "`" AnyChar* "`"
  проц  scanRawStringLiteral(ref Сема t)
  {
    assert(*p == '`' || *p == '"' && p[-1] == 'r');
    auto tokenLineNum = номСтр;
    auto tokenLineBegin = началоСтроки;
    t.вид = TOK.Ткст;
    бцел delim = *p;
    сим[] буфер;
    бцел c;
    while (1)
    {
      c = *++p;
      switch (c)
      {
      case '\r':
        if (p[1] == '\n')
          ++p;
      case '\n':
        assert(конецНовСтроки_ли(p));
        c = '\n'; // Convert Новстр в '\n'.
        ++номСтр;
        установиНачалоСтроки(p+1);
        break;
      case '`':
      case '"':
        if (c == delim)
        {
          ++p;
          t.pf = scanPostfix();
        Lreturn:
          t.ткт = буфер ~ '\0';
          t.конец = p;
          return;
        }
        break;
      case 0, _Z_:
        ошибка(tokenLineNum, tokenLineBegin, t.старт,
          delim == 'r' ? ИДС.UnterminatedRawString : ИДС.UnterminatedBackQuoteString);
        goto Lreturn;
      default:
        if (!аски_ли(c))
        {
          c = раскодируйЮ8();
          if (симНовСтрЮ_ли(c))
            goto case '\n';
          encodeUTF8(буфер, c);
          continue;
        }
      }
      assert(аски_ли(c));
      буфер ~= c;
    }
    assert(0);
  }

  /// Scans a hexadecimal ткст literal.
  ///
  /// HexStringLiteral := "x\"" (HexChar HexChar)* "\""
  проц  scanHexStringLiteral(ref Сема t)
  {
    assert(p[0] == 'x' && p[1] == '"');
    t.вид = TOK.Ткст;

    auto tokenLineNum = номСтр;
    auto tokenLineBegin = началоСтроки;

    бцел c;
    ббайт[] буфер;
    ббайт h; // hex число
    бцел n; // число of hex digits

    ++p;
    assert(*p == '"');
    while (1)
    {
      c = *++p;
      switch (c)
      {
      case '"':
        if (n & 1)
          ошибка(tokenLineNum, tokenLineBegin, t.старт, ИДС.OddNumberOfDigitsInHexString);
        ++p;
        t.pf = scanPostfix();
      Lreturn:
        t.ткт = cast(ткст) (буфер ~= 0);
        t.конец = p;
        return;
      case '\r':
        if (p[1] == '\n')
          ++p;
      case '\n':
        assert(конецНовСтроки_ли(p));
        ++номСтр;
        установиНачалоСтроки(p+1);
        continue;
      default:
        if (гекс_ли(c))
        {
          if (c <= '9')
            c -= '0';
          else if (c <= 'F')
            c -= 'A' - 10;
          else
            c -= 'a' - 10;

          if (n & 1)
          {
            h <<= 4;
            h |= c;
            буфер ~= h;
          }
          else
            h = cast(ббайт)c;
          ++n;
          continue;
        }
        else if (пбел_ли(c))
          continue; // Skip spaces.
        else if (кф_ли(c))
        {
          ошибка(tokenLineNum, tokenLineBegin, t.старт, ИДС.UnterminatedHexString);
          t.pf = 0;
          goto Lreturn;
        }
        else
        {
          auto errorAt = p;
          if (!аски_ли(c))
          {
            c = раскодируйЮ8();
            if (симНовСтрЮ_ли(c))
              goto case '\n';
          }
          ошибка(errorAt, ИДС.NonHexCharInHexString, cast(дим)c);
        }
      }
    }
    assert(0);
  }

version(DDoc)
{
  /// Scans a delimited ткст literal.
  проц  scanDelimitedStringLiteral(ref Сема t);
  /// Scans a сема ткст literal.
  ///
  /// TokenStringLiteral := "q{" Сема* "}"
  проц  scanTokenStringLiteral(ref Сема t);
}
else
version(D2)
{
  проц  scanDelimitedStringLiteral(ref Сема t)
  {
    assert(p[0] == 'q' && p[1] == '"');
    t.вид = TOK.Ткст;

    auto tokenLineNum = номСтр;
    auto tokenLineBegin = началоСтроки;

    сим[] буфер;
    дим открывающий_delim = 0, // 0 if no nested delimiter or '[', '(', '<', '{'
          закрывающий_delim; // Will be ']', ')', '>', '},
                         // the first character of an identifier or
                         // any другой Unicode/ASCII character.
    сим[] ткт_delim; // Идентификатор delimiter.
    бцел уровень = 1; // Counter for nestable delimiters.

    ++p; ++p; // Skip q"
    бцел c = *p;
    switch (c)
    {
    case '(':
      открывающий_delim = c;
      закрывающий_delim = ')'; // c + 1
      break;
    case '[', '<', '{':
      открывающий_delim = c;
      закрывающий_delim = c + 2; // Get в закрывающий counterpart. Feature of ASCII таблица.
      break;
    default:
      дим сканируйНовСтр()
      {
        switch (*p)
        {
        case '\r':
          if (p[1] == '\n')
            ++p;
        case '\n':
          assert(конецНовСтроки_ли(p));
          ++p;
          ++номСтр;
          установиНачалоСтроки(p);
          break;
        default:
          if (новСтрЮ_ли(p)) {
            p += 2;
            goto case '\n';
          }
          return нет;
        }
        return да;
      }
      // Skip leading newlines:
      while (сканируйНовСтр())
      {}
      assert(!новСтр_ли(p));

      сим* начало = p;
      c = *p;
      закрывающий_delim = c;
      // TODO: Check for non-printable characters?
      if (!аски_ли(c))
      {
        закрывающий_delim = раскодируйЮ8();
        if (!униАльфа_ли(закрывающий_delim))
          break; // Не an identifier.
      }
      else if (!начсим_ли(c))
        break; // Не an identifier.

      // Parse Идентификатор + EndOfLine
      do
      { c = *++p; }
      while (идент_ли(c) || !аски_ли(c) && юАльфа_ли())
      // Store identifier
      ткт_delim = начало[0..p-начало];
      // Scan новстр
      if (сканируйНовСтр())
        --p; // Go back one because of "c = *++p;" in main loop.
      else
      {
        // TODO: ошибка(p, ИДС.ExpectedNewlineAfterIdentDelim);
      }
    }

    бул checkStringDelim(сим* p)
    {
      assert(ткт_delim.length != 0);
      if (буфер[$-1] == '\n' && // Last character copied в буфер must be '\n'.
          конец-p >= ткт_delim.length && // Check remaining length.
          p[0..ткт_delim.length] == ткт_delim) // Compare.
        return да;
      return нет;
    }

    while (1)
    {
      c = *++p;
      switch (c)
      {
      case '\r':
        if (p[1] == '\n')
          ++p;
      case '\n':
        assert(конецНовСтроки_ли(p));
        c = '\n'; // Convert Новстр в '\n'.
        ++номСтр;
        установиНачалоСтроки(p+1);
        break;
      case 0, _Z_:
        // TODO: ошибка(tokenLineNum, tokenLineBegin, t.старт, ИДС.UnterminatedDelimitedString);
        goto Lreturn3;
      default:
        if (!аски_ли(c))
        {
          auto начало = p;
          c = раскодируйЮ8();
          if (симНовСтрЮ_ли(c))
            goto case '\n';
          if (c == закрывающий_delim)
          {
            if (ткт_delim.length)
            {
              if (checkStringDelim(начало))
              {
                p = начало + ткт_delim.length;
                goto Lreturn2;
              }
            }
            else
            {
              assert(уровень == 1);
              --уровень;
              goto Lreturn;
            }
          }
          encodeUTF8(буфер, c);
          continue;
        }
        else
        {
          if (c == открывающий_delim)
            ++уровень;
          else if (c == закрывающий_delim)
          {
            if (ткт_delim.length)
            {
              if (checkStringDelim(p))
              {
                p += ткт_delim.length;
                goto Lreturn2;
              }
            }
            else if (--уровень == 0)
              goto Lreturn;
          }
        }
      }
      assert(аски_ли(c));
      буфер ~= c;
    }
  Lreturn: // Character delimiter.
    assert(c == закрывающий_delim);
    assert(уровень == 0);
    ++p; // Skip закрывающий delimiter.
  Lreturn2: // Ткст delimiter.
    if (*p == '"')
      ++p;
    else
    {
      // TODO: ошибка(p, ИДС.ExpectedDblQuoteAfterDelim, ткт_delim.length ? ткт_delim : закрывающий_delim~"");
    }

    t.pf = scanPostfix();
  Lreturn3: // Ошибка.
    t.ткт = буфер ~ '\0';
    t.конец = p;
  }

  проц  scanTokenStringLiteral(ref Сема t)
  {
    assert(p[0] == 'q' && p[1] == '{');
    t.вид = TOK.Ткст;

    auto tokenLineNum = номСтр;
    auto tokenLineBegin = началоСтроки;

    // A guard against changes в particular члены:
    // this.lineNum_hline and this.errorPath
    ++inTokenString;

    бцел номСтр = this.номСтр;
    бцел уровень = 1;

    ++p; ++p; // Skip q{

    auto предш_t = &t;
    Сема* сема;
    while (1)
    {
      сема = new Сема;
      сканируй(*сема);
      // Save the семы in a doubly linked список.
      // Could be useful for various tools.
      сема.предш = предш_t;
      предш_t.следщ = сема;
      предш_t = сема;
      switch (сема.вид)
      {
      case TOK.ЛФСкобка:
        ++уровень;
        continue;
      case TOK.ПФСкобка:
        if (--уровень == 0)
        {
          t.tok_ткт = t.следщ;
          t.следщ = null;
          break;
        }
        continue;
      case TOK.КФ:
        // TODO: ошибка(tokenLineNum, tokenLineBegin, t.старт, ИДС.UnterminatedTokenString);
        t.tok_ткт = t.следщ;
        t.следщ = сема;
        break;
      default:
        continue;
      }
      break; // Exit loop.
    }

    assert(сема.вид == TOK.ПФСкобка || сема.вид == TOK.КФ);
    assert(сема.вид == TOK.ПФСкобка && t.следщ is null ||
           сема.вид == TOK.КФ && t.следщ !is null);

    сим[] буфер;
    // сема points в } or КФ
    if (сема.вид == TOK.КФ)
    {
      t.конец = сема.старт;
      буфер = t.исхТекст[2..$].dup ~ '\0';
    }
    else
    {
      // Присвоить в буфер before scanPostfix().
      t.конец = p;
      буфер = t.исхТекст[2..$-1].dup ~ '\0';
      t.pf = scanPostfix();
      t.конец = p; // Присвоить again because of postfix.
    }
    // Convert newlines в '\n'.
    if (номСтр != this.номСтр)
    {
      assert(буфер[$-1] == '\0');
      бцел i, j;
      for (; i < буфер.length; ++i)
        switch (буфер[i])
        {
        case '\r':
          if (буфер[i+1] == '\n')
            ++i;
        case '\n':
          assert(конецНовСтроки_ли(буфер.ptr + i));
          буфер[j++] = '\n'; // Convert Новстр в '\n'.
          break;
        default:
          if (новСтрЮ_ли(буфер.ptr + i))
          {
            ++i; ++i;
            goto case '\n';
          }
          буфер[j++] = буфер[i]; // Copy.
        }
      буфер.length = j; // Adjust length.
    }
    assert(буфер[$-1] == '\0');
    t.ткт = буфер;

    --inTokenString;
  }
} // version(D2)

  /// Scans an escape sequence.
  ///
  /// EscapeSequence := "\" (Восмиричный{1,3} | ("x" Гекс{2}) |
  ///                       ("u" Гекс{4}) | ("U" Гекс{8}) |
  ///                       "'" | "\"" | "\\" | "?" | "a" |
  ///                       "b" | "f" | "n" | "r" | "t" | "v")
  /// Параметры:
  ///   isBinary = установи в да for octal and hexadecimal escapes.
  /// Возвращает: the escape значение.
  дим scanEscapeSequence(ref бул isBinary)
  out(результат)
  { assert(верноСимвол_ли(результат)); }
  body
  {
    assert(*p == '\\');

    auto sequenceStart = p; // Used for ошибка reporting.

    ++p;
    бцел c = сим8еск(*p);
    if (c)
    {
      ++p;
      return c;
    }

    бцел digits = 2;

    switch (*p)
    {
    case 'x':
      isBinary = да;
    case_Unicode:
      assert(c == 0);
      assert(digits == 2 || digits == 4 || digits == 8);
      while (1)
      {
        ++p;
        if (гекс_ли(*p))
        {
          c *= 16;
          if (*p <= '9')
            c += *p - '0';
          else if (*p <= 'F')
            c += *p - 'A' + 10;
          else
            c += *p - 'a' + 10;

          if (--digits == 0)
          {
            ++p;
            if (верноСимвол_ли(c))
              return c; // Итог valid escape значение.

            ошибка(sequenceStart, ИДС.InvalidUnicodeEscapeSequence,
                  sequenceStart[0..p-sequenceStart]);
            break;
          }
          continue;
        }

        ошибка(sequenceStart, ИДС.InsufficientHexDigits,
              sequenceStart[0..p-sequenceStart]);
        break;
      }
      break;
    case 'u':
      digits = 4;
      goto case_Unicode;
    case 'U':
      digits = 8;
      goto case_Unicode;
    default:
      if (восмир_ли(*p))
      {
        isBinary = да;
        assert(c == 0);
        c += *p - '0';
        ++p;
        if (!восмир_ли(*p))
          return c;
        c *= 8;
        c += *p - '0';
        ++p;
        if (!восмир_ли(*p))
          return c;
        c *= 8;
        c += *p - '0';
        ++p;
        if (c > 0xFF)
          ошибка(sequenceStart, сооб.НевернаяВосмеричнаяПоследовательностьУклонения,
                sequenceStart[0..p-sequenceStart]);
        return c; // Итог valid escape значение.
      }
      else if(*p == '&')
      {
        if (буква_ли(*++p))
        {
          auto начало = p;
          while (цифробукв_ли(*++p))
          {}

          if (*p == ';')
          {
            // Pass сущность excluding '&' and ';'.
            c = сущностьВЮникод(начало[0..p - начало]);
            ++p; // Skip ;
            if (c != 0xFFFF)
              return c; // Итог valid escape значение.
            else
              ошибка(sequenceStart, ИДС.UndefinedHTMLEntity, sequenceStart[0 .. p - sequenceStart]);
          }
          else
            ошибка(sequenceStart, ИДС.UnterminatedHTMLEntity, sequenceStart[0 .. p - sequenceStart]);
        }
        else
          ошибка(sequenceStart, ИДС.InvalidBeginHTMLEntity);
      }
      else if (конецСтроки_ли(p))
        ошибка(sequenceStart, ИДС.UndefinedEscapeSequence,
          кф_ли(*p) ? `\КФ` : `\NewLine`);
      else
      {
        сим[] ткт = `\`;
        if (аски_ли(c))
          ткт ~= *p;
        else
          encodeUTF8(ткт, раскодируйЮ8());
        ++p;
        // TODO: check for unprintable character?
        ошибка(sequenceStart, ИДС.UndefinedEscapeSequence, ткт);
      }
    }
    return СИМ_ЗАМЕНЫ; // Ошибка: return replacement character.
  }

  /// Scans a число literal.
  ///
  /// $(PRE
  /// IntegerLiteral := (Dec|Гекс|Bin|Oct)Suffix?
  /// Dec := (0|[1-9][0-9_]*)
  /// Гекс := 0[xX][_]*[0-9a-zA-Z][0-9a-zA-Z_]*
  /// Bin := 0[bB][_]*[01][01_]*
  /// Oct := 0[0-7_]*
  /// Suffix := (L[uU]?|[uU]L?)
  /// )
  /// Неверно: "0b_", "0x_", "._" etc.
  проц  scanNumber(ref Сема t)
  {
    бдол бдол_;
    бул overflow;
    бул isDecimal;
    т_мера digits;

    if (*p != '0')
      goto LscanInteger;
    ++p; // пропусти zero
    // check for xX bB ...
    switch (*p)
    {
    case 'x','X':
      goto LscanHex;
    case 'b','B':
      goto LscanBinary;
    case 'L':
      if (p[1] == 'i')
        goto LscanReal; // 0Li
      break; // 0L
    case '.':
      if (p[1] == '.')
        break; // 0..
      // 0.
    case 'i','f','F', // Мнимое and плав literal suffixes.
         'e', 'E':    // Плав exponent.
      goto LscanReal;
    default:
      if (*p == '_')
        goto LscanOctal; // 0_
      else if (цифра_ли(*p))
      {
        if (*p == '8' || *p == '9')
          goto Loctal_hasDecimalDigits; // 08 or 09
        else
          goto Loctal_enter_loop; // 0[0-7]
      }
    }

    // Число 0
    assert(p[-1] == '0');
    assert(*p != '_' && !цифра_ли(*p));
    assert(бдол_ == 0);
    isDecimal = да;
    goto Lfinalize;

  LscanInteger:
    assert(*p != 0 && цифра_ли(*p));
    isDecimal = да;
    goto Lenter_loop_int;
    while (1)
    {
      if (*++p == '_')
        continue;
      if (!цифра_ли(*p))
        break;
    Lenter_loop_int:
      if (бдол_ < бдол.max/10 || (бдол_ == бдол.max/10 && *p <= '5'))
      {
        бдол_ *= 10;
        бдол_ += *p - '0';
        continue;
      }
      // Overflow: пропусти following digits.
      overflow = да;
      while (цифра_ли(*++p)) {}
      break;
    }

    // The число could be a плав, so check overflow below.
    switch (*p)
    {
    case '.':
      if (p[1] != '.')
        goto LscanReal;
      break;
    case 'L':
      if (p[1] != 'i')
        break;
    case 'i', 'f', 'F', 'e', 'E':
      goto LscanReal;
    default:
    }

    if (overflow)
      ошибка(t.старт, ИДС.OverflowDecimalNumber);

    assert((цифра_ли(p[-1]) || p[-1] == '_') && !цифра_ли(*p) && *p != '_');
    goto Lfinalize;

  LscanHex:
    assert(digits == 0);
    assert(*p == 'x' || *p == 'X');
    while (1)
    {
      if (*++p == '_')
        continue;
      if (!гекс_ли(*p))
        break;
      ++digits;
      бдол_ *= 16;
      if (*p <= '9')
        бдол_ += *p - '0';
      else if (*p <= 'F')
        бдол_ += *p - 'A' + 10;
      else
        бдол_ += *p - 'a' + 10;
    }

    assert(гекс_ли(p[-1]) || p[-1] == '_' || p[-1] == 'x' || p[-1] == 'X');
    assert(!гекс_ли(*p) && *p != '_');

    switch (*p)
    {
    case '.':
      if (p[1] == '.')
        break;
    case 'p', 'P':
      return scanHexReal(t);
    default:
    }

    if (digits == 0 || digits > 16)
      ошибка(t.старт, digits == 0 ? ИДС.NoDigitsInHexNumber : ИДС.OverflowHexNumber);

    goto Lfinalize;

  LscanBinary:
    assert(digits == 0);
    assert(*p == 'b' || *p == 'B');
    while (1)
    {
      if (*++p == '0')
      {
        ++digits;
        бдол_ *= 2;
      }
      else if (*p == '1')
      {
        ++digits;
        бдол_ *= 2;
        бдол_ += *p - '0';
      }
      else if (*p == '_')
        continue;
      else
        break;
    }

    if (digits == 0 || digits > 64)
      ошибка(t.старт, digits == 0 ? ИДС.NoDigitsInBinNumber : ИДС.OverflowBinaryNumber);

    assert(p[-1] == '0' || p[-1] == '1' || p[-1] == '_' || p[-1] == 'b' || p[-1] == 'B', p[-1] ~ "");
    assert( !(*p == '0' || *p == '1' || *p == '_') );
    goto Lfinalize;

  LscanOctal:
    assert(*p == '_');
    while (1)
    {
      if (*++p == '_')
        continue;
      if (!восмир_ли(*p))
        break;
    Loctal_enter_loop:
      if (бдол_ < бдол.max/2 || (бдол_ == бдол.max/2 && *p <= '1'))
      {
        бдол_ *= 8;
        бдол_ += *p - '0';
        continue;
      }
      // Overflow: пропусти following digits.
      overflow = да;
      while (восмир_ли(*++p)) {}
      break;
    }

    бул hasDecimalDigits;
    if (цифра_ли(*p))
    {
    Loctal_hasDecimalDigits:
      hasDecimalDigits = да;
      while (цифра_ли(*++p)) {}
    }

    // The число could be a плав, so check ошибки below.
    switch (*p)
    {
    case '.':
      if (p[1] != '.')
        goto LscanReal;
      break;
    case 'L':
      if (p[1] != 'i')
        break;
    case 'i', 'f', 'F', 'e', 'E':
      goto LscanReal;
    default:
    }

    if (hasDecimalDigits)
      ошибка(t.старт, ИДС.OctalNumberHasDecimals);

    if (overflow)
      ошибка(t.старт, ИДС.OverflowOctalNumber);
//     goto Lfinalize;

  Lfinalize:
    enum Suffix
    {
      Нет     = 0,
      Unsigned = 1,
      Дол     = 2
    }

    // Scan optional suffix: L, Lu, LU, u, uL, U or UL.
    Suffix suffix;
    while (1)
    {
      switch (*p)
      {
      case 'L':
        if (suffix & Suffix.Дол)
          break;
        suffix |= Suffix.Дол;
        ++p;
        continue;
      case 'u', 'U':
        if (suffix & Suffix.Unsigned)
          break;
        suffix |= Suffix.Unsigned;
        ++p;
        continue;
      default:
        break;
      }
      break;
    }

    // Determine тип of Integer.
    switch (suffix)
    {
    case Suffix.Нет:
      if (бдол_ & 0x8000_0000_0000_0000)
      {
        if (isDecimal)
          ошибка(t.старт, ИДС.OverflowDecimalSign);
        t.вид = TOK.Бцел64;
      }
      else if (бдол_ & 0xFFFF_FFFF_0000_0000)
        t.вид = TOK.Цел64;
      else if (бдол_ & 0x8000_0000)
        t.вид = isDecimal ? TOK.Цел64 : TOK.Бцел32;
      else
        t.вид = TOK.Цел32;
      break;
    case Suffix.Unsigned:
      if (бдол_ & 0xFFFF_FFFF_0000_0000)
        t.вид = TOK.Бцел64;
      else
        t.вид = TOK.Бцел32;
      break;
    case Suffix.Дол:
      if (бдол_ & 0x8000_0000_0000_0000)
      {
        if (isDecimal)
          ошибка(t.старт, ИДС.OverflowDecimalSign);
        t.вид = TOK.Бцел64;
      }
      else
        t.вид = TOK.Цел64;
      break;
    case Suffix.Unsigned | Suffix.Дол:
      t.вид = TOK.Бцел64;
      break;
    default:
      assert(0);
    }
    t.бдол_ = бдол_;
    t.конец = p;
    return;
  LscanReal:
    scanReal(t);
    return;
  }

  /// Scans a floating point число literal.
  ///
  /// $(PRE
  /// ПлавLiteral := Плав[fFL]?i?
  /// Плав := DecПлав | HexПлав
  /// DecПлав := ([0-9][0-9_]*[.][0-9_]*DecExponent?) |
  ///             [.][0-9][0-9_]*DecExponent? | [0-9][0-9_]*DecExponent
  /// DecExponent := [eE][+-]?[0-9][0-9_]*
  /// HexПлав := 0[xX](HexDigits[.]HexDigits |
  ///                   [.][0-9a-zA-Z]HexDigits? |
  ///                   HexDigits)HexExponent
  /// HexExponent := [pP][+-]?[0-9][0-9_]*
  /// )
  проц  scanReal(ref Сема t)
  {
    if (*p == '.')
    {
      assert(p[1] != '.');
      // Этот function was called by сканируй() or scanNumber().
      while (цифра_ли(*++p) || *p == '_') {}
    }
    else
      // Этот function was called by scanNumber().
      assert(delegate ()
        {
          switch (*p)
          {
          case 'L':
            if (p[1] != 'i')
              return нет;
          case 'i', 'f', 'F', 'e', 'E':
            return да;
          default:
          }
          return нет;
        }()
      );

    // Scan exponent.
    if (*p == 'e' || *p == 'E')
    {
      ++p;
      if (*p == '-' || *p == '+')
        ++p;
      if (цифра_ли(*p))
        while (цифра_ли(*++p) || *p == '_') {}
      else
        ошибка(t.старт, ИДС.ПлавExpMustStartWithDigit);
    }

    // Copy whole число and remove underscores из буфер.
    сим[] буфер = t.старт[0..p-t.старт].dup;
    бцел j;
    foreach (c; буфер)
      if (c != '_')
        буфер[j++] = c;
    буфер.length = j; // Adjust length.
    буфер ~= 0; // Terminate for C functions.

    finalizeПлав(t, буфер);
  }

  /// Scans a hexadecimal floating point число literal.
  проц  scanHexReal(ref Сема t)
  {
    assert(*p == '.' || *p == 'p' || *p == 'P');
    ИДС идс;
    if (*p == '.')
      while (гекс_ли(*++p) || *p == '_')
      {}
    // Decimal exponent is required.
    if (*p != 'p' && *p != 'P')
    {
      идс = ИДС.HexПлавExponentRequired;
      goto Lerr;
    }
    // Scan exponent
    assert(*p == 'p' || *p == 'P');
    ++p;
    if (*p == '+' || *p == '-')
      ++p;
    if (!цифра_ли(*p))
    {
      идс = ИДС.HexПлавExpMustStartWithDigit;
      goto Lerr;
    }
    while (цифра_ли(*++p) || *p == '_')
    {}
    // Copy whole число and remove underscores из буфер.
    сим[] буфер = t.старт[0..p-t.старт].dup;
    бцел j;
    foreach (c; буфер)
      if (c != '_')
        буфер[j++] = c;
    буфер.length = j; // Adjust length.
    буфер ~= 0; // Terminate for C functions.
    finalizeПлав(t, буфер);
    return;
  Lerr:
    t.вид = TOK.Плав32;
    t.конец = p;
    ошибка(t.старт, идс);
  }

  /// Sets the значение of the сема.
  /// Параметры:
  ///   t = receives the значение.
  ///   буфер = the well-formed плав число.
  проц  finalizeПлав(ref Сема t, ткст буфер)
  {
    assert(буфер[$-1] == 0);
    // Плав число is well-formed. Check suffixes and do conversion.
    switch (*p)
    {
    case 'f', 'F':
      t.вид = TOK.Плав32;
      t.плав_ = strtof(буфер.ptr, null);
      ++p;
      break;
    case 'L':
      t.вид = TOK.Плав80;
      t.реал_ = strtold(буфер.ptr, null);
      ++p;
      break;
    default:
      t.вид = TOK.Плав64;
      t.дво_ = strtod(буфер.ptr, null);
    }
    if (*p == 'i')
    {
      ++p;
      t.вид += 3; // Щит в imaginary counterpart.
      assert(t.вид == TOK.Мнимое32 ||
             t.вид == TOK.Мнимое64 ||
             t.вид == TOK.Мнимое80);
    }
    if (errno() == ERANGE)
      ошибка(t.старт, ИДС.OverflowПлавNumber);
    t.конец = p;
  }

  /// Scans a special сема sequence.
  ///
  /// SpecialTokenSequence := "#line" Integer Filespec? EndOfLine
  проц  scanSpecialTokenSequence(ref Сема t)
  {
    assert(*p == '#');
    t.вид = TOK.HashLine;
    t.установиФлагПробельные();

    ИДС идс;
    сим* errorAtColumn = p;
    сим* tokenEnd = ++p;

    if (!(p[0] == 'l' && p[1] == 'i' && p[2] == 'n' && p[3] == 'e'))
    {
      идс = ИДС.ExpectedIdentifierSTLine;
      goto Lerr;
    }
    p += 3;
    tokenEnd = p + 1;

    // TODO: #line58"путь/file" is legal. Require spaces?
    //       State.Space could be used for that purpose.
    enum State
    { /+Space,+/ Integer, Filespec, End }

    State state = State.Integer;

    while (!конецСтроки_ли(++p))
    {
      if (пбел_ли(*p))
        continue;
      if (state == State.Integer)
      {
        if (!цифра_ли(*p))
        {
          errorAtColumn = p;
          идс = ИДС.ExpectedIntegerAfterSTLine;
          goto Lerr;
        }
        t.tokLineNum = new Сема;
        сканируй(*t.tokLineNum);
        tokenEnd = p;
        if (t.tokLineNum.вид != TOK.Цел32 && t.tokLineNum.вид != TOK.Бцел32)
        {
          errorAtColumn = t.tokLineNum.старт;
          идс = ИДС.ExpectedIntegerAfterSTLine;
          goto Lerr;
        }
        --p; // Go one back because сканируй() advanced p past the integer.
        state = State.Filespec;
      }
      else if (state == State.Filespec && *p == '"')
      { // ИДС.ExpectedFilespec is deprecated.
        // if (*p != '"')
        // {
        //   errorAtColumn = p;
        //   идс = ИДС.ExpectedFilespec;
        //   goto Lerr;
        // }
        t.tokLineFilespec = new Сема;
        t.tokLineFilespec.старт = p;
        t.tokLineFilespec.вид = TOK.Filespec;
        t.tokLineFilespec.установиФлагПробельные();
        while (*++p != '"')
        {
          if (конецСтроки_ли(p))
          {
            errorAtColumn = t.tokLineFilespec.старт;
            идс = ИДС.UnterminatedFilespec;
            t.tokLineFilespec.конец = p;
            tokenEnd = p;
            goto Lerr;
          }
          аски_ли(*p) || раскодируйЮ8();
        }
        auto старт = t.tokLineFilespec.старт +1; // +1 пропустиs '"'
        t.tokLineFilespec.ткт = старт[0 .. p - старт];
        t.tokLineFilespec.конец = p + 1;
        tokenEnd = p + 1;
        state = State.End;
      }
      else/+ if (state == State.End)+/
      {
        идс = ИДС.UnterminatedSpecialToken;
        goto Lerr;
      }
    }
    assert(конецСтроки_ли(p));

    if (state == State.Integer)
    {
      errorAtColumn = p;
      идс = ИДС.ExpectedIntegerAfterSTLine;
      goto Lerr;
    }

    // Evaluate #line only when not in сема ткст.
    if (!inTokenString && t.tokLineNum)
    {
      this.lineNum_hline = this.номСтр - t.tokLineNum.бцел_ + 1;
      if (t.tokLineFilespec)
        новыйПутьФ(t.tokLineFilespec.ткт);
    }
    p = tokenEnd;
    t.конец = tokenEnd;

    return;
  Lerr:
    p = tokenEnd;
    t.конец = tokenEnd;
    ошибка(errorAtColumn, идс);
  }

  /// Inserts an empty dummy сема (TOK.Пусто) before t.
  ///
  /// Useful in the parsing phase for representing a узел in the AST
  /// that doesn't consume an actual сема из the source текст.
  Сема* insertEmptyTokenBefore(Сема* t)
  {
    assert(t !is null && t.предш !is null);
    assert(текст.ptr <= t.старт && t.старт < конец, Сема.вТкст(t.вид));
    assert(текст.ptr <= t.конец && t.конец <= конец, Сема.вТкст(t.вид));

    auto предш_t = t.предш;
    auto т_нов = new Сема;
    т_нов.вид = TOK.Пусто;
    т_нов.старт = т_нов.конец = предш_t.конец;
    // Link in new сема.
    предш_t.следщ = т_нов;
    т_нов.предш = предш_t;
    т_нов.следщ = t;
    t.предш = т_нов;
    return т_нов;
  }

  /// Returns the ошибка line число.
  бцел номерСтрокиОшиб(бцел номСтр)
  {
    return номСтр - this.lineNum_hline;
  }

  /// Forwards ошибка parameters.
  проц  ошибка(сим* columnPos, сим[] сооб, ...)
  {
    error_(this.номСтр, this.началоСтроки, columnPos, сооб, _arguments, _argptr);
  }

  /// определено
  проц  ошибка(сим* columnPos, ИДС идс, ...)
  {
    error_(this.номСтр, this.началоСтроки, columnPos, ДайСооб(идс), _arguments, _argptr);
  }

  /// определено
  проц  ошибка(бцел номСтр, сим* началоСтроки, сим* columnPos, ИДС идс, ...)
  {
    error_(номСтр, началоСтроки, columnPos, ДайСооб(идс), _arguments, _argptr);
  }

  /// Creates an ошибка report and appends it в a список.
  /// Параметры:
  ///   номСтр = the line число.
  ///   началоСтроки = points в the first character of the current line.
  ///   columnPos = points в the character where the ошибка is located.
  ///   сооб = the сообщение.
  проц  error_(бцел номСтр, сим* началоСтроки, сим* columnPos, сим[] сооб,
              TypeInfo[] _arguments, va_list _argptr)
  {
    номСтр = this.номерСтрокиОшиб(номСтр);
    auto errorPath = this.путиКФайлам.setPath;
    auto положение = new Положение(errorPath, номСтр, началоСтроки, columnPos);
    сооб = Формат(_arguments, _argptr, сооб);
    auto ошибка = new ОшибкаЛексера(положение, сооб);
    ошибки ~= ошибка;
    if (диаг !is null)
      диаг ~= ошибка;
  }

  /// Scans the whole source текст until КФ is encountered.
  проц  сканируйВсе()
  {
    while (следщСема() != TOK.КФ)
    {}
  }

  /// Returns the first сема of the source текст.
  /// Этот can be the КФ сема.
  /// Structure: ГОЛОВА -> Новстр -> First Сема
  Сема* перваяСема()
  {
    return this.глава.следщ.следщ;
  }

  /// Returns да if ткт is a valid D identifier.
  static бул строкаИдентификатора_ли(сим[] ткт)
  {
    if (ткт.length == 0 || цифра_ли(ткт[0]))
      return нет;
    т_мера idx;
    do
    {
      auto c = drc.Unicode.раскодируй(ткт, idx);
      if (c == СИМ_ОШИБКИ || !(идент_ли(c) || !аски_ли(c) && униАльфа_ли(c)))
        return нет;
    } while (idx < ткт.length)
    return да;
  }

  /// Returns да if ткт is a keyword or
  /// a special сема (__FILE__, __LINE__ etc.)
  static бул резервныйИдентификатор_ли(сим[] ткт)
  {
    if (ткт.length == 0)
      return нет;
    auto ид = ТаблицаИд.вСтатической(ткт);
    if (ид is null || ид.вид == TOK.Идентификатор)
      return нет; // ткт is not in the таблица or a normal identifier.
    return да;
  }

  /// Возвращает да, если это a valid identifier and if it's not reserved.
  static бул действитНерезИдентификатор_ли(сим[] ткт)
  {
    return строкаИдентификатора_ли(ткт) && !резервныйИдентификатор_ли(ткт);
  }

  /// Returns да if the current character в be decoded is
  /// a Unicode alpha character.
  ///
  /// The current pointer 'p' is установи в the last trailbyte if да is returned.
  бул юАльфа_ли()
  {
    assert(!аски_ли(*p), "check for ASCII сим before calling раскодируйЮ8().");
    сим* p = this.p;
    дим d = *p;
    ++p; // Move в second байт.
    // Ошибка if second байт is not a trail байт.
    if (!ведомыйБайт_ли(*p))
      return нет;
    // Check for overlong sequences.
    switch (d)
    {
    case 0xE0, 0xF0, 0xF8, 0xFC:
      if ((*p & d) == 0x80)
        return нет;
    default:
      if ((d & 0xFE) == 0xC0) // 1100000x
        return нет;
    }
    const сим[] проверьСледующийБайт = "if (!ведомыйБайт_ли(*++p))"
                                 "  return нет;";
    const сим[] добавьШестьБит = "d = (d << 6) | *p & 0b0011_1111;";
    // Decode
    if ((d & 0b1110_0000) == 0b1100_0000)
    {
      d &= 0b0001_1111;
      mixin(добавьШестьБит);
    }
    else if ((d & 0b1111_0000) == 0b1110_0000)
    {
      d &= 0b0000_1111;
      mixin(добавьШестьБит ~
            проверьСледующийБайт ~ добавьШестьБит);
    }
    else if ((d & 0b1111_1000) == 0b1111_0000)
    {
      d &= 0b0000_0111;
      mixin(добавьШестьБит ~
            проверьСледующийБайт ~ добавьШестьБит ~
            проверьСледующийБайт ~ добавьШестьБит);
    }
    else
      return нет;

    assert(ведомыйБайт_ли(*p));
    if (!верноСимвол_ли(d) || !униАльфа_ли(d))
      return нет;
    // Only advance pointer if this is a Unicode alpha character.
    this.p = p;
    return да;
  }

  /// Decodes the следщ UTF-8 sequence.
  дим раскодируйЮ8()
  {
    assert(!аски_ли(*p), "check for ASCII char before calling раскодируйЮ8().");
    сим* p = this.p;
    дим d = *p;

    ++p; // Move в second байт.
    // Ошибка if second байт is not a trail байт.
    if (!ведомыйБайт_ли(*p))
      goto Lerr2;

    // Check for overlong sequences.
    switch (d)
    {
    case 0xE0, // 11100000 100xxxxx
         0xF0, // 11110000 1000xxxx
         0xF8, // 11111000 10000xxx
         0xFC: // 11111100 100000xx
      if ((*p & d) == 0x80)
        goto Lerr;
    default:
      if ((d & 0xFE) == 0xC0) // 1100000x
        goto Lerr;
    }

    const сим[] проверьСледующийБайт = "if (!ведомыйБайт_ли(*++p))"
                                 "  goto Lerr2;";
    const сим[] добавьШестьБит = "d = (d << 6) | *p & 0b0011_1111;";

    // Decode
    if ((d & 0b1110_0000) == 0b1100_0000)
    { // 110xxxxx 10xxxxxx
      d &= 0b0001_1111;
      mixin(добавьШестьБит);
    }
    else if ((d & 0b1111_0000) == 0b1110_0000)
    { // 1110xxxx 10xxxxxx 10xxxxxx
      d &= 0b0000_1111;
      mixin(добавьШестьБит ~
            проверьСледующийБайт ~ добавьШестьБит);
    }
    else if ((d & 0b1111_1000) == 0b1111_0000)
    { // 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
      d &= 0b0000_0111;
      mixin(добавьШестьБит ~
            проверьСледующийБайт ~ добавьШестьБит ~
            проверьСледующийБайт ~ добавьШестьБит);
    }
    else
      // 5 and 6 байт UTF-8 sequences are not allowed yet.
      // 111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
      // 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
      goto Lerr;

    assert(ведомыйБайт_ли(*p));

    if (!верноСимвол_ли(d))
    {
    Lerr:
      // Three cases:
      // *) the UTF-8 sequence was successfully decoded but the resulting
      //    character is invalid.
      //    p points в last trail байт in the sequence.
      // *) the UTF-8 sequence is overlong.
      //    p points в second байт in the sequence.
      // *) the UTF-8 sequence has more than 4 bytes or starts with
      //    a trail байт.
      //    p points в second байт in the sequence.
      assert(ведомыйБайт_ли(*p));
      // Move в следщ ASCII character or lead байт of a UTF-8 sequence.
      while (p < (конец-1) && ведомыйБайт_ли(*p))
        ++p;
      --p;
      assert(!ведомыйБайт_ли(p[1]));
    Lerr2:
      d = СИМ_ЗАМЕНЫ;
      ошибка(this.p, ИДС.НедействительнаяПоследовательностьУТФ8, formatBytes(this.p, p));
    }

    this.p = p;
    return d;
  }

  /// Encodes the character d and appends it в ткт.
  static проц  encodeUTF8(ref сим[] ткт, дим d)
  {
    assert(!аски_ли(d), "check for ASCII сим before calling encodeUTF8().");
    assert(верноСимвол_ли(d), "check if character is valid before calling encodeUTF8().");

    сим[6] b = void;
    if (d < 0x800)
    {
      b[0] = 0xC0 | (d >> 6);
      b[1] = 0x80 | (d & 0x3F);
      ткт ~= b[0..2];
    }
    else if (d < 0x10000)
    {
      b[0] = 0xE0 | (d >> 12);
      b[1] = 0x80 | ((d >> 6) & 0x3F);
      b[2] = 0x80 | (d & 0x3F);
      ткт ~= b[0..3];
    }
    else if (d < 0x200000)
    {
      b[0] = 0xF0 | (d >> 18);
      b[1] = 0x80 | ((d >> 12) & 0x3F);
      b[2] = 0x80 | ((d >> 6) & 0x3F);
      b[3] = 0x80 | (d & 0x3F);
      ткт ~= b[0..4];
    }
    /+ // There are no 5 and 6 байт UTF-8 sequences yet.
    else if (d < 0x4000000)
    {
      b[0] = 0xF8 | (d >> 24);
      b[1] = 0x80 | ((d >> 18) & 0x3F);
      b[2] = 0x80 | ((d >> 12) & 0x3F);
      b[3] = 0x80 | ((d >> 6) & 0x3F);
      b[4] = 0x80 | (d & 0x3F);
      ткт ~= b[0..5];
    }
    else if (d < 0x80000000)
    {
      b[0] = 0xFC | (d >> 30);
      b[1] = 0x80 | ((d >> 24) & 0x3F);
      b[2] = 0x80 | ((d >> 18) & 0x3F);
      b[3] = 0x80 | ((d >> 12) & 0x3F);
      b[4] = 0x80 | ((d >> 6) & 0x3F);
      b[5] = 0x80 | (d & 0x3F);
      ткт ~= b[0..6];
    }
    +/
    else
     assert(0);
  }

  /// Formats the bytes between старт and конец.
  /// Возвращает: в.g.: abc -> \x61\x62\x63
  static сим[] formatBytes(сим* старт, сим* конец)
  {
    auto тктLen = конец-старт;
    const formatLen = `\xXX`.length;
    сим[] результат = new сим[тктLen*formatLen]; // Reserve space.
    результат.length = 0;
    foreach (c; cast(ббайт[])старт[0..тктLen])
      результат ~= Формат("\\x{:X}", c);
    return результат;
  }

  /// Searches for an invalid UTF-8 sequence in ткт.
  /// Возвращает: a formatted ткст of the invalid sequence (в.g. \xC0\x80).
  static ткст найдиНедействительнуюПоследовательностьУТФ8(ткст ткт)
  {
    сим* p = ткт.ptr, конец = p + ткт.length;
    while (p < конец)
    {
      if (раскодируй(p, конец) == СИМ_ОШИБКИ)
      {
        auto начало = p;
        // Skip trail-bytes.
        while (++p < конец && ведомыйБайт_ли(*p))
        {}
        return Лексер.formatBytes(начало, p);
      }
    }
    assert(p == конец);
    return "";
  }
}

/// Tests the лексер with a список of семы.
unittest
{
  выдай("Тестируем Лексер.\n");
  struct Пара
  {
    сим[] текстТокена;
    TOK вид;
  }
  static Пара[] пары = [
    {"#!äöüß",  TOK.Шебанг},       {"\n",      TOK.Новстр},
    {"//çay",   TOK.Комментарий},       {"\n",      TOK.Новстр},
                                    {"&",       TOK.ИБинарное},
    {"/*çağ*/", TOK.Комментарий},       {"&&",      TOK.ИЛогическое},
    {"/+çak+/", TOK.Комментарий},       {"&=",      TOK.ИПрисвой},
    {">",       TOK.Больше},       {"+",       TOK.Плюс},
    {">=",      TOK.БольшеРавно},  {"++",      TOK.ПлюсПлюс},
    {">>",      TOK.ПСдвиг},        {"+=",      TOK.ПлюсПрисвой},
    {">>=",     TOK.ПСдвигПрисвой},  {"-",       TOK.Минус},
    {">>>",     TOK.URShift},       {"--",      TOK.МинусМинус},
    {">>>=",    TOK.URShiftAssign}, {"-=",      TOK.МинусПрисвой},
    {"<",       TOK.Меньше},          {"=",       TOK.Присвоить},
    {"<=",      TOK.МеньшеРавно},     {"==",      TOK.Равно},
    {"<>",      TOK.LorG},          {"~",       TOK.Тильда},
    {"<>=",     TOK.LorEorG},       {"~=",      TOK.CatAssign},
    {"<<",      TOK.ЛСдвиг},        {"*",       TOK.Умножь},
    {"<<=",     TOK.ЛСдвигПрисвой},  {"*=",      TOK.УмножьПрисвой},
    {"!",       TOK.Не},           {"/",       TOK.Деление},
    {"!=",      TOK.НеРавно},      {"/=",      TOK.ДелениеПрисвой},
    {"!<",      TOK.UorGorE},       {"^",       TOK.ИИли},
    {"!>",      TOK.UorLorE},       {"^=",      TOK.ИИлиПрисвой},
    {"!<=",     TOK.UorG},          {"%",       TOK.Модуль},
    {"!>=",     TOK.UorL},          {"%=",      TOK.МодульПрисвой},
    {"!<>",     TOK.UorE},          {"(",       TOK.ЛСкобка},
    {"!<>=",    TOK.Unordered},     {")",       TOK.ПСкобка},
    {".",       TOK.Точка},           {"[",       TOK.ЛКвСкобка},
    {"..",      TOK.Срез},         {"]",       TOK.ПКвСкобка},
    {"...",     TOK.Эллипсис},      {"{",       TOK.ЛФСкобка},
    {"|",       TOK.ИлиБинарное},      {"}",       TOK.ПФСкобка},
    {"||",      TOK.ИлиЛогическое},     {":",       TOK.Двоеточие},
    {"|=",      TOK.ИлиПрисвой},      {";",       TOK.ТочкаЗапятая},
    {"?",       TOK.Вопрос},      {",",       TOK.Запятая},
    {"$",       TOK.Доллар},        {"cam",     TOK.Идентификатор},
    {"çay",     TOK.Идентификатор},    {".0",      TOK.Плав64},
    {"0",       TOK.Цел32},         {"\n",      TOK.Новстр},
    {"\r",      TOK.Новстр},       {"\r\n",    TOK.Новстр},
    {"\u2028",  TOK.Новстр},       {"\u2029",  TOK.Новстр}
  ];

  сим[] ист;

  // Join all сема тексты into a single ткст.
  foreach (i, пара; пары)
    if (пара.вид == TOK.Комментарий && пара.текстТокена[1] == '/' || // Line comment.
        пара.вид == TOK.Шебанг)
    {
      assert(пары[i+1].вид == TOK.Новстр); // Must be followed by a новстр.
      ист ~= пара.текстТокена;
    }
    else
      ист ~= пара.текстТокена ~ " ";

  // Lex the constructed source текст.
  auto lx = new Лексер(new ИсходныйТекст("", ист));
  lx.сканируйВсе();

  auto сема = lx.перваяСема();

  for (бцел i; i < пары.length && сема.вид != TOK.КФ;
       ++i, (сема = сема.следщ))
    if (сема.исхТекст != пары[i].текстТокена)
      assert(0, Формат("Найдено '{0}' , но ожидалось '{1}'",
                       сема.исхТекст, пары[i].текстТокена));
}

/// Tests the Лексер's возьми() method.
unittest
{
  выдай("Тестируем метод Лексер.возьми()\n");
  auto исходныйТекст = new ИсходныйТекст("", "unittest { }");
  auto lx = new Лексер(исходныйТекст, null);

  auto следщ = lx.глава;
  lx.возьми(следщ);
  assert(следщ.вид == TOK.Новстр);
  lx.возьми(следщ);
  assert(следщ.вид == TOK.Юниттест);
  lx.возьми(следщ);
  assert(следщ.вид == TOK.ЛФСкобка);
  lx.возьми(следщ);
  assert(следщ.вид == TOK.ПФСкобка);
  lx.возьми(следщ);
  assert(следщ.вид == TOK.КФ);

  lx = new Лексер(new ИсходныйТекст("", ""));
  следщ = lx.глава;
  lx.возьми(следщ);
  assert(следщ.вид == TOK.Новстр);
  lx.возьми(следщ);
  assert(следщ.вид == TOK.КФ);
}

unittest
{
  // Numbers unittest
  // 0L 0ULi 0_L 0_UL 0x0U 0x0p2 0_Fi 0_e2 0_F 0_i
  // 0u 0U 0uL 0UL 0L 0LU 0Lu
  // 0Li 0f 0F 0fi 0Fi 0i
  // 0b_1_LU 0b1000u
  // 0x232Lu
}
