module dmd.TypeSlice;

import dmd.common;
import dmd.Type;
import dmd.TypeNext;
import dmd.MOD;
import dmd.Expression;
import dmd.Loc;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.TY;
import dmd.TypeTuple;
import dmd.WANT;
import dmd.ArrayTypes;
import dmd.Parameter;
import dmd.SliceExp;
import dmd.TupleDeclaration;
import dmd.ScopeDsymbol;
import dmd.ArrayScopeSymbol;

import dmd.type.Util;

import dmd.DDMDExtensions;

class TypeSlice : TypeNext
{
	mixin insertMemberExtension!(typeof(this));

    Expression lwr;
    Expression upr;

    this(Type next, Expression lwr, Expression upr)
	{
		register();
		super(TY.Tslice, next);
		//printf("TypeSlice[%s .. %s]\n", lwr.toChars(), upr.toChars());
		this.lwr = lwr;
		this.upr = upr;
	}
	
    override Type syntaxCopy()
	{
		Type t = new TypeSlice(next.syntaxCopy(), lwr.syntaxCopy(), upr.syntaxCopy());
		t.mod = mod;
		return t;
	}
	
    override Type semantic(Loc loc, Scope sc)
	{
		//printf("TypeSlice.semantic() %s\n", toChars());
		next = next.semantic(loc, sc);
		transitive();
		//printf("next: %s\n", next.toChars());

		Type tbn = next.toBasetype();
		if (tbn.ty != Ttuple)
		{	
			error(loc, "can only slice tuple types, not %s", tbn.toChars());
			return Type.terror;
		}
		TypeTuple tt = cast(TypeTuple)tbn;

		lwr = semanticLength(sc, tbn, lwr);
		lwr = lwr.optimize(WANTvalue);
		ulong i1 = lwr.toUInteger();

		upr = semanticLength(sc, tbn, upr);
		upr = upr.optimize(WANTvalue);
		ulong i2 = upr.toUInteger();

		if (!(i1 <= i2 && i2 <= tt.arguments.dim))
		{	
			error(loc, "slice [%ju..%ju] is out of range of [0..%u]", i1, i2, tt.arguments.dim);
			return Type.terror;
		}

		auto args = new Parameters;
		args.reserve(cast(size_t)(i2 - i1));
		for (size_t i = cast(size_t)i1; i < cast(size_t)i2; i++)
		{	
			auto arg = tt.arguments[i];
			args.push(arg);
		}

		return new TypeTuple(args);
	}
	
    override void resolve(Loc loc, Scope sc, Expression* pe, Type* pt, Dsymbol* ps)
	{
		next.resolve(loc, sc, pe, pt, ps);
		if (*pe)
		{	// It's really a slice expression
			Expression e;
			e = new SliceExp(loc, *pe, lwr, upr);
			*pe = e;
		}
		else if (*ps)
		{	
			Dsymbol s = *ps;
			TupleDeclaration td = s.isTupleDeclaration();
			if (td)
			{
				/* It's a slice of a TupleDeclaration
				 */
				ScopeDsymbol sym = new ArrayScopeSymbol(sc, td);
				sym.parent = sc.scopesym;
				sc = sc.push(sym);

				lwr = lwr.semantic(sc);
				lwr = lwr.optimize(WANTvalue);
				ulong i1 = lwr.toUInteger();

				upr = upr.semantic(sc);
				upr = upr.optimize(WANTvalue);
				ulong i2 = upr.toUInteger();

				sc = sc.pop();

				if (!(i1 <= i2 && i2 <= td.objects.dim))
				{   
					error(loc, "slice [%ju..%ju] is out of range of [0..%u]", i1, i2, td.objects.dim);
					goto Ldefault;
				}

				if (i1 == 0 && i2 == td.objects.dim)
				{
					*ps = td;
					return;
				}

				/* Create a new TupleDeclaration which
				 * is a slice [i1..i2] out of the old one.
				 */
				auto objects = new Objects;
				objects.setDim(cast(uint)(i2 - i1));
				for (size_t i = 0; i < objects.dim; i++)
				{
					objects[i] = td.objects[cast(size_t)i1 + i];
				}

				auto tds = new TupleDeclaration(loc, td.ident, objects);
				*ps = tds;
			}
			else
				goto Ldefault;
		}
		else
		{
Ldefault:
			Type.resolve(loc, sc, pe, pt, ps);
		}
	}
	
    override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		assert(false);
	}
}
