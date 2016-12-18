/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.Time;

import cidrus : time, ctime, time_t, strlen;

/// Some convenience functions for dealing with C's время functions.
struct Время
{
static:
  /// Возвращает текущую дату в форме текста.
  ткст вТкст()
  {
    time_t знач_врем;
    .time(&знач_врем);
    сим* ткт = ctime(&знач_врем); // ctime returns a pointer в a static массив.
    ткст ткстВрем = ткт[0 .. strlen(ткт)-1]; // -1 removes trailing '\n'.
    return ткстВрем.dup;
  }

  /// Возвращает время  ткстВрем: чч:мм:сс
  ткст время(ткст ткстВрем)
  {
    return ткстВрем[11..19];
  }

  /// Возвращает месяц и день из ткстВрем: Ммм дд
  ткст день_месяца(ткст ткстВрем)
  {
    return ткстВрем[4..10];
  }

  /// Возвращает год из ткстВрем: гггг
  ткст год(ткст ткстВрем)
  {
    return ткстВрем[20..24];
  }
}
