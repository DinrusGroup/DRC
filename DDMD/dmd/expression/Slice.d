module dmd.expression.Slice;

import dmd.common;
import dmd.Expression;
import dmd.Type;
import dmd.Loc;
import dmd.TOK;
import dmd.StringExp;
import dmd.GlobalExpressions;
import dmd.ArrayLiteralExp;
import dmd.ArrayTypes;
import dmd.Util : printf;

import core.memory;

import core.stdc.stdlib;
import core.stdc.string;

import std.exception;


/* Also return EXP_CANT_INTERPRET if this fails
 */
Expression Slice(Type type, Expression e1, Expression lwr, Expression upr)
{   
	Expression e = EXP_CANT_INTERPRET;
    Loc loc = e1.loc;

version (LOG) {
    printf("Slice()\n");
    if (lwr)
    {	
		printf("\te1 = %s\n", e1.toChars());
		printf("\tlwr = %s\n", lwr.toChars());
		printf("\tupr = %s\n", upr.toChars());
    }
}
    if (e1.op == TOKstring && lwr.op == TOKint64 && upr.op == TOKint64)
    {	
		auto es1 = cast(StringExp)e1;
		ulong ilwr = lwr.toInteger();
		ulong iupr = upr.toInteger();

		if (iupr > es1.len || ilwr > iupr)
			e1.error("string slice [%ju .. %ju] is out of bounds", ilwr, iupr);
		else
		{   
			size_t len = cast(size_t)(iupr - ilwr);
			int sz = es1.sz;

			char* s = cast(char*)GC.malloc((len + 1) * sz);
			memcpy(s, cast(ubyte*)es1.string_ + ilwr * sz, len * sz);
			memset(s + len * sz, 0, sz);

			auto es = new StringExp(loc, assumeUnique(s[0..len]), es1.postfix);
			es.sz = cast(ubyte)sz;
			es.committed = 1;
			es.type = type;
			e = es;
		}
    }
    else if (e1.op == TOKarrayliteral &&
	    lwr.op == TOKint64 && upr.op == TOKint64 &&
	    !e1.checkSideEffect(2))
    {	
		auto es1 = cast(ArrayLiteralExp)e1;
		ulong ilwr = lwr.toInteger();
		ulong iupr = upr.toInteger();

		if (iupr > es1.elements.dim || ilwr > iupr)
			e1.error("array slice [%ju .. %ju] is out of bounds", ilwr, iupr);
		else
		{
			auto elements = new Expressions();
			elements.setDim(cast(uint)(iupr - ilwr));
			memcpy(elements.ptr,
			   es1.elements.ptr + ilwr,
			   cast(uint)(iupr - ilwr) * (*es1.elements.ptr).sizeof);
			e = new ArrayLiteralExp(e1.loc, elements);
			e.type = type;
		}
    }
    return e;
}
