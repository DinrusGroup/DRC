module rt.deh;

import core.sys.windows.windows;

enum size_t EXCEPTION_MAXIMUM_PARAMETERS = 15;

struct EXCEPTION_RECORD {
        DWORD ExceptionCode;
        DWORD ExceptionFlags;
        EXCEPTION_RECORD* ExceptionRecord;
        PVOID ExceptionAddress;
        DWORD NumberParameters;
        DWORD[EXCEPTION_MAXIMUM_PARAMETERS] ExceptionInformation;
}
alias EXCEPTION_RECORD* PEXCEPTION_RECORD, LPEXCEPTION_RECORD;

Throwable _d_translate_se_to_d_exception(EXCEPTION_RECORD* exception_record);
