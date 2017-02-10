/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.win32.DSO : DLL listing with NtQueryInformationProcess (undoc).
*/
module kong.win32.DSO;

version (Windows):

version (Phobos){
import std.stdint;
import std.path;
import std.c.string;
import std.string;
import std.c.windows.windows;
import std.utf;
}
version (Rulada){
import std.path;
import std.c;
import std.string;
import os.windows;
import std.utf;
}

version (Dinrus){
import std.path;
import cidrus;
import std.string;
import winapi;
import stdrus;
alias вТкст0 toStringz;
alias вЮ8 toUTF8;
}


public import kong.internal.dynamic_object;
public import kong.PE.types;
import kong.PE.PE;


version(X86)          alias PE_platform!(IMAGE_FILE_MACHINE_I386)  PE_native;
else version(X86_64)  alias PE_platform!(IMAGE_FILE_MACHINE_AMD64) PE_native;
else                  static assert(0);


void* DSO_resolve(string sym, string so, inout void* handle)
{
    char* str = (so == IMAGE_SELF) ? пусто : toStringz(so);

    if (handle == пусто)
    {
        handle = cast(void*) LoadLibraryA(str);

        if (handle == пусто)
            return пусто;
    }

    return GetProcAddress(handle, toStringz(sym));
}

void DSO_free(void *handle)
{
    FreeLibrary(handle);
}




struct
DSO_list
{
    static void* process_image;

    static
    dynamic_object[]
    opSlice()
    {
        dynamic_object[] table;

        if (!process_image)
            process_image = GetModuleHandleA(пусто);

        bool
        dll_process(LDR_MODULE* dll)
        {
            dynamic_object obj;
            obj.address = dll.BaseAddress;
            obj.name    = (dll.BaseAddress == process_image)
                        ? IMAGE_SELF
                        : toUTF8(dll.FullDllName.Buffer[0 .. dll.FullDllName.Length / wchar.sizeof]);

            obj.image = new PE_native.image(dll.BaseAddress, true);

            table ~= obj;
            return true;
        }
        enum_PEBDLL(&dll_process);
        return table;
    }


    static
    dynamic_object*
    opIndex(string name)
    {
        dynamic_object[] table;
        bool match_self = false;


        if (!process_image)
            process_image = GetModuleHandleA(пусто);

        if (name == IMAGE_SELF)
            match_self = true;

        bool
        dll_find(LDR_MODULE* dll)
        {
            string dll_name = toUTF8(dll.FullDllName.Buffer[0 .. dll.FullDllName.Length / wchar.sizeof]);

            if (match_self)
            {
                if (dll.BaseAddress != process_image)
                    return true;
            }
            else if (!fnmatch(dll_name, name))
                return true;

            dynamic_object obj;
            obj.address = dll.BaseAddress;
            obj.name    = (dll.BaseAddress == process_image) ? IMAGE_SELF : dll_name;
            obj.image   = new PE_native.image(dll.BaseAddress, true);

            table ~= obj;
            return false;
        }
        enum_PEBDLL(&dll_find);
        return (table.length) ? &table[0] : пусто;
    }

}
extern(Windows)
{
void* GetProcAddress(void*, char*);
void* LoadLibraryA(char*);
int FreeLibrary(void*);
void* GetModuleHandleA(char*);
}

extern (Windows) alias int function(void*, uint, void*, uint, uint*) NTQIP;

void
enum_PEBDLL(bool delegate(LDR_MODULE*) process)
{
    uint size;
    NTQIP NtQueryInformationProcess;
    PROCESS_BASIC_INFORMATION pbi;

    void* nt = GetModuleHandleA(cast(char*) "ntdll.dll");

    if (nt != пусто)
    {
        NtQueryInformationProcess = cast(NTQIP) GetProcAddress(nt, cast(char*)"NtQueryInformationProcess");

        if (NtQueryInformationProcess)
        {
            NtQueryInformationProcess(GetCurrentProcess(), 0, &pbi, pbi.sizeof, &size);

            if (size != pbi.sizeof)
                return;

            LDR_MODULE* dll;
            uint lc = 0;

            for (
              (dll = cast(LDR_MODULE*) pbi.PebBaseAddress.Ldr.InLoadOrderModuleList.Flink);
              (dll != пусто && dll.BaseAddress != пусто);
              (dll = cast(LDR_MODULE*) dll.InLoadOrderModuleList.Flink))
            {
                if (dll == cast(LDR_MODULE*) pbi.PebBaseAddress.Ldr.InLoadOrderModuleList.Flink && ++lc == 2)
                    break;

                if (dll.BaseDllName.Length == 0)
                    continue;

                if (process(dll) == false)
                    break;
            }

        }
    }

    return;
}



/*
example: de-linking dlls:

bool
dll_hide(LDR_MODULE* dll)
{
    LIST_ENTRY* next;
    LIST_ENTRY* prev;


    if (dll.BaseAddress == address)
    {
        next = dll.InLoadOrderModuleList.Flink;
        prev = dll.InLoadOrderModuleList.Blink;

        next.Blink = prev;
        prev.Flink = next;

        next = dll.InInitializationOrderModuleList.Flink;
        prev = dll.InInitializationOrderModuleList.Blink;

        next.Blink = prev;
        prev.Flink = next;

        next = dll.InMemoryOrderModuleList.Flink;
        prev = dll.InMemoryOrderModuleList.Blink;

        next.Blink = prev;
        prev.Flink = next;

        return false;
    }
    return true;
}

*/


