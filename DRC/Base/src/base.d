
/**
* Универсальный рантаймный модуль языка программирования Динрус,
* поддерживающий совместимость с английской версией.
* Разработчик Виталий Кулич
*/
module base;


version = Динрус;
version = Dinrus;
version (Windows)
{
version = ЛитлЭндиан;
}

//Константы
const бул нет = false;
const бул да = true;
const пусто = null;
alias пусто NULL;
//const неук = void; //получить тип от инициализатора не удаётся...

/* ************* Константы *************** */
    /** Строка, используемая для разделения имён папок в пути. Для
     *  Windows является обратным слэшем, для Linux - слэш. */
    const сим[1] РАЗДПАП = "\\";
    /** Alternate version of sep[] used in Windows (а slash). Under
     *  Linux this is empty. */
    const сим[1] АЛЬТРАЗДПАП = "/";
    /** Path separator string. A semi colon under Windows, а colon
     *  under Linux. */
    const сим[1] РАЗДПСТР = ";";
    /** String used to separate lines, \r\n under Windows and \n
     * under Linux. */
    const сим[2] РАЗДСТР = "\r\n"; /// String used to separate lines.
    const сим[1] ТЕКПАП = ".";	 /// String representing the current directory.
    const сим[2] РОДПАП = ".."; /// String representing the parent directory.

const сим[16] ЦИФРЫ16 = "0123456789ABCDEF";			/// 0..9A..F
const сим[10] ЦИФРЫ    = "0123456789";			/// 0..9
const сим[8]  ЦИФРЫ8 = "01234567";				/// 0..7
const сим[92] ПРОПИСНЫЕ = "abcdefghijklmnopqrstuvwxyzабвгдеёжзийклмнопрстуфхцчшщъыьэюя";	/// а..z а..я
const сим[92] СТРОЧНЫЕ = "ABCDEFGHIJKLMNOPQRSTUVWXYZАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ";	/// A..Z А..Я
const сим[184] БУКВЫ   = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" "abcdefghijklmnopqrstuvwxyz" "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ" "абвгдеёжзийклмнопрстуфхцчшщъыьэюя";	/// A..Za..z

const сим[6] ПРОБЕЛЫ = " \t\v\r\n\f";			/// пробелы в ASCII

const сим[3] РС = \u2028; /// Разделитель строк Unicode.
const дим РСд = 0x2028;  /// определено
const сим[3] РА = \u2029; /// Разделитель абзацев Unicode.
const дим РАд = 0x2029;  /// определено
static assert(РС[0] == РА[0] && РС[1] == РА[1]);

/// Метка перехода на новую строку для данной системы
version (Windows)
    const сим[2] НОВСТР = РАЗДСТР;
else version (Posix)
    const сим[1] НОВСТР = "\n";	
alias НОВСТР НС;

/// сигнатуры меток порядка байтов UTF (BOM) 
enum МПБ {
	Ю8,		/// UTF-8
	Ю16ЛЕ,	/// UTF-16 Little Эндиан
	Ю16БЕ,	/// UTF-16 Big Эндиан
	Ю32ЛЕ,	/// UTF-32 Little Эндиан
	Ю32БЕ,	/// UTF-32 Big Эндиан
}

private const цел ЧМПБ = 5;

Эндиан[ЧМПБ] МПБЭндиан = 
[ _эндиан, 
  Эндиан.ЛитлЭндиан, Эндиан.БигЭндиан,
  Эндиан.ЛитлЭндиан, Эндиан.БигЭндиан
  ];

ббайт[][ЧМПБ] МеткиПорядкаБайтов = 
[ [0xEF, 0xBB, 0xBF],
  [0xFF, 0xFE],
  [0xFE, 0xFF],
  [0xFF, 0xFE, 0x00, 0x00],
  [0x00, 0x00, 0xFE, 0xFF]
  ];

const{
	enum Эндиан
	 {
		БигЭндиан,	/// big _эндиан byte order
		ЛитлЭндиан	/// little _эндиан byte order
	 }

	
	version(ЛитлЭндиан)
	{
		/// Native system endianness
			Эндиан _эндиан = Эндиан.ЛитлЭндиан;
	}
	else
	{
			Эндиан _эндиан = Эндиан.БигЭндиан;
	}
  
}	
	
typedef дол т_время;
typedef бцел ФВремяДос;
const т_время т_время_нч = cast(т_время) дол.min;
alias сим рсим;
alias ткст рткст;
/+
alias typeof(delegate) делегат;
alias typeof(function) функция;
alias typeof(struct)    структ;
alias typeof(union)       союз;
+/

alias ткст ДИНРУС_МОДУЛЬ;

const ДИНРУС_МОДУЛЬ
	МД_БАЗА = "Dinrus.Base.dll",
	МД_МЕСА = "Dinrus.Mesa.dll";


extern(C) экз импорт(ДИНРУС_МОДУЛЬ имя);

/**
*Константы математического характера
*/

const реал ЛОГ2Т =      0x1.a934f0979a3715fcp+1;
const реал ЛОГ2Е =      0x1.71547652b82fe178p+0;
const реал ЛОГ2 =       0x1.34413509f79fef32p-2;
const реал ЛОГ10Е =     0.43429448190325182765;
const реал ЛН2 =        0x1.62e42fefa39ef358p-1;
const реал ЛН10 =       2.30258509299404568402;
const реал ПИ =         0x1.921fb54442d1846ap+1;
const реал ПИ_2 =       1.57079632679489661923;
const реал ПИ_4 =       0.78539816339744830962;
const реал М_1_ПИ =     0.31830988618379067154;
const реал М_2_ПИ =     0.63661977236758134308;
const реал М_2_КВКОРПИ = 1.12837916709551257390;
const реал КВКОР2 =      1.41421356237309504880;
const реал КВКОР1_2 =    0.70710678118654752440;

const реал E =          2.7182818284590452354L;

const реал МАКСЛОГ = 0x1.62e42fefa39ef358p+13L;  /** лог(реал.max) */
const реал МИНЛОГ = -0x1.6436716d5406e6d8p+13L; /** лог(реал.min*реал.epsilon) */
const реал ОЙЛЕРГАММА = 0.57721_56649_01532_86060_65120_90082_40243_10421_59335_93992L; /** Euler-Mascheroni constant 0.57721566.. */

const ткст ИМЕЙЛ =
r"[а-zA-Z]([.]?([[а-zA-Z0-9_]-]+)*)?@([[а-zA-Z0-9_]\-_]+\.)+[а-zA-Z]{2,6}";
	
const ткст УРЛ =   r"(([h|H][t|T]|[f|F])[t|T][p|P]([s|S]?)\:\/\/|~/|/)?([\w]+:\w+@)?(([а-zA-Z]{1}([\w\-]+\.)+([\w]{2,5}))(:[\d]{1,5})?)?((/?\w+/)+|/?)(\w+\.[\w]{3,4})?([,]\w+)*((\?\w+=\w+)?(&\w+=\w+)*([,]\w*)*)?";

enum
{
	ЧасовВДне    = 24,
	МинутВЧасе = 60,
	МсекВМинуте    = 60 * 1000,
	МсекВЧасе      = 60 * МсекВМинуте,
	МсекВДень       = 86400000,
	ТиковВМсек     = 1,
	ТиковВСекунду = 1000,			
	ТиковВМинуту = ТиковВСекунду * 60,
	ТиковВЧас   = ТиковВМинуту * 60,
	ТиковВДень    = ТиковВЧас  * 24,
}

enum ПМангл : сим
{
    Тпроц     = 'v',
    Тбул     = 'g',
    Тбайт     = 'b',
    Тббайт    = 'h',
    Ткрат    = 's',
    Тбкрат   = 't',
    Тцел      = 'i',
    Тбцел     = 'k',
    Тдол     = 'l',
    Тбдол    = 'm',
    Тплав    = 'f',
    Тдво   = 'd',
    Треал     = 'e',

    Твплав   = 'o',
    Твдво  = 'p',
    Твреал    = 'j',
    Ткплав   = 'q',
    Ткдво  = 'r',
    Ткреал    = 'c',

    Тсим     = 'a',
    Тшим    = 'u',
    Тдим    = 'w',

    Тмассив    = 'A',
    Тсмассив   = 'G',
    Тамассив   = 'H',
    Туказатель  = 'P',
    Тфункция = 'F',
    Тидент    = 'I',
    Ткласс    = 'C',
    Тструкт   = 'S',
    Тперечень     = 'E',
    Ттипдеф  = 'T',
    Тделегат = 'D',

    Тконст    = 'x',
    Тинвариант = 'y',
}

enum
    {
        СБОЙ_ОП = ~cast(т_мера)0
    }

enum
{   РАЗМЕР_СТРАНИЦЫ =    4096,
    РАЗМЕР_ПОДАЧИ = (4096*16),
    РАЗМЕР_ПУЛА =   (4096*256),
}
const т_мера МАСКА_СТРАНИЦЫ = РАЗМЕР_СТРАНИЦЫ - 1;

	/**
     * Элементы бит-поля, представляющего атрибуты блока памяти. Ими
     * можно манипулировать функциями СМ дайАтр, устАтр, удалиАтр.
     */
    enum ПАтрБлока : бцел
    {
        Финализовать = 0b0000_0001, /// Финализовать данные этого блока при сборке.
        НеСканировать  = 0b0000_0010, /// Не сканировать при сборке данный блок.
        НеПеремещать  = 0b0000_0100,  /// Не перемещать данный блок при сборке.
		МожноДобавить  = 0b0000_1000,
        БезНутра = 0b0001_0000,
		ВсеБиты = 0b1111_1111
    }
	
	
interface ИнфоОтслежИскл
{
    цел opApply( цел delegate( inout ткст ) );
}

version( Windows )
{
    alias wchar wint_t, wchar_t, wctype_t, wctrans_t;

    const wchar WEOF = 0xFFFF;
	alias WEOF ШКФ;
}
else
{
    alias dchar wint_t, wchar_t,  wctype_t, wctrans_t;

    const dchar WEOF = 0xFFFF;
	alias WEOF ШКФ;
}

extern(Windows)
{

alias UINT SOCKET;
alias int socklen_t;

}


  //  alias extern (Windows) int function() FARPROC, NEARPROC, PROC, ПРОЦУК;
extern (Windows) 
{	
version (0)
{   // Properly prototyped versions
   // alias BOOL function(HWND, UINT, WPARAM, LPARAM) DLGPROC;
  //  alias VOID function(HWND, UINT, UINT, DWORD) TIMERPROC;
    alias BOOL function(HDC, LPARAM, int) GRAYSTRINGPROC;
   // alias BOOL function(HWND, LPARAM) WNDENUMPROC;
    //alias LRESULT function(int code, WPARAM wParam, LPARAM lParam) HOOKPROC;
    alias VOID function(HWND, UINT, DWORD, LRESULT) SENDASYNCPROC;
    alias BOOL function(HWND, LPCSTR, HANDLE) PROPENUMPROCA;
    alias BOOL function(HWND, LPCWSTR, HANDLE) PROPENUMPROCW;
    alias BOOL function(HWND, LPSTR, HANDLE, DWORD) PROPENUMPROCEXA;
    alias BOOL function(HWND, LPWSTR, HANDLE, DWORD) PROPENUMPROCEXW;
    alias int function(LPSTR lpch, int ichCurrent, int cch, int code)
       EDITWORDBREAKPROCA;
    alias int function(LPWSTR lpch, int ichCurrent, int cch, int code)
       EDITWORDBREAKPROCW;
    alias BOOL function(HDC hdc, LPARAM lData, WPARAM wData, int cx, int cy)
       DRAWSTATEPROC;
}
else
{
    alias FARPROC DLGPROC;
    alias FARPROC TIMERPROC;
    alias FARPROC GRAYSTRINGPROC;
    alias FARPROC WNDENUMPROC;
    alias FARPROC HOOKPROC;
    alias FARPROC SENDASYNCPROC;
    alias FARPROC EDITWORDBREAKPROCA;
    alias FARPROC EDITWORDBREAKPROCW;
    alias FARPROC PROPENUMPROCA;
    alias FARPROC PROPENUMPROCW;
    alias FARPROC PROPENUMPROCEXA;
    alias FARPROC PROPENUMPROCEXW;
    alias FARPROC DRAWSTATEPROC;
}
}
//Базовые типы языка Динрус
version( X86_64 )
{
    alias ulong т_мера, size_t;
    alias long  т_дельтаук, ptrdiff_t;
}
else
{
    alias uint  т_мера, size_t;
    alias int  т_дельтаук, ptrdiff_t;
}

alias т_мера т_хэш, hash_t;

alias сим[] ткст, симма, string;
alias сим[] *уткст, усимма;

alias wchar[] шткст, шимма, wstring;
alias wchar[] *ушткст, ушимма;

alias dchar[] юткст, димма, dstring;
alias dchar[] *уюткст, удимма;

alias bool бул, бит, bit, BOOLEAN;
alias bool *убул, PBOOLEAN;

extern  (C){

	version( Windows )
	{
		alias int   c_long;
		alias uint  c_ulong;
	}
	else
	{
	  static if( (void*).sizeof > int.sizeof )
	  {
		alias long  c_long;
		alias ulong c_ulong;
	  }
	  else
	  {
		alias int   c_long;
		alias uint  c_ulong;
	  }
	}

    alias int sig_atomic_t;
	
	alias byte      int8_t;
	alias short     int16_t;
	alias int       int32_t;
	alias long      int64_t;
	//alias cent      int128_t;

	alias ubyte     uint8_t;
	alias ushort    uint16_t;
	alias uint      uint32_t;
	alias ulong     uint64_t;
	//alias ucent     uint128_t;

	alias byte      int_least8_t;
	alias short     int_least16_t;
	alias int       int_least32_t;
	alias long      int_least64_t;

	alias ubyte     uint_least8_t;
	alias ushort    uint_least16_t;
	alias uint      uint_least32_t;
	alias ulong     uint_least64_t;

	alias byte      int_fast8_t;
	alias int       int_fast16_t;
	alias int       int_fast32_t;
	alias long      int_fast64_t;

	alias ubyte     uint_fast8_t;
	alias uint      uint_fast16_t;
	alias uint      uint_fast32_t;
	alias ulong     uint_fast64_t;

	version( X86_64 )
	{
		alias long  intptr_t;
		alias ulong uintptr_t;
	}
	else
	{
		alias int   intptr_t;
		alias uint  uintptr_t;
	}

	alias long      intmax_t, т_максцел;
	alias ulong     uintmax_t, т_максбцел;
}

////////////////////////////

alias int цел, т_рав, т_фпоз, equals_t, fexcept_t, fpos_t,LONG, BOOL,WINBOOL, HFILE,
NT, LONG32, INT32, WINT, INT;

alias int *уцел, PINT, LPINT, LPLONG, PWINBOOL, LPWINBOOL, PBOOL, LPBOOL, PLONG,
 PLONG32, PINT32;

alias LONG HRESULT, SCODE, LPARAM, LRESULT;
	
alias uint бцел, ЛКИД, DWORD, UINT, ULONG, FLONG, LCID, ULONG32, DWORD32, UINT32,
CALTYPE, CALID;

alias uint *убцел, PULONG, PUINT, PLCID, LPUINT, PULONG32, PDWORD32, PUINT32;
alias UINT WPARAM;

//DWORD ALIASES
alias DWORD LCTYPE, COLORREF, ACCESS_MASK;

alias ACCESS_MASK *PACCESS_MASK;
alias ACCESS_MASK REGSAM;

alias DWORD *PDWORD, LPDWORD, LPCOLORREF;

alias long дол, LONGLONG, USN, LONG64, INT64;
alias long *удол, PLONGLONG,PLONG64, PINT64;

alias ulong бдол, ULONG64, DWORD64, UINT64, DWORDLONG, ULONGLONG;
alias ulong *убдол, PULONG64, PDWORD64, PUINT64, PDWORDLONG, PULONGLONG;

alias real реал;
alias real *уреал;

alias double дво, double_t;
alias double *удво;

alias char сим, CHAR, CCHAR;
alias char *усим, ткст0, PSZ, PCHAR;
alias CHAR *LPSTR, PSTR, LPCSTR, PCSTR;
//alias LPSTR LPTCH, PTCH, PTSTR, LPTSTR, LPCTSTR;

alias wchar шим, WCHAR;
alias wchar *ушим, шткст0, PWCHAR, LPWCH, PWCH, LPWSTR, PWSTR, LPCWSTR, PCWSTR;
////////////////////////////////////////////////

enum : BOOL
{
    FALSE = 0,
    TRUE = 1,
}

version(Unicode) {
    alias WCHAR TCHAR, _TCHAR;
} else {
    alias CHAR TCHAR, _TCHAR;
}

alias TCHAR* PTCH, PTBYTE, LPTCH, PTSTR, LPTSTR, LP, PTCHAR, LPCTSTR;
alias TCHAR        TBYTE;

alias dchar дим;
alias dchar *удим;

alias byte байт, FCHAR, INT8;
alias byte *убайт, PINT8;

alias ubyte ббайт, BYTE, UCHAR,UINT8;
alias ubyte *уббайт, PUINT8;
alias UCHAR *PUCHAR;
alias BYTE *PBYTE, LPBYTE;

alias short крат, SHORT,INT16;
alias short *украт, PSHORT, PINT16;

alias ushort бкрат, ИДЯз, WORD, USHORT, LANGID, FSHORT,UINT16;
alias ushort *убкрат,PUINT16;
alias USHORT *PUSHORT;
alias WORD    ATOM, АТОМ;
alias WORD *PWORD, LPWORD;

alias float плав, float_t, FLOAT;
alias float *уплав, PFLOAT;

alias void проц, VOID;

alias void *ук, спис_ва, va_list, HANDLE, PVOID, LPVOID,
 POINTER, LPCVOID, PVOID64, PCVOID;

alias HANDLE HINST, HGLOBAL, HLOCAL, HWND,
 HINSTANCE, HGDIOBJ, HACCEL, HBITMA, HBRUSH, HCOLORSPACE, HDC, HGLRC,
  HDESK, HENHMETAFILE, HFONT, HICON, HMENU, HMETAFILE, HPALETTE, HPEN,
   HRGN, HRSRC, HMONITOR, HSTR, HTASK, HWINSTA, HKEY, HKL, HBITMAP,
   HDWP,HDDEDATA,HCONV,HSZ, HHOOK,HIMAGELIST, HDROP,HCONVLIST, HRASCONN, HTHEME;

alias HANDLE* PHANDLE, LPHANDLE;


alias char* PANSICHAR;
alias wchar* PWIDECHAR;


 version (Windows) 
                 alias ук Дескр;     
             else
                typedef цел Дескр = -1; 
			
alias ук  ДЕСКР;
alias ДЕСКР гук, лук, экз;

alias HINSTANCE HMODULE;
alias HICON HCURSOR;
alias HKEY *PHKEY;

alias COLORREF ЦВПредст;
alias HBRUSH УКисть;
alias HCURSOR УКурсор;
alias HPEN УПеро;
alias HICON УПиктограмма, УИконка;
alias HFONT УШрифт;
alias HWND УОК;

alias ireal вреал;
alias ireal *увреал;

alias idouble вдво;
alias idouble *увдво;

alias ifloat вплав;
alias ifloat *увплав;

alias creal креал;
alias creal *укреал;

alias cdouble кдво;
alias cdouble *укдво;

alias cfloat кплав;
alias cfloat *укплав;

// ULONG_PTR должен способствовать сохранению указателя в виде целочисленного типа
version (Win64)
{
	alias long __int3264;
	const ulong ADDRESS_TAG_BIT = 0x40000000000;

	alias long INT_PTR, LONG_PTR;
	alias long* PINT_PTR, PLONG_PTR;
	alias ulong UINT_PTR, ULONG_PTR, HANDLE_PTR;
	alias ulong* PUINT_PTR, PULONG_PTR;
	alias int HALF_PTR;
	alias int* PHALF_PTR;
	alias uint UHALF_PTR;
	alias uint* PUHALF_PTR;
}
else // Win32
{
	alias int __int3264;
	const uint ADDRESS_TAG_BIT = 0x80000000;

	alias int INT_PTR, LONG_PTR;
	alias int* PINT_PTR, PLONG_PTR;
	alias uint UINT_PTR, ULONG_PTR, HANDLE_PTR;
	alias uint* PUINT_PTR, PULONG_PTR;
	alias short HALF_PTR;
	alias short* PHALF_PTR;
	alias ushort UHALF_PTR;
	alias ushort* PUHALF_PTR;
}


alias ULONG_PTR SIZE_T, DWORD_PTR;
alias ULONG_PTR* PSIZE_T, PDWORD_PTR;
alias LONG_PTR SSIZE_T;
alias LONG_PTR* PSSIZE_T;



//ип = импортируемая переменная
extern(C)
{
alias  extern int ипЦ; 
alias extern uint ипбЦ; 
alias extern double ипД2; 
alias extern float ипП; 
alias extern void ип; 
alias extern ук ипУ; 
alias extern byte ипБ; 
alias extern ubyte ипбБ; 
alias extern сим ипС; 
alias extern сим *ипуС;
alias extern wchar ипШ;
alias extern wchar *ипуШ;
alias extern long ипД;
alias extern ulong ипбД;
}

alias extern(D) int function() функЦ; 
alias extern(D) uint  function() функбЦ; 
alias extern(D) double  function() функД2; 
alias extern(D) float  function() функП; 
alias extern(D) void  function() функ; 
alias extern(D) ук function() функУ; 
alias extern(D) byte  function() функБ; 
alias extern(D) ubyte  function() функбБ; 
alias extern(D) сим  function() функС; 
alias extern(D) сим *function() функуС;
alias extern(D) wchar  function() функШ;
alias extern(D)  wchar *function() функуШ;
alias extern(D)  Object  function() функО;
alias extern(D)  long  function() функД;
alias extern(D)  ulong  function() функбД;

alias extern (Windows) проц function(цел) винфунк_Ц;
alias extern (Windows) проц function(цел, цел) винфунк_ЦЦ;
alias extern (Windows) проц function(цел, цел, цел) винфунк_ЦЦЦ;
alias extern (Windows) проц function(цел, цел, цел, цел) винфунк_ЦЦЦЦ;
alias extern (Windows) проц function(цел, цел, цел, цел, цел) винфунк_ЦЦЦЦЦ;
alias extern (Windows) проц function(сим, цел, цел) винфунк_СЦЦ;
alias extern (Windows) проц function(ббайт, цел, цел) винфунк_бБЦЦ;


alias extern (Windows) проц function(бцел, цел, цел, цел) винфунк_бЦЦЦЦ; 

alias extern(Windows) цел  function() винфункЦ; 
alias extern (Windows) цел function(сим, цел, цел) винфункЦ_СЦЦ;
alias extern (Windows) цел function(ббайт, цел, цел) винфункЦ_бБЦЦ;
alias extern (Windows) цел function(цел) винфункЦ_Ц;
alias extern (Windows) цел function(цел, цел) винфункЦ_ЦЦ;
alias extern (Windows) цел function(цел, цел, цел) винфункЦ_ЦЦЦ;
alias extern (Windows) цел function(цел, цел, цел, цел) винфункЦ_ЦЦЦЦ;
alias extern (Windows) цел function (ук, бцел, бцел, цел) винфункЦ_УбЦбЦЦ;

alias extern(Windows) бцел  function() винфункбЦ; 
alias extern(Windows) бцел function (ук, бцел, бцел, цел) винфункбЦ_УбЦбЦЦ;
alias  extern (Windows) бцел function(ук) винфункбЦ_У;

alias extern(Windows) дво  function() винфункД2; 
alias extern(Windows) плав  function() винфункП; 
alias extern(Windows) проц  function() винфунк;
alias extern(Windows) ук   function() винфункУ; 
alias extern(Windows) байт  function() винфункБ; 
alias extern(Windows) ббайт  function() винфункбБ; 
alias extern(Windows) сим  function() винфункС; 
alias extern(Windows) усим function() винфункуС;
alias extern(Windows) шим  function() винфункШ;
alias extern(Windows) ушим function() винфункуШ;
alias extern(Windows) дол  function() винфункД;
alias extern(Windows) бдол  function() винфункбД;

alias extern(Windows) бул  function() винфункБ2;
alias extern(Windows) бул function(бцел) винфункБ2_бЦ;

//alias extern (Windows) struct винструкт;
//alias extern (Windows) class винкласс;

alias винфункЦ_УбЦбЦЦ ОКОНПРОЦ;
alias винфункбЦ_УбЦбЦЦ ОТКРФЛХУКПРОЦ;
alias винфункБ2_бЦ ОБРАБПРОЦ;
alias винфункЦ УДПРОЦ;
 alias УДПРОЦ ДЛГПРОЦ;
 alias УДПРОЦ ТАЙМЕРПРОЦ;
 alias УДПРОЦ СЕРСТРПРОЦ;
 alias УДПРОЦ РИССТПРОЦ; 
alias бцел СОКЕТ;
typedef СОКЕТ т_сокет = cast(СОКЕТ)~0;	
alias цел т_длинсок;
alias бцел ЦВЕТ; 
alias шим ОЛЕСИМ;
alias ОЛЕСИМ олес;
alias цел Бул;
alias бцел МАСКА_ДОСТУПА;
alias ук УкТОКЕН_ДОСТУПА;
alias ук УкБИД;
alias бул РЕЖИМ_ОТСЛЕЖИВАНИЯ_КОНТЕКСТА_БЕЗОПАСНОСТИ;
alias бкрат УПР_ДЕСКРИПТОРА_БЕЗОПАСНОСТИ;


alias проц  function( ткст файл, т_мера строка, ткст сооб = пусто ) типПроверОбр;
alias ИнфоОтслежИскл function( ук укз = пусто ) типСледОбр;	
alias проц delegate( ук, ук ) сканФн;
alias бул function() ТестерМодулей;
alias бул function(Объект) ОбработчикСборки;
alias проц delegate( Исключение ) ОбработчикИсключения;
alias extern(D) проц delegate() ddel;
alias extern(D) проц delegate(цел, цел) dint;
alias проц delegate() ПередВходом;
alias проц delegate() ПередВыходом;
alias проц delegate(Объект) ДСобыт, DEvent;

extern (D) typedef цел delegate(ук) т_дг, dg_t;
extern (D) typedef цел delegate(ук, ук) т_дг2, dg2_t;

alias проц delegate( ук, ук ) фнСканВсеНити;

/* Тип для возвратного значения динамических массивов.
 */
alias long т_дмВозврат;

struct СМСтат
	{
		т_мера размерПула;        // общий размер пула
		т_мера испРазмер;        // выделено байтов
		т_мера свобБлоки;      // число блоков, помеченных FREE
		т_мера размСпискаСвобБлоков;    // всего памяти в списках освобождения
		т_мера блокиСтр; 
	}
	alias СМСтат GCStats;	
	/**
     * Содержит инфоагрегат о блоке управляемой памяти. Назначение этой
     * структуры заключается в поддержке более эффективного стиля опроса
     * в тех экземплярах, где требуется более подробная информация.
     *
     * основа = Указатель на основание опрашиваемого блока.
     * размер = Размер блока, вычисляемый от основания.
     * атр = Биты установленных на блоке памяти атрибутов.
     */
	 
	struct ИнфОБл
	{
		ук  основа;
		т_мера размер;
		бцел   атр;
	}
	alias ИнфОБл BlkInfo;
	/**
     * Элементы бит-поля, представляющего атрибуты блока памяти. Ими
     * можно манипулировать функциями дайАтр, устАтр, удалиАтр.
     */

	struct Пространство
	{
		ук Низ;
		ук Верх;
	};

	struct Array
	{
		size_t length;
		byte *data;
		ук ptr;
		
		alias length длина;
		alias data данные;
		alias ptr укз;
	}
alias Array Массив;

struct Complex
{
    real re;
    real im;
}

	struct aaA
	{
		//aaA *left;
		//aaA *right;
		//hash_t hash;
	aaA *next;
    hash_t hash;
		/* key   */
		/* value */
	}

	struct BB
	{
		aaA*[] b;
		size_t nodes;       // общее число узлов aaA
		TypeInfo keyti;     // TODO: заменить на TypeInfo_AssociativeArray, если  доступно через _aaGet()
		aaA*[4] binit;      // начальное значение с[]
	}

	/* Это тип Ассоциативный Массив, который действительно виден программисту,
	 * хотя он и правда, уплотнён.
	 */

	struct AA
	{
		BB* a;
	}
	
	/+class Амас
	{
	private AA амас;
	
	
	}+/
/+	
struct D_CRITICAL_SECTION
{
    D_CRITICAL_SECTION *next;
    //CRITICAL_SECTION cs;
}
+/
alias проц (*ФИНАЛИЗАТОР_СМ)(ук p, бул dummy);

//Функции, экспортируемые рантаймом
extern(C)
{  

    цел printf(усим, ...);
	alias printf эхо; 
	
	void _d_monitor_create(Object);
	void _d_monitor_destroy(Object);
	void _d_monitor_lock(Object);
	int  _d_monitor_unlock(Object);
	//asm
	void _minit();

//exception
	void onAssertError( ткст file, т_мера line );
	void onAssertErrorMsg( ткст file, т_мера line, ткст msg );
	void onArrayBoundsError( ткст file, т_мера line );
	void onFinalizeError( ClassInfo info, Исключение ex );
	void onOutOfMemoryError();
	void onSwitchError( ткст file, т_мера line );
	void onUnicodeError( ткст msg, т_мера idx );
	void onRangeError( string file, т_мера line );
	void onHiddenFuncError( Object o );
	void _d_assert( ткст file, uint line );
	static void _d_assert_msg( ткст msg, ткст file, uint line );
	void _d_array_bounds( ткст file, uint line );
	void _d_switch_error( ткст file, uint line );
	void _d_OutOfMemory();
	
	//ИнфоОтслежИскл контекстТрассировки( ук ptr = null );
	//бул устСледОбр( типСледОбр h );
	//бул устПроверОбр( типПроверОбр h );	
	
}


	/*
extern (C)
{
	
//complex.c
	Complex _complex_div(Complex x, Complex y);
	Complex _complex_mul(Complex x, Complex y);
	// long double _complex_abs(Complex z);
	Complex _complex_sqrt(Complex z);

//critical.c
	void _d_criticalenter(D_CRITICAL_SECTION *dcs);
	void _d_criticalexit(D_CRITICAL_SECTION *dcs);
	void _STI_critical_init();
	void _STD_critical_term();
	
//rt.adi
	long _adReverseChar(сим[] а);
	long _adReverseWchar(wchar[] а);
	long _adReverse(Array а, size_t szelem);
	long _adSortChar(сим[] а);
	long _adSortWchar(wchar[] а);
	int _adEq(Array a1, Array a2, TypeInfo ti);
	int _adEq2(Array a1, Array a2, TypeInfo ti);
	int _adCmp(Array a1, Array a2, TypeInfo ti);
	int _adCmp2(Array a1, Array a2, TypeInfo ti);
	int _adCmpChar(Array a1, Array a2);
	
//rt.aaA
	size_t _aaLen(AA aa);
	void* _aaGet(AA* aa, TypeInfo keyti, size_t valuesize, ...);
	void* _aaGetRvalue(AA aa, TypeInfo keyti, size_t valuesize, ...);
	void* _aaIn(AA aa, TypeInfo keyti, ...);
	void _aaDel(AA aa, TypeInfo keyti, ...);
	т_дмВозврат _aaValues(AA aa, size_t keysize, size_t valuesize);
	void* _aaRehash(AA* paa, TypeInfo keyti);
	void _aaBalance(AA* paa);
	т_дмВозврат _aaKeys(AA aa, size_t keysize);
	int _aaApply(AA aa, size_t keysize, т_дг дг);
	int _aaApply2(AA aa, size_t keysize, т_дг2 дг);
	BB* _d_assocarrayliteralT(TypeInfo_AssociativeArray ti, size_t length, ...);
	int _aaEqual(TypeInfo_AssociativeArray ti, AA e1, AA e2);
	
//rt.aApply
	int _aApplycd1(сим[] aa, т_дг дг);
	int _aApplywd1(wchar[] aa, т_дг дг);
	int _aApplycw1(сим[] aa, т_дг дг);
	int _aApplywc1(wchar[] aa, т_дг дг);
	int _aApplydc1(dchar[] aa, т_дг дг);
	int _aApplydw1(dchar[] aa, т_дг дг);
	int _aApplycd2(сим[] aa, т_дг2 дг);
	int _aApplywd2(wchar[] aa, т_дг2 дг);
	int _aApplycw2(сим[] aa, т_дг2 дг);
	int _aApplywc2(wchar[] aa, т_дг2 дг);
	int _aApplydc2(dchar[] aa, т_дг2 дг);
	int _aApplydw2(dchar[] aa, т_дг2 дг);
	
//rt.aApplyR
	int _aApplyRcd1(in сим[] aa, т_дг дг);
	int _aApplyRwd1(in wchar[] aa, т_дг дг);
	int _aApplyRcw1(in сим[] aa, т_дг дг);
	int _aApplyRwc1(in wchar[] aa, т_дг дг);
	int _aApplyRdc1(in dchar[] aa, т_дг дг);
	int _aApplyRdw1(in dchar[] aa, т_дг дг);
	int _aApplyRcd2(in сим[] aa, т_дг2 дг);
	int _aApplyRwd2(in wchar[] aa, т_дг2 дг);
	int _aApplyRcw2(in сим[] aa, т_дг2 дг);
	int _aApplyRwc2(in wchar[] aa, т_дг2 дг);
	int _aApplyRdc2(in dchar[] aa, т_дг2 дг);
	int _aApplyRdw2(in dchar[] aa, т_дг2 дг);
	
//rt.alloca
	void* __alloca(int nbytes);
	
//rt.arraycast
	void[] _d_arraycast(size_t tsize, size_t fsize, void[] а);
	void[] _d_arraycast_frombit(uint tsize, void[] а);

//rt.arraycat
	byte[] _d_arraycopy(size_t size, byte[] from, byte[] to);
	
//rt.cast
	Object _d_toObject(void* p);
	Object _d_interface_cast(void* p, ClassInfo c);
	Object _d_dynamic_cast(Object o, ClassInfo c);
	int _d_isbaseof2(ClassInfo oc, ClassInfo c, ref  size_t offset);
	int _d_isbaseof(ClassInfo oc, ClassInfo c);
	ук _d_interface_vtbl(ClassInfo ic, Object o);
	
//rt.lifetime
	Object _d_newclass(ClassInfo ci);
	void _d_delinterface(ук p);
	void _d_delclass(Object *p);
	ulong _d_newarrayT(TypeInfo ti, size_t length);
	ulong _d_newarrayiT(TypeInfo ti, size_t length);
	ulong _d_newarraymT(TypeInfo ti, int ndims, ...);
	ulong _d_newarraymiT(TypeInfo ti, int ndims, ...);
	void*  _d_allocmemory(size_t nbytes);
	void _d_delarray(Array *p);
	void _d_delmemory(void  *p);
	void _d_callfinalizer(ук p);	
	void ртФинализуй(ук  p, бул det = да);
	
	byte[] _d_arraysetlengthT(TypeInfo ti, size_t newlength, Array *p);
	byte[] _d_arraysetlengthiT(TypeInfo ti, size_t newlength, Array *p);
	long _d_arrayappendT(TypeInfo ti, Array *px, byte[] y);
	byte[] _d_arrayappendcT(TypeInfo ti, inout byte[] x, ...);
	byte[] _d_arraycatT(TypeInfo ti, byte[] x, byte[] y);	
	byte[] _d_arraycatnT(TypeInfo ti, uint n, ...);
	void*  _d_arrayliteralT(TypeInfo ti, size_t length, ...);
	long _adDupT(TypeInfo ti, Array а);
		
//rt.hash
	hash_t rt_hash_str(ук bStart,size_t длина, hash_t seed=cast(hash_t)0);
	hash_t rt_hash_block(size_t *bStart,size_t длина, hash_t seed=cast(hash_t)0);
	uint rt_hash_utf8(сим[] str, uint seed=0);
	uint rt_hash_utf16(wchar[] str, uint seed=0);
	uint rt_hash_utf32(dchar[] str, uint seed=0);
	hash_t rt_hash_combine( hash_t val1, hash_t val2 );
	uint rt_hash_str_neutral32(ук bStart,uint длина, uint seed=0);
	ulong rt_hash_str_neutral64(ук bStart,ulong длина, ulong seed=0);
	uint rt_hash_combine32( uint знач, uint seed );
	ulong rt_hash_combine64( ulong value, ulong level);
	
//rt.qsort
	long _adSort(Array а, TypeInfo ti);
	
//rt.memset
	short *_memset16(short *p, short value, size_t count);
	int *_memset32(int *p, int value, size_t count);
	long *_memset64(long *p, long value, size_t count);
	cdouble *_memset128(cdouble *p, cdouble value, size_t count);
	real *_memset80(real *p, real value, size_t count);
	creal *_memset160(creal *p, creal value, size_t count);
	ук _memsetn(ук p, ук value, int count, size_t sizelem);

//rt.switch
	int _d_switch_string(сим[][] table, сим[] ca);
	int _d_switch_ustring(wchar[][] table, wchar[] ca);
	int _d_switch_dstring(dchar[][] table, dchar[] ca);
	


//object	
	void _d_monitorrelease(Object h);
	
	
	void _d_notify_release(Object o);
	void _moduleCtor();
	void _moduleCtor2(ModuleInfo[] mi, int skip);
	void _moduleDtor();
	void _moduleUnitTests();
	void _moduleIndependentCtors();

	
	проц создайМонитор(Объект о);
	проц разрушьМонитор(Объект о) ;
	проц блокируйМонитор(Объект о) ;
	цел разблокируйМонитор(Объект о) ;
	
	void _d_monitordelete(Object h, bool det);
	проц удалиМонитор(Объект о, бул уд);	
	
	void _d_monitorenter(Object h);
	проц войдиВМонитор(Объект о);		
	
    void _d_monitorexit(Object h);
	проц выйдиИзМонитора(Объект о);
	void _d_monitor_devt(Monitor* m, Object h);
	проц событиеМонитора(Монитор* м, Объект о);	
	void rt_attachDisposeEvent(Object h, ДСобыт e);
	void rt_detachDisposeEvent(Object h, ДСобыт e);
	int _fatexit(ук);
	
//runtime
	сим[][] ртПолучиАрги(цел аргчло, сим **аргткст);
	бул рт_вЗадержке();
	бул ртПущен();
	бул ртОстановлен();
	бул ртСтарт(ПередВходом передвхо = пусто, ОбработчикИсключения дг = пусто);
	цел ртСтоп(ПередВыходом передвых = пусто, ОбработчикИсключения дг = пусто, цел результат = 0 );	
	проц  ртСоздайОбработчикСледа( Следопыт h );
	Исключение.ИнфОСледе ртСоздайКонтекстСледа( ук  ptr );
	проц  ртУстановиОбработчикСборки(ОбработчикСборки h);
	ук ртНизСтэка();
	ук ртВерхСтэка();
	проц ртСканируйСтатДан( сканФн scan );	
	void _d_callinterfacefinalizer(ук p);
	size_t gc_newCapacity(size_t newlength, size_t size);
	сим[] _d_arrayappendcd(inout сим[] x, dchar c);
	wchar[] _d_arrayappendwd(inout wchar[] x, dchar c);
	//проц устСовместнПам( убайт буф); 	 
	//убайт получиСовместнПам();
	
	
//thread

	void thread_init();
	void thread_attachThis();
	void thread_detachThis();
	void thread_joinAll();

	bool thread_needLock();
	void thread_suspendAll();
	void thread_resumeAll();
	void thread_scanAll( фнСканВсеНити scan, void* текВерхСтека = null );
	void thread_yield();   
	void thread_sleep(double период);
	void fiber_entryPoint();
	void fiber_switchContext( void** oldp, void* newp );
	
	
	 
}

extern (Windows) ук ДайДескрТекущейНити();
//extern (Windows) void d_throw(Object *o);

extern (C) //Возвращает массив определённого типа с заданным количеством элементов
{
 ткст симмас(цел к);
 байт[] байтмас(цел к);
 ббайт[] ббайтмас(цел к);
 плав[] плавмас(цел к);
 дво[] двомас(цел к);
 ткст[] ткстмас(цел к);//выдаёт ошибку; причина неясна
 бдол[] бдолмас(цел к);
 дол[] долмас(цел к);
 цел[] целмас(цел к);
 бцел[] бцелмас(цел к);
 крат[] кратмас(цел к);
 бкрат[] бкратмас(цел к);
 
	проц ошибка(ткст сооб, ткст файл = пусто , т_мера строка = 0 );
		
	проц ошибкаПодтверждения(ткст файл, т_мера строка);
	проц ошибкаГраницМассива(ткст файл, т_мера строка);
	проц ошибкаФинализации(ИнфОКлассе инфо, Исключение ис);
	проц ошибкаНехваткиПамяти();
	проц ошибкаПереключателя(ткст файл, т_мера строка);
	проц ошибкаЮникод(ткст сооб, т_мера индкс);
	проц ошибкаДиапазона(ткст файл, т_мера строка);
	проц ошибкаСкрытойФункции(Объект о);
	
}*/

//extern(C) ук адаптВыхУкз(ук укз);
//extern(C) ук адаптВхоУкз(ук укз);