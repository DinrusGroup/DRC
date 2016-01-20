/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module cmd.DDocHTML;

import cmd.Highlight,
       cmd.DDocEmitter;
import drc.doc.Macro;
import drc.semantic.Module;
import common;

/// Traverses the syntax tree and writes DDoc макрос в a ткст буфер.
class ГЯРЭмиттерДДок : ЭмиттерДДок
{
  /// Constructs a ГЯРЭмиттерДДок object.
  this(Модуль модуль, ТаблицаМакросов мтаблица, бул включатьНедокументированное,
       ПодсветчикСем псвСем)
  {
    super(модуль, мтаблица, включатьНедокументированное, псвСем);
  }
}
