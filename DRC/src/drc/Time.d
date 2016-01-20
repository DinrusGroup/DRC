/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.Time;

import tango.stdc.time : т_время, время, ctime;
import tango.stdc.string : strlen;

/// Some convenience functions for dealing with C's время functions.
struct Время
{
static:
  /// Возвращает текущую дату в форме текста.
  сим[] вТкст()
  {
    т_время знач_врем;
    .время(&знач_врем);
    сим* ткт = ctime(&знач_врем); // ctime returns a pointer в a static массив.
    сим[] ткстВрем = ткт[0 .. strlen(ткт)-1]; // -1 removes trailing '\n'.
    return ткстВрем.dup;
  }

  /// Возвращает время  ткстВрем: чч:мм:сс
  сим[] время(сим[] ткстВрем)
  {
    return ткстВрем[11..19];
  }

  /// Возвращает месяц и день из ткстВрем: Ммм дд
  сим[] день_месяца(сим[] ткстВрем)
  {
    return ткстВрем[4..10];
  }

  /// Возвращает год из ткстВрем: гггг
  сим[] год(сим[] ткстВрем)
  {
    return ткстВрем[20..24];
  }
}
