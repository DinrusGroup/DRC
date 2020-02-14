module std.stream;
import exception, std.intrinsic, std.utf,tpl.stream: Поток, ТПотокМассив;

/// Этот подкласс предназначен для небуферированных системных файловых потоков.

export extern (D)
 class Файл: Поток {

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
  файлУк = СоздайФайл(вЮ16(имяф), доступ, шара,  null, режСозд, ПФайл.Нормальный, null);

    открытый(файлУк != cast(ук) НЕВЕРНХЭНДЛ);

    if (!открытый())
      throw new Исключение("std.stream.Файл.открой:Не удалось открыть или создать файл '" ~ имяф ~ "'");
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
  throw new Исключение("std.stream.Файл.сместись: не удаётся переместить файловый указатель",__FILE__, __LINE__);
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

      ббайт[] буфер;
    бцел текБуфПоз;
   бцел длинаБуф;
    бул черновойБуф;
     бцел позИстокаБуф;
    бдол позПотока;


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
  throw new Исключение("std.stream.БуфПоток.слей: Не удаётся запись в поток", __FILE__, __LINE__);
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
    if (возвратКаретки) {
      возвратКаретки(нет);
      c = бериш();
      if (c != '\n')
  return c;
    }
  шим[] возвр = возврат();
    if (возвр.length > 1) {

      c = возвр[возвр.length - 1];
      возвр.length = возвр.length - 1;
    возврат(возвр);
    } else {
      ук буф = &c;
      т_мера n = читайБлок(буф,2);
      if (n == 1 && читайБлок(буф+1,1) == 0)
          throw new Исключение("std.stream.ПотокЭндианец.бериш: Недостаточно данных в потоке",__FILE__, __LINE__);
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
  this(байт[] буф) { this(cast(ббайт[]) буф);}  /// ditto
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

     бдол поз;  // our позиция relative to low
    бдол низ; // низ stream смещение.
    бдол верх; // верх stream смещение.
    бул ограничен; // upper-ограничен by верх.
  Поток п;


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
  Чтение,   /// read existing file
  ЧтенЗапНов, /// delete existing file, write new file
  ЧтенЗап,  /// read/write existing file, создай if not existing
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
          auto namez = std.utf.toUTF16(имяф);
          hFile = СоздайФайл(namez,
              dwDesiredAccess2,
              dwShareMode,
              null,
              dwCreationDisposition,
              ПФайл.Нормальный,
              cast(ук) null);        

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
          // эхо("\topen ошибка, errno = %d\n",getErrno());
          errNo();
        }

        if (os.posix.fstat(fd, &statbuf))
        {
          //эхо("\tfstat ошибка, errno = %d\n",getErrno());
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
version (linux)     флаги |= MAP_ANONYMOUS;
else version (OSX)    флаги |= MAP_ANON;
else version (FreeBSD)    флаги |= MAP_ANON;
else version (Solaris)    флаги |= MAP_ANON;
else        static assert(0);
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

      i = msync(cast(проц*)data, data.length, MS_SYNC); // sys/mman.h
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

  // unmap the current Диапазон
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

  // map Диапазон
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

  // ensure a given Диапазон is mapped
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

  // Report ошибка, where errno gives the ошибка number
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
