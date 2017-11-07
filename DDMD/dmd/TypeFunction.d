module dmd.TypeFunction;

import dmd.common;
import dmd.TypeNext;
import dmd.TypeSArray;
import dmd.TypeArray;
import dmd.TemplateTupleParameter;
import dmd.ArrayTypes;
import dmd.LINK;
import dmd.StructDeclaration;
import dmd.TypeStruct;
import dmd.Global;
import dmd.STC;
import dmd.MOD;
import dmd.PROT;
import dmd.TypeIdentifier;
import dmd.TemplateParameter;
import dmd.TypeInfoFunctionDeclaration;
import dmd.Tuple;
import dmd.Type;
import dmd.Loc;
import dmd.Scope;
import dmd.Identifier;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.CppMangleState;
import dmd.TypeInfoDeclaration;
import dmd.MATCH;
import dmd.Parameter;
import dmd.Expression;
import dmd.RET;
import dmd.TY;
import dmd.TRUST;
import dmd.Util;
import dmd.FuncDeclaration;
import dmd.Dsymbol;
import dmd.TypeTuple;
import dmd.TemplateInstance : isTuple;

import dmd.backend.TYPE;
import dmd.backend.PARAM;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.TF;
import dmd.backend.mTY;

import core.stdc.stdlib;
import core.stdc.string;

import std.stdio;

import dmd.DDMDExtensions;

class TypeFunction : TypeNext
{
	mixin insertMemberExtension!(typeof(this));

    // .next is the return type

    Parameters parameters;	// function parameters
    int varargs;	// 1: T t, ...) style for variable number of arguments
			// 2: T t ...) style for variable number of arguments
    bool isnothrow;	// true: nothrow
    bool ispure;	// true: pure
    bool isproperty;	// can be called without parentheses
    bool isref;		// true: returns a reference
    LINK linkage;	// calling convention
    TRUST trust;	// level of trust
    Expressions fargs;	// function arguments

    int inuse;

    this(Parameters parameters, Type treturn, int varargs, LINK linkage)
	{
		register();
		super(TY.Tfunction, treturn);

		//if (!treturn) *(char*)0=0;
	//    assert(treturn);
		assert(0 <= varargs && varargs <= 2);
		this.parameters = parameters;
		this.varargs = varargs;
		this.linkage = linkage;
        this.trust = TRUSTdefault;
	}
	
    override Type syntaxCopy()
	{
		Type treturn = next ? next.syntaxCopy() : null;
		auto params = Parameter.arraySyntaxCopy(parameters);
		TypeFunction t = new TypeFunction(params, treturn, varargs, linkage);
		t.mod = mod;
		t.isnothrow = isnothrow;
		t.ispure = ispure;
		t.isproperty = isproperty;
		t.isref = isref;
        t.trust = trust;
        t.fargs = fargs;

		return t;
	}

    override Type semantic(Loc loc, Scope sc)
	{
		if (deco)			// if semantic() already run
		{
			//printf("already done\n");
			return this;
		}
		//printf("TypeFunction.semantic() this = %p\n", this);
		//printf("TypeFunction::semantic() %s, sc->stc = %llx, fargs = %p\n", toChars(), sc->stc, fargs);

		/* Copy in order to not mess up original.
		 * This can produce redundant copies if inferring return type,
		 * as semantic() will get called again on this.
		 */

		TypeFunction tf = cloneThis(this);

		if (sc.stc & STC.STCpure)
			tf.ispure = true;
		if (sc.stc & STC.STCnothrow)
			tf.isnothrow = true;
		if (sc.stc & STC.STCref)
			tf.isref = true;
        if (sc.stc & STCsafe)
    	    tf.trust = TRUST.TRUSTsafe;
        if (sc.stc & STCtrusted)
    	    tf.trust = TRUST.TRUSTtrusted;
        if (sc.stc & STCproperty)
	        tf.isproperty = true;
        
		tf.linkage = sc.linkage;
        
        /* If the parent is @safe, then this function defaults to safe
         * too.
         */
        if (tf.trust == TRUST.TRUSTdefault)
	        for (Dsymbol p = sc.func; p; p = p.toParent2())
	        {   FuncDeclaration fd = p.isFuncDeclaration();
	            if (fd)
	            {
    		        if (fd.isSafe())
		                tf.trust = TRUST.TRUSTsafe;		// default to @safe
		            break;
	            }
	        }

        bool wildreturn = false;
		if (tf.next)
		{
			tf.next = tf.next.semantic(loc,sc);
version(SARRAYVALUE) {} else
{
			if (tf.next.toBasetype().ty == TY.Tsarray)
			{   
				error(loc, "functions cannot return static array %s", tf.next.toChars());
				tf.next = Type.terror;
			}
}
			if (tf.next.toBasetype().ty == TY.Tfunction)
			{   
				error(loc, "functions cannot return a function");
				tf.next = Type.terror;
			}
			if (tf.next.toBasetype().ty == TY.Ttuple)
			{   
				error(loc, "functions cannot return a tuple");
				tf.next = Type.terror;
			}
			if (tf.next.isauto() && !(sc.flags & SCOPE.SCOPEctor))
				error(loc, "functions cannot return scope %s", tf.next.toChars());
	        if (tf.next.toBasetype().ty == TY.Tvoid)
	            tf.isref = false;			// rewrite "ref void" as just "void"
	        if (tf.next.isWild())
	            wildreturn = true;
        }

        bool wildparams = false;
        bool wildsubparams = false;
		if (tf.parameters)
		{	
			/* Create a scope for evaluating the default arguments for the parameters
			 */
			Scope argsc = sc.push();
			argsc.stc = STCundefined;			// don't inherit storage class
			argsc.protection = PROT.PROTpublic;

			size_t dim = Parameter.dim(tf.parameters);

			for (size_t i = 0; i < dim; i++)
			{   auto fparam = Parameter.getNth(tf.parameters, i);

				tf.inuse++;
				fparam.type = fparam.type.semantic(loc, argsc);
				if (tf.inuse == 1) tf.inuse--;

				fparam.type = fparam.type.addStorageClass(fparam.storageClass);

				if (fparam.storageClass & (STC.STCauto | STC.STCalias | STC.STCstatic))
				{
					if (!fparam.type)
					continue;
				}

				Type t = fparam.type.toBasetype();

				if (fparam.storageClass & (STC.STCout | STC.STCref | STC.STClazy))
				{
					//if (t.ty == TY.Tsarray)
						//error(loc, "cannot have out or ref parameter of type %s", t.toChars());
					if (fparam.storageClass & STC.STCout && fparam.type.mod & (STCconst | STCimmutable))
						error(loc, "cannot have const or immutabl out parameter of type %s", t.toChars());
				}
				if (!(fparam.storageClass & STC.STClazy) && t.ty == TY.Tvoid)
					error(loc, "cannot have parameter of type %s", fparam.type.toChars());

	            if (t.isWild())
	            {
		            wildparams = true;
		            if (tf.next && !wildreturn)
		                error(loc, "inout on parameter means inout must be on return type as well (if from D1 code, replace with 'ref')");
	            }
	            else if (!wildsubparams && t.hasWild())
		            wildsubparams = true;

	            if (fparam.defaultArg)
	            {
		            fparam.defaultArg = fparam.defaultArg.semantic(argsc);
		            fparam.defaultArg = resolveProperties(argsc, fparam.defaultArg);
		            fparam.defaultArg = fparam.defaultArg.implicitCastTo(argsc, fparam.type);
	            }

				/* If fparam turns out to be a tuple, the number of parameters may
				 * change.
				 */
				if (t.ty == TY.Ttuple)
	            {
		        // Propagate storage class from tuple parameters to their element-parameters.
		            auto tt = cast(TypeTuple)t;
		            if (tt.arguments)
		            {
		                auto tdim = tt.arguments.dim;
		                foreach (narg; tt.arguments)
		                {
			                narg.storageClass = fparam.storageClass;
		                }
		            }

		            /* Reset number of parameters, and back up one to do this fparam again,
		             * now that it is the first element of a tuple
		             */
		            dim = Parameter.dim(tf.parameters);
					i--;
                    continue;
				}

	            /* Resolve "auto ref" storage class to be either ref or value,
	             * based on the argument matching the parameter
	             */
	            if (fparam.storageClass & STC.STCauto)
	            {
		            if (fargs && i < fargs.dim)
		            {
                        auto farg = fargs[i];
		                if (farg.isLvalue())
                            {}				// ref parameter
		                else
			                fparam.storageClass &= ~STC.STCref;	// value parameter
		            }
		            else
		                error(loc, "auto can only be used for template function parameters");
	            }
			}
			argsc.pop();
		}

        if (wildreturn && !wildparams)
	    error(loc, "inout on return means inout must be on a parameter as well for %s", toChars());
        if (wildsubparams && wildparams)
	    error(loc, "inout must be all or none on top level for %s", toChars());

		if (tf.next)
		tf.deco = tf.merge().deco;

		if (tf.inuse)
		{	error(loc, "recursive type");
			tf.inuse = 0;
			return terror;
		}

        if (tf.isproperty && (tf.varargs || Parameter.dim(tf.parameters) > 1))
	    error(loc, "properties can only have zero or one parameter");

		if (tf.varargs == 1 && tf.linkage != LINK.LINKd && Parameter.dim(tf.parameters) == 0)
			error(loc, "variadic functions with non-D linkage must have at least one parameter");

		/* Don't return merge(), because arg identifiers and default args
		 * can be different
		 * even though the types match
		 */
		return tf;
	}
	
    override void toDecoBuffer(OutBuffer buf, int flag)
	{
		ubyte mc;

		//printf("TypeFunction.toDecoBuffer() this = %p %s\n", this, toChars());
		//static int nest; if (++nest == 50) *(char*)0=0;
		if (inuse)
		{	
			inuse = 2;		// flag error to caller
			return;
		}
		inuse++;
        MODtoDecoBuffer(buf, mod);
		switch (linkage)
		{
			case LINK.LINKd:		mc = 'F';	break;
			case LINK.LINKc:		mc = 'U';	break;
			case LINK.LINKwindows:	mc = 'W';	break;
			case LINK.LINKpascal:	mc = 'V';	break;
			case LINK.LINKcpp:		mc = 'R';	break;
			default:
				writef("linkage: %d\n", linkage);
				assert(false, "ICE: undefined linkage occured");
		}
		buf.writeByte(mc);
		if (ispure || isnothrow || isproperty || isref || trust)
		{
			if (ispure)
				buf.writestring("Na");
			if (isnothrow)
				buf.writestring("Nb");
			if (isref)
				buf.writestring("Nc");
			if (isproperty)
				buf.writestring("Nd");
	        switch (trust)
	        {
	            case TRUST.TRUSTtrusted:
		            buf.writestring("Ne");
		            break;
	            case TRUST.TRUSTsafe:
		            buf.writestring("Nf");
		            break;
                default:
	        }
		}
		// Write argument types
		Parameter.argsToDecoBuffer(buf, parameters);
		//if (buf.data[buf.offset - 1] == '@') halt();
		buf.writeByte('Z' - varargs);	// mark end of arg list
		assert(next);
		next.toDecoBuffer(buf);
		inuse--;
	}
	
    override void toCBuffer(OutBuffer buf, Identifier ident, HdrGenState* hgs)
	{
		//printf("TypeFunction.toCBuffer() this = %p\n", this);
		string p = null;

		if (inuse)
		{	
			inuse = 2;		// flag error to caller
			return;
		}
		inuse++;

		/* Use 'storage class' style for attributes
		 */
	    if (mod)
        {
	        MODtoBuffer(buf, mod);
	        buf.writeByte(' ');
        }

		if (ispure)
			buf.writestring("pure ");
		if (isnothrow)
			buf.writestring("nothrow ");
		if (isproperty)
			buf.writestring("@property ");
		if (isref)
			buf.writestring("ref ");

        switch (trust)
        {
	    case TRUST.TRUSTtrusted:
	        buf.writestring("@trusted ");
	        break;

	    case TRUST.TRUSTsafe:
	        buf.writestring("@safe ");
	        break;

		default:
        }

		if (next && (!ident || ident.toHChars2() == ident.toChars()))
			next.toCBuffer2(buf, hgs, MODundefined);
		if (hgs.ddoc != 1)
		{
			switch (linkage)
			{
				case LINKd:		p = null;	break;
				case LINKc:		p = " C";	break;
				case LINKwindows:	p = " Windows";	break;
				case LINKpascal:	p = " Pascal";	break;
				case LINKcpp:	p = " C++";	break;
				default:
				assert(0);
			}
		}

		if (!hgs.hdrgen && p)
			buf.writestring(p);
		if (ident)
		{   
			buf.writeByte(' ');
			buf.writestring(ident.toHChars2());
		}
		Parameter.argsToCBuffer(buf, hgs, parameters, varargs);
		inuse--;
	}
	
    override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		//printf("TypeFunction::toCBuffer2() this = %p, ref = %d\n", this, isref);
		string p;

		if (inuse)
		{
			inuse = 2;		// flag error to caller
			return;
		}

		inuse++;
		if (next)
			next.toCBuffer2(buf, hgs, MODundefined);

		if (hgs.ddoc != 1)
		{
			switch (linkage)
			{
				case LINKd:			p = null;		break;
				case LINKc:			p = "C ";		break;
				case LINKwindows:	p = "Windows ";	break;
				case LINKpascal:	p = "Pascal ";	break;
				case LINKcpp:		p = "C++ ";		break;
				default: assert(0);
			}
		}

		if (!hgs.hdrgen && p)
			buf.writestring(p);
		buf.writestring(" function");
		Parameter.argsToCBuffer(buf, hgs, parameters, varargs);

		/* Use postfix style for attributes
		 */
		if (mod != this.mod)
		{
			modToBuffer(buf);
		}

		if (ispure)
			buf.writestring(" pure");
		if (isnothrow)
			buf.writestring(" nothrow");
		if (isproperty)
			buf.writestring(" @property");
		if (isref)
			buf.writestring(" ref");

        switch (trust)
        {
	    case TRUSTtrusted:
	        buf.writestring(" @trusted");
	        break;

	    case TRUSTsafe:
	        buf.writestring(" @safe");
	        break;

		default:
        }
		inuse--;
	}
	
    override MATCH deduceType(Scope sc, Type tparam, TemplateParameters parameters, Objects dedtypes)
	{
		//printf("TypeFunction.deduceType()\n");
		//printf("\tthis   = %d, ", ty); print();
		//printf("\ttparam = %d, ", tparam.ty); tparam.print();

		// Extra check that function characteristics must match
		if (tparam && tparam.ty == Tfunction)
		{
			TypeFunction tp = cast(TypeFunction)tparam;
			if (varargs != tp.varargs ||
				linkage != tp.linkage)
				return MATCHnomatch;

			size_t nfargs = Parameter.dim(this.parameters);
			size_t nfparams = Parameter.dim(tp.parameters);

			/* See if tuple match
			 */
			if (nfparams > 0 && nfargs >= nfparams - 1)
			{
				/* See if 'A' of the template parameter matches 'A'
				 * of the type of the last function parameter.
				 */
				auto fparam = Parameter.getNth(tp.parameters, nfparams - 1);
				assert(fparam);
				assert(fparam.type);
				if (fparam.type.ty != Tident)
					goto L1;
				TypeIdentifier tid = cast(TypeIdentifier)fparam.type;
				if (tid.idents.dim)
					goto L1;

				/* Look through parameters to find tuple matching tid.ident
				 */
				size_t tupi = 0;
				for (; 1; tupi++)
				{	
					if (tupi == parameters.dim)
						goto L1;
					TemplateParameter t = parameters[tupi];
					TemplateTupleParameter tup = t.isTemplateTupleParameter();
					if (tup && tup.ident.equals(tid.ident))
						break;
				}

				/* The types of the function arguments [nfparams - 1 .. nfargs]
				 * now form the tuple argument.
				 */
				int tuple_dim = nfargs - (nfparams - 1);

				/* See if existing tuple, and whether it matches or not
				 */
				Object o = dedtypes[tupi];
				if (o)
				{	
					// Existing deduced argument must be a tuple, and must match
					Tuple t = isTuple(o);
					if (!t || t.objects.dim != tuple_dim)
						return MATCHnomatch;
					for (size_t i = 0; i < tuple_dim; i++)
					{   
						auto arg = Parameter.getNth(this.parameters, nfparams - 1 + i);
						if (!arg.type.equals(t.objects[i]))
							return MATCHnomatch;
					}
				}
				else
				{	// Create new tuple
					Tuple t = new Tuple();
					t.objects.setDim(tuple_dim);
					for (size_t i = 0; i < tuple_dim; i++)
					{   
						auto arg = Parameter.getNth(this.parameters, nfparams - 1 + i);
						t.objects[i] = arg.type;
					}
					dedtypes[tupi] = t;
				}
				nfparams--;	// don't consider the last parameter for type deduction
				goto L2;
			}

			L1:
			if (nfargs != nfparams)
				return MATCHnomatch;
			L2:
			for (size_t i = 0; i < nfparams; i++)
			{
				auto a = Parameter.getNth(this.parameters, i);
				auto ap = Parameter.getNth(tp.parameters, i);
				if (a.storageClass != ap.storageClass ||
					!a.type.deduceType(sc, ap.type, parameters, dedtypes))
				return MATCHnomatch;
			}
		}
		return Type.deduceType(sc, tparam, parameters, dedtypes);
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoFunctionDeclaration(this);
	}
	
    override Type reliesOnTident()
	{
        size_t dim = Parameter.dim(parameters);
        for (size_t i = 0; i < dim; i++)
        {
            auto fparam = Parameter.getNth(parameters, i);
	        Type t = fparam.type.reliesOnTident();
	        if (t)
	            return t;
        }
        return next ? next.reliesOnTident() : null;
	}

version (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState* cms)
	{
		assert(false);
	}
}

	/***************************
	 * Examine function signature for parameter p and see if
	 * p can 'escape' the scope of the function.
	 */
    bool parameterEscapes(Parameter p)
	{
		/* Scope parameters do not escape.
		 * Allow 'lazy' to imply 'scope' -
		 * lazy parameters can be passed along
		 * as lazy parameters to the next function, but that isn't
		 * escaping.
		 */
		if (p.storageClass & (STC.STCscope | STC.STClazy))
			return false;

		if (ispure)
		{	/* With pure functions, we need only be concerned if p escapes
			 * via any return statement.
			 */
			Type tret = nextOf().toBasetype();
			if (!isref && !tret.hasPointers())
			{   /* The result has no references, so p could not be escaping
				 * that way.
				 */
				return false;
			}
		}

		/* Assume it escapes in the absence of better information.
		 */
		return true;
	}

	/********************************
	 * 'args' are being matched to function 'this'
	 * Determine match level.
	 * Returns:
	 *	MATCHxxxx
	 */
    MATCH callMatch(Expression ethis, Expressions args)
	{
		//printf("TypeFunction.callMatch() %s\n", toChars());
		MATCH match = MATCH.MATCHexact;		// assume exact match
        bool exactwildmatch = false;
        bool wildmatch = false;

		if (ethis)
		{
			Type t = ethis.type;
			if (t.toBasetype().ty == TY.Tpointer)
				t = t.toBasetype().nextOf();	// change struct* to struct

			if (t.mod != mod)
			{
				if (MODimplicitConv(t.mod, mod))
					match = MATCH.MATCHconst;
				else
					return MATCH.MATCHnomatch;
			}
		}

		size_t nparams = Parameter.dim(parameters);
		size_t nargs = args ? args.dim : 0;
		if (nparams == nargs) {
			//;
		} else if (nargs > nparams)
		{
			if (varargs == 0)
				goto Nomatch;		// too many args; no match
			match = MATCH.MATCHconvert;		// match ... with a "conversion" match level
		}

		for (size_t u = 0; u < nparams; u++)
		{	
			MATCH m;
			Expression arg;

			// BUG: what about out and ref?

			auto p = Parameter.getNth(parameters, u);
			assert(p);
			if (u >= nargs)
			{
				if (p.defaultArg)
					continue;
				if (varargs == 2 && u + 1 == nparams)
					goto L1;
				goto Nomatch;		// not enough arguments
			}

			arg = cast(Expression)args[u];
			assert(arg);
			// writef("arg: %s, type: %s\n", arg.toChars(), arg.type.toChars());


			// Non-lvalues do not match ref or out parameters
			if (p.storageClass & (STC.STCref | STC.STCout))
			{
				if (!arg.isLvalue())
					goto Nomatch;
			}
			
			if (p.storageClass & STCref)
			{
				/* Don't allow static arrays to be passed to mutable references
				 * to static arrays if the argument cannot be modified.
				 */
				Type targb = arg.type.toBasetype();
				Type tparb = p.type.toBasetype();
				//writef("%s\n", targb.toChars());
				//writef("%s\n", tparb.toChars());
				if (targb.nextOf() && tparb.ty == Tsarray &&
				   !MODimplicitConv(targb.nextOf().mod, tparb.nextOf().mod))
					goto Nomatch;
			}

			if (p.storageClass & STC.STClazy && p.type.ty == TY.Tvoid && arg.type.ty != TY.Tvoid)
				m = MATCH.MATCHconvert;
			else
            {
				m = arg.implicitConvTo(p.type);
	            if (p.type.isWild())
	            {
		            if (m == MATCHnomatch)
		            {
		                m = arg.implicitConvTo(p.type.constOf());
		                if (m == MATCHnomatch)
			            m = arg.implicitConvTo(p.type.sharedConstOf());
		                if (m != MATCHnomatch)
			            wildmatch = true;	// mod matched to wild
		            }
		            else
		                exactwildmatch = true;	// wild matched to wild

		            /* If both are allowed, then there could be more than one
		             * binding of mod to wild, leaving a gaping type hole.
		             */
		            if (wildmatch && exactwildmatch)
		                m = MATCHnomatch;
	            }
	        }

			//printf("\tm = %d\n", m);
			if (m == MATCH.MATCHnomatch)			// if no match
			{
			  L1:
				if (varargs == 2 && u + 1 == nparams)	// if last varargs param
				{	
					Type tb = p.type.toBasetype();
					TypeSArray tsa;
					long sz;

					switch (tb.ty)
					{
						case TY.Tsarray:
							tsa = cast(TypeSArray)tb;
							sz = tsa.dim.toInteger();
							if (sz != nargs - u)
								goto Nomatch;
						case TY.Tarray:
						{	
							TypeArray ta = cast(TypeArray)tb;
							for (; u < nargs; u++)
							{
								arg = cast(Expression)args[u];
								assert(arg);
static if (true) {
								/* If lazy array of delegates,
								 * convert arg(s) to delegate(s)
								 */
								Type tret = p.isLazyArray();
								if (tret)
								{
									if (ta.next.equals(arg.type))
									{   
										m = MATCH.MATCHexact;
									}
									else
									{
										m = arg.implicitConvTo(tret);
										if (m == MATCH.MATCHnomatch)
										{
											if (tret.toBasetype().ty == TY.Tvoid)
												m = MATCH.MATCHconvert;
										}
									}
								}
								else
									m = arg.implicitConvTo(ta.next);
} else {
								m = arg.implicitConvTo(ta.next);
}
								if (m == MATCH.MATCHnomatch)
									goto Nomatch;

								if (m < match)
									match = m;
							}
							goto Ldone;
						}

						case TY.Tclass:
							// Should see if there's a constructor match?
							// Or just leave it ambiguous?
							goto Ldone;

						default:
							goto Nomatch;
					}
				}

				goto Nomatch;
			}

			if (m < match)
				match = m;			// pick worst match
		}

	Ldone:
		//printf("match = %d\n", match);
		return match;

	Nomatch:
		//printf("no match\n");
		return MATCH.MATCHnomatch;
	}
	
	override type* toCtype()
	{
		if (ctype) {
			return ctype;
		}

		type* t;
		if (true)
		{
			param_t* paramtypes;
			tym_t tyf;
			type* tp;

			paramtypes = null;
			size_t nparams = Parameter.dim(parameters);
			for (size_t i = 0; i < nparams; i++)
			{   
				auto arg = Parameter.getNth(parameters, i);
				tp = arg.type.toCtype();
				if (arg.storageClass & (STC.STCout | STC.STCref))
				{   
					// C doesn't have reference types, so it's really a pointer
					// to the parameter type
					tp = type_allocn(TYM.TYref, tp);
				}
				param_append_type(&paramtypes,tp);
			}
			tyf = totym();
			t = type_alloc(tyf);
			t.Tflags |= TF.TFprototype;
			if (varargs != 1)
				t.Tflags |= TF.TFfixed;
			ctype = t;
			t.Tnext = next.toCtype();
			t.Tnext.Tcount++;
			t.Tparamtypes = paramtypes;
		}
		ctype = t;
		return t;
	}
	
	/***************************
	 * Determine return style of function - whether in registers or
	 * through a hidden pointer to the caller's stack.
	 */
	RET retStyle()
	{
		//printf("TypeFunction.retStyle() %s\n", toChars());
version (DMDV2)
{
		if (isref)
			return RET.RETregs;			// returns a pointer
}

		Type tn = next.toBasetype();
	    Type tns = tn;
	    ulong sz = tn.size();

version(SARRAYVALUE)
{
		if (tn.ty == Tsarray)
		{
			do
			{
				tns = tns.nextOf().toBasetype();
			} while (tns.ty == Tsarray);
			if (tns.ty != Tstruct)
			{
				if (global.params.isLinux && linkage != LINKd)
				{}
				else
				{
					switch (sz)
					{   case 1:
						case 2:
						case 4:
						case 8:
						return RET.RETregs;	// return small structs in regs
											// (not 3 byte structs!)
						default:
						break;
					}
				}
				return RET.RETstack;
			}
		}
}
		if (tns.ty == TY.Tstruct)
		{	
			StructDeclaration sd = (cast(TypeStruct)tn).sym;
			if (global.params.isLinux && linkage != LINK.LINKd) {
				//;
			}
///version (DMDV2) { // TODO:
			else if (sd.dtor || sd.cpctor)
			{
			}
///}
			else
			{
				switch (sz)
				{   
					case 1:
					case 2:
					case 4:
					case 8:
						return RET.RETregs;	// return small structs in regs
								// (not 3 byte structs!)
					default:
						break;
				}
			}
			return RET.RETstack;
		}
		else if ((global.params.isLinux || global.params.isOSX || global.params.isFreeBSD || global.params.isSolaris) &&
			 linkage == LINK.LINKc &&
			 tn.iscomplex())
		{
			if (tn.ty == TY.Tcomplex32)
				return RET.RETregs;	// in EDX:EAX, not ST1:ST0
			else
				return RET.RETstack;
		}
		else
			return RET.RETregs;
	}

    override TYM totym()
	{
		TYM tyf;

		//printf("TypeFunction.totym(), linkage = %d\n", linkage);
		switch (linkage)
		{
		case LINK.LINKwindows:
			tyf = (varargs == 1) ? TYM.TYnfunc : TYM.TYnsfunc;
			break;

		case LINK.LINKpascal:
			tyf = (varargs == 1) ? TYM.TYnfunc : TYM.TYnpfunc;
			break;

		case LINK.LINKc:
			tyf = TYM.TYnfunc;
	version (POSIX) {///TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
			if (retStyle() == RET.RETstack)
				tyf = TYM.TYhfunc;
	}
			break;

		case LINK.LINKd:
			tyf = (varargs == 1) ? TYM.TYnfunc : TYM.TYjfunc;
			break;

		case LINK.LINKcpp:
			tyf = TYM.TYnfunc;
			break;

		default:
			writef("linkage = %d\n", linkage);
			assert(0);
		}
	version (DMDV2) {
		if (isnothrow)
			tyf |= mTY.mTYnothrow;
	}
		return tyf;
	}
}
