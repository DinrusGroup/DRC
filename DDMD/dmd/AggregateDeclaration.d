module dmd.AggregateDeclaration;

import dmd.common;
import dmd.ScopeDsymbol;
import dmd.Type;
import dmd.Id;
import dmd.ExpStatement;
import dmd.AddrExp;
import dmd.CastExp;
import dmd.TypeSArray;
import dmd.DotVarExp;
import dmd.TypeStruct;
import dmd.StructDeclaration;
import dmd.Declaration;
import dmd.TypeClass;
import dmd.TOK;
import dmd.ThisExp;
import dmd.Global;
import dmd.PROT;
import dmd.Expression;
import dmd.STC;
import dmd.DotIdExp;
import dmd.CallExp;
import dmd.DtorDeclaration;
import dmd.Lexer;
import dmd.TY;
import dmd.Array;
import dmd.ArrayTypes;
import dmd.VarDeclaration;
import dmd.InvariantDeclaration;
import dmd.NewDeclaration;
import dmd.DeleteDeclaration;
import dmd.CtorDeclaration;
import dmd.FuncDeclaration;
import dmd.Identifier;
import dmd.Json;
import dmd.Loc;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.ClassDeclaration;
import dmd.BaseClass;
import dmd.Util;

import dmd.backend.Symbol;
import dmd.backend.Classsym;
import dmd.backend.Util;
import dmd.backend.LIST;
import dmd.backend.SC;
import dmd.backend.FL;
import dmd.backend.SFL;
import dmd.codegen.Util;

import dmd.DDMDExtensions;

/****************************************
 * Determine if scope sc has package level access to s.
 */

bool hasPackageAccess(Scope sc, Dsymbol s)
{
version (LOG) {
    printf("hasPackageAccess(s = '%s', sc = '%p')\n", s.toChars(), sc);
}

    for (; s; s = s.parent)
    {
		if (s.isPackage() && !s.isModule())
			break;
    }
version (LOG) {
    if (s)
		printf("\tthis is in package '%s'\n", s.toChars());
}

    if (s && s == sc.module_.parent)
    {
version (LOG) {
		printf("\ts is in same package as sc\n");
}
		return true;
    }


version (LOG) {
    printf("\tno package access\n");
}

    return false;
}

/********************************************************
 * Helper function for ClassDeclaration.accessCheck()
 * Returns:
 *	0	no access
 * 	1	access
 */

bool accessCheckX(Dsymbol smember, Dsymbol sfunc, AggregateDeclaration dthis, AggregateDeclaration cdscope)
{
    assert(dthis);

static if (false) {
    writef("accessCheckX for %s.%s in function %s() in scope %s\n", dthis.toChars(), smember.toChars(), sfunc ? sfunc.toChars() : "null", cdscope ? cdscope.toChars() : "null");
}
    if (dthis.hasPrivateAccess(sfunc) || dthis.isFriendOf(cdscope))
    {
		if (smember.toParent() == dthis)
			return true;
		else
		{
			ClassDeclaration cdthis = dthis.isClassDeclaration();
			if (cdthis)
			{
				foreach (b; cdthis.baseclasses)
				{
					PROT access = b.base.getAccess(smember);

					if (access >= PROT.PROTprotected || accessCheckX(smember, sfunc, b.base, cdscope))
						return true;
				}
			}
		}
    }
    else
    {
		if (smember.toParent() != dthis)
		{
			ClassDeclaration cdthis = dthis.isClassDeclaration();
			if (cdthis)
			{
				foreach (b; cdthis.baseclasses)
				{
					if (accessCheckX(smember, sfunc, b.base, cdscope))
						return true;
				}
			}
		}
    }

    return false;
}

class AggregateDeclaration : ScopeDsymbol
{
	mixin insertMemberExtension!(typeof(this));

    Type type;
    StorageClass storage_class;
    PROT protection = PROT.PROTpublic;
    Type handle;		// 'this' type
    uint structsize;	// size of struct
    uint alignsize;		// size of struct for alignment purposes
    uint structalign;	// struct member alignment in effect
    int hasUnions;		// set if aggregate has overlapping fields
    VarDeclarations fields;	// VarDeclaration fields
    uint sizeok;		// set when structsize contains valid data
				// 0: no size
				// 1: size is correct
				// 2: cannot determine size; fwd referenced
    bool isdeprecated;		// true if deprecated

version (DMDV2) {
    bool isnested;		// true if is nested
    VarDeclaration vthis;	// 'this' parameter if this aggregate is nested
}
    // Special member functions
    InvariantDeclaration inv;		// invariant
    NewDeclaration aggNew;		// allocator
    DeleteDeclaration aggDelete;	// deallocator

version (DMDV2) {
    //CtorDeclaration *ctor;
    Dsymbol ctor;			// CtorDeclaration or TemplateDeclaration
    CtorDeclaration defaultCtor;	// default constructor
    Dsymbol aliasthis;			// forward unresolved lookups to aliasthis
}

    FuncDeclarations dtors;	// Array of destructors
    FuncDeclaration dtor;	// aggregate destructor

version (IN_GCC) {
    Array methods;              // flat list of all methods for debug information
}

    this(Loc loc, Identifier id)
	{
		register();
		super(id);
		this.loc = loc;

		fields = new VarDeclarations();	///
		dtors = new FuncDeclarations();
	}

    override void semantic2(Scope sc)
	{
		//printf("AggregateDeclaration.semantic2(%s)\n", toChars());
		if (scope_ && members)
		{
			error("has forward references");
			return;
		}
		if (members)
		{
			sc = sc.push(this);
			foreach(Dsymbol s; members)
				s.semantic2(sc);
			sc.pop();
		}
	}

    override void semantic3(Scope sc)
	{
		//printf("AggregateDeclaration.semantic3(%s)\n", toChars());
		if (members)
		{
			sc = sc.push(this);
			foreach(Dsymbol s; members)
				s.semantic3(sc);
			sc.pop();
		}
	}

    override void inlineScan()
	{
		//printf("AggregateDeclaration.inlineScan(%s)\n", toChars());
		if (members)
		{
			foreach(Dsymbol s; members)
			{
				//printf("inline scan aggregate symbol '%s'\n", s.toChars());
				s.inlineScan();
			}
		}
	}

    override uint size(Loc loc)
	{
		//printf("AggregateDeclaration.size() = %d\n", structsize);
		if (!members)
			error(loc, "unknown size");

		if (sizeok != 1)
		{
			error(loc, "no size yet for forward reference");
			//*(char*)0=0;
		}

		return structsize;
	}

	/****************************
	 * Do byte or word alignment as necessary.
	 * Align sizes of 0, as we may not know array sizes yet.
	 */
    static void alignmember(uint salign, uint size, uint* poffset)
	{
		//printf("salign = %d, size = %d, offset = %d\n",salign,size,offset);
		if (salign > 1)
		{
			assert(size != 3);
			int sa = size;
			if (sa == 0 || salign < sa)
				sa = salign;
			*poffset = (*poffset + sa - 1) & ~(sa - 1);
		}
		//printf("result = %d\n",offset);
	}

    override Type getType()
	{
		return type;
	}

    void addField(Scope sc, VarDeclaration v)
	{
		uint memsize;		// size of member
		uint memalignsize;	// size of member for alignment purposes
		uint xalign;		// alignment boundaries

		//printf("AggregateDeclaration.addField('%s') %s\n", v.toChars(), toChars());
		assert(!(v.storage_class & (STC.STCstatic | STC.STCextern | STC.STCparameter | STC.STCtls)));

		// Check for forward referenced types which will fail the size() call
		Type t = v.type.toBasetype();
		if (v.storage_class & STC.STCref)
		{	// References are the size of a pointer
		t = global.tvoidptr;
		}
		if (t.ty == TY.Tstruct /*&& isStructDeclaration()*/)
		{	TypeStruct ts = cast(TypeStruct)t;
version (DMDV2) {
		if (ts.sym == this)
		{
			error("cannot have field %s with same struct type", v.toChars());
		}
}

		if (ts.sym.sizeok != 1)
		{
			sizeok = 2;		// cannot finish; flag as forward referenced
			return;
		}
		}
		if (t.ty == TY.Tident)
		{
			sizeok = 2;		// cannot finish; flag as forward referenced
			return;
		}

		memsize = cast(uint)t.size(loc);		///
		memalignsize = t.alignsize();
		xalign = t.memalign(sc.structalign);
		alignmember(xalign, memalignsize, &sc.offset);
		v.offset = sc.offset;
		sc.offset += memsize;
		if (sc.offset > structsize)
		structsize = sc.offset;
		if (sc.structalign < memalignsize)
		memalignsize = sc.structalign;
		if (alignsize < memalignsize)
		alignsize = memalignsize;
		//printf("\talignsize = %d\n", alignsize);

		v.storage_class |= STC.STCfield;
		//printf(" addField '%s' to '%s' at offset %d, size = %d\n", v.toChars(), toChars(), v.offset, memsize);
		fields.push(v);
	}

    override bool isDeprecated()		// is aggregate deprecated?
	{
		return isdeprecated;
	}

	/*****************************************
	 * Create inclusive destructor for struct/class by aggregating
	 * all the destructors in dtors[] with the destructors for
	 * all the members.
	 * Note the close similarity with StructDeclaration.buildPostBlit(),
	 * and the ordering changes (runs backward instead of forwards).
	 */
    FuncDeclaration buildDtor(Scope sc)
	{
		 //printf("AggregateDeclaration.buildDtor() %s\n", toChars());
		Expression e = null;

version (DMDV2)
{
		foreach (size_t i, VarDeclaration v; fields)
		{
			assert(v && v.storage_class & STC.STCfield);
			if (v.storage_class & STC.STCref)
				continue;
			Type tv = v.type.toBasetype();
			size_t dim = 1;
			while (tv.ty == TY.Tsarray)
			{   TypeSArray ta = cast(TypeSArray)tv;
				dim *= (cast(TypeSArray)tv).dim.toInteger();
				tv = tv.nextOf().toBasetype();
			}
			if (tv.ty == TY.Tstruct)
			{   TypeStruct ts = cast(TypeStruct)tv;
				StructDeclaration sd = ts.sym;
				if (sd.dtor)
				{
					Expression ex;

					// this.v
					ex = new ThisExp(Loc(0));
					ex = new DotVarExp(Loc(0), ex, v, 0);

					if (dim == 1)
					{
						// this.v.dtor()
						ex = new DotVarExp(Loc(0), ex, sd.dtor, 0);
						ex = new CallExp(Loc(0), ex);
					}
					else
					{
						// Typeinfo.destroy(cast(void*)&this.v);
						Expression ea = new AddrExp(Loc(0), ex);
						ea = new CastExp(Loc(0), ea, Type.tvoid.pointerTo());

						Expression et = v.type.getTypeInfo(sc);
						et = new DotIdExp(Loc(0), et, Id.destroy);

						ex = new CallExp(Loc(0), et, ea);
					}
					e = Expression.combine(ex, e);	// combine in reverse order
				}
			}
		}

		/* Build our own "destructor" which executes e
		 */
		if (e)
		{
			//printf("Building __fieldDtor()\n");
			DtorDeclaration dd = new DtorDeclaration(Loc(0), Loc(0), Lexer.idPool("__fieldDtor"));
			dd.fbody = new ExpStatement(Loc(0), e);
			dtors.shift(dd);
			members.push(dd);
			dd.semantic(sc);
		}
}

		switch (dtors.dim)
		{
			case 0:
				return null;

			case 1:
				return cast(FuncDeclaration)dtors[0];

			default:
				e = null;
				foreach(FuncDeclaration fd; dtors)
				{
					Expression ex = new ThisExp(Loc(0));
					ex = new DotVarExp(Loc(0), ex, fd, 0);
					ex = new CallExp(Loc(0), ex);
					e = Expression.combine(ex, e);
				}
				auto dd = new DtorDeclaration(Loc(0), Loc(0), Lexer.idPool("__aggrDtor"));
				dd.fbody = new ExpStatement(Loc(0), e);
				members.push(dd);
				dd.semantic(sc);
				return dd;
		}
	}

	/****************************************
	 * Returns true if there's an extra member which is the 'this'
	 * pointer to the enclosing context (enclosing aggregate or function)
	 */
    bool isNested()
	{
		return isnested;
	}

    override void emitComment(Scope sc)
	{
		assert(false);
	}

	override void toJsonBuffer(OutBuffer buf)
	{
		//writef("AggregateDeclaration.toJsonBuffer()\n");
		buf.writestring("{\n");

		JsonProperty(buf, Pname, toChars());
		JsonProperty(buf, Pkind, kind());
		if (comment)
			JsonProperty(buf, Pcomment, comment);
		if (loc.linnum)
			JsonProperty(buf, Pline, loc.linnum);

		ClassDeclaration cd = isClassDeclaration();
		if (cd)
		{
			if (cd.baseClass)
			{
				JsonProperty(buf, "base", cd.baseClass.toChars());
			}
			if (cd.interfaces_dim)
			{
				JsonString(buf, "interfaces");
				buf.writestring(" : [\n");
				size_t offset = buf.offset;
				for (int i = 0; i < cd.interfaces_dim; i++)
				{
					BaseClass b = cd.interfaces[i];
					if (offset != buf.offset)
					{
						buf.writestring(",\n");
						offset = buf.offset;
					}
					JsonString(buf, b.base.toChars());
				}
				JsonRemoveComma(buf);
				buf.writestring("],\n");
			}
		}

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

    // For access checking
    PROT getAccess(Dsymbol smember)	// determine access to smember
	{
		assert(false);
	}

	/****************************************
	 * Determine if this is the same or friend of cd.
	 */
    bool isFriendOf(AggregateDeclaration cd)
	{
version (LOG) {
		printf("AggregateDeclaration.isFriendOf(this = '%s', cd = '%s')\n", toChars(), cd ? cd.toChars() : "null");
}
		if (this is cd)
			return true;

		// Friends if both are in the same module
		//if (toParent() == cd.toParent())
		if (cd && getModule() == cd.getModule())
		{
version (LOG) {
			printf("\tin same module\n");
}
			return true;
		}

version (LOG) {
		printf("\tnot friend\n");
}
		return false;
	}

	/**********************************
	 * Determine if smember has access to private members of this declaration.
	 */
    bool hasPrivateAccess(Dsymbol smember)	// does smember have private access to members of this class?
	{
		if (smember)
		{
			AggregateDeclaration cd = null;
			Dsymbol smemberparent = smember.toParent();
			if (smemberparent)
				cd = smemberparent.isAggregateDeclaration();

		version (LOG) {
			printf("AggregateDeclaration::hasPrivateAccess(class %s, member %s)\n", toChars(), smember.toChars());
		}

			if (this == cd)		// smember is a member of this class
			{
		version (LOG) {
				printf("\tyes 1\n");
		}
				return true;		// so we get private access
			}

			// If both are members of the same module, grant access
			while (true)
			{
				Dsymbol sp = smember.toParent();
				if (sp.isFuncDeclaration() && smember.isFuncDeclaration())
					smember = sp;
				else
					break;
			}
			if (!cd && toParent() == smember.toParent())
			{
		version (LOG) {
				printf("\tyes 2\n");
		}
				return true;
			}
			if (!cd && getModule() == smember.getModule())
			{
		version (LOG) {
				printf("\tyes 3\n");
		}
				return true;
			}
		}
	version (LOG) {
		printf("\tno\n");
	}
		return false;
	}

	/*******************************
	 * Do access check for member of this class, this class being the
	 * type of the 'this' pointer used to access smember.
	 */
    void accessCheck(Loc loc, Scope sc, Dsymbol smember)
	{
		bool result;

		FuncDeclaration f = sc.func;
		AggregateDeclaration cdscope = sc.getStructClassScope();
		PROT access;

version (LOG) {
		printf("AggregateDeclaration.accessCheck() for %s.%s in function %s() in scope %s\n", toChars(), smember.toChars(), f ? f.toChars() : null, cdscope ? cdscope.toChars() : null);
}

		Dsymbol smemberparent = smember.toParent();
		if (!smemberparent || !smemberparent.isAggregateDeclaration())
		{
	version (LOG) {
			printf("not an aggregate member\n");
	}
			return;				// then it is accessible
		}

		// BUG: should enable this check
		//assert(smember.parent.isBaseOf(this, null));

		if (smemberparent == this)
		{
			PROT access2 = smember.prot();

			result = access2 >= PROT.PROTpublic ||
				hasPrivateAccess(f) ||
				isFriendOf(cdscope) ||
				(access2 == PROT.PROTpackage && hasPackageAccess(sc, this));

version (LOG) {
			printf("result1 = %d\n", result);
}
		}
		else if ((access = this.getAccess(smember)) >= PROT.PROTpublic)
		{
			result = true;
version (LOG) {
			printf("result2 = %d\n", result);
}
		}
		else if (access == PROT.PROTpackage && hasPackageAccess(sc, this))
		{
			result = true;
version (LOG) {
			printf("result3 = %d\n", result);
}
		}
		else
		{
			result = accessCheckX(smember, f, this, cdscope);
version (LOG) {
			printf("result4 = %d\n", result);
}
		}
		if (!result)
		{
			error(loc, "member %s is not accessible", smember.toChars());
			halt();
		}
	}

    override PROT prot()
	{
		assert(false);
	}

    // Back end
    Symbol* stag;		// tag symbol for debug data
    Symbol* sinit;

    Symbol* toInitializer()
	{
		Symbol* s;
		Classsym* stag;

		if (!sinit)
		{
			stag = fake_classsym(Id.ClassInfo);
			s = toSymbolX("__init", SC.SCextern, stag.Stype, "Z");
			s.Sfl = FL.FLextern;
			s.Sflags |= SFL.SFLnodebug;
			slist_add(s);
			sinit = s;
		}

		return sinit;
	}

    override AggregateDeclaration isAggregateDeclaration() { return this; }
}
