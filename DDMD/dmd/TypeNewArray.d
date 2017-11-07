module dmd.TypeNewArray;

import dmd.common;
import dmd.HdrGenState;
import dmd.MOD;
import dmd.OutBuffer;
import dmd.Type;
import dmd.TypeNext;
import dmd.TY;

import dmd.DDMDExtensions;

/** T[new]
 */
class TypeNewArray : TypeNext
{
	mixin insertMemberExtension!(typeof(this));

	this(Type next)
	{
		register();
		super(Tnarray, next);
		//writef("TypeNewArray\n");
	}

	override void toCBuffer2(OutBuffer buf, HdrGenState *hgs, MOD mod)
	{
		if (mod != this.mod)
		{
			toCBuffer3(buf, hgs, mod);
			return;
		}
		next.toCBuffer2(buf, hgs, this.mod);
		buf.writestring("[new]");
	}
}