/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module common;

public import tango.io.Stdout;
public import tango.text.convert.Layout;
//import tango.io.stream.Format;

alias Stdout выдай;
//alias tango.io.stream.Format.FormatOutput.nl новстр;
/// Ткст aliases.
//alias сим[] ткст;
//alias шим[] wstring; /// определено
//alias дим[] dstring; /// определено

/// Global formatter instance.
static Layout!(сим) Формат;
static this()
{
  Формат = new typeof(Формат);
}
