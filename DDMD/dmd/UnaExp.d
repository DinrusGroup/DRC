module dmd.UnaExp;

import dmd.common;
import dmd.Expression;
import dmd.InterState;
import dmd.TY;
import dmd.TypeClass;
import dmd.TypeStruct;
import dmd.Dsymbol;
import dmd.AggregateDeclaration;
import dmd.Type;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.TOK;
import dmd.Scope;
import dmd.InlineCostState;
import dmd.InlineDoState;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.DotIdExp;
import dmd.ArrayExp;
import dmd.CallExp;
import dmd.PREC;
import dmd.Token;
import dmd.expression.Util;

import dmd.DDMDExtensions;

class UnaExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Expression e1;

	this(Loc loc, TOK op, int size, Expression e1)
	{
		register();
		super(loc, op, size);
		this.e1 = e1;
	}

	override Expression syntaxCopy()
	{
		UnaExp e = cast(UnaExp)copy();
		e.type = null;
		e.e1 = e.e1.syntaxCopy();

		return e;
	}

	override Expression semantic(Scope sc)
	{
version (LOGSEMANTIC) {
		writef("UnaExp.semantic('%s')\n", toChars());
}
		e1 = e1.semantic(sc);
	//    if (!e1.type)
	//	error("%s has no value", e1.toChars());
		return this;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring(Token.toChars(op));
		expToCBuffer(buf, hgs, e1, precedence[op]);
	}

	override Expression optimize(int result)
	{
		e1 = e1.optimize(result);
		return this;
	}

	override void dump(int indent)
	{
		assert(false);
	}

	override void scanForNestedRef(Scope sc)
	{
		e1.scanForNestedRef(sc);
	}

	Expression interpretCommon(InterState istate, Expression* function(Type* a0, Expression* a1))
	{
		assert(false);
	}

	override bool canThrow()
	{
		return e1.canThrow();
	}

	override Expression resolveLoc(Loc loc, Scope sc)
	{
		e1 = e1.resolveLoc(loc, sc);
		return this;
	}

	override int inlineCost(InlineCostState* ics)
	{
		return 1 + e1.inlineCost(ics);
	}

	override Expression doInline(InlineDoState ids)
	{
		auto ue = cast(UnaExp)copy();

		ue.e1 = e1.doInline(ids);
		return ue;
	}

	override Expression inlineScan(InlineScanState* iss)
	{
		e1 = e1.inlineScan(iss);
		return this;
	}
	
	/************************************
	 * Operator overload.
	 * Check for operator overload, if so, replace
	 * with function call.
	 * Return null if not an operator overload.
	 */
	Expression op_overload(Scope sc)
	{
		//printf("UnaExp.op_overload() (%s)\n", toChars());
		AggregateDeclaration ad;
		Dsymbol fd;
		Type t1 = e1.type.toBasetype();

		if (t1.ty == TY.Tclass)
		{
			ad = (cast(TypeClass)t1).sym;
			goto L1;
		}
		else if (t1.ty == TY.Tstruct)
		{
			ad = (cast(TypeStruct)t1).sym;

			L1:
			fd = search_function(ad, opId());
			if (fd)
			{
				if (op == TOK.TOKarray)
				{
					/* Rewrite op e1[arguments] as:
					 *    e1.fd(arguments)
					 */
					Expression e = new DotIdExp(loc, e1, fd.ident);
					ArrayExp ae = cast(ArrayExp)this;
					e = new CallExp(loc, e, ae.arguments);
					e = e.semantic(sc);
					return e;
				}
				else
				{
					// Rewrite +e1 as e1.add()
					return build_overload(loc, sc, e1, null, fd.ident);
				}
			}

version (DMDV2) {
			// Didn't find it. Forward to aliasthis
			if (ad.aliasthis)
			{
				/* Rewrite op(e1) as:
				 *	op(e1.aliasthis)
				 */
				Expression e1 = new DotIdExp(loc, this.e1, ad.aliasthis.ident);
				Expression e = copy();
				(cast(UnaExp)e).e1 = e1;
				e = e.semantic(sc);
				return e;
			}
}
		}
		return null;
	}
}

