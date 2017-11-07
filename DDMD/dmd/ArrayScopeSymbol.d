module dmd.ArrayScopeSymbol;

import dmd.common;
import dmd.ScopeDsymbol;
import dmd.Expression;
import dmd.TypeTuple;
import dmd.TupleDeclaration;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.Loc;
import dmd.TOK;
import dmd.Identifier;
import dmd.Id;
import dmd.TY;
import dmd.TupleExp;
import dmd.StringExp;
import dmd.WANT;
import dmd.TypeExp;
import dmd.Type;
import dmd.SliceExp;
import dmd.IndexExp;
import dmd.IntegerExp;
import dmd.STC;
import dmd.ExpInitializer;
import dmd.VarDeclaration;
import dmd.ArrayLiteralExp;
import dmd.expression.Util;

import dmd.DDMDExtensions;

class ArrayScopeSymbol : ScopeDsymbol
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;	// IndexExp or SliceExp
    TypeTuple type;	// for tuple[length]
    TupleDeclaration td;	// for tuples of objects
    Scope sc;

    this(Scope sc, Expression e)
	{
		register();
		super();
		assert(e.op == TOKindex || e.op == TOKslice);
		this.exp = e;
		this.sc = sc;
	}
	
    this(Scope sc, TypeTuple t)
	{
		register();
		exp = null;
		type = t;
		td = null;
		this.sc = sc;
	}
	
    this(Scope sc, TupleDeclaration s)
	{
		register();

		exp = null;
		type = null;
		td = s;
		this.sc = sc;
	}
	
    override Dsymbol search(Loc loc, Identifier ident, int flags)
	{
		//printf("ArrayScopeSymbol.search('%s', flags = %d)\n", ident.toChars(), flags);
		if (ident == Id.length || ident == Id.dollar)
		{
			VarDeclaration* pvar;
			Expression ce;

		L1:
			if (td)
			{   /* $ gives the number of elements in the tuple
				 */
				VarDeclaration v = new VarDeclaration(loc, Type.tsize_t, Id.dollar, null);
				Expression e = new IntegerExp(Loc(0), td.objects.dim, Type.tsize_t);
				v.init = new ExpInitializer(Loc(0), e);
				v.storage_class |= STCstatic | STCconst;
				v.semantic(sc);
				return v;
			}

			if (type)
			{   /* $ gives the number of type entries in the type tuple
				 */
				VarDeclaration v = new VarDeclaration(loc, Type.tsize_t, Id.dollar, null);
				Expression e = new IntegerExp(Loc(0), type.arguments.dim, Type.tsize_t);
				v.init = new ExpInitializer(Loc(0), e);
				v.storage_class |= STCstatic | STCconst;
				v.semantic(sc);
				return v;
			}

			if (exp.op == TOKindex)
			{   /* array[index] where index is some function of $
				 */
				IndexExp ie = cast(IndexExp)exp;

				pvar = &ie.lengthVar;
				ce = ie.e1;
			}
			else if (exp.op == TOKslice)
			{   /* array[lwr .. upr] where lwr or upr is some function of $
				 */
				SliceExp se = cast(SliceExp)exp;

				pvar = &se.lengthVar;
				ce = se.e1;
			}
			else
				/* Didn't find $, look in enclosing scope(s).
				 */
				return null;

			/* If we are indexing into an array that is really a type
			 * tuple, rewrite this as an index into a type tuple and
			 * try again.
			 */
			if (ce.op == TOKtype)
			{
				Type t = (cast(TypeExp)ce).type;
				if (t.ty == Ttuple)
				{	
					type = cast(TypeTuple)t;
					goto L1;
				}
			}

			/* *pvar is lazily initialized, so if we refer to $
			 * multiple times, it gets set only once.
			 */
			if (!*pvar)		// if not already initialized
			{   /* Create variable v and set it to the value of $,
				 * which will be a constant.
				 */
				VarDeclaration v = new VarDeclaration(loc, Type.tsize_t, Id.dollar, null);

				if (ce.op == TOKvar)
				{	// if ce is const, get its initializer
					ce = fromConstInitializer(WANTvalue | WANTinterpret, ce);
				}

				if (ce.op == TOKstring)
				{	/* It is for a string literal, so the
					 * length will be a const.
					 */
					Expression e = new IntegerExp(Loc(0), (cast(StringExp)ce).len, Type.tsize_t);
					v.init = new ExpInitializer(Loc(0), e);
					v.storage_class |= STCstatic | STCconst;
				}
				else if (ce.op == TOKarrayliteral)
				{	/* It is for an array literal, so the
					 * length will be a const.
					 */
					Expression e = new IntegerExp(Loc(0), (cast(ArrayLiteralExp)ce).elements.dim, Type.tsize_t);
					v.init = new ExpInitializer(Loc(0), e);
					v.storage_class |= STCstatic | STCconst;
				}
				else if (ce.op == TOKtuple)
				{	/* It is for an expression tuple, so the
					 * length will be a const.
					 */
					Expression e = new IntegerExp(Loc(0), (cast(TupleExp)ce).exps.dim, Type.tsize_t);
					v.init = new ExpInitializer(Loc(0), e);
					v.storage_class |= STCstatic | STCconst;
				}
				*pvar = v;
			}
			(*pvar).semantic(sc);
			return (*pvar);
		}
		return null;
	}

    override ArrayScopeSymbol isArrayScopeSymbol() { return this; }
}
