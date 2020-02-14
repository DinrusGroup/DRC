/*
 * Placed into the Public Domain.
 * Digital Mars, www.digitalmars.com
 * Written by Walter Bright
 */

/**
 * Simple ASCII character classification functions.
 * For Unicode classification, see $(LINK2 std_uni.html, std.uni).
 * References:
 *	$(LINK2 http://www.digitalmars.com/d/ascii-table.html, ASCII Table),
 *	$(LINK2 http://en.wikipedia.org/wiki/Ascii, Wikipedia)
 * Macros:
 *	WIKI=Phobos/StdCtype
 */

module std.ctype;

 const dchar[66] РУСАЛФ =['а','б','в','г','д','е','ё','ж','з','и','й','к','л','м','н','о','п','р','с','т','у','ф','х','ц','ч','ш','щ','ъ','ы','ь','э','ю','я','А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й','К','Л','М','Н','О','П','Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Щ','Ъ','Ы','Ь','Э','Ю','Я'];
 
 const ubyte[66] РУСАЛФб =cast(ubyte[])['а','б','в','г','д','е','ё','ж','з','и','й','к','л','м','н','о','п','р','с','т','у','ф','х','ц','ч','ш','щ','ъ','ы','ь','э','ю','я','А','Б','В','Г','Д','Е','Ё','Ж','З','И','Й','К','Л','М','Н','О','П','Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Щ','Ъ','Ы','Ь','Э','Ю','Я'];
 
 юткст[33] РУСн = [\U00000430,\U00000431,\U00000432,\U00000233,\U00000434,\U00000435,\U00000451,\U00000436,\U00000437,\U00000438,\U00000439,\U0000043a,\U0000043b,\U0000043c,\U0000043d,\U0000043e,\U0000043f,\U00000440,\U00000441,\U00000442,\U00000443,\U00000444,\U00000445,\U00000446,\U00000447,\U00000448,\U00000449,\U0000044a,\U0000044b,\U0000044c,\U0000044d,\U0000044e,\U0000044f];

 юткст[33] РУСв = [\U00000410,\U00000411,\U00000412,\U00000413,\U00000414,\U00000415,\U00000401,\U00000416,\U00000417,\U00000418,\U00000419,\U0000041a,\U0000041b,\U0000041c,\U0000041d,\U0000041e,\U0000041f,\U00000420,\U00000421,\U00000422,\U00000423,\U00000424,\U00000425,\U00000426,\U00000427,\U00000428,\U00000429,\U0000042a,\U0000042b,\U0000042c,\U0000042d,\U0000042e,\U0000042f];
 
 бул рус_ли(дим б)
 {
  юткст м_б =[б];
  switch(м_б)
 {
 case "а","б","в","г","д","е","ё","ж","з","и","й","к","л","м","н","о","п","р","с","т","у","ф","х","ц","ч","ш","щ","ъ","ы","ь","э","ю","я","А","Б","В","Г","Д","Е","Ё","Ж","З","И","Й","К","Л","М","Н","О","П","Р","С","Т","У","Ф","Х","Ц","Ч","Ш","Щ","Ъ","Ы","Ь","Э","Ю","Я": return true;
 default:
 }
  return false;
 }
 
 цел проверьРус(дим б)
 {
	 юткст м_б =[б];
	 switch(м_б)
	 {
	 case "а","б","в","г","д","е","ё","ж","з","и","й","к","л","м","н","о","п","р","с","т","у","ф","х","ц","ч","ш","щ","ъ","ы","ь","э","ю","я":
	 return _БНР;
	 case "А","Б","В","Г","Д","Е","Ё","Ж","З","И","Й","К","Л","М","Н","О","П","Р","С","Т","У","Ф","Х","Ц","Ч","Ш","Щ","Ъ","Ы","Ь","Э","Ю","Я":
	 return _БВР;
	 default:
	}  
  return 0;   
}
  
/**
 * Возвращает !=0, если б является буквой в диапазоне (0..9, a..z, A..Z, а..я, А..Я).
 */
int isalnum(dchar б)
  {
  цел рез;
  рез =	(б <= 0x7F) ? _ctype[б] & (_БУКВ|_ЦИФР) : 0;
  if(рус_ли(б)) рез = проверьРус(б)& (_БУКВ|_ЦИФР);
  return рез;
 }
цел числобукв_ли(дим б){return isalnum(б);}
/**
 * Returns !=0 if б is an ascii upper or lower case letter.
 */
int isalpha(dchar б)  {
цел рез;
  рез =	(б <= 0x7F) ? _ctype[б] & (_БУКВ): 0;
  if(рус_ли(б)) рез = проверьРус(б) & (_БУКВ); 
 return рез;
 }
цел буква_ли(дим б){return  isalpha(б);}
/**
 * Returns !=0 if б is a control character.
 */
int iscntrl(dchar б)
  { 
  цел рез;
  рез = (б <= 0x7F) ? _ctype[б] & (_КТРЛ)      : 0;
  if(рус_ли(б)) рез = проверьРус(б)& (_КТРЛ);  
 return рез;  
  }
цел управ_ли(дим б){return iscntrl(б);}
/**
 * Returns !=0 if б is a digit.
 */
int isdigit(dchar б)  {
 цел рез;
  рез = (б <= 0x7F) ? _ctype[б] & (_ЦИФР): 0;
	if(рус_ли(б)) рез = проверьРус(б)& (_ЦИФР);
 return рез;
 }
цел цифра_ли(дим б){return isdigit(б);}
/**
 * Returns !=0 if б is lower case ascii letter.
 */
int islower(dchar б)  { 
цел рез;
  рез = (б <= 0x7F) ? _ctype[б] & (_БНР) : 0;
if(рус_ли(б)) рез = проверьРус(б)& (_БНР);
 return рез;
  }
цел проп_ли(дим б){return islower(б);}
/**
 * Returns !=0 if б is a punctuation character.
 */
int ispunct(dchar б)  {
цел рез;
  рез = (б <= 0x7F) ? _ctype[б] & (_ПУНКТ)      : 0;
  if(рус_ли(б)) рез = проверьРус(б)&(_ПУНКТ);
 return рез;
 }
цел пунктзнак_ли(дим б){return  ispunct(б);}
/**
 * Returns !=0 if б is a space, tab, vertical tab, form feed,
 * carriage return, or linefeed.
 */
int isspace(dchar б)  {
цел рез;
  рез = (б <= 0x7F) ? _ctype[б] & (_ПБЕЛ)      : 0;
    if(рус_ли(б)) рез = проверьРус(б)&(_ПБЕЛ);
 return рез;
 }
цел межбукв_ли(дим б){return isspace(б);}
/**
 * Returns !=0 if б is an upper case ascii character.
 */
int isupper(dchar б)  {
цел рез;
  рез = (б <= 0x7F) ? _ctype[б] & (_БВР)       : 0;
if(рус_ли(б)) рез = проверьРус(б)&(_БВР);
 return рез;
 }
цел заг_ли(дим б){return isupper(б);}
/**
 * Returns !=0 if б is a hex digit (0..9, a..f, A..F).
 */
int isxdigit(dchar б) {
цел рез;
  рез = (б <= 0x7F) ? _ctype[б] & (_ГЕКС)      : 0; 
 if(рус_ли(б)) рез = проверьРус(б)&(_ГЕКС);
 return рез;
 }
цел цифраикс_ли(дим б){return isxdigit(б);}
/**
 * Returns !=0 if б is a printing character except for the space character.
 */
int isgraph(dchar б)  {
цел рез;
  рез =(б <= 0x7F) ? _ctype[б] & (_БУКВ|_ЦИФР|_ПУНКТ) : 0;
   if(рус_ли(б)) рез = проверьРус(б)&(_БУКВ|_ЦИФР|_ПУНКТ);
 return рез;
 }
цел граф_ли(дим б){return  isgraph(б);}
/**
 * Returns !=0 if б is a printing character including the space character.
 */
int isprint(dchar б)
  {
 цел рез;
  рез =(б <= 0x7F) ? _ctype[б] & (_БУКВ|_ЦИФР|_ПУНКТ|_БЛК) : 0;
     if(рус_ли(б)) рез = проверьРус(б)&(_БУКВ|_ЦИФР|_ПУНКТ|_БЛК);
 return рез;
  }
цел печат_ли(дим б) {return  isprint(б);}
/**
 * Returns !=0 if б is in the ascii character set, i.e. in the range 0..0x7F.
 */
int isascii(dchar б)  { return б <= 0x7F; }
цел аски_ли(дим б){return  isascii(б);}

/**
 * If б is an upper case ascii character,
 * return the lower case equivalent, otherwise return б.
 */
dchar tolower(dchar б)
    out (результат)
    {
	assert(!isupper(результат));
    }
    body
    {
	return isupper(б) ? б + (cast(dchar)'a' - 'A') : б;
    }

дим впроп(дим б){return  tolower(б);}

/**
 * If б is a lower case ascii character,
 * return the upper case equivalent, otherwise return б.
 */
dchar toupper(dchar б)
    out (результат)
    {
	assert(!islower(результат));
    }
    body
    {
	return islower(б) ? б - (cast(dchar)'a' - 'A') : б;
    }
дим взаг(дим б){return toupper(б);}

private:

enum
{
    _ПБЕЛ =	8,
    _КТРЛ =	0x20,
    _БЛК =	0x40,
    _ГЕКС =	0x80,
    _БВР  =	1,
    _БНР  =	2,
    _ПУНКТ =	0x10,
    _ЦИФР =	4,
    _БУКВ =	_БВР|_БНР,
}


ббайт _ctype[128] =
[
	_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,
	_КТРЛ,_КТРЛ|_ПБЕЛ,_КТРЛ|_ПБЕЛ,_КТРЛ|_ПБЕЛ,_КТРЛ|_ПБЕЛ,_КТРЛ|_ПБЕЛ,_КТРЛ,_КТРЛ,
	_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,
	_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,_КТРЛ,
	_ПБЕЛ|_БЛК,_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,
	_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,
	_ЦИФР|_ГЕКС,_ЦИФР|_ГЕКС,_ЦИФР|_ГЕКС,_ЦИФР|_ГЕКС,_ЦИФР|_ГЕКС,
	_ЦИФР|_ГЕКС,_ЦИФР|_ГЕКС,_ЦИФР|_ГЕКС,_ЦИФР|_ГЕКС,_ЦИФР|_ГЕКС,
	_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,
	_ПУНКТ,_БВР|_ГЕКС,_БВР|_ГЕКС,_БВР|_ГЕКС,_БВР|_ГЕКС,_БВР|_ГЕКС,_БВР|_ГЕКС,_БВР,
	_БВР,_БВР,_БВР,_БВР,_БВР,_БВР,_БВР,_БВР,
	_БВР,_БВР,_БВР,_БВР,_БВР,_БВР,_БВР,_БВР,
	_БВР,_БВР,_БВР,_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,
	_ПУНКТ,_БНР|_ГЕКС,_БНР|_ГЕКС,_БНР|_ГЕКС,_БНР|_ГЕКС,_БНР|_ГЕКС,_БНР|_ГЕКС,_БНР,
	_БНР,_БНР,_БНР,_БНР,_БНР,_БНР,_БНР,_БНР,
	_БНР,_БНР,_БНР,_БНР,_БНР,_БНР,_БНР,_БНР,
	_БНР,_БНР,_БНР,_ПУНКТ,_ПУНКТ,_ПУНКТ,_ПУНКТ,_КТРЛ
];

//Дополнено для русского алфавита
public:
int isruslower(dchar б)  { return (б <= 'я' &&  б >='а' || б == 'ё'); }
int isrusupper(dchar б)  { return (б <=  'Я' && б >= 'А' || б == 'Ё') ; }
цел руспроп_ли(дим б)  { return (б <= 'я' &&  б >='а' || б == 'ё'); }
цел русзаг_ли(дим б)  { return (б <=  'Я' && б >= 'А' || б == 'Ё') ; }

unittest
{

ткст а = "а";
//шим Ан = РУСАЛФ[1];
	assert(а == \u0430);
	//assert(Ан == \U00000430);
	assert(isalnum('а'));
	assert(isalnum('б'));
	assert(isalnum('в'));
	assert(isalnum('г'));
	assert(isalnum('д'));
	assert(isalnum('е'));
	assert(isalnum('D'));
	assert(isalnum('ё'));
	assert(isalnum('ж'));
	assert(isalnum('з'));
	assert(isalnum('и'));
	assert(isalnum('й'));
	assert(isalnum('к'));
	assert(isalnum('л'));
	assert(isalnum('м'));
	assert(isalnum('н'));
	assert(isalnum('о'));
	assert(isalnum('п'));
	assert(isalnum('р'));
	assert(isalnum('с'));
	assert(isalnum('т'));
	assert(isalnum('у'));
	assert(isalnum('ф'));
	assert(isalnum('х'));
	assert(isalnum('ц'));
	assert(isalnum('ч'));
	assert(isalnum('ш'));
	assert(isalnum('щ'));
	assert(isalnum('ъ'));
	assert(isalnum('ы'));
	assert(isalnum('ь'));
	assert(isalnum('э'));
	assert(isalnum('ю'));
	assert(isalnum('я'));	
	assert(isalnum('А'));
	assert(isalnum('Б'));
	assert(isalnum('В'));
	assert(isalnum('Г'));
	assert(isalnum('Д'));
	assert(isalnum('Е'));
	assert(isalnum('Ё'));
	assert(isalnum('Ж'));
	assert(isalnum('З'));
	assert(isalnum('И'));
	assert(isalnum('Й'));
	assert(isalnum('К'));
	assert(isalnum('Л'));
	assert(isalnum('М'));
	assert(isalnum('Н'));
	assert(isalnum('О'));
	assert(isalnum('П'));
	assert(isalnum('Р'));
	assert(isalnum('С'));
	assert(isalnum('Т'));
	assert(isalnum('У'));
	assert(isalnum('Ф'));
	assert(isalnum('Х'));
	assert(isalnum('Ц'));
	assert(isalnum('Ч'));
	assert(isalnum('Ш'));
	assert(isalnum('Щ'));
	assert(isalnum('Ъ'));
	assert(isalnum('Ы'));
	assert(isalnum('Ь'));
	assert(isalnum('Э'));
	assert(isalnum('Ю'));
	assert(isalpha('Я'));	
	assert(!iscntrl('Я'));
	assert(!iscntrl('ё'));
    assert(isspace(' '));
    assert(!isspace('z'));
	assert(!isspace('Ъ'));
    assert(toupper('a') == 'A');
	assert(toupper('м') == 'М');
    assert(tolower('Q') == 'q');
	assert(tolower('Ю') == 'ю');
    assert(!isxdigit('G'));
	assert(isruslower('ф'));
	assert(!isxdigit('Ш'));
    assert(!isruslower('z'));
	assert (isrusupper('П'));
	assert (isrusupper('Ё'));
	assert(!isrusupper('п'));
	assert (isupper('Ё'));
	эхо("!!!!!!!!!!");
}
