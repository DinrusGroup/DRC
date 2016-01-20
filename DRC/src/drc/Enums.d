/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity very high)
module drc.Enums;

import common;

/// Перечень классов хранения.
enum КлассХранения
{
  Нет         = 0,
  Абстрактный     = 1,
  Авто         = 1<<2,
  Конст        = 1<<3,
  Устаревший   = 1<<4,
  Экстерн       = 1<<5,
  Окончательный        = 1<<6,
  Инвариант    = 1<<7,
  Перепись     = 1<<8,
  Масштаб        = 1<<9,
  Статический       = 1<<10,
  Синхронизованный = 1<<11,
  Вхо           = 1<<12,
  Вых          = 1<<13,
  Реф          = 1<<14,
  Отложенный         = 1<<15,
  Вариадический     = 1<<16,
  Манифест     = 1<<17, // D 2.0 manifest using enum.
}

/// Перечень атрибутов защиты.
enum Защита
{
  Нет,
  Приватный/+   = 1+/,
  Защищённый/+ = 1<<1+/,
  Пакет/+   = 1<<2+/,
  Публичный/+    = 1<<3+/,
  Экспорт/+    = 1<<4+/
}

/// Перечень типов компоновки.
enum ТипКомпоновки
{
  Нет,
  C,
  Cpp,
  D,
  Windows,
  Pascal,
  Система
}

/// Возвращает ткст для защ.
ткст вТкст(Защита защ)
{
  switch (защ)
  { alias Защита З;
  case З.Нет:      return "";
  case З.Приватный:   return "private";
  case З.Защищённый: return "protected";
  case З.Пакет:   return "package";
  case З.Публичный:    return "public";
  case З.Экспорт:    return "export";
  default:
    assert(0);
  }
}

/// Возвращает ткст класса хранения. Может быть установлен только 1 бит.
ткст вТкст(КлассХранения кхр)
{
  switch (кхр)
  { alias КлассХранения КХ;
  case КХ.Абстрактный:     return "abstract";
  case КХ.Авто:         return "auto";
  case КХ.Конст:        return "const";
  case КХ.Устаревший:   return "deprecated";
  case КХ.Экстерн:       return "extern";
  case КХ.Окончательный:        return "final";
  case КХ.Инвариант:    return "invariant";
  case КХ.Перепись:     return "override";
  case КХ.Масштаб:        return "scope";
  case КХ.Статический:       return "static";
  case КХ.Синхронизованный: return "synchronized";
  case КХ.Вхо:           return "in";
  case КХ.Вых:          return "out";
  case КХ.Реф:          return "ref";
  case КХ.Отложенный:         return "lazy";
  case КХ.Вариадический:     return "variadic";
  case КХ.Манифест:     return "manifest";
  default:
    assert(0);
  }
}

/// Returns the тксты for кхр. Any число of bits may be установи.
ткст[] вТксты(КлассХранения кхр)
{
  ткст[] результат;
  for (auto i = КлассХранения.max; i; i >>= 1)
    if (кхр & i)
      результат ~= вТкст(i);
  return результат;
}

/// Returns the ткст for ltype.
ткст вТкст(ТипКомпоновки ltype)
{
  switch (ltype)
  { alias ТипКомпоновки ТК;
  case ТК.Нет:    return "";
  case ТК.C:       return "C";
  case ТК.Cpp:     return "Cpp";
  case ТК.D:       return "D";
  case ТК.Windows: return "Windows";
  case ТК.Pascal:  return "Pascal";
  case ТК.Система:  return "System";
  default:
    assert(0);
  }
}
