/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.linux.DSO : runtime dynamic library enumeration for linux.
*/

module kong.linux.DSO;

version (linux):
import kong.internal.stdlib;
import kong.internal.dynamic_object;
import kong.ELF.ELF;

version(X86)         { mixin ELF_types!(ELFCLASS32); }
else version(X86_64) { mixin ELF_types!(ELFCLASS64); }
else                 static assert(0);


void* DSO_resolve(string sym, string so, inout void* handle)
{
    char* str = (so == IMAGE_SELF) ? пусто : toStringz(so);

    if (handle == пусто)
    {
        handle = dlopen(str, RTLD_NOW|RTLD_GLOBAL);

        if (handle == пусто)
            return пусто;
    }

    return dlsym(handle, toStringz(sym));
}

void DSO_free(void *handle)
{
    dlclose(handle);
}


struct dl_phdr_info
{
    _Addr    dlpi_addr;
    char*    dlpi_name;
    _Phdr*   dlpi_phdr;
    _Half    dlpi_phnum;

    /* Note: Following members were introduced after the first
     * version of this structure was available.  Check the SIZE
     * argument passed to the dl_iterate_phdr callback to determine
     * whether or not each later member is available.
     */

    uint64_t  dlpi_adds;        // Incremented when a new object may have been added.
    uint64_t  dlpi_subs;        // Incremented when an object may have been removed.
    size_t    dlpi_tls_modid;   // If there is a PT_TLS segment, its module ID as used in TLS relocations, else zero.

    /* The address of the calling thread's instance of this module's
     * PT_TLS segment, if it has one and it has been allocated
     * in the calling thread, otherwise a пусто pointer.
     */

    void *dlpi_tls_data;

    _Phdr[]
    segments()
    {
        /*
         * - dlpi_phdr[] doesnt store real addresses (offsets only).
         * - dlpi_phdr[] isnt write-able (?)
         */

        _Phdr[] segments;
        segments.length = dlpi_phnum;

        for (size_t j = 0; j < segments.length; j++)
        {
            segments[j] = dlpi_phdr[j];
            segments[j].p_vaddr = segments[j].p_vaddr + dlpi_addr;
        }

        return segments;
    }

};



struct
DSO_list
{
    static
    dynamic_object[]
    opSlice()
    {
        d_context da;
        dl_iterate_phdr(&callback, cast(void*) &da);

        return da.table;
    }

    static
    dynamic_object*
    opIndex(string name)
    {
        d_context da;
        da.match = name;
        dl_iterate_phdr(&callback, cast(void*) &da);

        return (da.table.length) ? &da.table[0] : пусто;
    }

}


extern (C):
// ----------------------------------------------------------------

int dl_iterate_phdr(int (*)(dl_phdr_info*, size_t, void *), void *);

private struct d_context
{
    string match;
    dynamic_object[] table;
    uint passes;
}


private
int
callback(dl_phdr_info* info, size_t size, void *data)
in
{
    assert(info);
    assert(data);
    assert(size >= dl_phdr_info.sizeof);

} body
{
    dynamic_object obj;
    d_context* ctx = cast(d_context*) data;
    obj.address    = cast(void*) info.dlpi_addr;

    ++ctx.passes;

    if      (!obj.address && ctx.passes == 1) obj.name = IMAGE_SELF;
    else if (!obj.address && ctx.passes == 2) obj.name = IMAGE_KERNEL;
    else
        obj.name = cast(string) info.dlpi_name[0 .. strlen(info.dlpi_name)];


    if (ctx.match && !path_match(obj.name, ctx.match))
        return 0;

    if (!obj.address)
    {
        foreach (ref _Phdr segment; info.segments())
        {
            // obj.address is пусто for IMAGE_SELF, IMAGE_KENREL.
            if (segment.p_type == PT_LOAD && segment.p_offset == 0)
                obj.address = cast(void*) segment.p_vaddr;

            else if (segment.p_type == PT_NULL)
                break;
        }
    }

    obj.image = new image(obj.address, true);
    ctx.table ~= obj;
    return (ctx.match) ? -1 : 0;
}

enum {
RTLD_LAZY         = 0x00001,
RTLD_NOW          = 0x00002,
RTLD_BINDING_MASK = 0x3,
RTLD_NOLOAD       = 0x00004,
RTLD_DEEPBIND     = 0x00008,
RTLD_GLOBAL       = 0x00100,
RTLD_LOCAL        = 0,
RTLD_NODELETE     = 0x01000,
}

void *dlopen(char *filename, int flag);
char *dlerror();
void *dlsym(void *handle, char *symbol);
int dlclose(void *handle);

