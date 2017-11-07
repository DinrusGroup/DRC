module dmd.StringExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.InterState;
import dmd.TypeSArray;
import dmd.CastExp;
import dmd.MATCH;
import dmd.TY;
import dmd.TypeDArray;
import dmd.Type;
import dmd.TOK;
import dmd.Module;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.StringExp;
import dmd.Global;
import dmd.HdrGenState;
import dmd.Utf;
import dmd.Util;
import dmd.WANT;
import dmd.backend.dt_t;
import dmd.backend.Symbol;
import dmd.backend.StringTab;
import dmd.backend.Util;
import dmd.backend.SC;
import dmd.backend.TYM;
import dmd.backend.FL;
import dmd.backend.TYPE;
import dmd.backend.OPER;

import dmd.Dsymbol : isExpression;

import core.memory;

import core.stdc.string;
import core.stdc.stdlib;
import core.stdc.ctype;

import dmd.DDMDExtensions;

class StringExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	void* string_;	// char, wchar, or dchar data
    size_t len;		// number of chars, wchars, or dchars
    ubyte sz;	// 1: char, 2: wchar, 4: dchar
    ubyte committed;	// !=0 if type is committed
    ubyte postfix;	// 'c', 'w', 'd'

	this(Loc loc, string s)
	{
		register();
		this(loc, s, 0);
	}

	this(Loc loc, string s, ubyte postfix)
	{
		register();
		super(loc, TOK.TOKstring, StringExp.sizeof);
		
		this.string_ = cast(void*)s.ptr;
		this.len = s.length;
		this.sz = 1;
		this.committed = 0;
		this.postfix = postfix;
	}

	override bool equals(Object o)
	{
		Expression e;
		//printf("StringExp.equals('%s')\n", o.toChars());
		if (o && ((e = isExpression(o)) !is null))
		{
			if (e.op == TOKstring)
			{
				return opCmp(o) == 0;
			}
		}
		
		return false;
	}

	override string toChars()
	{
		scope OutBuffer buf = new OutBuffer();
		HdrGenState hgs;
		char *p;

		memset(&hgs, 0, hgs.sizeof);
		toCBuffer(buf, &hgs);
		buf.writeByte(0);
		return buf.extractString();
	}

	override Expression semantic(Scope sc)
	{
version (LOGSEMANTIC) {
		printf("StringExp.semantic() %s\n", toChars());
}
		if (!type)
		{	
			scope OutBuffer buffer = new OutBuffer();
			size_t newlen = 0;
			string p;
			size_t u;
			dchar c;

			switch (postfix)
			{
				case 'd':
					for (u = 0; u < len;)
					{
						p = utf_decodeChar((cast(char*)string_)[0..len], &u, &c);
						if (p !is null)
						{	
							error("%s", p);
							break;
						}
						else
						{	
							buffer.write4(c);
							newlen++;
						}
					}
					buffer.write4(0);
					string_ = buffer.extractData();
					len = newlen;
					sz = 4;
					//type = new TypeSArray(Type.tdchar, new IntegerExp(loc, len, Type.tindex));
					type = new TypeDArray(Type.tdchar.invariantOf());
					committed = 1;
					break;

				case 'w':
					for (u = 0; u < len;)
					{
						p = utf_decodeChar((cast(char*)string_)[0..len], &u, &c);
						if (p !is null)
						{	
							error("%s", p);
							break;
						}
						else
						{	
							buffer.writeUTF16(c);
							newlen++;
							if (c >= 0x10000)
								newlen++;
						}
					}
					buffer.writeUTF16(0);
					string_ = buffer.extractData();
					len = newlen;
					sz = 2;
					//type = new TypeSArray(Type.twchar, new IntegerExp(loc, len, Type.tindex));
					type = new TypeDArray(Type.twchar.invariantOf());
					committed = 1;
					break;

				case 'c':
					committed = 1;
				default:
					//type = new TypeSArray(Type.tchar, new IntegerExp(loc, len, Type.tindex));
					type = new TypeDArray(Type.tchar.invariantOf());
					break;
			}
			type = type.semantic(loc, sc);
			//type = type.invariantOf();
			//printf("type = %s\n", type.toChars());
		}
		return this;
	}

	override Expression interpret(InterState istate)
	{
version (LOG) {
		printf("StringExp.interpret() %.*s\n", toChars());
}
		return this;
	}

	/**********************************
	 * Return length of string.
	 */
	size_t length()
	{
		size_t result = 0;
		dchar c;
		string p;

		switch (sz)
		{
		case 1:
			for (size_t u = 0; u < len;)
			{
				p = utf_decodeChar((cast(char*)string_)[0..len], &u, &c);
				if (p)
				{   
					error("%s", p);
					break;
				}
				else
					result++;
			}
			break;

		case 2:
			for (size_t u = 0; u < len;)
			{
				p = utf_decodeWchar((cast(wchar*)string_)[0..len], &u, &c);
				if (p)
				{   error("%s", p);
					break;
				}
				else
					result++;
			}
			break;

		case 4:
			result = len;
			break;

		default:
			assert(0);
		}
		return result;
	}

	/****************************************
	 * Convert string to char[].
	 */
	StringExp toUTF8(Scope sc)
	{
		if (sz != 1)
		{	
			// Convert to UTF-8 string
			committed = 0;
			Expression e = castTo(sc, Type.tchar.arrayOf());
			e = e.optimize(WANTvalue);
			assert(e.op == TOKstring);
			StringExp se = cast(StringExp)e;
			assert(se.sz == 1);
			return se;
		}
		return this;
	}

	override Expression implicitCastTo(Scope sc, Type t)
	{
		//printf("StringExp.implicitCastTo(%s of type %s) => %s\n", toChars(), type.toChars(), t.toChars());
		ubyte committed = this.committed;
		Expression e = Expression.implicitCastTo(sc, t);
		if (e.op == TOK.TOKstring)
		{
			// Retain polysemous nature if it started out that way
			(cast(StringExp)e).committed = committed;
		}
		return e;
	}

	override MATCH implicitConvTo(Type t)
	{
		MATCH m;

static if (false) {
		printf("StringExp.implicitConvTo(this=%s, committed=%d, type=%s, t=%s)\n",
			toChars(), committed, type.toChars(), t.toChars());
}
		if (!committed)
		{
			if (!committed && t.ty == TY.Tpointer && t.nextOf().ty == TY.Tvoid)
			{
				return MATCH.MATCHnomatch;
			}
			if (type.ty == TY.Tsarray || type.ty == TY.Tarray || type.ty == TY.Tpointer)
			{
				TY tyn = type.nextOf().ty;
				if (tyn == TY.Tchar || tyn == TY.Twchar || tyn == TY.Tdchar)
				{   
					Type tn;
					MATCH mm;

					switch (t.ty)
					{
						case TY.Tsarray:
							if (type.ty == TY.Tsarray)
							{
								if ((cast(TypeSArray)type).dim.toInteger() !=
									(cast(TypeSArray)t).dim.toInteger())
									return MATCH.MATCHnomatch;
								TY tynto = t.nextOf().ty;
								if (tynto == TY.Tchar || tynto == TY.Twchar || tynto == TY.Tdchar)
									return MATCH.MATCHexact;
							}
							else if (type.ty == TY.Tarray)
							{
								if (length() > (cast(TypeSArray)t).dim.toInteger())
									return MATCH.MATCHnomatch;
								TY tynto = t.nextOf().ty;
								if (tynto == TY.Tchar || tynto == TY.Twchar || tynto == TY.Tdchar)
									return MATCH.MATCHexact;
							}
						case TY.Tarray:
						case TY.Tpointer:
							tn = t.nextOf();
							mm = MATCH.MATCHexact;
							if (type.nextOf().mod != tn.mod)
							{	
								if (!tn.isConst())
									return MATCH.MATCHnomatch;
								mm = MATCH.MATCHconst;
							}
							switch (tn.ty)
							{
								case TY.Tchar:
								case TY.Twchar:
								case TY.Tdchar:
									return mm;
								default:
							}
							break;
						default:
							break;	///
					}
				}
			}
		}
		return Expression.implicitConvTo(t);
static if (false) {
		m = cast(MATCH)type.implicitConvTo(t);
		if (m)
		{
			return m;
		}

		return MATCH.MATCHnomatch;
}
	}
	
	static uint X(TY tf, TY tt) {
		return ((tf) * 256 + (tt));
	}

	override Expression castTo(Scope sc, Type t)
	{
		/* This follows copy-on-write; any changes to 'this'
		 * will result in a copy.
		 * The this.string member is considered immutable.
		 */
		int copied = 0;

		//printf("StringExp.castTo(t = %s), '%s' committed = %d\n", t.toChars(), toChars(), committed);

		if (!committed && t.ty == TY.Tpointer && t.nextOf().ty == TY.Tvoid)
		{
			error("cannot convert string literal to void*");
		}

		StringExp se = this;
		if (!committed)
		{   
			se = cast(StringExp)copy();
			se.committed = 1;
			copied = 1;
		}

		if (type == t)
		{
			return se;
		}

		Type tb = t.toBasetype();
		//printf("\ttype = %s\n", type.toChars());
		if (tb.ty == TY.Tdelegate && type.toBasetype().ty != TY.Tdelegate)
			return Expression.castTo(sc, t);

		Type typeb = type.toBasetype();
		if (typeb == tb)
		{
			if (!copied)
			{   
				se = cast(StringExp)copy();
				copied = 1;
			}
			se.type = t;
			return se;
		}

		if (committed && tb.ty == TY.Tsarray && typeb.ty == TY.Tarray)
		{
			se = cast(StringExp)copy();
			se.sz = cast(ubyte)tb.nextOf().size();
			se.len = (len * sz) / se.sz;
			se.committed = 1;
			se.type = t;
			return se;
		}

		if (tb.ty != TY.Tsarray && tb.ty != TY.Tarray && tb.ty != TY.Tpointer)
		{
			if (!copied)
			{   
				se = cast(StringExp)copy();
				copied = 1;
			}
			goto Lcast;
		}
		if (typeb.ty != TY.Tsarray && typeb.ty != TY.Tarray && typeb.ty != TY.Tpointer)
		{	
			if (!copied)
			{   
				se = cast(StringExp)copy();
				copied = 1;
			}
			goto Lcast;
		}

		if (typeb.nextOf().size() == tb.nextOf().size())
		{
			if (!copied)
			{
				se = cast(StringExp)copy();
				copied = 1;
			}
			
			if (tb.ty == TY.Tsarray)
				goto L2;	// handle possible change in static array dimension
			se.type = t;
			return se;
		}

		if (committed)
			goto Lcast;

		{
			scope OutBuffer buffer = new OutBuffer();
			size_t newlen = 0;
			TY tfty = typeb.nextOf().toBasetype().ty;
			TY ttty = tb.nextOf().toBasetype().ty;
			switch (X(tfty, ttty))
			{
				case X(TY.Tchar, TY.Tchar):
				case X(TY.Twchar,TY.Twchar):
				case X(TY.Tdchar,TY.Tdchar):
					break;

				case X(TY.Tchar, TY.Twchar):
					for (size_t u = 0; u < len;)
					{	
						dchar c;
						string p = utf_decodeChar((cast(char*)se.string_)[0..len], &u, &c);
						if (p !is null)
							error("%s", p);
						else
							buffer.writeUTF16(c);
					}
					newlen = buffer.offset / 2;
					buffer.writeUTF16(0);
					goto L1;

				case X(TY.Tchar, TY.Tdchar):
					for (size_t u = 0; u < len;)
					{	
						dchar c;
						string p = utf_decodeChar((cast(char*)se.string_)[0..len], &u, &c);
						if (p !is null)
							error("%s", p);
						buffer.write4(c);
						newlen++;
					}
					buffer.write4(0);
					goto L1;

				case X(TY.Twchar,TY.Tchar):
					for (size_t u = 0; u < len;)
					{	
						dchar c;
						string p = utf_decodeWchar((cast(wchar*)se.string_)[0..len], &u, &c);
						if (p)
							error("%s", p);
						else
							buffer.writeUTF8(c);
					}
					newlen = buffer.offset;
					buffer.writeUTF8(0);
					goto L1;

				case X(TY.Twchar,TY.Tdchar):
					for (size_t u = 0; u < len;)
					{	
						dchar c;
						string p = utf_decodeWchar((cast(wchar*)se.string_)[0..len], &u, &c);
						if (p)
							error("%s", p);
						buffer.write4(c);
						newlen++;
					}
					buffer.write4(0);
					goto L1;

				case X(TY.Tdchar,TY.Tchar):
					for (size_t u = 0; u < len; u++)
					{
						dchar c = (cast(dchar*)se.string_)[u];
						if (!utf_isValidDchar(c))
							error("invalid UCS-32 char \\U%08x", c);
						else
							buffer.writeUTF8(c);
						newlen++;
					}
					newlen = buffer.offset;
					buffer.writeUTF8(0);
					goto L1;

				case X(TY.Tdchar,TY.Twchar):
					for (size_t u = 0; u < len; u++)
					{
						dchar c = (cast(dchar*)se.string_)[u];
						if (!utf_isValidDchar(c))
							error("invalid UCS-32 char \\U%08x", c);
						else
							buffer.writeUTF16(c);
						newlen++;
					}
					newlen = buffer.offset / 2;
					buffer.writeUTF16(0);
					goto L1;

				L1:
					if (!copied)
					{   
						se = cast(StringExp)copy();
						copied = 1;
					}
					se.string_ = buffer.extractData();
					se.len = newlen;
					se.sz = cast(ubyte)tb.nextOf().size();
					break;

				default:
					assert(typeb.nextOf().size() != tb.nextOf().size());
					goto Lcast;
			}
		}
	L2:
		assert(copied);

		// See if need to truncate or extend the literal
		if (tb.ty == TY.Tsarray)
		{
			int dim2 = cast(int)(cast(TypeSArray)tb).dim.toInteger();

			//printf("dim from = %d, to = %d\n", se.len, dim2);

			// Changing dimensions
			if (dim2 != se.len)
			{
				// Copy when changing the string literal
				uint newsz = se.sz;
				void *s;
				int d;

				d = (dim2 < se.len) ? dim2 : se.len;
				s = cast(ubyte*)GC.malloc((dim2 + 1) * newsz);
				memcpy(s, se.string_, d * newsz);
				// Extend with 0, add terminating 0
				memset(cast(char*)s + d * newsz, 0, (dim2 + 1 - d) * newsz);
				se.string_ = s;
				se.len = dim2;
			}
		}
		se.type = t;
		return se;

	Lcast:
		Expression e = new CastExp(loc, se, t);
		e.type = t;	// so semantic() won't be run on e
		return e;
	}

	override int opCmp(Object obj)
	{
		// Used to sort case statement expressions so we can do an efficient lookup
		StringExp se2 = cast(StringExp)(obj);

		// This is a kludge so isExpression() in template.c will return 5
		// for StringExp's.
		/// ??????????????????
		if (!se2)
			return 5;

		assert(se2.op == TOKstring);

		int len1 = len;
		int len2 = se2.len;

		if (len1 == len2)
		{
			switch (sz)
			{
				case 1:
					return strcmp(cast(char*)string_, cast(char*)se2.string_);

				case 2:
				{	
					wchar* s1 = cast(wchar*)string_;
					wchar* s2 = cast(wchar*)se2.string_;

					for (uint u = 0; u < len; u++)
					{
						if (s1[u] != s2[u]) {
							return s1[u] - s2[u];
						}
					}
				}

				case 4:
				{	
					dchar* s1 = cast(dchar *)string_;
					dchar* s2 = cast(dchar *)se2.string_;

					for (uint u = 0; u < len; u++)
					{
						if (s1[u] != s2[u]) {
							return s1[u] - s2[u];
						}
					}
				}
				break;

				default:
					assert(0);
			}
		}
		
		return len1 - len2;
	}

	override bool isBool(bool result)
	{
		return result ? true : false;
	}

version(DMDV2)
{
	override bool isLvalue()
	{
		return true;
	}
}

	override Expression toLvalue(Scope sc, Expression e)
	{
		// writef("StringExp::toLvalue(%s)\n", toChars());
		return this;
	}

	uint charAt(size_t i)
	{
		uint value;

		switch (sz)
		{
			case 1:
				value = (cast(ubyte *)string_)[i];
				break;

			case 2:
				value = (cast(ushort *)string_)[i];
				break;

			case 4:
				value = (cast(uint *)string_)[i];
				break;

			default:
				assert(0);
				break;
		}
		return value;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writeByte('"');
		for (size_t i = 0; i < len; i++)
		{
			uint c = charAt(i);

			switch (c)
			{
				case '"':
				case '\\':
				if (!hgs.console)
					buf.writeByte('\\');
				default:
				if (c <= 0xFF)
				{  
					if (c <= 0x7F && (isprint(c) || hgs.console))
						buf.writeByte(c);
					else
						buf.printf("\\x%02x", c);
				}
				else if (c <= 0xFFFF)
					buf.printf("\\x%02x\\x%02x", c & 0xFF, c >> 8);
				else
					buf.printf("\\x%02x\\x%02x\\x%02x\\x%02x", c & 0xFF, (c >> 8) & 0xFF, (c >> 16) & 0xFF, c >> 24);
				break;
			}
		}
		buf.writeByte('"');
		if (postfix)
			buf.writeByte(postfix);
	}

	override void toMangleBuffer(OutBuffer buf)
	{
	    char m;
	    OutBuffer tmp = new OutBuffer();
	    string p;
	    dchar c;
	    size_t u;
	    ubyte *q;
	    uint qlen;

	    /* Write string in UTF-8 format
	     */
	    switch (sz)
	    {	case 1:
		    m = 'a';
		    q = cast(ubyte *)string_;
		    qlen = len;
		    break;
		case 2:
		    m = 'w';
		    for (u = 0; u < len; )
		    {
			p = utf_decodeWchar((cast(wchar*)string_)[0..len], &u, &c);
			if (p)
			    error("%s", p);
			else
			    tmp.writeUTF8(c);
		    }
		    q = tmp.data;
		    qlen = tmp.offset;
		    break;
		case 4:
		    m = 'd';
		    for (u = 0; u < len; u++)
		    {
			c = (cast(uint*)string_)[u];
			if (!utf_isValidDchar(c))
			    error("invalid UCS-32 char \\U%08x", c);
			else
			    tmp.writeUTF8(c);
		    }
		    q = tmp.data;
		    qlen = tmp.offset;
		    break;
		default:
		    assert(0);
	    }
	    buf.writeByte(m);
	    buf.printf("%d_", qlen);
	    for (size_t i = 0; i < qlen; i++)
		buf.printf("%02x", q[i]);
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;
		Type tb = type.toBasetype();

static if (false) {
		printf("StringExp.toElem() %s, type = %s\n", toChars(), type.toChars());
}

		if (tb.ty == TY.Tarray)
		{
			Symbol* si;
			dt_t* dt;
			StringTab* st;

static if (false) {
			printf("irs.m = %p\n", irs.m);
			printf(" m   = %s\n", irs.m.toChars());
			printf(" len = %d\n", len);
			printf(" sz  = %d\n", sz);
}
			for (size_t i = 0; i < STSIZE; i++)
			{
				st = &global.stringTab[(global.stidx + i) % STSIZE];
				//if (!st.m) continue;
				//printf(" st.m   = %s\n", st.m.toChars());
				//printf(" st.len = %d\n", st.len);
				//printf(" st.sz  = %d\n", st.sz);
				if (st.m is irs.m &&
					st.si &&
					st.len == len &&
					st.sz == sz &&
					memcmp(st.string_, string_, sz * len) == 0)
				{
					//printf("use cached value\n");
					si = st.si;	// use cached value
					goto L1;
				}
			}

			global.stidx = (global.stidx + 1) % STSIZE;
			st = &global.stringTab[global.stidx];

			dt = null;
			toDt(&dt);

			si = symbol_generate(SC.SCstatic, type_fake(TYM.TYdarray));
			si.Sdt = dt;
			si.Sfl = FL.FLdata;
version (ELFOBJ) {// Burton
			si.Sseg = Segment.CDATA;
}
version (MACHOBJ) {
			si.Sseg = Segment.DATA;
}
			outdata(si);

			st.m = irs.m;
			st.si = si;
			st.string_ = string_;
			st.len = len;
			st.sz = sz;
			L1:
			e = el_var(si);
		}
		else if (tb.ty == TY.Tsarray)
		{
			dt_t *dt = null;

			toDt(&dt);
			dtnzeros(&dt, sz);		// leave terminating 0

			Symbol* si = symbol_generate(SC.SCstatic,type_allocn(TYM.TYarray, tschar));
			si.Sdt = dt;
			si.Sfl = FL.FLdata;

version (ELFOBJ_OR_MACHOBJ) { // Burton
			si.Sseg = Segment.CDATA;
		}
			outdata(si);

			e = el_var(si);
			e.Enumbytes = len * sz;
		}
		else if (tb.ty == TY.Tpointer)
		{
			e = el_calloc();
			e.Eoper = OPER.OPstring;
static if (true) {
			// Match MEM_PH_FREE for OPstring in ztc\el.c
			e.EV.ss.Vstring = cast(char*)malloc((len + 1) * sz);
			memcpy(e.EV.ss.Vstring, string_, (len + 1) * sz);
} else {
			e.EV.ss.Vstring = cast(char*)string_;
}
			e.EV.ss.Vstrlen = (len + 1) * sz;
			e.Ety = TYM.TYnptr;
		}
		else
		{
			writef("type is %s\n", type.toChars());
			assert(0);
		}
		el_setLoc(e,loc);
		return e;
	}

	override dt_t** toDt(dt_t** pdt)
	{
		//printf("StringExp.toDt() '%s', type = %s\n", toChars(), type.toChars());
		Type t = type.toBasetype();

		// BUG: should implement some form of static string pooling
		switch (t.ty)
		{
			case TY.Tarray:
				dtdword(pdt, len);
				pdt = dtabytes(pdt, TYM.TYnptr, 0, (len + 1) * sz, cast(char*)string_);
				break;

			case TY.Tsarray:
			{   
				TypeSArray tsa = cast(TypeSArray)type;
				long dim;

				pdt = dtnbytes(pdt, len * sz, cast(const(char)*)string_);
				if (tsa.dim)
				{
					dim = tsa.dim.toInteger();
					if (len < dim)
					{
						// Pad remainder with 0
						pdt = dtnzeros(pdt, cast(uint)((dim - len) * tsa.next.size()));
					}
				}
				break;
			}

			case TY.Tpointer:
				pdt = dtabytes(pdt, TYM.TYnptr, 0, (len + 1) * sz, cast(char*)string_);
				break;

			default:
				writef("StringExp.toDt(type = %s)\n", type.toChars());
				assert(0);
		}

		return pdt;
	}
}

