/***
Модуль рантайма языка Динрус. Разработчик Виталий Кулич.

*/
module runtime;
import gc, cidrus: выход;
import  sys.WinFuncs;

//debug = НА_КОНСОЛЬ;

extern (C)
{
		проц нить_объединиВсе();
		проц нить_иниц();
		void _d_callfinalizer(ук  p);
		проц установиКонсоль();
}

extern (Windows) int WideCharToMultiByte(uint, uint, wchar_t*, int, char*, int, char*, int);

alias extern(C) проц function() МодИниц;

//======================================================================
//Получение аргументов командной строки

//Функция для получения этих аргументов
//вызывающей программой в обработанном виде:
export extern(C) ткст[] дайАргиКС(){return арги;}
//Функция, с помощью которой библиотека получает "сырые" аргументы от
//от вызывающей программы:
export extern (C) ткст[] ртПолучиАрги(int argc, char **argv)
{

        wchar*    wcbuf = GetCommandLineW();
        size_t    wclen = wcslen(wcbuf);
        int       wargc = 0;
        wchar**   wargs = CommandLineToArgvW(wcbuf, &wargc);
        assert(wargc == argc, stdrus.вТкст("Расхождение числа аргументов командной строки"));

        char*     cargp = null;
        size_t    cargl = WideCharToMultiByte(65001, 0, wcbuf, wclen, null, 0, null, 0);

        cargp = cast(char*) alloca(cargl);
        арги  = ((cast(char[]*) alloca(wargc * (char[]).sizeof)))[0 .. wargc];

        for (size_t i = 0, ptr = 0; i < wargc; i++)
        {
            int wlen = wcslen( wargs[i] );
            int clen = WideCharToMultiByte(65001, 0, &wargs[i][0], wlen, null, 0, null, 0);
            арги[i]  = cargp[ptr .. ptr+clen];
            ptr += clen; assert(ptr <= cargl);
            WideCharToMultiByte(65001, 0, &wargs[i][0], wlen, &арги[i][0], clen, null, 0);
        }
        LocalFree(cast(HLOCAL) wargs);
        wargs = null;
        wargc = 0;
		return арги;
/*

static цел шдлина;
static цел чдлин;
static ушим*   шарги;

		проц ошиб()
		{
		бцел кодош = ДайПоследнююОшибку();
		throw new Исключение (текстСисОшибки(кодош));
		}

try{
		 	ушим    шбуфчтен = ДайКомСтроку();
			т_мера    шстрдлин = длинашкс(шбуфчтен);
			цел       шаргчло = 0;
			шарги = КомСтрокаВАрги(шбуфчтен, &шаргчло);
			assert(шаргчло == аргчло);

			static усим     аргук = null;
			т_мера    аргстр = ШирСимВМультиБайт(ПКодСтр.УТФ8, cast(ПШирСим) 0, шбуфчтен, шстрдлин, null, 0, null, нет);

			аргук = cast(усим) разместа(аргстр);
			арги  = ((cast(char[]*) разместа(шаргчло * (char[]).sizeof)))[0 .. шаргчло];

			for (т_мера i = 0, укз = 0; i < шаргчло; i++)
			{
				шдлина = длинашкс( шарги[i] );
				assert(шдлина <= int.max, stdrus.вТкст("Длина аргументов не может превышать int.max"));
				чдлин = ШирСимВМультиБайт(ПКодСтр.УТФ8, cast(ПШирСим) 0, &шарги[i][0], шдлина, null, 0, null, нет);
				арги[i]  = аргук[укз .. укз+чдлин];
				укз += чдлин; assert(укз <= аргстр);
				if(!ШирСимВМультиБайт(ПКодСтр.УТФ8, cast(ПШирСим) 0, &шарги[i][0], шдлина, &арги[i][0], чдлин, null, нет))ошиб;
			}
			ОсвободиЛок(шарги);
			шарги = null;
			шаргчло = 0;
			return арги;
		}
	catch(Исключение и)
						{и.вТкст(); }//return арги = ["<пусто>"];}
		*/
}

//==============================================================

static ОбработчикСборки сбобр = null;
alias сбобр collectHandler;//нужно для модуля rt.lifetime
static Следопыт следопыт = null;

static	т_см _см;//Рабочий экземпляр сборщика мусора

static	бул задержка_ли = нет;
static	бул ртПущен_ли = нет;
static	бул смИнициирован = нет;

//Аргументы командной строки:
static ткст[] арги;


//++=====================================================================
extern(C) ИнфОМодуле[] _moduleinfo_array;
export extern(C) struct Рантайм
{
enum
{   НКМНачато = 1,	// построение модулей началось
    НКМВыполнено = 2,	// завершилось
    НКМОдиночно = 4,	// конструктор модуля не зависимый от
			// ранее инициализированных конструкторов
    ЕстьНКМ = 8,	// есть независимые конструкторы
}

static ИнфОМодуле[] конструкторы;
static ИнфОМодуле[] деструкторы;
static бцел квоПостроений = 0;
static бцел индекс;

//Запуск сборщика мусора:
/*private*/ проц смСтарт()
		{
			ук укз;
			ИнфОКлассе ci = СМ.classinfo;

			укз = cidrus.празмести(ci.init.length);
			(cast(байт*)укз)[0 .. ci.init.length] = ci.init[];
			_см = cast(т_см)  укз;
			_см.иниц();
			смИнициирован = да;
			_см.сканируйСтатДан( _см);
				debug(НА_КОНСОЛЬ) скажинс ("смСтарт передаёт команду пускНити");
			нить_иниц();
				debug(НА_КОНСОЛЬ) скажинс("СборщикМусора успешно инициализирован. Поздравляю!");
				debug(НА_КОНСОЛЬ) смСтат();
		}
//Передача адреса СМ вовне:
export extern(C) т_см дайСборщикМусора()
{
return cast(т_см) _см;
}

//Функции для передаче информации о подключенных модулях, их
//а.Конструкторы:
export extern(C) ИнфОМодуле[] дайКонструкторы()
{
return конструкторы;
}
//б.Деструкторы:
export extern(C) ИнфОМодуле[] дайДеструкторы()
{
return деструкторы;
}

//Необходимая процедура для переучёта конструкторов и деструкторов
//при присоединении к библиотеке новых запущеных модулей и формирования списка модулей
//для их обработки сборщиком мусора.
/*private*/ проц перерасчётИнфоСтруктур(ИнфОМодуле[] масмод)
{
	if(квоПостроений >= 1 && масмод !is null)
	{
		ИнфОМодуле[] м = конструкторы~масмод;
		assert(м.length == (конструкторы.length+масмод.length));
		конструкторы = м;
		assert(конструкторы.length == м.length);

		ИнфОМодуле[] д = деструкторы~new ИнфОМодуле[масмод.length];
		assert(д.length == (деструкторы.length+масмод.length));
		деструкторы = д;
		assert(деструкторы.length == д.length);

		бцел пересчёт;
		foreach(дест; деструкторы)
		{
		  if(дест !is null) пересчёт++;
		}
		//assert(пересчёт > индекс);
		индекс = пересчёт;
		assert(индекс < деструкторы.length);
		debug(НА_КОНСОЛЬ) скажинс("НАШ ПЕРЕРАСЧЁТ СРАБОТАЛ!))))))");
	}
}
//Выполняет инициализацию модулей как для самой библиотеки, так и для
//запускаемых и присоединяемых к ней программ.
/*private*/ проц модИниц(МодИниц миниц = &_minit, ИнфОМодуле[] масмод = null)
 {
if(миниц) миниц();
if(масмод is null && квоПостроений == 0)
{
конструкторы = _moduleinfo_array;
деструкторы = new ИнфОМодуле[конструкторы.length];
}
else перерасчётИнфоСтруктур(масмод);
 квоПостроений++;

debug(НА_КОНСОЛЬ) эхо("moduli.vsye = x%x\n", cast(ук )конструкторы);

debug(НА_КОНСОЛЬ) эхо("moduli.destructory = x%x\n", cast(ук )деструкторы);
//delete _moduleinfo_array;
}

/*private*/ проц проверка()
		{
				debug(НА_КОНСОЛЬ) скажи("проверкаМодулей()\n");
			for (бцел i = 0; i < конструкторы.length; i++)
			{
			ИнфОМодуле m = конструкторы[i];

			if (!m)
				continue;

				debug(НА_КОНСОЛЬ) эхо("\tmodule[%d] = '%.*s'\n", i, m.name);
			if (m.unitTest)
			{
				(*m.unitTest)();
			}
			}
		}

/*private*/ бул стройНезависимые()
			{
				debug(НА_КОНСОЛЬ) скажи("констрНезависимыхМодулей()\n");
				int raz = 1;
				foreach (m; конструкторы)
				{
				if (m && m.flags & ЕстьНКМ && m.ictor)
					{
						(*m.ictor)();
					debug(НА_КОНСОЛЬ) эхо("\tindependent module '%.*s'\n", m.name);
					}
				debug(НА_КОНСОЛЬ) скажинс(фм("%d цикл конструктора независимых (не импортирующих) модулей", raz));
				raz++;
				}
				return да;
			}

/*private*/ бул стройМодули(ИнфОМодуле[] ми, бул пропуск)
{
	//перерасчётИнфоСтруктур(ми);

		debug(НА_КОНСОЛЬ)
				{
				скажинс("\nНОВЫЙ ВЫЗОВ ПОСТРОЙЩИКА МОДУЛЕЙ");
				скажинс(фм("\nконструкторМодулей(): %d модулей", ми.length));
				скажинс("Список всех модулей: ");
					int n = 1;
					foreach(m; ми)
					{
					эхо("%d.< %.*s >: %p\n", ми.length - (ми.length - n), m.name, m);
					n++;
					}
					нс;
					скажинс("Обработка");
					нс;
				}

			for (бцел i = 0; i < ми.length; i++)
			{
				ИнфОМодуле m = ми[i];

					debug(НА_КОНСОЛЬ) эхо("Module[%d] = '%p' = '%.*s'\n", i, m, m.name);
				if (!m)
				{
				debug(НА_КОНСОЛЬ) скажинс("ИнфОМодуле отсутствует");
					continue;
				}

				if (m.flags & НКМВыполнено)
				{
				debug(НА_КОНСОЛЬ) скажинс("Модуль уже построен");
					continue;
				}
					debug(НА_КОНСОЛЬ) эхо("Module[%d] = '%.*s', m = x%x, m.flags = x%x\n", i, m.name, m, m.flags);

				if (m.ctor || m.dtor)
				{
					if (m.flags & НКМНачато)
					{	if (пропуск || m.flags & НКМОдиночно)
						{
						debug(НА_КОНСОЛЬ) скажи("Пропущен модуль: ");
						debug(НА_КОНСОЛЬ) эхо("module[%d] = '%.*s', m = x%x, m.flags = x%x\n", i, m.name, m, m.flags);
						continue;
						}
					throw new ОшКтораМодуля(m);
					}

					m.flags |= НКМНачато;
					debug(НА_КОНСОЛЬ) скажинс("\nРекурсивный вызов  1");
					this.стройМодули(m.importedModules, нет);
					if (m.ctor)
					debug(НА_КОНСОЛЬ)
					{
					скажи("Выполняется конструктор для модуля: \n");
					эхо("\tmodule[%d] = '%.*s', m = x%x, m.flags = x%x\n", i, m.name, m, m.flags);
					}
					(*m.ctor)();
					debug(НА_КОНСОЛЬ) скажи("Конструктор выполнен \n");
					m.flags &= ~НКМНачато;
					m.flags |= НКМВыполнено;
					debug(НА_КОНСОЛЬ) скажи("Флаги установлены \n");
					// После выполнения конструктора регистрируем деструктор
						debug(НА_КОНСОЛЬ) эхо("\tadding module dtor x%x\n", m);
					assert(индекс < деструкторы.length);
					деструкторы[индекс++] = m;
				}
				else
				{
					m.flags |= НКМВыполнено;
					debug(НА_КОНСОЛЬ) скажинс("\nРекурсивный вызов  2");
					this.стройМодули(m.importedModules, да);
				}
			}
		return да;
		}

export extern(C) бул старт()
{
смСтарт();
debug(НА_КОНСОЛЬ) скажинс("ПУСК СМ - отлично!");
модИниц();
debug(НА_КОНСОЛЬ) скажинс("ИНИЦИАЛИЗАЦИЯ МАССИВА МОДУЛЕЙ - отлично!");
стройНезависимые();
debug(НА_КОНСОЛЬ) скажинс("ПОСТРОЕНИЕ НЕЗАВИСИМЫХ МОДУЛЕЙ - отлично!");
стройМодули(конструкторы, нет);
debug(НА_КОНСОЛЬ) скажинс("ПОСТРОЙКА МОДУЛЕЙ - отлично!");
проверка();
debug(НА_КОНСОЛЬ) скажинс("ПРОВЕРКА МОДУЛЕЙ - отлично!");
ртПущен_ли = да;
return да;
}

export extern(C) бул интегрируй(ИнфОМодуле[] масмод)
{
модИниц(null, масмод);
стройНезависимые();
стройМодули(конструкторы, нет);
return да;
}

/*private*/ проц деструктор()
{
	debug(НА_КОНСОЛЬ) скажи(фм("деструкторМодулей(): %d модулей\n", индекс));
	for (бцел i = индекс; i-- != 0;)
	{
		ИнфОМодуле m = деструкторы[i];

		debug(НА_КОНСОЛЬ) эхо("\tmodule[%d] = '%.*s', x%x\n", i, m.name, m);
		if (m.dtor)
		{
			(*m.dtor)();
		}
	}
}

/*private*/ проц смСтоп()
		{
		_см.полныйСборБезСтэка();
		_см.Дтор();
		cidrus.освободи(cast(ук )_см);
		}

export extern(C) проц стоп()
	{
	ртПущен_ли = нет;
	деструктор();
	смСтоп();
	}

}

static Рантайм _рт;
export extern (C) Рантайм рантайм(){return _рт;}
//=========================================================
export extern (C)	бул ртСтарт(ПередВходом передвхо = null, ОбработчикИсключения дг = null)
	{

	if (ртПущен_ли)
			return да;

		try
		{
		_рт.старт();
		if(передвхо) передвхо();

		}
		catch( Исключение e )
		{
			if( дг )
				дг( e );
					return нет;
		}
		finally
		{
		установиКонсоль();
		}
		return да;
	}
//}
//===========================================================================================



export extern (C)	проц ртСтоп()//ПередВыходом передвых = пусто, ОбработчикИсключения дг = пусто )
	{




		try
			{
			задержка_ли = да;
			объединиВсеНити();
			_рт.стоп();
				выход(0);
			}
			catch( Исключение e )
			{
				выход(-1);
			}


	}


export extern (C) бул ртПущен(){ return ртПущен_ли;}
export extern (C) бул ртОстановлен(){ return !ртПущен_ли;}

//==================================================================
/+
проц создайПроцесс( )
{
    ИНФОСТАРТА si;
    ИНФОПРОЦ pi;

    ОбнулиПамять( &si, si.sizeof );
    si.размер = si.sizeof;
    ОбнулиПамять( &pi, pi.sizeof );

    // Start the child process.
    if( !СоздайПроцесс( пусто,   // Без названия модуля (использовать комстроку).
        "MyChildProcess", // Комстрока.
        пусто,             // Хендл процесса ненаследуемый.
        пусто,             // Хендл нити ненаследуемый.
        нет,            // Устанавливает наследование хендла в нет.
        0,                // Без флагов создания.
        пусто,             // Используется блок среды родителя.
        пусто,             // Используется стартовая папка родителя.
        &si,              // Указатель на структуру STARTUPINFO.
        &pi )             // Указатель на структуру PROCESS_INFORMATION.
    )
    {
        скажифнс( "CreateProcess не удался, т.к. (%d).\n", ДайПоследнююОшибку() );
        return;
    }

    // Ожидание завершения дочернего процесса.
    ЖдиОдинОбъект( pi.процесс, БЕСК );

    // Закрытие хендлов процесса и нити.
    ЗакройДескр( pi.процесс );
    ЗакройДескр( pi.нить );
}
+/
/**
Функция требует дополнения (и продолжения) из Танго.
*/



//========================================================================

export extern (C) проц  ртСоздайОбработчикСледа( Следопыт h )
	{
		следопыт = h;
	}

/**
Функция требует дополнения (и продолжения) из Танго.
*/
export extern (C) Исключение.ИнфОСледе ртСоздайКонтекстСледа( ук  укз ){
		if( следопыт is null )
			return null;
		return следопыт( укз );
		}

/**
Обработчик сборки взят из Танго и требуется
добавка кода оттуда, чтобы эта функция оказалась полезной.
(Дублировать на английском?)
*/
export extern (C) проц  ртУстановиОбработчикСборки(ОбработчикСборки h)
	{
		сбобр = h;
	}
/**
По идее у нас должно выполниться построение списков данных о модулях
библиотеки внутри самой библиотеки. Такое же построение происходит и
в параллельно запущенном исполнимом процессе. Поскольку их память
разграничена и не пересекается, эти процессы проводятся отдельно,
а далее - при слиянии сборщиков - все они объединяются в одно целое.

Концептуально можно следовать двум путям:
 а) использовать один общий сборщик мусора для всех выполняющихся модулей
 Динрус, что позволило бы контролировать общую рабочую среду для данного
 языка программирования, мониторировать все работающие программы, написанные
 на Динрусе, объединить все эти процессы одним общим сервисным узлом,
 который выполняет контролирующие функции и следит за "поведением"
 своего "братства"...

 б) создавать локальный СМ для каждой отдельной программы, то есть
 загружать память лишним мусором, тормозя быстродействие машины...

 В первом варианте рантайм выступает серверной службой, постоянно
 работающей для всех процессов; во втором - он загружается каждым процессом
 в своё "личное" адресное пространство и ничего не знает о сосуществовании
 других процессов, использующих его же копию в своём индивидуальном
 пространстве...

 На данный момент реализуемо и то и другое, но приоритет, кажется,
 нужно отдать первому варианту - это гарантия обеспечения безопасности
 для компьютера в целом со стороны программ, написанных на Динрусе и
 возможность точного мониторинга и контроля за общей рабочей средой.

 Собственно, Майкрософт так и делает в случае своего CLR.(!)

 в) Третий вариант более замысловатый: СЛУЖБА КОНТРОЛЯ над
 мусоросборщиками локальных процессов, т.е некий общий мусорособрщик-
 супервайзер, контролирующий работу внутренних мусоросборщиков
 каждой отдельной из программ. То есть, сетевая структура (!)
 с общим центром контроля...

 Как только появится библиотека VIZ - визуализации интерфейса
 пользователя, в трее может быть размещен "рычаг" для управления и
 мониторинга; а рантайм будет пополнен множеством модулей мониторинга
 всей рабочей среды Динрус, вплоть до регистрации времени работы каждой из программ.

 Те части Рулады, которые вряд ли будут далее изменяться, можно
 руссифицировать в виде обёрток и поместить в динамические библиотеки типа
 Dinrus.DBI.dll  и т.д. Это зрелые продукты, исходные коды которых
 можно будет надолго заархивировать и забыть об их "толщине",
 оставив только интерфейсные файлы для пользования реализованным в них "добром".

 У Рулады свой рантайм, поэтому Динрус должен регистрировать кэш подобных
 модулей. Впрочем, Такие же модули могут быть и на других языках программирования,
 с интерфейсом импорта типа lib.sdl или lib.arc, которые уже есть в Динрусе...

 Желательно не доверять чуждым продуктам, а пользоваться открытым кодом и
 создавать проверенные экземпляры с префиксом Dinrus (Dinrus.SDL.dll etc),
 чтобы в случае чего образовался самостоятельный кластер, на основе которого
 можно было бы создать собственную операционную систему.

*/

export extern (C)
{
///////////////////////////////////////////////////////////
	бул рт_вЗадержке()
		{
			return задержка_ли;
		}
////////////////////////////////////////////////////////

	бул смПроверь(ук укз)
		{
		_см.проверь(укз); return да;
		}

	бул смУменьши()
		{
		_см.экономь(); return да;
		}

	 бул смДобавьКорень( ук укз )
		{
		_см.добавьКорень( укз ); return да;
		}

	 бул смДобавьПространство( ук укз, т_мера разм )
		{
		_см.добавьПространство( укз, разм ); return да;
		}

	 бул смДобавьПространство2( ук укз, ук разм )
		 {
		 _см.добавьПространство( укз, разм ); return да;
		 }

	 бул смУдалиКорень( ук укз )
		{
		_см.удалиКорень( укз ); return да;
		}

	 бул смУдалиПространство( ук укз )
		{
		_см.удалиПространство( укз );return да;
		}

	т_мера смЁмкость(ук укз)
		 {
		   return _см.ёмкость(укз);
		 }

	 бул смМонитор(ddel начало, dint конец )
		{
		_см.монитор(начало, конец); return да;
		}

	 бул смСтат()
		 {
		 СМСтат стат = смДайСтат();
		скажинс(фм("
		ИНФО О СОСТОЯНИИ СМ:
		#размер пула = x%x,
		#используемый размер = x%x,
		#размер списка очистки = x%x,
		#блоков очистки = %d,
		#блоков страниц = %d",	стат.размерПула, стат.испРазмер, стат.размСпискаСвобБлоков, стат.свобБлоки, стат.блокиСтр));
			return да;
		}

	 СМСтат смДайСтат()
		 {
			СМСтат стат;
			_см.дайСтат(стат);
			return стат;
		}

	 проц[] смПразместиМас(т_мера члобайт)
		 {
			ук  укз = смКразмести(члобайт);
			return cast(проц[]) укз[0 .. члобайт];
		 }

	 проц[] смПереместиМас(ук  укз, т_мера члобайт)
		{
			ук  q = смПеремести(укз, члобайт);
			return cast(проц[]) q[0 .. члобайт];
		}

	 бул устИнфОТипе(ИнфОТипе иот, ук  укз)
	 {
		setTypeInfo(иот, укз);
		return да;
	 }

	 ук  дайУкНаСМ()
		{
		return адаптВыхУкз(&_см);
		}

	 бул укНаСМ(ук  укз)
	 	{
		ук oldp = дайУкНаСМ();
		т_см g = cast(т_см)адаптВхоУкз(укз);
		// Add our static data to the new gc
		_см.сканируйСтатДан(g);
		_см = g;
		return да;
		}

	 бул сбросьУкНаСМ()
		{
		_см.отсканируйСтатДан(_см);return да;
		}


	 бцел смДайАтр( ук  укз )
		 {
		  return _см.дайАтр( укз );
		 }

	 бцел смУстАтр( ук  укз, ПАтрБлока a )
	 	{
	   	return _см.устАтр( укз, a );
		}

	 бцел смУдалиАтр( ук  укз, ПАтрБлока a )
		 {
			return _см.удалиАтр( укз, a );
		 }

	 ук  смПразмести( т_мера разм, бцел ba = 0 )
		 {
			return адаптВыхУкз(_см.празмести( разм, ba ));
		 }

	 ук  смКразмести( т_мера разм, бцел ba = 0 )
		 {
		 return адаптВыхУкз(_см.кразмести( разм, ba ));
		 }

	 ук  смПеремести( ук  укз, т_мера разм, бцел ba = 0 )
		{
		  return адаптВыхУкз(_см.перемести( укз, разм, ba ));
		}

	 т_мера смРасширь( ук укз, т_мера mx, т_мера разм )
		{
		return _см.расширь( укз, mx, разм );
		}

	 т_мера смРезервируй( т_мера разм )
		{
		return _см.резервируй( разм );
		}

	 бул смОсвободи( ук  укз )
		{
		_см.освободи( адаптВхоУкз(укз) ); return да;
		}

	 ук  смАдрес( ук  укз )
		{
		return адаптВыхУкз(_см.адрес_у(адаптВхоУкз( укз)));
		}

	 т_мера смРазмер( ук  укз )
		{
		return _см.размер_у( адаптВхоУкз(укз) );
		}

	 ук  смСоздайСлабУк( Объект r )
		{
		  return адаптВыхУкз(_см.создайСлабУк(r));
		}

	 бул смУдалиСлабУк( ук  wp )
	 	{
		_см.удалиСлабУк(адаптВхоУкз(wp));return да;
		}

	 Объект смДайСлабУк( ук  wp )
	 {
	 return _см.дайСлабУк(адаптВхоУкз(wp));
	 }

	 ИнфОБл смОпроси( ук  укз )
		{
		 return cast(ИнфОБл) _см.опроси(адаптВхоУкз( укз) );
		}

	 бул смВключи()
		 {
		  _см.вкл(); return да;
		 }

	 бул смОтключи()
		{
		 _см.откл(); return да;
		}

	 бул смСобери()
		{
		 _см.собери();return да;
		}

	бул смИниц_ли(){return смИнициирован;}

	//цел смОбходКорня(){return _см.обходКорня;}

	//цел смОбходПространства(){return _см.обходПространства;}
}

	проц объединиВсеНити() {нить_объединиВсе();}

//////////////////////////////////////////////////////////

alias СМСтат GCStats;
alias ИнфОБл BlkInfo;
alias ФИНАЛИЗАТОР_СМ GC_FINALIZER;
alias т_см gc_t;
ModuleInfo[] _moduleinfo_dtors;
uint _moduleinfo_dtors_i;

export extern (D)
{
		 void addRoot(ук укз)		      { _см.добавьКорень(укз); }
		 void removeRoot(ук укз)	      { _см.удалиКорень(укз); }
		 void addRange(ук pbot, ук ptop) {_см.добавьПространство( pbot, ptop );}
		 void removeRange(ук pbot)	      { _см.удалиПространство(pbot); }
		 void fullCollect()		      { _см.собери(); }
		 void fullCollectNoStack()	      {_см.полныйСборБезСтэка();}
		 void genCollect()		      { _см.генСбор();}
		 void minimize()			      { _см.экономь(); }
		 void disable()			      { _см.откл(); }
		 void enable()			      { _см.вкл(); }
		 void getStats(out GCStats stats)      {  _см.дайСтат(stats);}
		 void hasPointers(ук  укз)	      { _см.естьУказатели(укз); }
		 void hasNoPointers(ук  укз)	      {  _см.нетУказателей(укз);}
		 void setV1_0()			      { _см.устВ1_0();}

	void[] malloc(size_t nbytes)
		{
			ук  укз = _см.празмести(nbytes);
			return cast(void[]) укз[0 .. nbytes];
		}

	void[] realloc(ук  укз, size_t nbytes)
		{
			ук  q = _см.перемести(укз, nbytes);
			return cast(void[]) q[0 .. nbytes];
		}

	size_t extend(ук  укз, size_t minbytes, size_t maxbytes)
		{
			return _см.расширь(укз, minbytes, maxbytes);
		}

	size_t capacity(ук  укз)
		{
			return _см.ёмкость(укз);
		}
 }

////////////////////////////////////////////////

export extern (C) проц _moduleCtor()
{
    _рт.модИниц();
    _рт.стройНезависимые();
    _рт.стройМодули(_рт.конструкторы, нет);
}

export extern (C) проц _moduleCtor2(ИнфОМодуле[] mi, бул skip)
{
    _рт.стройМодули(mi, skip);
}


/**********************************
 * Destruct the modules.
 */

// Starting the name with "_STD" means under linux a pointer to the
// function gets put in the .dtors segment.

  export extern (C) проц _moduleDtor()
	{
	_рт.деструктор();
	}

	/**********************************
	 * Run unit tests.
	 */

	 export extern (C) проц _moduleUnitTests()
	{
	_рт.проверка();
	}

	/**********************************
	 * Run unit tests.
	 */

	export  extern (C) проц _moduleIndependentCtors()
	{
	_рт.стройНезависимые();
	}


////////////////////////////////////////////////////////////////
//приводится чисто для использования библиотеки из Си
export:

 extern (C)  void _d_gc_addrange(ук pbot, ук ptop)
	{
		_см.добавьПространство(pbot, ptop);
	}

	//for gcosxc.c
extern (C)  void _d_gc_removerange(ук pbot)
	{
		_см.удалиПространство(pbot);
	}


extern (C) void setTypeInfo(TypeInfo ti, ук  укз)
	{
	try{
		if (ti.flags() & 1)
		_см.нетУказателей(укз);
		else
		_см.естьУказатели(укз);
		}
	catch(Исключение искл)
		{
		debug(TypeInfo) искл.выведи;
		_см.нетУказателей(укз);
		}
	}

extern (C) ук  getGCHandle()
	{
		return адаптВыхУкз(&_см);
	}

extern (C) void setGCHandle(ук  укз)
	{
		ук  oldp = getGCHandle();
		т_см g = cast(т_см)укз;


		// Add our static data to the new gc
		_см.сканируйСтатДан(g);

		_см = g;
	//    return oldp;
	}

extern (C) void endGCHandle()
	{
		_см.отсканируйСтатДан(_см);
	}

extern (C) void gc_init()
	{
			ук укз;
				ИнфОКлассе ci = СМ.classinfo;

				укз = cidrus.празмести(ci.init.length);
				(cast(byte*)укз)[0 .. ci.init.length] = ci.init[];
				_см = cast(т_см)  укз;
				_см.иниц();
				_см.сканируйСтатДан( _см);
				нить_иниц();
	}

extern (C) void gc_term()
	{
		_см.полныйСборБезСтэка();
		_см.Дтор();

	}

 void new_finalizer(ук укз, bool dummy)
	{
		//эхо("new_finalizer(укз = %укз)\n", укз);
		_d_callfinalizer(укз);
	}

	 extern (C) void _d_callinterfacefinalizer(ук укз)
	{
		//эхо("_d_callinterfacefinalizer(укз = %укз)\n", укз);
		if (укз)
		{
		Interface *pi = **cast(Interface ***)укз;
		Object o = cast(Object)(укз - pi.offset);
		_d_callfinalizer(cast(ук )o);
		}
	}


	 extern (C)  size_t gc_newCapacity(size_t новдлин, size_t size)
	{
		version(none)
		{
		size_t новёмксть = новдлин * size;
		}
		else
		{

		size_t новёмксть = новдлин * size;
		size_t newext = 0;

		if (новёмксть > 4096)
		{
			//double mult2 = 1.0 + (size / log10(pow(новёмксть * 2.0,2.0)));

			// Redo above line using only integer math

			static int log2plus1(size_t c)
			{   int i;

			if (c == 0)
				i = -1;
			else
				for (i = 1; c >>= 1; i++)
				{   }
			return i;
			}

			/* The following setting for mult sets how much bigger
			 * the new size will be over what is actually needed.
			 * 100 means the same size, more means proportionally more.
			 * More means faster but more memory consumption.
			 */
			//long mult = 100 + (1000L * size) / (6 * log2plus1(новёмксть));
			long mult = 100 + (1000L * size) / log2plus1(новёмксть);

			// testing shows 1.02 for large arrays is about the point of diminishing return
			if (mult < 102)
			mult = 102;
			newext = cast(size_t)((новёмксть * mult) / 100);
			newext -= newext % size;
			//эхо("mult: %2.2f, mult2: %2.2f, alloc: %2.2f\n",mult/100.0,mult2,newext / cast(double)size);
		}
		новёмксть = newext > новёмксть ? newext : новёмксть;
		//эхо("новёмксть = %d, новдлин = %d, size = %d\n", новёмксть, новдлин, size);
		}
		return новёмксть;
	}


	/**
	 * Append dchar to char[]
	 */
	 extern (C)  char[] _d_arrayappendcd(inout char[] x, dchar c)
	{
		const размэлта = c.sizeof;            // array element size
		auto ёмксть = _см.ёмкость(адаптВхоУкз(x.ptr));
		auto длина = x.length;

		// c could encode into from 1 to 4 characters
		int члосим;
		if (c <= 0x7F)
			члосим = 1;
		else if (c <= 0x7FF)
			члосим = 2;
		else if (c <= 0xFFFF)
			члосим = 3;
		else if (c <= 0x10FFFF)
			члосим = 4;
		else
		assert(0, "Символ УТФ неверен");	// invalid utf character - should we throw an exception instead?

		auto новдлин = длина + члосим;
		auto новразм = новдлин * размэлта;

		debug(НА_КОНСОЛЬ) эхо("_d_arrayappendcd(elemSize = %d, ptr = %ptr, length = %d, Capacity = %d)\n", размэлта, x.ptr, x.length, ёмксть);

		assert(ёмксть == 0 || длина * размэлта <= ёмксть, "Произведение длины на размер элемента больше ёмкости памяти, \nвыделенной сборщиком мусора под текстовый массив "~x);

		if (ёмксть <= новразм)
		{   byte* newdata;

		if (ёмксть >= 4096)
		{   // Try to extend in-place
			auto u = _см.расширь(x.ptr, (новразм + 1) - ёмксть, (новразм + 1) - ёмксть);
			if (u)
			{
			goto L1;
			}
		}
			debug(НА_КОНСОЛЬ) эхо("_d_arrayappendcd(length = %d, новдлин = %d, ёмксть = %d)\n", длина, новдлин, ёмксть);
			auto новёмксть = gc_newCapacity(новдлин, размэлта);
			assert(новёмксть >= новдлин * размэлта);
			newdata = cast(byte *)_см.празмести(новёмксть + 1);
		_см.нетУказателей(newdata);
			cidrus.memcpy(newdata, x.ptr, длина * размэлта);
			(cast(ук *)(&x))[1] = newdata;
		}
	  L1:
		*cast(size_t *)&x = новдлин;
		char* ptr = &x.ptr[длина];

		if (c <= 0x7F)
		{
			ptr[0] = cast(char) c;
		}
		else if (c <= 0x7FF)
		{
			ptr[0] = cast(char)(0xC0 | (c >> 6));
			ptr[1] = cast(char)(0x80 | (c & 0x3F));
		}
		else if (c <= 0xFFFF)
		{
			ptr[0] = cast(char)(0xE0 | (c >> 12));
			ptr[1] = cast(char)(0x80 | ((c >> 6) & 0x3F));
			ptr[2] = cast(char)(0x80 | (c & 0x3F));
		}
		else if (c <= 0x10FFFF)
		{
			ptr[0] = cast(char)(0xF0 | (c >> 18));
			ptr[1] = cast(char)(0x80 | ((c >> 12) & 0x3F));
			ptr[2] = cast(char)(0x80 | ((c >> 6) & 0x3F));
			ptr[3] = cast(char)(0x80 | (c & 0x3F));
		}
		else
		assert(0);

		assert((cast(size_t)x.ptr & 15) == 0);
		assert(_см.ёмкость(x.ptr) > x.length * размэлта);
		return x;
	}


	/**
	 * Append dchar to wchar[]
	 */
	 extern (C)  wchar[] _d_arrayappendwd(inout wchar[] x, dchar c)
	{
		const размэлта = c.sizeof;            // array element size
		auto ёмксть = _см.ёмкость(x.ptr);
		auto length = x.length;

		// c could encode into from 1 to 2 w characters
		int члосим;
		if (c <= 0xFFFF)
			члосим = 1;
		else
			члосим = 2;

		auto новдлин = length + члосим;
		auto новразм = новдлин * размэлта;

		assert(ёмксть == 0 || length * размэлта <= ёмксть);

		debug(НА_КОНСОЛЬ) эхо("_d_arrayappendwd(размэлта = %d, ptr = %укз, length = %d, ёмксть = %d)\n", размэлта, x.ptr, x.length, ёмксть);

		if (ёмксть <= новразм)
		{   byte* newdata;

		if (ёмксть >= 4096)
		{   // Try to extend in-place
			auto u = _см.расширь(x.ptr, (новразм + 1) - ёмксть, (новразм + 1) - ёмксть);
			if (u)
			{
			goto L1;
			}
		}

			debug(НА_КОНСОЛЬ) эхо("_d_arrayappendwd(length = %d, новдлин = %d, ёмксть = %d)\n", length, новдлин, ёмксть);
			auto новёмксть = gc_newCapacity(новдлин, размэлта);
			assert(новёмксть >= новдлин * размэлта);
			newdata = cast(byte *)_см.празмести(новёмксть + 1);
		_см.нетУказателей(newdata);
			cidrus.memcpy(newdata, x.ptr, length * размэлта);
			(cast(ук *)(&x))[1] = newdata;
		}
	  L1:
		*cast(size_t *)&x = новдлин;
		wchar* ptr = &x.ptr[length];

		if (c <= 0xFFFF)
		{
			ptr[0] = cast(wchar) c;
		}
		else
		{
		ptr[0] = cast(wchar) ((((c - 0x10000) >> 10) & 0x3FF) + 0xD800);
		ptr[1] = cast(wchar) (((c - 0x10000) & 0x3FF) + 0xDC00);
		}

		assert((cast(size_t)x.ptr & 15) == 0);
		assert(_см.ёмкость(x.ptr) > x.length * размэлта);
		return x;
	}


	/**********************************
	 * Support for array.dup property.
	 */

 extern (C) uint gc_getAttr( ук  укз )
	{
        return _см.дайАтр( укз );
	}

 extern (C) uint gc_setAttr( ук  укз, uint a )
	{
		return _см.устАтр( укз, cast(ПАтрБлока) a );
	}

extern (C) uint gc_clrAttr( ук  укз, uint a )
	{
		 return _см.удалиАтр( укз, cast(ПАтрБлока) a );
	}

extern (C) ук  gc_malloc( size_t разм, uint ba = 0 )
	{
        return адаптВыхУкз(_см.празмести( разм, ba ));
	}

	 extern (C) ук  gc_calloc( size_t разм, uint ba = 0 )
	{
        return адаптВыхУкз(_см.кразмести( разм, ba ));
	}

	 extern (C) ук  gc_realloc( ук  укз, size_t разм, uint ba = 0 )
	{
	        return адаптВыхУкз(_см.перемести( укз, разм, ba ));
	}

	 extern (C) size_t gc_extend( ук  укз, size_t mx, size_t разм )
	{
        return _см.расширь( укз, mx, разм );
	}

	 extern (C) size_t gc_reserve( size_t разм )
	{
        return _см.резервируй( разм );
	}

	 extern (C) void gc_free( ук  укз )
	{
        _см.освободи( укз );
 	}

	 extern (C) ук  gc_addrOf( ук  укз )
	{
        return адаптВыхУкз(_см.адрес_у( укз ));
	}

	 extern (C) size_t gc_sizeOf( ук  укз )
	{
        return _см.размер_у( укз );
	}

	 extern (C) ук  gc_weakpointerCreate( Object r )
	{
		return адаптВыхУкз(_см.создайСлабУк(r));
	}

	 extern (C) void gc_weakpointerDestroy( ук  wp )
	{
		_см.удалиСлабУк(wp);
	}

	 extern (C) Object gc_weakpointerGet( ук  wp )
	{
		return _см.дайСлабУк(wp);
	}

	 extern (C) BlkInfo gc_query( ук  укз )
	{
	        return cast(BlkInfo) _см.опроси( укз );
	}

extern (C) void gc_enable()
	{
	_см.вкл();
	}

extern (C) void gc_disable()
	{
	_см.откл();
	}

extern (C) void gc_collect()
	{
	 _см.собери();
	}

extern (C) проц setFinalizer(ук укз, GC_FINALIZER pFn)
	{
      	_см.устФинализатор(укз, pFn);
	}


extern (C) void gc_printStats(gc_t gc)
{
СМСтат стат;
gc.дайСтат(стат);
скажинс(фм("

ИНФО О СОСТОЯНИИ СМ:
#размер пула = x%x,
#используемый размер = x%x,
#размер списка очистки = x%x,
#блоков очистки = %d,
#блоков страниц = %d\n

",
		стат.размерПула, стат.испРазмер, стат.размСпискаСвобБлоков, стат.свобБлоки, стат.блокиСтр));
}

extern (C) bool rt_isHalting()
{
    return задержка_ли;
}

/////////////////////////////////////////////////////////////////////////////////
/+ Текст из CRITICAL.c Задача: ---Переделать в Динрус---

/*
 * Placed into the Public Domain
 * written by Walter Bright, Digital Mars
 * www.digitalmars.com
 */

/* ================================= Win32 ============================ */

#if _WIN32

#include	<windows.h>

/******************************************
 * Enter/exit critical section.
 */

/* Критические секции не инициализируются без нужды в этом.
 * Поэтому сохраняется линкованный список используемых секций.
 * В коде статического деструктора список обходится и
 * указанные в нём критические секции освобождаются.
 */

typedef struct D_CRITICAL_SECTION
{
    struct D_CRITICAL_SECTION *next;
    CRITICAL_SECTION cs;
} D_CRITICAL_SECTION;

static D_CRITICAL_SECTION *dcs_list;
static D_CRITICAL_SECTION critical_section;
static volatile int inited;

/*__declspec(dllexport)*/ void _d_criticalenter(D_CRITICAL_SECTION *dcs)
{
    if (!dcs->next)
    {
	EnterCriticalSection(&critical_section.cs);
	if (!dcs->next)	// if, in the meantime, another thread didn't set it
	{
	    dcs->next = dcs_list;
	    dcs_list = dcs;
	    InitializeCriticalSection(&dcs->cs);
	}
	LeaveCriticalSection(&critical_section.cs);
    }
    EnterCriticalSection(&dcs->cs);
}

/*__declspec(dllexport)*/ void _d_criticalexit(D_CRITICAL_SECTION *dcs)
{
    LeaveCriticalSection(&dcs->cs);
}

/*__declspec(dllexport)*/ void _STI_critical_init()
{
    if (!inited)
    {	InitializeCriticalSection(&critical_section.cs);
	dcs_list = &critical_section;
	inited = 1;
    }
}

/*__declspec(dllexport)*/ void _STD_critical_term()
{
    if (inited)
    {	inited = 0;
	while (dcs_list)
	{
	    DeleteCriticalSection(&dcs_list->cs);
	    dcs_list = dcs_list->next;
	}
    }
}

#endif

/* ================================= linux ============================ */

#if linux || __APPLE__ || __FreeBSD__ || __sun&&__SVR4

#include	<stdio.h>
#include	<stdlib.h>
#include	<pthread.h>

// PTHREAD_MUTEX_RECURSIVE is the "standard" symbol,
#if linux || __APPLE__
// while the _NP version is specific to Linux
#ifndef PTHREAD_MUTEX_RECURSIVE
#    define PTHREAD_MUTEX_RECURSIVE PTHREAD_MUTEX_RECURSIVE_NP
#endif
#endif

/******************************************
 * Enter/exit critical section.
 */

/* We don't initialize critical sections unless we actually need them.
 * So keep a linked list of the ones we do use, and in the static destructor
 * code, walk the list and release them.
 */

typedef struct D_CRITICAL_SECTION
{
    struct D_CRITICAL_SECTION *next;
    pthread_mutex_t cs;
} D_CRITICAL_SECTION;

static D_CRITICAL_SECTION *dcs_list;
static D_CRITICAL_SECTION critical_section;
static pthread_mutexattr_t _criticals_attr;

void _STI_critical_init(void);
void _STD_critical_term(void);

void _d_criticalenter(D_CRITICAL_SECTION *dcs)
{
    if (!dcs_list)
    {	_STI_critical_init();
	atexit(_STD_critical_term);
    }
    //printf("_d_criticalenter(dcs = x%x)\n", dcs);
    if (!dcs->next)
    {
	pthread_mutex_lock(&critical_section.cs);
	if (!dcs->next)	// if, in the meantime, another thread didn't set it
	{
	    dcs->next = dcs_list;
	    dcs_list = dcs;
	    pthread_mutex_init(&dcs->cs, &_criticals_attr);
	}
	pthread_mutex_unlock(&critical_section.cs);
    }
    pthread_mutex_lock(&dcs->cs);
}

void _d_criticalexit(D_CRITICAL_SECTION *dcs)
{
    //printf("_d_criticalexit(dcs = x%x)\n", dcs);
    pthread_mutex_unlock(&dcs->cs);
}

void _STI_critical_init()
{
    if (!dcs_list)
    {	//printf("_STI_critical_init()\n");
	pthread_mutexattr_init(&_criticals_attr);
	pthread_mutexattr_settype(&_criticals_attr, PTHREAD_MUTEX_RECURSIVE);

	// The global critical section doesn't need to be recursive
	pthread_mutex_init(&critical_section.cs, 0);
	dcs_list = &critical_section;
    }
}

void _STD_critical_term()
{
    if (dcs_list)
    {	//printf("_STI_critical_term()\n");
	while (dcs_list)
	{
	    //printf("\tlooping... %x\n", dcs_list);
	    pthread_mutex_destroy(&dcs_list->cs);
	    dcs_list = dcs_list->next;
	}
    }
}

#endif


+/