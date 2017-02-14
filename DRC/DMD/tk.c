
// Copyright (c) 1999-2002 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com

#include        <stdio.h>
#include        <stdlib.h>
#include        <string.h>


#include        "./backend/tassert.h"

#include        "./tk/mem.h"
#include        "./tk/filespec.c"

#if 0
#define malloc          ph_malloc
#define calloc(x,y)     ph_calloc((x) * (y))
#define realloc         ph_realloc
#define free            ph_free
#endif

#if !MEM_DEBUG
#define MEM_NOMEMCOUNT  1
#define MEM_NONEW       1
#endif
#include        "./tk/mem.c"
#include        "./tk/list.c"
#include        "./tk/vec.c"
