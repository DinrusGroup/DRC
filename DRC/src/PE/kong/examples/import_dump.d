/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 example: extracting import data from dlls.
*/
/* depends:
 * internal/core_stream.d
 * internal/image_interface.d
 * PE/PE.d
 * PE/types.d
 */

import kong.PE.PE;
import kong.internal.stdlib;

alias PE_platform!(IMAGE_FILE_MACHINE_I386)  PE_native;

void
main(string[] argv)
{
    if (argv.length != 2)
    {
        print!("%s")("usage: impdump.exe <target.dll>");
        return;
    }

    auto image = new PE_native.image(argv[1], IO_MODE.RW);
    image.analyze();

    size_t base;
    size_t size;

    with (image.NT.OptionalHeader){
    base = DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].VirtualAddress;
    size = DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT].Size;
    }

    IMAGE_IMPORT_DESCRIPTOR[] imps;

    foreach (IMAGE_IMPORT_DESCRIPTOR imp; image.link_b(imps, size, image.RVA2file(base)))
    {
        if (imp.Characteristics == 0)
            break;

        string name = image.read_stringz(image.RVA2file(imp.Name));
        print!(
          "\n ---- %s ----\n"
          " - OriginalFirstThunk  %08x\n"
          " - TimeDateStamp       %08x\n"
          " - ForwarderChain      %08x\n"
          " - FirstThunk          %08x\n"
          "\n  Imports:\n")(
          name,
          imp.OriginalFirstThunk,
          imp.TimeDateStamp,
          imp.ForwarderChain,
          imp.FirstThunk
        );

        uintptr_t thunk_data, func_data;
        ulong thunk_pos, func_pos;

        if (imp.OriginalFirstThunk)
        {
            thunk_pos = image.RVA2file(imp.OriginalFirstThunk);
            func_pos  = image.RVA2file(imp.FirstThunk);

        } else // no hint table
        {
            thunk_pos = image.RVA2file(imp.FirstThunk);
            func_pos  = image.RVA2file(imp.FirstThunk);
        }


        for (ulong offset = 0;; offset += uint32_t.sizeof)
        {

            image.copy(thunk_data, thunk_pos + offset);

            if (thunk_pos == func_pos)
                func_data = thunk_data;

            else
                image.copy(func_data, func_pos + offset);

            if (thunk_data == 0)
                break;

            if (IMAGE_SNAP_BY_ORDINAL(thunk_data))
                continue;


            thunk_data = image.RVA2file(thunk_data);
            // func_data = image.RVA2file(func_data); this is invalid for some dlls... why?

            print!("  * %s")(image.read_stringz(thunk_data + IMAGE_IMPORT_BY_NAME.Name.offsetof));
        }

    }
}
