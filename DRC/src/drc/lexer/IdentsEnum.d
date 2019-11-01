
module drc.lexer.IdentsEnum;

import drc.lexer.IdentsGenerator;

version(DDoc)
  enum ВИД : бкрат; /// Перечень видов предопределенных идентификаторов.
else
mixin(
  // Перечисляет предопределённые идентификаторы.
  "enum ВИД : бкрат {"
    "Нуль,"
    ~ генерируйЧленыИД ~
  "}"
);
