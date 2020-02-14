module tpl.signal;
import stdrus, cidrus;

extern  (C) Object _d_toObject(ук p);
extern  (C) проц _d_OutOfMemory();

template Сигнал(T1...)
{

    alias проц delegate(T1) т_слот;

    проц подай( T1 i )
    {
        foreach (слот; слоты[0 .. слоты_индкс])
	{   if (слот)
		слот(i);
	}
    }

    проц подключи(т_слот слот)
    {

	auto длин = слоты.length;
	if (слоты_индкс == длин)
	{
	    if (слоты.length == 0)
	    {
		длин = 4;
		auto p = кразмести(т_слот.sizeof, длин);
		if (!p)
		    _d_OutOfMemory();
		слоты = (cast(т_слот*)p)[0 .. длин];
	    }
	    else
	    {
		длин = длин * 2 + 4;
		auto p = перемести(слоты.ptr, т_слот.sizeof * длин);
		if (!p)
		    _d_OutOfMemory();
		слоты = (cast(т_слот*)p)[0 .. длин];
		слоты[слоты_индкс + 1 .. length] = пусто;
	    }
	}
	слоты[слоты_индкс++] = слот;

     L1:
	Объект o = _d_toObject(слот.ptr);
	o.notifyRegister(&unhook);
    }

    проц отключи( т_слот слот)
    {
	for (т_мера i = 0; i < слоты_индкс; )
	{
	    if (слоты[i] == слот)
	    {	слоты_индкс--;
		слоты[i] = слоты[слоты_индкс];
		слоты[слоты_индкс] = пусто;

		Объект o = _d_toObject(слот.ptr);
		o.notifyUnRegister(&unhook);
	    }
	    else
		i++;
	}
    }

    проц unhook(Объект o)
    {
	for (т_мера i = 0; i < слоты_индкс; )
	{
	    if (_d_toObject(слоты[i].ptr) is o)
	    {	слоты_индкс--;
		слоты[i] = слоты[слоты_индкс];
		слоты[слоты_индкс] = пусто;	// not strictly necessary
	    }
	    else
		i++;
	}
    }

    ~this()
    {
	if (слоты)
	{
	    foreach (слот; слоты[0 .. слоты_индкс])
	    {
		if (слот)
		{   Объект o = _d_toObject(слот.ptr);
		    o.notifyUnRegister(&unhook);
		}
	    }
	    освободи(слоты.ptr);
	    слоты = пусто;
	}
    }

  protected:
    т_слот[] слоты;	
    т_мера слоты_индкс;	
}

проц linkin() { }


unittest
{


    class Наблюдатель
    {
	проц следи(ткст сооб, цел i)
	{
	    скажинс(фм("Наблюдалось сообщение '%s' со значением %s", сооб, i));
	}
    }

    class Фу
    {
	цел значение() { return _value; }

	цел значение(цел v)
	{
	    if (v != _value)
	    {   _value = v;
		подай("устанавливаю новое значение", v);
	    }
	    return v;
	}

	mixin Сигнал!(char[], цел);

      protected:
	цел _value;
    }

    Фу a = new Фу;
    Наблюдатель o = new Наблюдатель;

    a.значение = 3;
    a.подключи(&o.следи);
    a.значение = 4;
    a.отключи(&o.следи);
    a.значение = 5;
    a.подключи(&o.следи);
    a.значение = 6;
    delete o;
    a.значение = 7;
}