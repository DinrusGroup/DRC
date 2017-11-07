module dmd.InterfaceDeclaration;

import dmd.common;
import dmd.ClassDeclaration;
import dmd.Loc;
import dmd.DsymbolTable;
import dmd.STC;
import dmd.Type;
import dmd.TY;
import dmd.LINK;
import dmd.Parameter;
import dmd.Util;
import dmd.TypeTuple;
import dmd.PROT;
import dmd.TypeClass;
import dmd.Identifier;
import dmd.ArrayTypes;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.Global;
import dmd.Module;
import dmd.BaseClass;
import dmd.Id;

import dmd.backend.Symbol;
import dmd.backend.TYM;
import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.codegen.Util;
import dmd.backend.SC;
import dmd.backend.FL;
import dmd.backend.LIST;
import dmd.backend.SFL;

import dmd.DDMDExtensions;

class InterfaceDeclaration : ClassDeclaration
{
	mixin insertMemberExtension!(typeof(this));

version (DMDV2) {
    bool cpp;				// true if this is a C++ interface
}
    this(Loc loc, Identifier id, BaseClasses baseclasses)
	{
		register();
		super(loc, id, baseclasses);

		if (id is Id.IUnknown)	// IUnknown is the root of all COM interfaces
		{
			com = true;
			cpp = true;		// IUnknown is also a C++ interface
		}
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		InterfaceDeclaration id;

		if (s)
			id = cast(InterfaceDeclaration)s;
		else
			id = new InterfaceDeclaration(loc, ident, null);

		ClassDeclaration.syntaxCopy(id);
		return id;
	}

    override void semantic(Scope sc)
	{
		//printf("InterfaceDeclaration.semantic(%s), type = %p\n", toChars(), type);
		if (inuse)
			return;

		if (!sc)
			sc = scope_;
		if (!parent && sc.parent && !sc.parent.isModule())
		parent = sc.parent;

		type = type.semantic(loc, sc);
		handle = type;

		if (!members)			// if forward reference
		{
			//printf("\tinterface '%s' is forward referenced\n", toChars());
			return;
		}
		if (symtab)			// if already done
		{
			if (!scope_)
				return;
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

		if (sc.stc & STC.STCdeprecated)
		{
			isdeprecated = true;
		}

		// Expand any tuples in baseclasses[]
		for (size_t i = 0; i < baseclasses.dim; )
		{
			auto b = baseclasses[0];
			b.type = b.type.semantic(loc, sc);
			Type tb = b.type.toBasetype();

			if (tb.ty == TY.Ttuple)
			{   TypeTuple tup = cast(TypeTuple)tb;
				PROT protection = b.protection;
				baseclasses.remove(i);
				size_t dim = Parameter.dim(tup.arguments);
				for (size_t j = 0; j < dim; j++)
				{	auto arg = Parameter.getNth(tup.arguments, j);
				b = new BaseClass(arg.type, protection);
				baseclasses.insert(i + j, b);
				}
			}
			else
				i++;
		}

		if (!baseclasses.dim && sc.linkage == LINK.LINKcpp)
		cpp = 1;

		// Check for errors, handle forward references
		for (size_t i = 0; i < baseclasses.dim; )
		{
			TypeClass tc;
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
				// Check for duplicate interfaces
				for (size_t j = 0; j < i; j++)
				{
					auto b2 = baseclasses[j];
					if (b2.base is tc.sym)
						error("inherits from duplicate interface %s", b2.base.toChars());
				}

				b.base = tc.sym;
				if (b.base == this || isBaseOf2(b.base))
				{
					error("circular inheritance of interface");
					baseclasses.remove(i);
					continue;
				}
				if (!b.base.symtab)
				{
					// Try to resolve forward reference
					if (sc.mustsemantic && b.base.scope_)
						b.base.semantic(null);
				}
				if (!b.base.symtab || b.base.scope_ || b.base.inuse)
				{
					//error("forward reference of base class %s", baseClass.toChars());
					// Forward reference of base, try again later
					//printf("\ttry later, forward reference of base %s\n", b.base.toChars());
					scope_ = scx ? scx : sc.clone();
					scope_.setNoFree();
					scope_.module_.addDeferredSemantic(this);
					return;
				}
			}
static if (false) {
			// Inherit const/invariant from base class
			storage_class |= b.base.storage_class & STC.STC_TYPECTOR;
}
			i++;
		}

		interfaces_dim = baseclasses.dim;
		interfaces = baseclasses.ptr;

		interfaceSemantic(sc);

		if (vtblOffset())
		vtbl.push(cast(void*)this);		// leave room at vtbl[0] for classinfo

		// Cat together the vtbl[]'s from base interfaces
		for (size_t i = 0; i < interfaces_dim; i++)
		{
			BaseClass b = interfaces[i];

			// Skip if b has already appeared
			for (int k = 0; k < i; k++)
			{
				if (b == interfaces[k])
				goto Lcontinue;
			}

			// Copy vtbl[] from base class
			if (b.base.vtblOffset())
			{   int d = b.base.vtbl.dim;
				if (d > 1)
				{
				vtbl.reserve(d - 1);
				for (int j = 1; j < d; j++)
					vtbl.push(b.base.vtbl.data[j]);
				}
			}
			else
			{
				vtbl.append(b.base.vtbl);
			}

			  Lcontinue:
			;
		}

		protection = sc.protection;
		storage_class |= sc.stc & STC.STC_TYPECTOR;

		foreach(Dsymbol s; members)
			s.addMember(sc, this, true);

		sc = sc.push(this);
		sc.stc &= ~(STC.STCfinal | STC.STCauto | STC.STCscope | STC.STCstatic |
					 STC.STCabstract | STC.STCdeprecated | STC.STC_TYPECTOR | STC.STCtls | STC.STCgshared);
		sc.stc |= storage_class & STC.STC_TYPECTOR;
		sc.parent = this;
		if (isCOMinterface())
		sc.linkage = LINK.LINKwindows;
		else if (isCPPinterface())
		sc.linkage = LINK.LINKcpp;
		sc.structalign = 8;
		structalign = sc.structalign;
		sc.offset = PTRSIZE * 2;
		inuse++;
		foreach(Dsymbol s; members)
			s.semantic(sc);
		inuse--;
		//members.print();
		sc.pop();
		//printf("-InterfaceDeclaration.semantic(%s), type = %p\n", toChars(), type);
	}

    override bool isBaseOf(ClassDeclaration cd, int* poffset)
	{
		uint j;

		//printf("%s.InterfaceDeclaration.isBaseOf(cd = '%s')\n", toChars(), cd.toChars());
		assert(!baseClass);
		for (j = 0; j < cd.interfaces_dim; j++)
		{
			BaseClass b = cd.interfaces[j];

			//printf("\tbase %s\n", b.base.toChars());
			if (this == b.base)
			{
				//printf("\tfound at offset %d\n", b.offset);
				if (poffset)
				{
					*poffset = b.offset;
					if (j && cd.isInterfaceDeclaration())
						*poffset = OFFSET_RUNTIME;
				}
				return true;
			}
			if (isBaseOf(b, poffset))
			{
				if (j && poffset && cd.isInterfaceDeclaration())
					*poffset = OFFSET_RUNTIME;
				return true;
			}
		}

		if (cd.baseClass && isBaseOf(cd.baseClass, poffset))
		return true;

		if (poffset)
			*poffset = 0;
		return false;
	}

    bool isBaseOf(BaseClass bc, int* poffset)
	{
	    //printf("%s.InterfaceDeclaration.isBaseOf(bc = '%s')\n", toChars(), bc.base.toChars());
		for (uint j = 0; j < bc.baseInterfaces.length; j++)
		{
			BaseClass b = bc.baseInterfaces[j];

			if (this == b.base)
			{
				if (poffset)
				{
					*poffset = b.offset;
					if (j && bc.base.isInterfaceDeclaration())
						*poffset = OFFSET_RUNTIME;
				}
				return true;
			}
			if (isBaseOf(b, poffset))
			{
				if (j && poffset && bc.base.isInterfaceDeclaration())
					*poffset = OFFSET_RUNTIME;
				return true;
			}
		}
		if (poffset)
			*poffset = 0;
		return false;
	}

    override string kind()
	{
		assert(false);
	}

	/****************************************
	 * Determine if slot 0 of the vtbl[] is reserved for something else.
	 * For class objects, yes, this is where the ClassInfo ptr goes.
	 * For COM interfaces, no.
	 * For non-COM interfaces, yes, this is where the Interface ptr goes.
	 */
    override int vtblOffset()
	{
		if (isCOMinterface() || isCPPinterface())
			return 0;
		return 1;
	}

version (DMDV2) {
    override bool isCPPinterface()
	{
		return cpp;
	}
}
    override bool isCOMinterface()
	{
		return com;
	}

    override void toObjFile(int multiobj)			// compile to .obj file
	{
		uint offset;
		Symbol* sinit;
		SC scclass;

		//printf("InterfaceDeclaration.toObjFile('%s')\n", toChars());

		if (!members)
			return;

		if (global.params.symdebug)
			toDebug();

		scclass = SCglobal;
		if (inTemplateInstance())
			scclass = SCcomdat;

		// Put out the members
		foreach(Dsymbol member; members)
		{
			if (!member.isFuncDeclaration())
				member.toObjFile(0);
		}

		// Generate C symbols
		toSymbol();

		//////////////////////////////////////////////

		// Put out the TypeInfo
		type.getTypeInfo(null);
		type.vtinfo.toObjFile(multiobj);

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
			Object *base;		// base class
			void *destructor;
			void *invariant;		// class invariant
			uint flags;
			void *deallocator;
			OffsetTypeInfo[] offTi;
			void *defaultConstructor;
	#if DMDV2
			const(MemberInfo[]) function(string) xgetMembers;	// module getMembers() function
	#endif
			//TypeInfo typeinfo;
		   }
		 */
		dt_t *dt = null;

		if (global.classinfo)
			dtxoff(&dt, global.classinfo.toVtblSymbol(), 0, TYnptr); // vtbl for ClassInfo
		else
			dtdword(&dt, 0);		// BUG: should be an assert()
		dtdword(&dt, 0);			// monitor

		// initializer[]
		dtdword(&dt, 0);			// size
		dtdword(&dt, 0);			// initializer

		// name[]
		string name = toPrettyChars();
		size_t namelen = name.length;
		dtdword(&dt, namelen);
		dtabytes(&dt, TYnptr, 0, namelen + 1, toStringz(name));

		// vtbl[]
		dtdword(&dt, 0);
		dtdword(&dt, 0);

		// vtblInterfaces.data[]
		dtdword(&dt, vtblInterfaces.dim);
		if (vtblInterfaces.dim)
		{
			if (global.classinfo)
				assert(global.classinfo.structsize == CLASSINFO_SIZE);
			offset = CLASSINFO_SIZE;
			dtxoff(&dt, csym, offset, TYnptr);	// (*)
		}
		else
			dtdword(&dt, 0);

		// base
		assert(!baseClass);
		dtdword(&dt, 0);

		// dtor
		dtdword(&dt, 0);

		// invariant
		dtdword(&dt, 0);

		// flags
		dtdword(&dt, 4 | isCOMinterface() | 32);

		// deallocator
		dtdword(&dt, 0);

		// offTi[]
		dtdword(&dt, 0);
		dtdword(&dt, 0);		// null for now, fix later

		// defaultConstructor
		dtdword(&dt, 0);

	version (DMDV2) {
		// xgetMembers
		dtdword(&dt, 0);
	}

		//dtxoff(&dt, type.vtinfo.toSymbol(), 0, TYnptr);	// typeinfo

		//////////////////////////////////////////////

		// Put out vtblInterfaces.data[]. Must immediately follow csym, because
		// of the fixup (*)

		offset += vtblInterfaces.dim * (4 * PTRSIZE);
		foreach (b; vtblInterfaces)
		{
			ClassDeclaration id = b.base;

			// ClassInfo
			dtxoff(&dt, id.toSymbol(), 0, TYnptr);

			// vtbl[]
			dtdword(&dt, 0);
			dtdword(&dt, 0);

			// this offset
			dtdword(&dt, b.offset);
		}

		csym.Sdt = dt;
	version (ELFOBJ) {
		csym.Sseg = Segment.CDATA;
	}
	version (MACHOBJ) {
		csym.Sseg = Segment.DATA;
	}
		outdata(csym);
		if (isExport())
			obj_export(csym,0);
	}

	/*************************************
	 * Create the "InterfaceInfo" symbol
	 */
    override Symbol* toSymbol()
	{
		if (!csym)
		{
			Symbol *s;

			s = toSymbolX("__Interface", SCextern, global.scc.Stype, "Z");
			s.Sfl = FLextern;
			s.Sflags |= SFLnodebug;
			csym = s;
			slist_add(s);
		}
		return csym;
	}

    override InterfaceDeclaration isInterfaceDeclaration() { return this; }
}
