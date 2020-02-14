//This file changed for Rulada by Vitaly Kulich

module object;
public import base, win, cidrus;
private import rt.lifetime, rt.hash, rt.aaA /*rt.console*/;//: кразмести, перемести, освободи, перембуф, копирбуф, сравбуф;
private import  runtime;
private  import std.string, std.utf;
alias std.string.format фм;
import sys.memory;
//debug = НА_КОНСОЛЬ;

alias Исключение.ИнфОСледе function( ук укз = пусто ) Следопыт, TraceHandler;

export extern (C)
{
 ткст симмас(цел к){return new сим[к];}
 байт[] байтмас(цел к){return new байт[к];}
 ббайт[] ббайтмас(цел к){return new ббайт[к];}
 плав[] плавмас(цел к){return new плав[к];}
 дво[] двомас(цел к){return new дво[к];}
 ткст[] ткстмас(цел к){return new ткст[к];}
 бдол[] бдолмас(цел к){return new бдол[к];}
 дол[] долмас(цел к){return new дол[к];}
 цел[] целмас(цел к){return new цел[к];}
 бцел[] бцелмас(цел к){return new бцел[к];}
 крат[] кратмас(цел к){return new крат[к];}
 бкрат[] бкратмас(цел к){return new бкрат[к];}
  реал[] реалмас(цел к){return new реал[к];}
}
extern (C)
{
	проц ошибка(ткст сооб, ткст файл = ткст.init, дол  строка = дол.init );
		
	проц ошибкаПодтверждения(ткст файл, т_мера строка);
	проц ошибкаГраницМассива(ткст файл, т_мера строка);
	проц ошибкаФинализации(ИнфОКлассе инфо, Исключение ис);
	проц ошибкаНехваткиПамяти();
	проц ошибкаПереключателя(ткст файл, т_мера строка);
	проц ошибкаЮникод(ткст сооб, т_мера индкс);
	проц ошибкаДиапазона(ткст файл, т_мера строка);
	проц ошибкаСкрытойФункции(Объект о);
	
}
private
{
	import exception: СистОШ = СисОш;
}


/******************
 * Все объекты "класс" в D наследуют от Object.
 */
export extern (D) class Object

{

   
	/**
     * Перепешите для захвата явного удаления или для косвенного 
     * удаления через масштабный экземпляр. В отличие от dtor(), ссылки GC
     * при вызове этого метода остаются нетронутыми
     */
   export проц dispose()
    {
	
    }
    /**
     * Преобразует Object в удобочитаемую форму и записывает эту строку в stdout.
     */
	 export проц вымести(){dispose();}
	 
   export  проц print()
    {
	эхо("%.*s\n", toString());
    }
	
	export проц выведи() {print();}
    /**
     * Преобразует Object в удобочитаемую строку.
     */
   export  ткст toString()
    {
	return this.classinfo.name;
    }
	
	export ткст вТкст(){return toString();}
	
    /**
     * Вычисляет хеш-функцию для Object.
     */
   export hash_t toHash()
    {
	// BUG: this prevents a compacting GC from working, needs to be fixed
	return cast(hash_t)cast(ук)this;
    }
	
	export т_хэш вХэш(){return toHash();}
	
    /**
     * Сравнить с другим Объектом obj.
     * Возвращает:
     *	$(TABLE
     *  $(TR $(TD this &lt; obj) $(TD &lt; 0))
     *  $(TR $(TD this == obj) $(TD 0))
     *  $(TR $(TD this &gt; obj) $(TD &gt; 0))
     *  )
     */
   export  цел opCmp(Object o)
    {
	// BUG: this prevents a compacting GC from working, needs to be fixed
	//return cast(цел)cast(ук )this - cast(цел)cast(ук )o;

	//throw new Error("need opCmp for class " ~ this.classinfo.name);
	return this !is o;
    }
	
	 /**
     * Returns !=0 if this object does have the same contents as obj.
     */
   export  цел opEquals(Object o) //цел in Phobos
    {
	return cast(цел)(this is o);
    }
	
	
	export interface Monitor
    {
	export:
        проц lock();
		alias lock блокируй;
		
        проц unlock();
		alias unlock разблокируй;
    }
	alias Monitor Монитор;
    /* **
     * Вызывается делегат дг, который передаётся этому методу при уничтожении объекта.
     * Использовать крайне осторожно, так как список делегатов находится в неизвестном
     * сборщику мусора месте. След., если какой-то из объектов, указанных этими делегатами,
     * освобождается СМ,  то вызов делегата вызовет крэш.
     * Исключительно для разработчиков библиотеки, as it will need to be
     * redone if weak pointers are added or a moving gc is developed.
     */
   export  final проц notifyRegister(проц delegate(Object) дг)
    {
	//эхо("notifyRegister(дг = %llx, o = %p)\n", дг, this);
	synchronized (this)
	{
	    .Monitor* m = cast(.Monitor*)(cast(ук*)this)[1];
	    foreach (inout x; m.delegates)
	    {
		if (!x || x == дг)
		{   x = дг;
		    return;
		}
	    }

	    // Increase size of delegates[]
	    auto len = m.delegates.length;
	    auto startlen = len;
	    if (len == 0)
	    {
		len = 4;
		auto p = кразмести((проц delegate(Object)).sizeof, len);
		if (!p)
		    _d_OutOfMemory();
		m.delegates = (cast(проц delegate(Object)*)p)[0 .. len];
	    }
	    else
	    {
		len += len + 4;
		auto p = cidrus.перемести(m.delegates.ptr, (проц delegate(Object)).sizeof * len);
		if (!p)
		    _d_OutOfMemory();
		m.delegates = (cast(проц delegate(Object)*)p)[0 .. len];
		m.delegates[startlen .. len] = null;
	    }
	    m.delegates[startlen] = дг;
	}
 }
 export final проц уведомиРег(проц delegate(Объект) дг){notifyRegister(дг);}
    /* **
     * Удаляет делегата дг из списка уведомления.
     * This is only for use by library developers, as it will need to be
     * redone if weak pointers are added or a moving gc is developed.
     */
   export final проц notifyUnRegister(проц delegate(Object) дг)
    {
	synchronized (this)
	{
	    .Monitor* m = cast(.Monitor*)(cast(ук*)this)[1];
	    foreach (inout x; m.delegates)
	    {
		if (x == дг)
		    x = null;
	    }
	}
    }
	export final проц уведомиОтрег(проц delegate(Объект) дг){notifyUnRegister(дг);}
    /******
     * Создает экземпляр класса, заданного посредством classname.
     * У этого класса либо не должно быть конструкторов,
     * либо дефолтного конструктора.
     * Возвращает:
     *	null if failed
     */
    static Object factory(ткст classname)
    {
	auto ci = ИнфОКлассе.find(classname);
	if (ci)
	{
	    return ci.создай();
	}
	return null;
    }
	
	export static Объект фабрика(ткст имякласса){return factory(имякласса);}
	
}
alias Object Объект;

ИнфОКлассе дайИоК(Объект о){return о.classinfo ;}
//////////////////////////////////////////////////////////////////////

  export extern (C) проц _d_notify_release(Object o)
	{
		//эхо("_d_notify_release(o = %p)\n", o);
		Monitor* m = cast(Monitor*)(cast(ук*)o)[1];
		if (m.delegates.length)
		{
		auto dgs = m.delegates;
		synchronized (o)
		{
			dgs = m.delegates;
			m.delegates = null;
		}

		foreach (дг; dgs)
		{
			if (дг)
			{	//эхо("calling дг = %llx (%p)\n", дг, o);
			дг(o);
			}
		}

		освободи(dgs.ptr);
		}
	}


/**
 * All irrecoverable exceptions should be derived from class Error.
 */
 private extern(Windows)
{
BOOL SetConsoleTextAttribute(HANDLE конс, DWORD атр );
}

export extern (D) class Exception : Object
{

alias SetConsoleTextAttribute УстановиАтрибутыТекстаКонсоли;

extern(C)
{
	ткст      msg = "Исключение Динрус";
    ткст      file = "Неизвестно";
    т_мера  line = т_мера.init;  // дол would be better
    TraceInfo   info;
    Exception   next;
	бул выведено = нет;
	
	alias msg сооб;
	alias file файл;
	alias line строка;
	alias info инфо;
	alias next следщ;
}
	
	export:	
    struct FrameInfo
	{
	export:
	
        дол  line;
		alias line строка;
		
        т_мера iframe;
		alias iframe икадр;
		
        ptrdiff_t offsetSymb;
		alias offsetSymb симвСмещ;
		
        т_мера baseSymb;
		alias baseSymb симвОвы;
		
        ptrdiff_t offsetImg;
		alias offsetImg обрСмещ;
		
        т_мера baseImg;
		alias baseImg обрОвы;
		
        т_мера address;
		alias address адрес;
		
        ткст file;
		alias file файл;
		
        ткст func;
		alias func функц;
		
        ткст extra;
		alias extra экстра;
		
        bool exactAddress;
		 alias exactAddress точныйАдрес;
		
        bool internalFunction;
		 alias internalFunction внутрФункция;
		 
        alias проц function(FrameInfo*,проц delegate(char[])) FramePrintHandler, ОбработчикПечатиКадра;
		
        static ОбработчикПечатиКадра defaultFramePrintingFunction;
		alias defaultFramePrintingFunction дефФцияПечатиКадра;
		
        проц writeOut(проц delegate(char[])sink){

            if (дефФцияПечатиКадра){
                дефФцияПечатиКадра(this,sink);
            } else {
                char[26] buf;
                //auto len=snprintf(buf.ptr,26,"[%8zx]",address);
                //sink(buf[0..len]);
                //len=snprintf(buf.ptr,26,"%8zx",baseImg);
                //sink(buf[0..len]);
                //len=snprintf(buf.ptr,26,"%+td ",offsetImg);
                //sink(buf[0..len]);
                //while (++len<6) sink(" ");
                if (func.length) {
                    sink(func);
                } else {
                    sink("???");
                }
                for (т_мера i=func.length;i<80;++i) sink(" ");
                //len=snprintf(buf.ptr,26," @%zx",baseSymb);
                //sink(buf[0..len]);
                //len=snprintf(buf.ptr,26,"%+td ",offsetSymb);
                //sink(buf[0..len]);
                if (extra.length){
                    sink(extra);
                    sink(" ");
                }
                sink(file);
                sink(":");
                sink(std.string.ulongToUtf8(buf, cast(т_мера) line));
            }
        }
		проц выпиши(проц delegate(ткст) синк){writeOut(синк);}
        
        проц clear(){
            line=0;
            iframe=-1;
            offsetImg=0;
            baseImg=0;
            offsetSymb=0;
            baseSymb=0;
            address=0;
            exactAddress=true;
            internalFunction=false;
            file=null;
            func=null;
            extra=null;
        }
		проц сотри(){clear();}
		
    }
	
    interface TraceInfo
    {
	export:
	
        цел opApply( цел delegate( ref FrameInfo fInfo ) );
        проц writeOut(проц delegate(char[])sink);
		
	alias writeOut выпиши;
    }
	

	private проц окрась()
	{
		УстановиАтрибутыТекстаКонсоли(КОНСОШ, 0x0004|0x0008);
	}
	
	проц сбрось()
	{
	УстановиАтрибутыТекстаКонсоли(КОНСОШ, 0x0001|0x0002|0x0008); runtime.смОсвободи(cast(ук) this);
	}

	
    this( ткст msg, ткст file, дол  line, Exception следщ, TraceInfo info )
    {
        // main constructor, breakpoint this if you want...
		окрась();
        this.msg = msg;
        this.next = следщ;
        this.file = file;
        this.line = cast(т_мера)line;
        this.info = info;
		
//debug  {

if(!выведено)
{
		this.выведи();
		wchar[] soob = toUTF16(фм("Класс Исключения: "~this.classinfo.name~"\nСообщение: "~msg~"\nФайл: "~file~"\nСтрока:"~std.string.toString(line)~"\nСообщение Системы: "~СистОШ.последнСооб));
        ОкноСооб(null, soob, "Исключение Динрус", ПСооб.Ошибка|ПСооб.Поверх);
		сбросьЦветКонсоли();	
		выведено = да;
} 
		
		//}
		
    }

    this( ткст msg, Exception следщ=null )
    {
		this(msg," ",0,null, ртСоздайКонтекстСледа(null));
    }

    this( ткст msg, ткст file, дол  line, Exception следщ=null )
    {	
		this(msg,file,cast(т_мера) line,null,ртСоздайКонтекстСледа(null));
    }
	override проц print()
    {
		{
		УстановиАтрибутыТекстаКонсоли(КОНСОШ, 0x0002|0x0008);
		ошибнс(фм("\n\nВНИМАНИЕ! Произошло исключение со следующим контекстом:"));
		окрась();		
		if (file.length>0 || line!=0)
        {
            char[25]buf;
			ошибнс(фм("\n\n"~this.classinfo.name~"@"~file~"("~std.string.ulongToUtf8(buf, line)~"):\n "~this.msg~"\r\n"));	
        }
        else
        {
           ошибнс(фм(this.classinfo.name~":\n "~this.msg~"\r\n"));
        }
		УстановиАтрибутыТекстаКонсоли(КОНСВЫВОД, 0x0001|0x0002|0x0008);	
		//сбрось();		
		}	
	}
	override проц выведи(){print();}
	
	
    override ткст toString()
    {
        return this.classinfo.name;
	}
	override ткст вТкст(){return toString();}
	
	/+
    проц writeOutMsg(проц delegate(char[])sink)
	{
	
	//	wchar[] soob =cast(wchar[])(toUTF16(this.msg)~"\n"~toUTF16(СистОШ.последнСооб)~"\nФайл: "~toUTF16(file)~"\nСтрока:"~toUTF16(std.string.toString(line)));
        sink(фм(this.msg~"\n"~СистОШ.последнСооб~"\nФайл: "~file~"\nСтрока:"~std.string.toString(line)));		
		//ОкноСооб(null, soob, "Исключение Динрус: "~toUTF16(this.classinfo.name), ПСооб.Ошибка|ПСооб.Поверх);			
	
   }
	проц выпишиСооб(проц delegate(ткст) синк){writeOutMsg(синк);}
	
	
    проц writeOut(проц delegate(char[])sink){
	
        if (file.length>0 || line!=0)
        {
            char[25]buf;
			sink("\n\n");
            sink(this.classinfo.name~"@"~file~"("~std.string.ulongToUtf8(buf, line)~"): ");
            sink(this.msg);
            sink("\n");
			
        }
        else
        {
           sink(this.classinfo.name~": ");
           sink(this.msg);
           sink("\n");
        }
        if (info)
        {
            sink("----------------\n");
            info.writeOut(sink);//kkkkkkkkkk
        }
        if (next){
            sink("\n++++++++++++++++\n");
            next.writeOut(sink);//kkkkkkkk MSG----
        }
    }
	проц выпиши(проц delegate(ткст) синк){ writeOut(синк);}
	+/
alias FrameInfo ИнфОКадре;
alias TraceInfo ИнфОСледе;
}
alias Exception Исключение;
////////////////////////////////////////////////////
/+
export extern (D) class Error : Exception
{
export:

    Error next;
	ткст msg;
	
	override проц print()
    {
	скажинс(фм("%s\n", msg));
	//ОкноСооб(null, cast(wchar[]) (toUTF16(msg)), "Ошибка Динрус: "~toUTF16(this.classinfo.name), ПСооб.Ошибка|ПСооб.Поверх);
	
    }
	override проц выведи(){print();}
	
	override ткст toString() { return msg; }
	override ткст вТкст(){return toString();}
    /**
     * Конструктор; msg - сообщение, описывающее исключение.
     */
	this(ткст msg){     
	super(msg," ",0, super.next,ртСоздайКонтекстСледа(null));
	this.msg = msg;	
	this.next = cast(Error) super.next;
    }

    this(ткст msg, Error следщ)
    {	
	super(msg," ",0, cast(Исключение) следщ,ртСоздайКонтекстСледа(null));
	this.msg = msg;
	this.next = следщ;
    }
}

alias Error Ошибка;
+/
///////////////////////////////////////////////////////////////////////
/**
 * Информация об интерфейсе.
 * При доступе к объекту через интерфейс,  Interface* появляется в виде
 * первой записи в его vtbl (виртуальной таблице).
 */
export extern (C) struct Interface
{
export:
   extern(C) extern ИнфОКлассе classinfo;	/// .classinfo для данного интерфейса (а не для включающего класса)
	alias classinfo классинфо;
	
   extern(C) extern ук[] vtbl;	
	alias vtbl вирттаб;
	
   extern(C) extern цел offset;			/// смещение к Интерфейсу 'this' от Объекта 'this'	
	alias offset смещение;
}
alias Interface Интерфейс;

//////////////////////////////////////////////////////////////////////
/**
 * Рантаймная информация о типах класса. Может быть получена для любого типа класса
 * или экземпляра через свойство .classinfo.
 * Указатель на this появляется как первая запись в vtbl[] класса.
 */

alias ClassInfo ИнфОКлассе;
export extern (D) class ClassInfo //: Object
{
export:
    extern(C) extern байт[] init;		/** статический инициализатор класса
				 * (init.length даёт размер класса в байтах)
				 */
	alias init иниц;
	байт[] getSetInit(байт[] init = null){if(init) this.иниц = init; return this.init;}
	байт[] дайУстИниц(байт[] init = null){if(init) this.иниц = init; return this.init;}
	
   extern(C) extern ткст name;		/// имя класса
	alias name имя;
	ткст getSetName(ткст name = null){if(name) this.имя = name; return this.name;}
	ткст дайУстИмя(ткст name = null){if(name) this.имя = name; return this.name;}	
	
   extern(C) extern ук [] vtbl;		/// таблица указателей на виртуальные функции
	alias vtbl вирттаб;
	ук[] getSetVtbl(ук[] vtbl){if(vtbl) this.вирттаб = vtbl; return this.vtbl;}
	ук[] дайУстВирттаб(ук[] vtbl){if(vtbl) this.вирттаб = vtbl; return this.vtbl;}
	
    extern(C) extern Interface[] interfaces;	/// реализуемые данным классом интерфейсы
	alias interfaces интерфейсы;	
	Интерфейс[] getSetInterfaces(Интерфейс[] interfaces = null){if(interfaces) this.интерфейсы = interfaces; return this.interfaces;}
	Интерфейс[] дайУстИнтерфейсы(Интерфейс[] interfaces = null){if(interfaces) this.интерфейсы = interfaces; return this.interfaces;}
	
    extern(C) extern ИнфОКлассе base;		/// класс-основа
	alias base основа;	
	ИнфОКлассе getSetBase(ИнфОКлассе base = null){if(base) this.основа = base; return this.base;}
	ИнфОКлассе дайУстОву(ИнфОКлассе base = null){if(base) this.основа = base; return this.base;}
	
   extern(C) extern ук destructor;
	alias destructor деструктор;
	ук getSetDestructor(ук destructor = null){if(destructor) this.деструктор = destructor; return this.деструктор;}
	ук дайУстДестр(ук destructor = null){if(destructor) this.деструктор = destructor; return this.destructor;}
	
    проц (*classInvariant)(Object);
	
    extern(C) extern бцел flags;
	alias flags флаги;
	//	1:			// IUnknown
    //	2:			// has no possible pointers into GC memory
    //	4:			// has offTi[] member
    //	8:			// has constructors
    //	32:			// has typeinfo
	бцел getSetFlags(бцел flags = бцел.init){if(flags) this.флаги = flags; return this.флаги;}    
	
   extern(C) extern ук deallocator;
	alias deallocator выместитель;
	ук getSetDeallocator(ук deallocator = null){if(deallocator) this.выместитель = deallocator; return this.выместитель;}
	ук дайУстДеаллок(ук deallocator = null){if(deallocator) this.выместитель = deallocator; return this.deallocator;}
	
    extern(C) extern OffsetTypeInfo[] offTi;
	alias offTi смТи;
	OffsetTypeInfo[] getSetOffTi(OffsetTypeInfo[] offTi = null){if(offTi) this.смТи = offTi; return this.смТи;}
	OffsetTypeInfo[] дайУстСмТи(OffsetTypeInfo[] offTi = null){if(offTi) this.смТи = offTi; return this.offTi;}
	
    проц function(Object) defaultConstructor;	// default Constructor
	
   extern(C) extern TypeInfo typeinfo;
    alias typeinfo инфотипе;
	ИнфОТипе getSetTypeinfo(ИнфОТипе typeinfo = null){if(typeinfo) this.инфотипе = typeinfo; return this.инфотипе;}
	ИнфОТипе дайУстИнфОТипе(ИнфОТипе typeinfo = null){if(typeinfo) this.инфотипе = typeinfo; return this.typeinfo;}
	
	/*************
     * Ищет во всех модулях ИнфОКлассе, соответствующее classname.
     * Возвращает: null if not found
     */
    static ИнфОКлассе find(ткст classname)
    {
	foreach (m; ModuleInfo.модули())
	{
	    //writefln("module %s, %d", m.name, m.localClasses.length);
	    foreach (c; m.localClasses)
	    {
		//writefln("\tclass %s", c.name);
		if (c.name == classname)
		    return c;
	    }
	}
	return null;
    }

	static ИнфОКлассе найди (ткст имякласса){ return find(имякласса);}
	
    /********************
     * Создаёт экземпляр Объекта, представленного 'this'.
     * Возвращает:
     *	созданный Объект, или null, если Object не
     *	имеет конструктора по умолчанию
     */
    /*Object создай()
    {
	if (flags & 8 && !defaultConstructor)
	    return null;
	Object o = _d_newclass(this);
	if (flags & 8 && defaultConstructor)
	{
	    defaultConstructor(o);
	}
	return o;
    }*/
	Object create()
    {
        if (flags & 8 && defaultConstructor is null)
            return null;
        Object o = _d_newclass(this);
        if (flags & 8 && defaultConstructor !is null)
        {
            Object delegate() ctor;
            ctor.ptr = cast(ук)o;
            ctor.funcptr = cast(Object function())defaultConstructor;
            return ctor();
        }
        return o;
    }

	Объект создай(){return create();}
}

private import std.string;
///////////////////////////////////////////////////////////////////////////////////
/**
 * Массив из пар, содержащих смещение и тип информации
 * для каждого члена агрегата.
 */
export struct OffsetTypeInfo
{
	export:
		
   extern(C) extern т_мера offset;	/// Смещение члена от начала объекта
	alias offset смещение;
	
   extern(C) extern TypeInfo ti;	/// ИнфОТипе для данного члена
	alias ti иот;
}
alias OffsetTypeInfo ИнфОТипеИСмещ;

/////////////////////////////////////////////////////////////////////////////
/**
 * Рантаймная информация о типе.
 * Может быть получена для любого типа с помощью
 * <a href="../expression.html#typeidexpression">TypeidExpression</a>.
 */
 alias TypeInfo ИнфОТипе; 
export extern (D) class TypeInfo
{
export:

    hash_t toHash()
    {	        
	auto data = this.toString();
    return hashOf(data.ptr, data.length);
    }	
	т_хэш вХэш(){return toHash();}
	

    override цел opCmp(Object o)
    {
	if (this is o)
	    return 0;
	TypeInfo ti = cast(TypeInfo)o;
	if (ti is null)
	    return 1;
	return std.string.cmp(this.toString(), ti.toString());
    }	

    override цел opEquals(Object o)
    {
	/* Экземпляры TypeInfo являются синглтонами, но могут существовать дубликаты
	 * по DLL. След., сравнения на совпадение имени достаточно.
	 */
	if (this is o)
	    return 1;
	TypeInfo ti = cast(TypeInfo)o;
	return cast(цел)(ti && this.toString() == ti.toString());
    }

    /// Возвращает хэш экземпляра типа.
    hash_t getHash(in ук p) { return cast(hash_t)p; }
	т_хэш дайХэш(in ук п){ return getHash(п);}
	
    /// Сравнивает два экземпляра на равенство.
    цел equals(in ук p1, in ук p2) { return cast(цел)(p1 == p2); }
	цел равны(in ук п1, in ук п2){return equals(п1, п2);}
	

    /// Сравнивает два экземпляра на &lt;, == или &gt;.
    цел compare(in ук p1, in ук p2) { return 0; }
	цел сравни(in ук п1, in ук п2){return compare(п1, п2);}
	
    /// Возвращает размер типа.
    т_мера tsize() { return 0; }
	т_мера тразм(){return tsize();}	
	
    /// Меняет местами два экземпляра типа.
    проц swap(ук p1, ук p2)
    {
	т_мера n = tsize();
	for (т_мера i = 0; i < n; i++)
		{   байт t;

			t = (cast(байт *)p1)[i];
			(cast(байт *)p1)[i] = (cast(байт *)p2)[i];
			(cast(байт *)p2)[i] = t;
		}
    }
	проц поменяй(ук п1, ук п2){swap(п1, п2);}
	

    /// Получить ИнфОТипе для следующего типа 'следщ', в соответствии с данным типом,
    /// null если нет.
    TypeInfo next() { return null; }
	ИнфОТипе следщ(){return next();}
	
    /// Возвращает дефолтный инициализатор, null, если дефолт инициализируется в 0
    проц[] init() { return null; }
	проц[] иниц(){return init();}

    /// Получить флаги типа: 1 означает, что СМ должен сканировать указатели
    бцел flags() { return 0; }
	бцел флаги(){return flags();}

    /// Get type information on the contents of the type; null if not available
    OffsetTypeInfo[] offTi() { return null; }
	ИнфОТипеИСмещ[] смТи(){return offTi();}
		
}
//////////////////////////////////////////////////////////////
export extern (D) class TypeInfo_Typedef : TypeInfo
{
export:

    override ткст toString() { return name; }
	override ткст вТкст(){return toString();}
	

    override цел opEquals(Object o)
    {   TypeInfo_Typedef c;

	return cast(цел)
		(this is o ||
		((c = cast(TypeInfo_Typedef)o) !is null &&
		 this.name == c.name &&
		 this.base == c.base));
    }

    override hash_t getHash(in ук p) { return super.getHash(p); }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	
    override цел equals(in ук p1, in ук p2) { return super.equals(p1, p2); }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}
	
    override цел compare(in ук p1, in ук p2) { return super.compare(p1, p2); }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}
	
    override т_мера tsize() { return tsize(); }
	override т_мера тразм(){return tsize();}
	
    override проц swap(ук p1, ук p2) { return super.swap(p1, p2); }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}
	
    override TypeInfo next() { return super.next(); }
	override ИнфОТипе следщ(){return next();}
	
   override  бцел flags() { return super.flags(); }
   override бцел флаги(){return flags();}
   
    override проц[] init() { return m_init.length ? m_init : init(); }
	override проц[] иниц(){return init();}

    extern(C) extern TypeInfo base;
	alias base основа;
	ИнфОТипе getSetBase(ИнфОТипе base = null){if(base) this.основа = base; return this.base;}
	ИнфОТипе дайУстОву(ИнфОТипе base = null){if(base) this.основа = base; return this.base;}
	
    extern(C) extern ткст name;
	alias name имя;
	ткст getSetName(ткст name = null){if(name) this.имя = name; return this.name;}
	ткст дайУстИмя(ткст name = null){if(name) this.имя = name; return this.name;}
	
    extern(C) extern проц[] m_init;
}
alias TypeInfo_Typedef ТипТипдеф;
///////////////////////////////////////////

export extern (D) class TypeInfo_Enum : TypeInfo_Typedef
{

}
alias TypeInfo_Enum  ТипПеречень;
//////////////////////////////////////////

export extern (D) class TypeInfo_Pointer : TypeInfo
{
export:

    override ткст toString() { return m_next.toString() ~ "*"; }
	override ткст вТкст(){return toString();}
	

    override цел opEquals(Object o)
    {   TypeInfo_Pointer c;

	return this is o ||
		((c = cast(TypeInfo_Pointer)o) !is null &&
		 this.m_next == c.m_next);
    }
	

    hash_t getHash(ук p)
    {
        return cast(бцел)*cast(ук  *)p;
    }
	т_хэш дайХэш(ук п){return getHash(п);}
	

    цел equals(ук p1, ук p2)
    {
        return cast(цел)(*cast(ук  *)p1 == *cast(ук  *)p2);
    }
	цел равны(ук п1, ук п2){return equals(п1, п2);}
	
	
    цел compare(ук p1, ук p2)
    {
	if (*cast(ук  *)p1 < *cast(ук  *)p2)
	    return -1;
	else if (*cast(ук  *)p1 > *cast(ук  *)p2)
	    return 1;
	else
	    return 0;
    }
	цел сравни(ук п1, ук п2){return compare(п1, п2);}
	

    override т_мера tsize()
    {
	return (ук ).sizeof;
    }
	override т_мера тразм(){return tsize();}
	

    override проц swap(ук p1, ук p2)
    {	ук  tmp;
	tmp = *cast(ук*)p1;
	*cast(ук*)p1 = *cast(ук*)p2;
	*cast(ук*)p2 = tmp;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}
	

    override TypeInfo next() { return m_next; }
	override ИнфОТипе следщ(){return next();}
	
	
    override бцел flags() { return 1; }
	override бцел флаги(){return flags();}
	

   extern(C) extern TypeInfo m_next;
}
alias TypeInfo_Pointer ТипУказатель;
///////////////////////////////////////////

export extern (D) class TypeInfo_Array : TypeInfo
{
export:

    override ткст toString() { return value.toString() ~ "[]"; }
	override ткст вТкст(){return toString();}

    override цел opEquals(Object o)
    {   TypeInfo_Array c;

	return cast(цел)
	       (this is o ||
		((c = cast(TypeInfo_Array)o) !is null &&
		 this.value == c.value));
    }

    hash_t getHash(ук p)
    {	т_мера разм = value.tsize();
	hash_t hash = 0;
	проц[] a = *cast(проц[]*)p;
	for (т_мера i = 0; i < a.length; i++)
	    hash += value.getHash(a.ptr + i * разм) * 11;
        return hash;
    }
	override т_хэш дайХэш(ук п){return getHash(п);}
	

    цел equals(ук p1, ук p2)
    {
	проц[] a1 = *cast(проц[]*)p1;
	проц[] a2 = *cast(проц[]*)p2;
	if (a1.length != a2.length)
	    return 0;
	т_мера разм = value.tsize();
	for (т_мера i = 0; i < a1.length; i++)
		{
			if (!value.equals(a1.ptr + i * разм, a2.ptr + i * разм))
			return 0;
		}
        return 1;
    }
	цел равны(ук п1, ук п2){return equals(п1, п2);}
	

    цел compare(ук p1, ук p2)
    {
	проц[] a1 = *cast(проц[]*)p1;
	проц[] a2 = *cast(проц[]*)p2;
	т_мера разм = value.tsize();
	т_мера len = a1.length;

        if (a2.length < len)
            len = a2.length;
        for (т_мера u = 0; u < len; u++)
        {
            цел результат = value.compare(a1.ptr + u * разм, a2.ptr + u * разм);
            if (результат)
                return результат;
        }
        return cast(цел)a1.length - cast(цел)a2.length;
    }
	цел сравни(ук п1, ук п2){return compare(п1, п2);}
	
	
    override т_мера tsize()
    {
	return (проц[]).sizeof;
    }
	override т_мера тразм(){return tsize();}
	

    override проц swap(ук p1, ук p2)
    {	проц[] tmp;
	tmp = *cast(проц[]*)p1;
	*cast(проц[]*)p1 = *cast(проц[]*)p2;
	*cast(проц[]*)p2 = tmp;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}
	

    extern(C) extern TypeInfo value;

    override TypeInfo next()
    {
	return value;
    }
	override ИнфОТипе следщ(){return next();}
	

    override бцел flags() { return 1; }
	override бцел флаги(){return flags();}
}
alias TypeInfo_Array ТипМассив;

/////////////////////////////////////////////////////////////////////////

export extern (D) class TypeInfo_StaticArray : TypeInfo
{
export:

    override ткст toString()
		{
		//return value.toString() ~ "[" ~ std.string.toString(len) ~ "]";
		char [10] tmp = void;
			return value.toString() ~ "[" ~ std.string.intToUtf8(tmp, len) ~ "]";
		}
	override ткст вТкст(){return toString();}
	

    override цел opEquals(Object o)
		{   TypeInfo_StaticArray c;

		return cast(цел)
			   (this is o ||
			((c = cast(TypeInfo_StaticArray)o) !is null &&
			 this.len == c.len &&
			 this.value == c.value));
		}

   /* hash_t getHash(in ук p)
    {	т_мера разм = value.tsize();
	hash_t hash = 0;
	for (т_мера i = 0; i < len; i++)
	    hash += value.getHash(p + i * разм);
        return hash;
    }*/
	override hash_t getHash(in ук  p)
		{
			т_мера разм = value.tsize();
			hash_t hash = len;
			for (т_мера i = 0; i < len; i++)
				hash = rt_hash_combine(value.getHash(p + i * разм),hash);
			return hash;
		}
	override т_хэш дайХэш(in ук п){return getHash(п);}
	
	
    override цел equals(in ук p1, in ук p2)
		{
		т_мера разм = value.tsize();

			for (т_мера u = 0; u < len; u++)
			{
			if (!value.equals(p1 + u * разм, p2 + u * разм))
			return false;//0
			}
			return true; //1;
		}
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
		{
		т_мера разм = value.tsize();

			for (т_мера u = 0; u < len; u++)
			{
				цел результат = value.compare(p1 + u * разм, p2 + u * разм);
				if (результат)
					return результат;
			}
			return 0;
		}
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}
	

    override т_мера tsize()
		{
		return len * value.tsize();
		}
	override т_мера тразм(){return tsize();}
	

    override проц swap(ук p1, ук p2)
    {	ук  tmp;
	т_мера разм = value.tsize();
	ббайт[16] buffer;
	ук  pbuffer;

	if (разм < buffer.sizeof)
	    tmp = buffer.ptr;
	else
	    tmp = pbuffer = (new проц[разм]).ptr;

	for (т_мера u = 0; u < len; u += разм)
	{   т_мера o = u * разм;
	    копирбуф(tmp, p1 + o, разм);
	    копирбуф(p1 + o, p2 + o, разм);
	    копирбуф(p2 + o, tmp, разм);
	}
	if (pbuffer)
	    delete pbuffer;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override проц[] init() { return value.init(); }
	override проц[] иниц(){return init();}
	
    override TypeInfo next() { return value; }
	override ИнфОТипе следщ(){return next();}
	
    override бцел flags() { return value.flags(); }
	override бцел флаги(){return flags();}

   extern(C) extern TypeInfo value;
	alias value значение;
	ИнфОТипе getSetValue(ИнфОТипе value = null){if(value) this.значение = value; return this.value;}
	ИнфОТипе дайУстЗначение(ИнфОТипе value = null){if(value) this.значение = value; return this.value;}
	
    extern(C) extern т_мера len;
	alias len длин;
	т_мера getSetLength(т_мера len = т_мера.init){if(len) this.длин = len; return this.len;}
	т_мера дайУстДлину(т_мера len = т_мера.init){if(len) this.длин = len; return this.len;}
}
alias TypeInfo_StaticArray ТипСтатичМассив;

////////////////////////////////////////////////////////////////////////////////////////////
export extern (D) class TypeInfo_AssociativeArray : TypeInfo
{
export:

    override ткст toString()
    {
        return next.toString() ~ "[" ~ key.toString() ~ "]";
    }
	override ткст вТкст(){return toString();}
	

    override /*цел*/ цел opEquals(Object o)
    {
        TypeInfo_AssociativeArray c;
        return this is o ||
                ((c = cast(TypeInfo_AssociativeArray)o) !is null &&
                 this.key == c.key &&
                 this.next == c.next);
    }

    override hash_t getHash(in ук  p)
    {
        т_мера разм = value.tsize();
        hash_t hash = разм;
        AA aa=*cast(AA*)p;
        т_мера keysize=key.tsize();
        цел res=_aaApply2(aa, keysize, cast(dg2_t) delegate цел(ук k, ук v){
            hash+=rt_hash_combine(key.getHash(k),value.getHash(v));
            return 0;
        });
        return hash;
    }
	override т_хэш дайХэш(in ук п){return getHash(п);}
	

    override т_мера tsize()
    {
        return (сим[цел]).sizeof;
    }
	override т_мера тразм(){return tsize();}
	
	
    override цел equals(in ук  p1, in ук  p2)
    {
        AA a=*cast(AA*)p1;
        AA b=*cast(AA*)p2;
        if (cast(ук )a.a==cast(ук )b.a) return true;
        т_мера l1=_aaLen(a);
        т_мера l2=_aaLen(b);
        if (l1!=l2) return false;
        т_мера keysize=key.tsize();
        цел same=true;
        цел res=_aaApply2(a, keysize, cast(dg2_t) delegate цел(ук k, ук v){
            ук  v2=_aaGetRvalue(b, key, value.tsize(), k);
            if (v2 is null || !value.equals(v,v2)) {
                same=false;
                return 1;
            }
            ++l1;
            return 0;
        });
        return same;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}
	

    override цел compare(in ук  p1, in ук  p2)
    {
        throw new Exception("Не подлежит сравнению",__FILE__,__LINE__);
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}
	

   override TypeInfo next() { return value; }
   override ИнфОТипе следщ(){return next();}
   
    override бцел flags() { return 1; }
	override бцел флаги(){return flags();}

   extern(C) extern TypeInfo value;
	alias value значение;
	ИнфОТипе getSetValue(ИнфОТипе value = null){if(value) this.значение = value; return this.value;}
	ИнфОТипе дайУстЗначение(ИнфОТипе value = null){if(value) this.значение = value; return this.value;}
	
   extern(C) extern TypeInfo key;
	alias key ключ;
	ИнфОТипе getSetKey(ИнфОТипе key = null){if(key) this.key = key; return this.key;}
	ИнфОТипе дайУстКлюч(ИнфОТипе key = null){if(value) this.key = key; return this.key;}
}
alias TypeInfo_AssociativeArray  ТипАссоцМассив;
////////////////////////////////////////////////////////////////////////////////////////////

export extern (D) class TypeInfo_Function : TypeInfo
{
export:

    override ткст toString()
    {
	return next.toString() ~ "()";
    }
	override ткст вТкст(){return toString();}
	

    override цел opEquals(Object o)
    {   TypeInfo_Function c;

	return this is o ||
		((c = cast(TypeInfo_Function)o) !is null &&
		 this.next == c.next);
    }

    // BUG: требуется добавить остальные функции

    override т_мера tsize()
    {
	return 0;	// размера для функций нет
    }
	override т_мера тразм(){return tsize();}	

   extern(C) extern TypeInfo next;
	alias next следщ;
	ИнфОТипе getSetNext(ИнфОТипе следщ = null){if(следщ) this.next = следщ; return this.next;}
	ИнфОТипе дайУстСледщ(ИнфОТипе следщ = null){if(следщ) this.next = следщ; return this.next;}
	
}
alias TypeInfo_Function ТипФункция;
/////////////////////////////////////////////////////////////////////////////////////

export extern (D) class TypeInfo_Delegate : TypeInfo
{
export:

    override ткст toString()
    {
	return next.toString() ~ " delegate()";
    }
	override ткст вТкст(){return toString();}
	

    override цел opEquals(Object o)
    {   TypeInfo_Delegate c;

	return this is o ||
		((c = cast(TypeInfo_Delegate)o) !is null &&
		 this.next == c.next);
    }

    // BUG: need to add the rest of the functions

    override т_мера tsize()
    {	alias цел delegate() дг;
	return дг.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override бцел flags() { return 1; }
	 override бцел флаги(){return flags();}

    extern(C) extern TypeInfo next;
	alias next следщ;
	ИнфОТипе getSetNext(ИнфОТипе следщ = null){if(следщ) this.next = следщ; return this.next;}
	ИнфОТипе дайУстСледщ(ИнфОТипе следщ = null){if(следщ) this.next = следщ; return this.next;}
}
alias TypeInfo_Delegate ТипДелегат;
//////////////////////////////////////////////////////////////////////////////////////

export extern (D) class TypeInfo_Class : TypeInfo
{
export:

    override ткст toString() { return info.name; }
	override ткст вТкст(){return toString();}

    override цел opEquals(Object o)
    {   TypeInfo_Class c;

	return this is o ||
		((c = cast(TypeInfo_Class)o) !is null &&
		 this.info.name == c.classinfo.name);
    }

    override hash_t getHash(in ук p)
	/*in
	{
		assert(p, "Получен нулевой указатель");
	}
	body*/
    {
				Object o = *cast(Object*)p;
				return o ? o.toHash() : 0;
			
	 }

	override т_хэш дайХэш(in ук п){return getHash(п);}
	

    цел equals(ук p1, ук p2)
    {
	Object o1 = *cast(Object*)p1;
	Object o2 = *cast(Object*)p2;

	return (o1 is o2) || (o1 && o1.opEquals(o2));
    }
	цел равны(ук п1, ук п2){return equals(п1, п2);}
	

    цел compare(ук p1, ук p2)
    {
	Object o1 = *cast(Object*)p1;
	Object o2 = *cast(Object*)p2;
	цел c = 0;

	// Regard null references as always being "less than"
	if (o1 !is o2)
	{
	    if (o1)
	    {	if (!o2)
		    c = 1;
		else
		    c = o1.opCmp(o2);
	    }
	    else
		c = -1;
	}
	return c;
    }
	цел сравни(ук п1, ук п2){return compare(п1, п2);}
	

    override т_мера tsize()
    {
	return Object.sizeof;
    }
	override т_мера тразм(){return tsize();}
	

    override бцел flags() { return 1; }
	 override бцел флаги(){return flags();}

    override OffsetTypeInfo[] offTi()
    {
	return (info.flags & 4) ? info.offTi : null;
    }
	override ИнфОТипеИСмещ[] смТи(){return offTi();}
	

    extern(C) extern ИнфОКлассе info;
	alias info инфо;
	ИнфОКлассе getSetInfo(ИнфОКлассе info = null){if(info) this.info = info; return this.info;}
	ИнфОКлассе дайУстИнфо(ИнфОКлассе info = null){if(info) this.info = info; return this.info;}
}
alias TypeInfo_Class ТипКласс;
///////////////////////////////////////////////////////////////////////////////////////////
export extern (D) class TypeInfo_Interface : TypeInfo
{
export:

    override ткст toString() { return info.name; }
	override ткст вТкст(){return toString();}

    override цел opEquals(Object o)
    {   TypeInfo_Interface c;

	return this is o ||
		((c = cast(TypeInfo_Interface)o) !is null &&
		 this.info.name == c.classinfo.name);
    }

    hash_t getHash(ук p)
    {
	Interface* pi = **cast(Interface ***)*cast(ук*)p;
	Object o = cast(Object)(*cast(ук*)p - pi.offset);
	assert(o);
	return o.toHash();
    }
	т_хэш дайХэш(ук п){return getHash(п);}
	

    цел equals(ук p1, ук p2)
    {
	Interface* pi = **cast(Interface ***)*cast(ук*)p1;
	Object o1 = cast(Object)(*cast(ук*)p1 - pi.offset);
	pi = **cast(Interface ***)*cast(ук*)p2;
	Object o2 = cast(Object)(*cast(ук*)p2 - pi.offset);

	return o1 == o2 || (o1 && o1.opCmp(o2) == 0);
    }
	цел равны(ук п1, ук п2){return equals(п1, п2);}
	

    цел compare(ук p1, ук p2)
    {
	Interface* pi = **cast(Interface ***)*cast(ук*)p1;
	Object o1 = cast(Object)(*cast(ук*)p1 - pi.offset);
	pi = **cast(Interface ***)*cast(ук*)p2;
	Object o2 = cast(Object)(*cast(ук*)p2 - pi.offset);
	цел c = 0;

	// Regard null references as always being "less than"
	if (o1 != o2)
	{
	    if (o1)
	    {	if (!o2)
		    c = 1;
		else
		    c = o1.opCmp(o2);
	    }
	    else
		c = -1;
	}
	return c;
    }
	цел сравни(ук п1, ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
	return Object.sizeof;
    }
	override т_мера тразм(){return tsize();}
	

    override бцел flags() { return 1; }
	 override бцел флаги(){return flags();}

   extern(C) extern ИнфОКлассе info;
	alias info инфо;
	ИнфОКлассе getSetInfo(ИнфОКлассе info = null){if(info) this.info = info; return this.info;}
	ИнфОКлассе дайУстИнфо(ИнфОКлассе info = null){if(info) this.info = info; return this.info;}
}
alias TypeInfo_Interface ТипИнтерфейс;
///////////////////////////////////////////////////////////////////////////////////

export extern (D) class TypeInfo_Struct : TypeInfo
{
export:

    override ткст toString() { return name; }
	override ткст вТкст(){return toString();}

    override цел opEquals(Object o)
    {   TypeInfo_Struct s;

	return this is o ||
		((s = cast(TypeInfo_Struct)o) !is null &&
		 this.name == s.name &&
		 this.init.length == s.init.length);
    }
	

    hash_t getHash(ук p)
    {	hash_t h;

	assert(p);
	if (xtoHash)
	{   //эхо("getHash() using xtoHash\n");
	    h = (*xtoHash)(p);
	}
	else
	{
	    //эхо("getHash() using default hash\n");
	    // A sorry hash algorithm.
	    // Should use the one for strings.
	    // BUG: relies on the GC not moving objects
	    for (т_мера i = 0; i < init.length; i++)
	    {	h = h * 9 + *cast(ббайт*)p;
		p++;
	    }
	}
	return h;
    }
	т_хэш дайХэш(ук п){return getHash(п);}
	

    цел equals(ук p1, ук p2)
    {	цел c;

	if (p1 == p2)
	    c = 1;
	else if (!p1 || !p2)
	    c = 0;
	else if (xopEquals)
	    c = (*xopEquals)(p1, p2);
	else
	    // BUG: relies on the GC not moving objects
	    c = (сравбуф(p1, p2, init.length) == 0);
	return c;
    }
	цел равны(ук п1, ук п2){return equals(п1, п2);}

    цел compare(ук p1, ук p2)
    {
	цел c = 0;

	// Regard null references as always being "less than"
	if (p1 != p2)
	{
	    if (p1)
	    {	if (!p2)
		    c = 1;
		else if (xopCmp)
		    c = (*xopCmp)(p2, p1);
		else
		    // BUG: relies on the GC not moving objects
		    c = сравбуф(p1, p2, init.length);
	    }
	    else
		c = -1;
	}
	return c;
    }
	цел сравни(ук п1, ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
	return init.length;
    }
	override т_мера тразм(){return tsize();}
	

    override проц[] init() { return m_init; }
	override проц[] иниц(){return init();}

    override бцел flags() { return m_flags; }
	override бцел флаги(){return flags();}
	

   extern(C) extern ткст name;
	alias name имя;
	ткст getSetName(ткст name = null){if(name) this.name = name; return this.name;}
	ткст дайУстИмя(ткст name = null){if(name) this.name = name; return this.name;}
	
   extern(C) extern проц[] m_init;	// инициализатор; init.ptr == null, если инициализует 0

    hash_t function(ук ) xtoHash;
    цел function(ук ,ук ) xopEquals;
    цел function(ук ,ук ) xopCmp;
    ткст function(ук ) xtoString;

    extern(C) extern бцел m_flags;
}
alias TypeInfo_Struct ТипСтрукт;
/////////////////////////////////////////////////////////////////////////////

export extern (D) class TypeInfo_Tuple : TypeInfo
{
export:

    extern(C) extern TypeInfo[] elements;
	alias elements элементы;
	ИнфОТипе[] getSetElements(ИнфОТипе[] elements = null){if(elements) this.elements = elements; return this.elements;}
	ИнфОТипе[] дайУстЭлементы(ИнфОТипе[] elements = null){if(elements) this.elements = elements; return this.elements;}
	

    override ткст toString()
    {
	ткст s;
	s = "(";
	foreach (i, element; elements)
	{
	    if (i)
		s ~= ',';
	    s ~= element.toString();
	}
	s ~= ")";
        return s;
    }
	override ткст вТкст(){return toString();}
	

    override цел opEquals(Object o)
    {
	if (this is o)
	    return 1;

	auto t = cast(TypeInfo_Tuple)o;
	if (t && elements.length == t.elements.length)
	{
	    for (т_мера i = 0; i < elements.length; i++)
	    {
		if (elements[i] != t.elements[i])
		    return 0;
	    }
	    return 1;
	}
	return 0;
    }

    hash_t getHash(ук p)
    {
        assert(0);
    }
	т_хэш дайХэш(ук п){return getHash(п);}
	

    цел equals(ук p1, ук p2)
    {
        assert(0);
    }
	цел равны(ук п1, ук п2){return equals(п1, п2);}
	

    цел compare(ук p1, ук p2)
    {
        assert(0);
    }
	цел сравни(ук п1, ук п2){return compare(п1, п2);}
	

    override т_мера tsize()
    {
        assert(0);
    }
	override т_мера тразм(){return tsize();}
	

    override проц swap(ук p1, ук p2)
    {
        assert(0);
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}
}
alias TypeInfo_Tuple ТипКортеж;
//////////////////////////////////////////////////////////////////////////////

export extern (D) class TypeInfo_Const : TypeInfo
{
export:

    override ткст toString() { return "const " ~ toString(); }
	override ткст вТкст(){return toString();}

    override цел opEquals(Object o) { return opEquals(o); }
    hash_t getHash(ук p) { return getHash(p); }
	т_хэш дайХэш(ук п){return getHash(п);}
	
    цел equals(ук p1, ук p2) { return equals(p1, p2); }
	цел равны(ук п1, ук п2){return equals(п1, п2);}
	
    цел compare(ук p1, ук p2) { return compare(p1, p2); }
	цел сравни(ук п1, ук п2){return compare(п1, п2);}
	
    override т_мера tsize() { return tsize(); }
	override т_мера тразм(){return tsize();}
	
    override проц swap(ук p1, ук p2) { return swap(p1, p2); }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override TypeInfo next() { return next(); }
	override ИнфОТипе следщ(){return next();}
	
    override бцел flags() { return flags(); }
	 override бцел флаги(){return flags();}
	 
    override проц[] init() { return init(); }
	override проц[] иниц(){return init();}

    extern(C) extern TypeInfo base;
	alias base основа;	
	ИнфОТипе getSetBase(ИнфОТипе base = null){if(base) this.основа = base; return this.base;}
	ИнфОТипе дайУстОву(ИнфОТипе base = null){if(base) this.base = base; return this.base;}
}
alias TypeInfo_Const ТипКонстанта;
///////////////////////////////////////////////////////////////////

export extern (D) class TypeInfo_Invariant : TypeInfo_Const
{
export:
    override ткст toString() { return "invariant " ~ toString(); }
	override ткст вТкст(){return toString();}
}
alias TypeInfo_Invariant ТипИнвариант;
/////////////////////////////////////////////////////////////////////////////

alias Object.Monitor        IMonitor, ИМонитор;
alias проц delegate(Object) ДСобыт;

/* *************************
 * Internal struct pointed to by the hidden .monitor member.
 */
export struct Monitor
{
export:
		
    проц delegate(Object)[] delegates;

    /* More stuff goes here defined by internal/monitor.c */
	extern(C) extern IMonitor impl;
    /* internal */
   extern(C) extern ДСобыт[] devt;
    /* stuff */
}
alias Monitor Монитор;



Монитор* дайМонитор(Объект h)
{
    return cast(Монитор*) (cast(ук*) h)[1];
	//return null;
}

проц устМонитор(Объект h, Монитор* m)
{
    (cast(ук*) h)[1] = m;
}

export extern  (C) проц создайМонитор(Объект о){ _d_monitor_create(о);}
export extern (C) проц разрушьМонитор(Объект о) {_d_monitor_destroy(о);}
export extern (C) проц блокируйМонитор(Объект о) {_d_monitor_lock(о);}
export extern (C) цел разблокируйМонитор(Объект о)  {return _d_monitor_unlock(о);}


export extern (C) проц _d_monitordelete(Объект h, bool det)
	{
		Монитор* m = дайМонитор(h);

		if (m !is null)
		{
			IMonitor i = m.impl;
			if (i is null)
			{
				_d_monitor_devt(m, h);
				разрушьМонитор(h);
				устМонитор(h, null);
				return;
			}
			if (det && (cast(ук ) i) !is (cast(ук ) h))
				delete i;
			устМонитор(h, null);
		}
	}
	export extern (C) проц удалиМонитор(Объект о, бул уд){ _d_monitordelete(о, уд);}
	
	
	export  extern (C) проц _d_monitorenter(Объект h)
	{
		//_monitorenter(&h);
		Монитор* m = дайМонитор(h);

		if (m is null)
		{
			создайМонитор(h);
			m = дайМонитор(h);
		}

		IMonitor i = m.impl;

		if (i is null)
		{
			блокируйМонитор(h);
			return;
		}
		i.lock();
	}
	export extern (C) проц войдиВМонитор(Объект о){_d_monitorenter(о);}
	
	
	export extern (C) проц _d_monitorexit(Объект h)
	{
	    
		Монитор* m = дайМонитор(h);
		IMonitor i = m.impl;
		//_monitorexit(&h);
		
		if (i is null)
		{
			разблокируйМонитор(h);
			return;
		}
		i.unlock();
	}
	export extern (C) проц выйдиИзМонитора(Объект о){ _d_monitorexit(о);}
	

	 export extern (C) проц _d_monitor_devt(Монитор* m, Объект h)
	{
		if (m.devt.length)
		{
			ДСобыт[] devt;

			synchronized (h)
			{
				devt = m.devt;
				m.devt = null;
			}
			foreach (v; devt)
			{
				if (v)
					v(h);
			}
			освободи(devt.ptr);
		}
	}
	export extern (C) проц событиеМонитора(Монитор* м, Объект о){ _d_monitor_devt(м, о);}
	
	
  export extern (C) проц rt_attachDisposeEvent(Объект h, ДСобыт e)
	{
		synchronized (h)
		{
			Монитор* m = дайМонитор(h);
			IMonitor i = m.impl;
			assert(i is null);

			foreach (inout v; m.devt)
			{
				if (v is null || v == e)
				{
					v = e;
					return;
				}
			}

			auto len = m.devt.length + 4; // grow by 4 elements
			auto pos = m.devt.length;     // insert position
			auto p = cidrus.перемести(m.devt.ptr, ДСобыт.sizeof * len);
			if (!p)
				onOutOfMemoryError();
			m.devt = (cast(ДСобыт*)p)[0 .. len];
			m.devt[pos+1 .. len] = null;
			m.devt[pos] = e;
		}
	}

  export extern (C) проц rt_detachDisposeEvent(Объект h, ДСобыт e)
	{
		synchronized (h)
		{
			Монитор* m = дайМонитор(h);
			IMonitor i = m.impl;
			assert(i is null);

			foreach (p, v; m.devt)
			{
				if (v == e)
				{
					перембуф(&m.devt[p],
							&m.devt[p+1],
							(m.devt.length - p - 1) * ДСобыт.sizeof);
					return;
				}
			}
		}
	}



alias ModuleInfo ИнфОМодуле;

/***********************
 * Information about each module.
 */
export extern(D) class ModuleInfo
{
export:
	
    extern(C) extern char name[];
    extern(C) extern ИнфОМодуле importedModules[];
    extern(C) extern ИнфОКлассе localClasses[];

    extern(C) extern бцел flags;		// initialization состояние

    проц function() ctor;       // module static constructor (order dependent)
    проц function() dtor;       // module static destructor
    проц function() unitTest;
	/*проц (*ctor)();	// module static constructor (order dependent)
	  проц (*dtor)();	// module static destructor
        проц (*unitTest)();	// module unit tests*/

    extern(C) extern ук  xgetMembers;	// module getMembers() function

    проц function() ictor;//проц (*ictor)();	// module static constructor (order independent)

	static цел opApply( цел delegate( ref  ModuleInfo ) дг )
    {
        цел ret = 0;
		debug(НА_КОНСОЛЬ) эхо("ModuleInfo.opApply called");

        foreach( m; _рт.конструкторы )
        {
            ret = дг( m );
            if( ret )
                break;
        }
        return ret;
    }
    /******************
     * Return collection of all modules in the program.
     */
    static ИнфОМодуле[] модули()
    {
	return _рт.конструкторы;
    }
}

export extern (D) class ОшКтораМодуля : Exception
{
export:

    this(ModuleInfo m)
    {
	super(cast(string) ("круговая зависимость при инициализации с модулем "
                            ~ m.name));
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
export extern (C):

/********************************
 * Compiler helper for operator == for class objects.
 */

int _d_obj_eq(Object o1, Object o2)
{
    return o1 is o2 || (o1 && o1.opEquals(o2));
}


/********************************
 * Compiler helper for operator <, <=, >, >= for class objects.
 */

int _d_obj_cmp(Object o1, Object o2)
{
    return o1.opCmp(o2);
}

////////////////////////////////////// typeinfo
///////////////////////////////
// байт
export extern (D) class TypeInfo_g : TypeInfo
{
export:
    override ткст toString() { return "байт"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return cast(т_хэш)(*cast(байт *)p);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(байт *)p1 == *cast(байт *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return *cast(байт *)p1 - *cast(байт *)p2;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return байт.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        байт t;

        t = *cast(байт *)p1;
        *cast(байт *)p1 = *cast(байт *)p2;
        *cast(байт *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}
}
//////////////////////////////////////

// Объект

export extern (D) class TypeInfo_C : TypeInfo
{
export:
    override т_хэш getHash(in ук p)
    {
        Объект o = *cast(Объект*)p;
        return o ? o.toHash() : cast(т_хэш)0xdeadbeef;
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	

    override цел equals(in ук p1, in ук p2)
    {
        Объект o1 = *cast(Объект*)p1;
        Объект o2 = *cast(Объект*)p2;

        return o1 == o2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        Объект o1 = *cast(Объект*)p1;
        Объект o2 = *cast(Объект*)p2;
        цел c = 0;

        // Regard null references as always being "less than"
        if (!(o1 is o2))
        {
            if (o1)
            {   if (!o2)
                    c = 1;
                else
                    c = o1.opCmp(o2);
            }
            else
                c = -1;
        }
        return c;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return Объект.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}
}

////////////////////////////////////
// кдво
export extern (D) class TypeInfo_r : TypeInfo
{
export:
    override ткст toString() { return "кдво"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return hashOf(p,кдво.sizeof,0);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	

    static цел _equals(кдво f1, кдво f2)
    {
        return f1 == f2;
    }

    static цел _compare(кдво f1, кдво f2)
    {   цел результат;

        if (f1.re < f2.re)
            результат = -1;
        else if (f1.re > f2.re)
            результат = 1;
        else if (f1.im < f2.im)
            результат = -1;
        else if (f1.im > f2.im)
            результат = 1;
        else
            результат = 0;
        return результат;
    }

    override цел equals(in ук p1, in ук p2)
    {
        return _equals(*cast(кдво *)p1, *cast(кдво *)p2);
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return _compare(*cast(кдво *)p1, *cast(кдво *)p2);
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return кдво.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        кдво t;

        t = *cast(кдво *)p1;
        *cast(кдво *)p1 = *cast(кдво *)p2;
        *cast(кдво *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override проц[] init()
    {   static кдво r;

        return (cast(кдво *)&r)[0 .. 1];
    }
	override проц[] иниц(){return init();}
	
	
}

////////////////////////////////////////
// cfloat
export extern (D) class TypeInfo_q : TypeInfo
{
export:
    override ткст toString() { return "кплав"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return hashOf(p, кплав.sizeof,0);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	

    static цел _equals(cfloat f1, cfloat f2)
    {
        return f1 == f2;
    }

    static цел _compare(cfloat f1, cfloat f2)
    {   цел результат;

        if (f1.re < f2.re)
            результат = -1;
        else if (f1.re > f2.re)
            результат = 1;
        else if (f1.im < f2.im)
            результат = -1;
        else if (f1.im > f2.im)
            результат = 1;
        else
            результат = 0;
        return результат;
    }

    override цел equals(in ук p1, in ук p2)
    {
        return _equals(*cast(cfloat *)p1, *cast(cfloat *)p2);
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return _compare(*cast(cfloat *)p1, *cast(cfloat *)p2);
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return кплав.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        cfloat t;

        t = *cast(cfloat *)p1;
        *cast(cfloat *)p1 = *cast(cfloat *)p2;
        *cast(cfloat *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override проц[] init()
    {   static cfloat r;

        return (cast(cfloat *)&r)[0 .. 1];
    }
	override проц[] иниц(){return init();}
}
////////////////////////////////////////


export extern (D) class TypeInfo_a : TypeInfo
{
export:
    override ткст toString() { return "сим"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return cast(т_хэш)(*cast(сим *)p);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(сим *)p1 == *cast(сим *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return *cast(сим *)p1 - *cast(сим *)p2;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return сим.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        сим t;

        t = *cast(сим *)p1;
        *cast(сим *)p1 = *cast(сим *)p2;
        *cast(сим *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override проц[] init()
    {   static сим c;

        return (cast(сим *)&c)[0 .. 1];
    }
	override проц[] иниц(){return init();}
}
///////////////////////////////////
// креал
export extern (D) class TypeInfo_c : TypeInfo
{
export:
    override ткст toString() { return "креал"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return hashOf(p,креал.sizeof,0);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	

    static цел _equals(креал f1, креал f2)
    {
        return f1 == f2;
    }
	

    static цел _compare(креал f1, креал f2)
    {   цел результат;

        if (f1.re < f2.re)
            результат = -1;
        else if (f1.re > f2.re)
            результат = 1;
        else if (f1.im < f2.im)
            результат = -1;
        else if (f1.im > f2.im)
            результат = 1;
        else
            результат = 0;
        return результат;
    }

    override цел equals(in ук p1, in ук p2)
    {
        return _equals(*cast(креал *)p1, *cast(креал *)p2);
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return _compare(*cast(креал *)p1, *cast(креал *)p2);
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return креал.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        креал t;

        t = *cast(креал *)p1;
        *cast(креал *)p1 = *cast(креал *)p2;
        *cast(креал *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override проц[] init()
    {   static креал r;

        return (cast(креал *)&r)[0 .. 1];
    }
	override проц[] иниц(){return init();}
}

///////////////////////////////////////
// dchar
export extern (D) class TypeInfo_w : TypeInfo
{
export:
    override ткст toString() { return "дим"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return cast(т_хэш)*cast(dchar *)p;
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(dchar *)p1 == *cast(dchar *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return *cast(dchar *)p1 - *cast(dchar *)p2;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return дим.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        dchar t;

        t = *cast(dchar *)p1;
        *cast(dchar *)p1 = *cast(dchar *)p2;
        *cast(dchar *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override проц[] init()
    {   static dchar c;

        return (cast(dchar *)&c)[0 .. 1];
    }
	override проц[] иниц(){return init();}
}
//////////////////////////////////////

// delegate
alias проц delegate(цел) дг;

export extern (D) class TypeInfo_D : TypeInfo
{
export:
    override т_хэш getHash(in ук p)
    {
        return rt_hash_block(cast(т_мера *)p,2,0);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(дг *)p1 == *cast(дг *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override т_мера tsize()
    {
        return дг.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        дг t;

        t = *cast(дг *)p1;
        *cast(дг *)p1 = *cast(дг *)p2;
        *cast(дг *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}
}
////////////////////////////
// double
export extern (D) class TypeInfo_d : TypeInfo
{
export:
    override ткст toString() { return "дво"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return hashOf(p,дво.sizeof);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	

    static цел _equals(double f1, double f2)
    {
        return f1 == f2 ||
                (f1 !<>= f1 && f2 !<>= f2);
    }

    static цел _compare(double d1, double d2)
    {
        if (d1 !<>= d2)         // if either are NaN
        {
            if (d1 !<>= d1)
            {   if (d2 !<>= d2)
                    return 0;
                return -1;
            }
            return 1;
        }
        return (d1 == d2) ? 0 : ((d1 < d2) ? -1 : 1);
    }

    override цел equals(in ук p1, in ук p2)
    {
        return _equals(*cast(double *)p1, *cast(double *)p2);
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return _compare(*cast(double *)p1, *cast(double *)p2);
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return дво.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        double t;

        t = *cast(double *)p1;
        *cast(double *)p1 = *cast(double *)p2;
        *cast(double *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override проц[] init()
    {   static double r;

        return (cast(double *)&r)[0 .. 1];
    }
	override проц[] иниц(){return init();}
}
///////////////////////////////
// float
export extern (D) class TypeInfo_f : TypeInfo
{
export:
    override ткст toString() { return "плав"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return cast(т_хэш)(*cast(бцел *)p);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	

    static цел _equals(float f1, float f2)
    {
        return f1 == f2 ||
                (f1 !<>= f1 && f2 !<>= f2);
    }

    static цел _compare(float d1, float d2)
    {
        if (d1 !<>= d2)         // if either are NaN
        {
            if (d1 !<>= d1)
            {   if (d2 !<>= d2)
                    return 0;
                return -1;
            }
            return 1;
        }
        return (d1 == d2) ? 0 : ((d1 < d2) ? -1 : 1);
    }

    override цел equals(in ук p1, in ук p2)
    {
        return _equals(*cast(float *)p1, *cast(float *)p2);
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return _compare(*cast(float *)p1, *cast(float *)p2);
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return float.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        float t;

        t = *cast(float *)p1;
        *cast(float *)p1 = *cast(float *)p2;
        *cast(float *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override проц[] init()
    {   static float r;

        return (cast(float *)&r)[0 .. 1];
    }
	override проц[] иниц(){return init();}
}
/////////////////////////////
// idouble
export extern (D) class TypeInfo_p : TypeInfo_d
{
export:
    override ткст toString() { return "вдво"; }
	override ткст вТкст(){return toString();}
}
/////////////////////////////
// ifloat
export extern (D) class TypeInfo_o : TypeInfo_f
{
export:
    override ткст toString() { return "вплав"; }
	override ткст вТкст(){return toString();}
}
/////////////////////////
// цел
export extern (D) class TypeInfo_i : TypeInfo
{
export:
    override ткст toString() { return "цел"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return cast(т_хэш)(*cast(бцел *)p);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(бцел *)p1 == *cast(бцел *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        if (*cast(цел*) p1 < *cast(цел*) p2)
            return -1;
        else if (*cast(цел*) p1 > *cast(цел*) p2)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return цел.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        цел t;

        t = *cast(цел *)p1;
        *cast(цел *)p1 = *cast(цел *)p2;
        *cast(цел *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}
}
///////////////////////////
// вреал
export extern (D) class TypeInfo_j : TypeInfo_e
{
export:
    override ткст toString() { return "вреал"; }
	override ткст вТкст(){return toString();}
}
//////////////////////////////
// дол
export extern (D) class TypeInfo_l : TypeInfo
{
export:
    override ткст toString() { return "дол"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        static if(т_хэш.sizeof==8){
            return cast(т_хэш)(*cast(бдол *)p);
        } else {
            return rt_hash_combine(*cast(бцел *)p,(cast(бцел *)p)[1]);
        }
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(дол *)p1 == *cast(дол *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        if (*cast(дол *)p1 < *cast(дол *)p2)
            return -1;
        else if (*cast(дол *)p1 > *cast(дол *)p2)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return дол.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        дол t;

        t = *cast(дол *)p1;
        *cast(дол *)p1 = *cast(дол *)p2;
        *cast(дол *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}
}

/////////////////////////////////
// pointer
export extern (D) class TypeInfo_P : TypeInfo
{
export:
    override т_хэш getHash(in ук p)
    {
        return cast(т_хэш)(*cast(т_мера *)p);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(ук *)p1 == *cast(ук *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        auto c = *cast(ук *)p1 - *cast(ук *)p2;
        if (c < 0)
            return -1;
        else if (c > 0)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return (ук ).sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        ук t;

        t = *cast(ук *)p1;
        *cast(ук *)p1 = *cast(ук *)p2;
        *cast(ук *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}
}

///////////////////////////
// реал
export extern (D) class TypeInfo_e : TypeInfo
{
export:
    override ткст toString() { return "реал"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return hashOf(p,реал.sizeof,0);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    static цел _equals(реал f1, реал f2)
    {
        return f1 == f2 ||
                (f1 !<>= f1 && f2 !<>= f2);
    }

    static цел _compare(реал d1, реал d2)
    {
        if (d1 !<>= d2)         // if either are NaN
        {
            if (d1 !<>= d1)
            {   if (d2 !<>= d2)
                    return 0;
                return -1;
            }
            return 1;
        }
        return (d1 == d2) ? 0 : ((d1 < d2) ? -1 : 1);
    }

    override цел equals(in ук p1, in ук p2)
    {
        return _equals(*cast(реал *)p1, *cast(реал *)p2);
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return _compare(*cast(реал *)p1, *cast(реал *)p2);
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return реал.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        реал t;

        t = *cast(реал *)p1;
        *cast(реал *)p1 = *cast(реал *)p2;
        *cast(реал *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override проц[] init()
    {   static реал r;

        return (cast(реал *)&r)[0 .. 1];
    }
	override проц[] иниц(){return init();}
}

////////////////////////////////////
// крат
export extern (D) class TypeInfo_s : TypeInfo
{
export:
    override ткст toString() { return "крат"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return cast(т_хэш)(*cast(бкрат *)p);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(крат *)p1 == *cast(крат *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return *cast(крат *)p1 - *cast(крат *)p2;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return крат.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        крат t;

        t = *cast(крат *)p1;
        *cast(крат *)p1 = *cast(крат *)p2;
        *cast(крат *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}
}
//////////////////////////////
// ббайт
export extern (D) class TypeInfo_h : TypeInfo
{
export:
    override ткст toString() { return "ббайт"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return cast(т_хэш)(*cast(ббайт *)p);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(ббайт *)p1 == *cast(ббайт *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return *cast(ббайт *)p1 - *cast(ббайт *)p2;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return ббайт.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        ббайт t;

        t = *cast(ббайт *)p1;
        *cast(ббайт *)p1 = *cast(ббайт *)p2;
        *cast(ббайт *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}
}

export extern (D) class TypeInfo_b : TypeInfo_h
{
export:
    override ткст toString() { return "бул"; }
	override ткст вТкст(){return toString();}
}
//////////////////////////////////
// бцел
export extern (D) class TypeInfo_k : TypeInfo
{
export:
    override ткст toString() { return "бцел"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return *cast(бцел *)p;
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(бцел *)p1 == *cast(бцел *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        if (*cast(бцел*) p1 < *cast(бцел*) p2)
            return -1;
        else if (*cast(бцел*) p1 > *cast(бцел*) p2)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return бцел.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        цел t;

        t = *cast(бцел *)p1;
        *cast(бцел *)p1 = *cast(бцел *)p2;
        *cast(бцел *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}
}
///////////////////////////////////
// бдол
export extern (D) class TypeInfo_m : TypeInfo
{
export:
    override ткст toString() { return "бдол"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        static if(т_хэш.sizeof==8){
            return cast(т_хэш)(*cast(бдол *)p);
        } else {
            return rt_hash_combine(*cast(бцел *)p,(cast(бцел *)p)[1]);
        }
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(бдол *)p1 == *cast(бдол *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        if (*cast(бдол *)p1 < *cast(бдол *)p2)
            return -1;
        else if (*cast(бдол *)p1 > *cast(бдол *)p2)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return бдол.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        бдол t;

        t = *cast(бдол *)p1;
        *cast(бдол *)p1 = *cast(бдол *)p2;
        *cast(бдол *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}
}
//////////////////////////////
export extern (D) class TypeInfo_t : TypeInfo
{
export:
    override ткст toString() { return "бкрат"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return *cast(бкрат *)p;
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}
	

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(бкрат *)p1 == *cast(бкрат *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return *cast(бкрат *)p1 - *cast(бкрат *)p2;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return бкрат.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        бкрат t;

        t = *cast(бкрат *)p1;
        *cast(бкрат *)p1 = *cast(бкрат *)p2;
        *cast(бкрат *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}
}
//////////////////////////////////////
// проц
export extern (D) class TypeInfo_v : TypeInfo
{
export:
    override ткст toString() { return "проц"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        assert(0);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(байт *)p1 == *cast(байт *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return *cast(байт *)p1 - *cast(байт *)p2;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return проц.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        байт t;

        t = *cast(байт *)p1;
        *cast(байт *)p1 = *cast(байт *)p2;
        *cast(байт *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}
}
///////////////////////////////


export extern (D) class TypeInfo_u : TypeInfo
{
export:
    override ткст toString() { return "шим"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {
        return cast(т_хэш)(*cast(шим *)p);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        return *cast(шим *)p1 == *cast(шим *)p2;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        return *cast(шим *)p1 - *cast(шим *)p2;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return шим.sizeof;
    }
	override т_мера тразм(){return tsize();}

    override проц swap(ук p1, ук p2)
    {
        шим t;

        t = *cast(шим *)p1;
        *cast(шим *)p1 = *cast(шим *)p2;
        *cast(шим *)p2 = t;
    }
	override проц поменяй( ук п1, ук п2){return swap(п1, п2);}

    override проц[] init()
    {   static шим c;

        return (cast(шим *)&c)[0 .. 1];
    }
	override проц[] иниц(){return init();}
}
///////////////////////////////////////////////////////

// Object[]

export extern (D) class TypeInfo_AC : TypeInfo_Array
{
export:
    override т_хэш getHash(in ук p)
    {   Объект[] s = *cast(Объект[]*)p;
        т_хэш hash = 0;

        foreach (Объект o; s)
        {
            if (o){
                hash = rt_hash_combine(o.toHash(),hash);
            } else {
                hash = rt_hash_combine(cast(т_хэш)0xdeadbeef,hash);
            }
        }
        return hash;
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

	
    override цел equals(in ук p1, in ук p2)
    {
        Объект[] s1 = *cast(Объект[]*)p1;
        Объект[] s2 = *cast(Объект[]*)p2;

        if (s1.length == s2.length)
        {
            for (т_мера u = 0; u < s1.length; u++)
            {   Объект o1 = s1[u];
                Объект o2 = s2[u];

                // Do not pass null's to Объект.opEquals()
                if (o1 is o2 ||
                    (!(o1 is null) && !(o2 is null) && o1.opEquals(o2)))
                    continue;
                return false;
            }
            return true;
        }
        return false;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        Объект[] s1 = *cast(Объект[]*)p1;
        Объект[] s2 = *cast(Объект[]*)p2;
        ptrdiff_t c;

        c = cast(ptrdiff_t)s1.length - cast(ptrdiff_t)s2.length;
        if (c == 0)
        {
            for (т_мера u = 0; u < s1.length; u++)
            {   Объект o1 = s1[u];
                Объект o2 = s2[u];

                if (o1 is o2)
                    continue;

                // Regard null references as always being "less than"
                if (o1)
                {
                    if (!o2)
                    {   c = 1;
                        break;
                    }
                    c = o1.opCmp(o2);
                    if (c)
                        break;
                }
                else
                {   c = -1;
                    break;
                }
            }
        }
        if (c < 0)
            c = -1;
        else if (c > 0)
            c = 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}
	

    override т_мера tsize()
    {
        return (Объект[]).sizeof;
    }
	override т_мера тразм(){return tsize();}

    override бцел flags()
    {
        return 1;
    }
	override бцел флаги(){return flags();}

    override TypeInfo next()
    {
        return typeid(Объект);
    }
	override ИнфОТипе следщ(){return next();}
}

//////////////////////////////////
// cdouble[]

export extern (D) class TypeInfo_Ar : TypeInfo_Array
{
export:
    override ткст toString() { return "кдво[]"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p) {
        cdouble[] s = *cast(cdouble[]*)p;
        т_мера len = s.length;
        cdouble *str = s.ptr;
        return hashOf(str,len*кдво.sizeof,0);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        cdouble[] s1 = *cast(cdouble[]*)p1;
        cdouble[] s2 = *cast(cdouble[]*)p2;
        т_мера len = s1.length;

        if (len != s2.length)
            return false;
        for (т_мера u = 0; u < len; u++)
        {
            if (!TypeInfo_r._equals(s1[u], s2[u]))
                return false;
        }
        return true;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        cdouble[] s1 = *cast(cdouble[]*)p1;
        cdouble[] s2 = *cast(cdouble[]*)p2;
        т_мера len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (т_мера u = 0; u < len; u++)
        {
            цел c = TypeInfo_r._compare(s1[u], s2[u]);
            if (c)
                return c;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return (кдво[]).sizeof;
    }
	override т_мера тразм(){return tsize();}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}

    override TypeInfo next()
    {
        return typeid(cdouble);
    }
	override ИнфОТипе следщ(){return next();}
}
//////////////////////////////////

// cfloat[]

export extern (D) class TypeInfo_Aq : TypeInfo_Array
{
export:
    override ткст toString() { return "кплав[]"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p) {
        cfloat[] s = *cast(cfloat[]*)p;
        т_мера len = s.length;
        cfloat *str = s.ptr;
        return hashOf(str,len*кплав.sizeof,0);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        cfloat[] s1 = *cast(cfloat[]*)p1;
        cfloat[] s2 = *cast(cfloat[]*)p2;
        т_мера len = s1.length;

        if (len != s2.length)
            return false;
        for (т_мера u = 0; u < len; u++)
        {
            if (!TypeInfo_q._equals(s1[u], s2[u]))
                return false;
        }
        return true;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        cfloat[] s1 = *cast(cfloat[]*)p1;
        cfloat[] s2 = *cast(cfloat[]*)p2;
        т_мера len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (т_мера u = 0; u < len; u++)
        {
            цел c = TypeInfo_q._compare(s1[u], s2[u]);
            if (c)
                return c;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return (кплав[]).sizeof;
    }
	override т_мера тразм(){return tsize();}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}

    override TypeInfo next()
    {
        return typeid(cfloat);
    }
	override ИнфОТипе следщ(){return next();}
}
/////////////////////////////////////

// creal[]

export extern (D) class TypeInfo_Ac : TypeInfo_Array
{
export:
    override ткст toString() { return "креал[]"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p){
        creal[] s = *cast(creal[]*)p;
        т_мера len = s.length;
        creal *str = s.ptr;
        return hashOf(str,len*креал.sizeof,0);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        creal[] s1 = *cast(creal[]*)p1;
        creal[] s2 = *cast(creal[]*)p2;
        т_мера len = s1.length;

        if (len != s2.length)
            return 0;
        for (т_мера u = 0; u < len; u++)
        {
            if (!TypeInfo_c._equals(s1[u], s2[u]))
                return false;
        }
        return true;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        creal[] s1 = *cast(creal[]*)p1;
        creal[] s2 = *cast(creal[]*)p2;
        т_мера len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (т_мера u = 0; u < len; u++)
        {
            цел c = TypeInfo_c._compare(s1[u], s2[u]);
            if (c)
                return c;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return (креал[]).sizeof;
    }
	override т_мера тразм(){return tsize();}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}

    override TypeInfo next()
    {
        return typeid(creal);
    }
	override ИнфОТипе следщ(){return next();}
}
/////////////////////////////////////////////

// double[]

export extern (D) class TypeInfo_Ad : TypeInfo_Array
{
export:
    override ткст toString() { return "дво[]"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p){
        double[] s = *cast(double[]*)p;
        т_мера len = s.length;
        auto str = s.ptr;
        return hashOf(str,len*дво.sizeof,0); // use rt_hash_block?
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        double[] s1 = *cast(double[]*)p1;
        double[] s2 = *cast(double[]*)p2;
        т_мера len = s1.length;

        if (len != s2.length)
            return 0;
        for (т_мера u = 0; u < len; u++)
        {
            if (!TypeInfo_d._equals(s1[u], s2[u]))
                return false;
        }
        return true;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        double[] s1 = *cast(double[]*)p1;
        double[] s2 = *cast(double[]*)p2;
        т_мера len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (т_мера u = 0; u < len; u++)
        {
            цел c = TypeInfo_d._compare(s1[u], s2[u]);
            if (c)
                return c;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return (дво[]).sizeof;
    }
	override т_мера тразм(){return tsize();}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}

    override TypeInfo next()
    {
        return typeid(double);
    }
	override ИнфОТипе следщ(){return next();}
}

// idouble[]

export extern (D) class TypeInfo_Ap : TypeInfo_Ad
{
export:
    ткст toString() { return "вдво[]"; }
	override ткст вТкст(){return toString();}

    override TypeInfo next()
    {
        return typeid(idouble);
    }
	override ИнфОТипе следщ(){return next();}
}
//////////////////////////////////////

// float[]

export extern (D) class TypeInfo_Af : TypeInfo_Array
{
export:
    override ткст toString() { return "плав[]"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p){
        float[] s = *cast(float[]*)p;
        т_мера len = s.length;
        auto str = s.ptr;
        return hashOf(str,len*плав.sizeof,0);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        float[] s1 = *cast(float[]*)p1;
        float[] s2 = *cast(float[]*)p2;
        т_мера len = s1.length;

        if (len != s2.length)
            return 0;
        for (т_мера u = 0; u < len; u++)
        {
            if (!TypeInfo_f._equals(s1[u], s2[u]))
                return false;
        }
        return true;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        float[] s1 = *cast(float[]*)p1;
        float[] s2 = *cast(float[]*)p2;
        т_мера len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (т_мера u = 0; u < len; u++)
        {
            цел c = TypeInfo_f._compare(s1[u], s2[u]);
            if (c)
                return c;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return (плав[]).sizeof;
    }
	override т_мера тразм(){return tsize();}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}

    override TypeInfo next()
    {
        return typeid(float);
    }
	override ИнфОТипе следщ(){return next();}
}

// ifloat[]

export extern (D) class TypeInfo_Ao : TypeInfo_Af
{
export:
    override ткст toString() { return "вплав[]"; }
	override ткст вТкст(){return toString();}

    override TypeInfo next()
    {
        return typeid(ifloat);
    }
	override ИнфОТипе следщ(){return next();}
}
///////////////////////////////////

// байт[]

export extern (D) class TypeInfo_Ag : TypeInfo_Array
{
export:
    override ткст toString() { return "байт[]"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p) {
        байт[] s = *cast(байт[]*)p;
        т_мера len = s.length;
        байт *str = s.ptr;
        return hashOf(str,len*байт.sizeof,0);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        байт[] s1 = *cast(байт[]*)p1;
        байт[] s2 = *cast(байт[]*)p2;

        return s1.length == s2.length &&
               сравбуф(cast(байт *)s1, cast(байт *)s2, s1.length) == 0;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
		проверьЧитается(p1);
		проверьЧитается(p2);
		байт[] s1 = *cast(байт[]*)p1;
        байт[] s2 = *cast(байт[]*)p2;

		 т_мера len = s1.length;

		 if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
		else
		{
			if (s2.length < len)
				len = s2.length;
			for (т_мера i = 0; i < len; i++)
			{
				цел результат = s1[i] - s2[i];
				//debug printf("\n_______________aaGot___________________\n");
				if (результат)
					return результат;
			}
		}
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return (байт[]).sizeof;
    }
	override т_мера тразм(){return tsize();}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}

    override TypeInfo next()
    {
        return typeid(байт);
    }
	override ИнфОТипе следщ(){return next();}
}


// ббайт[]

export extern (D) class TypeInfo_Ah : TypeInfo_Ag
{
export:
    override ткст toString() { return "ббайт[]"; }
	override ткст вТкст(){return toString();}

    override цел compare(in ук p1, in ук p2)
    {
        ткст s1 = *cast(char[]*)p1;
        ткст s2 = *cast(char[]*)p2;

        return stringCompare(s1, s2);
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override TypeInfo next()
    {
        return typeid(ббайт);
    }
	override ИнфОТипе следщ(){return next();}
}

// проц[]

export extern (D) class TypeInfo_Av : TypeInfo_Ah
{
export:
    override ткст toString() { return "проц[]"; }
	override ткст вТкст(){return toString();}

    override TypeInfo next()
    {
        return typeid(проц);
    }
	override ИнфОТипе следщ(){return next();}
}

// bool[]

export extern (D) class TypeInfo_Ab : TypeInfo_Ah
{
export:
    override ткст toString() { return "бул[]"; }
	override ткст вТкст(){return toString();}

    override TypeInfo next()
    {
        return typeid(bool);
    }
	override ИнфОТипе следщ(){return next();}
}

// ткст

export extern (D) class TypeInfo_Aa : TypeInfo_Ag
{

export:
    override ткст toString() { return "ткст"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p){
       ткст s = *cast(ткст*)p;
	   т_хэш hash = 0;
	   
			version(all) version (OldHash)
			{
				foreach (сим c; s)
					hash = hash * 11 + c;
				return hash;
			} 
		else
			{/+
			
				т_мера len = s.length;
				char *str = cast(char*)s;

				while (1)
				{
					switch (len)
					{
					case 0:
						return hash;

					case 1:
						hash *= 9;
						hash += *cast(ббайт *)str;
						return hash;

					case 2:
						hash *= 9;
						hash += *cast(ushort *)str;
						return hash;

					case 3:
						hash *= 9;
						hash += (*cast(ushort *)str << 8) +
							(cast(ббайт *)str)[2];
						return hash;

					default:
						hash *= 9;
						hash += *cast(uint *)str;
						str += 4;
						len -= 4;
						break;
					}
				}
			}
			else {+/
				//return rt_hash_utf8(s,0); // this would be encoding independent
				return hashOf(s.ptr,s.length,0);
			}
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override TypeInfo next()
    {
        return typeid(char);
    }
	override ИнфОТипе следщ(){return next();}
}
////////////////////////////////////

// цел[]

export extern (D) class TypeInfo_Ai : TypeInfo_Array
{
export:
    override ткст toString() { return "цел[]"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {   цел[] s = *cast(цел[]*)p;
        auto len = s.length;
        auto str = s.ptr;
        return hashOf(str,len*цел.sizeof,0);
    }

	override т_хэш дайХэш(in ук p){ return getHash(p);}
	
    override цел equals(in ук p1, in ук p2)
    {
        цел[] s1 = *cast(цел[]*)p1;
        цел[] s2 = *cast(цел[]*)p2;

        return s1.length == s2.length &&
               сравбуф(cast(ук )s1, cast(ук )s2, s1.length * цел.sizeof) == 0;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        цел[] s1 = *cast(цел[]*)p1;
        цел[] s2 = *cast(цел[]*)p2;
        т_мера len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (т_мера u = 0; u < len; u++)
        {
            цел результат = s1[u] - s2[u];
            if (результат)
                return результат;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return (цел[]).sizeof;
    }
	override т_мера тразм(){return tsize();}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}

    override TypeInfo next()
    {
        return typeid(цел);
    }
	override ИнфОТипе следщ(){return next();}
}

unittest
{
    цел[][] a = [[5,3,8,7], [2,5,3,8,7]];
    a.sort;
    assert(a == [[2,5,3,8,7], [5,3,8,7]]);

    a = [[5,3,8,7], [5,3,8]];
    a.sort;
    assert(a == [[5,3,8], [5,3,8,7]]);
}

// бцел[]

export extern (D) class TypeInfo_Ak : TypeInfo_Ai
{
export:
    override ткст toString() { return "бцел[]"; }
	override ткст вТкст(){return toString();}

    override цел compare(in ук p1, in ук p2)
    {
        бцел[] s1 = *cast(бцел[]*)p1;
        бцел[] s2 = *cast(бцел[]*)p2;
        т_мера len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (т_мера u = 0; u < len; u++)
        {
            цел результат = s1[u] - s2[u];
            if (результат)
                return результат;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override TypeInfo next()
    {
        return typeid(бцел);
    }
	override ИнфОТипе следщ(){return next();}
}

// dchar[]

export extern (D) class TypeInfo_Aw : TypeInfo_Ak
{
export:
    override ткст toString() { return "дим[]"; }
	override ткст вТкст(){return toString();}

    override TypeInfo next()
    {
        return typeid(dchar);
    }
	override ИнфОТипе следщ(){return next();}
}
///////////////////////////////////

// дол[]

export extern (D) class TypeInfo_Al : TypeInfo_Array
{
export:
    override ткст toString() { return "дол[]"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {   дол[] s = *cast(дол[]*)p;
        т_мера len = s.length;
        auto str = s.ptr;
        return hashOf(str,len*дол.sizeof,0);
    }

	override т_хэш дайХэш(in ук p){ return getHash(p);}
	
    override цел equals(in ук p1, in ук p2)
    {
        дол[] s1 = *cast(дол[]*)p1;
        дол[] s2 = *cast(дол[]*)p2;

        return s1.length == s2.length &&
               сравбуф(cast(ук )s1, cast(ук )s2, s1.length * дол.sizeof) == 0;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        дол[] s1 = *cast(дол[]*)p1;
        дол[] s2 = *cast(дол[]*)p2;
        т_мера len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (т_мера u = 0; u < len; u++)
        {
            if (s1[u] < s2[u])
                return -1;
            else if (s1[u] > s2[u])
                return 1;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return (дол[]).sizeof;
    }
	override т_мера тразм(){return tsize();}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}

    override TypeInfo next()
    {
        return typeid(дол);
    }
	override ИнфОТипе следщ(){return next();}
}


// ulong[]

export extern (D) class TypeInfo_Am : TypeInfo_Al
{
export:
    override ткст toString() { return "бдол[]"; }
	override ткст вТкст(){return toString();}

    override цел compare(in ук p1, in ук p2)
    {
        бдол[] s1 = *cast(бдол[]*)p1;
        бдол[] s2 = *cast(бдол[]*)p2;
        т_мера len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (т_мера u = 0; u < len; u++)
        {
            if (s1[u] < s2[u])
                return -1;
            else if (s1[u] > s2[u])
                return 1;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override TypeInfo next()
    {
        return typeid(бдол);
    }
	override ИнфОТипе следщ(){return next();}
}
//////////////////////////////////////////////

// real[]

export extern (D) class TypeInfo_Ae : TypeInfo_Array
{
export:
    override ткст toString() { return "реал[]"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {   реал[] s = *cast(реал[]*)p;
        т_мера len = s.length;
        auto str = s.ptr;
        return hashOf(str,len*реал.sizeof,0);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        реал[] s1 = *cast(реал[]*)p1;
        реал[] s2 = *cast(реал[]*)p2;
        т_мера len = s1.length;

        if (len != s2.length)
            return false;
        for (т_мера u = 0; u < len; u++)
        {
            if (!TypeInfo_e._equals(s1[u], s2[u]))
                return false;
        }
        return true;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        реал[] s1 = *cast(реал[]*)p1;
        реал[] s2 = *cast(реал[]*)p2;
        т_мера len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (т_мера u = 0; u < len; u++)
        {
            цел c = TypeInfo_e._compare(s1[u], s2[u]);
            if (c)
                return c;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return (реал[]).sizeof;
    }
	override т_мера тразм(){return tsize();}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}

    override TypeInfo next()
    {
        return typeid(реал);
    }
	override ИнфОТипе следщ(){return next();}
}

// вреал[]

export extern (D) class TypeInfo_Aj : TypeInfo_Ae
{
export:
    override ткст toString() { return "вреал[]"; }
	override ткст вТкст(){return toString();}

    override TypeInfo next()
    {
        return typeid(вреал);
    }
	override ИнфОТипе следщ(){return next();}
}
////////////////////////////////////////

// крат[]

export extern (D) class TypeInfo_As : TypeInfo_Array
{
export:
    override ткст toString() { return "крат[]"; }
	override ткст вТкст(){return toString();}

    override т_хэш getHash(in ук p)
    {   крат[] s = *cast(крат[]*)p;
        т_мера len = s.length;
        крат *str = s.ptr;
        return hashOf(str,len*крат.sizeof,0);
    }
	override т_хэш дайХэш(in  ук п){return getHash(п);}

    override цел equals(in ук p1, in ук p2)
    {
        крат[] s1 = *cast(крат[]*)p1;
        крат[] s2 = *cast(крат[]*)p2;

        return s1.length == s2.length &&
               сравбуф(cast(ук )s1, cast(ук )s2, s1.length * крат.sizeof) == 0;
    }
	override цел равны(in ук п1, in ук п2){return equals(п1, п2);}

    override цел compare(in ук p1, in ук p2)
    {
        крат[] s1 = *cast(крат[]*)p1;
        крат[] s2 = *cast(крат[]*)p2;
        т_мера len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (т_мера u = 0; u < len; u++)
        {
            цел результат = s1[u] - s2[u];
            if (результат)
                return результат;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override т_мера tsize()
    {
        return (крат[]).sizeof;
    }
	override т_мера тразм(){return tsize();}

    override бцел flags()
    {
        return 1;
    }
	 override бцел флаги(){return flags();}

    override TypeInfo next()
    {
        return typeid(крат);
    }
	override ИнфОТипе следщ(){return next();}
}


// бкрат[]

export extern (D) class TypeInfo_At : TypeInfo_As
{
export:
    override ткст toString() { return "бкрат[]"; }
	override ткст вТкст(){return toString();}

    override цел compare(in ук p1, in ук p2)
    {
        бкрат[] s1 = *cast(бкрат[]*)p1;
        бкрат[] s2 = *cast(бкрат[]*)p2;
        т_мера len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (т_мера u = 0; u < len; u++)
        {
            цел результат = s1[u] - s2[u];
            if (результат)
                return результат;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }
	override цел сравни(in ук п1, in ук п2){return compare(п1, п2);}

    override TypeInfo next()
    {
        return typeid(бкрат);
    }
	override ИнфОТипе следщ(){return next();}
}

// шим[]

export extern (D) class TypeInfo_Au : TypeInfo_At
{
export:
    override ткст toString() { return "шткст"; }
	override ткст вТкст(){return toString();}

    // getHash should be overridden and call rt_hash_utf16 if one wants dependence for codepoints only
    override TypeInfo next()
    {
        return typeid(шим);
    }
	override ИнфОТипе следщ(){return next();}
}

