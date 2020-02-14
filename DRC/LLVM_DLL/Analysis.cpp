
extern "C" {
#include "Header.h"

    LLEXPORT  void ЛЛИНицАнализ(ЛЛРеестрПроходок R) {
        LLVMInitializeAnalysis(R);
    }

    LLEXPORT  ЛЛБул ЛЛВерифицируйМодуль(ЛЛМодуль M, LLVMVerifierFailureAction Action,
        char** OutMessages) {
        return LLVMVerifyModule(M, Action, OutMessages);
    }

    LLEXPORT  ЛЛБул ЛЛВерифицируйФункцию(ЛЛЗначение Fn, LLVMVerifierFailureAction Action) {
        return LLVMVerifyFunction(Fn, Action);
    }

    LLEXPORT  void ЛЛПокажиКФГФункции(ЛЛЗначение Fn) {
        LLVMViewFunctionCFG(Fn);
    }

    LLEXPORT  void ЛЛПокажиТолькоКФГФункции(ЛЛЗначение Fn) {
        LLVMViewFunctionCFGOnly(Fn);
    }
}