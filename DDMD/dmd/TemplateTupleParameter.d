module dmd.TemplateTupleParameter;

import dmd.common;
import dmd.TemplateParameter;
import dmd.Loc;
import dmd.Identifier;
import dmd.TypeIdentifier;
import dmd.AliasDeclaration;
import dmd.Scope;
import dmd.ArrayTypes;
import dmd.MATCH;
import dmd.Declaration;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Util;
import dmd.Tuple;
import dmd.Dsymbol;
import dmd.TemplateInstance;
import dmd.Type;
import dmd.Expression;
import dmd.TupleDeclaration;

import dmd.DDMDExtensions;

class TemplateTupleParameter : TemplateParameter
{
	mixin insertMemberExtension!(typeof(this));

    /* Syntax:
     *	ident ...
     */

    this(Loc loc, Identifier ident)
	{
		register();
		super(loc, ident);
		this.ident = ident;
	}

    override TemplateTupleParameter isTemplateTupleParameter()
	{
		return this;
	}
	
    override TemplateParameter syntaxCopy()
	{
		TemplateTupleParameter tp = new TemplateTupleParameter(loc, ident);
		return tp;
	}
	
    override void declareParameter(Scope sc)
	{
		TypeIdentifier ti = new TypeIdentifier(loc, ident);
		sparam = new AliasDeclaration(loc, ident, ti);
		if (!sc.insert(sparam))
			error(loc, "parameter '%s' multiply defined", ident.toChars());
	}
	
    override void semantic(Scope)
	{
	}
	
    override void print(Object oarg, Object oded)
	{
		writef(" %s... [", ident.toChars());
		Tuple v = isTuple(oded);
		assert(v);

		//printf("|%d| ", v.objects.dim);
		for (int i = 0; i < v.objects.dim; i++)
		{
			if (i)
				writef(", ");

			Object o = v.objects[i];

			Dsymbol sa = isDsymbol(o);
			if (sa)
				writef("alias: %s", sa.toChars());

			Type ta = isType(o);
			if (ta)
				writef("type: %s", ta.toChars());

			Expression ea = isExpression(o);
			if (ea)
				writef("exp: %s", ea.toChars());

			assert(!isTuple(o));		// no nested Tuple arguments
		}

		writef("]\n");
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring(ident.toChars());
		buf.writestring("...");
	}
	
    override Object specialization()
	{
		return null;
	}
	
    override Object defaultArg(Loc loc, Scope sc)
	{
		return null;
	}
	
    override bool overloadMatch(TemplateParameter tp)
	{
		TemplateTupleParameter tvp = tp.isTemplateTupleParameter();
		if (tvp) {
			return true;			// match
		}

	Lnomatch:
		return false;
	}
	
    override MATCH matchArg(Scope sc, Objects tiargs, int i, TemplateParameters parameters, Objects dedtypes, Declaration* psparam, int flags)
	{
		//printf("TemplateTupleParameter.matchArg()\n");

		/* The rest of the actual arguments (tiargs[]) form the match
		 * for the variadic parameter.
		 */
		assert(i + 1 == dedtypes.dim);	// must be the last one
		Tuple ovar;
		if (i + 1 == tiargs.dim && isTuple(tiargs[i]))
			ovar = isTuple(tiargs[i]);
		else
		{
			ovar = new Tuple();
			//printf("ovar = %p\n", ovar);
			if (i < tiargs.dim)
			{
				//printf("i = %d, tiargs.dim = %d\n", i, tiargs.dim);
				ovar.objects.setDim(tiargs.dim - i);
				for (size_t j = 0; j < ovar.objects.dim; j++)
					ovar.objects[j] = tiargs[i + j];
			}
		}
		*psparam = new TupleDeclaration(loc, ident, ovar.objects);
		dedtypes[i] = ovar;

		return MATCH.MATCHexact;
	}
	
    override Object dummyArg()
	{
		return null;
	}
}
