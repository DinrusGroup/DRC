
// Written in the D programming language.

/**
 * Даты представляются в нескольких форматах. Реализация дат вращается
 * вокруг центрального типа, d_time (д_время), из которого и в который
 * преобразуются другие форматы.
 * Даты вычисляются по григорианскому календарю.
 * Ссылки:
 *	$(LINK2 http://en.wikipedia.org/wiki/Gregorian_calendar, Gregorian calendar (Wikipedia))
 * Macros:
 *	WIKI = Phobos/StdDate
 */

// Copyright (c) 1999-2008 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com

module std.date;

private import std.io;
private import std.dateparse;
private import std.c;
/**
 * d_time (д_время) это арифметический тип со знаком, который даёт время, прошедшее с
 * 1 Января 1970.
 * Отрицательные значения соответствуют датам в 1970. Используется единица времени Ticks.
 * Тики - это миллисекунды или ещё меньшие интервалы.
 *
 * The usual arithmetic operations can be performed on d_time, such as adding,
 * subtracting, etc. Elapsed time in Ticks can be computed by subtracting a
 * starting d_time из an ending d_time. 
 */
alias long d_time;
alias d_time д_время;

/**
 * A value for d_time that does not represent a valid time.
 */
const d_time d_time_nan = long.min;
alias d_time_nan д_время_нч;
/**
 * Time broken down into its components.
 */
struct Date
{
     int year = int.min;	/// use int.min as "nan" year value
	alias year год;
	
    int month;		/// 1..12
	alias month месяц;
	
    int day;		/// 1..31
	alias day день;
	
    int hour;		/// 0..23
	alias hour час;
	
    int minute;		/// 0..59
	alias minute минута;
	
    int second;		/// 0..59
	alias second секунда;
	
    int ms;		/// 0..999
	alias ms мсек;
	
    int weekday;	/// 0: not specified, 1..7: Sunday..Saturday
	alias weekday деньнед;
	
    int tzcorrection = int.min;	/// -1200..1200 correction in hours
	alias tzcorrection поправкаЧП;

    /// Parse date out of string s[] and store it in this Date instance.
    void parse(string s);
	alias parse разбор;
}
alias Date Дата;

enum
{
	HoursPerDay    = 24,
	MinutesPerHour = 60,
	msPerMinute    = 60 * 1000,
	msPerHour      = 60 * msPerMinute,
	msPerDay       = 86400000,
	TicksPerMs     = 1,
	TicksPerSecond = 1000,			/// Will be at least 1000
	TicksPerMinute = TicksPerSecond * 60,
	TicksPerHour   = TicksPerMinute * 60,
	TicksPerDay    = TicksPerHour   * 24,

	ЧасовВДне    = 24,
	МинутВЧасе = 60,
	МсекВМинуте    = 60 * 1000,
	МсекВЧасе      = 60 * МсекВМинуте,
	МсекВДень       = 86400000,
	ТиковВМсек     = 1,
	ТиковВСекунду = 1000,			/// Will be at least 1000
	ТиковВМинуту = ТиковВСекунду * 60,
	ТиковВЧас   = ТиковВМинуту * 60,
	ТиковВДень    = ТиковВЧас  * 24,
}

d_time LocalTZA = 0;
alias LocalTZA ЛокЧПП;

const char[] daystr = "SunMonTueWedThuFriSatВсПнВтСрЧтПтСб";
alias daystr стрдней;

const char[] monstr = "JanFebMarAprMayJunJulAugSepOctNovDec";

const int[12] mdays = [ 0,31,59,90,120,151,181,212,243,273,304,334 ];

/********************************
 * Compute year and week [1..53] из t. The ISO 8601 week 1 is the first week
 * of the year that includes January 4. Monday is the first day of the week.
 * Ссылки:
 *	$(LINK2 http://en.wikipedia.org/wiki/ISO_8601, ISO 8601 (Wikipedia))
 */

void toISO8601YearWeek(d_time t, out int year, out int week);
проц  вГодНедИСО8601(д_время t, out цел год, out цел неделя);

/* ***********************************
 * Делит время на делитель. Всегда округляет вниз, даже когда d отрицательный.
 */

d_time floor(d_time d, int divisor);
д_время нокругли(д_время d, цел делитель);

int dmod(d_time n, d_time d);
цел дмод(д_время n, д_время d);

int HourFromTime(d_time t);
цел часИзВрем(д_время t);

int MinFromTime(d_time t);
цел минИзВрем(д_время t);

int SecFromTime(d_time t);
цел секИзВрем(д_время t);

int msFromTime(d_time t);
цел мсекИзВрем(д_время t);

int TimeWithinDay(d_time t);
цел времениВДне(д_время t);

d_time toInteger(d_time n);
д_время вЦелое(д_время n);

int Day(d_time t);
цел День(д_время t);

int LeapYear(int y);
цел високосныйГод(цел y);

int DaysInYear(int y);
цел ДнейВГоду(цел y);

int DayFromYear(int y);
цел деньИзГода(цел y);

d_time TimeFromYear(int y);
д_время времяИзГода(цел y);

/*****************************
 * Calculates the year из the d_time t.
 */

int YearFromTime(d_time t);
цел годИзВремени(д_время t);

/*******************************
 * Determines if d_time t is a leap year.
 *
 * A leap year is every 4 years except years ending in 00 that are not
 * divsible by 400.
 *
 * Возвращает: != 0 (true) if it is a leap year.
 *
 * Ссылки:
 *	$(LINK2 http://en.wikipedia.org/wiki/Leap_year, Wikipedia)
 */

int inLeapYear(d_time t);
бул високосный_ли(д_время t);

/*****************************
 * Calculates the month из the d_time t.
 *
 * Возвращает: Integer in the range 0..11, where
 *	0 represents January and 11 represents December.
 */

int MonthFromTime(d_time t);
цел месИзВрем(д_время t);    

/*******************************
 * Compute which day in a month a d_time t is.
 * Возвращает:
 *	Integer in the range 1..31
 */
int DateFromTime(d_time t);
цел датаИзВрем(д_время t);	

/*******************************
 * Compute which day of the week a d_time t is.
 * Возвращает:
 *	Integer in the range 0..6, where 0 represents Sunday
 *	and 6 represents Saturday.
 */
int WeekDay(d_time t);
alias WeekDay деньНедели;
/***********************************
 * Convert из UTC to local time.
 */

d_time UTCtoLocalTime(d_time t);
alias UTCtoLocalTime униВрВЛок;
/***********************************
 * Convert из local time to UTC.
 */

d_time LocalTimetoUTC(d_time t);
alias LocalTimetoUTC локВрВУни;

d_time MakeTime(d_time hour, d_time min, d_time sec, d_time ms);
alias MakeTime создайВремя;
/* *****************************
 * Параметры:
 *	month = 0..11
 *	date = day of month, 1..31
 * Возвращает:
 *	number of days since start of epoch
 */

d_time MakeDay(d_time year, d_time month, d_time date);
alias MakeDay создайДень;

d_time MakeDate(d_time day, d_time time);
alias MakeDate создайДату;

d_time TimeClip(d_time time);
alias TimeClip клипВремени;

/***************************************
 * Determine the date in the month, 1..31, of the nth
 * weekday.
 * Параметры:
 *	year = year
 *	month = month, 1..12
 *	weekday = day of week 0..6 representing Sunday..Saturday
 *	n = nth occurrence of that weekday in the month, 1..5, where
 *	    5 also means "the last occurrence in the month"
 * Возвращает:
 *	the date in the month, 1..31, of the nth weekday
 */

int DateFromNthWeekdayOfMonth(int year, int month, int weekday, int n);
alias DateFromNthWeekdayOfMonth датаПоНеделиМесяца;   
/**************************************
 * Determine the number of days in a month, 1..31.
 * Параметры:
 *	month = 1..12
 */

int DaysInMonth(int year, int month);
alias DaysInMonth днейВМесяце;
/*************************************
 * Converts UTC time into a text string of the form:
 * "Www Mmm dd hh:mm:ss GMT+-TZ yyyy".
 * For example, "Tue Apr 02 02:04:57 GMT-0800 1996".
 * If time is invalid, i.e. is d_time_nan,
 * the string "Неверно date" is returned.
 *
 * Пример:
 * ------------------------------------
  d_time lNow;
  char[] lNowString;

  // Grab the date and time relative to UTC
  lNow = std.date.getUTCtime();
  // Convert this into the local date and time for display.
  lNowString = std.date.toString(lNow);
 * ------------------------------------
 */

string toString(d_time time);
alias toString вТкст;
/***********************************
 * Converts t into a text string of the form: "Www, dd Mmm yyyy hh:mm:ss UTC".
 * If t is invalid, "Неверно date" is returned.
 */

string toUTCString(d_time t);
alias toUTCString вУниВрТкст;
/************************************
 * Converts the date portion of time into a text string of the form: "Www Mmm dd
 * yyyy", for example, "Tue Apr 02 1996".
 * If time is invalid, "Неверно date" is returned.
 */

string toDateString(d_time time);
alias toDateString вТкстДаты;  

/******************************************
 * Converts the time portion of t into a text string of the form: "hh:mm:ss
 * GMT+-TZ", for example, "02:04:57 GMT-0800".
 * If t is invalid, "Неверно date" is returned.
 * The input must be in UTC, and the output is in local time.
 */

string toTimeString(d_time time);
 alias toTimeString вТкстВремени;   


/******************************************
 * Parses s as a textual date string, and returns it as a d_time.
 * If the string is not a valid date, d_time_nan is returned.
 */

d_time parse(string s);
alias parse разбор;
	  
static this();

version (Win32)
{

    private import os.windows;
    //import std.c;

    /******
     * Get current UTC time.
     */
    d_time getUTCtime();
	alias getUTCtime дайУниВр;

    static d_time FILETIME2d_time(FILETIME *ft);
	alias FILETIME2d_time ФВРЕМЯ8д_время;

    static d_time SYSTEMTIME2d_time(SYSTEMTIME *st, d_time t);
	alias SYSTEMTIME2d_time СИСВРЕМЯ8д_время;

	/* http://msdn.microsoft.com/library/en-us/sysinfo/base/gettimezoneinformation.asp
	 * http://msdn2.microsoft.com/en-us/library/ms725481.aspx
	 */
	
    d_time getLocalTZA();
	alias getLocalTZA дайЛокЧПП;
    /*
     * Get daylight savings time adjust for time dt.
     */

    int DaylightSavingTA(d_time dt);
	/* http://msdn.microsoft.com/library/en-us/sysinfo/base/gettimezoneinformation.asp
	 */
	alias DaylightSavingTA поправкаСветовогоДня;
}

/+ ====================== DOS File Time =============================== +/

/***
 * Type representing the DOS file date/time format.
 */
typedef uint DosFileTime;
alias DosFileTime ФВремяДОС;
/************************************
 * Convert из DOS file date/time to d_time.
 */

d_time toDtime(DosFileTime time);
alias toDtime вДВремя;
/****************************************
 * Convert из d_time to DOS file date/time.
 */

DosFileTime toDosFileTime(d_time t);
alias toDosFileTime вФВремяДОС;