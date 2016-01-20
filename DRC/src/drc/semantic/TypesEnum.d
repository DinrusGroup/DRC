/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.semantic.TypesEnum;

/// Enumeration of Тип IDs.
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

  ДМассив, /// Dynamic массив.
  СМассив, /// Статический массив.
  АМассив, /// Associative массив.

  Перечень,       /// An enum.
  Структура,     /// A struct.
  Класс,      /// A class.
  Типдеф,    /// A typedef.
  Функция,   /// A function.
  Делегат,   /// A delegate.
  Указатель,    /// A pointer.
  Ссылка,  /// A reference.
  Идентификатор, /// An identifier.
  ШЭкземпляр,  /// Шаблон instance.
  Кортеж,      /// A template tuple.
  Конст,      /// A constant тип. D2.0
  Инвариант,  /// An invariant тип. D2.0
}
