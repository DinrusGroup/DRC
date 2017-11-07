module dmd.EnumDeclaration;

import dmd.common;
import dmd.ScopeDsymbol;
import dmd.AddExp;
import dmd.Type;
import dmd.CmpExp;
import dmd.IntegerExp;
import dmd.EqualExp;
import dmd.TOK;
import dmd.Id;
import dmd.TY;
import dmd.DsymbolTable;
import dmd.STC;
import dmd.Expression;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Global;
import dmd.Loc;
import dmd.Module;
import dmd.TypeEnum;
import dmd.EnumMember;
import dmd.DYNCAST;
import dmd.WANT;
import dmd.Id;
import dmd.Json;
import dmd.Lexer;

import dmd.backend.SC;
import dmd.backend.FL;
import dmd.backend.Util;
import dmd.backend.Symbol;
import dmd.backend.Classsym;
import dmd.backend.SFL;
import dmd.backend.LIST;
import dmd.codegen.Util;

import std.stdio : writef;

import dmd.DDMDExtensions;

class EnumDeclaration : ScopeDsymbol
{
	mixin insertMemberExtension!(typeof(this));

   /* enum ident : memtype { ... }
     */
    Type type;			// the TypeEnum
    Type memtype;		// type of the members

version (DMDV1)
{
    ulong maxval;
    ulong minval;
    ulong defaultval;	// default initializer
}
else
{
    Expression maxval;
    Expression minval;
    Expression defaultval;	// default initializer
}
	bool isdeprecated = false;
	bool isdone = false;	// 0: not done
							// 1: semantic() successfully completed
    
    this(Loc loc, Identifier id, Type memtype)
	{
		register();
		super(id);
		this.loc = loc;
		type = new TypeEnum(this);
		this.memtype = memtype;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
	    Type t = null;
	    if (memtype)
		t = memtype.syntaxCopy();

	    EnumDeclaration ed;
	    if (s)
	    {	ed = cast(EnumDeclaration)s;
		ed.memtype = t;
	    }
	    else
		ed = new EnumDeclaration(loc, ident, t);
	    ScopeDsymbol.syntaxCopy(ed);
	    return ed;
	}
	
    override void semantic(Scope sc)
	{
		Type t;
		Scope sce;

		//writef("EnumDeclaration.semantic(sd = %p, '%s') %s\n", sc.scopesym, sc.scopesym.toChars(), toChars());
		//writef("EnumDeclaration.semantic() %s\n", toChars());
		if (!members)		// enum ident;
			return;

		if (!memtype && !isAnonymous())
		{	
			// Set memtype if we can to reduce fwd reference errors
			memtype = Type.tint32;	// case 1)  enum ident { ... }
		}

		if (symtab)			// if already done
		{	
			if (isdone || !scope_)
				return;		// semantic() already completed
		}
		else
			symtab = new DsymbolTable();

		Scope scx = null;
		if (scope_)
		{   sc = scope_;
			scx = scope_;            // save so we don't make redundant copies
			scope_ = null;
		}
		
	    uint dprogress_save = global.dprogress;

		if (sc.stc & STC.STCdeprecated)
			isdeprecated = true;

		parent = sc.parent;

		/* The separate, and distinct, cases are:
		 *  1. enum { ... }
		 *  2. enum : memtype { ... }
		 *  3. enum ident { ... }
		 *  4. enum ident : memtype { ... }
		 */

		if (memtype)
		{
			memtype = memtype.semantic(loc, sc);

			/* Check to see if memtype is forward referenced
			 */
			if (memtype.ty == TY.Tenum)
			{   EnumDeclaration sym = cast(EnumDeclaration)memtype.toDsymbol(sc);
				if (!sym.memtype || !sym.members || !sym.symtab || sym.scope_)
				{	
					// memtype is forward referenced, so try again later
					scope_ = scx ? scx : sc.clone();
					scope_.setNoFree();
					scope_.module_.addDeferredSemantic(this);
					global.dprogress = dprogress_save;
					//writef("\tdeferring %s\n", toChars());
					return;
				}
			}
static if (false)
{
		// Decided to abandon this restriction for D 2.0
			if (!memtype.isintegral())
			{   error("base type must be of integral type, not %s", memtype.toChars());
				memtype = Type.tint32;
			}
}
		}

		isdone = true;
	    global.dprogress++;

		type = type.semantic(loc, sc);
		if (isAnonymous())
			sce = sc;
		else
		{	sce = sc.push(this);
		sce.parent = this;
		}
		if (members.dim == 0)
		error("enum %s must have at least one member", toChars());
		int first = 1;
		Expression elast = null;
		foreach (Dsymbol s; members)
		{
		EnumMember em = s.isEnumMember();
		Expression e;

		if (!em)
			/* The e.semantic(sce) can insert other symbols, such as
			 * template instances and function literals.
			 */
			continue;

		//printf("  Enum member '%s'\n",em.toChars());
		if (em.type)
			em.type = em.type.semantic(em.loc, sce);
		e = em.value;
		if (e)
		{
			assert(e.dyncast() == DYNCAST.DYNCAST_EXPRESSION);
			e = e.semantic(sce);
			e = e.optimize(WANT.WANTvalue | WANT.WANTinterpret);
			if (memtype)
			{
			e = e.implicitCastTo(sce, memtype);
			e = e.optimize(WANT.WANTvalue | WANT.WANTinterpret);
			if (!isAnonymous())
				e = e.castTo(sce, type);
			t = memtype;
			}
			else if (em.type)
			{
			e = e.implicitCastTo(sce, em.type);
			e = e.optimize(WANT.WANTvalue | WANT.WANTinterpret);
			assert(isAnonymous());
			t = e.type;
			}
			else
			t = e.type;
		}
		else if (first)
		{
			if (memtype)
			t = memtype;
			else if (em.type)
			t = em.type;
			else
			t = Type.tint32;
			e = new IntegerExp(em.loc, 0, Type.tint32);
			e = e.implicitCastTo(sce, t);
			e = e.optimize(WANT.WANTvalue | WANT.WANTinterpret);
			if (!isAnonymous())
			e = e.castTo(sce, type);
		}
		else
		{
			// Set value to (elast + 1).
			// But first check that (elast != t.max)
			assert(elast);
			e = new EqualExp(TOK.TOKequal, em.loc, elast, t.getProperty(Loc(0), Id.max));
			e = e.semantic(sce);
			e = e.optimize(WANT.WANTvalue | WANT.WANTinterpret);
			if (e.toInteger())
			error("overflow of enum value %s", elast.toChars());

			// Now set e to (elast + 1)
			e = new AddExp(em.loc, elast, new IntegerExp(em.loc, 1, Type.tint32));
			e = e.semantic(sce);
			e = e.castTo(sce, elast.type);
			e = e.optimize(WANT.WANTvalue | WANT.WANTinterpret);
		}
		elast = e;
		em.value = e;

		// Add to symbol table only after evaluating 'value'
		if (isAnonymous())
		{
			/* Anonymous enum members get added to enclosing scope.
			 */
			for (Scope scxx = sce; scxx; scxx = scxx.enclosing)
			{
				if (scxx.scopesym)
				{
					if (!scxx.scopesym.symtab)
						scxx.scopesym.symtab = new DsymbolTable();
					em.addMember(sce, scxx.scopesym, true);
					break;
				}
			}
		}
		else
			em.addMember(sc, this, true);

		/* Compute .min, .max and .default values.
		 * If enum doesn't have a name, we can never identify the enum type,
		 * so there is no purpose for a .min, .max or .default
		 */
		if (!isAnonymous())
		{
			if (first)
			{	defaultval = e;
			minval = e;
			maxval = e;
			}
			else
			{	Expression ec;

			/* In order to work successfully with UDTs,
			 * build expressions to do the comparisons,
			 * and let the semantic analyzer and constant
			 * folder give us the result.
			 */

			// Compute if(e < minval)
			ec = new CmpExp(TOK.TOKlt, em.loc, e, minval);
			ec = ec.semantic(sce);
			ec = ec.optimize(WANT.WANTvalue | WANT.WANTinterpret);
			if (ec.toInteger())
				minval = e;

			ec = new CmpExp(TOK.TOKgt, em.loc, e, maxval);
			ec = ec.semantic(sce);
			ec = ec.optimize(WANT.WANTvalue | WANT.WANTinterpret);
			if (ec.toInteger())
				maxval = e;
			}
		}
		first = 0;
		}
		//printf("defaultval = %lld\n", defaultval);

		//if (defaultval) printf("defaultval: %s %s\n", defaultval.toChars(), defaultval.type.toChars());
		if (sc != sce)
		sce.pop();
		//members.print();
	}
	
    override bool oneMember(Dsymbol* ps)
	{
    		if (isAnonymous())
			return Dsymbol.oneMembers(members, ps);
	    	return Dsymbol.oneMember(ps);
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
	    buf.writestring("enum ");
	    if (ident)
	    {	buf.writestring(ident.toChars());
		buf.writeByte(' ');
	    }
	    if (memtype)
	    {
		buf.writestring(": ");
		memtype.toCBuffer(buf, null, hgs);
	    }
	    if (!members)
	    {
		buf.writeByte(';');
		buf.writenl();
		return;
	    }
	    buf.writenl();
	    buf.writeByte('{');
	    buf.writenl();
	    foreach(Dsymbol s; members)
	    {
		EnumMember em = s.isEnumMember();
		if (!em)
		    continue;
		//buf.writestring("    ");
		em.toCBuffer(buf, hgs);
		buf.writeByte(',');
		buf.writenl();
	    }
	    buf.writeByte('}');
	    buf.writenl();
	}
	
    override Type getType()
	{
		return type;
	}
	
    override string kind()
	{
		return "enum";
	}
	
version (DMDV2) {
    override Dsymbol search(Loc, Identifier ident, int flags)
	{
		//printf("%s.EnumDeclaration.search('%s')\n", toChars(), ident.toChars());
		if (scope_)
			// Try one last time to resolve this enum
			semantic(scope_);

		if (!members || !symtab || scope_)
		{   
			error("is forward referenced when looking for '%s'", ident.toChars());
			//*(char*)0=0;
			return null;
		}

		return ScopeDsymbol.search(loc, ident, flags);
	}
}
    override bool isDeprecated()			// is Dsymbol deprecated?
	{
		return isdeprecated;
	}

    override void emitComment(Scope sc)
	{
		assert(false);
	}

	override void toJsonBuffer(OutBuffer buf)
	{
		//writef("EnumDeclaration.toJsonBuffer()\n");
		if (isAnonymous())
		{
			if (members)
			{
				foreach (Dsymbol s; members)
				{
					s.toJsonBuffer(buf);
					buf.writestring(",\n");
				}
				JsonRemoveComma(buf);
			}
			return;
		}
	
		buf.writestring("{\n");
	
		JsonProperty(buf, Pname, toChars());
		JsonProperty(buf, Pkind, kind());
		if (comment)
			JsonProperty(buf, Pcomment, comment);
	
		if (loc.linnum)
			JsonProperty(buf, Pline, loc.linnum);
	
		if (memtype)
			JsonProperty(buf, "base", memtype.toChars());
	
		JsonString(buf, Pmembers);
		buf.writestring(" : [\n");
		size_t offset = buf.offset;
		foreach (Dsymbol s; members)
		{
			if (offset != buf.offset)
			{
				buf.writestring(",\n");
				offset = buf.offset;
			}
			s.toJsonBuffer(buf);
		}
		JsonRemoveComma(buf);
		buf.writestring("]\n");
	
		buf.writestring("}\n");
	}

    override void toDocBuffer(OutBuffer buf)
	{
		assert(false);
	}

    override EnumDeclaration isEnumDeclaration() { return this; }

    override void toObjFile(int multiobj)			// compile to .obj file
	{
		//printf("EnumDeclaration.toObjFile('%s')\n", toChars());
	version (DMDV2) {
		if (isAnonymous())
			return;
	}

		if (global.params.symdebug)
			toDebug();

		type.getTypeInfo(null);	// generate TypeInfo

		TypeEnum tc = cast(TypeEnum)type;
		if (!tc.sym.defaultval || type.isZeroInit(Loc(0))) {
			//;
		} else {
			SC scclass = SCglobal;
			if (inTemplateInstance())
				scclass = SCcomdat;

			// Generate static initializer
			toInitializer();
			sinit.Sclass = scclass;
			sinit.Sfl = FLdata;
		version (ELFOBJ) { // Burton
			sinit.Sseg = Segment.CDATA;
		}
		version (MACHOBJ) {
			sinit.Sseg = Segment.DATA;
		}
		version (DMDV1) {
			dtnbytes(&sinit.Sdt, tc.size(0), cast(char*)&tc.sym.defaultval);
			//sinit.Sdt = tc.sym.init.toDt();
		}
		version (DMDV2) {
			tc.sym.defaultval.toDt(&sinit.Sdt);
		}
			outdata(sinit);
		}
	}
	
    void toDebug()
	{
		assert(false);
	}
	
    override int cvMember(ubyte* p)
	{
		assert(false);
	}

    Symbol* sinit;

    Symbol* toInitializer()
	{
		Symbol* s;
		Classsym* stag;

		if (!sinit)
		{
			stag = fake_classsym(Id.ClassInfo);
			Identifier ident_save = ident;
			if (!ident)
				ident = Lexer.uniqueId("__enum");
			s = toSymbolX("__init", SCextern, stag.Stype, "Z");
			ident = ident_save;
			s.Sfl = FLextern;
			s.Sflags |= SFLnodebug;
			slist_add(s);
			sinit = s;
		}

		return sinit;
	}
};
