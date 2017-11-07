module dmd.TemplateTypeParameter;

import dmd.common;
import dmd.TemplateParameter;
import dmd.Type;
import dmd.Loc;
import dmd.Identifier;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Declaration;
import dmd.ArrayTypes;
import dmd.TypeIdentifier;
import dmd.AliasDeclaration;
import dmd.Util;
import dmd.MATCH;
import dmd.Dsymbol;

import dmd.DDMDExtensions;

class TemplateTypeParameter : TemplateParameter
{
	mixin insertMemberExtension!(typeof(this));

    /* Syntax:
     *	ident : specType = defaultType
     */
    Type specType;	// type parameter: if !=null, this is the type specialization
    Type defaultType;

    this(Loc loc, Identifier ident, Type specType, Type defaultType)
	{
		register();
		super(loc, ident);
		this.ident = ident;
		this.specType = specType;
		this.defaultType = defaultType;
	}

    override TemplateTypeParameter isTemplateTypeParameter()
	{
		return this;
	}
	
    override TemplateParameter syntaxCopy()
	{
		TemplateTypeParameter tp = new TemplateTypeParameter(loc, ident, specType, defaultType);
		if (tp.specType)
			tp.specType = specType.syntaxCopy();
		if (defaultType)
			tp.defaultType = defaultType.syntaxCopy();
		return tp;
	}
	
    override void declareParameter(Scope sc)
	{
		//printf("TemplateTypeParameter.declareParameter('%s')\n", ident.toChars());
		TypeIdentifier ti = new TypeIdentifier(loc, ident);
		sparam = new AliasDeclaration(loc, ident, ti);
		if (!sc.insert(sparam))
			error(loc, "parameter '%s' multiply defined", ident.toChars());
	}
	
    override void semantic(Scope sc)
	{
		//printf("TemplateTypeParameter.semantic('%s')\n", ident.toChars());
		if (specType)
		{
			specType = specType.semantic(loc, sc);
		}
	static if (false) {	// Don't do semantic() until instantiation
		if (defaultType)
		{
			defaultType = defaultType.semantic(loc, sc);
		}
	}
	}

    override void print(Object oarg, Object oded)
	{
		assert(false);
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring(ident.toChars());
		if (specType)
		{
			buf.writestring(" : ");
			specType.toCBuffer(buf, null, hgs);
		}
		if (defaultType)
		{
			buf.writestring(" = ");
			defaultType.toCBuffer(buf, null, hgs);
		}
	}

    override Object specialization()
	{
		return specType;
	}

    override Object defaultArg(Loc loc, Scope sc)
	{
		Type t;

		t = defaultType;
		if (t)
		{
			t = t.syntaxCopy();
			t = t.semantic(loc, sc);
		}
		return t;
	}

    override bool overloadMatch(TemplateParameter)
	{
		assert(false);
	}

	/*******************************************
	 * Match to a particular TemplateParameter.
	 * Input:
	 *	i		i'th argument
	 *	tiargs[]	actual arguments to template instance
	 *	parameters[]	template parameters
	 *	dedtypes[]	deduced arguments to template instance
	 *	*psparam	set to symbol declared and initialized to dedtypes[i]
	 *	flags		1: don't do 'toHeadMutable()'
	 */
    override MATCH matchArg(Scope sc, Objects tiargs, int i, TemplateParameters parameters, Objects dedtypes, Declaration* psparam, int flags)
	{
		//printf("TemplateTypeParameter.matchArg()\n");
		Type t;
		Object oarg;
		MATCH m = MATCHexact;
		Type ta;

		if (i < tiargs.dim)
			oarg = tiargs[i];
		else
		{	
			// Get default argument instead
			oarg = defaultArg(loc, sc);
			if (!oarg)
			{   
				assert(i < dedtypes.dim);
				// It might have already been deduced
				oarg = dedtypes[i];
				if (!oarg)
				{
					goto Lnomatch;
				}
				flags |= 1;		// already deduced, so don't to toHeadMutable()
			}
		}

		ta = isType(oarg);
		if (!ta)
		{
			//printf("%s %p %p %p\n", oarg.toChars(), isExpression(oarg), isDsymbol(oarg), isTuple(oarg));
			goto Lnomatch;
		}
		//printf("ta is %s\n", ta.toChars());

		t = cast(Type)dedtypes[i];

		if (specType)
		{
			//printf("\tcalling deduceType(): ta is %s, specType is %s\n", ta.toChars(), specType.toChars());
			MATCH m2 = ta.deduceType(sc, specType, parameters, dedtypes);
			if (m2 == MATCHnomatch)
			{   
				//printf("\tfailed deduceType\n");
				goto Lnomatch;
			}

			if (m2 < m)
				m = m2;
			t = cast(Type)dedtypes[i];
		}
		else
		{
			// So that matches with specializations are better
			m = MATCHconvert;

			/* This is so that:
			 *   template Foo(T), Foo!(const int), => ta == int
			 */
		//	if (!(flags & 1))
		//	    ta = ta.toHeadMutable();

			if (t)
			{   // Must match already deduced type

				m = MATCHexact;
				if (!t.equals(ta))
				{	
					//printf("t = %s ta = %s\n", t.toChars(), ta.toChars());
					goto Lnomatch;
				}
			}
		}

		if (!t)
		{
			dedtypes[i] = ta;
			t = ta;
		}

		*psparam = new AliasDeclaration(loc, ident, t);
		//printf("\tm = %d\n", m);
		return m;

	Lnomatch:
		*psparam = null;
		//printf("\tm = %d\n", MATCHnomatch);
		return MATCHnomatch;
	}
	
    override Object dummyArg()
	{
		Type t;

		if (specType)
			t = specType;
		else
		{   
			// Use this for alias-parameter's too (?)
			t = new TypeIdentifier(loc, ident);
		}
		return t;
	}
}
