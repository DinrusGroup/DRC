module dmd.expression.Util;

import dmd.common;
import dmd.Expression;
import dmd.Loc;
import dmd.RealExp;
import dmd.Scope;
import dmd.FuncExp;
import dmd.DelegateExp;
import dmd.LINK;
import dmd.NullExp;
import dmd.SymOffExp;
import dmd.ExpInitializer;
import dmd.Lexer;
import dmd.AddExp;
import dmd.MinExp;
import dmd.MulExp;
import dmd.DivExp;
import dmd.ModExp;
import dmd.AndExp;
import dmd.OrExp;
import dmd.ShlExp;
import dmd.ShrExp;
import dmd.UshrExp;
import dmd.XorExp;
import dmd.TypeSArray;
import dmd.TypeArray;
import dmd.VarDeclaration;
import dmd.VoidInitializer;
import dmd.DeclarationExp;
import dmd.VarExp;
import dmd.NewExp;
import dmd.STC;
import dmd.WANT;
import dmd.IndexExp;
import dmd.AssignExp;
import dmd.CommaExp;
import dmd.CondExp;
import dmd.Parameter;
import dmd.DefaultInitExp;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Global;
import dmd.ScopeDsymbol;
import dmd.DotIdExp;
import dmd.DotVarExp;
import dmd.CallExp;
import dmd.TY;
import dmd.MATCH;
import dmd.BUILTIN;
import dmd.TypeFunction;
import dmd.declaration.Match;
import dmd.ArrayTypes;
import dmd.Declaration;
import dmd.FuncAliasDeclaration;
import dmd.AliasDeclaration;
import dmd.FuncDeclaration;
import dmd.TemplateDeclaration;
import dmd.AggregateDeclaration;
import dmd.IntegerExp;
import dmd.Type;
import dmd.TOK;
import dmd.TypeExp;
import dmd.TypeTuple;
import dmd.TupleExp;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.ClassDeclaration;
import dmd.TypeClass;
import dmd.StructDeclaration;
import dmd.TypeStruct;
import dmd.MOD;
import dmd.PROT;
import dmd.PREC;
import dmd.Util;
import dmd.TypeAArray;
import dmd.Id;
import dmd.PtrExp;
import dmd.ErrorExp;

import std.stdio : writef;

import core.stdc.math;
import core.stdc.string;
import core.stdc.stdlib;

/***********************************
 * Utility to build a function call out of this reference and argument.
 */
Expression build_overload(Loc loc, Scope sc, Expression ethis, Expression earg, Identifier id)
{
    Expression e;

    //printf("build_overload(id = '%s')\n", id.toChars());
    //earg.print();
    //earg.type.print();
    e = new DotIdExp(loc, ethis, id);

    if (earg)
		e = new CallExp(loc, e, earg);
    else
		e = new CallExp(loc, e);

    e = e.semantic(sc);
    return e;
}

/***************************************
 * Search for function funcid in aggregate ad.
 */

Dsymbol search_function(ScopeDsymbol ad, Identifier funcid)
{
    Dsymbol s;
    FuncDeclaration fd;
    TemplateDeclaration td;

    s = ad.search(Loc(0), funcid, 0);
    if (s)
    {
		Dsymbol s2;

		//printf("search_function: s = '%s'\n", s.kind());
		s2 = s.toAlias();
		//printf("search_function: s2 = '%s'\n", s2.kind());
		fd = s2.isFuncDeclaration();
		if (fd && fd.type.ty == TY.Tfunction)
			return fd;

		td = s2.isTemplateDeclaration();
		if (td)
			return td;
    }

    return null;
}

/********************************************
 * Find function in overload list that exactly matches t.
 */

/***************************************************
 * Visit each overloaded function in turn, and call
 * dg(param, f) on it.
 * Exit when no more, or dg(param, f) returns 1.
 * Returns:
 *	0	continue
 *	1	done
 */
bool overloadApply(Visitor)(FuncDeclaration fstart, ref Visitor visitor)
{
    FuncDeclaration f;
    Declaration d;
    Declaration next;

    for (d = fstart; d; d = next)
    {	
		FuncAliasDeclaration fa = d.isFuncAliasDeclaration();

		if (fa)
		{
			if (overloadApply(fa.funcalias, visitor))
				return true;
			next = fa.overnext;
		}
		else
		{
			AliasDeclaration a = d.isAliasDeclaration();

			if (a)
			{
				Dsymbol s = a.toAlias();
				next = s.isDeclaration();
				if (next is a)
					break;
				if (next is fstart)
					break;
			}
			else
			{
				f = d.isFuncDeclaration();
				if (f is null)
				{  
					d.error("is aliased to a function");
					break;		// BUG: should print error message?
				}
				if (visitor.visit(f))
					return true;

				next = f.overnext;
			}
		}
    }
    return false;
}

/********************************************
 * If there are no overloads of function f, return that function,
 * otherwise return NULL.
 */
struct Unique
{
	bool visit(FuncDeclaration f)
	{
		if (this.f)
		{	
			this.f = null;
			return true;		// ambiguous, done
		}
		else
		{	
			this.f = f;
			return false;
		}
	}
	
	FuncDeclaration f;
}

/********************************************
 * Decide which function matches the arguments best.
 */

struct Param2
{
    Match* m;
version(DMDV2) {
    Expression ethis;
    int property;	// 0: unintialized
			// 1: seen @property
			// 2: not @property
}
    Expressions arguments;
	
	bool visit(FuncDeclaration f)
	{
		Param2* p = &this;
		Match* m = p.m;
		Expressions arguments = p.arguments;
		MATCH match;

		if (f != m.lastf)		// skip duplicates
		{
			m.anyf = f;
			TypeFunction tf = cast(TypeFunction)f.type;

			int property = (tf.isproperty) ? 1 : 2;
			if (p.property == 0)
				p.property = property;
			else if (p.property != property)
				error(f.loc, "cannot overload both property and non-property functions");

			match = cast(MATCH) tf.callMatch(f.needThis() ? p.ethis : null, arguments);
			//printf("test: match = %d\n", match);
			if (match != MATCHnomatch)
			{
				if (match > m.last)
					goto LfIsBetter;

				if (match < m.last)
					goto LlastIsBetter;

				/* See if one of the matches overrides the other.
				 */
				if (m.lastf.overrides(f))
					goto LlastIsBetter;
				else if (f.overrides(m.lastf))
					goto LfIsBetter;

version (DMDV2) {
				/* Try to disambiguate using template-style partial ordering rules.
				 * In essence, if f() and g() are ambiguous, if f() can call g(),
				 * but g() cannot call f(), then pick f().
				 * This is because f() is "more specialized."
				 */
				{
					MATCH c1 = f.leastAsSpecialized(m.lastf);
					MATCH c2 = m.lastf.leastAsSpecialized(f);
					//printf("c1 = %d, c2 = %d\n", c1, c2);
					if (c1 > c2)
						goto LfIsBetter;
					if (c1 < c2)
						goto LlastIsBetter;
				}
}
			Lambiguous:
				m.nextf = f;
				m.count++;
				return false;

			LfIsBetter:
				m.last = match;
				m.lastf = f;
				m.count = 1;
				return false;

			LlastIsBetter:
				return false;
			}
		}
		return false;
	}
}

struct Param1
{
    Type t;		// type to match
    FuncDeclaration f;	// return value
	
	bool visit(FuncDeclaration f)
	{   
		Param1* p = &this;
		Type t = p.t;

		if (t.equals(f.type))
		{	
			p.f = f;
			return true;
		}

	version (DMDV2) {
		/* Allow covariant matches, as long as the return type
		 * is just a const conversion.
		 * This allows things like pure functions to match with an impure function type.
		 */
		if (t.ty == Tfunction)
		{   
			TypeFunction tf = cast(TypeFunction)f.type;
			if (tf.covariant(t) == 1 &&
				tf.nextOf().implicitConvTo(t.nextOf()) >= MATCHconst)
			{
				p.f = f;
				return true;
			}
		}
	}
		return false;
	}
}

void overloadResolveX(Match* m, FuncDeclaration fstart, Expression ethis, Expressions arguments)
{
    Param2 p;
    p.m = m;
    p.ethis = ethis;
    p.property = 0;
    p.arguments = arguments;
	
    overloadApply(fstart, p);
}

void templateResolve(Match* m, TemplateDeclaration td, Scope sc, Loc loc, Objects targsi, Expression ethis, Expressions arguments)
{
    FuncDeclaration fd;

    assert(td);
    fd = td.deduceFunctionTemplate(sc, loc, targsi, ethis, arguments);
    if (!fd)
		return;
    m.anyf = fd;
    if (m.last >= MATCH.MATCHexact)
    {
		m.nextf = fd;
		m.count++;
    }
    else
    {
		m.last = MATCH.MATCHexact;
		m.lastf = fd;
		m.count = 1;
    }
}

/******************************
 * Perform semantic() on an array of Expressions.
 */

void arrayExpressionSemantic(Expressions exps, Scope sc)
{
    if (exps)
    {
		foreach (ref Expression e; exps)
		{   
			e = e.semantic(sc);
		}
    }
}

Expressions arrayExpressionToCommonType(Scope sc, Expressions exps, Type *pt)
{
//version(DMDV1) {
//    /* The first element sets the type
//     */
//    Type *t0 = NULL;
//    for (size_t i = 0; i < exps->dim; i++)
//    {	Expression *e = (Expression *)exps->data[i];
//
//	if (!e->type)
//	{   error("%s has no value", e->toChars());
//	    e = new ErrorExp();
//	}
//	e = resolveProperties(sc, e);
//
//	if (!t0)
//	    t0 = e->type;
//	else
//	    e = e->implicitCastTo(sc, t0);
//	exps->data[i] = (void *)e;
//    }
//
//    if (!t0)
//	t0 = Type::tvoid;
//    if (pt)
//	*pt = t0;
//
//    // Eventually, we want to make this copy-on-write
//    return exps;
//}
version(DMDV2) {
    /* The type is determined by applying ?: to each pair.
     */
    /* Still have a problem with:
     *	ubyte[][] = [ cast(ubyte[])"hello", [1]];
     * which works if the array literal is initialized top down with the ubyte[][]
     * type, but fails with this function doing bottom up typing.
     */
    //printf("arrayExpressionToCommonType()\n");
    scope integerexp = new IntegerExp(0);
    scope condexp = new CondExp(Loc(0), integerexp, null, null);

    Type t0;
    Expression e0;
    int j0;
    foreach (size_t i, Expression e; exps)
    {
		e = resolveProperties(sc, e);
		if (!e.type)
		{   error("%s has no value", e.toChars());
		    e = new ErrorExp();
		}

		if (t0)
		{ 
			if (t0 != e.type)
		    {
				/* This applies ?: to merge the types. It's backwards;
				* ?: should call this function to merge types.
				*/
				condexp.type = null;
				condexp.e1 = e0;
				condexp.e2 = e;
				condexp.semantic(sc);
				exps[j0] = condexp.e1;
				e = condexp.e2;
				j0 = i;
				e0 = e;
				t0 = e0.type;
			}
		}
		else
		{
			j0 = i;
			e0 = e;
			t0 = e.type;
		}
		exps[i] = e;
    }

    if (t0)
    {
		foreach (ref Expression e; exps)
		{
			e = e.implicitCastTo(sc, t0);
		}
    }
    else
		t0 = Type.tvoid;		// [] is typed as void[]
    if (pt)
		*pt = t0;

    // Eventually, we want to make this copy-on-write
    return exps;
}
}

/****************************************
 * Preprocess arguments to function.
 */

void preFunctionParameters(Loc loc, Scope sc, Expressions exps)
{
    if (exps)
    {
		expandTuples(exps);
		
		foreach (size_t i, ref Expression arg; exps)
		{   
			if (!arg.type)
			{
debug {
				if (!global.gag) {
					writef("1: \n");
				}
}
				arg.error("%s is not an expression", arg.toChars());
				arg = new IntegerExp(arg.loc, 0, Type.tint32);
			}

			arg = resolveProperties(sc, arg);

			//arg.rvalue();
static if (false) {
			if (arg.type.ty == TY.Tfunction)
			{
				arg = new AddrExp(arg.loc, arg);
				arg = arg.semantic(sc);
			}
}
		}
    }
}

/*************************************************************
 * Given var, we need to get the
 * right 'this' pointer if var is in an outer class, but our
 * existing 'this' pointer is in an inner class.
 * Input:
 *	e1	existing 'this'
 *	ad	struct or class we need the correct 'this' for
 *	var	the specific member of ad we're accessing
 */

Expression getRightThis(Loc loc, Scope sc, AggregateDeclaration ad, Expression e1, Declaration var)
{
	//printf("\ngetRightThis(e1 = %s, ad = %s, var = %s)\n", e1.toChars(), ad.toChars(), var.toChars());
 L1:
    Type t = e1.type.toBasetype();
    //printf("e1.type = %s, var.type = %s\n", e1.type.toChars(), var.type.toChars());

    /* If e1 is not the 'this' pointer for ad
     */
    if (ad && !(t.ty == TY.Tpointer && t.nextOf().ty == TY.Tstruct && (cast(TypeStruct)t.nextOf()).sym == ad) && !(t.ty == TY.Tstruct && (cast(TypeStruct)t).sym == ad))
    {
		ClassDeclaration cd = ad.isClassDeclaration();
		ClassDeclaration tcd = t.isClassHandle();

		/* e1 is the right this if ad is a base class of e1
		 */
		if (!cd || !tcd || !(tcd == cd || cd.isBaseOf(tcd, null)))
		{
			/* Only classes can be inner classes with an 'outer'
			 * member pointing to the enclosing class instance
			 */
			if (tcd && tcd.isNested())
			{   
				/* e1 is the 'this' pointer for an inner class: tcd.
				 * Rewrite it as the 'this' pointer for the outer class.
				 */

				e1 = new DotVarExp(loc, e1, tcd.vthis);
				e1.type = tcd.vthis.type;
				// Do not call checkNestedRef()
				//e1 = e1.semantic(sc);

				// Skip up over nested functions, and get the enclosing
				// class type.
				int n = 0;
				Dsymbol s;
				for (s = tcd.toParent(); s && s.isFuncDeclaration(); s = s.toParent())
				{   
					FuncDeclaration f = s.isFuncDeclaration();
					if (f.vthis)
					{
						//printf("rewriting e1 to %s's this\n", f.toChars());
						n++;
						e1 = new VarExp(loc, f.vthis);
					}
				}
				if (s && s.isClassDeclaration())
				{   
					e1.type = s.isClassDeclaration().type;
					if (n > 1)
						e1 = e1.semantic(sc);
				}
				else
					e1 = e1.semantic(sc);
				goto L1;
			}
			/* Can't find a path from e1 to ad
			 */
			e1.error("this for %s needs to be type %s not type %s", var.toChars(), ad.toChars(), t.toChars());
		}
    }
    return e1;
}

/*******************************************
 * Given a symbol that could be either a FuncDeclaration or
 * a function template, resolve it to a function symbol.
 *	sc		instantiation scope
 *	loc		instantiation location
 *	targsi		initial list of template arguments
 *	ethis		if !null, the 'this' pointer argument
 *	fargs		arguments to function
 *	flags		1: do not issue error message on no match, just return null
 */

FuncDeclaration resolveFuncCall(Scope sc, Loc loc, Dsymbol s,
	Objects tiargs,
	Expression ethis,
	Expressions arguments,
	int flags)
{
	if (!s)
		return null;			// no match
    FuncDeclaration f = s.isFuncDeclaration();
    if (f)
		f = f.overloadResolve(loc, ethis, arguments);
    else
    {	
		TemplateDeclaration td = s.isTemplateDeclaration();
		assert(td);
		f = td.deduceFunctionTemplate(sc, loc, tiargs, null, arguments, flags);
    }
    return f;
}

/****************************************
 * Now that we know the exact type of the function we're calling,
 * the arguments[] need to be adjusted:
 *	1. implicitly convert argument to the corresponding parameter type
 *	2. add default arguments for any missing arguments
 *	3. do default promotions on arguments corresponding to ...
 *	4. add hidden _arguments[] argument
 *	5. call copy constructor for struct value arguments
 * Returns:
 *	return type from function
 */

Type functionParameters(Loc loc, Scope sc, TypeFunction tf, Expressions arguments)
{
    //printf("functionParameters()\n");
    assert(arguments);
    size_t nargs = arguments ? arguments.dim : 0;
    size_t nparams = Parameter.dim(tf.parameters);

    if (nargs > nparams && tf.varargs == 0)
	error(loc, "expected %zu arguments, not %zu for non-variadic function type %s", nparams, nargs, tf.toChars());

    uint n = (nargs > nparams) ? nargs : nparams;	// n = max(nargs, nparams)

    uint wildmatch = 0;
    
    int done = 0;
    for (size_t i = 0; i < n; i++)
    {
		Expression arg;

		if (i < nargs)
			arg = arguments[i];
		else
			arg = null;

		Type tb;

		if (i < nparams)
		{
			auto p = Parameter.getNth(tf.parameters, i);

			if (!arg)
			{
				if (!p.defaultArg)
				{
					if (tf.varargs == 2 && i + 1 == nparams)
						goto L2;

					error(loc, "expected %d function arguments, not %d", nparams, nargs);
					return tf.next;
				}
				arg = p.defaultArg;
				arg = arg.copy();
version (DMDV2)
{
				arg = arg.resolveLoc(loc, sc);		// __FILE__ and __LINE__
}
				arguments.push(arg);
				nargs++;
			}

			if (tf.varargs == 2 && i + 1 == nparams)
			{
				//printf("\t\tvarargs == 2, p.type = '%s'\n", p.type.toChars());
				if (arg.implicitConvTo(p.type))
				{
					if (nargs != nparams)
					{
						error(loc, "expected %zu function arguments, not %zu", nparams, nargs);
						return tf.next;
					}
					goto L1;
				}
				 L2:
				tb = p.type.toBasetype();		///
				Type tret = p.isLazyArray();
				switch (tb.ty)
				{
					case TY.Tsarray:
					case TY.Tarray:
					{	// Create a static array variable v of type arg.type
version (IN_GCC) {
						/* GCC 4.0 does not like zero length arrays used like
						   this; pass a null array value instead. Could also
						   just make a one-element array. */
						if (nargs - i == 0)
						{
							arg = new NullExp(loc);
							break;
						}
}
						Identifier id = Lexer.uniqueId("__arrayArg");
						Type t = new TypeSArray((cast(TypeArray)tb).next, new IntegerExp(nargs - i));
						t = t.semantic(loc, sc);
						VarDeclaration v = new VarDeclaration(loc, t, id, new VoidInitializer(loc));
			            v.storage_class |= STCctfe;
						v.semantic(sc);
						v.parent = sc.parent;
						//sc.insert(v);

						Expression c = new DeclarationExp(Loc(0), v);
						c.type = v.type;

						for (size_t u = i; u < nargs; u++)
						{   
							auto a = arguments[u];
							if (tret && !(cast(TypeArray)tb).next.equals(a.type))
								a = a.toDelegate(sc, tret);

							Expression e = new VarExp(loc, v);
							e = new IndexExp(loc, e, new IntegerExp(u + 1 - nparams));
							auto ae = new AssignExp(loc, e, a);

			version (DMDV2) {
							ae.op = TOK.TOKconstruct;
			}

							if (c)
								c = new CommaExp(loc, c, ae);
							else
								c = ae;
						}

						arg = new VarExp(loc, v);
						if (c)
							arg = new CommaExp(loc, c, arg);
						break;
					}

					case TY.Tclass:
					{	/* Set arg to be:
						 *	new Tclass(arg0, arg1, ..., argn)
						 */
						Expressions args = new Expressions();
						args.setDim(nargs - i);
						for (size_t u = i; u < nargs; u++)
							args[u - i] = arguments[u];
						arg = new NewExp(loc, null, null, p.type, args);
						break;
					}

					default:
						if (!arg)
						{   
							error(loc, "not enough arguments");
							return tf.next;
						}
						break;
				}

				arg = arg.semantic(sc);
				//printf("\targ = '%s'\n", arg.toChars());
				arguments.setDim(i + 1);
				done = 1;
			}

		L1:
			if (!(p.storageClass & STC.STClazy && p.type.ty == TY.Tvoid))
			{
				if (p.type != arg.type)
				{
					//printf("arg.type = %s, p.type = %s\n", arg.type.toChars(), p.type.toChars());
					if (arg.op == TOKtype)
						arg.error("cannot pass type %s as function argument", arg.toChars());
		            if (p.type.isWild() && tf.next.isWild())
		            {	
                        Type t = p.type;
			            MATCH m = arg.implicitConvTo(t);
			            if (m == MATCH.MATCHnomatch)
			            {
                            t = t.constOf();
			                m = arg.implicitConvTo(t);
			                if (m == MATCHnomatch)
			                {
                                t = t.sharedConstOf();
				                m = arg.implicitConvTo(t);
			                }
			                wildmatch |= p.type.wildMatch(arg.type);
			            }
			            arg = arg.implicitCastTo(sc, t);
		            }
		            else
    					arg = arg.implicitCastTo(sc, p.type);
					arg = arg.optimize(WANT.WANTvalue);
				}
			}
			if (p.storageClass & STC.STCref)
			{
				arg = arg.toLvalue(sc, arg);
			}
			else if (p.storageClass & STC.STCout)
			{
				arg = arg.modifiableLvalue(sc, arg);
			}

			tb = arg.type.toBasetype();
version(SARRAYVALUE) {} else
{
			// Convert static arrays to pointers
			if (tb.ty == TY.Tsarray)
			{
				arg = arg.checkToPointer();
			}
}
version (DMDV2) {
			if (tb.ty == TY.Tstruct && !(p.storageClass & (STC.STCref | STC.STCout)))
			{
				arg = callCpCtor(loc, sc, arg);
			}
}

			// Convert lazy argument to a delegate
			if (p.storageClass & STC.STClazy)
			{
				arg = arg.toDelegate(sc, p.type);
			}
version (DMDV2) {
			/* Look for arguments that cannot 'escape' from the called
			 * function.
			 */
			if (!tf.parameterEscapes(p))
			{
				/* Function literals can only appear once, so if this
				 * appearance was scoped, there cannot be any others.
				 */
				if (arg.op == TOK.TOKfunction)
				{   
					FuncExp fe = cast(FuncExp)arg;
					fe.fd.tookAddressOf = 0;
				}

				/* For passing a delegate to a scoped parameter,
				 * this doesn't count as taking the address of it.
				 * We only worry about 'escaping' references to the function.
				 */
				else if (arg.op == TOK.TOKdelegate)
				{   
					DelegateExp de = cast(DelegateExp)arg;
					if (de.e1.op == TOK.TOKvar)
					{	
						VarExp ve = cast(VarExp)de.e1;
						FuncDeclaration f = ve.var.isFuncDeclaration();
						if (f)
						{   
							f.tookAddressOf--;
							//printf("tookAddressOf = %d\n", f.tookAddressOf);
						}
					}
				}
			}
}
		}
		else
		{
			// If not D linkage, do promotions
			if (tf.linkage != LINK.LINKd)
			{
				// Promote bytes, words, etc., to ints
				arg = arg.integralPromotions(sc);

				// Promote floats to doubles
				switch (arg.type.ty)
				{
					case TY.Tfloat32:
						arg = arg.castTo(sc, Type.tfloat64);
						break;

					case TY.Timaginary32:
						arg = arg.castTo(sc, Type.timaginary64);
						break;
					default:
						break;
				}
			}

			// Convert static arrays to dynamic arrays
			tb = arg.type.toBasetype();
			if (tb.ty == TY.Tsarray)
			{	
				TypeSArray ts = cast(TypeSArray)tb;
				Type ta = ts.next.arrayOf();
				if (ts.size(arg.loc) == 0)
					arg = new NullExp(arg.loc, ta);
				else
					arg = arg.castTo(sc, ta);
			}
version (DMDV2) {
			if (tb.ty == Tstruct)
			{
				arg = callCpCtor(loc, sc, arg);
			}
}

	    // Give error for overloaded function addresses
	    if (arg.op == TOKsymoff)
	    {	
			SymOffExp se = cast(SymOffExp)arg;
version (DMDV2) {
			bool aux = (se.hasOverloads != 0);
} else {
			bool aux = true;
}
		if (aux && !se.var.isFuncDeclaration().isUnique())
		    arg.error("function %s is overloaded", arg.toChars());
	    }

	    arg.rvalue();
	}

		arg = arg.optimize(WANT.WANTvalue);
		arguments[i] = arg;
		if (done)
			break;
    }

    // If D linkage and variadic, add _arguments[] as first argument
    if (tf.linkage == LINK.LINKd && tf.varargs == 1)
    {
		assert(arguments.dim >= nparams);
		auto e = createTypeInfoArray(sc, &arguments[nparams], arguments.dim - nparams);
		arguments.insert(0, e);
    }
    
    Type tret = tf.next;
    if (wildmatch)
    {	/* Adjust function return type based on wildmatch
	 */
	    //printf("wildmatch = x%x\n", wildmatch);
	    assert(tret.isWild());
	    if (wildmatch & MOD.MODconst || wildmatch & (wildmatch - 1))
	        tret = tret.constOf();
	    else if (wildmatch & MOD.MODimmutable)
	        tret = tret.invariantOf();
	    else
	    {
            assert(wildmatch & MOD.MODmutable);
	        tret = tret.mutableOf();
	    }
    }
    return tret;
}

/******************************
 * Perform canThrow() on an array of Expressions.
 */

version (DMDV2) {
bool arrayExpressionCanThrow(Expressions exps)
{
    if (exps)
    {
	foreach (e; exps)
	{
	    if (e && e.canThrow())
		return true;
	}
    }
    return false;
}
}

/****************************************
 * Expand tuples.
 */

void expandTuples(Expressions exps)
{
    //printf("expandTuples()\n");
    if (exps)
    {
		for (size_t i = 0; i < exps.dim; i++)
		{   
			auto arg = exps[i];
			if (!arg)
				continue;

			// Look for tuple with 0 members
			if (arg.op == TOK.TOKtype)
			{
				auto e = cast(TypeExp)arg;
				if (e.type.toBasetype().ty == TY.Ttuple)
				{   
					auto tt = cast(TypeTuple)e.type.toBasetype();

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
			while (arg.op == TOK.TOKtuple)
			{	
				auto te = cast(TupleExp)arg;

				exps.remove(i);		// remove arg
				exps.insert(i, te.exps);	// replace with tuple contents

				if (i == exps.dim)
					return;		// empty tuple, no more arguments

				arg = exps[i];
			}
		}
    }
}

/**************************************************
 * Write out argument types to buf.
 */

void argExpTypesToCBuffer(OutBuffer buf, Expressions arguments, HdrGenState* hgs)
{
    if (arguments)
    {	
		scope OutBuffer argbuf = new OutBuffer();

		foreach (size_t i, Expression arg; arguments)
		{   
			if (i)
				buf.writeByte(',');

			argbuf.reset();
			arg.type.toCBuffer2(argbuf, hgs, MOD.MODundefined);
			buf.write(argbuf);
		}
    }
}

/****************************************
 * Determine if scope sc has package level access to s.
 */

bool hasPackageAccess(Scope sc, Dsymbol s)
{
version (LOG) {
    printf("hasPackageAccess(s = '%s', sc = '%p')\n", s.toChars(), sc);
}

    for (; s; s = s.parent)
    {
		if (s.isPackage() && !s.isModule())
			break;
    }
version (LOG) {
    if (s)
		printf("\tthis is in package '%s'\n", s.toChars());
}

    if (s && s == sc.module_.parent)
    {
version (LOG) {
		printf("\ts is in same package as sc\n");
}
		return true;
    }


version (LOG) {
    printf("\tno package access\n");
}

    return false;
}

/*********************************************
 * Call copy constructor for struct value argument.
 */
version (DMDV2) {
	Expression callCpCtor(Loc loc, Scope sc, Expression e)
	{
		Type tb = e.type.toBasetype();
		assert(tb.ty == Tstruct);
		StructDeclaration sd = (cast(TypeStruct)tb).sym;
		if (sd.cpctor)
		{
			/* Create a variable tmp, and replace the argument e with:
			 *	(tmp = e),tmp
			 * and let AssignExp() handle the construction.
			 * This is not the most efficent, ideally tmp would be constructed
			 * directly onto the stack.
			 */
			Identifier idtmp = Lexer.uniqueId("__tmp");
			VarDeclaration tmp = new VarDeclaration(loc, tb, idtmp, new ExpInitializer(Loc(0), e));
			tmp.storage_class |= STCctfe;
			Expression ae = new DeclarationExp(loc, tmp);
			e = new CommaExp(loc, ae, new VarExp(loc, tmp));
			e = e.semantic(sc);
		}
		return e;
	}
}

/***************************************
 * Create a static array of TypeInfo references
 * corresponding to an array of Expression's.
 * Used to supply hidden _arguments[] value for variadic D functions.
 */

Expression createTypeInfoArray(Scope sc, Expression* exps, int dim)
{
static if (true)
{
	/* Get the corresponding TypeInfo_Tuple and
	 * point at its elements[].
	 */

	/* Create the TypeTuple corresponding to the types of args[]
	 */
	auto args = new Parameters;
	args.setDim(dim);
	for (size_t i = 0; i < dim; i++)
	{	
		auto arg = new Parameter(STCin, exps[i].type, null, null);
		args[i] = arg;
	}
	TypeTuple tup = new TypeTuple(args);
	Expression e = tup.getTypeInfo(sc);
	e = e.optimize(WANTvalue);
	assert(e.op == TOKsymoff);		// should be SymOffExp

version (BREAKABI)
{
	/*
	 * Should just pass a reference to TypeInfo_Tuple instead,
	 * but that would require existing code to be recompiled.
	 * Source compatibility can be maintained by computing _arguments[]
	 * at the start of the called function by offseting into the
	 * TypeInfo_Tuple reference.
	 */

}
else
{
	// Advance to elements[] member of TypeInfo_Tuple
	SymOffExp se = cast(SymOffExp)e;
	se.offset += PTRSIZE + PTRSIZE;

	// Set type to TypeInfo[]*
	se.type = Type.typeinfo.type.arrayOf().pointerTo();

	// Indirect to get the _arguments[] value
	e = new PtrExp(Loc(0), se);
	e.type = se.type.next;
}
	return e;
} // of static if (true)
else
{
	/* Improvements:
	 * 1) create an array literal instead,
	 * as it would eliminate the extra dereference of loading the
	 * static variable.
	 */

	ArrayInitializer ai = new ArrayInitializer(Loc(0));
	VarDeclaration v;
	Type t;
	Expression e;
	scope OutBuffer buf = new OutBuffer();
	Identifier id;
	string name;

	// Generate identifier for _arguments[]
	buf.writestring("_arguments_");
	for (int i = 0; i < dim; i++)
	{	
		t = exps[i].type;
		t.toDecoBuffer(buf);
	}
	buf.writeByte(0);
	id = Lexer.idPool(buf.extractString());

	Module m = sc.module_;
	Dsymbol s = m.symtab.lookup(id);

	if (s && s.parent == m)
	{	
		// Use existing one
		v = s.isVarDeclaration();
		assert(v);
	}
	else
	{	
		// Generate new one

		for (int i = 0; i < dim; i++)
		{   
			t = exps[i].type;
			e = t.getTypeInfo(sc);
			ai.addInit(new IntegerExp(i), new ExpInitializer(0, e));
		}

		t = Type.typeinfo.type.arrayOf();
		ai.type = t;
		v = new VarDeclaration(0, t, id, ai);
		m.members.push(v);
		m.symtabInsert(v);
		sc = sc.push();
		sc.linkage = LINKc;
		sc.stc = STCstatic | STCcomdat;
		ai.semantic(sc, t);
		v.semantic(sc);
		v.parent = m;
		sc = sc.pop();
	}
	e = new VarExp(0, v);
	e = e.semantic(sc);
	return e;
}
}

/**************************************
 * Evaluate builtin function.
 * Return result: null if cannot evaluate it.
 */

extern(C) extern real sinl(real);
extern(C) extern real cosl(real);
extern(C) extern real tanl(real);
extern(C) extern real sqrtl(real);
extern(C) extern real fabsl(real);
 
Expression eval_builtin(BUILTIN builtin, Expressions arguments)
{
	assert(arguments && arguments.dim);
    auto arg0 = arguments[0];
    Expression e = null;
    switch (builtin)
    {
	case BUILTINsin:
	    if (arg0.op == TOKfloat64)
		e = new RealExp(Loc(0), sinl(arg0.toReal()), arg0.type);
	    break;

	case BUILTINcos:
	    if (arg0.op == TOKfloat64)
		e = new RealExp(Loc(0), cosl(arg0.toReal()), arg0.type);
	    break;

	case BUILTINtan:
	    if (arg0.op == TOKfloat64)
		e = new RealExp(Loc(0), tanl(arg0.toReal()), arg0.type);
	    break;

	case BUILTINsqrt:
	    if (arg0.op == TOKfloat64)
		e = new RealExp(Loc(0), sqrtl(arg0.toReal()), arg0.type);
	    break;

	case BUILTINfabs:
	    if (arg0.op == TOKfloat64)
		e = new RealExp(Loc(0), fabsl(arg0.toReal()), arg0.type);
	    break;
		
	default:
		assert(false);
    }
    return e;
}

Expression fromConstInitializer(int result, Expression e1)
{
    //printf("fromConstInitializer(result = %x, %s)\n", result, e1.toChars());
    //static int xx; if (xx++ == 10) assert(0);
    Expression e = e1;
    if (e1.op == TOK.TOKvar)
    {	
		VarExp ve = cast(VarExp)e1;
		VarDeclaration v = ve.var.isVarDeclaration();
		e = expandVar(result, v);
		if (e)
		{   
			if (e.type != e1.type)
			{   
				// Type 'paint' operation
				e = e.copy();
				e.type = e1.type;
			}
			e.loc = e1.loc;
		}
		else
		{
			e = e1;
		}
    }
    return e;
}

/*************************************
 * If variable has a const initializer,
 * return that initializer.
 */

Expression expandVar(int result, VarDeclaration v)
{
	//printf("expandVar(result = %d, v = %p, %s)\n", result, v, v ? v.toChars() : "null");

    Expression e = null;
    if (!v)
		return e;

    if (v.isConst() || v.isImmutable() || v.storage_class & STC.STCmanifest)
    {
		if (!v.type)
		{
			//error("ICE");
			return e;
		}

		Type tb = v.type.toBasetype();
		if (result & WANT.WANTinterpret || v.storage_class & STC.STCmanifest || (tb.ty != TY.Tsarray && tb.ty != TY.Tstruct))
		{
			if (v.init)
			{
				if (v.inuse)
				{   
					if (v.storage_class & STC.STCmanifest)
						v.error("recursive initialization of constant");
					goto L1;
				}
				Expression ei = v.init.toExpression();
				if (!ei)
					goto L1;
				if (ei.op == TOK.TOKconstruct || ei.op == TOK.TOKblit)
				{   
					AssignExp ae = cast(AssignExp)ei;
					ei = ae.e2;
					if (ei.isConst() != 1 && ei.op != TOK.TOKstring)
						goto L1;
					if (ei.type != v.type)
						goto L1;
				}
				if (v.scope_)
				{
					v.inuse++;
					e = ei.syntaxCopy();
					e = e.semantic(v.scope_);
					e = e.implicitCastTo(v.scope_, v.type);
					// enabling this line causes test22 in test suite to fail
					//ei.type = e.type;
					v.scope_ = null;
					v.inuse--;
				}
				else if (!ei.type)
				{
					goto L1;
				}
				else
					// Should remove the copy() operation by
					// making all mods to expressions copy-on-write
					e = ei.copy();
			}
			else
			{
static if (true) {
			goto L1;
} else {
			// BUG: what if const is initialized in constructor?
			e = v.type.defaultInit();
			e.loc = e1.loc;
}
			}
			if (e.type != v.type)
			{
				e = e.castTo(null, v.type);
			}
			v.inuse++;
			e = e.optimize(result);
			v.inuse--;
		}
    }
L1:
    //if (e) printf("\te = %s, e.type = %s\n", e.toChars(), e.type.toChars());
    return e;
}

/****************************************
 * Check access to d for expression e.d
 */

void accessCheck(Loc loc, Scope sc, Expression e, Declaration d)
{
version (LOG) {
    if (e)
    {	
		printf("accessCheck(%s . %s)\n", e.toChars(), d.toChars());
		printf("\te.type = %s\n", e.type.toChars());
    }
    else
    {
		//printf("accessCheck(%s)\n", d.toChars());
    }
}
    if (!e)
    {
		if (d.prot() == PROT.PROTprivate && d.getModule() != sc.module_ ||
			d.prot() == PROT.PROTpackage && !hasPackageAccess(sc, d))

			error(loc, "%s %s.%s is not accessible from %s",
			d.kind(), d.getModule().toChars(), d.toChars(), sc.module_.toChars());
    }
    else if (e.type.ty == TY.Tclass)
    {   
		// Do access check
		ClassDeclaration cd;

		cd = cast(ClassDeclaration)((cast(TypeClass)e.type).sym);
static if (true) {
		if (e.op == TOK.TOKsuper)
		{   
			ClassDeclaration cd2 = sc.func.toParent().isClassDeclaration();
			if (cd2)
				cd = cd2;
		}
}
		cd.accessCheck(loc, sc, d);
    }
    else if (e.type.ty == TY.Tstruct)
    {   
		// Do access check
		StructDeclaration cd = cast(StructDeclaration)((cast(TypeStruct)e.type).sym);
		cd.accessCheck(loc, sc, d);
    }
}

/*****************************************
 * Given array of arguments and an aggregate type,
 * if any of the argument types are missing, attempt to infer
 * them from the aggregate type.
 */

void inferApplyArgTypes(TOK op, Parameters arguments, Expression aggr)
{
    if (!arguments || !arguments.dim)
		return;

    /* Return if no arguments need types.
     */
    for (size_t u = 0; 1; u++)
    {	
		if (u == arguments.dim)
			return;

		auto arg = arguments[u];
		if (!arg.type)
			break;
    }

    Dsymbol s;
    AggregateDeclaration ad;

    auto arg = arguments[0];
    Type taggr = aggr.type;
    if (!taggr)
		return;
    Type tab = taggr.toBasetype();
    switch (tab.ty)
    {
		case TY.Tarray:
		case TY.Tsarray:
		case TY.Ttuple:
			if (arguments.dim == 2)
			{
				if (!arg.type)
					arg.type = Type.tsize_t;	// key type
				arg = arguments[1];
			}
			if (!arg.type && tab.ty != TY.Ttuple)
				arg.type = tab.nextOf();	// value type
			break;

		case TY.Taarray:
		{   
			auto taa = cast(TypeAArray)tab;

			if (arguments.dim == 2)
			{
				if (!arg.type)
					arg.type = taa.index;	// key type
				arg = arguments[1];
			}
			if (!arg.type)
				arg.type = taa.next;		// value type
			break;
		}

		case TY.Tclass:
			ad = (cast(TypeClass)tab).sym;
			goto Laggr;

		case TY.Tstruct:
			ad = (cast(TypeStruct)tab).sym;
			goto Laggr;

		Laggr:
	        s = search_function(ad, (op == TOKforeach_reverse) ? Id.applyReverse : Id.apply);
	        if (s)
		        goto Lapply;			// prefer opApply

			if (arguments.dim == 1)
			{
				if (!arg.type)
				{
					/* Look for a head() or rear() overload
					 */
					Identifier id = (op == TOK.TOKforeach) ? Id.Fhead : Id.Ftoe;
					Dsymbol s1 = search_function(ad, id);
					FuncDeclaration fd = s1 ? s1.isFuncDeclaration() : null;
					if (!fd)
					{	
						if (s1 && s1.isTemplateDeclaration())
							break;
						goto Lapply;
					}
					arg.type = fd.type.nextOf();
				}
				break;
			}

		Lapply:
		{   /* Look for an
			 *	int opApply(int delegate(ref Type [, ...]) dg);
			 * overload
			 */
			if (s)
			{
				FuncDeclaration fd = s.isFuncDeclaration();
				if (fd) 
				{   
					inferApplyArgTypesX(fd, arguments);
					break;
				}
static if (false) {
				TemplateDeclaration td = s.isTemplateDeclaration();
				if (td)
				{   
					inferApplyArgTypesZ(td, arguments);
					break;
				}
}
			}
			break;
		}

		case TY.Tdelegate:
		{
			if (0 && aggr.op == TOK.TOKdelegate)
			{	
				DelegateExp de = cast(DelegateExp)aggr;

				FuncDeclaration fd = de.func.isFuncDeclaration();
				if (fd)
					inferApplyArgTypesX(fd, arguments);
				}
			else
			{
				inferApplyArgTypesY(cast(TypeFunction)tab.nextOf(), arguments);
			}
			break;
		}

		default:
			break;		// ignore error, caught later
    }
}

struct Param3
{
	/********************************
	 * Recursive helper function,
	 * analogous to func.overloadResolveX().
	 */

	bool visit(FuncDeclaration f)
	{
		Parameters arguments = this.arguments;
		TypeFunction tf = cast(TypeFunction)f.type;
		if (inferApplyArgTypesY(tf, arguments))
			return false;
		if (arguments.dim == 0)
			return true;
		return false;
	}
	
	Parameters arguments;
}

void inferApplyArgTypesX(FuncDeclaration fstart, Parameters arguments)
{
	Param3 p3;
	p3.arguments = arguments;
    overloadApply(fstart, p3);
}

/******************************
 * Infer arguments from type of function.
 * Returns:
 *	0 match for this function
 *	1 no match for this function
 */

bool inferApplyArgTypesY(TypeFunction tf, Parameters arguments)
{   
	size_t nparams;
    Parameter p;

    if (Parameter.dim(tf.parameters) != 1)
		goto Lnomatch;

    p = Parameter.getNth(tf.parameters, 0);
    if (p.type.ty != TY.Tdelegate)
		goto Lnomatch;

    tf = cast(TypeFunction)p.type.nextOf();
    assert(tf.ty == TY.Tfunction);

    /* We now have tf, the type of the delegate. Match it against
     * the arguments, filling in missing argument types.
     */
    nparams = Parameter.dim(tf.parameters);
    if (nparams == 0 || tf.varargs)
		goto Lnomatch;		// not enough parameters
    if (arguments.dim != nparams)
		goto Lnomatch;		// not enough parameters

    for (size_t u = 0; u < nparams; u++)
    {
		auto arg = arguments[u];
		auto param = Parameter.getNth(tf.parameters, u);
		if (arg.type)
		{   
			if (!arg.type.equals(param.type))
			{
				/* Cannot resolve argument types. Indicate an
				 * error by setting the number of arguments to 0.
				 */
				arguments.dim = 0;
				goto Lmatch;
			}
			continue;
		}
		arg.type = param.type;
    }

  Lmatch:
    return false;

  Lnomatch:
    return true;
}

/**************************************************
 * Write expression out to buf, but wrap it
 * in ( ) if its precedence is less than pr.
 */

void expToCBuffer(OutBuffer buf, HdrGenState* hgs, Expression e, PREC pr)
{
    //if (precedence[e.op] == 0) e.dump(0);
    if (precedence[e.op] < pr ||
	/* Despite precedence, we don't allow a<b<c expressions.
	 * They must be parenthesized.
	 */
	(pr == PREC.PREC_rel && precedence[e.op] == pr))
    {
		buf.writeByte('(');
		e.toCBuffer(buf, hgs);
		buf.writeByte(')');
    }
    else
		e.toCBuffer(buf, hgs);
}

/**************************************************
 * Write out argument list to buf.
 */

void argsToCBuffer(OutBuffer buf, Expressions arguments, HdrGenState* hgs)
{
    if (arguments)
    {
		foreach (size_t i, Expression arg; arguments)
		{   
			if (arg)
			{	
				if (i)
					buf.writeByte(',');
				expToCBuffer(buf, hgs, arg, PREC.PREC_assign);
			}
		}
    }
}

ulong getMask(ulong v)
{
    ulong u = 0;
    if (v >= 0x80)
		u = 0xFF;
    while (u < v)
		u = (u << 1) | 1;
    return u;
}

/******************************
 * Perform scanForNestedRef() on an array of Expressions.
 */

void arrayExpressionScanForNestedRef(Scope sc, Expressions a)
{
    //printf("arrayExpressionScanForNestedRef(%p)\n", a);
    if (a)
    {
		foreach (e; a)
		{   
			if (e)
			{
				e.scanForNestedRef(sc);
			}
		}
    }
}

void realToMangleBuffer(OutBuffer buf, real value)
{
    /* Rely on %A to get portable mangling.
     * Must munge result to get only identifier characters.
     *
     * Possible values from %A	=> mangled result
     * NAN			=> NAN
     * -INF			=> NINF
     * INF			=> INF
     * -0X1.1BC18BA997B95P+79	=> N11BC18BA997B95P79
     * 0X1.9P+2			=> 19P2
     */

    if (isnan(value))
		buf.writestring("NAN");	// no -NAN bugs
    else
    {
		char[32] buffer;
		int n = sprintf(buffer.ptr, "%LA", value);
		assert(n > 0 && n < buffer.sizeof);
		for (int i = 0; i < n; i++)
		{   char c = buffer[i];

			switch (c)
			{
			case '-':
				buf.writeByte('N');
				break;

			case '+':
			case 'X':
			case '.':
				break;

			case '0':
				if (i < 2)
				break;		// skip leading 0X
			default:
				buf.writeByte(c);
				break;
			}
		}
    }
}

/********************************
 * Test to see if two reals are the same.
 * Regard NaN's as equivalent.
 * Regard +0 and -0 as different.
 */

int RealEquals(real x1, real x2)
{
    return (isnan(x1) && isnan(x2)) || 
		/* In some cases, the REALPAD bytes get garbage in them,
		 * so be sure and ignore them.
		 */
		memcmp(&x1, &x2, REALSIZE - REALPAD) == 0;
}

void floatToBuffer(OutBuffer buf, Type type, real value)
{
    /* In order to get an exact representation, try converting it
     * to decimal then back again. If it matches, use it.
     * If it doesn't, fall back to hex, which is
     * always exact.
     */
    char[25] buffer;
    sprintf(buffer.ptr, "%Lg", value);
    assert(strlen(buffer.ptr) < buffer.length);
//#ifdef _WIN32 && __DMC__
//    char *save = __locale_decpoint;
//    __locale_decpoint = ".";
//    real_t r = strtold(buffer, NULL);
//    __locale_decpoint = save;
//#else
    real r = strtold(buffer.ptr, null);
//#endif
    if (r == value)			// if exact duplication
	    buf.writestring(buffer);
    else
	    buf.printf("%s", value);	// ensure exact duplication /// !

    if (type)
    {
	Type t = type.toBasetype();
	switch (t.ty)
	{
	    case Tfloat32:
	    case Timaginary32:
	    case Tcomplex32:
		buf.writeByte('F');
		break;

	    case Tfloat80:
	    case Timaginary80:
	    case Tcomplex80:
		buf.writeByte('L');
		break;

	    default:
		break;
	}
	if (t.isimaginary())
	    buf.writeByte('i');
    }
}

Expression opAssignToOp(Loc loc, TOK op, Expression e1, Expression e2)
{   
	Expression e;

    switch (op)
    {
		case TOK.TOKaddass:   e = new AddExp(loc, e1, e2);	break;
		case TOK.TOKminass:   e = new MinExp(loc, e1, e2);	break;
		case TOK.TOKmulass:   e = new MulExp(loc, e1, e2);	break;
		case TOK.TOKdivass:   e = new DivExp(loc, e1, e2);	break;
		case TOK.TOKmodass:   e = new ModExp(loc, e1, e2);	break;
		case TOK.TOKandass:   e = new AndExp(loc, e1, e2);	break;
		case TOK.TOKorass:    e = new OrExp (loc, e1, e2);	break;
		case TOK.TOKxorass:   e = new XorExp(loc, e1, e2);	break;
		case TOK.TOKshlass:   e = new ShlExp(loc, e1, e2);	break;
		case TOK.TOKshrass:   e = new ShrExp(loc, e1, e2);	break;
		case TOK.TOKushrass:  e = new UshrExp(loc, e1, e2);	break;
		default:	assert(0);
    }
    return e;
}