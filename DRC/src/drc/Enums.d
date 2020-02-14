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
  Си,
  СиПП,
  Ди,
  Виндовс,
  Паскаль,
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

/// Возвращает ткст для защ в русском варианте.
ткст вТкстРус(Защита защ)
{
	switch (защ)
	{ alias Защита З;
		case З.Нет:      return "";
		case З.Приватный:   return "прив";
		case З.Защищённый: return "защ";
		case З.Пакет:   return "пакет";
		case З.Публичный:    return "пуб";
		case З.Экспорт:    return "экспорт";
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

ткст вТкстРус(КлассХранения кхр)
{
	switch (кхр)
	{ alias КлассХранения КХ;
		case КХ.Абстрактный:     return "абстр";
		case КХ.Авто:         return "авто";
		case КХ.Конст:        return "конст";
		case КХ.Устаревший:   return "устар";
		case КХ.Экстерн:       return "экстерн";
		case КХ.Окончательный:        return "фин";
		case КХ.Инвариант:    return "инвариант";
		case КХ.Перепись:     return "переп";
		case КХ.Масштаб:        return "масштаб";
		case КХ.Статический:       return "стат";
		case КХ.Синхронизованный: return "синхр";
		case КХ.Вхо:           return "вхо";
		case КХ.Вых:          return "вых";
		case КХ.Реф:          return "реф";
		case КХ.Отложенный:         return "отлож";
		case КХ.Вариадический:     return "вариад";
		case КХ.Манифест:     return "манифест";
		default:
			assert(0);
	}
}

/// Возвращает тксты для кхр. Может устанавливаться любое число битов.
ткст[] вТксты(КлассХранения кхр)
{
  ткст[] результат;
  for (auto i = КлассХранения.max; i; i >>= 1)
    if (кхр & i)
      результат ~= вТкст(i);
  return результат;
}

/// Возвращает ткст для типК.
ткст вТкст(ТипКомпоновки типК)
{
  switch (типК)
  { alias ТипКомпоновки ТК;
  case ТК.Нет:    return "";
  case ТК.Си:       return "к";
  case ТК.СиПП:     return "Cpp";
  case ТК.Ди:       return "D";
  case ТК.Виндовс: return "Windows";
  case ТК.Паскаль:  return "Pascal";
  case ТК.Система:  return "System";
  default:
    assert(0);
  }
}

/// Возвращает ткст для типК в русском варианте.
ткст вТкстРус(ТипКомпоновки типК)
{
	switch (типК)
	{ alias ТипКомпоновки ТК;
		case ТК.Нет:    return "";
		case ТК.Си:       return "Си";
		case ТК.СиПП:     return "СиПП";
		case ТК.Ди:       return "Ди";
		case ТК.Виндовс: return "Виндовс";
		case ТК.Паскаль:  return "Паскаль";
		case ТК.Система:  return "Система";
		default:
			assert(0);
	}
}
