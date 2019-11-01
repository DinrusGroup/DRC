﻿module drc.ModuleManager;

import drc.semantic.Module,
       drc.semantic.Package;
import drc.Diagnostics;
import drc.Messages;
import common;

import io.FilePath,
       io.FileSystem,
       io.model;
import util.PathUtil : нормализуйПуть = нормализуй;

alias ФайлКонст.СимПутьРазд папРазд;

/// Управляет загруженными модулями в таблице.
class МодульМенеджер
{
  /// Корневой пакет. Содержит все прочие модули и пакеты.
  Пакет корневойПакет;
  /// Мапирует полные имена пакетов в пакеты. Напр.: drc.ast
  Пакет[ткст] таблицаПакетов;
  /// Мапирует ПКИ пути в модули. Напр.: drc/ast/Node
  Модуль[ткст] таблицаПКИПутейКМодулям;
  /// Карта абсолютных путей к файлам модулей. Напр.: /home/user/drc/src/main.d
  Модуль[ткст] таблицаАбсФПутей;
  Модуль[] загруженныеМодули; /// Загруженные модули в последовательном порядке.
  ткст[] путиИмпорта; /// Где искать файлы модулей.
  Диагностика диаг;

  /// Строит объект МодульМенеджер.
  this(ткст[] путиИмпорта, Диагностика диаг)
  {
    this.корневойПакет = new Пакет(пусто);
    таблицаПакетов[""] = this.корневойПакет;
    this.путиИмпорта = путиИмпорта;
    this.диаг = диаг;
  }

  /// Загружает модуль по заданному файловому пути.
  Модуль загрузиФайлМодуля(ткст путьКФайлуМодуля)
  {
    auto абсФПуть = ФСистема.вАбсолют(путьКФайлуМодуля);
    // FIXME: нормализуй() doesn'т simplify //. Handle the exception it throws.
    абсФПуть = нормализуйПуть(абсФПуть); // Удалить ./ /. ../ и /..
    if (auto сущМодуль = абсФПуть in таблицаАбсФПутей)
      return *сущМодуль;

    // Создать новый модуль.
    auto новМодуль = new Модуль(путьКФайлуМодуля, диаг);
    новМодуль.разбор();

    auto путьПоПКНМодуля = новМодуль.дайПутьПКИ();
    if (auto сущМодуль = путьПоПКНМодуля in таблицаПКИПутейКМодулям)
    { // Ошибка: два файла мудуля имеют одинаковые п.к. имена модуля.
      auto положение = новМодуль.дайСемуДеклМодуля().дайПоложениеОшибки();
      auto сооб = Формат(сооб.КонфликтующиеФайлыМодулей, новМодуль.путьКФайлу());
      диаг ~= new ОшибкаСемантики(положение, сооб);
      return *сущМодуль;
    }

    // Вставить новый модуль.
    таблицаПКИПутейКМодулям[путьПоПКНМодуля] = новМодуль;
    таблицаАбсФПутей[абсФПуть] = новМодуль;
    загруженныеМодули ~= новМодуль;
    // Добавить модуль в его пакет.
    auto пкт = дайПакет(новМодуль.имяПакета);
    пкт.добавь(новМодуль);

    if (auto у = новМодуль.дайПКИ() in таблицаПакетов)
    { // Ошибка: у модуля и пакета совпадают имена.
      auto положение = новМодуль.дайСемуДеклМодуля().дайПоложениеОшибки();
      auto сооб = Формат(сооб.КонфликтующиеМодульИПакет, новМодуль.дайПКИ());
      диаг ~= new ОшибкаСемантики(положение, сооб);
    }

    return новМодуль;
  }

  /// Возвращает пакет с указанным пк-именем.
  /// Возвращает корневой пакет при пустом ткст.
  Пакет дайПакет(ткст пКНПкта)
  {
    auto pPckg = пКНПкта in таблицаПакетов;
    if (pPckg)
      return *pPckg;

    ткст предшПКН, последнИмяПкта;
    // Напр.: пКНПкта = 'drc.ast', предшПКН = 'dil', последнИмяПкта = 'ast'
    разбейПКНПакета(пКНПкта, предшПКН, последнИмяПкта);
    // Рекурсивное построение иерархии пакетов.
    auto родПкт = дайПакет(предшПКН); // Напр.: 'dil'

    // Создать новый пакет.
    auto пкт = new Пакет(последнИмяПкта); // Напр.: 'ast'
    родПкт.добавь(пкт); // 'dil'.добавь('ast')

    // Вставить пакет в таблицу.
    таблицаПакетов[пКНПкта] = пкт;

    return пкт;
  }

  /// Разбивает напр. 'drc.ast.xyz' на 'drc.ast' и 'xyz'.
  /// Параметры:
  ///   пКНПкта = полное разбиваемое нами имя пакета.
  ///   предшПКН = установка в 'drc.ast' в примере.
  ///   последнИмя = последнее имя пакета; установлено в 'xyz' в примере.
  проц  разбейПКНПакета(ткст пКНПкта, ref ткст предшПКН, ref ткст последнИмя)
  {
    бцел последнИндксТчки;
    foreach_reverse (i, с; пКНПкта)
      if (с == '.')
      { последнИндксТчки = i; break; } // Найдена последняя точка.
    if (последнИндксТчки == 0)
      последнИмя = пКНПкта; // Особый случай - точки не найдено.
    else
    {
      предшПКН = пКНПкта[0..последнИндксТчки];
      последнИмя = пКНПкта[последнИндксТчки+1..$];
    }
  }

  /// Загружает модуль с указанным пк-путём.
  Модуль загрузиМодуль(ткст путьПоПКНМодуля)
  {
    // Просмотреть в таблице, найден ли уже этот модуль.
    Модуль* уМодуль = путьПоПКНМодуля in таблицаПКИПутейКМодулям;
    if (уМодуль)
      return *уМодуль;

    // Обнаружить модуль в файловой системе.
    auto путьКФайлуМодуля = найдиПутьКФайлуМодуля(путьПоПКНМодуля, путиИмпорта);
    if (!путьКФайлуМодуля.length)
      return пусто;

    // Загрузить найденный фаул модуля.
    auto модуль = загрузиФайлМодуля(путьКФайлуМодуля);
    if (модуль.дайПутьПКИ() != путьПоПКНМодуля)
    { // Ошибка: запрошенный модуль отсутствует в пакете.
      auto положение = модуль.дайСемуДеклМодуля().дайПоложениеОшибки();
      auto сооб = Формат(сооб.ВПакетеНетМодуля, дайПКНПакета(путьПоПКНМодуля));
      диаг ~= new ОшибкаСемантики(положение, сооб);
    }

    return модуль;
  }

  /// Возвращает напр. 'drc.ast' для 'ddc/ast/Node'.
  static ткст дайПКНПакета(ткст путьПоПКНМодуля)
  {
    ткст пкт = путьПоПКНМодуля.dup;
    бцел последнПапРазд;
    foreach (i, с; пкт)
      if (с == папРазд)
        (пкт[i] = '.'), (последнПапРазд = i);
    return пкт[0..последнПапРазд];
  }

  /// Ищет модуль в файловой системе по адресам, указанным в путиИмпорта.
  /// Возвращает: путь к файлу модуля или пусто, если он не нйден.
  static ткст найдиПутьКФайлуМодуля(ткст путьПоПКНМодуля, ткст[] путиИмпорта)
  {
    auto путьКФайлу = new ФПуть();
    foreach (путьИмпорта; путиИмпорта)
    {
      путьКФайлу.установи(путьИмпорта); // Напр.: src/
      путьКФайлу.добавь(путьПоПКНМодуля); // Напр.: drc/ast/Node
      foreach (суффиксМодуля; [".d", ".di"/*файл интерфейса*/])
      {
        путьКФайлу.суффикс(суффиксМодуля);
        if (путьКФайлу.есть_ли()) // Напр.: src/drc/ast/Node.d
          return путьКФайлу.вТкст();
      }
    }
    return пусто;
  }
}
