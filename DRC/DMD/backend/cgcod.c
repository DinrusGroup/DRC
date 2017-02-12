// Copyright (C) 1985-1998 by Symantec
// Copyright (C) 2000-2009 by Digital Mars
// All Rights Reserved
// http://www.digitalmars.com
// Written by Walter Bright
/*
 * This source file is made available for personal use
 * only. The license is in /dmd/src/dmd/backendlicense.txt
 * or /dm/src/dmd/backendlicense.txt.
 * For any other uses, please contact Digital Mars.
 */

#if !SPP

#include        <stdio.h>
#include        <string.h>
#include        <stdlib.h>
#include        <time.h>

#if __sun&&__SVR4
#include        <alloca.h>
#endif

#include        "cc.h"
#include        "el.h"
#include        "oper.h"
#include        "code.h"
#include        "global.h"
#include        "type.h"
#include        "exh.h"

static char __file__[] = __FILE__;      /* for tassert.h                */
#include        "tassert.h"

STATIC void resetEcomsub(elem *e);
STATIC code * loadcse(elem *,unsigned,regm_t);
STATIC void blcodgen(block *);
STATIC void cgcod_eh();
STATIC code * cse_save(regm_t ms);
STATIC int cse_simple(elem *e,int i);
STATIC code * comsub(elem *,regm_t *);

bool floatreg;                  // !=0 if floating register is required

targ_size_t Aoffset;            // offset of automatics and registers
targ_size_t Toffset;            // offset of temporaries
targ_size_t EEoffset;           // offset of SCstack variables from ESP
int Aalign;                     // alignment for Aoffset

REGSAVE regsave;

CGstate cgstate;                // state of code generator

/************************************
 * # of bytes that SP is beyond BP.
 */

unsigned stackpush;

int stackchanged;               /* set to !=0 if any use of the stack
                                   other than accessing parameters. Used
                                   to see if we can address parameters
                                   with ESP rather than EBP.
                                 */
int refparam;           // !=0 if we referenced any parameters
int reflocal;           // !=0 if we referenced any locals
char anyiasm;           // !=0 if any inline assembler
char calledafunc;       // !=0 if we called a function
char needframe;         // if TRUE, then we will need the frame
                        // pointer (BP for the 8088)
char usedalloca;        // if TRUE, then alloca() was called
char gotref;            // !=0 if the GOTsym was referenced
unsigned usednteh;              // if !=0, then used NT exception handling

/* Register contents    */
con_t regcon;

int pass;                       // PASSxxxx

static symbol *retsym;          // set to symbol that should be placed in
                                // register AX

/****************************
 * Register masks.
 */

regm_t msavereg;        // Mask of registers that we would like to save.
                        // they are temporaries (set by scodelem())
regm_t mfuncreg;        // Mask of registers preserved by a function
regm_t allregs;         // ALLREGS optionally including mBP

int dfoidx;                     /* which block we are in                */
struct CSE *csextab = NULL;     /* CSE table (allocated for each function) */
unsigned cstop;                 /* # of entries in CSE table (csextab[])   */
unsigned csmax;                 /* amount of space in csextab[]         */

targ_size_t     funcoffset;     // offset of start of function
targ_size_t     startoffset;    // size of function entry code
targ_size_t     retoffset;      /* offset from start of func to ret code */
targ_size_t     retsize;        /* size of function return              */

static regm_t lastretregs,last2retregs,last3retregs,last4retregs,last5retregs;

/*********************************
 * Generate code for a function.
 * Note at the end of this routine mfuncreg will contain the mask
 * of registers not affected by the function. Some minor optimization
 * possibilities are here...
 */

void codgen()
{   block *b,*bn;
    bool flag;
    int i;
    targ_size_t swoffset,coffset;
    tym_t functy;
    unsigned nretblocks;                // number of return blocks
    code *cprolog;
    regm_t noparams;
#if SCPP
    block *btry;
#endif
    // Register usage. If a bit is on, the corresponding register is live
    // in that basic block.

    //printf("codgen('%s')\n",funcsym_p->Sident);

    cgreg_init();
    csmax = 64;
    csextab = (struct CSE *) util_calloc(sizeof(struct CSE),csmax);
    functy = tybasic(funcsym_p->ty());
#if TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
    if (0 && config.flags3 & CFG3pic)
    {
        ALLREGS = ALLREGS_INIT_PIC;
        BYTEREGS = BYTEREGS_INIT_PIC;
    }
    else
    {
        regm_t value = BYTEREGS_INIT;
        ALLREGS = ALLREGS_INIT;
        BYTEREGS = value;
    }
    if (I64)
    {   ALLREGS = mAX|mBX|mCX|mDX|mSI|mDI| mR8|mR9|mR10|mR11|mR12|mR13|mR14|mR15;
        BYTEREGS = ALLREGS;
    }
#endif
    allregs = ALLREGS;
    if (0 && config.flags3 & CFG3pic)
        allregs &= ~mBX;
    pass = PASSinit;

tryagain:
    #ifdef DEBUG
    if (debugr)
        printf("------------------ PASS%s -----------------\n",
            (pass == PASSinit) ? "init" : ((pass == PASSreg) ? "reg" : "final"));
    #endif
    lastretregs = last2retregs = last3retregs = last4retregs = last5retregs = 0;

    // if no parameters, assume we don't need a stack frame
    needframe = 0;
    usedalloca = 0;
    gotref = 0;
    stackchanged = 0;
    stackpush = 0;
    refparam = 0;
    anyiasm = 0;
    calledafunc = 0;
    cgstate.stackclean = 1;
    retsym = NULL;

    regsave.reset();
    memset(_8087elems,0,sizeof(_8087elems));

    usednteh = 0;
#if (MARS) && TARGET_WINDOS
    if (funcsym_p->Sfunc->Fflags3 & Fjmonitor)
        usednteh |= NTEHjmonitor;
#else
    if (CPP)
    {
        if (config.flags2 & CFG2seh &&
            (funcsym_p->Stype->Tflags & TFemptyexc || funcsym_p->Stype->Texcspec))
            usednteh |= NTEHexcspec;
        except_reset();
    }
#endif

    floatreg = FALSE;
    assert(stackused == 0);             /* nobody in 8087 stack         */
    cstop = 0;                          /* no entries in table yet      */
    memset(&regcon,0,sizeof(regcon));
    regcon.cse.mval = regcon.cse.mops = 0;      // no common subs yet
#if 0 && TARGET_LINUX
    if (!(allregs & mBX))
        msavereg = mBX;
    else
#endif
        msavereg = 0;
    nretblocks = 0;
    mfuncreg = fregsaved;               // so we can see which are used
                                        // (bit is cleared each time
                                        //  we use one)
    for (b = startblock; b; b = b->Bnext)
    {   memset(&b->Bregcon,0,sizeof(b->Bregcon));       // Clear out values in registers
        if (b->Belem)
            resetEcomsub(b->Belem);     // reset all the Ecomsubs
        if (b->BC == BCasm)
            anyiasm = 1;                // we have inline assembler
        if (b->BC == BCret || b->BC == BCretexp)
            nretblocks++;
    }

    if (!config.fulltypes || (config.flags4 & CFG4optimized))
    {
        noparams = 0;
        for (i = 0; i < globsym.top; i++)
        {
            Symbol *s = globsym.tab[i];
            s->Sflags &= ~SFLread;
            switch (s->Sclass)
            {   case SCfastpar:
                    regcon.params |= mask[s->Spreg];
                case SCparameter:
                    if (s->Sfl == FLreg)
                        noparams |= s->Sregm;
                    break;
            }
        }
        regcon.params &= ~noparams;
    }

    if (config.flags4 & CFG4optimized)
    {
        if (nretblocks == 0)                    // if no return blocks in function
            funcsym_p->Sflags |= SFLexit;       // mark function as never returning

        assert(dfo);

        cgreg_reset();
        for (dfoidx = 0; dfoidx < dfotop; dfoidx++)
        {   regcon.used = msavereg | regcon.cse.mval;   // registers already in use
            b = dfo[dfoidx];
            blcodgen(b);                        // gen code in depth-first order
            //printf("b->Bregcon.used = x%x\n", b->Bregcon.used);
            cgreg_used(dfoidx,b->Bregcon.used); // gather register used information
        }
    }
    else
    {   pass = PASSfinal;
        for (b = startblock; b; b = b->Bnext)
            blcodgen(b);                // generate the code for each block
    }
    regcon.immed.mval = 0;
    assert(!regcon.cse.mops);           // should have all been used

    // See which variables we can put into registers
    if (pass != PASSfinal &&
        !anyiasm)                               // possible LEA or LES opcodes
    {
        allregs |= cod3_useBP();                // see if we can use EBP

        // If pic code, but EBX was never needed
        if (!(allregs & mBX) && !gotref)
        {   allregs |= mBX;                     // EBX can now be used
            cgreg_assign(retsym);
            pass = PASSreg;
        }
        else if (cgreg_assign(retsym))          // if we found some registers
            pass = PASSreg;
        else
            pass = PASSfinal;
        for (b = startblock; b; b = b->Bnext)
        {   code_free(b->Bcode);
            b->Bcode = NULL;
        }
        goto tryagain;
    }
    cgreg_term();

#if SCPP
    if (CPP)
        cgcod_eh();
#endif

    stackoffsets(1);            // compute addresses of stack variables
    cod5_prol_epi();            // see where to place prolog/epilog

    // Get rid of unused cse temporaries
    while (cstop != 0 && (csextab[cstop - 1].flags & CSEload) == 0)
        cstop--;

    if (configv.addlinenumbers)
        objlinnum(funcsym_p->Sfunc->Fstartline,Coffset);

    // Otherwise, jmp's to startblock will execute the prolog again
    assert(!startblock->Bpred);

    cprolog = prolog();                 // gen function start code
    if (cprolog)
        pinholeopt(cprolog,NULL);       // optimize

    funcoffset = Coffset;
    coffset = Coffset;

    if (eecontext.EEelem)
    {   regm_t retregs;
        code *c;

        eecontext.EEin++;
        regcon.immed.mval = 0;
        retregs = 0;    //regmask(eecontext.EEelem->Ety);
        assert(EEoffset >= REGSIZE);
        c = genc2(NULL,0x81,modregrm(3,5,SP),EEoffset - REGSIZE); // SUB ESP,EEoffset
        gen1(c,0x50 + SI);                      // PUSH ESI
        genadjesp(c,EEoffset);
        c = gencodelem(c,eecontext.EEelem,&retregs, FALSE);
        assignaddrc(c);
        pinholeopt(c,NULL);
        jmpaddr(c);
        eecontext.EEcode = gen1(c,0xCC);        // INT 3
        eecontext.EEin--;
    }

    for (b = startblock; b; b = b->Bnext)
    {
        // We couldn't do this before because localsize was unknown
        switch (b->BC)
        {   case BCret:
                if (configv.addlinenumbers && b->Bsrcpos.Slinnum && !(funcsym_p->ty() & mTYnaked))
                    cgen_linnum(&b->Bcode,b->Bsrcpos);
            case BCretexp:
                epilog(b);
                break;
            default:
                if (b->Bflags & BFLepilog)
                    epilog(b);
                break;
        }
        assignaddr(b);                  // assign addresses
        pinholeopt(b->Bcode,b);         // do pinhole optimization
        if (b->Bflags & BFLprolog)      // do function prolog
        {
            startoffset = coffset + calcblksize(cprolog) - funcoffset;
            b->Bcode = cat(cprolog,b->Bcode);
        }
        if (config.flags4 & CFG4speed &&
            config.target_cpu >= TARGET_Pentium &&
            b->BC != BCasm
           )
        {   regm_t scratch;

            scratch = allregs & ~(b->Bregcon.used | b->Bregcon.params | mfuncreg);
            scratch &= ~(b->Bregcon.immed.mval | b->Bregcon.cse.mval);
            cgsched_pentium(&b->Bcode,scratch);
            //printf("after schedule:\n"); WRcodlst(b->Bcode);
        }
        b->Bsize = calcblksize(b->Bcode);       // calculate block size
        if (b->Balign)
        {   targ_size_t u = b->Balign - 1;

            coffset = (coffset + u) & ~u;
        }
        b->Boffset = coffset;           /* offset of this block         */
        coffset += b->Bsize;            /* offset of following block    */
    }
#ifdef DEBUG
    debugw && printf("code addr complete\n");
#endif

    // Do jump optimization
    do
    {   flag = FALSE;
        for (b = startblock; b; b = b->Bnext)
        {   if (b->Bflags & BFLjmpoptdone)      /* if no more jmp opts for this blk */
                continue;
            i = branch(b,0);            // see if jmp => jmp short
            if (i)                      /* if any bytes saved           */
            {   targ_size_t offset;

                b->Bsize -= i;
                offset = b->Boffset + b->Bsize;
                for (bn = b->Bnext; bn; bn = bn->Bnext)
                {
                    if (bn->Balign)
                    {   targ_size_t u = bn->Balign - 1;

                        offset = (offset + u) & ~u;
                    }
                    bn->Boffset = offset;
                    offset += bn->Bsize;
                }
                coffset = offset;
                flag = TRUE;
            }
        }
        if (!I16 && !(config.flags4 & CFG4optimized))
            break;                      // use the long conditional jmps
    } while (flag);                     // loop till no more bytes saved
#ifdef DEBUG
    debugw && printf("code jump optimization complete\n");
#endif

    // Compute starting offset for switch tables
#if ELFOBJ || MACHOBJ
    swoffset = (config.flags & CFGromable) ? coffset : CDoffset;
#else
    swoffset = (config.flags & CFGromable) ? coffset : Doffset;
#endif
    swoffset = align(0,swoffset);

    // Emit the generated code
    if (eecontext.EEcompile == 1)
    {
        codout(eecontext.EEcode);
        code_free(eecontext.EEcode);
#if SCPP
        el_free(eecontext.EEelem);
#endif
    }
    else
    {
        for (b = startblock; b; b = b->Bnext)
        {
            if (b->BC == BCjmptab || b->BC == BCswitch)
            {   b->Btableoffset = swoffset;     /* offset of sw tab */
                swoffset += b->Btablesize;
            }
            jmpaddr(b->Bcode);          /* assign jump addresses        */
#ifdef DEBUG
            if (debugc)
            {   printf("Boffset = x%lx, Bsize = x%lx, Coffset = x%lx\n",
                    (long)b->Boffset,(long)b->Bsize,(long)Coffset);
                if (b->Bcode)
                    printf( "First opcode of block is: %0x\n", b->Bcode->Iop );
            }
#endif
            if (b->Balign)
            {   unsigned u = b->Balign;
                unsigned nalign = (u - (unsigned)Coffset) & (u - 1);

                while (nalign--)
                    obj_byte(cseg,Coffset++,0x90);      // XCHG AX,AX
            }
            assert(b->Boffset == Coffset);

#if SCPP
            if (CPP &&
                !(config.flags2 & CFG2seh))
            {
                //printf("b = %p, index = %d\n",b,b->Bindex);
                //except_index_set(b->Bindex);

                if (btry != b->Btry)
                {
                    btry = b->Btry;
                    except_pair_setoffset(b,Coffset - funcoffset);
                }
                if (b->BC == BCtry)
                {
                    btry = b;
                    except_pair_setoffset(b,Coffset - funcoffset);
                }
            }
#endif
            codout(b->Bcode);   // output code
    }
    if (coffset != Coffset)
    {
#ifdef DEBUG
        printf("coffset = %ld, Coffset = %ld\n",(long)coffset,(long)Coffset);
#endif
        assert(0);
    }
    funcsym_p->Ssize = Coffset - funcoffset;    // size of function

#if NTEXCEPTIONS || MARS
#if (SCPP && NTEXCEPTIONS)
    if (usednteh & NTEHcpp)
#elif MARS
        if (usednteh & NTEH_try)
#endif
    {   assert(!(config.flags & CFGromable));
        //printf("framehandleroffset = x%x, coffset = x%x\n",framehandleroffset,coffset);
        reftocodseg(cseg,framehandleroffset,coffset);
    }
#endif


    // Write out switch tables
    flag = FALSE;                       // TRUE if last active block was a ret
    for (b = startblock; b; b = b->Bnext)
    {
        switch (b->BC)
        {   case BCjmptab:              /* if jump table                */
                outjmptab(b);           /* write out jump table         */
                break;
            case BCswitch:
                outswitab(b);           /* write out switch table       */
                break;
            case BCret:
            case BCretexp:
                /* Compute offset to return code from start of function */
                retoffset = b->Boffset + b->Bsize - retsize - funcoffset;
#if MARS
                /* Add 3 bytes to retoffset in case we have an exception
                 * handler. THIS PROBABLY NEEDS TO BE IN ANOTHER SPOT BUT
                 * IT FIXES THE PROBLEM HERE AS WELL.
                 */
                if (usednteh & NTEH_try)
                    retoffset += 3;
#endif
                flag = TRUE;
                break;
            case BCexit:
                // Fake it to keep debugger happy
                retoffset = b->Boffset + b->Bsize - funcoffset;
                break;
        }
        code_free(b->Bcode);
        b->Bcode = NULL;
    }
    if (flag && configv.addlinenumbers && !(funcsym_p->ty() & mTYnaked))
        /* put line number at end of function on the
           start of the last instruction
         */
        /* Instead, try offset to cleanup code  */
        objlinnum(funcsym_p->Sfunc->Fendline,funcoffset + retoffset);

#if MARS
    if (usednteh & NTEH_try)
    {
        nteh_gentables();
    }
    if (usednteh & EHtry)
    {
        except_gentables();
    }
#endif

#if SCPP
#if NTEXCEPTIONS
    // Write out frame handler
    if (usednteh & NTEHcpp)
        nteh_framehandler(except_gentables());
    else
#endif
    {
#if NTEXCEPTIONS
        if (usednteh & NTEH_try)
            nteh_gentables();
        else
#endif
        {
            if (CPP)
                except_gentables();
        }
        ;
    }
#endif
    }

    // Mask of regs saved
    // BUG: do interrupt functions save BP?
    funcsym_p->Sregsaved = (functy == TYifunc) ? mBP : (mfuncreg | fregsaved);

    util_free(csextab);
    csextab = NULL;
#ifdef DEBUG
    if (stackused != 0)
          printf("stackused = %d\n",stackused);
#endif
    assert(stackused == 0);             /* nobody in 8087 stack         */

    /* Clean up ndp save array  */
    mem_free(NDP::save);
    NDP::save = NULL;
    NDP::savetop = 0;
    NDP::savemax = 0;
}


/******************************
 * Compute offsets for remaining tmp, automatic and register variables
 * that did not make it into registers.
 */

void stackoffsets(int flags)
{
    symbol *s;
    targ_size_t Amax,sz;
    unsigned alignsize;
    int offi;
    targ_size_t offstack[20];
    vec_t tbl = NULL;


    //printf("stackoffsets()\n");
    if (config.flags4 & CFG4optimized)
    {
        tbl = vec_calloc(globsym.top);
    }
    offi = 0;                           // index into offstack[]
    Aoffset = 0;                        // automatic & register offset
    Toffset = 0;                        // temporary offset
    Poffset = 0;                        // parameter offset
    EEoffset = 0;                       // for SCstack's
    Amax = 0;
    Aalign = REGSIZE;
    for (int pass = 0; pass < 2; pass++)
    {
        for (int si = 0; si < globsym.top; si++)
        {   s = globsym.tab[si];
            if (s->Sflags & SFLdead ||
                (!anyiasm && !(s->Sflags & SFLread) && s->Sflags & SFLunambig &&
#if MARS
                 /* mTYvolatile was set if s has been reference by a nested function
                  * meaning we'd better allocate space for it
                  */
                 !(s->Stype->Tty & mTYvolatile) &&
#endif
                 (config.flags4 & CFG4optimized || !config.fulltypes))
                )
                sz = 0;
            else
            {   sz = type_size(s->Stype);
                if (sz == 0)
                    sz++;               // can't handle 0 length structs
            }
            alignsize = type_alignsize(s->Stype);

            //printf("symbol '%s', size = x%lx, align = %d, read = %x\n",s->Sident,(long)sz, (int)type_alignsize(s->Stype), s->Sflags & SFLread);
            assert((int)sz >= 0);

            if (pass == 1)
            {
                if (s->Sclass == SCfastpar)     // if parameter s is passed in a register
                {
                    /* Allocate in second pass in order to get these
                     * right next to the stack frame pointer, EBP.
                     * Needed so we can call nested contract functions
                     * frequire and fensure.
                     */
                    if (s->Sfl == FLreg)        // if allocated in register
                        continue;
                    /* Needed because storing fastpar's on the stack in prolog()
                     * does the entire register
                     */
                    if (sz < REGSIZE)
                        sz = REGSIZE;

                    Aoffset = align(sz,Aoffset);
                    s->Soffset = Aoffset;
                    Aoffset += sz;
                    if (Aoffset > Amax)
                        Amax = Aoffset;
                    //printf("fastpar '%s' sz = %d, auto offset =  x%lx\n",s->Sident,sz,(long)s->Soffset);

                    // Align doubles to 8 byte boundary
                    if (!I16 && alignsize > REGSIZE)
                        Aalign = alignsize;
                }
                continue;
            }

            /* Can't do this for CPP because the inline function expander
                adds new symbols on the end.
             */
#if AUTONEST
            /*printf("symbol '%s', push = %d, pop = %d\n",
                s->Sident,s->Spush,s->Spop);*/

            /* Can't do this for optimizer if any code motion occurred.
                Code motion changes the live range, so variables that
                occupy the same space could have live ranges that overlap!
             */
            if (config.flags4 & CFG4optimized)
                s->Spop = 0;
            else
                while (s->Spush != 0)
                {   s->Spush--;
                    assert(offi < arraysize(offstack));
                    /*printf("Pushing offset x%x\n",Aoffset);*/
                    offstack[offi++] = Aoffset;
                }
#endif

            switch (s->Sclass)
            {
                case SCfastpar:
                    break;              // ignore on pass 0
                case SCregister:
                case SCauto:
                    if (s->Sfl == FLreg)        // if allocated in register
                        break;
                    // See if we can share storage with another variable
                    if (config.flags4 & CFG4optimized &&
                        // Don't share because could stomp on variables
                        // used in finally blocks
                        !(usednteh & ~NTEHjmonitor) &&
                        s->Srange && sz && flags && !(s->Sflags & SFLspill))
                    {
                        for (int i = 0; i < si; i++)
                        {
                            if (!vec_testbit(i,tbl))
                                continue;
                            symbol *sp = globsym.tab[i];
//printf("auto    s = '%s', sp = '%s', %d, %d, %d\n",s->Sident,sp->Sident,dfotop,vec_numbits(s->Srange),vec_numbits(sp->Srange));
                            if (vec_disjoint(s->Srange,sp->Srange) &&
                                sz <= type_size(sp->Stype))
                            {
                                vec_or(sp->Srange,sp->Srange,s->Srange);
                                //printf("sharing space - '%s' onto '%s'\n",s->Sident,sp->Sident);
                                s->Soffset = sp->Soffset;
                                goto L2;
                            }
                        }
                    }
                    Aoffset = align(sz,Aoffset);
                    s->Soffset = Aoffset;
                    //printf("auto    '%s' sz = %d, auto offset =  x%lx\n",s->Sident,sz,(long)s->Soffset);
                    Aoffset += sz;
                    if (Aoffset > Amax)
                        Amax = Aoffset;
                    if (s->Srange && sz && !(s->Sflags & SFLspill))
                        vec_setbit(si,tbl);

                    // Align doubles to 8 byte boundary
                    if (!I16 && type_alignsize(s->Stype) > REGSIZE)
                        Aalign = type_alignsize(s->Stype);
                L2:
                    break;

                case SCtmp:
                    // Allocated separately from SCauto to avoid storage
                    // overlapping problems.
                    Toffset = align(sz,Toffset);
                    s->Soffset = Toffset;
                    //printf("tmp offset =  x%lx\n",(long)s->Soffset);
                    Toffset += sz;
                    break;

                case SCstack:
                    EEoffset = align(sz,EEoffset);
                    s->Soffset = EEoffset;
                    //printf("EEoffset =  x%lx\n",(long)s->Soffset);
                    EEoffset += sz;
                    break;

                case SCparameter:
                    Poffset = align(REGSIZE,Poffset); /* align on word stack boundary */
                    if (I64 && alignsize == 16 && Poffset & 8)
                        Poffset += 8;
                    s->Soffset = Poffset;
                    //printf("%s param offset =  x%lx, alignsize = %d\n",s->Sident,(long)s->Soffset, (int)alignsize);
                    Poffset += (s->Sflags & SFLdouble)
                                ? type_size(tsdouble)   // float passed as double
                                : type_size(s->Stype);
                    break;
                case SCpseudo:
                case SCstatic:
                case SCbprel:
                    break;
                default:
#ifdef DEBUG
                    symbol_print(s);
#endif
                    assert(0);
            }

#if AUTONEST
            while (s->Spop != 0)
            {   s->Spop--;
                assert(offi > 0);
                Aoffset = offstack[--offi];
                /*printf("Popping offset x%x\n",Aoffset);*/
            }
#endif
        }
    }
    Aoffset = Amax;
    Aoffset = align(0,Aoffset);
    if (Aalign > REGSIZE)
        Aoffset = (Aoffset + Aalign - 1) & ~(Aalign - 1);
    //printf("Aligned Aoffset = x%lx, Toffset = x%lx\n", (long)Aoffset,(long)Toffset);
    Toffset = align(0,Toffset);

    if (config.flags4 & CFG4optimized)
    {
        vec_free(tbl);
    }
}

/****************************
 * Generate code for a block.
 */

STATIC void blcodgen(block *bl)
{   regm_t retregs;
    bool jcond;
    elem *e;
    code *c;
    block *nextb;
    block *bs1,*bs2;
    list_t bpl;
    int refparamsave;
    regm_t mfuncregsave = mfuncreg;
    char *sflsave = NULL;
    int anyspill;

    //dbg_printf("blcodgen(%p)\n",bl);

    /* Determine existing immediate values in registers by ANDing
        together the values from all the predecessors of b.
     */
    assert(bl->Bregcon.immed.mval == 0);
    regcon.immed.mval = 0;      // assume no previous contents in registers
//    regcon.cse.mval = 0;
    for (bpl = bl->Bpred; bpl; bpl = list_next(bpl))
    {   block *bp = list_block(bpl);

        if (bpl == bl->Bpred)
        {   regcon.immed = bp->Bregcon.immed;
            regcon.params = bp->Bregcon.params;
//          regcon.cse = bp->Bregcon.cse;
        }
        else
        {   int i;

            regcon.params &= bp->Bregcon.params;
            if ((regcon.immed.mval &= bp->Bregcon.immed.mval) != 0)
                // Actual values must match, too
                for (i = 0; i < REGMAX; i++)
                {
                    if (regcon.immed.value[i] != bp->Bregcon.immed.value[i])
                        regcon.immed.mval &= ~mask[i];
                }
#if 0
            if ((regcon.cse.mval &= bp->Bregcon.cse.mval) != 0)
                // Actual values must match, too
                for (i = 0; i < REGMAX; i++)
                {
                    if (regcon.cse.value[i] != bp->Bregcon.cse.value[i])
                        regcon.cse.mval &= ~mask[i];
                }
#endif
        }
    }
    regcon.cse.mops &= regcon.cse.mval;

    // Set regcon.mvar according to what variables are in registers for this block
    c = NULL;
    regcon.mvar = 0;
    regcon.mpvar = 0;
    regcon.indexregs = 1;
    anyspill = 0;
    if (config.flags4 & CFG4optimized)
    {   SYMIDX i;
        code *cload = NULL;
        code *cstore = NULL;

        sflsave = (char *) alloca(globsym.top * sizeof(char));
        for (i = 0; i < globsym.top; i++)
        {   symbol *s = globsym.tab[i];

            sflsave[i] = s->Sfl;
            if (s->Sclass & SCfastpar &&
                regcon.params & mask[s->Spreg] &&
                vec_testbit(dfoidx,s->Srange))
            {
                regcon.used |= mask[s->Spreg];
            }

            if (s->Sfl == FLreg)
            {   if (vec_testbit(dfoidx,s->Srange))
                {   regcon.mvar |= s->Sregm;
                    if (s->Sclass == SCfastpar)
                        regcon.mpvar |= s->Sregm;
                }
            }
            else if (s->Sflags & SFLspill)
            {   if (vec_testbit(dfoidx,s->Srange))
                {
                    anyspill = i + 1;
                    cgreg_spillreg_prolog(bl,s,&cstore,&cload);
                    if (vec_testbit(dfoidx,s->Slvreg))
                    {   s->Sfl = FLreg;
                        regcon.mvar |= s->Sregm;
                        regcon.cse.mval &= ~s->Sregm;
                        regcon.immed.mval &= ~s->Sregm;
                        if (s->Sclass == SCfastpar)
                            regcon.mpvar |= s->Sregm;
                    }
                }
            }
        }
        if ((regcon.cse.mops & regcon.cse.mval) != regcon.cse.mops)
        {   code *cx;

            cx = cse_save(regcon.cse.mops & ~regcon.cse.mval);
            cstore = cat(cx, cstore);
        }
        c = cat(cstore,cload);
        mfuncreg &= ~regcon.mvar;               // use these registers
        regcon.used |= regcon.mvar;

        // Determine if we have more than 1 uncommitted index register
        regcon.indexregs = IDXREGS & ~regcon.mvar;
        regcon.indexregs &= regcon.indexregs - 1;
    }

    e = bl->Belem;
    regsave.idx = 0;
    retregs = 0;
    reflocal = 0;
    refparamsave = refparam;
    refparam = 0;
    assert((regcon.cse.mops & regcon.cse.mval) == regcon.cse.mops);
    switch (bl->BC)                     /* block exit condition         */
    {
        case BCiftrue:
            jcond = TRUE;
            bs1 = list_block(bl->Bsucc);
            bs2 = list_block(list_next(bl->Bsucc));
            if (bs1 == bl->Bnext)
            {   // Swap bs1 and bs2
                block *btmp;

                jcond ^= 1;
                btmp = bs1;
                bs1 = bs2;
                bs2 = btmp;
            }
            c = cat(c,logexp(e,jcond,FLblock,(code *) bs1));
            nextb = bs2;
            bl->Bcode = NULL;
        L2:
            if (nextb != bl->Bnext)
            {   if (configv.addlinenumbers && bl->Bsrcpos.Slinnum &&
                    !(funcsym_p->ty() & mTYnaked))
                    cgen_linnum(&c,bl->Bsrcpos);
                assert(!(bl->Bflags & BFLepilog));
                c = cat(c,genjmp(CNIL,JMP,FLblock,nextb));
            }
            bl->Bcode = cat(bl->Bcode,c);
            break;
        case BCjmptab:
        case BCifthen:
        case BCswitch:
            assert(!(bl->Bflags & BFLepilog));
            doswitch(bl);               /* hide messy details           */
            bl->Bcode = cat(c,bl->Bcode);
            break;
#if MARS
        case BCjcatch:
            // Mark all registers as destroyed. This will prevent
            // register assignments to variables used in catch blocks.
            c = cat(c,getregs((I32 | I64) ? allregs : (ALLREGS | mES)));
#if 0 && TARGET_LINUX
            if (config.flags3 & CFG3pic && !(allregs & mBX))
            {
                c = cat(c, cod3_load_got());
            }
#endif
            goto case_goto;
#endif
#if SCPP
        case BCcatch:
            // Mark all registers as destroyed. This will prevent
            // register assignments to variables used in catch blocks.
            c = cat(c,getregs(allregs | mES));
#if 0 && TARGET_LINUX
            if (config.flags3 & CFG3pic && !(allregs & mBX))
            {
                c = cat(c, cod3_load_got());
            }
#endif
            goto case_goto;

        case BCtry:
            usednteh |= EHtry;
            if (config.flags2 & CFG2seh)
                usednteh |= NTEHtry;
            goto case_goto;
#endif
        case BCgoto:
            nextb = list_block(bl->Bsucc);
            if ((funcsym_p->Sfunc->Fflags3 & Fnteh ||
                 (MARS /*&& config.flags2 & CFG2seh*/)) &&
                bl->Btry != nextb->Btry &&
                nextb->BC != BC_finally)
            {   int toindex;
                int fromindex;

                bl->Bcode = NULL;
                c = gencodelem(c,e,&retregs,TRUE);
                toindex = nextb->Btry ? nextb->Btry->Bscope_index : -1;
                assert(bl->Btry);
                fromindex = bl->Btry->Bscope_index;
#if MARS
                if (toindex + 1 == fromindex)
                {   // Simply call __finally
                    if (bl->Btry &&
                        list_block(list_next(bl->Btry->Bsucc))->BC == BCjcatch)
                    {
                        goto L2;
                    }
                }
#endif
                if (config.flags2 & CFG2seh)
                    c = cat(c,nteh_unwind(0,toindex));
#if MARS && (TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS)
                else if (toindex + 1 <= fromindex)
                {
                    //c = cat(c, linux_unwind(0, toindex));
                    block *bt;

                    //printf("B%d: fromindex = %d, toindex = %d\n", bl->Bdfoidx, fromindex, toindex);
                    bt = bl;
                    while ((bt = bt->Btry) != NULL && bt->Bscope_index != toindex)
                    {   block *bf;

                        //printf("\tbt->Bscope_index = %d, bt->Blast_index = %d\n", bt->Bscope_index, bt->Blast_index);
                        bf = list_block(list_next(bt->Bsucc));
                        // Only look at try-finally blocks
                        if (bf->BC == BCjcatch)
                            continue;

                        if (bf == nextb)
                            continue;
                        //printf("\tbf = B%d, nextb = B%d\n", bf->Bdfoidx, nextb->Bdfoidx);
                        if (nextb->BC == BCgoto &&
                            !nextb->Belem &&
                            bf == list_block(nextb->Bsucc))
                            continue;

                        // call __finally
                        code *cs;
                        code *cr;
                        int nalign = 0;

                        gensaverestore(retregs,&cs,&cr);
                        if (STACKALIGN == 16)
                        {   int npush = (numbitsset(retregs) + 1) * REGSIZE;
                            if (npush & (STACKALIGN - 1))
                            {   nalign = STACKALIGN - (npush & (STACKALIGN - 1));
                                cs = genc2(cs,0x81,modregrm(3,5,SP),nalign); // SUB ESP,nalign
                                if (I64)
                                    code_orrex(cs, REX_W);
                            }
                        }
                        cs = genc(cs,0xE8,0,0,0,FLblock,(long)list_block(bf->Bsucc));
                        if (nalign)
                        {   cs = genc2(cs,0x81,modregrm(3,0,SP),nalign); // ADD ESP,nalign
                            if (I64)
                                code_orrex(cs, REX_W);
                        }
                        c = cat3(c,cs,cr);
                    }
                }
#endif
                goto L2;
            }
        case_goto:
            c = gencodelem(c,e,&retregs,TRUE);
            if (anyspill)
            {   // Add in the epilog code
                code *cstore = NULL;
                code *cload = NULL;

                for (int i = 0; i < anyspill; i++)
                {   symbol *s = globsym.tab[i];

                    if (s->Sflags & SFLspill &&
                        vec_testbit(dfoidx,s->Srange))
                    {
                        s->Sfl = sflsave[i];    // undo block register assignments
                        cgreg_spillreg_epilog(bl,s,&cstore,&cload);
                    }
                }
                c = cat3(c,cstore,cload);
            }

        L3:
            bl->Bcode = NULL;
            nextb = list_block(bl->Bsucc);
            goto L2;

        case BC_try:
            if (config.flags2 & CFG2seh)
            {   usednteh |= NTEH_try;
                nteh_usevars();
            }
            else
                usednteh |= EHtry;
            goto case_goto;

        case BC_finally:
            // Mark all registers as destroyed. This will prevent
            // register assignments to variables used in finally blocks.
            assert(!getregs(allregs));
            assert(!e);
            assert(!bl->Bcode);
#if TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
            if (config.flags3 & CFG3pic)
            {
                int nalign = 0;
                if (STACKALIGN == 16)
                {   nalign = STACKALIGN - REGSIZE;
                    c = genc2(c,0x81,modregrm(3,5,SP),nalign); // SUB ESP,nalign
                    if (I64)
                        code_orrex(c, REX_W);
                }
                // CALL bl->Bsucc
                c = genc(c,0xE8,0,0,0,FLblock,(long)list_block(bl->Bsucc));
                if (nalign)
                {   c = genc2(c,0x81,modregrm(3,0,SP),nalign); // ADD ESP,nalign
                    if (I64)
                        code_orrex(c, REX_W);
                }
                // JMP list_next(bl->Bsucc)
                nextb = list_block(list_next(bl->Bsucc));
                goto L2;
            }
            else
#endif
            {
                // Generate a PUSH of the address of the successor to the
                // corresponding BC_ret
                //assert(list_block(list_next(bl->Bsucc))->BC == BC_ret);
                // PUSH &succ
                c = genc(c,0x68,0,0,0,FLblock,(long)list_block(list_next(bl->Bsucc)));
                nextb = list_block(bl->Bsucc);
                goto L2;
            }

        case BC_ret:
            c = gencodelem(c,e,&retregs,TRUE);
            bl->Bcode = gen1(c,0xC3);   // RET
            break;

#if NTEXCEPTIONS
        case BC_except:
            assert(!e);
            usednteh |= NTEH_except;
            c = cat(c,nteh_setsp(0x8B));
            getregs(allregs);
            goto L3;

        case BC_filter:
            c = cat(c,nteh_filter(bl));
            // Mark all registers as destroyed. This will prevent
            // register assignments to variables used in filter blocks.
            getregs(allregs);
            retregs = regmask(e->Ety, TYnfunc);
            c = gencodelem(c,e,&retregs,TRUE);
            bl->Bcode = gen1(c,0xC3);   // RET
            break;
#endif

        case BCretexp:
            retregs = regmask(e->Ety, funcsym_p->ty());

            // For the final load into the return regs, don't set regcon.used,
            // so that the optimizer can potentially use retregs for register
            // variable assignments.

            if (config.flags4 & CFG4optimized)
            {   regm_t usedsave;

                c = cat(c,docommas(&e));
                usedsave = regcon.used;
                if (EOP(e))
                    c = gencodelem(c,e,&retregs,TRUE);
                else
                {
                    if (e->Eoper == OPconst)
                        regcon.mvar = 0;
                    c = gencodelem(c,e,&retregs,TRUE);
                    regcon.used = usedsave;
                    if (e->Eoper == OPvar)
                    {   symbol *s = e->EV.sp.Vsym;

                        if (s->Sfl == FLreg && s->Sregm != mAX)
                            retsym = s;
                    }
                }
            }
            else
            {
        case BCret:
        case BCexit:
                c = gencodelem(c,e,&retregs,TRUE);
            }
            bl->Bcode = c;
            if (retregs == mST0)
            {   assert(stackused == 1);
                pop87();                // account for return value
            }
            else if (retregs == mST01)
            {   assert(stackused == 2);
                pop87();
                pop87();                // account for return value
            }
            if (bl->BC == BCexit && config.flags4 & CFG4optimized)
                mfuncreg = mfuncregsave;
            if (MARS || usednteh & NTEH_try)
            {   block *bt;

                bt = bl;
                while ((bt = bt->Btry) != NULL)
                {   block *bf;

                    bf = list_block(list_next(bt->Bsucc));
#if MARS
                    // Only look at try-finally blocks
                    if (bf->BC == BCjcatch)
                    {
                        continue;
                    }
#endif
                    if (config.flags2 & CFG2seh)
                    {
                        if (bt->Bscope_index == 0)
                        {
                            // call __finally
                            code *cs;
                            code *cr;

                            c = cat(c,nteh_gensindex(-1));
                            gensaverestore(retregs,&cs,&cr);
                            cs = genc(cs,0xE8,0,0,0,FLblock,(long)list_block(bf->Bsucc));
                            bl->Bcode = cat3(c,cs,cr);
                        }
                        else
                            bl->Bcode = cat(c,nteh_unwind(retregs,~0));
                        break;
                    }
                    else
                    {
                        // call __finally
                        code *cs;
                        code *cr;
                        int nalign = 0;

                        gensaverestore(retregs,&cs,&cr);
                        if (STACKALIGN == 16)
                        {   int npush = (numbitsset(retregs) + 1) * REGSIZE;
                            if (npush & (STACKALIGN - 1))
                            {   nalign = STACKALIGN - (npush & (STACKALIGN - 1));
                                cs = genc2(cs,0x81,modregrm(3,5,SP),nalign); // SUB ESP,nalign
                                if (I64)
                                    code_orrex(cs, REX_W);
                            }
                        }
                        // CALL bf->Bsucc
                        cs = genc(cs,0xE8,0,0,0,FLblock,(long)list_block(bf->Bsucc));
                        if (nalign)
                        {   cs = genc2(cs,0x81,modregrm(3,0,SP),nalign); // ADD ESP,nalign
                            if (I64)
                                code_orrex(cs, REX_W);
                        }
                        bl->Bcode = c = cat3(c,cs,cr);
                    }
                }
            }
            break;

#if SCPP || MARS
        case BCasm:
            assert(!e);
            // Mark destroyed registers
            assert(!c);
            c = cat(c,getregs(iasm_regs(bl)));
            if (bl->Bsucc)
            {   nextb = list_block(bl->Bsucc);
                if (!bl->Bnext)
                    goto L2;
                if (nextb != bl->Bnext &&
                    bl->Bnext &&
                    !(bl->Bnext->BC == BCgoto &&
                     !bl->Bnext->Belem &&
                     nextb == list_block(bl->Bnext->Bsucc)))
                {   code *cl;

                    // See if already have JMP at end of block
                    cl = code_last(bl->Bcode);
                    if (!cl || cl->Iop != JMP)
                        goto L2;        // add JMP at end of block
                }
            }
            break;
#endif
        default:
#ifdef DEBUG
            printf("bl->BC = %d\n",bl->BC);
#endif
            assert(0);
    }

    for (int i = 0; i < anyspill; i++)
    {   symbol *s = globsym.tab[i];

        s->Sfl = sflsave[i];    // undo block register assignments
    }

    if (reflocal)
        bl->Bflags |= BFLreflocal;
    if (refparam)
        bl->Bflags |= BFLrefparam;
    refparam |= refparamsave;
    bl->Bregcon.immed = regcon.immed;
    bl->Bregcon.cse = regcon.cse;
    bl->Bregcon.used = regcon.used;
    bl->Bregcon.params = regcon.params;
#ifdef DEBUG
    debugw && printf("code gen complete\n");
#endif
}

/*****************************************
 * Add in exception handling code.
 */

#if SCPP

STATIC void cgcod_eh()
{   block *btry;
    code *c;
    code *c1;
    list_t stack;
    list_t list;
    block *b;
    int idx;
    int lastidx;
    int tryidx;
    int i;

    if (!(usednteh & (EHtry | EHcleanup)))
        return;

    // Compute Bindex for each block
    for (b = startblock; b; b = b->Bnext)
    {   b->Bindex = -1;
        b->Bflags &= ~BFLvisited;               /* mark as unvisited    */
    }
    btry = NULL;
    lastidx = 0;
    startblock->Bindex = 0;
    for (b = startblock; b; b = b->Bnext)
    {
        if (btry == b->Btry && b->BC == BCcatch)  // if don't need to pop try block
        {   block *br;

            br = list_block(b->Bpred);          // find corresponding try block
            assert(br->BC == BCtry);
            b->Bindex = br->Bindex;
        }
        else if (btry != b->Btry && b->BC != BCcatch ||
                 !(b->Bflags & BFLvisited))
            b->Bindex = lastidx;
        b->Bflags |= BFLvisited;
#ifdef DEBUG
        if (debuge)
        {
            WRBC(b->BC);
            dbg_printf(" block (%p) Btry=%p Bindex=%d\n",b,b->Btry,b->Bindex);
        }
#endif
        except_index_set(b->Bindex);
        if (btry != b->Btry)                    // exited previous try block
        {
            except_pop(b,NULL,btry);
            btry = b->Btry;
        }
        if (b->BC == BCtry)
        {
            except_push(b,NULL,b);
            btry = b;
            tryidx = except_index_get();
            b->Bcode = cat(nteh_gensindex(tryidx - 1),b->Bcode);
        }

        stack = NULL;
        for (c = b->Bcode; c; c = code_next(c))
        {
            if ((c->Iop & 0xFF) == ESCAPE)
            {
                c1 = NULL;
                switch (c->Iop & 0xFF00)
                {
                    case ESCctor:
//printf("ESCctor\n");
                        except_push(c,c->IEV1.Vtor,NULL);
                        goto L1;

                    case ESCdtor:
//printf("ESCdtor\n");
                        except_pop(c,c->IEV1.Vtor,NULL);
                    L1: if (config.flags2 & CFG2seh)
                        {
                            c1 = nteh_gensindex(except_index_get() - 1);
                            code_next(c1) = code_next(c);
                            code_next(c) = c1;
                        }
                        break;
                    case ESCmark:
//printf("ESCmark\n");
                        idx = except_index_get();
                        list_prependdata(&stack,idx);
                        except_mark();
                        break;
                    case ESCrelease:
//printf("ESCrelease\n");
                        idx = list_data(stack);
                        list_pop(&stack);
                        if (idx != except_index_get())
                        {
                            if (config.flags2 & CFG2seh)
                            {   c1 = nteh_gensindex(idx - 1);
                                code_next(c1) = code_next(c);
                                code_next(c) = c1;
                            }
                            else
                            {   except_pair_append(c,idx - 1);
                                c->Iop = ESCAPE | ESCoffset;
                            }
                        }
                        except_release();
                        break;
                    case ESCmark2:
//printf("ESCmark2\n");
                        except_mark();
                        break;
                    case ESCrelease2:
//printf("ESCrelease2\n");
                        except_release();
                        break;
                }
            }
        }
        assert(stack == NULL);
        b->Bendindex = except_index_get();

        if (b->BC != BCret && b->BC != BCretexp)
            lastidx = b->Bendindex;

        // Set starting index for each of the successors
        i = 0;
        for (list = b->Bsucc; list; list = list_next(list))
        {   block *bs = list_block(list);

            if (b->BC == BCtry)
            {   switch (i)
                {   case 0:                             // block after catches
                        bs->Bindex = b->Bendindex;
                        break;
                    case 1:                             // 1st catch block
                        bs->Bindex = tryidx;
                        break;
                    default:                            // subsequent catch blocks
                        bs->Bindex = b->Bindex;
                        break;
                }
#ifdef DEBUG
                if (debuge)
                {
                    dbg_printf(" 1setting %p to %d\n",bs,bs->Bindex);
                }
#endif
            }
            else if (!(bs->Bflags & BFLvisited))
            {
                bs->Bindex = b->Bendindex;
#ifdef DEBUG
                if (debuge)
                {
                    dbg_printf(" 2setting %p to %d\n",bs,bs->Bindex);
                }
#endif
            }
            bs->Bflags |= BFLvisited;
            i++;
        }
    }

    if (config.flags2 & CFG2seh)
        for (b = startblock; b; b = b->Bnext)
        {
            if (/*!b->Bcount ||*/ b->BC == BCtry)
                continue;
            for (list = b->Bpred; list; list = list_next(list))
            {   int pi;

                pi = list_block(list)->Bendindex;
                if (b->Bindex != pi)
                {
                    b->Bcode = cat(nteh_gensindex(b->Bindex - 1),b->Bcode);
                    break;
                }
            }
        }
}

#endif

/*****************************
 * Given a type, return a mask of
 * registers to hold that type.
 * Input:
 *      tyf     function type
 */

regm_t regmask(tym_t tym, tym_t tyf)
{
    switch (tybasic(tym))
    {
        case TYvoid:
        case TYstruct:
            return 0;
        case TYbool:
        case TYwchar_t:
        case TYchar16:
        case TYchar:
        case TYschar:
        case TYuchar:
        case TYshort:
        case TYushort:
        case TYint:
        case TYuint:
#if JHANDLE
        case TYjhandle:
#endif
        case TYnullptr:
        case TYnptr:
        case TYsptr:
        case TYcptr:
            return mAX;

        case TYfloat:
        case TYifloat:
            if (I64)
                return mXMM0;
            if (config.exe & EX_flat)
                return mST0;
        case TYlong:
        case TYulong:
        case TYdchar:
            if (!I16)
                return mAX;
        case TYfptr:
        case TYhptr:
            return mDX | mAX;

        case TYcent:
        case TYucent:
            assert(I64);
            return mDX | mAX;

        case TYvptr:
            return mDX | mBX;

        case TYdouble:
        case TYdouble_alias:
        case TYidouble:
            if (I64)
                return mXMM0;
            if (config.exe & EX_flat)
                return mST0;
            return DOUBLEREGS;

        case TYllong:
        case TYullong:
            return I64 ? mAX : (I32 ? mDX | mAX : DOUBLEREGS);

        case TYldouble:
        case TYildouble:
            return mST0;

        case TYcfloat:
#if TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
            if (I32 && tybasic(tyf) == TYnfunc)
                return mDX | mAX;
#endif
        case TYcdouble:
            if (I64)
                return mXMM0 | mXMM1;
        case TYcldouble:
            return mST01;

        default:
#if DEBUG
            WRTYxx(tym);
#endif
            assert(0);
            return 0;
    }
}

/******************************
 * Count the number of bits set in a register mask.
 */

int numbitsset(regm_t regm)
{   int n;

    n = 0;
    if (regm)
        do
            n++;
        while ((regm &= regm - 1) != 0);
    return n;
}

/******************************
 * Given a register mask, find and return the number
 * of the first register that fits.
 */

#undef findreg

unsigned findreg(regm_t regm
#ifdef DEBUG
        ,int line,const char *file
#endif
        )
#ifdef DEBUG
#define findreg(regm) findreg((regm),__LINE__,__FILE__)
#endif
{
#ifdef DEBUG
    regm_t regmsave = regm;
#endif
    int i = 0;
    while (1)
    {
        if (!(regm & 0xF))
        {
            regm >>= 4;
            i += 4;
            if (!regm)
                break;
        }
        if (regm & 1)
            return i;
        regm >>= 1;
        i++;
    }
#ifdef DEBUG
  printf("findreg(x%x, line=%d, file='%s')\n",regmsave,line,file);
  fflush(stdout);
#endif
*(char*)0=0;
  assert(0);
  return 0;
}

/***************
 * Free element (but not it's leaves! (assume they are already freed))
 * Don't decrement Ecount! This is so we can detect if the common subexp
 * has already been evaluated.
 * If common subexpression is not required anymore, eliminate
 * references to it.
 */

void freenode(elem *e)
{ unsigned i;

  elem_debug(e);
  //dbg_printf("freenode(%p) : comsub = %d, count = %d\n",e,e->Ecomsub,e->Ecount);
  if (e->Ecomsub--) return;             /* usage count                  */
  if (e->Ecount)                        /* if it was a CSE              */
  {     for (i = 0; i < arraysize(regcon.cse.value); i++)
        {   if (regcon.cse.value[i] == e)       /* if a register is holding it  */
            {   regcon.cse.mval &= ~mask[i];
                regcon.cse.mops &= ~mask[i];    /* free masks                   */
            }
        }
        for (i = 0; i < cstop; i++)
        {   if (csextab[i].e == e)
                csextab[i].e = NULL;
        }
  }
}

/*********************************
 * Reset Ecomsub for all elem nodes, i.e. reverse the effects of freenode().
 */

STATIC void resetEcomsub(elem *e)
{   unsigned op;

    while (1)
    {
        elem_debug(e);
        e->Ecomsub = e->Ecount;
        op = e->Eoper;
        if (!OTleaf(op))
        {       if (OTbinary(op))
                    resetEcomsub(e->E2);
                e = e->E1;
        }
        else
                break;
    }
}

/*********************************
 * Determine if elem e is a register variable.
 * If so:
 *      *pregm = mask of registers that make up the variable
 *      *preg = the least significant register
 *      returns TRUE
 * Else
 *      returns FALSE
 */

int isregvar(elem *e,regm_t *pregm,unsigned *preg)
{   symbol *s;
    unsigned u;
    regm_t m;
    regm_t regm;
    unsigned reg;

    elem_debug(e);
    if (e->Eoper == OPvar || e->Eoper == OPrelconst)
    {
        s = e->EV.sp.Vsym;
        switch (s->Sfl)
        {   case FLreg:
                if (s->Sclass == SCparameter)
                {   refparam = TRUE;
                    reflocal = TRUE;
                }
                reg = s->Sreglsw;
                regm = s->Sregm;
                //assert(tyreg(s->ty()));
#if 0
                // Let's just see if there is a CSE in a reg we can use
                // instead. This helps avoid AGI's.
                if (e->Ecount && e->Ecount != e->Ecomsub)
                {   int i;

                    for (i = 0; i < arraysize(regcon.cse.value); i++)
                    {
                        if (regcon.cse.value[i] == e)
                        {   reg = i;
                            break;
                        }
                    }
                }
#endif
                assert(regm & regcon.mvar && !(regm & ~regcon.mvar));
                goto Lreg;

            case FLpseudo:
#if MARS
                assert(0);
#else
                u = s->Sreglsw;
                m = pseudomask[u];
                if (m & ALLREGS && (u & ~3) != 4) // if not BP,SP,EBP,ESP,or ?H
                {   reg = pseudoreg[u] & 7;
                    regm = m;
                    goto Lreg;
                }
#endif
                break;
        }
    }
    return FALSE;

Lreg:
    if (preg)
        *preg = reg;
    if (pregm)
        *pregm = regm;
    return TRUE;
}

/*********************************
 * Allocate some registers.
 * Input:
 *      pretregs        Pointer to mask of registers to make selection from.
 *      tym             Mask of type we will store in registers.
 * Output:
 *      *pretregs       Mask of allocated registers.
 *      *preg           Register number of first allocated register.
 *      msavereg,mfuncreg       retregs bits are cleared.
 *      regcon.cse.mval,regcon.cse.mops updated
 * Returns:
 *      pointer to code generated if necessary to save any regcon.cse.mops on the
 *      stack.
 */

#undef allocreg

code *allocreg(regm_t *pretregs,unsigned *preg,tym_t tym
#ifdef DEBUG
        ,int line,const char *file
#endif
        )
#ifdef DEBUG
#define allocreg(a,b,c) allocreg((a),(b),(c),__LINE__,__FILE__)
#endif
{       regm_t r,s;
        regm_t retregs;
        unsigned reg;
        unsigned msreg,lsreg;
        int count;
        unsigned size;

#if 0
      if (pass == PASSfinal)
        {   dbg_printf("allocreg %s,%d: regcon.mvar %s regcon.cse.mval %s msavereg %s *pretregs %s tym ",
                file,line,regm_str(regcon.mvar),regm_str(regcon.cse.mval),
                regm_str(msavereg),regm_str(*pretregs));
            WRTYxx(tym);
            dbg_printf("\n");
        }
#endif
        tym = tybasic(tym);
        size = tysize[tym];
        *pretregs &= mES | allregs | XMMREGS;
        retregs = *pretregs;
        if ((retregs & regcon.mvar) == retregs) // if exactly in reg vars
        {
            if (size <= REGSIZE)
            {   *preg = findreg(retregs);
                assert(retregs == mask[*preg]); /* no more bits are set */
            }
            else if (size <= 2 * REGSIZE)
            {   *preg = findregmsw(retregs);
                assert(retregs & mLSW);
            }
            else
                assert(0);
            return getregs(retregs);
        }
        count = 0;
L1:
        //printf("L1: allregs = x%x, *pretregs = x%x\n", allregs, *pretregs);
        assert(++count < 20);           /* fail instead of hanging if blocked */
        s = retregs & mES;
        assert(retregs);
        msreg = lsreg = (unsigned)-1;           /* no value assigned yet        */
L3:
        //printf("L2: allregs = x%x, *pretregs = x%x\n", allregs, *pretregs);
        r = retregs & ~(msavereg | regcon.cse.mval | regcon.params);
        if (!r)
        {
            r = retregs & ~(msavereg | regcon.cse.mval);
            if (!r)
            {
                r = retregs & ~(msavereg | regcon.cse.mops);
                if (!r)
                {   r = retregs & ~msavereg;
                    if (!r)
                        r = retregs;
                }
            }
        }
        if (0 && r & ~fregsaved)
            r &= ~fregsaved;

        if (size <= REGSIZE)
        {
            if (r & ~mBP)
                r &= ~mBP;

            // If only one index register, prefer to not use LSW registers
            if (!regcon.indexregs && r & ~mLSW)
                r &= ~mLSW;

            if (pass == PASSfinal && r & ~lastretregs && !I16)
            {   // Try not to always allocate the same register,
                // to schedule better

                r &= ~lastretregs;
                if (r & ~last2retregs)
                {   r &= ~last2retregs;
                    if (r & ~last3retregs)
                    {   r &= ~last3retregs;
                        if (r & ~last4retregs)
                        {   r &= ~last4retregs;
//                          if (r & ~last5retregs)
//                              r &= ~last5retregs;
                        }
                    }
                }
                if (r & ~mfuncreg)
                    r &= ~mfuncreg;
            }
            reg = findreg(r);
            retregs = mask[reg];
        }
        else if (size <= 2 * REGSIZE)
        {
            /* Select pair with both regs free. Failing */
            /* that, select pair with one reg free.             */

            if (r & mBP)
            {   retregs &= ~mBP;
                goto L3;
            }

            if (r & mMSW)
            {
                if (r & mDX)
                    msreg = DX;                 /* prefer to use DX over CX */
                else
                    msreg = findregmsw(r);
                r &= mLSW;                      /* see if there's an LSW also */
                if (r)
                    lsreg = findreg(r);
                else if (lsreg == -1)   /* if don't have LSW yet */
                {       retregs &= mLSW;
                    goto L3;
                }
            }
            else
            {
                if (I64 && !(r & mLSW))
                {   retregs = *pretregs & (mMSW | mLSW);
                    assert(retregs);
                    goto L1;
                }
                lsreg = findreglsw(r);
                if (msreg == -1)
                {   retregs &= mMSW;
                    goto L3;
                }
            }
            reg = (msreg == ES) ? lsreg : msreg;
            retregs = mask[msreg] | mask[lsreg];
        }
        else if (I16 && (tym == TYdouble || tym == TYdouble_alias))
        {
#ifdef DEBUG
            if (retregs != DOUBLEREGS)
                printf("retregs = x%x, *pretregs = x%x\n",retregs,*pretregs);
#endif
            assert(retregs == DOUBLEREGS);
            reg = AX;
        }
        else
        {
#ifdef DEBUG
            WRTYxx(tym);
            printf("\nallocreg: fil %s lin %d, regcon.mvar x%x msavereg x%x *pretregs x%x, reg %d, tym x%x\n",
                file,line,regcon.mvar,msavereg,*pretregs,*preg,tym);
#endif
            assert(0);
        }
        if (retregs & regcon.mvar)              // if conflict with reg vars
        {
            if (!(size > REGSIZE && *pretregs == (mAX | mDX)))
            {
                retregs = (*pretregs &= ~(retregs & regcon.mvar));
                goto L1;                // try other registers
            }
        }
        *preg = reg;
        *pretregs = retregs;

        //printf("Allocating %s\n",regm_str(retregs));
        last5retregs = last4retregs;
        last4retregs = last3retregs;
        last3retregs = last2retregs;
        last2retregs = lastretregs;
        lastretregs = retregs;
        return getregs(retregs);
}

/*************************
 * Mark registers as used.
 */

void useregs(regm_t regm)
{
    //printf("useregs(x%x) %s\n", regm, regm_str(regm));
    mfuncreg &= ~regm;
    regcon.used |= regm;                // registers used in this block
    regcon.params &= ~regm;
    if (regm & regcon.mpvar)            // if modified a fastpar register variable
        regcon.params = 0;              // toss them all out
}

/*************************
 * We are going to use the registers in mask r.
 * Generate any code necessary to save any regs.
 */

code *getregs(regm_t r)
{   regm_t ms;

    //printf("getregs(x%x)\n",r);
    ms = r & regcon.cse.mops;           // mask of common subs we must save
    useregs(r);
    regcon.cse.mval &= ~r;
    msavereg &= ~r;                     // regs that are destroyed
    regcon.immed.mval &= ~r;
    return ms ? cse_save(ms) : NULL;
}

/*****************************************
 * Copy registers in cse.mops into memory.
 */

STATIC code * cse_save(regm_t ms)
{   unsigned reg,i,op;
    code *c = NULL;
    regm_t regm;

    assert((ms & regcon.cse.mops) == ms);
    regcon.cse.mops &= ~ms;

    /* Skip CSEs that are already saved */
    for (regm = 1; regm <= mES; regm <<= 1)
    {
        if (regm & ms)
        {   elem *e;

            e = regcon.cse.value[findreg(regm)];
            for (i = 0; i < csmax; i++)
            {
                if (csextab[i].e == e)
                {
                    tym_t tym;
                    unsigned sz;

                    tym = e->Ety;
                    sz = tysize(tym);
                    if (sz <= REGSIZE ||
                        sz <= 2 * REGSIZE &&
                            (regm & mMSW && csextab[i].regm & mMSW ||
                             regm & mLSW && csextab[i].regm & mLSW) ||
                        sz == 4 * REGSIZE && regm == csextab[i].regm
                       )
                    {
                        ms &= ~regm;
                        if (!ms)
                            goto Lret;
                        break;
                    }
                }
            }
        }
    }

    for (i = cstop; ms; i++)
    {
        if (i >= csmax)                 /* array overflow               */
        {   unsigned cseinc;

#ifdef DEBUG
            cseinc = 8;                 /* flush out reallocation bugs  */
#else
            cseinc = csmax + 32;
#endif
            csextab = (struct CSE *) util_realloc(csextab,
                (csmax + cseinc), sizeof(csextab[0]));
            memset(&csextab[csmax],0,cseinc * sizeof(csextab[0]));
            csmax += cseinc;
            goto L1;
        }
        if (i >= cstop)
        {
            memset(&csextab[cstop],0,sizeof(csextab[0]));
            goto L1;
        }
        if (csextab[i].e == NULL || i >= cstop)
        {
        L1:
            reg = findreg(ms);          /* the register to save         */
            csextab[i].e = regcon.cse.value[reg];
            csextab[i].regm = mask[reg];
            csextab[i].flags &= CSEload;
            if (i >= cstop)
                cstop = i + 1;

            ms &= ~mask[reg];           /* turn off reg bit in ms       */

            // If we can simply reload the CSE, we don't need to save it
            if (!cse_simple(csextab[i].e,i))
            {
                // MOV i[BP],reg
                op = 0x89;              // normal mov
                if (reg == ES)
                {   reg = 0;            // the real reg number
                    op = 0x8C;          // segment reg mov
                }
                c = genc1(c,op,modregxrm(2, reg, BPRM),FLcs,(targ_uns) i);
                if (I64)
                    code_orrex(c, REX_W);
                reflocal = TRUE;
            }
        }
    }
Lret:
    return c;
}

/******************************************
 * Getregs without marking immediate register values as gone.
 */

code *getregs_imm(regm_t r)
{   code *c;
    regm_t save;

    save = regcon.immed.mval;
    c = getregs(r);
    regcon.immed.mval = save;
    return c;
}

/******************************************
 * Flush all CSE's out of registers and into memory.
 * Input:
 *      do87    !=0 means save 87 registers too
 */

code *cse_flush(int do87)
{   code *c;

    //dbg_printf("cse_flush()\n");
    c = cse_save(regcon.cse.mops);      // save any CSEs to memory
    if (do87)
        c = cat(c,save87());    // save any 8087 temporaries
    return c;
}

/*************************************************
 */

STATIC int cse_simple(elem *e,int i)
{   regm_t regm;
    unsigned reg;
    code *c;
    int sz;

    sz = tysize[tybasic(e->Ety)];
    if (!I16 &&                                  // don't bother with 16 bit code
        e->Eoper == OPadd &&
        sz == REGSIZE &&
        e->E2->Eoper == OPconst &&
        e->E1->Eoper == OPvar &&
        isregvar(e->E1,&regm,&reg) &&
        sz <= REGSIZE &&
        !(e->E1->EV.sp.Vsym->Sflags & SFLspill)
       )
    {
        c = &csextab[i].csimple;
        memset(c,0,sizeof(*c));

        // Make this an LEA instruction
        c->Iop = 0x8D;                          // LEA
        buildEA(c,reg,-1,1,e->E2->EV.Vuns);
        if (I64)
        {   if (sz == 8)
                c->Irex |= REX_W;
            else if (sz == 1 && reg >= 4)
                c->Irex |= REX;
        }

        csextab[i].flags |= CSEsimple;
        return 1;
    }
    else if (e->Eoper == OPind &&
        sz <= REGSIZE &&
        e->E1->Eoper == OPvar &&
        isregvar(e->E1,&regm,&reg) &&
        (I32 || I64 || regm & IDXREGS) &&
        !(e->E1->EV.sp.Vsym->Sflags & SFLspill)
       )
    {
        c = &csextab[i].csimple;
        memset(c,0,sizeof(*c));

        // Make this a MOV instruction
        c->Iop = (sz == 1) ? 0x8A : 0x8B;       // MOV reg,EA
        buildEA(c,reg,-1,1,0);
        if (sz == 2 && I32)
            c->Iflags |= CFopsize;
        else if (I64)
        {   if (sz == 8)
                c->Irex |= REX_W;
            else if (sz == 1 && reg >= 4)
                c->Irex |= REX;
        }

        csextab[i].flags |= CSEsimple;
        return 1;
    }
    return 0;
}

/*************************
 * Common subexpressions exist in registers. Note this in regcon.cse.mval.
 * Input:
 *      e       the subexpression
 *      regm    mask of registers holding it
 *      opsflag if != 0 then regcon.cse.mops gets set too
 */

void cssave(elem *e,regm_t regm,unsigned opsflag)
{ unsigned i;

  /*if (e->Ecount && e->Ecount == e->Ecomsub)*/
  if (e->Ecount && e->Ecomsub)
  {
        //printf("cssave(e = %p, regm = x%x, opsflag = %d)\n", e, regm, opsflag);
        if (!opsflag && pass != PASSfinal && (I32 || I64))
            return;

        //printf("cssave(e = %p, regm = x%x, opsflag = x%x)\n", e, regm, opsflag);
        regm &= mBP | ALLREGS | mES;    /* just to be sure              */

#if 0
        /* Do not register CSEs if they are register variables and      */
        /* are not operator nodes. This forces the register allocation  */
        /* to go through allocreg(), which will prevent using register  */
        /* variables for scratch.                                       */
        if (opsflag || !(regm & regcon.mvar))
#endif
            for (i = 0; regm; i++)
            {   regm_t mi;

                mi = mask[i];
                if (regm & mi)
                {
                    regm &= ~mi;

                    // If we don't need this CSE, and the register already
                    // holds a CSE that we do need, don't mark the new one
                    if (regcon.cse.mval & mi && regcon.cse.value[i] != e &&
                        !opsflag && regcon.cse.mops & mi)
                        continue;

                    regcon.cse.mval |= mi;
                    if (opsflag)
                        regcon.cse.mops |= mi;
                    //printf("cssave set: regcon.cse.value[%s] = %p\n",regstring[i],e);
                    regcon.cse.value[i] = e;
                }
            }
  }
}

/*************************************
 * Determine if a computation should be done into a register.
 */

bool evalinregister(elem *e)
{       regm_t emask;
        unsigned i;
        unsigned sz;

        if (e->Ecount == 0)             /* elem is not a CSE, therefore */
                                        /* we don't need to evaluate it */
                                        /* in a register                */
                return FALSE;
        if (EOP(e))                     /* operators are always in register */
                return TRUE;
        sz = tysize(e->Ety);
        if (e->Ecount == e->Ecomsub)    /* elem is a CSE that needs     */
                                        /* to be generated              */
        {
            if ((I32 || I64) && pass == PASSfinal && sz <= REGSIZE)
            {
                // Do it only if at least 2 registers are available
                regm_t m;

                m = allregs & ~regcon.mvar;
                if (sz == 1)
                    m &= BYTEREGS;
                if (m & (m - 1))        // if more than one register
                {   // Need to be at least 3 registers available, as
                    // addressing modes can use up 2.
                    while (!(m & 1))
                        m >>= 1;
                    m >>= 1;
                    if (m & (m - 1))
                        return TRUE;
                }
            }
            return FALSE;
        }

        /* Elem is now a CSE that might have been generated. If so, and */
        /* it's in a register already, the computation should be done   */
        /* using that register.                                         */
        emask = 0;
        for (i = 0; i < arraysize(regcon.cse.value); i++)
                if (regcon.cse.value[i] == e)
                        emask |= mask[i];
        emask &= regcon.cse.mval;       // mask of available CSEs
        if (sz <= REGSIZE)
                return emask != 0;      /* the CSE is in a register     */
        else if (sz <= 2 * REGSIZE)
                return (emask & mMSW) && (emask & mLSW);
        return TRUE;                    /* cop-out for now              */
}

/*******************************************************
 * Return mask of scratch registers.
 */

regm_t getscratch()
{   regm_t scratch;

    scratch = 0;
    if (pass == PASSfinal)
    {
        scratch = allregs & ~(regcon.mvar | regcon.mpvar | regcon.cse.mval |
                regcon.immed.mval | regcon.params | mfuncreg);
    }
    return scratch;
}

/******************************
 * Evaluate an elem that is a common subexp that has been encountered
 * before.
 * Look first to see if it is already in a register.
 */

STATIC code * comsub(elem *e,regm_t *pretregs)
{   tym_t tym;
    regm_t regm,emask,csemask;
    unsigned reg,i,byte,sz;
    code *c;
    int forcc;                  // !=0 if we evaluate for condition codes
    int forregs;                // !=0 if we evaluate into registers

    //printf("comsub(e = %p, *pretregs = %s)\n",e,regm_str(*pretregs));
    elem_debug(e);
#ifdef DEBUG
    if (e->Ecomsub > e->Ecount)
        elem_print(e);
#endif
    assert(e->Ecomsub <= e->Ecount);

  c = CNIL;
  if (*pretregs == 0) goto done;        /* no possible side effects anyway */

    if (tyfloating(e->Ety) && config.inline8087)
        return comsub87(e,pretregs);

  /* First construct a mask, emask, of all the registers that   */
  /* have the right contents.                                   */

  emask = 0;
  for (i = 0; i < arraysize(regcon.cse.value); i++)
  {
        //dbg_printf("regcon.cse.value[%d] = %p\n",i,regcon.cse.value[i]);
        if (regcon.cse.value[i] == e)   /* if contents are right        */
                emask |= mask[i];       /* turn on bit for reg          */
  }
  emask &= regcon.cse.mval;                     /* make sure all bits are valid */

  /* create mask of what's in csextab[] */
  csemask = 0;
  for (i = 0; i < cstop; i++)
  {     if (csextab[i].e)
            elem_debug(csextab[i].e);
        if (csextab[i].e == e)
                csemask |= csextab[i].regm;
  }
  csemask &= ~emask;            /* stuff already in registers   */

#ifdef DEBUG
if (debugw)
{
printf("comsub(e=%p): *pretregs=%x, emask=%x, csemask=%x, regcon.cse.mval=%x, regcon.mvar=%x\n",
        e,*pretregs,emask,csemask,regcon.cse.mval,regcon.mvar);
if (regcon.cse.mval & 1) elem_print(regcon.cse.value[i]);
}
#endif

  tym = tybasic(e->Ety);
  sz = tysize[tym];
  byte = sz == 1;
  forcc = *pretregs & mPSW;
  forregs = *pretregs & (mBP | ALLREGS | mES);

  if (sz <= REGSIZE)                    // if data will fit in one register
  {
        /* First see if it is already in a correct register     */

        regm = emask & *pretregs;
        if (regm == 0)
                regm = emask;           /* try any other register       */
        if (regm)                       /* if it's in a register        */
        {
            if (EOP(e) || !(regm & regcon.mvar) || (*pretregs & regcon.mvar) == *pretregs)
            {
                regm = mask[findreg(regm)];
                goto fix;
            }
        }

        if (!EOP(e))                    /* if not op or func            */
                goto reload;            /* reload data                  */
        for (i = cstop; i--;)           /* look through saved comsubs   */
                if (csextab[i].e == e)  /* found it             */
                {   regm_t retregs;

                    if (csextab[i].flags & CSEsimple)
                    {   code *cr;

                        retregs = *pretregs;
                        if (byte && !(retregs & BYTEREGS))
                            retregs = BYTEREGS;
                        else if (!(retregs & allregs))
                            retregs = allregs;
                        c = allocreg(&retregs,&reg,tym);
                        cr = &csextab[i].csimple;
                        cr->setReg(reg);
                        c = gen(c,cr);
                        goto L10;
                    }
                    else
                    {
                        reflocal = TRUE;
                        csextab[i].flags |= CSEload;
                        if (*pretregs == mPSW)  /* if result in CCs only */
                        {                       // CMP cs[BP],0
                            c = genc(NULL,0x81 ^ byte,modregrm(2,7,BPRM),
                                        FLcs,i, FLconst,(targ_uns) 0);
                            if (I32 && sz == 2)
                                c->Iflags |= CFopsize;
                        }
                        else
                        {
                            retregs = *pretregs;
                            if (byte && !(retregs & BYTEREGS))
                                    retregs = BYTEREGS;
                            c = allocreg(&retregs,&reg,tym);
                                            // MOV reg,cs[BP]
                            c = genc1(c,0x8B,modregxrm(2,reg,BPRM),FLcs,(targ_uns) i);
                            if (I64)
                                code_orrex(c, REX_W);
                        L10:
                            regcon.cse.mval |= mask[reg]; // cs is in a reg
                            regcon.cse.value[reg] = e;
                            c = cat(c,fixresult(e,retregs,pretregs));
                        }
                    }
                    freenode(e);
                    return c;
                }
#ifdef DEBUG
        printf("couldn't find cse e = %p, pass = %d\n",e,pass);
        elem_print(e);
#endif
        assert(0);                      /* should have found it         */
  }
  else                                  /* reg pair is req'd            */
  if (sz <= 2 * REGSIZE)
  {     unsigned msreg,lsreg;

        /* see if we have both  */
        if (!((emask | csemask) & mMSW && (emask | csemask) & (mLSW | mBP)))
        {                               /* we don't have both           */
#if DEBUG
                if (EOP(e))
                {
                    printf("e = %p, op = x%x, emask = x%x, csemask = x%x\n",
                        e,e->Eoper,emask,csemask);
                    //printf("mMSW = x%x, mLSW = x%x\n", mMSW, mLSW);
                    elem_print(e);
                }
#endif
                assert(!EOP(e));        /* must have both for operators */
                goto reload;
        }

        /* Look for right vals in any regs      */

        regm = *pretregs & mMSW;
        if (emask & regm)
            msreg = findreg(emask & regm);
        else if (emask & mMSW)
            msreg = findregmsw(emask);
        else                    /* reload from cse array        */
        {
            if (!regm)
                regm = mMSW & ALLREGS;
            c = allocreg(&regm,&msreg,TYint);
            c = cat(c,loadcse(e,msreg,mMSW));
        }

        regm = *pretregs & (mLSW | mBP);
        if (emask & regm)
            lsreg = findreg(emask & regm);
        else if (emask & (mLSW | mBP))
            lsreg = findreglsw(emask);
        else
        {
            if (!regm)
                regm = mLSW;
            c = cat(c,allocreg(&regm,&lsreg,TYint));
            c = cat(c,loadcse(e,lsreg,mLSW | mBP));
        }

        regm = mask[msreg] | mask[lsreg];       /* mask of result       */
        goto fix;
  }
  else if (tym == TYdouble || tym == TYdouble_alias)    // double
  {
        assert(I16);
        if (((csemask | emask) & DOUBLEREGS_16) == DOUBLEREGS_16)
        {
            for (reg = AX; reg != -1; reg = dblreg[reg])
            {   assert((int) reg >= 0 && reg <= 7);
                if (mask[reg] & csemask)
                    c = cat(c,loadcse(e,reg,mask[reg]));
            }
            regm = DOUBLEREGS_16;
            goto fix;
        }
        if (!EOP(e)) goto reload;
#if DEBUG
        printf("e = %p, csemask = x%x, emask = x%x\n",e,csemask,emask);
#endif
        assert(0);
  }
  else
  {
#if DEBUG
        printf("e = %p, tym = x%x\n",e,tym);
#endif
        assert(0);
  }

reload:                                 /* reload result from memory    */
    switch (e->Eoper)
    {
        case OPrelconst:
            c = cdrelconst(e,pretregs);
            break;
#if TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
        case OPgot:
            c = cdgot(e,pretregs);
            break;
#endif
        default:
            c = loaddata(e,pretregs);
            break;
    }
    cssave(e,*pretregs,FALSE);
    freenode(e);
    return c;

fix:                                    /* we got result in regm, fix   */
  c = cat(c,fixresult(e,regm,pretregs));
done:
  freenode(e);
  return c;
}


/*****************************
 * Load reg from cse stack.
 * Returns:
 *      pointer to the MOV instruction
 */

STATIC code * loadcse(elem *e,unsigned reg,regm_t regm)
{ unsigned i,op;
  code *c;

  for (i = cstop; i--;)
  {
        //printf("csextab[%d] = %p, regm = x%x\n", i, csextab[i].e, csextab[i].regm);
        if (csextab[i].e == e && csextab[i].regm & regm)
        {
                reflocal = TRUE;
                csextab[i].flags |= CSEload;    /* it was loaded        */
                c = getregs(mask[reg]);
                regcon.cse.value[reg] = e;
                regcon.cse.mval |= mask[reg];
                op = 0x8B;
                if (reg == ES)
                {       op = 0x8E;
                        reg = 0;
                }
                c = genc1(c,op,modregxrm(2,reg,BPRM),FLcs,(targ_uns) i);
                if (I64)
                    code_orrex(c, REX_W);
                return c;
        }
  }
#if DEBUG
  printf("loadcse(e = %p, reg = %d, regm = x%x)\n",e,reg,regm);
elem_print(e);
#endif
  assert(0);
  /* NOTREACHED */
  return 0;
}

/***************************
 * Generate code sequence for an elem.
 * Input:
 *      pretregs        mask of possible registers to return result in
 *                      Note:   longs are in AX,BX or CX,DX or SI,DI
 *                              doubles are AX,BX,CX,DX only
 *      constflag       TRUE if user of result will not modify the
 *                      registers returned in *pretregs.
 * Output:
 *      *pretregs       mask of registers result is returned in
 * Returns:
 *      pointer to code sequence generated
 */

#include "cdxxx.c"                      /* jump table                   */

code *codelem(elem *e,regm_t *pretregs,bool constflag)
{ code *c;
  Symbol *s;
  tym_t tym;
  unsigned op;

#ifdef DEBUG
  if (debugw)
  {     printf("+codelem(e=%p,*pretregs=%s) ",e,regm_str(*pretregs));
        WROP(e->Eoper);
        printf("msavereg=x%x regcon.cse.mval=x%x regcon.cse.mops=x%x\n",
                msavereg,regcon.cse.mval,regcon.cse.mops);
        printf("Ecount = %d, Ecomsub = %d\n", e->Ecount, e->Ecomsub);
  }
#endif
  assert(e);
  elem_debug(e);
  if ((regcon.cse.mops & regcon.cse.mval) != regcon.cse.mops)
  {
#ifdef DEBUG
        printf("+codelem(e=%p,*pretregs=x%x) ",e,*pretregs);
        elem_print(e);
        printf("msavereg=x%x regcon.cse.mval=x%x regcon.cse.mops=x%x\n",
                msavereg,regcon.cse.mval,regcon.cse.mops);
        printf("Ecount = %d, Ecomsub = %d\n", e->Ecount, e->Ecomsub);
#endif
        assert(0);
  }

  if (!constflag && *pretregs & (mES | ALLREGS | mBP) & ~regcon.mvar)
        *pretregs &= ~regcon.mvar;                      /* can't use register vars */
  op = e->Eoper;
  if (e->Ecount && e->Ecount != e->Ecomsub)     /* if common subexp     */
  {     c = comsub(e,pretregs);
        goto L1;
  }

  switch (op)
  {
    default:
        if (e->Ecount)                          /* if common subexp     */
        {
            /* if no return value       */
            if ((*pretregs & (mSTACK | mES | ALLREGS | mBP)) == 0)
            {   if (tysize(e->Ety) == 1)
                    *pretregs |= BYTEREGS;
                else if (tybasic(e->Ety) == TYdouble || tybasic(e->Ety) == TYdouble_alias)
                    *pretregs |= DOUBLEREGS;
                else
                    *pretregs |= ALLREGS;       /* make one             */
            }

            /* BUG: For CSEs, make sure we have both an MSW             */
            /* and an LSW specified in *pretregs                        */
        }
        assert(op <= OPMAX);
        c = (*cdxxx[op])(e,pretregs);
        break;
    case OPrelconst:
        c = cdrelconst(e,pretregs);
        break;
    case OPvar:
        if (constflag && (s = e->EV.sp.Vsym)->Sfl == FLreg &&
            (s->Sregm & *pretregs) == s->Sregm)
        {
            if (tysize(e->Ety) <= REGSIZE && tysize(s->Stype->Tty) == 2 * REGSIZE)
                *pretregs &= mPSW | (s->Sregm & mLSW);
            else
                *pretregs &= mPSW | s->Sregm;
        }
    case OPconst:
        if (*pretregs == 0 && (e->Ecount >= 3 || e->Ety & mTYvolatile))
        {
            switch (tybasic(e->Ety))
            {
                case TYbool:
                case TYchar:
                case TYschar:
                case TYuchar:
                    *pretregs |= BYTEREGS;
                    break;
#if JHANDLE
                case TYjhandle:
#endif
                case TYnptr:
                case TYsptr:
                case TYcptr:
                    *pretregs |= IDXREGS;
                    break;
                case TYshort:
                case TYushort:
                case TYint:
                case TYuint:
                case TYlong:
                case TYulong:
                case TYllong:
                case TYullong:
                case TYcent:
                case TYucent:
#if !TARGET_FLAT
                case TYfptr:
                case TYhptr:
#endif
                case TYvptr:
                    *pretregs |= ALLREGS;
                    break;
            }
        }
        c = loaddata(e,pretregs);
        break;
  }
  cssave(e,*pretregs,!OTleaf(op));
  freenode(e);
L1:
#ifdef DEBUG
  if (debugw)
  {     printf("-codelem(e=%p,*pretregs=x%x) ",e,*pretregs);
        WROP(op);
        printf("msavereg=x%x regcon.cse.mval=x%x regcon.cse.mops=x%x\n",
                msavereg,regcon.cse.mval,regcon.cse.mops);
  }
#endif
    if (configv.addlinenumbers && e->Esrcpos.Slinnum)
        cgen_prelinnum(&c,e->Esrcpos);
    return c;
}

/*********************************************
 * Turn register mask into a string suitable for printing.
 */

#ifdef DEBUG

const char *regm_str(regm_t rm)
{
    #define NUM 4
    #define SMAX 64
    static char str[NUM][SMAX + 1];
    static int i;
    char *p;
    char *s;
    int j;

    if (rm == 0)
        return "0";
    if (rm == ALLREGS)
        return "ALLREGS";
    if (rm == BYTEREGS)
        return "BYTEREGS";
    if (rm == allregs)
        return "allregs";
    p = str[i];
    if (++i == NUM)
        i = 0;
    s = p;
    *p = 0;
    for (j = 0; j < 32; j++)
    {
        if (mask[j] & rm)
        {
            strcat(p,regstring[j]);
            rm &= ~mask[j];
            if (rm)
                strcat(p,"|");
        }
    }
    if (rm)
    {   s = p + strlen(p);
        sprintf(s,"x%02x",rm);
    }
    assert(strlen(p) <= SMAX);
    return strdup(p);
}

#endif

#endif // !SPP
