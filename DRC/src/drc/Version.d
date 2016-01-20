/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.Version;

private сим[] вТкст(бцел x)
{
  сим[] ткт;
  do
    ткт = cast(сим)('0' + (x % 10)) ~ ткт;
  while (x /= 10)
  return ткт;
}

private сим[] вТкст(бцел x, бцел pad)
{
  сим[] ткт = вТкст(x);
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
const бцел VERSION_MAJOR = VERSION_MAJOR_DEFAULT;
/// The minor version число of this compiler.
const бцел VERSION_MINOR = 0;
/// The compiler version formatted as a ткст.
const сим[] ВЕРСИЯ = вТкст(VERSION_MAJOR)~"."~вТкст(VERSION_MINOR, 3);
/// The имя of the compiler.
const сим[] ПОСТАВЩИК = "дил";
