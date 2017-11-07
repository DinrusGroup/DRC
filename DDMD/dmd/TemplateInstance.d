module dmd.TemplateInstance;

import dmd.common;
import dmd.ScopeDsymbol;
import dmd.IntegerExp;
import dmd.Identifier;
import dmd.ArrayTypes;
import dmd.TupleDeclaration;
import dmd.TemplateParameter;
import dmd.AliasDeclaration;
import dmd.TemplateDeclaration;
import dmd.TupleExp;
import dmd.WithScopeSymbol;
import dmd.Dsymbol;
import dmd.Module;
import dmd.ArrayTypes;
import dmd.Loc;
import dmd.Global;
import dmd.Util;
import dmd.Type;
import dmd.Expression;
import dmd.Tuple;
import dmd.STC;
import dmd.TOK;
import dmd.TY;
import dmd.TypeTuple;
import dmd.Parameter;
import dmd.WANT;
import dmd.ExpInitializer;
import dmd.Array;
import dmd.DsymbolTable;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.VarDeclaration;
import dmd.VarExp;
import dmd.FuncExp;
import dmd.Declaration;
import dmd.MATCH;
import dmd.TypeFunction;
import dmd.TemplateTupleParameter;
import dmd.FuncDeclaration;
import dmd.OverloadSet;
import dmd.templates.Util;

import dmd.backend.glue;

import dmd.DDMDExtensions;

Tuple isTuple(Object o)
{
    //return dynamic_cast<Tuple *>(o);
    ///if (!o || o.dyncast() != DYNCAST_TUPLE)
	///	return null;
    return cast(Tuple)o;
}

/******************************
 * If o1 matches o2, return 1.
 * Else, return 0.
 */

bool match(Object o1, Object o2, TemplateDeclaration tempdecl, Scope sc)
{
    Type t1 = isType(o1);
    Type t2 = isType(o2);
    Expression e1 = isExpression(o1);
    Expression e2 = isExpression(o2);
    Dsymbol s1 = isDsymbol(o1);
    Dsymbol s2 = isDsymbol(o2);
    Tuple v1 = isTuple(o1);
    Tuple v2 = isTuple(o2);

    //printf("\t match t1 %p t2 %p, e1 %p e2 %p, s1 %p s2 %p, v1 %p v2 %p\n", t1,t2,e1,e2,s1,s2,v1,v2);

    /* A proper implementation of the various equals() overrides
     * should make it possible to just do o1.equals(o2), but
     * we'll do that another day.
     */

    if (t1)
    {
		/* if t1 is an instance of ti, then give error
		 * about recursive expansions.
		 */
		Dsymbol s = t1.toDsymbol(sc);
		if (s && s.parent)
		{   
			TemplateInstance ti1 = s.parent.isTemplateInstance();
			if (ti1 && ti1.tempdecl == tempdecl)
			{
				for (Scope sc1 = sc; sc1; sc1 = sc1.enclosing)
				{
					if (sc1.scopesym == ti1)
					{
						error("recursive template expansion for template argument %s", t1.toChars());
						return true;	// fake a match
					}
				}
			}
		}

		//printf("t1 = %s\n", t1.toChars());
		//printf("t2 = %s\n", t2.toChars());
		if (!t2 || !t1.equals(t2))
			goto Lnomatch;
    }
    else if (e1)
    {
static if (false) {
		if (e1 && e2)
		{
			printf("match %d\n", e1.equals(e2));
			e1.print();
			e2.print();
			e1.type.print();
			e2.type.print();
		}
}
		if (!e2)
			goto Lnomatch;
		if (!e1.equals(e2))
			goto Lnomatch;
    }
    else if (s1)
    {
		//printf("%p %s, %p %s\n", s1, s1.toChars(), s2, s2.toChars());
		if (!s2 || !s1.equals(s2) || s1.parent != s2.parent)
		{
			goto Lnomatch;
		}
	version (DMDV2) {
		VarDeclaration vv1 = s1.isVarDeclaration();
		VarDeclaration vv2 = s2.isVarDeclaration();
		if (vv1 && vv2 && vv1.storage_class & vv2.storage_class & STCmanifest)
		{   
			ExpInitializer ei1 = vv1.init.isExpInitializer();
			ExpInitializer ei2 = vv2.init.isExpInitializer();
			if (ei1 && ei2 && !ei1.exp.equals(ei2.exp))
				goto Lnomatch;
		}
	}
    }
    else if (v1)
    {
		if (!v2)
			goto Lnomatch;

		if (v1.objects.dim != v2.objects.dim)
			goto Lnomatch;

		for (size_t i = 0; i < v1.objects.dim; i++)
		{
			if (!match(v1.objects[i], v2.objects[i], tempdecl, sc))
				goto Lnomatch;
		}
    }
    //printf("match\n");
    return true;	// match

Lnomatch:
    //printf("nomatch\n");
    return false;	// nomatch;
}

class TemplateInstance : ScopeDsymbol
{
	mixin insertMemberExtension!(typeof(this));

    /* Given:
     *	foo!(args) =>
     *	    name = foo
     *	    tiargs = args
     */
    Identifier name;
    //Array idents;
    Objects tiargs;		// Array of Types/Expressions of template
				// instance arguments [int*, char, 10*10]

    Objects tdtypes;		// Array of Types/Expressions corresponding
				// to TemplateDeclaration.parameters
				// [int, char, 100]

    TemplateDeclaration tempdecl;	// referenced by foo.bar.abc
    TemplateInstance inst;		// refer to existing instance
    TemplateInstance tinst;		// enclosing template instance
    ScopeDsymbol argsym;		// argument symbol table
    AliasDeclaration aliasdecl;	// !=null if instance is an alias for its
					// sole member
    WithScopeSymbol withsym;		// if a member of a with statement
    int semanticRun;	// has semantic() been done?
    int semantictiargsdone;	// has semanticTiargs() been done?
    int nest;		// for recursion detection
    int havetempdecl;	// 1 if used second constructor
    Dsymbol isnested;	// if referencing local symbols, this is the context
    int errors;		// 1 if compiled with errors
version (IN_GCC) {
    /* On some targets, it is necessary to know whether a symbol
       will be emitted in the output or not before the symbol
       is used.  This can be different from getModule(). */
    Module objFileModule;
}

    this(Loc loc, Identifier ident)
	{
		register();
		super(null);
		
	version (LOG) {
		printf("TemplateInstance(this = %p, ident = '%s')\n", this, ident ? ident.toChars() : "null");
	}
		this.loc = loc;
		this.name = ident;
		
		tdtypes = new Objects();
	}

	/*****************
	 * This constructor is only called when we figured out which function
	 * template to instantiate.
	 */
    this(Loc loc, TemplateDeclaration td, Objects tiargs)
	{
		register();
		super(null);
		
	version (LOG) {
		printf("TemplateInstance(this = %p, tempdecl = '%s')\n", this, td.toChars());
	}
		this.loc = loc;
		this.name = td.ident;
		this.tiargs = tiargs;
		this.tempdecl = td;
		this.semantictiargsdone = 1;
		this.havetempdecl = 1;

		assert(cast(size_t)cast(void*)tempdecl.scope_ > 0x10000);
		
		tdtypes = new Objects();
	}

    static Objects arraySyntaxCopy(Objects objs)
	{
	    Objects a = null;
	    if (objs)
	    {	a = new Objects();
		a.setDim(objs.dim);
		for (size_t i = 0; i < objs.dim; i++)
		{
		    a[i] = objectSyntaxCopy(objs[i]);
		}
	    }
	    return a;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
	    TemplateInstance ti;

	    if (s)
		ti = cast(TemplateInstance)s;
	    else
		ti = new TemplateInstance(loc, name);

	    ti.tiargs = arraySyntaxCopy(tiargs);

	    ScopeDsymbol.syntaxCopy(ti);
	    return ti;
	}

    override void semantic(Scope sc)
	{
        semantic(sc, null);
    }

    void semantic(Scope sc, Expressions fargs)
    {
	    if (global.errors)
		{
			if (!global.gag)
			{
				/* Trying to soldier on rarely generates useful messages
				 * at this point.
				 */
				fatal();
			}
			return;
		}

	version (LOG) {
		printf("\n+TemplateInstance.semantic('%s', this=%p)\n", toChars(), this);
	}

		if (inst)		// if semantic() was already run
		{
version (LOG) {
			printf("-TemplateInstance.semantic('%s', this=%p) already run\n", inst.toChars(), inst);
}
			return;
		}

		// get the enclosing template instance from the scope tinst
		tinst = sc.tinst;

		if (semanticRun != 0)
		{
			error(loc, "recursive template expansion");
		//	inst = this;
			return;
		}

		semanticRun = 1;

	version (LOG) {
		printf("\tdo semantic\n");
	}
		if (havetempdecl)
		{
			assert(cast(size_t)cast(void*)tempdecl.scope_ > 0x10000);

			// Deduce tdtypes
			tdtypes.setDim(tempdecl.parameters.dim);
			if (!tempdecl.matchWithInstance(this, tdtypes, 2))
			{
				error("incompatible arguments for template instantiation");
				inst = this;
				return;
			}
		}
		else
		{
			/* Run semantic on each argument, place results in tiargs[]
			 * (if we havetempdecl, then tiargs is already evaluated)
			 */
			semanticTiargs(sc);

			tempdecl = findTemplateDeclaration(sc);
			if (tempdecl)
				tempdecl = findBestMatch(sc);

			if (!tempdecl || global.errors)
			{   
				inst = this;
				//printf("error return %p, %d\n", tempdecl, global.errors);
				return;		// error recovery
			}
		}

		hasNestedArgs(tiargs);

		/* See if there is an existing TemplateInstantiation that already
		 * implements the typeargs. If so, just refer to that one instead.
		 */

		foreach (ti; tempdecl.instances)
		{
		version (LOG) {
			printf("\t%s: checking for match with instance %d (%p): '%s'\n", toChars(), i, ti, ti.toChars());
		}
			assert(tdtypes.dim == ti.tdtypes.dim);

			// Nesting must match
			if (isnested !is ti.isnested)
			{
				//printf("test2 isnested %s ti.isnested %s\n", isnested ? isnested.toChars() : "", ti.isnested ? ti.isnested.toChars() : "");
				continue;
			}
		static if (false) {
			if (isnested && sc.parent != ti.parent)
				continue;
		}
			for (size_t j = 0; j < tdtypes.dim; j++)
			{   
				Object o1 = tdtypes[j];
				Object o2 = ti.tdtypes[j];
				if (!match(o1, o2, tempdecl, sc))
				{
					goto L1;
	            }
	        }

	        /* Template functions may have different instantiations based on
	         * "auto ref" parameters.
	         */
	        if (fargs)
	        {
	            FuncDeclaration fd = ti.toAlias().isFuncDeclaration();
	            if (fd)
	            {
		            auto fparameters = fd.getParameters(null);
		            size_t nfparams = Parameter.dim(fparameters); // Num function parameters
		            for (int i = 0; i < nfparams && i < fargs.dim; i++)
		            {   auto fparam = Parameter.getNth(fparameters, i);
		                auto farg = fargs[i];
		                if (fparam.storageClass & STCauto)		// if "auto ref"
		                {
			                if (farg.isLvalue())
			                {   if (!(fparam.storageClass & STC.STCref))
				                goto L1;			// auto ref's don't match
			                }
			                else
			                {   if (fparam.storageClass & STC.STCref)
				                goto L1;			// auto ref's don't match
			                }
		                }
		            }
				}
			}

			// It's a match
			inst = ti;
			parent = ti.parent;
		version (LOG) {
			printf("\tit's a match with instance %p\n", inst);
		}
			return;

		L1:
			;
		}

		/* So, we need to implement 'this' instance.
		 */
	version (LOG) {
		printf("\timplement template instance '%s'\n", toChars());
	}
		uint errorsave = global.errors;
		inst = this;
		int tempdecl_instance_idx = tempdecl.instances.dim;
		tempdecl.instances.push(this);
		parent = tempdecl.parent;
		//printf("parent = '%s'\n", parent.kind());

		ident = genIdent();		// need an identifier for name mangling purposes.

	static if (true) {
		if (isnested)
			parent = isnested;
	}
		//printf("parent = '%s'\n", parent.kind());

		// Add 'this' to the enclosing scope's members[] so the semantic routines
		// will get called on the instance members
	static if (true) {
		int dosemantic3 = 0;
		{	
			Dsymbols a;

			Scope scx = sc;
	static if (false) {
			for (scx = sc; scx; scx = scx.enclosing)
				if (scx.scopesym)
					break;
	}

			//if (scx && scx.scopesym) printf("3: scx is %s %s\n", scx.scopesym.kind(), scx.scopesym.toChars());
			if (scx && scx.scopesym &&
				scx.scopesym.members && !scx.scopesym.isTemplateMixin()

///	static if (false) {	// removed because it bloated compile times
///				/* The problem is if A imports B, and B imports A, and both A
///				 * and B instantiate the same template, does the compilation of A
///				 * or the compilation of B do the actual instantiation?
///				 *
///				 * see bugzilla 2500.
///				 */
///				&& !scx.module.selfImports()
///	}
			   )
			{
				//printf("\t1: adding to %s %s\n", scx.scopesym.kind(), scx.scopesym.toChars());
				a = scx.scopesym.members;
			}
			else
			{   Module m = sc.module_.importedFrom;
				//printf("\t2: adding to module %s instead of module %s\n", m.toChars(), sc.module.toChars());
				a = m.members;
				if (m.semanticRun >= 3)
					dosemantic3 = 1;
			}

			for (int i = 0; 1; i++)
			{
				if (i == a.dim)
				{
					a.push(this);
					break;
				}

				if (this is a[i])	// if already in Array
					break;
			}
		}
	}

		// Copy the syntax trees from the TemplateDeclaration
		members = Dsymbol.arraySyntaxCopy(tempdecl.members);

		// Create our own scope for the template parameters
		Scope scope_ = tempdecl.scope_;
		if (!tempdecl.semanticRun)
		{
			error("template instantiation %s forward references template declaration %s\n", toChars(), tempdecl.toChars());
			return;
		}

	version (LOG) {
		printf("\tcreate scope for template parameters '%s'\n", toChars());
	}
		argsym = new ScopeDsymbol();
		argsym.parent = scope_.parent;
		scope_ = scope_.push(argsym);
	//    scope.stc = 0;

		// Declare each template parameter as an alias for the argument type
		Scope paramscope = scope_.push();
		paramscope.stc = STCundefined;
		declareParameters(paramscope);
		paramscope.pop();

		// Add members of template instance to template instance symbol table
	//    parent = scope.scopesym;
		symtab = new DsymbolTable();
		bool memnum = false;
		foreach(Dsymbol s; members)
		{
	version (LOG) {
			printf("\t[%d] adding member '%s' %p kind %s to '%s', memnum = %d\n", i, s.toChars(), s, s.kind(), this.toChars(), memnum);
	}
			memnum |= s.addMember(scope_, this, memnum);
		}

	version (LOG) {
		printf("adding members done\n");
	}

		/* See if there is only one member of template instance, and that
		 * member has the same name as the template instance.
		 * If so, this template instance becomes an alias for that member.
		 */
		//printf("members.dim = %d\n", members.dim);
		if (members.dim)
		{
			Dsymbol s;
			if (Dsymbol.oneMembers(members, &s) && s)
			{
				//printf("s.kind = '%s'\n", s.kind());
				//s.print();
				//printf("'%s', '%s'\n", s.ident.toChars(), tempdecl.ident.toChars());
				if (s.ident && s.ident.equals(tempdecl.ident))
				{
					//printf("setting aliasdecl\n");
					aliasdecl = new AliasDeclaration(loc, s.ident, s);
				}
			}
		}
        
        /* If function template declaration
         */
        if (fargs && aliasdecl)
        {
	        FuncDeclaration fd = aliasdecl.toAlias().isFuncDeclaration();
	        if (fd)
	        {
	            /* Transmit fargs to type so that TypeFunction::semantic() can
	             * resolve any "auto ref" storage classes.
	             */
	            auto tf = cast(TypeFunction)fd.type;
	            if (tf && tf.ty == TY.Tfunction)
		        tf.fargs = fargs;
	        }
        }

		// Do semantic() analysis on template instance members
	version (LOG) {
		printf("\tdo semantic() on template instance members '%s'\n", toChars());
	}
		Scope sc2;
		sc2 = scope_.push(this);
		//printf("isnested = %d, sc.parent = %s\n", isnested, sc.parent.toChars());
		sc2.parent = /*isnested ? sc.parent :*/ this;
		sc2.tinst = this;

		try
		{
//			static int nest;
			//printf("%d\n", nest);
			if (++nest > 500)
			{
				global.gag = 0;			// ensure error message gets printed
				error("recursive expansion");
				fatal();
			}
			foreach(Dsymbol s; members)
			{
				//printf("\t[%d] semantic on '%s' %p kind %s in '%s'\n", i, s.toChars(), s, s.kind(), this.toChars());
				//printf("test: isnested = %d, sc2.parent = %s\n", isnested, sc2.parent.toChars());
				//	if (isnested)
				//	    s.parent = sc.parent;
				//printf("test3: isnested = %d, s.parent = %s\n", isnested, s.parent.toChars());
				s.semantic(sc2);
				//printf("test4: isnested = %d, s.parent = %s\n", isnested, s.parent.toChars());
				sc2.module_.runDeferredSemantic();
			}
			--nest;
		}
		catch (Exception e)
		{
			global.gag = 0;			// ensure error message gets printed
			error("recursive expansion");
			fatal();
		}

		/* If any of the instantiation members didn't get semantic() run
		 * on them due to forward references, we cannot run semantic2()
		 * or semantic3() yet.
		 */
		auto deferred = global.deferred;
		for (size_t i = 0; i < deferred.dim; i++)
		{	
			Dsymbol sd = cast(Dsymbol)deferred.data[i];

			if (sd.parent is this)
				goto Laftersemantic;
		}

		/* The problem is when to parse the initializer for a variable.
		 * Perhaps VarDeclaration.semantic() should do it like it does
		 * for initializers inside a function.
		 */
		//    if (sc.parent.isFuncDeclaration())

		/* BUG 782: this has problems if the classes this depends on
		 * are forward referenced. Find a way to defer semantic()
		 * on this template.
		 */
		semantic2(sc2);

		if (sc.func || dosemantic3)
		{
			try
			{
//				static int nest; // TODO: 
				if (++nest > 300)
				{
				global.gag = 0;			// ensure error message gets printed
				error("recursive expansion");
				fatal();
				}
				semantic3(sc2);
				--nest;
			}
			catch (Exception e)
			{
				global.gag = 0;			// ensure error message gets printed
				error("recursive expansion");
				fatal();
			}
		}

	Laftersemantic:
		sc2.pop();

		scope_.pop();

		// Give additional context info if error occurred during instantiation
		if (global.errors != errorsave)
		{
			error("error instantiating");
			if (tinst)
			{   
				tinst.printInstantiationTrace();
			}
			errors = 1;
			if (global.gag)
				tempdecl.instances.remove(tempdecl_instance_idx);
		}

	version (LOG) {
		printf("-TemplateInstance.semantic('%s', this=%p)\n", toChars(), this);
	}
	}

    override void semantic2(Scope sc)
	{
		if (semanticRun >= 2)
			return;

		semanticRun = 2;
	version (LOG) {
		printf("+TemplateInstance.semantic2('%s')\n", toChars());
	}

		if (!errors && members)
		{
			sc = tempdecl.scope_;
			assert(sc);
			sc = sc.push(argsym);
			sc = sc.push(this);
			sc.tinst = this;

			foreach(Dsymbol s; members)
			{
	version (LOG) {
				printf("\tmember '%s', kind = '%s'\n", s.toChars(), s.kind());
	}
				s.semantic2(sc);
			}

			sc = sc.pop();
			sc.pop();
		}

	version (LOG) {
		printf("-TemplateInstance.semantic2('%s')\n", toChars());
	}
	}

    override void semantic3(Scope sc)
	{
	version (LOG) {
		printf("TemplateInstance.semantic3('%s'), semanticRun = %d\n", toChars(), semanticRun);
	}
	//if (toChars()[0] == 'D') *(char*)0=0;
		if (semanticRun >= 3)
			return;
		semanticRun = 3;
		if (!errors && members)
		{
			sc = tempdecl.scope_;
			sc = sc.push(argsym);
			sc = sc.push(this);
			sc.tinst = this;
			foreach(Dsymbol s; members)
				s.semantic3(sc);
			sc = sc.pop();
			sc.pop();
		}
	}

    override void inlineScan()
	{
	version (LOG) {
		printf("TemplateInstance.inlineScan('%s')\n", toChars());
	}
		if (!errors && members)
		{
			foreach(Dsymbol s; members)
				s.inlineScan();
		}
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		int i;

		Identifier id = name;
		buf.writestring(id.toChars());
		buf.writestring("!(");
		if (nest)
			buf.writestring("...");
		else
		{
			nest++;
			Objects args = tiargs;
			for (i = 0; i < args.dim; i++)
			{
				if (i)
					buf.writeByte(',');
				Object oarg = args[i];
				ObjectToCBuffer(buf, hgs, oarg);
			}
			nest--;
		}
		buf.writeByte(')');
	}
	
    override Dsymbol toAlias()			// resolve real symbol
	{
	version (LOG)
	{
		writef("TemplateInstance.toAlias()\n");
	}
		if (!inst)
		{	
			error("cannot resolve forward reference");
			errors = 1;
			return this;
		}

		if (inst !is this)
			return inst.toAlias();

		if (aliasdecl)
		{
			return aliasdecl.toAlias();
		}

		return inst;
	}
	
    override string kind()
	{
	    return "template instance";
	}
	
    override bool oneMember(Dsymbol* ps)
	{
	    *ps = null;
	    return true;
	}
    
    /*****************************************************
     * Determine if template instance is really a template function,
     * and that template function needs to infer types from the function
     * arguments.
     */

    bool needsTypeInference(Scope sc)
    {
        //printf("TemplateInstance::needsTypeInference() %s\n", toChars());
        if (!tempdecl)
	        tempdecl = findTemplateDeclaration(sc);
        for (TemplateDeclaration td = tempdecl; td; td = td.overnext)
        {
	    /* If any of the overloaded template declarations need inference,
	     * then return TRUE
	     */
	    FuncDeclaration fd;
	    if (!td.onemember ||
	        (fd = td.onemember.toAlias().isFuncDeclaration()) is null ||
	        fd.type.ty != TY.Tfunction)
	    {
	        /* Not a template function, therefore type inference is not possible.
	         */
	        //printf("false\n");
	        return false;
	    }

	    /* Determine if the instance arguments, tiargs, are all that is necessary
	     * to instantiate the template.
	     */
	    TemplateTupleParameter tp = td.isVariadic();
	    //printf("tp = %p, td->parameters->dim = %d, tiargs->dim = %d\n", tp, td->parameters->dim, tiargs->dim);
	    TypeFunction fdtype = cast(TypeFunction)fd.type;
	    if (Parameter.dim(fdtype.parameters) &&
	        (tp || tiargs.dim < td.parameters.dim))
	        return true;
        }
        //printf("false\n");
        return false;
    }
    
    override string toChars()
	{
		scope OutBuffer buf = new OutBuffer();
		HdrGenState hgs;

		toCBuffer(buf, &hgs);
		return buf.extractString();
	}
	
    override string mangle()
	{
	    OutBuffer buf = new OutBuffer();
	    string id;

	static if (false) {
	    printf("TemplateInstance.mangle() %s", toChars());
	    if (parent)
		printf("  parent = %s %s", parent.kind(), parent.toChars());
	    printf("\n");
	}
	    id = ident ? ident.toChars() : toChars();
	    if (!tempdecl)
		error("is not defined");
	    else if (tempdecl.parent)
	    {
		string p = tempdecl.parent.mangle();
		if (p[0] == '_' && p[1] == 'D')
		    p = p[2..$];
		buf.writestring(p);
	    }
	    buf.printf("%d%s", id.length, id);
	    id = buf.toChars();
	    buf.data = null;
	    //printf("TemplateInstance.mangle() %s = %s\n", toChars(), id);
	    return id;
	}
	
    /**************************************
     * Given an error instantiating the TemplateInstance,
     * give the nested TemplateInstance instantiations that got
     * us here. Those are a list threaded into the nested scopes.
     */
    void printInstantiationTrace()
	{
	    if (global.gag)
		    return;
/+
        const int max_shown = 6;
        const string format = "%s:        instantiated from here: %s\n";

        // determine instantiation depth and number of recursive instantiations
        int n_instantiations = 1;
        int n_totalrecursions = 0;
        for (TemplateInstance cur = this; cur; cur = cur.tinst)
        {
	        ++n_instantiations;
	        // If two instantiations use the same declaration, they are recursive.
	        // (this works even if they are instantiated from different places in the
	        // same template).
	        // In principle, we could also check for multiple-template recursion, but it's
	        // probably not worthwhile.
	        if (cur.tinst && cur.tempdecl && cur.tinst.tempdecl
	            && cur.tempdecl.loc.equals(cur.tinst.tempdecl.loc))
	            ++n_totalrecursions;
        }

        // show full trace only if it's short or verbose is on
        if (n_instantiations <= max_shown || global.params.verbose)
        {
	        for (TemplateInstance cur = this; cur; cur = cur.tinst)
	        {
	            fprintf(stdmsg, format, cur.loc.toChars(), cur.toChars());
	        }
        }
        else if (n_instantiations - n_totalrecursions <= max_shown)
        {
	        // By collapsing recursive instantiations into a single line,
	        // we can stay under the limit.
	        int recursionDepth=0;
	        for (TemplateInstance cur = this; cur; cur = cur.tinst)
	        {
	            if (cur.tinst && cur.tempdecl && cur.tinst.tempdecl
		            && cur.tempdecl.loc.equals(cur.tinst.tempdecl.loc))
	            {
    		        ++recursionDepth;
	            }
	            else
	            {
		            if (recursionDepth)
		                fprintf(stdmsg, "%s:        %d recursive instantiations from here: %s\n", cur.loc.toChars(), recursionDepth+2, cur.toChars());
		            else 
		                fprintf(stdmsg,format, cur.loc.toChars(), cur.toChars());
		            recursionDepth = 0;
	            }
	        }
        }
        else
        {
	        // Even after collapsing the recursions, the depth is too deep.
	        // Just display the first few and last few instantiations.
	        size_t i = 0;
	        for (TemplateInstance cur = this; cur; cur = cur.tinst)
	        {
	            if (i == max_shown / 2)
		        fprintf(stdmsg,"    ... (%d instantiations, -v to show) ...\n", n_instantiations - max_shown);

	            if (i < max_shown / 2 ||
		        i >= n_instantiations - max_shown + max_shown / 2)
		        fprintf(stdmsg, format, cur.loc.toChars(), cur.toChars());
	            ++i;
	        }
        }
+/
	}

    override void toObjFile(int multiobj)			// compile to .obj file
	{
	version (LOG) {
		printf("TemplateInstance.toObjFile('%s', this = %p)\n", toChars(), this);
	}
		if (!errors && members)
		{
			if (multiobj)
				// Append to list of object files to be written later
				obj_append(this);
			else
			{
				foreach(Dsymbol s; members)
					s.toObjFile(multiobj);
			}
		}
	}

    // Internal
	/**********************************
	 * Input:
	 *	flags	1: replace const variables with their initializers
	 */
    static void semanticTiargs(Loc loc, Scope sc, Objects tiargs, int flags)
	{
		// Run semantic on each argument, place results in tiargs[]
		//printf("+TemplateInstance.semanticTiargs() %s\n", toChars());
		if (!tiargs)
			return;
		for (size_t j = 0; j < tiargs.dim; j++)
		{
			Object o = tiargs[j];
			Type ta = isType(o);
			Expression ea = isExpression(o);
			Dsymbol sa = isDsymbol(o);

			//printf("1: tiargs.data[%d] = %p, %p, %p, ea=%p, ta=%p\n", j, o, isDsymbol(o), isTuple(o), ea, ta);
			if (ta)
			{
				//printf("type %s\n", ta.toChars());
				// It might really be an Expression or an Alias
				ta.resolve(loc, sc, &ea, &ta, &sa);
				if (ea)
				{
					ea = ea.semantic(sc);
					/* This test is to skip substituting a const var with
					 * its initializer. The problem is the initializer won't
					 * match with an 'alias' parameter. Instead, do the
					 * const substitution in TemplateValueParameter.matchArg().
					 */
					if (ea.op != TOKvar || flags & 1)
						ea = ea.optimize(WANTvalue | WANTinterpret);

					tiargs[j] = ea;
				}
				else if (sa)
				{	
					tiargs[j] = sa;
					TupleDeclaration d = sa.toAlias().isTupleDeclaration();
					if (d)
					{
						size_t dim = d.objects.dim;
						tiargs.remove(j);
						tiargs.insert(j, d.objects);
						j--;
					}
				}
				else if (ta)
				{
				Ltype:
					if (ta.ty == Ttuple)
					{   
						// Expand tuple
						auto tt = cast(TypeTuple)ta;
						size_t dim = tt.arguments.dim;
						tiargs.remove(j);
						if (dim)
						{	
							tiargs.reserve(dim);
							for (size_t i = 0; i < dim; i++)
							{   
								auto arg = tt.arguments[i];
								tiargs.insert(j + i, arg.type);
							}
						}
						j--;
					}
					else
						tiargs[j] = ta;
				}
				else
				{
					assert(global.errors);
					tiargs[j] = Type.terror;
				}
			}
			else if (ea)
			{
				if (!ea)
				{	
					assert(global.errors);
					ea = new IntegerExp(0);
				}
				assert(ea);
				ea = ea.semantic(sc);
				if (ea.op != TOKvar || flags & 1)
					ea = ea.optimize(WANTvalue | WANTinterpret);
				tiargs[j] = ea;
				if (ea.op == TOKtype)
				{	
					ta = ea.type;
					goto Ltype;
				}
				if (ea.op == TOKtuple)
				{   
					// Expand tuple
					auto te = cast(TupleExp)ea;
					size_t dim = te.exps.dim;
					tiargs.remove(j);
					if (dim)
					{   
						tiargs.reserve(dim);
						for (size_t i = 0; i < dim; i++)
						tiargs.insert(j + i, te.exps[i]);
					}
					j--;
				}
			}
			else if (sa)
			{
				TemplateDeclaration td = sa.isTemplateDeclaration();
				if (td && !td.semanticRun && td.literal)
					td.semantic(sc);
			}
			else
			{
				assert(0);
			}
			//printf("1: tiargs.data[%d] = %p\n", j, tiargs.data[j]);
		}

static if (false) {
		printf("-TemplateInstance.semanticTiargs('%s', this=%p)\n", toChars(), this);
		for (size_t j = 0; j < tiargs.dim; j++)
		{
			Object o = cast(Object)tiargs.data[j];
			Type ta = isType(o);
			Expression ea = isExpression(o);
			Dsymbol sa = isDsymbol(o);
			Tuple va = isTuple(o);

			printf("\ttiargs[%d] = ta %p, ea %p, sa %p, va %p\n", j, ta, ea, sa, va);
		}
}
	}

    void semanticTiargs(Scope sc)
	{
		//printf("+TemplateInstance.semanticTiargs() %s\n", toChars());
		if (semantictiargsdone)
			return;

		semantictiargsdone = 1;
		semanticTiargs(loc, sc, tiargs, 0);
	}

	/**********************************************
	 * Find template declaration corresponding to template instance.
	*/
	TemplateDeclaration findTemplateDeclaration(Scope sc)
	{
		//printf("TemplateInstance.findTemplateDeclaration() %s\n", toChars());
		if (!tempdecl)
		{
			/* Given:
			 *    foo!( ... )
			 * figure out which TemplateDeclaration foo refers to.
			 */
			Dsymbol s;
			Dsymbol scopesym;
			int i;

			Identifier id = name;
			s = sc.search(loc, id, &scopesym);
			if (!s)
			{   
				error("template '%s' is not defined", id.toChars());
				return null;
			}

	        /* If an OverloadSet, look for a unique member that is a template declaration
	         */
	        OverloadSet os = s.isOverloadSet();
	        if (os)
	        {
                s = null;
	            foreach (s2; os.a)
	            {
		            if (s2.isTemplateDeclaration())
		            {
		                if (s)
			                error("ambiguous template declaration %s and %s", s.toPrettyChars(), s2.toPrettyChars());
		                s = s2;
		            }
	            }
	            if (!s)
	            {
                    error("template '%s' is not defined", id.toChars());
		            return null;
	            }
	        }

		version (LOG) {
			printf("It's an instance of '%s' kind '%s'\n", s.toChars(), s.kind());
			if (s.parent)
				printf("s.parent = '%s'\n", s.parent.toChars());
		}
			withsym = scopesym.isWithScopeSymbol();

			/* We might have found an alias within a template when
			 * we really want the template.
			 */
			TemplateInstance ti;
			if (s.parent &&
				(ti = s.parent.isTemplateInstance()) !is null)
			{
				if (
					(ti.name == id ||
					ti.toAlias().ident == id)
					&&
					ti.tempdecl
				  )
				{
					/* This is so that one can refer to the enclosing
					 * template, even if it has the same name as a member
					 * of the template, if it has a !(arguments)
					 */
					tempdecl = ti.tempdecl;
					if (tempdecl.overroot)		// if not start of overloaded list of TemplateDeclaration's
						tempdecl = tempdecl.overroot; // then get the start

					s = tempdecl;
				}
			}

			s = s.toAlias();

			/* It should be a TemplateDeclaration, not some other symbol
			 */
			tempdecl = s.isTemplateDeclaration();
			if (!tempdecl)
			{
				if (!s.parent && global.errors)
				return null;
				if (!s.parent && s.getType())
				{	
					Dsymbol s2 = s.getType().toDsymbol(sc);
					if (!s2)
					{
						error("%s is not a template declaration, it is a %s", id.toChars(), s.kind());
						return null;
					}
					s = s2;
				}
		debug {
				//if (!s.parent) printf("s = %s %s\n", s.kind(), s.toChars());
		}
				//assert(s.parent);
				TemplateInstance ti2 = s.parent ? s.parent.isTemplateInstance() : null;
				if (ti2 &&
					(ti2.name == id ||
					ti2.toAlias().ident == id)
					&&
					ti2.tempdecl
				  )
				{
					/* This is so that one can refer to the enclosing
					 * template, even if it has the same name as a member
					 * of the template, if it has a !(arguments)
					 */
					tempdecl = ti2.tempdecl;
					if (tempdecl.overroot)		// if not start of overloaded list of TemplateDeclaration's
						tempdecl = tempdecl.overroot; // then get the start
				}
				else
				{
					error("%s is not a template declaration, it is a %s", id.toChars(), s.kind());
					return null;
				}
			}
		}
		else
			assert(tempdecl.isTemplateDeclaration());

		return tempdecl;
	}

    TemplateDeclaration findBestMatch(Scope sc)
	{
		/* Since there can be multiple TemplateDeclaration's with the same
		 * name, look for the best match.
		 */
		TemplateDeclaration td_ambig = null;
		TemplateDeclaration td_best = null;
		MATCH m_best = MATCHnomatch;
		scope Objects dedtypes = new Objects();

	version (LOG) {
		printf("TemplateInstance.findBestMatch()\n");
	}
		// First look for forward references
		for (TemplateDeclaration td = tempdecl; td; td = td.overnext)
		{
			if (!td.semanticRun)
			{
				if (td.scope_)
				{	
					// Try to fix forward reference
					td.semantic(td.scope_);
				}
				if (!td.semanticRun)
				{
					error("%s forward references template declaration %s\n", toChars(), td.toChars());
					return null;
				}
			}
		}

		for (TemplateDeclaration td = tempdecl; td; td = td.overnext)
		{
			MATCH m;

		//if (tiargs.dim) printf("2: tiargs.dim = %d, data[0] = %p\n", tiargs.dim, tiargs.data[0]);

			// If more arguments than parameters,
			// then this is no match.
			if (td.parameters.dim < tiargs.dim)
			{
				if (!td.isVariadic())
					continue;
			}

			dedtypes.setDim(td.parameters.dim);
			dedtypes.zero();
			assert(td.semanticRun);
			m = td.matchWithInstance(this, dedtypes, 0);
			//printf("matchWithInstance = %d\n", m);
			if (!m)			// no match at all
				continue;

			if (m < m_best)
				goto Ltd_best;
			if (m > m_best)
				goto Ltd;

			{
				// Disambiguate by picking the most specialized TemplateDeclaration
				MATCH c1 = td.leastAsSpecialized(td_best);
				MATCH c2 = td_best.leastAsSpecialized(td);
				//printf("c1 = %d, c2 = %d\n", c1, c2);

				if (c1 > c2)
					goto Ltd;
				else if (c1 < c2)
					goto Ltd_best;
				else
					goto Lambig;
			}

		Lambig:		// td_best and td are ambiguous
			td_ambig = td;
			continue;

		Ltd_best:		// td_best is the best match so far
			td_ambig = null;
			continue;

		Ltd:		// td is the new best match
			td_ambig = null;
			td_best = td;
			m_best = m;
			tdtypes.setDim(dedtypes.dim);
			memcpy(tdtypes.ptr, dedtypes.ptr, tdtypes.dim * (void*).sizeof);
			continue;
		}

		if (!td_best)
		{
			if (tempdecl && !tempdecl.overnext)
				// Only one template, so we can give better error message
				error("%s does not match template declaration %s", toChars(), tempdecl.toChars());
			else
				error("%s does not match any template declaration", toChars());
			return null;
		}

		if (td_ambig)
		{
			error("%s matches more than one template declaration, %s and %s",
				toChars(), td_best.toChars(), td_ambig.toChars());
		}

		/* The best match is td_best
		 */
		tempdecl = td_best;

	static if (false) {
		/* Cast any value arguments to be same type as value parameter
		 */
		for (size_t i = 0; i < tiargs.dim; i++)
		{	
			Object o = cast(Object)tiargs.data[i];
			Expression ea = isExpression(o);	// value argument
			TemplateParameter tp = cast(TemplateParameter)tempdecl.parameters.data[i];
			assert(tp);
			TemplateValueParameter tvp = tp.isTemplateValueParameter();
			if (tvp)
			{
				assert(ea);
				ea = ea.castTo(tvp.valType);
				ea = ea.optimize(WANTvalue | WANTinterpret);
				tiargs.data[i] = cast(Object)ea;
			}
		}
	}

	version (LOG) {
		printf("\tIt's a match with template declaration '%s'\n", tempdecl.toChars());
	}
		return tempdecl;
	}

	/****************************************************
	 * Declare parameters of template instance, initialize them with the
	 * template instance arguments.
	 */
    void declareParameters(Scope sc)
	{
		//printf("TemplateInstance.declareParameters()\n");
		for (int i = 0; i < tdtypes.dim; i++)
		{
			auto tp = tempdecl.parameters[i];
			//Object o = cast(Object)tiargs.data[i];
			Object o = tdtypes[i];		// initializer for tp

			//printf("\ttdtypes[%d] = %p\n", i, o);
			tempdecl.declareParameter(sc, tp, o);
		}
	}

	/*****************************************
	 * Determines if a TemplateInstance will need a nested
	 * generation of the TemplateDeclaration.
	 */
    bool hasNestedArgs(Objects args)
	{
		bool nested = false;
		//printf("TemplateInstance.hasNestedArgs('%s')\n", tempdecl.ident.toChars());

		/* A nested instance happens when an argument references a local
		 * symbol that is on the stack.
		 */
		for (size_t i = 0; i < args.dim; i++)
		{   
			Object o = args[i];
			Expression ea = isExpression(o);
			Dsymbol sa = isDsymbol(o);
			Tuple va = isTuple(o);
			if (ea)
			{
				if (ea.op == TOKvar)
				{
					sa = (cast(VarExp)ea).var;
					goto Lsa;
				}
				if (ea.op == TOKfunction)
				{
					sa = (cast(FuncExp)ea).fd;
					goto Lsa;
				}
			}
			else if (sa)
			{
			  Lsa:
				TemplateDeclaration td = sa.isTemplateDeclaration();
				Declaration d = sa.isDeclaration();
				if ((td && td.literal) ||
					(d && !d.isDataseg() &&

///		version (DMDV2) { // TODO:
					!(d.storage_class & STCmanifest) &&
///		}
					(!d.isFuncDeclaration() || d.isFuncDeclaration().isNested()) &&
					!isTemplateMixin()
					))
				{
					// if module level template
					if (tempdecl.toParent().isModule())
					{   
						Dsymbol dparent = sa.toParent();
						if (!isnested)
							isnested = dparent;
						else if (isnested != dparent)
						{
							/* Select the more deeply nested of the two.
							 * Error if one is not nested inside the other.
							 */
							for (Dsymbol p = isnested; p; p = p.parent)
							{
								if (p == dparent)
									goto L1;	// isnested is most nested
							}
							for (Dsymbol p = dparent; p; p = p.parent)
							{
								if (p == isnested)
								{	
									isnested = dparent;
									goto L1;	// dparent is most nested
								}
							}
							error("%s is nested in both %s and %s",
								toChars(), isnested.toChars(), dparent.toChars());
						}
					  L1:
						//printf("\tnested inside %s\n", isnested.toChars());
						nested |= 1;
					}
					else
						error("cannot use local '%s' as parameter to non-global template %s", d.toChars(), tempdecl.toChars());
				}
			}
			else if (va)
			{
				nested |= hasNestedArgs(va.objects);
			}
		}
		return nested;
	}

	/****************************************
	 * This instance needs an identifier for name mangling purposes.
	 * Create one by taking the template declaration name and adding
	 * the type signature for it.
	 */
    Identifier genIdent()
	{
		scope OutBuffer buf = new OutBuffer();

		//printf("TemplateInstance.genIdent('%s')\n", tempdecl.ident.toChars());
		string id = tempdecl.ident.toChars();
		buf.printf("__T%d%s", id.length, id);	///!
		Objects args = tiargs;
		for (int i = 0; i < args.dim; i++)
		{   
			Object o = args[i];
			Type ta = isType(o);
			Expression ea = isExpression(o);
			Dsymbol sa = isDsymbol(o);
			Tuple va = isTuple(o);
			//printf("\to [%d] %p ta %p ea %p sa %p va %p\n", i, o, ta, ea, sa, va);
			if (ta)
			{
				buf.writeByte('T');
				if (ta.deco)
					buf.writestring(ta.deco);
				else
				{
					debug writef("ta = %d, %s\n", ta.ty, ta.toChars());
					assert(global.errors);
				}
			}
			else if (ea)
			{
			  Lea:
				long v;
				real r;

				ea = ea.optimize(WANTvalue | WANTinterpret);
				if (ea.op == TOKvar)
				{
					sa = (cast(VarExp)ea).var;
					ea = null;
					goto Lsa;
				}
				if (ea.op == TOKfunction)
				{
					sa = (cast(FuncExp)ea).fd;
					ea = null;
					goto Lsa;
				}
				buf.writeByte('V');
				if (ea.op == TOKtuple)
				{	
					ea.error("tuple is not a valid template value argument");
					continue;
				}
		static if (true) {
				/* Use deco that matches what it would be for a function parameter
				 */
				buf.writestring(ea.type.deco);
		} else {
				// Use type of parameter, not type of argument
				TemplateParameter tp = cast(TemplateParameter)tempdecl.parameters.data[i];
				assert(tp);
				TemplateValueParameter tvp = tp.isTemplateValueParameter();
				assert(tvp);
				buf.writestring(tvp.valType.deco);
		}
				ea.toMangleBuffer(buf);
			}
			else if (sa)
			{
			  Lsa:
				buf.writeByte('S');
				Declaration d = sa.isDeclaration();
				if (d && (!d.type || !d.type.deco))
				{	
					error("forward reference of %s", d.toChars());
					continue;
				}
		static if (false) {
				VarDeclaration v = sa.isVarDeclaration();
				if (v && v.storage_class & STCmanifest)
				{	
					ExpInitializer ei = v.init.isExpInitializer();
					if (ei)
					{
						ea = ei.exp;
						goto Lea;
					}
				}
		}
				string p = sa.mangle();
				///buf.printf("%zu%s", p.length, p);
				buf.printf("%su%s", p.length, p);
			}
			else if (va)
			{
				assert(i + 1 == args.dim);		// must be last one
				args = va.objects;
				i = -1;
			}
			else
				assert(0);
		}
		buf.writeByte('Z');
		id = buf.toChars();
		buf.data = null;
		//printf("\tgenIdent = %s\n", id);
		return new Identifier(id, TOKidentifier);
	}

    override TemplateInstance isTemplateInstance() { return this; }

    override AliasDeclaration isAliasDeclaration()
	{
		assert(false);
	}
}
