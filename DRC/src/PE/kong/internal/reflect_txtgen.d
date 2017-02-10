/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.internal.reflect_txtgen : generates
        proxy structures that wrap 32/64bit structs
        and endian conversion.
*/

version (Tango)          { alias char[] string; }
else version (D_Version2){ }
else                     { alias char[] string; }

const string opIndex =
    "uint64_t opIndex(int i)
    in
    { assert(address != пусто);
    } body
    {
        uint64_t val;

        copy(&val, address + offset[type][i], size[type][i]);
        return val;
    }";


const string opIndexAssign =
    "void opIndexAssign(uint64_t val, int i)
    in
    { assert(address != пусто);
    } body
    {
        copy(address + offset[type][i], &val, size[type][i]);
    }";


const string tsize =
    "ushort tsize(){ return t_size[type]; }";


string
__body__(string name, string types, string table)
{
    return
    "struct "~name~"
    {
        union { "~ types ~" void* address; void* __R3FL3CTtyp31d__; }
        short type;
        extern(C) void* function(void* dst, void* src, size_t n) copy;
        "
        ~ table
        ~ opIndex
        ~ opIndexAssign
        ~ tsize
        ~ "
    }";
}




string __types__(string[] types)
{
    string text;

    foreach (type; types)
        text ~= type ~ "* __" ~ type ~ "__;";

    return text;
}

string __table__(string[] types, string[] t)
{
    string text = "enum { ";

    foreach (s; t)
        text ~= s ~ ",";

    text ~= "};";

    text ~= "static const ushort[] t_size = [";
    foreach (type; types)
        text ~= type ~ ".sizeof,";
    text ~= "];";

    text ~= "static const ushort[][] offset = [ ";

    foreach (type; types)
    {
        text ~= "[";

        foreach (s; t)
            text ~= type ~ "." ~ s ~ ".offsetof,";

        text ~= "],";

    }
    text ~= "];";
    text ~= "static const ushort[][] size = [ ";

    foreach (type; types)
    {
        text ~= "[";

        foreach (s; t)
            text ~= type ~ "." ~ s ~ ".sizeof,";

        text ~= "],";
    }
    text ~= "];";

    return text;
}

