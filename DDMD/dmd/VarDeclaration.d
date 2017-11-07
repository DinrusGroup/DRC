module dmd.VarDeclaration;

import dmd.common;
import dmd.Array;
import dmd.Declaration;
import dmd.SliceExp;
import dmd.ClassDeclaration;
import dmd.DeleteExp;
import dmd.SymOffExp;
import dmd.DotIdExp;
import dmd.PtrExp;
import dmd.CallExp;
import dmd.DotVarExp;
import dmd.CommaExp;
import dmd.CastExp;
import dmd.WANT;
import dmd.StructDeclaration;
import dmd.StorageClassDeclaration;
import dmd.DsymbolExp;
import dmd.TypeSArray;
import dmd.IntegerExp;
import dmd.VarExp;
import dmd.AssignExp;
import dmd.TypeTypedef;
import dmd.ArrayInitializer;
import dmd.StructInitializer;
import dmd.NewExp;
import dmd.TupleDeclaration;
import dmd.AggregateDeclaration;
import dmd.InterfaceDeclaration;
import dmd.TemplateInstance;
import dmd.Id;
import dmd.Initializer;
import dmd.TypeStruct;
import dmd.TypeTuple;
import dmd.Parameter;
import dmd.ExpInitializer;
import dmd.ArrayTypes;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Loc;
import dmd.STC;
import dmd.TOK;
import dmd.TupleExp;
import dmd.Global;
import dmd.Module;
import dmd.FuncDeclaration;
import dmd.Type;
import dmd.TY;
import dmd.LINK;
import dmd.Scope;
import dmd.Identifier;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.PROT;
import dmd.expression.Util;

import dmd.backend.Symbol;
import dmd.backend.TYM;
import dmd.backend.FL;
import dmd.backend.DT;
import dmd.backend.mTY;
import dmd.backend.SC;
import dmd.backend.mTYman;
import dmd.backend.TYPE;
import dmd.backend.Util;
import dmd.backend.LIST;

import std.stdio : writef;
import std.string : toStringz;

import dmd.DDMDExtensions;

class VarDeclaration : Declaration
{
	mixin insertMemberExtension!(typeof(this));

    Initializer init;
    uint offset;
    bool noauto;			// no auto semantics
version (DMDV2) {
	FuncDeclarations nestedrefs; // referenced by these lexically nested functions
	bool isargptr = false;		// if parameter that _argptr points to
} else {
    int nestedref;		// referenced by a lexically nested function
}
    int ctorinit;		// it has been initialized in a ctor
    int onstack;		// 1: it has been allocated on the stack
				// 2: on stack, run destructor anyway
    int canassign;		// it can be assigned to
    Dsymbol aliassym;		// if redone as alias to another symbol
    Expression value;		// when interpreting, this is the value
				// (null if value not determinable)
version (DMDV2) {
    VarDeclaration rundtor;	// if !null, rundtor is tested at runtime to see
				// if the destructor should be run. Used to prevent
				// dtor calls on postblitted vars
}

    this(Loc loc, Type type, Identifier id, Initializer init)
	{
		register();
		super(id);
		
debug
{
		if (!type && !init)
		{
			writef("VarDeclaration('%s')\n", id.toChars());
			//*(char*)0=0;
		}
}
		assert(type || init);
		this.type = type;
		this.init = init;
version(_DH)
{
		this.htype = null;
		this.hinit = null;
}
		this.loc = loc;
		
		/* TODO:
		#if DMDV1
    	nestedref = 0;
		#endif
		ctorinit = 0;
		aliassym = NULL;
		onstack = 0;
		canassign = 0;
		value = NULL;
		rundtor = NULL;
		 */
		nestedrefs = new FuncDeclarations();
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		//printf("VarDeclaration.syntaxCopy(%s)\n", toChars());

		VarDeclaration sv;
		if (s)
		{	
			sv = cast(VarDeclaration)s;
		}
		else
		{
			Initializer init = null;
			if (this.init)
			{   
				init = this.init.syntaxCopy();
				//init.isExpInitializer().exp.print();
				//init.isExpInitializer().exp.dump(0);
			}

			sv = new VarDeclaration(loc, type ? type.syntaxCopy() : null, ident, init);
			sv.storage_class = storage_class;
		}

	version (_DH) {
		// Syntax copy for header file
		if (!htype)      // Don't overwrite original
		{
			if (type)    // Make copy for both old and new instances
			{   htype = type.syntaxCopy();
				sv.htype = type.syntaxCopy();
			}
		}
		else            // Make copy of original for new instance
			sv.htype = htype.syntaxCopy();
		if (!hinit)
		{	
			if (init)
			{   
				hinit = init.syntaxCopy();
				sv.hinit = init.syntaxCopy();
			}
		}
		else
			sv.hinit = hinit.syntaxCopy();
	}
		return sv;
	}

    override void semantic(Scope sc)
	{
static if (false) {
		printf("VarDeclaration.semantic('%s', parent = '%s')\n", toChars(), sc.parent.toChars());
		printf(" type = %s\n", type ? type.toChars() : "null");
		printf(" stc = x%x\n", sc.stc);
		printf(" storage_class = x%x\n", storage_class);
		printf("linkage = %d\n", sc.linkage);
		//if (strcmp(toChars(), "mul") == 0) halt();
}

		storage_class |= sc.stc;
		if (storage_class & STC.STCextern && init)
			error("extern symbols cannot have initializers");
		
		/* If auto type inference, do the inference
		 */
		int inferred = 0;
		if (!type)
		{
			inuse++;
			
			ArrayInitializer ai = init.isArrayInitializer();
			if (ai)
			{
				Expression e;
				if (ai.isAssociativeArray())
					e = ai.toAssocArrayLiteral();
				else
					e = init.toExpression();
				init = new ExpInitializer(e.loc, e);
				type = init.inferType(sc);
				if (type.ty == TY.Tsarray)
					type = type.nextOf().arrayOf();
			}
			else
				type = init.inferType(sc);
			
			inuse--;
			inferred = 1;

			if (init.isArrayInitializer() && type.toBasetype().ty == TY.Tsarray)
			{   // Prefer array literals to give a T[] type rather than a T[dim]
				type = type.toBasetype().nextOf().arrayOf();
			}
			
			/* This is a kludge to support the existing syntax for RAII
			 * declarations.
			 */
			storage_class &= ~STC.STCauto;
			originalType = type;
		}
		else
		{	
			if (!originalType)
				originalType = type;
				
			type = type.semantic(loc, sc);
		}
		//printf(" semantic type = %s\n", type ? type.toChars() : "null");

		type.checkDeprecated(loc, sc);
		linkage = sc.linkage;
		this.parent = sc.parent;
		//printf("this = %p, parent = %p, '%s'\n", this, parent, parent.toChars());
		protection = sc.protection;
		//printf("sc.stc = %x\n", sc.stc);
		//printf("storage_class = x%x\n", storage_class);

version (DMDV2) {
static if (true) {
		if (storage_class & STC.STCgshared && sc.func && sc.func.isSafe())
		{
		error("__gshared not allowed in safe functions; use shared");
		}
} else {
		if (storage_class & STC.STCgshared && global.params.safe && !sc.module_.safe)
		{
		error("__gshared not allowed in safe mode; use shared");
		}
}
}

		Dsymbol parent = toParent();
		FuncDeclaration fd = parent.isFuncDeclaration();

		Type tb = type.toBasetype();
		if (tb.ty == TY.Tvoid && !(storage_class & STC.STClazy))
		{	error("voids have no value");
		type = Type.terror;
		tb = type;
		}
		if (tb.ty == TY.Tfunction)
		{	error("cannot be declared to be a function");
		type = Type.terror;
		tb = type;
		}
		if (tb.ty == TY.Tstruct)
		{	TypeStruct ts = cast(TypeStruct)tb;

		if (!ts.sym.members)
		{
			error("no definition of struct %s", ts.toChars());
		}
		}

		if (tb.ty == TY.Ttuple)
		{   /* Instead, declare variables for each of the tuple elements
			* and add those.
			*/
		TypeTuple tt = cast(TypeTuple)tb;
		size_t nelems = Parameter.dim(tt.arguments);
		Objects exps = new Objects();
		exps.setDim(nelems);
		Expression ie = init ? init.toExpression() : null;

		for (size_t i = 0; i < nelems; i++)
		{   auto arg = Parameter.getNth(tt.arguments, i);

			auto buf = new OutBuffer();
			///buf.printf("_%s_field_%zu", ident.toChars(), i);
			buf.printf("_%s_field_%s", ident.toChars(), i);
			buf.writeByte(0);
			string name = buf.extractString();
			Identifier id = new Identifier(name, TOK.TOKidentifier);

			Expression einit = ie;
			if (ie && ie.op == TOK.TOKtuple)
			{	einit = (cast(TupleExp)ie).exps[i];
			}
			Initializer ti = init;
			if (einit)
			{	ti = new ExpInitializer(einit.loc, einit);
			}

			auto v = new VarDeclaration(loc, arg.type, id, ti);
			//printf("declaring field %s of type %s\n", v.toChars(), v.type.toChars());
			v.semantic(sc);

			if (sc.scopesym)
			{	//printf("adding %s to %s\n", v.toChars(), sc.scopesym.toChars());
			if (sc.scopesym.members)
				sc.scopesym.members.push(v);
			}

			auto e = new DsymbolExp(loc, v);
			exps[i] = e;
		}
		auto v2 = new TupleDeclaration(loc, ident, exps);
		v2.isexp = 1;
		aliassym = v2;
		return;
		}

	Lagain:
		/* Storage class can modify the type
		 */
		type = type.addStorageClass(storage_class);

		/* Adjust storage class to reflect type
		 */
		if (type.isConst())
		{	storage_class |= STC.STCconst;
		if (type.isShared())
			storage_class |= STC.STCshared;
		}
		else if (type.isImmutable())
		storage_class |= STC.STCimmutable;
		else if (type.isShared())
		storage_class |= STC.STCshared;
        else if (type.isWild())
	    storage_class |= STC.STCwild;

		if (isSynchronized())
		{
		error("variable %s cannot be synchronized", toChars());
		}
		else if (isOverride())
		{
		error("override cannot be applied to variable");
		}
		else if (isAbstract())
		{
		error("abstract cannot be applied to variable");
		}
		else if (storage_class & STC.STCfinal)
		{
		error("final cannot be applied to variable");
		}

		if (storage_class & (STC.STCstatic | STC.STCextern | STC.STCmanifest | STC.STCtemplateparameter | STC.STCtls | STC.STCgshared))
		{
		}
		else
		{
		AggregateDeclaration aad = sc.anonAgg;
		if (!aad)
			aad = parent.isAggregateDeclaration();
		if (aad)
		{
///version (DMDV2) {
			assert(!(storage_class & (STC.STCextern | STC.STCstatic | STC.STCtls | STC.STCgshared)));

			if (storage_class & (STC.STCconst | STC.STCimmutable) && init)
			{
			if (!type.toBasetype().isTypeBasic())
				storage_class |= STC.STCstatic;
			}
			else
///}
			aad.addField(sc, this);
		}

		InterfaceDeclaration id = parent.isInterfaceDeclaration();
		if (id)
		{
			error("field not allowed in interface");
		}

		/* Templates cannot add fields to aggregates
		 */
		TemplateInstance ti = parent.isTemplateInstance();
		if (ti)
		{
			// Take care of nested templates
			while (1)
			{
			TemplateInstance ti2 = ti.tempdecl.parent.isTemplateInstance();
			if (!ti2)
				break;
			ti = ti2;
			}

			// If it's a member template
			AggregateDeclaration ad = ti.tempdecl.isMember();
			if (ad && storage_class != STC.STCundefined)
			{
			error("cannot use template to add field to aggregate '%s'", ad.toChars());
			}
		}
		}

version (DMDV2) {
		if ((storage_class & (STC.STCref | STC.STCparameter | STC.STCforeach)) == STC.STCref && ident != Id.This)
		{
			error("only parameters or foreach declarations can be ref");
		}

        if ((storage_class & (STCstatic | STCextern | STCtls | STCgshared | STCmanifest) ||
	        isDataseg()) &&
	        type.hasWild())
        {
	        error("only fields, parameters or stack based variables can be inout");
        }
}

		if (type.isauto() && !noauto)
		{
			if (storage_class & (STC.STCfield | STC.STCout | STC.STCref | STC.STCstatic | STC.STCmanifest | STC.STCtls | STC.STCgshared) || !fd)
			{
				error("globals, statics, fields, manifest constants, ref and out parameters cannot be scope");
			}

			if (!(storage_class & (STC.STCauto | STC.STCscope)))
			{
				if (!(storage_class & STC.STCparameter) && ident != Id.withSym)
				error("reference to scope class must be scope");
			}
		}

		if ((isConst() || isImmutable()) && !init && !fd)
		{
			// Initialize by constructor only
			storage_class |= STC.STCctorinit;
		}

		if (init)
			storage_class |= STC.STCinit;     // remember we had an explicit initializer
		else if (storage_class & STC.STCmanifest)
			error("manifest constants must have initializers");

		TOK op = TOK.TOKconstruct;
		if (!init && !sc.inunion && !isStatic() && fd &&
		(!(storage_class & (STC.STCfield | STC.STCin | STC.STCforeach | STC.STCparameter)) || (storage_class & STC.STCout)) &&
		type.size() != 0)
		{
			// Provide a default initializer
			//printf("Providing default initializer for '%s'\n", toChars());
			if (type.ty == TY.Tstruct &&
				(cast(TypeStruct)type).sym.zeroInit)
			{   /* If a struct is all zeros, as a special case
				 * set it's initializer to the integer 0.
				 * In AssignExp.toElem(), we check for this and issue
				 * a memset() to initialize the struct.
				 * Must do same check in interpreter.
				 */
				Expression e = new IntegerExp(loc, 0, Type.tint32);
				Expression e1;
				e1 = new VarExp(loc, this);
				e = new AssignExp(loc, e1, e);
				e.op = TOK.TOKconstruct;
				e.type = e1.type;		// don't type check this, it would fail
				init = new ExpInitializer(loc, e);
				return;
			}
			else if (type.ty == TY.Ttypedef)
			{   
				TypeTypedef td = cast(TypeTypedef)type;
				if (td.sym.init)
				{	
					init = td.sym.init;
					ExpInitializer ie = init.isExpInitializer();
					if (ie)
						// Make copy so we can modify it
						init = new ExpInitializer(ie.loc, ie.exp);
				}
				else
					init = getExpInitializer();
			}
			else
			{
				init = getExpInitializer();
			}
			// Default initializer is always a blit
			op = TOK.TOKblit;
		}

		if (init)
		{
			sc = sc.push();
			sc.stc &= ~(STC.STC_TYPECTOR | STC.STCpure | STC.STCnothrow | STC.STCref | STCdisable);

			ArrayInitializer ai = init.isArrayInitializer();
			if (ai && tb.ty == TY.Taarray)
			{
				Expression e = ai.toAssocArrayLiteral();
				init = new ExpInitializer(e.loc, e);
			}

			StructInitializer si = init.isStructInitializer();
			ExpInitializer ei = init.isExpInitializer();

			// See if initializer is a NewExp that can be allocated on the stack
			if (ei && isScope() && ei.exp.op == TOK.TOKnew)
			{   NewExp ne = cast(NewExp)ei.exp;
				if (!(ne.newargs && ne.newargs.dim))
				{	ne.onstack = 1;
				onstack = 1;
				if (type.isBaseOf(ne.newtype.semantic(loc, sc), null))
					onstack = 2;
				}
			}

			// If inside function, there is no semantic3() call
			if (sc.func)
			{
				// If local variable, use AssignExp to handle all the various
				// possibilities.
				if (fd &&
				!(storage_class & (STC.STCmanifest | STC.STCstatic | STC.STCtls | STC.STCgshared | STC.STCextern)) &&
				!init.isVoidInitializer())
				{
				//printf("fd = '%s', var = '%s'\n", fd.toChars(), toChars());
				if (!ei)
				{
					Expression e = init.toExpression();
					if (!e)
					{
					init = init.semantic(sc, type);
					e = init.toExpression();
					if (!e)
					{   error("is not a static and cannot have static initializer");
						return;
					}
					}
					ei = new ExpInitializer(init.loc, e);
					init = ei;
				}

				Expression e1 = new VarExp(loc, this);

				Type t = type.toBasetype();
				if (t.ty == TY.Tsarray && !(storage_class & (STC.STCref | STC.STCout)))
				{
					ei.exp = ei.exp.semantic(sc);
					if (!ei.exp.implicitConvTo(type))
					{
					int dim = cast(int)(cast(TypeSArray)t).dim.toInteger();	///
					// If multidimensional static array, treat as one large array
					while (1)
					{
						t = t.nextOf().toBasetype();
						if (t.ty != TY.Tsarray)
							break;
						dim *= (cast(TypeSArray)t).dim.toInteger();
						e1.type = new TypeSArray(t.nextOf(), new IntegerExp(Loc(0), dim, Type.tindex));
					}
					}
					e1 = new SliceExp(loc, e1, null, null);
				}
				else if (t.ty == TY.Tstruct)
				{
					ei.exp = ei.exp.semantic(sc);
					ei.exp = resolveProperties(sc, ei.exp);
					StructDeclaration sd = (cast(TypeStruct)t).sym;
	version (DMDV2)
	{
					/* Look to see if initializer is a call to the constructor
					 */
					if (sd.ctor &&		// there are constructors
					ei.exp.type.ty == TY.Tstruct &&	// rvalue is the same struct
					(cast(TypeStruct)ei.exp.type).sym == sd &&
					ei.exp.op == TOK.TOKstar)
					{
					/* Look for form of constructor call which is:
					 *    *__ctmp.ctor(arguments...)
					 */
					PtrExp pe = cast(PtrExp)ei.exp;
					if (pe.e1.op == TOK.TOKcall)
					{   CallExp ce = cast(CallExp)pe.e1;
						if (ce.e1.op == TOK.TOKdotvar)
						{	DotVarExp dve = cast(DotVarExp)ce.e1;
						if (dve.var.isCtorDeclaration())
						{   /* It's a constructor call, currently constructing
							 * a temporary __ctmp.
							 */
							/* Before calling the constructor, initialize
							 * variable with a bit copy of the default
							 * initializer
							 */
							Expression e = new AssignExp(loc, new VarExp(loc, this), t.defaultInit(loc));
							e.op = TOK.TOKblit;
							e.type = t;
							ei.exp = new CommaExp(loc, e, ei.exp);

							/* Replace __ctmp being constructed with e1
							 */
							dve.e1 = e1;
							return;
						}
						}
					}
					}
	}
					if (!ei.exp.implicitConvTo(type))
					{
						Type ti = ei.exp.type.toBasetype();
						// Look for constructor first
						if (sd.ctor &&
							/* Initializing with the same type is done differently
							 */
							!(ti.ty == Tstruct && t.toDsymbol(sc) == ti.toDsymbol(sc)))
						{
						   // Rewrite as e1.ctor(arguments)
							Expression ector = new DotIdExp(loc, e1, Id.ctor);
							ei.exp = new CallExp(loc, ector, ei.exp);
						} 
						else
						/* Look for opCall
						 * See bugzilla 2702 for more discussion
						 */

						// Don't cast away invariant or mutability in initializer
						if (search_function(sd, Id.call) &&
							/* Initializing with the same type is done differently
							 */
							!(ti.ty == Tstruct && t.toDsymbol(sc) == ti.toDsymbol(sc)))
						{   // Rewrite as e1.call(arguments)
							Expression eCall = new DotIdExp(loc, e1, Id.call);
							ei.exp = new CallExp(loc, eCall, ei.exp);
						}
					}
				}
				ei.exp = new AssignExp(loc, e1, ei.exp);
				ei.exp.op = op;
				canassign++;
				ei.exp = ei.exp.semantic(sc);
				canassign--;
				ei.exp.optimize(WANT.WANTvalue);
				}
				else
				{
				init = init.semantic(sc, type);
				}
			}
			else if (storage_class & (STC.STCconst | STC.STCimmutable | STC.STCmanifest) ||
				type.isConst() || type.isImmutable() ||
				parent.isAggregateDeclaration())
			{
				/* Because we may need the results of a const declaration in a
				 * subsequent type, such as an array dimension, before semantic2()
				 * gets ordinarily run, try to run semantic2() now.
				 * Ignore failure.
				 */

				if (!global.errors && !inferred)
				{
					uint errors = global.errors;
					global.gag++;
					//printf("+gag\n");
					Expression e;
					Initializer i2 = init;
					inuse++;
					if (ei)
					{
						e = ei.exp.syntaxCopy();
						e = e.semantic(sc);
						e = resolveProperties(sc, e);
version (DMDV2) {
					/* The problem is the following code:
					 *	struct CopyTest {
					 *	   double x;
					 *	   this(double a) { x = a * 10.0;}
					 *	   this(this) { x += 2.0; }
					 *	}
					 *	const CopyTest z = CopyTest(5.3);  // ok
					 *	const CopyTest w = z;              // not ok, postblit not run
					 *	static assert(w.x == 55.0);
					 * because the postblit doesn't get run on the initialization of w.
					 */

					Type tb_ = e.type.toBasetype();
					if (tb_.ty == Tstruct)
					{	
						StructDeclaration sd = (cast(TypeStruct)tb_).sym;
						Type typeb = type.toBasetype();
						/* Look to see if initializer involves a copy constructor
						 * (which implies a postblit)
						 */
						if (sd.cpctor &&		// there is a copy constructor
							typeb.equals(tb_))		// rvalue is the same struct
						{
							// The only allowable initializer is a (non-copy) constructor
							if (e.op == TOKcall)
							{
							CallExp ce = cast(CallExp)e;
							if (ce.e1.op == TOKdotvar)
							{
								DotVarExp dve = cast(DotVarExp)ce.e1;
								if (dve.var.isCtorDeclaration())
									goto LNoCopyConstruction;
							}
							}
							global.gag--;
							error("of type struct %s uses this(this), which is not allowed in static initialization", typeb.toChars());
							global.gag++;

						  LNoCopyConstruction:
							;
						}
					}
}
						e = e.implicitCastTo(sc, type);
					}
					else if (si || ai)
					{   
						i2 = init.syntaxCopy();
						i2 = i2.semantic(sc, type);
					}
					inuse--;
					global.gag--;
					//printf("-gag\n");
					if (errors != global.errors)	// if errors happened
					{
						if (global.gag == 0)
							global.errors = errors;	// act as if nothing happened
version (DMDV2) {
						/* Save scope for later use, to try again
						 */
						scope_ = sc.clone();
						scope_.setNoFree();
}
					}
					else if (ei)
					{
						if (isDataseg())
							/* static const/invariant does CTFE
							 */
							e = e.optimize(WANT.WANTvalue | WANT.WANTinterpret);
						else
							e = e.optimize(WANT.WANTvalue);
						if (e.op == TOK.TOKint64 || e.op == TOK.TOKstring || e.op == TOK.TOKfloat64)
						{
							ei.exp = e;		// no errors, keep result
						}
///version (DMDV2) {
						else
						{
							/* Save scope for later use, to try again
							 */
							scope_ = sc.clone();
							scope_.setNoFree();
						}
///}
					}
					else
						init = i2;		// no errors, keep result
				}
			}
			sc = sc.pop();
		}
	}

    override void semantic2(Scope sc)
	{
		//printf("VarDeclaration.semantic2('%s')\n", toChars());
		if (init && !toParent().isFuncDeclaration())
		{	
			inuse++;
static if (false) {
			ExpInitializer ei = init.isExpInitializer();
			if (ei)
			{
				ei.exp.dump(0);
				printf("type = %p\n", ei.exp.type);
			}
}
			init = init.semantic(sc, type);
			inuse--;
		}
	}

    override string kind()
	{
		return "variable";
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		StorageClassDeclaration.stcToCBuffer(buf, storage_class);

		/* If changing, be sure and fix CompoundDeclarationStatement.toCBuffer()
		 * too.
		 */
		if (type)
			type.toCBuffer(buf, ident, hgs);
		else
			buf.writestring(ident.toChars());
		if (init)
		{	
			buf.writestring(" = ");
///version (DMDV2) {
			ExpInitializer ie = init.isExpInitializer();
			if (ie && (ie.exp.op == TOKconstruct || ie.exp.op == TOKblit))
				(cast(AssignExp)ie.exp).e2.toCBuffer(buf, hgs);
			else
///}
				init.toCBuffer(buf, hgs);
		}
		buf.writeByte(';');
		buf.writenl();
	}
	
version (_DH) {
    Type htype;
    Initializer hinit;
}
    override bool needThis()
	{
		//printf("VarDeclaration.needThis(%s, x%x)\n", toChars(), storage_class);
		return (storage_class & STC.STCfield) != 0;
	}
	
    override bool isImportedSymbol()
	{
		if (protection == PROT.PROTexport && !init && (storage_class & STC.STCstatic || parent.isModule()))
			return true;

		return false;
	}

    override bool isDataseg()
	{
static if (false) {
		printf("VarDeclaration.isDataseg(%p, '%s')\n", this, toChars());
		printf("%llx, isModule: %p, isTemplateInstance: %p\n", storage_class & (STC.STCstatic | STC.STCconst), parent.isModule(), parent.isTemplateInstance());
		printf("parent = '%s'\n", parent.toChars());
}
		if (storage_class & STC.STCmanifest)
			return false;

		Dsymbol parent = this.toParent();
		if (!parent && !(storage_class & STC.STCstatic))
		{	
			error("forward referenced");
			type = Type.terror;
			return false;
		}

		return canTakeAddressOf() && (storage_class & (STC.STCstatic | STC.STCextern | STC.STCtls | STC.STCgshared) || toParent().isModule() || toParent().isTemplateInstance());
	}
	
    override bool isThreadlocal()
	{
		//printf("VarDeclaration.isThreadlocal(%p, '%s')\n", this, toChars());
static if (false) { /// || TARGET_OSX
		/* To be thread-local, must use the __thread storage class.
		 * BUG: OSX doesn't support thread local yet.
		 */
		return isDataseg() && (storage_class & (STC.STCtls | STC.STCconst | STC.STCimmutable | STC.STCshared | STC.STCgshared)) == STC.STCtls;
} else {
		/* Data defaults to being thread-local. It is not thread-local
		 * if it is immutable, const or shared.
		 */
		bool i = isDataseg() && !(storage_class & (STC.STCimmutable | STC.STCconst | STC.STCshared | STC.STCgshared));
		//printf("\treturn %d\n", i);
		return i;
}
	}
	
    /********************************************
     * Can variable be read and written by CTFE?
     */

    int isCTFE()
    {
        return (storage_class & STCctfe) || !isDataseg();
    }

    override bool hasPointers()
	{
		//printf("VarDeclaration.hasPointers() %s, ty = %d\n", toChars(), type.ty);
		return (!isDataseg() && type.hasPointers());
	}
	
version (DMDV2) {
    bool canTakeAddressOf()
	{
static if (false) {
		/* Global variables and struct/class fields of the form:
		 *	const int x = 3;
		 * are not stored and hence cannot have their address taken.
		 */
		if ((isConst() || isImmutable()) && (storage_class & STC.STCinit) && (!(storage_class & (STC.STCstatic | STC.STCextern)) || (storage_class & STC.STCfield)) &&
			(!parent || toParent().isModule() || toParent().isTemplateInstance()) && type.toBasetype().isTypeBasic())
		{
			return false;
		}
} else {
		if (storage_class & STC.STCmanifest)
			return false;
}
		return true;
	}
	
	/******************************************
	 * Return TRUE if variable needs to call the destructor.
	 */
    bool needsAutoDtor()
	{
		//printf("VarDeclaration.needsAutoDtor() %s\n", toChars());

		if (noauto || storage_class & STCnodtor)
			return false;

		// Destructors for structs and arrays of structs
		Type tv = type.toBasetype();
		while (tv.ty == Tsarray)
		{   
			TypeSArray ta = cast(TypeSArray)tv;
			tv = tv.nextOf().toBasetype();
		}
		if (tv.ty == Tstruct)
		{   
			TypeStruct ts = cast(TypeStruct)tv;
			StructDeclaration sd = ts.sym;
			if (sd.dtor)
				return true;
		}

		// Destructors for classes
		if (storage_class & (STCauto | STCscope))
		{
			if (type.isClassHandle())
				return true;
		}
		return false;
	}
}

	/******************************************
	 * If a variable has an auto destructor call, return call for it.
	 * Otherwise, return null.
	 */
    Expression callAutoDtor(Scope sc)
	{
		Expression e = null;

		//printf("VarDeclaration.callAutoDtor() %s\n", toChars());

		if (noauto || storage_class & STC.STCnodtor)
			return null;

		// Destructors for structs and arrays of structs
		bool array = false;
		Type tv = type.toBasetype();
		while (tv.ty == TY.Tsarray)
		{   
			TypeSArray ta = cast(TypeSArray)tv;
			array = true;
			tv = tv.nextOf().toBasetype();
		}
		if (tv.ty == TY.Tstruct)
		{   
			TypeStruct ts = cast(TypeStruct)tv;
			StructDeclaration sd = ts.sym;
			if (sd.dtor)
			{
				if (array)
				{
					// Typeinfo.destroy(cast(void*)&v);
					Expression ea = new SymOffExp(loc, this, 0, 0);
					ea = new CastExp(loc, ea, Type.tvoid.pointerTo());
					Expressions args = new Expressions();
					args.push(ea);

					Expression et = type.getTypeInfo(sc);
					et = new DotIdExp(loc, et, Id.destroy);

					e = new CallExp(loc, et, args);
				}
				else
				{
					e = new VarExp(loc, this);
					e = new DotVarExp(loc, e, sd.dtor, 0);
					e = new CallExp(loc, e);
				}
				return e;
			}
		}

		// Destructors for classes
		if (storage_class & (STC.STCauto | STC.STCscope))
		{
			for (ClassDeclaration cd = type.isClassHandle(); cd; cd = cd.baseClass)
			{
				/* We can do better if there's a way with onstack
				 * classes to determine if there's no way the monitor
				 * could be set.
				 */
				//if (cd.isInterfaceDeclaration())
				//error("interface %s cannot be scope", cd.toChars());
				if (1 || onstack || cd.dtors.dim)	// if any destructors
				{
					// delete this;
					Expression ec = new VarExp(loc, this);
					e = new DeleteExp(loc, ec);
					e.type = Type.tvoid;
					break;
				}
			}
		}
		return e;
	}

	/****************************
	 * Get ExpInitializer for a variable, if there is one.
	 */
    ExpInitializer getExpInitializer()
	{
		ExpInitializer ei;

		if (init)
			ei = init.isExpInitializer();
		else
		{
			Expression e = type.defaultInit(loc);
			if (e)
				ei = new ExpInitializer(loc, e);
			else
				ei = null;
		}
		return ei;
	}

	/*******************************************
	 * If variable has a constant expression initializer, get it.
	 * Otherwise, return null.
	 */
    Expression getConstInitializer()
	{
		if ((isConst() || isImmutable() || storage_class & STC.STCmanifest) && storage_class & STC.STCinit)
		{
			ExpInitializer ei = getExpInitializer();
			if (ei)
				return ei.exp;
		}

		return null;
	}

    override void checkCtorConstInit()
	{
	static if (false) { /* doesn't work if more than one static ctor */
		if (ctorinit == 0 && isCtorinit() && !(storage_class & STCfield))
			error("missing initializer in static constructor for const variable");
	}
	}

	/************************************
	 * Check to see if this variable is actually in an enclosing function
	 * rather than the current one.
	 */
    void checkNestedReference(Scope sc, Loc loc)
	{
		if (parent && !isDataseg() && parent != sc.parent && !(storage_class & STC.STCmanifest))
		{
			// The function that this variable is in
			FuncDeclaration fdv = toParent().isFuncDeclaration();
			// The current function
			FuncDeclaration fdthis = sc.parent.isFuncDeclaration();

			if (fdv && fdthis && fdv !is fdthis)
			{
				if (loc.filename)
					fdthis.getLevel(loc, fdv);

				foreach (f; nestedrefs)
				{	
					if (f == fdthis)
						goto L1;
				}
				nestedrefs.push(fdthis);
			  L1: ;

				foreach (s; fdv.closureVars)
				{	
					if (s == this)
						goto L2;
				}

				fdv.closureVars.push(this);
			  L2: ;

				//printf("fdthis is %s\n", fdthis.toChars());
				//printf("var %s in function %s is nested ref\n", toChars(), fdv.toChars());
			}
		}
	}

    override Dsymbol toAlias()
	{
		//printf("VarDeclaration::toAlias('%s', this = %p, aliassym = %p)\n", toChars(), this, aliassym);
		assert(this !is aliassym);
		return aliassym ? aliassym.toAlias() : this;
	}

    override Symbol* toSymbol()
	{
		//printf("VarDeclaration.toSymbol(%s)\n", toChars());
		//if (needThis()) *(char*)0=0;
		assert(!needThis());
		if (!csym)
		{	
			Symbol* s;
			TYPE* t;
			string id;

			if (isDataseg())
				id = mangle();
			else
				id = ident.toChars();

			s = symbol_calloc(toStringz(id));

			if (storage_class & (STC.STCout | STC.STCref))
			{
				if (global.params.symdebug && storage_class & STC.STCparameter)
				{
					t = type_alloc(TYM.TYnptr);		// should be TYref, but problems in back end
					t.Tnext = type.toCtype();
					t.Tnext.Tcount++;
				}
				else
					t = type_fake(TYM.TYnptr);
			}
			else if (storage_class & STC.STClazy)
				t = type_fake(TYM.TYdelegate);		// Tdelegate as C type
			else if (isParameter())
				t = type.toCParamtype();
			else
				t = type.toCtype();

			t.Tcount++;

			if (isDataseg())
			{
				if (isThreadlocal())
				{	
					/* Thread local storage
					 */
					TYPE* ts = t;
					ts.Tcount++;	// make sure a different t is allocated
					type_setty(&t, t.Tty | mTY.mTYthread);
					ts.Tcount--;

					if (global.params.vtls)
					{
						string p = loc.toChars();
						writef("%s: %s is thread local\n", p ? p : "", toChars());
					}
				}

				s.Sclass = SC.SCextern;
				s.Sfl = FL.FLextern;
				slist_add(s);
			}
			else
			{
				s.Sclass = SC.SCauto;
				s.Sfl = FL.FLauto;

				if (nestedrefs.dim)
				{
					/* Symbol is accessed by a nested function. Make sure
					 * it is not put in a register, and that the optimizer
					 * assumes it is modified across function calls and pointer
					 * dereferences.
					 */
					//printf("\tnested ref, not register\n");
					type_setcv(&t, t.Tty | mTY.mTYvolatile);
				}
			}

			mangle_t m = 0;
			switch (linkage)
			{
				case LINK.LINKwindows:
					m = mTYman.mTYman_std;
					break;

				case LINK.LINKpascal:
					m = mTYman.mTYman_pas;
					break;

				case LINK.LINKc:
					m = mTYman.mTYman_c;
					break;

				case LINK.LINKd:
					m = mTYman.mTYman_d;
					break;

				case LINK.LINKcpp:
					m = mTYman.mTYman_cpp;
					break;

				default:
					writef("linkage = %d\n", linkage);
					assert(0);
			}
			type_setmangle(&t, m);
			s.Stype = t;

			csym = s;
		}
		return csym;
	}

    override void toObjFile(int multiobj)			// compile to .obj file
	{
		Symbol* s;
		uint sz;
		Dsymbol parent;

		//printf("VarDeclaration.toObjFile(%p '%s' type=%s) protection %d\n", this, toChars(), type.toChars(), protection);
		//printf("\talign = %d\n", type.alignsize());

		if (aliassym)
		{	
			toAlias().toObjFile(0);
			return;
		}

	version (DMDV2) {
		// Do not store variables we cannot take the address of
		if (!canTakeAddressOf())
		{
			return;
		}
	}

		if (isDataseg() && !(storage_class & STC.STCextern))
		{
			s = toSymbol();
			sz = cast(uint)type.size();

			parent = this.toParent();
///		version (DMDV1) {	/* private statics should still get a global symbol, in case
///			 * another module inlines a function that references it.
///			 */
///			if (/*protection == PROT.PROTprivate ||*/
///				!parent || parent.ident == null || parent.isFuncDeclaration())
///			{
///				s.Sclass = SC.SCstatic;
///			}
///			else
///		}
			{
				if (storage_class & STC.STCcomdat)
					s.Sclass = SC.SCcomdat;
				else
					s.Sclass = SC.SCglobal;

				do
				{
					/* Global template data members need to be in comdat's
					 * in case multiple .obj files instantiate the same
					 * template with the same types.
					 */
					if (parent.isTemplateInstance() && !parent.isTemplateMixin())
					{
		version (DMDV1) {
						/* These symbol constants have already been copied,
						 * so no reason to output them.
						 * Note that currently there is no way to take
						 * the address of such a const.
						 */
						if (isConst() && type.toBasetype().ty != TY.Tsarray && init && init.isExpInitializer())
							return;
		}
						s.Sclass = SC.SCcomdat;
						break;
					}
					parent = parent.parent;
				} while (parent);
			}

			s.Sfl = FL.FLdata;

			if (init)
			{   
				s.Sdt = init.toDt();

				// Look for static array that is block initialized
				Type tb;
				ExpInitializer ie = init.isExpInitializer();

				tb = type.toBasetype();
				if (tb.ty == TY.Tsarray && ie
					&& !tb.nextOf().equals(ie.exp.type.toBasetype().nextOf())
					&& ie.exp.implicitConvTo(tb.nextOf()))
				{
					int dim = cast(int)(cast(TypeSArray)tb).dim.toInteger();

					// Duplicate Sdt 'dim-1' times, as we already have the first one
					while (--dim > 0)
					{
						ie.exp.toDt(&s.Sdt);
					}
				}
			}
			else if (storage_class & STC.STCextern)
			{
				s.Sclass = SC.SCextern;
				s.Sfl = FL.FLextern;
				s.Sdt = null;
				// BUG: if isExport(), shouldn't we make it dllimport?
				return;
			}
			else
			{
				type.toDt(&s.Sdt);
			}
			dt_optimize(s.Sdt);

			// See if we can convert a comdat to a comdef,
			// which saves on exe file space.
			if (s.Sclass == SC.SCcomdat &&
				s.Sdt &&
				s.Sdt.dt == DT.DT_azeros &&
				s.Sdt.DTnext is null &&
				!isThreadlocal())
			{
				s.Sclass = SC.SCglobal;
				s.Sdt.dt = DT.DT_common;
			}

		version (ELFOBJ_OR_MACHOBJ) { // Burton
			if (s.Sdt && s.Sdt.dt == DT.DT_azeros && s.Sdt.DTnext is null)
				s.Sseg = Segment.UDATA;
			else
				s.Sseg = Segment.DATA;
		}
			if (sz)
			{   
				outdata(s);
				if (isExport())
					obj_export(s, 0);
			}
		}
	}

    override int cvMember(ubyte* p)
	{
		assert(false);
	}

    // Eliminate need for dynamic_cast
    override VarDeclaration isVarDeclaration() { return this; }
}

alias Vector!VarDeclaration VarDeclarations;