module dmd.TypeSArray;

import dmd.common;
import dmd.TypeArray;
import dmd.TypeInfoStaticArrayDeclaration;
import dmd.TypeAArray;
import dmd.MOD;
import dmd.ArrayExp;
import dmd.Parameter;
import dmd.TypeIdentifier;
import dmd.TemplateParameter;
import dmd.TemplateValueParameter;
import dmd.TypeStruct;
import dmd.TypeTuple;
import dmd.VarExp;
import dmd.IntegerExp;
import dmd.Expression;
import dmd.Type;
import dmd.TupleDeclaration;
import dmd.TOK;
import dmd.Loc;
import dmd.STC;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Identifier;
import dmd.MATCH;
import dmd.TypeDArray;
import dmd.TypePointer;
import dmd.ArrayTypes;
import dmd.WANT;
import dmd.TypeInfoDeclaration;
import dmd.ScopeDsymbol;
import dmd.ArrayScopeSymbol;
import dmd.TY;
import dmd.Util;
import dmd.Id;
import dmd.IndexExp;

import dmd.type.Util;

import dmd.backend.dt_t;
import dmd.backend.TYPE;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.DT;

import dmd.DDMDExtensions;

// Static array, one with a fixed dimension
class TypeSArray : TypeArray
{
	mixin insertMemberExtension!(typeof(this));

    Expression dim;

    this(Type t, Expression dim)
	{
		register();
		super(TY.Tsarray, t);
		//printf("TypeSArray(%s)\n", dim.toChars());
		this.dim = dim;
	}
	
    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		Expression e = dim.syntaxCopy();
		t = new TypeSArray(t, e);
		t.mod = mod;
		return t;
	}

    override ulong size(Loc loc)
	{
		if (!dim)
			return Type.size(loc);

		long sz = dim.toInteger();

		{	
			long n, n2;
			n = next.size();
			n2 = n * sz;
			if (n && (n2 / n) != sz)
				goto Loverflow;

			sz = n2;
		}
		return sz;

	Loverflow:
		error(loc, "index %jd overflow for static array", sz);
		return 1;
	}
	
    override uint alignsize()
	{
		return next.alignsize();
	}

    override Type semantic(Loc loc, Scope sc)
	{
		//printf("TypeSArray.semantic() %s\n", toChars());

		Type t;
		Expression e;
		Dsymbol s;
		next.resolve(loc, sc, &e, &t, &s);
		if (dim && s && s.isTupleDeclaration())
		{	
			TupleDeclaration sd = s.isTupleDeclaration();

			dim = semanticLength(sc, sd, dim);
			dim = dim.optimize(WANT.WANTvalue | WANT.WANTinterpret);
			ulong d = dim.toUInteger();

			if (d >= sd.objects.dim)
			{   error(loc, "tuple index %ju exceeds %u", d, sd.objects.dim);
				return Type.terror;
			}
			///Object o = cast(Object)sd.objects.data[(size_t)d];
			///if (o.dyncast() != DYNCAST_TYPE)
			///{   
			///	error(loc, "%s is not a type", toChars());
			///	return Type.terror;
			///}
			///t = cast(Type)o;
			
			t = cast(Type)sd.objects[cast(size_t)d];
			if (t is null) {
				error(loc, "%s is not a type", toChars());
				return Type.terror;
			}
			return t;
		}

		next = next.semantic(loc,sc);
		transitive();

		Type tbn = next.toBasetype();

		if (dim)
		{	
			long n, n2;

		dim = semanticLength(sc, tbn, dim);

		dim = dim.optimize(WANT.WANTvalue | WANT.WANTinterpret);
		if (sc && sc.parameterSpecialization && dim.op == TOK.TOKvar &&
			(cast(VarExp)dim).var.storage_class & STC.STCtemplateparameter)
		{
			/* It could be a template parameter N which has no value yet:
			 *   template Foo(T : T[N], size_t N);
			 */
			return this;
		}
		long d1 = dim.toInteger();
		dim = dim.castTo(sc, tsize_t);
		dim = dim.optimize(WANT.WANTvalue);
		long d2 = dim.toInteger();

		if (d1 != d2)
			goto Loverflow;

		if (tbn.isintegral() ||
			 tbn.isfloating() ||
			 tbn.ty == TY.Tpointer ||
			 tbn.ty == TY.Tarray ||
			 tbn.ty == TY.Tsarray ||
			 tbn.ty == TY.Taarray ||
			 tbn.ty == TY.Tclass)
		{
			/* Only do this for types that don't need to have semantic()
			 * run on them for the size, since they may be forward referenced.
			 */
			n = tbn.size(loc);
			n2 = n * d2;
			if (cast(int)n2 < 0)
			goto Loverflow;
			if (n2 >= 0x1000000)	// put a 'reasonable' limit on it
			goto Loverflow;
			if (n && n2 / n != d2)
			{
			  Loverflow:
			error(loc, "index %jd overflow for static array", d1);
			dim = new IntegerExp(Loc(0), 1, tsize_t);
			}
		}
		}
		switch (tbn.ty)
		{
			case TY.Ttuple:
			{   // Index the tuple to get the type
				assert(dim);
				auto tt = cast(TypeTuple)tbn;
				ulong d = dim.toUInteger();

				if (d >= tt.arguments.dim)
				{	
					error(loc, "tuple index %ju exceeds %u", d, tt.arguments.dim);
					return Type.terror;
				}
				auto arg = tt.arguments[cast(size_t)d];
				return arg.type;
			}
			case TY.Tstruct:
			{   TypeStruct ts = cast(TypeStruct)tbn;
				if (ts.sym.isnested)
				error(loc, "cannot have array of inner structs %s", ts.toChars());
				break;
			}
			case TY.Tfunction:
			case TY.Tnone:
				error(loc, "can't have array of %s", tbn.toChars());
				tbn = next = tint32;
				break;
			default:		///
				break;
		}
		if (tbn.isauto())
			error(loc, "cannot have array of auto %s", tbn.toChars());
		return merge();
	}

    override void resolve(Loc loc, Scope sc, Expression* pe, Type* pt, Dsymbol* ps)
	{
		//printf("TypeSArray.resolve() %s\n", toChars());
		next.resolve(loc, sc, pe, pt, ps);
		//printf("s = %p, e = %p, t = %p\n", *ps, *pe, *pt);
		if (*pe)
		{	
			// It's really an index expression
			Expression e = new IndexExp(loc, *pe, dim);
			*pe = e;
		}
		else if (*ps)
		{	
			Dsymbol s = *ps;
			TupleDeclaration td = s.isTupleDeclaration();
			if (td)
			{
				ScopeDsymbol sym = new ArrayScopeSymbol(sc, td);
				sym.parent = sc.scopesym;
				sc = sc.push(sym);

				dim = dim.semantic(sc);
				dim = dim.optimize(WANTvalue | WANTinterpret);
				ulong d = dim.toUInteger();

				sc = sc.pop();

				if (d >= td.objects.dim)
				{	
					error(loc, "tuple index %ju exceeds %u", d, td.objects.dim);
					goto Ldefault;
				}
				Object o = td.objects[cast(size_t)d];
				if ((*ps = isDsymbol(o)) !is null)	/// !
				{
					return;
				}
				if ((*pe = isExpression(o)) !is null)	/// !
				{
					return;
				}

				/* Create a new TupleDeclaration which
				 * is a slice [d..d+1] out of the old one.
				 * Do it this way because TemplateInstance.semanticTiargs()
				 * can handle unresolved Objects this way.
				 */
				auto objects = new Objects;
				objects.setDim(1);
				objects[0] = o;

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

    override void toDecoBuffer(OutBuffer buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		if (dim)
			//buf.printf("%ju", dim.toInteger());	///
			buf.printf("%s", dim.toInteger());
		if (next)
			/* Note that static arrays are value types, so
			 * for a parameter, propagate the 0x100 to the next
			 * level, since for T[4][3], any const should apply to the T,
			 * not the [4].
			 */
			next.toDecoBuffer(buf,  (flag & 0x100) ? flag : mod);
	}
	
    override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		next.toCBuffer2(buf, hgs, this.mod);
		buf.printf("[%s]", dim.toChars());
	}
	
    override Expression dotExp(Scope sc, Expression e, Identifier ident)
	{
	version (LOGDOTEXP) {
		printf("TypeSArray.dotExp(e = '%s', ident = '%s')\n", e.toChars(), ident.toChars());
	}
		if (ident == Id.length)
		{
			e = dim;
		}
		else if (ident == Id.ptr)
		{
			e = e.castTo(sc, next.pointerTo());
		}
		else
		{
			e = TypeArray.dotExp(sc, e, ident);
		}
        e = e.semantic(sc);
		return e;
	}
	
    override bool isString()
	{
		TY nty = next.toBasetype().ty;
		return nty == Tchar || nty == Twchar || nty == Tdchar;
	}
	
    override bool isZeroInit(Loc loc)
	{
		return next.isZeroInit(loc);
	}
	
    override uint memalign(uint salign)
	{
		return next.memalign(salign);
	}
	
    override MATCH constConv(Type to)
	{
		if (to.ty == Tsarray)
		{
			TypeSArray tsa = cast(TypeSArray)to;
			if (!dim.equals(tsa.dim))
				return MATCHnomatch;
		}
		return super.constConv(to);
	}
	
    override MATCH implicitConvTo(Type to)
	{
		//printf("TypeSArray.implicitConvTo(to = %s) this = %s\n", to.toChars(), toChars());

		// Allow implicit conversion of static array to pointer or dynamic array
		if (IMPLICIT_ARRAY_TO_PTR && to.ty == Tpointer)
		{
			TypePointer tp = cast(TypePointer)to;

			if (!MODimplicitConv(next.mod, tp.next.mod))
				return MATCHnomatch;

			if (tp.next.ty == Tvoid || next.constConv(tp.next) != MATCHnomatch)
			{
				return MATCHconvert;
			}
			return MATCHnomatch;
		}
		if (to.ty == Tarray)
		{
			int offset = 0;
			TypeDArray ta = cast(TypeDArray)to;

			if (!MODimplicitConv(next.mod, ta.next.mod))
				return MATCHnomatch;

			if (next.equals(ta.next) ||
//				next.implicitConvTo(ta.next) >= MATCHconst ||
                next.constConv(ta.next) != MATCHnomatch ||
				(ta.next.isBaseOf(next, &offset) && offset == 0) ||
				ta.next.ty == Tvoid
			)
				return MATCHconvert;

			return MATCHnomatch;
		}
		if (to.ty == Tsarray)
		{
			if (this == to)
				return MATCHexact;

			TypeSArray tsa = cast(TypeSArray)to;

			if (dim.equals(tsa.dim))
			{
				/* Since static arrays are value types, allow
				 * conversions from const elements to non-const
				 * ones, just like we allow conversion from const int
				 * to int.
				 */
				MATCH m = next.implicitConvTo(tsa.next);
				if (m >= MATCHconst)
				{
					if (mod != to.mod)
						m = MATCHconst;
					return m;
				}
			}
		}
		return MATCHnomatch;
	}
	
    override Expression defaultInit(Loc loc)
	{
	version (LOGDEFAULTINIT) {
		printf("TypeSArray.defaultInit() '%s'\n", toChars());
	}
		return next.defaultInit(loc);
	}
	
    override dt_t** toDt(dt_t** pdt)
	{
		return toDtElem(pdt, null);
	}
	
    dt_t** toDtElem(dt_t** pdt, Expression e)
	{
		int i;

		//printf("TypeSArray::toDtElem()\n");
		uint len = cast(uint)dim.toInteger();
		if (len)
		{
			while (*pdt)
				pdt = &((*pdt).DTnext);
			Type tnext = next;
			Type tbn = tnext.toBasetype();
			while (tbn.ty == Tsarray)
			{   
				TypeSArray tsa = cast(TypeSArray)tbn;

				len *= tsa.dim.toInteger();
				tnext = tbn.nextOf();
				tbn = tnext.toBasetype();
			}
			if (!e)				// if not already supplied
				e = tnext.defaultInit(Loc(0));	// use default initializer
			if (tbn.ty == Tstruct)
				tnext.toDt(pdt);
			else
				e.toDt(pdt);
			dt_optimize(*pdt);
			if ((*pdt).dt == DT_azeros && !(*pdt).DTnext)
			{
				(*pdt).DTazeros *= len;
				pdt = &((*pdt).DTnext);
			}
			else if ((*pdt).dt == DT_1byte && (*pdt).DTonebyte == 0 && !(*pdt).DTnext)
			{
				(*pdt).dt = DT_azeros;
				(*pdt).DTazeros = len;
				pdt = &((*pdt).DTnext);
			}
			else if (e.op != TOKstring)
			{
				for (i = 1; i < len; i++)
				{
					if (tbn.ty == Tstruct)
					{   
						pdt = tnext.toDt(pdt);
						while (*pdt)
							pdt = &((*pdt).DTnext);
					}
					else
						pdt = e.toDt(pdt);
				}
			}
		}
		return pdt;
	}
	
    override MATCH deduceType(Scope sc, Type tparam, TemplateParameters parameters, Objects dedtypes)
	{
static if (false) {
		printf("TypeSArray.deduceType()\n");
		printf("\tthis   = %d, ", ty); print();
		printf("\ttparam = %d, ", tparam.ty); tparam.print();
}

		// Extra check that array dimensions must match
		if (tparam)
		{
			if (tparam.ty == Tsarray)
			{
				TypeSArray tp = cast(TypeSArray)tparam;

				if (tp.dim.op == TOKvar && (cast(VarExp)tp.dim).var.storage_class & STCtemplateparameter)
				{	
					int i = templateIdentifierLookup((cast(VarExp)tp.dim).var.ident, parameters);
				// This code matches code in TypeInstance.deduceType()
					if (i == -1)
						goto Lnomatch;
					auto tp2 = parameters[i];
					TemplateValueParameter tvp = tp2.isTemplateValueParameter();
					if (!tvp)
						goto Lnomatch;
					Expression e = cast(Expression)dedtypes[i];
					if (e)
					{
						if (!dim.equals(e))
						goto Lnomatch;
					}
					else
					{   
						Type vt = tvp.valType.semantic(Loc(0), sc);
						MATCH m = cast(MATCH)dim.implicitConvTo(vt);
						if (!m)
							goto Lnomatch;
						dedtypes[i] = dim;
					}
				}
				else if (dim.toInteger() != tp.dim.toInteger())
					return MATCHnomatch;
			}
			else if (tparam.ty == Taarray)
			{
				auto tp = cast(TypeAArray)tparam;
				if (tp.index.ty == Tident)
				{	
					auto tident = cast(TypeIdentifier)tp.index;

					if (tident.idents.dim == 0)
					{   
						Identifier id = tident.ident;

						for (size_t i = 0; i < parameters.dim; i++)
						{
							auto tp2 = parameters[i];

							if (tp2.ident.equals(id))
							{   
								// Found the corresponding template parameter
								TemplateValueParameter tvp = tp2.isTemplateValueParameter();
								if (!tvp || !tvp.valType.isintegral())
								goto Lnomatch;

								if (dedtypes[i])
								{
									if (!dim.equals(dedtypes[i]))
										goto Lnomatch;
								}
								else
								{	dedtypes[i] = dim;
								}
								return next.deduceType(sc, tparam.nextOf(), parameters, dedtypes);
							}
						}
					}
				}
			}
			else if (tparam.ty == Tarray)
			{   
				MATCH m;

				m = next.deduceType(sc, tparam.nextOf(), parameters, dedtypes);
				if (m == MATCHexact)
					m = MATCHconvert;
				return m;
			}
		}
		return Type.deduceType(sc, tparam, parameters, dedtypes);

	  Lnomatch:
		return MATCHnomatch;
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoStaticArrayDeclaration(this);
	}
	
    override Expression toExpression()
	{
		Expression e = next.toExpression();
		if (e)
		{	
			Expressions arguments = new Expressions();
			arguments.push(dim);
			e = new ArrayExp(dim.loc, e, arguments);
		}
		return e;
	}
	
    override bool hasPointers()
	{
		return next.hasPointers();
	}
	
version (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState* cms)
	{
		assert(false);
	}
}

    override type* toCtype()
	{
		if (!ctype)
		{
			type* tn = next.toCtype();
			ctype = type_allocn(TYarray, tn);
			ctype.Tdim = cast(uint)dim.toInteger();
		}

		return ctype;
	}
	
    override type* toCParamtype()
	{
version(SARRAYVALUE)
{
		return toCtype();
}
else
{
		// arrays are passed as pointers
		return next.pointerTo().toCtype();
}
	}
}
