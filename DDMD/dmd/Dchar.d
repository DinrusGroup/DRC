module dmd.Dchar;

import dmd.common;
import core.stdc.wchar_;
import core.stdc.string;
import core.stdc.ctype;

version (M_UNICODE) {
	alias wchat dchar_t;
	
	struct Dchar
	{
		static dchar_t* inc(dchar_t* p) { return p + 1; }
		static dchar_t* dec(dchar_t* pstart, dchar_t* p) { return p - 1; }
		static int len(const(dchar_t)* p) { return wcslen(p); }
		static dchar_t get(dchar_t* p) { return *p; }
		static dchar_t getprev(dchar_t* pstart, dchar_t* p) { return p[-1]; }
		static dchar_t* put(dchar_t* p, dchar_t c) { *p = c; return p + 1; }
		static int cmp(dchar_t* s1, dchar_t* s2)
		{
version (__DMC__) {
			if (!*s1 && !*s2)	// wcscmp is broken
				return 0;
}
		return wcscmp(s1, s2);
version (disabled) {
			return (*s1 == *s2)
				? wcscmp(s1, s2)
				: (cast(int)*s1 - cast(int)*s2);
}
		}
		static int memcmp(const(dchar_t)*s1, const(dchar_t)* s2, int nchars) { return .memcmp(s1, s2, nchars * dchar_t.sizeof); }
		static int isDigit(dchar_t c) { return '0' <= c && c <= '9'; }
		static int isAlpha(dchar_t c) { return iswalpha(c); }
		static int isUpper(dchar_t c) { return iswupper(c); }
		static int isLower(dchar_t c) { return iswlower(c); }
		static int isLocaleUpper(dchar_t c) { return isUpper(c); }
		static int isLocaleLower(dchar_t c) { return isLower(c); }
		static int toLower(dchar_t c) { return isUpper(c) ? towlower(c) : c; }
		static int toLower(dchar_t* p) { return toLower(*p); }
		static int toUpper(dchar_t c) { return isLower(c) ? towupper(c) : c; }
		static dchar_t* dup(dchar_t* p) { return ._wcsdup(p); }	// BUG: out of memory?
		
		static dchar_t* dup(char* p)
		{
			assert(false);
		}
		
		static dchar_t* chr(dchar_t *p, uint c) { return wcschr(p, cast(dchar_t)c); }
		static dchar_t* rchr(dchar_t *p, uint c) { return wcsrchr(p, cast(dchar_t)c); }

		static dchar_t* memchr(dchar_t* p, int c, int count)
		{
			assert(false);
		}
		
		static dchar_t* cpy(dchar_t* s1, dchar_t* s2) { return wcscpy(s1, s2); }
		static dchar_t* str(dchar_t* s1, dchar_t* s2) { return wcsstr(s1, s2); }
		
		static hash_t calcHash(const(dchar_t)* str, size_t len)
		{
			assert(false);
		}

		// Case insensitive versions
		static int icmp(dchar_t* s1, dchar_t* s2) { return wcsicmp(s1, s2); }
		static int memicmp(const(dchar_t)* s1, const(dchar_t)* s2, int nchars) { return .wcsnicmp(s1, s2, nchars); }
		
		static hash_t icalcHash(const(dchar_t)* str, size_t len)
		{
			assert(false);
		}
	}
} else version (UTF8) {
	alias char dchar_t;
	
	struct Dchar
	{
		static char[256] mblen;

		static dchar_t* inc(dchar_t* p) { return p + mblen[*p & 0xFF]; }

		static dchar_t* dec(dchar_t* pstart, dchar_t* p)
		{
			assert(false);
		}

		static int len(const(dchar_t)* p) { return strlen(p); }

		static int get(dchar_t* p)
		{
			assert(false);
		}

		static int getprev(dchar_t* pstart, dchar_t* p)
		{
			return *dec(pstart, p) & 0xFF;
		}

		static dchar_t* put(dchar_t* p, uint c)
		{
			assert(false);
		}

		static int cmp(dchar_t* s1, dchar_t* s2) { return strcmp(s1, s2); }

		static int memcmp(const(dchar_t)* s1, const(dchar_t)* s2, int nchars) { return .memcmp(s1, s2, nchars); }

		static int isDigit(dchar_t c) { return '0' <= c && c <= '9'; }

		static int isAlpha(dchar_t c) { return c <= 0x7F ? isalpha(c) : 0; }

		static int isUpper(dchar_t c) { return c <= 0x7F ? isupper(c) : 0; }

		static int isLower(dchar_t c) { return c <= 0x7F ? islower(c) : 0; }

		static int isLocaleUpper(dchar_t c) { return isUpper(c); }

		static int isLocaleLower(dchar_t c) { return isLower(c); }

		static int toLower(dchar_t c) { return isUpper(c) ? tolower(c) : c; }

		static int toLower(dchar_t* p) { return toLower(*p); }

		static int toUpper(dchar_t c) { return isLower(c) ? toupper(c) : c; }

		static dchar_t* dup(dchar_t* p) { return .strdup(p); }	// BUG: out of memory?

		static dchar_t* chr(dchar_t* p, int c) { return strchr(p, c); }

		static dchar_t* rchr(dchar_t* p, int c) { return strrchr(p, c); }

		static dchar_t* memchr(dchar_t* p, int c, int count)
		{
			return cast(dchar_t*).memchr(p, c, count);
		}
		
		static dchar_t* cpy(dchar_t* s1, dchar_t* s2) { return strcpy(s1, s2); }
		
		static dchar_t* str(dchar_t* s1, dchar_t* s2) { return strstr(s1, s2); }
		
		static hash_t calcHash(const(dchar_t)* str, size_t len)
		{
			assert(false);
		}

		// Case insensitive versions
		static int icmp(dchar_t* s1, dchar_t* s2) { return _mbsicmp(s1, s2); }
		
		static int memicmp(const(dchar_t)* s1, const(dchar_t)* s2, int nchars) { return ._mbsnicmp(s1, s2, nchars); }
	}
} else {
	alias char dchar_t;
	
	struct Dchar
	{
		static dchar_t* inc(dchar_t* p) { return p + 1; }
		
		static dchar_t* dec(dchar_t* pstart, dchar_t* p) { return p - 1; }
		
		static int len(const(dchar_t)* p) { return strlen(p); }
		
		static int get(dchar_t* p) { return *p & 0xFF; }
		
		static int getprev(dchar_t* pstart, dchar_t* p) { return p[-1] & 0xFF; }
		
		static dchar_t* put(dchar_t* p, uint c) { *p = cast(dchar_t)c; return p + 1; }
		
		static int cmp(dchar_t* s1, dchar_t* s2) { return strcmp(s1, s2); }
		
		static int memcmp(const(dchar_t)* s1, const(dchar_t)* s2, int nchars) { return .memcmp(s1, s2, nchars); }
		
		static int isDigit(dchar_t c) { return '0' <= c && c <= '9'; }
	
version (GCC_SAFE_DMD) {
} else {
		static int isAlpha(dchar_t c) { return isalpha(c); }
		
		static int isUpper(dchar_t c) { return isupper(c); }
		
		static int isLower(dchar_t c) { return islower(c); }
		
		static int isLocaleUpper(dchar_t c) { return isupper(c); }
		
		static int isLocaleLower(dchar_t c) { return islower(c); }
		
		static int toLower(dchar_t c) { return isupper(c) ? tolower(c) : c; }
		
		static int toLower(dchar_t* p) { return toLower(*p); }
		
		static int toUpper(dchar_t c) { return islower(c) ? toupper(c) : c; }
		
		static dchar_t* dup(dchar_t* p) { /*return .strdup(p);*/ assert(false); }	// BUG: out of memory?
}
		static dchar_t* chr(dchar_t *p, int c) { return strchr(p, c); }
		
		static dchar_t* rchr(dchar_t *p, int c) { return strrchr(p, c); }
		
		static dchar_t* memchr(dchar_t *p, int c, int count)
		{
			return cast(dchar_t*).memchr(p, c, count);
		}
		
		static dchar_t* cpy(dchar_t* s1, dchar_t* s2) { return strcpy(s1, s2); }
		
		static dchar_t* str(dchar_t* s1, dchar_t* s2) { return strstr(s1, s2); }
		
		static hash_t calcHash(const(dchar_t)* str, size_t len)
		{
			hash_t hash = 0;

			while (1)
			{
				switch (len)
				{
					case 0:
						return hash;

					case 1:
						hash *= 37;
						hash += *cast(const(uint8_t)*)str;
						return hash;

					case 2:
						hash *= 37;
version (__I86__) {
					hash += *cast(const(uint16_t)*)str;
} else {
					hash += str[0] * 256 + str[1];
}
					return hash;

					case 3:
					hash *= 37;
version (__I86__) {
					hash += (*cast(const(uint16_t)*)str << 8) +
						(cast(const(uint8_t)*)str)[2];
} else {
					hash += (str[0] * 256 + str[1]) * 256 + str[2];
}
					return hash;

					default:
					hash *= 37;
version (__I86__) {
					hash += *cast(const(uint32_t)*)str;
} else {
					hash += ((str[0] * 256 + str[1]) * 256 + str[2]) * 256 + str[3];
}
					str += 4;
					len -= 4;
					break;
				}
			}
			
			assert(false);
		}

		// Case insensitive versions
version (__GNUC__) {
		static int icmp(dchar_t* s1, dchar_t* s2) { return strcasecmp(s1, s2); }
} else {
		static int icmp(dchar_t* s1, dchar_t* s2) { /*return stricmp(s1, s2);*/ assert(false); }
}
		static int memicmp(const(dchar_t)* s1, const(dchar_t)* s2, int nchars) { /*return .memicmp(s1, s2, nchars);*/ assert(false); }
		static hash_t icalcHash(const(dchar_t)* str, size_t len)
		{
			assert(false);
		}
	}
}

