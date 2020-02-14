/**
Модуль функций WIN API для языка Динрус.
Разработчик Виталий Кулич.
*/
module sys.WinFuncs;

import  std.string, std.utf;
import  std.intrinsic;
import cidrus;
public import sys.inc.kernel32;

version = ЛитлЭндиан;


//////////////////////////////////////////////////////	
extern (Windows)
{

////////////////////
BOOL SetCurrentDirectoryA(LPCSTR lpPathName);//
BOOL SetCurrentDirectoryW(LPCWSTR lpPathName);//
DWORD GetCurrentDirectoryA(DWORD nBufferLength, LPSTR буф);//
DWORD GetCurrentDirectoryW(DWORD nBufferLength, LPWSTR буф);//
BOOL RemoveDirectoryA(LPCSTR lpPathName);//
BOOL RemoveDirectoryW(LPCWSTR lpPathName);//
BOOL   DeleteFileA(in char *lpFileName);//
BOOL   DeleteFileW(LPCWSTR lpFileName);//
BOOL   FindClose(HANDLE hFindFile);//
HANDLE FindFirstFileA(in char *lpFileName, WIN32_FIND_DATA* lpFindFileData);//
HANDLE FindFirstFileW(in LPCWSTR lpFileName, WIN32_FIND_DATAW* lpFindFileData);//
BOOL   FindNextFileA(HANDLE hFindFile, WIN32_FIND_DATA* lpFindFileData);//
BOOL   FindNextFileW(HANDLE hFindFile, WIN32_FIND_DATAW* lpFindFileData);//
BOOL   GetExitCodeThread(HANDLE hThread, DWORD *lpExitCode);//
DWORD  GetLastError();//
DWORD  GetFileAttributesA(in char *lpFileName);//
DWORD  GetFileAttributesW(in wchar *lpFileName);//
DWORD  GetFileSize(HANDLE hFile, DWORD *lpFileSizeHigh);//
BOOL   MoveFileA(in char *from, in char *to);//
BOOL   MoveFileW(LPCWSTR lpExistingFileName, LPCWSTR lpNewFileName);//
BOOL   ReadFile(HANDLE hFile, void *буф, DWORD nNumberOfBytesToRead, DWORD *lpNumberOfBytesRead, OVERLAPPED *lpOverlapped);//
DWORD  SetFilePointer(HANDLE hFile, LONG lDistanceToMove, LONG *lpDistanceToMoveHigh, DWORD dwMoveMethod);//
BOOL   WriteFile(HANDLE hFile, in void *буф, DWORD nNumberOfBytesToWrite, DWORD *lpNumberOfBytesWritten, OVERLAPPED *lpOverlapped);//
DWORD  GetModuleFileNameA(HMODULE hModule, LPSTR lpFilename, DWORD nSize);//
DWORD GetModuleFileNameW(HINST, LPWSTR, DWORD);
HMODULE GetModuleHandleA(LPCSTR lpModuleName);//
HMODULE GetModuleHandleW(LPCWSTR);//
HANDLE GetStdHandle(DWORD nStdHandle);//
BOOL   SetStdHandle(DWORD nStdHandle, HANDLE hHandle);//
HMODULE LoadLibraryA(LPCSTR lpLibFileName);//
HINST LoadLibraryW(LPCWSTR);//
HINST LoadLibraryExA(LPCSTR, HANDLE, DWORD);//
HINST LoadLibraryExW(LPCWSTR, HANDLE, DWORD);//
FARPROC GetProcAddress(HMODULE hModule, LPCSTR lpProcName);//
DWORD GetVersion();//
BOOL FreeLibrary(HMODULE hLibModule);//
void FreeLibraryAndExitThread(HMODULE hLibModule, DWORD dwExitCode);//

int MessageBoxA(HWND hWnd, LPCSTR lpText, LPCSTR lpCaption, UINT uType);//
int MessageBoxExA(HWND hWnd, LPCSTR lpText, LPCSTR lpCaption, UINT uType, WORD wLanguageId);//
int MessageBoxW(HWND hWnd, LPCWSTR lpText, LPCWSTR lpCaption, UINT uType);//
int MessageBoxExW(HWND hWnd, LPCWSTR lpText, LPCWSTR lpCaption, UINT uType, WORD wLanguageId);//

LONG RegDeleteKeyA(HKEY hKey, LPCSTR lpSubKey);//
LONG RegDeleteValueA(HKEY hKey, LPCSTR lpValueName);//
LONG  RegEnumKeyExA(HKEY hKey, DWORD dwIndex, LPSTR lpName, LPDWORD lpcbName, LPDWORD lpReserved, LPSTR lpClass, LPDWORD lpcbClass, FILETIME* lpftLastWriteTime);//
LONG RegEnumValueA(HKEY hKey, DWORD dwIndex, LPSTR lpValueName, LPDWORD lpcbValueName, LPDWORD lpReserved,
    LPDWORD lpType, LPBYTE lpData, LPDWORD lpcbData);//
LONG RegCloseKey(HKEY hKey);//
LONG RegFlushKey(HKEY hKey);//
LONG RegOpenKeyA(HKEY hKey, LPCSTR lpSubKey, PHKEY phkResult);//
LONG RegOpenKeyExA(HKEY hKey, LPCSTR lpSubKey, DWORD ulOptions, REGSAM samDesired, PHKEY phkResult);//
LONG RegQueryInfoKeyA(HKEY hKey, LPSTR lpClass, LPDWORD lpcbClass,
    LPDWORD lpReserved, LPDWORD lpcSubKeys, LPDWORD lpcbMaxSubKeyLen, LPDWORD lpcbMaxClassLen,
    LPDWORD lpcValues, LPDWORD lpcbMaxValueNameLen, LPDWORD lpcbMaxValueLen, LPDWORD lpcbSecurityDescriptor,
    PFILETIME lpftLastWriteTime);//
LONG RegQueryValueA(HKEY hKey, LPCSTR lpSubKey, LPSTR lpValue,
    LPLONG lpcbValue);//
LONG RegCreateKeyExA(HKEY hKey, LPCSTR lpSubKey, DWORD Reserved, LPSTR lpClass,
   DWORD dwOptions, REGSAM samDesired, SECURITY_ATTRIBUTES* lpSecurityAttributes,
    PHKEY phkResult, LPDWORD lpdwDisposition);//
LONG RegSetValueExA(HKEY hKey, LPCSTR lpValueName, DWORD Reserved, DWORD dwType, BYTE* lpData, DWORD cbData);//

 BOOL  FreeResource(HGLOBAL hResData);//
 LPVOID LockResource(HGLOBAL hResData);//
 HGLOBAL GlobalHandle(LPCVOID);//
HGLOBAL GlobalAlloc(UINT, DWORD);//
HGLOBAL GlobalReAlloc(HGLOBAL, DWORD, UINT);//
DWORD GlobalSize(HGLOBAL);//
UINT GlobalFlags(HGLOBAL);//
LPVOID GlobalLock(HGLOBAL);//
 BOOL GlobalUnlock(HGLOBAL hMem);//
 HGLOBAL GlobalFree(HGLOBAL hMem);//
 UINT GlobalCompact(DWORD dwMinFree);//
 void GlobalFix(HGLOBAL hMem);//
 void GlobalUnfix(HGLOBAL hMem);//
 LPVOID GlobalWire(HGLOBAL hMem);//
 BOOL GlobalUnWire(HGLOBAL hMem);//
 void GlobalMemoryStatus(LPMEMORYSTATUS буф);//
 HLOCAL LocalAlloc(UINT uFlags, UINT uBytes);//
 HLOCAL LocalReAlloc(HLOCAL hMem, UINT uBytes, UINT uFlags);//
 LPVOID LocalLock(HLOCAL hMem);//
 HLOCAL LocalHandle(LPCVOID pMem);//
 BOOL LocalUnlock(HLOCAL hMem);//
 UINT LocalSize(HLOCAL hMem);//
 UINT LocalFlags(HLOCAL hMem);//
 HLOCAL LocalFree(HLOCAL hMem);//
 UINT LocalShrink(HLOCAL hMem, UINT cbNewSize);//
 UINT LocalCompact(UINT uMinFree);//
 BOOL FlushInstructionCache(HANDLE hProcess, LPCVOID lpBaseAddress, DWORD dwSize);//
 LPVOID VirtualAlloc(LPVOID lpAddress, DWORD dwSize, DWORD flAllocationType, DWORD flProtect);//
 BOOL VirtualFree(LPVOID lpAddress, DWORD dwSize, DWORD dwFreeType);//
 BOOL VirtualProtect(LPVOID lpAddress, DWORD dwSize, DWORD flNewProtect, PDWORD lpflOldProtect);//
 DWORD VirtualQuery(LPCVOID lpAddress, PMEMORY_BASIC_INFORMATION буф, DWORD dwLength);//
 LPVOID VirtualAllocEx(HANDLE hProcess, LPVOID lpAddress, DWORD dwSize, DWORD flAllocationType, DWORD flProtect);//
 BOOL VirtualFreeEx(HANDLE hProcess, LPVOID lpAddress, DWORD dwSize, DWORD dwFreeType);//
 BOOL VirtualProtectEx(HANDLE hProcess, LPVOID lpAddress, DWORD dwSize, DWORD flNewProtect, PDWORD lpflOldProtect);//
 DWORD VirtualQueryEx(HANDLE hProcess, LPCVOID lpAddress, PMEMORY_BASIC_INFORMATION буф, DWORD dwLength);//
 void RtlFillMemory( PVOID Destination,  т_мера Length,  BYTE Fill);//
т_мера GetLargePageMinimum();//Не найдена!!!!
UINT GetWriteWatch(  DWORD dwFlags,  PVOID lpBaseAddress,  т_мера dwRegionSize,  PVOID* lpAddresses,  PULONG_PTR lpdwCount,  PULONG lpdwGranularity);//
void RtlCopyMemory(PVOID Destination, VOID* Source,  т_мера Length);//
BOOL IsBadStringPtrA(LPCSTR, UINT);//
BOOL IsBadStringPtrW(LPCWSTR, UINT);//
void RtlMoveMemory( PVOID Destination,  VOID* Source,  size_t Length);//
UINT ResetWriteWatch(  LPVOID lpBaseAddress,  size_t dwRegionSize);
PVOID RtlSecureZeroMemory(  PVOID ptr,  size_t cnt);//Не найдена!!!
void RtlZeroMemory(  PVOID Destination,  size_t Length);//

HANDLE HeapCreate(DWORD, DWORD, DWORD);//
BOOL HeapDestroy(HANDLE);//
LPVOID HeapAlloc(HANDLE, DWORD, DWORD);//
LPVOID HeapReAlloc(HANDLE, DWORD, LPVOID, DWORD);//
BOOL HeapFree(HANDLE, DWORD, LPVOID);//
DWORD HeapSize(HANDLE, DWORD, LPCVOID);//
BOOL HeapValidate(HANDLE, DWORD, LPCVOID);//
UINT HeapCompact(HANDLE, DWORD);//
BOOL HeapLock(HANDLE);//
BOOL HeapUnlock(HANDLE);//
BOOL HeapWalk(HANDLE, LPPROCESS_HEAP_ENTRY);//
BOOL HeapQueryInformation(  HANDLE HeapHandle,  бцел HeapInformationClass,  PVOID HeapInformation,
  т_мера HeapInformationLength,  т_мера* ReturnLength);//
BOOL HeapSetInformation(  HANDLE HeapHandle,  бцел HeapInformationClass,  PVOID HeapInformation,  т_мера HeapInformationLength);//
HANDLE GetProcessHeap();//
DWORD GetProcessHeaps(DWORD, HANDLE*);//

void GetSystemTime(SYSTEMTIME* lpSystemTime);//
BOOL GetFileTime(HANDLE hFile, FILETIME *lpCreationTime, FILETIME *lpLastAccessTime, FILETIME *lpLastWriteTime);//
void GetSystemTimeAsFileTime(FILETIME* lpSystemTimeAsFileTime);//
BOOL SetSystemTime(SYSTEMTIME* lpSystemTime);//
BOOL SetFileTime(HANDLE hFile, in FILETIME *lpCreationTime, in FILETIME *lpLastAccessTime, in FILETIME *lpLastWriteTime);//
void GetLocalTime(SYSTEMTIME* lpSystemTime);//
BOOL SetLocalTime(SYSTEMTIME* lpSystemTime);//
BOOL SystemTimeToTzSpecificLocalTime(TIME_ZONE_INFORMATION* lpTimeZoneInformation, SYSTEMTIME* lpUniversalTime, SYSTEMTIME* lpLocalTime);//
DWORD GetTimeZoneInformation(TIME_ZONE_INFORMATION* lpTimeZoneInformation);//
BOOL SetTimeZoneInformation(TIME_ZONE_INFORMATION* lpTimeZoneInformation);//

BOOL SystemTimeToFileTime(in SYSTEMTIME *lpSystemTime, FILETIME* lpFileTime);//
BOOL FileTimeToLocalFileTime(in FILETIME *lpFileTime, FILETIME* lpLocalFileTime);//
BOOL LocalFileTimeToFileTime(in FILETIME *lpLocalFileTime, FILETIME* lpFileTime);//
BOOL FileTimeToSystemTime(in FILETIME *lpFileTime, SYSTEMTIME* lpSystemTime);//
BOOL FileTimeToDosDateTime(in FILETIME *lpFileTime, WORD* lpFatDate, WORD* lpFatTime);//
BOOL DosDateTimeToFileTime(WORD wFatDate, WORD wFatTime, FILETIME* lpFileTime);//
DWORD GetTickCount();//
BOOL SetSystemTimeAdjustment(DWORD dwTimeAdjustment, BOOL bTimeAdjustmentDisabled);//
BOOL GetSystemTimeAdjustment(DWORD* lpTimeAdjustment, DWORD* lpTimeIncrement, BOOL* lpTimeAdjustmentDisabled);//

DWORD FormatMessageA(DWORD dwFlags, LPCVOID lpSource, DWORD dwMessageId, DWORD dwLanguageId, LPSTR буф, DWORD nSize, void* *Arguments);//
DWORD FormatMessageW(DWORD dwFlags, LPCVOID lpSource, DWORD dwMessageId, DWORD dwLanguageId, LPWSTR буф, DWORD nSize, void* *Arguments);//

HANDLE GetCurrentThread();//
BOOL GetProcessTimes(HANDLE hProcess, LPFILETIME lpCreationTime, LPFILETIME lpExitTime, LPFILETIME lpKernelTime, LPFILETIME lpUserTime);//
BOOL DuplicateHandle (HANDLE sourceProcess, HANDLE sourceThread,
        HANDLE targetProcessHandle, HANDLE *targetHandle, DWORD access,
        BOOL inheritHandle, DWORD options);//
DWORD GetCurrentThreadId();//
BOOL SetThreadPriority(HANDLE hThread, int nPriority);//
BOOL SetThreadPriorityBoost(HANDLE hThread, BOOL bDisablePriorityBoost);//
BOOL GetThreadPriorityBoost(HANDLE hThread, PBOOL pDisablePriorityBoost);//
BOOL GetThreadTimes(HANDLE hThread, LPFILETIME lpCreationTime, LPFILETIME lpExitTime, LPFILETIME lpKernelTime, LPFILETIME lpUserTime);
int GetThreadPriority(HANDLE hThread);//
BOOL GetThreadContext(HANDLE hThread, CONTEXT* lpContext);//
BOOL SetThreadContext(HANDLE hThread, CONTEXT* lpContext);//
DWORD SuspendThread(HANDLE hThread);//
DWORD ResumeThread(HANDLE hThread);//
DWORD WaitForSingleObject(HANDLE hHandle, DWORD dwMilliseconds);//
DWORD WaitForMultipleObjects(DWORD nCount, HANDLE *lpHandles, BOOL bWaitAll, DWORD dwMilliseconds);//
void Sleep(DWORD dwMilliseconds);//

BOOL QueryPerformanceCounter(long* lpPerformanceCount);//
BOOL QueryPerformanceFrequency(long* lpFrequency);//

бцел GetThreadLocale();//

wchar*   GetCommandLineW();//
wchar**  CommandLineToArgvW(wchar*, int*);

проц ExitProcess(UINT);
BOOL GetExitCodeProcess(HANDLE hProcess, LPDWORD lpExitCode);
BOOL CreateProcessAsUserA(HANDLE, LPCTSTR, LPTSTR, LPSECURITY_ATTRIBUTES, LPSECURITY_ATTRIBUTES, BOOL, DWORD, LPVOID, LPCTSTR, LPSTARTUPINFO, LPPROCESS_INFORMATION);
BOOL CreateProcessAsUserW(HANDLE, LPCWSTR, LPWSTR, LPSECURITY_ATTRIBUTES, LPSECURITY_ATTRIBUTES, BOOL, DWORD, LPVOID, LPCWSTR, LPSTARTUPINFO, LPPROCESS_INFORMATION);


BOOL GetProcessAffinityMask(HANDLE, LPDWORD, LPDWORD);
BOOL GetProcessWorkingSetSize(HANDLE, LPDWORD, LPDWORD);
BOOL SetProcessWorkingSetSize(HANDLE, DWORD, DWORD);
HANDLE OpenProcess(DWORD, BOOL, DWORD);
HANDLE GetCurrentProcess();//
DWORD GetCurrentProcessId();//
BOOL TerminateProcess(HANDLE, UINT);
HANDLE OpenFileMappingA(DWORD, BOOL, LPCSTR);
HANDLE OpenFileMappingW(DWORD, BOOL, LPCWSTR);


wchar* SysAllocString(in wchar* psz);
int SysReAllocString(wchar*, in wchar* psz);
wchar* SysAllocStringLen(in wchar* psz, uint len);
int SysReAllocStringLen(wchar*, in wchar* psz, uint len);
void SysFreeString(wchar*);
uint SysStringLen(wchar*);
uint SysStringByteLen(wchar*);
wchar* SysAllocStringByteLen(in ubyte* psz, uint len);
int CoCreateGuid(out sys.WinStructs.ГУИД pGuid);
int ProgIDFromCLSID(ref sys.WinStructs.ГУИД clsid, out wchar* lplpszProgID);
int CLSIDFromProgID(in wchar* lpszProgID, out sys.WinStructs.ГУИД lpclsid);
int CLSIDFromProgIDEx(in wchar* lpszProgID, out sys.WinStructs.ГУИД lpclsid);
int CoCreateInstance(ref sys.WinStructs.ГУИД rclsid, sys.WinIfaces.Инкогнито pUnkOuter, uint dwClsContext, ref sys.WinStructs.ГУИД riid, void** ppv);
int CoGetClassObject(ref sys.WinStructs.ГУИД rclsid, uint dwClsContext, void* pvReserved, ref sys.WinStructs.ГУИД riid, void** ppv);
int CoCreateInstanceEx(ref sys.WinStructs.ГУИД rclsid, sys.WinIfaces.Инкогнито pUnkOuter, uint dwClsContext, sys.WinStructs.КОСЕРВЕРИНФО* pServerInfo, uint dwCount, sys.WinStructs.МУЛЬТИ_ОИ* pResults);
int RegisterActiveObject(sys.WinIfaces.Инкогнито punk, ref sys.WinStructs.ГУИД rclsid, uint dwFlags, out uint pdwRegister);
int RevokeActiveObject(uint dwRegister, void* pvReserved);
int GetActiveObject(ref sys.WinStructs.ГУИД rclsid, void* pvReserved, out sys.WinIfaces.Инкогнито ppunk);

int SafeArrayAllocDescriptor(uint cDims, out sys.WinStructs.БЕЗОПМАС* ppsaOut);
int SafeArrayAllocDescriptorEx(ushort вт, uint cDims, out sys.WinStructs.БЕЗОПМАС* ppsaOut);
int SafeArrayAllocData(sys.WinStructs.БЕЗОПМАС* psa);
sys.WinStructs.БЕЗОПМАС* SafeArrayCreate(ushort вт, uint cDims, sys.WinStructs.ГРАНБЕЗОПМАСА* rgsabound);
sys.WinStructs.БЕЗОПМАС* SafeArrayCreateEx(ushort вт, uint cDims, sys.WinStructs.ГРАНБЕЗОПМАСА* rgsabound, void* pvExtra);
int SafeArrayCopyData(sys.WinStructs.БЕЗОПМАС* psaSource, sys.WinStructs.БЕЗОПМАС* psaTarget);
int SafeArrayDestroyDescriptor(sys.WinStructs.БЕЗОПМАС* psa);
int SafeArrayDestroyData(sys.WinStructs.БЕЗОПМАС* psa);
int SafeArrayDestroy(sys.WinStructs.БЕЗОПМАС* psa);
int SafeArrayRedim(sys.WinStructs.БЕЗОПМАС* psa, sys.WinStructs.ГРАНБЕЗОПМАСА* psaboundNew);
uint SafeArrayGetDim(sys.WinStructs.БЕЗОПМАС* psa);
uint SafeArrayGetElemsize(sys.WinStructs.БЕЗОПМАС* psa);
int SafeArrayGetUBound(sys.WinStructs.БЕЗОПМАС* psa, uint cDim, out int plUbound);
int SafeArrayGetLBound(sys.WinStructs.БЕЗОПМАС* psa, uint cDim, out int plLbound);
int SafeArrayLock(sys.WinStructs.БЕЗОПМАС* psa);
int SafeArrayUnlock(sys.WinStructs.БЕЗОПМАС* psa);
int SafeArrayAccessData(sys.WinStructs.БЕЗОПМАС* psa, void** ppvData);
int SafeArrayUnaccessData(sys.WinStructs.БЕЗОПМАС* psa);
int SafeArrayGetElement(sys.WinStructs.БЕЗОПМАС* psa, int* rgIndices, void* pv);
int SafeArrayPutElement(sys.WinStructs.БЕЗОПМАС* psa, int* rgIndices, void* pv);
int SafeArrayCopy(sys.WinStructs.БЕЗОПМАС* psa, out sys.WinStructs.БЕЗОПМАС* ppsaOut);
int SafeArrayPtrOfIndex(sys.WinStructs.БЕЗОПМАС* psa, int* rgIndices, void** ppvData);
int SafeArraySetRecordInfo(sys.WinStructs.БЕЗОПМАС* psa, sys.WinIfaces.IRecordInfo prinfo);
int SafeArrayGetRecordInfo(sys.WinStructs.БЕЗОПМАС* psa, out sys.WinIfaces.IRecordInfo prinfo);
int SafeArraySetIID(sys.WinStructs.БЕЗОПМАС* psa, ref sys.WinStructs.ГУИД guid);
int SafeArrayGetIID(sys.WinStructs.БЕЗОПМАС* psa, out sys.WinStructs.ГУИД pguid);
int SafeArrayGetVartype(sys.WinStructs.БЕЗОПМАС* psa, out ushort pvt);
sys.WinStructs.БЕЗОПМАС* SafeArrayCreateVector(ushort вт, int lLbound, uint cElements);
sys.WinStructs.БЕЗОПМАС* SafeArrayCreateVectorEx(ushort вт, int lLbound, uint cElements, void* pvExtra);

int VarDecFromUI4(uint ulIn, out sys.WinStructs.ДЕСЯТОК pdecOut);
int VarDecFromI4(int lIn, out sys.WinStructs.ДЕСЯТОК pdecOut);
int VarDecFromUI8(ulong ui64In, out sys.WinStructs.ДЕСЯТОК pdecOut);
int VarDecFromI8(long i64In, out sys.WinStructs.ДЕСЯТОК pdecOut);
int VarDecFromR4(float dlbIn, out sys.WinStructs.ДЕСЯТОК pdecOut);
int VarDecFromR8(double dlbIn, out sys.WinStructs.ДЕСЯТОК pdecOut);
int VarDecFromStr(in wchar* StrIn, uint lcid, uint dwFlags, out sys.WinStructs.ДЕСЯТОК pdecOut);
int VarBstrFromDec(ref sys.WinStructs.ДЕСЯТОК pdecIn, uint lcid, uint dwFlags, out wchar* pbstrOut);
int VarUI4FromDec(ref sys.WinStructs.ДЕСЯТОК pdecIn, out uint pulOut);
int VarI4FromDec(ref sys.WinStructs.ДЕСЯТОК pdecIn, out int plOut);
int VarUI8FromDec(ref sys.WinStructs.ДЕСЯТОК pdecIn, out ulong pui64Out);
int VarI8FromDec(ref sys.WinStructs.ДЕСЯТОК pdecIn, out long pi64Out);
int VarR4FromDec(ref sys.WinStructs.ДЕСЯТОК pdecIn, out float pfltOut);
int VarR8FromDec(ref sys.WinStructs.ДЕСЯТОК pdecIn, out double pdblOut);

int VarDecAdd(ref sys.WinStructs.ДЕСЯТОК pdecLeft, ref sys.WinStructs.ДЕСЯТОК pdecRight, out sys.WinStructs.ДЕСЯТОК pdecResult);
int VarDecSub(ref sys.WinStructs.ДЕСЯТОК pdecLeft, ref sys.WinStructs.ДЕСЯТОК pdecRight, out sys.WinStructs.ДЕСЯТОК pdecResult);
int VarDecMul(ref sys.WinStructs.ДЕСЯТОК pdecLeft, ref sys.WinStructs.ДЕСЯТОК pdecRight, out sys.WinStructs.ДЕСЯТОК pdecResult);
int VarDecDiv(ref sys.WinStructs.ДЕСЯТОК pdecLeft, ref sys.WinStructs.ДЕСЯТОК pdecRight, out sys.WinStructs.ДЕСЯТОК pdecResult);

int VarDecRound(ref sys.WinStructs.ДЕСЯТОК pdecIn, int cDecimals, out sys.WinStructs.ДЕСЯТОК pdecResult);
int VarDecAbs(ref sys.WinStructs.ДЕСЯТОК pdecIn, out sys.WinStructs.ДЕСЯТОК pdecResult);
int VarDecFix(ref sys.WinStructs.ДЕСЯТОК pdecIn, out sys.WinStructs.ДЕСЯТОК pdecResult);
int VarDecInt(ref sys.WinStructs.ДЕСЯТОК pdecIn, out sys.WinStructs.ДЕСЯТОК pdecResult);
int VarDecNeg(ref sys.WinStructs.ДЕСЯТОК pdecIn, out sys.WinStructs.ДЕСЯТОК pdecResult);
int VarDecCmp(ref sys.WinStructs.ДЕСЯТОК pdecLeft, out sys.WinStructs.ДЕСЯТОК pdecRight);

int VarBstrFromDec(sys.WinStructs.ДЕСЯТОК* pdecIn, uint lcid, uint dwFlags, out wchar* pbstrOut);
int VarR8FromDec(sys.WinStructs.ДЕСЯТОК* pdecIn, out double pdblOut);
int VarDecNeg(sys.WinStructs.ДЕСЯТОК* pdecIn, out sys.WinStructs.ДЕСЯТОК pdecResult);

void VariantInit(ref sys.WinStructs.ВАРИАНТ pvarg);
int VariantClear(ref sys.WinStructs.ВАРИАНТ pvarg);
int VariantCopy(ref sys.WinStructs.ВАРИАНТ pvargDest, ref sys.WinStructs.ВАРИАНТ pvargSrc);

int VarAdd(ref sys.WinStructs.ВАРИАНТ pvarLeft, ref sys.WinStructs.ВАРИАНТ pvarRight, out sys.WinStructs.ВАРИАНТ pvarResult);
int VarAnd(ref sys.WinStructs.ВАРИАНТ pvarLeft, ref sys.WinStructs.ВАРИАНТ pvarRight, out sys.WinStructs.ВАРИАНТ pvarResult);
int VarCat(ref sys.WinStructs.ВАРИАНТ pvarLeft, ref sys.WinStructs.ВАРИАНТ pvarRight, out sys.WinStructs.ВАРИАНТ pvarResult);
int VarDiv(ref sys.WinStructs.ВАРИАНТ pvarLeft, ref sys.WinStructs.ВАРИАНТ pvarRight, out sys.WinStructs.ВАРИАНТ pvarResult);
int VarMod(ref sys.WinStructs.ВАРИАНТ pvarLeft, ref sys.WinStructs.ВАРИАНТ pvarRight, out sys.WinStructs.ВАРИАНТ pvarResult);
int VarMul(ref sys.WinStructs.ВАРИАНТ pvarLeft, ref sys.WinStructs.ВАРИАНТ pvarRight, out sys.WinStructs.ВАРИАНТ pvarResult);
int VarOr(ref sys.WinStructs.ВАРИАНТ pvarLeft, ref sys.WinStructs.ВАРИАНТ pvarRight, out sys.WinStructs.ВАРИАНТ pvarResult);
int VarSub(ref sys.WinStructs.ВАРИАНТ pvarLeft, ref sys.WinStructs.ВАРИАНТ pvarRight, out sys.WinStructs.ВАРИАНТ pvarResult);
int VarXor(ref sys.WinStructs.ВАРИАНТ pvarLeft, ref sys.WinStructs.ВАРИАНТ pvarRight, out sys.WinStructs.ВАРИАНТ pvarResult);
int VarCmp(ref sys.WinStructs.ВАРИАНТ pvarLeft, ref sys.WinStructs.ВАРИАНТ pvarRight, uint lcid, uint dwFlags);

int VariantChangeType(ref sys.WinStructs.ВАРИАНТ pvargDest, ref sys.WinStructs.ВАРИАНТ pvarSrc, ushort wFlags, ushort вт);
int VariantChangeTypeEx(ref sys.WinStructs.ВАРИАНТ pvargDest, ref sys.WinStructs.ВАРИАНТ pvarSrc, uint lcid, ushort wFlags, ushort вт);

int SetErrorInfo(uint dwReserved, ИИнфОбОш perrinfo);
int GetErrorInfo(uint dwReserved, out ИИнфОбОш pperrinfo);
int CreateErrorInfo(out ИИнфОбОш pperrinfo);

int CoInitialize(void*);
void CoUninitialize();
int CoInitializeEx(void*, uint dwCoInit);

void* CoTaskMemAlloc(size_t cb);
void* CoTaskMemRealloc(void* pv, size_t cb);
void CoTaskMemFree(void* pv);
}

//////////////////////////////////////////

export extern(C)
{
бкрат СТАРШСЛОВО(цел l) { return cast(бкрат)((l >> 16) & 0xFFFF); }
бкрат МЛАДШСЛОВО(цел l) { return cast(бкрат)l; }
ббайт СТАРШБАЙТ(бкрат w) {  return cast(ббайт)((w >> 8) & 0xFF);}
ббайт МЛАДШБАЙТ(бкрат w) {  return cast(ббайт)(w & 0xFF);}
бул НЕУД(цел статус) { return статус < 0; }
бул УД(цел статус) { return статус >= 0; }

цел СДЕЛАЙИДЪЯЗ(ПЯзык p, ППодъяз s) { return ((cast(бкрат)s) << 10) | cast(бкрат)p; }
бкрат ПЕРВИЧНИДЪЯЗ(цел язид) { return cast(бкрат)(язид & 0x3ff); }
бкрат ИДПОДЪЯЗА(цел язид)     { return cast(бкрат)(язид >> 10); }
/+
WORD MAKELANGID(USHORT p, USHORT s) { return cast(WORD)((s << 10) | p); }
WORD PRIMARYLANGID(WORD lgid) { return cast(WORD)(lgid & 0x3FF); }
WORD SUBLANGID(WORD lgid) { return cast(WORD)(lgid >>> 10); }

DWORD MAKELCID(WORD lgid, WORD srtid) { return (cast(DWORD) srtid << 16) | cast(DWORD) lgid; }
// ???
//DWORD MAKESORTLCID(WORD lgid, WORD srtid, WORD ver) { return (MAKELCID(lgid, srtid)) | ((cast(DWORD)ver) << 20); }
WORD LANGIDFROMLCID(LCID lcid) { return cast(WORD) lcid; }
WORD SORTIDFROMLCID(LCID lcid) { return cast(WORD) ((lcid >>> 16) & 0x0F); }
WORD SORTVERSIONFROMLCID(LCID lcid) { return cast(WORD) ((lcid >>> 20) & 0x0F); }
+/

version(БигЭндиан)
{
	крат х8сбк(крат x)
	{
		return x;
	}
	
	
	цел х8сбц(цел x)
	{
		return x;
	}
}
else version(ЛитлЭндиан)
{
	
	бкрат х8сбк(бкрат x)
	{
		return cast(бкрат)((x >> 8) | (x << 8));
	}


	бцел х8сбц(бцел x)
	{
		return bswap(x);
	}
}
else
{
	static assert(0);
}


бкрат с8хбк(бкрат x)
{
	return х8сбк(x);
}


бцел с8хбц(бцел x)
{
	return х8сбц(x);
}

// Removes.
проц УД_УДАЛИ(СОКЕТ уд, sys.WinStructs.набор_уд* набор)
{
	бцел c = набор.счёт_уд;
	СОКЕТ* старт = набор.массив_уд.ptr;
	СОКЕТ* stop = старт + c;
	
	for(; старт != stop; старт++)
	{
		if(*старт == уд)
			goto found;
	}
	return; //not found
	
	found:
	for(++старт; старт != stop; старт++)
	{
		*(старт - 1) = *старт;
	}
	
	набор.счёт_уд = c - 1;
}


// Tests.
цел УД_УСТАНОВЛЕН(СОКЕТ уд, sys.WinStructs.набор_уд* набор)
{
	СОКЕТ* старт = набор.массив_уд.ptr;
	СОКЕТ* stop = старт + набор.счёт_уд;
	
	for(; старт != stop; старт++)
	{
		if(*старт == уд)
			return да;
	}
	return нет;
}


// Adds.
проц УД_УСТАНОВИ(СОКЕТ уд, sys.WinStructs.набор_уд* набор)
{
	бцел c = набор.счёт_уд;
	набор.массив_уд.ptr[c] = уд;
	набор.счёт_уд = c + 1;
}


// Resets to zero.
проц УД_ОБНУЛИ(sys.WinStructs.набор_уд* набор)
{
	набор.счёт_уд = 0;
}

///////////////
бул УстановиТекущуюПапкуА(ткст путь)
	{
	return cast(бул) SetCurrentDirectoryA(cast(LPCSTR) путь);
	}

бул УстановиТекущуюПапку(шткст путь)
	{
	ткст путь1 = toUTF8(путь);
	return cast(бул) SetCurrentDirectoryW(toUTF16z(путь1));
	}
////////////////////
бцел ДайТекущуюПапкуА(бцел длинаБуфера, ткст буфер)
	{
	return cast(бцел) GetCurrentDirectoryA(cast(DWORD) длинаБуфера, cast(LPSTR) буфер);
	}

бцел ДайТекущуюПапку(бцел длинаБуфера, шткст буфер)
	{
	ткст буф = toUTF8(буфер);
	return cast(бцел) GetCurrentDirectoryW(cast(DWORD) длинаБуфера, toUTF16z(буф));
	}
//////////////////

бул УдалиПапкуА(ткст путь)
	{
	return cast(бул) RemoveDirectoryA(cast(LPCSTR) путь);
	}

бул УдалиПапку(шткст путь)
	{
	ткст путь1 = toUTF8(путь);
	return cast(бул) RemoveDirectoryW(toUTF16z(путь1));
	}
////////////////

////////////////
бул НайдиЗакрой(ук найдиФайл)
	{
	return cast(бул)   FindClose(cast(HANDLE) найдиФайл);
	}
//////////
ук НайдиПервыйФайлА(in ткст фимя, sys.WinStructs.ПОИСК_ДАННЫХ_А* данныеПоискаФайла)
	{
	return cast(ук) FindFirstFileA(cast(сим *) фимя, cast(WIN32_FIND_DATA*) данныеПоискаФайла);
	}

ук НайдиПервыйФайл(in шткст фимя, sys.WinStructs.ПДАН* данныеПоискаФайла)
	{
	ткст ф = toUTF8(фимя);
	return cast(ук) FindFirstFileW(toUTF16z(ф), cast(WIN32_FIND_DATAW*) данныеПоискаФайла);
	}
////////////
бул НайдиСледующийФайлА(ук найдиФайл, sys.WinStructs.ПОИСК_ДАННЫХ_А* данныеПоискаФайла)
	{
	return cast(бул)   FindNextFileA(cast(HANDLE) найдиФайл, cast(WIN32_FIND_DATA*) данныеПоискаФайла);
	}

бул НайдиСледующийФайл(ук найдиФайл, sys.WinStructs.ПДАН* данныеПоискаФайла)
	{
	return cast(бул)   FindNextFileW(cast(HANDLE) найдиФайл, cast(WIN32_FIND_DATAW*) данныеПоискаФайла);
	}
////////////
бул ДайКодВыходаНити(ук нить, убцел кодВыхода)
	{
	return cast(бул)   GetExitCodeThread(cast(HANDLE) нить, cast(DWORD *) кодВыхода);
	}
///////////
бцел ДайПоследнююОшибку()
	{
	return cast(бцел)  GetLastError();
	}
////////////////
бцел ДайАтрибутыФайлаА(in ткст фимя)
	{
	return cast(бцел)  GetFileAttributesA(cast(сим *) фимя);
	}

бцел ДайАтрибутыФайла(in шткст фимя)
	{
	ткст ф = toUTF8(фимя);
	return cast(бцел)  GetFileAttributesW(toUTF16z(ф));
	}
/////////////
бцел ДайРазмерФайла(ук файл, убцел размерФайлаВ)
	{
	return cast(бцел)  GetFileSize(cast(HANDLE) файл, cast(DWORD *) размерФайлаВ);
	}
////////////////
бул ПереместиФайлА(in ткст откуда, in ткст куда)
	{
	return cast(бул)   MoveFileA(cast(char *) откуда, cast(char *) куда);
	}

бул ПереместиФайл(in шткст откуда, in шткст куда)
	{
	ткст сф = toUTF8(откуда);
	ткст нф = toUTF8(куда);
	return cast(бул)   MoveFileW(toUTF16z(сф), toUTF16z(нф));
	}
///////////////
бул ЧитайФайл(ук файл, ук буфер, бцел члоБайтДляЧит, бцел *члоСчитБайт, sys.WinStructs.АСИНХРОН *асинх)
	{
	return cast(бул)   ReadFile(cast(HANDLE) файл, cast(ук ) буфер, cast(DWORD) члоБайтДляЧит, cast(DWORD *) члоСчитБайт, cast(OVERLAPPED *) асинх);
	}
////////////
бцел УстановиУказательФайла(ук файл, цел дистанцияПереноса, уцел дистанцияПереносаВ, бцел методПереноса)
	{
	return cast(бцел)  SetFilePointer(cast(HANDLE) файл, cast(LONG) дистанцияПереноса, cast(LONG *) дистанцияПереносаВ, cast(DWORD) методПереноса);
	}
////////////////
бул ПишиФайл(ук файл, in ук буфер, бцел члоБайтДляЗаписи, убцел члоЗаписанБайт, sys.WinStructs.АСИНХРОН *асинх)
	{
	return cast(бул)   WriteFile(cast(HANDLE) файл, cast(ук ) буфер, cast(DWORD) члоБайтДляЗаписи, cast(DWORD *) члоЗаписанБайт, cast(OVERLAPPED *) асинх);
	}
///////////////////
бцел ДайИмяФайлаМодуляА(экз модуль, ткст *фимя, бцел размер)
	{
	return cast(бцел)  GetModuleFileNameA(cast(HMODULE) модуль, cast(LPSTR) фимя, cast(DWORD) размер);
	}
	
бцел ДайИмяФайлаМодуля(экз модуль, шткст *фимя, бцел размер)
	{
	return cast(бцел)  GetModuleFileNameW(cast(HMODULE) модуль, cast(LPWSTR) фимя, cast(DWORD) размер);
	}
/////////////////

экз ДайДескрМодуляА(ткст имя)
{
 return cast(экз) GetModuleHandleA(cast(LPCSTR) имя);
 }
 
экз ДайДескрМодуля(шткст имя)
{ 
ткст фимя = toUTF8(имя);
return cast(экз)GetModuleHandleW(cast(LPCWSTR) toUTF16z(фимя));
}
///////////////////////
ук ДайСтдДескр(ПСтд стдДескр)
	{
	return cast(ук) GetStdHandle(cast(DWORD) стдДескр);
	}
//////////////////
бул УстановиСтдДескр(ПСтд стдДескр, ук дескр)
	{
	return cast(бул)   SetStdHandle(cast(DWORD) стдДескр, cast(HANDLE) дескр);
	}
	
////////////

ук ЗагрузиБиблиотекуА(ткст имяФайлаБибл)
	{
	return cast(ук) LoadLibraryA(cast(LPCSTR) имяФайлаБибл);
	}
	
ук ЗагрузиБиблиотеку(шткст фимя){ return cast(ук) LoadLibraryW(cast(LPCWSTR) фимя);}
//////////////////
ук ЗагрузиБиблиотекуДопА(ткст фимя, ук файл, ПЗагрФлаг флаги){ return cast(ук) LoadLibraryExA(cast(LPCSTR) фимя, cast(HANDLE) файл, cast(DWORD) флаги);}

ук ЗагрузиБиблиотекуДоп(шткст фимя, ук файл, ПЗагрФлаг флаги){ return cast(ук) LoadLibraryExW(cast(LPCWSTR) фимя, cast(HANDLE)файл, cast(DWORD) флаги);}
///////////////////
ук ДайАдресПроц(ук модуль, ткст имяПроц)
	{
	return cast(ук) GetProcAddress(cast(HMODULE) модуль, cast(LPCSTR) имяПроц);
	}
////////////////////
бцел ДайВерсию()
	{
	return cast(бцел) GetVersion();
	}
///////////////////
бул ОсвободиБиблиотеку(ук библМодуль)
	{
	return cast(бул) FreeLibrary(cast(HMODULE) библМодуль);
	}
///////////////////////
проц ОсвободиБиблиотекуИВыйдиИзНити(ук библМодуль, бцел кодВыхода)
	{
	FreeLibraryAndExitThread(cast(HMODULE) библМодуль, cast(DWORD) кодВыхода);
	}
///////////////////

цел ОкноСообА(ук окно, ткст текст, ткст заголовок, ПСооб тип)
	{
	return cast(цел)  MessageBoxA(cast(HWND) окно, cast(LPCSTR) текст, cast(LPCSTR) заголовок, cast(UINT) тип);
	}

цел ОкноСооб(ук окно, шткст текст, шткст заголовок, ПСооб тип)
	{
	ткст ткс = toUTF8(текст);
	return cast(цел)  MessageBoxW(cast(HWND) окно, toUTF16z(ткс), cast(LPCWSTR) заголовок, cast(UINT) тип);
	}

цел ОкноСообДопА(ук окно, ткст текст, ткст заголовок, ПСооб тип, бкрат идЯзыка)
	{
	return cast(цел)  MessageBoxExA(cast(HWND) окно, cast(LPCSTR) текст, cast(LPCSTR) заголовок, cast(UINT) тип, cast(WORD) идЯзыка);
	}

цел ОкноСообДоп(ук окно, шткст текст, шткст заголовок, ПСооб тип, бкрат идЯзыка)
	{
	ткст ткс = toUTF8(текст);
	return cast(цел)  MessageBoxExW(cast(HWND) окно, toUTF16z(ткс), cast(LPCWSTR) заголовок, cast(UINT) тип, cast(WORD) идЯзыка);
	}
	
цел УдалиКлючРегА(ПКлючРег ключ, ткст подключ)
	{
	return cast(цел) RegDeleteKeyA(cast(HKEY) ключ, cast(LPCSTR) подключ);
	}

цел УдалиЗначениеРегА(ПКлючРег ключ, ткст имяЗнач)
	{
	return cast(цел) RegDeleteValueA(cast(HKEY) ключ, cast(LPCSTR) имяЗнач);
	}

цел ПеречислиКлючиРегДопА(ПКлючРег ключ, бцел индекс, ткст имя, убцел пкбИмя, убцел резерв, ткст класс, убцел пкбКласс, sys.WinStructs.ФВРЕМЯ *времяПоследнейЗаписи)
	{
	return cast(цел)  RegEnumKeyExA(cast(HKEY) ключ, cast(DWORD) индекс, cast(LPSTR) имя, cast(LPDWORD) пкбИмя, cast(LPDWORD) резерв, cast(LPSTR) класс, cast(LPDWORD) пкбКласс, cast(FILETIME*) времяПоследнейЗаписи);
	}

цел ПеречислиЗначенияРегА(ПКлючРег ключ, бцел индекс, ткст имяЗнач, убцел пкбИмяЗнач, убцел резерв, убцел тип, уббайт данные, убцел пкбДанные)
	{
	return cast(цел) RegEnumValueA(cast(HKEY) ключ,cast(DWORD) индекс, cast(LPSTR) имяЗнач, cast(LPDWORD) пкбИмяЗнач, cast(LPDWORD) резерв, cast(LPDWORD) тип, cast(LPBYTE) данные, cast(LPDWORD) пкбДанные);
	}

цел ЗакройКлючРег(ПКлючРег ключ){return cast(цел) RegCloseKey(cast(HKEY) ключ);}

цел ПодсветиКлючРег(ПКлючРег ключ){return cast(цел) RegFlushKey(cast(HKEY) ключ);}

цел ОткройКлючРегА(ПКлючРег ключ, ткст подключ, ук *результат)
	{
	return cast(цел) RegOpenKeyA(cast(HKEY) ключ, cast(LPCSTR) подключ, cast(PHKEY) результат);
	}

цел ОткройКлючРегДопА(ПКлючРег ключ, ткст подключ, ПРеестр опции, бцел желательно, ук *результат)
	{
	return cast(цел) RegOpenKeyExA(cast(HKEY) ключ, cast(LPCSTR) подключ,cast(DWORD) опции, cast(REGSAM) желательно, cast(PHKEY) результат);
	}

цел ЗапросиИнфОКлючеРегА(ПКлючРег ключ, ткст класс, убцел пкбКласс, убцел резерв, убцел подключи, убцел максДлинаПодключа, убцел пкбМаксДлинаКласса, убцел значения, убцел пкбМаксДлинаИмениЗначения, убцел пкбМаксДлинаЗначения, убцел пкбДескрБезоп, sys.WinStructs.ФВРЕМЯ *времяПоследнейЗаписи)
	{
	return cast(цел) RegQueryInfoKeyA(cast(HKEY) ключ, cast(LPSTR) класс, cast(LPDWORD) пкбКласс, cast(LPDWORD) резерв, cast(LPDWORD) подключи, cast(LPDWORD) максДлинаПодключа, cast(LPDWORD) пкбМаксДлинаКласса,  cast(LPDWORD) значения, cast(LPDWORD) пкбМаксДлинаИмениЗначения, cast(LPDWORD) пкбМаксДлинаЗначения, cast(LPDWORD) пкбДескрБезоп, cast(PFILETIME) времяПоследнейЗаписи);
	}

цел ЗапросиЗначениеРегА(ПКлючРег ключ, ткст подключ, ткст значение, уцел пкбЗначение)
	{
	return cast(цел) RegQueryValueA(cast(HKEY) ключ, cast(LPCSTR) подключ, cast(LPSTR) значение, cast(LPLONG) пкбЗначение);	}

цел СоздайКлючРегДопА(ПКлючРег ключ, ткст подключ, бцел резерв, ткст класс, ПРеестр опции, бцел желательно, sys.WinStructs.БЕЗАТРЫ *безАтры, ук *результат, убцел расположение) 
	{
	return cast(цел) RegCreateKeyExA(cast(HKEY) ключ, cast(LPCSTR) подключ,cast(DWORD) резерв, cast(LPSTR) класс, cast(DWORD) опции, cast(REGSAM) желательно, cast(SECURITY_ATTRIBUTES*) безАтры, cast(PHKEY) результат, cast(LPDWORD) расположение);
	}	

цел УстановиЗначениеРегДопА(ПКлючРег ключ, ткст имяЗначения, бцел резерв, ПРеестр тип, уббайт данные, бцел кбДанные)
	{
	return cast(цел) RegSetValueExA(cast(HKEY)ключ, cast(LPCSTR) имяЗначения,cast(DWORD) резерв,cast(DWORD) тип, cast(BYTE*) данные,cast(DWORD) кбДанные);
	}
	

бул ОсвободиРесурс(гук данныеРес)
	{
	return cast(бул)  FreeResource(cast(HGLOBAL) данныеРес);
	}

гук БлокируйРесурс(гук данныеРес)
	{
	return cast(гук) LockResource(cast(HGLOBAL) данныеРес);
	}
	
гук РазместиГлоб(ППамять флаги , бцел байты){return cast(гук) GlobalAlloc(cast(UINT) флаги , cast(DWORD) байты);}

гук ПереместиГлоб(гук укз, т_мера байты, ППамять флаги){return cast(гук) GlobalReAlloc(cast(HGLOBAL) укз, cast(DWORD) байты, cast(UINT) флаги);}

т_мера РазмерГлоб(гук укз){return cast(т_мера) GlobalSize(cast(HGLOBAL) укз);}
бцел ФлагиГлоб(гук укз){return cast(бцел) GlobalFlags(cast(HGLOBAL) укз );}
ук БлокируйГлоб(гук укз){return cast(ук) GlobalLock(cast(HGLOBAL) укз);}

гук ХэндлГлоб(ук пам){return cast(гук) GlobalHandle(cast(LPCVOID) пам);}

бул  РазблокируйГлоб(гук пам)
	{
	return cast(бул) GlobalUnlock(cast(HGLOBAL) пам);
	}

гук  ОсвободиГлоб(гук пам)
	{
	return cast(гук) GlobalFree(cast(HGLOBAL) пам);
	}

бцел СожмиГлоб(бцел минОсвоб)
	{
	return cast(бцел) GlobalCompact(cast(DWORD) минОсвоб);
	}

проц ФиксируйГлоб(гук пам)
	{
	return GlobalFix(cast(HGLOBAL) пам);
	}

проц РасфиксируйГлоб(гук пам)
	{
	return GlobalUnfix(cast(HGLOBAL) пам);
	}
	
ук ВяжиГлоб(гук пам)
	{
	return cast(ук) GlobalWire(cast(HGLOBAL) пам);
	}

бул ОтвяжиГлоб(гук пам)
	{
	return cast(бул) GlobalUnWire(cast(HGLOBAL) пам);
	}

проц СтатусГлобПамяти(sys.WinStructs.СТАТПАМ *буф)
	{
	GlobalMemoryStatus(cast(LPMEMORYSTATUS) буф);
	}
	

/+	
проц СтатусГлобПамятиДоп(sys.WinStructs.СТАТПАМДОП *буф)
	{
	GlobalMemoryStatus(cast(LPMEMORYSTATUSEX) буф);
	}
+/

лук РазместиЛок(ППамять флаги, бцел байты)
	{
	return cast(лук) LocalAlloc(cast(UINT) флаги, cast(UINT) байты);
	}

лук ПереместиЛок(лук пам, бцел байты, ППамять флаги)
	{
	return cast(лук) LocalReAlloc(cast(HLOCAL) пам, cast(UINT) байты, cast(UINT) флаги);
	}

ук БлокируйЛок(лук пам)
	{
	return cast(ук) LocalLock(cast(HLOCAL) пам);
	}

лук ХэндлЛок(ук пам)
	{
	return cast(лук) LocalHandle(cast(LPCVOID) пам);
	}

бул РазблокируйЛок(лук пам)
	{
	return cast(бул) LocalUnlock(cast(HLOCAL) пам);
	}

т_мера РазмерЛок(лук пам)
	{
	return cast(т_мера) LocalSize(cast(HLOCAL) пам);
	}

бцел ФлагиЛок(лук пам)
	{
	return cast(бцел) LocalFlags(cast(HLOCAL) пам);
	}

лук ОсвободиЛок(лук пам)
	{
	return cast(лук) LocalFree(cast(HLOCAL) пам);
	}

бцел РасширьЛок(лук пам, бцел новРазм)
	{
	return cast(бцел) LocalShrink(cast(HLOCAL) пам,cast(UINT) новРазм);
	}

бцел СожмиЛок(бцел минОсв)
	{
	return cast(бцел) LocalCompact(cast(UINT) минОсв);
	}

бул СлейКэшИнструкций(ук процесс, ук адрБаз, бцел разм)
	{
	return cast(бул) FlushInstructionCache(cast(HANDLE) процесс, cast(LPCVOID) адрБаз, cast(DWORD) разм);
	}

ук РазместиВирт(ук адрес, бцел разм, ППамять типРазмещения, бцел защита)
	{
	return cast(ук) VirtualAlloc(cast(LPVOID) адрес, cast(DWORD) разм, cast(DWORD) типРазмещения, cast(DWORD) защита);
	}

бул ОсвободиВирт(ук адрес, бцел разм, ППамять типОсвобождения)
	{
	return cast(бул) VirtualFree(cast(LPVOID) адрес, cast(DWORD) разм, cast(DWORD) типОсвобождения);
	}

бул ЗащитиВирт(ук адр, бцел разм, бцел новЗащ, убцел старЗащ)
	{
	return cast(бул) VirtualProtect(cast(LPVOID) адр, cast(DWORD) разм, cast(DWORD) новЗащ,cast(PDWORD) старЗащ);
	}

бцел ОпросиВирт(ук адр, sys.WinStructs.БАЗИОП *буф, бцел длина)
	{
	return cast(бцел) VirtualQuery(cast(LPCVOID) адр, cast(PMEMORY_BASIC_INFORMATION) буф, cast(DWORD) длина);
	}

ук РазместиВиртДоп(ук процесс, ук адрес, бцел разм, ППамять типРазмещ, бцел защита)
	{
	return cast(ук) VirtualAllocEx(cast(HANDLE) процесс, cast(LPVOID) адрес, cast(DWORD) разм, cast(DWORD) типРазмещ, cast(DWORD) защита);
	}

бул ОсвободиВиртДоп(ук процесс, ук адр, бцел разм, ППамять типОсвоб)
	{
	return cast(бул) VirtualFreeEx(cast(HANDLE) процесс, cast(LPVOID) адр, cast(DWORD) разм, cast(DWORD) типОсвоб);
	}

бул ЗащитиВиртДоп(ук процесс, ук адр, бцел разм, бцел новЗащ, убцел старЗащ)
	{
	return cast(бул) VirtualProtectEx(cast(HANDLE) процесс, cast(LPVOID) адр, cast(DWORD) разм, cast(DWORD) новЗащ, cast(PDWORD) старЗащ);
	}

бцел ОпросиВиртДоп(ук процесс, ук адр, sys.WinStructs.БАЗИОП *буф, бцел длина)
	{
	return cast(бцел) VirtualQueryEx(cast(HANDLE) процесс, cast(LPCVOID) адр, cast(PMEMORY_BASIC_INFORMATION) буф, cast(DWORD) длина);
	}
	
//проц КопируйПамять(ук куда, ук откуда, т_мера длина)
//{ RtlCopyMemory(  cast(PVOID) куда,  cast(VOID*) откуда,  длина);}

проц ЗаполниПамять(ук куда, т_мера длина, ббайт зап){ RtlFillMemory( cast(PVOID) куда,  длина, cast(BYTE) зап);}

//т_мера ДайМинимумБСтраницы() {return cast(т_мера) GetLargePageMinimum();}

бцел ДайОбзорЗаписи(ППамять флаги, in ук базАдр, in т_мера размРег, ук* адры, inout бцел* счёт, out бцел* гранулярность){return cast(бцел) GetWriteWatch(  cast(DWORD) флаги,  cast(PVOID) базАдр, размРег, cast(PVOID*) адры,  cast(PULONG_PTR) счёт,  cast(PULONG) гранулярность);}

бцел СбросьОбзорЗаписи(ук базАдр, т_мера размРег){ return cast(бцел) ResetWriteWatch( cast(LPVOID) базАдр, размРег);}

бул ПлохойУкНаКод_ли(ук проц){return cast(бул) IsBadCodePtr(cast(FARPROC) проц);}

бул ПлохойЧтенУк_ли(ук первБайтБлока, бцел размБлока){return cast(бул) IsBadReadPtr(cast(LPVOID) первБайтБлока, cast(UINT) размБлока);}

бул ПлохойЗапУк_ли(ук первБайтБлока, бцел размБлока){return cast(бул) IsBadWritePtr(cast(LPVOID) первБайтБлока, cast(UINT) размБлока);}
//{return cast(бул) IsBadHugeReadPtr(LPVOID, UINT);}
//{return cast(бул) IsBadHugeWritePtr(cast(LPVOID), UINT);}

бул ПлохойСтрУк_ли(усим т, бцел разм){return cast(бул) IsBadStringPtrA(cast(LPCSTR) т , cast(UINT) разм);}

бул ПлохойШСтрУк_ли(ушим т, бцел разм){return cast(бул) IsBadStringPtrW(cast(LPCWSTR)т, cast(UINT) разм);}

проц ПереместиПамять(ук куда, ук откуда, т_мера длина){ RtlMoveMemory( cast(PVOID) куда,  cast(VOID*) откуда, длина);}

//ук ОбнулиПамятьБезоп(ук укз, т_мера разм){return cast(ук) RtlSecureZeroMemory( cast(PVOID) укз, разм);}

проц ОбнулиПамять(ук где, т_мера разм){RtlZeroMemory(  cast(PVOID) где, разм);}


ук ДайКучуПроцесса(){return cast(ук) GetProcessHeap();}
	
бцел ДайКучиПроцесса(бцел члоКуч, out ук *укз){return cast(бцел) GetProcessHeaps(cast(DWORD) члоКуч, cast(HANDLE*) укз);}
	
ук СоздайКучу(ППамять опц, т_мера начРазм, т_мера максРазм){return cast(ук) HeapCreate(cast(DWORD) опц, cast(DWORD) начРазм, cast(DWORD) максРазм);}
бул УдалиКучу(ук укз){return cast(бул) HeapDestroy(cast(HANDLE) укз);}
ук РазместиКучу(ук куча, ППамять флаги, т_мера байты){return cast(ук) HeapAlloc(cast(HANDLE) куча, cast(DWORD) флаги, cast(DWORD) байты);}
ук ПереместиКучу(ук куча, ППамять флаги, ук блок, т_мера байты){return cast(ук) HeapReAlloc(cast(HANDLE) куча, cast(DWORD) флаги, cast(LPVOID) блок, cast(DWORD) байты);}
бул ОсвободиКучу(ук куча, ППамять флаги, ук блок){return cast(бул) HeapFree(cast(HANDLE) куча, cast(DWORD) флаги, cast(LPVOID) блок);}
бцел РазмерКучи(ук укз, ППамять флаги, ук блок ){return cast(бцел) HeapSize(cast(HANDLE) укз, cast(DWORD) флаги, cast(LPCVOID) блок);}
бул ПроверьКучу(ук укз, ППамять флаги, ук блок ){return cast(бул) HeapValidate(cast(HANDLE) укз, cast(DWORD) флаги, cast(LPCVOID) блок);}
бцел СожмиКучу(ук укз, ППамять флаги){ return cast(бцел) HeapCompact(cast(HANDLE) укз, cast(DWORD) флаги);}
бул БлокируйКучу(ук укз){return cast(бул) HeapLock(cast(HANDLE) укз);}
бул РазблокируйКучу(ук укз){return cast(бул) HeapUnlock(cast(HANDLE) укз);}
бул ОбойдиКучу(ук укз, ЗАППРОЦКУЧ* зап) {return cast(бул) HeapWalk(cast(HANDLE) укз, cast(LPPROCESS_HEAP_ENTRY) зап);}

бул ЗапросиИнфОКуче (ук куча, бцел клинф, ук инф, т_мера длинаклинф, т_мера* длвозвр){ return cast(бул) HeapQueryInformation(cast(HANDLE) куча,  клинф, cast(PVOID) инф, длинаклинф, длвозвр);}

бул УстановиИнфОКуче(ук куча, бцел клинф, ук кинф, т_мера длкинф){return cast(бул) HeapSetInformation( cast(HANDLE) куча, клинф, cast(PVOID) кинф, длкинф);}

проц ДайСистВремя(sys.WinStructs.СИСТВРЕМЯ* систВрем)
	{
	GetSystemTime(cast(SYSTEMTIME*) систВрем);
	}

бул ДайФВремя(ук файл, sys.WinStructs.ФВРЕМЯ *времяСоздания, sys.WinStructs.ФВРЕМЯ *времяПоследнегоДоступа, sys.WinStructs.ФВРЕМЯ *времяПоследнейЗаписи)
	{
	return cast(бул) GetFileTime(cast(HANDLE) файл, cast(FILETIME*) времяСоздания, cast(FILETIME*) времяПоследнегоДоступа, cast(FILETIME*) времяПоследнейЗаписи);
	}

проц ДайСистВремяКакФВремя(sys.WinStructs.ФВРЕМЯ* сисВремКакФВрем)
	{
	GetSystemTimeAsFileTime(cast(FILETIME*)  сисВремКакФВрем);
	}

бул УстановиСистВремя(sys.WinStructs.СИСТВРЕМЯ* систВрем)
	{
	return cast(бул) SetSystemTime(cast(SYSTEMTIME*) систВрем);
	}

бул УстановиФВремя(ук файл, in sys.WinStructs.ФВРЕМЯ *времяСоздания, in sys.WinStructs.ФВРЕМЯ *времяПоследнДоступа, in sys.WinStructs.ФВРЕМЯ *времяПоследнЗаписи)
	{
	return cast(бул) SetFileTime(cast(HANDLE) файл, cast(FILETIME*) времяСоздания, cast(FILETIME*) времяПоследнДоступа, cast(FILETIME*) времяПоследнЗаписи);
	}

проц ДайМестнВремя(sys.WinStructs.СИСТВРЕМЯ *систВремя)
	{
	GetLocalTime(cast(SYSTEMTIME*) систВремя);
	}
	
бул УстановиМестнВремя(sys.WinStructs.СИСТВРЕМЯ *систВремя)
	{
	return cast(бул) SetLocalTime(cast(SYSTEMTIME*) систВремя);
	}

бул СистВремяВМестнВремяЧП(ИНФОЧП *инфОЧасПоясе, sys.WinStructs.СИСТВРЕМЯ *мировВремя, sys.WinStructs.СИСТВРЕМЯ *местнВремя)
	{
	return cast(бул) SystemTimeToTzSpecificLocalTime(cast(TIME_ZONE_INFORMATION*) инфОЧасПоясе, cast(SYSTEMTIME*) мировВремя, cast(SYSTEMTIME*) местнВремя);
	}

бцел ДайИнфОЧП(ИНФОЧП *инфОЧП)
	{
	return cast(бцел) GetTimeZoneInformation(cast(TIME_ZONE_INFORMATION*) инфОЧП);
	}

бул УстановиИнфОЧП(ИНФОЧП *инфОЧП)
	{
	return cast(бул) SetTimeZoneInformation(cast(TIME_ZONE_INFORMATION*) инфОЧП);
	}

бул СистВремяВФВремя(in sys.WinStructs.СИСТВРЕМЯ *систВрем, sys.WinStructs.ФВРЕМЯ *фВрем)
	{
	return cast(бул) SystemTimeToFileTime(cast(SYSTEMTIME*) систВрем, cast(FILETIME*) фВрем);
	}

бул ФВремяВМестнФВремя(in sys.WinStructs.ФВРЕМЯ *фВрем, sys.WinStructs.ФВРЕМЯ *местнФВрем)
	{
	return cast(бул) FileTimeToLocalFileTime(cast(FILETIME*) фВрем, cast(FILETIME*) местнФВрем);
	}

бул МестнФВремяВФВремя(in sys.WinStructs.ФВРЕМЯ *локФВрем, sys.WinStructs.ФВРЕМЯ *фВрем)
	{
	return cast(бул) LocalFileTimeToFileTime(cast(FILETIME*) локФВрем, cast(FILETIME*) фВрем);
	}

бул ФВремяВСистВремя(in sys.WinStructs.ФВРЕМЯ *фВрем, sys.WinStructs.СИСТВРЕМЯ *систВрем)
	{
	return cast(бул) FileTimeToSystemTime(cast(FILETIME*) фВрем, cast(SYSTEMTIME*) систВрем);
	}

бул ФВремяВДатВремяДОС(in sys.WinStructs.ФВРЕМЯ *фвр, убкрат фатДата, убкрат фатВремя)
	{
	return cast(бул) FileTimeToDosDateTime(cast(FILETIME*) фвр, cast(WORD*) фатДата, cast(WORD*) фатВремя);
	}

бул ДатВремяДОСВФВремя(бкрат фатДата,  бкрат фатВремя, sys.WinStructs.ФВРЕМЯ *фвр)
	{
	return cast(бул) DosDateTimeToFileTime(cast(WORD) фатДата, cast(WORD) фатВремя, cast(FILETIME*) фвр);
	}

бцел ДайСчётТиков()
	{
	return cast(бцел) GetTickCount();
	}

бул УстановиНастрСистВремени(бцел настройкаВрем, бул настВремОтключена)
	{
	return cast(бул) SetSystemTimeAdjustment(cast(DWORD) настройкаВрем, cast(BOOL) настВремОтключена);
	}

бул ДайНастрСистВремени(убцел настрВрем, убцел инкВрем, бул* настрВремОтключена)
	{
	return cast(бул) GetSystemTimeAdjustment(cast(DWORD*) настрВрем, cast(DWORD*) инкВрем, cast(BOOL*) настрВремОтключена);
	}

бцел ФорматируйСообА(ПФорматСооб флаги, ук исток, бцел идСооб, бцел идЯз, ткст буф, бцел разм, ук* арги)
	{
	return cast(бцел) FormatMessageA(cast(DWORD) флаги, cast(LPCVOID) исток, cast(DWORD) идСооб, cast(DWORD) идЯз, cast(LPSTR) буф, cast(DWORD) разм, cast(ук*) арги);
	}

бцел ФорматируйСооб(ПФорматСооб флаги, ук исток, бцел идСооб, бцел идЯз, шткст буф, бцел разм, ук* арги)
	{
	ткст буф1 = toUTF8(буф);
	return cast(бцел) FormatMessageW(cast(DWORD) флаги, cast(LPCVOID) исток, cast(DWORD) идСооб, cast(DWORD) идЯз, toUTF16z(буф1), cast(DWORD) разм, cast(ук*) арги);
	}
	
ук ДайТекущуюНить()
	{
	return cast(ук) GetCurrentThread();
	}

бул ДайВременаПроцесса(ук процесс, sys.WinStructs.ФВРЕМЯ *времяСозд, sys.WinStructs.ФВРЕМЯ *времяВыхода, sys.WinStructs.ФВРЕМЯ *времяЯдра, sys.WinStructs.ФВРЕМЯ *времяПользователя)
	{
	return cast(бул) GetProcessTimes(cast(HANDLE) процесс, cast(FILETIME*) времяСозд, cast(FILETIME*) времяВыхода, cast(FILETIME*) времяЯдра, cast(FILETIME*) времяПользователя);
	}

ук ДайТекущийПроцесс()
	{
	return  cast(ук) GetCurrentProcess();
	}

бцел ДайИдТекущегоПроцесса()
	{
	return cast(бцел) GetCurrentProcessId();
	}

бул ДублируйДескр(ук исходнПроц, ук исходнНить, ук хендлПроцЦели, ук *цхендл, ППраваДоступа доступ, бул наследоватьДескр, бцел опции)
	{
	return cast(бул) DuplicateHandle(cast(HANDLE) исходнПроц, cast(HANDLE) исходнНить,  cast(HANDLE) хендлПроцЦели, cast(HANDLE*) цхендл, cast(DWORD) доступ, cast(BOOL) наследоватьДескр, cast(DWORD) опции);
	}

бцел ДайЛокальНити() {return GetThreadLocale();} 
	
бцел ДайИдТекущейНити()
	{
	return cast(бцел) GetCurrentThreadId();
	}

бул УстановиПриоритетНити(ук нить, ППриоритетНити приоритет)
	{
	return cast(бул) SetThreadPriority(cast(HANDLE) нить, cast(int) приоритет);
	}

бул УстановиПовышениеПриоритетаНити(ук нить, бул отклПовышениеПриоритета)
	{
	return cast(бул) SetThreadPriorityBoost(cast(HANDLE) нить, cast(Бул) отклПовышениеПриоритета);
	}

бул ДайПовышениеПриоритетаНити(ук нить, бул *отклПовышениеПриоритета)
	{
	return cast(бул) GetThreadPriorityBoost(cast(HANDLE) нить, cast(Бул*) отклПовышениеПриоритета);
	}

бул ДайВременаНити(ук нить, sys.WinStructs.ФВРЕМЯ *времяСозд, sys.WinStructs.ФВРЕМЯ *времяВыхода, sys.WinStructs.ФВРЕМЯ *времяЯдра, sys.WinStructs.ФВРЕМЯ *времяПользователя)
	{
	return cast(бул) GetThreadTimes(cast(HANDLE) нить, cast(FILETIME*) времяСозд, cast(FILETIME*) времяВыхода, cast(FILETIME*) времяЯдра, cast(FILETIME*) времяПользователя);
	}

цел ДайПриоритетНити(ук нить)
	{
	return cast(цел) GetThreadPriority(cast(HANDLE) нить);
	}

бул ДайКонтекстНити(ук нить, sys.WinStructs.КОНТЕКСТ *контекст)
	{
	return cast(бул) GetThreadContext(cast(HANDLE) нить, cast(CONTEXT*) контекст);
	}

бул УстановиКонтекстНити(ук нить, sys.WinStructs.КОНТЕКСТ *контекст)
	{
	return cast(бул) SetThreadContext(cast(HANDLE) нить, cast(CONTEXT*) контекст);
	}

бцел ЗаморозьНить(ук нить)
	{
	return cast(бцел) SuspendThread(cast(HANDLE) нить);
	}

бцел  РазморозьНить(ук нить)
	{
	return cast(бцел) ResumeThread(cast(HANDLE) нить);
	}

бцел ЖдиОдинОбъект(ук хендл, бцел миллисекк)
	{
	return cast(бцел) WaitForSingleObject(cast(HANDLE) хендл, cast(DWORD) миллисекк);
	}

бцел ЖдиНесколькоОбъектов(бцел счёт, ук *хендлы, бул ждатьВсе, бцел миллисекк)
	{
	return cast(бцел) WaitForMultipleObjects(cast(DWORD) счёт, cast(HANDLE *) хендлы, cast(BOOL) ждатьВсе, cast(DWORD) миллисекк);
	}

проц Спи(бцел миллисекк)
	{
	 Sleep(cast(DWORD) миллисекк);
	}
 //////
цел БлокированныйИнкремент( цел * увеличиваемое)
	{
	return cast(цел)  InterlockedIncrement(cast(LPLONG) увеличиваемое);
	}

цел БлокированныйДекремент( цел * уменьшаемое)
	{
	return cast(цел)  InterlockedDecrement(cast(LPLONG) уменьшаемое);
	}

цел БлокированныйОбмен( цел * цель, цел значение)
	{
	return cast(цел)  InterlockedExchange(cast(LPLONG) цель, cast(LONG) значение);
	}

цел БлокированныйОбменДобавка( цел * добавляемое, цел значение)
	{
	return cast(цел) InterlockedExchangeAdd(cast(LPLONG) добавляемое, cast(LONG) значение);
	}

ук БлокированныйОбменСравнение(ук *цель, ук обмен, ук сравниваемое)
	{
	return cast(ук) InterlockedCompareExchange(cast(PVOID *) цель, cast(PVOID) обмен, cast(PVOID) сравниваемое);
	}

проц ИнициализуйКритическуюСекцию(sys.WinStructs.КРИТСЕКЦ *критСекц)
	{
	InitializeCriticalSection(cast(CRITICAL_SECTION *) критСекц);
	}

проц ВойдиВКритическуюСекцию(sys.WinStructs.КРИТСЕКЦ *критСекц)
	{
	EnterCriticalSection(cast(CRITICAL_SECTION *) критСекц);
	}

бул ПробуйВойтиВКритическуюСекцию(sys.WinStructs.КРИТСЕКЦ *критСекц)
	{
	return cast(бул) TryEnterCriticalSection(cast(CRITICAL_SECTION *) критСекц);
	}

проц ПокиньКритическуюСекцию(sys.WinStructs.КРИТСЕКЦ *критСекц)
	{
	LeaveCriticalSection(cast(CRITICAL_SECTION *) критСекц);
	}

бул ОпросиСчётчикПроизводительности(дол *счПроизв)
	{
	return cast(бул) QueryPerformanceCounter(cast(дол*) счПроизв);
	}

бул ОпросиЧастотуПроизводительности(дол *частота)
	{
	return cast(бул) QueryPerformanceFrequency(cast(дол*) частота);
	}

ук ОткройМаппингФайлаА(ППамять желДоступ, бул наследовать, ткст имяМаппинга){return cast(ук) OpenFileMappingA(cast(DWORD) желДоступ, cast(BOOL) наследовать, cast(LPCSTR) имяМаппинга);}

ук ОткройМаппингФайла(ППамять желДоступ, бул наследовать, шткст имяМаппинга){return cast(ук) OpenFileMappingW(cast(DWORD) желДоступ, cast(BOOL) наследовать, cast(LPCWSTR) имяМаппинга);}

/*
Бул GetMailslotInfo(ук hMailslot, бцел* lpMaxMessageSize, бцел* lpNextSize, бцел* lpMessageCount, бцел* lpReadTimeout);
Бул SetMailslotInfo(ук hMailslot, бцел lReadTimeout);*/

ук ВидФайлаВКарту(ук объектФМап, ППамять желатДоступ, бцел фСмещВ, бцел фСмещН, бцел члоБайтовДляМап)
{
return cast(ук) MapViewOfFile(cast(HANDLE) объектФМап, cast(бцел) желатДоступ, cast(бцел) фСмещВ,cast(бцел) фСмещН,cast(бцел) члоБайтовДляМап);
}

ук ВидФайлаВКартуДоп(ук объектФМап, ППамять желатДоступ, бцел фСмещВ, бцел фСмещН, бцел члоБайтовДляМап, ук адрОвы)
	{
	return cast(ук) MapViewOfFileEx(cast(HANDLE) объектФМап, cast(бцел) желатДоступ, cast(бцел) фСмещВ,cast(бцел) фСмещН,cast(бцел) члоБайтовДляМап, cast(ук) адрОвы);
	}

бул СлейВидФайла(ук адрОвы, бцел члоСливБайт){return cast(бул) FlushViewOfFile(cast(ук) адрОвы,cast(бцел) члоСливБайт);}

бул ВидФайлаИзКарты(ук адрОвы){return cast(бул) UnmapViewOfFile(cast(ук) адрОвы);}
/*
 HGDIOBJ   GetStockObject(цел);
Бул ShowWindow(ук hWnd, цел nCmdShow);*/

проц СлейБуферыФайла(ук файлУк){FlushFileBuffers(cast(HANDLE) файлУк);}

бцел ДайТипФайла(ук файлУк){return cast(бцел)  GetFileType(cast(HANDLE) файлУк);}
	
 бул ОбновиОкно(ук ок){return cast(бул) UpdateWindow(cast(HWND) ок);}
 
 ук УстановиАктивноеОкно(ук ок){return cast(ук) SetActiveWindow(cast(HWND) ок);}
 
 ук ДайФоновоеОкно(){return cast(ук) GetForegroundWindow();}
 
 бул РисуйРабСтол(ук ку){return cast(бул) PaintDesktop(cast(HDC) ку);}
 
 бул УстановиФоновоеОкно(ук ок){return cast(бул) SetForegroundWindow(cast(HWND) ок);}
 
 ук ОкноИзКУ(ук ку){return cast(ук) WindowFromDC(cast(HDC) ку);}
 
 ук ДайКУ(ук ок){return cast(ук) GetDC(cast(HWND) ок);}
 
 ук ДайКУДоп(ук ок, ук регКлип, ПФлагКУДоп флаги){return cast(ук) GetDCEx(cast(HWND) ок, cast(HRGN) регКлип,cast(DWORD) флаги);}
 
 ук ДайКУОкна(ук ок){return cast(ук) GetWindowDC(cast(HWND) ок);}
 
 цел ОтпустиКУ(ук ок, ук ку){return cast(цел) ReleaseDC(cast(HWND) ок, cast(HDC) ку);}
 
 ук НачниРис(ук ок, РИССТРУКТ* рис){return cast(ук) BeginPaint(cast(HWND) ок, cast(LPPAINTSTRUCT) рис);}
 
 бул ЗавершиРис(ук ок, РИССТРУКТ * рис){return cast(бул) EndPaint(cast(HWND) ок, cast(LPPAINTSTRUCT) рис);} 
 
  бул ДайПрямОбнова(ук ок, ПРЯМ *пр, бул стереть){return cast(бул) GetUpdateRect(cast(HWND) ок,cast(LPRECT) пр, cast(Бул) стереть);}
  
  цел ДайРгнОбнова(ук ок, ук ргн, бул стереть){return GetUpdateRgn(cast(HWND) ок, cast(HRGN) ргн, cast(Бул) стереть);}
  
  цел УстановиРгнОкна(ук ок, ук рг, бул перерисовать){return  SetWindowRgn(cast(HWND) ок, cast(HRGN) рг, cast(Бул) перерисовать);}
  
  цел ДайРгнОкна(ук ок, ук ргн){return GetWindowRgn(cast(HWND) ок, cast(HRGN) ргн);}
  
  цел ИсключиРгнОбнова(ук ку, ук ок){return ExcludeUpdateRgn(cast(HDC) ку, cast(HWND) ок);}
  
  бул ИнвалидируйПрям(ук ок, ПРЯМ *пр, бул стереть){return cast(бул) InvalidateRect(cast(HWND) ок, cast(LPRECT) пр, cast(Бул) стереть);}
  
  бул ВалидируйПрям(ук ок, ПРЯМ *пр){return cast(бул) ValidateRect(cast(HWND) ок, cast(LPRECT) пр);}
  
  бул ИнвалидируйРгн(ук ок, ук ргн, бул стереть){return cast(бул) InvalidateRgn(cast(HWND) ок, cast(HRGN) ргн, cast(Бул) стереть);}
  
  бул ВалидируйРгн(ук ок, ук ргн){return cast(бул) ValidateRgn(cast(HWND) ок, cast(HRGN) ргн);}
  
  бул ПерерисуйОкно(ук ок, ПРЯМ *обн, ук ргнОб, бцел фОкПерерис){return cast(бул) RedrawWindow(cast(HWND) ок, cast(LPRECT) обн, cast(HRGN) ргнОб, cast(UINT) фОкПерерис);}
  
	
	цел ВСАСтарт(крат требВерсия, ВИНСОКДАН* всадан)
		{
		return  WSAStartup(cast(WORD) требВерсия, cast(LPWSADATA) всадан);
		}
		
	цел ВСАЧистка(){return  WSACleanup();}
	
	цел ВСАДайПоследнююОшибку(){return WSAGetLastError();}
	
	СОКЕТ сокет(ПСемействоАдресов са, ПТипСок тип, ППротокол протокол)
		{
		return cast(СОКЕТ) socket(cast(цел) са, cast(цел) тип, cast(цел) протокол);
		}
		
	цел ввктлсок(СОКЕТ с, цел кмд, бцел* аргук)
		{
		return  ioctlsocket(cast(SOCKET) с, кмд, аргук);
		}
		
	цел свяжисок(СОКЕТ с, sys.WinStructs.адрессок* имя, цел длинаим)
		{
		return  bind(cast(SOCKET) с, cast(sockaddr*) имя, длинаим);
		}
		
	цел подключи(СОКЕТ с, sys.WinStructs.адрессок* имя, цел длинаим)
		{
		return  connect(cast(SOCKET) с, cast(sockaddr*) имя, длинаим);
		}
		
	цел слушай(СОКЕТ с, цел бэклог)
		{
		return  listen(cast(SOCKET) с, бэклог);
		}
		
	СОКЕТ пусти(СОКЕТ с, sys.WinStructs.адрессок* адр,  цел * длинадр)
		{
		return cast(СОКЕТ) accept(cast(SOCKET) с, cast(sockaddr*) адр, cast(int*) длинадр);
		}
		
	цел закройсок(СОКЕТ с){return  closesocket(cast(SOCKET) с);}
	
	цел экстрзак(СОКЕТ с, ПЭкстрЗакрытиеСокета как){return  shutdown(cast(SOCKET) с, cast(цел) как);}
	
	
	цел дайимяпира(СОКЕТ с, sys.WinStructs.адрессок* имя,  цел * длинаим)
		{
		return  getpeername(cast(SOCKET) с, cast(sockaddr*) имя, cast(int*) длинаим);
		}
		
	цел дайимясок(СОКЕТ с, sys.WinStructs.адрессок* адр,  цел * длинаим)
		{
		return  getsockname(cast(SOCKET) с, cast(sockaddr*) адр, cast(int*) длинаим);
		}
		
	цел шли(СОКЕТ с, ук буф, цел длин, ПФлагиСокета флаги)
		{
		return  send(cast(SOCKET) с, буф, длин, cast(int) флаги);
		}
		
	цел шли_на(СОКЕТ с, ук буф, цел длин, ПФлагиСокета флаги, sys.WinStructs.адрессок* кому, цел длинаприём)
		{
		return sendto(cast(SOCKET) с, буф, длин, cast(цел) флаги, cast(sockaddr*) кому, длинаприём);
		}
		
	цел прими(СОКЕТ с, ук буф, цел длин, ПФлагиСокета флаги)
		{
		return recv(cast(SOCKET) с, буф, длин, cast(цел) флаги);
		}
		
	цел прими_от(СОКЕТ с, ук буф, цел длин, ПФлагиСокета флаги, sys.WinStructs.адрессок* от_кого,  цел * длинаистока)
		{
		return  recvfrom(cast(SOCKET) с, буф, длин, cast(цел) флаги, cast(sockaddr*) от_кого, cast(int*) длинаистока);
		}
		
	цел дайопцсок(СОКЕТ с, цел уровень, цел имяопц, ук значопц,  цел * длинаопц)
		{
		return  getsockopt(cast(SOCKET) с, уровень, имяопц, значопц, cast(int*) длинаопц);
		}
		
	цел установиопцсок(СОКЕТ с, цел уровень, цел имяопц, ук значопц, цел длинаопц)
		{
		return setsockopt(cast(SOCKET) с, уровень, имяопц, значопц, длинаопц);
		}
		
	бцел адр_инет(ткст т){return  inet_addr(cast(char*) т);}
	
	цел выбери(цел нуд, sys.WinStructs.набор_уд* читнуд, sys.WinStructs.набор_уд* запнуд, sys.WinStructs.набор_уд* ошнуд, sys.WinStructs.значврем* таймаут)
		{
		return select(нуд, cast(fd_set*) читнуд, cast(fd_set*) запнуд, cast(fd_set*) ошнуд, cast(timeval*) таймаут);
		}
		
	ткст инетс8а(sys.WinStructs.адрес_ин иа){return std.string.toString(inet_ntoa(cast(in_addr) иа));}
	
	sys.WinStructs.хостзап* дайхостпоимени(ткст имя){return cast(sys.WinStructs.хостзап*) gethostbyname(cast(char*) имя);}
	
	sys.WinStructs.хостзап* дайхостпоадресу(ук адр, цел длин, цел тип)
		{
		return cast(sys.WinStructs.хостзап*) gethostbyaddr(адр, длин, cast(цел) тип);
		}
		
	sys.WinStructs.протзап* дайпротпоимени(ткст имя){return cast(sys.WinStructs.протзап*) getprotobyname(cast(char*) имя);}
	
	sys.WinStructs.протзап* дайпротпономеру(цел номер){return cast(sys.WinStructs.протзап*) getprotobynumber(cast(int) номер);}
	
	
	sys.WinStructs.служзап* дайслужбупоимени(ткст имя, ткст протокол)
		{
		return cast(sys.WinStructs.служзап*) getservbyname(cast(char*) имя, cast(char*) протокол);
		}
		
	sys.WinStructs.служзап* дайслужбупопорту(цел порт, ткст протокол)
		{
		return cast(sys.WinStructs.служзап*) getservbyport(порт, cast(char*) протокол);
		}
		
	цел дайимяхоста(ткст имя, цел длинаим){return  gethostname(cast(char*) имя, длинаим);}
	
	цел дайадринфо(ткст имяузла, ткст имяслуж, sys.WinStructs.адринфо* хинты, sys.WinStructs.адринфо** рез)
		{
		return  getaddrinfo(cast(char*) имяузла, cast(char*) имяслуж, cast(addrinfo*) хинты, cast(addrinfo**) рез);
		}
		
	проц высвободиадринфо(sys.WinStructs.адринфо* аи){freeaddrinfo(cast(addrinfo*) аи);}
	
	цел дайинфобимени(sys.WinStructs.адрессок* ас, т_длинсок длинсок, ткст хост, бцел длинхост, ткст серв, бцел длинсерв, ПИмИнфо флаги)
		{
		return  getnameinfo(cast(sockaddr*) ас, длинсок, cast(char*) хост, cast(DWORD) длинхост, cast(char*) серв, cast(DWORD) длинсерв, cast(int) флаги);
		}
		
	ушим ДайКомСтроку(){return GetCommandLineW();}
 
	ушим* КомСтрокаВАрги(ушим ш, уцел н){ return CommandLineToArgvW(ш, н);}
 
	цел ШирСимВМультиБайт(ПКодСтр кодСтр, ПШирСим флаги, ушим укШирСим, цел члоСимШир, сим* укНовСтрБуф, цел размНовСтрБуф, сим* симНекартДефАдр, бул адрФлага)
	{
	return WideCharToMultiByte(cast(UINT) кодСтр, cast(DWORD) флаги, cast(LPCWSTR) укШирСим, члоСимШир, cast(LPSTR) укНовСтрБуф , размНовСтрБуф, cast(LPCSTR) симНекартДефАдр, cast(LPBOOL) адрФлага);
	}
	
	//цел MultiByteToWideChar(UINT, cast(DWORD), cast(LPCSTR), цел, cast(LPWSTR), цел);}

 
	бцел РазместиНлх(){ return cast(бцел) TlsAlloc();}
  
	ук ДайЗначениеНлх(бцел з){ return cast(ук) TlsGetValue(cast(DWORD) з);}
  
	бул УстановиЗначениеНлх(бцел з, ук укз){ return cast(бул) TlsSetValue(cast(DWORD) з, cast(LPVOID)укз);}
  
	бул ОсвободиНлх(бцел з){ return cast(бул) TlsFree(cast(DWORD) з);}  
 
	проц ПокиньПроцесс(бцел кодВыхода){ExitProcess(кодВыхода);}
 
	бул ДайКодВыходаПроцесса( ук процесс, out бцел* код){return cast(бул) GetExitCodeProcess(cast(HANDLE) процесс, cast(LPDWORD) код);} 
	
	бул СоздайПроцессПользователяА(ук токен, ткст назвПрил, ткст комСтр, БЕЗАТРЫ* атрыПроц, БЕЗАТРЫ* атрыНити, бул наследоватьДескрипторы, ПФлагСоздПроц создПроцФлаги, ук блокСреды, ткст текПап, ИНФОСТАРТА* стартИнф, ИНФОПРОЦ* инфОПроц)
	{
	return cast(бул) CreateProcessAsUserA(cast(HANDLE) токен, cast(LPCTSTR) назвПрил, cast(LPTSTR) комСтр, cast(LPSECURITY_ATTRIBUTES) атрыПроц, cast(LPSECURITY_ATTRIBUTES) атрыНити, cast(BOOL) наследоватьДескрипторы, cast(DWORD) создПроцФлаги, cast(LPVOID) блокСреды, cast(LPCTSTR) текПап, cast(LPSTARTUPINFO) стартИнф, cast(LPPROCESS_INFORMATION) инфОПроц);
	}
	
	бул СоздайПроцессПользователя(ук токен, шткст назвПрил, шткст комСтр, БЕЗАТРЫ* атрыПроц, БЕЗАТРЫ* атрыНити, бул наследоватьДескрипторы, ПФлагСоздПроц создПроцФлаги, ук блокСреды, шткст текПап, ИНФОСТАРТА* стартИнф, ИНФОПРОЦ* инфОПроц)
	{
	ткст назвПрил2 = toUTF8(назвПрил);
	ткст комСтр2 = toUTF8(комСтр);
	ткст текПап2 = toUTF8(текПап);
	return cast(бул) CreateProcessAsUserW(cast(HANDLE) токен, cast(LPCWSTR) toUTF16z(назвПрил2), cast(LPWSTR) toUTF16z(комСтр2), cast(LPSECURITY_ATTRIBUTES) атрыПроц, cast(LPSECURITY_ATTRIBUTES) атрыНити, cast(BOOL) наследоватьДескрипторы, cast(DWORD) создПроцФлаги, cast(LPVOID) блокСреды, cast(LPCWSTR) toUTF16z(текПап2), cast(LPSTARTUPINFO) стартИнф, cast(LPPROCESS_INFORMATION) инфОПроц);
	}
	
	бцел ВерсияПостройкиКо()	{	return cast(бцел) CoBuildVersion();	}
	
	цел ТкстИзГУИД2(sys.WinStructs.ГУИД *удгуид, шткст уш, цел кбМакс)
	{
	return cast(цел) StringFromGUID2(cast(GUID*) удгуид, cast(LPOLESTR) уш, cast(цел) кбМакс);
	}

	цел ИнициализуйКо(ук резерв)	{	return cast(цел) CoInitialize(cast(ук) резерв);	}
	цел ИнициализуйКоДоп(ук резерв, ПИницКо флаг){return cast(цел) CoInitializeEx(резерв, cast(бцел) флаг);}
	
	проц ДеинициализуйКо()	{	CoUninitialize();	}
	бцел ДайТекущийПроцессКо()	{return cast(бцел)  CoGetCurrentProcess();	}

//import sys.win32..objbase;
	
	цел СоздайГуидКо(out sys.WinStructs.ГУИД уГуид)
	{
	return cast(цел) CoCreateGuid( уГуид);
	}
	
	цел ПрогИДИзКЛСИД(sys.WinStructs.ГУИД клсид, out шим* прогИд){return  ProgIDFromCLSID( клсид, прогИд );}
	
    цел КЛСИДИзПрогИД(in шим* прогИд, out sys.WinStructs.ГУИД клсид){return  CLSIDFromProgID(прогИд, клсид);}
	
    цел КЛСИДИзПрогИДДоп(in шим* прогИд, out sys.WinStructs.ГУИД клсид){return CLSIDFromProgIDEx(прогИд, клсид);}
	
	цел СоздайЭкземплярКо(sys.WinStructs.ГУИД рклсид, sys.WinIfaces.Инкогнито анонВнешн, бцел контекстКл, sys.WinStructs.ГУИД риид, ук* ув)
		{
		return cast(цел) CoCreateInstance(рклсид, анонВнешн,  контекстКл,  риид,  ув);
		}

	цел ДайОбъектКлассаКо(sys.WinStructs.ГУИД рклсид, бцел контекстКл, ук резерв, sys.WinStructs.ГУИД риид, ук* ув)
		{
		return cast(цел) CoGetClassObject( рклсид, контекстКл, резерв,  риид, ув);
		}

	цел СоздайЭкземплярКоДоп(ref sys.WinStructs.ГУИД рклсид, sys.WinIfaces.Инкогнито анонВнешн, бцел контекстКл, sys.WinStructs.КОСЕРВЕРИНФО* сервИнф, бцел счёт, sys.WinStructs.МУЛЬТИ_ОИ* результы)
		{
		return cast(цел) CoCreateInstanceEx( рклсид, анонВнешн, контекстКл,  сервИнф, счёт,  результы);
		}	
		
	ук РазместиПамЗадачиКо(т_мера разм){return CoTaskMemAlloc(разм);}
    ук ПереместиПамЗадачиКо(ук вв, т_мера разм){return  CoTaskMemRealloc(вв, разм);}
    проц ОсвободиПамЗадачиКо(ук в){CoTaskMemFree(в);}

	цел РегистрируйАктивныйОбъект(sys.WinIfaces.Инкогнито инк, ref sys.WinStructs.ГУИД клсид, бцел флаги, out бцел рег)
		{
		return  RegisterActiveObject(инк,  клсид, флаги, рег);
		}
		
	цел РевоцируйАктивныйОбъект(бцел рег, ук резерв){return  RevokeActiveObject(рег, резерв);}
	
	цел ДайАктивныйОбъект(ref sys.WinStructs.ГУИД клсид, ук резерв, out sys.WinIfaces.Инкогнито инк)
		{
		return  GetActiveObject( клсид, резерв, инк);
		}
		
цел РазместиДескрипторБезопмаса(бцел члоИзм, out sys.WinStructs.БЕЗОПМАС* укнаВыв)
	{
	return cast(цел) SafeArrayAllocDescriptor(члоИзм,  укнаВыв);
	}

цел РазместиДескрипторБезопмасаДоп(бкрат вт, бцел члоИзм, out sys.WinStructs.БЕЗОПМАС* укнаВыв)
	{
	return cast(цел) SafeArrayAllocDescriptorEx( вт,  члоИзм, укнаВыв);
	}

цел РазместиДанныеБезопмаса(sys.WinStructs.БЕЗОПМАС* бм)
	{
	return cast(цел) SafeArrayAllocData( бм);
	}

sys.WinStructs.БЕЗОПМАС* СоздайБезопмас(бкрат вт, бцел члоИзм, sys.WinStructs.ГРАНБЕЗОПМАСА* бмГран)
	{
	return cast(sys.WinStructs.БЕЗОПМАС*) SafeArrayCreate( вт, члоИзм,  бмГран);
	}
	
sys.WinStructs.БЕЗОПМАС* СоздайБезопмасДоп(бкрат вт, бцел члоИзм, sys.WinStructs.ГРАНБЕЗОПМАСА* бмГран, ук вЭкстра)
	{
	return cast(sys.WinStructs.БЕЗОПМАС*) SafeArrayCreateEx( вт,  члоИзм,  бмГран, вЭкстра);
	}
	
цел КопируйДанныеБезопмаса(sys.WinStructs.БЕЗОПМАС* бмИсх, sys.WinStructs.БЕЗОПМАС* бмПрий)
	{
	return cast(цел) SafeArrayCopyData( бмИсх,  бмПрий);
	}

цел УничтожьДескрипторБезопмаса(sys.WinStructs.БЕЗОПМАС* бм)
	{
	return cast(цел) SafeArrayDestroyDescriptor( бм);
	}

цел УничтожьДанныеБезопмаса(sys.WinStructs.БЕЗОПМАС* бм)
	{
	return cast(цел) SafeArrayDestroyData(бм);
	}

цел УничтожьБезопмас(sys.WinStructs.БЕЗОПМАС* бм)
	{
	return cast(цел) SafeArrayDestroy( бм);
	}

цел ИзмениГраницуБезопмаса(sys.WinStructs.БЕЗОПМАС* бм, sys.WinStructs.ГРАНБЕЗОПМАСА* бмНовГран)
	{
	return cast(цел) SafeArrayRedim( бм, бмНовГран);
	}

бцел ДайЧлоИзмеренийБезопмаса(sys.WinStructs.БЕЗОПМАС* бм)
	{
	return cast(бцел) SafeArrayGetDim( бм);
	}

бцел ДайРазмерЭлементовБезопмаса(sys.WinStructs.БЕЗОПМАС* бм)
	{
	return cast(бцел) SafeArrayGetElemsize( бм);
	}

цел ДайВПределБезопмаса(sys.WinStructs.БЕЗОПМАС* бм, бцел члоИзм, out цел вПредел)
	{
	return cast(цел) SafeArrayGetUBound( бм, cast(бцел) члоИзм,  вПредел);
	}

цел ДайНПределБезопмаса(sys.WinStructs.БЕЗОПМАС* бм, бцел члоИзм, out цел нПредел)
	{
	return cast(цел) SafeArrayGetLBound( бм, члоИзм, нПредел);
	}

цел БлокируйБезопмас(sys.WinStructs.БЕЗОПМАС* бм)
	{
	return cast(цел) SafeArrayLock(бм);
	}

цел РазблокируйБезопмас(sys.WinStructs.БЕЗОПМАС* бм)
	{
	return cast(цел) SafeArrayUnlock( бм);
	}

цел ДоступКДаннымБезопмаса(sys.WinStructs.БЕЗОПМАС* бм, ук* данные)
	{
	return cast(цел) SafeArrayAccessData( бм, данные);
	}

цел ОтступОтДаныхБезопмаса(sys.WinStructs.БЕЗОПМАС* бм)
	{
	return cast(цел) SafeArrayUnaccessData( бм);
	}

цел ДайЭлементБезопмаса(sys.WinStructs.БЕЗОПМАС* бм,  цел * индексы, ук в)
	{
	return cast(цел) SafeArrayGetElement( бм,  cast(цел*) индексы,  в);
	}
	
цел ПоместиЭлементВБезопмас(sys.WinStructs.БЕЗОПМАС* бм,  цел * индексы, ук в)
	{
	return cast(цел) SafeArrayPutElement( бм,  cast(цел*) индексы,  в);
	}

цел КопируйБезопмас(sys.WinStructs.БЕЗОПМАС* бм, out sys.WinStructs.БЕЗОПМАС* бмВыв)
	{
	return cast(цел) SafeArrayCopy( бм, бмВыв);
	}

цел УкНаИндексБезопмаса(sys.WinStructs.БЕЗОПМАС* бм,  цел * индексы, ук* данные)
	{
	return cast(цел) SafeArrayPtrOfIndex( бм,  cast(цел*) индексы, данные);
	}

цел УстИнфОЗаписиБезопмаса(sys.WinStructs.БЕЗОПМАС* бм, sys.WinIfaces.ИИнфОЗаписи инфоз)
	{
	return cast(цел) SafeArraySetRecordInfo( бм,  инфоз);
	}

цел ДайИнфОЗаписиБезопмаса(sys.WinStructs.БЕЗОПМАС* бм, out sys.WinIfaces.ИИнфОЗаписи инфоз)
	{
	return cast(цел) SafeArrayGetRecordInfo( бм,  инфоз);
	}

цел УстановиИИДБезопмаса(sys.WinStructs.БЕЗОПМАС* бм, ref sys.WinStructs.ГУИД гуид)
	{
	return cast(цел) SafeArraySetIID( бм,  гуид);
	}

цел ДайИИДБезопмаса(sys.WinStructs.БЕЗОПМАС* бм, out sys.WinStructs.ГУИД гуид)
	{
	return cast(цел) SafeArrayGetIID( бм, гуид);
	}

цел ДайВартипБезопмаса(sys.WinStructs.БЕЗОПМАС* бм, бкрат вт)
	{
	return cast(цел) SafeArrayGetVartype( бм,  вт);
	}

sys.WinStructs.БЕЗОПМАС* СоздайВекторБезопмаса(бкрат вт, цел нПредел, бцел элементы)
	{
	return cast(sys.WinStructs.БЕЗОПМАС*) SafeArrayCreateVector( вт,  нПредел, элементы);
	}

sys.WinStructs.БЕЗОПМАС* СоздайВекторБезопмасаДоп(бкрат вт, цел нПредел, бцел элементы, ук экстра)
	{
	return cast(sys.WinStructs.БЕЗОПМАС*) SafeArrayCreateVectorEx( вт, нПредел,  элементы,  экстра);
	}
///////////////////////////////

цел ДесВарИзБцел(бцел бцВхо, out sys.WinStructs.ДЕСЯТОК десВых)
	{
	return cast(цел) VarDecFromUI4(бцВхо, десВых);
	}

цел ДесВарИзЦел(цел цВхо, out sys.WinStructs.ДЕСЯТОК десВых)
	{
	return cast(цел) VarDecFromI4(цВхо, десВых);
	}

цел ДесВарИзБдол(бдол бдВхо, out sys.WinStructs.ДЕСЯТОК десВых)
	{
		return cast(цел) VarDecFromUI8(бдВхо, десВых);
	}

цел ДесВарИзДол(дол дВхо, out sys.WinStructs.ДЕСЯТОК десВых)
	{
		return cast(цел) VarDecFromI8(дВхо,  десВых);
	}
	

цел ДесВарИзПлав(плав вх, out sys.WinStructs.ДЕСЯТОК дес)
	{	
		return VarDecFromR4(вх,  дес);
	}
		
цел ДесВарИзДво(дво вх, out sys.WinStructs.ДЕСЯТОК дес)
	{
		return VarDecFromR8(вх,  дес);
	}

цел ДесВарИзТкстш0(in шим* ткс, бцел лкид, бцел флаги, out sys.WinStructs.ДЕСЯТОК дес)
	{
	return VarDecFromStr(ткс, лкид, cast(бцел) флаги,  дес);
	}
/*
цел БткстВарИзДес(ref sys.WinStructs.ДЕСЯТОК дес, бцел лкид, бцел флаги, out шим* стр)
	{
	return VarBstrFromDec( дес,лкид, cast(бцел) флаги, стр);
	}
*/	
цел БткстВарИзДес(ref sys.WinStructs.ДЕСЯТОК *дес, бцел лкид, бцел флаги, out шим* стр)
	{
	return VarBstrFromDec( дес, лкид, cast(бцел) флаги, стр);
	}
	
цел БцелВарИзДес(ref sys.WinStructs.ДЕСЯТОК дес, out бцел ц)
	{
	return VarUI4FromDec( дес, ц);
	}
	
цел ЦелВарИзДес(ref sys.WinStructs.ДЕСЯТОК дес, out цел зн )
	{
	return VarI4FromDec( дес, зн);
	}
	
цел БдолВарИзДес(ref sys.WinStructs.ДЕСЯТОК дес, out бдол зн)
	{
	return VarUI8FromDec( дес, зн);
	}
	
цел ДолВарИзДес(ref sys.WinStructs.ДЕСЯТОК дес, out дол зн)
	{	
	return VarI8FromDec( дес, зн);
	}
	
цел ПлавВарИзДес(ref sys.WinStructs.ДЕСЯТОК дес, out плав зн)
	{
	return VarR4FromDec( дес, зн);
	}
/*	
цел ДвоВарИзДес(ref sys.WinStructs.ДЕСЯТОК дес, out дво зн)
	{
	return VarR8FromDec( дес, зн);
	}
*/	
цел ДвоВарИзДес(sys.WinStructs.ДЕСЯТОК *дес, out дво зн)
	{
	return VarR8FromDec( дес, зн);
	}

	цел ДесВарСложи(ref sys.WinStructs.ДЕСЯТОК дес1, ref sys.WinStructs.ДЕСЯТОК дес2, out sys.WinStructs.ДЕСЯТОК рез)
		{
		return VarDecAdd( дес1,  дес2,  рез);
		}
		
	цел ДесВарОтними(ref sys.WinStructs.ДЕСЯТОК дес1, ref sys.WinStructs.ДЕСЯТОК дес2, out sys.WinStructs.ДЕСЯТОК рез)
		{
		return VarDecSub( дес1,  дес2,  рез);
		}
		
	цел ДесВарУмножь(ref sys.WinStructs.ДЕСЯТОК дес1, ref sys.WinStructs.ДЕСЯТОК дес2, out sys.WinStructs.ДЕСЯТОК рез)
		{
		return VarDecMul( дес1,  дес2,  рез);
		}
		
	цел ДесВарДели(ref sys.WinStructs.ДЕСЯТОК дес1, ref sys.WinStructs.ДЕСЯТОК дес2, out sys.WinStructs.ДЕСЯТОК рез)
		{
		return VarDecDiv( дес1,  дес2,  рез);
		}
		
	цел ДесВарОкругли(ref sys.WinStructs.ДЕСЯТОК дес1, цел дес, out sys.WinStructs.ДЕСЯТОК рез)
	{
	return VarDecRound( дес1, дес,  рез);
	}
	
	цел ДесВарАбс(ref sys.WinStructs.ДЕСЯТОК дес1,  out sys.WinStructs.ДЕСЯТОК рез)
	{
	return VarDecAbs( дес1,  рез);
	}
	
	цел  ДесВарФиксируй(ref sys.WinStructs.ДЕСЯТОК дес1,  out sys.WinStructs.ДЕСЯТОК рез)
	{
	return VarDecFix( дес1,  рез);
	}
	
	цел ДесВарИнт(ref sys.WinStructs.ДЕСЯТОК дес1,  out sys.WinStructs.ДЕСЯТОК рез)
	{
	return VarDecInt( дес1,  рез);
	}
	/*
	цел  ДесВарОтриц(ref sys.WinStructs.ДЕСЯТОК дес1, out sys.WinStructs.ДЕСЯТОК рез)
	{
	return VarDecNeg( дес1,  рез);
	}
	*/
	цел  ДесВарОтриц(sys.WinStructs.ДЕСЯТОК *дес1, out sys.WinStructs.ДЕСЯТОК рез)
	{
	return VarDecNeg( дес1,  рез);
	}
	
	цел ДесВарСравни(ref sys.WinStructs.ДЕСЯТОК дес1, out sys.WinStructs.ДЕСЯТОК рез)
	{
	return VarDecCmp( дес1,  рез);
	}
/*
   
цел VarFormat(ref sys.WinStructs.ВАРИАНТ pvarIn, in шим* pstrFormat, цел iFirstDay, цел iFirstWeek, бцел dwFlags, out шим* pbstrOut);
цел VarFormatFromTokens(ref sys.WinStructs.ВАРИАНТ pvarIn, in шим* pstrFormat, byte* pbTokCur, бцел dwFlags, out шим* pbstrOut, бцел лкид);
цел VarFormatNumber(ref sys.WinStructs.ВАРИАНТ pvarIn, цел iNumDig, цел ilncLead, цел iUseParens, цел iGroup, бцел dwFlags, out шим* pbstrOut);
*/
проц ИницВариант(ref sys.WinStructs.ВАРИАНТ вар){VariantInit( вар);}
цел СотриВариант(ref sys.WinStructs.ВАРИАНТ вар){return cast(цел) VariantClear( вар);}
цел КопируйВариант(ref sys.WinStructs.ВАРИАНТ варгЦель, ref sys.WinStructs.ВАРИАНТ варгИст)
	{
	return cast(цел) VariantCopy( варгЦель,  варгИст);
	}

цел СложиВар(ref sys.WinStructs.ВАРИАНТ варЛев, ref sys.WinStructs.ВАРИАНТ варПрав, out sys.WinStructs.ВАРИАНТ варРез)
    {
	return cast(цел) VarAdd( варЛев,  варПрав,  варРез);
	}
	
цел ИВар(ref sys.WinStructs.ВАРИАНТ варЛев, ref sys.WinStructs.ВАРИАНТ варПрав, out sys.WinStructs.ВАРИАНТ варРез)
	{
	return cast(цел) VarAnd( варЛев,  варПрав,  варРез);
	}
	
цел СоединиВар(ref sys.WinStructs.ВАРИАНТ варЛев, ref sys.WinStructs.ВАРИАНТ варПрав, out sys.WinStructs.ВАРИАНТ варРез)
	{
	return cast(цел) VarCat( варЛев,  варПрав,  варРез); 
	}
	
цел ДелиВар(ref sys.WinStructs.ВАРИАНТ варЛев, ref sys.WinStructs.ВАРИАНТ варПрав, out sys.WinStructs.ВАРИАНТ варРез)
	{
	return cast(цел) VarDiv( варЛев,  варПрав,  варРез);
	}
	
цел УмножьВар(ref sys.WinStructs.ВАРИАНТ варЛев, ref sys.WinStructs.ВАРИАНТ варПрав, out sys.WinStructs.ВАРИАНТ варРез)
	{
	return cast(цел) VarMul( варЛев,  варПрав,  варРез);
	}
	
цел ИлиВар(ref sys.WinStructs.ВАРИАНТ варЛев, ref sys.WinStructs.ВАРИАНТ варПрав, out sys.WinStructs.ВАРИАНТ варРез)
	{
	return cast(цел) VarOr( варЛев,  варПрав,  варРез);
	}
	
цел ОтнимиВар(ref sys.WinStructs.ВАРИАНТ варЛев, ref sys.WinStructs.ВАРИАНТ варПрав, out sys.WinStructs.ВАРИАНТ варРез)
	{
	return cast(цел) VarSub( варЛев,  варПрав,  варРез);
	}
	
цел ИИлиВар(ref sys.WinStructs.ВАРИАНТ варЛев, ref sys.WinStructs.ВАРИАНТ варПрав, out sys.WinStructs.ВАРИАНТ варРез)
	{
	return cast(цел) VarXor( варЛев,  варПрав,  варРез);
	}
	
цел СравниВар(ref sys.WinStructs.ВАРИАНТ варЛев, ref sys.WinStructs.ВАРИАНТ варПрав, бцел лкид, бцел флаги)
	{
	return cast(цел) VarCmp( варЛев,  варПрав, cast(бцел) лкид, cast(бцел) флаги);
	}

цел МодВар(ref sys.WinStructs.ВАРИАНТ варЛев, ref sys.WinStructs.ВАРИАНТ варПрав, out sys.WinStructs.ВАРИАНТ варРез)
	{
	return cast(цел) VarMod( варЛев,  варПрав,  варРез);
	}
	
шим* СисРазместиТкст(in шим* ш){return  SysAllocString(ш);}
цел СисПереместиТкст(шим* а, in шим* ш){return  SysReAllocString(а, ш);}
шим* СисРазместиТкстДлин(in шим* ш, бцел длин){return  SysAllocStringLen(ш, длин);}
цел СисПереместиТкстДлин(шим* а, in шим* ш, бцел длин){return  SysReAllocStringLen(а, ш, длин);}
проц СисОсвободиТкст(шим* т){ SysFreeString(т);}
бцел СисТкстДлин(шим* ш){return  SysStringLen(ш);}
бцел СисТкстБайтДлин(шим* т){return  SysStringByteLen(т);}
шим* СисРазместиТкстБайтДлин(in ббайт* ш, бцел длин){return  SysAllocStringByteLen(ш, длин);}

цел УстановиИнфОбОш(бцел резерв, ИИнфОбОш ошинф){return  SetErrorInfo(резерв, ошинф);}
цел ДайИнфОбОш(бцел резерв, ИИнфОбОш ошинф){return  GetErrorInfo(резерв,  ошинф);}
цел СоздайИнфОбОш(out ИИнфОбОш ошинф){return  CreateErrorInfo(ошинф);}


цел ИзмениТипВарианта(ref sys.WinStructs.ВАРИАНТ приёмник, ref sys.WinStructs.ВАРИАНТ источник, ПВар флаги, бкрат вт )
	{
	return  VariantChangeType( приёмник,  источник, cast(бкрат) флаги, вт);
	}
	
цел ИзмениТипВариантаДоп(ref sys.WinStructs.ВАРИАНТ приёмник, ref sys.WinStructs.ВАРИАНТ источник, бцел лкид, ПВар флаги, бкрат вт)
	{
	return  VariantChangeTypeEx( приёмник,  источник, лкид, cast(бкрат) флаги, вт);
	}
	
 ///////нет в импорте 

/*
бул СоздайПроцессПодЛогином(ушим имяПользователя, ушим домен, ушим пароль, бцел логинфлаги, ушим назвПрил, ушим комстр, ПФлагСоздПроц флагиСозд, ук среда, ушим текПап, ИНФОСТАРТА* инфост, ПРОЦИНФО* процинфо)
	{
	return cast(бул)  CreateProcessWithLogonW( cast(LPCWSTR) имяПользователя, cast(LPCWSTR) домен, cast(LPCWSTR) пароль, cast(DWORD) логинфлаги,  cast(LPCWSTR) назвПрил, cast(LPWSTR) комстр, cast(DWORD) флагиСозд,  cast(LPVOID) среда,  cast(LPCWSTR) текПап, cast(LPSTARTUPINFOW) инфост, cast(LPPROCESS_INFORMATION) процинфо);
	}
*/

бул ДайМаскуСходстваПроцесса(ук процесс,out бцел* маскаПроц, out бцел* маскаСис ){return cast(бул) GetProcessAffinityMask(cast(HANDLE) процесс, cast(LPDWORD) маскаПроц, cast(LPDWORD) маскаСис);}
/*
бул ДайРазмерРабочегоНабораПроцесса(){return cast(бул) GetProcessWorkingSetSize(cast(HANDLE), cast(LPDWORD), cast(LPDWORD));}

бул УстановиРазмерРабочегоНабораПроцесса(){return cast(бул) SetProcessWorkingSetSize(cast(HANDLE), cast(DWORD), cast(DWORD));}
*/
ук ОткройПроцесс(ППроцесс желДоступ, бул наследоватьДескр, бцел идПроцесса){return cast(ук) OpenProcess(cast(DWORD) желДоступ, cast(BOOL) наследоватьДескр, cast(DWORD) идПроцесса);}

бул ПрервиПроцесс(ук процесс, бцел кодВыхода){return cast(бул) TerminateProcess(cast(HANDLE) процесс, cast(UINT)кодВыхода);}


бул УстановиРежимКонсоли(ук конс, ПРежимКонсоли режим){return cast(бул) SetConsoleMode(cast(HANDLE)  конс, cast(DWORD) режим);}

бул ДайРежимКонсоли(ук конс, ПРежимКонсоли режим){return cast(бул) GetConsoleMode(cast(HANDLE) конс, cast(LPDWORD)режим);}

бул ВозьмиВводВКонсольА(ук ввод, ЗАПВВОДА* буф, бцел длина, бцел* члоСчитанныхСобытий){return cast(бул) PeekConsoleInputA(cast(HANDLE)  ввод, cast(PINPUT_RECORD)  буф, cast(DWORD) длина, cast(LPDWORD) члоСчитанныхСобытий);}

бул ВозьмиВводВКонсоль(ук ввод, ЗАПВВОДА* буф, бцел длина, бцел* члоСчитанныхСобытий){return cast(бул) PeekConsoleInputW(cast(HANDLE)  ввод, cast(PINPUT_RECORD)  буф, cast(DWORD) длина, cast(LPDWORD) члоСчитанныхСобытий);}

бул ЧитайВводВКонсольА(ук ввод, ЗАПВВОДА* буф, бцел длина, бцел* члоСчитанныхСобытий){return cast(бул) ReadConsoleInputA(cast(HANDLE)  ввод, cast(PINPUT_RECORD)  буф, cast(DWORD) длина, cast(LPDWORD) члоСчитанныхСобытий);}

бул ЧитайВводВКонсоль(ук ввод, ЗАПВВОДА* буф, бцел длина, бцел* члоСчитанныхСобытий){return cast(бул) ReadConsoleInputW(cast(HANDLE)  ввод, cast(PINPUT_RECORD)  буф, cast(DWORD) длина, cast(LPDWORD) члоСчитанныхСобытий);}

бул ПишиВводВКонсольА(ук ввод, ЗАПВВОДА* буф, бцел длина, бцел* члоСчитанныхСобытий){return cast(бул) WriteConsoleInputA(cast(HANDLE)  ввод, cast(PINPUT_RECORD)  буф, cast(DWORD) длина, cast(LPDWORD) члоСчитанныхСобытий);}

бул ПишиВводВКонсоль(ук ввод, ЗАПВВОДА* буф, бцел длина, бцел* члоСчитанныхСобытий){return cast(бул) WriteConsoleInputW(cast(HANDLE)  ввод, cast(PINPUT_RECORD)  буф, cast(DWORD) длина, cast(LPDWORD) члоСчитанныхСобытий);}

бул ДайИнфОБуфЭкранаКонсоли(ук консВывод, ИНФОКОНСЭКРБУФ *консЭкрБуфИнфо) {return cast(бул) GetConsoleScreenBufferInfo(cast(HANDLE)консВывод, cast(PCONSOLE_SCREEN_BUFFER_INFO) консЭкрБуфИнфо);}

бул УстановиАтрибутыТекстаКонсоли(ук конс, ПТекстКонсоли атр ){return cast(бул) SetConsoleTextAttribute(cast(HANDLE) конс, cast(WORD) атр);}

бул УстановиПозициюКурсораКонсоли(ук конс, КООРД поз) {return cast(бул) SetConsoleCursorPosition(cast(HANDLE) конс, cast(COORD)  поз);}

бул ПрокрутиБуферЭкранаКонсолиА(ук конс, in МПРЯМ *прокрПрям, in МПРЯМ *обрПрям, КООРД начПриём, in ИНФОСИМ *зап)
 {
 return cast(бул) ScrollConsoleScreenBufferA(cast(HANDLE)  конс, cast(SMALL_RECT*) прокрПрям, cast(SMALL_RECT*) обрПрям, cast(COORD)  начПриём, cast(PCHAR_INFO) зап);
 }

бул ПрокрутиБуферЭкранаКонсоли(ук конс, in МПРЯМ *прокрПрям, in МПРЯМ *обрПрям, КООРД начПриём, in ИНФОСИМ *зап)
 {
 return cast(бул) ScrollConsoleScreenBufferW(cast(HANDLE)  конс, cast(SMALL_RECT*) прокрПрям, cast(SMALL_RECT*) обрПрям, cast(COORD)  начПриём,  cast(PCHAR_INFO) зап);
 }

 бул УстановиКСКонсоли(ПКодСтр кодСтр){return cast(бул) SetConsoleCP( cast(UINT)  кодСтр);}
 ///////нет в импорте
бцел ДайКСКонсоли(){return cast(бцел)  GetConsoleCP();}

бцел ДайКСВыводаКонсоли(){return cast(бцел)  GetConsoleOutputCP();}

бул УстановиКСВыводаКонсоли(ПКодСтр кстр){return cast(бул) SetConsoleOutputCP(cast(UINT)  кстр);}

бул ОсвободиКонсоль(){return cast(бул) FreeConsole();}

бул УстановиЗагКонсолиА(ткст загКонсоли){return cast(бул) SetConsoleTitleA(cast( LPCSTR)  загКонсоли);}

бул УстановиЗагКонсоли(шткст загКонсоли){return cast(бул) SetConsoleTitleW(cast(LPCWSTR) загКонсоли);}

бул УстановиАктивныйБуферКонсоли(ук консВывод){return cast(бул) SetConsoleActiveScreenBuffer(cast(HANDLE)  консВывод);}

бул ОчистиБуферВводаКонсоли(ук консВвод) {return cast(бул) FlushConsoleInputBuffer(cast(HANDLE)  консВвод);}

бул УстановиРазмерБуфераЭкранаКонсоли(ук вывод, КООРД размер) {return cast(бул) SetConsoleScreenBufferSize(cast(HANDLE)  вывод, cast(COORD)  размер);}

бул УстановиИнфОКурсореКонсоли(ук вывод, in ИНФОКОНСКУРСОР *инфо) {return cast(бул) SetConsoleCursorInfo(cast(HANDLE)  вывод, cast(CONSOLE_CURSOR_INFO *) инфо);}

бул УстановиИнфОбОкнеКонсоли(ук вывод, бул абс, in МПРЯМ *разм){return cast(бул) SetConsoleWindowInfo(cast(HANDLE)  вывод, cast(BOOL) абс, cast(SMALL_RECT *) разм);}
/////////////////////\\\\\\\\\\\\\\\\\\\\=
бул  ЧитайКонсольныйВыводА(ук КОНСВЫВОД, ИНФОСИМ* буф, КООРД буфРазм, КООРД буфКоорд, МПРЯМ* регЧтен)
{return cast(бул) ReadConsoleOutputA(cast(HANDLE)  КОНСВЫВОД, cast(PCHAR_INFO)  буф, cast(COORD)  буфРазм, cast(COORD)  буфКоорд, cast(PSMALL_RECT)  регЧтен);}

бул  ЧитайКонсольныйВывод(ук КОНСВЫВОД, ИНФОСИМ* буф, КООРД буфРазм, КООРД буфКоорд, МПРЯМ* регЧтен)
{return cast(бул) ReadConsoleOutputW(cast(HANDLE)  КОНСВЫВОД, cast(PCHAR_INFO)  буф, cast(COORD)  буфРазм, cast(COORD)  буфКоорд, cast(PSMALL_RECT)  регЧтен);}

бул ЧитайВыводКонсолиА(ук КОНСВЫВОД, in ИНФОСИМ *буф, КООРД буфРазм, КООРД буфКоорд, МПРЯМ *регЗап)
{return cast(бул) WriteConsoleOutputA(cast(HANDLE)  КОНСВЫВОД, cast(PCHAR_INFO) буф, cast(COORD)  буфРазм, cast(COORD)  буфКоорд, cast(PSMALL_RECT)  регЗап);}

бул ПишиНаВыводКонсоли(ук КОНСВЫВОД, in ИНФОСИМ *буф, КООРД буфРазм, КООРД буфКоорд, МПРЯМ *регЗап)
{return cast(бул) WriteConsoleOutputW(cast(HANDLE)  КОНСВЫВОД, cast(PCHAR_INFO) буф, cast(COORD)  буфРазм, cast(COORD)  буфКоорд, cast(PSMALL_RECT)  регЗап);}

бул ЧитайСимИзВыводаКонсолиА(ук КОНСВЫВОД, сим *симв, бцел длина, КООРД коордЧтен, бцел *члоСчитСим)
{return cast(бул) ReadConsoleOutputCharacterA(cast(HANDLE)  КОНСВЫВОД, cast(LPSTR)  симв, cast(DWORD) длина, cast(COORD)  коордЧтен, cast(LPDWORD) члоСчитСим);}

бул ЧитайСимИзВыводаКонсоли(ук КОНСВЫВОД, шим *симв, бцел длина, КООРД коордЧтен, бцел *члоСчитСим)
{return cast(бул) ReadConsoleOutputCharacterW(cast(HANDLE)  КОНСВЫВОД,cast( LPWSTR)  симв, cast(DWORD) длина, cast(COORD)  коордЧтен, cast(LPDWORD) члоСчитСим);}

бул ЧитайАтрибутВыводаКонсоли(ук КОНСВЫВОД, бкрат *атр, бцел длина, КООРД коордЧтен, бцел *члоСчитАтров){return cast(бул) ReadConsoleOutputAttribute(cast(HANDLE)  КОНСВЫВОД, cast( LPWORD)  атр, cast(DWORD) длина, cast(COORD)  коордЧтен, cast(LPDWORD) члоСчитАтров);}

бул ПишиАтрибутВыводаКонсоли(ук КОНСВЫВОД, сим *симв, бцел длина, КООРД коордЗап, бцел *члоЗаписанАтров){return cast(бул) WriteConsoleOutputCharacterA(cast(HANDLE)  КОНСВЫВОД, cast( LPCSTR)  симв, cast(DWORD) длина, cast(COORD)  коордЗап, cast(LPDWORD) члоЗаписанАтров);}

бул АтрибутЗаливкиВыводаКонсоли(ук конс, ПТекстКонсоли атр, бцел длин, КООРД коорд, бцел* члоЗапАтров){return cast(бул) FillConsoleOutputAttribute(cast(HANDLE) конс, cast(бкрат) атр, cast(DWORD) длин, cast(COORD) коорд, cast(LPDWORD) члоЗапАтров);}
/*
{return cast(бул) WriteConsoleOutputCharacterW cast(HANDLE)  КОНСВЫВОД, LPCWSTR симв, cast(DWORD) длина, cast(COORD)  коордЗап, cast(LPDWORD) члоЗаписанАтров);}

{return cast(бул) WriteConsoleOutputAttribute cast(HANDLE)  КОНСВЫВОД, in WORD *атр, cast(DWORD) длина, cast(COORD)  коордЗап, cast(LPDWORD) lpNumberOfAttrsWritten);}

{return cast(бул) FillConsoleOutputCharacterA cast(HANDLE)  КОНСВЫВОД, CHAR cCharacter, cast(DWORD)  длина, cast(COORD)   коордЗап, cast(LPDWORD) члоЗаписанАтров);}

{return cast(бул) FillConsoleOutputCharacterW cast(HANDLE)  КОНСВЫВОД, WCHAR cCharacter, cast(DWORD)  длина, cast(COORD)   коордЗап, cast(LPDWORD) члоЗаписанАтров);}
{return cast(бул) GetConsoleMode(cast(HANDLE)  hConsoleHandle, cast(LPDWORD) lpMode);}
{return cast(бул) GetNumberOfConsoleInputEvents(cast(HANDLE)  hConsoleInput, cast(LPDWORD) lpNumberOfEvents);}
{return cast(бул) GetConsoleScreenBufferInfocast(HANDLE)  КОНСВЫВОД, cast( PCONSOLE_SCREEN_BUFFER_INFO)  lpConsoleScreenBufferInfo);}
cast(COORD)  GetLargestConsoleWindowSize( HANDLE КОНСВЫВОД);}
{return cast(бул) GetConsoleCursorInfocast(HANDLE)  КОНСВЫВОД, cast( PCONSOLE_CURSOR_INFO)  lpConsoleCursorInfo);}
{return cast(бул) GetNumberOfConsoleMouseButtons( cast(LPDWORD) lpNumberOfMouseButtons);}


{return cast(бул) SetConsoleTextAttribute(cast(HANDLE)  КОНСВЫВОД, WORD wAttributes);}
alias {return cast(бул) function(cast(DWORD) CtrlType) PHANDLER_ROUTINE;}
{return cast(бул) SetConsoleCtrlHandler(PHANDLER_ROUTINE HandlerRoutine, {return cast(бул) Add);}
{return cast(бул) GenerateConsoleCtrlEvent( cast(DWORD) dwCtrlEvent, cast(DWORD) dwProcessGroupId);}
cast(DWORD) GetConsoleTitleA(cast(LPSTR)  lpConsoleTitle, cast(DWORD) nSize);}
cast(DWORD) GetConsoleTitleW(LPWSTR lpConsoleTitle, cast(DWORD) nSize);}
{return cast(бул) ReadConsoleA(cast(HANDLE)  hConsoleInput, cast(LPVOID)  буф, cast(DWORD) nNumberOfCharsToRead, cast(LPDWORD) члоСчитСим, cast(LPVOID)  lpReserved);}
{return cast(бул) ReadConsoleW(cast(HANDLE)  hConsoleInput, cast(LPVOID)  буф, cast(DWORD) nNumberOfCharsToRead, cast(LPDWORD) члоСчитСим, cast(LPVOID)  lpReserved);}
{return cast(бул) WriteConsoleA(cast(HANDLE)  КОНСВЫВОД, in  void *буф, cast(DWORD) nNumberOfCharsToWrite, cast(LPDWORD) члоЗаписанАтров, cast(LPVOID)  lpReserved);}
{return cast(бул) WriteConsoleW(cast(HANDLE)  КОНСВЫВОД, in  void *буф, cast(DWORD) nNumberOfCharsToWrite, cast(LPDWORD) члоЗаписанАтров, cast(LPVOID)  lpReserved);}

*/

 проц ДайИнфоСтарта(ИНФОСТАРТА* ис){GetStartupInfoW(cast(STARTUPINFO*) ис);}
 }
 

 extern(Windows)
{


BOOL SetPriorityClass(HANDLE, DWORD);
void GetStartupInfoW(STARTUPINFO*);
//BOOL CreateProcessWithLogonW( LPCWSTR lpUsername, LPCWSTR lpDomain, LPCWSTR lpPassword, DWORD dwLogonFlags,  LPCWSTR lpApplicationName,  LPWSTR lpCommandLine,  DWORD dwCreationFlags,  LPVOID lpEnvironment,  LPCWSTR lpCurrentDirectory,  LPSTARTUPINFOW lpStartupInfo, LPPROCESS_INFORMATION lpProcessInfo);

}
/*
cast(BOOL) GetWindowInfo(HWND, PWINDOWINFO);}
cast(BOOL) EnumDisplayMonitors(HDC, RECT*, MONITORENUMPROC, LPARAM);}
cast(BOOL) GetMonitorInfoA(HMONITOR, LPMONITORINFO);}
cast(BOOL) GetBinaryTypeA(cast(LPCSTR), cast(LPDWORD));}
cast(DWORD) GetShortPathNameA(cast(LPCSTR), cast(LPSTR), cast(DWORD));}
cast(LPSTR) GetEnvironmentStringsA();}
cast(BOOL) FreeEnvironmentStringsA(cast(LPSTR));}
cast(DWORD) FormatMessageA(cast(DWORD), LPCVOID, cast(DWORD), cast(DWORD), cast(LPSTR), cast(DWORD), VA_LIST*);}
цел lstrcmpA(cast(LPCSTR), cast(LPCSTR));}
цел lstrcmpiA(cast(LPCSTR), cast(LPCSTR));}
cast(LPSTR) lstrcpynA(cast(LPSTR), cast(LPCSTR), цел);}
cast(LPSTR) lstrcpyA(cast(LPSTR), cast(LPCSTR));}
cast(LPSTR) lstrcatA(cast(LPSTR), cast(LPCSTR));}
цел lstrlenA(cast(LPCSTR));}
cast(HANDLE) OpenMutexA(cast(DWORD), cast(BOOL), cast(LPCSTR));}
cast(HANDLE) OpenEventA(cast(DWORD), cast(BOOL), cast(LPCSTR));}
cast(HANDLE) OpenSemaphoreA(cast(DWORD), cast(BOOL), cast(LPCSTR));}
cast(DWORD) GetLogicalDriveStringsA(cast(DWORD), cast(LPSTR));}
проц FatalAppExitA(UINT);}
cast(LPSTR) GetCommandLineA();}
cast(LPWSTR) *CommandLineToArgvW(cast(LPCWSTR), цел*);} 
cast(DWORD) ExpandEnvironmentStringsA(cast(LPCSTR), cast(LPSTR), cast(DWORD));}
проц OutputDebugStringA(cast(LPCSTR));}
HRSRC FindResourceA(HINST, cast(LPCSTR), cast(LPCSTR));}
HRSRC FindResourceExA(HINST, cast(LPCSTR), cast(LPCSTR), бкрат);}
cast(BOOL) EnumResourceTypesA(HINST, ENUMRESTYPEPROC, LONG);}
cast(BOOL) EnumResourceNamesA(HINST, cast(LPCSTR), ENUMRESNAMEPROC, LONG);}
cast(BOOL) EnumResourceLanguagesA(HINST, cast(LPCSTR), cast(LPCSTR), ENUMRESLANGPROC, LONG);}
cast(BOOL) UpdateResourceA(cast(HANDLE), cast(LPCSTR), cast(LPCSTR), бкрат, cast(LPVOID), cast(DWORD));}
cast(BOOL) EndUpdateResourceA(cast(HANDLE), cast(BOOL));}
ATOM GlobalдобавьAtomA(cast(LPCSTR));}
ATOM GlobalFindAtomA(cast(LPCSTR));}
UINT GlobalGetAtomNameA(ATOM, cast(LPSTR), цел);}
ATOM добавьAtomA(cast(LPCSTR));}
ATOM FindAtomA(cast(LPCSTR));}
UINT GetAtomNameA(ATOM, cast(LPSTR), цел);}
UINT GetProfileIntA(cast(LPCSTR), cast(LPCSTR), INT);}
cast(DWORD) GetProfileStringA(cast(LPCSTR), cast(LPCSTR), cast(LPCSTR), cast(LPSTR), cast(DWORD));}
cast(BOOL) WriteProfileStringA(cast(LPCSTR), cast(LPCSTR), cast(LPCSTR));}
cast(DWORD) GetProfileSectionA(cast(LPCSTR), cast(LPSTR), cast(DWORD));}
cast(BOOL) WriteProfileSectionA(cast(LPCSTR), cast(LPCSTR));}
UINT GetPrivateProfileIntA(cast(LPCSTR), cast(LPCSTR), INT, cast(LPCSTR));}
cast(DWORD) GetPrivateProfileStringA(cast(LPCSTR), cast(LPCSTR), cast(LPCSTR), cast(LPSTR), cast(DWORD), cast(LPCSTR));}
cast(BOOL) WritePrivateProfileStringA(cast(LPCSTR), cast(LPCSTR), cast(LPCSTR), cast(LPCSTR));}
cast(DWORD) GetPrivateProfileSectionA(cast(LPCSTR), cast(LPSTR), cast(DWORD), cast(LPCSTR));}
cast(BOOL) WritePrivateProfileSectionA(cast(LPCSTR), cast(LPCSTR), cast(LPCSTR));}
UINT GetDriveTypeA(cast(LPCSTR));}
UINT GetSystemDirectoryA(cast(LPSTR), UINT);}
cast(DWORD) GetTempPathA(cast(DWORD), cast(LPSTR));}
UINT GetTempFileNameA(cast(LPCSTR), cast(LPCSTR), UINT, cast(LPSTR));}
UINT GetWindowsDirectoryA(cast(LPSTR), UINT);}
cast(BOOL) GetDiskFreeSpaceA(cast(LPCSTR), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD));}
cast(DWORD) GetFullPathNameA(cast(LPCSTR), cast(DWORD), cast(LPSTR), cast(LPSTR)*);}
cast(DWORD) QueryDosDeviceA(cast(LPCSTR), cast(LPSTR), cast(DWORD));}
cast(BOOL) SetFileAttributesA(cast(LPCSTR), cast(DWORD));}
cast(DWORD) GetFileAttributesA(cast(LPCSTR));}
cast(BOOL) GetFileAttributesExA(cast(LPCSTR), cast(DWORD), WIN32_FILE_ATTRIBUTE_DATA*);}
cast(DWORD) GetCompressedFileSizeA(cast(LPCSTR), cast(LPDWORD));}
cast(DWORD) SearchPathA(cast(LPCSTR), cast(LPCSTR), cast(LPCSTR), cast(DWORD), cast(LPSTR), cast(LPSTR));}
cast(BOOL) CopyFileA(cast(LPCSTR), cast(LPCSTR), cast(BOOL));}
cast(BOOL) MoveFileA(cast(LPCSTR), cast(LPCSTR));}
cast(BOOL) MoveFileExA(cast(LPCSTR), cast(LPCSTR), cast(DWORD));}
cast(BOOL) GetNamedPipeHandleStateA(cast(HANDLE), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPSTR), cast(DWORD));}
cast(BOOL) WaitNamedPipeA(cast(LPCSTR), cast(DWORD));}
cast(BOOL) SetVolumeLabelA(cast(LPCSTR), cast(LPCSTR));}
cast(BOOL) GetVolumePathNameA(cast(LPCSTR), cast(LPSTR), cast(DWORD));}
cast(BOOL) GetVolumeInformationA(cast(LPCSTR), cast(LPSTR), cast(DWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPSTR), cast(DWORD));}
cast(BOOL) ClearEventLogA(cast(HANDLE), cast(LPCSTR));}
cast(BOOL) BackupEventLogA(cast(HANDLE), cast(LPCSTR));}
cast(HANDLE) OpenEventLogA(cast(LPCSTR), cast(LPCSTR));}
cast(HANDLE) RegisterEventSourceA(cast(LPCSTR), cast(LPCSTR));}
cast(HANDLE) OpenBackupEventLogA(cast(LPCSTR), cast(LPCSTR));}
cast(BOOL) ReadEventLogA(cast(HANDLE), cast(DWORD), cast(DWORD), cast(LPVOID), cast(DWORD), cast(LPDWORD), cast(LPDWORD));}
cast(BOOL) ReportEventA(cast(HANDLE), бкрат, бкрат, cast(DWORD), PSID, бкрат, cast(DWORD), cast(LPCSTR)*, cast(LPVOID));}
cast(BOOL) AccessCheckAndAuditAlarmA(cast(LPCSTR), cast(LPVOID), cast(LPSTR), cast(LPSTR), PSECURITY_DESCRIPTOR, cast(DWORD), PGENERIC_MAPPING, cast(BOOL), cast(LPDWORD), LPcast(BOOL), LPcast(BOOL));}
cast(BOOL) ObjectOpenAuditAlarmA(cast(LPCSTR), cast(LPVOID), cast(LPSTR), cast(LPSTR), PSECURITY_DESCRIPTOR, cast(HANDLE), cast(DWORD), cast(DWORD), PPRIVILEGE_SET, cast(BOOL), cast(BOOL), LPcast(BOOL));}
cast(BOOL) ObjectPrivilegeAuditAlarmA(cast(LPCSTR), cast(LPVOID), cast(HANDLE), cast(DWORD), PPRIVILEGE_SET, cast(BOOL));}
cast(BOOL) ObjectCloseAuditAlarmA(cast(LPCSTR), cast(LPVOID), cast(BOOL));}
cast(BOOL) PrivilegedServiceAuditAlarmA(cast(LPCSTR), cast(LPCSTR), cast(HANDLE), PPRIVILEGE_SET, cast(BOOL));}
cast(BOOL) SetFileSecurityA(cast(LPCSTR), SECURITY_INFORMATION, PSECURITY_DESCRIPTOR);}
cast(BOOL) GetFileSecurityA(cast(LPCSTR), SECURITY_INFORMATION, PSECURITY_DESCRIPTOR, cast(DWORD), cast(LPDWORD));}
cast(HANDLE) FindFirstChangeNotificationA(cast(LPCSTR), cast(BOOL), cast(DWORD));}
cast(BOOL) LookupAccountSidA(cast(LPCSTR), PSID, cast(LPSTR), cast(LPDWORD), cast(LPSTR), cast(LPDWORD), PSID_NAME_USE);}
cast(BOOL) LookupAccountNameA(cast(LPCSTR), cast(LPCSTR), PSID, cast(LPDWORD), cast(LPSTR), cast(LPDWORD), PSID_NAME_USE);}
cast(BOOL) LookupPrivilegeValueA(cast(LPCSTR), cast(LPCSTR), PLUID);}
cast(BOOL) LookupPrivilegeNameA(cast(LPCSTR), PLUID, cast(LPSTR), cast(LPDWORD));}
cast(BOOL) LookupPrivilegeDisplayNameA(cast(LPCSTR), cast(LPCSTR), cast(LPSTR), cast(LPDWORD), cast(LPDWORD));}
cast(BOOL) GetDefaultCommConfigA(cast(LPCSTR), LPCOMMCONFIG, cast(LPDWORD));}
cast(BOOL) SetDefaultCommConfigA(cast(LPCSTR), LPCOMMCONFIG, cast(DWORD));}
cast(BOOL) GetComputerNameA(cast(LPSTR), cast(LPDWORD));}
cast(BOOL) SetComputerNameA(cast(LPCSTR));}
cast(BOOL) GetUserNameA(cast(LPSTR), cast(LPDWORD));}
цел wvsprintfA(cast(LPSTR), cast(LPCSTR), VA_LIST*);}
HKL LoadKeyboardLayoutA(cast(LPCSTR), UINT);}
cast(BOOL) GetKeyboardLayoutNameA(cast(LPSTR));}
HDESK CreateDesktopA(cast(LPSTR), cast(LPSTR), LPDEVMODE, cast(DWORD), cast(DWORD), cast(LPSECURITY_ATTRIBUTES));}
HDESK OpenDesktopA(cast(LPSTR), cast(DWORD), cast(BOOL), cast(DWORD));}
cast(BOOL) EnumDesktopsA(HWINSTA, DESKTOPENUMPROC, LPARAM);}
HWINSTA CreateWindowStationA(cast(LPSTR), cast(DWORD), cast(DWORD), cast(LPSECURITY_ATTRIBUTES));}
HWINSTA OpenWindowStationA(cast(LPSTR), cast(BOOL), cast(DWORD));}
cast(BOOL) EnumWindowStationsA(ENUMWINDOWSTATIONPROC, LPARAM);}
cast(BOOL) GetUserObjectInformationA(cast(HANDLE), цел, PVOID, cast(DWORD), cast(LPDWORD));}
cast(BOOL) SetUserObjectInformationA(cast(HANDLE), цел, PVOID, cast(DWORD));}
UINT RegisterWindowMessageA(cast(LPCSTR));}
cast(BOOL) GetMessageA(LPMSG, HWND, UINT, UINT);}
LONG DispatchMessageA(LPMSG);}
cast(BOOL) PeekMessageA(LPMSG, HWND, UINT, UINT, UINT);}
LRESULT SendMessageA(HWND, UINT, WPARAM, LPARAM);}
LRESULT SendMessageA(HWND, UINT, проц*, LPARAM);}
LRESULT SendMessageA(HWND, UINT, WPARAM, проц*);}
LRESULT SendMessageA(HWND, UINT, проц*, проц*);}
LRESULT SendMessageTimeoutA(HWND, UINT, WPARAM, LPARAM, UINT, UINT, cast(LPDWORD));}
cast(BOOL) SendNotifyMessageA(HWND, UINT, WPARAM, LPARAM);}
cast(BOOL) SendMessageCallbackA(HWND, UINT, WPARAM, LPARAM, SENDASYNCPROC, cast(DWORD));}
cast(BOOL) PostMessageA(HWND, UINT, WPARAM, LPARAM);}
cast(BOOL) PostThreadMessageA(cast(DWORD), UINT, WPARAM, LPARAM);}
LRESULT DefWindowProcA(HWND, UINT, WPARAM, LPARAM);}
LRESULT CallWindowProcA(WNDPROC, HWND, UINT, WPARAM, LPARAM);}
ATOM RegisterClassA(LPWNDCLASSA);}
cast(BOOL) UnregisterClassA(cast(LPCSTR), HINST);}
cast(BOOL) GetClassInfoA(HINST, cast(LPCSTR), LPWNDCLASS);}
ATOM RegisterClassExA(LPWNDCLASSEX);}
cast(BOOL) GetClassInfoExA(HINST, cast(LPCSTR), LPWNDCLASSEX);}
HWND CreateWindowExA(cast(DWORD), cast(LPCSTR), cast(LPCSTR), cast(DWORD), цел, цел, цел, цел, HWND, HMENU, HINST, cast(LPVOID));}
HWND CreateDialogParamA(HINST, cast(LPCSTR), HWND, DLGPROC, LPARAM);}
HWND CreateDialogIndirectParamA(HINST, LPCDLGTEMPLATE, HWND, DLGPROC, LPARAM);}
цел DialogBoxParamA(HINST, cast(LPCSTR), HWND, DLGPROC, LPARAM);}
цел DialogBoxIndirectParamA(HINST, LPCDLGTEMPLATE, HWND, DLGPROC, LPARAM);}
cast(BOOL) SetDlgItemTextA(HWND, цел, cast(LPCSTR));}
UINT GetDlgItemTextA(HWND, цел, cast(LPSTR), цел);}
LONG SendDlgItemMessageA(HWND, цел, UINT, WPARAM, LPARAM);}
LRESULT DefDlgProcA(HWND, UINT, WPARAM, LPARAM);}
cast(BOOL) CallMsgFilterA(LPMSG, цел);}
UINT RegisterClipboardFormatA(cast(LPCSTR));}
цел GetClipboardFormatNameA(UINT, cast(LPSTR), цел);}
cast(BOOL) CharToOemA(cast(LPCSTR), cast(LPSTR));}
cast(BOOL) OemToCharA(cast(LPCSTR), cast(LPSTR));}
cast(BOOL) CharToOemBuffA(cast(LPCSTR), cast(LPSTR), cast(DWORD));}
cast(BOOL) OemToCharBuffA(cast(LPCSTR), cast(LPSTR), cast(DWORD));}
cast(LPSTR) CharUpperA(cast(LPSTR));}
cast(DWORD) CharUpperBuffA(cast(LPSTR), cast(DWORD));}
cast(LPSTR) CharLowerA(cast(LPSTR));}
cast(DWORD) CharLowerBuffA(cast(LPSTR), cast(DWORD));}
cast(LPSTR) CharNextA(cast(LPCSTR));}
cast(LPSTR) CharPrevA(cast(LPCSTR), cast(LPCSTR));}
cast(BOOL) IsCharAlphaA(сим);}
cast(BOOL) IsCharAlphaNumericA(сим);}
cast(BOOL) IsCharUpperA(сим);}
cast(BOOL) IsCharLowerA(сим);}
цел GetKeyNameTextA(LONG, cast(LPSTR), цел);}
SHORT VkKeyScanA(сим);}
SHORT VkKeyScanExA(сим, HKL);}
UINT MapVirtualKeyA(UINT, UINT);}
UINT MapVirtualKeyExA(UINT, UINT, HKL);}
HACCEL LoadAcceleratorsA(HINST, cast(LPCSTR));}
HACCEL CreateAcceleratorTableA(LPACCEL, цел);}
цел CopyAcceleratorTableA(HACCEL, LPACCEL, цел);}
цел TranslateAcceleratorA(HWND, HACCEL, LPMSG);}
HMENU LoadMenuA(HINST, cast(LPCSTR));}
HMENU LoadMenuIndirectA(LPMENUTEMPLATE);}
cast(BOOL) ChangeMenuA(HMENU, UINT, cast(LPCSTR), UINT, UINT);}
цел GetMenuStringA(HMENU, UINT, cast(LPSTR), цел, UINT);}
cast(BOOL) InsertMenuA(HMENU, UINT, UINT, UINT, cast(LPCSTR));}
cast(BOOL) AppendMenuA(HMENU, UINT, UINT, cast(LPCSTR));}
cast(BOOL) ModifyMenuA(HMENU, UINT, UINT, UINT, cast(LPCSTR));}
cast(BOOL) InsertMenuItemA(HMENU, UINT, cast(BOOL), LPCMENUITEMINFO);}
cast(BOOL) GetMenuItemInfoA(HMENU, UINT, cast(BOOL), LPMENUITEMINFO);}
cast(BOOL) SetMenuItemInfoA(HMENU, UINT, cast(BOOL), LPCMENUITEMINFO);}
цел DrawTextA(HDC, cast(LPCSTR), цел, LPRECT, UINT);}
цел DrawTextExA(HDC, cast(LPSTR), цел, LPRECT, UINT, LPDRAWTEXTPARAMS);}
cast(BOOL) GrayStringA(HDC, HBRUSH, GRAYSTRINGPROC, LPARAM, цел, цел, цел, цел, цел);}
cast(BOOL) DrawStateA(HDC, HBRUSH, DRAWSTATEPROC, LPARAM, WPARAM, цел, цел, цел, цел, UINT);}
LONG TabbedTextOutA(HDC, цел, цел, cast(LPCSTR), цел, цел, LPINT, цел);}
cast(DWORD) GetTabbedTextExtentA(HDC, cast(LPCSTR), цел, цел, LPINT);}
cast(BOOL) SetPropA(HWND, cast(LPCSTR), cast(HANDLE));}
cast(HANDLE) GetPropA(HWND, cast(LPCSTR));}
cast(HANDLE) RemovePropA(HWND, cast(LPCSTR));}
цел EnumPropsExA(HWND, PROPENUMPROCEX, LPARAM);}
цел EnumPropsA(HWND, PROPENUMPROC);}
cast(BOOL) SetWindowTextA(HWND, cast(LPCSTR));}
цел GetWindowTextA(HWND, cast(LPSTR), цел);}
цел GetWindowTextLengthA(HWND);}
цел MessageBoxA(HWND, cast(LPCSTR), cast(LPCSTR), UINT);}
цел MessageBoxExA(HWND, cast(LPCSTR), cast(LPCSTR), UINT, бкрат);}
цел MessageBoxIndirectA(LPMSGBOXPARAMS);}
LONG GetWindowLongA(HWND, цел);}
LONG SetWindowLongA(HWND, цел, LONG);}
cast(DWORD) GetClassLongA(HWND, цел);}
cast(DWORD) SetClassLongA(HWND, цел, LONG);}
HWND FindWindowA(cast(LPCSTR), cast(LPCSTR));}
HWND FindWindowExA(HWND, HWND, cast(LPCSTR), cast(LPCSTR));}
цел GetClassNameA(HWND, cast(LPSTR), цел);}
HHOOK SetWindowsHookExA(цел, HOOKPROC, HINST, cast(DWORD));}
HBITMAP LoadBitmapA(HINST, cast(LPCSTR));}
HCURSOR LoadCursorA(HINST, cast(LPCSTR));}
HCURSOR LoadCursorFromFileA(cast(LPCSTR));}
HICON LoadIconA(HINST, cast(LPCSTR));}
cast(HANDLE) LoadImageA(HINST, cast(LPCSTR), UINT, цел, цел, UINT);}
цел LoadStringA(HINST, UINT, cast(LPSTR), цел);}
cast(BOOL) IsDialogMessageA(HWND, LPMSG);}
цел DlgDirListA(HWND, cast(LPSTR), цел, цел, UINT);}
cast(BOOL) DlgDirSelectExA(HWND, cast(LPSTR), цел, цел);}
цел DlgDirListComboBoxA(HWND, cast(LPSTR), цел, цел, UINT);}
cast(BOOL) DlgDirSelectComboBoxExA(HWND, cast(LPSTR), цел, цел);}
LRESULT DefFrameProcA(HWND, HWND, UINT, WPARAM, LPARAM);}
LRESULT DefMDIChildProcA(HWND, UINT, WPARAM, LPARAM);}
HWND CreateMDIWindowA(cast(LPSTR), cast(LPSTR), cast(DWORD), цел, цел, цел, цел, HWND, HINST, LPARAM);}
cast(BOOL) WinHelpA(HWND, cast(LPCSTR), UINT, cast(DWORD));}
LONG ChangeDisplaySettingsA(LPDEVMODE, cast(DWORD));}
cast(BOOL) EnumDisplaySettingsA(cast(LPCSTR), cast(DWORD), LPDEVMODE);}
cast(BOOL) SystemParametersInfoA(UINT, UINT, PVOID, UINT);}
цел добавьFontResourceA(cast(LPCSTR));}
HMETAFILE CopyMetaFileA(HMETAFILE, cast(LPCSTR));}
HFONT CreateFontIndirectA(LPLOGFONT);}
HDC CreateICA(cast(LPCSTR), cast(LPCSTR), cast(LPCSTR), LPDEVMODE);}
HDC CreateMetaFileA(cast(LPCSTR));}
cast(BOOL) CreateScalableFontResourceA(cast(DWORD), cast(LPCSTR), cast(LPCSTR), cast(LPCSTR));}
цел EnumFontFamiliesExA(HDC, LPLOGFONT, FONTENUMEXPROC, LPARAM, cast(DWORD));}
цел EnumFontFamiliesA(HDC, cast(LPCSTR), FONTENUMPROC, LPARAM);}
цел EnumFontsA(HDC, cast(LPCSTR), ENUMFONTSPROC, LPARAM);}
cast(BOOL) GetCharWidthA(HDC, UINT, UINT, LPINT);}
cast(BOOL) GetCharWidth32A(HDC, UINT, UINT, LPINT);}
cast(BOOL) GetCharWidthFloatA(HDC, UINT, UINT, PFLOAT);}
cast(BOOL) GetCharABCWidthsA(HDC, UINT, UINT, LPABC);}
cast(BOOL) GetCharABCWidthsFloatA(HDC, UINT, UINT, LPABCFLOAT);}
cast(DWORD) GetGlyphOutlineA(HDC, UINT, UINT, LPGLYPHMETRICS, cast(DWORD), cast(LPVOID), PMAT2);}
HMETAFILE GetMetaFileA(cast(LPCSTR));}
UINT GetOutlineTextMetricsA(HDC, UINT, LPOUTLINETEXTMETRIC);}
cast(BOOL) GetTextExtentPointA(HDC, cast(LPCSTR), цел, LPSIZE);}
cast(BOOL) GetTextExtentPoint32A(HDC, cast(LPCSTR), цел, LPSIZE);}
cast(BOOL) GetTextExtentExPointA(HDC, cast(LPCSTR), цел, цел, LPINT, LPINT, LPSIZE);}
cast(DWORD) GetCharacterPlacementA(HDC, cast(LPCSTR), цел, цел, LPGCP_RESULTS, cast(DWORD));}
HDC ResetDCA(HDC, LPDEVMODE);}
cast(BOOL) RemoveFontResourceA(cast(LPCSTR));}
HENHMETAFILE CopyEnhMetaFileA(HENHMETAFILE, cast(LPCSTR));}
HDC CreateEnhMetaFileA(HDC, cast(LPCSTR), LPRECT, cast(LPCSTR));}
HENHMETAFILE GetEnhMetaFileA(cast(LPCSTR));}
UINT GetEnhMetaFileDescriptionA(HENHMETAFILE, UINT, cast(LPSTR));}
cast(BOOL) GetTextMetricsA(HDC, LPTEXTMETRIC);}
цел StartDocA(HDC, PDOCINFO);}
цел GetObjectA(HGDIOBJ, цел, cast(LPVOID));}
cast(BOOL) TextOutA(HDC, цел, цел, cast(LPCSTR), цел);}
cast(BOOL) ExtTextOutA(HDC, цел, цел, UINT, LPRECT, cast(LPCSTR), UINT, LPINT);}
cast(BOOL) PolyTextOutA(HDC, PPOLYTEXT, цел);}
цел GetTextFaceA(HDC, цел, cast(LPSTR));}
cast(DWORD) GetKerningPairsA(HDC, cast(DWORD), LPKERNINGPAIR);}
HCOLORSPACE CreateColorSpaceA(LPLOGCOLORSPACE);}
cast(BOOL) GetLogColorSpaceA(HCOLORSPACE, LPLOGCOLORSPACE, cast(DWORD));}
cast(BOOL) GetICMProfileA(HDC, cast(DWORD), cast(LPSTR));}
cast(BOOL) SetICMProfileA(HDC, cast(LPSTR));}
cast(BOOL) UpdateICMRegKeyA(cast(DWORD), cast(DWORD), cast(LPSTR), UINT);}
цел EnumICMProfilesA(HDC, ICMENUMPROC, LPARAM);}
цел PropertySheetA(LPCPROPSHEETHEADER);}
HIMAGELIST ImageList_LoadImageA(HINST, cast(LPCSTR), цел, цел, COLORREF, UINT, UINT);}
HWND CreateStatusWindowA(LONG, cast(LPCSTR), HWND, UINT);}
проц DrawStatusTextA(HDC, LPRECT, cast(LPCSTR));}
cast(BOOL) GetOpenFileNameA(LPOPENFILENAME);}
cast(BOOL) GetSaveFileNameA(LPOPENFILENAME);}
цел GetFileTitleA(cast(LPCSTR), cast(LPSTR), бкрат);}
cast(BOOL) ChooseColorA(LPCHOOSECOLOR);}
HWND FindTextA(LPFINDREPLACE);}
HWND ReplaceTextA(LPFINDREPLACE);}
cast(BOOL) ChooseFontA(LPCHOOSEFONTA);}
cast(BOOL) PrintDlgA(LPPRINTDLGA);}
cast(BOOL) PageSetupDlgA(LPPAGESETUPDLG);}
проц GetStartupInfoA(cast(LPSTARTUPINFO));}
cast(HANDLE) FindFirstFileA(cast(LPCSTR), LPWIN32_FIND_DATA);}
cast(BOOL) FindNextFileA(cast(HANDLE), LPWIN32_FIND_DATA);}
cast(BOOL) GetVersionExA(LPOSVERSIONINFO);}
HDC CreateDCA(cast(LPCSTR), cast(LPCSTR), cast(LPCSTR), PDEVMODE);}
cast(DWORD) VerInstallFileA(cast(DWORD), cast(LPSTR), cast(LPSTR), cast(LPSTR), cast(LPSTR), cast(LPSTR), cast(LPSTR), PUINT);}
cast(DWORD) GetFileVersionInfoSizeA(cast(LPSTR), cast(LPDWORD));}
cast(BOOL) GetFileVersionInfoA(cast(LPSTR), cast(DWORD), cast(DWORD), cast(LPVOID));}
cast(DWORD) VerLanguageNameA(cast(DWORD), cast(LPSTR), cast(DWORD));}
cast(BOOL) VerQueryValueA(cast(LPVOID), cast(LPSTR), cast(LPVOID), PUINT);}
cast(DWORD) VerFindFileA(cast(DWORD), cast(LPSTR), cast(LPSTR), cast(LPSTR), cast(LPSTR), PUINT, cast(LPSTR), PUINT);}
LONG RegConnectRegistryA(cast(LPSTR), HKEY, PHKEY);}
LONG RegCreateKeyA(HKEY, cast(LPCSTR), PHKEY);}
LONG RegCreateKeyExA(HKEY, cast(LPCSTR), cast(DWORD), cast(LPSTR), cast(DWORD), REGSAM, cast(LPSECURITY_ATTRIBUTES), PHKEY, cast(LPDWORD));}
LONG RegDeleteKeyA(HKEY, cast(LPCSTR));}
LONG RegDeleteValueA(HKEY, cast(LPCSTR));}
LONG RegEnumKeyA(HKEY, cast(DWORD), cast(LPSTR), cast(DWORD));}
LONG RegEnumKeyExA(HKEY, cast(DWORD), cast(LPSTR), cast(LPDWORD), cast(LPDWORD), cast(LPSTR), cast(LPDWORD), PFILETIME);}
LONG RegEnumValueA(HKEY, cast(DWORD), cast(LPSTR), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), LPBYTE, cast(LPDWORD));}
LONG RegLoadKeyA(HKEY, cast(LPCSTR), cast(LPCSTR));}
LONG RegOpenKeyA(HKEY, cast(LPCSTR), PHKEY);}
LONG RegOpenKeyExA(HKEY, cast(LPCSTR), cast(DWORD), REGSAM, PHKEY);}
LONG RegQueryInfoKeyA(HKEY, cast(LPSTR), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), PFILETIME);}
LONG RegQueryValueA(HKEY, cast(LPCSTR), cast(LPSTR), PLONG);}
LONG RegQueryMultipleValuesA(HKEY, PVALENT, cast(DWORD), cast(LPSTR), cast(LPDWORD));}
LONG RegQueryValueExA(HKEY, cast(LPCSTR), cast(LPDWORD), cast(LPDWORD), LPBYTE, cast(LPDWORD));}
LONG RegReplaceKeyA(HKEY, cast(LPCSTR), cast(LPCSTR), cast(LPCSTR));}
LONG RegRestoreKeyA(HKEY, cast(LPCSTR), cast(DWORD));}
LONG RegSaveKeyA(HKEY, cast(LPCSTR), cast(LPSECURITY_ATTRIBUTES));}
LONG RegSetValueA(HKEY, cast(LPCSTR), cast(DWORD), cast(LPCSTR), cast(DWORD));}
LONG RegSetValueExA(HKEY, cast(LPCSTR), cast(DWORD), cast(DWORD), LPBYTE, cast(DWORD));}
LONG RegUnLoadKeyA(HKEY, cast(LPCSTR));}
cast(BOOL) InitiateSystemShutdownA(cast(LPSTR), cast(LPSTR), cast(DWORD), cast(BOOL), cast(BOOL));}
cast(BOOL) AbortSystemShutdownA(cast(LPSTR));}
цел LCMapStringA(LCID, cast(DWORD), cast(LPCSTR), цел, cast(LPSTR), цел);}
цел GetLocaleInfoA(LCID, LCTYPE, cast(LPSTR), цел);}
cast(BOOL) SetLocaleInfoA(LCID, LCTYPE, cast(LPCSTR));}
цел GetTimeFormatA(LCID, cast(DWORD), LPSYSTEMTIME, cast(LPCSTR), cast(LPSTR), цел);}
цел GetDateFormatA(LCID, cast(DWORD), LPSYSTEMTIME, cast(LPCSTR), cast(LPSTR), цел);}
цел GetNumberFormatA(LCID, cast(DWORD), cast(LPCSTR), PNUMBERFMT, cast(LPSTR), цел);}
цел GetCurrencyFormatA(LCID, cast(DWORD), cast(LPCSTR), PCURRENCYFMT, cast(LPSTR), цел);}
cast(BOOL) EnumCalendarInfoA(CALINFO_ENUMPROC, LCID, CALID, CALTYPE);}
cast(BOOL) EnumTimeFormatsA(TIMEFMT_ENUMPROC, LCID, cast(DWORD));}
cast(BOOL) EnumDateFormatsA(DATEFMT_ENUMPROC, LCID, cast(DWORD));}
cast(BOOL) GetStringTypeExA(LCID, cast(DWORD), cast(LPCSTR), цел, LPWORD);}
cast(BOOL) GetStringTypeA(LCID, cast(DWORD), cast(LPCSTR), цел, LPWORD);}
цел FoldStringA(cast(DWORD), cast(LPCSTR), цел, cast(LPSTR), цел);}
cast(BOOL) EnumSystemLocalesA(LOCALE_ENUMPROC, cast(DWORD));}
cast(BOOL) EnumSystemCodePagesA(CODEPAGE_ENUMPROC, cast(DWORD));}
cast(BOOL) PeekConsoleInputA(cast(HANDLE), PINPUTRECORD, cast(DWORD), cast(LPDWORD));}
cast(BOOL) ReadConsoleInputA(cast(HANDLE), PINPUTRECORD, cast(DWORD), cast(LPDWORD));}
cast(BOOL) WriteConsoleInputA(cast(HANDLE), PINPUTRECORD, cast(DWORD), cast(LPDWORD));}
cast(BOOL) ReadConsoleOutputA(cast(HANDLE), PCHAR_INFO, COORD, COORD, PSMALL_RECT);}
cast(BOOL) WriteConsoleOutputA(cast(HANDLE), PCHAR_INFO, COORD, COORD, PSMALL_RECT);}

cast(BOOL) WriteConsoleOutputCharacterA(cast(HANDLE), cast(LPCSTR), cast(DWORD), COORD, cast(LPDWORD));}
cast(BOOL) FillConsoleOutputCharacterA(cast(HANDLE), сим, cast(DWORD), COORD, cast(LPDWORD));}
cast(BOOL) ScrollConsoleScreenBufferA(cast(HANDLE), PSMALL_RECT, PSMALL_RECT, COORD, PCHAR_INFO);}
cast(DWORD) GetConsoleTitleA(cast(LPSTR), cast(DWORD));}
cast(BOOL) SetConsoleTitleA(cast(LPCSTR));}
cast(BOOL) ReadConsoleA(cast(HANDLE), cast(LPVOID), cast(DWORD), cast(LPDWORD), cast(LPVOID));}
cast(BOOL) WriteConsoleA(cast(HANDLE), LPVOID, cast(DWORD), cast(LPDWORD), cast(LPVOID));}
cast(DWORD) WNetдобавьConnectionA(cast(LPCSTR), cast(LPCSTR), cast(LPCSTR));}
cast(DWORD) WNetдобавьConnection2A(LPNETRESOURCE, cast(LPCSTR), cast(LPCSTR), cast(DWORD));}
cast(DWORD) WNetдобавьConnection3A(HWND, LPNETRESOURCE, cast(LPCSTR), cast(LPCSTR), cast(DWORD));}
cast(DWORD) WNetCancelConnectionA(cast(LPCSTR), cast(BOOL));}
cast(DWORD) WNetCancelConnection2A(cast(LPCSTR), cast(DWORD), cast(BOOL));}
cast(DWORD) WNetGetConnectionA(cast(LPCSTR), cast(LPSTR), cast(LPDWORD));}
cast(DWORD) WNetUseConnectionA(HWND, LPNETRESOURCE, cast(LPCSTR), cast(LPCSTR), cast(DWORD), cast(LPSTR), cast(LPDWORD), cast(LPDWORD));}
cast(DWORD) WNetSetConnectionA(cast(LPCSTR), cast(DWORD), cast(LPVOID));}
cast(DWORD) WNetConnectionDialog1A(LPCONNECTDLGSTRUCT);}
cast(DWORD) WNetDisconnectDialog1A(LPDISCDLGSTRUCT);}
cast(DWORD) WNetOpenEnumA(cast(DWORD), cast(DWORD), cast(DWORD), LPNETRESOURCE, LPcast(HANDLE));}
cast(DWORD) WNetEnumResourceA(cast(HANDLE), cast(LPDWORD), cast(LPVOID), cast(LPDWORD));}
cast(DWORD) WNetGetUniversalNameA(cast(LPCSTR), cast(DWORD), cast(LPVOID), cast(LPDWORD));}
cast(DWORD) WNetGetUserA(cast(LPCSTR), cast(LPSTR), cast(LPDWORD));}
cast(DWORD) WNetGetProviderNameA(cast(DWORD), cast(LPSTR), cast(LPDWORD));}
cast(DWORD) WNetGetNetworkInformationA(cast(LPCSTR), LPNETINFOSTRUCT);}
cast(DWORD) WNetGetLastErrorA(cast(LPDWORD), cast(LPSTR), cast(DWORD), cast(LPSTR), cast(DWORD));}
cast(DWORD) MultinetGetConnectionPerformanceA(LPNETRESOURCE, LPNETCONNECTINFOSTRUCT);}
cast(BOOL) ChangeServiceConfigA(SC_cast(HANDLE), cast(DWORD), cast(DWORD), cast(DWORD), cast(LPCSTR), cast(LPCSTR), cast(LPDWORD), cast(LPCSTR), cast(LPCSTR), cast(LPCSTR), cast(LPCSTR));}
SC_cast(HANDLE) CreateServiceA(SC_cast(HANDLE), cast(LPCSTR), cast(LPCSTR), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(LPCSTR), cast(LPCSTR), cast(LPDWORD), cast(LPCSTR), cast(LPCSTR), cast(LPCSTR));}
cast(BOOL) EnumDependentServicesA(SC_cast(HANDLE), cast(DWORD), LPENUM_SERVICE_STATUS, cast(DWORD), cast(LPDWORD), cast(LPDWORD));}
cast(BOOL) EnumServicesStatusA(SC_cast(HANDLE), cast(DWORD), cast(DWORD), LPENUM_SERVICE_STATUS, cast(DWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD));}
cast(BOOL) GetServiceKeyNameA(SC_cast(HANDLE), cast(LPCSTR), cast(LPSTR), cast(LPDWORD));}
cast(BOOL) GetServiceDisplayNameA(SC_cast(HANDLE), cast(LPCSTR), cast(LPSTR), cast(LPDWORD));}
SC_cast(HANDLE) OpenSCManagerA(cast(LPCSTR), cast(LPCSTR), cast(DWORD));}
SC_cast(HANDLE) OpenServiceA(SC_cast(HANDLE), cast(LPCSTR), cast(DWORD));}
cast(BOOL) QueryServiceConfigA(SC_cast(HANDLE), LPQUERY_SERVICE_CONFIG, cast(DWORD), cast(LPDWORD));}
cast(BOOL) QueryServiceLockStatusA(SC_cast(HANDLE), LPQUERY_SERVICE_LOCK_STATUS, cast(DWORD), cast(LPDWORD));}
SERVICE_STATUS_cast(HANDLE) RegisterServiceCtrlHandlerA(cast(LPCSTR), LPcast(HANDLE)R_FUNCTION);}
cast(BOOL) StartServiceCtrlDispatcherA(LPSERVICE_TABLE_ENTRY);}
cast(BOOL) StartServiceA(SC_cast(HANDLE), cast(DWORD), cast(LPCSTR));}
бцел DragQueryFileA(HDROP, бцел, PCHAR, бцел);}
HICON ExtractAssociatedIconA(HINST, PCHAR, LPWORD);}
HICON ExtractIconA(HINST, PCHAR, бцел);}
HINST FindExecutableA(PCHAR, PCHAR, PCHAR);}
цел ShellAboutA(HWND, PCHAR, PCHAR, HICON);}
HINST ShellExecuteA(HWND, PCHAR, PCHAR, PCHAR, PCHAR, цел);}
HSZ DdeCreateStringHandleA(cast(DWORD), PCHAR, цел);}
UINT DdeInitializeA(cast(LPDWORD), PFNCALLBACK, cast(DWORD), cast(DWORD));}
cast(DWORD) DdeQueryStringA(cast(DWORD), HSZ, PCHAR, cast(DWORD), цел);}
cast(BOOL) LogonUserA(cast(LPSTR), cast(LPSTR), cast(LPSTR), cast(DWORD), cast(DWORD), Pcast(HANDLE));}
cast(BOOL) GetBinaryTypeW(cast(LPCWSTR), cast(LPDWORD));}
cast(DWORD) GetShortPathNameW(cast(LPCWSTR), cast(LPWSTR), cast(DWORD));}
cast(LPWSTR) GetEnvironmentStringsW();}
cast(BOOL) FreeEnvironmentStringsW(cast(LPWSTR));}
cast(DWORD) FormatMessageW(cast(DWORD), LPCVOID, cast(DWORD), cast(DWORD), cast(LPWSTR), cast(DWORD), VA_LIST*);}
цел lstrcmpW(cast(LPCWSTR), cast(LPCWSTR));}
цел lstrcmpiW(cast(LPCWSTR), cast(LPCWSTR));}
cast(LPWSTR) lstrcpynW(cast(LPWSTR), cast(LPCWSTR), цел);}
cast(LPWSTR) lstrcpyW(cast(LPWSTR), cast(LPCWSTR));}
cast(LPWSTR) lstrcatW(cast(LPWSTR), cast(LPCWSTR));}
цел lstrlenW(cast(LPCWSTR));}
cast(HANDLE) OpenMutexW(cast(DWORD), cast(BOOL), cast(LPCWSTR));}
cast(HANDLE) OpenEventW(cast(DWORD), cast(BOOL), cast(LPCWSTR));}
cast(HANDLE) OpenSemaphoreW(cast(DWORD), cast(BOOL), cast(LPCWSTR));}
cast(DWORD) GetLogicalDriveStringsW(cast(DWORD), cast(LPWSTR));}
cast(DWORD) GetModuleFileNameW(HINST, cast(LPWSTR), cast(DWORD));}
HMODULE GetModuleHandleW(cast(LPCWSTR));}
проц FatalAppExitW(UINT);}
cast(DWORD) GetEnvironmentVariableW(cast(LPCWSTR), cast(LPWSTR), cast(DWORD));}
cast(BOOL) SetEnvironmentVariableW(cast(LPCWSTR), cast(LPCWSTR));}
cast(DWORD) ExpandEnvironmentStringsW(cast(LPCWSTR), cast(LPWSTR), cast(DWORD));}
проц OutputDebugStringW(cast(LPCWSTR));}
HRSRC FindResourceW(HINST, cast(LPCWSTR), cast(LPCWSTR));}
HRSRC FindResourceExW(HINST, cast(LPCWSTR), cast(LPCWSTR), бкрат);}
cast(BOOL) EnumResourceTypesW(HINST, ENUMRESTYPEPROC, LONG);}
cast(BOOL) EnumResourceNamesW(HINST, cast(LPCWSTR), ENUMRESNAMEPROC, LONG);}
cast(BOOL) EnumResourceLanguagesW(HINST, cast(LPCWSTR), cast(LPCWSTR), ENUMRESLANGPROC, LONG);}
cast(BOOL) UpdateResourceW(cast(HANDLE), cast(LPCWSTR), cast(LPCWSTR), бкрат, cast(LPVOID), cast(DWORD));}
cast(BOOL) EndUpdateResourceW(cast(HANDLE), cast(BOOL));}
ATOM GlobalдобавьAtomW(cast(LPCWSTR));}
ATOM GlobalFindAtomW(cast(LPCWSTR));}
UINT GlobalGetAtomNameW(ATOM, cast(LPWSTR), цел);}
ATOM добавьAtomW(cast(LPCWSTR));}
ATOM FindAtomW(cast(LPCWSTR));}
UINT GetAtomNameW(ATOM, cast(LPWSTR), цел);}
UINT GetProfileIntW(cast(LPCWSTR), cast(LPCWSTR), INT);}
cast(DWORD) GetProfileStringW(cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR), cast(LPWSTR), cast(DWORD));}
cast(BOOL) WriteProfileStringW(cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR));}
cast(DWORD) GetProfileSectionW(cast(LPCWSTR), cast(LPWSTR), cast(DWORD));}
cast(BOOL) WriteProfileSectionW(cast(LPCWSTR), cast(LPCWSTR));}
UINT GetPrivateProfileIntW(cast(LPCWSTR), cast(LPCWSTR), INT, cast(LPCWSTR));}
cast(DWORD) GetPrivateProfileStringW(cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR), cast(LPWSTR), cast(DWORD), cast(LPCWSTR));}
cast(BOOL) WritePrivateProfileStringW(cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR));}
cast(DWORD) GetPrivateProfileSectionW(cast(LPCWSTR), cast(LPWSTR), cast(DWORD), cast(LPCWSTR));}
cast(BOOL) WritePrivateProfileSectionW(cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR));}
UINT GetDriveTypeW(cast(LPCWSTR));}
UINT GetSystemDirectoryW(cast(LPWSTR), UINT);}
cast(DWORD) GetTempPathW(cast(DWORD), cast(LPWSTR));}
UINT GetTempFileNameW(cast(LPCWSTR), cast(LPCWSTR), UINT, cast(LPWSTR));}
UINT GetWindowsDirectoryW(cast(LPWSTR), UINT);}
cast(BOOL) GetDiskFreeSpaceW(cast(LPCWSTR), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD));}
cast(DWORD) GetFullPathNameW(cast(LPCWSTR), cast(DWORD), cast(LPWSTR), cast(LPWSTR)*);}
cast(DWORD) QueryDosDeviceW(cast(LPCWSTR), cast(LPWSTR), cast(DWORD));}
cast(BOOL) SetFileAttributesW(cast(LPCWSTR), cast(DWORD));}
cast(DWORD) GetFileAttributesW(cast(LPCWSTR));}
cast(BOOL) GetFileAttributesExW(cast(LPCWSTR), cast(DWORD), WIN32_FILE_ATTRIBUTE_DATA*);}
cast(DWORD) GetCompressedFileSizeW(cast(LPCWSTR), cast(LPDWORD));}
cast(DWORD) SearchPathW(cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR), cast(DWORD), cast(LPWSTR), cast(LPWSTR));}
cast(BOOL) CopyFileW(cast(LPCWSTR), cast(LPCWSTR), cast(BOOL));}
cast(BOOL) MoveFileW(cast(LPCWSTR), cast(LPCWSTR));}
cast(BOOL) MoveFileExW(cast(LPCWSTR), cast(LPCWSTR), cast(DWORD));}
cast(BOOL) GetNamedPipeHandleStateW(cast(HANDLE), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPWSTR), cast(DWORD));}
cast(BOOL) WaitNamedPipeW(cast(LPCWSTR), cast(DWORD));}
cast(BOOL) SetVolumeLabelW(cast(LPCWSTR), cast(LPCWSTR));}
cast(BOOL) GetVolumePathNameW(cast(LPCWSTR), cast(LPWSTR), cast(DWORD));}
cast(BOOL) GetVolumeInformationW(cast(LPCWSTR), cast(LPWSTR), cast(DWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPWSTR), cast(DWORD));}
cast(BOOL) ClearEventLogW(cast(HANDLE), cast(LPCWSTR));}
cast(BOOL) BackupEventLogW(cast(HANDLE), cast(LPCWSTR));}
cast(HANDLE) OpenEventLogW(cast(LPCWSTR), cast(LPCWSTR));}
cast(HANDLE) RegisterEventSourceW(cast(LPCWSTR), cast(LPCWSTR));}
cast(HANDLE) OpenBackupEventLogW(cast(LPCWSTR), cast(LPCWSTR));}
cast(BOOL) ReadEventLogW(cast(HANDLE), cast(DWORD), cast(DWORD), cast(LPVOID), cast(DWORD), cast(LPDWORD), cast(LPDWORD));}
cast(BOOL) ReportEventW(cast(HANDLE), бкрат, бкрат, cast(DWORD), PSID, бкрат, cast(DWORD), cast(LPCWSTR)*, cast(LPVOID));}
cast(BOOL) AccessCheckAndAuditAlarmW(cast(LPCWSTR), cast(LPVOID), cast(LPWSTR), cast(LPWSTR), PSECURITY_DESCRIPTOR, cast(DWORD), PGENERIC_MAPPING, cast(BOOL), cast(LPDWORD), LPcast(BOOL), LPcast(BOOL));}
cast(BOOL) ObjectOpenAuditAlarmW(cast(LPCWSTR), cast(LPVOID), cast(LPWSTR), cast(LPWSTR), PSECURITY_DESCRIPTOR, cast(HANDLE), cast(DWORD), cast(DWORD), PPRIVILEGE_SET, cast(BOOL), cast(BOOL), LPcast(BOOL));}
cast(BOOL) ObjectPrivilegeAuditAlarmW(cast(LPCWSTR), cast(LPVOID), cast(HANDLE), cast(DWORD), PPRIVILEGE_SET, cast(BOOL));}
cast(BOOL) ObjectCloseAuditAlarmW(cast(LPCWSTR), cast(LPVOID), cast(BOOL));}
cast(BOOL) PrivilegedServiceAuditAlarmW(cast(LPCWSTR), cast(LPCWSTR), cast(HANDLE), PPRIVILEGE_SET, cast(BOOL));}
cast(BOOL) SetFileSecurityW(cast(LPCWSTR), SECURITY_INFORMATION, PSECURITY_DESCRIPTOR);}
cast(BOOL) GetFileSecurityW(cast(LPCWSTR), SECURITY_INFORMATION, PSECURITY_DESCRIPTOR, cast(DWORD), cast(LPDWORD));}
cast(HANDLE) FindFirstChangeNotificationW(cast(LPCWSTR), cast(BOOL), cast(DWORD));}
cast(BOOL) LookupAccountSidW(cast(LPCWSTR), PSID, cast(LPWSTR), cast(LPDWORD), cast(LPWSTR), cast(LPDWORD), PSID_NAME_USE);}
cast(BOOL) LookupAccountNameW(cast(LPCWSTR), cast(LPCWSTR), PSID, cast(LPDWORD), cast(LPWSTR), cast(LPDWORD), PSID_NAME_USE);}
cast(BOOL) LookupPrivilegeValueW(cast(LPCWSTR), cast(LPCWSTR), PLUID);}
cast(BOOL) LookupPrivilegeNameW(cast(LPCWSTR), PLUID, cast(LPWSTR), cast(LPDWORD));}
cast(BOOL) LookupPrivilegeDisplayNameW(cast(LPCWSTR), cast(LPCWSTR), cast(LPWSTR), cast(LPDWORD), cast(LPDWORD));}
cast(BOOL) BuildCommDCBAndTimeoutsW(cast(LPCWSTR), LPDCB, LPCOMMTIMEOUTS);}
cast(BOOL) GetDefaultCommConfigW(cast(LPCWSTR), LPCOMMCONFIG, cast(LPDWORD));}
cast(BOOL) SetDefaultCommConfigW(cast(LPCWSTR), LPCOMMCONFIG, cast(DWORD));}
cast(BOOL) GetComputerNameW(cast(LPWSTR), cast(LPDWORD));}
cast(BOOL) SetComputerNameW(cast(LPCWSTR));}
cast(BOOL) GetUserNameW(cast(LPWSTR), cast(LPDWORD));}
цел wvsprintfW(cast(LPWSTR), cast(LPCWSTR), VA_LIST*);}
HKL LoadKeyboardLayoutW(cast(LPCWSTR), UINT);}
cast(BOOL) GetKeyboardLayoutNameW(cast(LPWSTR));}
HDESK CreateDesktopW(cast(LPWSTR), cast(LPWSTR), LPDEVMODE, cast(DWORD), cast(DWORD), cast(LPSECURITY_ATTRIBUTES));}
HDESK OpenDesktopW(cast(LPWSTR), cast(DWORD), cast(BOOL), cast(DWORD));}
cast(BOOL) EnumDesktopsW(HWINSTA, DESKTOPENUMPROC, LPARAM);}
HWINSTA CreateWindowStationW(cast(LPWSTR), cast(DWORD), cast(DWORD), cast(LPSECURITY_ATTRIBUTES));}
HWINSTA OpenWindowStationW(cast(LPWSTR), cast(BOOL), cast(DWORD));}
cast(BOOL) EnumWindowStationsW(ENUMWINDOWSTATIONPROC, LPARAM);}
cast(BOOL) GetUserObjectInformationW(cast(HANDLE), цел, PVOID, cast(DWORD), cast(LPDWORD));}
cast(BOOL) SetUserObjectInformationW(cast(HANDLE), цел, PVOID, cast(DWORD));}
UINT RegisterWindowMessageW(cast(LPCWSTR));}
cast(BOOL) GetMessageW(LPMSG, HWND, UINT, UINT);}
LONG DispatchMessageW(LPMSG);}
cast(BOOL) PeekMessageW(LPMSG, HWND, UINT, UINT, UINT);}
LRESULT SendMessageW(HWND, UINT, WPARAM, LPARAM);}
LRESULT SendMessageW(HWND, UINT, WPARAM, проц*);}
LRESULT SendMessageW(HWND, UINT, проц*, LPARAM);}
LRESULT SendMessageW(HWND, UINT, проц*, проц*);}
LRESULT SendMessageTimeoutW(HWND, UINT, WPARAM, LPARAM, UINT, UINT, cast(LPDWORD));}
cast(BOOL) SendNotifyMessageW(HWND, UINT, WPARAM, LPARAM);}
cast(BOOL) SendMessageCallbackW(HWND, UINT, WPARAM, LPARAM, SENDASYNCPROC, cast(DWORD));}
cast(BOOL) PostMessageW(HWND, UINT, WPARAM, LPARAM);}
cast(BOOL) PostThreadMessageW(cast(DWORD), UINT, WPARAM, LPARAM);}
LRESULT DefWindowProcW(HWND, UINT, WPARAM, LPARAM);}
LRESULT CallWindowProcW(WNDPROC, HWND, UINT, WPARAM, LPARAM);}
ATOM RegisterClassW(LPWNDCLASSW);}
cast(BOOL) UnregisterClassW(cast(LPCWSTR), HINST);}
cast(BOOL) GetClassInfoW(HINST, cast(LPCWSTR), LPWNDCLASS);}
ATOM RegisterClassExW(LPWNDCLASSEX);}
cast(BOOL) GetClassInfoExW(HINST, cast(LPCWSTR), LPWNDCLASSEX);}
HWND CreateWindowExW(cast(DWORD), cast(LPCWSTR), cast(LPCWSTR), cast(DWORD), цел, цел, цел, цел, HWND, HMENU, HINST, cast(LPVOID));}
HWND CreateDialogParamW(HINST, cast(LPCWSTR), HWND, DLGPROC, LPARAM);}
HWND CreateDialogIndirectParamW(HINST, LPCDLGTEMPLATE, HWND, DLGPROC, LPARAM);}
цел DialogBoxParamW(HINST, cast(LPCWSTR), HWND, DLGPROC, LPARAM);}
цел DialogBoxIndirectParamW(HINST, LPCDLGTEMPLATE, HWND, DLGPROC, LPARAM);}
cast(BOOL) SetDlgItemTextW(HWND, цел, cast(LPCWSTR));}
UINT GetDlgItemTextW(HWND, цел, cast(LPWSTR), цел);}
LONG SendDlgItemMessageW(HWND, цел, UINT, WPARAM, LPARAM);}
LRESULT DefDlgProcW(HWND, UINT, WPARAM, LPARAM);}
cast(BOOL) CallMsgFilterW(LPMSG, цел);}
UINT RegisterClipboardFormatW(cast(LPCWSTR));}
цел GetClipboardFormatNameW(UINT, cast(LPWSTR), цел);}
cast(BOOL) CharToOemW(cast(LPCWSTR), cast(LPSTR));}
cast(BOOL) OemToCharW(cast(LPCSTR), cast(LPWSTR));}
cast(BOOL) CharToOemBuffW(cast(LPCWSTR), cast(LPSTR), cast(DWORD));}
cast(BOOL) OemToCharBuffW(cast(LPCSTR), cast(LPWSTR), cast(DWORD));}
cast(LPWSTR) CharUpperW(cast(LPWSTR));}
cast(DWORD) CharUpperBuffW(cast(LPWSTR), cast(DWORD));}
cast(LPWSTR) CharLowerW(cast(LPWSTR));}
cast(DWORD) CharLowerBuffW(cast(LPWSTR), cast(DWORD));}
cast(LPWSTR) CharNextW(cast(LPCWSTR));}
cast(LPWSTR) CharPrevW(cast(LPCWSTR), cast(LPCWSTR));}
cast(BOOL) IsCharAlphaW(WCHAR);}
cast(BOOL) IsCharAlphaNumericW(WCHAR);}
cast(BOOL) IsCharUpperW(WCHAR);}
cast(BOOL) IsCharLowerW(WCHAR);}
цел GetKeyNameTextW(LONG, cast(LPWSTR), цел);}
SHORT VkKeyScanW(WCHAR);}
SHORT VkKeyScanExW(WCHAR, HKL);}
UINT MapVirtualKeyW(UINT, UINT);}
UINT MapVirtualKeyExW(UINT, UINT, HKL);}
HACCEL LoadAcceleratorsW(HINST, cast(LPCWSTR));}
HACCEL CreateAcceleratorTableW(LPACCEL, цел);}
цел CopyAcceleratorTableW(HACCEL, LPACCEL, цел);}
цел TranslateAcceleratorW(HWND, HACCEL, LPMSG);}
HMENU LoadMenuW(HINST, cast(LPCWSTR));}
HMENU LoadMenuIndirectW(LPMENUTEMPLATE);}
cast(BOOL) ChangeMenuW(HMENU, UINT, cast(LPCWSTR), UINT, UINT);}
цел GetMenuStringW(HMENU, UINT, cast(LPWSTR), цел, UINT);}
cast(BOOL) InsertMenuW(HMENU, UINT, UINT, UINT, cast(LPCWSTR));}
cast(BOOL) AppendMenuW(HMENU, UINT, UINT, cast(LPCWSTR));}
cast(BOOL) ModifyMenuW(HMENU, UINT, UINT, UINT, cast(LPCWSTR));}
cast(BOOL) InsertMenuItemW(HMENU, UINT, cast(BOOL), LPCMENUITEMINFO);}
cast(BOOL) GetMenuItemInfoW(HMENU, UINT, cast(BOOL), LPMENUITEMINFO);}
cast(BOOL) SetMenuItemInfoW(HMENU, UINT, cast(BOOL), LPCMENUITEMINFO);}
цел DrawTextW(HDC, cast(LPCWSTR), цел, LPRECT, UINT);}
цел DrawTextExW(HDC, cast(LPWSTR), цел, LPRECT, UINT, LPDRAWTEXTPARAMS);}
cast(BOOL) GrayStringW(HDC, HBRUSH, GRAYSTRINGPROC, LPARAM, цел, цел, цел, цел, цел);}
cast(BOOL) DrawStateW(HDC, HBRUSH, DRAWSTATEPROC, LPARAM, WPARAM, цел, цел, цел, цел, UINT);}
LONG TabbedTextOutW(HDC, цел, цел, cast(LPCWSTR), цел, цел, LPINT, цел);}
cast(DWORD) GetTabbedTextExtentW(HDC, cast(LPCWSTR), цел, цел, LPINT);}
cast(BOOL) SetPropW(HWND, cast(LPCWSTR), cast(HANDLE));}
cast(HANDLE) GetPropW(HWND, cast(LPCWSTR));}
cast(HANDLE) RemovePropW(HWND, cast(LPCWSTR));}
цел EnumPropsExW(HWND, PROPENUMPROCEX, LPARAM);}
цел EnumPropsW(HWND, PROPENUMPROC);}
cast(BOOL) SetWindowTextW(HWND, cast(LPCWSTR));}
цел GetWindowTextW(HWND, cast(LPWSTR), цел);}
цел GetWindowTextLengthW(HWND);}
цел MessageBoxW(HWND, cast(LPCWSTR), cast(LPCWSTR), UINT);}
цел MessageBoxExW(HWND, cast(LPCWSTR), cast(LPCWSTR), UINT, бкрат);}
цел MessageBoxIndirectW(LPMSGBOXPARAMS);}
LONG GetWindowLongW(HWND, цел);}
LONG SetWindowLongW(HWND, цел, LONG);}
cast(DWORD) GetClassLongW(HWND, цел);}
cast(DWORD) SetClassLongW(HWND, цел, LONG);}
HWND FindWindowW(cast(LPCWSTR), cast(LPCWSTR));}
HWND FindWindowExW(HWND, HWND, cast(LPCWSTR), cast(LPCWSTR));}
цел GetClassNameW(HWND, cast(LPWSTR), цел);}
HHOOK SetWindowsHookExW(цел, HOOKPROC, HINST, cast(DWORD));}
HBITMAP LoadBitmapW(HINST, cast(LPCWSTR));}
HCURSOR LoadCursorW(HINST, cast(LPCWSTR));}
HCURSOR LoadCursorFromFileW(cast(LPCWSTR));}
HICON LoadIconW(HINST, cast(LPCWSTR));}
cast(HANDLE) LoadImageW(HINST, cast(LPCWSTR), UINT, цел, цел, UINT);}
цел LoadStringW(HINST, UINT, cast(LPWSTR), цел);}
cast(BOOL) IsDialogMessageW(HWND, LPMSG);}
цел DlgDirListW(HWND, cast(LPWSTR), цел, цел, UINT);}
cast(BOOL) DlgDirSelectExW(HWND, cast(LPWSTR), цел, цел);}
цел DlgDirListComboBoxW(HWND, cast(LPWSTR), цел, цел, UINT);}
cast(BOOL) DlgDirSelectComboBoxExW(HWND, cast(LPWSTR), цел, цел);}
LRESULT DefFrameProcW(HWND, HWND, UINT, WPARAM, LPARAM);}
LRESULT DefMDIChildProcW(HWND, UINT, WPARAM, LPARAM);}
HWND CreateMDIWindowW(cast(LPWSTR), cast(LPWSTR), cast(DWORD), цел, цел, цел, цел, HWND, HINST, LPARAM);}
cast(BOOL) WinHelpW(HWND, cast(LPCWSTR), UINT, cast(DWORD));}
LONG ChangeDisplaySettingsW(LPDEVMODE, cast(DWORD));}
cast(BOOL) EnumDisplaySettingsW(cast(LPCWSTR), cast(DWORD), LPDEVMODE);}
cast(BOOL) SystemParametersInfoW(UINT, UINT, PVOID, UINT);}
цел добавьFontResourceW(cast(LPCWSTR));}
HMETAFILE CopyMetaFileW(HMETAFILE, cast(LPCWSTR));}
HFONT CreateFontIndirectW(PLOGFONT);}
HFONT CreateFontW(цел, цел, цел, цел, цел, cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(LPCWSTR));}
HDC CreateICW(cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR), LPDEVMODE);}
HDC CreateMetaFileW(cast(LPCWSTR));}
cast(BOOL) CreateScalableFontResourceW(cast(DWORD), cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR));}
цел EnumFontFamiliesExW(HDC, LPLOGFONT, FONTENUMEXPROC, LPARAM, cast(DWORD));}
цел EnumFontFamiliesW(HDC, cast(LPCWSTR), FONTENUMPROC, LPARAM);}
цел EnumFontsW(HDC, cast(LPCWSTR), ENUMFONTSPROC, LPARAM);}
cast(BOOL) GetCharWidthW(HDC, UINT, UINT, LPINT);}
cast(BOOL) GetCharWidth32W(HDC, UINT, UINT, LPINT);}
cast(BOOL) GetCharWidthFloatW(HDC, UINT, UINT, PFLOAT);}
cast(BOOL) GetCharABCWidthsW(HDC, UINT, UINT, LPABC);}
cast(BOOL) GetCharABCWidthsFloatW(HDC, UINT, UINT, LPABCFLOAT);}
cast(DWORD) GetGlyphOutlineW(HDC, UINT, UINT, LPGLYPHMETRICS, cast(DWORD), cast(LPVOID), PMAT2);}
HMETAFILE GetMetaFileW(cast(LPCWSTR));}
UINT GetOutlineTextMetricsW(HDC, UINT, LPOUTLINETEXTMETRIC);}
cast(BOOL) GetTextExtentPointW(HDC, cast(LPCWSTR), цел, LPSIZE);}
cast(BOOL) GetTextExtentPoint32W(HDC, cast(LPCWSTR), цел, LPSIZE);}
cast(BOOL) GetTextExtentExPointW(HDC, cast(LPCWSTR), цел, цел, LPINT, LPINT, LPSIZE);}
cast(DWORD) GetCharacterPlacementW(HDC, cast(LPCWSTR), цел, цел, LPGCP_RESULTS, cast(DWORD));}
HDC ResetDCW(HDC, LPDEVMODE);}
cast(BOOL) RemoveFontResourceW(cast(LPCWSTR));}
HENHMETAFILE CopyEnhMetaFileW(HENHMETAFILE, cast(LPCWSTR));}
HDC CreateEnhMetaFileW(HDC, cast(LPCWSTR), LPRECT, cast(LPCWSTR));}
HENHMETAFILE GetEnhMetaFileW(cast(LPCWSTR));}
UINT GetEnhMetaFileDescriptionW(HENHMETAFILE, UINT, cast(LPWSTR));}
cast(BOOL) GetTextMetricsW(HDC, LPTEXTMETRIC);}
цел StartDocW(HDC, PDOCINFO);}
цел GetObjectW(HGDIOBJ, цел, cast(LPVOID));}
cast(BOOL) TextOutW(HDC, цел, цел, cast(LPCWSTR), цел);}
cast(BOOL) ExtTextOutW(HDC, цел, цел, UINT, LPRECT, cast(LPCWSTR), UINT, LPINT);}
cast(BOOL) PolyTextOutW(HDC, PPOLYTEXT, цел);}
цел GetTextFaceW(HDC, цел, cast(LPWSTR));}
cast(DWORD) GetKerningPairsW(HDC, cast(DWORD), LPKERNINGPAIR);}
cast(BOOL) GetLogColorSpaceW(HCOLORSPACE, LPLOGCOLORSPACE, cast(DWORD));}
HCOLORSPACE CreateColorSpaceW(LPLOGCOLORSPACE);}
cast(BOOL) GetICMProfileW(HDC, cast(DWORD), cast(LPWSTR));}
cast(BOOL) SetICMProfileW(HDC, cast(LPWSTR));}
cast(BOOL) UpdateICMRegKeyW(cast(DWORD), cast(DWORD), cast(LPWSTR), UINT);}
цел EnumICMProfilesW(HDC, ICMENUMPROC, LPARAM);}
HPROPSHEETPAGE CreatePropertySheetPageW(LPCPROPSHEETPAGE);}
цел PropertySheetW(LPCPROPSHEETHEADER);}
HIMAGELIST ImageList_LoadImageW(HINST, cast(LPCWSTR), цел, цел, COLORREF, UINT, UINT);}
HWND CreateStatusWindowW(LONG, cast(LPCWSTR), HWND, UINT);}
проц DrawStatusTextW(HDC, LPRECT, cast(LPCWSTR));}
cast(BOOL) GetOpenFileNameW(LPOPENFILENAME);}
cast(BOOL) GetSaveFileNameW(LPOPENFILENAME);}
цел GetFileTitleW(cast(LPCWSTR), cast(LPWSTR), бкрат);}
cast(BOOL) ChooseColorW(LPCHOOSECOLOR);}
HWND ReplaceTextW(LPFINDREPLACE);}
cast(BOOL) ChooseFontW(LPCHOOSEFONTW);}
HWND FindTextW(LPFINDREPLACE);}
cast(BOOL) PrintDlgW(LPPRINTDLGW);}
cast(BOOL) PageSetupDlgW(LPPAGESETUPDLG);}
проц GetStartupInfoW(cast(LPSTARTUPINFO));}
cast(HANDLE) FindFirstFileW(cast(LPCWSTR), LPWIN32_FIND_DATAW);}
cast(BOOL) FindNextFileW(cast(HANDLE), LPWIN32_FIND_DATAW);}
cast(BOOL) GetVersionExW(LPOSVERSIONINFO);}
HDC CreateDCW(cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR), PDEVMODE);}
HFONT CreateFontA(цел, цел, цел, цел, цел, cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(LPCSTR));}
cast(DWORD) VerInstallFileW(cast(DWORD), cast(LPWSTR), cast(LPWSTR), cast(LPWSTR), cast(LPWSTR), cast(LPWSTR), cast(LPWSTR), PUINT);}
cast(DWORD) GetFileVersionInfoSizeW(cast(LPWSTR), cast(LPDWORD));}
cast(BOOL) GetFileVersionInfoW(cast(LPWSTR), cast(DWORD), cast(DWORD), cast(LPVOID));}
cast(DWORD) VerLanguageNameW(cast(DWORD), cast(LPWSTR), cast(DWORD));}
cast(BOOL) VerQueryValueW(cast(LPVOID), cast(LPWSTR), cast(LPVOID), PUINT);}
cast(DWORD) VerFindFileW(cast(DWORD), cast(LPWSTR), cast(LPWSTR), cast(LPWSTR), cast(LPWSTR), PUINT, cast(LPWSTR), PUINT);}
LONG RegSetValueExW(HKEY, cast(LPCWSTR), cast(DWORD), cast(DWORD), LPBYTE, cast(DWORD));}
LONG RegUnLoadKeyW(HKEY, cast(LPCWSTR));}
cast(BOOL) InitiateSystemShutdownW(cast(LPWSTR), cast(LPWSTR), cast(DWORD), cast(BOOL), cast(BOOL));}
cast(BOOL) AbortSystemShutdownW(cast(LPWSTR));}
LONG RegRestoreKeyW(HKEY, cast(LPCWSTR), cast(DWORD));}
LONG RegSaveKeyW(HKEY, cast(LPCWSTR), cast(LPSECURITY_ATTRIBUTES));}
LONG RegSetValueW(HKEY, cast(LPCWSTR), cast(DWORD), cast(LPCWSTR), cast(DWORD));}
LONG RegQueryValueW(HKEY, cast(LPCWSTR), cast(LPWSTR), PLONG);}
LONG RegQueryMultipleValuesW(HKEY, PVALENT, cast(DWORD), cast(LPWSTR), cast(LPDWORD));}
LONG RegQueryValueExW(HKEY, cast(LPCWSTR), cast(LPDWORD), cast(LPDWORD), LPBYTE, cast(LPDWORD));}
LONG RegReplaceKeyW(HKEY, cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR));}
LONG RegConnectRegistryW(cast(LPWSTR), HKEY, PHKEY);}
LONG RegCreateKeyW(HKEY, cast(LPCWSTR), PHKEY);}
LONG RegCreateKeyExW(HKEY, cast(LPCWSTR), cast(DWORD), cast(LPWSTR), cast(DWORD), REGSAM, cast(LPSECURITY_ATTRIBUTES), PHKEY, cast(LPDWORD));}
LONG RegDeleteKeyW(HKEY, cast(LPCWSTR));}
LONG RegDeleteValueW(HKEY, cast(LPCWSTR));}
LONG RegEnumKeyW(HKEY, cast(DWORD), cast(LPWSTR), cast(DWORD));}
LONG RegEnumKeyExW(HKEY, cast(DWORD), cast(LPWSTR), cast(LPDWORD), cast(LPDWORD), cast(LPWSTR), cast(LPDWORD), PFILETIME);}
LONG RegEnumValueW(HKEY, cast(DWORD), cast(LPWSTR), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), LPBYTE, cast(LPDWORD));}
LONG RegLoadKeyW(HKEY, cast(LPCWSTR), cast(LPCWSTR));}
LONG RegOpenKeyW(HKEY, cast(LPCWSTR), PHKEY);}
LONG RegOpenKeyExW(HKEY, cast(LPCWSTR), cast(DWORD), REGSAM, PHKEY);}
LONG RegQueryInfoKeyW(HKEY, cast(LPWSTR), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), PFILETIME);}
цел LCMapStringW(LCID, cast(DWORD), cast(LPCWSTR), цел, cast(LPWSTR), цел);}
цел GetLocaleInfoW(LCID, LCTYPE, cast(LPWSTR), цел);}
cast(BOOL) SetLocaleInfoW(LCID, LCTYPE, cast(LPCWSTR));}
цел GetTimeFormatW(LCID, cast(DWORD), LPSYSTEMTIME, cast(LPCWSTR), cast(LPWSTR), цел);}
цел GetDateFormatW(LCID, cast(DWORD), LPSYSTEMTIME, cast(LPCWSTR), cast(LPWSTR), цел);}
цел GetNumberFormatW(LCID, cast(DWORD), cast(LPCWSTR), PNUMBERFMT, cast(LPWSTR), цел);}
цел GetCurrencyFormatW(LCID, cast(DWORD), cast(LPCWSTR), PCURRENCYFMT, cast(LPWSTR), цел);}
cast(BOOL) EnumCalendarInfoW(CALINFO_ENUMPROC, LCID, CALID, CALTYPE);}
cast(BOOL) EnumTimeFormatsW(TIMEFMT_ENUMPROC, LCID, cast(DWORD));}
cast(BOOL) EnumDateFormatsW(DATEFMT_ENUMPROC, LCID, cast(DWORD));}
cast(BOOL) GetStringTypeExW(LCID, cast(DWORD), cast(LPCWSTR), цел, LPWORD);}
cast(BOOL) GetStringTypeW(cast(DWORD), cast(LPCWSTR), цел, LPWORD);}
цел FoldStringW(cast(DWORD), cast(LPCWSTR), цел, cast(LPWSTR), цел);}
cast(BOOL) EnumSystemLocalesW(LOCALE_ENUMPROC, cast(DWORD));}
cast(BOOL) EnumSystemCodePagesW(CODEPAGE_ENUMPROC, cast(DWORD));}
cast(BOOL) PeekConsoleInputW(cast(HANDLE), PINPUTRECORD, cast(DWORD), cast(LPDWORD));}
cast(BOOL) ReadConsoleInputW(cast(HANDLE), PINPUTRECORD, cast(DWORD), cast(LPDWORD));}
cast(BOOL) WriteConsoleInputW(cast(HANDLE), PINPUTRECORD, cast(DWORD), cast(LPDWORD));}
cast(BOOL) ReadConsoleOutputW(cast(HANDLE), PCHAR_INFO, COORD, COORD, PSMALL_RECT);}
cast(BOOL) WriteConsoleOutputW(cast(HANDLE), PCHAR_INFO, COORD, COORD, PSMALL_RECT);}
cast(BOOL) WriteConsoleOutputCharacterW(cast(HANDLE), cast(LPCWSTR), cast(DWORD), COORD, cast(LPDWORD));}
cast(BOOL) FillConsoleOutputCharacterW(cast(HANDLE), WCHAR, cast(DWORD), COORD, cast(LPDWORD));}
cast(BOOL) ScrollConsoleScreenBufferW(cast(HANDLE), PSMALL_RECT, PSMALL_RECT, COORD, PCHAR_INFO);}
cast(DWORD) GetConsoleTitleW(cast(LPWSTR), cast(DWORD));}
cast(BOOL) SetConsoleTitleW(cast(LPCWSTR));}
cast(BOOL) ReadConsoleW(cast(HANDLE), cast(LPVOID), cast(DWORD), cast(LPDWORD), cast(LPVOID));}
cast(BOOL) WriteConsoleW(cast(HANDLE), LPVOID, cast(DWORD), cast(LPDWORD), cast(LPVOID));}
cast(DWORD) WNetдобавьConnectionW(cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR));}
cast(DWORD) WNetдобавьConnection2W(LPNETRESOURCE, cast(LPCWSTR), cast(LPCWSTR), cast(DWORD));}
cast(DWORD) WNetдобавьConnection3W(HWND, LPNETRESOURCE, cast(LPCWSTR), cast(LPCWSTR), cast(DWORD));}
cast(DWORD) WNetCancelConnectionW(cast(LPCWSTR), cast(BOOL));}
cast(DWORD) WNetCancelConnection2W(cast(LPCWSTR), cast(DWORD), cast(BOOL));}
cast(DWORD) WNetGetConnectionW(cast(LPCWSTR), cast(LPWSTR), cast(LPDWORD));}
cast(DWORD) WNetUseConnectionW(HWND, LPNETRESOURCE, cast(LPCWSTR), cast(LPCWSTR), cast(DWORD), cast(LPWSTR), cast(LPDWORD), cast(LPDWORD));}
cast(DWORD) WNetSetConnectionW(cast(LPCWSTR), cast(DWORD), cast(LPVOID));}
cast(DWORD) WNetConnectionDialog1W(LPCONNECTDLGSTRUCT);}
cast(DWORD) WNetDisconnectDialog1W(LPDISCDLGSTRUCT);}
cast(DWORD) WNetOpenEnumW(cast(DWORD), cast(DWORD), cast(DWORD), LPNETRESOURCE, LPcast(HANDLE));}
cast(DWORD) WNetEnumResourceW(cast(HANDLE), cast(LPDWORD), cast(LPVOID), cast(LPDWORD));}
cast(DWORD) WNetGetUniversalNameW(cast(LPCWSTR), cast(DWORD), cast(LPVOID), cast(LPDWORD));}
cast(DWORD) WNetGetUserW(cast(LPCWSTR), cast(LPWSTR), cast(LPDWORD));}
cast(DWORD) WNetGetProviderNameW(cast(DWORD), cast(LPWSTR), cast(LPDWORD));}
cast(DWORD) WNetGetNetworkInformationW(cast(LPCWSTR), LPNETINFOSTRUCT);}
cast(DWORD) WNetGetLastErrorW(cast(LPDWORD), cast(LPWSTR), cast(DWORD), cast(LPWSTR), cast(DWORD));}
cast(DWORD) MultinetGetConnectionPerformanceW(LPNETRESOURCE, LPNETCONNECTINFOSTRUCT);}
cast(BOOL) ChangeServiceConfigW(SC_cast(HANDLE), cast(DWORD), cast(DWORD), cast(DWORD), cast(LPCWSTR), cast(LPCWSTR), cast(LPDWORD), cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR));}
SC_cast(HANDLE) CreateServiceW(SC_cast(HANDLE), cast(LPCWSTR), cast(LPCWSTR), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(LPCWSTR), cast(LPCWSTR), cast(LPDWORD), cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR));}
cast(BOOL) EnumDependentServicesW(SC_cast(HANDLE), cast(DWORD), LPENUM_SERVICE_STATUS, cast(DWORD), cast(LPDWORD), cast(LPDWORD));}
cast(BOOL) EnumServicesStatusW(SC_cast(HANDLE), cast(DWORD), cast(DWORD), LPENUM_SERVICE_STATUS, cast(DWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD));}
cast(BOOL) GetServiceKeyNameW(SC_cast(HANDLE), cast(LPCWSTR), cast(LPWSTR), cast(LPDWORD));}
cast(BOOL) GetServiceDisplayNameW(SC_cast(HANDLE), cast(LPCWSTR), cast(LPWSTR), cast(LPDWORD));}
SC_cast(HANDLE) OpenSCManagerW(cast(LPCWSTR), cast(LPCWSTR), cast(DWORD));}
SC_cast(HANDLE) OpenServiceW(SC_cast(HANDLE), cast(LPCWSTR), cast(DWORD));}
cast(BOOL) QueryServiceConfigW(SC_cast(HANDLE), LPQUERY_SERVICE_CONFIG, cast(DWORD), cast(LPDWORD));}
cast(BOOL) QueryServiceLockStatusW(SC_cast(HANDLE), LPQUERY_SERVICE_LOCK_STATUS, cast(DWORD), cast(LPDWORD));}
SERVICE_STATUS_cast(HANDLE) RegisterServiceCtrlHandlerW(cast(LPCWSTR), LPcast(HANDLE)R_FUNCTION);}
cast(BOOL) StartServiceCtrlDispatcherW(LPSERVICE_TABLE_ENTRY);}
cast(BOOL) StartServiceW(SC_cast(HANDLE), cast(DWORD), cast(LPCWSTR));}
бцел DragQueryFileW(HDROP, бцел, cast(LPCWSTR), бцел);}
HICON ExtractAssociatedIconW(HINST, cast(LPCWSTR), LPWORD);}
HICON ExtractIconW(HINST, cast(LPCWSTR), бцел);}
HINST FindExecutableW(cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR));}
цел ShellAboutW(HWND, cast(LPCWSTR), cast(LPCWSTR), HICON);}
HINST ShellExecuteW(HWND, cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR), cast(LPCWSTR), цел);}
HSZ DdeCreateStringHandleW(cast(DWORD), cast(LPCWSTR), цел);}
UINT DdeInitializeW(cast(LPDWORD), PFNCALLBACK, cast(DWORD), cast(DWORD));}
cast(DWORD) DdeQueryStringW(cast(DWORD), HSZ, cast(LPCWSTR), cast(DWORD), цел);}
cast(BOOL) LogonUserW(cast(LPWSTR), cast(LPWSTR), cast(LPWSTR), cast(DWORD), cast(DWORD), Pcast(HANDLE));}
cast(BOOL) AccessCheck(PSECURITY_DESCRIPTOR, cast(HANDLE), cast(DWORD), PGENERIC_MAPPING, PPRIVILEGE_SET, cast(LPDWORD), cast(LPDWORD), LPcast(BOOL));}
LONG InterlockedIncrement(LPLONG);}
LONG InterlockedDecrement(LPLONG);}
LONG InterlockedExchange(LPLONG, LONG);}
cast(BOOL) FreeResource(HGLOBAL);}
cast(LPVOID) LockResource(HGLOBAL);}
cast(BOOL) FreeLibrary(HINST);}
проц FreeLibraryAndExitThread(HMODULE, cast(DWORD));}
FARPROC GetProcадрес(HINST, cast(LPCSTR));}
cast(DWORD) GetVersion();}
проц FatalExit(цел);}
проц RaiseException(cast(DWORD), cast(DWORD), cast(DWORD));}
LONG UnhandledExceptionFilter(EMPTYRECORD*);}
cast(HANDLE) GetCurrentThread();}
cast(DWORD) GetCurrentThreadId();}
cast(DWORD) SetThreadAffinityMask(cast(HANDLE), cast(DWORD));}
cast(BOOL) SetThreadPriority(cast(HANDLE), цел);}
цел GetThreadPriority(cast(HANDLE));}
cast(BOOL) GetThreadTimes(cast(HANDLE), LPFILETIME, LPFILETIME, LPFILETIME, LPFILETIME);}
проц ExitThread(cast(DWORD));}
cast(BOOL) TerminateThread(cast(HANDLE), cast(DWORD));}
cast(BOOL) GetExitCodeThread(cast(HANDLE), cast(LPDWORD));}
cast(BOOL) GetThreadSelectorEntry(cast(HANDLE), cast(DWORD), LPLDT_ENTRY);}
cast(DWORD) GetLastError();}
проц SetLastError(cast(DWORD));}
UINT SetErrorMode(UINT);}
cast(BOOL) ReadProcessMemory(cast(HANDLE), LPCVOID, cast(LPVOID), cast(DWORD), cast(LPDWORD));}
cast(BOOL) WriteProcessMemory(cast(HANDLE), cast(LPVOID), cast(LPVOID), cast(DWORD), cast(LPDWORD));}
cast(BOOL) GetThreadContext(cast(HANDLE), LPCONTEXT);}
cast(DWORD) SuspendThread(cast(HANDLE));}
cast(DWORD) ResumeThread(cast(HANDLE));}
cast(BOOL) WaitForDebugEvent(LPDEBUG_EVENT, cast(DWORD));}
проц InitializeCriticalSection(LPCRITICAL_SECTION);}
проц EnterCriticalSection(LPCRITICAL_SECTION);}
cast(BOOL) TryEnterCriticalSection(LPCRITICAL_SECTION);}
проц LeaveCriticalSection(LPCRITICAL_SECTION);}
cast(BOOL) SetEvent(cast(HANDLE));}
cast(BOOL) ResetEvent(cast(HANDLE));}
cast(BOOL) PulseEvent(cast(HANDLE));}
cast(BOOL) ReleaseSemaphore(cast(HANDLE), LONG, LPLONG);}
cast(BOOL) ReleaseMutex(cast(HANDLE));}
cast(DWORD) WaitForSingleObject(cast(HANDLE), cast(DWORD));}
cast(DWORD) WaitForMultipleObjects(cast(DWORD), cast(HANDLE)*, cast(BOOL), cast(DWORD));}
проц Sleep(cast(DWORD));}
HGLOBAL LoadResource(HINST, HRSRC);}
cast(DWORD) SizeofResource(HINST, HRSRC);}
ATOM GlobalDeleteAtom(ATOM);}
cast(BOOL) InitAtomTable(cast(DWORD));}
UINT SetHandleCount(UINT);}
cast(DWORD) GetLogicalDrives();}
cast(BOOL) LockFile(cast(HANDLE), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD));}
cast(BOOL) UnlockFile(cast(HANDLE), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD));}
cast(BOOL) LockFileEx(cast(HANDLE), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), LPOVERLAPPED);}
cast(BOOL) UnlockFileEx(cast(HANDLE), cast(DWORD), cast(DWORD), cast(DWORD), LPOVERLAPPED);}
cast(BOOL) GetFileInformationByHandle(cast(HANDLE), LPBY_cast(HANDLE)_FILE_INFORMATION);}
cast(DWORD) GetFileType(cast(HANDLE));}
cast(DWORD) GetFileSize(cast(HANDLE), cast(LPDWORD));}
cast(HANDLE) GetStdHandle(cast(DWORD));}
cast(BOOL) SetStdHandle(cast(DWORD), cast(HANDLE));}
cast(BOOL) FlushFileBuffers(cast(HANDLE));}
cast(BOOL) SetEndOfFile(cast(HANDLE));}
cast(BOOL) GetFileSizeEx(cast(HANDLE), PLARGE_INTEGER);} 
cast(DWORD) SetFilePointer(cast(HANDLE), LONG, PLONG, cast(DWORD));}
cast(BOOL) SetFilePointerEx(cast(HANDLE), LARGE_INTEGER, PLARGE_INTEGER, cast(DWORD));} 
cast(BOOL) GetFileTime(cast(HANDLE), LPFILETIME, LPFILETIME, LPFILETIME);}
cast(BOOL) SetFileTime(cast(HANDLE), FILETIME*, FILETIME*, FILETIME*);}
cast(BOOL) DuplicateHandle(cast(HANDLE), cast(HANDLE), cast(HANDLE), LPcast(HANDLE), cast(DWORD), cast(BOOL), cast(DWORD));}
cast(BOOL) GetHandleInformation(cast(HANDLE), cast(LPDWORD));}
cast(BOOL) SetHandleInformation(cast(HANDLE), cast(DWORD), cast(DWORD));}
cast(DWORD) LoadModule(cast(LPCSTR), cast(LPVOID));}
UINT WinExec(cast(LPCSTR), UINT);}
cast(BOOL) SetupComm(cast(HANDLE), cast(DWORD), cast(DWORD));}
cast(BOOL) EscapeCommFunction(cast(HANDLE), cast(DWORD));}
cast(BOOL) GetCommConfig(cast(HANDLE), LPCOMMCONFIG, cast(LPDWORD));}
cast(BOOL) GetCommProperties(cast(HANDLE), LPCOMMPROP);}
cast(BOOL) GetCommModemStatus(cast(HANDLE), Pcast(DWORD));}
cast(BOOL) GetCommState(cast(HANDLE), PDCB);}
cast(BOOL) GetCommTimeouts(cast(HANDLE), PCOMMTIMEOUTS);}
cast(BOOL) PurgeComm(cast(HANDLE), cast(DWORD));}
cast(BOOL) SetCommBreak(cast(HANDLE));}
cast(BOOL) SetCommConfig(cast(HANDLE), LPCOMMCONFIG, cast(DWORD));}
cast(BOOL) SetCommMask(cast(HANDLE), cast(DWORD));}
cast(BOOL) SetCommState(cast(HANDLE), TDCB*);}
cast(BOOL) SetCommTimeouts(cast(HANDLE), TCOMMTIMEOUTS*);}
cast(BOOL) TransmitCommChar(cast(HANDLE), сим);}
cast(BOOL) WaitCommEvent(cast(HANDLE), cast(LPDWORD), LPOVERLAPPED);}
cast(DWORD) SetTapePosition(cast(HANDLE), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(BOOL));}
cast(DWORD) GetTapePosition(cast(HANDLE), cast(DWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD));}
cast(DWORD) PrepareTape(cast(HANDLE), cast(DWORD), cast(BOOL));}
cast(DWORD) EraseTape(cast(HANDLE), cast(DWORD), cast(BOOL));}
cast(DWORD) WriteTapemark(cast(HANDLE), cast(DWORD), cast(DWORD), cast(BOOL));}
cast(DWORD) GetTapeStatus(cast(HANDLE));}
cast(DWORD) GetTapeParameters(cast(HANDLE), cast(DWORD), cast(LPDWORD), cast(LPVOID));}
cast(DWORD) SetTapeParameters(cast(HANDLE), cast(DWORD), cast(LPVOID));}
цел MulDiv(цел, цел, цел);}
проц GetSystemTime(LPSYSTEMTIME);}
проц GetSystemTimeAsFileTime(FILETIME*);}
cast(BOOL) SetSystemTime(SYSTEMTIME*);}
проц GetLocalTime(LPSYSTEMTIME);}
cast(BOOL) SetLocalTime(SYSTEMTIME*);}
проц GetSystemInfo(LPSYSTEM_INFO);}
cast(BOOL) SystemTimeToTzSpecificLocalTime(LPTIME_ZONE_INFORMATION, LPSYSTEMTIME, LPSYSTEMTIME);}
cast(DWORD) GetTimeZoneInformation(LPTIME_ZONE_INFORMATION);}
cast(BOOL) SetTimeZoneInformation(TIME_ZONE_INFORMATION*);}
cast(BOOL) SystemTimeToFileTime(SYSTEMTIME*, LPFILETIME);}
cast(BOOL) FileTimeToLocalFileTime(FILETIME*, LPFILETIME);}
cast(BOOL) LocalFileTimeToFileTime(FILETIME*, LPFILETIME);}
cast(BOOL) FileTimeToSystemTime(FILETIME*, LPSYSTEMTIME);}
cast(BOOL) FileTimeToDosDateTime(FILETIME*, LPWORD, LPWORD);}
cast(BOOL) DosDateTimeToFileTime(бкрат, бкрат, LPFILETIME);}
cast(DWORD) GetTickCount();}
cast(BOOL) SetSystemTimeAdjustment(cast(DWORD), cast(BOOL));}
cast(BOOL) GetSystemTimeAdjustment(Pcast(DWORD), Pcast(DWORD), Pcast(BOOL));}
cast(BOOL) SetNamedPipeHandleState(cast(HANDLE), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD));}
cast(BOOL) GetNamedPipeInfo(cast(HANDLE), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD));}
cast(BOOL) PeekNamedPipe(cast(HANDLE), cast(LPVOID), cast(DWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD));}
cast(BOOL) TransactNamedPipe(cast(HANDLE), cast(LPVOID), cast(DWORD), cast(LPVOID), cast(DWORD), cast(LPDWORD), LPOVERLAPPED);}
cast(BOOL) GetMailslotInfo(cast(HANDLE), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD), cast(LPDWORD));}
cast(BOOL) SetMailslotInfo(cast(HANDLE), cast(DWORD));}
cast(LPVOID) MapViewOfFile(cast(HANDLE), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD));}
cast(BOOL) FlushViewOfFile(LPCVOID, cast(DWORD));}
cast(BOOL) UnmapViewOfFile(cast(LPVOID));}
HFILE OpenFile(cast(LPCSTR), LPOFSTRUCT, UINT);}
HFILE _lopen(cast(LPCSTR), цел);}
HFILE _lcreat(cast(LPCSTR), цел);}
UINT _lread(HFILE, cast(LPVOID), UINT);}
UINT _lwrite(HFILE, cast(LPCSTR), UINT);}
цел _hread(HFILE, cast(LPVOID), цел);}
цел _hwrite(HFILE, cast(LPCSTR), цел);}
HFILE _lclose(HFILE);}
LONG _llseek(HFILE, LONG, цел);}
cast(BOOL) IsTextUnicode(cast(LPVOID), цел, LPINT);}
cast(DWORD) TlsAlloc();}
cast(LPVOID) TlsGetValue(cast(DWORD));}
cast(BOOL) TlsSetValue(cast(DWORD), cast(LPVOID));}
cast(BOOL) TlsFree(cast(DWORD));}
cast(DWORD) SleepEx(cast(DWORD), cast(BOOL));}
cast(DWORD) WaitForSingleObjectEx(cast(HANDLE), cast(DWORD), cast(BOOL));}
cast(DWORD) WaitForMultipleObjectsEx(cast(DWORD), cast(HANDLE)*, cast(BOOL), cast(DWORD), cast(BOOL));}
cast(BOOL) ReadFileEx(cast(HANDLE), cast(LPVOID), cast(DWORD), LPOVERLAPPED, LPOVERLAPPED_COMPLETION_ROUTINE);}
cast(BOOL) WriteFileEx(cast(HANDLE), LPCVOID, cast(DWORD), LPOVERLAPPED, LPOVERLAPPED_COMPLETION_ROUTINE);}

cast(BOOL) SetProcessShutdownParameters(cast(DWORD), cast(DWORD));}
cast(BOOL) GetProcessShutdownParameters(cast(LPDWORD), cast(LPDWORD));}
проц SetFileApisToOEM();}
проц SetFileApisToANSI();}
cast(BOOL) AreFileApisANSI();}
cast(BOOL) CloseEventLog(cast(HANDLE));}
cast(BOOL) DeregisterEventSource(cast(HANDLE));}
cast(BOOL) NotifyChangeEventLog(cast(HANDLE), cast(HANDLE));}
cast(BOOL) GetNumberOfEventLogRecords(cast(HANDLE), Pcast(DWORD));}
cast(BOOL) GetOldestEventLogRecord(cast(HANDLE), Pcast(DWORD));}
cast(BOOL) DuplicateToken(cast(HANDLE), SECURITY_IMPERSONATION_LEVEL, Pcast(HANDLE));}
cast(BOOL) GetKernelObjectSecurity(cast(HANDLE), SECURITY_INFORMATION, PSECURITY_DESCRIPTOR, cast(DWORD), cast(LPDWORD));}
cast(BOOL) ImpersonateNamedPipeClient(cast(HANDLE));}
cast(BOOL) ImpersonateLoggedOnUser(cast(HANDLE));}
cast(BOOL) ImpersonateSelf(SECURITY_IMPERSONATION_LEVEL);}
cast(BOOL) RevertToSelf();}
cast(BOOL) SetThreadToken(Pcast(HANDLE), cast(HANDLE));}
cast(BOOL) OpenProcessToken(cast(HANDLE), cast(DWORD), Pcast(HANDLE));}
cast(BOOL) OpenThreadToken(cast(HANDLE), cast(DWORD), cast(BOOL), Pcast(HANDLE));}
cast(BOOL) GetTokenInformation(cast(HANDLE), TOKEN_INFORMATION_CLASS, cast(LPVOID), cast(DWORD), Pcast(DWORD));}
cast(BOOL) SetTokenInformation(cast(HANDLE), TOKEN_INFORMATION_CLASS, cast(LPVOID), cast(DWORD));}
cast(BOOL) AdjustTokenPrivileges(cast(HANDLE), cast(BOOL), PTOKEN_PRIVILEGES, cast(DWORD), PTOKEN_PRIVILEGES, Pcast(DWORD));}
cast(BOOL) AdjustTokenGroups(cast(HANDLE), cast(BOOL), PTOKEN_GROUPS, cast(DWORD), PTOKEN_GROUPS, Pcast(DWORD));}
cast(BOOL) PrivilegeCheck(cast(HANDLE), PPRIVILEGE_SET, LPcast(BOOL));}
cast(BOOL) IsValidSid(PSID);}
cast(BOOL) EqualSid(PSID, PSID);}
cast(BOOL) EqualPrefixSid(PSID, PSID);}
cast(DWORD) GetSidLengthRequired(UCHAR);}
cast(BOOL) AllocateAndInitializeSid(PSID_IDENTIFIER_AUTHORITY, ббайт, cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), PSID*);}
PVOID FreeSid(PSID);}
cast(BOOL) InitializeSid(PSID, PSID_IDENTIFIER_AUTHORITY, ббайт);}
PSID_IDENTIFIER_AUTHORITY GetSidIdentifierAuthority(PSID);}
Pcast(DWORD) GetSidSubAuthority(PSID, cast(DWORD));}
PUCHAR GetSidSubAuthorityCount(PSID);}
cast(DWORD) GetLengthSid(PSID);}
cast(BOOL) CopySid(cast(DWORD), PSID, PSID);}
cast(BOOL) AreAllAccessesGranted(cast(DWORD), cast(DWORD));}
cast(BOOL) AreAnyAccessesGranted(cast(DWORD), cast(DWORD));}
проц MapGenericMask(Pcast(DWORD));}
cast(BOOL) IsValidAcl(PACL);}
cast(BOOL) InitializeAcl(PACL, cast(DWORD), cast(DWORD));}
cast(BOOL) GetAclInformation(PACL, cast(LPVOID), cast(DWORD), ACL_INFORMATION_CLASS);}
cast(BOOL) SetAclInformation(PACL, cast(LPVOID), cast(DWORD), ACL_INFORMATION_CLASS);}
cast(BOOL) добавьAce(PACL, cast(DWORD), cast(DWORD), cast(LPVOID), cast(DWORD));}
cast(BOOL) DeleteAce(PACL, cast(DWORD));}
cast(BOOL) GetAce(PACL, cast(DWORD), cast(LPVOID)*);}
cast(BOOL) добавьAccessAllowedAce(PACL, cast(DWORD), cast(DWORD), PSID);}
cast(BOOL) добавьAccessDeniedAce(PACL, cast(DWORD), cast(DWORD), PSID);}
cast(BOOL) добавьAuditAccessAce(PACL, cast(DWORD), cast(DWORD), PSID, cast(BOOL), cast(BOOL));}
cast(BOOL) FindFirstFreeAce(PACL, cast(LPVOID)*);}
cast(BOOL) InitializeSecurityDescriptor(PSECURITY_DESCRIPTOR, cast(DWORD));}
cast(BOOL) IsValidSecurityDescriptor(PSECURITY_DESCRIPTOR);}
cast(DWORD) GetSecurityDescriptorLength(PSECURITY_DESCRIPTOR);}
cast(BOOL) GetSecurityDescriptorControl(PSECURITY_DESCRIPTOR, PSECURITY_DESCRIPTOR_CONTROL, cast(LPDWORD));}
cast(BOOL) SetSecurityDescriptorDacl(PSECURITY_DESCRIPTOR, cast(BOOL), PACL, cast(BOOL));}
cast(BOOL) GetSecurityDescriptorDacl(PSECURITY_DESCRIPTOR, LPcast(BOOL), PACL*, LPcast(BOOL));}
cast(BOOL) SetSecurityDescriptorSacl(PSECURITY_DESCRIPTOR, cast(BOOL), PACL, cast(BOOL));}
cast(BOOL) GetSecurityDescriptorSacl(PSECURITY_DESCRIPTOR, LPcast(BOOL), PACL*, LPcast(BOOL));}
cast(BOOL) SetSecurityDescriptorOwner(PSECURITY_DESCRIPTOR, PSID, cast(BOOL));}
cast(BOOL) GetSecurityDescriptorOwner(PSECURITY_DESCRIPTOR, PSID*, LPcast(BOOL));}
cast(BOOL) SetSecurityDescriptorGroup(PSECURITY_DESCRIPTOR, PSID, cast(BOOL));}
cast(BOOL) GetSecurityDescriptorGroup(PSECURITY_DESCRIPTOR, PSID*, LPcast(BOOL));}
cast(BOOL) CreatePrivateObjectSecurity(PSECURITY_DESCRIPTOR, PSECURITY_DESCRIPTOR, PSECURITY_DESCRIPTOR*, cast(BOOL), cast(HANDLE), PGENERIC_MAPPING);}
cast(BOOL) SetPrivateObjectSecurity(SECURITY_INFORMATION, PSECURITY_DESCRIPTOR, PSECURITY_DESCRIPTOR*, PGENERIC_MAPPING, cast(HANDLE));}
cast(BOOL) GetPrivateObjectSecurity(PSECURITY_DESCRIPTOR, SECURITY_INFORMATION, PSECURITY_DESCRIPTOR, cast(DWORD), Pcast(DWORD));}
cast(BOOL) DestroyPrivateObjectSecurity(PSECURITY_DESCRIPTOR);}
cast(BOOL) MakeSelfRelativeSD(PSECURITY_DESCRIPTOR, PSECURITY_DESCRIPTOR, cast(LPDWORD));}
cast(BOOL) MakeAbsoluteSD(PSECURITY_DESCRIPTOR, PSECURITY_DESCRIPTOR, cast(LPDWORD), PACL, cast(LPDWORD), PACL, cast(LPDWORD), PSID, cast(LPDWORD), PSID, cast(LPDWORD));}
cast(BOOL) SetKernelObjectSecurity(cast(HANDLE), SECURITY_INFORMATION, PSECURITY_DESCRIPTOR);}
cast(BOOL) FindNextChangeNotification(cast(HANDLE));}
cast(BOOL) FindCloseChangeNotification(cast(HANDLE));}
cast(BOOL) VirtualLock(cast(LPVOID), cast(DWORD));}
cast(BOOL) VirtualUnlock(cast(LPVOID), cast(DWORD));}
cast(LPVOID) MapViewOfFileEx(cast(HANDLE), cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD), cast(LPVOID));}
cast(BOOL) SetPriorityClass(cast(HANDLE), cast(DWORD));}
cast(DWORD) GetPriorityClass(cast(HANDLE));}
cast(BOOL) AllocateLocallyUniqueId(PLUID);}
cast(BOOL) QueryPerformanceCounter(PLARGE_INTEGER);}
cast(BOOL) QueryPerformanceFrequency(PLARGE_INTEGER);}
cast(BOOL) ActivateKeyboardLayout(HKL, UINT);}
cast(BOOL) UnloadKeyboardLayout(HKL);}
цел GetKeyboardLayoutList(цел, HKL*);}
HKL GetKeyboardLayout(cast(DWORD));}
HDESK OpenInputDesktop(cast(DWORD), cast(BOOL), cast(DWORD));}
cast(BOOL) EnumDesktopWindows(HDESK, ENUMWINDOWSPROC, LPARAM);}
cast(BOOL) SwitchDesktop(HDESK);}
cast(BOOL) SetThreдобавьesktop(HDESK);}
cast(BOOL) CloseDesktop(HDESK);}
HDESK GetThreдобавьesktop(cast(DWORD));}
cast(BOOL) CloseWindowStation(HWINSTA);}
cast(BOOL) SetProcessWindowStation(HWINSTA);}
HWINSTA GetProcessWindowStation();}
cast(BOOL) SetUserObjectSecurity(cast(HANDLE), PSECURITY_INFORMATION, PSECURITY_DESCRIPTOR);}
cast(BOOL) GetUserObjectSecurity(cast(HANDLE), PSECURITY_INFORMATION, PSECURITY_DESCRIPTOR, cast(DWORD), cast(LPDWORD));}
cast(BOOL) TranslateMessage(LPMSG);}
cast(BOOL) SetMessageQueue(цел);}
cast(BOOL) RegisterHotKey(HWND, цел, UINT, UINT);}
cast(BOOL) UnregisterHotKey(HWND, цел);}
cast(BOOL) ExitWindowsEx(UINT, cast(DWORD));}
cast(BOOL) SwapMouseButton(cast(BOOL));}
cast(DWORD) GetMessagePos();}
LONG GetMessageTime();}
LONG GetMessageExtraInfo();}
LPARAM SetMessageExtraInfo(LPARAM);}
цел BroadcastSystemMessage(cast(DWORD), cast(LPDWORD), UINT, WPARAM, LPARAM);}
cast(BOOL) AttachThreadInput(cast(DWORD), cast(DWORD), cast(BOOL));}
cast(BOOL) ReplyMessage(LRESULT);}
cast(BOOL) WaitMessage();}
cast(DWORD) WaitForInputIdle(cast(HANDLE), cast(DWORD));}
проц PostQuitMessage(цел);}
cast(BOOL) InSendMessage();}
UINT GetDoubleClickTime();}
cast(BOOL) SetDoubleClickTime(UINT);}
cast(BOOL) IsWindow(HWND);}
cast(BOOL) IsMenu(HMENU);}
cast(BOOL) IsChild(HWND, HWND);}
cast(BOOL) DestroyWindow(HWND);}
cast(BOOL) ShowWindow(HWND, цел);}
cast(BOOL) ShowWindowAsync(HWND, цел);}
cast(BOOL) FlashWindow(HWND, cast(BOOL));}
cast(BOOL) ShowOwnedPopups(HWND, cast(BOOL));}
cast(BOOL) OpenIcon(HWND);}
cast(BOOL) CloseWindow(HWND);}
cast(BOOL) MoveWindow(HWND, цел, цел, цел, цел, cast(BOOL));}
cast(BOOL) SetWindowPos(HWND, HWND, цел, цел, цел, цел, UINT);}
cast(BOOL) GetWindowPlacement(HWND, WINDOWPLACEMENT*);}
cast(BOOL) SetWindowPlacement(HWND, WINDOWPLACEMENT*);}
HDWP BeginDeferWindowPos(цел);}
HDWP DeferWindowPos(HDWP, HWND, HWND, цел, цел, цел, цел, UINT);}
cast(BOOL) EndDeferWindowPos(HDWP);}
cast(BOOL) IsWindowVisible(HWND);}
cast(BOOL) IsIconic(HWND);}
cast(BOOL) AnyPopup();}
cast(BOOL) BringWindowToTop(HWND);}
cast(BOOL) IsZoomed(HWND);}
cast(BOOL) EndDialog(HWND, цел);}
HWND GetDlgItem(HWND, цел);}
cast(BOOL) SetDlgItemInt(HWND, цел, UINT, cast(BOOL));}
UINT GetDlgItemInt(HWND, цел, cast(BOOL)*, cast(BOOL));}
cast(BOOL) CheckDlgButton(HWND, цел, UINT);}
cast(BOOL) CheckRadioButton(HWND, цел, цел, цел);}
UINT IsDlgButtonChecked(HWND, цел);}
HWND GetNextDlgGroupItem(HWND, HWND, cast(BOOL));}
HWND GetNextDlgTabItem(HWND, HWND, cast(BOOL));}
цел GetDlgCtrlID(HWND);}
цел GetDialogBaseUnits();}
cast(BOOL) OpenClipboard(HWND);}
cast(BOOL) CloseClipboard();}
HWND GetClipboardOwner();}
HWND SetClipboardViewer(HWND);}
HWND GetClipboardViewer();}
cast(BOOL) ChangeClipboardChain(HWND, HWND);}
cast(HANDLE) SetClipboardData(UINT, cast(HANDLE));}
cast(HANDLE) GetClipboardData(UINT);}
цел CountClipboardFormats();}
UINT EnumClipboardFormats(UINT);}
cast(BOOL) EmptyClipboard();}
cast(BOOL) IsClipboardFormatAvailable(UINT);}
цел GetPriorityClipboardFormat(UINT*, цел);}
HWND GetOpenClipboardWindow();}
cast(LPSTR) CharNextExA(бкрат, cast(LPCSTR), cast(DWORD));}
cast(LPSTR) CharPrevExA(бкрат, cast(LPCSTR), cast(LPCSTR), cast(DWORD));}
HWND SetFocus(HWND);}
HWND GetActiveWindow();}
HWND GetFocus();}
UINT GetKBCodePage();}
SHORT GetKeyState(цел);}
SHORT GetAsyncKeyState(цел);}
cast(BOOL) GetKeyboardState(PBYTE);}
cast(BOOL) SetKeyboardState(LPBYTE);}
цел GetKeyboardType(цел);}
цел ToAscii(UINT, UINT, PBYTE, LPWORD, UINT);}
цел ToAsciiEx(UINT, UINT, PBYTE, LPWORD, UINT, HKL);}
цел ToUnicode(UINT, UINT, PBYTE, cast(LPWSTR), цел, UINT);}
cast(DWORD) OemKeyScan(бкрат);}
проц keybd_event(ббайт, ббайт, cast(DWORD), LPVOID);}
проц mouse_event(cast(DWORD), cast(DWORD), cast(DWORD), cast(DWORD));}
cast(BOOL) GetInputState();}
cast(DWORD) GetQueueStatus(UINT);}
HWND GetCapture();}
HWND SetCapture(HWND);}
cast(BOOL) ReleaseCapture();}
cast(DWORD) MsgWaitForMultipleObjects(cast(DWORD), LPcast(HANDLE), cast(BOOL), cast(DWORD), cast(DWORD));}
UINT SetTimer(HWND, UINT, UINT, TIMERPROC);}
cast(BOOL) KillTimer(HWND, UINT);}
cast(BOOL) IsWindowUnicode(HWND);}
cast(BOOL) EnableWindow(HWND, cast(BOOL));}
cast(BOOL) IsWindowEnabled(HWND);}
cast(BOOL) DestroyAcceleratorTable(HACCEL);}
цел GetSystemMetrics(цел);}
HMENU GetMenu(HWND);}
cast(BOOL) SetMenu(HWND, HMENU);}
cast(BOOL) HiliteMenuItem(HWND, HMENU, UINT, UINT);}
UINT GetMenuState(HMENU, UINT, UINT);}
cast(BOOL) DrawMenuBar(HWND);}
HMENU GetSystemMenu(HWND, cast(BOOL));}
HMENU CreateMenu();}
HMENU CreatePopupMenu();}
cast(BOOL) DestroyMenu(HMENU);}
cast(DWORD) CheckMenuItem(HMENU, UINT, UINT);}
cast(BOOL) EnableMenuItem(HMENU, UINT, UINT);}
HMENU GetSubMenu(HMENU, цел);}
UINT GetMenuItemID(HMENU, цел);}
цел GetMenuItemCount(HMENU);}
cast(BOOL) RemoveMenu(HMENU, UINT, UINT);}
cast(BOOL) DeleteMenu(HMENU, UINT, UINT);}
cast(BOOL) SetMenuItemBitmaps(HMENU, UINT, UINT, HBITMAP, HBITMAP);}
LONG GetMenuCheckMarkDimensions();}
cast(BOOL) TrackPopupMenu(HMENU, UINT, цел, цел, цел, HWND, RECT*);}
UINT GetMenuDefaultItem(HMENU, UINT, UINT);}
cast(BOOL) SetMenuDefaultItem(HMENU, UINT, UINT);}
cast(BOOL) GetMenuItemRect(HWND, HMENU, UINT, LPRECT);}
цел MenuItemFromPoint(HWND, HMENU, POINT);}
cast(DWORD) DragObject(HWND, HWND, UINT, cast(DWORD), HCURSOR);}
cast(BOOL) DragDetect(HWND, POINT);}
cast(BOOL) DrawIcon(HDC, цел, цел, HICON);}
cast(BOOL) UpdateWindow(HWND);}
HWND SetActiveWindow(HWND);}
HWND GetForegroundWindow();}
cast(BOOL) PaintDesktop(HDC);}
cast(BOOL) SetForegroundWindow(HWND);}
HWND WindowFromDC(HDC);}
HDC GetDC(HWND);}
HDC GetDCEx(HWND, HRGN, cast(DWORD));}
HDC GetWindowDC(HWND);}
цел ReleaseDC(HWND, HDC);}
HDC BeginPaint(HWND, LPPAINTSTRUCT);}
cast(BOOL) EndPaint(HWND, LPPAINTSTRUCT);}
cast(BOOL) GetUpdateRect(HWND, LPRECT, cast(BOOL));}
цел GetUpdateRgn(HWND, HRGN, cast(BOOL));}
цел SetWindowRgn(HWND, HRGN, cast(BOOL));}
цел GetWindowRgn(HWND, HRGN);}
цел ExcludeUpdateRgn(HDC, HWND);}
cast(BOOL) InvalidateRect(HWND, RECT*, cast(BOOL));}
cast(BOOL) ValidateRect(HWND, RECT*);}
cast(BOOL) InvalidateRgn(HWND, HRGN, cast(BOOL));}
cast(BOOL) ValidateRgn(HWND, HRGN);}
cast(BOOL) RedrawWindow(HWND, RECT*, HRGN, UINT);}
cast(BOOL) LockWindowUpdate(HWND);}
cast(BOOL) ScrollWindow(HWND, цел, цел, RECT*, RECT*);}
cast(BOOL) ScrollDC(HDC, цел, цел, RECT*, RECT*, HRGN, LPRECT);}
цел ScrollWindowEx(HWND, цел, цел, RECT*, RECT*, HRGN, LPRECT, UINT);}
цел SetScrollPos(HWND, цел, цел, cast(BOOL));}
цел GetScrollPos(HWND, цел);}
cast(BOOL) SetScrollRange(HWND, цел, цел, цел, cast(BOOL));}
cast(BOOL) GetScrollRange(HWND, цел, LPINT, LPINT);}
cast(BOOL) ShowScrollBar(HWND, цел, cast(BOOL));}
cast(BOOL) EnableScrollBar(HWND, UINT, UINT);}
cast(BOOL) GetClientRect(HWND, LPRECT);}
cast(BOOL) GetWindowRect(HWND, LPRECT);}
cast(BOOL) AdjustWindowRect(LPRECT, cast(DWORD), cast(BOOL));}
cast(BOOL) AdjustWindowRectEx(LPRECT, cast(DWORD), cast(BOOL), cast(DWORD));}
cast(BOOL) SetWindowContextHelpId(HWND, cast(DWORD));}
cast(DWORD) GetWindowContextHelpId(HWND);}
cast(BOOL) SetMenuContextHelpId(HMENU, cast(DWORD));}
cast(DWORD) GetMenuContextHelpId(HMENU);}
cast(BOOL) MessageBeep(UINT);}
цел ShowCursor(cast(BOOL));}
cast(BOOL) SetCursorPos(цел, цел);}
HCURSOR SetCursor(HCURSOR);}
cast(BOOL) GetCursorPos(LPPOINT);}
cast(BOOL) ClipCursor(RECT*);}
cast(BOOL) GetClipCursor(LPRECT);}
HCURSOR GetCursor();}
cast(BOOL) CreateCaret(HWND, HBITMAP, цел, цел);}
UINT GetCaretBlinkTime();}
cast(BOOL) SetCaretBlinkTime(UINT);}
cast(BOOL) DestroyCaret();}
cast(BOOL) HideCaret(HWND);}
cast(BOOL) ShowCaret(HWND);}
cast(BOOL) SetCaretPos(цел, цел);}
cast(BOOL) GetCaretPos(LPPOINT);}
cast(BOOL) ClientToScreen(HWND, LPPOINT);}
cast(BOOL) ScreenToClient(HWND, LPPOINT);}
цел MapWindowPoints(HWND, HWND, LPPOINT, UINT);}
HWND WindowFromPoint(POINT);}
HWND ChildWindowFromPoint(HWND, POINT);}
cast(DWORD) GetSysColor(цел);}
HBRUSH GetSysColorBrush(цел);}
cast(BOOL) SetSysColors(цел, WINT*, COLORREF*);}
cast(BOOL) DrawFocusRect(HDC, RECT*);}
цел FillRect(HDC, RECT*, HBRUSH);}
цел FrameRect(HDC, RECT*, HBRUSH);}
cast(BOOL) InvertRect(HDC, RECT*);}
cast(BOOL) SetRect(LPRECT, цел, цел, цел, цел);}
cast(BOOL) SetRectEmpty(LPRECT);}
cast(BOOL) CopyRect(LPRECT, RECT*);}
cast(BOOL) InflateRect(LPRECT, цел, цел);}
cast(BOOL) IntersectRect(LPRECT, RECT*, RECT*);}
cast(BOOL) UnionRect(LPRECT, RECT*, RECT*);}
cast(BOOL) SubtractRect(LPRECT, RECT*, RECT*);}
cast(BOOL) OffsetRect(LPRECT, цел, цел);}
cast(BOOL) IsRectEmpty(RECT*);}
cast(BOOL) EqualRect(RECT*, RECT*);}
cast(BOOL) PtInRect(RECT*, POINT);}
бкрат GetWindowWord(HWND, цел);}
бкрат SetWindowWord(HWND, цел, бкрат);}
бкрат GetClassWord(HWND, цел);}
бкрат SetClassWord(HWND, цел, бкрат);}
HWND GetDesktopWindow();}
HWND GetParent(HWND);}
HWND SetParent(HWND, HWND);}
cast(BOOL) EnumChildWindows(HWND, ENUMWINDOWSPROC, LPARAM);}
cast(BOOL) EnumWindows(ENUMWINDOWSPROC, LPARAM);}
cast(BOOL) EnumThreadWindows(cast(DWORD), ENUMWINDOWSPROC, LPARAM);}
HWND GetTopWindow(HWND);}
cast(DWORD) GetWindowThreadProcessId(HWND, cast(LPDWORD));}
HWND GetLastActivePopup(HWND);}
HWND GetWindow(HWND, UINT);}
cast(BOOL) UnhookWindowsHook(цел, HOOKPROC);}
cast(BOOL) UnhookWindowsHookEx(HHOOK);}
LRESULT CallNextHookEx(HHOOK, цел, WPARAM, LPARAM);}
cast(BOOL) CheckMenuRadioItem(HMENU, UINT, UINT, UINT, UINT);}
HCURSOR CreateCursor(HINST, цел, цел, цел, цел, LPVOID, LPVOID);}
cast(BOOL) DestroyCursor(HCURSOR);}
cast(BOOL) SetSystemCursor(HCURSOR, cast(DWORD));}
HICON CreateIcon(HINST, цел, цел, ббайт, ббайт, ббайт*, ббайт*);}
cast(BOOL) DestroyIcon(HICON);}
цел LookupIconIdFromDirectory(PBYTE, cast(BOOL));}
цел LookupIconIdFromDirectoryEx(PBYTE, cast(BOOL), цел, цел, UINT);}
HICON CreateIconFromResource(PBYTE, cast(DWORD), cast(BOOL), cast(DWORD));}
HICON CreateIconFromResourceEx(PBYTE, cast(DWORD), cast(BOOL), cast(DWORD), цел, цел, UINT);}
HICON CopyImage(cast(HANDLE), UINT, цел, цел, UINT);}
HICON CreateIconIndirect(PICONINFO);}
HICON CopyIcon(HICON);}
cast(BOOL) GetIconInfo(HICON, PICONINFO);}
cast(BOOL) MapDialogRect(HWND, LPRECT);}
цел SetScrollInfo(HWND, цел, LPCSCROLLINFO, cast(BOOL));}
cast(BOOL) GetScrollInfo(HWND, цел, LPSCROLLINFO);}
cast(BOOL) TranslateMDISysAccel(HWND, LPMSG);}
UINT ArrangeIconicWindows(HWND);}
бкрат TileWindows(HWND, UINT, RECT*, UINT, HWND*);}
бкрат CascadeWindows(HWND, UINT, RECT*, UINT, HWND*);}
проц SetLastErrorEx(cast(DWORD));}
проц SetDebugErrorУровень(cast(DWORD));}
cast(BOOL) DrawEdge(HDC, LPRECT, UINT, UINT);}
cast(BOOL) DrawFrameControl(HDC, LPRECT, UINT, UINT);}
cast(BOOL) DrawCaption(HWND, HDC, RECT*, UINT);}
cast(BOOL) DrawAnimatedRects(HWND, цел, RECT*, RECT*);}
cast(BOOL) TrackPopupMenuEx(HMENU, UINT, цел, цел, HWND, LPTPMPARAMS);}
HWND ChildWindowFromPointEx(HWND, POINT, UINT);}
cast(BOOL) DrawIconEx(HDC, цел, цел, HICON, цел, цел, UINT, HBRUSH, UINT);}
cast(BOOL) AnimatePalette(HPALETTE, UINT, UINT, PALETTEENTRY*);}
cast(BOOL) Arc(HDC, цел, цел, цел, цел, цел, цел, цел, цел);}
cast(BOOL) BitBlt(HDC, цел, цел, цел, цел, HDC, цел, цел, cast(DWORD));}
cast(BOOL) CancelDC(HDC);}
cast(BOOL) Chord(HDC, цел, цел, цел, цел, цел, цел, цел, цел);}
HMETAFILE CloseMetaFile(HDC);}
цел CombineRgn(HRGN, HRGN, HRGN, цел);}
HBITMAP CreateBitmap(цел, цел, UINT, UINT, LPVOID);}
HBITMAP CreateBitmapIndirect(BITMAP*);}
HBRUSH CreateBrushIndirect(LOGBRUSH*);}
HBITMAP CreateCompatibleBitmap(HDC, цел, цел);}
HBITMAP CreateDiscardableBitmap(HDC, цел, цел);}
HDC CreateCompatibleDC(HDC);}
HBITMAP CreateDIBitmap(HDC, BITMAPINFOHEADER*, cast(DWORD), LPVOID, BITMAPINFO*, UINT);}
HBRUSH CreateDIBPatternBrush(HGLOBAL, UINT);}
HBRUSH CreateDIBPatternBrushPt(LPVOID, UINT);}
HRGN CreateEllipticRgn(цел, цел, цел, цел);}
HRGN CreateEllipticRgnIndirect(RECT*);}
HBRUSH CreateHatchBrush(цел, COLORREF);}
HPALETTE CreatePalette(LOGPALETTE*);}
HPEN CreatePen(цел, цел, COLORREF);}
HPEN CreatePenIndirect(LOGPEN*);}
HRGN CreatePolyPolygonRgn(POINT*, WINT*, цел, цел);}
HBRUSH CreatePatternBrush(HBITMAP);}
HRGN CreateRectRgn(цел, цел, цел, цел);}
HRGN CreateRectRgnIndirect(RECT*);}
HRGN CreateRoundRectRgn(цел, цел, цел, цел, цел, цел);}
HBRUSH CreateSolidBrush(COLORREF);}
cast(BOOL) DeleteDC(HDC);}
cast(BOOL) DeleteMetaFile(HMETAFILE);}
cast(BOOL) DeleteObject(HGDIOBJ);}
цел DrawEscape(HDC, цел, цел, cast(LPCSTR));}
cast(BOOL) Ellipse(HDC, цел, цел, цел, цел);}
цел EnumObjects(HDC, цел, ENUMOBJECTSPROC, LPARAM);}
cast(BOOL) EqualRgn(HRGN, HRGN);}
цел Escape(HDC, цел, цел, cast(LPCSTR), cast(LPVOID));}
цел ExtEscape(HDC, цел, цел, cast(LPCSTR), цел, cast(LPSTR));}
цел ExcludeClipRect(HDC, цел, цел, цел, цел);}
HRGN ExtCreateRegion(XFORM*, cast(DWORD), RGNDATA*);}
cast(BOOL) ExtFloodFill(HDC, цел, цел, COLORREF, UINT);}
cast(BOOL) FillRgn(HDC, HRGN, HBRUSH);}
cast(BOOL) FloodFill(HDC, цел, цел, COLORREF);}
cast(BOOL) FrameRgn(HDC, HRGN, HBRUSH, цел, цел);}
цел GetROP2(HDC);}
cast(BOOL) GetAspectRatioFilterEx(HDC, LPSIZE);}
COLORREF GetBkColor(HDC);}
цел GetBkMode(HDC);}
LONG GetBitmapBits(HBITMAP, LONG, cast(LPVOID));}
cast(BOOL) GetBitmapDimensionEx(HBITMAP, LPSIZE);}
UINT GetBoundsRect(HDC, LPRECT, UINT);}
cast(BOOL) GetBrushOrgEx(HDC, LPPOINT);}
цел GetClipBox(HDC, LPRECT);}
цел GetClipRgn(HDC, HRGN);}
цел GetMetaRgn(HDC, HRGN);}
HGDIOBJ GetCurrentObject(HDC, UINT);}
cast(BOOL) GetCurrentPositionEx(HDC, LPPOINT);}
цел GetDeviceCaps(HDC, цел);}
цел GetDIBits(HDC, HBITMAP, UINT, UINT, cast(LPVOID), LPBITMAPINFO, UINT);}
cast(DWORD) GetFontData(HDC, cast(DWORD), cast(DWORD), cast(LPVOID), cast(DWORD));}
цел GetGraphicsMode(HDC);}
цел GetMapMode(HDC);}
UINT GetMetaFileBitsEx(HMETAFILE, UINT, cast(LPVOID));}
COLORREF GetNearestColor(HDC, COLORREF);}
UINT GetNearestPaletteIndex(HPALETTE, COLORREF);}
cast(DWORD) GetObjectType(HGDIOBJ);}
UINT GetPaletteEntries(HPALETTE, UINT, UINT, LPPALETTEENTRY);}
COLORREF GetPixel(HDC, цел, цел);}
цел GetPixelFormat(HDC);}
цел GetPolyFillMode(HDC);}
cast(BOOL) GetRasterizerCaps(LPRASTERIZER_STATUS, UINT);}
cast(DWORD) GetRegionData(HRGN, cast(DWORD), LPRGNDATA);}
цел GetRgnBox(HRGN, LPRECT);}
HGDIOBJ GetStockObject(цел);}
цел GetStretchBltMode(HDC);}
UINT GetSystemPaletteEntries(HDC, UINT, UINT, LPPALETTEENTRY);}
UINT GetSystemPaletteUse(HDC);}
цел GetTextCharacterExtra(HDC);}
UINT GetTextAlign(HDC);}
COLORREF GetTextColor(HDC);}
цел GetTextCharset(HDC);}
цел GetTextCharsetInfo(HDC, LPFONTSIGNATURE, cast(DWORD));}
cast(BOOL) TranslateCharsetInfo(cast(DWORD)*, LPCHARSETINFO, cast(DWORD));}
cast(DWORD) GetFontLanguageInfo(HDC);}
cast(BOOL) GetViewportExtEx(HDC, LPSIZE);}
cast(BOOL) GetViewportOrgEx(HDC, LPPOINT);}
cast(BOOL) GetWindowExtEx(HDC, LPSIZE);}
cast(BOOL) GetWindowOrgEx(HDC, LPPOINT);}
цел IntersectClipRect(HDC, цел, цел, цел, цел);}
cast(BOOL) InvertRgn(HDC, HRGN);}
cast(BOOL) LineDDA(цел, цел, цел, цел, LINEDDAPROC, LPARAM);}
cast(BOOL) LineTo(HDC, цел, цел);}
cast(BOOL) MaskBlt(HDC, цел, цел, цел, цел, HDC, цел, цел, HBITMAP, цел, цел, cast(DWORD));}
cast(BOOL) PlgBlt(HDC, POINT*, HDC, цел, цел, цел, цел, HBITMAP, цел, цел);}
цел OffsetClipRgn(HDC, цел, цел);}
цел OffsetRgn(HRGN, цел, цел);}
cast(BOOL) PatBlt(HDC, цел, цел, цел, цел, cast(DWORD));}
cast(BOOL) Pie(HDC, цел, цел, цел, цел, цел, цел, цел, цел);}
cast(BOOL) PlayMetaFile(HDC, HMETAFILE);}
cast(BOOL) PaintRgn(HDC, HRGN);}
cast(BOOL) PolyPolygon(HDC, POINT*, WINT*, цел);}
cast(BOOL) PtInRegion(HRGN, цел, цел);}
cast(BOOL) PtVisible(HDC, цел, цел);}
cast(BOOL) RectInRegion(HRGN, RECT*);}
cast(BOOL) RectVisible(HDC, RECT*);}
cast(BOOL) Rectangle(HDC, цел, цел, цел, цел);}
cast(BOOL) RestoreDC(HDC, цел);}
UINT RealizePalette(HDC);}
cast(BOOL) RoundRect(HDC, цел, цел, цел, цел, цел, цел);}
cast(BOOL) ResizePalette(HPALETTE, UINT);}
цел SaveDC(HDC);}
цел SelectClipRgn(HDC, HRGN);}
цел ExtSelectClipRgn(HDC, HRGN, цел);}
цел SetMetaRgn(HDC);}
HGDIOBJ SelectObject(HDC, HGDIOBJ);}
HPALETTE SelectPalette(HDC, HPALETTE, cast(BOOL));}
COLORREF SetBkColor(HDC, COLORREF);}
цел SetBkMode(HDC, цел);}
LONG SetBitmapBits(HBITMAP, cast(DWORD), LPVOID);}
UINT SetBoundsRect(HDC, RECT*, UINT);}
цел SetDIBits(HDC, HBITMAP, UINT, UINT, LPVOID, PBITMAPINFO, UINT);}
цел SetDIBitsToDevice(HDC, цел, цел, cast(DWORD), cast(DWORD), цел, цел, UINT, UINT, LPVOID, BITMAPINFO*, UINT);}
cast(DWORD) SetMapperFlags(HDC, cast(DWORD));}
цел SetGraphicsMode(HDC, цел);}
цел SetMapMode(HDC, цел);}
HMETAFILE SetMetaFileBitsEx(UINT, ббайт*);}
UINT SetPaletteEntries(HPALETTE, UINT, UINT, PALETTEENTRY*);}
COLORREF SetPixel(HDC, цел, цел, COLORREF);}
cast(BOOL) SetPixelV(HDC, цел, цел, COLORREF);}
цел SetPolyFillMode(HDC, цел);}
cast(BOOL) StretchBlt(HDC, цел, цел, цел, цел, HDC, цел, цел, цел, цел, cast(DWORD));}
cast(BOOL) SetRectRgn(HRGN, цел, цел, цел, цел);}
цел StretchDIBits(HDC, цел, цел, цел, цел, цел, цел, цел, цел, LPVOID, BITMAPINFO*, UINT, cast(DWORD));}
цел SetROP2(HDC, цел);}
цел SetStretchBltMode(HDC, цел);}
UINT SetSystemPaletteUse(HDC, UINT);}
цел SetTextCharacterExtra(HDC, цел);}
COLORREF SetTextColor(HDC, COLORREF);}
UINT SetTextAlign(HDC, UINT);}
cast(BOOL) SetTextJustification(HDC, цел, цел);}
cast(BOOL) UpdateColors(HDC);}
cast(BOOL) PlayMetaFileRecord(HDC, LPcast(HANDLE)TABLE, LPMETARECORD, UINT);}
cast(BOOL) EnumMetaFile(HDC, HMETAFILE, ENUMMETAFILEPROC, LPARAM);}
HENHMETAFILE CloseEnhMetaFile(HDC);}
cast(BOOL) DeleteEnhMetaFile(HENHMETAFILE);}
cast(BOOL) EnumEnhMetaFile(HDC, HENHMETAFILE, ENHMETAFILEPROC, cast(LPVOID), RECT*);}
UINT GetEnhMetaFileHeader(HENHMETAFILE, UINT, LPENHMETAHEADER);}
UINT GetEnhMetaFilePaletteEntries(HENHMETAFILE, UINT, LPPALETTEENTRY);}
UINT GetWinMetaFileBits(HENHMETAFILE, UINT, LPBYTE, WINT, HDC);}
cast(BOOL) PlayEnhMetaFile(HDC, HENHMETAFILE, RECT*);}
cast(BOOL) PlayEnhMetaFileRecord(HDC, LPcast(HANDLE)TABLE, ENHMETARECORD*, UINT);}
HENHMETAFILE SetEnhMetaFileBits(UINT, ббайт*);}
HENHMETAFILE SetWinMetaFileBits(UINT, ббайт*, HDC, METAFILEPICT*);}
cast(BOOL) GdiComment(HDC, UINT, ббайт*);}
cast(BOOL) AngleArc(HDC, цел, цел, cast(DWORD), FLOAT, FLOAT);}
cast(BOOL) PolyPolyline(HDC, POINT*, cast(DWORD)*, cast(DWORD));}
cast(BOOL) GetWorldTransform(HDC, LPXFORM);}
cast(BOOL) SetWorldTransform(HDC, XFORM*);}
cast(BOOL) ModifyWorldTransform(HDC, XFORM*, cast(DWORD));}
cast(BOOL) CombineTransform(LPXFORM, XFORM*, XFORM*);}
HBITMAP CreateDIBSection(HDC, BITMAPINFO*, UINT, LPVOID*, cast(HANDLE), cast(DWORD));}
UINT GetDIBColorTable(HDC, UINT, UINT, RGBQUAD*);}
UINT SetDIBColorTable(HDC, UINT, UINT, RGBQUAD*);}
cast(BOOL) SetColorAdjustment(HDC, COLORADJUSTMENT*);}
cast(BOOL) GetColorAdjustment(HDC, LPCOLORADJUSTMENT);}
HPALETTE CreateHalftonePalette(HDC);}
цел EndDoc(HDC);}
цел StartPage(HDC);}
цел EndPage(HDC);}
цел AbortDoc(HDC);}
цел SetAbortProc(HDC, TABORTPROC);}
cast(BOOL) ArcTo(HDC, цел, цел, цел, цел, цел, цел, цел, цел);}
cast(BOOL) BeginPath(HDC);}
cast(BOOL) CloseFigure(HDC);}
cast(BOOL) EndPath(HDC);}
cast(BOOL) FillPath(HDC);}
cast(BOOL) FlattenPath(HDC);}
цел GetPath(HDC, LPPOINT, LPBYTE, цел);}
HRGN PathToRegion(HDC);}
cast(BOOL) PolyDraw(HDC, POINT*, ббайт*, цел);}
cast(BOOL) SelectClipPath(HDC, цел);}
цел SetArcDirection(HDC, цел);}
cast(BOOL) SetMiterLimit(HDC, FLOAT, PFLOAT);}
cast(BOOL) StrokeAndFillPath(HDC);}
cast(BOOL) StrokePath(HDC);}
cast(BOOL) WidenPath(HDC);}
HPEN ExtCreatePen(cast(DWORD), cast(DWORD), LOGBRUSH*, cast(DWORD), cast(DWORD)*);}
cast(BOOL) GetMiterLimit(HDC, PFLOAT);}
цел GetArcDirection(HDC);}
cast(BOOL) MoveToEx(HDC, цел, цел, LPPOINT);}
HRGN CreatePolygonRgn(POINT*, цел, цел);}
cast(BOOL) DPtoLP(HDC, LPPOINT, цел);}
cast(BOOL) LPtoDP(HDC, LPPOINT, цел);}
cast(BOOL) Polygon(HDC, POINT*, цел);}
cast(BOOL) Polyline(HDC, POINT*, цел);}
cast(BOOL) PolyBezier(HDC, POINT*, cast(DWORD));}
cast(BOOL) PolyBezierTo(HDC, POINT*, cast(DWORD));}
cast(BOOL) PolylineTo(HDC, POINT*, cast(DWORD));}
cast(BOOL) SetViewportExtEx(HDC, цел, цел, LPSIZE);}
cast(BOOL) SetViewportOrgEx(HDC, цел, цел, LPPOINT);}
cast(BOOL) SetWindowExtEx(HDC, цел, цел, LPSIZE);}
cast(BOOL) SetWindowOrgEx(HDC, цел, цел, LPPOINT);}
cast(BOOL) OffsetViewportOrgEx(HDC, цел, цел, LPPOINT);}
cast(BOOL) OffsetWindowOrgEx(HDC, цел, цел, LPPOINT);}
cast(BOOL) ScaleViewportExtEx(HDC, цел, цел, цел, цел, LPSIZE);}
cast(BOOL) ScaleWindowExtEx(HDC, цел, цел, цел, цел, LPSIZE);}
cast(BOOL) SetBitmapDimensionEx(HBITMAP, цел, цел, LPSIZE);}
cast(BOOL) SetBrushOrgEx(HDC, цел, цел, LPPOINT);}
cast(BOOL) GetDCOrgEx(HDC, LPPOINT);}
cast(BOOL) FixBrushOrgEx(HDC, цел, цел, LPPOINT);}
cast(BOOL) UnrealizeObject(HGDIOBJ);}
cast(BOOL) GdiFlush();}
cast(DWORD) GdiSetBatchLimit(cast(DWORD));}
cast(DWORD) GdiGetBatchLimit();}
цел SetICMMode(HDC, цел);}
cast(BOOL) CheckColorsInGamut(HDC, cast(LPVOID), cast(LPVOID), cast(DWORD));}
cast(HANDLE) GetColorSpace(HDC);}
cast(BOOL) SetColorSpace(HDC, HCOLORSPACE);}
cast(BOOL) DeleteColorSpace(HCOLORSPACE);}
cast(BOOL) GetDeviceGammaRamp(HDC, cast(LPVOID));}
cast(BOOL) SetDeviceGammaRamp(HDC, cast(LPVOID));}
cast(BOOL) ColorMatchToTarget(HDC, HDC, cast(DWORD));}
HPROPSHEETPAGE CreatePropertySheetPageA(LPCPROPSHEETPAGE);}
cast(BOOL) DestroyPropertySheetPage(HPROPSHEETPAGE);}
проц InitCommonControls();}
HIMAGELIST ImageList_Create(цел, цел, UINT, цел, цел);}
cast(BOOL) ImageList_Destroy(HIMAGELIST);}
цел ImageList_GetImageCount(HIMAGELIST);}
цел ImageList_добавь(HIMAGELIST, HBITMAP, HBITMAP);}
цел ImageList_ReplaceIcon(HIMAGELIST, цел, HICON);}
COLORREF ImageList_SetBkColor(HIMAGELIST, COLORREF);}
COLORREF ImageList_GetBkColor(HIMAGELIST);}
cast(BOOL) ImageList_SetOverlayImage(HIMAGELIST, цел, цел);}
cast(BOOL) ImageList_Draw(HIMAGELIST, цел, HDC, цел, цел, UINT);}
cast(BOOL) ImageList_Replace(HIMAGELIST, цел, HBITMAP, HBITMAP);}
цел ImageList_добавьMasked(HIMAGELIST, HBITMAP, COLORREF);}
cast(BOOL) ImageList_DrawEx(HIMAGELIST, цел, HDC, цел, цел, цел, цел, COLORREF, COLORREF, UINT);}
cast(BOOL) ImageList_Remove(HIMAGELIST, цел);}
HICON ImageList_GetIcon(HIMAGELIST, цел, UINT);}
cast(BOOL) ImageList_BeginDrag(HIMAGELIST, цел, цел, цел);}
проц ImageList_EndDrag();}
cast(BOOL) ImageList_DragEnter(HWND, цел, цел);}
cast(BOOL) ImageList_DragLeave(HWND);}
cast(BOOL) ImageList_DragMove(цел, цел);}
cast(BOOL) ImageList_SetDragCursorImage(HIMAGELIST, цел, цел, цел);}
cast(BOOL) ImageList_DragShowNolock(cast(BOOL));}
HIMAGELIST ImageList_GetDragImage(POINT*, POINT*);}
cast(BOOL) ImageList_GetIconSize(HIMAGELIST, цел*, цел*);}
cast(BOOL) ImageList_SetIconSize(HIMAGELIST, цел, цел);}
cast(BOOL) ImageList_GetImageInfo(HIMAGELIST, цел, IMAGEINFO*);}
HIMAGELIST ImageList_Merge(HIMAGELIST, цел, HIMAGELIST, цел, цел, цел);}
HWND CreateToolbarEx(HWND, cast(DWORD), UINT, цел, HINST, UINT, LPCTBBUTTON, цел, цел, цел, цел, цел, UINT);}
HBITMAP CreateMappedBitmap(HINST, цел, UINT, LPCOLORMAP, цел);}
проц MenuHelp(UINT, WPARAM, LPARAM, HMENU, HINST, HWND);}
cast(BOOL) ShowHideMenuCtl(HWND, UINT, LPINT);}
проц GetEffectiveClientRect(HWND, LPRECT);}
cast(BOOL) MakeDragList(HWND);}
проц DrawInsert(HWND, HWND);}
цел LBItemFromPt(HWND, POINT, cast(BOOL));}
HWND CreateUpDownControl(cast(DWORD), цел, цел, цел, цел, HWND, цел, HINST, HWND, цел, цел, цел);}
LONG RegCloseKey(HKEY);}
LONG RegSetKeySecurity(HKEY, SECURITY_INFORMATION, PSECURITY_DESCRIPTOR);}
LONG RegFlushKey(HKEY);}
LONG RegGetKeySecurity(HKEY, SECURITY_INFORMATION, PSECURITY_DESCRIPTOR, cast(LPDWORD));}
LONG RegNotifyChangeKeyValue(HKEY, cast(BOOL), cast(DWORD), cast(HANDLE), cast(BOOL));}
cast(BOOL) IsValidCodePage(UINT);}
UINT GetACP();}
UINT GetOEMCP();}
cast(BOOL) GetCPInfo(UINT, LPCPINFO);}
cast(BOOL) IsDBCSLeadByte(ббайт);}
cast(BOOL) IsDBCSLeadByteEx(UINT, ббайт);}
cast(BOOL) IsValidLocale(LCID, cast(DWORD));}
LCID GetThreadLocale();}
cast(BOOL) SetThreadLocale(LCID);}
LANGID GetSystemDefaultLangID();}
LANGID GetUserDefaultLangID();}
LCID GetSystemDefaultLCID();}
LCID GetUserDefaultLCID();}
cast(BOOL) ReadConsoleOutputAttribute(cast(HANDLE), LPWORD, cast(DWORD), COORD, cast(LPDWORD));}
cast(BOOL) WriteConsoleOutputAttribute(cast(HANDLE), бкрат*, cast(DWORD), COORD, cast(LPDWORD));}
cast(BOOL) GetNumberOfConsoleInputEvents(cast(HANDLE), Pcast(DWORD));}
COORD GetLargestConsoleWindowSize(cast(HANDLE));}
cast(BOOL) GetConsoleCursorInfo(cast(HANDLE), PCONSOLE_CURSOR_INFO);}
cast(BOOL) GetNumberOfConsoleMouseButtons(cast(LPDWORD));}
cast(BOOL) SetConsoleActiveScreenBuffer(cast(HANDLE));}
cast(BOOL) FlushConsoleInputBuffer(cast(HANDLE));}
cast(BOOL) SetConsoleScreenBufferSize(cast(HANDLE), COORD);}
cast(BOOL) SetConsoleCursorPosition(cast(HANDLE), COORD);}
cast(BOOL) SetConsoleCursorInfo(cast(HANDLE), PCONSOLE_CURSOR_INFO);}
cast(BOOL) SetConsoleWindowInfo(cast(HANDLE), cast(BOOL), SMALL_RECT*);}
cast(BOOL) SetConsoleCtrlHandler(Pcast(HANDLE)R_ROUTINE, cast(BOOL));}
cast(BOOL) GenerateConsoleCtrlEvent(cast(DWORD), cast(DWORD));}
cast(BOOL) AllocConsole();}
cast(BOOL) FreeConsole();}
UINT GetConsoleCP();}
cast(BOOL) SetConsoleCP(UINT);}
UINT GetConsoleOutputCP();}
cast(BOOL) SetConsoleOutputCP(UINT);}
cast(DWORD) WNetConnectionDialog(HWND, cast(DWORD));}
cast(DWORD) WNetDisconnectDialog(HWND, cast(DWORD));}
cast(DWORD) WNetCloseEnum(cast(HANDLE));}
cast(BOOL) CloseServiceHandle(SC_cast(HANDLE));}
cast(BOOL) ControlService(SC_cast(HANDLE), cast(DWORD), LPSERVICE_STATUS);}
cast(BOOL) DeleteService(SC_cast(HANDLE));}
SC_LOCK LockServiceDatabase(SC_cast(HANDLE));}
cast(BOOL) NotifyBootConfigStatus(cast(BOOL));}
cast(BOOL) QueryServiceObjectSecurity(SC_cast(HANDLE), SECURITY_INFORMATION, PSECURITY_DESCRIPTOR, cast(DWORD), cast(LPDWORD));}
cast(BOOL) QueryServiceStatus(SC_cast(HANDLE), LPSERVICE_STATUS);}
cast(BOOL) SetServiceObjectSecurity(SC_cast(HANDLE), SECURITY_INFORMATION, PSECURITY_DESCRIPTOR);}
cast(BOOL) SetServiceStatus(SERVICE_STATUS_cast(HANDLE), LPSERVICE_STATUS);}
cast(BOOL) UnlockServiceDatabase(SC_LOCK);}
цел ChoosePixelFormat(HDC, PIXELFORMATDESCRIPTOR*);}
цел DescribePixelFormat(HDC, цел, UINT, LPPIXELFORMATDESCRIPTOR);}
cast(BOOL) SetPixelFormat(HDC, цел, PPIXELFORMATDESCRIPTOR);}
cast(BOOL) SwapBuffers(HDC);}
cast(BOOL) DragQueryPoint(HDROP, LPPOINT);}
проц DragFinish(HDROP);}
проц DragAcceptFiles(HWND, cast(BOOL));}
HICON DuplicateIcon(HINST, HICON);}
cast(BOOL) DdeAbandonTransaction(cast(DWORD), HCONV, cast(DWORD));}
PBYTE DdeAccessData(HDDEDATA, Pcast(DWORD));}
HDDEDATA DdeAddData(HDDEDATA, PBYTE, cast(DWORD), cast(DWORD));}
HDDEDATA DdeClientTransaction(PBYTE, cast(DWORD), HCONV, HSZ, UINT, UINT, cast(DWORD), Pcast(DWORD));}
цел DdeCmpStringHandles(HSZ, HSZ);}
HCONV DdeConnect(cast(DWORD), HSZ, HSZ, CONVCONTEXT*);}
HCONVLIST DdeConnectList(cast(DWORD), HSZ, HSZ, HCONVLIST, PCONVCONTEXT);}
HDDEDATA DdeCreateDataHandle(cast(DWORD), LPBYTE, cast(DWORD), cast(DWORD), HSZ, UINT, UINT);}
cast(BOOL) DdeDisconnect(HCONV);}
cast(BOOL) DdeDisconnectList(HCONVLIST);}
cast(BOOL) DdeEnableCallback(cast(DWORD), HCONV, UINT);}
cast(BOOL) DdeFreeDataHandle(HDDEDATA);}
cast(BOOL) DdeFreeStringHandle(cast(DWORD), HSZ);}
cast(DWORD) DdeGetData(HDDEDATA, ббайт*, cast(DWORD), cast(DWORD));}
UINT DdeGetLastError(cast(DWORD));}
cast(BOOL) DdeImpersonateClient(HCONV);}
cast(BOOL) DdeKeepStringHandle(cast(DWORD), HSZ);}
HDDEDATA DdeNameService(cast(DWORD), HSZ, HSZ, UINT);}
cast(BOOL) DdePostAdvise(cast(DWORD), HSZ, HSZ);}
UINT DdeQueryConvInfo(HCONV, cast(DWORD), PCONVINFO);}
HCONV DdeQueryNextServer(HCONVLIST, HCONV);}
HCONV DdeReconnect(HCONV);}
cast(BOOL) DdeSetUserHandle(HCONV, cast(DWORD), cast(DWORD));}
cast(BOOL) DdeUnaccessData(HDDEDATA);}
cast(BOOL) DdeUninitialize(cast(DWORD));}
проц SHдобавьToRecentDocs(UINT);}
LPITEMIDLIST SHBrowseForFolder(LPBROWSEINFO);}
проц SHChangeNotify(LONG, UINT, LPCVOID);}
цел SHFileOperationA(LPSHFILEOPSTRUCTA);}
цел SHFileOperationW(LPSHFILEOPSTRUCTW);}
проц SHFreeNameMappings(cast(HANDLE));}
cast(DWORD) SHGetFileInfo(LPCTSTR, cast(DWORD), SHFILEINFO*, UINT, UINT);}
cast(BOOL) SHGetPathFromIDList(LPCITEMIDLIST, LPTSTR);}
HRESULT SHGetSpecialFolderLocation(HWND, цел, LPITEMIDLIST*);}
cast(BOOL) DdeSetQualityOfService(HWND, TSECURITYQUALITYOFSERVICE*, PSECURITYQUALITYOFSERVICE);}
cast(BOOL) GetCommMask(Tcast(HANDLE), cast(DWORD)*);}
cast(BOOL) GetDiskFreeSpaceExA(cast(LPCSTR), PULARGE_INTEGER, PULARGE_INTEGER, PULARGE_INTEGER);}
cast(BOOL) GetDiskFreeSpaceExW(cast(LPWSTR), PULARGE_INTEGER, PULARGE_INTEGER, PULARGE_INTEGER);}
cast(DWORD) GetKerningPairs(HDC, cast(DWORD), проц*);}
cast(BOOL) PostQueuedCompletionStatus (cast(HANDLE), cast(DWORD), ULONG, LPOVERLAPPED);}
cast(BOOL) GetOverlappedResult(Tcast(HANDLE), TOVERLAPPED*, cast(DWORD)*, cast(BOOL));}
cast(BOOL) GetQueuedCompletionStatus(Tcast(HANDLE), cast(DWORD)*, ULONG_PTR*, LPOVERLAPPED*, cast(DWORD));}
cast(BOOL) GetQueuedCompletionStatusEx(Tcast(HANDLE), OVERLAPPED_ENTRY*, ULONG, ULONG*, cast(DWORD), cast(BOOL));}
cast(BOOL) GetSystemPowerStatus(TSYSTEMPOWERSTATUS*);}
cast(BOOL) ReadFile(Tcast(HANDLE), проц*, cast(DWORD), cast(DWORD)*, LPOVERLAPPED);}
cast(BOOL) SetThreadContext(Tcast(HANDLE), TCONTEXT*);}
cast(BOOL) wglDescribeLayerPlane(HDC, цел, цел, бцел, TLAYERPLANEDESCRIPTOR*);}
цел wglGetLayerPaletteEntries(HDC, цел, цел, цел, проц*);}
цел wglSetLayerPaletteEntries(HDC, цел, цел, цел, проц*);}
cast(DWORD) WNetGetResourceParentA(PNETRESOURCEA, LPVOID, cast(DWORD)*);}
cast(BOOL) WriteFile(Tcast(HANDLE), проц*, cast(DWORD), cast(DWORD)*, LPOVERLAPPED);}
cast(HANDLE) OpenWaitableTimerA(cast(DWORD) dwDesiredAccess, cast(BOOL) bInheritHandle, cast(LPCSTR) lpTimerName);}
cast(HANDLE) OpenWaitableTimerW(cast(DWORD) dwDesiredAccess, cast(BOOL) bInheritHandle, cast(LPCWSTR) lpTimerName);}
cast(BOOL) SetWaitableTimer(cast(HANDLE) hTimer, LARGE_INTEGER* pDueTime, LONG lPeriod, PTIMERAPCROUTINE pfnCompletionRoutine, cast(LPVOID) lpArgToCompletionRoutine, cast(BOOL) fResume);}
}
*/






////////////////////////////////////////////////////////////////////////////////////// 

/**
 *  Windows is a registered trademark of Microsoft Corporation in the United
 *  States and other countries.
 *
 * Copyright: Copyright Digital Mars 2000 - 2009.
 * License:   <a href="http://www.boost.org/LICENSE_1_0.txt">Boost License 1.0</a>.
 * Authors:   Walter Bright, Sean Kelly
 *
 *          Copyright Digital Mars 2000 - 2009.
 * Distributed under the Boost Software License, Version 1.0.
 *    (See accompanying file LICENSE_1_0.txt or copy at
 *          http://www.boost.org/LICENSE_1_0.txt)
 */


 extern  (Windows) {  
    void FlushFileBuffers(HANDLE файлУк);
    DWORD  GetFileType(HANDLE файлУк);
  }
  
extern (Windows)
{

version(D_Version2) {
  mixin("
  const(wchar)* MAKEINTRESOURCEW(int i) {
    return cast(wchar*)cast(uint)cast(ushort)i;
  }
  ");
}
else {
  wchar* MAKEINTRESOURCEW(int i) {
    return cast(wchar*)cast(uint)cast(ushort)i;
	}
	
	шим* ДЕЛИНТРЕСУРС(цел i){return cast(шим*) MAKEINTRESOURCEW(cast(int) i);}
  
}
alias MAKEINTRESOURCEW MAKEINTRESOURCE;

const wchar* RT_STRING       = MAKEINTRESOURCE(6);

   // alias DWORD ACCESS_MASK;
    alias ACCESS_MASK *PACCESS_MASK;
    alias ACCESS_MASK REGSAM;

    alias int function() FARPROC;
   

version (0)
{   // Properly prototyped versions
    alias BOOL function(HWND, UINT, WPARAM, LPARAM) DLGPROC;
    alias VOID function(HWND, UINT, UINT, DWORD) TIMERPROC;
    alias BOOL function(HDC, LPARAM, int) GRAYSTRINGPROC;
    alias BOOL function(HWND, LPARAM) WNDENUMPROC;
    alias LRESULT function(int code, WPARAM wParam, LPARAM lParam) HOOKPROC;
    alias VOID function(HWND, UINT, DWORD, LRESULT) SENDASYNCPROC;
    alias BOOL function(HWND, LPCSTR, HANDLE) PROPENUMPROCA;
    alias BOOL function(HWND, LPCWSTR, HANDLE) PROPENUMPROCW;
    alias BOOL function(HWND, LPSTR, HANDLE, DWORD) PROPENUMPROCEXA;
    alias BOOL function(HWND, LPWSTR, HANDLE, DWORD) PROPENUMPROCEXW;
    alias int function(LPSTR lpch, int ichCurrent, int cch, int code)
       EDITWORDBREAKPROCA;
    alias int function(LPWSTR lpch, int ichCurrent, int cch, int code)
       EDITWORDBREAKPROCW;
    alias BOOL function(HDC hdc, LPARAM lData, WPARAM wData, int cx, int cy)
       DRAWSTATEPROC;
}
else
{
    alias FARPROC DLGPROC;
    alias FARPROC TIMERPROC;
    alias FARPROC GRAYSTRINGPROC;
    alias FARPROC WNDENUMPROC;
    alias FARPROC HOOKPROC;
    alias FARPROC SENDASYNCPROC;
    alias FARPROC EDITWORDBREAKPROCA;
    alias FARPROC EDITWORDBREAKPROCW;
    alias FARPROC PROPENUMPROCA;
    alias FARPROC PROPENUMPROCW;
    alias FARPROC PROPENUMPROCEXA;
    alias FARPROC PROPENUMPROCEXW;
    alias FARPROC DRAWSTATEPROC;
}



enum : uint
{
    MAX_PATH = 260,
    HINSTANCE_ERROR = 32,
}


enum : DWORD
{
    MAILSLOT_NO_MESSAGE = cast(DWORD)-1,
    MAILSLOT_WAIT_FOREVER = cast(DWORD)-1,
}


/+
struct MEMORYSTATUSEX 
{
  DWORD dwLength;
  DWORD dwMemoryLoad; 
  DWORDLONG ullTotalPhys; 
  DWORDLONG ullAvailPhys; 
  DWORDLONG ullTotalPageFile;
  DWORDLONG ullAvailPageFile; 
  DWORDLONG ullTotalVirtual;  
  DWORDLONG ullAvailVirtual; 
  DWORDLONG ullAvailExtendedVirtual;
}
alias MEMORYSTATUSEX *LPMEMORYSTATUSEX;

+/


enum
{
    SORT_DEFAULT                   = 0x0,    // sorting default

    SORT_JAPANESE_XJIS             = 0x0,    // Japanese XJIS order
    SORT_JAPANESE_UNICODE          = 0x1,    // Japanese Unicode order

    SORT_CHINESE_BIG5              = 0x0,    // Chinese BIG5 order
    SORT_CHINESE_PRCP              = 0x0,    // PRC Chinese Phonetic order
    SORT_CHINESE_UNICODE           = 0x1,    // Chinese Unicode order
    SORT_CHINESE_PRC               = 0x2,    // PRC Chinese Stroke Count order

    SORT_KOREAN_KSC                = 0x0,    // Korean KSC order
    SORT_KOREAN_UNICODE            = 0x1,    // Korean Unicode order

    SORT_GERMAN_PHONE_BOOK         = 0x1,    // German Phone Book order
}

// end_r_winnt

//
//  A language ID is a 16 bit value which is the combination of a
//  primary language ID and a secondary language ID.  The bits are
//  allocated as follows:
//
//       +-----------------------+-------------------------+
//       |     Sublanguage ID    |   Primary Language ID   |
//       +-----------------------+-------------------------+
//        15                   10 9                       0   bit
//
//
//  Language ID creation/extraction macros:
//
//    MAKELANGID    - construct language id from a primary language id and
//                    a sublanguage id.
//    PRIMARYLANGID - extract primary language id from a language id.
//    SUBLANGID     - extract sublanguage id from a language id.
//

int MAKELANGID(int p, int s) { return ((cast(WORD)s) << 10) | cast(WORD)p; }
WORD PRIMARYLANGID(int lgid) { return cast(WORD)(lgid & 0x3ff); }
WORD SUBLANGID(int lgid)     { return cast(WORD)(lgid >> 10); }



enum
{
    SIZE_OF_80387_REGISTERS =      80,
//
// The following flags control the contents of the CONTEXT structure.
//
    CONTEXT_i386 =    0x00010000,    // this assumes that i386 and
    CONTEXT_i486 =    0x00010000,    // i486 have identical context records

    CONTEXT_CONTROL =         (CONTEXT_i386 | 0x00000001), // SS:SP, CS:IP, FLAGS, BP
    CONTEXT_INTEGER =         (CONTEXT_i386 | 0x00000002), // AX, BX, CX, DX, SI, DI
    CONTEXT_SEGMENTS =        (CONTEXT_i386 | 0x00000004), // DS, ES, FS, GS
    CONTEXT_FLOATING_POINT =  (CONTEXT_i386 | 0x00000008), // 387 state
    CONTEXT_DEBUG_REGISTERS = (CONTEXT_i386 | 0x00000010), // DB 0-3,6,7

    CONTEXT_FULL = (CONTEXT_CONTROL | CONTEXT_INTEGER | CONTEXT_SEGMENTS),
}

enum
{
    THREAD_BASE_PRIORITY_LOWRT =  15,  // value that gets a thread to LowRealtime-1
    THREAD_BASE_PRIORITY_MAX =    2,   // maximum thread base priority boost
    THREAD_BASE_PRIORITY_MIN =    -2,  // minimum thread base priority boost
    THREAD_BASE_PRIORITY_IDLE =   -15, // value that gets a thread to idle

    THREAD_PRIORITY_LOWEST =          THREAD_BASE_PRIORITY_MIN,
    THREAD_PRIORITY_BELOW_NORMAL =    (THREAD_PRIORITY_LOWEST+1),
    THREAD_PRIORITY_NORMAL =          0,
    THREAD_PRIORITY_HIGHEST =         THREAD_BASE_PRIORITY_MAX,
    THREAD_PRIORITY_ABOVE_NORMAL =    (THREAD_PRIORITY_HIGHEST-1),
    THREAD_PRIORITY_ERROR_RETURN =    int.max,

    THREAD_PRIORITY_TIME_CRITICAL =   THREAD_BASE_PRIORITY_LOWRT,
    THREAD_PRIORITY_IDLE =            THREAD_BASE_PRIORITY_IDLE,
}


// Synchronization

extern (Windows)
{


/+
BOOL GlobalMemoryStatusEx(  LPMEMORYSTATUSEX буф);
+/
BOOL IsBadCodePtr(  FARPROC lpfn);
BOOL IsBadReadPtr(LPVOID, UINT);
BOOL IsBadWritePtr(LPVOID, UINT);
BOOL IsBadHugeReadPtr(LPVOID, UINT);
BOOL IsBadHugeWritePtr(LPVOID, UINT);

LONG  InterlockedIncrement(LPLONG lpAddend);
LONG  InterlockedDecrement(LPLONG lpAddend);
LONG  InterlockedExchange(LPLONG Target, LONG Value);
LONG  InterlockedExchangeAdd(LPLONG Addend, LONG Value);
PVOID InterlockedCompareExchange(PVOID *Destination, PVOID Exchange, PVOID Comperand);

void InitializeCriticalSection(CRITICAL_SECTION * lpCriticalSection);
void EnterCriticalSection(CRITICAL_SECTION * lpCriticalSection);
BOOL TryEnterCriticalSection(CRITICAL_SECTION * lpCriticalSection);
void LeaveCriticalSection(CRITICAL_SECTION * lpCriticalSection);
}





enum
{
    WM_NOTIFY =                       0x004E,
    WM_INPUTLANGCHANGEREQUEST =       0x0050,
    WM_INPUTLANGCHANGE =              0x0051,
    WM_TCARD =                        0x0052,
    WM_HELP =                         0x0053,
    WM_USERCHANGED =                  0x0054,
    WM_NOTIFYFORMAT =                 0x0055,

    NFR_ANSI =                             1,
    NFR_UNICODE =                          2,
    NF_QUERY =                             3,
    NF_REQUERY =                           4,

    WM_CONTEXTMENU =                  0x007B,
    WM_STYLECHANGING =                0x007C,
    WM_STYLECHANGED =                 0x007D,
    WM_DISPLAYCHANGE =                0x007E,
    WM_GETICON =                      0x007F,
    WM_SETICON =                      0x0080,



    WM_NCCREATE =                     0x0081,
    WM_NCDESTROY =                    0x0082,
    WM_NCCALCSIZE =                   0x0083,
    WM_NCHITTEST =                    0x0084,
    WM_NCPAINT =                      0x0085,
    WM_NCACTIVATE =                   0x0086,
    WM_GETDLGCODE =                   0x0087,

    WM_NCMOUSEMOVE =                  0x00A0,
    WM_NCLBUTTONDOWN =                0x00A1,
    WM_NCLBUTTONUP =                  0x00A2,
    WM_NCLBUTTONDBLCLK =              0x00A3,
    WM_NCRBUTTONDOWN =                0x00A4,
    WM_NCRBUTTONUP =                  0x00A5,
    WM_NCRBUTTONDBLCLK =              0x00A6,
    WM_NCMBUTTONDOWN =                0x00A7,
    WM_NCMBUTTONUP =                  0x00A8,
    WM_NCMBUTTONDBLCLK =              0x00A9,

    WM_KEYFIRST =                     0x0100,
    WM_KEYDOWN =                      0x0100,
    WM_KEYUP =                        0x0101,
    WM_CHAR =                         0x0102,
    WM_DEADCHAR =                     0x0103,
    WM_SYSKEYDOWN =                   0x0104,
    WM_SYSKEYUP =                     0x0105,
    WM_SYSCHAR =                      0x0106,
    WM_SYSDEADCHAR =                  0x0107,
    WM_KEYLAST =                      0x0108,


    WM_IME_STARTCOMPOSITION =         0x010D,
    WM_IME_ENDCOMPOSITION =           0x010E,
    WM_IME_COMPOSITION =              0x010F,
    WM_IME_KEYLAST =                  0x010F,


    WM_INITDIALOG =                   0x0110,
    WM_COMMAND =                      0x0111,
    WM_SYSCOMMAND =                   0x0112,
    WM_TIMER =                        0x0113,
    WM_HSCROLL =                      0x0114,
    WM_VSCROLL =                      0x0115,
    WM_INITMENU =                     0x0116,
    WM_INITMENUPOPUP =                0x0117,
    WM_MENUSELECT =                   0x011F,
    WM_MENUCHAR =                     0x0120,
    WM_ENTERIDLE =                    0x0121,

    WM_CTLCOLORMSGBOX =               0x0132,
    WM_CTLCOLOREDIT =                 0x0133,
    WM_CTLCOLORLISTBOX =              0x0134,
    WM_CTLCOLORBTN =                  0x0135,
    WM_CTLCOLORDLG =                  0x0136,
    WM_CTLCOLORSCROLLBAR =            0x0137,
    WM_CTLCOLORSTATIC =               0x0138,



    WM_MOUSEFIRST =                   0x0200,
    WM_MOUSEMOVE =                    0x0200,
    WM_LBUTTONDOWN =                  0x0201,
    WM_LBUTTONUP =                    0x0202,
    WM_LBUTTONDBLCLK =                0x0203,
    WM_RBUTTONDOWN =                  0x0204,
    WM_RBUTTONUP =                    0x0205,
    WM_RBUTTONDBLCLK =                0x0206,
    WM_MBUTTONDOWN =                  0x0207,
    WM_MBUTTONUP =                    0x0208,
    WM_MBUTTONDBLCLK =                0x0209,



    WM_MOUSELAST =                    0x0209,








    WM_PARENTNOTIFY =                 0x0210,
    MENULOOP_WINDOW =                 0,
    MENULOOP_POPUP =                  1,
    WM_ENTERMENULOOP =                0x0211,
    WM_EXITMENULOOP =                 0x0212,


    WM_NEXTMENU =                     0x0213,
}

enum
{
/*
 * Dialog Box Command IDs
 */
    IDOK =                1,
    IDCANCEL =            2,
    IDABORT =             3,
    IDRETRY =             4,
    IDIGNORE =            5,
    IDYES =               6,
    IDNO =                7,

    IDCLOSE =         8,
    IDHELP =          9,


// end_r_winuser



/*
 * Control Manager Structures and Definitions
 */



// begin_r_winuser

/*
 * Edit Control Styles
 */
    ES_LEFT =             0x0000,
    ES_CENTER =           0x0001,
    ES_RIGHT =            0x0002,
    ES_MULTILINE =        0x0004,
    ES_UPPERCASE =        0x0008,
    ES_LOWERCASE =        0x0010,
    ES_PASSWORD =         0x0020,
    ES_AUTOVSCROLL =      0x0040,
    ES_AUTOHSCROLL =      0x0080,
    ES_NOHIDESEL =        0x0100,
    ES_OEMCONVERT =       0x0400,
    ES_READONLY =         0x0800,
    ES_WANTRETURN =       0x1000,

    ES_NUMBER =           0x2000,


// end_r_winuser



/*
 * Edit Control Notification Codes
 */
    EN_SETFOCUS =         0x0100,
    EN_KILLFOCUS =        0x0200,
    EN_CHANGE =           0x0300,
    EN_UPDATE =           0x0400,
    EN_ERRSPACE =         0x0500,
    EN_MAXTEXT =          0x0501,
    EN_HSCROLL =          0x0601,
    EN_VSCROLL =          0x0602,


/* Edit control EM_SETMARGIN parameters */
    EC_LEFTMARGIN =       0x0001,
    EC_RIGHTMARGIN =      0x0002,
    EC_USEFONTINFO =      0xffff,




// begin_r_winuser

/*
 * Edit Control Messages
 */
    EM_GETSEL =               0x00B0,
    EM_SETSEL =               0x00B1,
    EM_GETRECT =              0x00B2,
    EM_SETRECT =              0x00B3,
    EM_SETRECTNP =            0x00B4,
    EM_SCROLL =               0x00B5,
    EM_LINESCROLL =           0x00B6,
    EM_SCROLLCARET =          0x00B7,
    EM_GETMODIFY =            0x00B8,
    EM_SETMODIFY =            0x00B9,
    EM_GETLINECOUNT =         0x00BA,
    EM_LINEINDEX =            0x00BB,
    EM_SETHANDLE =            0x00BC,
    EM_GETHANDLE =            0x00BD,
    EM_GETTHUMB =             0x00BE,
    EM_LINELENGTH =           0x00C1,
    EM_REPLACESEL =           0x00C2,
    EM_GETLINE =              0x00C4,
    EM_LIMITTEXT =            0x00C5,
    EM_CANUNDO =              0x00C6,
    EM_UNDO =                 0x00C7,
    EM_FMTLINES =             0x00C8,
    EM_LINEFROMCHAR =         0x00C9,
    EM_SETTABSTOPS =          0x00CB,
    EM_SETPASSWORDCHAR =      0x00CC,
    EM_EMPTYUNDOBUFFER =      0x00CD,
    EM_GETFIRSTVISIBLELINE =  0x00CE,
    EM_SETREADONLY =          0x00CF,
    EM_SETWORDBREAKPROC =     0x00D0,
    EM_GETWORDBREAKPROC =     0x00D1,
    EM_GETPASSWORDCHAR =      0x00D2,

    EM_SETMARGINS =           0x00D3,
    EM_GETMARGINS =           0x00D4,
    EM_SETLIMITTEXT =         EM_LIMITTEXT, /* ;win40 Name change */
    EM_GETLIMITTEXT =         0x00D5,
    EM_POSFROMCHAR =          0x00D6,
    EM_CHARFROMPOS =          0x00D7,



// end_r_winuser


/*
 * EDITWORDBREAKPROC code values
 */
    WB_LEFT =            0,
    WB_RIGHT =           1,
    WB_ISDELIMITER =     2,

// begin_r_winuser

/*
 * Button Control Styles
 */
    BS_PUSHBUTTON =       0x00000000,
    BS_DEFPUSHBUTTON =    0x00000001,
    BS_CHECKBOX =         0x00000002,
    BS_AUTOCHECKBOX =     0x00000003,
    BS_RADIOBUTTON =      0x00000004,
    BS_3STATE =           0x00000005,
    BS_AUTO3STATE =       0x00000006,
    BS_GROUPBOX =         0x00000007,
    BS_USERBUTTON =       0x00000008,
    BS_AUTORADIOBUTTON =  0x00000009,
    BS_OWNERDRAW =        0x0000000B,
    BS_LEFTTEXT =         0x00000020,

    BS_TEXT =             0x00000000,
    BS_ICON =             0x00000040,
    BS_BITMAP =           0x00000080,
    BS_LEFT =             0x00000100,
    BS_RIGHT =            0x00000200,
    BS_CENTER =           0x00000300,
    BS_TOP =              0x00000400,
    BS_BOTTOM =           0x00000800,
    BS_VCENTER =          0x00000C00,
    BS_PUSHLIKE =         0x00001000,
    BS_MULTILINE =        0x00002000,
    BS_NOTIFY =           0x00004000,
    BS_FLAT =             0x00008000,
    BS_RIGHTBUTTON =      BS_LEFTTEXT,



/*
 * User Button Notification Codes
 */
    BN_CLICKED =          0,
    BN_PAINT =            1,
    BN_HILITE =           2,
    BN_UNHILITE =         3,
    BN_DISABLE =          4,
    BN_DOUBLECLICKED =    5,

    BN_PUSHED =           BN_HILITE,
    BN_UNPUSHED =         BN_UNHILITE,
    BN_DBLCLK =           BN_DOUBLECLICKED,
    BN_SETFOCUS =         6,
    BN_KILLFOCUS =        7,

/*
 * Button Control Messages
 */
    BM_GETCHECK =        0x00F0,
    BM_SETCHECK =        0x00F1,
    BM_GETSTATE =        0x00F2,
    BM_SETSTATE =        0x00F3,
    BM_SETSTYLE =        0x00F4,

    BM_CLICK =           0x00F5,
    BM_GETIMAGE =        0x00F6,
    BM_SETIMAGE =        0x00F7,

    BST_UNCHECKED =      0x0000,
    BST_CHECKED =        0x0001,
    BST_INDETERMINATE =  0x0002,
    BST_PUSHED =         0x0004,
    BST_FOCUS =          0x0008,


/*
 * Static Control Constants
 */
    SS_LEFT =             0x00000000,
    SS_CENTER =           0x00000001,
    SS_RIGHT =            0x00000002,
    SS_ICON =             0x00000003,
    SS_BLACKRECT =        0x00000004,
    SS_GRAYRECT =         0x00000005,
    SS_WHITERECT =        0x00000006,
    SS_BLACKFRAME =       0x00000007,
    SS_GRAYFRAME =        0x00000008,
    SS_WHITEFRAME =       0x00000009,
    SS_USERITEM =         0x0000000A,
    SS_SIMPLE =           0x0000000B,
    SS_LEFTNOWORDWRAP =   0x0000000C,

    SS_OWNERDRAW =        0x0000000D,
    SS_BITMAP =           0x0000000E,
    SS_ENHMETAFILE =      0x0000000F,
    SS_ETCHEDHORZ =       0x00000010,
    SS_ETCHEDVERT =       0x00000011,
    SS_ETCHEDFRAME =      0x00000012,
    SS_TYPEMASK =         0x0000001F,

    SS_NOPREFIX =         0x00000080, /* Don't do "&" character translation */

    SS_NOTIFY =           0x00000100,
    SS_CENTERIMAGE =      0x00000200,
    SS_RIGHTJUST =        0x00000400,
    SS_REALSIZEIMAGE =    0x00000800,
    SS_SUNKEN =           0x00001000,
    SS_ENDELLIPSIS =      0x00004000,
    SS_PATHELLIPSIS =     0x00008000,
    SS_WORDELLIPSIS =     0x0000C000,
    SS_ELLIPSISMASK =     0x0000C000,


// end_r_winuser


/*
 * Static Control Mesages
 */
    STM_SETICON =         0x0170,
    STM_GETICON =         0x0171,

    STM_SETIMAGE =        0x0172,
    STM_GETIMAGE =        0x0173,
    STN_CLICKED =         0,
    STN_DBLCLK =          1,
    STN_ENABLE =          2,
    STN_DISABLE =         3,

    STM_MSGMAX =          0x0174,
}


enum
{
/*
 * Window Messages
 */

    WM_NULL =                         0x0000,
    WM_CREATE =                       0x0001,
    WM_DESTROY =                      0x0002,
    WM_MOVE =                         0x0003,
    WM_SIZE =                         0x0005,

    WM_ACTIVATE =                     0x0006,
/*
 * WM_ACTIVATE state values
 */
    WA_INACTIVE =     0,
    WA_ACTIVE =       1,
    WA_CLICKACTIVE =  2,

    WM_SETFOCUS =                     0x0007,
    WM_KILLFOCUS =                    0x0008,
    WM_ENABLE =                       0x000A,
    WM_SETREDRAW =                    0x000B,
    WM_SETTEXT =                      0x000C,
    WM_GETTEXT =                      0x000D,
    WM_GETTEXTLENGTH =                0x000E,
    WM_PAINT =                        0x000F,
    WM_CLOSE =                        0x0010,
    WM_QUERYENDSESSION =              0x0011,
    WM_QUIT =                         0x0012,
    WM_QUERYOPEN =                    0x0013,
    WM_ERASEBKGND =                   0x0014,
    WM_SYSCOLORCHANGE =               0x0015,
    WM_ENDSESSION =                   0x0016,
    WM_SHOWWINDOW =                   0x0018,
    WM_WININICHANGE =                 0x001A,

    WM_SETTINGCHANGE =                WM_WININICHANGE,



    WM_DEVMODECHANGE =                0x001B,
    WM_ACTIVATEAPP =                  0x001C,
    WM_FONTCHANGE =                   0x001D,
    WM_TIMECHANGE =                   0x001E,
    WM_CANCELMODE =                   0x001F,
    WM_SETCURSOR =                    0x0020,
    WM_MOUSEACTIVATE =                0x0021,
    WM_CHILDACTIVATE =                0x0022,
    WM_QUEUESYNC =                    0x0023,

    WM_GETMINMAXINFO =                0x0024,
}


// flags for GetDCEx()

enum
{
    DCX_WINDOW =           0x00000001,
    DCX_CACHE =            0x00000002,
    DCX_NORESETATTRS =     0x00000004,
    DCX_CLIPCHILDREN =     0x00000008,
    DCX_CLIPSIBLINGS =     0x00000010,
    DCX_PARENTCLIP =       0x00000020,
    DCX_EXCLUDERGN =       0x00000040,
    DCX_INTERSECTRGN =     0x00000080,
    DCX_EXCLUDEUPDATE =    0x00000100,
    DCX_INTERSECTUPDATE =  0x00000200,
    DCX_LOCKWINDOWUPDATE = 0x00000400,
    DCX_VALIDATE =         0x00200000,
}

extern (Windows)
{
 BOOL UpdateWindow(HWND hWnd);
 HWND SetActiveWindow(HWND hWnd);
 HWND GetForegroundWindow();
 BOOL PaintDesktop(HDC hdc);
 BOOL SetForegroundWindow(HWND hWnd);
 HWND WindowFromDC(HDC hDC);
 HDC GetDC(HWND hWnd);
 HDC GetDCEx(HWND hWnd, HRGN hrgnClip, DWORD flags);
 HDC GetWindowDC(HWND hWnd);
 int ReleaseDC(HWND hWnd, HDC hDC);
 HDC BeginPaint(HWND hWnd, LPPAINTSTRUCT lpPaint);
 BOOL EndPaint(HWND hWnd, PAINTSTRUCT *lpPaint);
 BOOL GetUpdateRect(HWND hWnd, LPRECT lpRect, BOOL bErase);
 int GetUpdateRgn(HWND hWnd, HRGN hRgn, BOOL bErase);
 int SetWindowRgn(HWND hWnd, HRGN hRgn, BOOL bRedraw);
 int GetWindowRgn(HWND hWnd, HRGN hRgn);
 int ExcludeUpdateRgn(HDC hDC, HWND hWnd);
 BOOL InvalidateRect(HWND hWnd, RECT *lpRect, BOOL bErase);
 BOOL ValidateRect(HWND hWnd, RECT *lpRect);
 BOOL InvalidateRgn(HWND hWnd, HRGN hRgn, BOOL bErase);
 BOOL ValidateRgn(HWND hWnd, HRGN hRgn);
 BOOL RedrawWindow(HWND hWnd, RECT *lprcUpdate, HRGN hrgnUpdate, UINT flags);
}

// flags for RedrawWindow()
enum
{
    RDW_INVALIDATE =          0x0001,
    RDW_INTERNALPAINT =       0x0002,
    RDW_ERASE =               0x0004,
    RDW_VALIDATE =            0x0008,
    RDW_NOINTERNALPAINT =     0x0010,
    RDW_NOERASE =             0x0020,
    RDW_NOCHILDREN =          0x0040,
    RDW_ALLCHILDREN =         0x0080,
    RDW_UPDATENOW =           0x0100,
    RDW_ERASENOW =            0x0200,
    RDW_FRAME =               0x0400,
    RDW_NOFRAME =             0x0800,
}

extern (Windows)
{
 BOOL GetClientRect(HWND hWnd, LPRECT lpRect);
 BOOL GetWindowRect(HWND hWnd, LPRECT lpRect);
 BOOL AdjustWindowRect(LPRECT lpRect, DWORD dwStyle, BOOL bMenu);
 BOOL AdjustWindowRectEx(LPRECT lpRect, DWORD dwStyle, BOOL bMenu, DWORD dwExStyle);
 HFONT CreateFontA(int, int, int, int, int, DWORD,
                             DWORD, DWORD, DWORD, DWORD, DWORD,
                             DWORD, DWORD, LPCSTR);
 HFONT CreateFontW(int, int, int, int, int, DWORD,
                             DWORD, DWORD, DWORD, DWORD, DWORD,
                             DWORD, DWORD, LPCWSTR);
}

enum
{
    OUT_DEFAULT_PRECIS =          0,
    OUT_STRING_PRECIS =           1,
    OUT_CHARACTER_PRECIS =        2,
    OUT_STROKE_PRECIS =           3,
    OUT_TT_PRECIS =               4,
    OUT_DEVICE_PRECIS =           5,
    OUT_RASTER_PRECIS =           6,
    OUT_TT_ONLY_PRECIS =          7,
    OUT_OUTLINE_PRECIS =          8,
    OUT_SCREEN_OUTLINE_PRECIS =   9,

    CLIP_DEFAULT_PRECIS =     0,
    CLIP_CHARACTER_PRECIS =   1,
    CLIP_STROKE_PRECIS =      2,
    CLIP_MASK =               0xf,
    CLIP_LH_ANGLES =          (1<<4),
    CLIP_TT_ALWAYS =          (2<<4),
    CLIP_EMBEDDED =           (8<<4),

    DEFAULT_QUALITY =         0,
    DRAFT_QUALITY =           1,
    PROOF_QUALITY =           2,

    NONANTIALIASED_QUALITY =  3,
    ANTIALIASED_QUALITY =     4,


    DEFAULT_PITCH =           0,
    FIXED_PITCH =             1,
    VARIABLE_PITCH =          2,

    MONO_FONT =               8,


    ANSI_CHARSET =            0,
    DEFAULT_CHARSET =         1,
    SYMBOL_CHARSET =          2,
    ШИФТJIS_CHARSET =        128,
    HANGEUL_CHARSET =         129,
    GB2312_CHARSET =          134,
    CHINESEBIG5_CHARSET =     136,
    OEM_CHARSET =             255,

    JOHAB_CHARSET =           130,
    HEBREW_CHARSET =          177,
    ARABIC_CHARSET =          178,
    GREEK_CHARSET =           161,
    TURKISH_CHARSET =         162,
    VIETNAMESE_CHARSET =      163,
    THAI_CHARSET =            222,
    EASTEUROPE_CHARSET =      238,
    RUSSIAN_CHARSET =         204,

    MAC_CHARSET =             77,
    BALTIC_CHARSET =          186,

    FS_LATIN1 =               0x00000001L,
    FS_LATIN2 =               0x00000002L,
    FS_CYRILLIC =             0x00000004L,
    FS_GREEK =                0x00000008L,
    FS_TURKISH =              0x00000010L,
    FS_HEBREW =               0x00000020L,
    FS_ARABIC =               0x00000040L,
    FS_BALTIC =               0x00000080L,
    FS_VIETNAMESE =           0x00000100L,
    FS_THAI =                 0x00010000L,
    FS_JISJAPAN =             0x00020000L,
    FS_CHINESESIMP =          0x00040000L,
    FS_WANSUNG =              0x00080000L,
    FS_CHINESETRAD =          0x00100000L,
    FS_JOHAB =                0x00200000L,
    FS_SYMBOL =               cast(int)0x80000000L,


/* Font Families */
    FF_DONTCARE =         (0<<4), /* Don't care or don't know. */
    FF_ROMAN =            (1<<4), /* Variable stroke width, serifed. */
                                    /* Times Roman, Century Schoolbook, etc. */
    FF_SWISS =            (2<<4), /* Variable stroke width, sans-serifed. */
                                    /* Helvetica, Swiss, etc. */
    FF_MODERN =           (3<<4), /* Constant stroke width, serifed or sans-serifed. */
                                    /* Pica, Elite, Courier, etc. */
    FF_SCRIPT =           (4<<4), /* Cursive, etc. */
    FF_DECORATIVE =       (5<<4), /* Old English, etc. */

/* Font Weights */
    FW_DONTCARE =         0,
    FW_THIN =             100,
    FW_EXTRALIGHT =       200,
    FW_LIGHT =            300,
    FW_NORMAL =           400,
    FW_MEDIUM =           500,
    FW_SEMIBOLD =         600,
    FW_BOLD =             700,
    FW_EXTRABOLD =        800,
    FW_HEAVY =            900,

    FW_ULTRALIGHT =       FW_EXTRALIGHT,
    FW_REGULAR =          FW_NORMAL,
    FW_DEMIBOLD =         FW_SEMIBOLD,
    FW_ULTRABOLD =        FW_EXTRABOLD,
    FW_BLACK =            FW_HEAVY,

    PANOSE_COUNT =               10,
    PAN_FAMILYTYPE_INDEX =        0,
    PAN_SERIFSTYLE_INDEX =        1,
    PAN_WEIGHT_INDEX =            2,
    PAN_PROPORTION_INDEX =        3,
    PAN_CONTRAST_INDEX =          4,
    PAN_STROKEVARIATION_INDEX =   5,
    PAN_ARMSTYLE_INDEX =          6,
    PAN_LETTERFORM_INDEX =        7,
    PAN_MIDLINE_INDEX =           8,
    PAN_XHEIGHT_INDEX =           9,

    PAN_CULTURE_LATIN =           0,
}



extern (Windows)
{
 BOOL   RoundRect(HDC, int, int, int, int, int, int);
 BOOL   ResizePalette(HPALETTE, UINT);
 int    SaveDC(HDC);
 int    SelectClipRgn(HDC, HRGN);
 int    ExtSelectClipRgn(HDC, HRGN, int);
 int    SetMetaRgn(HDC);
 HGDIOBJ   SelectObject(HDC, HGDIOBJ);
 HPALETTE   SelectPalette(HDC, HPALETTE, BOOL);
 COLORREF   SetBkColor(HDC, COLORREF);
 int     SetBkMode(HDC, int);
 LONG    SetBitmapBits(HBITMAP, DWORD, void *);
 UINT    SetBoundsRect(HDC,   RECT *, UINT);
 int     SetDIBits(HDC, HBITMAP, UINT, UINT, void *, BITMAPINFO *, UINT);
 int     SetDIBitsToDevice(HDC, int, int, DWORD, DWORD, int,
        int, UINT, UINT, void *, BITMAPINFO *, UINT);
 DWORD   SetMapperFlags(HDC, DWORD);
 int     SetGraphicsMode(HDC hdc, int iMode);
 int     SetMapMode(HDC, int);
 HMETAFILE     SetMetaFileBitsEx(UINT, BYTE *);
 UINT    SetPaletteEntries(HPALETTE, UINT, UINT, PALETTEENTRY *);
 COLORREF   SetPixel(HDC, int, int, COLORREF);
 BOOL     SetPixelV(HDC, int, int, COLORREF);
 BOOL    SetPixelFormat(HDC, int, PIXELFORMATDESCRIPTOR *);
 int     SetPolyFillMode(HDC, int);
 BOOL    StretchBlt(HDC, int, int, int, int, HDC, int, int, int, int, DWORD);
 BOOL    SetRectRgn(HRGN, int, int, int, int);
 int     StretchDIBits(HDC, int, int, int, int, int, int, int, int,
         void *, BITMAPINFO *, UINT, DWORD);
 int     SetROP2(HDC, int);
 int     SetStretchBltMode(HDC, int);
 UINT    SetSystemPaletteUse(HDC, UINT);
 int     SetTextCharacterExtra(HDC, int);
 COLORREF   SetTextColor(HDC, COLORREF);
 UINT    SetTextAlign(HDC, UINT);
 BOOL    SetTextJustification(HDC, int, int);
 BOOL    UpdateColors(HDC);
}

/* Text Alignment Options */
enum
{
    TA_NOUPDATECP =                0,
    TA_UPDATECP =                  1,

    TA_LEFT =                      0,
    TA_RIGHT =                     2,
    TA_CENTER =                    6,

    TA_TOP =                       0,
    TA_BOTTOM =                    8,
    TA_BASELINE =                  24,

    TA_RTLREADING =                256,
    TA_MASK =       (TA_BASELINE+TA_CENTER+TA_UPDATECP+TA_RTLREADING),
}



extern (Windows)
{
 BOOL    MoveToEx(HDC, int, int, LPPOINT);
 BOOL    TextOutA(HDC, int, int, LPCSTR, int);
 BOOL    TextOutW(HDC, int, int, LPCWSTR, int);
}

extern (Windows) void PostQuitMessage(int nExitCode);
extern (Windows) LRESULT DefWindowProcA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);

/*
 * Window Styles
 */
enum : uint
{
    WS_OVERLAPPED =       0x00000000,
    WS_POPUP =            0x80000000,
    WS_CHILD =            0x40000000,
    WS_MINIMIZE =         0x20000000,
    WS_VISIBLE =          0x10000000,
    WS_DISABLED =         0x08000000,
    WS_CLIPSIBLINGS =     0x04000000,
    WS_CLIPCHILDREN =     0x02000000,
    WS_MAXIMIZE =         0x01000000,
    WS_CAPTION =          0x00C00000,  /* WS_BORDER | WS_DLGFRAME  */
    WS_BORDER =           0x00800000,
    WS_DLGFRAME =         0x00400000,
    WS_VSCROLL =          0x00200000,
    WS_HSCROLL =          0x00100000,
    WS_SYSMENU =          0x00080000,
    WS_THICKFRAME =       0x00040000,
    WS_GROUP =            0x00020000,
    WS_TABSTOP =          0x00010000,

    WS_MINIMIZEBOX =      0x00020000,
    WS_MAXIMIZEBOX =      0x00010000,

    WS_TILED =            WS_OVERLAPPED,
    WS_ICONIC =           WS_MINIMIZE,
    WS_SIZEBOX =          WS_THICKFRAME,

/*
 * Common Window Styles
 */
    WS_OVERLAPPEDWINDOW = (WS_OVERLAPPED |            WS_CAPTION |  WS_SYSMENU |  WS_THICKFRAME |            WS_MINIMIZEBOX |                 WS_MAXIMIZEBOX),
    WS_TILEDWINDOW =      WS_OVERLAPPEDWINDOW,
    WS_POPUPWINDOW =      (WS_POPUP |  WS_BORDER |  WS_SYSMENU),
    WS_CHILDWINDOW =      (WS_CHILD),
}

/*
 * Class styles
 */
enum
{
    CS_VREDRAW =          0x0001,
    CS_HREDRAW =          0x0002,
    CS_KEYCVTWINDOW =     0x0004,
    CS_DBLCLKS =          0x0008,
    CS_OWNDC =            0x0020,
    CS_CLASSDC =          0x0040,
    CS_PARENTDC =         0x0080,
    CS_NOKEYCVT =         0x0100,
    CS_NOCLOSE =          0x0200,
    CS_SAVEBITS =         0x0800,
    CS_BYTEALIGNCLIENT =  0x1000,
    CS_BYTEALIGNWINDOW =  0x2000,
    CS_GLOBALCLASS =      0x4000,


    CS_IME =              0x00010000,
}

extern (Windows)
{
 HICON LoadIconA(HINSTANCE hInstance, LPCSTR lpIconName);
 HICON LoadIconW(HINSTANCE hInstance, LPCWSTR lpIconName);
 HCURSOR LoadCursorA(HINSTANCE hInstance, LPCSTR lpCursorName);
 HCURSOR LoadCursorW(HINSTANCE hInstance, LPCWSTR lpCursorName);
}



const LPSTR IDI_APPLICATION =     cast(LPSTR)(32512);

const LPSTR IDC_ARROW =           cast(LPSTR)(32512);
const LPSTR IDC_CROSS =           cast(LPSTR)(32515);



/*
 * Color Types
 */

const CTLCOLOR_MSGBOX =         0;
const CTLCOLOR_EDIT =           1;
const CTLCOLOR_LISTBOX =        2;
const CTLCOLOR_BTN =            3;
const CTLCOLOR_DLG =            4;
const CTLCOLOR_SCROLLBAR =      5;
const CTLCOLOR_STATIC =         6;
const CTLCOLOR_MAX =            7;

const COLOR_SCROLLBAR =         0;
const COLOR_BACKGROUND =        1;
const COLOR_ACTIVECAPTION =     2;
const COLOR_INACTIVECAPTION =   3;
const COLOR_MENU =              4;
const COLOR_WINDOW =            5;
const COLOR_WINDOWFRAME =       6;
const COLOR_MENUTEXT =          7;
const COLOR_WINDOWTEXT =        8;
const COLOR_CAPTIONTEXT =       9;
const COLOR_ACTIVEBORDER =      10;
const COLOR_INACTIVEBORDER =    11;
const COLOR_APPWORKSPACE =      12;
const COLOR_HIGHLIGHT =         13;
const COLOR_HIGHLIGHTTEXT =     14;
const COLOR_BTNFACE =           15;
const COLOR_BTNSHADOW =         16;
const COLOR_GRAYTEXT =          17;
const COLOR_BTNTEXT =           18;
const COLOR_INACTIVECAPTIONTEXT = 19;
const COLOR_BTNHIGHLIGHT =      20;


const COLOR_3DDKSHADOW =        21;
const COLOR_3DLIGHT =           22;
const COLOR_INFOTEXT =          23;
const COLOR_INFOBK =            24;

const COLOR_DESKTOP =       COLOR_BACKGROUND;
const COLOR_3DFACE =            COLOR_BTNFACE;
const COLOR_3DSHADOW =          COLOR_BTNSHADOW;
const COLOR_3DHIGHLIGHT =       COLOR_BTNHIGHLIGHT;
const COLOR_3DHILIGHT =         COLOR_BTNHIGHLIGHT;
const COLOR_BTNHILIGHT =        COLOR_BTNHIGHLIGHT;


enum : int
{
    CW_USEDEFAULT = cast(int)0x80000000
}

/*
 * Special value for CreateWindow, et al.
 */
const HWND  HWND_DESKTOP = cast(HWND)0;

extern (Windows) ATOM RegisterClassA(WNDCLASSA *lpWndClass);

extern (Windows) HWND CreateWindowExA(
    DWORD dwExStyle,
    LPCSTR lpClassName,
    LPCSTR lpWindowName,
    DWORD dwStyle,
    int X,
    int Y,
    int nWidth,
    int nHeight,
    HWND hWndParent ,
    HMENU hMenu,
    HINSTANCE hInstance,
    LPVOID lpParam);


HWND CreateWindowA(
    LPCSTR lpClassName,
    LPCSTR lpWindowName,
    DWORD dwStyle,
    int X,
    int Y,
    int nWidth,
    int nHeight,
    HWND hWndParent ,
    HMENU hMenu,
    HINSTANCE hInstance,
    LPVOID lpParam)
{
    return CreateWindowExA(0, lpClassName, lpWindowName, dwStyle, X, Y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam);
}


extern (Windows)
{
 BOOL GetMessageA(LPMSG lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax);
 BOOL TranslateMessage(MSG *lpMsg);
 LONG DispatchMessageA(MSG *lpMsg);
 BOOL PeekMessageA(MSG *lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax, UINT wRemoveMsg);
 HWND GetFocus();
}

extern (Windows) DWORD ExpandEnvironmentStringsA(LPCSTR lpSrc, LPSTR lpDst, DWORD nSize);

extern (Windows)
{
 BOOL IsValidCodePage(UINT CodePage);
 UINT GetACP();
 UINT GetOEMCP();
 //BOOL GetCPInfo(UINT CodePage, LPCPINFO lpCPInfo);
 BOOL IsDBCSLeadByte(BYTE TestChar);
 BOOL IsDBCSLeadByteEx(UINT CodePage, BYTE TestChar);
 int MultiByteToWideChar(UINT CodePage, DWORD dwFlags, LPCSTR lpMultiByteStr, int cchMultiByte, LPWSTR lpWideCharStr, int cchWideChar);
 int WideCharToMultiByte(UINT CodePage, DWORD dwFlags, LPCWSTR lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cchMultiByte, LPCSTR lpDefaultChar, LPBOOL lpUsedDefaultChar);
}

extern (Windows) BOOL GetMailslotInfo(HANDLE hMailslot, LPDWORD lpMaxMessageSize, LPDWORD lpNextSize, LPDWORD lpMessageCount, LPDWORD lpReadTimeout);
extern (Windows) BOOL SetMailslotInfo(HANDLE hMailslot, DWORD lReadTimeout);
extern (Windows) LPVOID MapViewOfFile(HANDLE hFileMappingObject, DWORD dwDesiredAccess, DWORD dwFileOffsetHigh, DWORD dwFileOffsetLow, DWORD dwNumberOfBytesToMap);
extern (Windows) LPVOID MapViewOfFileEx(HANDLE hFileMappingObject, DWORD dwDesiredAccess, DWORD dwFileOffsetHigh, DWORD dwFileOffsetLow, DWORD dwNumberOfBytesToMap, LPVOID lpBaseAddress);
extern (Windows) BOOL FlushViewOfFile(LPCVOID lpBaseAddress, DWORD dwNumberOfBytesToFlush);
extern (Windows) BOOL UnmapViewOfFile(LPCVOID lpBaseAddress);

extern (Windows)  HGDIOBJ   GetStockObject(int);
extern (Windows) BOOL ShowWindow(HWND hWnd, int nCmdShow);

/* Stock Logical Objects */
enum
{   WHITE_BRUSH =         0,
    LTGRAY_BRUSH =        1,
    GRAY_BRUSH =          2,
    DKGRAY_BRUSH =        3,
    BLACK_BRUSH =         4,
    NULL_BRUSH =          5,
    HOLLOW_BRUSH =        NULL_BRUSH,
    WHITE_PEN =           6,
    BLACK_PEN =           7,
    NULL_PEN =            8,
    OEM_FIXED_FONT =      10,
    ANSI_FIXED_FONT =     11,
    ANSI_VAR_FONT =       12,
    SYSTEM_FONT =         13,
    DEVICE_DEFAULT_FONT = 14,
    DEFAULT_PALETTE =     15,
    SYSTEM_FIXED_FONT =   16,
    DEFAULT_GUI_FONT =    17,
    STOCK_LAST =          17,
}

/*
 * ShowWindow() Commands
 */
enum
{   SW_HIDE =             0,
    SW_SHOWNORMAL =       1,
    SW_NORMAL =           1,
    SW_SHOWMINIMIZED =    2,
    SW_SHOWMAXIMIZED =    3,
    SW_MAXIMIZE =         3,
    SW_SHOWNOACTIVATE =   4,
    SW_SHOW =             5,
    SW_MINIMIZE =         6,
    SW_SHOWMINNOACTIVE =  7,
    SW_SHOWNA =           8,
    SW_RESTORE =          9,
    SW_SHOWDEFAULT =      10,
    SW_MAX =              10,
}


extern (Windows)  BOOL   GetTextMetricsA(HDC, TEXTMETRICA*);

/*
 * Scroll Bar Constants
 */
enum
{   SB_HORZ =             0,
    SB_VERT =             1,
    SB_CTL =              2,
    SB_BOTH =             3,
}

/*
 * Scroll Bar Commands
 */
enum
{   SB_LINEUP =           0,
    SB_LINELEFT =         0,
    SB_LINEDOWN =         1,
    SB_LINERIGHT =        1,
    SB_PAGEUP =           2,
    SB_PAGELEFT =         2,
    SB_PAGEDOWN =         3,
    SB_PAGERIGHT =        3,
    SB_THUMBPOSITION =    4,
    SB_THUMBTRACK =       5,
    SB_TOP =              6,
    SB_LEFT =             6,
    SB_BOTTOM =           7,
    SB_RIGHT =            7,
    SB_ENDSCROLL =        8,
}

extern (Windows) int SetScrollPos(HWND hWnd, int nBar, int nPos, BOOL bRedraw);
extern (Windows) int GetScrollPos(HWND hWnd, int nBar);
extern (Windows) BOOL SetScrollRange(HWND hWnd, int nBar, int nMinPos, int nMaxPos, BOOL bRedraw);
extern (Windows) BOOL GetScrollRange(HWND hWnd, int nBar, LPINT lpMinPos, LPINT lpMaxPos);
extern (Windows) BOOL ShowScrollBar(HWND hWnd, int wBar, BOOL bShow);
extern (Windows) BOOL EnableScrollBar(HWND hWnd, UINT wSBflags, UINT wArrows);

/*
 * LockWindowUpdate API
 */

extern (Windows) BOOL LockWindowUpdate(HWND hWndLock);
extern (Windows) BOOL ScrollWindow(HWND hWnd, int XAmount, int YAmount, RECT* lpRect, RECT* lpClipRect);
extern (Windows) BOOL ScrollDC(HDC hDC, int dx, int dy, RECT* lprcScroll, RECT* lprcClip, HRGN hrgnUpdate, LPRECT lprcUpdate);
extern (Windows) int ScrollWindowEx(HWND hWnd, int dx, int dy, RECT* prcScroll, RECT* prcClip, HRGN hrgnUpdate, LPRECT prcUpdate, UINT flags);

/*
 * Virtual Keys, Standard Set
 */
enum
{   VK_LBUTTON =        0x01,
    VK_RBUTTON =        0x02,
    VK_CANCEL =         0x03,
    VK_MBUTTON =        0x04, /* NOT contiguous with L & RBUTTON */

    VK_BACK =           0x08,
    VK_TAB =            0x09,

    VK_CLEAR =          0x0C,
    VK_RETURN =         0x0D,

    VK_ШИФТ =          0x10,
    VK_CONTROL =        0x11,
    VK_MENU =           0x12,
    VK_PAUSE =          0x13,
    VK_CAPITAL =        0x14,


    VK_ESCAPE =         0x1B,

    VK_SPACE =          0x20,
    VK_PRIOR =          0x21,
    VK_NEXT =           0x22,
    VK_END =            0x23,
    VK_HOME =           0x24,
    VK_LEFT =           0x25,
    VK_UP =             0x26,
    VK_RIGHT =          0x27,
    VK_DOWN =           0x28,
    VK_SELECT =         0x29,
    VK_PRINT =          0x2A,
    VK_EXECUTE =        0x2B,
    VK_SNAPSHOT =       0x2C,
    VK_INSERT =         0x2D,
    VK_DELETE =         0x2E,
    VK_HELP =           0x2F,

/* VK_0 thru VK_9 are the same as ASCII '0' thru '9' (0x30 - 0x39) */
/* VK_A thru VK_Z are the same as ASCII 'A' thru 'Z' (0x41 - 0x5A) */

    VK_LWIN =           0x5B,
    VK_RWIN =           0x5C,
    VK_APPS =           0x5D,

    VK_NUMPAD0 =        0x60,
    VK_NUMPAD1 =        0x61,
    VK_NUMPAD2 =        0x62,
    VK_NUMPAD3 =        0x63,
    VK_NUMPAD4 =        0x64,
    VK_NUMPAD5 =        0x65,
    VK_NUMPAD6 =        0x66,
    VK_NUMPAD7 =        0x67,
    VK_NUMPAD8 =        0x68,
    VK_NUMPAD9 =        0x69,
    VK_MULTIPLY =       0x6A,
    VK_ADD =            0x6B,
    VK_SEPARATOR =      0x6C,
    VK_SUBTRACT =       0x6D,
    VK_DECIMAL =        0x6E,
    VK_DIVIDE =         0x6F,
    VK_F1 =             0x70,
    VK_F2 =             0x71,
    VK_F3 =             0x72,
    VK_F4 =             0x73,
    VK_F5 =             0x74,
    VK_F6 =             0x75,
    VK_F7 =             0x76,
    VK_F8 =             0x77,
    VK_F9 =             0x78,
    VK_F10 =            0x79,
    VK_F11 =            0x7A,
    VK_F12 =            0x7B,
    VK_F13 =            0x7C,
    VK_F14 =            0x7D,
    VK_F15 =            0x7E,
    VK_F16 =            0x7F,
    VK_F17 =            0x80,
    VK_F18 =            0x81,
    VK_F19 =            0x82,
    VK_F20 =            0x83,
    VK_F21 =            0x84,
    VK_F22 =            0x85,
    VK_F23 =            0x86,
    VK_F24 =            0x87,

    VK_NUMLOCK =        0x90,
    VK_SCROLL =         0x91,

/*
 * VK_L* & VK_R* - left and right Alt, Ctrl and Shift virtual keys.
 * Used only as parameters to GetAsyncKeyState() and GetKeyState().
 * No other API or message will distinguish left and right keys in this way.
 */
    VK_LШИФТ =         0xA0,
    VK_RШИФТ =         0xA1,
    VK_LCONTROL =       0xA2,
    VK_RCONTROL =       0xA3,
    VK_LMENU =          0xA4,
    VK_RMENU =          0xA5,


    VK_PROCESSKEY =     0xE5,


    VK_ATTN =           0xF6,
    VK_CRSEL =          0xF7,
    VK_EXSEL =          0xF8,
    VK_EREOF =          0xF9,
    VK_PLAY =           0xFA,
    VK_ZOOM =           0xFB,
    VK_NONAME =         0xFC,
    VK_PA1 =            0xFD,
    VK_OEM_CLEAR =      0xFE,
}

extern (Windows) LRESULT SendMessageA(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);

BOOL          GetOpenFileNameA(LPOPENFILENAMEA);
BOOL          GetOpenFileNameW(LPOPENFILENAMEW);

BOOL          GetSaveFileNameA(LPOPENFILENAMEA);
BOOL          GetSaveFileNameW(LPOPENFILENAMEW);

short         GetFileTitleA(LPCSTR, LPSTR, WORD);
short         GetFileTitleW(LPCWSTR, LPWSTR, WORD);

enum
{
    PM_NOREMOVE =         0x0000,
    PM_REMOVE =           0x0001,
    PM_NOYIELD =          0x0002,
}

extern (Windows)  HANDLE CreateConsoleScreenBuffer(
DWORD dwDesiredAccess,
   DWORD dwShareMode,
SECURITY_ATTRIBUTES* lpSecurityAttributes,
DWORD dwFlags,
LPVOID lpScreenBufferData
);

extern (Windows)  HDC       CreateCompatibleDC(HDC);

extern (Windows)  int     GetObjectA(HGDIOBJ, int, LPVOID);
extern (Windows)  int     GetObjectW(HGDIOBJ, int, LPVOID);
extern (Windows)  BOOL   DeleteDC(HDC);

extern (Windows) HMENU LoadMenuA(HINSTANCE hInstance, LPCSTR lpMenuName);
extern (Windows) HMENU LoadMenuW(HINSTANCE hInstance, LPCWSTR lpMenuName);

extern (Windows) HMENU GetSubMenu(HMENU hMenu, int nPos);

extern (Windows) HBITMAP LoadBitmapA(HINSTANCE hInstance, LPCSTR lpBitmapName);
extern (Windows) HBITMAP LoadBitmapW(HINSTANCE hInstance, LPCWSTR lpBitmapName);

LPSTR MAKEINTRESOURCEA(int i) { return cast(LPSTR)(cast(DWORD)(cast(WORD)(i))); }

extern (Windows)  HFONT     CreateFontIndirectA(LOGFONTA *);

extern (Windows) BOOL MessageBeep(UINT uType);
extern (Windows) int ShowCursor(BOOL bShow);
extern (Windows) BOOL SetCursorPos(int X, int Y);
extern (Windows) HCURSOR SetCursor(HCURSOR hCursor);
extern (Windows) BOOL GetCursorPos(LPPOINT lpPoint);
extern (Windows) BOOL ClipCursor( RECT *lpRect);
extern (Windows) BOOL GetClipCursor(LPRECT lpRect);
extern (Windows) HCURSOR GetCursor();
extern (Windows) BOOL CreateCaret(HWND hWnd, HBITMAP hBitmap , int nWidth, int nHeight);
extern (Windows) UINT GetCaretBlinkTime();
extern (Windows) BOOL SetCaretBlinkTime(UINT uMSeconds);
extern (Windows) BOOL DestroyCaret();
extern (Windows) BOOL HideCaret(HWND hWnd);
extern (Windows) BOOL ShowCaret(HWND hWnd);
extern (Windows) BOOL SetCaretPos(int X, int Y);
extern (Windows) BOOL GetCaretPos(LPPOINT lpPoint);
extern (Windows) BOOL ClientToScreen(HWND hWnd, LPPOINT lpPoint);
extern (Windows) BOOL ScreenToClient(HWND hWnd, LPPOINT lpPoint);
extern (Windows) int MapWindowPoints(HWND hWndFrom, HWND hWndTo, LPPOINT lpPoints, UINT cPoints);
extern (Windows) HWND WindowFromPoint(POINT Point);
extern (Windows) HWND ChildWindowFromPoint(HWND hWndParent, POINT Point);


extern (Windows) BOOL TrackPopupMenu(HMENU hMenu, UINT uFlags, int x, int y,
    int nReserved, HWND hWnd, RECT *prcRect);


extern (Windows) int DialogBoxParamA(HINSTANCE hInstance, LPCSTR lpTemplateName,
    HWND hWndParent, DLGPROC lpDialogFunc, LPARAM dwInitParam);
extern (Windows) int DialogBoxIndirectParamA(HINSTANCE hInstance,
    LPCDLGTEMPLATEA hDialogTemplate, HWND hWndParent, DLGPROC lpDialogFunc,
    LPARAM dwInitParam);

enum : DWORD
{
    SRCCOPY =             cast(DWORD)0x00CC0020, /* dest = source                   */
    SRCPAINT =            cast(DWORD)0x00EE0086, /* dest = source OR dest           */
    SRCAND =              cast(DWORD)0x008800C6, /* dest = source AND dest          */
    SRCINVERT =           cast(DWORD)0x00660046, /* dest = source XOR dest          */
    SRCERASE =            cast(DWORD)0x00440328, /* dest = source AND (NOT dest)   */
    NOTSRCCOPY =          cast(DWORD)0x00330008, /* dest = (NOT source)             */
    NOTSRCERASE =         cast(DWORD)0x001100A6, /* dest = (NOT src) AND (NOT dest) */
    MERGECOPY =           cast(DWORD)0x00C000CA, /* dest = (source AND pattern)     */
    MERGEPAINT =          cast(DWORD)0x00BB0226, /* dest = (NOT source) OR dest     */
    PATCOPY =             cast(DWORD)0x00F00021, /* dest = pattern                  */
    PATPAINT =            cast(DWORD)0x00FB0A09, /* dest = DPSnoo                   */
    PATINVERT =           cast(DWORD)0x005A0049, /* dest = pattern XOR dest         */
    DSTINVERT =           cast(DWORD)0x00550009, /* dest = (NOT dest)               */
    BLACKNESS =           cast(DWORD)0x00000042, /* dest = BLACK                    */
    WHITENESS =           cast(DWORD)0x00FF0062, /* dest = WHITE                    */
}

enum
{
    SND_SYNC =            0x0000, /* play synchronously (default) */
    SND_ASYNC =           0x0001, /* play asynchronously */
    SND_NODEFAULT =       0x0002, /* silence (!default) if sound not found */
    SND_MEMORY =          0x0004, /* pszSound points to a memory file */
    SND_LOOP =            0x0008, /* loop the sound until next sndPlaySound */
    SND_NOSTOP =          0x0010, /* don't stop any currently playing sound */

    SND_NOWAIT =    0x00002000, /* don't wait if the driver is busy */
    SND_ALIAS =       0x00010000, /* name is a registry alias */
    SND_ALIAS_ID =  0x00110000, /* alias is a predefined ID */
    SND_FILENAME =    0x00020000, /* name is file name */
    SND_RESOURCE =    0x00040004, /* name is resource name or atom */

    SND_PURGE =           0x0040, /* purge non-static events for task */
    SND_APPLICATION =     0x0080, /* look for application specific association */


    SND_ALIAS_START =   0,     /* alias base */
}

extern (Windows)  BOOL   PlaySoundA(LPCSTR pszSound, HMODULE hmod, DWORD fdwSound);
extern (Windows)  BOOL   PlaySoundW(LPCWSTR pszSound, HMODULE hmod, DWORD fdwSound);

extern (Windows)  int     GetClipBox(HDC, LPRECT);
extern (Windows)  int     GetClipRgn(HDC, HRGN);
extern (Windows)  int     GetMetaRgn(HDC, HRGN);
extern (Windows)  HGDIOBJ   GetCurrentObject(HDC, UINT);
extern (Windows)  BOOL    GetCurrentPositionEx(HDC, LPPOINT);
extern (Windows)  int     GetDeviceCaps(HDC, int);

enum
{
    PS_SOLID =            0,
    PS_DASH =             1, /* -------  */
    PS_DOT =              2, /* .......  */
    PS_DASHDOT =          3, /* _._._._  */
    PS_DASHDOTDOT =       4, /* _.._.._  */
    PS_NULL =             5,
    PS_INSIDEFRAME =      6,
    PS_USERSTYLE =        7,
    PS_ALTERNATE =        8,
    PS_STYLE_MASK =       0x0000000F,

    PS_ENDCAP_ROUND =     0x00000000,
    PS_ENDCAP_SQUARE =    0x00000100,
    PS_ENDCAP_FLAT =      0x00000200,
    PS_ENDCAP_MASK =      0x00000F00,

    PS_JOIN_ROUND =       0x00000000,
    PS_JOIN_BEVEL =       0x00001000,
    PS_JOIN_MITER =       0x00002000,
    PS_JOIN_MASK =        0x0000F000,

    PS_COSMETIC =         0x00000000,
    PS_GEOMETRIC =        0x00010000,
    PS_TYPE_MASK =        0x000F0000,
}

extern (Windows)  HPALETTE   CreatePalette(LOGPALETTE *);
extern (Windows)  HPEN      CreatePen(int, int, COLORREF);
extern (Windows)  HPEN      CreatePenIndirect(LOGPEN *);
extern (Windows)  HRGN      CreatePolyPolygonRgn(POINT *, INT *, int, int);
extern (Windows)  HBRUSH    CreatePatternBrush(HBITMAP);
extern (Windows)  HRGN      CreateRectRgn(int, int, int, int);
extern (Windows)  HRGN      CreateRectRgnIndirect(RECT *);
extern (Windows)  HRGN      CreateRoundRectRgn(int, int, int, int, int, int);
extern (Windows)  BOOL      CreateScalableFontResourceA(DWORD, LPCSTR, LPCSTR, LPCSTR);
extern (Windows)  BOOL      CreateScalableFontResourceW(DWORD, LPCWSTR, LPCWSTR, LPCWSTR);

COLORREF RGB(int r, int g, int b)
{
    return cast(COLORREF)
    ((cast(BYTE)r|(cast(WORD)(cast(BYTE)g)<<8))|((cast(DWORD)cast(BYTE)b)<<16));
}

extern (Windows)  BOOL   LineTo(HDC, int, int);
extern (Windows)  BOOL   DeleteObject(HGDIOBJ);
extern (Windows) int FillRect(HDC hDC,  RECT *lprc, HBRUSH hbr);


extern (Windows) BOOL EndDialog(HWND hDlg, int nResult);
extern (Windows) HWND GetDlgItem(HWND hDlg, int nIDDlgItem);

extern (Windows) BOOL SetDlgItemInt(HWND hDlg, int nIDDlgItem, UINT uValue, BOOL bSigned);
extern (Windows) UINT GetDlgItemInt(HWND hDlg, int nIDDlgItem, BOOL *lpTranslated,
    BOOL bSigned);

extern (Windows) BOOL SetDlgItemTextA(HWND hDlg, int nIDDlgItem, LPCSTR lpString);
extern (Windows) BOOL SetDlgItemTextW(HWND hDlg, int nIDDlgItem, LPCWSTR lpString);

extern (Windows) UINT GetDlgItemTextA(HWND hDlg, int nIDDlgItem, LPSTR lpString, int nMaxCount);
extern (Windows) UINT GetDlgItemTextW(HWND hDlg, int nIDDlgItem, LPWSTR lpString, int nMaxCount);

extern (Windows) BOOL CheckDlgButton(HWND hDlg, int nIDButton, UINT uCheck);
extern (Windows) BOOL CheckRadioButton(HWND hDlg, int nIDFirstButton, int nIDLastButton,
    int nIDCheckButton);

extern (Windows) UINT IsDlgButtonChecked(HWND hDlg, int nIDButton);

extern (Windows) HWND SetFocus(HWND hWnd);

extern (Windows) int wsprintfA(LPSTR, LPCSTR, ...);
extern (Windows) int wsprintfW(LPWSTR, LPCWSTR, ...);

enum : uint
{
    INFINITE =              uint.max,
    WAIT_OBJECT_0 =         0,
    WAIT_ABANDONED_0 =      0x80,
    WAIT_TIMEOUT =          0x102,
    WAIT_IO_COMPLETION =    0xc0,
    WAIT_ABANDONED =        0x80,
    WAIT_FAILED =           uint.max,
}

extern (Windows) HANDLE OpenSemaphoreA(DWORD dwDesiredAccess, BOOL bInheritHandle, LPCTSTR lpName);
extern (Windows) BOOL ReleaseSemaphore(HANDLE hSemaphore, LONG lReleaseCount, LPLONG lpPreviousCount);

enum
{
    RIGHT_ALT_PRESSED =     0x0001, // the right alt key is pressed.
    LEFT_ALT_PRESSED =      0x0002, // the left alt key is pressed.
    RIGHT_CTRL_PRESSED =    0x0004, // the right ctrl key is pressed.
    LEFT_CTRL_PRESSED =     0x0008, // the left ctrl key is pressed.
    ШИФТ_PRESSED =         0x0010, // the shift key is pressed.
    NUMLOCK_ON =            0x0020, // the numlock light is on.
    SCROLLLOCK_ON =         0x0040, // the scrolllock light is on.
    CAPSLOCK_ON =           0x0080, // the capslock light is on.
    ENHANCED_KEY =          0x0100, // the key is enhanced.
}

//
// ButtonState flags
//
enum
{
    FROM_LEFT_1ST_BUTTON_PRESSED =    0x0001,
    RIGHTMOST_BUTTON_PRESSED =        0x0002,
    FROM_LEFT_2ND_BUTTON_PRESSED =    0x0004,
    FROM_LEFT_3RD_BUTTON_PRESSED =    0x0008,
    FROM_LEFT_4TH_BUTTON_PRESSED =    0x0010,
}

//
// EventFlags
//

enum
{
    MOUSE_MOVED =   0x0001,
    DOUBLE_CLICK =  0x0002,
}


//
//  EventType flags:
//

enum
{
    KEY_EVENT =         0x0001, // Event contains key event record
    MOUSE_EVENT =       0x0002, // Event contains mouse event record
    WINDOW_BUFFER_SIZE_EVENT = 0x0004, // Event contains window change event record
    MENU_EVENT = 0x0008, // Event contains menu event record
    FOCUS_EVENT = 0x0010, // event contains focus change
}


//
// Attributes flags:
//

enum
{
    FOREGROUND_BLUE =      0x0001, // text color contains blue.
    FOREGROUND_GREEN =     0x0002, // text color contains green.
    FOREGROUND_RED =       0x0004, // text color contains red.
    FOREGROUND_INTENSITY = 0x0008, // text color is intensified.
    BACKGROUND_BLUE =      0x0010, // background color contains blue.
    BACKGROUND_GREEN =     0x0020, // background color contains green.
    BACKGROUND_RED =       0x0040, // background color contains red.
    BACKGROUND_INTENSITY = 0x0080, // background color is intensified.
}


enum
{
    ENABLE_PROCESSED_INPUT = 0x0001,
    ENABLE_LINE_INPUT =      0x0002,
    ENABLE_ECHO_INPUT =      0x0004,
    ENABLE_WINDOW_INPUT =    0x0008,
    ENABLE_MOUSE_INPUT =     0x0010,
}

enum
{
    ENABLE_PROCESSED_OUTPUT =    0x0001,
    ENABLE_WRAP_AT_EOL_OUTPUT =  0x0002,
}

BOOL PeekConsoleInputA(HANDLE hConsoleInput, PINPUT_RECORD буф, DWORD длина, LPDWORD lpNumberOfEventsRead);
BOOL PeekConsoleInputW(HANDLE hConsoleInput, PINPUT_RECORD буф, DWORD длина, LPDWORD lpNumberOfEventsRead);
BOOL ReadConsoleInputA(HANDLE hConsoleInput, PINPUT_RECORD буф, DWORD длина, LPDWORD lpNumberOfEventsRead);
BOOL ReadConsoleInputW(HANDLE hConsoleInput, PINPUT_RECORD буф, DWORD длина, LPDWORD lpNumberOfEventsRead);
BOOL WriteConsoleInputA(HANDLE hConsoleInput, in INPUT_RECORD *буф, DWORD длина, LPDWORD lpNumberOfEventsWritten);
BOOL WriteConsoleInputW(HANDLE hConsoleInput, in INPUT_RECORD *буф, DWORD длина, LPDWORD lpNumberOfEventsWritten);
BOOL ReadConsoleOutputA(HANDLE КОНСВЫВОД, PCHAR_INFO буф, COORD буфРазм, COORD буфКоорд, PSMALL_RECT регЧтен);
BOOL ReadConsoleOutputW(HANDLE КОНСВЫВОД, PCHAR_INFO буф, COORD буфРазм, COORD буфКоорд, PSMALL_RECT регЧтен);
BOOL WriteConsoleOutputA(HANDLE КОНСВЫВОД, in CHAR_INFO *буф, COORD буфРазм, COORD буфКоорд, PSMALL_RECT регЗап);
BOOL WriteConsoleOutputW(HANDLE КОНСВЫВОД, in CHAR_INFO *буф, COORD буфРазм, COORD буфКоорд, PSMALL_RECT регЗап);
BOOL ReadConsoleOutputCharacterA(HANDLE КОНСВЫВОД, LPSTR симв, DWORD длина, COORD коордЧтен, LPDWORD члоСчитСим);
BOOL ReadConsoleOutputCharacterW(HANDLE КОНСВЫВОД, LPWSTR симв, DWORD длина, COORD коордЧтен, LPDWORD члоСчитСим);
BOOL ReadConsoleOutputAttributecast(HANDLE  hConsoleOutput,  LPWORD  lpAttribute, DWORD nLength, COORD dwReadCoord, LPDWORD lpNumberOfAttrsRead);
BOOL WriteConsoleOutputCharacterAcast(HANDLE hConsoleOutput, LPCSTR lpCharacter, DWORD nLength, COORD dwWriteCoord, LPDWORD члоЗаписанАтров);
BOOL ReadConsoleOutputAttribute(HANDLE КОНСВЫВОД, LPWORD атр, DWORD длина, COORD коордЧтен, LPDWORD члоСчитАтров);
BOOL WriteConsoleOutputCharacterA(HANDLE КОНСВЫВОД, LPCSTR симв, DWORD длина, COORD коордЗап, LPDWORD члоЗаписанАтров);
BOOL WriteConsoleOutputCharacterW(HANDLE КОНСВЫВОД, LPCWSTR симв, DWORD длина, COORD коордЗап, LPDWORD члоЗаписанАтров);
BOOL WriteConsoleOutputAttribute(HANDLE КОНСВЫВОД, in WORD *атр, DWORD длина, COORD коордЗап, LPDWORD lpNumberOfAttrsWritten);
BOOL FillConsoleOutputCharacterA(HANDLE КОНСВЫВОД, CHAR cCharacter, DWORD  длина, COORD  коордЗап, LPDWORD члоЗаписанАтров);
BOOL FillConsoleOutputCharacterW(HANDLE КОНСВЫВОД, WCHAR cCharacter, DWORD  длина, COORD  коордЗап, LPDWORD члоЗаписанАтров);
BOOL FillConsoleOutputAttribute(HANDLE КОНСВЫВОД, WORD   wAttribute, DWORD  длина, COORD  коордЗап, LPDWORD lpNumberOfAttrsWritten);
BOOL GetConsoleMode(HANDLE hConsoleHandle, LPDWORD lpMode);
BOOL GetNumberOfConsoleInputEvents(HANDLE hConsoleInput, LPDWORD lpNumberOfEvents);
BOOL GetConsoleScreenBufferInfo(HANDLE КОНСВЫВОД, PCONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo);
COORD GetLargestConsoleWindowSize( HANDLE КОНСВЫВОД);
BOOL GetConsoleCursorInfo(HANDLE КОНСВЫВОД, PCONSOLE_CURSOR_INFO lpConsoleCursorInfo);
BOOL GetNumberOfConsoleMouseButtons( LPDWORD lpNumberOfMouseButtons);
BOOL SetConsoleMode(HANDLE hConsoleHandle, DWORD dwMode);
BOOL SetConsoleActiveScreenBuffer(HANDLE КОНСВЫВОД);
BOOL FlushConsoleInputBuffer(HANDLE hConsoleInput);
BOOL SetConsoleScreenBufferSize(HANDLE КОНСВЫВОД, COORD dwSize);
BOOL WriteConsoleOutputAcast(HANDLE  hConsoleOutput, in PCHAR_INFO lpBuffer, COORD  dwBufferSize, COORD  dwBufferCoord, PSMALL_RECT  lpWriteRegion);
BOOL WriteConsoleOutputWcast(HANDLE hConsoleOutput, in PCHAR_INFO lpBuffer, COORD dwBufferSize, COORD  dwBufferCoord, PSMALL_RECT lpWriteRegion);
BOOL SetConsoleCursorPosition(HANDLE КОНСВЫВОД, COORD dwCursorPosition);
BOOL SetConsoleCursorInfo(HANDLE КОНСВЫВОД, in CONSOLE_CURSOR_INFO *lpConsoleCursorInfo);
BOOL ScrollConsoleScreenBufferA(HANDLE КОНСВЫВОД, in SMALL_RECT *lpScrollRectangle, in SMALL_RECT *lpClipRectangle, COORD dwDestinationOrigin, in CHAR_INFO *lpFill);
BOOL ScrollConsoleScreenBufferW(HANDLE КОНСВЫВОД, in SMALL_RECT *lpScrollRectangle, in SMALL_RECT *lpClipRectangle, COORD dwDestinationOrigin, in CHAR_INFO *lpFill);
BOOL SetConsoleWindowInfo(HANDLE КОНСВЫВОД, BOOL bAbsolute, in SMALL_RECT *lpConsoleWindow);
BOOL SetConsoleTextAttribute(HANDLE КОНСВЫВОД, WORD wAttributes);
alias BOOL function(DWORD CtrlType) PHANDLER_ROUTINE;
BOOL SetConsoleCtrlHandler(PHANDLER_ROUTINE HandlerRoutine, BOOL Add);
BOOL GenerateConsoleCtrlEvent( DWORD dwCtrlEvent, DWORD dwProcessGroupId);
BOOL FreeConsole();
DWORD GetConsoleTitleA(LPSTR lpConsoleTitle, DWORD nSize);
DWORD GetConsoleTitleW(LPWSTR lpConsoleTitle, DWORD nSize);
BOOL SetConsoleTitleA(LPCSTR lpConsoleTitle);
BOOL SetConsoleTitleW(LPCWSTR lpConsoleTitle);
BOOL ReadConsoleA(HANDLE hConsoleInput, LPVOID буф, DWORD nNumberOfCharsToRead, LPDWORD члоСчитСим, LPVOID lpReserved);
BOOL ReadConsoleW(HANDLE hConsoleInput, LPVOID буф, DWORD nNumberOfCharsToRead, LPDWORD члоСчитСим, LPVOID lpReserved);
BOOL WriteConsoleA(HANDLE КОНСВЫВОД, in  void *буф, DWORD nNumberOfCharsToWrite, LPDWORD члоЗаписанАтров, LPVOID lpReserved);
BOOL WriteConsoleW(HANDLE КОНСВЫВОД, in  void *буф, DWORD nNumberOfCharsToWrite, LPDWORD члоЗаписанАтров, LPVOID lpReserved);
UINT GetConsoleCP();
BOOL SetConsoleCP( UINT wCodePageID);
UINT GetConsoleOutputCP();
BOOL SetConsoleOutputCP(UINT wCodePageID);

enum
{
    CONSOLE_TEXTMODE_BUFFER = 1,
}

enum
{
    SM_CXSCREEN =             0,
    SM_CYSCREEN =             1,
    SM_CXVSCROLL =            2,
    SM_CYHSCROLL =            3,
    SM_CYCAPTION =            4,
    SM_CXBORDER =             5,
    SM_CYBORDER =             6,
    SM_CXDLGFRAME =           7,
    SM_CYDLGFRAME =           8,
    SM_CYVTHUMB =             9,
    SM_CXHTHUMB =             10,
    SM_CXICON =               11,
    SM_CYICON =               12,
    SM_CXCURSOR =             13,
    SM_CYCURSOR =             14,
    SM_CYMENU =               15,
    SM_CXFULLSCREEN =         16,
    SM_CYFULLSCREEN =         17,
    SM_CYKANJIWINDOW =        18,
    SM_MOUSEPRESENT =         19,
    SM_CYVSCROLL =            20,
    SM_CXHSCROLL =            21,
    SM_DEBUG =                22,
    SM_SWAPBUTTON =           23,
    SM_RESERVED1 =            24,
    SM_RESERVED2 =            25,
    SM_RESERVED3 =            26,
    SM_RESERVED4 =            27,
    SM_CXMIN =                28,
    SM_CYMIN =                29,
    SM_CXSIZE =               30,
    SM_CYSIZE =               31,
    SM_CXFRAME =              32,
    SM_CYFRAME =              33,
    SM_CXMINTRACK =           34,
    SM_CYMINTRACK =           35,
    SM_CXDOUBLECLK =          36,
    SM_CYDOUBLECLK =          37,
    SM_CXICONSPACING =        38,
    SM_CYICONSPACING =        39,
    SM_MENUDROPALIGNMENT =    40,
    SM_PENWINDOWS =           41,
    SM_DBCSENABLED =          42,
    SM_CMOUSEBUTTONS =        43,


    SM_CXFIXEDFRAME =         SM_CXDLGFRAME,
    SM_CYFIXEDFRAME =         SM_CYDLGFRAME,
    SM_CXSIZEFRAME =          SM_CXFRAME,
    SM_CYSIZEFRAME =          SM_CYFRAME,

    SM_SECURE =               44,
    SM_CXEDGE =               45,
    SM_CYEDGE =               46,
    SM_CXMINSPACING =         47,
    SM_CYMINSPACING =         48,
    SM_CXSMICON =             49,
    SM_CYSMICON =             50,
    SM_CYSMCAPTION =          51,
    SM_CXSMSIZE =             52,
    SM_CYSMSIZE =             53,
    SM_CXMENUSIZE =           54,
    SM_CYMENUSIZE =           55,
    SM_ARRANGE =              56,
    SM_CXMINIMIZED =          57,
    SM_CYMINIMIZED =          58,
    SM_CXMAXTRACK =           59,
    SM_CYMAXTRACK =           60,
    SM_CXMAXIMIZED =          61,
    SM_CYMAXIMIZED =          62,
    SM_NETWORK =              63,
    SM_CLEANBOOT =            67,
    SM_CXDRAG =               68,
    SM_CYDRAG =               69,
    SM_SHOWSOUNDS =           70,
    SM_CXMENUCHECK =          71,
    SM_CYMENUCHECK =          72,
    SM_SLOWMACHINE =          73,
    SM_MIDEASTENABLED =       74,
    SM_CMETRICS =             75,
}

int GetSystemMetrics(int nIndex);

enum : DWORD
{
    ЕЩЁ_АКТИВНА = (0x103),
}

DWORD TlsAlloc();
LPVOID TlsGetValue(DWORD);
BOOL TlsSetValue(DWORD, LPVOID);
BOOL TlsFree(DWORD);

}


//********************************************************//
/***************************************os.wyndows ************************************************/
extern(Windows)
{

	int WSAStartup(WORD wVersionRequested, LPWSADATA lpWSAData);
	int WSACleanup();
	SOCKET socket(int af, int type, int protocol);
	int ioctlsocket(SOCKET s, int cmd, uint* argp);
	int bind(SOCKET s, sockaddr* name, int namelen);
	int connect(SOCKET s, sockaddr* name, int namelen);
	int listen(SOCKET s, int backlog);
	SOCKET accept(SOCKET s, sockaddr* addr, int* addrlen);
	int closesocket(SOCKET s);
	int shutdown(SOCKET s, int how);
	int getpeername(SOCKET s, sockaddr* name, int* namelen);
	int getsockname(SOCKET s, sockaddr* name, int* namelen);
	int send(SOCKET s, void* buf, int len, int flags);
	int sendto(SOCKET s, void* buf, int len, int flags, sockaddr* to, int tolen);
	int recv(SOCKET s, void* buf, int len, int flags);
	int recvfrom(SOCKET s, void* buf, int len, int flags, sockaddr* from, int* fromlen);
	int getsockopt(SOCKET s, int level, int optname, void* optval, int* optlen);
	int setsockopt(SOCKET s, int level, int optname, void* optval, int optlen);
	uint inet_addr(char* cp);
	int select(int nfds, fd_set* readfds, fd_set* writefds, fd_set* errorfds, timeval* timeout);
	char* inet_ntoa(in_addr ina);
	hostent* gethostbyname(char* name);
	hostent* gethostbyaddr(void* addr, int len, int type);
	protoent* getprotobyname(char* name);
	protoent* getprotobynumber(int number);
	servent* getservbyname(char* name, char* proto);
	servent* getservbyport(int port, char* proto);
	int gethostname(char* name, int namelen);
	int getaddrinfo(char* nodename, char* servname, addrinfo* hints, addrinfo** res);
	void freeaddrinfo(addrinfo* ai);
	int getnameinfo(sockaddr* sa, socklen_t salen, char* host, DWORD hostlen, char* serv, DWORD servlen, int flags);

enum: int
{
	WSAEWOULDBLOCK =     10035,
	WSAEINTR =           10004,
	WSAHOST_NOT_FOUND =  11001,
}

int WSAGetLastError();


// Removes.
void FD_CLR(SOCKET fd, fd_set* set)
{
	uint c = set.fd_count;
	SOCKET* start = set.fd_array.ptr;
	SOCKET* stop = start + c;
	
	for(; start != stop; start++)
	{
		if(*start == fd)
			goto found;
	}
	return; //not found
	
	found:
	for(++start; start != stop; start++)
	{
		*(start - 1) = *start;
	}
	
	set.fd_count = c - 1;
}


// Tests.
int FD_ISSET(SOCKET fd, fd_set* set)
{
	SOCKET* start = set.fd_array.ptr;
	SOCKET* stop = start + set.fd_count;
	
	for(; start != stop; start++)
	{
		if(*start == fd)
			return true;
	}
	return false;
}


// Adds.
void FD_SET(SOCKET fd, fd_set* set)
{
	uint c = set.fd_count;
	set.fd_array.ptr[c] = fd;
	set.fd_count = c + 1;
}


// Resets to zero.
void FD_ZERO(fd_set* set)
{
	set.fd_count = 0;
}


/+
union in6_addr
{
	private union _u_t
	{
		BYTE[16] Byte;
		WORD[8] Word;
	}
	_u_t u;
}


struct in_addr6
{
	BYTE[16] s6_addr;
}
+/


version(BigEndian)
{
	uint16_t htons(uint16_t x)
	{
		return x;
	}
	
	
	uint32_t htonl(uint32_t x)
	{
		return x;
	}
}
else version(LittleEndian)
{
	private import std.intrinsic;
	
	
	uint16_t htons(uint16_t x)
	{
		return cast(uint16_t)((x >> 8) | (x << 8));
	}


	uint32_t htonl(uint32_t x)
	{
		return bswap(x);
	}
}
else
{
	static assert(0);
}


uint16_t ntohs(uint16_t x)
{
	return htons(x);
}


uint32_t ntohl(uint32_t x)
{
	return htonl(x);
}


const in6_addr IN6ADDR_ANY = { s6_addr8: [0] };
const in6_addr IN6ADDR_LOOPBACK = { s6_addr8: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1] };
//alias IN6ADDR_ANY IN6ADDR_ANY_INIT;
//alias IN6ADDR_LOOPBACK IN6ADDR_LOOPBACK_INIT;
	
const uint INET_ADDRSTRLEN = 16;
const uint INET6_ADDRSTRLEN = 46;


}
/************************************** os.win.com *********************************************************/

alias WCHAR OLECHAR;
alias OLECHAR *LPOLESTR;
alias OLECHAR *LPCOLESTR;

enum
{
	rmm = 23,	// OLE 2 version number info
	rup = 639,
}

enum : int
{
	S_OK = 0,
	S_FALSE = 0x00000001,
	NOERROR = 0,
	E_NOTIMPL     = cast(int)0x80004001,
	E_NOINTERFACE = cast(int)0x80004002,
	E_POINTER     = cast(int)0x80004003,
	E_ABORT       = cast(int)0x80004004,
	E_FAIL        = cast(int)0x80004005,
	E_HANDLE      = cast(int)0x80070006,
	CLASS_E_NOAGGREGATION = cast(int)0x80040110,
	E_OUTOFMEMORY = cast(int)0x8007000E,
	E_INVALIDARG  = cast(int)0x80070057,
	E_UNEXPECTED  = cast(int)0x8000FFFF,
}

struct GUID {          // size is 16
    align(1):
	DWORD Data1;
	WORD  Data2;
	WORD  Data3;
	BYTE  Data4[8];
}

enum
{
	CLSCTX_INPROC_SERVER	= 0x1,
	CLSCTX_INPROC_HANDLER	= 0x2,
	CLSCTX_LOCAL_SERVER	= 0x4,
	CLSCTX_INPROC_SERVER16	= 0x8,
	CLSCTX_REMOTE_SERVER	= 0x10,
	CLSCTX_INPROC_HANDLER16	= 0x20,
	CLSCTX_INPROC_SERVERX86	= 0x40,
	CLSCTX_INPROC_HANDLERX86 = 0x80,

	CLSCTX_INPROC = (CLSCTX_INPROC_SERVER|CLSCTX_INPROC_HANDLER),
	CLSCTX_ALL = (CLSCTX_INPROC_SERVER| CLSCTX_INPROC_HANDLER| CLSCTX_LOCAL_SERVER),
	CLSCTX_SERVER = (CLSCTX_INPROC_SERVER|CLSCTX_LOCAL_SERVER),
}

alias GUID IID;
alias GUID CLSID;


extern (System)
{

extern (Windows)
{
DWORD   CoBuildVersion();

int StringFromGUID2(GUID *rguid, LPOLESTR lpsz, int cbMax);

/* init/uninit */

DWORD   CoGetCurrentProcess();


HRESULT CoCreateInstance(CLSID *rclsid, IUnknown UnkOuter,
                    DWORD dwClsContext, IID* riid, void* ppv);

//HINSTANCE CoLoadLibrary(LPOLESTR lpszLibName, BOOL bAutoFree);
void    CoFreeLibrary(HINSTANCE hInst);
void    CoFreeAllLibraries();
void    CoFreeUnusedLibraries();
}

interface IUnknown
{
    HRESULT QueryInterface(IID* riid, void** pvObject);
    ULONG AddRef();
    ULONG Release();
}

interface IClassFactory : IUnknown
{
    HRESULT CreateInstance(IUnknown UnkOuter, IID* riid, void** pvObject);
    HRESULT LockServer(BOOL fLock);
}
/*
class ComObject : IUnknown
{
extern (System):
    HRESULT QueryInterface(IID* riid, void** ppv)
    {
	if (*riid == IID_IUnknown)
	{
	    *ppv = cast(void*)cast(IUnknown)this;
	    AddRef();
	    return S_OK;
	}
	else
	{   *ppv = null;
	    return E_NOINTERFACE;
	}
    }

    ULONG AddRef()
    {
	return InterlockedIncrement(&count);
    }

    ULONG Release()
    {
	LONG lRef = InterlockedDecrement(&count);
	if (lRef == 0)
	{
	    // free object

	    // If we delete this object, then the postinvariant called upon
	    // return from Release() will fail.
	    // Just let the GC reap it.
	    //delete this;

	    return 0;
	}
	return cast(ULONG)lRef;
    }

    LONG count = 0;		// object reference count
}
*/
}

/****************************************** os.win.stat ************************************************/

extern (C):

// linux version is in linux

version (Windows)
{
const S_IFMT   = 0xF000;
const S_IFDIR  = 0x4000;
const S_IFCHR  = 0x2000;
const S_IFIFO  = 0x1000;
const S_IFREG  = 0x8000;
const S_IREAD  = 0x0100;
const S_IWRITE = 0x0080;
const S_IEXEC  = 0x0040;
const S_IFBLK  = 0x6000;
const S_IFNAM  = 0x5000;

int S_ISREG(int m)  { return (m & S_IFMT) == S_IFREG; }
int S_ISBLK(int m)  { return (m & S_IFMT) == S_IFBLK; }
int S_ISNAM(int m)  { return (m & S_IFMT) == S_IFNAM; }
int S_ISDIR(int m)  { return (m & S_IFMT) == S_IFDIR; }
int S_ISCHR(int m)  { return (m & S_IFMT) == S_IFCHR; }

struct struct_stat
{
    short st_dev;
    ushort st_ino;
    ushort st_mode;
    short st_nlink;
    ushort st_uid;
    ushort st_gid;
    short st_rdev;
    short dummy;
    int st_size;
    int st_atime;
    int st_mtime;
    int st_ctime;
}

int  stat(char *, struct_stat *);
int  fstat(int, struct_stat *);
int  _wstat(wchar *, struct_stat *);
}