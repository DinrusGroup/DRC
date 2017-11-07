module dmd.StructDeclaration;

import dmd.common;
import dmd.AggregateDeclaration;
import dmd.FuncDeclaration;
import dmd.DeclarationExp;
import dmd.VoidInitializer;
import dmd.Initializer;
import dmd.ExpInitializer;
import dmd.TOK;
import dmd.Statement;
import dmd.VarExp;
import dmd.CompoundStatement;
import dmd.AssignExp;
import dmd.DotVarExp;
import dmd.AddrExp;
import dmd.CastExp;
import dmd.PostBlitDeclaration;
import dmd.Lexer;
import dmd.ExpStatement;
import dmd.DotIdExp;
import dmd.TypeSArray;
import dmd.ThisExp;
import dmd.ThisDeclaration;
import dmd.TypeFunction;
import dmd.Parameter;
import dmd.Id;
import dmd.TY;
import dmd.LINK;
import dmd.Type;
import dmd.DsymbolTable;
import dmd.ArrayTypes;
import dmd.Loc;
import dmd.STC;
import dmd.Identifier;
import dmd.TemplateInstance;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.PROT;
import dmd.TypeStruct;
import dmd.expression.Util;
import dmd.Expression;
import dmd.IdentifierExp;
import dmd.PtrExp;
import dmd.CallExp;
import dmd.ReturnStatement;
import dmd.ScopeDsymbol;
import dmd.Module;
import dmd.VarDeclaration;
import dmd.InvariantDeclaration;
import dmd.NewDeclaration;
import dmd.DeleteDeclaration;
import dmd.Global;
import dmd.MOD;
import dmd.IntegerExp;
import dmd.EqualExp;
import dmd.AndAndExp;

import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.backend.SC;
import dmd.backend.DT;
import dmd.backend.FL;
import dmd.backend.glue;

import std.stdio;

import dmd.DDMDExtensions;

class StructDeclaration : AggregateDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    bool zeroInit;		// true if initialize with 0 fill

version (DMDV2) {
    int hasIdentityAssign;	// !=0 if has identity opAssign
    FuncDeclaration cpctor;	// generated copy-constructor, if any
    FuncDeclaration eq;	// bool opEquals(ref const T), if any

    FuncDeclarations postblits;	// Array of postblit functions
    FuncDeclaration postblit;	// aggregate postblit
}

    this(Loc loc, Identifier id)
	{
		register();
		super(loc, id);

		// For forward references
		type = new TypeStruct(this);

		postblits = new FuncDeclarations(); ///
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		StructDeclaration sd;

		if (s)
			sd = cast(StructDeclaration)s;
		else
			sd = new StructDeclaration(loc, ident);
		ScopeDsymbol.syntaxCopy(sd);
		return sd;
	}

    override void semantic(Scope sc)
	{
		Scope sc2;

		//writef("+StructDeclaration.semantic(this=%p, '%s', sizeok = %d)\n", this, toChars(), sizeok);

		//static int count; if (++count == 20) halt();

		assert(type);
		if (!members)			// if forward reference
		return;

		if (sizeok == 1 || symtab)
		{
			if (!scope_)
			{
				// writef("already completed\n");
				scope_ = null;
				return;             // semantic() already completed
			}
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

		parent = sc.parent;
		type = type.semantic(loc, sc);
version (STRUCTTHISREF) {
		handle = type;
} else {
		handle = type.pointerTo();
}
		structalign = sc.structalign;
		protection = sc.protection;
		storage_class |= sc.stc;
		if (sc.stc & STC.STCdeprecated)
		isdeprecated = 1;
		assert(!isAnonymous());
		if (sc.stc & STC.STCabstract)
		error("structs, unions cannot be abstract");
version (DMDV2) {
		if (storage_class & STC.STCimmutable)
			type = type.invariantOf();
		else if (storage_class & STC.STCconst)
			type = type.constOf();
		else if (storage_class & STC.STCshared)
			type = type.sharedOf();
}

		if (sizeok == 0)		// if not already done the addMember step
		{
		int hasfunctions = 0;
		foreach(Dsymbol s; members)
		{
			//printf("adding member '%s' to '%s'\n", s.toChars(), this.toChars());
			s.addMember(sc, this, true);
			if (s.isFuncDeclaration())
			hasfunctions = 1;
		}

		// If nested struct, add in hidden 'this' pointer to outer scope
		if (hasfunctions && !(storage_class & STC.STCstatic))
			{   Dsymbol s = toParent2();
				if (s)
				{
					AggregateDeclaration ad = s.isAggregateDeclaration();
					FuncDeclaration fd = s.isFuncDeclaration();

			TemplateInstance ti;
					if (ad && (ti = ad.parent.isTemplateInstance()) !is null && ti.isnested || fd)
					{   isnested = true;
						Type t;
						if (ad)
							t = ad.handle;
						else if (fd)
						{
							AggregateDeclaration add = fd.isMember2();
							if (add)
								t = add.handle;
							else
								t = global.tvoidptr;
						}
						else
							assert(0);
				if (t.ty == TY.Tstruct)
				t = global.tvoidptr;	// t should not be a ref type
						assert(!vthis);
						vthis = new ThisDeclaration(loc, t);
				//vthis.storage_class |= STC.STCref;
						members.push(vthis);
					}
				}
			}
		}

		sizeok = 0;
		sc2 = sc.push(this);
		sc2.stc &= storage_class & STC.STC_TYPECTOR;
		sc2.parent = this;
		if (isUnionDeclaration())
		sc2.inunion = 1;
		sc2.protection = PROT.PROTpublic;
		sc2.explicitProtection = 0;


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
	            s.setScope(sc2);
	        }
        }

		foreach(Dsymbol s; members)
		{
			s.semantic(sc2);
			if (isUnionDeclaration())
				sc2.offset = 0;
static if (false) {
			if (sizeok == 2)
			{   //printf("forward reference\n");
				break;
			}
}
			if (auto d = s.isDeclaration())
			{
				if (auto t = d.type) {
					if (t.toBasetype().ty == TY.Tstruct) {
						auto ad = t.toDsymbol(sc).isThis();
						/*
						StructDeclaration sd = cast(StructDeclaration)foo;
						if (foo && !sd) {
							writeln(t.classin);
							writeln(foo.classinfo.name);
							assert(false);
						}
						*/
						if (ad && ad.isnested)
							error("inner struct %s cannot be a field", ad.toChars());
					}
				}
			}
		}

version(DMDV1) {
        /* This doesn't work for DMDV2 because (ref S) and (S) parameter
         * lists will overload the same.
         */
		/* The TypeInfo_Struct is expecting an opEquals and opCmp with
		 * a parameter that is a pointer to the struct. But if there
		 * isn't one, but is an opEquals or opCmp with a value, write
		 * another that is a shell around the value:
		 *	int opCmp(struct *p) { return opCmp(*p); }
		 */

		TypeFunction tfeqptr;
		{
			auto arguments = new Parameters;
			auto arg = new Parameter(STC.STCin, handle, Id.p, null);

			arguments.push(arg);
			tfeqptr = new TypeFunction(arguments, Type.tint32, 0, LINK.LINKd);
			tfeqptr = cast(TypeFunction)tfeqptr.semantic(Loc(0), sc);
		}

		TypeFunction tfeq;
		{
			auto arguments = new Parameters;
			auto arg = new Parameter(STC.STCin, type, null, null);

			arguments.push(arg);
			tfeq = new TypeFunction(arguments, Type.tint32, 0, LINK.LINKd);
			tfeq = cast(TypeFunction)tfeq.semantic(Loc(0), sc);
		}

		Identifier id = Id.eq;
		for (int j = 0; j < 2; j++)
		{
			Dsymbol s = search_function(this, id);
			FuncDeclaration fdx = s ? s.isFuncDeclaration() : null;
			if (fdx)
			{   FuncDeclaration fd = fdx.overloadExactMatch(tfeqptr);
				if (!fd)
				{	fd = fdx.overloadExactMatch(tfeq);
				if (fd)
				{   // Create the thunk, fdptr
					FuncDeclaration fdptr = new FuncDeclaration(loc, loc, fdx.ident, STC.STCundefined, tfeqptr);
					Expression e = new IdentifierExp(loc, Id.p);
					e = new PtrExp(loc, e);
					auto args = new Expressions();
					args.push(e);
					e = new IdentifierExp(loc, id);
					e = new CallExp(loc, e, args);
					fdptr.fbody = new ReturnStatement(loc, e);
					ScopeDsymbol ss = fdx.parent.isScopeDsymbol();
					assert(ss);
					ss.members.push(fdptr);
					fdptr.addMember(sc, ss, true);
					fdptr.semantic(sc2);
				}
				}
			}

			id = Id.cmp;
		}
}
version (DMDV2) {
        /* Try to find the opEquals function. Build it if necessary.
         */
        TypeFunction tfeqptr;
        {   // bool opEquals(const T*) const;
            auto parameters = new Parameters;
version(STRUCTTHISREF) {
            // bool opEquals(ref const T) const;
            auto param = new Parameter(STC.STCref, type.constOf(), null, null);
} else {
            // bool opEquals(const T*) const;
            auto param = new Parameter(STC.STCin, type.pointerTo(), null, null);
}

            parameters.push(param);
            tfeqptr = new TypeFunction(parameters, Type.tbool, 0, LINK.LINKd);
            tfeqptr.mod = MOD.MODconst;
            tfeqptr = cast(TypeFunction)(tfeqptr.semantic(Loc(0), sc2));

	        Dsymbol s = search_function(this, Id.eq);
	        FuncDeclaration fdx = s ? s.isFuncDeclaration() : null;
	        if (fdx)
	        {
	            eq = fdx.overloadExactMatch(tfeqptr);
	            if (!eq)
		            fdx.error("type signature should be %s not %s", tfeqptr.toChars(), fdx.type.toChars());
	        }

	        if (!eq)
	            eq = buildOpEquals(sc2);
        }

		dtor = buildDtor(sc2);
		postblit = buildPostBlit(sc2);
		cpctor = buildCpCtor(sc2);
		buildOpAssign(sc2);
}

		sc2.pop();

		if (sizeok == 2)
		{	
			// semantic() failed because of forward references.
			// Unwind what we did, and defer it for later
			fields.setDim(0);
			structsize = 0;
			alignsize = 0;
			structalign = 0;

			scope_ = scx ? scx : sc.clone();
			scope_.setNoFree();
			scope_.module_.addDeferredSemantic(this);
			
			global.dprogress = dprogress_save;
			//printf("\tdeferring %s\n", toChars());
			return;
		}

		// 0 sized struct's are set to 1 byte
		if (structsize == 0)
		{
			structsize = 1;
			alignsize = 1;
		}

		// Round struct size up to next alignsize boundary.
		// This will ensure that arrays of structs will get their internals
		// aligned properly.
		structsize = (structsize + alignsize - 1) & ~(alignsize - 1);

		sizeok = 1;
		global.dprogress++;

		//printf("-StructDeclaration.semantic(this=%p, '%s')\n", this, toChars());

		// Determine if struct is all zeros or not
		zeroInit = true;
		foreach (VarDeclaration vd; fields)
		{
			if (vd && !vd.isDataseg())
			{
				if (vd.init)
				{
				// Should examine init to see if it is really all 0's
				zeroInit = false;
				break;
				}
				else
				{
				if (!vd.type.isZeroInit(loc))
				{
					zeroInit = false;
					break;
				}
				}
			}
		}

		/* Look for special member functions.
		 */
version (DMDV2) {
		ctor = search(Loc(0), Id.ctor, 0);
}
		inv =    cast(InvariantDeclaration)search(Loc(0), Id.classInvariant, 0);
		aggNew =       cast(NewDeclaration)search(Loc(0), Id.classNew,       0);
		aggDelete = cast(DeleteDeclaration)search(Loc(0), Id.classDelete,    0);

		if (sc.func)
		{
		semantic2(sc);
		semantic3(sc);
		}
	}

    override Dsymbol search(Loc loc, Identifier ident, int flags)
    {
        //printf("%s.StructDeclaration::search('%s')\n", toChars(), ident->toChars());

        if (scope_)
    	    semantic(scope_);

        if (!members || !symtab)
        {
    	    error("is forward referenced when looking for '%s'", ident.toChars());
	        return null;
        }

        return ScopeDsymbol.search(loc, ident, flags);
    }

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

    override string mangle()
	{
		//printf("StructDeclaration.mangle() '%s'\n", toChars());
		return Dsymbol.mangle();
	}

    override string kind()
	{
		assert(false);
	}

version(DMDV1)
{
    Expression cloneMembers()
	{
		assert(false);
	}
}

version(DMDV2)
{
	/*******************************************
	 * We need an opAssign for the struct if
	 * it has a destructor or a postblit.
	 * We need to generate one if a user-specified one does not exist.
	 */
    bool needOpAssign()
	{
static if (false) {
		printf("StructDeclaration.needOpAssign() %s\n", toChars());
}
		if (hasIdentityAssign)
			goto Ldontneed;

		if (dtor || postblit)
			goto Lneed;

		/* If any of the fields need an opAssign, then we
		 * need it too.
		 */
		foreach (VarDeclaration v; fields)
		{
			assert(v && v.storage_class & STC.STCfield);
			if (v.storage_class & STC.STCref)
				continue;
			Type tv = v.type.toBasetype();
			while (tv.ty == TY.Tsarray)
			{   TypeSArray ta = cast(TypeSArray)tv;
				tv = tv.nextOf().toBasetype();
			}
			if (tv.ty == TY.Tstruct)
			{   TypeStruct ts = cast(TypeStruct)tv;
				StructDeclaration sd = ts.sym;
				if (sd.needOpAssign())
					goto Lneed;
			}
		}
	Ldontneed:
static if (false) {
		printf("\tdontneed\n");
}
		return false;

	Lneed:
static if (false) {
		printf("\tneed\n");
}
		return true;
	}

	/*******************************************
	* We need an opEquals for the struct if
	* any fields has an opEquals.
	* Generate one if a user-specified one does not exist.
	*/
	bool needOpEquals()
	{
		enum X = 0;
static if (X) printf("StructDeclaration::needOpEquals() %s\n", toChars());

		/* If any of the fields has an opEquals, then we
		 * need it too.
		 */
		foreach (s; fields)
		{
		VarDeclaration v = s.isVarDeclaration();
		assert(v && v.storage_class & STC.STCfield);
		if (v.storage_class & STC.STCref)
			continue;
		Type tv = v.type.toBasetype();
		while (tv.ty == Tsarray)
		{   auto ta = cast(TypeSArray)tv;
			tv = tv.nextOf().toBasetype();
		}
		if (tv.ty == Tstruct)
		{   auto ts = cast(TypeStruct)tv;
			StructDeclaration sd = ts.sym;
			if (sd.eq)
			goto Lneed;
		}
		}
	Ldontneed:
static if (X) printf("\tdontneed\n");
		return false;

	Lneed:
static if (X) printf("\tneed\n");
		return true;
	}

	/******************************************
	 * Build opAssign for struct.
	 *	S* opAssign(S s) { ... }
	 */
    FuncDeclaration buildOpAssign(Scope sc)
	{
		if (!needOpAssign())
			return null;

		//printf("StructDeclaration.buildOpAssign() %s\n", toChars());

		FuncDeclaration fop = null;

		auto param = new Parameter(STC.STCnodtor, type, Id.p, null);
		auto fparams = new Parameters;
		fparams.push(param);
		Type ftype = new TypeFunction(fparams, handle, false, LINK.LINKd);
version (STRUCTTHISREF) {
		(cast(TypeFunction)ftype).isref = 1;
}

		fop = new FuncDeclaration(Loc(0), Loc(0), Id.assign, STC.STCundefined, ftype);

		Expression e = null;
		if (postblit)
		{	/* Swap:
			 *    tmp = *this; *this = s; tmp.dtor();
			 */
		//printf("\tswap copy\n");
		Identifier idtmp = Lexer.uniqueId("__tmp");
		VarDeclaration tmp;
		AssignExp ec = null;
		if (dtor)
		{
			tmp = new VarDeclaration(Loc(0), type, idtmp, new VoidInitializer(Loc(0)));
			tmp.noauto = true;
		    tmp.storage_class |= STCctfe;
			e = new DeclarationExp(Loc(0), tmp);

			Expression e2;
version (STRUCTTHISREF) {
			e2 = new ThisExp(Loc(0));
} else {
			e2 = new PtrExp(Loc(0), new ThisExp(Loc(0)));
}
			ec = new AssignExp(Loc(0), new VarExp(Loc(0), tmp), e2);
			ec.op = TOK.TOKblit;
			e = Expression.combine(e, ec);
		}
		Expression e2;
version (STRUCTTHISREF) {
			e2 = new ThisExp(Loc(0));
} else {
			e2 = new PtrExp(Loc(0), new ThisExp(Loc(0)));
}

		ec = new AssignExp(Loc(0), e2, new IdentifierExp(Loc(0), Id.p));
		ec.op = TOK.TOKblit;
		e = Expression.combine(e, ec);
		if (dtor)
		{
			/* Instead of running the destructor on s, run it
			 * on tmp. This avoids needing to copy tmp back in to s.
			 */
			Expression ecc = new DotVarExp(Loc(0), new VarExp(Loc(0), tmp), dtor, 0);
			ecc = new CallExp(Loc(0), ecc);
			e = Expression.combine(e, ecc);
		}
		}
		else
		{	/* Do memberwise copy
			 */
		//printf("\tmemberwise copy\n");
		foreach (VarDeclaration v; fields)
		{
			assert(v && v.storage_class & STC.STCfield);
			// this.v = s.v;
			AssignExp ec = new AssignExp(Loc(0), new DotVarExp(Loc(0), new ThisExp(Loc(0)), v, 0), new DotVarExp(Loc(0), new IdentifierExp(Loc(0), Id.p), v, 0));
			ec.op = TOK.TOKblit;
			e = Expression.combine(e, ec);
		}
		}
		Statement s1 = new ExpStatement(Loc(0), e);

		/* Add:
		 *   return this;
		 */
		e = new ThisExp(Loc(0));
		Statement s2 = new ReturnStatement(Loc(0), e);

		fop.fbody = new CompoundStatement(Loc(0), s1, s2);

		members.push(fop);
		fop.addMember(sc, this, true);

		sc = sc.push();
		sc.stc = STC.STCundefined;
		sc.linkage = LINK.LINKd;

		fop.semantic(sc);

		sc.pop();

		//printf("-StructDeclaration.buildOpAssign() %s\n", toChars());

		return fop;
	}

	/******************************************
	 * Build opEquals for struct.
	 *	const bool opEquals(const ref S s) { ... }
	 */
	FuncDeclaration buildOpEquals(Scope sc)
	{
		if (!needOpEquals())
		return null;
		//printf("StructDeclaration::buildOpEquals() %s\n", toChars());
		Loc loc = this.loc;

		auto parameters = new Parameters;
version (STRUCTTHISREF) {
		// bool opEquals(ref const T) const;
		auto param = new Parameter(STC.STCref, type.constOf(), Id.p, null);
} else {
		// bool opEquals(const T*) const;
		auto param = new Parameter(STC.STCin, type.pointerTo(), Id.p, null);
}

		parameters.push(param);
		auto ftype = new TypeFunction(parameters, Type.tbool, 0, LINKd);
		ftype.mod = MOD.MODconst;
		ftype = cast(TypeFunction)ftype.semantic(loc, sc);

		auto fop = new FuncDeclaration(loc, Loc(0), Id.eq, STC.STCundefined, ftype);

		Expression e = null;
		/* Do memberwise compare
		 */
		//printf("\tmemberwise compare\n");
		foreach (s; fields)
		{
		VarDeclaration v = s.isVarDeclaration();
		assert(v && v.storage_class & STC.STCfield);
		if (v.storage_class & STC.STCref)
			assert(0);			// what should we do with this?
		// this.v == s.v;
		auto ec = new EqualExp(TOKequal, loc,
			new DotVarExp(loc, new ThisExp(loc), v, 0),
			new DotVarExp(loc, new IdentifierExp(loc, Id.p), v, 0));
		if (e)
			e = new AndAndExp(loc, e, ec);
		else
			e = ec;
		}
		if (!e)
		e = new IntegerExp(loc, 1, Type.tbool);
		fop.fbody = new ReturnStatement(loc, e);

		members.push(fop);
		fop.addMember(sc, this, 1);

		sc = sc.push();
		sc.stc = STCundefined;
		sc.linkage = LINK.LINKd;

		fop.semantic(sc);

		sc.pop();

		//printf("-StructDeclaration::buildOpEquals() %s\n", toChars());

		return fop;
	}

	/*****************************************
	 * Create inclusive postblit for struct by aggregating
	 * all the postblits in postblits[] with the postblits for
	 * all the members.
	 * Note the close similarity with AggregateDeclaration.buildDtor(),
	 * and the ordering changes (runs forward instead of backwards).
	 */

version (DMDV2) {
    FuncDeclaration buildPostBlit(Scope sc)
	{
		//printf("StructDeclaration.buildPostBlit() %s\n", toChars());
		Expression e = null;
	    StorageClass stc = STCundefined;

		foreach (VarDeclaration v; fields)
		{
			assert(v && v.storage_class & STC.STCfield);
			if (v.storage_class & STC.STCref)
				continue;
			Type tv = v.type.toBasetype();
			size_t dim = 1;
			while (tv.ty == TY.Tsarray)
			{   
				TypeSArray ta = cast(TypeSArray)tv;
				dim *= (cast(TypeSArray)tv).dim.toInteger();
				tv = tv.nextOf().toBasetype();
			}
			if (tv.ty == TY.Tstruct)
			{   
				TypeStruct ts = cast(TypeStruct)tv;
				StructDeclaration sd = ts.sym;
				if (sd.postblit)
				{	
					Expression ex;
					
					stc |= sd.postblit.storage_class & STCdisable;

					// this.v
					ex = new ThisExp(Loc(0));
					ex = new DotVarExp(Loc(0), ex, v, 0);

					if (dim == 1)
					{   // this.v.postblit()
						ex = new DotVarExp(Loc(0), ex, sd.postblit, 0);
						ex = new CallExp(Loc(0), ex);
					}
					else
					{
						// Typeinfo.postblit(cast(void*)&this.v);
						Expression ea = new AddrExp(Loc(0), ex);
						ea = new CastExp(Loc(0), ea, Type.tvoid.pointerTo());

						Expression et = v.type.getTypeInfo(sc);
						et = new DotIdExp(Loc(0), et, Id._postblit);

						ex = new CallExp(Loc(0), et, ea);
					}
					e = Expression.combine(e, ex);	// combine in forward order
				}
			}
		}

		/* Build our own "postblit" which executes e
		 */
		if (e)
		{	
			//printf("Building __fieldPostBlit()\n");
			auto dd = new PostBlitDeclaration(Loc(0), Loc(0), Lexer.idPool("__fieldPostBlit"));
			dd.storage_class |= stc;
			dd.fbody = new ExpStatement(Loc(0), e);
			postblits.shift(dd);
			members.push(dd);
			dd.semantic(sc);
		}

		switch (postblits.dim)
		{
		case 0:
			return null;

		case 1:
			return cast(FuncDeclaration)postblits[0];

		default:
			e = null;
			foreach(FuncDeclaration fd; postblits)
			{
				Expression ex = new ThisExp(Loc(0));
				stc |= fd.storage_class & STCdisable;
				ex = new DotVarExp(Loc(0), ex, fd, 0);
				ex = new CallExp(Loc(0), ex);
				e = Expression.combine(e, ex);
			}
			auto dd = new PostBlitDeclaration(Loc(0), Loc(0), Lexer.idPool("__aggrPostBlit"));
		    dd.storage_class |= stc;
			dd.fbody = new ExpStatement(Loc(0), e);
			members.push(dd);
			dd.semantic(sc);
			return dd;
		}
	}
}

	/*******************************************
	 * Build copy constructor for struct.
	 * Copy constructors are compiler generated only, and are only
	 * callable from the compiler. They are not user accessible.
	 * A copy constructor is:
	 *    void cpctpr(ref S s)
	 *    {
	 *	*this = s;
	 *	this.postBlit();
	 *    }
	 * This is done so:
	 *	- postBlit() never sees uninitialized data
	 *	- memcpy can be much more efficient than memberwise copy
	 *	- no fields are overlooked
	 */
    FuncDeclaration buildCpCtor(Scope sc)
	{
		//printf("StructDeclaration.buildCpCtor() %s\n", toChars());
		FuncDeclaration fcp = null;

		/* Copy constructor is only necessary if there is a postblit function,
		 * otherwise the code generator will just do a bit copy.
		 */
		if (postblit)
		{
			//printf("generating cpctor\n");

		        auto param = new Parameter(STC.STCref, type, Id.p, null);
		        auto fparams = new Parameters;
			fparams.push(param);
			Type ftype = new TypeFunction(fparams, Type.tvoid, false, LINK.LINKd);

			fcp = new FuncDeclaration(Loc(0), Loc(0), Id.cpctor, STC.STCundefined, ftype);
			fcp.storage_class |= postblit.storage_class & STCdisable;

			// Build *this = p;
			Expression e = new ThisExp(Loc(0));
version (STRUCTTHISREF) {
} else {
			e = new PtrExp(Loc(0), e);
}
			AssignExp ea = new AssignExp(Loc(0), e, new IdentifierExp(Loc(0), Id.p));
			ea.op = TOK.TOKblit;
			Statement s = new ExpStatement(Loc(0), ea);

			// Build postBlit();
			e = new VarExp(Loc(0), postblit, 0);
			e = new CallExp(Loc(0), e);

			s = new CompoundStatement(Loc(0), s, new ExpStatement(Loc(0), e));
			fcp.fbody = s;

			members.push(fcp);

			sc = sc.push();
			sc.stc = STC.STCundefined;
			sc.linkage = LINK.LINKd;

			fcp.semantic(sc);

			sc.pop();
		}

		return fcp;
	}
}
    override void toDocBuffer(OutBuffer buf)
	{
		assert(false);
	}

    override PROT getAccess(Dsymbol smember)	// determine access to smember
	{
		assert(false);
	}

    override void toObjFile(int multiobj)			// compile to .obj file
	{
		//printf("StructDeclaration.toObjFile('%s')\n", toChars());

		if (multiobj)
		{
			obj_append(this);
			return;
		}

		// Anonymous structs/unions only exist as part of others,
		// do not output forward referenced structs's
		if (!isAnonymous() && members)
		{
			if (global.params.symdebug) {
				toDebug();
			}

			type.getTypeInfo(null);	// generate TypeInfo

			if (true)
			{
				// Generate static initializer
				toInitializer();

static if (false) {
				sinit.Sclass = SC.SCcomdat;
} else {
				if (inTemplateInstance())
				{
					sinit.Sclass = SC.SCcomdat;
				}
				else
				{
					sinit.Sclass = SC.SCglobal;
				}
}
				sinit.Sfl = FL.FLdata;

				toDt(&sinit.Sdt);

version (OMFOBJ)
{
				/* For OMF, common blocks aren't pulled in from the library.
				 */
				/* ELF comdef's generate multiple
				 * definition errors for them from the gnu linker.
				 * Need to figure out how to generate proper comdef's for ELF.
				 */
				// See if we can convert a comdat to a comdef,
				// which saves on exe file space.
				if (0 && // causes multiple def problems with COMMON in one file and COMDAT in library
				    sinit.Sclass == SCcomdat &&
					sinit.Sdt &&
					sinit.Sdt.dt == DT.DT_azeros &&
					sinit.Sdt.DTnext == null &&
					!global.params.multiobj)
				{
					sinit.Sclass = SC.SCglobal;
					sinit.Sdt.dt = DT.DT_common;
				}
}

version (ELFOBJ) {
				sinit.Sseg = Segment.CDATA;
}
version (MACHOBJ) {
				sinit.Sseg = Segment.DATA;
}
				outdata(sinit);
			}

			// Put out the members
			foreach(Dsymbol member; members)
				member.toObjFile(0);
		}
	}

    void toDt(dt_t** pdt)
	{
		uint offset;
		dt_t* dt;

		//printf("StructDeclaration.toDt(), this='%s'\n", toChars());
		offset = 0;

		// Note equivalence of this loop to class's
		for (uint i = 0; i < fields.dim; i++)
		{
			VarDeclaration v = cast(VarDeclaration)fields[i];
			//printf("\tfield '%s' voffset %d, offset = %d\n", v.toChars(), v.offset, offset);
			dt = null;
			int sz;

			if (v.storage_class & STC.STCref)
			{
				sz = PTRSIZE;
				if (v.offset >= offset)
					dtnzeros(&dt, sz);
			}
			else
			{
				sz = cast(uint)v.type.size();
				Initializer init = v.init;
				if (init)
				{
					//printf("\t\thas initializer %s\n", init.toChars());
					ExpInitializer ei = init.isExpInitializer();
					Type tb = v.type.toBasetype();
					if (ei && tb.ty == TY.Tsarray)
						(cast(TypeSArray)tb).toDtElem(&dt, ei.exp);
					else
						dt = init.toDt();
				}
				else if (v.offset >= offset)
					v.type.toDt(&dt);
			}
			if (dt)
			{
				if (v.offset < offset)
					error("overlapping initialization for struct %s.%s", toChars(), v.toChars());
				else
				{
					if (offset < v.offset)
						dtnzeros(pdt, v.offset - offset);
					dtcat(pdt, dt);
					offset = v.offset + sz;
				}
			}
		}

		if (offset < structsize)
			dtnzeros(pdt, structsize - offset);

		dt_optimize(*pdt);
	}

    void toDebug()			// to symbolic debug info
	{
		assert(false);
	}

    override StructDeclaration isStructDeclaration() { return this; }
}
