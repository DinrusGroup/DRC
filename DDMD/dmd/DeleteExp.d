module dmd.DeleteExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.UnaExp;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.Type;
import dmd.IndexExp;
import dmd.PREC;
import dmd.Global;
import dmd.VarExp;
import dmd.Identifier;
import dmd.StructDeclaration;
import dmd.Lexer;
import dmd.FuncDeclaration;
import dmd.TypeStruct;
import dmd.CallExp;
import dmd.DotVarExp;
import dmd.DeclarationExp;
import dmd.ExpInitializer;
import dmd.VarDeclaration;
import dmd.TypePointer;
import dmd.ClassDeclaration;
import dmd.TypeClass;
import dmd.TY;
import dmd.TOK;
import dmd.TypeAArray;
import dmd.TypeSArray;

import dmd.expression.Util;
import dmd.codegen.Util;
import dmd.backend.Util;
import dmd.backend.OPER;
import dmd.backend.RTLSYM;
import dmd.backend.mTY;
import dmd.backend.Symbol;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

class DeleteExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Expression e)
	{
		register();
		super(loc, TOK.TOKdelete, DeleteExp.sizeof, e);
	}

	override Expression semantic(Scope sc)
	{
		Type tb;

		UnaExp.semantic(sc);
		e1 = resolveProperties(sc, e1);
		e1 = e1.toLvalue(sc, null);
		type = Type.tvoid;

		tb = e1.type.toBasetype();
		switch (tb.ty)
		{
			case Tclass:
			{
				TypeClass tc = cast(TypeClass)tb;
				ClassDeclaration cd = tc.sym;

				if (cd.isCOMinterface())
				{	/* Because COM classes are deleted by IUnknown.Release()
					 */
					error("cannot delete instance of COM interface %s", cd.toChars());
				}
				break;
			}
			case Tpointer:
				tb = (cast(TypePointer)tb).next.toBasetype();
				if (tb.ty == Tstruct)
				{
					TypeStruct ts = cast(TypeStruct)tb;
					StructDeclaration sd = ts.sym;
					FuncDeclaration f = sd.aggDelete;
					FuncDeclaration fd = sd.dtor;

					if (!f && !fd)
						break;

					/* Construct:
					 *	ea = copy e1 to a tmp to do side effects only once
					 *	eb = call destructor
					 *	ec = call deallocator
					 */
					Expression ea = null;
					Expression eb = null;
					Expression ec = null;
					VarDeclaration v;

					if (fd && f)
					{
						Identifier id = Lexer.idPool("__tmp");
						v = new VarDeclaration(loc, e1.type, id, new ExpInitializer(loc, e1));
						v.semantic(sc);
						v.parent = sc.parent;
						ea = new DeclarationExp(loc, v);
						ea.type = v.type;
					}

					if (fd)
					{
						Expression e = ea ? new VarExp(loc, v) : e1;
						e = new DotVarExp(Loc(0), e, fd, 0);
						eb = new CallExp(loc, e);
						eb = eb.semantic(sc);
					}

					if (f)
					{
						Type tpv = Type.tvoid.pointerTo();
						Expression e = ea ? new VarExp(loc, v) : e1.castTo(sc, tpv);
						e = new CallExp(loc, new VarExp(loc, f), e);
						ec = e.semantic(sc);
					}
					ea = combine(ea, eb);
					ea = combine(ea, ec);
					assert(ea);
					return ea;
				}
				break;

			case Tarray:
				/* BUG: look for deleting arrays of structs with dtors.
				 */
				break;

			default:
				if (e1.op == TOKindex)
				{
					IndexExp ae = cast(IndexExp)e1;
					Type tb1 = ae.e1.type.toBasetype();
					if (tb1.ty == Taarray)
						break;
				}
				error("cannot delete type %s", e1.type.toChars());
				break;
		}

		if (e1.op == TOKindex)
		{
			IndexExp ae = cast(IndexExp)e1;
			Type tb1 = ae.e1.type.toBasetype();
			if (tb1.ty == Taarray)
			{
				if (!global.params.useDeprecated)
					error("delete aa[key] deprecated, use aa.remove(key)");
			}
		}

		return this;
	}

	override Expression checkToBoolean()
	{
		assert(false);
	}

	override bool checkSideEffect(int flag)
	{
		return true;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("delete ");
		expToCBuffer(buf, hgs, e1, precedence[op]);
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;
		int rtl;
		Type tb;

		//printf("DeleteExp.toElem()\n");
		if (e1.op == TOKindex)
		{
			IndexExp ae = cast(IndexExp)e1;
			tb = ae.e1.type.toBasetype();
			if (tb.ty == Taarray)
			{
				TypeAArray taa = cast(TypeAArray)tb;
				elem* ea = ae.e1.toElem(irs);
				elem* ekey = ae.e2.toElem(irs);
				elem* ep;
				elem* keyti;

				if (tybasic(ekey.Ety) == TYstruct || tybasic(ekey.Ety) == TYarray)
				{
					ekey = el_una(OPstrpar, TYstruct, ekey);
					ekey.Enumbytes = ekey.E1.Enumbytes;
					assert(ekey.Enumbytes);
				}

				Symbol *s = taa.aaGetSymbol("Del", 0);
				keyti = taa.index.getInternalTypeInfo(null).toElem(irs);
				ep = el_params(ekey, keyti, ea, null);
				e = el_bin(OPcall, TYnptr, el_var(s), ep);
				goto Lret;
			}
		}
		//e1.type.print();
		e = e1.toElem(irs);
		tb = e1.type.toBasetype();
		switch (tb.ty)
		{
			case Tarray:
			{
				e = addressElem(e, e1.type);
				rtl = RTLSYM_DELARRAYT;

				/* See if we need to run destructors on the array contents
				 */
				elem *et = null;
				Type tv = tb.nextOf().toBasetype();
				while (tv.ty == Tsarray)
				{
					TypeSArray ta = cast(TypeSArray)tv;
					tv = tv.nextOf().toBasetype();
				}
				if (tv.ty == Tstruct)
				{
					TypeStruct ts = cast(TypeStruct)tv;
					StructDeclaration sd = ts.sym;
					if (sd.dtor)
						et = tb.nextOf().getTypeInfo(null).toElem(irs);
				}
				if (!et)				// if no destructors needed
					et = el_long(TYnptr, 0);	// pass null for TypeInfo
				e = el_params(et, e, null);
				// call _d_delarray_t(e, et);
				e = el_bin(OPcall, TYvoid, el_var(rtlsym[rtl]), e);
				goto Lret;
			}
			case Tclass:
				if (e1.op == TOKvar)
				{
					VarExp ve = cast(VarExp)e1;
					if (ve.var.isVarDeclaration() &&
						ve.var.isVarDeclaration().onstack)
					{
						rtl = RTLSYM_CALLFINALIZER;
						if (tb.isClassHandle().isInterfaceDeclaration())
							rtl = RTLSYM_CALLINTERFACEFINALIZER;
						break;
					}
				}
				e = addressElem(e, e1.type);
				rtl = RTLSYM_DELCLASS;
				if (tb.isClassHandle().isInterfaceDeclaration())
					rtl = RTLSYM_DELINTERFACE;
				break;

			case Tpointer:
				e = addressElem(e, e1.type);
				rtl = RTLSYM_DELMEMORY;
				break;

			default:
				assert(0);
				break;
		}
		e = el_bin(OPcall, TYvoid, el_var(rtlsym[rtl]), e);

	  Lret:
		el_setLoc(e,loc);
		return e;
	}
}

