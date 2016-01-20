/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity average)
module drc.Diagnostics;

public import drc.Information;

/// Собирает диагностическую информацию о процессе компиляции.
class Диагностика
{
  Информация[] инфо;

  бул естьИнфо_ли()
  {
    return инфо.length != 0;
  }

  проц  opCatAssign(Информация инфо)
  {
    this.инфо ~= инфо;
  }

  проц  opCatAssign(Информация[] инфо)
  {
    this.инфо ~= инфо;
  }
}
