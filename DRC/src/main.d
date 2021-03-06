module main;

import drc.parser.Parser;
import drc.lexer.Lexer,
       drc.lexer.Token;
import drc.ast.Declarations,
       drc.ast.Expressions,
       drc.ast.Node,
        drc.ast.Visitor;
import drc.semantic.Module,
       drc.semantic.Symbols,
       drc.semantic.Pass1,
       drc.semantic.Pass2,
       drc.semantic.Passes;
import drc.code.Interpreter;
import drc.translator.German;
import drc.Messages;
import drc.CompilerInfo;
import drc.Diagnostics;
import drc.SourceText;
import drc.Compilation;

import cmd.Compile;
import cmd.Highlight;
import cmd.Statistics;
import cmd.ImportGraph;
import cmd.DDoc;

import Settings;
import SettingsLoader;
import common;

import Целое = text.convert.Integer;
import cidrus;
import io.File;
import text.Util;
import time.StopWatch;
import text.Ascii : сравнилюб;
import ll.Core, ll.Types;

/// Функция входа в drc.
проц  main(ткст[] арги)
{
    ЛЛРеестрПроходок пр = ЛЛДайГлобРеестрПроходок();
   	ЛЛИницЯдро(пр);	
	ЛЛШатдаун();

  auto диаг = new Диагностика();
  ЗагрузчикКонфиг(диаг).загрузи();
  if (диаг.естьИнфо)
    return выведиОшибки(диаг);

  if (арги.length <= 1)
    return выведиСправку("глав");

  ткст команда = арги[1];
  switch (команда)
  {
  case "к", "компилируй", "конст", "compile":
    if (арги.length < 3)
      return выведиСправку(команда);

    КомандаКомпилировать кмд;
    кмд.контекст = новКонтекстКомпиляции();
    кмд.диаг = диаг;

    foreach (арг; арги[2..$])
    {
      if (разборОтладкаИлиВерсия(арг, кмд.контекст))
      {}
      else if (ткстнач(арг, "-S"))
        кмд.контекст.путиИмпорта ~= арг[2..$];
      else if (арг == "-выпуск"||"-release")
        кмд.контекст.постройкаРелиз = да;
      else if (арг == "-тест"||"-unittest")
      {
      version(D2)
        кмд.контекст.добавьИдВерсии("unittest");
        кмд.контекст.постройкаТест = да;
      }
      else if (арг == "-о")
        кмд.контекст.приниматьДеприкированное = да;
      else if (арг == "-пс")
        кмд.вывестиДеревоСимволов = да;
      else if (арг == "-пм")
        кмд.вывестиДеревоМодулей = да;
      else
        кмд.путиКФайлам ~= арг;
    }
    кмд.пуск();
    диаг.естьИнфо && выведиОшибки(диаг);
    break;
  case "ддок", "д", "ddoc", "d":
    if (арги.length < 4)
      return выведиСправку(команда);

    КомандаДДок кмд;
    кмд.путьКПапкеНазн = арги[2];
    кмд.макроПути = ГлобальныеНастройки.путиКФайлуДдок;
    кмд.контекст = новКонтекстКомпиляции();
    кмд.диаг = диаг;

    // Разбор аргументов.
    foreach (арг; арги[3..$])
    {
      if (разборОтладкаИлиВерсия(арг, кмд.контекст))
      {}
      else if (арг == "--ряр"||"--xml")
        кмд.писатьРЯР = да;
      else if (арг == "-и"||"-i")
        кмд.включатьНедокументированное = да;
      else if (арг == "-в"|| "-v")
        кмд.подробно = да;
      else if (арг.length > 3 && ткстнач(арг, "-м=")||ткстнач(арг, "-m="))
        кмд.ПутьТкстаМод = арг[3..$];
      else if (арг.length > 5 && сравнилюб(арг[$-4..$], "ддок") == 0||сравнилюб(арг[$-4..$], "ддок") == 0)
        кмд.макроПути ~= арг;
      else
        кмд.путиКФайлам ~= арг;
    }
    кмд.пуск();
    диаг.естьИнфо && выведиОшибки(диаг);
    break;
  case "псв", "подсвети", "hl":
    if (арги.length < 3)
      return выведиСправку(команда);

    КомандаВыделить кмд;
    кмд.диаг = диаг;

    foreach (арг; арги[2..$])
    {
      switch (арг)
      {
      case "--синтаксис","--синт","s":
        кмд.добавь(КомандаВыделить.Опция.Синтаксис); break;
      case "-ряр","-xml":
        кмд.добавь(КомандаВыделить.Опция.РЯР); break;
      case "-гяр","-html":
        кмд.добавь(КомандаВыделить.Опция.ГЯР); break;
      case "-строки", "-стр":
        кмд.добавь(КомандаВыделить.Опция.ВыводСтрок); break;
      default:
        кмд.путьКФайлу = арг;
      }
    }
    кмд.пуск();
    диаг.естьИнфо && выведиОшибки(диаг);
    break;
  case "графимпорта", "ги", "g":
    if (арги.length < 3)
      return выведиСправку(команда);

    ИКомандаГрафа кмд;
    кмд.контекст = новКонтекстКомпиляции();

    foreach (арг; арги[2..$])
    {
      if (разборОтладкаИлиВерсия(арг, кмд.контекст))
      {}
      else if (ткстнач(арг, "-S"))
        кмд.контекст.путиИмпорта ~= арг[2..$];
      else if(ткстнач(арг, "-х"))
        кмд.регвыры ~= арг[2..$];
      else if(ткстнач(арг, "-у"))
        кмд.уровни = Целое.вЦел(арг[2..$]);
      else if(ткстнач(арг, "-си"))
        кмд.сиСтиль = арг[3..$];
      else if(ткстнач(арг, "-пи"))
        кмд.пиСтиль = арг[3..$];
      else
        switch (арг)
        {
        case "--дот", "--dot":
          кмд.добавь(ИКомандаГрафа.Опция.ВыводитьДот); break;
        case "--пути", "--paths":
          кмд.добавь(ИКомандаГрафа.Опция.ВывестиПути); break;
        case "--список", "--list":
          кмд.добавь(ИКомандаГрафа.Опция.ВывестиСписок); break;
        case "-и", "-i":
          кмд.добавь(ИКомандаГрафа.Опция.ВключатьНеопределённыеМодули); break;
        case "-псвкр", "-hle":
          кмд.добавь(ИКомандаГрафа.Опция.ВыделитьЦиклическиеКрая); break;
        case "-псввер":
          кмд.добавь(ИКомандаГрафа.Опция.ВыделитьЦиклическиеВершины); break;
        case "-гнп":
          кмд.добавь(ИКомандаГрафа.Опция.ГруппироватьПоИменамПакетов); break;
        case "--гпнп":
          кмд.добавь(ИКомандаГрафа.Опция.ГруппироватьПоПолномуИмениПакета); break;
        case "-м":
          кмд.добавь(ИКомандаГрафа.Опция.ПометитьЦиклическиеМодули); break;
        default:
          кмд.путьКФайлу = арг;
        }
    }
    кмд.пуск();
    break;
  case "стат", "статистика", "stats":
    if (арги.length < 3)
      return выведиСправку(команда);

    КомандаСтат кмд;
    foreach (арг; арги[2..$])
      if (арг == "--семтабл")
        кмд.выводитьТаблицуТокенов = да;
      else if (арг == "--адстабл")
        кмд.выводитьТаблицуУзлов = да;
      else
        кмд.путиКФайлам ~= арг;
    кмд.пуск();
    break;
  case "сем", "семанализ", "sem":
    if (арги.length < 3)
      return выведиСправку(команда);
    ИсходныйТекст исходныйТекст;
    ткст путьКФайлу;
    ткст разделитель;
    бул игнорироватьШССемы;
    бул выводитьШС;

    foreach (арг; арги[2..$])
    {
      if (ткстнач(арг, "-к"))
        разделитель = арг[2..$];
      else if (арг == "-")
        исходныйТекст = new ИсходныйТекст("стдвхо", читайСтдвхо());
      else if (арг == "-и")
        игнорироватьШССемы = да;
      else if (арг == "-дс")
        выводитьШС = да;
      else
        путьКФайлу = арг;
    }

    разделитель || (разделитель = "\n");
    if (!исходныйТекст)
      исходныйТекст = new ИсходныйТекст(путьКФайлу, да);

    диаг = new Диагностика();
    auto lx = new Лексер(исходныйТекст, диаг);
    lx.сканируйВсе();
    auto сема = lx.перваяСема();

    for (; сема.вид != TOK.КФ; сема = сема.следщ)
    {
      if (сема.вид == TOK.Новстр || игнорироватьШССемы && сема.пробел)
        continue;
      if (выводитьШС && сема.пп)
        выдай(сема.пробСимволы);
      выдай(сема.исхТекст)(разделитель);
    }

    диаг.естьИнфо && выведиОшибки(диаг);
    break;
  case "пер", "п", "т":
    if (арги.length < 3)
      return выведиСправку(команда);

    if (арги[2] != "Немецкий")
      return выдай.форматнс("Ошибка: нераспознаный целевой язык перевода \"{}\"", арги[2]);

    диаг = new Диагностика();
    auto путьКФайлу = арги[3];
    auto мод = new Модуль(путьКФайлу, диаг);
    // Разбор файла.
    мод.разбор();
    if (!мод.естьОшибки)
    { // Перевод
      auto немец = new НемецкийПереводчик(выдай, "  ");
      немец.переведи(мод.корень);
    }
    выведиОшибки(диаг);
    break;
  case "профиль", "profile":
    if (арги.length < 3)
      break;
    сим[][] путиКФайлам;
    if (арги[2] == "дстресс"||"dstress")
    {
      auto текст = cast(сим[])(new Файл("dstress_files")).читай();
      путиКФайлам = разбей(текст, "\0");
    }
    else
      путиКФайлам = арги[2..$];

    Секундомер секмер;
    секмер.старт;

    foreach (путьКФайлу; путиКФайлам)
      (new Лексер(new ИсходныйТекст(путьКФайлу, да))).сканируйВсе();

    выдай.форматнс("Сканирован за {:f10}с.", секмер.стоп);
    break;
  case "с", "справка", "h", "help", "/?":
    выведиСправку(арги.length >= 3 ? арги[2] : "");
    break;
  default:
    выведиСправку("глав");
  }
  
}

/// Читает со стандартного ввода и возвращает его содержимое.
ткст читайСтдвхо()
{
  ткст текст;
  while (1)
  {
    auto с = берисфл(стдвхо);
    if (с == КФ)
      break;
    текст ~= с;
  }
  return текст;
}

/// Доступные команды.
const ткст КОМАНДЫ =
"  справка,с        (h, /?, help) \n"
"  компиляция,к     (с,compile)   \n"
"  ддок, д          (d, ддок)     \n"
"  подсвет,псв      (hl)           \n"
"  графимпорта,ги   (g)           \n"
"  статистика,стат  (стат)        \n"
"  семанализ,сем    (sem)         \n"
"  перевод, п       (т, translate)\n";

бул ткстнач(ткст ткт, ткст начало)
{
  if (ткт.length >= начало.length)
  {
    if (ткт[0 .. начало.length] == начало)
      return да;
  }
  return нет;
}

/// Создаёт глобальный контекст компиляции.
КонтекстКомпиляции новКонтекстКомпиляции()
{
  auto кк = new КонтекстКомпиляции;
  кк.путиИмпорта = ГлобальныеНастройки.путиИмпорта;
  кк.добавьИдВерсии("drc(дрк)");
  кк.добавьИдВерсии("все");
version(D2)
  кк.добавьИдВерсии("D_Version2");
  foreach (идВерсии; ГлобальныеНастройки.идыВерсий)
    if (Лексер.действитНерезИдентификатор(идВерсии))
      кк.добавьИдВерсии(идВерсии);
  return кк;
}

/// Разбирает опции командной строки отладка ил версия.
бул разборОтладкаИлиВерсия(ткст арг, КонтекстКомпиляции контекст)
{
  if (ткстнач(арг, "-отладка")||ткстнач(арг, "-debug"))
  {
    if (арг.length > 7)
    {
      auto знач = арг[7..$];
      if (drc.lexer.Funcs.цифра(знач[0]))
        контекст.уровеньОтладки = Целое.вЦел(знач);
      else if (Лексер.действитНерезИдентификатор(знач))
        контекст.добавьИдОтладки(знач);
    }
    else
      контекст.уровеньОтладки = 1;
  }
  else if (арг.length > 9 && ткстнач(арг, "-версия=")||ткстнач(арг, "-version="))
  {
    auto знач = арг[9..$];
    if (drc.lexer.Funcs.цифра(знач[0]))
      контекст.уровеньВерсии = Целое.вЦел(знач);
    else if (Лексер.действитНерезИдентификатор(знач))
      контекст.добавьИдВерсии(знач);
  }
  else
    return нет;
  return да;
}

/// Выводит ошибки, собранные при диагностике.
проц  выведиОшибки(Диагностика диаг)
{
  foreach (инфо; диаг.инфо)
  {
    ткст форматОшибки;
    if (инфо.classinfo is ОшибкаЛексера.classinfo)
      форматОшибки = ГлобальныеНастройки.форматОшибкиЛексера;
    else if (инфо.classinfo is ОшибкаПарсера.classinfo)
      форматОшибки = ГлобальныеНастройки.форматОшибкиПарсера;
    else if (инфо.classinfo is ОшибкаСемантики.classinfo)
      форматОшибки = ГлобальныеНастройки.форматОшибкиСемантики;
    else if (инфо.classinfo is Предупреждение.classinfo)
      форматОшибки = "{0}: Предупреждение: {3}";
    else if (инфо.classinfo is drc.Information.Ошибка.classinfo)
      форматОшибки = "Ошибка: {3}";
    else
      continue;
    auto ош = cast(Проблема)инфо;
    Стдош.форматнс(форматОшибки, ош.путьКФайлу, ош.место, ош.столб, ош.дайСооб);
  }
}

/// Распечатывает справочное сообщение о команде.
/// Если команда не найдена, распечатывается главное справочное сообщение.
проц  выведиСправку(ткст команда)
{
  ткст сооб;
	  switch (команда)
	  {
	  case "к", "компиляция", "с", "compile":
	  сооб = ДайСооб(ИДС.СправкаОКомпиляции);

	  /+  сооб = `Компилировать исходники на Ди.
	Использование:
	  drc(дрк) компилируй файл.d [файл2.d, ...] [Опции]

	  Эта команда только парсирует исходники и выполняет небольший семантический анализ.
	  Ошибки выводятся на стандартный вывод для ошибок.

	Опции:
	  -депр             : принимать деприкированный код
	  -отладка          : включать код отладки
	  -отладка=уровень  : включать код отладка(у), где у <= уровень
	  -отладка=идент    : включать код отладка(идент)
	  -версия=уровень   : включать код версия(у), где у >= уровень
	  -версия=идент     : включать код версия(идент)
	  -Ипуть            : добавить 'путь' в список путей импорта
	  -релиз       	: компилировать постройку-релиз
	  -тест        		: компилировать постройку-тест
	  -32               : произвести 32-битный код (дефолт)
	  -64               : произвести 64-битный код
	  -прогПРОГ           : вывести программу в ПРОГ

	  -пс               : вывести дерево символов модуля
	  -пм               : вывести дерево пакетов/модулей

	Пример:
	  drc(дрк) к src/main.d -Иист/`;+/
		break;
	  case "ддок", "д", "ddoc","d":
	  сооб = ДайСооб(ИДС.СправкаОДДок);

	 /+   сооб = `Генерировать документацию из комментариев DDoc в исходниках D.
	Использование:
	  drc(дрк) ддок Приёмник файл.d [файл2.d, ...] [Опции]

	  Приёмник - это папка, в которую записываются файлы документации.
	  Файлы с расширением .ддок распознаются как файлы с определением макросов.

	Опции:
	  --ряр            : записать документы РЯР(XML), а не ГЯР(HTML)
	  -и               : включить недокументированные символы
	  -в               : многословный вывод
	  -м=ПУТЬ          : записать список обработанных модулей в ПУТЬ(PATH)

	Пример:
	  drc(дрк) д doc/ src/main.d src/macros_drc.ддок -и -м=doc/модули.txt`;+/
		break;
	  case "псв", "подсвет":
		 сооб = ДайСооб(ИДС.СправкаОПодсветке);
		/+сооб = `Подсветить исходный файл Ди с тегами РЯР или ГЯР.
	Использование:
	  drc(дрк) псв файл.d [Опции]

	Опции:
	  --синтаксис     : генерировать теги для синтактического дерева
	  --ряр           : использовать формат РЯР(XML) (дефолт)
	  --гяр           : использовать формат ГЯР(HTML)
	  --строки        : выводить номера строк

	Пример:
	  drc(дрк) псв src/main.d --гяр --синтаксис > main.html`;+/
		break;
	  case "графимпорта", "ги":
		 сооб = ДайСооб(ИДС.СправкаОГрафеИмпорта);
	   /+ сооб = `Разобрать модуль и построить граф зависимостей, основанный на его импортах.
	Использование:
	  drc(дрк) ги файл.d Формат [Опции]

	  Папка файл.d негласно добавляется в список путей импорта.

	Формат:
	  --дот            : генерировать документ dot (дефолт)
	  Опции, относящиеся к --дот:
	  -гнп             : Группировать модули по названию пакета
	  --гпнп           : Группировать модули по полному названию пакета
	  -псвкр           : подсветить циклические края в графе
	  -псввер          : подсветить модули в цикличиских связях
	  -сиСТИЛЬ         : стиль края, используемый для статических импортов
	  -пиСТИЛЬ         : стиль края, используемый для публичных импортов
	  СТИЛЬ может быть: "dashed", "dotted", "solid", "invis" или "bold"

	  --пути           : вывести пути к файлам модулей в графе

	  --список         : вывести имена модулей в граф
	  Опции, общие для --пути и --список:
	  -уЧИСЛО              : вывести ЧИСЛО уровней.
	  -м               : использовать '*' для пометки модулей с циклическими взаимосвязями

	Опции:
	  -Ипуть           : добавить 'путь' в список путей импорта, по которым будут
						 искаться модули
	  -хРЕГВЫР         : исключить модули, имена которых совпадают с регулярным выражением
						 РЕГВЫР
	  -и               : включить нелоцируемые модули

	Пример:
	  drc(дрк) ги src/main.d --список
	  drc(дрк) ги src/main.d | dot -Tpng > main.png`;+/
		break;
	  case "сем", "семанализ", "sem":
	  сооб = ДайСооб(ИДС.СправкаОСеманализе);
		/+сооб = `Вывести семы исходного файла Ди.
	Использование:
	  drc(дрк) сем файл.d [Опции]

	Опции:
	  -               : читать текст со стандартного ввода.
	  -рРАЗДЕЛИТЕЛЬ   : выводить РАЗДЕЛИТЕЛЬ вместо новой строки между семами.
	  -и              : игнорировать пробельные символы (т.е. коментарии, шебанг и т.д.)
	  -п             : выводить предшествующие пробельные символы.

	Пример:
	  echo "module foo; проц  функц(){}" | drc(дрк) лекс -
	  drc(дрк) лекс src/main.d | grep ^[0-9]`;+/
		break;
	  case "stats", "стат", "статистика":
	  сооб = ДайСооб(ИДС.СправкаОСтатистике);
	  /+ сооб = `Собрать статистику об исходных файлах Ди.
	Использование:
	  drc(дрк) стат файл.d [файл2.d, ...] [Опции]

	Опции:
	  --табток      : вывести число всех видов лексем в таблице.
	  --табаст      : вывести число всех видов узлов в таблице.

	Пример:
	  drc(дрк) стат src/main.d src/drc/Юникод.d`;+/
		break;
	  case "п", "переведи","т", "translate":
		сооб = ДайСооб(ИДС.СправкаОПереводе);
	   /+ сооб = `Перевести исходник Ди  на другой язык.
	Использование:
	  drc(дрк) переведи ЯЗЫК файл.d

	  Поддерживаемые языки:
		*) Немецкий

	Пример:
	  drc(дрк) п Немецкий src/main.d`;+/
		break;
	  case "глав":
	  default:
		auto КОМПИЛИРОВАНО_ПРИ_ПОМОЩИ = __VENDOR__;
		auto КОМПИЛ_ВЕРСИЯ = Формат("{}.{,:d3}", __VERSION__/1000, __VERSION__%1000);
		auto КОМПИЛ_ДАТА = __TIMESTAMP__;
	сооб = ФорматируйСооб(ИДС.ГлавнаяСправка, ВЕРСИЯ, КОМАНДЫ, КОМПИЛИРОВАНО_ПРИ_ПОМОЩИ,
						КОМПИЛ_ВЕРСИЯ, КОМПИЛ_ДАТА);

/+сооб = Формат(`Компилятор Динрус версии {0}
Авторское право (с) 2012-2020 Виталий Кулич, Азиз Кёксал.
Лицензия GPL3.

Подкоманды:

{1}

Введите 'drc(дрк) справка <подкоманда>' для получения
 дополнительной информации о подкоманде.

Компилирован с помощью {2} версии {3}
Дата компиляции: {4}.`, ВЕРСИЯ, КОМАНДЫ, КОМПИЛИРОВАНО_ПРИ_ПОМОЩИ,
						КОМПИЛ_ВЕРСИЯ, КОМПИЛ_ДАТА);
			+/
	  }
  выдай(сооб).нс;
}
