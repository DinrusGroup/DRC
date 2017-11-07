module dmd.Token;

import dmd.common;
import dmd.TOK;
import dmd.Identifier;
import dmd.OutBuffer;
import dmd.Utf;

import core.stdc.stdio;
import core.stdc.ctype;

struct Token
{
    Token* next;
    ubyte* ptr;		// pointer to first character of this token within buffer
    TOK value;
    string blockComment; // doc comment string prior to this token
    string lineComment;	 // doc comment for previous token
    
	union
    {
		// Integers
		int 	int32value;
		uint	uns32value;
		long	int64value;
		ulong	uns64value;

	// Floats
version (IN_GCC) {
	// real_t float80value; // can't use this in a union!
} else {
		real float80value;
}

		struct
		{
			const(char)* ustring;	// UTF8 string
			uint len;
			ubyte postfix;	// 'c', 'w', 'd'
		};

		Identifier ident;
    }

version (IN_GCC) {
    real float80value; // can't use this in a union!
}

    static __gshared string[TOK.TOKMAX] tochars;
///    static void *operator new(size_t sz);

    int isKeyword()
	{
		assert(false);
	}
	
    void print()
	{
		assert(false);
	}
	
    string toChars()
	{
		string p;
		
		char[3 + 3 * value.sizeof + 1] buffer;
		
		switch (value)
		{
		case TOK.TOKint32v:
version (IN_GCC) {
			sprintf(buffer.ptr,"%d",cast(int)int64value);
} else {
			sprintf(buffer.ptr,"%d",int32value);
}
			break;

		case TOK.TOKuns32v:
		case TOK.TOKcharv:
		case TOK.TOKwcharv:
		case TOK.TOKdcharv:
version (IN_GCC) {
			sprintf(buffer.ptr,"%uU",cast(uint)uns64value);
} else {
			sprintf(buffer.ptr,"%uU",uns32value);
}
			break;

		case TOK.TOKint64v:
			sprintf(buffer.ptr,"%jdL",int64value);
			break;

		case TOK.TOKuns64v:
			sprintf(buffer.ptr,"%juUL",uns64value);
			break;

version (IN_GCC) {
		case TOK.TOKfloat32v:
		case TOK.TOKfloat64v:
		case TOK.TOKfloat80v:
			float80value.format(buffer, sizeof(buffer));
			break;
		case TOK.TOKimaginary32v:
		case TOK.TOKimaginary64v:
		case TOK.TOKimaginary80v:
			float80value.format(buffer, sizeof(buffer));
			// %% buffer
			strcat(buffer, "i");
			break;
} else {
		case TOK.TOKfloat32v:
			sprintf(buffer.ptr,"%Lgf", float80value);
			break;

		case TOK.TOKfloat64v:
			sprintf(buffer.ptr,"%Lg", float80value);
			break;

		case TOK.TOKfloat80v:
			sprintf(buffer.ptr,"%LgL", float80value);
			break;

		case TOK.TOKimaginary32v:
			sprintf(buffer.ptr,"%Lgfi", float80value);
			break;

		case TOK.TOKimaginary64v:
			sprintf(buffer.ptr,"%Lgi", float80value);
			break;

		case TOK.TOKimaginary80v:
			sprintf(buffer.ptr,"%LgLi", float80value);
			break;
}

		case TOK.TOKstring:
version (CSTRINGS) {
			p = string;
} else {
		{   OutBuffer buf = new OutBuffer();

			buf.writeByte('"');
			for (size_t i = 0; i < len; )
			{	
				dchar c;			///! 

				utf_decodeChar(ustring[0..len], &i, &c);
				switch (c)
				{
					case 0:
					break;

					case '"':
					case '\\':
					buf.writeByte('\\');
					default:
					if (isprint(c))
						buf.writeByte(c);
					else if (c <= 0x7F)
						buf.printf("\\x%02x", c);
					else if (c <= 0xFFFF)
						buf.printf("\\u%04x", c);
					else
						buf.printf("\\U%08x", c);
					continue;
				}
				break;
			}
			buf.writeByte('"');
			if (postfix)
			buf.writeByte('"');
			buf.writeByte(0);
			p = buf.extractString();
		}
}
			break;

		case TOK.TOKidentifier:
		case TOK.TOKenum:
		case TOK.TOKstruct:
		case TOK.TOKimport:
		case TOK.TOKwchar: case TOK.TOKdchar:
		case TOK.TOKbit: case TOK.TOKbool: case TOK.TOKchar:
		case TOK.TOKint8: case TOK.TOKuns8:
		case TOK.TOKint16: case TOK.TOKuns16:
		case TOK.TOKint32: case TOK.TOKuns32:
		case TOK.TOKint64: case TOK.TOKuns64:
		case TOK.TOKfloat32: case TOK.TOKfloat64: case TOK.TOKfloat80:
		case TOK.TOKimaginary32: case TOK.TOKimaginary64: case TOK.TOKimaginary80:
		case TOK.TOKcomplex32: case TOK.TOKcomplex64: case TOK.TOKcomplex80:
		case TOK.TOKvoid:
			p = ident.toChars();
			break;

		default:
			p = toChars(value);
			break;
		}
		return p;
	}
	
    static string toChars(TOK value)
	{
		string p;
		
		char[3 + 3 * value.sizeof + 1] buffer;

		p = tochars[value];
		if (!p)
		{
			int len = sprintf(buffer.ptr, "TOK%d".ptr, value);
			p = buffer[0..len].idup;
		}

		return p;
	}
}
