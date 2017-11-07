module dmd.TypeClass;

import dmd.common;
import dmd.Type;
import dmd.ClassDeclaration;
import dmd.TypeInstance;
import dmd.Loc;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.Identifier;
import dmd.MATCH;
import dmd.DYNCAST;
import dmd.CppMangleState;
import dmd.ArrayTypes;
import dmd.TypeInfoDeclaration;
import dmd.TY;
import dmd.MOD;
import dmd.Global;
import dmd.TypePointer;
import dmd.Declaration;
import dmd.VarDeclaration;
import dmd.TOK;
import dmd.DotExp;
import dmd.Id;
import dmd.ScopeExp;
import dmd.DotVarExp;
import dmd.VarExp;
import dmd.PtrExp;
import dmd.AddExp;
import dmd.IntegerExp;
import dmd.DotIdExp;
import dmd.EnumMember;
import dmd.TemplateMixin;
import dmd.TemplateDeclaration;
import dmd.TemplateInstance;
import dmd.OverloadSet;
import dmd.DotTypeExp;
import dmd.TupleExp;
import dmd.ClassInfoDeclaration;
import dmd.TypeInfoInterfaceDeclaration;
import dmd.TypeInfoClassDeclaration;
import dmd.Util;
import dmd.NullExp;
import dmd.TypeExp;
import dmd.DotTemplateExp;
import dmd.ErrorExp;
import dmd.ThisExp;
import dmd.CommaExp;

import dmd.expression.Util;
import dmd.backend.Symbol;
import dmd.backend.TYPE;
import dmd.backend.Util;
import dmd.backend.SC;
import dmd.backend.STR;
import dmd.backend.TYM;
import dmd.backend.LIST;
import dmd.backend.Classsym;

import std.string : toStringz;

import dmd.DDMDExtensions;

class TypeClass : Type
{
	mixin insertMemberExtension!(typeof(this));

    ClassDeclaration sym;

    this(ClassDeclaration sym)
	{
		register();
		super(TY.Tclass);
		this.sym = sym;
	}

    override ulong size(Loc loc)
	{
		return PTRSIZE;
	}
	
    override string toChars()
	{
		if (mod)
			return Type.toChars();
		return sym.toPrettyChars();
	}
	
    override Type syntaxCopy()
	{
		assert(false);
	}
	
    override Type semantic(Loc loc, Scope sc)
	{
		//printf("TypeClass.semantic(%s)\n", sym.toChars());
		if (deco)
			return this;
		//printf("\t%s\n", merge().deco);
		return merge();
	}
	
    override Dsymbol toDsymbol(Scope sc)
	{
		return sym;
	}
	
    override void toDecoBuffer(OutBuffer buf, int flag)
	{
		string name = sym.mangle();
		//printf("TypeClass.toDecoBuffer('%s' flag=%d mod=%x) = '%s'\n", toChars(), flag, mod, name);
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
		buf.writestring(sym.toChars());
	}

    override Expression dotExp(Scope sc, Expression e, Identifier ident)
	{
		uint offset;

		Expression b;
		VarDeclaration v;
		Dsymbol s;

version (LOGDOTEXP) {
		printf("TypeClass.dotExp(e='%s', ident='%s')\n", e.toChars(), ident.toChars());
}

		if (e.op == TOK.TOKdotexp)
		{
			DotExp de = cast(DotExp)e;

			if (de.e1.op == TOK.TOKimport)
			{
				ScopeExp se = cast(ScopeExp)de.e1;

				s = se.sds.search(e.loc, ident, 0);
				e = de.e1;
				goto L1;
			}
		}

		if (ident is Id.tupleof_)
		{
			/* Create a TupleExp
			 */
			e = e.semantic(sc);	// do this before turning on noaccesscheck
			Expressions exps = new Expressions;
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

		s = sym.search(e.loc, ident, 0);
	L1:
		if (!s)
		{
			// See if it's a base class
			ClassDeclaration cbase;
			for (cbase = sym.baseClass; cbase; cbase = cbase.baseClass)
			{
				if (cbase.ident.equals(ident))
				{
					e = new DotTypeExp(Loc(0), e, cbase);
					return e;
				}
			}

			if (ident is Id.classinfo_)
			{
				assert(global.classinfo);
				Type t = global.classinfo.type;
				if (e.op == TOK.TOKtype || e.op == TOK.TOKdottype)
				{
					/* For type.classinfo, we know the classinfo
					 * at compile time.
					 */
					if (!sym.vclassinfo)
						sym.vclassinfo = new TypeInfoClassDeclaration(sym.type);

					e = new VarExp(e.loc, sym.vclassinfo);
					e = e.addressOf(sc);
					e.type = t;	// do this so we don't get redundant dereference
				}
				else
				{	
					/* For class objects, the classinfo reference is the first
					 * entry in the vtbl[]
					 */
					e = new PtrExp(e.loc, e);
					e.type = t.pointerTo();
					if (sym.isInterfaceDeclaration())
					{
						if (sym.isCPPinterface())
						{	
							/* C++ interface vtbl[]s are different in that the
							 * first entry is always pointer to the first virtual
							 * function, not classinfo.
							 * We can't get a .classinfo for it.
							 */
							error(e.loc, "no .classinfo for C++ interface objects");
						}
						/* For an interface, the first entry in the vtbl[]
						 * is actually a pointer to an instance of struct Interface.
						 * The first member of Interface is the .classinfo,
						 * so add an extra pointer indirection.
						 */
						e.type = e.type.pointerTo();
						e = new PtrExp(e.loc, e);
						e.type = t.pointerTo();
					}
					e = new PtrExp(e.loc, e, t);
				}
				return e;
			}

			if (ident is Id.__vptr)
			{   
				/* The pointer to the vtbl[]
				 * *cast(invariant(void*)**)e
				 */
				e = e.castTo(sc, global.tvoidptr.invariantOf().pointerTo().pointerTo());
				e = new PtrExp(e.loc, e);
				e = e.semantic(sc);
				return e;
			}

			if (ident is Id.__monitor)
			{   /* The handle to the monitor (call it a void*)
				 * *(cast(void**)e + 1)
				 */
				e = e.castTo(sc, global.tvoidptr.pointerTo());
				e = new AddExp(e.loc, e, new IntegerExp(1));
				e = new PtrExp(e.loc, e);
				e = e.semantic(sc);
				return e;
			}

			if (ident is Id.typeinfo_)
			{
				if (!global.params.useDeprecated)
					error(e.loc, ".typeinfo deprecated, use typeid(type)");

				return getTypeInfo(sc);
			}
			if (ident is Id.outer && sym.vthis)
			{
				s = sym.vthis;
			}
			else
			{
				return noMember(sc, e, ident);
			}
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
		//	if (e.op == TOKtype)
				return new TypeExp(e.loc, s.getType());
		//	return new DotTypeExp(e.loc, e, s);
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
			Expression de = new DotExp(e.loc, e, new ScopeExp(e.loc, tm));
			de.type = e.type;
			return de;
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
			Expression de = new DotExp(e.loc, e, new ScopeExp(e.loc, ti));
			de.type = e.type;
			return de;
		}

		OverloadSet o = s.isOverloadSet();
		if (o)
		{	
			/* We really should allow this
			 */
			error(e.loc, "overload set for %s.%s not allowed in struct declaration", e.toChars(), ident.toChars());
			return new ErrorExp();
		}

		Declaration d = s.isDeclaration();
		if (!d)
		{
			e.error("%s.%s is not a declaration", e.toChars(), ident.toChars());
			return new ErrorExp();
		}

		if (e.op == TOK.TOKtype)
		{
			/* It's:
			 *    Class.d
			 */
			if (d.isTupleDeclaration())
			{
				e = new TupleExp(e.loc, d.isTupleDeclaration());
				e = e.semantic(sc);
				return e;
			}
			else if (d.needThis() && (hasThis(sc) || !(sc.intypeof || d.isFuncDeclaration())))
			{
				if (sc.func)
				{
					ClassDeclaration thiscd;
					thiscd = sc.func.toParent().isClassDeclaration();

					if (thiscd)
					{
						ClassDeclaration cd = e.type.isClassHandle();

						if (cd is thiscd)
						{
							e = new ThisExp(e.loc);
							e = new DotTypeExp(e.loc, e, cd);
							DotVarExp de = new DotVarExp(e.loc, e, d);
							e = de.semantic(sc);
							return e;
						}
						else if ((!cd || !cd.isBaseOf(thiscd, null)) && !d.isFuncDeclaration())
							e.error("'this' is required, but %s is not a base class of %s", e.type.toChars(), thiscd.toChars());
					}
				}

				/* Rewrite as:
				 *	this.d
				 */
				DotVarExp de = new DotVarExp(e.loc, new ThisExp(e.loc), d);
				e = de.semantic(sc);
				return e;
			}
			else
			{
				VarExp ve = new VarExp(e.loc, d, 1);
				return ve;
			}
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

		if (d.parent && d.toParent().isModule())
		{
			// (e, d)
			VarExp ve = new VarExp(e.loc, d, 1);
			e = new CommaExp(e.loc, e, ve);
			e.type = d.type;
			return e;
		}

		DotVarExp de = new DotVarExp(e.loc, e, d);
		return de.semantic(sc);
	}
	
    override ClassDeclaration isClassHandle()
	{
		return sym;
	}
	
    override bool isBaseOf(Type t, int* poffset)
	{
		if (t.ty == Tclass)
		{   
			ClassDeclaration cd;

			cd   = (cast(TypeClass)t).sym;
			if (sym.isBaseOf(cd, poffset))
				return true;
		}
		
		return false;
	}
	
    override MATCH implicitConvTo(Type to)
	{
		//printf("TypeClass.implicitConvTo(to = '%s') %s\n", to.toChars(), toChars());
		MATCH m = constConv(to);
		if (m != MATCH.MATCHnomatch)
			return m;

		ClassDeclaration cdto = to.isClassHandle();
		if (cdto && cdto.isBaseOf(sym, null))
		{	
			//printf("'to' is base\n");
			return MATCH.MATCHconvert;
		}

		if (global.params.Dversion == 1)
		{
			// Allow conversion to (void *)
			if (to.ty == TY.Tpointer && (cast(TypePointer)to).next.ty == TY.Tvoid)
				return MATCH.MATCHconvert;
		}

		m = MATCH.MATCHnomatch;
		if (sym.aliasthis)
		{
			Declaration d = sym.aliasthis.isDeclaration();
			if (d)
			{   
				assert(d.type);
				Type t = d.type.addMod(mod);
				m = t.implicitConvTo(to);
			}
		}

		return m;
	}
	
    override Expression defaultInit(Loc loc)
	{
version (LOGDEFAULTINIT) {
		printf("TypeClass::defaultInit() '%s'\n", toChars());
}
		return new NullExp(loc, this);
	}
	
    override bool isZeroInit(Loc loc)
	{
		return true;
	}
	
    override MATCH deduceType(Scope sc, Type tparam, TemplateParameters parameters, Objects dedtypes)
	{
		//printf("TypeClass.deduceType(this = %s)\n", toChars());

		/* If this class is a template class, and we're matching
		 * it against a template instance, convert the class type
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
		if (tparam && tparam.ty == Tclass)
		{
			TypeClass tp = cast(TypeClass)tparam;

			//printf("\t%d\n", (MATCH) implicitConvTo(tp));
			return implicitConvTo(tp);
		}
		return Type.deduceType(sc, tparam, parameters, dedtypes);
	}
	
    override bool isauto()
	{
		return sym.isauto;
	}
	
    override bool checkBoolean()
	{
		return true;
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		if (sym.isInterfaceDeclaration())
			return new TypeInfoInterfaceDeclaration(this);
		else
			return new TypeInfoClassDeclaration(this);
	}
	
    override bool hasPointers()
	{
		return true;
	}
	
    override bool builtinTypeInfo()
	{
		/* This is statically put out with the ClassInfo, so
		 * claim it is built in so it isn't regenerated by each module.
		 */
	version (DMDV2) {
		return mod ? false : true;
	} else {
		return true;
	}
	}
	
version (DMDV2) {
    override Type toHeadMutable()
	{
		assert(false);
	}
	
    override MATCH constConv(Type to)
	{
		if (equals(to))
			return MATCH.MATCHexact;

		if (ty == to.ty && sym == (cast(TypeClass)to).sym && to.mod == MOD.MODconst)
			return MATCH.MATCHconst;

		return MATCH.MATCHnomatch;
	}
	
version (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState* cms)
	{
		assert(false);
	}
}
}

    override type* toCtype()
	{
		type* t;
		Symbol* s;

		//printf("TypeClass.toCtype() %s\n", toChars());
		if (ctype)
			return ctype;

		/* Need this symbol to do C++ name mangling
		 */
		string name = sym.isCPPinterface() ? sym.ident.toChars() : sym.toPrettyChars();
		s = symbol_calloc(toStringz(name));
		s.Sclass = SC.SCstruct;
		s.Sstruct = struct_calloc();
		s.Sstruct.Sflags |= STR.STRclass;
		s.Sstruct.Salignsize = sym.alignsize;
		s.Sstruct.Sstructalign = cast(ubyte)sym.structalign;
		s.Sstruct.Sstructsize = sym.structsize;

		t = type_alloc(TYM.TYstruct);
		t.Ttag = cast(Classsym*)s;		// structure tag name
		t.Tcount++;
		s.Stype = t;
		slist_add(s);

		t = type_allocn(TYM.TYnptr, t);

		t.Tcount++;
		ctype = t;

		/* Add in fields of the class
		 * (after setting ctype to avoid infinite recursion)
		 */
		if (global.params.symdebug)
			for (int i = 0; i < sym.fields.dim; i++)
			{   
				VarDeclaration v = cast(VarDeclaration)sym.fields[i];

				Symbol* s2 = symbol_name(toStringz(v.ident.toChars()), SC.SCmember, v.type.toCtype());
				s2.Smemoff = v.offset;
				list_append(&s.Sstruct.Sfldlst, s2);
			}

		return t;
	}
	
    override Symbol* toSymbol()
	{
		return sym.toSymbol();
	}
}
