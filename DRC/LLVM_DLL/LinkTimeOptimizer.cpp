
extern "C" {
#include "Header.h"

    /**
     * @defgroup LLVMCLinkTimeOptimizer Link Time Optimization
     * @ingroup LLVMC
     *
     * @{
     */

     /// This provides a dummy type for pointers to the LTO object.
    typedef void* т_лл_овк;


    /// This provides C interface to initialize link time optimizer. This allows
    /// linker to use dlopen() interface to dynamically load LinkTimeOptimizer.
    /// extern "C" helps, because dlopen() interface uses name to find the symbol.
    LLEXPORT т_лл_овк ЛЛСоздайОВК(void) { llvm_create_optimizer(); }
    LLEXPORT void ЛЛРазрушьОВК(т_лл_овк lto) { llvm_destroy_optimizer(lto); }

    LLEXPORT llvm_lto_status_t  ЛЛОВК_ЧитайОбъФайл(т_лл_овк lto, const char* input_filename) {
        llvm_read_object_file(lto, input_filename);
    }
    LLEXPORT llvm_lto_status_t ЛЛОВК_ОптимизируйМодуль(т_лл_овк lto, const char* output_filename) {
        return llvm_optimize_modules (lto,  output_filename); 
    }

/**
 * @}
 */


}
