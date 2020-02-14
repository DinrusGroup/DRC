// Написано на языке программирования Динрус

/**
 * Привязка аргументов к функции.
 *
 * References:
 *	$(LINK2 http://www.boost.org/libs/привяжи/привяжи.html, boost::привяжи)	
 * Authors: Tomasz Stachowiak
 * Date: November 28, 2006
 * Macros:
 *	WIKI = Phobos/StdBind
 * Copyright:
 *	Public Domain
 */
module tpl.bind;


import stdrus:форматируй;
import tpl.traits;
import tpl.typetuple;





struct ДинАрг(цел i) {
	static assert (i >= 0);
	
	alias i аргНом;
}


/**
	При передаче функции 'привяжи' будут обозначать динамические параметры: те, что не связаны статически.
	В boost'е они называются __1, __2, __3 и т.д. Здесь: __0, __1, __2, ...
*/
const ДинАрг!(0) _0;
const ДинАрг!(1) _1;		/// описано ранее
const ДинАрг!(2) _2;		/// описано ранее
const ДинАрг!(3) _3;		/// описано ранее
const ДинАрг!(4) _4;		/// описано ранее
const ДинАрг!(5) _5;		/// описано ранее
const ДинАрг!(6) _6;		/// описано ранее
const ДинАрг!(7) _7;		/// описано ранее
const ДинАрг!(8) _8;		/// описано ранее
const ДинАрг!(9) _9;		/// описано ранее



/*
	Выявить, есть ли данный тип ДинАрг с любым индексом
*/
template динАрг_ли(T) {
	static if (is(typeof(T.аргНом))) {			
		static if(is(T : ДинАрг!(T.аргНом))) {		
			static const бул динАрг_ли =да;
		} else static const бул динАрг_ли = нет;
	} else static const бул динАрг_ли = нет;
}


/*
	Выявить, есть ли данный тип ДинАрг с указанным индексом
*/
template динАрг_ли(T, цел i) {
	static const бул динАрг_ли = is(T : ДинАрг!(i));
}


/*
	Преобразовать из типа статического массива в тип динамического массива
*/
template ТипДинМас(T) {
	alias typeof(T[0])[] ТипДинМас;
}


/*
	Присваивает одну сущность другой. Так как статические массивы не поддерживают нормального присваивания, то к ним применяется присваивание среза.
	
	Парамы:
		a = приёмник
		b = источник
*/
template _присвой(T) {
	static if (статМас_ли!(T)) {
		проц _присвой(ТипДинМас!(T) a, ТипДинМас!(T) b) {
			a[] = b[];
		}
	} else {
		проц _присвой(inout T a, inout T b) {
			a = b;
		}
	}
}


/*
	Присваивает и потенциально преобразует одну сущность в другую.
	
	Как правило, используются только косвенные преобразования, но когда оба операнда числовых типов, то над ними прозводится явное приведение к типу.
	
	Парамы:
		T = тип приёмника
		a = приёмник
		Y = тип источника
		b = источник
		copyStaticArrays = когда статический массив присваивается динамическому, иногда требуется его дублирование, так как хранилище может быть в "волатильных" местах...
*/
template _присвой(T, Y, бул копироватьСтатМас =да) {
	static if (статМас_ли!(T)) {
		
		// если приёмник - статический массив, то каждый элемент копируется из источника с помощью foreach
		проц _присвой(ТипДинМас!(T) a, ТипДинМас!(Y) b) {
			foreach (i, x; b) {
				_присвой!(typeof(a[i]), typeof(x))(a[i], x);
			}
		}
	} else static if (!статМас_ли!(T) && статМас_ли!(Y)) {
		
		// приёмник - динамический массив, а источник - статический. Порой здесь нужен .dup
		проц _присвой(inout T a, ТипДинМас!(Y) b) {
			static if (копироватьСтатМас) {
				a = b.dup;
			} else {
				a = b;
			}
		}
	} else {
		
		// ни один из элементом не является статическим массивом
		проц _присвой(inout T a, inout Y b) {
			static if (Индекс_у!(T, ЧисловыеТипы.тип) != -1 && Индекс_у!(Y, ЧисловыеТипы.тип) != -1) {
				a = cast(T)b;
			} else {
				a = b;
			}
		}
	}
}



/**
	Простая структура-кортеж с некоторыми основными операциями
*/
struct Кортеж(T ...) {
	alias Кортеж	meta;
	const бул	кортежВыражений = кортежВыражений_ли!(T);
	
	static if (!кортежВыражений) {
		alias T	тип;		// встроенный кортеж
		T			значение;		// экземпляр встроенного кортежа
	} else {
		alias T	значение;
	}
	
	
	const цел length = значение.length;
	

	/**
		Statically yields a кортеж тип with an extra element added at its end
	*/
	template добавьТ(X) {
		alias .Кортеж!(T, X) добавьТ;
	}


	/**
		Yields a кортеж with an extra element added at its end
	*/
	добавьТ!(X) добавь(X)(X x) {
		добавьТ!(X) рез;
		foreach (i, y; значение) {
			_присвой!(typeof(y))(рез.значение[i], y);
		}
		_присвой!(typeof(x))(рез.значение[$-1], x);
		return рез;
	}
	
	
	/**
		Statically yields a кортеж тип with an extra element added at its beginning
	*/
	template приставьТ(X) {
		alias .Кортеж!(X, T) приставьТ;
	}


	/**
		Yields a кортеж with an extra element added at its beginning
	*/
	приставьТ!(X) приставь(X)(X x) {
		приставьТ!(X) рез;
		foreach (i, y; значение) {
			_присвой!(typeof(y))(рез.значение[i+1], y);
		}
		_присвой!(typeof(x))(рез.значение[0], x);
		return рез;
	}
	
	
	/**
		Statically concatenates this кортеж тип with another кортеж тип
	*/
	template конкатенируйТ(T ...) {
		static if (кортежВыражений) {
			alias .Кортеж!(значение, T) конкатенируйТ;
		} else {
			alias .Кортеж!(тип, T) конкатенируйТ;
		}
	}
	
	
	ткст вТкст() {
		auto рез = "(" ~ форматируй(значение[0]);
		foreach (x; значение[1..$]) {
			рез ~= форматируй(", ", x);
		}
		return рез ~ ")";
	}
}


/**
	An empty кортеж struct
*/
struct Кортеж() {
	alias Кортеж					meta;

	template ПустойКортеж_(T ...) {
		alias T ПустойКортеж_;
	}
	

	alias ПустойКортеж_!()	тип;		/// an empty built-in кортеж
	alias ПустойКортеж_!()	значение;		/// an empty built-in кортеж
	
	const бул	кортежВыражений = нет;	
	const цел	length = 0;


	template добавьТ(X) {
		alias .Кортеж!(X) добавьТ;
	}
	alias добавьТ приставьТ;


	добавьТ!(X) добавь(X)(X x) {
		добавьТ!(X) рез;
		foreach (i, y; значение) {
			_присвой!(typeof(y))(рез.значение[i], y);
		}
		return рез;
	}
	alias добавь приставь;
	
	
	// T - other кортеж
	template конкатенируйТ(T ...) {
		alias .Кортеж!(T) конкатенируйТ;
	}
	
	
	сим[] вТкст() {
		return "()";
	}
}


/**
	Dynamically создай a кортеж from the given items
*/
Кортеж!(T) кортеж(T ...)(T t) {
	Кортеж!(T) рез;
	foreach (i, x; t) {
		_присвой!(typeof(x))(рез.значение[i], x);
	}
	return рез;
}


/**
	Checks whether a given тип is the Кортеж struct of any length
*/
template типКортеж_ли(T) {
	static if (is(T.тип)) {
		static if (is(T == Кортеж!(T.тип))) {
			const бул типКортеж_ли =да;
		} else const бул типКортеж_ли = нет;
	} else const бул типКортеж_ли = нет;
}

static assert(типКортеж_ли!(Кортеж!(цел)));
static assert(типКортеж_ли!(Кортеж!(float, сим)));
static assert(типКортеж_ли!(Кортеж!(double, float, цел, сим[])));
static assert(типКортеж_ли!(Кортеж!(Object, creal, дол)));
static assert(!типКортеж_ли!(Object));
static assert(!типКортеж_ли!(цел));




template minNumArgs_impl(alias fn, fnT) {
	alias КортежТипаПараметр!(fnT) Парамы;
	Парамы парамы = void;
	
	template цикл(цел i = 0) {
		static assert (i <= Парамы.length);
		
		static if (is(typeof(fn(парамы[0..i])))) {
			const цел рез = i;
		} else {
			alias цикл!(i+1).рез рез;
		}
	}
	
	alias цикл!().рез рез;
}
/**
	Найти минимальное число аргументов, к-е д. б. представлено данной функции
*/
template минЧлоАргов(alias fn, fnT = typeof(&fn)) {
	const цел минЧлоАргов = minNumArgs_impl!(fn, fnT).рез;
}


// mixed into СвязаннаяФункц struct/class
template СФункцСвязки() {
	// meta
	alias FAlias_													АлиасФ;
	alias FT															ТипФункц;
	alias AllBoundArgs_										ВсеСвязанныеАрги;		// all arguments given to привяжи() or привяжиАлиас()
	
	static if (!is(typeof(АлиасФ) == ПустойСлот)) {
		alias Кортеж!(КортежТипаПараметр!(FT))				RealFuncParams;	// the parameters of the bound function
		alias СсылПарамыФункцВВидеУков!(АлиасФ)	ПарамыФункц;			// references converted to pointers
	} else {
		alias Кортеж!(КортежТипаПараметр!(FT))			ПарамыФункц;			// the parameters of the bound function
	}
	
	alias ВозврТип!(FT)										ВозврТип;				// the return тип of the bound function
	alias ИзвлечённыеСвязанныеАрги!(ВсеСвязанныеАрги.тип)	СвязанныеАрги;			// 'saved' arguments. this includes nested/composed functions
	
	
	// if привяжиАлиас was used, we can detect default arguments and only demand the non-default arguments to be specified
	static if (!is(typeof(АлиасФ) == ПустойСлот)) {
		const цел минАрговФции = минЧлоАргов!(АлиасФ);
		
		alias КортежМетодовПередачиПараметров!(АлиасФ)			ParamPassingMethods;	// find out whether the function expects parameters by значение or reference
	} else {
		const цел минАрговФции = ПарамыФункц.length;
	}
	
	// the parameters that our wrapper function must дай
	alias дайТипыДинАргов!(ПарамыФункц, ВсеСвязанныеАрги, минАрговФции).рез.тип	ДинПарамы;
	
	// data
	ТипФункц			fp;
	СвязанныеАрги		связанныеАрги;

	// yields the number of bound-function parameters that are covered by the binding. takes кортеж expansion into account
	template члоДействитСвязанныхАрговФций(цел argI = 0, цел fargI = 0, цел bargI = 0) {
		
		// walk though all of ВсеСвязанныеАрги
		static if (argI < ВсеСвязанныеАрги.length) {
			
			// the argI-th арг is a composed/nested function
			static if (функцСвязки_ли!(ВсеСвязанныеАрги.тип[argI])) {
				alias ДерефФункц!(ВсеСвязанныеАрги.тип[argI]).ВозврТип		ТипВозвратаФункц;
				const цел argLen = дайДлинуАрга!(ПарамыФункц.тип[fargI], ТипВозвратаФункц);
				const цел bargInc = 1;
			}
			
			// the argI-th арг is a dynamic argument whose значение we will дай in the вызови to func()
			else static if (динАрг_ли!(ВсеСвязанныеАрги.тип[argI])) {
				const цел argLen = дайДлинуАрга!(ПарамыФункц.тип[fargI], ДинПарамы[ВсеСвязанныеАрги.тип[argI].аргНом]);
				const цел bargInc = 0;
			}
			
			// the argI-th арг is a statically bound argument
			else {
				const цел argLen = дайДлинуАрга!(ПарамыФункц.тип[fargI], СвязанныеАрги.тип[bargI]);
				const цел bargInc = 1;
			}
			
			// iterate
			const цел рез = члоДействитСвязанныхАрговФций!(argI+1, fargI+argLen, bargI+bargInc).рез;
		} else {
			// last iteration
			
			// the number of bound args is the number of arguments we've detected in this template цикл
			const цел рез = fargI;

			// make sure we'll copy all args the function is going to need
			static assert (рез >= минАрговФции);
		}
	}
	
	const цел члоУказанныхПарамов = члоДействитСвязанныхАрговФций!().рез;
	
	// it's a кортеж тип whose instance will be applied to the bound function
	alias Кортеж!(ПарамыФункц.тип[0 .. члоУказанныхПарамов])	УказанныеПараметры;
	

	// argI = indexes ВсеСвязанныеАрги
	// fargI = indexes funcArgs
	// bargI = indexes связанныеАрги
	проц копируйАрги(цел argI = 0, цел fargI = 0, цел bargI = 0)(inout УказанныеПараметры funcArgs, ДинПарамы динАрги) {
		static if (argI < ВсеСвязанныеАрги.length) {

			// the argI-th арг is a composed/nested function
			static if (функцСвязки_ли!(ВсеСвязанныеАрги.тип[argI])) {
				alias ДерефФункц!(ВсеСвязанныеАрги.тип[argI]).ВозврТип		ТипВозвратаФункц;
				alias ДерефФункц!(ВсеСвязанныеАрги.тип[argI]).ДинПарамы	ДинПарамыФункц;
				
				// if ДинПарамыФункц contains an empty slot, e.g. as in the case  привяжи(&f, привяжи(&g, _1), _0)
				// then we cannot just apply the динАрги кортеж to the nested/composed function because it will have ПустойСлот парамы
				// while our динАрги кортеж will contain ordinary types
				static if (СодержитТипПустойСлот!(ДинПарамыФункц)) {
					
					ДинПарамыФункц funcParams;	// we'll fill it with values in a bit
					
					foreach (i, dummy_; динАрги) {
						static if (!is(typeof(ДинПарамыФункц[i] == ПустойСлот))) {
							
							// 3rd param is нет because there is no need to .dup static arrays just for the function below this foreach
							// the storage exists in the whole копируйАрги function
							// динАрги[i] is used instead of dummy_ so that цикл-local data isn't referenced in any dynamic arrays after the цикл
							_присвой!(typeof(funcParams[i]), typeof(dummy_), нет)(funcParams[i], динАрги[i]);
						}
					}
					
					ТипВозвратаФункц funcRet = связанныеАрги.значение[bargI].func(funcParams);
				} else {
					ТипВозвратаФункц funcRet = связанныеАрги.значение[bargI].func(динАрги[0..ДинПарамыФункц.length]);	// only give it as many dynParams as it needs
				}
				
				// we'll take data from the returned значение
				auto srcItem = &funcRet;
				
				const цел bargInc = 1;							// nested/composed functions belong to the связанныеАрги кортеж
				const бул dupStaticArrays =да;		// because the function's return значение is stored locally
			}

			// the argI-th арг is a dynamic argument whose значение we will дай in the вызови to func()
			else static if (динАрг_ли!(ВсеСвязанныеАрги.тип[argI])) {
				
				// we'll take data from динАрги
				auto srcItem = &динАрги[ВсеСвязанныеАрги.тип[argI].аргНом];
				
				const цел bargInc = 0;							// dynamic args don't belond to the связанныеАрги кортеж
				const бул dupStaticArrays =да;		// because we дай динАрги on stack
			}
			
			// the argI-th арг is a statically bound argument
			else {
				
				// we'll take data directly from связанныеАрги
				auto srcItem = &связанныеАрги.значение[bargI];
				
				const цел bargInc = 1;							// statically bound args belong to the связанныеАрги кортеж
				const бул dupStaticArrays = нет;		// because the storage exists in связанныеАрги
			}

			// the number of bound-function parameters this argument will cover after кортеж expansion
			const цел argLen = дайДлинуАрга!(funcArgs.тип[fargI], typeof(*srcItem));

			static if (типКортеж_ли!(typeof(*srcItem)) && !типКортеж_ли!(funcArgs.тип[fargI])) {
				foreach (i, x; srcItem.значение) {
					_присвой!(funcArgs.тип[fargI + i], typeof(x), dupStaticArrays)(funcArgs.значение[fargI + i], x);
				}
			} else {
				static assert (1 == argLen);
				_присвой!(funcArgs.тип[fargI], typeof(*srcItem), dupStaticArrays)(funcArgs.значение[fargI], *srcItem);
			}

			// because we might've just expended a кортеж, this may be larger than one
			static assert (argLen >= 1);
			
			// we could've just used a dynamic арг (0) or a statically bound арг(1)
			static assert (bargInc == 0 || bargInc == 1);
			
			
			return копируйАрги!(argI+1, fargI+argLen, bargI+bargInc)(funcArgs, динАрги);
		} else {
			// last iteration
			
			// make sure we've copied all args the function will need
			static assert (fargI >= минАрговФции);
		}
	}


	static if (УказанныеПараметры.length > 0) {
		/// The final wrapped function
		ВозврТип func(ДинПарамы динАрги) {
			УказанныеПараметры funcArgs;
			копируйАрги!()(funcArgs, динАрги);
			
			// if the function expects any parameters passed by reference, we'll have to use the примениУк template
			// and convert pointers back to references by hand
			static if (!is(typeof(АлиасФ) == ПустойСлот) && Индекс_у!(PassByRef, ParamPassingMethods.тип) != -1) {
				
				// function parameter тип pointers (цел, float*, inout сим) -> (цел*, float*, сим*)
				КортежУказателей!(Кортеж!(RealFuncParams.тип[0 .. УказанныеПараметры.length]))	ptrs;
				
				// initialize the 'ptrs' кортеж instance
				foreach (i, dummy_; funcArgs.значение) {
					static if (is(ParamPassingMethods.тип[i] == PassByRef)) {
						
						version (BindNoNullCheck) {}
						else {
							assert (funcArgs.значение[i], "references cannot be пусто");
						}
						
						ptrs.значение[i] = funcArgs.значение[i];
					} else {
						ptrs.значение[i] = &funcArgs.значение[i];
					}
				}
				
				// and вызови the function :)
				примениУк!(ВозврТип, ТипФункц, ptrs.тип)(fp, ptrs.значение);
			} else {
				
				// ordinary вызови-by-кортеж
				return fp(funcArgs.значение);
			}
		}
	} else {
		/// The final wrapped function
		ВозврТип func() {
			return fp();
		}
	}
	
	/// The final wrapped function
	alias func вызови;
	
	
	/// The final wrapped function
	alias func opCall;
	
	
	/**
		Тип делегата, к-й м.б. возвращен из данного объекта
	*/
	template ТипУк() {
		alias typeof(&(new СвязаннаяФункц).вызови) ТипУк;
	}
	
	/**
		Get a delegate. Equivalent to getting it thru &amp;foo.вызови
	*/
	ТипУк!() указ() {
		return &this.func;
	}
}


version (BindUseStruct) {
	template ДерефФункц(T) {
		alias typeof(*T) ДерефФункц;
	}

	/**
		A context for bound/curried functions
	*/
	struct СвязаннаяФункц(FT, alias FAlias_, AllBoundArgs_) {
		mixin СФункцСвязки;
	}
} else {
	template ДерефФункц(T) {
		alias T ДерефФункц;
	}

	/**
		A context for bound/curried functions
	*/
	class СвязаннаяФункц(FT, alias FAlias_, AllBoundArgs_) {
		mixin СФункцСвязки;
	}
}


/**
	привяжи() can curry or "привяжи" arguments of a function, producing a different function which requires less parameters,
	or a different order of parameters. It also allows function composition.
	
	The syntax of a привяжи() вызови is:
	
	привяжи(function or delegate pointer { , <b>argument</b> });
	
	<b>argument</b> can be one of:
	<ul>
	<li> static/bound argument (an immediate значение) </li>
	<li> another bound function object </li>
	<li> dynamic argument, of the form __[0-9], e.g. __0, __3 or __9 </li>
	</ul>
	
	The результат is a function object, which can be called using вызови(), func() or opCall().
	There also exists a convenience function, указ() which returns a delegate to вызови/func/opCall
	
	The resulting delegate accepts exactly as many parameters as many distinct dynamic arguments were used.
---
- привяжи(&foo, _0, _1) // will жни a delegate accepting two parameters
- привяжи(&foo, _1, _0) // will жни a delegate accepting two parameters
- привяжи(&bar, _0, _1, _2, _0) // will жни a delegate accepting three parameters
---
	
	<br />
	<br />
	The types of dynamic parameters are extracted from the bound function itself and when necessary, тип negotiation
	is performed. For example, binding a function
---
проц foo(цел a, дол b)

// with:
привяжи(&foo, _0, _0)
---
	will результат in a delegate accepting a single, optimal parameter тип. The best тип is computed
	using std.typetuple.ПроизводныйВперёд, so in case of an цел and a дол, дол will be selected. Generally, привяжи will try to find
	a тип that can be implicitly converted to all the other types a given dynamic parameter uses.
		Note: in case of numeric types, an explicit, but transparent (to the user) cast will be performed
	
	<br />
	Function composition works intuitively:
---
привяжи(&f1, привяжи(&f2, _0))
---
	
	which will жни a delegate, that takes the argument, calls f2, then uses the return значение of f2 to вызови f1. Mathematically
	speaking, it will жни a function composition:
---
f1(f2(_0))
---
	
	When one function is composed multiple times, it will be called multiple times - Bind does no lazy evaluation, so
---
привяжи(&f3, привяжи(&f4, _0), привяжи(&f4, _0))
---
	will produce a delegate, which, upon calling, will invoke f4 two times to evaluate the arguments for f3 and then вызови f3
	
	
	One another feature that привяжи() supports is automatic кортеж expansion. It means that having functions:
---
проц foo(цел a, цел b)
Кортеж!(цел, цел) bar()
---
	
	Allows them to be bound by writing:
---
привяжи(&foo, привяжи(&bar))
// or
привяжи(&foo, кортеж(23, 45))
---
*/
typeof(new СвязаннаяФункц!(FT, АлиасПусто, Кортеж!(СписокАргов))) привяжи(FT, СписокАргов...)(FT fp, СписокАргов args) {
	auto рез = new ДерефФункц!(ВозврТип!(привяжи));
	рез.fp = fp;
	извлекиСвязанныеАрги!(0, 0, СписокАргов)(рез.связанныеАрги, args);
	return рез;
}


/**
	привяжиАлиас() is similar to привяжи(), but it's more powerful. Use привяжиАлиас() rather than привяжи() where possible. <br/>


	The syntax is:
	
	привяжиАлиас!(Function)(argument, argument, argument, argument, ...);
	
	привяжиАлиас takes advantage of using aliases directly, thus being able to extract default values from functions and not forcing the user
	to привяжи them. It doesn't, however mean that the resulting delegate can be called, omitting some of its parameters. It only means that these
	arguments that have default values in the function provided to привяжиАлиас don't have to be bound explicitly.
	
	Additionally, привяжиАлиас takes care of functions with out/inout parameters, by converting them to pointers internally. A function like:
---
проц foo(inout a)
---	
	can be bound using:
---
цел x;
привяжиАлиас!(foo)(&x);
---
	
	Note: there is no привяжи-time check for reference nullness, there is however a вызови-time check on all references which can be disabled
	by using version=BindNoNullCheck or compiling in release mode.
*/
template привяжиАлиас(alias FT) {
	typeof(new СвязаннаяФункц!(typeof(&FT), FT, Кортеж!(СписокАргов))) привяжиАлиас(СписокАргов...)(СписокАргов args) {
		auto рез = new ДерефФункц!(ВозврТип!(привяжиАлиас));
		рез.fp = &FT;
		извлекиСвязанныеАрги!(0, 0, СписокАргов)(рез.связанныеАрги, args);
		return рез;
	}
}


/*
	Tells whether the specified тип is a bound function
*/
template функцСвязки_ли(T) {
	static if (is(ДерефФункц!(T).ТипФункц)) {
		static if (is(ДерефФункц!(T).СвязанныеАрги)) {
			static if (is(typeof(ДерефФункц!(T).АлиасФ))) {
				static if (is(ДерефФункц!(T) : СвязаннаяФункц!(ДерефФункц!(T).ТипФункц, ДерефФункц!(T).АлиасФ, ДерефФункц!(T).ВсеСвязанныеАрги))) {
					static const бул функцСвязки_ли =да;
				} else static const бул функцСвязки_ли = нет;
			} else static const бул функцСвязки_ли = нет;
		} else static const бул функцСвязки_ли = нет;
	} else static const бул функцСвязки_ли = нет;
}


// all numeric types as of dmd.175
alias Кортеж!(байт, ббайт, крат, бкрат, цел, бцел, дол, бдол, /+cent, ucent, +/float, double, real, ifloat, idouble, ireal, cfloat, cdouble, creal) ЧисловыеТипы;



/*
	Gather all types that a given (i-th) dynamic арг uses.
	The types will be inserted into a кортеж
*/
template типыДинАргов(цел i, ПарамыФункц, СвязанныеАрги, цел minParamsLeft) {
	
	// performs slicing on the кортеж ... кортеж[i .. length]
	template sliceOffTuple(T, цел i) {
		alias Кортеж!(T.тип[i..length]) рез;
	}
	
	// prepends a T to the resulting кортеж
	// SkipType - the тип in СвязанныеАрги that we're just processing
	template prependType(T, SkipType) {
		static if (типКортеж_ли!(SkipType) && !типКортеж_ли!(ПарамыФункц.тип[0])) {
			// perform кортеж decomposition
			// e.g. if a function being bound is accepting (цел, цел) and the current тип is a Кортеж!(цел, цел),
			// then skip just one кортеж in the bound args and the length of the кортеж in func args
			// - skips two ints and one кортеж in the example
			alias типыДинАргов!(
					i,
					sliceOffTuple!(ПарамыФункц, SkipType.length).рез,
					Кортеж!(СвязанныеАрги.тип[1..$]),
					minParamsLeft - SkipType.length
				).рез tmp;
				
		} else {
			// just advance by one тип
			alias типыДинАргов!(
					i,
					sliceOffTuple!(ПарамыФункц, 1).рез,
					Кортеж!(СвязанныеАрги.тип[1..$]),
					minParamsLeft-1
				).рез tmp;
		}
		
		static if (is(T == проц)) {	// проц means that we aren't adding anything
			alias tmp рез;
		} else {
			alias tmp.meta.приставьТ!(T) рез;
		}
	}
	
	// iteration end detector
	static if (is(СвязанныеАрги == Кортеж!())) {
		static assert (minParamsLeft <= 0, "there are still unbound function parameters");
		alias Кортеж!() рез;
	}
	else {
		
		// w00t, detected a regular dynamic арг
		static if (динАрг_ли!(СвязанныеАрги.тип[0], i)) {
			alias prependType!(ПарамыФункц.тип[0], СвязанныеАрги.тип[0]).рез рез;
		} 
		
		// the арг is a bound function, extract info from it. we will be evaluating it later
		else static if (функцСвязки_ли!(СвязанныеАрги.тип[0])) {
			alias ДерефФункц!(СвязанныеАрги.тип[0]) СвязаннаяФункц;		// the bound function is a struct pointer, we have to derefernce its тип
			
			// does that function even have any dynamic парамы ?
			static if (СвязаннаяФункц.ДинПарамы.length > i) {
				alias prependType!(СвязаннаяФункц.ДинПарамы[i], СвязаннаяФункц.ВозврТип).рез рез;
			}
			// it doesn't
			else {
				alias prependType!(проц, СвязаннаяФункц.ВозврТип).рез рез;
			}
		}
		
		// a static арг, just skip it since we want to find all types a given ДинАрг uses. static args <> dyn args
		else alias prependType!(проц, СвязанныеАрги.тип[0]).рез рез;
	}
}


// just a simple util
protected template макЦел(цел a, цел b) {
	static if (a > b) static const цел макЦел = a;
	else static const цел макЦел = b;
}


/*
	Given a list of СвязанныеАрги, it returns the nuber of args that should be specified dynamically
*/
template члоДинАргов(СвязанныеАрги) {
	static if (СвязанныеАрги.length == 0) {
		// received an EmptyTuple
		static const цел рез = 0;
	} else {
		// ordinary dynamic арг
		static if (динАрг_ли!(СвязанныеАрги.тип[0])) {
			static const цел рез = макЦел!(СвязанныеАрги.тип[0].аргНом+1, члоДинАргов!(Кортеж!(СвязанныеАрги.тип[1..$])).рез);
		}
		
		// count the args in nested / composed functions
		else static if (функцСвязки_ли!(СвязанныеАрги.тип[0])) {
			static const цел рез = макЦел!(ДерефФункц!(СвязанныеАрги.тип[0]).ДинПарамы.length, члоДинАргов!(Кортеж!(СвязанныеАрги.тип[1..$])).рез);
		}
		
		// statically bound арг, skip it
		else {
 			static const цел рез = члоДинАргов!(Кортеж!(СвязанныеАрги.тип[1..$])).рез;
		}
	}
}


/*
	Used internally to mark a parameter which is a dummy placeholder
	E.g. when using привяжи(&f, привяжи(&g, _1), _0), then the inner bound function will use an ПустойСлот for its 0-th parameter
*/
struct ПустойСлот {
	ткст вТкст( ) {
		return "_";
	}
}


/*
	Get a кортеж of all dynamic args a function binding will need
	take nested/composed functions as well as кортеж decomposition into account
*/
template дайТипыДинАргов(ПарамыФункц, СвязанныеАрги, цел минАрговФции) {
	template цикл(цел i) {
		static if (i < члоДинАргов!(СвязанныеАрги).рез) {
			alias типыДинАргов!(i, ПарамыФункц, СвязанныеАрги, минАрговФции).рез.тип dirtyArgTypeList;
			
			// 'clean' the тип list, erasing all NoTypes from it that could've been added there from composed functions
			// if the арг is not used, we'll mark it as NoType anyway, but for now, we only want 'real' types so the most derived one can be found
			alias Кортеж!(ВырезатьВсе!(ПустойСлот, dirtyArgTypeList)) argTypeList;
			
			
			// make sure the арг is used
			static if(!is(argTypeList == Кортеж!())) {
				alias ПроизводныйВперёд!(argTypeList.тип)[0] argType;
			} else {
				//static assert(нет, i);
				alias ПустойСлот argType;
			}

			alias цикл!(i+1).рез.meta.приставьТ!(argType) рез;
		} else {
			alias Кортеж!() рез;
		}
	}
	
	alias цикл!(0).рез рез;
}


/*
	Given a кортеж that привяжи() was called with, it will detect which types need to be stored in a СвязаннаяФункц object
*/
template ИзвлечённыеСвязанныеАрги(СвязанныеАрги ...) {
	static if (СвязанныеАрги.length == 0) {
		alias Кортеж!() ИзвлечённыеСвязанныеАрги;
	}
	
	// we'll store all non-dynamic arguments...
	else static if (!динАрг_ли!(СвязанныеАрги[0])) {
		alias ИзвлечённыеСвязанныеАрги!(СвязанныеАрги[1..$]).meta.приставьТ!(СвязанныеАрги[0]) ИзвлечённыеСвязанныеАрги;
	}
	
	// ... and we're going to leave the dynamic ones for later
	else {
		alias ИзвлечённыеСвязанныеАрги!(СвязанныеАрги[1..$]) ИзвлечённыеСвязанныеАрги;
	}
}


/*
	Given a кортеж that привяжи() was called with, it will copy all data that a СвязаннаяФункц object will store into an ИзвлечённыеСвязанныеАрги кортеж
*/
проц извлекиСвязанныеАрги(цел dst, цел src, СвязанныеАрги ...)(inout ИзвлечённыеСвязанныеАрги!(СвязанныеАрги) результат, СвязанныеАрги связанныеАрги) {
	static if (dst < результат.length) {
		// again, we only want non-dynamic arguments here
		static if (!динАрг_ли!(СвязанныеАрги[src])) {
			_присвой!(typeof(результат.значение[dst]), typeof(связанныеАрги[src]))(результат.значение[dst], связанныеАрги[src]);
			return извлекиСвязанныеАрги!(dst+1, src+1, СвязанныеАрги)(результат, связанныеАрги);
		}
		
		// the dynamic ones will be specified at the time СвязаннаяФункц.вызови() is invoked
		else {
			return извлекиСвязанныеАрги!(dst, src+1, СвязанныеАрги)(результат, связанныеАрги);
		}
	}
}


/*
	Number of args in the bound function that this Src арг will cover
*/
template дайДлинуАрга(Dst, Src) {
	// if the арг is a кортеж and the target isn't one, it will be expanded/decomposed to the кортеж's length
	static if (типКортеж_ли!(Src) && !типКортеж_ли!(Dst)) {
		static const цел дайДлинуАрга = Src.length;
	}
	
	// plain арг - it will use 1:1 mapping of functioni парамы to bound парамы
	else {
		static const цел дайДлинуАрга = 1;
	}
}


/*
	Tell whether a parameter тип кортеж contains an ПустойСлот struct
*/
template СодержитТипПустойСлот(СписокПараметров ...) {
	const бул СодержитТипПустойСлот = -1 != Индекс_у!(ПустойСлот, СписокПараметров);
}


// just something to be default in привяжи(). привяжиАлиас() will use real aliases.
const ПустойСлот АлиасПусто;




struct PassByCopy	{}
struct PassByRef	{}

template ParamsPassMethodTuple_impl(alias Func, цел i = 0) {
	alias Кортеж!(КортежТипаПараметр!(typeof(&Func)))	Парамы;
	
	static if (Парамы.length == i) {
		alias Кортеж!() рез;
	} else {
		Парамы парамы = void;
		const парамы.тип[i] constParam;
		
		// if the function expects references, it won't like our const.
		static if (is(typeof(Func(парамы.значение[0..i], constParam, парамы.значение[i+1..$])))) {
			alias ParamsPassMethodTuple_impl!(Func, i+1).рез.meta.приставьТ!(PassByCopy) рез;
		} else {
			alias ParamsPassMethodTuple_impl!(Func, i+1).рез.meta.приставьТ!(PassByRef) рез;
		}
	}
}

/*
	Detect parameter passing methods: PassByCopy or PassByRef[erence]
*/
template КортежМетодовПередачиПараметров(alias Func) {
	alias ParamsPassMethodTuple_impl!(Func).рез КортежМетодовПередачиПараметров;
}


template FuncReferenceParamsAsPointers_impl(alias Func) {
	alias Кортеж!(КортежТипаПараметр!(typeof(&Func)))	Парамы;
	alias КортежМетодовПередачиПараметров!(Func)						PassMethods;
	
	template цикл(цел i) {
		static if (i == Парамы.length) {
			alias Кортеж!() рез;
		} else {
			static if (is(PassMethods.тип[i] == PassByRef)) {
				alias Парамы.тип[i]*	тип;
			} else {
				alias Парамы.тип[i]	тип;
			}
			
			alias цикл!(i+1).рез.meta.приставьТ!(тип) рез;
		}		
	}
	
	alias цикл!(0).рез рез;
}

/*
	Takes a function/delegate alias and converts its refence parameters to pointers. E.g.
	
	проц function(цел, inout сим, float*)    ->   (цел, сим*, float*)
*/
template СсылПарамыФункцВВидеУков(alias Func) {
	alias FuncReferenceParamsAsPointers_impl!(Func).рез СсылПарамыФункцВВидеУков;
}



/*
	Converts a кортеж of types to a кортеж containing pointer types of the original types
*/
template КортежУказателей(T) {
	static if (T.length > 0) {
		alias КортежУказателей!(Кортеж!(T.тип[1..$])).meta.приставьТ!(T.тип[0]*) КортежУказателей;
	} else {
		alias Кортеж!() КортежУказателей;
	}
}



/*
	Calls a function, dereferencing a pointer кортеж for each argument
*/
ВозврТип примениУк(ВозврТип, FN, T ...)(FN fn, T t) {
	static if (1 == T.length) {
		return fn(*t[0]);
	}
	else static if (2 == T.length) {
		return fn(*t[0], *t[1]);
	}
	else static if (3 == T.length) {
		return fn(*t[0], *t[1], *t[2]);
	}
	else static if (4 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3]);
	}
	else static if (5 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3], *t[4]);
	}
	else static if (6 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3], *t[4], *t[5]);
	}
	else static if (7 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3], *t[4], *t[5], *t[6]);
	}
	else static if (8 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3], *t[4], *t[5], *t[6], *t[7]);
	}
	else static if (9 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3], *t[4], *t[5], *t[6], *t[7], *t[8]);
	}
	else static if (10 == T.length) {
		return fn(*t[0], *t[1], *t[2], *t[3], *t[4], *t[5], *t[6], *t[7], *t[8], *t[9]);
	}
}
