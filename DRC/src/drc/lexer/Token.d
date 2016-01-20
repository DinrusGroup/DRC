/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.lexer.Token;

import drc.lexer.Identifier,
       drc.lexer.Funcs;
import drc.Location;
import tango.stdc.stdlib : malloc, free;
import tango.core.Exception;
import common;

public import drc.lexer.TokensEnum;

/// A Сема - это цепочка символов, формируемая лексическим анализатором.
struct Сема
{ /// Флаги, устанавливаемые Лексером.
  enum Флаги : бкрат
  {
    Нет,
    Пробельный = 1, /// Знаки с этим флагом игнорируются Парсером.
  }

  TOK вид; /// Вид семы.
  Флаги флаги; /// Флаги семы.
  /// Указатели на следующую и предыдущую семы (дважды линкованный список.)
  Сема* следщ, предш;

  /// Начало пробельных символов перед семой. Нуль, если их нет.
  /// TODO: remove в save space; can be replaced by 'предш.конец'.
  сим* пп;
  сим* старт; /// Указывает на первый символ семы.
  сим* конец;   /// Points one character past the конец of the сема.

  /// Данные, ассоциированные с данной семой.
  /// TODO: move данные structures out; use only pointers here в keep Сема.sizeof small.
  union
  {
    /// При новстр семы.
    ДанныеНовСтр новстр;
    /// При #line семы.
    struct
    {
      Сема* tokLineNum; /// #line число
      Сема* tokLineFilespec; /// #line число filespec
    }
    /// The значение of a ткст сема.
    struct
    {
      ткст ткт; /// Zero-terminated ткст. (The zero is included in the length.)
      сим pf;    /// Postfix 'c', 'w', 'd' or 0 for none.
    version(D2)
      Сема* tok_ткт; /++ Points в the contents of a сема ткст stored as a
                          doubly linked список. The last сема is always '}' or
                          КФ in case конец of source текст is "q{" КФ.
                      +/
    }
    Идентификатор* идент; /// При keywords and identifiers.
    дим  дим_;   /// A character значение.
    дол   дол_;    /// A дол integer значение.
    бдол  бдол_;   /// An unsigned дол integer значение.
    цел    цел_;     /// An integer значение.
    бцел   бцел_;    /// An unsigned integer значение.
    плав  плав_;   /// A плав значение.
    дво дво_;  /// A дво значение.
    реал   реал_;    /// A реал значение.
  }

  /// Returns the текст of the сема.
  ткст исхТекст()
  {
    assert(старт && конец);
    return старт[0 .. конец - старт];
  }

  /// Returns the preceding whitespace of the сема.
  ткст пробСимволы()
  {
    assert(пп && старт);
    return пп[0 .. старт - пп];
  }

  /// Finds the следщ non-whitespace сема.
  /// Возвращает: 'эту' сему, если предыдущая является TOK.ГОЛОВА или null.
  Сема* следщНепроб()
  out(сема)
  {
    assert(сема !is null);
  }
  body
  {
    auto сема = следщ;
    while (сема !is null && сема.пробел_ли)
      сема = сема.следщ;
    if (сема is null || сема.вид == TOK.КФ)
      return this;
    return сема;
  }

  /// Находит предшествующую непробельную сему.
  /// Возвращает: 'эту' сему, если предыдущая является TOK.ГОЛОВА или null.
  Сема* предшНепроб()
  out(сема)
  {
    assert(сема !is null);
  }
  body
  {
    auto сема = предш;
    while (сема !is null && сема.пробел_ли)
      сема = сема.предш;
    if (сема is null || сема.вид == TOK.ГОЛОВА)
      return this;
    return сема;
  }

  /// Возвращает текстовое определение вида данной семы.
  static ткст вТкст(TOK вид)
  {
    return семаВТкст[вид];
  }

  /// Adds Флаги.Пробельный в this.флаги.
  проц  установиФлагПробельные()
  {
    this.флаги |= Флаги.Пробельный;
  }

  /// Возвращает да, если это сема, внутри которой могут быть символы новой строки.
  ///
  /// These can be block and nested comments and any ткст literal
  /// except for escape ткст literals.
  бул многострок_ли()
  {
    return вид == TOK.Ткст && старт[0] != '\\' ||
           вид == TOK.Комментарий && старт[1] != '/';
  }

  /// Возвращает да, если это сема-ключевое слово.
  бул кслово_ли()
  {
    return НачалоКС <= вид && вид <= КонецКС;
  }

  /// Возвращает да, если это сема интегрального типа.
  бул интегральныйТип_ли()
  {
    return НачалоИнтегральногоТипа <= вид && вид <= КонецИнтегральногоТипа;
  }

  /// Возвращает да, если это сема пробела.
  бул пробел_ли()
  {
    return !!(флаги & Флаги.Пробельный);
  }

  /// Возвращает да, если это a special сема.
  бул спецСема_ли()
  {
    return НачалоСпецСем <= вид && вид <= КонецСпецСем;
  }

version(D2)
{
  /// Возвращает да, если это a сема ткст literal.
  бул семаСтроковогоЛитерала_ли()
  {
    return вид == TOK.Ткст && tok_ткт !is null;
  }
}

  /// Returns да if this сема starts a ДефиницияДекларации.
  бул началоДефДекл_ли()
  {
    return семаНачалаДеклДеф_ли(вид);
  }

  /// Returns да if this сема starts a Инструкция.
  бул началоИнстр_ли()
  {
    return семаНачалаИнстр_ли(вид);
  }

  /// Returns да if this сема starts an ИнструкцияАсм.
  бул началоАсмИнстр_ли()
  {
    return семаНачалаАсмИнстр_ли(вид);
  }

  цел opEquals(TOK kind2)
  {
    return вид == kind2;
  }

  цел opCmp(Сема* пв)
  {
    return старт < пв.старт;
  }

  /// Returns the Положение of this сема.
  Положение дайПоложение(бул реальноеПоложение)()
  {
    auto search_t = this.предш;
    // Find предшious новстр сема.
    while (search_t.вид != TOK.Новстр)
      search_t = search_t.предш;
    static if (реальноеПоложение)
    {
      auto путьКФайлу  = search_t.новстр.путиКФайлам.oriPath;
      auto номСтр   = search_t.новстр.oriLineNum;
    }
    else
    {
      auto путьКФайлу  = search_t.новстр.путиКФайлам.setPath;
      auto номСтр   = search_t.новстр.oriLineNum - search_t.новстр.setLineNum;
    }
    auto началоСтроки = search_t.конец;
    // Determine actual line начало and line число.
    while (1)
    {
      search_t = search_t.следщ;
      if (search_t == this)
        break;
      // Multiline семы must be rescanned for newlines.
      if (search_t.многострок_ли)
      {
        auto p = search_t.старт, конец = search_t.конец;
        while (p != конец)
          if (сканируйНовСтр(p))
          {
            началоСтроки = p;
            ++номСтр;
          }
          else
            ++p;
      }
    }
    return new Положение(путьКФайлу, номСтр, началоСтроки, this.старт);
  }

  alias дайПоложение!(да) getRealLocation;
  alias дайПоложение!(нет) дайПоложениеОшибки;

  бцел lineCount()
  {
    бцел счёт = 1;
    if (this.многострок_ли)
    {
      auto p = this.старт, конец = this.конец;
      while (p != конец)
      {
        if (сканируйНовСтр(p) == '\n')
          ++счёт;
        else
          ++p;
      }
    }
    return счёт;
  }

  /// Итог the source текст enclosed by the левый and правый сема.
  static сим[] textSpan(Сема* левый, Сема* правый)
  {
    assert(левый.конец <= правый.старт || левый is правый );
    return левый.старт[0 .. правый.конец - левый.старт];
  }

  /// Uses malloc() в allocate memory for a сема.
  new(т_мера размер)
  {
    ук p = malloc(размер);
    if (p is null)
      throw new OutOfMemoryException(__FILE__, __LINE__);
    // TODO: Сема.иниц should be all zeros.
    // Maybe use calloc() в avoid this line?
    *cast(Сема*)p = Сема.init;
    return p;
  }

  /// Deletes a сема using free().
  delete(ук p)
  {
    auto сема = cast(Сема*)p;
    if (сема)
    {
      if(сема.вид == TOK.HashLine)
        сема.destructHashLineToken();
      else
      {
      version(D2)
        if (сема.семаСтроковогоЛитерала_ли)
          сема.destructTokenStringLiteral();
      }
    }
    free(p);
  }

  проц  destructHashLineToken()
  {
    assert(вид == TOK.HashLine);
    delete tokLineNum;
    delete tokLineFilespec;
  }

version(D2)
{
  проц  destructTokenStringLiteral()
  {
    assert(вид == TOK.Ткст);
    assert(старт && *старт == 'q' && старт[1] == '{');
    assert(tok_ткт !is null);
    auto tok_it = tok_ткт;
    auto tok_del = tok_ткт;
    while (tok_it && tok_it.вид != TOK.КФ)
    {
      tok_it = tok_it.следщ;
      assert(tok_del && tok_del.вид != TOK.КФ);
      delete tok_del;
      tok_del = tok_it;
    }
  }
}
}

/// Data associated with новстр семы.
struct ДанныеНовСтр
{
  struct ФПути
  {
    сим[] oriPath;   /// Original путь в the source текст.
    сим[] setPath;   /// Path установи by #line.
  }
  ФПути* путиКФайлам;
  бцел oriLineNum;  /// Actual line число in the source текст.
  бцел setLineNum;  /// Delta line число установи by #line.
}

/// Returns да if this сема starts a ДефиницияДекларации.
бул семаНачалаДеклДеф_ли(TOK лекс)
{
  switch (лекс)
  {
  alias TOK T;
  case  T.Расклад, T.Прагма, T.Экспорт, T.Приватный, T.Пакет, T.Защищённый,
        T.Публичный, T.Экстерн, T.Устаревший, T.Перепись, T.Абстрактный,
        T.Синхронизованный, T.Статический, T.Окончательный, T.Конст, T.Инвариант/*D 2.0*/,
        T.Авто, T.Масштаб, T.Алиас, T.Типдеф, T.Импорт, T.Перечень, T.Класс,
        T.Интерфейс, T.Структура, T.Союз, T.Этот, T.Тильда, T.Юниттест, T.Отладка,
        T.Версия, T.Шаблон, T.Нов, T.Удалить, T.Смесь, T.ТочкаЗапятая,
        T.Идентификатор, T.Точка, T.Типа:
    return да;
  default:
    if (НачалоИнтегральногоТипа <= лекс && лекс <= КонецИнтегральногоТипа)
      return да;
  }
  return нет;
}

/// Returns да if this сема starts a Инструкция.
бул семаНачалаИнстр_ли(TOK лекс)
{
  switch (лекс)
  {
  alias TOK T;
  case  T.Расклад, T.Экстерн, T.Окончательный, T.Конст, T.Авто, T.Идентификатор, T.Точка,
        T.Типа, T.Если, T.Пока, T.Делай, T.При, T.Длявсех, T.Длявсех_реверс,
        T.Щит, T.Реле, T.Дефолт, T.Далее, T.Всё, T.Итог, T.Переход,
        T.Для, T.Синхронизованный, T.Пробуй, T.Брось, T.Масштаб, T.Volatile, T.Asm,
        T.Прагма, T.Смесь, T.Статический, T.Отладка, T.Версия, T.Алиас, T.ТочкаЗапятая,
        T.Перечень, T.Класс, T.Интерфейс, T.Структура, T.Союз, T.ЛФСкобка, T.Типдеф,
        T.Этот, T.Супер, T.Нуль, T.Истина, T.Ложь, T.Цел32, T.Цел64, T.Бцел32,
        T.Бцел64, T.Плав32, T.Плав64, T.Плав80, T.Мнимое32,
        T.Мнимое64, T.Мнимое80, T.СимЛитерал, T.Ткст, T.ЛКвСкобка,
        T.Функция, T.Делегат, T.Подтвердить, T.Импорт, T.Идтипа, T.Является, T.ЛСкобка,
        T.Traits/*D2.0*/, T.ИБинарное, T.ПлюсПлюс, T.МинусМинус, T.Умножь,
        T.Минус, T.Плюс, T.Не, T.Тильда, T.Нов, T.Удалить, T.Каст:
    return да;
  default:
    if (НачалоИнтегральногоТипа <= лекс && лекс <= КонецИнтегральногоТипа ||
        НачалоСпецСем <= лекс && лекс <= КонецСпецСем)
      return да;
  }
  return нет;
}

/// Returns да if this сема starts an ИнструкцияАсм.
бул семаНачалаАсмИнстр_ли(TOK лекс)
{
  switch(лекс)
  {
  alias TOK T;
  case T.Вхо, T.Цел, T.Вых, T.Идентификатор, T.Расклад, T.ТочкаЗапятая:
    return да;
  default:
  }
  return нет;
}
