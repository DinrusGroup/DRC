module exception;
private import cidrus, rt.syserror, std.utf: вЮ8, вЮ16;
private import std.string: format;
alias format форматируй;//, stdrus;
private import sys.WinConsts, sys.WinFuncs;

//Exceptions
/+
extern (C)
{
int   _snprintf(сим* s, size_t n, in сим* fmt, ...);
int sprintf(сим* s, in сим* format, ...);
}+/

alias проц  function( ткст файл, т_мера строка, ткст msg = null ) типПроверОбр;
alias ИнфоОтслежИскл function( ук ptr = null ) типСледОбр;

  типПроверОбр   проверОбр   = null;
  типСледОбр    трОбр    = null;


interface ИнфоОтслежИскл
{
    цел opApply( цел delegate( inout ткст ) );
}

/*******************************************************************************

*******************************************************************************/

export extern(C) struct СисОш
{  
export: 
        /***********************************************************************

        ***********************************************************************/

        static бцел последнКод ()
        {
                version (Win32)
                         return ДайПоследнююОшибку;
                     else
                         return дайНомош;
        }

        /***********************************************************************

        ***********************************************************************/

        static ткст последнСооб ()
        {
                return найди (последнКод);
        }

        /***********************************************************************

        ***********************************************************************/

        static ткст найди (бцел кодош)
        {
                ткст text;

                version (Win32)
                        {
                        DWORD  i;
                        LPWSTR lpMsgBuf;

                        i = FormatMessageW (
                                ПФорматСооб.РазмБуф |
                                ПФорматСооб.ИзСист |
                                ПФорматСооб.ИгнорВставки,
                                null,
                                кодош,
                                СДЕЛАЙИДЪЯЗ(ПЯзык.НЕЙТРАЛЬНЫЙ, ППодъяз.ДЕФОЛТ), // Default language
                                cast(LPWSTR)&lpMsgBuf,
                                0,
                                null);

                        /* Remove \r\n from error string */
                        if (i >= 2) i -= 2;
                        text = new сим[i * 3];
                        i = WideCharToMultiByte (ПКодСтр.УТФ8, 0, lpMsgBuf, i, 
                                                 cast(PCHAR)text.ptr, text.length, null, null);
                        text = text [0 .. i];
                        LocalFree (cast(HLOCAL) lpMsgBuf);
                        }
                     else
                        {
                        бцел  r;
                        сим* pemsg;

                        pemsg = strerror(кодош);
                        r = strlen(pemsg);

                        /* Remove \r\n from error string */
                        if (pemsg[r-1] == '\n') r--;
                        if (pemsg[r-1] == '\r') r--;
                        text = pemsg[0..r].dup;
                        }

                return text;
        }
}

////////////////////////////////////////////////////////////////////////////////
/*
- Исключение
  - OutOfMemoryException

  - Tracedexception
    - ЩитИскл
    - ПроверИскл
    - ArrayBoundsException
    - ФинализИскл

    - PlatformException
      - ProcessException
      - НитьИскл
        - ФибраИскл
      - СинхИскл
      - ВВИскл
        - СокетИскл
          - SocketAcceptException
        - AddressException
        - HostException
        - VfsException
        - ClusterException

    - NoSuchElementException
      - CorruptedIteratorException

    - ИсклНелегальногоАргумента
      - IllegalElementException

    - ТекстИскл
      - RegexException
      - LocaleException
      - ЮникодИскл

    - PayloadException
*/
////////////////////////////////////////////////////////////////////////////////

export extern(D) class ИсклОсновы64: Исключение
{
export:
	this(ткст msg)
	{
		super(msg);		
	}
}

export extern(D) class ИсклСимвОсновы64: Исключение
{
export:
	this(ткст msg)
	{
		super(msg);
		
	}
}


export extern(D) class ИсклВнешнМодуля:Исключение
{
export:	
	    this(ткст сооб)
    {
        super("Неудачное подключение к модулю:\n"~сооб);		
    }

    this(бцел кодош)
    {
     super("Неудачное подключение к модулю\n"~cast(string)строшиб(кодош));      
    }
}

export extern(D) class ФайлИскл : Исключение
{
    бцел номош;			// operating system error code
	
    this(ткст имя)
    {
	super(имя);	
	}

    this(ткст имя, ткст сооб)
    {
	super("Файловое исключение:\n"~сооб, имя, 0);			
    }

    this(ткст имя, бцел номош)
    {	
	this.номош = номош;
	super("Файловое исключение:\n"~sysErrorString(номош),имя, 0);
		
    }
}
/// Исключение, выводимое при попытке динамического доступа к несуществующему члену.
export extern (D) class ИсклНедостающЧлена : Исключение 
{

  protected const ткст О_НЕТЧЛЕНА = "Член не обнаружен.";  
  export:
  
  this() {
    super(О_НЕТЧЛЕНА);
  }

  this(ткст сообщение) {
    super(сообщение);
  }

  this(ткст имяКласса, ткст имяЧлена) {
    super(форматируй("Член '" ~ имяКласса ~ "." ~ имяЧлена ~ "' не обнаружен."));
  }

}

export extern (D) class ИсклКОМ : Исключение
 {
export:
  цел ошКод_;

  this(цел кодОшибки) {
    super(дайОшСооб(кодОшибки));
    ошКод_ = кодОшибки;
  }

  this(ткст сообщение, цел кодОшибки)
  {
    super(сообщение);
    ошКод_ = кодОшибки;
  }

  цел кодОшибки() 
  {
    return ошКод_;
  }

  protected static ткст дайОшСооб(цел кодОшибки) {
    шим[256] буф;
    бцел результат = ФорматируйСооб(cast(ПФорматСооб)(0x00001000 | 0x00000200), null, кодОшибки, 0, буф, буф.length + 1, null);
    if (результат != 0) {
      ткст s = вЮ8(буф[0 .. результат]);

      // Remove trailing симacters
      while (результат > 0) {
        сим c = s[результат - 1];
        if (c > ' ' && c != '.')
          break;
        результат--;
      }

      return форматируй("%s. (Исключение из HRESULT: 0x%08X)", s[0 .. результат], cast(бцел)кодОшибки);
    }

    return форматируй("Необозначенная ошибка (0x%08X)", cast(бцел)кодОшибки);
  }

}

/**
 * Thrown on an out of memory error.
 */
export extern (D) class ВнеПамИскл : Исключение
{
export:		
	
    this( ткст файл = __FILE__, т_мера строка = __LINE__ )
    {
        super( форматируй("Размещение в памяти не удалось"), файл, строка );
		
    }

    override ткст toString()
    {
        return msg ? super.toString() : "Размещение в памяти не удалось";
    }
}

alias ВнеПамИскл OutOfMemoryException;

/**
 * Stores a stack trace when thrown.
 */
export extern (D) class ОтслежИскл : Исключение
{
export:
    this( ткст msg )
    {
        super( msg );
        m_info = контекстТрассировки();
		
    }

    this( ткст msg, Исключение e )
    {
        super( msg, e );
        m_info = контекстТрассировки();
		
    }

    this( ткст msg, ткст файл, т_мера строка )
    {
        super( msg, файл, строка );
        m_info = контекстТрассировки();
		
    }
    ткст вТкст(){return toString();}
	
    override ткст toString()
    {
        if( m_info is null )
            return super.toString();
        ткст буф = super.toString();
        буф ~= "\n----------------";
        foreach( строка; m_info )
            буф ~= "\n" ~ строка;
        return буф;
    }

    цел opApply( цел delegate( inout ткст буф ) дг )
    {
        if( m_info is null )
            return 0;
        return m_info.opApply( дг );
    }

private:
    ИнфоОтслежИскл m_info;
}
alias ОтслежИскл TracedException;

/**
 * Основа export extern (D) class for operating system or library exceptions.
 */
export extern (D) class ПлатформИскл : ОтслежИскл
{
export:

    this( ткст msg )
    {
        super( msg );
		
    }
}

alias ПлатформИскл PlatformException;
/**
 * Thrown on an assert error.
 */
export extern (D) class ПроверИскл : ОтслежИскл
{
export:
    this( ткст файл =__FILE__, т_мера строка =__LINE__ )
    {
        super( форматируй("Неподтверждённая проверка"), файл, строка );
		//
    }

    this( ткст msg, ткст файл = __FILE__, т_мера строка =__LINE__ )
    {
        super( msg, файл, строка );
		//
    }
}
alias ПроверИскл AssertException;

export extern (D) class ПроверОшиб : Исключение
{
export:
    т_мера linnum;
    ткст filename;

    this(ткст filename =__FILE__, т_мера linnum =__LINE__)
    {
	this(пусто, filename, linnum);
	
    }

    this(ткст msg, ткст filename =__FILE__, т_мера linnum =__LINE__)
    {
	this.linnum = linnum;
	this.filename = filename;

	сим* buffer;
	т_мера len;
	int count;

	/* This code is careful to not use gc allocated memory,
	 * as that may be the source of the problem.
	 * Instead, stick with C functions.
	 */

	len = 23 + filename.length + т_мера.sizeof * 3 + msg.length + 1;
	buffer = cast(сим*)malloc(len);
	if (buffer == null)
	    super(форматируй("ОшибкаПодтверждения - нехватка памяти"));
	else
	{
	    version (Win32) alias _snprintf snprintf;
	    count = snprintf(buffer, len, "AssertError Failure %.*s(%u)\n %.*s",
		filename, linnum, msg);
	    if (count >= len || count == -1)
	    {	super(форматируй("ОшибкаПодтверждения - внутренний сбой"));
		cidrus.free(buffer);
	    }
	    else
		super(buffer[0 .. count]);
	}
	
    }

    ~this()
    {
	if (msg.ptr && msg[12] == 'F')	// if it was allocated with malloc()
	{   cidrus.free(msg.ptr);
	    msg = null;
	}
    }
}
alias ПроверОшиб AssertError;
/**
 * Thrown on an array bounds error.
 */
export extern (D) class ГранМасИскл : ОтслежИскл
{
export:
    this( ткст файл=__FILE__, т_мера строка =__LINE__ )
    {
        super( форматируй("Индекс массива вне его пределов"), файл, строка );
		
    }
}
alias ГранМасИскл ArrayBoundsException;

export extern (D) class ГранМасОшиб : Исключение
{
  private:

    т_мера linnum;
    ткст filename;

  export:
    this(ткст filename =__FILE__, т_мера linnum =__LINE__)
    {
	this.linnum = linnum;
	this.filename = filename;

	ткст buffer = new сим[19 + filename.length + linnum.sizeof * 3 + 1];
	int len;
	len = sprintf(buffer.ptr, "ArrayBoundsError %.*s(%u)", filename, linnum);
	super(buffer[0..len]);
	
    }
}
alias ГранМасОшиб ArrayBoundsError;
/**
 * Thrown on finalize error.
 */
export extern (D) class ФинализИскл : ОтслежИскл
{
export:
    ClassInfo   info;

    this( ClassInfo c, Исключение e = null )
    {
        super( форматируй("Ошибка финализации"), e );
        info = c;
		
    }

    override ткст toString()
    {
        return форматируй("Выдана ошибка при финализации экземпляра класса ") ~ info.имя;
    }
}
alias ФинализИскл FinalizeException;


/**
 * Thrown on a switch error.
 */
export extern (D) class ЩитИскл : ОтслежИскл
{
export:
    this( ткст файл = __FILE__, т_мера строка =__LINE__ )
    {
        super( форматируй("Не найдено соответствующего элемента переключателя"), файл, строка );
		
    }
}
alias ЩитИскл SwitchException;

export extern (D) class ЩитОшиб : Исключение
{
  private:

    бцел linnum;
    ткст filename;
	
export:

    this(ткст filename =__FILE__, бцел linnum =__LINE__)
    {
	this.linnum = linnum;
	this.filename = filename;

	ткст buffer = new сим[17 + filename.length + linnum.sizeof * 3 + 1];
	int len = sprintf(buffer.ptr, "Switch Default %.*s(%u)", filename, linnum);
	super(buffer[0..len]);
	
    }


      /***************************************
     * If nobody catches the Assert, this winds up
     * getting called by the startup code.
     */

    override void print()
    {
	эхо("Switch Default %s(%u)\n", cast(сим *)filename, linnum);
    }
}
alias ЩитОшиб SwitchError;

/**
 * Represents a text processing error.
 */
export extern (D) class ТекстИскл : ОтслежИскл
{
export:
    this( ткст msg )
    {
        super( форматируй("Неудачная операция с текстом: "~msg) );
		
    }
}
alias ТекстИскл TextException;
/**
 * Thrown on a unicode conversion error.
 */
export extern (D) class ЮникодИскл : ТекстИскл
{
export:
    т_мера idx;

    this( ткст msg, т_мера idx )
    {
        super(форматируй("Ошибка при преобразовании в/из кодировки Unicode: "~ msg) );
        this.idx = idx;
		
    }
}
alias ЮникодИскл UnicodeException;

/**
 * Основа export extern (D) class for thread exceptions.
 */
export extern (D) class НитьИскл : ПлатформИскл
{
export:
    this( ткст msg )
    {
        super( форматируй("Ошибка нити: "~msg) );
		
    }
}
alias НитьИскл ThreadException;

/**
 * Основа export extern (D) class for fiber exceptions.
 */
export extern (D) class ФибраИскл : ThreadException
{
export:

    this( ткст msg )
    {
        super( форматируй("\n\tОшибка фибры: "~msg ));
		
    }
}
alias ФибраИскл FiberException;

/**
 * Основа export extern (D) class for synchronization exceptions.
 */
export extern (D) class СинхИскл : ПлатформИскл
{
export:

    this( ткст msg )
    {
        super( форматируй("Ошибка синхронизации: "~msg) );
		
    }
}

alias СинхИскл SyncException;

/**
 * The basic Исключение thrown by the io package. One should try to ensure
 * that all Tango exceptions related to IO are derived from this one.
 */
export extern (D) class ВВИскл : ПлатформИскл
{
export:
    this( ткст msg )
    {
        super( "Ошибка ввода-вывода:\n "~ msg );
		
    }
}
alias ВВИскл IOException;

/**
 * The basic Исключение thrown by the io.vfs package. 
 */
export extern (D) class ВфсИскл : IOException
{
export:
    this( ткст msg )
    {
        super( "Ошибка виртуальной файловой системы\n "~msg );
		
    }
}
alias ВфсИскл VfsException;
/**
 * The basic Исключение thrown by the io.cluster package. 
 */
export extern (D) class КластерИскл : IOException
{
export:
    this( ткст msg )
    {
        super( msg );
		
    }
}
alias КластерИскл ClusterException;
/**
 * Основа export extern (D) class for socket exceptions.
 */
export extern (D) class СокетИскл : IOException
{
int errorCode; /// Platform-specific error code.

export:
	
	this(ткст msg, int err = 0)
	{
	    errorCode = err;

	    super(msg);
	}
}

alias СокетИскл SocketException;
/**
 * Основа export extern (D) class for Исключение thrown by an InternetHost.
 */
export extern (D) class ХостИскл : IOException
{
int errorCode;
export:
    this( ткст msg, int err = 0 )
    {
	errorCode = err;
        super( msg );
		
    }
}
alias ХостИскл HostException;
/**
 * Основа export extern (D) class for exceptiond thrown by an Адрес.
 */
export extern (D) class АдрИскл : IOException
{
int errorCode;
export:
    this( ткст msg, int err = 0 )
    {
	errorCode = err;
        super( msg );
		
    }
}
alias АдрИскл AddressException;

/**
 * Thrown when a socket failed to accept an incoming connection.
 */
export extern (D) class СокетПриёмИскл  : СокетИскл
{
export:
    this( ткст msg )
    {
        super( msg );
		
    }
}
alias СокетПриёмИскл SocketAcceptException;

/**
 * Thrown on a process error.
 */
export extern (D) class ПроцессИскл : ПлатформИскл
{
export:
    this( ткст msg )
    {
        super( msg );
		
    }
}
alias ПроцессИскл ProcessException;

/**
 * Основа export extern (D) class for regluar expression exceptions.
 */
export extern (D) class РегВырИскл : TextException
{
export:
    this( ткст msg )
    {
        super( msg );
		
    }
}

alias РегВырИскл RegexException;

/**
 * Основа export extern (D) class for locale exceptions.
 */
export extern (D) class ИсклЛокали : TextException
{
export:
    this( ткст msg )
    {
        super( msg );
		
    }
}

alias ИсклЛокали LocaleException;
/**
 * RegistryException is thrown when the NetworkRegistry encounters a
 * problem during proxy registration, or when it sees an unregistered
 * guid.
 */
export extern (D) class ИсклРеестра  : ОтслежИскл
{
export:
    this( ткст msg )
    {
        super( msg );
		
    }
}
alias ИсклРеестра RegistryException;

/**
 * Thrown when an illegal argument is encountered.
 */
export extern (D) class  НевернАргИскл: ОтслежИскл
{
export:
    this( ткст msg )
    {
        super( msg );
		
    }
}
alias НевернАргИскл ИсклНелегальногоАргумента;

/**
 *
 * IllegalElementException is thrown by Collection methods
 * that add (or replace) elements (and/or keys) when their
 * arguments are null or do not pass screeners.
 *
 */
export extern (D) class НевернЭлемИскл : ИсклНелегальногоАргумента
{
export:
    this( ткст msg )
    {
        super( msg );
		
    }
}
alias НевернЭлемИскл IllegalElementException;

/**
 * Thrown on past-the-end errors by iterators and containers.
 */
export extern (D) class  НетЭлементаИскл: ОтслежИскл
{
export:
    this( ткст msg )
    {
        super( msg );
		
    }
}
alias НетЭлементаИскл NoSuchElementException;

/**
 * Thrown when a corrupt iterator is detected.
 */
export extern (D) class ИсклПовреждённыйИтератор : NoSuchElementException
{
export:
    this( ткст msg )
    {
        super( msg );
		
    }
}
alias ИсклПовреждённыйИтератор CorruptedIteratorException;
/**
 * Thrown on finalize error.
 */
export extern (D) class ФинализОшиб : Исключение
{
export:
    ClassInfo   info;

    this( ClassInfo c, Исключение e = null )
    {
        super( "Ошибка финализации", e );
        info = c;
		
    }

    override ткст toString()
    {
        return "Выдана ошибка при финализации экземпляра класса:\n" ~ info.имя;
    }
}
alias ФинализОшиб  FinalizeError;
/**
 * Thrown on a range error.
 */
export extern (D) class ДиапазонИскл : Исключение
{
export:
    this( ткст файл, т_мера строка )
    {
        super( "Нарушение диапазона", файл, строка );
		
    }
}

/**
 * Thrown on hidden function error.
 */
export extern (D) class СкрытФункцИскл : Исключение
{
export:
    this( ClassInfo ci )
    {
        super( "Вызван скрытый метод для " ~ ci.имя );
		
    }
}

export extern (D) class ИсклРЯР : TextException
{
export:
    this(ткст msg)
{
super(msg);
}
}


////////////////////////


/**
 * The exception thrown when one of the arguments provided to a method is not valid.
 */
export extern (D) class АргИскл : Исключение {


  private static const E_ARGUMENT = "Значение не входит в ожидаемый диапазон.";

  private ткст paramName_;

  export:
  
  this() {
    super(E_ARGUMENT);
  }

  this(ткст сооб) {
    super(сооб);
  }

  this(ткст сооб, ткст парамИмя) {
    super(сооб);
    paramName_ = парамИмя;
  }

  final ткст парамИмя() {
    return paramName_;
  }

}

/**
 * The exception thrown when a null reference is passed to a method that does not accept it as a valid argument.
 */
export extern (D) class ПустойАргИскл : АргИскл {

  private static const E_ARGUMENTNULL = "Значение не может быть пустым (null).";

  export:
  this() {
    super(E_ARGUMENTNULL);
  }

  this(ткст парамИмя) {
    super(E_ARGUMENTNULL, парамИмя);
  }

  this(ткст парамИмя, ткст сооб) {
    super(сооб, парамИмя);
  }

}

/**
 * The exception that is thrown when the value of an argument passed to a method is outside the allowable range of values.
 */
export extern (D) class АргВнеИскл : АргИскл {

  private static const E_ARGUMENTOUTOFRANGE = "Индекс вне диапазона.";
export:
  this() {
    super(E_ARGUMENTOUTOFRANGE);
  }

  this(ткст парамИмя) {
    super(E_ARGUMENTOUTOFRANGE, парамИмя);
  }

  this(ткст парамИмя, ткст сооб) {
    super(сооб, парамИмя);
  }

}

/**
 * The exception thrown when the format of an argument does not meet the parameter specifications of the invoked method.
 */
export extern (D) class ФорматИскл : Исключение {

  private static const E_FORMAT = "Значение в неправильном формате.";
export:
  this() {
    super(E_FORMAT);
  }

  this(ткст сооб) {
    super("Несовпадение формата с заданным аргументом: "~сооб);
  }

}

/**
 * The exception thrown for invalid casting.
 */
export extern (D) class КастИскл : Исключение {

  private static const E_INVALIDCAST = "Указанное приведение к типу недопустимо.";
export:
  this() {
    super(E_INVALIDCAST);
  }

  this(ткст сооб) {
    super(сооб);
  }

}

/**
 * The exception thrown when a method call is invalid.
 */
export extern (D) class ОпИскл : Исключение {

  private static const E_INVALIDOPERATION = "Операция недопустима.";
export:
  this() {
    super(E_INVALIDOPERATION);
  }

  this(ткст сооб) {
    super(сооб);
  }

}

/**
 * The exception thrown when a requested method or operation is not implemented.
 */
export extern (D) class НереализИскл : Исключение {

  private static const E_NOTIMPLEMENTED = "Операция не реализована.";
export:
  this() {
    super(E_NOTIMPLEMENTED);
  }

  this(ткст сооб) {
    super(сооб);
  }

}

/**
 * The exception thrown when an invoked method is not supported.
 */
export extern (D) class НеПоддерживаетсяИскл : Исключение {

  private static const E_NOTSUPPORTED = "Указанный метод не поддерживается.";
export:
  this() {
    super(E_NOTSUPPORTED);
  }

  this(ткст сооб) {
    super(сооб);
  }

}

/**
 * The exception thrown when there is an attempt to dereference a null reference.
 */
export extern (D) class НулСсылкаИскл : Исключение {

  private static const E_NULLREFERENCE = "Ссылка на объект не установлена на экземпляр объекта.";
export:
  this() {
    super(E_NULLREFERENCE);
  }

  this(ткст сооб) {
    super(сооб);
  }

}

/**
 * The exception thrown when the operating system denies access.
 */
export extern (D) class ВзломИскл : Исключение {

  private static const E_UNAUTHORIZEDACCESS = "Доступ запрещён.";
export:
  this() {
    super(E_UNAUTHORIZEDACCESS);
  }

  this(ткст сооб) {
    super(сооб);
  }

}

/**
 * The exception thrown when a security error is detected.
 */
export extern (D) class БезопИскл : Исключение {

  private static const E_SECURITY = "Ошибка  безопасности.";
export:
  this() {
    super(E_SECURITY);
  }

  this(ткст сооб) {
    super(сооб);
  }

}

/**
 * The exception thrown for errors in an arithmetic, casting or conversion operation.
 */
export extern (D) class МатИскл : Исключение {

  private static const E_ARITHMETIC = "Перебор или недобор при арифметической операции.";
export:
  this() {
    super(E_ARITHMETIC);
  }

  this(ткст сооб) {
    super(сооб);
  }

}

/**
 * The exception thrown when an arithmetic, casting or conversion operation results in an overflow.
 */
export extern (D) class ПереполнИскл : МатИскл {

  private const E_OVERFLOW = "Арифметическая операция завершилась переполнением.";
export:
  this() {
    super(E_OVERFLOW);
  }

  this(ткст сооб) {
    super(сооб);
  }

}

/////////////////////


//static module!!!!
static this()
{
}

////////////////////////////////////////////////////////////////////////////////
// Overrides
////////////////////////////////////////////////////////////////////////////////


/**
 * Overrides the default assert hander with a user-supplied version.
 *
 * Параметры:
 *  h = The new assert handler.  Set to null to use the default handler.
 */
export extern (C)
{

	 бул устПроверОбр( типПроверОбр h )
	{
		проверОбр = h;
		return true;
	}


	/**
	 * Overrides the default trace hander with a user-supplied version.
	 *
	 * Параметры:
	 *  h = The new trace handler.  Set to null to use the default handler.
	 */
	бул устСледОбр( типСледОбр h )
	{
		трОбр = h;
		return true;
	}

	/**
	 * This function will be called when a ОтслежИскл is constructed.  The
	 * user-supplied trace handler will be called if one has been supplied,
	 * otherwise no trace will be generated.
	 *
	 * Параметры:
	 *  ptr = A pointer to the location from which to generate the trace, or null
	 *        if the trace should be generated from within the trace handler
	 *        itself.
	 *
	 * Возвращает:
	 *  An object describing the current calling context or null if no handler is
	 *  supplied.
	 */
	ИнфоОтслежИскл контекстТрассировки( ук ptr = null )
	{
		if( трОбр is null )
			return null;
		return трОбр( ptr );
	}

}

////////////////////////////////////////////////////////////////////////////////
// Overridable Callbacks
////////////////////////////////////////////////////////////////////////////////
export:

/**
 * A callback for assert errors in D.  The user-supplied assert handler will
 * be called if one has been supplied, otherwise an AssertException will be
 * thrown.
 *
 * Параметры:
 *  файл = The имя of the файл that signaled this error.
 *  строка = The строка number on which this error occurred.
 */
extern  (C) void onAssertError( ткст файл, т_мера строка )
{
    if( проверОбр is null )
        throw new AssertException( файл, строка );
    проверОбр( файл, строка );
}


/**
 * A callback for assert errors in D.  The user-supplied assert handler will
 * be called if one has been supplied, otherwise an AssertException will be
 * thrown.
 *
 * Параметры:
 *  файл = The имя of the файл that signaled this error.
 *  строка = The строка number on which this error occurred.
 *  msg  = An error сооб supplied by the user.
 */
extern  (C) void onAssertErrorMsg( ткст файл, т_мера строка, ткст msg )
{
    if( проверОбр is null )
        throw new AssertException( msg, файл, строка );
    проверОбр( файл, строка, msg );
}



////////////////////////////////////////////////////////////////////////////////
// Internal Ошибка Callbacks
////////////////////////////////////////////////////////////////////////////////


/**
 * A callback for array bounds errors in D.  An ArrayBoundsException will be
 * thrown.
 *
 * Параметры:
 *  файл = The имя of the файл that signaled this error.
 *  строка = The строка number on which this error occurred.
 *
 * Выводит:
 *  ArrayBoundsException.
 */
extern  (C) void onArrayBoundsError( ткст файл, т_мера строка )
{
    throw new ArrayBoundsException( файл, строка );
}


/**
 * A callback for finalize errors in D.  A FinalizeException will be thrown.
 *
 * Параметры:
 *  e = The Исключение thrown during finalization.
 *
 * Выводит:
 *  FinalizeException.
 */
extern  (C) void onFinalizeError( ClassInfo info, Исключение ex )
{
    throw new FinalizeException( info, ex );
}


/**
 * A callback for out of memory errors in D.  An ВнеПамИскл will be
 * thrown.
 *
 * Выводит:
 *  ВнеПамИскл.
 */
extern  (C) void onOutOfMemoryError()
{
    // NOTE: Since an out of memory condition exists, no allocation must occur
    //       while generating this object.
    throw cast(ВнеПамИскл) cast(void*) ВнеПамИскл.classinfo.init;
}
//{
    // NOTE: Since an out of memory condition exists, no allocation must occur
    //       while generating this object.
   // throw cast(ВнеПамИскл) cast(void*) ВнеПамИскл.classinfo.init;
//}


/**
 * A callback for switch errors in D.  A SwitchException will be thrown.
 *
 * Параметры:
 *  файл = The имя of the файл that signaled this error.
 *  строка = The строка number on which this error occurred.
 *
 * Выводит:
 *  SwitchException.
 */
extern  (C) void onSwitchError( ткст файл, т_мера строка )
{
    throw new SwitchException( файл, строка );
}


/**
 * A callback for unicode errors in D.  A UnicodeException will be thrown.
 *
 * Параметры:
 *  msg = Information about the error.
 *  idx = String index where this error was detected.
 *
 * Выводит:
 *  UnicodeException.
 */
extern  (C) void onUnicodeError( ткст msg, т_мера idx )
{
    throw new UnicodeException( msg, idx );
}
alias onUnicodeError приОшУни;

/**
 * A callback for array bounds errors in D.  A ДиапазонИскл will be thrown.
 *
 * Параметры:
 *  файл = The имя of the файл that signaled this error.
 *  строка = The строка number on which this error occurred.
 *
 * Выводит:
 *  ДиапазонИскл.
 */
extern  (C) void onRangeError( ткст файл, т_мера строка )
{
    throw new ДиапазонИскл( файл, строка );
}



/**
 * A callback for hidden function errors in D.  A СкрытФункцИскл will be
 * thrown.
 *
 * Выводит:
 *  СкрытФункцИскл.
 */
extern  (C) void onHiddenFuncError( Object o )
{
    throw new СкрытФункцИскл( o.classinfo );
}

/***********************************
 * These are internal callbacks for various language errors.
 */
extern  (C) void _d_assert( ткст файл, бцел строка )
{
    if( проверОбр is null )throw new AssertError( файл, строка );проверОбр( файл, строка );
}

extern  (C) static void _d_assert_msg( ткст msg, ткст файл, бцел строка )
{
    if( проверОбр is null )
        throw new AssertException( msg, файл, строка );
    проверОбр( файл, строка, msg );
}

extern  (C) void _d_array_bounds( ткст файл, бцел строка )
{
    onArrayBoundsError( файл, cast(т_мера) строка );
	эхо(" _d_assert(%s, %d)\n", cast(сим *)файл, строка);
    ArrayBoundsError a = new ArrayBoundsError(файл, cast(т_мера) строка);
    эхо("assertion %p created\n", a);
    throw a;
}

extern  (C) void _d_switch_error( ткст файл, бцел строка )
{
    onSwitchError( файл, cast(т_мера) строка );
}

extern  (C) void _d_OutOfMemory()
{
	onOutOfMemoryError();
}


export extern (C)
{
	проц ошибка(ткст сооб, ткст файл = ткст.init, дол  строка = дол.init)
		{
		wchar[] soob =cast(wchar[])(вЮ16(сооб)~"\nФайл: "~вЮ16(файл)~"\nСтрока:"~вЮ16(std.string.toString(строка)));
		ОкноСооб(null, soob, "Исключение Динрус :", ПСооб.Ошибка|ПСооб.Поверх);
		throw new Исключение(сооб, файл, строка);
		}
		
	проц ошибкаПодтверждения(ткст файл, т_мера строка){
	if( проверОбр is null )throw new AssertError( файл, строка );проверОбр( файл, строка );}
	проц ошибкаГраницМассива(ткст файл, т_мера строка){throw new ArrayBoundsError(файл, строка );}
	проц ошибкаФинализации(ИнфОКлассе инфо, Исключение ис){throw new FinalizeError(инфо, ис );}
	проц ошибкаНехваткиПамяти(){throw new ВнеПамИскл;}
	проц ошибкаПереключателя(ткст файл, т_мера строка){throw new  SwitchError(файл, строка );}
	проц ошибкаЮникод(ткст сооб, т_мера индкс){throw new  UnicodeException( сооб, индкс);}
	проц ошибкаДиапазона(ткст файл, т_мера строка){throw new ДиапазонИскл(файл, строка);}
	проц ошибкаСкрытойФункции(Объект о){throw new СкрытФункцИскл( о.classinfo );}
}
