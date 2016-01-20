/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module drc.lexer.IdentsEnum;

import drc.lexer.IdentsGenerator;

version(DDoc)
  enum ВИД : бкрат; /// Перечень видов предопределенных идентификаторов.
else
mixin(
  // Enumerates predefined identifiers.
  "enum ВИД : бкрат {"
    "Нуль,"
    ~ генерируйЧленыИД ~
  "}"
);
