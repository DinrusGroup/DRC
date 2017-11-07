module dmd.backend.TYM;

enum TYM
{
    TYbool		= 0,
    TYchar		= 1,
    TYschar		= 2,	// signed char
    TYuchar		= 3,	// unsigned char
    TYshort		= 4,
    TYwchar_t		= 5,
    TYushort		= 6,	// unsigned short
    TYenum		= 7,	// enumeration value
    TYint		= 8,
    TYuint		= 9,	// unsigned
    TYlong		= 0xA,
    TYulong		= 0xB,	// unsigned long
    TYdchar		= 0xC,	// 32 bit Unicode char
    TYllong		= 0xD,	// 64 bit long
    TYullong		= 0xE,	// 64 bit unsigned long
    TYfloat		= 0xF,	// 32 bit real
    TYdouble		= 0x10,	// 64 bit real

    // long double is mapped to either of the following at runtime:
    TYdouble_alias	= 0x11,	// 64 bit real (but distinct for overload purposes)
    TYldouble		= 0x12,	// 80 bit real

    // Add imaginary and complex types for D and C99
    TYifloat		= 0x13,
    TYidouble		= 0x14,
    TYildouble		= 0x15,
    TYcfloat		= 0x16,
    TYcdouble		= 0x17,
    TYcldouble		= 0x18,

///#if TX86
    TYjhandle		= 0x19,	// Jupiter handle type, equals TYnptr except
				// that the debug type is different so the
				// debugger can distinguish them
    TYnptr		= 0x1A,	// data segment relative pointer
    TYsptr		= 0x1B,	// stack segment relative pointer
    TYcptr		= 0x1C,	// code segment relative pointer
    TYf16ptr		= 0x1D,	// special OS/2 far16 pointer
    TYfptr		= 0x1E,	// far pointer (has segment and offset)
    TYhptr		= 0x1F,	// huge pointer (has segment and offset)
    TYvptr		= 0x20,	// __handle pointer (has segment and offset)
    TYref		= 0x21,	// reference to another type
    TYvoid		= 0x22,
    TYstruct		= 0x23,	// watch tyaggregate()
    TYarray		= 0x24,	// watch tyaggregate()
    TYnfunc		= 0x25,	// near C func
    TYffunc		= 0x26,	// far  C func
    TYnpfunc		= 0x27,	// near Cpp func
    TYfpfunc		= 0x28,	// far  Cpp func
    TYnsfunc		= 0x29,	// near stdcall func
    TYfsfunc		= 0x2A,	// far stdcall func
    TYifunc		= 0x2B,	// interrupt func
    TYmemptr		= 0x2C,	// pointer to member
    TYident		= 0x2D,	// type-argument
    TYtemplate		= 0x2E,	// unexpanded class template
    TYvtshape		= 0x2F,	// virtual function table
    TYptr		= 0x30,	// generic pointer type
    TYf16func		= 0x31,	// _far16 _pascal function
    TYnsysfunc		= 0x32,	// near __syscall func
    TYfsysfunc		= 0x33,	// far __syscall func
    TYmfunc		= 0x34,	// NT C++ member func
    TYjfunc		= 0x35,	// LINKd D function
    TYhfunc		= 0x36, // C function with hidden parameter
    TYnref		= 0x37,	// near reference
    TYfref		= 0x38,	// far reference
    TYMAX		= 0x39,

///#if MARS
	TYaarray = TYnptr,
	TYdelegate = TYllong,
	TYdarray = TYullong,
///#endif
}

version (Windows) {
	extern (C++) extern {
		__gshared int TYptrdiff, TYsize, TYsize_t;
	}
} else {
	extern (C) extern {
		__gshared int TYptrdiff, TYsize, TYsize_t;
	}
}

import dmd.EnumUtils;
mixin(BringToCurrentScope!(TYM));
