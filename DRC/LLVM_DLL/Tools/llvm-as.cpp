//===--- llvm-as.cpp - The low-level LLVM assembler -----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
//  This utility may be invoked in the following manner:
//   llvm-as --help         - Output information about command line switches
//   llvm-as [options]      - Read LLVM asm from stdin, write bitcode to stdout
//   llvm-as [options] x.ll - Read LLVM asm from the x.ll file, write bitcode
//                            to the x.bc file.
//
//===----------------------------------------------------------------------===//

#include "llvm/AsmParser/Parser.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ModuleSummaryIndex.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/ManagedStatic.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/SystemUtils.h"
#include "llvm/Support/ToolOutputFile.h"
#include <memory>
using namespace llvm;

cl::OptionCategory AsCat("Опции llvm-as");

static cl::opt<std::string> InputFilename(cl::Positional,
                                          cl::desc("<входные файлы .llvm>"),
                                          cl::init("-"));

static cl::opt<std::string> OutputFilename("o",
                                           cl::desc("Переписать выходное имяф"),
                                           cl::value_desc("filename"),
                                           cl::cat(AsCat));

static cl::opt<bool> Force("f", cl::desc("Активировать бинарный вывод на терминалы"),
                           cl::cat(AsCat));

static cl::opt<bool> DisableOutput("disable-output", cl::desc("Отключит вывод"),
                                   cl::init(false), cl::cat(AsCat));

static cl::opt<bool> EmitModuleHash("module-hash", cl::desc("Генерировать хэш модуля"),
                                    cl::init(false), cl::cat(AsCat));

static cl::opt<bool> DumpAsm("d", cl::desc("Вывести сборку после разбора"),
                             cl::Hidden, cl::cat(AsCat));

static cl::opt<bool>
    DisableVerify("disable-verify", cl::Hidden,
                  cl::desc("Не запускайте верификатор на вводном LLVM (опасно!)"),
                  cl::cat(AsCat));

static cl::opt<bool> PreserveBitcodeUseListOrder(
    "preserve-bc-uselistorder",
    cl::desc("Сохранять порядок use-list при записи биткода LLVM."),
    cl::init(true), cl::Hidden, cl::cat(AsCat));

static cl::opt<std::string> ClDataLayout("data-layout",
                                         cl::desc("строка используемой раскладки данных"),
                                         cl::value_desc("layout-string"),
                                         cl::init(""), cl::cat(AsCat));

static void WriteOutputFile(const Module *M, const ModuleSummaryIndex *Index) {
  // Infer the output filename if needed.
  if (OutputFilename.empty()) {
    if (InputFilename == "-") {
      OutputFilename = "-";
    } else {
      StringRef IFN = InputFilename;
      OutputFilename = (IFN.endswith(".ll") ? IFN.drop_back(3) : IFN).str();
      OutputFilename += ".bc";
    }
  }

  std::error_code EC;
  std::unique_ptr<ToolOutputFile> Out(
      new ToolOutputFile(OutputFilename, EC, sys::fs::F_None));
  if (EC) {
    errs() << EC.message() << '\n';
    exit(1);
  }

  if (Force || !CheckBitcodeOutputToConsole(Out->os(), true)) {
    const ModuleSummaryIndex *IndexToWrite = nullptr;
    // Don't attempt to write a summary index unless it contains any entries.
    // Otherwise we get an empty summary section.
    if (Index && Index->begin() != Index->end())
      IndexToWrite = Index;
    if (!IndexToWrite || (M && (!M->empty() || !M->global_empty())))
      // If we have a non-empty Module, then we write the Module plus
      // any non-null Index along with it as a per-module Index.
      // If both are empty, this will give an empty module block, which is
      // the expected behavior.
      WriteBitcodeToFile(*M, Out->os(), PreserveBitcodeUseListOrder,
                         IndexToWrite, EmitModuleHash);
    else
      // Otherwise, with an empty Module but non-empty Index, we write a
      // combined index.
      WriteIndexToFile(*IndexToWrite, Out->os());
  }

  // Declare success.
  Out->keep();
}

extern "C" __declspec(dllexport) int ЛЛВхоФункцАс(int argc, char **argv) {
  InitLLVM X(argc, argv);
  LLVMContext Context;
  cl::HideUnrelatedOptions(AsCat);
  cl::ParseCommandLineOptions(argc, argv, "llvm .ll -> .bc ассемблер\n");

  // Parse the file now...
  SMDiagnostic Err;
  auto ModuleAndIndex = parseAssemblyFileWithIndex(
      InputFilename, Err, Context, nullptr, !DisableVerify, ClDataLayout);
  std::unique_ptr<Module> M = std::move(ModuleAndIndex.Mod);
  if (!M.get()) {
    Err.print(argv[0], errs());
    return 1;
  }
  std::unique_ptr<ModuleSummaryIndex> Index = std::move(ModuleAndIndex.Index);

  if (!DisableVerify) {
    std::string ErrorStr;
    raw_string_ostream OS(ErrorStr);
    if (verifyModule(*M.get(), &OS)) {
      errs() << argv[0]
             << ": сборка разобрана, но не верифицирована как точная!\n";
      errs() << OS.str();
      return 1;
    }
    // TODO: Implement and call summary index verifier.
  }

  if (DumpAsm) {
    errs() << "Вот ассемблер:\n" << *M.get();
    if (Index.get() && Index->begin() != Index->end())
      Index->print(errs());
  }

  if (!DisableOutput)
    WriteOutputFile(M.get(), Index.get());

  return 0;
}
