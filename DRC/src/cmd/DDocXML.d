/// Authors: Aziz Köksal, Jari-Matti Mäkelä
/// License: GPL3
/// $(Maturity average)
module cmd.DDocXML;

import cmd.Highlight,
       cmd.DDocEmitter;
import drc.doc.Macro;
import drc.ast.Declarations;
import drc.semantic.Module;
import common;

/// Traverses the syntax tree and writes DDoc макрос в a ткст буфер.
class РЯРЭмиттерДДок : ЭмиттерДДок
{
  /// Constructs a РЯРЭмиттерДДок object.
  this(Модуль модуль, ТаблицаМакросов мтаблица, бул включатьНедокументированное,
       ПодсветчикСем псвСем)
  {
    super(модуль, мтаблица, включатьНедокументированное, псвСем);
  }

  alias Декларация D;

override:
  D посети(ДекларацияФункции d)
  {
    if (!ddoc(d))
      return d;
    auto тип = textSpan(d.типВозврата.типОснова.начало, d.типВозврата.конец);
    DECL({
      пиши("function, ");
      пиши("$(TYPE ");
      пиши("$(RETURNS ", escape(тип), ")");
      writeTemplateParams();
      writeParams(d.парамы);
      пиши(")");
      SYMBOL(d.имя.ткт, "function", d);
    }, d);
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
      DECL({ пиши("переменная, "); пиши("$(TYPE ", escape(тип), ")");
        SYMBOL(имя.ткт, "переменная", d);
      }, d);
    DESC();
    return d;
  }
}
