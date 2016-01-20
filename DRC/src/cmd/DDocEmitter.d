/// Author: Aziz Köksal
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

import tango.text.Ascii : toUpper, icompare;

/// Обходит синтактическое дерево и записывает макросы DDoc в текстовый буфер.
abstract class ЭмиттерДДок : ДефолтныйВизитёр
{
  сим[] текст; /// Буфер, в который происходит запись.
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
  сим[] выдать()
  {
    if (isDDocFile(модуль))
    { // Модуль действительно является текстовым файлом DDoc.
      auto c = УтилитыДДок.дайКомментарийДДок(дайТекстДДок(модуль));
      foreach (s; c.резделы)
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

  /// Returns да if the source текст starts with "Ddoc\n" (ignores letter case.)
  static бул isDDocFile(Модуль мод)
  {
    auto данные = мод.исходныйТекст.данные;
    // 5 = "ddoc\n".length; +1 = trailing '\0' in данные.
    if (данные.length >= 5 + 1 && // Check for minimum length.
        icompare(данные[0..4], "ddoc") == 0 && // Check first four characters.
        новСтр_ли(данные.ptr + 4)) // Check for a новстр.
      return да;
    return нет;
  }

  /// Returns the DDoc текст of this module.
  static сим[] дайТекстДДок(Модуль мод)
  {
    auto данные = мод.исходныйТекст.данные;
    сим* p = данные.ptr + "ddoc".length;
    if (сканируйНовСтр(p)) // Skip the новстр.
      // Exclude preceding "Ddoc\n" and trailing '\0'.
      return данные[p-данные.ptr .. $-1];
    return null;
  }

  сим[] textSpan(Сема* левый, Сема* правый)
  {
    //assert(левый && правый && (левый.конец <= правый.старт || левый is правый));
    //сим[] результат;
    //TODO: filter out whitespace семы.
    return Сема.textSpan(левый, правый);
  }

  /// The template parameters of the current declaration.
  ПараметрыШаблона шпарамы;

  /// Reflects the fully qualified имя of the current символ's родитель.
  /// A push occurs when entering a Масштаб, and a pop when exiting it.
  ткст[] fqnStack;
  /// Counts символы with the same ПКИ.
  /// Этот is useful for anchor имена that требуется unique тксты.
  бцел[ткст] fqnCount;

  /// Pushes an identifier onto the stack.
  проц  pushFQN(ткст fqn)
  {
    if (fqn.length)
      fqnStack ~= fqn;
  }
  /// Pops an identifier из the stack.
  проц  popFQN()
  {
    if (fqnStack.length)
      fqnStack = fqnStack[0..$-1];
  }

  /// Returns a unique, identifying ткст for the current символ.
  ткст getSymbolFQN(ткст имя)
  {
    сим[] fqn;
    foreach (name_part; fqnStack)
      fqn ~= name_part ~ ".";
    fqn ~= имя;

    бцел счёт;
    auto pfqn = fqn in fqnCount;
    if (pfqn)
      счёт = (*pfqn += 1); // Update counter.
    else
      fqnCount[fqn] = 1; // Start counting with 1.

    if (счёт > 1) // Ignore unique suffix for the значение 1.
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
    this.emptyCmnt = new КомментарийДДок(null, null, null);
  }

  /// Keeps track of предшious comments in each Масштаб.
 scope class DDocScope
  {
    КомментарийДДок saved_предшCmnt;
    бул saved_cmntIsDitto;
    бцел saved_предшDeclOffset;
    /// When constructed, переменные are saved.
    this(ткст имя)
    { // Save the предшious comment of the родитель Масштаб.
      saved_предшCmnt = this.outer.предшCmnt;
      saved_cmntIsDitto = this.outer.cmntIsDitto;
      saved_предшDeclOffset = this.outer.предшDeclOffset;
      pushFQN(имя);
      // Entering a new Масштаб. Clear переменные.
      this.outer.предшCmnt = null;
      this.outer.cmntIsDitto = нет;
      this.outer.предшDeclOffset = 0;
    }
    /// When destructed, переменные are restored.
    ~this()
    { // Restore the предшious comment of the родитель Масштаб.
      this.outer.предшCmnt = saved_предшCmnt;
      this.outer.cmntIsDitto = saved_cmntIsDitto;
      this.outer.предшDeclOffset = saved_предшDeclOffset;
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
      if (this.cmnt.дитто_ли) // A определено comment.
        (this.cmnt = this.предшCmnt), (this.cmntIsDitto = да);
      else // A normal comment.
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
    auto c = this.cmnt;
    assert(c !is null);
    пиши("$(DDOC_SECTIONS ");
      foreach (s; c.резделы)
      {
        if (s is c.сводка)
          пиши("\n$(DDOC_SUMMARY ");
        else if (s is c.описание)
          пиши("\n$(DDOC_DESCRIPTION ");
        else if (auto имя = toUpper(s.имя.dup) in specialSections)
          пиши("\n$(DDOC_", *имя, " ");
        else if (s.Является("парамы"))
        { // Process parameters раздел.
          auto ps = new РазделПараметров(s.имя, s.текст);
          пиши("\n$(DDOC_PARAMS ");
          foreach (i, paramName; ps.paramNames)
            пиши("\n$(DDOC_PARAM_ROW ",
                    "$(DDOC_PARAM_ID $(DDOC_PARAM ", paramName, "))",
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
  сим[] replace_(сим[] ткт)
  {
    foreach (ref c; ткт.dup)
      if (c == '_') c = ' ';
    return ткт;
  }

  /// Scans the comment текст and:
  /// $(UL
  /// $(LI пропустиs and leaves macro invocations unchanged)
  /// $(LI пропустиs ГЯР tags)
  /// $(LI escapes '(', ')', '<', '>' and '&')
  /// $(LI inserts $&#40;DDOC_BLANKLINE&#41; in place of \n\n)
  /// $(LI highlights код in код резделы)
  /// )
  сим[] scanCommentText(сим[] текст)
  {
    сим* p = текст.ptr;
    сим* конец = p + текст.length;
    сим[] результат = new сим[текст.length]; // Reserve space.
    результат.length = 0;

    while (p < конец)
    {
      switch (*p)
      {
      case '$':
        if (auto конецМакроса = ПарсерМакросов.сканируйМакрос(p, конец))
        {
          результат ~= сделайТекст(p, конецМакроса); // Copy macro invocation as is.
          p = конецМакроса;
          continue;
        }
        goto default;
      case '<':
        auto начало = p;
        p++;
        if (p+2 < конец && *p == '!' && p[1] == '-' && p[2] == '-') // <!--
        {
          p += 2; // Point в 2nd '-'.
          // Scan в закрывающий "-->".
          while (++p < конец)
            if (*p == '-' && p+2 < конец && p[1] == '-' && p[2] == '>')
            {
              p += 3; // Point one past '>'.
              break;
            }
          результат ~= сделайТекст(начало, p);
        } // <tag ...> or </tag>
        else if (p < конец && (буква_ли(*p) || *p == '/'))
        {
          while (++p < конец && *p != '>') // Skip в закрывающий '>'.
          {}
          if (p == конец)
          { // No закрывающий '>' found.
            p = начало + 1;
            результат ~= "&lt;";
            continue;
          }
          p++; // Skip '>'.
          результат ~= сделайТекст(начало, p);
        }
        else
          результат ~= "&lt;";
        continue;
      case '(': результат ~= "&#40;"; break;
      case ')': результат ~= "&#41;"; break;
      // case '\'': результат ~= "&apos;"; break; // &#39;
      // case '"': результат ~= "&quot;"; break;
      case '>': результат ~= "&gt;"; break;
      case '&':
        if (p+1 < конец && (буква_ли(p[1]) || p[1] == '#'))
          goto default;
        результат ~= "&amp;";
        break;
      case '\n':
        if (!(p+1 < конец && p[1] == '\n'))
          goto default;
        ++p;
        результат ~= "$(DDOC_BLANKLINE)";
        break;
      case '-':
        if (p+2 < конец && p[1] == '-' && p[2] == '-')
        { // Found "---".
          while (p < конец && *p == '-') // Skip leading dashes.
            p++;
          auto codeBegin = p;
          while (p < конец && пбел_ли(*p))
            p++;
          if (p < конец && *p == '\n') // Skip first новстр.
            codeBegin = ++p;
          // Find закрывающий dashes.
          while (p < конец && !(*p == '-' && p+2 < конец &&
                            p[1] == '-' && p[2] == '-'))
            p++;
          // Remove last новстр if present.
          auto codeEnd = p;
          while (пбел_ли(*--codeEnd))
          {}
          if (*codeEnd != '\n') // Leaving the pointer on '\n' will exclude it.
            codeEnd++; // Include the non-новстр character.
          if (codeBegin < codeEnd)
          { // Highlight the extracted source код.
            auto codeText = сделайТекст(codeBegin, codeEnd);
            codeText = УтилитыДДок.unindentText(codeText);
            результат ~= псвСем.highlight(codeText, модуль.дайПКН());
          }
          while (p < конец && *p == '-') // Skip remaining dashes.
            p++;
          continue;
        }
        //goto default;
      default:
        результат ~= *p;
      }
      p++;
    }
    assert(p is конец);
    return результат;
  }

  /// Escapes '<', '>' and '&' with named ГЯР entities.
  сим[] escape(сим[] текст)
  {
    сим[] результат = new сим[текст.length]; // Reserve space.
    результат.length = 0;
    foreach(c; текст)
      switch(c)
      {
        case '<': результат ~= "&lt;";  break;
        case '>': результат ~= "&gt;";  break;
        case '&': результат ~= "&amp;"; break;
        default:  результат ~= c;
      }
    if (результат.length != текст.length)
      return результат;
    // Nothing escaped. Итог original текст.
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
  проц  writeParams(Параметры парамы)
  {
    пиши("$(DIL_PARAMS ");
    foreach (парам; парамы.элементы)
    {
      if (парам.СиВариадический_ли)
        пиши("...");
      else
      {
        assert(парам.тип);
        // Write storage classes.
        auto typeBegin = парам.тип.типОснова.начало;
        if (typeBegin !is парам.начало) // Write storage classes.
          пиши(textSpan(парам.начало, typeBegin.предшНепроб), " ");
        пиши(escape(textSpan(typeBegin, парам.тип.конец))); // Write тип.
        if (парам.имя)
          пиши(" $(DDOC_PARAM ", парам.имя.ткт, ")");
        if (парам.ДиВариадический_ли)
          пиши("...");
        if (парам.дефЗначение)
          пиши(" = ", escape(textSpan(парам.дефЗначение.начало, парам.дефЗначение.конец)));
      }
      пиши(", ");
    }
    if (парамы.элементы)
      текст = текст[0..$-2]; /// Срез off last ", ".
    пиши(")");
  }

  /// Writes the current template parameters в the текст буфер.
  проц  writeTemplateParams()
  {
    if (!шпарамы)
      return;
    auto текст = textSpan(шпарамы.начало, шпарамы.конец);
    текст = escape(текст)[1..$-1]; // Escape and remove '(', ')'.
    пиши("$(DIL_TEMPLATE_PARAMS ", текст, ")");
    шпарамы = null;
  }

  /// Writes основы в the текст буфер.
  проц  writeInheritanceList(ТипКлассОснова[] основы)
  {
    if (основы.length == 0)
      return;
    auto basesBegin = основы[0].начало.предшНепроб;
    if (basesBegin.вид == TOK.Двоеточие)
      basesBegin = основы[0].начало;
    auto текст = escape(textSpan(basesBegin, основы[$-1].конец));
    пиши(" $(DIL_BASE_CLASSES ", текст, ")");
  }

  /// Offset at which в вставь a declaration with a "определено" comment.
  бцел предшDeclOffset;

  /// Writes a declaration в the текст буфер.
  проц  DECL(проц  delegate() dg, Декларация d, бул writeSemicolon = да)
  {
    проц  writeDECL()
    {
      пиши("\n$(DDOC_DECL ");
      dg();
      writeSemicolon && пиши(";");
      writeAttributes(d);
      пиши(")");
    }

    if (/+включатьНедокументированное &&+/ this.cmnt is this.emptyCmnt)
    { // Handle undocumented символы separately.
      // Этот way they don't interrupt consolidated declarations.
      writeDECL();
      // Write an empty DDOC_DECL_DD.
      // The method DESC() does not выдать anything when cmntIsDitto is да.
      cmntIsDitto && пиши("\n$(DDOC_DECL_DD)");
    }
    else if (cmntIsDitto)
    { // The declaration has a определено comment.
      alias предшDeclOffset offs;
      assert(offs != 0);
      auto savedText = текст;
      текст = "";
      writeDECL();
      // Insert текст at offset.
      auto len = текст.length;
      текст = savedText[0..offs] ~ текст ~ savedText[offs..$];
      offs += len; // Add length of the inserted текст в the offset.
    }
    else
    {
      writeDECL();
      // Set the offset. At this offset другой declarations with a определено
      // comment will be inserted, if present.
      предшDeclOffset = текст.length;
    }
  }

  /// Wraps the DDOC_DECL_DD macro around the текст written by dg().
  /// Writes the comment before dg() is called.
  проц  DESC(проц  delegate() dg = null)
  {
    if (cmntIsDitto)
      return; // Don't пиши a описание when we have a определено declaration.
    пиши("\n$(DDOC_DECL_DD ");
    writeComment();
    dg && dg();
    пиши(")");
  }

  /// Writes a символ в the текст буфер.
  /// E.g: &#36;(DIL_SYMBOL сканируй, Лексер.сканируй, func, 229, 646);
  проц  SYMBOL(ткст имя, ткст вид, Декларация d)
  {
    auto fqn = getSymbolFQN(имя);
    auto место = d.начало.getRealLocation();
    auto loc_end = d.конец.getRealLocation();
    auto ткт = Формат("$(DIL_SYMBOL {}, {}, {}, {}, {})",
                      имя, fqn, вид, место.номСтр, loc_end.номСтр);
    пиши(ткт);
    // пиши("$(DDOC_PSYMBOL ", имя, ")"); // DMD's macro with no инфо.
  }

  /// Wraps the DDOC_kind_MEMBERS macro around the текст
  /// written by посети(члены).
  проц  ЧЛЕНЫ(D)(ткст вид, ткст имя, D члены)
  {
    scope s = new DDocScope(имя);
    пиши("\n$(DDOC_"~вид~"_MEMBERS ");
    if (члены !is null)
      super.посети(члены);
    пиши(")");
  }

  /// Writes a class or interface declaration.
  проц  writeClassOrЦелerface(T)(T d)
  {
    //if (!ddoc(d))
     // return d;
    DECL({
      const вид = is(T == ДекларацияКласса) ? "class" : "interface";
      пиши(вид, " ");
      SYMBOL(d.имя.ткт, вид, d);
      writeTemplateParams();
      writeInheritanceList(d.основы);
    }, d);
    const вид = is(T == ДекларацияКласса) ? "CLASS" : "INTERFACE";
    DESC({ ЧЛЕНЫ(вид, d.имя.ткт, d.деклы); });
  }

  /// Writes a struct or union declaration.
  проц  writeStructOrUnion(T)(T d)
  {
    //if (!ddoc(d))
     // return d;
    DECL({
      const вид = is(T == ДекларацияСтруктуры) ? "struct" : "union";
      пиши(вид, d.имя ? " " : "");
      if (d.имя)
        SYMBOL(d.имя.ткт, вид, d);
      writeTemplateParams();
    }, d);
    const вид = is(T == ДекларацияСтруктуры) ? "STRUCT" : "UNION";
    DESC({ ЧЛЕНЫ(вид, d.имя ? d.имя.ткт : "", d.деклы); });
  }

  /// Writes an alias or typedef declaration.
  проц  writeAliasOrTypedef(T)(T d)
  {
    const вид = is(T == ДекларацияАлиаса) ? "alias" : "typedef";
    if (auto vd = d.декл.Является!(ДекларацияПеременных))
    {
      auto тип = textSpan(vd.узелТипа.типОснова.начало, vd.узелТипа.конец);
      foreach (имя; vd.имена)
        DECL({ пиши(вид, " "); пиши(escape(тип), " ");
          SYMBOL(имя.ткт, вид, d);
        }, d);
    }
    else if (auto дф = d.декл.Является!(ДекларацияФункции))
    {}
    // DECL({ пиши(textSpan(d.начало, d.конец)); }, нет);
    DESC();
  }

  /// Writes the attributes of a declaration in brackets.
  проц  writeAttributes(Декларация d)
  {
    сим[][] attributes;

    if (d.защ != Защита.Нет)
      attributes ~= "$(DIL_PROT " ~ .вТкст(d.защ) ~ ")";

    auto кхр = d.кхр;
    кхр &= ~КлассХранения.Авто; // Ignore auto.
    foreach (stcStr; .вТксты(кхр))
      attributes ~= "$(DIL_STC " ~ stcStr ~ ")";

    ТипКомпоновки ltype;
    if (auto vd = d.Является!(ДекларацияПеременных))
      ltype = vd.типКомпоновки;
    else if (auto дф = d.Является!(ДекларацияФункции))
      ltype = дф.типКомпоновки;

    if (ltype != ТипКомпоновки.Нет)
      attributes ~= "$(DIL_LINKAGE extern(" ~ .вТкст(ltype) ~ "))";

    if (!attributes.length)
      return;

    пиши(" $(DIL_ATTRIBUTES ", attributes[0]);
    foreach (attribute; attributes[1..$])
      пиши(", ", attribute);
    пиши(")");
  }

  alias Декларация D;

override:
  D посети(ДекларацияАлиаса d)
  {
    if (ddoc(d))
      writeAliasOrTypedef(d);
    return d;
  }

  D посети(ДекларацияТипдефа d)
  {
    if (ddoc(d))
      writeAliasOrTypedef(d);
    return d;
  }

  D посети(ДекларацияПеречня d)
  {
    if (!ddoc(d))
      return d;
    DECL({
      пиши("enum", d.имя ? " " : "");
      d.имя && SYMBOL(d.имя.ткт, "enum", d);
    }, d);
    DESC({ ЧЛЕНЫ("ENUM", d.имя ? d.имя.ткт : "", d); });
    return d;
  }

  D посети(ДекларацияЧленаПеречня d)
  {
    if (!ddoc(d))
      return d;
    DECL({ SYMBOL(d.имя.ткт, "enummem", d); }, d, нет);
    DESC();
    return d;
  }

  D посети(ДекларацияШаблона d)
  {
    this.шпарамы = d.шпарамы;
    if (d.начало.вид != TOK.Шаблон)
    { // Этот is a templatized class/interface/struct/union/function.
      super.посети(d.деклы);
      this.шпарамы = null;
      return d;
    }
    if (!ddoc(d))
      return d;
    DECL({
      пиши("template ");
      SYMBOL(d.имя.ткт, "template", d);
      writeTemplateParams();
    }, d);
    DESC({ ЧЛЕНЫ("TEMPLATE", d.имя.ткт, d.деклы); });
    return d;
  }

  D посети(ДекларацияКласса d)
  {
    writeClassOrЦелerface(d);
    return d;
  }

  D посети(ДекларацияИнтерфейса d)
  {
    writeClassOrЦелerface(d);
    return d;
  }

  D посети(ДекларацияСтруктуры d)
  {
    writeStructOrUnion(d);
    return d;
  }

  D посети(ДекларацияСоюза d)
  {
    writeStructOrUnion(d);
    return d;
  }

  D посети(ДекларацияКонструктора d)
  {
    if (!ddoc(d))
      return d;
    DECL({ SYMBOL("this", "ctor", d); writeParams(d.парамы); }, d);
    DESC();
    return d;
  }

  D посети(ДекларацияСтатическогоКонструктора d)
  {
    if (!ddoc(d))
      return d;
    DECL({ пиши("static "); SYMBOL("this", "sctor", d); пиши("()"); }, d);
    DESC();
    return d;
  }

  D посети(ДекларацияДеструктора d)
  {
    if (!ddoc(d))
      return d;
    DECL({ пиши("~"); SYMBOL("this", "dtor", d); пиши("()"); }, d);
    DESC();
    return d;
  }

  D посети(ДекларацияСтатическогоДеструктора d)
  {
    if (!ddoc(d))
      return d;
    DECL({ пиши("static ~"); SYMBOL("this", "sdtor", d); пиши("()"); }, d);
    DESC();
    return d;
  }

  D посети(ДекларацияФункции d)
  {
    if (!ddoc(d))
      return d;
    auto тип = textSpan(d.типВозврата.типОснова.начало, d.типВозврата.конец);
    DECL({
      пиши(escape(тип), " ");
      SYMBOL(d.имя.ткт, "function", d);
      writeTemplateParams();
      writeParams(d.парамы);
    }, d);
    DESC();
    return d;
  }

  D посети(ДекларацияНов d)
  {
    if (!ddoc(d))
      return d;
    DECL({ SYMBOL("new", "new", d); writeParams(d.парамы); }, d);
    DESC();
    return d;
  }

  D посети(ДекларацияУдали d)
  {
    if (!ddoc(d))
      return d;
    DECL({ SYMBOL("delete", "delete", d); writeParams(d.парамы); }, d);
    DESC();
    return d;
  }

  D посети(ДекларацияПеременных d)
  {
    if (!ddoc(d))
      return d;
    сим[] тип = "auto";
    if (d.узелТипа)
      тип = textSpan(d.узелТипа.типОснова.начало, d.узелТипа.конец);
    foreach (имя; d.имена)
      DECL({ пиши(escape(тип), " "); SYMBOL(имя.ткт, "переменная", d); }, d);
    DESC();
    return d;
  }

  D посети(ДекларацияИнварианта d)
  {
    if (!ddoc(d))
      return d;
    DECL({ SYMBOL("invariant", "invariant", d); }, d);
    DESC();
    return d;
  }

  D посети(ДекларацияЮниттеста d)
  {
    if (!ddoc(d))
      return d;
    DECL({ SYMBOL("unittest", "unittest", d); }, d);
    DESC();
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
