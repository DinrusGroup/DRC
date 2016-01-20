/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.ModuleManager;

import drc.semantic.Module,
       drc.semantic.Package;
import drc.Diagnostics;
import drc.Messages;
import common;

import tango.io.FilePath,
       tango.io.FileSystem,
       tango.io.model.IFile;
import tango.util.PathUtil : pathNormalize = normalize;

alias FileConst.PathSeparatorChar папРазд;

/// Manages loaded модули in a таблица.
class МодульМенеджер
{
  /// Корневой пакет. Содержит все прочие модули и пакеты.
  Пакет корневойПакет;
  /// Maps full package имена в пакеты. E.g.: drc.ast
  Пакет[ткст] таблицаПакетов;
  /// Maps ПКИ пути в модули. E.g.: dil/ast/Узел
  Модуль[ткст] таблицаПКИПутейКМодулям;
  /// Карта абсолютных путей к файлам модулей. Напр.: /home/user/dil/src/main.d
  Модуль[ткст] таблицаАбсФПутей;
  Модуль[] загруженныеМодули; /// Loaded модули in sequential order.
  ткст[] путиИмпорта; /// Where в look for module files.
  Диагностика диаг;

  /// Constructs a МодульМенеджер object.
  this(ткст[] путиИмпорта, Диагностика диаг)
  {
    this.корневойПакет = new Пакет(null);
    таблицаПакетов[""] = this.корневойПакет;
    this.путиИмпорта = путиИмпорта;
    this.диаг = диаг;
  }

  /// Loads a module given a file путь.
  Модуль загрузиФайлМодуля(ткст путьКФайлуМодуля)
  {
    auto absFilePath = FileSystem.toAbsolute(путьКФайлуМодуля);
    // FIXME: normalize() doesn't simplify //. Handle the exception it throws.
    absFilePath = pathNormalize(absFilePath); // Remove ./ /. ../ and /..
    if (auto existingModule = absFilePath in таблицаАбсФПутей)
      return *existingModule;

    // Create a new module.
    auto newModule = new Модуль(путьКФайлуМодуля, диаг);
    newModule.разбор();

    auto путьПоПКНМодуля = newModule.дайПутьПКН();
    if (auto existingModule = путьПоПКНМодуля in таблицаПКИПутейКМодулям)
    { // Ошибка: two module files have the same f.q. module имя.
      auto положение = newModule.дайСемуДеклМодуля().дайПоложениеОшибки();
      auto сооб = Формат(сооб.КонфликтующиеФайлыМодулей, newModule.путьКФайлу());
      диаг ~= new ОшибкаСемантики(положение, сооб);
      return *existingModule;
    }

    // Insert new module.
    таблицаПКИПутейКМодулям[путьПоПКНМодуля] = newModule;
    таблицаАбсФПутей[absFilePath] = newModule;
    загруженныеМодули ~= newModule;
    // Add the module в its package.
    auto пкт = дайПакет(newModule.имяПакета);
    пкт.добавь(newModule);

    if (auto p = newModule.дайПКН() in таблицаПакетов)
    { // Ошибка: module and package share the same имя.
      auto положение = newModule.дайСемуДеклМодуля().дайПоложениеОшибки();
      auto сооб = Формат(сооб.КонфликтующиеМодульИПакет, newModule.дайПКН());
      диаг ~= new ОшибкаСемантики(положение, сооб);
    }

    return newModule;
  }

  /// Returns the package given a f.q. package имя.
  /// Returns the корень package for an empty ткст.
  Пакет дайПакет(ткст pckgFQN)
  {
    auto pPckg = pckgFQN in таблицаПакетов;
    if (pPckg)
      return *pPckg;

    ткст предшFQN, lastPckgName;
    // E.g.: pckgFQN = 'drc.ast', предшFQN = 'dil', lastPckgName = 'ast'
    разбейПКНПакета(pckgFQN, предшFQN, lastPckgName);
    // Recursively build package hierarchy.
    auto parentPckg = дайПакет(предшFQN); // E.g.: 'dil'

    // Create a new package.
    auto пкт = new Пакет(lastPckgName); // E.g.: 'ast'
    parentPckg.добавь(пкт); // 'dil'.добавь('ast')

    // Insert the package into the таблица.
    таблицаПакетов[pckgFQN] = пкт;

    return пкт;
  }

  /// Splits в.g. 'drc.ast.xyz' into 'drc.ast' and 'xyz'.
  /// Параметры:
  ///   pckgFQN = the full package имя в be split.
  ///   предшFQN = установи в 'drc.ast' in the example.
  ///   lastName = the last package имя; установи в 'xyz' in the example.
  проц  разбейПКНПакета(ткст pckgFQN, ref ткст предшFQN, ref ткст lastName)
  {
    бцел lastDotIndex;
    foreach_reverse (i, c; pckgFQN)
      if (c == '.')
      { lastDotIndex = i; break; } // Found last dot.
    if (lastDotIndex == 0)
      lastName = pckgFQN; // Special case - no dot found.
    else
    {
      предшFQN = pckgFQN[0..lastDotIndex];
      lastName = pckgFQN[lastDotIndex+1..$];
    }
  }

  /// Loads a module given an ПКИ путь.
  Модуль загрузиМодуль(ткст путьПоПКНМодуля)
  {
    // Look up in таблица if the module is already loaded.
    Модуль* pModul = путьПоПКНМодуля in таблицаПКИПутейКМодулям;
    if (pModul)
      return *pModul;

    // Locate the module in the file system.
    auto путьКФайлуМодуля = найдиПутьКФайлуМодуля(путьПоПКНМодуля, путиИмпорта);
    if (!путьКФайлуМодуля.length)
      return null;

    // Load the found module file.
    auto модуль = загрузиФайлМодуля(путьКФайлуМодуля);
    if (модуль.дайПутьПКН() != путьПоПКНМодуля)
    { // Ошибка: the requested module is not in the correct package.
      auto положение = модуль.дайСемуДеклМодуля().дайПоложениеОшибки();
      auto сооб = Формат(сооб.ВПакетеНетМодуля, дайПКНПакета(путьПоПКНМодуля));
      диаг ~= new ОшибкаСемантики(положение, сооб);
    }

    return модуль;
  }

  /// Returns в.g. 'drc.ast' for 'dil/ast/Узел'.
  static ткст дайПКНПакета(ткст путьПоПКНМодуля)
  {
    ткст пкт = путьПоПКНМодуля.dup;
    бцел lastDirSep;
    foreach (i, c; пкт)
      if (c == папРазд)
        (пкт[i] = '.'), (lastDirSep = i);
    return пкт[0..lastDirSep];
  }

  /// Searches for a module in the file system looking in путиИмпорта.
  /// Возвращает: the file путь в the module, or null if it wasn't found.
  static ткст найдиПутьКФайлуМодуля(ткст путьПоПКНМодуля, ткст[] путиИмпорта)
  {
    auto путьКФайлу = new FilePath();
    foreach (путьИмпорта; путиИмпорта)
    {
      путьКФайлу.set(путьИмпорта); // E.g.: ист/
      путьКФайлу.append(путьПоПКНМодуля); // E.g.: dil/ast/Узел
      foreach (суффиксМодуля; [".d", ".di"/*interface file*/])
      {
        путьКФайлу.suffix(суффиксМодуля);
        if (путьКФайлу.exists()) // E.g.: ист/dil/ast/Узел.d
          return путьКФайлу.вТкст();
      }
    }
    return null;
  }
}
