module dmd.backend.iasm;

import dmd.common;
import dmd.Dsymbol;
import dmd.LabelDsymbol;
import dmd.AsmStatement;
import dmd.Type;
import dmd.Scope;
import dmd.Loc;
import dmd.Token;
import dmd.TOK;
import dmd.Identifier;
import dmd.Declaration;
import dmd.VarDeclaration;
import dmd.EnumMember;
import dmd.ExpInitializer;
import dmd.Expression;
import dmd.IdentifierExp;
import dmd.StringExp;
import dmd.Global;
import dmd.WANT;
import dmd.STC;
import dmd.TY;
import dmd.EnumUtils;
import dmd.TupleDeclaration;
import dmd.VarExp;
import dmd.Id;
import dmd.FuncExp;
import dmd.DotIdExp;

import dmd.backend.code;
import dmd.backend.Srcpos;
import dmd.backend.FL;
import dmd.backend.Util;
import dmd.backend.regm_t;
import dmd.backend.Config;
import dmd.backend.targ_types;
import dmd.backend.elem;
import dmd.backend.block;
import dmd.Util;

import std.stdio : writef, writefln;
import std.string : toStringz;
import std.algorithm : min;

import core.memory;

import core.stdc.stdio : printf;
import core.stdc.string : strlen;
import core.stdc.stdlib : realloc;
import core.stdc.limits;

import std.bitmanip;

alias int[10] jmp_buf;

extern (C) extern 
{
	int setjmp(ref jmp_buf env);
	void longjmp(ref jmp_buf env, int value);
	
	void cod3_set386();
	code* genlinnum(code*, Srcpos);
	code *code_calloc();
	
	__gshared int BPRM;
}

enum const(char)*[ASMTK.ASMTKmax] apszAsmtk = [
	"__LOCAL_SIZE".ptr,
	"dword".ptr,
	"even".ptr,
	"far".ptr,
	"naked".ptr,
	"near".ptr,
	"ptr".ptr,
	"qword".ptr,
	"seg".ptr,
	"word".ptr,
];

version (Windows) {
	extern (Pascal) code * cat(code *c1,code *c2);
} else {
	extern (C) code * cat(code *c1,code *c2);
}

version (Bug4059)
{
	private extern(C) OP* _Z13asm_op_lookupPKc(const(char)* s);
	private extern(C) int _Z6binaryPKcPS0_i(const(char)* p , const(char)** tab, int high);
	OP* asm_op_lookup(const(char)* s) { return _Z13asm_op_lookupPKc(s); }
	int binary(const(char)* p , const(char)** tab, int high) { return _Z6binaryPKcPS0_i(p, tab, high); }
}
else
{
	extern (C++) {
		OP* asm_op_lookup(const(char)* s);
		int binary(const(char)* p , const(char)** tab, int high);
	}
}

extern (C++) //extern 
{
	void init_optab();
	const(char)* asm_opstr(OP* pop);
}

__gshared ubyte asm_TKlbra_seen = 0;

struct REG
{
	string regstr;
	ubyte val;
	opflag_t ty;
}

OP* asm_op_lookup(string s)
{
	return asm_op_lookup(toStringz(s));
}

// For amod (3 bits)
enum ASM_MODIFIERS : ubyte
{
    _normal,	    // Normal register value
    _rseg,	    // Segment registers
    _rspecial,	    // Special registers
    _addr16,	    // 16 bit address
    _addr32,	    // 32 bit address
    _fn16,	    // 16 bit function call
    _fn32,	    // 32 bit function call
    _flbl	    // Label
}

mixin(BringToCurrentScope!(ASM_MODIFIERS));

// For aopty (3 bits)
enum ASM_OPERAND_TYPE : ubyte
{
    _reg,	    // _r8, _r16, _r32
    _m,		    // _m8, _m16, _m32, _m48
    _imm,	    // _imm8, _imm16, _imm32
    _rel,	    // _rel8, _rel16, _rel32
    _mnoi,	    // _m1616, _m1632
    _p,		    // _p1616, _p1632
    _rm,	    // _rm8, _rm16, _rm32
    _float	    // Floating point operand, look at cRegmask for the
		    // actual size
}

mixin(BringToCurrentScope!(ASM_OPERAND_TYPE));

/* Register definitions */

enum AX	= 0;
enum CX	= 1;
enum DX	= 2;
enum BX	= 3;
enum SP	= 4;
enum BP	= 5;
enum SI	= 6;
enum DI	= 7;

enum ES	= 9;
enum PSW	= 10;
enum STACK	= 11;	// top of stack
enum MEM	= 12;	// memory
enum OTHER	= 13;	// other things
enum ST0	= 14;	// 8087 top of stack register
enum ST01	= 15;	// top two 8087 registers; for complex types

enum NOREG = 100;	// no register

enum AL = 0;
enum CL = 1;
enum DL = 2;
enum BL = 3;
enum AH = 4;
enum CH = 5;
enum DH = 6;
enum BH = 7;

enum mAX = 1;
enum mCX = 2;
enum mDX = 4;
enum mBX = 8;
enum mSP = 0x10;
enum mBP = 0x20;
enum mSI = 0x40;
enum mDI = 0x80;
enum mES = (1 << ES);	// 0x200
enum mPSW = (1 << PSW);	// 0x400

enum mSTACK = (1 << STACK);	// 0x800
enum mMEM = (1 << MEM);	// 0x1000
enum mOTHER = (1 << OTHER);	// 0x2000

enum mST0 = (1 << ST0);	// 0x4000
enum mST01 = (1 << ST01);	// 0x8000

version (POSIX) { ///TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
    // To support positional independent code,
    // must be able to remove BX from available registers
extern (C) extern __gshared regm_t ALLREGS;			
enum ALLREGS_INIT = (mAX|mBX|mCX|mDX|mSI|mDI);
enum ALLREGS_INIT_PIC = (mAX|mCX|mDX|mSI|mDI);
extern (C) extern regm_t BYTEREGS;			
enum BYTEREGS_INIT = (mAX|mBX|mCX|mDX);
enum BYTEREGS_INIT_PIC = (mAX|mCX|mDX);
} else {
enum ALLREGS = (mAX|mBX|mCX|mDX|mSI|mDI);
///#define ALLREGS_INIT		ALLREGS
///#undef BYTEREGS
///#define BYTEREGS		(mAX|mBX|mCX|mDX)
}

//#define NPTRSIZE	tysize[TYnptr]
enum NPTRSIZE = 4;

uint ADDFWAIT() { return 0; }

enum I16 = 0;		// no 16 bit code for D
enum I32 = (NPTRSIZE == 4);
enum I64 = (NPTRSIZE == 8);	// true if generating 64 bit code

// For uRegmask (6 bits)

// uRegmask flags when aopty == _float
enum _rst = 0x1;
enum _rsti = 0x2;
enum _64 = 0x4;
enum _80 = 0x8;
enum _128 = 0x40;
enum _112 = 0x10;
enum _224 = 0x20;

ushort CONSTRUCT_FLAGS(ushort uSizemask, ubyte aopty, ubyte amod, ushort uRegmask ) {
    return cast(ushort)( (uSizemask) | (aopty) << 4 | (amod) << 7 | (uRegmask) << 10);
}

// _seg register values (amod == _rseg)
//
enum _ds = CONSTRUCT_FLAGS( 0, 0, _rseg, 0x01 );
enum _es = CONSTRUCT_FLAGS( 0, 0, _rseg, 0x02 );
enum _ss = CONSTRUCT_FLAGS( 0, 0, _rseg, 0x04 );
enum _fs = CONSTRUCT_FLAGS( 0, 0, _rseg, 0x08 );
enum _gs = CONSTRUCT_FLAGS( 0, 0, _rseg, 0x10 );
enum _cs = CONSTRUCT_FLAGS( 0, 0, _rseg, 0x20 );

//
// _special register values
//
enum _crn = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._rspecial, 0x01 ); // CRn register (0,2,3)
enum _drn = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._rspecial, 0x02 ); // DRn register (0-3,6-7)
enum _trn = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._rspecial, 0x04 ); // TRn register (3-7)
enum _mm  = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._rspecial, 0x08 ); // MMn register (0-7)
enum _xmm = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._rspecial, 0x10 ); // XMMn register (0-7)

//
// Default register values
//
enum _al = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._normal, 0x01 );	// AL register
enum _ax = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._normal, 0x02 );	// AX register
enum _eax = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._normal, 0x04 );	// EAX register
enum _dx = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._normal, 0x08 );	// DX register
enum _cl = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._normal, 0x10 );	// CL register

enum _rplus_r = 0x20;
//#define _plus_r	CONSTRUCT_FLAGS( 0, 0, 0, _rplus_r )
		// Add the register to the opcode (no mod r/m)

ubyte ASM_GET_uSizemask(uint us) {
	return ((us) & 0x0F);
}

ASM_OPERAND_TYPE ASM_GET_aopty(uint us) {
	return cast(ASM_OPERAND_TYPE)(((us) & 0x70) >> 4);
}

ASM_MODIFIERS ASM_GET_amod(uint us)	{
	return (cast(ASM_MODIFIERS)(((us) & 0x380) >> 7));
}

ubyte ASM_GET_uRegmask(uint us) {
	return (((us) & 0xFC00) >> 10);
}

enum _st = CONSTRUCT_FLAGS( 0, _float, 0, _rst );	// stack register 0
enum _m112 = CONSTRUCT_FLAGS( 0, _m, 0, _112 );
enum _m224 = CONSTRUCT_FLAGS( 0, _m, 0, _224 );
enum _m512 = _m224;
enum _sti = CONSTRUCT_FLAGS( 0, _float, 0, _rsti );

__gshared REG regFp =	{ "ST", 0, _st };

enum REG[8] aregFp = [
	{ "ST(0)", 0, _sti },
	{ "ST(1)", 1, _sti },
	{ "ST(2)", 2, _sti },
	{ "ST(3)", 3, _sti },
	{ "ST(4)", 4, _sti },
	{ "ST(5)", 5, _sti },
	{ "ST(6)", 6, _sti },
	{ "ST(7)", 7, _sti }
];

// For uSizemask (4 bits)
enum _8  = 0x1;
enum _16 = 0x2;
enum _32 = 0x4;
enum _48 = 0x8;
enum _anysize = (_8 | _16 | _32 | _48 );

enum _modrm = 0x10;

//// This is for when the reg field of modregrm specifies which instruction it is
enum NUM_MASK = 0x7;
//#define _0	(0x0 | _modrm)		// insure that some _modrm bit is set
//#define _1	0x1			// with _0
//#define _2	0x2
//#define _3	0x3
//#define _4	0x4
//#define _5	0x5
//#define _6	0x6
//#define _7	0x7
//
//#define	_modrm	0x10
//
//#define _r	_modrm
//#define _cb	_modrm
//#define _cw	_modrm
//#define _cd	_modrm
//#define _cp	_modrm
//#define _ib	0
//#define _iw	0
//#define _id	0
//#define _rb	0
//#define _rw	0
//#define _rd	0
enum _16_bit = 0x20;
enum _32_bit = 0x40;
enum _I386 = 0x80;		// opcode is only for 386 and later
enum _16_bit_addr = 0x100;
enum _32_bit_addr = 0x200;
enum _fwait = 0x400;	// Add an FWAIT prior to the instruction opcode
enum _nfwait = 0x800;	// Do not add an FWAIT prior to the instruction

enum MOD_MASK = 0xF000;	// Mod mask
enum _modsi = 0x1000;	// Instruction modifies SI
enum _moddx = 0x2000;	// Instruction modifies DX
enum _mod2 = 0x3000;	// Instruction modifies second operand
enum _modax = 0x4000;	// Instruction modifies AX
enum _modnot1 = 0x5000;	// Instruction does not modify first operand
enum _modaxdx = 0x6000;	// instruction modifies AX and DX
enum _moddi = 0x7000;	// Instruction modifies DI
enum _modsidi = 0x8000;	// Instruction modifies SI and DI
enum _modcx	= 0x9000;	// Instruction modifies CX
enum _modes = 0xa000;	// Instruction modifies ES
enum _modall = 0xb000;	// Instruction modifies all register values
enum _modsiax = 0xc000;	// Instruction modifies AX and SI
enum _modsinot1 = 0xd000;	// Instruction modifies SI and not first param

/////////////////////////////////////////////////
// Operand flags - usOp1, usOp2, usOp3
//

alias ushort opflag_t;

// Operand flags for normal opcodes

enum _r8 = CONSTRUCT_FLAGS( _8, ASM_OPERAND_TYPE._reg, ASM_MODIFIERS._normal, 0 );
enum _r16 = CONSTRUCT_FLAGS(_16, ASM_OPERAND_TYPE._reg, ASM_MODIFIERS._normal, 0 );
enum _r32 = CONSTRUCT_FLAGS(_32, ASM_OPERAND_TYPE._reg, ASM_MODIFIERS._normal, 0 );
enum _m8 = CONSTRUCT_FLAGS(_8, ASM_OPERAND_TYPE._m, ASM_MODIFIERS._normal, 0 );
enum _m16 = CONSTRUCT_FLAGS(_16, ASM_OPERAND_TYPE._m, ASM_MODIFIERS._normal, 0 );
enum _m32 = CONSTRUCT_FLAGS(_32, ASM_OPERAND_TYPE._m, ASM_MODIFIERS._normal, 0 );
enum _m48 = CONSTRUCT_FLAGS( _48, ASM_OPERAND_TYPE._m, ASM_MODIFIERS._normal, 0 );
enum _m64 = CONSTRUCT_FLAGS( _anysize, ASM_OPERAND_TYPE._m, ASM_MODIFIERS._normal, 0 );
enum _m128 = CONSTRUCT_FLAGS( _anysize, ASM_OPERAND_TYPE._m, ASM_MODIFIERS._normal, 0 );
enum _rm8 = CONSTRUCT_FLAGS(_8, ASM_OPERAND_TYPE._rm, ASM_MODIFIERS._normal, 0 );
enum _rm16 = CONSTRUCT_FLAGS(_16, ASM_OPERAND_TYPE._rm, ASM_MODIFIERS._normal, 0 );
enum _rm32 = CONSTRUCT_FLAGS(_32, ASM_OPERAND_TYPE._rm, ASM_MODIFIERS._normal, 0);
enum _r32m16 = CONSTRUCT_FLAGS(_32|_16, ASM_OPERAND_TYPE._rm, ASM_MODIFIERS._normal, 0);
enum _imm8 = CONSTRUCT_FLAGS(_8, ASM_OPERAND_TYPE._imm, ASM_MODIFIERS._normal, 0 );
enum _imm16 = CONSTRUCT_FLAGS(_16, ASM_OPERAND_TYPE._imm, ASM_MODIFIERS._normal, 0);
enum _imm32 = CONSTRUCT_FLAGS(_32, ASM_OPERAND_TYPE._imm, ASM_MODIFIERS._normal, 0);
enum _rel8 = CONSTRUCT_FLAGS(_8, ASM_OPERAND_TYPE._rel, ASM_MODIFIERS._normal, 0);
enum _rel16 = CONSTRUCT_FLAGS(_16, ASM_OPERAND_TYPE._rel, ASM_MODIFIERS._normal, 0);
enum _rel32 = CONSTRUCT_FLAGS(_32, ASM_OPERAND_TYPE._rel, ASM_MODIFIERS._normal, 0);
enum _p1616 = CONSTRUCT_FLAGS(_32, ASM_OPERAND_TYPE._p, ASM_MODIFIERS._normal, 0);
enum _m1616 = CONSTRUCT_FLAGS(_32, ASM_OPERAND_TYPE._mnoi, ASM_MODIFIERS._normal, 0);
enum _p1632 = CONSTRUCT_FLAGS(_48, ASM_OPERAND_TYPE._p, ASM_MODIFIERS._normal, 0 );
enum _m1632 = CONSTRUCT_FLAGS(_48, ASM_OPERAND_TYPE._mnoi, ASM_MODIFIERS._normal, 0);
enum _special = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._rspecial, 0 );
enum _seg = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._rseg, 0 );
enum _a16 = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._addr16, 0 );
enum _a32 = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._addr32, 0 );
enum _f16 = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._fn16, 0);
						// Near function pointer
enum _f32 = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._fn32, 0);
						// Far function pointer
enum _lbl = CONSTRUCT_FLAGS( 0, 0, ASM_MODIFIERS._flbl, 0 );
						// Label (in current function)

enum _mmm32 = CONSTRUCT_FLAGS( 0, ASM_OPERAND_TYPE._m, 0, _32);
enum _mmm64 = CONSTRUCT_FLAGS( 0, ASM_OPERAND_TYPE._m, 0, _64);
enum _mmm128 = CONSTRUCT_FLAGS( 0, ASM_OPERAND_TYPE._m, 0, _128);

enum _xmm_m32 = CONSTRUCT_FLAGS( _32, ASM_OPERAND_TYPE._m, ASM_MODIFIERS._rspecial, 0);
enum _xmm_m64 =CONSTRUCT_FLAGS( _anysize, ASM_OPERAND_TYPE._m, ASM_MODIFIERS._rspecial, 0);
enum _xmm_m128 =CONSTRUCT_FLAGS( _anysize, ASM_OPERAND_TYPE._m, ASM_MODIFIERS._rspecial, 0);

enum _moffs8 = (_rel8);
enum _moffs16 = (_rel16 );
enum _moffs32 = (_rel32 );

////////////////////////////////////////////////////////////////////
// Operand flags for floating point opcodes are all just aliases for
// normal opcode variants and only asm_determine_operator_flags should
// need to care.
//
enum _fm80 = CONSTRUCT_FLAGS( 0, ASM_OPERAND_TYPE._m, 0, _80 );
enum _fm64 = CONSTRUCT_FLAGS( 0, ASM_OPERAND_TYPE._m, 0, _64 );
enum _fm128 = CONSTRUCT_FLAGS( 0, ASM_OPERAND_TYPE._m, 0, _128 );
enum _fanysize = (_64 | _80 | _112 | _224);

enum _AL 		=0;
enum _AH		=4;
enum _AX		=0;
enum _EAX		=0;
enum _BL		=3;
enum _BH		=7;
enum _BX		=3;
enum _EBX		=3;
enum _CL		=1;
enum _CH		=5;
enum _CX		=1;
enum _ECX		=1;
enum _DL		=2;
enum _DH		=6;
enum _DX		=2;
enum _EDX		=2;
enum _BP		=5;
enum _EBP		=5;
enum _SP		=4;
enum _ESP		=4;
enum _DI		=7;
enum _EDI		=7;
enum _SI		=6;
enum _ESI		=6;
enum _ES		=0;
enum _CS		=1;
enum _SS		=2;
enum _DS		=3;
enum _GS		=5;
enum _FS		=4;

enum ASM = 0x36;			// string of asm bytes, actually an SS: opcode
enum ASM_END = 0xffff;		// special opcode meaning end of table

struct PTRNTAB0
{
	uint usOpcode;
//	#define ASM_END	0xffff		// special opcode meaning end of table
	ushort usFlags;
}

struct PTRNTAB1
{
	uint usOpcode;
	ushort usFlags;
	opflag_t usOp1;
}

struct PTRNTAB2
{
	uint usOpcode;
	ushort usFlags;
	opflag_t usOp1;
	opflag_t usOp2;
}

struct PTRNTAB3
{
	uint usOpcode;
	ushort usFlags;
	opflag_t usOp1;
	opflag_t usOp2;
	opflag_t usOp3;
}

union PTRNTAB
{
	PTRNTAB0	*pptb0;
	PTRNTAB1	*pptb1;
	PTRNTAB2	*pptb2;
	PTRNTAB3	*pptb3;
}

struct OP
{
	ubyte usNumops;
	PTRNTAB	ptb;
}

enum ASM_JUMPTYPE
{
    ASM_JUMPTYPE_UNSPECIFIED,
    ASM_JUMPTYPE_SHORT,
    ASM_JUMPTYPE_NEAR,
    ASM_JUMPTYPE_FAR
}		    // ajt

mixin(BringToCurrentScope!(ASM_JUMPTYPE));

struct OPND
{
	REG* base;		// if plain register
	REG* pregDisp1;		// if [register1]
	REG* pregDisp2;
	REG* segreg;		// if segment override
	char indirect = 0;		// if had a '*' or '.'
	char bOffset = 0;		// if 'offset' keyword
	char bSeg = 0;		// if 'segment' keyword
	char bPtr = 0;		// if 'ptr' keyword
	uint uchMultiplier;	// register multiplier; valid values are 0,1,2,4,8
	opflag_t usFlags;
	Dsymbol s;
	int disp;
	real real_ = 0;
	Type ptype;
	ASM_JUMPTYPE ajt;
}

struct ASM_STATE
{
	ubyte ucItype;	// Instruction type
	Loc loc;
	ubyte bInit;
	LabelDsymbol psDollar;
	Dsymbol psLocalsize;
	jmp_buf env;
	ubyte bReturnax;
	AsmStatement statement;
	Scope sc;
}

enum IT
{
	ITprefix	= 0x10,	// special prefix
	ITjump		= 0x20,	// jump instructions CALL, Jxx and LOOPxx
	ITimmed		= 0x30,	// value of an immediate operand controls
						// code generation
	ITopt		= 0x40,	// not all operands are required
	ITshift		= 0x50,	// rotate and shift instructions
	ITfloat		= 0x60,	// floating point coprocessor instructions
	ITdata		= 0x70,	// DB, DW, DD, DQ, DT pseudo-ops
	ITaddr		= 0x80,	// DA (define addresss) pseudo-op
	ITMASK		= 0xF0,
	ITSIZE		= 0x0F,	// mask for size
}

alias IT.ITprefix ITprefix;
alias IT.ITjump ITjump;
alias IT.ITimmed ITimmed;
alias IT.ITopt ITopt;
alias IT.ITshift ITshift;
alias IT.ITfloat ITfloat;
alias IT.ITdata ITdata;
alias IT.ITaddr ITaddr;
alias IT.ITMASK ITMASK;
alias IT.ITSIZE ITSIZE;

ref ASM_STATE asmstate()
{
	return global.asmstate;
}

ref Token* asmtok()
{
	return global.asmtok;
}

void asmtok(Token* value)
{
	global.asmtok = value;
}

ref TOK tok_value()
{
	return global.tok_value;
}

void tok_value(TOK value)
{
	global.tok_value = value;
}

// Additional tokens for the inline assembler
enum ASMTK 
{
    ASMTKlocalsize = TOKMAX + 1,
    ASMTKdword,
    ASMTKeven,
    ASMTKfar,
    ASMTKnaked,
    ASMTKnear,
    ASMTKptr,
    ASMTKqword,
    ASMTKseg,
    ASMTKword,
    ASMTKmax = ASMTKword - (TOK.TOKMAX + 1) + 1
}

mixin(BringToCurrentScope!(ASMTK));

enum OP_DB
{
///version (SCPP) {
///    // These are the number of bytes
///    OPdb = 1,
///    OPdw = 2,
///    OPdd = 4,
///    OPdq = 8,
///    OPdt = 10,
///    OPdf = 4,
///    OPde = 10,
///    OPds = 2,
///    OPdi = 4,
///    OPdl = 8,
///}
///version (MARS) {
    // Integral types
    OPdb,
    OPds,
    OPdi,
    OPdl,

    // Float types
    OPdf,
    OPdd,
    OPde,

    // Deprecated
    OPdw = OPds,
    OPdq = OPdl,
    OPdt = OPde,
///}
}

OPND* opnd_calloc()
{   
	return new OPND();
}

void opnd_free(OPND* o)
{
    delete o;
}

/******************************
 * Convert assembly instruction into a code, and append
 * it to the code generated for this block.
 */

code* asm_emit(Loc loc, uint usNumops, PTRNTAB ptb, OP* pop, OPND* popnd1, OPND* popnd2, OPND* popnd3)
{
debug {
	ubyte[16] auchOpcode;
	uint usIdx = 0;
	void emit(ubyte op)	{
		auchOpcode[usIdx++] = op;
	}
} else {
	void emit(ubyte op) {}
}
	Identifier id;
//	ushort us;
	ubyte* puc;
	uint usDefaultseg;
	code* pc = null;
	OPND* popndTmp;
	ASM_OPERAND_TYPE aoptyTmp;
	ushort uSizemaskTmp;
	REG* pregSegment;
	code* pcPrefix = null;

	uint uSizemask1 = 0;
	uint uSizemask2 = 0;
	uint uSizemask3 = 0;

	//ASM_OPERAND_TYPE    aopty1 = ASM_OPERAND_TYPE._reg , aopty2 = 0, aopty3 = 0;
	ASM_MODIFIERS amod1 = ASM_MODIFIERS._normal;
	ASM_MODIFIERS amod2 = ASM_MODIFIERS._normal;
	ASM_MODIFIERS amod3 = ASM_MODIFIERS._normal;

	uint uRegmask1 = 0;
	uint uRegmask2 = 0;
	uint uRegmask3 = 0;
	
	uint uSizemaskTable1 = 0;
	uint uSizemaskTable2 = 0;
	uint uSizemaskTable3 = 0;

	ASM_OPERAND_TYPE aoptyTable1 = ASM_OPERAND_TYPE._reg;
	ASM_OPERAND_TYPE aoptyTable2 = ASM_OPERAND_TYPE._reg;
	ASM_OPERAND_TYPE aoptyTable3 = ASM_OPERAND_TYPE._reg;

	ASM_MODIFIERS amodTable1 = ASM_MODIFIERS._normal;
	ASM_MODIFIERS amodTable2 = ASM_MODIFIERS._normal;
	ASM_MODIFIERS amodTable3 = ASM_MODIFIERS._normal;

	uint uRegmaskTable1 = 0;
	uint uRegmaskTable2 = 0;
	uint uRegmaskTable3 = 0;
	
	pc = code_calloc();
	pc.Iflags |= CF.CFpsw;		// assume we want to keep the flags

	if (popnd1)
	{
	    uSizemask1 = ASM_GET_uSizemask(popnd1.usFlags);
	    //aopty1 = ASM_GET_aopty(popnd1.usFlags);
	    amod1 = ASM_GET_amod(popnd1.usFlags);
	    uRegmask1 = ASM_GET_uRegmask(popnd1.usFlags);

	    uSizemaskTable1 = ASM_GET_uSizemask(ptb.pptb1.usOp1);
	    aoptyTable1 = ASM_GET_aopty(ptb.pptb1.usOp1);
	    amodTable1 = ASM_GET_amod(ptb.pptb1.usOp1);
	    uRegmaskTable1 = ASM_GET_uRegmask(ptb.pptb1.usOp1);
	    
	}

	if (popnd2)
	{
static if (false) {
	    printf("\nasm_emit:\nop: ");
	    asm_output_flags(popnd2.usFlags);
	    printf("\ntb: ");
	    asm_output_flags(ptb.pptb2.usOp2);
	    printf("\n");
}
	    uSizemask2 = ASM_GET_uSizemask(popnd2.usFlags);
	    //aopty2 = ASM_GET_aopty(popnd2.usFlags);
	    amod2 = ASM_GET_amod(popnd2.usFlags);
	    uRegmask2 = ASM_GET_uRegmask(popnd2.usFlags);

	    uSizemaskTable2 = ASM_GET_uSizemask(ptb.pptb2.usOp2);
	    aoptyTable2 = ASM_GET_aopty(ptb.pptb2.usOp2);
	    amodTable2 = ASM_GET_amod(ptb.pptb2.usOp2);
	    uRegmaskTable2 = ASM_GET_uRegmask(ptb.pptb2.usOp2);
	}
	if (popnd3)
	{
	    uSizemask3 = ASM_GET_uSizemask(popnd3.usFlags);
	    //aopty3 = ASM_GET_aopty(popnd3.usFlags);
	    amod3 = ASM_GET_amod(popnd3.usFlags);
	    uRegmask3 = ASM_GET_uRegmask(popnd3.usFlags);

	    uSizemaskTable3 = ASM_GET_uSizemask(ptb.pptb3.usOp3);
	    aoptyTable3 = ASM_GET_aopty(ptb.pptb3.usOp3);
	    amodTable3 = ASM_GET_amod(ptb.pptb3.usOp3);
	    uRegmaskTable3 = ASM_GET_uRegmask(ptb.pptb3.usOp3);
	}

	asmstate.statement.regs |= asm_modify_regs(ptb, popnd1, popnd2);

	if (!I32 && ptb.pptb0.usFlags & _I386)
	{
	    switch (usNumops)
	    {
			case 0:
				break;

			case 1:
				if (popnd1 && popnd1.s)
				{
L386_WARNING:
					id = popnd1.s.ident;
L386_WARNING2:
					if (config.target_cpu < TARGET.TARGET_80386)
					{   
						// Reference to %s caused a 386 instruction to be generated
						//warerr(WM_386_op, id.toChars());
					}
				}
				break;

			case 2:
			case 3:	    // The third operand is always an ASM_OPERAND_TYPE._imm
				if (popnd1 && popnd1.s)
					goto L386_WARNING;
				if (popnd2 && popnd2.s)
				{
					id = popnd2.s.ident;
					goto L386_WARNING2;
				}
				break;

			default:
				assert(false);
	    }
	}

	switch (usNumops)
	{
	    case 0:
			if ((I32 && (ptb.pptb0.usFlags & _16_bit)) || (!I32 && (ptb.pptb0.usFlags & _32_bit)))
			{
				emit(0x66);
				pc.Iflags |= CF.CFopsize;
			}
			break;

	    // 3 and 2 are the same because the third operand is always
	    // an immediate and does not affect operation size
	    case 3:
	    case 2:
			if ((I32 && 
				  (amod2 == ASM_MODIFIERS._addr16 ||
				   (uSizemaskTable2 & _16 && aoptyTable2 == ASM_OPERAND_TYPE._rel) ||
				   (uSizemaskTable2 & _32 && aoptyTable2 == ASM_OPERAND_TYPE._mnoi) ||
				   (ptb.pptb2.usFlags & _16_bit_addr)
				 )
				) ||
				 (!I32 &&
				   (amod2 == ASM_MODIFIERS._addr32 ||
				(uSizemaskTable2 & _32 && aoptyTable2 == ASM_OPERAND_TYPE._rel) ||
				(uSizemaskTable2 & _48 && aoptyTable2 == ASM_OPERAND_TYPE._mnoi) ||
				(ptb.pptb2.usFlags & _32_bit_addr)))
			  )
			{
				emit(0x67);
				pc.Iflags |= CF.CFaddrsize;

				if (I32)
					amod2 = ASM_MODIFIERS._addr16;
				else
					amod2 = ASM_MODIFIERS._addr32;

				popnd2.usFlags &= ~CONSTRUCT_FLAGS(0,0,7,0);
				popnd2.usFlags |= CONSTRUCT_FLAGS(0,0,amod2,0);
			}


			/* Fall through, operand 1 controls the opsize, but the
			address size can be in either operand 1 or operand 2,
			hence the extra checking the flags tested for SHOULD
			be mutex on operand 1 and operand 2 because there is
			only one MOD R/M byte
			 */

	    case 1:
			if ((I32 &&
				  (amod1 == ASM_MODIFIERS._addr16 ||
				   (uSizemaskTable1 & _16 && aoptyTable1 == ASM_OPERAND_TYPE._rel) ||
					(uSizemaskTable1 & _32 && aoptyTable1 == ASM_OPERAND_TYPE._mnoi) ||
				(ptb.pptb1.usFlags & _16_bit_addr))) ||
				 (!I32 &&
				  (amod1 == ASM_MODIFIERS._addr32 ||
				(uSizemaskTable1 & _32 && aoptyTable1 == ASM_OPERAND_TYPE._rel) ||
				(uSizemaskTable1 & _48 && aoptyTable1 == ASM_OPERAND_TYPE._mnoi) ||
				 (ptb.pptb1.usFlags & _32_bit_addr))))
			{
				emit(0x67);	// address size prefix
				pc.Iflags |= CF.CFaddrsize;
				if (I32)
					amod1 = ASM_MODIFIERS._addr16;
				else
					amod1 = ASM_MODIFIERS._addr32;
				popnd1.usFlags &= ~CONSTRUCT_FLAGS(0,0,7,0);
				popnd1.usFlags |= CONSTRUCT_FLAGS(0,0,amod1,0);
			}

			// If the size of the operand is unknown, assume that it is
			// the default size
			if ((I32 && (ptb.pptb0.usFlags & _16_bit)) ||
				(!I32 && (ptb.pptb0.usFlags & _32_bit)))
			{
				//if (asmstate.ucItype != ITjump)
				{	emit(0x66);
				pc.Iflags |= CF.CFopsize;
				}
			}
			if (((pregSegment = (popndTmp = popnd1).segreg) != null) ||
				((popndTmp = popnd2) != null &&
				(pregSegment = popndTmp.segreg) != null)
			  )
			{
				if ((popndTmp.pregDisp1 &&
					popndTmp.pregDisp1.val == _BP) ||
					popndTmp.pregDisp2 &&
					popndTmp.pregDisp2.val == _BP)
					usDefaultseg = _SS;
				else
					usDefaultseg = _DS;
				if (pregSegment.val != usDefaultseg)
				switch (pregSegment.val) {
				case _CS:
					emit(0x2e);
					pc.Iflags |= CF.CFcs;
					break;
				case _SS:
					emit(0x36);
					pc.Iflags |= CF.CFss;
					break;
				case _DS:
					emit(0x3e);
					pc.Iflags |= CF.CFds;
					break;
				case _ES:
					emit(0x26);
					pc.Iflags |= CF.CFes;
					break;
				case _FS:
					emit(0x64);
					pc.Iflags |= CF.CFfs;
					break;
				case _GS:
					emit(0x65);
					pc.Iflags |= CF.CFgs;
					break;
				default:
					assert(0);
				}
			}
			break;
			
			default:
				assert(false);
		}
		uint usOpcode = ptb.pptb0.usOpcode;

		if ((usOpcode & 0xFFFFFF00) == 0x660F3A00 ||	// SSE4
			(usOpcode & 0xFFFFFF00) == 0x660F3800)	// SSE4
		{
			pc.Iflags |= CF.CFopsize;
			pc.Iop = 0x0F;
			pc.Iop2 = (usOpcode >> 8) & 0xFF;
			pc.Iop3 = usOpcode & 0xFF;
			goto L3;
		}
		switch (usOpcode & 0xFF0000)
		{
			case 0:
			break;

			case 0x660000:
			pc.Iflags |= CF.CFopsize;
			usOpcode &= 0xFFFF;
			break;

			case 0xF20000:			// REPNE
			case 0xF30000:			// REP/REPE
			// BUG: What if there's an address size prefix or segment
			// override prefix? Must the REP be adjacent to the rest
			// of the opcode?
			pcPrefix = code_calloc();
			pcPrefix.Iop = cast(ubyte)(usOpcode >> 16);
			usOpcode &= 0xFFFF;
			break;

			case 0x0F0000:			// an AMD instruction
			puc = (cast(ubyte*) &usOpcode);
			if (puc[1] != 0x0F)		// if not AMD instruction 0x0F0F
				goto L4;
			emit(puc[2]);
			emit(puc[1]);
			emit(puc[0]);
			pc.Iop = puc[2];
			pc.Iop2 = puc[1];
			pc.IEVint2() = puc[0];
			pc.IFL2 = FL.FLconst;
			goto L3;

			default:
			puc = (cast(ubyte*) &usOpcode);
			L4:
			emit(puc[2]);
			emit(puc[1]);
			emit(puc[0]);
			pc.Iop = puc[2];
			pc.Iop2 = puc[1];
			pc.Irm = puc[0];
			goto L3;
		}
		if (usOpcode & 0xff00)
		{
			puc = (cast(ubyte*) &(usOpcode));
			emit(puc[1]);
			emit(puc[0]);
			pc.Iop = puc[1];
			if (pc.Iop == 0x0f)
			pc.Iop2 = puc[0];
			else
			{
			if (usOpcode == 0xDFE0)	// FSTSW AX
			{   pc.Irm = puc[0];
				goto L2;
			}
			if (asmstate.ucItype == IT.ITfloat)
				pc.Irm = puc[0];
			else
			{   
				pc.IEVint2() = puc[0];
				pc.IFL2 = FL.FLconst;
			}
			}
		}
		else
		{
			emit(cast(ubyte)usOpcode);
			pc.Iop = cast(ubyte)usOpcode;
		}
    L3:	;

		// If CALL, Jxx or LOOPx to a symbolic location
		if (/*asmstate.ucItype == ITjump &&*/
			popnd1 && popnd1.s && popnd1.s.isLabel())
		{   
			Dsymbol s = popnd1.s;
			if (s == asmstate.psDollar)
			{
				pc.IFL2 = FL.FLconst;
				if (uSizemaskTable1 & (_8 | _16))
					pc.IEVint2() = popnd1.disp;
				else if (uSizemaskTable1 & _32)
					pc.IEVpointer2() = cast(targ_size_t) popnd1.disp;
			}   
			else
			{	
				LabelDsymbol label = s.isLabel();
				if (label)
				{   
					if ((pc.Iop & 0xF0) == 0x70)
						pc.Iflags |= CF.CFjmp16;
					if (usNumops == 1)
					{	
						pc.IFL2 = FL.FLblock;
						pc.IEVlsym2() = label;
					}
					else
					{	
						pc.IFL1 = FL.FLblock;
						pc.IEVlsym1() = label;
					}
				}
			}
	}

	switch (usNumops)
	{
	    case 0:
			break;

		case 1:
			if (((aoptyTable1 == ASM_OPERAND_TYPE._reg || aoptyTable1 == ASM_OPERAND_TYPE._float) &&
				 amodTable1 == ASM_MODIFIERS._normal && (uRegmaskTable1 & _rplus_r)))
			{
				if (asmstate.ucItype == IT.ITfloat)
					pc.Irm += popnd1.base.val;
				else if (pc.Iop == 0x0f)
					pc.Iop2 += popnd1.base.val;
				else
					pc.Iop += popnd1.base.val;
debug {
				auchOpcode[usIdx-1] += popnd1.base.val;
}
			}
			else
			{	
				debug asm_make_modrm_byte(
				auchOpcode, &usIdx,
				pc, 
				ptb.pptb1.usFlags,
				popnd1, null);
				else asm_make_modrm_byte(
				pc, 
				ptb.pptb1.usFlags,
				popnd1, null);
			}

			popndTmp = popnd1;
			aoptyTmp = aoptyTable1;
			uSizemaskTmp = cast(ushort)uSizemaskTable1;
	L1:
			if (aoptyTmp == ASM_OPERAND_TYPE._imm)
			{
				Declaration d = popndTmp.s ? popndTmp.s.isDeclaration() : null;
				if (popndTmp.bSeg)
				{
					if (!(d && d.isDataseg()))
						asmerr(ASMERRMSGS.EM_bad_addr_mode);	// illegal addressing mode
				}
				switch (uSizemaskTmp)
				{
					case _8:
					case _16:
					case _32:
						if (popndTmp.s is asmstate.psLocalsize)
						{
							pc.IFL2 = FL.FLlocalsize;
							pc.IEVdsym2() = null;
							pc.Iflags |= CF.CFoff;
							pc.IEVoffset2() = popndTmp.disp;
						}
						else if (d)
						{
static if (false) {
							if ((pc.IFL2 = d.Sfl) == 0)
								pc.IFL2 = FL.FLdsymbol;
} else {
							pc.IFL2 = FL.FLdsymbol;
}
							pc.Iflags &= ~(CF.CFseg | CF.CFoff);
							if (popndTmp.bSeg)
								pc.Iflags |= CF.CFseg;
							else
								pc.Iflags |= CF.CFoff;

							pc.IEVoffset2() = popndTmp.disp;
							pc.IEVdsym2() = d;
						}
						else
						{
							pc.IEVint2() = popndTmp.disp;
							pc.IFL2 = FL.FLconst;
						}
						break;
						
					default:
						assert(false);
				}
			}
				
			break;
		case 2:
	//
	// If there are two immediate operands then
	//
			if (aoptyTable1 == ASM_OPERAND_TYPE._imm && aoptyTable2 == ASM_OPERAND_TYPE._imm)
			{
				pc.IEVint1() = popnd1.disp;
				pc.IFL1 = FL.FLconst;
				pc.IEVint2() = popnd2.disp;
				pc.IFL2 = FL.FLconst;
				break;
			}
			if (aoptyTable2 == ASM_OPERAND_TYPE._m ||
				aoptyTable2 == ASM_OPERAND_TYPE._rel ||
				// If not MMX register (_mm) or XMM register (_xmm)
				(amodTable1 == ASM_MODIFIERS._rspecial && !(uRegmaskTable1 & (0x08 | 0x10)) && !uSizemaskTable1) ||
				aoptyTable2 == ASM_OPERAND_TYPE._rm ||
				(popnd1.usFlags == _r32 && popnd2.usFlags == _xmm) ||
				(popnd1.usFlags == _r32 && popnd2.usFlags == _mm))
			{
static if (false) {
				printf("test4 %d,%d,%d,%d\n",
				(aoptyTable2 == ASM_OPERAND_TYPE._m),
				(aoptyTable2 == ASM_OPERAND_TYPE._rel),
				(amodTable1 == ASM_MODIFIERS._rspecial && !(uRegmaskTable1 & (0x08 | 0x10))),
				(aoptyTable2 == ASM_OPERAND_TYPE._rm)
				);
				printf("usOpcode = %x\n", usOpcode);
}
				if (ptb.pptb0.usOpcode == 0x0F7E ||	// MOVD _rm32,_mm
					ptb.pptb0.usOpcode == 0x660F7E	// MOVD _rm32,_xmm
				   )
				{
					debug asm_make_modrm_byte(
						auchOpcode, &usIdx,
						pc, 
						ptb.pptb1.usFlags,
						popnd1, popnd2);
					else asm_make_modrm_byte(pc, ptb.pptb1.usFlags, popnd1, popnd2);
				}
				else
				{
					debug asm_make_modrm_byte(
						auchOpcode, &usIdx,
						pc, 
						ptb.pptb1.usFlags,
						popnd2, popnd1);
					else asm_make_modrm_byte(pc, ptb.pptb1.usFlags, popnd2, popnd1);
				}
				popndTmp = popnd1;
				aoptyTmp = aoptyTable1;
				uSizemaskTmp = cast(ushort)uSizemaskTable1;
			}
			else
			{
				if (((aoptyTable1 == ASM_OPERAND_TYPE._reg || aoptyTable1 == ASM_OPERAND_TYPE._float) &&
					 amodTable1 == ASM_MODIFIERS._normal &&
					 (uRegmaskTable1 & _rplus_r)))
				{
					if (asmstate.ucItype == IT.ITfloat)
						pc.Irm += popnd1.base.val;
					else if (pc.Iop == 0x0f)
						pc.Iop2 += popnd1.base.val;
					else
						pc.Iop += popnd1.base.val;
debug {
					auchOpcode[usIdx-1] += popnd1.base.val;
}
				}
				else if (((aoptyTable2 == ASM_OPERAND_TYPE._reg || aoptyTable2 == ASM_OPERAND_TYPE._float) &&
					 amodTable2 == ASM_MODIFIERS._normal &&
					 (uRegmaskTable2 & _rplus_r)))
				{
					if (asmstate.ucItype == IT.ITfloat)
						pc.Irm += popnd2.base.val;
					else if (pc.Iop == 0x0f)
						pc.Iop2 += popnd2.base.val;
					else
						pc.Iop += popnd2.base.val;
debug {
					auchOpcode[usIdx-1] += popnd2.base.val;
}
				}
				else if (ptb.pptb0.usOpcode == 0xF30FD6 ||
					 ptb.pptb0.usOpcode == 0x0F12 ||
					 ptb.pptb0.usOpcode == 0x0F16 ||
					 ptb.pptb0.usOpcode == 0x660F50 ||
					 ptb.pptb0.usOpcode == 0x0F50 ||
					 ptb.pptb0.usOpcode == 0x660FD7 ||
					 ptb.pptb0.usOpcode == 0x0FD7)
				{
					debug asm_make_modrm_byte(
///debug {
						auchOpcode, &usIdx,
///}
						pc, 
						ptb.pptb1.usFlags,
						popnd2, popnd1);
					else asm_make_modrm_byte(
						pc, 
						ptb.pptb1.usFlags,
						popnd2, popnd1); 
				}
				else
				{
					debug asm_make_modrm_byte(
///debug {
						auchOpcode, &usIdx,
///}
						pc, 
						ptb.pptb1.usFlags,
						popnd1, popnd2);
					else asm_make_modrm_byte(
						pc, 
						ptb.pptb1.usFlags,
						popnd1, popnd2); 

				}
				if (aoptyTable1 == ASM_OPERAND_TYPE._imm)
				{
					popndTmp = popnd1;
					aoptyTmp = aoptyTable1;
					uSizemaskTmp = cast(ushort)uSizemaskTable1;
				}
				else
				{
					popndTmp = popnd2;
					aoptyTmp = aoptyTable2;
					uSizemaskTmp = cast(ushort)uSizemaskTable2;
				}
			}
			goto L1;	

		case 3:
			if (aoptyTable2 == ASM_OPERAND_TYPE._m || aoptyTable2 == ASM_OPERAND_TYPE._rm ||
				usOpcode == 0x0FC5) // PEXTRW
			{
				debug asm_make_modrm_byte(
///debug {
					auchOpcode, &usIdx,
///}
					pc, 
					ptb.pptb1.usFlags,
					popnd2, popnd1);
				else asm_make_modrm_byte(
					pc, 
					ptb.pptb1.usFlags,
					popnd2, popnd1); 
				popndTmp = popnd3;
				aoptyTmp = aoptyTable3;
				uSizemaskTmp = cast(ushort)uSizemaskTable3;
			} else {
				if (((aoptyTable1 == ASM_OPERAND_TYPE._reg || aoptyTable1 == ASM_OPERAND_TYPE._float) &&
					 amodTable1 == ASM_MODIFIERS._normal &&
					 (uRegmaskTable1 &_rplus_r)))
				{
					if (asmstate.ucItype == IT.ITfloat)
						pc.Irm += popnd1.base.val;
					else if (pc.Iop == 0x0f)
						pc.Iop2 += popnd1.base.val;
					else
						pc.Iop += popnd1.base.val;
debug {
					auchOpcode[usIdx-1] += popnd1.base.val;
}
				}
				else if (((aoptyTable2 == ASM_OPERAND_TYPE._reg || aoptyTable2 == ASM_OPERAND_TYPE._float) &&
					 amodTable2 == ASM_MODIFIERS._normal &&
					 (uRegmaskTable2 &_rplus_r)))
				{
					if (asmstate.ucItype == IT.ITfloat)
						pc.Irm += popnd1.base.val;
					else if (pc.Iop == 0x0f)
						pc.Iop2 += popnd1.base.val;
					else
						pc.Iop += popnd2.base.val;
debug {
					auchOpcode[usIdx-1] += popnd2.base.val;
}
				}
				else
				{
					debug asm_make_modrm_byte(
///debug {
						auchOpcode, &usIdx,
///}
						pc, 
						ptb.pptb1.usFlags,
						popnd1, popnd2);
					else asm_make_modrm_byte(
						pc, 
						ptb.pptb1.usFlags,
						popnd1, popnd2); 
				}
				popndTmp = popnd3;
				aoptyTmp = aoptyTable3;
				uSizemaskTmp = cast(ushort)uSizemaskTable3;
			}
			goto L1;
			
		default:
			assert(false);
	}
L2:

	if ((pc.Iop & 0xF8) == 0xD8 &&
	    ADDFWAIT() &&
	    !(ptb.pptb0.usFlags & _nfwait))
		pc.Iflags |= CF.CFwait;
	else if ((ptb.pptb0.usFlags & _fwait) &&
	    config.target_cpu >= TARGET.TARGET_80386)
		pc.Iflags |= CF.CFwait;

debug {
	if (debuga)
	{   
		uint u;

	    for (u = 0; u < usIdx; u++) 
			printf("  %02X", auchOpcode[u]);
	
	    printf("\t%s\t", asm_opstr(pop));
	    if (popnd1)
			asm_output_popnd(popnd1);
	    if (popnd2) {
			printf(",");
			asm_output_popnd(popnd2);
	    }
	    if (popnd3) {
			printf(",");
			asm_output_popnd(popnd3);
	    }
	    printf("\n");
	}
}

	pc = cat(pcPrefix, pc);
	pc = asm_genloc(loc, pc);
	return pc;
}

void asm_token_trans(Token* tok)
{
    tok_value = TOK.TOKeof;

    if (tok)
    {
		tok_value = tok.value;
		if (tok_value == TOK.TOKidentifier)
		{   
			string id = tok.ident.toChars();
			size_t len = id.length;
			if (len < 20)
			{
				ASMTK asmtk = cast(ASMTK) binary(toStringz(id), apszAsmtk, ASMTK.ASMTKmax);
				
				if (cast(int)asmtk >= 0)
					tok_value = cast(TOK)(asmtk + TOK.TOKMAX + 1);
			}
		}
    }
}

void asm_token()
{
    if (asmtok)
		asmtok = asmtok.next;

    asm_token_trans(asmtok);
}


/**********************
 * If c is a power of 2, return that power else -1.
 */

int ispow2(ulong c)
{	
	int i;

	if (c == 0 || (c & (c - 1)))
	    i = -1;
	else
	    for (i = 0; c >>= 1; i++) {
			//;
		}

	return i;
}

// Error numbers
enum ASMERRMSGS
{
    EM_bad_float_op,
    EM_bad_addr_mode,
    EM_align,
    EM_opcode_exp,
    EM_prefix,
    EM_eol,
    EM_bad_operand,
    EM_bad_integral_operand,
    EM_ident_exp,
    EM_not_struct,
    EM_nops_expected,
    EM_bad_op,
    EM_const_init,
    EM_undefined,
    EM_pointer,
    EM_colon,
    EM_rbra,
    EM_rpar,
    EM_ptr_exp,
    EM_num,
    EM_float,
    EM_char,
    EM_label_expected,
    EM_uplevel,
    EM_type_as_operand,
}

mixin(BringToCurrentScope!(ASMERRMSGS));

enum string[] asmerrmsgs =
[
    "unknown operand for floating point instruction",
    "bad addr mode",
    "align %d must be a power of 2",
    "opcode expected, not %s",
    "prefix",
    "end of instruction",
    "bad operand",
    "bad integral operand",
    "identifier expected",
    "not struct",
    "nops expected",
    "bad type/size of operands '%s'",
    "constant initializer expected",
    "undefined identifier '%s'",
    "pointer",
    "colon",
    "] expected instead of '%s'",
    ") expected instead of '%s'",
    "ptr expected",
    "integer expected",
    "floating point expected",
    "character is truncated",
    "label expected",
    "uplevel nested reference to variable %s",
    "cannot use type %s as an operand"
];

void asmerr(T...)(int errnum, T t)
{   
    string format = asmerrmsgs[errnum];
	asmerr(format, t);
}

void asmerr(T...)(string format, T t)
{
    string p = asmstate.loc.toChars();
	if (p.length != 0)
		writef("%s: ", p);

	writefln(format, t);

    longjmp(asmstate.env,1);
}

PTRNTAB asm_classify(OP* pop, OPND* popnd1, OPND* popnd2, OPND* popnd3, uint* pusNumops)
{
	uint usNumops;
	uint usActual;
	PTRNTAB	ptbRet = { null };
	opflag_t usFlags1 = 0 ;
	opflag_t usFlags2 = 0;
	opflag_t usFlags3 = 0;

	PTRNTAB1 *pptb1; 
	PTRNTAB2 *pptb2;
	PTRNTAB3 *pptb3;

	char bFake = false;
	
	ubyte bMatch1, bMatch2, bMatch3, bRetry = false;

	// How many arguments are there?  the parser is strictly left to right
	// so this should work.

	if (!popnd1)
	    usNumops = 0;
	else
	{
	    popnd1.usFlags = usFlags1 = asm_determine_operand_flags(popnd1);
	    if (!popnd2) 
			usNumops = 1;
	    else
	    {
			popnd2.usFlags = usFlags2 = asm_determine_operand_flags(popnd2);
			if (!popnd3)
				usNumops = 2;
			else
			{
				popnd3.usFlags = usFlags3 = asm_determine_operand_flags(popnd3);
				usNumops = 3;
			}
		}
	}

	// Now check to insure that the number of operands is correct
	usActual = (pop.usNumops & IT.ITSIZE);
	if (usActual != usNumops && asmstate.ucItype != IT.ITopt &&
	    asmstate.ucItype != IT.ITfloat)
	{
PARAM_ERROR:
		asmerr(ASMERRMSGS.EM_nops_expected, usActual, asm_opstr(pop), usNumops);
	}
	*pusNumops = usNumops;
//
//	The number of arguments matches, now check to find the opcode
//	in the associated opcode table
//
RETRY:
	//printf("usActual = %d\n", usActual);
	switch (usActual)
	{
		default:
			assert(false);
			
	    case 0:
			ptbRet = pop.ptb ;
			goto RETURN_IT;

	    case 1:
			//printf("usFlags1 = "); asm_output_flags(usFlags1); printf("\n");
			for (pptb1 = pop.ptb.pptb1; pptb1.usOpcode != ASM_END;
				pptb1++)
			{
				//printf("table    = "); asm_output_flags(pptb1.usOp1); printf("\n");
				bMatch1 = asm_match_flags(usFlags1, pptb1.usOp1);
				if (bMatch1)
				{   if (pptb1.usOpcode == 0x68 &&
					I32 &&
					pptb1.usOp1 == _imm16
					  )
					// Don't match PUSH imm16 in 32 bit code
					continue;
					break;
				}
				if ((asmstate.ucItype == IT.ITimmed) &&
					asm_match_flags(usFlags1,
					CONSTRUCT_FLAGS(_8 | _16 | _32, ASM_OPERAND_TYPE._imm, ASM_MODIFIERS._normal,
							 0)) &&
					popnd1.disp == pptb1.usFlags)
					break;
				if ((asmstate.ucItype == IT.ITopt ||
					 asmstate.ucItype == IT.ITfloat) &&
					!usNumops &&
					!pptb1.usOp1)
				{
					if (usNumops > 1)
					goto PARAM_ERROR;
					break;
				}
			}
			if (pptb1.usOpcode == ASM_END)
			{
debug {
				if (debuga)
				{	
					printf("\t%s\t", asm_opstr(pop));
					if (popnd1)
						asm_output_popnd(popnd1);
					if (popnd2) {
						printf(",");
						asm_output_popnd(popnd2);
					}
					if (popnd3) {
						printf(",");
						asm_output_popnd(popnd3);
					}
					printf("\n");
					
					printf("OPCODE mism = ");
					if (popnd1)
						asm_output_flags(popnd1.usFlags);
					else
						printf("NONE");
					printf("\n");
				}
}
TYPE_SIZE_ERROR:
				if (popnd1 && ASM_GET_aopty(popnd1.usFlags) != ASM_OPERAND_TYPE._reg)
				{
					usFlags1 = popnd1.usFlags |= _anysize;
					if (asmstate.ucItype == IT.ITjump)
					{
						if (bRetry && popnd1.s && !popnd1.s.isLabel())
						{
							asmerr(ASMERRMSGS.EM_label_expected, popnd1.s.toChars());
						}

						popnd1.usFlags |= CONSTRUCT_FLAGS(0, 0, 0, _fanysize);
					}
				}	
				if (popnd2 && ASM_GET_aopty(popnd2.usFlags) != ASM_OPERAND_TYPE._reg) {
					usFlags2 = popnd2.usFlags |= (_anysize);
					if (asmstate.ucItype == IT.ITjump)
					popnd2.usFlags |= CONSTRUCT_FLAGS(0, 0, 0,
						_fanysize);
				}	
				if (popnd3 && ASM_GET_aopty(popnd3.usFlags) != ASM_OPERAND_TYPE._reg) {
					usFlags3 = popnd3.usFlags |= (_anysize);
					if (asmstate.ucItype == IT.ITjump)
					popnd3.usFlags |= CONSTRUCT_FLAGS(0, 0, 0,
						_fanysize);
				}
				if (bRetry)
				{
					asmerr(ASMERRMSGS.EM_bad_op, fromStringz(asm_opstr(pop)));	// illegal type/size of operands
				}
				bRetry = true;
				goto RETRY;
			}
			ptbRet.pptb1 = pptb1;
			goto RETURN_IT;

	    case 2:
			//printf("usFlags1 = "); asm_output_flags(usFlags1); printf(" ");
			//printf("usFlags2 = "); asm_output_flags(usFlags2); printf("\n");
			for (pptb2 = pop.ptb.pptb2;
				 pptb2.usOpcode != ASM_END;
				 pptb2++)
			{
				//printf("table1   = "); asm_output_flags(pptb2.usOp1); printf(" ");
				//printf("table2   = "); asm_output_flags(pptb2.usOp2); printf("\n");
				bMatch1 = asm_match_flags(usFlags1, pptb2.usOp1);
				bMatch2 = asm_match_flags(usFlags2, pptb2.usOp2);
				//printf("match1 = %d, match2 = %d\n",bMatch1,bMatch2);
				if (bMatch1 && bMatch2) {

					//printf("match\n");

					// OK, if they both match and the first op in the table is not AL 
					// or size of 8 and the second is immediate 8,
					// then check to see if the constant
					// is a signed 8 bit constant.  If so, then do not match, otherwise match
					//
					if (!bRetry &&
						!((ASM_GET_uSizemask(pptb2.usOp1) & _8) ||
						  (ASM_GET_uRegmask(pptb2.usOp1) & _al)) &&
						(ASM_GET_aopty(pptb2.usOp2) == ASM_OPERAND_TYPE._imm) &&
						(ASM_GET_uSizemask(pptb2.usOp2) & _8))
					{
						if (popnd2.disp <= char.max)
							break;
						else
							bFake = true;
					}
					else
						break;
				}
				if (asmstate.ucItype == IT.ITopt || asmstate.ucItype == IT.ITfloat)
				{
					switch (usNumops)
					{
						case 0:
							if (!pptb2.usOp1)
								goto Lfound2;
							break;
						case 1:
							if (bMatch1 && !pptb2.usOp2)
								goto Lfound2;
							break;
						case 2:
							break;
						default:
							goto PARAM_ERROR;
					}
				}
static if (false) {
				if (asmstate.ucItype == IT.ITshift &&
					!pptb2.usOp2 &&
					bMatch1 && popnd2.disp == 1 &&
					asm_match_flags(usFlags2,
					CONSTRUCT_FLAGS(_8|_16|_32, ASM_OPERAND_TYPE._imm,ASM_MODIFIERS._normal,0))
				  )
				{
					break;
				}
}
			}
			Lfound2:
			if (pptb2.usOpcode == ASM_END)
			{
debug {
				if (debuga)
				{	
					printf("\t%s\t", asm_opstr(pop));
					if (popnd1)
						asm_output_popnd(popnd1);
					if (popnd2) {
						printf(",");
						asm_output_popnd(popnd2);
					}
					if (popnd3) {
						printf(",");
						asm_output_popnd(popnd3);
					}
					printf("\n");
					
					printf("OPCODE mismatch = ");
					if (popnd1)
						asm_output_flags(popnd1.usFlags);
					else
						printf("NONE");
					printf( " Op2 = ");
					if (popnd2)
						asm_output_flags(popnd2.usFlags);
					else
						printf("NONE");
					printf("\n");
				}
}
				goto TYPE_SIZE_ERROR;
			}
			ptbRet.pptb2 = pptb2;
			goto RETURN_IT;

		case 3:
			for (pptb3 = pop.ptb.pptb3;
				 pptb3.usOpcode != ASM_END;
				 pptb3++)
			{
				bMatch1 = asm_match_flags(usFlags1, pptb3.usOp1);
				bMatch2 = asm_match_flags(usFlags2, pptb3.usOp2);
				bMatch3 = asm_match_flags(usFlags3, pptb3.usOp3);
				if (bMatch1 && bMatch2 && bMatch3)
					goto Lfound3;

				if (asmstate.ucItype == IT.ITopt)
				{
					switch (usNumops)
					{
					case 0:
						if (!pptb3.usOp1)
							goto Lfound3;
						break;
					case 1:
						if (bMatch1 && !pptb3.usOp2)
							goto Lfound3;
						break;
					case 2:
						if (bMatch1 && bMatch2 && !pptb3.usOp3)
							goto Lfound3;
						break;
					case 3:
						break;
					default:
						goto PARAM_ERROR;
					}
				}
			}
			Lfound3:
			if (pptb3.usOpcode == ASM_END)
			{
debug {
				if (debuga)
				{	
					printf("\t%s\t", asm_opstr(pop));
					if (popnd1)
						asm_output_popnd(popnd1);
					if (popnd2) {
						printf(",");
						asm_output_popnd(popnd2);
					}
					if (popnd3) {
						printf(",");
						asm_output_popnd(popnd3);
					}
					printf("\n");
					
					printf("OPCODE mismatch = ");
					if (popnd1)
						asm_output_flags(popnd1.usFlags);
					else
						printf("NONE");
					printf( " Op2 = ");
					if (popnd2)
						asm_output_flags(popnd2.usFlags);
					else
						printf("NONE");
					if (popnd3)
						asm_output_flags(popnd3.usFlags);
					printf("\n");
				}
}
				goto TYPE_SIZE_ERROR;
			}

			ptbRet.pptb3 = pptb3;
			goto RETURN_IT;
	}

RETURN_IT:
	if (bRetry && !bFake)
	{
	    asmerr(ASMERRMSGS.EM_bad_op, fromStringz(asm_opstr(pop)));
	}
	return ptbRet;
}

/*******************************
 *	start of inline assemblers expression parser
 *	NOTE: functions in call order instead of alphabetical
 */

/*******************************************
 * Parse DA expression
 *
 * Very limited define address to place a code
 * address in the assembly
 * Problems:
 *	o	Should use dw offset and dd offset instead,
 *		for near/far support.
 *	o	Should be able to add an offset to the label address.
 *	o	Blocks addressed by DA should get their Bpred set correctly
 *		for optimizer.
 */

code* asm_da_parse(OP* pop)
{
    code* clst = null;
    elem* e;
    
    while (1)
    {	
		code* c;

		if (tok_value == TOK.TOKidentifier)
		{
			LabelDsymbol label = asmstate.sc.func.searchLabel(asmtok.ident);
			if (!label)
				error(asmstate.loc, "label '%s' not found\n", asmtok.ident.toChars());

			c = code_calloc();
			c.Iop = ASM;
			c.Iflags = CF.CFaddrsize;
			c.IFL1 = FL.FLblockoff;
			c.IEVlsym1() = label;
			c = asm_genloc(asmstate.loc, c);
			clst = cat(clst,c);
		}
		else
			asmerr(ASMERRMSGS.EM_bad_addr_mode);	// illegal addressing mode

		asm_token();
		if (tok_value != TOK.TOKcomma)
			break;

		asm_token();
    }
    
    asmstate.statement.regs |= mES | ALLREGS;
    asmstate.bReturnax = true;

    return clst;
}

/*******************************************
 * Parse DB, DW, DD, DQ and DT expressions.
 */

code* asm_db_parse(OP* pop)
{
    uint usSize;
    uint usMaxbytes;
    uint usBytes;

    union DT
    {	
		targ_ullong ul;
		targ_float f;
		targ_double d;
		targ_ldouble ld;
		char[10] value;
    }
	
	DT dt;

    code* c;
    uint op;
    enum ubyte[7] opsize = [ 1,2,4,8,4,8,10 ];

    op = pop.usNumops & IT.ITSIZE;
    usSize = opsize[op];

    usBytes = 0;
    usMaxbytes = 0;
    c = code_calloc();
    c.Iop = ASM;
    
    while (1)
    {
		size_t len;
		ubyte* q;

		if (usBytes+usSize > usMaxbytes)
		{   
			usMaxbytes = usBytes + usSize + 10;
			c.IEV1.as.bytes = cast(char*)realloc(c.IEV1.as.bytes,usMaxbytes);
		}
		switch (tok_value)
		{
			case TOK.TOKint32v:
				dt.ul = asmtok.int32value;
				goto L1;
			case TOK.TOKuns32v:
				dt.ul = asmtok.uns32value;
				goto L1;
			case TOK.TOKint64v:
				dt.ul = asmtok.int64value;
				goto L1;
			case TOK.TOKuns64v:
				dt.ul = asmtok.uns64value;
				goto L1;
			L1:
				switch (op)
				{
					case OP_DB.OPdb:
					case OP_DB.OPds:
					case OP_DB.OPdi:
					case OP_DB.OPdl:
						break;
					default:
						asmerr(ASMERRMSGS.EM_float);
				}
				goto L2;

			case TOK.TOKfloat32v:
			case TOK.TOKfloat64v:
			case TOK.TOKfloat80v:
				switch (op)
				{
					case OP_DB.OPdf:
						dt.f = asmtok.float80value;
						break;
					case OP_DB.OPdd:
						dt.d = asmtok.float80value;
						break;
					case OP_DB.OPde:
						dt.ld = asmtok.float80value;
						break;
					default:
						asmerr(ASMERRMSGS.EM_num);
				}
				goto L2;

			L2:
				memcpy(c.IEV1.as.bytes + usBytes,&dt,usSize);
				usBytes += usSize;
				break;

			case TOK.TOKstring:
				len = asmtok.len;
				q = cast(ubyte*)asmtok.ustring;
				L3:
				if (len)
				{
					usMaxbytes += len * usSize;
					c.IEV1.as.bytes =  cast(char*)realloc(c.IEV1.as.bytes,usMaxbytes);
					memcpy(c.IEV1.as.bytes + usBytes,asmtok.ustring,len);

					char* p = c.IEV1.as.bytes + usBytes;
					for (size_t i = 0; i < len; i++)
					{
						// Be careful that this works
						memset(p, 0, usSize);
						switch (op)
						{
							case OP_DB.OPdb:
								*p = cast(ubyte)*q;
								if (*p != *q)
									asmerr(ASMERRMSGS.EM_char);
								break;

							case OP_DB.OPds:
								*cast(short*)p = *cast(ubyte*)q;
								if (*cast(short*)p != *q)
									asmerr(ASMERRMSGS.EM_char);
								break;

							case OP_DB.OPdi:
							case OP_DB.OPdl:
								*cast(int*)p = *q;
								break;

							default:
								asmerr(ASMERRMSGS.EM_float);
						}
						q++;
						p += usSize;
					}

					usBytes += len * usSize;
				}
				break;

			case TOK.TOKidentifier:
			{
				Expression e = new IdentifierExp(asmstate.loc, asmtok.ident);
				e = e.semantic(asmstate.sc);
				e = e.optimize(WANT.WANTvalue | WANT.WANTinterpret);
				if (e.op == TOK.TOKint64)
				{   
					dt.ul = e.toInteger();
					goto L2;
				}
				else if (e.op == TOK.TOKfloat64)
				{
					switch (op)
					{
					case OP_DB.OPdf:
						dt.f = e.toReal();
						break;
					case OP_DB.OPdd:
						dt.d = e.toReal();
						break;
					case OP_DB.OPde:
						dt.ld = e.toReal();
						break;
					default:
						asmerr(ASMERRMSGS.EM_num);
					}
					goto L2;
				}
				else if (e.op == TOK.TOKstring)
				{   
					StringExp se = cast(StringExp)e;
					q = cast(ubyte*)se.string_;
					len = se.len;
					goto L3;
				}
				goto Ldefault;
			}

			default:
				Ldefault:
				asmerr(ASMERRMSGS.EM_const_init);		// constant initializer
				break;
		}
		c.IEV1.as.len = usBytes;

		asm_token();
		if (tok_value != TOK.TOKcomma)
			break;

		asm_token();
    }

    c = asm_genloc(asmstate.loc, c);

    asmstate.statement.regs |= /* mES| */ ALLREGS;
    asmstate.bReturnax = true;

    return c;
}

/**********************************
 * Parse and get integer expression.
 */

int asm_getnum()
{   
	int v;
    long i;

    switch (tok_value)
    {
		case TOK.TOKint32v:
			v = asmtok.int32value;
			break;

		case TOK.TOKuns32v:
			v = asmtok.uns32value;
			break;

		case TOK.TOKidentifier:
			Expression e = new IdentifierExp(asmstate.loc, asmtok.ident);
			e = e.semantic(asmstate.sc);
			e = e.optimize(WANT.WANTvalue | WANT.WANTinterpret);
			i = e.toInteger();
			v = cast(int) i;
			if (v != i)
				asmerr(ASMERRMSGS.EM_num);
			break;

		default:
			asmerr(ASMERRMSGS.EM_num);
			break;
    }

    asm_token();

    return v;
}


/*******************************
 */

OPND* asm_cond_exp()
{
    OPND* o1;
	OPND* o2;
	OPND* o3;

    //printf("asm_cond_exp()\n");
    o1 = asm_log_or_exp();
    if (tok_value == TOK.TOKquestion)
    {
		asm_token();
		o2 = asm_cond_exp();
		asm_token();
		asm_chktok(TOK.TOKcolon, ASMERRMSGS.EM_colon);
		o3 = asm_cond_exp();
		o1 = (o1.disp) ? o2 : o3;
    }

    return o1;
}

regm_t asm_modify_regs(PTRNTAB ptb, OPND* popnd1, OPND* popnd2)
{
    regm_t usRet = 0;
    
    switch (ptb.pptb0.usFlags & MOD_MASK) {
		case _modsi:
			usRet |= mSI;
			break;
		case _moddx:
			usRet |= mDX;
			break;
		case _mod2:
			if (popnd2)
				usRet |= asm_modify_regs(ptb, popnd2, null);
			break;
		case _modax:
			usRet |= mAX;
			break;
		case _modnot1:
			popnd1 = null;
			break;
		case _modaxdx:
			usRet |= (mAX | mDX);
			break;
		case _moddi:
			usRet |= mDI;
			break;
		case _modsidi:
			usRet |= (mSI | mDI);
			break;
		case _modcx:
			usRet |= mCX;
			break;
		case _modes:
			/*usRet |= mES;*/
			break;
		case _modall:
			asmstate.bReturnax = true;
			return /*mES |*/ ALLREGS;
		case _modsiax:
			usRet |= (mSI | mAX);
			break;
		case _modsinot1:
			usRet |= mSI;
			popnd1 = null;
			break;
		default:
			break;	///
    }
    if (popnd1 && ASM_GET_aopty(popnd1.usFlags) == ASM_OPERAND_TYPE._reg) {
		switch (ASM_GET_amod(popnd1.usFlags)) {
			default:
				if (ASM_GET_uSizemask(popnd1.usFlags) == _8) {
					switch(popnd1.base.val) {
						default:
							assert(false);
						case _AL:
						case _AH:
							usRet |= mAX;
							break;
						case _BL:
						case _BH:
							usRet |= mBX;
							break;
						case _CL:
						case _CH:
							usRet |= mCX;
							break;
						case _DL:
						case _DH:
							usRet |= mDX;
							break;
					}
				}
				else {
					switch (popnd1.base.val) {
						case _AX:
							usRet |= mAX;
							break;
						case _BX:
							usRet |= mBX;
							break;
						case _CX:
							usRet |= mCX;
							break;
						case _DX:
							usRet |= mDX;
							break;
						case _SI:
							usRet |= mSI;
							break;
						case _DI:
							usRet |= mDI;
							break;
						default:
							break;	///
					}
				}
				break;

			case ASM_MODIFIERS._rseg:
				//if (popnd1.base.val == _ES)
				//usRet |= mES;
				break;
			
			case ASM_MODIFIERS._rspecial:
				break;
		}
    }
    if (usRet & mAX)
		asmstate.bReturnax = true;
    
    return usRet;
}


/****************************
 * Fill in the modregrm and sib bytes of code.
 */
 
uint X(ubyte r1, ubyte r2) {
	return (((r1) * 16) + (r2));
}

uint Y(ubyte r1) {
	return X(r1, 9);
}

// Save a copy/pasted function
template Tuple(T...) { alias T Tuple; }
debug alias Tuple!(ubyte[], uint*) asm_make_modrm_args;
else alias Tuple!() asm_make_modrm_args;

void asm_make_modrm_byte(asm_make_modrm_args ocidx, code *pc, ushort usFlags, OPND *popnd, OPND *popnd2)
{
///    #undef modregrm
debug alias ocidx[0] puchOpcode;
debug alias ocidx[1] pusIdx;
    union MODRM_BYTE			// mrmb
	{
		struct MODRM
		{
			mixin(bitfields!(
				uint, "rm",    	3,
				uint, "reg",   	3,
				uint, "mod",   	2));
		}
		
		ubyte uchOpcode;
		MODRM modregrm;
    }

    union SIB_BYTE
	{
		struct SIB
		{
			
			mixin(bitfields!(
				uint, "base",	3,
				uint, "index",	3,
				uint, "ss",		2));
		}
		
		ubyte uchOpcode;
		SIB sib;
    }
	

    MODRM_BYTE	mrmb;
    SIB_BYTE	sib;
    char		bSib = false;
    char		bDisp = false;
    char		b32bit = false;
    ubyte* 		puc;
    char		bModset = false;
    Dsymbol		s;
    
    uint uSizemask = 0;
    ASM_OPERAND_TYPE    aopty;
    ASM_MODIFIERS	    amod;
    ushort uRegmask;
    ubyte bOffsetsym = false;

static if (false) {
    printf("asm_make_modrm_byte(usFlags = x%x)\n", usFlags);
    printf("op1: ");
    asm_output_flags(popnd.usFlags);
    if (popnd2)
    {	
		printf(" op2: ");
		asm_output_flags(popnd2.usFlags);
    }
    printf("\n");
}

    uSizemask = ASM_GET_uSizemask(popnd.usFlags);
    aopty = ASM_GET_aopty(popnd.usFlags);
    amod = ASM_GET_amod(popnd.usFlags);
    uRegmask = ASM_GET_uRegmask(popnd.usFlags);
    s = popnd.s;
    if (s)
    {
		Declaration d = s.isDeclaration();

		if (amod == ASM_MODIFIERS._fn16 && aopty == ASM_OPERAND_TYPE._rel && popnd2)
		{   
			aopty = ASM_OPERAND_TYPE._m;
			goto L1;
		}

		if (amod == ASM_MODIFIERS._fn16 || amod == ASM_MODIFIERS._fn32)
		{
			pc.Iflags |= CF.CFoff;
debug {
			puchOpcode[(*pusIdx)++] = 0;
			puchOpcode[(*pusIdx)++] = 0;
}
			if (aopty == ASM_OPERAND_TYPE._m || aopty == ASM_OPERAND_TYPE._mnoi)
			{
				pc.IFL1 = FL.FLdata;
				pc.IEVdsym1() = d;
				pc.IEVoffset1() = 0;
			}
			else
			{
				if (aopty == ASM_OPERAND_TYPE._p)
					pc.Iflags |= CF.CFseg;
				
				debug if (aopty == ASM_OPERAND_TYPE._p || aopty == ASM_OPERAND_TYPE._rel)
				{   
					puchOpcode[(*pusIdx)++] = 0;
					puchOpcode[(*pusIdx)++] = 0;
				}

				pc.IFL2 = FL.FLfunc;
				pc.IEVdsym2() = d;
				pc.IEVoffset2() = 0;
				//return;
			}
		}
		else
		{
		  L1:
			LabelDsymbol label = s.isLabel();
			if (label)
			{
				if (s == asmstate.psDollar)
				{
					pc.IFL1 = FL.FLconst;
					if (uSizemask & (_8 | _16))
						pc.IEVint1() = popnd.disp;
					else if (uSizemask & _32)
						pc.IEVpointer1() = cast(targ_size_t) popnd.disp;
				}
				else
				{   
					pc.IFL1 = FL.FLblockoff;
					pc.IEVlsym1() = label;
				}
			}
			else if (s == asmstate.psLocalsize)
			{
				pc.IFL1 = FL.FLlocalsize;
				pc.IEVdsym1() = null;
				pc.Iflags |= CF.CFoff;
				pc.IEVoffset1() = popnd.disp;
			}
			else if (s.isFuncDeclaration())
			{
				pc.IFL1 = FL.FLfunc;
				pc.IEVdsym1() = d;
				pc.IEVoffset1() = popnd.disp;
			}
			else
			{
				debug if (debuga)
				{
					char* h = cast(char*) d.ident.toChars();
					printf("Setting up symbol %s\n", h);
				}
				pc.IFL1 = FL.FLdsymbol;
				pc.IEVdsym1() = d;
				pc.Iflags |= CF.CFoff;
				pc.IEVoffset1() = popnd.disp;
			}
		}
    }

    mrmb.modregrm.reg = usFlags & NUM_MASK;

    if (s && (aopty == ASM_OPERAND_TYPE._m || aopty == ASM_OPERAND_TYPE._mnoi) && !s.isLabel())
    {
		if (s == asmstate.psLocalsize)
		{
		DATA_REF:
			mrmb.modregrm.rm = BPRM;
			if (amod == ASM_MODIFIERS._addr16 || amod == ASM_MODIFIERS._addr32)
				mrmb.modregrm.mod = 0x2;
			else
				mrmb.modregrm.mod = 0x0;
		}
		else
		{
			Declaration d = s.isDeclaration();
			assert(d);
			if (d.isDataseg() || d.isCodeseg())
			{
				if (( I32 && amod == ASM_MODIFIERS._addr16) ||
					(!I32 && amod == ASM_MODIFIERS._addr32))
					asmerr(ASMERRMSGS.EM_bad_addr_mode);	// illegal addressing mode
				goto DATA_REF;
			}
			mrmb.modregrm.rm = BPRM;
			mrmb.modregrm.mod = 0x2;
		}
    }
    
    if (aopty == ASM_OPERAND_TYPE._reg || amod == ASM_MODIFIERS._rspecial) {
	    mrmb.modregrm.mod = 0x3;
	    mrmb.modregrm.rm = mrmb.modregrm.rm | popnd.base.val;
    }
    else if (amod == ASM_MODIFIERS._addr16 || (amod == ASM_MODIFIERS._flbl && !I32))
    {   
		uint rm;

		debug if (debuga)
			printf("This is an ADDR16\n");

		if (!popnd.pregDisp1)
		{   rm = 0x6;
			if (!s)
			bDisp = true;
		}
		else
		{   
			uint r1r2;

			if (popnd.pregDisp2)
				r1r2 = X(popnd.pregDisp1.val,popnd.pregDisp2.val);
			else
				r1r2 = Y(popnd.pregDisp1.val);

			switch (r1r2)
			{
				case X(_BX,_SI):	rm = 0;	break;
				case X(_BX,_DI):	rm = 1;	break;
				case Y(_BX):		rm = 7;	break;

				case X(_BP,_SI):	rm = 2;	break;
				case X(_BP,_DI):	rm = 3;	break;
				case Y(_BP):		rm = 6;	bDisp = true;	break;

				case X(_SI,_BX):	rm = 0;	break;
				case X(_SI,_BP):	rm = 2;	break;
				case Y(_SI):		rm = 4;	break;

				case X(_DI,_BX):	rm = 1;	break;
				case X(_DI,_BP):	rm = 3;	break;
				case Y(_DI):		rm = 5;	break;

				default:
					asmerr(ASMERRMSGS.EM_bad_addr_mode);	// illegal addressing mode
			}
		}
		mrmb.modregrm.rm = rm;

		debug if (debuga)
			printf("This is an mod = %d, popnd.s =%ld, popnd.disp = %ld\n",
			   mrmb.modregrm.mod, s, popnd.disp);

		if (!s || (!mrmb.modregrm.mod && popnd.disp))
		{
			if ((!popnd.disp && !bDisp) || !popnd.pregDisp1)
				mrmb.modregrm.mod = 0x0;
			else if (popnd.disp >= CHAR_MIN && popnd.disp <= SCHAR_MAX)
				mrmb.modregrm.mod = 0x1;
			else
				mrmb.modregrm.mod = 0X2;
		}
		else
			bOffsetsym = true;
	    
    }
    else if (amod == ASM_MODIFIERS._addr32 || (amod == ASM_MODIFIERS._flbl && I32))
    {
		debug if (debuga)
			printf("This is an ADDR32\n");

		if (!popnd.pregDisp1)
			mrmb.modregrm.rm = 0x5;
		else if (popnd.pregDisp2 || 
			 popnd.uchMultiplier ||
			 popnd.pregDisp1.val == _ESP)
		{
			if (popnd.pregDisp2)
			{   
				if (popnd.pregDisp2.val == _ESP)
					asmerr(ASMERRMSGS.EM_bad_addr_mode);	// illegal addressing mode
			}
			else
			{   
				if (popnd.uchMultiplier && popnd.pregDisp1.val ==_ESP)
					asmerr(ASMERRMSGS.EM_bad_addr_mode);	// illegal addressing mode
				bDisp = true;
			}
			
			mrmb.modregrm.rm = 0x4;
			bSib = true;
			if (bDisp)
			{
				if (!popnd.uchMultiplier &&
					popnd.pregDisp1.val==_ESP)
				{
					sib.sib.base = popnd.pregDisp1.val;
					sib.sib.index = 0x4;
				}
				else
				{
					debug if (debuga)
						printf("Resetting the mod to 0\n");
		
					if (popnd.pregDisp2)
					{
						if (popnd.pregDisp2.val != _EBP)
							asmerr(ASMERRMSGS.EM_bad_addr_mode);	// illegal addressing mode
					}
					else
					{   
						mrmb.modregrm.mod = 0x0;
						bModset = true;
					}
					
					sib.sib.base = 0x5;
					sib.sib.index = popnd.pregDisp1.val;
				}
			}
			else
			{
				sib.sib.base = popnd.pregDisp1.val;
				//
				// This is to handle the special case
				// of using the EBP register and no
				// displacement.  You must put in an
				// 8 byte displacement in order to
				// get the correct opcodes.
				//
				if (popnd.pregDisp1.val == _EBP && (!popnd.disp && !s))
				{
					debug if (debuga)
						printf("Setting the mod to 1 in the _EBP case\n");

					mrmb.modregrm.mod = 0x1;
					bDisp = true;   // Need a
									// displacement
					bModset = true;
				}
					
				sib.sib.index = popnd.pregDisp2.val;
			}
			switch (popnd.uchMultiplier)
			{
				case 0:	sib.sib.ss = 0;	break;
				case 1:	sib.sib.ss = 0;	break;
				case 2:	sib.sib.ss = 1;	break;
				case 4:	sib.sib.ss = 2;	break;
				case 8:	sib.sib.ss = 3;	break;

				default:
					asmerr(ASMERRMSGS.EM_bad_addr_mode);		// illegal addressing mode
					break;
			}
			if (bDisp && sib.sib.base == 0x5)
				b32bit = true;
		}
		else
		{   
			uint rm;

			if (popnd.uchMultiplier)
				asmerr(ASMERRMSGS.EM_bad_addr_mode);		// illegal addressing mode
			switch (popnd.pregDisp1.val)
			{
				case _EAX:	rm = 0;	break;
				case _ECX:	rm = 1;	break;
				case _EDX:	rm = 2;	break;
				case _EBX:	rm = 3;	break;
				case _ESI:	rm = 6;	break;
				case _EDI:	rm = 7;	break;

				case _EBP:
					if (!popnd.disp && !s)
					{
						mrmb.modregrm.mod = 0x1;
						bDisp = true;   // Need a displacement
						bModset = true;
					}
					rm = 5;
					break;

				default:
					asmerr(ASMERRMSGS.EM_bad_addr_mode);	// illegal addressing mode
					break;
			}
			mrmb.modregrm.rm = rm;
		}
		if (!bModset && (!s || (!mrmb.modregrm.mod && popnd.disp)))
		{
			if ((!popnd.disp && !mrmb.modregrm.mod) ||
				(!popnd.pregDisp1 && !popnd.pregDisp2))
			{
				mrmb.modregrm.mod = 0x0;
				bDisp = true;
			}
			else if (popnd.disp >= CHAR_MIN && popnd.disp <= SCHAR_MAX)
				mrmb.modregrm.mod = 0x1;
			else
				mrmb.modregrm.mod = 0x2;
		}
		else
			bOffsetsym = true;
    }
    if (popnd2 && !mrmb.modregrm.reg &&
		asmstate.ucItype != IT.ITshift &&
		(ASM_GET_aopty(popnd2.usFlags) == ASM_OPERAND_TYPE._reg  ||
		ASM_GET_amod(popnd2.usFlags) == ASM_MODIFIERS._rseg ||
		ASM_GET_amod(popnd2.usFlags) == ASM_MODIFIERS._rspecial))
    {
	    mrmb.modregrm.reg =  popnd2.base.val;
    }
	debug puchOpcode[ (*pusIdx)++ ] = mrmb.uchOpcode;

    pc.Irm = mrmb.uchOpcode;
    //printf("Irm = %02x\n", pc.Irm);
    if (bSib)
    {
		debug puchOpcode[ (*pusIdx)++ ] = sib.uchOpcode;
	    pc.Isib= sib.uchOpcode;
    }
    if ((!s || (popnd.pregDisp1 && !bOffsetsym)) &&
		aopty != ASM_OPERAND_TYPE._imm &&
		(popnd.disp || bDisp))
    {
	    if (popnd.usFlags & _a16)
	    {
			debug {
				puc = (cast(ubyte*) &(popnd.disp));
				puchOpcode[(*pusIdx)++] = puc[1];
				puchOpcode[(*pusIdx)++] = puc[0];
			}
		    if (usFlags & (_modrm | NUM_MASK)) {
				debug if (debuga)
					printf("Setting up value %ld\n", popnd.disp);

				pc.IEVint1() = popnd.disp;
				pc.IFL1 = FL.FLconst;
		    }
		    else {
				pc.IEVint2() = popnd.disp;
				pc.IFL2 = FL.FLconst;
		    }
			    
	    }
	    else
	    {
			debug {
				puc = (cast(ubyte*) &(popnd.disp));
				puchOpcode[(*pusIdx)++] = puc[3];
				puchOpcode[(*pusIdx)++] = puc[2];
				puchOpcode[(*pusIdx)++] = puc[1];
				puchOpcode[(*pusIdx)++] = puc[0];
			}
		    if (usFlags & (_modrm | NUM_MASK)) {
				debug if (debuga)
					printf("Setting up value %ld\n", popnd.disp);

			    pc.IEVpointer1() = cast(targ_size_t) popnd.disp;
			    pc.IFL1 = FL.FLconst;
		    } else {
			    pc.IEVpointer2() = cast(targ_size_t) popnd.disp;
			    pc.IFL2 = FL.FLconst;
		    }
	    }
    }
}

void asm_output_popnd(OPND* popnd)
{
	if (popnd.segreg)
		printf("%s:", popnd.segreg.regstr);
	
	if (popnd.s)
		writef("%s", popnd.s.ident.toChars());
	
	if (popnd.base)
		printf("%s", popnd.base.regstr);

	if (popnd.pregDisp1) {
		if (popnd.pregDisp2) {
			if (popnd.usFlags & _a32)
				if (popnd.uchMultiplier)
					printf("[%s][%s*%d]",
						popnd.pregDisp1.regstr,
						popnd.pregDisp2.regstr,
						popnd.uchMultiplier);
				else
					printf("[%s][%s]",
						popnd.pregDisp1.regstr,
						popnd.pregDisp2.regstr);
			else
				printf("[%s+%s]",
					popnd.pregDisp1.regstr,
					popnd.pregDisp2.regstr);
		}
		else {
			if (popnd.uchMultiplier)
				printf("[%s*%d]",
					popnd.pregDisp1.regstr,
					popnd.uchMultiplier);
			else
				printf("[%s]",
					popnd.pregDisp1.regstr);
		}
	}
	if (ASM_GET_aopty(popnd.usFlags) == ASM_OPERAND_TYPE._imm)
		printf("%lxh", popnd.disp);
	else if (popnd.disp)
		printf("+%lxh", popnd.disp);
}

/*******************************
 * Prepend line number to c.
 */

code* asm_genloc(Loc loc, code* c)
{
    if (global.params.symdebug)
    {   
		code* pcLin;
		Srcpos srcpos;

		srcpos.Slinnum = loc.linnum;
		srcpos.Sfilename = cast(char*)toStringz(loc.filename);
		pcLin = genlinnum(null, srcpos);

		c = cat(pcLin, c);
    }

    return c;
}

opflag_t asm_determine_operand_flags(OPND* popnd)
{
	Dsymbol ps;
	int ty;
	opflag_t us;
	opflag_t sz;
	ASM_OPERAND_TYPE opty;
	ASM_MODIFIERS amod;

	// If specified 'offset' or 'segment' but no symbol
	if ((popnd.bOffset || popnd.bSeg) && !popnd.s)
	    asmerr(ASMERRMSGS.EM_bad_addr_mode);		// illegal addressing mode
	    
	if (asmstate.ucItype == IT.ITfloat)
	    return asm_determine_float_flags(popnd);

	// If just a register	
	if (popnd.base && !popnd.s && !popnd.disp && !popnd.real_)
		return popnd.base.ty;

	debug if (debuga)
	    printf("popnd.base = %s\n, popnd.pregDisp1 = %ld\n", popnd.base ? popnd.base.regstr : "NONE", popnd.pregDisp1);

	ps = popnd.s;
	Declaration ds = ps ? ps.isDeclaration() : null;
	if (ds && ds.storage_class & STC.STClazy)
	    sz = _anysize;
	else
	    sz = cast(ushort)asm_type_size((ds && ds.storage_class & (STC.STCout | STC.STCref)) ? popnd.ptype.pointerTo() : popnd.ptype);
	if (popnd.pregDisp1 && !popnd.base)
	{
	    if (ps && ps.isLabel() && sz == _anysize)
			sz = I32 ? _32 : _16;
	    return (popnd.pregDisp1.ty & _r32)
			? CONSTRUCT_FLAGS(sz, ASM_OPERAND_TYPE._m, ASM_MODIFIERS._addr32, 0)
			: CONSTRUCT_FLAGS(sz, ASM_OPERAND_TYPE._m, ASM_MODIFIERS._addr16, 0);
	}
	else if (ps)
	{
		if (popnd.bOffset || popnd.bSeg || ps == asmstate.psLocalsize)
		    return I32
			? CONSTRUCT_FLAGS(_32, ASM_OPERAND_TYPE._imm, ASM_MODIFIERS._normal, 0)
			: CONSTRUCT_FLAGS(_16, ASM_OPERAND_TYPE._imm, ASM_MODIFIERS._normal, 0);
		
		if (ps.isLabel())
		{
		    switch (popnd.ajt)
		    {
				case ASM_JUMPTYPE.ASM_JUMPTYPE_UNSPECIFIED:
					if (ps == asmstate.psDollar)
					{
						if (popnd.disp >= CHAR_MIN &&
							popnd.disp <= CHAR_MAX)
							us = CONSTRUCT_FLAGS(_8, _rel, ASM_MODIFIERS._flbl,0);
						else
						if (popnd.disp >= SHRT_MIN &&
							popnd.disp <= SHRT_MIN)
							us = CONSTRUCT_FLAGS(_16, _rel, ASM_MODIFIERS._flbl,0);
						else
							us = CONSTRUCT_FLAGS(_32, _rel, ASM_MODIFIERS._flbl,0);
					}
					else if (asmstate.ucItype != ITjump)
					{	
						if (sz == _8)
						{   us = CONSTRUCT_FLAGS(_8,ASM_OPERAND_TYPE._rel,ASM_MODIFIERS._flbl,0);
							break;
						}
						goto case_near;
					}
					else
						us = I32
						? CONSTRUCT_FLAGS(_8|_32, ASM_OPERAND_TYPE._rel, ASM_MODIFIERS._flbl, 0)
						: CONSTRUCT_FLAGS(_8|_16, ASM_OPERAND_TYPE._rel, ASM_MODIFIERS._flbl, 0);
					break;
					
				case ASM_JUMPTYPE.ASM_JUMPTYPE_NEAR:
				case_near:
					us = I32
					? CONSTRUCT_FLAGS(_32, _rel, _flbl, 0)
					: CONSTRUCT_FLAGS(_16, _rel, _flbl, 0);
					break;
				case ASM_JUMPTYPE.ASM_JUMPTYPE_SHORT:
					us = CONSTRUCT_FLAGS(_8, _rel, _flbl, 0);
					break;
				case ASM_JUMPTYPE.ASM_JUMPTYPE_FAR:
					us = I32
					? CONSTRUCT_FLAGS(_48, _rel, _flbl, 0)
					: CONSTRUCT_FLAGS(_32, _rel, _flbl, 0);
					break;
				default:
					assert(0);
		    }
		    return us;
		}
		if (!popnd.ptype)
		    return CONSTRUCT_FLAGS(sz, _m, _normal, 0);
		ty = popnd.ptype.ty;
		if (ty == Tpointer && popnd.ptype.nextOf().ty == Tfunction &&
		    !ps.isVarDeclaration())
		{
static if (true) {
		    return CONSTRUCT_FLAGS(_32, _m, _fn16, 0);
} else {
		    ty = popnd.ptype.Tnext.Tty;
		    if (tyfarfunc(tybasic(ty))) {
			return I32
			    ? CONSTRUCT_FLAGS(_48, _mnoi, _fn32, 0)
			    : CONSTRUCT_FLAGS(_32, _mnoi, _fn32, 0);
		    }
		    else {
			return I32
			    ? CONSTRUCT_FLAGS(_32, _m, _fn16, 0)
			    : CONSTRUCT_FLAGS(_16, _m, _fn16, 0);
		    }
}
		}
		else if (ty == TY.Tfunction)
		{
static if (true) {
		    return CONSTRUCT_FLAGS(_32, _rel, _fn16, 0);
} else {
		    if (tyfarfunc(tybasic(ty)))
			return I32
			    ? CONSTRUCT_FLAGS(_48, _p, _fn32, 0)
			    : CONSTRUCT_FLAGS(_32, _p, _fn32, 0);
		    else
			return I32
			    ? CONSTRUCT_FLAGS(_32, _rel, _fn16, 0)
			    : CONSTRUCT_FLAGS(_16, _rel, _fn16, 0);
}
		}
		else if (asmstate.ucItype == IT.ITjump)
		{   
			amod = _normal;
		    goto L1;
		}
		else
		    return CONSTRUCT_FLAGS(sz, _m, _normal, 0);
	}
	if (popnd.segreg /*|| popnd.bPtr*/)
	{
	    amod = I32 ? _addr32 : _addr16;
	    if (asmstate.ucItype == ITjump)
	    {
			L1:
			opty = _m;
			if (I32)
			{   if (sz == _48)
				opty = _mnoi;
			}
			else
			{
				if (sz == _32)
				opty = _mnoi;
			}
			us = CONSTRUCT_FLAGS(sz,opty,amod,0);
	    }
	    else
			us = CONSTRUCT_FLAGS(sz, 
//				     _rel, amod, 0);
				     _m, amod, 0);
	}

	else if (popnd.ptype)
	    us = CONSTRUCT_FLAGS(sz, _imm, _normal, 0);

	else if (popnd.disp >= CHAR_MIN && popnd.disp <= UCHAR_MAX)
	    us = CONSTRUCT_FLAGS(_8 | _16 | _32, _imm, _normal, 0);
	else if (popnd.disp >= SHRT_MIN && popnd.disp <= USHRT_MAX)
	    us = CONSTRUCT_FLAGS(_16 | _32, _imm, _normal, 0);
	else
	    us = CONSTRUCT_FLAGS(_32, _imm, _normal, 0);
	return us;
}

/*******************************
 * Match flags in operand against flags in opcode table.
 * Returns:
 *	!=0 if match
 */

ubyte asm_match_flags(opflag_t usOp, opflag_t usTable)
{
    ASM_OPERAND_TYPE	aoptyTable;
    ASM_OPERAND_TYPE	aoptyOp;
    ASM_MODIFIERS	amodTable;
    ASM_MODIFIERS	amodOp;
    uint uRegmaskTable;
    uint uRegmaskOp;
    ubyte bRegmatch;
    ubyte bRetval = false;
    uint uSizemaskOp;
    uint uSizemaskTable;
    ubyte bSizematch;

    //printf("asm_match_flags(usOp = x%x, usTable = x%x)\n", usOp, usTable);
    if (asmstate.ucItype == IT.ITfloat)
    {
		bRetval = asm_match_float_flags(usOp, usTable);
		goto EXIT;
    }

    uSizemaskOp = ASM_GET_uSizemask(usOp);
    uSizemaskTable = ASM_GET_uSizemask(usTable);

    // Check #1, if the sizes do not match, NO match
    bSizematch = (uSizemaskOp & uSizemaskTable) != 0;

    amodOp = ASM_GET_amod(usOp);
    
    aoptyTable = ASM_GET_aopty(usTable);
    aoptyOp = ASM_GET_aopty(usOp);

    // _mmm64 matches with a 64 bit mem or an MMX register
    if (usTable == _mmm64)
    {
		if (usOp == _mm)
			goto Lmatch;
		if (aoptyOp == _m && (bSizematch || uSizemaskOp == _anysize))
			goto Lmatch;
		goto EXIT;
    }

    // _xmm_m32, _xmm_m64, _xmm_m128 match with XMM register or memory
    if (usTable == _xmm_m32 ||
		usTable == _xmm_m64 ||
		usTable == _xmm_m128)
    {
		if (usOp == _xmm)
			goto Lmatch;
		if (aoptyOp == _m && (bSizematch || uSizemaskOp == _anysize))
			goto Lmatch;
    }

    if (!bSizematch && uSizemaskTable)
    {
		//printf("no size match\n");
		goto EXIT;
    }


//
// The operand types must match, otherwise return false.
// There is one exception for the _rm which is a table entry which matches
// _reg or _m
//
    if (aoptyTable != aoptyOp)
    {
		if (aoptyTable == _rm && (aoptyOp == _reg ||
					  aoptyOp == _m ||
					  aoptyOp == _rel))
			goto Lok;

		if (aoptyTable == _mnoi && aoptyOp == _m &&
			(uSizemaskOp == _32 && amodOp == _addr16 ||
			 uSizemaskOp == _48 && amodOp == _addr32 ||
			 uSizemaskOp == _48 && amodOp == _normal)
		  )
			goto Lok;
		goto EXIT;
    }
Lok:

//
// Looks like a match so far, check to see if anything special is going on
//
    amodTable = ASM_GET_amod(usTable);
    uRegmaskOp = ASM_GET_uRegmask(usOp);
    uRegmaskTable = ASM_GET_uRegmask(usTable);
    bRegmatch = ((!uRegmaskTable && !uRegmaskOp) ||
		 (uRegmaskTable & uRegmaskOp));

    switch (amodTable)
    {
		default:
			assert(false);
		case _normal:		// Normal's match with normals
			switch(amodOp) {
				case _normal:
				case _addr16:
				case _addr32:
				case _fn16:
				case _fn32:
				case _flbl:
				bRetval = (bSizematch || bRegmatch);
				goto EXIT;
				default:
				goto EXIT;
			}
		case _rseg:
		case _rspecial:
			bRetval = (amodOp == amodTable && bRegmatch);
			goto EXIT;
    }
EXIT:
static if (false) {
    printf("OP : ");
    asm_output_flags(usOp);
    printf("\nTBL: ");
    asm_output_flags(usTable);
    writef(": %s\n", bRetval ? "MATCH" : "NOMATCH");
}
    return bRetval;

Lmatch:
    //printf("match\n");
    return 1;
}

void asm_output_flags(opflag_t usFlags)
{
	ASM_OPERAND_TYPE    aopty = ASM_GET_aopty(usFlags);
	ASM_MODIFIERS	    amod = ASM_GET_amod(usFlags);
	uint uRegmask = ASM_GET_uRegmask(usFlags);
	uint uSizemask = ASM_GET_uSizemask(usFlags);

	if (uSizemask == _anysize)
	    printf("_anysize ");
	else if (uSizemask == 0)
	    printf("0        ");
	else
	{
	    if (uSizemask & _8)
			printf("_8  ");
	    if (uSizemask & _16)
			printf("_16 ");
	    if (uSizemask & _32)
			printf("_32 ");
	    if (uSizemask & _48)
			printf("_48 ");
	}

	printf("_");
	switch (aopty) {
	    case ASM_OPERAND_TYPE._reg:
			printf("reg   ");
			break;
	    case ASM_OPERAND_TYPE._m:
			printf("m     ");
			break;
	    case ASM_OPERAND_TYPE._imm:
			printf("imm   ");
			break;
	    case ASM_OPERAND_TYPE._rel:
			printf("rel   ");
			break;
	    case ASM_OPERAND_TYPE._mnoi:
			printf("mnoi  ");
			break;
	    case ASM_OPERAND_TYPE._p:
			printf("p     ");
			break;
	    case ASM_OPERAND_TYPE._rm:
			printf("rm    ");
			break;
	    case ASM_OPERAND_TYPE._float:
			printf("float ");
			break;
	    default:
			printf(" UNKNOWN ");
	}

	printf("_");
	switch (amod) {
	    case ASM_MODIFIERS._normal:
			printf("normal   ");
			if (uRegmask & 1) printf("_al ");
			if (uRegmask & 2) printf("_ax ");
			if (uRegmask & 4) printf("_eax ");
			if (uRegmask & 8) printf("_dx ");
			if (uRegmask & 0x10) printf("_cl ");
			return;
	    case ASM_MODIFIERS._rseg:
			printf("rseg     ");
			break;
	    case ASM_MODIFIERS._rspecial:
			printf("rspecial ");
			break;
	    case ASM_MODIFIERS._addr16:
			printf("addr16   ");
			break;
	    case ASM_MODIFIERS._addr32:
			printf("addr32   ");
			break;
	    case ASM_MODIFIERS._fn16:
			printf("fn16     ");
			break;
	    case ASM_MODIFIERS._fn32:
			printf("fn32     ");
			break;
	    case ASM_MODIFIERS._flbl:
			printf("flbl     ");
			break;
	    default:
			printf("UNKNOWN  ");
			break;
	}

	printf("uRegmask=x%02x", uRegmask);	   
}

OPND* asm_log_or_exp()
{
	OPND* o1 = asm_log_and_exp();
	OPND* o2;

	while (tok_value == TOK.TOKoror)
	{
		asm_token();
		o2 = asm_log_and_exp();
		if (asm_isint(o1) && asm_isint(o2))
		    o1.disp = o1.disp || o2.disp;
		else
		    asmerr(ASMERRMSGS.EM_bad_integral_operand);		// illegal operand
		o2.disp = 0;
		o1 = asm_merge_opnds(o1, o2);
	}
	return o1;
}

void asm_chktok(TOK toknum, uint errnum)
{
    if (tok_value == toknum)
		asm_token();			// scan past token
    else
		/* When we run out of tokens, asmtok is null.
		 * But when this happens when a ';' was hit.
		 */
		asmerr(errnum, asmtok ? asmtok.toChars() : ";");
}

opflag_t asm_determine_float_flags(OPND* popnd)
{
    //printf("asm_determine_float_flags()\n");

    opflag_t us;
	opflag_t usFloat;

    // Insure that if it is a register, that it is not a normal processor
    // register.

    if (popnd.base && 
	    !popnd.s && !popnd.disp && !popnd.real_
	    && !(popnd.base.ty & (_r8 | _r16 | _r32)))
    {
		return popnd.base.ty;
    }
    if (popnd.pregDisp1 && !popnd.base)
    {
		us = asm_float_type_size(popnd.ptype, &usFloat);
		//printf("us = x%x, usFloat = x%x\n", us, usFloat);
		if (popnd.pregDisp1.ty & _r32)
			return(CONSTRUCT_FLAGS(us, _m, _addr32, usFloat));
		else if (popnd.pregDisp1.ty & _r16)
			return(CONSTRUCT_FLAGS(us, _m, _addr16, usFloat));
    }
    else if (popnd.s !is null)
    {
		us = asm_float_type_size(popnd.ptype, &usFloat);
		return CONSTRUCT_FLAGS(us, _m, _normal, usFloat);
    }

    if (popnd.segreg)
    {
		us = asm_float_type_size(popnd.ptype, &usFloat);
		if (I32)
			return(CONSTRUCT_FLAGS(us, _m, _addr32, usFloat));
		else
			return(CONSTRUCT_FLAGS(us, _m, _addr16, usFloat));
    }

static if (false) {
    if (popnd.real_)
    {
		switch (popnd.ptype.ty)
		{
			case TY.Tfloat32:
				popnd.s = fconst(popnd.real_);
				return(CONSTRUCT_FLAGS(_32, _m, _normal, 0));

			case TY.Tfloat64:
				popnd.s = dconst(popnd.real_);
				return(CONSTRUCT_FLAGS(0, _m, _normal, _64));

			case TY.Tfloat80:
				popnd.s = ldconst(popnd.real_);
				return(CONSTRUCT_FLAGS(0, _m, _normal, _80));
		}
    }
}

    asmerr(ASMERRMSGS.EM_bad_float_op);	// unknown operand for floating point instruction
    return 0;
}

uint asm_type_size(Type ptype)
{   
    //if (ptype) printf("asm_type_size('%s') = %d\n", ptype.toChars(), (int)ptype.size());
    uint u = _anysize;
    if (ptype && ptype.ty != TY.Tfunction /*&& ptype.isscalar()*/)
    {
		switch (cast(int)ptype.size())
		{
			case 0:	asmerr(ASMERRMSGS.EM_bad_op, "0 size");	break;
			case 1:	u = _8;		break;
			case 2:	u = _16;	break;
			case 4:	u = _32;	break;
			case 6:	u = _48;	break;
			default:
				break;	///
		}
    }
    return u;
}

bool asm_match_float_flags(opflag_t usOp, opflag_t usTable)
{
    ASM_OPERAND_TYPE	aoptyTable;
    ASM_OPERAND_TYPE	aoptyOp;
    ASM_MODIFIERS	amodTable;
    ASM_MODIFIERS	amodOp;
    uint uRegmaskTable;
    uint uRegmaskOp;
    ubyte bRegmatch;

    
//
// Check #1, if the sizes do not match, NO match
//
    uRegmaskOp = ASM_GET_uRegmask(usOp);
    uRegmaskTable = ASM_GET_uRegmask(usTable);
    bRegmatch = (uRegmaskTable & uRegmaskOp) != 0;
    
    if (!(ASM_GET_uSizemask(usTable) & ASM_GET_uSizemask(usOp) || bRegmatch))
		return false;
    
    aoptyTable = ASM_GET_aopty(usTable);
    aoptyOp = ASM_GET_aopty(usOp);
//
// The operand types must match, otherwise return false.
// There is one exception for the _rm which is a table entry which matches
// _reg or _m
//
    if (aoptyTable != aoptyOp)
    {
		if (aoptyOp != _float)
			return false;
    }

//
// Looks like a match so far, check to see if anything special is going on
//
    amodOp = ASM_GET_amod(usOp);
    amodTable = ASM_GET_amod(usTable);
    switch (amodTable)
    {
		// Normal's match with normals
		case _normal:
			switch(amodOp)
			{
				case _normal:
				case _addr16:
				case _addr32:
				case _fn16:
				case _fn32:
				case _flbl:
					return true;

				default:
					return false;
			}

		case _rseg:
		case _rspecial:
			return false;
		default:
			assert(0);
    }
}

OPND* asm_log_and_exp()
{
	OPND* o1 = asm_inc_or_exp();
	OPND* o2;

	while (tok_value == TOKandand)
	{
		asm_token();
		o2 = asm_inc_or_exp();
		if (asm_isint(o1) && asm_isint(o2))
			o1.disp = o1.disp && o2.disp;
		else {
			asmerr(EM_bad_integral_operand);		// illegal operand
		}
		o2.disp = 0;
		o1 = asm_merge_opnds(o1, o2);
	}
	return o1;
}

bool 	asm_isint(OPND *o)
{
    if (!o || o.base || o.s)
		return false;

    //return o.disp != 0;
    return true;
}

/*******************************
 * Merge operands o1 and o2 into a single operand.
 */

OPND* asm_merge_opnds(OPND* o1, OPND* o2)
{
	debug immutable(char)* psz;
    debug if (debuga)
    {	
		printf("asm_merge_opnds(o1 = ");
		if (o1) asm_output_popnd(o1);
			printf(", o2 = ");
		if (o2) asm_output_popnd(o2);
			printf(")\n");
    }

	if (!o1)
		return o2;
	if (!o2)
		return o1;
version (EXTRA_DEBUG) {
	printf("Combining Operands: mult1 = %d, mult2 = %d",
		o1.uchMultiplier, o2.uchMultiplier);
}
	/*	combine the OPND's disp field */
	if (o2.segreg) {
	    if (o1.segreg) {
			debug psz = "o1.segment && o2.segreg".ptr;
			goto ILLEGAL_ADDRESS_ERROR;
	    }
	    else
			o1.segreg = o2.segreg;
	}
	
	// combine the OPND's symbol field
	if (o1.s && o2.s)
	{
	    debug psz = "o1.s && os.s";
ILLEGAL_ADDRESS_ERROR:
		debug printf("Invalid addr because /%s/\n", psz);
    
	    asmerr(EM_bad_addr_mode);		// illegal addressing mode
	}
	else if (o2.s)
	    o1.s = o2.s;
	else if (o1.s && o1.s.isTupleDeclaration())
	{   
		TupleDeclaration tup = o1.s.isTupleDeclaration();

	    size_t index = o2.disp;
	    if (index >= tup.objects.dim)
			error(asmstate.loc, "tuple index %u exceeds %u", index, tup.objects.dim);
	    else
	    {
			Object o = tup.objects[index];
			if (auto d = cast(Dsymbol)o)
			{   
				o1.s = d;
				return o1;
			}
			else if (auto e = cast(Expression)o)
			{
				if (e.op == TOKvar)
				{   
					o1.s = (cast(VarExp)e).var;
					return o1;
				}
				else if (e.op == TOKfunction)
				{   
					o1.s = (cast(FuncExp)e).fd;
					return o1;
				}
			}
			error(asmstate.loc, "invalid asm operand %s", o1.s.toChars());
	    }
	}

	if (o1.disp && o2.disp)
	    o1.disp += o2.disp;
	else if (o2.disp)
	    o1.disp = o2.disp;

	/* combine the OPND's base field */
	if (o1.base !is null && o2.base !is null) {
		debug psz = "o1.base != null && o2.base != null".ptr;
		goto ILLEGAL_ADDRESS_ERROR;
	}
	else if (o2.base)
		o1.base = o2.base;

	/* Combine the displacement register fields */
	if (o2.pregDisp1)
	{
		if (o1.pregDisp2)
		{
		    debug psz = "o2.pregDisp1 && o1.pregDisp2";
		    goto ILLEGAL_ADDRESS_ERROR;
		}
		else if (o1.pregDisp1)
		{
		    if (o1.uchMultiplier ||
			    (o2.pregDisp1.val == _ESP &&
			    (o2.pregDisp1.ty & _r32) &&
			    !o2.uchMultiplier))
		    {
				o1.pregDisp2 = o1.pregDisp1;
				o1.pregDisp1 = o2.pregDisp1;
		    }
		    else
				o1.pregDisp2 = o2.pregDisp1;
		}
		else 
			o1.pregDisp1 = o2.pregDisp1;
	}
	if (o2.pregDisp2) {
		if (o1.pregDisp2) {
			debug psz = "o1.pregDisp2 && o2.pregDisp2";
			goto ILLEGAL_ADDRESS_ERROR;
		}
		else
			o1.pregDisp2 = o2.pregDisp2;
	}
	if (o2.uchMultiplier)
	{
	    if (o1.uchMultiplier)
	    {
			debug psz = "o1.uchMultiplier && o2.uchMultiplier";
			goto ILLEGAL_ADDRESS_ERROR;
	    }
	    else
			o1.uchMultiplier = o2.uchMultiplier;
	}
	if (o2.ptype && !o1.ptype)
	    o1.ptype = o2.ptype;
	if (o2.bOffset)
	    o1.bOffset = o2.bOffset;
	if (o2.bSeg)
	    o1.bSeg = o2.bSeg;
	
	if (o2.ajt && !o1.ajt)
	    o1.ajt = o2.ajt;

	opnd_free(o2);
version (EXTRA_DEBUG) {
	printf("Result = %d\n", o1.uchMultiplier);
}
	debug if (debuga)
	{   printf("Merged result = /");
	    asm_output_popnd(o1);
	    printf("/\n");
	}

	return o1;
}

opflag_t asm_float_type_size(Type ptype, opflag_t* pusFloat)
{
    *pusFloat = 0;
    
    //printf("asm_float_type_size('%s')\n", ptype.toChars());
    if (ptype && ptype.isscalar())
    {
		int sz = cast(int)ptype.size();
		if (sz == REALSIZE)
		{   
			*pusFloat = _80;
			return 0;
		}
		switch (sz)
		{
			case 2:
				return _16;
			case 4:
				return _32;
			case 8:
				*pusFloat = _64;
				return 0;
			default:
				break;
		}
    }

    *pusFloat = _fanysize;
    return _anysize;
}

OPND* asm_inc_or_exp()
{
	OPND* o1 = asm_xor_exp();
	OPND* o2;

	while (tok_value == TOKor)
	{
		asm_token();
		o2 = asm_xor_exp();
		if (asm_isint(o1) && asm_isint(o2))
			o1.disp |= o2.disp;
		else {
			asmerr(EM_bad_integral_operand);		// illegal operand
		}
		o2.disp = 0;
		o1 = asm_merge_opnds(o1, o2);
	}
	return o1;
}

OPND* asm_xor_exp()
{
	OPND* o1 = asm_and_exp();
	OPND* o2;

	while (tok_value == TOKxor)
	{
		asm_token();
		o2 = asm_and_exp();
		if (asm_isint(o1) && asm_isint(o2))
			o1.disp ^= o2.disp;
		else {
			asmerr(EM_bad_integral_operand);		// illegal operand
		}
		o2.disp = 0;
		o1 = asm_merge_opnds(o1, o2);
	}
	return o1;
}

OPND* asm_and_exp()
{ 
	OPND* o1 = asm_equal_exp();
	OPND* o2;

	while (tok_value == TOKand)
	{
		asm_token();
		o2 = asm_equal_exp();
		if (asm_isint(o1) && asm_isint(o2))
			o1.disp &= o2.disp;
		else {
			asmerr(EM_bad_integral_operand);		// illegal operand
		}
		o2.disp = 0;
		o1 = asm_merge_opnds(o1, o2);
	}
	return o1;
}

OPND* asm_equal_exp()
{
    OPND* o1 = asm_rel_exp();
	OPND* o2;

    while (1)
    {
		switch (tok_value)
		{
			case TOKequal:
				asm_token();
				o2 = asm_rel_exp();
				if (asm_isint(o1) && asm_isint(o2))
					o1.disp = o1.disp == o2.disp;
				else {
					asmerr(EM_bad_integral_operand);	// illegal operand
				}
				o2.disp = 0;
				o1 = asm_merge_opnds(o1, o2);
				break;

			case TOKnotequal:
				asm_token();
				o2 = asm_rel_exp();
				if (asm_isint(o1) && asm_isint(o2))
					o1.disp = o1.disp != o2.disp;
				else {
					asmerr(EM_bad_integral_operand);
				}
				o2.disp = 0;
				o1 = asm_merge_opnds(o1, o2);
				break;

			default:
				return o1;
		}
    }
	
	assert(false);
}

OPND* asm_rel_exp()
{
    OPND* o1 = asm_shift_exp();
	OPND* o2;

    TOK tok_save;

    while (1)
    {
		switch (tok_value)
		{
			case TOKgt:
			case TOKge:
			case TOKlt:
			case TOKle:
				tok_save = tok_value;
				asm_token();
				o2 = asm_shift_exp();
				if (asm_isint(o1) && asm_isint(o2))
				{
					switch (tok_save)
					{
						default:
							assert(false);
						case TOKgt:
							o1.disp = o1.disp > o2.disp;
							break;
						case TOKge:
							o1.disp = o1.disp >= o2.disp;
							break;
						case TOKlt:
							o1.disp = o1.disp < o2.disp;
							break;
						case TOKle:
							o1.disp = o1.disp <= o2.disp;
							break;
					}
				}
				else
					asmerr(EM_bad_integral_operand);
				o2.disp = 0;
				o1 = asm_merge_opnds(o1, o2);
				break;

			default:
				return o1;
		}
    }
	
	assert(false);
}

OPND* asm_shift_exp()
{
    OPND* o1 = asm_add_exp();
	OPND* o2;
    
	int op;
    TOK tk;

    while (tok_value == TOKshl || tok_value == TOKshr || tok_value == TOKushr)
    {   
		tk = tok_value;
		asm_token();
		o2 = asm_add_exp();
		if (asm_isint(o1) && asm_isint(o2))
		{   if (tk == TOKshl)
			o1.disp <<= o2.disp;
			else if (tk == TOKushr)
			o1.disp = cast(uint)o1.disp >> o2.disp;
			else
			o1.disp >>= o2.disp;
		}
		else
			asmerr(EM_bad_integral_operand);
		o2.disp = 0;
		o1 = asm_merge_opnds(o1, o2);
    }
    return o1;
}

/*******************************
 */

OPND* asm_add_exp()
{
    OPND* o1 = asm_mul_exp();
	OPND* o2;

    while (1)
    {
		switch (tok_value) 
		{
			case TOKadd:
				asm_token();
				o2 = asm_mul_exp();
				o1 = asm_merge_opnds(o1, o2);
				break;

			case TOKmin:
				asm_token();
				o2 = asm_mul_exp();
				if (asm_isint(o1) && asm_isint(o2))
				{
					o1.disp -= o2.disp;
					o2.disp = 0;
				}
				else
					o2.disp = - o2.disp;
				o1 = asm_merge_opnds(o1, o2);
				break;

			default:
				return o1;
		}
    }
	
	assert(false);
}

/*******************************
 */

OPND* asm_mul_exp()
{
    OPND* o1;
	OPND* o2;
    OPND* popndTmp;

    //printf("+asm_mul_exp()\n");
    o1 = asm_br_exp();
    while (1)
    {
		switch (tok_value)
		{
			case TOKmul:
				asm_token();
				o2 = asm_br_exp();
version (EXTRA_DEBUG) {
				printf("Star  o1.isint=%d, o2.isint=%d, lbra_seen=%d\n",
					asm_isint(o1), asm_isint(o2), asm_TKlbra_seen );
}
				if (asm_isNonZeroInt(o1) && asm_isNonZeroInt(o2))
					o1.disp *= o2.disp;
				else if (asm_TKlbra_seen && o1.pregDisp1 && asm_isNonZeroInt(o2))
				{
					o1.uchMultiplier = o2.disp;
version (EXTRA_DEBUG) {
					printf("Multiplier: %d\n", o1.uchMultiplier);
}
				}
				else if (asm_TKlbra_seen && o2.pregDisp1 && asm_isNonZeroInt(o1))
				{
					popndTmp = o2;
					o2 = o1;
					o1 = popndTmp;
					o1.uchMultiplier = o2.disp;
version (EXTRA_DEBUG) {
					printf("Multiplier: %d\n",
					o1.uchMultiplier);
}
				}
				else if (asm_isint(o1) && asm_isint(o2))
					o1.disp *= o2.disp;
				else
					asmerr(EM_bad_operand);
				o2.disp = 0;
				o1 = asm_merge_opnds(o1, o2);
				break;

			case TOKdiv:
				asm_token();
				o2 = asm_br_exp();
				if (asm_isint(o1) && asm_isint(o2))
					o1.disp /= o2.disp;
				else
					asmerr(EM_bad_integral_operand);
				o2.disp = 0;
				o1 = asm_merge_opnds(o1, o2);
				break;

			case TOKmod:
				asm_token();
				o2 = asm_br_exp();
				if (asm_isint(o1) && asm_isint(o2))
					o1.disp %= o2.disp;
				else
					asmerr(EM_bad_integral_operand);
				o2.disp = 0;
				o1 = asm_merge_opnds(o1, o2);
				break;

			default:
				return o1;
		}
    }

    return o1;
}

OPND* asm_br_exp()
{
    //printf("asm_br_exp()\n");
	
	OPND* o1 = asm_una_exp();
	OPND* o2;
    Declaration s;
	
    while (1)
    {
		switch (tok_value)
		{
			case TOKlbracket:
			{
version (EXTRA_DEBUG) {
				printf("Saw a left bracket\n");
}
				asm_token();
				asm_TKlbra_seen++;
				o2 = asm_cond_exp();
				asm_TKlbra_seen--;
				asm_chktok(TOKrbracket,EM_rbra);
version (EXTRA_DEBUG) {
				printf("Saw a right bracket\n");
}
				o1 = asm_merge_opnds(o1, o2);
				if (tok_value == TOKidentifier)
				{   o2 = asm_una_exp();
					o1 = asm_merge_opnds(o1, o2);
				}
				break;
			}
			default:
				return o1;
		}
    }
	
	assert(false);
}

/*******************************
 */

OPND* asm_una_exp()
{
	OPND* o1;
	int op;
	Type ptype;
	Type ptypeSpec;
	ASM_JUMPTYPE ajt = ASM_JUMPTYPE_UNSPECIFIED;
	char bPtr = 0;
	
	switch (cast(int)tok_value)
	{
static if (false) {
		case TOKand:
		    asm_token();
		    o1 = asm_una_exp();
		    break;

		case TOKmul: 
		    asm_token();
		    o1 = asm_una_exp();
		    ++o1.indirect;
		    break;
}
		case TOKadd:
		    asm_token();
		    o1 = asm_una_exp();
		    break;

		case TOKmin: 
		    asm_token();
			o1 = asm_una_exp();
			if (asm_isint(o1))
				o1.disp = -o1.disp;
		    break;

		case TOKnot: 
		    asm_token();
			o1 = asm_una_exp();
			if (asm_isint(o1))
				o1.disp = !o1.disp;
		    break;

		case TOKtilde: 
		    asm_token();
			o1 = asm_una_exp();
			if (asm_isint(o1))
				o1.disp = ~o1.disp;
		    break;

static if (false) {
		case TOKlparen:
		    // stoken() is called directly here because we really
		    // want the INT token to be an INT.
		    stoken();
		    if (type_specifier(&ptypeSpec)) /* if type_name	*/
		    {   
				ptype = declar_abstract(ptypeSpec);
						/* read abstract_declarator	 */
				fixdeclar(ptype);/* fix declarator		 */
				type_free(ptypeSpec);/* the declar() function
							allocates the typespec again */
				chktok(TOKrparen,EM_rpar);
				ptype.Tcount--;
				goto CAST_REF;
		    }
		    else
		    {
				type_free(ptypeSpec);
				o1 = asm_cond_exp();
				chktok(TOKrparen, EM_rpar);
		    }
		    break;
}

		case TOKidentifier:
		    // Check for offset keyword
		    if (asmtok.ident == Id.offset)
		    {
				if (!global.params.useDeprecated)
					error(asmstate.loc, "offset deprecated, use offsetof");
				goto Loffset;
		    }
		    if (asmtok.ident == Id.offsetof)
		    {
		      Loffset:
				asm_token();
				o1 = asm_cond_exp();
				if (!o1)
					o1 = opnd_calloc();
				o1.bOffset= true;
		    }
		    else
				o1 = asm_primary_exp();
		    break;

		case ASMTK.ASMTKseg:
		    asm_token();
		    o1 = asm_cond_exp();
		    if (!o1)
			o1 = opnd_calloc();
		    o1.bSeg= true;
		    break;
			
		case TOKint16:
		    if (asmstate.ucItype != ITjump)
		    {
			ptype = Type.tint16;
			goto TYPE_REF;
		    }
		    ajt = ASM_JUMPTYPE_SHORT;
		    asm_token();
		    goto JUMP_REF2;

		case ASMTKnear:
		    ajt = ASM_JUMPTYPE_NEAR;
		    goto JUMP_REF;

		case ASMTKfar:
		    ajt = ASM_JUMPTYPE_FAR;
JUMP_REF:
		    asm_token();
		    asm_chktok(cast(TOK) ASMTKptr, EM_ptr_exp);
JUMP_REF2:
		    o1 = asm_cond_exp();
		    if (!o1)
				o1 = opnd_calloc();
		    o1.ajt= ajt;
		    break;
		    
		case TOKint8:
		    ptype = Type.tint8;
		    goto TYPE_REF;
		case TOKint32:
		case ASMTKdword:
		    ptype = Type.tint32;
		    goto TYPE_REF;
		case TOKfloat32:
		    ptype = Type.tfloat32;
		    goto TYPE_REF;
		case ASMTKqword:
		case TOKfloat64:
		    ptype = Type.tfloat64;
		    goto TYPE_REF;
		case TOKfloat80:
		    ptype = Type.tfloat80;
		    goto TYPE_REF;
		case ASMTKword:
		    ptype = Type.tint16;
TYPE_REF:
		    bPtr = 1;
		    asm_token();
		    asm_chktok(cast(TOK) ASMTKptr, EM_ptr_exp);
CAST_REF:
		    o1 = asm_cond_exp();
		    if (!o1)
				o1 = opnd_calloc();
		    o1.ptype = ptype;
		    o1.bPtr = bPtr;
		    break;
		    
		default:
		    o1 = asm_primary_exp();
		    break;
	}
	return o1;
}

bool asm_isNonZeroInt(OPND* o)
{
    if (!o || o.base || o.s)
		return false;

    return o.disp != 0;
}

OPND* asm_primary_exp()
{
	OPND* o1 = null;
	OPND* o2 = null;
	Type ptype;
	Dsymbol s;
	Dsymbol scopesym;

	TOK tkOld;
	int global;
	REG* regp;

 	global = 0;	
	switch (cast(int)tok_value)
	{
	    case TOKdollar:
			o1 = opnd_calloc();
			o1.s = asmstate.psDollar;
			asm_token();
			break;

static if (false) {
	    case TOKthis:
			strcpy(tok.TKid,cpp_name_this);
}
	    case TOKidentifier:
	    case_ident:
			o1 = opnd_calloc();
			regp = asm_reg_lookup(asmtok.ident.toChars());
			if (regp !is null)
			{
				asm_token();
				// see if it is segment override (like SS:)
				if (!asm_TKlbra_seen &&
					(regp.ty & _seg) &&
					tok_value == TOKcolon)
				{
				o1.segreg = regp;
				asm_token();
				o2 = asm_cond_exp();
				o1 = asm_merge_opnds(o1, o2);
				}
				else if (asm_TKlbra_seen)
				{   // should be a register
				if (o1.pregDisp1)
					asmerr(EM_bad_operand);
				else
					o1.pregDisp1 = regp;
				}
				else
				{   if (o1.base == null)
					o1.base = regp;
				else
					asmerr(EM_bad_operand);
				}
				break;
			}
			// If floating point instruction and id is a floating register
			else if (asmstate.ucItype == ITfloat &&
				 asm_is_fpreg(asmtok.ident.toChars()))
			{
				asm_token();
				if (tok_value == TOKlparen)
				{	
					uint n;

					asm_token();
					asm_chktok(TOKint32v, EM_num);
					n = cast(uint)asmtok.uns64value;
					if (n > 7)
						asmerr(EM_bad_operand);
					o1.base = &(aregFp[n]);
					asm_chktok(TOKrparen, EM_rpar);
				}
				else
					o1.base = &regFp;
			}
			else
			{
				if (asmstate.ucItype == ITjump)
				{
					s = null;
					if (asmstate.sc.func.labtab)
						s = asmstate.sc.func.labtab.lookup(asmtok.ident);
					if (!s)
						s = asmstate.sc.search(Loc(0), asmtok.ident, &scopesym);
					if (!s)
					{   // Assume it is a label, and define that label
						s = asmstate.sc.func.searchLabel(asmtok.ident);
					}
				}
				else
					s = asmstate.sc.search(Loc(0), asmtok.ident, &scopesym);

				if (!s)
					asmerr(EM_undefined, asmtok.toChars());

				Identifier id = asmtok.ident;
				asm_token();
				if (tok_value == TOKdot)
				{	
					Expression e;
					VarExp v;

					e = new IdentifierExp(asmstate.loc, id);
					while (1)
					{
						asm_token();
						if (tok_value == TOKidentifier)
						{
							e = new DotIdExp(asmstate.loc, e, asmtok.ident);
							asm_token();
							if (tok_value != TOKdot)
								break;
						}
						else
						{
							asmerr(EM_ident_exp);
							break;
						}
					}
					e = e.semantic(asmstate.sc);
					e = e.optimize(WANTvalue | WANTinterpret);
					if (e.isConst())
					{
						if (e.type.isintegral())
						{
							o1.disp = cast(int)e.toInteger();
							goto Lpost;
						}
						else if (e.type.isreal())
						{
							o1.real_ = e.toReal();
							o1.ptype = e.type;
							goto Lpost;
						}
						else
						{
							asmerr(EM_bad_op, e.toChars());
						}
					}
					else if (e.op == TOKvar)
					{
						v = cast(VarExp)e;
						s = v.var;
					}
					else
					{
						asmerr(EM_bad_op, e.toChars());
					}
				}

				asm_merge_symbol(o1,s);

				/* This attempts to answer the question: is
				 *	char[8] foo;
				 * of size 1 or size 8? Presume it is 8 if foo
				 * is the last token of the operand.
				 */
				if (o1.ptype && tok_value != TOKcomma && tok_value != TOKeof)
				{
				for (;
					 o1.ptype.ty == Tsarray;
					 o1.ptype = o1.ptype.nextOf())
				{
					//;
				}
				}

			Lpost:
static if (false) {
				// for []
				if (tok_value == TOKlbracket)
					o1 = asm_prim_post(o1);
}
				goto Lret;
			}
			break;

	    case TOKint32v:
	    case TOKuns32v:
			o1 = opnd_calloc();
			o1.disp = asmtok.int32value;
			asm_token();
			break;

	    case TOKfloat32v:
			o1 = opnd_calloc();
			o1.real_ = asmtok.float80value;
			o1.ptype = Type.tfloat32;
			asm_token();
			break;

	    case TOKfloat64v:
			o1 = opnd_calloc();
			o1.real_ = asmtok.float80value;
			o1.ptype = Type.tfloat64;
			asm_token();
			break;

	    case TOKfloat80v:
			o1 = opnd_calloc();
			o1.real_ = asmtok.float80value;
			o1.ptype = Type.tfloat80;
			asm_token();
			break;

	    case ASMTKlocalsize:
			o1 = opnd_calloc();
			o1.s = asmstate.psLocalsize;
			o1.ptype = Type.tint32;
			asm_token();
			break;
			
		default:
			break;	///
	}
Lret:
	return o1;
}

void asm_merge_symbol(OPND* o1, Dsymbol s)
{   
	Type ptype;
    VarDeclaration v;
    EnumMember em;

    //printf("asm_merge_symbol(s = %s %s)\n", s.kind(), s.toChars());
    s = s.toAlias();
    //printf("s = %s %s\n", s.kind(), s.toChars());
    if (s.isLabel())
    {
		o1.s = s;
		return;
    }

    v = s.isVarDeclaration();
    if (v)
    {
		if (v.isParameter())
			asmstate.statement.refparam = true;

		v.checkNestedReference(asmstate.sc, asmstate.loc);
static if (false) {
		if (!v.isDataseg() && v.parent != asmstate.sc.parent && v.parent)
		{
			asmerr(EM_uplevel, v.toChars());
		}
}
		if (v.storage_class & STCfield)
		{
			o1.disp += v.offset;
			goto L2;
		}
		if ((v.isConst()
///version (DMDV2) {
			|| v.isImmutable() || v.storage_class & STCmanifest
///}
			) && !v.type.isfloating() && v.init)
		{   
			ExpInitializer ei = v.init.isExpInitializer();

			if (ei)
			{
				o1.disp = cast(int)ei.exp.toInteger();
				return;
			}
		}
    }
    em = s.isEnumMember();
    if (em)
    {
		o1.disp = cast(int)em.value.toInteger();
		return;
    }
    o1.s = s;	// a C identifier
L2:
    Declaration d = s.isDeclaration();
    if (!d)
    {
		asmerr("%s %s is not a declaration", s.kind(), s.toChars());
    }
    else if (d.getType())
		asmerr(EM_type_as_operand, d.getType().toChars());
    else if (d.isTupleDeclaration()) {
		//;
    } else
		o1.ptype = d.type.toBasetype();
}

__gshared REG[63] regtab = 
[
	{"AL",	_AL,	_r8 | _al,},
	{"AH",	_AH,	_r8,},
	{"AX",	_AX,	_r16 | _ax,},
	{"EAX",	_EAX,	_r32 | _eax,},
	{"BL",	_BL,	_r8,},	
	{"BH",	_BH,	_r8,},
	{"BX",	_BX,	_r16,},
	{"EBX",	_EBX,	_r32,},
	{"CL",	_CL,	_r8 | _cl,},
	{"CH",	_CH,	_r8,},
	{"CX",	_CX,	_r16,},
	{"ECX",	_ECX,	_r32,},	
	{"DL",	_DL,	_r8,},	
	{"DH",	_DH,	_r8,},
	{"DX",	_DX,	_r16 | _dx,},
	{"EDX",	_EDX,	_r32,},
	{"BP",	_BP,	_r16,},
	{"EBP",	_EBP,	_r32,},
	{"SP",	_SP,	_r16,},	
	{"ESP",	_ESP,	_r32,},
	{"DI",	_DI,	_r16,},	
	{"EDI",	_EDI,	_r32,},
	{"SI",	_SI,	_r16,},
	{"ESI",	_ESI,	_r32,},
	{"ES",	_ES,	_seg | _es,},
	{"CS",	_CS,	_seg | _cs,},
	{"SS",	_SS,	_seg | _ss,},	
	{"DS",	_DS,	_seg | _ds,},
	{"GS",	_GS,	_seg | _gs,},
	{"FS",	_FS,	_seg | _fs,},
	{"CR0",	0,	_special | _crn,},
	{"CR2",	2,	_special | _crn,},
	{"CR3",	3,	_special | _crn,},
	{"CR4",	4,	_special | _crn,},
	{"DR0",	0,	_special | _drn,},
	{"DR1",	1,	_special | _drn,},
	{"DR2",	2,	_special | _drn,},
	{"DR3",	3,	_special | _drn,},
	{"DR4",	4,	_special | _drn,},
	{"DR5",	5,	_special | _drn,},
	{"DR6",	6,	_special | _drn,},
	{"DR7",	7,	_special | _drn,},
	{"TR3",	3,	_special | _trn,},
	{"TR4",	4,	_special | _trn,},
	{"TR5",	5,	_special | _trn,},
	{"TR6",	6,	_special | _trn,},
	{"TR7",	7,	_special | _trn,},
	{"MM0",	0,	_mm,},
	{"MM1",	1,	_mm,},
	{"MM2",	2,	_mm,},
	{"MM3",	3,	_mm,},
	{"MM4",	4,	_mm,},
	{"MM5",	5,	_mm,},
	{"MM6",	6,	_mm,},
	{"MM7",	7,	_mm,},
	{"XMM0",	0,	_xmm,},
	{"XMM1",	1,	_xmm,},
	{"XMM2",	2,	_xmm,},
	{"XMM3",	3,	_xmm,},
	{"XMM4",	4,	_xmm,},
	{"XMM5",	5,	_xmm,},
	{"XMM6",	6,	_xmm,},
	{"XMM7",	7,	_xmm,},
];

REG* asm_reg_lookup(string s)
{
    //dbg_printf("asm_reg_lookup('%s')\n",s);	

    for (int i = 0; i < regtab.length; i++)
    {
		if (regtab[i].regstr == s)
		{
			return &regtab[i];
		}
    }

    return null;
}

int asm_is_fpreg(string szReg)
{
static if (true) {
	return(szReg.length == 2 && szReg[0] == 'S' && 
		szReg[1] == 'T');
} else {
	return(szReg.length == 2 && (szReg[0] == 's' || szReg[0] == 'S') &&
		(szReg[1] == 't' || szReg[1] == 'T'));
}
}

extern(C)
{
	// backward reference from backend
	
	extern __gshared int refparam;
	
	/**********************************
	 * Return mask of registers used by block bp.
	 */
	regm_t iasm_regs(block *bp)
	{
		debug if (debuga)
			printf("Block iasm regs = 0x%X\n", bp.usIasmregs);

		refparam |= bp.bIasmrefparam;
		return bp.usIasmregs;
	}
}