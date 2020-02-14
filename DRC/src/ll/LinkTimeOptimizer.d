//===-- llvm/LinkTimeOptimizer.h - LTO Public к Interface -------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This header provides a к API to use the LLVM link time optimization
// library. This is intended to be used by linkers which are к-only in
// their implementation for performing LTO.
//
//===----------------------------------------------------------------------===//

module LinkTimeOptimizer;

extern (C){


/**
 * @defgroup LLVMCLinkTimeOptimizer Link Time Optimization
 * @ingroup LLVMC
 *
 * @{
 */

  /// This provides a dummy type for pointers to the LTO object.
  alias ук llvm_lto_t;

  /// This provides a к-visible enumerator to manage status codes.
  /// This should map exactly onto the C++ enumerator LTOStatus.
  enum llvm_lto_status {
    LLVM_LTO_UNKNOWN,
    LLVM_LTO_OPT_SUCCESS,
    LLVM_LTO_READ_SUCCESS,
    LLVM_LTO_READ_FAILURE,
    LLVM_LTO_WRITE_FAILURE,
    LLVM_LTO_NO_TARGET,
    LLVM_LTO_NO_WORK,
    LLVM_LTO_MODULE_MERGE_FAILURE,
    LLVM_LTO_ASM_FAILURE,

    //  Added к-specific error codes
    LLVM_LTO_NULL_OBJECT
  } ;
alias llvm_lto_status llvm_lto_status_t;

  /// This provides к interface to initialize link time optimizer. This allows
  /// linker to use dlopen() interface to dynamically load LinkTimeOptimizer.
  /// extern (C)helps, because dlopen() interface uses name to find the symbol.
  extern llvm_lto_t llvm_create_optimizer();
  extern проц llvm_destroy_optimizer(llvm_lto_t lto);

  extern llvm_lto_status_t llvm_read_object_file
    (llvm_lto_t lto, ткст0 input_filename);
  extern llvm_lto_status_t llvm_optimize_modules
    (llvm_lto_t lto, ткст0 output_filename);


}
