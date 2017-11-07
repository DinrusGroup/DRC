module dmd.ErrorExp;

import dmd.common;
import dmd.OutBuffer;
import dmd.IntegerExp;
import dmd.Loc;
import dmd.TOK;
import dmd.HdrGenState;
import dmd.Type;

import dmd.DDMDExtensions;

/* Use this expression for error recovery.
 * It should behave as a 'sink' to prevent further cascaded error messages.
 */

class ErrorExp : IntegerExp
{
	mixin insertMemberExtension!(typeof(this));

	this()
	{
		register();
		super(Loc(0), 0, Type.terror);
	    op = TOKerror;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("__error");
	}
}

