module dmd.TemplateDeclaration;

import dmd.common;
import dmd.Loc;
import dmd.ScopeDsymbol;
import dmd.ArrayTypes;
import dmd.Dsymbol;
import dmd.STC;
import dmd.TemplateThisParameter;
import dmd.Global;
import dmd.Array;
import dmd.Identifier;
import dmd.TypeArray;
import dmd.Expression;
import dmd.Scope;
import dmd.TypeIdentifier;
import dmd.TypeDelegate;
import dmd.IntegerExp;
import dmd.TypeSArray;
import dmd.StringExp;
import dmd.TOK;
import dmd.Parameter;
import dmd.CtorDeclaration;
import dmd.TypeFunction;
import dmd.TY;
import dmd.OutBuffer;
import dmd.Declaration;
import dmd.HdrGenState;
import dmd.TemplateInstance;
import dmd.WANT;
import dmd.FuncDeclaration;
import dmd.TemplateTupleParameter;
import dmd.MATCH;
import dmd.Type;
import dmd.Tuple;
import dmd.TupleDeclaration;
import dmd.Initializer;
import dmd.Json;
import dmd.ExpInitializer;
import dmd.TemplateValueParameter;
import dmd.AliasDeclaration;
import dmd.VarDeclaration;
import dmd.TemplateParameter;
import dmd.TemplateTypeParameter;
import dmd.MOD;

import dmd.expression.Util;

import std.stdio;

import dmd.DDMDExtensions;

/**************************************
 * Determine if TemplateDeclaration is variadic.
 */

TemplateTupleParameter isVariadic(TemplateParameters parameters)
{   
	size_t dim = parameters.dim;
	TemplateTupleParameter tp = null;

	if (dim)
		tp = parameters[dim - 1].isTemplateTupleParameter();

	return tp;
}

void ObjectToCBuffer(OutBuffer buf, HdrGenState* hgs, Object oarg)
{
	//printf("ObjectToCBuffer()\n");
	Type t = isType(oarg);
	Expression e = isExpression(oarg);
	Dsymbol s = isDsymbol(oarg);
	Tuple v = isTuple(oarg);
	if (t)
	{	
		//printf("\tt: %s ty = %d\n", t.toChars(), t.ty);
		t.toCBuffer(buf, null, hgs);
	}
	else if (e)
		e.toCBuffer(buf, hgs);
	else if (s)
	{
		string p = s.ident ? s.ident.toChars() : s.toChars();
		buf.writestring(p);
	}
	else if (v)
	{
		Objects args = v.objects;
		for (size_t i = 0; i < args.dim; i++)
		{
			if (i)
				buf.writeByte(',');
			Object o = args[i];
			ObjectToCBuffer(buf, hgs, o);
		}
	}
	else if (!oarg)
	{
		buf.writestring("null");
	}
	else
	{
		debug writef("bad Object = %p\n", oarg);
		assert(0);
	}
}

class TemplateDeclaration : ScopeDsymbol
{
	mixin insertMemberExtension!(typeof(this));

	TemplateParameters parameters;	// array of TemplateParameter's

	TemplateParameters origParameters;	// originals for Ddoc
	Expression constraint;
	Vector!TemplateInstance instances;			// array of TemplateInstance's

	TemplateDeclaration overnext;	// next overloaded TemplateDeclaration
	TemplateDeclaration overroot;	// first in overnext list

	int semanticRun;			// 1 semantic() run

	Dsymbol onemember;		// if !=NULL then one member of this template

	int literal;		// this template declaration is a literal

	this(Loc loc, Identifier id, TemplateParameters parameters, Expression constraint, Dsymbols decldefs)
	{	
		register();
		super(id);
		
	version (LOG) {
		printf("TemplateDeclaration(this = %p, id = '%s')\n", this, id.toChars());
	}
	static if (false) {
		if (parameters)
			for (int i = 0; i < parameters.dim; i++)
			{   
				TemplateParameter tp = cast(TemplateParameter)parameters.data[i];
				//printf("\tparameter[%d] = %p\n", i, tp);
				TemplateTypeParameter ttp = tp.isTemplateTypeParameter();

				if (ttp)
				{
					printf("\tparameter[%d] = %s : %s\n", i, tp.ident.toChars(), ttp.specType ? ttp.specType.toChars() : "");
				}
			}
	}
		
		this.loc = loc;
		this.parameters = parameters;
		this.origParameters = parameters;
		this.constraint = constraint;
		this.members = decldefs;
		
		instances = new Vector!TemplateInstance();
	}

	override Dsymbol syntaxCopy(Dsymbol)
	{
		//printf("TemplateDeclaration.syntaxCopy()\n");
		TemplateDeclaration td;
		TemplateParameters p;
		Dsymbols d;

		p = null;
		if (parameters)
		{
			p = new TemplateParameters();
			p.setDim(parameters.dim);
			for (int i = 0; i < p.dim; i++)
			{   
				auto tp = parameters[i];
				p[i] = tp.syntaxCopy();
			}
		}
		
		Expression e = null;
		if (constraint)
			e = constraint.syntaxCopy();
		d = Dsymbol.arraySyntaxCopy(members);
		td = new TemplateDeclaration(loc, ident, p, e, d);
		return td;
	}

	override void semantic(Scope sc)
	{
	version (LOG) {
		writef("TemplateDeclaration.semantic(this = %p, id = '%s')\n", this, ident.toChars());
	    writef("sc.stc = %llx\n", sc.stc);
	}
		if (semanticRun)
			return;		// semantic() already run
		semanticRun = 1;

		if (sc.func)
		{
	version (DMDV1) {
			error("cannot declare template at function scope %s", sc.func.toChars());
	}
		}

		if (/*global.params.useArrayBounds &&*/ sc.module_)
		{
			// Generate this function as it may be used
			// when template is instantiated in other modules
			sc.module_.toModuleArray();
		}

		if (/*global.params.useAssert &&*/ sc.module_)
		{
			// Generate this function as it may be used
			// when template is instantiated in other modules
			sc.module_.toModuleAssert();
		}

		/* Remember Scope for later instantiations, but make
		 * a copy since attributes can change.
		 */
		this.scope_ = sc.clone();
		this.scope_.setNoFree();

		// Set up scope for parameters
		ScopeDsymbol paramsym = new ScopeDsymbol();
		paramsym.parent = sc.parent;
		Scope paramscope = sc.push(paramsym);
		paramscope.parameterSpecialization = 1;
		paramscope.stc = STCundefined;

		if (!parent)
			parent = sc.parent;

		if (global.params.doDocComments)
		{
			origParameters = new TemplateParameters();
			origParameters.setDim(parameters.dim);
			foreach (size_t i, TemplateParameter tp; parameters)
			{
				origParameters[i] = tp.syntaxCopy();
			}
		}

		foreach (tp; parameters)
		{
			tp.declareParameter(paramscope);
		}

		foreach (size_t i, TemplateParameter tp; parameters)
		{
			tp.semantic(paramscope);
			if (i + 1 != parameters.dim && tp.isTemplateTupleParameter())
				error("template tuple parameter must be last one");
		}

		paramscope.pop();

		if (members)
		{
			Dsymbol s;
			if (Dsymbol.oneMembers(members, &s))
			{
				if (s && s.ident && s.ident.equals(ident))
				{
					onemember = s;
					s.parent = this;
				}
			}
		}

		/* BUG: should check:
		 *	o no virtual functions or non-static data members of classes
		 */
	}

	/**********************************
	 * Overload existing TemplateDeclaration 'this' with the new one 's'.
	 * Return !=0 if successful; i.e. no conflict.
	 */
	override bool overloadInsert(Dsymbol s)
	{
		TemplateDeclaration *pf;
		TemplateDeclaration f;

	version (LOG) {
		printf("TemplateDeclaration.overloadInsert('%.*s')\n", s.toChars());
	}
		f = s.isTemplateDeclaration();
		if (!f)
			return false;

		TemplateDeclaration pthis = this;
		for (pf = &pthis; *pf; pf = &(*pf).overnext)
		{
static if (false) {
			// Conflict if TemplateParameter's match
			// Will get caught anyway later with TemplateInstance, but
			// should check it now.
			if (f.parameters.dim != f2.parameters.dim)
				goto Lcontinue;

			for (int i = 0; i < f.parameters.dim; i++)
			{   
				TemplateParameter p1 = cast(TemplateParameter)f.parameters.data[i];
				TemplateParameter p2 = cast(TemplateParameter)f2.parameters.data[i];

				if (!p1.overloadMatch(p2))
					goto Lcontinue;
			}

version (LOG) {
			printf("\tfalse: conflict\n");
}
			return false;

Lcontinue:
		;
}
		}

		f.overroot = this;
		*pf = f;
	version (LOG) {
		printf("\ttrue: no conflict\n");
	}
	
		return true;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
static if (false) // Should handle template functions
{
		if (onemember && onemember.isFuncDeclaration())
			buf.writestring("foo ");
}
		buf.writestring(kind());
		buf.writeByte(' ');
		buf.writestring(ident.toChars());
		buf.writeByte('(');
		foreach (size_t i, TemplateParameter tp; parameters)
		{
			if (hgs.ddoc)
				tp = origParameters[i];
			if (i)
				buf.writeByte(',');
			tp.toCBuffer(buf, hgs);
		}
		buf.writeByte(')');
version(DMDV2)
{
		if (constraint)
		{   buf.writestring(" if (");
			constraint.toCBuffer(buf, hgs);
			buf.writeByte(')');
		}
}

		if (hgs.hdrgen)
		{
			hgs.tpltMember++;
			buf.writenl();
			buf.writebyte('{');
			buf.writenl();
			foreach (Dsymbol s; members)
				s.toCBuffer(buf, hgs);

			buf.writebyte('}');
			buf.writenl();
			hgs.tpltMember--;
		}
	}

	override void toJsonBuffer(OutBuffer buf)
	{
		//writef("TemplateDeclaration.toJsonBuffer()\n");

		buf.writestring("{\n");

		JsonProperty(buf, Pname, toChars());
		JsonProperty(buf, Pkind, kind());
		if (comment)
			JsonProperty(buf, Pcomment, comment);

		if (loc.linnum)
			JsonProperty(buf, Pline, loc.linnum);

		JsonString(buf, Pmembers);
		buf.writestring(" : [\n");
		size_t offset = buf.offset;
		foreach (Dsymbol s; members)
		{
			if (offset != buf.offset)
			{   buf.writestring(",\n");
				offset = buf.offset;
			}
			s.toJsonBuffer(buf);
		}
		JsonRemoveComma(buf);
		buf.writestring("]\n");

		buf.writestring("}\n");
	}

	override string kind()
	{
		return (onemember && onemember.isAggregateDeclaration())
			? onemember.kind()
			: "template";
	}

	override string toChars()
	{
		OutBuffer buf = new OutBuffer();
		HdrGenState hgs;

		/// memset(&hgs, 0, hgs.sizeof);
		buf.writestring(ident.toChars());
		buf.writeByte('(');
		foreach (size_t i, TemplateParameter tp; parameters)
		{
			if (i)
				buf.writeByte(',');
			tp.toCBuffer(buf, &hgs);
		}
		buf.writeByte(')');
version (DMDV2) {
		if (constraint)
		{
			buf.writestring(" if (");
			constraint.toCBuffer(buf, &hgs);
			buf.writeByte(')');
		}
}
		buf.writeByte(0);
		return buf.extractString();
	}

	override void emitComment(Scope sc)
	{
		assert(false);
	}
	
//	void toDocBuffer(OutBuffer *buf);

	/***************************************
	 * Given that ti is an instance of this TemplateDeclaration,
	 * deduce the types of the parameters to this, and store
	 * those deduced types in dedtypes[].
	 * Input:
	 *	flag	1: don't do semantic() because of dummy types
	 *		2: don't change types in matchArg()
	 * Output:
	 *	dedtypes	deduced arguments
	 * Return match level.
	 */
	MATCH matchWithInstance(TemplateInstance ti, Objects dedtypes, int flag)
	{
		MATCH m;
		int dedtypes_dim = dedtypes.dim;

	version (LOGM) {
		printf("\n+TemplateDeclaration.matchWithInstance(this = %.*s, ti = %.*s, flag = %d)\n", toChars(), ti.toChars(), flag);
	}

	static if (false) {
		printf("dedtypes.dim = %d, parameters.dim = %d\n", dedtypes_dim, parameters.dim);
		if (ti.tiargs.dim)
			printf("ti.tiargs.dim = %d, [0] = %p\n", ti.tiargs.dim, ti.tiargs.data[0]);
	}
		dedtypes.zero();

		int parameters_dim = parameters.dim;
		int variadic = isVariadic() !is null;

		// If more arguments than parameters, no match
		if (ti.tiargs.dim > parameters_dim && !variadic)
		{
	version (LOGM) {
			printf(" no match: more arguments than parameters\n");
	}
			return MATCHnomatch;
		}

		assert(dedtypes_dim == parameters_dim);
		assert(dedtypes_dim >= ti.tiargs.dim || variadic);

		// Set up scope for parameters
		assert(cast(size_t)cast(void*)scope_ > 0x10000);
		ScopeDsymbol paramsym = new ScopeDsymbol();
		paramsym.parent = scope_.parent;
		Scope paramscope = scope_.push(paramsym);
		paramscope.stc = STCundefined;

		// Attempt type deduction
		m = MATCHexact;
		for (int i = 0; i < dedtypes_dim; i++)
		{	
			MATCH m2;
			auto tp = parameters[i];
			Declaration sparam;

			//printf("\targument [%d]\n", i);
		version (LOGM) {
			//printf("\targument [%d] is %s\n", i, oarg ? oarg.toChars() : "null");
			TemplateTypeParameter *ttp = tp.isTemplateTypeParameter();
			if (ttp)
				printf("\tparameter[%d] is %s : %s\n", i, tp.ident.toChars(), ttp.specType ? ttp.specType.toChars() : "");
		}

		version (DMDV1) {
			m2 = tp.matchArg(paramscope, ti.tiargs, i, parameters, dedtypes, &sparam);
		} else {
			m2 = tp.matchArg(paramscope, ti.tiargs, i, parameters, dedtypes, &sparam, (flag & 2) ? 1 : 0);
		}
			//printf("\tm2 = %d\n", m2);

			if (m2 == MATCHnomatch)
			{
		static if (false) {
				printf("\tmatchArg() for parameter %i failed\n", i);
		}
				goto Lnomatch;
			}

			if (m2 < m)
				m = m2;

			if (!flag)
				sparam.semantic(paramscope);
			if (!paramscope.insert(sparam))
				goto Lnomatch;
		}

		if (!flag)
		{
			/* Any parameter left without a type gets the type of
			 * its corresponding arg
			 */
			for (int i = 0; i < dedtypes_dim; i++)
			{
				if (!dedtypes[i])
				{
					assert(i < ti.tiargs.dim);
					dedtypes[i] = ti.tiargs[i];
				}
			}
		}

	version (DMDV2) {
		if (m && constraint && !(flag & 1))
		{	/* Check to see if constraint is satisfied.
			 */
            makeParamNamesVisibleInConstraint(paramscope);
			Expression e = constraint.syntaxCopy();
			paramscope.flags |= SCOPE.SCOPEstaticif;
			e = e.semantic(paramscope);
			e = e.optimize(WANTvalue | WANTinterpret);
			if (e.isBool(true)) {
				//;
			} else if (e.isBool(false))
				goto Lnomatch;
			else
			{
				e.error("constraint %s is not constant or does not evaluate to a bool", e.toChars());
			}
		}
	}

	version (LOGM) {
		// Print out the results
		printf("--------------------------\n");
		printf("template %s\n", toChars());
		printf("instance %s\n", ti.toChars());
		if (m)
		{
			for (int i = 0; i < dedtypes_dim; i++)
			{
				TemplateParameter tp = cast(TemplateParameter)parameters.data[i];
				Object oarg;

				printf(" [%d]", i);

				if (i < ti.tiargs.dim)
					oarg = cast(Object)ti.tiargs.data[i];
				else
					oarg = null;
				tp.print(oarg, cast(Object)dedtypes.data[i]);
			}
		}
		else
			goto Lnomatch;
	}

	version (LOGM) {
		printf(" match = %d\n", m);
	}
		goto Lret;

	Lnomatch:
	version (LOGM) {
		printf(" no match\n");
	}
		m = MATCHnomatch;

	Lret:
		paramscope.pop();
	version (LOGM) {
		printf("-TemplateDeclaration.matchWithInstance(this = %p, ti = %p) = %d\n", this, ti, m);
	}
		return m;
	}
	
	/********************************************
	 * Determine partial specialization order of 'this' vs td2.
	 * Returns:
	 *	match	this is at least as specialized as td2
	 *	0	td2 is more specialized than this
	 */
	MATCH leastAsSpecialized(TemplateDeclaration td2)
	{
		/* This works by taking the template parameters to this template
		 * declaration and feeding them to td2 as if it were a template
		 * instance.
		 * If it works, then this template is at least as specialized
		 * as td2.
		 */

		scope TemplateInstance ti = new TemplateInstance(Loc(0), ident);	// create dummy template instance
		scope Objects dedtypes = new Objects();

version (LOG_LEASTAS) {
		printf("%s.leastAsSpecialized(%s)\n", toChars(), td2.toChars());
}

		// Set type arguments to dummy template instance to be types
		// generated from the parameters to this template declaration
		ti.tiargs = new Objects();
		ti.tiargs.setDim(parameters.dim);
		for (int i = 0; i < ti.tiargs.dim; i++)
		{
			auto tp = parameters[i];

			auto p = tp.dummyArg();
			if (p)
				ti.tiargs[i] = p;
			else
				ti.tiargs.setDim(i);
		}

		// Temporary Array to hold deduced types
		//dedtypes.setDim(parameters.dim);
		dedtypes.setDim(td2.parameters.dim);

		// Attempt a type deduction
		MATCH m = td2.matchWithInstance(ti, dedtypes, 1);
		if (m)
		{
			/* A non-variadic template is more specialized than a
			 * variadic one.
			 */
			if (isVariadic() && !td2.isVariadic())
				goto L1;

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

	/*************************************************
	 * Match function arguments against a specific template function.
	 * Input:
	 *	loc		instantiation location
	 *	targsi		Expression/Type initial list of template arguments
	 *	ethis		'this' argument if !null
	 *	fargs		arguments to function
	 * Output:
	 *	dedargs		Expression/Type deduced template arguments
	 * Returns:
	 *	match level
	 */
	MATCH deduceFunctionTemplateMatch(Loc loc, Objects targsi, Expression ethis, Expressions fargs, Objects dedargs)
	{
		size_t nfparams;
		size_t nfargs;
		size_t nargsi;		// array size of targsi
		int fptupindex = -1;
		int tuple_dim = 0;
		MATCH match = MATCHexact;
		FuncDeclaration fd = onemember.toAlias().isFuncDeclaration();
		Parameters fparameters;		// function parameter list
		int fvarargs;			// function varargs
		scope Objects dedtypes = new Objects();	// for T:T*, the dedargs is the T*, dedtypes is the T

	static if (false)
	{
		printf("\nTemplateDeclaration.deduceFunctionTemplateMatch() %s\n", toChars());
		for (i = 0; i < fargs.dim; i++)
		{	
			Expression e = cast(Expression)fargs.data[i];
			printf("\tfarg[%d] is %s, type is %s\n", i, e.toChars(), e.type.toChars());
		}
		printf("fd = %s\n", fd.toChars());
	    printf("fd.type = %s\n", fd.type.toChars());
		if (ethis)
			printf("ethis.type = %s\n", ethis.type.toChars());
	}

		assert(cast(size_t)cast(void*)scope_ > 0x10000);

		dedargs.setDim(parameters.dim);
		dedargs.zero();

		dedtypes.setDim(parameters.dim);
		dedtypes.zero();

		// Set up scope for parameters
		ScopeDsymbol paramsym = new ScopeDsymbol();
		paramsym.parent = scope_.parent;
		Scope paramscope = scope_.push(paramsym);

		TemplateTupleParameter tp = isVariadic();
        int tp_is_declared = 0;

	static if (false)
	{
		for (i = 0; i < dedargs.dim; i++)
		{
			printf("\tdedarg[%d] = ", i);
			Object oarg = cast(Object)dedargs.data[i];
			if (oarg) printf("%s", oarg.toChars());
				printf("\n");
		}
	}


		nargsi = 0;
		if (targsi)
		{
			// Set initial template arguments
			nargsi = targsi.dim;
			size_t n = parameters.dim;
			if (tp)
				n--;
			if (nargsi > n)
			{   
				if (!tp)
					goto Lnomatch;

				/* The extra initial template arguments
				 * now form the tuple argument.
				 */
				auto t = new Tuple();
				assert(parameters.dim);
				dedargs[parameters.dim - 1] = t;

				tuple_dim = nargsi - n;
				t.objects.setDim(tuple_dim);
				for (size_t i = 0; i < tuple_dim; i++)
				{
					t.objects[i] = targsi[n + i];
				}
				declareParameter(paramscope, tp, t);
                tp_is_declared = 1;
			}
			else
				n = nargsi;

			memcpy(dedargs.ptr, targsi.ptr, n * (*dedargs.ptr).sizeof);

			for (size_t i = 0; i < n; i++)
			{   
				assert(i < parameters.dim);
				auto tp2 = parameters[i];
				MATCH m;
				Declaration sparam = null;

				m = tp2.matchArg(paramscope, dedargs, i, parameters, dedtypes, &sparam);
				//printf("\tdeduceType m = %d\n", m);
				if (m == MATCHnomatch)
					goto Lnomatch;
				if (m < match)
					match = m;

				sparam.semantic(paramscope);
				if (!paramscope.insert(sparam))
					goto Lnomatch;
			}
		}
	static if (false)
	{
		for (i = 0; i < dedargs.dim; i++)
		{
			printf("\tdedarg[%d] = ", i);
			Object oarg = cast(Object)dedargs.data[i];
			if (oarg) printf("%s", oarg.toChars());
				printf("\n");
		}
	}

		fparameters = fd.getParameters(&fvarargs);
		nfparams = Parameter.dim(fparameters);	// number of function parameters
		nfargs = fargs ? fargs.dim : 0;		// number of function arguments

		/* Check for match of function arguments with variadic template
		 * parameter, such as:
		 *
		 * template Foo(T, A...) { void Foo(T t, A a); }
		 * void main() { Foo(1,2,3); }
		 */
		if (tp)				// if variadic
		{
			if (nfparams == 0 && nfargs != 0)		// if no function parameters
			{
	            if (tp_is_declared)
		            goto L2;
				auto t = new Tuple();
				//printf("t = %p\n", t);
				dedargs[parameters.dim - 1] = t;
				declareParameter(paramscope, tp, t);
				goto L2;
			}
			else if (nfargs < nfparams - 1)
				goto L1;
			else
			{
				/* Figure out which of the function parameters matches
				 * the tuple template parameter. Do this by matching
				 * type identifiers.
				 * Set the index of this function parameter to fptupindex.
				 */
				for (fptupindex = 0; fptupindex < nfparams; fptupindex++)
				{
					auto fparam = fparameters[fptupindex];
					if (fparam.type.ty != Tident)
						continue;
					auto tid = cast(TypeIdentifier)fparam.type;
					if (!tp.ident.equals(tid.ident) || tid.idents.dim)
						continue;

					if (fvarargs)		// variadic function doesn't
						goto Lnomatch;	// go with variadic template

            		if (tp_is_declared)
            		    goto L2;
                    
					/* The types of the function arguments
					 * now form the tuple argument.
					 */
					auto t = new Tuple();
					dedargs[parameters.dim - 1] = t;

					tuple_dim = nfargs - (nfparams - 1);
					t.objects.setDim(tuple_dim);
					for (size_t i = 0; i < tuple_dim; i++)
					{   
						auto farg = fargs[fptupindex + i];
						t.objects[i] = farg.type;
					}
					declareParameter(paramscope, tp, t);
					goto L2;
				}
				fptupindex = -1;
			}
		}

	L1:
		if (nfparams == nfargs) {
			//;
		} else if (nfargs > nfparams) {
			if (fvarargs == 0)
				goto Lnomatch;		// too many args, no match
			match = MATCHconvert;		// match ... with a conversion
		}

	L2:
	version (DMDV2) {
		if (ethis)
		{
			// Match 'ethis' to any TemplateThisParameter's
			for (size_t i = 0; i < parameters.dim; i++)
			{   
				auto tp2 = parameters[i];
				TemplateThisParameter ttp = tp2.isTemplateThisParameter();
				if (ttp)
				{	
					MATCH m;

					Type t = new TypeIdentifier(Loc(0), ttp.ident);
					m = ethis.type.deduceType(paramscope, t, parameters, dedtypes);
					if (!m)
						goto Lnomatch;
					if (m < match)
						match = m;		// pick worst match
				}
			}
			
			// Match attributes of ethis against attributes of fd
			if (fd.type)
			{
				Type tthis = ethis.type;
				MOD mod = fd.type.mod;
				StorageClass stc = scope_.stc;
				if (stc & (STCshared | STCsynchronized))
					mod |= MODshared;
				if (stc & STCimmutable)
					mod |= MODimmutable;
				if (stc & STCconst)
					mod |= MODconst;
				if (stc & STCwild)
					mod |= MODwild;
				// Fix mod
				if (mod & MODimmutable)
					mod = MODimmutable;
				if (mod & MODconst)
					mod &= ~STCwild;
				if (tthis.mod != mod)
				{
					if (!MODimplicitConv(tthis.mod, mod))
						goto Lnomatch;
					if (MATCHconst < match)
						match = MATCHconst;
				}
			}

		}
	}

		// Loop through the function parameters
		for (size_t i = 0; i < nfparams; i++)
		{
			/* Skip over function parameters which wound up
			 * as part of a template tuple parameter.
			 */
			if (i == fptupindex)
			{   
				if (fptupindex == nfparams - 1)
					break;
				i += tuple_dim - 1;
				continue;
			}

			auto fparam = Parameter.getNth(fparameters, i);

			if (i >= nfargs)		// if not enough arguments
			{
				if (fparam.defaultArg)
				{	
					/* Default arguments do not participate in template argument
					 * deduction.
					 */
					goto Lmatch;
				}
			}
			else
			{   
				auto farg = fargs[i];
		static if (false) {
				printf("\tfarg.type   = %s\n", farg.type.toChars());
				printf("\tfparam.type = %s\n", fparam.type.toChars());
		}
				Type argtype = farg.type;

		version (DMDV2) {
				/* Allow string literals which are type [] to match with [dim]
				 */
				if (farg.op == TOKstring)
				{	
					StringExp se = cast(StringExp)farg;
					if (!se.committed && argtype.ty == Tarray &&
						fparam.type.toBasetype().ty == Tsarray)
					{
						argtype = new TypeSArray(argtype.nextOf(), new IntegerExp(se.loc, se.len, Type.tindex));
						argtype = argtype.semantic(se.loc, null);
						argtype = argtype.invariantOf();
					}
				}
		}

				MATCH m;
				m = argtype.deduceType(paramscope, fparam.type, parameters, dedtypes);
				//printf("\tdeduceType m = %d\n", m);

				/* If no match, see if there's a conversion to a delegate
				 */
				if (!m && fparam.type.toBasetype().ty == Tdelegate)
				{
					TypeDelegate td = cast(TypeDelegate)fparam.type.toBasetype();
					TypeFunction tf = cast(TypeFunction)td.next;

					if (!tf.varargs && Parameter.dim(tf.parameters) == 0)
					{
						m = farg.type.deduceType(paramscope, tf.next, parameters, dedtypes);
						if (!m && tf.next.toBasetype().ty == Tvoid)
							m = MATCHconvert;
					}
					//printf("\tm2 = %d\n", m);
				}

				if (m)
				{	
					if (m < match)
						match = m;		// pick worst match
					continue;
				}
			}

			/* The following code for variadic arguments closely
			 * matches TypeFunction.callMatch()
			 */
			if (!(fvarargs == 2 && i + 1 == nfparams))
				goto Lnomatch;

			/* Check for match with function parameter T...
			 */
			Type tb = fparam.type.toBasetype();
			switch (tb.ty)
			{
				// Perhaps we can do better with this, see TypeFunction.callMatch()
				case Tsarray:
				{
					TypeSArray tsa = cast(TypeSArray)tb;
					ulong sz = tsa.dim.toInteger();
					if (sz != nfargs - i)
						goto Lnomatch;
				}
				case Tarray:
				{   
					TypeArray ta = cast(TypeArray)tb;
					for (; i < nfargs; i++)
					{
						auto arg = fargs[i];
						assert(arg);
						MATCH m;
						/* If lazy array of delegates,
						 * convert arg(s) to delegate(s)
						 */
						Type tret = fparam.isLazyArray();
						if (tret)
						{
							if (ta.next.equals(arg.type))
							{   
								m = MATCHexact;
							}
							else
							{
								m = arg.implicitConvTo(tret);
								if (m == MATCHnomatch)
								{
									if (tret.toBasetype().ty == Tvoid)
										m = MATCHconvert;
								}
							}
						}
						else
						{
							m = arg.type.deduceType(paramscope, ta.next, parameters, dedtypes);
							//m = arg.implicitConvTo(ta.next);
						}
						if (m == MATCHnomatch)
							goto Lnomatch;
						if (m < match)
							match = m;
					}
					goto Lmatch;
				}
				case Tclass:
				case Tident:
					goto Lmatch;

				default:
					goto Lnomatch;
			}
		}

	Lmatch:

		/* Fill in any missing arguments with their defaults.
		 */
		for (size_t i = nargsi; i < dedargs.dim; i++)
		{
			auto tparam = parameters[i];
			//printf("tparam[%d] = %s\n", i, tparam.ident.toChars());
			/* For T:T*, the dedargs is the T*, dedtypes is the T
			 * But for function templates, we really need them to match
			 */
			Object oarg = dedargs[i];
			Object oded = dedtypes[i];
			//printf("1dedargs[%d] = %p, dedtypes[%d] = %p\n", i, oarg, i, oded);
			//if (oarg) printf("oarg: %s\n", oarg.toChars());
			//if (oded) printf("oded: %s\n", oded.toChars());
			if (!oarg)
			{
				if (oded)
				{
					if (tparam.specialization())
					{   
						/* The specialization can work as long as afterwards
						 * the oded == oarg
						 */
						Declaration sparam;
						dedargs[i] = oded;
						MATCH m2 = tparam.matchArg(paramscope, dedargs, i, parameters, dedtypes, &sparam, 0);
						//printf("m2 = %d\n", m2);
						if (!m2)
							goto Lnomatch;
						if (m2 < match)
							match = m2;		// pick worst match
						if (dedtypes[i] !is oded)
							error("specialization not allowed for deduced parameter %s", tparam.ident.toChars());
					}
				}
				else
				{	
					if (!oded)
					{
						if (tp &&						// if tuple parameter and
							fptupindex < 0 &&			// tuple parameter was not in function parameter list and
							nargsi == dedargs.dim - 1)	// we're one argument short (i.e. no tuple argument)
						{   
							// make tuple argument an empty tuple
							oded = new Tuple();
						}
						else
							goto Lnomatch;
					}
				}
				declareParameter(paramscope, tparam, oded);
				dedargs[i] = oded;
			}
		}

	version (DMDV2) {
		if (constraint)
		{	/* Check to see if constraint is satisfied.
			 */
            makeParamNamesVisibleInConstraint(paramscope);
			Expression e = constraint.syntaxCopy();
			paramscope.flags |= SCOPE.SCOPEstaticif;
			e = e.semantic(paramscope);
			e = e.optimize(WANTvalue | WANTinterpret);
			if (e.isBool(true)) {
				//;
			} else if (e.isBool(false))
				goto Lnomatch;
			else
			{
				e.error("constraint %s is not constant or does not evaluate to a bool", e.toChars());
			}
		}
	}

	static if (false) {
		for (i = 0; i < dedargs.dim; i++)
		{	
			Type t = cast(Type)dedargs.data[i];
			printf("\tdedargs[%d] = %d, %s\n", i, t.dyncast(), t.toChars());
		}
	}

		paramscope.pop();
		//printf("\tmatch %d\n", match);
		return match;

	Lnomatch:
		paramscope.pop();
		//printf("\tnomatch\n");
		return MATCHnomatch;
	}
	
	/*************************************************
	 * Given function arguments, figure out which template function
	 * to expand, and return that function.
	 * If no match, give error message and return null.
	 * Input:
	 *	sc		instantiation scope
	 *	loc		instantiation location
	 *	targsi		initial list of template arguments
	 *	ethis		if !null, the 'this' pointer argument
	 *	fargs		arguments to function
	 *	flags		1: do not issue error message on no match, just return null
	 */
	FuncDeclaration deduceFunctionTemplate(Scope sc, Loc loc, Objects targsi, Expression ethis, Expressions fargs, int flags = 0)
	{
		MATCH m_best = MATCHnomatch;
		TemplateDeclaration td_ambig = null;
		TemplateDeclaration td_best = null;
		Objects tdargs = new Objects();
		TemplateInstance ti;
		FuncDeclaration fd;

	static if (false) {
		printf("TemplateDeclaration.deduceFunctionTemplate() %s\n", toChars());
		printf("	targsi:\n");
		if (targsi)
		{	
			for (int i = 0; i < targsi.dim; i++)
			{   
				Object arg = cast(Object)targsi.data[i];
				printf("\t%s\n", arg.toChars());
			}
		}
		printf("	fargs:\n");
		for (int i = 0; i < fargs.dim; i++)
		{	
			Expression arg = cast(Expression)fargs.data[i];
			printf("\t%s %s\n", arg.type.toChars(), arg.toChars());
			//printf("\tty = %d\n", arg.type.ty);
		}
	    printf("stc = %llx\n", scope_.stc);
	}

		for (TemplateDeclaration td = this; td; td = td.overnext)
		{
			if (!td.semanticRun)
			{
				error("forward reference to template %s", td.toChars());
				goto Lerror;
			}
			if (!td.onemember || !td.onemember.toAlias().isFuncDeclaration())
			{
				error("is not a function template");
				goto Lerror;
			}

			MATCH m;
			scope Objects dedargs = new Objects();

			m = td.deduceFunctionTemplateMatch(loc, targsi, ethis, fargs, dedargs);
			//printf("deduceFunctionTemplateMatch = %d\n", m);
			if (!m)			// if no match
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
			assert(cast(size_t)cast(void*)td.scope_ > 0x10000);
			td_best = td;
			m_best = m;
			tdargs.setDim(dedargs.dim);
			memcpy(tdargs.ptr, dedargs.ptr, tdargs.dim * (void*).sizeof);
			continue;
		}
		if (!td_best)
		{
			if (!(flags & 1))
				error(loc, "does not match any function template declaration");
			goto Lerror;
		}
		if (td_ambig)
		{
			error(loc, "matches more than one function template declaration:\n  %s\nand:\n  %s",
				td_best.toChars(), td_ambig.toChars());
		}

		/* The best match is td_best with arguments tdargs.
		 * Now instantiate the template.
		 */
		assert(cast(size_t)cast(void*)td_best.scope_ > 0x10000);
		ti = new TemplateInstance(loc, td_best, tdargs);
		ti.semantic(sc, fargs);
		fd = ti.toAlias().isFuncDeclaration();
		if (!fd)
		goto Lerror;
		return fd;

	  Lerror:
///	version (DMDV2) {
		if (!(flags & 1))
///	}
		{
			HdrGenState hgs;

			scope OutBuffer bufa = new OutBuffer();
			Objects args = targsi;
			if (args)
			{   
				for (int i = 0; i < args.dim; i++)
				{
					if (i)
						bufa.writeByte(',');
					Object oarg = args[i];
					ObjectToCBuffer(bufa, &hgs, oarg);
				}
			}

			scope OutBuffer buf = new OutBuffer();
			argExpTypesToCBuffer(buf, fargs, &hgs);
			error(loc, "cannot deduce template function from argument types !(%s)(%s)", bufa.toChars(), buf.toChars());
		}
		return null;
	}
	
	/**************************************************
	 * Declare template parameter tp with value o, and install it in the scope sc.
	 */
	void declareParameter(Scope sc, TemplateParameter tp, Object o)
	{
		//printf("TemplateDeclaration.declareParameter('%s', o = %p)\n", tp.ident.toChars(), o);

		Type targ = isType(o);
		Expression ea = isExpression(o);
		Dsymbol sa = isDsymbol(o);
		Tuple va = isTuple(o);

		Dsymbol s;

		// See if tp.ident already exists with a matching definition
		Dsymbol scopesym;
		s = sc.search(loc, tp.ident, &scopesym);
		if (s && scopesym == sc.scopesym)
		{
			TupleDeclaration td = s.isTupleDeclaration();
			if (va && td)
			{   
				Tuple tup = new Tuple();
				assert(false);	// < not implemented
				///tup.objects = *td.objects;
				if (match(va, tup, this, sc))
				{
					return;
				}
			}
		}

		if (targ)
		{
			//printf("type %s\n", targ.toChars());
			s = new AliasDeclaration(Loc(0), tp.ident, targ);
		}
		else if (sa)
		{
			//printf("Alias %s %s;\n", sa.ident.toChars(), tp.ident.toChars());
			s = new AliasDeclaration(Loc(0), tp.ident, sa);
		}
		else if (ea)
		{
			// tdtypes.data[i] always matches ea here
			Initializer init = new ExpInitializer(loc, ea);
			TemplateValueParameter tvp = tp.isTemplateValueParameter();

			Type t = tvp ? tvp.valType : null;

			VarDeclaration v = new VarDeclaration(loc, t, tp.ident, init);
			v.storage_class = STCmanifest;
			s = v;
		}
		else if (va)
		{
			//printf("\ttuple\n");
			s = new TupleDeclaration(loc, tp.ident, va.objects);
		}
		else
		{
			debug writefln(o.toString());
			assert(0);
		}

		if (!sc.insert(s))
			error("declaration %s is already defined", tp.ident.toChars());

		s.semantic(sc);
	}
	
	override TemplateDeclaration isTemplateDeclaration() { return this; }

	TemplateTupleParameter isVariadic()
	{
		return .isVariadic(parameters);
	}
	
	/***********************************
	 * We can overload templates.
	 */
	override bool isOverloadable()
	{
		return true;
	}
    
    /****************************
     * Declare all the function parameters as variables
     * and add them to the scope
     */
    void makeParamNamesVisibleInConstraint(Scope paramscope)
    {
        /* We do this ONLY if there is only one function in the template.
         */	 
        FuncDeclaration fd = onemember && onemember.toAlias() ?
	    onemember.toAlias().isFuncDeclaration() : null;
        if (fd)
        {
	        paramscope.parent = fd;
	        int fvarargs;				// function varargs
            Parameters fparameters = fd.getParameters(&fvarargs);
	        size_t nfparams = Parameter.dim(fparameters); // Num function parameters
	        for (int i = 0; i < nfparams; i++)
	        {
	            Parameter fparam = Parameter.getNth(fparameters, i).syntaxCopy();
	            if (!fparam.ident)
		            continue;			// don't add it, if it has no name
	            Type vtype = fparam.type.syntaxCopy();
	            // isPure will segfault if called on a ctor, because fd->type is null.
	            if (fd.type && fd.isPure())
		        vtype = vtype.addMod(MODconst);
	            VarDeclaration v = new VarDeclaration(loc, vtype, fparam.ident, null);
	            v.storage_class |= STCparameter;
	            // Not sure if this condition is correct/necessary.
	            //   It's from func.c
	            if (//fd->type && fd->type->ty == Tfunction &&
	                fvarargs == 2 && i + 1 == nfparams)
		            v.storage_class |= STCvariadic;
		
	            v.storage_class |= fparam.storageClass & (STCin | STCout | STCref | STClazy | STCfinal | STC_TYPECTOR | STCnodtor);
	            v.semantic(paramscope);
	            if (!paramscope.insert(v))
		            error("parameter %s.%s is already defined", toChars(), v.toChars());
	            else
		            v.parent = this;
	        }
        }
    }
}
