
extern "C" {
#include "Header.h"

	/* Links the source module into the destination module. The source module is
	 * destroyed.
	 * The return value is true if an error occurred, false otherwise.
	 * Use the diagnostic handler to get any diagnostic message.
	*/
	LLEXPORT ЛЛБул ЛЛКомпонуйМодули2(ЛЛМодуль Dest, ЛЛМодуль Src){
		return LLVMLinkModules2(Dest, Src);
	}


}