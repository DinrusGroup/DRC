module dmd.Optimize;

import dmd.common;
import dmd.Expression;
import dmd.TOK;
import dmd.VarExp;
import dmd.VarDeclaration;
import dmd.STC;
import dmd.AssignExp;
import dmd.Type;
import dmd.WANT;
import dmd.TY;

/*************************************
 * If variable has a const initializer,
 * return that initializer.
 */

Expression expandVar(int result, VarDeclaration v)
{
    //printf("expandVar(result = %d, v = %p, %s)\n", result, v, v ? v.toChars() : "null");

    Expression e = null;
    if (!v)
    	return e;

    if (v.isConst() || v.isImmutable() || v.storage_class & STC.STCmanifest)
    {
	if (!v.type)
	{
	    //error("ICE");
	    return e;
	}

	Type tb = v.type.toBasetype();
	if (result & WANT.WANTinterpret ||
	    v.storage_class & STC.STCmanifest ||
	    (tb.ty != TY.Tsarray && tb.ty != TY.Tstruct)
	   )
	{
	    if (v.init)
	    {
		if (v.inuse)
		{   if (v.storage_class & STC.STCmanifest)
			v.error("recursive initialization of constant");
		    goto L1;
		}
		Expression ei = v.init.toExpression();
		if (!ei)
		    goto L1;
		if (ei.op == TOK.TOKconstruct || ei.op == TOK.TOKblit)
		{   AssignExp ae = cast(AssignExp)ei;
		    ei = ae.e2;
		    if (ei.isConst() != 1 && ei.op != TOK.TOKstring)
			goto L1;
		    if (ei.type != v.type)
			goto L1;
		}
		if (v.scope_)
		{
		    v.inuse++;
		    e = ei.syntaxCopy();
		    e = e.semantic(v.scope_);
		    e = e.implicitCastTo(v.scope_, v.type);
		    // enabling this line causes test22 in test suite to fail
		    //ei.type = e.type;
		    v.scope_ = null;
		    v.inuse--;
		}
		else if (!ei.type)
		{
		    goto L1;
		}
		else
		    // Should remove the copy() operation by
		    // making all mods to expressions copy-on-write
		    e = ei.copy();
	    }
	    else
	    {
static if (true) {
		goto L1;
} else {
		// BUG: what if const is initialized in constructor?
		e = v.type.defaultInit();
		e.loc = e1.loc;
}
	    }
	    if (e.type != v.type)
	    {
		e = e.castTo(null, v.type);
	    }
	    v.inuse++;
	    e = e.optimize(result);
	    v.inuse--;
	}
    }
L1:
    //if (e) printf("\te = %s, e.type = %s\n", e.toChars(), e.type.toChars());
    return e;
}