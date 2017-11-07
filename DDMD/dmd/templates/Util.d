module dmd.templates.Util;

import dmd.common;
import dmd.Dsymbol;
import dmd.Type;
import dmd.Expression;
import dmd.Loc;
import dmd.Scope;
import dmd.WANT;

version (DMDV2) {
	Object objectSyntaxCopy(Object o)
	{
		if (!o)
			return null;

		Type t = isType(o);
		if (t)
			return t.syntaxCopy();

		Expression e = isExpression(o);
		if (e)
			return e.syntaxCopy();

		return o;
	}
}

Object aliasParameterSemantic(Loc loc, Scope sc, Object o)
{
    if (o)
    {
		Expression ea = isExpression(o);
		Type ta = isType(o);
		if (ta)
		{   
			Dsymbol s = ta.toDsymbol(sc);
			if (s)
				o = s;
			else
				o = ta.semantic(loc, sc);
		}
		else if (ea)
		{
			ea = ea.semantic(sc);
			o = ea.optimize(WANTvalue | WANTinterpret);
		}
    }
    return o;
}