module dmd.DsymbolExp;

import dmd.common;
import dmd.Expression;
import dmd.OutBuffer;
import dmd.EnumMember;
import dmd.VarDeclaration;
import dmd.FuncDeclaration;
import dmd.FuncLiteralDeclaration;
import dmd.OverloadSet;
import dmd.Declaration;
import dmd.ClassDeclaration;
import dmd.Import;
import dmd.Package;
import dmd.Type;
import dmd.DotVarExp;
import dmd.ThisExp;
import dmd.VarExp;
import dmd.FuncExp;
import dmd.OverExp;
import dmd.DotTypeExp;
import dmd.STC;
import dmd.ScopeExp;
import dmd.Module;
import dmd.TypeExp;
import dmd.TupleDeclaration;
import dmd.TupleExp;
import dmd.TemplateInstance;
import dmd.Global;
import dmd.TemplateDeclaration;
import dmd.TemplateExp;
import dmd.Loc;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Dsymbol;
import dmd.TOK;
import dmd.ErrorExp;

import dmd.DDMDExtensions;

class DsymbolExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Dsymbol s;
	bool hasOverloads;

	this(Loc loc, Dsymbol s, bool hasOverloads = false)
	{
		register();
		super(loc, TOK.TOKdsymbol, DsymbolExp.sizeof);
		this.s = s;
		this.hasOverloads = hasOverloads;
	}

	override Expression semantic(Scope sc)
	{
version (LOGSEMANTIC)
{
		printf("DsymbolExp.semantic('%s')\n", s.toChars());
}

	Lagain:
		EnumMember em;
		Expression e;
		VarDeclaration v;
		FuncDeclaration f;
		FuncLiteralDeclaration fld;
		OverloadSet o;
		Declaration d;
		ClassDeclaration cd;
		ClassDeclaration thiscd = null;
		Import imp;
		Package pkg;
		Type t;

		//printf("DsymbolExp. %p '%s' is a symbol\n", this, toChars());
		//printf("s = '%s', s.kind = '%s'\n", s.toChars(), s.kind());
		if (type)
			return this;

		if (!s.isFuncDeclaration())	// functions are checked after overloading
			checkDeprecated(sc, s);

		s = s.toAlias();
		//printf("s = '%s', s.kind = '%s', s.needThis() = %p\n", s.toChars(), s.kind(), s.needThis());
		if (!s.isFuncDeclaration())
			checkDeprecated(sc, s);

		if (sc.func)
			thiscd = sc.func.parent.isClassDeclaration();

		// BUG: This should happen after overload resolution for functions, not before
		if (s.needThis())
		{
version (DMDV2) {
			bool cond = !s.isFuncDeclaration();
} else {
			bool cond = true;
}
			if (hasThis(sc) && cond)
			{
				// Supply an implicit 'this', as in
				//	  this.ident
				DotVarExp de = new DotVarExp(loc, new ThisExp(loc), s.isDeclaration());
				return de.semantic(sc);
			}
		}

		em = s.isEnumMember();
		if (em)
		{
			e = em.value;
			e = e.semantic(sc);
			return e;
		}
		v = s.isVarDeclaration();
		if (v)
		{
			//printf("Identifier '%s' is a variable, type '%s'\n", toChars(), v.type.toChars());
			if (!type)
			{   
				type = v.type;
				if (!v.type)
				{
					error("forward reference of %s %s", v.kind(), v.toChars());
					type = Type.terror;
				}
			}

			if ((v.storage_class & STC.STCmanifest) && v.init)
			{
				e = v.init.toExpression();
	            if (!e)
				{   
					error("cannot make expression out of initializer for %s", v.toChars());
					e = new ErrorExp();
				}
				e = e.semantic(sc);
				return e;
			}

			e = new VarExp(loc, v);
			e.type = type;
			e = e.semantic(sc);
			return e.deref();
		}

		fld = s.isFuncLiteralDeclaration();
		if (fld)
		{	
			//printf("'%s' is a function literal\n", fld.toChars());
			e = new FuncExp(loc, fld);
			return e.semantic(sc);
		}
		f = s.isFuncDeclaration();
		if (f)
		{	
			//printf("'%s' is a function\n", f.toChars());

			if (!f.type.deco)
			{
				error("forward reference to %s", toChars());
				return new ErrorExp();
			}
			return new VarExp(loc, f, hasOverloads);
		}
		o = s.isOverloadSet();
		if (o)
		{	
			//printf("'%s' is an overload set\n", o.toChars());
			return new OverExp(o);
		}
		cd = s.isClassDeclaration();
		if (cd && thiscd && cd.isBaseOf(thiscd, null) && sc.func.needThis())
		{
			// We need to add an implicit 'this' if cd is this class or a base class.
			DotTypeExp dte = new DotTypeExp(loc, new ThisExp(loc), s);
			return dte.semantic(sc);
		}
		imp = s.isImport();
		if (imp)
		{
			if (!imp.pkg)
			{   
				error("forward reference of import %s", imp.toChars());
				return this;
			}
			ScopeExp ie = new ScopeExp(loc, imp.pkg);
			return ie.semantic(sc);
		}
		pkg = s.isPackage();
		if (pkg)
		{
			ScopeExp ie = new ScopeExp(loc, pkg);
			return ie.semantic(sc);
		}
		Module mod = s.isModule();
		if (mod)
		{
			ScopeExp ie = new ScopeExp(loc, mod);
			return ie.semantic(sc);
		}

		t = s.getType();
		if (t)
		{
			return new TypeExp(loc, t);
		}

		TupleDeclaration tup = s.isTupleDeclaration();
		if (tup)
		{
			e = new TupleExp(loc, tup);
			e = e.semantic(sc);
			return e;
		}

		TemplateInstance ti = s.isTemplateInstance();
		if (ti && !global.errors)
		{   
			if (!ti.semanticRun)
				ti.semantic(sc);

			s = ti.inst.toAlias();
			if (!s.isTemplateInstance())
				goto Lagain;

			e = new ScopeExp(loc, ti);
			e = e.semantic(sc);
			return e;
		}

		TemplateDeclaration td = s.isTemplateDeclaration();
		if (td)
		{
			e = new TemplateExp(loc, td);
			e = e.semantic(sc);
			return e;
		}

	Lerr:
		error("%s '%s' is not a variable", s.kind(), s.toChars());
		type = Type.terror;
		return this;
	}

	override string toChars()
	{
		assert(false);
	}

	override void dump(int indent)
	{
		assert(false);
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

	override bool isLvalue()
	{
		assert(false);
	}

	override Expression toLvalue(Scope sc, Expression e)
	{
		assert(false);
	}
}

