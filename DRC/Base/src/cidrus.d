module cidrus;

import /*rt.console*/ std.string: toStringz, toString;
 import std.utf: toUTF16z;
 public import tpl.args;
 
 alias toStringz вТкст0;
alias toString вТкст;

enum ППозКурсора {
  Уст,
  Тек,
  Кон,   
}

 enum
    {
	ФУК_ДОБАВКА	= 0x04,
	ФУК_УСТРВО	= 0x08,
	ФУК_ТЕКСТ	= 0x10,
	ФУК_БАЙТ	= 0x20,
	ФУК_ШИМ	= 0x40,
   
    ВВФБФ   = 0,
    ВВЛБФ   = 0x40,
	ВВНБФ   = 4,
    ВВЧИТ  = 1,	  // non-standard
    ВВЗАП   = 2,	  // non-standard
    ВВМОЙБУФ = 8,	  // non-standard	
    ВВКФ   = 0x10,  // non-standard
    ВВОШ   = 0x20,  // non-standard
    ВВСТРЖ  = 0x40,  // non-standard
    ВВЧЗ    = 0x80,  // non-standard
    ВВТРАН  = 0x100, // non-standard
    ВВПРИЛ   = 0x200, // non-standard
    }

 enum
    {
        РАЗМБУФ       = 0x4000,
        КФ          = -1,//конец файла
        МАКС_ОТКРФ    = 20,
        МАКС_ИМЯФ = 256, // 255 plus NULL
        МАКС_ВРЕМ      = 32767,
        СИС_ОТКР     = 20,	// non-standard
    }

const шим ШКФ = 0xFFFF;

const дво ДВОБЕСК      = дво.infinity;
const дво ПЛАВБЕСК     = плав.infinity;
const дво РЕАЛБЕСК    = реал.infinity;

const СИМБИТ       = 8;
const БАЙТМИН      = байт.min;
const БАЙТМАКС      = байт.max;
const ББАЙТМИН      = ббайт.min;
const СИММИН       = сим.min;
const СИММАКС       = сим.max;
const МБДЛИНМАКС     = 2;
const КРАТМИН       = крат.min;
const КРАТМАКС       = крат.max;
const БКРАТМАКС      = бкрат.max;
const ЦЕЛМИН        = цел.min;
const ЦЕЛМАКС        = цел.max;
const БЦЕЛМАКС       = бцел.max;
const ДОЛМИН      = дол.min;
const ДОЛМАКС      = дол.max;
const БДОЛМАКС     = бдол.max;

const ПЛАВОКРУГЛ			= 1;
const ПЛАВМЕТОДОЦЕНКИ	= 2;
const ПЛАВКОРЕНЬ			= 2;

const ПЛАВЦИФР			= плав.dig;
const ДВОЦИФР			= дво.dig;
const РЕАЛЦИФР			= реал.dig;

const ПЛАВМАНТЦИФР		= плав.mant_dig;
const ДВОМАНТЦИФР		= дво.mant_dig;
const РЕАЛМАНТЦИФР		= реал.mant_dig;

const ПЛАВМИН			= плав.min;
const ДВОМИН			= дво.min;
const РЕАЛМИН			= реал.min;

const ПЛАВМАКС			= плав.max;
const ДВОМАКС			= дво.max;
const РЕАЛМАКС			= реал.max;

const ПЛАВЭПС		= плав.epsilon;
const ДВОЭПС		= дво.epsilon;
const РЕАЛЭПС		= реал.epsilon;

const ПЛАВМИНЭКСП		= плав.min_exp;
const ДВОМИНЭКСП		= дво.min_exp;
const РЕАЛМИНЭКСП		= реал.min_exp;

const ПЛАВМАКСЭКСП		= плав.max_exp;
const ДВОМАКСЭКСП		= дво.max_exp;
const РЕАЛМАКСЭКСП		= реал.max_exp;

const ПЛАВМИН10ЭКСП		= плав.min_10_exp;
const ДВОМИН10ЭКСП		= дво.min_10_exp;
const РЕАЛМИН10ЭКСП	= реал.min_10_exp;

const ПЛАВМАКС10ЭКСП		= плав.max_10_exp;
const ДВОМАКС10ЭКСП		= дво.max_10_exp;
const РЕАЛМАКС10ЭКСП	= реал.max_10_exp;

const плав БЕСКОНЕЧНОСТЬ       = плав.infinity;
const плав Н_Ч            = плав.nan;

const цел ПЗ_ИЛОГБ0        = цел.min;
const цел ПЗ_ИЛОГБНЧ      = цел.min;

const цел МАТОШ       = 1;//математическая ошибка
const цел МАТОШИСКЛ   = 2;
const цел матошобработка = МАТОШ | МАТОШИСКЛ;

const ЛП_СИТИП          = 0;
const ЛП_ЧИСЛО        = 1;
const ЛП_ВРЕМЯ           = 2;
const ЛП_КОЛЛЕЙТ        = 3;
const ЛП_МОНЕТА       = 4;
const ЛП_ВСЕ            = 6;
const ЛП_БУМАГА          = 7;  // non-standard
const ЛП_ИМЯ           = 8;  // non-standard
const ЛП_АДРЕС        = 9;  // non-standard
const ЛП_ТЕЛЕФОН      = 10; // non-standard
const ЛП_МЕРА    = 11; // non-standard
const ЛП_ИДЕНТИФИКАЦИЯ = 12; // non-standard

enum ФИскл
{
    Повреждён      = 1,
    Ненорм     = 2, // non-standard
    ДелениеНаНоль    = 4,
    Переполнение     = 8,
    Недополнение    = 0x10,
    Неточность      = 0x20,
    ВсеИскл   = 0x3F,
    КБлиж    = 0,
    Выше       = 0x800,
    Ниже     = 0x400,
    КНулю   = 0xC00,
}

extern(C)
{
//сиэф = экспортируемая си-функция
alias  проц function() сифунк;
alias проц function(цел) сифунк_Ц;
alias проц function(цел, цел) сифунк_ЦЦ;
alias проц function(цел, цел, цел) сифунк_ЦЦЦ;
alias проц function(цел, цел, цел, цел) сифунк_ЦЦЦЦ;
alias проц function(цел, цел, цел, цел, цел) сифунк_ЦЦЦЦЦ;
alias проц function(сим, цел, цел) сифунк_СЦЦ;
alias проц function(ббайт, цел, цел) сифунк_бБЦЦ;
alias  проц function(ук) сифунк_У;
alias проц function(бцел, цел, цел, цел) сифунк_бЦЦЦЦ; 

alias цел function() сифункЦ; 
alias цел function(сим, цел, цел) сифункЦ_СЦЦ;
alias цел function(ббайт, цел, цел) сифункЦ_бБЦЦ;
alias цел function(цел) сифункЦ_Ц;
alias цел function(цел, цел) сифункЦ_ЦЦ;
alias цел function(цел, цел, цел) сифункЦ_ЦЦЦ;
alias цел function(цел, цел, цел, цел) сифункЦ_ЦЦЦЦ;
alias цел function (ук, бцел, бцел, цел) сифункЦ_УбЦбЦЦ;

alias бцел function() сифункбЦ; 
alias бцел function (ук, бцел, бцел, цел) сифункбЦ_УбЦбЦЦ;
alias  бцел function(ук) сифункбЦ_У;

alias дво  function() сифункД2; 
alias плав  function() сифункП; 
alias ук   function() сифункУ; 
alias байт  function() сифункБ; 
alias ббайт  function() сифункбБ; 
alias сим  function() сифункС; 
alias усим function() сифункуС;
alias шим  function() сифункШ;
alias ушим function() сифункуШ;
alias дол  function() сифункД;
alias бдол  function() сифункбД;

alias бул  function() сифункБ2;
alias бул function(бцел) сифункБ2_бЦ;
//alias struct систрукт;
//alias class сикласс;
}

alias проц function(цел) т_сигфн, sigfn_t;


//const wchar WEOF = 0xFFFF;	 
 const CHAR_BIT       = 8;
const SCHAR_MIN      = byte.min;
const SCHAR_MAX      = byte.max;
const UCHAR_MAX      = ubyte.min;
const CHAR_MIN       = сим.max;
const CHAR_MAX       = сим.max;
const MB_LEN_MAX     = 2;
const SHRT_MIN       = short.min;
const SHRT_MAX       = short.max;
const USHRT_MAX      = ushort.max;
const INT_MIN        = int.min;
const INT_MAX        = int.max;
const UINT_MAX       = uint.max;
const LONG_MIN       = c_long.min;
const LONG_MAX       = c_long.max;
const ULONG_MAX      = c_ulong.max;
const LLONG_MIN      = long.min;
const LLONG_MAX      = long.max;
const ULLONG_MAX     = ulong.max;

const int FP_ILOGB0        = int.min;
const int FP_ILOGBNAN      = int.min;
 
const УДАЧНЫЙ_ВЫХОД = 0;
const НЕУДАЧНЫЙ_ВЫХОД = 1;
const СЛУЧ_МАКС     = 32767;
const МБ_ТЕК_МАКС   = 1;
 
     enum
    {
        FP_NANS        = 0,
        FP_NANQ        = 1,
        FP_INFINITE    = 2,
        FP_NORMAL      = 3,
        FP_SUBNORMAL   = 4,
        FP_ZERO        = 5,
        FP_NAN         = FP_NANQ,
        FP_EMPTY       = 6,
        FP_UNSUPPORTED = 7,
    }
	
enum
{
    SEEK_SET,
    SEEK_CUR,
    SEEK_END
}
	
 

extern  (C) 
{
	
	struct div_t
	{
		int quot,
			rem;
	}


struct ldiv_t
	{
		int quot,
			rem;
	}
struct lldiv_t
	{
		long quot,
			 rem;
	}
	
struct imaxdiv_t
{
    intmax_t    quot,
                rem;
}


intmax_t  imaxabs(intmax_t j);
imaxdiv_t imaxdiv(intmax_t numer, intmax_t denom);
intmax_t  strtoimax(in сим* nptr, сим** endptr, int base);
uintmax_t strtoumax(in сим* nptr, сим** endptr, int base);
intmax_t  wcstoimax(in wchar_t* nptr, wchar_t** endptr, int base);
uintmax_t wcstoumax(in wchar_t* nptr, wchar_t** endptr, int base);



void _c_exit();
void _cexit();
void _exit(int);
void abort();
void _dodtors();
int getpid();
void    exit(int status);
int     atexit(void function() func);
void    _Exit(int status);



enum { _P_WAIT, _P_NOWAIT, _P_OVERLAY };

int execl(сим *, сим *,...);
int execle(сим *, сим *,...);
int execlp(сим *, сим *,...);
int execlpe(сим *, сим *,...);
int execv(сим *, сим **);
int execve(сим *, сим **, сим **);
int execvp(сим *, сим **);
int execvpe(сим *, сим **, сим **);


enum { WAIT_CHILD, WAIT_GRANDCHILD }

int cwait(int *,int,int);
int wait(int *);

version (Windows)
{

alias void function(void *) _У;
    uint _beginthread( _У ,uint, void *);

    extern  (Windows) alias uint (*stdfp)(void *);

    uint _beginthreadex(void* security, uint stack_size,
	    stdfp start_addr, void* arglist, uint initflag,
	    uint* thrdaddr);

    void _endthread();
    void _endthreadex(uint);

    int spawnl(int, сим *, сим *,...);
    int spawnle(int, сим *, сим *,...);
    int spawnlp(int, сим *, сим *,...);
    int spawnlpe(int, сим *, сим *,...);
    int spawnv(int, сим *, сим **);
    int spawnve(int, сим *, сим **, сим **);
    int spawnvp(int, сим *, сим **);
    int spawnvpe(int, сим *, сим **, сим **);


    int _wsystem(wchar_t *);
    int _wspawnl(int, wchar_t *, wchar_t *, ...);
    int _wspawnle(int, wchar_t *, wchar_t *, ...);
    int _wspawnlp(int, wchar_t *, wchar_t *, ...);
    int _wspawnlpe(int, wchar_t *, wchar_t *, ...);
    int _wspawnv(int, wchar_t *, wchar_t **);
    int _wspawnve(int, wchar_t *, wchar_t **, wchar_t **);
    int _wspawnvp(int, wchar_t *, wchar_t **);
    int _wspawnvpe(int, wchar_t *, wchar_t **, wchar_t **);

    int _wexecl(wchar_t *, wchar_t *, ...);
    int _wexecle(wchar_t *, wchar_t *, ...);
    int _wexeclp(wchar_t *, wchar_t *, ...);
    int _wexeclpe(wchar_t *, wchar_t *, ...);
    int _wexecv(wchar_t *, wchar_t **);
    int _wexecve(wchar_t *, wchar_t **, wchar_t **);
    int _wexecvp(wchar_t *, wchar_t **);
    int _wexecvpe(wchar_t *, wchar_t **, wchar_t **);
}


int iswalnum(wint_t wc);
int iswalpha(wint_t wc);
int iswblank(wint_t wc);
int iswcntrl(wint_t wc);
int iswdigit(wint_t wc);
int iswgraph(wint_t wc);
int iswlower(wint_t wc);
int iswprint(wint_t wc);
int iswpunct(wint_t wc);
int iswspace(wint_t wc);
int iswupper(wint_t wc);
int iswxdigit(wint_t wc);

int       iswctype(wint_t wc, wctype_t desc);
wctype_t  wctype(in сим* property);
wint_t    towlower(wint_t wc);
wint_t    towupper(wint_t wc);
wint_t    towctrans(wint_t wc, wctrans_t desc);
wctrans_t wctrans(in сим* property);
	
void* memchr(in void* s, int c, size_t n);
int   memcmp(in void* s1, in void* s2, size_t n);
void* memcpy(void* s1, in void* s2, size_t n);
void* memmove(void* s1, in void* s2, size_t n);
void* memset(void* s, int c, size_t n);

сим*  strcpy(сим* s1, in сим* s2);
сим*  strncpy(сим* s1, in сим* s2, size_t n);
сим*  strcat(сим* s1, in сим* s2);
сим*  strncat(сим* s1, in сим* s2, size_t n);
int    strcmp(in сим* s1, in сим* s2);
int    strcoll(in сим* s1, in сим* s2);
int    strncmp(in сим* s1, in сим* s2, size_t n);
size_t strxfrm(сим* s1, in сим* s2, size_t n);
сим*  strchr(in сим* s, int c);
size_t strcspn(in сим* s1, in сим* s2);
сим*  strpbrk(in сим* s1, in сим* s2);
сим*  strrchr(in сим* s, int c);
size_t strspn(in сим* s1, in сим* s2);
сим*  strstr(in сим* s1, in сим* s2);
сим*  strtok(сим* s1, in сим* s2);
сим*  strerror(int errnum);
size_t strlen(in сим* s);

int memicmp(сим* s1, сим* s2, size_t n);
		
	int _fputc_nlock(int, FILE*);
	int _fputwc_nlock(int, FILE*);
	int _fgetc_nlock(FILE*);
	int _fgetwc_nlock(FILE*);
	int __fp_lock(FILE*);
	проц __fp_unlock(FILE*);
	
	int getErrno();      // for internal use
	int setErrno(int);   // for internal use
	
	    struct fenv_t
    {
        ushort    status;
        ushort    control;
        ushort    round;
        ushort[2] reserved;
    }
	
	void feraiseexcept(int excepts);
	void feclearexcept(int excepts);

	int fetestexcept(int excepts);
	int feholdexcept(fenv_t* envp);

	void fegetexceptflag(fexcept_t* flagp, int excepts);
	void fesetexceptflag(in fexcept_t* flagp, int excepts);

	int fegetround();
	int fesetround(int round);

	void fegetenv(fenv_t* envp);
	void fesetenv(in fenv_t* envp);
	void feupdateenv(in fenv_t* envp);
	
alias creal complex;
alias ireal imaginary;

cdouble cacos(cdouble z);
cfloat  cacosf(cfloat z);
creal   cacosl(creal z);

cdouble casin(cdouble z);
cfloat  casinf(cfloat z);
creal   casinl(creal z);

cdouble catan(cdouble z);
cfloat  catanf(cfloat z);
creal   catanl(creal z);

cdouble ccos(cdouble z);
cfloat  ccosf(cfloat z);
creal   ccosl(creal z);

cdouble csin(cdouble z);
cfloat  csinf(cfloat z);
creal   csinl(creal z);

cdouble ctan(cdouble z);
cfloat  ctanf(cfloat z);
creal   ctanl(creal z);

cdouble cacosh(cdouble z);
cfloat  cacoshf(cfloat z);
creal   cacoshl(creal z);

cdouble casinh(cdouble z);
cfloat  casinhf(cfloat z);
creal   casinhl(creal z);

cdouble catanh(cdouble z);
cfloat  catanhf(cfloat z);
creal   catanhl(creal z);

cdouble ccosh(cdouble z);
cfloat  ccoshf(cfloat z);
creal   ccoshl(creal z);

cdouble csinh(cdouble z);
cfloat  csinhf(cfloat z);
creal   csinhl(creal z);

cdouble ctanh(cdouble z);
cfloat  ctanhf(cfloat z);
creal   ctanhl(creal z);

cdouble cexp(cdouble z);
cfloat  cexpf(cfloat z);
creal   cexpl(creal z);

cdouble clog(cdouble z);
cfloat  clogf(cfloat z);
creal   clogl(creal z);

 double cabs(cdouble z);
 float  cabsf(cfloat z);
 real   cabsl(creal z);

cdouble cpow(cdouble x, cdouble y);
cfloat  cpowf(cfloat x, cfloat y);
creal   cpowl(creal x, creal y);

cdouble csqrt(cdouble z);
cfloat  csqrtf(cfloat z);
creal   csqrtl(creal z);

 double carg(cdouble z);
 float  cargf(cfloat z);
 real   cargl(creal z);

 double cimag(cdouble z);
 float  cimagf(cfloat z);
 real   cimagl(creal z);

cdouble conj(cdouble z);
cfloat  conjf(cfloat z);
creal   conjl(creal z);

cdouble cproj(cdouble z);
cfloat  cprojf(cfloat z);
creal   cprojl(creal z);

// double creal(cdouble z);
 float  crealf(cfloat z);
 real   creall(creal z);
 
int isalnum(int c);
int isalpha(int c);
int isblank(int c);
int iscntrl(int c);
int isdigit(int c);
int isgraph(int c);
int islower(int c);
int isprint(int c);
int ispunct(int c);
int isspace(int c);
int isupper(int c);
int isxdigit(int c);
int tolower(int c);
int toupper(int c);

struct lconv
{
    сим* decimal_point;
    сим* thousands_sep;
    сим* grouping;
    сим* int_curr_symbol;
    сим* currency_symbol;
    сим* mon_decimal_point;
    сим* mon_thousands_sep;
    сим* mon_grouping;
    сим* positive_sign;
    сим* negative_sign;
    byte  int_frac_digits;
    byte  frac_digits;
    byte  p_cs_precedes;
    byte  p_sep_by_space;
    byte  n_cs_precedes;
    byte  n_sep_by_space;
    byte  p_sign_posn;
    byte  n_sign_posn;
    byte  int_p_cs_precedes;
    byte  int_p_sep_by_space;
    byte  int_n_cs_precedes;
    byte  int_n_sep_by_space;
    byte  int_p_sign_posn;
    byte  int_n_sign_posn;
}

сим*  setlocale(int category, in сим* locale);
lconv* localeconv();
	
    uint __fpclassify_f(float x);
    uint __fpclassify_d(double x);
    uint __fpclassify_ld(real x);
	
	 double  acos(double x);
    float   acosf(float x);
    real    acosl(real x);

    double  asin(double x);
    float   asinf(float x);
    real    asinl(real x);

    double  atan(double x);
    float   atanf(float x);
    real    atanl(real x);

    double  atan2(double y, double x);
    float   atan2f(float y, float x);
    real    atan2l(real y, real x);

    double  cos(double x);
    float   cosf(float x);
    real    cosl(real x);

    double  sin(double x);
    float   sinf(float x);
    real    sinl(real x);

    double  tan(double x);
    float   tanf(float x);
    real    tanl(real x);

    double  acosh(double x);
    float   acoshf(float x);
    real    acoshl(real x);

    double  asinh(double x);
    float   asinhf(float x);
    real    asinhl(real x);

    double  atanh(double x);
    float   atanhf(float x);
    real    atanhl(real x);

    double  cosh(double x);
    float   coshf(float x);
    real    coshl(real x);

    double  sinh(double x);
    float   sinhf(float x);
    real    sinhl(real x);

    double  tanh(double x);
    float   tanhf(float x);
    real    tanhl(real x);

    double  exp(double x);
    float   expf(float x);
    real    expl(real x);

    double  exp2(double x);
    float   exp2f(float x);
    real    exp2l(real x);

    double  expm1(double x);
    float   expm1f(float x);
    real    expm1l(real x);

    double  frexp(double value, int* exp);
    float   frexpf(float value, int* exp);
    real    frexpl(real value, int* exp);

    int     ilogb(double x);
    int     ilogbf(float x);
    int     ilogbl(real x);

    double  ldexp(double x, int exp);
    float   ldexpf(float x, int exp);
    real    ldexpl(real x, int exp);

    double  log(double x);
    float   logf(float x);
    real    logl(real x);

    double  log10(double x);
    float   log10f(float x);
    real    log10l(real x);

    double  log1p(double x);
    float   log1pf(float x);
    real    log1pl(real x);

    double  log2(double x);
    float   log2f(float x);
    real    log2l(real x);

    double  logb(double x);
    float   logbf(float x);
    real    logbl(real x);

    double  modf(double value, double* iptr);
    float   modff(float value, float* iptr);
    real    modfl(real value, real *iptr);

    double  scalbn(double x, int n);
    float   scalbnf(float x, int n);
    real    scalbnl(real x, int n);

    double  scalbln(double x, c_long n);
    float   scalblnf(float x, c_long n);
    real    scalblnl(real x, c_long n);

    double  cbrt(double x);
    float   cbrtf(float x);
    real    cbrtl(real x);

    double  fabs(double x);
    float   fabsf(float x);
    real    fabsl(real x);

    double  hypot(double x, double y);
    float   hypotf(float x, float y);
    real    hypotl(real x, real y);

    double  pow(double x, double y);
    float   powf(float x, float y);
    real    powl(real x, real y);

    double  sqrt(double x);
    float   sqrtf(float x);
    real    sqrtl(real x);

    double  erf(double x);
    float   erff(float x);
    real    erfl(real x);

    double  erfc(double x);
    float   erfcf(float x);
    real    erfcl(real x);

    double  lgamma(double x);
    float   lgammaf(float x);
    real    lgammal(real x);

    double  tgamma(double x);
    float   tgammaf(float x);
    real    tgammal(real x);

    double  ceil(double x);
    float   ceilf(float x);
    real    ceill(real x);

    double  floor(double x);
    float   floorf(float x);
    real    floorl(real x);

    double  nearbyint(double x);
    float   nearbyintf(float x);
    real    nearbyintl(real x);

    double  rint(double x);
    float   rintf(float x);
    real    rintl(real x);

    c_long  lrint(double x);
    c_long  lrintf(float x);
    c_long  lrintl(real x);

    long    llrint(double x);
    long    llrintf(float x);
    long    llrintl(real x);

    double  round(double x);
    float   roundf(float x);
    real    roundl(real x);

    c_long  lround(double x);
    c_long  lroundf(float x);
    c_long  lroundl(real x);

    long    llround(double x);
    long    llroundf(float x);
    long    llroundl(real x);

    double  trunc(double x);
    float   truncf(float x);
    real    truncl(real x);

    double  fmod(double x, double y);
    float   fmodf(float x, float y);
    real    fmodl(real x, real y);

    double  remainder(double x, double y);
    float   remainderf(float x, float y);
    real    remainderl(real x, real y);

    double  remquo(double x, double y, int* quo);
    float   remquof(float x, float y, int* quo);
    real    remquol(real x, real y, int* quo);

    double  copysign(double x, double y);
    float   copysignf(float x, float y);
    real    copysignl(real x, real y);

    double  nan(сим* tagp);
    float   nanf(сим* tagp);
    real    nanl(сим* tagp);

    double  nextafter(double x, double y);
    float   nextafterf(float x, float y);
    real    nextafterl(real x, real y);

    double  nexttoward(double x, real y);
    float   nexttowardf(float x, real y);
    real    nexttowardl(real x, real y);

    double  fdim(double x, double y);
    float   fdimf(float x, float y);
    real    fdiml(real x, real y);

    double  fmax(double x, double y);
    float   fmaxf(float x, float y);
    real    fmaxl(real x, real y);

    double  fmin(double x, double y);
    float   fminf(float x, float y);
    real    fminl(real x, real y);

    double  fma(double x, double y, double z);
    float   fmaf(float x, float y, float z);
    real    fmal(real x, real y, real z);
	
	int remove(in сим* filename);
int rename(in сим* from, in сим* to);

FILE* tmpfile();
сим* tmpnam(сим* s);

int   fclose(FILE* stream);
int   fflush(FILE* stream);
FILE* fopen(in сим* filename, in сим* mode);
FILE* freopen(in сим* filename, in сим* mode, FILE* stream);

void setbuf(FILE* stream, сим* buf);
int  setvbuf(FILE* stream, сим* buf, int mode, size_t size);

int fprintf(FILE* stream, in сим* format, ...);
int fscanf(FILE* stream, in сим* format, ...);
int sprintf(сим* s, in сим* format, ...);
int sscanf(in сим* s, in сим* format, ...);
int vfprintf(FILE* stream, in сим* format, va_list арг);
int vfscanf(FILE* stream, in сим* format, va_list арг);
int vsprintf(сим* s, in сим* format, va_list арг);
int vsscanf(in сим* s, in сим* format, va_list арг);
int vprintf(in сим* format, va_list арг);
int vscanf(in сим* format, va_list арг);
//int эхо(in сим* format, ...);
int scanf(in сим* format, ...);

int fgetc(FILE* stream);
int fputc(int c, FILE* stream);

сим* fgets(сим* s, int n, FILE* stream);
int   fputs(in сим* s, FILE* stream);
сим* gets(сим* s);
int   puts(in сим* s);

int ungetc(int c, FILE* stream);

size_t fread(void* ptr, size_t size, size_t nmemb, FILE* stream);
size_t fwrite(in void* ptr, size_t size, size_t nmemb, FILE* stream);

int fgetpos(FILE* stream, fpos_t * pos);
int fsetpos(FILE* stream, in fpos_t* pos);

int    fseek(FILE* stream, c_long offset, int whence);
c_long ftell(FILE* stream);

int   _snprintf(сим* s, size_t n, in сим* fmt, ...);
alias _snprintf snprintf;

int   _vsnprintf(сим* s, size_t n, in сим* format, va_list арг);
alias _vsnprintf vsnprintf;

void perror(in сим* s);

double  atof(in сим* nptr);
int     atoi(in сим* nptr);
c_long  atol(in сим* nptr);
long    atoll(in сим* nptr);

double  strtod(in сим* nptr, сим** endptr);
float   strtof(in сим* nptr, сим** endptr);
real    strtold(in сим* nptr, сим** endptr);
c_long  strtol(in сим* nptr, сим** endptr, int base);
long    strtoll(in сим* nptr, сим** endptr, int base);
c_ulong strtoul(in сим* nptr, сим** endptr, int base);
ulong   strtoull(in сим* nptr, сим** endptr, int base);

int     rand();
void    srand(uint seed);

void*   malloc(size_t size);
void*   calloc(size_t nmemb, size_t size);
void*   realloc(void* ptr, size_t size);
void    free(void* ptr);

сим*   getenv(in сим* name);
int     system(in сим* string);

void*   bsearch(in void* key, in void* base, size_t nmemb, size_t size, int function(in void*, in void*) compar);
void    qsort(void* base, size_t nmemb, size_t size, int function(in void*, in void*) compar);

int     abs(int j);
c_long  labs(c_long j);
long    llabs(long j);

div_t   div(int numer, int denom);
ldiv_t  ldiv(c_long numer, c_long denom);
lldiv_t lldiv(long numer, long denom);

int     mblen(in сим* s, size_t n);
int     mbtowc(wchar_t* pwc, in сим* s, size_t n);
int     wctomb(сим*s, wchar_t wc);
size_t  mbstowcs(wchar_t* pwcs, in сим* s, size_t n);
size_t  wcstombs(сим* s, in wchar_t* pwcs, size_t n);

version( DigitalMars )
	{
		void* alloca(size_t size); // non-standard
		
	}
	
version( Windows )
{
    struct tm
    {
        int     tm_sec;     // seconds after the minute - [0, 60]
        int     tm_min;     // minutes after the hour - [0, 59]
        int     tm_hour;    // hours since midnight - [0, 23]
        int     tm_mday;    // day of the month - [1, 31]
        int     tm_mon;     // months since January - [0, 11]
        int     tm_year;    // years since 1900
        int     tm_wday;    // days since Sunday - [0, 6]
        int     tm_yday;    // days since January 1 - [0, 365]
        int     tm_isdst;   // Daylight Saving Time flag
    }
}
else
{
    struct tm
    {
        int     tm_sec;     // seconds after the minute [0-60]
        int     tm_min;     // minutes after the hour [0-59]
        int     tm_hour;    // hours since midnight [0-23]
        int     tm_mday;    // day of the month [1-31]
        int     tm_mon;     // months since January [0-11]
        int     tm_year;    // years since 1900
        int     tm_wday;    // days since Sunday [0-6]
        int     tm_yday;    // days since January 1 [0-365]
        int     tm_isdst;   // Daylight Savings Time flag
        c_long  tm_gmtoff;  // offset from CUT in seconds
        сим*   tm_zone;    // timezone abbreviation
    }
}

alias c_long time_t;
alias c_long clock_t;


 clock_t CLOCKS_PER_SEC = 1000;


clock_t clock();
double  difftime(time_t time1, time_t time0);
time_t  mktime(tm* timeptr);
time_t  time(time_t* timer);
сим*   asctime(in tm* timeptr);
сим*   ctime(in time_t* timer);
tm*     gmtime(in time_t* timer);
tm*     localtime(in time_t* timer);
size_t  strftime(сим* s, size_t maxsize, in сим* format, in tm* timeptr);

    void  tzset();  		 // non-standard
    void  _tzset(); 		 // non-standard
    сим* _strdate(сим* s); // non-standard
    сим* _strtime(сим* s); // non-standard
	
alias int     mbstate_t;
//alias wchar_t wint_t;

//const wchar_t WEOF = 0xFFFF;

int fwprintf(FILE* stream, in wchar_t* format, ...);
int fwscanf(FILE* stream, in wchar_t* format, ...);
int swprintf(wchar_t* s, size_t n, in wchar_t* format, ...);
int swscanf(in wchar_t* s, in wchar_t* format, ...);
int vfwprintf(FILE* stream, in wchar_t* format, va_list арг);
int vfwscanf(FILE* stream, in wchar_t* format, va_list арг);
int vswprintf(wchar_t* s, size_t n, in wchar_t* format, va_list арг);
int vswscanf(in wchar_t* s, in wchar_t* format, va_list арг);
int vwprintf(in wchar_t* format, va_list арг);
int vwscanf(in wchar_t* format, va_list арг);
int wprintf(in wchar_t* format, ...);
int wscanf(in wchar_t* format, ...);

wint_t fgetwc(FILE* stream);
wint_t fputwc(wchar_t c, FILE* stream);

wchar_t* fgetws(wchar_t* s, int n, FILE* stream);
int      fputws(in wchar_t* s, FILE* stream);

wint_t ungetwc(wint_t c, FILE* stream);
int    fwide(FILE* stream, int mode);

double  wcstod(in wchar_t* nptr, wchar_t** endptr);
float   wcstof(in wchar_t* nptr, wchar_t** endptr);
real    wcstold(in wchar_t* nptr, wchar_t** endptr);
c_long  wcstol(in wchar_t* nptr, wchar_t** endptr, int base);
long    wcstoll(in wchar_t* nptr, wchar_t** endptr, int base);
c_ulong wcstoul(in wchar_t* nptr, wchar_t** endptr, int base);
ulong   wcstoull(in wchar_t* nptr, wchar_t** endptr, int base);

wchar_t* wcscpy(wchar_t* s1, in wchar_t* s2);
wchar_t* wcsncpy(wchar_t* s1, in wchar_t* s2, size_t n);
wchar_t* wcscat(wchar_t* s1, in wchar_t* s2);
wchar_t* wcsncat(wchar_t* s1, in wchar_t* s2, size_t n);
int      wcscmp(in wchar_t* s1, in wchar_t* s2);
int      wcscoll(in wchar_t* s1, in wchar_t* s2);
int      wcsncmp(in wchar_t* s1, in wchar_t* s2, size_t n);
size_t   wcsxfrm(wchar_t* s1, in wchar_t* s2, size_t n);
wchar_t* wcschr(in wchar_t* s, wchar_t c);
size_t   wcscspn(in wchar_t* s1, in wchar_t* s2);
wchar_t* wcspbrk(in wchar_t* s1, in wchar_t* s2);
wchar_t* wcsrchr(in wchar_t* s, wchar_t c);
size_t   wcsspn(in wchar_t* s1, in wchar_t* s2);
wchar_t* wcsstr(in wchar_t* s1, in wchar_t* s2);
wchar_t* wcstok(wchar_t* s1, in wchar_t* s2, wchar_t** ptr);
size_t   wcslen(in wchar_t* s);

wchar_t* wmemchr(in wchar_t* s, wchar_t c, size_t n);
int      wmemcmp(in wchar_t* s1, in wchar_t* s2, size_t n);
wchar_t* wmemcpy(wchar_t* s1, in wchar_t* s2, size_t n);
wchar_t* wmemmove(wchar_t*s1, in wchar_t* s2, size_t n);
wchar_t* wmemset(wchar_t* s, wchar_t c, size_t n);

size_t wcsftime(wchar_t* s, size_t maxsize, in wchar_t* format, in tm* timeptr);

version( Windows )
{
    wchar_t* _wasctime(tm*);      // non-standard
    wchar_t* _wctime(time_t*);	  // non-standard
    wchar_t* _wstrdate(wchar_t*); // non-standard
    wchar_t* _wstrtime(wchar_t*); // non-standard
}

wint_t btowc(int c);
int    wctob(wint_t c);
int    mbsinit(in mbstate_t* ps);
size_t mbrlen(in сим* s, size_t n, mbstate_t* ps);
size_t mbrtowc(wchar_t* pwc, in сим* s, size_t n, mbstate_t* ps);
size_t wcrtomb(сим* s, wchar_t wc, mbstate_t* ps);
size_t mbsrtowcs(wchar_t* dst, in сим** src, size_t len, mbstate_t* ps);
size_t wcsrtombs(сим* dst, in wchar_t** src, size_t len, mbstate_t* ps);

sigfn_t signal(int sig, sigfn_t func);
int     raise(int sig);

}
	
const int     _NFILE     = 60;
extern (C) struct _iobuf
{
align (1):
export:
        сим* _ptr;
        int   _cnt;
        сим* _base;
        int   _flag;
        int   _file;
        int   _симbuf;
        int   _bufsiz;
        int   __tmpnum;
   
        alias _ptr Ук ;
        alias   _cnt Конт;
        alias _base Ова ;
        alias   _flag Флаг ;
        alias   _file Файл ;
        alias   _симbuf Симбуф;
        alias  _bufsiz  Буфразм ;
        alias  __tmpnum  Времчло ;
	
}
alias _iobuf ФАЙЛ, FILE;
alias ФАЙЛ *фук;
extern (C) extern ФАЙЛ[_NFILE] _iob;

const фук стдвхо = &_iob[0];
const фук стдвых = &_iob[1];
const фук стдош = &_iob[2];
const фук стддоп = &_iob[3];
const фук стдпрн = &_iob[4];

	alias стдвхо stdin;
	alias стдвых stdout;
	alias стдош stderr;
	alias стддоп stdaux;
	alias стдпрн stdprn;
	
export extern (C) фук дайСтдвхо(){return стдвхо;}
export extern (C) фук дайСтдвых(){return стдвых;}
export extern (C) фук дайСтдош(){return стдош;}
export extern (C) фук дайСтддоп(){return стддоп;}
export extern (C) фук дайСтдпрн(){return стдпрн;}

 extern (C) extern ubyte __fhnd_info[_NFILE];	
 
    enum
    {
	FHND_APPEND	= 0x04,
	FHND_DEVICE	= 0x08,
	FHND_TEXT	= 0x10,
	FHND_BYTE	= 0x20,
	FHND_WCHAR	= 0x40,
    }
	
    enum
    {
        _IOFBF   = 0,
        _IOLBF   = 0x40,
		_IONBF   = 4,
        _IOREAD  = 1,	  // non-standard
        _IOWRT   = 2,	  // non-standard
        _IOMYBUF = 8,	  // non-standard	
        _IOEOF   = 0x10,  // non-standard
        _IOERR   = 0x20,  // non-standard
        _IOSTRG  = 0x40,  // non-standard
        _IORW    = 0x80,  // non-standard
        _IOTRAN  = 0x100, // non-standard
        _IOAPP   = 0x200, // non-standard
    }
alias дол т_максцел;
alias бдол т_максбцел;

/* export extern (D)
{
    цел getсим()                 { return getc(stdin);     }
    цел putсим(цел c)            { return putc(c,stdout);  }
    цел getc(фук stream)        { return fgetc(stream);   }
    цел putc(цел c, фук stream) { return fputc(c,stream); }
}

extern  (D)
{
    wint_t getwchar()                     { return fgetwc(stdin);     }
    wint_t putwchar(wchar_t c)            { return fputwc(c,stdout);  }
    wint_t getwc(фук stream)            { return fgetwc(stream);    }
    wint_t putwc(wchar_t c, фук stream) { return fputwc(c, stream); }
}


*/

export extern (D)
{


	//цел fpclassify(реал-floating x);
    цел птклассифицируй(плав x)     { return __fpclassify_f(x); }
    цел птклассифицируй(дво x)    { return __fpclassify_d(x); }
    цел птклассифицируй(реал x)
    {
        return (реал.sizeof == дво.sizeof)
            ? __fpclassify_d(x)
            : __fpclassify_ld(x);
    }

    //цел isfinite(реал-floating x);
    цел конечен_ли(плав x)       { return птклассифицируй(x) >= FP_NORMAL; }
    цел конечен_ли(дво x)      { return птклассифицируй(x) >= FP_NORMAL; }
    цел конечен_ли(реал x)        { return птклассифицируй(x) >= FP_NORMAL; }

    //цел isinf(реал-floating x);
    цел беск_ли(плав x)          { return птклассифицируй(x) == FP_INFINITE; }
    цел беск_ли(дво x)         { return птклассифицируй(x) == FP_INFINITE; }
    цел беск_ли(реал x)           { return птклассифицируй(x) == FP_INFINITE; }

    //цел isnan(реал-floating x);
    цел нечисло_ли(плав x)          { return птклассифицируй(x) <= FP_NANQ;   }
    цел нечисло_ли(дво x)         { return птклассифицируй(x) <= FP_NANQ;   }
    цел нечисло_ли(реал x)           { return птклассифицируй(x) <= FP_NANQ;   }

    //цел isnormal(реал-floating x);
    цел нормаль_ли(плав x)       { return птклассифицируй(x) == FP_NORMAL; }
    цел нормаль_ли(дво x)      { return птклассифицируй(x) == FP_NORMAL; }
    цел нормаль_ли(реал x)        { return птклассифицируй(x) == FP_NORMAL; }

    //цел signbit(реал-floating x);
    цел знакбит(плав x)     { return (cast(крат*)&(x))[1] & 0x8000; }
    цел знакбит(дво x)    { return (cast(крат*)&(x))[3] & 0x8000; }
    цел знакбит(реал x)
    {
        return (реал.sizeof == дво.sizeof)
            ? (cast(крат*)&(x))[3] & 0x8000
            : (cast(крат*)&(x))[4] & 0x8000;
    }
	  //цел isgreater(реал-floating x, реал-floating y);
    цел больше_ли(плав x, плав y)        { return !(x !>  y); }
    цел больше_ли(дво x, дво y)      { return !(x !>  y); }
    цел больше_ли(реал x, реал y)          { return !(x !>  y); }

    //цел большеравны_ли(реал-floating x, реал-floating y);
    цел большеравен_ли(плав x, плав y)   { return !(x !>= y); }
    цел большеравен_ли(дво x, дво y) { return !(x !>= y); }
    цел большеравен_ли(реал x, реал y)     { return !(x !>= y); }

    //цел isless(реал-floating x, реал-floating y);
    цел меньше_ли(плав x, плав y)           { return !(x !<  y); }
    цел меньше_ли(дво x, дво y)         { return !(x !<  y); }
    цел меньше_ли(реал x, реал y)             { return !(x !<  y); }

    //цел меньше_ли(реал-floating x, реал-floating y);
    цел меньшеравен_ли(плав x, плав y)      { return !(x !<= y); }
    цел меньшеравен_ли(дво x, дво y)    { return !(x !<= y); }
    цел меньшеравен_ли(реал x, реал y)        { return !(x !<= y); }

    //цел меньше_лиgreater(реал-floating x, реал-floating y);
    цел меньшебольше_ли(плав x, плав y)    { return !(x !<> y); }
    цел меньшебольше_ли(дво x, дво y)  { return !(x !<> y); }
    цел меньшебольше_ли(реал x, реал y)      { return !(x !<> y); }

    //цел isunordered(реал-floating x, реал-floating y);
    цел беспорядочны_ли(плав x, плав y)      { return (x !<>= y); }
    цел беспорядочны_ли(дво x, дво y)    { return (x !<>= y); }
    цел беспорядочны_ли(реал x, реал y)        { return (x !<>= y); }
	  дво  акос(дво x){return acos(x);}
    плав   акосп(плав x){return acosf(x);}
    реал    акосд(реал x){return acosl(x);}

    дво  асин(дво x){return asin(x);}
    плав   асинп(плав x){return asinf(x);}
    реал    асинд(реал x){return asinl(x);}

    дво  атан(дво x){return atan(x);}
    плав   атанп(плав x){return atanf(x);}
    реал    атанд(реал x){return atanl(x);}

    дво  атан2(дво y, дво x){return atan2(y, x);}
    плав   атан2п(плав y, плав x){return atan2f(y, x);}
    реал    атан2д(реал y, реал x){return atan2l(y, x);}

    дво  кос(дво x){return cos(x);}
    плав   косп(плав x){return cosf(x);}
    реал    косд(реал x){return cosl(x);}

    дво  син(дво x){return sin(x);}
    плав   синп(плав x){return sinf(x);}
    реал    синд(реал x){return sinl(x);}

    дво  тан(дво x){return tan(x);}
    плав   танп(плав x){return tanf(x);}
    реал    танд(реал x){return tanl(x);}

    дво  акосг(дво x){return acosh(x);}
    плав   акосгп(плав x){return acoshf(x);}
    реал    акосгд(реал x){return acoshl(x);}

    дво  асинг(дво x){return asinh(x);}
    плав   асингп(плав x){return asinhf(x);}
    реал    асингд(реал x){return asinhl(x);}

    дво  атанг(дво x){return atanh(x);}
    плав   атангп(плав x){return atanhf(x);}
    реал    атангд(реал x){return atanhl(x);}

    дво  косг(дво x){return cosh(x);}
    плав   косгп(плав x){return coshf(x);}
    реал    косгд(реал x){return coshl(x);}

    дво  синг(дво x){return sinh(x);}
    плав   сингп(плав x){return sinhf(x);}
    реал    сингд(реал x){return sinhl(x);}

    дво  танг(дво x){return tanh(x);}
    плав   тангп(плав x){return tanhf(x);}
    реал    тангд(реал x){return tanhl(x);}

    дво  эксп(дво x){return exp(x);}
    плав   экспп(плав x){return expf(x);}
    реал    экспд(реал x){return expl(x);}

    дво  эксп2(дво x){return exp2(x);}
    плав   эксп2п(плав x){return exp2f(x);}
    реал    эксп2д(реал x){return exp2l(x);}

    дво  экспм1(дво x){return expm1(x);}
    плав  экспм1п(плав x){return expm1f(x);}
    реал    экспм1д(реал x){return expm1l(x);}

    дво  фрэксп(дво value, цел* exp){return frexp(value, exp);}//
    плав   фрэкспп(плав value, цел* exp){return frexpf(value, exp);}//
    реал   фрэкспд(реал value, цел* exp){return frexpl(value, exp);}//!!!!!!!!!!!!!!!!!!

    цел     илогб(дво x){return ilogb(x);}
    цел     илогбп(плав x){return ilogbf(x);}
    цел     илогбд(реал x){return ilogbl(x);}
/*
    дво  ldexp(дво x, цел exp){return ldexp(x, exp);}
    плав   ldexpf(плав x, цел exp){return ldexpf(x, exp);}
    реал    ldexpl(реал x, цел exp){return ldexpl(x, exp);}
*/
    дво  лог(дво x){return log(x);}
    плав   логп(плав x){return logf(x);}
    реал    логд(реал x){return logl(x);}

    дво  лог10(дво x){return log10(x);}
    плав   лог10п(плав x){return log10f(x);}
    реал    лог10д(реал x){return log10l(x);}

    дво  лог1п(дво x){return log1p(x);}
    плав   лог1пп(плав x){return log1pf(x);}
    реал    лог1пд(реал x){return log1pl(x);}

    дво  лог2(дво x){return log2(x);}
    плав   лог2п(плав x){return log2f(x);}
    реал    лог2д(реал x){return log2l(x);}

    дво  логб(дво x){return logb(x);}
    плав   логбп(плав x){return logbf(x);}
    реал    логбд(реал x){return logbl(x);}

    дво  модф(дво значение, дво* цук){return modf(значение, цук);}
    плав   модфп(плав значение, плав* цук){return modff(значение, цук);}
    реал    модфд(реал значение, реал *цук){return modfl(значение, цук);}
/*
    дво  scalbn(дво x, цел n){return scalbn(x, n);}
    плав   scalbnf(плав x, цел n){return scalbnf(x, n);}
    реал    scalbnl(реал x, цел n){return scalbnl(x, n);}

    дво  scalbln(дво x, c_long n){return scalbln(x, n);}
    плав   scalblnf(плав x, c_long n){return scalblnf(x, n);}
    реал    scalblnl(реал x, c_long n){return scalblnl(x, n);}
*/
    дво  кубкор(дво x){return cbrt(x);}
    плав   кубкорп(плав x){return cbrtf(x);}
    реал    кубкорд(реал x){return cbrtl(x);}

    дво  фабс(дво x){return fabs(x);}
    плав   фабсп(плав x){return fabsf(x);}
    реал    фабсд(реал x){return fabsl(x);}

    дво  гипот(дво x, дво y){return hypot(x, y);}
    плав   гипотп(плав x, плав y){return hypotf(x, y);}
    реал    гипотд(реал x, реал y){return hypotl(x, y);}

    дво  степ(дво x, дво y){return pow(x, y);}
    плав   степп(плав x, плав y){return powf(x, y);}
    реал    степд(реал x, реал y){return powl(x, y);}

    дво  квкор(дво x){return sqrt(x);}
    плав   квкорп(плав x){return sqrtf(x);}
    реал    квкорд(реал x){return sqrtl(x);}

    дво  фцош(дво x){return erf(x);}
    плав   фцошп(плав x){return erff(x);}
    реал    фцошд(реал x){return erfl(x);}

    дво  фцошк(дво x){return erfc(x);}
    плав   фцошкп(плав x){return erfcf(x);}
    реал    фцошкд(реал x){return erfcl(x);}

    дво  лгамма(дво x){return lgamma(x);}
    плав   лгаммап(плав x){return lgammaf(x);}
    реал    лгаммад(реал x){return lgammal(x);}

    дво  тгамма(дво x){return tgamma(x);}
    плав   тгаммап(плав x){return tgammaf(x);}
    реал   тгаммад(реал x){return tgammal(x);}

    дво  вокругли(дво x){return ceil(x);}
    плав   вокруглип(плав x){return ceilf(x);}
    реал    вокруглид(реал x){return ceill(x);}

    дво  нокругли(дво x){return floor(x);}
    плав   нокруглип(плав x){return floorf(x);}
    реал    нокруглид(реал x){return floorl(x);}

    дво  ближцел(дво x){return nearbyint(x);}
    плав   ближцелп(плав x){return nearbyintf(x);}
    реал    ближцелд(реал x){return nearbyintl(x);}

    дво  ринт(дво x){return rint(x);}//
    плав   ринтп(плав x){return rintf(x);}//
    реал    ринтд(реал x){return rintl(x);}//
/*
    c_long  lrint(дво x){return lrint(x);}
    c_long  lrintf(плав x){return lrintf(x);}
    c_long  lrintl(реал x){return lrintl(x);}

    дол    llrint(дво x){return llrint(x);}
    дол    llrintf(плав x){return llrintf(x);}
    дол    llrintl(реал x){return llrintl(x);}
*/
    дво  округли(дво x){return round(x);}
    плав   округлип(плав x){return roundf(x);}
    реал    округлид(реал x){return roundl(x);}
/*
    c_long  lround(дво x){return lround(x);}
    c_long  lroundf(плав x){return lroundf(x);}
    c_long  lroundl(реал x){return lroundl(x);}

    дол    llround(дво x){return llround(x);}
    дол    llroundf(плав x){return llroundf(x);}
    дол    llroundl(реал x){return llroundl(x);}

    дво  trunc(дво x){return trunc(x);}
    плав   truncf(плав x){return truncf(x);}
    реал    truncl(реал x){return truncl(x);}

    дво  fmod(дво x, дво y){return fmod(x, y);}
    плав   fmodf(плав x, плав y){return fmodf(x, y);}
    реал    fmodl(реал x, реал y){return fmodl(x, y);}
*/
    дво  остаток(дво x, дво y){return remainder(x, y);}
    плав   остатокп(плав x, плав y){return remainderf(x, y);}
    реал    остатокд(реал x, реал y){return remainderl(x, y);}
/*
    дво  remquo(дво x, дво y, цел* quo){return remquo(x, y, quo);}
    плав   remquof(плав x, плав y, цел* quo){return remquof(x, y, quo);}
    реал    remquol(реал x, реал y, цел* quo){return remquol(x, y, quo);}
*/
    дво  копируйзнак(дво x, дво y){return copysign(x, y);}
    плав   копируйзнакп(плав x, плав y){return copysignf(x, y);}
    реал    копируйзнакд(реал x, реал y){return copysignl(x, y);}

    дво  нечисло(ткст tangp){return nan(вТкст0(tangp));}
    плав   нечислоп(ткст tangp){return nanf(вТкст0(tangp));}
    реал    нечислод(ткст tangp){return nanl(вТкст0(tangp));}

    дво  следза(дво x, дво y){return nextafter(x, y);}
    плав   следзап(плав x, плав y){return nextafterf(x, y);}
    //реал    следзад(реал x, реал y){return nextafterl(x, y);}

    //дво  следк(дво x, реал y){return nexttoward(x, y);}
    //плав   следкп(плав x, реал y){return nexttowardf(x, y);}
    //реал    следкд(реал x, реал y){return nexttowardl(x, y);}
/*
    дво  fdim(дво x, дво y){return fdim(x, y);}
    плав   fdimf(плав x, плав y){return fdimf(x, y);}
    реал    fdiml(реал x, реал y){return fdiml(x, y);}

    дво  fmax(дво x, дво y){return fmax(x, y);}
    плав   fmaxf(плав x, плав y){return fmaxf(x, y);}
    реал    fmaxl(реал x, реал y){return fmaxl(x, y);}

    дво  fmin(дво x, дво y){return fmin(x, y);}
    плав   fminf(плав x, плав y){return fminf(x, y);}
    реал    fminl(реал x, реал y){return fminl(x, y);}

    дво  fma(дво x, дво y, дво z){return fma(x, y, z);}
    плав   fmaf(плав x, плав y, плав z){return fmaf(x, y, z);}
    реал    fmal(реал x, реал y, реал z){return fmal(x, y, z);}*/
	

}

export extern (D)
  {
    проц перемотай(фук поток)   { fseek(cast(FILE*) поток,0L,SEEK_SET); поток.Флаг&=~_IOERR; }
    проц сбросьош(фук поток) { поток.Флаг &= ~(_IOERR|_IOEOF);                 }
    цел  конфл(фук поток)     { return поток.Флаг&_IOEOF;                       }
    цел  ошфл(фук поток)   { return поток.Флаг&_IOERR;                       }
  }
//////////////////
export extern  (C):

struct лпреобр
{
export:
    ткст десятичная_точка;
    ткст делит_тысяч;
    ткст группировка;
    ткст цел_валютн_символ;
    ткст символ_валюты;
    ткст мон_десятичная_точка;
    ткст мон_делит_тыс;
    ткст мон_группировка;
    ткст положит_знак;
    ткст отрицат_знак;
    байт  цел_дробн_цифры;
    байт  дробн_цифры;
    байт  p_cs_precedes;
    байт  p_sep_by_space;
    байт  n_cs_precedes;
    байт  n_sep_by_space;
    байт  p_sign_posn;
    байт  n_sign_posn;
    байт  цел_p_cs_precedes;
    байт  цел_p_sep_by_space;
    байт  цел_n_cs_precedes;
    байт  цел_n_sep_by_space;
    байт  цел_p_sign_posn;
    байт  цел_n_sign_posn;
}

struct т_цмаксдел
	{
	export:
		дол    квот,
					рем;
	}

struct т_фсред
    {
	export:
        бкрат    статус;
        бкрат    контроль;
        бкрат    округл;
        бкрат[2] резерв;
    }
	
struct т_дели
	{
	export:
		цел квот,
			рем;
	}


struct т_делиц
	{
	export:
		цел квот,
			рем;
	}

struct т_делид
	{
	export:
		дол квот,
			 рем;
	}
	
	
цел удали(in ткст фимя){return remove(вТкст0(фимя));}
цел переименуй(in ткст из, in ткст в){return rename(вТкст0(из), вТкст0(в));}

фук времфл(){return cast(FILE*) tmpfile();}
ткст времим(ткст s){return вТкст(tmpnam(вТкст0(s)));}

цел   закройфл(фук поток){return fclose(cast(FILE*)поток);}
цел   слейфл(фук поток){return fflush(cast(FILE*)поток);}
фук откройфл(in ткст фимя, in ткст режим){return cast(FILE*) fopen(вТкст0(фимя), вТкст0(режим));}
фук переоткройфл(in ткст фимя, in ткст режим, фук поток){return cast(FILE*) freopen(вТкст0(фимя), вТкст0(режим),  cast(FILE*) поток);}

проц устбуффл(фук поток, ткст буф){return setbuf(cast(FILE*)поток, вТкст0(буф));}
цел  уствбуф(фук поток, ткст буф, цел режим, т_мера размер){return setvbuf(cast(FILE*)поток, вТкст0(буф), режим, размер);}

цел вфвыводф(фук поток, in ткст формат, спис_ва арг){return vfprintf(cast(FILE*)поток, вТкст0(формат), арг);}
цел вфсканф(фук поток, in ткст формат, спис_ва арг){return vfscanf(cast(FILE*)поток, вТкст0(формат), арг);}
цел всвыводф(ткст s, in ткст формат, спис_ва арг){return vsprintf(вТкст0(s), вТкст0(формат), арг);}
цел вссканф(in ткст s, in ткст формат, спис_ва арг){return vsscanf(вТкст0(s), вТкст0(формат), арг);}
цел ввыводф(in ткст формат, спис_ва арг){return vprintf(вТкст0(формат), арг);}
цел всканф(in ткст формат, спис_ва арг){return vscanf(вТкст0(формат), арг);}
цел берисфл(фук поток){return fgetc(cast(FILE*)поток);}
цел вставьсфл(цел c, фук поток){return fputc(c, cast(FILE*)поток);}

ткст дайтфл(ткст s, цел n, фук поток){return вТкст(fgets(вТкст0(s), n, cast(FILE*)поток));}
цел   вставьтфл(in ткст s, фук поток){return fputs(вТкст0(s), cast(FILE*)поток);}
ткст дайт(ткст s){return вТкст(gets(вТкст0(s)));}
цел   вставьт(in ткст s){return puts(вТкст0(s));}

цел отдайс(цел c, фук поток){return ungetc(c, cast(FILE*)поток);}

т_мера читайфл(ук указат, т_мера размер, т_мера nmemb, фук поток){return fread(адаптВхоУкз(указат), размер, nmemb, cast(FILE*)поток);}
т_мера пишифл(in ук указат, т_мера размер, т_мера nmemb, фук поток){return fwrite(адаптВхоУкз(указат), размер, nmemb, cast(FILE*)поток);}

цел дайпозфл(фук поток, цел* поз){return fgetpos(cast(FILE*)поток, cast(fpos_t*) поз);}
цел устпозфл(фук поток, in цел* поз){return fsetpos(cast(FILE*)поток, cast(fpos_t*) поз);}

цел    сместисьфл(фук поток, цел смещение, цел куда){return fseek(cast(FILE*)поток, cast(c_long) смещение, куда);}
цел скажифл(фук поток){return cast(цел) ftell(cast(FILE*)поток);}

цел   вснвыводф(ткст s, т_мера n, in ткст формат, спис_ва арг){return _vsnprintf(вТкст0(s), n, вТкст0(формат), арг);}

проц укошиб(in ткст s){return perror(вТкст0(s));}

//////////////////////////////////////////

т_сигфн сигнал(цел сиг, т_сигфн функ){return cast(т_сигфн) signal(сиг, cast(sigfn_t) функ);}
цел     влеки(цел сиг){return raise(сиг);}

кдво какос(кдво z){return cacos(z);}
кплав  какосп(кплав z){return cacosf(z);}
креал   какосд(креал z){return cacosl(z);}

кдво касин(кдво z){return casin(z);}
кплав  касинп(кплав z){return casinf(z);}
креал   касинд(креал z){return casinl(z);}

кдво катан(кдво z){return catan(z);}
кплав  катанп(кплав z){return catanf(z);}
креал   катанд(креал z){return catanl(z);}

кдво ккос(кдво z){return ccos(z);}
кплав  ккосп(кплав z){return ccosf(z);}
креал   ккосд(креал z){return ccosl(z);}

кдво ксин(кдво z){return csin(z);}
кплав  ксинп(кплав z){return csinf(z);}
креал   ксинд(креал z){return csinl(z);}

кдво ктан(кдво z){return ctan(z);}
кплав  ктанп(кплав z){return ctanf(z);}
креал   ктанд(креал z){return ctanl(z);}

кдво какосг(кдво z){return cacosh(z);}
кплав  какосгп(кплав z){return cacoshf(z);}
креал   какосгд(креал z){return cacoshl(z);}

кдво касинг(кдво z){return casinh(z);}
кплав  касингп(кплав z){return casinhf(z);}
креал   касингд(креал z){return casinhl(z);}

кдво катанг(кдво z){return catanh(z);}
кплав  катангп(кплав z){return catanhf(z);}
креал   катангд(креал z){return catanhl(z);}

кдво ккосг(кдво z){return ccosh(z);}
кплав  ккосгп(кплав z){return ccoshf(z);}
креал   ккосгд(креал z){return ccoshl(z);}

кдво ксинг(кдво z){return csinh(z);}
кплав  ксингп(кплав z){return csinhf(z);}
креал   ксингд(креал z){return csinhl(z);}

кдво ктанг(кдво z){return ctanh(z);}
кплав  ктангп(кплав z){return ctanhf(z);}
креал   ктангд(креал z){return ctanhl(z);}

кдво кэксп(кдво z){return cexp(z);}
кплав  кэкспп(кплав z){return cexpf(z);}
креал   кэкспд(креал z){return cexpl(z);}

кдво клог(кдво z){return clog(z);}
кплав  клогп(кплав z){return clogf(z);}
креал   клогд(креал z){return clogl(z);}

дво кабс(кдво z){return cabs(z);}
плав  кабсп(кплав z){return cabsf(z);}
реал  кабсд(креал z){return cabsl(z);}

кдво кстеп(кдво x, кдво y){return cpow(x, y);}
кплав  кстепп(кплав x, кплав y){return cpowf(x, y);}
креал   кстепд(креал x, креал y){return cpowl(x, y);}

кдво кквкор(кдво z){return csqrt(z);}
кплав  кквкорп(кплав z){return csqrtf(z);}
креал   кквкорд(креал z){return csqrtl(z);}

 дво карг(кдво z){return carg(z);}
 плав  каргп(кплав z){return cargf(z);}
 реал  каргд(креал z){return cargl(z);}

// дво квообр(кдво z){return cimag(z);}
 //плав  квообрп(кплав z){return cimagf(z);}
 //реал  квообрд(креал z){return cimagl(z);}

//кдво конъюнк(кдво z){return conj(z);}
//кплав  конъюнкп(кплав z){return conjf(z);}
//креал   конъюнкд(креал z){return conjl(z);}

кдво кпроекц(кдво z){return cproj(z);}
кплав  кпроекцп(кплав z){return cprojf(z);}
креал   кпроекцд(креал z){return cprojl(z);}

 //дво креал(кдво z){return creal(z);}
 //плав  креалп(кплав z){return crealf(z);}
 //реал  креалд(креал z){return creall(z);}
 
 
цел числобукв_ли(цел c){return isalnum(c);}
цел буква_ли(цел c){return isalpha(c);}
цел пробел_ли(цел c){return isblank(c);}
цел управ_ли(цел c){return iscntrl(c);}
цел цифра_ли(цел c){return isdigit(c);}
цел граф_ли(цел c){return isgraph(c);}
цел проп_ли(цел c){return islower(c);}
цел печат_ли(цел c){return isprint(c);}
цел пункт_ли(цел c){return ispunct(c);}
цел межбукв_ли(цел c){return isspace(c);}
цел заг_ли(цел c){return isupper(c);}
цел цифраикс_ли(цел c){return isxdigit(c);}
цел впроп(цел c){return tolower(c);}
цел взаг(цел c){return toupper(c);}

цел числобуквш_ли(шим c){return iswalnum(cast(wchar_t) c);}
цел букваш_ли(шим c){return iswalpha(cast(wchar_t) c);}
//цел пробелш_ли(шим c){return iswblank(cast(wchar_t) c);}
цел управш_ли(шим c){return iswcntrl(cast(wchar_t) c);}
цел цифраш_ли(шим c){return iswdigit(cast(wchar_t) c);}
цел графш_ли(шим c){return iswgraph(cast(wchar_t) c);}
цел пропш_ли(шим c){return iswlower(cast(wchar_t) c);}
цел печатш_ли(шим c){return iswprint(cast(wchar_t) c);}
цел пунктш_ли(шим c){return iswpunct(cast(wchar_t) c);}
цел межбуквш_ли(шим c){return iswspace(cast(wchar_t) c);}
цел загш_ли(шим c){return iswupper(cast(wchar_t) c);}
цел цифраиксш_ли(шим c){return iswxdigit(cast(wchar_t) c);}
цел впропш(шим c){return towlower(cast(wchar_t) c);}
цел взагш(шим c){return towupper(cast(wchar_t) c);}
//шим    втрансш(шим ш, шим опис){return cast(шим) towctrans(cast(wchar_t) ш, cast(wctrans_t) опис);}
//шим трансш( in ткст0 свойство){return cast(шим) wctrans(свойство);}


цел дайНомош(){return getErrno();}      
цел устНомош(цел n){return setErrno(n);}   

проц влекиисклфе(цел исклы){feraiseexcept(исклы);}
проц сотриисклфе(цел исклы){feclearexcept(исклы);}

цел тестисклфе(цел исклы){return fetestexcept(исклы);}
цел задержиисклфе(т_фсред* средп){return feholdexcept(cast(fenv_t*) средп);}

проц дайфлагисклфе(цел* флагп, цел исклы){return fegetexceptflag(cast(fexcept_t*) флагп, исклы);}
проц устфлагисклфе(in цел* флагп, цел исклы){return fesetexceptflag(cast(fexcept_t*)флагп, исклы);}

цел дайкругфе(){return fegetround();}
цел усткругфе(цел круг){return fesetround(круг);}

проц дайсредфе(т_фсред* средп){fegetenv(cast(fenv_t*)средп);}
проц устсредфе(in т_фсред* средп){fesetenv(cast(fenv_t*) средп);}
проц обновисредфе(in т_фсред* средп){feupdateenv(cast(fenv_t*) средп);}

дол  цмаксабс(дол j){ return cast(дол) imaxabs(cast(intmax_t)j);}
т_цмаксдел цмаксдел(дол число, дол делитель){return cast(т_цмаксдел) imaxdiv(число, делитель);}
дол  ткствмаксц(in ткст чук, ткст* конук, цел основа){return cast(дол) strtoimax(вТкст0(чук), cast(сим**) конук, основа);}
бдол ткствбмакс(in ткст чук, ткст* конук, цел основа){return cast(бдол) strtoumax(вТкст0(чук), cast(сим**)конук, основа);}
дол  шимвцмакс(in шткст чук, шткст* конук, int основа){return cast(дол) wcstoimax(cast(wchar_t*) чук, cast(wchar_t**) конук, основа);}
бдол шимвбмакс(in шткст чук, шткст* конук, int основа){return cast(бдол) wcstoumax(cast(wchar_t*) чук, cast(wchar_t**) конук, основа);}

ткст  устлокаль(int категория, in ткст локаль)	{return вТкст(setlocale(категория, вТкст0(локаль)));}	
лпреобр* преобрлокаль(){return cast(лпреобр*) localeconv();}

    бцел __птклассифицируй_п(плав x){return __fpclassify_f(x);}
    бцел __птклассифицируй_д(дво x){return __fpclassify_d(x);}
    бцел __птклассифицируй_дд(реал x){return __fpclassify_ld(x);}


//проц exit(цел);
проц _си_выход(){_c_exit();}
проц _сивыход(){_cexit();}
проц _выход(цел x){_exit(x);}
проц _аборт(){abort();}
проц _деструкт(){_dodtors();}
цел дайпид(){return getpid();}
/*
//цел system(сим *){rt.core.stdc.process

enum { П_ЖДИ = _P_WAIT, П_НЕЖДИ = _P_NOWAIT, П_ПОВЕРХ = _P_OVERLAY }

цел execl(сим *, сим *,...){rt.core.stdc.process
цел execle(сим *, сим *,...){rt.core.stdc.process
цел execlp(сим *, сим *,...){rt.core.stdc.process
цел execlpe(сим *, сим *,...){rt.core.stdc.process
цел execv(сим *, сим **){rt.core.stdc.process
цел execve(сим *, сим **, сим **){rt.core.stdc.process
цел execvp(сим *, сим **){rt.core.stdc.process
цел execvpe(сим *, сим **, сим **){rt.core.stdc.process


enum { WAIT_CHILD, WAIT_GRANDCHILD }

цел cwait(цел *,цел,цел){rt.core.stdc.process
цел жди(цел *){rt.core.stdc.process

version (Windows)
{
    бцел начни_нить(проц function(ук ),бцел,ук ){rt.core.stdc.process

    extern  (Windows) alias бцел (*stdfp)(ук ){rt.core.stdc.process

    бцел начни_нить_доп(ук security, бцел stack_size,
	    stdfp start_addr, ук arglist, бцел initflag,
	    бцел* thrdaddr){rt.core.stdc.process

    проц стоп_нить(){rt.core.stdc.process
    проц стоп_нить_доп(бцел){rt.core.stdc.process

    цел spawnl(цел, сим *, сим *,...){rt.core.stdc.process
    цел spawnle(цел, сим *, сим *,...){rt.core.stdc.process
    цел spawnlp(цел, сим *, сим *,...){rt.core.stdc.process
    цел spawnlpe(цел, сим *, сим *,...){rt.core.stdc.process
    цел spawnv(цел, сим *, сим **){rt.core.stdc.process
    цел spawnve(цел, сим *, сим **, сим **){rt.core.stdc.process
    цел spawnvp(цел, сим *, сим **){rt.core.stdc.process
    цел spawnvpe(цел, сим *, сим **, сим **){rt.core.stdc.process


    цел _wsystem(wchar_t *){rt.core.stdc.process
    цел _wspawnl(цел, wchar_t *, wchar_t *, ...){rt.core.stdc.process
    цел _wspawnle(цел, wchar_t *, wchar_t *, ...){rt.core.stdc.process
    цел _wspawnlp(цел, wchar_t *, wchar_t *, ...){rt.core.stdc.process
    цел _wspawnlpe(цел, wchar_t *, wchar_t *, ...){rt.core.stdc.process
    цел _wspawnv(цел, wchar_t *, wchar_t **){rt.core.stdc.process
    цел _wspawnve(цел, wchar_t *, wchar_t **, wchar_t **){rt.core.stdc.process
    цел _wspawnvp(цел, wchar_t *, wchar_t **){rt.core.stdc.process
    цел _wspawnvpe(цел, wchar_t *, wchar_t **, wchar_t **){rt.core.stdc.process

    цел _wexecl(wchar_t *, wchar_t *, ...){rt.core.stdc.process
    цел _wexecle(wchar_t *, wchar_t *, ...){rt.core.stdc.process
    цел _wexeclp(wchar_t *, wchar_t *, ...){rt.core.stdc.process
    цел _wexeclpe(wchar_t *, wchar_t *, ...){rt.core.stdc.process
    цел _wexecv(wchar_t *, wchar_t **){rt.core.stdc.process
    цел _wexecve(wchar_t *, wchar_t **, wchar_t **){rt.core.stdc.process
    цел _wexecvp(wchar_t *, wchar_t **){rt.core.stdc.process
    цел _wexecvpe(wchar_t *, wchar_t **, wchar_t **){rt.core.stdc.process
}
*/


//stdlib


дво  алфнапз(in ткст укнач){return atof(вТкст0(укнач));}
цел     алфнац(in ткст укнач){return atoi(вТкст0(укнач));}
цел алфнадл(in ткст укнач){return cast(цел) atol(вТкст0(укнач));}
дол    алфнадлдл(in ткст укнач){return atoll(вТкст0(укнач));}

дво  стрнад(in ткст укнач, ткст* укнакон){return strtod(вТкст0(укнач), cast(сим**) укнакон);}
плав   стрнапз(in ткст укнач, ткст* укнакон){return strtof(вТкст0(укнач), cast(сим**) укнакон);}
реал    стрнадлд(in ткст укнач, ткст* укнакон){return strtold(вТкст0(укнач), cast(сим**) укнакон);}
цел  стрнадл(in ткст укнач, ткст* укнакон, цел ова){return cast(цел) strtol(вТкст0(укнач), cast(сим**) укнакон, ова);}
дол    стрнадлдл(in ткст укнач, ткст* укнакон, цел ова){return strtoll(вТкст0(укнач), cast(сим**)  укнакон, ова);}
бцел стрнабдл(in ткст укнач, ткст* укнакон, цел ова){return cast(бцел) strtoul(вТкст0(укнач), cast(сим**) укнакон, ова);}
бдол   стрнабдлдл(in ткст укнач, ткст* укнакон, цел ова){return strtoull(вТкст0(укнач), cast(сим**) укнакон, ова);}


цел     случ(){return rand();}
проц    сслуч(бцел семя){srand(семя);}


ук   празмести(т_мера разм){return адаптВыхУкз(malloc(разм));}
ук   кразмести(т_мера члочленов, т_мера разм){return адаптВыхУкз(calloc(члочленов, разм));}
ук   перемести(ук указ, т_мера разм){return адаптВыхУкз(realloc(указ, разм));}
проц    освободи(ук указ){ free(адаптВхоУкз(указ));}


проц    аборт(){abort();}
проц    выход(цел статус){ exit(статус);}
цел     навыходе(проц function() функц){return atexit(функц);}
проц    _Выход(цел статус){_Exit(статус);}


ткст   дайсреду(in ткст имя){return вТкст(getenv(вТкст0(имя)));}
цел     система(in ткст текст){return system(вТкст0(текст));}


ук   бпоиск(in ук key, in ук ова, т_мера члочленов, т_мера разм, цел function(in проц*, in проц*) compar){return адаптВыхУкз(bsearch(адаптВхоУкз(key), ова, члочленов, разм, compar));}
проц    бсорт(ук ова, т_мера члочленов, т_мера разм, цел function(in проц*, in проц*) compar){ qsort(адаптВхоУкз(ова), члочленов, разм, compar);}


цел     абс(цел j){return abs(j);}
цел  абсц(цел j){return cast(цел) labs(cast(c_long) j);}
дол    абсд(дол j){return llabs(j);}


т_дели   дели(цел число, цел делитель){return cast(т_дели) div(число, делитель);}
т_делиц  делиц(цел число, цел делитель){return cast(т_делиц) ldiv(cast(c_long) число, cast(c_long) делитель);}
т_делид делид(дол число, дол делитель){return cast(т_делид) lldiv(число, делитель);}



цел     мбдлин(in ткст s, т_мера n){return mblen(вТкст0(s), n);}
цел     мбнашк(шткст pwc, in ткст s, т_мера n){return mbtowc(cast(wchar_t*) pwc, вТкст0(s), n);}
цел     шкнамб(ткст s, шим wc){return wctomb(вТкст0(s), cast(wchar_t)wc);}
т_мера  мбтнашкт(шткст pwcs, in ткст s, т_мера n){return mbstowcs(cast(wchar_t*)pwcs, вТкст0(s), n);}
т_мера  шктнамбт(ткст s, in шткст pwcs, т_мера n){return wcstombs(вТкст0(s), cast(wchar_t*)pwcs, n);}



version( DigitalMars )
{
    ук разместа(т_мера разм){return адаптВыхУкз(alloca(разм));} // non-standard
}

цел ширфл(фук поток, цел реж){return fwide( cast(FILE*)поток, реж);}  
	
	цел поместсфл(цел ц, фук ф){return _fputc_nlock(ц,  cast(FILE*)ф);}
    цел поместшфл(цел ц, фук ф){return  _fputwc_nlock(ц,  cast(FILE*)ф);}
    цел извлсфл(фук ф){return _fgetc_nlock( cast(FILE*)ф);}
    цел извлшфл(фук ф){return _fgetwc_nlock( cast(FILE*)ф);}
    цел блокфл(фук ф){return  __fp_lock( cast(FILE*)ф);}
    проц разблокфл(фук ф){__fp_unlock( cast(FILE*)ф);}

/*
alias цел     mbstate_t;
//alias wchar_t wцел_t;

//const wchar_t WEOF = 0xFFFF;

цел fwprintf(фук поток, in wchar_t* format, ...);
цел fwscanf(фук поток, in wchar_t* format, ...);
цел swprintf(wchar_t* s, т_мера n, in wchar_t* format, ...);
цел swscanf(in wchar_t* s, in wchar_t* format, ...);
цел vfwprintf(фук поток, in wchar_t* format, va_list арг);
цел vfwscanf(фук поток, in wchar_t* format, va_list арг);
цел vswprintf(wchar_t* s, т_мера n, in wchar_t* format, va_list арг);
цел vswscanf(in wchar_t* s, in wchar_t* format, va_list арг);
цел vwprintf(in wchar_t* format, va_list арг);
цел vwscanf(in wchar_t* format, va_list арг);
цел wprintf(in wchar_t* format, ...);
цел wscanf(in wchar_t* format, ...);

wint_t fgetwc(фук поток);
wint_t fputwc(wchar_t c, фук поток);

wchar_t* fgetws(wchar_t* s, цел n, фук поток);
цел      fputws(in wchar_t* s, фук поток);

extern  (D)
{
    wint_t getwchar()                     { return fgetwc(stdin);     }
    wint_t putwchar(wchar_t c)            { return fputwc(c,stdout);  }
    wint_t getwc(фук поток)            { return fgetwc(поток);    }
    wint_t putwc(wchar_t c, фук поток) { return fputwc(c, поток); }
}

wint_t ungetwc(wint_t c, фук поток);
цел    fwide(фук поток, цел mode);

double  wcstod(in wchar_t* nptr, wchar_t** endptr);
float   wcstof(in wchar_t* nptr, wchar_t** endptr);
real    wcstold(in wchar_t* nptr, wchar_t** endptr);
c_long  wcstol(in wchar_t* nptr, wchar_t** endptr, цел base);
дол    wcstoll(in wchar_t* nptr, wchar_t** endptr, цел base);
c_ulong wcstoul(in wchar_t* nptr, wchar_t** endptr, цел base);
ulong   wcstoull(in wchar_t* nptr, wchar_t** endptr, цел base);

wchar_t* wcscpy(wchar_t* s1, in wchar_t* s2);
wchar_t* wcsncpy(wchar_t* s1, in wchar_t* s2, т_мера n);
wchar_t* wcscat(wchar_t* s1, in wchar_t* s2);
wchar_t* wcsncat(wchar_t* s1, in wchar_t* s2, т_мера n);
цел      wcscmp(in wchar_t* s1, in wchar_t* s2);
цел      wcscoll(in wchar_t* s1, in wchar_t* s2);
цел      wcsncmp(in wchar_t* s1, in wchar_t* s2, т_мера n);
т_мера   wcsxfrm(wchar_t* s1, in wchar_t* s2, т_мера n);
wchar_t* wcschr(in wchar_t* s, wchar_t c);
т_мера   wcscspn(in wchar_t* s1, in wchar_t* s2);
wchar_t* wcspbrk(in wchar_t* s1, in wchar_t* s2);
wchar_t* wcsrchr(in wchar_t* s, wchar_t c);
т_мера   wcsspn(in wchar_t* s1, in wchar_t* s2);
wchar_t* wcsstr(in wchar_t* s1, in wchar_t* s2);
wchar_t* wcstok(wchar_t* s1, in wchar_t* s2, wchar_t** ptr);
т_мера   wcslen(in wchar_t* s);

wchar_t* wmemchr(in wchar_t* s, wchar_t c, т_мера n);
цел      wmemcmp(in wchar_t* s1, in wchar_t* s2, т_мера n);
wchar_t* wmemcpy(wchar_t* s1, in wchar_t* s2, т_мера n);
wchar_t* wmemmove(wchar_t*s1, in wchar_t* s2, т_мера n);
wchar_t* wmemset(wchar_t* s, wchar_t c, т_мера n);

т_мера wcsftime(wchar_t* s, т_мера maxsize, in wchar_t* format, in tm* timeptr);

version( Windows )
{
    wchar_t* _wasctime(tm*);      // non-standard
    wchar_t* _wctime(time_t*);	  // non-standard
    wchar_t* _wstrdate(wchar_t*); // non-standard
    wchar_t* _wstrtime(wchar_t*); // non-standard
}

wцел_t btowc(цел c);
цел    wctob(wint_t c);
цел    mbsinit(in mbstate_t* ps);
т_мера mbrlen(in сим* s, т_мера n, mbstate_t* ps);
т_мера mbrtowc(wchar_t* pwc, in сим* s, т_мера n, mbstate_t* ps);
т_мера wcrtomb(сим* s, wchar_t wc, mbstate_t* ps);
т_мера mbsrtowcs(wchar_t* dst, in сим** src, т_мера len, mbstate_t* ps);
т_мера wcsrtombs(сим* dst, in wchar_t** src, т_мера len, mbstate_t* ps);
*/

version (Windows)
{
    	///////////////////////////
	/*
	* memicmp /сравнибуфлюб/: Сравнивает символы из двух буферов (без учета региста).
	*/
	цел сравбуфлюб(ткст0 буф1, ткст0 буф2, т_мера члоб)
	{
	return cast(цел) memicmp(буф1, буф2, члоб);
	}
	
	alias сравбуфлюб сравни_буферы_люб ;
}

/////////////////////////////////////////////////////
/*
* memchr /ищисим/ ищет первый случай сим в 
* строке, состоящей из члабайт буфера. Она
* останавливается, когда найдёт сим, либо
* проверив первое члобайт.
*/
ук ищисим(in ук строка, цел симв, т_мера члобайт)
	{
	//return memchr(строка, симв, члобайт);

    ббайт *cs_ = cast(ббайт*) адаптВхоУкз(строка);
    ббайт c_ = cast(ббайт) симв;
    т_мера i;

    for (i = 0; i < члобайт; ++i)
    {
	if (cs_[i] == c_) return адаптВыхУкз(cast(ук) (cs_ + i));
    }

    return null;


	}
	
alias ищисим ищи_символ;

///////////////////////////////////////////////////////////
/*
* memcmp /сравбуф/: Сравнение символов двух буферов.
* Если возврат < 0, то буф1 меньше буф2; возврат = 0, буферы идентичны;
* возврат > 0, буф1 больше буф2.
*/
цел сравбуф(in ук буф1, in ук буф2, т_мера члобайт)
	{
	return cast(цел)   memcmp(адаптВхоУкз(буф1), адаптВхоУкз(буф2), члобайт);
	/+
	int memcmp(const void *cs, const void *ct, size_t n)
	
	const сим *cs_ = cs;
    const сим *ct_ = ct;
    size_t i;

    for (i = 0; i < n; ++i)
    {
	if (cs_[i] != ct_[i]) return cs_[i] - ct_[i];
    }

    return 0;
	+/
	}
	
alias  сравбуф сравни_буферы;

///////////////////////////////////////////////////////////
version(WinCRT_s)
{
	extern(C)
	{
	int memcpy_s(   void *dest,   size_t numberOfElements,   void *src,   size_t count );
	int wmemcpy_s(   wchar_t *dest,   size_t numberOfElements,   wchar_t *src,   size_t count);
	}
}
/*
* memcpy /копирбуф/ копирует члобайт из истока в приёмник;
* если исток и приёмник накладываются, то поведение
* memcpy неопределено. Для обработки накладывающихся
* регионов лучше использовать memmove /перембуф/.
*/
ук копирбуф(ук приёмник, in ук источник, т_мера члобайт)
{	
	//version(useSNN)
	return адаптВыхУкз(cast(ук) memcpy(адаптВхоУкз(приёмник), адаптВхоУкз(источник), cast(size_t) члобайт));
	/+  version(WinCRT_s)  memcpy_s(   п,   п.sizeof,   и,   члобайт );
	
	version(вариант2)
	{
	т_мера i;
	сим *п = cast(сим*) приёмник;
    сим *и = cast(сим*) источник;
	
		for (i = 0; i < члобайт; ++i)
		{ 
		п[i] = и[i];
		}
	}
	
	try
	{	
		сим *п = cast(сим*) приёмник;
		сим *и = cast(сим*) источник;
		т_мера чб = члобайт;
		
		if(приёмник <= источник)
		{
			 while (чб--)
				п[чб] = и[чб];
		}
		else 
		{
		перемести_буфер(приёмник, источник, члобайт);
		}
	}
		catch(Объект ош){эхо("Error in cidrus.memcpy (ln 2042)\n");}	

    
   return приёмник;+/
}
	
alias  копирбуф копируй_буфер;

/////////////////////////////////////////////////////////////
/*
* memmove /перембуф/ копирует байты из откуда в куда.
* Если некоторые области исходной зоны и приёмной нахлёстываются,
* то гарантируется копирование исходных байтов из области
* накладки до того, как будет произведена перезапись.
*/
ук перембуф(ук куда, in ук откуда, т_мера сколько)
	{
	return адаптВыхУкз(cast(ук) memmove(адаптВхоУкз(куда), адаптВхоУкз(откуда), cast(size_t) сколько));
	/+try
	{
		ббайт *s_ = cast(ббайт*) куда;
		ббайт *ct_ = cast(ббайт*) откуда;

		if (куда <= откуда)
		{
		return копирбуф(куда, откуда, сколько);
		} else {
		for ( ; сколько; --сколько) s_[сколько - 1] = ct_[сколько - 1];
		}
	}
	catch(Объект ош){эхо("Error in cidrus.memmove (ln 2090)\n");}

    return куда;+/
	
	}
	
alias перембуф перемести_буфер;

///////////////////////////////////////////////////
/*
* memset /устанбуф/ устанавливает первое чло символов приёмника
* где на символ сим.
*/
ук устбуф(ук куда, цел что, т_мера члосим)
	{
	return адаптВыхУкз(memset(адаптВхоУкз(куда), что, члосим));
	
	/+ббайт *s_ = cast(ббайт*) куда;
    ббайт c_ = cast(ббайт) что;
    т_мера i;

    for (i = 0; i < члосим; ++i) s_[i] = c_;

    return куда;+/
	}
	
alias  устбуф установи_буфер ;

/////////////////////////////////////////////
/*
* Функция strcpy /копиртекс/ копирует символы откуда,
* включая оканчивающий нуль, в место,
* указанное параметром куда. Поведение strcpy
* неопределено при накладке между источником и приёмником.
*/
ткст0 копиртекс(ткст0 куда, in ткст0 откуда)
	{
	
	return strcpy(куда, откуда);
	
	/+сим *p = cast(сим*) куда;
    while (*откуда) *p++ = *откуда++;
    *p = 0;
    return куда;+/
	}
	
alias копиртекс копируй_символы;

/////////////////////////////////////////////////
/*
* Функция strncpy /копирчтекс/ копирует начальное число символов
* из  откуда в куда, и возвращает куда. Если члосим меньше или
* равно длине откуда, то к копированной строке нулевой символ
* автоматически не добавляется. Если же члосим больше длины
* откуда, то принимающая строка заполняется на всю остаточную
* длину нулями. При накладке источника и приёмника поведение
* strncpy неопределено.
*/
ткст0 копирчтекс(ткст0 куда, in ткст0 откуда, т_мера члосим)
	{
	return strncpy( куда, откуда, члосим );
	}
	
alias  копирчтекс копируй_чло_сим;

/////////////////////////////////////////////
/*
* Функция strcat /сотекс/ добавляет текст_плюс к ткст1,
* и завершает полученную строку нулевым символом.
* Начальный сивол текст_плюс переписывает конечный
* нулевой символ текст1. При накладке источника и
* приёмника поведение неопределено.
*/
ткст0 сотекс(ткст0 текст1, in ткст0 текст_плюс)
	{
	return strcat(текст1, текст_плюс);
	}
	
alias сотекс соедини_тексты;

////////////////////////////////////////////////////
/*
* Функция strncat /сочтекс/ добавляет не более первого
* чласим ткст2 к ткст1. Начальный символ ткст2 переписывает
* конечный нулевой ткст1. Если до окончания добавления
* в стр2 попадается нулевой символ, то strncat добавляет
* все символы из ткст2, вплоть до нулевого. Если члосим
* больше длины ткст2, то эта длина ткст2 используется
* вместо члосим. Во всех случаях  получаемая строка
* оканчивается на нулевой символ. Если происходит копирование
* между налагающимися строками, то поведение её остаётся не выясненным.
*/
ткст0 сочтекс(ткст0 ткст1, in ткст0 ткст2, т_мера члосим)
	{
	return strncat(ткст1, ткст2, члосим);
	}
	
alias  сочтекс соедини_чло_сим;

////////////////////////////////////////////
/*
* Сравнение символов двух строк. Функция strncmp /сравнитекс/ сравнивает
* лексикографически текст1 и текст2 и возвращает значение, показывающее их
* взаимоотношение.
* Если возврат < 0, то текст1 меньше текст2; возврат = 0, тексты идентичны;
* возврат > 0, текст1 больше текст2.
*/
цел сравтекс(in ткст0 текст1, in ткст0 текст2)
	{
	return cast(цел)    strcmp(текст1, текст2);
	}
	
alias сравтекс сравни_тексты ;

/////////////////////////////////////////////
/*
.........................
*/
цел кодстрсравнитекс( in ткст0 текст1, in ткст0 текст2)
	{
	return cast(цел)    strcoll(текст1, текст2);
	}
	
alias кодстрсравнитекс кссравтекс;
///////////////////////////////////////////////
/*
* Сравнение символов двух строк с использованием текущей локали
* или заданной локали. Функция strncmp /сравничтекс/ сравнивает 
* лексикографически не более чем первые члосим в текст1 и текст2,
* и возвращает значение, показывающее взаимоотнощение между подстроками.
* strncmp - это регистрочувствительная версия _strnicmp.
*/
цел сравчтекс(in ткст0 текст1, in ткст0 текст2, т_мера члосим)
	{
	return cast(цел) strncmp(текст1, текст2, члосим);
	}

alias сравчтекс сравни_чло_сим ;

/////////////////////////////////////////////////
/*
* Функция strxfrm /форматчтекс/ преобразует строку, указанную как
* из, в новую форму, сохраняемую в в. Преобразуется не более
* чла символов, включая и нулевой, который помещаются в
* результат. Трансформация происходит с применением
* установки категории LC_COLLATE локали.
*/
т_мера форматчтекс(ткст0 в, in ткст0 из, т_мера чло)
	{
	return cast(т_мера) strxfrm(в, из, чло);
	}

alias форматчтекс преобразуй_чло_сим_лок ;

//////////////////////////////////////////
/*
* Функция strchr /найдипер/ находит первый случай с в строке т,
* либо возвращает NULL, если с не найден. В поиск включается и
* завершающий символ нуля.
*/
ткст  найдипер(in ткст0 т, цел с)
	{
	return вТкст(strchr( т, с));
	}
	
alias найдипер найди_перв_сим ;

/////////////////////////////////////////
/*
* strcspn /персиндекс/: Возвращает индекс первого случая символа
* что в строке где, который принадлежит к указанному в что
* набору символов.
*/
т_мера персинд (in ткст0 где, in ткст0 что)
	{
	return cast(т_мера) strcspn ( где, что);
	}

alias персинд дай_индекс_перв_сим ;

///////////////////////////////////////
/*
* Функция strpbrk /найдитексвнаб/ возвращает указатель на первый
* символ в строке вчём, принадлежащий набору символов
* из ряда изчего. Поиск не включает оканчивающего
* нулевого символа.
*/
ткст0  найдитексвнаб(in ткст0 вчём, in ткст0 изчего)
	{
	return  strpbrk( вчём, изчего );
	}
	
alias  найдитексвнаб найди_сим_из_набора ;

/////////////////////////////////////
/*
* Функция strrchr /найдипос/ находит последний случай символа сим 
* (преобразованного в сим) в строке ткс. В поиск входит 
* оканчивающий нулевой символ.
*/
ткст0  найдипос(in  ткст0 ткс, цел сим)
	{
	return  strrchr ( ткс, сим );
	}
	
alias найдипос найди_посл_сим ;

/////////////////////////////////////
/*
* Функция strspn /найдитекснеизнаб/ возвращает индекс
* первого символа в строке вчём,не принадлежащего набору
* символов изчего. В поиск не входят
* оканчивающие нулевые символы.
*/

т_мера найдитекснеизнаб(in ткст0 вчём, in ткст0 изчего)
	{
	return cast(т_мера) strspn(вчём, изчего);
	}
	
alias найдитекснеизнаб найди_сим_не_из_набора ;

/////////////////////////////////////////
/*
* Функция strstr /найдиподтекст/ возвращает указатель на первый случай
* искомой строки в строке стр. В поиске не участвуют
* завершающие нулевые символы.
*/
ткст0  найдиподтекс(in ткст0 стр, in ткст0 иском)
	{
	return strstr(стр, иском);
	}
	
alias найдиподтекс найди_подтекст ;

/////////////////////////////////////////
/*
* Функция strtok /стрзнак/ находит следующий знак в стрзнак.
* Набор символов в строгран определяет возможные
* разграничители искомого в стрзнак знака.
*/
ткст0  стрзнак(ткст0 стрзнак, in ткст0 строгран)
	{
	return strtok(стрзнак, строгран);
	}
////////////////////////////////////////
/*
* Функция strerror /строшиб/ преобразует номош в
* строку сообщения об ошибке, возвращая указатель на
* эту строку. Ни strerror, ни _strerror на самом деле
* не выводят сообщения: для этого требуется вызвать
* функцию вывода типа fprintf:

	if (( _access( "datafile",2 )) == -1 )
   fprintf( stderr, _strerror(NULL) );
   
* Если  strErrMsg передано как NULL, _strerror возвратит указатель
* на строку, содержащую системное сообщение об ошибке для последней
* вызваной библиотеки, создавшей ошибку. Строка сообщения об ошибке
* завершается символом перехода на новую строку ('\n'). Если strErrMsg
* не равно NULL, то _strerror возвращает уккзатель на строку,
* содержащую ваше сообщение об ошибке, точку с запятой, пробел, системное
* сообщение об ошибке последней вызванной библиотеки и символ новой строки.
* Строковое сообщение может быть длиной не более 94 символов.

* Действительный номер ошибки для _strerror хранится в переменной errno.
* Системные сообщения об ошибке доступны через переменную _sys_errlist,
* являющую собой масссив упорядоченных по номеру ошибки сообщений.
* _strerror получает доступ к соответствующему сообщению по значению errno,
* представляющему индекс в переменной _sys_errlist. Значение переменной _sys_nerr
* определено как максимальное число элементов в массиве _sys_errlist. 
* Для правильной работы _strerror вызывается сразу после того, как процедура
* библиотеки вернула ошибку. Иначе последующие вызовы strerror или _strerror
* могут переписать значение errno.
*/
ткст  строшиб(цел номош)
	{
	return вТкст(strerror(номош));
	}

////////////////////////////////////////
/*
* strlen /длинтекс/ воспринимает строку как однобайтный символьный ряд, поэтому значение
* возврата всегда равно числу байтов, даже если в строке есть многобайтные
* символы. wcslen -это широкосимвольная версия strlen.
*/
т_мера длинтекс(in ткст0 текст)
	{
	//return cast(т_мера) strlen (текст);
	
	т_мера len = 0;
    while (текст[len]) ++len;
    return len;
	}
////////////////

т_мера длинашкс (in шим* с){return wcslen(cast(wchar_t*) с);}

//////////////////////////////////////////////////////////////////////
ук начнить(сифунк_У адр, бцел размстэка, ук аргспис)
{
return адаптВыхУкз(cast(ук) _beginthread(адр, размстэка, адаптВхоУкз(аргспис))); 
}

проц стопнить(){_endthread();}

ук начнитьдоп(ук безоп, бцел размстэка, винфункбЦ_У адр, ук аргспис, бцел иницфлаг, бцел* адрнити)
{
return адаптВыхУкз(cast(ук) _beginthreadex(адаптВхоУкз(безоп), размстэка, cast(stdfp) адр, аргспис, иницфлаг, адрнити));
}

проц стопнитьдоп(бцел кодвых){_endthreadex(кодвых);}

