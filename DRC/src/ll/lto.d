
module ll.lto;
import ll.Types;


/**
 * @defgroup LLVMCLTO LTO
 * @ingroup LLVMC
 *
 * @{
 */

const LTO_API_VERSION = 24;

/**
 * \since prior to LTO_API_VERSION=3
 */
enum ЛЛАтрибутыСимволаОВК{
    LTO_SYMBOL_ALIGNMENT_MASK              = 0x0000001F, /* log2 of alignment */
    LTO_SYMBOL_PERMISSIONS_MASK            = 0x000000E0,
    LTO_SYMBOL_PERMISSIONS_CODE            = 0x000000A0,
    LTO_SYMBOL_PERMISSIONS_DATA            = 0x000000C0,
    LTO_SYMBOL_PERMISSIONS_RODATA          = 0x00000080,
    LTO_SYMBOL_DEFINITION_MASK             = 0x00000700,
    LTO_SYMBOL_DEFINITION_REGULAR          = 0x00000100,
    LTO_SYMBOL_DEFINITION_TENTATIVE        = 0x00000200,
    LTO_SYMBOL_DEFINITION_WEAK             = 0x00000300,
    LTO_SYMBOL_DEFINITION_UNDEFINED        = 0x00000400,
    LTO_SYMBOL_DEFINITION_WEAKUNDEF        = 0x00000500,
    LTO_SYMBOL_SCOPE_MASK                  = 0x00003800,
    LTO_SYMBOL_SCOPE_INTERNAL              = 0x00000800,
    LTO_SYMBOL_SCOPE_HIDDEN                = 0x00001000,
    LTO_SYMBOL_SCOPE_PROTECTED             = 0x00002000,
    LTO_SYMBOL_SCOPE_DEFAULT               = 0x00001800,
    LTO_SYMBOL_SCOPE_DEFAULT_CAN_BE_HIDDEN = 0x00002800,
    LTO_SYMBOL_COMDAT                      = 0x00004000,
    LTO_SYMBOL_ALIAS                       = 0x00008000
} ;

/**
 * \since prior to LTO_API_VERSION=3
 */
enum ЛЛМодельОтладки{
    LTO_DEBUG_MODEL_NONE         = 0,
    LTO_DEBUG_MODEL_DWARF        = 1
} ;

/**
 * \since prior to LTO_API_VERSION=3
 */
enum ЛЛМодельОВККодген{
    LTO_CODEGEN_PIC_MODEL_STATIC         = 0,
    LTO_CODEGEN_PIC_MODEL_DYNAMIC        = 1,
    LTO_CODEGEN_PIC_MODEL_DYNAMIC_NO_PIC = 2,
    LTO_CODEGEN_PIC_MODEL_DEFAULT        = 3
} ;

struct LLVMOpaqueLTOModule{}
/** opaque reference to a loaded object модule */
alias LLVMOpaqueLTOModule *ЛЛОВКМодуль;

struct LLVMOpaqueLTOCodeGenerator{}
/** opaque reference to a code generator */
alias LLVMOpaqueLTOCodeGenerator *ЛЛОВККодГен;

struct LLVMOpaqueThinLTOCodeGenerator{}
/** opaque reference to a thin code generator */
alias LLVMOpaqueThinLTOCodeGenerator *ЛЛОВККодГен2;

extern (C){


/**
 * Returns a printable string.
 *
 * \since prior to LTO_API_VERSION=3
 */
 ткст0 ЛЛОВК_ДайВерсию();

/**
 * Returns the last error string or NULL if last operation was successful.
 *
 * \since prior to LTO_API_VERSION=3
 */
 ткст0 ЛЛОВК_ДайОшСооб();

/**
 * Checks if a file is a loadable object file.
 *
 * \since prior to LTO_API_VERSION=3
 */
 бул ЛЛОВКМодуль_ФайлОбъект_ли(ткст0 путь);

/**
 * Checks if a file is a loadable object compiled for requested target.
 *
 * \since prior to LTO_API_VERSION=3
 */
 бул ЛЛОВКМодуль_ФайлОбъектДляЦели_ли(ткст0 путь,
                                     ткст0 префиксТриадыЦели);

/**
 * Return true if \p Buffer contains a bitcode file with ObjC code (category
 * or class) in it.
 *
 * \since LTO_API_VERSION=20
 */
 бул ЛЛОВКМодуль_ЕстьКатегорияОБджСи_ли(ук пам, т_мера длина);

/**
 * Checks if a buffer is a loadable object file.
 *
 * \since prior to LTO_API_VERSION=3
 */
 бул ЛЛОВКМодуль_ФайлОбъектВПамяти_ли(ук пам,
                                                      т_мера длина);

/**
 * Checks if a buffer is a loadable object compiled for requested target.
 *
 * \since prior to LTO_API_VERSION=3
 */
 бул ЛЛОВКМодуль_ФайлОбъектВПамятиДляЦели_ли(ук пам, т_мера длина, ткст0 префиксТриадыЦели);

/**
 * Loads an object file from disk.
 * Returns NULL on error (check lto_get_error_message() for details).
 *
 * \since prior to LTO_API_VERSION=3
 */
 ЛЛОВКМодуль ЛЛОВКМодуль_Создай(ткст0 путь);

/**
 * Loads an object file from memory.
 * Returns NULL on error (check lto_get_error_message() for details).
 *
 * \since prior to LTO_API_VERSION=3
 */
 ЛЛОВКМодуль ЛЛОВКМодуль_СоздайИзПамяти(ук пам, т_мера длина);

/**
 * Loads an object file from memory with an extra путь argument.
 * Returns NULL on error (check lto_get_error_message() for details).
 *
 * \since LTO_API_VERSION=9
 */
 ЛЛОВКМодуль ЛЛОВКМодуль_СоздайИзПамятиСПутём(ук пам, т_мера длина, ткст0 путь);

/**
 * Loads an object file in its own context.
 *
 * Loads an object file in its own LLVMContext.  This function call is
 * thread-safe.  However, модules created this way should not be merged into an
 * ЛЛОВККодГен using \a lto_codegen_add_модule().
 *
 * Returns NULL on error (check lto_get_error_message() for details).
 *
 * \since LTO_API_VERSION=11
 */
 ЛЛОВКМодуль ЛЛОВКМодуль_СоздайВЛокКонтексте(ук пам, т_мера длина, ткст0 путь);

/**
 * Loads an object file in the codegen context.
 *
 * Loads an object file into the same context as \конст кг.  The модule is safe to
 * add using \a lto_codegen_add_модule().
 *
 * Returns NULL on error (check lto_get_error_message() for details).
 *
 * \since LTO_API_VERSION=11
 */
 ЛЛОВКМодуль ЛЛОВКМодуль_СоздайВКонтекстеКодГена(ук пам, т_мера длина, ткст0 путь, ЛЛОВККодГен кг);

/**
 * Loads an object file from disk. The seek point of фд is not preserved.
 * Returns NULL on error (check lto_get_error_message() for details).
 *
 * \since LTO_API_VERSION=5
 */
 ЛЛОВКМодуль ЛЛОВКМодуль_СоздайИзФД(цел фд, ткст0 путь, т_мера фразм);

/**
 * Loads an object file from disk. The seek point of фд is not preserved.
 * Returns NULL on error (check lto_get_error_message() for details).
 *
 * \since LTO_API_VERSION=5
 */
 ЛЛОВКМодуль ЛЛОВКМодуль_СоздайИзФДПоСмещению(цел фд, ткст0 путь, т_мера фразм, т_мера map_size, off_t смещение);

/**
 * Frees all memory internally allocated by the модule.
 * Upon return the ЛЛОВКМодуль is no longer valid.
 *
 * \since prior to LTO_API_VERSION=3
 */
 проц ЛЛОВКМодуль_Вымести(ЛЛОВКМодуль мод);

/**
 * Returns триада string which the object модule was compiled under.
 *
 * \since prior to LTO_API_VERSION=3
 */
 ткст0 ЛЛОВКМодуль_ДайТриадуЦели(ЛЛОВКМодуль мод);

/**
 * Sets триада string with which the object will be codegened.
 *
 * \since LTO_API_VERSION=4
 */
 проц ЛЛОВКМодуль_УстТриадуЦели(ЛЛОВКМодуль мод, ткст0 триада);

/**
 * Returns the number of символs in the object модule.
 *
 * \since prior to LTO_API_VERSION=3
 */
 бцел ЛЛОВКМодуль_ДайЧлоСимволов(ЛЛОВКМодуль мод);

/**
 * Returns the name of the ith символ in the object модule.
 *
 * \since prior to LTO_API_VERSION=3
 */
 ткст0 ЛЛОВКМодуль_ДайИмяСимвола(ЛЛОВКМодуль мод, бцел инд);

/**
 * Returns the attributes of the ith символ in the object модule.
 *
 * \since prior to LTO_API_VERSION=3
 */
 ЛЛАтрибутыСимволаОВК ЛЛОВКМодуль_ДайАтрибутыСимвола(ЛЛОВКМодуль мод, бцел инд);

/**
 * Returns the модule's linker options.
 *
 * The linker options may consist of multiple flags. It is the linker's
 * responsibility to split the flags using a platform-specific mechanism.
 *
 * \since LTO_API_VERSION=16
 */
 ткст0 ЛЛОВКМодуль_ДайОпцииКомпоновщика(ЛЛОВКМодуль мод);

/**
 * Diagnostic severity.
 *
 * \since LTO_API_VERSION=7
 */
enum ЛЛОВККодГенДиагностичСтрогость {
  LTO_DS_ERROR = 0,
  LTO_DS_WARNING = 1,
  LTO_DS_REMARK = 3, // Added in LTO_API_VERSION=10.
  LTO_DS_NOTE = 2
} ;

/**
 * Diagnostic handler type.
 * \p severity defines the severity.
 * \p diag is the actual diagnostic.
 * The diagnostic is not prefixed by any of severity keyword, e.g., 'error: '.
 * \p ctxt is used to pass the context set with the diagnostic handler.
 *
 * \since LTO_API_VERSION=7
 */
alias проц function(ЛЛОВККодГенДиагностичСтрогость строгость, ткст0 diag, ук ctxt)
	lto_diagnostic_handler_t;

/**
 * Set a diagnostic handler and the related context (ук ).
 * This is more general than lto_get_error_message, as the diagnostic handler
 * can be called at anytime within lto.
 *
 * \since LTO_API_VERSION=7
 */
 проц ЛЛОВККодГен_УстОбработчикДиагностики(ЛЛОВККодГен,
                                               lto_diagnostic_handler_t,
                                               ук );

/**
 * Instantiates a code generator.
 * Returns NULL on error (check lto_get_error_message() for details).
 *
 * All модules added using \a lto_codegen_add_модule() must have been created
 * in the same context as the codegen.
 *
 * \since prior to LTO_API_VERSION=3
 */
 ЛЛОВККодГен ЛЛОВККодГен_Создай();

/**
 * Instantiate a code generator in its own context.
 *
 * Instantiates a code generator in its own context.  Modules added via \a
 * lto_codegen_add_модule() must have all been created in the same context,
 * using \a lto_модule_create_in_codegen_context().
 *
 * \since LTO_API_VERSION=11
 */
 ЛЛОВККодГен ЛЛОВККодГен_СоздайВЛокКонтексте();

/**
 * Frees all code generator and all memory it internally allocated.
 * Upon return the ЛЛОВККодГен is no longer valid.
 *
 * \since prior to LTO_API_VERSION=3
 */
 проц ЛЛОВККодГен_Вымести(ЛЛОВККодГен);

/**
 * Add an object модule to the set of модules for which code will be generated.
 * Returns true on error (check lto_get_error_message() for details).
 *
 * \конст кг and \конст мод must both be in the same context.  See \a
 * lto_codegen_create_in_local_context() and \a
 * lto_модule_create_in_codegen_context().
 *
 * \since prior to LTO_API_VERSION=3
 */
 бул ЛЛОВККодГен_ДобавьМодуль(ЛЛОВККодГен кг, ЛЛОВКМодуль мод);

/**
 * Sets the object модule for code generation. This will transfer the ownership
 * of the модule to the code generator.
 *
 * \конст кг and \конст мод must both be in the same context.
 *
 * \since LTO_API_VERSION=13
 */
 проц ЛЛОВККодГен_УстМодуль(ЛЛОВККодГен кг, ЛЛОВКМодуль мод);

/**
 * Sets if debug info should be generated.
 * Returns true on error (check lto_get_error_message() for details).
 *
 * \since prior to LTO_API_VERSION=3
 */
 бул ЛЛОВККодГен_УстМодельОтладки(ЛЛОВККодГен кг, ЛЛМодельОтладки);

/**
 * Sets which PIC code модel to generated.
 * Returns true on error (check lto_get_error_message() for details).
 *
 * \since prior to LTO_API_VERSION=3
 */
 бул ЛЛОВККодГен_УстМодельПИК(ЛЛОВККодГен кг, ЛЛМодельОВККодген);

/**
 * Sets the цпб to generate code for.
 *
 * \since LTO_API_VERSION=4
 */
 проц ЛЛОВККодГен_УстЦПБ(ЛЛОВККодГен кг, ткст0 цпб);

/**
 * Sets the location of the assembler tool to run. If not set, libLTO
 * will use gcc to invoke the assembler.
 *
 * \since LTO_API_VERSION=3
 */
 проц ЛЛОВККодГен_УстАсмПуть(ЛЛОВККодГен кг, ткст0 путь);

/**
 * Sets extra arguments that libLTO should pass to the assembler.
 *
 * \since LTO_API_VERSION=4
 */
 проц ЛЛОВККодГен_УстАсмАрги(ЛЛОВККодГен кг, ткст0 *args, цел члоАрг);

/**
 * Adds to a list of all global символs that must exist in the final generated
 * code. If a function is not listed there, it might be inlined into every usage
 * and optimized away.
 *
 * \since prior to LTO_API_VERSION=3
 */
 проц ЛЛОВККодГен_ДобавьСимволМастПрезерв(ЛЛОВККодГен кг, ткст0 символ);

/**
 * Writes a new object file at the specified путь that contains the
 * merged contents of all модules added so far.
 * Returns true on error (check lto_get_error_message() for details).
 *
 * \since LTO_API_VERSION=5
 */
 бул ЛЛОВККодГен_ПишиСлитноМодуль(ЛЛОВККодГен кг, ткст0 путь);

/**
 * Generates code for all added модules into one native object file.
 * This calls lto_codegen_optimize then lto_codegen_compile_optimized.
 *
 * On success returns a pointer to a generated mach-o/ELF buffer and
 * длина set to the buffer size.  The buffer is owned by the
 * ЛЛОВККодГен and will be freed when lto_codegen_dispose()
 * is called, or lto_codegen_compile() is called again.
 * On failure, returns NULL (check lto_get_error_message() for details).
 *
 * \since prior to LTO_API_VERSION=3
 */
 ук ЛЛОВККодГен_Компилируй(ЛЛОВККодГен кг, т_мера* длина);

/**
 * Generates code for all added модules into one native object file.
 * This calls lto_codegen_optimize then lto_codegen_compile_optimized (instead
 * of returning a generated mach-o/ELF buffer, it writes to a file).
 *
 * The name of the file is written to name. Returns true on error.
 *
 * \since LTO_API_VERSION=5
 */
 бул ЛЛОВККодГен_КомпилируйВФайл(ЛЛОВККодГен кг, ткст0* name);

/**
 * Runs optimization for the merged модule. Returns true on error.
 *
 * \since LTO_API_VERSION=12
 */
 бул ЛЛОВККодГен_Оптимизируй(ЛЛОВККодГен кг);

/**
 * Generates code for the optimized merged модule into one native object file.
 * It will not run any IR optimizations on the merged модule.
 *
 * On success returns a pointer to a generated mach-o/ELF buffer and длина set
 * to the buffer size.  The buffer is owned by the ЛЛОВККодГен and will be
 * freed when lto_codegen_dispose() is called, or
 * lto_codegen_compile_optimized() is called again. On failure, returns NULL
 * (check lto_get_error_message() for details).
 *
 * \since LTO_API_VERSION=12
 */
 ук ЛЛОВККодГен_КомпилируйОптимиз(ЛЛОВККодГен кг, т_мера* длина);

/**
 * Returns the runtime API version.
 *
 * \since LTO_API_VERSION=12
 */
 бцел ЛЛОВКАПИВерсия();

/**
 * Sets options to help debug codegen bugs.
 *
 * \since prior to LTO_API_VERSION=3
 */
 проц ЛЛОВККодГен_ОпцииОтладки(ЛЛОВККодГен кг, ткст0 );

/**
 * Initializes LLVM disassemblers.
 * FIXME: This doesn't really belong here.
 *
 * \since LTO_API_VERSION=5
 */
 проц ЛЛОВК_ИницДизасм();

/**
 * Sets if we should run internalize pass during optimization and code
 * generation.
 *
 * \since LTO_API_VERSION=14
 */
 проц ЛЛОВККодГен_УстСледуетИнтернализовать(ЛЛОВККодГен кг, бул интернализовать_ли);

/**
 * Set whether to embed uselists in bitcode.
 *
 * Sets whether \a lto_codegen_write_merged_модules() should embed uselists in
 * output bitcode.  This should be turned on for all -save-temps output.
 *
 * \since LTO_API_VERSION=15
 */
 проц ЛЛОВККодГен_УстСледуетВнедритьСписокИспользований(ЛЛОВККодГен кг, бул ShouldEmbedUselists);

/**
 * @} // endgoup LLVMCLTO
 * @defgroup LLVMCTLTO ThinLTO
 * @ingroup LLVMC
 *
 * @{
 */

/**
 * Type to wrap a single object returned by ThinLTO.
 *
 * \since LTO_API_VERSION=18
 */
struct LTOObjectBuffer {
  ткст0 Buffer;
  т_мера разм;
} ;

/**
 * Instantiates a ThinLTO code generator.
 * Returns NULL on error (check lto_get_error_message() for details).
 *
 *
 * The ThinLTOCodeGenerator is not intended to be reuse for multiple
 * compilation: the модel is that the client adds модules to the generator and
 * ask to perform the ThinLTO optimizations / codegen, and finally destroys the
 * codegenerator.
 *
 * \since LTO_API_VERSION=18
 */
 ЛЛОВККодГен2 ЛЛОВК2_СоздайКодГен();

/**
 * Frees the generator and all memory it internally allocated.
 * Upon return the ЛЛОВККодГен2 is no longer valid.
 *
 * \since LTO_API_VERSION=18
 */
 проц ЛЛОВК2_ВыместиКодГен(ЛЛОВККодГен2 кг);

/**
 * Add a модule to a ThinLTO code generator. Identifier has to be unique among
 * all the модules in a code generator. The data buffer stays owned by the
 * client, and is expected to be available for the entire lifetime of the
 * ЛЛОВККодГен2 it is added to.
 *
 * On failure, returns NULL (check lto_get_error_message() for details).
 *
 *
 * \since LTO_API_VERSION=18
 */
 проц ЛЛОВК2_ДобавьМодуль(ЛЛОВККодГен2 кг,
                                       ткст0 identifier, ткст0 data, цел длина);

/**
 * Optimize and codegen all the модules added to the codegenerator using
 * ThinLTO. Resulting objects are accessible using thinlto_модule_get_object().
 *
 * \since LTO_API_VERSION=18
 */
 проц ЛЛОВК2КодГен_Обработай(ЛЛОВККодГен2 кг);

/**
 * Returns the number of object files produced by the ThinLTO CodeGenerator.
 *
 * It usually matches the number of input files, but this is not a guarantee of
 * the API and may change in future implementation, so the client should not
 * assume it.
 *
 * \since LTO_API_VERSION=18
 */
 бцел ЛЛОВК2Модуль_ДайЧлоОбъектов(ЛЛОВККодГен2 кг);

/**
 * Returns a reference to the ith object file produced by the ThinLTO
 * CodeGenerator.
 *
 * Client should use \p thinlto_модule_get_num_objects() to get the number of
 * available objects.
 *
 * \since LTO_API_VERSION=18
 */
 LTOObjectBuffer ЛЛОВК2Модуль_ДайОбъект(ЛЛОВККодГен2 кг, бцел инд);

/**
 * Returns the number of object files produced by the ThinLTO CodeGenerator.
 *
 * It usually matches the number of input files, but this is not a guarantee of
 * the API and may change in future implementation, so the client should not
 * assume it.
 *
 * \since LTO_API_VERSION=21
 */
бцел ЛЛОВК2Модуль_ДайЧлоОбъектФайлов(ЛЛОВККодГен2 кг);

/**
 * Returns the путь to the ith object file produced by the ThinLTO
 * CodeGenerator.
 *
 * Client should use \p thinlto_модule_get_num_object_files() to get the number
 * of available objects.
 *
 * \since LTO_API_VERSION=21
 */
ткст0 ЛЛОВК2Модуль_ДайОбъектФайл(ЛЛОВККодГен2 кг, бцел инд);

/**
 * Sets which PIC code модel to generate.
 * Returns true on error (check lto_get_error_message() for details).
 *
 * \since LTO_API_VERSION=18
 */
 бул ЛЛОВК2КодГен_УстМодельПИК(ЛЛОВККодГен2 кг, ЛЛМодельОВККодген модель);

/**
 * Sets the путь to a directory to use as a storage for temporary bitcode files.
 * The intention is to make the bitcode files available for debugging at various
 * stage of the pipeline.
 *
 * \since LTO_API_VERSION=18
 */
 проц ЛЛОВК2КодГен_УстПапкуВремХран(ЛЛОВККодГен2 кг, ткст0 времХранПап);

/**
 * Set the путь to a directory where to save generated object files. This
 * путь can be used by a linker to request on-disk files instead of in-memory
 * buffers. When set, results are available through
 * thinlto_модule_get_object_file() instead of thinlto_модule_get_object().
 *
 * \since LTO_API_VERSION=21
 */
проц ЛЛОВК2КодГен_УстПапкуСгенОбъектов(ЛЛОВККодГен2 кг, ткст0 времХранПап);

/**
 * Sets the цпб to generate code for.
 *
 * \since LTO_API_VERSION=18
 */
 проц ЛЛОВК2КодГен_УстЦПБ(ЛЛОВККодГен2 кг, ткст0 цпб);

/**
 * Disable CodeGen, only run the stages till codegen and stop. The output will
 * be bitcode.
 *
 * \since LTO_API_VERSION=19
 */
 проц ЛЛОВК2КодГен_ОтключиКодГен(ЛЛОВККодГен2 кг, бул отключить_ли);

/**
 * Perform CodeGen only: disable all other stages.
 *
 * \since LTO_API_VERSION=19
 */
 проц ЛЛОВК2КодГен_УстТолькоКодГен(ЛЛОВККодГен2 кг, бул codegen_only);

/**
 * Parse -mllvm style debug options.
 *
 * \since LTO_API_VERSION=18
 */
 проц ЛЛОВК2_ОпцииОтладки(ткст0 *options, цел number);

/**
 * Test if a модule has support for ThinLTO linking.
 *
 * \since LTO_API_VERSION=18
 */
 бул ЛЛОВКМодуль_ОВК2_ли(ЛЛОВКМодуль мод);

/**
 * Adds a символ to the list of global символs that must exist in the final
 * generated code. If a function is not listed there, it might be inlined into
 * every usage and optimized away. For every single модule, the functions
 * referenced from code outside of the ThinLTO модules need to be added here.
 *
 * \since LTO_API_VERSION=18
 */
 проц ЛЛОВК2КодГен_ДобавьСимволМастПрезерв(ЛЛОВККодГен2 кг,
                                                     ткст0 name,
                                                     цел длина);

/**
 * Adds a символ to the list of global символs that are cross-referenced between
 * ThinLTO files. If the ThinLTO CodeGenerator can ensure that every
 * references from a ThinLTO модule to this символ is optimized away, then
 * the символ can be discarded.
 *
 * \since LTO_API_VERSION=18
 */
 проц ЛЛОВК2КодГен_ДобавьКроссРефСимвол(ЛЛОВККодГен2 кг,
                                                        ткст0 name,
                                                        цел длина);

/**
 * @} // endgoup LLVMCTLTO
 * @defgroup LLVMCTLTO_CACHING ThinLTO Cache Control
 * @ingroup LLVMCTLTO
 *
 * These entry points control the ThinLTO cache. The cache is intended to
 * support incremental builds, and thus needs to be persistent across builds.
 * The client enables the cache by supplying a путь to an existing directory.
 * The code generator will use this to store objects files that may be reused
 * during a subsequent построй.
 * To avoid filling the disk space, a few knobs are provided:
 *  - The pruning interval limits the frequency at which the garbage collector
 *    will try to scan the cache directory to prune expired entries.
 *    Setting to a negative number disables the pruning.
 *  - The pruning expiration time indicates to the garbage collector how old an
 *    entry needs to be to be removed.
 *  - Finally, the garbage collector can be instructed to prune the cache until
 *    the occupied space goes below a threshold.
 * @{
 */

/**
 * Sets the путь to a directory to use as a cache storage for incremental построй.
 * Setting this activates caching.
 *
 * \since LTO_API_VERSION=18
 */
 проц ЛЛОВК2КодГен_УстПапкуКэша(ЛЛОВККодГен2 кг,
                                          ткст0 cache_dir);

/**
 * Sets the cache pruning interval (in seconds). атр negative знач disables the
 * pruning. An unspecified default знач will be applied, and a знач of 0 will
 * force prunning to occur.
 *
 * \since LTO_API_VERSION=18
 */
 проц ЛЛОВК2КодГен_УстИнтервалПрюнингаКэша(ЛЛОВККодГен2 кг,
                                                       цел interval);

/**
 * Sets the maximum cache size that can be persistent across построй, in terms of
 * percentage of the available space on the disk. Set to 100 to indicate
 * no limit, 50 to indicate that the cache size will not be left over half the
 * available space. атр знач over 100 will be reduced to 100, a знач of 0 will
 * be ignored. An unspecified default знач will be applied.
 *
 * The formula looks like:
 *  AvailableSpace = FreeSpace + ExistingCacheSize
 *  NewCacheSize = AvailableSpace * P/100
 *
 * \since LTO_API_VERSION=18
 */
 проц ЛЛОВК2КодГен_УстФинальнРазКэшаОтносительноДоступнПрострву(
    ЛЛОВККодГен2 кг, бцел percentage);

/**
 * Sets the expiration (in seconds) for an entry in the cache. An unspecified
 * default знач will be applied. атр знач of 0 will be ignored.
 *
 * \since LTO_API_VERSION=18
 */
 проц ЛЛОВК2КодГен_УстЭкспирациюЗаписиКэша(ЛЛОВККодГен2 кг,
                                                       бцел expiration);

/**
 * Sets the maximum size of the cache directory (in bytes). атр знач over the
 * amount of available space on the disk will be reduced to the amount of
 * available space. An unspecified default знач will be applied. атр знач of 0
 * will be ignored.
 *
 * \since LTO_API_VERSION=22
 */
 проц ЛЛОВК2КодГен_УстРазмКэшаВБайтах(ЛЛОВККодГен2 кг,
                                                 бцел max_size_bytes);

/**
 * Same as thinlto_codegen_set_cache_size_bytes, except the maximum size is in
 * megabytes (2^20 bytes).
 *
 * \since LTO_API_VERSION=23
 */
 проц ЛЛОВК2КодГен_УстРазмКэшаВМегаБайтах(ЛЛОВККодГен2 кг,
                                         бцел max_size_megabytes);

/**
 * Sets the maximum number of files in the cache directory. An unspecified
 * default знач will be applied. атр знач of 0 will be ignored.
 *
 * \since LTO_API_VERSION=22
 */
 проц ЛЛОВК2КодГен_УстРазмКэшаВФайлах(ЛЛОВККодГен2 кг, бцел max_size_files);

struct LLVMOpaqueLTOInput{}
/** Opaque reference to an LTO input file */
alias LLVMOpaqueLTOInput *ЛЛОВКВвод;

/**
  * Creates an LTO input file from a buffer. The путь
  * argument is used for diagnotics as this function
  * otherwise does not know which file the given buffer
  * is associated with.
  *
  * \since LTO_API_VERSION=24
  */
 ЛЛОВКВвод ЛЛОВКВвод_Создай(ук буф, т_мера размБуф, ткст0 путь);

/**
  * Frees all memory internally allocated by the LTO input file.
  * Upon return the ЛЛОВКМодуль is no longer valid.
  *
  * \since LTO_API_VERSION=24
  */
 проц ЛЛОВКВвод_Вымести(ЛЛОВКВвод ввод);

/**
  * Returns the number of dependent library specifiers
  * for the given LTO input file.
  *
  * \since LTO_API_VERSION=24
  */
 бцел ЛЛОВКВвод_ДайЧлоЗависимыхБиб(ЛЛОВКВвод ввод);

/**
  * Returns the ith dependent library specifier
  * for the given LTO input file. The returned
  * string is not null-terminated.
  *
  * \since LTO_API_VERSION=24
  */
 ткст0  ЛЛОВКВвод_ДайЗависимБиб(ЛЛОВКВвод input, т_мера инд,т_мера *разм);


}
