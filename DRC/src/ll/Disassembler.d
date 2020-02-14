
module ll.Disassembler;
import ll.DisassemblerTypes, ll.Types;

/**
 * @defgroup LLVMCDisassembler Дизассемблер
 * @ingroup LLVMC
 *
 * @{
 */


extern (C){


/**
 * Создаёт дизассемблер для имяТриады.  Символьное дизассемблирование поддерживается
 * передачей блока инфы в парметр инфоДиз и указанием
 * типТэга и функциями обрвызова, как описано выше. Все они могут передаваться
 * как NULL.  При успехе возвращается контекст дизассемблирования.  При провале
 * возвращается NULL. Эта функция равноценна вызову
 * LLVMCreateDisasmCPUFeatures() с пустым именем CPU и набором фич.
 */
ЛЛКонтекстДизасма ЛЛСоздайДизасм(ткст0 имяТриады, ук инфоДиз, цел типТэга, ЛЛОбрвызОпИнфо дайОпИнфо, ЛЛОбрвызПоискСимвола поискСим);

/**
 * Create a disassembler for the имяТриады and a specific CPU.  Symbolic
 * disassembly is supported by passing a блок of information in the инфоДиз
 * parameter and specifying the типТэга and callback functions as described
 * above.  These can all be passed * as NULL.  If successful, this returns a
 * disassembler context.  If not, it returns NULL. This function is equivalent
 * to calling LLVMCreateDisasmCPUFeatures() with an empty feature set.
 */
ЛЛКонтекстДизасма ЛЛСоздайДизасмЦПБ(ткст0 триада, ткст0 CPU, ук инфоДиз, цел типТэга,
     ЛЛОбрвызОпИнфо дайОпИнфо, ЛЛОбрвызПоискСимвола поискСим);

/**
 * Create a disassembler for the имяТриады, a specific CPU and specific feature
 * string.  Symbolic disassembly is supported by passing a блок of information
 * in the инфоДиз parameter and specifying the типТэга and callback functions as
 * described above.  These can all be passed * as NULL.  If successful, this
 * returns a disassembler context.  If not, it returns NULL.
 */
ЛЛКонтекстДизасма
ЛЛСоздайДизасмЦПБФичи(ткст0 триада, ткст0 цпу,
                            ткст0 фичи, ук инфоДиз, цел типТэга,
                            ЛЛОбрвызОпИнфо дайОпИнфо,
                            ЛЛОбрвызПоискСимвола поискСим);

/**
 * Установить опции дизассемблера.  Возвращает 1, если может установить Опции или 0,
 * в противном случае.
 */
цел ЛЛУстОпцииДизасм(ЛЛКонтекстДизасма DC, бдол опции);

/* The option to produce marked up assembly. */
const LLVMDisassembler_Option_UseMarkup = 1;
/* The option to принт immediates as hex. */
const LLVMDisassembler_Option_PrintImmHex = 2;
/* The option use the other assembler printer variant */
const LLVMDisassembler_Option_AsmPrinterVariant = 4;
/* The option to set comment on instructions */
const LLVMDisassembler_Option_SetInstrComments = 8;
  /* The option to принт latency information alongside instructions */
const LLVMDisassembler_Option_PrintLatency = 16;



/**
 * Выместить контекст дизассемблера.
 */
проц ЛЛВыместиДизасм(ЛЛКонтекстДизасма DC);

/**
 * Disassemble a single instruction using the disassembler context specified in
 * the parameter DC.  The bytes of the instruction are specified in the
 * parameter байты, and contains at least BytesSize number of bytes.  The
 * instruction is at the address specified by the PC parameter.  If a valid
 * instruction can be disassembled, its string is returned indirectly in
 * OutString whose size is specified in the parameter OutStringSize.  This
 * function returns the number of bytes in the instruction or zero if there was
 * no valid instruction.
 */
т_мера ЛЛИнструкцияДмзасм(ЛЛКонтекстДизасма DC, ббайт *байты,
бдол разБайт, бдол пк, ткст0 выхТкст, т_мера размВыхТкст);

}

