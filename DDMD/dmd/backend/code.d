module dmd.backend.code;

import dmd.common;
import dmd.backend.targ_types;
import dmd.backend.Srcpos;
import dmd.backend.elem;
import dmd.backend.block;
import dmd.backend.Symbol;
import dmd.Declaration;
import dmd.LabelDsymbol;

/**********************************
 * Code data type
 */

union evc
{
    targ_int	Vint;		// also used for tmp numbers (FLtmp)
    targ_uns	Vuns;
    targ_long	Vlong;

    struct EP
    {	
		targ_size_t Vpointer;
		int Vseg;		// segment the pointer is in
    } EP _EP;

    Srcpos	Vsrcpos;	// source position for OPlinnum
    elem* Vtor;		// OPctor/OPdtor elem
    block* Vswitch;	// when FLswitch and we have a switch table
    code* Vcode;		// when code is target of a jump (FLcode)
    block* Vblock;	// when block " (FLblock)

    struct SP
    {
		targ_size_t Voffset;	// offset from symbol
		Symbol* Vsym;		// pointer to symbol table (FLfunc,FLextern)
    } SP sp;

version (MARS) {
    struct DSP
    {
		targ_size_t Voffset;	// offset from symbol
		Declaration Vsym;	// pointer to D symbol table
    } DSP dsp;
}

version (MARS) {
    struct LAB
    {
		targ_size_t Voffset;	// offset from symbol
		LabelDsymbol Vsym;	// pointer to Label
    } LAB lab;
}

    struct AS
    {   
		uint len;
		char* bytes;
    } AS as;			// asm node (FLasm)
}

enum CF
{
	CFes	         = 1,	// generate an ES: segment override for this instr
	CFjmp16	         = 2,	// need 16 bit jump offset (long branch)
	CFtarg	         = 4,	// this code is the target of a jump
	CFseg	         = 8,	// get segment of immediate value
	CFoff	      = 0x10,	// get offset of immediate value
	CFss	      = 0x20,	// generate an SS: segment override (not with
							// CFes at the same time, though!)
	CFpsw	     =  0x40,	// we need the flags result after this instruction
	CFopsize     =  0x80,	// prefix with operand size
	CFaddrsize   = 0x100,	// prefix with address size
	CFds	     = 0x200,	// need DS override (not with es, ss, or cs )	
	CFcs	     = 0x400,	// need CS override
	CFfs	     = 0x800,	// need FS override
	CFgs = (CFcs | CFfs),	// need GS override
	CFwait      = 0x1000,	// If I32 it indicates when to output a WAIT
	CFselfrel   = 0x2000, 	// if self-relative
	CFunambig   = 0x4000,   // indicates cannot be accessed by other addressing
							// modes
	CFtarg2	    = 0x8000,	// like CFtarg, but we can't optimize this away
	CFvolatile = 0x10000,	// volatile reference, do not schedule
	CFclassinit= 0x20000,	// class init code

	CFSEG	= (CFes | CFss | CFds | CFcs | CFfs | CFgs),
	CFPREFIX = (CFSEG | CFopsize | CFaddrsize),
}

struct code
{
    code* next;
    uint Iflags;

    ubyte Ijty = 0;		// type of operand, 0 if unknown

    ubyte Iop;
    ubyte Irm;		// reg/mode

    ubyte Iop2;		// second opcode byte
    ubyte Isib = 0;		// SIB byte

    ubyte Iop3;		// third opcode byte

    ubyte IFL1;
	ubyte IFL2;		// FLavors of 1st, 2nd operands
    evc IEV1;		// 1st operand, if any
	
	ref targ_size_t IEVpointer1 () { return IEV1._EP.Vpointer; }
	ref int IEVseg1     () { return IEV1._EP.Vseg; }
	ref Symbol* IEVsym1     () { return IEV1.sp.Vsym; }
	ref Declaration IEVdsym1    () { return IEV1.dsp.Vsym; }
	ref targ_size_t IEVoffset1  () { return IEV1.sp.Voffset; }
	ref LabelDsymbol IEVlsym1    () { return IEV1.lab.Vsym; }
	ref targ_int IEVint1	   () { return IEV1.Vint; }
	
    evc IEV2;		// 2nd operand, if any

	ref targ_size_t IEVpointer2 () { return IEV2._EP.Vpointer; }
	ref int IEVseg2     () { return IEV2._EP.Vseg; }
	ref Symbol* IEVsym2     () { return IEV2.sp.Vsym; }
	ref Declaration IEVdsym2    () { return IEV2.dsp.Vsym; }
	ref targ_size_t IEVoffset2  () { return IEV2.sp.Voffset; }
	ref LabelDsymbol IEVlsym2    () { return IEV2.lab.Vsym; }
	ref targ_int IEVint2	   () { return IEV2.Vint; }
/+
    void print();		// pretty-printer
+/
}

import std.stdio;

void dumpCode(code* foo)
{
	writefln("code.sizeof: %d", code.sizeof);
	writefln("Srcpos.sizeof: %d", Srcpos.sizeof);
	writefln("evc.sizeof: %d", evc.sizeof);
	writefln("EP.sizeof: %d", evc.EP.sizeof);
	writefln("SP.sizeof: %d", evc.SP.sizeof);
	writefln("targ_long.sizeof: %d", targ_long.sizeof);
	foreach (a, b; foo.tupleof)
	{
		///std.stdio.writeln(foo.tupleof[a].stringof, " ", cast(char*)&foo.tupleof[a] - cast(char*)foo, " = ", foo.tupleof[a]);
		//std.stdio.writeln("printf(\"", foo.tupleof[a].stringof, " %d = %d\\n\",(char*)(&", foo.tupleof[a].stringof, ")-(char*)foo, ", foo.tupleof[a].stringof, ");");
	}
}