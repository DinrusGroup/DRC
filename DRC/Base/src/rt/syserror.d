module rt.syserror;

private import rt.charset;
private import sys.WinFuncs, sys.WinConsts;

char[] sysErrorString(uint errcode)
{
    char[] результат;
    char* buffer;
    DWORD r;

    r = FormatMessageA( 
	    ПФорматСооб.РазмБуф | 
	    ПФорматСооб.ИзСист | 
	    ПФорматСооб.ИгнорВставки,
	    null,
	    errcode,
	    MAKELANGID(ПЯзык.НЕЙТРАЛЬНЫЙ, ППодъяз.ДЕФОЛТ), // Default language
	    cast(LPTSTR)&buffer,
	    0,
	    null);

    /* Remove \r\n from error string */
    if (r >= 2)
	r -= 2;

    /* Create 0 terminated copy on GC heap because fromMBSz()
     * may return it.
     */
    результат = new char[r + 1];
    результат[0 .. r] = buffer[0 .. r];
    результат[r] = 0;

    результат = rt.charset.fromMBSz(результат.ptr);

    LocalFree(cast(HLOCAL)buffer);
    return результат;
}
