/// Карта докэлементов и сем Динрус для форматирования текстов.
ткст[ткст] карта = [
  "ЗаголовокДок" : `<!DOCTYPE XML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">`\n
              `<html>`\n
              `<head>`\n
              `  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">`\n
              `  <title>{0}</title>`\n
              `  <link href="html.css" rel="stylesheet" type="text/css">`\n
              `</head>`\n
              `<body>`\n
              `<table><tr>`\n,
  "НачалоКомп"   : `<td><div class="compilerinfo">`\n,
  "КонецКомп"     : "</div>\n</td></tr><tr>",
  "ОшибкаЛексера"  : `<p class="error L">{0}({1},{2})L: {3}</p>`\n,
  "ОшибкаПарсера" : `<p class="error P">{0}({1},{2})P: {3}</p>`\n,

  "НачалоНомераСтроки" : `<td class="linescolumn">`,
  "КонецНомераСтроки"   : "</td>\n<td>",
  "НомерСтроки"      : `<a id="L{0}" href="#L{0}">{0}</a>`,

  "НачалоИсходника" : `<td><pre class="sourcecode">`\n,
  "КонецИсходника"   : "\n</pre></td>",

  "КонецДок"  : "\n</tr></table>"
              "\n</body>"
              "\n</html>",

  // Node categories:
  "Декларация" : "d",
  "Инструкция"   : "s",
  "Выражение"  : "в",
  "Тип"        : "t",
  "Иное"       : "o",

  // {0} = категория узла.
  // {1} = имя класса узла: "Call", "Если", "Class" etc.
  // E.g.: <span class="d Struct">...</d>
  "НачалоУзла" : `<span class="{0} {1}">`,
  "КонецУзла"   : `</span>`,

  "Идентификатор" : `<span class="i">{0}</span>`,
  "Ткст"     : `<span class="sl">{0}</span>`,
  "Сим"       : `<span class="cl">{0}</span>`,
  "Число"     : `<span class="n">{0}</span>`,
  "КСлово"    : `<span class="k">{0}</span>`,

  "LineC"   : `<span class="lc">{0}</span>`,
  "BlockC"  : `<span class="bc">{0}</span>`,
  "NestedC" : `<span class="nc">{0}</span>`,

  "Шебанг"  : `<span class="shebang">{0}</span>`,
  "HLine"    : `<span class="hl">{0}</span>`, // #line
  "Filespec" : `<span class="fs">{0}</span>`, // #line N "filespec"
  "НовСтр"  : "{0}", // \n | \r | \r\n | РС | РА
  "Нелегал"  : `<span class="ill">{0}</span>`, // Символ, не распознаваемый лексером.

  "ОсобаяСема" : `<span class="st">{0}</span>`, // __FILE__, __LINE__ etc.

  "("    : "(",
  ")"    : ")",
  "["    : "[",
  "]"    : "]",
  "{"    : "{",
  "}"    : "}",
  "."    : ".",
  ".."   : "..",
  "..."  : "...",
  "!<>=" : "!&lt;&gt;=", // Unordered
  "!<>"  : "!&lt;&gt;",  // UorE
  "!<="  : "!&lt;=",     // UorG
  "!<"   : "!&lt;",      // UorGorE
  "!>="  : "!&gt;=",     // UorL
  "!>"   : "!&gt;",      // UorLorE
  "<>="  : "&lt;&gt;=",  // LorEorG
  "<>"   : "&lt;&gt;",   // LorG
  "="    : "=",
  "=="   : "==",
  "!"    : "!",
  "!="   : "!=",
  "<="   : "&lt;=",
  "<"    : "&lt;",
  ">="   : "&gt;=",
  ">"    : "&gt;",
  "<<="  : "&lt;&lt;=",
  "<<"   : "&lt;&lt;",
  ">>="  : "&gt;&gt;=",
  ">>"   : "&gt;&gt;",
  ">>>=" : "&gt;&gt;&gt;=",
  ">>>"  : "&gt;&gt;&gt;",
  "|"    : "|",
  "||"   : "||",
  "|="   : "|=",
  "&"    : "&amp;",
  "&&"   : "&amp;&amp;",
  "&="   : "&amp;=",
  "+"    : "+",
  "++"   : "++",
  "+="   : "+=",
  "-"    : "-",
  "--"   : "--",
  "-="   : "-=",
  "/"    : "/",
  "/="   : "/=",
  "*"    : "*",
  "*="   : "*=",
  "%"    : "%",
  "%="   : "%=",
  "^"    : "^",
  "^="   : "^=",
  "~"    : "~",
  "~="   : "~=",
  ":"    : ":",
  ";"    : ";",
  "?"    : "?",
  ","    : ",",
  "$"    : "$",
  "КФ"  : ""
];
