
extern "C" {
#include "Header.h"

    LLEXPORT  void ЛЛИНицАнализ(ЛЛРеестрПроходок R);

    LLEXPORT  ЛЛБул ЛЛВерифицируйМодуль(ЛЛМодуль M, LLVMVerifierFailureAction Action,
        char** OutMessages) ;

    LLEXPORT  ЛЛБул ЛЛВерифицируйФункцию(ЛЛЗначение Fn, LLVMVerifierFailureAction Action) ;

    LLEXPORT  void ЛЛПокажиКФГФункции(ЛЛЗначение Fn);

    LLEXPORT  void ЛЛПокажиТолькоКФГФункции(ЛЛЗначение Fn);
}