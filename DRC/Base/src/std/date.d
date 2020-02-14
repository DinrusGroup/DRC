
// Написано на языке программирования Динрус. Разработчик Виталий Кулич.

/**
 * Dates are represented in several formats. The дата implementation revolves
 * around a central type, d_time, from which other formats are converted to and
 * from.
 * Dates are calculated using the Gregorian calendar.
 * References:
 *	$(LINK2 http://en.wikipedia.org/wiki/Gregorian_calendar, Gregorian calendar (Wikipedia))
 * Macros:
 *	WIKI = Phobos/StdDate
 */

// Copyright (c) 1999-2008 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com

module std.date;

private import std.io, cidrus;
private import std.dateparse;

/*extern (C)
{
int vsprintf(char* s, in char* format, va_list арг);
int sprintf(char* s, in char* format, ...);
}*/
/**
 * d_time is a signed arithmetic type giving the time elapsed since January 1,
 * 1970.
 * Negative values are for dates preceding 1970. The time unit used is Ticks.
 * Ticks are milliseconds or smaller intervals.
 *
 * The usual arithmetic operations can be performed on d_time, such as adding,
 * subtracting, etc. Elapsed time in Ticks can be computed by subtracting a
 * starting d_time from an ending d_time. 
 */
alias long d_time, д_время;
/**
 * A value for d_time that does not represent a valid time.
 */
const d_time d_time_nan = long.min;
alias d_time_nan д_время_нч;
alias Date Дата;
//alias toISO8601YearWeek вГодНедИСО8601;
//alias dmod
//alias HourFromTime часИзВрем;
//alias MinFromTime минИзВрем;
//alias SecFromTime секИзВрем;
//alias msFromTime мсекИзВрем;
//alias TimeWithinDay времениВДне;
//alias toInteger вЦелое;
//alias Day День;
//alias LeapYear високосныйГод;
//alias DaysInYear днейВГоду;
//alias DayFromYear деньИзГода;
//alias TimeFromYear времяИзГода;
//alias YearFromTime годИзВремени;
//alias inLeapYear високосный_ли;
//alias MonthFromTime месИзВрем;  
//alias DateFromTime датаИзВрем;
alias WeekDay деньНедели;
alias UTCtoLocalTime униВрВЛок;
alias LocalTimetoUTC локВрВУни;
alias MakeTime создайВремя;
alias MakeDay создайДень;
alias MakeDate создайДату;
alias TimeClip клипВремени;
alias DateFromNthWeekdayOfMonth датаПоНеделиМесяца;
alias DaysInMonth днейВМесяце;
alias toString вТкст;
alias toUTCString вУниВрТкст;
alias toDateString вТкстДаты; 
 alias toTimeString вТкстВремени;
 alias parse разбор;
 alias getUTCtime дайУниВр;
alias FILETIME2d_time ФВРЕМЯ8д_время;
 alias SYSTEMTIME2d_time СИСВРЕМЯ8д_время;
 alias дайЛокTZA дайЛокЧПП;
 alias DaylightSavingTA поправкаСветовогоДня;
 alias DosFileTime ФВремяДОС;
 alias toDtime вДВремя;
 alias toDosFileTime вФВремяДОС;
 
/**
 * Time broken down into its components.
 */
struct Date
{
alias year год;
alias day день;
alias hour час;
alias minute минута;
alias second секунда;
alias ms мсек;
alias weekday деньнед;
alias tzcorrection поправкаЧП;
alias parse разбор;

    int year = int.min;	/// use int.min as "nan" year value
    int month;		/// 1..12
    int day;		/// 1..31
    int hour;		/// 0..23
    int minute;		/// 0..59
    int second;		/// 0..59
    int ms;		/// 0..999
    int weekday;	/// 0: not specified, 1..7: Sunday..Saturday
    int tzcorrection = int.min;	/// -1200..1200 correction in hours

    /// Parse дата out of string s[] and store it in this Date instance.
    void parse(string s)
    {
	DateParse dp;

	dp.parse(s, *this);
    }
}

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
}

enum
{
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
 * Compute year and week [1..53] from t. The ISO 8601 week 1 is the first week
 * of the year that includes January 4. Monday is the first day of the week.
 * References:
 *	$(LINK2 http://en.wikipedia.org/wiki/ISO_8601, ISO 8601 (Wikipedia))
 */
проц  вГодНедИСО8601(д_время t, out цел год, out цел неделя)
	{ toISO8601YearWeek(t, год, неделя);
	}
	
цел День(д_время t)
	{
		return cast(int)std.date.floor(t, msPerDay);
	}

цел високосныйГод(цел y)
	{
		return ((y & 3) == 0 &&
			(y % 100 || (y % 400) == 0));
	}

цел ДнейВГоду(цел y)
	{
		return 365 + LeapYear(y);
	}

цел деньИзГода(цел y)
	{
		return std.date.DayFromYear(y);
	}

д_время времяИзГода(цел y)
	{
		return cast(d_time)msPerDay * DayFromYear(y);
	}

цел годИзВремени(д_время t)
	{   
	return YearFromTime(t);
	}	
	
бул високосный_ли(д_время t)
	{
		if(LeapYear(YearFromTime(t)) != 0)
		return true;
		else return false;
	}

цел месИзВрем(д_время t)
	{
		return MonthFromTime(t);
	}

цел датаИзВрем(д_время t)
	{
		return DateFromTime(t);
	}
	
void toISO8601YearWeek(d_time t, out int year, out int week)
{
    year = YearFromTime(t);

    int yday = Day(t) - DayFromYear(year);
    int d;
    int w;
    int ydaybeg;

    /* Determine day of week Jan 4 falls on.
     * Weeks begin on a Monday.
     */

    d = DayFromYear(year);
    w = (d + 3/*Jan4*/ + 3) % 7;
    if (w < 0)
        w += 7;

    /* Find yday of beginning of ISO 8601 year
     */
    ydaybeg = 3/*Jan4*/ - w;

    /* Check if yday is actually the last week of the previous year
     */
    if (yday < ydaybeg)
    {
	year -= 1;
	week = 53;
        return;
    }

    /* Check if yday is actually the first week of the следщ year
     */
    if (yday >= 362)                            // possible
    {   int d2;
        int ydaybeg2;

        d2 = DayFromYear(year + 1);
        w = (d2 + 3/*Jan4*/ + 3) % 7;
        if (w < 0)
            w += 7;
        //эхо("w = %d\n", w);
        ydaybeg2 = 3/*Jan4*/ - w;
        if (d + yday >= d2 + ydaybeg2)
        {
	    year += 1;
	    week = 1;
            return;
        }
    }

    week = (yday - ydaybeg) / 7 + 1;
}

/* ***********************************
 * Divide time by divisor. Always round down, even if d is negative.
 */

д_время нокругли(д_время d, цел делитель)
	{
	return floor(d, делитель);	
	}
	
цел дмод(д_время n, д_время d)
	{   return dmod(n,d);
	}
	
d_time floor(d_time d, int divisor)
{
    if (d < 0)
	d -= divisor - 1;
    return d / divisor;
}

int dmod(d_time n, d_time d)
{   d_time r;

    r = n % d;
    if (r < 0)
	r += d;
    assert(cast(int)r == r);
    return cast(int)r;
}

цел часИзВрем(д_время t)
	{
		return dmod(floor(t, msPerHour), HoursPerDay);
	}
	
цел минИзВрем(д_время t)
	{
		return dmod(floor(t, msPerMinute), MinutesPerHour);
	}
	
цел секИзВрем(д_время t)
	{
		return dmod(floor(t, TicksPerSecond), 60);
	}
	
цел мсекИзВрем(д_время t)
	{
		return dmod(t / (TicksPerSecond / 1000), 1000);
	}
	
int HourFromTime(d_time t)
{
    return dmod(floor(t, msPerHour), HoursPerDay);
}

int MinFromTime(d_time t)
{
    return dmod(floor(t, msPerMinute), MinutesPerHour);
}

int SecFromTime(d_time t)
{
    return dmod(floor(t, TicksPerSecond), 60);
}

int msFromTime(d_time t)
{
    return dmod(t / (TicksPerSecond / 1000), 1000);
}

int TimeWithinDay(d_time t)
{
    return dmod(t, msPerDay);
}

цел времениВДне(д_время t)
	{
		return dmod(t, msPerDay);
	}

d_time toInteger(d_time n)
{
    return n;
}

д_время вЦелое(д_время n)
	{
		return n;
	}

int Day(d_time t)
{
    return cast(int)floor(t, msPerDay);
}

int LeapYear(int y)
{
    return ((y & 3) == 0 &&
	    (y % 100 || (y % 400) == 0));
}

int DaysInYear(int y)
{
    return 365 + LeapYear(y);
}

int DayFromYear(int y)
{
    return cast(int) (365 * (y - 1970) +
		floor((y - 1969), 4) -
		floor((y - 1901), 100) +
		floor((y - 1601), 400));
}

d_time TimeFromYear(int y)
{
    return cast(d_time)msPerDay * DayFromYear(y);
}

/*****************************
 * Calculates the year from the d_time t.
 */

int YearFromTime(d_time t)
{   int y;

    if (t == d_time_nan)
	return 0;

    // Hazard a guess
    //y = 1970 + cast(int) (t / (365.2425 * msPerDay));
    // Use integer only math
    y = 1970 + cast(int) (t / (3652425 * (msPerDay / 10000)));

    if (TimeFromYear(y) <= t)
    {
	while (TimeFromYear(y + 1) <= t)
	    y++;
    }
    else
    {
	do
	{
	    y--;
	}
	while (TimeFromYear(y) > t);
    }
    return y;
}

/*******************************
 * Determines if d_time t is a leap year.
 *
 * A leap year is every 4 years except years ending in 00 that are not
 * divsible by 400.
 *
 * Returns: !=0 if it is a leap year.
 *
 * References:
 *	$(LINK2 http://en.wikipedia.org/wiki/Leap_year, Wikipedia)
 */

int inLeapYear(d_time t)
{
    return LeapYear(YearFromTime(t));
}

/*****************************
 * Calculates the month from the d_time t.
 *
 * Returns: Integer in the range 0..11, where
 *	0 represents January and 11 represents December.
 */

int MonthFromTime(d_time t)
{
    int day;
    int month;
    int year;

    year = YearFromTime(t);
    day = Day(t) - DayFromYear(year);

    if (day < 59)
    {
	if (day < 31)
	{   assert(day >= 0);
	    month = 0;
	}
	else
	    month = 1;
    }
    else
    {
	day -= LeapYear(year);
	if (day < 212)
	{
	    if (day < 59)
		month = 1;
	    else if (day < 90)
		month = 2;
	    else if (day < 120)
		month = 3;
	    else if (day < 151)
		month = 4;
	    else if (day < 181)
		month = 5;
	    else
		month = 6;
	}
	else
	{
	    if (day < 243)
		month = 7;
	    else if (day < 273)
		month = 8;
	    else if (day < 304)
		month = 9;
	    else if (day < 334)
		month = 10;
	    else if (day < 365)
		month = 11;
	    else
		assert(0);
	}
    }
    return month;
}

/*******************************
 * Compute which day in a month a d_time t is.
 * Returns:
 *	Integer in the range 1..31
 */
int DateFromTime(d_time t)
{
    int day;
    int leap;
    int month;
    int year;
    int дата;

    year = YearFromTime(t);
    day = Day(t) - DayFromYear(year);
    leap = LeapYear(year);
    month = MonthFromTime(t);
    switch (month)
    {
	case 0:	 дата = day +   1;		break;
	case 1:	 дата = day -  30;		break;
	case 2:	 дата = day -  58 - leap;	break;
	case 3:	 дата = day -  89 - leap;	break;
	case 4:	 дата = day - 119 - leap;	break;
	case 5:	 дата = day - 150 - leap;	break;
	case 6:	 дата = day - 180 - leap;	break;
	case 7:	 дата = day - 211 - leap;	break;
	case 8:	 дата = day - 242 - leap;	break;
	case 9:	 дата = day - 272 - leap;	break;
	case 10: дата = day - 303 - leap;	break;
	case 11: дата = day - 333 - leap;	break;
	default:
	    assert(0);
    }
    return дата;
}

/*******************************
 * Compute which day of the week a d_time t is.
 * Returns:
 *	Integer in the range 0..6, where 0 represents Sunday
 *	and 6 represents Saturday.
 */
int WeekDay(d_time t)
{   int w;

    w = (cast(int)Day(t) + 4) % 7;
    if (w < 0)
	w += 7;
    return w;
}

/***********************************
 * Convert from UTC to local time.
 */

d_time UTCtoLocalTime(d_time t)
{
    return (t == d_time_nan)
	? d_time_nan
	: t + LocalTZA + DaylightSavingTA(t);
}

/***********************************
 * Convert from local time to UTC.
 */

d_time LocalTimetoUTC(d_time t)
{
    return (t == d_time_nan)
	? d_time_nan
/* BUGZILLA 1752 says this line should be:
 *	: t - LocalTZA - DaylightSavingTA(t);
 */
	: t - LocalTZA - DaylightSavingTA(t - LocalTZA);
}


d_time MakeTime(d_time hour, d_time min, d_time sec, d_time ms)
{
    return hour * TicksPerHour +
	   min * ТиковВМинуту +
	   sec * TicksPerSecond +
	   ms * TicksPerMs;
}

/* *****************************
 * Параметры:
 *	month = 0..11
 *	дата = day of month, 1..31
 * Returns:
 *	number of days since start of epoch
 */

d_time MakeDay(d_time year, d_time month, d_time дата)
{   d_time t;
    int y;
    int m;
    int leap;

    y = cast(int)(year + floor(month, 12));
    m = dmod(month, 12);

    leap = LeapYear(y);
    t = TimeFromYear(y) + cast(d_time)mdays[m] * msPerDay;
    if (leap && month >= 2)
	t += msPerDay;

    if (YearFromTime(t) != y ||
	MonthFromTime(t) != m ||
	DateFromTime(t) != 1)
    {
	return  d_time_nan;
    }

    return Day(t) + дата - 1;
}

d_time MakeDate(d_time day, d_time time)
{
    if (day == d_time_nan || time == d_time_nan)
	return d_time_nan;

    return day * TicksPerDay + time;
}

d_time TimeClip(d_time time)
{
    //эхо("TimeClip(%g) = %g\n", time, toInteger(time));

    return toInteger(time);
}

/***************************************
 * Determine the дата in the month, 1..31, of the nth
 * weekday.
 * Параметры:
 *	year = year
 *	month = month, 1..12
 *	weekday = day of week 0..6 representing Sunday..Saturday
 *	n = nth occurrence of that weekday in the month, 1..5, where
 *	    5 also means "the last occurrence in the month"
 * Returns:
 *	the дата in the month, 1..31, of the nth weekday
 */

int DateFromNthWeekdayOfMonth(int year, int month, int weekday, int n)
in
{
    assert(1 <= month && month <= 12);
    assert(0 <= weekday && weekday <= 6);
    assert(1 <= n && n <= 5);
}
body
{
    // Get day of the first of the month
    auto x = MakeDay(year, month - 1, 1);

    // Get the week day 0..6 of the first of this month
    auto wd = WeekDay(MakeDate(x, 0));

    // Get monthday of first occurrence of weekday in this month
    auto mday = weekday - wd + 1;
    if (mday < 1)
	mday += 7;

    // Add in number of weeks
    mday += (n - 1) * 7;

    // If monthday is more than the number of days in the month,
    // back up to 'last' occurrence
    if (mday > 28 && mday > DaysInMonth(year, month))
    {	assert(n == 5);
	mday -= 7;
    }

    return mday;
}

unittest
{
    assert(DateFromNthWeekdayOfMonth(2003,  3, 0, 5) == 30);
    assert(DateFromNthWeekdayOfMonth(2003, 10, 0, 5) == 26);
    assert(DateFromNthWeekdayOfMonth(2004,  3, 0, 5) == 28);
    assert(DateFromNthWeekdayOfMonth(2004, 10, 0, 5) == 31);
}

/**************************************
 * Determine the number of days in a month, 1..31.
 * Параметры:
 *	month = 1..12
 */

int DaysInMonth(int year, int month)
{
    switch (month)
    {
	case 1:
	case 3:
	case 5:
	case 7:
	case 8:
	case 10:
	case 12:
	    return 31;
	case 2:
	    return 28 + LeapYear(year);
	case 4:
	case 6:
	case 9:
	case 11:
	    return 30;
	default:
	    assert(0);
    }
}

unittest
{
    assert(DaysInMonth(2003, 2) == 28);
    assert(DaysInMonth(2004, 2) == 29);
}

/*************************************
 * Converts UTC time into a text string of the form:
 * "Www Mmm dd hh:mm:ss GMT+-TZ yyyy".
 * For example, "Tue Apr 02 02:04:57 GMT-0800 1996".
 * If time is invalid, i.e. is d_time_nan,
 * the string "Invalid дата" is returned.
 *
 * Example:
 * ------------------------------------
  d_time lNow;
  char[] lNowString;

  // Grab the дата and time relative to UTC
  lNow = std.date.getUTCtime();
  // Convert this into the local дата and time for display.
  lNowString = std.date.toString(lNow);
 * ------------------------------------
 */

string toString(d_time time)
{
    d_time t;
    char sign;
    int hr;
    int mn;
    int len;
    d_time offset;
    d_time dst;

    // Years are supposed to be -285616 .. 285616, or 7 digits
    // "Tue Apr 02 02:04:57 GMT-0800 1996"
    char[] buffer = new char[29 + 7 + 1];

    if (time == d_time_nan)
	return "Invalid Date";

    dst = DaylightSavingTA(time);
    offset = LocalTZA + dst;
    t = time + offset;
    sign = '+';
    if (offset < 0)
    {	sign = '-';
//	offset = -offset;
	offset = -(LocalTZA + dst);
    }

    mn = cast(int)(offset / msPerMinute);
    hr = mn / 60;
    mn %= 60;

    //эхо("hr = %d, offset = %g, LocalTZA = %g, dst = %g, + = %g\n", hr, offset, LocalTZA, dst, LocalTZA + dst);

    len = sprintf(buffer.ptr, "%.3s %.3s %02d %02d:%02d:%02d GMT%c%02d%02d %d",
	&daystr[WeekDay(t) * 3],
	&monstr[MonthFromTime(t) * 3],
	DateFromTime(t),
	HourFromTime(t), MinFromTime(t), SecFromTime(t),
	sign, hr, mn,
	cast(long)YearFromTime(t));

    // Ensure no buggy buffer overflows
    //эхо("len = %d, buffer.length = %d\n", len, buffer.length);
    assert(len < buffer.length);

    return buffer[0 .. len];
}

/***********************************
 * Converts t into a text string of the form: "Www, dd Mmm yyyy hh:mm:ss UTC".
 * If t is invalid, "Invalid дата" is returned.
 */

string toUTCString(d_time t)
{
    // Years are supposed to be -285616 .. 285616, or 7 digits
    // "Tue, 02 Apr 1996 02:04:57 GMT"
    char[] buffer = new char[25 + 7 + 1];
    int len;

    if (t == d_time_nan)
	return "Invalid Date";

    len = sprintf(buffer.ptr, "%.3s, %02d %.3s %d %02d:%02d:%02d UTC",
	&daystr[WeekDay(t) * 3], DateFromTime(t),
	&monstr[MonthFromTime(t) * 3],
	YearFromTime(t),
	HourFromTime(t), MinFromTime(t), SecFromTime(t));

    // Ensure no buggy buffer overflows
    assert(len < buffer.length);

    return buffer[0 .. len];
}

/************************************
 * Converts the дата portion of time into a text string of the form: "Www Mmm dd
 * yyyy", for example, "Tue Apr 02 1996".
 * If time is invalid, "Invalid дата" is returned.
 */

string toDateString(d_time time)
{
    d_time t;
    d_time offset;
    d_time dst;
    int len;

    // Years are supposed to be -285616 .. 285616, or 7 digits
    // "Tue Apr 02 1996"
    char[] buffer = new char[29 + 7 + 1];

    if (time == d_time_nan)
	return "Invalid Date";

    dst = DaylightSavingTA(time);
    offset = LocalTZA + dst;
    t = time + offset;

    len = sprintf(buffer.ptr, "%.3s %.3s %02d %d",
	&daystr[WeekDay(t) * 3],
	&monstr[MonthFromTime(t) * 3],
	DateFromTime(t),
	cast(long)YearFromTime(t));

    // Ensure no buggy buffer overflows
    assert(len < buffer.length);

    return buffer[0 .. len];
}

/******************************************
 * Converts the time portion of t into a text string of the form: "hh:mm:ss
 * GMT+-TZ", for example, "02:04:57 GMT-0800".
 * If t is invalid, "Invalid дата" is returned.
 * The input must be in UTC, and the output is in local time.
 */

string toTimeString(d_time time)
{
    d_time t;
    char sign;
    int hr;
    int mn;
    int len;
    d_time offset;
    d_time dst;

    // "02:04:57 GMT-0800"
    char[] buffer = new char[17 + 1];

    if (time == d_time_nan)
	return "Invalid Date";

    dst = DaylightSavingTA(time);
    offset = LocalTZA + dst;
    t = time + offset;
    sign = '+';
    if (offset < 0)
    {	sign = '-';
//	offset = -offset;
	offset = -(LocalTZA + dst);
    }

    mn = cast(int)(offset / msPerMinute);
    hr = mn / 60;
    mn %= 60;

    //эхо("hr = %d, offset = %g, LocalTZA = %g, dst = %g, + = %g\n", hr, offset, LocalTZA, dst, LocalTZA + dst);

    len = sprintf(buffer.ptr, "%02d:%02d:%02d GMT%c%02d%02d",
	HourFromTime(t), MinFromTime(t), SecFromTime(t),
	sign, hr, mn);

    // Ensure no buggy buffer overflows
    assert(len < buffer.length);

    // Lop off terminating 0
    return buffer[0 .. len];
}


/******************************************
 * Parses s as a textual дата string, and returns it as a d_time.
 * If the string is not a valid дата, d_time_nan is returned.
 */

d_time parse(string s)
{
    Date dp;
    d_time n;
    d_time day;
    d_time time;

    try
    {
	dp.parse(s);

	//writefln("year = %d, month = %d, day = %d", dp.year, dp.month, dp.day);
	//writefln("%02d:%02d:%02d.%03d", dp.hour, dp.minute, dp.second, dp.ms);
	//writefln("weekday = %d, ampm = %d, tzcorrection = %d", dp.weekday, 1, dp.tzcorrection);

	time = MakeTime(dp.hour, dp.minute, dp.second, dp.ms);
	if (dp.tzcorrection == int.min)
	    time -= LocalTZA;
	else
	{
	    time += cast(d_time)(dp.tzcorrection / 100) * msPerHour +
		    cast(d_time)(dp.tzcorrection % 100) * msPerMinute;
	}
	day = MakeDay(dp.year, dp.month - 1, dp.day);
	n = MakeDate(day,time);
	n = TimeClip(n);
    }
    catch
    {
	n =  d_time_nan;		// erroneous дата string
    }
    return n;
}

static this()
{
    LocalTZA = дайЛокTZA();
    //эхо("LocalTZA = %g, %g\n", LocalTZA, LocalTZA / msPerHour);
}

version (Win32)
{

    private import sys.WinFuncs;
    //import c.time;

    /******
     * Get current UTC time.
     */
    d_time getUTCtime()
    {
	СИСТВРЕМЯ st;
	d_time n;

	ДайСистВремя(&st);		// get time in UTC
	n = SYSTEMTIME2d_time(&st, 0);
	return n;
	//return c.time.time(null) * TicksPerSecond;
    }

    static d_time FILETIME2d_time(ФВРЕМЯ *ft)
    {   СИСТВРЕМЯ st;

	if (!ФВремяВСистВремя(ft, &st))
	    return d_time_nan;
	return SYSTEMTIME2d_time(&st, 0);
    }

    static d_time SYSTEMTIME2d_time(СИСТВРЕМЯ *st, d_time t)
    {
	/* More info: http://delphicikk.atw.hu/listaz.php?id=2667&oldal=52
	 */
	d_time n;
	d_time day;
	d_time time;

	if (st.год)
	{
	    time = MakeTime(st.час, st.минута, st.секунда, st.миллисекунды);
	    day = MakeDay(st.год, st.месяц - 1, st.день);
	}
	else
	{   /* wYear being 0 is a flag to indicate relative time:
	     * wMonth is the month 1..12
	     * wDayOfWeek is weekday 0..6 corresponding to Sunday..Saturday
	     * wDay is the nth time, 1..5, that wDayOfWeek occurs
	     */

	    auto year = YearFromTime(t);
	    auto mday = DateFromNthWeekdayOfMonth(year, st.месяц, st.день, st.день_недели);
	    day = MakeDay(year, st.месяц - 1, mday);
	    time = MakeTime(st.час, st.минута, 0, 0);
	}
	n = MakeDate(day,time);
	n = TimeClip(n);
	return n;
    }

    d_time дайЛокTZA()
    {
	d_time t;
	DWORD r;
	ИНФОЧП tzi;

	/* http://msdn.microsoft.com/library/en-us/sysinfo/base/gettimezoneinformation.asp
	 * http://msdn2.microsoft.com/en-us/library/ms725481.aspx
	 */
	r = ДайИнфОЧП(&tzi);
	//эхо("bias = %d\n", tzi.Bias);
	//эхо("standardbias = %d\n", tzi.StandardBias);
	//эхо("daylightbias = %d\n", tzi.DaylightBias);
	switch (r)
	{
	    case ПИдЧП.Стд:
		t = -(tzi.Разница + tzi.СтандартнаяРазница) * cast(d_time)(60 * TicksPerSecond);
		break;
	    case ПИдЧП.Дэйлайт:
		//t = -(tzi.Bias + tzi.DaylightBias) * cast(d_time)(60 * TicksPerSecond);
		//break;
	    case ПИдЧП.Неизв:
		t = -(tzi.Разница) * cast(d_time)(60 * TicksPerSecond);
		break;

	    default:
		t = 0;
		break;
	}

	return t;
    }

    /*
     * Get daylight savings time adjust for time dt.
     */

    int DaylightSavingTA(d_time dt)
    {
	int t;
	DWORD r;
	ИНФОЧП tzi;
	d_time ts;
	d_time td;

	/* http://msdn.microsoft.com/library/en-us/sysinfo/base/gettimezoneinformation.asp
	 */
	r = ДайИнфОЧП(&tzi);
	t = 0;
	switch (r)
	{
	    case ПИдЧП.Стд:
	    case ПИдЧП.Дэйлайт:
		if (tzi.СтандартнаяДата.месяц == 0 ||
		    tzi.ДатаДейлайт.месяц == 0)
		    break;

		ts = SYSTEMTIME2d_time(&tzi.СтандартнаяДата, dt);
		td = SYSTEMTIME2d_time(&tzi.ДатаДейлайт, dt);

		if (td <= dt && dt < ts)
		{
		    t = -tzi.РазницаДейлайт * (60 * TicksPerSecond);
		    //эхо("DST is in effect, %d\n", t);
		}
		else
		{
		    //эхо("no DST\n");
		}
		break;

	    case ПИдЧП.Неизв:
		// Daylight savings time not used in this time zone
		break;

	    default:
		assert(0);
	}
	return t;
    }
}

version (Posix)
{

    private import os.posix;

    d_time getUTCtime()
    {   timeval tv;

	//эхо("getUTCtime()\n");
	if (gettimeofday(&tv, null))
	{   // Some error happened - try time() instead
	    return time(null) * TicksPerSecond;
	}

	return tv.tv_sec * cast(d_time)TicksPerSecond +
		(tv.tv_usec / (1000000 / cast(d_time)TicksPerSecond));
    }

    d_time дайЛокTZA()
    {
	__time_t t;

	time(&t);
      version (OSX)
      { tm результат;
	localtime_r(&t, &результат);
	return результат.tm_gmtoff * TicksPerSecond;
      }
      else
      {
	localtime(&t);	// this will set timezone
	return -(timezone * TicksPerSecond);
      }
    }

    /*
     * Get daylight savings time adjust for time dt.
     */

    int DaylightSavingTA(d_time dt)
    {
	tm *tmp;
	os.posix.__time_t t;
	int dst = 0;

	if (dt != d_time_nan)
	{
	    d_time seconds = dt / TicksPerSecond;
	    t = cast(__time_t) seconds;
	    if (t == seconds)	// if in range
	    {
		tmp = localtime(&t);
		if (tmp.tm_isdst > 0)
		    dst = TicksPerHour;	// BUG: Assume daylight savings time is plus one hour.
	    }
	    else // out of range for system time, use our own calculation
	    {
		/* BUG: this works for the US, but not other timezones.
		 */

		dt -= LocalTZA;

		int year = YearFromTime(dt);

		/* Compute time given year, month 1..12,
		 * week in month, weekday, hour
		 */
		d_time dstt(int year, int month, int week, int weekday, int hour)
		{
		    auto mday = DateFromNthWeekdayOfMonth(year,  month, weekday, week);
		    return TimeClip(MakeDate(
			MakeDay(year, month - 1, mday),
			MakeTime(hour, 0, 0, 0)));
		}

		d_time start;
		d_time end;
		if (year < 2007)
		{   // Daylight savings time goes from 2 AM the first Sunday
		    // in April through 2 AM the last Sunday in October
		    start = dstt(year,  4, 1, 0, 2);
		    end   = dstt(year, 10, 5, 0, 2);
		}
		else
		{
		    // the second Sunday of March to
		    // the first Sunday in November
		    start = dstt(year,  3, 2, 0, 2);
		    end   = dstt(year, 11, 1, 0, 2);
		}

		if (start <= dt && dt < end)
		    dst = TicksPerHour;
		//writefln("start = %s, dt = %s, end = %s, dst = %s", start, dt, end, dst);
	    }
	}
	return dst;
    }

}


/+ ====================== DOS File Time =============================== +/

/***
 * Type representing the DOS file дата/time format.
 */
typedef uint DosFileTime;

/************************************
 * Convert from DOS file дата/time to d_time.
 */

d_time toDtime(DosFileTime time)
{
    uint dt = cast(uint)time;

    if (dt == 0)
	return d_time_nan;

    int year = ((dt >> 25) & 0x7F) + 1980;
    int month = ((dt >> 21) & 0x0F) - 1;	// 0..12
    int dayofmonth = ((dt >> 16) & 0x1F);	// 0..31
    int hour = (dt >> 11) & 0x1F;		// 0..23
    int minute = (dt >> 5) & 0x3F;		// 0..59
    int second = (dt << 1) & 0x3E;		// 0..58 (in 2 second increments)

    d_time t;

    t = std.date.MakeDate(std.date.MakeDay(year, month, dayofmonth),
	    std.date.MakeTime(hour, minute, second, 0));

    assert(YearFromTime(t) == year);
    assert(MonthFromTime(t) == month);
    assert(DateFromTime(t) == dayofmonth);
    assert(HourFromTime(t) == hour);
    assert(MinFromTime(t) == minute);
    assert(SecFromTime(t) == second);

    t -= LocalTZA + DaylightSavingTA(t);

    return t;
}

/****************************************
 * Convert from d_time to DOS file дата/time.
 */

DosFileTime toDosFileTime(d_time t)
{   uint dt;

    if (t == d_time_nan)
	return cast(DosFileTime)0;

    t += LocalTZA + DaylightSavingTA(t);

    uint year = YearFromTime(t);
    uint month = MonthFromTime(t);
    uint dayofmonth = DateFromTime(t);
    uint hour = HourFromTime(t);
    uint minute = MinFromTime(t);
    uint second = SecFromTime(t);

    dt = (year - 1980) << 25;
    dt |= ((month + 1) & 0x0F) << 21;
    dt |= (dayofmonth & 0x1F) << 16;
    dt |= (hour & 0x1F) << 11;
    dt |= (minute & 0x3F) << 5;
    dt |= (second >> 1) & 0x1F;

    return cast(DosFileTime)dt;
}
