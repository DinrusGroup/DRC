module dmd.Lexer;

import dmd.common;
import dmd.StringTable;
import dmd.OutBuffer;
import dmd.Token;
import dmd.Loc;
import dmd.Module;
import dmd.Identifier;
import dmd.TOK;
import dmd.Keyword;
import dmd.StringValue;
import dmd.Global;
import dmd.Util;
import dmd.Id;
import dmd.Dchar;
import dmd.Utf;

import std.stdio : writeln;

import core.memory;

import core.stdc.ctype;
import core.stdc.stdlib;
import core.stdc.string;
import core.stdc.errno;

enum LS = 0x2028;	// UTF line separator
enum PS = 0x2029;	// UTF paragraph separator

extern (C) extern
{
	__gshared char* __locale_decpoint;
}

bool isUniAlpha(uint u)
{
	enum ushort[][2] table =
    [
		[ 0x00AA, 0x00AA ],
		[ 0x00B5, 0x00B5 ],
		[ 0x00B7, 0x00B7 ],
		[ 0x00BA, 0x00BA ],
		[ 0x00C0, 0x00D6 ],
		[ 0x00D8, 0x00F6 ],
		[ 0x00F8, 0x01F5 ],
		[ 0x01FA, 0x0217 ],
		[ 0x0250, 0x02A8 ],
		[ 0x02B0, 0x02B8 ],
		[ 0x02BB, 0x02BB ],
		[ 0x02BD, 0x02C1 ],
		[ 0x02D0, 0x02D1 ],
		[ 0x02E0, 0x02E4 ],
		[ 0x037A, 0x037A ],
		[ 0x0386, 0x0386 ],
		[ 0x0388, 0x038A ],
		[ 0x038C, 0x038C ],
		[ 0x038E, 0x03A1 ],
		[ 0x03A3, 0x03CE ],
		[ 0x03D0, 0x03D6 ],
		[ 0x03DA, 0x03DA ],
		[ 0x03DC, 0x03DC ],
		[ 0x03DE, 0x03DE ],
		[ 0x03E0, 0x03E0 ],
		[ 0x03E2, 0x03F3 ],
		[ 0x0401, 0x040C ],
		[ 0x040E, 0x044F ],
		[ 0x0451, 0x045C ],
		[ 0x045E, 0x0481 ],
		[ 0x0490, 0x04C4 ],
		[ 0x04C7, 0x04C8 ],
		[ 0x04CB, 0x04CC ],
		[ 0x04D0, 0x04EB ],
		[ 0x04EE, 0x04F5 ],
		[ 0x04F8, 0x04F9 ],
		[ 0x0531, 0x0556 ],
		[ 0x0559, 0x0559 ],
		[ 0x0561, 0x0587 ],
		[ 0x05B0, 0x05B9 ],
		[ 0x05BB, 0x05BD ],
		[ 0x05BF, 0x05BF ],
		[ 0x05C1, 0x05C2 ],
		[ 0x05D0, 0x05EA ],
		[ 0x05F0, 0x05F2 ],
		[ 0x0621, 0x063A ],
		[ 0x0640, 0x0652 ],
		[ 0x0660, 0x0669 ],
		[ 0x0670, 0x06B7 ],
		[ 0x06BA, 0x06BE ],
		[ 0x06C0, 0x06CE ],
		[ 0x06D0, 0x06DC ],
		[ 0x06E5, 0x06E8 ],
		[ 0x06EA, 0x06ED ],
		[ 0x06F0, 0x06F9 ],
		[ 0x0901, 0x0903 ],
		[ 0x0905, 0x0939 ],
		[ 0x093D, 0x093D ],
		[ 0x093E, 0x094D ],
		[ 0x0950, 0x0952 ],
		[ 0x0958, 0x0963 ],
		[ 0x0966, 0x096F ],
		[ 0x0981, 0x0983 ],
		[ 0x0985, 0x098C ],
		[ 0x098F, 0x0990 ],
		[ 0x0993, 0x09A8 ],
		[ 0x09AA, 0x09B0 ],
		[ 0x09B2, 0x09B2 ],
		[ 0x09B6, 0x09B9 ],
		[ 0x09BE, 0x09C4 ],
		[ 0x09C7, 0x09C8 ],
		[ 0x09CB, 0x09CD ],
		[ 0x09DC, 0x09DD ],
		[ 0x09DF, 0x09E3 ],
		[ 0x09E6, 0x09EF ],
		[ 0x09F0, 0x09F1 ],
		[ 0x0A02, 0x0A02 ],
		[ 0x0A05, 0x0A0A ],
		[ 0x0A0F, 0x0A10 ],
		[ 0x0A13, 0x0A28 ],
		[ 0x0A2A, 0x0A30 ],
		[ 0x0A32, 0x0A33 ],
		[ 0x0A35, 0x0A36 ],
		[ 0x0A38, 0x0A39 ],
		[ 0x0A3E, 0x0A42 ],
		[ 0x0A47, 0x0A48 ],
		[ 0x0A4B, 0x0A4D ],
		[ 0x0A59, 0x0A5C ],
		[ 0x0A5E, 0x0A5E ],
		[ 0x0A66, 0x0A6F ],
		[ 0x0A74, 0x0A74 ],
		[ 0x0A81, 0x0A83 ],
		[ 0x0A85, 0x0A8B ],
		[ 0x0A8D, 0x0A8D ],
		[ 0x0A8F, 0x0A91 ],
		[ 0x0A93, 0x0AA8 ],
		[ 0x0AAA, 0x0AB0 ],
		[ 0x0AB2, 0x0AB3 ],
		[ 0x0AB5, 0x0AB9 ],
		[ 0x0ABD, 0x0AC5 ],
		[ 0x0AC7, 0x0AC9 ],
		[ 0x0ACB, 0x0ACD ],
		[ 0x0AD0, 0x0AD0 ],
		[ 0x0AE0, 0x0AE0 ],
		[ 0x0AE6, 0x0AEF ],
		[ 0x0B01, 0x0B03 ],
		[ 0x0B05, 0x0B0C ],
		[ 0x0B0F, 0x0B10 ],
		[ 0x0B13, 0x0B28 ],
		[ 0x0B2A, 0x0B30 ],
		[ 0x0B32, 0x0B33 ],
		[ 0x0B36, 0x0B39 ],
		[ 0x0B3D, 0x0B3D ],
		[ 0x0B3E, 0x0B43 ],
		[ 0x0B47, 0x0B48 ],
		[ 0x0B4B, 0x0B4D ],
		[ 0x0B5C, 0x0B5D ],
		[ 0x0B5F, 0x0B61 ],
		[ 0x0B66, 0x0B6F ],
		[ 0x0B82, 0x0B83 ],
		[ 0x0B85, 0x0B8A ],
		[ 0x0B8E, 0x0B90 ],
		[ 0x0B92, 0x0B95 ],
		[ 0x0B99, 0x0B9A ],
		[ 0x0B9C, 0x0B9C ],
		[ 0x0B9E, 0x0B9F ],
		[ 0x0BA3, 0x0BA4 ],
		[ 0x0BA8, 0x0BAA ],
		[ 0x0BAE, 0x0BB5 ],
		[ 0x0BB7, 0x0BB9 ],
		[ 0x0BBE, 0x0BC2 ],
		[ 0x0BC6, 0x0BC8 ],
		[ 0x0BCA, 0x0BCD ],
		[ 0x0BE7, 0x0BEF ],
		[ 0x0C01, 0x0C03 ],
		[ 0x0C05, 0x0C0C ],
		[ 0x0C0E, 0x0C10 ],
		[ 0x0C12, 0x0C28 ],
		[ 0x0C2A, 0x0C33 ],
		[ 0x0C35, 0x0C39 ],
		[ 0x0C3E, 0x0C44 ],
		[ 0x0C46, 0x0C48 ],
		[ 0x0C4A, 0x0C4D ],
		[ 0x0C60, 0x0C61 ],
		[ 0x0C66, 0x0C6F ],
		[ 0x0C82, 0x0C83 ],
		[ 0x0C85, 0x0C8C ],
		[ 0x0C8E, 0x0C90 ],
		[ 0x0C92, 0x0CA8 ],
		[ 0x0CAA, 0x0CB3 ],
		[ 0x0CB5, 0x0CB9 ],
		[ 0x0CBE, 0x0CC4 ],
		[ 0x0CC6, 0x0CC8 ],
		[ 0x0CCA, 0x0CCD ],
		[ 0x0CDE, 0x0CDE ],
		[ 0x0CE0, 0x0CE1 ],
		[ 0x0CE6, 0x0CEF ],
		[ 0x0D02, 0x0D03 ],
		[ 0x0D05, 0x0D0C ],
		[ 0x0D0E, 0x0D10 ],
		[ 0x0D12, 0x0D28 ],
		[ 0x0D2A, 0x0D39 ],
		[ 0x0D3E, 0x0D43 ],
		[ 0x0D46, 0x0D48 ],
		[ 0x0D4A, 0x0D4D ],
		[ 0x0D60, 0x0D61 ],
		[ 0x0D66, 0x0D6F ],
		[ 0x0E01, 0x0E3A ],
		[ 0x0E40, 0x0E5B ],
	//	{ 0x0E50, 0x0E59 },
		[ 0x0E81, 0x0E82 ],
		[ 0x0E84, 0x0E84 ],
		[ 0x0E87, 0x0E88 ],
		[ 0x0E8A, 0x0E8A ],
		[ 0x0E8D, 0x0E8D ],
		[ 0x0E94, 0x0E97 ],
		[ 0x0E99, 0x0E9F ],
		[ 0x0EA1, 0x0EA3 ],
		[ 0x0EA5, 0x0EA5 ],
		[ 0x0EA7, 0x0EA7 ],
		[ 0x0EAA, 0x0EAB ],
		[ 0x0EAD, 0x0EAE ],
		[ 0x0EB0, 0x0EB9 ],
		[ 0x0EBB, 0x0EBD ],
		[ 0x0EC0, 0x0EC4 ],
		[ 0x0EC6, 0x0EC6 ],
		[ 0x0EC8, 0x0ECD ],
		[ 0x0ED0, 0x0ED9 ],
		[ 0x0EDC, 0x0EDD ],
		[ 0x0F00, 0x0F00 ],
		[ 0x0F18, 0x0F19 ],
		[ 0x0F20, 0x0F33 ],
		[ 0x0F35, 0x0F35 ],
		[ 0x0F37, 0x0F37 ],
		[ 0x0F39, 0x0F39 ],
		[ 0x0F3E, 0x0F47 ],
		[ 0x0F49, 0x0F69 ],
		[ 0x0F71, 0x0F84 ],
		[ 0x0F86, 0x0F8B ],
		[ 0x0F90, 0x0F95 ],
		[ 0x0F97, 0x0F97 ],
		[ 0x0F99, 0x0FAD ],
		[ 0x0FB1, 0x0FB7 ],
		[ 0x0FB9, 0x0FB9 ],
		[ 0x10A0, 0x10C5 ],
		[ 0x10D0, 0x10F6 ],
		[ 0x1E00, 0x1E9B ],
		[ 0x1EA0, 0x1EF9 ],
		[ 0x1F00, 0x1F15 ],
		[ 0x1F18, 0x1F1D ],
		[ 0x1F20, 0x1F45 ],
		[ 0x1F48, 0x1F4D ],
		[ 0x1F50, 0x1F57 ],
		[ 0x1F59, 0x1F59 ],
		[ 0x1F5B, 0x1F5B ],
		[ 0x1F5D, 0x1F5D ],
		[ 0x1F5F, 0x1F7D ],
		[ 0x1F80, 0x1FB4 ],
		[ 0x1FB6, 0x1FBC ],
		[ 0x1FBE, 0x1FBE ],
		[ 0x1FC2, 0x1FC4 ],
		[ 0x1FC6, 0x1FCC ],
		[ 0x1FD0, 0x1FD3 ],
		[ 0x1FD6, 0x1FDB ],
		[ 0x1FE0, 0x1FEC ],
		[ 0x1FF2, 0x1FF4 ],
		[ 0x1FF6, 0x1FFC ],
		[ 0x203F, 0x2040 ],
		[ 0x207F, 0x207F ],
		[ 0x2102, 0x2102 ],
		[ 0x2107, 0x2107 ],
		[ 0x210A, 0x2113 ],
		[ 0x2115, 0x2115 ],
		[ 0x2118, 0x211D ],
		[ 0x2124, 0x2124 ],
		[ 0x2126, 0x2126 ],
		[ 0x2128, 0x2128 ],
		[ 0x212A, 0x2131 ],
		[ 0x2133, 0x2138 ],
		[ 0x2160, 0x2182 ],
		[ 0x3005, 0x3007 ],
		[ 0x3021, 0x3029 ],
		[ 0x3041, 0x3093 ],
		[ 0x309B, 0x309C ],
		[ 0x30A1, 0x30F6 ],
		[ 0x30FB, 0x30FC ],
		[ 0x3105, 0x312C ],
		[ 0x4E00, 0x9FA5 ],
		[ 0xAC00, 0xD7A3 ],
	];

debug {
	for (int i = 0; i < table.length; i++)
	{
		//printf("%x\n", table[i][0]);
		assert(table[i][0] <= table[i][1]);
		if (i < table.length - 1)
			assert(table[i][1] < table[i + 1][0]);
	}
}

	if (u > 0xD7A3)
		goto Lisnot;

	// Binary search
	int mid;
	int low;
	int high;

	low = 0;
	high = table.length - 1;
	while (low <= high)
	{
		mid = (low + high) >> 1;
		if (u < table[mid][0])
			high = mid - 1;
		else if (u > table[mid][1])
			low = mid + 1;
		else
			goto Lis;
	}

Lisnot:
debug {
	for (int i = 0; i < table.length; i++)
	{
		assert(u < table[i][0] || u > table[i][1]);
	}
}
	return false;

Lis:
debug {
	for (int i = 0; i < table.length; i++)
	{
		if (u >= table[i][0] && u <= table[i][1])
			return 1;
	}
	assert(0);		// should have been in table
}
	return true;
}

import dmd.TObject;

class Lexer : TObject
{
    Loc loc;			// for error messages

    ubyte* base;	// pointer to start of buffer
    ubyte* end;		// past end of buffer
    ubyte* p;		// current character
    Token token;
    Module mod;
    int doDocComment;		// collect doc comment information
    int anyToken;		// !=0 means seen at least one token
    int commentToken;		// !=0 means comments are TOKcomment's

    this(Module mod, ubyte* base, uint begoffset, uint endoffset, int doDocComment, int commentToken)
	{
		register();
		loc = Loc(mod, 1);

		memset(&token,0,token.sizeof);
		this.base = base;
		this.end  = base + endoffset;
		p = base + begoffset;
		this.mod = mod;
		this.doDocComment = doDocComment;
		this.anyToken = 0;
		this.commentToken = commentToken;
		//initKeywords();

		/* If first line starts with '#!', ignore the line
		 */

		if (p[0] == '#' && p[1] =='!')
		{
			p += 2;
			while (1)
			{
				ubyte c = *p;
				switch (c)
				{
				case '\n':
					p++;
					break;

				case '\r':
					p++;
					if (*p == '\n')
					p++;
					break;

				case 0:
				case 0x1A:
					break;

				default:
					if (c & 0x80)
					{
						uint u = decodeUTF();
						if (u == PS || u == LS)
							break;
					}
					p++;
					continue;
				}
				break;
			}
			loc.linnum = 2;
		}
	}

version (DMDV2) {
	enum Keyword[] keywords =
	[
	//    {	"",		TOK	},

		{	"this",		TOK.TOKthis		},
		{	"super",	TOK.TOKsuper	},
		{	"assert",	TOK.TOKassert	},
		{	"null",		TOK.TOKnull		},
		{	"true",		TOK.TOKtrue		},
		{	"false",	TOK.TOKfalse	},
		{	"cast",		TOK.TOKcast		},
		{	"new",		TOK.TOKnew		},
		{	"delete",	TOK.TOKdelete	},
		{	"throw",	TOK.TOKthrow	},
		{	"module",	TOK.TOKmodule	},
		{	"pragma",	TOK.TOKpragma	},
		{	"typeof",	TOK.TOKtypeof	},
		{	"typeid",	TOK.TOKtypeid	},

		{	"template",	TOK.TOKtemplate	},

		{	"void",		TOK.TOKvoid		},
		{	"byte",		TOK.TOKint8		},
		{	"ubyte",	TOK.TOKuns8		},
		{	"short",	TOK.TOKint16	},
		{	"ushort",	TOK.TOKuns16	},
		{	"int",		TOK.TOKint32	},
		{	"uint",		TOK.TOKuns32	},
		{	"long",		TOK.TOKint64	},
		{	"ulong",	TOK.TOKuns64	},
		{	"cent",		TOK.TOKcent,	},
		{	"ucent",	TOK.TOKucent,	},
		{	"float",	TOK.TOKfloat32	},
		{	"double",	TOK.TOKfloat64	},
		{	"real",		TOK.TOKfloat80	},

		{	"bool",		TOK.TOKbool		},
		{	"char",		TOK.TOKchar		},
		{	"wchar",	TOK.TOKwchar	},
		{	"dchar",	TOK.TOKdchar	},

		{	"ifloat",	TOK.TOKimaginary32	},
		{	"idouble",	TOK.TOKimaginary64	},
		{	"ireal",	TOK.TOKimaginary80	},

		{	"cfloat",	TOK.TOKcomplex32	},
		{	"cdouble",	TOK.TOKcomplex64	},
		{	"creal",	TOK.TOKcomplex80	},

		{	"delegate",	TOK.TOKdelegate	},
		{	"function",	TOK.TOKfunction	},

		{	"is",		TOK.TOKis		},
		{	"if",		TOK.TOKif		},
		{	"else",		TOK.TOKelse		},
		{	"while",	TOK.TOKwhile	},
		{	"for",		TOK.TOKfor		},
		{	"do",		TOK.TOKdo		},
		{	"switch",	TOK.TOKswitch	},
		{	"case",		TOK.TOKcase		},
		{	"default",	TOK.TOKdefault	},
		{	"break",	TOK.TOKbreak	},
		{	"continue",	TOK.TOKcontinue	},
		{	"synchronized",	TOK.TOKsynchronized	},
		{	"return",	TOK.TOKreturn	},
		{	"goto",		TOK.TOKgoto		},
		{	"try",		TOK.TOKtry		},
		{	"catch",	TOK.TOKcatch	},
		{	"finally",	TOK.TOKfinally	},
		{	"with",		TOK.TOKwith		},
		{	"asm",		TOK.TOKasm		},
		{	"foreach",	TOK.TOKforeach	},
		{	"foreach_reverse",	TOK.TOKforeach_reverse	},
		{	"scope",	TOK.TOKscope	},

		{	"struct",	TOK.TOKstruct	},
		{	"class",	TOK.TOKclass	},
		{	"interface",	TOK.TOKinterface	},
		{	"union",	TOK.TOKunion	},
		{	"enum",		TOK.TOKenum		},
		{	"import",	TOK.TOKimport	},
		{	"mixin",	TOK.TOKmixin	},
		{	"static",	TOK.TOKstatic	},
		{	"final",	TOK.TOKfinal	},
		{	"const",	TOK.TOKconst	},
		{	"typedef",	TOK.TOKtypedef	},
		{	"alias",	TOK.TOKalias	},
		{	"override",	TOK.TOKoverride	},
		{	"abstract",	TOK.TOKabstract	},
		{	"volatile",	TOK.TOKvolatile	},
		{	"debug",	TOK.TOKdebug	},
		{	"deprecated",	TOK.TOKdeprecated	},
		{	"in",		TOK.TOKin		},
		{	"out",		TOK.TOKout		},
		{	"inout",	TOK.TOKinout	},
		{	"lazy",		TOK.TOKlazy		},
		{	"auto",		TOK.TOKauto		},

		{	"align",	TOK.TOKalign	},
		{	"extern",	TOK.TOKextern	},
		{	"private",	TOK.TOKprivate	},
		{	"package",	TOK.TOKpackage	},
		{	"protected",	TOK.TOKprotected	},
		{	"public",	TOK.TOKpublic	},
		{	"export",	TOK.TOKexport	},

		{	"body",		TOK.TOKbody		},
		{	"invariant",	TOK.TOKinvariant	},
		{	"unittest",	TOK.TOKunittest	},
		{	"version",	TOK.TOKversion	},
		//{	"manifest",	TOK.TOKmanifest	},

		// Added after 1.0
		{	"ref",		TOK.TOKref		},
		{	"macro",	TOK.TOKmacro	},
		{	"pure",		TOK.TOKpure		},
		{	"nothrow",	TOK.TOKnothrow	},
		{	"__thread",	TOK.TOKtls		},
		{	"__gshared",	TOK.TOKgshared	},
		{	"__traits",	TOK.TOKtraits	},
		{	"__overloadset", TOK.TOKoverloadset	},
		{	"__FILE__",	TOK.TOKfile		},
		{	"__LINE__",	TOK.TOKline		},
		{	"shared",	TOK.TOKshared	},
		{	"immutable",	TOK.TOKimmutable	},
	];
} else {
	enum Keyword[] keywords =
	[
	//    {	"",		TOK	},

		{	"this",		TOK.TOKthis		},
		{	"super",	TOK.TOKsuper	},
		{	"assert",	TOK.TOKassert	},
		{	"null",		TOK.TOKnull		},
		{	"true",		TOK.TOKtrue		},
		{	"false",	TOK.TOKfalse	},
		{	"cast",		TOK.TOKcast		},
		{	"new",		TOK.TOKnew		},
		{	"delete",	TOK.TOKdelete	},
		{	"throw",	TOK.TOKthrow	},
		{	"module",	TOK.TOKmodule	},
		{	"pragma",	TOK.TOKpragma	},
		{	"typeof",	TOK.TOKtypeof	},
		{	"typeid",	TOK.TOKtypeid	},

		{	"template",	TOK.TOKtemplate	},

		{	"void",		TOK.TOKvoid		},
		{	"byte",		TOK.TOKint8		},
		{	"ubyte",	TOK.TOKuns8		},
		{	"short",	TOK.TOKint16	},
		{	"ushort",	TOK.TOKuns16	},
		{	"int",		TOK.TOKint32	},
		{	"uint",		TOK.TOKuns32	},
		{	"long",		TOK.TOKint64	},
		{	"ulong",	TOK.TOKuns64	},
		{	"cent",		TOK.TOKcent,	},
		{	"ucent",	TOK.TOKucent,	},
		{	"float",	TOK.TOKfloat32	},
		{	"double",	TOK.TOKfloat64	},
		{	"real",		TOK.TOKfloat80	},

		{	"bool",		TOK.TOKbool		},
		{	"char",		TOK.TOKchar		},
		{	"wchar",	TOK.TOKwchar	},
		{	"dchar",	TOK.TOKdchar	},

		{	"ifloat",	TOK.TOKimaginary32	},
		{	"idouble",	TOK.TOKimaginary64	},
		{	"ireal",	TOK.TOKimaginary80	},

		{	"cfloat",	TOK.TOKcomplex32	},
		{	"cdouble",	TOK.TOKcomplex64	},
		{	"creal",	TOK.TOKcomplex80	},

		{	"delegate",	TOK.TOKdelegate	},
		{	"function",	TOK.TOKfunction	},

		{	"is",		TOK.TOKis		},
		{	"if",		TOK.TOKif		},
		{	"else",		TOK.TOKelse		},
		{	"while",	TOK.TOKwhile	},
		{	"for",		TOK.TOKfor		},
		{	"do",		TOK.TOKdo		},
		{	"switch",	TOK.TOKswitch	},
		{	"case",		TOK.TOKcase		},
		{	"default",	TOK.TOKdefault	},
		{	"break",	TOK.TOKbreak	},
		{	"continue",	TOK.TOKcontinue	},
		{	"synchronized",	TOK.TOKsynchronized	},
		{	"return",	TOK.TOKreturn	},
		{	"goto",		TOK.TOKgoto		},
		{	"try",		TOK.TOKtry		},
		{	"catch",	TOK.TOKcatch	},
		{	"finally",	TOK.TOKfinally	},
		{	"with",		TOK.TOKwith		},
		{	"asm",		TOK.TOKasm		},
		{	"foreach",	TOK.TOKforeach	},
		{	"foreach_reverse",	TOK.TOKforeach_reverse	},
		{	"scope",	TOK.TOKscope	},

		{	"struct",	TOK.TOKstruct	},
		{	"class",	TOK.TOKclass	},
		{	"interface",	TOK.TOKinterface	},
		{	"union",	TOK.TOKunion	},
		{	"enum",		TOK.TOKenum		},
		{	"import",	TOK.TOKimport	},
		{	"mixin",	TOK.TOKmixin	},
		{	"static",	TOK.TOKstatic	},
		{	"final",	TOK.TOKfinal	},
		{	"const",	TOK.TOKconst	},
		{	"typedef",	TOK.TOKtypedef	},
		{	"alias",	TOK.TOKalias	},
		{	"override",	TOK.TOKoverride	},
		{	"abstract",	TOK.TOKabstract	},
		{	"volatile",	TOK.TOKvolatile	},
		{	"debug",	TOK.TOKdebug	},
		{	"deprecated",	TOK.TOKdeprecated	},
		{	"in",		TOK.TOKin		},
		{	"out",		TOK.TOKout		},
		{	"inout",	TOK.TOKinout	},
		{	"lazy",		TOK.TOKlazy		},
		{	"auto",		TOK.TOKauto		},

		{	"align",	TOK.TOKalign	},
		{	"extern",	TOK.TOKextern	},
		{	"private",	TOK.TOKprivate	},
		{	"package",	TOK.TOKpackage	},
		{	"protected",	TOK.TOKprotected	},
		{	"public",	TOK.TOKpublic	},
		{	"export",	TOK.TOKexport	},

		{	"body",		TOK.TOKbody		},
		{	"invariant",	TOK.TOKinvariant	},
		{	"unittest",	TOK.TOKunittest	},
		{	"version",	TOK.TOKversion	},
		//{	"manifest",	TOK.TOKmanifest	},

		// Added after 1.0
		{	"ref",		TOK.TOKref		},
		{	"macro",	TOK.TOKmacro	},
	];
}

	static __gshared ubyte[256] cmtable;
	enum CMoctal =	0x1;
	enum  CMhex =	0x2;
	enum  CMidchar =	0x4;

	ubyte isoctal (ubyte c) { return cmtable[c] & CMoctal; }
	ubyte ishex   (ubyte c) { return cmtable[c] & CMhex; }
	ubyte isidchar(ubyte c) { return cmtable[c] & CMidchar; }

	static void cmtable_init()
	{
		for (uint c = 0; c < cmtable.length; c++)
		{
			if ('0' <= c && c <= '7')
				cmtable[c] |= CMoctal;
			if (isdigit(c) || ('a' <= c && c <= 'f') || ('A' <= c && c <= 'F'))
				cmtable[c] |= CMhex;
			if (isalnum(c) || c == '_')
				cmtable[c] |= CMidchar;
		}
	}

	static ref StringTable stringtable()
	{
		return global.stringtable;
	}

	static OutBuffer stringbuffer()
	{
		return global.stringbuffer;
	}

    static void initKeywords()
	{
		uint nkeywords = keywords.length;

		if (global.params.Dversion == 1)
			nkeywords -= 2;

		cmtable_init();

		for (uint u = 0; u < nkeywords; u++)
		{
			//printf("keyword[%d] = '%.*s'\n",u, keywords[u].name);
			string s = keywords[u].name;
			TOK v = keywords[u].value;
			Object* sv = stringtable.insert(s);
			*sv = new Identifier(s, v);

			//printf("tochars[%d] = '%s'\n",v, s);
			Token.tochars[v] = s;
		}

		Token.tochars[TOK.TOKeof]		= "EOF";
		Token.tochars[TOK.TOKlcurly]		= "{";
		Token.tochars[TOK.TOKrcurly]		= "}";
		Token.tochars[TOK.TOKlparen]		= "(";
		Token.tochars[TOK.TOKrparen]		= ")";
		Token.tochars[TOK.TOKlbracket]		= "[";
		Token.tochars[TOK.TOKrbracket]		= "]";
		Token.tochars[TOK.TOKsemicolon]	= ";";
		Token.tochars[TOK.TOKcolon]		= ":";
		Token.tochars[TOK.TOKcomma]		= ",";
		Token.tochars[TOK.TOKdot]		= ".";
		Token.tochars[TOK.TOKxor]		= "^";
		Token.tochars[TOK.TOKxorass]		= "^=";
		Token.tochars[TOK.TOKassign]		= "=";
		Token.tochars[TOK.TOKconstruct]	= "=";
version (DMDV2) {
		Token.tochars[TOK.TOKblit]		= "=";
}
		Token.tochars[TOK.TOKlt]		= "<";
		Token.tochars[TOK.TOKgt]		= ">";
		Token.tochars[TOK.TOKle]		= "<=";
		Token.tochars[TOK.TOKge]		= ">=";
		Token.tochars[TOK.TOKequal]		= "==";
		Token.tochars[TOK.TOKnotequal]		= "!=";
		Token.tochars[TOK.TOKnotidentity]	= "!is";
		Token.tochars[TOK.TOKtobool]		= "!!";

		Token.tochars[TOK.TOKunord]		= "!<>=";
		Token.tochars[TOK.TOKue]		= "!<>";
		Token.tochars[TOK.TOKlg]		= "<>";
		Token.tochars[TOK.TOKleg]		= "<>=";
		Token.tochars[TOK.TOKule]		= "!>";
		Token.tochars[TOK.TOKul]		= "!>=";
		Token.tochars[TOK.TOKuge]		= "!<";
		Token.tochars[TOK.TOKug]		= "!<=";

		Token.tochars[TOK.TOKnot]		= "!";
		Token.tochars[TOK.TOKtobool]		= "!!";
		Token.tochars[TOK.TOKshl]		= "<<";
		Token.tochars[TOK.TOKshr]		= ">>";
		Token.tochars[TOK.TOKushr]		= ">>>";
		Token.tochars[TOK.TOKadd]		= "+";
		Token.tochars[TOK.TOKmin]		= "-";
		Token.tochars[TOK.TOKmul]		= "*";
		Token.tochars[TOK.TOKdiv]		= "/";
		Token.tochars[TOK.TOKmod]		= "%";
		Token.tochars[TOK.TOKslice]		= "..";
		Token.tochars[TOK.TOKdotdotdot]	= "...";
		Token.tochars[TOK.TOKand]		= "&";
		Token.tochars[TOK.TOKandand]		= "&&";
		Token.tochars[TOK.TOKor]		= "|";
		Token.tochars[TOK.TOKoror]		= "||";
		Token.tochars[TOK.TOKarray]		= "[]";
		Token.tochars[TOK.TOKindex]		= "[i]";
		Token.tochars[TOK.TOKaddress]		= "&";
		Token.tochars[TOK.TOKstar]		= "*";
		Token.tochars[TOK.TOKtilde]		= "~";
		Token.tochars[TOK.TOKdollar]		= "$";
		Token.tochars[TOK.TOKcast]		= "cast";
		Token.tochars[TOK.TOKplusplus]		= "++";
		Token.tochars[TOK.TOKminusminus]	= "--";
		Token.tochars[TOK.TOKtype]		= "type";
		Token.tochars[TOK.TOKquestion]		= "?";
		Token.tochars[TOK.TOKneg]		= "-";
		Token.tochars[TOK.TOKuadd]		= "+";
		Token.tochars[TOK.TOKvar]		= "var";
		Token.tochars[TOK.TOKaddass]		= "+=";
		Token.tochars[TOK.TOKminass]		= "-=";
		Token.tochars[TOK.TOKmulass]		= "*=";
		Token.tochars[TOK.TOKdivass]		= "/=";
		Token.tochars[TOK.TOKmodass]		= "%=";
		Token.tochars[TOK.TOKshlass]		= "<<=";
		Token.tochars[TOK.TOKshrass]		= ">>=";
		Token.tochars[TOK.TOKushrass]		= ">>>=";
		Token.tochars[TOK.TOKandass]		= "&=";
		Token.tochars[TOK.TOKorass]		= "|=";
		Token.tochars[TOK.TOKcatass]		= "~=";
		Token.tochars[TOK.TOKcat]		= "~";
		Token.tochars[TOK.TOKcall]		= "call";
		Token.tochars[TOK.TOKidentity]		= "is";
		Token.tochars[TOK.TOKnotidentity]	= "!is";

		Token.tochars[TOK.TOKorass]		= "|=";
		Token.tochars[TOK.TOKidentifier]	= "identifier";
		Token.tochars[TOK.TOKat]		= "@";
        Token.tochars[TOK.TOKpow]		= "^^";
        Token.tochars[TOK.TOKpowass]		= "^^=";

		 // For debugging
		Token.tochars[TOKerror]		= "error";
		Token.tochars[TOK.TOKdotexp]		= "dotexp";
		Token.tochars[TOK.TOKdotti]		= "dotti";
		Token.tochars[TOK.TOKdotvar]		= "dotvar";
		Token.tochars[TOK.TOKdottype]		= "dottype";
		Token.tochars[TOK.TOKsymoff]		= "symoff";
		Token.tochars[TOK.TOKarraylength]	= "arraylength";
		Token.tochars[TOK.TOKarrayliteral]	= "arrayliteral";
		Token.tochars[TOK.TOKassocarrayliteral] = "assocarrayliteral";
		Token.tochars[TOK.TOKstructliteral]	= "structliteral";
		Token.tochars[TOK.TOKstring]		= "string";
		Token.tochars[TOK.TOKdsymbol]		= "symbol";
		Token.tochars[TOK.TOKtuple]		= "tuple";
		Token.tochars[TOK.TOKdeclaration]	= "declaration";
		Token.tochars[TOK.TOKdottd]		= "dottd";
		Token.tochars[TOK.TOKon_scope_exit]	= "scope(exit)";
		Token.tochars[TOK.TOKon_scope_success]	= "scope(success)";
		Token.tochars[TOK.TOKon_scope_failure]	= "scope(failure)";
	}

    static Identifier idPool(string s)
	{
		Object* sv = stringtable.update(s);
		Identifier id = cast(Identifier) *sv;
		if (id is null)
		{
			id = new Identifier(s, TOK.TOKidentifier);
			*sv = id;
		}

		return id;
	}

    static Identifier uniqueId(string s)
	{
		return uniqueId(s, ++global.num);
	}

	/*********************************************
	 * Create a unique identifier using the prefix s.
	 */
    static Identifier uniqueId(string s, int num)
	{
		char[32] buffer;
		size_t slen = s.length;

		assert(slen + num.sizeof * 3 + 1 <= buffer.sizeof);
		int len = sprintf(buffer.ptr, "%.*s%d", s, num);

		return idPool(buffer[0..len].idup);
	}

    TOK nextToken()
	{
		Token *t;

		if (token.next)
		{
			t = token.next;
			memcpy(&token, t, Token.sizeof);
			t.next = global.freelist;
			global.freelist = t;
		}
		else
		{
			scan(&token);
		}

		//token.print();
		return token.value;
	}

	/***********************
	 * Look ahead at next token's value.
	 */
    TOK peekNext()
	{
		return peek(&token).value;
	}

	/***********************
	 * Look 2 tokens ahead at value.
	 */
    TOK peekNext2()
	{
		Token* t = peek(&token);
		return peek(t).value;
	}

    void scan(Token* t)
	{
		uint lastLine = loc.linnum;
		uint linnum;

		t.blockComment = null;
		t.lineComment = null;
		while (1)
		{
			t.ptr = p;
			//printf("p = %p, *p = '%c'\n",p,*p);
			switch (*p)
			{
				case 0:
				case 0x1A:
				t.value = TOK.TOKeof;			// end of file
				return;

				case ' ':
				case '\t':
				case '\v':
				case '\f':
				p++;
				continue;			// skip white space

				case '\r':
				p++;
				if (*p != '\n')			// if CR stands by itself
					loc.linnum++;
				continue;			// skip white space

				case '\n':
				p++;
				loc.linnum++;
				continue;			// skip white space

				case '0':  	case '1':   case '2':   case '3':   case '4':
				case '5':  	case '6':   case '7':   case '8':   case '9':
				t.value = number(t);
				return;

version (CSTRINGS) {
				case '\'':
				t.value = charConstant(t, 0);
				return;

				case '"':
				t.value = stringConstant(t,0);
				return;

				case 'l':
				case 'L':
				if (p[1] == '\'')
				{
					p++;
					t.value = charConstant(t, 1);
					return;
				}
				else if (p[1] == '"')
				{
					p++;
					t.value = stringConstant(t, 1);
					return;
				}
} else {
				case '\'':
				t.value = charConstant(t,0);
				return;

				case 'r':
				if (p[1] != '"')
					goto case_ident;
				p++;
				case '`':
				t.value = wysiwygStringConstant(t, *p);
				return;

				case 'x':
				if (p[1] != '"')
					goto case_ident;
				p++;
				t.value = hexStringConstant(t);
				return;

version (DMDV2) {
				case 'q':
				if (p[1] == '"')
				{
					p++;
					t.value = delimitedStringConstant(t);
					return;
				}
				else if (p[1] == '{')
				{
					p++;
					t.value = tokenStringConstant(t);
					return;
				}
				else
					goto case_ident;
}

				case '"':
				t.value = escapeStringConstant(t,0);
				return;
version (TEXTUAL_ASSEMBLY_OUT) {
} else {
				case '\\':			// escaped string literal
				{	uint c;
				ubyte* pstart = p;

				stringbuffer.reset();
				do
				{
					p++;
					switch (*p)
					{
					case 'u':
					case 'U':
					case '&':
						c = escapeSequence();
						stringbuffer.writeUTF8(c);
						break;

					default:
						c = escapeSequence();
						stringbuffer.writeByte(c);
						break;
					}
				} while (*p == '\\');
				t.len = stringbuffer.offset;
				stringbuffer.writeByte(0);
				char* cc = cast(char*)GC.malloc(stringbuffer.offset);
				memcpy(cc, stringbuffer.data, stringbuffer.offset);
				t.ustring = cc;
				t.postfix = 0;
				t.value = TOK.TOKstring;
				if (!global.params.useDeprecated)
					error("Escape String literal %.*s is deprecated, use double quoted string literal \"%.*s\" instead", p - pstart, pstart, p - pstart, pstart);
				return;
				}
}
				case 'l':
				case 'L':
}
				case 'a':  	case 'b':   case 'c':   case 'd':   case 'e':
				case 'f':  	case 'g':   case 'h':   case 'i':   case 'j':
				case 'k':  	            case 'm':   case 'n':   case 'o':
version (DMDV2) {
				case 'p':  	/*case 'q': case 'r':*/ case 's':   case 't':
} else {
				case 'p':  	case 'q': /*case 'r':*/ case 's':   case 't':
}
				case 'u':  	case 'v':   case 'w': /*case 'x':*/ case 'y':
				case 'z':
				case 'A':  	case 'B':   case 'C':   case 'D':   case 'E':
				case 'F':  	case 'G':   case 'H':   case 'I':   case 'J':
				case 'K':  	            case 'M':   case 'N':   case 'O':
				case 'P':  	case 'Q':   case 'R':   case 'S':   case 'T':
				case 'U':  	case 'V':   case 'W':   case 'X':   case 'Y':
				case 'Z':
				case '_':
				case_ident:
				{
                ubyte c;

		        while (1)
		        {
		            c = *++p;
		            if (isidchar(c))
			            continue;
		            else if (c & 0x80)
		            {
                        ubyte *s = p;
			            uint u = decodeUTF();
			            if (isUniAlpha(u))
    			            continue;
			            error("char 0x%04x not allowed in identifier", u);
			            p = s;
		            }
		            break;
		        }

                auto s = cast(string)(t.ptr[0.. p - t.ptr]);
		        Object* sv = stringtable.update(s);
		        Identifier id = cast(Identifier) *sv;

				if (id is null)
				{
				    id = new Identifier(s, TOK.TOKidentifier);
					*sv = id;
				}
				t.ident = id;
				t.value = cast(TOK) id.value;
				anyToken = 1;
				if (*t.ptr == '_')	// if special identifier token
				{
///version (DMDV1) {
///					if (mod && id == Id.FILE)
///					{
///					t.ustring = cast(ubyte*)(loc.filename ? loc.filename : mod.ident.toChars());
///					goto Lstr;
///					}
///					else if (mod && id == Id.LINE)
///					{
///					t.value = TOK.TOKint64v;
///					t.uns64value = loc.linnum;
///					}
///					else
///}
					if (id == Id.DATE)
					{
					t.ustring = global.date.ptr;
					goto Lstr;
					}
					else if (id == Id.TIME)
					{
					t.ustring = global.time.ptr;
					goto Lstr;
					}
					else if (id == Id.VENDOR)
					{
					t.ustring = "Digital Mars D".ptr;
					goto Lstr;
					}
					else if (id == Id.TIMESTAMP)
					{
					t.ustring = global.timestamp.ptr;
					 Lstr:
					t.value = TOK.TOKstring;
					 Llen:
					t.postfix = 0;
					t.len = strlen(cast(char*)t.ustring);
					}
					else if (id == Id.VERSIONX)
					{
						uint major = 0;
						uint minor = 0;

						foreach (char cc; global.version_[1..$])
						{
							if (isdigit(cc))
								minor = minor * 10 + cc - '0';
							else if (cc == '.')
							{
								major = minor;
								minor = 0;
							}
							else
								break;
						}
						t.value = TOK.TOKint64v;
						t.uns64value = major * 1000 + minor;
					}
///version (DMDV2) {
					else if (id == Id.EOFX)
					{
					t.value = TOK.TOKeof;
					// Advance scanner to end of file
					while (!(*p == 0 || *p == 0x1A))
						p++;
					}
///}
				}
				//printf("t.value = %d\n",t.value);
				return;
				}

				case '/':
				p++;
				switch (*p)
				{
					case '=':
						p++;
						t.value = TOK.TOKdivass;
						return;

					case '*':
						p++;
						linnum = loc.linnum;
						while (1)
						{
							while (1)
							{
								ubyte c = *p;
								switch (c)
								{
									case '/':
									break;

									case '\n':
									loc.linnum++;
									p++;
									continue;

									case '\r':
									p++;
									if (*p != '\n')
										loc.linnum++;
									continue;

									case 0:
									case 0x1A:
									error("unterminated /* */ comment");
									p = end;
									t.value = TOK.TOKeof;
									return;

									default:
									if (c & 0x80)
									{   uint u = decodeUTF();
										if (u == PS || u == LS)
										loc.linnum++;
									}
									p++;
									continue;
								}
								break;
							}
							p++;
							if (p[-2] == '*' && p - 3 != t.ptr)
							break;
						}
						if (commentToken)
						{
							t.value = TOK.TOKcomment;
							return;
						}
						else if (doDocComment && t.ptr[2] == '*' && p - 4 != t.ptr)
						{   // if /** but not /**/
							getDocComment(t, lastLine == linnum);
						}
						continue;

					case '/':		// do // style comments
						linnum = loc.linnum;
						while (1)
						{   ubyte c = *++p;
							switch (c)
							{
							case '\n':
								break;

							case '\r':
								if (p[1] == '\n')
								p++;
								break;

							case 0:
							case 0x1A:
								if (commentToken)
								{
								p = end;
								t.value = TOK.TOKcomment;
								return;
								}
								if (doDocComment && t.ptr[2] == '/' || t.ptr[2] == '!') // '///' or '//!'
								getDocComment(t, lastLine == linnum);
								p = end;
								t.value = TOK.TOKeof;
								return;

							default:
								if (c & 0x80)
								{   uint u = decodeUTF();
								if (u == PS || u == LS)
									break;
								}
								continue;
							}
							break;
						}

						if (commentToken)
						{
							p++;
							loc.linnum++;
							t.value = TOK.TOKcomment;
							return;
						}
						if (doDocComment && t.ptr[2] == '/' || t.ptr[2] == '!') // '///' or '//!'
							getDocComment(t, lastLine == linnum);

						p++;
						loc.linnum++;
						continue;

					case '+':
					{
						int nest;

						linnum = loc.linnum;
						p++;
						nest = 1;
						while (1)
						{   ubyte c = *p;
							switch (c)
							{
							case '/':
								p++;
								if (*p == '+')
								{
								p++;
								nest++;
								}
								continue;

							case '+':
								p++;
								if (*p == '/')
								{
								p++;
								if (--nest == 0)
									break;
								}
								continue;

							case '\r':
								p++;
								if (*p != '\n')
								loc.linnum++;
								continue;

							case '\n':
								loc.linnum++;
								p++;
								continue;

							case 0:
							case 0x1A:
								error("unterminated /+ +/ comment");
								p = end;
								t.value = TOK.TOKeof;
								return;

							default:
								if (c & 0x80)
								{   uint u = decodeUTF();
								if (u == PS || u == LS)
									loc.linnum++;
								}
								p++;
								continue;
							}
							break;
						}
						if (commentToken)
						{
							t.value = TOK.TOKcomment;
							return;
						}
						if (doDocComment && t.ptr[2] == '+' && p - 4 != t.ptr)
						{   // if /++ but not /++/
							getDocComment(t, lastLine == linnum);
						}
						continue;
					}

					default:
						break;	///
				}
				t.value = TOK.TOKdiv;
				return;

				case '.':
				p++;
				if (isdigit(*p))
				{   /* Note that we don't allow ._1 and ._ as being
					 * valid floating point numbers.
					 */
					p--;
					t.value = inreal(t);
				}
				else if (p[0] == '.')
				{
					if (p[1] == '.')
					{   p += 2;
					t.value = TOK.TOKdotdotdot;
					}
					else
					{   p++;
					t.value = TOK.TOKslice;
					}
				}
				else
					t.value = TOK.TOKdot;
				return;

				case '&':
				p++;
				if (*p == '=')
				{   p++;
					t.value = TOK.TOKandass;
				}
				else if (*p == '&')
				{   p++;
					t.value = TOK.TOKandand;
				}
				else
					t.value = TOK.TOKand;
				return;

				case '|':
				p++;
				if (*p == '=')
				{   p++;
					t.value = TOK.TOKorass;
				}
				else if (*p == '|')
				{   p++;
					t.value = TOK.TOKoror;
				}
				else
					t.value = TOK.TOKor;
				return;

				case '-':
				p++;
				if (*p == '=')
				{   p++;
					t.value = TOK.TOKminass;
				}
///		#if 0
///				else if (*p == '>')
///				{   p++;
///					t.value = TOK.TOKarrow;
///				}
///		#endif
				else if (*p == '-')
				{   p++;
					t.value = TOK.TOKminusminus;
				}
				else
					t.value = TOK.TOKmin;
				return;

				case '+':
				p++;
				if (*p == '=')
				{   p++;
					t.value = TOK.TOKaddass;
				}
				else if (*p == '+')
				{   p++;
					t.value = TOK.TOKplusplus;
				}
				else
					t.value = TOK.TOKadd;
				return;

				case '<':
				p++;
				if (*p == '=')
				{   p++;
					t.value = TOK.TOKle;			// <=
				}
				else if (*p == '<')
				{   p++;
					if (*p == '=')
					{   p++;
					t.value = TOK.TOKshlass;		// <<=
					}
					else
					t.value = TOK.TOKshl;		// <<
				}
				else if (*p == '>')
				{   p++;
					if (*p == '=')
					{   p++;
					t.value = TOK.TOKleg;		// <>=
					}
					else
					t.value = TOK.TOKlg;		// <>
				}
				else
					t.value = TOK.TOKlt;			// <
				return;

				case '>':
				p++;
				if (*p == '=')
				{   p++;
					t.value = TOK.TOKge;			// >=
				}
				else if (*p == '>')
				{   p++;
					if (*p == '=')
					{   p++;
					t.value = TOK.TOKshrass;		// >>=
					}
					else if (*p == '>')
					{	p++;
					if (*p == '=')
					{   p++;
						t.value = TOK.TOKushrass;	// >>>=
					}
					else
						t.value = TOK.TOKushr;		// >>>
					}
					else
					t.value = TOK.TOKshr;		// >>
				}
				else
					t.value = TOK.TOKgt;			// >
				return;

				case '!':
				p++;
				if (*p == '=')
				{   p++;
					if (*p == '=' && global.params.Dversion == 1)
					{	p++;
					t.value = TOK.TOKnotidentity;	// !==
					}
					else
					t.value = TOK.TOKnotequal;		// !=
				}
				else if (*p == '<')
				{   p++;
					if (*p == '>')
					{	p++;
					if (*p == '=')
					{   p++;
						t.value = TOK.TOKunord; // !<>=
					}
					else
						t.value = TOK.TOKue;	// !<>
					}
					else if (*p == '=')
					{	p++;
					t.value = TOK.TOKug;	// !<=
					}
					else
					t.value = TOK.TOKuge;	// !<
				}
				else if (*p == '>')
				{   p++;
					if (*p == '=')
					{	p++;
					t.value = TOK.TOKul;	// !>=
					}
					else
					t.value = TOK.TOKule;	// !>
				}
				else
					t.value = TOK.TOKnot;		// !
				return;

				case '=':
				p++;
				if (*p == '=')
				{   p++;
					if (*p == '=' && global.params.Dversion == 1)
					{	p++;
					t.value = TOK.TOKidentity;		// ===
					}
					else
					t.value = TOK.TOKequal;		// ==
				}
				else
					t.value = TOK.TOKassign;		// =
				return;

				case '~':
				p++;
				if (*p == '=')
				{   p++;
					t.value = TOK.TOKcatass;		// ~=
				}
				else
					t.value = TOK.TOKtilde;		// ~
				return;

version(DMDV2) {
	    case '^':
		p++;
		if (*p == '^')
		{   p++;
		    if (*p == '=')
		    {   p++;
			t.value = TOKpowass;  // ^^=
		    }
		    else
			t.value = TOKpow;     // ^^
		}
		else if (*p == '=')
		{   p++;
		    t.value = TOKxorass;    // ^=
		}
		else
		    t.value = TOKxor;       // ^
		return;
}

/*
		#define SINGLE(c,tok) case c: p++; t.value = tok; return;

				SINGLE('(',	TOKlparen)
				SINGLE(')', TOKrparen)
				SINGLE('[', TOKlbracket)
				SINGLE(']', TOKrbracket)
				SINGLE('{', TOKlcurly)
				SINGLE('}', TOKrcurly)
				SINGLE('?', TOKquestion)
				SINGLE(',', TOKcomma)
				SINGLE(';', TOKsemicolon)
				SINGLE(':', TOKcolon)
				SINGLE('$', TOKdollar)
				SINGLE('@', TOKat)

		#undef SINGLE

		#define DOUBLE(c1,tok1,c2,tok2)		\
				case c1:			\
				p++;			\
				if (*p == c2)		\
				{   p++;		\
					t.value = tok2;	\
				}			\
				else			\
					t.value = tok1;	\
				return;

				DOUBLE('*', TOKmul, '=', TOKmulass)
				DOUBLE('%', TOKmod, '=', TOKmodass)
#if DMDV1
				DOUBLE('^', TOKxor, '=', TOKxorass)
#endif
		#undef DOUBLE
*/

				case '(': p++; t.value = TOK.TOKlparen; return;
				case ')': p++; t.value = TOK.TOKrparen; return;
				case '[': p++; t.value = TOK.TOKlbracket; return;
				case ']': p++; t.value = TOK.TOKrbracket; return;
				case '{': p++; t.value = TOK.TOKlcurly; return;
				case '}': p++; t.value = TOK.TOKrcurly; return;
				case '?': p++; t.value = TOK.TOKquestion; return;
				case ',': p++; t.value = TOK.TOKcomma; return;
				case ';': p++; t.value = TOK.TOKsemicolon; return;
				case ':': p++; t.value = TOK.TOKcolon; return;
				case '$': p++; t.value = TOK.TOKdollar; return;
				case '@': p++; t.value = TOK.TOKat; return;

				case '*':
					p++;
					if (*p == '=') {
						p++;
						t.value = TOK.TOKmulass;
					} else {
						t.value = TOK.TOKmul;
					}
					return;

				case '%':
					p++;
					if (*p == '=') {
						p++;
						t.value = TOK.TOKmodass;
					} else {
						t.value = TOK.TOKmod;
					}
					return;
version(DMDV1) {
				case '^':
					p++;
					if (*p == '=') {
						p++;
						t.value = TOK.TOKxorass;
					} else {
						t.value = TOK.TOKxor;
					}
					return;
}
				case '#':
				p++;
				pragma_();
				continue;

				default:
				{	uint c = *p;

				if (c & 0x80)
				{   c = decodeUTF();

					// Check for start of unicode identifier
					if (isUniAlpha(c))
					goto case_ident;

					if (c == PS || c == LS)
					{
					loc.linnum++;
					p++;
					continue;
					}
				}
				if (c < 0x80 && isprint(c))
					error("unsupported char '%c'", c);
				else
					error("unsupported char 0x%02x", c);
				p++;
				continue;
				}
			}
		}
	}

    Token* peek(Token* ct)
	{
		Token* t;

		if (ct.next)
			t = ct.next;
		else
		{
			t = new Token();
			scan(t);
			t.next = null;
			ct.next = t;
		}
		return t;
	}

    Token* peekPastParen(Token* tk)
	{
		//printf("peekPastParen()\n");
		int parens = 1;
		int curlynest = 0;
		while (1)
		{
			tk = peek(tk);
			//tk.print();
			switch (tk.value)
			{
				case TOK.TOKlparen:
				parens++;
				continue;

				case TOK.TOKrparen:
				--parens;
				if (parens)
					continue;
				tk = peek(tk);
				break;

				case TOK.TOKlcurly:
				curlynest++;
				continue;

				case TOK.TOKrcurly:
				if (--curlynest >= 0)
					continue;
				break;

				case TOK.TOKsemicolon:
				if (curlynest)
					continue;
				break;

				case TOK.TOKeof:
				break;

				default:
				continue;
			}
			return tk;
		}
	}

	/*******************************************
	 * Parse escape sequence.
	 */
    uint escapeSequence()
	{
		uint c = *p;

	version (TEXTUAL_ASSEMBLY_OUT) {
		return c;
	}
		int n;
		int ndigits;

		switch (c)
		{
			case '\'':
			case '"':
			case '?':
			case '\\':
			Lconsume:
				p++;
				break;

			case 'a':	c = 7;		goto Lconsume;
			case 'b':	c = 8;		goto Lconsume;
			case 'f':	c = 12;		goto Lconsume;
			case 'n':	c = 10;		goto Lconsume;
			case 'r':	c = 13;		goto Lconsume;
			case 't':	c = 9;		goto Lconsume;
			case 'v':	c = 11;		goto Lconsume;

			case 'u':
				ndigits = 4;
				goto Lhex;
			case 'U':
				ndigits = 8;
				goto Lhex;
			case 'x':
				ndigits = 2;
			Lhex:
				p++;
				c = *p;
				if (ishex(cast(ubyte)c))
				{
					uint v;

					n = 0;
					v = 0;
					while (1)
					{
					if (isdigit(c))
						c -= '0';
					else if (islower(c))
						c -= 'a' - 10;
					else
						c -= 'A' - 10;
					v = v * 16 + c;
					c = *++p;
					if (++n == ndigits)
						break;
					if (!ishex(cast(ubyte)c))
					{   error("escape hex sequence has %d hex digits instead of %d", n, ndigits);
						break;
					}
					}
					if (ndigits != 2 && !utf_isValidDchar(v))
					{	error("invalid UTF character \\U%08x", v);
					v = '?';	// recover with valid UTF character
					}
					c = v;
				}
				else
					error("undefined escape hex sequence \\%c\n",c);
				break;

			case '&':			// named character entity
				for (ubyte* idstart = ++p; true; p++)
				{
					switch (*p)
					{
					case ';':
						c = HtmlNamedEntity(idstart, p - idstart);
						if (c == ~0)
						{
							error("unnamed character entity &%s;", idstart[0..(p - idstart)]);
							c = ' ';
						}
						p++;
						break;

					default:
						if (isalpha(*p) ||
						(p != idstart + 1 && isdigit(*p)))
						continue;
						error("unterminated named entity");
						break;
					}
					break;
				}
				break;

			case 0:
			case 0x1A:			// end of file
				c = '\\';
				break;

			default:
				if (isoctal(cast(ubyte)c))
				{
					uint v;

					n = 0;
					v = 0;
					do
					{
					v = v * 8 + (c - '0');
					c = *++p;
					} while (++n < 3 && isoctal(cast(ubyte)c));
					c = v;
					if (c > 0xFF)
					error("0%03o is larger than a byte", c);
				}
				else
					error("undefined escape sequence \\%c\n",c);
				break;
		}
		return c;
	}

    TOK wysiwygStringConstant(Token* t, int tc)
	{
		uint c;
		Loc start = loc;

		p++;
		stringbuffer.reset();
		while (true)
		{
			c = *p++;
			switch (c)
			{
				case '\n':
					loc.linnum++;
					break;

				case '\r':
					if (*p == '\n')
						continue;	// ignore
					c = '\n';	// treat EndOfLine as \n character
					loc.linnum++;
					break;

				case 0:
				case 0x1A:
					error("unterminated string constant starting at %s", start.toChars());
					t.ustring = "".ptr;
					t.len = 0;
					t.postfix = 0;
					return TOKstring;

				case '"':
				case '`':
					if (c == tc)
					{
						t.len = stringbuffer.offset;
						stringbuffer.writeByte(0);
						char* tmp = cast(char*)GC.malloc(stringbuffer.offset);
						memcpy(tmp, stringbuffer.data, stringbuffer.offset);
						t.ustring = tmp;
						stringPostfix(t);
						return TOKstring;
					}
					break;

				default:
					if (c & 0x80)
					{   p--;
						uint u = decodeUTF();
						p++;
						if (u == PS || u == LS)
							loc.linnum++;
						stringbuffer.writeUTF8(u);
						continue;
					}
					break;
			}
			stringbuffer.writeByte(c);
		}

		assert(false);
	}

	/**************************************
	 * Lex hex strings:
	 *	x"0A ae 34FE BD"
	 */
    TOK hexStringConstant(Token* t)
	{
		uint c;
		Loc start = loc;
		uint n = 0;
		uint v;

		p++;
		stringbuffer.reset();
		while (1)
			{
			c = *p++;
			switch (c)
			{
				case ' ':
				case '\t':
				case '\v':
				case '\f':
					continue;			// skip white space

				case '\r':
					if (*p == '\n')
						continue;			// ignore
				// Treat isolated '\r' as if it were a '\n'
				case '\n':
					loc.linnum++;
					continue;

				case 0:
				case 0x1A:
					error("unterminated string constant starting at %s", start.toChars());
					t.ustring = "".ptr;
					t.len = 0;
					t.postfix = 0;
					return TOKstring;

				case '"':
					if (n & 1)
					{
						error("odd number (%d) of hex characters in hex string", n);
						stringbuffer.writeByte(v);
					}
					t.len = stringbuffer.offset;
					stringbuffer.writeByte(0);
					void* mem = GC.malloc(stringbuffer.offset);
					memcpy(mem, stringbuffer.data, stringbuffer.offset);
					t.ustring = cast(const(char)*)mem;
					stringPostfix(t);
					return TOKstring;

			default:
				if (c >= '0' && c <= '9')
					c -= '0';
				else if (c >= 'a' && c <= 'f')
					c -= 'a' - 10;
				else if (c >= 'A' && c <= 'F')
					c -= 'A' - 10;
				else if (c & 0x80)
				{   p--;
					uint u = decodeUTF();
					p++;
					if (u == PS || u == LS)
					loc.linnum++;
					else
					error("non-hex character \\u%04x", u);
				}
				else
					error("non-hex character '%c'", c);
				if (n & 1)
				{   v = (v << 4) | c;
					stringbuffer.writeByte(v);
				}
				else
					v = c;
				n++;
				break;
			}
		}
	}

version (DMDV2) {
	/**************************************
	 * Lex delimited strings:
	 *	q"(foo(xxx))"   // "foo(xxx)"
	 *	q"[foo(]"       // "foo("
	 *	q"/foo]/"       // "foo]"
	 *	q"HERE
	 *	foo
	 *	HERE"		// "foo\n"
	 * Input:
	 *	p is on the "
	 */
    TOK delimitedStringConstant(Token* t)
	{
		uint c;
		Loc start = loc;
		uint delimleft = 0;
		uint delimright = 0;
		uint nest = 1;
		uint nestcount;
		Identifier hereid = null;
		uint blankrol = 0;
		uint startline = 0;

		p++;
		stringbuffer.reset();
		while (1)
		{
			c = *p++;
			//printf("c = '%c'\n", c);
			switch (c)
			{
				case '\n':
					Lnextline:
					loc.linnum++;
					startline = 1;
					if (blankrol)
					{   blankrol = 0;
						continue;
					}
					if (hereid)
					{
						stringbuffer.writeUTF8(c);
						continue;
					}
					break;

				case '\r':
					if (*p == '\n')
						continue;	// ignore
					c = '\n';	// treat EndOfLine as \n character
					goto Lnextline;

				case 0:
				case 0x1A:
					goto Lerror;

				default:
					if (c & 0x80)
					{   p--;
						c = decodeUTF();
						p++;
						if (c == PS || c == LS)
						goto Lnextline;
					}
					break;
			}
			if (delimleft == 0)
			{
				delimleft = c;
				nest = 1;
				nestcount = 1;
				if (c == '(')
					delimright = ')';
				else if (c == '{')
					delimright = '}';
				else if (c == '[')
					delimright = ']';
				else if (c == '<')
					delimright = '>';
				else if (isalpha(c) || c == '_' || (c >= 0x80 && isUniAlpha(c)))
				{
					// Start of identifier; must be a heredoc
					Token t2;
					p--;
					scan(&t2);		// read in heredoc identifier
					if (t2.value != TOKidentifier)
					{
						error("identifier expected for heredoc, not %s", t2.toChars());
						delimright = c;
					}
					else
					{
						hereid = t2.ident;
						//printf("hereid = '%s'\n", hereid.toChars());
						blankrol = 1;
					}
					nest = 0;
				}
				else
				{
					delimright = c;
					nest = 0;
					if (isspace(c))
						error("delimiter cannot be whitespace");
				}
			}
			else
			{
				if (blankrol)
				{
					error("heredoc rest of line should be blank");
					blankrol = 0;
					continue;
				}
				if (nest == 1)
				{
					if (c == delimleft)
						nestcount++;
					else if (c == delimright)
					{   nestcount--;
						if (nestcount == 0)
						goto Ldone;
					}
				}
				else if (c == delimright)
					goto Ldone;
				if (startline && isalpha(c) && hereid)
				{
					Token t2;
					ubyte* psave = p;
					p--;
					scan(&t2);		// read in possible heredoc identifier
					//printf("endid = '%s'\n", t2.ident.toChars());
					if (t2.value == TOKidentifier && t2.ident.equals(hereid))
					{
						/* should check that rest of line is blank
						 */
						goto Ldone;
					}
					p = psave;
				}
				stringbuffer.writeUTF8(c);
				startline = 0;
			}
		}

	Ldone:
		if (*p == '"')
			p++;
		else
			error("delimited string must end in %c\"", delimright);
		t.len = stringbuffer.offset;
		stringbuffer.writeByte(0);
		void* mem = GC.malloc(stringbuffer.offset);
		memcpy(mem, stringbuffer.data, stringbuffer.offset);
		t.ustring = cast(const(char)*)mem;
		stringPostfix(t);
		return TOKstring;

	Lerror:
		error("unterminated string constant starting at %s", start.toChars());
		t.ustring = "".ptr;
		t.len = 0;
		t.postfix = 0;
		return TOKstring;
	}

	/**************************************
	 * Lex delimited strings:
	 *	q{ foo(xxx) } // " foo(xxx) "
	 *	q{foo(}       // "foo("
	 *	q{{foo}"}"}   // "{foo}"}""
	 * Input:
	 *	p is on the q
	 */
    TOK tokenStringConstant(Token* t)
	{
		uint nest = 1;
		Loc start = loc;
		ubyte* pstart = ++p;

		while (true)
		{
			Token tok;

			scan(&tok);
			switch (tok.value)
			{
				case TOKlcurly:
					nest++;
					continue;

				case TOKrcurly:
					if (--nest == 0)
						goto Ldone;
					continue;

				case TOKeof:
					goto Lerror;

				default:
					continue;
			}
		}

	Ldone:
		t.len = p - 1 - pstart;
		char* tmp = cast(char*)GC.malloc(t.len + 1);
		memcpy(tmp, pstart, t.len);
		tmp[t.len] = 0;
		t.ustring = tmp;
		stringPostfix(t);
		return TOKstring;

	Lerror:
		error("unterminated token string constant starting at %s", start.toChars());
		t.ustring = "".ptr;
		t.len = 0;
		t.postfix = 0;
		return TOKstring;
	}
}
    TOK escapeStringConstant(Token* t, int wide)
	{
		uint c;
		Loc start = loc;

		p++;
		stringbuffer.reset();
		while (true)
		{
			c = *p++;
			switch (c)
			{
		version (TEXTUAL_ASSEMBLY_OUT) {
		} else {
				case '\\':
					switch (*p)
					{
						case 'u':
						case 'U':
						case '&':
						c = escapeSequence();
						stringbuffer.writeUTF8(c);
						continue;

						default:
						c = escapeSequence();
						break;
					}
					break;
		}
				case '\n':
					loc.linnum++;
					break;

				case '\r':
					if (*p == '\n')
						continue;	// ignore
					c = '\n';	// treat EndOfLine as \n character
					loc.linnum++;
					break;

				case '"':
					t.len = stringbuffer.offset;
					stringbuffer.writeByte(0);
					char* tmp = cast(char*)GC.malloc(stringbuffer.offset);
					memcpy(tmp, stringbuffer.data, stringbuffer.offset);
					t.ustring = tmp;
					stringPostfix(t);
					return TOK.TOKstring;

				case 0:
				case 0x1A:
					p--;
					error("unterminated string constant starting at %s", start.toChars());
					t.ustring = "".ptr;
					t.len = 0;
					t.postfix = 0;
					return TOK.TOKstring;

				default:
					if (c & 0x80)
					{
						p--;
						c = decodeUTF();
						if (c == LS || c == PS)
						{	c = '\n';
						loc.linnum++;
						}
						p++;
						stringbuffer.writeUTF8(c);
						continue;
					}
					break;
			}
			stringbuffer.writeByte(c);
		}

		assert(false);
	}

    TOK charConstant(Token* t, int wide)
	{
		uint c;
		TOK tk = TOKcharv;

		//printf("Lexer.charConstant\n");
		p++;
		c = *p++;
		switch (c)
		{
		version (TEXTUAL_ASSEMBLY_OUT) {
		} else {
			case '\\':
				switch (*p)
				{
				case 'u':
					t.uns64value = escapeSequence();
					tk = TOKwcharv;
					break;

				case 'U':
				case '&':
					t.uns64value = escapeSequence();
					tk = TOKdcharv;
					break;

				default:
					t.uns64value = escapeSequence();
					break;
				}
				break;
		}
			case '\n':
			L1:
				loc.linnum++;
			case '\r':
			case 0:
			case 0x1A:
			case '\'':
				error("unterminated character constant");
				return tk;

			default:
				if (c & 0x80)
				{
					p--;
					c = decodeUTF();
					p++;
					if (c == LS || c == PS)
						goto L1;
					if (c < 0xD800 || (c >= 0xE000 && c < 0xFFFE))
						tk = TOKwcharv;
					else
						tk = TOKdcharv;
				}
				t.uns64value = c;
				break;
		}

		if (*p != '\'')
		{
			error("unterminated character constant");
			return tk;
		}
		p++;
		return tk;
	}

	/***************************************
	 * Get postfix of string literal.
	 */
    void stringPostfix(Token* t)
	{
		switch (*p)
		{
			case 'c':
			case 'w':
			case 'd':
				t.postfix = *p;
				p++;
				break;

			default:
				t.postfix = 0;
				break;
		}
	}

    uint wchar_(uint u)
	{
		assert(false);
	}

	/**************************************
	 * Read in a number.
	 * If it's an integer, store it in tok.TKutok.Vlong.
	 *	integers can be decimal, octal or hex
	 *	Handle the suffixes U, UL, LU, L, etc.
	 * If it's double, store it in tok.TKutok.Vdouble.
	 * Returns:
	 *	TKnum
	 *	TKdouble,...
	 */

    TOK number(Token* t)
	{
		// We use a state machine to collect numbers
		enum STATE { STATE_initial, STATE_0, STATE_decimal, STATE_octal, STATE_octale,
		STATE_hex, STATE_binary, STATE_hex0, STATE_binary0,
		STATE_hexh, STATE_error }
		STATE state;

		enum FLAGS
		{
			FLAGS_undefined = 0,
			FLAGS_decimal  = 1,		// decimal
			FLAGS_unsigned = 2,		// u or U suffix
			FLAGS_long     = 4,		// l or L suffix
		}

		FLAGS flags = FLAGS.FLAGS_decimal;

		int i;
		int base;
		uint c;
		ubyte *start;
		TOK result;

		//printf("Lexer.number()\n");
		state = STATE.STATE_initial;
		base = 0;
		stringbuffer.reset();
		start = p;
		while (1)
		{
		c = *p;
		switch (state)
		{
			case STATE.STATE_initial:		// opening state
			if (c == '0')
				state = STATE.STATE_0;
			else
				state = STATE.STATE_decimal;
			break;

			case STATE.STATE_0:
			flags = (flags & ~FLAGS.FLAGS_decimal);
			switch (c)
			{
version (ZEROH) {
				case 'H':			// 0h
				case 'h':
				goto hexh;
}
				case 'X':
				case 'x':
				state = STATE.STATE_hex0;
				break;

				case '.':
				if (p[1] == '.')	// .. is a separate token
					goto done;
				case 'i':
				case 'f':
				case 'F':
				goto real_;
version (ZEROH) {
				case 'E':
				case 'e':
				goto case_hex;
}
				case 'B':
				case 'b':
				state = STATE.STATE_binary0;
				break;

				case '0': case '1': case '2': case '3':
				case '4': case '5': case '6': case '7':
				state = STATE.STATE_octal;
				break;

version (ZEROH) {
				case '8': case '9': case 'A':
				case 'C': case 'D': case 'F':
				case 'a': case 'c': case 'd': case 'f':
				case_hex:
				state = STATE.STATE_hexh;
				break;
}
				case '_':
				state = STATE.STATE_octal;
				p++;
				continue;

				case 'L':
				if (p[1] == 'i')
					goto real_;
				goto done;

				default:
				goto done;
			}
			break;

			case STATE.STATE_decimal:		// reading decimal number
			if (!isdigit(c))
			{
version (ZEROH) {
				if (ishex(c)
				|| c == 'H' || c == 'h'
				   )
				goto hexh;
}
				if (c == '_')		// ignore embedded _
				{	p++;
				continue;
				}
				if (c == '.' && p[1] != '.')
				goto real_;
				else if (c == 'i' || c == 'f' || c == 'F' ||
					 c == 'e' || c == 'E')
				{
			real_:	// It's a real number. Back up and rescan as a real
				p = start;
				return inreal(t);
				}
				else if (c == 'L' && p[1] == 'i')
				goto real_;
				goto done;
			}
			break;

			case STATE.STATE_hex0:		// reading hex number
			case STATE.STATE_hex:
			if (! ishex(cast(ubyte)c))
			{
				if (c == '_')		// ignore embedded _
				{	p++;
				continue;
				}
				if (c == '.' && p[1] != '.')
				goto real_;
				if (c == 'P' || c == 'p' || c == 'i')
				goto real_;
				if (state == STATE.STATE_hex0)
				error("Hex digit expected, not '%c'", c);
				goto done;
			}
			state = STATE.STATE_hex;
			break;

version (ZEROH) {
			hexh:
			state = STATE.STATE_hexh;
			case STATE.STATE_hexh:		// parse numbers like 0FFh
			if (!ishex(c))
			{
				if (c == 'H' || c == 'h')
				{
				p++;
				base = 16;
				goto done;
				}
				else
				{
				// Check for something like 1E3 or 0E24
				if (memchr(cast(char*)stringbuffer.data, 'E', stringbuffer.offset) ||
					memchr(cast(char*)stringbuffer.data, 'e', stringbuffer.offset))
					goto real_;
				error("Hex digit expected, not '%c'", c);
				goto done;
				}
			}
			break;
}

			case STATE.STATE_octal:		// reading octal number
			case STATE.STATE_octale:		// reading octal number with non-octal digits
			if (!isoctal(cast(ubyte)c))
			{
version (ZEROH) {
				if (ishex(c)
				|| c == 'H' || c == 'h'
				   )
				goto hexh;
}
				if (c == '_')		// ignore embedded _
				{	p++;
				continue;
				}
				if (c == '.' && p[1] != '.')
				goto real_;
				if (c == 'i')
				goto real_;
				if (isdigit(c))
				{
				state = STATE.STATE_octale;
				}
				else
				goto done;
			}
			break;

			case STATE.STATE_binary0:		// starting binary number
			case STATE.STATE_binary:		// reading binary number
			if (c != '0' && c != '1')
			{
version (ZEROH) {
				if (ishex(c)
				|| c == 'H' || c == 'h'
				   )
				goto hexh;
}
				if (c == '_')		// ignore embedded _
				{	p++;
				continue;
				}
				if (state == STATE.STATE_binary0)
				{	error("binary digit expected");
				state = STATE.STATE_error;
				break;
				}
				else
				goto done;
			}
			state = STATE.STATE_binary;
			break;

			case STATE.STATE_error:		// for error recovery
			if (!isdigit(c))	// scan until non-digit
				goto done;
			break;

			default:
			assert(0);
		}
		stringbuffer.writeByte(c);
		p++;
		}
	done:
		stringbuffer.writeByte(0);		// terminate string
		if (state == STATE.STATE_octale)
		error("Octal digit expected");

		ulong n;			// unsigned >=64 bit integer type

		if (stringbuffer.offset == 2 && (state == STATE.STATE_decimal || state == STATE.STATE_0))
		n = stringbuffer.data[0] - '0';
		else
		{
		// Convert string to integer
version (__DMC__) {
		errno = 0;
		n = strtoull(cast(char*)stringbuffer.data,null,base);
		if (errno == ERANGE)
			error("integer overflow");
} else {
		// Not everybody implements strtoull()
		char* p = cast(char*)stringbuffer.data;
		int r = 10, d;

		if (*p == '0')
		{
			if (p[1] == 'x' || p[1] == 'X')
			p += 2, r = 16;
			else if (p[1] == 'b' || p[1] == 'B')
			p += 2, r = 2;
			else if (isdigit(p[1]))
			p += 1, r = 8;
		}

		n = 0;
		while (1)
		{
			if (*p >= '0' && *p <= '9')
			d = *p - '0';
			else if (*p >= 'a' && *p <= 'z')
			d = *p - 'a' + 10;
			else if (*p >= 'A' && *p <= 'Z')
			d = *p - 'A' + 10;
			else
			break;
			if (d >= r)
			break;
			ulong n2 = n * r;
			//printf("n2 / r = %llx, n = %llx\n", n2/r, n);
			if (n2 / r != n || n2 + d < n)
			{
			error ("integer overflow");
			break;
			}

			n = n2 + d;
			p++;
		}
}
		if (n.sizeof > 8 &&
			n > 0xFFFFFFFFFFFFFFFF)	// if n needs more than 64 bits
			error("integer overflow");
		}

		// Parse trailing 'u', 'U', 'l' or 'L' in any combination
		while (1)
		{   FLAGS f;

		switch (*p)
		{   case 'U':
			case 'u':
			f = FLAGS.FLAGS_unsigned;
			goto L1;

			case 'l':
			if (1 || !global.params.useDeprecated)
				error("'l' suffix is deprecated, use 'L' instead");
			case 'L':
			f = FLAGS.FLAGS_long;
			L1:
			p++;
			if (flags & f)
				error("unrecognized token");
			flags = (flags | f);
			continue;
			default:
			break;
		}
		break;
		}

		switch (flags)
		{
		case FLAGS.FLAGS_undefined:
			/* Octal or Hexadecimal constant.
			 * First that fits: int, uint, long, ulong
			 */
			if (n & 0x8000000000000000)
				result = TOK.TOKuns64v;
			else if (n & 0xFFFFFFFF00000000)
				result = TOK.TOKint64v;
			else if (n & 0x80000000)
				result = TOK.TOKuns32v;
			else
				result = TOK.TOKint32v;
			break;

		case FLAGS.FLAGS_decimal:
			/* First that fits: int, long, long long
			 */
			if (n & 0x8000000000000000)
			{	    error("signed integer overflow");
				result = TOK.TOKuns64v;
			}
			else if (n & 0xFFFFFFFF80000000)
				result = TOK.TOKint64v;
			else
				result = TOK.TOKint32v;
			break;

		case FLAGS.FLAGS_unsigned:
		case FLAGS.FLAGS_decimal | FLAGS.FLAGS_unsigned:
			/* First that fits: uint, ulong
			 */
			if (n & 0xFFFFFFFF00000000)
				result = TOK.TOKuns64v;
			else
				result = TOK.TOKuns32v;
			break;

		case FLAGS.FLAGS_decimal | FLAGS.FLAGS_long:
			if (n & 0x8000000000000000)
			{	    error("signed integer overflow");
				result = TOK.TOKuns64v;
			}
			else
				result = TOK.TOKint64v;
			break;

		case FLAGS.FLAGS_long:
			if (n & 0x8000000000000000)
				result = TOK.TOKuns64v;
			else
				result = TOK.TOKint64v;
			break;

		case FLAGS.FLAGS_unsigned | FLAGS.FLAGS_long:
		case FLAGS.FLAGS_decimal | FLAGS.FLAGS_unsigned | FLAGS.FLAGS_long:
			result = TOK.TOKuns64v;
			break;

		default:
debug {
			printf("%x\n",flags);
}
			assert(0);
		}
		t.uns64value = n;
		return result;
	}

	/**************************************
	 * Read in characters, converting them to real.
	 * Bugs:
	 *	Exponent overflow not detected.
	 *	Too much requested precision is not detected.
	 */
    TOK inreal(Token* t)
	in
	{
		assert(*p == '.' || isdigit(*p));
	}
	out (result)
	{
		switch (result)
		{
			case TOKfloat32v:
			case TOKfloat64v:
			case TOKfloat80v:
			case TOKimaginary32v:
			case TOKimaginary64v:
			case TOKimaginary80v:
				break;

			default:
				assert(0);
		}
	}
	body
	{
		int dblstate;
		uint c;
		char hex;			// is this a hexadecimal-floating-constant?
		TOK result;

		//printf("Lexer.inreal()\n");
		stringbuffer.reset();
		dblstate = 0;
		hex = 0;
	Lnext:
		while (true)
		{
			// Get next char from input
			c = *p++;
			//printf("dblstate = %d, c = '%c'\n", dblstate, c);
			while (true)
			{
				switch (dblstate)
				{
					case 0:			// opening state
						if (c == '0')
						dblstate = 9;
						else if (c == '.')
						dblstate = 3;
						else
						dblstate = 1;
						break;

					case 9:
						dblstate = 1;
						if (c == 'X' || c == 'x')
						{
							hex++;
							break;
						}
					case 1:			// digits to left of .
					case 3:			// digits to right of .
					case 7:			// continuing exponent digits
						if (!isdigit(c) && !(hex && isxdigit(c)))
						{
							if (c == '_')
								goto Lnext;	// ignore embedded '_'
							dblstate++;
							continue;
						}
						break;

					case 2:			// no more digits to left of .
						if (c == '.')
						{
							dblstate++;
							break;
						}
					case 4:			// no more digits to right of .
						if ((c == 'E' || c == 'e') ||
							hex && (c == 'P' || c == 'p'))
						{
							dblstate = 5;
							hex = 0;	// exponent is always decimal
							break;
						}
						if (hex)
							error("binary-exponent-part required");
						goto done;

					case 5:			// looking immediately to right of E
						dblstate++;
						if (c == '-' || c == '+')
							break;
					case 6:			// 1st exponent digit expected
						if (!isdigit(c))
							error("exponent expected");
						dblstate++;
						break;

					case 8:			// past end of exponent digits
						goto done;

					default:
						assert(0, "inreal.dblstate has unexpected value");
				}
				break;
			}
			stringbuffer.writeByte(c);
		}
	done:
		p--;

		stringbuffer.writeByte(0);

	version (Windows) { /// && __DMC__
		char* save = __locale_decpoint;
		__locale_decpoint = cast(char*)".".ptr;
	}
		t.float80value = strtold(cast(char*)stringbuffer.data, null);

		errno = 0;
		switch (*p)
		{
		case 'F':
		case 'f':
			strtof(cast(char*)stringbuffer.data, null);
			result = TOKfloat32v;
			p++;
			break;

		default:
			strtod(cast(char*)stringbuffer.data, null);
			result = TOKfloat64v;
			break;

		case 'l':
			if (!global.params.useDeprecated)
				error("'l' suffix is deprecated, use 'L' instead");
		case 'L':
			result = TOKfloat80v;
			p++;
			break;
		}
		if (*p == 'i' || *p == 'I')
		{
			if (!global.params.useDeprecated && *p == 'I')
				error("'I' suffix is deprecated, use 'i' instead");
			p++;
			switch (result)
			{
				case TOKfloat32v:
					result = TOKimaginary32v;
					break;
				case TOKfloat64v:
					result = TOKimaginary64v;
					break;
				case TOKfloat80v:
					result = TOKimaginary80v;
					break;
				default:
			}
		}

	version (Windows) { ///&& __DMC__
		__locale_decpoint = save;
	}
		if (errno == ERANGE)
			error("number is not representable");

		return result;
	}

	void error(T...)(string format, T t)
	{
		error(this.loc, format, t);
	}

    void error(T...)(Loc loc, string format, T t)
	{
		if (mod && !global.gag)
		{
			string p = loc.toChars();
			if (p.length != 0)
				writef("%s: ", p);

			writefln(format, t);

			if (global.errors >= 20)	// moderate blizzard of cascading messages
				fatal();
		}

		global.errors++;
	}

	/*********************************************
	 * Do pragma.
	 * Currently, the only pragma supported is:
	 *	#line linnum [filespec]
	 */
    void pragma_()
	{
		Token tok;
		int linnum;
		string filespec = null;
		Loc loc = this.loc;

		scan(&tok);
		if (tok.value != TOKidentifier || tok.ident != Id.line)
			goto Lerr;

		scan(&tok);
		if (tok.value == TOKint32v || tok.value == TOKint64v)
			linnum = cast(int)(tok.uns64value - 1); ///
		else
			goto Lerr;

		while (1)
		{
			switch (*p)
			{
				case 0:
				case 0x1A:
				case '\n':
					Lnewline:
					this.loc.linnum = linnum;
					if (filespec != null)
						this.loc.filename = filespec;
					return;

				case '\r':
					p++;
					if (*p != '\n')
					{   p--;
						goto Lnewline;
					}
					continue;

				case ' ':
				case '\t':
				case '\v':
				case '\f':
					p++;
					continue;			// skip white space

				case '_':
					if (mod && memcmp(p, "__FILE__".ptr, 8) == 0)
					{
						p += 8;
						filespec = (loc.filename ? loc.filename : mod.ident.toChars());
					}
					continue;

				case '"':
					if (filespec)
						goto Lerr;
					stringbuffer.reset();
					p++;
					while (1)
					{
						uint c;

						c = *p;
						switch (c)
						{
							case '\n':
							case '\r':
							case 0:
							case 0x1A:
								goto Lerr;

							case '"':
								stringbuffer.writeByte(0);
								filespec = stringbuffer.extractString();	///
								p++;
								break;

							default:
								if (c & 0x80)
								{
									uint u = decodeUTF();
									if (u == PS || u == LS)
										goto Lerr;
								}
								stringbuffer.writeByte(c);
								p++;
								continue;
						}
						break;
					}
					continue;

				default:
					if (*p & 0x80)
					{
						uint u = decodeUTF();
						if (u == PS || u == LS)
							goto Lnewline;
					}
					goto Lerr;
			}
		}

	Lerr:
		error(loc, "#line integer [\"filespec\"]\\n expected");
	}

	/********************************************
	 * Decode UTF character.
	 * Issue error messages for invalid sequences.
	 * Return decoded character, advance p to last character in UTF sequence.
	 */
    uint decodeUTF()
	{
		dchar u;
		ubyte c;
		ubyte* s = p;
		size_t len;
		size_t idx;
		string msg;

		c = *s;
		assert(c & 0x80);

		// Check length of remaining string up to 6 UTF-8 characters
		for (len = 1; len < 6 && s[len]; len++) {
			//;
		}

		idx = 0;
		msg = utf_decodeChar(cast(string)s[0..len], &idx, &u);
		p += idx - 1;
		if (msg)
		{
			error("%s", msg);
		}
		return u;
	}

	/***************************************************
	 * Parse doc comment embedded between t.ptr and p.
	 * Remove trailing blanks and tabs from lines.
	 * Replace all newlines with \n.
	 * Remove leading comment character from each line.
	 * Decide if it's a lineComment or a blockComment.
	 * Append to previous one for this token.
	 */
	void getDocComment(Token* t, uint lineComment)
	{
		/* ct tells us which kind of comment it is: '!', '/', '*', or '+'
		 */
		ubyte ct = t.ptr[2];

		/* Start of comment text skips over / * *, / + +, or / / /
		 */
		ubyte* q = t.ptr + 3;	  // start of comment text

		ubyte* qend = p;
		if (ct == '*' || ct == '+')
			qend -= 2;

		/* Scan over initial row of ****'s or ++++'s or ////'s
		 */
		for (; q < qend; q++)
		{
			if (*q != ct)
				break;
		}

		/* Remove trailing row of ****'s or ++++'s
		 */
		if (ct != '/' && ct != '!')
		{
			for (; q < qend; qend--)
			{
				if (qend[-1] != ct)
					break;
			}
		}

		/* Comment is now [q .. qend].
		 * Canonicalize it into buf[].
		 */
		OutBuffer buf = new OutBuffer;
		int linestart = 0;

		for (; q < qend; q++)
		{
			ubyte c = *q;

			switch (c)
			{
				case '*':
				case '+':
					if (linestart && c == ct)
					{   linestart = 0;
						/* Trim preceding whitespace up to preceding \n
						 */
						while (buf.offset && (buf.data[buf.offset - 1] == ' ' || buf.data[buf.offset - 1] == '\t'))
							buf.offset--;
						continue;
					}
					break;

				case ' ':
				case '\t':
					break;

				case '\r':
					if (q[1] == '\n')
						continue;		   // skip the \r
					goto Lnewline;

				default:
					if (c == 226)
					{
						// If LS or PS
						if (q[1] == 128 &&
							(q[2] == 168 || q[2] == 169))
						{
							q += 2;
							goto Lnewline;
						}
					}
					linestart = 0;
					break;

				Lnewline:
					c = '\n';			   // replace all newlines with \n
				case '\n':
					linestart = 1;

					/* Trim trailing whitespace
					 */
					while (buf.offset && (buf.data[buf.offset - 1] == ' ' || buf.data[buf.offset - 1] == '\t'))
						buf.offset--;

					break;
			}
			buf.writeByte(c);
		}

		// Always end with a newline
		if (!buf.offset || buf.data[buf.offset - 1] != '\n')
			buf.writeByte('\n');

		buf.writeByte(0);

		// It's a line comment if the start of the doc comment comes
		// after other non-whitespace on the same line.
		string* dc = (lineComment && anyToken)
							 ? &t.lineComment
							 : &t.blockComment;

		// Combine with previous doc comment, if any
		if (*dc)
			*dc = combineComments(*dc, cast(string) buf.data[0 .. buf.size]); // TODO: utf decode etc?
		else
		{
			auto bufsize = buf.size;
			*dc = cast(string) buf.extractData()[0..bufsize];
		}
	}

	/********************************************
	 * Combine two document comments into one,
	 * separated by a newline.
	 */
	static string combineComments(string c1, string c2)
	{
		//printf("Lexer::combineComments('%s', '%s')\n", c1, c2);

		string c = c2;

		if (c1)
		{
			c = c1;
			if (c2)
			{
				size_t len1 = c1.length;
				size_t len2 = c2.length;

				c = c1.idup;
				if (len1 && c1[$-1] != '\n')
					c ~= '\n';
				c ~= c2;
			}
		}
		return c;
	}

    static bool isValidIdentifier(string p)
	{
		if (p.length == 0) {
			return false;
		}

		if (p[0] >= '0' && p[0] <= '9') {		// beware of isdigit() on signed chars
			return false;
		}

		size_t idx = 0;
		while (idx < p.length)
		{
			dchar dc;

			if (utf_decodeChar(p, &idx, &dc) !is null) {
				return false;
			}

			if (!((dc >= 0x80 && isUniAlpha(dc)) || isalnum(dc) || dc == '_')) {
				return false;
			}
		}

		return true;
	}

	/// TODO: use normal string append when GC works
	static string combineComments(const(char)[] c1, const(char)[] c2)
	{
		//writef("Lexer.combineComments('%s', '%s')\n", c1, c2);

		char[] c = cast(char[]) c2;

		if (c1 !is null)
		{
			c = cast(char[]) c1;
			if (c2 !is null)
			{
				c = cast(char[]) (GC.malloc(c1.length + 1 + c2.length)[0 .. c1.length + 1 + c2.length]);
				size_t len1 = c1.length;
				c[0..len1] = c1[];
				c[len1++] = '\n';
				c[len1 .. len1 + c2.length] = c2[];
			}
		}

		return cast(string)c;
	}
}
