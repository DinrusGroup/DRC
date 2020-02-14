
// Написано на языке программирования Динрус.

/**
 * Шаблоны для извлечения информации о типах во время
 * компиляции.
 *
 * Macros:
 *	WIKI = Phobos/StdTraits
 * Copyright:
 *	Public Domain
 */

/*
 * Authors:
 *	Walter Bright, Digital Mars, www.digitalmars.com
 *	Tomasz Stachowiak (статМас_ли, кортежВыражений_ли)
 */

module tpl.traits;

/***
 * Получить тип возвратного значения функции,
 * указатель на функуцию или делегат.
 * Пример:
 * ---
 * import tpl.traits;
 * цел foo();
 * ВозврТип!(foo) x;   // x объявлен как цел
 * ---
 */
template ВозврТип(alias дг)
{
    alias ВозврТип!(typeof(дг)) ВозврТип;
}

/** описано ранее */
template ВозврТип(дг)
{
    static if (is(дг R == return))
	alias R ВозврТип;
    else
	static assert(0, cast(ткст) "у аргумента отсутствует тип возврата");
}

/***
 * Получить типы заданных функции  параметров,
 * указатель на функцию или на делегат в виде кортежа.
 * Пример:
 * ---
 * import tpl.traits;
 * цел foo(цел, дол);
 * проц bar(КортежТипаПараметр!(foo));      // объявляет проц bar(цел, дол);
 * проц abc(КортежТипаПараметр!(foo)[1]);   // объявляет проц abc(дол);
 * ---
 */
template КортежТипаПараметр(alias дг)
{
    alias КортежТипаПараметр!(typeof(дг)) КортежТипаПараметр;
}

/** описано ранее */
template КортежТипаПараметр(дг)
{
    static if (is(дг P == function))
	alias P КортежТипаПараметр;
    else static if (is(дг P == delegate))
	alias КортежТипаПараметр!(P) КортежТипаПараметр;
    else static if (is(дг P == P*))
	alias КортежТипаПараметр!(P) КортежТипаПараметр;
    else
	static assert(0, cast(ткст) "у аргумента отсутствуют параметры");
}


/***
 * Получить типы полей структуры или класса.
 * Состоят из полей, занимающих пространство памяти,
 * за исключением скрытых полей типа указателя на
 * таблицу виртуальных функций.
 */

template КортежТипаПоле(S)
{
    static if (is(S == struct) || is(S == class))
	alias typeof(S.tupleof) КортежТипаПоле;
    else
	static assert(0, cast(ткст)"аргумент не является структурой или классом");
}


/***
 * Получить КортежТипа базового класса и базовые интерфейсы
 * данного класса или интерфейса.
 * Пример:
 * ---
 * import tpl.traits, tpl.typetuple, stdrus;
 * interface I { }
 * class A { }
 * class B : A, I { }
 *
 * проц main()
 * {
 *     alias КортежТипаОснова!(B) TL;
 *     writefln(typeid(TL));	// prints: (A,I)
 * }
 * ---
 */

template КортежТипаОснова(A)
{
    static if (is(A P == super))
	alias P КортежТипаОснова;
    else
	static assert(0, cast(ткст) "аргумент не является классом или интерфейсом");
}

unittest
{
    interface I { }
    class A { }
    class B : A, I { }

    alias КортежТипаОснова!(B) TL;
    assert(TL.length == 2);
    assert(is (TL[0] == A));
    assert(is (TL[1] == I));
}

/* *******************************************
 */
private template isStaticArray_impl(Т)
{
    const Т inst = void;
    
    static if (is(typeof(Т.length)))
    {
	static if (!is(Т == typeof(Т.init)))
	{			// abuses the fact that цел[5].init == цел
	    static if (is(Т == typeof(Т[0])[inst.length]))
	    {	// sanity check. this check alone isn't enough because dmd complains about dynamic arrays
		const бул рез =да;
	    }
	    else
		const бул рез = нет;
	}
	else
	    const бул рез = нет;
    }
    else
    {
	    const бул рез = нет;
    }
}
/**
 * Detect whether тип Т is a static массив.
 */
template статМас_ли(Т)
{
    const бул статМас_ли = isStaticArray_impl!(Т).рез;
}


static assert (статМас_ли!(цел[51]));
static assert (статМас_ли!(цел[][2]));
static assert (статМас_ли!(сим[][цел][11]));
static assert (!статМас_ли!(цел[]));
static assert (!статМас_ли!(цел[сим]));
static assert (!статМас_ли!(цел[1][]));

/**
 * Tells whether the кортеж Т is an expression кортеж.
 */
template кортежВыражений_ли(Т ...)
{
    static if (is(проц function(Т)))
	const бул кортежВыражений_ли = false;
    else
	const бул кортежВыражений_ли = true;
}

//std2.traits

/***
 * Получить тип возврата функции,
 * указатель на функцию, структуру с opCall
 * или класс с opCall.
 * Пример:
 * ---
 * import tpl.traits;
 * цел foo();
 * ТипВозврата2!(foo) x;   // x объявлен как цел
 * ---
 */
template ТипВозврата2(alias дг)
{
    alias ТипВозврата2!(typeof(дг), проц) ТипВозврата2;
}

template ТипВозврата2(дг, dummy = void)
{
    static if (is(дг R == return))
	alias R ТипВозврата2;
    else static if (is(дг Т : Т*))
	alias ТипВозврата2!(Т, проц) ТипВозврата2;
    else static if (is(дг S == struct))
	alias ТипВозврата2!(typeof(&дг.opCall), проц) ТипВозврата2;
    else static if (is(дг C == class))
	alias ТипВозврата2!(typeof(&дг.opCall), проц) ТипВозврата2;
    else
	static assert(0, "у аргумента false возвратного типа");
}

unittest
{
    struct G
    {
	цел opCall (цел i) { return 1;}
    }

    //alias ТипВозврата2!(G) ShouldBeInt;
   // static assert(is(ShouldBeInt == цел));

    G g;
    static assert(is(ТипВозврата2!(g) == цел));

    G* p;
    alias ТипВозврата2!(p) pg;
    static assert(is(pg == цел));

    class C
    {
	цел opCall (цел i) { return 1;}
    }

   // static assert(is(ТипВозврата2!(C) == цел));

    C c;
    static assert(is(ТипВозврата2!(c) == цел));
}

/***
 * Получить  типы параметров функции,
 * указатель на функцию или делегата в качестве кортежа.
 * Пример:
 * ---
 * import std.traits;
 * цел foo(цел, дол);
 * проц bar(КортежТипаПараметров!(foo));      // declares проц bar(цел, дол);
 * проц abc(КортежТипаПараметров!(foo)[1]);   // declares проц abc(дол);
 * ---
 */
template КортежТипаПараметров(alias дг)
{
    alias КортежТипаПараметров!(typeof(дг)) КортежТипаПараметров;
}

/** описано ранее */
template КортежТипаПараметров(дг)
{
    static if (is(дг P == function))
	alias P КортежТипаПараметров;
    else static if (is(дг P == delegate))
	alias КортежТипаПараметров!(P) КортежТипаПараметров;
    else static if (is(дг P == P*))
	alias КортежТипаПараметров!(P) КортежТипаПараметров;
    else
	static assert(0, "у аргумента параметры отсутствуют");
}
/+

/***
 * Get the типы of the fields of a struct or class.
 * This consists of the fields that take up memory space,
 * excluding the hidden fields like the virtual function
 * table pointer.
 */

template FieldTypeTuple(S)
{
    static if (is(S == struct) || is(S == class) || is(S == union))
	alias typeof(S.tupleof) FieldTypeTuple;
    else
        alias S FieldTypeTuple;
	//static assert(0, "argument is not struct or class");
}

// // FieldOffsetsTuple
// protected template FieldOffsetsTupleImpl(т_мера n, Т...)
// {
//     static if (Т.length == 0)
//     {
//         alias КортежТипа!() Result;
//     }
//     else
//     {
//         //protected alias FieldTypeTuple!(Т[0]) Types;
//         protected enum т_мера myOffset =
//             ((n + Т[0].alignof - 1) / Т[0].alignof) * Т[0].alignof;
//         static if (is(Т[0] == struct))
//         {
//             alias FieldTypeTuple!(Т[0]) MyRep;
//             alias FieldOffsetsTupleImpl!(myOffset, MyRep, Т[1 .. $]).Result
//                 Result;
//         }
//         else
//         {
//             protected enum т_мера mySize = Т[0].sizeof;
//             alias КортежТипа!(myOffset) Head;
//             static if (is(Т == union))
//             {
//                 alias FieldOffsetsTupleImpl!(myOffset, Т[1 .. $]).Result
//                     Tail;
//             }
//             else
//             {
//                 alias FieldOffsetsTupleImpl!(myOffset + mySize,
//                                              Т[1 .. $]).Result
//                     Tail;
//             }
//             alias КортежТипа!(Head, Tail) Result;
//         }
//     }
// }

// template FieldOffsetsTuple(Т...)
// {
//     alias FieldOffsetsTupleImpl!(0, Т).Result FieldOffsetsTuple;
// }

// unittest
// {
//     alias FieldOffsetsTuple!(цел) T1;
//     assert(T1.length == 1 && T1[0] == 0);
//     //
//     struct S2 { char a; цел b; char c; double d; char e, f; }
//     alias FieldOffsetsTuple!(S2) T2;
//     //pragma(msg, T2);
//     static assert(T2.length == 6
//            && T2[0] == 0 && T2[1] == 4 && T2[2] == 8 && T2[3] == 16
//                   && T2[4] == 24&& T2[5] == 25);
//     //
//     class C { цел a, b, c, d; }
//     struct S3 { char a; C b; char c; }
//     alias FieldOffsetsTuple!(S3) T3;
//     //pragma(msg, T2);
//     static assert(T3.length == 3
//            && T3[0] == 0 && T3[1] == 4 && T3[2] == 8);
//     //
//     struct S4 { char a; union { цел b; char c; } цел d; }
//     alias FieldOffsetsTuple!(S4) T4;
//     //pragma(msg, FieldTypeTuple!(S4));
//     static assert(T4.length == 4
//            && T4[0] == 0 && T4[1] == 4 && T4[2] == 8);
// }

// /***
// Get the offsets of the fields of a struct or class.
// */

// template FieldOffsetsTuple(S)
// {
//     static if (is(S == struct) || is(S == class))
// 	alias typeof(S.tupleof) FieldTypeTuple;
//     else
// 	static assert(0, "argument is not struct or class");
// }

/***
Get the primitive типы of the fields of a struct or class, in
topological order.

Example:
----
struct S1 { цел a; float b; }
struct S2 { ткст a; union { S1 b; S1 * c; } }
alias RepresentationTypeTuple!(S2) R;
assert(R.length == 4
    && is(R[0] == char[]) && is(R[1] == цел)
    && is(R[2] == float) && is(R[3] == S1*));
----
*/

template RepresentationTypeTuple(Т...)
{
    static if (Т.length == 0)
    {
        alias КортежТипа!() RepresentationTypeTuple;
    }
    else
    {
        static if (is(Т[0] == struct) || is(Т[0] == union))
// @@@BUG@@@ this should work
//             alias .RepresentationTypes!(Т[0].tupleof)
//                 RepresentationTypes;
            alias .RepresentationTypeTuple!(FieldTypeTuple!(Т[0]),
                                            Т[1 .. $])
                RepresentationTypeTuple;
        else static if (is(Т[0] U == typedef))
        {
            alias .RepresentationTypeTuple!(FieldTypeTuple!(U),
                                            Т[1 .. $])
                RepresentationTypeTuple;
        }
        else
        {
            alias КортежТипа!(Т[0], RepresentationTypeTuple!(Т[1 .. $]))
                RepresentationTypeTuple;
        }
    }
}

unittest
{
    alias RepresentationTypeTuple!(цел) S1;
    static assert(is(S1 == КортежТипа!(цел)));
    struct S2 { цел a; }
    static assert(is(RepresentationTypeTuple!(S2) == КортежТипа!(цел)));
    struct S3 { цел a; char b; }
    static assert(is(RepresentationTypeTuple!(S3) == КортежТипа!(цел, char)));
    struct S4 { S1 a; цел b; S3 c; }
    static assert(is(RepresentationTypeTuple!(S4) ==
                     КортежТипа!(цел, цел, цел, char)));

    struct S11 { цел a; float b; }
    struct S21 { ткст a; union { S11 b; S11 * c; } }
    alias RepresentationTypeTuple!(S21) R;
    assert(R.length == 4
           && is(R[0] == char[]) && is(R[1] == цел)
           && is(R[2] == float) && is(R[3] == S11*));
}

/*
RepresentationOffsets
*/

// protected template Repeat(т_мера n, Т...)
// {
//     static if (n == 0) alias КортежТипа!() Repeat;
//     else alias КортежТипа!(Т, Repeat!(n - 1, Т)) Repeat;
// }

// template RepresentationOffsetsImpl(т_мера n, Т...)
// {
//     static if (Т.length == 0)
//     {
//         alias КортежТипа!() Result;
//     }
//     else
//     {
//         protected enum т_мера myOffset =
//             ((n + Т[0].alignof - 1) / Т[0].alignof) * Т[0].alignof;
//         static if (!is(Т[0] == union))
//         {
//             alias Repeat!(n, FieldTypeTuple!(Т[0])).Result
//                 Head;
//         }
//         static if (is(Т[0] == struct))
//         {
//             alias .RepresentationOffsetsImpl!(n, FieldTypeTuple!(Т[0])).Result
//                 Head;
//         }
//         else
//         {
//             alias КортежТипа!(myOffset) Head;
//         }
//         alias КортежТипа!(Head,
//                          RepresentationOffsetsImpl!(
//                              myOffset + Т[0].sizeof, Т[1 .. $]).Result)
//             Result;
//     }
// }

// template RepresentationOffsets(Т)
// {
//     alias RepresentationOffsetsImpl!(0, Т).Result
//         RepresentationOffsets;
// }

// unittest
// {
//     struct S1 { char c; цел i; }
//     alias RepresentationOffsets!(S1) Offsets;
//     static assert(Offsets[0] == 0);
//     //pragma(msg, Offsets[1]);
//     static assert(Offsets[1] == 4);
// }

// hasRawAliasing

protected template HasRawPointerImpl(Т...)
{
    static if (Т.length == 0)
    {
        const результат = false;
    }
    else
    {
        static if (is(Т[0] U : U*))
            const hasRawAliasing = true;
        else static if (is(Т[0] U : U[]))
            const hasRawAliasing = true;
        else
            const hasRawAliasing = false;
        const результат = hasRawAliasing || HasRawPointerImpl!(Т[1 .. $]).результат;
    }
}

/*
Statically evaluates to $(D true) if and only if $(D Т)'s
representation contains at least one field of pointer or массив type.
Members of class типы are not considered raw pointers. Pointers to
invariant objects are not considered raw aliasing.

Example:
---
// simple типы
static assert(!hasRawAliasing!(цел));
static assert(hasRawAliasing!(char*));
// references aren't raw pointers
static assert(!hasRawAliasing!(Object));
// built-in arrays do contain raw pointers
static assert(hasRawAliasing!(цел[]));
// aggregate of simple типы
struct S1 { цел a; double b; }
static assert(!hasRawAliasing!(S1));
// indirect aggregation
struct S2 { S1 a; double b; }
static assert(!hasRawAliasing!(S2));
// struct with a pointer member
struct S3 { цел a; double * b; }
static assert(hasRawAliasing!(S3));
// struct with an indirect pointer member
struct S4 { S3 a; double b; }
static assert(hasRawAliasing!(S4));
----
*/
protected template hasRawAliasing(Т...)
{
    const hasRawAliasing
        = HasRawPointerImpl!(RepresentationTypeTuple!(Т)).результат;
}

unittest
{
// simple типы
    static assert(!hasRawAliasing!(цел));
    static assert(hasRawAliasing!(char*));
// references aren't raw pointers
    static assert(!hasRawAliasing!(Object));
    static assert(!hasRawAliasing!(цел));
    struct S1 { цел z; }
    static assert(!hasRawAliasing!(S1));
    struct S2 { цел* z; }
    static assert(hasRawAliasing!(S2));
    struct S3 { цел a; цел* z; цел c; }
    static assert(hasRawAliasing!(S3));
    struct S4 { цел a; цел z; цел c; }
    static assert(!hasRawAliasing!(S4));
    struct S5 { цел a; Object z; цел c; }
    static assert(!hasRawAliasing!(S5));
    union S6 { цел a; цел b; }
    static assert(!hasRawAliasing!(S6));
    union S7 { цел a; цел * b; }
    static assert(hasRawAliasing!(S7));
    typedef цел* S8;
    static assert(hasRawAliasing!(S8));
    enum S9 { a };
    static assert(!hasRawAliasing!(S9));
    // indirect members
    struct S10 { S7 a; цел b; }
    static assert(hasRawAliasing!(S10));
    struct S11 { S6 a; цел b; }
    static assert(!hasRawAliasing!(S11));
}

/*
Statically evaluates to $(D true) if and only if $(D Т)'s
representation includes at least one non-invariant object reference.
*/

protected template hasObjects(Т...)
{
    static if (Т.length == 0)
    {
        const hasObjects = false;
    }
    else static if (is(Т[0] U == typedef))
    {
        const hasObjects = hasObjects!(U, Т[1 .. $]);
    }
    else static if (is(Т[0] == struct))
    {
        const hasObjects = hasObjects!(
            RepresentationTypeTuple!(Т[0]), Т[1 .. $]);
    }
    else
    {
        const hasObjects = is(Т[0] == class) || hasObjects!(Т[1 .. $]);
    }
}

/**
Returns $(D true) if and only if $(D Т)'s representation includes at
least one of the following: $(OL $(LI a raw pointer $(D U*) and $(D U)
is not invariant;) $(LI an массив $(D U[]) and $(D U) is not
invariant;) $(LI a reference to a class type $(D C) and $(D C) is not
invariant.))
*/

template hasAliasing(Т...)
{
    const hasAliasing = hasRawAliasing!(Т) || hasObjects!(Т);
}

unittest
{
    struct S1 { цел a; Object b; }
    static assert(hasAliasing!(S1));
    struct S2 { string a; }
    static assert(!hasAliasing!(S2));
}

/***
 * Get a $(D_PARAM КортежТипа) of the base class and base interfaces of
 * this class or interface. $(D_PARAM КортежТипаОснова!(Object)) returns
 * the empty type tuple.
 * 
 * Example:
 * ---
 * import tpl.traits, tpl.typetuple, stdrus;
 * interface I { }
 * class A { }
 * class B : A, I { }
 *
 * проц main()
 * {
 *     alias КортежТипаОснова!(B) TL;
 *     writeln(typeid(TL));	// prints: (A,I)
 * }
 * ---
 */

template КортежТипаОснова(A)
{
    static if (is(A P == super))
	alias P КортежТипаОснова;
    else
	static assert(0, "argument is not a class or interface");
}

unittest
{
    interface I1 { }
    interface I2 { }
    class A { }
    class C : A, I1, I2 { }

    alias КортежТипаОснова!(C) TL;
    assert(TL.length == 3);
    assert(is (TL[0] == A));
    assert(is (TL[1] == I1));
    assert(is (TL[2] == I2));

    assert(КортежТипаОснова!(Object).length == 0);
}

/**
 * Get a $(D_PARAM КортежТипа) of $(I all) base classes of this class,
 * in decreasing order. Interfaces are not included. $(D_PARAM
 * BaseClassesTuple!(Object)) yields the empty type tuple.
 *
 * Example:
 * ---
 * import std.traits, std.typetuple, stdrus;
 * interface I { }
 * class A { }
 * class B : A, I { }
 * class C : B { }
 *
 * проц main()
 * {
 *     alias BaseClassesTuple!(C) TL;
 *     writeln(typeid(TL));	// prints: (B,A,Object)
 * }
 * ---
 */

template BaseClassesTuple(Т)
{
    static if (is(Т == Object))
    {
        alias КортежТипа!() BaseClassesTuple;
    }
    static if (is(КортежТипаОснова!(Т)[0] == Object))
    {
        alias КортежТипа!(Object) BaseClassesTuple;
    }
    else
    {
        alias КортежТипа!(КортежТипаОснова!(Т)[0],
                         BaseClassesTuple!(КортежТипаОснова!(Т)[0]))
            BaseClassesTuple;
    }
}

/**
 * Get a $(D_PARAM КортежТипа) of $(I all) interfaces directly or
 * indirectly inherited by this class or interface. Interfaces do not
 * repeat if multiply implemented. $(D_PARAM КортежИнтерфейсов!(Object))
 * yields the empty type tuple.
 *
 * Example:
 * ---
 * import std.traits, std.typetuple, stdrus;
 * interface I1 { }
 * interface I2 { }
 * class A : I1, I2 { }
 * class B : A, I1 { }
 * class C : B { }
 *
 * проц main()
 * {
 *     alias КортежИнтерфейсов!(C) TL;
 *     writeln(typeid(TL));	// prints: (I1, I2)
 * }
 * ---
 */

template КортежИнтерфейсов(Т)
{
    static if (is(Т == Object))
    {
        alias КортежТипа!() КортежИнтерфейсов;
    }
    static if (is(КортежТипаОснова!(Т)[0] == Object))
    {
        alias КортежТипа!(КортежТипаОснова!(Т)[1 .. $]) КортежИнтерфейсов;
    }
    else
    {
        alias БезДубликатов!(
            КортежТипа!(КортежТипаОснова!(Т)[1 .. $], // direct interfaces
                       КортежИнтерфейсов!(КортежТипаОснова!(Т)[0])))
            КортежИнтерфейсов;
    }
}

unittest
{
    interface I1 {}
    interface I2 {}
    {
        // doc example
        class A : I1, I2 { }
        class B : A, I1 { }
        class C : B { }
        alias КортежИнтерфейсов!(C) TL;
        assert(is(TL[0] == I1) && is(TL[1] == I2));
    }
    class B1 : I1, I2 {}
    class B2 : B1, I1 {}
    class B3 : B2, I2 {}
    alias КортежИнтерфейсов!(B3) TL;
    //
    assert(TL.length == 2);
    assert(is (TL[0] == I2));
    assert(is (TL[1] == I1));
}

/**
 * Get a $(D_PARAM КортежТипа) of $(I all) base classes of $(D_PARAM
 * Т), in decreasing order, followed by $(D_PARAM Т)'s
 * interfaces. $(D_PARAM TransitiveКортежТипаОснова!(Object)) yields the
 * empty type tuple.
 *
 * Example:
 * ---
 * import std.traits, std.typetuple, stdrus;
 * interface I { }
 * class A { }
 * class B : A, I { }
 * class C : B { }
 *
 * проц main()
 * {
 *     alias TransitiveКортежТипаОснова!(C) TL;
 *     writeln(typeid(TL));	// prints: (B,A,Object,I)
 * }
 * ---
 */

template TransitiveКортежТипаОснова(Т)
{
    static if (is(Т == Object))
        alias КортежТипа!() TransitiveКортежТипаОснова;
    else
        alias КортежТипа!(BaseClassesTuple!(Т),
            КортежИнтерфейсов!(Т))
            TransitiveКортежТипаОснова;
}

unittest
{
    interface I1 {}
    interface I2 {}
    class B1 {}
    class B2 : B1, I1, I2 {}
    class B3 : B2, I1 {}
    alias TransitiveКортежТипаОснова!(B3) TL;
    assert(TL.length == 5);
    assert(is (TL[0] == B2));
    assert(is (TL[1] == B1));
    assert(is (TL[2] == Object));
    assert(is (TL[3] == I1));
    assert(is (TL[4] == I2));
    
    assert(TransitiveКортежТипаОснова!(Object).length == 0);
}

/**
Get the type that all типы can be implicitly converted to. Useful
e.g. in figuring out an массив type from a bunch of initializing
values. Returns $(D_PARAM проц) if passed an empty list, or if the
типы have no common type.

Example:

----
alias CommonType!(цел, дол, крат) X;
assert(is(X == дол));
alias CommonType!(цел, char[], крат) Y;
assert(is(Y == проц));
----
*/
template CommonType(Т...)
{
    static if (!Т.length)
        alias проц CommonType;
    else static if (Т.length == 1)
        alias Т[0] CommonType;
    else static if (is(typeof(true ? Т[0] : Т[1]) U))
        alias CommonType!(U, Т[2 .. $]) CommonType;
    else
        alias проц CommonType;
}

unittest
{
    alias CommonType!(цел, дол, крат) X;
    assert(is(X == дол));
    alias CommonType!(char[], цел, дол, крат) Y;
    assert(is(Y == проц), Y.stringof);
}

/**
 * Returns a tuple with all possible цель типы of an implicit
 * conversion of a value of type $(D_PARAM Т).
 *
 * Important note:
 *
 * The possible targets are computed more conservatively than the D
 * 2.005 compiler does, eliminating all dangerous conversions. For
 * example, $(D_PARAM ImplicitConversionTargets!(double)) does not
 * include $(D_PARAM float).
 */

template ImplicitConversionTargets(Т)
{
    static if (is(Т == бул))
        alias КортежТипа!(byte, ббайт, крат, ushort, цел, бцел, дол, ulong,
            float, double, real, char, шим, dchar)
            ImplicitConversionTargets;
    else static if (is(Т == byte))
        alias КортежТипа!(крат, ushort, цел, бцел, дол, ulong,
            float, double, real, char, шим, dchar)
            ImplicitConversionTargets;
    else static if (is(Т == ббайт))
        alias КортежТипа!(крат, ushort, цел, бцел, дол, ulong,
            float, double, real, char, шим, dchar)
            ImplicitConversionTargets;
    else static if (is(Т == крат))
        alias КортежТипа!(ushort, цел, бцел, дол, ulong,
            float, double, real)
            ImplicitConversionTargets;
    else static if (is(Т == ushort))
        alias КортежТипа!(цел, бцел, дол, ulong, float, double, real)
            ImplicitConversionTargets;
    else static if (is(Т == цел))
        alias КортежТипа!(дол, ulong, float, double, real)
            ImplicitConversionTargets;
    else static if (is(Т == бцел))
        alias КортежТипа!(дол, ulong, float, double, real)
            ImplicitConversionTargets;
    else static if (is(Т == дол))
        alias КортежТипа!(float, double, real)
            ImplicitConversionTargets;
    else static if (is(Т == ulong))
        alias КортежТипа!(float, double, real)
            ImplicitConversionTargets;
    else static if (is(Т == float))
        alias КортежТипа!(double, real)
            ImplicitConversionTargets;
    else static if (is(Т == double))
        alias КортежТипа!(real)
            ImplicitConversionTargets;
    else static if (is(Т == char))
        alias КортежТипа!(шим, dchar, byte, ббайт, крат, ushort,
            цел, бцел, дол, ulong, float, double, real)
            ImplicitConversionTargets;
    else static if (is(Т == шим))
        alias КортежТипа!(шим, dchar, крат, ushort, цел, бцел, дол, ulong,
            float, double, real)
            ImplicitConversionTargets;
    else static if (is(Т == dchar))
        alias КортежТипа!(шим, dchar, цел, бцел, дол, ulong,
            float, double, real)
            ImplicitConversionTargets;
    else static if(is(Т : Object))
        alias TransitiveКортежТипаОснова!(Т) ImplicitConversionTargets;
    else static if (is(Т : ук))
        alias КортежТипа!(ук) ImplicitConversionTargets;
    else
        alias КортежТипа!() ImplicitConversionTargets;
}

unittest
{
    assert(is(ImplicitConversionTargets!(double)[0] == real));
}

/**
 * Detect whether Т is a built-in integral type
 */

template isIntegral(Т)
{
    static const isIntegral = is(Т == byte) || is(Т == ббайт) || is(Т == крат)
        || is(Т == ushort) || is(Т == цел) || is(Т == бцел)
        || is(Т == дол) || is(Т == ulong);
}

/**
 * Detect whether Т is a built-in floating point type
 */

template isFloatingPoint(Т)
{
    static const isFloatingPoint = is(Т == float)
        || is(Т == double) || is(Т == real);
}

/**
 * Detect whether Т is a built-in numeric type
 */

template isNumeric(Т)
{
    static const isNumeric = isIntegral!(Т) || isFloatingPoint!(Т);
}

/**
 * Detect whether Т is one of the built-in string типы
 */

template isSomeString(Т)
{
    static const isSomeString = is(Т : char[])
        || is(Т : шим[]) || is(Т : dchar[]);
}

static assert(!isSomeString!(цел));
static assert(!isSomeString!(цел[]));
static assert(!isSomeString!(byte[]));
static assert(isSomeString!(char[]));
static assert(isSomeString!(dchar[]));
static assert(isSomeString!(string));
static assert(isSomeString!(wstring));
static assert(isSomeString!(dstring));
static assert(isSomeString!(char[4]));

/**
 * Detect whether Т is an associative массив type
 */

template isAssociativeArray(Т)
{
    static const бул isAssociativeArray =
        is(typeof(Т.keys)) && is(typeof(Т.values));
}

static assert(!isAssociativeArray!(цел));
static assert(!isAssociativeArray!(цел[]));
static assert(isAssociativeArray!(цел[цел]));
static assert(isAssociativeArray!(цел[string]));
static assert(isAssociativeArray!(char[5][цел]));

/**
 * Detect whether type Т is a static массив.
 */
template isStaticArray(Т : U[N], U, т_мера N)
{
    const бул isStaticArray = true;
}

template isStaticArray(Т)
{
    const бул isStaticArray = false;
}

static assert (isStaticArray!(цел[51]));
static assert (isStaticArray!(цел[][2]));
static assert (isStaticArray!(char[][цел][11]));
static assert (!isStaticArray!(цел[]));
static assert (!isStaticArray!(цел[char]));
static assert (!isStaticArray!(цел[1][]));
static assert(isStaticArray!(char[13u]));
static assert (isStaticArray!(typeof("string literal")));
static assert (isStaticArray!(проц[0]));
static assert (!isStaticArray!(цел[цел]));
static assert (!isStaticArray!(цел));

/**
 * Detect whether type Т is a dynamic массив.
 */
template isDynamicArray(Т, U = void)
{
    static const isDynamicArray = false;
}

template isDynamicArray(Т : U[], U)
{
  static const isDynamicArray = !isStaticArray!(Т);
}

static assert(isDynamicArray!(цел[]));
static assert(!isDynamicArray!(цел[5]));

/**
 * Detect whether type Т is an массив.
 */
template isArray(Т)
{
    static const isArray = isStaticArray!(Т) || isDynamicArray!(Т);
}

static assert(isArray!(цел[]));
static assert(isArray!(цел[5]));
static assert(!isArray!(бцел));
static assert(!isArray!(бцел[бцел]));
static assert(isArray!(проц[]));


/**
 * Tells whether the tuple Т is an expression tuple.
 */
template isExpressionTuple(Т ...)
{
    static if (is(проц function(Т)))
	const бул isExpressionTuple = false;
    else
	const бул isExpressionTuple = true;
}

/**
 * Returns the corresponding unsigned type for Т. Т must be a numeric
 * integral type, otherwise a compile-time error occurs.
 */

template unsigned(Т) {
    static if (is(Т == byte)) alias ббайт unsigned;
    else static if (is(Т == крат)) alias ushort unsigned;
    else static if (is(Т == цел)) alias бцел unsigned;
    else static if (is(Т == дол)) alias ulong unsigned;
    else static if (is(Т == ббайт)) alias ббайт unsigned;
    else static if (is(Т == ushort)) alias ushort unsigned;
    else static if (is(Т == бцел)) alias бцел unsigned;
    else static if (is(Т == ulong)) alias ulong unsigned;
    else static if (is(Т == char)) alias char unsigned;
    else static if (is(Т == шим)) alias шим unsigned;
    else static if (is(Т == dchar)) alias dchar unsigned;
    else static if(is(Т == enum)) {
        static if (Т.sizeof == 1) alias ббайт unsigned;
        else static if (Т.sizeof == 2) alias ushort unsigned;
        else static if (Т.sizeof == 4) alias бцел unsigned;
        else static if (Т.sizeof == 8) alias ulong unsigned;
        else static assert(false, "Type " ~ Т.stringof
                           ~ " does not have an unsigned counterpart");
    }
    else static assert(false, "Type " ~ Т.stringof
                       ~ " does not have an unsigned counterpart");
}

unittest
{
    alias unsigned!(цел) U;
    assert(is(U == бцел));
}

/******
 * Returns the mutable version of the type Т.
 */

template Mutable(Т)
{
/+
    static if (is(Т U == const(U)))
	alias U Mutable;
    else static if (is(Т U == invariant(U)))
	alias U Mutable;
    else
+/
	alias Т Mutable;
}

/**
Returns the most negative value of the numeric type Т.
*/

template mostNegative(Т)
{
    static if (Т.min == 0) const byte mostNegative = 0;
    else static if (Т.min > 0) const mostNegative = -Т.max;
    else const mostNegative = Т.min;
}

unittest
{
    static assert(mostNegative!(float) == -float.max);
    static assert(mostNegative!(бцел) == 0);
    static assert(mostNegative!(дол) == дол.min);
}
+/


/**
 * Оценивается как true, если Т является char[], wchar[] или dchar[].
 */
template текстТип_ли( Т )
{
    const bool текстТип_ли = is( Т : char[] )  ||
                              is( Т : wchar[] ) ||
                              is( Т : dchar[] ) ||
							  is( Т : сим[] )  ||
                              is( Т : шим[] ) ||
                              is( Т : дим[] );
}

/**
 * Evaluates to true if Т is char, wchar, or dchar.
 */
template симТип_ли( Т )
{
    const bool симТип_ли = is( Т == char )  ||
                            is( Т == wchar ) ||
                            is( Т == dchar ) ||
							is( Т == сим )  ||
                            is( Т == шим ) ||
                            is( Т == дим );
}


/**
 * Evaluates to true if Т is a signed integer type.
 */
template целСоЗнакомТип_ли( Т )
{
    const bool целСоЗнакомТип_ли = is( Т == byte )  ||
                                     is( Т == short ) ||
                                     is( Т == int )   ||
                                     is( Т == long ) ||
									 is( Т == байт )  ||
                                     is( Т == крат ) ||
                                     is( Т == цел )   ||
                                     is( Т == дол ) 
									 /+||
                                     is( Т == cent  )+/;
}


/**
 * Evaluates to true if Т is an unsigned integer type.
 */
template целБезЗнакаТип_ли( Т )
{
    const bool целБезЗнакаТип_ли = is( Т == ubyte )  ||
                                       is( Т == ushort ) ||
                                       is( Т == uint )   ||
                                       is( Т == ulong ) ||
									   is( Т == ббайт )  ||
                                       is( Т == бкрат ) ||
                                       is( Т == бцел )   ||
                                       is( Т == бдол ) 
									   /+||
                                       is( Т == ucent  )+/;
}


/**
 * Evaluates to true if Т is a signed or unsigned integer type.
 */
template целТип_ли( Т )
{
    const bool целТип_ли = целСоЗнакомТип_ли!(Т) ||
                               целБезЗнакаТип_ли!(Т);
}


/**
 * Evaluates to true if Т is a real floating-point type.
 */
template реалТип_ли( Т )
{
    const bool реалТип_ли = is( Т == float )  ||
                            is( Т == double ) ||
                            is( Т == real ) ||
							is( Т == плав )  ||
                            is( Т == дво ) ||
                            is( Т == реал );
}


/**
 * Evaluates to true if Т is a complex floating-point type.
 */
template комплексТип_ли( Т )
{
    const bool комплексТип_ли = is( Т == cfloat ) ||
                               is( Т == cdouble ) ||
                               is( Т == creal )||
							   is( Т == кплав ) ||
                               is( Т == кдво ) ||
                               is( Т == креал );
}


/**
 * Evaluates to true if Т is an imaginary floating-point type.
 */
template мнимыйТип_ли( Т )
{
    const bool мнимыйТип_ли = is( Т == ifloat )  ||
                                 is( Т == idouble ) ||
                                 is( Т == ireal )||
								 is( Т == вплав )  ||
                                 is( Т == вдво ) ||
                                 is( Т == вреал )	;
}


/**
 * Evaluates to true if Т is any floating-point type: real, complex, or
 * imaginary.
 */
template плавзапТип_ли( Т )
{
    const bool плавзапТип_ли = реалТип_ли!(Т)    ||
                                     комплексТип_ли!(Т) ||
                                     мнимыйТип_ли!(Т);
}

/// true if Т is an atomic type
template атомТип_ли(Т)
{
    static if( is( Т == bool )
            || is( Т == char )
            || is( Т == wchar )
            || is( Т == dchar )
            || is( Т == byte )
            || is( Т == short )
            || is( Т == int )
            || is( Т == long )
            || is( Т == ubyte )
            || is( Т == ushort )
            || is( Т == uint )
            || is( Т == ulong )
            || is( Т == float )
            || is( Т == double )
            || is( Т == real )
            || is( Т == ifloat )
            || is( Т == idouble )
            || is( Т == ireal )
			||is( Т == бул )
            || is( Т == сим )
            || is( Т == шим )
            || is( Т == дим )
            || is( Т == байт )
            || is( Т == крат )
            || is( Т == цел )
            || is( Т == дол )
            || is( Т == ббайт )
            || is( Т == бкрат )
            || is( Т == бцел )
            || is( Т == бдол )
            || is( Т == плав )
            || is( Т == дво )
            || is( Т == реал )
            || is( Т == вплав )
            || is( Т == вдво )
            || is( Т == вреал ))
        const атомТип_ли = true;
    else
        const атомТип_ли = false;
}

/**
 * complex type for the given type
 */
template ComplexTypeOf(Т){
    static if(is(Т==float)||is(Т==ifloat)||is(Т==cfloat)){
        alias cfloat ComplexTypeOf;
    } else static if(is(Т==double)|| is(Т==idouble)|| is(Т==cdouble)){
        alias cdouble ComplexTypeOf;
    } else static if(is(Т==real)|| is(Т==ireal)|| is(Т==creal)){
        alias creal ComplexTypeOf;
    } else static assert(0,"unsupported type in ComplexTypeOf "~Т.stringof);
}

/**
 * real type for the given type
 */
template RealTypeOf(Т){
    static if(is(Т==float)|| is(Т==ifloat)|| is(Т==cfloat)){
        alias float RealTypeOf;
    } else static if(is(Т==double)|| is(Т==idouble)|| is(Т==cdouble)){
        alias double RealTypeOf;
    } else static if(is(Т==real)|| is(Т==ireal)|| is(Т==creal)){
        alias real RealTypeOf;
    } else static assert(0,"unsupported type in RealTypeOf "~Т.stringof);
}

/**
 * imaginary type for the given type
 */
template ImaginaryTypeOf(Т){
    static if(is(Т==float)|| is(Т==ifloat)|| is(Т==cfloat)){
        alias ifloat ImaginaryTypeOf;
    } else static if(is(Т==double)|| is(Т==idouble)|| is(Т==cdouble)){
        alias idouble ImaginaryTypeOf;
    } else static if(is(Т==real)|| is(Т==ireal)|| is(Т==creal)){
        alias ireal ImaginaryTypeOf;
    } else static assert(0,"unsupported type in ImaginaryTypeOf "~Т.stringof);
}

/// type with maximum precision
template MaxPrecTypeOf(Т){
    static if (комплексТип_ли!(Т)){
        alias creal MaxPrecTypeOf;
    } else static if (мнимыйТип_ли!(Т)){
        alias ireal MaxPrecTypeOf;
    } else {
        alias real MaxPrecTypeOf;
    }
}


/**
 * Evaluates to true if Т is a pointer type.
 */
template типУказатель_ли(Т)
{
        const типУказатель_ли = false;
}

template типУказатель_ли(Т : Т*)
{
        const типУказатель_ли = true;
}

debug( UnitTest )
{
    unittest
    {
        static assert( типУказатель_ли!(void*) );
        static assert( !типУказатель_ли!(char[]) );
        static assert( типУказатель_ли!(char[]*) );
        static assert( !типУказатель_ли!(char*[]) );
        static assert( типУказатель_ли!(real*) );
        static assert( !типУказатель_ли!(uint) );
        static assert( is(MaxPrecTypeOf!(float)==real));
        static assert( is(MaxPrecTypeOf!(cfloat)==creal));
        static assert( is(MaxPrecTypeOf!(ifloat)==ireal));

        class Ham
        {
            void* a;
        }

        static assert( !типУказатель_ли!(Ham) );

        union Eggs
        {
            void* a;
            uint  b;
        };

        static assert( !типУказатель_ли!(Eggs) );
        static assert( типУказатель_ли!(Eggs*) );

        struct Bacon {};

        static assert( !типУказатель_ли!(Bacon) );

    }
}

/**
 * Evaluates to true if Т is a a pointer, class, interface, or delegate.
 */
template типСсылка_ли( Т )
{

    const bool типСсылка_ли = типУказатель_ли!(Т)  ||
                               is( Т == class )     ||
                               is( Т == interface ) ||
                               is( Т == delegate );
}


/**
 * Evaulates to true if Т is a dynamic array type.
 */
template типДинМасс_ли( Т )
{
    const bool типДинМасс_ли = is( typeof(Т.init[0])[] == Т );
}

/**
 * Evaluates to true if Т is a static array type.
 */
version( GNU )
{
    // GDC should also be able to use the other version, but it probably
    // relies on a frontend fix in one of the latest DMD versions - will
    // remove this when GDC is ready. For now, this code pass the unittests.
    private template isStaticArrayTypeInst( Т )
    {
        const Т isStaticArrayTypeInst = void;
    }

    template типСтатМасс_ли( Т )
    {
        static if( is( typeof(Т.length) ) && !is( typeof(Т) == typeof(Т.init) ) )
        {
            const bool типСтатМасс_ли = is( Т == typeof(Т[0])[isStaticArrayTypeInst!(Т).length] );
        }
        else
        {
            const bool типСтатМасс_ли = false;
        }
    }
}
else
{
    template типСтатМасс_ли( Т : Т[U], size_t U )
    {
        const bool типСтатМасс_ли = true;
    }

    template типСтатМасс_ли( Т )
    {
        const bool типСтатМасс_ли = false;
    }
}

/// true for array types
template типМассив_ли(Т)
{
    static if (is( Т U : U[] ))
        const bool типМассив_ли=true;
    else
        const bool типМассив_ли=false;
}

debug( UnitTest )
{
    unittest
    {
        static assert( типСтатМасс_ли!(char[5][2]) );
        static assert( !типДинМасс_ли!(char[5][2]) );
        static assert( типМассив_ли!(char[5][2]) );

        static assert( типСтатМасс_ли!(char[15]) );
        static assert( !типСтатМасс_ли!(char[]) );

        static assert( типДинМасс_ли!(char[]) );
        static assert( !типДинМасс_ли!(char[15]) );

        static assert( типМассив_ли!(char[15]) );
        static assert( типМассив_ли!(char[]) );
        static assert( !типМассив_ли!(char) );
    }
}

/**
 * Evaluates to true if Т is an associative array type.
 */
template типАссоцМасс_ли( Т )
{
    const bool типАссоцМасс_ли = is( typeof(Т.init.values[0])[typeof(Т.init.keys[0])] == Т );
}


/**
 * Evaluates to true if Т is a function, function pointer, delegate, or
 * callable object.
 */
template isCallableType( Т )
{
    const bool isCallableType = is( Т == function )             ||
                                is( typeof(*Т) == function )    ||
                                is( Т == delegate )             ||
                                is( typeof(Т.opCall) == function );
}


/**
 * Evaluates to the return type of Fn.  Fn is required to be a callable type.
 */
template ТипВозвратаУ( Fn )
{
    static if( is( Fn Ret == return ) )
        alias Ret ТипВозвратаУ;
    else
        static assert( false, "Аргумент не имеет типа возврата." );
}

/** 
 * Returns the type that a Т would evaluate to in an expression.
 * Expr is not required to be a callable type
 */ 
template ExprTypeOf( Expr )
{
    static if(isCallableType!( Expr ))
        alias ТипВозвратаУ!( Expr ) ExprTypeOf;
    else
        alias Expr ExprTypeOf;
}


/**
 * Evaluates to the return type of fn.  fn is required to be callable.
 */
template ТипВозвратаУ( alias fn )
{
    static if( is( typeof(fn) Основа == typedef ) )
        alias ТипВозвратаУ!(Основа) ТипВозвратаУ;
    else
        alias ТипВозвратаУ!(typeof(fn)) ТипВозвратаУ;
}


/**
 * Evaluates to a tuple representing the parameters of Fn.  Fn is required to
 * be a callable type.
 */
template КортежПараметровУ( Fn )
{
    static if( is( Fn Params == function ) )
        alias Params КортежПараметровУ;
    else static if( is( Fn Params == delegate ) )
        alias КортежПараметровУ!(Params) КортежПараметровУ;
    else static if( is( Fn Params == Params* ) )
        alias КортежПараметровУ!(Params) КортежПараметровУ;
    else
        static assert( false, "У аргумента отсутствуют параметры." );
}


/**
 * Evaluates to a tuple representing the parameters of fn.  n is required to
 * be callable.
 */
template КортежПараметровУ( alias fn )
{
    static if( is( typeof(fn) Основа == typedef ) )
        alias КортежПараметровУ!(Основа) КортежПараметровУ;
    else
        alias КортежПараметровУ!(typeof(fn)) КортежПараметровУ;
}


/**
 * Evaluates to a tuple representing the ancestors of Т.  Т is required to be
 * a class or interface type.
 */
template КортежТиповОсновУ( Т )
{
    static if( is( Т Основа == super ) )
        alias Основа КортежТиповОсновУ;
    else
        static assert( false, "Аргумент не является ни классом, ни интерфейсом." );
}

/**
 * Strips the []'s off of a type.
 */
template ТипОсноваМассивов(Т)
{
    static if( is( Т S : S[]) ) {
        alias ТипОсноваМассивов!(S)  ТипОсноваМассивов;
    }
    else {
        alias Т ТипОсноваМассивов;
    }
}

/**
 * strips one [] off a type
 */
template ТипЭлементовМассива(Т:Т[])
{
    alias Т ТипЭлементовМассива;
}

/**
 * Count the []'s on an array type
 */
template рангМассива(Т) {
    static if(is(Т S : S[])) {
        const uint рангМассива = 1 + рангМассива!(S);
    } else {
        const uint рангМассива = 0;
    }
}

/// type of the keys of an AA
template ТипКлючаАМ(Т){
    alias typeof(Т.init.keys[0]) ТипКлючаАМ;
}

/// type of the values of an AA
template ТипЗначенияАМ(Т){
    alias typeof(Т.init.values[0]) ТипЗначенияАМ;
}

/// returns the size of a static array
template размерСтатМассива(Т)
{
    static assert(типСтатМасс_ли!(Т),"размерСтатМассива требует указать статический массив в качестве типа");
    static assert(рангМассива!(Т)==1,"реализовано только для массивов 1d...");
    const size_t размерСтатМассива=(Т).sizeof / typeof(Т.init).sizeof;
}

/// is Т is static array returns a dynamic array, otherwise returns Т
template ТипДинМас(Т)
{
    static if( типСтатМасс_ли!(Т) )
        alias typeof(Т.dup) ТипДинМас;
    else
        alias Т ТипДинМас;
}

debug( UnitTest )
{
    static assert( is(ТипОсноваМассивов!(real[][])==real) );
    static assert( is(ТипОсноваМассивов!(real[2][3])==real) );
    static assert( is(ТипЭлементовМассива!(real[])==real) );
    static assert( is(ТипЭлементовМассива!(real[][])==real[]) );
    static assert( is(ТипЭлементовМассива!(real[2][])==real[2]) );
    static assert( is(ТипЭлементовМассива!(real[2][2])==real[2]) );
    static assert( рангМассива!(real[][])==2 );
    static assert( рангМассива!(real[2][])==2 );
    static assert( is(ТипЗначенияАМ!(char[int])==char));
    static assert( is(ТипКлючаАМ!(char[int])==int));
    static assert( is(ТипЗначенияАМ!(char[][int])==char[]));
    static assert( is(ТипКлючаАМ!(char[][int[]])==int[]));
    static assert( типАссоцМасс_ли!(char[][int[]]));
    static assert( !типАссоцМасс_ли!(char[]));
    static assert( is(ТипДинМас!(char[2])==ТипДинМас!(char[])));
    static assert( is(ТипДинМас!(char[2])==char[]));
    static assert( размерСтатМассива!(char[2])==2);
}


