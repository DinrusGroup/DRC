/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.ELF.hook_api : PLT|GOT style hooks.
*/

module kong.ELF.hook_api;
import kong.ELF.ELF;
import kong.internal.stdlib;
import kong.internal.hook_interface;
import kong.internal.dynamic_object;
import kong.process;

class ELF_apihook : hook_chain
{
    private:

    void*[]   saved;
    void**    GOT_slot;
    Rel*      reloc;
    uint64_t  offset;

    public:

    this(void* callback, string query, dynamic_object* obj)
    in
    {
        assert(obj);
        assert(query);

    } body
    {
        reloc = find_reloc(obj, query);

        if (reloc == пусто)
            throw new hook_exception(hook_exception.ERROR.NOTFOUND);

        GOT_slot = cast(void**) (*reloc)[Rel.r_offset];
        saved   ~= *GOT_slot;
        offset   = (*reloc)[Rel.r_offset];

        /*
         * 1: Modifying the relocaton record causes the Runtime
         *    Dynamic Linker to record the address of the real function
         *    here, inside saved[0], instead of the Global Offset Table.
         *    This happens the first time the function gets called.
         *
         * 2: Manually patch the GOT entry with our callback.
         */
        force_access(reloc.address,
            memory_region.ACCESS.WRITE |
            memory_region.ACCESS.READ |
            memory_region.ACCESS.EXEC);

        (*reloc)[Rel.r_offset] = cast(uint64_t) &saved[0];
        *GOT_slot = callback;
    }

    void*
    original_function()
    {
        return cast(void*) saved[0];
    }

    void*
    push(void* callback)
    {
        void* entry  = *GOT_slot;
        saved       ~= entry;
        *GOT_slot    = callback;

        return entry;
    }

    bool pop()
    in
    {
        assert(saved.length != 0);

    } body
    {
        *GOT_slot    = saved[$ - 1];
        saved.length = saved.length - 1;

        if (saved.length == 0)
            (*reloc)[Rel.r_offset] = offset;

        return (saved.length != 0);
    }


    static Rel*
    find_reloc(dynamic_object* obj, string query)
    {
        image image = cast(image) obj.image;
        PT data;
        Sym* symbol;

        data = new PT(image, [DT_STRSZ, DT_STRTAB, DT_SYMTAB, DT_JMPREL, DT_PLTRELSZ, DT_PLTREL, DT_HASH]);
        image.analyze(data);

        if (!data)
            throw new hook_exception(hook_exception.ERROR.NOTFOUND);

        with (data.dynamic)
        {
            symbol = symbol_lookup(query);

            if (!symbol || ST_TYPE(*symbol) != STT_FUNC)
                throw new hook_exception(hook_exception.ERROR.NOTFOUND);

            if (PLT_type == DT_REL)
                return image.PLT_lookup(PLT_rel, *symbol, symbols);

            else if (PLT_type == DT_RELA)
                return cast(Rel*) image.PLT_lookup(PLT_rela, *symbol, symbols);
        }
    }

}

alias ELF_apihook apihook_chain;

