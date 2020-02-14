module tpl.box;
import stdrus,  runtime;

class РазбоксИскл : Исключение
{

    Бокс объект;	/// This is the box that the user attempted to unbox.

    ИнфОТипе типВывода; /// This is the type that the user attempted to unbox the value as.

    /**
     * Assign parameters and создай the message in the form
     * <tt>"Could not unbox from type ... to ... ."</tt>
     */
    this(Бокс объект, ИнфОТипе типВывода)
    {
        this.объект = объект;
        this.типВывода = типВывода;
        super(форматируй("Не удалось разбоксирование из типа %s в %s.", объект.тип, типВывода));
		//шим* soob =cast(шим*)(вЮ16(форматируй("Не удалось разбоксирование из типа %s в %s.", объект.тип, типВывода)));
		//ОкноСооб(пусто, cast(шим*) soob, "Рантайм Динрус: РазбоксИскл", ПСооб.Ок|ПСооб.Ошибка);
    }
}

 бул инфОТипеМассив_ли(ИнфОТипе тип)
{
    ткст имя = тип.classinfo.name;
    return имя.length >= 10 && имя[9] == 'A' && имя != "TypeInfo_AssociativeArray";
}

protected template разбоксКастРеал(T)
{
    T разбоксКастРеал(Бокс значение)
    {
        assert (значение.тип !is пусто);
        
        if (значение.тип is typeid(плав))
            return cast(T) *cast(плав*) значение.данные;
        if (значение.тип is typeid(дво))
            return cast(T) *cast(дво*) значение.данные;
        if (значение.тип is typeid(реал))
            return cast(T) *cast(реал*) значение.данные;
        return разбоксКастЦелый!(T)(значение);
    }
}

protected template разбоксКастЦелый(T)
{
    T разбоксКастЦелый(Бокс значение)
    {
        assert (значение.тип !is пусто);
        
        if (значение.тип is typeid(цел))
            return cast(T) *cast(цел*) значение.данные;
        if (значение.тип is typeid(бцел))
            return cast(T) *cast(бцел*) значение.данные;
        if (значение.тип is typeid(дол))
            return cast(T) *cast(дол*) значение.данные;
        if (значение.тип is typeid(бдол))
            return cast(T) *cast(бдол*) значение.данные;
        if (значение.тип is typeid(бул))
            return cast(T) *cast(бул*) значение.данные;
        if (значение.тип is typeid(байт))
            return cast(T) *cast(байт*) значение.данные;
        if (значение.тип is typeid(ббайт))
            return cast(T) *cast(ббайт*) значение.данные;
        if (значение.тип is typeid(крат))
            return cast(T) *cast(крат*) значение.данные;
        if (значение.тип is typeid(бкрат))
            return cast(T) *cast(бкрат*) значение.данные;
        throw new РазбоксИскл(значение, typeid(T));
    }
}

protected template разбоксКастКомплекс(T)
{
    T разбоксКастКомплекс(Бокс значение)
    {
        assert (значение.тип !is пусто);
        
        if (значение.тип is typeid(кплав))
            return cast(T) *cast(кплав*) значение.данные;
        if (значение.тип is typeid(кдво))
            return cast(T) *cast(кдво*) значение.данные;
        if (значение.тип is typeid(креал))
            return cast(T) *cast(креал*) значение.данные;
        if (значение.тип is typeid(вплав))
            return cast(T) *cast(вплав*) значение.данные;
        if (значение.тип is typeid(вдво))
            return cast(T) *cast(вдво*) значение.данные;
        if (значение.тип is typeid(вреал))
            return cast(T) *cast(вреал*) значение.данные;
        return разбоксКастРеал!(T)(значение);
    }
}

protected template разбоксКастМнимое(T)
{
    T разбоксКастМнимое(Бокс значение)
    {
        assert (значение.тип !is пусто);
        
        if (значение.тип is typeid(вплав))
            return cast(T) *cast(вплав*) значение.данные;
        if (значение.тип is typeid(вдво))
            return cast(T) *cast(вдво*) значение.данные;
        if (значение.тип is typeid(вреал))
            return cast(T) *cast(вреал*) значение.данные;
        throw new РазбоксИскл(значение, typeid(T));
    }
}
   
template изБокса(T)
{
    T изБокса(Бокс значение)
    {
        assert (значение.тип !is пусто);
        
        if (typeid(T) is значение.тип)
            return *cast(T*) значение.данные;
        throw new РазбоксИскл(значение, typeid(T));
    }
}

template изБокса(T : байт) { T изБокса(Бокс значение) { return разбоксКастЦелый!(T) (значение); } }
template изБокса(T : ббайт) { T изБокса(Бокс значение) { return разбоксКастЦелый!(T) (значение); } }
template изБокса(T : крат) { T изБокса(Бокс значение) { return разбоксКастЦелый!(T) (значение); } }
template изБокса(T : бкрат) { T изБокса(Бокс значение) { return разбоксКастЦелый!(T) (значение); } }
template изБокса(T : цел) { T изБокса(Бокс значение) { return разбоксКастЦелый!(T) (значение); } }
template изБокса(T : бцел) { T изБокса(Бокс значение) { return разбоксКастЦелый!(T) (значение); } }
template изБокса(T : дол) { T изБокса(Бокс значение) { return разбоксКастЦелый!(T) (значение); } }
template изБокса(T : бдол) { T изБокса(Бокс значение) { return разбоксКастЦелый!(T) (значение); } }
template изБокса(T : плав) { T изБокса(Бокс значение) { return разбоксКастРеал!(T) (значение); } }
template изБокса(T : дво) { T изБокса(Бокс значение) { return разбоксКастРеал!(T) (значение); } }
template изБокса(T : реал) { T изБокса(Бокс значение) { return разбоксКастРеал!(T) (значение); } }
template изБокса(T : кплав) { T изБокса(Бокс значение) { return разбоксКастКомплекс!(T) (значение); } }
template изБокса(T : кдво) { T изБокса(Бокс значение) { return разбоксКастКомплекс!(T) (значение); } }
template изБокса(T : креал) { T изБокса(Бокс значение) { return разбоксКастКомплекс!(T) (значение); } }
template изБокса(T : вплав) { T изБокса(Бокс значение) { return разбоксКастМнимое!(T) (значение); } }
template изБокса(T : вдво) { T изБокса(Бокс значение) { return разбоксКастМнимое!(T) (значение); } }
template изБокса(T : вреал) { T изБокса(Бокс значение) { return разбоксКастМнимое!(T) (значение); } }

template изБокса(T : Объект)
{
    T изБокса(Бокс значение)
    {
        assert (значение.тип !is пусто);
        
        if (typeid(T) == значение.тип || cast(TypeInfo_Class) значение.тип)
        {
            Объект object = *cast(Объект*)значение.данные;
            T результат = cast(T)object;
            
            if (object is пусто)
                return пусто;
            if (результат is пусто)
                throw new РазбоксИскл(значение, typeid(T));
            return результат;
        }
        
        if (typeid(ук) is значение.тип && *cast(ук*) значение.данные is пусто)
            return пусто;
        throw new РазбоксИскл(значение, typeid(T));
    }
}

template изБокса(T : T[])
{
    T[] изБокса(Бокс значение)
    {
        assert (значение.тип !is пусто);
        
        if (typeid(T[]) is значение.тип)
            return *cast(T[]*) значение.данные;
        if (typeid(ук) is значение.тип && *cast(ук*) значение.данные is пусто)
            return пусто;
        throw new РазбоксИскл(значение, typeid(T[]));
    }
}

template изБокса(T : T*)
{
    T* изБокса(Бокс значение)
    {
        assert (значение.тип !is пусто);
        
        if (typeid(T*) is значение.тип)
            return *cast(T**) значение.данные;
        if (typeid(ук) is значение.тип && *cast(ук*) значение.данные is пусто)
            return пусто;
        if (typeid(T[]) is значение.тип)
            return (*cast(T[]*) значение.данные).ptr;
        
        throw new РазбоксИскл(значение, typeid(T*));
    }
}

template изБокса(T : ук)
{
    T изБокса(Бокс значение)
    {
        assert (значение.тип !is пусто);
        
        if (cast(TypeInfo_Pointer) значение.тип)
            return *cast(ук*) значение.данные;
        if (инфОТипеМассив_ли(значение.тип))
            return (*cast(проц[]*) значение.данные).ptr;
        if (cast(TypeInfo_Class) значение.тип)
            return cast(T)(*cast(Объект*) значение.данные);
        
        throw new РазбоксИскл(значение, typeid(T));
    }
}

template разбоксОбъ(T)
{
    бул разбоксОбъ(Бокс значение)
    {
        return значение.разбоксОбъ(typeid(T));
    }
}

template тестРазбокс(T)
{
    T тестРазбокс(Бокс значение)
    {
        T результат;
        бул разбоксОбъ = значение.разбоксОбъ(typeid(T));
        
        try результат = изБокса!(T) (значение);
        catch (РазбоксИскл error)
        {
            if (разбоксОбъ)
                ошибка ("Не удалось разбоксировать " ~ значение.тип.вТкст ~ " как " ~ typeid(T).вТкст ~ "; однако разбоксОбъ должен бы работать...");
            assert (!разбоксОбъ);
            throw error;
        }
        
        if (!разбоксОбъ)
            ошибка ("Разбоксирован " ~ значение.тип.вТкст ~ " как " ~ typeid(T).вТкст ~ "; однако, он должен был вызвать ошибку.");
        return результат;
    }
}


protected enum КлассТипа
{
    Бул, /**< бул */
    Бит = Бул,	// for backwards compatibility
    Целое, /**< byte, ббайт, крат, ushort, цел, бцел, дол, ulong */
    Плав, /**< float, double, real */
    Комплекс, /**< cfloat, cdouble, creal */
    Мнимое, /**< ifloat, idouble, ireal */
    Класс, /**< Inherits from Объект */
    Указатель, /**< Указатель type (T *) */
    Массив, /**< Массив type (T []) */
    Другой, /**< Any other type, such as delegates, function pointers, struct, проц... */
}


struct Бокс
{
    ИнфОТипе п_тип; /**< The type of the contained object. */
    
    union
    {
        ук п_долДанные; /**< An массив of the contained object. */
        проц[8] п_кратДанные; /**< Data used when the object is small. */
    }
    
    protected static КлассТипа выявиКлассТипа(ИнфОТипе тип)
    {
        if (cast(TypeInfo_Class) тип)
            return КлассТипа.Класс;
        if (cast(TypeInfo_Pointer) тип)
            return КлассТипа.Указатель;
        if (инфОТипеМассив_ли(тип))
            return КлассТипа.Массив;

        version (DigitalMars)
        {
            /* Depend upon the имя of the base тип classes. */
            if (тип.classinfo.name.length != "TypeInfo_?".length)
                return КлассТипа.Другой;
            switch (тип.classinfo.name[9])
            {
                case 'b', 'x': return КлассТипа.Бул;
                case 'g', 'h', 's', 't', 'i', 'k', 'l', 'm': return КлассТипа.Целое;
                case 'f', 'd', 'e': return КлассТипа.Плав;
                case 'q', 'r', 'c': return КлассТипа.Комплекс;
                case 'o', 'p', 'j': return КлассТипа.Мнимое;
                default: return КлассТипа.Другой;
            }
        }
        else
        {
            /* Use the имя returned from toString, which might (but hopefully doesn't) include an allocation. */
            switch (тип.вТкст)
            {
                case "бул", "bool": return КлассТипа.Бул;
                case "byte", "ббайт", "крат", "ushort", "бцел", "дол", "ulong", "uint", "ubyte": return КлассТипа.Целое;
                case "float", "real", "double": return КлассТипа.Плав;
                case "cfloat", "cdouble", "creal": return КлассТипа.Комплекс;
                case "ifloat", "idouble", "ireal": return КлассТипа.Мнимое;
                default: return КлассТипа.Другой;
            }
        }
    }
     static проц opCall(){}
    /** Return whether this value could be unboxed as the given тип without throwing. */
    бул разбоксОбъ(ИнфОТипе тест)
    {
        if (тип is тест)
            return да;
        
        TypeInfo_Class ca = cast(TypeInfo_Class) тип, cb = cast(TypeInfo_Class) тест;
        
        if (ca !is пусто && cb !is пусто)
        {
            ИнфОКлассе ia = (*cast(Объект *) данные).classinfo, ib = cb.info;
            
            for ( ; ia !is пусто; ia = ia.base)
                if (ia is ib)
                    return да;
            return нет;
        }
        
        КлассТипа ta = выявиКлассТипа(тип), tb = выявиКлассТипа(тест);
        
        if (тип is typeid(ук) && *cast(ук*) данные is пусто)
            return (tb == КлассТипа.Класс || tb == КлассТипа.Указатель || tb == КлассТипа.Массив);
        
        if (тест is typeid(ук))
            return (tb == КлассТипа.Класс || tb == КлассТипа.Указатель || tb == КлассТипа.Массив);
        
        if (ta == КлассТипа.Указатель && tb == КлассТипа.Указатель)
            return (cast(TypeInfo_Pointer)тип).следщ is (cast(TypeInfo_Pointer)тест).следщ;
        
        if ((ta == tb && ta != КлассТипа.Другой)
        || (ta == КлассТипа.Бул && tb == КлассТипа.Целое)
        || (ta <= КлассТипа.Целое && tb == КлассТипа.Плав)
        || (ta <= КлассТипа.Мнимое && tb == КлассТипа.Комплекс))
            return да;
        return нет;
    }
    
    /**
     * Property for the тип contained by the box.
     * This is initially пусто and cannot be assigned directly.
     * возвращает: the тип of the contained object.
     */
     ИнфОТипе тип()
    {
        return п_тип;
    }
    
    /**
     * Property for the data pointer to the value of the box.
     * This is initially пусто and cannot be assigned directly.
     * возвращает: the data массив.
     */
     проц[] данные()
    {
        т_мера size = тип.tsize();
        
        return size <= п_кратДанные.length ? п_кратДанные[0..size] : п_долДанные[0..size];
    }

    /**
     * Attempt to convert the boxed value into a string using std.string.format;
     * this will throw if that function cannot хэндл it. If the box is
     * uninitialized then this returns "".    
     */
    ткст toString(){return вТкст();}
   
    ткст вТкст()
    {
        if (тип is пусто)
            return "<пустой бокс>";
        
        ИнфОТипе[2] arguments;
        ткст string;
        проц[] args = new проц[(char[]).sizeof + данные.length];
        ткст format = "%s";
        
        arguments[0] = typeid(char[]);
        arguments[1] = тип;
        
       проц putc(dchar ch)
        {
            кодируйЮ(string, ch);
        }        
        
        args[0..(char[]).sizeof] = (cast(ук) &format)[0..(char[]).sizeof];
        args[(char[]).sizeof..length] = данные;
        форматДелай(&putc, arguments, args.ptr);
        delete args;
        
        return string;
    }
    
    protected бул opEqualsInternal(Бокс other, бул inverted)
    {
        if (тип != other.тип)
        {
            if (!разбоксОбъ(other.тип))
            {
                if (inverted)
                    return нет;
                return other.opEqualsInternal(*this, да);
            }
            
            КлассТипа ta = выявиКлассТипа(тип), tb = выявиКлассТипа(other.тип);
            
            if (ta <= КлассТипа.Целое && tb <= КлассТипа.Целое)
            {
                ткст na = тип.вТкст, nb = other.тип.вТкст;
                
                if (na == "ulong" || nb == "ulong")
                    return изБокса!(ulong)(*this) == изБокса!(ulong)(other);
                return изБокса!(дол)(*this) == изБокса!(дол)(other);
            }
            else if (tb == КлассТипа.Плав)
                return изБокса!(real)(*this) == изБокса!(real)(other);
            else if (tb == КлассТипа.Комплекс)
                return изБокса!(creal)(*this) == изБокса!(creal)(other);
            else if (tb == КлассТипа.Мнимое)
                return изБокса!(ireal)(*this) == изБокса!(ireal)(other);
            
            assert (0);
        }
        
        return cast(бул)тип.equals(данные.ptr, other.данные.ptr);
    }

    /**
     * Compare this box's value with another box. This implicitly casts if the
     * types are different, identical to the regular тип system.    
     */
    бул opEquals(Бокс другой)
    {
	//скажинс("пошло сравнение");
        return opEqualsInternal(другой, нет);
    }
    
    protected float opCmpInternal(Бокс other, бул inverted)
    {
        if (тип != other.тип)
        {
            if (!разбоксОбъ(other.тип))
            {
                if (inverted)
                    return 0;
                return other.opCmpInternal(*this, да);
            }
            
            КлассТипа ta = выявиКлассТипа(тип), tb = выявиКлассТипа(other.тип);
            
            if (ta <= КлассТипа.Целое && tb == КлассТипа.Целое)
            {
                if (тип == typeid(ulong) || other.тип == typeid(ulong))
                {
                    ulong va = изБокса!(ulong)(*this), vb = изБокса!(ulong)(other);
                    return va > vb ? 1 : va < vb ? -1 : 0;
                }
                
                дол va = изБокса!(дол)(*this), vb = изБокса!(дол)(other);
                return va > vb ? 1 : va < vb ? -1 : 0;
            }
            else if (tb == КлассТипа.Плав)
            {
                real va = изБокса!(real)(*this), vb = изБокса!(real)(other);
                return va > vb ? 1 : va < vb ? -1 : va == vb ? 0 : float.nan;
            }
            else if (tb == КлассТипа.Комплекс)
            {
                creal va = изБокса!(creal)(*this), vb = изБокса!(creal)(other);
                return va == vb ? 0 : float.nan;
            }
            else if (tb == КлассТипа.Мнимое)
            {
                ireal va = изБокса!(ireal)(*this), vb = изБокса!(ireal)(other);
                return va > vb ? 1 : va < vb ? -1 : va == vb ? 0 : float.nan;
            }
            
            assert (0);
        }
        
        return тип.compare(данные.ptr, other.данные.ptr);
    }

    /**
     * Compare this box's value with another box. This implicitly casts if the
     * types are different, identical to the regular тип system.
     */
    плав opCmp(Бокс другой)
    {
        return opCmpInternal(другой, нет);
    }

    /**
     * Return the value's hash.
     */
    т_хэш вХэш()
    {
        return тип.getHash(данные.ptr);
    }
}

//////////////////////////////

 Бокс бокс(ИнфОТипе тип, ук данные)
in
{
    assert(тип !is пусто);
}
body
{
//скажинс("начинаю работать...");
    Бокс результат;
	//скажинс("вхожу в первое присваивание...");
    т_мера size = тип.tsize();
    //скажинс("первое присваивание...");
    результат.п_тип = тип;
	//скажинс("второе присваивание...");
    if (size <= результат.п_кратДанные.length){
        результат.п_кратДанные[0..size] = данные[0..size];
		//скажинс("условное присваивание...");
		}
    else
	{
        результат.п_долДанные = данные[0..size].dup.ptr;
		//скажинс("безусловное присваивание...");
		}
        //скажинс(форматируй("выдаю рез...%s", результат.вТкст));
		//скажинс(форматируй("входный тип...%s", тип.вТкст));
		//скажинс(форматируй("размер входных данных...%s", данные.sizeof));
    return результат;
}


protected т_мера длинаАргумента(т_мера baseLength)
{
    return (baseLength + цел.sizeof - 1) & ~(цел.sizeof - 1);
}
  
 Бокс[] масБокс(ИнфОТипе[] типы, ук данные)
{
//скажинс("вызываю фцию222...");
    Бокс[] массив = new Бокс[типы.length];
    
    foreach(т_мера index, ИнфОТипе тип; типы)
    {
        массив[index] = бокс(тип, данные);
        данные += длинаАргумента(тип.tsize());
    }
       return массив;
}

проц массивБоксВАргументы(Бокс[] аргументы, out ИнфОТипе[] типы, out ук данные)
	{
		т_мера dataLength;
		ук pointer;
	// скажинс("вызываю фцию111...");
		foreach (Бокс item; аргументы)
		
			dataLength += длинаАргумента(item.данные.length);
			
		типы = new ИнфОТипе[аргументы.length];
		pointer = данные = (new проц[dataLength]).ptr;

		foreach (т_мера index, Бокс item; аргументы)
		{
			типы[index] = item.тип;
			pointer[0..item.данные.length] = item.данные;
			pointer += длинаАргумента(item.данные.length);
		}    
	}
	
Бокс вБокс(...)
	in
	{
		assert (_arguments.length == 1);
	}
	body
	{
	
		return бокс(_arguments[0], _argptr);
	}
  

   
Бокс[] массивБокс(...)
	{
	//скажинс("вызываю фцию222...");
		return масБокс(_arguments, _argptr);
	}