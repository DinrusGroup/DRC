module drc.Diagnostics;

public import drc.Information;

/// Собирает диагностическую информацию о процессе компиляции.
class Диагностика
{
  Информация[] инфо;

  бул естьИнфо()
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
