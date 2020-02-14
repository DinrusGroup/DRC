
// Написано на языке программирования Динрус. Разработчик Виталий Кулич.

/**
 * Templates with which to extract information about
 * types at compile time.
 *
 * Macros:
 *	WIKI = Phobos/StdTraits
 * Copyright:
 *	Public Domain
 */

/*
 * Authors:
 *	Walter Bright, Digital Mars, www.digitalmars.com
 *	Tomasz Stachowiak (isStaticArray, isExpressionTuple)
 */

module std.traits;

/***
 * Get the type of the return value from a function,
 * a pointer to function, or a delegate.
 * Example:
 * ---
 * import std.traits;
 * int foo();
 * ReturnType!(foo) x;   // x is declared as int
 * ---
 */
template ReturnType(alias дг)
{
    alias ReturnType!(typeof(дг)) ReturnType;
}

/** ditto */
template ReturnType(дг)
{
    static if (is(дг R == return))
	alias R ReturnType;
    else
	static assert(0, "argument has no return type");
}

/***
 * Get the types of the paramters to a function,
 * a pointer to function, or a delegate as a tuple.
 * Example:
 * ---
 * import std.traits;
 * int foo(int, long);
 * void bar(КортежТипаПараметров!(foo));      // declares void bar(int, long);
 * void abc(КортежТипаПараметров!(foo)[1]);   // declares void abc(long);
 * ---
 */
template КортежТипаПараметров(alias дг)
{
    alias КортежТипаПараметров!(typeof(дг)) КортежТипаПараметров;
}

/** ditto */
template КортежТипаПараметров(дг)
{
    static if (is(дг P == function))
	alias P КортежТипаПараметров;
    else static if (is(дг P == delegate))
	alias КортежТипаПараметров!(P) КортежТипаПараметров;
    else static if (is(дг P == P*))
	alias КортежТипаПараметров!(P) КортежТипаПараметров;
    else
	static assert(0, "argument has no parameters");
}


/***
 * Get the types of the fields of a struct or class.
 * This consists of the fields that take up memory space,
 * excluding the hidden fields like the virtual function
 * table pointer.
 */

template FieldTypeTuple(S)
{
    static if (is(S == struct) || is(S == class))
	alias typeof(S.tupleof) FieldTypeTuple;
    else
	static assert(0, "argument is not struct or class");
}


/***
 * Get a КортежТипа of the base class and base interfaces of
 * this class or interface.
 * Example:
 * ---
 * import std.traits, std.typetuple, std.io;
 * interface I { }
 * class A { }
 * class B : A, I { }
 *
 * void main()
 * {
 *     alias BaseTypeTuple!(B) TL;
 *     writefln(typeid(TL));	// prints: (A,I)
 * }
 * ---
 */

template BaseTypeTuple(A)
{
    static if (is(A P == super))
	alias P BaseTypeTuple;
    else
	static assert(0, "argument is not a class or interface");
}

unittest
{
    interface I { }
    class A { }
    class B : A, I { }

    alias BaseTypeTuple!(B) TL;
    assert(TL.length == 2);
    assert(is (TL[0] == A));
    assert(is (TL[1] == I));
}

/* *******************************************
 */
template isStaticArray_impl(T)
{
    const T inst = void;
    
    static if (is(typeof(T.length)))
    {
	static if (!is(T == typeof(T.init)))
	{			// abuses the fact that int[5].init == int
	    static if (is(T == typeof(T[0])[inst.length]))
	    {	// sanity check. this check alone isn't enough because dmd complains about dynamic arrays
		const bool res = true;
	    }
	    else
		const bool res = false;
	}
	else
	    const bool res = false;
    }
    else
    {
	    const bool res = false;
    }
}
/**
 * Detect whether type T is a static array.
 */
template isStaticArray(T)
{
    const bool isStaticArray = isStaticArray_impl!(T).res;
}


static assert (isStaticArray!(int[51]));
static assert (isStaticArray!(int[][2]));
static assert (isStaticArray!(char[][int][11]));
static assert (!isStaticArray!(int[]));
static assert (!isStaticArray!(int[char]));
static assert (!isStaticArray!(int[1][]));

/**
 * Tells whether the tuple T is an expression tuple.
 */
template isExpressionTuple(T ...)
{
    static if (is(void function(T)))
	const bool isExpressionTuple = false;
    else
	const bool isExpressionTuple = true;
}



