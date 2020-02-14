﻿//_ adi.d

/**
 * Part of the D programming language runtime library.
 * Dynamic array property support routines
 */


module rt.adi;


//debug=adi;            // uncomment to turn on debugging printf's

private
{
    import cidrus;
    import std.utf;

    extern (C) void* gc_malloc( size_t sz, uint ba = 0 );
    extern (C) void* gc_calloc( size_t sz, uint ba = 0 );
    extern (C) void  gc_free( void* p );
}

//Основная проблема - унифицировать структуру Массив для всех модулей рантайма,
// чтобы она всегда была такой, какой представлена в модуле base...
struct Array
{
    size_t  length;
    void*   ptr;
}



export :


/**********************************************
 * Reverse array of chars.
 * Handled separately because embedded multibyte encodings should not be
 * reversed.
 */

extern (C) char[] _adReverseChar(char[] a)
{
    if (a.length > 1)
    {
        char[6] tmp;
        char[6] tmplo;
        char* lo = a.ptr;
        char* hi = &a[$ - 1];

        while (lo < hi)
        {   auto clo = *lo;
            auto chi = *hi;

            debug(adi) printf("lo = %d, hi = %d\n", lo, hi);
            if (clo <= 0x7F && chi <= 0x7F)
            {
                debug(adi) printf("\tascii\n");
                *lo = chi;
                *hi = clo;
                lo++;
                hi--;
                continue;
            }

            uint stridelo = UTF8stride[clo];

            uint stridehi = 1;
            while ((chi & 0xC0) == 0x80)
            {
                chi = *--hi;
                stridehi++;
                assert(hi >= lo);
            }
            if (lo == hi)
                break;

            debug(adi) printf("\tstridelo = %d, stridehi = %d\n", stridelo, stridehi);
            if (stridelo == stridehi)
            {

                cidrus.memcpy(tmp.ptr, lo, stridelo);
                cidrus.memcpy(lo, hi, stridelo);
                cidrus.memcpy(hi, tmp.ptr, stridelo);
                lo += stridelo;
                hi--;
                continue;
            }

            /* Shift the whole array. This is woefully inefficient
             */
            cidrus.memcpy(tmp.ptr, hi, stridehi);
            cidrus.memcpy(tmplo.ptr, lo, stridelo);
            cidrus.memmove(lo + stridehi, lo + stridelo , cast(size_t)((hi - lo) - stridelo));
            cidrus.memcpy(lo, tmp.ptr, stridehi);
            cidrus.memcpy(hi + stridehi - stridelo, tmplo.ptr, stridelo);

            lo += stridehi;
            hi = hi - 1 + cast(int)(stridehi - stridelo);
        }
    }
    return a;
}

unittest
{
    auto a = "abcd"c[];

    auto r = a.dup.reverse;
    //writefln(r);
    assert(r == "dcba");

    a = "a\u1235\u1234c";
    //writefln(a);
    r = a.dup.reverse;
    //writefln(r);
    assert(r == "c\u1234\u1235a");

    a = "ab\u1234c";
    //writefln(a);
    r = a.dup.reverse;
    //writefln(r);
    assert(r == "c\u1234ba");

    a = "\u3026\u2021\u3061\n";
    r = a.dup.reverse;
    assert(r == "\n\u3061\u2021\u3026");
}


/**********************************************
 * Reverse array of wchars.
 * Handled separately because embedded multiword encodings should not be
 * reversed.
 */

extern (C) wchar[] _adReverseWchar(wchar[] a)
{
    if (a.length > 1)
    {
        wchar[2] tmp;
        wchar* lo = a.ptr;
        wchar* hi = &a[$ - 1];

        while (lo < hi)
        {   auto clo = *lo;
            auto chi = *hi;

            if ((clo < 0xD800 || clo > 0xDFFF) &&
                (chi < 0xD800 || chi > 0xDFFF))
            {
                *lo = chi;
                *hi = clo;
                lo++;
                hi--;
                continue;
            }

            int stridelo = 1 + (clo >= 0xD800 && clo <= 0xDBFF);

            int stridehi = 1;
            if (chi >= 0xDC00 && chi <= 0xDFFF)
            {
                chi = *--hi;
                stridehi++;
                assert(hi >= lo);
            }
            if (lo == hi)
                break;

            if (stridelo == stridehi)
            {   int stmp;

                assert(stridelo == 2);
                assert(stmp.sizeof == 2 * (*lo).sizeof);
                stmp = *cast(int*)lo;
                *cast(int*)lo = *cast(int*)hi;
                *cast(int*)hi = stmp;
                lo += stridelo;
                hi--;
                continue;
            }

            /* Shift the whole array. This is woefully inefficient
             */
            cidrus.memcpy(tmp.ptr, hi, stridehi * wchar.sizeof);
            cidrus.memcpy(hi + stridehi - stridelo, lo, stridelo * wchar.sizeof);
            cidrus.memmove(lo + stridehi, lo + stridelo , (hi - (lo + stridelo)) * wchar.sizeof);
            cidrus.memcpy(lo, tmp.ptr, stridehi * wchar.sizeof);

            lo += stridehi;
            hi = hi - 1 + (stridehi - stridelo);
        }
    }
    return a;
}

unittest
{
    wstring a = "abcd";

    auto r = a.dup.reverse;
    assert(r == "dcba");

    a = "a\U00012356\U00012346c";
    r = a.dup.reverse;
    assert(r == "c\U00012346\U00012356a");

    a = "ab\U00012345c";
    r = a.dup.reverse;
    assert(r == "c\U00012345ba");
}


/**********************************************
 * Support for array.reverse property.
 */

extern (C) void[] _adReverse(Array a, size_t szelem)
out (result)
{
    assert(result is *cast(void[]*)(&a));
}
body
{
    if (a.length >= 2)
    {
        byte*    tmp;
        byte[16] buffer;

        void* lo = a.ptr;
        void* hi = a.ptr + (a.length - 1) * szelem;

        tmp = buffer.ptr;
        if (szelem > 16)
        {
            //version (Windows)
                tmp = cast(byte*) alloca(szelem);
            //else
                //tmp = gc_malloc(szelem);
        }

        for (; lo < hi; lo += szelem, hi -= szelem)
        {
            cidrus.memcpy(tmp, lo,  szelem);
            cidrus.memcpy(lo,  hi,  szelem);
            cidrus.memcpy(hi,  tmp, szelem);
        }

        version (Windows)
        {
        }
        else
        {
            //if (szelem > 16)
                // BUG: bad code is generate for delete pointer, tries
                // to call delclass.
                //gc_free(tmp);
        }
    }
    return *cast(void[]*)(&a);
}

unittest
{
    debug(adi) printf("array.reverse.unittest\n");

    int[] a = new int[5];
    int[] b;

    for (auto i = 0; i < 5; i++)
        a[i] = i;
    b = a.reverse;
    assert(b is a);
    for (auto i = 0; i < 5; i++)
        assert(a[i] == 4 - i);

    struct X20
    {   // More than 16 bytes in size
        int a;
        int b, c, d, e;
    }

    X20[] c = new X20[5];
    X20[] d;

    for (auto i = 0; i < 5; i++)
    {   c[i].a = i;
        c[i].e = 10;
    }
    d = c.reverse;
    assert(d is c);
    for (auto i = 0; i < 5; i++)
    {
        assert(c[i].a == 4 - i);
        assert(c[i].e == 10);
    }
}

/**********************************************
 * Sort array of chars.
 */

extern (C) char[] _adSortChar(char[] a)
{
    if (a.length > 1)
    {
        dchar[] da = cast(dchar[])toUTF32(a);
        da.sort;
        size_t i = 0;
        foreach (dchar d; da)
        {   char[4] buf;
            auto t = toUTF8(buf, d);
            a[i .. i + t.length] = t[];
            i += t.length;
        }
        delete da;
    }
    return a;
}

/**********************************************
 * Sort array of wchars.
 */

extern (C) wchar[] _adSortWchar(wchar[] a)
{
    if (a.length > 1)
    {
        dchar[] da = cast(dchar[])toUTF32(a);
        da.sort;
        size_t i = 0;
        foreach (dchar d; da)
        {   wchar[2] buf;
            auto t = toUTF16(buf, d);
            a[i .. i + t.length] = t[];
            i += t.length;
        }
        delete da;
    }
    return a;
}

/***************************************
 * Support for array equality test.
 * Returns:
 *      1       equal
 *      0       not equal
 */

extern (C) int _adEq(Array a1, Array a2, TypeInfo ti)
{
    debug(adi) printf("_adEq(a1.length = %d, a2.length = %d)\n", a1.length, a2.length);
    if (a1.length != a2.length)
        return 0; // not equal
    auto sz = ti.tsize();
    auto p1 = a1.ptr;
    auto p2 = a2.ptr;

    if (sz == 1)
        // We should really have a ti.isPOD() check for this
        return (cidrus.memcmp(p1, p2, a1.length) == 0);

    for (size_t i = 0; i < a1.length; i++)
    {
        if (!ti.equals(p1 + i * sz, p2 + i * sz))
            return 0; // not equal
    }
    return 1; // equal
}

extern (C) int _adEq2(Array a1, Array a2, TypeInfo ti)
{
    debug(adi) printf("_adEq2(a1.length = %d, a2.length = %d)\n", a1.length, a2.length);
    if (a1.length != a2.length)
        return 0;               // not equal
    if (!ti.equals(&a1, &a2))
        return 0;
    return 1;
}
unittest
{
    debug(adi) printf("array.Eq unittest\n");

    auto a = "hello"c;

    assert(a != "hel");
    assert(a != "helloo");
    assert(a != "betty");
    assert(a == "hello");
    assert(a != "hxxxx");
}

/***************************************
 * Support for array compare test.
 */

extern (C) int _adCmp(Array a1, Array a2, TypeInfo ti)
{
    debug(adi) printf("adCmp()\n");
    auto len = a1.length;
    if (a2.length < len)
        len = a2.length;
    auto sz = ti.tsize();
    void *p1 = a1.ptr;
    void *p2 = a2.ptr;

    if (sz == 1)
    {   // We should really have a ti.isPOD() check for this
        auto c = cidrus.memcmp(p1, p2, len);
        if (c)
            return c;
    }
    else
    {
        for (size_t i = 0; i < len; i++)
        {
            auto c = ti.compare(p1 + i * sz, p2 + i * sz);
            if (c)
                return c;
        }
    }
    if (a1.length == a2.length)
        return 0;
    return (a1.length > a2.length) ? 1 : -1;
}

extern (C) int _adCmp2(Array a1, Array a2, TypeInfo ti)
{
    debug(adi) printf("_adCmp2(a1.length = %d, a2.length = %d)\n", a1.length, a2.length);
    return ti.compare(&a1, &a2);
}
unittest
{
    debug(adi) printf("array.Cmp unittest\n");

    auto a = "hello"c;

    assert(a >  "hel");
    assert(a >= "hel");
    assert(a <  "helloo");
    assert(a <= "helloo");
    assert(a >  "betty");
    assert(a >= "betty");
    assert(a == "hello");
    assert(a <= "hello");
    assert(a >= "hello");
}

/***************************************
 * Support for array compare test.
 */

extern (C) int _adCmpChar(Array a1, Array a2)
{
  version (X86)
  {
    asm
    {   naked                   ;

        push    EDI             ;
        push    ESI             ;

        mov    ESI,a1+4[4+ESP]  ;
        mov    EDI,a2+4[4+ESP]  ;

        mov    ECX,a1[4+ESP]    ;
        mov    EDX,a2[4+ESP]    ;

        cmp     ECX,EDX         ;
        jb      GotLength       ;

        mov     ECX,EDX         ;

GotLength:
        cmp    ECX,4            ;
        jb    DoBytes           ;

        // Do alignment if neither is dword aligned
        test    ESI,3           ;
        jz    Aligned           ;

        test    EDI,3           ;
        jz    Aligned           ;
DoAlign:
        mov    AL,[ESI]         ; //align ESI to dword bounds
        mov    DL,[EDI]         ;

        cmp    AL,DL            ;
        jnz    Unequal          ;

        inc    ESI              ;
        inc    EDI              ;

        test    ESI,3           ;

        lea    ECX,[ECX-1]      ;
        jnz    DoAlign          ;
Aligned:
        mov    EAX,ECX          ;

        // do multiple of 4 bytes at a time

        shr    ECX,2            ;
        jz    TryOdd            ;

        repe                    ;
        cmpsd                   ;

        jnz    UnequalQuad      ;

TryOdd:
        mov    ECX,EAX          ;
DoBytes:
        // if still equal and not end of string, do up to 3 bytes slightly
        // slower.

        and    ECX,3            ;
        jz    Equal             ;

        repe                    ;
        cmpsb                   ;

        jnz    Unequal          ;
Equal:
        mov    EAX,a1[4+ESP]    ;
        mov    EDX,a2[4+ESP]    ;

        sub    EAX,EDX          ;
        pop    ESI              ;

        pop    EDI              ;
        ret                     ;

UnequalQuad:
        mov    EDX,[EDI-4]      ;
        mov    EAX,[ESI-4]      ;

        cmp    AL,DL            ;
        jnz    Unequal          ;

        cmp    AH,DH            ;
        jnz    Unequal          ;

        shr    EAX,16           ;

        shr    EDX,16           ;

        cmp    AL,DL            ;
        jnz    Unequal          ;

        cmp    AH,DH            ;
Unequal:
        sbb    EAX,EAX          ;
        pop    ESI              ;

        or     EAX,1            ;
        pop    EDI              ;

        ret                     ;
    }
  }
  else
  {
    debug(adi) printf("adCmpChar()\n");
    auto len = a1.length;
    if (a2.length < len)
        len = a2.length;
    auto c = cidrus.memcmp(cast(char *)a1.ptr, cast(char *)a2.ptr, len);
    if (!c)
        c = cast(int)a1.length - cast(int)a2.length;
    return c;
  }
}

unittest
{
    debug(adi) printf("array.CmpChar unittest\n");

    auto a = "hello"c;

    assert(a >  "hel");
    assert(a >= "hel");
    assert(a <  "helloo");
    assert(a <= "helloo");
    assert(a >  "betty");
    assert(a >= "betty");
    assert(a == "hello");
    assert(a <= "hello");
    assert(a >= "hello");
}
