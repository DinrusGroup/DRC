//===-lto.cpp - LLVM Link Time Optimizer ----------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the Link Time Optimization library. This library is
// intended to be used by linker to optimize code at link time.
//
//===----------------------------------------------------------------------===//

#include "llvm-c/lto.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Bitcode/BitcodeReader.h"
#include "llvm/CodeGen/CommandFlags.inc"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/DiagnosticPrinter.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/LTO/LTO.h"
#include "llvm/LTO/legacy/LTOCodeGenerator.h"
#include "llvm/LTO/legacy/LTOModule.h"
#include "llvm/LTO/legacy/ThinLTOCodeGenerator.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Signals.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/raw_ostream.h"

namespace ltocmd
{
	// extra command-line flags needed for LTOCodeGenerator
	static cl::opt<char>
	OptLevel("O",
			 cl::desc("Уровень оптимизации. [-O0, -O1, -O2 или -O3] "
					  "(дефолт = '-O2')"),
			 cl::Prefix,
			 cl::ZeroOrMore,
			 cl::init('2'));

	static cl::opt<bool>
	DisableInline("disable-inlining", cl::init(false),
	  cl::desc("Не выполнять проходку инлайнера"));

	static cl::opt<bool>
	DisableGVNLoadPRE("disable-gvn-loadpre", cl::init(false),
	  cl::desc("Не выполнять проходку GVN load PRE"));

	static cl::opt<bool> DisableLTOVectorization(
		"disable-lto-vectorization", cl::init(false),
		cl::desc("Не выполнять векторизацию цикла(loop) или slp во время LTO"));

	static cl::opt<bool> EnableFreestanding(
		"lto-freestanding", cl::init(false),
		cl::desc("Активировать Freestanding (выключить builtins / TLI) во время LTO"));

	#ifdef NDEBUG
	static bool VerifyByDefault = false;
	#else
	static bool VerifyByDefault = true;
	#endif

	static cl::opt<bool> DisableVerify(
		"disable-llvm-verifier", cl::init(!VerifyByDefault),
		cl::desc("Не выполнять верификатор LLVM при пайплайне оптимизации"));

	// Holds most recent error string.
	// *** Not thread safe ***
	static std::string sLastErrorString;

	// Holds the initialization state of the LTO module.
	// *** Not thread safe ***
	static bool initialized = false;

	// Holds the command-line option parsing state of the LTO module.
	static bool parsedOptions = false;

	static LLVMContext *LTOContext = nullptr;

	struct LTOToolDiagnosticHandler : public DiagnosticHandler {
	  bool handleDiagnostics(const DiagnosticInfo &DI) override {
		if (DI.getSeverity() != DS_Error) {
		  DiagnosticPrinterRawOStream DP(errs());
		  DI.print(DP);
		  errs() << '\n';
		  return true;
		}
		sLastErrorString = "";
		{
		  raw_string_ostream Stream(sLastErrorString);
		  DiagnosticPrinterRawOStream DP(Stream);
		  DI.print(DP);
		}
		return true;
	  }
	};

	// Initialize the configured targets if they have not been initialized.
	static void lto_initialize() {
	  if (!initialized) {
	#ifdef _WIN32
		// Dialog box on crash disabling doesn't work across DLL boundaries, so do
		// it here.
		llvm::sys::DisableSystemDialogsOnCrash();
	#endif

		InitializeAllTargetInfos();
		InitializeAllTargets();
		InitializeAllTargetMCs();
		InitializeAllAsmParsers();
		InitializeAllAsmPrinters();
		InitializeAllDisassemblers();

		static LLVMContext Context;
		ltocmd::LTOContext = &Context;
		ltocmd::LTOContext->setDiagnosticHandler(
			llvm::make_unique<ltocmd::LTOToolDiagnosticHandler>(), true);
		ltocmd::initialized = true;
	  }
	}

	namespace {

	    static void handleLibLTODiagnostic(lto_codegen_diagnostic_severity_t Severity,
									       const char *Msg, void *) {
		    sLastErrorString = Msg;
	    }

	    // This derived class owns the native object file. This helps implement the
	    // libLTO API semantics, which require that the code generator owns the object
	    // file.
	    struct LibLTOCodeGenerator : LTOCodeGenerator {
	      LibLTOCodeGenerator() : LTOCodeGenerator(*ltocmd::LTOContext) { init(); }
	      LibLTOCodeGenerator(std::unique_ptr<LLVMContext> Context)
		      : LTOCodeGenerator(*Context), OwnedContext(std::move(Context)) {
		    init();
	      }

	      // Reset the module first in case MergedModule is created in OwnedContext.
	      // Module must be destructed before its context gets destructed.
	      ~LibLTOCodeGenerator() { resetMergedModule(); }

	      void init() { setDiagnosticHandler(handleLibLTODiagnostic, nullptr); }

	      std::unique_ptr<MemoryBuffer> NativeObjectFile;
	      std::unique_ptr<LLVMContext> OwnedContext;
	    };

	}

	DEFINE_SIMPLE_CONVERSION_FUNCTIONS(LibLTOCodeGenerator, lto_code_gen_t)
	DEFINE_SIMPLE_CONVERSION_FUNCTIONS(ThinLTOCodeGenerator, thinlto_code_gen_t)
	DEFINE_SIMPLE_CONVERSION_FUNCTIONS(LTOModule, lto_module_t)

	// Convert the subtarget features into a string to pass to LTOCodeGenerator.
	static void lto_add_attrs(lto_code_gen_t cg) {
	  LTOCodeGenerator *CG = unwrap(cg);
	  if (MAttrs.size()) {
		std::string attrs;
		for (unsigned i = 0; i < MAttrs.size(); ++i) {
		  if (i > 0)
			attrs.append(",");
		  attrs.append(MAttrs[i]);
		}

		CG->setAttr(attrs);
	  }

	  if (ltocmd::OptLevel < '0' || ltocmd::OptLevel > '3')
		report_fatal_error("Уровень оптимизации должен быть между 0 и 3");
	  CG->setOptLevel(ltocmd::OptLevel - '0');
	  CG->setFreestanding(ltocmd::EnableFreestanding);
	}

    static lto_code_gen_t createCodeGen(bool InLocalContext) {
        lto_initialize();

        TargetOptions Options = InitTargetOptionsFromCodeGenFlags();

        LibLTOCodeGenerator* CodeGen =
            InLocalContext ? new LibLTOCodeGenerator(make_unique<LLVMContext>())
            : new LibLTOCodeGenerator();
        CodeGen->setTargetOptions(Options);
        return wrap(CodeGen);
    }
	
    DEFINE_SIMPLE_CONVERSION_FUNCTIONS(lto::InputFile, lto_input_t)
}//end of ltocmd namespace

extern "C"
{
#include "Header.h"

    LLEXPORT const char* ЛЛОВК_ДайВерсию() {
        return LTOCodeGenerator::getVersionString();
    }

    LLEXPORT const char* ЛЛОВК_ДайОшСооб() {
        return ltocmd::sLastErrorString.c_str();
    }

    LLEXPORT bool ЛЛОВКМодуль_ФайлОбъект_ли(const char* path) {
        return LTOModule::isBitcodeFile(StringRef(path));
    }

    LLEXPORT bool ЛЛОВКМодуль_ФайлОбъектДляЦели_ли(const char* path,
        const char* target_triplet_prefix) {
        ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer = MemoryBuffer::getFile(path);
        if (!Buffer)
            return false;
        return LTOModule::isBitcodeForTarget(Buffer->get(),
            StringRef(target_triplet_prefix));
    }

    LLEXPORT bool ЛЛОВКМодуль_ЕстьКатегорияОБджСи_ли(const void* mem, size_t length) {
        std::unique_ptr<MemoryBuffer> Buffer(LTOModule::makeBuffer(mem, length));
        if (!Buffer)
            return false;
        LLVMContext Ctx;
        ErrorOr<bool> Result = expectedToErrorOrAndEmitErrors(
            Ctx, llvm::isBitcodeContainingObjCCategory(*Buffer));
        return Result && *Result;
    }

    LLEXPORT bool ЛЛОВКМодуль_ФайлОбъектВПамяти_ли(const void* mem, size_t length) {
        return LTOModule::isBitcodeFile(mem, length);
    }

    LLEXPORT bool
        ЛЛОВКМодуль_ФайлОбъектВПамятиДляЦели_ли(const void* mem,
            size_t length,
            const char* target_triplet_prefix) {
        std::unique_ptr<MemoryBuffer> buffer(LTOModule::makeBuffer(mem, length));
        if (!buffer)
            return false;
        return LTOModule::isBitcodeForTarget(buffer.get(),
            StringRef(target_triplet_prefix));
    }

    LLEXPORT lto_module_t ЛЛОВКМодуль_Создай(const char* path) {
        ltocmd::lto_initialize();
        llvm::TargetOptions Options = InitTargetOptionsFromCodeGenFlags();
        ErrorOr<std::unique_ptr<LTOModule>> M =
            LTOModule::createFromFile(*ltocmd::LTOContext, StringRef(path), Options);
        if (!M)
            return nullptr;
        return ltocmd::wrap(M->release());
    }

    LLEXPORT lto_module_t ЛЛОВКМодуль_СоздайИзФД(int fd, const char* path, size_t size) {
        ltocmd::lto_initialize();
        llvm::TargetOptions Options = InitTargetOptionsFromCodeGenFlags();
        ErrorOr<std::unique_ptr<LTOModule>> M = LTOModule::createFromOpenFile(
            *ltocmd::LTOContext, fd, StringRef(path), size, Options);
        if (!M)
            return nullptr;
        return ltocmd::wrap(M->release());
    }

    LLEXPORT lto_module_t ЛЛОВКМодуль_СоздайИзФДПоСмещению(int fd, const char* path,
        size_t file_size,
        size_t map_size,
        off_t offset) {
        ltocmd::lto_initialize();
        llvm::TargetOptions Options = InitTargetOptionsFromCodeGenFlags();
        ErrorOr<std::unique_ptr<LTOModule>> M = LTOModule::createFromOpenFileSlice(
            *ltocmd::LTOContext, fd, StringRef(path), map_size, offset, Options);
        if (!M)
            return nullptr;
        return ltocmd::wrap(M->release());
    }

    LLEXPORT lto_module_t ЛЛОВКМодуль_СоздайИзПамяти(const void* mem, size_t length) {
        ltocmd::lto_initialize();
        llvm::TargetOptions Options = InitTargetOptionsFromCodeGenFlags();
        ErrorOr<std::unique_ptr<LTOModule>> M =
            LTOModule::createFromBuffer(*ltocmd::LTOContext, mem, length, Options);
        if (!M)
            return nullptr;
        return ltocmd::wrap(M->release());
    }

    LLEXPORT lto_module_t ЛЛОВКМодуль_СоздайИзПамятиСПутём(const void* mem,
        size_t length,
        const char* path) {
        ltocmd::lto_initialize();
        llvm::TargetOptions Options = InitTargetOptionsFromCodeGenFlags();
        ErrorOr<std::unique_ptr<LTOModule>> M = LTOModule::createFromBuffer(
            *ltocmd::LTOContext, mem, length, Options, StringRef(path));
        if (!M)
            return nullptr;
        return ltocmd::wrap(M->release());
    }

    LLEXPORT lto_module_t ЛЛОВКМодуль_СоздайВЛокКонтексте(const void* mem, size_t length,
        const char* path) {
        ltocmd::lto_initialize();
        llvm::TargetOptions Options = InitTargetOptionsFromCodeGenFlags();

        // Create a local context. Ownership will be transferred to LTOModule.
        std::unique_ptr<LLVMContext> Context = llvm::make_unique<LLVMContext>();
        Context->setDiagnosticHandler(llvm::make_unique<ltocmd::LTOToolDiagnosticHandler>(),
            true);

        ErrorOr<std::unique_ptr<LTOModule>> M = LTOModule::createInLocalContext(
            std::move(Context), mem, length, Options, StringRef(path));
        if (!M)
            return nullptr;
        return ltocmd::wrap(M->release());
    }

    LLEXPORT lto_module_t ЛЛОВКМодуль_СоздайВКонтекстеКодГена(const void* mem,
        size_t length,
        const char* path,
        lto_code_gen_t cg) {
        ltocmd::lto_initialize();
        llvm::TargetOptions Options = InitTargetOptionsFromCodeGenFlags();
        ErrorOr<std::unique_ptr<LTOModule>> M = LTOModule::createFromBuffer(
            ltocmd::unwrap(cg)->getContext(), mem, length, Options, StringRef(path));
        return ltocmd::wrap(M->release());
    }

    LLEXPORT void ЛЛОВКМодуль_Вымести(lto_module_t mod) { delete ltocmd::unwrap(mod); }

    LLEXPORT const char* ЛЛОВКМодуль_ДайТриадуЦели(lto_module_t mod) {
        return ltocmd::unwrap(mod)->getTargetTriple().c_str();
    }

    LLEXPORT void ЛЛОВКМодуль_УстТриадуЦели(lto_module_t mod, const char* triple) {
        return ltocmd::unwrap(mod)->setTargetTriple(StringRef(triple));
    }

    LLEXPORT unsigned int ЛЛОВКМодуль_ДайЧлоСимволов(lto_module_t mod) {
        return ltocmd::unwrap(mod)->getSymbolCount();
    }

    LLEXPORT const char* ЛЛОВКМодуль_ДайИмяСимвола(lto_module_t mod, unsigned int index) {
        return ltocmd::unwrap(mod)->getSymbolName(index).data();
    }

    LLEXPORT lto_symbol_attributes ЛЛОВКМодуль_ДайАтрибутыСимвола(lto_module_t mod,
        unsigned int index) {
        return ltocmd::unwrap(mod)->getSymbolAttributes(index);
    }

    LLEXPORT const char* ЛЛОВКМодуль_ДайОпцииКомпоновщика(lto_module_t mod) {
        return ltocmd::unwrap(mod)->getLinkerOpts().data();
    }

    LLEXPORT void ЛЛОВККодГен_УстОбработчикДиагностики(lto_code_gen_t cg,
        lto_diagnostic_handler_t diag_handler,
        void* ctxt) {
        ltocmd::unwrap(cg)->setDiagnosticHandler(diag_handler, ctxt);
    }

    LLEXPORT lto_code_gen_t ЛЛОВККодГен_Создай(void) {
        return ltocmd::createCodeGen(/* InLocalContext */ false);
    }

    LLEXPORT lto_code_gen_t ЛЛОВККодГен_СоздайВЛокКонтексте(void) {
        return ltocmd::createCodeGen(/* InLocalContext */ true);
    }

    LLEXPORT void ЛЛОВККодГен_Вымести(lto_code_gen_t cg) { delete ltocmd::unwrap(cg); }

    LLEXPORT bool ЛЛОВККодГен_ДобавьМодуль(lto_code_gen_t cg, lto_module_t mod) {
        return !ltocmd::unwrap(cg)->addModule(ltocmd::unwrap(mod));
    }

    LLEXPORT void ЛЛОВККодГен_УстМодуль(lto_code_gen_t cg, lto_module_t mod) {
        ltocmd::unwrap(cg)->setModule(std::unique_ptr<LTOModule>(ltocmd::unwrap(mod)));
    }

    LLEXPORT bool ЛЛОВККодГен_УстМодельОтладки(lto_code_gen_t cg, lto_debug_model debug) {
        ltocmd::unwrap(cg)->setDebugInfo(debug);
        return false;
    }

    LLEXPORT bool ЛЛОВККодГен_УстМодельПИК(lto_code_gen_t cg, lto_codegen_model model) {
        switch (model) {
        case LTO_CODEGEN_PIC_MODEL_STATIC:
            ltocmd::unwrap(cg)->setCodePICModel(Reloc::Static);
            return false;
        case LTO_CODEGEN_PIC_MODEL_DYNAMIC:
            ltocmd::unwrap(cg)->setCodePICModel(Reloc::PIC_);
            return false;
        case LTO_CODEGEN_PIC_MODEL_DYNAMIC_NO_PIC:
            ltocmd::unwrap(cg)->setCodePICModel(Reloc::DynamicNoPIC);
            return false;
        case LTO_CODEGEN_PIC_MODEL_DEFAULT:
            ltocmd::unwrap(cg)->setCodePICModel(None);
            return false;
        }
        ltocmd::sLastErrorString = "Неизвестная модель PIC";
        return true;
    }

    LLEXPORT void ЛЛОВККодГен_УстЦПБ(lto_code_gen_t cg, const char* cpu) {
        return ltocmd::unwrap(cg)->setCpu(cpu);
    }

    LLEXPORT void ЛЛОВККодГен_УстАсмПуть(lto_code_gen_t cg, const char* path) {
        // In here only for backwards compatibility. We use MC now.
    }

    LLEXPORT void ЛЛОВККодГен_УстАсмАрги(lto_code_gen_t cg, const char** args,
        int nargs) {
        // In here only for backwards compatibility. We use MC now.
    }

    LLEXPORT void ЛЛОВККодГен_ДобавьСимволМастПрезерв(lto_code_gen_t cg,
        const char* symbol) {
        ltocmd::unwrap(cg)->addMustPreserveSymbol(symbol);
    }

    static void maybeParseOptions(lto_code_gen_t cg) {
        if (!ltocmd::parsedOptions) {
            ltocmd::unwrap(cg)->parseCodeGenDebugOptions();
            ltocmd::lto_add_attrs(cg);
            ltocmd::parsedOptions = true;
        }
    }

    LLEXPORT bool ЛЛОВККодГен_ПишиСлитноМодуль(lto_code_gen_t cg, const char* path) {
        maybeParseOptions(cg);
        return !ltocmd::unwrap(cg)->writeMergedModules(path);
    }

    LLEXPORT const void* ЛЛОВККодГен_Компилируй(lto_code_gen_t cg, size_t* length) {
        maybeParseOptions(cg);
        ltocmd::LibLTOCodeGenerator* CG = ltocmd::unwrap(cg);
        CG->NativeObjectFile =
            CG->compile(ltocmd::DisableVerify, ltocmd::DisableInline, ltocmd::DisableGVNLoadPRE,
                ltocmd::DisableLTOVectorization);
        if (!CG->NativeObjectFile)
            return nullptr;
        *length = CG->NativeObjectFile->getBufferSize();
        return CG->NativeObjectFile->getBufferStart();
    }

    LLEXPORT bool ЛЛОВККодГен_Оптимизируй(lto_code_gen_t cg) {
        maybeParseOptions(cg);
        return !ltocmd::unwrap(cg)->optimize(ltocmd::DisableVerify, ltocmd::DisableInline, ltocmd::DisableGVNLoadPRE,
            ltocmd::DisableLTOVectorization);
    }

    LLEXPORT const void* ЛЛОВККодГен_КомпилируйОптимиз(lto_code_gen_t cg, size_t* length) {
        maybeParseOptions(cg);
        ltocmd::LibLTOCodeGenerator* CG = ltocmd::unwrap(cg);
        CG->NativeObjectFile = CG->compileOptimized();
        if (!CG->NativeObjectFile)
            return nullptr;
        *length = CG->NativeObjectFile->getBufferSize();
        return CG->NativeObjectFile->getBufferStart();
    }

    LLEXPORT bool ЛЛОВККодГен_КомпилируйВФайл(lto_code_gen_t cg, const char** name) {
        maybeParseOptions(cg);
        return !ltocmd::unwrap(cg)->compile_to_file(
            name, ltocmd::DisableVerify, ltocmd::DisableInline, ltocmd::DisableGVNLoadPRE,
            ltocmd::DisableLTOVectorization);
    }

    LLEXPORT void ЛЛОВККодГен_ОпцииОтладки(lto_code_gen_t cg, const char* opt) {
        ltocmd::unwrap(cg)->setCodeGenDebugOptions(opt);
    }

    LLEXPORT unsigned int ЛЛОВКАПИВерсия() { return LTO_API_VERSION; }

    LLEXPORT void ЛЛОВККодГен_УстСледуетИнтернализовать(lto_code_gen_t cg,
        bool ShouldInternalize) {
        ltocmd::unwrap(cg)->setShouldInternalize(ShouldInternalize);
    }

    LLEXPORT void ЛЛОВККодГен_УстСледуетВнедритьСписокИспользований(lto_code_gen_t cg,
        lto_bool_t ShouldEmbedUselists) {
        ltocmd::unwrap(cg)->setShouldEmbedUselists(ShouldEmbedUselists);
    }

    // ThinLTO API below

    LLEXPORT thinlto_code_gen_t ЛЛОВК2_СоздайКодГен(void) {
        ltocmd::lto_initialize();
        ThinLTOCodeGenerator* CodeGen = new ThinLTOCodeGenerator();
        CodeGen->setTargetOptions(InitTargetOptionsFromCodeGenFlags());
        CodeGen->setFreestanding(ltocmd::EnableFreestanding);

        if (ltocmd::OptLevel.getNumOccurrences()) {
            if (ltocmd::OptLevel < '0' || ltocmd::OptLevel > '3')
                report_fatal_error("Уровень оптимизации должен быть между 0 и 3");
            CodeGen->setOptLevel(ltocmd::OptLevel - '0');
            switch (ltocmd::OptLevel) {
            case '0':
                CodeGen->setCodeGenOptLevel(CodeGenOpt::None);
                break;
            case '1':
                CodeGen->setCodeGenOptLevel(CodeGenOpt::Less);
                break;
            case '2':
                CodeGen->setCodeGenOptLevel(CodeGenOpt::Default);
                break;
            case '3':
                CodeGen->setCodeGenOptLevel(CodeGenOpt::Aggressive);
                break;
            }
        }
        return ltocmd::wrap(CodeGen);
    }

    LLEXPORT void ЛЛОВК2_ВыместиКодГен(thinlto_code_gen_t cg) { delete ltocmd::unwrap(cg); }

    LLEXPORT void ЛЛОВК2_ДобавьМодуль(thinlto_code_gen_t cg, const char* Identifier,
        const char* Data, int Length) {
        ltocmd::unwrap(cg)->addModule(Identifier, StringRef(Data, Length));
    }

    LLEXPORT void ЛЛОВК2КодГен_Обработай(thinlto_code_gen_t cg) { ltocmd::unwrap(cg)->run(); }

    LLEXPORT unsigned int ЛЛОВК2Модуль_ДайЧлоОбъектов(thinlto_code_gen_t cg) {
        return ltocmd::unwrap(cg)->getProducedBinaries().size();
    }
    LTOObjectBuffer ЛЛОВК2Модуль_ДайОбъект(thinlto_code_gen_t cg,
        unsigned int index) {
        assert(index < ltocmd::unwrap(cg)->getProducedBinaries().size() && "Index overflow");
        auto& MemBuffer = ltocmd::unwrap(cg)->getProducedBinaries()[index];
        return LTOObjectBuffer{ MemBuffer->getBufferStart(),
                               MemBuffer->getBufferSize() };
    }

    LLEXPORT unsigned int ЛЛОВК2Модуль_ДайЧлоОбъектФайлов(thinlto_code_gen_t cg) {
        return ltocmd::unwrap(cg)->getProducedBinaryFiles().size();
    }
    LLEXPORT const char* ЛЛОВК2Модуль_ДайОбъектФайл(thinlto_code_gen_t cg,
        unsigned int index) {
        assert(index < ltocmd::unwrap(cg)->getProducedBinaryFiles().size() &&
            "Index overflow");
        return ltocmd::unwrap(cg)->getProducedBinaryFiles()[index].c_str();
    }

    LLEXPORT void ЛЛОВК2КодГен_ОтключиКодГен(thinlto_code_gen_t cg,
        lto_bool_t disable) {
        ltocmd::unwrap(cg)->disableCodeGen(disable);
    }

    LLEXPORT void ЛЛОВК2КодГен_УстТолькоКодГен(thinlto_code_gen_t cg,
        lto_bool_t CodeGenOnly) {
        ltocmd::unwrap(cg)->setCodeGenOnly(CodeGenOnly);
    }

    LLEXPORT void ЛЛОВК2_ОпцииОтладки(const char* const* options, int number) {
        // if options were requested, set them
        if (number && options) {
            std::vector<const char*> CodegenArgv(1, "libLTO");
            for (auto Arg : ArrayRef<const char*>(options, number))
                CodegenArgv.push_back(Arg);
            cl::ParseCommandLineOptions(CodegenArgv.size(), CodegenArgv.data());
        }
    }

    LLEXPORT lto_bool_t ЛЛОВКМодуль_ОВК2_ли(lto_module_t mod) {
        return ltocmd::unwrap(mod)->isThinLTO();
    }

    LLEXPORT void ЛЛОВК2КодГен_ДобавьСимволМастПрезерв(thinlto_code_gen_t cg,
        const char* Name, int Length) {
        ltocmd::unwrap(cg)->preserveSymbol(StringRef(Name, Length));
    }

    LLEXPORT void ЛЛОВК2КодГен_ДобавьКроссРефСимвол(thinlto_code_gen_t cg,
        const char* Name, int Length) {
        ltocmd::unwrap(cg)->crossReferenceSymbol(StringRef(Name, Length));
    }

    LLEXPORT void ЛЛОВК2КодГен_УстЦПБ(thinlto_code_gen_t cg, const char* cpu) {
        return ltocmd::unwrap(cg)->setCpu(cpu);
    }

    LLEXPORT void ЛЛОВК2КодГен_УстПапкуКэша(thinlto_code_gen_t cg,
        const char* cache_dir) {
        return ltocmd::unwrap(cg)->setCacheDir(cache_dir);
    }

    LLEXPORT void ЛЛОВК2КодГен_УстИнтервалПрюнингаКэша(thinlto_code_gen_t cg,
        int interval) {
        return ltocmd::unwrap(cg)->setCachePruningInterval(interval);
    }

    LLEXPORT void ЛЛОВК2КодГен_УстЭкспирациюЗаписиКэша(thinlto_code_gen_t cg,
        unsigned expiration) {
        return ltocmd::unwrap(cg)->setCacheEntryExpiration(expiration);
    }

    LLEXPORT void ЛЛОВК2КодГен_УстФинальнРазКэшаОтносительноДоступнПрострву(
        thinlto_code_gen_t cg, unsigned Percentage) {
        return ltocmd::unwrap(cg)->setMaxCacheSizeRelativeToAvailableSpace(Percentage);
    }

    LLEXPORT void ЛЛОВК2КодГен_УстРазмКэшаВБайтах(
        thinlto_code_gen_t cg, unsigned MaxSizeBytes) {
        return ltocmd::unwrap(cg)->setCacheMaxSizeBytes(MaxSizeBytes);
    }

    LLEXPORT void ЛЛОВК2КодГен_УстРазмКэшаВМегаБайтах(
        thinlto_code_gen_t cg, unsigned MaxSizeMegabytes) {
        uint64_t MaxSizeBytes = MaxSizeMegabytes;
        MaxSizeBytes *= 1024 * 1024;
        return ltocmd::unwrap(cg)->setCacheMaxSizeBytes(MaxSizeBytes);
    }

    LLEXPORT void ЛЛОВК2КодГен_УстРазмКэшаВФайлах(
        thinlto_code_gen_t cg, unsigned MaxSizeFiles) {
        return ltocmd::unwrap(cg)->setCacheMaxSizeFiles(MaxSizeFiles);
    }

    LLEXPORT void ЛЛОВК2КодГен_УстПапкуВремХран(thinlto_code_gen_t cg,
        const char* save_temps_dir) {
        return ltocmd::unwrap(cg)->setSaveTempsDir(save_temps_dir);
    }

    LLEXPORT void ЛЛОВК2КодГен_УстПапкуСгенОбъектов(thinlto_code_gen_t cg,
        const char* save_temps_dir) {
        ltocmd::unwrap(cg)->setGeneratedObjectsDirectory(save_temps_dir);
    }

    LLEXPORT lto_bool_t ЛЛОВК2КодГен_УстМодельПИК(thinlto_code_gen_t cg,
        lto_codegen_model model) {
        switch (model) {
        case LTO_CODEGEN_PIC_MODEL_STATIC:
            ltocmd::unwrap(cg)->setCodePICModel(Reloc::Static);
            return false;
        case LTO_CODEGEN_PIC_MODEL_DYNAMIC:
            ltocmd::unwrap(cg)->setCodePICModel(Reloc::PIC_);
            return false;
        case LTO_CODEGEN_PIC_MODEL_DYNAMIC_NO_PIC:
            ltocmd::unwrap(cg)->setCodePICModel(Reloc::DynamicNoPIC);
            return false;
        case LTO_CODEGEN_PIC_MODEL_DEFAULT:
            ltocmd::unwrap(cg)->setCodePICModel(None);
            return false;
        }
        ltocmd::sLastErrorString = "Неизвестная модель PIC";
        return true;
    }

    LLEXPORT lto_input_t ЛЛОВКВвод_Создай(const void* buffer, size_t buffer_size, const char* path) {
        return ltocmd::wrap(LTOModule::createInputFile(buffer, buffer_size, path, ltocmd::sLastErrorString));
    }

    LLEXPORT void ЛЛОВКВвод_Вымести(lto_input_t input) {
        delete ltocmd::unwrap(input);
    }

    LLEXPORT  unsigned ЛЛОВКВвод_ДайЧлоЗависимыхБиб(lto_input_t input) {
        return LTOModule::getDependentLibraryCount(ltocmd::unwrap(input));
    }

    LLEXPORT  const char* ЛЛОВКВвод_ДайЗависимБиб(lto_input_t input,
        size_t index,
        size_t* size) {
        return LTOModule::getDependentLibrary(ltocmd::unwrap(input), index, size);
    }
}
