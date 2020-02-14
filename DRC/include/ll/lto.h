extern "C"
{
  #include "Header.h"

LLEXPORT const char* ЛЛОВК_ДайВерсию();
LLEXPORT const char* ЛЛОВК_ДайОшСооб() ;
LLEXPORT bool ЛЛОВКМодуль_ФайлОбъект_ли(const char* path) ;
LLEXPORT bool ЛЛОВКМодуль_ФайлОбъектДляЦели_ли(const char* path,
                                          const char* target_triplet_prefix) ;
LLEXPORT bool ЛЛОВКМодуль_ЕстьКатегорияОБджСи_ли(const void *mem, size_t length);
LLEXPORT bool ЛЛОВКМодуль_ФайлОбъектВПамяти_ли(const void* mem, size_t length);
LLEXPORT bool
ЛЛОВКМодуль_ФайлОбъектВПамятиДляЦели_ли(const void* mem,
                                            size_t length,
                                            const char* target_triplet_prefix) ;
LLEXPORT lto_module_t ЛЛОВКМодуль_Создай(const char* path) ;
LLEXPORT lto_module_t ЛЛОВКМодуль_СоздайИзФД(int fd, const char *path, size_t size) ;
LLEXPORT lto_module_t ЛЛОВКМодуль_СоздайИзФДПоСмещению(int fd, const char *path,
                                                 size_t file_size,
                                                 size_t map_size,
                                                 off_t offset);
LLEXPORT lto_module_t ЛЛОВКМодуль_СоздайИзПамяти(const void* mem, size_t length);
LLEXPORT lto_module_t ЛЛОВКМодуль_СоздайИзПамятиСПутём(const void* mem,
                                                     size_t length,
                                                     const char *path) ;
LLEXPORT lto_module_t ЛЛОВКМодуль_СоздайВЛокКонтексте(const void *mem, size_t length,
                                                const char *path);
LLEXPORT lto_module_t ЛЛОВКМодуль_СоздайВКонтекстеКодГена(const void *mem,
                                                  size_t length,
                                                  const char *path,
                                                  lto_code_gen_t cg);
LLEXPORT void ЛЛОВКМодуль_Вымести(lto_module_t mod);
LLEXPORT const char* ЛЛОВКМодуль_ДайТриадуЦели(lto_module_t mod) ;
LLEXPORT void ЛЛОВКМодуль_УстТриадуЦели(lto_module_t mod, const char *triple) ;
LLEXPORT unsigned int ЛЛОВКМодуль_ДайЧлоСимволов(lto_module_t mod);
LLEXPORT const char* ЛЛОВКМодуль_ДайИмяСимвола(lto_module_t mod, unsigned int index);
LLEXPORT lto_symbol_attributes ЛЛОВКМодуль_ДайАтрибутыСимвола(lto_module_t mod,
                                                      unsigned int index) ;
LLEXPORT const char* ЛЛОВКМодуль_ДайОпцииКомпоновщика(lto_module_t mod);
LLEXPORT void ЛЛОВККодГен_УстОбработчикДиагностики(lto_code_gen_t cg,
                                        lto_diagnostic_handler_t diag_handler,
                                        void *ctxt);
LLEXPORT lto_code_gen_t ЛЛОВККодГен_Создай(void) ;
LLEXPORT lto_code_gen_t ЛЛОВККодГен_СоздайВЛокКонтексте(void);
LLEXPORT void ЛЛОВККодГен_Вымести(lto_code_gen_t cg);
LLEXPORT bool ЛЛОВККодГен_ДобавьМодуль(lto_code_gen_t cg, lto_module_t mod) ;
LLEXPORT void ЛЛОВККодГен_УстМодуль(lto_code_gen_t cg, lto_module_t mod);
LLEXPORT bool ЛЛОВККодГен_УстМодельОтладки(lto_code_gen_t cg, lto_debug_model debug);

LLEXPORT bool ЛЛОВККодГен_УстМодельПИК(lto_code_gen_t cg, lto_codegen_model model) ;
LLEXPORT void ЛЛОВККодГен_УстЦПБ(lto_code_gen_t cg, const char *cpu);
LLEXPORT void ЛЛОВККодГен_УстАсмПуть(lto_code_gen_t cg, const char *path) ;
LLEXPORT void ЛЛОВККодГен_УстАсмАрги(lto_code_gen_t cg, const char **args,
                                    int nargs) ;
LLEXPORT void ЛЛОВККодГен_ДобавьСимволМастПрезерв(lto_code_gen_t cg,
                                          const char *symbol) ;
static void maybeParseOptions(lto_code_gen_t cg) ;
LLEXPORT bool ЛЛОВККодГен_ПишиСлитноМодуль(lto_code_gen_t cg, const char *path);
LLEXPORT const void *ЛЛОВККодГен_Компилируй(lto_code_gen_t cg, size_t *length);
LLEXPORT bool ЛЛОВККодГен_Оптимизируй(lto_code_gen_t cg);
LLEXPORT const void *ЛЛОВККодГен_КомпилируйОптимиз(lto_code_gen_t cg, 
  size_t *length) ;
LLEXPORT bool ЛЛОВККодГен_КомпилируйВФайл(lto_code_gen_t cg, const char **name) ;
LLEXPORT void ЛЛОВККодГен_ОпцииОтладки(lto_code_gen_t cg, const char *opt);
LLEXPORT unsigned int ЛЛОВКАПИВерсия();
LLEXPORT void ЛЛОВККодГен_УстСледуетИнтернализовать(lto_code_gen_t cg,
                                        bool ShouldInternalize);
LLEXPORT void ЛЛОВККодГен_УстСледуетВнедритьСписокИспользований(lto_code_gen_t cg,
                                           lto_bool_t ShouldEmbedUselists);

// ThinLTO API below

LLEXPORT thinlto_code_gen_t ЛЛОВК2_СоздайКодГен(void) ;

LLEXPORT void ЛЛОВК2_ВыместиКодГен(thinlto_code_gen_t cg);
LLEXPORT void ЛЛОВК2_ДобавьМодуль(thinlto_code_gen_t cg, const char *Identifier,
                                const char *Data, int Length);
LLEXPORT void ЛЛОВК2КодГен_Обработай(thinlto_code_gen_t cg) ;
LLEXPORT unsigned int ЛЛОВК2Модуль_ДайЧлоОбъектов(thinlto_code_gen_t cg) ;
LTOObjectBuffer ЛЛОВК2Модуль_ДайОбъект(thinlto_code_gen_t cg,
                                          unsigned int index);
LLEXPORT unsigned int ЛЛОВК2Модуль_ДайЧлоОбъектФайлов(thinlto_code_gen_t cg);
LLEXPORT const char *ЛЛОВК2Модуль_ДайОбъектФайл(thinlto_code_gen_t cg,
                                           unsigned int index);
LLEXPORT void ЛЛОВК2КодГен_ОтключиКодГен(thinlto_code_gen_t cg,
                                     lto_bool_t disable) ;
LLEXPORT void ЛЛОВК2КодГен_УстТолькоКодГен(thinlto_code_gen_t cg,
                                      lto_bool_t CodeGenOnly);
LLEXPORT void ЛЛОВК2_ОпцииОтладки(const char *const *options, int number);
LLEXPORT lto_bool_t ЛЛОВКМодуль_ОВК2_ли(lto_module_t mod);
LLEXPORT void ЛЛОВК2КодГен_ДобавьСимволМастПрезерв(thinlto_code_gen_t cg,
                                              const char *Name, int Length) ;
LLEXPORT void ЛЛОВК2КодГен_ДобавьКроссРефСимвол(thinlto_code_gen_t cg,
                                                 const char *Name, int Length) ;
LLEXPORT void ЛЛОВК2КодГен_УстЦПБ(thinlto_code_gen_t cg, const char *cpu) ;
LLEXPORT void ЛЛОВК2КодГен_УстПапкуКэша(thinlto_code_gen_t cg,
                                   const char *cache_dir) ;
LLEXPORT void ЛЛОВК2КодГен_УстИнтервалПрюнингаКэша(thinlto_code_gen_t cg,
                                                int interval) ;
LLEXPORT void ЛЛОВК2КодГен_УстЭкспирациюЗаписиКэша(thinlto_code_gen_t cg,
                                                unsigned expiration);
LLEXPORT void ЛЛОВК2КодГен_УстФинальнРазКэшаОтносительноДоступнПрострву(
    thinlto_code_gen_t cg, unsigned Percentage) ;
LLEXPORT void ЛЛОВК2КодГен_УстРазмКэшаВБайтах( thinlto_code_gen_t cg, unsigned MaxSizeBytes);
LLEXPORT void ЛЛОВК2КодГен_УстРазмКэшаВМегаБайтах( thinlto_code_gen_t cg, unsigned MaxSizeMegabytes) ;
LLEXPORT void ЛЛОВК2КодГен_УстРазмКэшаВФайлах( thinlto_code_gen_t cg, unsigned MaxSizeFiles) ;
LLEXPORT void ЛЛОВК2КодГен_УстПапкуВремХран(thinlto_code_gen_t cg,
                                       const char *save_temps_dir) ;
LLEXPORT void ЛЛОВК2КодГен_УстПапкуСгенОбъектов(thinlto_code_gen_t cg,
                                       const char *save_temps_dir);
LLEXPORT lto_bool_t ЛЛОВК2КодГен_УстМодельПИК(thinlto_code_gen_t cg,
                                         lto_codegen_model model) ;
LLEXPORT lto_input_t ЛЛОВКВвод_Создай(const void *buffer, size_t buffer_size, const char *path) ;
LLEXPORT void ЛЛОВКВвод_Вымести(lto_input_t input) ;
LLEXPORT  unsigned ЛЛОВКВвод_ДайЧлоЗависимыхБиб(lto_input_t input);
LLEXPORT  const char *ЛЛОВКВвод_ДайЗависимБиб(lto_input_t input,
                                                   size_t index,
                                                   size_t *size) ;
}