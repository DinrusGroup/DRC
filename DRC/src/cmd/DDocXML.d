/// Authors: Aziz Köksal, Vitaly Kulich, Jari-Matti Mäkelä
/// License: GPL3
/// $(Maturity average)
module cmd.DDocXML;

import cmd.Highlight,
       cmd.DDocEmitter;
import drc.doc.Macro;
import drc.ast.Declarations;
import drc.semantic.Module;
import common;

/// Обходит синтактическое дерево и записывает макрос DDoc в текстовый буфер.
class РЯРЭмиттерДДок : ЭмиттерДДок
{
  /// Строит РЯРЭмиттерДДок объект.
  this(Модуль модуль, ТаблицаМакросов мтаблица, бул включатьНедокументированное,
       ПодсветчикСем псвСем)
  {
    super(модуль, мтаблица, включатьНедокументированное, псвСем);
  }

  alias Декларация D;

override:
  D посети(ДекларацияФункции d)
  {
    if (!ддок(d))
      return d;
    auto тип = участокТекста(d.типВозврата.типОснова.начало, d.типВозврата.конец);
    ДЕКЛ({
      пиши("function, ");
      пиши("$(TYPE ");
      пиши("$(RETURNS ", escape(тип), ")");
      пишиПарамыШаблона();
      пишиПарамы(d.парамы);
      пиши(")");
      СИМВОЛ(d.имя.ткт, "function", d);
    }, d);
    ДЕСК();
    return d;
  }

  D посети(ДекларацияПеременных d)
  {
    if (!ддок(d))
      return d;
    ткст тип = "auto";
    if (d.узелТипа)
      тип = участокТекста(d.узелТипа.типОснова.начало, d.узелТипа.конец);
    foreach (имя; d.имена)
      ДЕКЛ({ пиши("variable, "); пиши("$(TYPE ", escape(тип), ")");
        СИМВОЛ(имя.ткт, "variable", d);
      }, d);
    ДЕСК();
    return d;
  }
}
