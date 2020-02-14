/**
Модуль для работы с потоками и фибрами языка Динрус.
Разработчик Виталий Кулич.
*/
module thread;

    import exception, sync, stdrus, cidrus;
    version = СТЭК_РАСТЁТ_ВНИЗ;

extern(C) ук адаптВыхУкз(ук укз);
extern(C) ук адаптВхоУкз(ук укз);

    private
    {
        extern (C) 
        {
        проц  _d_monitorenter(Object);
        проц  _d_monitorexit(Object);
        ук ртНизСтэка();
        ук ртВерхСтэка();
        }

        version(D_InlineAsm_X86){
            бцел getEBX(){
                бцел retVal;
                asm{
                    mov retVal,EBX;
                }
                return retVal;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Обработчики Сигналов и Входа в Нить 
    ////////////////////////////////////////////////////////////////////////////////

    version( Win32 )
    {
        
                    //
            // точка входа для нитей на Windows
            //
            extern (Windows) бцел нить_точкаВхода( ук арг )
            {
                Нить  объ = cast(Нить) адаптВхоУкз(арг);
                assert( объ );
                scope( exit ) Нить.удали( объ );

                assert( объ.м_тек is &объ.м_глав );
                объ.м_глав.нстэк = ртНизСтэка();
                объ.м_глав.встэк = объ.м_глав.нстэк;
                Нить.добавь( &объ.м_глав );
                Нить.установиЭту( объ );

                // NOTE: Пока не установлены указатели стека, не могут происходить
                //      никакие размещения сборщиком мусора, а Нить.дайЭту 
                //       возвращает рабочую ссылку на Объект данной нити
                //       (последнее условие не строго соблюдается для
                //       Win32, но ему нужно следовать ради
                //       консистентности).

                // TODO: Consider putting an auto exception Object here (using
                //       alloca) forOutOfMemoryError plus something to track
                //       whether an exception is in-flight?

                try
                {
                    объ.пуск();
                }
                catch( Object o )
                {
                    объ.м_необработ = o;
                }
                return 0;
            }


            //
            // copy of the same-named function in phobos.std.thread--it uses the
            // Windows naming convention to be consistent with GetCurrentThreadId
            //
    export  extern (Windows)    ук ДайДескрТекущейНити()
            {
                const бцел DUPLICATE_SAME_ACCESS = 0x00000002;

                ук curr = ДайТекущуюНить(),
                       proc = ДайТекущийПроцесс(),
                       hndl;

                ДублируйДескр( proc, curr, proc, &hndl, cast(ППраваДоступа) 0, да, DUPLICATE_SAME_ACCESS );
                return адаптВыхУкз(hndl);
            }
        
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Нить
    ////////////////////////////////////////////////////////////////////////////////


    /**
     * В этом классе собрана вся функциональность Динрус, связанная с потоками.
     * Так как управление нитями - важное средство для сборки мусора,
     * все нити пользователя должны происходить от данного класса,
     * а экземпляры данного класса не могут удаляться непосредственно.
     * Новая нить может быть создана либо с использованием деривации, либо композиции,
     * как показано в следующем примере.
     *
     * Пример:
     * -----------------------------------------------------------------------------
     *
     * class ПроизводнаяНить : Нить
     * {
     *     this()
     *     {
     *         super( &пуск );
     *     }
     *
     * private :
     *     проц пуск()
     *     {
     *         скажинс( "Запущена производная нить.\n" );
     *     }
     * }
     *
     * проц функцНити()
     * {
     *     скажинс( "Компонированная нить выполняется.\n" );
     * }
     *
     * // создание экземпляров каждого типа
     * Нить производная = new ПроизводнаяНить();
     * Нить компонированная = new Нить( &функцНити );
     *
     * // старт обеих нитей
     * производная.старт();
     * компонированная.старт();
     *
     * -----------------------------------------------------------------------------
     */
export extern(D) class Нить
    {   



    export  this( проц function() фн, т_мера разм = 0 )
        in
        {
            assert( фн );
        }
        body
        {
            м_фн   = фн;
            м_рр   = разм;
            м_вызов = Вызов.ФН;
            м_тек = &м_глав;
        }


        /**
         * Инициализует объект нити, связанный с динамической функцией
         * Динрус.
         *
         * Параметры:
         *  дг = Функция нити.
         *  разм = Размер стека для этой нити.
         *
         * In:
         *  дг не должно быть null.
         */
    export  this( проц delegate() дг, т_мера разм = 0 )
        in
        {
            assert( дг );
        }
        body
        {
            м_дг   = дг;
            м_рр   = разм;
            м_вызов = Вызов.ДГ;
            м_тек = &м_глав;
        }


        /**
         * Очищает остатки ресурсов, использованных объектом.
         */
    export  ~this()
        {
            if( м_адр == м_адр.init )
            {
                return;
            }

                м_адр = м_адр.init;
                ЗакройДескр( м_дескр );
                м_дескр = м_дескр.init;     
        }


        ////////////////////////////////////////////////////////////////////////////
        // Основные Действия
        ////////////////////////////////////////////////////////////////////////////


        /**
         * Запускает нить и вызывает функцию или делегат,
         * переданный при конструкции.
         *
         * In:
         *  Процедура может вызываться лишь единожды на экземпляр.
         *
         * Throws:
         *  ОшибкаНити, если старт не удаётся.
         */
         
    export  final проц старт()   
        in
        {
            assert( !следщ && !предщ );
        }
        body
        {
            version( Win32 ) {} 

            // NOTE: Эта операция требует синхронизации во избежание
            //       интерференции с СМ. Без данной блокировки нить
            //       может запуститься и разместить память до её добавления
            //       в глобальный список нитей, что сделает её несканируемой,
            //       и вызовет сбор память, которая находится в активном использовании.
            synchronized( slock )
            {
                volatile флагМультипоточности = true;
                
                    м_дескр = cast(ук) начнитьдоп( null, м_рр, &нить_точкаВхода, cast(ук) this, 0, &м_адр );
                    if( cast(т_мера) м_дескр == 0 )
                        throw new ОшибкаНити( "Ошибка при создании нити" );     
                добавь( this );
            }
        
        }


        /**
        * Ждёт завершения данной нити.  If the thread terminated as the
         * результат of an unhandled exception, this exception will be rethrown.
         *
         * Параметры:
         *  повторноБросить = Rethrow any unhandled exception which may have caused this
         *            thread to terminate.
         *
         * Throws:
         *  ОшибкаНити if the operation fails.
         *  Any exception not handled by the joined thread.
         *
         * Returns:
         *  Any exception not handled by this thread if повторноБросить = false, null
         *  otherwise.
         */
    export  final Объект присоедини( бул повторноБросить = true )
        {
            if(!пущена_ли())
                return null;
        
                if( ЖдиОдинОбъект( м_дескр, БЕСК ) != ЖДИ_ОБЪЕКТ_0 )
                    throw new ОшибкаНити( "Не удаётся присоединить нити" );
                // NOTE: м_адр must be cleared before м_дескр is closed to avoid
                //       a race condition with пущена_ли.  The operation is labeled
                //       volatile to prevent compiler reordering.
                volatile м_адр = м_адр.init;
                ЗакройДескр( м_дескр );
                м_дескр = м_дескр.init;
        
            if( м_необработ )
            {
                if( повторноБросить )
                    throw м_необработ;
                return м_необработ;
            }
            return null;
        }


        ////////////////////////////////////////////////////////////////////////////
        // Общие Свойства
        ////////////////////////////////////////////////////////////////////////////


        /**
         * Gets the user-readable label for this thread.
         *
         * Returns:
         *  The имя of this thread.
         */
    export  final ткст имя()
        {
            synchronized( this )
            {
                return м_имя;
            }
        }


        /**
         * Sets the user-readable label for this thread.
         *
         * Параметры:
         *  знач = The new имя of this thread.
         */
        export final проц имя( ткст знач )
        {
            synchronized( this )
            {
                м_имя = знач.dup;
            }
        }


        /**
         * Gets the daemon status for this thread.  While the runtime will жди for
         * all normal threads to complete before tearing down the process, daemon
         * threads are effectively ignored and thus will not prevent the process
         * from terminating.  In effect, daemon threads will be terminated
         * automatically by the OS when the process exits.
         *
         * Returns:
         *  true if this is a daemon thread.
         */
        final бул демон_ли()
        {
            synchronized( this )
            {
                return м_демон;
            }
        }


        /**
         * Sets the daemon status for this thread.  While the runtime will жди for
         * all normal threads to complete before tearing down the process, daemon
         * threads are effectively ignored and thus will not prevent the process
         * from terminating.  In effect, daemon threads will be terminated
         * automatically by the OS when the process exits.
         *
         * Параметры:
         *  знач = The new daemon status for this thread.
         */
    export  final проц демон_ли( бул знач )
        {
            synchronized( this )
            {
                м_демон = знач;
            }
        }


        /**
         * Tests whether this thread is running.
         *
         * Returns:
         *  true if the thread is running, false if not.
         */
    export  final бул пущена_ли()
        {
            if( м_адр == м_адр.init )
            {
                return false;
            }

            
                бцел ecode = 0;
                ДайКодВыходаНити( м_дескр, &ecode );
                return ecode == ЕЩЁ_АКТИВНА;
            
        }

        ////////////////////////////////////////////////////////////////////////////
        // Нить Priority Actions
        ////////////////////////////////////////////////////////////////////////////


        /**
         * The minimum scheduling приоритет that may be set for a thread.  On
         * systems where multiple scheduling policies are defined, this value
         * represents the minimum valid приоритет for the scheduling политика of
         * the process.
         */
        static const цел МИНПРИОР;


        /**
         * The maximum scheduling приоритет that may be set for a thread.  On
         * systems where multiple scheduling policies are defined, this value
         * represents the minimum valid приоритет for the scheduling политика of
         * the process.
         */
        static const цел МАКСПРИОР;


        /**
         *  Выводит планируемый приоритет для связанной с ней нити.
         *
         * Возвращает:
         *  планируемый приоритет для данной нити.
         */
    export  final цел приоритет()
        {           
                return ДайПриоритетНити( м_дескр );         
        }


        /**
         * Устанавливает планируемый приоритет для связанной с ней нити.
         *
         * Параметры:
         *  знач = новый планируемый приоритет для данной нити.
         */
    export  final проц приоритет( цел процент )
        {   
        ППриоритетНити приор;
        
        if(процент == МАКСПРИОР)
            приор = cast(ППриоритетНити) МАКСПРИОР;
        else if(процент == МИНПРИОР)
            приор = cast(ППриоритетНити) МИНПРИОР;
        else if(процент <= 25)
            приор = ППриоритетНити.Мин;
        else if(процент <= 75)
            приор = ППриоритетНити.НижеНормы;
        else if(процент <= 125)
            приор = ППриоритетНити.Норма;
        else if(процент <= 175)
            приор = ППриоритетНити.ВышеНормы;
        else
            приор = ППриоритетНити.Макс;
            
                if( !УстановиПриоритетНити( м_дескр, приор ) )
                    throw new ОшибкаНити( "Не удаётся установить приоритет нити" );     
        }


        ////////////////////////////////////////////////////////////////////////////
        // Действия над Вызывающей Нитью
        ////////////////////////////////////////////////////////////////////////////


        /**
         * Замораживает вызывающую нить на указанное время, вплоть до
         * максимума (бцел.max - 1) миллисекунд.
         *
         * Параметры:
         *  период = Минимальная продолжительность для заморозки вызывающей нити,
         *           в сек.  Промежутки времени менее секунды задаются как
         *           дробные значения
         * Вход:
         *  период должен быть менее (бцел.max - 1) миллисек.
         *
         * Пример:
         * -------------------------------------------------------------------------
         *
         * Нить.спи( 0.05 ); // "спать" 50 миллисек
         * Нить.спи( 5 );    // спать 5 сек
         *
         * -------------------------------------------------------------------------
         */
    export  static проц спи( дво период )
        in
        {
            // NOTE: The fractional value added to период is to correct fp error.
            assert( период * 1000 + 0.1 < бцел.max - 1 );
        }
        body
        {
          Спи( cast(бцел)( период * 1000 + 0.1 ) );
            
        }


        /+
        /**
         * Suspends the calling thread for at least the supplied time, up to a
         * maximum of (бцел.max - 1) milliseconds.
         *
         * Параметры:
         *  период = The minimum duration the calling thread should be suspended.
         *
         * In:
         *  период must be less than (бцел.max - 1) milliseconds.
         *
         * Example:
         * -------------------------------------------------------------------------
         *
         * Нить.спи( TimeSpan.milliseconds( 50 ) ); // спи for 50 milliseconds
         * Нить.спи( TimeSpan.seconds( 5 ) );       // спи for 5 seconds
         *
         * -------------------------------------------------------------------------
         */
        static проц спи( TimeSpan период )
        in
        {
            assert( период.milliseconds < бцел.max - 1 );
        }
        body
        {
            version( Win32 )
            {
                Sleep( cast(бцел)( период.milliseconds ) );
            }
            else version( Posix )
            {
                timespec tin  = void;
                timespec tout = void;

                if( tin.tv_sec.max < период.seconds )
                {
                    tin.tv_sec  = tin.tv_sec.max;
                    tin.tv_nsec = 0;
                }
                else
                {
                    tin.tv_sec  = cast(typeof(tin.tv_sec))  период.seconds;
                    tin.tv_nsec = cast(typeof(tin.tv_nsec)) период.nanoseconds % 1_000_000_000;
                }

                while( true )
                {
                    if( !nanosleep( &tin, &tout ) )
                        return;
                    if( getErrno() != EINTR )
                        throw new ОшибкаНити( "Unable to спи for specified duration" );
                    tin = tout;
                }
            }
        }


        /**
         * Suspends the calling thread for at least the supplied time, up to a
         * maximum of (бцел.max - 1) milliseconds.
         *
         * Параметры:
         *  период = The minimum duration the calling thread should be suspended,
         *           in seconds.  Sub-second durations are specified as fractional
         *           values.  Please note that because период is a floating-point
         *           number, some accuracy may be lost for certain intervals.  For
         *           this reason, the TimeSpan overload is preferred in instances
         *           where an exact interval is required.
         *
         * In:
         *  период must be less than (бцел.max - 1) milliseconds.
         *
         * Example:
         * -------------------------------------------------------------------------
         *
         * Нить.спи( 0.05 ); // спи for 50 milliseconds
         * Нить.спи( 5 );    // спи for 5 seconds
         *
         * -------------------------------------------------------------------------
         */
        static проц спи( дво период )
        {
          спи( TimeSpan.interval( период ) );
        }
        +/


        /**
         * Forces a context switch to occur away from the calling thread.
         */
        export static проц жни()
        {
                // NOTE: Sleep(1) is necessary because Sleep(0) does not give
                //       lower приоритет threads any timeslice, so looping on
                //       Sleep(0) could be resource-intensive in some cases.
                Спи( 1 );
            
        }


        ////////////////////////////////////////////////////////////////////////////
        // Нить Accessors
        ////////////////////////////////////////////////////////////////////////////


        /**
         * Provides a reference to the calling thread.
         *
         * Returns:
         *  The thread Объект representing the calling thread.  The результат of
         *  deleting this Объект is undefined.
         */
    export  static Нить дайЭту()
        {
            // NOTE: This function may not be called until нить_иниц has
            //       completed.  See нить_заморозьВсе for more information
            //       on why this might occur.
            return cast(Нить)адаптВыхУкз(ДайЗначениеНлх( см_эта ));
            
        }


        /**
         * Provides a list of all threads currently being tracked by the system.
         *
         * Returns:
         *  An array containing references to all threads currently being
         *  tracked by the system.  The результат of deleting any contained
         *  OBJECTs is undefined.
         */
    export  static Нить[] дайВсе()
        {
            Нить[] буф;
            while(1){
                if (буф) delete буф;
                буф = new Нить[см_ндлин];
                synchronized( slock )
                {
                    т_мера   pos = 0;
                    if (буф.length < см_ндлин) {
                        continue;
                    } else {
                        буф.length = см_ндлин;
                    }
                    foreach( Нить t; Нить )
                    {
                        буф[pos++] = t;
                    }
                    return буф;
                }
            }
        }


        /**
         * Operates on all threads currently being tracked by the system.  The
         * результат of deleting any Нить Объект is undefined.
         *
         * Параметры:
         *  дг = The supplied code as a delegate.
         *
         * Returns:
         *  Zero if all elemented are visited, nonzero if not.
         */
    export  static цел opApply( цел delegate( ref  Нить ) дг )
        {
            synchronized( slock )
            {
                цел ret = 0;

                for( Нить t = см_ннач; t; t = t.следщ )
                {
                    ret = дг( t );
                    if( ret )
                        break;
                }
                return ret;
            }
        }


        ////////////////////////////////////////////////////////////////////////////
        // Local Storage Actions
        ////////////////////////////////////////////////////////////////////////////


        /**
         * Indicates the number of local storage pointers available at program
         * startup.  It is recommended that this number be at least 64.
         */
        static const бцел МАКСЛОК = 64;


        /**
         * Reserves a local storage pointer for use and initializes this location
         * to null for all running threads.
         *
         * Returns:
         *  A ключ representing the array offset of this memory location.
         */
    export  static бцел создайЛок()
        {
            synchronized( slock )
            {
                foreach( бцел ключ, ref  бул set; см_локал )
                {
                    if( !set )
                    {
                        //foreach( Нить t; см_ннач ) Bug in GDC 0.24 SVN (r139)
                        for( Нить t = см_ннач; t; t = t.следщ )
                        {
                            t.м_локал[ключ] = null;
                        }
                        set = true;
                        return ключ;
                    }
                }
                throw new ОшибкаНити( "Нет свободных локальных ячеек памяти" );
            }
        }


        /**
         * Marks the supplied ключ as available and sets the associated location
         * to null for all running threads.  It is assumed that any ключ passed
         * to this function is valid.  The результат of calling this function for
         * a ключ which is still in use is undefined.
         *
         * Параметры:
         *  ключ = The ключ to delete.
         */
    export  static проц удалиЛок( бцел ключ )
        {
            synchronized( slock )
            {
                см_локал[ключ] = false;
                // foreach( Нить t; см_ннач ) Bug in GDC 0.24 SVN (r139)
                for( Нить t = см_ннач; t; t = t.следщ )
                {
                    t.м_локал[ключ] = null;
                }
            }
        }


        /**
         * Loads the value stored at ключ внутри a thread-local static array.  It is
         * assumed that any ключ passed to this function is valid.
         *
         * Параметры:
         *  ключ = The location which holds the desired data.
         *
         * Returns:
         *  The data associated with the supplied ключ.
         */
    export  static ук дайЛок( бцел ключ )
        {
            return дайЭту().м_локал[ключ];
        }


        /**
         * Stores the supplied value at ключ внутри a thread-local static array.  It
         * is assumed that any ключ passed to this function is valid.
         *
         * Параметры:
         *  ключ = The location to store the supplied data.
         *  знач = The data to store.
         *
         * Returns:
         *  A copy of the data which has just been stored.
         */
    export  static ук устЛок( бцел ключ, ук знач )
        {
            return дайЭту().м_локал[ключ] = знач;
        }


        ////////////////////////////////////////////////////////////////////////////
        // Статический Инициализатор
        ////////////////////////////////////////////////////////////////////////////


        /**
         * Инициализатор для установки констант нити. Вся реальная
         * инициализация происходит внутри нить_иниц().
         */
        static this()
        {
                МИНПРИОР = -15;
                МАКСПРИОР =  15;
        
        }


    
        //
        // Инициализует объек Нить, не связанный ни с какой исполнимой функцией.
        // Используется для главной нити, инициализированной в нить_иниц().
        //
    private this()
        {
            м_вызов = Вызов.НЕТ;
            м_тек = &м_глав;
        }


        //
        // Точка входа в Нить. Вызывает функцию или делегата, переданного при
        // конструкции (если он передан!).
        //
    export  final проц пуск()
        {
            switch( м_вызов )
            {
            case Вызов.ФН:
                м_фн();
                break;
            case Вызов.ДГ:
                м_дг();
                break;
            default:
                break;
            }
        }

    //
        // Тип процедуры, передаваемой при конструкции нити.
        //
        enum Вызов
        {
            НЕТ,
            ФН,
            ДГ
        }


        //
        // Стандартные типы
        //
        
            alias бцел КлючНЛХ;
            alias бцел АдрНити;

        //
        // Локальное хранилище
        //
        static бул[МАКСЛОК]  см_локал;
        static КлючНЛХ           см_эта;

        ук[МАКСЛОК]        м_локал;


        //
        // Стандартные данные нити
        //
        version( Win32 )
        {
            ук          м_дескр;
        }
        public АдрНити          м_адр;
        Вызов                м_вызов;
        ткст              м_имя;
        union
        {
            проц function() м_фн;
            проц delegate() м_дг;
        }
        т_мера              м_рр;
        version( Posix )
        {
            бул            м_пущена;
        }
        бул                м_демон;
        public Объект              м_необработ;


        ////////////////////////////////////////////////////////////////////////////
        // Хранилище Активной Нить
        ////////////////////////////////////////////////////////////////////////////


        //
        // Устанавливает нителокальную ссылку на текущий объект нити.
        //
    export  static проц установиЭту( Нить t )
        {           
                УстановиЗначениеНлх( см_эта, cast(ук) t );      
        }

        ////////////////////////////////////////////////////////////////////////////
        // Контекст нити и поддержка сканирования для СМ
        ////////////////////////////////////////////////////////////////////////////


    export  final проц суньКонтекст( Контекст* c )
        in
        {
            assert( !c.внутри );
        }
        body
        {
            c.внутри = м_тек;
            м_тек = c;
        }


    export  final проц выньКонтекст()
        in
        {
            assert( м_тек && м_тек.внутри );
        }
        body
        {
            Контекст* c = м_тек;
            м_тек = c.внутри;
            c.внутри = null;
        }


    export final Контекст* топКонтекст()
        in
        {
            assert( м_тек );
        }
        body
        {
            return м_тек;
        }


    public static struct Контекст
        {
            ук           нстэк,
                            встэк;
            Контекст*        внутри;
            Контекст*        следщ,
                            предщ;
        }

        Контекст             м_глав;
        Контекст*            м_тек;
        бул                м_блок;

        version( Win32 )
        {
            бцел[8]         м_рег; // edi,esi,ebp,esp,ebx,edx,ecx,eax
        }
        ////////////////////////////////////////////////////////////////////////////
        // Поддержка Сканирования для СМ
        ////////////////////////////////////////////////////////////////////////////


        // NOTE: Процесс сканирования СМ выполняется следщ. обр.:
        //
        //          1. Заморозка всех нитей.
        //          2. Сканирование стеков всех замороженных нитей на наличие корней.
        //          3. Разморозка всех нитей.
        //
        //       Шаги 1 и 3 требуют списка всех нитей системы, а
        //       для шага 2 нужен список всех стеков нитей (каждый представляется структурой
        //       Контекст).  Традиционно был 1 стек на каждую нить,
        //       и структуры Контекст не требовались.  Однако, Фибры изменили положение
        //       вещей, теперь у каждой нити есть собственный 'главный' стек плюс
        //       произвольное число внедрённых стеков (обычно указываемых через
        //       м_тек).  Также в системе м.б. 'свободно-плавающие' стеки,
        //       т.е. Фибры, в данный момент не выполняемые на какой ни-ть нити,
        //       но всё ещё обрабатываемые и содержащие рабочие корни.
        //
        //       To support all of this, the Контекст struct has been created to
        //       represent a stack range, and a global list of Контекст structs has
        //       been added to enable scanning of these stack ranges.  The lifetime
        //       (and presence in the Контекст list) of a thread's 'main' stack will
        //       be equivalent to the thread's lifetime.  So the Ccontext will be
        //       added to the list on thread entry, and removed from the list on
        //       thread exit (which is essentially the same as the presence of a
        //       Нить Объект in its own global list).  The lifetime of a Фибра's
        //       context, however, will be tied to the lifetime of the Фибра Объект
        //       itself, and Fibers are expected to добавь/удали their Контекст struct
        //       on construction/deletion.


        //
        // All use of the global lists should synchronize on this блокируй.
        //
    export  static Объект slock()
        {
            return Нить.classinfo;
        }


        static Контекст*     см_кнач;
        static т_мера       см_кдлин;

        static Нить       см_ннач;
        static т_мера       см_ндлин;

        //
        // Используется для упорядочивания нитей в глобальном списке.
        //
        Нить              предщ;
        Нить              следщ;


        ////////////////////////////////////////////////////////////////////////////
        // Global Контекст List Operations
        ////////////////////////////////////////////////////////////////////////////


        //
        // Add a context to the global context list.
        //
    export  static проц добавь( Контекст* c )
        in
        {
            assert( c );
            assert( !c.следщ && !c.предщ );
        }
        body
        {
            synchronized( slock )
            {
                if( см_кнач )
                {
                    c.следщ = см_кнач;
                    см_кнач.предщ = c;
                }
                см_кнач = c;
                ++см_кдлин;
            }
        }


        //
        // Remove a context from the global context list.
        //
    export  static проц удали( Контекст* c )
        in
        {
            assert( c );
            assert( c.следщ || c.предщ );
        }
        body
        {
            synchronized( slock )
            {
                if( c.предщ )
                    c.предщ.следщ = c.следщ;
                if( c.следщ )
                    c.следщ.предщ = c.предщ;
                if( см_кнач == c )
                    см_кнач = c.следщ;
                --см_кдлин;
            }
            // NOTE: Don't null out c.следщ or c.предщ because opApply currently
            //       follows c.следщ after removing a node.  This could be easily
            //       addressed by simply returning the следщ node from this function,
            //       however, a context should never be re-added to the list anyway
            //       and having следщ and предщ be non-null is a good way to
            //       ensure that.
        }


        ////////////////////////////////////////////////////////////////////////////
        // Операции с Глобальным Списком Нитей
        ////////////////////////////////////////////////////////////////////////////


        //
        // Добавить нить в глобальный список нитей.
        //
        export static проц добавь( Нить t )
        in
        {
            assert( t );
            assert( !t.следщ && !t.предщ );
            assert( t.пущена_ли );
        }
        body
        {
            synchronized( slock )
            {
                if( см_ннач )
                {
                    t.следщ = см_ннач;
                    см_ннач.предщ = t;
                }
                см_ннач = t;
                ++см_ндлин;
            }
        }


        //
        // Удалить нить из списка.
        //
        export static проц удали( Нить t )
        in
        {
            assert( t );
            assert( t.следщ || t.предщ );
        }
        body
        {
            synchronized( slock )
            {
                // NOTE: When a thread is removed from the global thread list its
                //       main context is invalid and should be removed as well.
                //       It is possible that t.м_тек could reference more
                //       than just the main context if the thread exited abnormally
                //       (if it was terminated), but we must assume that the user
                //       retains a reference to them and that they may be re-used
                //       elsewhere.  Therefore, it is the responsibility of any
                //       Объект that creates contexts to clean them up properly
                //       when it is done with them.
                удали( &t.м_глав );

                if( t.предщ )
                    t.предщ.следщ = t.следщ;
                if( t.следщ )
                    t.следщ.предщ = t.предщ;
                if( см_ннач == t )
                    см_ннач = t.следщ;
                --см_ндлин;
            }
            // NOTE: Don't null out t.следщ or t.предщ because opApply currently
            //       follows t.следщ after removing a node.  This could be easily
            //       addressed by simply returning the следщ node from this function,
            //       however, a thread should never be re-added to the list anyway
            //       and having следщ and предщ be non-null is a good way to
            //       ensure that.
        }
    }


    ////////////////////////////////////////////////////////////////////////////////
    // GC Support Routines
    ////////////////////////////////////////////////////////////////////////////////


    /**
     * Initializes the thread module.  This function must be called by the
     * garbage collector on startup and before any other thread routines
     * are called.
     */
    export extern (C) проц нить_иниц()
    {
        // NOTE: If нить_иниц itself performs any allocations then the thread
        //       routines reserved for garbage collector use may be called while
        //       нить_иниц is being processed.  However, since no memory should
        //       exist to be scanned at this point, it is sufficient for these
        //       functions to detect the condition and return immediately.
            //скажинс("Начало инициализации нити");
        
            Нить.см_эта = РазместиНлх();
            //скажинс("Начало инициализации нити2");
            assert( Нить.см_эта != ПОшибка.НЛХВнеИндексов );
            //скажинс("Начало инициализации нити3");
            Фибра.см_эта = РазместиНлх();
            //скажинс("Начало инициализации нити4");
            assert( Нить.см_эта != ПОшибка.НЛХВнеИндексов );
            //скажинс("Начало инициализации нити5");

        нить_прикрепиЭту();
        //скажинс("Выход из нициализации нити");
    }


    /**
     * Registers the calling thread for use with Tango.  If this routine is called
     * for a thread which is already registered, the результат is undefined.
     */
    export extern (C) проц нить_прикрепиЭту()
    {
        //скажинс("Начало прикрепления нити");
        
            Нить          этаНить  = new Нить();
            //скажинс("Создан класс нити");
            Нить.Контекст* этотКонтекст = &этаНить.м_глав;
            assert( этотКонтекст == этаНить.м_тек );

            этаНить.м_адр  = ДайИдТекущейНити();
            этаНить.м_дескр  = ДайДескрТекущейНити();
            этотКонтекст.нстэк = ртНизСтэка();
            этотКонтекст.встэк = этотКонтекст.нстэк;

            этаНить.м_демон = true;

            Нить.установиЭту( этаНить );
        

        Нить.добавь( этаНить );
        Нить.добавь( этотКонтекст );
    }

    /**
     * Deregisters the calling thread from use with Tango.  If this routine is
     * called for a thread which is already registered, the результат is undefined.
     */
    export extern (C) проц нить_открепиЭту()
    {
        Нить.удали( Нить.дайЭту() );
    }

    /**
     * Joins all non-daemon threads that are currently running.  This is done by
     * performing successive scans through the thread list until a scan consists
     * of only daemon threads.
     */
    export extern (C) проц нить_объединиВсе()
    {

        while( true )
        {
            Нить неДемон = null;

            foreach( t; Нить )
            {
                if( !t.демон_ли )
                {
                    неДемон = t;
                    break;
                }
            }
            if( неДемон is null )
                return;
            неДемон.присоедини();
        }
    }


    /**
     * Performs intermediate shutdown of the thread module.
     */
    static ~this()
    {
        // NOTE: The functionality related to garbage collection must be minimally
        //       operable after this dtor completes.  Therefore, only minimal
        //       cleanup may occur.

        for( Нить t = Нить.см_ннач; t; t = t.следщ )
        {
            if( !t.пущена_ли )
                Нить.удали( t );
        }
    }


    // Used for needLock below
    private бул флагМультипоточности = true;


    /**
     * This function is used to determine whether the the process is
     * multi-threaded.  Optimizations may only be performed on this
     * value if the programmer can guarantee that no path from the
     * enclosed code will старт a thread.
     *
     * Returns:
     *  True if Нить.старт() has been called in this process.
     */
    export extern (C) бул нить_нужнаБлокировка()
    {
        return флагМультипоточности;
    }


    // Used for suspendAll/разморозьAll below
    private бцел suspendDepth = 0;

    /**
     * Suspend all threads but the calling thread for "stop the world" garbage
     * collection runs.  This function may be called multiple times, and must
     * be followed by a matching number of calls to нить_разморозьВсе before
     * processing is разморозьd.
     *
     * Throws:
     *  ОшибкаНити if the заморозь operation fails for a running thread.
     */
    export extern (C) проц нить_заморозьВсе()
    {
        цел suspendedCount=0;
        /**
         * Suspend the specified thread and load stack and register information for
         * use by нить_сканируйВсе.  If the supplied thread is the calling thread,
         * stack and register information will be loaded but the thread will not
         * be suspended.  If the заморозь operation fails and the thread is not
         * running then it will be removed from the global thread list, otherwise
         * an exception will be thrown.
         *
         * Параметры:
         *  t = The thread to заморозь.
         *
         * Throws:
         *  ОшибкаНити if the заморозь operation fails for a running thread.
         */
        проц заморозь( Нить t )
        {
            version( Win32 )
            {
                if( t.м_адр != ДайИдТекущейНити() && ЗаморозьНить( t.м_дескр ) == 0xFFFFFFFF )
                {
                    if( !t.пущена_ли )
                    {
                        Нить.удали( t );
                        return;
                    }
                    throw new ОшибкаНити( "Не удаётся заморозить нить" );
                }

                КОНТЕКСТ context = void;
                context.ФлагиКонтекста = ПКонтекст.Целое | ПКонтекст.Упр;

                if( !ДайКонтекстНити( t.м_дескр, &context ) )
                    throw new ОшибкаНити( "Не удаётся загрузить контекст нити" );
                if( !t.м_блок )
                    t.м_тек.встэк = cast(ук) context.Esp;
                // edi,esi,ebp,esp,ebx,edx,ecx,eax
                t.м_рег[0] = context.Edi;
                t.м_рег[1] = context.Esi;
                t.м_рег[2] = context.Ebp;
                t.м_рег[3] = context.Esp;
                t.м_рег[4] = context.Ebx;
                t.м_рег[5] = context.Edx;
                t.м_рег[6] = context.Ecx;
                t.м_рег[7] = context.Eax;
            }
            else version( Posix )
            {
                if( t.м_адр != эта_нить() )
                {
                    if( pthread_kill( t.м_адр, SIGUSR1 ) != 0 )
                    {
                        if( !t.пущена_ли )
                        {
                            Нить.удали( t );
                            return;
                        }
                        throw new ОшибкаНити( "Не удаётся заморозить нить" );
                    }
                    version (AtomicSuspendCount){
                        ++suspendedCount;
                        version(AtomicSuspendCount){
                            version(SuspendOneAtTime){ // when debugging suspending all threads at once might give "lost" signals
                                цел icycle=0;
                                suspendLoop: while (флагДай(suspendCount)!=suspendedCount){
                                    for (т_мера i=1000;i!=0;--i){
                                        if (флагДай(suspendCount)==suspendedCount) break suspendLoop;
                                        if (++icycle==100_000){
                                            debug(Нить)
                                                скажинс(фм("ожидалась на %d циклов заморозка нити,  suspendCount=%d, вместо %d\nАтомные операции не работают?\nПродолжается ожидание...\n",icycle,suspendCount,suspendedCount));
                                        }
                                        Нить.жни();
                                    }
                                    Нить.спи(0.0001);
                                }
                            }
                        }
                        
                    } else {
                        sem_wait( &suspendCount );
                        // shouldn't the return be checked and maybe a loop added for further interrupts
                        // as in Семафор.d ?
                    }
                }
                else if( !t.м_блок )
                {
                    t.м_тек.встэк = ртВерхСтэка();
                }
            }
        }


        // NOTE: We've got an odd chicken & egg problem here, because while the GC
        //       is required to call нить_иниц before calling any other thread
        //       routines, нить_иниц may allocate memory which could in turn
        //       trigger a collection.  Thus, нить_заморозьВсе, нить_сканируйВсе,
        //       and нить_разморозьВсе must be callable before нить_иниц completes,
        //       with the assumption that no other GC memory has yet been allocated
        //       by the system, and thus there is no risk of losing data if the
        //       global thread list is empty.  The check of Нить.см_ннач
        //       below is done to ensure нить_иниц has completed, and therefore
        //       that calling Нить.дайЭту will not результат in an error.  For the
        //       short time when Нить.см_ннач is null, there is no reason
        //       not to simply call the multithreaded code below, with the
        //       expectation that the foreach loop will never be entered.
        if( !флагМультипоточности && Нить.см_ннач )
        {
            if( ++suspendDepth == 1 ) {
                заморозь( Нить.дайЭту() );
            }
            return;
        }
        _d_monitorenter(Нить.slock);
        {
            if( ++suspendDepth > 1 )
                return;
            // NOTE: I'd really prefer not to check пущена_ли внутри this loop but
            //       not doing so could be problematic if threads are termianted
            //       abnormally and a new thread is created with the same thread
            //       address before the следщ GC пуск.  This situation might cause
            //       the same thread to be suspended twice, which would likely
            //       cause the second заморозь to fail, the garbage collection to
            //       abort, and Bad Things to occur.
            for( Нить t = Нить.см_ннач; t; t = t.следщ )
            {
                if( t.пущена_ли ){
                    заморозь( t );
                } else
                    Нить.удали( t );
            }

            version( Posix )
            {
                version(AtomicSuspendCount){
                    цел icycle=0;
                    suspendLoop2: while (флагДай(suspendCount)!=suspendedCount){
                        for (т_мера i=1000;i!=0;--i){
                            if (флагДай(suspendCount)==suspendedCount) break suspendLoop2;
                            if (++icycle==1000_000){
                                debug(Нить)
                                    скажинс(фм("ожидалась на %d циклов заморозка нити,  suspendCount=%d, вместо %d\nАтомные операции не работают?\nПродолжается ожидание...\n",icycle,suspendCount,suspendedCount));
                            }
                            Нить.жни();
                        }
                        Нить.спи(0.0001);
                    }
                }
            }
        }
    }


    /**
     * Resume all threads but the calling thread for "stop the world" garbage
     * collection runs.  This function must be called once for each preceding
     * call to нить_заморозьВсе before the threads are actually разморозьd.
     *
     * In:
     *  This routine must be preceded by a call to нить_заморозьВсе.
     *
     * Throws:
     *  ОшибкаНити if the разморозь operation fails for a running thread.
     */
    export extern (C) проц нить_разморозьВсе()
    in
    {
        assert( suspendDepth > 0 );
    }
    body
    {
        version(AtomicSuspendCount) version(SuspendOneAtTime) auto suspendedCount=флагДай(suspendCount);
        /**
         * Resume the specified thread and unload stack and register information.
         * If the supplied thread is the calling thread, stack and register
         * information will be unloaded but the thread will not be разморозьd.  If
         * the разморозь operation fails and the thread is not running then it will
         * be removed from the global thread list, otherwise an exception will be
         * thrown.
         *
         * Параметры:
         *  t = The thread to разморозь.
         *
         * Throws:
         *  ОшибкаНити if the разморозь fails for a running thread.
         */
        проц разморозь( Нить t )
        {
            version( Win32 )
            {
                if( t.м_адр != ДайИдТекущейНити() && РазморозьНить( t.м_дескр ) == 0xFFFFFFFF )
                {
                    if( !t.пущена_ли )
                    {
                        Нить.удали( t );
                        return;
                    }
                    throw new ОшибкаНити( "Не удалось разморозить нить" );
                }

                if( !t.м_блок )
                    t.м_тек.встэк = t.м_тек.нстэк;
                t.м_рег[0 .. $] = 0;
            }
            else version( Posix )
            {
                if( t.м_адр != эта_нить() )
                {
                    if( pthread_kill( t.м_адр, SIGUSR2 ) != 0 )
                    {
                        if( !t.пущена_ли )
                        {
                            Нить.удали( t );
                            return;
                        }
                        throw new ОшибкаНити( "Не удаётся разморозить нить" );
                    }
                    version (AtomicSuspendCount){
                        version(SuspendOneAtTime){ // when debugging suspending all threads at once might give "lost" signals
                            --suspendedCount;
                            цел icycle=0;
                            recoverLoop: while(флагДай(suspendCount)>suspendedCount){
                                for (т_мера i=1000;i!=0;--i){
                                    if (флагДай(suspendCount)==suspendedCount) break recoverLoop;
                                    if (++icycle==100_000){
                                        debug(Нить)
                                            скажинс(фм("ожидалось %d циклов до восстановления нити,  suspendCount=%d, но должно бы быть %d\nАтомные операции не работают?\nПродолжается ожидание...\n",icycle,suspendCount,suspendedCount));
                                    }
                                    Нить.жни();
                                }
                                Нить.спи(0.0001);
                            }
                        }
                    } else {
                        sem_wait( &suspendCount );
                        // shouldn't the return be checked and maybe a loop added for further interrupts
                        // as in Семафор.d ?
                    }
                }
                else if( !t.м_блок )
                {
                    t.м_тек.встэк = t.м_тек.нстэк;
                }
            }
        }


        // NOTE: See нить_заморозьВсе for the logic behind this.
        if( !флагМультипоточности && Нить.см_ннач )
        {
            if( --suspendDepth == 0 )
                разморозь( Нить.дайЭту() );
            return;
        }

        {
            scope(exit) _d_monitorexit(Нить.slock);
            if( --suspendDepth > 0 )
                return;
            {
                for( Нить t = Нить.см_ннач; t; t = t.следщ )
                {
                    разморозь( t );
                }
                version(AtomicSuspendCount){
                    цел icycle=0;
                    recoverLoop2: while(флагДай(suspendCount)>0){
                        for (т_мера i=1000;i!=0;--i){
                            Нить.жни();
                            if (флагДай(suspendCount)==0) break recoverLoop2;
                            if (++icycle==100_000){
                                debug(Нить)
                                    эхо("waited %d cycles for thread recovery,  suspendCount=%d, should be %d\nAtomic ops do not work?\nContinuing жди...\n",icycle,suspendCount,0);
                            }
                        }
                        Нить.спи(0.0001);
                    }
                }
            }
        }
    }

    private alias проц delegate( ук, ук ) фнСканВсеНити;


    /**
     * The main entry point for garbage collection.  The supplied delegate
     * will be passed ranges representing both stack and register values.
     *
     * Параметры:
     *  scan        = The scanner function.  It should scan from p1 through p2 - 1.
     *  текВерхСтека = An optional pointer to the top of the calling thread's stack.
     *
     * In:
     *  This routine must be preceded by a call to нить_заморозьВсе.
     */
    export extern (C) проц нить_сканируйВсе( фнСканВсеНити scan, ук текВерхСтека = null )
    in
    {
        assert( suspendDepth > 0 );
    }
    body
    {
    debug(НА_КОНСОЛЬ) эхо(" нить_сканируйВсе\n");
        Нить  этаНить  = null;
        ук   прежднВерхСтека = null;

        if( текВерхСтека && Нить.см_ннач )
        {
            этаНить  = Нить.дайЭту();
            if( этаНить && (!этаНить.м_блок) )
            {
                прежднВерхСтека = этаНить.м_тек.встэк;
                этаНить.м_тек.встэк = текВерхСтека;
            }
        }

        scope( exit )
        {
            if( текВерхСтека && Нить.см_ннач )
            {
                if( этаНить && (!этаНить.м_блок) )
                {
                    этаНить.м_тек.встэк = прежднВерхСтека;
                }
            }
        }

        // NOTE: Synchronizing on Нить.slock is not needed because this
        //       function may only be called after all other threads have
        //       been suspended from внутри the same блокируй.
        for( Нить.Контекст* c = Нить.см_кнач; c; c = c.следщ )
        {
            version( СТЭК_РАСТЁТ_ВНИЗ )
            {
                // NOTE: We can't index past the bottom of the stack
                //       so don't do the "+1" for СТЭК_РАСТЁТ_ВНИЗ.
                if( c.встэк && c.встэк < c.нстэк )
                    scan( c.встэк, c.нстэк );
            }
            else
            {
                if( c.нстэк && c.нстэк < c.встэк )
                    scan( c.нстэк, c.встэк + 1 );
            }
        }
        version( Win32 )
        {
            for( Нить t = Нить.см_ннач; t; t = t.следщ )
            {
                scan( &t.м_рег[0], &t.м_рег[0] + t.м_рег.length );
            }
        }
    }


    ////////////////////////////////////////////////////////////////////////////////
    // Нить Local
    ////////////////////////////////////////////////////////////////////////////////


    /**
     * This class encapsulates the operations required to initialize, access, and
     * destroy thread local data.
     */
    class НитьЛок( T )
    {

        ////////////////////////////////////////////////////////////////////////////
        // Initialization
        ////////////////////////////////////////////////////////////////////////////


        /**
         * Initializes thread local storage for the indicated value which will be
         * initialized to def for all threads.
         *
         * Параметры:
         *  def = The default value to return if no value has been explicitly set.
         */
        this( T def = T.init )
        {
            м_деф = def;
            м_ключ = Нить.создайЛок();
        }


        ~this()
        {
            Нить.удалиЛок( м_ключ );
        }


        ////////////////////////////////////////////////////////////////////////////
        // Accessors
        ////////////////////////////////////////////////////////////////////////////


        /**
         * Gets the value last set by the calling thread, or def if no such value
         * has been set.
         *
         * Returns:
         *  The stored value or def if no value is stored.
         */
        T знач()
        {
            Обёртка* wrap = cast(Обёртка*) Нить.дайЛок( м_ключ );

            return wrap ? wrap.знач : м_деф;
        }


        /**
         * Copies newval to a location specific to the calling thread, and returns
         * newval.
         *
         * Параметры:
         *  newval = The value to set.
         *
         * Returns:
         *  The value passed to this function.
         */
        T знач( T newval )
        {
            Обёртка* wrap = cast(Обёртка*) Нить.дайЛок( м_ключ );

            if( wrap is null )
            {
                wrap = new Обёртка;
                Нить.устЛок( м_ключ, wrap );
            }
            wrap.знач = newval;
            return newval;
        }


    private:
        //
        // A wrapper for the stored data.  This is needed for determining whether
        // set has ever been called for this thread (and therefore whether the
        // default value should be returned) and also to flatten the differences
        // between data that is smaller and lаргer than (ук).sizeof.  The
        // obvious tradeoff here is an extra per-thread allocation for each
        // НитьЛок value as compared to calling the Нить routines directly.
        //
        struct Обёртка
        {
            T   знач;
        }


        T       м_деф;
        бцел    м_ключ;
    }


    ////////////////////////////////////////////////////////////////////////////////
    // Нить Group
    ////////////////////////////////////////////////////////////////////////////////


    /**
     * This class is intended to simplify certain common programming techniques.
     */
export extern (D)   class ГруппаНитей
    {
    export:
        /**
         * Creates and starts a new Нить Объект that executes фн and adds it to
         * the list of tracked threads.
         *
         * Параметры:
         *  фн = The thread function.
         *
         * Returns:
         *  A reference to the newly created thread.
         */
        final Нить создай( проц function() фн )
        {
            Нить t = new Нить( фн );

            t.старт();
            synchronized( this )
            {
                м_все[t] = t;
            }
            return t;
        }


        /**
         * Creates and starts a new Нить Объект that executes дг and adds it to
         * the list of tracked threads.
         *
         * Параметры:
         *  дг = The thread function.
         *
         * Returns:
         *  A reference to the newly created thread.
         */
        final Нить создай( проц delegate() дг )
        {
            Нить t = new Нить( дг );

            t.старт();
            synchronized( this )
            {
                м_все[t] = t;
            }
            return t;
        }


        /**
         * Add t to the list of tracked threads if it is not already being tracked.
         *
         * Параметры:
         *  t = The thread to добавь.
         *
         * In:
         *  t must not be null.
         */
        final проц добавь( Нить t )
        in
        {
            assert( t );
        }
        body
        {
            synchronized( this )
            {
                м_все[t] = t;
            }
        }


        /**
         * Removes t from the list of tracked threads.  No operation will be
         * performed if t is not currently being tracked by this Объект.
         *
         * Параметры:
         *  t = The thread to удали.
         *
         * In:
         *  t must not be null.
         */
        final проц удали( Нить t )
        in
        {
            assert( t );
        }
        body
        {
            synchronized( this )
            {
                м_все.remove( t );
            }
        }


        /**
         * Operates on all threads currently tracked by this Объект.
         */
        final цел opApply( цел delegate( ref  Нить ) дг )
        {
            synchronized( this )
            {
                цел ret = 0;

                // NOTE: This loop relies on the knowledge that м_все uses the
                //       Нить Объект for both the ключ and the mapped value.
                foreach( Нить t; м_все.keys )
                {
                    ret = дг( t );
                    if( ret )
                        break;
                }
                return ret;
            }
        }


        /**
         * Iteratively joins all tracked threads.  This function will block добавь,
         * удали, and opApply until it completes.
         *
         * Параметры:
         *  повторноБросить = Rethrow any unhandled exception which may have caused the
         *            current thread to terminate.
         *
         * Throws:
         *  Any exception not handled by the joined threads.
         */
        final проц объединиВсе( бул повторноБросить = true )
        {
            synchronized( this )
            {
                // NOTE: This loop relies on the knowledge that м_все uses the
                //       Нить Объект for both the ключ and the mapped value.
                foreach( Нить t; м_все.keys )
                {
                    t.присоедини( повторноБросить );
                }
            }
        }


    private:
        Нить[Нить]  м_все;
    }


    ////////////////////////////////////////////////////////////////////////////////
    // Фибра Platform Detection and Memory Allocation
    ////////////////////////////////////////////////////////////////////////////////
    version( D_InlineAsm_X86 )
        {
            version( X86_64 )
            {
                // Shouldn't an x64 compiler be setting D_InlineAsm_X86_64 instead?
            }
            else
            {
                version( Win32 )
                    version = AsmX86_Win32;
                else version( Posix )
                    version = AsmX86_Posix;
            }
        }
        else version( D_InlineAsm_X86_64 )
        {
            version( Posix )
                version = AsmX86_64_Posix;
        }
        else version( PPC )
        {
            version( Posix )
                version = AsmPPC_Posix;
        }

        version( Posix )
        {
            import rt.core.os.posix.unistd;   // for sysconf
            import rt.core.os.posix.sys.mman; // for mmap
            import rt.core.os.posix.stdlib;   // for malloc, valloc, free

            version( AsmX86_Win32 ) {} else
            version( AsmX86_Posix ) {} else
            version( AsmX86_64_Posix ) {} else
            version( AsmPPC_Posix ) {} else
            {
                // NOTE: The ucontext implementation requires architecture specific
                //       data definitions to operate so testing for it must be done
                //       by checking for the existence of ucontext_t rather than by
                //       a version identifier.  Please note that this is considered
                //       an obsolescent feature according to the POSIX spec, so a
                //       custom solution is still preferred.
                import rt.core.os.posix.ucontext;
                static assert( is( ucontext_t ), "Unknown fiber implementation");
            }
        }
        
    const т_мера РАЗМЕР_СТРАНИЦЫ;

        

    private static this()
    {
        static if( is( typeof( GetSystemInfo ) ) )
        {
            SYSTEM_INFO info;
            GetSystemInfo( &info );

            РАЗМЕР_СТРАНИЦЫ = info.dwPageSize;
            assert( РАЗМЕР_СТРАНИЦЫ < цел.max );
        }
        else static if( is( typeof( sysconf ) ) &&
                        is( typeof( _SC_PAGESIZE ) ) )
        {
            РАЗМЕР_СТРАНИЦЫ = cast(т_мера) sysconf( _SC_PAGESIZE );
            assert( РАЗМЕР_СТРАНИЦЫ < цел.max );
        }
        else
        {
            version( PPC )
                РАЗМЕР_СТРАНИЦЫ = 8192;
            else
                РАЗМЕР_СТРАНИЦЫ = 4096;
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // Фибра Entry Point and Контекст Switch
    ////////////////////////////////////////////////////////////////////////////////



    export extern (C) проц фибра_точкаВхода()
        {
            Фибра   объ = Фибра.дайЭту();
            assert( объ );

            assert( Нить.дайЭту().м_тек is объ.м_кткст );
            volatile Нить.дайЭту().м_блок = false;
            объ.м_кткст.встэк = объ.м_кткст.нстэк;
            объ.м_состояние = Фибра.Состояние.ВЫП;

            try
            {
                объ.пуск();
            }
            catch( Объект o )
            {
                объ.м_необработ = o;
            }

            static if( is( ucontext_t ) )
              объ.m_ucur = &объ.m_utxt;

            объ.м_состояние = Фибра.Состояние.ТЕРМ;
            объ.отключись();
        }


      // NOTE: If AsmPPC_Posix is defined then the context switch routine will
      //       be defined externally until GDC supports inline PPC ASM.
      version( AsmPPC_Posix )
        extern (C) проц фибра_переклКонтекст( ук* oldp, ук newp );
      else
        export extern (C) проц фибра_переклКонтекст( ук* oldp, ук newp )
        {
            // NOTE: The data pushed and popped in this routine must match the
            //       default stack created by Фибра.инициализуйСтэк or the initial
            //       switch into a new context will fail.

            version( AsmX86_Win32 )
            {
                asm
                {
                    naked;

                    // save current stack состояние
                    push EBP;
                    mov  EBP, ESP;
                    push EAX;
                    push dword ptr FS:[0];
                    push dword ptr FS:[4];
                    push dword ptr FS:[8];
                    push EBX;
                    push ESI;
                    push EDI;

                    // store oldp again with more accurate address
                    mov EAX, dword ptr 8[EBP];
                    mov [EAX], ESP;
                    // load newp to begin context switch
                    mov ESP, dword ptr 12[EBP];

                    // load saved состояние from new stack
                    pop EDI;
                    pop ESI;
                    pop EBX;
                    pop dword ptr FS:[8];
                    pop dword ptr FS:[4];
                    pop dword ptr FS:[0];
                    pop EAX;
                    pop EBP;

                    // 'return' to complete switch
                    ret;
                }
            }
            else version( AsmX86_Posix )
            {
                asm
                {
                    naked;

                    // save current stack состояние
                    push EBP;
                    mov  EBP, ESP;
                    push EAX;
                    push EBX;
                    push ECX;
                    push ESI;
                    push EDI;

                    // store oldp again with more accurate address
                    mov EAX, dword ptr 8[EBP];
                    mov [EAX], ESP;
                    // load newp to begin context switch
                    mov ESP, dword ptr 12[EBP];

                    // load saved состояние from new stack
                    pop EDI;
                    pop ESI;
                    pop ECX;
                    pop EBX;
                    pop EAX;
                    pop EBP;

                    // 'return' to complete switch
                    ret;
                }
            }
            else version( AsmX86_64_Posix )
            {
                asm
                {
                    naked;

                    // save current stack состояние
                    pushq RBP;
                    mov RBP, RSP;
                    pushq RBX;
                    pushq R12;
                    pushq R13;
                    pushq R14;
                    pushq R15;
                    sub RSP, 4;
                    stmxcsr [RSP];
                    sub RSP, 4;
                    //version(SynchroFloatExcept){
                        fstcw [RSP];
                        fwait;
                    //} else {
                    //    fnstcw [RSP];
                    //    fnclex;
                    //}

                    // store oldp again with more accurate address
                    mov [RDI], RSP;
                    // load newp to begin context switch
                    mov RSP, RSI;

                    // load saved состояние from new stack
                    fldcw [RSP];
                    добавь RSP, 4;
                    ldmxcsr [RSP];
                    добавь RSP, 4;
                    popq R15;
                    popq R14;
                    popq R13;
                    popq R12;

                    popq RBX;
                    popq RBP;

                    // 'return' to complete switch
                    ret;
                }
            }
            else static if( is( ucontext_t ) )
            {
                Фибра   cfib = Фибра.дайЭту();
                ук   ucur = cfib.m_ucur;

                *oldp = &ucur;
                swapcontext( **(cast(ucontext_t***) oldp),
                              *(cast(ucontext_t**)  newp) );
            }
        }
    


    ////////////////////////////////////////////////////////////////////////////////
    // Фибра
    ////////////////////////////////////////////////////////////////////////////////

    private ткст ptrToStr(т_мера addr,ткст буф){
        ткст digits="0123456789ABCDEF";
        enum{ nDigits=т_мера.sizeof*2 }
        if (nDigits>буф.length) assert(0);
        ткст res=буф[0..nDigits];
        т_мера addrAtt=addr;
        for (цел i=nDigits;i!=0;--i){
            res[i-1]=digits[addrAtt&0xF];
            addrAtt>>=4;
        }
        return res;
    }

    /**
     * This class provides a cooperative concurrency mechanism integrated with the
     * threading and garbage collection functionality.  Calling a fiber may be
     * considered a blocking operation that returns when the fiber yields (via
     * Фибра.жни()).  Execution occurs внутри the context of the calling thread
     * so synchronization is not necessary to guarantee memory visibility so дол
     * as the same thread calls the fiber each time.  Please note that there is no
     * requirement that a fiber be bound to one specific thread.  Rather, fibers
     * may be freely passed between threads so дол as they are not currently
     * executing.  Like threads, a new fiber thread may be created using either
     * derivation or composition, as in the following example.
     *
     * Example:
     * ----------------------------------------------------------------------
     *
     * class DerivedFiber : Фибра
     * {
     *     this()
     *     {
     *         super( &пуск );
     *     }
     *
     * private :
     *     проц пуск()
     *     {
     *         эхо( "Derived fiber running.\n" );
     *     }
     * }
     *
     * проц fiberFunc()
     * {
     *     эхо( "Composed fiber running.\n" );
     *     Фибра.жни();
     *     эхо( "Composed fiber running.\n" );
     * }
     *
     * // создай instances of each type
     * Фибра derived = new DerivedFiber();
     * Фибра composed = new Фибра( &fiberFunc );
     *
     * // call both fibers once
     * derived.call();
     * composed.call();
     * эхо( "Execution returned to calling context.\n" );
     * composed.call();
     *
     * // since each fiber has пуск to completion, each should have состояние ТЕРМ
     * assert( derived.состояние == Фибра.Состояние.ТЕРМ );
     * assert( composed.состояние == Фибра.Состояние.ТЕРМ );
     *
     * ----------------------------------------------------------------------
     *
     * Authors: Based on a design by Mikola Lysenko.
     */

export extern (D) class Фибра
    {
    
            
        //
        // Фибра entry point.  Invokes the function or delegate passed on
        // construction (if any).
        //
    export  final проц пуск()
        {
            switch( м_вызов )
            {
            case Вызов.ФН:
                м_фн();
                break;
            case Вызов.ДГ:
                м_дг();
                break;
            default:
                break;
            }
        }

    export  static class Планировщик
        {
        export:
        
            alias ук Дескр;

            enum Тип {Чтение=1, Запись=2, Приём=3, Подключение=4, Трансфер=5}

        export  проц пауза (бцел ms) {}

        export  проц готов (Фибра fiber) {}

        export  проц открой (Дескр fd, ткст имя) {}

        export  проц закрой (Дескр fd, ткст имя) {}

        export  проц ожидай (Дескр fd, Тип t, бцел timeout) {}
            
        export  проц ответви (ткст имя, проц delegate() дг, т_мера stack=8192) {}    
        }

        struct Событие                        // планировщик support 
        {  
            бцел             инд;           // support for timer removal
            Фибра            следщ;          // linked list of elapsed fibers
            ук            данные;          // данные to exchange
            бдол            время;         // request timeout duration
            Планировщик.Дескр хэндл;        // IO request хэндл
            Планировщик        планировщик;     // associated планировщик (may be null)
        }
    /+
        final override цел opCmp (Объект o)
        {   
            throw new Exception ("Invalid opCmp in Фибра");

            auto other = cast(Фибра) cast(ук) o;
            if (other)
               {
               auto x = cast(дол) событие.время - cast(дол) other.событие.время;
               return (x < 0 ? -1 : x is 0 ? 0 : 1);
               }
            return 1;
        }
    +/

    export  final static Планировщик планировщик ()
        {
            return дайЭту.событие.планировщик;
        }

        ////////////////////////////////////////////////////////////////////////////
        // Initialization
        ////////////////////////////////////////////////////////////////////////////

        /**
         * Initializes an empty fiber Объект
         *
         * (useful to сбрось it)
         */
    export  this(т_мера разм){
            м_дг    = null;
            м_фн    = null;
            м_вызов  = Вызов.НЕТ;
            м_состояние = Состояние.ТЕРМ;
            м_необработ = null;
            
            разместиСтэк( разм );
        }

        /**
         * Initializes a fiber Объект which is associated with a static
         * D function.
         *
         * Параметры:
         *  фн = The thread function.
         *  разм = The stack size for this fiber.
         *
         * In:
         *  фн must not be null.
         */
    export  this( проц function() фн, т_мера разм = РАЗМЕР_СТРАНИЦЫ)
        in
        {
            assert( фн );
        }
        body
        {
            м_фн    = фн;
            м_вызов  = Вызов.ФН;
            м_состояние = Состояние.ЗАДЕРЖ;
            разместиСтэк( разм );
            инициализуйСтэк();
        }


        /**
         * Initializes a fiber Объект which is associated with a dynamic
         * D function.
         *
         * Параметры:
         *  дг = The thread function.
         *  разм = The stack size for this fiber.
         *
         * In:
         *  дг must not be null.
         */
    export  this( проц delegate() дг, т_мера разм = РАЗМЕР_СТРАНИЦЫ, Планировщик s = null )
        in
        {
            assert( дг );
        }
        body
        {
            событие.планировщик = s;

            м_дг    = дг;
            м_вызов  = Вызов.ДГ;
            м_состояние = Состояние.ЗАДЕРЖ;
            разместиСтэк(разм);
            инициализуйСтэк();
        }


        /**
         * Cleans up any remaining resources used by this Объект.
         */
    export  ~this()
        {
            // NOTE: A live reference to this Объект will exist on its associated
            //       stack from the first time its вызови() method has been called
            //       until its execution completes with Состояние.ТЕРМ.  Thus, the only
            //       times this dtor should be called are either if the fiber has
            //       terminated (and therefore has no active stack) or if the user
            //       explicitly deletes this Объект.  The latter case is an error
            //       but is not easily tested for, since Состояние.ЗАДЕРЖ may imply that
            //       the fiber was just created but has never been пуск.  There is
            //       not a compelling case to создай a Состояние.INIT just to offer a
            //       means of ensuring the user isn't violating this Объект's
            //       contract, so for now this requirement will be enforced by
            //       documentation only.
            освободиСтэк();
        }


        ////////////////////////////////////////////////////////////////////////////
        // General Actions
        ////////////////////////////////////////////////////////////////////////////


        /**
         * Передаёт выполнение на данный объект Фибра. Вызывающий контекст
         * замораживается до вызова процедуры Фибра.жни(), либо до её терминации
         * из-за необработанного исключения.
         *
         * Параметры:
         *  повторноБросить = Rethrow any unhandled exception which may have caused this
         *            fiber to terminate.
         *
         * In:
         *  This fiber must be in состояние ЗАДЕРЖ.
         *
         * Throws:
         *  Any exception not handled by the joined thread.
         *
         * Returns:
         *  Any exception not handled by this fiber if повторноБросить = false, null
         *  otherwise.
         */
    export  final Объект вызови( бул повторноБросить = true )
        in
        {
            assert( м_состояние == Состояние.ЗАДЕРЖ );
        }
        body
        {
            Фибра   cur = дайЭту();

            static if( is( ucontext_t ) )
              m_ucur = cur ? &cur.m_utxt : &Фибра.sm_utxt;

            установиЭту( this );
            this.подключись();
            установиЭту( cur );

            static if( is( ucontext_t ) )
              m_ucur = null;

            // NOTE: If the fiber has terminated then the stack pointers must be
            //       сбрось.  This ensures that the stack for this fiber is not
            //       scanned if the fiber has terminated.  This is necessary to
            //       prevent any references lingering on the stack from delaying
            //       the collection of otherwise dead OBJECTs.  The most notable
            //       being the current Объект, which is referenced at the top of
            //       фибра_точкаВхода.
            if( м_состояние == Состояние.ТЕРМ )
            {
                м_кткст.встэк = м_кткст.нстэк;
            }
            if( м_необработ )
            {
                Объект объ  = м_необработ;
                м_необработ = null;
                if( повторноБросить )
                    throw объ;
                return объ;
            }
            return null;
        }


        /**
         * Resets this fiber so that it may be re-used with the same function.
         * This routine may only be
         * called for fibers that have terminated, as doing otherwise could результат
         * in scope-dependent functionality that is not executed.  Stack-based
         * classes, for example, may not be cleaned up properly if a fiber is сбрось
         * before it has terminated.
         *
         * In:
         *  This fiber must be in состояние ТЕРМ, and have a valid function/delegate.
         */
    export  final проц сбрось()
        in
        {
            assert( м_вызов != Вызов.НЕТ );
            assert( м_состояние == Состояние.ТЕРМ );
            assert( м_кткст.встэк == м_кткст.нстэк );
        }
        body
        {
            м_состояние = Состояние.ЗАДЕРЖ;
            инициализуйСтэк();
            м_необработ = null;
        }

        /**
         * Reinitializes a fiber Объект which is associated with a static
         * D function.
         *
         * Параметры:
         *  фн = The thread function.
         *
         * In:
         *  This fiber must be in состояние ТЕРМ.
         *  фн must not be null.
         */
    export  final проц сбрось( проц function() фн )
        in
        {
            assert( фн );
            assert( м_состояние == Состояние.ТЕРМ );
            assert( м_кткст.встэк == м_кткст.нстэк );
        }
        body
        {
            м_фн    = фн;
            м_вызов  = Вызов.ФН;
            м_состояние = Состояние.ЗАДЕРЖ;
            инициализуйСтэк();
            м_необработ = null;
        }


        /**
         * reinitializes a fiber Объект which is associated with a dynamic
         * D function.
         *
         * Параметры:
         *  дг = The thread function.
         *
         * In:
         *  This fiber must be in состояние ТЕРМ.
         *  дг must not be null.
         */
    export  final проц сбрось( проц delegate() дг )
        in
        {
            assert( дг );
            assert( м_состояние == Состояние.ТЕРМ );
            assert( м_кткст.встэк == м_кткст.нстэк );
        }
        body
        {
            м_дг    = дг;
            м_вызов  = Вызов.ДГ;
            м_состояние = Состояние.ЗАДЕРЖ;
            инициализуйСтэк();
            м_необработ = null;
        }
        
        /**
         * Clears the fiber from all references to a previous вызови (unhandled exceptions, delegate)
         *
         * In:
         *  This fiber must be in состояние ТЕРМ.
         */
    export  final проц сотри()
        in
        {
            assert( м_состояние == Состояние.ТЕРМ );
            assert( м_кткст.встэк == м_кткст.нстэк );
        }
        body
        {
            if (м_состояние != Состояние.ТЕРМ){
                char[20] буф;
                throw new Exception("Фибра@"~ptrToStr(cast(т_мера)cast(ук)this,буф)~" в неожиданном состоянии "~ptrToStr(м_состояние,буф),__FILE__,__LINE__);
            }
            if (м_кткст.встэк != м_кткст.нстэк){
                char[20] буф;
                throw new Exception("Фибра@"~ptrToStr(cast(т_мера)cast(ук)this,буф)~" нстэк="~ptrToStr(cast(т_мера)cast(ук)м_кткст.нстэк,буф)~" != встэк="~ptrToStr(cast(т_мера)cast(ук)м_кткст.встэк,буф),__FILE__,__LINE__);
            }
            м_дг    = null;
            м_фн    = null;
            м_вызов  = Вызов.НЕТ;
            м_состояние = Состояние.ТЕРМ;
            м_необработ = null;
        }
        

        ////////////////////////////////////////////////////////////////////////////
        // General Properties
        ////////////////////////////////////////////////////////////////////////////


        /**
         * A fiber may occupy one of three states: ЗАДЕРЖ, ВЫП, and ТЕРМ.  The ЗАДЕРЖ
         * состояние applies to any fiber that is suspended and готов to be called.
         * The ВЫП состояние will be set for any fiber that is currently executing.
         * And the ТЕРМ состояние is set when a fiber terminates.  Once a fiber
         * terminates, it must be сбрось before it may be called again.
         */
        enum Состояние
        {
            ЗАДЕРЖ,   ///
            ВЫП,   ///
            ТЕРМ    ///
        }


        /**
         * Gets the current состояние of this fiber.
         *
         * Returns:
         *  The состояние of this fiber as an enumerated value.
         */
    export  final Состояние состояние()
        {
                    return м_состояние;
        }
        
        export т_мера размерСтэка(){
            return м_разм;
        }


        ////////////////////////////////////////////////////////////////////////////
        // Actions on Calling Фибра
        ////////////////////////////////////////////////////////////////////////////


        /**
         * Forces a context switch to occur away from the calling fiber.
         */
    export  final проц глуши ()
        {
            assert( м_состояние == Состояние.ВЫП );

            static if( is( ucontext_t ) )
                       m_ucur = &m_utxt;

            м_состояние = Состояние.ЗАДЕРЖ;
            отключись();
            м_состояние = Состояние.ВЫП;
        }


        /**
         * Forces a context switch to occur away from the calling fiber.
         */
    export  static проц жни()
        {
            Фибра cur = дайЭту;
            assert( cur, "Фибра.жни() вызвана при отсутствии активной фибры" );
            if (cur.событие.планировщик)
                cur.событие.планировщик.пауза (0);
            else
              cur.глуши;
        }

        /**
         * Forces a context switch to occur away from the calling fiber and then
         * throws объ in the calling fiber.
         *
         * Параметры:
         *  объ = The Объект to throw.
         *
         * In:
         *  объ must not be null.
         */
    export  static проц жниИБросай( Объект объ )
        in
        {
            assert( объ );
        }
        body
        {
            Фибра cur = дайЭту();
            assert( cur, "Фибра.жни(объ) called with no active fiber" );
            cur.м_необработ = объ;
            if (cur.событие.планировщик)
                cur.событие.планировщик.пауза (0);
            else
               cur.глуши;
        }


        ////////////////////////////////////////////////////////////////////////////
        // Фибра Accessors
        ////////////////////////////////////////////////////////////////////////////


        /**
         * Provides a reference to the calling fiber or null if no fiber is
         * currently active.
         *
         * Returns:
         *  The fiber Объект representing the calling fiber or null if no fiber
         *  is currently active.  The результат of deleting this Объект is undefined.
         */
    export  static Фибра дайЭту()
        {
            return cast(Фибра) ДайЗначениеНлх( см_эта );            
        }

    //
        // The type of routine passed on fiber construction.
        //
        enum Вызов
        {
            НЕТ,
            ФН,
            ДГ
        }


        //
        // Standard fiber данные
        //
        Вызов                м_вызов;
        union
        {
            проц function() м_фн;
            проц delegate() м_дг;
        }
        бул                м_пущена;
        Объект              м_необработ;
        Состояние               м_состояние;
        ткст              м_имя;
    public:
        Событие               событие;


        ////////////////////////////////////////////////////////////////////////////
        // Stack Management
        ////////////////////////////////////////////////////////////////////////////


        //
        // Allocate a new stack for this fiber.
        //
    export  final проц разместиСтэк( т_мера разм )
        in
        {
            assert( !м_пам && !м_кткст );
        }
        body
        {
            // adjust alloc size to a multiple of РАЗМЕР_СТРАНИЦЫ
            разм += РАЗМЕР_СТРАНИЦЫ - 1;
            разм -= разм % РАЗМЕР_СТРАНИЦЫ;

            // NOTE: This instance of Нить.Контекст is dynamic so Фибра OBJECTs
            //       can be collected by the GC so дол as no user level references
            //       to the Объект exist.  If м_кткст were not dynamic then its
            //       presence in the global context list would be enough to keep
            //       this Объект alive indefinitely.  An alternative to allocating
            //       room for this struct explicitly would be to mash it into the
            //       base of the stack being allocated below.  However, doing so
            //       requires too much special logic to be worthwhile.
            м_кткст = new Нить.Контекст;

            static if( is( typeof( VirtualAlloc ) ) )
            {
                // reserve memory for stack
                м_пам = VirtualAlloc( null,
                                       разм + РАЗМЕР_СТРАНИЦЫ,
                                       ППамять.Резервировать,
                                       ППамять.СтрНедост );
                if( !м_пам )
                {
                    throw new FiberException( "Не удаётся занять память под стэк" );
                }

                version( СТЭК_РАСТЁТ_ВНИЗ )
                {
                    ук stack = м_пам + РАЗМЕР_СТРАНИЦЫ;
                    ук guard = м_пам;
                    ук pbase = stack + разм;
                }
                else
                {
                    ук stack = м_пам;
                    ук guard = м_пам + разм;
                    ук pbase = stack;
                }

                // allocate reserved stack segment
                stack = VirtualAlloc( stack,
                                      разм,
                                      ППамять.Отправить,
                                      ППамять.СтрЗапЧтен );
                if( !stack )
                {
                    throw new FiberException( "Не удаётся разместить память под стэк" );
                }

                // allocate reserved guard page
                guard = VirtualAlloc( guard,
                                      РАЗМЕР_СТРАНИЦЫ,
                                      ППамять.Отправить,
                                      ППамять.СтрЗапЧтен | ППамять.СтрОхрана );
                if( !guard )
                {
                    throw new FiberException( "Не удаётся создать гардпейдж для стека" );
                }

                м_кткст.нстэк = pbase;
                м_кткст.встэк = pbase;
                м_разм = разм;
            }
            else
            {   static if( is( typeof( mmap ) ) )
                {
                    м_пам = mmap( null,
                                   разм,
                                   PROT_READ | PROT_WRITE,
                                   MAP_PRIVATE | MAP_ANON,
                                   -1,
                                   0 );
                    if( м_пам == MAP_FAILED )
                        м_пам = null;
                }
                else static if( is( typeof( valloc ) ) )
                {
                    м_пам = valloc( разм );
                }
                else static if( is( typeof( malloc ) ) )
                {
                    м_пам = malloc( разм );
                }
                else
                {
                    м_пам = null;
                }

                if( !м_пам )
                {
                    throw new FiberException( "Не удаётся разместить память под стек" );
                }

                version( СТЭК_РАСТЁТ_ВНИЗ )
                {
                    м_кткст.нстэк = м_пам + разм;
                    м_кткст.встэк = м_пам + разм;
                }
                else
                {
                    м_кткст.нстэк = м_пам;
                    м_кткст.встэк = м_пам;
                }
                м_разм = разм;
            }

            Нить.добавь( м_кткст );
        }


        //
        // Free this fiber's stack.
        //
    export  final проц освободиСтэк()
        in
        {
            assert( м_пам && м_кткст );
        }
        body
        {
            // NOTE: Since this routine is only ever expected to be called from
            //       the dtor, pointers to freed данные are not set to null.

            // NOTE: м_кткст is guaranteed to be alive because it is held in the
            //       global context list.
            Нить.удали( м_кткст );

            static if( is( typeof( VirtualAlloc ) ) )
            {
                VirtualFree( м_пам, 0, ППамять.Освободить );
            }
            else static if( is( typeof( mmap ) ) )
            {
                munmap( м_пам, м_разм );
            }
            else static if( is( typeof( valloc ) ) )
            {
                free( м_пам );
            }
            else static if( is( typeof( malloc ) ) )
            {
                free( м_пам );
            }
            delete м_кткст;
        }


        //
        // Initialize the allocated stack.
        //
    export  final проц инициализуйСтэк()
        in
        {
            assert( м_кткст.встэк && м_кткст.встэк == м_кткст.нстэк );
            assert( cast(т_мера) м_кткст.нстэк % (ук).sizeof == 0 );
        }
        body
        {
            ук pstack = м_кткст.встэк;
            scope( exit )  м_кткст.встэк = pstack;

            проц push( т_мера знач )
            {
                version( СТЭК_РАСТЁТ_ВНИЗ )
                {
                    pstack -= т_мера.sizeof;
                    *(cast(т_мера*) pstack) = знач;
                }
                else
                {
                    pstack += т_мера.sizeof;
                    *(cast(т_мера*) pstack) = знач;
                }
            }

            // NOTE: On OS X the stack must be 16-byte aligned according to the
            // IA-32 вызови spec.
            version( darwin )
            {
                 pstack = cast(ук)(cast(бцел)(pstack) - (cast(бцел)(pstack) & 0x0F));
            }

            version( AsmX86_Win32 )
            {
                push( cast(т_мера) &фибра_точкаВхода );                 // EIP
                push( 0xFFFFFFFF );                                     // EBP
                push( 0x00000000 );                                     // EAX
                push( 0xFFFFFFFF );                                     // FS:[0]
                version( СТЭК_РАСТЁТ_ВНИЗ )
                {
                    push( cast(т_мера) м_кткст.нстэк );                 // FS:[4]
                    push( cast(т_мера) м_кткст.нстэк - м_разм );        // FS:[8]
                }
                else
                {
                    push( cast(т_мера) м_кткст.нстэк );                 // FS:[4]
                    push( cast(т_мера) м_кткст.нстэк + м_разм );        // FS:[8]
                }
                push( 0x00000000 );                                     // EBX
                push( 0x00000000 );                                     // ESI
                push( 0x00000000 );                                     // EDI
            }
            else version( AsmX86_Posix )
            {
                push( 0x00000000 );                                     // strange pre EIP
                push( cast(т_мера) &фибра_точкаВхода );                 // EIP
                push( (cast(т_мера)pstack)+8 );                         // EBP
                push( 0x00000000 );                                     // EAX
                push( getEBX() );                                       // EBX used for PIC code
                push( 0x00000000 );                                     // ECX just to have it aligned...
                push( 0x00000000 );                                     // ESI
                push( 0x00000000 );                                     // EDI
            }
            else version( AsmX86_64_Posix )
            {
                push( 0x00000000 );                                     // strange pre EIP
                push( cast(т_мера) &фибра_точкаВхода );                 // RIP
                push( (cast(т_мера)pstack)+8 );                         // RBP
                push( 0x00000000_00000000 );                            // RBX
                push( 0x00000000_00000000 );                            // R12
                push( 0x00000000_00000000 );                            // R13
                push( 0x00000000_00000000 );                            // R14
                push( 0x00000000_00000000 );                            // R15
                push( 0x00001f80_0000037f );                            // MXCSR (32 bits), unused (16 bits) , x87 control (16 bits)
            }
            else version( AsmPPC_Posix )
            {
                version( СТЭК_РАСТЁТ_ВНИЗ )
                {
                    pstack -= цел.sizeof * 5;
                }
                else
                {
                    pstack += цел.sizeof * 5;
                }

                push( cast(т_мера) &фибра_точкаВхода );     // link register
                push( 0x00000000 );                         // control register
                push( 0x00000000 );                         // old stack pointer

                // GPR values
                version( СТЭК_РАСТЁТ_ВНИЗ )
                {
                    pstack -= цел.sizeof * 20;
                }
                else
                {
                    pstack += цел.sizeof * 20;
                }

                assert( cast(бцел) pstack & 0x0f == 0 );
            }
            else static if( is( ucontext_t ) )
            {
                getcontext( &m_utxt );
                // patch from #1707 - thanks to jerdfelt
                //m_utxt.uc_stack.ss_sp   = м_кткст.нстэк;
                m_utxt.uc_stack.ss_sp   = м_пам;
                m_utxt.uc_stack.ss_size = м_разм;
                makecontext( &m_utxt, &фибра_точкаВхода, 0 );
                // NOTE: If ucontext is being used then the top of the stack will
                //       be a pointer to the ucontext_t struct for that fiber.
                push( cast(т_мера) &m_utxt );
            }
        }

                ////////////////////////////////////////////////////////////////////////////
        // Static Initialization
        ////////////////////////////////////////////////////////////////////////////


        static this()
        {
            version( Win32 )
            {
                см_эта = РазместиНлх();
                assert( см_эта != ПОшибка.НЛХВнеИндексов );
            }
            else version( Posix )
            {
                цел status;

                status = pthread_key_create( &см_эта, null );
                assert( status == 0 );

              static if( is( ucontext_t ) )
              {
                status = getcontext( &sm_utxt );
                assert( status == 0 );
              }
            }
        }


    private this()
        {
            м_вызов = Вызов.НЕТ;
        }
        
        public Нить.Контекст* м_кткст;
        public т_мера          м_разм;
        ук           м_пам;

        static if( is( ucontext_t ) )
        {
            // NOTE: The static ucontext instance is used to represent the context
            //       of the main application thread.
            static ucontext_t   sm_utxt = void;
            ucontext_t          m_utxt  = void;
            ucontext_t*         m_ucur  = null;
        }

    ////////////////////////////////////////////////////////////////////////////
        // Storage of Active Фибра
        ////////////////////////////////////////////////////////////////////////////


        //
        // Sets a thread-local reference to the current fiber Объект.
        //
    export  static проц установиЭту( Фибра f )
        {
            version( Win32 )
            {
                УстановиЗначениеНлх( см_эта, cast(ук) f );
            }
            else version( Posix )
            {
                pthread_setspecific( см_эта, cast(ук) f );
            }
        }


        static Нить.КлючНЛХ    см_эта;


    private:
        ////////////////////////////////////////////////////////////////////////////
        // Контекст Switching
        ////////////////////////////////////////////////////////////////////////////


        //
        // Switches into the stack held by this fiber.
        //
    export  final проц подключись()
        {
            Нить  нобъ = Нить.дайЭту();
            ук*  oldp = &нобъ.м_тек.встэк;
            ук   newp = м_кткст.встэк;

            // NOTE: The order of operations here is very important.  The current
            //       stack top must be stored before м_блок is set, and суньКонтекст
            //       must not be called until after м_блок is set.  This process
            //       is intended to prevent a race condition with the заморозь
            //       mechanism used for garbage collection.  If it is not followed,
            //       a badly timed collection could cause the GC to scan from the
            //       bottom of one stack to the top of another, or to miss scanning
            //       a stack that still contains valid данные.  The old stack pointer
            //       oldp will be set again before the context switch to guarantee
            //       that it points to exactly the correct stack location so the
            //       successive pop operations will succeed.
            *oldp = ртВерхСтэка();
            volatile нобъ.м_блок = true;
            нобъ.суньКонтекст( м_кткст );

            фибра_переклКонтекст( oldp, newp );

            // NOTE: As above, these operations must be performed in a strict order
            //       to prevent Bad Things from happening.
            нобъ.выньКонтекст();
            volatile нобъ.м_блок = false;
            нобъ.м_тек.встэк = нобъ.м_тек.нстэк;
        }


        //
        // Switches out of the current stack and into the enclosing stack.
        //
    export  final проц отключись()
        {
            Нить  нобъ = Нить.дайЭту();
            ук*  oldp = &м_кткст.встэк;
            ук   newp = нобъ.м_тек.внутри.встэк;

            // NOTE: The order of operations here is very important.  The current
            //       stack top must be stored before м_блок is set, and суньКонтекст
            //       must not be called until after м_блок is set.  This process
            //       is intended to prevent a race condition with the заморозь
            //       mechanism used for garbage collection.  If it is not followed,
            //       a badly timed collection could cause the GC to scan from the
            //       bottom of one stack to the top of another, or to miss scanning
            //       a stack that still contains valid данные.  The old stack pointer
            //       oldp will be set again before the context switch to guarantee
            //       that it points to exactly the correct stack location so the
            //       successive pop operations will succeed.
            *oldp = ртВерхСтэка();
            volatile нобъ.м_блок = true;

            фибра_переклКонтекст( oldp, newp );

            // NOTE: As above, these operations must be performed in a strict order
            //       to prevent Bad Things from happening.
            нобъ=Нить.дайЭту();
            volatile нобъ.м_блок = false;
            нобъ.м_тек.встэк = нобъ.м_тек.нстэк;
        }
    }

    extern(C){
        проц нить_жни(){
            Нить.жни();
        }
        
        проц нить_спи(дво период){
            Нить.спи(период);
        }
    }

export extern (C)
{
void thread_init(){ нить_иниц();}
void thread_attachThis(){ нить_прикрепиЭту();}
void thread_detachThis(){ нить_открепиЭту();}
void thread_joinAll(){ нить_объединиВсе();}

bool thread_needLock(){return нить_нужнаБлокировка();}
void thread_suspendAll(){ нить_заморозьВсе();}
void thread_resumeAll(){ нить_разморозьВсе();}
void thread_scanAll( фнСканВсеНити scan, void* текВерхСтека = null ){ нить_сканируйВсе(scan, текВерхСтека);}
void thread_yield(){ нить_жни();}    
void thread_sleep(double период){ нить_спи(период);}
void fiber_entryPoint() { фибра_точкаВхода();}
void fiber_switchContext( void** oldp, void* newp ) { фибра_переклКонтекст(oldp, newp );}
}
