/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module drc.lexer.IdentsGenerator;

/// Таблица предопределенных идентификаторов.
///
/// Формат ('#' начинает комментарии):
/// $(PRE
/// ПредопределенныйИдентификатор := ИмяИсхКода (":" ТекстИда)?
/// ИмяИсхКода := Идентификатор # Имя, которое будет использоваться в исходном коде.
/// ТекстИда := Пусто | Идентификатор # Действительный текст идентификатора.
/// Пусто := ""                  # ТекстИда может быть пустым.
/// Идентификатор := см. модуль $(MODLINK drc.lexer.Identifier).
/// )
/// Если ТекстИда не указан, то дефолтом является ИмяИсхКода.
private static const сим[][] предопрИденты = [
  // Специальный пустой идентификатор:
  "Пусто:",
  // Предопределенные идентификаторы версии:
  "DigitalMars", "X86", "X86_64",
  /*"Windows", */"Win32", "Win64",
  "Linux:linux", "LittleEndian", "BigEndian",
  "D_Coverage", "D_InlineAsm_X86", "D_Version2",
  "none", "all",
  // Вариадические параметры:
  "Аргументы:_arguments", "Аргук:_argptr",
  // масштаб(Идентификатор):
  "выход", "успех", "сбой", "exit", "success", "failure",
  // pragma:
  "сооб", "lib", "startaddress", "msg",
  // Linkage:
  "C", "D", "Windows", "Pascal", "System",
  // Con-/Destructor:
  "Ктор:__ctor", "Дтор:__dtor",
  // new() and delete() methods.
  "Нов:__new", "Удалить:__delete",
  // Юниттест and invariant.
  "Юниттест:__unittest", "Инвариант:__invariant",
  // Operator overload methods:
  "opNeg", "opPos", "opCom",
  "opEquals", "opCmp",  "opAssign",
  "opAdd",  "opAdd_r",  "opAddAssign",
  "opSub",  "opSub_r",  "opSubAssign",
  "opMul",  "opMul_r",  "opMulAssign",
  "opDiv",  "opDiv_r",  "opDivAssign",
  "opMod",  "opMod_r",  "opModAssign",
  "opAnd",  "opAnd_r",  "opAndAssign",
  "opOr",   "opOr_r",   "opOrAssign",
  "opXor",  "opXor_r",  "opXorAssign",
  "opShl",  "opShl_r",  "opShlAssign",
  "opShr",  "opShr_r",  "opShrAssign",
  "opUShr", "opUShr_r", "opUShrAssign",
  "opCat",  "opCat_r",  "opCatAssign",
  "opIn",   "opIn_r",
  "opIndex", "opIndexAssign",
  "opSlice", "opSliceAssign",
  "opPostInc",
  "opPostDec",
  "opCall",
  "opCast",
  "opStar", // D2
  // foreach and foreach_reverse:
  "opApply", "opApplyReverse",
  // Entry function:
  "main",
  // ASM identifiers:
  "near", "far", "word", "dword", "qword",
  "ptr", "offset", "seg", "__LOCAL_SIZE",
  "FS", "ST",
  "AL", "AH", "AX", "EAX",
  "BL", "BH", "BX", "EBX",
  "CL", "CH", "CX", "ECX",
  "DL", "DH", "DX", "EDX",
  "BP", "EBP", "SP", "ESP",
  "DI", "EDI", "SI", "ESI",
  "ES", "CS", "SS", "DS", "GS",
  "CR0", "CR2", "CR3", "CR4",
  "DR0", "DR1", "DR2", "DR3", "DR6", "DR7",
  "TR3", "TR4", "TR5", "TR6", "TR7",
  "MM0", "MM1", "MM2", "MM3",
  "MM4", "MM5", "MM6", "MM7",
  "XMM0", "XMM1", "XMM2", "XMM3",
  "XMM4", "XMM5", "XMM6", "XMM7",
];

сим[][] дайПару(сим[] текстИда)
{
  foreach (i, c; текстИда)
    if (c == ':')
      return [текстИда[0..i], текстИда[i+1..текстИда.length]];
  return [текстИда, текстИда];
}

unittest
{
  static assert(
    дайПару("test") == ["test", "test"] &&
    дайПару("test:tset") == ["test", "tset"] &&
    дайПару("empty:") == ["empty", ""]
  );
}

/++
  CTF для генерации членов структуры Идент.

  Результирующий текст выглядить примерно так:
  ---
  private struct Иды {static const:
    Идентификатор _Empty = {"", TOK.Идентификатор, ВИД.Пусто};
    Идентификатор _main = {"main", TOK.Идентификатор, ВИД.main};
    // etc.
  }
  Идентификатор* Пусто = &Иды._Empty;
  Идентификатор* main = &Иды._main;
  // etc.
  private Идентификатор*[] __allIds = [
    Пусто,
    main,
    // и т.д.
  ];
  ---
+/
сим[] генерируйЧленыИдент()
{
  сим[] приват_члены = "private struct Иды {static const:";
  сим[] публ_члены = "";
  сим[] массив = "private Идентификатор*[] __allIds = [";

  foreach (идент; предопрИденты)
  {
    сим[][] пара = дайПару(идент);
    // Идентификатор _name = {"имя", TOK.Идентификатор, ID.имя};
    приват_члены ~= "Идентификатор _"~пара[0]~` = {"`~пара[1]~`", TOK.Идентификатор, ВИД.`~пара[0]~"};\n";
    // Идентификатор* имя = &_name;
    публ_члены ~= "Идентификатор* "~пара[0]~" = &Иды._"~пара[0]~";\n";
    массив ~= пара[0]~",";
  }

  приват_члены ~= "}"; // Close private {
  массив ~= "];";

  return приват_члены ~ публ_члены ~ массив;
}

/// CTF for generating the члены of the enum ВИД.
сим[] генерируйЧленыИД()
{
  сим[] члены;
  foreach (идент; предопрИденты)
    члены ~= дайПару(идент)[0] ~ ",\n";
  return члены;
}

// pragma(сооб, генерируйЧленыИдент());
// pragma(сооб, генерируйЧленыИД());
