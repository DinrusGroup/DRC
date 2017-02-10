// Import table dep hook
// 2007 Neal Alexander <wqeqweuqy@hotmail.com> - public domain
// dmd examples/import_dephook.d PE/pe.d PE/types.d internal/image_interface.d internal/core_stream.d

import kong.PE.PE;
import kong.internal.stdlib;

alias PE_platform!(IMAGE_FILE_MACHINE_I386)  PE_native;



void
main(string[] args)
{
    IMAGE_DATA_DIRECTORY* directory;
    IMAGE_IMPORT_DESCRIPTOR[] imports;

    PE_native.image image;
    aligned_block   block;
    size_t          size;


    if (args.length != 4)
    {
        print!("%s")("usage: dephook.exe <target.dll> <hook.dll> <import_symbol>");
        return;
    }

    string input    = args[1];
    string filename = file_basename(args[2]) ~ "\x00";
    string symbol   = args[3] ~ "\x00";

    image = new PE_native.image(input, IO_MODE.RW);
    image.analyze();

    // check if we can squeeze a new section in
    size = image.sections_offset + ((image.sections.length + 1) * IMAGE_SECTION_HEADER.sizeof);

    if (image.NT.OptionalHeader.SizeOfHeaders < size)
    {
        print!("%s")("Error: Section table is full.");
        return;
    }

    string backup = input ~ ".bak";

    if (file_exists(backup) == 0)
        file_copy(input, backup);

    try
    {
        directory = &image.NT.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
        ulong pos = image.RVA2file(directory.VirtualAddress);
        imports.length = directory.Size / IMAGE_IMPORT_DESCRIPTOR.sizeof;

        print!("> Copying %d import descriptor(s) from %08x  (%08x bytes)")(imports.length, pos, directory.Size);
        image.copy(imports, pos);

        print!("> Extending file (New Section size: %08x)")(image.NT.OptionalHeader.SectionAlignment);
        imports.length = imports.length + 1;
        size  = image.NT.OptionalHeader.SectionAlignment;
        block = image.aligned_extend(size, image.NT.OptionalHeader.FileAlignment);


        IMAGE_SECTION_HEADER header;
        uintptr_t start = image.sections[$-1].VirtualAddress +
                          image.sections[$-1].VirtualSize;

        //header.Name[0 .. IMAGE_SIZEOF_SHORT_NAME] = cast(ubyte[]) ".newimp\x00";
        header.VirtualSize          = image.align_to(size,  image.NT.OptionalHeader.SectionAlignment);
        header.VirtualAddress       = image.align_to(start, image.NT.OptionalHeader.SectionAlignment);
        header.SizeOfRawData        = block.size;
        header.PointerToRawData     = block.offset;
        header.PointerToRelocations = 0;
        header.PointerToLinenumbers = 0;
        header.NumberOfRelocations  = 0;
        header.NumberOfLinenumbers  = 0;
        header.Characteristics      = IMAGE_SCN_CNT_INITIALIZED_DATA|IMAGE_SCN_MEM_READ|IMAGE_SCN_MEM_WRITE;

        directory.VirtualAddress    = header.VirtualAddress;
        directory.Size              = IMAGE_IMPORT_DESCRIPTOR.sizeof * imports.length;

        size_t hdrpos = image.sections_offset + (image.sections.length * IMAGE_SECTION_HEADER.sizeof);

        print!("%s")("> Updating PE header");

        image.NT.FileHeader.NumberOfSections++;
        image.file.write(&header, header.sizeof, hdrpos);
        image.NT.OptionalHeader.SizeOfInitializedData += block.size;
        image.NT.OptionalHeader.SizeOfImage           += block.size;
        image.commit();


        print!("%s")("> Writing new import section");

        ulong offset = block.offset + (IMAGE_IMPORT_DESCRIPTOR.sizeof * imports.length);

        uint32_t thunk_entry = image.file2RVA(offset + filename.length + (4*4), &header);
        uint32_t thunk_end   = 0;
        uint16_t hint        = 0;

        imports[$-2].OriginalFirstThunk = image.file2RVA(offset + filename.length + (4*2), &header);
        imports[$-2].TimeDateStamp      = 0;
        imports[$-2].ForwarderChain     = 0;
        imports[$-2].Name               = image.file2RVA(offset, &header);
        imports[$-2].FirstThunk         = image.file2RVA(offset + filename.length, &header);

        image.write(imports, block.offset);
        image.write(cast(void[]) filename);
        image.file.write(&thunk_entry, thunk_entry.sizeof);
        image.file.write(&thunk_end, thunk_end.sizeof);
        image.file.write(&thunk_entry, thunk_entry.sizeof);
        image.file.write(&thunk_end, thunk_end.sizeof);
        image.file.write(&hint, hint.sizeof);
        image.write(cast(void[]) symbol);

        print!("%s")("> Done");
    }
    catch (Exception e)
    {
        print!("> Error: %s\n> Revert: %s -> %s")(e.msg, file_basename(backup), file_basename(input));
        image.file.close();
        file_copy(backup, input);
    }

}


version (Tango)
{
import tango.io.FilePath;

string file_basename(string path)
    { return FilePath(path).name(); }

int file_exists(string path)
    { return FilePath(path).exists(); }

void file_copy(in string from, in string to)
    { FilePath(to).copy(from); }

} else {

import std.path;
import std.file;

string file_basename(string path)
    { return getBaseName(path); }

int file_exists(string name)
    { return exists(name); }

void file_copy(in string from, in string to)
    { return copy(from, to); }

}

