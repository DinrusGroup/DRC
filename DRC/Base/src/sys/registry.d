module sys.registry;
import stdrus;

/// A strongly-typed Boolean
public alias цел        булево;

version(LittleEndian)
{
    private const цел Эндиан_Амбьент =   1;
}
version(BigEndian)
{
    private const цел Эндиан_Амбьент =   2;
}

class Win32Exception : Exception
{
    цел ошиб;

    this(ткст сообщение)
    {
	super(msg);
    }

    this(ткст msg, цел errnum)
    {
	super(msg);
	ошиб = errnum;
    }
}

/// An enumeration representing байт-ordering (Эндиан) strategies
public enum Эндиан
{
        Неизвестно =   0                   //!< Неизвестно эндиан-ness. Indicates an ошиб
    ,   Литтл  =   1                   //!< Литтл эндиан architecture
    ,   Биг     =   2                   //!< Биг эндиан architecture
    ,   Миддл  =   3                   //!< Миддл эндиан architecture
    ,   БайтСекс =   4
    ,   Амбьент =   Эндиан_Амбьент      //!< The ambient architecture, e.g. equivalent to Биг on big-эндиан architectures.
/+ ++++ The compiler does not support this, due to deficiencies in the version() mechanism ++++
  version(LittleEndian)
  {
    ,   Амбьент =   Литтл
  }
  version(BigEndian)
  {
    ,   Амбьент =   Биг
  }
+/
}
/+
 +/


//import synsoft.win32.types;
/+ + These are borrowed from synsoft.win32.types for the moment, but will not be
 + needed once I've convinced Walter to use strong typedefs for things like HKEY +
 +/
private typedef бцел Reserved;

//import synsoft.text.token;
/+ ++++++ This is borrowed from synsoft.text.token, until such time as something
 + similar is in Phobos ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 +/
ткст[] tokenise(ткст исходник, сим разграничитель, булево bElideBlanks, булево bZeroTerminate)
{
    цел         i;
    цел         cDelimiters =   128;
    ткст[]   tokens      =   new ткст[cDelimiters];
    цел         start;
    цел         begin;
    цел         cTokens;

    /// Ensures that the tokens array is big enough
    проц ensure_length()
    {
        if(!(cTokens < tokens.length))
        {
            tokens.length = tokens.length * 2;
        }
    }

    if(bElideBlanks)
    {
        for(start = 0, begin = 0, cTokens = 0; begin < исходник.length; ++begin)
        {
            if(исходник[begin] == разграничитель)
            {
                if(start < begin)
                {
                    ensure_length();

                    tokens[cTokens++]   =   исходник[start .. begin];
                }

                start = begin + 1;
            }
        }

        if(start < begin)
        {
            ensure_length();

            tokens[cTokens++]   =   исходник[start .. begin];
        }
    }
    else
    {
        for(start = 0, begin = 0, cTokens = 0; begin < исходник.length; ++begin)
        {
            if(исходник[begin] == разграничитель)
            {
                ensure_length();

                tokens[cTokens++]   =   исходник[start .. begin];

                start = begin + 1;
            }
        }

        ensure_length();

        tokens[cTokens++]   =   исходник[start .. begin];
    }

    tokens.length = cTokens;

    if(bZeroTerminate)
    {
        for(i = 0; i < tokens.length; ++i)
        {
            tokens[i] ~= cast(сим)0;
        }
    }

    return tokens;
}
/+
 +/
  const HKEY  HKEY_CLASSES_ROOT =           cast(HKEY)(0x80000000);
  const HKEY  HKEY_CURRENT_USER =           cast(HKEY)(0x80000001);
  const HKEY  HKEY_LOCAL_MACHINE =          cast(HKEY)(0x80000002);
  const HKEY  HKEY_USERS =                  cast(HKEY)(0x80000003);
  const HKEY  HKEY_PERFORMANCE_DATA =       cast(HKEY)(0x80000004);
 const HKEY   HKEY_PERFORMANCE_TEXT =       cast(HKEY)(0x80000050);
  const HKEY  HKEY_PERFORMANCE_NLSTEXT =    cast(HKEY)(0x80000060);
  const HKEY  HKEY_CURRENT_CONFIG =         cast(HKEY)(0x80000005);
   const HKEY HKEY_DYN_DATA =               cast(HKEY)(0x80000006);
   
   enum
{
    ERROR_SUCCESS =                    0,
    ERROR_INVALID_FUNCTION =           1,
    ERROR_FILE_NOT_FOUND =             2,
    ERROR_PATH_NOT_FOUND =             3,
    ERROR_TOO_MANY_OPEN_FILES =        4,
    ERROR_ACCESS_DENIED =              5,
    ERROR_INVALID_HANDLE =             6,
    ERROR_NO_MORE_FILES =              18,
    ERROR_MORE_DATA =          234,
    ERROR_NO_MORE_ITEMS =          259,
}

/* ////////////////////////////////////////////////////////////////////////// */

/// \defgroup group_std_windows_reg std.import rt.core.os.windows;.registry
/// \ingroup group_std_windows
/// \brief This library provides Win32 Реестр facilities

/* /////////////////////////////////////////////////////////////////////////////
 * Private constants
 */

private const бцел DELETE                      =   0x00010000L;
private const бцел READ_CONTROL                =   0x00020000L;
private const бцел WRITE_DAC                   =   0x00040000L;
private const бцел WRITE_OWNER                 =   0x00080000L;
private const бцел SYNCHRONIZE                 =   0x00100000L;

private const бцел STANDARD_RIGHTS_REQUIRED    =   0x000F0000L;

private const бцел STANDARD_RIGHTS_READ        =   0x00020000L/* READ_CONTROL */;
private const бцел STANDARD_RIGHTS_WRITE       =   0x00020000L/* READ_CONTROL */;
private const бцел STANDARD_RIGHTS_EXECUTE     =   0x00020000L/* READ_CONTROL */;

private const бцел STANDARD_RIGHTS_ALL         =   0x001F0000L;

private const бцел SPECIFIC_RIGHTS_ALL         =   0x0000FFFFL;

private const Reserved  RESERVED                =   cast(Reserved)0;

private const бцел REG_CREATED_NEW_KEY     =   0x00000001;
private const бцел REG_OPENED_EXISTING_KEY =   0x00000002;

/* /////////////////////////////////////////////////////////////////////////////
 * Public enumerations
 */

/// Перечисление распознаваемых режимов доступа к реестру
///
/// \ingroup group_D_win32_reg
enum ПРежимДоступаКРеестру
{
        ЗапросЗначения         =   0x0001 //!< Разрешение запроса данных подключа
    ,   УстановкаЗначения           =   0x0002 //!< Разрешение установки данных подключа
    ,   СозданиеПодключа      =   0x0004 //!< Разрешение создавать подключи
    ,   ПеречислениеПодключей  =   0x0008 //!< Разрешение перечислять подключи
    ,   Уведомление              =   0x0010 //!< Разрешение уведомления об изменении
    ,   СозданиеСссылки         =   0x0020 //!< Разрешение на создание символьной ссылки
    ,   KEY_WOW64_32KEY         =   0x0200 //!< Разрешает 64- или 32-битному приложению открывать 32-битный ключ
    ,   KEY_WOW64_64KEY         =   0x0100 //!< Разрешает 64- или 32-битному приложению открывать 64-битный ключ
    ,   KEY_WOW64_RES           =   0x0300 //!< 
    ,   Чтение                =   (   STANDARD_RIGHTS_READ
                                    |   ЗапросЗначения
                                    |   ПеречислениеПодключей
                                    |   Уведомление)
                                &   ~(SYNCHRONIZE) //!< Combines the STANDARD_RIGHTS_READ, ЗапросЗначения, ПеречислениеПодключей, and Уведомление доступ rights
    ,   Запись               =   (   STANDARD_RIGHTS_WRITE
                                    |   УстановкаЗначения
                                    |   СозданиеПодключа)
                                &   ~(SYNCHRONIZE) //!< Combines the STANDARD_RIGHTS_WRITE, УстановкаЗначения, and СозданиеПодключа доступ rights
    ,   Выполнение             =   Чтение
                                &   ~(SYNCHRONIZE) //!< Permission for read доступ
    ,   ПолныйДоступ          =   (   STANDARD_RIGHTS_ALL
                                    |   ЗапросЗначения
                                    |   УстановкаЗначения
                                    |   СозданиеПодключа
                                    |   ПеречислениеПодключей
                                    |   Уведомление
                                    |   СозданиеСссылки)
                                &   ~(SYNCHRONIZE) //!< Combines the ЗапросЗначения, ПеречислениеПодключей, Уведомление, СозданиеПодключа, СозданиеСссылки, and УстановкаЗначения доступ rights, plus all the standard доступ rights except SYNCHRONIZE
}

/// Перечень распознаваемых типов значений реестра
///
/// \ingroup group_D_win32_reg
public enum ПТипЗначенияРеестра
{
        Неизвестен                     =   -1 //!< 
    ,   Никакой                        =   0  //!< Тип значения null. (На практике рассматривается как бинарный массив нулевой длины в реестре Win32)
    ,   Ткст0                          =   1  //!< A zero-terminated ткст
    ,   Ткст0Развёрт                   =   2  //!< A zero-terminated ткст containing expandable environment variable references
    ,   Бинарный                      =   3  //!< A binary blob
    ,   Бцел                       =   4  //!< A 32-bit unsigned integer
    ,   БцелЛЕ         =   4  //!< A 32-bit unsigned integer, stored in little-эндиан байт order
    ,   БцелБЕ            =   5  //!< A 32-bit unsigned integer, stored in big-эндиан байт order
    ,   Ссылка                        =   6  //!< A registry link
    ,   МногоТкст0                    =   7  //!< A set of zero-terminated strings
    ,   СписокРесурсов               =   8  //!< A hardware resource list
    ,   ПолныйДескрипторРесурса    =   9  //!< A hardware resource descriptor
    ,   СписовТребуемыхРесурсов  =   10 //!< A hardware resource requirements list
    ,   Бцел64                       =   11 //!< A 64-bit unsigned integer
    ,   Бцел64ЛЕ         =   11 //!< A 64-bit unsigned integer, stored in little-эндиан байт order
}

/* /////////////////////////////////////////////////////////////////////////////
 * external function declarations
 */

extern  (C)
{
    цел wsprintfA(сим *dest, сим *fmt, ...);
}

extern  (Windows)
{
    LONG    RegCreateKeyExA(in HKEY hkey, in LPCSTR lpSubKey, in Reserved 
                        ,   in Reserved , in бцел dwOptions
                        ,   in ПРежимДоступаКРеестру samDesired
                        ,   in sys.WinStructs.LPSECURITY_ATTRIBUTES lpsa
                        ,   out HKEY hkeyResult, out бцел disposition);
    LONG    RegDeleteKeyA(in HKEY hkey, in LPCSTR lpSubKey);
    LONG    RegDeleteValueA(in HKEY hkey, in LPCSTR lpValueName);
    LONG    RegOpenKeyA(in HKEY hkey, in LPCSTR lpSubKey, out HKEY hkeyResult);
    LONG    RegOpenKeyExA(  in HKEY hkey, in LPCSTR lpSubKey, in Reserved 
                        ,   in ПРежимДоступаКРеестру samDesired, out HKEY hkeyResult);
    LONG    RegCloseKey(in HKEY hkey);
    LONG    RegFlushKey(in HKEY hkey);
    LONG    RegQueryValueExA(   in HKEY hkey, in LPCSTR lpValueName, in Reserved 
                            ,   out ПТипЗначенияРеестра тип, in проц *lpData
                            ,   inout бцел cbData);
    LONG    RegEnumKeyExA(  in HKEY hkey, in бцел dwIndex, in LPSTR lpName
                        ,   inout бцел cchName, in Reserved , in LPSTR lpClass
                        ,   in LPDWORD cchClass, in sys.WinStructs.FILETIME *ftLastWriteTime);
    LONG    RegEnumValueA(  in HKEY hkey, in бцел dwIndex, in LPSTR lpValueName
                        ,   inout бцел cchValueName, in Reserved 
                        ,   in LPDWORD lpType, in проц *lpData
                        ,   in LPDWORD lpcbData);
    LONG    RegQueryInfoKeyA(   in HKEY hkey, in LPSTR lpClass
                            ,   in LPDWORD lpcClass, in Reserved
                            ,   in LPDWORD lpcSubKeys
                            ,   in LPDWORD lpcMaxSubKeyLen
                            ,   in LPDWORD lpcMaxClassLen, in LPDWORD lpcValues
                            ,   in LPDWORD lpcMaxValueNameLen
                            ,   in LPDWORD lpcMaxValueLen
                            ,   in LPDWORD lpcbSecurityDescriptor
                            ,   in sys.WinStructs.FILETIME *lpftLastWriteTime);
    LONG    RegSetValueExA( in HKEY hkey, in LPCSTR lpSubKey, in Reserved 
                        ,   in ПТипЗначенияРеестра тип, in LPCVOID lpData
                        ,   in бцел cbData);

    бцел   ExpandEnvironmentStringsA(in LPCSTR src, in LPSTR dest, in бцел cchDest);
    цел     GetLastError();
}

/* /////////////////////////////////////////////////////////////////////////////
 * Private utility functions
 */

private ПТипЗначенияРеестра _RVT_from_Endian(Эндиан эндиан)
{
    switch(эндиан)
    {
        case    Эндиан.Биг:
            return ПТипЗначенияРеестра.БцелБЕ;

        case    Эндиан.Литтл:
            return ПТипЗначенияРеестра.БцелЛЕ;

        default:
            throw new ИсклРеестра("Задан неправильный Эндиан");
    }
}

private бцел swap(in бцел i)
{
    version(X86)
    {
        asm
        {    naked;
             bswap EAX ;
             ret ;
        }
    }
    else
    {
        бцел    v_swap  =   (i & 0xff) << 24
                        |   (i & 0xff00) << 8
                        |   (i >> 8) & 0xff00
                        |   (i >> 24) & 0xff;

        return v_swap;
    }
}

/+
private ткст expand_environment_strings(in ткст значение)
in
{
    assert(!(null is значение));
}
body
{
    LPCSTR  lpSrc       =   stdrus.вТкст0(значение);
    бцел   cchRequired =   ExpandEnvironmentStringsA(lpSrc, null, 0);
    сим[]  newValue    =   new сим[cchRequired];

    if(!ExpandEnvironmentStringsA(lpSrc, newValue, newValue.length))
    {
        throw new Win32Exception("Failed to expand environment variables");
    }

    return newValue;
}
+/

/* /////////////////////////////////////////////////////////////////////////////
 * Translation of the raw APIs:
 *
 * - translating сим[] to сим*
 * - removing the reserved arguments.
 */

private LONG Reg_CloseKey_(in HKEY hkey)
in
{
    assert(!(null is hkey));
}
body
{
    /* No need to attempt to close any of the standard hive ключи.
     * Although it's documented that calling RegCloseKey() on any of
     * these hive ключи is ignored, we'd rather not trust the Win32
     * API.
     */
    if(cast(бцел)hkey & 0x80000000)
    {
        switch(cast(бцел)hkey)
        {
            case    HKEY_CLASSES_ROOT:
            case    HKEY_CURRENT_USER:
            case    HKEY_LOCAL_MACHINE:
            case    HKEY_USERS:
            case    HKEY_PERFORMANCE_DATA:
            case    HKEY_PERFORMANCE_TEXT:
            case    HKEY_PERFORMANCE_NLSTEXT:
            case    HKEY_CURRENT_CONFIG:
            case    HKEY_DYN_DATA:
                return ERROR_SUCCESS;
            default:
                /* Do nothing */
                break;
        }
    }

    return RegCloseKey(hkey);
}

private LONG Reg_FlushKey_(in HKEY hkey)
in
{
    assert(!(null is hkey));
}
body
{
    return RegFlushKey(hkey);
}

private LONG Reg_CreateKeyExA_(     in HKEY hkey, in ткст subKey
                                ,   in бцел dwOptions, in ПРежимДоступаКРеестру samDesired
                                ,   in sys.WinStructs.LPSECURITY_ATTRIBUTES lpsa
                                ,   out HKEY hkeyResult, out бцел disposition)
in
{
    assert(!(null is hkey));
    assert(!(null is subKey));
}
body
{
    return RegCreateKeyExA( hkey, stdrus.вТкст0(subKey), RESERVED, RESERVED
                        ,   dwOptions, samDesired, lpsa, hkeyResult
                        ,   disposition);
}

private LONG Reg_DeleteKeyA_(in HKEY hkey, in ткст subKey)
in
{
    assert(!(null is hkey));
    assert(!(null is subKey));
}
body
{
    return RegDeleteKeyA(hkey, stdrus.вТкст0(subKey));
}

private LONG Reg_DeleteValueA_(in HKEY hkey, in ткст valueName)
in
{
    assert(!(null is hkey));
    assert(!(null is valueName));
}
body
{
    return RegDeleteValueA(hkey, stdrus.вТкст0(valueName));
}

private HKEY Reg_Dup_(HKEY hkey)
in
{
    assert(!(null is hkey));
}
body
{
    /* Can't duplicate standard ключи, but don't need to, so can just return */
    if(cast(бцел)hkey & 0x80000000)
    {
        switch(cast(бцел)hkey)
        {
            case    HKEY_CLASSES_ROOT:
            case    HKEY_CURRENT_USER:
            case    HKEY_LOCAL_MACHINE:
            case    HKEY_USERS:
            case    HKEY_PERFORMANCE_DATA:
            case    HKEY_PERFORMANCE_TEXT:
            case    HKEY_PERFORMANCE_NLSTEXT:
            case    HKEY_CURRENT_CONFIG:
            case    HKEY_DYN_DATA:
                return hkey;
            default:
                /* Do nothing */
                break;
        }
    }

    HKEY    hkeyDup;
    LONG    lRes = RegOpenKeyA(hkey, null, hkeyDup);

    debug
    {
        if(ERROR_SUCCESS != lRes)
        {
            printf("Reg_Dup_() failed: 0x%08x 0x%08x %d\n", hkey, hkeyDup, lRes);
        }

        assert(ERROR_SUCCESS == lRes);
    }

    return (ERROR_SUCCESS == lRes) ? hkeyDup : null;
}

private LONG Reg_EnumKeyName_(  in HKEY hkey, in бцел индекс, inout сим [] имя
                            ,   out бцел cchName)
in
{
    assert(!(null is hkey));
    assert(!(null is имя));
    assert(0 < имя.length);
}
body
{
    LONG    res;

    // The Реестр API lies about the lengths of a very few sub-ключ lengths
    // so we have to test to see if it whinges about more data, and provide 
    // more if it does.
    for(;;)
    {
        cchName = имя.length;

        res = RegEnumKeyExA(hkey, индекс, имя.ptr, cchName, RESERVED, null, null, null);

        if(ERROR_MORE_DATA != res)
        {
            break;
        }
        else
        {
            // Now need to increase the size of the buffer and try again
            имя.length = 2 * имя.length;
        }
    }

    return res;
}


private LONG Reg_EnumValueName_(in HKEY hkey, in бцел dwIndex, in LPSTR lpName
                            ,   inout бцел cchName)
in
{
    assert(!(null is hkey));
}
body
{
    return RegEnumValueA(hkey, dwIndex, lpName, cchName, RESERVED, null, null, null);
}

private LONG Reg_GetNumSubKeys_(in HKEY hkey, out бцел cSubKeys
                            ,   out бцел cchSubKeyMaxLen)
in
{
    assert(!(null is hkey));
}
body
{
    return RegQueryInfoKeyA(hkey, null, null, RESERVED, &cSubKeys
                        ,   &cchSubKeyMaxLen, null, null, null, null, null, null);
}

private LONG Reg_GetNumValues_( in HKEY hkey, out бцел cValues
                            ,   out бцел cchValueMaxLen)
in
{
    assert(!(null is hkey));
}
body
{
    return RegQueryInfoKeyA(hkey, null, null, RESERVED, null, null, null
                        ,   &cValues, &cchValueMaxLen, null, null, null);
}

private LONG Reg_GetValueType_( in HKEY hkey, in ткст имя
                            ,   out ПТипЗначенияРеестра тип)
in
{
    assert(!(null is hkey));
}
body
{
    бцел   cbData  =   0;
    LONG    res     =   RegQueryValueExA(   hkey, stdrus.вТкст0(имя), RESERVED, тип
                                        ,   cast(байт*)0, cbData);

    if(ERROR_MORE_DATA == res)
    {
        res = ERROR_SUCCESS;
    }

    return res;
}

private LONG Reg_OpenKeyExA_(   in HKEY hkey, in ткст subKey
                            ,   in ПРежимДоступаКРеестру samDesired, out HKEY hkeyResult)
in
{
    assert(!(null is hkey));
    assert(!(null is subKey));
}
body
{
    return RegOpenKeyExA(hkey, stdrus.вТкст0(subKey), RESERVED, samDesired, hkeyResult);
}

private проц Reg_QueryValue_(   in HKEY hkey, ткст имя, out ткст значение
                            ,   out ПТипЗначенияРеестра тип)
in
{
    assert(!(null is hkey));
}
body
{
    // See bugzilla 961 on this
    union U
    {
        бцел    dw;
        бдол   qw;
    };
    U       u;
    проц    *data   =   &u.qw;
    бцел   cbData  =   U.qw.sizeof;
    LONG    res     =   RegQueryValueExA(   hkey, stdrus.вТкст0(имя), RESERVED
                                        ,   тип, data, cbData);

    if(ERROR_MORE_DATA == res)
    {
        data = (new байт[cbData]).ptr;

        res = RegQueryValueExA( hkey, stdrus.вТкст0(имя), RESERVED, тип, data
                            ,   cbData);
    }

    if(ERROR_SUCCESS != res)
    {
        throw new ИсклРеестра("Не удаётся прочесть требуемое значение", res);
    }
    else
    {
        switch(тип)
        {
            default:
            case    ПТипЗначенияРеестра.Бинарный:
            case    ПТипЗначенияРеестра.МногоТкст0:
                throw new ИсклРеестра("Не удаётся прочесть требуемое значение как ткст");

            case    ПТипЗначенияРеестра.Ткст0:
            case    ПТипЗначенияРеестра.Ткст0Развёрт:
                значение = stdrus.вТкст(cast(сим*)data);
		if (значение.ptr == cast(сим*)&u.qw)
		    значение = значение.dup;		// don't point into the stack
                break;
version(LittleEndian)
{
            case    ПТипЗначенияРеестра.БцелЛЕ:
                значение = stdrus.вТкст(u.dw);
                break;
            case    ПТипЗначенияРеестра.БцелБЕ:
                значение = stdrus.вТкст(swap(u.dw));
                break;
}
version(BigEndian)
{
            case    ПТипЗначенияРеестра.БцелЛЕ:
                значение = stdrus.вТкст(swap(u.dw));
                break;
            case    ПТипЗначенияРеестра.БцелБЕ:
                значение = stdrus.вТкст(u.dw);
                break;
}
            case    ПТипЗначенияРеестра.Бцел64ЛЕ:
                значение = stdrus.вТкст(u.qw);
                break;
        }
    }
}

private проц Reg_QueryValue_(   in HKEY hkey, in ткст имя, out ткст[] значение
                            ,   out ПТипЗначенияРеестра тип)
in
{
    assert(!(null is hkey));
}
body
{
    сим[]  data    =   new сим[256];
    бцел   cbData  =   data.sizeof;
    LONG    res     =   RegQueryValueExA( hkey, stdrus.вТкст0(имя), RESERVED, тип
                                        , data.ptr, cbData);

    if(ERROR_MORE_DATA == res)
    {
        data.length = cbData;

        res = RegQueryValueExA(hkey, stdrus.вТкст0(имя), RESERVED, тип, data.ptr, cbData);
    }
    else if(ERROR_SUCCESS == res)
    {
        data.length = cbData;
    }

    if(ERROR_SUCCESS != res)
    {
        throw new ИсклРеестра("Не удаётся прочесть требуемое значение", res);
    }
    else
    {
        switch(тип)
        {
            default:
                throw new ИсклРеестра("Не удаётся прочесть требуемое значение как ткст");

            case    ПТипЗначенияРеестра.МногоТкст0:
                break;
        }
    }

    // Now need to tokenise it
    значение = tokenise(cast(ткст)data, cast(сим)0, 1, 0);
}

private проц Reg_QueryValue_(   in HKEY hkey, in ткст имя, out бцел значение
                            ,   out ПТипЗначенияРеестра тип)
in
{
    assert(!(null is hkey));
}
body
{
    бцел   cbData  =   значение.sizeof;
    LONG    res     =   RegQueryValueExA(   hkey, stdrus.вТкст0(имя), RESERVED, тип
                                        ,   &значение, cbData);

    if(ERROR_SUCCESS != res)
    {
        throw new ИсклРеестра("Не удаётся прочесть требуемое значение", res);
    }
    else
    {
        switch(тип)
        {
            default:
                throw new ИсклРеестра("Не удаётся прочесть требуемое значение как 32-битное целое");

version(LittleEndian)
{
            case    ПТипЗначенияРеестра.БцелЛЕ:
                assert(ПТипЗначенияРеестра.Бцел == ПТипЗначенияРеестра.БцелЛЕ);
                break;
            case    ПТипЗначенияРеестра.БцелБЕ:
} // version(LittleEndian)
version(BigEndian)
{
            case    ПТипЗначенияРеестра.БцелБЕ:
                assert(ПТипЗначенияРеестра.Бцел == ПТипЗначенияРеестра.БцелБЕ);
                break;
            case    ПТипЗначенияРеестра.БцелЛЕ:
} // version(BigEndian)
                значение = swap(значение);
                break;
        }
    }
}

private проц Reg_QueryValue_(   in HKEY hkey, in ткст имя, out бдол значение
                            ,   out ПТипЗначенияРеестра тип)
in
{
    assert(!(null is hkey));
}
body
{
    бцел   cbData  =   значение.sizeof;
    LONG    res     =   RegQueryValueExA(   hkey, stdrus.вТкст0(имя), RESERVED, тип
                                        ,   &значение, cbData);

    if(ERROR_SUCCESS != res)
    {
        throw new ИсклРеестра("Не удаётся прочесть требуемое значение", res);
    }
    else
    {
        switch(тип)
        {
            default:
                throw new ИсклРеестра("Не удаётся прочесть требуемое значение как 64-битное целое");

            case    ПТипЗначенияРеестра.Бцел64ЛЕ:
                break;
        }
    }
}

private проц Reg_QueryValue_(   in HKEY hkey, in ткст имя, out байт[] значение
                            ,   out ПТипЗначенияРеестра тип)
in
{
    assert(!(null is hkey));
}
body
{
    байт[]  data    =   new байт[100];
    бцел   cbData  =   data.sizeof;
    LONG    res     =   RegQueryValueExA(   hkey, stdrus.вТкст0(имя), RESERVED, тип
                                        ,   data.ptr, cbData);

    if(ERROR_MORE_DATA == res)
    {
        data.length = cbData;

        res = RegQueryValueExA(hkey, stdrus.вТкст0(имя), RESERVED, тип, data.ptr, cbData);
    }

    if(ERROR_SUCCESS != res)
    {
        throw new ИсклРеестра("Не удаётся прочесть требуемое значение", res);
    }
    else
    {
        switch(тип)
        {
            default:
                throw new ИсклРеестра("Не удаётся прочесть требуемое значение как ткст");

            case    ПТипЗначенияРеестра.Бинарный:
                data.length = cbData;
                значение = data;
                break;
        }
    }
}

private проц Reg_SetValueExA_(  in HKEY hkey, in ткст subKey
                            ,   in ПТипЗначенияРеестра тип, in LPCVOID lpData
                            ,   in бцел cbData)
in
{
    assert(!(null is hkey));
}
body
{
    LONG    res =   RegSetValueExA( hkey, stdrus.вТкст0(subKey), RESERVED, тип
                                ,   lpData, cbData);

    if(ERROR_SUCCESS != res)
    {
        throw new ИсклРеестра("Не удаётся установить значение : \"" ~ subKey ~ "\"", res);
    }
}

/* /////////////////////////////////////////////////////////////////////////////
 * Classes
 */

////////////////////////////////////////////////////////////////////////////////
// ИсклРеестра

/// Exception class thrown by the std.import rt.core.os.windows;.registry classes
///
/// \ingroup group_D_win32_reg

public class ИсклРеестра
    : Win32Exception
{
/// \имя Construction
//@{
public:
    /// \brief Creates an instance of the exception
    ///
    /// \param сообщение The сообщение associated with the exception
    this(ткст сообщение)
    {
        super(сообщение);
    }
    /// \brief Creates an instance of the exception, with the given 
    ///
    /// \param сообщение The сообщение associated with the exception
    /// \param ошиб The Win32 ошиб number associated with the exception
    this(ткст сообщение, цел ошиб)
    {
        super(сообщение, ошиб);
    }
//@}
}

unittest
{
    // (i) Test that we can throw and catch one by its own тип
    try
    {
        ткст  сообщение =   "Test 1";
        цел     код    =   3;
        ткст  ткст  =   "Test 1 (3)";

        try
        {
            throw new ИсклРеестра(сообщение, код);
        }
        catch(ИсклРеестра x)
        {
            assert(x.ошиб == код);
/+
            if(ткст != x.toString())
            {
                printf( "UnitTest failure for ИсклРеестра:\n"
                        "  x.сообщение [%d;\"%.*s\"] does not equal [%d;\"%.*s\"]\n"
                    ,   x.msg.length, x.msg
                    ,   ткст.length, ткст);
            }
            assert(сообщение == x.msg);
+/
        }
    }
    catch(Exception /* x */)
    {
        цел code_flow_should_never_reach_here = 0;
        assert(code_flow_should_never_reach_here);
    }
}

////////////////////////////////////////////////////////////////////////////////
// Ключ

/// This class represents a registry ключ
///
/// \ingroup group_D_win32_reg

export extern(D) class Ключ
{
    invariant()
    {
        assert(!(null is m_hkey));
    }

/// \имя Construction
//@{
export:
    this(HKEY hkey, ткст имя, булево созд)
    in
    {
        assert(!(null is hkey));
    }
    body
    {
        m_hkey      =   hkey;
        m_name      =   имя;
        m_created   =   созд;
    }

    ~this()
    {
        Reg_CloseKey_(m_hkey);

        // Even though this is horried waste-of-cycles programming
        // we're doing it here so that the 
        m_hkey = null;
    }
//@}

/// \имя Attributes
//@{

    /// The имя of the ключ
    ткст имя()
    {
        return m_name;
    }

/*  /// Indicates whether this ключ was созд, rather than opened, by the client
    булево Created()
    {
        return m_created;
    }
*/

    /// The number of sub ключи
    бцел члоПодключей()
    {
        бцел    cSubKeys;
        бцел    cchSubKeyMaxLen;
        LONG    res =   Reg_GetNumSubKeys_(m_hkey, cSubKeys, cchSubKeyMaxLen);

        if(ERROR_SUCCESS != res)
        {
            throw new ИсклРеестра("Невозможно определить количество подключей", res);
        }

        return cSubKeys;
    }

    /// An enumerable sequence of all the sub-ключи of this ключ
    РядКлючей ключи()
    {
        return new РядКлючей(this);
    }

    /// An enumerable sequence of the names of all the sub-ключи of this ключ
    РядИмёнКлючей именаКлючей()
    {
        return new РядИмёнКлючей(this);
    }

    /// The number of значения
    бцел члоЗначений()
    {
        бцел    cValues;
        бцел    cchValueMaxLen;
        LONG    res =   Reg_GetNumValues_(m_hkey, cValues, cchValueMaxLen);

        if(ERROR_SUCCESS != res)
        {
            throw new ИсклРеестра("Невозможно определить количество значений", res);
        }

        return cValues;
    }

    /// An enumerable sequence of all the значения of this ключ
    РядЗначений значения()
    {
        return new РядЗначений(this);
    }

    /// An enumerable sequence of the names of all the значения of this ключ
    РядИмёнЗначений именаЗначений()
    {
        return new РядИмёнЗначений(this);
    }

    /// Returns the named sub-ключ of this ключ
    ///
    /// \param имя The имя of the subkey to create. May not be null
    /// \return The созд ключ
    /// \note If the ключ cannot be созд, a ИсклРеестра is thrown.
    Ключ создайКлюч(ткст имя, ПРежимДоступаКРеестру доступ)
    {
        if( null is имя ||
            0 == имя.length)
        {
            throw new ИсклРеестра("Название ключа неправильное");
        }
        else
        {
            HKEY    hkey;
            бцел   disposition;
            LONG    lRes    =   Reg_CreateKeyExA_(  m_hkey, имя, 0
                                                ,   ПРежимДоступаКРеестру.ПолныйДоступ
                                                ,   null, hkey, disposition);

            if(ERROR_SUCCESS != lRes)
            {
                throw new ИсклРеестра("Не удалось создать запрашиваемый ключ: \"" ~ имя ~ "\"", lRes);
            }

            assert(!(null is hkey));

            // Potential resource leak here!!
            //
            // If the allocation of the memory for Ключ fails, the HKEY could be
            // lost. Hence, we catch such a failure by the finally, and release
            // the HKEY there. If the creation of 
            try
            {
                Ключ ключ =   new Ключ(hkey, имя, disposition == REG_CREATED_NEW_KEY);

                hkey = null;

                return ключ;
            }
            finally
            {
                if(hkey != null)
                {
                    Reg_CloseKey_(hkey);
                }
            }
        }
    }
    
    /// Returns the named sub-ключ of this ключ
    ///
    /// \param имя The имя of the subkey to create. May not be null
    /// \return The созд ключ
    /// \note If the ключ cannot be созд, a ИсклРеестра is thrown.
    /// \note This function is equivalent to calling CreateKey(имя, ПРежимДоступаКРеестру.ПолныйДоступ), and returns a ключ with all доступ
    Ключ создайКлюч(ткст имя)
    {
        return создайКлюч(имя, cast(ПРежимДоступаКРеестру)ПРежимДоступаКРеестру.ПолныйДоступ);
    }

    /// Returns the named sub-ключ of this ключ
    ///
    /// \param имя The имя of the subkey to aquire. If имя is null (or the empty-ткст), then the called ключ is duplicated
    /// \param доступ The desired доступ; one of the ПРежимДоступаКРеестру enumeration
    /// \return The aquired ключ. 
    /// \note This function never returns null. If a ключ corresponding to the requested имя is not found, a ИсклРеестра is thrown
    Ключ дайКлюч(ткст имя, ПРежимДоступаКРеестру доступ)
    {
        if( null is имя ||
            0 == имя.length)
        {
            return new Ключ(Reg_Dup_(m_hkey), m_name, false);
        }
        else
        {
            HKEY    hkey;
            LONG    lRes    =   Reg_OpenKeyExA_(m_hkey, имя, ПРежимДоступаКРеестру.ПолныйДоступ, hkey);

            if(ERROR_SUCCESS != lRes)
            {
                throw new ИсклРеестра("Не удалось открыть запрашиваемый ключ: \"" ~ имя ~ "\"", lRes);
            }

            assert(!(null is hkey));

            // Potential resource leak here!!
            //
            // If the allocation of the memory for Ключ fails, the HKEY could be
            // lost. Hence, we catch such a failure by the finally, and release
            // the HKEY there. If the creation of 
            try
            {
                Ключ ключ =   new Ключ(hkey, имя, false);

                hkey = null;

                return ключ;
            }
            finally
            {
                if(hkey != null)
                {
                    Reg_CloseKey_(hkey);
                }
            }
        }
    }

    /// Returns the named sub-ключ of this ключ
    ///
    /// \param имя The имя of the subkey to aquire. If имя is null (or the empty-ткст), then the called ключ is duplicated
    /// \return The aquired ключ. 
    /// \note This function never returns null. If a ключ corresponding to the requested имя is not found, a ИсклРеестра is thrown
    /// \note This function is equivalent to calling GetKey(имя, ПРежимДоступаКРеестру.Чтение), and returns a ключ with read/enum доступ
    Ключ дайКлюч(ткст имя)
    {
        return дайКлюч(имя, cast(ПРежимДоступаКРеестру)(ПРежимДоступаКРеестру.Чтение));
    }

    /// Deletes the named ключ
    ///
    /// \param имя The имя of the ключ to delete. May not be null
    проц удалиКлюч(ткст имя)
    {
        if( null is имя ||
            0 == имя.length)
        {
            throw new ИсклРеестра("Название ключа неверное");
        }
        else
        {
            LONG    res =   Reg_DeleteKeyA_(m_hkey, имя);

            if(ERROR_SUCCESS != res)
            {
                throw new ИсклРеестра("Не удаётся удалить значение: \"" ~ имя ~ "\"", res);
            }
        }
    }

    /// Returns the named значение
    ///
    /// \note if имя is null (or the empty-ткст), then the default значение is returned
    /// \return This function never returns null. If a значение corresponding to the requested имя is not found, a ИсклРеестра is thrown
    Значение дайЗначение(ткст имя)
    {
        ПТипЗначенияРеестра  тип;
        LONG            res =   Reg_GetValueType_(m_hkey, имя, тип);

        if(ERROR_SUCCESS == res)
        {
            return new Значение(this, имя, тип);
        }
        else
        {
            throw new ИсклРеестра("Не удаётся открыть значение: \"" ~ имя ~ "\"", res);
        }
    }

    /// Sets the named значение with the given 32-bit unsigned integer значение
    ///
    /// \param имя The имя of the значение to set. If null, or the empty ткст, sets the default значение
    /// \param значение The 32-bit unsigned значение to set
    /// \note If a значение corresponding to the requested имя is not found, a ИсклРеестра is thrown
    проц установиЗначение(ткст имя, бцел значение)
    {
        установиЗначение(имя, значение, Эндиан.Амбьент);
    }

    /// Sets the named значение with the given 32-bit unsigned integer значение, according to the desired байт-ordering
    ///
    /// \param имя The имя of the значение to set. If null, or the empty ткст, sets the default значение
    /// \param значение The 32-bit unsigned значение to set
    /// \param эндиан Can be Эндиан.Биг or Эндиан.Литтл
    /// \note If a значение corresponding to the requested имя is not found, a ИсклРеестра is thrown
    проц установиЗначение(ткст имя, бцел значение, Эндиан эндиан)
    {
        ПТипЗначенияРеестра  тип    =   _RVT_from_Endian(эндиан);

        assert( тип == ПТипЗначенияРеестра.БцелБЕ || 
                тип == ПТипЗначенияРеестра.БцелЛЕ);

        Reg_SetValueExA_(m_hkey, имя, тип, &значение, значение.sizeof);
    }

    /// Sets the named значение with the given 64-bit unsigned integer значение
    ///
    /// \param имя The имя of the значение to set. If null, or the empty ткст, sets the default значение
    /// \param значение The 64-bit unsigned значение to set
    /// \note If a значение corresponding to the requested имя is not found, a ИсклРеестра is thrown
    проц установиЗначение(ткст имя, бдол значение)
    {
        Reg_SetValueExA_(m_hkey, имя, ПТипЗначенияРеестра.Бцел64, &значение, значение.sizeof);
    }

    /// Sets the named значение with the given ткст значение
    ///
    /// \param имя The имя of the значение to set. If null, or the empty ткст, sets the default значение
    /// \param значение The ткст значение to set
    /// \note If a значение corresponding to the requested имя is not found, a ИсклРеестра is thrown
    проц установиЗначение(ткст имя, ткст значение)
    {
        установиЗначение(имя, значение, false);
    }

    /// Sets the named значение with the given ткст значение
    ///
    /// \param имя The имя of the значение to set. If null, or the empty ткст, sets the default значение
    /// \param значение The ткст значение to set
    /// \param asEXPAND_SZ If true, the значение will be stored as an expandable environment ткст, otherwise as a normal ткст
    /// \note If a значение corresponding to the requested имя is not found, a ИсклРеестра is thrown
    проц установиЗначение(ткст имя, ткст значение, булево asEXPAND_SZ)
    {
        Reg_SetValueExA_(m_hkey, имя, asEXPAND_SZ 
                                            ? ПТипЗначенияРеестра.Ткст0Развёрт
                                            : ПТипЗначенияРеестра.Ткст0, значение.ptr
                        , значение.length);
    }

    /// Sets the named значение with the given multiple-strings значение
    ///
    /// \param имя The имя of the значение to set. If null, or the empty ткст, sets the default значение
    /// \param значение The multiple-strings значение to set
    /// \note If a значение corresponding to the requested имя is not found, a ИсклРеестра is thrown
    проц установиЗначение(ткст имя, ткст[] значение)
    {
        цел total = 2;

        // Work out the length

        foreach(ткст s; значение)
        {
            total += 1 + s.length;
        }

        // Allocate

	сим[]  cs      =   new сим[total];
        цел     base    =   0;

        // Slice the individual strings into the new array

        foreach(ткст s; значение)
        {
            цел top = base + s.length;

            cs[base .. top] = s;
            cs[top] = 0;

            base = 1 + top;
        }

        Reg_SetValueExA_(m_hkey, имя, ПТипЗначенияРеестра.МногоТкст0, cs.ptr, cs.length);
    }

    /// Sets the named значение with the given binary значение
    ///
    /// \param имя The имя of the значение to set. If null, or the empty ткст, sets the default значение
    /// \param значение The binary значение to set
    /// \note If a значение corresponding to the requested имя is not found, a ИсклРеестра is thrown
    проц установиЗначение(ткст имя, байт[] значение)
    {
        Reg_SetValueExA_(m_hkey, имя, ПТипЗначенияРеестра.Бинарный, значение.ptr, значение.length);
    }

    /// Deletes the named значение
    ///
    /// \param имя The имя of the значение to delete. May not be null
    /// \note If a значение of the requested имя is not found, a ИсклРеестра is thrown
    проц удалиЗначение(ткст имя)
    {
        LONG    res =   Reg_DeleteValueA_(m_hkey, имя);

        if(ERROR_SUCCESS != res)
        {
            throw new ИсклРеестра("Не удаётся удалить значение: \"" ~ имя ~ "\"", res);
        }
    }

    /// Flushes any changes to the ключ to disk
    ///
    проц слей()
    {
        LONG    res =   Reg_FlushKey_(m_hkey);

        if(ERROR_SUCCESS != res)
        {
            throw new ИсклРеестра("Ключ не удаётся слить", res);
        }
    }
//@}

/// \имя Members
//@{
private:
    HKEY    m_hkey;
    ткст m_name;
    булево m_created;
//@}
}

////////////////////////////////////////////////////////////////////////////////
// Значение

/// This class represents a значение of a registry ключ
///
/// \ingroup group_D_win32_reg

export extern(D) class Значение
{
    invariant()
    {
        assert(!(null is m_key));
    }

export:
    this(Ключ ключ, ткст имя, ПТипЗначенияРеестра тип)
    in
    {
        assert(!(ключ is null));
    }
    body
    {
        m_key   =   ключ;
        m_type  =   тип;
        m_name  =   имя;
    }

/// \имя Attributes
//@{

    /// The имя of the значение.
    ///
    /// \note If the значение represents a default значение of a ключ, which has no имя, the returned ткст will be of zero length
    ткст имя()
    {
        return m_name;
    }

    /// The тип of значение
    ПТипЗначенияРеестра тип()
    {
        return m_type;
    }

    /// Obtains the current значение of the значение as a ткст.
    ///
    /// \return The contents of the значение
    /// \note If the значение's тип is Ткст0Развёрт the returned значение is <b>not</b> expanded; Value_EXPAND_SZ() should be called
    /// \note Throws a ИсклРеестра if the тип of the значение is not Ткст0, Ткст0Развёрт, Бцел(_*) or Бцел64(_*):
    ткст значение_Ткст0()
    {
        ПТипЗначенияРеестра  тип;
        ткст          значение;

        Reg_QueryValue_(m_key.m_hkey, m_name, значение, тип);

        if(тип != m_type)
        {
            throw new ИсклРеестра("Тип значения изменён с момента его получения");
        }

        return значение;
    }

    /// Obtains the current значение as a ткст, within which any environment
    /// variables have undergone expansion
    ///
    /// \return The contents of the значение
    /// \note This function works with the same значение-types as Value_SZ().
    ткст значение_Ткст0Развёрт()
    {
        ткст  значение   =   значение_Ткст0;

/+
        значение = expand_environment_strings(значение);

        return значение;
 +/
	// ExpandEnvironemntStrings():
	//	http://msdn2.microsoft.com/en-us/library/ms724265.aspx
        LPCSTR  lpSrc       =   stdrus.вТкст0(значение);
        бцел   cchRequired =   ExpandEnvironmentStringsA(lpSrc, null, 0);
        сим[]  newValue    =   new сим[cchRequired];

        if(!ExpandEnvironmentStringsA(lpSrc, newValue.ptr, newValue.length))
        {
            throw new Win32Exception("Не удалось развернуть переменные среды");
        }

        return stdrus.вТкст(newValue.ptr);	// remove trailing 0
    }

    /// Obtains the current значение as an array of strings
    ///
    /// \return The contents of the значение
    /// \note Throws a ИсклРеестра if the тип of the значение is not МногоТкст0
    ткст[] многострочноеТкст0Значение()
    {
        ПТипЗначенияРеестра  тип;
        ткст[]        значение;

        Reg_QueryValue_(m_key.m_hkey, m_name, значение, тип);

        if(тип != m_type)
        {
            throw new ИсклРеестра("Тип значения был изменён со времени его получения");
        }

        return значение;
    }

    /// Obtains the current значение as a 32-bit unsigned integer, ordered correctly according to the current architecture
    ///
    /// \return The contents of the значение
    /// \note An exception is thrown for all types other than Бцел, БцелЛЕ and БцелБЕ.
    бцел значениеБцел()
    {
        ПТипЗначенияРеестра  тип;
        бцел            значение;

        Reg_QueryValue_(m_key.m_hkey, m_name, значение, тип);

        if(тип != m_type)
        {
            throw new ИсклРеестра("Тип значения был извенен со времени его получения");
        }

        return значение;
    }

    /// Obtains the значение as a 64-bit unsigned integer, ordered correctly according to the current architecture
    ///
    /// \return The contents of the значение
    /// \note Throws a ИсклРеестра if the тип of the значение is not Бцел64
    бдол значениеБдол()
    {
        ПТипЗначенияРеестра  тип;
        бдол           значение;

        Reg_QueryValue_(m_key.m_hkey, m_name, значение, тип);

        if(тип != m_type)
        {
            throw new ИсклРеестра("Тип значения был извенен со времени его получения");
        }

        return значение;
    }

    /// Obtains the значение as a binary blob
    ///
    /// \return The contents of the значение
    /// \note Throws a ИсклРеестра if the тип of the значение is not Бинарный
    байт[]  бинарноеЗначение()
    {
        ПТипЗначенияРеестра  тип;
        байт[]          значение;

        Reg_QueryValue_(m_key.m_hkey, m_name, значение, тип);

        if(тип != m_type)
        {
            throw new ИсклРеестра("Тип значения был извенен со времени его получения");
        }

        return значение;
    }
//@}

/// \имя Members
//@{
private:
    Ключ             m_key;
    ПТипЗначенияРеестра  m_type;
    ткст         m_name;
//@}
}

////////////////////////////////////////////////////////////////////////////////
// Реестр

/// Represents the local system registry.
///
/// \ingroup group_D_win32_reg

export extern(D) class Реестр
{
private:
    static this()
    {
        sm_keyClassesRoot       = new Ключ(  Reg_Dup_(HKEY_CLASSES_ROOT)
                                        ,   "HKEY_CLASSES_ROOT", false);
        sm_keyCurrentUser       = new Ключ(  Reg_Dup_(HKEY_CURRENT_USER)
                                        ,   "HKEY_CURRENT_USER", false);
        sm_keyLocalMachine      = new Ключ(  Reg_Dup_(HKEY_LOCAL_MACHINE)
                                        ,   "HKEY_LOCAL_MACHINE", false);
        sm_keyUsers             = new Ключ(  Reg_Dup_(HKEY_USERS)
                                        ,   "HKEY_USERS", false);
        sm_keyPerformanceData   = new Ключ(  Reg_Dup_(HKEY_PERFORMANCE_DATA)
                                        ,   "HKEY_PERFORMANCE_DATA", false);
        sm_keyCurrentConfig     = new Ключ(  Reg_Dup_(HKEY_CURRENT_CONFIG)
                                        ,   "HKEY_CURRENT_CONFIG", false);
        sm_keyDynData           = new Ключ(  Reg_Dup_(HKEY_DYN_DATA)
                                        ,   "HKEY_DYN_DATA", false);
    }

export:
    this() {  }

/// \имя Hives
//@{

    /// Returns the root ключ for the HKEY_CLASSES_ROOT hive
    static Ключ  кореньКлассов()       {   return sm_keyClassesRoot;       }
    /// Returns the root ключ for the HKEY_CURRENT_USER hive
    static Ключ  текущийПользователь()       {   return sm_keyCurrentUser;       }
    /// Returns the root ключ for the HKEY_LOCAL_MACHINE hive
    static Ключ  локальнаяМашина()      {   return sm_keyLocalMachine;      }
    /// Returns the root ключ for the HKEY_USERS hive
    static Ключ  пользователи()             {   return sm_keyUsers;             }
    /// Returns the root ключ for the HKEY_PERFORMANCE_DATA hive
    static Ключ  данныеПроизводительности()   {   return sm_keyPerformanceData;   }
    /// Returns the root ключ for the HKEY_CURRENT_CONFIG hive
    static Ключ  текущаяКонфигурация()     {   return sm_keyCurrentConfig;     }
    /// Returns the root ключ for the HKEY_DYN_DATA hive
    static Ключ  динДанные()           {   return sm_keyDynData;           }
//@}

private:
    static Ключ  sm_keyClassesRoot;
    static Ключ  sm_keyCurrentUser;
    static Ключ  sm_keyLocalMachine;
    static Ключ  sm_keyUsers;
    static Ключ  sm_keyPerformanceData;
    static Ключ  sm_keyCurrentConfig;
    static Ключ  sm_keyDynData;
}

////////////////////////////////////////////////////////////////////////////////
// РядИмёнКлючей

/// An enumerable sequence representing the names of the sub-ключи of a registry Ключ
///
/// It would be used as follows:
///
/// <код>&nbsp;&nbsp;Ключ&nbsp;ключ&nbsp;=&nbsp;. . .</код>
/// <br>
/// <код></код>
/// <br>
/// <код>&nbsp;&nbsp;foreach(сим[] kName; ключ.SubKeys)</код>
/// <br>
/// <код>&nbsp;&nbsp;{</код>
/// <br>
/// <код>&nbsp;&nbsp;&nbsp;&nbsp;process_Key(kName);</код>
/// <br>
/// <код>&nbsp;&nbsp;}</код>
/// <br>
/// <br>
///
/// \ingroup group_D_win32_reg

export extern(D) class РядИмёнКлючей
{
    invariant()
    {
        assert(!(null is m_key));
    }

/// Construction
export:
    this(Ключ ключ)
    {
        m_key = ключ;
    }

/// \имя Attributes
///@{

    /// The number of ключи
    бцел количество()
    {
        return m_key.члоПодключей();
    }

    /// The имя of the ключ at the given индекс
    ///
    /// \param индекс The 0-based индекс of the ключ to retrieve
    /// \return The имя of the ключ corresponding to the given индекс
    /// \note Throws a ИсклРеестра if no corresponding ключ is retrieved
    ткст дайИмяКлюча(бцел индекс)
    {
        бцел   cSubKeys;
        бцел   cchSubKeyMaxLen;
        HKEY    hkey    =   m_key.m_hkey;
        LONG    res     =   Reg_GetNumSubKeys_(hkey, cSubKeys, cchSubKeyMaxLen);
        сим[]  sName   =   new сим[1 + cchSubKeyMaxLen];
        бцел   cchName;

        assert(ERROR_SUCCESS == res);

        res = Reg_EnumKeyName_(hkey, индекс, sName, cchName);

        assert(ERROR_MORE_DATA != res);

        if(ERROR_SUCCESS != res)
        {
            throw new ИсклРеестра("Неверный ключ", res);
        }

        return cast(ткст)sName[0 .. cchName];
    }

    /// The имя of the ключ at the given индекс
    ///
    /// \param индекс The 0-based индекс of the ключ to retrieve
    /// \return The имя of the ключ corresponding to the given индекс
    /// \note Throws a ИсклРеестра if no corresponding ключ is retrieved
    ткст opIndex(бцел индекс)
    {
        return дайИмяКлюча(индекс);
    }

    цел opApply(цел delegate(inout ткст имя) dg)
    {
        цел     result  =   0;
        HKEY    hkey    =   m_key.m_hkey;
        бцел   cSubKeys;
        бцел   cchSubKeyMaxLen;
        LONG    res     =   Reg_GetNumSubKeys_(hkey, cSubKeys, cchSubKeyMaxLen);
        сим[]  sName   =   new сим[1 + cchSubKeyMaxLen];

        assert(ERROR_SUCCESS == res);

        for(бцел индекс = 0; 0 == result; ++индекс)
        {
            бцел   cchName;

            res =   Reg_EnumKeyName_(hkey, индекс, sName, cchName);
            assert(ERROR_MORE_DATA != res);

            if(ERROR_NO_MORE_ITEMS == res)
            {
                // Enumeration complete

                break;
            }
            else if(ERROR_SUCCESS == res)
            {
                ткст имя = cast(ткст)sName[0 .. cchName];

                result = dg(имя);
            }
            else
            {
                throw new ИсклРеестра("Неполный перечень имён ключей", res);
            }
        }

        return result;
    }

/// Members
private:
    Ключ m_key;
}


////////////////////////////////////////////////////////////////////////////////
// РядКлючей

/// An enumerable sequence representing the sub-ключи of a registry Ключ
///
/// It would be used as follows:
///
/// <код>&nbsp;&nbsp;Ключ&nbsp;ключ&nbsp;=&nbsp;. . .</код>
/// <br>
/// <код></код>
/// <br>
/// <код>&nbsp;&nbsp;foreach(Ключ k; ключ.SubKeys)</код>
/// <br>
/// <код>&nbsp;&nbsp;{</код>
/// <br>
/// <код>&nbsp;&nbsp;&nbsp;&nbsp;process_Key(k);</код>
/// <br>
/// <код>&nbsp;&nbsp;}</код>
/// <br>
/// <br>
///
/// \ingroup group_D_win32_reg

export extern(D) class РядКлючей
{
    invariant()
    {
        assert(!(null is m_key));
    }

/// Construction
export:
    this(Ключ ключ)
    {
        m_key = ключ;
    }


    /// The number of ключи
    бцел количество()
    {
        return m_key.члоПодключей();
    }

    /// The ключ at the given индекс
    ///
    /// \param индекс The 0-based индекс of the ключ to retrieve
    /// \return The ключ corresponding to the given индекс
    /// \note Throws a ИсклРеестра if no corresponding ключ is retrieved
    Ключ дайКлюч(бцел индекс)
    {
        бцел   cSubKeys;
        бцел   cchSubKeyMaxLen;
        HKEY    hkey    =   m_key.m_hkey;
        LONG    res     =   Reg_GetNumSubKeys_(hkey, cSubKeys, cchSubKeyMaxLen);
        сим[]  sName   =   new сим[1 + cchSubKeyMaxLen];
        бцел   cchName;

        assert(ERROR_SUCCESS == res);

        res =   Reg_EnumKeyName_(hkey, индекс, sName, cchName);

        assert(ERROR_MORE_DATA != res);

        if(ERROR_SUCCESS != res)
        {
            throw new ИсклРеестра("Неверный ключ", res);
        }

        return m_key.дайКлюч(cast(ткст)sName[0 .. cchName]);
    }

    /// The ключ at the given индекс
    ///
    /// \param индекс The 0-based индекс of the ключ to retrieve
    /// \return The ключ corresponding to the given индекс
    /// \note Throws a ИсклРеестра if no corresponding ключ is retrieved
    Ключ opIndex(бцел индекс)
    {
        return дайКлюч(индекс);
    }


    цел opApply(цел delegate(inout Ключ ключ) dg)
    {
        цел         result  =   0;
        HKEY        hkey    =   m_key.m_hkey;
        бцел       cSubKeys;
        бцел       cchSubKeyMaxLen;
        LONG        res     =   Reg_GetNumSubKeys_(hkey, cSubKeys, cchSubKeyMaxLen);
        сим[]      sName   =   new сим[1 + cchSubKeyMaxLen];

        assert(ERROR_SUCCESS == res);

        for(бцел индекс = 0; 0 == result; ++индекс)
        {
            бцел   cchName;

	    res     =   Reg_EnumKeyName_(hkey, индекс, sName, cchName);
            assert(ERROR_MORE_DATA != res);

            if(ERROR_NO_MORE_ITEMS == res)
            {
                // Enumeration complete

                break;
            }
            else if(ERROR_SUCCESS == res)
            {
                try
                {
                    Ключ ключ =   m_key.дайКлюч(cast(ткст)sName[0 .. cchName]);

                    result = dg(ключ);
                }
                catch(ИсклРеестра x)
                {
                    // Skip inaccessible ключи; they are
                    // accessible via the РядИмёнКлючей
                    if(x.ошиб == ERROR_ACCESS_DENIED)
                    {
                        continue;
                    }

                    throw x;
                }
            }
            else
            {
                throw new ИсклРеестра("Неполный перечень ключей", res);
            }
        }

        return result;
    }

/// Members
private:
    Ключ m_key;
}

////////////////////////////////////////////////////////////////////////////////
// РядИмёнЗначений

/// An enumerable sequence representing the names of the значения of a registry Ключ
///
/// It would be used as follows:
///
/// <код>&nbsp;&nbsp;Ключ&nbsp;ключ&nbsp;=&nbsp;. . .</код>
/// <br>
/// <код></код>
/// <br>
/// <код>&nbsp;&nbsp;foreach(сим[] vName; ключ.Values)</код>
/// <br>
/// <код>&nbsp;&nbsp;{</код>
/// <br>
/// <код>&nbsp;&nbsp;&nbsp;&nbsp;process_Value(vName);</код>
/// <br>
/// <код>&nbsp;&nbsp;}</код>
/// <br>
/// <br>
///
/// \ingroup group_D_win32_reg

export extern(D) class РядИмёнЗначений
{
    invariant()
    {
        assert(!(null is m_key));
    }

/// Construction
export:
    this(Ключ ключ)
    {
        m_key = ключ;
    }

/// \имя Attributes
///@{

    /// The number of значения
    бцел количество()
    {
        return m_key.члоЗначений();
    }

    /// The имя of the значение at the given индекс
    ///
    /// \param индекс The 0-based индекс of the значение to retrieve
    /// \return The имя of the значение corresponding to the given индекс
    /// \note Throws a ИсклРеестра if no corresponding значение is retrieved
    ткст дайИмяЗначения(бцел индекс)
    {
        бцел   cValues;
        бцел   cchValueMaxLen;
        HKEY    hkey    =   m_key.m_hkey;
        LONG    res     =   Reg_GetNumValues_(hkey, cValues, cchValueMaxLen);
        сим[]  sName   =   new сим[1 + cchValueMaxLen];
        бцел   cchName =   1 + cchValueMaxLen;

        assert(ERROR_SUCCESS == res);

        res = Reg_EnumValueName_(hkey, индекс, sName.ptr, cchName);

        if(ERROR_SUCCESS != res)
        {
            throw new ИсклРеестра("Неверное значение", res);
        }

        return cast(ткст)sName[0 .. cchName];
    }

    /// The имя of the значение at the given индекс
    ///
    /// \param индекс The 0-based индекс of the значение to retrieve
    /// \return The имя of the значение corresponding to the given индекс
    /// \note Throws a ИсклРеестра if no corresponding значение is retrieved
    ткст opIndex(бцел индекс)
    {
        return дайИмяЗначения(индекс);
    }

    цел opApply(цел delegate(inout ткст имя) dg)
    {
        цел     result  =   0;
        HKEY    hkey    =   m_key.m_hkey;
        бцел   cValues;
        бцел   cchValueMaxLen;
        LONG    res     =   Reg_GetNumValues_(hkey, cValues, cchValueMaxLen);
        сим[]  sName   =   new сим[1 + cchValueMaxLen];

        assert(ERROR_SUCCESS == res);

        for(бцел индекс = 0; 0 == result; ++индекс)
        {
            бцел   cchName =   1 + cchValueMaxLen;

	    res = Reg_EnumValueName_(hkey, индекс, sName.ptr, cchName);
            if(ERROR_NO_MORE_ITEMS == res)
            {
                // Enumeration complete
                break;
            }
            else if(ERROR_SUCCESS == res)
            {
                ткст имя = cast(ткст)sName[0 .. cchName];

                result = dg(имя);
            }
            else
            {
                throw new ИсклРеестра("Перечень имён значений неполный", res);
            }
        }

        return result;
    }

/// Members
private:
    Ключ m_key;
}

////////////////////////////////////////////////////////////////////////////////
// РядЗначений

/// An enumerable sequence representing the значения of a registry Ключ
///
/// It would be used as follows:
///
/// <код>&nbsp;&nbsp;Ключ&nbsp;ключ&nbsp;=&nbsp;. . .</код>
/// <br>
/// <код></код>
/// <br>
/// <код>&nbsp;&nbsp;foreach(Значение v; ключ.Values)</код>
/// <br>
/// <код>&nbsp;&nbsp;{</код>
/// <br>
/// <код>&nbsp;&nbsp;&nbsp;&nbsp;process_Value(v);</код>
/// <br>
/// <код>&nbsp;&nbsp;}</код>
/// <br>
/// <br>
///
/// \ingroup group_D_win32_reg

export extern(D) class РядЗначений
{
    invariant()
    {
        assert(!(null is m_key));
    }

/// Construction
export:
    this(Ключ ключ)
    {
        m_key = ключ;
    }

/// \имя Attributes
///@{

    /// The number of значения
    бцел количество()
    {
        return m_key.члоЗначений();
    }

    /// The значение at the given индекс
    ///
    /// \param индекс The 0-based индекс of the значение to retrieve
    /// \return The значение corresponding to the given индекс
    /// \note Throws a ИсклРеестра if no corresponding значение is retrieved
    Значение дайЗначение(бцел индекс)
    {
        бцел   cValues;
        бцел   cchValueMaxLen;
        HKEY    hkey    =   m_key.m_hkey;
        LONG    res     =   Reg_GetNumValues_(hkey, cValues, cchValueMaxLen);
        сим[]  sName   =   new сим[1 + cchValueMaxLen];
        бцел   cchName =   1 + cchValueMaxLen;

        assert(ERROR_SUCCESS == res);

        res     =   Reg_EnumValueName_(hkey, индекс, sName.ptr, cchName);

        if(ERROR_SUCCESS != res)
        {
            throw new ИсклРеестра("Неверное значение", res);
        }

        return m_key.дайЗначение(cast(ткст)sName[0 .. cchName]);
    }

    /// The значение at the given индекс
    ///
    /// \param индекс The 0-based индекс of the значение to retrieve
    /// \return The значение corresponding to the given индекс
    /// \note Throws a ИсклРеестра if no corresponding значение is retrieved
    Значение opIndex(бцел индекс)
    {
        return дайЗначение(индекс);
    }

    цел opApply(цел delegate(inout Значение значение) dg)
    {
        цел     result  =   0;
        HKEY    hkey    =   m_key.m_hkey;
        бцел   cValues;
        бцел   cchValueMaxLen;
        LONG    res     =   Reg_GetNumValues_(hkey, cValues, cchValueMaxLen);
        сим[]  sName   =   new сим[1 + cchValueMaxLen];

        assert(ERROR_SUCCESS == res);

        for(бцел индекс = 0; 0 == result; ++индекс)
        {
            бцел   cchName =   1 + cchValueMaxLen;

	    res = Reg_EnumValueName_(hkey, индекс, sName.ptr, cchName);
            if(ERROR_NO_MORE_ITEMS == res)
            {
                // Enumeration complete
                break;
            }
            else if(ERROR_SUCCESS == res)
            {
                Значение значение = m_key.дайЗначение(cast(ткст)sName[0 .. cchName]);

                result = dg(значение);
            }
            else
            {
                throw new ИсклРеестра("Перечень значений неполный", res);
            }
        }

        return result;
    }

/// Members
private:
    Ключ m_key;
}

/* ////////////////////////////////////////////////////////////////////////// */

unittest
{
    Ключ HKCR    =   Реестр.кореньКлассов;
    Ключ CLSID   =   HKCR.дайКлюч("CLSID");

//  foreach(Ключ ключ; CLSID.ключи) // Still cannot use a property as a freachable quantity without calling the prop function
    foreach(Ключ ключ; CLSID.ключи())
    {
//      foreach(Значение val; ключ.Values) // Still cannot use a property as a freachable quantity without calling the prop function
        foreach(Значение val; ключ.значения())
        {
        }
    }
}

/* ////////////////////////////////////////////////////////////////////////// */
