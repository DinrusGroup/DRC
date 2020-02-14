/**
 * Encodes/decodes MIME base64 data.
 *
 * Macros:
 *	WIKI=Phobos/StdBase64
 * References:
 *	<a href="http://en.wikipedia.org/wiki/Base64">Wikipedia Base64</a>$(BR)
 *	<a href="http://www.ietf.org/rfc/rfc2045.txt">RFC 2045</a>$(BR)
 */

module std.base64;

/**
 */

import sys.WinFuncs, std.utf, exception;



const char[] rarray = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯабвгдеёжзийклмнопрстуфхцчшщьыъэюя0123456789+/";
const char[] array = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯабвгдеёжзийклмнопрстуфхцчшщьыъэюя0123456789+/";

/**
 * Returns the number of bytes needed to encode a string of length slen.
 */

uint encodeLength(uint slen)
{
	uint результат;
	результат = slen / 3;
	if(slen % 3)
		результат++;
	return результат * 4;
}

/**
 * Encodes str[] and places the результат in buf[].
 * Параметры:
 *	str = string to encode
 * 	buf = destination buffer, must be large enough for the результат.
 * Returns:
 *	slice into buf[] representing encoded результат
 */

char[] encode(char[] str, char[] buf)
in
{
	assert(buf.length >= encodeLength(str.length));
}
body
{
	if(!str.length)
		return buf[0 .. 0];
	
	uint stri;
	uint strmax = str.length / 3;
	uint strleft = str.length % 3;
	uint x;
	char* sp, bp;
	
	bp = &buf[0];
	sp = &str[0];
	for(stri = 0; stri != strmax; stri++)
	{
		x = (sp[0] << 16) | (sp[1] << 8) | (sp[2]);
		sp+= 3;
		*bp++ = array[(x & 0b11111100_00000000_00000000) >> 18];
		*bp++ = array[(x & 0b00000011_11110000_00000000) >> 12];
		*bp++ = array[(x & 0b00000000_00001111_11000000) >> 6];
		*bp++ = array[(x & 0b00000000_00000000_00111111)];
	}
	
	switch(strleft)
	{
		case 2:
			x = (sp[0] << 16) | (sp[1] << 8);
			sp += 2;
			*bp++ = array[(x & 0b11111100_00000000_00000000) >> 18];
			*bp++ = array[(x & 0b00000011_11110000_00000000) >> 12];
			*bp++ = array[(x & 0b00000000_00001111_11000000) >> 6];
			*bp++ = '=';
			break;
		
		case 1:
			x = *sp++ << 16;
			*bp++ = array[(x & 0b11111100_00000000_00000000) >> 18];
			*bp++ = array[(x & 0b00000011_11110000_00000000) >> 12];
			*bp++ = '=';
			*bp++ = '=';
			break;
		
		case 0:
			break;

		default:
			assert(0);
	}
	
	return buf[0 .. (bp - &buf[0])];
}


/**
 * Encodes str[] and returns the результат.
 */

char[] encode(char[] str)
{
	return encode(str, new char[encodeLength(str.length)]);
}

/+
unittest
{
	assert(encode("f") == "Zg==");
	assert(encode("fo") == "Zm8=");
	assert(encode("foo") == "Zm9v");
	assert(encode("foos") == "Zm9vcw==");
	assert(encode("all your base64 are belong to foo") == "YWxsIHlvdXIgYmFzZTY0IGFyZSBiZWxvbmcgdG8gZm9v");
}
+/

/**
 * Returns the number of bytes needed to decode an encoded string of this
 * length.
 */
uint decodeLength(uint elen)
{
	return elen / 4 * 3;
}


/**
 * Decodes str[] and places the результат in buf[].
 * Параметры:
 *	str = string to encode
 * 	buf = destination buffer, must be large enough for the результат.
 * Returns:
 *	slice into buf[] representing encoded результат
 * Errors:
 *	Throws ИсклОсновы64 on invalid base64 encoding in estr[].
 *	Throws ИсклСимвОсновы64 on invalid base64 character in estr[].
 */
char[] decode(char[] estr, char[] buf)
in
{
	assert(buf.length + 2 >= decodeLength(estr.length)); //account for '=' padding
}
body
{
	void badc(char ch)
	{
		throw new ИсклСимвОсновы64("Неверный символ base64 '" ~ (&ch)[0 .. 1] ~ "'");
	}
	
	
	uint arrayIndex(char ch)
	out(результат)
	{
		assert(ch == array[результат]);
	}
	body
	{
		if(ch >= 'A' && ch <= 'Z')
			return ch - 'A';
		if(ch >= 'a' && ch <= 'z')
			return 'Z' - 'A' + 1 + ch - 'a';
		if(ch >= '0' && ch <= '9')
			return 'Z' - 'A' + 1 + 'z' - 'a' + 1 + ch - '0';
		if(ch == '+')
			return 'Z' - 'A' + 1 + 'z' - 'a' + 1 + '9' - '0' + 1;
		if(ch == '/')
			return 'Z' - 'A' + 1 + 'z' - 'a' + 1 + '9' - '0' + 1 + 1;
		badc(ch);
		assert(0);
	}
	
	
	if(!estr.length)
		return buf[0 .. 0];
	
	if(estr.length % 4)
		throw new ИсклОсновы64("Неверно кодированная строка base64");
	
	uint estri;
	uint estrmax = estr.length / 4;
	uint x;
	char* sp, bp;
	char ch;
	
	sp = &estr[0];
	bp = &buf[0];
	for(estri = 0; estri != estrmax; estri++)
	{
		x = arrayIndex(sp[0]) << 18 | arrayIndex(sp[1]) << 12;
		sp += 2;

		ch = *sp++;
		if(ch == '=')
		{
			if(*sp++ != '=')
				badc('=');
			*bp++ = cast(char) (x >> 16);
			break;
		}
		x |= arrayIndex(ch) << 6;
		
		ch = *sp++;
		if(ch == '=')
		{
			*bp++ = cast(char) (x >> 16);
			*bp++ = cast(char) ((x >> 8) & 0xFF);
			break;
		}
		x |= arrayIndex(ch);
		
		*bp++ = cast(char) (x >> 16);
		*bp++ = cast(char) ((x >> 8) & 0xFF);
		*bp++ = cast(char) (x & 0xFF);
	}
	
	return buf[0 .. (bp - &buf[0])];
}

/**
 * Decodes estr[] and returns the результат.
 * Errors:
 *	Throws ИсклОсновы64 on invalid base64 encoding in estr[].
 *	Throws ИсклСимвОсновы64 on invalid base64 character in estr[].
 */

char[] decode(char[] estr)
{
	return decode(estr, new char[decodeLength(estr.length)]);
}





