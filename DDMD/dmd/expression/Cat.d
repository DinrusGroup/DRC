module dmd.expression.Cat;

import dmd.common;
import dmd.Type;
import dmd.Expression;
import dmd.Loc;
import dmd.TOK;
import dmd.StringExp;
import dmd.ArrayLiteralExp;
import dmd.Global;
import dmd.TY;
import dmd.Type;
import dmd.GlobalExpressions;
import dmd.ArrayTypes;
import dmd.TypeSArray;
import dmd.IntegerExp;

import core.memory;

import core.stdc.string;
import core.stdc.stdlib;

import std.exception;

/* Also return EXP_CANT_INTERPRET if this fails
 */
Expression Cat(Type type, Expression e1, Expression e2)
{   
	Expression e = EXP_CANT_INTERPRET;
    Loc loc = e1.loc;
	
	Type t;

    Type t1 = e1.type.toBasetype();
    Type t2 = e2.type.toBasetype();

    //printf("Cat(e1 = %s, e2 = %s)\n", e1.toChars(), e2.toChars());
    //printf("\tt1 = %s, t2 = %s\n", t1.toChars(), t2.toChars());

    if (e1.op == TOKnull && (e2.op == TOKint64 || e2.op == TOKstructliteral))
    {	
		e = e2;
		goto L2;
    }
    else if ((e1.op == TOKint64 || e1.op == TOKstructliteral) && e2.op == TOKnull)
    {	
		e = e1;
	L2:
		Type tn = e.type.toBasetype();
		if (tn.ty == Tchar || tn.ty == Twchar || tn.ty == Tdchar)
		{
			// Create a StringExp
			size_t len = 1;
			int sz = cast(int)tn.size();
			ulong v = e.toInteger();

			char* s = cast(char*)GC.malloc((len + 1) * sz);
			memcpy(s, &v, sz);

			// Add terminating 0
			memset(s + len * sz, 0, sz);

			StringExp es = new StringExp(loc, assumeUnique(s[0..len]));
			es.sz = cast(ubyte)sz;
			es.committed = 1;
			e = es;
		}
		else
		{   
			// Create an ArrayLiteralExp
			auto elements = new Expressions();
			elements.push(e);
			e = new ArrayLiteralExp(e.loc, elements);
		}
		e.type = type;
		return e;
    }
    else if (e1.op == TOKstring && e2.op == TOKstring)
    {
		// Concatenate the strings
		auto es1 = cast(StringExp)e1;
		auto es2 = cast(StringExp)e2;
		
		size_t len = es1.len + es2.len;
		int sz = es1.sz;

		if (sz != es2.sz)
		{
			/* Can happen with:
			 *   auto s = "foo"d ~ "bar"c;
			 */
			assert(global.errors);
			return e;
		}

		char* s = cast(char*)GC.malloc((len + 1) * sz);
		memcpy(s, es1.string_, es1.len * sz);
		memcpy(s + es1.len * sz, es2.string_, es2.len * sz);

		// Add terminating 0
		memset(s + len * sz, 0, sz);

		StringExp es = new StringExp(loc, assumeUnique(s[0..len]));
		es.sz = cast(ubyte)sz;
		es.committed = es1.committed | es2.committed;
		
		Type tt;
		if (es1.committed)
			tt = es1.type;
		else
			tt = es2.type;

		es.type = type;
		e = es;
    }
    else if (e1.op == TOKstring && e2.op == TOKint64)
    {
		// Concatenate the strings
		StringExp es1 = cast(StringExp)e1;
		size_t len = es1.len + 1;
		int sz = es1.sz;
		ulong v = e2.toInteger();

		char* s = cast(char*)GC.malloc((len + 1) * sz);
		memcpy(s, es1.string_, es1.len * sz);
		memcpy(s + es1.len * sz, &v, sz);

		// Add terminating 0
		memset(s + len * sz, 0, sz);

		StringExp es = new StringExp(loc, assumeUnique(s[0..len]));
		es.sz = cast(ubyte)sz;
		es.committed = es1.committed;
		Type tt = es1.type;
		es.type = type;
		e = es;
    }
    else if (e1.op == TOKint64 && e2.op == TOKstring)
    {
		// Concatenate the strings
		StringExp es2 = cast(StringExp)e2;
		size_t len = 1 + es2.len;
		int sz = es2.sz;
		ulong v = e1.toInteger();

		char* s = cast(char*)GC.malloc((len + 1) * sz);
		memcpy(s, &v, sz);
		memcpy(s + sz, es2.string_, es2.len * sz);

		// Add terminating 0
		memset(s + len * sz, 0, sz);

		StringExp es = new StringExp(loc, assumeUnique(s[0..len]));
		es.sz = cast(ubyte)sz;
		es.committed = es2.committed;
		Type tt = es2.type;
		es.type = type;
		e = es;
    }
    else if (e1.op == TOKarrayliteral && e2.op == TOKarrayliteral &&
		t1.nextOf().equals(t2.nextOf()))
    {
		// Concatenate the arrays
		ArrayLiteralExp es1 = cast(ArrayLiteralExp)e1;
		ArrayLiteralExp es2 = cast(ArrayLiteralExp)e2;

		es1 = new ArrayLiteralExp(es1.loc, cast(Expressions)es1.elements.copy());
		es1.elements.insert(es1.elements.dim, es2.elements);
		e = es1;

		if (type.toBasetype().ty == Tsarray)
		{
			e.type = new TypeSArray(t1.nextOf(), new IntegerExp(loc, es1.elements.dim, Type.tindex));
			e.type = e.type.semantic(loc, null);
		}
		else
			e.type = type;
    }
    else if (e1.op == TOKarrayliteral && e2.op == TOKnull &&
		t1.nextOf().equals(t2.nextOf()))
    {
		e = e1;
		goto L3;
    }
    else if (e1.op == TOKnull && e2.op == TOKarrayliteral &&
		t1.nextOf().equals(t2.nextOf()))
    {
		e = e2;
	L3:
		// Concatenate the array with null
		ArrayLiteralExp es = cast(ArrayLiteralExp)e;

		es = new ArrayLiteralExp(es.loc, cast(Expressions)es.elements.copy());
		e = es;

		if (type.toBasetype().ty == Tsarray)
		{
			e.type = new TypeSArray(t1.nextOf(), new IntegerExp(loc, es.elements.dim, Type.tindex));
			e.type = e.type.semantic(loc, null);
		}
		else
			e.type = type;
    }
    else if ((e1.op == TOKarrayliteral || e1.op == TOKnull) &&
		e1.type.toBasetype().nextOf().equals(e2.type))
    {
		ArrayLiteralExp es1;
		if (e1.op == TOKarrayliteral)
		{   es1 = cast(ArrayLiteralExp)e1;
			es1 = new ArrayLiteralExp(es1.loc, cast(Expressions)es1.elements.copy());
			es1.elements.push(e2);
		}
		else
		{
			es1 = new ArrayLiteralExp(e1.loc, e2);
		}
		e = es1;

		if (type.toBasetype().ty == Tsarray)
		{
			e.type = new TypeSArray(e2.type, new IntegerExp(loc, es1.elements.dim, Type.tindex));
			e.type = e.type.semantic(loc, null);
		}
		else
			e.type = type;
    }
    else if (e2.op == TOKarrayliteral &&
		e2.type.toBasetype().nextOf().equals(e1.type))
    {
		ArrayLiteralExp es2 = cast(ArrayLiteralExp)e2;

		es2 = new ArrayLiteralExp(es2.loc, cast(Expressions)es2.elements.copy());
		es2.elements.shift(e1);
		e = es2;

		if (type.toBasetype().ty == Tsarray)
		{
			e.type = new TypeSArray(e1.type, new IntegerExp(loc, es2.elements.dim, Type.tindex));
			e.type = e.type.semantic(loc, null);
		}
		else
			e.type = type;
    }
    else if (e1.op == TOKnull && e2.op == TOKstring)
    {
		t = e1.type;
		e = e2;
		goto L1;
    }
    else if (e1.op == TOKstring && e2.op == TOKnull)
    {
		e = e1;
		t = e2.type;
	L1:
		Type tb = t.toBasetype();
		if (tb.ty == Tarray && tb.nextOf().equals(e.type))
		{   
			auto expressions = new Expressions();
			expressions.push(e);
			e = new ArrayLiteralExp(loc, expressions);
			e.type = t;
		}
		if (!e.type.equals(type))
		{   
			StringExp se = cast(StringExp)e.copy();
			e = se.castTo(null, type);
		}
    }
    return e;
}