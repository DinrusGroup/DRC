module dmd.ExpInitializer;

import dmd.common;
import dmd.Initializer;
import dmd.DelegateExp;
import dmd.Loc;
import dmd.Scope;
import dmd.Type;
import dmd.SymOffExp;
import dmd.Expression;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.WANT;
import dmd.TOK;
import dmd.StringExp;
import dmd.TY;
import dmd.TypeSArray;

import dmd.backend.dt_t;

import dmd.DDMDExtensions;

class ExpInitializer : Initializer
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;

    this(Loc loc, Expression exp)
	{
		register();
		super(loc);
		this.exp = exp;
	}
	
    override Initializer syntaxCopy()
	{
		return new ExpInitializer(loc, exp.syntaxCopy());
	}
	
    override Initializer semantic(Scope sc, Type t)
	{
		//printf("ExpInitializer.semantic(%s), type = %s\n", exp.toChars(), t.toChars());
		exp = exp.semantic(sc);
		exp = resolveProperties(sc, exp);
		exp = exp.optimize(WANT.WANTvalue | WANT.WANTinterpret);
		Type tb = t.toBasetype();

		/* Look for case of initializing a static array with a too-short
		 * string literal, such as:
		 *	char[5] foo = "abc";
		 * Allow this by doing an explicit cast, which will lengthen the string
		 * literal.
		 */
		if (exp.op == TOK.TOKstring && tb.ty == TY.Tsarray && exp.type.ty == TY.Tsarray)
		{	
			StringExp se = cast(StringExp)exp;

			if (!se.committed && se.type.ty == TY.Tsarray && (cast(TypeSArray)se.type).dim.toInteger() < (cast(TypeSArray)t).dim.toInteger())
			{
				exp = se.castTo(sc, t);
				goto L1;
			}
		}

		// Look for the case of statically initializing an array
		// with a single member.
		if (tb.ty == TY.Tsarray && !tb.nextOf().equals(exp.type.toBasetype().nextOf()) && exp.implicitConvTo(tb.nextOf()))
		{
			t = tb.nextOf();
		}

		exp = exp.implicitCastTo(sc, t);
	L1:
		exp = exp.optimize(WANT.WANTvalue | WANT.WANTinterpret);
		//printf("-ExpInitializer.semantic(): "); exp.print();
		return this;
	}
	
    override Type inferType(Scope sc)
	{
		//printf("ExpInitializer::inferType() %s\n", toChars());
		exp = exp.semantic(sc);
		exp = resolveProperties(sc, exp);

		// Give error for overloaded function addresses
		if (exp.op == TOKsymoff)
		{   
			SymOffExp se = cast(SymOffExp)exp;
			if (se.hasOverloads && !se.var.isFuncDeclaration().isUnique())
				exp.error("cannot infer type from overloaded function symbol %s", exp.toChars());
		}
		
	    // Give error for overloaded function addresses
		if (exp.op == TOKdelegate)
		{   
			DelegateExp se = cast(DelegateExp)exp;
			if (se.func.isFuncDeclaration() && !se.func.isFuncDeclaration().isUnique())
				exp.error("cannot infer type from overloaded function symbol %s", exp.toChars());
		}


		Type t = exp.type;
		if (!t)
			t = Initializer.inferType(sc);

		return t;
	}
	
    override Expression toExpression()
	{
		return exp;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		exp.toCBuffer(buf, hgs);
	}

    override dt_t* toDt()
	{
		dt_t* dt = null;

		exp = exp.optimize(WANT.WANTvalue);
		exp.toDt(&dt);

		return dt;
	}

    override ExpInitializer isExpInitializer() { return this; }
}
