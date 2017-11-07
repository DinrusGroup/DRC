module dmd.Dsymbol;

import dmd.common;
import dmd.Loc;
import dmd.STC;
import dmd.Scope;
import dmd.Lexer;
import dmd.Module;
import dmd.Array;
import dmd.ScopeDsymbol;
import dmd.OutBuffer;
import dmd.Id;
import dmd.Identifier;
import dmd.TemplateInstance;
import dmd.SharedStaticCtorDeclaration;
import dmd.SharedStaticDtorDeclaration;
import dmd.HdrGenState;
import dmd.AggregateDeclaration;
import dmd.ClassDeclaration;
import dmd.LabelDsymbol;
import dmd.Type;
import dmd.PROT;
import dmd.ArrayTypes;
import dmd.Package;
import dmd.EnumMember;
import dmd.TemplateDeclaration;
import dmd.TemplateMixin;
import dmd.Declaration;
import dmd.ThisDeclaration;
import dmd.TupleDeclaration;
import dmd.TypedefDeclaration;
import dmd.AliasDeclaration;
import dmd.FuncDeclaration;
import dmd.FuncAliasDeclaration;
import dmd.FuncLiteralDeclaration;
import dmd.CtorDeclaration;
import dmd.PostBlitDeclaration;
import dmd.DtorDeclaration;
import dmd.StaticCtorDeclaration;
import dmd.StaticDtorDeclaration;
import dmd.InvariantDeclaration;
import dmd.UnitTestDeclaration;
import dmd.NewDeclaration;
import dmd.VarDeclaration;
import dmd.StructDeclaration;
import dmd.UnionDeclaration;
import dmd.InterfaceDeclaration;
import dmd.WithScopeSymbol;
import dmd.ArrayScopeSymbol;
import dmd.Import;
import dmd.EnumDeclaration;
import dmd.DeleteDeclaration;
import dmd.SymbolDeclaration;
import dmd.AttribDeclaration;
import dmd.OverloadSet;
import dmd.DYNCAST;
import dmd.Global;
import dmd.Expression;
import dmd.TOK;
import dmd.VarExp;
import dmd.FuncExp;

import dmd.backend.Symbol;
import dmd.backend.TYPE;
import dmd.backend.Util;
import dmd.backend.mTYman;
import dmd.backend.TYFL;
import dmd.backend.TYM;
import dmd.backend.mTY;
import dmd.backend.SC;
import dmd.backend.FL;
import dmd.backend.LIST;
public import dmd.PASS;

import dmd.DDMDExtensions;

import core.stdc.string : strcmp, memcpy, strlen;
version (Bug4054) import core.memory;
else import core.stdc.stdlib : alloca;

import std.stdio;

// TODO: remove dependencies on these
Expression isExpression(Object o)
{
    return cast(Expression)o;
}

Dsymbol isDsymbol(Object o)
{
    return cast(Dsymbol)o;
}

Type isType(Object o)
{
    return cast(Type)o;
}

/***********************
 * Try to get arg as a type.
 */

Type getType(Object o)
{
    Type t = isType(o);
    if (!t)
    {   Expression e = isExpression(o);
	if (e)
	    t = e.type;
    }
    return t;
}


Dsymbol getDsymbol(Object oarg)
{
	Dsymbol sa;
    Expression ea = isExpression(oarg);
    if (ea)
    {   // Try to convert Expression to symbol
		if (ea.op == TOK.TOKvar)
			sa = (cast(VarExp)ea).var;
		else if (ea.op == TOK.TOKfunction)
			sa = (cast(FuncExp)ea).fd;
		else
			sa = null;
    }
    else
    {   // Try to convert Type to symbol
		Type ta = isType(oarg);
		if (ta)
			sa = ta.toDsymbol(null);
		else
			sa = isDsymbol(oarg);	// if already a symbol
    }
    return sa;
}

alias Vector!Dsymbol Dsymbols;

import dmd.TObject;

class Dsymbol : TObject
{
	mixin insertMemberExtension!(typeof(this));
	
    Identifier ident;
    Identifier c_ident;
    Dsymbol parent;
    Symbol* csym;		// symbol for code generator
    Symbol* isym;		// import version of csym
    string comment;	// documentation comment for this Dsymbol
    Loc loc;			// where defined
    Scope scope_;		// !=null means context to use for semantic()

    this()
	{
		register();
		// do nothing
	}
	
    this(Identifier ident)
	{
		register();
		this.ident = ident;
	}

    string toChars()
	{
		return ident ? ident.toChars() : "__anonymous";
	}

    string locToChars()
	{
		scope OutBuffer buf = new OutBuffer();
		Module m = getModule();

		if (m && m.srcfile)
			loc.filename = m.srcfile.toChars();

		return loc.toChars();
	}

    bool equals(Object o)
	{
		Dsymbol s;

		if (this is o)
			return true;
			
		s = cast(Dsymbol)(o);
		if (s && ident.equals(s.ident))
			return true;

		return false;
	}

    bool isAnonymous()
	{
		return ident ? 0 : 1;
	}

    void error(T...)(Loc loc, string format, T t)
	{
		if (!global.gag)
		{
			string p = loc.toChars();
			if (p.length == 0)
				p = locToChars();

			if (p.length != 0) {
				writef("%s: ", p);
			}

			write("Error: ");
			writef("%s %s ", kind(), toPrettyChars());

			writefln(format, t);
		}

		global.errors++;
		
		//fatal();
	}

    void error(T...)(string format, T t)
	{
		//printf("Dsymbol.error()\n");
		if (!global.gag)
		{
			string p = loc.toChars();

			if (p.length != 0) {
				writef("%s: ", p);
			}

			write("Error: ");
			if (isAnonymous()) {
				writef("%s ", kind());
			} else {
				writef("%s %s ", kind(), toPrettyChars());
			}

			writefln(format, t);
		}
		global.errors++;

		//fatal();
	}

    void checkDeprecated(Loc loc, Scope sc)
	{
		if (!global.params.useDeprecated && isDeprecated())
		{
			// Don't complain if we're inside a deprecated symbol's scope
			for (Dsymbol sp = sc.parent; sp; sp = sp.parent)
			{   
				if (sp.isDeprecated())
					goto L1;
			}

			for (; sc; sc = sc.enclosing)
			{
				if (sc.scopesym && sc.scopesym.isDeprecated())
					goto L1;

				// If inside a StorageClassDeclaration that is deprecated
				if (sc.stc & STC.STCdeprecated)
					goto L1;
			}

			error(loc, "is deprecated");
		}
		
	L1:
		Declaration d = isDeclaration();
		if (d && d.storage_class & STCdisable)
		{
			if (!(sc.func && sc.func.storage_class & STCdisable))
			{
				if (d.ident == Id.cpctor && d.toParent())
					d.toParent().error(loc, "is not copyable");
				else
					error(loc, "is not callable");
			}
		}
	}
	
    Module getModule()
	{
		//printf("Dsymbol.getModule()\n");
		Dsymbol s = this;
		while (s)
		{
			//printf("\ts = '%s'\n", s.toChars());
			Module m = s.isModule();
			if (m)
				return m;
			s = s.parent;
		}

		return null;
	}
	
    Dsymbol pastMixin()
	{
		 Dsymbol s = this;
		//printf("Dsymbol::pastMixin() %s\n", toChars());
		while (s && s.isTemplateMixin())
			s = s.parent;
		return s;
	}
	
    Dsymbol toParent()
	{
		return parent ? parent.pastMixin() : null;
	}

	/**********************************
	 * Use this instead of toParent() when looking for the
	 * 'this' pointer of the enclosing function/class.
	 */
    Dsymbol toParent2()
	{
		Dsymbol s = parent;
		while (s && s.isTemplateInstance())
			s = s.parent;
		return s;
	}
	
    TemplateInstance inTemplateInstance()
	{
		for (Dsymbol parent = this.parent; parent; parent = parent.parent)
		{
			TemplateInstance ti = parent.isTemplateInstance();
			if (ti)
				return ti;
		}

		return null;
	}

    DYNCAST dyncast() { return DYNCAST.DYNCAST_DSYMBOL; }	// kludge for template.isSymbol()

	/*************************************
	 * Do syntax copy of an array of Dsymbol's.
	 */
    static Vector!Dsymbol arraySyntaxCopy(Vector!Dsymbol a)
	{
		Vector!Dsymbol b = null;
		if (a)
		{
			b = a.copy();
			for (int i = 0; i < b.dim; i++)
			{
				auto s = b[i];

				s = s.syntaxCopy(null);
				b[i] = s;
			}
		}
		return b;
	}

    string toPrettyChars()
	{
		//printf("Dsymbol.toPrettyChars() '%s'\n", toChars());
		if (!parent) {
			return toChars();
		}

		size_t len = 0;
		for (Dsymbol p = this; p; p = p.parent) {
			len += p.toChars().length + 1;
		}
		--len;

version (Bug4054)
		char* s = cast(char*)GC.malloc(len);
else
		char* s = cast(char*)alloca(len);
		char* q = s + len;

		for (Dsymbol p = this; p; p = p.parent)
		{
			string t = p.toChars();
			size_t length = t.length;
			q -= length;

			memcpy(q, t.ptr, length);
			if (q is s)
				break;
			
			q--;
	version (TARGET_NET) {
			if (AggregateDeclaration ad = p.isAggregateDeclaration())
			{
				if (ad.isNested() && p.parent && p.parent.isAggregateDeclaration())
				{
					*q = '/';
					continue;
				}
			}
	}
			*q = '.';
		}

		return s[0..len].idup;
	}
	
    string kind()
	{
		assert(false);
	}
	
	/*********************************
	 * If this symbol is really an alias for another,
	 * return that other.
	 */
    Dsymbol toAlias()			// resolve real symbol
	{
		return this;
	}
	
    bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
	{
		//printf("Dsymbol.addMember('%s')\n", toChars());
		//printf("Dsymbol.addMember(this = %p, '%s' scopesym = '%s')\n", this, toChars(), sd.toChars());
		assert(sd !is null);
		parent = sd;
		if (!isAnonymous())		// no name, so can't add it to symbol table
		{
			if (!sd.symtabInsert(this))	// if name is already defined
			{
				Dsymbol s2 = sd.symtab.lookup(ident);
				if (!s2.overloadInsert(this))
				{
					sd.multiplyDefined(Loc(0), this, s2);
				}
			}
			if (sd.isAggregateDeclaration() || sd.isEnumDeclaration())
			{
				if (ident is Id.__sizeof || ident is Id.alignof_ || ident is Id.mangleof_)
					error(".%s property cannot be redefined", ident.toChars());
			}
			return true;
		}

		return false;
	}
	
    void setScope(Scope sc)
	{
		//printf("Dsymbol.setScope() %p %s\n", this, toChars());
		if (!sc.nofree)
			sc.setNoFree();		// may need it even after semantic() finishes
		scope_ = sc;
	}
    
    void importAll(Scope sc)
    {
    }
	
    void semantic(Scope sc)
	{
    	error("%p has no semantic routine", this);
	}
	
	/*************************************
	 * Does semantic analysis on initializers and members of aggregates.
	 */
    void semantic2(Scope sc)
	{
		// Most Dsymbols have no further semantic analysis needed
	}

	/*************************************
	 * Does semantic analysis on function bodies.
	 */	
    void semantic3(Scope sc)
	{
		// Most Dsymbols have no further semantic analysis needed
	}
	
	/*************************************
	 * Look for function inlining possibilities.
	 */
    void inlineScan()
	{
		// Most Dsymbols aren't functions
	}
	
	/*********************************************
	 * Search for ident as member of s.
	 * Input:
	 *	flags:	1	don't find private members
	 *		2	don't give error messages
	 *		4	return null if ambiguous
	 * Returns:
	 *	null if not found
	 */
    Dsymbol search(Loc loc, Identifier ident, int flags)
	{
		//printf("Dsymbol.search(this=%p,%s, ident='%s')\n", this, toChars(), ident.toChars());
		return null;
	}
	
	/***************************************
	 * Search for identifier id as a member of 'this'.
	 * id may be a template instance.
	 * Returns:
	 *	symbol found, null if not
	 */
    Dsymbol searchX(Loc loc, Scope sc, Object o)
	{
		//printf("Dsymbol::searchX(this=%p,%s, ident='%s')\n", this, toChars(), ident.toChars());
		Dsymbol s = toAlias();
		Dsymbol sm;

		if (auto ident = cast(Identifier)o)
		{
			sm = s.search(loc, ident, 0);
		}
		else if (auto st = cast(Dsymbol)o)
		{
			// It's a template instance
			//printf("\ttemplate instance id\n");
			TemplateInstance ti = st.isTemplateInstance();
			Identifier id = ti.name;
			sm = s.search(loc, cast(Identifier)id, 0);
			if (!sm)
			{   
				error("template identifier %s is not a member of %s %s", id.toChars(), s.kind(), s.toChars());
				return null;
			}
			sm = sm.toAlias();
			TemplateDeclaration td = sm.isTemplateDeclaration();
			if (!td)
			{
				error("%s is not a template, it is a %s", id.toChars(), sm.kind());
				return null;
			}

			ti.tempdecl = td;
			if (!ti.semanticRun)
				ti.semantic(sc);

			sm = ti.toAlias();
		}
		else
		{
			assert(0);
		}
		return sm;
	}
	
    bool overloadInsert(Dsymbol s)
	{
		assert(false);
	}
	
version (_DH)
{
    char* toHChars()
	{
		assert(false);
	}
	
    void toHBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
}
    void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
	
    void toDocBuffer(OutBuffer buf)
	{
		assert(false);
	}
    
    void toJsonBuffer(OutBuffer buf)
    {
    }
	
    uint size(Loc loc)
	{
		assert(false);
	}

    int isforwardRef()
	{
		assert(false);
	}
	
    void defineRef(Dsymbol s)
	{
		assert(false);
	}
	
    AggregateDeclaration isThis()	// is a 'this' required to access the member
	{
		return null;
	}
	
    ClassDeclaration isClassMember()	// are we a member of a class?
	{
		Dsymbol parent = toParent();
		if (parent && parent.isClassDeclaration())
			return cast(ClassDeclaration)parent;
		return null;
	}
	
    bool isExport()			// is Dsymbol exported?
	{
		return false;
	}
	
    bool isImportedSymbol()		// is Dsymbol imported?
	{
		return false;
	}
	
    bool isDeprecated()			// is Dsymbol deprecated?
	{
		return false;
	}

version (DMDV2) {
    bool isOverloadable()
	{
		return false;
	}
}

    LabelDsymbol isLabel()		// is this a LabelDsymbol?
	{
		return null;
	}
	
    AggregateDeclaration isMember()	// is this symbol a member of an AggregateDeclaration?
	{
		//printf("Dsymbol::isMember() %s\n", toChars());
		Dsymbol parent = toParent();
		//printf("parent is %s %s\n", parent.kind(), parent.toChars());
		return parent ? parent.isAggregateDeclaration() : null;
	}

    Type getType()			// is this a type?
	{
		return null;
	}
	
    string mangle()
	{
		OutBuffer buf = new OutBuffer();
		string id;

static if (false) {
		printf("Dsymbol::mangle() '%s'", toChars());
		if (parent)
			printf("  parent = %s %s", parent.kind(), parent.toChars());
		printf("\n");
}
		id = ident ? ident.toChars() : toChars();
		if (parent)
		{
			string p = parent.mangle();
			if (p[0] == '_' && p[1] == 'D')
				p =  p[2..$];
			buf.writestring(p);
		}
		///buf.printf("%zu%s", id.length, id);
		buf.printf("%d%s", id.length, id);
		id = buf.toChars();
		buf.data = null;
		//printf("Dsymbol::mangle() %s = %s\n", toChars(), id);
		return id;
	}

    bool needThis()			// need a 'this' pointer?
	{
		return false;
	}

    PROT prot()
	{
		assert(false);
	}

    Dsymbol syntaxCopy(Dsymbol s)	// copy only syntax trees
	{
		assert(false);
	}

	/**************************************
	 * Determine if this symbol is only one.
	 * Returns:
	 *	false, *ps = null: There are 2 or more symbols
	 *	true,  *ps = null: There are zero symbols
	 *	true,  *ps = symbol: The one and only one symbol
	 */
    bool oneMember(Dsymbol* ps)
	{
		//printf("Dsymbol::oneMember()\n");
		*ps = this;
		return true;
	}

	/*****************************************
	 * Same as Dsymbol::oneMember(), but look at an array of Dsymbols.
	 */
    static bool oneMembers(Dsymbols members, Dsymbol* ps)
	{
		//printf("Dsymbol::oneMembers() %d\n", members ? members->dim : 0);
		Dsymbol s = null;

		if (members)
		{
			foreach(sx; members)
			{   
				bool x = sx.oneMember(ps);
				//printf("\t[%d] kind %s = %d, s = %p\n", i, sx->kind(), x, *ps);
				if (!x)
				{
					//printf("\tfalse 1\n");
					assert(*ps is null);
					return false;
				}
				if (*ps)
				{
					if (s)			// more than one symbol
					{   
						*ps = null;
						//printf("\tfalse 2\n");
						return false;
					}
					s = *ps;
				}
			}
		}

		*ps = s;		// s is the one symbol, null if none
		//printf("\ttrue\n");
		return true;
	}
	
	/*****************************************
	 * Is Dsymbol a variable that contains pointers?
	 */
    bool hasPointers()
	{
		//printf("Dsymbol::hasPointers() %s\n", toChars());
		return 0;
	}

    void addLocalClass(ClassDeclarations) { }
    void checkCtorConstInit() { }

    // since comment is stored immutable string is correct here
    void addComment(string comment)
	{
		//if (comment)
			//writef("adding comment '%s' to symbol %p '%s'\n", comment, this, toChars());

		if (this.comment is null)
		{
			this.comment = comment;
		}
		else
		{
static if (true)
{
			if (comment !is null && comment != this.comment)
			{	// Concatenate the two
				this.comment = Lexer.combineComments(this.comment, comment);
			}
}
		}
	}
	
    void emitComment(Scope sc)
	{
		assert(false);
	}
	
    void emitDitto(Scope sc)
	{
		assert(false);
	}

    // Backend

    Symbol* toSymbol()			// to backend symbol
	{
		assert(false);
	}
	
    void toObjFile(int multiobj)			// compile to .obj file
	{
		//printf("Dsymbol::toObjFile('%s')\n", toChars());
		// ignore
	}
	
    int cvMember(ubyte* p)	// emit cv debug info for member
	{
		assert(false);
	}

	/*********************************
	 * Generate import symbol from symbol.
	 */
    Symbol* toImport()				// to backend import symbol
	{
		if (!isym)
		{
			if (!csym)
				csym = toSymbol();
			isym = toImport(csym);
		}

		return isym;
	}
	
    static Symbol* toImport(Symbol* sym)		// to backend import symbol
	{
		char* id;
		char* n;
		Symbol* s;
		type* t;

		//printf("Dsymbol::toImport('%s')\n", sym->Sident);
		n = sym.Sident.ptr;
version (Bug4054)
		id = cast(char*) GC.malloc(6 + strlen(n) + 1 + (type_paramsize_i(sym.Stype)).sizeof*3 + 1);
else
		id = cast(char*) alloca(6 + strlen(n) + 1 + (type_paramsize_i(sym.Stype)).sizeof*3 + 1);
		if (sym.Stype.Tmangle == mTYman_std && tyfunc(sym.Stype.Tty))
		{
			sprintf(id, "_imp__%s@%lu", n, type_paramsize_i(sym.Stype));
		}
		else if (sym.Stype.Tmangle == mTYman_d)
			sprintf(id,"_imp_%s",n);
		else
			sprintf(id,"_imp__%s",n);
		t = type_alloc(TYnptr | mTYconst);
		t.Tnext = sym.Stype;
		t.Tnext.Tcount++;
		t.Tmangle = mTYman_c;
		t.Tcount++;
		s = symbol_calloc(id);
		s.Stype = t;
		s.Sclass = SCextern;
		s.Sfl = FLextern;
		slist_add(s);

		return s;
	}

    Symbol* toSymbolX(string prefix, int sclass, TYPE* t, string suffix)	// helper
	{
		Symbol* s;
		char* id;
		string n;
		size_t nlen;

		//writef("Dsymbol::toSymbolX('%s', '%s')\n", prefix, this.classinfo.name);
		n = mangle();
		assert(n.length != 0);

		nlen = n.length;
static if (false) {
		if (nlen > 2 && n[0] == '_' && n[1] == 'D')
		{
			nlen -= 2;
			n += 2;
		}
}
		version (Bug4054)
		id = cast(char*) GC.malloc(2 + nlen + size_t.sizeof * 3 + prefix.length + suffix.length + 1);
		else
		id = cast(char*) alloca(2 + nlen + size_t.sizeof * 3 + prefix.length + suffix.length + 1);
	    sprintf(id, "_D%.*s%zu%.*s%.*s", n, prefix.length, prefix, suffix);
		
	static if (false) {
		if (global.params.isWindows && (type_mangle(t) == mTYman.mTYman_c || type_mangle(t) == mTYman.mTYman_std))
			id++;			// Windows C mangling will put the '_' back in
	}
		s = symbol_name(id, sclass, t);
		
		//printf("-Dsymbol::toSymbolX() %s\n", id);
		return s;
	}

    // Eliminate need for dynamic_cast
    Package isPackage() { return null; }
    Module isModule() { return null; }
    EnumMember isEnumMember() { return null; }
    TemplateDeclaration isTemplateDeclaration() { return null; }
    TemplateInstance isTemplateInstance() { return null; }
    TemplateMixin isTemplateMixin() { return null; }
    Declaration isDeclaration() { return null; }
    ThisDeclaration isThisDeclaration() { return null; }
    TupleDeclaration isTupleDeclaration() { return null; }
    TypedefDeclaration isTypedefDeclaration() { return null; }
    AliasDeclaration isAliasDeclaration() { return null; }
    AggregateDeclaration isAggregateDeclaration() { return null; }
    FuncDeclaration isFuncDeclaration() { return null; }
    FuncAliasDeclaration isFuncAliasDeclaration() { return null; }
    FuncLiteralDeclaration isFuncLiteralDeclaration() { return null; }
    CtorDeclaration isCtorDeclaration() { return null; }
    PostBlitDeclaration isPostBlitDeclaration() { return null; }
    DtorDeclaration isDtorDeclaration() { return null; }
    StaticCtorDeclaration isStaticCtorDeclaration() { return null; }
    StaticDtorDeclaration isStaticDtorDeclaration() { return null; }
    SharedStaticCtorDeclaration isSharedStaticCtorDeclaration() { return null; }
    SharedStaticDtorDeclaration isSharedStaticDtorDeclaration() { return null; }
    InvariantDeclaration isInvariantDeclaration() { return null; }
    UnitTestDeclaration isUnitTestDeclaration() { return null; }
    NewDeclaration isNewDeclaration() { return null; }
    VarDeclaration isVarDeclaration() { return null; }
    ClassDeclaration isClassDeclaration() { return null; }
    StructDeclaration isStructDeclaration() { return null; }
    UnionDeclaration isUnionDeclaration() { return null; }
    InterfaceDeclaration isInterfaceDeclaration() { return null; }
    ScopeDsymbol isScopeDsymbol() { return null; }
    WithScopeSymbol isWithScopeSymbol() { return null; }
    ArrayScopeSymbol isArrayScopeSymbol() { return null; }
    Import isImport() { return null; }
    EnumDeclaration isEnumDeclaration() { return null; }
version (_DH)
{
    DeleteDeclaration isDeleteDeclaration() { return null; }
}
    SymbolDeclaration isSymbolDeclaration() { return null; }
    AttribDeclaration isAttribDeclaration() { return null; }
    OverloadSet isOverloadSet() { return null; }
version (TARGET_NET)
{
    PragmaScope isPragmaScope() { return null; }
}
}