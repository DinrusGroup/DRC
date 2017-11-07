module dmd.File;

import dmd.common;
import dmd.FileName;
import dmd.Array;
import dmd.Util;

import core.stdc.stdlib;
version (Windows)
{
    import core.sys.windows.windows;
}
version (POSIX)
{
    import core.sys.posix.fcntl;
    import core.stdc.errno;
    import core.sys.posix.unistd;
    import core.sys.posix.utime;
    import core.stdc.stdio;
}

import std.string : toStringz;
import std.stdio;
import std.conv;

import core.memory;

import dmd.TObject;

class File : TObject
{
    int ref_;					// != 0 if this is a reference to someone else's buffer
    ubyte* buffer;				// data for our file
    uint len;					// amount of data in buffer[]
    void* touchtime;			// system time to use for file

    FileName name;				// name of our file

    this(string n)
	{
		register();
		name = new FileName(n);
	}

    this(FileName n)
	{
		register();
		name = n;
	}

    ~this()
	{
		if (buffer !is null) {
			if (ref_ == 0) {
				///free(buffer);
			} else {
version (Windows) {
				if (ref_ == 2) {
					UnmapViewOfFile(buffer);
				}
}
			}
		}

		if (touchtime !is null) {
			///free(touchtime);
		}
	}

    void mark()
	{
		///mem.mark(buffer);
		///mem.mark(touchtime);
		///mem.mark(name);
	}

    string toChars()
	{
		return name.toChars();
	}

    /* Read file, return !=0 if error
     */

    int read()
	{
version (Posix)
{
		int result = 0;

		string name = this.name.toChars();

		//writefln("File::read('%s')\n",name);
		int fd = open(toStringz(name), O_RDONLY);
		if (fd == -1) {
			result = errno;
			printf("file: %s\n", toStringz(name));
			printf("\topen error, errno = %d\n", errno);
			goto err1;
		}

		if (ref_ == 0) {
			///free(buffer);
		}

		ref_ = 0;       // we own the buffer now

		//printf("\tfile opened\n");
		stat_t buf;
		if (fstat(fd, &buf)) {
			printf("\tfstat error, errno = %d\n", errno);
			goto err2;
		}

		size_t size = cast(size_t) buf.st_size;
		buffer = cast(ubyte*)GC.malloc(size + 2);
		if (buffer is null) {
			printf("\tmalloc error, errno = %d\n", errno);
			goto err2;
		}

		ssize_t numread = .read(fd, buffer, size);
		if (numread != size) {
			printf("\tread error, errno = %d\n",errno);
			goto err2;
		}

		if (touchtime !is null) {
			memcpy(touchtime, &buf, buf.sizeof);
		}

		if (close(fd) == -1) {
			printf("\tclose error, errno = %d\n",errno);
			goto err;
		}

		len = size;

		// Always store a wchar ^Z past end of buffer so scanner has a sentinel
		buffer[size] = 0;		// ^Z is obsolete, use 0
		buffer[size + 1] = 0;

		return 0;

	err2:
		close(fd);

	err:
		///free(buffer);
		buffer = null;
		len = 0;

	err1:
		result = 1;
		return result;
} else version (Windows) {
		DWORD size;
		DWORD numread;
		HANDLE h;
		int result = 0;

		string name = this.name.toChars();
		//writeln("Open file ", name);

		h = CreateFileA(toStringz(name), GENERIC_READ, FILE_SHARE_READ, null, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, HANDLE.init);
		if (h == INVALID_HANDLE_VALUE) {
			goto err1;
		}

		if (!ref_) {
			///free(buffer);
		}
		ref_ = 0;

		size = GetFileSize(h, null);
		buffer = cast(ubyte*) GC.malloc(size + 2);
		if (!buffer)
			goto err2;

		if (ReadFile(h, buffer, size, &numread, null) != TRUE)
			goto err2;

		if (numread != size)
			goto err2;

		if (touchtime) {
			if (!GetFileTime(h, null, null, &(cast(WIN32_FIND_DATA*)touchtime).ftLastWriteTime))
				goto err2;
		}

		if (!CloseHandle(h))
			goto err;

		len = size;

		// Always store a wchar ^Z past end of buffer so scanner has a sentinel
		buffer[size] = 0;		// ^Z is obsolete, use 0
		buffer[size + 1] = 0;
		return 0;

	err2:
		CloseHandle(h);
	err:
		///free(buffer);
		buffer = null;
		len = 0;

	err1:
		result = 1;
		return result;
} else {
		static assert(0);
}
	}

    /* Write file, either succeed or fail
     * with error message & exit.
     */

    void readv()
	{
		if (read())
			error("Error reading file '%s'\n",name.toChars());
	}

    /* Read file, return !=0 if error
     */

    int mmread()
	{
		assert(false);
	}

    /* Write file, either succeed or fail
     * with error message & exit.
     */

    void mmreadv()
	{
		assert(false);
	}

    /* Write file, return !=0 if error
     */

	/*********************************************
	 * Write a file.
	 * Returns:
	 *	0	success
	 */
    int write()
	{
version (POSIX) {
		//assert(false);
		
		int fd;
		ssize_t numwritten;
		const(char)* name = toStringz(this.name.toChars());
		fd = open(name, O_CREAT | O_WRONLY | O_TRUNC, std.conv.octal!644);
		if (fd == -1)
		goto err;

		numwritten = core.sys.posix.unistd.write(fd, buffer, len);
		if (len != numwritten)
		goto err2;
		
		if (close(fd) == -1)
		goto err;

		if (touchtime)
		{   utimbuf ubuf;

			ubuf.actime = (cast(stat_t *)touchtime).st_atime;
			ubuf.modtime = (cast(stat_t *)touchtime).st_mtime;
		if (utime(name, &ubuf))
			goto err;
		}
		return 0;

	err2:
		close(fd);
		.remove(name);
	err:
		return 1;
		
} else version (Windows) {
		HANDLE h;
		DWORD numwritten;

		const(char)* name = toStringz(this.name.toChars());
		h = CreateFileA(name, GENERIC_WRITE, 0, null, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, null);
		if (h == INVALID_HANDLE_VALUE)
			goto err;

		if (WriteFile(h, buffer, len, &numwritten, null) != TRUE)
			goto err2;

		if (len != numwritten)
			goto err2;
		
		if (touchtime) {
			SetFileTime(h, null, null, &(cast(WIN32_FIND_DATA*)touchtime).ftLastWriteTime);
		}
		if (!CloseHandle(h))
			goto err;
		return 0;

	err2:
		CloseHandle(h);
		DeleteFileA(name);
	err:
		return 1;
} else {
		static assert(false);
}
	}

    /* Write file, either succeed or fail
     * with error message & exit.
     */

    void writev()
	{
		if (write()) {
			error("Error writing file '%s'\n", name.toChars());
		}
	}

    /* Return !=0 if file exists.
     *	0:	file doesn't exist
     *	1:	normal file
     *	2:	directory
     */

    /* Append to file, return !=0 if error
     */

    int append()
	{
		assert(false);
	}

    /* Append to file, either succeed or fail
     * with error message & exit.
     */

    void appendv()
	{
		assert(false);
	}

    /* Return !=0 if file exists.
     *	0:	file doesn't exist
     *	1:	normal file
     *	2:	directory
     */

    int exists()
	{
		assert(false);
	}

    /* Given wildcard filespec, return an array of
     * matching File's.
     */

    static Array match(char*)
	{
		assert(false);
	}

    static Array match(FileName *)
	{
		assert(false);
	}

    // Compare file times.
    // Return	<0	this < f
    //		=0	this == f
    //		>0	this > f
    int compareTime(File f)
	{
		assert(false);
	}

    // Read system file statistics
    void stat()
	{
		assert(false);
	}

    /* Set buffer
     */

    void setbuffer(void* buffer, uint len)
    {
		this.buffer = cast(ubyte*)buffer;
		this.len = len;
    }

    void checkoffset(size_t offset, size_t nbytes)
	{
		assert(false);
	}

    void remove()		// delete file
	{
version (POSIX) {
		.remove(toStringz(this.name.toChars()));
} else version (_WIN32) {
		DeleteFileA(toStringz(this.name.toChars()));
} else {
		assert(0);
}
	}
}
