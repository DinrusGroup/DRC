module dmd.IndexExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.VarDeclaration;
import dmd.InlineDoState;
import dmd.Type;
import dmd.ScopeDsymbol;
import dmd.TY;
import dmd.Util;
import dmd.ArrayScopeSymbol;
import dmd.PREC;
import dmd.TypeNext;
import dmd.TypeSArray;
import dmd.TypeAArray;
import dmd.UnaExp;
import dmd.IRState;
import dmd.BinExp;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.WANT;
import dmd.TupleExp;
import dmd.TypeTuple;
import dmd.Parameter;
import dmd.TypeExp;
import dmd.VarExp;
import dmd.STC;
import dmd.GlobalExpressions;
import dmd.ExpInitializer;
import dmd.Global;

import dmd.expression.util.arrayTypeCompatible;
import dmd.expression.Util;
import dmd.expression.Index;
import dmd.expression.ArrayLength;

import dmd.backend.Symbol;
import dmd.backend.Util;
import dmd.codegen.Util;
import dmd.backend.OPER;
import dmd.backend.mTY;
import dmd.backend.TYM;

import core.stdc.string;
import core.stdc.stdio;

import dmd.DDMDExtensions;

class IndexExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

	VarDeclaration lengthVar;
	int modifiable = 0;	// assume it is an rvalue

	this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKindex, IndexExp.sizeof, e1, e2);
		//printf("IndexExp.IndexExp('%s')\n", toChars());
	}

	override Expression semantic(Scope sc)
	{
		Expression e;
		BinExp b;
		UnaExp u;
		Type t1;
		ScopeDsymbol sym;

	version (LOGSEMANTIC) {
		printf("IndexExp.semantic('%s')\n", toChars());
	}
		if (type)
			return this;
		if (!e1.type)
			e1 = e1.semantic(sc);
		assert(e1.type);		// semantic() should already be run on it
		e = this;

		// Note that unlike C we do not implement the int[ptr]

		t1 = e1.type.toBasetype();

		if (t1.ty == Tsarray || t1.ty == Tarray || t1.ty == Ttuple)
		{
			// Create scope for 'length' variable
			sym = new ArrayScopeSymbol(sc, this);
			sym.loc = loc;
			sym.parent = sc.scopesym;
			sc = sc.push(sym);
		}

		e2 = e2.semantic(sc);
		if (!e2.type)
		{
			error("%s has no value", e2.toChars());
			e2.type = Type.terror;
		}
		e2 = resolveProperties(sc, e2);

		if (t1.ty == Tsarray || t1.ty == Tarray || t1.ty == Ttuple)
			sc = sc.pop();

		switch (t1.ty)
		{
			case Tpointer:
			case Tarray:
				e2 = e2.implicitCastTo(sc, Type.tsize_t);
				e.type = (cast(TypeNext)t1).next;
				break;

			case Tsarray:
			{
				e2 = e2.implicitCastTo(sc, Type.tsize_t);

				TypeSArray tsa = cast(TypeSArray)t1;

		static if (false) {
				// Don't do now, because it might be short-circuit evaluated
				// Do compile time array bounds checking if possible
				e2 = e2.optimize(WANTvalue);
				if (e2.op == TOKint64)
				{
					ulong index = e2.toInteger();
					ulong length = tsa.dim.toInteger();
					if (index < 0 || index >= length)
						error("array index [%lld] is outside array bounds [0 .. %lld]", index, length);
				}
		}
				e.type = t1.nextOf();
				break;
			}

			case Taarray:
			{
				TypeAArray taa = cast(TypeAArray)t1;
				if (!arrayTypeCompatible(e2.loc, e2.type, taa.index))
				{
					e2 = e2.implicitCastTo(sc, taa.index);	// type checking
				}
				type = taa.next;
				break;
			}

			case Ttuple:
			{
				e2 = e2.implicitCastTo(sc, Type.tsize_t);
				e2 = e2.optimize(WANTvalue | WANTinterpret);
				ulong index = e2.toUInteger();
				size_t length;
				TupleExp te;
				TypeTuple tup;

				if (e1.op == TOKtuple)
				{
					te = cast(TupleExp)e1;
					length = te.exps.dim;
				}
				else if (e1.op == TOKtype)
				{
					tup = cast(TypeTuple)t1;
					length = Parameter.dim(tup.arguments);
				}
				else
					assert(0);

				if (index < length)
				{
					if (e1.op == TOKtuple)
						e = te.exps[cast(size_t)index];
					else
						e = new TypeExp(e1.loc, Parameter.getNth(tup.arguments, cast(size_t)index).type);
				}
				else
				{
					error("array index [%ju] is outside array bounds [0 .. %zu]", index, length);
					e = e1;
				}
				break;
			}

			default:
				error("%s must be an array or pointer type, not %s", e1.toChars(), e1.type.toChars());
				type = Type.tint32;
				break;
		}

		return e;
	}

	override bool isLvalue()
	{
		return true;
	}

	override Expression toLvalue(Scope sc, Expression e)
	{
		//    if (type && type.toBasetype().ty == Tvoid)
		//		error("voids have no value");
		return this;
	}

	override Expression modifiableLvalue(Scope sc, Expression e)
	{
		//printf("IndexExp::modifiableLvalue(%s)\n", toChars());
		modifiable = 1;
		if (e1.op == TOKstring)
			error("string literals are immutable");
		if (type && !type.isMutable())
			error("%s isn't mutable", e.toChars());
		if (e1.type.toBasetype().ty == Taarray)
			e1 = e1.modifiableLvalue(sc, e1);
		return toLvalue(sc, e);
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC.PREC_primary);
		buf.writeByte('[');
		expToCBuffer(buf, hgs, e2, PREC.PREC_assign);
		buf.writeByte(']');
	}

	override Expression optimize(int result)
	{
		Expression e;

		//printf("IndexExp::optimize(result = %d) %s\n", result, toChars());
		Expression e1 = this.e1.optimize(WANTvalue | (result & WANTinterpret));
		e1 = fromConstInitializer(result, e1);
		if (this.e1.op == TOKvar)
		{
			VarExp ve = cast(VarExp)this.e1;
			if (ve.var.storage_class & STCmanifest)
			{
				/* We generally don't want to have more than one copy of an
				 * array literal, but if it's an enum we have to because the
				 * enum isn't stored elsewhere. See Bugzilla 2559
				 */
				this.e1 = e1;
			}
		}

		e2 = e2.optimize(WANTvalue | (result & WANTinterpret));
		e = Index(type, e1, e2);
		if (e is EXP_CANT_INTERPRET)
			e = this;

		return e;
	}

	override Expression interpret(InterState istate)
	{
		Expression e;
		Expression e1;
		Expression e2;

	version (LOG) {
		printf("IndexExp.interpret() %s\n", toChars());
	}
		e1 = this.e1.interpret(istate);
		if (e1 is EXP_CANT_INTERPRET)
			goto Lcant;

		if (e1.op == TOKstring || e1.op == TOKarrayliteral)
		{
			/* Set the $ variable
			 */
			e = ArrayLength(Type.tsize_t, e1);
			if (e is EXP_CANT_INTERPRET)
				goto Lcant;
			if (lengthVar)
				lengthVar.value = e;
		}

		e2 = this.e2.interpret(istate);
		if (e2 is EXP_CANT_INTERPRET)
			goto Lcant;
		return Index(type, e1, e2);

	Lcant:
		return EXP_CANT_INTERPRET;
	}

	override Expression doInline(InlineDoState ids)
	{
		IndexExp are = cast(IndexExp)copy();

		are.e1 = e1.doInline(ids);

		if (lengthVar)
		{	//printf("lengthVar\n");
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
		are.e2 = e2.doInline(ids);
		return are;
	}

	override void scanForNestedRef(Scope sc)
	{
		e1.scanForNestedRef(sc);

		if (lengthVar)
		{
			//printf("lengthVar\n");
			lengthVar.parent = sc.parent;
		}
		e2.scanForNestedRef(sc);
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;
		elem* n1 = e1.toElem(irs);
		elem* eb = null;

		//printf("IndexExp.toElem() %s\n", toChars());
		Type t1 = e1.type.toBasetype();
		if (t1.ty == Taarray)
		{
			// set to:
			//	*aaGet(aa, keyti, valuesize, index);

			TypeAArray taa = cast(TypeAArray)t1;
			elem* keyti;
			elem* ep;
			int vsize = cast(int)taa.next.size();
			Symbol* s;

			// n2 becomes the index, also known as the key
			elem* n2 = e2.toElem(irs);
			if (tybasic(n2.Ety) == TYstruct || tybasic(n2.Ety) == TYarray)
			{
				n2 = el_una(OPstrpar, TYstruct, n2);
				n2.Enumbytes = n2.E1.Enumbytes;
				if (taa.index.ty == Tsarray)
			    {
					assert(e2.type.size() == taa.index.size());
					n2.Enumbytes = cast(size_t) taa.index.size();
			    }
				//printf("numbytes = %d\n", n2.Enumbytes);
				assert(n2.Enumbytes);
			}
			elem* valuesize = el_long(TYuint, vsize);	// BUG: should be TYsize_t
			//printf("valuesize: "); elem_print(valuesize);
			if (modifiable)
			{
				n1 = el_una(OPaddr, TYnptr, n1);
				s = taa.aaGetSymbol("Get", 1);
			}
			else
			{
				s = taa.aaGetSymbol("GetRvalue", 1);
			}
			//printf("taa.index = %s\n", taa.index.toChars());
			keyti = taa.index.getInternalTypeInfo(null).toElem(irs);
			//keyti = taa.index.getTypeInfo(null).toElem(irs);
			//printf("keyti:\n");
			//elem_print(keyti);
			ep = el_params(n2, valuesize, keyti, n1, null);
			e = el_bin(OPcall, TYnptr, el_var(s), ep);

			if (irs.arrayBoundsCheck())
			{
				elem* ea;

				elem* n = el_same(&e);

				// Construct: ((e || ModuleAssert(line)),n)
				Symbol* sassert = irs.blx.module_.toModuleArray();

				ea = el_bin(OPcall,TYvoid,el_var(sassert),
				el_long(TYint, loc.linnum));
				e = el_bin(OPoror,TYvoid,e,ea);
				e = el_bin(OPcomma, TYnptr, e, n);
			}
			e = el_una(OPind, type.totym(), e);
			if (tybasic(e.Ety) == TYstruct)
				e.Enumbytes = cast(uint)type.size();
		}
		else
		{
			elem* einit = resolveLengthVar(lengthVar, &n1, t1);
			elem* n2 = e2.toElem(irs);

			if (irs.arrayBoundsCheck())
			{
				elem* elength;
				elem* n2x;
				elem* ea;

				if (t1.ty == Tsarray)
				{
					TypeSArray tsa = cast(TypeSArray)t1;
					ulong length = tsa.dim.toInteger();

					elength = el_long(TYuint, length);
					goto L1;
				}
				else if (t1.ty == Tarray)
				{
					elength = n1;
					n1 = el_same(&elength);
					elength = el_una(OP64_32, TYuint, elength);
					L1:
					n2x = n2;
					n2 = el_same(&n2x);
					n2x = el_bin(OPlt, TYint, n2x, elength);

					// Construct: (n2x || ModuleAssert(line))
					Symbol* sassert;

					sassert = irs.blx.module_.toModuleArray();
					ea = el_bin(OPcall,TYvoid,el_var(sassert),
						el_long(TYint, loc.linnum));
					eb = el_bin(OPoror,TYvoid,n2x,ea);
				}
			}

			n1 = array_toPtr(t1, n1);

			{
				elem* escale;

				escale = el_long(TYint, t1.nextOf().size());
				n2 = el_bin(OPmul, TYint, n2, escale);
				e = el_bin(OPadd, TYnptr, n1, n2);
				e = el_una(OPind, type.totym(), e);
				if (tybasic(e.Ety) == TYstruct || tybasic(e.Ety) == TYarray)
				{
					e.Ety = TYstruct;
					e.Enumbytes = cast(uint)type.size();
				}
			}

			eb = el_combine(einit, eb);
			e = el_combine(eb, e);
		}

		el_setLoc(e,loc);

		return e;
	}
}

