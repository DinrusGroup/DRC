module dmd.AsmStatement;

import dmd.common;
import dmd.Loc;
import dmd.Statement;
import dmd.Token;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.IRState;
import dmd.BE;
import dmd.LabelDsymbol;
import dmd.Dsymbol;
import dmd.Id;
import dmd.TOK;
import dmd.Global;
import dmd.FuncDeclaration;
import dmd.Declaration;
import dmd.LabelStatement;
import dmd.Util;

import dmd.backend.code;
import dmd.backend.iasm;
import dmd.backend.block;
import dmd.backend.Blockx;
import dmd.backend.Util;
import dmd.codegen.Util;
import dmd.backend.BC;
import dmd.backend.FL;
import dmd.backend.SFL;
import dmd.backend.SC;
import dmd.backend.mTY;
import dmd.backend.Symbol;
import dmd.backend.LIST;

import core.stdc.string : memset;
import core.stdc.stdlib : exit, EXIT_FAILURE;

import std.stdio;

import dmd.DDMDExtensions;

class AsmStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Token* tokens;
    code* asmcode;
    uint asmalign;		// alignment of this statement
    bool refparam;		// true if function parameter is referenced
    bool naked;		// true if function is to be naked
    uint regs;		// mask of registers modified

    this(Loc loc, Token* tokens)
	{
		register();

		super(loc);
		this.tokens = tokens;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
    override Statement semantic(Scope sc)
	{
		//printf("AsmStatement.semantic()\n");
//static if (true) {
        if (sc.func && sc.func.isSafe())
        	error("inline assembler not allowed in @safe function %s", sc.func.toChars());
//} else {
//		if (global.params.safe && !sc.module_.safe)
//		{
//			error("inline assembler not allowed in safe mode");
//		}
//}
        
		OP* o;
		OPND* o1 = null;
		OPND* o2 = null;
		OPND* o3 = null;

		PTRNTAB ptb;
		uint usNumops;
		ubyte uchPrefix = 0;
		ubyte bAsmseen;
		char* pszLabel = null;
		code* c;
		FuncDeclaration fd = sc.parent.isFuncDeclaration();

		assert(fd);
		fd.inlineAsm = 1;

		if (!tokens)
			return null;

		auto asmstate = &global.asmstate;
			
		memset(asmstate, 0, (*asmstate).sizeof);

		asmstate.statement = this;
		asmstate.sc = sc;

static if (false) {
		// don't use bReturnax anymore, and will fail anyway if we use return type inference
		// Scalar return values will always be in AX.  So if it is a scalar
		// then asm block sets return value if it modifies AX, if it is non-scalar
		// then always assume that the ASM block sets up an appropriate return
		// value.

		asmstate.bReturnax = 1;
		if (sc.func.type.nextOf().isscalar())
			asmstate.bReturnax = 0;
}

		// Assume assembler code takes care of setting the return value
		sc.func.hasReturnExp |= 8;
		
		if (!asmstate.bInit)
		{
			asmstate.bInit = true;
			init_optab();
			asmstate.psDollar = new LabelDsymbol(Id.__dollar);
			//asmstate.psLocalsize = new VarDeclaration(0, Type.tint32, Id.__LOCAL_SIZE, null);
			asmstate.psLocalsize = new Dsymbol(Id.__LOCAL_SIZE);
			cod3_set386();
		}
		
		asmstate.loc = loc;

		global.asmtok = tokens;
		asm_token_trans(global.asmtok);
		if (setjmp(asmstate.env))
		{	
			global.asmtok = null;			// skip rest of line
			global.tok_value = TOK.TOKeof;
			exit(EXIT_FAILURE);
			goto AFTER_EMIT;
		}

		switch (cast(int)global.tok_value)
		{
			case ASMTK.ASMTKnaked:
				naked = true;
				sc.func.naked = true;
				asm_token();
				break;

			case ASMTK.ASMTKeven:
				asm_token();
				asmalign = 2;
				break;

			case TOK.TOKalign:
			{   
				asm_token();
				uint align_ = asm_getnum();
				if (ispow2(align_) == -1)
					asmerr(ASMERRMSGS.EM_align, align_);	// power of 2 expected
				else
					asmalign = align_;
				break;
			}

			// The following three convert the keywords 'int', 'in', 'out'
			// to identifiers, since they are x86 instructions.
			case TOK.TOKint32:
				o = asm_op_lookup(Id.__int.toChars());
				goto Lopcode;

			case TOK.TOKin:
				o = asm_op_lookup(Id.___in.toChars());
				goto Lopcode;

			case TOK.TOKout:
				o = asm_op_lookup(Id.___out.toChars());
				goto Lopcode;

			case TOK.TOKidentifier:
				o = asm_op_lookup(global.asmtok.ident.toChars());
				if (!o)
					goto OPCODE_EXPECTED;

			Lopcode:
				asmstate.ucItype = o.usNumops & IT.ITMASK;
				asm_token();
				if (o.usNumops > 3)
				{
					switch (asmstate.ucItype)
					{
						case IT.ITdata:
							asmcode = asm_db_parse(o);
							goto AFTER_EMIT;

						case IT.ITaddr:
							asmcode = asm_da_parse(o);
							goto AFTER_EMIT;
						
						default:
							break;
					}
				}
				// get the first part of an expr
				o1 = asm_cond_exp();
				if (global.tok_value == TOK.TOKcomma)
				{
					asm_token();
					o2 = asm_cond_exp();
				}
				if (global.tok_value == TOK.TOKcomma)
				{
					asm_token();
					o3 = asm_cond_exp();
				}
				// match opcode and operands in ptrntab to verify legal inst and
				// generate

				ptb = asm_classify(o, o1, o2, o3, &usNumops);
				assert(ptb.pptb0);

				//
				// The Multiply instruction takes 3 operands, but if only 2 are seen
				// then the third should be the second and the second should
				// be a duplicate of the first.
				//
						
				if (asmstate.ucItype == IT.ITopt &&
					(usNumops == 2) &&
					(ASM_GET_aopty(o2.usFlags) == ASM_OPERAND_TYPE._imm) &&
					((o.usNumops & IT.ITSIZE) == 3))
				{
					o3 = o2;
					o2 = opnd_calloc();
					*o2 = *o1;

					// Re-classify the opcode because the first classification
					// assumed 2 operands.

					ptb = asm_classify(o, o1, o2, o3, &usNumops);
				}
				else
				{
static if (false) {
					if (asmstate.ucItype == IT.ITshift && (ptb.pptb2.usOp2 == 0 ||
						(ptb.pptb2.usOp2 & _cl))) {
						opnd_free(o2);
						o2 = null;
						usNumops = 1;
					}
}
				}

				asmcode = asm_emit(loc, usNumops, ptb, o, o1, o2, o3);
				break;

			default:
			OPCODE_EXPECTED:
				asmerr(ASMERRMSGS.EM_opcode_exp, global.asmtok.toChars());	// assembler opcode expected
				break;
		}

	AFTER_EMIT:
		opnd_free(o1);
		opnd_free(o2);
		opnd_free(o3);
		o1 = o2 = o3 = null;

		if (global.tok_value != TOK.TOKeof)
			asmerr(ASMERRMSGS.EM_eol);			// end of line expected

		//return asmstate.bReturnax;
		return this;
	}
	
    override BE blockExit()
	{
		assert(false);
	}
	
    override bool comeFrom()
	{
		assert(false);
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("asm { ");
		Token* t = tokens;
		while (t)
		{
			buf.writestring(t.toChars());
			if (t.next                         &&
			   t.value != TOKmin               &&
			   t.value != TOKcomma             &&
			   t.next.value != TOKcomma       &&
			   t.value != TOKlbracket          &&
			   t.next.value != TOKlbracket    &&
			   t.next.value != TOKrbracket    &&
			   t.value != TOKlparen            &&
			   t.next.value != TOKlparen      &&
			   t.next.value != TOKrparen      &&
			   t.value != TOKdot               &&
			   t.next.value != TOKdot)
			{
				buf.writebyte(' ');
			}
			t = t.next;
		}
		buf.writestring("; }");
		buf.writenl();
	}
	
    override AsmStatement isAsmStatement() { return this; }

    override void toIR(IRState *irs)
	{
		block* bpre;
		block* basm;
		Declaration d;
		Symbol* s;
		Blockx* blx = irs.blx;

//		dumpCode(asmcode);

		//printf("AsmStatement::toIR(asmcode = %x)\n", asmcode);
		bpre = blx.curblock;
		block_next(blx,BCgoto,null);
		basm = blx.curblock;
		list_append(&bpre.Bsucc, basm);
		basm.Bcode = asmcode;
		basm.Balign = cast(ubyte)asmalign;

static if (false) {
		if (label)
		{	
			block* b = labelToBlock(loc, blx, label);
			printf("AsmStatement::toIR() %p\n", b);
			if (b)
				list_append(&basm.Bsucc, b);
		}
}
		// Loop through each instruction, fixing Dsymbols into Symbol's
		for (code* c = asmcode; c; c = c.next)
		{	
			LabelDsymbol label;
			block* b;
			
			switch (c.IFL1)
			{
				case FLblockoff:
				case FLblock:
					// FLblock and FLblockoff have LabelDsymbol's - convert to blocks
					label = c.IEVlsym1;
					b = labelToBlock(loc, blx, label);
					list_append(&basm.Bsucc, b);
					c.IEV1.Vblock = b;
					break;

				case FLdsymbol:
				case FLfunc:
					s = c.IEVdsym1.toSymbol();
					if (s.Sclass == SCauto && s.Ssymnum == -1)
						symbol_add(s);
					c.IEVsym1() = s;
					c.IFL1 = s.Sfl ? s.Sfl : FLauto;
					break;
				default:
					break;
			}

			// Repeat for second operand
			switch (c.IFL2)
			{
				case FLblockoff:
				case FLblock:
					label = c.IEVlsym2;
					b = labelToBlock(loc, blx, label);
					list_append(&basm.Bsucc, b);
					c.IEV2.Vblock = b;
					break;

				case FLdsymbol:
				case FLfunc:
					d = c.IEVdsym2;
					s = d.toSymbol();
					if (s.Sclass == SCauto && s.Ssymnum == -1)
						symbol_add(s);
					c.IEVsym2() = s;
					c.IFL2 = s.Sfl ? s.Sfl : FLauto;
					if (d.isDataseg())
						s.Sflags |= SFLlivexit;
					break;
				default:
					break;
			}
			//c.print();
		}

		basm.bIasmrefparam = refparam;		// are parameters reference?
		basm.usIasmregs = cast(ushort)regs;			// registers modified

		block_next(blx,BCasm, null);
		list_prepend(&basm.Bsucc, blx.curblock);

		if (naked)
		{
			blx.funcsym.Stype.Tty |= mTYnaked;
		}
	}
}
