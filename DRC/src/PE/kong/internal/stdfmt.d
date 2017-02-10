/*
  6        _._    (     _/
    6    c(@@ )o __)   _/  _/      _/_/    _/_/_/      _/_/_/
  6     __('_  (      _/_/      _/    _/  _/    _/  _/    _/
       q  /. )_)     _/  _/    _/    _/  _/    _/  _/    _/
         /( (       _/    _/    _/_/    _/    _/    _/_/_/
 2007    m  m                                          _/
 public domain : N. Alexander <wqeqweuqy@hotmail> _/_/

 file : kong.internal.stdfmt : Printf -> .NET format string
        compile time conversion.
*/

module kong.internal.stdfmt;
//TODO: escape { and } in fmt strings

version (Tango):

private enum : uint
{
FLdash = 1,
FLplus = 2,
FLspace = 4,
FLhash = 8,
FLlngdbl = 0x20,
FLzpad = 0x40,
FLprecision = 0x80,
}

private  char[] parse(char[] s)
{
    char[] x;
    char[] width, precision;
    char type = '?';

    int i;
    uint flags = 0;

    for (i = 1; type == '?'; ++i)
    {
        switch (s[i]){
        case '-': flags |= FLdash; break;
        case '#': flags |= FLhash; break;
        case '0': flags |= FLzpad; break;
        case '+': assert(0); // unsupported
        case ' ': assert(0); // unsupported

        default:

            if (s[i] == '*')
                assert(0); // unsupported

            if (s[i] >= '0' && s[i] <= '9')
            {
                do width ~= s[i++];
                while (s[i] >= '0' && s[i] <= '9');
            }

            if (s[i] == '.')
            {
                if (s[++i] == '*')
                    assert(0); // unsupported

                else if (s[i] >= '0' && s[i] <= '9')
                {
                    flags |= FLprecision;

                    do precision ~= s[i++];
                    while (s[i] >= '0' && s[i] <= '9');
                }
            }

            type = get_type(s[i]);

            if (type == '%')
                return "%";
        }
    }

    if (flags & FLplus)
        flags &= ~FLspace;

    if (flags & FLdash)
        flags &= ~FLzpad;

    if (flags & FLhash)
    {
        if (type == 'x' || type == 'X')
            x ~= "0x";

        else if (type == 'o')
            x ~= "0";

        // e, E, f, F, g, G decimal not needed?
    }

    x ~= "{";

    if (width && (flags & FLzpad) == 0)
    {
        x ~= ',';

        if (flags & FLdash)
            x ~= '-';

        x ~= width;
    }

    if (type != 's')
    {
        x ~= ":" ~ type;

        if (flags & FLzpad)
            x ~= width;

        if (flags & FLprecision)
            x ~= precision;
    }

    x ~= '}';


    return x;
}

private char get_type(char c)
{
    switch (c){
    case '%': return '%';
    case 'c': return 'c';
    case 'u': return 'u';
    case 'o': return 'o';
    case 'x': return 'x';
    case 'X': return 'X';
    case 's': return 's';
    case 'i':
    case 'd': return 'd';
    case 'e': return 'e';
    case 'E': return 'E';
    case 'f': return 'f';
    case 'F': return 'F';
    case 'g': return 'g';
    case 'G': return 'G';
    case 'p': return 'x';
    case 'a':
    case 'A': assert(0);
    default : return '?';
    }
}

private int skip(char[] s)
{
    int n = 1;

    for (char t = '?'; t == '?'; ++n)
        t = get_type(s[n]);

    return n;
}

template FMT(char[] s)
{
    static if (s.length == 0)
        const char[] FMT = s;
    else
    {
        static if (s[0] == '{')
            const char[] FMT = "{{" ~ FMT!(s[2 .. $]);

        else static if (s[0] == '}')
            const char[] FMT = "}}" ~ FMT!(s[2 .. $]);

        else static if (s[0] == '%')
            const char[] FMT = parse(s) ~ FMT!(s[skip(s) .. $]);

        else
            const char[] FMT = s[0] ~ FMT!(s[1 .. $]);
    }
}






