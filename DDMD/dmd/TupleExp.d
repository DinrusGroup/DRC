module dmd.TupleExp;

import dmd.common;
import dmd.Expression;
import dmd.TupleDeclaration;
import dmd.backend.elem;
import dmd.InterState;
import dmd.WANT;
import dmd.Type;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.InlineCostState;
import dmd.IRState;
import dmd.InlineDoState;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.ArrayTypes;
import dmd.TypeExp;
import dmd.TypeTuple;
import dmd.TOK;
import dmd.TY;
import dmd.Dsymbol;
import dmd.DsymbolExp;
import dmd.DYNCAST;
import dmd.expression.Util;

import dmd.DDMDExtensions;

/****************************************
 * Expand tuples.
 */
/+
void expandTuples(Expressions exps)
{
    //printf("expandTuples()\n");
    if (exps)
    {
	for (size_t i = 0; i < exps.dim; i++)
	{   Expression arg = cast(Expression)exps.data[i];
	    if (!arg)
		continue;

	    // Look for tuple with 0 members
	    if (arg.op == TOKtype)
	    {	TypeExp e = cast(TypeExp)arg;
		if (e.type.toBasetype().ty == Ttuple)
		{   TypeTuple tt = cast(TypeTuple)e.type.toBasetype();

		    if (!tt.arguments || tt.arguments.dim == 0)
		    {
			exps.remove(i);
			if (i == exps.dim)
			    return;
			i--;
			continue;
		    }
		}
	    }

	    // Inline expand all the tuples
	    while (arg.op == TOKtuple)
	    {	TupleExp te = cast(TupleExp)arg;

		exps.remove(i);		// remove arg
		exps.insert(i, te.exps);	// replace with tuple contents
		if (i == exps.dim)
		    return;		// empty tuple, no more arguments
		arg = cast(Expression)exps.data[i];
	    }
	}
    }
}
+/
class TupleExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Expressions exps;

	this(Loc loc, Expressions exps)
	{
		register();
		super(loc, TOKtuple, TupleExp.sizeof);
		
		this.exps = exps;
		this.type = null;
	}

	this(Loc loc, TupleDeclaration tup)
	{
		register();
		super(loc, TOKtuple, TupleExp.sizeof);
		exps = new Expressions();
		type = null;

		exps.reserve(tup.objects.dim);
		foreach (o; tup.objects)
		{   
			if (auto e = cast(Expression)o)
			{
				e = e.syntaxCopy();
				exps.push(e);
			}
			else if (auto s = cast(Dsymbol)o)
			{
				auto e = new DsymbolExp(loc, s);
				exps.push(e);
			}
			else if (auto t = cast(Type)o)
			{
				auto e = new TypeExp(loc, t);
				exps.push(e);
			}
			else
			{
				error("%s is not an expression", o.toString());
			}
		}
	}

	override Expression syntaxCopy()
	{
		return new TupleExp(loc, arraySyntaxCopy(exps));
	}

	override bool equals(Object o)
	{
		TupleExp ne;

		if (this == o)
			return 1;
		if ((cast(Expression)o).op == TOKtuple)
		{
			auto te = cast(TupleExp)o;
			if (exps.dim != te.exps.dim)
				return 0;
			for (size_t i = 0; i < exps.dim; i++)
			{   auto e1 = exps[i];
				auto e2 = te.exps[i];

				if (!e1.equals(e2))
					return 0;
			}
			return 1;
		}
		return 0;
	}

	override Expression semantic(Scope sc)
	{
		version (LOGSEMANTIC) {
			printf("+TupleExp::semantic(%s)\n", toChars());
		}
		if (type)
			return this;

		// Run semantic() on each argument
		foreach (ref Expression e; exps)
		{
			e = e.semantic(sc);
			if (!e.type)
			{   error("%s has no value", e.toChars());
				e.type = Type.terror;
			}
		}

		expandTuples(exps);
		if (0 && exps.dim == 1)
		{
			return exps[0];
		}
		type = new TypeTuple(exps);
		type = type.semantic(loc, sc);
		//printf("-TupleExp::semantic(%s)\n", toChars());
		return this;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("tuple(");
		argsToCBuffer(buf, exps, hgs);
		buf.writeByte(')');
	}

	override void scanForNestedRef(Scope sc)
	{
		assert(false);
	}

	override void checkEscape()
	{
		foreach(e; exps)
		{
			e.checkEscape();
		}
	}

	override bool checkSideEffect(int flag)
	{
		bool f = false;

		foreach(e; exps)
		{
			f |= e.checkSideEffect(2);
		}
		if (flag == 0 && f == 0)
			Expression.checkSideEffect(0);
		return f;
	}

	override Expression optimize(int result)
	{
		foreach(ref Expression e; exps)
		{   
			e = e.optimize(WANTvalue | (result & WANTinterpret));
		}
		return this;
	}

	override Expression interpret(InterState istate)
	{
		assert(false);
	}

	override Expression castTo(Scope sc, Type t)
	{
		assert(false);
	}

	override elem* toElem(IRState* irs)
	{
		assert(false);
	}

	override bool canThrow()
	{
		return arrayExpressionCanThrow(exps);
	}

	override int inlineCost(InlineCostState* ics)
	{
		assert(false);
	}

	override Expression doInline(InlineDoState ids)
	{
		assert(false);
	}

	override Expression inlineScan(InlineScanState* iss)
	{
		assert(false);
	}
}

