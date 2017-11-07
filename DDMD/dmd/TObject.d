module dmd.TObject;
/*
import core.runtime;
import core.stdc.stdio;
import core.stdc.string;
import core.stdc.stdlib;

import dmd.TObject;

import core.sys.windows.windows;
import core.sys.windows.codeview;
import core.demangle;
import core.memory;
import core.stdc.stdlib;

version = TrackArray;

version (TrackList) {
    enum mNull = TObject.pack(0);
    __gshared size_t mHead = mNull;
} else version (TrackArray) {
    __gshared size_t[] objects;
}
*/
class TObject
{
	void register()
	{
	}
	
	void forceRegister()
	{
	}
	
	/*
    this()
    {
        register();
    }

	~this()
	{
	    size_t mThis = pack(this);

        version (TrackList) {
            if (mPrev != mNull) {
                unpack(mPrev).mNext = mNext;
            } else {
                assert(mHead == mThis);
                mHead = mNext;
            }

            if (mNext != mNull) {
                unpack(mNext).mPrev = mPrev;
            }
        } else version (TrackArray) {
            foreach (i, o; objects) {
                if (o == mThis) {
                    size_t newLen = objects.length - 1;
                    objects[i] = objects[newLen];
                    objects.length = newLen;

                    alloc = cast(void*)-1;
                    return;
                }
            }
        }
	}

    version (TrackList) {
        size_t mPrev;
        size_t mNext;
    }

	void* alloc;

	static TObject unpack(size_t m)
	{
        m &= ~(1 << 31);
        return cast(TObject)cast(void*)m;
	}

	static size_t pack(size_t m)
	{
	    return m |= (1 << 31);
	}

	static size_t pack(TObject o)
	{
	    return pack(cast(size_t)cast(void*)o);
	}

	void forceRegister()
	{
	    version (TrackList) {
	        alloc = alloc_point();
            size_t mThis = pack(this);

            mNext = mHead;
            if (mHead != mNull) {
                unpack(mHead).mPrev = mThis;
            }

            mPrev = mNull;
            mHead = mThis;
	    } else version (TrackArray) {
	        alloc = alloc_point();
            objects ~= pack(this);
	    }
	}

	void register()
	{
        if (alloc !is null) return;
        forceRegister();
	}

	static void dump()
	{
		int[void*] allocStat;

        version (TrackList) {
            auto o = unpack(mHead);
            while (o !is null) {
                allocStat[o.alloc]++;
                o = unpack(o.mNext);
            }
        } else version (TrackArray) {
            foreach (i, m; objects) {
                allocStat[unpack(m).alloc]++;
            }
        }

		FILE* f = fopen("alloc_stat.txt", "wb");
		if (f is null) return;

		StackFrameInfo* frame = void;
		DebugImage* imageList, image = void;
		char[255] buffer = void;

		MEMORY_BASIC_INFORMATION mbi = void;

		void resolve(const(void)* c) {
			StackFrameInfo frame;
			frame.va = cast(void*)c;

			// mbi.Allocation base is the handle to stack frame's module
			VirtualQuery(frame.va, &mbi, MEMORY_BASIC_INFORMATION.sizeof);
			if (!mbi.AllocationBase) return;

			image = imageList;
			while(image) {
				if (image.baseAddress == cast(size_t)mbi.AllocationBase) break;
				image = image.next;
			}

			if (!image) {
				image = new DebugImage;

				with (*image) {
					next = imageList;
					imageList = image;
					baseAddress = cast(size_t)mbi.AllocationBase;

					uint len = GetModuleFileNameA(cast(HMODULE)baseAddress, buffer.ptr, buffer.length);
					moduleName = buffer[0 .. len].idup;

					if (len != 0) {
						exeModule = new PEImage(moduleName);
						rvaOffset = baseAddress + exeModule.codeOffset;
						debugInfo = exeModule.debugInfo;
					}
				}
			}

			frame.moduleName = image.moduleName;

			size_t va = cast(size_t)frame.va;

			if (image.debugInfo) with (image.debugInfo) {
				uint rva = va - image.rvaOffset;

				frame.symbol = ResolveSymbol(rva);
				frame.fileLine = ResolveFileLine(rva);
			}

			auto s = image.exeModule.closestSymbol(va);
			printf("%.*s\n", s);
			auto symbol = demangle(s.symbol);

			if (frame.fileLine.file.length != 0) {
				fprintf(f, "%.*s %.*s:%d\n", symbol, frame.fileLine.file, frame.fileLine.line);
//			} else {
//				if (symbol.length != 0) {
//					fprintf(f, "%.*s", symbol);
//				}
			}
		}

		while (imageList) {
			image = imageList.next;
			delete imageList.debugInfo;
			delete imageList.exeModule;
			delete imageList;
			imageList = image;
		}

        int max = 0;
        int total = 0;
		fprintf(f, "%d\n", allocStat.length);
		foreach (alloc, count; allocStat) {
			resolve(alloc);

			fprintf(f, "count: %d\n\n", count);
			if (count > max) max = count;
			total += count;
		}
		fprintf(f, "max: %d\n\n", max);
		fprintf(f, "total: %d\n\n", total);
		fclose(f);
	}
	*/
}
/*
void* alloc_point()
{
	void** bp = void;

	asm {
		mov bp, EBP;
	}

    bp = cast(void**)*bp;
    bp = cast(void**)*bp;
    bp = cast(void**)*bp;
    return *(bp + 1);
}

void callstack_print(FILE* f, void*[] callstack)
{
	char** framelist = backtrace_symbols(callstack.ptr, callstack.length);
	for( int i = 0; i < callstack.length; ++i )
	{
		auto line = framelist[i];
		if (strcmp(line, "<no debug info found>") == 0) {
			continue;
		}
		fwrite(line, 1, strlen(line), f);
		fwrite("\n".ptr, 1, 1, f);
	}
	free(framelist);
}
*/