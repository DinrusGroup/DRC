module dmd.TypeEnum;

import dmd.common;
import dmd.Type;
import dmd.EnumDeclaration;
import dmd.Scope;
import dmd.Loc;
import dmd.Id;
import dmd.ErrorExp;
import dmd.Dsymbol;
import dmd.EnumMember;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.Identifier;
import dmd.MATCH;
import dmd.OutBuffer;
import dmd.CppMangleState;
import dmd.StringExp;
import dmd.TypeInfoDeclaration;
import dmd.TypeInfoEnumDeclaration;
import dmd.ArrayTypes;
import dmd.TY;
import dmd.MOD;
import dmd.Util;

import dmd.backend.TYPE;

import dmd.DDMDExtensions;

class TypeEnum : Type
{
	mixin insertMemberExtension!(typeof(this));

    EnumDeclaration sym;

    this(EnumDeclaration sym)
	{
		register();
		super(TY.Tenum);
		this.sym = sym;
	}
	
    override Type syntaxCopy()
	{
		assert(false);
	}
	
    override ulong size(Loc loc)
	{
		if (!sym.memtype)
		{
			error(loc, "enum %s is forward referenced", sym.toChars());
			return 4;
		}
		return sym.memtype.size(loc);
	}
	
	override uint alignsize()
	{
		if (!sym.memtype)
		{
			debug writef("1: ");

			error(Loc(0), "enum %s is forward referenced", sym.toChars());
			return 4;
		}
		return sym.memtype.alignsize();
	}

	override string toChars()
	{
		if (mod)
			return super.toChars();
		return sym.toChars();
	}
	
    override Type semantic(Loc loc, Scope sc)
	{
		//printf("TypeEnum::semantic() %s\n", toChars());
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
	version (LOGDOTEXP) {
		printf("TypeEnum::dotExp(e = '%s', ident = '%s') '%s'\n", e.toChars(), ident.toChars(), toChars());
	}
		Dsymbol s = sym.search(e.loc, ident, 0);
		if (!s)
		{
			if (ident is Id.max ||
				ident is Id.min ||
				ident is Id.init_ ||
				ident is Id.stringof_ ||
				!sym.memtype
			   )
			{
				return getProperty(e.loc, ident);
			}

			return sym.memtype.dotExp(sc, e, ident);
		}

		EnumMember m = s.isEnumMember();
		Expression em = m.value.copy();
		em.loc = e.loc;
		return em;
	}
	
	override Expression getProperty(Loc loc, Identifier ident)
	{
		Expression e;

		if (ident is Id.max)
		{
			if (!sym.maxval)
				goto Lfwd;
			e = sym.maxval;
		}
		else if (ident is Id.min)
		{
			if (!sym.minval)
				goto Lfwd;
			e = sym.minval;
		}
		else if (ident is Id.init_)
		{
			e = defaultInitLiteral(loc);
		}
		else if (ident is Id.stringof_)
		{
			string s = toChars();
			e = new StringExp(loc, s, 'c');
			Scope sc;
			e = e.semantic(sc);
		}
		else if (ident is Id.mangleof_)
		{
			e = Type.getProperty(loc, ident);
		}
		else
		{
			e = toBasetype().getProperty(loc, ident);
		}
		return e;

	Lfwd:
		error(loc, "forward reference of %s.%s", toChars(), ident.toChars());
		return new ErrorExp();
	}
	
    override bool isintegral()
	{
	    return sym.memtype.isintegral();
	}
	
    override bool isfloating()
	{
	    return sym.memtype.isfloating();
	}
	
    override bool isreal()
	{
		return sym.memtype.isreal();
	}
	
    override bool isimaginary()
	{
		return sym.memtype.isimaginary();
	}
	
    override bool iscomplex()
	{
		return sym.memtype.iscomplex();
	}
	
    override bool checkBoolean()
	{
		return sym.memtype.checkBoolean();
	}
	
    override bool isAssignable()
	{
		return sym.memtype.isAssignable();
	}
	
    override bool isscalar()
	{
	    return sym.memtype.isscalar();
	}
	
    override bool isunsigned()
	{
		return sym.memtype.isunsigned();
	}
	
    override MATCH implicitConvTo(Type to)
	{
		MATCH m;

		//printf("TypeEnum::implicitConvTo()\n");
		if (ty == to.ty && sym == (cast(TypeEnum)to).sym)
			m = (mod == to.mod) ? MATCHexact : MATCHconst;
		else if (sym.memtype.implicitConvTo(to))
			m = MATCHconvert;	// match with conversions
		else
			m = MATCHnomatch;	// no match
		return m;
	}
	
    override MATCH constConv(Type to)
	{
        if (equals(to))
	        return MATCHexact;
        if (ty == to.ty && sym == (cast(TypeEnum)to).sym &&
	        MODimplicitConv(mod, to.mod))
	        return MATCHconst;
        return MATCHnomatch;
	}
	
    override Type toBasetype()
	{
        if (sym.scope_)
        {
			// Enum is forward referenced. We don't need to resolve the whole thing,
			// just the base type
			if (sym.memtype)
			{   
				sym.memtype = sym.memtype.semantic(sym.loc, sym.scope_);
			}
			else
			{   
				if (!sym.isAnonymous())
					sym.memtype = Type.tint32;
			}
        }
		if (!sym.memtype)
		{
			debug writef("2: ");
			error(sym.loc, "enum %s is forward referenced", sym.toChars());
			return tint32;
		}

		return sym.memtype.toBasetype();
	}
	
    override Expression defaultInit(Loc loc)
	{
	version (LOGDEFAULTINIT) {
		printf("TypeEnum::defaultInit() '%s'\n", toChars());
	}
		// Initialize to first member of enum
		//printf("%s\n", sym.defaultval.type.toChars());
		if (!sym.defaultval)
		{
			error(loc, "forward reference of %s.init", toChars());
			return new ErrorExp();
		}
		return sym.defaultval;
	}
	
    override bool isZeroInit(Loc loc)
	{
		if (!sym.defaultval)
		{
			debug writef("3: ");
			error(loc, "enum %s is forward referenced", sym.toChars());
			return 0;
		}
		return sym.defaultval.isBool(false);
	}
	
	override MATCH deduceType(Scope sc, Type tparam, TemplateParameters parameters, Objects dedtypes)
	{
		// Extra check
		if (tparam && tparam.ty == Tenum)
		{
			TypeEnum tp = cast(TypeEnum)tparam;

			if (sym != tp.sym)
				return MATCHnomatch;
		}
		return Type.deduceType(sc, tparam, parameters, dedtypes);
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoEnumDeclaration(this);
	}
	
    override bool hasPointers()
	{
		return toBasetype().hasPointers();
	}
	
version (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState* cms)
	{
		assert(false);
	}
}

    override type* toCtype()
	{
		return sym.memtype.toCtype();
	}
}
