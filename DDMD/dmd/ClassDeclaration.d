module dmd.ClassDeclaration;

import dmd.common;
import dmd.AggregateDeclaration;
import dmd.InterfaceDeclaration;
import dmd.ThisDeclaration;
import dmd.CompoundStatement;
import dmd.DeleteDeclaration;
import dmd.NewDeclaration;
import dmd.CtorDeclaration;
import dmd.TypeIdentifier;
import dmd.STC;
import dmd.Parameter;
import dmd.TypeTuple;
import dmd.TY;
import dmd.LINK;
import dmd.DsymbolTable;
import dmd.FuncDeclaration;
import dmd.Array;
import dmd.TypeClass;
import dmd.Module;
import dmd.Id;
import dmd.Type;
import dmd.OverloadSet;
import dmd.ArrayTypes;
import dmd.BaseClass;
import dmd.ClassInfoDeclaration;
import dmd.TypeInfoClassDeclaration;
import dmd.Loc;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.TypeFunction;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.VarDeclaration;
import dmd.Initializer;
import dmd.ExpInitializer;
import dmd.TypeSArray;
import dmd.ScopeDsymbol;
import dmd.PROT;
import dmd.Util;
import dmd.Global;

import dmd.expression.Util;

import dmd.backend.Symbol;
import dmd.backend.dt_t;
import dmd.backend.TYPE;
import dmd.backend.FL;
import dmd.backend.SFL;
import dmd.backend.mTY;
import dmd.backend.SC;
import dmd.backend.mTYman;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.Classsym;
import dmd.backend.glue;
import dmd.backend.RTLSYM;
import dmd.backend.LIST;

import dmd.codegen.Util;

import dmd.DDMDExtensions;

import std.string;

version (DMDV2) {
	enum CLASSINFO_SIZE = (0x3C+12+4);	// value of ClassInfo.size
} else {
	enum CLASSINFO_SIZE = (0x3C+12+4);	// value of ClassInfo.size
}

enum OFFSET_RUNTIME = 0x76543210;

struct FuncDeclarationFinder
{
	bool visit(FuncDeclaration fd2)
	{
		//printf("param = %p, fd = %p %s\n", param, fd, fd.toChars());
		return fd is fd2;
	}

	FuncDeclaration fd;
}

class ClassDeclaration : AggregateDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    ClassDeclaration baseClass;	// null only if this is Object
version(DMDV1) {
    CtorDeclaration *ctor;
    CtorDeclaration *defaultCtor;	// default constructor
}
    FuncDeclaration staticCtor;
    FuncDeclaration staticDtor;
    Array vtbl;				// Array of FuncDeclaration's making up the vtbl[]
    Array vtblFinal;			// More FuncDeclaration's that aren't in vtbl[]

    BaseClasses baseclasses;		// Array of BaseClass's; first is super,
					// rest are Interface's

    int interfaces_dim;
    BaseClass* interfaces;		// interfaces[interfaces_dim] for this class
					// (does not include baseClass)

    BaseClasses vtblInterfaces;	// array of base interfaces that have
					// their own vtbl[]

    TypeInfoClassDeclaration vclassinfo;	// the ClassInfo object for this ClassDeclaration
    bool com;				// true if this is a COM class (meaning
					// it derives from IUnknown)
    bool isauto;				// true if this is an auto class
    bool isabstract;			// true if abstract class
version(DMDV1) {
    int isnested;			// !=0 if is nested
}
    int inuse;				// to prevent recursive attempts

    this(Loc loc, Identifier id, BaseClasses baseclasses)
	{
		register();

		super(loc, id);

		vtbl = new Array();
		vtblFinal = new Array();

		enum msg = "only object.d can define this reserved class name";

		if (baseclasses) {
			this.baseclasses = baseclasses;
		} else {
			this.baseclasses = new BaseClasses();
		}

		//printf("ClassDeclaration(%s), dim = %d\n", id.toChars(), this.baseclasses.dim);

		// For forward references
		type = new TypeClass(this);

		if (id)
		{
			// Look for special class names

			if (id is Id.__sizeof || id is Id.alignof_ || id is Id.mangleof_)
				error("illegal class name");

			// BUG: What if this is the wrong TypeInfo, i.e. it is nested?
			if (id.toChars()[0] == 'T')
			{
				if (id is Id.TypeInfo)
				{
					if (global.typeinfo) {
						global.typeinfo.error("%s", msg);
					}

					global.typeinfo = this;
				}

				if (id is Id.TypeInfo_Class)
				{
					if (global.typeinfoclass)
						global.typeinfoclass.error("%s", msg);
					global.typeinfoclass = this;
				}

				if (id is Id.TypeInfo_Interface)
				{
					if (global.typeinfointerface)
						global.typeinfointerface.error("%s", msg);
					global.typeinfointerface = this;
				}

				if (id is Id.TypeInfo_Struct)
				{
					if (global.typeinfostruct)
						global.typeinfostruct.error("%s", msg);
					global.typeinfostruct = this;
				}

				if (id is Id.TypeInfo_Typedef)
				{
					if (global.typeinfotypedef)
						global.typeinfotypedef.error("%s", msg);
					global.typeinfotypedef = this;
				}

				if (id is Id.TypeInfo_Pointer)
				{
					if (global.typeinfopointer)
						global.typeinfopointer.error("%s", msg);
					global.typeinfopointer = this;
				}

				if (id is Id.TypeInfo_Array)
				{
					if (global.typeinfoarray)
						global.typeinfoarray.error("%s", msg);
					global.typeinfoarray = this;
				}

				if (id is Id.TypeInfo_StaticArray)
				{	//if (global.typeinfostaticarray)
					//global.typeinfostaticarray.error("%s", msg);
					global.typeinfostaticarray = this;
				}

				if (id is Id.TypeInfo_AssociativeArray)
				{
					if (global.typeinfoassociativearray)
						global.typeinfoassociativearray.error("%s", msg);
					global.typeinfoassociativearray = this;
				}

				if (id is Id.TypeInfo_Enum)
				{
					if (global.typeinfoenum)
						global.typeinfoenum.error("%s", msg);
					global.typeinfoenum = this;
				}

				if (id is Id.TypeInfo_Function)
				{
					if (global.typeinfofunction)
						global.typeinfofunction.error("%s", msg);
					global.typeinfofunction = this;
				}

				if (id is Id.TypeInfo_Delegate)
				{
					if (global.typeinfodelegate)
						global.typeinfodelegate.error("%s", msg);
					global.typeinfodelegate = this;
				}

				if (id is Id.TypeInfo_Tuple)
				{
					if (global.typeinfotypelist)
						global.typeinfotypelist.error("%s", msg);
					global.typeinfotypelist = this;
				}

	version (DMDV2) {
				if (id is Id.TypeInfo_Const)
				{
					if (global.typeinfoconst)
						global.typeinfoconst.error("%s", msg);
					global.typeinfoconst = this;
				}

				if (id is Id.TypeInfo_Invariant)
				{
					if (global.typeinfoinvariant)
						global.typeinfoinvariant.error("%s", msg);
					global.typeinfoinvariant = this;
				}

				if (id is Id.TypeInfo_Shared)
				{
					if (global.typeinfoshared)
						global.typeinfoshared.error("%s", msg);
					global.typeinfoshared = this;
				}

	            if (id == Id.TypeInfo_Wild)
	            {
                    if (global.typeinfowild)
		                global.typeinfowild.error("%s", msg);
		            global.typeinfowild = this;
	            }
	}
			}

			if (id is Id.Object_)
			{
				if (global.object)
					global.object.error("%s", msg);
				global.object = this;
			}

//			if (id is Id.ClassInfo)
			if (id is Id.TypeInfo_Class)
			{
				if (global.classinfo)
					global.classinfo.error("%s", msg);
				global.classinfo = this;
			}

			if (id is Id.ModuleInfo)
			{
				if (global.moduleinfo)
					global.moduleinfo.error("%s", msg);
				global.moduleinfo = this;
			}
		}

		com = 0;
		isauto = false;
		isabstract = false;
		inuse = 0;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		ClassDeclaration cd;

		//printf("ClassDeclaration.syntaxCopy('%s')\n", toChars());
		if (s)
			cd = cast(ClassDeclaration)s;
		else
		cd = new ClassDeclaration(loc, ident, null);

		cd.storage_class |= storage_class;

		cd.baseclasses.setDim(this.baseclasses.dim);
		for (size_t i = 0; i < cd.baseclasses.dim; i++)
		{
			auto b = this.baseclasses[i];
			auto b2 = new BaseClass(b.type.syntaxCopy(), b.protection);
			cd.baseclasses[i] = b2;
		}

		ScopeDsymbol.syntaxCopy(cd);
		return cd;
	}

    override void semantic(Scope sc)
	{
		uint offset;

		//printf("ClassDeclaration.semantic(%s), type = %p, sizeok = %d, this = %p\n", toChars(), type, sizeok, this);
		//printf("\tparent = %p, '%s'\n", sc.parent, sc.parent ? sc.parent.toChars() : "");
		//printf("sc.stc = %x\n", sc.stc);

		//{ static int n;  if (++n == 20) *(char*)0=0; }

		if (!ident)		// if anonymous class
		{
			string id = "__anonclass";
			ident = Identifier.generateId(id);
		}

		if (!sc)
			sc = scope_;

		if (!parent && sc.parent && !sc.parent.isModule())
			parent = sc.parent;

		type = type.semantic(loc, sc);
		handle = type;

		if (!members)			// if forward reference
		{
			//printf("\tclass '%s' is forward referenced\n", toChars());
			return;
		}
		if (symtab)
		{	if (sizeok == 1 || !scope_)
		{   //printf("\tsemantic for '%s' is already completed\n", toChars());
			return;		// semantic() already completed
		}
		}
		else
		symtab = new DsymbolTable();

		Scope scx = null;
		if (scope_)
		{	
			sc = scope_;
			scx = scope_;		// save so we don't make redundant copies
			scope_ = null;
		}
	    uint dprogress_save = global.dprogress;
version (IN_GCC) {
		methods.setDim(0);
}

		if (sc.stc & STC.STCdeprecated)
		{
		isdeprecated = 1;
		}

		if (sc.linkage == LINK.LINKcpp)
		error("cannot create C++ classes");

		// Expand any tuples in baseclasses[]
		for (size_t i = 0; i < baseclasses.dim; )
		{
			auto b = baseclasses[i];
		//printf("test1 %s %s\n", toChars(), b.type.toChars());
			b.type = b.type.semantic(loc, sc);
		//printf("test2\n");
			Type tb = b.type.toBasetype();

			if (tb.ty == TY.Ttuple)
			{
				TypeTuple tup = cast(TypeTuple)tb;
				PROT protection = b.protection;
				baseclasses.remove(i);
				size_t dim = Parameter.dim(tup.arguments);
				for (size_t j = 0; j < dim; j++)
				{
					auto arg = Parameter.getNth(tup.arguments, j);
					b = new BaseClass(arg.type, protection);
					baseclasses.insert(i + j, b);
				}
			}
			else
				i++;
		}

		// See if there's a base class as first in baseclasses[]
		if (baseclasses.dim)
		{
			TypeClass tc;
			BaseClass b;
			Type tb;

			b = baseclasses[0];
			//b.type = b.type.semantic(loc, sc);
			tb = b.type.toBasetype();
			if (tb.ty != TY.Tclass)
			{   error("base type must be class or interface, not %s", b.type.toChars());
				baseclasses.remove(0);
			}
			else
			{
				tc = cast(TypeClass)(tb);

				if (tc.sym.isDeprecated())
				{
				if (!isDeprecated())
				{
					// Deriving from deprecated class makes this one deprecated too
					isdeprecated = 1;

					tc.checkDeprecated(loc, sc);
				}
				}

				if (tc.sym.isInterfaceDeclaration()) {
					//;
				} else {
					for (ClassDeclaration cdb = tc.sym; cdb; cdb = cdb.baseClass)
					{
						if (cdb == this)
						{
							error("circular inheritance");
							baseclasses.remove(0);
							goto L7;
						}
					}
					if (!tc.sym.symtab || tc.sym.sizeok == 0)
					{   // Try to resolve forward reference
						if (sc.mustsemantic && tc.sym.scope_)
						tc.sym.semantic(null);
					}
					if (!tc.sym.symtab || tc.sym.scope_ || tc.sym.sizeok == 0)
					{
						//printf("%s: forward reference of base class %s\n", toChars(), tc.sym.toChars());
						//error("forward reference of base class %s", baseClass.toChars());
						// Forward reference of base class, try again later
						//printf("\ttry later, forward reference of base class %s\n", tc.sym.toChars());
						scope_ = scx ? scx : sc.clone();
						scope_.setNoFree();
						if (tc.sym.scope_)
							tc.sym.scope_.module_.addDeferredSemantic(tc.sym);
						scope_.module_.addDeferredSemantic(this);
						return;
					}
					else
					{   baseClass = tc.sym;
						b.base = baseClass;
					}
				 L7: ;
				}
			}
		}

		// Treat the remaining entries in baseclasses as interfaces
		// Check for errors, handle forward references
		for (int i = (baseClass ? 1 : 0); i < baseclasses.dim; )
		{	TypeClass tc;
		BaseClass b;
		Type tb;

		b = baseclasses[i];
		b.type = b.type.semantic(loc, sc);
		tb = b.type.toBasetype();
		if (tb.ty == TY.Tclass)
			tc = cast(TypeClass)tb;
		else
			tc = null;
		if (!tc || !tc.sym.isInterfaceDeclaration())
		{
			error("base type must be interface, not %s", b.type.toChars());
			baseclasses.remove(i);
			continue;
		}
		else
		{
			if (tc.sym.isDeprecated())
			{
			if (!isDeprecated())
			{
				// Deriving from deprecated class makes this one deprecated too
				isdeprecated = 1;

				tc.checkDeprecated(loc, sc);
			}
			}

			// Check for duplicate interfaces
			for (size_t j = (baseClass ? 1 : 0); j < i; j++)
			{
			auto b2 = baseclasses[j];
			if (b2.base == tc.sym)
				error("inherits from duplicate interface %s", b2.base.toChars());
			}

			if (!tc.sym.symtab)
			{   // Try to resolve forward reference
			if (sc.mustsemantic && tc.sym.scope_)
				tc.sym.semantic(null);
			}

			b.base = tc.sym;
			if (!b.base.symtab || b.base.scope_)
			{
			//error("forward reference of base class %s", baseClass.toChars());
			// Forward reference of base, try again later
			//printf("\ttry later, forward reference of base %s\n", baseClass.toChars());
			scope_ = scx ? scx : sc.clone();
			scope_.setNoFree();
			if (tc.sym.scope_)
				tc.sym.scope_.module_.addDeferredSemantic(tc.sym);
			scope_.module_.addDeferredSemantic(this);
			return;
			}
		}
		i++;
		}


		// If no base class, and this is not an Object, use Object as base class
		if (!baseClass && ident !is Id.Object_)
		{
			// BUG: what if Object is redefined in an inner scope?
			Type tbase = new TypeIdentifier(Loc(0), Id.Object_);
			BaseClass b;
			TypeClass tc;
			Type bt;

			if (!global.object)
			{
				error("missing or corrupt object.d");
				fatal();
			}
			bt = tbase.semantic(loc, sc).toBasetype();
			b = new BaseClass(bt, PROT.PROTpublic);
			baseclasses.shift(b);
			assert(b.type.ty == TY.Tclass);
			tc = cast(TypeClass)(b.type);
			baseClass = tc.sym;
			assert(!baseClass.isInterfaceDeclaration());
			b.base = baseClass;
		}

		interfaces_dim = baseclasses.dim;
		interfaces = baseclasses.ptr;

		if (baseClass)
		{
			if (baseClass.storage_class & STC.STCfinal)
				error("cannot inherit from final class %s", baseClass.toChars());

			interfaces_dim--;
			interfaces++;

			// Copy vtbl[] from base class
			vtbl.setDim(baseClass.vtbl.dim);
			memcpy(vtbl.data, baseClass.vtbl.data, (void*).sizeof * vtbl.dim);

			// Inherit properties from base class
			com = baseClass.isCOMclass();
			isauto = baseClass.isauto;
			vthis = baseClass.vthis;
			storage_class |= baseClass.storage_class & STC.STC_TYPECTOR;
		}
		else
		{
			// No base class, so this is the root of the class hierarchy
			vtbl.setDim(0);
			vtbl.push(cast(void*)this);		// leave room for classinfo as first member
		}

		protection = sc.protection;
		storage_class |= sc.stc;

		if (sizeok == 0)
		{
		interfaceSemantic(sc);

		foreach (s; members)
			s.addMember(sc, this, true);

		/* If this is a nested class, add the hidden 'this'
		 * member which is a pointer to the enclosing scope.
		 */
		if (vthis)		// if inheriting from nested class
		{   // Use the base class's 'this' member
			isnested = true;
			if (storage_class & STC.STCstatic)
			error("static class cannot inherit from nested class %s", baseClass.toChars());
			if (toParent2() != baseClass.toParent2())
			{
			if (toParent2())
			{
				error("is nested within %s, but super class %s is nested within %s",
				toParent2().toChars(),
				baseClass.toChars(),
				baseClass.toParent2().toChars());
			}
			else
			{
				error("is not nested, but super class %s is nested within %s",
				baseClass.toChars(),
				baseClass.toParent2().toChars());
			}
			isnested = false;
			}
		}
		else if (!(storage_class & STC.STCstatic))
		{
			Dsymbol s = toParent2();
			if (s)
			{
				AggregateDeclaration ad = s.isClassDeclaration();
				FuncDeclaration fd = s.isFuncDeclaration();

				if (ad || fd)
				{   isnested = true;
					Type t;
					if (ad)
						t = ad.handle;
					else if (fd)
					{
						AggregateDeclaration ad2 = fd.isMember2();
						if (ad2)
							t = ad2.handle;
						else
						{
							t = global.tvoidptr;
						}
					}
					else
						assert(0);
					if (t.ty == TY.Tstruct)	// ref to struct
						t = global.tvoidptr;
					assert(!vthis);
					vthis = new ThisDeclaration(loc, t);
					members.push(vthis);
				}
			}
		}
		}

		if (storage_class & (STC.STCauto | STC.STCscope))
			isauto = true;
		if (storage_class & STC.STCabstract)
			isabstract = true;
		if (storage_class & STC.STCimmutable)
			type = type.invariantOf();
		else if (storage_class & STC.STCconst)
			type = type.constOf();
		else if (storage_class & STC.STCshared)
			type = type.sharedOf();

		sc = sc.push(this);
		sc.stc &= ~(STC.STCfinal | STC.STCauto | STC.STCscope | STC.STCstatic |
			 STC.STCabstract | STC.STCdeprecated | STC.STC_TYPECTOR | STC.STCtls | STC.STCgshared);
		sc.stc |= storage_class & STC.STC_TYPECTOR;
		sc.parent = this;
		sc.inunion = 0;

		if (isCOMclass())
		{
version (Windows) {
		sc.linkage = LINK.LINKwindows;
} else {
		/* This enables us to use COM objects under Linux and
		 * work with things like XPCOM
		 */
		sc.linkage = LINK.LINKc;
}
		}
		sc.protection = PROT.PROTpublic;
		sc.explicitProtection = 0;
		sc.structalign = 8;
		structalign = sc.structalign;
		if (baseClass)
		{	sc.offset = baseClass.structsize;
		alignsize = baseClass.alignsize;
	//	if (isnested)
	//	    sc.offset += PTRSIZE;	// room for uplevel context pointer
		}
		else
		{	sc.offset = PTRSIZE * 2;	// allow room for __vptr and __monitor
		alignsize = PTRSIZE;
		}
		structsize = sc.offset;
		Scope scsave = sc.clone();
		sizeok = 0;

        /* Set scope so if there are forward references, we still might be able to
         * resolve individual members like enums.
         */
        foreach (s; members)
        {
	        /* There are problems doing this in the general case because
	         * Scope keeps track of things like 'offset'
	         */
	        if (s.isEnumDeclaration() || (s.isAggregateDeclaration() && s.ident))
	        {
	            //printf("setScope %s %s\n", s->kind(), s->toChars());
	            s.setScope(sc);
	        }
        }

		foreach (Dsymbol s; members) {
			s.semantic(sc);
		}

		if (sizeok == 2)
		{	
			// semantic() failed because of forward references.
			// Unwind what we did, and defer it for later
			fields.setDim(0);
			structsize = 0;
			alignsize = 0;
			structalign = 0;

			sc = sc.pop();

			scope_ = scx ? scx : sc.clone();
			scope_.setNoFree();
			scope_.module_.addDeferredSemantic(this);
			
			global.dprogress = dprogress_save;

			//printf("\tsemantic('%s') failed due to forward references\n", toChars());
			return;
		}

		//printf("\tsemantic('%s') successful\n", toChars());

		structsize = sc.offset;
		//members.print();

		/* Look for special member functions.
		 * They must be in this class, not in a base class.
		 */
		ctor = cast(CtorDeclaration)search(Loc(0), Id.ctor, 0);
		if (ctor && (ctor.toParent() != this || !ctor.isCtorDeclaration()))
			ctor = null;

	//    dtor = (DtorDeclaration *)search(Id.dtor, 0);
	//    if (dtor && dtor.toParent() != this)
	//	dtor = null;

	//    inv = (InvariantDeclaration *)search(Id.classInvariant, 0);
	//    if (inv && inv.toParent() != this)
	//	inv = null;

		// Can be in base class
		aggNew = cast(NewDeclaration)search(Loc(0), Id.classNew, 0);
		aggDelete = cast(DeleteDeclaration)search(Loc(0), Id.classDelete, 0);

		// If this class has no constructor, but base class does, create
		// a constructor:
		//    this() { }
		if (!ctor && baseClass && baseClass.ctor)
		{
			//printf("Creating default this(){} for class %s\n", toChars());
			CtorDeclaration ctor = new CtorDeclaration(loc, Loc(0), null, 0);
			ctor.fbody = new CompoundStatement(Loc(0), new Statements());
			members.push(ctor);
			ctor.addMember(sc, this, true);
			sc = scsave;	// why? What about sc.nofree?	///
			sc.offset = structsize;
			ctor.semantic(sc);
			this.ctor = ctor;
			defaultCtor = ctor;
		}

static if (false) {
		if (baseClass)
		{	
			if (!aggDelete)
				aggDelete = baseClass.aggDelete;
			if (!aggNew)
				aggNew = baseClass.aggNew;
		}
}

		// Allocate instance of each new interface
		foreach (b; vtblInterfaces)
		{
			uint thissize = PTRSIZE;

			alignmember(structalign, thissize, &sc.offset);
			assert(b.offset == 0);
			b.offset = sc.offset;

			// Take care of single inheritance offsets
			while (b.baseInterfaces.length)
			{
				b = b.baseInterfaces[0];
				b.offset = sc.offset;
			}

			sc.offset += thissize;
			if (alignsize < thissize)
				alignsize = thissize;
		}
		structsize = sc.offset;
		sizeok = 1;
		global.dprogress++;

		dtor = buildDtor(sc);

		sc.pop();

static if (false) { // Do not call until toObjfile() because of forward references
		// Fill in base class vtbl[]s
		for (int i = 0; i < vtblInterfaces.dim; i++)
		{
			BaseClass b = cast(BaseClass)vtblInterfaces.data[i];

		//b.fillVtbl(this, &b.vtbl, 1);
		}
}
		//printf("-ClassDeclaration.semantic(%s), type = %p\n", toChars(), type);
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		if (!isAnonymous())
		{
			buf.printf("%s ", kind());
			buf.writestring(toChars());
			if (baseclasses.dim)
				buf.writestring(" : ");
		}
		foreach (size_t i, BaseClass b; baseclasses)
		{
			if (i)
				buf.writeByte(',');
			//buf.writestring(b.base.ident.toChars());
			b.type.toCBuffer(buf, null, hgs);
		}
		if (members)
		{
			buf.writenl();
			buf.writeByte('{');
			buf.writenl();
			foreach (s; members)
			{
				buf.writestring("    ");
				s.toCBuffer(buf, hgs);
			}
			buf.writestring("}");
		}
		else
			buf.writeByte(';');
		buf.writenl();
	}

	/*********************************************
	 * Determine if 'this' is a base class of cd.
	 * This is used to detect circular inheritance only.
	 */
    int isBaseOf2(ClassDeclaration cd)
	{
		if (!cd)
			return 0;
		//printf("ClassDeclaration::isBaseOf2(this = '%s', cd = '%s')\n", toChars(), cd.toChars());
		foreach (b; cd.baseclasses)
		{
			if (b.base is this || isBaseOf2(b.base))
				return 1;
		}
		return 0;
	}

	/*******************************************
	 * Determine if 'this' is a base class of cd.
	 */
///    #define OFFSET_RUNTIME 0x76543210
    bool isBaseOf(ClassDeclaration cd, int* poffset)
	{
		if (!cd)
			return 0;
		//printf("ClassDeclaration::isBaseOf2(this = '%s', cd = '%s')\n", toChars(), cd.toChars());
		foreach (b; cd.baseclasses)
		{
			if (b.base == this || isBaseOf2(b.base))
				return 1;
		}

		return 0;
	}

    override Dsymbol search(Loc, Identifier ident, int flags)
	{
		Dsymbol s;
		//printf("%s.ClassDeclaration.search('%s')\n", toChars(), ident.toChars());

		if (scope_)
		{
			Scope sc = scope_;
			sc.mustsemantic++;
			semantic(sc);
			sc.mustsemantic--;
		}

		if (!members || !symtab || scope_)
		{
			error("is forward referenced when looking for '%s'", ident.toChars());
			//*(char*)0=0;
			return null;
		}

		s = ScopeDsymbol.search(loc, ident, flags);
		if (!s)
		{
			// Search bases classes in depth-first, left to right order

			int i;

			foreach (b; baseclasses)
			{
				if (b.base)
				{
					if (!b.base.symtab)
						error("base %s is forward referenced", b.base.ident.toChars());
					else
					{
						s = b.base.search(loc, ident, flags);
						if (s is this)	// happens if s is nested in this and derives from this
							s = null;
						else if (s)
							break;
					}
				}
			}
		}
		return s;
	}

version (DMDV2) {
    bool isFuncHidden(FuncDeclaration fd)
	{
		//printf("ClassDeclaration::isFuncHidden(class = %s, fd = %s)\n", toChars(), fd.toChars());
		Dsymbol s = search(Loc(0), fd.ident, 4|2);
		if (!s)
		{
			//printf("not found\n");
			/* Because, due to a hack, if there are multiple definitions
			 * of fd.ident, null is returned.
			 */
			return false;
		}

		FuncDeclarationFinder p; p.fd = fd;

		s = s.toAlias();
		OverloadSet os = s.isOverloadSet();
		if (os)
		{
			foreach (s2; os.a)
			{
				auto f2 = s2.isFuncDeclaration();
				if (f2 && overloadApply(f2, p))
					return false;
			}
			return true;
		}
		else
		{
			FuncDeclaration fdstart = s.isFuncDeclaration();
			//printf("%s fdstart = %p\n", s.kind(), fdstart);
			return !overloadApply(fdstart, p);
		}
	}
}
    FuncDeclaration findFunc(Identifier ident, TypeFunction tf)
	{
		//printf("ClassDeclaration.findFunc(%s, %s) %s\n", ident.toChars(), tf.toChars(), toChars());

		ClassDeclaration cd = this;
		Array vtbl = cd.vtbl;
		while (true)
		{
			for (size_t i = 0; i < vtbl.dim; i++)
			{
				FuncDeclaration fd = (cast(Dsymbol)vtbl.data[i]).isFuncDeclaration();
				if (!fd)
					continue;		// the first entry might be a ClassInfo

				//printf("\t[%d] = %s\n", i, fd.toChars());
				if (ident == fd.ident &&
					//tf.equals(fd.type)
					fd.type.covariant(tf) == 1
				   )
				{   //printf("\t\tfound\n");
					return fd;
				}
				//else printf("\t\t%d\n", fd.type.covariant(tf));
			}
			if (!cd)
				break;

			vtbl = cd.vtblFinal;
			cd = cd.baseClass;
		}

		return null;
	}

    void interfaceSemantic(Scope sc)
	{
		InterfaceDeclaration id = isInterfaceDeclaration();

		vtblInterfaces = new BaseClasses();
		vtblInterfaces.reserve(interfaces_dim);

		for (size_t i = 0; i < interfaces_dim; i++)
		{
			BaseClass b = interfaces[i];

			// If this is an interface, and it derives from a COM interface,
			// then this is a COM interface too.
			if (b.base.isCOMinterface())
				com = 1;

			if (b.base.isCPPinterface() && id)
				id.cpp = 1;

			vtblInterfaces.push(b);
			b.copyBaseInterfaces(vtblInterfaces);
		}
	}

version(DMDV1)
{
    int isNested()
	{
		assert(false);
	}
}
    bool isCOMclass()
	{
		return com;
	}

    bool isCOMinterface()
	{
		return false;
	}

version (DMDV2) {
    bool isCPPinterface()
	{
		return false;
	}
}
    bool isAbstract()
	{
		if (isabstract)
			return true;

		for (int i = 1; i < vtbl.dim; i++)
		{
			FuncDeclaration fd = (cast(Dsymbol)vtbl.data[i]).isFuncDeclaration();

			//printf("\tvtbl[%d] = %p\n", i, fd);
			if (!fd || fd.isAbstract())
			{
				isabstract = true;
				return true;
			}
		}

		return false;
	}

    int vtblOffset()
	{
		assert(false);
	}

    override string kind()
	{
		return "class";
	}

    override string mangle()
	{
		Dsymbol parentsave = parent;

		//printf("ClassDeclaration.mangle() %s.%s\n", parent.toChars(), toChars());

		/* These are reserved to the compiler, so keep simple
		 * names for them.
		 */
		if (ident is Id.Exception)
		{
			if (parent.ident is Id.object)
				parent = null;
		}
		else if (ident is Id.TypeInfo   ||
		//	ident is Id.Exception ||
			ident is Id.TypeInfo_Struct   ||
			ident is Id.TypeInfo_Class    ||
			ident is Id.TypeInfo_Typedef  ||
			ident is Id.TypeInfo_Tuple ||
			this is global.object     ||
			this is global.classinfo  ||
			this is global.moduleinfo ||
			ident.toChars().startsWith("TypeInfo_")
		   )
		{
			parent = null;
		}

		string id = Dsymbol.mangle();
		parent = parentsave;
		return id;
	}

    override void toDocBuffer(OutBuffer buf)
	{
		assert(false);
	}

    override PROT getAccess(Dsymbol smember)	// determine access to smember
	{
		PROT access_ret = PROT.PROTnone;

	version (LOG) {
		printf("+ClassDeclaration::getAccess(this = '%s', smember = '%s')\n",
			toChars(), smember.toChars());
	}
		if (smember.toParent() is this)
		{
			access_ret = smember.prot();
		}
		else
		{
			PROT access;

			if (smember.isDeclaration().isStatic())
			{
				access_ret = smember.prot();
			}

			foreach (b; baseclasses)
			{
				access = b.base.getAccess(smember);
				switch (access)
				{
					case PROT.PROTnone:
						break;

					case PROT.PROTprivate:
						access = PROT.PROTnone;	// private members of base class not accessible
						break;

					case PROT.PROTpackage:
					case PROT.PROTprotected:
					case PROT.PROTpublic:
					case PROT.PROTexport:
						// If access is to be tightened
						if (b.protection < access)
							access = b.protection;

						// Pick path with loosest access
						if (access > access_ret)
							access_ret = access;
						break;

					default:
						assert(0);
				}
			}
		}

	version (LOG) {
		printf("-ClassDeclaration::getAccess(this = '%s', smember = '%s') = %d\n",
			toChars(), smember.toChars(), access_ret);
	}

		return access_ret;
	}

    override void addLocalClass(ClassDeclarations aclasses)
	{
		aclasses.push(this);
	}

    // Back end
    override void toObjFile(int multiobj)			// compile to .obj file
	{
		uint offset;
		Symbol* sinit;
		enum_SC scclass;

		//printf("ClassDeclaration.toObjFile('%s')\n", toChars());

		if (!members)
			return;

		if (multiobj)
		{
			obj_append(this);
			return;
		}

		if (global.params.symdebug)
			toDebug();

		assert(!scope_);	// semantic() should have been run to completion

		scclass = SCglobal;
		if (inTemplateInstance())
			scclass = SCcomdat;

		// Put out the members
		foreach (member; members)
			member.toObjFile(0);

static if (false) {
		// Build destructor by aggregating dtors[]
		Symbol* sdtor;
		switch (dtors.dim)
		{
			case 0:
				// No destructors for this class
				sdtor = null;
				break;

			case 1:
				// One destructor, just use it directly
				sdtor = (cast(DtorDeclaration)dtors.data[0]).toSymbol();
				break;

			default:
			{
				/* Build a destructor that calls all the
				 * other destructors in dtors[].
				 */

				elem* edtor = null;

				// Declare 'this' pointer for our new destructor
				Symbol* sthis = symbol_calloc("this");
				sthis.Stype = type_fake(TYnptr);
				sthis.Stype.Tcount++;
				sthis.Sclass = SCfastpar;
				sthis.Spreg = AX;
				sthis.Sfl = FLauto;

				// Call each of the destructors in dtors[]
				// in reverse order
				for (size_t i = 0; i < dtors.dim; i++)
				{
					DtorDeclaration d = cast(DtorDeclaration)dtors.data[i];
					Symbol* s = d.toSymbol();
					elem* e = el_bin(OPcall, TYvoid, el_var(s), el_var(sthis));
					edtor = el_combine(e, edtor);
				}

				// Create type for the function
				.type* t = type_alloc(TYjfunc);
				t.Tflags |= TFprototype | TFfixed;
				t.Tmangle = mTYman_d;
				t.Tnext = tsvoid;
				tsvoid.Tcount++;

				// Create the function, sdtor, and write it out
				localgot = null;
				sdtor = toSymbolX("__dtor", SCglobal, t, "FZv");
				block* b = block_calloc();
				b.BC = BCret;
				b.Belem = edtor;
				sdtor.Sfunc.Fstartblock = b;
				cstate.CSpsymtab = &sdtor.Sfunc.Flocsym;
				symbol_add(sthis);
				writefunc(sdtor);
			}
		}
}

		// Generate C symbols
		toSymbol();
		toVtblSymbol();
		sinit = toInitializer();

		//////////////////////////////////////////////

		// Generate static initializer
		sinit.Sclass = scclass;
		sinit.Sfl = FLdata;
	version (ELFOBJ) { // Burton
		sinit.Sseg = Segment.CDATA;
	}
	version (MACHOBJ) {
		sinit.Sseg = Segment.DATA;
	}
		toDt(&sinit.Sdt);
		outdata(sinit);

		//////////////////////////////////////////////

		// Put out the TypeInfo
		type.getTypeInfo(null);
		//type.vtinfo.toObjFile(multiobj);

		//////////////////////////////////////////////

		// Put out the ClassInfo
		csym.Sclass = scclass;
		csym.Sfl = FLdata;

		/* The layout is:
		   {
			void **vptr;
			monitor_t monitor;
			byte[] initializer;		// static initialization data
			char[] name;		// class name
			void *[] vtbl;
			Interface[] interfaces;
			ClassInfo *base;		// base class
			void *destructor;
			void *invariant;		// class invariant
			uint flags;
			void *deallocator;
			OffsetTypeInfo[] offTi;
			void *defaultConstructor;
			const(MemberInfo[]) function(string) xgetMembers;	// module getMembers() function
			//TypeInfo typeinfo;
		   }
		 */
		dt_t* dt = null;
		offset = CLASSINFO_SIZE;			// must be ClassInfo.size
		if (global.classinfo)
		{
			if (global.classinfo.structsize != CLASSINFO_SIZE)
				error("D compiler and phobos' object.d are mismatched");

			dtxoff(&dt, global.classinfo.toVtblSymbol(), 0, TYnptr); // vtbl for ClassInfo
		}
		else
		{
			dtdword(&dt, 0);		// BUG: should be an assert()
		}

		dtdword(&dt, 0);			// monitor

		// initializer[]
		assert(structsize >= 8);
		dtdword(&dt, structsize);		// size
		dtxoff(&dt, sinit, 0, TYnptr);	// initializer

		// name[]
		string name = ident.toChars();
		size_t namelen = name.length;
		if (!(namelen > 9 && name[0..9] == "TypeInfo_"))
		{
			name = toPrettyChars();
			namelen = name.length;
		}
		dtdword(&dt, namelen);
		dtabytes(&dt, TYnptr, 0, namelen + 1, toStringz(name));

		// vtbl[]
		dtdword(&dt, vtbl.dim);
		dtxoff(&dt, vtblsym, 0, TYnptr);

		// interfaces[]
		dtdword(&dt, vtblInterfaces.dim);
		if (vtblInterfaces.dim)
			dtxoff(&dt, csym, offset, TYnptr);	// (*)
		else
			dtdword(&dt, 0);

		// base
		if (baseClass)
			dtxoff(&dt, baseClass.toSymbol(), 0, TYnptr);
		else
			dtdword(&dt, 0);

		// destructor
		if (dtor)
			dtxoff(&dt, dtor.toSymbol(), 0, TYnptr);
		else
			dtdword(&dt, 0);

		// invariant
		if (inv)
			dtxoff(&dt, inv.toSymbol(), 0, TYnptr);
		else
			dtdword(&dt, 0);

		// flags
		int flags = 4 | isCOMclass();
	version (DMDV2) {
		flags |= 16;
	}
		flags |= 32;

		if (ctor)
			flags |= 8;
		for (ClassDeclaration cd = this; cd; cd = cd.baseClass)
		{
			if (cd.members)
			{
				foreach (sm; cd.members)
				{
					//printf("sm = %s %s\n", sm.kind(), sm.toChars());
					if (sm.hasPointers())
						goto L2;
				}
			}
		}
		flags |= 2;			// no pointers
	  L2:
		dtdword(&dt, flags);


		// deallocator
		if (aggDelete)
			dtxoff(&dt, aggDelete.toSymbol(), 0, TYnptr);
		else
			dtdword(&dt, 0);

		// offTi[]
		dtdword(&dt, 0);
		dtdword(&dt, 0);		// null for now, fix later

		// defaultConstructor
		if (defaultCtor)
			dtxoff(&dt, defaultCtor.toSymbol(), 0, TYnptr);
		else
			dtdword(&dt, 0);

	version (DMDV2) {
		FuncDeclaration sgetmembers = findGetMembers();
		if (sgetmembers)
			dtxoff(&dt, sgetmembers.toSymbol(), 0, TYnptr);
		else
			dtdword(&dt, 0);	// module getMembers() function
	}

		//dtxoff(&dt, type.vtinfo.toSymbol(), 0, TYnptr);	// typeinfo
		//dtdword(&dt, 0);

		//////////////////////////////////////////////

		// Put out vtblInterfaces.data[]. Must immediately follow csym, because
		// of the fixup (*)

		offset += vtblInterfaces.dim * (4 * PTRSIZE);
		foreach (b; vtblInterfaces)
		{
			ClassDeclaration id = b.base;

			/* The layout is:
	         *  struct Interface
             *  {
			 *	ClassInfo *interface;
			 *	void *[] vtbl;
			 *	ptrdiff_t offset;
			 *  }
			 */

			// Fill in vtbl[]
			b.fillVtbl(this, b.vtbl, 1);

			dtxoff(&dt, id.toSymbol(), 0, TYnptr);		// ClassInfo

			// vtbl[]
			dtdword(&dt, id.vtbl.dim);
			dtxoff(&dt, csym, offset, TYnptr);

			dtdword(&dt, b.offset);			// this offset

			offset += id.vtbl.dim * PTRSIZE;
		}

		// Put out the vtblInterfaces.data[].vtbl[]
		// This must be mirrored with ClassDeclaration.baseVtblOffset()
		//printf("putting out %d interface vtbl[]s for '%s'\n", vtblInterfaces.dim, toChars());
		foreach (size_t i, BaseClass b; vtblInterfaces)
		{
			ClassDeclaration id = b.base;
			int j;

			//printf("    interface[%d] is '%s'\n", i, id.toChars());
			j = 0;
			if (id.vtblOffset())
			{
				// First entry is ClassInfo reference
				//dtxoff(&dt, id.toSymbol(), 0, TYnptr);

				// First entry is struct Interface reference
				dtxoff(&dt, csym, CLASSINFO_SIZE + i * (4 * PTRSIZE), TYnptr);
				j = 1;
			}

			assert(id.vtbl.dim == b.vtbl.dim);
			for (; j < id.vtbl.dim; j++)
			{
				assert(j < b.vtbl.dim);
		static if (false) {
				Object o = cast(Object)b.vtbl.data[j];
				if (o)
				{
					printf("o = %p\n", o);
					assert(o.dyncast() == DYNCAST_DSYMBOL);
					Dsymbol s = cast(Dsymbol)o;
					printf("s.kind() = '%s'\n", s.kind());
				}
		}
				auto fd = cast(FuncDeclaration)b.vtbl.data[j];
				if (fd)
					dtxoff(&dt, fd.toThunkSymbol(b.offset), 0, TYnptr);
				else
					dtdword(&dt, 0);
			}
		}

	static if (true) {
		// Put out the overriding interface vtbl[]s.
		// This must be mirrored with ClassDeclaration.baseVtblOffset()
		//printf("putting out overriding interface vtbl[]s for '%s' at offset x%x\n", toChars(), offset);
		ClassDeclaration cd;
		scope Array bvtbl = new Array();

		for (cd = this.baseClass; cd; cd = cd.baseClass)
		{
			foreach (size_t k, BaseClass bs; cd.vtblInterfaces)
			{
				if (bs.fillVtbl(this, bvtbl, 0))
				{
					//printf("\toverriding vtbl[] for %s\n", bs.base.toChars());
					ClassDeclaration id = bs.base;
					int j;

					j = 0;
					if (id.vtblOffset())
					{
						// First entry is ClassInfo reference
						//dtxoff(&dt, id.toSymbol(), 0, TYnptr);

						// First entry is struct Interface reference
						dtxoff(&dt, cd.toSymbol(), CLASSINFO_SIZE + k * (4 * PTRSIZE), TYnptr);
						j = 1;
					}

					for (; j < id.vtbl.dim; j++)
					{
						assert(j < bvtbl.dim);
						FuncDeclaration fd = cast(FuncDeclaration)bvtbl.data[j];
						if (fd)
							dtxoff(&dt, fd.toThunkSymbol(bs.offset), 0, TYnptr);
						else
							dtdword(&dt, 0);
					}
				}
			}
		}
	}

	version (INTERFACE_VIRTUAL) {
		// Put out the overriding interface vtbl[]s.
		// This must be mirrored with ClassDeclaration.baseVtblOffset()
		//printf("putting out overriding interface vtbl[]s for '%s' at offset x%x\n", toChars(), offset);
		for (size_t i = 0; i < vtblInterfaces.dim; i++)
		{
			BaseClass b = cast(BaseClass)vtblInterfaces.data[i];
			ClassDeclaration cd;

			for (cd = this.baseClass; cd; cd = cd.baseClass)
			{
				for (int k = 0; k < cd.vtblInterfaces.dim; k++)
				{
					BaseClass bs = cast(BaseClass)cd.vtblInterfaces.data[k];

					if (b.base == bs.base)
					{
						//printf("\toverriding vtbl[] for %s\n", b.base.toChars());
						ClassDeclaration id = b.base;
						int j;

						j = 0;
						if (id.vtblOffset())
						{
							// First entry is ClassInfo reference
							//dtxoff(&dt, id.toSymbol(), 0, TYnptr);

							// First entry is struct Interface reference
							dtxoff(&dt, cd.toSymbol(), CLASSINFO_SIZE + k * (4 * PTRSIZE), TYnptr);
							j = 1;
						}

						for (; j < id.vtbl.dim; j++)
						{
							assert(j < b.vtbl.dim);
							FuncDeclaration fd = cast(FuncDeclaration)b.vtbl.data[j];
							if (fd)
								dtxoff(&dt, fd.toThunkSymbol(bs.offset), 0, TYnptr);
							else
								dtdword(&dt, 0);
						}
					}
				}
			}
		}
	}


		csym.Sdt = dt;
	version (ELFOBJ_OR_MACHOBJ) { // Burton
		// ClassInfo cannot be const data, because we use the monitor on it
		csym.Sseg = Segment.DATA;
	}
		outdata(csym);
		if (isExport())
			obj_export(csym,0);

		//////////////////////////////////////////////

		// Put out the vtbl[]
		//printf("putting out %s.vtbl[]\n", toChars());
		dt = null;
		size_t i;
		if (0)
			i = 0;
		else
		{
			dtxoff(&dt, csym, 0, TYnptr);		// first entry is ClassInfo reference
			i = 1;
		}
		for (; i < vtbl.dim; i++)
		{
			FuncDeclaration fd = (cast(Dsymbol)vtbl.data[i]).isFuncDeclaration();

			//printf("\tvtbl[%d] = %p\n", i, fd);
			if (fd && (fd.fbody || !isAbstract()))
			{
				Symbol* s = fd.toSymbol();

		version (DMDV2) {
				if (isFuncHidden(fd))
				{
					/* fd is hidden from the view of this class.
					 * If fd overlaps with any function in the vtbl[], then
					 * issue 'hidden' error.
					 */
					for (int j = 1; j < vtbl.dim; j++)
					{
						if (j == i)
							continue;
						FuncDeclaration fd2 = (cast(Dsymbol)vtbl.data[j]).isFuncDeclaration();
						if (!fd2.ident.equals(fd.ident))
							continue;
						if (fd.leastAsSpecialized(fd2) || fd2.leastAsSpecialized(fd))
						{
							if (global.params.warnings)
							{
								TypeFunction tf = cast(TypeFunction)fd.type;
								if (tf.ty == Tfunction)
									warning("%s%s is hidden by %s\n", fd.toPrettyChars(), Parameter.argsTypesToChars(tf.parameters, tf.varargs), toChars());
								else
									warning("%s is hidden by %s\n", fd.toPrettyChars(), toChars());
							}
							s = rtlsym[RTLSYM_DHIDDENFUNC];
							break;
						}
					}
				}
		}
				dtxoff(&dt, s, 0, TYnptr);
			}
			else
				dtdword(&dt, 0);
		}

		vtblsym.Sdt = dt;
		vtblsym.Sclass = scclass;
		vtblsym.Sfl = FLdata;
	version (ELFOBJ) {
		vtblsym.Sseg = Segment.CDATA;
	}
	version (MACHOBJ) {
		vtblsym.Sseg = Segment.DATA;
	}
		outdata(vtblsym);
		if (isExport())
			obj_export(vtblsym,0);
	}

    void toDebug()
	{
		assert(false);
	}

	/******************************************
	 * Get offset of base class's vtbl[] initializer from start of csym.
	 * Returns ~0 if not this csym.
	 */
    uint baseVtblOffset(BaseClass bc)
	{
		uint csymoffset;

		//printf("ClassDeclaration.baseVtblOffset('%s', bc = %p)\n", toChars(), bc);
		csymoffset = CLASSINFO_SIZE;
		csymoffset += vtblInterfaces.dim * (4 * PTRSIZE);

		foreach (b; vtblInterfaces)
		{
			if (b == bc)
				return csymoffset;
			csymoffset += b.base.vtbl.dim * PTRSIZE;
		}

	static if (true) {
		// Put out the overriding interface vtbl[]s.
		// This must be mirrored with ClassDeclaration.baseVtblOffset()
		//printf("putting out overriding interface vtbl[]s for '%s' at offset x%x\n", toChars(), offset);
		ClassDeclaration cd;
		Array bvtbl;

		for (cd = this.baseClass; cd; cd = cd.baseClass)
		{
			foreach(bs; cd.vtblInterfaces)
			{
				if (bs.fillVtbl(this, null, 0))
				{
					if (bc == bs)
					{
						//printf("\tcsymoffset = x%x\n", csymoffset);
						return csymoffset;
					}
					csymoffset += bs.base.vtbl.dim * PTRSIZE;
				}
			}
		}
	}
	version (INTERFACE_VIRTUAL) {
		for (size_t i = 0; i < vtblInterfaces.dim; i++)
		{
			BaseClass b = cast(BaseClass)vtblInterfaces.data[i];
			ClassDeclaration cd;

			for (cd = this.baseClass; cd; cd = cd.baseClass)
			{
				//printf("\tbase class %s\n", cd.toChars());
				for (int k = 0; k < cd.vtblInterfaces.dim; k++)
				{
					BaseClass bs = cast(BaseClass)cd.vtblInterfaces.data[k];

					if (bc == bs)
					{
						//printf("\tcsymoffset = x%x\n", csymoffset);
						return csymoffset;
					}
					if (b.base == bs.base)
						csymoffset += bs.base.vtbl.dim * PTRSIZE;
				}
			}
		}
	}

		return ~0;
	}

	/*************************************
	 * Create the "ClassInfo" symbol
	 */
    override Symbol* toSymbol()
	{
		if (!csym)
		{
			Symbol* s;

			s = toSymbolX("__Class", SC.SCextern, global.scc.Stype, "Z");
			s.Sfl = FL.FLextern;
			s.Sflags |= SFL.SFLnodebug;
			csym = s;
			slist_add(s);
		}

		return csym;
	}

	/*************************************
	 * This is accessible via the ClassData, but since it is frequently
	 * needed directly (like for rtti comparisons), make it directly accessible.
	 */
    Symbol* toVtblSymbol()
	{
		if (!vtblsym)
		{
			if (!csym)
				toSymbol();

			TYPE* t = type_alloc(TYM.TYnptr | mTY.mTYconst);
			t.Tnext = tsvoid;
			t.Tnext.Tcount++;
			t.Tmangle = mTYman.mTYman_d;

			Symbol* s = toSymbolX("__vtbl", SC.SCextern, t, "Z");
			s.Sflags |= SFL.SFLnodebug;
			s.Sfl = FL.FLextern;
			vtblsym = s;
			slist_add(s);
		}
		return vtblsym;
	}

	// Generate the data for the static initializer.
    void toDt(dt_t **pdt)
	{
		//printf("ClassDeclaration.toDt(this = '%s')\n", toChars());

		// Put in first two members, the vtbl[] and the monitor
		dtxoff(pdt, toVtblSymbol(), 0, TYnptr);
		dtdword(pdt, 0);			// monitor

		// Put in the rest
		toDt2(pdt, this);

		//printf("-ClassDeclaration.toDt(this = '%s')\n", toChars());
	}

    void toDt2(dt_t** pdt, ClassDeclaration cd)
	{
		uint offset;

		dt_t* dt;
		uint csymoffset;

	version (LOG) {
		printf("ClassDeclaration.toDt2(this = '%s', cd = '%s')\n", toChars(), cd.toChars());
	}
		if (baseClass)
		{
			baseClass.toDt2(pdt, cd);
			offset = baseClass.structsize;
		}
		else
		{
			offset = 8;
		}

		// Note equivalence of this loop to struct's
		for (size_t i = 0; i < fields.dim; i++)
		{
			VarDeclaration v = cast(VarDeclaration)fields[i];
			Initializer init;

			//printf("\t\tv = '%s' v.offset = %2d, offset = %2d\n", v.toChars(), v.offset, offset);
			dt = null;
			init = v.init;
			if (init)
			{
				//printf("\t\t%s has initializer %s\n", v.toChars(), init.toChars());
				ExpInitializer ei = init.isExpInitializer();
				Type tb = v.type.toBasetype();
				if (ei && tb.ty == Tsarray)
					(cast(TypeSArray)tb).toDtElem(&dt, ei.exp);
				else
					dt = init.toDt();
			}
			else if (v.offset >= offset)
			{   //printf("\t\tdefault initializer\n");
				v.type.toDt(&dt);
			}
			if (dt)
			{
				if (v.offset < offset)
					error("duplicated union initialization for %s", v.toChars());
				else
				{
					if (offset < v.offset)
						dtnzeros(pdt, v.offset - offset);
					dtcat(pdt, dt);
					offset = v.offset + cast(uint)v.type.size();
				}
			}
		}

		// Interface vptr initializations
		toSymbol();						// define csym

		foreach (b; vtblInterfaces)
		{
///		version (1 || INTERFACE_VIRTUAL) {
			for (ClassDeclaration cd2 = cd; 1; cd2 = cd2.baseClass)
			{
				assert(cd2);
				csymoffset = cd2.baseVtblOffset(b);
				if (csymoffset != ~0)
				{
					if (offset < b.offset)
						dtnzeros(pdt, b.offset - offset);
					dtxoff(pdt, cd2.toSymbol(), csymoffset, TYnptr);
					break;
				}
			}
///		} else {
///			csymoffset = baseVtblOffset(b);
///			assert(csymoffset != ~0);
///			dtxoff(pdt, csym, csymoffset, TYnptr);
///		}
			offset = b.offset + 4;
		}

		if (offset < structsize)
			dtnzeros(pdt, structsize - offset);
	}

    Symbol* vtblsym;

    ///ClassDeclaration isClassDeclaration() { return cast(ClassDeclaration)this; }	/// huh?
    override ClassDeclaration isClassDeclaration() { return this; }
}
