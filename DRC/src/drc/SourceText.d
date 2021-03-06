﻿module drc.SourceText;

import drc.Converter;
import drc.Diagnostics;
import drc.Messages;
import common;

import io.File,
       io.FilePath;  
	

/// Представляет исходный код Динрус.
///
/// Исходный текст может поступать из файла или буфера памяти.
final class ИсходныйТекст
{
  /// Файловый путь к исходному тексту. Используется в обновном для сообщений об ошибках.
  ткст путьКФайлу;
  ткст данные; /// UTF-8, исходный текст с нулевым окончанием.

  /// Строит объект ИсходныйТекст.
  /// Параметры:
  ///   путьКФайлу = Файловый путь к исходнику.
  ///   загрузитьФайл = загружать ли файл в конструктор.
  this(ткст путьКФайлу, бул загрузитьФайл = нет)
  {
    this.путьКФайлу = путьКФайлу;
    загрузитьФайл && загрузи();
  }

  /// Строит объект ИсходныйТекст.
  /// Параметры:
  ///   путьКФайлу = файловый путь для сообщения об ошибке.
  ///   данные = буфер памяти.
  this(ткст путьКФайлу, ткст данные)
  {
    this(путьКФайлу);
    this.данные = данные;
    addSentinelCharacter();
  }

  /// Загружает текст исходника из файла.
  проц  загрузи(Диагностика диаг = пусто)
  {
    if (!диаг)
      диаг = new Диагностика;
    assert(путьКФайлу.length);

    scope(failure)
    {
      if (!(new ФПуть(this.путьКФайлу)).есть_ли())
        диаг ~= new ОшибкаЛексера(new Положение(путьКФайлу, 0),
                                  сооб.ФайлОтсутствует);
      else
        диаг ~= new ОшибкаЛексера(new Положение(путьКФайлу, 0),
                                  сооб.ФайлНеЧитается);
      данные = "\0";
      return;
    }

    // Прочитать файл.
    auto rawdata = cast(ббайт[]) (new Файл(путьКФайлу)).читай();
    // Преобразовать данные.
    auto конвертер = Преобразователь(путьКФайлу, диаг);
    данные = конвертер.данныеВУТФ8(rawdata);
    addSentinelCharacter();
  }

  /// Добавляет '\0' в текст (если ещё нет.)
  private проц  addSentinelCharacter()
  {
    if (данные.length == 0 || данные[$-1] != 0)
      данные ~= 0;
  }
}
