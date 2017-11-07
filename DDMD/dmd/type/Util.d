module dmd.type.Util;

import dmd.common;
import dmd.TY;
import dmd.Expression;
import dmd.Scope;
import dmd.Type;
import dmd.TupleDeclaration;
import dmd.TypeTuple;
import dmd.ScopeDsymbol;
import dmd.ArrayScopeSymbol;

/**************************
 * This evaluates exp while setting length to be the number
 * of elements in the tuple t.
 */
Expression semanticLength(Scope sc, Type t, Expression exp)
{
    if (t.ty == TY.Ttuple)
    {
		ScopeDsymbol sym = new ArrayScopeSymbol(sc, cast(TypeTuple)t);
		sym.parent = sc.scopesym;
		sc = sc.push(sym);

		exp = exp.semantic(sc);

		sc.pop();
    }
    else
		exp = exp.semantic(sc);

    return exp;
}

//! ditto
Expression semanticLength(Scope sc, TupleDeclaration s, Expression exp)
{
	assert(false);
	
    ScopeDsymbol sym = new ArrayScopeSymbol(sc, s);
    sym.parent = sc.scopesym;
    sc = sc.push(sym);

    exp = exp.semantic(sc);

    sc.pop();
    return exp;
}