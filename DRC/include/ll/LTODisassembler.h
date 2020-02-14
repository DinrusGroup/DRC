//===-- LTODisassembler.cpp - LTO Disassembler interface ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This function provides utility methods used by clients of libLTO that want
// to use the disassembler.
//
//===----------------------------------------------------------------------===//

#include "llvm-c/lto.h"
#include "llvm/Support/TargetSelect.h"
#include "Header.h"

using namespace llvm;

LLEXPORT void ЛЛОВК_ИницДизасм();
