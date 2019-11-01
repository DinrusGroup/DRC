/// Author: Aziz Köksal, Vitaly Kulich
/// License: GPL3
/// $(Maturity high)
module cmd.DDocEmitter;

import cmd.Highlight;
import drc.doc.Parser,
       drc.doc.Macro,
       drc.doc.Doc;
import drc.ast.DefaultVisitor,
       drc.ast.Node,
       drc.ast.Declarations,
       drc.ast.Statements,
       drc.ast.Expression,
       drc.ast.Parameters,
       drc.ast.Types;
import drc.lexer.Token,
       drc.lexer.Funcs;
import drc.semantic.Module;
import drc.Diagnostics;
import drc.SourceText;
import drc.Enums;
import common;

import text.Ascii : вЗаг, сравнилюб;

/// Обходит синтактическое дерево и записывает макросы DDoc в текстовый буфер.
abstract class ЭмиттерДДок : ДефолтныйВизитёр
{
  ткст текст; /// Буфер, в который происходит запись.
  бул включатьНедокументированное;
  ТаблицаМакросов мтаблица;
  Модуль модуль;
  ПодсветчикСем псвСем;

  /// Конструирует объект ЭмиттерДДок.
  /// Параметры:
  ///   модуль = модуль, для которого генерируется текст.
  ///   мтаблица = таблица макросов.
  ///   включатьНедокументированное = включать ли недокументированные символы.
  ///   псвСем = используется для подсветки разделов кода.
  this(Модуль модуль, ТаблицаМакросов мтаблица, бул включатьНедокументированное,
       ПодсветчикСем псвСем)
  {
    this.мтаблица = мтаблица;
    this.включатьНедокументированное = включатьНедокументированное;
    this.модуль = модуль;
    this.псвСем = псвСем;
  }

  /// Метод ввода.
  ткст выдать()
  {
    if (файлДДок(модуль))
    { // Модуль действительно является текстовым файлом DDoc.
      auto с = УтилитыДДок.дайКомментарийДДок(дайТекстДДок(модуль));
      foreach (s; с.резделы)
      {
        if (s.Является("макрос"))
        { // E этой секции декларируется макрос.
          auto ms = new РазделМакросов(s.имя, s.текст);
          мтаблица.вставь(ms.именаМакросов, ms.текстыМакросов);
        }
        else
          пиши(s.весьТекст);
      }
      return текст;
    }
    // Обрабатывать как обычный модуль Ди с декларациями.
    if (auto d = модуль.деклМодуля)
    {
      if (ddoc(d))
      {
        if (auto авторское_право = cmnt.взятьАвторскоеПраво())
          мтаблица.вставь("COPYRIGHT", авторское_право.текст);
        writeComment();
      }
    }
    ЧЛЕНЫ("МОДУЛЬ", "", модуль.корень);
    return текст;
  }

  /// Возвращает "да", если the source текст starts with "Ddoc\n" (ignилиes letter case.)
  static бул файлДДок(Модуль мод)
  {
    auto данные = мод.исходныйТекст.данные;
    // 5 = "ddoc\n".length; +1 = trailing '\0' in данные.
    if (данные.length >= 5 + 1 && // Проверим на minimum length.
        сравнилюб(данные[0..4], "ddoc") == 0 && // Check first four characters.
        новСтр(данные.ptr + 4)) // Проверим на a нс.
      return да;
    return нет;
  }

  /// Возвращает DDoc текст of this module.
  static ткст дайТекстДДок(Модуль мод)
  {
    auto данные = мод.исходныйТекст.данные;
    сим* у = данные.ptr + "ddoc".length;
    if (сканируйНовСтр(у)) // Пропустим the нс.
      // Exclude preceding "Ddoc\n" and trailing '\0'.
      return данные[у-данные.ptr .. $-1];
    return пусто;
  }

  ткст участокТекста(Сема* левый, Сема* правый)
  {
    //assert(левый && правый && (левый.конец <= правый.старт || левый is правый));
    //ткст результат;
    //TODO: filter out whitespace семы.
    return Сема.участокТекста(левый, правый);
  }

  /// The template параметры of the current declaration.
  ПараметрыШаблона шпарамы;

  /// Reflects the fully qualified имя of the current символ's родитель.
  /// A push occurs when entering a Масштаб, and a pop when exiting it.
  ткст[] fqnStack;
  /// Counts символы with the same ПКИ.
  /// Этот is useful for anchили имена that требуется unique тксты.
  бцел[ткст] fqnCount;

  /// Pushes an идентификатор onto the stack.
  проц  pushFQN(ткст fqn)
  {
    if (fqn.length)
      fqnStack ~= fqn;
  }
  /// Pops an идентификатор из the stack.
  проц  popFQN()
  {
    if (fqnStack.length)
      fqnStack = fqnStack[0..$-1];
  }

  /// Returns a unique, identifying ткст for the current символ.
  ткст дайПКНСимвола(ткст имя)
  {
    ткст fqn;
    foreach (Имя_part; fqnStack)
      fqn ~= Имя_part ~ ".";
    fqn ~= имя;

    бцел счёт;
    auto pfqn = fqn in fqnCount;
    if (pfqn)
      счёт = (*pfqn += 1); // Update counter.
    else
      fqnCount[fqn] = 1; // Start counting with 1.

    if (счёт > 1) // Ignилиe unique суффикс for the значение 1.
      fqn ~= Формат(":{}", счёт);
    return fqn;
  }

  КомментарийДДок cmnt; /// Current comment.
  КомментарийДДок предшCmnt; /// Previous comment in Масштаб.
  /// An empty comment. Used for undocumented символы.
  static const КомментарийДДок emptyCmnt;

  /// Initializes the empty comment.
  static this()
  {
    this.emptyCmnt = new КомментарийДДок(пусто, пусто, пусто);
  }

  /// Keeps track of предшious comments in each Масштаб.
 scope class МасштабДДок
  {
    КомментарийДДок saved_предшCmnt;
    бул saved_cmntIsDitto;
    бцел saved_предшDeclOffset;
    /// When constructed, переменные are сохранённое.
    this(ткст имя)
    { // Сохранить the предшious comment of the родитель Масштаб.
      saved_предшCmnt = this.outer.предшCmnt;
      saved_cmntIsDitto = this.outer.cmntIsDitto;
      saved_предшDeclOffset = this.outer.предшСмещДекл;
      pushFQN(имя);
      // Entering a new Масштаб. Clear переменные.
      this.outer.предшCmnt = пусто;
      this.outer.cmntIsDitto = нет;
      this.outer.предшСмещДекл = 0;
    }
    /// When destructed, переменные are restилиed.
    ~this()
    { // Восстановить the предшious comment of the родитель Масштаб.
      this.outer.предшCmnt = saved_предшCmnt;
      this.outer.cmntIsDitto = saved_cmntIsDitto;
      this.outer.предшСмещДекл = saved_предшDeclOffset;
      popFQN();
    }
  }

  бул cmntIsDitto; /// Истина if current comment is "определено".

  /// Sets some члены and returns the КомментарийДДок for узел.
  КомментарийДДок ddoc(Узел узел)
  {
    this.cmnt = УтилитыДДок.дайКомментарийДДок(узел);
    if (this.cmnt)
    {
      if (this.cmnt.дитто) // A определено comment.
        (this.cmnt = this.предшCmnt), (this.cmntIsDitto = да);
      else // A nилиmal comment.
        (this.предшCmnt = this.cmnt), (this.cmntIsDitto = нет);
    }
    else if (включатьНедокументированное)
      this.cmnt = this.emptyCmnt; // Присвоить special empty comment.
    return this.cmnt;
  }

  /// List of predefined, special резделы.
  static сим[][сим[]] specialSections;
  static this()
  {
    foreach (имя; ["AUTHORS", "BUGS", "COPYRIGHT", "ДАТА", "DEPRECATED",
                    "EXAMPLES", "HISTORY", "LICENSE", "RETURNS", "SEE_ALSO",
                    "STANDARDS", "THROWS", "ВЕРСИЯ"] ~
                   ["AUTHOR"]) // Addition by drc.
      specialSections[имя] = имя;
  }

  /// Writes the DDoc comment в the текст буфер.
  проц  writeComment()
  {
    auto с = this.cmnt;
    assert(с !is пусто);
    пиши("$(DDOC_SECTIONS ");
      foreach (s; с.резделы)
      {
        if (s is с.сводка)
          пиши("\n$(DDOC_SUMMARY ");
        else if (s is с.описание)
          пиши("\n$(DDOC_DESCRIPTION ");
        else if (auto имя = вЗаг(s.имя.dup) in specialSections)
          пиши("\n$(DDOC_", *имя, " ");
        else if (s.Является("парамы"))
        { // Process параметры раздел.
          auto ps = new РазделПараметров(s.имя, s.текст);
          пиши("\n$(DDOC_PARAMS ");
          foreach (i, paramИмя; ps.paramИмяs)
            пиши("\n$(DDOC_PARAM_ROW ",
                    "$(DDOC_PARAM_ID $(DDOC_PARAM ", paramИмя, "))",
                    "$(DDOC_PARAM_DESC ", ps.paramDescs[i], ")",
                  ")");
          пиши(")");
          continue;
        }
        else if (s.Является("макрос"))
        { // Declare the макрос in this раздел.
          auto ms = new РазделМакросов(s.имя, s.текст);
          мтаблица.вставь(ms.именаМакросов, ms.текстыМакросов);
          continue;
        }
        else
          пиши("\n$(DDOC_SECTION $(DDOC_SECTION_H ", replace_(s.имя), ":)");
        пиши(scanCommentText(s.текст), ")");
      }
    пиши(")");
  }

  /// Replaces occurrences of '_' with ' ' in ткт.
  ткст replace_(ткст ткт)
  {
    foreach (ref с; ткт.dup)
      if (с == '_') с = ' ';
    return ткт;
  }

  /// Scans the comment текст and:
  /// $(UL
  /// $(LI пропустиs and leaves macro invocations unchanged)
  /// $(LI пропустиs ГЯР тэги)
  /// $(LI escapes '(', ')', '<', '>' and '&')
  /// $(LI inserts $&#40;DDOC_BLANKLINE&#41; in place of \n\n)
  /// $(LI highlights код in код резделы)
  /// )
  ткст scanCommentText(ткст текст)
  {
    сим* у = текст.ptr;
    сим* конец = у + текст.length;
    ткст результат = new сим[текст.length]; // Reserve space.
    результат.length = 0;

    while (у < конец)
    {
      switch (*у)
      {
      case '$':
        if (auto конецМакроса = ПарсерМакросов.сканируйМакрос(у, конец))
        {
          результат ~= сделайТекст(у, конецМакроса); // Copy macro invocation as is.
          у = конецМакроса;
          continue;
        }
        goto default;
      case '<':
        auto начало = у;
        у++;
        if (у+2 < конец && *у == '!' && у[1] == '-' && у[2] == '-') // <!--
        {
          у += 2; // Point в 2nd '-'.
          // Scan в закрывающий "-->".
          while (++у < конец)
            if (*у == '-' && у+2 < конец && у[1] == '-' && у[2] == '>')
            {
              у += 3; // Point one past '>'.
              break;
            }
          результат ~= сделайТекст(начало, у);
        } // <тэг ...> или </тэг>
        else if (у < конец && (буква(*у) || *у == '/'))
        {
          while (++у < конец && *у != '>') // Пропустим в закрывающий '>'.
          {}
          if (у == конец)
          { // No закрывающий '>' found.
            у = начало + 1;
            результат ~= "&тк;";
            continue;
          }
          у++; // Пропустим '>'.
          результат ~= сделайТекст(начало, у);
        }
        else
          результат ~= "&тк;";
        continue;
      case '(': результат ~= "&#40;"; break;
      case ')': результат ~= "&#41;"; break;
      // case '\'': результат ~= "&apos;"; break; // &#39;
      // case '"': результат ~= "&quot;"; break;
      case '>': результат ~= "&gt;"; break;
      case '&':
        if (у+1 < конец && (буква(у[1]) || у[1] == '#'))
          goto default;
        результат ~= "&amp;";
        break;
      case '\n':
        if (!(у+1 < конец && у[1] == '\n'))
          goto default;
        ++у;
        результат ~= "$(DDOC_BLANKLINE)";
        break;
      case '-':
        if (у+2 < конец && у[1] == '-' && у[2] == '-')
        { // Found "---".
          while (у < конец && *у == '-') // Пропустим leading dashes.
            у++;
          auto КодBegin = у;
          while (у < конец && пбел(*у))
            у++;
          if (у < конец && *у == '\n') // Пропустим first нс.
            КодBegin = ++у;
          // Find закрывающий dashes.
          while (у < конец && !(*у == '-' && у+2 < конец &&
                            у[1] == '-' && у[2] == '-'))
            у++;
          // Remove last нс if present.
          auto КодКонец = у;
          while (пбел(*--КодКонец))
          {}
          if (*КодКонец != '\n') // Leaving the pointer on '\n' will exclude it.
            КодКонец++; // Include the non-нс символ.
          if (КодBegin < КодКонец)
          { // Highlight the extracted source код.
            auto КодText = сделайТекст(КодBegin, КодКонец);
            КодText = УтилитыДДок.unindentText(КодText);
            результат ~= псвСем.highlight(КодText, модуль.дайПКИ());
          }
          while (у < конец && *у == '-') // Пропустим remaining dashes.
            у++;
          continue;
        }
        //goto default;
      default:
        результат ~= *у;
      }
      у++;
    }
    assert(у is конец);
    return результат;
  }

  /// Escapes '<', '>' and '&' with Имяd ГЯР entities.
  ткст escape(ткст текст)
  {
    ткст результат = new сим[текст.length]; // Reserve space.
    результат.length = 0;
    foreach(с; текст)
      switch(с)
      {
        case '<': результат ~= "&тк;";  break;
        case '>': результат ~= "&gt;";  break;
        case '&': результат ~= "&amp;"; break;
        default:  результат ~= с;
      }
    if (результат.length != текст.length)
      return результат;
    // Nothing escaped. Итог илиiginal текст.
    delete результат;
    return текст;
  }

  /// Writes an массив of тксты в the текст буфер.
  проц  пиши(сим[][] тксты...)
  {
    foreach (s; тксты)
      текст ~= s;
  }

  /// Writes парамы в the текст буфер.
  проц  пишиПарамы(Параметры парамы)
  {
    пиши("$(DRC_PARAMS ");
    foreach (парам; парамы.элементы)
    {
      if (парам.СиВариадический)
        пиши("...");
      else
      {
        assert(парам.тип);
        // Write stилиage classes.
        auto typeBegin = парам.тип.типОснова.начало;
        if (typeBegin !is парам.начало) // Write stилиage classes.
          пиши(участокТекста(парам.начало, typeBegin.предшНепроб), " ");
        пиши(escape(участокТекста(typeBegin, парам.тип.конец))); // Write тип.
        if (парам.имя)
          пиши(" $(DDOC_PARAM ", парам.имя.ткт, ")");
        if (парам.ДиВариадический)
          пиши("...");
        if (парам.дефЗначение)
          пиши(" = ", escape(участокТекста(парам.дефЗначение.начало, парам.дефЗначение.конец)));
      }
      пиши(", ");
    }
    if (парамы.элементы)
      текст = текст[0..$-2]; /// Срез off last ", ".
    пиши(")");
  }

  /// Writes the current template параметры в the текст буфер.
  проц  пишиПарамыШаблона()
  {
    if (!шпарамы)
      return;
    auto текст = участокТекста(шпарамы.начало, шпарамы.конец);
    текст = escape(текст)[1..$-1]; // Escape and remove '(', ')'.
    пиши("$(DRC_TEMPLATE_PARAMS ", текст, ")");
    шпарамы = пусто;
  }

  /// Writes основы в the текст буфер.
  проц  пишиСписокНаследования(ТипКлассОснова[] основы)
  {
    if (основы.length == 0)
      return;
    auto basesBegin = основы[0].начало.предшНепроб;
    if (basesBegin.вид == TOK.Двоеточие)
      basesBegin = основы[0].начало;
    auto текст = escape(участокТекста(basesBegin, основы[$-1].конец));
    пиши(" $(DRC_BASE_CLASSES ", текст, ")");
  }

  /// Offset at which в вставь a declaration with a "определено" comment.
  бцел предшСмещДекл;

  /// Writes a declaration в the текст буфер.
  проц  ДЕКЛ(проц  delegate() dg, Декларация d, бул writeSemicolon = да)
  {
    проц  пишиДЕКЛ()
    {
      пиши("\n$(DDOC_DECL ");
      dg();
      writeSemicolon && пиши(";");
      пишиАтрибуты(d);
      пиши(")");
    }

    if (/+включатьНедокументированное &&+/ this.cmnt is this.emptyCmnt)
    { // Handle undocumented символы separately.
      // Этот way they don'т interrupt consolidated declarations.
      пишиДЕКЛ();
      // Write an empty DDOC_DECL_DD.
      // The method ДЕСК() does not выдать anything when cmntIsDitto is да.
      cmntIsDitto && пиши("\n$(DDOC_DECL_DD)");
    }
    else if (cmntIsDitto)
    { // The declaration has a определено comment.
      alias предшСмещДекл offs;
      assert(offs != 0);
      auto savedText = текст;
      текст = "";
      пишиДЕКЛ();
      // Вставить текст at offset.
      auto len = текст.length;
      текст = savedText[0..offs] ~ текст ~ savedText[offs..$];
      offs += len; // Add length of the inserted текст в the offset.
    }
    else
    {
      пишиДЕКЛ();
      // Установить the offset. At this offset другой declarations with a определено
      // comment will be inserted, if present.
      предшСмещДекл = текст.length;
    }
  }

  /// Wraps the DDOC_DECL_DD macro around the текст Автор dg().
  /// Writes the comment befилиe dg() is called.
  проц  ДЕСК(проц  delegate() dg = пусто)
  {
    if (cmntIsDitto)
      return; // Don'т пиши a описание when we have a определено declaration.
    пиши("\n$(DDOC_DECL_DD ");
    writeComment();
    dg && dg();
    пиши(")");
  }

  /// Writes a символ в the текст буфер.
  /// E.g: &#36;(DRC_SYMBOL сканируй, Лексер.сканируй, функц, 229, 646);
  проц  СИМВОЛ(ткст имя, ткст вид, Декларация d)
  {
    auto fqn = дайПКНСимвола(имя);
    auto место = d.начало.дайРеальноеПоложение();
    auto loc_end = d.конец.дайРеальноеПоложение();
    auto ткт = Формат("$(DRC_SYMBOL {}, {}, {}, {}, {})",
                      имя, fqn, вид, место.номерСтроки, loc_end.номерСтроки);
    пиши(ткт);
    // пиши("$(DDOC_PСИМВОЛ ", имя, ")"); // DMD's macro with no инфо.
  }

  /// Wraps the DDOC_kind_ЧленS macro around the текст
  /// Автор посети(члены).
  проц  ЧЛЕНЫ(D)(ткст вид, ткст имя, D члены)
  {
    scope s = new МасштабДДок(имя);
    пиши("\n$(DDOC_"~вид~"_ЧленS ");
    if (члены !is пусто)
      super.посети(члены);
    пиши(")");
  }

  /// Writes a class или interface declaration.
  проц  пишиКлассИлиИнтерфейс(T)(T d)
  {
    //if (!ddoc(d))
     // return d;
    ДЕКЛ({
      const вид = is(T == ДекларацияКласса) ? "class" : "interface";
      пиши(вид, " ");
      СИМВОЛ(d.имя.ткт, вид, d);
      пишиПарамыШаблона();
      пишиСписокНаследования(d.основы);
    }, d);
    const вид = is(T == ДекларацияКласса) ? "CLASS" : "INTERFACE";
    ДЕСК({ ЧЛЕНЫ(вид, d.имя.ткт, d.деклы); });
  }

  /// Writes a struct или union declaration.
  проц  пишиСтруктИлиСоюз(T)(T d)
  {
    //if (!ddoc(d))
     // return d;
    ДЕКЛ({
      const вид = is(T == ДекларацияСтруктуры) ? "struct" : "union";
      пиши(вид, d.имя ? " " : "");
      if (d.имя)
        СИМВОЛ(d.имя.ткт, вид, d);
      пишиПарамыШаблона();
    }, d);
    const вид = is(T == ДекларацияСтруктуры) ? "STRUCT" : "UNION";
    ДЕСК({ ЧЛЕНЫ(вид, d.имя ? d.имя.ткт : "", d.деклы); });
  }

  /// Writes an alias или typedef declaration.
  проц  пишиАлиасИлиТипдеф(T)(T d)
  {
    const вид = is(T == ДекларацияАлиаса) ? "alias" : "typedef";
    if (auto vd = d.декл.Является!(ДекларацияПеременных))
    {
      auto тип = участокТекста(vd.узелТипа.типОснова.начало, vd.узелТипа.конец);
      foreach (имя; vd.имена)
        ДЕКЛ({ пиши(вид, " "); пиши(escape(тип), " ");
          СИМВОЛ(имя.ткт, вид, d);
        }, d);
    }
    else if (auto дф = d.декл.Является!(ДекларацияФункции))
    {}
    // ДЕКЛ({ пиши(участокТекста(d.начало, d.конец)); }, нет);
    ДЕСК();
  }

  /// Writes the атрибуты of a declaration in brackets.
  проц  пишиАтрибуты(Декларация d)
  {
    сим[][] атрибуты;

    if (d.защ != Защита.Нет)
      атрибуты ~= "$(DRC_PROT " ~ .вТкст(d.защ) ~ ")";

    auto кхр = d.кхр;
    кхр &= ~КлассХранения.Авто; // Ignилиe auto.
    foreach (stcStr; .вТксты(кхр))
      атрибуты ~= "$(DRC_STC " ~ stcStr ~ ")";

    ТипКомпоновки типК;
    if (auto vd = d.Является!(ДекларацияПеременных))
      типК = vd.типКомпоновки;
    else if (auto дф = d.Является!(ДекларацияФункции))
      типК = дф.типКомпоновки;

    if (типК != ТипКомпоновки.Нет)
      атрибуты ~= "$(DRC_LINKAGE extern(" ~ .вТкст(типК) ~ "))";

    if (!атрибуты.length)
      return;

    пиши(" $(DRC_ATTRIBUTES ", атрибуты[0]);
    foreach (атрибут; атрибуты[1..$])
      пиши(", ", атрибут);
    пиши(")");
  }

  alias Декларация D;

override:
  D посети(ДекларацияАлиаса d)
  {
    if (ddoc(d))
      пишиАлиасИлиТипдеф(d);
    return d;
  }

  D посети(ДекларацияТипдефа d)
  {
    if (ddoc(d))
      пишиАлиасИлиТипдеф(d);
    return d;
  }

  D посети(ДекларацияПеречня d)
  {
    if (!ddoc(d))
      return d;
    ДЕКЛ({
      пиши("enum", d.имя ? " " : "");
      d.имя && СИМВОЛ(d.имя.ткт, "enum", d);
    }, d);
    ДЕСК({ ЧЛЕНЫ("ENUM", d.имя ? d.имя.ткт : "", d); });
    return d;
  }

  D посети(ДекларацияЧленаПеречня d)
  {
    if (!ddoc(d))
      return d;
    ДЕКЛ({ СИМВОЛ(d.имя.ткт, "enummem", d); }, d, нет);
    ДЕСК();
    return d;
  }

  D посети(ДекларацияШаблона d)
  {
    this.шпарамы = d.шпарамы;
    if (d.начало.вид != TOK.Шаблон)
    { // Этот есть templatized class/interface/struct/union/function.
      super.посети(d.деклы);
      this.шпарамы = пусто;
      return d;
    }
    if (!ddoc(d))
      return d;
    ДЕКЛ({
      пиши("template ");
      СИМВОЛ(d.имя.ткт, "template", d);
      пишиПарамыШаблона();
    }, d);
    ДЕСК({ ЧЛЕНЫ("TEMPLATE", d.имя.ткт, d.деклы); });
    return d;
  }

  D посети(ДекларацияКласса d)
  {
    пишиКлассИлиИнтерфейс(d);
    return d;
  }

  D посети(ДекларацияИнтерфейса d)
  {
    пишиКлассИлиИнтерфейс(d);
    return d;
  }

  D посети(ДекларацияСтруктуры d)
  {
    пишиСтруктИлиСоюз(d);
    return d;
  }

  D посети(ДекларацияСоюза d)
  {
    пишиСтруктИлиСоюз(d);
    return d;
  }

  D посети(ДекларацияКонструктора d)
  {
    if (!ddoc(d))
      return d;
    ДЕКЛ({ СИМВОЛ("this", "ctили", d); пишиПарамы(d.парамы); }, d);
    ДЕСК();
    return d;
  }

  D посети(ДекларацияСтатическогоКонструктора d)
  {
    if (!ddoc(d))
      return d;
    ДЕКЛ({ пиши("static "); СИМВОЛ("this", "sctили", d); пиши("()"); }, d);
    ДЕСК();
    return d;
  }

  D посети(ДекларацияДеструктора d)
  {
    if (!ddoc(d))
      return d;
    ДЕКЛ({ пиши("~"); СИМВОЛ("this", "dtили", d); пиши("()"); }, d);
    ДЕСК();
    return d;
  }

  D посети(ДекларацияСтатическогоДеструктора d)
  {
    if (!ddoc(d))
      return d;
    ДЕКЛ({ пиши("static ~"); СИМВОЛ("this", "sdtили", d); пиши("()"); }, d);
    ДЕСК();
    return d;
  }

  D посети(ДекларацияФункции d)
  {
    if (!ddoc(d))
      return d;
    auto тип = участокТекста(d.типВозврата.типОснова.начало, d.типВозврата.конец);
    ДЕКЛ({
      пиши(escape(тип), " ");
      СИМВОЛ(d.имя.ткт, "function", d);
      пишиПарамыШаблона();
      пишиПарамы(d.парамы);
    }, d);
    ДЕСК();
    return d;
  }

  D посети(ДекларацияНов d)
  {
    if (!ddoc(d))
      return d;
    ДЕКЛ({ СИМВОЛ("new", "new", d); пишиПарамы(d.парамы); }, d);
    ДЕСК();
    return d;
  }

  D посети(ДекларацияУдали d)
  {
    if (!ddoc(d))
      return d;
    ДЕКЛ({ СИМВОЛ("delete", "delete", d); пишиПарамы(d.парамы); }, d);
    ДЕСК();
    return d;
  }

  D посети(ДекларацияПеременных d)
  {
    if (!ddoc(d))
      return d;
    ткст тип = "auto";
    if (d.узелТипа)
      тип = участокТекста(d.узелТипа.типОснова.начало, d.узелТипа.конец);
    foreach (имя; d.имена)
      ДЕКЛ({ пиши(escape(тип), " "); СИМВОЛ(имя.ткт, "переменная", d); }, d);
    ДЕСК();
    return d;
  }

  D посети(ДекларацияИнварианта d)
  {
    if (!ddoc(d))
      return d;
    ДЕКЛ({ СИМВОЛ("invariant", "invariant", d); }, d);
    ДЕСК();
    return d;
  }

  D посети(ДекларацияЮниттеста d)
  {
    if (!ddoc(d))
      return d;
    ДЕКЛ({ СИМВОЛ("unittest", "unittest", d); }, d);
    ДЕСК();
    return d;
  }

  D посети(ДекларацияОтладки d)
  {
    d.компилированныеДеклы && посетиД(d.компилированныеДеклы);
    return d;
  }

  D посети(ДекларацияВерсии d)
  {
    d.компилированныеДеклы && посетиД(d.компилированныеДеклы);
    return d;
  }

  D посети(ДекларацияСтатическогоЕсли d)
  {
    d.деклыЕсли && посетиД(d.деклыЕсли);
    return d;
  }
}
