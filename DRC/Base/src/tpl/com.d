module tpl.com;

//pragma(lib, "dinrus.lib");
import cidrus, runtime;
import tpl.traits, tpl.args, tpl.typetuple;
import std.string: format;
import std.utf: toUTF8;
import std.utf: toUTF16z;
private import sys.uuid;
alias toUTF16z вЮ16н;
alias  toUTF8  вЮ8;
alias format фм;

ук* возврзнач(T)(out T ppv)
in {
  assert(&ppv != пусто);
}
body {
  return cast(ук*)&ppv;
}

/**
 * Извлекает ГУИД, связанный с указанной переменной или типом.
 * Примеры:
 * ---
 * import com.com, 
 *   stdrus;
 *
 * проц main() {
 *   writefln("ГУИДом IXMLDOMDocument2 является %s", ууид_у!(IXMLDOMDocument2));
 * }
 *
 * // Производит:
 * // ГУИДом IXMLDOMDocument2 является {2933bf95-7b36-11d2-b20e-00c04f983e60}
 * ---
 */
 template ууид_уТ(T : T)
 {
  static if (is(typeof(mixin("IID_" ~ T.stringof))))
    const ГУИД ууид_уТ = mixin("IID_" ~ T.stringof); // e.g., IID_IShellFolder
  else static if (is(typeof(mixin("CLSID_" ~ T.stringof))))
    const ГУИД ууид_уТ = mixin("CLSID_" ~ T.stringof); // e.g., CLSID_Shell
  else static if (is(typeof(T.IID)))
    const ГУИД ууид_уТ = T.IID;
  else
      static assert(нет, " No GUID has been associated with '" ~ T.stringof ~ "'.");
	
}


template ууид_у(alias T)
{
  static if (is(typeof(T)))
    const ГУИД ууид_у = ууид_уТ!(typeof(T));
  else
    const ГУИД ууид_у = ууид_уТ!(T);
	
}

template статМас_ли(T : U[N], U, т_мера N)
 {
  const статМас_ли = да;
}

template статМас_ли(T) 
{
  const статМас_ли = нет;
}

template динМас_ли(T, U = void)
 {
  const динМас_ли = нет;
}

template динМас_ли(T : U[], U)
 {
  const динМас_ли = !статМас_ли!(T);
 }

template массив_ли(T) 
{
  const массив_ли = статМас_ли!(T) || динМас_ли!(T);
}

template указатель_ли(T) 
{
  const указатель_ли = is(T : ук);
}


/**
 * Определяет при компиляции встроенный тип, эквивалентный COM-типу.
 * Примеры:
 * ---
 * auto a = ТипВариант!(ткст);          // ПТипВарианта.БинТекст
 * auto b = ТипВариант!(бул);            // ПТипВарианта.Бул
 * auto c = ТипВариант!(typeof([1,2,3])); // ПТипВарианта.Массив | ПТипВарианта.Ц4
 * ---
 */
template ТипВариант(T)
 {
  static if (is(T == ком_бул))
    const ТипВариант = ПТипВарианта.Бул;
  else static if (is(T == бул))
    const ТипВариант = ПТипВарианта.Бул;
  else static if (is(T == сим))
    const ТипВариант = ПТипВарианта.Бц1;
  else static if (is(T == ббайт))
    const ТипВариант = ПТипВарианта.Бц1;
  else static if (is(T == байт))
    const ТипВариант = ПТипВарианта.Ц1;
  else static if (is(T == бкрат))
    const ТипВариант = ПТипВарианта.Бц2;
  else static if (is(T == крат))
    const ТипВариант = ПТипВарианта.Ц2;
  else static if (is(T == бцел))
    const ТипВариант = ПТипВарианта.Бц4;
  else static if (is(T == цел))
    const ТипВариант = ПТипВарианта.Ц4;
  else static if (is(T == бдол))
    const ТипВариант = ПТипВарианта.Бц8;
  else static if (is(T == дол))
    const ТипВариант = ПТипВарианта.Ц8;
  else static if (is(T == плав))
    const ТипВариант = ПТипВарианта.Р4;
  else static if (is(T == дво))
    const ТипВариант = ПТипВарианта.Р8;
  else static if (is(T == ДЕСЯТОК))
    const ТипВариант = ПТипВарианта.ДЕСЯТОК;
  else static if (is(T E == enum))
    const ТипВариант = ТипВариант!(E);
  else static if (is(T : ткст) || is(T : шткст) || is(T : юткст))
    const ТипВариант = ПТипВарианта.БинТекст;
  else static if (is(T == шим*))
    const ТипВариант = ПТипВарианта.БинТекст;
  else static if (is(T == БЕЗОПМАС*))
    const ТипВариант = ПТипВарианта.Массив;
  else static if (is(T == ВАРИАНТ))
    const ТипВариант = ПТипВарианта.ВАРИАНТ;
  else static if (is(T : ИДиспетчер))
    const ТипВариант = ПТипВарианта.Диспетчер;
  else static if (is(T : Инкогнито))
    const ТипВариант = ПТипВарианта.Инкогнито;
  else static if (массив_ли!(T))
    const ТипВариант = ТипВариант!(typeof(*T)) | ПТипВарианта.Массив;
  else static if (указатель_ли!(T)/* && !is(T == ук)*/)
    const ТипВариант = ТипВариант!(typeof(*T)) | ПТипВарианта.ПоСсылке;
  else
    const ТипВариант = ПТипВарианта.Проц;
}


ВАРИАНТ вВар(T)(T значение, бул autoFree = нет) {
  if (!autoFree) {
    return ВАРИАНТ(значение);
  }
  else return (new class(значение) {
    ВАРИАНТ var;
    this(T значение) { var = ВАРИАНТ(значение); }
    ~this() { var.сотри(); }
  }).var;
}

template com_cast_impl(T, ППолитикаИсключений политика)
 {

  T com_cast_impl(U)(U объ) {
    static if (is(U : Инкогнито)) {
      static if (is(typeof(объ is пусто))) {
        if (объ is пусто) {
          static if (политика == ППолитикаИсключений.Выводить)
           throw new ИсклНедостающЧлена("Исключение нулевого аргумента: объ");
          else
            return пусто;
        }
      }
      else static if (is(typeof(объ.нулл_ли))) {
        // com_ref
        if (объ.нулл_ли) {
          static if (политика == ППолитикаИсключений.Выводить)
            throw new ИсклНедостающЧлена("Исключение нулевого аргумента: объ");
          else
            return пусто;
        }
      }

      T результат;
      if (УД(объ.QueryInterface(ууид_у!(T), возврзнач(результат))))
        return результат;

      static if (политика == ППолитикаИсключений.Выводить)
        throw new Error("Неудачный каст из '" ~ U.stringof ~ "' в '" ~ T.stringof ~ "'.");
      else
        return пусто;
    }
    else static if (is(U : Объект)) {
      if (auto comObj = cast(КомОбъект)объ)
        return com_cast!(T)(comObj.объ);

      static if (политика == ППолитикаИсключений.Выводить)
        throw new Error("Неудачный каст из '" ~ U.stringof ~ "' в '" ~ T.stringof ~ "'.");
      else
        return пусто;
    }
    else static if (is(U == ВАРИАНТ)) {
      const тип = ТипВариант!(T);

      static if (тип != ПТипВарианта.Проц) {
        ВАРИАНТ temp;
        if (УД(ИзмениТипВариантаДоп(temp, объ,  ДайЛокальНити(), ПВар.АльфаБул, тип))) {
          scope(exit) temp.сотри();

          with (temp) {
            static if (тип == ПТипВарианта.Бул) {
              static if (is(T == бул))
                return (булЗнач == ДА_ВАРИАНТ) ? да : нет;
              else 
                return булЗнач;
            }
            else static if (тип == ПТипВарианта.Бц1) return ббайтЗнач;
            else static if (тип == ПТипВарианта.Ц1) return байтЗнач;
            else static if (тип == ПТипВарианта.Бц2) return бкратЗнач;
            else static if (тип == ПТипВарианта.Ц2) return кратЗнач;
            else static if (тип == ПТипВарианта.Бц4) return бцелЗнач;
            else static if (тип == ПТипВарианта.Ц4) return целЗнач;
            else static if (тип == ПТипВарианта.Бц8) return бдолЗнач;
            else static if (тип == ПТипВарианта.Ц8) return долЗнач;
            else static if (тип == ПТипВарианта.Р4) return плавЗнач;
            else static if (тип == ПТипВарианта.Р8) return двоЗнач;
            else static if (тип == ПТипВарианта.ДЕСЯТОК) return десЗнач;
            else static if (тип == ПТипВарианта.БинТекст) {
              static if (is(T : ткст))
                return бткстВТкст(бстрЗнач);
              else 
                return бстрЗнач;
            }
            else static if (тип == ПТипВарианта.Инкогнито) return com_cast_impl(объ.инкЗнач);
            else static if (тип == ПТипВарианта.Диспетчер) return com_cast_impl(объ.депЗнач);
            else return T.init;
          }
        }
        static if (политика == ППолитикаИсключений.Выводить)
          throw new Error("Неудачный каст из '" ~ U.stringof ~ "' в '" ~ T.stringof ~ "'.");
        else
          return T.init;
      }
      else static assert(нет, "Cannot cast from '" ~ U.stringof ~ "' to '" ~ T.stringof ~ "'.");
    }
    else static assert(нет, "Cannot cast from '" ~ U.stringof ~ "' to '" ~ T.stringof ~ "'.");
  }

}

/**
 * Вызывет операцию преобразования из одного типа COM в другой.
 *
 * Если операнд является ВАРИАНТом, эта функция преобразует его значение в тип,
 * представленный $(I T). Если операндом является производный от Инкогнито объект, эта функция 
 * вызывает у объекта метод QueryInterface. Если операция преобразования не удаётся,
 * функция возвращает T.init.
 *
 * Примеры:
 * ---
 * // C++
 * бул tryToMeow(Dog* dog) {
 *   Cat* cat = NULL;
 *   HRESULT хрез = dog->QueryInterface(IID_Cat, static_cast<ук*>(&cat));
 *   if (хрез == ПКомРез.Да) {
 *     хрез = cat->meow();
 *     cat->Release();
 *   }
 *   return хрез == ПКомРез.Да;
 * }
 *
 * // C#
 * бул tryToMeow(Dog dog) {
 *   Cat cat = dog as Cat;
 *   if (cat != пусто)
 *     return cat.meow();
 *   return нет;
 * }
 *
 * // D
 * бул tryToMeow(Dog dog) {
 *   if (auto cat = com_cast!(Cat)(dog)) {
 *     scope(exit) cat.Release();
 *     return cat.meow() == ПКомРез.Да;
 *   }
 *   return нет;
 * }
 * ---
 */
template com_cast(T) { 

 alias com_cast_impl!(T, ППолитикаИсключений.НеВыводить) com_cast;}

/// Вызывает операцию преобразования из одного COM типа в другой, как и выше, но выводит
///исключение в случае неудачного каста.
/// Выводит исключение: ИсклКОМ, если каст не удался.

template com_safe_cast(T) {  alias com_cast_impl!(T, ППолитикаИсключений.Выводить) com_safe_cast;}

/**
 * Создаёт COM объект класса, ассоциированного с указанным CLSIDом.
 * Параметры:
 *   клсид = КЛСИД, ассоциированный с соклассом, который будет использован для создания объекта.
 *   контекст =  _context, в котором запускается код, управляющий новым объектом.
 * Возвращает: Ссылку на интерфейс, идентифицируемый T.
 * Примеры:
 * ---
 * if (auto doc = создайКо!(IXMLDOMDocument3)(ууид_у!(DOMDocument60))) {
 *   scope(exit) doc.Release();
 * }
 * ---
 */
template создайКо(T, ППолитикаИсключений политика = cast(ППолитикаИсключений)1) {

  T создайКо(U)(U клсид, ПКонтекстВып контекст = cast(ПКонтекстВып) 0x1) {
    ГУИД гуид;
    static if (is(U : ГУИД)) {
      гуид = клсид;
    }
    else static if (is(U : ткст)) {
      try {
        гуид = ГУИД(клсид);
      }
      catch (Исключение) {
        цел хрез = КЛСИДИзПрогИД(вЮ16н(клсид), гуид);
        if (НЕУД(хрез)) {
          static if (политика == ППолитикаИсключений.Выводить)
            throw new ИсклКОМ(хрез);
          else
            return пусто;
        }
      }
    }
    else static assert(нет);

    T рет;
    цел хрез = СоздайЭкземплярКо(гуид, пусто, контекст, ууид_у!(T), возврзнач(рет));

    if (НЕУД(хрез)) {
      static if (политика == ППолитикаИсключений.Выводить)
        throw new ИсклКОМ(хрез);
      else
        return пусто;
    }

    return рет;
  }

}

template создайКоДоп(T, ППолитикаИсключений политика = cast(ППолитикаИсключений) 1) {

  T создайКоДоп(U)(U клсид, ткст сервер, ПКонтекстВып контекст = cast(ПКонтекстВып) 0x1) {
    ГУИД гуид;
    static if (is(U : ГУИД)) {
      гуид = клсид;
    }
    else static if (is(U : ткст)) {
      try {
        гуид = ГУИД(клсид);
      }
      catch (Исключение) {
        цел хрез = КЛСИДИзПрогИД(stdrus.вЮ16н(клсид), гуид);
        if (НЕУД(хрез)) {
          static if (политика == ППолитикаИсключений.Выводить)
            throw new ИсклКОМ(хрез);
          else
            return пусто;
        }
      }
    }

    КОСЕРВЕРИНФО кси;
    кси.имяОбъ = stdrus.вЮ16н(сервер);

    МУЛЬТИ_ОИ рет;
    рет.укНаИИд = &ууид_у!(T);
    цел хрез = СоздайЭкземплярКоДоп(гуид, пусто, контекст, &кси, 1, &рет);

    if (НЕУД(хрез)) {
      static if (политика == ППолитикаИсключений.Выводить)
        throw new ИсклКОМ(хрез);
      else
        return пусто;
    }

    return cast(T)рет.укНаИз;
  }

}

template Интерфейсы(ТСписок...) {

  static T создайКо(T, ППолитикаИсключений политика = cast(ППолитикаИсключений) 1)(ПКонтекстВып контекст = cast(ПКонтекстВып) 0x1) {
    static if (tpl.typetuple.Индекс_у!(T, ТСписок) == -1)
      static assert(нет, stdrus.вЮ8(cast(ткст)"'" ~ typeof(this).stringof ~ "' не поддерживает '" ~ T.stringof ~ "'."));
    else
      return создайКо!(T, политика)(ууид_у!(typeof(this)), контекст);
  }

}

template ОпросиИнтерфейсРеализ(ТСписок...) {

  extern(Windows)
  цел QueryInterface(ref ГУИД riid, ук* ppvObject) {
    if (ppvObject is пусто)
      return ПКомРез.Ук;

    *ppvObject = пусто;

    if (riid == ууид_у!(Инкогнито)) {
      *ppvObject = cast(ук)cast(Инкогнито)this;
    }
    else foreach (T; ТСписок) {
      // Поиск по заданному списку типов для выяснения того, поддерживается ли у нас запрашиваемый интерфейс.
      if (riid == ууид_у!(T)) {
        // This is the one, so we need look no further.
        *ppvObject = cast(ук)cast(T)this;
        break;
      }
    }

    if (*ppvObject is пусто)
      return ПКомРез.НеИнтерфейс;

    (cast(Инкогнито)this).AddRef();
    return ПКомРез.Да;
  }

}

// Реализует AddRef & Release для подклассов Инкогнито.
template СчётСсылокРеализ() 
	{
	protected цел refCount_ = 1;
	protected бул finalized_;

	extern(Windows):

	бцел AddRef()	{	 return БлокированныйИнкремент(&refCount_);	}

	бцел Release() 
	{
		if (БлокированныйДекремент(&refCount_) == 0)
		{
			if (!finalized_)
			{
			finalized_ = да;
			выполниТерминатор(this);
			}
      
			смУдалиПространство(cast(ук)this);
			cidrus.освободи(cast(ук)this);      
		}
    return refCount_;
	}

  extern(D):

  // Подклассы Инкогнито имеют ручное управление памятью.
  new(т_мера разм)
  {
    ук p = cidrus.празмести(разм);
    if (p is пусто)
      throw new ВнеПамИскл();
    смДобавьПространство2(p, p + разм);    
    return p;
  }
}


template КортежИнтерфейсов(T)
	{
	static if (is(T == Объект))
	  {
		alias КортежТипа!() КортежИнтерфейсов;
	  }
	static if (is(КортежТипаОснова!(T)[0] == Объект))
	  {
		alias КортежТипа!(КортежТипаОснова!(T)[1 .. $]) КортежИнтерфейсов;
	  }
	else 
	  {
		alias tpl.typetuple.БезДубликатов!(
		  КортежТипа!(КортежТипаОснова!(T)[1 .. $], 
			КортежИнтерфейсов!(КортежТипаОснова!(T)[0]))) 
		  КортежИнтерфейсов;
	  }
	}

/// Предоставляет реализацию Инкогнито, удобную для использования как mixin.
template ИнкогнитоРеализ(T...)
	 {
	  static if (is(T[0] : Объект))
		mixin ОпросиИнтерфейсРеализ!(КортежИнтерфейсов!(T[0]), T[1 .. $]);
	  else
		mixin ОпросиИнтерфейсРеализ!(T);
	  mixin СчётСсылокРеализ;

	  }

/// Предоставляет реализацию ИДиспетчер, удобную для использования как mixin.
template ИДиспетчерРеализ(T...)
 {

  mixin ИнкогнитоРеализ!(T);

  цел GetTypeInfoCount(out бцел pctinfo)
	  {
		pctinfo = 0;
		return ПКомРез.Нереализовано;
	  }

  цел GetTypeInfo(бцел iTInfo, бцел лкид, out ИИнфОТипе ppTInfo)
	  {
		ppTInfo = пусто;
		return ПКомРез.Нереализовано;
	  }

  цел GetIDsOfNames(ref ГУИД riid, шим** rgszNames, бцел cNames, бцел лкид, цел* rgDispId)
	  {
		rgDispId = пусто;
		return ПКомРез.Нереализовано;
	  }

  цел Invoke(цел dispIdMember, ref ГУИД riid, бцел лкид, бкрат wFlags, ДИСППАРАМЫ* pDispParams, ВАРИАНТ* pVarResult, ИСКЛИНФО* pExcepInfo, бцел* puArgError)
	  {
		return DISP_E_UNKNOWNNAME;
	  }

}

template ВсеТипыОсновы_уРеализ(T...)
	 {

	  static if (T.length == 0)
		alias КортежТипа!() ВсеТипыОсновы_уРеализ;
	  else
		alias КортежТипа!(T[0],
		  ВсеТипыОсновы_уРеализ!(tpl.traits.КортежТипаОснова!(T[0])),
			ВсеТипыОсновы_уРеализ!(T[1 .. $]))
		ВсеТипыОсновы_уРеализ;

	}

template ВсеТипыОсновы_у(T...)
	 {
	  alias БезДубликатов!(ВсеТипыОсновы_уРеализ!(T)) ВсеТипыОсновы_у;
	 }

	 
/**
 * Абстрактный класс-основа для объектов COM, происходящих от Инкогнито или ИДиспетчер.
 *
 * Класс Реализует предоставляет дефолтную реализацию требуемых этими интерфейсами методов. Следовательно, от подклассов требуется только переписать их, когда им 
 * понадобится дополнительная функциональность. Этот класс также переписывает оператор new,
 * после чего экземпляры не собираются сборщиком мусора (СМ).
 * Примеры:
 * ---
 * class MyImpl : Реализует!(Инкогнито) {
 * }
 * ---
 */
abstract class Реализует(T...) : T
	 {

	  static if (tpl.typetuple.Индекс_у!(ИДиспетчер, ВсеТипыОсновы_у!(T)) != -1)
		mixin ИДиспетчерРеализ!(T, ВсеТипыОсновы_у!(T));
	  else
		mixin ИнкогнитоРеализ!(T, ВсеТипыОсновы_у!(T));

	 }

///////////////////////////////////////////////////////////////////////////////////////////////////
// DMD предотвращает запуск деструкторов над объектами COM.
проц выполниТерминатор(Объект объ) 
{
  if (объ) 
  {
    ИнфОКлассе** ci = cast(ИнфОКлассе**)cast(ук)объ;
    if (*ci) 
	{
      if (auto c = **ci) 
	  {
        do
		{
          if (c.destructor)
		  {
            auto finalizer = cast(проц function(Объект))c.destructor;
            finalizer(объ);
          }
          c = c.base;
        } while (c);
      }
    }
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////