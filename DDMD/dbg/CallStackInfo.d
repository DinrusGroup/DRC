/**
 A simple runtime crash handler which collects various informations about
 the crash such as registers, stack traces, and loaded modules.

 TODO:
	* Threading support
	* Stack dumps

 Authors:
	Jeremie Pelletier

 License:
	Public Domain
*/
module dbg.CallStackInfo;

import dbg.Debug;
import dbg.image.PE;

import core.stdc.stdio;
import core.sys.windows.windows;

import rt.deh;

class CallStackInfo
{
	this(EXCEPTION_POINTERS* e = null)
	{
		size_t[16] buff;
		size_t[] backtrace = buff[];
		size_t numTraces = 0;
		
		bool skipFirst = false;
		
		size_t ip = void, bp = void;
		version(Windows) {
		if (e !is null) {
			ip = e.ContextRecord.Eip;
			bp = e.ContextRecord.Ebp;
			
			error = _d_translate_se_to_d_exception(e.ExceptionRecord);
			append(backtrace, numTraces, ip);
		} else {
			asm {
				mov bp, EBP;
			}
		}
		}
		
		while (true) {
			ip = cast(size_t)*(cast(void**)bp + 1);
			if (ip == 0) break;
			
			append(backtrace, numTraces, ip);
			
			bp = cast(size_t)*cast(void**)bp;
		}
		
		frames = new StackFrameInfo[numTraces];
		ResolveStackFrames(backtrace[0..numTraces], frames);
	}
	
	Throwable error;
	StackFrameInfo[] frames;

	override string toString()
	{
		string text;
		
		if (error !is null) {	
			text ~= error.toString() ~ "\n";			
		}
		
		text ~= "Stack trace:\n------------------\n";
		char[128] buffer;
		foreach(ref frame; frames)
		{
			with(frame.fileLine) if(line)
			{
				auto len = snprintf(buffer.ptr, buffer.length, "%u", line);
				text ~= file ~ ":" ~ buffer[0 .. len] ~ "\r\n";
			}
		}

		text ~= '\0';

		return text;
	}
	
	void dump()
	{
		if (error !is null) {	
			char* er = cast(char*) error.toString();
			printf("%.*s\n",  er);
		}
		
		printf("Stack trace:\n------------------\n");
		foreach(ref frame; frames) {
			with(frame.fileLine) if (line) {
				printf("%.*s:%d\r\n", file, line);
			}
		}
	}

private:

	struct StackFrameInfo {
		size_t			va;
		string			moduleName;
		SymbolInfo		symbol;
		FileLineInfo	fileLine;
	}

	struct DebugImage {
		DebugImage*			next;
		string				moduleName;
		size_t				baseAddress;
		uint				rvaOffset;
		IExecutableImage	exeModule;
		ISymbolicDebugInfo	debugInfo;
	}

	void ResolveStackFrames(size_t[] backtrace, StackFrameInfo[] frames) const {
		StackFrameInfo* frame = void;
		DebugImage* imageList, image = void;
		char[255] buffer = void;
		uint len = void;
		uint rva = void;

		version(Windows) MEMORY_BASIC_INFORMATION mbi = void;

		foreach(i, va; backtrace) {
			frame = &frames[i];
			frame.va = va;

			version(Windows) {
			    // mbi.Allocation base is the handle to stack frame's module
			    VirtualQuery(cast(void*)va, &mbi, MEMORY_BASIC_INFORMATION.sizeof);
			    if(!mbi.AllocationBase) break;

			    image = imageList;
			    while(image) {
				    if(image.baseAddress == cast(size_t)mbi.AllocationBase) break;
				    image = image.next;
			    }

			    if(!image) {
				    image = new DebugImage;

				    with(*image) {
					    next = imageList;
					    imageList = image;
					    baseAddress = cast(size_t)mbi.AllocationBase;

					    len = GetModuleFileNameA(cast(HMODULE)baseAddress, buffer.ptr, buffer.length);
					    moduleName = buffer[0 .. len].idup;
					    if (len != 0) {
						    exeModule = new PEImage(moduleName);
						    rvaOffset = baseAddress + exeModule.codeOffset;
						    debugInfo = exeModule.debugInfo;
					    }
				    }
			    }
			}
			else version(POSIX)
			{
				assert(0);
			}
			else static assert(0);

			frame.moduleName = image.moduleName;

			if(!image.debugInfo) continue;

			rva = va - image.rvaOffset;

			with(image.debugInfo) {
				frame.symbol = ResolveSymbol(rva);
				frame.fileLine = ResolveFileLine(rva);
			}
		}

		while(imageList) {
			image = imageList.next;
			delete imageList.debugInfo;
			delete imageList.exeModule;
			delete imageList;
			imageList = image;
		}
	}
}

void CrashHandlerInit() {
	version(Windows) {
	    //SetErrorMode(SetErrorMode(0) | SEM_FAILCRITICALERRORS);
	    SetErrorMode(0);
	    SetUnhandledExceptionFilter(&UnhandledExceptionHandler);
	}
	else version(Posix) {
	assert(0);
	/+	sigaction_t sa;
		sa.sa_handler = cast(sighandler_t)&SignalHandler;
		sigemptyset(&sa.sa_mask);
		sa.sa_flags = SA_RESTART | SA_SIGINFO;

		sigaction(SIGILL, &sa, null);
		sigaction(SIGFPE, &sa, null);
		sigaction(SIGSEGV, &sa, null);+/
	}
	else static assert(0);
}
enum EXCEPTION_EXECUTE_HANDLER = 1;

/*extern(Windows) */int UnhandledExceptionHandler(EXCEPTION_POINTERS* e) {
	scope CallStackInfo info = new CallStackInfo(e);
	info.dump();

	return EXCEPTION_EXECUTE_HANDLER;
}

extern (Windows) extern UINT SetErrorMode(UINT);
alias LONG function(EXCEPTION_POINTERS*) PTOP_LEVEL_EXCEPTION_FILTER;
extern (Windows) PTOP_LEVEL_EXCEPTION_FILTER SetUnhandledExceptionFilter(PTOP_LEVEL_EXCEPTION_FILTER);

void append(T)(ref T[] array, ref size_t index, T value)
{
	size_t capacity = array.length;
	assert(capacity >= index);
	if (capacity == index) {
		if (capacity < 8) {
			capacity = 8;
		} else {
			capacity *= 2;
		}
		
		array.length = capacity;
	}
	
	array[index++] = value;
}

struct EXCEPTION_POINTERS {
	core.sys.windows.winnt.EXCEPTION_RECORD* ExceptionRecord;
	CONTEXT*          ContextRecord;
}

const MAXIMUM_SUPPORTED_EXTENSION = 512;

struct CONTEXT {
	DWORD ContextFlags;
	DWORD Dr0;
	DWORD Dr1;
	DWORD Dr2;
	DWORD Dr3;
	DWORD Dr6;
	DWORD Dr7;
	FLOATING_SAVE_AREA FloatSave;
	DWORD SegGs;
	DWORD SegFs;
	DWORD SegEs;
	DWORD SegDs;
	DWORD Edi;
	DWORD Esi;
	DWORD Ebx;
	DWORD Edx;
	DWORD Ecx;
	DWORD Eax;
	DWORD Ebp;
	DWORD Eip;
	DWORD SegCs;
	DWORD EFlags;
	DWORD Esp;
	DWORD SegSs;
	BYTE[MAXIMUM_SUPPORTED_EXTENSION] ExtendedRegisters;
}

//extern Throwable _d_translate_se_to_d_exception(EXCEPTION_RECORD* exception_record);
