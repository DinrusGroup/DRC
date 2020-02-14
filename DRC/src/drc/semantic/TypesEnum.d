/// Author: Aziz Köksal, Vitaly Kulich
/// License: GPL3
/// $(Maturity high)
module drc.semantic.TypesEnum;

/// Перечень идентификаторов типов.
enum ТИП
{
  Ошибка,
  // Basic types.
  Сим,    /// сим
  Шим,   /// шим
  Дим,   /// дим
  Бул,    /// бул
  Байт,    /// int8
  Ббайт,   /// uint8
  Крат,   /// int16
  Бкрат,  /// uint16
  Цел,     /// int32
  Бцел,    /// uint32
  Дол,    /// int64
  Бдол,   /// uint64
  Цент,    /// int128
  Бцент,   /// uint128
  Плав,   /// float32
  Дво,  /// float64
  Реал,    /// float80
  Вплав,  /// imaginary float32
  Вдво, /// imaginary float64
  Вреал,   /// imaginary float80
  Кплав,  /// complex float32
  Кдво, /// complex float64
  Креал,   /// complex float80
  Проц,    /// проц 

  Нет,   /// TypeNone in the specs. Why?

  ДМассив, /// Динамический массив.
  СМассив, /// Статический массив.
  АМассив, /// Ассоциативный массив.

  Перечень,       /// An enum.
  Структура,     /// атр struct.
  Класс,      /// атр class.
  Типдеф,    /// атр alias.
  Функция,   /// атр function.
  Делегат,   /// атр delegate.
  Указатель,    /// атр pointer.
  Ссылка,  /// атр reference.
  Идентификатор, /// An идентификатор.
  ШЭкземпляр,  /// Шаблон instance.
  Кортеж,      /// атр template tuple.
  Конст,      /// атр constant тип. D2.0
  Инвариант,  /// An invariant тип. D2.0
}
