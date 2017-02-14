
// Copyright (c) 2004 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com

#include <stdio.h>
#include <stddef.h>
#include <time.h>
#include <assert.h>

#include "mars.h"
#include "module.h"
#include "mtype.h"
#include "declaration.h"
#include "statement.h"
#include "enum.h"
#include "aggregate.h"
#include "init.h"
#include "attrib.h"
#include "id.h"
#include "import.h"
#include "template.h"

#include "./root/rmem.h"
#include "./backend/cc.h"
#include "./backend/global.h"
#include "./backend/oper.h"
#include "./backend/code.h"
#include "./backend/type.h"
#include "./backend/dt.h"
#include "./backend/cv4.h"
#include "./backend/cgcv.h"
#include "./backend/outbuf.h"
#include "irstate.h"

/****************************
 * Emit symbolic debug info in Dwarf2 format.
 */

void TypedefDeclaration::toDebug()
{
    //printf("TypedefDeclaration::toDebug('%s')\n", toChars());
}


void EnumDeclaration::toDebug()
{
    //printf("EnumDeclaration::toDebug('%s')\n", toChars());
}


void StructDeclaration::toDebug()
{
}


void ClassDeclaration::toDebug()
{
}


/* ===================================================================== */

/*****************************************
 * Insert CV info into *p.
 * Returns:
 *      number of bytes written, or that would be written if p==NULL
 */

int Dsymbol::cvMember(unsigned char *p)
{
    return 0;
}


int TypedefDeclaration::cvMember(unsigned char *p)
{
    return 0;
}


int EnumDeclaration::cvMember(unsigned char *p)
{
    return 0;
}


int FuncDeclaration::cvMember(unsigned char *p)
{
    return 0;
}

int VarDeclaration::cvMember(unsigned char *p)
{
    return 0;
}