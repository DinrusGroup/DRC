/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity average)
module cmd.ASTStats;

import drc.ast.DefaultVisitor,
       drc.ast.Node,
       drc.ast.Declaration,
       drc.ast.Statement,
       drc.ast.Expression,
       drc.ast.Types;

/// Считает узлы в синтактическом древе.
class СтатАДС : ДефолтныйВизитёр
{
  бцел[] таблица; /// Таблица для подсчёта узлов.

  /// Starts counting.
  бцел[] счёт(Узел корень)
  {
    таблица = new бцел[г_именаКлассов.length];
    super.посетиУ(корень);
    return таблица;
  }

  // Перепись отправь function.
  override Узел отправь(Узел n)
  {
    таблица[n.вид]++;
    return super.отправь(n);
  }
}
