module drc.CompilerInfo;

public import drc.Version;

/// Глобальный размер раскладки по умолчанию для полей структуры.
const бцел РАЗМЕР_РАСКЛАДКИ_ПО_УМОЛЧАНИЮ = 4;

// TODO: это должно быть в КонтекстКомпиляции, чтобы сделать
//       возможной кросс-компиляцию.
version(DDoc)
  const бцел РАЗМЕР_УК; /// Размер указателя в зависимости от платформы.
else
version(X86_64)
  const бцел РАЗМЕР_УК = 8; // Размер указателя на 64-битной платформе.
else
  const бцел РАЗМЕР_УК = 4; // Размер указателя на 32-битной платформе.
