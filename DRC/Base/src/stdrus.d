module stdrus;

private import  exception, runtime;
private import tpl.args, tpl.stream;

import std.base64, std.bitarray, std.path, std.string;


//debug = РегВыр;
//debug = Нить;
import std.io;


extern(Windows) бцел mciSendCommandA(бцел, бцел, бцел, бцел);

	
бцел винВерсия;	
	
static this()
	{	
	винВерсия = win.ДайВерсию();
	
	ВИНСОКДАН вд;

		цел знач;
		знач = ВСАСтарт(0x2020, &вд);
		if(знач) // Request Winsock 2.2 for IPv6.
			throw new СокетИскл("Не удалось инициализовать библиотеку сокетов", знач);
	}
	
	
	        static ~this()
        {
                ВСАЧистка();
        }
		

const т_время т_время_нч = cast(т_время) дол.min;
typedef бцел ФВремяДос;
//typedef сим рсим;
//typedef ткст рткст;

//alias сим рсим;
//alias ткст рткст;

struct т_регсвер
{
    цел рснач;			// индекс начала совпадения
    цел рскон;			// индекс по завершению совпадения
}

export extern(D) class Модуль
{

export:

private  ук м_укМодуль;

	this(ук умодуль, бул овладеть)
	
		in
		{
			assert(null !is умодуль);
		}
		body
		{
			if(овладеть)
			{
				м_укМодуль = адаптВхоУкз(умодуль);
			}
		else
			{
			
			ткст путь = Путь();
			м_укМодуль = cast(ук)ЗагрузиБиблиотекуА(путь);
			if (м_укМодуль == null)
				throw new ИсклВнешнМодуля(ДайПоследнююОшибку());
			}
		}
	
	
	this(ткст имяМодуля)
	
		in
		{
			assert(null !is имяМодуля);
		}
		body
		{
		м_укМодуль = cast(ук) ЗагрузиБиблиотекуА(имяМодуля);
			if (null is м_укМодуль)
			throw new ИсклВнешнМодуля(ДайПоследнююОшибку());
		}
	
	
	~this()
    {
        закрой();
    }
	
	
	проц закрой()
	{
		if(null !is м_укМодуль)
        {
		if(!ОсвободиБиблиотеку(м_укМодуль))
		    throw new ИсклВнешнМодуля(ДайПоследнююОшибку());
		}
	}
	
	ук дайСимвол(in ткст симв)
	in
	{
		assert(симв !is null);		
	}
	body
	{
	ук символ = cast(ук) ДайАдресПроц(м_укМодуль, симв);
	    if(null is символ)
	    {
		throw new ИсклВнешнМодуля(ДайПоследнююОшибку());
	    }
	return адаптВыхУкз(символ);
	}
	
	ук найдиСимвол(in ткст симв)
	{
	return адаптВыхУкз(дайСимволИМодуля(м_укМодуль, симв));
	}
	
	ук Ук()
	{
	return адаптВыхУкз(м_укМодуль);
	}
	
	ткст Путь()
	{
	assert(null != м_укМодуль);
	
	ткст имяФ = new сим[260];
	
	бцел cch = ДайИмяФайлаМодуляА(м_укМодуль, &имяФ, имяФ.length);
	    if (cch == 0)
		throw new ИсклВнешнМодуля(ДайПоследнююОшибку());

	    return имяФ[0 .. cch].dup;
	
	}
}//end of class

export extern(D)
{
	проц инфо(ткст сооб)
			{
			ОкноСооб(null, toUTF16(сооб), "Сообщение Динрус", ПСооб.Инфо|ПСооб.Поверх);
			}

	import std.md5;

	проц суммаМД5(ббайт[16] дайджест, проц[] данные){std.md5.sum(дайджест, данные);}
	проц выведиМД5Дайджест(ббайт дайджест[16]){std.md5.printDigest(дайджест);}
	ткст дайджестМД5вТкст(ббайт[16] дайджест){return std.md5.digestToString(дайджест);}

	import rt.syserror;

	ткст текстСисОшибки(бцел кодош){return  rt.syserror.sysErrorString(кодош);}

	import std.loader;

	цел иницМодуль(){return std.loader.ExeModule_Init();}
	проц деиницМодуль(){return std.loader.ExeModule_Uninit();}
	ук загрузиМодуль(in ткст имямод){return cast(ук) адаптВыхУкз(std.loader.ExeModule_Load(имямод));}
	ук добавьСсылНаМодуль(ук умодуль){return cast(ук) std.loader.ExeModule_AddRef(cast(HXModule) умодуль);}
	проц отпустиМодуль(inout ук умодуль){return std.loader.ExeModule_Release(cast(HXModule) умодуль);}
	ук дайСимволИМодуля(inout ук умодуль, in ткст имяСимвола){return std.loader.ExeModule_GetSymbol(cast(HXModule) умодуль, имяСимвола);}
	ткст ошибкаИМодуля(){return std.loader.ExeModule_Error();}	


	import std.intrinsic;

	цел пуб(бцел х){return std.intrinsic.bsf(х);}//Поиск первого установленного бита (узнаёт его номер)
	цел пубр(бцел х){return std.intrinsic.bsr(х);}//Поиск первого установленного бита (от старшего к младшему)
	цел тб(in бцел *х, бцел номбит){return std.intrinsic.bt(х, номбит);}//Тест бит
	цел тбз(бцел *х, бцел номбит){return std.intrinsic.btc(х, номбит);}// тест и заполнение
	цел тбп(бцел *х, бцел номбит){return std.intrinsic.btr(х, номбит);}// тест и переустановка
	цел тбу(бцел *х, бцел номбит){return std.intrinsic.bts(х, номбит);}// тест и установка
	бцел развербит(бцел б){return std.intrinsic.bswap(б);}//Развернуть биты в байте
	ббайт чипортБб(бцел адр_порта){return std.intrinsic.inp(адр_порта);}//читает порт ввода с указанным адресом
	бкрат чипортБк(бцел адр_порта){return std.intrinsic.inpw(адр_порта);}
	бцел чипортБц(бцел адр_порта){return std.intrinsic.inpl(адр_порта);}
	ббайт пипортБб(бцел адр_порта, ббайт зап){return std.intrinsic.outp(адр_порта, зап);}//пишет в порт вывода с указанным адресом
	бкрат пипортБк(бцел адр_порта, бкрат зап){return std.intrinsic.outpw(адр_порта, зап);}
	бцел пипортБц(бцел адр_порта, бцел зап){return std.intrinsic.outpl(адр_порта, зап);}
	цел члоустбит32( бцел x )
	{
		x = x - ((x>>1) & 0x5555_5555);
		x = ((x&0xCCCC_CCCC)>>2) + (x&0x3333_3333);
		x += (x>>4);
		x &= 0x0F0F_0F0F;
		x += (x>>8);
		x &= 0x00FF_00FF;
		x += (x>>16);
		x &= 0xFFFF;
		return x;
	}

	бцел битсвоп( бцел x )
	{

		version( D_InlineAsm_X86 )
		{
			asm
			{
				// Author: Tiago Gasiba.
				mov EDX, EAX;
				shr EAX, 1;
				and EDX, 0x5555_5555;
				and EAX, 0x5555_5555;
				shl EDX, 1;
				or  EAX, EDX;
				mov EDX, EAX;
				shr EAX, 2;
				and EDX, 0x3333_3333;
				and EAX, 0x3333_3333;
				shl EDX, 2;
				or  EAX, EDX;
				mov EDX, EAX;
				shr EAX, 4;
				and EDX, 0x0f0f_0f0f;
				and EAX, 0x0f0f_0f0f;
				shl EDX, 4;
				or  EAX, EDX;
				bswap EAX;
			}
		}
		else
		{
			x = ((x >> 1) & 0x5555_5555) | ((x & 0x5555_5555) << 1);
			x = ((x >> 2) & 0x3333_3333) | ((x & 0x3333_3333) << 2);
			x = ((x >> 4) & 0x0F0F_0F0F) | ((x & 0x0F0F_0F0F) << 4);
			x = ((x >> 8) & 0x00FF_00FF) | ((x & 0x00FF_00FF) << 8);
			x = ( x >> 16              ) | ( x               << 16);
			return x;

		}
	}
}///extern Windows


export extern(D) struct ПерестановкаБайт
{
export:

        final static проц своп16 (проц[] приёмн)
        {
                своп16 (приёмн.ptr, приёмн.length);
        }


        final static проц своп32 (проц[] приёмн)
        {
                своп32 (приёмн.ptr, приёмн.length);
        }


        final static проц своп64 (проц[] приёмн)
        {
                своп64 (приёмн.ptr, приёмн.length);
        }


        final static проц своп80 (проц[] приёмн)
        {
                своп80 (приёмн.ptr, приёмн.length);
        }


        final static проц своп16 (проц *приёмн, бцел байты)
        {
                assert ((байты & 0x01) is 0);

                auto p = cast(ббайт*) приёмн;
                while (байты)
                      {
                      ббайт b = p[0];
                      p[0] = p[1];
                      p[1] = b;

                      p += крат.sizeof;
                      байты -= крат.sizeof;
                      }
        }


        final static проц своп32 (проц *приёмн, бцел байты)
        {
                assert ((байты & 0x03) is 0);

                auto p = cast(бцел*) приёмн;
                while (байты)
                      {
                      *p = bswap(*p);
                      ++p;
                      байты -= цел.sizeof;
                      }
        }


        final static проц своп64 (проц *приёмн, бцел байты)
        {
                assert ((байты & 0x07) is 0);

                auto p = cast(бцел*) приёмн;
                while (байты)
                      {
                      бцел i = p[0];
                      p[0] = bswap(p[1]);
                      p[1] = bswap(i);

                      p += (дол.sizeof / цел.sizeof);
                      байты -= дол.sizeof;
                      }
        }


        final static проц своп80 (проц *приёмн, бцел байты)
        {
                assert ((байты % 10) is 0);
               
                auto p = cast(ббайт*) приёмн;
                while (байты)
                      {
                      ббайт b = p[0];
                      p[0] = p[9];
                      p[9] = b;

                      b = p[1];
                      p[1] = p[8];
                      p[8] = b;

                      b = p[2];
                      p[2] = p[7];
                      p[7] = b;

                      b = p[3];
                      p[3] = p[6];
                      p[6] = b;

                      b = p[4];
                      p[4] = p[5];
                      p[5] = b;

                      p += 10;
                      байты -= 10;
                      }
        }
}///end of struct

typedef extern (D) ткст function(дим) Обрвызов_диэксп_Дим;

export extern(D)
{	

	бул вОбразце(дим с, ткст образец){return cast(бул) std.string.inPattern(с, образец);}
	бул вОбразце(дим с, ткст[] образец){return cast(бул) std.string.inPattern(с, образец);}
	
	проц пишиф(...)/////
	{
	auto args = _arguments;
	std.io.writefx( cidrus.стдвых, _arguments, _argptr, 0);
	}

	проц пишифнс(...)//////
	{
	std.io.writefx( cidrus.стдвых, _arguments, _argptr, 1);
	}
	
	проц скажифнс(...)//////
	{
	auto args = _arguments;
    auto argptr = _argptr;
   // ткст fmt = null;
    //разборСпискаАргументов(args, argptr, fmt);
	
    ткст т;

    проц putc(дим c)
    {
	std.utf.encode(т, c);
    }

		форматДелай(&putc, args, argptr);
		win.скажинс(т);
	}
	
	проц скажиф(...)///////
	{
	auto args = _arguments;
    auto argptr = _argptr;
   // ткст fmt = null;
    //разборСпискаАргументов(args, argptr, fmt);
	
    ткст т;

    проц putc(дим c)
    {
	std.utf.encode(т, c);
    }

		форматДелай(&putc, args, argptr);
		win.скажи(т);
	}
	
	проц пишиф_в(cidrus.фук чф, ...)//////
	{
	
		std.io.writefx( чф, _arguments, _argptr, 0);
	}

	проц пишифнс_в(cidrus.фук чф, ...)///////
	{
		std.io.writefx( чф, _arguments, _argptr, 1);
	}
	
	ткст фм(...)//////
	{
	auto args = _arguments;
    auto argptr = _argptr;
   // ткст fmt = null;
    //разборСпискаАргументов(args, argptr, fmt);
	
    ткст т;

    проц putc(дим c)
    {
	std.utf.encode(т, c);
    }

		форматДелай(&putc, args, argptr);
		return т;
	}
alias фм форматируй;
	
	ткст форматируйс(ткст т, ...)
	{   
	
	т_мера i;

		проц putc(дим c)
		{
		if (c <= 0x7F)
		{
			if (i >= т.length)
			throw new ГранМасОшиб("stdrus.форматируйс", __LINE__);
			т[i] = cast(сим)c;
			++i;
		}
		else
		{   сим[4] буф;
			ткст b;

			b = std.utf.toUTF8(буф, c);
			if (i + b.length > т.length)
		throw new ГранМасОшиб("stdrus.форматируйс", __LINE__);
			т[i..i+b.length] = b[];
			i += b.length;
		}
		}

		форматДелай(&putc, _arguments, _argptr);
		return т[0 .. i];
	}
}/////extern D
///////////////////////////////////////////////////
export extern(D)
{
	import std.demangle;

	ткст разманглируй(ткст имя){return std.demangle.demangle(имя);}

	бцел кодируйДлину64(бцел сдлин)
		{
		return cast(бцел) encodeLength(cast(бцел) сдлин);
		}
	ткст кодируй64(ткст стр, ткст буф = ткст.init)
		{
		if(буф)	return cast(ткст) std.base64.encode(cast(сим[]) стр, cast(сим[]) буф);
		else return cast(ткст) std.base64.encode(cast(сим[])стр);
		}

	бцел раскодируйДлину64(бцел кдлин)
		{
		return cast(бцел) decodeLength(cast(бцел) кдлин);
		}
	ткст раскодируй64(ткст кстр, ткст буф = ткст.init)
		{
		if(буф) return cast(ткст) std.base64.decode(cast(сим[]) кстр, cast(сим[]) буф);
		else return cast(ткст) std.base64.decode(cast(сим[]) кстр);
		}

import rt.charset;

///////////////////////////////////////////////////////
ткст0 ю8Вин16н(ткст с, бцел кодСтр = 0)
{
return cast(усим) rt.charset.toMBSz(cast(char[]) с, cast(uint) кодСтр);
}
////////////////////////////////////////////////////////////
ткст вин16нЮ8(ткст0 с, цел кодСтр = 0)
{
return cast(сим[]) rt.charset.fromMBSz(cast(char*) с, cast(int) кодСтр);
}
////////////////////////////////////////////////////////////

	т_мера читайстр(inout ткст буф = ткст.init)
	{
	/+
		DWORD i = буф.length / 4;
		const Кф = -1;
		шим[] ввод = new шим [1024 * 1];

                                   assert (i);

                                   if (i > ввод.length)
                                       i = ввод.length;
                                       
                                   // читай a chunk of wchars из_ the console
                                   if (! ReadConsoleW (ДайСтдДескр(ПСтд.Ввод), ввод.ptr, i, &i, null))
                                         exception.ошибка("Неудачное чтение консоли");

                                   // no ввод ~ go home
                                   if (i is 0)
                                       return Кф;

                                   // translate в_ utf8, directly преобр_в приёмн
                                   i = sys.WinFuncs.WideCharToMultiByte (65001, 0, ввод.ptr, i, 
                                                            cast(PCHAR) буф.ptr, буф.length, null, 0);
                                   if (i is 0)
                                       exception.ошибка ("Неудачное преобразование консольного вввода");

                                   return i;
								   +/
		return читайстр(cidrus.стдвхо, буф);
								   
	}
	
	т_мера читайстр(фук чф, inout ткст буф)
	{	
	return std.io.readln(чф, буф);
	}

	проц скажи(ткст ткт){ win.скажи(ткт);}
	проц скажинс(ткст ткт){ win.скажинс(ткт);}
	проц скажи(бдол ткт){ win.скажи(ткт);}
	проц скажинс(бдол ткт){ win.скажинс(ткт);}

	проц нс(){win.нс();}
	проц таб(){win.таб();}	
	
	import std.ctype;

	цел числобукв_ли(дим б){return std.ctype.isalnum(б);}
	цел буква_ли(дим б){return  std.ctype.isalpha(б);}
	цел управ_ли(дим б){return std.ctype.iscntrl(б);}
	цел цифра_ли(дим б){return std.ctype.isdigit(б);}
	цел проп_ли(дим б){return std.ctype.islower(б);}
	цел пунктзнак_ли(дим б){return  std.ctype.ispunct(б);}
	цел межбукв_ли(дим б){return std.ctype.isspace(б);}
	цел заг_ли(дим б){return std.ctype.isupper(б);}
	цел цифраикс_ли(дим б){return std.ctype.isxdigit(б);}
	цел граф_ли(дим б){return  std.ctype.isgraph(б);}
	цел печат_ли(дим б) {return  std.ctype.isprint(б);}
	цел аски_ли(дим б){return  std.ctype.isascii(б);}
	дим впроп(дим б){return  std.ctype.tolower(б);}
	дим взаг(дим б){return std.ctype.toupper(б);}
}//////////// extern C
///////////////////////////////////////
export extern(D) struct МассивБит
{
    т_мера длин;
    бцел* укз;
	
	alias  укз ptr;

	export т_мера разм()
	{
	return cast(т_мера) dim();
	}
	
    т_мера dim()
    {
	return (длин + 31) / 32;
    }
	
	export т_мера длина()
	{
	return cast(т_мера) length();
	}
	
    т_мера length()
    {
	return длин;
    }

	export проц длина(т_мера новдлин)
	{
	return length(новдлин);
	}
	
    проц length(т_мера newlen)
    {
	if (newlen != длин)
	{
	    т_мера olddim = dim();
	    т_мера newdim = (newlen + 31) / 32;

	    if (newdim != olddim)
	    {
		// Create a fake array so we can use D'т realloc machinery
		бцел[] b = ptr[0 .. olddim];
		b.length = newdim;		// realloc
		ptr = b.ptr;
		if (newdim & 31)
		{   // Уст any pad bits to 0
		    ptr[newdim - 1] &= ~(~0 << (newdim & 31));
		}
	    }

	    длин = newlen;
	}
    }

  export  бул opIndex(т_мера i)
    in
    {
	assert(i < длин);
    }
    body
    {
	return cast(бул)bt(ptr, i);
    }

    /** ditto */
   export бул opIndexAssign(бул b, т_мера i)
    in
    {
	assert(i < длин);
    }
    body
    {
	if (b)
	    bts(ptr, i);
	else
	    btr(ptr, i);
	return b;
    }

   
	export МассивБит дубль()
	 {
	 return dup();
	 }
	 
    МассивБит dup()
    {
	МассивБит ba;

	бцел[] b = ptr[0 .. dim].dup;
	ba.длин = длин;
	ba.ptr = b.ptr;
	return ba;
    }

   export цел opApply(цел delegate(inout бул) дг)
    {
	цел результат;

	for (т_мера i = 0; i < длин; i++)
	{   бул b = opIndex(i);
	    результат = дг(b);
	    (*this)[i] = b;
	    if (результат)
		break;
	}
	return результат;
    }

  
   export цел opApply(цел delegate(inout т_мера, inout бул) дг)
    {
	цел результат;

	for (т_мера i = 0; i < длин; i++)
	{   бул b = opIndex(i);
	    результат = дг(i, b);
	    (*this)[i] = b;
	    if (результат)
		break;
	}
	return результат;
    }

	export МассивБит реверсни()
	{
	return  reverse();
	}
	
    МассивБит reverse()
	out (результат)
	{
	    assert(результат == *this);
	}
	body
	{
	    if (длин >= 2)
	    {
		бул t;
		т_мера lo, hi;

		lo = 0;
		hi = длин - 1;
		for (; lo < hi; lo++, hi--)
		{
		    t = (*this)[lo];
		    (*this)[lo] = (*this)[hi];
		    (*this)[hi] = t;
		}
	    }
	    return *this;
	}

  
	export МассивБит сортируй()
	{
	return sort();
	}
	
    МассивБит sort()
	out (результат)
	{
	    assert(результат == *this);
	}
	body
	{
	    if (длин >= 2)
	    {
		т_мера lo, hi;

		lo = 0;
		hi = длин - 1;
		while (1)
		{
		    while (1)
		    {
			if (lo >= hi)
			    goto Ldone;
			if ((*this)[lo] == да)
			    break;
			lo++;
		    }

		    while (1)
		    {
			if (lo >= hi)
			    goto Ldone;
			if ((*this)[hi] == нет)
			    break;
			hi--;
		    }

		    (*this)[lo] = нет;
		    (*this)[hi] = да;

		    lo++;
		    hi--;
		}
	    Ldone:
		;
	    }
	    return *this;
	}

    export цел opEquals(МассивБит a2)
    {   цел i;

	if (this.length != a2.length)
	    return 0;		// not equal
	байт *p1 = cast(байт*)this.ptr;
	байт *p2 = cast(байт*)a2.ptr;
	бцел n = this.length / 8;
	for (i = 0; i < n; i++)
	{
	    if (p1[i] != p2[i])
		return 0;		// not equal
	}

	ббайт маска;

	n = this.length & 7;
	маска = cast(ббайт)((1 << n) - 1);
	//prцелf("i = %d, n = %d, маска = %x, %x, %x\n", i, n, маска, p1[i], p2[i]);
	return (маска == 0) || (p1[i] & маска) == (p2[i] & маска);
    }

   export цел opCmp(МассивБит a2)
    {
	бцел длин;
	бцел i;

	длин = this.length;
	if (a2.length < длин)
	    длин = a2.length;
	ббайт* p1 = cast(ббайт*)this.ptr;
	ббайт* p2 = cast(ббайт*)a2.ptr;
	бцел n = длин / 8;
	for (i = 0; i < n; i++)
	{
	    if (p1[i] != p2[i])
		break;		// not equal
	}
	for (бцел j = i * 8; j < длин; j++)
	{   ббайт маска = cast(ббайт)(1 << j);
	    цел c;

	    c = cast(цел)(p1[i] & маска) - cast(цел)(p2[i] & маска);
	    if (c)
		return c;
	}
	return cast(цел)this.длин - cast(цел)a2.length;
    }

	export проц иниц(бул[] бм)
	{
	init(cast(бул[]) бм);
	}
	
    проц init(бул[] ba)
    {
	length = ba.length;
	foreach (i, b; ba)
	{
	    (*this)[i] = b;
	}
    }

	export проц иниц(проц[] в, т_мера члобит)
	{
	init(cast(проц[]) в, cast(т_мера) члобит);
	}
	
    проц init(проц[] v, т_мера numbits)
    in
    {
	assert(numbits <= v.length * 8);
	assert((v.length & 3) == 0);
    }
    body
    {
	ptr = cast(бцел*)v.ptr;
	длин = numbits;
    }

  export  проц[] opCast()
    {
	return cast(проц[])ptr[0 .. dim];
    }

    
  export  МассивБит opCom()
    {
	auto dim = this.dim();

	МассивБит результат;

	результат.length = длин;
	for (т_мера i = 0; i < dim; i++)
	    результат.ptr[i] = ~this.ptr[i];
	if (длин & 31)
	    результат.ptr[dim - 1] &= ~(~0 << (длин & 31));
	return результат;
    }

  export  МассивБит opAnd(МассивБит e2)
    in
    {
	assert(длин == e2.length);
    }
    body
    {
	auto dim = this.dim();

	МассивБит результат;

	результат.length = длин;
	for (т_мера i = 0; i < dim; i++)
	    результат.ptr[i] = this.ptr[i] & e2.ptr[i];
	return результат;
    }

    export МассивБит opOr(МассивБит e2)
    in
    {
	assert(длин == e2.length);
    }
    body
    {
	auto dim = this.dim();

	МассивБит результат;

	результат.length = длин;
	for (т_мера i = 0; i < dim; i++)
	    результат.ptr[i] = this.ptr[i] | e2.ptr[i];
	return результат;
    }

   export МассивБит opXor(МассивБит e2)
    in
    {
	assert(длин == e2.length);
    }
    body
    {
	auto dim = this.dim();

	МассивБит результат;

	результат.length = длин;
	for (т_мера i = 0; i < dim; i++)
	    результат.ptr[i] = this.ptr[i] ^ e2.ptr[i];
	return результат;
    }

  export  МассивБит opSub(МассивБит e2)
    in
    {
	assert(длин == e2.length);
    }
    body
    {
	auto dim = this.dim();

	МассивБит результат;

	результат.length = длин;
	for (т_мера i = 0; i < dim; i++)
	    результат.ptr[i] = this.ptr[i] & ~e2.ptr[i];
	return результат;
    }

   export МассивБит opAndAssign(МассивБит e2)
    in
    {
	assert(длин == e2.length);
    }
    body
    {
	auto dim = this.dim();

	for (т_мера i = 0; i < dim; i++)
	    ptr[i] &= e2.ptr[i];
	return *this;
    }

   export МассивБит opOrAssign(МассивБит e2)
    in
    {
	assert(длин == e2.length);
    }
    body
    {
	auto dim = this.dim();

	for (т_мера i = 0; i < dim; i++)
	    ptr[i] |= e2.ptr[i];
	return *this;
    }

   export МассивБит opXorAssign(МассивБит e2)
    in
    {
	assert(длин == e2.length);
    }
    body
    {
	auto dim = this.dim();

	for (т_мера i = 0; i < dim; i++)
	    ptr[i] ^= e2.ptr[i];
	return *this;
    }

   export МассивБит opSubAssign(МассивБит e2)
    in
    {
	assert(длин == e2.length);
    }
    body
    {
	auto dim = this.dim();

	for (т_мера i = 0; i < dim; i++)
	    ptr[i] &= ~e2.ptr[i];
	return *this;
    }

    export МассивБит opCatAssign(бул b)
    {
	length = длин + 1;
	(*this)[длин - 1] = b;
	return *this;
    }

   export МассивБит opCatAssign(МассивБит b)
    {
	auto istart = длин;
	length = длин + b.length;
	for (auto i = istart; i < длин; i++)
	    (*this)[i] = b[i - istart];
	return *this;
    }

   export МассивБит opCat(бул b)
    {
	МассивБит r;

	r = this.dup;
	r.length = длин + 1;
	r[длин] = b;
	return r;
    }

   export МассивБит opCat_r(бул b)
    {
	МассивБит r;

	r.length = длин + 1;
	r[0] = b;
	for (т_мера i = 0; i < длин; i++)
	    r[1 + i] = (*this)[i];
	return r;
    }

  export  МассивБит opCat(МассивБит b)
    {
	МассивБит r;

	r = this.dup();
	r ~= b;
	return r;
    }

}/////end of class

МассивБит вМасБит(std.bitarray.BitArray ба)
	{
	МассивБит рез;
	рез.длин = ба.длин;
	рез.укз = ба.ptr;
	return  рез;
	}
	
BitArray изМасБита(МассивБит мб)
	{
	std.bitarray.BitArray рез;
	рез.длин = мб.длин;
	рез.ptr = мб.укз;
	return  рез;
	}

/*************************/
////////////////////////////////////////////
import std.string, std.utf;

export extern(D)
{	/////////////////////////////////
	бул пробел_ли(дим т)
	{
	return cast(бул)(std.string.iswhite(cast(дим) т));
	}
	/////////////////////////////
	дол ткствцел(ткст т)
	{
	return cast(дол)(std.string.atoi(cast(сим[]) т));
	}
	/////////////////////////////////
	реал ткствдробь(ткст т)
	{
	return cast(реал)(std.string.atof(cast(сим[]) т));
	}
	/////////////////////////////////////
	цел сравни(ткст s1, ткст s2)
	{
	return cast(цел)(std.string.cmp(cast(сим[]) s1, cast(сим[]) s2));
	}
	///////////////////////////////////////
	цел сравнлюб(ткст s1, ткст s2)
	{
	return cast(цел)(std.string.icmp(cast(сим[]) s1, cast(сим[]) s2));
	}
	/////////////////////////////////////////////
	сим* вТкст0(ткст т)
	{
	return cast(сим*)(std.string.toStringz(cast(сим[]) т));
	}
	/////////////////////////////////////////////
	цел найди(ткст т, дим c)
	{
	return cast(цел)(std.string.find(cast(сим[]) т, cast(дим) c));
	}
	/////////////////////////////////////////////////
	цел найдлюб(ткст т, дим c)
	{
	return cast(цел)(std.string.ifind(cast(сим[]) т, cast(дим) c));
	}
	////////////////////////////////////////////////
	цел найдрек(ткст т, дим c)
	{
	return cast(цел)(std.string.rfind(cast(сим[]) т, cast(дим) c));
	}
	///////////////////////////////////////////////
	цел найдлюбрек(ткст т, дим c)
	{
	return cast(цел)(std.string.irfind(cast(сим[]) т, cast(дим) c));
	}
	/////////////////////////////////////////////////
	цел найди(ткст т, ткст тзам)
	{
	return cast(цел)(std.string.find(cast(сим[]) т, cast(сим[]) тзам));
	}
	/////////////////////////////////////////////////
	цел найдлюб(ткст т, ткст тзам)
	{
	return  cast(цел)(std.string.ifind(cast(сим[]) т, cast(сим[]) тзам));
	}
	/////////////////////////////////////////////////
	цел найдрек(ткст т, ткст тзам)
	{
	return  cast(цел)(std.string.rfind(cast(сим[]) т, cast(сим[]) тзам));
	}
	///////////////////////////////////////////////
	цел найдлюбрек(ткст т, ткст тзам)
	{
	return  cast(цел)(std.string.irfind(cast(сим[]) т, cast(сим[]) тзам));
	}
	//////////////////////////////////////////////
	ткст впроп(ткст т)
	{
	return cast(ткст)(std.string.tolower(cast(ткст) т));
	}
	//////////////////////////////////////////////////
	ткст взаг(ткст т)
	{
	return cast(ткст)(std.string.toupper(cast(ткст) т));
	}
	////////////////////////////////////////////////////
	ткст озаг(ткст т){return std.string.capitalize(т);}
	////////////////////////////////////////////////////
	ткст озагслова(ткст т){return std.string.capwords(т);}
	/////////////////////////////////////////////
	ткст повтори(ткст т, т_мера м){return std.string.repeat(т, м);}
	///////////////////////////////////////////
	ткст объедини(ткст[] слова, ткст разд){return  std.string.join(слова, разд);}
	///////////////////////////////////////
	ткст[] разбей(ткст т){ткст м_т = т; return std.string.split(м_т);}
	ткст[] разбейдоп(ткст т, ткст разделитель){ткст м_т = т; ткст м_разделитель = разделитель; return std.string.split(м_т, м_разделитель);}
	//////////////////////////////
	ткст[] разбейнастр(ткст т){return std.string.splitlines(т);}
	////////////////////////
	ткст уберислева(ткст т){return  std.string.stripl(т);}
	ткст уберисправа(ткст т){return  std.string.stripr(т);}
	ткст убери(ткст т){return  std.string.strip(т);}
	///////////////////////////
	ткст убериразгр(ткст т){return  std.string.chomp(т);}
	ткст уберигран(ткст т){return  std.string.chop(т);}
	/////////////////
	ткст полев(ткст т, цел ширина){return  ljustify(т, ширина);}
	ткст поправ(ткст т, цел ширина){return  rjustify(т, ширина);}
	ткст вцентр(ткст т, цел ширина){return  center(т, ширина);}
	ткст занули(ткст т, цел ширина){return  zfill(т, ширина);}
	
	ткст замени(ткст т, ткст с, ткст на){ ткст м_т = т.dup; ткст м_с = т.dup; ткст м_на = т.dup; return  std.string.replace(м_т, м_с, м_на);}
	ткст заменисрез(ткст т, ткст срез, ткст замена){ткст м_т = т; ткст м_срез = срез; ткст м_замена = замена; return  std.string.replaceSlice(м_т, м_срез, м_замена);}
	ткст вставь(ткст т, т_мера индекс, ткст подст){ return  std.string.insert(т, индекс, подст);}
	т_мера счесть(ткст т, ткст подст){return  std.string.count(т, подст);}


	ткст заменитабнапбел(ткст стр, цел размтаб=8){return std.string.expandtabs(стр, размтаб);}
	ткст заменипбелнатаб(ткст стр, цел размтаб=8){return std.string.entab(стр, размтаб);}
	ткст постройтранстаб(ткст из, ткст в){return maketrans(из, в);}
	ткст транслируй(ткст т, ткст табтранс, ткст удсим){return translate(т, табтранс, удсим);}
		

	т_мера посчитайсимв(ткст т, ткст образец){return  std.string.countchars(т, образец);}
	ткст удалисимв(ткст т, ткст образец){return  std.string.removechars(т, образец);}
	ткст сквиз(ткст т, ткст образец= null){return  std.string.squeeze(cast(сим[]) т, cast(сим[]) образец);}
	ткст следщ(ткст т){return std.string.succ(т);}
	
	ткст тз(ткст ткт, ткст из, ткст в, ткст модифф = null){return std.string.tr(ткт, из, в, модифф);}
	бул чис_ли(in ткст т, in бул раздВкл = false){return cast(бул) std.string.isNumeric(т, раздВкл);}
	т_мера колном(ткст ткт, цел размтаб=8){return std.string.column(ткт, размтаб);}
	ткст параграф(ткст т, цел колонки = 80, ткст первотступ = null, ткст отступ = null, цел размтаб = 8){return std.string.wrap(т, колонки, первотступ, отступ, размтаб);}
	ткст эладр_ли(ткст т){return  std.string.isEmail(т);}
	ткст урл_ли(ткст т){return  std.string.isURL(т);}
	ткст целВЮ8(ткст врем, бцел знач){return std.string.intToUtf8(врем, знач);}
	ткст бдолВЮ8(ткст врем, бцел знач){return std.string.ulongToUtf8(врем, знач);}

import std.conv;

	цел вЦел(ткст т){return std.conv.toInt(т);}
	бцел вБцел(ткст т){return std.conv.toUint(т);}
	дол вДол(ткст т){return std.conv.toLong(т);}
	бдол вБдол(ткст т){return std.conv.toUlong(т);}
	крат вКрат(ткст т){return std.conv.toShort(т);}
	бкрат вБкрат(ткст т){return std.conv.toUshort(т);}  
	байт вБайт(ткст т){return std.conv.toByte(т);}
	ббайт вБбайт(ткст т){return std.conv.toUbyte(т);} 
	плав вПлав(ткст т){return std.conv.toFloat(т);}   
	дво вДво(ткст т){return std.conv.toDouble(т);} 
	реал вРеал(ткст т){return std.conv.toReal(т);}

}///extern C
////////////////////////////

enum ПМангл : сим
{
    Тпроц     = 'v',
    Тбул     = 'b',
    Тбайт     = 'g',
    Тббайт    = 'h',
    Ткрат    = 's',
    Тбкрат   = 't',
    Тцел      = 'i',
    Тбцел     = 'k',
    Тдол     = 'l',
    Тбдол    = 'm',
    Тплав    = 'f',
    Тдво   = 'd',
    Треал     = 'e',

    Твплав   = 'o',
    Твдво  = 'p',
    Твреал    = 'j',
    Ткплав   = 'q',
    Ткдво  = 'r',
    Ткреал    = 'c',

    Тсим     = 'a',
    Тшим    = 'u',
    Тдим    = 'w',

    Тмассив    = 'A',
    Тсмассив   = 'G',
    Тамассив   = 'H',
    Туказатель  = 'P',
    Тфункция = 'F',
    Тидент    = 'I',
    Ткласс    = 'C',
    Тструкт   = 'S',
    Тперечень     = 'E',
    Ттипдеф  = 'T',
    Тделегат = 'D',

    Тконст    = 'x',
    Тинвариант = 'y',
}

export extern(D) ИнфОТипе простаяИнфОТипе(ПМангл м) 
{
  ИнфОТипе ti;

  switch (м)
    {
    case ПМангл.Тпроц:
      ti = typeid(проц);break;
    case ПМангл.Тбул:
      ti = typeid(бул);break;
    case ПМангл.Тбайт:
      ti = typeid(байт);break;
    case ПМангл.Тббайт:
      ti = typeid(ббайт);break;
    case ПМангл.Ткрат:
      ti = typeid(крат);break;
    case ПМангл.Тбкрат:
      ti = typeid(бкрат);break;
    case ПМангл.Тцел:
      ti = typeid(цел);break;
    case ПМангл.Тбцел:
      ti = typeid(бцел);break;
    case ПМангл.Тдол:
      ti = typeid(дол);break;
    case ПМангл.Тбдол:
      ti = typeid(бдол);break;
    case ПМангл.Тплав:
      ti = typeid(плав);break;
    case ПМангл.Тдво:
      ti = typeid(дво);break;
    case ПМангл.Треал:
      ti = typeid(реал);break;
    case ПМангл.Твплав:
      ti = typeid(вплав);break;
    case ПМангл.Твдво:
      ti = typeid(вдво);break;
    case ПМангл.Твреал:
      ti = typeid(вреал);break;
    case ПМангл.Ткплав:
      ti = typeid(кплав);break;
    case ПМангл.Ткдво:
      ti = typeid(кдво);break;
    case ПМангл.Ткреал:
      ti = typeid(креал);break;
    case ПМангл.Тсим:
      ti = typeid(сим);break;
    case ПМангл.Тшим:
      ti = typeid(шим);break;
    case ПМангл.Тдим:
      ti = typeid(дим);break;
    default:
      ti = null;
    }
  return ti;
}

version (Windows)
{
    version (DigitalMars)
    {
	version = DigitalMarsC;
    }
}

version (DigitalMarsC)
{
    // This is DMC'т internal floating poцел formatting function
    extern  (C)
    {
	extern  сим* function(цел c, цел флаги, цел точность, реал* pdзнач,
	    сим* буф, цел* psl, цел width) __pfloatfmt;
    }
}
else
{
    // Use C99 snprцелf
    extern  (C) цел snprintf(сим* т, т_мера n, сим* format, ...);
}

export extern(D)
{
	ткст вТкст(бул с){return std.string.toString(с);}
	ткст вТкст(сим с)
	{
		ткст результат = new сим[2];
		результат[0] = с;
		результат[1] = 0;
		return результат[0 .. 1];
	}
	ткст вТкст(ббайт с){return std.string.toString(с);}
	ткст вТкст(бкрат с){return std.string.toString(с);}
	ткст вТкст(бцел с){return std.string.toString(с);}
	ткст вТкст(бдол с){return std.string.toString(с);}
	ткст вТкст(байт с){return std.string.toString(с);}
	ткст вТкст(крат с){return std.string.toString(с);}
	ткст вТкст(цел с){return std.string.toString(с);}
	ткст вТкст(дол с){return std.string.toString(с);}
	ткст вТкст(плав с){return std.string.toString(с);}
	ткст вТкст(дво с){return std.string.toString(с);}
	ткст вТкст(реал с){return std.string.toString(с);}
	ткст вТкст(вплав с){return std.string.toString(с);}
	ткст вТкст(вдво с){return std.string.toString(с);}
	ткст вТкст(вреал с){return std.string.toString(с);}
	ткст вТкст(кплав с){return std.string.toString(с);}
	ткст вТкст(кдво с){return std.string.toString(с);}
	ткст вТкст(креал с){return std.string.toString(с);}
	ткст вТкст(дол знач, бцел корень){return std.string.toString(знач, корень);}
	ткст вТкст(бдол знач, бцел корень){return std.string.toString(знач, корень);}
	ткст вТкст(сим *с){return std.string.toString(с);}
	
	проц разборСпискаАргументов(ref ИнфОТипе[] args, ref спис_ва argptr, out ткст format)
	 {
	  if (args.length == 2 && args[0] == typeid(ИнфОТипе[]) && args[1] == typeid(спис_ва)) {
		args = ва_арг!(ИнфОТипе[])(argptr);
		argptr = *cast(спис_ва*)argptr;

		if (args.length > 1 && args[0] == typeid(ткст)) {
		  format = ва_арг!(ткст)(argptr);
		  args = args[1 .. $];
		}

		if (args.length == 2 && args[0] == typeid(ИнфОТипе[]) && args[1] == typeid(спис_ва)) {
		  разборСпискаАргументов(args, argptr, format);
		}
	  }
	  else if (args.length > 1 && args[0] == typeid(ткст)) {
		format = ва_арг!(ткст)(argptr);
		args = args[1 .. $];
	  }
	} 
/*
auto args = _arguments;
    auto argptr = _argptr;
    ткст fmt = null;
    разборСпискаАргументов(args, argptr, fmt);
*/
проц форматДелай(проц delegate(дим) putc, ИнфОТипе[] arguments, спис_ва argptr)
	{
	цел j;
    ИнфОТипе ti;
    ПМангл m;
    бцел флаги;
    цел ширина_поля;
    цел точность;

    enum : бцел
    {
	FLdash = 1,
	FLplus = 2,
	FLspace = 4,
	FLhash = 8,
	FLlngdbl = 0x20,
	FL0pad = 0x40,
	FLprecision = 0x80,
    }
    
    static ИнфОТипе skipCI(ИнфОТипе типзнач)
    {
      while (1)
      {
	if (типзнач.classinfo.name.length == 18 &&  типзнач.classinfo.name[9..18] == "Invariant")
	    типзнач =	(cast(TypeInfo_Invariant)типзнач).следщ;
	else if (типзнач.classinfo.name.length == 14 && типзнач.classinfo.name[9..14] == "Const")
	    типзнач =	(cast(TypeInfo_Const)типзнач).следщ;
	else
	    break;
      }
      return типзнач;
    }

    проц formatArg(сим fc)
    {
	бул vbit;
	бдол vnumber;
	сим vchar;
	дим vdchar;
	Объект vobject;
	реал vreal;
	креал vcreal;
	ПМангл m2;
	цел signed = 0;
	бцел base = 10;
	цел uc;
	сим[бдол.sizeof * 8] tmpbuf;	// дол enough to print дол in binary
	сим* prefix = "";
	ткст т;

	проц putstr(ткст т)
	{
	    //эхо("флаги = x%x\n", флаги);
		//win.скажинс(т);
	    цел prepad = 0;
	    цел postpad = 0;
		цел padding = ширина_поля - (cidrus.strlen(prefix) + т.length);//toUCSindex(т, т.length));
	    if (padding > 0)
	    {
		if (флаги & FLdash)
		    postpad = padding;
		else
		    prepad = padding;
	    }

	    if (флаги & FL0pad)
	    {
		while (*prefix)
		    putc(*prefix++);
		while (prepad--)
		    putc('0');
	    }
	    else
	    {
		while (prepad--)
		    putc(' ');
		while (*prefix)
		    putc(*prefix++);
	    }

	    foreach (дим c; т)
		putc(c);

	    while (postpad--)
		putc(' ');
	}

	проц putreal(реал v)
	{
	    //эхо("putreal %Lg\n", vreal);

	    switch (fc)
	    {
		case 's':
		    fc = 'g';
		    break;

		case 'f', 'F', 'e', 'E', 'g', 'G', 'a', 'A':
		    break;

		default:
		    //эхо("fc = '%c'\n", fc);
		Lerror:
		    throw new ФорматИскл("плавающая запятая");
	    }
	    version (DigitalMarsC)
	    {
		цел sl;
		ткст fbuf = tmpbuf;
		if (!(флаги & FLprecision))
		    точность = 6;
		while (1)
		{
		    sl = fbuf.length;
		    prefix = (*__pfloatfmt)(fc, флаги | FLlngdbl,
			    точность, &v, cast(сим*)fbuf, &sl, ширина_поля);
		    if (sl != -1)
			break;
		    sl = fbuf.length * 2;
		    fbuf = (cast(сим*)cidrus.разместа(sl * сим.sizeof))[0 .. sl];
		}
		debug(PutStr) win.скажинс("путстр1");
		putstr(fbuf[0 .. sl]);
	    }
	    else
	    {
		цел sl;
		ткст fbuf = tmpbuf;
		сим[12] format;
		format[0] = '%';
		цел i = 1;
		if (флаги & FLdash)
		    format[i++] = '-';
		if (флаги & FLplus)
		    format[i++] = '+';
		if (флаги & FLspace)
		    format[i++] = ' ';
		if (флаги & FLhash)
		    format[i++] = '#';
		if (флаги & FL0pad)
		    format[i++] = '0';
		format[i + 0] = '*';
		format[i + 1] = '.';
		format[i + 2] = '*';
		format[i + 3] = 'L';
		format[i + 4] = fc;
		format[i + 5] = 0;
		if (!(флаги & FLprecision))
		    точность = -1;
		while (1)
		{   цел n;

		    sl = fbuf.length;
		    n = snprintf(fbuf.ptr, sl, format.ptr, ширина_поля, точность, v);
		    //эхо("format = '%s', n = %d\n", cast(сим*)format, n);
		    if (n >= 0 && n < sl)
		    {	sl = n;
			break;
		    }
		    if (n < 0)
			sl = sl * 2;
		    else
			sl = n + 1;
		    fbuf = (cast(сим*)cidrus.разместа(sl * сим.sizeof))[0 .. sl];
		}
		debug(PutStr) win.скажинс("путстр2");
		putstr(fbuf[0 .. sl]);
	    }
	    return;
	}

	static ПМангл getMan(ИнфОТипе ti)
	{
	  auto m = cast(ПМангл)ti.classinfo.name[9];
	  if (ti.classinfo.name.length == 20 &&
	      ti.classinfo.name[9..20] == "StaticArray")
		m = cast(ПМангл)'G';
	  return m;
	}

	проц putArray(ук p, т_мера длин, ИнфОТипе типзнач)
	{
	  //эхо("\nputArray(длин = %u), tsize = %u\n", длин, типзнач.tsize());
	  putc('[');
	  типзнач = skipCI(типзнач);
	  т_мера tsize = типзнач.tsize();
	  auto argptrSave = argptr;
	  auto tiSave = ti;
	  auto mSave = m;
	  ti = типзнач;
	  //эхо("\n%.*т\n", типзнач.classinfo.name);
	  m = getMan(типзнач);
	  while (длин--)
	  {
	    //doFormat(putc, (&типзнач)[0 .. 1], p);
	    argptr = адаптВхоУкз(p);
	    formatArg('s');

	    p += tsize;
	    if (длин > 0) putc(',');
	  }
	  m = mSave;
	  ti = tiSave;
	  argptr = argptrSave;
	  putc(']');
	}

	проц putAArray(ббайт[дол] vaa, ИнфОТипе типзнач, ИнфОТипе keyti)
	{
	  putc('[');
	  бул comma=нет;
	  auto argptrSave = argptr;
	  auto tiSave = ti;
	  auto mSave = m;
	  типзнач = skipCI(типзнач);
	  keyti = skipCI(keyti);
	  foreach(inout fakevalue; vaa)
	  {
	    if (comma) putc(',');
	    comma = да;
	    // the key comes before the значение
	    ббайт* key = &fakevalue - дол.sizeof;

	    //doFormat(putc, (&keyti)[0..1], key);
	    argptr = key;
	    ti = keyti;
	    m = getMan(keyti);
	    formatArg('s');

	    putc(':');
	    auto keysize = keyti.tsize;
	    keysize = (keysize + 3) & ~3;
	    ббайт* значение = key + keysize;
	    //doFormat(putc, (&типзнач)[0..1], значение);
	    argptr = значение;
	    ti = типзнач;
	    m = getMan(типзнач);
	    formatArg('s');
	  }
	  m = mSave;
	  ti = tiSave;
	  argptr = argptrSave;
	  putc(']');
	}

	//эхо("formatArg(fc = '%c', m = '%c')\n", fc, m);
	switch (m)
	{
	    case ПМангл.Тбул:
		vbit = ва_арг!(бул)(argptr);
		if (fc != 's')
		{   vnumber = vbit;
		    goto Lnumber;
		}
		debug(PutStr) win.скажинс("путстр3");
		putstr(vbit ? "да" : "нет");
		return;


	    case ПМангл.Тсим:
		vchar = ва_арг!(сим)(argptr);
		if (fc != 's')
		{   vnumber = vchar;
		    goto Lnumber;
		}
	    L2:
		debug(PutStr) win.скажинс("путстр4");
		putstr((&vchar)[0 .. 1]);
		return;

	    case ПМангл.Тшим:
		vdchar = ва_арг!(шим)(argptr);
		goto L1;

	    case ПМангл.Тдим:
		vdchar = ва_арг!(дим)(argptr);
	    L1:
		if (fc != 's')
		{   vnumber = vdchar;
		    goto Lnumber;
		}
		if (vdchar <= 0x7F)
		{   vchar = cast(сим)vdchar;
		    goto L2;
		}
		else
		{   if (!isValidDchar(vdchar))
			throw new Исключение("Неверный дим в формате",__FILE__, __LINE__);
		    сим[4] vbuf;
			debug(PutStr) win.скажинс("путстр5");
		    putstr(toUTF8(vbuf, vdchar));
		}
		return;


	    case ПМангл.Тбайт:
		signed = 1;
		vnumber = ва_арг!(байт)(argptr);
		goto Lnumber;

	    case ПМангл.Тббайт:
		vnumber = ва_арг!(ббайт)(argptr);
		goto Lnumber;

	    case ПМангл.Ткрат:
		signed = 1;
		vnumber = ва_арг!(крат)(argptr);
		goto Lnumber;

	    case ПМангл.Тбкрат:
		vnumber = ва_арг!(бкрат)(argptr);
		goto Lnumber;

	    case ПМангл.Тцел:
		signed = 1;
		vnumber = ва_арг!(цел)(argptr);
		goto Lnumber;

	    case ПМангл.Тбцел:
	    Luцел:
		vnumber = ва_арг!(бцел)(argptr);
		goto Lnumber;

	    case ПМангл.Тдол:
		signed = 1;
		vnumber = cast(бдол)ва_арг!(дол)(argptr);
		goto Lnumber;

	    case ПМангл.Тбдол:
	    Lбдол:
		vnumber = ва_арг!(бдол)(argptr);
		goto Lnumber;

	    case ПМангл.Ткласс:
		vobject = ва_арг!(Объект)(argptr);
		if (vobject is null)
		    т = "null";
		else
		    т = vobject.toString();
		goto Lputstr;

	    case ПМангл.Туказатель:
		vnumber = cast(бдол)ва_арг!(проц*)(argptr);
		if (fc != 'x' && fc != 'X')		uc = 1;
		флаги |= FL0pad;
		if (!(флаги & FLprecision))
		{   флаги |= FLprecision;
		    точность = (проц*).sizeof;
		}
		base = 16;
		goto Lnumber;


	    case ПМангл.Тплав:
	    case ПМангл.Твплав:
		if (fc == 'x' || fc == 'X')
		    goto Luцел;
		vreal = ва_арг!(плав)(argptr);
		goto Lreal;

	    case ПМангл.Тдво:
	    case ПМангл.Твдво:
		if (fc == 'x' || fc == 'X')
		    goto Lбдол;
		vreal = ва_арг!(дво)(argptr);
		goto Lreal;

	    case ПМангл.Треал:
	    case ПМангл.Твреал:
		vreal = ва_арг!(реал)(argptr);
		goto Lreal;


	    case ПМангл.Ткплав:
		vcreal = ва_арг!(кплав)(argptr);
		goto Lcomplex;

	    case ПМангл.Ткдво:
		vcreal = ва_арг!(кдво)(argptr);
		goto Lcomplex;

	    case ПМангл.Ткреал:
		vcreal = ва_арг!(креал)(argptr);
		goto Lcomplex;

	    case ПМангл.Тсмассив:
		putArray(argptr, (cast(TypeInfo_StaticArray)ti).длин, (cast(TypeInfo_StaticArray)ti).следщ);
		return;

	    case ПМангл.Тмассив:
		цел mi = 10;
	        if (ti.classinfo.name.length == 14 &&
		    ti.classinfo.name[9..14] == "Array") 
		{ // array of non-primitive types
		  ИнфОТипе tn = (cast(TypeInfo_Array)ti).следщ;
		  tn = skipCI(tn);
		  switch (cast(ПМангл)tn.classinfo.name[9])
		  {
		    case ПМангл.Тсим:  goto LarrayChar;
		    case ПМангл.Тшим: goto LarrayWchar;
		    case ПМангл.Тдим: goto LarrayDchar;
		    default:
			break;
		  }
		  проц[] va = ва_арг!(проц[])(argptr);
		  putArray(va.ptr, va.length, tn);
		  return;
		}
		if (ti.classinfo.name.length == 25 &&
		    ti.classinfo.name[9..25] == "AssociativeArray") 
		{ // associative array
		  ббайт[дол] vaa = ва_арг!(ббайт[дол])(argptr);
		  putAArray(vaa,
			(cast(TypeInfo_AssociativeArray)ti).следщ,
			(cast(TypeInfo_AssociativeArray)ti).key);
		  return;
		}

		while (1)
		{
		    m2 = cast(ПМангл)ti.classinfo.name[mi];
		    switch (m2)
		    {
			case ПМангл.Тсим:
			LarrayChar:
			    т = ва_арг!(ткст)(argptr);
			    goto Lputstr;

			case ПМангл.Тшим:
			LarrayWchar:
			    шим[] sw = ва_арг!(wstring)(argptr);
			    т = toUTF8(sw);
			    goto Lputstr;

			case ПМангл.Тдим:
			LarrayDchar:
			    дим[] sd = ва_арг!(dstring)(argptr);
			    т = toUTF8(sd);
			Lputstr:
			    if (fc != 's')
				{
				throw new ФорматИскл("ткст");
				}
			    if (флаги & FLprecision && точность < т.length)
				т = т[0 .. точность];
				debug(PutStr) win.скажинс("путстр6");
			    putstr(т);
			    break;

			case ПМангл.Тконст:
			case ПМангл.Тинвариант:
			    mi++;
			    continue;

			default:
			    ИнфОТипе ti2 = простаяИнфОТипе(m2);
			    if (!ti2)
			      goto Lerror;
			    проц[] va = ва_арг!(проц[])(argptr);
			    putArray(va.ptr, va.length, ti2);
		    }
		    return;
		}

	    case ПМангл.Ттипдеф:
		ti = (cast(TypeInfo_Typedef)ti).base;
		m = cast(ПМангл)ti.classinfo.name[9];
		formatArg(fc);
		return;

	    case ПМангл.Тперечень:
		ti = (cast(TypeInfo_Enum)ti).base;
		m = cast(ПМангл)ti.classinfo.name[9];
		formatArg(fc);
		return;

	    case ПМангл.Тструкт:
	    {	TypeInfo_Struct tis = cast(TypeInfo_Struct)ti;
		if (tis.xtoString is null)
		    throw new ФорматИскл("Не удаётся преобразовать " ~ tis.toString() ~ " в ткст: функция \"ткст вТкст()\" не определена");
		т = tis.xtoString(argptr);
		argptr += (tis.tsize() + 3) & ~3;
		goto Lputstr;
	    }

	    default:
		goto Lerror;
	}

    Lnumber:
	switch (fc)
	{
	    case 's':
	    case 'd':
		if (signed)
		{   if (cast(дол)vnumber < 0)
		    {	prefix = "-";
			vnumber = -vnumber;
		    }
		    else if (флаги & FLplus)
			prefix = "+";
		    else if (флаги & FLspace)
			prefix = " ";
		}
		break;

	    case 'b':
		signed = 0;
		base = 2;
		break;

	    case 'o':
		signed = 0;
		base = 8;
		break;

	    case 'X':
		uc = 1;
		if (флаги & FLhash && vnumber)
		    prefix = "0X";
		signed = 0;
		base = 16;
		break;

	    case 'x':
		if (флаги & FLhash && vnumber)
		    prefix = "0x";
		signed = 0;
		base = 16;
		break;

	    default:
		goto Lerror;
	}

	if (!signed)
	{
	    switch (m)
	    {
		case ПМангл.Тбайт:
		    vnumber &= 0xFF;
		    break;

		case ПМангл.Ткрат:
		    vnumber &= 0xFFFF;
		    break;

		case ПМангл.Тцел:
		    vnumber &= 0xFFFFFFFF;
		    break;

		default:
		    break;
	    }
	}

	if (флаги & FLprecision && fc != 'p')
	    флаги &= ~FL0pad;

	if (vnumber < base)
	{
	    if (vnumber == 0 && точность == 0 && флаги & FLprecision &&
		!(fc == 'o' && флаги & FLhash))
	    {
		debug(PutStr) win.скажинс("путстр7");
		putstr(null);
		return;
	    }
	    if (точность == 0 || !(флаги & FLprecision))
	    {	vchar = cast(сим)('0' + vnumber);
		if (vnumber < 10)
		    vchar = cast(сим)('0' + vnumber);
		else
		    vchar = cast(сим)((uc ? 'A' - 10 : 'a' - 10) + vnumber);
		goto L2;
	    }
	}

	цел n = tmpbuf.length;
	сим c;
	цел hexсмещение = uc ? ('A' - ('9' + 1)) : ('a' - ('9' + 1));

	while (vnumber)
	{
	    c = cast(сим)((vnumber % base) + '0');
	    if (c > '9')
		c += hexсмещение;
	    vnumber /= base;
	    tmpbuf[--n] = c;
	}
	if (tmpbuf.length - n < точность && точность < tmpbuf.length)
	{
	    цел m = tmpbuf.length - точность;
	    tmpbuf[m .. n] = '0';
	    n = m;
	}
	else if (флаги & FLhash && fc == 'o')
	    prefix = "0";
		debug(PutStr) win.скажинс("путстр8");
	putstr(tmpbuf[n .. tmpbuf.length]);
	return;

    Lreal:
	putreal(vreal);
	return;

    Lcomplex:
	putreal(vcreal.re);
	putc('+');
	putreal(vcreal.im);
	putc('i');
	return;

    Lerror:
	throw new ФорматИскл("\n\tформат аргумента неправильно указан");
    }


    for (j = 0; j < arguments.length; )
    {	ti = arguments[j++];
	//эхо("test1: '%.*т' %d\n", ti.classinfo.name, ti.classinfo.name.length);
	//ti.print();

	флаги = 0;
	точность = 0;
	ширина_поля = 0;

	ti = skipCI(ti);
	цел mi = 9;
	do
	{
	    if (ti.classinfo.name.length <= mi)
		goto Lerror;
	    m = cast(ПМангл)ti.classinfo.name[mi++];
	} while (m == ПМангл.Тконст || m == ПМангл.Тинвариант);

	if (m == ПМангл.Тмассив)
	{
	    if (ti.classinfo.name.length == 14 &&
		ti.classinfo.name[9..14] == "Array") 
	    {
	      ИнфОТипе tn = (cast(TypeInfo_Array)ti).следщ;
	      tn = skipCI(tn);
	      switch (cast(ПМангл)tn.classinfo.name[9])
	      {
		case ПМангл.Тсим:
		case ПМангл.Тшим:
		case ПМангл.Тдим:
		    ti = tn;
		    mi = 9;
		    break;
		default:
		    break;
	      }
	    }
	L1:
	    ПМангл m2 = cast(ПМангл)ti.classinfo.name[mi];
	    ткст  fmt;			// format ткст
	    wstring wfmt;
	    dstring dfmt;

	    /* For performance причины, this код takes advantage of the
	     * fact that most format strings will be ASCII, and that the
	     * format specifiers are always ASCII. This means we only need
	     * to deal with UTF in a couple of isolated spots.
	     */

	    switch (m2)
	    {
		case ПМангл.Тсим:
		    fmt = ва_арг!(ткст)(argptr);
		    break;

		case ПМангл.Тшим:
		    wfmt = ва_арг!(wstring)(argptr);
		    fmt = toUTF8(wfmt);
		    break;

		case ПМангл.Тдим:
		    dfmt = ва_арг!(dstring)(argptr);
		    fmt = toUTF8(dfmt);
		    break;

		case ПМангл.Тконст:
		case ПМангл.Тинвариант:
		    mi++;
		    goto L1;

		default:
		    formatArg('s');
		    continue;
	    }

	    for (т_мера i = 0; i < fmt.length; )
	    {	дим c = fmt[i++];

		дим getFmtChar()
		{   // Valid format specifier символs will never be UTF
		    if (i == fmt.length)
			throw new ФорматИскл("Неверный спецификатор");
		    return fmt[i++];
		}

		цел getFmtInt()
		{   цел n;

		    while (1)
		    {
			n = n * 10 + (c - '0');
			if (n < 0)	// overflow
			    throw new ФорматИскл("Превышение размера цел");
			c = getFmtChar();
			if (c < '0' || c > '9')
			    break;
		    }
		    return n;
		}

		цел getFmtStar()
		{   ПМангл m;
		    ИнфОТипе ti;

		    if (j == arguments.length)
			throw new ФорматИскл("Недостаточно аргументов");
		    ti = arguments[j++];
		    m = cast(ПМангл)ti.classinfo.name[9];
		    if (m != ПМангл.Тцел)
			throw new ФорматИскл("Ожидался аргумент типа цел");
		    return ва_арг!(цел)(argptr);
		}

		if (c != '%')
		{
		    if (c > 0x7F)	// if UTF sequence
		    {
			i--;		// back up and decode UTF sequence
			c = std.utf.decode(fmt, i);
		    }
		Lputc:
		    putc(c);
		    continue;
		}

		// Get флаги {-+ #}
		флаги = 0;
		while (1)
		{
		    c = getFmtChar();
		    switch (c)
		    {
			case '-':	флаги |= FLdash;	continue;
			case '+':	флаги |= FLplus;	continue;
			case ' ':	флаги |= FLspace;	continue;
			case '#':	флаги |= FLhash;	continue;
			case '0':	флаги |= FL0pad;	continue;

			case '%':	if (флаги == 0)
					    goto Lputc;
			default:	break;
		    }
		    break;
		}

		// Get field width
		ширина_поля = 0;
		if (c == '*')
		{
		    ширина_поля = getFmtStar();
		    if (ширина_поля < 0)
		    {   флаги |= FLdash;
			ширина_поля = -ширина_поля;
		    }

		    c = getFmtChar();
		}
		else if (c >= '0' && c <= '9')
		    ширина_поля = getFmtInt();

		if (флаги & FLplus)
		    флаги &= ~FLspace;
		if (флаги & FLdash)
		    флаги &= ~FL0pad;

		// Get точность
		точность = 0;
		if (c == '.')
		{   флаги |= FLprecision;
		    //флаги &= ~FL0pad;

		    c = getFmtChar();
		    if (c == '*')
		    {
			точность = getFmtStar();
			if (точность < 0)
			{   точность = 0;
			    флаги &= ~FLprecision;
			}

			c = getFmtChar();
		    }
		    else if (c >= '0' && c <= '9')
			точность = getFmtInt();
		}

		if (j == arguments.length)
		    goto Lerror;
		ti = arguments[j++];
		ti = skipCI(ti);
		mi = 9;
		do
		{
		    m = cast(ПМангл)ti.classinfo.name[mi++];
		} while (m == ПМангл.Тконст || m == ПМангл.Тинвариант);

		if (c > 0x7F)		// if UTF sequence
		    goto Lerror;	// format specifiers can't be UTF
		formatArg(cast(сим)c);
	    }
	}
	else
	{
	    formatArg('s');
	}
    }
    return;

Lerror:
    throw new ФорматИскл();
}
	
}//end of extern D
//////////////////////////////////

export extern(D)
{

import std.random;

	проц случсей(бцел семя, бцел индекс){std.random.rand_seed(cast(бцел) семя, cast(бцел) индекс);}
	бцел случайно(){return cast(бцел) std.random.rand();}
	бцел случген(бцел семя, бцел индекс, реал члоциклов)
		{
		return cast(бцел) std.random.randomGen(cast(бцел) семя, cast(бцел) индекс, cast(бцел) члоциклов);
		}

import std.file;

	проц[] читайФайл(ткст имяф){return std.file.read(имяф);}
	проц пишиФайл(ткст имяф, проц[] буф){std.file.write(имяф, буф);}
	проц допишиФайл(ткст имяф, проц[] буф){std.file.append(имяф, буф);}
	проц переименуйФайл(ткст из, ткст в){std.file.rename(из, в);}
	проц удалиФайл(ткст имяф){std.file.remove(имяф);}
	бдол дайРазмерФайла(ткст имяф){return std.file.getSize(имяф);}
	проц дайВременаФайла(ткст имяф, out т_время фтц, out т_время фта, out т_время фтм){std.file.getTimes(имяф, фтц, фта, фтм);}
	бул естьФайл(ткст имяф){return cast(бул) std.file.exists(имяф);}
	бцел дайАтрибутыФайла(ткст имяф){return std.file.getAttributes(имяф);}
	бул файл_ли(ткст имяф){return cast(бул) std.file.isfile(имяф);}
	бул папка_ли(ткст имяп){return cast(бул) std.file.isdir(имяп);}
	проц сменипап(ткст имяп){std.file.chdir(имяп);}
	проц сделайпап(ткст имяп){std.file.mkdir(имяп);}
	проц удалипап(ткст имяп){std.file.rmdir(имяп);}
	ткст дайтекпап(){return std.file.getcwd();}
	ткст[] списпап(ткст имяп){return std.file.listdir(имяп);}
	ткст[] списпап(ткст имяп, ткст образец){return std.file.listdir(имяп, образец);}
	
}

export extern(D)
{	

	import std.utf;

	бул дим_ли(дим д){return std.utf.isValidDchar(д);}
	бцел байтЮ(ткст т, т_мера и)
		{
		бцел б = std.utf.stride(т, и);
		if(б == 0xFF)
			{ win.скажинс("бцел байтЮ(ткст т, т_мера и): ткт[индкс] не является началом последовательности UTF-8");
			}
		return б;
		}

	бцел байтЮ(шткст т, т_мера и)
		{
		бцел б = std.utf.stride(т, и);
		if(б == 0xFF)
			{ win.скажинс("бцел байтЮ(шткст т, т_мера и): ткт[индкс] не является началом последовательности UTF-16");
			}
		return б;
		}
		
	бцел байтЮ(юткст т, т_мера и)
		{
		бцел б = std.utf.stride(т, и);
		if(б == 0xFF)
			{ win.скажинс("бцел байтЮ(юткст т, т_мера и): ткт[индкс] не является началом последовательности UTF-32");
			}
		return б;
		}

	т_мера доИндексаУНС(ткст т, т_мера и){return std.utf.toUCSindex(т, и);}
	т_мера доИндексаУНС(шткст т, т_мера и){return std.utf.toUCSindex(т, и);}
	т_мера доИндексаУНС(юткст т, т_мера и){return std.utf.toUCSindex(т, и);}
	т_мера вИндексЮ(ткст т, т_мера и){return std.utf.toUCSindex(т, и);}
	т_мера вИндексЮ(шткст т, т_мера и){return std.utf.toUCSindex(т, и);}
	т_мера вИндексЮ(юткст т, т_мера и){return std.utf.toUCSindex(т, и);}
	дим раскодируйЮ(ткст т, inout т_мера инд){return std.utf.decode(т, инд);}
	дим раскодируйЮ(шткст т, inout т_мера инд){return std.utf.decode(т, инд);}
	дим раскодируйЮ(юткст т, inout т_мера инд){return std.utf.decode(т, инд);}
	проц кодируйЮ(inout ткст т, дим с){std.utf.encode(т, с);}
	проц кодируйЮ(inout шткст т, дим с){std.utf.encode(т, с);}
	проц кодируйЮ(inout юткст т, дим с){std.utf.encode(т, с);}
	проц оцениЮ(ткст т){std.utf.validate(т);}
	проц оцениЮ(шткст т){std.utf.validate(т);}
	проц оцениЮ(юткст т){std.utf.validate(т);}
	ткст вЮ8(сим[4] буф, дим с){return std.utf.toUTF8(буф, с);}
	ткст вЮ8(ткст т){return std.utf.toUTF8(т);}
	ткст вЮ8(шткст т){return std.utf.toUTF8(т);}
	ткст вЮ8(юткст т){return std.utf.toUTF8(т);}
	шткст вЮ16(шим[2] буф, дим с){return std.utf.toUTF16(буф, с);}
	шткст вЮ16(ткст т){return std.utf.toUTF16(т);}
	шим* вЮ16н(ткст т){return std.utf.toUTF16z(т);}
	шткст вЮ16(шткст т){return std.utf.toUTF16(т);}
	шткст вЮ16(юткст т){return std.utf.toUTF16(т);}
	юткст вЮ32(ткст т){return std.utf.toUTF32(т);}
	юткст вЮ32(шткст т){return std.utf.toUTF32(т);}
	юткст вЮ32(юткст т){return std.utf.toUTF32(т);}
	
	т_время вЦел(т_время n)	{		return n;	}

	ткст[] списпап(ткст имяп, РегВыр рег)//////
	{ 
		ткст[] результат;

		бул callback(ПапЗап* de)
		{
		if (de.папка_ли)
			списпап(de.имя, &callback);
		else
		{   if (рег.проверь(de.имя))
			результат ~= de.имя;
		}
		return да; // continue
		}

		списпап(имяп, &callback);
		return результат;
	}
	
	проц списпап(ткст имяп, бул delegate(ткст имяф) обрвызов)//////
		{return listdir(имяп, обрвызов);}
	
	проц списпап(ткст имяп, бул delegate(ПапЗап* пз) обрвызов)//////
	{
	    ткст c;
    ук  h;
    ПапЗап пз;

    c = std.path.join(имяп, "*.*");
    if (useWfuncs)
    {
	ПОИСК_ДАННЫХ fileinfo;

	h = НайдиПервыйФайл(вЮ16(c), &fileinfo);
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

		    пз.иниц(имяп, &fileinfo);
		    if (!обрвызов(&пз))
			break;
		} while (НайдиСледующийФайл(h,&fileinfo) != нет);
	    }
	    finally
	    {
		НайдиЗакрой(h);
	    }
	}
    }
    else
    {
	ПОИСК_ДАННЫХ_А fileinfo;

	h = cast(ук) НайдиПервыйФайлА(c, &fileinfo);
	if (h != cast(ук) НЕВЕРНХЭНДЛ)	// should we throw exception if inзначid?
	{
	    try
	    {
		do
		{
		    // Skip "." and ".."
		    if (cidrus.сравтекс(fileinfo.имяФайла.ptr, ".") == 0 ||
			cidrus.сравтекс(fileinfo.имяФайла.ptr, "..") == 0)
			continue;

		    пз.иниц(имяп, &fileinfo);
		    if (!обрвызов(&пз))
			break;
		} while (НайдиСледующийФайлА(h,&fileinfo) != нет);
	    }
	    finally
	    {
		НайдиЗакрой(h);
	    }
	}
    }	
 }	

креал син(креал x){return std.math.sin(x);}
вреал син(вреал x){return std.math.sin(x);} 
реал абс(креал x){return std.math.abs(x);}
реал абс(вреал x){return std.math.abs(x);}
креал квкор(креал x){return std.math.sqrt(x);}
креал кос(креал x){return std.math.cos(x);}
креал конъюнк(креал y){return std.math.conj(y);}
вреал конъюнк(вреал y){return std.math.conj(y);}
реал кос(вреал x){return std.math.cos(x);}
реал степень(реал а, бцел н){return std.math.pow(а, н);}

цел квадрат(цел а){return std.math2.sqr(а);}
дол квадрат(цел а){return std.math2.sqr(а);}
цел сумма(цел[] ч){return std.math2.sum(ч);}
дол сумма(дол[] ч){return std.math2.sum(ч);}
цел меньш_из(цел[] ч){return std.math2.min(ч);}
дол меньш_из(дол[] ч){return std.math2.min(ч);}
цел меньш_из(цел а, цел б){return std.math2.min(а, б);}
дол меньш_из(дол а, дол б){return std.math2.min(а, б);}
цел больш_из(цел[] ч){return std.math2.max(ч);}
дол больш_из(дол[] ч){return std.math2.max(ч);}
цел больш_из(цел а, цел б){return std.math2.max(а, б);}
дол больш_из(дол а, дол б){return std.math2.max(а, б);}
}//end of extern D

export extern(D)
{
проц копируйФайл(ткст из, ткст в){copy(из, в);}

сим* вМБТ_0(ткст т){return toMBSz(т);}
	
import std.date;

проц  вГодНедИСО8601(т_время t, out цел год, out цел неделя){ std.date.toISO8601YearWeek(t, год, неделя);}
	
цел День(т_время t)	{return cast(цел)std.date.floor(t, 86400000);	}

цел високосныйГод(цел y)
	{
		return ((y & 3) == 0 &&
			(y % 100 || (y % 400) == 0));
	}

цел днейВГоду(цел y)	{		return 365 + std.date.LeapYear(y);	}

цел деньИзГода(цел y)	{		return std.date.DayFromYear(y);	}

т_время времяИзГода(цел y)	{		return cast(т_время) (msPerDay * std.date.DayFromYear(y));	}

цел годИзВрем(т_время t)	{return std.date.YearFromTime(cast(d_time) t);}	
	
бул високосный_ли(т_время t)
	{
		if(std.date.LeapYear(std.date.YearFromTime(cast(d_time) t)) != 0)
		return да;
		else return нет;
	}

цел месИзВрем(т_время t)	{return std.date.MonthFromTime(cast(d_time) t);	}

цел датаИзВрем(т_время t)	{return std.date.DateFromTime(cast(d_time) t);	}

т_время нокругли(т_время d, цел делитель)	{	return cast(т_время) std.date.floor(cast(d_time) d, делитель);		}
	
цел дмод(т_время n, т_время d)	{   return std.date.dmod(n,d);	}

цел часИзВрем(т_время t)	{		return std.date.dmod(std.date.floor(t, msPerHour), HoursPerDay);	}
	
цел минИзВрем(т_время t)	{		return std.date.dmod(std.date.floor(t, msPerMinute), MinutesPerHour);	}
	
цел секИзВрем(т_время t)	{		return std.date.dmod(std.date.floor(t, TicksPerSecond), 60);	}
	
цел мсекИзВрем(т_время t)	{		return std.date.dmod(t / (TicksPerSecond / 1000), 1000);	}
	
цел времениВДне(т_время t)	{		return std.date.dmod(t, msPerDay);	}
	
цел ДеньНедели(т_время вр){return std.date.WeekDay(вр);}
т_время МВ8Местное(т_время вр){return cast(т_время) std.date.UTCtoLocalTime(вр);}
т_время местное8МВ(т_время вр){return cast(т_время) std.date.LocalTimetoUTC(вр);}
т_время сделайВремя(т_время час, т_время мин, т_время сек, т_время мс){return cast(т_время) std.date.MakeTime(час, мин, сек, мс);}
т_время сделайДень(т_время год, т_время месяц, т_время дата){return cast(т_время) std.date.MakeDay(год, месяц, дата);}
т_время сделайДату(т_время день, т_время вр){return cast(т_время) std.date.MakeDate(день, вр);}
//d_time TimeClip(d_time время)
цел датаОтДняНеделиМесяца(цел год, цел месяц, цел день_недели, цел ч){return  std.date.DateFromNthWeekdayOfMonth(год, месяц, день_недели, ч);}
цел днейВМесяце(цел год, цел месяц){return std.date.DaysInMonth(год, месяц);}
ткст вТкст(т_время время){return std.date.toString(время);}
ткст вТкстМВ(т_время время){return std.date.toUTCString(время);}
ткст вТкстДаты(т_время время){return std.date.toDateString(время);}
ткст вТкстВремени(т_время время){return std.date.toTimeString(время);}
т_время разборВремени(ткст т){return cast(т_время) std.date.parse(т);}
т_время дайВремяМВ(){return cast(т_время) std.date.getUTCtime();}
т_время ФВРЕМЯ8т_время(ФВРЕМЯ *фв){return cast(т_время) std.date.FILETIME2d_time(фв);}
т_время СИСТВРЕМЯ8т_время(СИСТВРЕМЯ *св, т_время вр){return cast(т_время) std.date.SYSTEMTIME2d_time(св,cast(дол) вр);}
т_время дайМестнуюЗЧП(){return cast(т_время) std.date.дайЛокTZA();}
цел дневноеСохранениеЧО(т_время вр){return std.date.DaylightSavingTA(вр);}
т_время вДвремя(ФВремяДос вр){return cast(т_время) std.date.toDtime(cast(DosFileTime) вр);}
ФВремяДос вФВремяДос(т_время вр){return cast(ФВремяДос) std.date.toDosFileTime(вр);}

import std.cpuid:mmx,fxsr,sse,sse2,sse3,ssse3,amd3dnow,amd3dnowExt,amdMmx,ia64,amd64,hyperThreading, vendor, processor,family,model,stepping,threadsPerCPU,coresPerCPU;

export extern(D) struct Процессор
{
	export:

	ткст производитель()	{return std.cpuid.vendor();}
	ткст название()			{return std.cpuid.processor();}
	бул поддержкаММЭкс()	{return std.cpuid.mmx();}
	бул поддержкаФЭксСР()	{return std.cpuid.fxsr();}
	бул поддержкаССЕ()		{return std.cpuid.sse();}
	бул поддержкаССЕ2()		{return std.cpuid.sse2();}
	бул поддержкаССЕ3()		{return std.cpuid.sse3();}
	бул поддержкаСССЕ3()	{return std.cpuid.ssse3();}
	бул поддержкаАМД3ДНау()	{return std.cpuid.amd3dnow();}
	бул поддержкаАМД3ДНауЭкст(){return std.cpuid.amd3dnowExt();}
	бул поддержкаАМДММЭкс()	{return std.cpuid.amdMmx();}
	бул являетсяИА64()		{return std.cpuid.ia64();}
	бул являетсяАМД64()		{return std.cpuid.amd64();}
	бул поддержкаГиперПоточности(){return std.cpuid.hyperThreading();}
	бцел потоковНаЦПБ()		{return std.cpuid.threadsPerCPU();}
	бцел ядерНаЦПБ()		{return std.cpuid.coresPerCPU();}
	бул являетсяИнтел()		{return std.cpuid.intel();}
	бул являетсяАМД()		{return std.cpuid.amd();}
	бцел поколение()		{return std.cpuid.stepping();}
	бцел модель()			{return std.cpuid.model();}
	бцел семейство()		{return std.cpuid.family();}
	ткст вТкст()			{return о_ЦПУ();}
}

ткст о_ЦПУ(){

	ткст feats;
	if (mmx)			feats ~= "MMX ";
	if (fxsr)			feats ~= "FXSR ";
	if (sse)			feats ~= "SSE ";
	if (sse2)			feats ~= "SSE2 ";
	if (sse3)			feats ~= "SSE3 ";
	if (ssse3)			feats ~= "SSSE3 ";
	if (amd3dnow)			feats ~= "3DNow! ";
	if (amd3dnowExt)		feats ~= "3DNow!+ ";
	if (amdMmx)			feats ~= "MMX+ ";
	if (ia64)			feats ~= "IA-64 ";
	if (amd64)			feats ~= "AMD64 ";
	if (hyperThreading)		feats ~= "HTT";

	ткст цпу = фм(
		"\t\tИНФОРМАЦИЯ О ЦПУ ДАННОГО КОМПЬЮТЕРА\n\t**************************************************************\n\t"~
		" Производитель   \t|   %s                                 \n\t"~"--------------------------------------------------------------\n\t", vendor(),
		" Процессор       \t|   %s                                 \n\t"~"--------------------------------------------------------------\n\t", processor(),
		" Сигнатура     \t| Семейство %d | Модель %d | Поколение %d \n\t"~"--------------------------------------------------------------\n\t", family(), model(), stepping(),
		" Функции         \t|   %s                                 \n\t"~"--------------------------------------------------------------\n\t", feats,
		" Многопоточность \t|  %d-поточный / %d-ядерный            \n\t"~"**************************************************************", threadsPerCPU(), coresPerCPU());
	return цпу;

    }

import std.path;

ткст извлекиРасш(ткст полнимя){return std.path.getExt(полнимя);}
//getExt(r"d:\путь\foo.bat") // "bat"     getExt(r"d:\путь.two\bar") // null
ткст дайИмяПути(ткст полнимя){return std.path.getName(полнимя);}
//getName(r"d:\путь\foo.bat") => "d:\путь\foo"     getName(r"d:\путь.two\bar") => null
ткст извлекиИмяПути(ткст пимя){return std.path.getBaseName(пимя);}//getBaseName(r"d:\путь\foo.bat") => "foo.bat"
ткст извлекиПапку(ткст пимя){return std.path.getDirName(пимя);}
//getDirName(r"d:\путь\foo.bat") => "d:\путь"     getDirName(getDirName(r"d:\путь\foo.bat")) => r"d:\"
ткст извлекиМеткуДиска(ткст пимя){return std.path.getDrive(пимя);}
ткст устДефРасш(ткст пимя, ткст расш){return std.path.defaultExt(пимя, расш);}
ткст добРасш(ткст фимя, ткст расш){return std.path.addExt(фимя, расш);}
бул абсПуть_ли(ткст путь){return cast(бул) std.path.isabs(путь);}
ткст слейПути(ткст п1, ткст п2){return std.path.join(п1, п2);}
бул сравниПути(дим п1, дим п2){return cast(бул) std.path.fncharmatch(п1, п2);}
бул сравниПутьОбразец(ткст фимя, ткст образец){return cast(бул) std.path.fnmatch(фимя, образец);}
ткст разверниТильду(ткст путь){return std.path.expandTilde(путь);}

бул выведиФайл(ткст имяф){ скажи(cast(ткст) читайФайл(имяф)); return да;}


}///end of extern C


export extern(D) struct Дата
	{
export:
	цел год;	/// use цел.min as "nan" year значение
    цел месяц;		/// 1..12
    цел день;		/// 1..31
    цел час;		/// 0..23
    цел минута;		/// 0..59
    цел секунда;		/// 0..59
    цел мс;		/// 0..999
    цел день_недели;	/// 0: not specified, 1..7: Sunday..Saturday
    цел коррекцияЧП;	/// -1200..1200 correction in hours

    /// Разбор даты из текста т[] и сохранение её как экземпляра Даты.

    проц разбор(ткст т)
    {
		Дата а = разборДаты(т);
		год = а.год;	/// use цел.min as "nan" year значение
		месяц = а.месяц;		/// 1..12
		день =а.день;		/// 1..31
		час =а.час;		/// 0..23
		минута = а.минута;		/// 0..59
		секунда = а.секунда;		/// 0..59
		мс = а.мс;		/// 0..999
		день_недели = а.день_недели;	/// 0: not specified, 1..7: Sunday..Saturday
		коррекцияЧП = а.коррекцияЧП;		
    }

}

private Дата вДату(Date d, out Дата рез)
{
	//Дата рез;
	рез.год = d.year ;	/// use цел.min as "nan" year значение
    рез.месяц = d.month;		/// 1..12
    рез.день = d.day;		/// 1..31
    рез.час = d.hour;		/// 0..23
    рез.минута = d.minute;		/// 0..59
    рез.секунда = d.second;		/// 0..59
    рез.мс = d.ms;		/// 0..999
    рез.день_недели = d.weekday;	/// 0: not specified, 1..7: Sunday..Saturday
    рез.коррекцияЧП = d.tzcorrection;
	return рез;
}


import std.dateparse;

export extern(D) Дата разборДаты(ткст т)
{	
DateParse dp;
Date d;
Дата д;
dp.parse(т, d);
	 вДату(d, д);
	return  д;	
}
	
	
export extern(D) struct ПапЗап
	{
	
private DirEntry de;



	ткст имя;
    бдол размер = ~0UL;
    т_время времяСоздания = т_время_нч;
    т_время времяПоследнегоДоступа = т_время_нч;	
    т_время времяПоследнейЗаписи = т_время_нч;
    бцел атрибуты;

  export  проц иниц(ткст путь, ПОИСК_ДАННЫХ_А *дф)
    {
	de.init(путь, дф);
	имя = de.имя;
    размер = de.размер;
    времяСоздания = cast(т_время) de.creationTime;
    времяПоследнегоДоступа =cast(т_время) de.lastAccessTime ;	
    времяПоследнейЗаписи = cast(т_время) de.lastWriteTime ;
    атрибуты = de.attributes;
    }

  export   проц иниц(ткст путь, ПОИСК_ДАННЫХ *дф)
    {
	de.init(путь, дф);
	имя = de.имя;
    размер = de.размер;
    времяСоздания = cast(т_время) de.creationTime;
    времяПоследнегоДоступа =cast(т_время) de.lastAccessTime ;	
    времяПоследнейЗаписи = cast(т_время) de.lastWriteTime ;
    атрибуты = de.attributes;
    }

  export  бцел папка_ли()
    {
	return de.isdir();
    }

  export бцел файл_ли()
    {
	return de.isfile();
    }
	
DirEntry вДирЭнтри()
	{
	de.имя = имя;
    de.размер = размер;
    de.creationTime = времяСоздания;
    de.lastAccessTime = времяПоследнегоДоступа;	
    de.lastWriteTime = времяПоследнейЗаписи;
    de.attributes = атрибуты;
	return de;
	}

	

}

import std.outbuffer;

export extern (D) class БуферВывода
{



ббайт данные[];
бцел смещение;

invariant
    {
	//say(format("this = %p, смещение = %x, данные.length = %u\n", this, смещение, данные.length));
	assert(смещение <= данные.length);
	assert(данные.length <= смЁмкость(данные.ptr));
    }
	
	export this()
    {
	//say("in OutBuffer constructor\n");
	}
	
export	ббайт[] вБайты() { return данные[0 .. смещение]; }
	
export	проц резервируй(бцел члобайт)
	in
	{
	    assert(смещение + члобайт >= смещение);
	}
	out
	{
	    assert(смещение + члобайт <= данные.length);
	    assert(данные.length <= смЁмкость(данные.ptr));
	}
	body
	{
	    if (данные.length < смещение + члобайт)
	    {
		данные.length = (смещение + члобайт) * 2;
		setTypeInfo(null, данные.ptr);
	    }
	}

 export   проц пиши(ббайт[] байты)
	{
	    резервируй(байты.length);
	    данные[смещение .. смещение + байты.length] = байты;
	    смещение += байты.length;
	}

  export  проц пиши(ббайт b)		/// ditto
	{
	    резервируй(ббайт.sizeof);
	    this.данные[смещение] = b;
	    смещение += ббайт.sizeof;
	}

  export  проц пиши(байт b) { пиши(cast(ббайт)b); }		/// ditto
 export   проц пиши(сим c) { пиши(cast(ббайт)c); }		/// ditto

 export   проц пиши(бкрат w)		/// ditto
    {
	резервируй(бкрат.sizeof);
	*cast(бкрат *)&данные[смещение] = w;
	смещение += бкрат.sizeof;
    }

  export  проц пиши(крат т) { пиши(cast(бкрат)т); }		/// ditto

  export  проц пиши(шим c)		/// ditto
    {
	резервируй(шим.sizeof);
	*cast(шим *)&данные[смещение] = c;
	смещение += шим.sizeof;
    }

  export  проц пиши(бцел w)		/// ditto
    {
	резервируй(бцел.sizeof);
	*cast(бцел *)&данные[смещение] = w;
	смещение += бцел.sizeof;
    }

  export  проц пиши(цел i) { пиши(cast(бцел)i); }		/// ditto

  export  проц пиши(бдол l)		/// ditto
    {
	резервируй(бдол.sizeof);
	*cast(бдол *)&данные[смещение] = l;
	смещение += бдол.sizeof;
    }

  export  проц пиши(дол l) { пиши(cast(бдол)l); }		/// ditto

   export проц пиши(плав f)		/// ditto
    {
	резервируй(плав.sizeof);
	*cast(плав *)&данные[смещение] = f;
	смещение += плав.sizeof;
    }

   export проц пиши(дво f)		/// ditto
    {
	резервируй(дво.sizeof);
	*cast(дво *)&данные[смещение] = f;
	смещение += дво.sizeof;
    }

  export  проц пиши(реал f)		/// ditto
    {
	резервируй(реал.sizeof);
	*cast(реал *)&данные[смещение] = f;
	смещение += реал.sizeof;
    }

   export проц пиши(ткст т)		/// ditto
    {
	пиши(cast(ббайт[])т);
    }

   export проц пиши(БуферВывода буф)		/// ditto
    {
	пиши(буф.вБайты());
    }

    /****************************************
     * Добавка члобайт of 0 to the internal буфер.
     */

  export  проц занули(бцел члобайт)
    {
	резервируй(члобайт);
	данные[смещение .. смещение + члобайт] = 0;
	смещение += члобайт;
    }

    /**********************************
     * 0-fill to align on power of 2 boundary.
     */

  export  проц расклад(бцел мера)
    in
    {
	assert(мера && (мера & (мера - 1)) == 0);
    }
    out
    {
	assert((смещение & (мера - 1)) == 0);
    }
    body
    {   бцел члобайт;

	члобайт = смещение & (мера - 1);
	if (члобайт)
	    занули(мера - члобайт);
    }

    /****************************************
     * Optimize common special case расклад(2)
     */

  export  проц расклад2()
    {
	if (смещение & 1)
	    пиши(cast(байт)0);
    }

    /****************************************
     * Optimize common special case расклад(4)
     */

   export проц расклад4()
    {
	if (смещение & 3)
	{   бцел члобайт = (4 - смещение) & 3;
	    занули(члобайт);
	}
    }

    /**************************************
     * Convert internal буфер to array of симs.
     */

   export ткст вТкст()
    {
	//эхо("БуферВывода.вТкст()\n");
	return cast(сим[])данные[0 .. смещение];
    }

    /*****************************************
     * Добавка output of C'т vprintf() to internal буфер.
     */

  export  проц ввыводф(ткст формат, спис_ва арги)
    {
	сим[128] буфер;
	сим* p;
	бцел psize;
	цел count;

	auto f = вТкст0(формат);
	p = буфер.ptr;
	psize = буфер.length;
	for (;;)
		{
			count = _vsnprintf(p,psize,f,арги);
			if (count != -1)
				break;
			psize *= 2;
			p = cast(сим *) cidrus.alloca(psize);	// буфер too small, try again with larger размер
		}
	пиши(p[0 .. count]);
    }

    /*****************************************
     * Добавка output of C'т эхо() to internal буфер.
     */

  export  проц выводф(ткст формат, ...)
    {
	спис_ва ap;
	ap = cast(спис_ва)&формат;
	ap += формат.sizeof;
	ввыводф(формат, ap);
    }

    /*****************************************
     * At смещение index целo буфер, создай члобайт of space by shifting upwards
     * all данные past index.
     */

  export  проц простели(бцел индекс, бцел члобайт)
	in
	{
	    assert(индекс <= смещение);
	}
	body
	{
	    резервируй(члобайт);

	    // This is an overlapping copy - should use memmove()
	    for (бцел i = смещение; i > индекс; )
	    {
		--i;
		данные[i + члобайт] = данные[i];
	    }
	    смещение += члобайт;
	}
	
	export ~this(){}
}



export extern(D)
{

ткст ДАТА()
{
СИСТВРЕМЯ систВремя;
ДайМестнВремя(&систВремя);
ткст ДАТА = вТкст(систВремя.день)~"."~вТкст(систВремя.месяц)~"."~вТкст(систВремя.год);
return  ДАТА;
}

ткст ВРЕМЯ()
{
СИСТВРЕМЯ систВремя;
ДайМестнВремя(&систВремя);
ткст ВРЕМЯ = вТкст(систВремя.час)~" ч. "~вТкст(систВремя.минута)~" мин.";
return  ВРЕМЯ;
}

	
import std.math;

реал абс(реал x){return std.math.abs(x);}
дол абс(дол x){return std.math.abs(x);}
цел абс(цел x){return std.math.abs(x);}
реал кос(реал x){return std.math.cos(x);}
реал син(реал x){return std.math.sin(x);}
реал тан(реал x){return std.math.tan(x);}
реал акос(реал x){return std.math.acos(x);}
реал асин(реал x){return std.math.asin(x);}
реал атан(реал x){return std.math.atan(x);}
реал атан2(реал y, реал x){return std.math.atan2(x, y);}
реал гкос(реал x){return std.math.cosh(x);}
реал гсин(реал x){return std.math.sinh(x);}
реал гтан(реал x){return std.math.tanh(x);}
реал гакос(реал x){return std.math.acosh(x);}
реал гасин(реал x){return std.math.asinh(x);}
реал гатан(реал x){return std.math.atanh(x);}
дол округливдол(реал x){return std.math.rndtol(x);}
реал округливближдол(реал x){return std.math.rndtonl(x);}
плав квкор(плав x){return std.math.sqrt(x);}
дво квкор(дво x){return std.math.sqrt(x);}
реал квкор(реал x){return std.math.sqrt(x);}
реал эксп(реал x){return std.math.exp(x);}
реал экспм1(реал x){return std.math.expm1(x);}
реал эксп2(реал x){return std.math.exp2(x);}
креал экспи(реал x){return std.math.expi(x);}
реал прэксп(реал знач, out цел эксп){return std.math.frexp(знач, эксп);}
цел илогб(реал x){return std.math.ilogb(x);}
реал лдэксп(реал н, цел эксп){return std.math.ldexp(н, эксп);}
реал лог(реал x){return std.math.log(x);}
реал лог10(реал x){return std.math.log10(x);}
реал лог1п(реал x){return std.math.log1p(x);}
реал лог2(реал x){return std.math.log2(x);}
реал логб(реал x){return std.math.logb(x);}
реал модф(реал x, inout реал y){return std.math.modf(x, y);}
реал скалбн(реал x, цел н){return std.math.scalbn(x,н);}
реал кубкор(реал x){return std.math.cbrt(x);}
реал фабс(реал x){return std.math.fabs(x);}
реал гипот(реал x, реал y){return std.math.hypot(x, y);}
реал фцош(реал x){return std.math.erf(x);}
реал лгамма(реал x){return std.math.lgamma(x);}
реал тгамма(реал x){return std.math.tgamma(x);}
реал потолок(реал x){return std.math.ceil(x);}
реал пол(реал x){return std.math.floor(x);}
реал ближцел(реал x){return std.math.nearbyint(x);}

цел окрвцел(реал x)
{
    //version(Naked_D_InlineAsm_X86)
   // {
        цел n;
        asm
        {
            fld x;
            fistp n;
        }
        return n;
  //  }
  //  else
  //  {
   //     return cidrus.lrintl(x);
   // }
}
реал окрвреал(реал x){return std.math.rint(x);}
дол окрвдол(реал x){return std.math.lrint(x);}
реал округли(реал x){return std.math.round(x);}
дол докругли(реал x){return std.math.lround(x);}
реал упрости(реал x){return std.math.trunc(x);}
реал остаток(реал x, реал y){return std.math.remainder(x, y);}
бул нч_ли(реал x){return cast(бул) std.math.isnan(x);}
бул конечен_ли(реал р){return cast(бул) std.math.isfinite(р);}

бул субнорм_ли(плав п){return cast(бул) std.math.issubnormal(п);}
бул субнорм_ли(дво п){return cast(бул) std.math.issubnormal(п);}
бул субнорм_ли(реал п){return cast(бул) std.math.issubnormal(п);}
бул беск_ли(реал р){return cast(бул) std.math.isinf(р);}
бул идентичен_ли(реал р, реал д){return std.math.isIdentical(р, д);}
бул битзнака(реал р){ if(1 == std.math.signbit(р)){return да;} return нет;}
реал копируйзнак(реал кому, реал у_кого){return std.math.copysign(кому, у_кого);}
реал нч(ткст тэгп){return std.math.nan(тэгп);}
реал следщБольш(реал р){return std.math.nextUp(р);}
дво следщБольш(дво р){return std.math.nextUp(р);}
плав следщБольш(плав р){return std.math.nextUp(р);}
реал следщМеньш(реал р){return std.math.nextUp(р);}
дво следщМеньш(дво р){return std.math.nextUp(р);}
плав следщМеньш(плав р){return std.math.nextUp(р);}
реал следщза(реал а, реал б){return std.math.nextafter(а, б);}
плав следщза(плав а, плав б){return std.math.nextafter(а, б);}
дво следщза(дво а, дво б){return std.math.nextafter(а, б);}
реал пдельта(реал а, реал б){return std.math.fdim(а, б);}
реал пбольш_из(реал а, реал б){return std.math.fmax(а, б);}
реал пменьш_из(реал а, реал б){return std.math.fmin(а, б);}

реал степень(реал а, цел н){return std.math.pow(а, н);}
реал степень(реал а, реал н){return std.math.pow(а, н);}

import std.math2;

бул правны(реал а, реал б){return std.math2.feq(а, б);}
бул правны(реал а, реал б, реал эпс){return std.math2.feq(а, б, эпс);}

реал квадрат(цел а){return std.math2.sqr(а);}
реал дробь(реал а){return std.math2.frac(а);}
цел знак(цел а){return std.math2.sign(а);}
цел знак(дол а){return std.math2.sign(а);}
цел знак(реал а){return std.math2.sign(а);}
реал цикл8градус(реал ц){return std.math2.cycle2deg(ц);}
реал цикл8радиан(реал ц){return std.math2.cycle2rad(ц);}
реал цикл8градиент(реал ц){return std.math2.cycle2grad(ц);}
реал градус8цикл(реал г){return std.math2.deg2cycle(г);}
реал градус8радиан(реал г){return std.math2.deg2rad(г);}
реал градус8градиент(реал г){return std.math2.deg2grad(г);}
реал радиан8градус(реал р){return std.math2.rad2deg(р);}
реал радиан8цикл(реал р){return std.math2.rad2cycle(р);}
реал радиан8градиент(реал р){return std.math2.rad2grad(р);}
реал градиент8градус(реал г){return std.math2.grad2deg(г);}
реал градиент8цикл(реал г){return std.math2.grad2cycle(г);}
реал градиент8радиан(реал г){return std.math2.grad2rad(г);}
реал сариф(реал[] ч){return std.math2.avg(ч);}
реал сумма(реал[] ч){return std.math2.sum(ч);}
реал меньш_из(реал[] ч){return std.math2.min(ч);}
реал меньш_из(реал а, реал б){return std.math2.min(а, б);}
реал больш_из(реал[] ч){return std.math2.max(ч);}
реал больш_из(реал а, реал б){return std.math2.max(а, б);}
реал акот(реал р){return std.math2.acot(р);}
реал асек(реал р){return std.math2.asec(р);}
реал акосек(реал р){return std.math2.acosec(р);}
реал кот(реал р){return std.math2.cot(р);}
реал сек(реал р){return std.math2.sec(р);}
реал косек(реал р){return std.math2.cosec(р);}
реал гкот(реал р){return std.math2.coth(р);}
реал гсек(реал р){return std.math2.sech(р);}
реал гкосек(реал р){return std.math2.cosech(р);}
реал гакот(реал р){return std.math2.acoth(р);}
реал гасек(реал р){return std.math2.asech(р);}
реал гакосек(реал р){return std.math2.acosech(р);}
реал ткст8реал(ткст т){return std.math2.atof(т);} 


import std.regexp;


ткст подставь(ткст текст, ткст образец, ткст формат, ткст атрибуты = null)
	{
	return std.regexp.sub(текст, образец, формат, атрибуты);
	}
}//end of extern C

export extern(D) ткст подставь(ткст текст, ткст образец, ткст delegate(РегВыр) дг, ткст атрибуты = null)
	{
	  auto r = РегВыр(образец, атрибуты);
    рсим[] результат;
    цел последниндкс;
    цел смещение;

    результат = текст;
    последниндкс = 0;
    смещение = 0;
    while (r.проверь(текст, последниндкс))
    {
	цел so = r.псовп[0].рснач;
	цел eo = r.псовп[0].рскон;

	рсим[] замена = дг(r);

	// Optimize by using std.string.replace if possible - Dave Fladebo
	рсим[] срез = результат[смещение + so .. смещение + eo];
	if (r.атрибуты & РегВыр.РВА.глоб &&		// глоб, so replace all
	    !(r.атрибуты & РегВыр.РВА.любрег) &&	// not ignoring case
	    !(r.атрибуты & РегВыр.РВА.многострок) &&	// not многострок
	    образец == срез)				// simple образец (exact match, no special символs) 
	{
	    debug(РегВыр)
		win.скажинс(фм("образец: %s, срез: %s, замена: %s\n", образец, результат[смещение + so .. смещение + eo],замена));
	    результат = замени(результат,срез,замена);
	    break;
	}

	результат = replaceSlice(результат, результат[смещение + so .. смещение + eo], замена);

	if (r.атрибуты & РегВыр.РВА.глоб)
	{
	    смещение += замена.length - (eo - so);

	    if (последниндкс == eo)
		последниндкс++;		// always consume some source
	    else
		последниндкс = eo;
	}
	else
	    break;
    }
    delete r;

    return результат;

	}
	
export extern(D) РегВыр ищи(ткст текст, ткст образец, ткст атрибуты = null)
	{
	auto r = РегВыр(образец, атрибуты);

    if (r.проверь(текст))
		{
		}
		else
		{	delete r;
		r = null;
		}
    return r;
	}

export extern (D)
{
	цел найди(рткст текст, ткст образец, ткст атрибуты = null)//Возврат -1=совпадений нет, иначе=индекс совпадения
		{
		
	//debug win.скажинс("РегВыр.найди");
	//debug win.скажинс(текст);
		    int i = -1;

    auto r = new РегВыр(образец, атрибуты);
    if (r.проверь(текст))
    {
	i = r.псовп[0].рснач;
    }
    delete r;
    return i;

		//return std.regexp.find(текст, образец, атрибуты);
		}

	цел найдирек(рткст текст, ткст образец, ткст атрибуты = null)
		{
		return std.regexp.rfind(текст, образец, атрибуты);
		}

	ткст[] разбей(ткст текст, ткст образец, ткст атрибуты = null)
		{
	//debug win.скажинс(текст);
	auto r = new РегВыр(образец, атрибуты);
    auto результат = r.разбей(текст);
    delete r;
    return результат;

		//return std.regexp.split(текст, образец, атрибуты);
		}

import std.uni;

бул юпроп_ли(дим с){return cast(бул) std.uni.isUniLower(с);}
бул юзаг_ли(дим с){return cast(бул) std.uni.isUniUpper(с);}
дим в_юпроп(дим с){return std.uni.toUniLower(с);}
дим в_юзаг(дим с){return std.uni.toUniUpper(с);}
бул юцб_ли(дим с){return cast(бул) std.uni.isUniAlpha(с);}

import std.uri;

бцел аски8гекс(дим с){return std.uri.ascii2hex(с);}
ткст раскодируйУИР(ткст кодирУИР){return std.uri.decode(кодирУИР);}
ткст раскодируйКомпонентУИР(ткст кодирКомпонУИР){return std.uri.decodeComponent(кодирКомпонУИР);}
ткст кодируйУИР(ткст уир){return std.uri.encode(уир);}
ткст кодируйКомпонентУИР(ткст уирКомпон){return std.uri.encodeComponent(уирКомпон);}

import std.zlib;

бцел адлер32(бцел адлер, проц[] буф){return std.zlib.adler32(адлер, буф);}
бцел цпи32(бцел кс, проц[] буф){return std.zlib.crc32(кс, буф);}

проц[] сожмиЗлиб(проц[] истбуф, цел ур = цел.init)
	{
	if(ур) return std.zlib.compress(истбуф, ур);
	else return std.zlib.compress(истбуф);
	}

проц[] разожмиЗлиб(проц[] истбуф, бцел итдлин = 0u, цел винбиты = 15){return std.zlib.uncompress(истбуф, итдлин, винбиты);}

import std.crc32;

бцел иницЦПИ32(){return std.crc32.init_crc32();}
бцел обновиЦПИ32б(ббайт зн, бцел црц){return std.crc32.update_crc32(зн, црц);}
бцел обновиЦПИ32с(сим зн, бцел црц){return std.crc32.update_crc32(зн, црц);}
бцел ткстЦПИ32(ткст т){return std.crc32.crc32(т);}

}	

export extern(D) class СжатиеЗлиб
{
private std.zlib.Compress zc;

export:
	enum
	{
		БЕЗ_СЛИВА      = 0,
		СИНХ_СЛИВ    = 2,
		ПОЛН_СЛИВ    = 3,
		ФИНИШ       = 4,
	}

	this(цел ур){zc = new std.zlib.Compress(ур);}
	this(){zc = new std.zlib.Compress();}
	~this(){delete zc;}
	проц[] сжать(проц[] буф){return  zc.compress(буф);}
	проц[] слей(цел режим = ФИНИШ){return  zc.flush(режим);}
}

export extern(D) class РасжатиеЗлиб
{
private std.zlib.UnCompress zc;

export:
	
	this(бцел размБуфЦели){zc = new std.zlib.UnCompress(размБуфЦели);}
	this(){zc = new std.zlib.UnCompress;}
	~this(){delete zc;}
	проц[] расжать(проц[] буф){return  zc.uncompress(буф);}
	проц[] слей(){return  zc.flush();}
}



export extern(D) class ИсключениеРегВыр : Исключение
{
export:
    this(ткст сооб)
    {
	super("Неудачная операция с регулярным выражением: "~сооб,__FILE__,__LINE__);
	}
}


export extern (D) class РегВыр
{

   export ~this(){};

    export this(рсим[] образец, рсим[] атрибуты = null)
    {
	псовп = (&гсовп)[0 .. 1];
	компилируй(образец, атрибуты);
    }

    export static РегВыр opCall(рсим[] образец, рсим[] атрибуты = null)
    {
	return new РегВыр(образец, атрибуты);
    }

    export РегВыр ищи(рсим[] текст)
    {
	ввод = текст;
	псовп[0].рскон = 0;
	return this;
    }

    /** ditto */
   export  цел opApply(цел delegate(inout РегВыр) дг)
    {
	цел результат;
	РегВыр r = this;

	while (проверь())
	{
	    результат = дг(r);
	    if (результат)
		break;
	}

	return результат;
    }

   export  ткст сверь(т_мера n)
    {
	if (n >= псовп.length)
	    return null;
	else
	{   т_мера рснач, рскон;
	    рснач = псовп[n].рснач;
	    рскон = псовп[n].рскон;
	    if (рснач == рскон)
		return null;
	    return ввод[рснач .. рскон];
	}
    }

   export  ткст перед()
    {
	return ввод[0 .. псовп[0].рснач];
    }

   export  ткст после()
    {
	return ввод[псовп[0].рскон .. $];
    }

    бцел члоподстр;		// number of parenthesized subexpression matches
    т_регсвер[] псовп;	// array [члоподстр + 1]

    рсим[] ввод;		// the текст to ищи

    // per instance:

    рсим[] образец;		// source text of the regular expression

    рсим[] флаги;		// source text of the атрибуты parameter

    цел ошибки;

    бцел атрибуты;

    enum РВА
    {
	глоб		= 1,	// has the g attribute
	любрег	= 2,	// has the i attribute
	многострок	= 4,	// if treat as multiple lines separated
				// by newlines, or as a single строка
	тчксовплф	= 8,	// if . matches \n
    }


private{
    т_мера истк;			// current source index in ввод[]
    т_мера старт_истк;		// starting index for сверь in ввод[]
    т_мера p;			// позиция of parser in образец[]
    т_регсвер гсовп;		// сверь for the entire regular expression
				// (serves as storage for псовп[0])

    ббайт[] программа;		// образец[] compiled целo regular expression программа
    БуферВывода буф;
	}

// Opcodes

enum : ббайт
{
    РВконец,		// end of программа
    РВсим,		// single символ
    РВлсим,		// single символ, case insensitive
    РВдим,		// single UCS символ
    РВлдим,		// single wide символ, case insensitive
    РВлюбсим,		// any символ
    РВлюбзвезда,		// ".*"
    РВткст,		// текст of символs
    РВлткст,		// текст of символs, case insensitive
    РВтестбит,		// any in bitmap, non-consuming
    РВбит,		// any in the bit map
    РВнебит,		// any not in the bit map
    РВдиапазон,		// any in the текст
    РВнедиапазон,		// any not in the текст
    РВили,		// a | b
    РВплюс,		// 1 or more
    РВзвезда,		// 0 or more
    РВвопрос,		// 0 or 1
    РВнм,		// n..m
    РВнмкю,		// n..m, non-greedy version
    РВначстр,		// beginning of строка
    РВконстр,		// end of строка
    РВвскоб,		// parenthesized subexpression
    РВгоуту,		// goto смещение

    РВгранслова,
    РВнегранслова,
    РВцифра,
    РВнецифра,
    РВпространство,
    РВнепространство,
    РВслово,
    РВнеслово,
    РВобрссыл,
};

// BUG: should this include '$'?
private цел слово_ли(дим c) { return числобукв_ли(c) || c == '_'; }

private бцел бескн = ~0u;

/* ********************************
 * Throws ИсключениеРегВыр on error
 */

export проц компилируй(рсим[] образец, рсим[] атрибуты)
{
   debug(РегВыр) скажи(фм("РегВыр.компилируй('%s', '%s')\n", образец, атрибуты));

    this.атрибуты = 0;
    foreach (рсим c; атрибуты)
    {   РВА att;

	switch (c)
	{
	    case 'g': att = РВА.глоб;		break;
	    case 'i': att = РВА.любрег;	break;
	    case 'm': att = РВА.многострок;	break;
	    default:
		error("нераспознанный атрибут");
		return;
	}
	if (this.атрибуты & att)
	{   error("повторяющийся атрибут");
	    return;
	}
	this.атрибуты |= att;
    }

    ввод = null;

    this.образец = образец;
    this.флаги = атрибуты;

    бцел oldre_nsub = члоподстр;
    члоподстр = 0;
    ошибки = 0;

    буф = new БуферВывода();
    буф.резервируй(образец.length * 8);
    p = 0;
    разборРегвыр();
    if (p < образец.length)
    {	error("несовпадение ')'");
    }
    оптимизируй();
    программа = буф.данные;
    буф.данные = null;
   // delete буф;//Вызывает ошибку!)))

    if (члоподстр > oldre_nsub)
    {
	if (псовп.ptr is &гсовп)
	    псовп = null;
	псовп.length = члоподстр + 1;
    }
    псовп[0].рснач = 0;
    псовп[0].рскон = 0;
}


 export рсим[][] разбей(рсим[] текст)
{
    debug(РегВыр) скажи("РегВыр.разбей()\n");

    рсим[][] результат;

    if (текст.length)
    {
	цел p = 0;
	цел q;
	for (q = p; q != текст.length;)
	{
	    if (проверь(текст, q))
	    {	цел e;

		q = псовп[0].рснач;
		e = псовп[0].рскон;
		if (e != p)
		{
		    результат ~= текст[p .. q];
		    for (цел i = 1; i < псовп.length; i++)
		    {
			цел so = псовп[i].рснач;
			цел eo = псовп[i].рскон;
			if (so == eo)
			{   so = 0;	// -1 gives array bounds error
			    eo = 0;
			}
			результат ~= текст[so .. eo];
		    }
		    q = p = e;
		    continue;
		}
	    }
	    q++;
	}
	результат ~= текст[p .. текст.length];
    }
    else if (!проверь(текст))
	результат ~= текст;
    return результат;
}

 export цел найди(рсим[] текст)
{
    цел i;

    i = проверь(текст);
    if (i)
	i = псовп[0].рснач;
    else
	i = -1;			// no сверь
    return i;
}

 export рсим[][] сверь(рсим[] текст)
{
    рсим[][] результат;

    if (атрибуты & РВА.глоб)
    {
	цел последниндкс = 0;

	while (проверь(текст, последниндкс))
	{   цел eo = псовп[0].рскон;

	    результат ~= ввод[псовп[0].рснач .. eo];
	    if (последниндкс == eo)
		последниндкс++;		// always consume some source
	    else
		последниндкс = eo;
	}
    }
    else
    {
	результат = выполни(текст);
    }
    return результат;
}

 export рсим[] замени(рсим[] текст, рсим[] формат)
{
    рсим[] результат;
    цел последниндкс;
    цел смещение;

    результат = текст;
    последниндкс = 0;
    смещение = 0;
    for (;;)
    {
	if (!проверь(текст, последниндкс))
	    break;

	цел so = псовп[0].рснач;
	цел eo = псовп[0].рскон;

	рсим[] замена = замени(формат);

	// Optimize by using std.текст.замени if possible - Dave Fladebo
	рсим[] срез = результат[смещение + so .. смещение + eo];
	if (атрибуты & РВА.глоб &&		// глоб, so замени all
	   !(атрибуты & РВА.любрег) &&	// not ignoring case
	   !(атрибуты & РВА.многострок) &&	// not многострок
	   образец == срез &&			// simple образец (exact сверь, no special символs) 
	   формат == замена)		// simple формат, not $ formats
	{
	    debug(РегВыр)
		скажифнс("образец: %s срез: %s, формат: %s, замена: %s\n" ,образец,результат[смещение + so .. смещение + eo],формат, замена);
	    результат = std.string.replace(результат,срез,замена);
	    break;
	}

	результат = replaceSlice(результат, результат[смещение + so .. смещение + eo], замена);

	if (атрибуты & РВА.глоб)
	{
	    смещение += замена.length - (eo - so);

	    if (последниндкс == eo)
		последниндкс++;		// always consume some source
	    else
		последниндкс = eo;
	}
	else
	    break;
    }

    return результат;
}

 export рсим[][] выполни(рсим[] текст)
{
    debug(РегВыр) win.скажи(фм("РегВыр.выполни(текст = '%s')\n", текст));
    ввод = текст;
    псовп[0].рснач = 0;
    псовп[0].рскон = 0;
    return выполни();
}

 export рсим[][] выполни()
{
    if (!проверь())
	return null;

    auto результат = new рсим[][псовп.length];
    for (цел i = 0; i < псовп.length; i++)
    {
	if (псовп[i].рснач == псовп[i].рскон)
	    результат[i] = null;
	else
	    результат[i] = ввод[псовп[i].рснач .. псовп[i].рскон];
    }

    return результат;
}

 export цел проверь(рсим[] текст)
{
    return проверь(текст, 0 /*псовп[0].рскон*/);
}

export цел проверь()
{
    return проверь(ввод, псовп[0].рскон);
}

export цел проверь(ткст текст, цел стартиндекс)
{
    сим firstc;
    бцел ит;

    ввод = текст;
    debug (РегВыр) win.скажи(фм("РегВыр.проверь(ввод[] = '%s', стартиндекс = %d)\n", ввод, стартиндекс));
    псовп[0].рснач = 0;
    псовп[0].рскон = 0;
    if (стартиндекс < 0 || стартиндекс > ввод.length)
    {
	return 0;			// fail
    }
    debug(РегВыр) выведиПрограмму(программа);

    // First символ optimization
    firstc = 0;
    if (программа[0] == РВсим)
    {
	firstc = программа[1];
	if (атрибуты & РВА.любрег && буква_ли(firstc))
	    firstc = 0;
    }

    for (ит = стартиндекс; ; ит++)
    {
	if (firstc)
	{
	    if (ит == ввод.length)
		break;			// no сверь
	    if (ввод[ит] != firstc)
	    {
		ит++;
		if (!чр(ит, firstc))	// if first символ not found
		    break;		// no сверь
	    }
	}
	for (цел i = 0; i < члоподстр + 1; i++)
	{
	    псовп[i].рснач = -1;
	    псовп[i].рскон = -1;
	}
	старт_истк = истк = ит;
	if (пробнсвер(0, программа.length))
	{
	    псовп[0].рснач = ит;
	    псовп[0].рскон = истк;
	    //debug(РегВыр) эхо("старт = %d, end = %d\n", гсовп.рснач, гсовп.рскон);
	    return 1;
	}
	// If possible сверь must старт at beginning, we are done
	if (программа[0] == РВначстр || программа[0] == РВлюбзвезда)
	{
	    if (атрибуты & РВА.многострок)
	    {
		// Scan for the следщ \n
		if (!чр(ит, '\n'))
		    break;		// no сверь if '\n' not found
	    }
	    else
		break;
	}
	if (ит == ввод.length)
	    break;
	//debug(РегВыр) эхо("Starting new try: '%.*т'\n", ввод[ит + 1 .. ввод.length]);
    }
    return 0;		// no сверь
}

export цел чр(inout бцел ит, рсим c)
{
    for (; ит < ввод.length; ит++)
    {
	if (ввод[ит] == c)
	    return 1;
    }
    return 0;
}


export проц выведиПрограмму(ббайт[] прог)
{
  
    бцел pc;
    бцел длин;
    бцел n;
    бцел m;
    бкрат *pu;
    бцел *pбцел;

    debug(РегВыр) win.скажи("Вывод Программы()\n");
    for (pc = 0; pc < прог.length; )
    {
	debug(РегВыр) скажифнс("прог[pc] = %d, РВсим = %d, РВнмкю = %d\n", прог[pc], РВсим, РВнмкю);
	switch (прог[pc])
	{
	    case РВсим:
		debug(РегВыр) win.скажи(фм("\tРВсим '%c'\n", прог[pc + 1]));
		pc += 1 + сим.sizeof;
		break;

	    case РВлсим:
		debug(РегВыр) скажифнс("\tРВлсим '%c'\n", прог[pc + 1]);
		pc += 1 + сим.sizeof;
		break;

	    case РВдим:
		debug(РегВыр) скажифнс("\tРВдим '%c'\n", *cast(дим *)&прог[pc + 1]);
		pc += 1 + дим.sizeof;
		break;

	    case РВлдим:
		debug(РегВыр) скажифнс("\tРВлдим '%c'\n", *cast(дим *)&прог[pc + 1]);
		pc += 1 + дим.sizeof;
		break;

	    case РВлюбсим:
		debug(РегВыр) win.скажи("\tРВлюбсим\n");
		pc++;
		break;

	    case РВткст:
		длин = *cast(бцел *)&прог[pc + 1];
		debug(РегВыр) скажифнс("\tРВткст x%x, '%s'\n", длин,
			(&прог[pc + 1 + бцел.sizeof])[0 .. длин]);
		pc += 1 + бцел.sizeof + длин * рсим.sizeof;
		break;

	    case РВлткст:
		длин = *cast(бцел *)&прог[pc + 1];
		debug(РегВыр) скажифнс("\tРВлткст x%x, '%s'\n", длин,
			(&прог[pc + 1 + бцел.sizeof])[0 .. длин]);
		pc += 1 + бцел.sizeof + длин * рсим.sizeof;
		break;

	    case РВтестбит:
		pu = cast(бкрат *)&прог[pc + 1];
		debug(РегВыр) скажифнс("\tРВтестбит %d, %d\n", pu[0], pu[1]);
		длин = pu[1];
		pc += 1 + 2 * бкрат.sizeof + длин;
		break;

	    case РВбит:
		pu = cast(бкрат *)&прог[pc + 1];
		длин = pu[1];
		debug(РегВыр) скажифнс("\tРВбит cmax=%x, длин=%d:", pu[0], длин);
		for (n = 0; n < длин; n++)
		  debug(РегВыр)  скажифнс(" %x", прог[pc + 1 + 2 * бкрат.sizeof + n]);
		debug(РегВыр)скажифнс("\n");
		pc += 1 + 2 * бкрат.sizeof + длин;
		break;

	    case РВнебит:
		pu = cast(бкрат *)&прог[pc + 1];
		debug(РегВыр) скажифнс("\tРВнебит %d, %d\n", pu[0], pu[1]);
		длин = pu[1];
		pc += 1 + 2 * бкрат.sizeof + длин;
		break;

	    case РВдиапазон:
		длин = *cast(бцел *)&прог[pc + 1];
		debug(РегВыр) скажифнс("\tРВдиапазон %d\n", длин);
		// BUG: REAignoreCase?
		pc += 1 + бцел.sizeof + длин;
		break;

	    case РВнедиапазон:
		длин = *cast(бцел *)&прог[pc + 1];
		debug(РегВыр) скажифнс("\tРВнедиапазон %d\n", длин);
		// BUG: REAignoreCase?
		pc += 1 + бцел.sizeof + длин;
		break;

	    case РВначстр:
		debug(РегВыр) win.скажи("\tРВначстр\n");
		pc++;
		break;

	    case РВконстр:
		debug(РегВыр) win.скажи("\tРВконстр\n");
		pc++;
		break;

	    case РВили:
		длин = *cast(бцел *)&прог[pc + 1];
		debug(РегВыр) скажифнс("\tРВили %d, pc=>%d\n", длин, pc + 1 + бцел.sizeof + длин);
		pc += 1 + бцел.sizeof;
		break;

	    case РВгоуту:
		длин = *cast(бцел *)&прог[pc + 1];
		debug(РегВыр) скажифнс("\tРВгоуту %d, pc=>%d\n", длин, pc + 1 + бцел.sizeof + длин);
		pc += 1 + бцел.sizeof;
		break;

	    case РВлюбзвезда:
		debug(РегВыр) win.скажи("\tРВлюбзвезда\n");
		pc++;
		break;

	    case РВнм:
	    case РВнмкю:
		// длин, n, m, ()
		pбцел = cast(бцел *)&прог[pc + 1];
		длин = pбцел[0];
		n = pбцел[1];
		m = pбцел[2];
		debug(РегВыр) скажифнс("\tРВнм = %s длин=%d, n=%u, m=%u, pc=>%d\n", (прог[pc] == РВнмкю) ? "q" : " ",   длин, n, m, pc + 1 + бцел.sizeof * 3 + длин);
		pc += 1 + бцел.sizeof * 3;
		break;

	    case РВвскоб:
		// длин, n, ()
		pбцел = cast(бцел *)&прог[pc + 1];
		длин = pбцел[0];
		n = pбцел[1];
		debug(РегВыр) скажифнс("\tРВвскоб длин=%d n=%d, pc=>%d\n", длин, n, pc + 1 + бцел.sizeof * 2 + длин);
		pc += 1 + бцел.sizeof * 2;
		break;

	    case РВконец:
		debug(РегВыр) win.скажи("\tРВконец\n");
		return;

	    case РВгранслова:
		debug(РегВыр) win.скажи("\tРВгранслова\n");
		pc++;
		break;

	    case РВнегранслова:
		debug(РегВыр) win.скажи("\tРВнегранслова\n");
		pc++;
		break;

	    case РВцифра:
		debug(РегВыр) win.скажи("\tРВцифра\n");
		pc++;
		break;

	    case РВнецифра:
		debug(РегВыр) win.скажи("\tРВнецифра\n");
		pc++;
		break;

	    case РВпространство:
		debug(РегВыр) win.скажи("\tРВпространство\n");
		pc++;
		break;

	    case РВнепространство:
		debug(РегВыр) win.скажи("\tРВнепространство\n");
		pc++;
		break;

	    case РВслово:
		debug(РегВыр) win.скажи("\tРВслово\n");
		pc++;
		break;

	    case РВнеслово:
		debug(РегВыр) win.скажи("\tРВнеслово\n");
		pc++;
		break;

	    case РВобрссыл:
		debug(РегВыр) скажифнс("\tРВобрссыл %d\n", прог[1]);
		pc += 2;
		break;

	    default:
		assert(0);
	}
  }
  //}
}


export цел пробнсвер(цел pc, цел pcend)
{   цел srcsave;
    бцел длин;
    бцел n;
    бцел m;
    бцел count;
    бцел pop;
    бцел ss;
    т_регсвер *psave;
    бцел c1;
    бцел c2;
    бкрат* pu;
    бцел* pбцел;

    debug(РегВыр)	win.скажи(фм("РегВыр.пробнсвер(pc = %d, истк = '%s', pcend = %d)\n",
	    pc, ввод[истк .. ввод.length], pcend));
    srcsave = истк;
    psave = null;
    for (;;)
    {
	if (pc == pcend)		// if done matching
	{   debug(РегВыр) win.скажи("\tконецпрог\n");
	    return 1;
	}

	//эхо("\top = %d\n", программа[pc]);
	switch (программа[pc])
	{
	    case РВсим:
		if (истк == ввод.length)
		    goto Lnomatch;
		debug(РегВыр) win.скажи(фм("\tРВсим '%i', истк = '%i'\n", программа[pc + 1], ввод[истк]));
		if (программа[pc + 1] != ввод[истк])
		    goto Lnomatch;
		истк++;
		pc += 1 + сим.sizeof;
		break;

	    case РВлсим:
		if (истк == ввод.length)
		    goto Lnomatch;
		debug(РегВыр) win.скажи(фм("\tРВлсим '%i', истк = '%i'\n", программа[pc + 1], ввод[истк]));
		c1 = программа[pc + 1];
		c2 = ввод[истк];
		if (c1 != c2)
		{
		    if (проп_ли(cast(рсим)c2))
			c2 = std.ctype.toupper(cast(рсим)c2);
		    else
			goto Lnomatch;
		    if (c1 != c2)
			goto Lnomatch;
		}
		истк++;
		pc += 1 + сим.sizeof;
		break;

	    case РВдим:
		debug(РегВыр) win.скажи(фм("\tРВдим '%i', истк = '%i'\n", *(cast(дим *)&программа[pc + 1]), ввод[истк]));
		if (истк == ввод.length)
		    goto Lnomatch;
		if (*(cast(дим *)&программа[pc + 1]) != ввод[истк])
		    goto Lnomatch;
		истк++;
		pc += 1 + дим.sizeof;
		break;

	    case РВлдим:
		debug(РегВыр) win.скажи(фм("\tРВлдим '%i', истк = '%i'\n", *(cast(дим *)&программа[pc + 1]), ввод[истк]));
		if (истк == ввод.length)
		    goto Lnomatch;
		c1 = *(cast(дим *)&программа[pc + 1]);
		c2 = ввод[истк];
		if (c1 != c2)
		{
		    if (проп_ли(cast(рсим)c2))
			c2 = std.ctype.toupper(cast(рсим)c2);
		    else
			goto Lnomatch;
		    if (c1 != c2)
			goto Lnomatch;
		}
		истк++;
		pc += 1 + дим.sizeof;
		break;

	    case РВлюбсим:
		debug(РегВыр) win.скажи("\tРВлюбсим\n");
		if (истк == ввод.length)
		    goto Lnomatch;
		if (!(атрибуты & РВА.тчксовплф) && ввод[истк] == cast(рсим)'\n')
		    goto Lnomatch;
		истк += std.utf.stride(ввод, истк);
		//истк++;
		pc++;
		break;

	    case РВткст:
		длин = *cast(бцел *)&программа[pc + 1];
		debug(РегВыр) win.скажи(фм("\tРВткст x%x, '%s'\n", длин,
			(&программа[pc + 1 + бцел.sizeof])[0 .. длин]));
		if (истк + длин > ввод.length)
		    goto Lnomatch;
		if (cidrus.memcmp(&программа[pc + 1 + бцел.sizeof], &ввод[истк], длин * рсим.sizeof))
		    goto Lnomatch;
		истк += длин;
		pc += 1 + бцел.sizeof + длин * рсим.sizeof;
		break;

	    case РВлткст:
		длин = *cast(бцел *)&программа[pc + 1];
		debug(РегВыр) win.скажи(фм("\tРВлткст x%x, '%s'\n", длин,
			(&программа[pc + 1 + бцел.sizeof])[0 .. длин]));
		if (истк + длин > ввод.length)
		    goto Lnomatch;
		version (Win32)
		{
		    if (memicmp(cast(сим*)&программа[pc + 1 + бцел.sizeof], &ввод[истк], длин * рсим.sizeof))
			goto Lnomatch;
		}
		else
		{
		    if (icmp((cast(сим*)&программа[pc + 1 + бцел.sizeof])[0..длин],
			     ввод[истк .. истк + длин]))
			goto Lnomatch;
		}
		истк += длин;
		pc += 1 + бцел.sizeof + длин * рсим.sizeof;
		break;

	    case РВтестбит:
		pu = (cast(бкрат *)&программа[pc + 1]);
		debug(РегВыр) win.скажи(фм("\tРВтестбит %d, %d, '%i', x%x\n",
		    pu[0], pu[1], ввод[истк], ввод[истк]));
		if (истк == ввод.length)
		    goto Lnomatch;
		длин = pu[1];
		c1 = ввод[истк];
		//эхо("[x%02x]=x%02x, x%02x\n", c1 >> 3, ((&программа[pc + 1 + 4])[c1 >> 3] ), (1 << (c1 & 7)));
		if (c1 <= pu[0] &&
		    !((&(программа[pc + 1 + 4]))[c1 >> 3] & (1 << (c1 & 7))))
		    goto Lnomatch;
		pc += 1 + 2 * бкрат.sizeof + длин;
		break;

	    case РВбит:
		pu = (cast(бкрат *)&программа[pc + 1]);
		debug(РегВыр) win.скажи(фм("\tРВбит %d, %d, '%c'\n",
		    pu[0], pu[1], ввод[истк]));
		if (истк == ввод.length)
		    goto Lnomatch;
		длин = pu[1];
		c1 = ввод[истк];
		if (c1 > pu[0])
		    goto Lnomatch;
		if (!((&программа[pc + 1 + 4])[c1 >> 3] & (1 << (c1 & 7))))
		    goto Lnomatch;
		истк++;
		pc += 1 + 2 * бкрат.sizeof + длин;
		break;

	    case РВнебит:
		pu = (cast(бкрат *)&программа[pc + 1]);
		debug(РегВыр) win.скажи(фм("\tРВнебит %d, %d, '%c'\n",
		    pu[0], pu[1], ввод[истк]));
		if (истк == ввод.length)
		    goto Lnomatch;
		длин = pu[1];
		c1 = ввод[истк];
		if (c1 <= pu[0] &&
		    ((&программа[pc + 1 + 4])[c1 >> 3] & (1 << (c1 & 7))))
		    goto Lnomatch;
		истк++;
		pc += 1 + 2 * бкрат.sizeof + длин;
		break;

	    case РВдиапазон:
		длин = *cast(бцел *)&программа[pc + 1];
		debug(РегВыр) win.скажи(фм("\tРВдиапазон %d\n", длин));
		if (истк == ввод.length)
		    goto Lnomatch;
		// BUG: РВА.любрег?
		if (memchr(cast(сим*)&программа[pc + 1 + бцел.sizeof], ввод[истк], длин) == null)
		    goto Lnomatch;
		истк++;
		pc += 1 + бцел.sizeof + длин;
		break;

	    case РВнедиапазон:
		длин = *cast(бцел *)&программа[pc + 1];
		debug(РегВыр) win.скажи(фм("\tРВнедиапазон %d\n", длин));
		if (истк == ввод.length)
		    goto Lnomatch;
		// BUG: РВА.любрег?
		if (memchr(cast(сим*)&программа[pc + 1 + бцел.sizeof], ввод[истк], длин) != null)
		    goto Lnomatch;
		истк++;
		pc += 1 + бцел.sizeof + длин;
		break;

	    case РВначстр:
		debug(РегВыр) win.скажи("\tРВначстр\n");
		if (истк == 0)
		{
		}
		else if (атрибуты & РВА.многострок)
		{
		    if (ввод[истк - 1] != '\n')
			goto Lnomatch;
		}
		else
		    goto Lnomatch;
		pc++;
		break;

	    case РВконстр:
		debug(РегВыр) win.скажи("\tРВконстр\n");
		if (истк == ввод.length)
		{
		}
		else if (атрибуты & РВА.многострок && ввод[истк] == '\n')
		    истк++;
		else
		    goto Lnomatch;
		pc++;
		break;

	    case РВили:
		длин = (cast(бцел *)&программа[pc + 1])[0];
		debug(РегВыр) win.скажи(фм("\tРВили %d\n", длин));
		pop = pc + 1 + бцел.sizeof;
		ss = истк;
		if (пробнсвер(pop, pcend))
		{
		    if (pcend != программа.length)
		    {	цел т;

			т = истк;
			if (пробнсвер(pcend, программа.length))
			{   debug(РегВыр) win.скажи("\tпервый операнд соответствует\n");
			    истк = т;
			    return 1;
			}
			else
			{
			    // If second branch doesn't сверь to end, take first anyway
			    истк = ss;
			    if (!пробнсвер(pop + длин, программа.length))
			    {
				debug(РегВыр) win.скажи("\tпервый операнд соответствует\n");
				истк = т;
				return 1;
			    }
			}
			истк = ss;
		    }
		    else
		    {	debug(РегВыр) win.скажи("\tпервый операнд соответствует\n");
			return 1;
		    }
		}
		pc = pop + длин;		// proceed with 2nd branch
		break;

	    case РВгоуту:
		debug(РегВыр) win.скажи("\tРВгоуту\n");
		длин = (cast(бцел *)&программа[pc + 1])[0];
		pc += 1 + бцел.sizeof + длин;
		break;

	    case РВлюбзвезда:
		debug(РегВыр) win.скажи("\tРВлюбзвезда\n");
		pc++;
		for (;;)
		{   цел s1;
		    цел s2;

		    s1 = истк;
		    if (истк == ввод.length)
			break;
		    if (!(атрибуты & РВА.тчксовплф) && ввод[истк] == '\n')
			break;
		    истк++;
		    s2 = истк;

		    // If no сверь after consumption, but it
		    // did сверь before, then no сверь
		    if (!пробнсвер(pc, программа.length))
		    {
			истк = s1;
			// BUG: should we save/restore псовп[]?
			if (пробнсвер(pc, программа.length))
			{
			    истк = s1;		// no сверь
			    break;
			}
		    }
		    истк = s2;
		}
		break;

	    case РВнм:
	    case РВнмкю:
		// длин, n, m, ()
		pбцел = cast(бцел *)&программа[pc + 1];
		длин = pбцел[0];
		n = pбцел[1];
		m = pбцел[2];
		debug(РегВыр) скажифнс("\tРВнм %s длин=%d, n=%u, m=%u\n", (программа[pc] == РВнмкю) ? cast(сим*)"q" : cast(сим*)"", длин, n, m);
		pop = pc + 1 + бцел.sizeof * 3;
		for (count = 0; count < n; count++)
		{
		    if (!пробнсвер(pop, pop + длин))
			goto Lnomatch;
		}
		if (!psave && count < m)
		{
		    //version (Win32)
			psave = cast(т_регсвер *)cidrus.alloca((члоподстр + 1) * т_регсвер.sizeof);
		    //else
			//psave = new т_регсвер[члоподстр + 1];
		}
		if (программа[pc] == РВнмкю)	// if minimal munch
		{
		    for (; count < m; count++)
		    {   цел s1;

			cidrus.memcpy(psave, псовп.ptr, (члоподстр + 1) * т_регсвер.sizeof);
			s1 = истк;

			if (пробнсвер(pop + длин, программа.length))
			{
			    истк = s1;
			    cidrus.memcpy(псовп.ptr, psave, (члоподстр + 1) * т_регсвер.sizeof);
			    break;
			}

			if (!пробнсвер(pop, pop + длин))
			{   debug(РегВыр) win.скажи("\tнесовпадение с подвыражением\n");
			    break;
			}

			// If source is not consumed, don't
			// infinite loop on the сверь
			if (s1 == истк)
			{   debug(РегВыр) win.скажи("\tисточник не потреблён\n");
			    break;
			}
		    }
		}
		else	// maximal munch
		{
		    for (; count < m; count++)
		    {   цел s1;
			цел s2;

			cidrus.memcpy(psave, псовп.ptr, (члоподстр + 1) * т_регсвер.sizeof);
			s1 = истк;
			if (!пробнсвер(pop, pop + длин))
			{   debug(РегВыр) win.скажи("\tнесовпадение с подвыражением\n");
			    break;
			}
			s2 = истк;

			// If source is not consumed, don't
			// infinite loop on the сверь
			if (s1 == s2)
			{   debug(РегВыр) win.скажи("\tисточник не потреблён\n");
			    break;
			}

			// If no сверь after consumption, but it
			// did сверь before, then no сверь
			if (!пробнсвер(pop + длин, программа.length))
			{
			    истк = s1;
			    if (пробнсвер(pop + длин, программа.length))
			    {
				истк = s1;		// no сверь
				cidrus.memcpy(псовп.ptr, psave, (члоподстр + 1) * т_регсвер.sizeof);
				break;
			    }
			}
			истк = s2;
		    }
		}
		debug(РегВыр) win.скажинс(фм("\tРВнм len=%d, n=%u, m=%u, DONE count=%d\n", длин, n, m, count));
		pc = pop + длин;
		break;

	    case РВвскоб:
		// длин, ()
		debug(РегВыр) win.скажи("\tРВвскоб\n");
		pбцел = cast(бцел *)&программа[pc + 1];
		длин = pбцел[0];
		n = pбцел[1];
		pop = pc + 1 + бцел.sizeof * 2;
		ss = истк;
		if (!пробнсвер(pop, pop + длин))
		    goto Lnomatch;
		псовп[n + 1].рснач = ss;
		псовп[n + 1].рскон = истк;
		pc = pop + длин;
		break;

	    case РВконец:
		debug(РегВыр) win.скажи("\tРВконец\n");
		return 1;		// successful сверь

	    case РВгранслова:
		debug(РегВыр) win.скажи("\tРВгранслова\n");
		if (истк > 0 && истк < ввод.length)
		{
		    c1 = ввод[истк - 1];
		    c2 = ввод[истк];
		    if (!(
			  (слово_ли(cast(рсим)c1) && !слово_ли(cast(рсим)c2)) ||
			  (!слово_ли(cast(рсим)c1) && слово_ли(cast(рсим)c2))
			 )
		       )
			goto Lnomatch;
		}
		pc++;
		break;

	    case РВнегранслова:
		debug(РегВыр) win.скажи("\tРВнегранслова\n");
		if (истк == 0 || истк == ввод.length)
		    goto Lnomatch;
		c1 = ввод[истк - 1];
		c2 = ввод[истк];
		if (
		    (слово_ли(cast(рсим)c1) && !слово_ли(cast(рсим)c2)) ||
		    (!слово_ли(cast(рсим)c1) && слово_ли(cast(рсим)c2))
		   )
		    goto Lnomatch;
		pc++;
		break;

	    case РВцифра:
		debug(РегВыр) win.скажи("\tРВцифра\n");
		if (истк == ввод.length)
		    goto Lnomatch;
		if (!std.ctype.isdigit(ввод[истк]))
		    goto Lnomatch;
		истк++;
		pc++;
		break;

	    case РВнецифра:
		debug(РегВыр) win.скажи("\tРВнецифра\n");
		if (истк == ввод.length)
		    goto Lnomatch;
		if (std.ctype.isdigit(ввод[истк]))
		    goto Lnomatch;
		истк++;
		pc++;
		break;

	    case РВпространство:
		debug(РегВыр) win.скажи("\tРВпространство\n");
		if (истк == ввод.length)
		    goto Lnomatch;
		if (!межбукв_ли(ввод[истк]))
		    goto Lnomatch;
		истк++;
		pc++;
		break;

	    case РВнепространство:
		debug(РегВыр) win.скажи("\tРВнепространство\n");
		if (истк == ввод.length)
		    goto Lnomatch;
		if (межбукв_ли(ввод[истк]))
		    goto Lnomatch;
		истк++;
		pc++;
		break;

	    case РВслово:
		debug(РегВыр) win.скажи("\tРВслово\n");
		if (истк == ввод.length)
		    goto Lnomatch;
		if (!слово_ли(ввод[истк]))
		    goto Lnomatch;
		истк++;
		pc++;
		break;

	    case РВнеслово:
		debug(РегВыр) win.скажи("\tРВнеслово\n");
		if (истк == ввод.length)
		    goto Lnomatch;
		if (слово_ли(ввод[истк]))
		    goto Lnomatch;
		истк++;
		pc++;
		break;

	    case РВобрссыл:
	    {
		n = программа[pc + 1];
		debug(РегВыр) win.скажи(фм("\tРВобрссыл %d\n", n));

		цел so = псовп[n + 1].рснач;
		цел eo = псовп[n + 1].рскон;
		длин = eo - so;
		if (истк + длин > ввод.length)
		    goto Lnomatch;
		else if (атрибуты & РВА.любрег)
		{
		    if (icmp(ввод[истк .. истк + длин], ввод[so .. eo]))
			goto Lnomatch;
		}
		else if (cidrus.memcmp(&ввод[истк], &ввод[so], длин * рсим.sizeof))
		    goto Lnomatch;
		истк += длин;
		pc += 2;
		break;
	    }

	    default:
		assert(0);
	}
    }

Lnomatch:
    debug(РегВыр) скажифнс("\tnomatch pc=%d\n", pc);
    истк = srcsave;
    return 0;
}

/* =================== Compiler ================== */

export цел разборРегвыр()
{   бцел смещение;
    бцел переходКсмещению;
    бцел len1;
    бцел len2;

    debug(РегВыр) скажифнс("разборРегвыр() '%s'\n", образец[p .. образец.length]);
    смещение = буф.смещение;
    for (;;)
    {
	assert(p <= образец.length);
	if (p == образец.length)
	{   буф.пиши(РВконец);
	    return 1;
	}
	switch (образец[p])
	{
	    case ')':
		return 1;

	    case '|':
		p++;
		переходКсмещению = буф.смещение;
		буф.пиши(РВгоуту);
		буф.пиши(cast(бцел)0);
		len1 = буф.смещение - смещение;
		буф.простели(смещение, 1 + бцел.sizeof);
		переходКсмещению += 1 + бцел.sizeof;
		разборРегвыр();
		len2 = буф.смещение - (переходКсмещению + 1 + бцел.sizeof);
		буф.данные[смещение] = РВили;
		(cast(бцел *)&буф.данные[смещение + 1])[0] = len1;
		(cast(бцел *)&буф.данные[переходКсмещению + 1])[0] = len2;
		break;

	    default:
		разборКуска();
		break;
	}
    }
}

export цел разборКуска()
{   бцел смещение;
    бцел длин;
    бцел n;
    бцел m;
    ббайт op;
    цел plength = образец.length;

    debug(РегВыр)  скажифнс("разборКуска() '%s'\n", образец[p .. образец.length]);
    смещение = буф.смещение;
    разборАтома();
    if (p == plength)
	return 1;
    switch (образец[p])
    {
	case '*':
	    // Special optimization: замени .* with РВлюбзвезда
	    if (буф.смещение - смещение == 1 &&
		буф.данные[смещение] == РВлюбсим &&
		p + 1 < plength &&
		образец[p + 1] != '?')
	    {
		буф.данные[смещение] = РВлюбзвезда;
		p++;
		break;
	    }

	    n = 0;
	    m = бескн;
	    goto Lnm;

	case '+':
	    n = 1;
	    m = бескн;
	    goto Lnm;

	case '?':
	    n = 0;
	    m = 1;
	    goto Lnm;

	case '{':	// {n} {n,} {n,m}
	    p++;
	    if (p == plength || !std.ctype.isdigit(образец[p]))
		goto Lerr;
	    n = 0;
	    do
	    {
		// BUG: хэндл overflow
		n = n * 10 + образец[p] - '0';
		p++;
		if (p == plength)
		    goto Lerr;
	    } while (std.ctype.isdigit(образец[p]));
	    if (образец[p] == '}')		// {n}
	    {	m = n;
		goto Lnm;
	    }
	    if (образец[p] != ',')
		goto Lerr;
	    p++;
	    if (p == plength)
		goto Lerr;
	    if (образец[p] == /*{*/ '}')	// {n,}
	    {	m = бескн;
		goto Lnm;
	    }
	    if (!std.ctype.isdigit(образец[p]))
		goto Lerr;
	    m = 0;			// {n,m}
	    do
	    {
		// BUG: хэндл overflow
		m = m * 10 + образец[p] - '0';
		p++;
		if (p == plength)
		    goto Lerr;
	    } while (std.ctype.isdigit(образец[p]));
	    if (образец[p] != /*{*/ '}')
		goto Lerr;
	    goto Lnm;

	Lnm:
	    p++;
	    op = РВнм;
	    if (p < plength && образец[p] == '?')
	    {	op = РВнмкю;	// minimal munch version
		p++;
	    }
	    длин = буф.смещение - смещение;
	    буф.простели(смещение, 1 + бцел.sizeof * 3);
	    буф.данные[смещение] = op;
	    бцел* pбцел = cast(бцел *)&буф.данные[смещение + 1];
	    pбцел[0] = длин;
	    pбцел[1] = n;
	    pбцел[2] = m;
	    break;

	default:
	    break;
    }
    return 1;

Lerr:
    error("неверно оформленные {n,m}");
    assert(0);
}

export цел разборАтома()
{   ббайт op;
    бцел смещение;
    рсим c;

    debug(РегВыр) скажифнс("разборАтома() '%s'\n", образец[p .. образец.length]);
    if (p < образец.length)
    {
	c = образец[p];
	switch (c)
	{
	    case '*':
	    case '+':
	    case '?':
		error("*+? недопустимо в атоме");
		p++;
		return 0;

	    case '(':
		p++;
		буф.пиши(РВвскоб);
		смещение = буф.смещение;
		буф.пиши(cast(бцел)0);		// резервируй space for length
		буф.пиши(члоподстр);
		члоподстр++;
		разборРегвыр();
		*cast(бцел *)&буф.данные[смещение] =
		    буф.смещение - (смещение + бцел.sizeof * 2);
		if (p == образец.length || образец[p] != ')')
		{
		    error("')' ожидалось");
		    return 0;
		}
		p++;
		break;

	    case '[':
		if (!parseRange())
		    return 0;
		break;

	    case '.':
		p++;
		буф.пиши(РВлюбсим);
		break;

	    case '^':
		p++;
		буф.пиши(РВначстр);
		break;

	    case '$':
		p++;
		буф.пиши(РВконстр);
		break;

	    case '\\':
		p++;
		if (p == образец.length)
		{ 
		error("отсутствие символов после '\\'");
		    return 0;
		}
		c = образец[p];
		switch (c)
		{
		    case 'b':    op = РВгранслова;	 goto Lop;
		    case 'B':    op = РВнегранслова; goto Lop;
		    case 'd':    op = РВцифра;		 goto Lop;
		    case 'D':    op = РВнецифра;	 goto Lop;
		    case 's':    op = РВпространство;		 goto Lop;
		    case 'S':    op = РВнепространство;	 goto Lop;
		    case 'w':    op = РВслово;		 goto Lop;
		    case 'W':    op = РВнеслово;	 goto Lop;

		    Lop:
			буф.пиши(op);
			p++;
			break;

		    case 'f':
		    case 'n':
		    case 'r':
		    case 't':
		    case 'v':
		    case 'c':
		    case 'x':
		    case 'u':
		    case '0':
			c = cast(сим)escape();
			goto Lbyte;

		    case '1': case '2': case '3':
		    case '4': case '5': case '6':
		    case '7': case '8': case '9':
			c -= '1';
			if (c < члоподстр)
			{   буф.пиши(РВобрссыл);
			    буф.пиши(cast(ббайт)c);
			}
			else
			{   error("нет соответствующей обратной ссылки");
			    return 0;
			}
			p++;
			break;

		    default:
			p++;
			goto Lbyte;
		}
		break;

	    default:
		p++;
	    Lbyte:
		op = РВсим;
		if (атрибуты & РВА.любрег)
		{
		    if (буква_ли(c))
		    {
			op = РВлсим;
			c = cast(сим)std.ctype.toupper(c);
		    }
		}
		if (op == РВсим && c <= 0xFF)
		{
		    // Look ahead and see if we can make this целo
		    // an РВткст
		    цел q;
		    цел длин;

		    for (q = p; q < образец.length; ++q)
		    {	рсим qc = образец[q];

			switch (qc)
			{
			    case '{':
			    case '*':
			    case '+':
			    case '?':
				if (q == p)
				    goto Lсим;
				q--;
				break;

			    case '(':	case ')':
			    case '|':
			    case '[':	case ']':
			    case '.':	case '^':
			    case '$':	case '\\':
			    case '}':
				break;

			    default:
				continue;
			}
			break;
		    }
		    длин = q - p;
		    if (длин > 0)
		    {
			debug(РегВыр) скажифнс("записывается текст длин %d, c = '%c', образец[p] = '%c'\n", длин+1, c, образец[p]);
			буф.резервируй(5 + (1 + длин) * рсим.sizeof);
			буф.пиши((атрибуты & РВА.любрег) ? РВлткст : РВткст);
			буф.пиши(длин + 1);
			буф.пиши(c);
			буф.пиши(образец[p .. p + длин]);
			p = q;
			break;
		    }
		}
		if (c >= 0x80)
		{
		    // Convert to дим opcode
		    op = (op == РВсим) ? РВдим : РВлдим;
		    буф.пиши(op);
		    буф.пиши(c);
		}
		else
		{
		 Lсим:
		    debug(РегВыр) скажифнс(" РВсим '%c'\n", c);
		    буф.пиши(op);
		    буф.пиши(cast(сим)c);
		}
		break;
	}
    }
    return 1;
}


class Range
{
    бцел maxc;
    бцел maxb;
    БуферВывода буф;
    ббайт* base;
    BitArray bits;

    this(БуферВывода буф)
    {
	this.буф = буф;
	if (буф.данные.length)
	    this.base = &буф.данные[буф.смещение];
    }

    проц setbitmax(бцел u)
    {   бцел b;

	//эхо("setbitmax(x%x), maxc = x%x\n", u, maxc);
	if (u > maxc)
	{
	    maxc = u;
	    b = u / 8;
	    if (b >= maxb)
	    {	бцел u2;

		u2 = base ? base - &буф.данные[0] : 0;
		буф.занули(b - maxb + 1);
		base = &буф.данные[u2];
		maxb = b + 1;
		//bits = (cast(bit*)this.base)[0 .. maxc + 1];
		bits.ptr = cast(бцел*)this.base;
	    }
	    bits.длин = maxc + 1;
	}
    }

    проц setbit2(бцел u)
    {
	setbitmax(u + 1);
	//эхо("setbit2 [x%02x] |= x%02x\n", u >> 3, 1 << (u & 7));
	bits[u] = 1;
    }

};

цел parseRange()
{   ббайт op;
    цел c;
    цел c2;
    бцел i;
    бцел cmax;
    бцел смещение;

    cmax = 0x7F;
    p++;
    op = РВбит;
    if (p == образец.length)
	goto Lerr;
    if (образец[p] == '^')
    {   p++;
	op = РВнебит;
	if (p == образец.length)
	    goto Lerr;
    }
    буф.пиши(op);
    смещение = буф.смещение;
    буф.пиши(cast(бцел)0);		// резервируй space for length
    буф.резервируй(128 / 8);
    auto r = new Range(буф);
    if (op == РВнебит)
	r.setbit2(0);
    switch (образец[p])
    {
	case ']':
	case '-':
	    c = образец[p];
	    p++;
	    r.setbit2(c);
	    break;

	default:
	    break;
    }

    enum RS { старт, rliteral, dash };
    RS rs;

    rs = RS.старт;
    for (;;)
    {
	if (p == образец.length)
	    goto Lerr;
	switch (образец[p])
	{
	    case ']':
		switch (rs)
		{   case RS.dash:
			r.setbit2('-');
		    case RS.rliteral:
			r.setbit2(c);
			break;
		    case RS.старт:
			break;
		    default:
			assert(0);
		}
		p++;
		break;

	    case '\\':
		p++;
		r.setbitmax(cmax);
		if (p == образец.length)
		    goto Lerr;
		switch (образец[p])
		{
		    case 'd':
			for (i = '0'; i <= '9'; i++)
			    r.bits[i] = 1;
			goto Lrs;

		    case 'D':
			for (i = 1; i < '0'; i++)
			    r.bits[i] = 1;
			for (i = '9' + 1; i <= cmax; i++)
			    r.bits[i] = 1;
			goto Lrs;

		    case 's':
			for (i = 0; i <= cmax; i++)
			    if (межбукв_ли(i))
				r.bits[i] = 1;
			goto Lrs;

		    case 'S':
			for (i = 1; i <= cmax; i++)
			    if (!межбукв_ли(i))
				r.bits[i] = 1;
			goto Lrs;

		    case 'w':
			for (i = 0; i <= cmax; i++)
			    if (слово_ли(cast(рсим)i))
				r.bits[i] = 1;
			goto Lrs;

		    case 'W':
			for (i = 1; i <= cmax; i++)
			    if (!слово_ли(cast(рсим)i))
				r.bits[i] = 1;
			goto Lrs;

		    Lrs:
			switch (rs)
			{   case RS.dash:
				r.setbit2('-');
			    case RS.rliteral:
				r.setbit2(c);
				break;
			    default:
				break;
			}
			rs = RS.старт;
			continue;

		    default:
			break;
		}
		c2 = escape();
		goto Lrange;

	    case '-':
		p++;
		if (rs == RS.старт)
		    goto Lrange;
		else if (rs == RS.rliteral)
		    rs = RS.dash;
		else if (rs == RS.dash)
		{
		    r.setbit2(c);
		    r.setbit2('-');
		    rs = RS.старт;
		}
		continue;

	    default:
		c2 = образец[p];
		p++;
	    Lrange:
		switch (rs)
		{   case RS.rliteral:
			r.setbit2(c);
		    case RS.старт:
			c = c2;
			rs = RS.rliteral;
			break;

		    case RS.dash:
			if (c > c2)
			{   error("инвертированный диапазон в классе символов");
			    return 0;
			}
			r.setbitmax(c2);
			//эхо("c = %x, c2 = %x\n",c,c2);
			for (; c <= c2; c++)
			    r.bits[c] = 1;
			rs = RS.старт;
			break;

		    default:
			assert(0);
		}
		continue;
	}
	break;
    }
    if (атрибуты & РВА.любрег)
    {
	// BUG: what about дим?
	r.setbitmax(0x7F);
	for (c = 'a'; c <= 'z'; c++)
	{
	    if (r.bits[c])
		r.bits[c + 'A' - 'a'] = 1;
	    else if (r.bits[c + 'A' - 'a'])
		r.bits[c] = 1;
	}
    }
    //эхо("maxc = %d, maxb = %d\n",r.maxc,r.maxb);
    (cast(бкрат *)&буф.данные[смещение])[0] = cast(бкрат)r.maxc;
    (cast(бкрат *)&буф.данные[смещение])[1] = cast(бкрат)r.maxb;
    return 1;

Lerr:
    error("неверный диапазон");
    return 0;
}

проц error(ткст msg)
{
    ошибки++;
    debug(РегВыр) скажифнс("ошибка: %s\n", msg);
//assert(0);
//*(сим*)0=0;
    throw new ИсключениеРегВыр(msg);
}

// p is following the \ сим
цел escape()
in
{
    assert(p < образец.length);
}
body
{   цел c;
    цел i;
    рсим tc;

    c = образец[p];		// none of the cases are multibyte
    switch (c)
    {
	case 'b':    c = '\b';	break;
	case 'f':    c = '\f';	break;
	case 'n':    c = '\n';	break;
	case 'r':    c = '\r';	break;
	case 't':    c = '\t';	break;
	case 'v':    c = '\v';	break;

	// BUG: Perl does \a and \e too, should we?

	case 'c':
	    ++p;
	    if (p == образец.length)
		goto Lretc;
	    c = образец[p];
	    // Note: we are deliberately not allowing дим letters
	    if (!(('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z')))
	    {
	     Lcerr:
		error("ожидалась буква после \\c");
		return 0;
	    }
	    c &= 0x1F;
	    break;

	case '0':
	case '1':
	case '2':
	case '3':
	case '4':
	case '5':
	case '6':
	case '7':
	    c -= '0';
	    for (i = 0; i < 2; i++)
	    {
		p++;
		if (p == образец.length)
		    goto Lretc;
		tc = образец[p];
		if ('0' <= tc && tc <= '7')
		{   c = c * 8 + (tc - '0');
		    // Treat overflow as if last
		    // digit was not an octal digit
		    if (c >= 0xFF)
		    {	c >>= 3;
			return c;
		    }
		}
		else
		    return c;
	    }
	    break;

	case 'x':
	    c = 0;
	    for (i = 0; i < 2; i++)
	    {
		p++;
		if (p == образец.length)
		    goto Lretc;
		tc = образец[p];
		if ('0' <= tc && tc <= '9')
		    c = c * 16 + (tc - '0');
		else if ('a' <= tc && tc <= 'f')
		    c = c * 16 + (tc - 'a' + 10);
		else if ('A' <= tc && tc <= 'F')
		    c = c * 16 + (tc - 'A' + 10);
		else if (i == 0)	// if no hex digits after \x
		{
		    // Not a значid \xXX sequence
		    return 'x';
		}
		else
		    return c;
	    }
	    break;

	case 'u':
	    c = 0;
	    for (i = 0; i < 4; i++)
	    {
		p++;
		if (p == образец.length)
		    goto Lretc;
		tc = образец[p];
		if ('0' <= tc && tc <= '9')
		    c = c * 16 + (tc - '0');
		else if ('a' <= tc && tc <= 'f')
		    c = c * 16 + (tc - 'a' + 10);
		else if ('A' <= tc && tc <= 'F')
		    c = c * 16 + (tc - 'A' + 10);
		else
		{
		    // Not a значid \uXXXX sequence
		    p -= i;
		    return 'u';
		}
	    }
	    break;

	default:
	    break;
    }
    p++;
Lretc:
    return c;
}

/* ==================== optimizer ======================= */

export проц оптимизируй()
{   ббайт[] прог;

    debug(РегВыр) win.скажи("РегВыр.оптимизируй()\n");
    прог = буф.вБайты();
    for (т_мера i = 0; 1;)
    {
	//эхо("\tprog[%d] = %d, %d\n", i, прог[i], РВткст);
	switch (прог[i])
	{
	    case РВконец:
	    case РВлюбсим:
	    case РВлюбзвезда:
	    case РВобрссыл:
	    case РВконстр:
	    case РВсим:
	    case РВлсим:
	    case РВдим:
	    case РВлдим:
	    case РВткст:
	    case РВлткст:
	    case РВтестбит:
	    case РВбит:
	    case РВнебит:
	    case РВдиапазон:
	    case РВнедиапазон:
	    case РВгранслова:
	    case РВнегранслова:
	    case РВцифра:
	    case РВнецифра:
	    case РВпространство:
	    case РВнепространство:
	    case РВслово:
	    case РВнеслово:
		return;

	    case РВначстр:
		i++;
		continue;

	    case РВили:
	    case РВнм:
	    case РВнмкю:
	    case РВвскоб:
	    case РВгоуту:
	    {
		auto bitbuf = new БуферВывода;
		auto r = new Range(bitbuf);
		бцел смещение;

		смещение = i;
		if (starrchars(r, прог[i .. прог.length]))
		{
		    debug(РегВыр) эхо("\tfilter built\n");
		    буф.простели(смещение, 1 + 4 + r.maxb);
		    буф.данные[смещение] = РВтестбит;
		    (cast(бкрат *)&буф.данные[смещение + 1])[0] = cast(бкрат)r.maxc;
		    (cast(бкрат *)&буф.данные[смещение + 1])[1] = cast(бкрат)r.maxb;
		    i = смещение + 1 + 4;
		    буф.данные[i .. i + r.maxb] = r.base[0 .. r.maxb];
		}
		return;
	    }
	    default:
		assert(0);
	}
    }
}

/////////////////////////////////////////
// OR the leading символ bits целo r.
// Limit the символ range from 0..7F,
// пробнсвер() will allow through anything over maxc.
// Return 1 if success, 0 if we can't build a filter or
// if there is no poцел to one.

export цел starrchars(Range r, ббайт[] прог)
{   рсим c;
    бцел maxc;
    бцел maxb;
    бцел длин;
    бцел b;
    бцел n;
    бцел m;
    ббайт* pop;

  //  debug(РегВыр) скажифнс("РегВыр.starrchars(прог = %p, progend = %p)\n", прог, progend);
    for (т_мера i = 0; i < прог.length;)
    {
	switch (прог[i])
	{
	    case РВсим:
		c = прог[i + 1];
		if (c <= 0x7F)
		    r.setbit2(c);
		return 1;

	    case РВлсим:
		c = прог[i + 1];
		if (c <= 0x7F)
		{   r.setbit2(c);
		    r.setbit2(std.ctype.tolower(cast(рсим)c));
		}
		return 1;

	    case РВдим:
	    case РВлдим:
		return 1;

	    case РВлюбсим:
		return 0;		// no poцел

	    case РВткст:
		длин = *cast(бцел *)&прог[i + 1];
		assert(длин);
		c = *cast(рсим *)&прог[i + 1 + бцел.sizeof];
		debug(РегВыр) скажифнс("\tРВткст %d, '%c'\n", длин, c);
		if (c <= 0x7F)
		    r.setbit2(c);
		return 1;

	    case РВлткст:
		длин = *cast(бцел *)&прог[i + 1];
		assert(длин);
		c = *cast(рсим *)&прог[i + 1 + бцел.sizeof];
		debug(РегВыр) скажифнс("\tРВлткст %d, '%c'\n", длин, c);
		if (c <= 0x7F)
		{   r.setbit2(std.ctype.toupper(cast(рсим)c));
		    r.setbit2(std.ctype.tolower(cast(рсим)c));
		}
		return 1;

	    case РВтестбит:
	    case РВбит:
		maxc = (cast(бкрат *)&прог[i + 1])[0];
		maxb = (cast(бкрат *)&прог[i + 1])[1];
		if (maxc <= 0x7F)
		    r.setbitmax(maxc);
		else
		    maxb = r.maxb;
		for (b = 0; b < maxb; b++)
		    r.base[b] |= прог[i + 1 + 4 + b];
		return 1;

	    case РВнебит:
		maxc = (cast(бкрат *)&прог[i + 1])[0];
		maxb = (cast(бкрат *)&прог[i + 1])[1];
		if (maxc <= 0x7F)
		    r.setbitmax(maxc);
		else
		    maxb = r.maxb;
		for (b = 0; b < maxb; b++)
		    r.base[b] |= ~прог[i + 1 + 4 + b];
		return 1;

	    case РВначстр:
	    case РВконстр:
		return 0;

	    case РВили:
		длин = (cast(бцел *)&прог[i + 1])[0];
		return starrchars(r, прог[i + 1 + бцел.sizeof .. прог.length]) &&
		       starrchars(r, прог[i + 1 + бцел.sizeof + длин .. прог.length]);

	    case РВгоуту:
		длин = (cast(бцел *)&прог[i + 1])[0];
		i += 1 + бцел.sizeof + длин;
		break;

	    case РВлюбзвезда:
		return 0;

	    case РВнм:
	    case РВнмкю:
		// длин, n, m, ()
		длин = (cast(бцел *)&прог[i + 1])[0];
		n   = (cast(бцел *)&прог[i + 1])[1];
		m   = (cast(бцел *)&прог[i + 1])[2];
		pop = &прог[i + 1 + бцел.sizeof * 3];
		if (!starrchars(r, pop[0 .. длин]))
		    return 0;
		if (n)
		    return 1;
		i += 1 + бцел.sizeof * 3 + длин;
		break;

	    case РВвскоб:
		// длин, ()
		длин = (cast(бцел *)&прог[i + 1])[0];
		n   = (cast(бцел *)&прог[i + 1])[1];
		pop = &прог[0] + i + 1 + бцел.sizeof * 2;
		return starrchars(r, pop[0 .. длин]);

	    case РВконец:
		return 0;

	    case РВгранслова:
	    case РВнегранслова:
		return 0;

	    case РВцифра:
		r.setbitmax('9');
		for (c = '0'; c <= '9'; c++)
		    r.bits[c] = 1;
		return 1;

	    case РВнецифра:
		r.setbitmax(0x7F);
		for (c = 0; c <= '0'; c++)
		    r.bits[c] = 1;
		for (c = '9' + 1; c <= r.maxc; c++)
		    r.bits[c] = 1;
		return 1;

	    case РВпространство:
		r.setbitmax(0x7F);
		for (c = 0; c <= r.maxc; c++)
		    if (межбукв_ли(c))
			r.bits[c] = 1;
		return 1;

	    case РВнепространство:
		r.setbitmax(0x7F);
		for (c = 0; c <= r.maxc; c++)
		    if (!межбукв_ли(c))
			r.bits[c] = 1;
		return 1;

	    case РВслово:
		r.setbitmax(0x7F);
		for (c = 0; c <= r.maxc; c++)
		    if (слово_ли(cast(рсим)c))
			r.bits[c] = 1;
		return 1;

	    case РВнеслово:
		r.setbitmax(0x7F);
		for (c = 0; c <= r.maxc; c++)
		    if (!слово_ли(cast(рсим)c))
			r.bits[c] = 1;
		return 1;

	    case РВобрссыл:
		return 0;

	    default:
		assert(0);
	}
    }
    return 1;
}


 export рсим[] замени(рсим[] формат)
{
    return замени3(формат, ввод, псовп[0 .. члоподстр + 1]);
}

// Static version that doesn't require a РегВыр объект to be created

 export static рсим[] замени3(рсим[] формат, рсим[] ввод, т_регсвер[] псовп)
{
    рсим[] результат;
    бцел c2;
    цел рснач;
    цел рскон;
    цел i;
   debug(РегВыр) скажифнс("замени3(формат = '%s', ввод = '%s')\n", формат, ввод);
    результат.length = формат.length;
    результат.length = 0;
    for (т_мера f = 0; f < формат.length; f++)
    {
	auto c = формат[f];
      L1:
	if (c != '$')
	{
	    результат ~= c;
	    continue;
	}
	++f;
	if (f == формат.length)
	{
	    результат ~= '$';
	    break;
	}
	c = формат[f];
	switch (c)
	{
	    case '&':
		рснач = псовп[0].рснач;
		рскон = псовп[0].рскон;
		goto Lstring;

	    case '`':
		рснач = 0;
		рскон = псовп[0].рснач;
		goto Lstring;

	    case '\'':
		рснач = псовп[0].рскон;
		рскон = ввод.length;
		goto Lstring;

	    case '0': case '1': case '2': case '3': case '4':
	    case '5': case '6': case '7': case '8': case '9':
		i = c - '0';
		if (f + 1 == формат.length)
		{
		    if (i == 0)
		    {
			результат ~= '$';
			результат ~= c;
			continue;
		    }
		}
		else
		{
		    c2 = формат[f + 1];
		    if (c2 >= '0' && c2 <= '9')
		    {   i = (c - '0') * 10 + (c2 - '0');
			f++;
		    }
		    if (i == 0)
		    {
			результат ~= '$';
			результат ~= c;
			c = cast(сим)c2;
			goto L1;
		    }
		}

		if (i < псовп.length)
		{   рснач = псовп[i].рснач;
		    рскон = псовп[i].рскон;
		    goto Lstring;
		}
		break;

	    Lstring:
		if (рснач != рскон)
		    результат ~= ввод[рснач .. рскон];
		break;

	    default:
		результат ~= '$';
		результат ~= c;
		break;
	}
    }
    return результат;
}

 export рсим[] замениСтарый(рсим[] формат)
{
    рсим[] результат;

//debug(РегВыр)  скажифнс("замени: this = %p so = %d, eo = %d\n", this, псовп[0].рснач, псовп[0].рскон);
//эхо("3input = '%.*т'\n", ввод);
    результат.length = формат.length;
    результат.length = 0;
    for (т_мера i; i < формат.length; i++)
    {
	auto c = формат[i];
	switch (c)
	{
	    case '&':
//эхо("сверь = '%.*т'\n", ввод[псовп[0].рснач .. псовп[0].рскон]);
		результат ~= ввод[псовп[0].рснач .. псовп[0].рскон];
		break;

	    case '\\':
		if (i + 1 < формат.length)
		{
		    c = формат[++i];
		    if (c >= '1' && c <= '9')
		    {   бцел j;

			j = c - '0';
			if (j <= члоподстр && псовп[j].рснач != псовп[j].рскон)
			    результат ~= ввод[псовп[j].рснач .. псовп[j].рскон];
			break;
		    }
		}
		результат ~= c;
		break;

	    default:
		результат ~= c;
		break;
	}
    }
    return результат;
}

}

export extern(D)
{

	import std.process;

	цел система (ткст команда)
	{
	return cast(цел) std.process.system(cast(ткст) команда);
	}

	цел пауза(){система("pause"); return 0;}
	
	цел пускпрог(цел режим, ткст путь, ткст[] арги)
	{
	return cast(цел) std.process.spawnvp(cast(цел) режим, cast(ткст) путь, cast(ткст[]) арги);
	}

	цел выппрог(ткст путь, ткст[] арги)
	{
	return cast(цел)  std.process.execv(cast(ткст) путь, cast(ткст[]) арги);
	}

	цел выппрог(ткст путь, ткст[] арги, ткст[] перемср)
	{
	return cast(цел) std.process.execve(cast(ткст) путь, cast(ткст[]) арги, cast(ткст[]) перемср);
	}

	цел выппрогcp(ткст путь, ткст[] арги)
	{
	return cast(цел) std.process.execvp(cast(ткст) путь, cast(ткст[]) арги);
	}

	цел выппрогср(ткст путь, ткст[] арги, ткст[] перемср)
	{
	return cast(цел) std.process.execve(cast(ткст) путь, cast(ткст[]) арги, cast(ткст[]) перемср);
	}
}
/////////////////////////////////////

/// Этот подкласс предназначен для небуферированных системных файловых потоков.

export extern (D) class Файл: Поток {

ук файлУк;
export:

  this() {
    //super();
     // win.скажинс("Вход в конструктор Файла");
    файлУк = null;    
    открытый(нет);
	 // win.скажинс("Выход из конструктора Файла");
	
  }

  // opens existing хэндл; use with care!
  this(ук флУк, ПРежимФайла режим) {
    //super();
	//win.скажинс("установил супер");
    this.файлУк = адаптВхоУкз(флУк);
    читаемый(cast(бул)(режим & ПРежимФайла.Ввод));	
    записываемый(cast(бул)(режим & ПРежимФайла.Вывод));	
    сканируемый(ДайТипФайла(файлУк) == 1); // FILE_TYPE_DISK   
	
  }
   
  this(ткст имяф, ПРежимФайла режим = cast(ПФРежим) 1)
  {
      this();
      открой(имяф, режим);
  }
  
    private проц выяснитьРежим(ПРежимФайла режим,
			 out ППраваДоступа доступ,
			 out ПСовмИспФайла шара,
			 out ПРежСоздФайла режСозд) {    
      шара |= ПСовмИспФайла.Чтение |  ПСовмИспФайла.Запись;
      if (режим & ПРежимФайла.Ввод) {
	доступ |= ППраваДоступа.ГенерноеЧтение; 
	//win.скажинс(фм("ГЕНЕРНОЕ_ЧТЕНИЕ = 0x%x",ППраваДоступа.ГенерноеЧтение));
	режСозд = ПРежСоздФайла.ОткрытьСущ;
      }
      if (режим & ПРежимФайла.Вывод) {
	доступ |= ППраваДоступа.ГенернаяЗапись ;
	//win.скажинс(фм("ППраваДоступа.ГенернаяЗапись = 0x%x", доступ));
	режСозд = ПРежСоздФайла.ОткрытьВсегда; 
      }
      if ((режим & ПРежимФайла.ВыводНов) == ПРежимФайла.ВыводНов) {
	режСозд = ПРежСоздФайла.СоздатьВсегда; 
      }
    } 

  проц открой(ткст имяф, ПРежимФайла режим = cast(ПФРежим) 1) {
 
     закрой();
    ППраваДоступа доступ;
	ПСовмИспФайла шара;
	ПРежСоздФайла режСозд;	
    выяснитьРежим(режим, доступ, шара, режСозд);	
    сканируемый(да);
    читаемый(cast(бул)(режим & ПРежимФайла.Ввод));
	записываемый(cast(бул)(режим & ПРежимФайла.Вывод));	
	//читаемый(); записываемый();	
	//win.скажинс("Процедура открытия файла...");
	//win.скажинс(фм("доступ = 0x%x шара = 0x%x режим = 0x%x",доступ, шара, режСозд));
	файлУк = СоздайФайл(имяф, доступ, шара,  null, режСозд, ПФайл.Нормальный, null);
    
    открытый(файлУк != cast(ук) НЕВЕРНХЭНДЛ);
	
    if (!открытый())
      throw new Исключение("stdrus.Файл.открой:Не удалось открыть или создать файл '" ~ имяф ~ "'");
    else if ((режим & ПРежимФайла.Добавка) == ПРежимФайла.Добавка)
      измпозКон(0);	
  }

  
    проц создай(ткст имяф, ПРежимФайла режим) {	
	закрой();
	открой(имяф, режим | ПРежимФайла.ВыводНов);
	
	  }

  проц создай(ткст имяф) {
      закрой();
	 открой(имяф, ПРежимФайла.ВыводНов);	
  }
  
  override проц закрой() {

    if (открытый())
	{ 
      super.закрой();
      if (файлУк)
	  {
	  ЗакройДескр(файлУк);
	  файлУк = null;	  	
      }
    }
  }
  ~this() { закрой(); }

     бдол размер() {
      проверьСканируемость(this.toString(),__FILE__,__LINE__);
      бцел sizehi;
      бцел sizelow = ДайРазмерФайла(файлУк,&sizehi);
      return (cast(бдол)sizehi << 32) + sizelow;
    }

  override т_мера читайБлок(ук буфер, т_мера размер) {
	  auto разм = размер;
	      проверьЧитаемость();
          ЧитайФайл(файлУк, адаптВхоУкз(буфер), разм, &разм, cast(АСИНХРОН*) null);
		  читатьдоКФ(размер == 0);
    return разм;
  }
   override т_мера пишиБлок(ук буфер, т_мера размер) {
    проверьЗаписываемость(this.toString());   
      ПишиФайл( файлУк, адаптВхоУкз(буфер), размер, &размер, null);   
    return размер;
  }
  override бдол сместись(дол смещение, ППозКурсора rel) {
    проверьСканируемость(this.toString(),__FILE__,__LINE__);
      цел hi = cast(цел)(смещение>>32);
      бцел low = УстановиУказательФайла(файлУк, cast(цел) смещение, &hi, rel);
      if ((low == cast(бцел)-1) && (ДайПоследнююОшибку() != 0))
	throw new Исключение("stdrus.Файл.сместись: не удаётся переместить файловый указатель",__FILE__, __LINE__);
      бдол результат = (cast(бдол)hi << 32) + low;
      читатьдоКФ(нет);
    return результат;
  }
  override т_мера доступно() {
    if (сканируемый()) {
      бдол lavail = размер - позиция;
      if (lavail > т_мера.max) lavail = т_мера.max;
      return cast(т_мера)lavail;
    }
    return 0;
  }
  
  ук  хэндл() { return адаптВыхУкз(файлУк); }

 }
/////////////////////////////////////////

export extern (D) class ФильтрПоток : Поток
 {
 
 
	extern(C) extern
	{
	  Поток п;              // source stream
	бул закрытьГнездо;
	}
	  
	export:

	 бул закрытьИсток(){return закрытьГнездо;}
	  проц закрытьИсток(бул б){закрытьГнездо = б;}
	  
	  	  /***
	   * Indicates the исток stream changed состояние and that this stream should reset
	   * any читаем, записываем, сканируем, открыт_ли and buffering флаги.
	   */
	  проц сбросьИсток() {
		if (п !is null) {
		  читаемый(п.читаемый());
		  записываемый(п.записываемый());
		  сканируемый(п.сканируемый());
		  открытый(п.открыт_ли());
		} else {
		  читаемый(нет);записываемый(нет);сканируемый(нет);
		  открытый(нет);
		}
		читатьдоКФ(нет); возвратКаретки(нет);
	  }
	  
	  /// Construct a ФильтрПоток for the given source.
		this(Поток исток) {
		this.п = исток;
		закрытьИсток(да);
		if (п !is null) {
		  читаемый(п.читаемый());
		  записываемый(п.записываемый());
		  сканируемый(п.сканируемый());
		  открытый(п.открыт_ли());
		} else {
		  читаемый(нет);записываемый(нет);сканируемый(нет);
		  открытый(нет);
		}
		читатьдоКФ(нет); возвратКаретки(нет);
	  }
	  
	  ~this(){}

	  // исток getter/setter

	  /***
	   * Get the current исток stream.
	   */
	   Поток исток(){return this.п;}

	  /***
	   * Уст the current исток stream.
	   *
	   * Setting the исток stream закройs this stream before attaching the new
	   * исток. Attaching an open stream reopens this stream and resets the stream
	   * состояние. 
	   */
	  проц исток(Поток п) {
		закрой();
		this.п = п;
		сбросьИсток();
	  }



	  // читай from исток
	  т_мера читайБлок(ук буфер, т_мера размер) {
		т_мера рез = п.читайБлок(адаптВхоУкз(буфер),размер);
		читатьдоКФ(рез == 0);
		return рез;
	  }

	  // пиши to исток
	  override т_мера пишиБлок(ук буфер, т_мера размер) {
		return п.пишиБлок(адаптВхоУкз(буфер),размер);
	  }

	  // закрой stream
	  override проц закрой() { 
		if (открытый()) {
		  super.закрой();
		  if (закрытьГнездо)
		п.закрой();
		}
	  }

	  // сместись on исток
	  override бдол сместись(дол смещение, ППозКурсора откуда) {
		читатьдоКФ(нет);
		return п.сместись(смещение,откуда);
	  }

	  т_мера доступно () { return п.доступно(); }
	  override проц слей() { super.слей(); п.слей(); }
}

export extern (D) class БуфПоток : ФильтрПоток {

extern(C) extern
{
      ббайт[] буфер; 
	  бцел текБуфПоз;  
	 бцел длинаБуф; 
	  бул черновойБуф;
	   бцел позИстокаБуф;  
	  бдол позПотока; 
 }
 
export:
	
	  проц устБуфер(ббайт[] буф){буфер = буф;}
	  ббайт[] дайБуфер(){return буфер;}
  
	  проц устТекБуфПоз(бцел тбп){текБуфПоз = тбп;}
	  бцел дайТекБуфПоз(){return текБуфПоз;}
  
  
	  проц устДлинуБуф(бцел дб){длинаБуф = дб;}
	  бцел дайДлинуБуф(){return длинаБуф;}
  

	  проц устЧерновой(бул чб){черновойБуф = чб;}
	  бул дайЧерновойБуф(){return черновойБуф;}
	  
  
	  проц устПозИстокаБуф(бцел пиб){позИстокаБуф = пиб;}
	  бцел дайПозИстокаБуф(){return позИстокаБуф;}
	  
	
	  проц устПозПотока(бдол пп){позПотока = пп;}
	  бдол дайПозПотока(){return позПотока;}

  invariant() {
    assert(длинаБуф <= буфер.length,вЮ8(cast(ткст)"Несоблюдение первого требования инварианта класса БУфПоток"));
    assert(текБуфПоз <= длинаБуф, вЮ8(cast(ткст)"Несоблюдение второго требования инварианта класса БУфПоток"));
     assert(позИстокаБуф <= длинаБуф, вЮ8(cast(ткст)"Несоблюдение третьего требования инварианта класса БУфПоток"));
  }

  const бцел дефРазмБуфера = 8192;

  /***
   * Create a buffered stream for the stream исток with the буфер размер
   * bufferSize.
   */
  this(Поток исток, бцел размБуф = дефРазмБуфера) {
  
   super(исток);
   assert(super.п == исток);
		  this.п = super.п;
		  читаемый(super.читаемый());
		  записываемый(super.записываемый());
		  сканируемый(super.сканируемый());
		  открытый(super.открыт_ли());
 
   if (размБуф)
    буфер = new ббайт[размБуф];	 
	черновойБуф = нет;	  
  }
  
  ~this(){}

  override проц сбросьИсток() {
    super.сбросьИсток();
    позПотока = 0;
    длинаБуф = позИстокаБуф = текБуфПоз = 0;
    черновойБуф = нет;
  }

  // reads block of данные of specified размер using any buffered данные
  // returns actual number of bytes читай
  override т_мера читайБлок(ук результат, т_мера длин) {
    if (длин == 0) return 0;

    проверьЧитаемость(this.toString());

    ббайт* outbuf = cast(ббайт*)адаптВхоУкз(результат);
    т_мера readsize = 0;

    if (текБуфПоз + длин < длинаБуф) {
      // буфер has all the данные so copy it
      outbuf[0 .. длин] = буфер[текБуфПоз .. текБуфПоз+длин];
      текБуфПоз += длин;
      readsize = длин;
      goto ExitRead;
    }

    readsize = длинаБуф - текБуфПоз;
    if (readsize > 0) {
      // буфер has some данные so copy what is left
      outbuf[0 .. readsize] = буфер[текБуфПоз .. длинаБуф];
      outbuf += readsize;
      текБуфПоз += readsize;
      длин -= readsize;
    }

    слей();

    if (длин >= буфер.length) {
      // буфер can't hold the данные so fill output буфер directly
      т_мера siz = super.читайБлок(outbuf, длин);
      readsize += siz;
      позПотока += siz;
    } else {
      // читай a new block целo буфер
      длинаБуф = super.читайБлок(буфер.ptr, буфер.length);
      if (длинаБуф < длин) длин = длинаБуф;
      outbuf[0 .. длин] = буфер[0 .. длин];
      позИстокаБуф = длинаБуф;
      позПотока += длинаБуф;
      текБуфПоз = длин;
      readsize += длин;
    }

  ExitRead:
    return readsize;
  }

  // пиши block of данные of specified размер
  // returns actual number of bytes written
  override т_мера пишиБлок(ук результат, т_мера длин) {
    проверьЗаписываемость(this.toString());

    ббайт* буф = cast(ббайт*)адаптВхоУкз(результат);
    т_мера writesize = 0;

    if (длинаБуф == 0) {
      // буфер is empty so fill it if possible
      if ((длин < буфер.length) && (читаемый())) {
	// читай in данные if the буфер is currently empty
	длинаБуф = п.читайБлок(буфер.ptr, буфер.length);
	позИстокаБуф = длинаБуф;
	позПотока += длинаБуф;
	  
      } else if (длин >= буфер.length) {
	// буфер can't hold the данные so пиши it directly and exit
	writesize = п.пишиБлок(буф, длин);
	позПотока += writesize;
	goto ExitWrite;
      }
    }

    if (текБуфПоз + длин <= буфер.length) {
      // буфер has space for all the данные so copy it and exit
      буфер[текБуфПоз .. текБуфПоз+длин] = буф[0 .. длин];
      текБуфПоз += длин;
      длинаБуф = текБуфПоз > длинаБуф ? текБуфПоз : длинаБуф;
      writesize = длин;
      черновойБуф = да;
      goto ExitWrite;
    }

    writesize = буфер.length - текБуфПоз;
    if (writesize > 0) { 
      // буфер can take some данные
      буфер[текБуфПоз .. буфер.length] = буф[0 .. writesize];
      текБуфПоз = длинаБуф = буфер.length;
      буф += writesize;
      длин -= writesize;
      черновойБуф = да;
    }

    assert(текБуфПоз == буфер.length);
    assert(длинаБуф == буфер.length);

    слей();

    writesize += пишиБлок(буф,длин);

  ExitWrite:
    return writesize;
  }

  override бдол сместись(дол смещение, ППозКурсора откуда) {
    проверьСканируемость(this.toString(),__FILE__,__LINE__);

    if ((откуда != ППозКурсора.Тек) ||
	(смещение + текБуфПоз < 0) ||
	(смещение + текБуфПоз >= длинаБуф)) {
      слей();
      позПотока = п.сместись(смещение,откуда);
    } else {
      текБуфПоз += смещение;
    }
    читатьдоКФ(нет);
    return позПотока-позИстокаБуф+текБуфПоз;
  }

  // Buffered читайСтр - Dave Fladebo
  // reads a строка, terminated by either CR, LF, CR/LF, or EOF
  // reusing the memory in буфер if результат will fit, otherwise
  // will reallocate (using concatenation)
  template TreadLine(T) {
    T[] читайСтр(T[] вхБуфер)
      {
	т_мера    размерСтрок = 0;
	бул    haveCR = нет;
	T       c = '\0';
	т_мера    инд = 0;
	ббайт*  pc = cast(ббайт*)&c;

      L0:
	for(;;) {
	  бцел старт = текБуфПоз;
	L1:
	  foreach(ббайт b; буфер[старт .. длинаБуф]) {
	    текБуфПоз++;
	    pc[инд] = b;
	    if(инд < T.sizeof - 1) {
	      инд++;
	      continue L1;
	    } else {
	      инд = 0;
	    }
	    if(c == '\n' || haveCR) {
	      if(haveCR && c != '\n') текБуфПоз--;
	      break L0;
	    } else {
	      if(c == '\r') {
		haveCR = да;
	      } else {
		if(размерСтрок < вхБуфер.length) {
		  вхБуфер[размерСтрок] = c;
		} else {
		  вхБуфер ~= c;
		}
		размерСтрок++;
	      }
	    }
	  }
	  слей();
	  т_мера рез = super.читайБлок(буфер.ptr, буфер.length);
	  if(!рез) break L0; // EOF
	  позИстокаБуф = длинаБуф = рез;
	  позПотока += рез;
	}

	return вхБуфер[0 .. размерСтрок];
      }
  } // template TreadLine(T)

  override ткст читайСтр(ткст вхБуфер) {
    if (верниЧтоЕсть())
      return super.читайСтр(вхБуфер);
    else
      return TreadLine!(сим).читайСтр(вхБуфер);
  }
  

  override шим[] читайСтрШ(шим[] вхБуфер) {
    if (верниЧтоЕсть())
      return super.читайСтрШ(вхБуфер);
    else
      return TreadLine!(шим).читайСтр(вхБуфер);
  }
 

  override проц слей()
  out {
    assert(текБуфПоз == 0);
    assert(позИстокаБуф == 0);
    assert(длинаБуф == 0);
  }
  body {
    if (записываемый() && черновойБуф) {
      if (позИстокаБуф != 0 && сканируемый()) {
	// move actual файл poцелer to front of буфер
	позПотока = п.сместись(-позИстокаБуф, ППозКурсора.Тек);
      }
      // пиши буфер out
      позИстокаБуф = п.пишиБлок(буфер.ptr, длинаБуф);
      if (позИстокаБуф != длинаБуф) {
	throw new Исключение("stdrus.БуфПоток.слей: Не удаётся запись в поток", __FILE__, __LINE__);
      }
    }
    super.слей();
    дол diff = cast(дол)текБуфПоз-позИстокаБуф;
    if (diff != 0 && сканируемый()) {
      // move actual файл poцелer to current позиция
      позПотока = п.сместись(diff, ППозКурсора.Тек);
    }
    // reset буфер данные to be empty
    позИстокаБуф = текБуфПоз = длинаБуф = 0;
    черновойБуф = нет;
  }

  // returns да if end of stream is reached, нет otherwise
  override бул кф() {
    if ((буфер.length == 0) || !читаемый()) {
      return super.кф();
    }
    // some simple tests to avoid flushing
    if (верниЧтоЕсть() || текБуфПоз != длинаБуф)
      return нет;
    if (длинаБуф == буфер.length)
      слей();
    т_мера рез = super.читайБлок(&буфер[длинаБуф],буфер.length-длинаБуф);
    позИстокаБуф +=  рез;
    длинаБуф += рез;
    позПотока += рез;
    return читатьдоКФ;
  }

  // returns размер of stream
  override бдол размер() {
    if (черновойБуф) слей();
    return п.размер();
  }

  // returns estimated number of bytes доступно for immediate reading
  override т_мера доступно() {
    return длинаБуф - текБуфПоз;
  }
  
  override проц закрой(){слей(); super.закрой();}
}

///////////////////// 
export extern (D) class БуфФайл: БуфПоток {

alias ФильтрПоток.п п;
export:

  /// opens файл for reading
  this() {
//  win.скажинс("Вход в конструктор БуфФайла");
	 super(new Файл); 
   // win.скажинс("Выход из конструктора БуфФайла");
 // this.п = super.п;
  }
  
  ~this(){}

  /// opens файл in requested режим and буфер размер
  this(ткст имяф, ПРежимФайла режим = cast(ПРежимФайла) 1,
       бцел размБуф = дефРазмБуфера) {
    super(new Файл(имяф,режим),размБуф);
	//this.п = super.п;
  }

  /// opens файл for reading with requested буфер размер
  this(Файл файл, бцел размБуф = дефРазмБуфера) {
    super(файл,размБуф);
	//this.п = super.п;
  }

  /// opens existing хэндл; use with care!
  this(ук  файлУк, ПРежимФайла режим, бцел размбуфа) {
    super(new Файл(адаптВхоУкз(файлУк),режим),размбуфа);
	//this.п = super.п;
  }

  /// opens файл in requested режим
  проц открой(ткст имяф, ПРежимФайла режим = cast(ПРежимФайла) 1) {
    Файл sf = cast(Файл)п;
	this.записываемый(п.записываемый());
    сканируемый(да);
    читаемый(cast(бул)(режим & ПРежимФайла.Ввод));
	записываемый(cast(бул)(режим & ПРежимФайла.Вывод));	
    sf.открой(имяф,режим);
    сбросьИсток();
  }

  /// creates файл in requested режим
  проц создай(ткст имяф, ПРежимФайла режим = cast(ПРежимФайла) 6) {
  //скажифнс("Режим создания $i", режим);
    Файл sf = cast(Файл) п;
	 сканируемый(да);
    читаемый(cast(бул)(режим & ПРежимФайла.Ввод));
	записываемый(cast(бул)(режим & ПРежимФайла.Вывод));	
    sf.создай(имяф,режим);
    сбросьИсток();
  }
  
  проц удали(ткст фимя)
  {
  Поток п = п;
  delete п;
  super.удали(фимя);
  }
  
  
   override проц закрой() {
		super.закрой();
		читатьдоКФ(нет); возвратКаретки(нет);открытый(нет);читаемый(нет);
		записываемый(нет);сканируемый(нет);
	  }
  
}

export extern(D) БуфФайл объБуфФайл(){return new БуфФайл;}

export extern (D) class ПотокЭндианец : ФильтрПоток {

export:

  Эндиан эндиан;        /// Endianness property of the исток stream.

  this(Поток исток, Эндиан end) {
    super(исток);
    эндиан = end;
  }

  ~this(){}

  проц устЭндиан(Эндиан э){this.эндиан = э;}
  проц выведиЭндиан()
  { 
  ткст эн;
  if(эндиан == 1) эн = "ЛитлЭндиан";
   else if(эндиан == 2)эн = "БигЭндиан";  
  win.скажинс(фм("Установленная эндианность потока: "~эн));   
  }
   
  цел читайМПБ(цел размВозврСим) {
    ббайт[4] BOM_buffer;
    цел n = 0;       // the number of читай bytes
    цел результат = -1; // the last match or -1
    for (цел i=0; i < 5/*ЧМПБ*/; ++i) {
      цел j;
      ббайт[] bom = МеткиПорядкаБайтов[i];
      for (j=0; j < bom.length; ++j) {
	if (n <= j) { // have to читай more
	  if (кф())
	    break;
	  читайРовно(&BOM_buffer[n++],1);
	}
	if (BOM_buffer[j] != bom[j])
	  break;
      }
      if (j == bom.length) // found a match
	результат = i;
    }
    цел m = 0;
    if (результат != -1) {
      эндиан = МПБЭндиан[результат]; // установи stream endianness
      m = МеткиПорядкаБайтов[результат].length;
    }
    if ((размВозврСим == 1 && результат == -1) || (результат == МПБ.Ю8)) {
      while (n-- > m)
	отдайс(BOM_buffer[n]);
    } else { // should eventually support возврат for дим as well
      if (n & 1) // make sure we have an even number of bytes
	читайРовно(&BOM_buffer[n++],1);
      while (n > m) {
	n -= 2;
	шим cw = *(cast(шим*)&BOM_buffer[n]);
	фиксируйПБ(&cw,2);
	отдайш(cw);
      }
    }
	//win.скажи("читайМПБ!");
    return результат;
  }

  /***
   * Correct the байт order of буфер to match native endianness.
   * размер must be even.
   */
   проц фиксируйПБ(ук буфер, бцел размер) {
    if (эндиан != _эндиан) {
      ббайт* startb = cast(ббайт*)адаптВхоУкз(буфер);
      бцел* старт = cast(бцел*)адаптВхоУкз(буфер);
      switch (размер) {
      case 0: break;
      case 2: {
	ббайт x = *startb;
	*startb = *(startb+1);
	*(startb+1) = x;
	break;
      }
      case 4: {
	*старт = развербит(*старт);
	break;
      }
      default: {
	бцел* end = cast(бцел*)(буфер + размер - бцел.sizeof);
	while (старт < end) {
	  бцел x = развербит(*старт);
	  *старт = развербит(*end);
	  *end = x;
	  ++старт;
	  --end;
	}
	startb = cast(ббайт*)старт;
	ббайт* endb = cast(ббайт*)end;
	цел длин = бцел.sizeof - (startb - endb);
	if (длин > 0)
	  фиксируйПБ(startb,длин);
      }
      }
    }
  }

  /***
   * Correct the байт order of the given буфер in blocks of the given размер and
   * repeated the given number of times.
   * размер must be even.
   */
   проц фиксируйБлокПБ(ук буфер, бцел размер, т_мера повтор) {
    while (повтор--) {
      фиксируйПБ(адаптВхоУкз(буфер),размер);
      буфер += размер;
    }
  }

  override проц читай(out байт x) { читайРовно(&x, x.sizeof); }
  override проц читай(out ббайт x) { читайРовно(&x, x.sizeof); }
  проц читай(out крат x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }
  проц читай(out бкрат x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }
  проц читай(out цел x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }
  проц читай(out бцел x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }
  проц читай(out дол x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }
  проц читай(out бдол x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }
  проц читай(out плав x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }
  проц читай(out дво x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }
  проц читай(out реал x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }
  проц читай(out вплав x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }
  проц читай(out вдво x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }
  проц читай(out вреал x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }
  проц читай(out кплав x) { читайРовно(&x, x.sizeof); фиксируйБлокПБ(&x,плав.sizeof,2); }
  проц читай(out кдво x) { читайРовно(&x, x.sizeof); фиксируйБлокПБ(&x,дво.sizeof,2); }
  проц читай(out креал x) { читайРовно(&x, x.sizeof); фиксируйБлокПБ(&x,реал.sizeof,2); }
  проц читай(out шим x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }
  проц читай(out дим x) { читайРовно(&x, x.sizeof); фиксируйПБ(&x,x.sizeof); }

  шим бериш() {
    шим c;
    if (предВкар) {
      предВкар = нет;
      c = бериш();
      if (c != '\n') 
	return c;
    }
    if (возврат.length > 1) {
      c = возврат[возврат.length - 1];
      возврат.length = возврат.length - 1;
    } else {
      ук буф = &c;
      т_мера n = читайБлок(буф,2);
      if (n == 1 && читайБлок(буф+1,1) == 0)
          throw new Исключение("stdrus.ПотокЭндианец.бериш: Недостаточно данных в потоке",__FILE__, __LINE__);
      фиксируйПБ(&c,c.sizeof);
    }
    return c;
  }

  шим[] читайТкстШ(т_мера length) {
    шим[] результат = new шим[length];
    читайРовно(результат.ptr, результат.length * шим.sizeof);
    фиксируйБлокПБ(&результат,2,length);
    return результат;
  }

  /// Write the specified МПБ b to the исток stream.
  проц пишиМПБ(МПБ b) {
    ббайт[] bom = МеткиПорядкаБайтов[b];
    пишиБлок(bom.ptr, bom.length);
  }

  override проц пиши(байт x) { пишиРовно(&x, x.sizeof); }
  override проц пиши(ббайт x) { пишиРовно(&x, x.sizeof); }
  проц пиши(крат x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }
  проц пиши(бкрат x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }
  проц пиши(цел x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }
  проц пиши(бцел x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }
  проц пиши(дол x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }
  проц пиши(бдол x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }
  проц пиши(плав x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }
  проц пиши(дво x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }
  проц пиши(реал x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }
  проц пиши(вплав x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }
  проц пиши(вдво x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }
  проц пиши(вреал x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }
  проц пиши(кплав x) { фиксируйБлокПБ(&x,плав.sizeof,2); пишиРовно(&x, x.sizeof); }
  проц пиши(кдво x) { фиксируйБлокПБ(&x,дво.sizeof,2); пишиРовно(&x, x.sizeof); }
  проц пиши(креал x) { фиксируйБлокПБ(&x,реал.sizeof,2); пишиРовно(&x, x.sizeof);  }
  проц пиши(шим x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }
  проц пиши(дим x) { фиксируйПБ(&x,x.sizeof); пишиРовно(&x, x.sizeof); }

  проц пишиТкстШ(шим[] str) {
    foreach(шим cw;str) {
      фиксируйПБ(&cw,2);
      п.пишиРовно(&cw, 2);
    }
  }

  override бул кф() { return п.кф() && !верниЧтоЕсть();  }
  override бдол размер() { return п.размер();  }

}

export class ПотокПамяти: ТПотокМассив!(ббайт[])
 {
export:


  ~this(){}

  this(ббайт[] буф = null) {super (буф);  }
  this(байт[] буф) { this(cast(ббайт[]) буф);}	/// ditto
  this(ткст буф) {this(cast(ббайт[]) буф); } /// ditto

  /// Ensure the stream can hold count bytes.
  проц резервируй(т_мера count) {
    if (тек + count > буф.length)
      буф.length = cast(бцел)((тек + count) * 2);
  }

  override т_мера пишиБлок(ук буфер, т_мера размер) {
    резервируй(размер);
    return super.пишиБлок(адаптВхоУкз(буфер),размер);
  }
 
 override т_мера читайБлок(ук буфер, т_мера размер) {  return super.читайБлок(адаптВхоУкз(буфер), размер); }

 override бдол сместись(дол смещение, ППозКурсора rel) {  return super.сместись(смещение, rel); }

 override т_мера доступно () { return super.доступно(); }

 override ббайт[] данные() {  return super.данные(); }

 override ткст вТкст() {  return super.вТкст ();  }


}

export extern (D) class РПФайлПоток : ТПотокМассив!(РПФайл) {
export:

  /// Create stream wrapper for файл.
  this(РПФайл файл) {
    super (файл);
    РПФайл.Режим режим = файл.режим;
    записываемый(режим > РПФайл.Режим.Чтение);
  }
  
  ~this(){}

  override проц слей() {
    if (открытый()) {
      super.слей();
      буф.слей();
    }
  }

  override проц закрой() {
    if (открытый()) {
      super.закрой();
      delete буф;
      буф = null;
    }
  }
  
override  т_мера читайБлок(ук буфер, т_мера размер) {  return super.читайБлок(адаптВхоУкз(буфер), размер); }

 override т_мера пишиБлок(ук буфер, т_мера размер) { return super.пишиБлок(адаптВхоУкз(буфер), размер);  }

 override бдол сместись(дол смещение, ППозКурсора rel) {  return super.сместись(смещение, rel); }

 override т_мера доступно () { return super.доступно(); }

 override ббайт[] данные() {  return super.данные(); }

 override ткст вТкст() {  return super.вТкст ();  }
 
  override проц удали(ткст фимя)
  {
  delete буф;
  super.удали(фимя);
  }
}
 
export extern (D) class ПотокСрез : ФильтрПоток {

export extern (C) extern
{
     бдол поз;  // our позиция relative to low
    бдол низ; // низ stream смещение.
    бдол верх; // верх stream смещение.
    бул ограничен; // upper-ограничен by верх.
	Поток п;
}

  export:
  this (Поток п, бдол нз)
  in {
    assert (нз <= п.размер ());
  }
  body {
	super(п);
	this.п =  super.исток();
    this.низ = нз; 
    this.верх = 0;
    this.ограничен = нет;	 
	 }

  ~this(){delete п;}
  
  this (Поток п, бдол нз, бдол вх)
  in {
    assert (нз <= вх);
    assert (вх <= п.размер ());
  }
  body {  
	super(п);
	this.п =  super.исток();
	this.позиция(п.позиция());
    this.низ = нз; 
    this.верх = вх; 
    this.ограничен = да; 
	   }

  invariant() {
    if (ограничен)
      assert (поз <= верх - низ, вЮ8(cast(ткст)"Несоблюдение требования инварианта\n\tкласса ПотокСрез (ограничен)"));
    else
      assert (поз <= п.размер - низ, вЮ8(cast(ткст)"Несоблюдение требования инварианта\n\tкласса ПотокСрез (неограничен)"));
  }

  override т_мера читайБлок (ук буфер, т_мера размер) {
    проверьЧитаемость();
    if (ограничен && размер > верх - низ - поз)
	размер = cast(т_мера)(верх - низ - поз);
    бдол bp = п.позиция;
    if (сканируемый)
      п.позиция = низ + поз;
    т_мера возвр = super.читайБлок(адаптВхоУкз(буфер), размер);
    if (сканируемый) {
      поз = п.позиция - низ;
      п.позиция = bp;
    }
    return возвр;
  }

  override т_мера пишиБлок (ук буфер, т_мера размер) {
    проверьЗаписываемость(this.toString());
    if (ограничен && размер > верх - низ - поз)
	размер = cast(т_мера)(верх - низ - поз);
    бдол bp = п.позиция;
    if (сканируемый)
      п.позиция = низ + поз;
    т_мера возвр = п.пишиБлок(адаптВхоУкз(буфер), размер);
    if (сканируемый) {
      поз = п.позиция - низ;
      п.позиция = bp;
    }
    return возвр;
  }

  override бдол сместись(дол смещение, ППозКурсора rel) {
    проверьСканируемость("ПотокСрез",__FILE__,__LINE__);
    дол spos;

    switch (rel) {
      case ППозКурсора.Уст:
	spos = смещение;
	break;
      case ППозКурсора.Тек:
	spos = cast(дол)(поз + смещение);
	break;
      case ППозКурсора.Кон:
	if (ограничен)
	  spos = cast(дол)(верх - низ + смещение);
	else
	  spos = cast(дол)(п.размер - низ + смещение);
	break;
      default:
	assert(0);
    }

    if (spos < 0)
      поз = 0;
    else if (ограничен && spos > верх - низ)
      поз = верх - низ;
    else if (!ограничен && spos > п.размер - низ)
      поз = п.размер - низ;
    else
      поз = cast(бдол)spos;

    читатьдоКФ(нет);
    return поз;
  }

  override т_мера доступно () {
    т_мера рез = п.доступно;
    бдол bp = п.позиция;
    if (bp <= поз+низ && поз+низ <= bp+рез) {
      if (!ограничен || bp+рез <= верх)
	return cast(т_мера)(bp + рез - поз - низ);
      else if (верх <= bp+рез)
	return cast(т_мера)(верх - поз - низ);
    }
    return 0;
  }


}

/////////////////////////


export extern(D) class РПФайл
{
export:

alias длина length;

    enum Режим
    {
	Чтение,		/// read existing file
	ЧтенЗапНов,	/// delete existing file, write new file
	ЧтенЗап,	/// read/write existing file, создай if not existing
	ЧтенКопирПриЗап, /// read/write existing file, copy on write
	
    }
	
    this(ткст имяф)
    {
		this(имяф, Режим.Чтение, 0, null);
    }
    
	
    this(ткст имяф, Режим режим, бдол размер, ук адрес,
			т_мера окно = 0)
    {
		this.имяф = имяф;
		this.м_режим = режим;
		this.окно = окно;
		this.адрес = адаптВхоУкз(адрес);
	
		version (Win32)
		{
			ук p;
		    ППраваДоступа dwDesiredAccess2;
			ПСовмИспФайла dwShareMode;
			ПРежСоздФайла dwCreationDisposition;
			ППамять flProtect;
	    
			if (винВерсия & 0x80000000 && (винВерсия & 0xFF) == 3)
			{
			    throw new ФайлИскл(имяф,
				"Win32s не реализует рпфайлы");
			}
	    
			switch (режим)
			{
			    case Режим.Чтение:
				dwDesiredAccess2 =ППраваДоступа.ГенерноеЧтение;
				dwShareMode = ПСовмИспФайла.Чтение;
				dwCreationDisposition = ПРежСоздФайла.ОткрытьСущ;
				flProtect = ППамять.СтрТолькоЧтен ;
				dwDesiredAccess = ППамять.Чтение ;
				break;

			    case Режим.ЧтенЗапНов:
				assert(размер != 0);
				dwDesiredAccess2 =ППраваДоступа.ГенерноеЧтение | ППраваДоступа.ГенернаяЗапись;
				dwShareMode = ПСовмИспФайла.Чтение |  ПСовмИспФайла.Запись;
				dwCreationDisposition = ПРежСоздФайла.СоздатьВсегда;
				flProtect = ППамять.СтрЗапЧтен;
				dwDesiredAccess = ППамять.Запись;
				break;

			    case Режим.ЧтенЗап:
				dwDesiredAccess2 =ППраваДоступа.ГенерноеЧтение | ППраваДоступа.ГенернаяЗапись;
				dwShareMode = ПСовмИспФайла.Чтение |  ПСовмИспФайла.Запись;
				dwCreationDisposition = ПРежСоздФайла.ОткрытьВсегда;
				flProtect = ППамять.СтрЗапЧтен;
				dwDesiredAccess = ППамять.Запись;
				break;

			    case Режим.ЧтенКопирПриЗап:
				if (винВерсия & 0x80000000)
				{
				    throw new ФайлИскл(имяф,
					"Win9x не реализует копирование при записи");
				}
				dwDesiredAccess2 =ППраваДоступа.ГенерноеЧтение | ППраваДоступа.ГенернаяЗапись;
				dwShareMode = ПСовмИспФайла.Чтение |  ПСовмИспФайла.Запись;
				dwCreationDisposition = ПРежСоздФайла.ОткрытьСущ;
				flProtect = ППамять.СтрЗапКоп;
				dwDesiredAccess = ППамять.Копия;
				break;

			    default:
				assert(0);
			}
		
			if (имяф)
			{
				if (useWfuncs)
				{
					auto namez = имяф;
					hFile = СоздайФайл(namez,
							dwDesiredAccess2,
							dwShareMode,
							null,
							dwCreationDisposition,
							ПФайл.Нормальный,
							cast(ук) null);
				}
				else
				{
					auto namez = имяф;
					hFile =cast(ук) СоздайФайлА(namez,
							dwDesiredAccess2,
							dwShareMode,
							null,
							dwCreationDisposition,
							ПФайл.Нормальный,
							cast(ук)null);
				}
				if (hFile == cast(ук) НЕВЕРНХЭНДЛ)
					goto err1;
			}
			else
				hFile = null;
		
			цел hi = cast(цел)(размер>>32);
			hFileMap = СоздайМаппингФайлаА(hFile, null, flProtect, hi, cast(бцел)размер, null);
			if (hFileMap == null)               // mapping failed
				goto err1;
		
			if (размер == 0)
			{
				бцел sizehi;
				бцел sizelow = ДайРазмерФайла(hFile,&sizehi);
				размер = (cast(бдол)sizehi << 32) + sizelow;
			}
			this.размер = размер;
		
			т_мера initial_map = (окно && 2*окно<размер)? 2*окно : cast(т_мера)размер;
			p = ВидФайлаВКартуДоп(hFileMap, dwDesiredAccess, 0, 0, initial_map, адрес);
			if (!p) goto err1;
			data = p[0 .. initial_map];
		
			debug (РПФайл) скажифнс("РПФайл.this(): p = %p, размер = %d\n", p, размер);
			return;
		
			err1:
			if (hFileMap != null)
				ЗакройДескр(hFileMap);
			hFileMap = null;
		
			if (hFile !=cast(ук) НЕВЕРНХЭНДЛ)
				ЗакройДескр(hFile);
			hFile = cast(ук) НЕВЕРНХЭНДЛ;
		
			errNo();
		}
		else version (Posix)
		{
			auto namez = вТкст0(имяф);
			ук p;
			цел oflag;
			цел fрежим;
	
			switch (режим)
			{
				case Режим.Чтение:
					флаги = MAP_SHARED;
					prot = PROT_READ;
					oflag = O_RDONLY;
					fрежим = 0;
					break;
	
				case Режим.ЧтенЗапНов:
					assert(размер != 0);
					флаги = MAP_SHARED;
					prot = PROT_READ | PROT_WRITE;
					oflag = O_CREAT | O_RDWR | O_TRUNC;
					fрежим = 0660;
					break;
	
				case Режим.ЧтенЗап:
					флаги = MAP_SHARED;
					prot = PROT_READ | PROT_WRITE;
					oflag = O_CREAT | O_RDWR;
					fрежим = 0660;
					break;
	
				case Режим.ЧтенКопирПриЗап:
					флаги = MAP_PRIVATE;
					prot = PROT_READ | PROT_WRITE;
					oflag = O_RDWR;
					fрежим = 0;
					break;

				default:
					assert(0);
			}
	
			if (имяф.length)
			{	
				struct_stat statbuf;
	
				fd = os.posix.open(namez, oflag, fрежим);
				if (fd == -1)
				{
					// эхо("\topen error, errno = %d\n",getErrno());
					errNo();
				}
	
				if (os.posix.fstat(fd, &statbuf))
				{
					//эхо("\tfstat error, errno = %d\n",getErrno());
					os.posix.close(fd);
					errNo();
				}
	
				if (prot & PROT_WRITE && размер > statbuf.st_size)
				{
					// Need to make the file размер bytes big
					os.posix.lseek(fd, cast(цел)(размер - 1), SEEK_SET);
					сим c = 0;
					os.posix.write(fd, &c, 1);
				}
				else if (prot & PROT_READ && размер == 0)
					размер = cast(бдол)statbuf.st_size;
			}
			else
			{
				fd = -1;
version (linux)			флаги |= MAP_ANONYMOUS;
else version (OSX)		флаги |= MAP_ANON;
else version (FreeBSD)		флаги |= MAP_ANON;
else version (Solaris)		флаги |= MAP_ANON;
else				static assert(0);
			}
			this.размер = размер;
			т_мера initial_map = (окно && 2*окно<размер)? 2*окно : cast(т_мера)размер;
			p = mmap(адрес, initial_map, prot, флаги, fd, 0);
			if (p == MAP_FAILED) {
			  if (fd != -1)
			    os.posix.close(fd);
			  errNo();
			}

			data = p[0 .. initial_map];
		}
		else
		{
			static assert(0);
		}
	}

	/**
	 * Flushes pending output and closes the memory mapped file.
	 */
	~this()
	{
		debug (РПФайл) win.скажи("РПФайл.~this()\n");
		unmap();
		version (Win32)
		{
			if (hFileMap != null && ЗакройДескр(hFileMap) != да)
				errNo();
			hFileMap = null;

			if (hFile && hFile != cast(ук) НЕВЕРНХЭНДЛ&& ЗакройДескр(hFile) != да)
				errNo();
			hFile = cast(ук) НЕВЕРНХЭНДЛ;
		}
		else version (Posix)
		{
			if (fd != НЕВЕРНХЭНДЛ&& os.posix.close(fd) == cast(ук) НЕВЕРНХЭНДЛ)
				errNo();
			fd = cast(ук) НЕВЕРНХЭНДЛ;
		}
		else
		{
			static assert(0);
		}
		data = null;
	}

	/* Flush any pending output.
	*/
	проц слей()
	{
		debug (РПФайл) win.скажи("РПФайл.слей()\n");
		version (Win32)
		{
			СлейВидФайла(data.ptr, data.length);
		}
		else version (Posix)
		{
			цел i;

			i = msync(cast(проц*)data, data.length, MS_SYNC);	// sys/mman.h
			if (i != 0)
				errNo();
		}
		else
		{
			static assert(0);
		}
	}

	/**
	 * Gives размер in bytes of the memory mapped file.
	 */
	бдол длина()
	{
		debug (РПФайл) win.скажи("РПФайл.длина()\n");
		return размер;
	}

	/**
	 * Чтение-only property returning the file режим.
	 */
	Режим режим()
	{
		debug (РПФайл) win.скажи("РПФайл.режим()\n");
		return м_режим;
	}

	/**
	 * Returns entire file contents as an array.
	 */
	проц[] opSlice()
	{
		debug (РПФайл) win.скажи("РПФайл.opSlice()\n");
		return opSlice(0,размер);
	}

	/**
	 * Returns срез of file contents as an array.
	 */
	проц[] opSlice(бдол i1, бдол i2)
	{
		debug (РПФайл) скажифнс("РПФайл.opSlice(%lld, %lld)\n", i1, i2);
		ensureMapped(i1,i2);
		т_мера off1 = cast(т_мера)(i1-старт);
		т_мера off2 = cast(т_мера)(i2-старт);
		return data[off1 .. off2];
	}

	/**
	 * Returns byte at index i in file.
	 */
	ббайт opIndex(бдол i)
	{
		debug (РПФайл) скажифнс("РПФайл.opIndex(%lld)\n", i);
		ensureMapped(i);
		т_мера off = cast(т_мера)(i-старт);
		return (cast(ббайт[])data)[off];
	}

	/**
	 * Sets and returns byte at index i in file to значение.
	 */
	ббайт opIndexAssign(ббайт значение, бдол i)
	{
		debug (РПФайл) скажифнс("РПФайл.opIndex(%lld, %d)\n", i, значение);
		ensureMapped(i);
		т_мера off = cast(т_мера)(i-старт);
		return (cast(ббайт[])data)[off] = значение;
	}


	// return да if the given position is currently mapped
	private цел mapped(бдол i) 
	{
		debug (РПФайл) скажифнс("РПФайл.mapped(%lld, %lld, %d)\n", i,старт, 
				data.length);
		return i >= старт && i < старт+data.length;
	}

	// unmap the current range
	private проц unmap() 
	{
		debug (РПФайл) скажифнс("РПФайл.unmap()\n");
		version(Windows) {
			/* Note that under Windows 95, UnmapViewOfFile() seems to return
			* random значues, not да or нет.
			*/
			if (data && ВидФайлаИзКарты(data.ptr) == нет &&
				(винВерсия & 0x80000000) == 0)
				errNo();
		} else {
			if (data && munmap(cast(проц*)data, data.length) != 0)
				errNo();
		}
		data = null;
	}

	// map range
	private проц map(бдол старт, т_мера len) 
	{
		debug (РПФайл) скажифнс("РПФайл.map(%lld, %d)\n", старт, len);
		ук p;
		if (старт+len > размер)
			len = cast(т_мера)(размер-старт);
		version(Windows) {
			бцел hi = cast(бцел)(старт>>32);
			p = ВидФайлаВКартуДоп(hFileMap, dwDesiredAccess, hi, cast(бцел)старт, len, адрес);
			if (!p) errNo();
		} else {
			p = mmap(адрес, len, prot, флаги, fd, cast(цел)старт);
			if (p == MAP_FAILED) errNo();
		}
		data = p[0 .. len];
		this.старт = старт;
	}

	// ensure a given position is mapped
	private проц ensureMapped(бдол i) 
	{
		debug (РПФайл) скажифнс("РПФайл.ensureMapped(%lld)\n", i);
		if (!mapped(i)) {
			unmap();
			if (окно == 0) {
				map(0,cast(т_мера)размер);
			} else {
				бдол block = i/окно;
				if (block == 0)
					map(0,2*окно);
				else 
					map(окно*(block-1),3*окно);
			}
		}
	}

	// ensure a given range is mapped
	private проц ensureMapped(бдол i, бдол j) 
	{
		debug (РПФайл) скажифнс("РПФайл.ensureMapped(%lld, %lld)\n", i, j);
		if (!mapped(i) || !mapped(j-1)) {
			unmap();
			if (окно == 0) {
				map(0,cast(т_мера)размер);
			} else {
				бдол iblock = i/окно;
				бдол jblock = (j-1)/окно;
				if (iblock == 0) {
					map(0,cast(т_мера)(окно*(jblock+2)));
				} else {
					map(окно*(iblock-1),cast(т_мера)(окно*(jblock-iblock+3)));
				}
			}
		}
	}

	private:
	ткст имяф;
	проц[] data;
	бдол  старт;
	т_мера окно;
	бдол  размер;
	Режим   м_режим;
	ук  адрес;

	version (Win32)
	{
		ук hFile = cast(ук)НЕВЕРНХЭНДЛ;
		ук hFileMap = null;
		ППамять dwDesiredAccess;
	}
	else version (Posix)
	{
		цел fd;
		цел prot;
		цел флаги;
		цел fрежим;
	}
	else
	{
		static assert(0);
	}

	// Report error, where errno gives the error number
	проц errNo()
	{
		version (Win32)
		{
			throw new ФайлИскл(имяф, ДайПоследнююОшибку());
		}
		else version (Posix)
		{
			throw new ФайлИскл(имяф, getErrno());
		}
		else
		{
			static assert(0);
		}
	}
}
////////////////////////////

export class СФайл : Поток {
export:

 extern  (C) extern фук файлси;

  this(фук файлси, ПРежимФайла режим, бул сканируем = false) {
	//win.скажинс("акт супер");
     // super();
    this.файлси = файлси;
    читаемый(cast(бул)(режим & ПРежимФайла.Ввод));
    записываемый(cast(бул)(режим & ПРежимФайла.Вывод));
    сканируемый(сканируем);
	//win.скажинс("выход из констр");
  }

  ~this() { закрой(); }

  фук файл() { return файлси; }

  проц файл(фук файлси) {
    this.файлси = файлси; 
    открытый(да);
  }

  override проц слей() { слейфл(файлси); }

  override проц закрой() { 
    if (открыт_ли)
      закройфл(файлси); 
    открытый(нет); читаемый(нет); записываемый(нет); сканируемый(нет); 
  }

 
  override бул кф() { 
    return cast(бул)(читатьдоКФ() || конфл(файлси)); 
  }

  override сим берис() { 
    return cast(сим) берисфл(файлси); 
  }

 
  override сим отдайс(сим c) { 
    return cast(сим) cidrus.отдайс(c,файлси); 
  }

 
  override т_мера читайБлок(ук буфер, т_мера размер) {
    т_мера n = читайфл(адаптВхоУкз(буфер),1,размер,файлси);
    читатьдоКФ(cast(бул)(n == 0));
    return n;
  }

  override т_мера пишиБлок(ук буфер, т_мера размер) {
    return пишифл(адаптВхоУкз(буфер),1,размер,файлси);
  }

 
  override бдол сместись(дол смещение, ППозКурсора rel) {
    читатьдоКФ(нет);
    if (сместисьфл(файлси,cast(цел)смещение,rel) != 0)
      throw new Исключение("Не удаётся переместить файловый указатель",__FILE__, __LINE__);
    return скажифл(файлси);
  }


  override проц пишиСтр(сим[] т) {
    пишиТкст(т);
    пишиТкст("\n");
  }

  override проц пишиСтрШ(шим[] т) {
    пишиТкстШ(т);
    пишиТкстШ("\n");
  }
}

import std.zip;

export extern (D) struct ЧленАрхиваЗИП //ArchiveMember
{
export:
    бкрат версияСборки = 20;	
    бкрат версияИзвлечения = 20;	
    бкрат флаги;		
    бкрат методСжатия;	
    ФВремяДос время;	
    бцел цпи32;			
    бцел сжатыйРазмер;	
    бцел расжатыйРазмер;		
    бкрат номерДиска;		
    бкрат внутренниеАтрибуты;	
    бцел внешниеАтрибуты;	
    private бцел смещение;
    ткст имя;
    ббайт[] экстра;		
    ткст комментарий;		
    ббайт[] сжатыеДанные;	
    ббайт[] расжатыеДанные;	

    проц выведи()
    {
	win.скажи(фм("имя = '%s'\n", имя));
	win.скажи(фм("\tкомментарий = '%s'\n", комментарий));
	win.скажи(фм("\tверсияСборки = %d\n", версияСборки));
	win.скажи(фм("\tверсияИзвлечения = %d\n", версияИзвлечения));
	win.скажи(фм("\tфлаги = %d\n", флаги));
	win.скажи(фм("\tметодСжатия = %d\n", методСжатия));
	win.скажи(фм("\tвремя = %d\n", время));
	win.скажи(фм("\tцпи32 = %d\n", цпи32));
	win.скажи(фм("\tрасжатыйРазмер = %d\n", расжатыйРазмер));
	win.скажи(фм("\tсжатыйРазмер = %d\n", сжатыйРазмер));
	win.скажи(фм("\tвнутренниеАрибуты = %d\n", внутренниеАтрибуты));
	win.скажи(фм("\tвнешниеАтрибуты = %d\n", внешниеАтрибуты));
    }
    
}

export extern (D) class АрхивЗИП
{
export:

 extern  (C) extern
 {
    ббайт[] данные;	
    бцел смещКПоследнЗаписи;

    бцел номерДиска;	
    бцел стартПапкаДиска;	
    бцел члоЗаписей;	
    бцел всегоЗаписей;	
    ткст комментарий; 
   ЧленАрхиваЗИП[ткст] папка; 
}
   
    проц выведи()
    {
	win.скажи(фм("\tномерДиска = %u\n", номерДиска));
	win.скажи(фм("\tстартПапкаДиска = %u\n", стартПапкаДиска));
	win.скажи(фм("\tчлоЗаписей = %u\n", члоЗаписей));
	win.скажи(фм("\tвсегоЗаписей = %u\n", всегоЗаписей));
	win.скажи(фм("\tкомментарий = '%.*т'\n", комментарий));    
    }

     this()
    {
    }

   
    проц добавьЧлен(ЧленАрхиваЗИП de)
    {
	папка[de.имя] = de;
    }
   
    проц удалиЧлен(ЧленАрхиваЗИП de)
    {
	папка.remove(de.имя);
    }

     проц[] строй()
    {	бцел i;
	бцел папкаOffset;

	if (комментарий.length > 0xFFFF)
	    throw new ZipException("комментарий архива длиннее 65535");

	
	бцел размАрхива = 0;
	бцел размПапки = 0;
	foreach (ЧленАрхиваЗИП de; папка)
	{
	    de.расжатыйРазмер = de.расжатыеДанные.length;
	    switch (de.методСжатия)
	    {
		case 0:
		    de.сжатыеДанные = de.расжатыеДанные;
		    break;

		case 8:
		    de.сжатыеДанные = cast(ббайт[])std.zlib.compress(cast(проц[])de.расжатыеДанные);
		    de.сжатыеДанные = de.сжатыеДанные[2 .. de.сжатыеДанные.length - 4];
		    break;

		default:
		    throw new ZipException("неподдерживаемый метод сжатия");
	    }
	    de.сжатыйРазмер = de.сжатыеДанные.length;
	    de.цпи32 = цпи32(0, cast(проц[])de.расжатыеДанные);

	    размАрхива += 30 + de.имя.length +
				de.экстра.length +
				de.сжатыйРазмер;
	    размПапки += 46 + de.имя.length +
				de.экстра.length +
				de.комментарий.length;
	}

	данные = new ббайт[размАрхива + размПапки + 22 + комментарий.length];

	

	
	i = 0;
	foreach (ЧленАрхиваЗИП de; папка)
	{
	    de.смещение = i;
	    данные[i .. i + 4] = cast(ббайт[])"PK\x03\x04";
	    putUshort(i + 4,  de.версияИзвлечения);
	    putUshort(i + 6,  de.флаги);
	    putUshort(i + 8,  de.методСжатия);
	    putUint  (i + 10, cast(бцел)de.время);
	    putUint  (i + 14, de.цпи32);
	    putUint  (i + 18, de.сжатыйРазмер);
	    putUint  (i + 22, de.расжатыеДанные.length);
	    putUshort(i + 26, cast(бкрат)de.имя.length);
	    putUshort(i + 28, cast(бкрат)de.экстра.length);
	    i += 30;

	    данные[i .. i + de.имя.length] = cast(ббайт[])de.имя[];
	    i += de.имя.length;
	    данные[i .. i + de.экстра.length] = cast(ббайт[])de.экстра[];
	    i += de.экстра.length;
	    данные[i .. i + de.сжатыйРазмер] = de.сжатыеДанные[];
	    i += de.сжатыйРазмер;
	}

	
	папкаOffset = i;
	члоЗаписей = 0;
	foreach (ЧленАрхиваЗИП de; папка)
	{
	    данные[i .. i + 4] = cast(ббайт[])"PK\x01\x02";
	    putUshort(i + 4,  de.версияСборки);
	    putUshort(i + 6,  de.версияИзвлечения);
	    putUshort(i + 8,  de.флаги);
	    putUshort(i + 10, de.методСжатия);
	    putUint  (i + 12, cast(бцел)de.время);
	    putUint  (i + 16, de.цпи32);
	    putUint  (i + 20, de.сжатыйРазмер);
	    putUint  (i + 24, de.расжатыйРазмер);
	    putUshort(i + 28, cast(бкрат)de.имя.length);
	    putUshort(i + 30, cast(бкрат)de.экстра.length);
	    putUshort(i + 32, cast(бкрат)de.комментарий.length);
	    putUshort(i + 34, de.номерДиска);
	    putUshort(i + 36, de.внутренниеАтрибуты);
	    putUint  (i + 38, de.внешниеАтрибуты);
	    putUint  (i + 42, de.смещение);
	    i += 46;

	    данные[i .. i + de.имя.length] = cast(ббайт[])de.имя[];
	    i += de.имя.length;
	    данные[i .. i + de.экстра.length] = cast(ббайт[])de.экстра[];
	    i += de.экстра.length;
	    данные[i .. i + de.комментарий.length] = cast(ббайт[])de.комментарий[];
	    i += de.комментарий.length;
	    члоЗаписей++;
	}
	всегоЗаписей = члоЗаписей;

	
	смещКПоследнЗаписи = i;
	данные[i .. i + 4] = cast(ббайт[])"PK\x05\x06";
	putUshort(i + 4,  cast(бкрат)номерДиска);
	putUshort(i + 6,  cast(бкрат)стартПапкаДиска);
	putUshort(i + 8,  cast(бкрат)члоЗаписей);
	putUshort(i + 10, cast(бкрат)всегоЗаписей);
	putUint  (i + 12, размПапки);
	putUint  (i + 16, папкаOffset);
	putUshort(i + 20, cast(бкрат)комментарий.length);
	i += 22;

	
	assert(i + комментарий.length == данные.length);
	данные[i .. данные.length] = cast(ббайт[])комментарий[];

	return cast(проц[])данные;
    }


    this(проц[] буфер)
    {	цел iend;
	цел i;
	цел endкомментарийlength;
	бцел размПапки;
	бцел папкаOffset;

	this.данные = cast(ббайт[]) буфер;

	
	iend = данные.length - 66000;
	if (iend < 0)
	    iend = 0;
	for (i = данные.length - 22; 1; i--)
	{
	    if (i < iend)
		throw new ZipException("нет записи о конце");

	    if (данные[i .. i + 4] == cast(ббайт[])"PK\x05\x06")
	    {
		endкомментарийlength = getUshort(i + 20);
		if (i + 22 + endкомментарийlength > данные.length)
		    continue;
		комментарий = cast(ткст)(данные[i + 22 .. i + 22 + endкомментарийlength]);
		смещКПоследнЗаписи = i;
		break;
	    }
	}

	
	номерДиска = getUshort(i + 4);
	стартПапкаДиска = getUshort(i + 6);

	члоЗаписей = getUshort(i + 8);
	всегоЗаписей = getUshort(i + 10);

	if (члоЗаписей != всегоЗаписей)
	    throw new ZipException("зип на несколько дисков не поддерживается");

	размПапки = getUint(i + 12);
	папкаOffset = getUint(i + 16);

	if (папкаOffset + размПапки > i)
	    throw new ZipException("повреждённая папка");

	i = папкаOffset;
	for (цел n = 0; n < члоЗаписей; n++)
	{
	    
	    бцел смещение;
	    бцел длинаим;
	    бцел экстрадлин;
	    бцел комментарийlen;

	    if (данные[i .. i + 4] != cast(ббайт[])"PK\x01\x02")
		throw new ZipException("неверная запись папки 1");
	    ЧленАрхиваЗИП de;
	    de.версияСборки = getUshort(i + 4);
	    de.версияИзвлечения = getUshort(i + 6);
	    de.флаги = getUshort(i + 8);
	    de.методСжатия = getUshort(i + 10);
	    de.время = cast(ФВремяДос)getUint(i + 12);
	    de.цпи32 = getUint(i + 16);
	    de.сжатыйРазмер = getUint(i + 20);
	    de.расжатыйРазмер = getUint(i + 24);
	    длинаим = getUshort(i + 28);
	    экстрадлин = getUshort(i + 30);
	    комментарийlen = getUshort(i + 32);
	    de.номерДиска = getUshort(i + 34);
	    de.внутренниеАтрибуты = getUshort(i + 36);
	    de.внешниеАтрибуты = getUint(i + 38);
	    de.смещение = getUint(i + 42);
	    i += 46;

	    if (i + длинаим + экстрадлин + комментарийlen > папкаOffset + размПапки)
		throw new ZipException("неверная запись папки 2");

	    de.имя = cast(ткст)(данные[i .. i + длинаим]);
	    i += длинаим;
	    de.экстра = данные[i .. i + экстрадлин];
	    i += экстрадлин;
	    de.комментарий = cast(ткст)(данные[i .. i + комментарийlen]);
	    i += комментарийlen;

	    папка[de.имя] = de;
	}
	if (i != папкаOffset + размПапки)
	    throw new ZipException("неверная запись папки 3");
    }

   
    ббайт[]расжать(ЧленАрхиваЗИП de)
    {	бцел длинаим;
	бцел экстрадлин;

	if (данные[de.смещение .. de.смещение + 4] != cast(ббайт[])"PK\x03\x04")
	    throw new ZipException("неверная запись папки 4");

	
	de.версияИзвлечения = getUshort(de.смещение + 4);
	de.флаги = getUshort(de.смещение + 6);
	de.методСжатия = getUshort(de.смещение + 8);
	de.время = cast(ФВремяДос)getUint(de.смещение + 10);
	de.цпи32 = getUint(de.смещение + 14);
	de.сжатыйРазмер = getUint(de.смещение + 18);
	de.расжатыйРазмер = getUint(de.смещение + 22);
	длинаим = getUshort(de.смещение + 26);
	экстрадлин = getUshort(de.смещение + 28);

	    win.скажи(фм("\t\tрасжатыйРазмер = %d\n", de.расжатыйРазмер));
	    win.скажи(фм("\t\tсжатыйРазмер = %d\n", de.сжатыйРазмер));
	    win.скажи(фм("\t\tдлинаим = %d\n", длинаим));
	    win.скажи(фм("\t\tэкстрадлин = %d\n", экстрадлин));
	
	if (de.флаги & 1)
	    throw new ZipException("кодирование не поддерживается");

	цел i;
	i = de.смещение + 30 + длинаим + экстрадлин;
	if (i + de.сжатыйРазмер > смещКПоследнЗаписи)
	    throw new ZipException("неверная запись папки 5");

	de.сжатыеДанные = данные[i .. i + de.сжатыйРазмер];
	debug(print) arrayPrint(de.сжатыеДанные);

	switch (de.методСжатия)
		{
			case 0:
			de.расжатыеДанные = de.сжатыеДанные;
			return de.расжатыеДанные;

			case 8:
			
			
			
			de.расжатыеДанные = cast(ббайт[])std.zlib.uncompress(cast(проц[])de.сжатыеДанные, de.расжатыйРазмер, -15);
			return de.расжатыеДанные;

			default:
			throw new ZipException("неподдерживаемый метод сжатия");
		}
    }    

    бкрат getUshort(цел i)
    {
	version (LittleEndian)
	{
	    return *cast(бкрат *)&данные[i];
	}
	else
	{
	    ббайт b0 = данные[i];
	    ббайт b1 = данные[i + 1];
	    return (b1 << 8) | b0;
	}
    }

    бцел getUint(цел i)
    {
	version (LittleEndian)
	{
	    return *cast(бцел *)&данные[i];
	}
	else
	{
	    return bswap(*cast(бцел *)&данные[i]);
	}
    }

    проц putUshort(цел i, бкрат us)
    {
	version (LittleEndian)
	{
	    *cast(бкрат *)&данные[i] = us;
	}
	else
	{
	    данные[i] = cast(ббайт)us;
	    данные[i + 1] = cast(ббайт)(us >> 8);
	}
    }

    проц putUint(цел i, бцел ui)
    {
	version (BigEndian)
	{
	    ui = bswap(ui);
	}
	*cast(бцел *)&данные[i] = ui;
    }
}

struct MCI_OPEN_PARMSA {
	бцел dwCallback;
	бцел wDeviceID;
	сим* lpstrDeviceType;
	сим* lpstrElementName;
    сим* lpstrAlias;
}
alias MCI_OPEN_PARMSA* PMCI_OPEN_PARMSA, LPMCI_OPEN_PARMSA;

export extern(D) бул откройДисковод(ткст drive)
		{

		  бцел Res; // MciError;
		  MCI_OPEN_PARMSA OpenParm;
		  бцел флаги;
		  ткст S;
		  бцел DeviceID;
		
		  бул результат = нет;
		  S = drive;
		  флаги = 0x2000 | 512;
		  with (OpenParm)
			{			  
				dwCallback = 0;
				lpstrDeviceType = "CDAudio";
				lpstrElementName = cast(ткст0) S;
			}
			  Res = mciSendCommandA(0, 0x803, флаги, cast(бцел) &OpenParm);
			  if (Res<>0)
			  {
				debug win.скажинс("\nДисковод "~drive~" не обнаружен"); результат= нет; return результат;
				}
				else
				{
			  DeviceID = OpenParm.wDeviceID;
			  try{
					Res = mciSendCommandA(DeviceID, 0x80D, 256, cast(бцел)0);
					if (Res == 0)
					 debug инфо("Дисковод "~drive~" открыт");
					результат = да;
					}
			  finally
			  {
				mciSendCommandA(DeviceID, 0x804, флаги, cast(бцел) &OpenParm);
			  }
			  return результат;
			  }
		}
		
export extern(D) бул закройДисковод(ткст drive)
		{

		  бцел Res; // MciError;
		  MCI_OPEN_PARMSA OpenParm;
		  бцел флаги;
		  ткст S;
		  бцел DeviceID;
		
		  бул  результат = нет;
		  S = drive;
		  флаги = 0x2000 | 512;
		  with (OpenParm)
			{			  
				dwCallback = 0;
				lpstrDeviceType = "CDAudio";
				lpstrElementName = cast(ткст0) S;
			}
			  Res = mciSendCommandA(0, 0x803, флаги, cast(бцел) &OpenParm);
			  if (Res<>0)
			  {
				debug win.скажинс("\nДисковод "~drive~" не обнаружен"); результат= нет; return результат;
				}
			   else
			   {			   
			  DeviceID = OpenParm.wDeviceID;
			  try{
					Res = mciSendCommandA(DeviceID, 0x80D, 512, cast(бцел)0);
					if (Res == 0)
					  debug инфо("Дисковод "~drive~" закрыт");
					результат = да;
					}
			  finally
			  {
				mciSendCommandA(DeviceID, 0x804, флаги, cast(бцел) &OpenParm);
			  }
			  return результат;
			}
		}
		
		
//Загрузчик от Derelict'а	........................................	

char* toCString(char[] str)
{
    return std.string.toStringz(str);
}

char[] toDString(char* cstr)
{
        return std.string.toString(cstr);    
}

int findStr(char[] str, char[] match)
{
        return std.string.find(str, match);    
}

char[][] splitStr(char[] str, char[] delim)
{
    return std.string.split(str, delim);
}

char[] stripWhiteSpace(char[] str)
{    
        return std.string.strip(str);    
}


class ИсключениеЗагрузкиБиблиотеки
{

    ткст м_назвСовмБиб;
	
  static проц выведи(in ткст[] назвыБиб, in ткст[] причины)
    {
        ткст сооб = "Не удалось загрузить одну (или более) ДЛЛ:";
        foreach(i, n; назвыБиб)
        {
            сооб ~= "\n\t" ~ n ~ " - ";
            if(i < причины.length)
                сооб ~= причины[i];
            else
                сооб ~= "Неизвестно";
        }
        throw new Исключение(сооб);
    }

    this(ткст сооб)
    {
	м_назвСовмБиб = "";
        throw new Исключение(сооб,__FILE__, __LINE__);
        
    }

    this(ткст сооб, ткст назвСовмБиб)
    {
	м_назвСовмБиб = назвСовмБиб;
        throw new Исключение(сооб,__FILE__, __LINE__);
        
    }

    ткст имяБиб()
    {
        return м_назвСовмБиб;
    }


}

class ИсключениеНеверногоУкНаБиб
{
public:

    this(ткст назвСовмБиб)
    {
        throw new Исключение("Попытка применить указатель на незагруженную ДЛЛ " ~ назвСовмБиб,__FILE__, __LINE__);
        м_назвСовмБиб = назвСовмБиб;
    }

    ткст имяБиб()
    {
        return м_назвСовмБиб;
    }

private:
    ткст м_назвСовмБиб;
}

export ткст дайТкстОшибки()
    {
        // adapted from Tango

        бцел ошкод = ДайПоследнююОшибку();

        ткст буфСооб;
        бцел i = ФорматируйСообА(
            ПФорматСооб.РазмБуф | ПФорматСооб.ИзСист | ПФорматСооб.ИгнорВставки,
            null,
            ошкод,
            СДЕЛАЙИДЪЯЗ(ПЯзык.НЕЙТРАЛЬНЫЙ, ППодъяз.ДЕФОЛТ),
            буфСооб,
            0,
            null);

        ткст text = буфСооб;
        ОсвободиЛок(cast(лук) буфСооб);

        if(i >= 2)
            i -= 2;
        return text[0 .. i];
    }
	
export extern(D) class Биб
{
private{
    ук _укз;
    ткст _имя;
	}
export:
    ткст имя()
    {
        return _имя;
    }

  this(ук укз, ткст имя)
    {
        _укз = адаптВхоУкз(укз);
        _имя = имя;
    }
}

export extern(D) Биб загрузиБиб(ткст имяб)
in
{
    assert(имяб !is null);
}
body
{
    ук хэндл = ЗагрузиБиблиотекуА(имяб);
    if(хэндл is null)
        throw new Исключение("Не удалось загрузить библиотеку " ~ имяб ~ ": " ~ дайТкстОшибки(),__FILE__, __LINE__);
    return new Биб(хэндл, имяб);
}

export extern(D) Биб загрузиБиб(ткст[] именаб)
in
{
   try	{
   assert(именаб !is null);
   }
   catch(Исключение пи){инфо("Не заданы имена для загрузки в функции загрузиБиб"); выход(0);}
}
body
{
    char[][] незагрБибы;
    char[][] причины;

    foreach(ткст имяб; именаб)
    {
        ук хэндл = ЗагрузиБиблиотекуА(имяб);
        if(хэндл !is null)
        {
            return new Биб(хэндл, имяб);
        }
        else
        {
            незагрБибы ~= имяб;
            причины ~= дайТкстОшибки();
        }

    }
    ИсключениеЗагрузкиБиблиотеки.выведи(незагрБибы, причины);
    return null; // to shut the compiler up
}

export extern(D) проц выгрузиБиб(Биб биб)
{
    if(биб !is null && биб._укз !is null)
        ОсвободиБиблиотеку(биб._укз);
        биб._укз = null;
}

export extern(D) ук дайПроцИзБиб(Биб биб, ткст имяПроц)
in
{
    assert(биб !is null);
    assert(имяПроц !is null);
}
body
{
    if(биб._укз is null)
        new ИсключениеНеверногоУкНаБиб(биб._имя);
		ук proc = ДайАдресПроц(биб._укз, имяПроц);
        if(null is proc)
            ОбработайНедостачуПроц(биб._имя, имяПроц);

        return proc;
}

alias бул function(ткст имяБиб, ткст имяПроц) ОбрвызНедостСимвола;
alias ОбрвызНедостСимвола ОбрвызНедостПроц;

private ОбрвызНедостСимвола обрвызНедостПроц;

проц ОбработайНедостачуПроц(ткст имяБиб, ткст имяСимвола)
{
    бул результат = нет;
    if(обрвызНедостПроц !is null)
        результат = обрвызНедостПроц(имяБиб, имяСимвола);
    if(!результат)
        new ИсключениеЗагрузкиБиблиотеки(имяБиб, имяСимвола);
}

export extern(D) struct ЖанБибгр {
export:

   проц заряжай(ткст винБибы, проц function(Биб) пользовательскийЗагр, ткст текстВерсии = "") {
        assert (пользовательскийЗагр !is null);
        this.винБибы = винБибы;
        this.пользовательскийЗагр = пользовательскийЗагр;
        this.текстВерсии = текстВерсии;
    }

    проц загружай(ткст текстНазвБиб = null)
    {
        if (мояБиб !is null) return;        
        зарегестрированныеЗагрузчики ~= this;
        if (текстНазвБиб is null) текстНазвБиб = винБибы;

            if(текстНазвБиб is null || текстНазвБиб == "")
            {
                throw new Исключение("stdrus.ЖанБибгр.загружай: Название несуществующей библиотеки!");
            }
        
        ткст[] назвыБиб = текстНазвБиб.splitStr(",");
        foreach (б; назвыБиб)
			{
				б = б.stripWhiteSpace();
			}

        загружай(назвыБиб);
    }

    проц загружай(ткст[] назвыБиб)
    {
        мояБиб = загрузиБиб(назвыБиб);

        if(пользовательскийЗагр is null)
        {
            // this should never, ever, happen
            throw new Исключение("stdrus.ЖанБибгр.загружай: Кошмар! Внутренняя функция загрузки сконфигурирована с ошибками...",__FILE__, __LINE__);
        }
		
        пользовательскийЗагр(мояБиб);
		
    }

    ткст строкаВерсии()
    {
        return текстВерсии;
    }

    проц выгружай()
    {
        if (мояБиб !is null) {
            выгрузиБиб(мояБиб);
            мояБиб = null;
        }
    }

    бул загружено()
    {
        return (мояБиб !is null);
    }

    ткст имяБиб()
    {
        return загружено ? мояБиб.имя : null;
    }

    static ~this()
    {
        foreach (x; зарегестрированныеЗагрузчики) {
            x.выгружай();
        }
    }

    private {
        static ЖанБибгр*[] зарегестрированныеЗагрузчики;

        Биб мояБиб;
        ткст винБибы;
        ткст текстВерсии = "";

        проц function(Биб) пользовательскийЗагр;
    }
}

export extern(D) struct ЗавЖанБибгр {
export:

    проц заряжай(ЖанБибгр* dependence,  проц function(Биб) пользовательскийЗагр) {
        assert (dependence !is null);
        assert (пользовательскийЗагр !is null);

        this.dependence = dependence;
        this.пользовательскийЗагр = пользовательскийЗагр;
    }

    проц загружай()
    {
        assert (dependence.загружено);
        пользовательскийЗагр(dependence.мояБиб);
    }

    ткст строкаВерсии()
    {
        return dependence.строкаВерсии;
    }

    проц выгружай()
    {
    }

    бул загружено()
    {
        return dependence.загружено;
    }

    ткст имяБиб()
    {
        return dependence.имяБиб;
    }

    private {
        ЖанБибгр*              dependence;
        проц function(Биб)    пользовательскийЗагр;
    }
}

struct Вяз(T) {
    проц opCall(ткст n, Биб lib) {
        *fptr = дайПроцИзБиб(lib, n);
    }
        ук* fptr;  
}


template вяжи(T) {
    Вяз!(T) вяжи(inout T a) {
        Вяз!(T) рез;
        рез.fptr = cast(ук*)&a;
        return рез;
    }
}

export extern(D) бул создайБибИзДлл(ткст имяБ, ткст имяД = null, ткст путь = null, ткст расшД = "dll")
{

if(имяД == null) имяД = имяБ;
сис(фм("implib/system %s.lib %s%s.%s", имяБ, путь, имяД, расшД));
return да;
}

export extern(D) бул создайЛистинг(ткст имяБ)
{
сис(фм("d:\\dinrus\\bin\\lib -l %s.lib", имяБ));
if(естьФайл(имяБ~".lst"))удалиФайл(имяБ~".lib");
	else throw new Исключение("Неудачная генерация листинга",имяБ, __LINE__);
return  да;
}

export extern(D) цел генМакетИмпорта(ткст имяМ, ткст[] список)
{
	СИСТВРЕМЯ систВремя;
	цел счёт = 1;
	
	ДайМестнВремя(&систВремя);
	ткст дата = вТкст(систВремя.день)~"."~вТкст(систВремя.месяц)~"."~вТкст(систВремя.год);
	ткст время = вТкст(систВремя.час)~" ч. "~вТкст(систВремя.минута)~" мин.";

	ткст заг = фм("
	/*******************************************************************************
	*  Файл генерирован автоматически с помощью либпроцессора Динрус               *
	*  Дата:%s                                           Время: %s\n
	*******************************************************************************/

", дата, время);

	ткст имп = фм("
	module lib.%s;

	import stdrus;

	проц грузи(Биб биб)
	{

	", имяМ);

	ткст связка(ткст[] список)
	{
	ткст вяз;

		foreach(выр; список)
			{
			auto рез = убери(выр);
			вяз ~= фм("
		//вяжи(функция_%s)(%s биб);\r\n", счёт, рез);
			счёт++;
			}
		return вяз;
	}	

	ткст вяз = связка(список);

	ткст имя = stdrus.взаг(имяМ);	

	ткст закр ="
	}\r\n\r\n";

		
	ткст жб = фм("ЖанБибгр %s;\r\n", имя);

	ткст гр = фм("
		static this()
		{
			%s.заряжай(\"%s.dll\", &грузи );
		}\r\n",имя, имяМ);
		
	ткст гн = "
	extern(C)
	{\r\n\r\n";

	ткст функ()
	{
	ткст ф;
		for(цел ц = 1; ц < счёт; ц++ )
		{
		  ф ~= фм("
		//проц function() функция_%s; \r\n", ц);
		}
		return  ф;
	}
		
	ткст ф = функ();

	ткст итог = заг~имп~вяз~закр~жб~гр~гн~ф~закр;

	пишиФайл(имяМ~".d", итог);
	инфо(фм("Сгенерирован макет импорта динамической библиотеки %s,
			результирующий текст которого был записан в файл %s",stdrus.взаг(имяМ), имяМ~".d"));
	return 0;	
}

ткст удалитьДубликатыИзТМас(ткст текст)
{
    ткст строка_итог;
    ткст[] список;
	список = разбейнастр(текст);	
	цел и;
	int[ткст] предшстр;
	ткст следщстр = "";
	цел проходка = 0;
	цел взято = -1;
	бул взят = нет;
	
	for( ; и < список.length ; )
	{
	//if(auto т = _сравни(строка, предшстр) == 0) delete список[и]; предшстр = "";
		  
		foreach(строка; список)
		{		
			while(проходка == 0){ goto старт;}
				
			
		if(строка in предшстр) {delete строка; //_скажинс("удалена предшествующая"); 
		}	
		
		старт:	
			
			if(строка == следщстр || строка != пусто)
			{		
				while(!взят)
				{
				if(строка  in предшстр)
							{
								//_скажинс("А я  тоже грю, конца не будет! ");								
							    следщстр = пусто;
								взят = да;
								break;
							}
				//if(строка in предшстр){ _скажинс("бряк!"); break;}
					if(auto т = сравни(строка, список[и]) == 0  )
					{								
					//_скажинс(фм("да: %s = %s ; и она будет взята из списка в результат\n", строка, список[и])) ;
					строка_итог ~= строка~"\r\n"; 
					взято++;					
					предшстр[строка] = взято;								 
											
				    	foreach(стр; список)
						{
								
							if(!(стр  in предшстр))
							{
									//_скажинс("Я нужен! А он? ");
									
									следщстр = стр;
									взят = да;
									break;
							}
						}
					//_скажинс("Бастилия взята!");
					взят = да;
					
					}
				}
				
			}
			взят = нет;
			if(!(строка in предшстр) && строка != следщстр && строка != пусто)
			{
			следщстр = строка;
			//_скажинс("Я нужен!");
			}
			else {
			     foreach(стрк; список)
						{
							if(стрк  in предшстр)
								//_скажинс("Типа конец, что ли? ");								
							    следщстр = пусто;
								взят = да;
								break;
                        }
					}
			проходка++;
			и++;
			//_скажинс(фм("проходка %s\n, следщстр = %s", проходка, следщстр)) ;
		}
	 
	}
return строка_итог;
}

ткст[] обработатьЛистинг(ткст имяЛ)
{
 ткст буф = cast(ткст) читайФайл(имяЛ~".lst");
  win.скажинс(буф);
  ткст[] список = разбейнастр(буф);
  ткст строка_итог;
 
    
  foreach(строка; список)
	{
	auto рез = убери(строка);		
	if(рез == "Publics by name		module"||рез == "Publics by module"||рез == "") {рез = пусто;}
	if(рез != пусто) строка_итог ~= рез~"\n";	
		
	}		
		
	список = пусто;
	список = разбей(строка_итог);
	строка_итог = пусто;
		
	foreach(строка; список)
	{
	auto рез = убери(строка);		
	if(рез != пусто) строка_итог ~= "\""~рез~"\",\r\n"; 
	
	}		
	auto итог = удалитьДубликатыИзТМас(строка_итог);	
	 удалиФайл(имяЛ~".lst");
	список = пусто;
	список = разбей(итог);
 return список;
}

export extern(D) проц обработай(ткст имяБ,ткст расшД = "dll", ткст путь = пусто, ткст имяД = пусто )
{
ткст[] список;
if(естьФайл(имяБ~".d")) удалиФайл(имяБ~".d");
if(создайБибИзДлл(имяБ, имяД, путь,расшД))
{
   if(естьФайл(имяБ~".lib"))создайЛистинг(имяБ);
   else exception.ошибка("Листинг файла не найден");
   
     if(естьФайл(имяБ~".lst"))список = обработатьЛистинг(имяБ);
	 else exception.ошибка("Листинг файла не обработан");	
 }
 else exception.ошибка("Не удалось создать библиотеку импорта");
if(список != пусто) генМакетИмпорта(имяБ, список); 
//_удалиФайл(имяБ~".lst"); 
}	
///////////////////////////////////////////////////////
scope class PerformanceCounterScope(T)
{
    public:
	this(T счётчик)
	in
	{
	    assert(null !is счётчик);
	}
	body
	{
	    м_счётчик = счётчик;

	    м_счётчик.старт();
	}
	~this()	{	    м_счётчик.стоп();	}
	проц стоп()	{ м_счётчик.стоп();}
	T счётчик()	{	    return м_счётчик;	}
    private:
	T   м_счётчик;

    private:
	this(PerformanceCounterScope rhs);
}


 export extern (D) class СчётчикВысокойПроизводительности
 {
  
    private:
	alias   дол    epoch_type;
    public:

	alias   дол    т_интервал;
	alias PerformanceCounterScope!(СчётчикВысокойПроизводительности)  scope_type;

    export:
	static this()
	{
	    if(!ОпросиЧастотуПроизводительности(&sm_freq))
	    {
		sm_freq = 0x7fffffffffffffffL;
	    }
	}
    
	проц старт()	{	    ОпросиСчётчикПроизводительности(&m_start);	}
	проц стоп()	{	    ОпросиСчётчикПроизводительности(&m_end);	}
   
	т_интервал счётПериодов(){ return m_end - m_start;	}

	т_интервал секунды()	{	    return счётПериодов() / sm_freq;	}

	т_интервал миллисекунды()
	{
	    т_интервал   результат;
	    т_интервал   count   =   счётПериодов();

	    if(count < 0x20C49BA5E353F7L)
	    {
		результат = (count * 1000) / sm_freq;
	    }
	    else
	    {
		результат = (count / sm_freq) * 1000;
	    }

	    return результат;
	}

	т_интервал микросекунды()
	{
	    т_интервал   результат;
	    т_интервал   count   =   счётПериодов();

	    if(count < 0x8637BD05AF6L)
	    {
		результат = (count * 1000000) / sm_freq;
	    }
	    else
	    {
		результат = (count / sm_freq) * 1000000;
	    }

	    return результат;
	}
 
    private:
	epoch_type              m_start;    // старт of measurement период
	epoch_type              m_end;      // End of measurement период
	static т_интервал    sm_freq;    // Frequency

 }
 
 export extern (D) class СчётчикТиков
    {
  
    private:
	alias   дол    epoch_type;
    export:

	alias   дол    т_интервал;

	alias PerformanceCounterScope!(СчётчикТиков) scope_type;
    export:

    export:

	проц старт()	{	    m_start = win.ДайСчётТиков();	}
	проц стоп()	{	    m_end = win.ДайСчётТиков();	}
  
    export:

	т_интервал счётПериодов()	{	    return m_end - m_start;	}

	т_интервал секунды()	{	    return счётПериодов() / 1000;	}

	т_интервал миллисекунды()	{	    return счётПериодов();	}

	т_интервал микросекунды()	{	    return счётПериодов() * 1000;	}

    private:
	бцел    m_start;    // старт of measurement период
	бцел    m_end;      // End of measurement период
    /// @}
    }

export extern (D) class СчётчикВремениНити
    {
   
    private:
	alias   дол    epoch_type;
    export:
	
	alias   дол    т_интервал;
	alias PerformanceCounterScope!(СчётчикВремениНити)  scope_type;
  
    export:

	this(){	    m_thread = ДайТекущуюНить();	}

   
	проц старт()
	{
	    ФВРЕМЯ    creationTime;
	    ФВРЕМЯ    exitTime;

	    ДайВременаНити(m_thread, &creationTime, &exitTime, cast(ФВРЕМЯ*)&m_kernelStart, cast(ФВРЕМЯ*)&m_userStart);
	}

	проц стоп()
	{
	    ФВРЕМЯ    creationTime;
	    ФВРЕМЯ    exitTime;

	    ДайВременаНити(m_thread, &creationTime, &exitTime, cast(ФВРЕМЯ*)&m_kernelEnd, cast(ФВРЕМЯ*)&m_userEnd);
	}
  
    export:

	т_интервал счётПериодаЯдра()	{	    return m_kernelEnd - m_kernelStart;	}

	т_интервал секундыЯдра()	{	    return счётПериодаЯдра() / 10000000;	}

	т_интервал миллисекундыЯдра()	{	    return счётПериодаЯдра() / 10000;	}
	
	т_интервал микросекундыЯдра()	{	    return счётПериодаЯдра() / 10;	}

	т_интервал счётПользовательскогоПериода()	{	    return m_userEnd - m_userStart;	}

	т_интервал секундыПользователя()	{	    return счётПользовательскогоПериода() / 10000000;	}

	т_интервал миллисекундыПользователя()	{	    return счётПользовательскогоПериода() / 10000;	}

	т_интервал микросекундыПользователя()	{	    return счётПользовательскогоПериода() / 10;	}
	
	т_интервал счётПериодов()	{	    return счётПериодаЯдра() + счётПользовательскогоПериода();	}

	т_интервал секунды()	{	    return счётПериодов() / 10000000;	}

	т_интервал миллисекунды()	{	    return счётПериодов() / 10000;	}

	т_интервал микросекунды()	{	    return счётПериодов() / 10;	}

    private:
	epoch_type  m_kernelStart;
	epoch_type  m_kernelEnd;
	epoch_type  m_userStart;
	epoch_type  m_userEnd;
	ук      m_thread;
   
    }
	
	
export extern (D) class СчётчикВремениПроцесса
    {
    private:
	alias   дол    epoch_type;
    export:
	alias   дол    т_интервал;
	alias PerformanceCounterScope!(СчётчикВремениПроцесса) scope_type;
   
	static this()
	{
	    sm_process = ДайТекущийПроцесс();
	}

    export:

	проц старт()
	{
	    ФВРЕМЯ    creationTime;
	    ФВРЕМЯ    exitTime;

	    ДайВременаПроцесса(sm_process, &creationTime, &exitTime, cast(ФВРЕМЯ*)&m_kernelStart, cast(ФВРЕМЯ*)&m_userStart);
	}

	проц стоп()
	{
	    ФВРЕМЯ    creationTime;
	    ФВРЕМЯ    exitTime;

	    ДайВременаПроцесса(sm_process, &creationTime, &exitTime, cast(ФВРЕМЯ*)&m_kernelEnd, cast(ФВРЕМЯ*)&m_userEnd);
	}
  
    export:

	т_интервал счётПериодаЯдра()	{	    return m_kernelEnd - m_kernelStart;	}
	
	т_интервал секундыЯдра()	{	    return счётПериодаЯдра() / 10000000;	}

	т_интервал миллисекундыЯдра()	{	    return счётПериодаЯдра() / 10000;	}

	т_интервал микросекундыЯдра()	{	    return счётПериодаЯдра() / 10;	}

	т_интервал счётПользовательскогоПериода()	{	    return m_userEnd - m_userStart;	}

	т_интервал секундыПользователя()	{	    return счётПользовательскогоПериода() / 10000000;	}

	т_интервал миллисекундыПользователя()	{	    return счётПользовательскогоПериода() / 10000;	}

	т_интервал микросекундыПользователя()	{	    return счётПользовательскогоПериода() / 10;	}
	
	т_интервал счётПериодов()	{	    return счётПериодаЯдра() + счётПользовательскогоПериода();	}

	т_интервал секунды()	{	    return счётПериодов() / 10000000;	}

	т_интервал миллисекунды()	{	    return счётПериодов() / 10000;	}

	т_интервал микросекунды()	{	    return счётПериодов() / 10;	}

    private:
	epoch_type      m_kernelStart;
	epoch_type      m_kernelEnd;
	epoch_type      m_userStart;
	epoch_type      m_userEnd;
	static ук   sm_process;
    }
	
//////////////////////////////////////////
	


abstract class Адрес
{
	protected адрессок* имя();
	protected цел длинаИм();
	ПСемействоАдресов семействоАдресов();	/// Family of this address.
	ткст вТкст();		/// Human readable ткст representing this address.
}

export extern (D)  class Протокол
{
	
export: 

	ППротокол тип;
	ткст имя;
	ткст[] алиасы;

	проц заполни(win.протзап* прото)
	{
	тип = cast(ППротокол)прото.прот;
		имя = std.string.toString(прото.имя).dup;

		int i;
		for(i = 0;; i++)
		{
			if(!прото.алиасы[i])
				break;
		}

		if(i)
		{
			алиасы = new ткст[i];
			for(i = 0; i != алиасы.length; i++)
			{
			    алиасы[i] =
				std.string.toString(прото.алиасы[i]).dup;
			}
		}
		else
		{
			алиасы = null;
		}
	
	}
	бул дайПротоколПоИмени(ткст имя)
	{
	
	win.протзап* прото;
		прото = cast(протзап*) дайпротпоимени(имя);
		if(!прото)
			return нет;
		заполни(прото);
		return да;
	}
	
	бул дайПротоколПоТипу(ППротокол тип)
	{
	протзап* прото;
		прото =cast(протзап*) дайпротпономеру(тип);
		if(!прото)
			return нет;
		заполни(прото);
		return да;
	}
}

export extern (D)  class Служба
{
export:

	ткст имя;
	ткст[] алиасы;
	бкрат порт;
	ткст имяПротокола;

	проц заполни(служзап* служба)
	{
		имя = std.string.toString(служба.имя).dup;
		порт = с8хбк(cast(бкрат)служба.порт);
		имяПротокола = std.string.toString(служба.прот).dup;

		int i;
		for(i = 0;; i++)
		{
			if(!служба.алиасы[i])
				break;
		}

		if(i)
		{
			алиасы = new ткст[i];
			for(i = 0; i != алиасы.length; i++)
			{
                            алиасы[i] =
                                std.string.toString(служба.алиасы[i]).dup;
			}
		}
		else
		{
			алиасы = null;
		}
	}
	бул дайСлужбуПоИмени(ткст имя, ткст имяПротокола)
	{
	служзап* serv;
		serv =cast(служзап*) дайслужбупоимени(имя, имяПротокола);
		if(!serv)
			return нет;
		заполни(serv);
		return да;
	}
	
	бул дайСлужбуПоИмени(ткст имя)
	{
	служзап* serv;
		serv =cast(служзап*) дайслужбупоимени(имя , null);
		if(!serv)
			return нет;
		заполни(serv);
		return да;
	}
	
	бул дайСлужбуПоПорту(бкрат порт, ткст имяПротокола)
	{
	служзап* serv;
		serv =cast(служзап*) дайслужбупопорту(порт, имяПротокола);
		if(!serv)
			return нет;
		заполни(serv);
		return да;
	}
	бул дайСлужбуПоПорту(бкрат порт)
	{
	служзап* serv;
		serv =cast(служзап*) дайслужбупопорту(порт, null);
		if(!serv)
			return нет;
		заполни(serv);
		return да;
	}
}

export extern (D)  class ИнтернетХост
{
export:

	ткст имя;
	ткст[] алиасы;
	бцел[] списокАдр;

	проц реальнаяХостзап(хостзап* хз)
	{
	if(хз.типадр != cast(int)ПСемействоАдресов.ИНЕТ || хз.длина != 4)
			throw new ХостИскл("Несовпадение семейства адресов", _lasterr());
	}
	
	проц заполни(хостзап* хз)
	{
	int i;
		char* p;

		имя = std.string.toString(хз.имя).dup;

		for(i = 0;; i++)
		{
			p = хз.алиасы[i];
			if(!p)
				break;
		}

		if(i)
		{
			алиасы = new ткст[i];
			for(i = 0; i != алиасы.length; i++)
			{
                            алиасы[i] =
                                std.string.toString(хз.алиасы[i]).dup;
			}
		}
		else
		{
			алиасы = null;
		}

		for(i = 0;; i++)
		{
			p = хз.списадр[i];
			if(!p)
				break;
		}

		if(i)
		{
			списокАдр = new бцел[i];
			for(i = 0; i != списокАдр.length; i++)
			{
				списокАдр[i] = с8хбц(*(cast(бцел*)хз.списадр[i]));
			}
		}
		else
		{
			списокАдр = null;
		}
	}
	
	бул дайХостПоИмени(ткст имя)
	{
	хостзап* he;
                synchronized(this.classinfo) he = cast(хостзап*)дайхостпоимени(имя);
		if(!he)
			return нет;
		 реальнаяХостзап(he);
		заполни(he);
		return да;
	}
	бул дайХостПоАдр(бцел адр)
	{
	бцел x = х8сбц(адр);
		хостзап* he;
                synchronized(this.classinfo) he = cast(хостзап*) дайхостпоадресу(&x, 4, cast(int)ПСемействоАдресов.ИНЕТ);
		if(!he)
			return нет;
		реальнаяХостзап(he);
		заполни(he);
		return да;
	}
	бул дайХостПоАдр(ткст адр)
	{
	бцел x = адр_инет(адр);
		хостзап* he;
                synchronized(this.classinfo) he = cast(хостзап*) дайхостпоадресу(&x, 4, cast(int)ПСемействоАдресов.ИНЕТ);
		if(!he)
			return нет;
		реальнаяХостзап(he);
		заполни(he);
		return да;
	}
}


export extern (D)  class НеизвестныйАдрес: Адрес
{
export:
	адрессок ас;


	override адрессок* имя()
	{
		return &ас;
	}


	override цел длинаИм()
	{
		return ас.sizeof;
	}


	override ПСемействоАдресов семействоАдресов()
	{
		return cast(ПСемействоАдресов) ас.семейство;
	}


	override ткст вТкст()
	{
		return std.string.toString("Неизвестно");
	}
}

export extern (D)  class ИнтернетАдрес: Адрес
{
	export:
	адрессок_ин иас;


	override адрессок* имя()
	{
		return cast(адрессок*)&иас;
	}


	override цел длинаИм()
	{
		return иас.sizeof;
	}


	this()
	{
	}
	
	const бцел АДР_ЛЮБОЙ = ПИнАдр.Любой;	/// Любое адресное число IPv4.
	const бцел АДР_НЕУК = ПИнАдр.Неук;	/// Любое неверное адресное число IPv4.
	const бкрат ПОРТ_ЛЮБОЙ = 0;	/// Любое число порта IPv4.
	
	override ПСемействоАдресов семействоАдресов()
	{
	return cast(ПСемействоАдресов) ПСемействоАдресов.ИНЕТ;
	}
	
	бкрат порт(){return с8хбк(cast(uint16_t) иас.порт);}
	
	бцел адр(){return с8хбц(cast(бцел) иас.адр.с_адр);}
	
	this(ткст адр, бкрат порт)
	{
		бцел uiaddr = разбор(адр);
		if(АДР_НЕУК == uiaddr)
		{
		    ИнтернетХост ih = new ИнтернетХост;
			if(!ih.дайХостПоИмени(адр))
				               throw new СокетИскл(
                                 "Неразборчивый хост '" ~ адр ~ "'");
			uiaddr = ih.списокАдр[0];
		}
		иас.адр.с_адр = х8сбц(cast(бцел) uiaddr);
		иас.порт = х8сбк(cast(uint16_t) порт);
	}
	
	this(бцел адр, бкрат порт)
	{
		иас.адр.с_адр = х8сбц(адр);
		иас.порт = х8сбк(порт);
	}

	this(бкрат порт)
	{
		иас.адр.с_адр = 0; //любой, "0.0.0.0"
		иас.порт = х8сбк(порт);
	}
	
	ткст вАдрТкст()
	{
		return инетс8а(cast(адрес_ин) иас.адр).dup;
	}
	
	ткст вПортТкст()
	{
		return std.string.toString(порт());
	}
	
	override ткст вТкст(){return вАдрТкст()~":"~вПортТкст();}
	
	static бцел разбор(ткст адр)
	{
		return с8хбц(адр_инет(адр));
	}
}


export extern (D)  class НаборСокетов
{
private	бцел наибсок; 
private	набор_уд набор;
	
private	бцел счёт(){return  набор.счёт_уд;}
	
	export:

	this(бцел макс)
	{
		наибсок = макс;
		переуст();
	}

	this()
	{
		this(РАЗМНАБ_УД);
	}
	
	проц переуст()
	{
		УД_ОБНУЛИ(cast(набор_уд*) &набор);
	}
	
	проц прибавь(т_сокет с)
	in
	{
		assert(счёт < наибсок);		
	}
	body
	{
		УД_УСТАНОВИ(с, cast(набор_уд*) &набор);
	}
	
	проц прибавь(Сокет с)
	{
		прибавь(с.сок);
	}
	
	проц удали(т_сокет с)
	{
		УД_УДАЛИ(с, cast(набор_уд*) &набор);
		
	}

	проц удали(Сокет с)
	{
		удали(с.сок);
	}

	цел вНаборе(т_сокет с)
	{
		return УД_УСТАНОВЛЕН(с, cast(набор_уд*) &набор);
	}

	цел вНаборе(Сокет с)
	{
		return вНаборе(с.сок);
	}

	бцел макс()
	{
		return наибсок;
	}

	набор_уд* вНабор_уд()
	{
		return cast(набор_уд*) &набор;
	}

	цел выберич()
	{		
			return счёт;		
	}
	
}


private цел _lasterr()
	{
		return ВСАДайПоследнююОшибку();
	}
	
export extern (D)  class Сокет
{
private
{
т_сокет сок;
ПСемействоАдресов _семейство;
бул _блокируемый = нет;
}

export:

this(ПСемействоАдресов са, ПТипСок тип, ППротокол протокол)
	{
		сок = cast(т_сокет)сокет(са, тип, протокол);
		if(сок == т_сокет.init)
			throw new СокетИскл("Не удаётся создать сокет", _lasterr());
		_семейство = са;
	}

this(ПСемействоАдресов са, ПТипСок тип)
	{
		this(са, тип, cast(ППротокол)0); // Pseudo protocol number.
	}
	
this(ПСемействоАдресов са, ПТипСок тип, ткст имяПротокола)
	{
		протзап* прото;
		прото = дайпротпоимени(имяПротокола);
		if(!прото)
			throw new СокетИскл("Не удаётся найти протокол", _lasterr());
		this(са, тип, cast(ППротокол) прото.прот);
	}
	
	~this()
	{
		закрой();
	}
	
protected this(){}
	
т_сокет Ук()
	{
		return сок;
	}
	
бул блокируемый()
	{
		return _блокируемый;		
	}
	
проц блокируемый(бул б)
	{
			бцел num = !б;
			if(-1 == ввктлсок(сок, ВВФСБВВ, &num))
				goto err;
			_блокируемый = б;
		return; // Success.

		err:
		throw new СокетИскл("Не удаётся установить сокет блокируемым", _lasterr());
	}

ПСемействоАдресов семействоАдресов() // getter
	{
		return _семейство;
	}
	
бул жив_ли() // getter
	{
		цел тип, размтипа = тип.sizeof;
		return !дайопцсок(cast(СОКЕТ) сок, ППротокол.СОКЕТ, ПОпцияСокета.Тип, cast(char*)&тип, &размтипа);
	}

проц свяжи(Адрес адр)
	{
		if(-1 == свяжисок(cast(СОКЕТ) сок, cast(адрессок*) адр.имя(), адр.длинаИм()))
			throw new СокетИскл("Не удаётся связать сокет", _lasterr());
	}

проц подключись(Адрес к)
	{
		if(-1 == подключи(cast(СОКЕТ) сок, cast(адрессок*) к.имя(), к.длинаИм()))
		{
			цел err;
			err = _lasterr();

			if(!блокируемый)
			{
				if(ПВинСокОш.Блокировано == err)
						return;
				
			}
			throw new СокетИскл("Не удаётся подключить сокет", err);
		}
	}

проц слушай(цел backlog)
	{
		if(-1 == win.слушай(cast(СОКЕТ) сок, backlog))
			throw new СокетИскл("Не удаётся прослушивание сокета", _lasterr());
	}
	
Сокет принимающий()
	{
		return new Сокет;
	}

Сокет прими()
	{
		т_сокет newsock;
		//newsock = cast(socket_t).accept(sock, null, null); // DMD 0.101 error: found '(' when expecting ';' following 'statement
		alias win.пусти topaccept;
		newsock = cast(т_сокет)topaccept(cast(СОКЕТ) сок, null, null);
		if(т_сокет.init == newsock)
			throw new СокетИскл("Не удаётся принят подключение через сокет", _lasterr());

		Сокет newSocket;
		try
		{
			newSocket = принимающий();
			assert(newSocket.сок == т_сокет.init);

			newSocket.сок = newsock;
			version(Win32)
				newSocket._блокируемый = _блокируемый; //inherits blocking mode
			newSocket._семейство = _семейство; //same семейство
		}
		catch(Объект o)
		{
			_close(newsock);
			throw o;
		}

		return newSocket;
	}

	/// Disables sends and/or receives.
	проц экстрзак(ПЭкстрЗакрытиеСокета how)
	{
		win.экстрзак(cast(СОКЕТ) сок,  how);
	}


	private static проц _close(т_сокет сок)
	{
		закройсок(cast(СОКЕТ) сок);
	}

	проц закрой()
	{
		_close(сок);
		сок = т_сокет.init;
	}


	private Адрес новОбъектСемейства()
	{
		Адрес результат;
		switch(_семейство)
		{
			case cast(ПСемействоАдресов) ПСемействоАдресов.ИНЕТ:
				результат = new stdrus.ИнтернетАдрес;
				break;

			default:
				результат = new stdrus.НеизвестныйАдрес;
		}
		return результат;
	}


static ткст имяХоста() // getter
	{
		char[256] результат; // Host names are limited to 255 chars.
		if(-1 == дайимяхоста(результат, результат.length))
			throw new СокетИскл("Не удаётся получить имя хоста", _lasterr());
		return std.string.toString(cast(char*)результат).dup;
	}

Адрес удалённыйАдрес()
	{
		Адрес адр = новОбъектСемейства();
		цел длинаИм = адр.длинаИм();
		if(-1 == дайимяпира(cast(СОКЕТ)сок, cast(адрессок*) адр.имя(), &длинаИм))
			throw new СокетИскл("Не удаётся получить адрес удалённого сокета", _lasterr());
		assert(адр.семействоАдресов() == _семейство);
		return адр;
	}

Адрес локальныйАдрес()
	{
		Адрес адр = новОбъектСемейства();
		цел длинаИм = адр.длинаИм();
		if(-1 == дайимясок(cast(СОКЕТ) сок, cast(адрессок*) адр.имя(), &длинаИм))
			throw new СокетИскл("Не удаётся получить адрес локального сокета", _lasterr());
		assert(адр.семействоАдресов() == _семейство);
		return адр;
	}

	const цел ОШИБКА = -1;

	цел шли(проц[] буф, ПФлагиСокета флаги)
	{
                флаги |= ПФлагиСокета.БезСигнала;
		цел sent = win.шли(сок, буф.ptr, буф.length, флаги);
		return sent;
	}

	цел шли(проц[] буф)
	{
		return шли(буф, ПФлагиСокета.БезСигнала);
	}

	цел шли_на(проц[] буф, ПФлагиСокета флаги, Адрес to)
	{
                флаги |= ПФлагиСокета.БезСигнала;
		цел sent = win.шли_на(cast(СОКЕТ) сок, буф.ptr, буф.length, флаги,cast(адрессок*) to.имя(), to.длинаИм());
		return sent;
	}

	цел шли_на(проц[] буф, Адрес to)
	{
		return шли_на(буф, ПФлагиСокета.Неук, to);
	}

	цел шли_на(проц[] буф, ПФлагиСокета флаги)
	{
                флаги |= ПФлагиСокета.БезСигнала;
		цел sent = win.шли_на(cast(СОКЕТ) сок, буф.ptr, буф.length, флаги, null, нет);
		return sent;
	}

	цел шли_на(проц[] буф)
	{
		return шли_на(буф, ПФлагиСокета.Неук);
	}

	цел получи(проц[] буф, ПФлагиСокета флаги)
	{
		if(!буф.length) //return 0 and don't think the connection closed
			return 0;
		цел read = win.прими(cast(СОКЕТ) сок, буф.ptr, буф.length, флаги);
		// if(!read) //connection closed
		return read;
	}

	цел получи(проц[] буф)
	{
		return получи(буф, ПФлагиСокета.Неук);
	}

	цел получи_от(проц[] буф, ПФлагиСокета флаги, out Адрес от)
	{
		if(!буф.length) //return 0 and don't think the connection closed
			return 0;
		от = новОбъектСемейства();
		цел длинаИм = от.длинаИм();
		цел read = win.прими_от(cast(СОКЕТ) сок, буф.ptr, буф.length, флаги, cast(адрессок*) от.имя(), &длинаИм);
		assert(от.семействоАдресов() == _семейство);
		// if(!read) //connection closed
		return read;
	}

	цел получи_от(проц[] буф, out Адрес от)
	{
		return получи_от(буф, ПФлагиСокета.Неук, от);
	}

	цел получи_от(проц[] буф, ПФлагиСокета флаги)
	{
		if(!буф.length) //return 0 and don't think the connection closed
			return 0;
		цел read = прими_от(cast(СОКЕТ) сок, буф.ptr, буф.length, флаги, null, null);
		// if(!read) //connection closed
		return read;
	}

цел получи_от(проц[] буф)
	{
		return получи_от(буф, ПФлагиСокета.Неук);
	}

цел дайОпцию(ППротокол уровень, ПОпцияСокета опция, проц[] результат)
	{
		цел len = результат.length;
		if(-1 == дайопцсок(cast(СОКЕТ) сок, уровень, опция, результат.ptr, &len))
			throw new СокетИскл("Не удаётся получить опцию сокета", _lasterr());
		return len;
	}

цел дайОпцию(ППротокол уровень, ПОпцияСокета опция, out цел результат)
	{
		return дайОпцию(уровень, опция, (&результат)[0 .. 1]);
	}

цел дайОпцию(ППротокол уровень, ПОпцияСокета опция, out заминка результат)
	{
		return дайОпцию(уровень, опция, (&результат)[0 .. 1]);
	}

проц установиОпцию(ППротокол уровень, ПОпцияСокета опция, проц[] значение)
	{
		if(-1 == установиопцсок(сок, уровень, опция, значение.ptr, значение.length))
			throw new СокетИскл("Не удаётся  установить опцию сокета", _lasterr());
	}

проц установиОпцию(ППротокол уровень, ПОпцияСокета опция, цел значение)
	{
		установиОпцию(уровень, опция, (&значение)[0 .. 1]);
	}

проц установиОпцию(ППротокол уровень, ПОпцияСокета опция, заминка значение)
	{
	установиОпцию(уровень, опция, (&значение)[0 .. 1]);
	}

static цел выбери(НаборСокетов checkRead, НаборСокетов checkWrite, НаборСокетов checkError, win.значврем* tv)
	in
	{
		//make sure none of the НаборСокетов'т are the same object
		if(checkRead)
		{
			assert(checkRead !is checkWrite);
			assert(checkRead !is checkError);
		}
		if(checkWrite)
		{
			assert(checkWrite !is checkError);
		}
	}
	body
	{
		набор_уд* fr, fw, fe;
		цел n = 0;

		version(Win32)
		{
			// Windows has a problem with empty набор_уд`т that aren't null.
			fr = (checkRead && checkRead.счёт()) ? checkRead.вНабор_уд() : null;
			fw = (checkWrite && checkWrite.счёт()) ? checkWrite.вНабор_уд() : null;
			fe = (checkError && checkError.счёт()) ? checkError.вНабор_уд() : null;
		}
		else
		{
			if(checkRead)
			{
				fr = checkRead.вНабор_уд();
				n = checkRead.выберич();
			}
			else
			{
				fr = null;
			}

			if(checkWrite)
			{
				fw = checkWrite.вНабор_уд();
				цел _n;
				_n = checkWrite.выберич();
				if(_n > n)
					n = _n;
			}
			else
			{
				fw = null;
			}

			if(checkError)
			{
				fe = checkError.вНабор_уд();
				цел _n;
				_n = checkError.выберич();
				if(_n > n)
					n = _n;
			}
			else
			{
				fe = null;
			}
		}

		цел результат = win.выбери(n, cast(набор_уд*) fr, cast(набор_уд*) fw, cast(набор_уд*) fe, cast(win.значврем*)tv);

		version(Win32)
		{
			if(-1 == результат && ВСАДайПоследнююОшибку() == ПВинСокОш.Прервано)
				return -1;
		}
		else version(Posix)
		{
			if(-1 == результат && дайНомош() == EINTR)
				return -1;
		}
		else
		{
			static assert(0);
		}

		if(-1 == результат)
			throw new СокетИскл("Ошибка выбора сокета", _lasterr());

		return результат;
	}

static цел выбери(НаборСокетов checkRead, НаборСокетов checkWrite, НаборСокетов checkError, цел микросекунды)
	{
	    win.значврем tv;
	    tv.секунды = микросекунды / 1_000_000;
	    tv.микросекунды = микросекунды % 1_000_000;
	    return выбери(checkRead, checkWrite, checkError, &tv);
	}

static цел выбери(НаборСокетов checkRead, НаборСокетов checkWrite, НаборСокетов checkError)
	{
		return выбери(checkRead, checkWrite, checkError, null);
	}

}


export extern (D) class ПутСокет: Сокет
{
export:

	this(ПСемействоАдресов семейство)
	{
		super(семейство, ПТипСок.Поток, ППротокол.ПУТ);
	}

	this()
	{
		this(ПСемействоАдресов.ИНЕТ);
	}

	this(Адрес подкл_к)
	{
		this(подкл_к.семействоАдресов());
		подключись(подкл_к);
	}
}

export extern (D) class ПпдСокет: Сокет
{
export:

	this(ПСемействоАдресов семейство)
	{
		super(семейство, ПТипСок.ДГрамма, ППротокол.ППД);
	}

	this()
	{
		this(ПСемействоАдресов.ИНЕТ);
	}
}

export extern (D) class СокетПоток: Поток
{
    private:
	Сокет сок;
	
    export:

	this(Сокет сок, ПРежимФайла режим)
	{
		if(режим & ПРежимФайла.Ввод)
			читаемый(да);
		if(режим & ПРежимФайла.Вывод)
			записываемый(да);
		
		this.сок = сок;
	}
	
	this(Сокет сок)
	{
		записываемый(да); читаемый(да);
		this.сок = сок;
	}
	
	Сокет сокет()
	{
		return сок;
	}
	
	override т_мера читайБлок(ук _буфер, т_мера размер)
	{
	  ббайт* буфер = cast(ббайт*)адаптВхоУкз(_буфер);
	  проверьЧитаемость();
	  
	  if (размер == 0)
	    return размер;
	  
	  auto len = сок.получи(буфер[0 .. размер]);
	  читатьдоКФ(cast(бул)(len == 0));
	  if (len == сок.ОШИБКА)
	    len = 0;
	  return len;
	}
	
		override т_мера пишиБлок(ук _буфер, т_мера размер)
	{
	  ббайт* буфер = cast(ббайт*)адаптВхоУкз(_буфер);
	  проверьЗаписываемость(this.toString());

	  if (размер == 0)
	    return размер;
	  
	  auto len = сок.шли(буфер[0 .. размер]);
	  читатьдоКФ(cast(бул)(len == 0));
	  if (len == сок.ОШИБКА) 
	    len = 0;
	  return len;
	}
	
	override бдол сместись(дол смещение, ППозКурсора куда)
	{
		throw new Исключение("Перемещение по сокету невозможно.");
		//return 0;
	}
	
	override ткст вТкст()
	{
		return сок.вТкст();
	}
	
	override проц закрой()
	{
		сок.закрой();
	}
}

/* ================================ Win32 ================================= */

extern (Windows) alias бцел (*stdfp)(ук);
alias ук thread_hdl;
alias бцел thread_id;
alias ук нук;
alias бцел нид;

extern (C)    thread_hdl _beginthreadex(ук security, бцел stack_size,
	stdfp start_addr, ук arglist, бцел initflag,
	thread_id* thrdaddr);



export extern (D) нук начниНитьДоп(ук безоп, бцел размстека, stdfp стартадр, ук списаргов, бцел иницфлаг, нид* адрнити)
{
return cast(нук) _beginthreadex(безоп, размстека, стартадр, списаргов, иницфлаг, cast(thread_id*) адрнити);
}

private const бцел  ВЫХОД_ИЗ_ОЖИДАНИЯ = 258;



/**
 * Выводится при ошибках.
 */
 

class ОшибкаНити : Исключение
{

    this(ткст т)
    {
	super("Ошибка в классе Нить: " ~ т);
    }
}

/**
 * Для каждой нити создаётся один экземпляр этого класса. 
 */


export  extern (D) class Нить
{
export:
    /**
     * Конструктор, используемый производными от Нить, переписывающий main(). 
     * Необязательный параметр размстека имеет по умолчанию значение 0. С
     * этим значением нить создаётся с размером по умолчанию для исполнимых файлов.
     */
    this(т_мера размстека = 0)
    {	
	this.размстека = размстека;	
	
    }

    /**
     * Конструктор для производных от Нить, переписывающий пуск().
     */
    this(цел (*fp)(ук), ук арг, т_мера размстека = 0)
    {
	this.fp = fp;
	this.арг = арг;
	this.размстека = размстека;
	}

    /**
     * Constructor used by classes derived from Нить that override пуск().
     */
    this(цел delegate() дг, т_мера размстека = 0)
    {
	this.дг = дг;
	this.размстека = размстека;	
    }

    /**
     * Destructor
     *
     * If the thread hasn't been joined yet, detach it.
     */
    ~this()
    {
        if (состояние != СН.ЗАВЕРШЕНА)
            ЗакройДескр(hdl);
    }

    /**
     * The хэндл to this thread assigned by the operating system. This is set
     * to нид.init if the thread hasn't been started yet.
     */
    ук hdl;

    ук низСтэка;

    /**
     * Create a new thread and старт it running. The new thread initializes
     * itself and then calls пуск(). старт() can only be called once.
     */
   проц старт()
    {
	synchronized (Нить.classinfo)
	{
	    if (состояние != СН.НАЧАЛЬНОЕ)
		{
		пуск(); return;
		}//error("уже пущена");

	    for (цел i = 0; 1; i++)
	    {
		if (i == allThreads.length)
		    error("слишком много нитей");
		if (!allThreads[i])
		{   allThreads[i] = this;
		    инд = i;
		    if (i >= allThreadsDim)
			allThreadsDim = i + 1;
		    break;
		}
	    }
	    члонн++;
		

	    состояние = СН.ПУЩЕНА;
	    hdl = начниНитьДоп(null, cast(бцел) размстека, &стартнити, cast(ук) this, 0, &id);
	    if (hdl == cast(ук) 0)
	    {
		allThreads[инд] = null;
		члонн--;
		
		состояние = СН.ЗАВЕРШЕНА;
		инд = -1;
		error("не удался старт");
	    }
	}
    }

    /**
     * Точка входа в нить. Если не переписан, то вызывает
     * указатель на функцию fp и аргумент арг пререданный конструктору, или делегат
     * дг.
     * Возвращает: код выхода нити, обычно 0.
     */
		
    цел пуск()
    {
	if (fp)
	    return fp(арг);
	else if (дг)
	    return дг();
	assert(0);
    }

    /*****************************
     * Wait for this thread to terminate.
     * Simply returns if thread has already terminated.
     * Выводит исключение: $(B ОшибкаНити) if the thread hasn't begun yet or
     * is called on itself.
     */
    проц жди()
    {
	if (сама_ли)
	    error("ожидание самой себя");
	if (состояние != СН.ЗАВЕРШЕНА)
	{   бцел dw;

	    dw = ЖдиОдинОбъект(hdl, 0xFFFFFFFF);
            состояние = СН.ЗАВЕРШЕНА;
            ЗакройДескр(hdl);
            hdl = null;
	}
    }

    /******************************
     * Wait for this thread to terminate or until миллисек time has
     * elapsed, whichever occurs first.
     * Simply returns if thread has already terminated.
     * Выводит исключение: $(B ОшибкаНити) if the thread hasn't begun yet or
     * is called on itself.
     */
    проц жди(бцел миллисек)
    {
	if (сама_ли)
	    error("ожидание самой себя");
	if (состояние != СН.ЗАВЕРШЕНА)
	{   бцел dw;

	    dw = ЖдиОдинОбъект(hdl, миллисек);
	    if (dw != ВЫХОД_ИЗ_ОЖИДАНИЯ)
	    {
		состояние = СН.ЗАВЕРШЕНА;
		ЗакройДескр(hdl);
		hdl = null;
	    }
	}
    }

    /**
     * Состояние нити.
     */
    enum СН
    {
	НАЧАЛЬНОЕ,	/// The thread hasn't been started yet.
	ПУЩЕНА,	/// The thread is running or paused.
	ПРЕРВАНА,	/// The thread has ended.
        ЗАВЕРШЕНА        /// The thread has been cleaned up
    }

    /**
     * Возвращает состояние нити.
     */
    СН дайСостояние()
    {
	return состояние;
    }

    /**
     * Приоритет нити.
     */
    enum ПРИОРИТЕТ
    {
	УВЕЛИЧЬ,	/// Increase thread приоритет
	УМЕНЬШИ,	/// Decrease thread приоритет
	НИЗКИЙ,		/// Assign thread low приоритет
	ВЫСОКИЙ,	/// Assign thread high приоритет
	НОРМАЛЬНЫЙ,
    }

    /**
     * Регулирует приоритет текущей нити.
     * Выводит исключение: ОшибкаНити, если не удаётся установить приоритет
     */
    проц устПриор(ПРИОРИТЕТ p)
    {
	ППриоритетНити nPriority;

	switch (p)
	{
	    case ПРИОРИТЕТ.УВЕЛИЧЬ:
		nPriority = ППриоритетНити.ВышеНормы;
		break;
	    case ПРИОРИТЕТ.УМЕНЬШИ:
		nPriority = ППриоритетНити.ВышеНормы;
		break;
	    case ПРИОРИТЕТ.НИЗКИЙ:
		nPriority = ППриоритетНити.Холостая;
		break;
	    case ПРИОРИТЕТ.ВЫСОКИЙ:
		nPriority = ППриоритетНити.НизРеалВрем;
		break;
	    case ПРИОРИТЕТ.НОРМАЛЬНЫЙ:
		nPriority = ППриоритетНити.Норма;
		break;
	    default:
		assert(0);
	}

	if (УстановиПриоритетНити(hdl, nPriority) == ППриоритетНити.ВозвратОшибок)
	    error("установка приоритета");
    }

    /**
     * Вернёт да, если данная нить является текущей нитью.
     */
    bool сама_ли()
    {
	//эхо("id = %d, этот = %d\n", id, эта_нить());
	return (id == ДайИдТекущейНити());
    }

    /**
     * Возвращает ссылку на Нить, вызвавшую функцию.
     */
    static Нить дайЭту()
    {
	//эхо("дайЭту(), allThreadsDim = %d\n", allThreadsDim);
        бцел id = ДайИдТекущейНити();
        for (цел i = 0; i < allThreadsDim; i++)
        {
            Нить t = allThreads[i];
            if (t && id == t.id)
            {
                return t;
            }
        }
	//win.скажинс("Нить, вызвавшая функцию, не обнаружена");
	assert(0);
    }

    /**
     * Возвращает массив всех выполняемых нитей.
     */
    static Нить[] дайВсе()
    {
	synchronized (Нить.classinfo) return allThreads[0 .. allThreadsDim];
    }

	бцел дайЧлоНитей()
	{
	return члонн;
	}
	
    /**
     * Приостановить выполнение текущей нити.
     */
    проц пауза()
    {
	if (состояние != СН.ПУЩЕНА || ЗаморозьНить(hdl) == 0xFFFFFFFF)
	    error("не удаётся пауза");
    }

    /**
     * Возобновить выполнение текущей нити.
     */
    проц возобнови()
    {
	if (состояние != СН.ПУЩЕНА || РазморозьНить(hdl) == 0xFFFFFFFF)
	    error("не удаётся возобновить");
    }

    /**
     * Приостановить выполнение всех, кроме этой, нитей.
     */
    static проц паузаВсем()
    {
        synchronized (Нить.classinfo)
        {
            if (члонн > 1)
            {
		бцел thisid = ДайИдТекущейНити();

		for (цел i = 0; i < allThreadsDim; i++)
		{
		    Нить t = allThreads[i];
		    if (t && t.id != thisid && t.состояние == СН.ПУЩЕНА)
			t.пауза();
		}
            }
        }
    }

    /**
     * Возобновить все приостановленные нити.
     */
    static проц возобновиВсе()
    {
        synchronized (Нить.classinfo)
        {
            if (члонн > 1)
            {
                бцел thisid = ДайИдТекущейНити();

                for (цел i = 0; i < allThreadsDim; i++)
                {
                    Нить t = allThreads[i];
                    if (t && t.id != thisid && t.состояние == СН.ПУЩЕНА)
                        t.возобнови();
                }
            }
        }
    }

    /**
     * Отбросить остаток отрезка времени данной нити.
     */
    static проц рви()
    {
	Спи(0);
    }

    /**
     *
     */
    static бцел члонн = 0;
	
	
private
{

    static бцел allThreadsDim;
    static Нить[0x400] allThreads;	// длина соответствует значению в рантайме Си

    СН состояние = СН.НАЧАЛЬНОЕ;
    цел инд = -1;			// index into allThreads[]
    бцел id;
    т_мера размстека = 0;

    цел (*fp)(ук);
    ук арг;

    цел delegate() дг;

    проц error(ткст msg)
    {
	throw new ОшибкаНити(msg);
    }


}   
 /* ***********************************************
     * Это просто мост между C rtl и Нить.пуск().
     */

   export extern (Windows) static бцел стартнити(ук p)
    {
	Нить t = cast(Нить) p;
	цел результат;

	debug (thread) скажифнс("Starting thread %d\n", t.инд);
	t.низСтэка = дай_низ_стека();
	try
	{
	    результат = t.пуск();
	}
	catch (Object o)
	{
	    fprintf(cast(фук) cidrus.stderr, "Error: %.*т\n", o.toString());
	    результат = 1;
	}

	debug (thread) скажифнс("Ending thread %d\n", t.инд);
        synchronized (Нить.classinfo)
        {
            allThreads[t.инд] = null;
            члонн--;
			
	    t.состояние = СН.ПРЕРВАНА;
            t.инд = -1;
        }
	return результат;
    }


    /**************************************
     * Создаёт Нить для глобальной функции main().
     */

    public static проц пускНити()
    {
	debug(Нить) win.скажинс("Нить будет запускаться...");
	Нить t = new .Нить();
	win.скажинс ("Создан экземпляр Нити");
	t.состояние = СН.ПУЩЕНА;
	t.id = ДайИдТекущейНити();
	debug(Нить) win.скажинс ("Выполнена команда ДайИдТекущейНити");
	t.hdl = Нить.дайУкНаТекНить();
	debug(Нить) win.скажинс("Получен указатель на текущую нить");
	t.низСтэка = дай_низ_стека();
	debug(Нить) win.скажинс("Произведён опрос низа стека");

	assert(!allThreads[0]);
	allThreads[0] = t;
	allThreadsDim = 1;
	t.инд = 0;
	debug(Нить) win.скажи("Выполнены все необходимые проверки и присвоения");
	}

    static ~this()
    {
	if (allThreadsDim)
	{
	    ЗакройДескр(allThreads[0].hdl);
	    allThreads[0].hdl = ДайТекущуюНить();
	}
    }
          
    /********************************************
     * Returns the хэндл of the current thread.
     * This is needed because ДайТекущуюНить() always returns -2 which
     * is a pseudo-хэндл representing the current thread.
     * The returned thread хэндл is a windows resource and must be explicitly
     * closed.
     * Many thanks to Justin (jhenzie@mastd.c.com) for figuring this out
     * and providing the fix.
     */
    static ук дайУкНаТекНить()
    {
	ук currentThread = ДайТекущуюНить();
	ук actualThreadHandle;

	//ук currentProcess = cast(ук)-1;
	ук currentProcess = ДайТекущийПроцесс(); // http://www.digitalmars.com/drn-bin/wwwnews?D/21217


	бцел access = cast(бцел)0x00000002;

	ДублируйДескр(currentProcess, currentThread, currentProcess,
			 &actualThreadHandle, cast(ППраваДоступа)0, да, access);

	return actualThreadHandle;
     }
}

/**********************************************
 * Determine "bottom" of stack (actually the top on Win32 systems).
 */

 export extern(D) ук дай_низ_стека()
{
    asm
    {
	naked			;
	mov	EAX,FS:4	;
	ret			;
    }
}

////////////////////////////////////
export extern(D):

/** Get an environment variable D-ly */
ткст дайПеремСреды(ткст пер)
{
        сим[10240] буфер;
        буфер[0] = '\0';
        GetEnvironmentVariableA(
                вТкст0(пер),
                буфер.ptr,
                10240);
        return вТкст(буфер.ptr);

}

/** Set an environment variable D-ly */
проц устПеремСреды(ткст пер, ткст знач)
{
        SetEnvironmentVariableA(
            вТкст0(пер),
            вТкст0(знач));

}

/** Get the system PATH */
ткст[] дайПуть()
{
    return разбей(вТкст(getenv("PATH")), РАЗДПСТР);
}

/** From args[0], figure out our путь.  Returns 'нет' on failure */
бул гдеЯ(ткст argvz, inout ткст пап, inout ткст bname)
{
    // split it
    bname = извлекиИмяПути(argvz);
    пап = извлекиПапку(argvz);
    
    // on Windows, this is a .exe
    version (Windows) {
        bname = устДефРасш(bname, "exe");
    }
    
    // is this a directory?
    if (пап != "") {
        if (!абсПуть_ли(пап)) {
            // make it absolute
            пап = дайтекпап() ~ РАЗДПАП ~ пап;
        }
        return да;
    }
    
    version (Windows) {
        // is it in cwd?
        char[] cwd = дайтекпап();
        if (естьФайл(cwd ~ РАЗДПАП ~ bname)) {
            пап = cwd;
            return да;
        }
    }
    
    // rifle through the путь
    char[][] путь = дайПуть();
    foreach (pe; путь) {
        char[] fullname = pe ~ РАЗДПАП ~ bname;
        if (естьФайл(fullname)) {
            version (Windows) {
                пап = pe;
                return да;
            } else {
                if (дайАтрибутыФайла(fullname) & 0100) {
                    пап = pe;
                    return да;
                }
            }
        }
    }
    
    // bad
    return нет;
}

/// Return a canonical pathname
ткст канонПуть(ткст исхПуть)
{
    char[] возвр;
    
    version (Windows) {
        // replace any altsep with sep
        if (АЛЬТРАЗДПАП.length) {
            возвр = замени(исхПуть, АЛЬТРАЗДПАП, "\\\\");
        } else {
            возвр = исхПуть.dup;
        }
    } else {
        возвр = исхПуть.dup;
    }
    
    // expand tildes
    возвр = разверниТильду(возвр);
    
    // get rid of any duplicate separators
    for (int i = 0; i < возвр.length; i++) {
        if (возвр[i .. (i + 1)] == РАЗДПАП) {
            // drop the duplicate separator
            i++;
            while (i < возвр.length &&
                   возвр[i .. (i + 1)] == РАЗДПАП) {
                возвр = возвр[0 .. i] ~ возвр[(i + 1) .. $];
            }
        }
    }
    
    // make sure we don't miss a .. element
    if (возвр.length > 3 && возвр[($-3) .. $] == РАЗДПАП ~ "..") {
        возвр ~= РАЗДПАП;
    }
    
    // or a . element
    if (возвр.length > 2 && возвр[($-2) .. $] == РАЗДПАП ~ ".") {
        возвр ~= РАЗДПАП;
    }
    
    // search for .. elements
    for (int i = 0; возвр.length > 4 && i <= возвр.length - 4; i++) {
        if (возвр[i .. (i + 4)] == РАЗДПАП ~ ".." ~ РАЗДПАП) {
            // drop the previous путь element
            int j;
            for (j = i - 1; j > 0 && возвр[j..(j+1)] != РАЗДПАП; j--) {}
            if (j > 0) {
                // cut
                if (возвр[j..j+2] == "/.") {
                    j = i + 2; // skip it
                } else {
                    возвр = возвр[0..j] ~ возвр[(i + 3) .. $];
                }
            } else {
                // can't cut
                j = i + 2;
            }
            i = j - 1;
        }
    }
    
    // search for . elements
    for (int i = 0; возвр.length > 2 && i <= возвр.length - 3; i++) {
        if (возвр[i .. (i + 3)] == РАЗДПАП ~ "." ~ РАЗДПАП) {
            // drop this путь element
            возвр = возвр[0..i] ~ возвр[(i + 2) .. $];
            i--;
        }
    }

    // get rid of any introductory ./'т
    while (возвр.length > 2 && возвр[0..2] == "." ~ РАЗДПАП) {
        возвр = возвр[2..$];
    }
    
    // finally, get rid of any trailing separators
    while (возвр.length &&
           возвр[($ - 1) .. $] == РАЗДПАП) {
        возвр = возвр[0 .. ($ - 1)];
    }
	
    return возвр;
}

/** Make a directory and all parent directories */
проц сделпапР(ткст пап)
{
    пап = канонПуть(пап);
    version (Windows) {
        пап = замени(пап, "/", "\\\\");
    }
    
    // split it into elements
    char[][] элтыпап = разбей(пап, "\\\\");
    
    char[] текпап;
    
    // check for root пап
    if (элтыпап.length &&
        элтыпап[0] == "") {
        текпап = РАЗДПАП;
        элтыпап = элтыпап[1..$];
    }
    
    // then go piece-by-piece, making directories
    foreach (элтпап; элтыпап) {
        if (текпап.length) {
            текпап ~= РАЗДПАП ~ элтпап;
        } else {
            текпап ~= элтпап;
        }
        
        if (!естьФайл(текпап)) {
            сделайпап(текпап);
        }
    }
}

/** Remove a file or directory and all of its children */
проц удалиРек(ткст имя)
{
    // can only delete writable files on Windows
    version (Windows) {
        SetFileAttributesA(toStringz(имя),
                           GetFileAttributesA(toStringz(имя)) &
                           ~0x00000001);
    }
    
    if (std.file.isdir(имя)) {
        foreach (элем; std.file.listdir(имя)) {
            // don't delete . or ..
            if (элем == "." ||
                элем == "..") continue;
            удалиРек(имя ~ РАЗДПАП ~ элем);
        }
        
        // remove the directory itself
        std.file.rmdir(имя);
    } else {
        std.file.remove(имя);
    }
}


private{
    бул[ткст] спСущФайлов;
}

// --------------------------------------------------
бул естьФайлВКэш(ткст имяФ)
{
    if (имяФ in спСущФайлов)
    {
        return да;
    }
    try {
    if(файл_ли(имяФ) && естьФайл(имяФ))
    {
        спСущФайлов[имяФ] = да;
        return да;
    }
    } catch { };
    return нет;
}

// --------------------------------------------------
проц удалиКэшСущФайлов()
{
    ткст[] спКлюч;

    спКлюч = спСущФайлов.keys.dup;
    foreach(ткст спФайл; спКлюч)
    {
        спСущФайлов.remove(спФайл);
    }
}

/+
СФайл двхо;
СФайл двых;
СФайл дош;

static this() {
  // open standard I/O devices
  двхо = new СФайл(дайСтдвхо(), ПФРежим.Ввод);
  двых = new СФайл(дайСтдвых(), ПФРежим.Вывод);
  дош = new СФайл(дайСтдош(), ПФРежим.Вывод);
}

static ~this()
 {
  двхо.слей();
  двхо.закрой();
  двых.слей();
  двых.закрой();
  дош.слей();
  дош.закрой();
}
+/