
// Написано на языке программирования Динрус. Разработчик Виталий Кулич.

/* Written by Walter Bright and Andrei Alexandrescu
 * http://www.digitalmars.com/d
 * Placed in the Public Domain.
 */

/********************************
 * Стандартные функции I/O, расширяющие $(B c).
 * $(B c) импортируется автоматически при импорте
 * $(B std.io).
 * Макрос:
 *	WIKI=Phobos/StdStdio
 */

module std.io;

import cidrus;
import std.format;
import std.utf;
import std.string;
import runtime;
//public import rt.console;


version (DigitalMars)
{
    version (Windows)
    {
	// Specific to the way Digital Mars C does stdio
	version = DIGITAL_MARS_STDIO;
    }
}

version (linux)
{
    // Specific to the way Gnu C does stdio
    version = GCC_IO;
    import os.linux;
}

version (OSX)
{
    version = GENERIC_IO;
}

version (FreeBSD)
{
    version = GENERIC_IO;
}

version (Solaris)
{
    version = GENERIC_IO;
}

version (DIGITAL_MARS_STDIO)
{
     extern  (C) 
	 
    {
	;
	/* **
	 * Digital Mars under-the-hood C I/O functions
	 */
	int _fputc_nlock(int, фук);
	int _fputwc_nlock(int, фук);
	int _fgetc_nlock(фук);
	int _fgetwc_nlock(фук);
	int __fp_lock(фук);
	void __fp_unlock(фук);
    }
    alias _fputc_nlock FPUTC;
    alias _fputwc_nlock FPUTWC;
    alias _fgetc_nlock FGETC;
    alias _fgetwc_nlock FGETWC;

    alias __fp_lock FLOCK;
    alias __fp_unlock FUNLOCK;
	
	alias FPUTC ФПОМЕСТС;
	alias FPUTWC ФПОМЕСТШ;
	alias FGETC ФИЗВЛС;
	alias FGETWC ФИЗВЛШ;
	alias FLOCK ФБЛОК;
	alias FUNLOCK ФРБЛОК;
}
else version (GCC_IO)
{
    /* **
     * Gnu under-the-hood C I/O functions; see
     * http://www.gnu.org/software/libc/manual/html_node/I_002fO-on-Streams.html#I_002fO-on-Streams
     */
    extern  (C)
    {
	int fputc_unlocked(int, фук);
	int fputwc_unlocked(wchar_t, фук);
	int fgetc_unlocked(фук);
	int fgetwc_unlocked(фук);
	void flockfile(фук);
	void funlockfile(фук);
	ssize_t getline(char**, size_t*, фук);
	ssize_t getdelim (char**, size_t*, int, фук);
    }

    alias fputc_unlocked FPUTC;
    alias fputwc_unlocked FPUTWC;
    alias fgetc_unlocked FGETC;
    alias fgetwc_unlocked FGETWC;

    alias flockfile FLOCK;
    alias funlockfile FUNLOCK;
}
else version (GENERIC_IO)
{
    extern  (C)
    {
	void flockfile(фук);
	void funlockfile(фук);
    }

    alias fputc FPUTC;
    alias fputwc FPUTWC;
    alias fgetc FGETC;
    alias fgetwc FGETWC;

    alias flockfile FLOCK;
    alias funlockfile FUNLOCK;
}
else
{
    static assert(0, "unsupported C I/O system");
}

alias readln читайнс;
//alias FILE ФАЙЛ;
alias fwritefln фпишифнс;
alias fwritef фпишиф;
alias writefln пишифнс;
alias writef пишиф;
alias ИсклСтдВВ ВВИскл;

/*********************
 * Выводится при ошибке I/O.
 */


class ИсклСтдВВ : Exception
{

    uint errno;			// operating system error code

    this(string msg)
    {
	super(msg);
    }

    this(uint errno)
    {
	version (Posix)
	{   char[80] buf = void;
	    auto s = cidrus.strerror_r(errno, buf.ptr, buf.length);
	}
	else
	{
	    auto s = cidrus.строшиб(errno);
	}
	super(s.dup);
    }

    static void opCall(string msg)
    {
	throw new ИсклСтдВВ(msg);
    }

    static void opCall()
    {
	throw new ИсклСтдВВ("Ошибка при оперирование вводом-выводом");
    }
}

//private
void writefx(фук fp, TypeInfo[] arguments, void* argptr, int newline=false)
{
    int orientation = fwide(cast(фук)fp, 0);

    /* Do the file stream locking at the outermost level
     * rather than character by character.
     */
    FLOCK(fp);
    scope(exit) FUNLOCK(fp);

    if (orientation <= 0)		// byte orientation or no orientation
    {
	void putc(dchar c)
	{
	    if (c <= 0x7F)
	    {
		FPUTC(c, fp);
	    }
	    else
	    {   char[4] buf;
		auto b = std.utf.toUTF8(buf, c);
		for (size_t i = 0; i < b.length; i++)
		    FPUTC(b[i], fp);
	    }
	}

	std.format.doFormat(&putc, arguments, argptr);
	if (newline)
	    FPUTC('\n', fp);
    }
    else if (orientation > 0)		// wide orientation
    {
	version (Windows)
	{
	    void putcw(dchar c)
	    {
		assert(isValidDchar(c));
		if (c <= 0xFFFF)
		{
		    FPUTWC(c, fp);
		}
		else
		{   wchar[2] buf;

		    buf[0] = cast(wchar) ((((c - 0x10000) >> 10) & 0x3FF) + 0xD800);
		    buf[1] = cast(wchar) (((c - 0x10000) & 0x3FF) + 0xDC00);
		    FPUTWC(buf[0], fp);
		    FPUTWC(buf[1], fp);
		}
	    }
	}
	else version (Posix)
	{
	    void putcw(dchar c)
	    {
		FPUTWC(c, fp);
	    }
	}
	else
	{
	    static assert(0);
	}

	std.format.doFormat(&putcw, arguments, argptr);
	if (newline)
	    FPUTWC('\n', fp);
    }
}


/***********************************
 * Arguments are formatted per the
 * $(LINK2 std_format.html#format-string, format strings)
 * and written to $(B stdout).
 */

void writef(...)
{
    writefx(cidrus.stdout, _arguments, _argptr, 0);
}

/***********************************
 * То же, что и $(B writef), но к выводу добавляется
 * символ новой строки.
 */

void writefln(...)
{
    writefx(cidrus.stdout, _arguments, _argptr, 1);
}

/***********************************
 * Same as $(B writef), but output is sent to the
 * stream fp instead of $(B stdout).
 */

void fwritef(фук fp, ...)
{
    writefx(fp, _arguments, _argptr, 0);
}

/***********************************
 * Same as $(B writefln), but output is sent to the
 * stream fp instead of $(B stdout).
 */

void fwritefln(фук fp, ...)
{
    writefx(fp, _arguments, _argptr, 1);
}

/**********************************
 * Read line from stream fp.
 * Возвращает:
 *	null for end of file,
 *	ткст for line read from fp, including terminating '\n'
 * Параметры:
 *	fp = input stream
 * Выводит исключение:
 *	$(B ИсклСтдВВ) on error
 * Пример:
 *	Reads $(B stdin) and writes it to $(B stdout).
---
import std.io;

int main()
{
    ткст buf;
    while ((buf = readln()) != null)
	writef("%s", buf);
    return 0;
}
---
 */
string readln(фук fp = cast(фук) cidrus.стдвхо)
{
    ткст buf;
    readln(fp, buf);
    return buf;
}

/**********************************
 * Read line from stream fp and write it to buf[],
 * including terminating '\n'.
 *
 * This is often faster than readln(фук) because the buffer
 * is reused each call. Note that reusing the buffer means that
 * the previous contents of it need to be copied if needed.
 * Параметры:
 *	fp = input stream
 *	buf = buffer used to store the resulting line data. buf
 *		is resized as necessary.
 * Возвращает:
 *	0 for end of file, otherwise
 *	number of characters read
 * Выводит исключение:
 *	$(B ИсклСтдВВ) on error
 * Пример:
 *	Reads $(B stdin) and writes it to $(B stdout).
---
import std.io;

int main()
{
    ткст buf;
    while (readln(stdin, buf))
	writef("%s", buf);
    return 0;
}
---
 */
version = DIGITAL_MARS_STDIO;

size_t readln(фук fp, inout ткст buf)
{
    version (DIGITAL_MARS_STDIO)
    {
	FLOCK(fp);
	
	scope(exit) {
	try	{FUNLOCK(fp);
	}
	finally{}
	}
	 //char[] buf = rt.charset.fromMBSz(char* inbuf, 0);

	if (__fhnd_info[fp._file] & ФУК_ШИМ)
	{   /* Stream is in wide characters.
	     * Read them and convert to chars.
	     */
		    static assert(wchar_t.sizeof == 2);
	    buf.length = 0;
	    int c2;
	    for (int c = void; (c = FGETWC(fp)) != -1; )
	    {
		if ((c & ~0x7F) == 0)
		{   buf ~= c;
		    if (c == '\r'||c == '\n')
			break;
		}
		else
		{
		    if (c >= 0xD800 && c <= 0xDBFF)
		    {
			if ((c2 = FGETWC(fp)) != -1 ||
			    c2 < 0xDC00 && c2 > 0xDFFF)
			{
			    ИсклСтдВВ("беспарный суррогат UTF-16");
			}
			c = ((c - 0xD7C0) << 10) + (c2 - 0xDC00);
		    }
		    std.utf.encode(buf, c);
		}
	    }
	    if (ошфл(cast(фук) fp))
		ИсклСтдВВ("ошибка FGETWC при чтении шткст");
	    return buf.length;
	}

	auto разм = runtime.capacity(buf.ptr);
	//auto разм = buf.length;
	buf = buf.ptr[0 .. разм];
	if (fp._flag & ВВНБФ)
	{
	    /* Use this for unbuffered I/O, when running
	     * across buffer boundaries, or for any but the common
	     * cases.
	     */
	 L1:
	    char *p;

	    if (разм)
	    {
		p = buf.ptr;
	    }
	    else
	    {
		разм = 64;
		p = cast(char*) runtime.malloc(разм);
		runtime.hasNoPointers(p);
		buf = p[0 .. разм];
	    }
	    size_t i = 0;
	    for (int c; (c = FGETC(fp)) != -1; )
	    {
		if ((p[i] = cast(char)c) != '\n')
		{
		    i++;
		    if (i < разм)
			continue;
		    buf = p[0 .. i] ~ readln(fp);
		    return buf.length;
		}
		else
		{
		    buf = p[0 .. i + 1];
		    return i + 1;
		}
	    }
	    if (ошфл(cast(фук) fp))
		ИсклСтдВВ("ошибка FGETC при чтении ткст");
	    buf = p[0 .. i];
	    return i;
	}
	else
	{
	    int u = fp._cnt;
	    char* p = fp._ptr;
	    int i;
	    if (fp._flag & ВВТРАН)
	    {   /* Translated mode ignores \r and treats ^Z as end-of-file
		 */
		char c;
		while (1)
		{
		    if (i == u)		// if end of buffer
			goto L1;	// give up
		    c = p[i];
		    i++;
		    if (c != '\r')
		    {
			if (c == '\n')
			    break;
			if (c != 0x1A)
			    continue;
			goto L1;
		    }
		    else
		    {   if (i != u && p[i] == '\n')
			    break;
			goto L1;
		    }
		}
		if (i > разм)
		{
		    buf = cast(char[])runtime.malloc(i);
		    runtime.hasNoPointers(buf.ptr);
		}
		if (i - 1)
		    cidrus.memcpy(buf.ptr, p, i - 1);
		buf[i - 1] = '\n';
		if (c == '\r')
		    i++;
	    }
	    else
	    {
		while (1)
		{
		    if (i == u)		// if end of buffer
			goto L1;	// give up
		    auto c = p[i];
		    i++;
		    if (c == '\n')
			break;
		}
		if (i > разм)
		{
		    buf = cast(char[])runtime.malloc(i);
		    runtime.hasNoPointers(buf.ptr);
		}
		cidrus.memcpy(buf.ptr, p, i);
	    }
	    fp._cnt -= i;
	    fp._ptr += i;
	    buf = buf[0 .. i];
	    return i;
	}
    }
    else version (GCC_IO)
    {
	if (fwide(fp, 0) > 0)
	{   /* Stream is in wide characters.
	     * Read them and convert to chars.
	     */
	    FLOCK(fp);
	    scope(exit) FUNLOCK(fp);
	    version (Windows)
	    {
		buf.length = 0;
		int c2;
		for (int c = void; (c = FGETWC(fp)) != -1; )
		{
		    if ((c & ~0x7F) == 0)
		    {   buf ~= c;
			if (c == '\n')
			    break;
		    }
		    else
		    {
			if (c >= 0xD800 && c <= 0xDBFF)
			{
			    if ((c2 = FGETWC(fp)) != -1 ||
				c2 < 0xDC00 && c2 > 0xDFFF)
			    {
				ИсклСтдВВ("беспарный суррогат UTF-16");
			    }
			    c = ((c - 0xD7C0) << 10) + (c2 - 0xDC00);
			}
			std.utf.encode(buf, c);
		    }
		}
		if (ошфл(fp))
		    ИсклСтдВВ();
		return buf.length;
	    }
	    else version (Posix)
	    {
		buf.length = 0;
		for (int c; (c = FGETWC(fp)) != -1; )
		{
		    if ((c & ~0x7F) == 0)
			buf ~= c;
		    else
			std.utf.encode(buf, cast(dchar)c);
		    if (c == '\n')
			break;
		}
		if (ошфл(fp))
		    ИсклСтдВВ();
		return buf.length;
	    }
	    else
	    {
		static assert(0);
	    }
	}

	char *lineptr = null;
	size_t n = 0;
	auto s = getdelim(&lineptr, &n, '\n', fp);
	scope(exit) free(lineptr);
	if (s < 0)
	{
	    if (ошфл(fp))
		ИсклСтдВВ();
	    buf.length = 0;		// end of file
	    return 0;
	}
	buf = buf.ptr[0 .. runtime.capacity(buf.ptr)];
	if (s <= buf.length)
	{
	    buf.length = s;
	    buf[] = lineptr[0 .. s];
	}
	else
	{
	    buf = lineptr[0 .. s].dup;
	}
	return s;
    }
    else version (GENERIC_IO)
    {
	FLOCK(fp);
	scope(exit) FUNLOCK(fp);
	if (fwide(fp, 0) > 0)
	{   /* Stream is in wide characters.
	     * Read them and convert to chars.
	     */
	    version (Windows)
	    {
		buf.length = 0;
		int c2;
		for (int c; (c = FGETWC(fp)) != -1; )
		{
		    if ((c & ~0x7F) == 0)
		    {   buf ~= c;
			if (c == '\n')
			    break;
		    }
		    else
		    {
			if (c >= 0xD800 && c <= 0xDBFF)
			{
			    if ((c2 = FGETWC(fp)) != -1 ||
				c2 < 0xDC00 && c2 > 0xDFFF)
			    {
				ИсклСтдВВ("беспарный суррогат UTF-16");
			    }
			    c = ((c - 0xD7C0) << 10) + (c2 - 0xDC00);
			}
			std.utf.encode(buf, c);
		    }
		}
		if (ошфл(fp))
		    ИсклСтдВВ("Ошибка 2 FGETWC");
		return buf.length;
	    }
	    else version (Posix)
	    {
		buf.length = 0;
		for (int c; (c = FGETWC(fp)) != -1; )
		{
		    if ((c & ~0x7F) == 0)
			buf ~= c;
		    else
			std.utf.encode(buf, cast(dchar)c);
		    if (c == '\n')
			break;
		}
		if (ошфл(fp))
		    ИсклСтдВВ();
		return buf.length;
	    }
	    else
	    {
		static assert(0);
	    }
	}

	buf.length = 0;
	for (int c; (c = FGETC(fp)) != -1; )
	{
	    buf ~= c;
	    if (c == '\n')
		break;
	}
	if (ошфл(fp))
	    ИсклСтдВВ();
	return buf.length;
    }
    else
    {
	static assert(0);
    }
}

/** ditto */
size_t readln(inout ткст buf)
{
    return readln(cidrus.stdin, buf);
}
