module cmd.ASTStats;

import drc.ast.DefaultVisitor,
       drc.ast.Node,
       drc.ast.Declaration,
       drc.ast.Statement,
       drc.ast.Expression,
       drc.ast.Types;

/// Считает узлы в абстрактном синтактическом древе (АСД).
class СтатАСД : ДефолтныйВизитёр
{
  бцел[] таблица; /// Таблица для подсчёта узлов.

  /// Начать подсчёт.
  бцел[] счёт(Узел корень)
  {
    таблица = new бцел[г_именаКлассов.length];
    super.посетиУ(корень);
    return таблица;
  }

  /// Переписываемая функция отправки.
  override Узел отправь(Узел n)
  {
    таблица[n.вид]++;
    return super.отправь(n);
  }
}
