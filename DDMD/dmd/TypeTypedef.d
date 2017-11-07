module dmd.TypeTypedef;

import dmd.common;
import dmd.Type;
import dmd.TypedefDeclaration;
import dmd.MOD;
import dmd.Loc;
import dmd.Id;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.Identifier;
import dmd.ArrayTypes;
import dmd.MATCH;
import dmd.TypeSArray;
import dmd.CppMangleState;
import dmd.TypeInfoDeclaration;
import dmd.TypeInfoTypedefDeclaration;
import dmd.TY;

import dmd.backend.TYPE;
import dmd.backend.dt_t;

import dmd.DDMDExtensions;

class TypeTypedef : Type
{
	mixin insertMemberExtension!(typeof(this));

    TypedefDeclaration sym;

    this(TypedefDeclaration sym)
	{
		register();
		super(Ttypedef);
		this.sym = sym;
	}
	
    override Type syntaxCopy()
	{
		assert(false);
	}
	
    override ulong size(Loc loc)
	{
		return sym.basetype.size(loc);
	}
	
    override uint alignsize()
	{
		assert(false);
	}
	
    override string toChars()
	{
		assert(false);
	}
	
    override Type semantic(Loc loc, Scope sc)
	{
		//printf("TypeTypedef::semantic(%s), sem = %d\n", toChars(), sym->sem);
		sym.semantic(sc);
		return merge();
	}
	
    override Dsymbol toDsymbol(Scope sc)
	{
		return sym;
	}
	
    override void toDecoBuffer(OutBuffer buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		string name = sym.mangle();
		buf.printf("%s", name);
	}
	
    override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		//printf("TypeTypedef.toCBuffer2() '%s'\n", sym.toChars());
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
		printf("TypeTypedef.dotExp(e = '%s', ident = '%s') '%s'\n", e.toChars(), ident.toChars(), toChars());
	}
		if (ident is Id.init_)
		{
			return Type.dotExp(sc, e, ident);
		}
		return sym.basetype.dotExp(sc, e, ident);
	}
	
    override Expression getProperty(Loc loc, Identifier ident)
	{
version (LOGDOTEXP) {
		printf("TypeTypedef.getProperty(ident = '%s') '%s'\n", ident.toChars(), toChars());
}
		if (ident == Id.init_)
		{
			return Type.getProperty(loc, ident);
		}
		return sym.basetype.getProperty(loc, ident);
	}
	
    bool isbit()
	{
		assert(false);
	}
	
    override bool isintegral()
	{
		//printf("TypeTypedef::isintegral()\n");
		//printf("sym = '%s'\n", sym->toChars());
		//printf("basetype = '%s'\n", sym->basetype->toChars());
		return sym.basetype.isintegral();
	}
	
    override bool isfloating()
	{
		return sym.basetype.isfloating();
	}
	
    override bool isreal()
	{
		return sym.basetype.isreal();
	}
	
    override bool isimaginary()
	{
		return sym.basetype.isimaginary();
	}
	
    override bool iscomplex()
	{
		return sym.basetype.iscomplex();
	}
	
    override bool isscalar()
	{
		return sym.basetype.isscalar();
	}
	
    override bool isunsigned()
	{
		return sym.basetype.isunsigned();
	}
	
    override bool checkBoolean()
	{
		return sym.basetype.checkBoolean();
	}
	
    override bool isAssignable()
	{
		return sym.basetype.isAssignable();
	}
	
    override Type toBasetype()
	{
		if (sym.inuse)
		{
			sym.error("circular definition");
			sym.basetype = Type.terror;
			return Type.terror;
		}
		sym.inuse = 1;
		Type t = sym.basetype.toBasetype();
		sym.inuse = 0;
		t = t.addMod(mod);
		return t;
	}
	
    override MATCH implicitConvTo(Type to)
	{
		MATCH m;

		//printf("TypeTypedef::implicitConvTo(to = %s) %s\n", to->toChars(), toChars());
		if (equals(to))
			m = MATCHexact;		// exact match
		else if (sym.basetype.implicitConvTo(to))
			m = MATCHconvert;	// match with conversions
		else if (ty == to.ty && sym == (cast(TypeTypedef)to).sym)
		{
			m = constConv(to);
		}
		else
			m = MATCHnomatch;	// no match
		return m;
	}
	
    override MATCH constConv(Type to)
	{
		if (equals(to))
			return MATCHexact;
		if (ty == to.ty && sym == (cast(TypeTypedef)to).sym)
			return sym.basetype.implicitConvTo((cast(TypeTypedef)to).sym.basetype);
		return MATCHnomatch;
	}
	
    override Expression defaultInit(Loc loc)
	{
	version (LOGDEFAULTINIT) {
		printf("TypeTypedef::defaultInit() '%s'\n", toChars());
	}
		if (sym.init)
		{
			//sym->init->toExpression()->print();
			return sym.init.toExpression();
		}
		Type bt = sym.basetype;
		Expression e = bt.defaultInit(loc);
		e.type = this;
		while (bt.ty == Tsarray)
		{	
			TypeSArray tsa = cast(TypeSArray)bt;
			e.type = tsa.next;
			bt = tsa.next.toBasetype();
		}
		return e;
	}

    override bool isZeroInit(Loc loc)
	{
		if (sym.init)
		{
			if (sym.init.isVoidInitializer())
				return true;		// initialize voids to 0
			Expression e = sym.init.toExpression();
			if (e && e.isBool(false))
				return true;

			return false;		// assume not
		}
		if (sym.inuse)
		{
			sym.error("circular definition");
			sym.basetype = Type.terror;
		}
		sym.inuse = 1;
		bool result = sym.basetype.isZeroInit(loc);
		sym.inuse = 0;

		return result;
	}
	
    override dt_t** toDt(dt_t** pdt)
	{
		if (sym.init)
		{
			dt_t* dt = sym.init.toDt();

			while (*pdt)
				pdt = &((*pdt).DTnext);
			*pdt = dt;
			return pdt;
		}

		sym.basetype.toDt(pdt);
		return pdt;
	}
	
    override MATCH deduceType(Scope sc, Type tparam, TemplateParameters parameters, Objects dedtypes)
	{
		// Extra check
		if (tparam && tparam.ty == Ttypedef)
		{
			TypeTypedef tp = cast(TypeTypedef)tparam;

			if (sym != tp.sym)
				return MATCHnomatch;
		}
		return Type.deduceType(sc, tparam, parameters, dedtypes);
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoTypedefDeclaration(this);
	}
	
    override bool hasPointers()
	{
		return toBasetype().hasPointers();
	}
	
    override int hasWild()
    {
        return mod & MOD.MODwild || toBasetype().hasWild();
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
		return sym.basetype.toCtype();
	}
	
    override type* toCParamtype()
	{
		return sym.basetype.toCParamtype();
	}
}
