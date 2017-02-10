module kong.IA32.X86IL;

//  Based on X86IL.h by Radim Picha (C 2006)

enum { SIZE16 = 2 }
enum { SIZE32 = 4 }
enum { X86IL_PREFIX_COUNT = 11 }


struct X86_opinfo
{
    ubyte prefix_count;   // Number of instruction prefixes.
    ubyte modRM_offset;   // ModRM-byte's offset from the start of
                          // the instruction (zero if none).
    ubyte immediate_size; // Size of immediate value(s) or moffs.
}

enum MODE { X32 = 32-32, X16 = 32-16, X64 = 32-64 }


int X86IL(ubyte* assembly, MODE bits, X86_opinfo* info = пусто)
{    static const ubyte X86ILTable[256] =
    [
    0x88,0x88,0x41,0x00,0x88,0x88,0x41,0x00,0x88,0x88,0x41,0x00,0x88,0x88,0x41,
    0x00,0x88,0x88,0x41,0x00,0x88,0x88,0x41,0x00,0x88,0x88,0x41,0x00,0x88,0x88,
    0x41,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x88,0x00,0x00,0xc4,0x91,0x00,0x00,0x11,0x11,0x11,0x11,
    0x11,0x11,0x11,0x11,0xc9,0x99,0x88,0x88,0x88,0x88,0x88,0x88,0x00,0x00,0x00,
    0x00,0x00,0x06,0x00,0x00,0x55,0x55,0x00,0x00,0x41,0x00,0x00,0x00,0x11,0x11,
    0x11,0x11,0x77,0x77,0x77,0x77,0x99,0x02,0x88,0xc9,0x03,0x02,0x10,0x00,0x88,
    0x88,0x11,0x00,0x88,0x88,0x88,0x88,0x11,0x11,0x11,0x11,0x44,0x16,0x00,0x00,
    0x00,0x00,0x00,0x88,0x00,0x00,0x00,0x88,0x88,0x88,0x00,0x00,0x00,0x00,0x80,
    0x80,0x88,0x88,0x88,0x88,0x08,0x00,0x00,0x00,0x11,0x11,0x11,0x11,0x88,0x88,
    0x88,0x88,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x88,0x88,0x88,0x88,0x88,
    0x88,0x88,0x88,0x80,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,
    0x88,0x88,0x00,0x88,0x99,0x99,0x88,0x08,0x00,0x00,0x00,0x88,0x44,0x44,0x44,
    0x44,0x44,0x44,0x44,0x44,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x88,0x00,0x80,
    0x89,0x00,0x00,0x80,0x89,0x88,0x88,0x88,0x88,0x88,0x00,0x89,0x88,0x88,0x88,
    0x88,0x99,0x89,0x00,0x00,0x00,0x00,0x80,0x88,0x88,0x80,0x88,0x88,0x88,0x88,
    0x88,0x88,0x88,0x80,0x88,0x88,0x88,0x88,0x80,0x88,0x88,0x88,0x88,0x88,0x88,
    0x08 ];

    static const ubyte X86IL_Prefixes[X86IL_PREFIX_COUNT] =
    [
      0x26, 0x2E, 0x36, 0x3E,
      0x64, 0x65, 0x66, 0x67,
      0xF0, 0xF2, 0xF3
    ];

    ubyte operand_size(ubyte x)
        { return (x >> 0) & 0x7; }

    ubyte isModRM(ubyte x)
        { return (x >> 3) & 0x1; }

    int def_argsize;  // 4 ubyte for 32bit,  2 ubyte for 16bit
    int fix_argsize;  // 0 ubyte for 32bit, -2 ubyte for 16bit because tables are 32bit
    int mode;         // 0 - 32bit, 1 - 16bit table
    int index;
    int ModRMAnd7;

    ubyte opcode;
    ubyte ModRM;
    ubyte pair_id;

    bool isSIB;

    // Init -------------

    bool OSChanged  = false;
    bool AMChanged  = false;
    int pos         = 0;
    int argsize     = 0;
    int ModRM_len   = 0;
    byte Rex        = 0;


    if (bits > 0)
    {
        def_argsize  = SIZE16;
        fix_argsize  = -2;
        mode =  1;

    } else
    {
        def_argsize  = SIZE32;
        fix_argsize  = 0;
        mode = 0;
    }

    if (info)
    {
        info.prefix_count   = 0;
        info.modRM_offset   = 0;
        info.immediate_size = 0;
    }

    // Prefix -------------

    while (pos < 16)
    {
        opcode = assembly[pos];
        pos++;

        if (bits < 0)
        {
            if (opcode >= 0x40 && opcode <= 0x4F){
                Rex = opcode;
                continue;
            }
        }

        for (ModRM = 0; (ModRM < X86IL_PREFIX_COUNT) && (X86IL_Prefixes[ModRM] != opcode); ModRM++)
            {}

        if (ModRM == X86IL_PREFIX_COUNT)
            break;

        Rex = 0;

        if (opcode == 0x66)
            OSChanged = true;

        if (opcode == 0x67)
            AMChanged = true;
    }

    if (pos >= 16)
        return pos;


    if (bits >= 0 || !(Rex & 8))
    {
        if (OSChanged)
        {
            if(fix_argsize == 0)
            {
                def_argsize = SIZE16;
                fix_argsize = -2;

            } else
            {
                def_argsize = SIZE32;
                fix_argsize = +0;
            }
        }
    }

    if (bits >= 0 && AMChanged)
        mode ^= 1;


    // Instruction -------------

    if (info)
        info.prefix_count = pos - 1;

    if (opcode == 0xF)
    {
        opcode = assembly[pos];
        pos++;
        index = (opcode >> 1) + (0x100 >> 1);
    }
    else
        index = (opcode >> 1) + (0x000 >> 1);


    pair_id   = X86ILTable[index];
    pair_id >>= (opcode & 1) << 2;

    // ModRM, SIB -------------

    if (isModRM(pair_id))
    {
        ModRM_len++;
        ModRM = assembly[pos];

        if (info)
            info.modRM_offset = pos;

        ++pos;

        ModRMAnd7 = ModRM & 7;
        isSIB     = ModRMAnd7 == 4;

        switch(ModRM >> 6){
        case 0:

            if (mode == 0) //32bit
            {
                if (isSIB)
                {
                    if ((assembly[pos] & 7) == 5)
                        ModRM_len += SIZE32;

                    ModRM_len++;

                } else
                {
                    if (ModRMAnd7 == 5)
                        ModRM_len += SIZE32;
                }
            } else //16bit
            {
                if (ModRMAnd7 == 6)
                    ModRM_len += SIZE16;
            }
            break;

        case 1:

            if (mode == 0 && isSIB)
                ModRM_len++;

            ModRM_len++;
            break;

        case 2:

            if (mode == 0) //32bit
            {
                if (isSIB)
                    ModRM_len++;

                ModRM_len += SIZE32;
            }
            else
                ModRM_len += SIZE16; //16bit

            break;

        default : break;
        }

        pos += ModRM_len - 1;

        if (((opcode & 0xFE) == 0xF6) && index <= 0x7F && ((ModRM & 0x38) == 0x00)) // fix F6, F7 - TEST R/M, IMM
            argsize += (opcode & 1) ? def_argsize : 1;

    }

    // Operand -------------

    if (operand_size(pair_id))
    {
        switch (operand_size(pair_id)){
        default       : argsize += operand_size(pair_id); break;
        case SIZE32+0 : argsize += SIZE32 + 0 + fix_argsize; break;
        case SIZE32+2 : argsize += SIZE32 + 2 + fix_argsize; break;
        case SIZE32+3 : argsize += (Rex & 8) ? SIZE32*2 : (SIZE32 + fix_argsize); break;
        case SIZE32+1 : argsize += ((bits < 0 && AMChanged) || mode ? SIZE16 : SIZE32)*(bits < 0 ? 2 : 1); break;
        }
    }

    if (info)
        info.immediate_size = argsize;

    if (opcode == 0xF) //3DNow!
        argsize++;

    pos += argsize;

    return pos;
}


unittest
{
    struct tst
    {
        int flag1;
        int flag2;
        int flag3;
        int flag4;
        int flag5;
    }

    ubyte code[] = [
    0x8d,0x4c,0x24,0x04,0x83,0xe4,0xf0,0xff,0x71,0xfc,0x55,0x89,0xe5,0x51,0x83,0xec,
    0x14,0x8b,0x11,0x8b,0x41,0x04,0xc7,0x44,0x24,0x08,0x53,0xa5,0x04,0x08,0x89,0x14,
    0x24,0x89,0x44,0x24,0x04,0xe8,0x46,0x3b,0x00,0x00,0x83,0xc4,0x14,0x59,0x5d,0x8d,
    0x61,0xfc,0xc3,0x90
    ];

    // length, info.prefix_count, i, j, info.immediate_size
    tst[19] test_list = [
    tst(4, 0, 1, 3, 0),
    tst(3, 0, 1, 1, 1),
    tst(3, 0, 1, 2, 0),
    tst(1, 0, 1, 0, 0),
    tst(2, 0, 1, 1, 0),
    tst(1, 0, 1, 0, 0),
    tst(3, 0, 1, 1, 1),
    tst(2, 0, 1, 1, 0),
    tst(3, 0, 1, 2, 0),
    tst(8, 0, 1, 3, 4),
    tst(3, 0, 1, 2, 0),
    tst(4, 0, 1, 3, 0),
    tst(5, 0, 1, 0, 4),
    tst(3, 0, 1, 1, 1),
    tst(1, 0, 1, 0, 0),
    tst(1, 0, 1, 0, 0),
    tst(3, 0, 1, 2, 0),
    tst(1, 0, 1, 0, 0),
    tst(1, 0, 1, 0, 0)
    ];

    X86_opinfo info;

    ubyte *ptr = code.ptr;


    foreach (ref test; test_list)
    {
        int length = X86IL(ptr, MODE.X32, &info);

        int i = (info.modRM_offset
              ?  info.modRM_offset + (ptr[info.modRM_offset-1] == 0xF ? 1 : 0)
              :  length - info.immediate_size)
              - info.prefix_count;

        int j = (info.modRM_offset)
              ? length - info.prefix_count - i - info.immediate_size
              : 0;

        assert(tst(length, info.prefix_count, i, j, info.immediate_size) == test);
        ptr += length;
    }
}
