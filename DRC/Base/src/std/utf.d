module std.utf;
private import std.io, sys.WinFuncs /*rt.console*/, std.string: format;

alias isValidDchar реальноДсим_ли;
alias stride пролёт;
alias toUCSindex вИндексУНC;
alias toUTFindex вИндексУТШ;
alias decode раскодируй;
alias encode кодируй;
alias validate оцени;
alias toUTF8 вЮ8;
alias toUTF16 вЮ16;
alias toUTF32 вЮ32;

/// U+FFFD = �. Используется для замены неверных символов Unicode.
const дим СИМ_ЗАМЕНЫ = '\uFFFD';
const сим[3] СТР_ЗАМЕНЫ = \uFFFD; /// Ditto
/// Неверный символ, возвращается при ошибке.
const дим СИМ_ОШИБКИ = 0xD800;

//debug=utf;		// uncomment to turn on debugging эхо's


class ИсклКодировки:Исключение
{
т_мера индкс;
this(ткст s, т_мера i){индкс = i; super("Неудачная операция с кодировкой UTF: \n"~s,__FILE__, индкс);}
}

/*******************************
 * Test if c is a valid UTF-32 character.
 *
 * \uFFFE and \uFFFF are considered valid by this function,
 * as they are permitted for internal use by an application,
 * but they are not allowed for interchange by the Unicode standard.
 *
 * Returns: true if it is, false if not.
 */

bool isValidDchar(дим c)
{
    return c < СИМ_ОШИБКИ || c > 0xDFFF && c <= 0x10FFFF;
}


ubyte[256] UTF8stride =
[
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
    0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
    0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
    0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
    3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
    4,4,4,4,4,4,4,4,5,5,5,5,6,6,0xFF,0xFF,
];

/**
 * stride() возвращает длину последовательности UTF-8, начиная с индекса i
 * в строке s.
 * Возвращает:
 *	Число байтов в последовательности UTF-8 или
 *	0xFF, означающее что s[i] не является началом последовательности UTF-8.
 */

бцел stride(ткст s, т_мера i)
{
   return UTF8stride[s[i]];
}
	
	

/**
 * stride() returns the length of a UTF-16 sequence starting at index i
 * in string s.
 */

бцел stride(wchar[] s, т_мера i)
{   бцел u = s[i];
    return 1 + (u >= СИМ_ОШИБКИ && u <= 0xDBFF);
}

/**
 * stride() returns the length of a UTF-32 sequence starting at index i
 * in string s.
 * Returns: The return value will always be 1.
 */

бцел stride(дим[] s, т_мера i)
{
    return 1;
}

/*******************************************
 * При наличии индекса i в символьном массиве s[],
 * и предполагая, что этот индекс i находится в начале символа UTF,
 * определяет число символов UCS до этого индекса i.
 */

т_мера toUCSindex(in ткст s, т_мера i)
{
    т_мера n;
    т_мера j;
    
    for (j = 0; j < i; )
    {
        j += stride(s, j);
        n++;
    }
    if (j > i)
    {
      throw new ИсклКодировки("toUCSindex: Неверная последовательность UTF-8", j);
    }
    return n;
}

/** ditto */

т_мера toUCSindex(wchar[] s, т_мера i)
{
    т_мера n;
    т_мера j;

    for (j = 0; j < i; )
    {
	j += stride(s, j);
	n++;
    }
    if (j > i)
    {
	throw new ИсклКодировки("toUCSindex: Неверная последовательность UTF-16", j);
    }
    return n;
}

/** ditto */

т_мера toUCSindex(дим[] s, т_мера i)
{
    return i;
}

/******************************************
 * Given a UCS index n into an array of characters s[], return the UTF index.
 */

т_мера toUTFindex(ткст s, т_мера n)
{
    т_мера i;

    while (n--)
    {
	бцел j = UTF8stride[s[i]];
	if (j == 0xFF)
	    throw new ИсклКодировки("toUTFindex: Неверная последовательность UTF-8", i);
	i += j;
    }
    return i;
}

/** ditto */

т_мера toUTFindex(wchar[] s, т_мера n)
{
    т_мера i;

    while (n--)
    {	wchar u = s[i];

	i += 1 + (u >= СИМ_ОШИБКИ && u <= 0xDBFF);
    }
    return i;
}

/** ditto */

т_мера toUTFindex(дим[] s, т_мера n)
{
    return n;
}

/* =================== Decode ======================= */

/***************
 * Декодирует и возвращает символ, начинающийся по s[инд]. инд 
 * перемещается за декодированный символ.
 * Если символ неверно оформлен, выдаётся ИсклКодировки,
 * а инд остаётся неизменённым.
 */
 
/// Возвращает: да if this is a trail байт of a UTF-8 sequence.
бул ведомыйБайт_ли(ббайт b)
{
  return (b & 0xC0) == 0x80; // 10xx_xxxx
}

/// Возвращает: да if this is a lead байт of a UTF-8 sequence.
бул ведущийБайт_ли(ббайт b)
{
  return (b & 0xC0) == 0xC0; // 11xx_xxxx
}

бул рус_ли(дим б)
 {
	switch(б)
	{
	case 'а':
	case 'б':
	case 'в':
	case 'г':
	case 'д':
	case 'е':
	case 'ё':
	case 'ж':
	case 'з':
	case 'и':
	case 'й':
	case 'к':
	case 'л':
	case 'м':
	case 'н':
	case 'о':
	case 'п':
	case 'р':
	case 'с':
	case 'т':
	case 'у':
	case 'ф':
	case 'х':
	case 'ц':
	case 'ч':
	case 'ш':
	case 'щ':
	case 'ъ':
	case 'ы':
	case 'ь':
	case 'э':
	case 'ю':
	case 'я':
	case 'А':
	case 'Б':
	case 'В':
	case 'Г':
	case 'Д':
	case 'Е':
	case 'Ё':
	case 'Ж':
	case 'З':
	case 'И':
	case 'Й':
	case 'К':
	case 'Л':
	case 'М':
	case 'Н':
	case 'О':
	case 'П':
	case 'Р':
	case 'С':
	case 'Т':
	case 'У':
	case 'Ф':
	case 'Х':
	case 'Ц':
	case 'Ч':
	case 'Ш':
	case 'Щ':
	case 'Ъ':
	case 'Ы':
	case 'Ь':
	case 'Э':
	case 'Ю':
	case 'Я': 
	return true;
	default:
		return false;
	}	

 }
 
бул верноСимвол_ли(дим d)
{
  return d < СИМ_ОШИБКИ || d > 0xDFFF && d <= 0x10FFFF||рус_ли(d);
}

дим раскод(ref сим* ref_p, сим* конец)
in { assert(ref_p && ref_p < конец); }
out(c) { assert(ref_p <= конец && (верноСимвол_ли(c) || c == СИМ_ОШИБКИ)); }
body
{
  сим* p = ref_p;
  дим c = *p;

  if (c < 0x80)
    return ref_p++, c;

  p++; // Move в second байт.
  if (!(p < конец))
    return СИМ_ОШИБКИ;

  // Ошибка if second байт is not a trail байт.
  if (!ведомыйБайт_ли(*p))
    return СИМ_ОШИБКИ;

  // Check for overlong sequences.
  switch (c)
  {
  case 0xE0, // 11100000 100xxxxx
       0xF0, // 11110000 1000xxxx
       0xF8, // 11111000 10000xxx
       0xFC: // 11111100 100000xx
    if ((*p & c) == 0x80)
      return СИМ_ОШИБКИ;
  default:
    if ((c & 0xFE) == 0xC0) // 1100000x
      return СИМ_ОШИБКИ;
  }

  const ткст проверьСледующийБайт = "if (!(++p < конец && ведомыйБайт_ли(*p)))"
                                "  return СИМ_ОШИБКИ;";
  const ткст добавьШестьБит = "c = (c << 6) | *p & 0b0011_1111;";

  // Decode
  if ((c & 0b1110_0000) == 0b1100_0000)
  {
    // 110xxxxx 10xxxxxx
    c &= 0b0001_1111;
    mixin(добавьШестьБит);
  }
  else if ((c & 0b1111_0000) == 0b1110_0000)
  {
    // 1110xxxx 10xxxxxx 10xxxxxx
    c &= 0b0000_1111;
    mixin(добавьШестьБит ~
          проверьСледующийБайт ~ добавьШестьБит);
  }
  else if ((c & 0b1111_1000) == 0b1111_0000)
  {
    // 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
    c &= 0b0000_0111;
    mixin(добавьШестьБит ~
          проверьСледующийБайт ~ добавьШестьБит ~
          проверьСледующийБайт ~ добавьШестьБит);
  }
  else
    // 5 and 6 байт UTF-8 sequences are not allowed yet.
    // 111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
    // 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
    return СИМ_ОШИБКИ;

  assert(ведомыйБайт_ли(*p));

  if (!верноСимвол_ли(c))
    return СИМ_ОШИБКИ;
  ref_p = p+1;
  return c;
}

дим decode(ткст ткт, ref т_мера индекс)
in { assert(ткт.length && индекс < ткт.length); }
out { assert(индекс <= ткт.length); }
body
{
  сим* p = ткт.ptr + индекс;
  сим* конец = ткт.ptr + ткт.length;
  дим c = раскод(p, конец);
  if (c != СИМ_ОШИБКИ)
    индекс = p - ткт.ptr;
  return c;
}

/+
дим decode(ткст s, inout т_мера инд)

    in
    {
	assert(инд >= 0 && инд < s.length);
    }
    out (результат)
    {
	assert(isValidDchar(результат));
    }
    body
    {
	т_мера len = s.length;
	дим V;
	т_мера i = инд;
	сим u = s[i];
	ткст случай;

	if (u & 0x80)
	{   бцел n = 1;
	
	    /* The following encodings are valid, except for the 5 and 6 byte
	     * combinations:
	     *	0xxxxxxx
	     *	110xxxxx 10xxxxxx
	     *	1110xxxx 10xxxxxx 10xxxxxx
	     *	11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
	     *	111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
	     *	1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
	     */
	    for (; ; n++)
	    {
		if (n > 4)		
		{
		случай = "1";
		  goto Lerr;		// only do the first 4 of 6 encodings
		}
		if (((u << n) & 0x80) == 0)
		{
		    if (n == 1)
			{
			случай = "2";
			goto Lerr;
			}
		    break;
		}
	    }

	    // Pick off (7 - n) significant bits of B from first byte of octet
	    V = cast(дим)(u & ((1 << (7 - n)) - 1));

	    if (i + (n - 1) >= len)
		{ 
		случай = "3";
		goto Lerr;			// off end of string
		}
	    /* The following combinations are overlong, and illegal:
	     *	1100000x (10xxxxxx)
	     *	11100000 100xxxxx (10xxxxxx)
	     *	11110000 1000xxxx (10xxxxxx 10xxxxxx)
	     *	11111000 10000xxx (10xxxxxx 10xxxxxx 10xxxxxx)
	     *	11111100 100000xx (10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx)
	     */
	    auto u2 = s[i + 1];
	    if ((u & 0xFE) == 0xC0 ||
                (u == 0xE0 && (u2 & 0xE0) == 0x80) ||
                (u == 0xF0 && (u2 & 0xF0) == 0x80) ||
                (u == 0xF8 && (u2 & 0xF8) == 0x80) ||
                (u == 0xFC && (u2 & 0xFC) == 0x80))
			{
			случай = "4";
            goto Lerr;			// overlong combination
			}

	    for (бцел j = 1; j != n; j++)
	    {
            u = s[i + j];
            if ((u & 0xC0) != 0x80)
			{
			случай = "5";
            goto Lerr;			// trailing bytes are 10xxxxxx
			}
            V = (V << 6) | (u & 0x3F);
	    }
	    if (!isValidDchar(V))
		{
		случай = "6";
        goto Lerr;
		}
	    i += n;
	}
	else
	{
	    V = cast(дим) u;
	    i++;
	}

	инд = i;
	return V;

      Lerr:
	эхо("\ndecode: ind = %d, i = %d, length = %d s ='%.*s' %x '%.*s'\n", инд, i, s.length, s, s[i], s[i .. length]);
	throw new ИсклКодировки(фм("Функция декодирования дим decode(ткст s, inout т_мера инд) 
	случай %s: 
	Неверная последовательность UTF-8:\n\t %s", случай, s[i .. length]), i);
    }
+/
unittest
{   т_мера i;
    дим c;

    debug(utf) эхо("utf.decode.unittest\n");

    static ткст s1 = "abcd";
    i = 0;
    c = decode(s1, i);
    assert(c == cast(дим)'a');
    assert(i == 1);
    c = decode(s1, i);
    assert(c == cast(дим)'b');
    assert(i == 2);

    static ткст s2 = "\xC2\xA9";
    i = 0;
    c = decode(s2, i);
    assert(c == cast(дим)'\u00A9');
    assert(i == 2);

    static ткст s3 = "\xE2\x89\xA0";
    i = 0;
    c = decode(s3, i);
    assert(c == cast(дим)'\u2260');
    assert(i == 3);

    static сим[][] s4 =
    [	"\xE2\x89",		// too short
	"\xC0\x8A",
	"\xE0\x80\x8A",
	"\xF0\x80\x80\x8A",
	"\xF8\x80\x80\x80\x8A",
	"\xFC\x80\x80\x80\x80\x8A",
    ];

    for (int j = 0; j < s4.length; j++)
    {
	try
	{
	    i = 0;
	    c = decode(s4[j], i);
	    assert(0);
	}
	catch (ИсклКодировки u)
	{
	    i = 23;
	    delete u;
	}
	assert(i == 23);
    }
}

/** ditto */
дим decode(wchar[] ткт, ref т_мера индекс)
{
assert(ткт.length && индекс < ткт.length);
  дим c = ткт[индекс];
  if (СИМ_ОШИБКИ > c || c > 0xDFFF)
  {
    ++индекс;
    return c;
  }
  if (c <= 0xDBFF && индекс+1 != ткт.length)
  {
    шим c2 = ткт[индекс+1];
    if (0xDC00 <= c2 && c2 <= 0xDFFF)
    { // Decode surrogate пара.
      // (c - СИМ_ОШИБКИ) << 10 + 0x10000 ->
      // (c - СИМ_ОШИБКИ + 0x40) << 10 ->
      c = (c - 0xD7C0) << 10;
      c |= (c2 & 0x3FF);
      индекс += 2;
      return c;
    }
  }
  return СИМ_ОШИБКИ;
}
/+
дим decode(wchar[] s, inout т_мера инд)
    in
    {
	assert(инд >= 0 && инд < s.length);
    }
    out (результат)
    {
	assert(isValidDchar(результат));
    }
    body
    {
	string msg;
	дим V;
	т_мера i = инд;
	бцел u = s[i];

	if (u & ~0x7F)
	{   if (u >= СИМ_ОШИБКИ && u <= 0xDBFF)
	    {   бцел u2;

		if (i + 1 == s.length)
		{   msg = "суррогатное верхнее значение UTF-16 в завершении строки";
		    goto Lerr;
		}
		u2 = s[i + 1];
		if (u2 < 0xDC00 || u2 > 0xDFFF)
		{   msg = "суррогатное нижнее значение UTF-16 вне диапазона";
		    goto Lerr;
		}
		u = ((u - 0xD7C0) << 10) + (u2 - 0xDC00);
		i += 2;
	    }
	    else if (u >= 0xDC00 && u <= 0xDFFF)
	    {   msg = "беспарное суррогатное значение UTF-16";
		goto Lerr;
	    }
	    else if (u == 0xFFFE || u == 0xFFFF)
	    {   msg = "нелегальное значение UTF-16 value";
		goto Lerr;
	    }
	    else
		i++;
	}
	else
	{
	    i++;
	}

	инд = i;
	return cast(дим)u;

      Lerr:
	throw new ИсклКодировки(msg, i);
    }
+/

/** ditto */

дим decode(дим[] s, inout т_мера инд)
    in
    {
	assert(инд >= 0 && инд < s.length);
    }
    body
    {
	т_мера i = инд;
	дим c = s[i];

	if (!isValidDchar(c))
	    goto Lerr;
	инд = i + 1;
	return c;

      Lerr:
	throw new ИсклКодировки("Неверное значение UTF-32", i);
    }


/* =================== Encode ======================= */

/*******************************
 * Encodes character c and appends it to array s[].
 */
 
 void encode(ref ткст ткт, дим c)
 {
  ткст рез;
// if(!верноСимвол_ли(c)) скажинс(ткт~рез[cast(сим) c]);
 
  assert(верноСимвол_ли(c), "При проверке валидности текста:\n "~ткт);
 
  сим[6] b = void;
  if (c < 0x80)
    ткт ~= c;
  else if (c < 0x800)
  {
    b[0] = 0xC0 | (c >> 6);
    b[1] = 0x80 | (c & 0x3F);
    ткт ~= b[0..2];
  }
  else if (c < 0x10000)
  {
    b[0] = 0xE0 | (c >> 12);
    b[1] = 0x80 | ((c >> 6) & 0x3F);
    b[2] = 0x80 | (c & 0x3F);
    ткт ~= b[0..3];
  }
  else if (c < 0x200000)
  {
    b[0] = 0xF0 | (c >> 18);
    b[1] = 0x80 | ((c >> 12) & 0x3F);
    b[2] = 0x80 | ((c >> 6) & 0x3F);
    b[3] = 0x80 | (c & 0x3F);
    ткт ~= b[0..4];
 }
 else
    assert(0);
}
/+
void encode(inout ткст s, дим c)
    in
    {
	assert(isValidDchar(c));
    }
    body
    {
	ткст r = s;

	if (c <= 0x7F)
	{
	    r ~= cast(сим) c;
	}
	else
	{
	    сим[4] buf;
	    бцел L;

	    if (c <= 0x7FF)
	    {
		buf[0] = cast(сим)(0xC0 | (c >> 6));
		buf[1] = cast(сим)(0x80 | (c & 0x3F));
		L = 2;
	    }
	    else if (c <= 0xFFFF)
	    {
		buf[0] = cast(сим)(0xE0 | (c >> 12));
		buf[1] = cast(сим)(0x80 | ((c >> 6) & 0x3F));
		buf[2] = cast(сим)(0x80 | (c & 0x3F));
		L = 3;
	    }
	    else if (c <= 0x10FFFF)
	    {
		buf[0] = cast(сим)(0xF0 | (c >> 18));
		buf[1] = cast(сим)(0x80 | ((c >> 12) & 0x3F));
		buf[2] = cast(сим)(0x80 | ((c >> 6) & 0x3F));
		buf[3] = cast(сим)(0x80 | (c & 0x3F));
		L = 4;
	    }
	    else
	    {
		assert(0);
	    }
	    r ~= buf[0 .. L];
	}
	s = r;
    }
+/
unittest
{
    debug(utf) эхо("utf.encode.unittest\n");

    ткст s = "abcd";
    encode(s, cast(дим)'a');
    assert(s.length == 5);
    assert(s == "abcda");

    encode(s, cast(дим)'\u00A9');
    assert(s.length == 7);
    assert(s == "abcda\xC2\xA9");
    //assert(s == "abcda\u00A9");	// BUG: fix compiler

    encode(s, cast(дим)'\u2260');
    assert(s.length == 10);
    assert(s == "abcda\xC2\xA9\xE2\x89\xA0");
}

/** ditto */

void encode(inout wchar[] s, дим c)
    in
    {
	assert(isValidDchar(c),"При кодировании шткст-строки");
    }
    body
    {
	wchar[] r = s;

	if (c <= 0xFFFF)
	{
	    r ~= cast(wchar) c;
	}
	else
	{
	    wchar[2] buf;

	    buf[0] = cast(wchar) ((((c - 0x10000) >> 10) & 0x3FF) + СИМ_ОШИБКИ);
	    buf[1] = cast(wchar) (((c - 0x10000) & 0x3FF) + 0xDC00);
	    r ~= buf;
	}
	s = r;
    }

/** ditto */

void encode(inout дим[] s, дим c)
    in
    {
	assert(isValidDchar(c));
    }
    body
    {
	s ~= c;
    }

/* =================== Validation ======================= */

/***********************************
 * Checks to see if string is well formed or not. Throws a ИсклКодировки if it is
 * not. Use to check all untrusted input for correctness.
 */

void validate(ткст s)
{
    т_мера len = s.length;
    т_мера i;

    for (i = 0; i < len; )
    {
	decode(s, i);
    }
}

/** ditto */

void validate(wchar[] s)
{
    т_мера len = s.length;
    т_мера i;

    for (i = 0; i < len; )
    {
	decode(s, i);
    }
}

/** ditto */

void validate(дим[] s)
{
    т_мера len = s.length;
    т_мера i;

    for (i = 0; i < len; )
    {
	decode(s, i);
    }
}

/* =================== Conversion to UTF8 ======================= */

ткст toUTF8(сим[4] buf, дим c)
    in
    {
	assert(isValidDchar(c));
    }
    body
    {
	if (c <= 0x7F)
	{
	    buf[0] = cast(сим) c;
	    return buf[0 .. 1];
	}
	else if (c <= 0x7FF)
	{
	    buf[0] = cast(сим)(0xC0 | (c >> 6));
	    buf[1] = cast(сим)(0x80 | (c & 0x3F));
	    return buf[0 .. 2];
	}
	else if (c <= 0xFFFF)
	{
	    buf[0] = cast(сим)(0xE0 | (c >> 12));
	    buf[1] = cast(сим)(0x80 | ((c >> 6) & 0x3F));
	    buf[2] = cast(сим)(0x80 | (c & 0x3F));
	    return buf[0 .. 3];
	}
	else if (c <= 0x10FFFF)
	{
	    buf[0] = cast(сим)(0xF0 | (c >> 18));
	    buf[1] = cast(сим)(0x80 | ((c >> 12) & 0x3F));
	    buf[2] = cast(сим)(0x80 | ((c >> 6) & 0x3F));
	    buf[3] = cast(сим)(0x80 | (c & 0x3F));
	    return buf[0 .. 4];
	}
	assert(0);
    }

/*******************
 * Encodes string s into UTF-8 and returns the encoded string.
 */

ткст toUTF8(ткст s)
    in
    {
	validate(s);
    }
    body
    {
	return s;
    }

/** ditto */

ткст toUTF8(wchar[] s)
{
    ткст r;
    т_мера i;
    т_мера slen = s.length;

    r.length = slen;

    for (i = 0; i < slen; i++)
    {	wchar c = s[i];

	if (c <= 0x7F)
	    r[i] = cast(сим)c;		// fast path for ascii
	else
	{
	    r.length = i;
	    foreach (дим c; s[i .. slen])
	    {
		encode(r, c);
	    }
	    break;
	}
    }
    return r;
}

/** ditto */

ткст toUTF8(дим[] s)
{
    ткст r;
    т_мера i;
    т_мера slen = s.length;

    r.length = slen;

    for (i = 0; i < slen; i++)
    {	дим c = s[i];

	if (c <= 0x7F)
	    r[i] = cast(сим)c;		// fast path for ascii
	else
	{
	    r.length = i;
	    foreach (дим d; s[i .. slen])
	    {
		encode(r, d);
	    }
	    break;
	}
    }
    return r;
}

/* =================== Conversion to UTF16 ======================= */

wchar[] toUTF16(wchar[2] buf, дим c)
    in
    {
	assert(isValidDchar(c));
    }
    body
    {
	if (c <= 0xFFFF)
	{
	    buf[0] = cast(wchar) c;
	    return buf[0 .. 1];
	}
	else
	{
	    buf[0] = cast(wchar) ((((c - 0x10000) >> 10) & 0x3FF) + СИМ_ОШИБКИ);
	    buf[1] = cast(wchar) (((c - 0x10000) & 0x3FF) + 0xDC00);
	    return buf[0 .. 2];
	}
    }

/****************
 * Encodes string s into UTF-16 and returns the encoded string.
 * toUTF16z() is suitable for calling the 'W' functions in the Win32 API that take
 * an LPWSTR or LPCWSTR argument.
 */

wchar[] toUTF16(ткст s)
{
    wchar[] r;
    т_мера slen = s.length;

    r.length = slen;
    r.length = 0;
    for (т_мера i = 0; i < slen; )
    {
	дим c = s[i];
	if (c <= 0x7F)
	{
	    i++;
	    r ~= cast(wchar)c;
	}
	else
	{
	    c = decode(s, i);
	    encode(r, c);
	}
    }
    return r;
}

/** ditto */

wchar* toUTF16z(ткст s)
{
    wchar[] r;
    т_мера slen = s.length;

    r.length = slen + 1;
    r.length = 0;
    for (т_мера i = 0; i < slen; )
    {
	дим c = s[i];
	if (c <= 0x7F)
	{
	    i++;
	    r ~= cast(wchar)c;
	}
	else
	{
	    c = decode(s, i);
	    encode(r, c);
	}
    }
    r ~= "\000";
    return r.ptr;
}

/** ditto */

wchar[] toUTF16(wchar[] s)
    in
    {
	validate(s);
    }
    body
    {
	return s;
    }

/** ditto */

wchar[] toUTF16(дим[] s)
{
    wchar[] r;
    т_мера slen = s.length;

    r.length = slen;
    r.length = 0;
    for (т_мера i = 0; i < slen; i++)
    {
	encode(r, s[i]);
    }
    return r;
}

/* =================== Conversion to UTF32 ======================= */

/*****
 * Encodes string s into UTF-32 and returns the encoded string.
 */

дим[] toUTF32(ткст s)
{
    дим[] r;
    т_мера slen = s.length;
    т_мера j = 0;

    r.length = slen;		// r[] will never be longer than s[]
    for (т_мера i = 0; i < slen; )
    {
	дим c = s[i];
	if (c >= 0x80)
	    c = decode(s, i);
	else
	    i++;		// c is ascii, no need for decode
	r[j++] = c;
    }
    return r[0 .. j];
}

/** ditto */

дим[] toUTF32(wchar[] s)
{
    дим[] r;
    т_мера slen = s.length;
    т_мера j = 0;

    r.length = slen;		// r[] will never be longer than s[]
    for (т_мера i = 0; i < slen; )
    {
	дим c = s[i];
	if (c >= 0x80)
	    c = decode(s, i);
	else
	    i++;		// c is ascii, no need for decode
	r[j++] = c;
    }
    return r[0 .. j];
}

/** ditto */

дим[] toUTF32(дим[] s)
    in
    {
	validate(s);
    }
    body
    {
	return s;
    }

/* ================================ tests ================================== */

unittest
{
    debug(utf) эхо("utf.toUTF.unittest\n");

    ткст c;
    wchar[] w;
    дим[] d;

    c = "hello";
    w = toUTF16(c);
    assert(w == "hello");
    d = toUTF32(c);
    assert(d == "hello");

    c = toUTF8(w);
    assert(c == "hello");
    d = toUTF32(w);
    assert(d == "hello");

    c = toUTF8(d);
    assert(c == "hello");
    w = toUTF16(d);
    assert(w == "hello");


    c = "hel\u1234o";
    w = toUTF16(c);
    assert(w == "hel\u1234o");
    d = toUTF32(c);
    assert(d == "hel\u1234o");

    c = toUTF8(w);
    assert(c == "hel\u1234o");
    d = toUTF32(w);
    assert(d == "hel\u1234o");

    c = toUTF8(d);
    assert(c == "hel\u1234o");
    w = toUTF16(d);
    assert(w == "hel\u1234o");


    c = "he\U0010AAAAllo";
    w = toUTF16(c);
    //foreach (wchar c; w) эхо("c = x%x\n", c);
    //foreach (wchar c; cast(wchar[])"he\U0010AAAAllo") эхо("c = x%x\n", c);
    assert(w == "he\U0010AAAAllo");
    d = toUTF32(c);
    assert(d == "he\U0010AAAAllo");

    c = toUTF8(w);
    assert(c == "he\U0010AAAAllo");
    d = toUTF32(w);
    assert(d == "he\U0010AAAAllo");

    c = toUTF8(d);
    assert(c == "he\U0010AAAAllo");
    w = toUTF16(d);
    assert(w == "he\U0010AAAAllo");
}
