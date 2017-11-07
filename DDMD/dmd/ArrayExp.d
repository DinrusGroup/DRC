module dmd.ArrayExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.UnaExp;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.InlineCostState;
import dmd.InlineDoState;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.ArrayTypes;
import dmd.PREC;
import dmd.TOK;
import dmd.Type;
import dmd.TY;
import dmd.Id;
import dmd.IndexExp;

import dmd.expression.Util;

import dmd.DDMDExtensions;

class ArrayExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	Expressions arguments;

	this(Loc loc, Expression e1, Expressions args)
	{
		register();
		super(loc, TOK.TOKarray, ArrayExp.sizeof, e1);
		arguments = args;
	}

	override Expression syntaxCopy()
	{
	    return new ArrayExp(loc, e1.syntaxCopy(), arraySyntaxCopy(arguments));
	}

	override Expression semantic(Scope sc)
	{
		Expression e;
		Type t1;

	version (LOGSEMANTIC) {
		printf("ArrayExp::semantic('%s')\n", toChars());
	}
		UnaExp.semantic(sc);
		e1 = resolveProperties(sc, e1);

		t1 = e1.type.toBasetype();
		if (t1.ty != Tclass && t1.ty != Tstruct)
		{	
			// Convert to IndexExp
			if (arguments.dim != 1)
				error("only one index allowed to index %s", t1.toChars());
			e = new IndexExp(loc, e1, arguments[0]);
			return e.semantic(sc);
		}

		// Run semantic() on each argument
		foreach (size_t i, Expression e; arguments)
		{	
			e = e.semantic(sc);
			if (!e.type)
				error("%s has no value", e.toChars());
			arguments[i] = e;
		}

		expandTuples(arguments);
		assert(arguments && arguments.dim);

		e = op_overload(sc);
		if (!e)
		{
			error("no [] operator overload for type %s", e1.type.toChars());
			e = e1;
		}
		return e;
	}

	override bool isLvalue()
	{
		assert(false);
	}

	override Expression toLvalue(Scope sc, Expression e)
	{
		assert(false);
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC_primary);
		buf.writeByte('[');
		argsToCBuffer(buf, arguments, hgs);
		buf.writeByte(']');
	}

	override void scanForNestedRef(Scope sc)
	{
		assert(false);
	}

	override Identifier opId()
	{
		return Id.index;
	}

	override int inlineCost(InlineCostState* ics)
	{
		return 1 + e1.inlineCost(ics) + arrayInlineCost(ics, arguments);
	}

	override Expression doInline(InlineDoState ids)
	{
		ArrayExp ce;

		ce = cast(ArrayExp)copy();
		ce.e1 = e1.doInline(ids);
		ce.arguments = arrayExpressiondoInline(arguments, ids);
		return ce;
	}

	override Expression inlineScan(InlineScanState* iss)
	{
		Expression e = this;

		//printf("ArrayExp.inlineScan()\n");
		e1 = e1.inlineScan(iss);
		arrayInlineScan(iss, arguments);

		return e;
	}
}

