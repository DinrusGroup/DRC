// stdafx.h: включаемый файл для стандартных системных включаемых файлов
	// или включаемых файлов для конкретного проекта, которые часто используются, но
	// не часто изменяются
	//

	#pragma once
	#include "targetver.h"
	#define WIN32_LEAN_AND_MEAN 
#define M_UNICODE

	 // Исключите редко используемые компоненты из заголовков Windows
	 // Файлы заголовков Windows:
	 
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <time.h>


	// TODO: Установите здесь ссылки на дополнительные заголовки, требующиеся для программы

	
	
//#include ".\DMD\aa.h"
//#include ".\DMD\aav.h"
#include ".\DMD\aggregate.h"
#include ".\DMD\aliasthis.h"
#include ".\DMD\arraytypes.h"
#include ".\DMD\async.h"
#include ".\DMD\attrib.h"
#include ".\DMD\bcomplex.h"
#include ".\DMD\cc.h"
#include ".\DMD\cdef.h"
#include ".\DMD\cdeflnx.h"
#include ".\DMD\cgcv.h"
#include ".\DMD\code.h"
#include ".\DMD\complex_t.h"
#include ".\DMD\cond.h"
#include ".\DMD\cpp.h"
#include ".\DMD\cv4.h"
#include ".\DMD\dchar.h"
#include ".\DMD\declaration.h"
#include ".\DMD\doc.h"
#include ".\DMD\dsymbol.h"
#include ".\DMD\dt.h"
#include ".\DMD\dwarf.h"
#include ".\DMD\dwarf2.h"
#include ".\DMD\el.h"
#include ".\DMD\enum.h"
#include ".\DMD\exh.h"
#include ".\DMD\expression.h"
#include ".\DMD\filespec.h"
#include ".\DMD\global.h"
#include ".\DMD\gnuc.h"
#include ".\DMD\go.h"
#include ".\DMD\hdrgen.h"
#include ".\DMD\html.h"
#include ".\DMD\iasm.h"
#include ".\DMD\id.h"
#include ".\DMD\identifier.h"
#include ".\DMD\import.h"
#include ".\DMD\init.h"
#include ".\DMD\irstate.h"
#include ".\DMD\json.h"
#include ".\DMD\lexer.h"
#include ".\DMD\lib.h"
#include ".\DMD\list.h"
#include ".\DMD\lstring.h"
#include ".\DMD\mach.h"
#include ".\DMD\macro.h"
#include ".\DMD\mars.h"
#include ".\DMD\md5.h"
#include ".\DMD\melf.h"
#include ".\DMD\mem.h"
#include ".\DMD\module.h"
#include ".\DMD\mtype.h"
#include ".\DMD\objfile.h"
#include ".\DMD\oper.h"
#include ".\DMD\outbuf.h"
#include ".\DMD\parse.h"
#include ".\DMD\parser.h"
#include ".\DMD\port.h"
#include ".\DMD\rmem.h"
#include ".\DMD\root.h"
#include ".\DMD\rtlsym.h"
#include ".\DMD\scope.h"
#include ".\DMD\speller.h"
#include ".\DMD\statement.h"
#include ".\DMD\staticassert.h"
#include ".\DMD\stringtable.h"
#include ".\DMD\tassert.h"
#include ".\DMD\template.h"
//#include ".\DMD\tinfo.h"
#include ".\DMD\toir.h"
#include ".\DMD\token.h"
#include ".\DMD\total.h"
#include ".\DMD\ty.h"
#include ".\DMD\type.h"
#include ".\DMD\utf.h"
#include ".\DMD\vec.h"
#include ".\DMD\version.h"