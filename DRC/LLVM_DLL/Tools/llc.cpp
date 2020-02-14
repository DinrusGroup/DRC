//===-- llc.cpp - Implement the LLVM Native Code Generator ----------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This is the llc code generator driver. It provides a convenient
// command-line interface for generating native assembly-language code
// or C code, given LLVM bitcode.
//
//===----------------------------------------------------------------------===//

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/Triple.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/CodeGen/CommandFlags.inc"
#include "llvm/CodeGen/LinkAllAsmWriterComponents.h"
#include "llvm/CodeGen/LinkAllCodegenComponents.h"
#include "llvm/CodeGen/MIRParser/MIRParser.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/IR/AutoUpgrade.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/DiagnosticPrinter.h"
#include "llvm/IR/IRPrintingPasses.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/RemarkStreamer.h"
#include "llvm/IR/Verifier.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/MC/SubtargetFeature.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/Host.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/ManagedStatic.h"
#include "llvm/Support/PluginLoader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/ToolOutputFile.h"
#include "llvm/Support/WithColor.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include <memory>
#include <cstring> 

using namespace llvm;
	
struct LLCDiagnosticHandler : public DiagnosticHandler {
        bool* HasError;
        LLCDiagnosticHandler(bool* HasErrorPtr) : HasError(HasErrorPtr) {}
        bool handleDiagnostics(const DiagnosticInfo& DI) override {
            if (DI.getSeverity() == DS_Error)
                *HasError = true;

            if (auto* Remark = dyn_cast<DiagnosticInfoOptimizationBase>(&DI))
                if (!Remark->isEnabled())
                    return true;

            DiagnosticPrinterRawOStream DP(errs());
            errs() << LLVMContext::getDiagnosticMessagePrefix(DI.getSeverity()) << ": ";
            DI.print(DP);
            errs() << "\n";
            return true;
        }
    };

 void InlineAsmDiagHandler(const SMDiagnostic& SMD, void* Context,
        unsigned LocCookie) {
        bool* HasError = static_cast<bool*>(Context);
        if (SMD.getKind() == SourceMgr::DK_Error)
            *HasError = true;

        SMD.print(nullptr, errs());

        // For testing purposes, we print the LocCookie here.
        if (LocCookie)
            WithColor::note() << "!srcloc = " << LocCookie << "\n";
    }

 bool addPass(PassManagerBase& PM, const char* argv0,
        StringRef PassName, TargetPassConfig& TPC) {
        if (PassName == "none")
            return false;

        const PassRegistry* PR = PassRegistry::getPassRegistry();
        const PassInfo* PI = PR->getPassInfo(PassName);
        if (!PI) {
            WithColor::error(errs(), argv0)
                << "run-pass " << PassName << " не зарегистрирован.\n";
            return true;
        }

        Pass* P;
        if (PI->getNormalCtor())
            P = PI->getNormalCtor()();
        else {
            WithColor::error(errs(), argv0)
                << "нельзя создать проходку: " << PI->getPassName() << "\n";
            return true;
        }
        std::string Banner = std::string("После ") + std::string(P->getPassName());
        PM.add(P);
        TPC.printAndVerify(Banner);

        return false;
    }
 
extern "C" __declspec(dllexport) int ЛЛВхоФункцЛЛКомпилятора(char** args) {

   auto argn =(int) strlen((const char*)args);
    InitLLVM X(argn, args);
//////////////////////////////////////////////////////////
		
static	 ManagedStatic<std::vector<std::string>> RunPassNames;

        struct RunPassOption {
            void operator=(const std::string& Val) const {
                if (Val.empty())
                    return;
                SmallVector<StringRef, 8> PassNames;
                StringRef(Val).split(PassNames, ',', -1, false);
                for (auto PassName : PassNames)
                    RunPassNames->push_back(PassName);
            }
        };
    
 static  RunPassOption RunPassOpt;
		//////////////////////////////////////////
	 cl::opt<std::string>
        InputFilename(cl::Positional, cl::desc("<input bitcode>"), cl::init("-"));

     cl::opt<std::string>
        InputLanguage("x", cl::desc("Язык ввода ('ir' или 'mir')"));

     cl::opt<std::string>
        OutputFilename("obj", cl::desc("Выходной файл"), cl::value_desc("filename"));

     cl::opt<std::string>
        SplitDwarfOutputFile("split-dwarf-output",
            cl::desc("Выходной файл.dwo "),
            cl::value_desc("filename"));

     cl::opt<unsigned>
        TimeCompilations("time-compilations", cl::Hidden, cl::init(1u),
            cl::value_desc("N"),
            cl::desc("Повторить компиляцию N раз для тайминга"));

     cl::opt<bool>
        NoIntegratedAssembler("no-integrated-as", cl::Hidden,
            cl::desc("Отключить интергрированный ассемблер"));

     cl::opt<bool>
        PreserveComments("preserve-as-comments", cl::Hidden,
            cl::desc("Сохранить комментарии в итоговой сборке"),
            cl::init(true));

    // Determine optimization level.
     cl::opt<char>
        OptLevel("O",
            cl::desc("Уровень оптимизации. [-O0, -O1, -O2, or -O3] "
                "(Дефолт = '-O2')"),
            cl::Prefix,
            cl::ZeroOrMore,
            cl::init(' '));

     cl::opt<std::string>
        TargetTriple("mtriple", cl::desc("Переписать целевую триаду для модуля"));

     cl::opt<std::string> SplitDwarfFile(
        "split-dwarf-file",
        cl::desc(
            "Укажите имя файла .dwo для кодирования вывода в DWARF"));

     cl::opt<bool> NoVerify("disable-verify", cl::Hidden,
        cl::desc("Не проверять модуль на вводе"));

     cl::opt<bool> DisableSimplifyLibCalls("disable-simplify-libcalls",
        cl::desc("Отключить упрощение вызова библиотек"));

     cl::opt<bool> ShowMCEncoding("show-mc-encoding", cl::Hidden,
        cl::desc("Показать кодировку в выводе .s"));

     cl::opt<bool> EnableDwarfDirectory(
        "enable-dwarf-directory", cl::Hidden,
        cl::desc("Использовать директиву .file с явной папкой."));

     cl::opt<bool> AsmVerbose("asm-verbose",
        cl::desc("Все комментарии к директивам."),
        cl::init(true));

     cl::opt<bool>
        CompileTwice("compile-twice", cl::Hidden,
            cl::desc("Пройтись дважды, используя один и тот же менеджер "
                "проходок и проверить резаультаты на равность."),
            cl::init(false));

     cl::opt<bool> DiscardValueNames(
        "discard-value-names",
        cl::desc("Удалить имена из значения (если оно не глобальное)."),
        cl::init(false), cl::Hidden);

     cl::list<std::string> IncludeDirs("I", cl::desc("Включить путь поиска"));

     cl::opt<bool> RemarksWithHotness(
        "pass-remarks-with-hotness",
        cl::desc("При PGO, включить профайл-счёт в оптимизационных ремарках"),
        cl::Hidden);

     cl::opt<unsigned>
        RemarksHotnessThreshold("pass-remarks-hotness-threshold",
            cl::desc("Минимальный профайл-счёт, требуемый для "
                "выведения оптимизационной ремарки"),
            cl::Hidden);

     cl::opt<std::string>
        RemarksFilename("pass-remarks-output",
            cl::desc("Выводной файл для ремарок проходки"),
            cl::value_desc("filename"));

     cl::opt<std::string>
        RemarksPasses("pass-remarks-filter",
            cl::desc("Только ремарки оптимизации записи из проходок с "
                "именами, соответствующими данному регулярному выражению"),
            cl::value_desc("regex"));

     cl::opt<std::string> RemarksFormat(
        "pass-remarks-format",
        cl::desc("Формат, используемый для сериализационных ремарок (дефолт: YAML)"),
        cl::value_desc("format"), cl::init("yaml"));
		
	 cl::opt<RunPassOption, true, cl::parser<std::string>> RunPass(
        "run-pass",
        cl::desc("Запустить компилятор только для указанных проходок(список через запятую)"),
        cl::value_desc("pass-name"), cl::ZeroOrMore, cl::location(RunPassOpt));
//////////////////////////////////////////////////////////////////////////////
     
        // Enable debug stream buffering.
        EnableDebugBuffering = true;

        LLVMContext Context;

        // Initialize targets first, so that --version shows registered targets.
        InitializeAllTargets();
        InitializeAllTargetMCs();
        InitializeAllAsmPrinters();
        InitializeAllAsmParsers();

        // Initialize codegen and IR passes used by llc so that the -print-after,
        // -print-before, and -stop-after options work.
        PassRegistry* Registry = PassRegistry::getPassRegistry();
        initializeCore(*Registry);
        initializeCodeGen(*Registry);
        initializeLoopStrengthReducePass(*Registry);
        initializeLowerIntrinsicsPass(*Registry);
        initializeEntryExitInstrumenterPass(*Registry);
        initializePostInlineEntryExitInstrumenterPass(*Registry);
        initializeUnreachableBlockElimLegacyPassPass(*Registry);
        initializeConstantHoistingLegacyPassPass(*Registry);
        initializeScalarOpts(*Registry);
        initializeVectorization(*Registry);
        initializeScalarizeMaskedMemIntrinPass(*Registry);
        initializeExpandReductionsPass(*Registry);
        initializeHardwareLoopsPass(*Registry);

        // Initialize debugging passes.
        initializeScavengerTestPass(*Registry);

        // Register the target printer for --version.
        cl::AddExtraVersionPrinter(TargetRegistry::printRegisteredTargetsForVersion);
        cl::ParseCommandLineOptions(argn, args, "Компилятор Системы LLVM \n");
        Context.setDiscardValueNames(DiscardValueNames);

        // Set a diagnostic handler that doesn't exit on the first error
        bool HasError = false;
        Context.setDiagnosticHandler(
            llvm::make_unique<LLCDiagnosticHandler>(&HasError));
        Context.setInlineAsmDiagnosticHandler(InlineAsmDiagHandler, &HasError);

        Expected<std::unique_ptr<ToolOutputFile>> RemarksFileOrErr =
            setupOptimizationRemarks(Context, RemarksFilename, RemarksPasses,
                RemarksFormat, RemarksWithHotness,
                RemarksHotnessThreshold);
        if (Error E = RemarksFileOrErr.takeError()) {
            WithColor::error(errs(), args[0]) << toString(std::move(E)) << '\n';
            return 1;
        }
        std::unique_ptr<ToolOutputFile> RemarksFile = std::move(*RemarksFileOrErr);

        if (InputLanguage != "" && InputLanguage != "ir" &&
            InputLanguage != "mir") {
            WithColor::error(errs(), args[0])
                << "языком ввода должен быть '', 'IR' или 'MIR'\n";
            return 1;
        }

        // Compile the module TimeCompilations times to give better compile time
        // metrics.
        for (unsigned I = TimeCompilations; I; --I)
		{
	    // Load the module to be compiled...
        SMDiagnostic Err;
        std::unique_ptr<Module> M;
        std::unique_ptr<MIRParser> MIR;
        Triple TheTriple;

        bool SkipModule = MCPU == "help" ||
            (!MAttrs.empty() && MAttrs.front() == "help");

        // If user just wants to list available options, skip module loading
        if (!SkipModule) {
            if (InputLanguage == "mir" ||
                (InputLanguage == "" && StringRef(InputFilename).endswith(".mir"))) {
                MIR = createMIRParserFromFile(InputFilename, Err, Context);
                if (MIR)
                    M = MIR->parseIRModule();
            }
            else
                M = parseIRFile(InputFilename, Err, Context, false);
            if (!M) {
                Err.print(args[0], WithColor::error(errs(), args[0]));
                return 1;
            }

            // If we are supposed to override the target triple, do so now.
            if (!TargetTriple.empty())
                M->setTargetTriple(Triple::normalize(TargetTriple));
            TheTriple = Triple(M->getTargetTriple());
        }
        else {
            TheTriple = Triple(Triple::normalize(TargetTriple));
        }

        if (TheTriple.getTriple().empty())
            TheTriple.setTriple(sys::getDefaultTargetTriple());

        // Get the target specific parser.
        std::string Error;
        const Target* TheTarget = TargetRegistry::lookupTarget(MArch, TheTriple,
            Error);
        if (!TheTarget) {
            WithColor::error(errs(), args[0]) << Error;
            return 1;
        }

        std::string CPUStr = getCPUStr(), FeaturesStr = getFeaturesStr();

        CodeGenOpt::Level OLvl = CodeGenOpt::Default;
        switch (OptLevel) {
        default:
            WithColor::error(errs(), args[0]) << "неверный уровень оптимизации.\n";
            return 1;
        case ' ': break;
        case '0': OLvl = CodeGenOpt::None; break;
        case '1': OLvl = CodeGenOpt::Less; break;
        case '2': OLvl = CodeGenOpt::Default; break;
        case '3': OLvl = CodeGenOpt::Aggressive; break;
        }

        TargetOptions Options = InitTargetOptionsFromCodeGenFlags();
        Options.DisableIntegratedAS = NoIntegratedAssembler;
        Options.MCOptions.ShowMCEncoding = ShowMCEncoding;
        Options.MCOptions.MCUseDwarfDirectory = EnableDwarfDirectory;
        Options.MCOptions.AsmVerbose = AsmVerbose;
        Options.MCOptions.PreserveAsmComments = PreserveComments;
        Options.MCOptions.IASSearchPaths = IncludeDirs;
        Options.MCOptions.SplitDwarfFile = SplitDwarfFile;

        std::unique_ptr<TargetMachine> Target(TheTarget->createTargetMachine(
            TheTriple.getTriple(), CPUStr, FeaturesStr, Options, getRelocModel(),
            getCodeModel(), OLvl));

        assert(Target && "Не удаётся разместить целевую машину!");

        // If we don't have a module then just exit now. We do this down
        // here since the CPU/Feature help is underneath the target machine
        // creation.
        if (SkipModule)
            return 0;

        assert(M && "Должно было прерваться, если модуль отсутствует!");
        if (FloatABIForCalls != FloatABI::Default)
            Options.FloatABIType = FloatABIForCalls;

        // Figure out where we are going to send the output.
		/////////////////////////////////////////////////////////
		const char* TargetName = TheTarget->getName();
        Triple::OSType OS = TheTriple.getOS();
 
		std::unique_ptr<ToolOutputFile> Out;
		
        if (OutputFilename.empty()) {
            if (InputFilename == "-")
                OutputFilename = "-";
            else {
                // If InputFilename ends in .bc or .ll, remove it.
                StringRef IFN = InputFilename;
                if (IFN.endswith(".bc") || IFN.endswith(".ll"))
                    OutputFilename = IFN.drop_back(3);
                else if (IFN.endswith(".mir"))
                    OutputFilename = IFN.drop_back(4);
                else
                    OutputFilename = IFN;

                switch (FileType) {
                case TargetMachine::CGFT_AssemblyFile:
                    if (TargetName[0] == 'c') {
                        if (TargetName[1] == 0)
                            OutputFilename += ".cbe.c";
                        else if (TargetName[1] == 'p' && TargetName[2] == 'p')
                            OutputFilename += ".cpp";
                        else
                            OutputFilename += ".s";
                    }
                    else
                        OutputFilename += ".s";
                    break;
                case TargetMachine::CGFT_ObjectFile:
                    if (OS == Triple::Win32)
                        OutputFilename += ".obj";
                    else
                        OutputFilename += ".o";
                    break;
                case TargetMachine::CGFT_Null:
                    OutputFilename += ".null";
                    break;
                }
            }
        }

        // Decide if we need "binary" output.
        bool Binary = false;
        switch (FileType) {
        case TargetMachine::CGFT_AssemblyFile:
            break;
        case TargetMachine::CGFT_ObjectFile:
        case TargetMachine::CGFT_Null:
            Binary = true;
            break;
        }

        // Open the file.
        std::error_code EC;
        sys::fs::OpenFlags OpenFlags = sys::fs::F_None;
        if (!Binary)
            OpenFlags |= sys::fs::F_Text;
        Out = llvm::make_unique<ToolOutputFile>(OutputFilename, EC, OpenFlags);
        if (EC) {
            WithColor::error() << EC.message() << '\n';
            Out =  nullptr;
        }
        if (!Out) return 1;

        std::unique_ptr<ToolOutputFile> DwoOut;
        if (!SplitDwarfOutputFile.empty()) {
            std::error_code EC;
            DwoOut = llvm::make_unique<ToolOutputFile>(SplitDwarfOutputFile, EC,
                sys::fs::F_None);
            if (EC) {
                WithColor::error(errs(), args[0]) << EC.message() << '\n';
                return 1;
            }
        }

        // Build up all of the passes that we want to do to the module.
        legacy::PassManager PM;

        // Add an appropriate TargetLibraryInfo pass for the module's triple.
        TargetLibraryInfoImpl TLII(Triple(M->getTargetTriple()));

        // The -disable-simplify-libcalls flag actually disables all builtin optzns.
        if (DisableSimplifyLibCalls)
            TLII.disableAllFunctions();
        PM.add(new TargetLibraryInfoWrapperPass(TLII));

        // Add the target data from the target machine, if it exists, or the module.
        M->setDataLayout(Target->createDataLayout());

        // This needs to be done after setting datalayout since it calls verifier
        // to check debug info whereas verifier relies on correct datalayout.
        UpgradeDebugInfo(*M);

        // Verify module immediately to catch problems before doInitialization() is
        // called on any passes.
        if (!NoVerify && verifyModule(*M, &errs())) {
            std::string Prefix =
                (Twine(args[0]) + Twine(": ") + Twine(InputFilename)).str();
            WithColor::error(errs(), Prefix) << "входной модуль неконсистентен!\n";
            return 1;
        }

        // Override function attributes based on CPUStr, FeaturesStr, and command line
        // flags.
        setFunctionAttributes(CPUStr, FeaturesStr, *M);

        if (RelaxAll.getNumOccurrences() > 0 &&
            FileType != TargetMachine::CGFT_ObjectFile)
            WithColor::warning(errs(), args[0])
            << ": предупреждение: игнорируется -mc-llvm::wrap-all, так как тип файла != obj";

        {
            raw_pwrite_stream* OS = &Out->os();

            // Manually do the buffering rather than using buffer_ostream,
            // so we can memcmp the contents in CompileTwice mode
            SmallVector<char, 0> Buffer;
            std::unique_ptr<raw_svector_ostream> BOS;
            if ((FileType != TargetMachine::CGFT_AssemblyFile &&
                !Out->os().supportsSeeking()) ||
                CompileTwice) {
                BOS = make_unique<raw_svector_ostream>(Buffer);
                OS = BOS.get();
            }

            const char* argv0 = args[0];
            LLVMTargetMachine& LLVMTM = static_cast<LLVMTargetMachine&>(*Target);
            MachineModuleInfo* MMI = new MachineModuleInfo(&LLVMTM);

            // Construct a custom pass pipeline that starts after instruction
            // selection.
            if (!RunPassNames->empty()) {
                if (!MIR) {
                    WithColor::warning(errs(), args[0])
                        << "run-pass только для файла .mir.\n";
                    return 1;
                }
                TargetPassConfig& TPC = *LLVMTM.createPassConfig(PM);
                if (TPC.hasLimitedCodeGenPipeline()) {
                    WithColor::warning(errs(), args[0])
                        << "run-pass нельзя использовать с "
                        << TPC.getLimitedCodeGenPipelineReason(" and ") << ".\n";
                    return 1;
                }

                TPC.setDisableVerify(NoVerify);
                PM.add(&TPC);
                PM.add(MMI);
                TPC.printAndVerify("");
                for (const std::string& RunPassName : *RunPassNames) {
                    if (addPass(PM, argv0, RunPassName, TPC))
                        return 1;
                }
                TPC.setInitialized();
                PM.add(createPrintMIRPass(*OS));
                PM.add(createFreeMachineFunctionPass());
            }
            else if (Target->addPassesToEmitFile(PM, *OS,
                DwoOut ? &DwoOut->os() : nullptr,
                FileType, NoVerify, MMI)) {
                WithColor::warning(errs(), args[0])
                    << "цель не поддерживает генерацию этого"
                    << " типа файла!\n";
                return 1;
            }

            if (MIR) {
                assert(MMI && "Забыли создать MMI?");
                if (MIR->parseMachineFunctions(*M, *MMI))
                    return 1;
            }

            // Before executing passes, print the final values of the LLVM options.
            cl::PrintOptionValues();

            // If requested, run the pass manager over the same module again,
            // to catch any bugs due to persistent state in the passes. Note that
            // opt has the same functionality, so it may be worth abstracting this out
            // in the future.
            SmallVector<char, 0> CompileTwiceBuffer;
            if (CompileTwice) {
                std::unique_ptr<Module> M2(llvm::CloneModule(*M));
                PM.run(*M2);
                CompileTwiceBuffer = Buffer;
                Buffer.clear();
            }

            PM.run(*M);

            auto HasError =
                ((const LLCDiagnosticHandler*)(Context.getDiagHandlerPtr()))->HasError;
            if (*HasError)
                return 1;

            // Compare the two outputs and make sure they're the same
            if (CompileTwice) {
                if (Buffer.size() != CompileTwiceBuffer.size() ||
                    (memcmp(Buffer.data(), CompileTwiceBuffer.data(), Buffer.size()) !=
                        0)) {
                    errs()
                        << "Двойной запуск менеджера проходок изменил вывод.\n"
                        "Результат второй проходки записан на указанный вывод.\n"
                        "Чтобы сгенерировать однопроходный бинарник сравнения, запустите без\n"
                        "опции compile-twice\n";
                    Out->os() << Buffer;
                    Out->keep();
                    return 1;
                }
            }

            if (BOS) {
                Out->os() << Buffer;
            }
        }

        // Declare success.
        Out->keep();
        if (DwoOut)
            DwoOut->keep();

        return 0;	
		}


        if (RemarksFile)
            RemarksFile->keep();
        return 0;
    }
    
