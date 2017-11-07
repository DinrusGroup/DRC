module dmd.TypeStruct;

import dmd.common;
import dmd.Type;
import dmd.TypeInstance;
import dmd.StructDeclaration;
import dmd.Declaration;
import dmd.STC;
import dmd.MOD;
import dmd.OutBuffer;
import dmd.DotVarExp;
import dmd.TemplateMixin;
import dmd.DotTemplateExp;
import dmd.DsymbolExp;
import dmd.TypeExp;
import dmd.EnumMember;
import dmd.Id;
import dmd.DotIdExp;
import dmd.ScopeExp;
import dmd.TupleExp;
import dmd.TemplateDeclaration;
import dmd.OverloadSet;
import dmd.Import;
import dmd.DotExp;
import dmd.ErrorExp;
import dmd.Loc;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.Identifier;
import dmd.MATCH;
import dmd.ArrayTypes;
import dmd.DYNCAST;
import dmd.TemplateInstance;
import dmd.FuncDeclaration;
import dmd.VarExp;
import dmd.CommaExp;
import dmd.ThisExp;
import dmd.StructLiteralExp;
import dmd.SymbolDeclaration;
import dmd.TypeInfoDeclaration;
import dmd.TypeInfoStructDeclaration;
import dmd.TY;
import dmd.TOK;
import dmd.Global;
import dmd.VarDeclaration;
import dmd.Util;
import dmd.expression.Util;

import dmd.backend.TYPE;
import dmd.backend.dt_t;
import dmd.backend.Symbol;
import dmd.backend.Util;
import dmd.backend.STR;
import dmd.backend.TYM;
import dmd.backend.Classsym;
import dmd.backend.SC;
import dmd.backend.LIST;

import std.string : toStringz;

import dmd.DDMDExtensions;

class TypeStruct : Type
{
	mixin insertMemberExtension!(typeof(this));

    StructDeclaration sym;

    this(StructDeclaration sym)
	{
		register();
		super(TY.Tstruct);
		this.sym = sym;
	}
    override ulong size(Loc loc)
	{
		return sym.size(loc);
	}

    override uint alignsize()
	{
		uint sz;

		sym.size(Loc(0));		// give error for forward references
		sz = sym.alignsize;
		if (sz > sym.structalign)
			sz = sym.structalign;
		return sz;
	}

    override string toChars()
	{
		//printf("sym.parent: %s, deco = %s\n", sym.parent.toChars(), deco);
		if (mod)
			return Type.toChars();
		TemplateInstance ti = sym.parent.isTemplateInstance();
		if (ti && ti.toAlias() == sym)
		{
			return ti.toChars();
		}
		return sym.toChars();
	}

    override Type syntaxCopy()
	{
		assert(false);
	}

    override Type semantic(Loc loc, Scope sc)
	{
		//printf("TypeStruct.semantic('%s')\n", sym.toChars());

		/* Cannot do semantic for sym because scope chain may not
		 * be right.
		 */
		//sym.semantic(sc);

		return merge();
	}

    override Dsymbol toDsymbol(Scope sc)
	{
		return sym;
	}

    override void toDecoBuffer(OutBuffer buf, int flag)
	{
		string name = sym.mangle();
		//printf("TypeStruct.toDecoBuffer('%s') = '%s'\n", toChars(), name);
		Type.toDecoBuffer(buf, flag);
		buf.printf("%s", name);
	}

    override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		if (mod != this.mod)
		{
			toCBuffer3(buf, hgs, mod);
			return;
		}
		TemplateInstance ti = sym.parent.isTemplateInstance();
		if (ti && ti.toAlias() == sym)
			buf.writestring(ti.toChars());
		else
			buf.writestring(sym.toChars());
	}

    override Expression dotExp(Scope sc, Expression e, Identifier ident)
	{
		uint offset;

		VarDeclaration v;
		Dsymbol s;
		DotVarExp de;
		Declaration d;

	version (LOGDOTEXP) {
		printf("TypeStruct.dotExp(e = '%s', ident = '%s')\n", e.toChars(), ident.toChars());
	}
		if (!sym.members)
		{
			error(e.loc, "struct %s is forward referenced", sym.toChars());
			return new ErrorExp();
		}

		/* If e.tupleof
		 */
		if (ident is Id.tupleof_)
		{
			/* Create a TupleExp out of the fields of the struct e:
			 * (e.field0, e.field1, e.field2, ...)
			 */
			e = e.semantic(sc);	// do this before turning on noaccesscheck
			auto exps = new Expressions;
			exps.reserve(sym.fields.dim);
			for (size_t i = 0; i < sym.fields.dim; i++)
			{
				VarDeclaration v2 = cast(VarDeclaration)sym.fields[i];
				Expression fe = new DotVarExp(e.loc, e, v2);
				exps.push(fe);
			}
			e = new TupleExp(e.loc, exps);
			sc = sc.push();
			sc.noaccesscheck = 1;
			e = e.semantic(sc);
			sc.pop();
			return e;
		}

		if (e.op == TOK.TOKdotexp)
		{
			DotExp de2 = cast(DotExp)e;

			if (de2.e1.op == TOK.TOKimport)
			{
				assert(0);	// cannot find a case where this happens; leave
					// assert in until we do
				ScopeExp se = cast(ScopeExp)de2.e1;

				s = se.sds.search(e.loc, ident, 0);
				e = de2.e1;
				goto L1;
			}
		}

		s = sym.search(e.loc, ident, 0);
	L1:
		if (!s)
		{
	        return noMember(sc, e, ident);
		}

		if (!s.isFuncDeclaration())	// because of overloading
			s.checkDeprecated(e.loc, sc);

		s = s.toAlias();

		v = s.isVarDeclaration();
		if (v && !v.isDataseg())
		{
			Expression ei = v.getConstInitializer();
			if (ei)
			{
				e = ei.copy();	// need to copy it if it's a StringExp
				e = e.semantic(sc);
				return e;
			}
		}

		if (s.getType())
		{
			//return new DotTypeExp(e.loc, e, s);
			return new TypeExp(e.loc, s.getType());
		}

		EnumMember em = s.isEnumMember();
		if (em)
		{
			assert(em.value);
			return em.value.copy();
		}

		TemplateMixin tm = s.isTemplateMixin();
		if (tm)
		{
			Expression de2 = new DotExp(e.loc, e, new ScopeExp(e.loc, tm));
			de2.type = e.type;
			return de2;
		}

		TemplateDeclaration td = s.isTemplateDeclaration();
		if (td)
		{
			e = new DotTemplateExp(e.loc, e, td);
			e.semantic(sc);
			return e;
		}

		TemplateInstance ti = s.isTemplateInstance();
		if (ti)
		{
			if (!ti.semanticRun)
				ti.semantic(sc);
			s = ti.inst.toAlias();
			if (!s.isTemplateInstance())
				goto L1;
			Expression de2 = new DotExp(e.loc, e, new ScopeExp(e.loc, ti));
			de2.type = e.type;
			return de2;
		}

		Import timp = s.isImport();
		if (timp)
		{
			e = new DsymbolExp(e.loc, s, 0);
			e = e.semantic(sc);
			return e;
		}

		OverloadSet o = s.isOverloadSet();
		if (o)
		{
			/* We really should allow this, triggered by:
			 *   template c()
			 *   {
			 *		void a();
			 *		void b () { this.a(); }
			 *   }
			 *   struct S
			 *   {
			 *		mixin c;
			 *		mixin c;
			 *  }
			 *  alias S e;
			 */
			error(e.loc, "overload set for %s.%s not allowed in struct declaration", e.toChars(), ident.toChars());
			return new ErrorExp();
		}

		d = s.isDeclaration();

	debug {
		if (!d)
			writef("d = %s '%s'\n", s.kind(), s.toChars());
	}
		assert(d);

		if (e.op == TOK.TOKtype)
		{
			FuncDeclaration fd = sc.func;

			if (d.isTupleDeclaration())
			{
				e = new TupleExp(e.loc, d.isTupleDeclaration());
				e = e.semantic(sc);
				return e;
			}

			if (d.needThis() && fd && fd.vthis)
			{
				e = new DotVarExp(e.loc, new ThisExp(e.loc), d);
				e = e.semantic(sc);
				return e;
			}

			return new VarExp(e.loc, d, 1);
		}

		if (d.isDataseg())
		{
			// (e, d)
			accessCheck(e.loc, sc, e, d);
			VarExp ve = new VarExp(e.loc, d);
			e = new CommaExp(e.loc, e, ve);
			e.type = d.type;
			return e;
		}

		if (v)
		{
			if (v.toParent() != sym)
				sym.error(e.loc, "'%s' is not a member", v.toChars());

			// *(&e + offset)
			accessCheck(e.loc, sc, e, d);
static if (false) {
			Expression b = new AddrExp(e.loc, e);
			b.type = e.type.pointerTo();
			b = new AddExp(e.loc, b, new IntegerExp(e.loc, v.offset, Type.tint32));
			b.type = v.type.pointerTo();
			b = new PtrExp(e.loc, b);
			b.type = v.type.addMod(e.type.mod);
			return b;
}
		}

		de = new DotVarExp(e.loc, e, d);
		return de.semantic(sc);
	}

    override uint memalign(uint salign)
	{
		sym.size(Loc(0));		// give error for forward references
		return sym.structalign;
	}

    override Expression defaultInit(Loc loc)
	{
	version (LOGDEFAULTINIT) {
		printf("TypeStruct::defaultInit() '%s'\n", toChars());
	}
		Symbol *s = sym.toInitializer();
		Declaration d = new SymbolDeclaration(sym.loc, s, sym);
		assert(d);
		d.type = this;
		return new VarExp(sym.loc, d);
	}

    /***************************************
     * Use when we prefer the default initializer to be a literal,
     * rather than a global immutable variable.
     */
    override Expression defaultInitLiteral(Loc loc)
    {
	version (LOGDEFAULTINIT) {
        printf("TypeStruct::defaultInitLiteral() '%s'\n", toChars());
    }
        auto structelems = new Expressions();
        structelems.setDim(sym.fields.dim);
        for (size_t j = 0; j < structelems.dim; j++)
        {
	        auto vd = cast(VarDeclaration)(sym.fields[j]);
	        Expression e;
	        if (vd.init)
	            e = vd.init.toExpression();
	        else
	            e = vd.type.defaultInitLiteral(Loc(0));
	        structelems[j] = e;
        }
        auto structinit = new StructLiteralExp(loc, cast(StructDeclaration)sym, structelems);
        // Why doesn't the StructLiteralExp constructor do this, when
        // sym->type != NULL ?
        structinit.type = sym.type;
        return structinit;
    }

    override bool isZeroInit(Loc loc)
	{
		return sym.zeroInit;
	}

    override bool isAssignable()
	{
		/* If any of the fields are const or invariant,
		 * then one cannot assign this struct.
		 */
		for (size_t i = 0; i < sym.fields.dim; i++)
		{
			VarDeclaration v = cast(VarDeclaration)sym.fields[i];
			if (v.isConst() || v.isImmutable())
				return false;
		}
		return true;
	}

    override bool checkBoolean()
	{
		return false;
	}

    override dt_t** toDt(dt_t** pdt)
	{
		sym.toDt(pdt);
		return pdt;
	}

    override MATCH deduceType(Scope sc, Type tparam, TemplateParameters parameters, Objects dedtypes)
	{
		//printf("TypeStruct.deduceType()\n");
		//printf("\tthis.parent   = %s, ", sym.parent.toChars()); print();
		//printf("\ttparam = %d, ", tparam.ty); tparam.print();

		/* If this struct is a template struct, and we're matching
		 * it against a template instance, convert the struct type
		 * to a template instance, too, and try again.
		 */
		TemplateInstance ti = sym.parent.isTemplateInstance();

		if (tparam && tparam.ty == Tinstance)
		{
			if (ti && ti.toAlias() == sym)
			{
				TypeInstance t = new TypeInstance(Loc(0), ti);
				return t.deduceType(sc, tparam, parameters, dedtypes);
			}

			/* Match things like:
			 *  S!(T).foo
			 */
			TypeInstance tpi = cast(TypeInstance)tparam;
			if (tpi.idents.dim)
			{   Identifier id = cast(Identifier)tpi.idents.data[tpi.idents.dim - 1];
				if (id.dyncast() == DYNCAST.DYNCAST_IDENTIFIER && sym.ident.equals(id))
				{
					Type tparent = sym.parent.getType();
					if (tparent)
					{
						/* Slice off the .foo in S!(T).foo
						 */
						tpi.idents.dim--;
						MATCH m = tparent.deduceType(sc, tpi, parameters, dedtypes);
						tpi.idents.dim++;
						return m;
					}
				}
			}
		}

		// Extra check
		if (tparam && tparam.ty == Tstruct)
		{
			TypeStruct tp = cast(TypeStruct)tparam;

			if (sym != tp.sym)
				return MATCHnomatch;
		}
		return Type.deduceType(sc, tparam, parameters, dedtypes);
	}

    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoStructDeclaration(this);
	}

    override bool hasPointers()
	{
        // Probably should cache this information in sym rather than recompute
		StructDeclaration s = sym;

		sym.size(Loc(0));		// give error for forward references
		foreach (VarDeclaration sm; s.fields)
		{
			Declaration d = sm.isDeclaration();
			if (d.storage_class & STC.STCref || d.hasPointers())
				return true;
		}

		return false;
	}

    override MATCH implicitConvTo(Type to)
	{
		MATCH m;

		//printf("TypeStruct.implicitConvTo(%s => %s)\n", toChars(), to.toChars());
		if (ty == to.ty && sym == (cast(TypeStruct)to).sym)
		{
			m = MATCHexact;		// exact match
			if (mod != to.mod)
			{
				if (MODimplicitConv(mod, to.mod))
					m = MATCHconst;
				else
				{	/* Check all the fields. If they can all be converted,
					 * allow the conversion.
					 */
					foreach (VarDeclaration v; sym.fields)
					{
						assert(v && v.storage_class & STCfield);

						// 'from' type
						Type tvf = v.type.addMod(mod);

						// 'to' type
						Type tv = v.type.castMod(to.mod);

						//printf("\t%s => %s, match = %d\n", v.type.toChars(), tv.toChars(), tvf.implicitConvTo(tv));
						if (tvf.implicitConvTo(tv) < MATCHconst)
							return MATCHnomatch;
					}
					m = MATCHconst;
				}
			}
		}
		else if (sym.aliasthis)
		{
			m = MATCHnomatch;
			Declaration d = sym.aliasthis.isDeclaration();
			if (d)
			{
				assert(d.type);
				Type t = d.type.addMod(mod);
				m = t.implicitConvTo(to);
			}
		}
		else
			m = MATCHnomatch;	// no match
		return m;
	}

    override MATCH constConv(Type to)
	{
		if (equals(to))
			return MATCHexact;
		if (ty == to.ty && sym == (cast(TypeStruct)to).sym &&
            MODimplicitConv(mod, to.mod))
			return MATCHconst;
		return MATCHnomatch;
	}

    override Type toHeadMutable()
	{
		assert(false);
	}

version (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState* cms)
	{
		assert(false);
	}
}

    override type* toCtype()
	{
		type* t;
		Symbol* s;

		if (ctype)
			return ctype;

		//printf("TypeStruct.toCtype() '%s'\n", sym.toChars());
		s = symbol_calloc(toStringz(sym.toPrettyChars()));
		s.Sclass = SC.SCstruct;
		s.Sstruct = struct_calloc();
		s.Sstruct.Sflags |= 0;	/// huh?
		s.Sstruct.Salignsize = sym.alignsize;
		s.Sstruct.Sstructalign = cast(ubyte)sym.structalign;
		s.Sstruct.Sstructsize = sym.structsize;

		if (sym.isUnionDeclaration())
			s.Sstruct.Sflags |= STR.STRunion;

		t = type_alloc(TYM.TYstruct);
		t.Ttag = cast(Classsym*)s;		// structure tag name
		t.Tcount++;
		s.Stype = t;
		slist_add(s);
		ctype = t;

		/* Add in fields of the struct
		 * (after setting ctype to avoid infinite recursion)
		 */
		if (global.params.symdebug) {
			for (int i = 0; i < sym.fields.dim; i++)
			{
				VarDeclaration v = cast(VarDeclaration)sym.fields[i];

				Symbol* s2 = symbol_name(toStringz(v.ident.toChars()), SC.SCmember, v.type.toCtype());
				s2.Smemoff = v.offset;
				list_append(&s.Sstruct.Sfldlst, s2);
			}
		}

		//printf("t = %p, Tflags = x%x\n", t, t.Tflags);
		return t;
	}
}
