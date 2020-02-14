// Написано на языке программирования Динрус. Разработчик Виталий Кулич.


module std.file;

//public import rt.console;


private import cidrus, exception:ФайлИскл, СисОш;
private import std.path;
private import std.string;
private import std.regexp;
private import runtime;

/* =========================== Win32 ======================= */

version (Win32)
{

private import sys.WinFuncs;
private import std.utf;
private import rt.syserror;
private import rt.charset;
private import std.date;

alias rt.charset.toMBSz toMBSz;

int useWfuncs = 1;

//extern(C) int      wcscmp(in wchar_t* s1, in wchar_t* s2);

static this()
{
    // Win 95, 98, ME do not implement the W functions
    useWfuncs = (GetVersion() < 0x80000000);
}

  alias read читай;
  alias write пиши;
  alias append допиши;
   alias rename переименуй;
    alias remove удали;
	alias getSize дайРазмер;
	alias getTimes дайВремя;
	 alias exists есть_ли;
	 alias getAttributes дайАтры;
	  alias isfile файл_ли;
	  alias isdir папка_ли;
	  alias chdir сменипап;
	  alias mkdir сделпап;
	  alias rmdir удалипап;
	  alias getcwd дайтекпап;
	  alias listdir списпап;
	  alias toMBSz вМбс0;
	  alias copy копируй;

/********************************************
 * Read file name[], return array of bytes read.
 * Throws:
 *	ФайлИскл on error.
 */

void[] read(char[] name)
{
    DWORD numread;
    HANDLE h;

    if (useWfuncs)
    {
	wchar* namez = std.utf.toUTF16z(name);
	h = CreateFileW(namez,ППраваДоступа.ГенерноеЧтение,ПФайл.СЧ,null,ПРежСоздФайла.ОткрытьСущ,
	    ПФайл.Нормальный | ПФайл.ПоследоватСкан,cast(HANDLE)null);
    }
    else
    {
	char* namez = toMBSz(name);
	h = CreateFileA(namez,ППраваДоступа.ГенерноеЧтение,ПФайл.СЧ,null,ПРежСоздФайла.ОткрытьСущ,
	    ПФайл.Нормальный | ПФайл.ПоследоватСкан,cast(HANDLE)null);
    }

    if (h == cast(HANDLE) НЕВЕРНХЭНДЛ)
	goto err1;

    auto size = GetFileSize(h, null);
    if (size == НЕВЕРНРАЗМФАЙЛА)
	goto err2;

    auto buf = runtime.malloc(size);
    if (buf)
	runtime.hasNoPointers(buf.ptr);

    if (ReadFile(h,buf.ptr,size,&numread,null) != 1)
	goto err2;

    if (numread != size)
	goto err2;

    if (!CloseHandle(h))
	goto err;

    return buf[0 .. size];

err2:
    CloseHandle(h);
err:
    delete buf;
err1:
    throw new ФайлИскл(name, GetLastError());
}

/*********************************************
 * Write buffer[] to file name[].
 * Throws: ФайлИскл on error.
 */

void write(char[] name, void[] buffer)
{
    HANDLE h;
    DWORD numwritten;

    if (useWfuncs)
    {
	wchar* namez = std.utf.toUTF16z(name);
	h = CreateFileW(namez,ППраваДоступа.ГенернаяЗапись,0,null,ПРежСоздФайла.СоздатьВсегда,
	    ПФайл.Нормальный | ПФайл.ПоследоватСкан,cast(HANDLE)null);
    }
    else
    {
	char* namez = toMBSz(name);
	h = CreateFileA(namez,ППраваДоступа.ГенернаяЗапись,0,null,ПРежСоздФайла.СоздатьВсегда,
	    ПФайл.Нормальный | ПФайл.ПоследоватСкан,cast(sys.WinFuncs.HANDLE)null);
    }
    if (h == cast(HANDLE) НЕВЕРНХЭНДЛ)
	goto err;

    if (sys.WinFuncs.WriteFile(h,buffer.ptr,buffer.length,&numwritten,null) != 1)
	goto err2;

    if (buffer.length != numwritten)
	goto err2;

    if (!CloseHandle(h))
	goto err;
    return;

err2:
    CloseHandle(h);
err:
    throw new ФайлИскл(name, GetLastError());
}


/*********************************************
 * Append buffer[] to file name[].
 * Throws: ФайлИскл on error.
 */

void append(char[] name, void[] buffer)
{
    HANDLE h;
    DWORD numwritten;

    if (useWfuncs)
    {
	wchar* namez = std.utf.toUTF16z(name);
	h = CreateFileW(namez,ППраваДоступа.ГенернаяЗапись,0,null,ПРежСоздФайла.ОткрытьВсегда,
	    ПФайл.Нормальный | ПФайл.ПоследоватСкан,cast(HANDLE)null);
    }
    else
    {
	char* namez = toMBSz(name);
	h = CreateFileA(namez,ППраваДоступа.ГенернаяЗапись,0,null,ПРежСоздФайла.ОткрытьВсегда,
	    ПФайл.Нормальный | ПФайл.ПоследоватСкан,cast(sys.WinFuncs.HANDLE)null);
    }
    if (h == cast(HANDLE) НЕВЕРНХЭНДЛ)
	goto err;

    SetFilePointer(h, 0, null, ПФайл.Кон);

    if (sys.WinFuncs.WriteFile(h,buffer.ptr,buffer.length,&numwritten,null) != 1)
	goto err2;

    if (buffer.length != numwritten)
	goto err2;

    if (!CloseHandle(h))
	goto err;
    return;

err2:
    CloseHandle(h);
err:
    throw new ФайлИскл(name, GetLastError());
}


/***************************************************
 * Rename file from[] to to[].
 * Throws: ФайлИскл on error.
 */

void rename(char[] from, char[] to)
{
    BOOL результат;

    if (useWfuncs)
	результат = MoveFileW(std.utf.toUTF16z(from), std.utf.toUTF16z(to));
    else
	результат = MoveFileA(toMBSz(from), toMBSz(to));
    if (!результат)
	throw new ФайлИскл(to, GetLastError());
}


/***************************************************
 * Delete file name[].
 * Throws: ФайлИскл on error.
 */

void remove(char[] name)
{
    BOOL результат;

    if (useWfuncs)
	результат = УдалиФайл(name);
    else
	результат = УдалиФайлА(name);
    if (!результат)
	throw new ФайлИскл(name, GetLastError());
}


/***************************************************
 * Get size of file name[].
 * Throws: ФайлИскл on error.
 */

ulong getSize(char[] name)
{
    HANDLE findhndl;
    uint resulth;
    uint resultl;

    if (useWfuncs)
    {
	WIN32_FIND_DATAW filefindbuf;

	findhndl = FindFirstFileW(std.utf.toUTF16z(name), &filefindbuf);
	resulth = filefindbuf.nFileSizeHigh;
	resultl = filefindbuf.nFileSizeLow;
    }
    else
    {
	WIN32_FIND_DATA filefindbuf;

	findhndl = FindFirstFileA(toMBSz(name), &filefindbuf);
	resulth = filefindbuf.nFileSizeHigh;
	resultl = filefindbuf.nFileSizeLow;
    }

    if (findhndl == cast(HANDLE)-1)
    {
	throw new ФайлИскл(name, GetLastError());
    }
    FindClose(findhndl);
    return (cast(ulong)resulth << 32) + resultl;
}

/*************************
 * Get creation/access/modified times of file name[].
 * Throws: ФайлИскл on error.
 */

void getTimes(char[] name, out d_time ftc, out d_time fta, out d_time ftm)
{
    HANDLE findhndl;

    if (useWfuncs)
    {
	ПДАН filefindbuf;

	findhndl = НайдиПервыйФайл(std.utf.toUTF16(name), &filefindbuf);
	ftc = std.date.FILETIME2d_time(&filefindbuf.времяСоздания);
	fta = std.date.FILETIME2d_time(&filefindbuf.времяПоследнегоДоступа);
	ftm = std.date.FILETIME2d_time(&filefindbuf.времяПоследнейЗаписи);
    }
    else
    {
	ПДАН_А filefindbuf;

	findhndl = НайдиПервыйФайлА(name, &filefindbuf);
	ftc = std.date.FILETIME2d_time(&filefindbuf.времяСоздания);
	fta = std.date.FILETIME2d_time(&filefindbuf.времяПоследнегоДоступа);
	ftm = std.date.FILETIME2d_time(&filefindbuf.времяПоследнейЗаписи);
    }

    if (findhndl == cast(ук)-1)
    {
	throw new ФайлИскл(name, ДайПоследнююОшибку());
    }
    НайдиЗакрой(findhndl);
}


/***************************************************
 * Does file name[] (or directory) exist?
 * Return 1 if it does, 0 if not.
 */

int exists(char[] name)
{
    uint результат;

    if (useWfuncs)
	// http://msdn.microsoft.com/library/default.asp?url=/library/en-us/fileio/base/getfileattributes.asp
	результат = GetFileAttributesW(std.utf.toUTF16z(name));
    else
	результат = GetFileAttributesA(toMBSz(name));

    return результат != 0xFFFFFFFF;
}

/***************************************************
 * Get file name[] attributes.
 * Throws: ФайлИскл on error.
 */

uint getAttributes(string name)
{
    uint результат;

    if (useWfuncs)
	результат = GetFileAttributesW(std.utf.toUTF16z(name));
    else
	результат = GetFileAttributesA(toMBSz(name));
    if (результат == 0xFFFFFFFF)
    {
	throw new ФайлИскл(name, GetLastError());
    }
    return результат;
}

/****************************************************
 * Is name[] a file?
 * Throws: ФайлИскл if name[] doesn't exist.
 */

int isfile(char[] name)
{
    return (getAttributes(name) & ПФайл.Папка) == 0;
}

/****************************************************
 * Is name[] a directory?
 * Throws: ФайлИскл if name[] doesn't exist.
 */

int isdir(char[] name)
{
    return (getAttributes(name) & ПФайл.Папка) != 0;
}

/****************************************************
 * Change directory to pathname[].
 * Throws: ФайлИскл on error.
 */

void chdir(char[] pathname)
{   BOOL результат;

    if (useWfuncs)
	результат = SetCurrentDirectoryW(std.utf.toUTF16z(pathname));
    else
	результат = SetCurrentDirectoryA(toMBSz(pathname));

    if (!результат)
    {
	throw new ФайлИскл(pathname, GetLastError());
    }
}

/****************************************************
 * Make directory pathname[].
 * Throws: ФайлИскл on error.
 */

void mkdir(char[] pathname)
{   BOOL результат;

    if (useWfuncs)
	результат = CreateDirectoryW(std.utf.toUTF16z(pathname), null);
    else
	результат = CreateDirectoryA(toMBSz(pathname), null);

    if (!результат)
    {
	throw new ФайлИскл(pathname, GetLastError());
    }
}

/****************************************************
 * Remove directory pathname[].
 * Throws: ФайлИскл on error.
 */

void rmdir(char[] pathname)
{   BOOL результат;

    if (useWfuncs)
	результат = RemoveDirectoryW(std.utf.toUTF16z(pathname));
    else
	результат = RemoveDirectoryA(toMBSz(pathname));

    if (!результат)
    {
	throw new ФайлИскл(pathname, GetLastError());
    }
}

/****************************************************
 * Get current directory.
 * Throws: ФайлИскл on error.
 */

char[] getcwd()
{
    if (useWfuncs)
    {
	wchar c;

	auto len = GetCurrentDirectoryW(0, &c);
	if (!len)
	    goto Lerr;
	auto dir = new wchar[len];
	len = GetCurrentDirectoryW(len, dir.ptr);
	if (!len)
	    goto Lerr;
	return std.utf.toUTF8(dir[0 .. len]); // leave off terminating 0
    }
    else
    {
	char c;

	auto len = GetCurrentDirectoryA(0, &c);
	if (!len)
	    goto Lerr;
	auto dir = new char[len];
	len = GetCurrentDirectoryA(len, dir.ptr);
	if (!len)
	    goto Lerr;
	return dir[0 .. len];		// leave off terminating 0
    }

Lerr:
    throw new ФайлИскл("getcwd", GetLastError());
}

/***************************************************
 * Directory Entry
 */

struct DirEntry
{


	alias name имя;	
	alias size размер;
	alias creationTime датаСозд;	
	alias lastAccessTime последВремяДост;
	alias lastWriteTime последнВремяЗап;
	alias attributes атрибуты;	
	alias init иниц;
	alias isdir папка_ли;  
	alias isfile файл_ли;
	
    string name;			/// file or directory name
    ulong size = ~0UL;			/// size of file in bytes
    d_time creationTime = d_time_nan;	/// time of file creation
    d_time lastAccessTime = d_time_nan;	/// time file was last accessed
    d_time lastWriteTime = d_time_nan;	/// time file was last written to
    uint attributes;		// Windows file attributes OR'd together

    void init(string path, ПДАН_А *fd)
    {
	wchar[] wbuf;
	size_t clength;
	size_t wlength;
	size_t n;

	clength = cidrus.strlen(fd.имяФайла.ptr);

	// Convert cFileName[] to unicode
	wlength = sys.WinFuncs.MultiByteToWideChar(0,0,fd.имяФайла.ptr,clength,null,0);
	if (wlength > wbuf.length)
	    wbuf.length = wlength;
	n = sys.WinFuncs.MultiByteToWideChar(0,0,fd.имяФайла.ptr,clength,cast(wchar*)wbuf,wlength);
	assert(n == wlength);
	// toUTF8() returns a new buffer
	name = std.path.join(path, std.utf.toUTF8(wbuf[0 .. wlength]));

	size = (cast(ulong)fd.размерФайлаВ << 32) | fd.размерФайлаН;
	creationTime = std.date.FILETIME2d_time(&fd.времяСоздания);
	lastAccessTime = std.date.FILETIME2d_time(&fd.времяПоследнегоДоступа);
	lastWriteTime = std.date.FILETIME2d_time(&fd.времяПоследнейЗаписи);
	attributes = fd.атрибутыФайла;
    }

    void init(string path, ПДАН *fd)
    {
	size_t clength = wcslen(fd.имяФайла.ptr);
	name = std.path.join(path, std.utf.toUTF8(fd.имяФайла[0 .. clength]));
	size = (cast(ulong)fd.размерФайлаВ << 32) | fd.размерФайлаН;
	creationTime = std.date.FILETIME2d_time(&fd.времяСоздания);
	lastAccessTime = std.date.FILETIME2d_time(&fd.времяПоследнегоДоступа);
	lastWriteTime = std.date.FILETIME2d_time(&fd.времяПоследнейЗаписи);
	attributes = fd.атрибутыФайла;
    }

    /****
     * Return !=0 if DirEntry is a directory.
     */
    uint isdir()
    {
	return attributes & ПФайл.Папка;
    }

    /****
     * Return !=0 if DirEntry is a file.
     */
    uint isfile()
    {
	return !(attributes & ПФайл.Папка);
    }
}


/***************************************************
 * Return contents of directory pathname[].
 * The names in the contents do not include the pathname.
 * Throws: ФайлИскл on error
 * Example:
 *	This program lists all the files and subdirectories in its
 *	path argument.
 * ----
 * import std.io;
 * import std.file;
 *
 * void main(string[] args)
 * {
 *    auto dirs = listdir(args[1]);
 *
 *    foreach (d; dirs)
 *	writefln(d);
 * }
 * ----
 */

string[] listdir(string pathname)
{
    string[] результат;

    bool listing(string filename)
    {
	результат ~= filename;
	return true; // continue
    }

    listdir(pathname, &listing);
    return результат;
}


/*****************************************************
 * Return all the files in the directory and its subdirectories
 * that match pattern or regular expression r.
 * Параметры:
 *	pathname = Directory name
 *	pattern = String with wildcards, such as $(RED "*.d"). The supported
 *		wildcard strings are described under fnmatch() in
 *		$(LINK2 std_path.html, std.path).
 *	r = Regular expression, for more powerful _pattern matching.
 * Example:
 *	This program lists all the files with a "d" extension in
 *	the path passed as the first argument.
 * ----
 * import std.io;
 * import std.file;
 *
 * void main(string[] args)
 * {
 *    auto d_source_files = listdir(args[1], "*.d");
 *
 *    foreach (d; d_source_files)
 *	writefln(d);
 * }
 * ----
 * A regular expression version that searches for all files with "d" or
 * "объ" extensions:
 * ----
 * import std.io;
 * import std.file;
 * import std.regexp;
 *
 * void main(string[] args)
 * {
 *    auto d_source_files = listdir(args[1], RegExp(r"\.(d|объ)$"));
 *
 *    foreach (d; d_source_files)
 *	writefln(d);
 * }
 * ----
 */

string[] listdir(string pathname, string pattern)
{   string[] результат;

    bool callback(DirEntry* de)
    {
	if (de.isdir)
	    listdir(de.name, &callback);
	else
	{   if (std.path.fnmatch(de.name, pattern))
		результат ~= de.name;
	}
	return true; // continue
    }

    listdir(pathname, &callback);
    return результат;
}

/** Ditto */

string[] listdir(string pathname, RegExp r)
{   string[] результат;

    bool callback(DirEntry* de)
    {
	if (de.isdir)
	    listdir(de.name, &callback);
	else
	{   if (r.test(de.name))
		результат ~= de.name;
	}
	return true; // continue
    }

    listdir(pathname, &callback);
    return результат;
}

/******************************************************
 * For each file and directory name in pathname[],
 * pass it to the callback delegate.
 * Параметры:
 *	callback =	Delegate that processes each
 *			filename in turn. Returns true to
 *			continue, false to stop.
 * Example:
 *	This program lists all the files in its
 *	path argument, including the path.
 * ----
 * import std.io;
 * import std.path;
 * import std.file;
 *
 * void main(string[] args)
 * {
 *    auto pathname = args[1];
 *    string[] результат;
 *
 *    bool listing(string filename)
 *    {
 *      результат ~= std.path.join(pathname, filename);
 *      return true; // continue
 *    }
 *
 *    listdir(pathname, &listing);
 *
 *    foreach (name; результат)
 *      writefln("%s", name);
 * }
 * ----
 */

void listdir(string pathname, bool delegate(string filename) callback)
{
    bool listing(DirEntry* de)
    {
	return callback(std.path.getBaseName(de.name));
    }

    listdir(pathname, &listing);
}

/******************************************************
 * For each file and directory DirEntry in pathname[],
 * pass it to the callback delegate.
 * Параметры:
 *	callback =	Delegate that processes each
 *			DirEntry in turn. Returns true to
 *			continue, false to stop.
 * Example:
 *	This program lists all the files in its
 *	path argument and all subdirectories thereof.
 * ----
 * import std.io;
 * import std.file;
 *
 * void main(string[] args)
 * {
 *    bool callback(DirEntry* de)
 *    {
 *      if (de.isdir)
 *        listdir(de.name, &callback);
 *      else
 *        writefln(de.name);
 *      return true;
 *    }
 *
 *    listdir(args[1], &callback);
 * }
 * ----
 */

void listdir(string pathname, bool delegate(DirEntry* de) callback)
{
    string c;
    ук h;
    DirEntry de;

    c = std.path.join(pathname, "*.*");
    if (useWfuncs)
    {
	ПДАН fileinfo;

	h = НайдиПервыйФайл(std.utf.toUTF16(c), &fileinfo);
	if (h != cast(ук) НЕВЕРНХЭНДЛ)
	{
	    try
	    {
		do
		{
		    // Skip "." and ".."
		    if (wcscmp(fileinfo.имяФайла.ptr, ".") == 0 ||
			wcscmp(fileinfo.имяФайла.ptr, "..") == 0)
			continue;

		    de.init(pathname, &fileinfo);
		    if (!callback(&de))
			break;
		} while (НайдиСледующийФайл(cast(ук)h,&fileinfo) != ЛОЖЬ);
	    }
	    finally
	    {
		НайдиЗакрой(h);
	    }
	}
    }
    else
    {
	ПДАН_А fileinfo;

	h = НайдиПервыйФайлА(c, &fileinfo);
	if (h != cast(ук) НЕВЕРНХЭНДЛ)	// should we throw exception if invalid?
	{
	    try
	    {
		do
		{
		    // Skip "." and ".."
		    if (cidrus.strcmp(fileinfo.имяФайла.ptr, ".") == 0 ||
			cidrus.strcmp(fileinfo.имяФайла.ptr, "..") == 0)
			continue;

		    de.init(pathname, &fileinfo);
		    if (!callback(&de))
			break;
		} while (НайдиСледующийФайлА(h,&fileinfo) != ЛОЖЬ);
	    }
	    finally
	    {
		НайдиЗакрой(h);
	    }
	}
    }
}

void copy(string from, string to)
{
    BOOL результат;

    if (useWfuncs)
	результат = CopyFileW(std.utf.toUTF16z(from), std.utf.toUTF16z(to), false);
    else
	результат = CopyFileA(toMBSz(from), toMBSz(to), false);
    if (!результат)
         throw new ФайлИскл(to, GetLastError());
}


}

/* =========================== Posix ======================= */

version (Posix)
{

private import std.date;
private import os.posix;
private import cidrus;

/***********************************
 */

class ФайлИскл : Exception
{
    uint errno;			// operating system error code

    this(string name)
    {
	this(name, "ввод-вывод файла");
    }

    this(string name, string message)
    {
	super(name ~ ": " ~ message);
    }

    this(string name, uint errno)
    {
        char[1024] buf = void;
	auto s = strerror_r(errno, buf.ptr, buf.length);
	this(name, std.string.toString(s).dup);
	this.errno = errno;
    }
}

/********************************************
 * Read a file.
 * Returns:
 *	array of bytes read
 */

void[] read(string name)
{
    struct_stat statbuf;

    auto namez = toStringz(name);
    //эхо("file.read('%s')\n",namez);
    auto fd = os.posix.open(namez, O_RDONLY);
    if (fd == -1)
    {
        //эхо("\topen error, errno = %d\n",getErrno());
        goto err1;
    }

    //эхо("\tfile opened\n");
    if (os.posix.fstat(fd, &statbuf))
    {
        //эхо("\tfstat error, errno = %d\n",getErrno());
        goto err2;
    }
    auto size = statbuf.st_size;
    if (size > int.max)
	goto err2;

    void[] buf;
    if (size == 0)
    {	/* The size could be 0 if the file is a device or a procFS file,
	 * so we just have to try reading it.
	 */
	int readsize = 1024;
	while (1)
	{
	    buf = runtime.realloc(buf.ptr, cast(int)size + readsize);

	    auto toread = readsize;
	    while (toread)
	    {
		auto numread = os.posix.read(fd, buf.ptr + size, toread);
		if (numread == -1)
		    goto err2;
		size += numread;
		if (numread == 0)
		{   if (size == 0)			// it really was 0 size
			delete buf;			// don't need the buffer
		    else
			runtime.hasNoPointers(buf.ptr);
		    goto Leof;				// end of file
		}
		toread -= numread;
	    }
	}
    }
    else
    {
	buf = runtime.malloc(cast(int)size);
	if (buf.ptr)
	    runtime.hasNoPointers(buf.ptr);

	auto numread = os.posix.read(fd, buf.ptr, cast(int)size);
	if (numread != size)
	{
	    //эхо("\tread error, errno = %d\n",getErrno());
	    goto err2;
	}
    }

  Leof:
    if (os.posix.close(fd) == -1)
    {
	//эхо("\tclose error, errno = %d\n",getErrno());
        goto err;
    }

    return buf[0 .. cast(size_t)size];

err2:
    os.posix.close(fd);
err:
    delete buf;

err1:
    throw new ФайлИскл(name, getErrno());
}

unittest
{
    version (linux)
    {	// A file with "zero" length that doesn't have 0 length at all
	char[] s = cast(char[])read("/proc/sys/kernel/osrelease");
	assert(s.length > 0);
	//writefln("'%s'", s);
    }
}

/*********************************************
 * Write a file.
 */

void write(string name, void[] buffer)
{
    int fd;
    int numwritten;
    char *namez;

    namez = toStringz(name);
    fd = os.posix.open(namez, O_CREAT | O_WRONLY | O_TRUNC, 0660);
    if (fd == -1)
        goto err;

    numwritten = os.posix.write(fd, buffer.ptr, buffer.length);
    if (buffer.length != numwritten)
        goto err2;

    if (os.posix.close(fd) == -1)
        goto err;

    return;

err2:
    os.posix.close(fd);
err:
    throw new ФайлИскл(name, getErrno());
}


/*********************************************
 * Append to a file.
 */

void append(string name, void[] buffer)
{
    int fd;
    int numwritten;
    char *namez;

    namez = toStringz(name);
    fd = os.posix.open(namez, O_APPEND | O_WRONLY | O_CREAT, 0660);
    if (fd == -1)
        goto err;

    numwritten = os.posix.write(fd, buffer.ptr, buffer.length);
    if (buffer.length != numwritten)
        goto err2;

    if (os.posix.close(fd) == -1)
        goto err;

    return;

err2:
    os.posix.close(fd);
err:
    throw new ФайлИскл(name, getErrno());
}


/***************************************************
 * Rename a file.
 */

void rename(string from, string to)
{
    char *fromz = toStringz(from);
    char *toz = toStringz(to);

    if (cidrus.rename(fromz, toz) == -1)
	throw new ФайлИскл(to, getErrno());
}


/***************************************************
 * Delete a file.
 */

void remove(string name)
{
    if (cidrus.remove(toStringz(name)) == -1)
	throw new ФайлИскл(name, getErrno());
}


/***************************************************
 * Get file size.
 */

ulong getSize(string name)
{
    int fd;
    struct_stat statbuf;
    char *namez;

    namez = toStringz(name);
    //эхо("file.getSize('%s')\n",namez);
    fd = os.posix.open(namez, O_RDONLY);
    if (fd == -1)
    {
        //эхо("\topen error, errno = %d\n",getErrno());
        goto err1;
    }

    //эхо("\tfile opened\n");
    if (os.posix.fstat(fd, &statbuf))
    {
        //эхо("\tfstat error, errno = %d\n",getErrno());
        goto err2;
    }
    auto size = statbuf.st_size;

    if (os.posix.close(fd) == -1)
    {
	//эхо("\tclose error, errno = %d\n",getErrno());
        goto err;
    }

    return cast(ulong)size;

err2:
    os.posix.close(fd);
err:
err1:
    throw new ФайлИскл(name, getErrno());
}


/***************************************************
 * Get file attributes.
 */

uint getAttributes(string name)
{
    struct_stat statbuf;
    char *namez;

    namez = toStringz(name);
    if (os.posix.stat(namez, &statbuf))
    {
	throw new ФайлИскл(name, getErrno());
    }

    return statbuf.st_mode;
}

/*************************
 * Get creation/access/modified times of file name[].
 * Throws: ФайлИскл on error.
 */

void getTimes(string name, out d_time ftc, out d_time fta, out d_time ftm)
{
    struct_stat statbuf;
    char *namez;

    namez = toStringz(name);
    if (os.posix.stat(namez, &statbuf))
    {
	throw new ФайлИскл(name, getErrno());
    }

    version (linux)
    {
	ftc = cast(d_time)statbuf.st_ctime * std.date.TicksPerSecond;
	fta = cast(d_time)statbuf.st_atime * std.date.TicksPerSecond;
	ftm = cast(d_time)statbuf.st_mtime * std.date.TicksPerSecond;
    }
    else version (OSX)
    {	// BUG: should add in tv_nsec field
	ftc = cast(d_time)statbuf.st_ctimespec.tv_sec * std.date.TicksPerSecond;
	fta = cast(d_time)statbuf.st_atimespec.tv_sec * std.date.TicksPerSecond;
	ftm = cast(d_time)statbuf.st_mtimespec.tv_sec * std.date.TicksPerSecond;
    }
    else version (FreeBSD)
    {	// BUG: should add in tv_nsec field
	ftc = cast(d_time)statbuf.st_ctimespec.tv_sec * std.date.TicksPerSecond;
	fta = cast(d_time)statbuf.st_atimespec.tv_sec * std.date.TicksPerSecond;
	ftm = cast(d_time)statbuf.st_mtimespec.tv_sec * std.date.TicksPerSecond;
    }
    else version (Solaris)
    {  // BUG: should add in *nsec fields
       ftc = cast(d_time)statbuf.st_ctime * std.date.TicksPerSecond;
       fta = cast(d_time)statbuf.st_atime * std.date.TicksPerSecond;
       ftm = cast(d_time)statbuf.st_mtime * std.date.TicksPerSecond;
    }
    else
    {
	static assert(0);
    }
}


/****************************************************
 * Does file/directory exist?
 */

int exists(char[] name)
{
    return access(toStringz(name),0) == 0;

/+
    struct_stat statbuf;
    char *namez;

    namez = toStringz(name);
    if (os.posix.stat(namez, &statbuf))
    {
	return 0;
    }
    return 1;
+/
}

unittest
{
    assert(exists("."));
}

/****************************************************
 * Is name a file?
 */

int isfile(string name)
{
    return (getAttributes(name) & S_IFMT) == S_IFREG;	// regular file
}

/****************************************************
 * Is name a directory?
 */

int isdir(string name)
{
    return (getAttributes(name) & S_IFMT) == S_IFDIR;
}

/****************************************************
 * Change directory.
 */

void chdir(string pathname)
{
    if (os.posix.chdir(toStringz(pathname)))
    {
	throw new ФайлИскл(pathname, getErrno());
    }
}

/****************************************************
 * Make directory.
 */

void mkdir(char[] pathname)
{
    if (os.posix.mkdir(toStringz(pathname), 0777))
    {
	throw new ФайлИскл(pathname, getErrno());
    }
}

/****************************************************
 * Remove directory.
 */

void rmdir(string pathname)
{
    if (os.posix.rmdir(toStringz(pathname)))
    {
	throw new ФайлИскл(pathname, getErrno());
    }
}

/****************************************************
 * Get current directory.
 */

string getcwd()
{
    auto p = os.posix.getcwd(null, 0);
    if (!p)
    {
	throw new ФайлИскл("cannot get cwd", getErrno());
    }

    auto len = cidrus.strlen(p);
    auto buf = new char[len];
    buf[] = p[0 .. len];
    cidrus.free(p);
    return buf;
}

/***************************************************
 * Directory Entry
 */

alias DirEntry ПапЗапись;
struct DirEntry
{
alias isfile файл_ли;
alias isdir папка_ли;
alias init иниц;
alias attributes атрибуты;
alias lastWriteTime последнВремяЗап;
alias lastAccessTime последВремяДост;
alias creationTime датаСозд;
alias size размер;
alias name имя;

    string name;			/// file or directory name
    ulong _size = ~0UL;			// size of file in bytes
    d_time _creationTime = d_time_nan;	// time of file creation
    d_time _lastAccessTime = d_time_nan; // time file was last accessed
    d_time _lastWriteTime = d_time_nan;	// time file was last written to
    ubyte d_type;
    ubyte didstat;			// done lazy evaluation of stat()

    void init(string path, dirent *fd)
    {	size_t len = cidrus.strlen(fd.d_name.ptr);
	name = std.path.join(path, fd.d_name[0 .. len]);
	d_type = fd.d_type;
       // Some platforms, like Solaris, don't have this member.
       // TODO: Bug: d_type is never set on Solaris (see bugzilla 2838 for fix.)
       static if (is(fd.d_type))
           d_type = fd.d_type;
	didstat = 0;
    }

    int isdir()
    {
	return d_type & DT_DIR;
    }

    int isfile()
    {
	return d_type & DT_REG;
    }

    ulong size()
    {
	if (!didstat)
	    doStat();
	return _size;
    }

    d_time creationTime()
    {
	if (!didstat)
	    doStat();
	return _creationTime;
    }

    d_time lastAccessTime()
    {
	if (!didstat)
	    doStat();
	return _lastAccessTime;
    }

    d_time lastWriteTime()
    {
	if (!didstat)
	    doStat();
	return _lastWriteTime;
    }

    /* This is to support lazy evaluation, because doing stat's is
     * expensive and not always needed.
     */

    void doStat()
    {
	int fd;
	struct_stat statbuf;
	char* namez;

	namez = toStringz(name);
	if (os.posix.stat(namez, &statbuf))
	{
	    //эхо("\tstat error, errno = %d\n",getErrno());
	    return;
	}
	_size = cast(ulong)statbuf.st_size;
	version (linux)
	{
	    _creationTime = cast(d_time)statbuf.st_ctime * std.date.TicksPerSecond;
	    _lastAccessTime = cast(d_time)statbuf.st_atime * std.date.TicksPerSecond;
	    _lastWriteTime = cast(d_time)statbuf.st_mtime * std.date.TicksPerSecond;
	}
	else version (OSX)
	{
	    _creationTime =   cast(d_time)statbuf.st_ctimespec.tv_sec * std.date.TicksPerSecond;
	    _lastAccessTime = cast(d_time)statbuf.st_atimespec.tv_sec * std.date.TicksPerSecond;
	    _lastWriteTime =  cast(d_time)statbuf.st_mtimespec.tv_sec * std.date.TicksPerSecond;
	}
	else version (FreeBSD)
	{
	    _creationTime =   cast(d_time)statbuf.st_ctimespec.tv_sec * std.date.TicksPerSecond;
	    _lastAccessTime = cast(d_time)statbuf.st_atimespec.tv_sec * std.date.TicksPerSecond;
	    _lastWriteTime =  cast(d_time)statbuf.st_mtimespec.tv_sec * std.date.TicksPerSecond;
	}
	else version (Solaris)
	{
	    _creationTime   = cast(d_time)statbuf.st_ctime * std.date.TicksPerSecond;
	    _lastAccessTime = cast(d_time)statbuf.st_atime * std.date.TicksPerSecond;
	    _lastWriteTime  = cast(d_time)statbuf.st_mtime * std.date.TicksPerSecond;
	}
	else
	{
	    static assert(0);
	}

	didstat = 1;
    }
}


/***************************************************
 * Return contents of directory.
 */

string[] listdir(string pathname)
{
    string[] результат;
    bool listing(string filename)
    {
	результат ~= filename;
	return true; // continue
    }

    listdir(pathname, &listing);
    return результат;
}

string[] listdir(string pathname, string pattern)
{   string[] результат;
    bool callback(DirEntry* de)
    {
	if (de.isdir)
	    listdir(de.name, &callback);
	else
	{   if (std.path.fnmatch(de.name, pattern))
		результат ~= de.name;
	}
	return true; // continue
    }
    
    listdir(pathname, &callback);
    return результат;
}

string[] listdir(string pathname, RegExp r)
{   string[] результат;

    bool callback(DirEntry* de)
    {
	if (de.isdir)
	    listdir(de.name, &callback);
	else
	{   if (r.test(de.name))
		результат ~= de.name;
	}
	return true; // continue
    }

    listdir(pathname, &callback);
    return результат;
}

void listdir(string pathname, bool delegate(string filename) callback)
{
    bool listing(DirEntry* de)
    {
	return callback(std.path.getBaseName(de.name));
    }

    listdir(pathname, &listing);
}

void listdir(string pathname, bool delegate(DirEntry* de) callback)
{
    DIR* h;
    dirent* fdata;
    DirEntry de;

    h = opendir(toStringz(pathname));
    if (h)
    {
	try
	{
	    while((fdata = readdir(h)) != null)
	    {
		// Skip "." and ".."
		if (!cidrus.strcmp(fdata.d_name.ptr, ".") ||
		    !cidrus.strcmp(fdata.d_name.ptr, ".."))
			continue;

		de.init(pathname, fdata);
		if (!callback(&de))	    
		    break;
	    }
	}
	finally
	{
	    closedir(h);
	}
    }
    else
    {
        throw new ФайлИскл(pathname, getErrno());
    }
}


/***************************************************
 * Copy a file. File timestamps are preserved.
 */

void copy(string from, string to)
{
  version (all)
  {
    struct_stat statbuf;

    char* fromz = toStringz(from);
    char* toz = toStringz(to);
    //эхо("file.copy(from='%s', to='%s')\n", fromz, toz);

    int fd = os.posix.open(fromz, O_RDONLY);
    if (fd == -1)
    {
        //эхо("\topen error, errno = %d\n",getErrno());
        goto err1;
    }

    //эхо("\tfile opened\n");
    if (os.posix.fstat(fd, &statbuf))
    {
        //эхо("\tfstat error, errno = %d\n",getErrno());
        goto err2;
    }

    int fdw = os.posix.open(toz, O_CREAT | O_WRONLY | O_TRUNC, 0660);
    if (fdw == -1)
    {
        //эхо("\topen error, errno = %d\n",getErrno());
        goto err2;
    }

    size_t BUFSIZ = 4096 * 16;
    void* buf = cidrus.malloc(BUFSIZ);
    if (!buf)
    {	BUFSIZ = 4096;
	buf = cidrus.malloc(BUFSIZ);
    }
    if (!buf)
    {
        //эхо("\topen error, errno = %d\n",getErrno());
        goto err4;
    }

    for (auto size = statbuf.st_size; size; )
    {	size_t toread = (size > BUFSIZ) ? BUFSIZ : cast(size_t)size;

	auto n = os.posix.read(fd, buf, toread);
	if (n != toread)
	{
	    //эхо("\tread error, errno = %d\n",getErrno());
	    goto err5;
	}
	n = os.posix.write(fdw, buf, toread);
	if (n != toread)
	{
	    //эхо("\twrite error, errno = %d\n",getErrno());
	    goto err5;
	}
	size -= toread;
    }

    cidrus.free(buf);

    if (os.posix.close(fdw) == -1)
    {
	//эхо("\tclose error, errno = %d\n",getErrno());
        goto err2;
    }

    utimbuf utim = void;
    version (linux)
    {
	utim.actime = cast(__time_t)statbuf.st_atime;
	utim.modtime = cast(__time_t)statbuf.st_mtime;
    }
    else version (OSX)
    {
	utim.actime = cast(__time_t)statbuf.st_atimespec.tv_sec;
	utim.modtime = cast(__time_t)statbuf.st_mtimespec.tv_sec;
    }
    else version (FreeBSD)
    {
	utim.actime = cast(__time_t)statbuf.st_atimespec.tv_sec;
	utim.modtime = cast(__time_t)statbuf.st_mtimespec.tv_sec;
    }
    else version (Solaris)
    {
       utim.actime = cast(__time_t)statbuf.st_atime;
       utim.modtime = cast(__time_t)statbuf.st_mtime;
    }
    else
    {
	static assert(0);
    }
    if (utime(toz, &utim) == -1)
    {
	//эхо("\tutime error, errno = %d\n",getErrno());
	goto err3;
    }

    if (os.posix.close(fd) == -1)
    {
	//эхо("\tclose error, errno = %d\n",getErrno());
        goto err1;
    }

    return;

err5:
    cidrus.free(buf);
err4:
    os.posix.close(fdw);
err3:
    cidrus.remove(toz);
err2:
    os.posix.close(fd);
err1:
    throw new ФайлИскл(from, getErrno());
  }
  else
  {
    void[] buffer;

    buffer = read(from);
    write(to, buffer);
    delete buffer;
  }
}



}

unittest
{
    //эхо("unittest\n");
    void[] buf;

    buf = new void[10];
    (cast(byte[])buf)[] = 3;
    write("unittest_write.tmp", buf);
    void buf2[] = read("unittest_write.tmp");
    assert(buf == buf2);

    copy("unittest_write.tmp", "unittest_write2.tmp");
    buf2 = read("unittest_write2.tmp");
    assert(buf == buf2);

    remove("unittest_write.tmp");
    if (exists("unittest_write.tmp"))
	assert(0);
    remove("unittest_write2.tmp");
    if (exists("unittest_write2.tmp"))
	assert(0);
}

unittest
{
    listdir (".", delegate bool (DirEntry * de)
    {
	auto s = std.string.format("%s : c %s, w %s, a %s", de.name,
		toUTCString (de.creationTime),
		toUTCString (de.lastWriteTime),
		toUTCString (de.lastAccessTime));
	return true;
    }
    );
}


