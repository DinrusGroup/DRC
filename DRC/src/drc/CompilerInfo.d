/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity average)
module drc.CompilerInfo;

public import drc.Version;

/// The global, default alignment размер for struct fields.
const бцел РАЗМЕР_РАСКЛАДКИ_ПО_УМОЛЧАНИЮ = 4;

// TODO: this needs в be in КонтекстКомпиляции, в make
//       cross-compiling possible.
version(DDoc)
  const бцел РАЗМЕР_УК; /// The pointer размер depending on the platform.
else
version(X86_64)
  const бцел РАЗМЕР_УК = 8; // Указатель размер on 64-bit platforms.
else
  const бцел РАЗМЕР_УК = 4; // Указатель размер on 32-bit platforms.
