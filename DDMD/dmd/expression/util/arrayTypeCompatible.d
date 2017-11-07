module dmd.expression.util.arrayTypeCompatible;

import dmd.common;
import dmd.Loc;
import dmd.Type;
import dmd.TY;
import dmd.MATCH;
import dmd.Util;

/***********************************
 * See if both types are arrays that can be compared
 * for equality. Return !=0 if so.
 * If they are arrays, but incompatible, issue error.
 * This is to enable comparing things like an immutable
 * array with a mutable one.
 */
bool arrayTypeCompatible(Loc loc, Type t1, Type t2)
{
    t1 = t1.toBasetype();
    t2 = t2.toBasetype();

    if ((t1.ty == TY.Tarray || t1.ty == TY.Tsarray || t1.ty == TY.Tpointer) && (t2.ty == TY.Tarray || t2.ty == TY.Tsarray || t2.ty == TY.Tpointer))
	{
		if (t1.nextOf().implicitConvTo(t2.nextOf()) < MATCH.MATCHconst && 
			t2.nextOf().implicitConvTo(t1.nextOf()) < MATCH.MATCHconst &&
			(t1.nextOf().ty != TY.Tvoid && t2.nextOf().ty != TY.Tvoid))
		{
			error(loc, "array equality comparison type mismatch, %s vs %s", t1.toChars(), t2.toChars());
		}
		
		return true;
    }

    return false;
}