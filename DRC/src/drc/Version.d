/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.Version;

private ткст вТкст(бцел x)
{
  ткст ткт;
  do
    ткт = cast(сим)('0' + (x % 10)) ~ ткт;
  while (x /= 10)
  return ткт;
}

private ткст вТкст(бцел x, бцел pad)
{
  ткст ткт = вТкст(x);
  if (pad > ткт.length)
    for (бцел i = pad-ткт.length; i; i--)
      ткт = "0" ~ ткт;
  return ткт;
}

version(D2)
  const бцел VERSION_MAJOR_DEFAULT = 2;
else
  const бцел VERSION_MAJOR_DEFAULT = 1;

/// The major version число of this compiler.
const бцел ВЕРСИЯ_МАЖОР = VERSION_MAJOR_DEFAULT;
/// The minor version число of this compiler.
const бцел ВЕРСИЯ_МИНОР = 0;
/// The compiler version formatted as a ткст.
const ткст ВЕРСИЯ = вТкст(ВЕРСИЯ_МАЖОР)~"."~вТкст(ВЕРСИЯ_МИНОР, 3);
/// The имя of the compiler.
const ткст ПОСТАВЩИК = "Dinrus Group";
