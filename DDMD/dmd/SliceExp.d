module dmd.SliceExp;

import dmd.common;
import dmd.Expression;
import dmd.expression.ArrayLength;
import dmd.backend.elem;
import dmd.UnaExp;
import dmd.Identifier;
import dmd.IdentifierExp;
import dmd.ArrayExp;
import dmd.STC;
import dmd.InterState;
import dmd.ScopeDsymbol;
import dmd.WANT;
import dmd.Util;
import dmd.ArrayScopeSymbol;
import dmd.CallExp;
import dmd.DotIdExp;
import dmd.Id;
import dmd.expression.Util;
import dmd.TypeTuple;
import dmd.TupleExp;
import dmd.TypeStruct;
import dmd.TypeClass;
import dmd.TY;
import dmd.Type;
import dmd.AggregateDeclaration;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.InlineCostState;
import dmd.VarDeclaration;
import dmd.ErrorExp;
import dmd.TypeExp;
import dmd.Parameter;
import dmd.ExpInitializer;
import dmd.IRState;
import dmd.InlineDoState;
import dmd.ArrayTypes;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.TOK;
import dmd.TypeSArray;
import dmd.GlobalExpressions;
import dmd.Global;
import dmd.PREC;

import dmd.expression.Slice;
import dmd.expression.Util;

import dmd.backend.Util;
import dmd.backend.Symbol;
import dmd.backend.OPER;
import dmd.backend.TYM;
import dmd.codegen.Util;

import core.stdc.string;

import dmd.DDMDExtensions;

class SliceExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	Expression upr;		// null if implicit 0
    Expression lwr;		// null if implicit [length - 1]

	VarDeclaration lengthVar = null;

	this(Loc loc, Expression e1, Expression lwr, Expression upr)
	{
		register();
		super(loc, TOK.TOKslice, SliceExp.sizeof, e1);
		this.upr = upr;
		this.lwr = lwr;
	}

	override Expression syntaxCopy()
	{
		Expression lwr = null;
		if (this.lwr)
			lwr = this.lwr.syntaxCopy();

		Expression upr = null;
		if (this.upr)
			upr = this.upr.syntaxCopy();

		return new SliceExp(loc, e1.syntaxCopy(), lwr, upr);
	}

	override Expression semantic(Scope sc)
	{
		Expression e;
		AggregateDeclaration ad;
		//FuncDeclaration fd;
		ScopeDsymbol sym;

	version (LOGSEMANTIC) {
		printf("SliceExp.semantic('%s')\n", toChars());
	}
		if (type)
			return this;

		UnaExp.semantic(sc);
		e1 = resolveProperties(sc, e1);

		e = this;

		Type t = e1.type.toBasetype();
		if (t.ty == Tpointer)
		{
			if (!lwr || !upr)
				error("need upper and lower bound to slice pointer");
		}
		else if (t.ty == Tarray)
		{
		}
		else if (t.ty == Tsarray)
		{
		}
		else if (t.ty == Tclass)
		{
			ad = (cast(TypeClass)t).sym;
			goto L1;
		}
		else if (t.ty == Tstruct)
		{
			ad = (cast(TypeStruct)t).sym;

		L1:
			if (search_function(ad, Id.slice))
			{
				// Rewrite as e1.slice(lwr, upr)
				e = new DotIdExp(loc, e1, Id.slice);

				if (lwr)
				{
					assert(upr);
					e = new CallExp(loc, e, lwr, upr);
				}
				else
				{
					assert(!upr);
					e = new CallExp(loc, e);
				}
				e = e.semantic(sc);
				return e;
			}
			goto Lerror;
		}
		else if (t.ty == Ttuple)
		{
			if (!lwr && !upr)
				return e1;
			if (!lwr || !upr)
			{   error("need upper and lower bound to slice tuple");
				goto Lerror;
			}
		}
		else
			goto Lerror;

		{
			Scope sc2 = sc;
			if (t.ty == Tsarray || t.ty == Tarray || t.ty == Ttuple)
			{
				sym = new ArrayScopeSymbol(sc, this);
				sym.loc = loc;
				sym.parent = sc.scopesym;
				sc2 = sc.push(sym);
			}

			if (lwr)
			{
				lwr = lwr.semantic(sc2);
				lwr = resolveProperties(sc2, lwr);
				lwr = lwr.implicitCastTo(sc2, Type.tsize_t);
			}
			if (upr)
			{
				upr = upr.semantic(sc2);
				upr = resolveProperties(sc2, upr);
				upr = upr.implicitCastTo(sc2, Type.tsize_t);
			}

			if (sc2 != sc)
				sc2.pop();
		}

		if (t.ty == Ttuple)
		{
			lwr = lwr.optimize(WANTvalue);
			upr = upr.optimize(WANTvalue);
			ulong i1 = lwr.toUInteger();
			ulong i2 = upr.toUInteger();

			size_t length;
			TupleExp te;
			TypeTuple tup;

			if (e1.op == TOKtuple)		// slicing an expression tuple
			{
				te = cast(TupleExp)e1;
				length = te.exps.dim;
			}
			else if (e1.op == TOKtype)	// slicing a type tuple
			{
				tup = cast(TypeTuple)t;
				length = Parameter.dim(tup.arguments);
			}
			else
				assert(0);

			if (i1 <= i2 && i2 <= length)
			{
				size_t j1 = cast(size_t) i1;
				size_t j2 = cast(size_t) i2;

				if (e1.op == TOKtuple)
				{
					auto exps = new Expressions;
					exps.setDim(j2 - j1);
					for (size_t i = 0; i < j2 - j1; i++)
					{
						auto e2 = te.exps[j1 + i];
						exps[i] = e2;
					}
					e = new TupleExp(loc, exps);
				}
				else
				{
					auto args = new Parameters;
					args.reserve(j2 - j1);
					for (size_t i = j1; i < j2; i++)
					{
						auto arg = Parameter.getNth(tup.arguments, i);
						args.push(arg);
					}
					e = new TypeExp(e1.loc, new TypeTuple(args));
				}
				e = e.semantic(sc);
			}
			else
			{
				error("string slice [%ju .. %ju] is out of bounds", i1, i2);
				e = new ErrorExp();
			}
			return e;
		}

		if (t.ty == Tarray)
		{
			type = e1.type;
		}
		else
			type = t.nextOf().arrayOf();
		return e;

	Lerror:
		string s;
		if (t.ty == Tvoid)
			s = e1.toChars();
		else
			s = t.toChars();
		error("%s cannot be sliced with []", s);
		e = new ErrorExp();
		return e;
	}

	override void checkEscape()
	{
		e1.checkEscape();
	}

    override void checkEscapeRef()
    {
        e1.checkEscapeRef();
    }

version (DMDV2) {
	override bool isLvalue()
	{
		return true;
	}
}
	override Expression toLvalue(Scope sc, Expression e)
	{
		return this;
	}

	override Expression modifiableLvalue(Scope sc, Expression e)
	{
		error("slice expression %s is not a modifiable lvalue", toChars());
		return this;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		expToCBuffer(buf, hgs, e1, precedence[op]);
		buf.writeByte('[');
		if (upr || lwr)
		{
			if (lwr)
				expToCBuffer(buf, hgs, lwr, PREC.PREC_assign);
			else
				buf.writeByte('0');
			buf.writestring("..");
			if (upr)
				expToCBuffer(buf, hgs, upr, PREC.PREC_assign);
			else
				buf.writestring("length");		// BUG: should be array.length
		}
		buf.writeByte(']');
	}

	override Expression optimize(int result)
	{
		Expression e;

		//printf("SliceExp::optimize(result = %d) %s\n", result, toChars());
		e = this;
		e1 = e1.optimize(WANTvalue | (result & WANTinterpret));
		if (!lwr)
		{
			if (e1.op == TOKstring)
			{
				// Convert slice of string literal into dynamic array
				Type t = e1.type.toBasetype();
				if (t.nextOf())
					e = e1.castTo(null, t.nextOf().arrayOf());
			}
			return e;
		}
		e1 = fromConstInitializer(result, e1);
		lwr = lwr.optimize(WANTvalue | (result & WANTinterpret));
		upr = upr.optimize(WANTvalue | (result & WANTinterpret));
		e = Slice(type, e1, lwr, upr);
		if (e is EXP_CANT_INTERPRET)
			e = this;
		//printf("-SliceExp::optimize() %s\n", e->toChars());
		return e;
	}

	override Expression interpret(InterState istate)
	{
		Expression e;
		Expression e1;
		Expression lwr;
		Expression upr;

version (LOG) {
		printf("SliceExp.interpret() %s\n", toChars());
}
		e1 = this.e1.interpret(istate);
		if (e1 is EXP_CANT_INTERPRET)
			goto Lcant;
		if (!this.lwr)
		{
			e = e1.castTo(null, type);
			return e.interpret(istate);
		}

		/* Set the $ variable
		 */
		e = ArrayLength(Type.tsize_t, e1);
		if (e is EXP_CANT_INTERPRET)
			goto Lcant;
		if (lengthVar)
			lengthVar.value = e;

		/* Evaluate lower and upper bounds of slice
		 */
		lwr = this.lwr.interpret(istate);
		if (lwr is EXP_CANT_INTERPRET)
			goto Lcant;
		upr = this.upr.interpret(istate);
		if (upr is EXP_CANT_INTERPRET)
			goto Lcant;

		return Slice(type, e1, lwr, upr);

	Lcant:
		return EXP_CANT_INTERPRET;
	}

	override void dump(int indent)
	{
		assert(false);
	}

	override elem* toElem(IRState* irs)
	{
		//printf("SliceExp.toElem()\n");
		auto t1 = e1.type.toBasetype();
		auto e = e1.toElem(irs);
		if (lwr)
		{
			auto einit = resolveLengthVar(lengthVar, &e, t1);

			int sz = cast(uint)t1.nextOf().size();

			auto elwr = lwr.toElem(irs);
			auto eupr = upr.toElem(irs);

			auto elwr2 = el_same(&elwr);

			// Create an array reference where:
			// length is (upr - lwr)
			// pointer is (ptr + lwr*sz)
			// Combine as (length pair ptr)

			if (irs.arrayBoundsCheck())
			{
				// Checks (unsigned compares):
				//	upr <= array.length
				//	lwr <= upr

				elem *c1;
				elem *c2;
				elem *ea;
				elem *eb;
				elem *eupr2;
				elem *elength;

				if (t1.ty == Tpointer)
				{
					// Just do lwr <= upr check

					eupr2 = el_same(&eupr);
					eupr2.Ety = TYuint;			// make sure unsigned comparison
					c1 = el_bin(OPle, TYint, elwr2, eupr2);
					c1 = el_combine(eupr, c1);
					goto L2;
				}
				else if (t1.ty == Tsarray)
				{
					TypeSArray tsa = cast(TypeSArray)t1;
					ulong length = tsa.dim.toInteger();

					elength = el_long(TYuint, length);
					goto L1;
				}
				else if (t1.ty == Tarray)
				{
					if (lengthVar)
						elength = el_var(lengthVar.toSymbol());
					else
					{
						elength = e;
						e = el_same(&elength);
						elength = el_una(OP64_32, TYuint, elength);
					}
					L1:
					eupr2 = el_same(&eupr);
					c1 = el_bin(OPle, TYint, eupr, elength);
					eupr2.Ety = TYuint;			// make sure unsigned comparison
					c2 = el_bin(OPle, TYint, elwr2, eupr2);
					c1 = el_bin(OPandand, TYint, c1, c2);	// (c1 && c2)

					L2:
					// Construct: (c1 || ModuleArray(line))
					Symbol* sassert;

					sassert = irs.blx.module_.toModuleArray();
					ea = el_bin(OPcall,TYvoid,el_var(sassert), el_long(TYint, loc.linnum));
					eb = el_bin(OPoror,TYvoid,c1,ea);
					elwr = el_combine(elwr, eb);

					elwr2 = el_copytree(elwr2);
					eupr = el_copytree(eupr2);
				}
			}

			auto eptr = array_toPtr(e1.type, e);

			elem *elength = el_bin(OPmin, TYint, eupr, elwr2);
			eptr = el_bin(OPadd, TYnptr, eptr, el_bin(OPmul, TYint, el_copytree(elwr2), el_long(TYint, sz)));

			e = el_pair(TYullong, elength, eptr);
			e = el_combine(elwr, e);
			e = el_combine(einit, e);
		}
		else if (t1.ty == Tsarray)
		{
			e = sarray_toDarray(loc, t1, null, e);
		}

		el_setLoc(e,loc);
		return e;
	}

	override void scanForNestedRef(Scope sc)
	{
		e1.scanForNestedRef(sc);

		if (lengthVar)
		{
			//printf("lengthVar\n");
			lengthVar.parent = sc.parent;
		}
		if (lwr)
			lwr.scanForNestedRef(sc);
		if (upr)
			upr.scanForNestedRef(sc);
	}

	override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		buf.writestring("Slice");
		arguments.shift(this);
	}

	override Expression buildArrayLoop(Parameters fparams)
	{
		Identifier id = Identifier.generateId("p", fparams.dim);
		auto param = new Parameter(STCconst, type, id, null);
		fparams.shift(param);
		Expression e = new IdentifierExp(Loc(0), id);
		Expressions arguments = new Expressions();
		Expression index = new IdentifierExp(Loc(0), Id.p);
		arguments.push(index);
		e = new ArrayExp(Loc(0), e, arguments);
		return e;
	}

	override int inlineCost(InlineCostState* ics)
	{
		int cost = 1 + e1.inlineCost(ics);
		if (lwr)
			cost += lwr.inlineCost(ics);
		if (upr)
			cost += upr.inlineCost(ics);
		return cost;
	}

	override Expression doInline(InlineDoState ids)
	{
		SliceExp are = cast(SliceExp)copy();

		are.e1 = e1.doInline(ids);

		if (lengthVar)
		{
			//printf("lengthVar\n");
			VarDeclaration vd = lengthVar;
			ExpInitializer ie;
			ExpInitializer ieto;
			VarDeclaration vto;

			vto = cloneThis(vd);

			vto.parent = ids.parent;
			vto.csym = null;
			vto.isym = null;

			ids.from.push(cast(void*)vd);
			ids.to.push(cast(void*)vto);

			if (vd.init)
			{
				ie = vd.init.isExpInitializer();
				assert(ie);
				ieto = new ExpInitializer(ie.loc, ie.exp.doInline(ids));
				vto.init = ieto;
			}

			are.lengthVar = vto;
		}

		if (lwr)
			are.lwr = lwr.doInline(ids);
		if (upr)
			are.upr = upr.doInline(ids);
		return are;
	}

	override Expression inlineScan(InlineScanState* iss)
	{
		e1 = e1.inlineScan(iss);
		if (lwr)
			lwr = lwr.inlineScan(iss);
		if (upr)
			upr = upr.inlineScan(iss);
		return this;
	}
}

