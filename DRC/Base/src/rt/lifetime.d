module rt.lifetime;

    import cidrus, tpl.args;
  // import rt.console;

  // debug = НА_КОНСОЛЬ;
struct Array
{
    size_t length;
    byte*  data;
}

struct Array2
{
    size_t length;
    void*  ptr;
}

static ОбработчикСборки сбобр = null;
alias сбобр collectHandler;//нужно для модуля rt.lifetime

export:


/**
 *
 */
extern (C) void rt_finalize(void* p, bool det = true)
{
    debug(PRINTF) printf("rt_finalize(p = %p)\n", p);

    if (p) 
    {
        ClassInfo** pc = cast(ClassInfo**)p;

        if (*pc)
        {
            ClassInfo c = **pc;
            byte[]    w = c.init;

            try
            {
                if (det || collectHandler is null || collectHandler(cast(Object)p))
                {
                    do
                    {
                        if (c.destructor)
                        {
                            fp_t fp = cast(fp_t)c.destructor;
                            (*fp)(cast(Object)p); // call destructor
                        }
                        c = c.base;
                    } while (c);
                }
                if ((cast(void**)p)[1]) // if monitor is not null
                    _d_monitordelete(cast(Object)p, det);
                (cast(byte*) p)[0 .. w.length] = w[];
            }
            catch (Exception e)
            {
                onFinalizeError(**pc, e);
            }
            finally
            {
                *pc = null; // zero vptr
            }
        }
    }
}

/**
 * Оптимизированная версия rt_finalize, вызов которой предполагается
 * из СМ, чем компенсируется задержка на ненужные операции.
 */
extern (C) void rt_finalize_gc(void* p)
{
    debug(PRINTF) printf("rt_finalize_gc(p = %p)\n", p);

    ClassInfo** pc = cast(ClassInfo**)p;
    
    if (*pc) 
    {
        ClassInfo c = **pc;

        try
        {
            if (collectHandler is null || collectHandler(cast(Object)p))
            {
                do
                {
                    if (c.destructor)
                    {
                        fp_t fp = cast(fp_t)c.destructor;
                        (*fp)(cast(Object)p); // call destructor
                    }
                    c = c.base;
                } while (c);
            }
            if ((cast(void**)p)[1]) // if monitor is not null
                _d_monitordelete(cast(Object)p, false);
        }
        catch (Exception e)
        {
            onFinalizeError(**pc, e);
        }
    }
}

/**
 *
 */
extern (C) Object _d_newclass(ClassInfo ci)
{
    ук  p;

   debug(НА_КОНСОЛЬ) { эхо("_d_newclass(ci = %p, ", ci); скажинс(ci.name);}
    if (ci.flags & 1) // if COM object
    {   /* Объекты COM не собираются, подчитываются ссылки на них
         * с помощью AddRef() и Release().  Они освобождаются функцией Си free(),
         * которую вызывает Release(), когда счётчик ссылок у  Release()
         * доходит до нуля.
	 */
        p = cidrus.празмести(ci.init.length);
        if (!p)
            onOutOfMemoryError();
    }
    else
    {
        p = смПразмести(ci.init.length,
                      ПАтрБлока.Финализовать | (ci.flags & 2 ? ПАтрБлока.НеСканировать : 0));
        debug(НА_КОНСОЛЬ)  эхо(" p = %p\n", p);
    }

    debug(НА_КОНСОЛЬ) 
    {
        эхо("p = %p\n", p);
        эхо("ci = %p, ci.init = %p, len = %d\n", ci, ci.init, ci.init.length);
        эхо("vptr = %p\n", *cast(ук *) ci.init);
        эхо("vtbl[0] = %p\n", (*cast(ук **) ci.init)[0]);
        эхо("vtbl[1] = %p\n", (*cast(ук **) ci.init)[1]);
        эхо("init[0] = %x\n", (cast(uint*) ci.init)[0]);
        эхо("init[1] = %x\n", (cast(uint*) ci.init)[1]);
        эхо("init[2] = %x\n", (cast(uint*) ci.init)[2]);
        эхо("init[3] = %x\n", (cast(uint*) ci.init)[3]);
        эхо("init[4] = %x\n", (cast(uint*) ci.init)[4]);
    }

    // initialize it
    (cast(byte*) p)[0 .. ci.init.length] = ci.init[];

    debug(НА_КОНСОЛЬ)  эхо("initialization done\n");
    return cast(Object) p;
}


/**
 *
 */
extern (C) void _d_delinterface(ук * p)
{
    if (*p)
    {
        Interface* pi = **cast(Interface ***)*p;
        Object     o  = cast(Object)(*p - pi.offset);

        _d_delclass(&o);
        *p = null;
    }
}


// used for deletion
private extern (D) alias void (*fp_t)(Object);


/**
 *
 */
extern (C) void _d_delclass(Object* p)
{
    if (*p)
    {
        debug(НА_КОНСОЛЬ)  эхо("_d_delclass(%p)\n", *p);

        ClassInfo **pc = cast(ClassInfo **)*p;
        if (*pc)
        {
            ClassInfo c = **pc;

            ртФинализуй(cast(ук ) *p);

            if (c.deallocator)
            {
                fp_t fp = cast(fp_t)c.deallocator;
                (*fp)(*p); // call deallocator
                *p = null;
                return;
            }
        }
        else
        {
            ртФинализуй(cast(ук ) *p);
        }
        смОсвободи(cast(ук ) *p);
        *p = null;
    }
}


/**
 * Allocate a new array of length elements.
 * ti is the type of the resulting array, or pointer to element.
 * (For when the array is initialized to 0)
 */
extern (C) ulong _d_newarrayT(TypeInfo ti, size_t length)
{
    ук  p;
    ulong результат;
    auto размер = ti.next.tsize();                // array element размер

    debug(НА_КОНСОЛЬ)  эхо("_d_newarrayT(length = x%x, размер = %d)\n", length, размер);
    if (length == 0 || размер == 0)
        результат = 0;
    else
    {
        if(!смИниц_ли())//version (D_InlineAsm_X86)
        {
            asm
            {
                mov     EAX,размер        ;
                mul     EAX,length      ;
                mov     размер,EAX        ;
                jc      Loverflow       ;
            }
        }
        else
        размер *= length;
        p = смПразмести(размер + 1, !(ti.next.flags() & 1) ? ПАтрБлока.НеСканировать : 0);
        debug(НА_КОНСОЛЬ)  эхо(" p = %p\n", p);
        cidrus.устбуф(p, 0, размер);
        результат = cast(ulong)length + (cast(ulong)cast(uint)p << 32);
    }
    return результат;

Loverflow:
    onOutOfMemoryError();
}

/**
 * For when the array has a non-zero initializer.
 */
extern (C) ulong _d_newarrayiT(TypeInfo ti, size_t length)
{
    ulong результат;
    auto размер = ti.next.tsize();                // array element размер

    debug(НА_КОНСОЛЬ)  эхо("_d_newarrayiT(length = %d, размер = %d)\n", length, размер);

    if (length == 0 || размер == 0)
        результат = 0;
    else
    {
        auto initializer = ti.next.init();
        auto isize = initializer.length;
        auto q = initializer.ptr;
        version (D_InlineAsm_X86)
        {
            asm
            {
                mov     EAX,размер        ;
                mul     EAX,length      ;
                mov     размер,EAX        ;
                jc      Loverflow       ;
            }
        }
        else
            размер *= length;
        auto p = смПразмести(размер + 1, !(ti.next.flags() & 1) ? ПАтрБлока.НеСканировать : 0);
        debug(НА_КОНСОЛЬ)  эхо(" p = %p\n", p);
        if (isize == 1)
            cidrus.устбуф(p, *cast(ubyte*)q, размер);
        else if (isize == int.sizeof)
        {
            int init = *cast(int*)q;
            размер /= int.sizeof;
            for (size_t u = 0; u < размер; u++)
            {
                (cast(int*)p)[u] = init;
            }
        }
        else
        {
            for (size_t u = 0; u < размер; u += isize)
            {
                cidrus.копирбуф(p + u, q, isize);
            }
        }
        ва_стоп(q);
        результат = cast(ulong)length + (cast(ulong)cast(uint)p << 32);
    }
    return результат;

Loverflow:
    onOutOfMemoryError();
}

/**
 *
 */
extern (C) ulong _d_newarraymT(TypeInfo ti, int ndims, ...)
{
    ulong результат;

    debug(НА_КОНСОЛЬ)  эхо("_d_newarraymT(ndims = %d)\n", ndims);
    if (ndims == 0)
        результат = 0;
    else
    {   спис_ва q;
        ва_старт!(int)(q, ndims);

        void[] foo(TypeInfo ti, size_t* pdim, int ndims)
        {
            size_t dim = *pdim;
            void[] p;

            debug(НА_КОНСОЛЬ)  эхо("foo(ti = %p, ti.next = %p, dim = %d, ndims = %d\n", ti, ti.next, dim, ndims);
            if (ndims == 1)
            {
                auto r = _d_newarrayT(ti, dim);
                p = *cast(void[]*)(&r);
            }
            else
            {
                p = смПразмести(dim * (void[]).sizeof + 1)[0 .. dim];
                for (int i = 0; i < dim; i++)
                {
                    (cast(void[]*)p.ptr)[i] = foo(ti.next, pdim + 1, ndims - 1);
                }
            }
            return p;
        }

        size_t* pdim = cast(size_t *)q;
        результат = cast(ulong)foo(ti, pdim, ndims);
        debug(НА_КОНСОЛЬ)  эхо("result = %llx\n", результат);

        version (none)
        {
            for (int i = 0; i < ndims; i++)
            {
                эхо("index %d: %d\n", i, va_arg!(int)(q));
            }
        }
        ва_стоп(q);
    }
    return результат;
}


/**
 *
 */
extern (C) ulong _d_newarraymiT(TypeInfo ti, int ndims, ...)
{
    ulong результат;

    debug(НА_КОНСОЛЬ)  эхо("_d_newarraymiT(ndims = %d)\n", ndims);
    if (ndims == 0)
        результат = 0;
    else
    {
        спис_ва q;
        ва_старт!(int)(q, ndims);

        void[] foo(TypeInfo ti, size_t* pdim, int ndims)
        {
            size_t dim = *pdim;
            void[] p;

            if (ndims == 1)
            {
                auto r = _d_newarrayiT(ti, dim);
                p = *cast(void[]*)(&r);
            }
            else
            {
                p = смПразмести(dim * (void[]).sizeof + 1)[0 .. dim];
                for (int i = 0; i < dim; i++)
                {
                    (cast(void[]*)p.ptr)[i] = foo(ti.next, pdim + 1, ndims - 1);
                }
            }
            return p;
        }

        size_t* pdim = cast(size_t *)q;
        результат = cast(ulong)foo(ti, pdim, ndims);
        debug(НА_КОНСОЛЬ)  эхо("result = %llx\n", результат);

        version (none)
        {
            for (int i = 0; i < ndims; i++)
            {
                эхо("index %d: %d\n", i, va_arg!(int)(q));
                эхо("init = %d\n", va_arg!(int)(q));
            }
        }
        ва_стоп(q);
    }
    return результат;
}


/**
 *
 */
extern (C) ук  _d_allocmemory(size_t nbytes)
{
    return смПразмести(nbytes);
}


/**
 *
 */
extern (C) void _d_delarray(Array *p)
{
    if (p)
    {
        assert(!p.length || p.data);

        if (p.data)
            смОсвободи(p.data);
        p.data = null;
        p.length = 0;
    }
}


/**
 *
 */
extern (C) void _d_delmemory(ук  *p)
{
    if (*p)
    {
        смОсвободи(*p);
        *p = null;
    }
}


/**
 *
 */
extern (C) void _d_callfinalizer(ук  p)
{
    ртФинализуй( p );
}
//alias void (*ФИНАЛИЗАТОР_СМ)(void *p, bool dummy);
ФИНАЛИЗАТОР_СМ finalizer;
/**
 *
 */
extern (C) void ртФинализуй(ук  p, bool det = true)
{
   /* debug(НА_КОНСОЛЬ)  эхо("rtFinalize(p = %p)\n", p);
	if (finalizer)
            (*finalizer)(p, det);
			
    if (p) // not necessary if called from gc
    {
        ClassInfo** pc = cast(ClassInfo**)p;

        if (*pc)
        {
            ClassInfo c = **pc;

            try
            {
                if (det)// || onCollectResource(cast(Object)p))
                {
                    do
                    {
                        if (c.destructor)
                        {
                            fp_t fp = cast(fp_t)c.destructor;
                            (*fp)(cast(Object)p); // call destructor
                        }
                        c = c.дайУстОву();
                    } while (c);
                }
                if ((cast(ук *)p)[1]) // if monitor is not null
                    _d_monitordelete(cast(Object)p, det);
            }
            catch (Exception e)
            {
                onFinalizeError(**pc, e);
            }
            finally
            {
                *pc = null; // zero vptr
            }
        }
    }*/
	rt_finalize(p, det);
}


/**
 * Resize dynamic arrays with 0 initializers.
 */
extern (C) byte[] _d_arraysetlengthT(TypeInfo ti, size_t newlength, Array *p)
in
{
    assert(ti);
    assert(!p.length || p.data);
}
body
{
    byte* newdata;
    size_t sizeelem = ti.next.tsize();

    debug(НА_КОНСОЛЬ) 
	
    {
        эхо("_d_arraysetlengthT(p = %p, sizeelem = %d, newlength = %d)\n", p, sizeelem, newlength);
        if (p)
            эхо("\tp.data = %p, p.length = %d\n", p.data, p.length);
    }

    if (newlength)
    {
        version (D_InlineAsm_X86)
        {
            size_t newsize = void;

            asm
            {
                mov EAX, newlength;
                mul EAX, sizeelem;
                mov newsize, EAX;
                jc  Loverflow;
            }
        }
        else
        {
            size_t newsize = sizeelem * newlength;

            if (newsize / newlength != sizeelem)
                goto Loverflow;
        }

        debug(НА_КОНСОЛЬ)  эхо("newsize = %x, newlength = %x\n", newsize, newlength);

        if (p.data)
        {
            newdata = p.data;
            if (newlength > p.length)
            {
                size_t размер = p.length * sizeelem;
                auto   info = смОпроси(p.data);

                if (info.размер <= newsize || info.основа != p.data)
                {
                    if (info.размер >= РАЗМЕР_СТРАНИЦЫ && info.основа == p.data)
                    {   // Try to extend in-place
                        auto u = смРасширь(p.data, (newsize + 1) - info.размер, (newsize + 1) - info.размер);
                        if (u)
                        {
                            goto L1;
                        }
                    }
                    newdata = cast(byte *)смПразмести(newsize + 1, info.атр);
                    newdata[0 .. размер] = p.data[0 .. размер];
                }
             L1:
                newdata[размер .. newsize] = 0;
            }
        }
        else
        {
            newdata = cast(byte *)смКразмести(newsize + 1, !(ti.next.flags() & 1) ? ПАтрБлока.НеСканировать : 0);
        }
    }
    else
    {
        newdata = p.data;
    }

    p.data = newdata;
    p.length = newlength;
    return newdata[0 .. newlength];

Loverflow:
    onOutOfMemoryError();
}


/**
 * Resize arrays for non-zero initializers.
 *      p               pointer to array lvalue to be updated
 *      newlength       new .length property of array
 *      sizeelem        размер of each element of array
 *      initsize        размер of initializer
 *      ...             initializer
 */
extern (C) byte[] _d_arraysetlengthiT(TypeInfo ti, size_t newlength, Array *p)
in
{
	debug(НА_КОНСОЛЬ)  эхо("ENTERED !!!!\n");
    assert(!p.length || p.data);
}
body
{
    byte* newdata;
//	debug(НА_КОНСОЛЬ)  эхо("yes,I am\n");
//	debug(НА_КОНСОЛЬ)  эхо("ti = \"%s\"\n",ti.toString());
    size_t sizeelem = ti.next.tsize();
//	debug(НА_КОНСОЛЬ)  эхо("no, t's a mistake!\n");
    void[] initializer = ti.next.init();
    size_t initsize = initializer.length;

    assert(sizeelem);
    assert(initsize);
    assert(initsize <= sizeelem);
    assert((sizeelem / initsize) * initsize == sizeelem);

    debug(НА_КОНСОЛЬ) 
    {
      эхо("_d_arraysetlengthiT(p = %p, sizeelem = %d, newlength = %d, initsize = %d)\n", p, sizeelem, newlength, initsize);
       if (p)
            эхо("\tp.data = %p, p.length = %d\n", p.data, p.length);
    }

    if (newlength)
    {
        version (D_InlineAsm_X86)
        {
            size_t newsize = void;

            asm
            {
                mov     EAX,newlength   ;
                mul     EAX,sizeelem    ;
                mov     newsize,EAX     ;
                jc      Loverflow       ;
            }
        }
        else
        {
            size_t newsize = sizeelem * newlength;

            if (newsize / newlength != sizeelem)
                goto Loverflow;
        }
        debug(НА_КОНСОЛЬ)  эхо("newsize = %x, newlength = %x\n", newsize, newlength);

        size_t размер = p.length * sizeelem;

        if (p.data)
        {
            newdata = p.data;
            if (newlength > p.length)
            {
                auto info = смОпроси(p.data);

                if (info.размер <= newsize || info.основа != p.data)
                {
                    if (info.размер >= РАЗМЕР_СТРАНИЦЫ && info.основа == p.data)
                    {   // Try to extend in-place
                        auto u = смРасширь(p.data, (newsize + 1) - info.размер, (newsize + 1) - info.размер);
                        if (u)
                        {
                            goto L1;
                        }
                    }
                    newdata = cast(byte *)смПразмести(newsize + 1, info.атр);
                    newdata[0 .. размер] = p.data[0 .. размер];
                L1: ;
                }
            }
        }
        else
        {
            newdata = cast(byte *)смПразмести(newsize + 1, !(ti.next.flags() & 1) ? ПАтрБлока.НеСканировать : 0);
        }

        auto q = initializer.ptr; // pointer to initializer

        if (newsize > размер)
        {
            if (initsize == 1)
            {
                debug(НА_КОНСОЛЬ)  эхо("newdata = %p, размер = %d, newsize = %d, *q = %d\n", newdata, размер, newsize, *cast(byte*)q);
                newdata[размер .. newsize] = *(cast(byte*)q);
            }
            else
            {
                for (size_t u = размер; u < newsize; u += initsize)
                {
                    cidrus.копирбуф(newdata + u, q, initsize);
                }
            }
        }
    }
    else
    {
        newdata = p.data;
    }

    p.data = newdata;
    p.length = newlength;
    return newdata[0 .. newlength];

Loverflow:
    onOutOfMemoryError();
}


/**
 * Append y[] to array x[].
 * размер is размер of each array element.
 */
extern (C) long _d_arrayappendT(TypeInfo ti, Array *px, byte[] y)
{
    auto sizeelem = ti.next.tsize();            // array element размер
    auto info = смОпроси(px.data);
    auto length = px.length;
    auto newlength = length + y.length;
    auto newsize = newlength * sizeelem;

    if (info.размер < newsize || info.основа != px.data)
    {   byte* newdata;

        if (info.размер >= РАЗМЕР_СТРАНИЦЫ && info.основа == px.data)
        {   // Try to extend in-place
            auto u = смРасширь(px.data, (newsize + 1) - info.размер, (newsize + 1) - info.размер);
            if (u)
            {
                goto L1;
            }
        }
        newdata = cast(byte *)смПразмести(newCapacity(newlength, sizeelem) + 1, info.атр);
        cidrus.копирбуф(newdata, px.data, length * sizeelem);
        px.data = newdata;
    }
  L1:
    px.length = newlength;
    cidrus.копирбуф(px.data + length * sizeelem, y.ptr, y.length * sizeelem);
    return *cast(long*)px;
}


/**
 *
 */
extern (C)  size_t newCapacity(size_t newlength, size_t размер)
{
    version(none)
    {
        size_t newcap = newlength * размер;
    }
    else
    {
        /*
         * Better version by Dave Fladebo:
         * This uses an inverse logorithmic algorithm to pre-allocate a bit more
         * space for larger arrays.
         * - Arrays smaller than РАЗМЕР_СТРАНИЦЫ bytes are left as-is, so for the most
         * common cases, memory allocation is 1 to 1. The small overhead added
         * doesn't affect small array perf. (it's virtually the same as
         * current).
         * - Larger arrays have some space pre-allocated.
         * - As the arrays grow, the relative pre-allocated space shrinks.
         * - The logorithmic algorithm allocates relatively more space for
         * mid-размер arrays, making it very fast for medium arrays (for
         * mid-to-large arrays, this turns out to be quite a bit faster than the
         * equivalent realloc() code in C, on Linux at least. Small arrays are
         * just as fast as GCC).
         * - Perhaps most importantly, overall memory usage and stress on the GC
         * is decreased significantly for demanding environments.
         */
        size_t newcap = newlength * размер;
        size_t newext = 0;

        if (newcap > РАЗМЕР_СТРАНИЦЫ)
        {
            //double mult2 = 1.0 + (размер / log10(pow(newcap * 2.0,2.0)));

            // redo above line using only integer math

            static int log2plus1(size_t c)
            {   int i;

                if (c == 0)
                    i = -1;
                else
                    for (i = 1; c >>= 1; i++)
                    {
                    }
                return i;
            }

            /* The following setting for mult sets how much bigger
             * the new размер will be over what is actually needed.
             * 100 means the same размер, more means proportionally more.
             * More means faster but more memory consumption.
             */
            //long mult = 100 + (1000L * размер) / (6 * log2plus1(newcap));
            long mult = 100 + (1000L * размер) / log2plus1(newcap);

            // testing shows 1.02 for large arrays is about the point of diminishing return
            if (mult < 102)
                mult = 102;
            newext = cast(size_t)((newcap * mult) / 100);
            newext -= newext % размер;
            debug(НА_КОНСОЛЬ)  эхо("mult: %2.2f, alloc: %2.2f\n",mult/100.0,newext / cast(double)размер);
        }
        newcap = newext > newcap ? newext : newcap;
        debug(НА_КОНСОЛЬ)  эхо("newcap = %d, newlength = %d, size = %d\n", newcap, newlength, размер);
    }
    return newcap;
}


/**
 *
 */
extern (C) byte[] _d_arrayappendcT(TypeInfo ti, inout byte[] x, ...)
{
    auto sizeelem = ti.next.tsize();            // array element размер
    auto info = смОпроси(x.ptr);
    auto length = x.length;
    auto newlength = length + 1;
    auto newsize = newlength * sizeelem;

    assert(info.размер == 0 || length * sizeelem <= info.размер);

    debug(НА_КОНСОЛЬ)  эхо("_d_arrayappendcT(sizeelem = %d, ptr = %p, length = %d, cap = %d)\n", sizeelem, x.ptr, x.length, info.размер);

    if (info.размер <= newsize || info.основа != x.ptr)
    {   byte* newdata;

        if (info.размер >= РАЗМЕР_СТРАНИЦЫ && info.основа == x.ptr)
        {   // Try to extend in-place
            auto u = смРасширь(x.ptr, (newsize + 1) - info.размер, (newsize + 1) - info.размер);
            if (u)
            {
                goto L1;
            }
        }
        debug(НА_КОНСОЛЬ)  эхо("_d_arrayappendcT(length = %d, newlength = %d, cap = %d)\n", length, newlength, info.размер);
        auto newcap = newCapacity(newlength, sizeelem);
        assert(newcap >= newlength * sizeelem);
        newdata = cast(byte *)смПразмести(newcap + 1, info.атр);
        cidrus.копирбуф(newdata, x.ptr, length * sizeelem);
        (cast(ук *)(&x))[1] = newdata;
    }
  L1:
    byte *argp = cast(byte *)(&ti + 2);

    *cast(size_t *)&x = newlength;
    x.ptr[length * sizeelem .. newsize] = argp[0 .. sizeelem];
    assert((cast(size_t)x.ptr & 15) == 0);
    assert(смРазмер(x.ptr) > x.length * sizeelem);
    return x;
}


/**
 *
 */
extern (C) byte[] _d_arraycatT(TypeInfo ti, byte[] x, byte[] y)
out (результат)
{
    auto sizeelem = ti.next.tsize();            // array element размер
    debug(НА_КОНСОЛЬ)  эхо("_d_arraycatT(%d,%p ~ %d,%p sizeelem = %d => %d,%p)\n", x.length, x.ptr, y.length, y.ptr, sizeelem, результат.length, результат.ptr);
    assert(результат.length == x.length + y.length);
    for (size_t i = 0; i < x.length * sizeelem; i++)
        assert((cast(byte*)результат)[i] == (cast(byte*)x)[i]);
    for (size_t i = 0; i < y.length * sizeelem; i++)
        assert((cast(byte*)результат)[x.length * sizeelem + i] == (cast(byte*)y)[i]);

    size_t cap = смРазмер(результат.ptr);
    assert(!cap || cap > результат.length * sizeelem);
}
body
{
    version (none)
    {
        /* Cannot use this optimization because:
         *  char[] a, b;
         *  char c = 'a';
         *  b = a ~ c;
         *  c = 'b';
         * will change the contents of b.
         */
        if (!y.length)
            return x;
        if (!x.length)
            return y;
    }

    debug(НА_КОНСОЛЬ)  эхо("_d_arraycatT(%d,%p ~ %d,%p)\n", x.length, x.ptr, y.length, y.ptr);
    auto sizeelem = ti.next.tsize();            // array element размер
    debug(НА_КОНСОЛЬ)  эхо("_d_arraycatT(%d,%p ~ %d,%p sizeelem = %d)\n", x.length, x.ptr, y.length, y.ptr, sizeelem);
    size_t xlen = x.length * sizeelem;
    size_t ylen = y.length * sizeelem;
    size_t len  = xlen + ylen;

    if (!len)
        return null;

    byte* p = cast(byte*)смПразмести(len + 1, !(ti.next.flags() & 1) ? ПАтрБлока.НеСканировать : 0);
    cidrus.копирбуф(p, x.ptr, xlen);
    cidrus.копирбуф(p + xlen, y.ptr, ylen);
    p[len] = 0;
    return p[0 .. x.length + y.length];
}


/**
 *
 */
extern (C) byte[] _d_arraycatnT(TypeInfo ti, uint n, ...)
{   ук  a;
    size_t length;
    byte[]* p;
    uint i;
    byte[] b;
    auto размер = ti.next.tsize(); // array element размер

    p = cast(byte[]*)(&n + 1);

    for (i = 0; i < n; i++)
    {
        b = *p++;
        length += b.length;
    }
    if (!length)
        return null;

    a = смПразмести(length * размер, !(ti.next.flags() & 1) ? ПАтрБлока.НеСканировать : 0);
    p = cast(byte[]*)(&n + 1);

    uint j = 0;
    for (i = 0; i < n; i++)
    {
        b = *p++;
        if (b.length)
        {
            cidrus.копирбуф(a + j, b.ptr, b.length * размер);
            j += b.length * размер;
        }
    }

    byte[] результат;
    *cast(int *)&результат = length;       // jam length
    (cast(void **)&результат)[1] = a;      // jam ptr
    return результат;
}


/**
 *
 */
extern(C) void*  _d_arrayliteralT(TypeInfo ti, size_t length, ...)
{
    auto sizeelem = ti.next.tsize();            // array element размер
    void* результат;

    debug(НА_КОНСОЛЬ) эхо("_d_arrayliteralT(sizeelem = %d, length = %d)\n", sizeelem, length);
    if (length == 0 || sizeelem == 0)
        результат = null;
    else
    {
        результат = смПразмести(length * sizeelem, !(ti.next.flags() & 1) ? ПАтрБлока.НеСканировать : 0);

        спис_ва q;
        ва_старт!(size_t)(q, length);

        size_t stacksize = (sizeelem + int.sizeof - 1) & ~(int.sizeof - 1);

        if (stacksize == sizeelem)
        {
            cidrus.копирбуф(результат, q, length * sizeelem);
        }
        else
        {
            for (size_t i = 0; i < length; i++)
            {
                cidrus.копирбуф(результат + i * sizeelem, q, sizeelem);
                q += stacksize;
            }
        }

        ва_стоп(q);
    }
    return результат;
}


/**
 * Support for array.dup property.
 */

extern (C) long _adDupT(TypeInfo ti, Array2 a)
	out(результат)
	{
		//auto sizeelem = ti.next.tsize();            // array element размер
		//assert(cidrus.сравбуф((*cast(Array2*)&результат).ptr, a.ptr, a.length * sizeelem) == 0);
	}
	body
	{
		Array2 r;
	   if (a.length)
		{
			auto sizeelem = ti.next.tsize();                // array element размер
			auto размер = a.length * sizeelem;
			r.ptr = смПразмести(размер, !(ti.next.flags() & 1) ? ПАтрБлока.НеСканировать : 0);
			r.length = a.length;
			cidrus.копирбуф(r.ptr, a.ptr, размер);
		}
		 auto результат = *cast(long*)(&r);	
		 return результат;
	}


unittest
{
    int[] a;
    int[] b;
    int i;

    a = new int[3];
    a[0] = 1; a[1] = 2; a[2] = 3;
    b = a.dup;
    assert(b.length == 3);
    for (i = 0; i < 3; i++)
        assert(b[i] == i + 1);
}

extern (C):

ук  смПразмести( т_мера разм, бцел ba = 0 );
ук  смКразмести( т_мера разм, бцел ba = 0 );
т_мера смРасширь( ук p, т_мера mx, т_мера разм );
бул смОсвободи( ук  p );
т_мера смРазмер( ук  p );
ИнфОБл смОпроси( ук  p );
бул смИниц_ли();
