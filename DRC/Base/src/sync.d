module sync;


export extern (D) class ИсключениеСинх : Исключение
{
export:

    this( ткст сооб )
    {
        super( сооб );
    }
}

private
 {
    template целыйТип_ли( T )
    {
        const bool целыйТип_ли = целыйЗначныйТип_ли!(T) ||
                                   целыйБеззначныйТип_ли!(T);
    }

    template указательИлиКласс_ли(T)
    {
        const указательИлиКласс_ли = is(T==class);
    }

    template указательИлиКласс_ли(T : T*)
    {
            const указательИлиКласс_ли = true;
    }
  
    template целыйЗначныйТип_ли( T )
    {
        const bool целыйЗначныйТип_ли = is( T == byte )  ||
                                         is( T == short ) ||
                                         is( T == int )   ||
                                         is( T == long )/+||
                                         is( T == cent  )+/;
    }

    template целыйБеззначныйТип_ли( T )
    {
        const bool целыйБеззначныйТип_ли = is( T == ubyte )  ||
                                           is( T == ushort ) ||
                                           is( T == uint )   ||
                                           is( T == ulong )/+||
                                           is( T == ucent  )+/;
    }
    
     template УкНаКласс(T){
        static if (is(T==class)){
            alias ук УкНаКласс;
        } else {
            alias T УкНаКласс;
        }
    }
}

template атомныеЗначенияПравильноРазмещены( T )
{
    bool атомныеЗначенияПравильноРазмещены( т_мера адр )
    {
        return адр % УкНаКласс!(T).sizeof == 0;
    }
}

version(D_InlineAsm_X86){
    проц барьерПамяти(bool ll, bool ls, bool sl,bool ss,bool device=false)(){
        static if (device) {
            if (ls || sl || ll || ss){
                // cpid should sequence even more than mfence
                volatile asm {
                    push EBX;
                    mov EAX, 0; // model, stepping
                    cpuid;
                    pop EBX;
                }
            }
        } else static if (ls || sl || (ll && ss)){ // use a sequencing operation like cpuid or simply cmpxch instead?
            volatile asm {
                mfence;
            }
            // this is supposedly faster and correct, but let's play it safe and use the specific instruction
            // push rax
            // xchg rax
            // pop rax
        } else static if (ll){
            volatile asm {
                lfence;
            }
        } else static if( ss ){
            volatile asm {
                sfence;
            }
        }
    }
} else version(D_InlineAsm_X86_64){
    проц барьерПамяти(bool ll, bool ls, bool sl,bool ss,bool device=false)(){
        static if (device) {
            if (ls || sl || ll || ss){
                // cpid should sequence even more than mfence
                volatile asm {
                    push RBX;
                    mov RAX, 0; // model, stepping
                    cpuid;
                    pop RBX;
                }
            }
        } else static if (ls || sl || (ll && ss)){ // use a sequencing operation like cpuid or simply cmpxch instead?
            volatile asm {
                mfence;
            }
            // this is supposedly faster and correct, but let's play it safe and use the specific instruction
            // push rax
            // xchg rax
            // pop rax
        } else static if (ll){
            volatile asm {
                lfence;
            }
        } else static if( ss ){
            volatile asm {
                sfence;
            }
        }
    }
} else {
    pragma(msg,"WARNING: no atomic operations on this architecture");
    pragma(msg,"WARNING: this is *slow* you probably want to change this!");
    цел dummy;
    // acquires a блокируй... probably you will want to skip this
    synchronized проц барьерПамяти(bool ll, bool ls, bool sl,bool ss,bool device=false)(){
        dummy =1;
    }
    enum{LockVersion = true}
}

static if (!is(typeof(LockVersion))) {
    enum{LockVersion = false}
}

// use stricter fences
enum{strictFences = false}

/// utility function for a write barrier (disallow store and store reorderig)
проц барьерЗаписи(){
    барьерПамяти!(false,false,strictFences,true)();
}
/// utility function for a read barrier (disallow load and load reorderig)
проц барьерЧтения(){
    барьерПамяти!(true,strictFences,false,false)();
}
/// utility function for a full barrier (disallow reorderig)
проц полныйБарьер(){
    барьерПамяти!(true,true,true,true)();
}

 version(D_InlineAsm_X86) {
    T атомнаяПерестановка( T )( inout T знач, T новзнач )
    in {
        // NOTE: 32 bit x86 systems support 8 byte CAS, which only requires
        //       4 byte alignment, so use т_мера as the align type here.
        static if( T.sizeof > т_мера.sizeof )
            assert( атомныеЗначенияПравильноРазмещены!(т_мера)( cast(т_мера) &знач ) );
        else
            assert( атомныеЗначенияПравильноРазмещены!(T)( cast(т_мера) &знач ) );
    } body {
        T*posVal=&знач;
        static if( T.sizeof == byte.sizeof ) {
            volatile asm {
                mov AL, новзнач;
                mov ECX, posVal;
                lock; // блокируй always needed to make this op atomic
                xchg [ECX], AL;
            }
        }
        else static if( T.sizeof == short.sizeof ) {
            volatile asm {
                mov AX, новзнач;
                mov ECX, posVal;
                lock; // блокируй always needed to make this op atomic
                xchg [ECX], AX;
            }
        }
        else static if( T.sizeof == цел.sizeof ) {
            volatile asm {
                mov EAX, новзнач;
                mov ECX, posVal;
                lock; // блокируй always needed to make this op atomic
                xchg [ECX], EAX;
            }
        }
        else static if( T.sizeof == дол.sizeof ) {
            // 8 Byte swap on 32-Bit Processor, use CAS?
            static assert( false, "Invalid template type specified, 8bytes in 32 bit mode: "~T.stringof );
        }
        else
        {
            static assert( false, "Invalid template type specified: "~T.stringof );
        }
    }
} else version (D_InlineAsm_X86_64){
    T атомнаяПерестановка( T )( inout T знач, T новзнач )
    in {
        assert( атомныеЗначенияПравильноРазмещены!(T)( cast(т_мера) &знач ) );
    } body {
        T*posVal=&знач;
        static if( T.sizeof == byte.sizeof ) {
            volatile asm {
                mov AL, новзнач;
                mov RCX, posVal;
                lock; // блокируй always needed to make this op atomic
                xchg [RCX], AL;
            }
        }
        else static if( T.sizeof == short.sizeof ) {
            volatile asm {
                mov AX, новзнач;
                mov RCX, posVal;
                lock; // блокируй always needed to make this op atomic
                xchg [RCX], AX;
            }
        }
        else static if( T.sizeof == цел.sizeof ) {
            volatile asm {
                mov EAX, новзнач;
                mov RCX, posVal;
                lock; // блокируй always needed to make this op atomic
                xchg [RCX], EAX;
            }
        }
        else static if( T.sizeof == дол.sizeof ) {
            volatile asm {
                mov RAX, новзнач;
                mov RCX, posVal;
                lock; // блокируй always needed to make this op atomic
                xchg [RCX], RAX;
            }
        }
        else
        {
            static assert( false, "Invalid template type specified: "~T.stringof );
        }
    }
} else {
    T атомнаяПерестановка( T )( inout T знач, T новзнач )
    in {
        assert( атомныеЗначенияПравильноРазмещены!(T)( cast(т_мера) &знач ) );
    } body {
        T прежднЗнач;
        synchronized(typeid(T)){
            прежднЗнач=знач;
            знач=новзнач;
        }
        return прежднЗнач;
    }
}

//---------------------
// internal conversion template
private T aCasT(T,V)(ref   T знач, T новзнач, T равно){
    union UVConv{V v; T t;}
    union UVPtrConv{V *v; T *t;}
    UVConv vNew,vOld,vAtt;
    UVPtrConv valPtr;
    vNew.t=новзнач;
    vOld.t= равно;
    valPtr.t=&знач;
    vAtt.v=atomicCAS(*valPtr.v,vNew.v,vOld.v);
    return vAtt.t;
}
/// internal reduction 
private T aCas(T)(ref   T знач, T новзнач, T равно){
    static if (T.sizeof==1){
        return aCasT!(T,ubyte)(знач,новзнач,равно);
    } else static if (T.sizeof==2){
        return aCasT!(T,ushort)(знач,новзнач,равно);
    } else static if (T.sizeof==4){
        return aCasT!(T,бцел)(знач,новзнач,равно);
    } else static if (T.sizeof==8){ // unclear if it is always supported...
        return aCasT!(T,ulong)(знач,новзнач,равно);
    } else {
        static assert(0,"invalid type "~T.stringof);
    }
}

version(D_InlineAsm_X86) {
    version(darwin){
        extern(C) ubyte OSAtomicCompareAndSwap64(дол прежднЗначue, дол newValue,
                 дол *theValue); // assumes that in C sizeof(_Bool)==1 (as given in osx IA-32 ABI)
    }
    T atomicCAS( T )( ref   T знач, T новзнач, T равно )
    in {
        // NOTE: 32 bit x86 systems support 8 byte CAS, which only requires
        //       4 byte alignment, so use т_мера as the align type here.
        static if( УкНаКласс!(T).sizeof > т_мера.sizeof )
            assert( атомныеЗначенияПравильноРазмещены!(т_мера)( cast(т_мера) &знач ) );
        else
            assert( атомныеЗначенияПравильноРазмещены!(УкНаКласс!(T))( cast(т_мера) &знач ) );
    } body {
        T*posVal=&знач;
        static if( T.sizeof == byte.sizeof ) {
            volatile asm {
                mov DL, новзнач;
                mov AL, равно;
                mov ECX, posVal;
                lock; // блокируй always needed to make this op atomic
                cmpxchg [ECX], DL;
            }
        }
        else static if( T.sizeof == short.sizeof ) {
            volatile asm {
                mov DX, новзнач;
                mov AX, равно;
                mov ECX, posVal;
                lock; // блокируй always needed to make this op atomic
                cmpxchg [ECX], DX;
            }
        }
        else static if( УкНаКласс!(T).sizeof == цел.sizeof ) {
            volatile asm {
                mov EDX, новзнач;
                mov EAX, равно;
                mov ECX, posVal;
                lock; // блокируй always needed to make this op atomic
                cmpxchg [ECX], EDX;
            }
        }
        else static if( T.sizeof == дол.sizeof ) {
            // 8 Byte StoreIf on 32-Bit Processor
            version(darwin){
                union UVConv{дол v; T t;}
                union UVPtrConv{дол *v; T *t;}
                UVConv vEqual,vNew;
                UVPtrConv valPtr;
                vEqual.t=равно;
                vNew.t=новзнач;
                valPtr.t=&знач;
                while(1){
                    if(OSAtomicCompareAndSwap64(vEqual.v, vNew.v, valPtr.v)!=0)
                    {
                        return равно;
                    } else {
                        volatile {
                            T res=знач;
                            if (res!is равно) return res;
                        }
                    }
                }
            } else {
                T res;
                volatile asm
                {
                    push EDI;
                    push EBX;
                    lea EDI, новзнач;
                    mov EBX, [EDI];
                    mov ECX, 4[EDI];
                    lea EDI, равно;
                    mov EAX, [EDI];
                    mov EDX, 4[EDI];
                    mov EDI, знач;
                    lock; // блокируй always needed to make this op atomic
                    cmpxch8b [EDI];
                    lea EDI, res;
                    mov [EDI], EAX;
                    mov 4[EDI], EDX;
                    pop EBX;
                    pop EDI;
                }
                return res;
            }
        }
        else
        {
            static assert( false, "Invalid template type specified: "~T.stringof );
        }
    }
} else version (D_InlineAsm_X86_64){
    T atomicCAS( T )( ref   T знач, T новзнач, T равно )
    in {
        assert( атомныеЗначенияПравильноРазмещены!(T)( cast(т_мера) &знач ) );
    } body {
        T*posVal=&знач;
        static if( T.sizeof == byte.sizeof ) {
            volatile asm {
                mov DL, новзнач;
                mov AL, равно;
                mov RCX, posVal;
                lock; // блокируй always needed to make this op atomic
                cmpxchg [RCX], DL;
            }
        }
        else static if( T.sizeof == short.sizeof ) {
            volatile asm {
                mov DX, новзнач;
                mov AX, равно;
                mov RCX, posVal;
                lock; // блокируй always needed to make this op atomic
                cmpxchg [RCX], DX;
            }
        }
        else static if( УкНаКласс!(T).sizeof == цел.sizeof ) {
            volatile asm {
                mov EDX, новзнач;
                mov EAX, равно;
                mov RCX, posVal;
                lock; // блокируй always needed to make this op atomic
                cmpxchg [RCX], EDX;
            }
        }
        else static if( УкНаКласс!(T).sizeof == дол.sizeof ) {
            volatile asm {
                mov RDX, новзнач;
                mov RAX, равно;
                mov RCX, posVal;
                lock; // блокируй always needed to make this op atomic
                cmpxchg [RCX], RDX;
            }
        }
        else
        {
            static assert( false, "Invalid template type specified: "~T.stringof );
        }
    }
} else {
    T atomicCAS( T )( ref   T знач, T новзнач, T равно )
    in {
        assert( атомныеЗначенияПравильноРазмещены!(T)( cast(т_мера) &знач ) );
    } body {
        T oldval;
        synchronized(typeid(T)){
            oldval=знач;
            if(oldval==равно) {
                знач=новзнач;
            }
        }
        return oldval;
    }
}

bool atomicCASB(T)( ref   T знач, T новзнач, T равно ){
    return (равно is atomicCAS(знач,новзнач,равно));
}

T атомнаяЗагрузка(T)(ref   T знач)
in {
    assert( атомныеЗначенияПравильноРазмещены!(T)( cast(т_мера) &знач ) );
    static assert(УкНаКласс!(T).sizeof<=т_мера.sizeof,"invalid size for "~T.stringof);
} body {
    volatile T res=знач;
    return res;
}

проц атомноеСохранение(T)(ref   T знач, T newVal)
in {
        assert( атомныеЗначенияПравильноРазмещены!(T)( cast(т_мера) &знач ), "invalid alignment" );
        static assert(УкНаКласс!(T).sizeof<=т_мера.sizeof,"invalid size for "~T.stringof);
} body {
    volatile знач=newVal;
}

version (D_InlineAsm_X86){
    T атомнаяПрибавка(T,U=T)(ref   T знач, U incV_){
        T incV=cast(T)incV_;
        static if (целыйТип_ли!(T)||указательИлиКласс_ли!(T)){
            T* posVal=&знач;
            T res;
            static if (T.sizeof==1){
                volatile asm {
                    mov DL, incV;
                    mov ECX, posVal;
                    lock;
                    xadd byte ptr [ECX],DL;
                    mov byte ptr res[EBP],DL;
                }
            } else static if (T.sizeof==2){
                volatile asm {
                    mov DX, incV;
                    mov ECX, posVal;
                    lock;
                    xadd short ptr [ECX],DX;
                    mov short ptr res[EBP],DX;
                }
            } else static if (T.sizeof==4){
                volatile asm
                {
                    mov EDX, incV;
                    mov ECX, posVal;
                    lock;
                    xadd int ptr [ECX],EDX;
                    mov int ptr res[EBP],EDX;
                }
            } else static if (T.sizeof==8){
                return атомнаяОп(знач,delegate (T x){ return x+incV; });
            } else {
                static assert(0,"Unsupported type size");
            }
            return res;
        } else {
            return атомнаяОп(знач,delegate T(T a){ return a+incV; });
        }
    }
} else version (D_InlineAsm_X86_64){
    T атомнаяПрибавка(T,U=T)(ref   T знач, U incV_){
        T incV=cast(T)incV_;
        static if (целыйТип_ли!(T)||указательИлиКласс_ли!(T)){
            T* posVal=&знач;
            T res;
            static if (T.sizeof==1){
                volatile asm {
                    mov DL, incV;
                    mov RCX, posVal;
                    lock;
                    xadd byte ptr [RCX],DL;
                    mov byte ptr res[EBP],DL;
                }
            } else static if (T.sizeof==2){
                volatile asm {
                    mov DX, incV;
                    mov RCX, posVal;
                    lock;
                    xadd short ptr [RCX],DX;
                    mov short ptr res[EBP],DX;
                }
            } else static if (T.sizeof==4){
                volatile asm
                {
                    mov EDX, incV;
                    mov RCX, posVal;
                    lock;
                    xadd int ptr [RCX],EDX;
                    mov int ptr res[EBP],EDX;
                }
            } else static if (T.sizeof==8){
                volatile asm
                {
                    mov RAX, знач;
                    mov RDX, incV;
                    lock; // блокируй always needed to make this op atomic
                    xadd qword ptr [RAX],RDX;
                    mov res[EBP],RDX;
                }
            } else {
                static assert(0,"Unsupported type size for type:"~T.stringof);
            }
            return res;
        } else {
            return атомнаяОп(знач,delegate T(T a){ return a+incV; });
        }
    }
} else {
    static if (LockVersion){
        T атомнаяПрибавка(T,U=T)(ref   T знач, U incV_){
            T incV=cast(T)incV_;
            static assert( целыйТип_ли!(T)||указательИлиКласс_ли!(T),"invalid type: "~T.stringof );
            synchronized(typeid(T)){
                T oldV=знач;
                знач+=incV;
                return oldV;
            }
        }
    } else {
        T атомнаяПрибавка(T,U=T)(ref   T знач, U incV_){
            T incV=cast(T)incV_;
            static assert( целыйТип_ли!(T)||указательИлиКласс_ли!(T),"invalid type: "~T.stringof );
            synchronized(typeid(T)){
                T oldV,newVal,nextVal;
                volatile nextVal=знач;
                do{
                    oldV=nextVal;
                    newV=oldV+incV;
                    auto nextVal=atomicCAS!(T)(знач,newV,oldV);
                } while(nextVal!=oldV)
                return oldV;
            }
        }
    }
}

T атомнаяОп(T)(ref   T знач, T delegate(T) f){
    T oldV,newV,nextV;
    цел i=0;
    nextV=знач;
    do {
        oldV=nextV;
        newV=f(oldV);
        nextV=aCas!(T)(знач,newV,oldV);
        if (nextV is oldV || newV is oldV) return oldV;
    } while(++i<200)
    while (true){
        нить_жни();
        volatile oldV=знач;
        newV=f(oldV);
        nextV=aCas!(T)(знач,newV,oldV);
        if (nextV is oldV || newV is oldV) return oldV;
    }
}

T флагДай(T)(ref   T flag){
    T res;
    volatile res=flag;
    барьерПамяти!(true,false,strictFences,false)();
    return res;
}

T флагУст(T)(ref   T flag,T newVal){
    барьерПамяти!(false,strictFences,false,true)();
    return атомнаяПерестановка(flag,newVal);
}

T флагОп(T)(ref   T flag,T delegate(T) op){
    барьерПамяти!(false,strictFences,false,true)();
    return атомнаяОп(flag,op);
}

T флагДоб(T)(ref   T flag,T incV=cast(T)1){
    static if (!LockVersion)
        барьерПамяти!(false,strictFences,false,true)();
    return атомнаяПрибавка(flag,incV);
}

T следщЗнач(T)(ref   T знач){
    return атомнаяПрибавка(знач,cast(T)1);
}

////////////////////////////////////////////////////////////////////////////////
// Условие
//
// проц жди();
// проц уведоми();
// проц уведомиВсе();
////////////////////////////////////////////////////////////////////////////////

export extern (D) class Условие
{
export:
    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////

    this( Мютекс m )
    {
             m_blockLock = CreateSemaphoreA( null, 1, 1, null );
            if( m_blockLock == m_blockLock.init )
                throw new ИсключениеСинх( "Не удаётся инициализировать условие" );
            scope(failure) CloseHandle( m_blockLock );

            m_blockQueue = CreateSemaphoreA( null, 0, цел.max, null );
            if( m_blockQueue == m_blockQueue.init )
                throw new ИсключениеСинх( "Не удаётся инициализировать условие" );
            scope(failure) CloseHandle( m_blockQueue );

            InitializeCriticalSection( &m_unblockLock );
            m_assocMutex = m;
    }


    ~this()
    {
            BOOL rc = CloseHandle( m_blockLock );
            assert( rc, "Unable to destroy condition" );
            rc = CloseHandle( m_blockQueue );
            assert( rc, "Unable to destroy condition" );
            DeleteCriticalSection( &m_unblockLock );
       
    }


    ////////////////////////////////////////////////////////////////////////////
    // General Actions
    ////////////////////////////////////////////////////////////////////////////

    проц жди()
    {
         ждатьПоВремени( INFINITE );       
    }

    bool жди( дол период )
    in
    {
        assert( период >= 0 );
    }
    body
    {
           enum : бцел
            {
                TICKS_PER_MILLI = 10_000,
                MAX_WAIT_MILLIS = бцел.max - 1
            }

            период /= TICKS_PER_MILLI;
            if( период > MAX_WAIT_MILLIS )
                период = MAX_WAIT_MILLIS;
            return ждатьПоВремени( cast(бцел) период );    
    }

  
    проц уведоми()
    {
         уведоми( false );     
    }


    проц уведомиВсе()
    {
         уведоми( true );    
    }


private:

        bool ждатьПоВремени( DWORD timeout )
        {
            цел   numSignalsLeft;
            цел   numWaitersGone;
            DWORD rc;

            rc = WaitForSingleObject( m_blockLock, INFINITE );
            assert( rc == WAIT_OBJECT_0 );

            m_numWaitersBlocked++;

            rc = ReleaseSemaphore( m_blockLock, 1, null );
            assert( rc );

            m_assocMutex.разблокируй();
            scope(failure) m_assocMutex.блокируй();

            rc = WaitForSingleObject( m_blockQueue, timeout );
            assert( rc == WAIT_OBJECT_0 || rc == WAIT_TIMEOUT );
            bool timedOut = (rc == WAIT_TIMEOUT);

            EnterCriticalSection( &m_unblockLock );
            scope(failure) LeaveCriticalSection( &m_unblockLock );

            if( (numSignalsLeft = m_numWaitersToUnblock) != 0 )
            {
                if ( timedOut )
                {
                    // timeout (or canceled)
                    if( m_numWaitersBlocked != 0 )
                    {
                        m_numWaitersBlocked--;
                        // do not unblock следщ waiter below (already unblocked)
                        numSignalsLeft = 0;
                    }
                    else
                    {
                        // spurious wakeup pending!!
                        m_numWaitersGone = 1;
                    }
                }
                if( --m_numWaitersToUnblock == 0 )
                {
                    if( m_numWaitersBlocked != 0 )
                    {
                        // open the gate
                        rc = ReleaseSemaphore( m_blockLock, 1, null );
                        assert( rc );
                        // do not open the gate below again
                        numSignalsLeft = 0;
                    }
                    else if( (numWaitersGone = m_numWaitersGone) != 0 )
                    {
                        m_numWaitersGone = 0;
                    }
                }
            }
            else if( ++m_numWaitersGone == цел.max / 2 )
            {
                // timeout/canceled or spurious event :-)
                rc = WaitForSingleObject( m_blockLock, INFINITE );
                assert( rc == WAIT_OBJECT_0 );
                // something is going on here - test of timeouts?
                m_numWaitersBlocked -= m_numWaitersGone;
                rc = ReleaseSemaphore( m_blockLock, 1, null );
                assert( rc == WAIT_OBJECT_0 );
                m_numWaitersGone = 0;
            }

            LeaveCriticalSection( &m_unblockLock );

            if( numSignalsLeft == 1 )
            {
                // better now than spurious later (same as ResetEvent)
                for( ; numWaitersGone > 0; --numWaitersGone )
                {
                    rc = WaitForSingleObject( m_blockQueue, INFINITE );
                    assert( rc == WAIT_OBJECT_0 );
                }
                // open the gate
                rc = ReleaseSemaphore( m_blockLock, 1, null );
                assert( rc );
            }
            else if( numSignalsLeft != 0 )
            {
                // unblock следщ waiter
                rc = ReleaseSemaphore( m_blockQueue, 1, null );
                assert( rc );
            }
            m_assocMutex.блокируй();
            return !timedOut;
        }


        проц уведоми( bool all )
        {
            DWORD rc;

            EnterCriticalSection( &m_unblockLock );
            scope(failure) LeaveCriticalSection( &m_unblockLock );

            if( m_numWaitersToUnblock != 0 )
            {
                if( m_numWaitersBlocked == 0 )
                {
                    LeaveCriticalSection( &m_unblockLock );
                    return;
                }
                if( all )
                {
                    m_numWaitersToUnblock += m_numWaitersBlocked;
                    m_numWaitersBlocked = 0;
                }
                else
                {
                    m_numWaitersToUnblock++;
                    m_numWaitersBlocked--;
                }
                LeaveCriticalSection( &m_unblockLock );
            }
            else if( m_numWaitersBlocked > m_numWaitersGone )
            {
                rc = WaitForSingleObject( m_blockLock, INFINITE );
                assert( rc == WAIT_OBJECT_0 );
                if( 0 != m_numWaitersGone )
                {
                    m_numWaitersBlocked -= m_numWaitersGone;
                    m_numWaitersGone = 0;
                }
                if( all )
                {
                    m_numWaitersToUnblock = m_numWaitersBlocked;
                    m_numWaitersBlocked = 0;
                }
                else
                {
                    m_numWaitersToUnblock = 1;
                    m_numWaitersBlocked--;
                }
                LeaveCriticalSection( &m_unblockLock );
                rc = ReleaseSemaphore( m_blockQueue, 1, null );
                assert( rc );
            }
            else
            {
                LeaveCriticalSection( &m_unblockLock );
            }
        }


        // NOTE: This implementation uses Algorithm 8c as described here:
        //       http://groups.google.com/group/comp.programming.threads/
        //              browse_frm/thread/1692bdec8040ba40/e7a5f9d40e86503a
        HANDLE              m_blockLock;    // auto-reset event (now semaphore)
        HANDLE              m_blockQueue;   // auto-reset event (now semaphore)
        Мютекс               m_assocMutex;   // external mutex/CS
        CRITICAL_SECTION    m_unblockLock;  // internal mutex/CS
        цел                 m_numWaitersGone        = 0;
        цел                 m_numWaitersBlocked     = 0;
        цел                 m_numWaitersToUnblock   = 0;
 
}



////////////////////////////////////////////////////////////////////////////////
// Барьер
//
// проц жди();
////////////////////////////////////////////////////////////////////////////////


/**
 * Класс представляет барьер, через который нити могут проходить только группами * * определённого размера.
 */
export extern (D) class Барьер
{
export:
    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////

    this( бцел предел )
    in
    {
        assert( предел > 0 );
    }
    body
    {
        м_блок  = new Мютекс;
        м_усл  = new Условие( м_блок );
        м_группа = 0;
        м_предел = предел;
        м_счёт = предел;
    }


    ////////////////////////////////////////////////////////////////////////////
    // General Actions
    ////////////////////////////////////////////////////////////////////////////
проц жди()
    {
        synchronized( м_блок )
        {
            бцел group = м_группа;

            if( --м_счёт == 0 )
            {
                м_группа++;
                м_счёт = м_предел;
                м_усл.уведомиВсе();
            }
            while( group == м_группа )
                м_усл.жди();
        }
    }


private:
    Мютекс       м_блок;
    Условие   м_усл;
    бцел        м_группа;
    бцел        м_предел;
    бцел        м_счёт;
}



////////////////////////////////////////////////////////////////////////////////
// Семафор
//
// проц жди();
// проц уведоми();
// bool пробуйЖдать();
////////////////////////////////////////////////////////////////////////////////

export extern (D) class Семафор
{
export:
    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////

    this( бцел счёт = 0 )
    {
        
            m_hndl = CreateSemaphoreA( null, счёт, цел.max, null );
            if( m_hndl == m_hndl.init )
                throw new ИсключениеСинх( "Не удалось создать семафор" );
        
    }


    ~this()
    {        
            BOOL rc = CloseHandle( m_hndl );
            assert( rc, "Не удалось удалить семафор" );
        
    }


    ////////////////////////////////////////////////////////////////////////////
    // General Actions
    ////////////////////////////////////////////////////////////////////////////

    проц жди()
    {
       
            DWORD rc = WaitForSingleObject( m_hndl, INFINITE );
            if( rc != WAIT_OBJECT_0 )
                throw new ИсключениеСинх( "Не удалось дождаться семафора" );
        
    }

    bool жди( дол период )
    in
    {
        assert( период >= 0 );
    }
    body
    {
            enum : бцел
            {
                TICKS_PER_MILLI = 10_000,
                MAX_WAIT_MILLIS = бцел.max - 1
            }

            период /= TICKS_PER_MILLI;
            if( период > MAX_WAIT_MILLIS )
                период = MAX_WAIT_MILLIS;
            switch( WaitForSingleObject( m_hndl, cast(бцел) период ) )
            {
            case WAIT_OBJECT_0:
                return true;
            case WAIT_TIMEOUT:
                return false;
            default:
                throw new ИсключениеСинх( "Не удалось дождаться семафора" );
            }
        
    }

    проц уведоми()
    {
        
            if( !ReleaseSemaphore( m_hndl, 1, null ) )
                throw new ИсключениеСинх( "Не удалось уведомить о семафоре" );
       
    }

    bool пробуйЖдать()
    {
          switch( WaitForSingleObject( m_hndl, 0 ) )
            {
            case WAIT_OBJECT_0:
                return true;
            case WAIT_TIMEOUT:
                return false;
            default:
                throw new ИсключениеСинх( "Не удалось дождаться семафора" );
            }
       
    }


private:
    version( Win32 )
    {
        HANDLE  m_hndl;
    }
    else version( OSX )
    {
        semaphore_t m_hndl;
    }
    else version( Posix )
    {
        sem_t   m_hndl;
    }
}



////////////////////////////////////////////////////////////////////////////////
// Мютекс
//
// проц блокируй();
// проц разблокируй();
// bool пытайсяБлокировать();
////////////////////////////////////////////////////////////////////////////////

export extern (D) class Мютекс :
    Объект.Монитор
{
export:
    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////

    this()
    {
         InitializeCriticalSection( &m_hndl );
       
        м_прокси.связка = this;
        // NOTE: With DMD this can be "this.__monitor = &м_прокси".
        (cast(ук*) this)[1] = &м_прокси;
    }

    this( Object o )
    in
    {
        // NOTE: With DMD this can be "o.__monitor is null".
        assert( (cast(ук*) o)[1] is null );
    }
    body
    {
        this();
        // NOTE: With DMD this can be "o.__monitor = &м_прокси".
        (cast(ук*) o)[1] = &м_прокси;
    }


    ~this()
    {
       DeleteCriticalSection( &m_hndl );
       
        (cast(ук*) this)[1] = null;
    }


    ////////////////////////////////////////////////////////////////////////////
    // General Actions
    ////////////////////////////////////////////////////////////////////////////

    проц блокируй()
    {
       EnterCriticalSection( &m_hndl );        
    }
 
    проц разблокируй()
    {
        
            LeaveCriticalSection( &m_hndl );       
    }

    void lock(){ блокируй();}
	 void unlock(){ разблокируй();}
  
    bool пытайсяБлокировать()
    {        
            return TryEnterCriticalSection( &m_hndl ) != 0;       
    }

private:
     CRITICAL_SECTION    m_hndl;    

    struct ПроксиМонитора
    {
        Объект.Монитор связка;
    }

    ПроксиМонитора            м_прокси;

}



////////////////////////////////////////////////////////////////////////////////
// ЧЗМютекс
//
// Читатель читатель();
// Писатель писатель();
////////////////////////////////////////////////////////////////////////////////

export extern(D) class ЧЗМютекс
{
export:

    enum Политика
    {
        ПОЧЁТ_ЧИТАТЕЛЮ, /// Readers get preference.  This may starve writers.
        ПОЧЁТ_ПИСАТЕЛЮ  /// Writers get preference.  This may starve readers.
    }


    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////

    this( Политика политика = Политика.ПОЧЁТ_ПИСАТЕЛЮ )
    {
        м_общийМютекс = new Мютекс;
        if( !м_общийМютекс )
            throw new ИсключениеСинх( "Не удаётся инициализировать мютекс" );
        scope(failure) delete м_общийМютекс;

        м_очередьЧитателей = new Условие( м_общийМютекс );
        if( !м_очередьЧитателей )
            throw new ИсключениеСинх( "Не удалось инициализировать мютекс" );
        scope(failure) delete м_очередьЧитателей;

        м_очередьПисателей = new Условие( м_общийМютекс );
        if( !м_очередьПисателей )
            throw new ИсключениеСинх( "Не удалось инициализировать мютекс" );
        scope(failure) delete м_очередьПисателей;

        м_политика = политика;
        м_читатель = new Читатель;
        м_писатель = new Писатель;
    }


    ////////////////////////////////////////////////////////////////////////////
    // General Properties
    ////////////////////////////////////////////////////////////////////////////

    Политика политика()
    {
        return м_политика;
    }
    ////////////////////////////////////////////////////////////////////////////
    // Читатель/Писатель Handles
    ////////////////////////////////////////////////////////////////////////////

    Читатель читатель()
    {
        return м_читатель;
    }

    Писатель писатель()
    {
        return м_писатель;
    }


    ////////////////////////////////////////////////////////////////////////////
    // Читатель
    ////////////////////////////////////////////////////////////////////////////

class Читатель :
        Объект.Монитор
    {
	export:
        /**
         * Initializes a read/write mutex читатель proxy object.
         */
        this()
        {
            м_прокси.связка = this;
            (cast(ук*) this)[1] = &м_прокси;
        }

        проц блокируй()
        {
            synchronized( м_общийМютекс )
            {
                ++м_члоЖдущихЧитателей;
                scope(exit) --м_члоЖдущихЧитателей;

                while( shouldQueueReader() )
                    м_очередьЧитателей.жди();
                ++м_члоАктивнЧитателей;
            }
        }

        проц разблокируй()
        {
            synchronized( м_общийМютекс )
            {
                if( --м_члоАктивнЧитателей < 1 )
                {
                    if( м_члоЖдущихПисателей > 0 )
                        м_очередьПисателей.уведоми();
                }
            }
        }

     void lock(){ блокируй();}
	 void unlock(){ разблокируй();}

        bool пытайсяБлокировать()
        {
            synchronized( м_общийМютекс )
            {
                if( shouldQueueReader() )
                    return false;
                ++м_члоАктивнЧитателей;
                return true;
            }
        }


    private:
        bool shouldQueueReader()
        {
            if( м_члоАктивнПисателей > 0 )
                return true;

            switch( м_политика )
            {
            case Политика.ПОЧЁТ_ПИСАТЕЛЮ:
                 return м_члоЖдущихПисателей > 0;

            case Политика.ПОЧЁТ_ЧИТАТЕЛЮ:
            default:
                 break;
            }

        return false;
        }

        struct ПроксиМонитора
        {
            Объект.Монитор связка;
        }

        ПроксиМонитора    м_прокси;
    }


    ////////////////////////////////////////////////////////////////////////////
    // Писатель
    ////////////////////////////////////////////////////////////////////////////
class Писатель :
        Объект.Монитор
    {
	export:
	
        /**
         * Initializes a read/write mutex писатель proxy object.
         */
        this()
        {
            м_прокси.связка = this;
            (cast(ук*) this)[1] = &м_прокси;
        }

        проц блокируй()
        {
            synchronized( м_общийМютекс )
            {
                ++м_члоЖдущихПисателей;
                scope(exit) --м_члоЖдущихПисателей;

                while( поставитьВОчередьПисателя_ли() )
                    м_очередьПисателей.жди();
                ++м_члоАктивнПисателей;
            }
        }

        проц разблокируй()
        {
            synchronized( м_общийМютекс )
            {
                if( --м_члоАктивнПисателей < 1 )
                {
                    switch( м_политика )
                    {
                    default:
                    case Политика.ПОЧЁТ_ЧИТАТЕЛЮ:
                        if( м_члоЖдущихЧитателей > 0 )
                            м_очередьЧитателей.уведомиВсе();
                        else if( м_члоЖдущихПисателей > 0 )
                            м_очередьПисателей.уведоми();
                        break;
                    case Политика.ПОЧЁТ_ПИСАТЕЛЮ:
                        if( м_члоЖдущихПисателей > 0 )
                            м_очередьПисателей.уведоми();
                        else if( м_члоЖдущихЧитателей > 0 )
                            м_очередьЧитателей.уведомиВсе();
                    }
                }
            }
        }
		
    void lock(){ блокируй();}
	 void unlock(){ разблокируй();}

        bool пытайсяБлокировать()
        {
            synchronized( м_общийМютекс )
            {
                if( поставитьВОчередьПисателя_ли() )
                    return false;
                ++м_члоАктивнПисателей;
                return true;
            }
        }


    private:
        bool поставитьВОчередьПисателя_ли()
        {
            if( м_члоАктивнПисателей > 0 ||
                м_члоАктивнЧитателей > 0 )
                return true;
            switch( м_политика )
            {
            case Политика.ПОЧЁТ_ЧИТАТЕЛЮ:
                return м_члоЖдущихЧитателей > 0;

            case Политика.ПОЧЁТ_ПИСАТЕЛЮ:
            default:
                 break;
            }

        return false;
        }

        struct ПроксиМонитора
        {
            Объект.Монитор связка;
        }

        ПроксиМонитора    м_прокси;
    }


private:
    Политика      м_политика;
    Читатель      м_читатель;
    Писатель      м_писатель;

    Мютекс       м_общийМютекс;
    Условие   м_очередьЧитателей;
    Условие   м_очередьПисателей;

    цел         м_члоЖдущихЧитателей;
    цел         м_члоАктивнЧитателей;
    цел         м_члоЖдущихПисателей;
    цел         м_члоАктивнПисателей;
}

/////////////////////////////////////
/+
{ *************************************************************************** }
{                                                                             }
{ Kylix and Delphi Cross-Platform Visual Component Library                    }
{                                                                             }
{ Copyright (c) 1997-2004 Borland Software Corporation                        }
{                                                                             }
{ *************************************************************************** }

unit SyncObjs;

interface

БЕЗАТРЫ *безатры;
alias extern(Windows) цел function(бцел флаги, бцел таймаут, бцел уки, ук[] уки, бцел инд) ПроцЖдатьНескУковКо;
ПроцЖдатьНескУковКо процЖНУК;

ук окНитиОле;

const
{
  сим ИмяОкКлассаОле = 'OleMainThreadWndClass'; //do not localize
  COWAIT_WAITALL = x00000001;
  COWAIT_ALERTABLE = x00000002;
}

ук дайОкноПотокаОле()
{
ук дочОк, родОк;

  if (окНитиОле == 0 || !IsWindow(окНитиОле))
   {
    if (Win32Platform == VER_PLATFORM_WIN32_NT ||Win32MajorVersion >= 5)
      родОк = HWND_MESSAGE;
     else
	 {
      родОк = 0;
      дочОк = 0;	 
		do
		{
		  окНитиОле = cast(ук) FindWindowEx(родОк, дочОк, ИмяОкКлассаОле, пусто);
		  дочОк = окНитиОле;
		}
		while (окНитиОле == 0 ||GetWindowThreadProcessId(окНитиОле, пусто) == GetCurrentThreadId() );
	}
  return окНитиОле;
}

class СинхроОбъект
{
  public:  
  проц взять(){}
  проц освободить(){}
}

enum  РезОжидания
	{
	роСигнализированный,
	роТаймаут,
	роПокинутый,
	роОшибка
	}

 class УкзОбъект:  СинхроОбъект
{
  protected
    ук м_укз;
    цел м_послОш;
    бул м_испКОМЖди;
	
  public
    this(бул испКОМЖди = нет){}
    ~this(){}

    РезОжидания ждатьвтеч(дол таймаут){}

    цел послОшиб(цел по = 0){if(по !=0) м_послОш = по; return послОш;}
    ук укз(ук указ = пусто){if(указ) м_укз = указ; return укз;}
}

class Событие : УкзОбъект  
{
  public
    this(БЕЗАТРЫ *атрыСоб, бул ручнСброс, бул начСост, ткст имя, испКОМЖди = нет){}	
    this(испКОМЖди = нет){}
    проц устСоб(){}
	проц сбросьСоб(){}
}

 
class ПростоеСобытие: Событие{}

class Мютекс: УкзОбъект
{
  public
    this(бул испКОМЖди = нет){}
    this(БЕЗАТРЫ *атрыМютекса, бул начВладелец, ткст имя, бул испКОМЖди = нет){}
    this(бцел необхДоступ, бул наследУказ, ткст имя, бул испКОМЖди = нет){}
    override проц взять(){}
	override проц освободить(){}
}

 class КритСекция:СинхроОбъект
 {
  protected
    КРИТСЕКЦ м_секц;
  public
    this(){}
    ~this(){}
    override проц взять(){}
	override проц освободить(){}
    бул пробуйВойти(){}
    проц войди(){}
    проц выйди(){}
}

implementation


function InternalCoWaitForMultipleHandles(dwFlags: DWORD; dwTimeOut: DWORD;
  cHandles: LongWord; var Handles; var lpdwIndex: DWORD): HRESULT; stdcall;
var
  WaitResult: DWORD;
  OleThreadWnd: HWnd;
  Msg: TMsg;
begin
  WaitResult := 0; // supress warning
  OleThreadWnd := GetOleThreadWindow;
  if OleThreadWnd <> 0 then
    while True do
    begin
      WaitResult := MsgWaitForMultipleObjectsEx(cHandles, Handles, dwTimeOut, QS_ALLEVENTS, dwFlags);
      if WaitResult = WAIT_OBJECT_0 + cHandles then
      begin
        if PeekMessage(Msg, OleThreadWnd, 0, 0, PM_REMOVE) then
        begin
          TranslateMessage(Msg);
          DispatchMessage(Msg);
        end;
      end else
        Break;
    end
  else
    WaitResult := WaitForMultipleObjectsEx(cHandles, @Handles,
      dwFlags and COWAIT_WAITALL <> 0, dwTimeOut, dwFlags and COWAIT_ALERTABLE <> 0);
  if WaitResult = WAIT_TIMEOUT then
    Result := RPC_E_TIMEOUT
  else if WaitResult = WAIT_IO_COMPLETION then
    Result := RPC_S_CALLPENDING
  else
  begin
    Result := S_OK;
    if (WaitResult >= WAIT_ABANDONED_0) and (WaitResult < WAIT_ABANDONED_0 + cHandles) then
      lpdwIndex := WaitResult - WAIT_ABANDONED_0
    else
      lpdwIndex := WaitResult - WAIT_OBJECT_0;
  end;
end;

function CoWaitForMultipleHandles(dwFlags: DWORD; dwTimeOut: DWORD;
  cHandles: LongWord; var Handles; var lpdwIndex: DWORD): HRESULT;

  procedure LookupProc;
  var
    Ole32Handle: HMODULE;
  begin
    Ole32Handle := GetModuleHandle('ole32.dll'); //do not localize
    if Ole32Handle <> 0 then
      CoWaitForMultipleHandlesProc := GetProcAddress(Ole32Handle, 'CoWaitForMultipleHandles'); //do not localize
    if not Assigned(CoWaitForMultipleHandlesProc) then
      CoWaitForMultipleHandlesProc := InternalCoWaitForMultipleHandles;
  end;

begin
  if not Assigned(CoWaitForMultipleHandlesProc) then
    LookupProc;
  Result := CoWaitForMultipleHandlesProc(dwFlags, dwTimeOut, cHandles, Handles, lpdwIndex)
end;

{ СинхроОбъект }

procedure СинхроОбъект.Acquire;
begin
end;

procedure СинхроОбъект.Release;
begin
end;

{ УкОбъект }

{$IFDEF MSWINDOWS}
constructor УкОбъект.Create(UseComWait: Boolean);
begin
  inherited Create;
  FUseCOMWait := UseCOMWait;
end;

destructor УкОбъект.Destroy;
begin
  CloseHandle(FHandle);
  inherited Destroy;
end;
{$ENDIF}

function УкОбъект.WaitFor(Timeout: LongWord): РезОжидания;
var
  Index: DWORD;
begin
{$IFDEF MSWINDOWS}
  if FUseCOMWait then
  begin
    case CoWaitForMultipleHandles(0, TimeOut, 1, FHandle, Index) of
      S_OK: Result := роСигнализированный;
      RPC_S_CALLPENDING,
      RPC_E_TIMEOUT: Result := роТаймаут;
    else
      Result := роОшибка;
      FLastError := GetLastError;
    end;
  end else
  begin
    case WaitForSingleObject(Handle, Timeout) of
      WAIT_ABANDONED: Result := роПокинутый;
      WAIT_OBJECT_0: Result := роСигнализированный;
      WAIT_TIMEOUT: Result := роТаймаут;
      WAIT_FAILED:
        begin
          Result := роОшибка;
          FLastError := GetLastError;
        end;
    else
      Result := роОшибка;
    end;
  end;
{$ENDIF}
{$IFDEF LINUX}
  Result := роОшибка;
{$ENDIF}
end;

{ TEvent }

constructor TEvent.Create(EventAttributes: PSecurityAttributes; ManualReset,
  InitialState: Boolean; const Name: ткст; UseCOMWait: Boolean);
{$IFDEF MSWINDOWS}
begin
  inherited Create(UseCOMWait);
  FHandle := CreateEvent(EventAttributes, ManualReset, InitialState, PChar(Name));
end;
{$ENDIF}
{$IFDEF LINUX}
var
   Value: Integer;
begin
  if InitialState then
    Value := 1
  else
    Value := 0;

  FManualReset := ManualReset;

  sem_init(FEvent, False, Value);
end;
{$ENDIF}

constructor TEvent.Create(UseCOMWait: Boolean);
begin
  Create(nil, True, False, '', UseCOMWait);
end;

{$IFDEF LINUX}
function TEvent.WaitFor(Timeout: LongWord): РезОжидания;
begin
  if Timeout = LongWord($FFFFFFFF) then
  begin
    sem_wait(FEvent);
    Result := роСигнализированный;
  end
  else if FManualReset then
    sem_post(FEvent)
  else
    Result := роОшибка;
end;
{$ENDIF}

procedure TEvent.SetEvent;
{$IFDEF MSWINDOWS}
begin
  Windows.SetEvent(Handle);
end;
{$ENDIF}
{$IFDEF LINUX}
var
  I: Integer;
begin
  sem_getvalue(FEvent, I);
  if I = 0 then
    sem_post(FEvent);
end;
{$ENDIF}

procedure TEvent.ResetEvent;
begin
{$IFDEF MSWINDOWS}
  Windows.ResetEvent(Handle);
{$ENDIF}
{$IFDEF LINUX}
  while sem_trywait(FEvent) = 0 do { nothing };
{$ENDIF}
end;

{ TCriticalSection }

constructor TCriticalSection.Create;
begin
  inherited Create;
  InitializeCriticalSection(FSection);
end;

destructor TCriticalSection.Destroy;
begin
  DeleteCriticalSection(FSection);
  inherited Destroy;
end;

procedure TCriticalSection.Acquire;
begin
  EnterCriticalSection(FSection);
end;

procedure TCriticalSection.Release;
begin
  LeaveCriticalSection(FSection);
end;

function TCriticalSection.TryEnter: Boolean;
begin
  Result := TryEnterCriticalSection(FSection);
end;

procedure TCriticalSection.Enter;
begin
  Acquire;
end;

procedure TCriticalSection.Leave;
begin
  Release;
end;

{ TMutex }

procedure TMutex.Acquire;
begin
  if WaitFor(INFINITE) = роОшибка then
    RaiseLastOSError;
end;

constructor TMutex.Create(UseCOMWait: Boolean);
begin
  Create(nil, False, '', UseCOMWait);
end;

constructor TMutex.Create(MutexAttributes: PSecurityAttributes;
  InitialOwner: Boolean; const Name: ткст; UseCOMWait: Boolean);
var
  lpName: PChar;
begin
  inherited Create(UseCOMWait);
  if Name <> '' then
    lpName := PChar(Name)
  else
    lpName := nil;
  FHandle := CreateMutex(MutexAttributes, InitialOwner, lpName);
  if FHandle = 0 then
    RaiseLastOSError;
end;

constructor TMutex.Create(DesiredAccess: LongWord; InheritHandle: Boolean;
  const Name: ткст; UseCOMWait: Boolean);
var
  lpName: PChar;
begin
  inherited Create(UseCOMWait);
  if Name <> '' then
    lpName := PChar(Name)
  else
    lpName := nil;
  FHandle := OpenMutex(DesiredAccess, InheritHandle, lpName);
  if FHandle = 0 then
    RaiseLastOSError;
end;

procedure TMutex.Release;
begin
  if not ReleaseMutex(FHandle) then
    RaiseLastOSError;
end;

end.
+/