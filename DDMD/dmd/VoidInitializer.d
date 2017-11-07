module dmd.VoidInitializer;

import dmd.common;
import dmd.Initializer;
import dmd.Type;
import dmd.Loc;
import dmd.Scope;
import dmd.Expression;
import dmd.OutBuffer;
import dmd.HdrGenState;

import dmd.backend.dt_t;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class VoidInitializer : Initializer
{
	mixin insertMemberExtension!(typeof(this));

    Type type = null;		// type that this will initialize to

    this(Loc loc)
	{
		register();
		super(loc);
	}
	
    override Initializer syntaxCopy()
	{
		return new VoidInitializer(loc);
	}
	
    override Initializer semantic(Scope sc, Type t)
	{
		//printf("VoidInitializer.semantic(t = %p)\n", t);
		type = t;
		return this;
	}
	
    override Expression toExpression()
	{
		assert(false);
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("void");
	}

    override dt_t* toDt()
	{
		/* Void initializers are set to 0, just because we need something
		 * to set them to in the static data segment.
		 */
		dt_t *dt = null;

		dtnzeros(&dt, cast(uint)type.size());
		return dt;
	}

    override VoidInitializer isVoidInitializer() { return this; }
}
