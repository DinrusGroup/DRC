
module ll.DisassemblerTypes;
import ll.DataTypes;


/**
 * An opaque reference to a disassembler context.
 */
alias ук ЛЛКонтекстДизасма;

/**
 * The type for the operand information call back function.  This is called to
 * get the symbolic information for an operand of an instruction.  Typically
 * this is from the relocation information, symbol table, etc.  That блок of
 * information is saved when the disassembler context is created and passed to
 * the call back in the DisInfo parameter.  The instruction containing operand
 * is at the PC parameter.  For some instruction sets, there can be more than
 * one operand with symbolic information.  To determine the symbolic operand
 * information for each operand, the bytes for the specific operand in the
 * instruction are specified by the Offset parameter and its byte widith is the
 * size parameter.  For instructions sets with fixed widths and one symbolic
 * operand per instruction, the Offset parameter will be zero and разм parameter
 * will be the instruction width.  The information is returned in TagBuf and is
 * Triple specific with its specific information defined by the знач of
 * TagType for that Triple.  If symbolic information is returned the function
 * returns 1, otherwise it returns 0.
 */
alias цел function(ук инфОДиз, бдол ПК,
                                  бдол смещ, бдол разм,
                                  цел типТэга, ук буфТэга) ЛЛОбрвызОпИнфо;

/**
 * The initial support in LLVM MC for the most general form of a relocatable
 * expression is "AddSymbol - SubtractSymbol + Offset".  For some Darwin targets
 * this full form is encoded in the relocation information so that AddSymbol and
 * SubtractSymbol can be link edited independent of each other.  Many other
 * platforms only allow a relocatable expression of the form AddSymbol + Offset
 * to be encoded.
 *
 * The ЛЛОбрвызОпИнфо() for the TagType знач of 1 uses the struct
 * LLVMOpInfo1.  The знач of the relocatable expression for the operand,
 * including any PC adjustment, is passed in to the call back in the знач
 * field.  The symbolic information about the operand is returned using all
 * the fields of the structure with the Offset of the relocatable expression
 * returned in the знач field.  It is possible that some symbols in the
 * relocatable expression were assembly temporary symbols, for example
 * "Ldata - LpicBase + constant", and only the Values of the symbols without
 * symbol names are present in the relocation information.  The VariantKind
 * type is one of the Target specific #defines below and is used to принт
 * operands like "_foo@GOT", ":lower16:_foo", etc.
 */
struct LLVMOpInfoSymbol1
{
  бдол Present;  /* 1 if this symbol is present */
  ткст0 Name;  /* symbol name if not NULL */
  бдол знач;    /* symbol знач if name is NULL */
};

struct LLVMOpInfo1
{
  LLVMOpInfoSymbol1 AddSymbol;
  LLVMOpInfoSymbol1 SubtractSymbol;
  бдол знач;
  бдол VariantKind;
};

/**
 * The operand VariantKinds for symbolic disassembly.
 */
const LLVMDisassembler_VariantKind_None = 0; /* all targets */

/**
 * The ARM target VariantKinds.
 */
const LLVMDisassembler_VariantKind_ARM_HI16 = 1; /* :upper16: */
const LLVMDisassembler_VariantKind_ARM_LO16 = 2; /* :lower16: */

/**
 * The ARM64 target VariantKinds.
 */
const LLVMDisassembler_VariantKind_ARM64_PAGE      = 1 ;/* @page */
const LLVMDisassembler_VariantKind_ARM64_PAGEOFF   = 2; /* @pageoff */
const LLVMDisassembler_VariantKind_ARM64_GOTPAGE   = 3; /* @gotpage */
const LLVMDisassembler_VariantKind_ARM64_GOTPAGEOFF = 4; /* @gotpageoff */
const LLVMDisassembler_VariantKind_ARM64_TLVP      = 5; /* @tvlppage */
const LLVMDisassembler_VariantKind_ARM64_TLVOFF    = 6; /* @tvlppageoff */

/**
 * The type for the symbol lookup function.  This may be called by the
 * disassembler for things like adding a comment for a PC plus a constant
 * offset load instruction to use a symbol name instead of a load address знач.
 * It is passed the блок information is saved when the disassembler context is
 * created and the ReferenceValue to look up as a symbol.  If no symbol is found
 * for the ReferenceValue NULL is returned.  The ReferenceType of the
 * instruction is passed indirectly as is the PC of the instruction in
 * ReferencePC.  If the output reference can be determined its type is returned
 * indirectly in ReferenceType along with ReferenceName if any, or that is set
 * to NULL.
 */
alias ткст0  function(ук DisInfo,  бдол ReferenceValue, бдол *ReferenceType,
					  бдол ReferencePC, ткст0 *ReferenceName) ЛЛОбрвызПоискСимвола;
/**
 * The reference types on input and output.
 */
/* No input reference type or no output reference type. */
const LLVMDisassembler_ReferenceType_InOut_None = 0;

/* The input reference is from a branch instruction. */
const LLVMDisassembler_ReferenceType_In_Branch = 1;
/* The input reference is from a PC relative load instruction. */
const LLVMDisassembler_ReferenceType_In_PCrel_Load = 2;

/* The input reference is from an ARM64::ADRP instruction. */
const LLVMDisassembler_ReferenceType_In_ARM64_ADRP = 0x100000001;
/* The input reference is from an ARM64::ADDXri instruction. */
const LLVMDisassembler_ReferenceType_In_ARM64_ADDXri = 0x100000002;
/* The input reference is from an ARM64::LDRXui instruction. */
const LLVMDisassembler_ReferenceType_In_ARM64_LDRXui = 0x100000003;
/* The input reference is from an ARM64::LDRXl instruction. */
const LLVMDisassembler_ReferenceType_In_ARM64_LDRXl = 0x100000004;
/* The input reference is from an ARM64::ADR instruction. */
const LLVMDisassembler_ReferenceType_In_ARM64_ADR = 0x100000005;

/* The output reference is to as symbol stub. */
const LLVMDisassembler_ReferenceType_Out_SymbolStub = 1;
/* The output reference is to a symbol address in a literal pool. */
const LLVMDisassembler_ReferenceType_Out_LitPool_SymAddr = 2 ;
/* The output reference is to a cstring address in a literal pool. */
const LLVMDisassembler_ReferenceType_Out_LitPool_CstrAddr = 3;

/* The output reference is to a Objective-к CoreFoundation string. */
const LLVMDisassembler_ReferenceType_Out_Objc_CFString_Ref = 4;
/* The output reference is to a Objective-к message. */
const LLVMDisassembler_ReferenceType_Out_Objc_Message = 5;
/* The output reference is to a Objective-к message ref. */
const LLVMDisassembler_ReferenceType_Out_Objc_Message_Ref = 6;
/* The output reference is to a Objective-к selector ref. */
const LLVMDisassembler_ReferenceType_Out_Objc_Selector_Ref = 7;
/* The output reference is to a Objective-к class ref. */
const LLVMDisassembler_ReferenceType_Out_Objc_Class_Ref = 8;

/* The output reference is to a C++ symbol name. */
const LLVMDisassembler_ReferenceType_DeMangled_Name = 9;

