/* Public Domain */

/**
 * Support UTF-8 on Windows 95, 98 and ME systems.
 * Macros:
 *	WIKI = Phobos/StdWindowsCharset
 */

module rt.charset;

private import sys.WinFuncs;
private import rt.syserror;
private import std.utf;
private import std.string;

///////////////////////////////////////////////////////
ткст0 вМБТн(ткст с, бцел кодСтр = 1)
{
return cast(усим) toMBSz(cast(char[]) с, cast(uint) кодСтр);
}
////////////////////////////////////////////////////////////
ткст изМБТн(ткст0 с, цел кодСтр = 1)
{
return cast(сим[]) fromMBSz(cast(char*) с, cast(int) кодСтр);
}
////////////////////////////////////////////////////////////
/******************************************
 * Преобразовать строку UTF-8 s в строку с нулевым окончанием в
 * 8-битном символьном наборе Windows.
 *
 * Параметры:
 * s = преобразуемая строка UTF-8.
 * codePage = номер целевой кодовой страницы, либо
 *   0 - ANSI,
 *   1 - OEM,
 *   2 - Mac
 *
 * Authors:
 *	yaneurao, Walter Bright, Stewart Gordon
 */

char* toMBSz(char[] s, uint codePage = 0)
{
    // Only need to do this if any chars have the high bit set
    foreach (char c; s)
    {
	if (c >= 0x80)
	{
	    char[] результат;
	    int readLen;
	    wchar* ws = std.utf.toUTF16z(s);
	    результат.length = sys.WinFuncs.WideCharToMultiByte(codePage, 0, ws, -1, null, 0,
		null, null);

	    if (результат.length)
	    {
		readLen = sys.WinFuncs.WideCharToMultiByte(codePage, 0, ws, -1, результат.ptr,
			результат.length, null, null);
	    }

	    if (!readLen || readLen != результат.length)
	    {
		throw new Exception("Не удалось конвертировать строку: " ~
			sysErrorString(GetLastError()),__FILE__,__LINE__);
	    }

	    return результат.ptr;
	}
    }
    return std.string.toStringz(s);
}


/**********************************************
 * Converts the null-terminated string s from a Windows 8-bit character set
 * into a UTF-8 char array.
 *
 * Параметры:
 * s = UTF-8 string to convert.
 * codePage = is the number of the source codepage, or
 *   0 - ANSI,
 *   1 - OEM,
 *   2 - Mac
 * Authors: Stewart Gordon, Walter Bright
 */

char[] fromMBSz(char* s, int codePage = 0)
{
    char* c;

    for (c = s; *c != 0; c++)
    {
	if (*c >= 0x80)
	{
	    wchar[] результат;
	    int readLen;

	    результат.length = sys.WinFuncs.MultiByteToWideChar(codePage, 0, s, -1, null, 0);

	    if (результат.length)
	    {
		readLen = sys.WinFuncs.MultiByteToWideChar(codePage, 0, s, -1, результат.ptr,
			результат.length);
	    }

	    if (!readLen || readLen != результат.length)
	    {
		throw new Exception("Не удалось конвертировать строку: " ~
		    sysErrorString(GetLastError()),__FILE__,__LINE__);
	    }

	    return std.utf.toUTF8(результат[0 .. результат.length-1]); // omit trailing null
	}
    }
    return s[0 .. c-s];		// string is ASCII, no conversion necessary
}


