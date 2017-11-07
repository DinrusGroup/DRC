module dmd.FileName;

import dmd.common;
import dmd.String;
import dmd.Array;
import dmd.OutBuffer;
import dmd.File;

import core.memory;

import core.stdc.stdlib : malloc, alloca;
import core.stdc.string : memcpy, strlen;
import core.stdc.ctype : isspace;

import std.exception : assumeUnique;
import std.string : cmp, icmp;
import std.file : mkdirRecurse;

version (Windows)
{
    import core.sys.windows.windows;
}

version (POSIX)
{
    import core.stdc.stdlib;
    import core.sys.posix.sys.stat;
    import std.conv;
}

class FileName : String
{
    this(string str)
	{
		register();
		super(str);
	}

    this(string path, string name)
	{
		register();
		super(combine(path, name));
	}

    override hash_t hashCode()
	{
version (Windows)
{
		// We need a different hashCode because it must be case-insensitive
		size_t len = str.length;
		hash_t hash = 0;
		ubyte* s = cast(ubyte*)str.ptr;

		for (;;)
		{
			switch (len)
			{
				case 0:
					return hash;

				case 1:
					hash *= 37;
					hash += *(cast(ubyte*)s) | 0x20;
					return hash;

				case 2:
					hash *= 37;
					hash += *(cast(ushort*)s) | 0x2020;
					return hash;

				case 3:
					hash *= 37;
					hash += (*cast(ushort*)s) << 8 +
						((cast(ubyte*)s)[2]) | 0x202020;
					break;

				default:
					hash *= 37;
					hash += (*cast(int*)s) | 0x20202020;
					s += 4;
					len -= 4;
					break;
			}
		}
} else {
		// darwin HFS is case insensitive, though...
		return super.hashCode();
}
	}

    override bool opEquals(Object obj)
	{
		return opCmp(obj) == 0;
	}

    static bool equals(string name1, string name2)
	{
		return compare(name1, name2) == 0;
	}

    override int opCmp(Object obj)
	{
		return compare(str, (cast(FileName)obj).str);
	}

    static int compare(string name1, string name2)
	{
version (_WIN32) {
    return icmp(name1, name2);
} else {
    return cmp(name1, name2);
}
	}

	static pure bool absolute(const(char)[] name)
	{
version (Windows)
{
		return (name[0] == '\\') ||
			(name[0] == '/')  ||
			((name.length > 1) && (name[1] == ':'));
}
else version (POSIX)
{
		return (name[0] == '/');
}
else
{
	static assert(false);
}
	}

	/********************************
	 * Return filename extension (read-only).
	 * Points past '.' of extension.
	 * If there isn't one, return NULL.
	 */
    static string ext(string str)
	{
		foreach_reverse (i, c; str)
		{
			switch (c)
			{
				case '.':
					return str[i+1..$];
version (POSIX) {
				case '/':
					return null;
}
version (Windows)
{
				case '\\':
				case ':':
				case '/':
					return null;

}				default:
					break;
			}
		}

		return null;
	}

    string ext()
	{
		return ext(str);
	}

	/********************************
	 * Return filename with extension removed.
	 */

    static string removeExt(string str)
	{
		string e = ext(str);
		if (e !is null)
		{
			size_t len = (e.ptr - str.ptr - 1);
			return str[0..len];
		}

		return str;
	}

	/********************************
	 * Return filename name excluding path (read-only).
	 */

    static string name(string str)
	{
		foreach_reverse(i, c; str)
		{
			switch (c)
			{
version (Posix)
{
				case '/':
				   return str[i+1..$];
}
version (Windows)
{
				case '/':
				case '\\':
					return str[i+1..$];
				case ':':
					/* The ':' is a drive letter only if it is the second
					 * character or the last character,
					 * otherwise it is an ADS (Alternate Data Stream) separator.
					 * Consider ADS separators as part of the file name.
					 */
					if (i == 1 || i == str.length - 1)
						return str[i+1..$];
}
				default:
					break;
			}
		}

		return str;
	}

    string name()
	{
		return name(str);
	}

	/**************************************
	 * Return path portion of str.
	 * Path will does not include trailing path separator.
	 */

    static string path(string str)
	{
		auto n = name(str).ptr;

		if (n > str.ptr)
		{
			auto p = n - 1;
version (Posix)
{
			if (*p == '/')
				n--;
} else version (Windows)
{
			if (*p == '\\' || *p == '/')
				n--;
} else
{
			static assert(false);
}
		}

		size_t pathlen = n - str.ptr;
		return str[0..pathlen];
	}

	/**************************************
	 * Replace filename portion of path.
	 */

    static string replaceName(string path, string name)
	{
		if (absolute(name))
			return name;

		string n = FileName.name(path);
		if (n is path)
			return name;

		size_t pathlen = n.ptr - path.ptr;
		size_t namelen = name.length;

		char* f = cast(char*)GC.malloc(pathlen + 1 + namelen + 1);
		memcpy(f, path.ptr, pathlen);
version (Posix)
{
		if (path[pathlen - 1] != '/')
		{
			f[pathlen] = '/';
			pathlen++;
		}
}
else version (Windows)
{
		if (path[pathlen - 1] != '\\' &&
			path[pathlen - 1] != '/' &&
			path[pathlen - 1] != ':')
		{
			f[pathlen] = '\\';
			pathlen++;
		}
}
else
{
		static assert(false);
}
		memcpy(f + pathlen, name.ptr, namelen + 1);

		return assumeUnique(f[0..pathlen+namelen]);
	}

    static string combine(string path, string name)
	{
		size_t pathlen;
		size_t namelen;

		if (path.length == 0)
			return name;

		pathlen = path.length;
		namelen = name.length;

		char* f = cast(char*)GC.malloc(pathlen + 1 + namelen + 1);

		memcpy(f, path.ptr, pathlen);

version (Posix) {
		if (path[pathlen - 1] != '/')
		{
			f[pathlen] = '/';
			pathlen++;
		}
}
else version (Windows)
{
		if (path[pathlen - 1] != '\\' &&
			path[pathlen - 1] != '/'  &&
			path[pathlen - 1] != ':')
		{
			f[pathlen] = '\\';
			pathlen++;
		}
}
else
{
		static assert(0);
}
		memcpy(f + pathlen, name.ptr, namelen + 1);

		return assumeUnique(f[0..pathlen+namelen]);
	}

    static string[] splitPath(const(char)[] spath)
	{
		char c = 0;				// unnecessary initializer is for VC /W4

		scope OutBuffer buf = new OutBuffer();
		string[] array;

		if (spath !is null)
		{
			const(char)* p = spath.ptr;
			int len = spath.length;
			do
			{
				char instring = 0;

				while (len > 0 && isspace(*p))	{	// skip leading whitespace
					p++;
					--len;
				}

				buf.reserve(len + 1);	// guess size of path
				for (; len; p++, len--)
				{
					c = *p;
					switch (c)
					{
						case '"':
							instring ^= 1;	// toggle inside/outside of string
							continue;

	version (MACINTOSH) {
						case ',':
	}
	version (Windows) {
						case ';':
	}
	version (Posix) {
						case ':':
	}
							p++;
							break;		// note that ; cannot appear as part
										// of a path, quotes won't protect it

						case 0x1A:		// ^Z means end of file
						//case 0:
							break;

						case '\r':
							continue;	// ignore carriage returns

	version (POSIX) {
						case '~':
							buf.writestring(to!string(getenv("HOME")));
							continue;
	}

	version (disabled) {
						case ' ':
						case '\t':		// tabs in filenames?
							if (!instring)	// if not in string
								break;	// treat as end of path
	}
						default:
						buf.writeByte(c);
						continue;
					}
					break;
				}
				if (buf.offset)		// if path is not empty
				{
					//buf.writeByte(0);	// to asciiz
					array ~= buf.extractString();
				}
			} while (len > 0);
		}

		return array;
	}

    static FileName defaultExt(string name, string ext)
	{
		string e = FileName.ext(name);
		if (e !is null) {
			// if already has an extension
			return new FileName(name);
		}

		size_t len = name.length;
		size_t extlen = ext.length;
		char* s = cast(char*)GC.malloc(len + 1 + extlen + 1);
		memcpy(s, name.ptr, len);
		s[len] = '.';
		memcpy(s + len + 1, ext.ptr, extlen + 1);

		return new FileName(assumeUnique(s[0..len+1+extlen]));
	}

    static FileName forceExt(string name, string ext)
	{
		string e = FileName.ext(name);
		if (e !is null)				// if already has an extension
		{
			size_t len = e.ptr - name.ptr;
			size_t extlen = ext.length;

			char* s = cast(char*)GC.malloc(len + extlen + 1);  /// !
			memcpy(s, name.ptr, len);
			memcpy(s + len, ext.ptr, extlen + 1);
			return new FileName(assumeUnique(s[0..len+extlen]));
		}

		return defaultExt(name, ext);	// doesn't have one
	}

	/******************************
	 * Return true if extensions match.
	 */

    bool equalsExt(string ext)
	{
		string e = FileName.ext();
		if (e.length == 0 && ext.length == 0)
			return true;

		if (e.length == 0 || ext.length == 0)
			return false;

version (POSIX) {
		return cmp(e,ext) == 0;
} else version (Windows) {
		return icmp(e,ext) == 0;
} else {
		static assert(0);
}
	}

	/*************************************
	 * Copy file from this to to.
	 */

    void CopyTo(FileName to)
	{
		scope File file = new File(this);

version (Win32) {
		file.touchtime = GC.malloc(WIN32_FIND_DATA.sizeof);	// keep same file time
} else version (Posix) {
		file.touchtime = GC.malloc(stat_t.sizeof); // keep same file time
} else {
		static assert(0);
}
		file.readv();
		file.name = to;
		file.writev();
	}

	/*************************************
	 * Search Path for file.
	 * Input:
	 *	cwd	if true, search current directory before searching path
	 */

    static string searchPath(Array path, string name, bool cwd)
	{
		if (absolute(name)) {
			return exists(name) ? name : null;
		}

		if (cwd) {
			if (exists(name)) {
				return name;
			}
		}

		if (path !is null) {
			foreach (i; 0..path.dim)
			{
				String p = cast(String)path.data[i];
				string n = combine(p.str, name);

				if (exists(n))
					return n;
			}
		}

		return null;
	}

	static string searchPath(string[] path, string name, bool cwd)
	{
		if (absolute(name)) {
			return exists(name) ? name : null;
		}

		if (cwd) {
			if (exists(name)) {
				return name;
			}
		}

		if (path !is null) {
			foreach (i, p; path)
			{
				string n = combine(p, name);

				if (exists(n))
					return n;
			}
		}

		return null;
	}

    static int exists(string name)
	{
version (Posix) {
		stat_t st;

		if (stat(toStringz(name), &st) < 0)
			return 0;
		if (S_ISDIR(st.st_mode))
			return 2;
		return 1;
} else version (Win32) {
		HANDLE h = CreateFileA(toStringz(name), GENERIC_READ, FILE_SHARE_READ, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, HANDLE.init);	///
		if (h == INVALID_HANDLE_VALUE) {
			return 0;
		}

		CloseHandle(h);

		DWORD dw = GetFileAttributesA(name.ptr);	/// CARE!
		if (dw == -1L) {
			assert(false);
			return 0;
		} else if (dw & FILE_ATTRIBUTE_DIRECTORY) {
			return 2;
		} else {
			return 1;
		}
} else {
		static assert(0);
}
	}

    static void ensurePathExists(string path)
	{
		if (path.length == 0)
			return;
		try {
			mkdirRecurse(path);
		} catch {
		}
	}
}
