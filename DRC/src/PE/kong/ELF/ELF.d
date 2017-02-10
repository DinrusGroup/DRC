/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.ELF.ELF : ELF parser and data mining callbacks.
*/

module kong.ELF.ELF;
import kong.internal.stdlib;
import kong.internal.mine;

public import kong.ELF.types;
public import kong.internal.image_interface;
import kong.internal.image_reflect;

enum { TYPE_ELF32, TYPE_ELF64 }

mixin (reflect!("Ehdr", ["Elf32_Ehdr", "Elf64_Ehdr"],
"e_type",
"e_machine",
"e_version",
"e_entry",
"e_phoff",
"e_shoff",
"e_flags",
"e_ehsize",
"e_phentsize", "e_phnum",
"e_shentsize", "e_shnum",
"e_shstrndx"));

mixin (reflect!("Phdr", ["Elf32_Phdr", "Elf64_Phdr"],
"p_type",
"p_offset",
"p_vaddr",
"p_paddr",
"p_filesz",
"p_memsz",
"p_flags",
"p_align"));

mixin (reflect!("Shdr", ["Elf32_Shdr", "Elf64_Shdr"],
"sh_name",
"sh_type",
"sh_flags",
"sh_addr",
"sh_offset",
"sh_size",
"sh_link",
"sh_info",
"sh_addralign",
"sh_entsize"));

mixin (reflect!("Sym", ["Elf32_Sym", "Elf64_Sym"],
"st_name",
"st_value",
"st_size",
"st_info",
"st_other",
"st_shndx"));

mixin (reflect!("Rel", ["Elf32_Rel", "Elf64_Rel"],
"r_offset",
"r_info"));

mixin (reflect!("Rela", ["Elf32_Rela", "Elf64_Rela"],
"r_offset",
"r_info",
"r_addend"));

mixin (reflect!("Dyn", ["Elf32_Dyn", "Elf64_Dyn"],
"d_val",
"d_ptr",
"d_tag"));


class image : image_interface
{
    public:

    Ehdr  header;
    uint64_t sn;
    uint64_t pn;

    bool active = false;

    void
    ELF_verify(io_stream file)
    {
        ubyte[EI_NIDENT] id;

        file.copy(id.ptr, EI_NIDENT, 0);

        enforce(id[0 .. 4] != ELFMAG!(), "Invalid ELF header");
        enforce(id[EI_VERSION] != EV_CURRENT, "Unsupported ELF version");

        if ((id[EI_DATA] == ELFDATA2MSB && _эндиан == Эндиан.Литл) ||
            (id[EI_DATA] == ELFDATA2LSB && _эндиан == Эндиан.Биг))
            super.endian = true;

        if (id[EI_CLASS] == ELFCLASS32)
            type = TYPE_ELF32;

        else if (id[EI_CLASS] == ELFCLASS64)
            type = TYPE_ELF64;

        else throw new image_exception("Invalid ELF class");
    }

    this(string a, IO_MODE mode = IO_MODE.R)
        { this(new file_stream(a, mode)); }

    this(void* base, bool active)
        { this.active = active; this(new memory_stream(base)); }


    this(io_stream file)
    {
        super(file);
        ELF_verify(file);

        link(header, 1, 0);

        pn = header[header.e_phnum];
        sn = header[header.e_shnum];

        if (header[Ehdr.e_shoff] && active == false)
        {
            Shdr sh0;
            copy(sh0, header[Ehdr.e_shoff]);

            if (pn == PN_XNUM)
                pn = sh0[Shdr.sh_link];

            if (sn == 0)
                sn = sh0[Shdr.sh_size];
        }

    }

    void
    analyze(T...)(T tt)
    {
        static if (tt.length)
        {
            static if (is(T[0] : mine!(Phdr)))
            {
                if (header[Ehdr.e_phoff] && pn != PN_XNUM)
                {
                    T[0] x = tt[0];
                    x.analyze(link(x.data, pn, header[header.e_phoff]));
                }
            }
            else static if (is(T([0]) : mine!(Shdr)))
            {
                if (header[Ehdr.e_shoff] && active == false && sn)
                {
                    T[0] x = tt[0];
                    x.analyze(link(x.data, sn, header[header.e_shoff]));
                }
            }

            static if (tt.length >= 2)
                analyze(tt[1 .. $]);
        }
    }


    // UTILITY FUNCTIONS //

    static uint64_t  RVA2file(uint64_t x, ref Phdr s){ return (x - s[s.p_vaddr])  + s[s.p_offset]; }
    static uint64_t file2RVA(uint64_t  x, ref Phdr s){ return (x - s[s.p_offset]) + s[s.p_vaddr];  }

    static
    Sym*
    symbol_lookup(string query, Sym[] table, uint32_t[] buckets, uint32_t[] chains, char[] strtab)
    in
    {
        assert(buckets.length);
        assert(query.length);

    } body
    {
        if (!query)
            return пусто;

        uint32_t i = symbol_hash(query) % buckets.length;

        for (i = buckets[i]; i != STN_UNDEF; i = chains[i])
        {
            if (string_lookup(table[i][Sym.st_name], strtab) == query)
                return &table[i];
        }

        return пусто;
    }

    static
    T*
    PLT_lookup(T)(T[] reloc_table, ref Sym symbol, Sym[] symbols)
    {
        uint64_t name = symbol[Sym.st_name];

        foreach(ref r; reloc_table)
        {
            if (symbols[R_SYM(r)][Sym.st_name] == name && r[r.r_offset])
                return &r;
        }

        return пусто;
    }
}



class PT : mine!(Phdr)
{
    DT dynamic;
    image img;

    uint index(ref Phdr x){ return x[x.p_type]; };

    this(image img, lazy DT dynamic, uint[] mask = пусто)
    {
        table[PT_DYNAMIC] = &xPT_DYNAMIC;
        this.img     = img;
        this.dynamic = cast(DT) dynamic;

        if (mask)
            this.reduceto(mask);
    }

    this(image img, uint[] mask = пусто)
    {
        this(img, new DT(this, img), mask);
    }

    void xPT_DYNAMIC(inout Phdr p)
    {
        typeof(dynamic.data) x;
        img.link_b(x, p[p.p_filesz], p[p.p_offset]);
        dynamic.analyze(dynamic.data = x);
    }


    uint64_t
    RVA2file(uint64_t x)
    {
        foreach(ref Phdr p; data)
            if (x >= p[p.p_vaddr] && x < p[p.p_vaddr] + p[p.p_memsz])
                return img.RVA2file(x, p);

        throw new image_exception("RVA2file: offset out of bounds");
    }

    uint64_t
    file2RVA(uint64_t x)
    {
        foreach(ref Phdr p; data)
            if (x >= p[p.p_offset] && x < p[p.p_offset] + p[p.p_filesz])
                return img.file2RVA(x, p);

        throw new image_exception("file2RVA: offset out of bounds");
    }

}



class DT : mine!(Dyn)
{
    Sym[]      symbols;
    Rel[]      reloc;
    Rela[]     reloc_a;
    Rel[]      PLT_rel;
    Rela[]     PLT_rela;
    uint64_t   PLT_type;

    uint32_t[] h_buckets;
    uint32_t[] h_chains;
    uint64_t[] depends;

    char[]     strings;
    PT         segment;

    private:

    uint64_t rbase, rbase_a, rbase_p, strbase, symbase;
    uint64_t rsize, rsize_a, rsize_p, strsize;

    public:
    image img;

    this(PT segment, image img)
    {
        this.img = img;
        this.segment = segment;

        table[DT_SYMENT]   = &xDT_SYMENT;
        table[DT_RELAENT]  = &xDT_RELAENT;
        table[DT_RELENT]   = &xDT_RELENT;
        table[DT_REL]      = &xDT_REL;
        table[DT_RELA]     = &xDT_RELA;
        table[DT_RELSZ]    = &xDT_RELSZ;
        table[DT_RELASZ]   = &xDT_RELASZ;
        table[DT_JMPREL]   = &xDT_JMPREL;
        table[DT_PLTRELSZ] = &xDT_PLTRELSZ;
        table[DT_PLTREL]   = &xDT_PLTREL;
        table[DT_NEEDED]   = &xDT_NEEDED;
        table[DT_STRSZ]    = &xDT_STRSZ;
        table[DT_STRTAB]   = &xDT_STRTAB;
        table[DT_SYMTAB]   = &xDT_SYMTAB;
        table[DT_HASH]     = &xDT_HASH;
    }

    void xDT_REL      (inout Dyn d){ rbase    = d[d.d_ptr]; }
    void xDT_RELA     (inout Dyn d){ rbase_a  = d[d.d_ptr]; }
    void xDT_RELSZ    (inout Dyn d){ rsize    = d[d.d_val]; }
    void xDT_RELASZ   (inout Dyn d){ rsize_a  = d[d.d_val]; }
    void xDT_JMPREL   (inout Dyn d){ rbase_p  = d[d.d_ptr]; }
    void xDT_PLTRELSZ (inout Dyn d){ rsize_p  = d[d.d_val]; }
    void xDT_PLTREL   (inout Dyn d){ PLT_type = d[d.d_val]; }
    void xDT_NEEDED   (inout Dyn d){ depends ~= d[d.d_ptr]; }
    void xDT_STRSZ    (inout Dyn d){ strsize  = d[d.d_val]; }
    void xDT_STRTAB   (inout Dyn d){ strbase  = d[d.d_ptr]; }
    void xDT_SYMTAB   (inout Dyn d){ symbase  = d[d.d_ptr]; }

    void xDT_SYMENT (inout Dyn d)
        { enforce(d[d.d_val] != Sym.t_size[img.type], "SYMENT invalid"); }

    void xDT_RELAENT (inout Dyn d)
        { enforce(d[d.d_val] != Rela.t_size[img.type], "RELAENT invalid"); }

    void xDT_RELENT (inout Dyn d)
        { enforce(d[d.d_val] != Rel.t_size[img.type], "RELENT invalid"); }

    void xDT_HASH(inout Dyn d)
    {
        uint32_t[] n;
        segment.img.link(n, 2, convert(d[d.d_ptr]));
        segment.img.link(h_buckets, n[0]);
        segment.img.link(h_chains,  n[1]);
    }

    // TODO: document this function

    uint64_t
    convert(uint64_t input)
    {
        uint64_t result;

        if (segment.img.active)
        {
            result = input - cast(uint64_t) (cast(memory_stream)segment.img.file).base_address;
            return result;
        }

        result = segment.RVA2file(input);
        return result;
    }

    uint index(ref Dyn d)
        { return d[d.d_tag]; }

    void finalize()
    {
        if (h_buckets.length && symbase)
            segment.img.link(symbols, h_chains.length, convert(symbase));

        if (strbase && strsize)
            segment.img.link_b(strings, strsize, convert(strbase));

        if (rbase && rsize)
            segment.img.link_b(reloc, rsize, convert(rbase));

        if (rbase_a && rsize_a)
            segment.img.link_b(reloc_a, rsize_a, convert(rbase_a));

        if (rbase_p && rsize_p && PLT_type == DT_REL)
            segment.img.link_b(PLT_rel, rsize_p, convert(rbase_p));

        else if (rbase_p && rsize_p && PLT_type == DT_RELA)
            segment.img.link_b(PLT_rela, rsize_p, convert(rbase_p));
    }

    Sym* symbol_lookup(string query)
        { return segment.img.symbol_lookup(query, symbols, h_buckets, h_chains, strings); }

    char[] string_lookup(size_t index)
        { return .string_lookup(index, strings); }
}


class SHT : mine!(Shdr)
{
    image           img;
    char[]          strings;
    Shdr*[string]   sections;


    this(image img, uint[] mask = пусто)
    {
        this.img = img;

        if (mask)
            this.reduceto(mask);
    }

    uint index(ref Shdr s)
        { return s[s.sh_type]; };

    void finalize()
    {
        uint64_t i = img.header[Ehdr.e_shstrndx];
        uint64_t x = (i != SHN_XINDEX) ? i : data[0][Shdr.sh_link];

        img.link_b(strings, data[x][Shdr.sh_size], data[x][Shdr.sh_offset]);

        foreach(ref section; data)
        {
            char[] index = string_lookup(section[Shdr.sh_name], strings);

            if (index)
                sections[cast(string)index] = &section;
        }
    }

    Shdr*
    opIndex(string name)
    {
        Shdr** section = name in sections;

        if (section)
            return *section;

        return пусто;
    }

}

/*
    struct linkmap
    {
        Addr     l_addr;      // Base address shared object is loaded at.
        char*    l_name;      // Absolute file name object was found in.
        Dyn*     l_ld;        // Dynamic section of the shared object.
        linkmap* l_next;
        linkmap* l_prev;      // Chain of loaded objects.

        int opApply(int delegate(ref linkmap) dg)
        {
            int result = 0;

            for (linkmap* l = this; l; l = l.l_next)
            {
                result = dg(*l);

                if (result)
                    break;
            }
            return result;
        }

        int opApplyReverse(int delegate(ref linkmap) dg)
        {
            int result = 0;

            for (linkmap* l = this; l; l = l.l_prev)
            {
                result = dg(*l);

                if (result)
                    break;
            }
            return result;
        }

        /
        string
        toString()
        {
            return format(" %-40.40s  %08x   %08x", l_name[0 .. strlen(l_name)], l_addr, l_ld);
        }
        /
    };
    */




char[]
string_lookup(size_t index, char[] table)
in {
    assert(index >= 0);
    assert(index < table.length);

} body
{
    char*  s = &table[index];
    size_t n = cidrus.strlen(s);

    if (n)
        return table[index .. index + n];

    return [];
}


uint32_t
symbol_hash(string name)
{
    uint32_t hash;
    uint32_t tmp;

    foreach (ubyte c; cast(ubyte[]) name)
    {
        hash  = (hash << 4) + c;
        tmp   = hash & 0xf0000000;
        hash ^= tmp;
        hash ^= tmp >> 24;
    }
    return hash;
}

/*
alias ELF_platform!(ELFCLASS64) ELF64;
alias ELF_platform!(ELFCLASS32) ELF32;

version(X86)     alias ELF_platform!(ELFCLASS32) ELF_native;
version(X86_64)  alias ELF_platform!(ELFCLASS64) ELF_native;
*/

ubyte ST_BIND(ref Sym s)        { return s[s.st_info] >> 4; }
ubyte ST_TYPE(ref Sym s)        { return s[s.st_info] & 0xf; }
ubyte ST_INFO(ubyte A, ubyte B) { return (B << 4) + (B & 0xf); }

uint64_t R_SYM(ref Rel r)   { return (r.type == TYPE_ELF32) ? r[r.r_info] >> 8   : r[r.r_info] >> 32; }
uint64_t R_SYM(ref Rela r)  { return (r.type == TYPE_ELF32) ? r[r.r_info] >> 8   : r[r.r_info] >> 32; }
uint64_t R_TYPE(ref Rel r)  { return (r.type == TYPE_ELF32) ? r[r.r_info] & 0xff : r[r.r_info] & 0xffffffff; }
uint64_t R_TYPE(ref Rela r) { return (r.type == TYPE_ELF32) ? r[r.r_info] & 0xff : r[r.r_info] & 0xffffffff; }

uint64_t R_INFO (ref Rel R, uint64_t A, uint64_t B)
    { return (R.type == TYPE_ELF32) ? (A << 8) + (B & 0xff) : (A << 32) + (B); };

uint64_t R_INFO (ref Rela R, uint64_t A, uint64_t B)
    { return (R.type == TYPE_ELF32) ? (A << 8) + (B & 0xff) : (A << 32) + (B); };


