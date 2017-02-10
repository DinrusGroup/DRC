/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 example: extending default ELF miner's behavior.
*/

/* depends:
 * internal/core_stream.d
 * internal/image_interface.d
 * ELF/ELF.d
 * ELF/types.d
 */


import kong.ELF.ELF;
import kong.internal.stdlib;



class _PT : PT
{
    this(image img)
    {  .print!("%s")("PT_CONSTRUCTOR");
        super(img, new _DT(this, img));
        table[PT_LOAD] = &xPT_LOAD;
    }

    void xPT_LOAD(inout Phdr p)
    {
        .print!("PT_LOAD: %08x - %08x (%d bytes) | file @ %08x (%d bytes)")
        (p[p.p_vaddr], (p[p.p_vaddr] + p[p.p_memsz]), p[p.p_memsz], p[p.p_offset], p[p.p_filesz]);
    }
}

class _DT : DT
{
    this(_PT pt, image img){ super(pt, img); }

    void finalize()
    {
        super.finalize();

        if (symbols)
        {
            .print!("\n\nSYMBOLS (%d):\n\n %-40s  %-8s  TYPE  BIND  SIZE ")(symbols.length, "SYMBOL NAME", "VALUE");

            foreach (ref Sym symbol; symbols)
                .print!(" %-40.40s  %08x   %02d    %02d   %04x ")
                (
                    string_lookup(symbol[Sym.st_name]),
                    symbol[Sym.st_value], ST_TYPE(symbol), ST_BIND(symbol),
                    symbol[Sym.st_size]
                );
        }

        if (reloc)
        {
            .print!("\n\nRELOCATIONS (%d):\n\n %-40s  OFFSET    TYPE ")
                (reloc.length, "SYMBOL NAME");

            foreach (ref Rel r; reloc)
                .print!(" %-40.40s  %08x   %02d")
                (
                    string_lookup(
                    symbols[R_SYM(r)][Sym.st_name]),
                    r[r.r_offset],
                    R_TYPE(r)
                );
        }

        if (reloc_a)
        {
            .print!("\n\nRELOCATIONS (%d) [addends]:\n\n %-40s  OFFSET    TYPE  ADDEND")
                (reloc_a.length, "SYMBOL NAME");

            foreach (ref Rela r; reloc_a)
                .print!(" %-40.40s  %08x   %02d   %08x")
                (
                    string_lookup(symbols[R_SYM(r)][Sym.st_name]),
                    r[r.r_offset], R_TYPE(r),
                    r[r.r_addend]
                );

        }

        .print!("%s")("\n\nIMPORTS:\n");

        foreach (index; depends)
            .print!("> %s")(string_lookup(index));

    }
}

class _SHT : SHT
{
    this(image img){ .print!("%s")("SHT_CONSTRUCTOR"); super(img); }

    void finalize()
    {
        super.finalize();

        .print!("%s")("\n\nSECTIONS:\n");

        foreach (name, index; sections)
            .print!("%s")(name);
    }

}



void
main(string argv[])
{
    if (argv.length != 2)
    {
        .print!("%s")("usage: elf_dump <target>");
        return;
    }
    image i = new image(argv[1], IO_MODE.R);
        
    _PT  p = new _PT(i);
    _SHT s = new _SHT(i);

    i.analyze(p, s);
}


