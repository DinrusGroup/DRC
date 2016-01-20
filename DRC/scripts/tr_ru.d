#!/usr/bin/rdmd
/++
  Author: Aziz Köksal
  License: GPL3
+/
module TypeRules;

import tango.io.Stdout;

alias Stdout выдай;

void main(char[][] args)
{
  выдай(
    `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">`\n
    `<html>`\n
    `<head>`\n
    `  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">`\n
    `  <link href="" rel="stylesheet" type="text/css">`\n
    `  <style type="text/css">`\n
    `    .E { color: darkred; } /* Error */`\n
    `    .R { font-size: 0.8em; } /* Result */`\n
    `    .X { color: darkorange; }`\n
    `    .Y { color: darkblue; }`\n
    `  </style>`\n
    `</head>`\n
    `<body>`\n
    `<p>Следующая таблица показывает типовые результаты различных выражений. Использован компилятор: `
  );

  выдай.format("{} {}.{,:d3}.</p>\n", __VENDOR__, __VERSION__/1000, __VERSION__%1000);

  выдай.format("<table>\n<tr><th colspan=\"{}\">Унарные Выражения</th></tr>\n", unaryExpressions.length);
  выдай("<tr><td><!--typecol--></td>");
  foreach (unaryExpression; unaryExpressions)
    выдай.format("<td>{}</td>", {
      if (unaryExpression[0] == 'x')
        return `<span class="X">x</span>` ~ xml_escape(unaryExpression[1..$]);
      else
        return xml_escape(unaryExpression[0..$-1]) ~ `<span class="X">x</span>`;
    }());
  выдай("</tr>\n");
  foreach (i, basicType; basicTypes)
  {
    выдай.format("<tr>\n"`<td class="X">{}</td>`, basicType);
    foreach (expResults; unaryExpsResults)
    {
      auto result =  expResults[i];
      выдай.format(`<td class="R">{}</td>`, result[0] == 'E' ? `<span class="E">Error</span>`[] : result);
    }
    выдай("\n<tr>\n");
  }
  выдай("</table>\n");

  foreach (i, expResults; binaryExpsResults)
  {
    auto binaryExpression = binaryExpressions[i];
    binaryExpression = `<span class="X">x</span> ` ~
                       xml_escape(binaryExpression[1..$-1]) ~
                       ` <span class="Y">y</span>`;
    выдай.format("<table>\n<tr><th colspan=\"{}\">{}</th></tr>\n", basicTypes.length, binaryExpression);
    выдай.format("<tr><td><!--typecol--></td>");
    foreach (basicType; basicTypes)
      выдай.format(`<td class="Y">{}</td>`, basicType);
    выдай("\n<tr>\n");
    foreach (j, results; expResults)
    {
      выдай.format("<tr>\n"`<td class="X">{}</td>`, basicTypes[j]);
      foreach (result; results)
        выдай.format(`<td class="R">{}</td>`, result[0] == 'E' ? `<span class="E">Error</span>`[] : result);
      выдай("\n<tr>\n");
    }
    выдай("</table>\n");
  }

  выдай(
    "\n</body>"
    "\n</html>"
  );
}

/// Escapes the characters '<', '>' and '&' with named character entities.
/// Taken from module cmd.Highlight;
char[] xml_escape(char[] text)
{
  char[] result;
  foreach(c; text)
    switch(c)
    {
      case '<': result ~= "&lt;";  break;
      case '>': result ~= "&gt;";  break;
      case '&': result ~= "&amp;"; break;
      default:  result ~= c;
    }
  if (result.length != text.length)
    return result;
  // Nothing escaped. Return original text.
  delete result;
  return text;
}

char char_; wchar wchar_; dchar dchar_; bool bool_;
byte byte_; ubyte ubyte_; short short_; ushort ushort_;
int int_; uint uint_; long long_; ulong ulong_;
/+cent cent_;   ucent ucent_;+/
float float_; double double_; real real_;
ifloat ifloat_; idouble idouble_; ireal ireal_;
cfloat cfloat_; cdouble cdouble_; creal creal_;

static const char[][] basicTypes = [
  "сим"[],   "шим",   "дим", "бул",
  "байт",   "ббайт",   "крат", "бкрат",
  "цел",    "бцел",    "дол",  "бдол",
  /+"cent",   "ucent",+/
  "плав",  "дво",  "реал",
  "вплав", "вдво", "вреал",
  "кплав", "кдво", "креал"/+, "void"+/
];

static const char[][] unaryExpressions = [
  "!x",
  "&x",
  "~x",
  "+x",
  "-x",
  "++x",
  "--x",
  "x++",
  "x--",
];

static const char[][] binaryExpressions = [
  "x!<>=y",
  "x!<>y",
  "x!<=y",
  "x!<y",
  "x!>=y",
  "x!>y",
  "x<>=y",
  "x<>y",

  "x=y", "x==y", "x!=y",
  "x<=y", "x<y",
  "x>=y", "x>y",
  "x<<=y", "x<<y",
  "x>>=y","x>>y",
  "x>>>=y", "x>>>y",
  "x|=y", "x||y", "x|y",
  "x&=y", "x&&y", "x&y",
  "x+=y", "x+y",
  "x-=y", "x-y",
  "x/=y", "x/y",
  "x*=y", "x*y",
  "x%=y", "x%y",
  "x^=y", "x^y",
  "x~=y",
  "x~y",
  "x,y"
];

template ExpressionType(alias x, alias y, char[] expression)
{
  static if(is(typeof(mixin(expression)) ResultType))
    const char[] result = ResultType.stringof;
  else
    const char[] result = "Ошибка";
}
alias ExpressionType EType;

char[] genBinaryExpArray(char[] expression)
{
  char[] result = "[\n";
  foreach (t1; basicTypes)
  {
    result ~= "[\n";
    foreach (t2; basicTypes)
      result ~= `EType!(`~t1~`_, `~t2~`_, "`~expression~`").result,`\n;
    result[result.length-2] = ']'; // Overwrite last comma.
    result[result.length-1] = ','; // Overwrite last \n.
  }
  result[result.length-1] = ']'; // Overwrite last comma.
  return result;
}
// pragma(msg, mixin(genBinaryExpArray("x%y")).stringof);

char[] genBinaryExpsArray()
{
  char[] result = "[\n";
  foreach (expression; binaryExpressions)
  {
    result ~= genBinaryExpArray(expression);
    result ~= ",\n";
  }
  result[result.length-2] = ']';
  return result;
}

// pragma(msg, mixin(genBinaryExpsArray()).stringof);

char[] genUnaryExpArray(char[] expression)
{
  char[] result = "[\n";
  foreach (t1; basicTypes)
    result ~= `EType!(`~t1~`_, цел_, "`~expression~`").result,`\n;
  result[result.length-2] = ']'; // Overwrite last comma.
  return result;
}

char[] genUnaryExpsArray()
{
  char[] result = "[\n";
  foreach (expression; unaryExpressions)
    result ~= genUnaryExpArray(expression) ~ ",\n";
  result[result.length-2] = ']';
  return result;
}

// pragma(msg, mixin(genUnaryExpsArray()).stringof);

auto unaryExpsResults = mixin(genUnaryExpsArray());
auto binaryExpsResults = mixin(genBinaryExpsArray());

