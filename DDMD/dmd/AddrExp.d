module dmd.AddrExp;

import dmd.common;
import dmd.Expression;
import dmd.UnaExp;
import dmd.MATCH;
import dmd.Type;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.ErrorExp;
import dmd.DotVarExp;
import dmd.FuncDeclaration;
import dmd.DelegateExp;
import dmd.VarExp;
import dmd.VarDeclaration;
import dmd.ThisExp;
import dmd.TOK;
import dmd.WANT;
import dmd.CommaExp;
import dmd.STC;
import dmd.PtrExp;
import dmd.SymOffExp;
import dmd.IndexExp;
import dmd.OverExp;
import dmd.Dsymbol;
import dmd.ScopeDsymbol;
import dmd.TY;
import dmd.TypeSArray;

import dmd.backend.elem;
import dmd.backend.Util;
import dmd.codegen.Util;

import dmd.DDMDExtensions;

class AddrExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		register();
		super(loc, TOK.TOKaddress, AddrExp.sizeof, e);
	}

	override Expression semantic(Scope sc)
	{
	version (LOGSEMANTIC) {
		printf("AddrExp.semantic('%s')\n", toChars());
	}
		if (!type)
		{
			UnaExp.semantic(sc);
			e1 = e1.toLvalue(sc, null);
			if (!e1.type)
			{
				error("cannot take address of %s", e1.toChars());
				return new ErrorExp();
			}
			if (!e1.type.deco)
			{
				/* No deco means semantic() was not run on the type.
				 * We have to run semantic() on the symbol to get the right type:
				 *	auto x = &bar;
				 *	pure: int bar() { return 1;}
				 * otherwise the 'pure' is missing from the type assigned to x.
				 */

				error("forward reference to %s", e1.toChars());
				return new ErrorExp();
			}

			type = e1.type.pointerTo();

			// See if this should really be a delegate
			if (e1.op == TOKdotvar)
			{
				DotVarExp dve = cast(DotVarExp)e1;
				FuncDeclaration f = dve.var.isFuncDeclaration();

				if (f)
				{
					if (!dve.hasOverloads)
						f.tookAddressOf++;
					Expression e = new DelegateExp(loc, dve.e1, f, dve.hasOverloads);
					e = e.semantic(sc);
					return e;
				}
			}
			else if (e1.op == TOKvar)
			{
				VarExp ve = cast(VarExp)e1;

				VarDeclaration v = ve.var.isVarDeclaration();
				if (v && !v.canTakeAddressOf())
					error("cannot take address of %s", e1.toChars());

				FuncDeclaration f = ve.var.isFuncDeclaration();

				if (f)
				{
					if (!ve.hasOverloads ||
						/* Because nested functions cannot be overloaded,
						 * mark here that we took its address because castTo()
						 * may not be called with an exact match.
						 */
						f.toParent2().isFuncDeclaration())
						f.tookAddressOf++;

					if (f.isNested())
					{
						Expression e = new DelegateExp(loc, e1, f, ve.hasOverloads);
						e = e.semantic(sc);
						return e;
					}
					if (f.needThis() && hasThis(sc))
					{
						/* Should probably supply 'this' after overload resolution,
						 * not before.
						 */
						Expression ethis = new ThisExp(loc);
						Expression e = new DelegateExp(loc, ethis, f, ve.hasOverloads);
						e = e.semantic(sc);
						return e;
					}
				}
			}
			return optimize(WANTvalue);
		}
		return this;
	}

    override void checkEscape()
    {
        e1.checkEscapeRef();
    }
    
	override elem* toElem(IRState* irs)
	{
		elem* e;

		//printf("AddrExp.toElem('%s')\n", toChars());

		e = e1.toElem(irs);
		e = addressElem(e, e1.type);
	L2:
		e.Ety = type.totym();
		el_setLoc(e,loc);
		return e;
	}

	override MATCH implicitConvTo(Type t)
	{
	static if (false) {
		printf("AddrExp.implicitConvTo(this=%s, type=%s, t=%s)\n",
		toChars(), type.toChars(), t.toChars());
	}
		MATCH result;

		result = type.implicitConvTo(t);
		//printf("\tresult = %d\n", result);

		if (result == MATCHnomatch)
		{
			// Look for pointers to functions where the functions are overloaded.

			t = t.toBasetype();

			if (e1.op == TOKoverloadset &&
				(t.ty == Tpointer || t.ty == Tdelegate) && t.nextOf().ty == Tfunction)
			{   
				OverExp eo = cast(OverExp)e1;
				FuncDeclaration f = null;
				foreach (s; eo.vars.a)
				{   
					auto f2 = s.isFuncDeclaration();
					assert(f2);
					if (f2.overloadExactMatch(t.nextOf()))
					{   
						if (f)
							/* Error if match in more than one overload set,
							 * even if one is a 'better' match than the other.
							 */
							ScopeDsymbol.multiplyDefined(loc, f, f2);
						else
							f = f2;
						result = MATCHexact;
					}
				}
			}

			if (type.ty == Tpointer && type.nextOf().ty == Tfunction &&
				t.ty == Tpointer && t.nextOf().ty == Tfunction &&
				e1.op == TOKvar)
			{
				/* I don't think this can ever happen -
				 * it should have been
				 * converted to a SymOffExp.
				 */
				assert(0);
				VarExp ve = cast(VarExp)e1;
				FuncDeclaration f = ve.var.isFuncDeclaration();
				if (f && f.overloadExactMatch(t.nextOf()))
					result = MATCHexact;
			}
		}

		//printf("\tresult = %d\n", result);
		return result;
	}

	override Expression castTo(Scope sc, Type t)
	{
	    Type tb;

	static if (false) {
		printf("AddrExp.castTo(this=%s, type=%s, t=%s)\n", toChars(), type.toChars(), t.toChars());
	}
		Expression e = this;

		tb = t.toBasetype();
		type = type.toBasetype();
		if (tb != type)
		{
			// Look for pointers to functions where the functions are overloaded.

			if (e1.op == TOKoverloadset &&
				(t.ty == Tpointer || t.ty == Tdelegate) && t.nextOf().ty == Tfunction)
			{   
				OverExp eo = cast(OverExp)e1;
				FuncDeclaration f = null;
				foreach (s; eo.vars.a)
				{   
					auto f2 = s.isFuncDeclaration();
					assert(f2);
					if (f2.overloadExactMatch(t.nextOf()))
					{   
						if (f)
							/* Error if match in more than one overload set,
							 * even if one is a 'better' match than the other.
							 */
							ScopeDsymbol.multiplyDefined(loc, f, f2);
						else
							f = f2;
					}
				}
				if (f)
				{	
					f.tookAddressOf++;
					SymOffExp se = new SymOffExp(loc, f, 0, 0);
					se.semantic(sc);
					// Let SymOffExp.castTo() do the heavy lifting
					return se.castTo(sc, t);
				}
			}


			if (type.ty == Tpointer && type.nextOf().ty == Tfunction &&
				tb.ty == Tpointer && tb.nextOf().ty == Tfunction &&
				e1.op == TOKvar)
			{
				VarExp ve = cast(VarExp)e1;
				FuncDeclaration f = ve.var.isFuncDeclaration();
				if (f)
				{
					assert(0);	// should be SymOffExp instead
					f = f.overloadExactMatch(tb.nextOf());
					if (f)
					{
						e = new VarExp(loc, f);
						e.type = f.type;
						e = new AddrExp(loc, e);
						e.type = t;
						return e;
					}
				}
			}
			e = Expression.castTo(sc, t);
		}
		e.type = t;
		return e;
	}

	override Expression optimize(int result)
	{
		Expression e;

		//printf("AddrExp.optimize(result = %d) %s\n", result, toChars());

		/* Rewrite &(a,b) as (a,&b)
		 */
		if (e1.op == TOKcomma)
		{	
			CommaExp ce = cast(CommaExp)e1;
			AddrExp ae = new AddrExp(loc, ce.e2);
			ae.type = type;
			e = new CommaExp(ce.loc, ce.e1, ae);
			e.type = type;
			return e.optimize(result);
		}

		if (e1.op == TOKvar)
		{	
			VarExp ve = cast(VarExp)e1;
			if (ve.var.storage_class & STCmanifest)
				e1 = e1.optimize(result);
		}
		else
			e1 = e1.optimize(result);

		// Convert &*ex to ex
		if (e1.op == TOKstar)
		{	
			Expression ex;

			ex = (cast(PtrExp)e1).e1;
			if (type.equals(ex.type))
				e = ex;
			else
			{
				e = ex.copy();
				e.type = type;
			}
			return e;
		}
		if (e1.op == TOKvar)
		{	
			VarExp ve = cast(VarExp)e1;
			if (!ve.var.isOut() && !ve.var.isRef() &&
				!ve.var.isImportedSymbol())
			{
				SymOffExp se = new SymOffExp(loc, ve.var, 0, ve.hasOverloads);
				se.type = type;
				return se;
			}
		}
		if (e1.op == TOKindex)
		{	
			// Convert &array[n] to &array+n
			IndexExp ae = cast(IndexExp)e1;

			if (ae.e2.op == TOKint64 && ae.e1.op == TOKvar)
			{
				long index = ae.e2.toInteger();
				VarExp ve = cast(VarExp)ae.e1;
				if (ve.type.ty == Tsarray
					&& !ve.var.isImportedSymbol())
				{
					TypeSArray ts = cast(TypeSArray)ve.type;
					long dim = ts.dim.toInteger();
					if (index < 0 || index >= dim)
						error("array index %jd is out of bounds [0..%jd]", index, dim);
					e = new SymOffExp(loc, ve.var, cast(uint)(index * ts.nextOf().size()));
					e.type = type;
					return e;
				}
			}
		}
		return this;
	}
}

