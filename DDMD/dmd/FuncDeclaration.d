module dmd.FuncDeclaration;

import dmd.common;
import dmd.Declaration;
import dmd.DotIdExp;
import dmd.AddrExp;
import dmd.TryFinallyStatement;
import dmd.TryCatchStatement;
import dmd.SharedStaticDtorDeclaration;
import dmd.Catch;
import dmd.DeclarationStatement;
import dmd.StaticDtorDeclaration;
import dmd.GlobalExpressions;
import dmd.PeelStatement;
import dmd.SynchronizedStatement;
import dmd.TOK;
import dmd.SymOffExp;
import dmd.AssignExp;
import dmd.ExpInitializer;
import dmd.BE;
import dmd.Id;
import dmd.StorageClassDeclaration;
import dmd.StringExp;
import dmd.PASS;
import dmd.DsymbolExp;
import dmd.HaltExp;
import dmd.CommaExp;
import dmd.ReturnStatement;
import dmd.IntegerExp;
import dmd.ExpStatement;
import dmd.CSX;
import dmd.PROT;
import dmd.CompoundStatement;
import dmd.LabelStatement;
import dmd.ThisExp;
import dmd.SuperExp;
import dmd.IdentifierExp;
import dmd.AssertExp;
import dmd.CallExp;
import dmd.RET;
import dmd.VarExp;
import dmd.TupleDeclaration;
import dmd.ThisDeclaration;
import dmd.TypeTuple;
import dmd.TemplateInstance;
import dmd.ScopeDsymbol;
import dmd.AliasDeclaration;
import dmd.MOD;
import dmd.PROT;
import dmd.Lexer;
import dmd.LINK;
import dmd.CtorDeclaration;
import dmd.Global;
import dmd.DtorDeclaration;
import dmd.InvariantDeclaration;
import dmd.TY;
import dmd.PtrExp;
import dmd.DeclarationExp;
import dmd.InlineDoState;
import dmd.Parameter;
import dmd.StructDeclaration;
import dmd.ClassDeclaration;
import dmd.InterfaceDeclaration;
import dmd.Array;
import dmd.Statement;
import dmd.Identifier;
import dmd.VarDeclaration;
import dmd.LabelDsymbol;
import dmd.DsymbolTable;
import dmd.ArrayTypes;
import dmd.Loc;
import dmd.ILS;
import dmd.ForeachStatement;
import dmd.Type;
import dmd.BUILTIN;
import dmd.TypeFunction;
import dmd.Expression;
import dmd.STC;
import dmd.TRUST;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.MATCH;
import dmd.AggregateDeclaration;
import dmd.InterState;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.Util;
import dmd.BaseClass;
import dmd.Module;
import dmd.InlineCostState;

import dmd.expression.Util;

import dmd.declaration.Match;

import dmd.backend.Symbol;
import dmd.backend.func_t;
import dmd.backend.Util;
import dmd.backend.glue;
import dmd.backend.SC;
import dmd.backend.F;
import dmd.backend.Cstate;
import dmd.backend.TYM;
import dmd.backend.OPER;
import dmd.backend.TYFL;
import dmd.backend.TYPE;
import dmd.backend.SFL;
import dmd.backend.mTY;
import dmd.backend.FL;
import dmd.backend.REG;
import dmd.backend.block;
import dmd.backend.Blockx;
import dmd.backend.Config;
import dmd.backend.BC;
import dmd.backend.elem;
import dmd.backend.targ_types;
import dmd.backend.mTYman;
import dmd.backend.RTLSYM;
import dmd.backend.LIST;

import dmd.DDMDExtensions;

import core.stdc.stdio;
import core.stdc.string;
version (Bug4054) import core.memory;

import dmd.interpret.Util;

import std.string;

class FuncDeclaration : Declaration
{
	mixin insertMemberExtension!(typeof(this));
	
    Array fthrows;			// Array of Type's of exceptions (not used)
    Statement frequire;
    Statement fensure;
    Statement fbody;

    FuncDeclarations foverrides;	// functions this function overrides
    FuncDeclaration fdrequire;		// function that does the in contract
    FuncDeclaration fdensure;		// function that does the out contract

    Identifier outId;			// identifier for out statement
    VarDeclaration vresult;		// variable corresponding to outId
    LabelDsymbol returnLabel;		// where the return goes

    DsymbolTable localsymtab;		// used to prevent symbols in different
					// scopes from having the same name
    VarDeclaration vthis;		// 'this' parameter (member and nested)
    VarDeclaration v_arguments;	// '_arguments' parameter
version (IN_GCC) {
    VarDeclaration v_argptr;	        // '_argptr' variable
}
    Dsymbols parameters;		// Array of VarDeclaration's for parameters
    DsymbolTable labtab;		// statement label symbol table
    Declaration overnext;		// next in overload list
    Loc endloc;					// location of closing curly bracket
    int vtblIndex;				// for member functions, index into vtbl[]
    int naked;					// !=0 if naked
    int inlineAsm;				// !=0 if has inline assembler
    ILS inlineStatus;
    int inlineNest;				// !=0 if nested inline
    int cantInterpret;			// !=0 if cannot interpret function
    PASS semanticRun;
								// this function's frame ptr
    ForeachStatement fes;		// if foreach body, this is the foreach
    int introducing;			// !=0 if 'introducing' function
    Type tintro;			// if !=null, then this is the type
					// of the 'introducing' function
					// this one is overriding
    int inferRetType;			// !=0 if return type is to be inferred

    // Things that should really go into Scope
    int hasReturnExp;			// 1 if there's a return exp; statement
					// 2 if there's a throw statement
					// 4 if there's an assert(0)
					// 8 if there's inline asm

    // Support for NRVO (named return value optimization)
    bool nrvo_can = true;			// !=0 means we can do it
    VarDeclaration nrvo_var;		// variable to replace with shidden
    Symbol* shidden;			// hidden pointer passed to function

version (DMDV2) {
    BUILTIN builtin;		// set if this is a known, builtin
					// function we can evaluate at compile
					// time

    int tookAddressOf;			// set if someone took the address of
					// this function
    Dsymbols closureVars;		// local variables in this function
					// which are referenced by nested
					// functions
} else {
    int nestedFrameRef;			// !=0 if nested variables referenced
}

    this(Loc loc, Loc endloc, Identifier id, StorageClass storage_class, Type type)
	{
		register();
		super(id);

		//printf("FuncDeclaration(id = '%s', type = %p)\n", id.toChars(), type);
		//printf("storage_class = x%x\n", storage_class);
		this.storage_class = storage_class;
		this.type = type;
		this.loc = loc;
		this.endloc = endloc;
		fthrows = null;
		frequire = null;
		fdrequire = null;
		fdensure = null;
		outId = null;
		vresult = null;
		returnLabel = null;
		fensure = null;
		fbody = null;
		localsymtab = null;
		vthis = null;
		v_arguments = null;
version (IN_GCC) {
		v_argptr = null;
}
		parameters = null;
		labtab = null;
		overnext = null;
		vtblIndex = -1;
		hasReturnExp = 0;
		naked = 0;
		inlineStatus = ILS.ILSuninitialized;
		inlineNest = 0;
		inlineAsm = 0;
		cantInterpret = 0;
		semanticRun = PASSinit;
version (DMDV1) {
		nestedFrameRef = 0;
}
		fes = null;
		introducing = 0;
		tintro = null;
		/* The type given for "infer the return type" is a TypeFunction with
		 * null for the return type.
		 */
		inferRetType = (type && type.nextOf() is null);
		hasReturnExp = 0;
		nrvo_can = 1;
		nrvo_var = null;
		shidden = null;
version (DMDV2) {
		builtin = BUILTINunknown;
		tookAddressOf = 0;
}
		foverrides = new FuncDeclarations();
		closureVars = new Dsymbols();
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		FuncDeclaration f;

		//printf("FuncDeclaration::syntaxCopy('%s')\n", toChars());
		if (s)
			f = cast(FuncDeclaration)s;
		else
			f = new FuncDeclaration(loc, endloc, ident, storage_class, type.syntaxCopy());

		f.outId = outId;
		f.frequire = frequire ? frequire.syntaxCopy() : null;
		f.fensure  = fensure  ? fensure.syntaxCopy()  : null;
		f.fbody    = fbody    ? fbody.syntaxCopy()    : null;
		assert(!fthrows); // deprecated

		return f;
	}

	// Do the semantic analysis on the external interface to the function.
    override void semantic(Scope sc)
	{
		TypeFunction f;
		StructDeclaration sd;
		ClassDeclaration cd;
		InterfaceDeclaration id;
		Dsymbol pd;

static if (false)
{
		printf("FuncDeclaration.semantic(sc = %p, this = %p, '%s', linkage = %d)\n", sc, this, toPrettyChars(), sc.linkage);
		if (isFuncLiteralDeclaration())
			printf("\tFuncLiteralDeclaration()\n");
		printf("sc.parent = %s, parent = %s\n", sc.parent.toChars(), parent ? parent.toChars() : "");
		printf("type: %p, %s\n", type, type.toChars());
}

		if (semanticRun != PASSinit && isFuncLiteralDeclaration())
		{
			/* Member functions that have return types that are
			 * forward references can have semantic() run more than
			 * once on them.
			 * See test\interface2.d, test20
			 */
			return;
		}
		
		parent = sc.parent;
		Dsymbol parent = toParent();
		
		if (semanticRun == PASSsemanticdone)
		{
			if (!parent.isClassDeclaration())
				return;
			// need to re-run semantic() in order to set the class's vtbl[]
		}
		else
		{
			assert(semanticRun <= PASSsemantic);
			semanticRun = PASSsemantic;
		}

		uint dprogress_save = global.dprogress;

		foverrides.setDim(0);	// reset in case semantic() is being retried for this function

		storage_class |= sc.stc & ~STC.STCref;
	    //printf("function storage_class = x%llx, sc->stc = x%llx\n", storage_class, sc->stc);

		if (!originalType)
			originalType = type;
		if (!type.deco)
		{
    	    sc = sc.push();
        	sc.stc |= storage_class & STCref;	// forward to function type
	        type = type.semantic(loc, sc);
	        sc = sc.pop();

			/* Apply const, immutable and shared storage class
			 * to the function type
			 */
			StorageClass stc = storage_class;
			if (type.isImmutable())
				stc |= STC.STCimmutable;
			if (type.isConst())
				stc |= STC.STCconst;
			if (type.isShared() || storage_class & STC.STCsynchronized)
				stc |= STC.STCshared;
	        if (type.isWild())
	            stc |= STC.STCwild;
			switch (stc & STC.STC_TYPECTOR)
			{
				case STC.STCimmutable:
				case STC.STCimmutable | STC.STCconst:
				case STC.STCimmutable | STC.STCconst | STC.STCshared:
				case STC.STCimmutable | STC.STCshared:
                case STC.STCimmutable | STC.STCwild:
	            case STC.STCimmutable | STC.STCconst | STC.STCwild:
	            case STC.STCimmutable | STC.STCconst | STC.STCshared | STC.STCwild:
	            case STC.STCimmutable | STC.STCshared | STC.STCwild:
				// Don't use toInvariant(), as that will do a merge()
				type = type.makeInvariant();
				goto Lmerge;

				case STC.STCconst:
	            case STC.STCconst | STC.STCwild:
				type = type.makeConst();
				goto Lmerge;

				case STC.STCshared | STC.STCconst:
	            case STC.STCshared | STC.STCconst | STC.STCwild:
				type = type.makeSharedConst();
				goto Lmerge;

				case STC.STCshared:
				type = type.makeShared();
		        goto Lmerge;

	            case STC.STCwild:
		        type = type.makeWild();
		        goto Lmerge;

	            case STC.STCshared | STC.STCwild:
		        type = type.makeSharedWild();
		        goto Lmerge;

				Lmerge:
					if (!(type.ty == Tfunction && !type.nextOf()))
						/* Can't do merge if return type is not known yet
					     */
						type.deco = type.merge().deco;
				break;

				case STC.STCundefined:
				break;

				default:
				assert(0);
			}
		}
        storage_class &= ~STC.STCref;
		if (type.ty != TY.Tfunction)
		{
		error("%s must be a function", toChars());
		return;
		}
		f = cast(TypeFunction)type;
		size_t nparams = Parameter.dim(f.parameters);

		linkage = sc.linkage;
		protection = sc.protection;

		if (storage_class & STC.STCscope)
		error("functions cannot be scope");

		if (isAbstract() && !isVirtual())
		error("non-virtual functions cannot be abstract");

		if ((f.isConst() || f.isImmutable()) && !isThis())
		error("without 'this' cannot be const/immutable");

		if (isAbstract() && isFinal())
		error("cannot be both final and abstract");
static if (false) {
		if (isAbstract() && fbody)
		error("abstract functions cannot have bodies");
}

static if (false) {
		if (isStaticConstructor() || isStaticDestructor())
		{
		if (!isStatic() || type.nextOf().ty != Tvoid)
			error("static constructors / destructors must be static void");
		if (f.arguments && f.arguments.dim)
			error("static constructors / destructors must have empty parameter list");
		// BUG: check for invalid storage classes
		}
}

version (IN_GCC) {
		AggregateDeclaration ad;

		ad = parent.isAggregateDeclaration();
		if (ad)
			ad.methods.push(cast(void*)this);
}
		sd = parent.isStructDeclaration();
		if (sd)
		{
		if (isCtorDeclaration())
		{
			goto Ldone;
		}
static if (false) {
		// Verify no constructors, destructors, etc.
		if (isCtorDeclaration()
			//||isDtorDeclaration()
			//|| isInvariantDeclaration()
			//|| isUnitTestDeclaration()
		   )
		{
			error("special member functions not allowed for %ss", sd.kind());
		}

		if (!sd.inv)
			sd.inv = isInvariantDeclaration();

		if (!sd.aggNew)
			sd.aggNew = isNewDeclaration();

		if (isDelete())
		{
			if (sd.aggDelete)
			error("multiple delete's for struct %s", sd.toChars());
			sd.aggDelete = cast(DeleteDeclaration)this;
		}
}
		}

		id = parent.isInterfaceDeclaration();
		if (id)
		{
		storage_class |= STC.STCabstract;

		if (isCtorDeclaration() ||
///static if (DMDV2) {
			isPostBlitDeclaration() ||
///}
			isDtorDeclaration() ||
			isInvariantDeclaration() ||
			isUnitTestDeclaration() || isNewDeclaration() || isDelete())
			error("special function not allowed in interface %s", id.toChars());
		if (fbody && isVirtual())
			error("function body is not abstract in interface %s", id.toChars());
		}

		/* Template member functions aren't virtual:
		 *   interface TestInterface { void tpl(T)(); }
		 * and so won't work in interfaces
		 */
		if ((pd = toParent()) !is null &&
		pd.isTemplateInstance() &&
		(pd = toParent2()) !is null &&
		(id = pd.isInterfaceDeclaration()) !is null)
		{
		error("template member function not allowed in interface %s", id.toChars());
		}

		cd = parent.isClassDeclaration();
		if (cd)
		{	int vi;
		CtorDeclaration ctor;
		DtorDeclaration dtor;
		InvariantDeclaration inv;

		if (isCtorDeclaration())
		{
	//	    ctor = cast(CtorDeclaration)this;
	//	    if (!cd.ctor)
	//		cd.ctor = ctor;
			return;
		}

static if (false) {
		dtor = isDtorDeclaration();
		if (dtor)
		{
			if (cd.dtor)
			error("multiple destructors for class %s", cd.toChars());
			cd.dtor = dtor;
		}

		inv = isInvariantDeclaration();
		if (inv)
		{
			cd.inv = inv;
		}

		if (isNewDeclaration())
		{
			if (!cd.aggNew)
				cd.aggNew = cast(NewDeclaration)this;
		}

		if (isDelete())
		{
			if (cd.aggDelete)
			error("multiple delete's for class %s", cd.toChars());
			cd.aggDelete = cast(DeleteDeclaration)this;
		}
}

		if (storage_class & STC.STCabstract)
			cd.isabstract = true;

		// if static function, do not put in vtbl[]
		if (!isVirtual())
		{
			//printf("\tnot virtual\n");
			goto Ldone;
		}

		/* Find index of existing function in base class's vtbl[] to override
		 * (the index will be the same as in cd's current vtbl[])
		 */
		vi = cd.baseClass ? findVtblIndex(cd.baseClass.vtbl, cd.baseClass.vtbl.dim) : -1;
		switch (vi)
		{
			case -1:
			/* Didn't find one, so
			 * This is an 'introducing' function which gets a new
			 * slot in the vtbl[].
			 */

			// Verify this doesn't override previous final function
			if (cd.baseClass)
			{
				Dsymbol s = cd.baseClass.search(loc, ident, 0);
				if (s)
				{
				FuncDeclaration ff = s.isFuncDeclaration();
				ff = ff.overloadExactMatch(type);
				if (ff && ff.isFinal() && ff.prot() != PROT.PROTprivate)
					error("cannot override final function %s", ff.toPrettyChars());
				}
			}

			if (isFinal())
			{
				if (isOverride())
				error("does not override any function");
				cd.vtblFinal.push(cast(void*)this);
			}
			else
			{
				// Append to end of vtbl[]
				//printf("\tintroducing function\n");
				introducing = 1;
				vi = cd.vtbl.dim;
				cd.vtbl.push(cast(void*)this);
				vtblIndex = vi;
			}
			break;

			case -2:	// can't determine because of fwd refs
				cd.sizeok = 2;	// can't finish due to forward reference
				global.dprogress = dprogress_save;
				return;

			default:
			{
			FuncDeclaration fdv = cast(FuncDeclaration)cd.baseClass.vtbl.data[vi];

			// This function is covariant with fdv
			if (fdv.isFinal())
				error("cannot override final function %s", fdv.toPrettyChars());

version (DMDV2) {
			if (!isOverride())
				warning(loc, "overrides base class function %s, but is not marked with 'override'", fdv.toPrettyChars());
}

			if (fdv.toParent() == parent)
			{
				// If both are mixins, then error.
				// If either is not, the one that is not overrides
				// the other.
				if (fdv.parent.isClassDeclaration())
				break;
				if (!this.parent.isClassDeclaration()
///static if (!BREAKABI) {
				&& !isDtorDeclaration()
///}
///version (DMDV2) {
				&& !isPostBlitDeclaration()
///}
				)
				error("multiple overrides of same function");
			}
			cd.vtbl.data[vi] = cast(void*)this;
			vtblIndex = vi;

			/* Remember which functions this overrides
			 */
			foverrides.push(fdv);

			/* This works by whenever this function is called,
			 * it actually returns tintro, which gets dynamically
			 * cast to type. But we know that tintro is a base
			 * of type, so we could optimize it by not doing a
			 * dynamic cast, but just subtracting the isBaseOf()
			 * offset if the value is != null.
			 */

			if (fdv.tintro)
				tintro = fdv.tintro;
			else if (!type.equals(fdv.type))
			{
				/* Only need to have a tintro if the vptr
				 * offsets differ
				 */
				int offset;
				if (fdv.type.nextOf().isBaseOf(type.nextOf(), &offset))
				{
				tintro = fdv.type;
				}
			}
			break;
			}
		}

		/* Go through all the interface bases.
		 * If this function is covariant with any members of those interface
		 * functions, set the tintro.
		 */
		for (int i = 0; i < cd.interfaces_dim; i++)
		{
			BaseClass b = cd.interfaces[i];
			vi = findVtblIndex(b.base.vtbl, b.base.vtbl.dim);
			switch (vi)
			{
			case -1:
				break;

			case -2:
				cd.sizeok = 2;	// can't finish due to forward reference
			    global.dprogress = dprogress_save;
				return;

			default:
			{   FuncDeclaration fdv = cast(FuncDeclaration)b.base.vtbl.data[vi];
				Type ti = null;

				/* Remember which functions this overrides
				 */
				foverrides.push(fdv);

				if (fdv.tintro)
					ti = fdv.tintro;
				else if (!type.equals(fdv.type))
				{
					/* Only need to have a tintro if the vptr
					 * offsets differ
					 */
					uint errors = global.errors;
					global.gag++;            // suppress printing of error messages
					int offset;
					int baseOf = fdv.type.nextOf().isBaseOf(type.nextOf(), &offset);
					global.gag--;            // suppress printing of error messages
					if (errors != global.errors)
					{
						// any error in isBaseOf() is a forward reference error, so we bail out
						global.errors = errors;
						cd.sizeok = 2;    // can't finish due to forward reference
						global.dprogress = dprogress_save;
						return;
					}
					if (baseOf)
					{
						ti = fdv.type;
					}
				}
				if (ti)
				{
				if (tintro && !tintro.equals(ti))
				{
					error("incompatible covariant types %s and %s", tintro.toChars(), ti.toChars());
				}
				tintro = ti;
				}
				goto L2;
			}
			}
		}

		if (introducing && isOverride())
		{
			error("does not override any function");
		}

		L2: ;
			/* Go through all the interface bases.
			 * Disallow overriding any final functions in the interface(s).
			 */
			for (int i = 0; i < cd.interfaces_dim; i++)
			{
				BaseClass b = cd.interfaces[i];
				if (b.base)
				{
					Dsymbol s = search_function(b.base, ident);
					if (s)
					{
						FuncDeclaration f_ = s.isFuncDeclaration();
						if (f_)
						{
							f_ = f_.overloadExactMatch(type);
							if (f_ && f_.isFinal() && f_.prot() != PROT.PROTprivate)
								error("cannot override final function %s.%s", b.base.toChars(), f_.toPrettyChars());
						}
					}
				}
			}
		}
		else if (isOverride() && !parent.isTemplateInstance())
		error("override only applies to class member functions");

		/* Do not allow template instances to add virtual functions
		 * to a class.
		 */
		if (isVirtual())
		{
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
			ClassDeclaration cdd = ti.tempdecl.isClassMember();
			if (cdd)
			{
				error("cannot use template to add virtual function to class '%s'", cdd.toChars());
			}
		}
		}

		if (isMain())
		{
		// Check parameters to see if they are either () or (char[][] args)
		switch (nparams)
		{
			case 0:
			break;

			case 1:
			{
			auto arg0 = Parameter.getNth(f.parameters, 0);
			if (arg0.type.ty != TY.Tarray ||
				arg0.type.nextOf().ty != TY.Tarray ||
				arg0.type.nextOf().nextOf().ty != TY.Tchar ||
				arg0.storageClass & (STC.STCout | STC.STCref | STC.STClazy))
				goto Lmainerr;
			break;
			}

			default:
			goto Lmainerr;
		}

		if (!f.nextOf())
			error("must return int or void");
		else if (f.nextOf().ty != TY.Tint32 && f.nextOf().ty != TY.Tvoid)
			error("must return int or void, not %s", f.nextOf().toChars());
		if (f.varargs)
		{
		Lmainerr:
			error("parameters must be main() or main(char[][] args)");
		}
		}

		if (ident == Id.assign && (sd || cd))
		{	// Disallow identity assignment operator.

		// opAssign(...)
		if (nparams == 0)
		{   if (f.varargs == 1)
			goto Lassignerr;
		}
		else
		{
			auto arg0 = Parameter.getNth(f.parameters, 0);
			Type t0 = arg0.type.toBasetype();
			Type tb = sd ? sd.type : cd.type;
			if (arg0.type.implicitConvTo(tb) ||
			(sd && t0.ty == TY.Tpointer && t0.nextOf().implicitConvTo(tb))
			   )
			{
			if (nparams == 1)
				goto Lassignerr;
			auto arg1 = Parameter.getNth(f.parameters, 1);
			if (arg1.defaultArg)
				goto Lassignerr;
			}
		}
		}

	    if (isVirtual() && semanticRun != PASSsemanticdone)
		{
			/* Rewrite contracts as nested functions, then call them.
			 * Doing it as nested functions means that overriding functions
			 * can call them.
			 */
			if (frequire)
			{
				/*   in { ... }
				 * becomes:
				 *   void __require() { ... }
				 *   __require();
				 */
				Loc loc = frequire.loc;
				TypeFunction tf = new TypeFunction(null, Type.tvoid, 0, LINKd);
				FuncDeclaration fd = new FuncDeclaration(loc, loc, Id.require, STCundefined, tf);
				fd.fbody = frequire;
				Statement s1 = new DeclarationStatement(loc, fd);
				Expression e = new CallExp(loc, new VarExp(loc, fd, 0), cast(Expressions)null);
				Statement s2 = new ExpStatement(loc, e);
				frequire = new CompoundStatement(loc, s1, s2);
				fdrequire = fd;
			}

			if (fensure)
			{   /*   out (result) { ... }
				 * becomes:
				 *   tret __ensure(ref tret result) { ... }
				 *   __ensure(result);
				 */
				if (!outId && f.nextOf().toBasetype().ty != Tvoid)
					outId = Id.result;	// provide a default

				Loc loc = fensure.loc;
				auto arguments = new Parameters();
				Parameter a = null;
				if (outId)
				{
					a = new Parameter(STCref, f.nextOf(), outId, null);
					arguments.push(a);
				}
				TypeFunction tf = new TypeFunction(arguments, Type.tvoid, 0, LINKd);
				FuncDeclaration fd = new FuncDeclaration(loc, loc, Id.ensure, STCundefined, tf);
				fd.fbody = fensure;
				Statement s1 = new DeclarationStatement(loc, fd);
				Expression eresult = null;
				if (outId)
					eresult = new IdentifierExp(loc, outId);
				Expression e = new CallExp(loc, new VarExp(loc, fd, 0), eresult);
				Statement s2 = new ExpStatement(loc, e);
				fensure = new CompoundStatement(loc, s1, s2);
				fdensure = fd;
			}
		}

	Ldone:
	    global.dprogress++;
		semanticRun = PASSsemanticdone;

		/* Save scope for possible later use (if we need the
		 * function internals)
		 */
		scope_ = sc.clone();
		scope_.setNoFree();
		return;

	Lassignerr:
		if (sd)
		{
		sd.hasIdentityAssign = 1;	// don't need to generate it
		goto Ldone;
		}
		error("identity assignment operator overload is illegal");
	}

    override void semantic2(Scope sc)
	{
	}

	// Do the semantic analysis on the internals of the function.
    override void semantic3(Scope sc)
	{
		TypeFunction f;
		VarDeclaration argptr = null;
		VarDeclaration _arguments = null;

		if (!parent)
		{
		if (global.errors)
			return;
		//printf("FuncDeclaration.semantic3(%s '%s', sc = %p)\n", kind(), toChars(), sc);
		assert(0);
		}
		//printf("FuncDeclaration.semantic3('%s.%s', sc = %p, loc = %s)\n", parent.toChars(), toChars(), sc, loc.toChars());
		//fflush(stdout);
		//printf("storage class = x%x %x\n", sc.stc, storage_class);
		//{ static int x; if (++x == 2) *(char*)0=0; }
		//printf("\tlinkage = %d\n", sc.linkage);

		//printf(" sc.incontract = %d\n", sc.incontract);
	    if (semanticRun >= PASSsemantic3)
			return;
		semanticRun = PASSsemantic3;

		if (!type || type.ty != TY.Tfunction)
		return;
		f = cast(TypeFunction)(type);

		// Check the 'throws' clause
		if (fthrows)
		{
		for (int i = 0; i < fthrows.dim; i++)
		{
			Type t = cast(Type)fthrows.data[i];

			t = t.semantic(loc, sc);
			if (!t.isClassHandle())
			error("can only throw classes, not %s", t.toChars());
		}
		}

	    frequire = mergeFrequire(frequire);
		fensure = mergeFensure(fensure);

		if (fbody || frequire)
		{
		/* Symbol table into which we place parameters and nested functions,
		 * solely to diagnose name collisions.
		 */
		localsymtab = new DsymbolTable();

		// Establish function scope
		ScopeDsymbol ss = new ScopeDsymbol();
		ss.parent = sc.scopesym;
		Scope sc2 = sc.push(ss);
		sc2.func = this;
		sc2.parent = this;
		sc2.callSuper = 0;
		sc2.sbreak = null;
		sc2.scontinue = null;
		sc2.sw = null;
		sc2.fes = fes;
		sc2.linkage = LINK.LINKd;
        sc2.stc &= ~(STC.STCauto | STC.STCscope | STC.STCstatic | STC.STCabstract | STC.STCdeprecated |
			        STC.STC_TYPECTOR | STC.STCfinal | STC.STCtls | STC.STCgshared | STC.STCref |
			        STCproperty | STCsafe | STCtrusted | STCsystem);
        sc2.protection = PROT.PROTpublic;
		sc2.explicitProtection = 0;
		sc2.structalign = 8;
		sc2.incontract = 0;
		sc2.tf = null;
		sc2.noctor = 0;

		// Declare 'this'
		AggregateDeclaration ad = isThis();
		if (ad)
		{   VarDeclaration v;

			if (isFuncLiteralDeclaration() && isNested())
			{
			error("literals cannot be class members");
			return;
			}
			else
			{
			assert(!isNested());	// can't be both member and nested
			assert(ad.handle);
			Type thandle = ad.handle;
version (STRUCTTHISREF) {
			thandle = thandle.addMod(type.mod);
			thandle = thandle.addStorageClass(storage_class);
			if (isPure())
				thandle = thandle.addMod(MOD.MODconst);
} else {
			if (storage_class & STC.STCconst || type.isConst())
			{
				assert(0); // BUG: shared not handled
				if (thandle.ty == TY.Tclass)
				thandle = thandle.constOf();
				else
				{	assert(thandle.ty == TY.Tpointer);
				thandle = thandle.nextOf().constOf().pointerTo();
				}
			}
			else if (storage_class & STC.STCimmutable || type.isImmutable())
			{
				if (thandle.ty == TY.Tclass)
				thandle = thandle.invariantOf();
				else
				{	assert(thandle.ty == TY.Tpointer);
				thandle = thandle.nextOf().invariantOf().pointerTo();
				}
			}
			else if (storage_class & STC.STCshared || type.isShared())
			{
				assert(0);  // not implemented
			}
}
			v = new ThisDeclaration(loc, thandle);
			v.storage_class |= STC.STCparameter;
version (STRUCTTHISREF) {
			if (thandle.ty == TY.Tstruct)
				v.storage_class |= STC.STCref;
}
			v.semantic(sc2);
			if (!sc2.insert(v))
				assert(0);
			v.parent = this;
			vthis = v;
			}
		}
		else if (isNested())
		{
			/* The 'this' for a nested function is the link to the
			 * enclosing function's stack frame.
			 * Note that nested functions and member functions are disjoint.
			 */
			VarDeclaration v = new ThisDeclaration(loc, Type.tvoid.pointerTo());
			v.storage_class |= STC.STCparameter;
			v.semantic(sc2);
			if (!sc2.insert(v))
			assert(0);
			v.parent = this;
			vthis = v;
		}

		// Declare hidden variable _arguments[] and _argptr
		if (f.varargs == 1)
		{
version (TARGET_NET) {
			varArgs(sc2, f, argptr, _arguments);
} else {
			Type t;

			if (f.linkage == LINK.LINKd)
			{
				// Declare _arguments[]
version (BREAKABI) {
				v_arguments = new VarDeclaration(Loc(0), global.typeinfotypelist.type, Id._arguments_typeinfo, null);
				v_arguments.storage_class = STCparameter;
				v_arguments.semantic(sc2);
				sc2.insert(v_arguments);
				v_arguments.parent = this;

				//t = Type.typeinfo.type.constOf().arrayOf();
				t = global.typeinfo.type.arrayOf();
				_arguments = new VarDeclaration(Loc(0), t, Id._arguments, null);
				_arguments.semantic(sc2);
				sc2.insert(_arguments);
				_arguments.parent = this;
} else {
				t = Type.typeinfo.type.arrayOf();
				v_arguments = new VarDeclaration(Loc(0), t, Id._arguments, null);
				v_arguments.storage_class = STC.STCparameter | STC.STCin;
				v_arguments.semantic(sc2);
				sc2.insert(v_arguments);
				v_arguments.parent = this;
	}
				}
				if (f.linkage == LINK.LINKd || (parameters && parameters.dim))
				{	// Declare _argptr
version (IN_GCC) {
				t = d_gcc_builtin_va_list_d_type;
} else {
				t = Type.tvoid.pointerTo();
}
				argptr = new VarDeclaration(Loc(0), t, Id._argptr, null);
				argptr.semantic(sc2);
				sc2.insert(argptr);
				argptr.parent = this;
			}
}
		}
static if(false) {
		// Propagate storage class from tuple parameters to their element-parameters.
		if (f.parameters)
		{
			foreach (arg; f.parameters)
			{
			//printf("[%d] arg.type.ty = %d %s\n", i, arg.type.ty, arg.type.toChars());
			if (arg.type.ty == TY.Ttuple)
			{   auto t = cast(TypeTuple)arg.type;
				size_t dim = Parameter.dim(t.arguments);
				for (size_t j = 0; j < dim; j++)
				{
                    auto narg = Parameter.getNth(t.arguments, j);
				    narg.storageClass = arg.storageClass;
				}
			}
			}
		}
}
		/* Declare all the function parameters as variables
		 * and install them in parameters[]
		 */
		size_t nparams = Parameter.dim(f.parameters);
		if (nparams)
		{   /* parameters[] has all the tuples removed, as the back end
			 * doesn't know about tuples
			 */
			parameters = new Dsymbols();
			parameters.reserve(nparams);
			for (size_t i = 0; i < nparams; i++)
			{
			auto arg = Parameter.getNth(f.parameters, i);
			Identifier id = arg.ident;
			if (!id)
			{
				/* Generate identifier for un-named parameter,
				 * because we need it later on.
				 */
				arg.ident = id = Identifier.generateId("_param_", i);
			}
			Type vtype = arg.type;
			if (isPure())
				vtype = vtype.addMod(MOD.MODconst);
			VarDeclaration v = new VarDeclaration(loc, vtype, id, null);
			//printf("declaring parameter %s of type %s\n", v.toChars(), v.type.toChars());
			v.storage_class |= STC.STCparameter;
			if (f.varargs == 2 && i + 1 == nparams)
				v.storage_class |= STC.STCvariadic;
			v.storage_class |= arg.storageClass & (STC.STCin | STC.STCout | STC.STCref | STC.STClazy | STC.STCfinal | STC.STC_TYPECTOR | STC.STCnodtor);
			v.semantic(sc2);
			if (!sc2.insert(v))
				error("parameter %s.%s is already defined", toChars(), v.toChars());
			else
				parameters.push(v);
			localsymtab.insert(v);
			v.parent = this;
			}
		}

		// Declare the tuple symbols and put them in the symbol table,
		// but not in parameters[].
		if (f.parameters)
		{
			foreach (arg; f.parameters)
			{
			if (!arg.ident)
				continue;			// never used, so ignore
			if (arg.type.ty == TY.Ttuple)
			{   auto t = cast(TypeTuple)arg.type;
				size_t dim = Parameter.dim(t.arguments);
				Objects exps = new Objects();
				exps.setDim(dim);
				for (size_t j = 0; j < dim; j++)
				{	auto narg = Parameter.getNth(t.arguments, j);
				assert(narg.ident);
				VarDeclaration v = sc2.search(Loc(0), narg.ident, null).isVarDeclaration();
				assert(v);
				Expression e = new VarExp(v.loc, v);
				exps[j] = e;
				}
				assert(arg.ident);
				auto v = new TupleDeclaration(loc, arg.ident, exps);
				//printf("declaring tuple %s\n", v.toChars());
				v.isexp = 1;
				if (!sc2.insert(v))
				error("parameter %s.%s is already defined", toChars(), v.toChars());
				localsymtab.insert(v);
				v.parent = this;
			}
			}
		}

		/* Do the semantic analysis on the [in] preconditions and
		 * [out] postconditions.
		 */
		sc2.incontract++;

		if (frequire)
		{   /* frequire is composed of the [in] contracts
			 */
			// BUG: need to error if accessing out parameters
			// BUG: need to treat parameters as const
			// BUG: need to disallow returns and throws
			// BUG: verify that all in and ref parameters are read
			frequire = frequire.semantic(sc2);
			labtab = null;		// so body can't refer to labels
		}

		if (fensure || addPostInvariant())
		{
			/* fensure is composed of the [out] contracts
			 */
			if (!type.nextOf())		// if return type is inferred
		    {
				/* This case:
				 *   auto fp = function() out { } body { };
				 * Can fix by doing semantic() onf fbody first.
				 */
				error("post conditions are not supported if the return type is inferred");
				return;
		    }

			ScopeDsymbol sym = new ScopeDsymbol();
			sym.parent = sc2.scopesym;
			sc2 = sc2.push(sym);

			assert(type.nextOf());
			if (type.nextOf().ty == TY.Tvoid)
			{
			if (outId)
				error("void functions have no result");
			}
			else
			{
			if (!outId)
				outId = Id.result;		// provide a default
			}

			if (outId)
			{	// Declare result variable
			Loc loc = this.loc;

			if (fensure)
				loc = fensure.loc;

			auto v = new VarDeclaration(loc, type.nextOf(), outId, null);
			v.noauto = true;
version (DMDV2) {
		    if (!isVirtual())
		        v.storage_class |= STC.STCconst;
			if (f.isref)
			{
				v.storage_class |= STC.STCref | STC.STCforeach;
			}
}
			sc2.incontract--;
			v.semantic(sc2);
			sc2.incontract++;
			if (!sc2.insert(v))
				error("out result %s is already defined", v.toChars());
			v.parent = this;
			vresult = v;

			// vresult gets initialized with the function return value
			// in ReturnStatement.semantic()
			}

			// BUG: need to treat parameters as const
			// BUG: need to disallow returns and throws
			if (fensure)
			{	fensure = fensure.semantic(sc2);
			labtab = null;		// so body can't refer to labels
			}

			if (!global.params.useOut)
			{	fensure = null;		// discard
			vresult = null;
			}

			// Postcondition invariant
			if (addPostInvariant())
			{
			Expression e = null;
			if (isCtorDeclaration())
			{
				// Call invariant directly only if it exists
				InvariantDeclaration inv = ad.inv;
				ClassDeclaration cd = ad.isClassDeclaration();

				while (!inv && cd)
				{
				cd = cd.baseClass;
				if (!cd)
					break;
				inv = cd.inv;
				}
				if (inv)
				{
				e = new DsymbolExp(Loc(0), inv);
				e = new CallExp(Loc(0), e);
				e = e.semantic(sc2);
				}
			}
			else
			{   // Call invariant virtually
				Expression v = new ThisExp(Loc(0));
				v.type = vthis.type;
version (STRUCTTHISREF) {
				if (ad.isStructDeclaration())
				v = v.addressOf(sc);
}
				e = new AssertExp(Loc(0), v);
			}
			if (e)
			{
				ExpStatement s = new ExpStatement(Loc(0), e);
				if (fensure)
				fensure = new CompoundStatement(Loc(0), s, fensure);
				else
				fensure = s;
			}
			}

			if (fensure)
			{	returnLabel = new LabelDsymbol(Id.returnLabel);
			LabelStatement ls = new LabelStatement(Loc(0), Id.returnLabel, fensure);
			ls.isReturnLabel = 1;
			returnLabel.statement = ls;
			}
			sc2 = sc2.pop();
		}

		sc2.incontract--;

		if (fbody)
		{   ClassDeclaration cd = isClassMember();

			/* If this is a class constructor
			 */
			if (isCtorDeclaration() && cd)
			{
				for (int i = 0; i < cd.fields.dim; i++)
				{   VarDeclaration v = cast(VarDeclaration)cd.fields[i];

					v.ctorinit = 0;
				}
			}

			if (inferRetType || f.retStyle() != RET.RETstack)
			nrvo_can = 0;

			fbody = fbody.semantic(sc2);
			if (!fbody)
			fbody = new CompoundStatement(Loc(0), new Statements());

			if (inferRetType)
			{	// If no return type inferred yet, then infer a void
			if (!type.nextOf())
			{
				(cast(TypeFunction)type).next = Type.tvoid;
				type = type.semantic(loc, sc);
			}
			f = cast(TypeFunction)type;
			}

			if (isStaticCtorDeclaration())
			{
				/* It's a static constructor. Ensure that all
				 * ctor consts were initialized.
				 */

			Dsymbol p = toParent();
			ScopeDsymbol add = p.isScopeDsymbol();
			if (!add)
			{
				error("static constructor can only be member of struct/class/module, not %s %s", p.kind(), p.toChars());
			}
			else
			{
				foreach (Dsymbol s; add.members)
				{
				s.checkCtorConstInit();
				}
			}
			}

			if (isCtorDeclaration() && cd)
			{
				//printf("callSuper = x%x\n", sc2.callSuper);

				// Verify that all the ctorinit fields got initialized
				if (!(sc2.callSuper & CSX.CSXthis_ctor))
				{
					for (int i = 0; i < cd.fields.dim; i++)
					{   VarDeclaration v = cast(VarDeclaration)cd.fields[i];

					if (v.ctorinit == 0 && v.isCtorinit())
						error("missing initializer for final field %s", v.toChars());
					}
				}

				if (!(sc2.callSuper & CSX.CSXany_ctor) &&
					cd.baseClass && cd.baseClass.ctor)
				{
					sc2.callSuper = 0;

					// Insert implicit super() at start of fbody
					Expression e1 = new SuperExp(Loc(0));
					Expression e = new CallExp(Loc(0), e1);

					e = e.trySemantic(sc2);
					if (!e)
					error("no match for implicit super() call in constructor");
					else
					{
					Statement s = new ExpStatement(Loc(0), e);
					fbody = new CompoundStatement(Loc(0), s, fbody);
					}
				}
				}
				else if (fes)
				{	// For foreach(){} body, append a return 0;
				Expression e = new IntegerExp(0);
				Statement s = new ReturnStatement(Loc(0), e);
				fbody = new CompoundStatement(Loc(0), fbody, s);
				assert(!returnLabel);
				}
				else if (!hasReturnExp && type.nextOf().ty != TY.Tvoid)
				error("expected to return a value of type %s", type.nextOf().toChars());
				else if (!inlineAsm)
				{
version (DMDV2) {
				BE blockexit = fbody ? fbody.blockExit() : BE.BEfallthru;
				if (f.isnothrow && blockexit & BE.BEthrow)
					error("'%s' is nothrow yet may throw", toChars());

				int offend = blockexit & BE.BEfallthru;
}
				if (type.nextOf().ty == TY.Tvoid)
				{
					if (offend && isMain())
					{	// Add a return 0; statement
					Statement s = new ReturnStatement(Loc(0), new IntegerExp(0));
					fbody = new CompoundStatement(Loc(0), fbody, s);
					}
				}
				else
				{
					if (offend)
					{
						Expression e;
version (DMDV1) {
						warning(loc, "no return exp; or assert(0); at end of function");
} else {
						error("no return exp; or assert(0); at end of function");
}
						if (global.params.useAssert &&
							!global.params.useInline)
						{   /* Add an assert(0, msg); where the missing return
							 * should be.
							 */
							e = new AssertExp(
							  endloc,
							  new IntegerExp(0),
							  new StringExp(loc, "missing return expression")
							);
						}
						else
							e = new HaltExp(endloc);

						e = new CommaExp(Loc(0), e, type.nextOf().defaultInit(Loc(0)));
						e = e.semantic(sc2);
						Statement s = new ExpStatement(Loc(0), e);
						fbody = new CompoundStatement(Loc(0), fbody, s);
					}
				}
			}
		}

		{
			auto a = new Statements();

			// Merge in initialization of 'out' parameters
			if (parameters)
			{	foreach (Dsymbol s; parameters)
			{
				auto v = cast(VarDeclaration)s;
				if (v.storage_class & STC.STCout)
				{
				assert(v.init);
				ExpInitializer ie = v.init.isExpInitializer();
				assert(ie);
				a.push(new ExpStatement(Loc(0), ie.exp));
				}
			}
			}

			if (argptr)
			{	// Initialize _argptr to point past non-variadic arg
version (IN_GCC) {
				// Handled in FuncDeclaration.toObjFile
				v_argptr = argptr;
				v_argptr.init = new VoidInitializer(loc);
} else {
				Type t = argptr.type;
				VarDeclaration p;
				uint offset;

				Expression e1 = new VarExp(Loc(0), argptr);
				if (parameters && parameters.dim)
					p = cast(VarDeclaration)parameters[parameters.length - 1];
				else
					p = v_arguments;		// last parameter is _arguments[]
				if (p.storage_class & STClazy)
					// If the last parameter is lazy, it's the size of a delegate
					offset = PTRSIZE * 2;
				else
					offset = cast(size_t)p.type.size();
				offset = (offset + 3) & ~3;	// assume stack aligns on 4
				Expression e = new SymOffExp(Loc(0), p, offset);
				e = new AssignExp(Loc(0), e1, e);
				e.type = t;
				a.push(new ExpStatement(Loc(0), e));
				p.isargptr = true;
}
			}

			if (_arguments)
			{
			/* Advance to elements[] member of TypeInfo_Tuple with:
			 *  _arguments = v_arguments.elements;
			 */
			Expression e = new VarExp(Loc(0), v_arguments);
			e = new DotIdExp(Loc(0), e, Id.elements);
			Expression e1 = new VarExp(Loc(0), _arguments);
			e = new AssignExp(Loc(0), e1, e);
			e.op = TOK.TOKconstruct;
			e = e.semantic(sc2);
			a.push(new ExpStatement(Loc(0), e));
			}

			// Merge contracts together with body into one compound statement

version (_DH) {
			if (frequire && global.params.useIn)
			{	frequire.incontract = 1;
			a.push(frequire);
			}
} else {
			if (frequire && global.params.useIn)
			a.push(frequire);
}

			// Precondition invariant
			if (addPreInvariant())
			{
			Expression e = null;
			if (isDtorDeclaration())
			{
				// Call invariant directly only if it exists
				InvariantDeclaration inv = ad.inv;
				ClassDeclaration cd = ad.isClassDeclaration();

				while (!inv && cd)
				{
				cd = cd.baseClass;
				if (!cd)
					break;
				inv = cd.inv;
				}
				if (inv)
				{
				e = new DsymbolExp(Loc(0), inv);
				e = new CallExp(Loc(0), e);
				e = e.semantic(sc2);
				}
			}
			else
			{   // Call invariant virtually
				Expression v = new ThisExp(Loc(0));
				v.type = vthis.type;
version (STRUCTTHISREF) {
				if (ad.isStructDeclaration())
					v = v.addressOf(sc);
}
				Expression se = new StringExp(Loc(0), "null this");
				se = se.semantic(sc);
				se.type = Type.tchar.arrayOf();
				e = new AssertExp(loc, v, se);
			}
			if (e)
			{
				auto s = new ExpStatement(Loc(0), e);
				a.push(s);
			}
			}

			if (fbody)
			a.push(fbody);

			if (fensure)
			{
			a.push(returnLabel.statement);

			if (type.nextOf().ty != TY.Tvoid)
			{
				// Create: return vresult;
				assert(vresult);
				Expression e = new VarExp(Loc(0), vresult);
				if (tintro)
				{	e = e.implicitCastTo(sc, tintro.nextOf());
				e = e.semantic(sc);
				}
				auto s = new ReturnStatement(Loc(0), e);
				a.push(s);
			}
			}

			fbody = new CompoundStatement(Loc(0), a);
version (DMDV2) {
			/* Append destructor calls for parameters as finally blocks.
			 */
			if (parameters)
			{	foreach(Dsymbol symb; parameters)
			{
				auto v = cast(VarDeclaration)symb;

				if (v.storage_class & (STC.STCref | STC.STCout))
				continue;

				/* Don't do this for static arrays, since static
				 * arrays are called by reference. Remove this
				 * when we change them to call by value.
				 */
				if (v.type.toBasetype().ty == TY.Tsarray)
				continue;

				Expression e = v.callAutoDtor(sc);
				if (e)
				{	Statement s = new ExpStatement(Loc(0), e);
				s = s.semantic(sc);
				if (fbody.blockExit() == BE.BEfallthru)
					fbody = new CompoundStatement(Loc(0), fbody, s);
				else
					fbody = new TryFinallyStatement(Loc(0), fbody, s);
				}
			}
			}
}

static if (true) {
			if (isSynchronized())
			{	/* Wrap the entire function body in a synchronized statement
				 */
				ClassDeclaration cd = parent.isClassDeclaration();
				if (cd)
				{
///version (TARGET_WINDOS) {
					if (/*config.flags2 & CFG2.CFG2seh &&*/	// always on for WINDOS
					!isStatic() && !fbody.usesEH())
					{
						/* The back end uses the "jmonitor" hack for syncing;
						 * no need to do the sync at this level.
						 */
					}
					else
///}
					{
						Expression vsync;
						if (isStatic())
						{
							// The monitor is in the ClassInfo
							vsync = new DotIdExp(loc, new DsymbolExp(loc, cd), Id.classinfo_);
						}
						else
						{   // 'this' is the monitor
							vsync = new VarExp(loc, vthis);
						}
						fbody = new PeelStatement(fbody);	// don't redo semantic()
						fbody = new SynchronizedStatement(loc, vsync, fbody);
						fbody = fbody.semantic(sc2);
					}
				}
				else
				{
					error("synchronized function %s must be a member of a class", toChars());
				}
			}
}
		}

		sc2.callSuper = 0;
		sc2.pop();
		}
		
	    semanticRun = PASSsemantic3done;
	}

    // called from semantic3
    void varArgs(Scope sc, TypeFunction, ref VarDeclaration, ref VarDeclaration)
	{
		assert(false);
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
//		writef("FuncDeclaration.toCBuffer() '%s'\n", toChars());

		StorageClassDeclaration.stcToCBuffer(buf, storage_class);
		type.toCBuffer(buf, ident, hgs);
		bodyToCBuffer(buf, hgs);
	}

	void bodyToCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		if (fbody &&
			(!hgs.hdrgen || hgs.tpltMember || canInline(1,1))
		   )
		{
			buf.writenl();

			// in{}
			if (frequire)
			{
				buf.writestring("in");
				buf.writenl();
				frequire.toCBuffer(buf, hgs);
			}

			// out{}
			if (fensure)
			{
				buf.writestring("out");
				if (outId)
				{
					buf.writebyte('(');
					buf.writestring(outId.toChars());
					buf.writebyte(')');
				}
				buf.writenl();
				fensure.toCBuffer(buf, hgs);
			}

			if (frequire || fensure)
			{
				buf.writestring("body");
				buf.writenl();
			}

			buf.writebyte('{');
			buf.writenl();
			fbody.toCBuffer(buf, hgs);
			buf.writebyte('}');
			buf.writenl();
		}
		else
		{   buf.writeByte(';');
			buf.writenl();
		}
	}

	/****************************************************
	 * Determine if 'this' overrides fd.
	 * Return true if it does.
	 */
    bool overrides(FuncDeclaration fd)
	{
		bool result = false;

		if (fd.ident == ident)
		{
			int cov = type.covariant(fd.type);
			if (cov)
			{
				ClassDeclaration cd1 = toParent().isClassDeclaration();
				ClassDeclaration cd2 = fd.toParent().isClassDeclaration();

				if (cd1 && cd2 && cd2.isBaseOf(cd1, null))
					result = true;
			}
		}
		return result;
	}

	/*************************************************
	 * Find index of function in vtbl[0..dim] that
	 * this function overrides.
	 * Prefer an exact match to a covariant one.
	 * Returns:
	 *	-1	didn't find one
	 *	-2	can't determine because of forward references
	 */
    int findVtblIndex(Array vtbl, int dim)
	{
	    FuncDeclaration mismatch = null;
		int bestvi = -1;
		for (int vi = 0; vi < dim; vi++)
		{
			FuncDeclaration fdv = (cast(Dsymbol)vtbl.data[vi]).isFuncDeclaration();
			if (fdv && fdv.ident is ident)
			{
			    if (type.equals(fdv.type))	// if exact match
					return vi;				// no need to look further
				int cov = type.covariant(fdv.type);
				//printf("\tbaseclass cov = %d\n", cov);
				switch (cov)
				{
					case 0:		// types are distinct
						break;

					case 1:
			            bestvi = vi;	// covariant, but not identical
						break;			// keep looking for an exact match

					case 2:
						mismatch = fdv;	// overrides, but is not covariant
						break;			// keep looking for an exact match

					case 3:
						return -2;	// forward references

					default:
						writef("cov = %d\n", cov);
						assert(false);
				}
			}
		}
	    if (bestvi == -1 && mismatch)
		{
			//type.print();
			//mismatch.type.print();
			//writef("%s %s\n", type.deco, mismatch.type.deco);
			error("of type %s overrides but is not covariant with %s of type %s",
				type.toChars(), mismatch.toPrettyChars(), mismatch.type.toChars());
		}
		return bestvi;
	}

	/****************************************************
	 * Overload this FuncDeclaration with the new one f.
	 * Return !=0 if successful; i.e. no conflict.
	 */
    override bool overloadInsert(Dsymbol s)
	{
		FuncDeclaration f;
		AliasDeclaration a;

		//writef("FuncDeclaration.overloadInsert(%s)\n", s.toChars());
		a = s.isAliasDeclaration();
		if (a)
		{
			if (overnext)
				return overnext.overloadInsert(a);

			if (!a.aliassym && a.type.ty != TY.Tident && a.type.ty != TY.Tinstance)
			{
				//writef("\ta = '%s'\n", a.type.toChars());
				return false;
			}
			overnext = a;
			//printf("\ttrue: no conflict\n");
			return true;
		}
		f = s.isFuncDeclaration();
		if (!f)
			return false;

static if (false) {
		/* Disable this check because:
		 *	const void foo();
		 * semantic() isn't run yet on foo(), so the const hasn't been
		 * applied yet.
		 */
		if (type)
		{
			printf("type = %s\n", type.toChars());
			printf("f.type = %s\n", f.type.toChars());
		}
		if (type && f.type &&	// can be null for overloaded constructors
		f.type.covariant(type) &&
		f.type.mod == type.mod &&
		!isFuncAliasDeclaration())
		{
			//printf("\tfalse: conflict %s\n", kind());
			return false;
		}
}

		if (overnext)
			return overnext.overloadInsert(f);
		overnext = f;
		//printf("\ttrue: no conflict\n");
		return true;
	}

    FuncDeclaration overloadExactMatch(Type t)
	{
		Param1 p;
		p.t = t;
		p.f = null;
		overloadApply(this, p);
		return p.f;
	}

    FuncDeclaration overloadResolve(Loc loc, Expression ethis, Expressions arguments, int flags = 0)
	{
		TypeFunction tf;
		Match m;

static if (false) {
		printf("FuncDeclaration.overloadResolve('%s')\n", toChars());
		if (arguments)
		{
			int i;

			for (i = 0; i < arguments.dim; i++)
			{
				Expression arg;

				arg = cast(Expression)arguments.data[i];
				assert(arg.type);
				printf("\t%s: ", arg.toChars());
				arg.type.print();
			}
		}
}

		m.last = MATCH.MATCHnomatch;
		overloadResolveX(&m, this, ethis, arguments);

		if (m.count == 1)		// exactly one match
		{
			return m.lastf;
		}
		else
		{
			scope OutBuffer buf = new OutBuffer();

			buf.writeByte('(');
			if (arguments)
			{
				HdrGenState hgs;

				argExpTypesToCBuffer(buf, arguments, &hgs);
				buf.writeByte(')');
				if (ethis)
					ethis.type.modToBuffer(buf);
			}
			else
				buf.writeByte(')');

			if (m.last == MATCH.MATCHnomatch)
			{
				if (flags & 1)		// if do not print error messages
					return null;		// no match

				tf = cast(TypeFunction)type;

				scope OutBuffer buf2 = new OutBuffer();
				tf.modToBuffer(buf2);

				//printf("tf = %s, args = %s\n", tf.deco, ((Expression *)arguments.data[0]).type.deco);
				error(loc, "%s%s is not callable using argument types %s",
				Parameter.argsTypesToChars(tf.parameters, tf.varargs),
				buf2.toChars(),
				buf.toChars());
				return m.anyf;		// as long as it's not a FuncAliasDeclaration
			}
			else
			{
static if (true) {
				TypeFunction t1 = cast(TypeFunction)m.lastf.type;
				TypeFunction t2 = cast(TypeFunction)m.nextf.type;

				error(loc, "called with argument types:\n\t(%s)\nmatches both:\n\t%s%s\nand:\n\t%s%s",
					buf.toChars(),
					m.lastf.toPrettyChars(), Parameter.argsTypesToChars(t1.parameters, t1.varargs),
					m.nextf.toPrettyChars(), Parameter.argsTypesToChars(t2.parameters, t2.varargs));
} else {
				error(loc, "overloads %s and %s both match argument list for %s",
					m.lastf.type.toChars(),
					m.nextf.type.toChars(),
					m.lastf.toChars());
}
				return m.lastf;
			}
		}
	}

	/*************************************
	 * Determine partial specialization order of 'this' vs g.
	 * This is very similar to TemplateDeclaration.leastAsSpecialized().
	 * Returns:
	 *	match	'this' is at least as specialized as g
	 *	0	g is more specialized than 'this'
	 */
    MATCH leastAsSpecialized(FuncDeclaration g)
	{
	version (LOG_LEASTAS) {
		printf("%s.leastAsSpecialized(%s)\n", toChars(), g.toChars());
	}

		/* This works by calling g() with f()'s parameters, and
		 * if that is possible, then f() is at least as specialized
		 * as g() is.
		 */

		TypeFunction tf = cast(TypeFunction)type;
		TypeFunction tg = cast(TypeFunction)g.type;
		size_t nfparams = Parameter.dim(tf.parameters);
		size_t ngparams = Parameter.dim(tg.parameters);
		MATCH match = MATCHexact;

		/* If both functions have a 'this' pointer, and the mods are not
		 * the same and g's is not const, then this is less specialized.
		 */
		if (needThis() && g.needThis())
		{
			if (tf.mod != tg.mod)
			{
				if (tg.mod == MODconst)
					match = MATCHconst;
				else
					return MATCHnomatch;
			}
		}

		/* Create a dummy array of arguments out of the parameters to f()
		 */
		scope Expressions args = new Expressions();
		args.setDim(nfparams);
		for (int u = 0; u < nfparams; u++)
		{
			auto p = Parameter.getNth(tf.parameters, u);
			Expression e;
			if (p.storageClass & (STCref | STCout))
			{
				e = new IdentifierExp(Loc(0), p.ident);
				e.type = p.type;
			}
			else
				e = p.type.defaultInit(Loc(0));

			args[u] = e;
		}

		MATCH m = cast(MATCH) tg.callMatch(null, args);
		if (m)
		{
			/* A variadic parameter list is less specialized than a
			 * non-variadic one.
			 */
			if (tf.varargs && !tg.varargs)
				goto L1;	// less specialized

	version (LOG_LEASTAS) {
			printf("  matches %d, so is least as specialized\n", m);
	}
			return m;
		}
	  L1:
	version (LOG_LEASTAS) {
		printf("  doesn't match, so is not as specialized\n");
	}
		return MATCHnomatch;
	}

	/********************************
	 * Labels are in a separate scope, one per function.
	 */
    LabelDsymbol searchLabel(Identifier ident)
	{
		Dsymbol s;

		if (!labtab)
			labtab = new DsymbolTable();	// guess we need one

		s = labtab.lookup(ident);
		if (!s)
		{
			s = new LabelDsymbol(ident);
			labtab.insert(s);
		}

		return cast(LabelDsymbol)s;
	}

	/****************************************
	 * If non-static member function that has a 'this' pointer,
	 * return the aggregate it is a member of.
	 * Otherwise, return null.
	 */
    override AggregateDeclaration isThis()
	{
		AggregateDeclaration ad = null;

		//printf("+FuncDeclaration.isThis() '%s'\n", toChars());
		if ((storage_class & STC.STCstatic) == 0)
		{
			ad = isMember2();
		}
		//printf("-FuncDeclaration.isThis() %p\n", ad);
		return ad;
	}

    AggregateDeclaration isMember2()
	{
		AggregateDeclaration ad = null;

		//printf("+FuncDeclaration.isMember2() '%s'\n", toChars());
		for (Dsymbol s = this; s; s = s.parent)
		{
		//printf("\ts = '%s', parent = '%s', kind = %s\n", s.toChars(), s.parent.toChars(), s.parent.kind());
			ad = s.isMember();
			if (ad)
			{   //printf("test4\n");
					break;
			}
			if (!s.parent || (!s.parent.isTemplateInstance()))
			{   //printf("test5\n");
					break;
			}
		}
		//printf("-FuncDeclaration.isMember2() %p\n", ad);
		return ad;
	}

	/*****************************************
	 * Determine lexical level difference from 'this' to nested function 'fd'.
	 * Error if this cannot call fd.
	 * Returns:
	 *	0	same level
	 *	-1	increase nesting by 1 (fd is nested within 'this')
	 *	>0	decrease nesting by number
	 */
    int getLevel(Loc loc, FuncDeclaration fd)	// lexical nesting level difference
	{
		int level;
		Dsymbol s;
		Dsymbol fdparent;

		//printf("FuncDeclaration.getLevel(fd = '%s')\n", fd.toChars());
		fdparent = fd.toParent2();
		if (fdparent == this)
			return -1;
		s = this;
		level = 0;
		while (fd != s && fdparent != s.toParent2())
		{
			//printf("\ts = '%s'\n", s.toChars());
			FuncDeclaration thisfd = s.isFuncDeclaration();
			if (thisfd)
			{
				if (!thisfd.isNested() && !thisfd.vthis)
					goto Lerr;
			}
			else
			{
				AggregateDeclaration thiscd = s.isAggregateDeclaration();
				if (thiscd)
				{
					if (!thiscd.isNested())
						goto Lerr;
				}
				else
					goto Lerr;
			}

			s = s.toParent2();
			assert(s);
			level++;
		}
		return level;

	Lerr:
		error(loc, "cannot access frame of function %s", fd.toChars());
		return 1;
	}

    void appendExp(Expression e)
	{
		assert(false);
	}

    void appendState(Statement s)
	{
		assert(false);
	}

    override string mangle()
	out (result)
	{
		assert(result.length > 0);
	}
	body
	{
		if (isMain()) {
			return "_Dmain";
		}

		if (isWinMain() || isDllMain() || ident == Id.tls_get_addr)
			return ident.toChars();

		assert(this);

		return Declaration.mangle();
	}

    override string toPrettyChars()
	{
		if (isMain())
			return "D main";
		else
			return Dsymbol.toPrettyChars();
	}

    int isMain()
	{
		return ident is Id.main && linkage != LINK.LINKc && !isMember() && !isNested();
	}

    int isWinMain()
	{
		//printf("FuncDeclaration::isWinMain() %s\n", toChars());
static if (false) {
		int x = ident == Id.WinMain &&
		linkage != LINK.LINKc && !isMember();
		printf("%s\n", x ? "yes" : "no");
		return x;
} else {
		return ident == Id.WinMain && linkage != LINK.LINKc && !isMember();
}
	}

    int isDllMain()
	{
		return ident == Id.DllMain && linkage != LINK.LINKc && !isMember();
	}

	/**********************************
	 * Determine if function is a builtin one that we can
	 * evaluate at compile time.
	 */
    BUILTIN isBuiltin()
	{
		enum FeZe = "FNaNbeZe";	// pure nothrow real function(real)

		//printf("FuncDeclaration::isBuiltin() %s\n", toChars());
		if (builtin == BUILTIN.BUILTINunknown)
		{
			builtin = BUILTIN.BUILTINnot;
			if (parent && parent.isModule())
			{
				// If it's in the std.math package
				if (parent.ident == Id.math && parent.parent && parent.parent.ident == Id.std && !parent.parent.parent)
				{
					//printf("deco = %s\n", type.deco);
					if (type.deco == FeZe)
					{
						if (ident == Id.sin)
							builtin = BUILTIN.BUILTINsin;
						else if (ident == Id.cos)
							builtin = BUILTIN.BUILTINcos;
						else if (ident == Id.tan)
							builtin = BUILTIN.BUILTINtan;
						else if (ident == Id._sqrt)
							builtin = BUILTIN.BUILTINsqrt;
						else if (ident == Id.fabs)
							builtin = BUILTIN.BUILTINfabs;
						//printf("builtin = %d\n", builtin);
					}
					// if float or double versions
					else if (type.deco == "FNaNbdZd" || type.deco == "FNaNbfZf")
					{
						if (ident == Id._sqrt)
							builtin = BUILTIN.BUILTINsqrt;
					}
				}
			}
		}

		return builtin;
	}

    override bool isExport()
	{
		return protection == PROT.PROTexport;
	}

    override bool isImportedSymbol()
	{
		//printf("isImportedSymbol()\n");
		//printf("protection = %d\n", protection);
		return (protection == PROT.PROTexport) && !fbody;
	}

    override bool isAbstract()
	{
		return (storage_class & STC.STCabstract) != 0;
	}

    override bool isCodeseg()
	{
		return true;		// functions are always in the code segment
	}

    override bool isOverloadable()
	{
		return 1;			// functions can be overloaded
	}

    bool isPure()
	{
		//printf("FuncDeclaration::isPure() '%s'\n", toChars());
		assert(type.ty == TY.Tfunction);
		return (cast(TypeFunction)this.type).ispure;
	}

	int isSafe()
	{
		assert(type.ty == TY.Tfunction);
		return (cast(TypeFunction)this.type).trust == TRUST.TRUSTsafe;
	}

	int isTrusted()
	{
		assert(type.ty == TY.Tfunction);
		return (cast(TypeFunction)this.type).trust == TRUST.TRUSTtrusted;
	}

    bool isNested()
	{
		//if (!toParent())
		//printf("FuncDeclaration.isNested('%s') parent=%p\n", toChars(), parent);
		//printf("\ttoParent2() = '%s'\n", toParent2().toChars());
		return ((storage_class & STC.STCstatic) == 0) &&
		   (toParent2().isFuncDeclaration() !is null);
	}

    override bool needThis()
	{
		//printf("FuncDeclaration.needThis() '%s'\n", toChars());
		bool needThis = isThis() !is null;

		//printf("\t%d\n", i);
		if (!needThis) {
			if (auto fa = isFuncAliasDeclaration()) {
				needThis = fa.funcalias.needThis();
			}
		}

		return needThis;
	}

    bool isVirtual()
	{
static if (false) {
		printf("FuncDeclaration.isVirtual(%s)\n", toChars());
		printf("isMember:%p isStatic:%d private:%d ctor:%d !Dlinkage:%d\n", isMember(), isStatic(), protection == PROT.PROTprivate, isCtorDeclaration(), linkage != LINK.LINKd);
		printf("result is %d\n",
		isMember() && !(isStatic() || protection == PROT.PROTprivate || protection == PROT.PROTpackage) && toParent().isClassDeclaration());
}
	    Dsymbol p = toParent();
	    return isMember() &&
			!(isStatic() || protection == PROT.PROTprivate || protection == PROT.PROTpackage) &&
			p.isClassDeclaration() &&
			!(p.isInterfaceDeclaration() && isFinal());
	}

    override bool isFinal()
	{
		ClassDeclaration cd;
static if (false) {
		printf("FuncDeclaration.isFinal(%s)\n", toChars());
		printf("%p %d %d %d %d\n", isMember(), isStatic(), protection == PROT.PROTprivate, isCtorDeclaration(), linkage != LINK.LINKd);
		printf("result is %d\n",
		isMember() && !(isStatic() || protection == PROT.PROTprivate || protection == PROT.PROTpackage) && (cd = toParent().isClassDeclaration()) !is null && cd.storage_class & STC.STCfinal);
}
		return isMember() && (Declaration.isFinal() || ((cd = toParent().isClassDeclaration()) !is null && cd.storage_class & STC.STCfinal));
	}

    bool addPreInvariant()
	{
		AggregateDeclaration ad = isThis();
		return (ad &&
			//ad.isClassDeclaration() &&
			global.params.useInvariants &&
			(protection == PROT.PROTpublic || protection == PROT.PROTexport) &&
			!naked &&
			ident !is Id.cpctor);
	}

    bool addPostInvariant()
	{
		AggregateDeclaration ad = isThis();
		return (ad && ad.inv &&
			//ad.isClassDeclaration() &&
			global.params.useInvariants &&
			(protection == PROT.PROTpublic || protection == PROT.PROTexport) &&
			!naked &&
			ident !is Id.cpctor);
	}

	/*************************************
	 * Attempt to interpret a function given the arguments.
	 * Input:
	 *	istate     state for calling function (null if none)
	 *      arguments  function arguments
	 *      thisarg    'this', if a needThis() function, null if not.
	 *
	 * Return result expression if successful, null if not.
	 */
    Expression interpret(InterState istate, Expressions arguments, Expression thisarg = null)
	{
version (LOG) {
		printf("\n********\nFuncDeclaration.interpret(istate = %p) %s\n", istate, toChars());
		printf("cantInterpret = %d, semanticRun = %d\n", cantInterpret, semanticRun);
}
		if (global.errors)
			return null;
version(DMDV1)
{
		if (ident == Id.aaLen)
			return interpret_aaLen(istate, arguments);
		else if (ident == Id.aaKeys)
			return interpret_aaKeys(istate, arguments);
		else if (ident == Id.aaValues)
			return interpret_aaValues(istate, arguments);
}
else version(DMDV2)
{
		if (thisarg && (!arguments || arguments.dim == 0))
		{
			if (ident == Id.length)
				return interpret_length(istate, thisarg);
			else if (ident == Id.keys)
				return interpret_keys(istate, thisarg, this);
			else if (ident == Id.values)
				return interpret_values(istate, thisarg, this);
		}
}

	    if (cantInterpret || semanticRun == PASSsemantic3)
			return null;

		if (!fbody)
		{
			cantInterpret = 1;
			return null;
		}

		if (semanticRun < PASSsemantic3 && scope_)
		{
			semantic3(scope_);
			if (global.errors)	// if errors compiling this function
				return null;
		}
		if (semanticRun < PASSsemantic3done)
			return null;

		Type tb = type.toBasetype();
		assert(tb.ty == Tfunction);
		TypeFunction tf = cast(TypeFunction)tb;
		Type tret = tf.next.toBasetype();
		if (tf.varargs && arguments && parameters && arguments.dim != parameters.dim)
		{
			cantInterpret = 1;
			error("C-style variadic functions are not yet implemented in CTFE");
			return null;
		}

		scope InterState istatex = new InterState();
		istatex.caller = istate;
		istatex.fd = this;
		istatex.localThis = thisarg;

		scope Expressions vsave = new Expressions();		// place to save previous parameter values
		size_t dim = 0;
		if (needThis() && !thisarg)
		{
			cantInterpret = 1;
			// error, no this. Prevent segfault.
			error("need 'this' to access member %s", toChars());
			return null;
		}
		if (arguments)
		{
			dim = arguments.dim;
			assert(!dim || (parameters && (parameters.dim == dim)));
			vsave.setDim(dim);

			/* Evaluate all the arguments to the function,
			 * store the results in eargs[]
			 */
			scope Expressions eargs = new Expressions();
			eargs.setDim(dim);

			for (size_t i = 0; i < dim; i++)
			{
				Expression earg = arguments[i];
				auto arg = Parameter.getNth(tf.parameters, i);

			    if (arg.storageClass & (STCout | STCref | STClazy))
				{
				}
				else
				{	/* Value parameters
				 */
					Type ta = arg.type.toBasetype();
					if (ta.ty == Tsarray && earg.op == TOKaddress)
					{
						/* Static arrays are passed by a simple pointer.
						 * Skip past this to get at the actual arg.
						 */
						earg = (cast(AddrExp)earg).e1;
					}
					earg = earg.interpret(istate ? istate : istatex);
					if (earg is EXP_CANT_INTERPRET)
					{
						cantInterpret = 1;
						return null;
					}
				}
				eargs[i] = earg;
			}

			for (size_t i = 0; i < dim; i++)
			{
				auto earg = eargs[i];
				auto arg = Parameter.getNth(tf.parameters, i);
				auto v = cast(VarDeclaration)parameters[i];
				vsave[i] = v.value;
version (LOG) {
				printf("arg[%d] = %s\n", i, earg.toChars());
}
				if (arg.storageClass & (STCout | STCref) && earg.op==TOKvar)
				{
					/* Bind out or ref parameter to the corresponding
					 * variable v2
					 */
					if (!istate)
					{
						cantInterpret = 1;
						error("%s cannot be by passed by reference at compile time", earg.toChars());
						return null;	// can't bind to non-interpreted vars
					}
					// We need to chase down all of the the passed parameters until
					// we find something that isn't a TOKvar, then create a variable
					// containg that expression.
					VarDeclaration v2;
					while (1)
					{
						VarExp ve = cast(VarExp)earg;
						v2 = ve.var.isVarDeclaration();
						if (!v2)
						{
							cantInterpret = 1;
							return null;
						}
						if (!v2.value || v2.value.op != TOKvar)
							break;
						if ((cast(VarExp)v2.value).var.isSymbolDeclaration())
						{
							// This can happen if v is a struct initialized to
							// 0 using an __initZ SymbolDeclaration from
							// TypeStruct.defaultInit()
							break; // eg default-initialized variable
						}
						earg = v2.value;
					}

					v.value = new VarExp(earg.loc, v2);

					/* Don't restore the value of v2 upon function return
					 */
					assert(istate);
					foreach(size_t j, Dsymbol s2; istate.vars)// (size_t j = 0; j < istate.vars.dim; j++)
					{
						auto vd = cast(VarDeclaration)s2;
						if (vd == v2)
						{
							istate.vars[j] = null;
							break;
						}
					}
				}
				else
				{
					// Value parameters and non-trivial references
					v.value = earg;
				}
version (LOG) {
				printf("interpreted arg[%d] = %s\n", i, earg.toChars());
}
			}
		}
		// Don't restore the value of 'this' upon function return
		if (needThis() && thisarg.op == TOKvar && istate) {
			VarDeclaration thisvar = (cast(VarExp)thisarg).var.isVarDeclaration();
 			foreach (size_t i, Dsymbol s; istate.vars)
			{
				auto v = cast(VarDeclaration)s;
				if (v == thisvar)
				{
					istate.vars[i] = null;
					break;
				}
			}
		}

		/* Save the values of the local variables used
		 */
		scope valueSaves = new Expressions();
		if (istate && !isNested())
		{
			//printf("saving local variables...\n");
			valueSaves.setDim(istate.vars.dim);
			foreach (size_t i, Dsymbol s3; istate.vars)
			{
				if (auto v = cast(VarDeclaration)s3)
				{
					//printf("\tsaving [%d] %s = %s\n", i, v.toChars(), v.value ? v.value.toChars() : "");
					valueSaves[i] = v.value;
					v.value = null;
				}
			}
		}

		Expression e = null;
		while (1)
		{
			e = fbody.interpret(istatex);
			if (e is EXP_CANT_INTERPRET)
			{
version (LOG) {
				printf("function body failed to interpret\n");
}
				e = null;
			}

			/* This is how we deal with a recursive statement AST
			 * that has arbitrary goto statements in it.
			 * Bubble up a 'result' which is the target of the goto
			 * statement, then go recursively down the AST looking
			 * for that statement, then execute starting there.
			 */
			if (e is EXP_GOTO_INTERPRET)
			{
				istatex.start = istatex.gotoTarget;	// set starting statement
				istatex.gotoTarget = null;
			}
			else
				break;
		}
		/* Restore the parameter values
		 */
		for (size_t i = 0; i < dim; i++)
		{
			auto v = cast(VarDeclaration)parameters[i];
			v.value = vsave[i];
		}

		if (istate && !isNested())
		{
			/* Restore the variable values
			 */
			//printf("restoring local variables...\n");
			foreach (size_t i , Dsymbol s3; istate.vars)
			{
				if (auto v = cast(VarDeclaration)s3)
				{
					v.value = valueSaves[i];
					//printf("\trestoring [%d] %s = %s\n", i, v.toChars(), v.value ? v.value.toChars() : "");
				}
			}
		}
		return e;
	}

    override void inlineScan()
	{
		InlineScanState iss;

	version (LOG) {
		printf("FuncDeclaration.inlineScan('%s')\n", toChars());
	}
		///memset(&iss, 0, sizeof(iss));
		iss.fd = this;
		if (fbody)
		{
			inlineNest++;
			fbody = fbody.inlineScan(&iss);
			inlineNest--;
		}
	}

    int canInline(int hasthis, int hdrscan = 0)
	{
		int cost;

//	#define CANINLINE_LOG 0

	version (CANINLINE_LOG) {
		printf("FuncDeclaration.canInline(hasthis = %d, '%s')\n", hasthis, toChars());
	}

		if (needThis() && !hasthis)
			return 0;

	    if (inlineNest || (semanticRun < PASSsemantic3 && !hdrscan))
		{
	version (CANINLINE_LOG) {
			printf("\t1: no, inlineNest = %d, semanticRun = %d\n", inlineNest, semanticRun);
	}
			return 0;
		}

		switch (inlineStatus)
		{
			case ILS.ILSyes:
		version (CANINLINE_LOG) {
				printf("\t1: yes %s\n", toChars());
		}
				return 1;

			case ILS.ILSno:
		version (CANINLINE_LOG) {
				printf("\t1: no %s\n", toChars());
		}
				return 0;

			case ILS.ILSuninitialized:
				break;

			default:
				assert(0);
		}

		if (type)
		{
			assert(type.ty == Tfunction);
			TypeFunction tf = cast(TypeFunction)type;
			if (tf.varargs == 1)	// no variadic parameter lists
				goto Lno;

			/* Don't inline a function that returns non-void, but has
			 * no return expression.
			 */
			if (tf.next && tf.next.ty != Tvoid &&
				!(hasReturnExp & 1) &&
				!hdrscan)
					goto Lno;
		}
		else
		{
			CtorDeclaration ctor = isCtorDeclaration();
			if (ctor && ctor.varargs == 1)
				goto Lno;
		}

		if (
			!fbody ||
			!hdrscan &&
		(
///	static if (false) {
///		isCtorDeclaration() ||	// cannot because need to convert:
///					//	return;
///					// to:
///					//	return this;
///	}
		isSynchronized() ||
		isImportedSymbol() ||
///	version (DMDV2) {
		closureVars.dim ||	// no nested references to this frame
///	} else {
///		nestedFrameRef ||	// no nested references to this frame
///	}
		(isVirtual() && !isFinal())
		   ))
		{
			goto Lno;
		}

		/* If any parameters are Tsarray's (which are passed by reference)
		 * or out parameters (also passed by reference), don't do inlining.
		 */
		if (parameters)
		{
			foreach (Dsymbol s3; parameters)
			{
				auto v = cast(VarDeclaration)s3;
				if (v.isOut() || v.isRef() || v.type.toBasetype().ty == Tsarray)
					goto Lno;
			}
		}

		InlineCostState ics;
		///memset(&ics, 0, sizeof(ics));
		ics.hasthis = hasthis;
		ics.fd = this;
		ics.hdrscan = hdrscan;
		cost = fbody.inlineCost(&ics);
	version (CANINLINE_LOG) {
		printf("cost = %d\n", cost);
	}
		if (cost >= COST_MAX)
			goto Lno;

		if (!hdrscan)    // Don't scan recursively for header content scan
			inlineScan();

	Lyes:
		if (!hdrscan)    // Don't modify inlineStatus for header content scan
			inlineStatus = ILS.ILSyes;
	version (CANINLINE_LOG) {
		printf("\t2: yes %s\n", toChars());
	}
		return 1;

	Lno:
		if (!hdrscan)    // Don't modify inlineStatus for header content scan
			inlineStatus = ILS.ILSno;
	version (CANINLINE_LOG) {
		printf("\t2: no %s\n", toChars());
	}
		return 0;
	}

    Expression doInline(InlineScanState* iss, Expression ethis, Expressions arguments)
	{
		InlineDoState ids = new InlineDoState();
		DeclarationExp de;
		Expression e = null;

	version (LOG) {
		printf("FuncDeclaration.doInline('%s')\n", toChars());
	}

		///memset(&ids, 0, sizeof(ids));
		ids.parent = iss.fd;

		// Set up vthis
		if (ethis)
		{
			VarDeclaration vthis;
			ExpInitializer ei;
			VarExp ve;

		version (STRUCTTHISREF) {
			if (ethis.type.ty == Tpointer)
			{
				Type t = ethis.type.nextOf();
				ethis = new PtrExp(ethis.loc, ethis);
				ethis.type = t;
			}
			ei = new ExpInitializer(ethis.loc, ethis);

			vthis = new VarDeclaration(ethis.loc, ethis.type, Id.This, ei);
			if (ethis.type.ty != Tclass)
				vthis.storage_class = STCref;
			else
				vthis.storage_class = STCin;
		} else {
			if (ethis.type.ty != Tclass && ethis.type.ty != Tpointer)
			{
				ethis = ethis.addressOf(null);
			}

			ei = new ExpInitializer(ethis.loc, ethis);

			vthis = new VarDeclaration(ethis.loc, ethis.type, Id.This, ei);
			vthis.storage_class = STCin;
		}
			vthis.linkage = LINKd;
			vthis.parent = iss.fd;

			ve = new VarExp(vthis.loc, vthis);
			ve.type = vthis.type;

			ei.exp = new AssignExp(vthis.loc, ve, ethis);
			ei.exp.type = ve.type;
		version (STRUCTTHISREF) {
			if (ethis.type.ty != Tclass)
			{
				/* This is a reference initialization, not a simple assignment.
				 */
				ei.exp.op = TOKconstruct;
			}
		}

			ids.vthis = vthis;
		}

		// Set up parameters
		if (ethis)
		{
			e = new DeclarationExp(Loc(0), ids.vthis);
			e.type = Type.tvoid;
		}

		if (arguments && arguments.dim)
		{
			assert(parameters.dim == arguments.dim);

			for (int i = 0; i < arguments.dim; i++)
			{
				auto vfrom = cast(VarDeclaration)parameters[i];
				VarDeclaration vto;
				Expression arg = arguments[i];
				ExpInitializer ei;
				VarExp ve;

				ei = new ExpInitializer(arg.loc, arg);

				vto = new VarDeclaration(vfrom.loc, vfrom.type, vfrom.ident, ei);
				vto.storage_class |= vfrom.storage_class & (STCin | STCout | STClazy | STCref);
				vto.linkage = vfrom.linkage;
				vto.parent = iss.fd;
				//printf("vto = '%s', vto.storage_class = x%x\n", vto.toChars(), vto.storage_class);
				//printf("vto.parent = '%s'\n", iss.fd.toChars());

				ve = new VarExp(vto.loc, vto);
				//ve.type = vto.type;
				ve.type = arg.type;

				ei.exp = new AssignExp(vto.loc, ve, arg);
				ei.exp.type = ve.type;
		//ve.type.print();
		//arg.type.print();
		//ei.exp.print();

				ids.from.push(cast(void*)vfrom);
				ids.to.push(cast(void*)vto);

				de = new DeclarationExp(Loc(0), vto);
				de.type = Type.tvoid;

				e = Expression.combine(e, de);
			}
		}

		inlineNest++;
		Expression eb = fbody.doInline(ids);
		inlineNest--;
	//eb.type.print();
	//eb.print();
	//eb.dump(0);
		return Expression.combine(e, eb);
	}

    override string kind()
	{
		return "function";
	}

    override void toDocBuffer(OutBuffer buf)
	{
		assert(false);
	}

	FuncDeclaration isUnique()
	{
		Unique unique;
		overloadApply(this, unique);

		return unique.f;
	}

	/*******************************
	 * Look at all the variables in this function that are referenced
	 * by nested functions, and determine if a closure needs to be
	 * created for them.
	 */
    bool needsClosure()
	{
		/* Need a closure for all the closureVars[] if any of the
		 * closureVars[] are accessed by a
		 * function that escapes the scope of this function.
		 * We take the conservative approach and decide that any function that:
		 * 1) is a virtual function
		 * 2) has its address taken
		 * 3) has a parent that escapes
		 *
		 * Note that since a non-virtual function can be called by
		 * a virtual one, if that non-virtual function accesses a closure
		 * var, the closure still has to be taken. Hence, we check for isThis()
		 * instead of isVirtual(). (thanks to David Friedman)
		 */

		//printf("FuncDeclaration.needsClosure() %s\n", toChars());
		foreach (Dsymbol s3; closureVars)
		{
			auto v = cast(VarDeclaration)s3;
			assert(v.isVarDeclaration());
			//printf("\tv = %s\n", v.toChars());

			foreach(FuncDeclaration f; v.nestedrefs)
			{
				assert(f != this);

				//printf("\t\tf = %s, %d, %p, %d\n", f.toChars(), f.isVirtual(), f.isThis(), f.tookAddressOf);
				if (f.isThis() || f.tookAddressOf)
					goto Lyes;	// assume f escapes this function's scope

				// Look to see if any parents of f that are below this escape
				for (Dsymbol s = f.parent; s && s !is this; s = s.parent)
				{
					f = s.isFuncDeclaration();
					if (f && (f.isThis() || f.tookAddressOf)) {
						goto Lyes;
					}
				}
			}
		}
		return false;

	Lyes:
		//printf("\tneeds closure\n");
		return true;
	}

    /****************************************************
	 * Merge into this function the 'in' contracts of all it overrides.
	 * 'in's are OR'd together, i.e. only one of them needs to pass.
	 */

	Statement mergeFrequire(Statement sf)
	{
		/* Implementing this is done by having the overriding function call
		 * nested functions (the fdrequire functions) nested inside the overridden
		 * function. This requires that the stack layout of the calling function's
		 * parameters and 'this' pointer be in the same place (as the nested
		 * function refers to them).
		 * This is easy for the parameters, as they are all on the stack in the same
		 * place by definition, since it's an overriding function. The problem is
		 * getting the 'this' pointer in the same place, since it is a local variable.
		 * We did some hacks in the code generator to make this happen:
		 *	1. always generate exception handler frame, or at least leave space for it
		 *     in the frame (Windows 32 SEH only)
		 *	2. always generate an EBP style frame
		 *  3. since 'this' is passed in a register that is subsequently copied into
		 *     a stack local, allocate that local immediately following the exception
		 *     handler block, so it is always at the same offset from EBP.
		 */
		foreach(FuncDeclaration fdv; foverrides) //(int i = 0; i < foverrides.dim; i++)
		{
			sf = fdv.mergeFrequire(sf);
			if (fdv.fdrequire)
			{
				//printf("fdv.frequire: %s\n", fdv.frequire.toChars());
				/* Make the call:
				 *   try { __require(); }
				 *   catch { frequire; }
				 */
				Expression eresult = null;
				Expression e = new CallExp(loc, new VarExp(loc, fdv.fdrequire, 0), eresult);
				Statement s2 = new ExpStatement(loc, e);

				if (sf)
				{
					Catch c = new Catch(loc, null, null, sf);
					Array catches = new Array();
					catches.push(cast(void*)c);
					sf = new TryCatchStatement(loc, s2, catches);
				}
				else
					sf = s2;
			}
		}
		return sf;
	}

    /****************************************************
	 * Merge into this function the 'out' contracts of all it overrides.
	 * 'out's are AND'd together, i.e. all of them need to pass.
	 */

	Statement mergeFensure(Statement sf)
	{
		/* Same comments as for mergeFrequire(), except that we take care
		 * of generating a consistent reference to the 'result' local by
		 * explicitly passing 'result' to the nested function as a reference
		 * argument.
		 * This won't work for the 'this' parameter as it would require changing
		 * the semantic code for the nested function so that it looks on the parameter
		 * list for the 'this' pointer, something that would need an unknown amount
		 * of tweaking of various parts of the compiler that I'd rather leave alone.
		 */
		foreach (FuncDeclaration fdv; foverrides)
		{
			sf = fdv.mergeFensure(sf);
			if (fdv.fdensure)
			{
				//printf("fdv.fensure: %s\n", fdv.fensure.toChars());
				// Make the call: __ensure(result)
				Expression eresult = null;
				if (outId)
					eresult = new IdentifierExp(loc, outId);
				Expression e = new CallExp(loc, new VarExp(loc, fdv.fdensure, 0), eresult);
				Statement s2 = new ExpStatement(loc, e);

				if (sf)
				{
					sf = new CompoundStatement(fensure.loc, s2, sf);
				}
				else
					sf = s2;
			}
		}
		return sf;
	}

    static FuncDeclaration genCfunc(Type treturn, string name)
	{
		return genCfunc(treturn, Lexer.idPool(name));
	}

	/**********************************
	 * Generate a FuncDeclaration for a runtime library function.
	 */
    static FuncDeclaration genCfunc(Type treturn, Identifier id)
	{
		FuncDeclaration fd;
		TypeFunction tf;
		Dsymbol s;

		//printf("genCfunc(name = '%s')\n", id.toChars());
		//printf("treturn\n\t"); treturn.print();

		// See if already in table
		s = global.st.lookup(id);
		if (s)
		{
			debug fd = s.isFuncDeclaration();
			debug assert(fd);
			debug assert(fd.type.nextOf().equals(treturn));
		}
		else
		{
			tf = new TypeFunction(null, treturn, 0, LINK.LINKc);
			fd = new FuncDeclaration(Loc(0), Loc(0), id, STCstatic, tf);
			fd.protection = PROT.PROTpublic;
			fd.linkage = LINK.LINKc;

			global.st.insert(fd);
		}
		return fd;
	}

    override Symbol* toSymbol()
	{
		if (!csym)
		{
			Symbol* s;
			TYPE* t;
			string id;

static if (false) {
			id = ident.toChars();
} else {
			id = mangle();
}
			//writef("FuncDeclaration.toSymbol(%s %s)\n", kind(), toChars());
			//writef("\tid = '%s'\n", id);
			//writef("\ttype = %s\n", type.toChars());
			s = symbol_calloc(toStringz(id));
			slist_add(s);

			{
				s.prettyIdent = toStringz(toPrettyChars());
				s.Sclass = SC.SCglobal;
				symbol_func(s);
				func_t* f = s.Sfunc;
				if (isVirtual())
					f.Fflags |= F.Fvirtual;
				else if (isMember2())
					f.Fflags |= F.Fstatic;
				f.Fstartline.Slinnum = loc.linnum;
				f.Fstartline.Sfilename = cast(char*)toStringz(loc.filename);
				if (endloc.linnum)
				{
					f.Fendline.Slinnum = endloc.linnum;
					f.Fendline.Sfilename = cast(char*)toStringz(endloc.filename);
				}
				else
				{
					f.Fendline.Slinnum = loc.linnum;
					f.Fendline.Sfilename = cast(char*)toStringz(loc.filename);
				}
				t = type.toCtype();
			}

			mangle_t msave = t.Tmangle;
			if (isMain())
			{
				t.Tty = TYM.TYnfunc;
				t.Tmangle = mTYman.mTYman_c;
			}
			else
			{
				switch (linkage)
				{
				case LINK.LINKwindows:
					t.Tmangle = mTYman.mTYman_std;
					break;

				case LINK.LINKpascal:
					t.Tty = TYM.TYnpfunc;
					t.Tmangle = mTYman.mTYman_pas;
					break;

				case LINK.LINKc:
					t.Tmangle = mTYman.mTYman_c;
					break;

				case LINK.LINKd:
					t.Tmangle = mTYman.mTYman_d;
					break;

				case LINK.LINKcpp:
				{   t.Tmangle = mTYman.mTYman_cpp;
		version (TARGET_WINDOS) {
					if (isThis())
						t.Tty = TYM.TYmfunc;
		}
					s.Sflags |= SFL.SFLpublic;
					Dsymbol parent = toParent();
					ClassDeclaration cd = parent.isClassDeclaration();
					if (cd)
					{
						.type* tt = cd.type.toCtype();
						s.Sscope = tt.Tnext.Ttag;
					}
					break;
				}
				default:
					writef("linkage = %d\n", linkage);
					assert(0);
				}
			}
			if (msave)
				assert(msave == t.Tmangle);
			//printf("Tty = %x, mangle = x%x\n", t.Tty, t.Tmangle);
			t.Tcount++;
			s.Stype = t;
				//s.Sfielddef = this;

			csym = s;
		}
		return csym;
	}

    Symbol* toThunkSymbol(int offset)	// thunk version
	{
		Symbol *sthunk;

		toSymbol();

	static if (false) {
		char *id;
		char *n;
		type *t;

		n = sym.Sident;
		version (Bug4054) {
			id = cast(char*) GC.malloc(8 + 5 + strlen(n) + 1);
		} else {
			id = cast(char*) alloca(8 + 5 + strlen(n) + 1);
		}
		sprintf(id, "_thunk%d__%s", offset, n);
		s = symbol_calloc(id);
		slist_add(s);
		s.Stype = csym.Stype;
		s.Stype.Tcount++;
	}
		sthunk = symbol_generate(SCstatic, csym.Stype);
		sthunk.Sflags |= SFLimplem;
		cod3_thunk(sthunk, csym, 0, TYnptr, -offset, -1, 0);
		return sthunk;
	}

    override void toObjFile(int multiobj)			// compile to .obj file
	{
		Symbol* s;
		func_t* f;
		Symbol* senter;
		Symbol* sexit;

		FuncDeclaration func = this;
		ClassDeclaration cd = func.parent.isClassDeclaration();
		int reverse;

		int has_arguments;

		//printf("FuncDeclaration.toObjFile(%p, %s.%s)\n", func, parent.toChars(), func.toChars());
static if (false)
{
		//printf("line = %d\n",func.getWhere() / LINEINC);
		EEcontext ee = env.getEEcontext();
		if (ee.EEcompile == 2)
		{
			if (ee.EElinnum < (func.getWhere() / LINEINC) ||
				ee.EElinnum > (func.endwhere / LINEINC)
			)
			return;		// don't compile this function
			ee.EEfunc = func.toSymbol();
		}
}

		if (multiobj && !isStaticDtorDeclaration() && !isStaticCtorDeclaration())
		{
			obj_append(this);
			return;
		}

		if (semanticRun >= PASSobj)	// if toObjFile() already run
			return;
		semanticRun = PASSobj;

		if (!func.fbody)
		{
			return;
		}

		if (func.isUnitTestDeclaration() && !global.params.useUnitTests)
			return;

		if (global.params.verbose)
			writef("function  %s\n",func.toChars());

		s = func.toSymbol();
		f = s.Sfunc;

version (TARGET_WINDOS)
{
    /* This is done so that the 'this' pointer on the stack is the same
     * distance away from the function parameters, so that an overriding
     * function can call the nested fdensure or fdrequire of its overridden function
     * and the stack offsets are the same.
     */
    if (isVirtual() && (fensure || frequire))
		f.Fflags3 |= F3.Ffakeeh;
}

version (TARGET_OSX) {
		s.Sclass = SC.SCcomdat;
} else {
		s.Sclass = SC.SCglobal;
}

		for (Dsymbol p = parent; p; p = p.parent)
		{
			if (p.isTemplateInstance())
			{
				s.Sclass = SC.SCcomdat;
				break;
			}
		}

		if (isNested())
		{
		//	if (!(config.flags3 & CFG3pic))
		//	    s.Sclass = SCstatic;
			f.Fflags3 |= F3.Fnested;
		}
		else
		{
			const(char)* libname = (global.params.symdebug) ? global.params.debuglibname : global.params.defaultlibname;

			// Pull in RTL startup code
			if (func.isMain())
			{   
				objextdef("_main");
version (POSIX) { ///TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
				obj_ehsections();	// initialize exception handling sections
}
version (TARGET_WINDOS) {
				objextdef("__acrtused_con");
}
				obj_includelib(libname);
				s.Sclass = SC.SCglobal;
			}
			else if (strcmp(s.Sident.ptr, "main".ptr) == 0 && linkage == LINK.LINKc)
			{
version (TARGET_WINDOS) {
				objextdef("__acrtused_con");	// bring in C startup code
				obj_includelib("snn.lib");		// bring in C runtime library
}
				s.Sclass = SCglobal;
			}
			else if (func.isWinMain())
			{
				objextdef("__acrtused");
				obj_includelib(libname);
				s.Sclass = SC.SCglobal;
			}

			// Pull in RTL startup code
			else if (func.isDllMain())
			{
				objextdef("__acrtused_dll");
				obj_includelib(libname);
				s.Sclass = SC.SCglobal;
			}
		}

		cstate.CSpsymtab = &f.Flocsym;

		// Find module m for this function
		Module m = null;
		for (Dsymbol p = parent; p; p = p.parent)
		{
			m = p.isModule();
			if (m)
				break;
		}

		IRState irs = IRState(m, func);
		Array deferToObj = new Array();			// write these to OBJ file later
		irs.deferToObj = deferToObj;

		TypeFunction tf;
		RET retmethod;
		Symbol* shidden = null;
		Symbol* sthis = null;
		tym_t tyf;

		tyf = tybasic(s.Stype.Tty);
		//printf("linkage = %d, tyf = x%x\n", linkage, tyf);
		reverse = tyrevfunc(s.Stype.Tty);

		assert(func.type.ty == TY.Tfunction);
		tf = cast(TypeFunction)(func.type);
		has_arguments = (tf.linkage == LINK.LINKd) && (tf.varargs == 1);
		retmethod = tf.retStyle();
		if (retmethod == RET.RETstack)
		{
			// If function returns a struct, put a pointer to that
			// as the first argument
			.type* thidden = tf.next.pointerTo().toCtype();
			char[5+4+1] hiddenparam;
			sprintf(hiddenparam.ptr, "__HID%d".ptr, ++global.hiddenparami);
			shidden = symbol_name(hiddenparam.ptr, SC.SCparameter, thidden);
			shidden.Sflags |= SFL.SFLtrue | SFL.SFLfree;

version (DMDV1) {
			bool nestedref = func.nrvo_can && func.nrvo_var && func.nrvo_var.nestedref;
} else {
			bool nestedref = func.nrvo_can && func.nrvo_var && (func.nrvo_var.nestedrefs.dim != 0);
}
			if (nestedref) {
				type_setcv(&shidden.Stype, shidden.Stype.Tty | mTY.mTYvolatile);
			}

			irs.shidden = shidden;
			this.shidden = shidden;
		}

		if (vthis)
		{
			assert(!vthis.csym);
			sthis = vthis.toSymbol();
			irs.sthis = sthis;
			if (!(f.Fflags3 & F3.Fnested))
				f.Fflags3 |= F3.Fmember;
		}

		Symbol** params;
		uint pi;

		// Estimate number of parameters, pi
		pi = (v_arguments !is null);
		if (parameters)
			pi += parameters.dim;

		// Allow extra 2 for sthis and shidden
version (Bug4054)
		params = cast(Symbol**)GC.malloc((pi + 2) * (Symbol*).sizeof);
else
		params = cast(Symbol**)alloca((pi + 2) * (Symbol*).sizeof);

		// Get the actual number of parameters, pi, and fill in the params[]
		pi = 0;
		if (v_arguments)
		{
			params[pi] = v_arguments.toSymbol();
			pi += 1;
		}
		if (parameters)
		{
			size_t i = 0;
			for ( ; i < parameters.dim; ++i)
			{
				auto v = cast(VarDeclaration)parameters[i];

				if (v.csym)
				{
					error("compiler error, parameter '%s', bugzilla 2962?", v.toChars());
					assert(false);
				}
				params[pi + i] = v.toSymbol();
			}
			pi += i;
		}

		if (reverse)
		{
			// Reverse params[] entries
			for (size_t i = 0; i < pi/2; i++)
			{
				Symbol* sptmp = params[i];
				params[i] = params[pi - 1 - i];
				params[pi - 1 - i] = sptmp;
			}
		}

		if (shidden)
		{
static if (false) {
			// shidden becomes last parameter
			params[pi] = shidden;
} else {
			// shidden becomes first parameter
			memmove(params + 1, params, pi * (*params).sizeof);
			params[0] = shidden;
}
			pi++;
		}


		if (sthis)
		{
static if (false) {
			// sthis becomes last parameter
			params[pi] = sthis;
} else {
			// sthis becomes first parameter
			memmove(params + 1, params, pi * (*params).sizeof);
			params[0] = sthis;
}
			pi++;
		}

		if ((global.params.isLinux || global.params.isOSX || global.params.isFreeBSD || global.params.isSolaris) &&
			linkage != LINK.LINKd && shidden && sthis)
		{
			/* swap shidden and sthis
			 */
			Symbol* sp = params[0];
			params[0] = params[1];
			params[1] = sp;
		}

		for (size_t i = 0; i < pi; i++)
		{
			Symbol *sp = params[i];
			sp.Sclass = SC.SCparameter;
			sp.Sflags &= ~SFL.SFLspill;
			sp.Sfl = FL.FLpara;
			symbol_add(sp);
		}

		// First parameter goes in register
		if (pi)
		{
			Symbol* sp = params[0];
			if ((tyf == TYM.TYjfunc || tyf == TYM.TYmfunc) && type_jparam(sp.Stype))
			{
				sp.Sclass = SC.SCfastpar;
				sp.Spreg = (tyf == TYM.TYjfunc) ? REG.AX : REG.CX;
				sp.Sfl = FL.FLauto;
				//printf("'%s' is SCfastpar\n",sp.Sident);
			}
		}

		if (func.fbody)
		{
			block* b;
			Blockx bx;
			Statement sbody;

			global.localgot = null;

			sbody = func.fbody;
			///memset(&bx, 0, (bx).sizeof);
			bx.startblock = block_calloc();
			bx.curblock = bx.startblock;
			bx.funcsym = s;
			bx.scope_index = -1;
			bx.classdec = cd;
			bx.member = func;
			bx.module_ = getModule();
			irs.blx = &bx;

			buildClosure(&irs);

static if (false) {
			if (func.isSynchronized())
			{
				if (cd)
				{
					elem *esync;
					if (func.isStatic())
					{   // monitor is in ClassInfo
						esync = el_ptr(cd.toSymbol());
					}
					else
					{   // 'this' is the monitor
						esync = el_var(sthis);
					}

					if (func.isStatic() || sbody.usesEH() ||
						!(config.flags2 & CFG2.CFG2seh))
					{   // BUG: what if frequire or fensure uses EH?

						sbody = new SynchronizedStatement(func.loc, esync, sbody);
					}
					else
					{
		version (TARGET_WINDOS) {
						if (config.flags2 & CFG2.CFG2seh)
						{
							/* The "jmonitor" uses an optimized exception handling frame
							 * which is a little shorter than the more general EH frame.
							 * It isn't strictly necessary.
							 */
							s.Sfunc.Fflags3 |= Fjmonitor;
						}
			}
						el_free(esync);
					}
				}
				else
				{
					error("synchronized function %s must be a member of a class", func.toChars());
				}
			}
} else version (TARGET_WINDOS) {
			if (func.isSynchronized() && cd && config.flags2 & CFG2.CFG2seh &&
				!func.isStatic() && !sbody.usesEH())
			{
				/* The "jmonitor" hack uses an optimized exception handling frame
				 * which is a little shorter than the more general EH frame.
				 */
				s.Sfunc.Fflags3 |= F3.Fjmonitor;
			}
}

			sbody.toIR(&irs);
			bx.curblock.BC = BC.BCret;

			f.Fstartblock = bx.startblock;
		//	einit = el_combine(einit,bx.init);

			if (isCtorDeclaration())
			{
				assert(sthis);
				for (b = f.Fstartblock; b; b = b.Bnext)
				{
					if (b.BC == BC.BCret)
					{
						b.BC = BC.BCretexp;
						b.Belem = el_combine(b.Belem, el_var(sthis));
					}
				}
			}
		}

		// If static constructor
		if (isSharedStaticCtorDeclaration())	// must come first because it derives from StaticCtorDeclaration
		{
			elem* e = el_una(OPucall, TYvoid, el_var(s));
			global.esharedctor = el_combine(global.esharedctor, e);
		}
		else if (isStaticCtorDeclaration())
		{
			elem* e = el_una(OPucall, TYvoid, el_var(s));
			global.ector = el_combine(global.ector, e);
		}

		// If static destructor
		if (auto f_ = isSharedStaticDtorDeclaration())	// must come first because it derives from StaticDtorDeclaration
		{
			elem* e;

version (STATICCTOR) {
			e = el_bin(OPcall, TYvoid, el_var(rtlsym[RTLSYM_FATEXIT]), el_ptr(s));
			esharedctor = el_combine(esharedctor, e);
			shareddtorcount++;
} else {
			if (f_.vgate)
			{   
				/* Increment destructor's vgate at construction time
				 */
				global.esharedctorgates.push(cast(void*)f_);
			}

			e = el_una(OPucall, TYvoid, el_var(s));
			global.eshareddtor = el_combine(e, global.eshareddtor);
}
		}
		else if (auto f_ = isStaticDtorDeclaration())
		{
			elem* e;

version (STATICCTOR) {
			e = el_bin(OPcall, TYvoid, el_var(rtlsym[RTLSYM_FATEXIT]), el_ptr(s));
			global.ector = el_combine(ector, e);
			dtorcount++;
} else {
			if (f_.vgate)
			{   /* Increment destructor's vgate at construction time
				 */
				global.ectorgates.push(cast(void*)f_);
			}

			e = el_una(OPucall, TYvoid, el_var(s));
			global.edtor = el_combine(e, global.edtor);
}
		}

		// If unit test
		if (isUnitTestDeclaration())
		{
			elem* e = el_una(OPER.OPucall, TYM.TYvoid, el_var(s));
			global.etest = el_combine(global.etest, e);
		}

		if (global.errors)
			return;

		writefunc(s);

		if (isExport()) {
			obj_export(s, Poffset);
		}

		for (size_t i = 0; i < irs.deferToObj.dim; i++)
		{
			Dsymbol ss = cast(Dsymbol)irs.deferToObj.data[i];
			ss.toObjFile(0);
		}

version (POSIX) { ///TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
		// A hack to get a pointer to this function put in the .dtors segment
		if (ident && ident.toChars() == "_STD") {
			obj_staticdtor(s);
		}
}
version (DMDV2) {
		if (irs.startaddress)
		{
			writef("Setting start address\n");
			obj_startaddress(irs.startaddress);
		}
}
	}

    override int cvMember(ubyte* p)
	{
		assert(false);
	}

	/*************************************
	 * Closures are implemented by taking the local variables that
	 * need to survive the scope of the function, and copying them
	 * into a gc allocated chuck of memory. That chunk, called the
	 * closure here, is inserted into the linked list of stack
	 * frames instead of the usual stack frame.
	 *
	 * buildClosure() inserts code just after the function prolog
	 * is complete. It allocates memory for the closure, allocates
	 * a local variable (sclosure) to point to it, inserts into it
	 * the link to the enclosing frame, and copies into it the parameters
	 * that are referred to in nested functions.
	 * In VarExp.toElem and SymOffExp.toElem, when referring to a
	 * variable that is in a closure, takes the offset from sclosure rather
	 * than from the frame pointer.
	 *
	 * getEthis() and NewExp.toElem need to use sclosure, if set, rather
	 * than the current frame pointer.
	 */
    void buildClosure(IRState* irs)
	{
		if (needsClosure())
		{
			// Generate closure on the heap
			// BUG: doesn't capture variadic arguments passed to this function

		version (DMDV2) {
			/* BUG: doesn't handle destructors for the local variables.
			 * The way to do it is to make the closure variables the fields
			 * of a class object:
			 *    class Closure
			 *    {   vtbl[]
			 *	  monitor
			 *	  ptr to destructor
			 *	  sthis
			 *	  ... closure variables ...
			 *	  ~this() { call destructor }
			 *    }
			 */
		}
			//printf("FuncDeclaration.buildClosure()\n");
			Symbol* sclosure;
			sclosure = symbol_name("__closptr".ptr, SC.SCauto, global.tvoidptr.toCtype());
			sclosure.Sflags |= SFL.SFLtrue | SFL.SFLfree;
			symbol_add(sclosure);
			irs.sclosure = sclosure;

			uint offset = PTRSIZE;	// leave room for previous sthis
			foreach (Dsymbol s3; closureVars)
			{
				auto v = cast(VarDeclaration)s3;
				assert(v.isVarDeclaration());

		version (DMDV2) {
				if (v.needsAutoDtor())
					v.error("has scoped destruction, cannot build closure");
		}
				/* Align and allocate space for v in the closure
				 * just like AggregateDeclaration.addField() does.
				 */
				uint memsize;
				uint memalignsize;
				uint xalign;
///		version (DMDV2) {
				if (v.storage_class & STC.STClazy)
				{
					/* Lazy variables are really delegates,
					 * so give same answers that TypeDelegate would
					 */
					memsize = PTRSIZE * 2;
					memalignsize = memsize;
					xalign = global.structalign;
				}
				else
///		}
				{
					memsize = cast(uint)v.type.size();
					memalignsize = v.type.alignsize();
					xalign = v.type.memalign(global.structalign);
				}
				AggregateDeclaration.alignmember(xalign, memalignsize, &offset);
				v.offset = offset;
				offset += memsize;

				/* Can't do nrvo if the variable is put in a closure, since
				 * what the shidden points to may no longer exist.
				 */
				if (nrvo_can && nrvo_var == v)
				{
					nrvo_can = 0;
				}
			}
			// offset is now the size of the closure

			// Allocate memory for the closure
			elem* e;
			e = el_long(TYM.TYint, offset);
			e = el_bin(OPER.OPcall, TYM.TYnptr, el_var(rtlsym[RTLSYM.RTLSYM_ALLOCMEMORY]), e);

			// Assign block of memory to sclosure
			//    sclosure = allocmemory(sz);
			e = el_bin(OPER.OPeq, TYM.TYvoid, el_var(sclosure), e);

			// Set the first element to sthis
			//    *(sclosure + 0) = sthis;
			elem* ethis;
			if (irs.sthis)
				ethis = el_var(irs.sthis);
			else
				ethis = el_long(TYM.TYnptr, 0);
			elem *ex = el_una(OPER.OPind, TYM.TYnptr, el_var(sclosure));
			ex = el_bin(OPER.OPeq, TYM.TYnptr, ex, ethis);
			e = el_combine(e, ex);

			// Copy function parameters into closure
			foreach (Dsymbol s3; closureVars)
			{   auto v = cast(VarDeclaration)s3;

				if (!v.isParameter())
					continue;
				TYM tym = v.type.totym();
				if (v.type.toBasetype().ty == TY.Tsarray || v.isOut() || v.isRef())
					tym = TYM.TYnptr;	// reference parameters are just pointers
///		version (DMDV2) {
				else if (v.storage_class & STC.STClazy)
					tym = TYM.TYdelegate;
///		}
				ex = el_bin(OPER.OPadd, TYM.TYnptr, el_var(sclosure), el_long(TYM.TYint, v.offset));
				ex = el_una(OPER.OPind, tym, ex);
				if (ex.Ety == TYM.TYstruct)
				{
					ex.Enumbytes = cast(uint)v.type.size();
					ex = el_bin(OPER.OPstreq, tym, ex, el_var(v.toSymbol()));
					ex.Enumbytes = cast(uint)v.type.size();
				}
				else
				{
					ex = el_bin(OPER.OPeq, tym, ex, el_var(v.toSymbol()));
				}

				e = el_combine(e, ex);
			}

			block_appendexp(irs.blx.curblock, e);
		}
	}

    /*********************************************
     * Return the function's parameter list, and whether
     * it is variadic or not.
     */

    Parameters getParameters(int *pvarargs)
    {
        Parameters fparameters;
        int fvarargs;

        if (type)
        {
	        assert(type.ty == Tfunction);
	        auto fdtype = cast(TypeFunction)type;
	        fparameters = fdtype.parameters;
	        fvarargs = fdtype.varargs;
        }
        else // Constructors don't have type's
        {
            CtorDeclaration fctor = isCtorDeclaration();
	        assert(fctor);
	        fparameters = fctor.arguments;
	        fvarargs = fctor.varargs;
        }
        if (pvarargs)
	    *pvarargs = fvarargs;
        return fparameters;
    }

    override FuncDeclaration isFuncDeclaration() { return this; }
}

alias Vector!FuncDeclaration FuncDeclarations;
