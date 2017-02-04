﻿/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.SourceText;

import drc.Converter;
import drc.Diagnostics;
import drc.Messages;
import common;

import io.File,
       io.FilePath;
	   
	

/// Represents D source код.
///
/// The source текст may come из a file or из a memory буфер.
final class ИсходныйТекст
{
  /// The file путь в the source текст. Mainly used for ошибка сообщения.
  ткст путьКФайлу;
  ткст данные; /// The UTF-8, zero-terminated source текст.

  /// Строит ИсходныйТекст объект.
  /// Параметры:
  ///   путьКФайлу = file путь в the source file.
  ///   загрузитьФайл = whether в загрузи the file in the constructor.
  this(ткст путьКФайлу, бул загрузитьФайл = нет)
  {
    this.путьКФайлу = путьКФайлу;
    загрузитьФайл && загрузи();
  }

  /// Строит ИсходныйТекст объект.
  /// Параметры:
  ///   путьКФайлу = file путь for ошибка сообщения.
  ///   данные = memory буфер.
  this(ткст путьКФайлу, ткст данные)
  {
    this(путьКФайлу);
    this.данные = данные;
    addSentinelCharacter();
  }

  /// Loads the source текст из a file.
  проц  загрузи(Диагностика диаг = null)
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

    // Read the file.
    auto rawdata = cast(ббайт[]) (new Файл(путьКФайлу)).читай();
    // Convert the данные.
    auto конвертер = Преобразователь(путьКФайлу, диаг);
    данные = конвертер.данныеВУТФ8(rawdata);
    addSentinelCharacter();
  }

  /// Adds '\0' в the текст (if not already there.)
  private проц  addSentinelCharacter()
  {
    if (данные.length == 0 || данные[$-1] != 0)
      данные ~= 0;
  }
}
