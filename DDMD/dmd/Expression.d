module dmd.Expression;

import dmd.common;
import dmd.Loc;
import dmd.TOK;
import dmd.Parameter;
import dmd.IdentifierExp;
import dmd.Type;
import dmd.WANT;
import dmd.Scope;
import dmd.Array;
import dmd.ArrayTypes;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.MATCH;
import dmd.IntRange;
import dmd.Dsymbol;
import dmd.FuncDeclaration;
import dmd.InterState;
import dmd.InlineCostState;
import dmd.InlineDoState;
import dmd.InlineScanState;
import dmd.Identifier;
import dmd.IRState;
import dmd.DotIdExp;
import dmd.TypeExp;
import dmd.DYNCAST;
import dmd.TY;
import dmd.CallExp;
import dmd.VarExp;
import dmd.STC;
import dmd.TemplateInstance;
import dmd.CommaExp;
import dmd.NullExp;
import dmd.AddrExp;
import dmd.LINK;
import dmd.FuncExp;
import dmd.ReturnStatement;
import dmd.Statement;
import dmd.FuncLiteralDeclaration;
import dmd.TypeFunction;
import dmd.ErrorExp;
import dmd.TypeStruct;
import dmd.CastExp;
import dmd.Global;
import dmd.GlobalExpressions;
import dmd.Token;
import dmd.TypeClass;
import dmd.PtrExp;
import dmd.TypeSArray;
import dmd.TypeReference;
import dmd.Util;
import dmd.Complex;

import dmd.backend.elem;
import dmd.backend.Util;
import dmd.backend.dt_t;

import dmd.DDMDExtensions;

import core.memory;

import std.stdio : writef;

import std.conv;

/* Things like:
 *	int.size
 *	foo.size
 *	(foo).size
 *	cast(foo).size
 */

Expression typeDotIdExp(Loc loc, Type type, Identifier ident)
{
	return new DotIdExp(loc, new TypeExp(loc, type), ident);
}

/*****************************************
 * Determine if 'this' is available.
 * If it is, return the FuncDeclaration that has it.
 */

FuncDeclaration hasThis(Scope sc)
{  
	FuncDeclaration fd;
    FuncDeclaration fdthis;

    //printf("hasThis()\n");
    fdthis = sc.parent.isFuncDeclaration();
    //printf("fdthis = %p, '%s'\n", fdthis, fdthis ? fdthis.toChars() : "");

    // Go upwards until we find the enclosing member function
    fd = fdthis;
    while (1)
    {
		if (!fd)
		{
			goto Lno;
		}
		if (!fd.isNested())
			break;

		Dsymbol parent = fd.parent;
		while (parent)
		{
			TemplateInstance ti = parent.isTemplateInstance();
			if (ti)
				parent = ti.parent;
			else
				break;
		}

		fd = fd.parent.isFuncDeclaration();
    }

    if (!fd.isThis())
    {  
		//printf("test '%s'\n", fd.toChars());
		goto Lno;
    }

    assert(fd.vthis);
    return fd;

Lno:
    return null;		// don't have 'this' available
}

/***************************************
 * Pull out any properties.
 */
Expression resolveProperties(Scope sc, Expression e)
{
    //printf("resolveProperties(%s)\n", e.toChars());
    if (e.type)
    {
		Type t = e.type.toBasetype();

		if (t.ty == TY.Tfunction || e.op == TOK.TOKoverloadset)
		{
static if(false)
{
		    if (t.ty == Tfunction && !(cast(TypeFunction)t).isproperty)
			error(e.loc, "not a property %s\n", e.toChars());
}
			e = new CallExp(e.loc, e);
			e = e.semantic(sc);
		}

		/* Look for e being a lazy parameter; rewrite as delegate call
		 */
		else if (e.op == TOK.TOKvar)
		{   VarExp ve = cast(VarExp)e;

			if (ve.var.storage_class & STC.STClazy)
			{
				e = new CallExp(e.loc, e);
				e = e.semantic(sc);
			}
		}

		else if (e.op == TOK.TOKdotexp)
		{
			e.error("expression has no value");
		}
    }
    else if (e.op == TOK.TOKdottd)
    {
		e = new CallExp(e.loc, e);
		e = e.semantic(sc);
    }

    return e;
}

void indent(int indent)
{
    foreach (i; 0 .. indent)
        writef(" ");
}

string type_print(Type type)
{
    return type ? type.toChars() : "null";
}

import dmd.TObject;

class Expression : TObject
{
	mixin insertMemberExtension!(typeof(this));
	
    Loc loc;			// file location
    TOK op;		// handy to minimize use of dynamic_cast
    Type type;			// !=null means that semantic() has been run
    int size;			// # of bytes in Expression so we can copy() it

    this(Loc loc, TOK op, int size)
	{
		register();
		this.loc = loc;
		//writef("Expression.Expression(op = %d %s) this = %p\n", op, to!(string)(op), this);
		this.op = op;
		this.size = size;
		type = null;
	}

	bool equals(Object o)
	{
		return this is o;
	}

	/*********************************
	 * Does *not* do a deep copy.
	 */
    Expression copy()
	{
		return cloneThis(this);
	}
	
    Expression syntaxCopy()
	{
		//printf("Expression::syntaxCopy()\n");
		//dump(0);
		return copy();
	}
	
    Expression semantic(Scope sc)
	{
	version (LOGSEMANTIC) {
		printf("Expression.semantic() %s\n", toChars());
	}
		if (type)
			type = type.semantic(loc, sc);
		else
			type = Type.tvoid;
		return this;
	}
	
    Expression trySemantic(Scope sc)
	{
		uint errors = global.errors;
		global.gag++;
		Expression e = semantic(sc);
		global.gag--;
		if (errors != global.errors)
		{
			global.errors = errors;
			e = null;
		}
		return e;
	}

    DYNCAST dyncast() { return DYNCAST.DYNCAST_EXPRESSION; }	// kludge for template.isExpression()

    void print()
	{
		assert(false);
	}
	
    string toChars()
	{
		scope OutBuffer buf = new OutBuffer();
		HdrGenState hgs;
	
		toCBuffer(buf, &hgs);
		return buf.toChars();
	}
	
    void dump(int i)
	{
		indent(i);
		writef("%p %s type=%s\n", this, Token.toChars(op), type_print(type));
	}

    void error(T...)(string format, T t)
	{
		.error(loc, format, t);
	}
	
    void warning(T...)(string formar, T t)
	{
		.warning(loc, format, t);
	}

    void rvalue()
	{
		if (type && type.toBasetype().ty == TY.Tvoid)
		{	
			error("expression %s is void and has no value", toChars());
static if (false) {
			dump(0);
			halt();
}
			type = Type.terror;
		}
	}

    static Expression combine(Expression e1, Expression e2)
	{
		if (e1)
		{
			if (e2)
			{
				e1 = new CommaExp(e1.loc, e1, e2);
				e1.type = e2.type;
			}
		}
		else
		{
			e1 = e2;
		}

		return e1;
	}
    
	static Expressions arraySyntaxCopy(Expressions exps)
	{
		Expressions a = null;

		if (exps)
		{
			a = new Expressions();
			a.setDim(exps.dim);
			for (size_t i = 0; i < a.dim; i++)
			{   
				auto e = exps[i];

			    if (e)
					e = e.syntaxCopy();
				a[i] = e;
			}
		}
		return a;
	}

    ulong toInteger()
	{
		//printf("Expression %s\n", Token.toChars(op));
		error("Integer constant expression expected instead of %s", toChars());
		return 0;
	}
    
    ulong toUInteger()
	{
		//printf("Expression %s\n", Token.toChars(op));
		return cast(ulong)toInteger();
	}
    
    real toReal()
	{
		error("Floating point constant expression expected instead of %s", toChars());
		return 0;
	}
    
    real toImaginary()
	{
		error("Floating point constant expression expected instead of %s", toChars());
		return 0;
	}
    
    Complex!(real) toComplex()
	{
		error("Floating point constant expression expected instead of %s", toChars());
		return Complex!real(0);
	}
    
    void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring(Token.toChars(op));
	}
    
    void toMangleBuffer(OutBuffer buf)
	{
		error("expression %s is not a valid template value argument", toChars());
		assert(false);
version (DEBUG) {
		dump(0);
}
	}
    
	/***************************************
	 * Return true if expression is an lvalue.
	 */
    bool isLvalue()
	{
		return false;
	}

	/*******************************
	 * Give error if we're not an lvalue.
	 * If we can, convert expression to be an lvalue.
	 */
	Expression toLvalue(Scope sc, Expression e)
	{
		   if (!e)
				e = this;
			else if (!loc.filename)
				loc = e.loc;
			error("%s is not an lvalue", e.toChars());
			return this;
	}

    Expression modifiableLvalue(Scope sc, Expression e)
	{
		//printf("Expression::modifiableLvalue() %s, type = %s\n", toChars(), type.toChars());

		// See if this expression is a modifiable lvalue (i.e. not const)
version (DMDV2) {
		if (type && (!type.isMutable() || !type.isAssignable()))
			error("%s is not mutable", e.toChars());
}
		return toLvalue(sc, e);
	}
    
	/**************************************
	 * Do an implicit cast.
	 * Issue error if it can't be done.
	 */
    Expression implicitCastTo(Scope sc, Type t)
	{
		//printf("Expression.implicitCastTo(%s of type %s) => %s\n", toChars(), type.toChars(), t.toChars());

		MATCH match = implicitConvTo(t);
		if (match)
		{
			TY tyfrom = type.toBasetype().ty;
			TY tyto = t.toBasetype().ty;

version (DMDV1) {
			if (global.params.warnings &&
				Type.impcnvWarn[tyfrom][tyto] &&
				op != TOKint64)
			{
				Expression e = optimize(WANT.WANTflags | WANT.WANTvalue);

				if (e.op == TOK.TOKint64)
				return e.implicitCastTo(sc, t);
				if (tyfrom == Tint32 && (op == TOKadd || op == TOKmin || op == TOKand || op == TOKor || op == TOKxor))
				{
					/* This is really only a semi-kludge fix,
					 * we really should look at the operands of op
					 * and see if they are narrower types.
					 * For example, b=b|b and b=b|7 and s=b+b should be allowed,
					 * but b=b|i should be an error.
					 */
					//;
				}
				else
				{
					warning("implicit conversion of expression (%s) of type %s to %s can cause loss of data", toChars(), type.toChars(), t.toChars());
				}
			}
}
version (DMDV2) {
			if (match == MATCH.MATCHconst && t == type.constOf())
			{
				Expression e = copy();
				e.type = t;
				return e;
			}
}
			return castTo(sc, t);
		}

		Expression e = optimize(WANT.WANTflags | WANT.WANTvalue);
		if (e != this)
			return e.implicitCastTo(sc, t);

static if (false) {
	printf("ty = %d\n", type.ty);
	print();
	type.print();
	printf("to:\n");
	t.print();
	printf("%p %p type: %s to: %s\n", type.deco, t.deco, type.deco, t.deco);
	//printf("%p %p %p\n", type.nextOf().arrayOf(), type, t);
	fflush(stdout);
}
		if (!t.deco) {
			/* Can happen with:
			 *    enum E { One }
			 *    class A
			 *    { static void fork(EDG dg) { dg(E.One); }
			 *	alias void delegate(E) EDG;
			 *    }
			 * Should eventually make it work.
			 */
			error("forward reference to type %s", t.toChars());
		} else if (t.reliesOnTident()) {
			error("forward reference to type %s", t.reliesOnTident().toChars());
		}

		error("cannot implicitly convert expression (%s) of type %s to %s", toChars(), type.toChars(), t.toChars());
		return castTo(sc, t);
	}
    
	/*******************************************
	 * Return !=0 if we can implicitly convert this to type t.
	 * Don't do the actual cast.
	 */
    MATCH implicitConvTo(Type t)
	{
static if (false) {
		printf("Expression.implicitConvTo(this=%s, type=%s, t=%s)\n",
			toChars(), type.toChars(), t.toChars());
}
		//static int nest; if (++nest == 10) halt();
		if (!type)
		{	
			error("%s is not an expression", toChars());
			type = Type.terror;
		}
		Expression e = optimize(WANT.WANTvalue | WANT.WANTflags);
		if (e.type == t)
			return MATCH.MATCHexact;
		if (e != this)
		{	
			//printf("\toptimized to %s of type %s\n", e.toChars(), e.type.toChars());
			return e.implicitConvTo(t);
		}
		MATCH match = type.implicitConvTo(t);
		if (match != MATCH.MATCHnomatch)
			return match;

		/* See if we can do integral narrowing conversions
		 */
		if (type.isintegral() && t.isintegral() &&
		type.isTypeBasic() && t.isTypeBasic())
		{	
			IntRange ir = getIntRange();
			if (ir.imax <= t.sizemask())
				return MATCH.MATCHconvert;
		}

static if (false) {
		Type tb = t.toBasetype();
		if (tb.ty == Tdelegate)
		{	
			TypeDelegate td = cast(TypeDelegate)tb;
			TypeFunction tf = cast(TypeFunction)td.nextOf();

			if (!tf.varargs && !(tf.arguments && tf.arguments.dim))
			{
				match = type.implicitConvTo(tf.nextOf());
				if (match)
					return match;
				if (tf.nextOf().toBasetype().ty == Tvoid)
					return MATCH.MATCHconvert;
			}
		}
}
		return MATCH.MATCHnomatch;
	}

    IntRange getIntRange()
	{
		IntRange ir;
		ir.imin = 0;
	    if (type.isintegral())
			ir.imax = type.sizemask();
		else
			ir.imax = 0xFFFFFFFFFFFFFFFFUL; // assume the worst

		return ir;
	}
	
	/**************************************
	 * Do an explicit cast.
	 */
    Expression castTo(Scope sc, Type t)
	{
		//printf("Expression.castTo(this=%s, t=%s)\n", toChars(), t.toChars());
static if (false) {
		writef("Expression.castTo(this=%s, type=%s, t=%s)\n",
		toChars(), type.toChars(), t.toChars());
}
		if (type is t)
			return this;
		Expression e = this;
		Type tb = t.toBasetype();
		Type typeb = type.toBasetype();
		if (tb != typeb)
		{
			// Do (type *) cast of (type [dim])
			if (tb.ty == TY.Tpointer && typeb.ty == TY.Tsarray
			   )
			{
				//printf("Converting [dim] to *\n");

				if (typeb.size(loc) == 0)
					e = new NullExp(loc);
				else
					e = new AddrExp(loc, e);
			}
			else {
static if (false) {
				if (tb.ty == Tdelegate && type.ty != Tdelegate)
				{
					TypeDelegate td = cast(TypeDelegate)tb;
					TypeFunction tf = cast(TypeFunction)td.nextOf();
					return toDelegate(sc, tf.nextOf());
				}
}
				if (typeb.ty == TY.Tstruct)
				{   
					TypeStruct ts = cast(TypeStruct)typeb;
					if (!(tb.ty == TY.Tstruct && ts.sym == (cast(TypeStruct)tb).sym) &&
						ts.sym.aliasthis)
					{   /* Forward the cast to our alias this member, rewrite to:
						 *   cast(to)e1.aliasthis
						 */
						Expression e1 = new DotIdExp(loc, this, ts.sym.aliasthis.ident);
						Expression e2 = new CastExp(loc, e1, tb);
						e2 = e2.semantic(sc);
						return e2;
					}
				}
				else if (typeb.ty == TY.Tclass)
				{   
					TypeClass ts = cast(TypeClass)typeb;
					if (tb.ty != TY.Tclass && ts.sym.aliasthis)
					{   /* Forward the cast to our alias this member, rewrite to:
						 *   cast(to)e1.aliasthis
						 */
						Expression e1 = new DotIdExp(loc, this, ts.sym.aliasthis.ident);
						Expression e2 = new CastExp(loc, e1, tb);
						e2 = e2.semantic(sc);
						return e2;
					}
				}
				e = new CastExp(loc, e, tb);
			}
		}
		else
		{
			e = e.copy();	// because of COW for assignment to e.type
		}

		assert(e != this);
		e.type = t;
		//printf("Returning: %s\n", e.toChars());
		return e;
	}
    
	/************************************
	 * Detect cases where pointers to the stack can 'escape' the
	 * lifetime of the stack frame.
	 */
    void checkEscape()
	{
	}
    
    void checkEscapeRef()
    {
    }
    
    void checkScalar()
	{
		if (!type.isscalar())
			error("'%s' is not a scalar, it is a %s", toChars(), type.toChars());

		rvalue();
	}

    void checkNoBool()
	{
		if (type.toBasetype().ty == TY.Tbool)
			error("operation not allowed on bool '%s'", toChars());
	}
    
    Expression checkIntegral()
	{
		if (!type.isintegral())
		{	
			error("'%s' is not of integral type, it is a %s", toChars(), type.toChars());
			return new ErrorExp();
		}

		rvalue();
		return this;
	}
    
    Expression checkArithmetic()
	{
		if (!type.isintegral() && !type.isfloating())
		{	
			error("'%s' is not of arithmetic type, it is a %s", toChars(), type.toChars());
			return new ErrorExp();
		}

		rvalue();
		return this;
	}
    
    void checkDeprecated(Scope sc, Dsymbol s)
	{
		s.checkDeprecated(loc, sc);
	}
    
    void checkPurity(Scope sc, FuncDeclaration f)
	{
static if (true) {
		if (sc.func)
		{
			/* Given:
			 * void f()
			 * { pure void g()
			 *   {
			 *	void h()
			 *	{
			 *	   void i() { }
			 *	}
			 *   }
			 * }
			 * g() can call h() but not f()
			 * i() can call h() and g() but not f()
			 */
			FuncDeclaration outerfunc = sc.func;
			while (outerfunc.toParent2() && outerfunc.toParent2().isFuncDeclaration())
			{
				outerfunc = outerfunc.toParent2().isFuncDeclaration();
			}
			if (outerfunc.isPure() && !sc.intypeof && (!f.isNested() && !f.isPure()))
				error("pure function '%s' cannot call impure function '%s'\n",
				sc.func.toChars(), f.toChars());
		}
} else {
		if (sc.func && sc.func.isPure() && !sc.intypeof && !f.isPure())
		error("pure function '%s' cannot call impure function '%s'\n",
			sc.func.toChars(), .toChars());
}
	}
	
	void checkSafety(Scope sc, FuncDeclaration f)
	{
		if (sc.func && sc.func.isSafe() && !sc.intypeof &&
			!f.isSafe() && !f.isTrusted())
			error("safe function '%s' cannot call system function '%s'\n",
				sc.func.toChars(), f.toChars());
	}
    
	/*****************************
	 * Check that expression can be tested for true or false.
	 */
    Expression checkToBoolean()
	{
		// Default is 'yes' - do nothing

debug {
		if (!type)
			dump(0);
}

		if (!type.checkBoolean())
		{
			error("expression %s of type %s does not have a boolean value", toChars(), type.toChars());
		}

		return this;
	}
    
    Expression checkToPointer()
	{
		//writef("Expression::checkToPointer()\n");
		Expression e = this;

version(SARRAYVALUE) {} else
{
		// If C static array, convert to pointer
		Type tb = type.toBasetype();
		if (tb.ty == Tsarray)
		{	
			TypeSArray ts = cast(TypeSArray)tb;
			if (ts.size(loc) == 0)
				e = new NullExp(loc);
			else
				e = new AddrExp(loc, this);
			e.type = ts.next.pointerTo();
		}
}
		return e;
	}
    
    Expression addressOf(Scope sc)
	{
		//printf("Expression::addressOf()\n");
		Expression e = toLvalue(sc, null);
		e = new AddrExp(loc, e);
		e.type = type.pointerTo();
		return e;
	}
    
	/******************************
	 * If this is a reference, dereference it.
	 */
    Expression deref()
	{
		//printf("Expression::deref()\n");
	    // type could be null if forward referencing an 'auto' variable
		if (type && type.ty == Treference)
		{
			Expression e = new PtrExp(loc, this);
			e.type = (cast(TypeReference)type).next;
			return e;
		}
		return this;
	}
    
	/***********************************
	 * Do integral promotions (convertchk).
	 * Don't convert <array of> to <pointer to>
	 */
    Expression integralPromotions(Scope sc)
	{
		Expression e = this;

		//printf("integralPromotions %s %s\n", e.toChars(), e.type.toChars());
		switch (type.toBasetype().ty)
		{
			case TY.Tvoid:
				error("void has no value");
				break;

			case TY.Tint8:
			case TY.Tuns8:
			case TY.Tint16:
			case TY.Tuns16:
			case TY.Tbit:
			case TY.Tbool:
			case TY.Tchar:
			case TY.Twchar:
				e = e.castTo(sc, Type.tint32);
				break;

			case TY.Tdchar:
				e = e.castTo(sc, Type.tuns32);
				break;
			default:
				break;	///
		}
		return e;
	}
    
	/********************************************
	 * Convert from expression to delegate that returns the expression,
	 * i.e. convert:
	 *	expr
	 * to:
	 *	t delegate() { return expr; }
	 */
    Expression toDelegate(Scope sc, Type t)
	{
		//printf("Expression.toDelegate(t = %s) %s\n", t.toChars(), toChars());
		TypeFunction tf = new TypeFunction(null, t, 0, LINKd);
		FuncLiteralDeclaration fld = new FuncLiteralDeclaration(loc, loc, tf, TOKdelegate, null);
		Expression e;
	static if (true) {
		sc = sc.push();
		sc.parent = fld;		// set current function to be the delegate
		e = this;
		e.scanForNestedRef(sc);
		sc = sc.pop();
	} else {
		e = this.syntaxCopy();
	}
		Statement s = new ReturnStatement(loc, e);
		fld.fbody = s;
		e = new FuncExp(loc, fld);
		e = e.semantic(sc);
		return e;
	}
    
    void scanForNestedRef(Scope sc)
	{
		//printf("Expression.scanForNestedRef(%s)\n", toChars());
	}
    
    Expression optimize(int result)
	{
		//printf("Expression.optimize(result = x%x) %s\n", result, toChars());
		return this;
	}
    
	Expression interpret(InterState istate)
	{
version(LOG)
{
		writef("Expression::interpret() %s\n", toChars());
		writef("type = %s\n", type.toChars());
		dump(0);
}
		error("Cannot interpret %s at compile time", toChars());
		return EXP_CANT_INTERPRET;
	}

    int isConst()
	{
		//printf("Expression::isConst(): %s\n", toChars());
		return 0;
	}
    
	/********************************
	 * Does this expression statically evaluate to a boolean TRUE or FALSE?
	 */
    bool isBool(bool result)
	{
		return false;
	}
    
	/********************************
	 * Does this expression result in either a 1 or a 0?
	 */
	bool isBit()
	{
		return false;
	}

	/********************************
	 * Check for expressions that have no use.
	 * Input:
	 *	flag	0 not going to use the result, so issue error message if no
	 *		  side effects
	 *		1 the result of the expression is used, but still check
	 *		  for useless subexpressions
	 *		2 do not issue error messages, just return !=0 if expression
	 *		  has side effects
	 */
    bool checkSideEffect(int flag)
	{
		if (flag == 0)
		{	
			if (op == TOKerror)
			{
				// Error should have already been printed
			}
			else if (op == TOKimport)
				error("%s has no effect", toChars());
			else
				error("%s has no effect in expression (%s)",

			Token.toChars(op), toChars());
		}

		return false;
	}
    
    bool canThrow()
	{
version (DMDV2) {
    return false;
} else {
    return true;
}
	}
    
	/****************************************
	 * Resolve __LINE__ and __FILE__ to loc.
	 */
	Expression resolveLoc(Loc loc, Scope sc)
	{
	    return this;
	}

    int inlineCost(InlineCostState* ics)
	{
		return 1;
	}
    
    Expression doInline(InlineDoState ids)
	{
		//printf("Expression.doInline(%s): %s\n", Token.toChars(op), toChars());
		return copy();
	}
    
    Expression inlineScan(InlineScanState* iss)
	{
		return this;
	}
	
	/***********************************
	 * Determine if operands of binary op can be reversed
	 * to fit operator overload.
	 */
    
    // For operator overloading
    bool isCommutative()
	{
		return false;	// default is no reverse
	}
    
	/***********************************
	 * Get Identifier for operator overload.
	 */	 
    Identifier opId()
	{
		assert(false);
	}
    
	/***********************************
	 * Get Identifier for reverse operator overload,
	 * null if not supported for this operator.
	 */
    Identifier opId_r()
	{
		return null;
	}
    
    // For array ops
	/******************************************
	 * Construct the identifier for the array operation function,
	 * and build the argument list to pass to it.
	 */
    void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		buf.writestring("Exp");
		arguments.shift(this);
	}
    
    Expression buildArrayLoop(Parameters fparams)
	{
		Identifier id = Identifier.generateId("c", fparams.dim);
		auto param = new Parameter(STC.STCundefined, type, id, null);
		fparams.shift(param);
		Expression e = new IdentifierExp(Loc(0), id);
		return e;
	}

	/***********************************************
	 * Test if operand is a valid array op operand.
	 */
	int isArrayOperand()
	{
		//writef("Expression::isArrayOperand() %s\n", toChars());
		if (op == TOKslice)
			return 1;
		if (type.toBasetype().ty == TY.Tarray)
		{
			switch (op)
			{
				case TOKadd:
				case TOKmin:
				case TOKmul:
				case TOKdiv:
				case TOKmod:
				case TOKxor:
				case TOKand:
				case TOKor:
				case TOKneg:
				case TOKtilde:
				return 1;
	
				default:
				break;
			}
		}
		return 0;
	}

    // Back end
    elem* toElem(IRState* irs)
	{
		print();
		assert(false);
		return null;
	}
    
    dt_t** toDt(dt_t** pdt)
	{
		debug
		{
			writef("Expression::toDt() %d\n", op);
			dump(0);
		}
		error("non-constant expression %s", toChars());
		pdt = dtnzeros(pdt, 1);
		return pdt;
	}
}

alias Vector!Expression Expressions;