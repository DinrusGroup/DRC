module dmd.InlineDoState;

import dmd.common;
import dmd.Array;
import dmd.Dsymbol;
import dmd.VarDeclaration;
import dmd.Expression;
import dmd.ArrayTypes;

import dmd.TObject;

class InlineDoState : TObject
{
    VarDeclaration vthis;
    Array from;		// old Dsymbols
    Array to;		// parallel array of new Dsymbols
    Dsymbol parent;	// new parent
	
	this()
	{
		register();
		from = new Array();
		to = new Array();
	}
}

/******************************
 * Perform doInline() on an array of Expressions.
 */

Expressions arrayExpressiondoInline(Expressions a, InlineDoState ids)
{   
	Expressions newa = null;

    if (a)
    {
		newa = new Expressions();
		newa.setDim(a.dim);

		foreach (size_t i, Expression e; a)
		{   
			if (e)
			{
				e = e.doInline(ids);
				newa[i] = e;
			}
		}
    }
    return newa;
}