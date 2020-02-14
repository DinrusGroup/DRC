
module tpl.typetuple;

/**
 * Создаёт кортеж типов в виде цепочки из нуля и более типов.
 * Пример:
 * ---
 * import tpl.typetuple;
 * alias КортежТипа!(цел, дво) TL;
 *
 * цел foo(TL td)  // то же что и цел foo(цел, дво);
 * {
 *    return td[0] + cast(цел)td[1];
 * }
 * ---
 *
 * Пример:
 * ---
 * КортежТипа!(TL, сим)
 * // это равнозначно с:
 * КортежТипа!(цел, дво, сим)
 * ---
 */
template КортежТипа(ТСписок...)
{
    alias ТСписок КортежТипа;
}

/**
 * Возвращает индекс первого случая типа T, найденного в
 * цепи из ноль или более типов в ТСписке.
 * Если не найден, будет получен ответ -1.
 * Пример:
 * ---
 * import tpl.typetuple;
 * import stdrus;
 *
 * проц foo()
 * {
 *    пишифнс("Индексом дол является ",
 *          Индекс_у!(дол, КортежТипа!(цел, дол, дво)));
 *    // выводит: Индексом дол является 1
 * }
 * ---
 */
template Индекс_у(T, ТСписок...)
{
    static if (ТСписок.length == 0)
	const цел Индекс_у = -1;
    else static if (is(T == ТСписок[0]))
	const цел Индекс_у = 0;
    else
	const цел Индекс_у =
		(Индекс_у!(T, ТСписок[1 .. length]) == -1)
			? -1
			: 1 + Индекс_у!(T, ТСписок[1 .. length]);
}

/**
 * Returns a typetuple created from ТСписок with the first occurrence,
 * if any, of T removed.
 * Example:
 * ---
 * Вырезать!(дол, цел, дол, double, сим)
 * // is the same as:
 * КортежТипа!(цел, double, сим)
 * ---
 */
template Вырезать(T, ТСписок...)
{
    static if (ТСписок.length == 0)
	alias ТСписок Вырезать;
    else static if (is(T == ТСписок[0]))
	alias ТСписок[1 .. length] Вырезать;
    else
	alias КортежТипа!(ТСписок[0], Вырезать!(T, ТСписок[1 .. length])) Вырезать;
}

/**
 * Returns a typetuple created from ТСписок with the all occurrences,
 * if any, of T removed.
 * Example:
 * ---
 * alias КортежТипа!(цел, дол, дол, цел) TL;
 *
 * ВырезатьВсе!(дол, TL)
 * // is the same as:
 * КортежТипа!(цел, цел)
 * ---
 */
template ВырезатьВсе(T, ТСписок...)
{
    static if (ТСписок.length == 0)
	alias ТСписок ВырезатьВсе;
    else static if (is(T == ТСписок[0]))
	alias ВырезатьВсе!(T, ТСписок[1 .. length]) ВырезатьВсе;
    else
	alias КортежТипа!(ТСписок[0], ВырезатьВсе!(T, ТСписок[1 .. length])) ВырезатьВсе;
}

/**
 * Returns a typetuple created from ТСписок with the all duplicate
 * типы removed.
 * Example:
 * ---
 * alias КортежТипа!(цел, дол, дол, цел, float) TL;
 *
 * БезДубликатов!(TL)
 * // is the same as:
 * КортежТипа!(цел, дол, float)
 * ---
 */
template БезДубликатов(ТСписок...)
{
    static if (ТСписок.length == 0)
	alias ТСписок БезДубликатов;
    else
	alias КортежТипа!(ТСписок[0], БезДубликатов!(ВырезатьВсе!(ТСписок[0], ТСписок[1 .. length]))) БезДубликатов;
}

/**
 * Returns a typetuple created from ТСписок with the first occurrence
 * of тип T, if found, replaced with тип U.
 * Example:
 * ---
 * alias КортежТипа!(цел, дол, дол, цел, float) TL;
 *
 * Заменить!(дол, сим, TL)
 * // is the same as:
 * КортежТипа!(цел, сим, дол, цел, float)
 * ---
 */
template Заменить(T, U, ТСписок...)
{
    static if (ТСписок.length == 0)
	alias ТСписок Заменить;
    else static if (is(T == ТСписок[0]))
	alias КортежТипа!(U, ТСписок[1 .. length]) Заменить;
    else
	alias КортежТипа!(ТСписок[0], Заменить!(T, U, ТСписок[1 .. length])) Заменить;
}

/**
 * Returns a typetuple created from ТСписок with all occurrences
 * of тип T, if found, replaced with тип U.
 * Example:
 * ---
 * alias КортежТипа!(цел, дол, дол, цел, float) TL;
 *
 * ЗаменитьВсе!(дол, сим, TL)
 * // is the same as:
 * КортежТипа!(цел, сим, сим, цел, float)
 * ---
 */
template ЗаменитьВсе(T, U, ТСписок...)
{
    static if (ТСписок.length == 0)
	alias ТСписок ЗаменитьВсе;
    else static if (is(T == ТСписок[0]))
	alias КортежТипа!(U, ЗаменитьВсе!(T, U, ТСписок[1 .. length])) ЗаменитьВсе;
    else
	alias КортежТипа!(ТСписок[0], ЗаменитьВсе!(T, U, ТСписок[1 .. length])) ЗаменитьВсе;
}

/**
 * Returns a typetuple created from ТСписок with the order reversed.
 * Example:
 * ---
 * alias КортежТипа!(цел, дол, дол, цел, float) TL;
 *
 * Реверсировать!(TL)
 * // is the same as:
 * КортежТипа!(float, цел, дол, дол, цел)
 * ---
 */
template Реверсировать(ТСписок...)
{
    static if (ТСписок.length == 0)
	alias ТСписок Реверсировать;
    else
	alias КортежТипа!(Реверсировать!(ТСписок[1 .. length]), ТСписок[0]) Реверсировать;
}

/**
 * Returns the тип from ТСписок that is the most derived from тип T.
 * If none are found, T is returned.
 * Example:
 * ---
 * class A { }
 * class B : A { }
 * class C : B { }
 * alias КортежТипа!(A, C, B) TL;
 *
 * ПоследнийПроизводный!(Object, TL) x;  // x is declared as тип C
 * ---
 */
template ПоследнийПроизводный(T, ТСписок...)
{
    static if (ТСписок.length == 0)
	alias T ПоследнийПроизводный;
    else static if (is(ТСписок[0] : T))
	alias ПоследнийПроизводный!(ТСписок[0], ТСписок[1 .. length]) ПоследнийПроизводный;
    else
	alias ПоследнийПроизводный!(T, ТСписок[1 .. length]) ПоследнийПроизводный;
}

/**
 * Returns the typetuple ТСписок with the типы sorted so that the most
 * derived типы come first.
 * Example:
 * ---
 * class A { }
 * class B : A { }
 * class C : B { }
 * alias КортежТипа!(A, C, B) TL;
 *
 * ПроизводныйВперёд!(TL)
 * // is the same as:
 * КортежТипа!(C, B, A)
 * ---
 */
template ПроизводныйВперёд(ТСписок...)
{
    static if (ТСписок.length == 0)
	alias ТСписок ПроизводныйВперёд;
    else
	alias КортежТипа!(ПоследнийПроизводный!(ТСписок[0], ТСписок[1 .. length]),
	                ПроизводныйВперёд!(ЗаменитьВсе!(ПоследнийПроизводный!(ТСписок[0], ТСписок[1 .. length]),
						    ТСписок[0],
						    ТСписок[1 .. length]))) ПроизводныйВперёд;
}
