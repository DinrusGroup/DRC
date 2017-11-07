module dmd.NullExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.InterState;
import dmd.MATCH;
import dmd.Type;
import dmd.TY;
import dmd.TypeTypedef;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.backend.dt_t;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class NullExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	ubyte committed;

	this(Loc loc, Type type = null)
	{
		register();
		super(loc, TOK.TOKnull, NullExp.sizeof);
        this.type = type;
	}

	override Expression semantic(Scope sc)
	{
version (LOGSEMANTIC) {
		printf("NullExp.semantic('%s')\n", toChars());
}
		// null is the same as (void*)0
		if (!type)
			type = Type.tvoid.pointerTo();

		return this;
	}

	override bool isBool(bool result)
	{
		assert(false);
	}

	override int isConst()
	{
		return 0;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("null");
	}

	override void toMangleBuffer(OutBuffer buf)
	{
		buf.writeByte('n');
	}

	override MATCH implicitConvTo(Type t)
	{
static if (false) {
		printf("NullExp.implicitConvTo(this=%s, type=%s, t=%s, committed = %d)\n",
		toChars(), type.toChars(), t.toChars(), committed);
}
		if (this.type.equals(t))
			return MATCH.MATCHexact;

		/* Allow implicit conversions from invariant to mutable|const,
		 * and mutable to invariant. It works because, after all, a null
		 * doesn't actually point to anything.
		 */
		if (t.invariantOf().equals(type.invariantOf()))
			return MATCH.MATCHconst;

		// null implicitly converts to any pointer type or dynamic array
		if (type.ty == TY.Tpointer && type.nextOf().ty == TY.Tvoid)
		{
			if (t.ty == TY.Ttypedef)
				t = (cast(TypeTypedef)t).sym.basetype;
			if (t.ty == TY.Tpointer || t.ty == TY.Tarray ||
				t.ty == TY.Taarray  || t.ty == TY.Tclass ||
				t.ty == TY.Tdelegate)
			{
				return committed ? MATCH.MATCHconvert : MATCH.MATCHexact;
			}
		}

		return Expression.implicitConvTo(t);
	}

	override Expression castTo(Scope sc, Type t)
	{
		NullExp e;
		Type tb;

		//printf("NullExp::castTo(t = %p)\n", t);
		if (type is t)
		{
			committed = 1;
			return this;
		}

		e = cast(NullExp)copy();
		e.committed = 1;
		tb = t.toBasetype();
		e.type = type.toBasetype();

		if (tb !is e.type)
		{
			// null implicitly converts to any pointer type or dynamic array
			if (e.type.ty == TY.Tpointer && e.type.nextOf().ty == TY.Tvoid &&
				(tb.ty == TY.Tpointer || tb.ty == TY.Tarray || tb.ty == TY.Taarray ||
				 tb.ty == TY.Tdelegate))
			{
static if (false) {
				if (tb.ty == TY.Tdelegate)
				{   
					TypeDelegate td = cast(TypeDelegate)tb;
					TypeFunction tf = cast(TypeFunction)td.nextOf();

					if (!tf.varargs && !(tf.arguments && tf.arguments.dim))
					{
						return Expression.castTo(sc, t);
					}
				}
}
			}
			else
			{
				return e.Expression.castTo(sc, t);
			}
		}
		e.type = t;
		return e;
	}

	override Expression interpret(InterState istate)
	{
		return this;
	}

	override elem* toElem(IRState* irs)
	{
		return el_long(type.totym(), 0);
	}

	override dt_t** toDt(dt_t** pdt)
	{
		assert(type);
		return dtnzeros(pdt, cast(uint)type.size());
	}
}

