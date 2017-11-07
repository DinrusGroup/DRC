module dmd.TemplateAliasParameter;

import dmd.common;
import dmd.TemplateParameter;
import dmd.Loc;
import dmd.Identifier;
import dmd.Type;
import dmd.TypeIdentifier;
import dmd.ArrayTypes;
import dmd.Scope;
import dmd.Global;
import dmd.Declaration;
import dmd.MATCH;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Dsymbol;
import dmd.WANT;
import dmd.Expression;
import dmd.Initializer;
import dmd.ExpInitializer;
import dmd.AliasDeclaration;
import dmd.VarDeclaration;
import dmd.TemplateDeclaration;
import dmd.STC;
import dmd.Util;

import dmd.templates.Util;

import dmd.DDMDExtensions;

Object aliasParameterSemantic(Loc loc, Scope sc, Object o)
{
	if (o)
	{
		Expression ea = isExpression(o);
		Type ta = isType(o);
		if (ta)
		{   Dsymbol s = ta.toDsymbol(sc);
			if (s)
				o = s;
			else
				o = ta.semantic(loc, sc);
		}
		else if (ea)
		{
			ea = ea.semantic(sc);
			o = ea.optimize(WANT.WANTvalue | WANT.WANTinterpret);
		}
	}
	return o;
}

class TemplateAliasParameter : TemplateParameter
{
	mixin insertMemberExtension!(typeof(this));

	/* Syntax:
	 *	specType ident : specAlias = defaultAlias
	 */

	Type specType;
	Object specAlias;
	Object defaultAlias;

	this(Loc loc, Identifier ident, Type specType, Object specAlias, Object defaultAlias)
	{
		register();
		super(loc, ident);

		this.specType = specType;
		this.specAlias = specAlias;
		this.defaultAlias = defaultAlias;
	}

	override TemplateAliasParameter isTemplateAliasParameter()
	{
		return this;
	}

	override TemplateParameter syntaxCopy()
	{
		TemplateAliasParameter tp = new TemplateAliasParameter(loc, ident, specType, specAlias, defaultAlias);
		if (tp.specType)
			tp.specType = specType.syntaxCopy();
		tp.specAlias = objectSyntaxCopy(specAlias);
		tp.defaultAlias = objectSyntaxCopy(defaultAlias);
		return tp;
	}

	override void declareParameter(Scope sc)
	{
		TypeIdentifier ti = new TypeIdentifier(loc, ident);
		sparam = new AliasDeclaration(loc, ident, ti);
		if (!sc.insert(sparam))
			error(loc, "parameter '%s' multiply defined", ident.toChars());
	}

	override void semantic(Scope sc)
	{
		if (specType)
		{
			specType = specType.semantic(loc, sc);
		}
		specAlias = aliasParameterSemantic(loc, sc, specAlias);
static if (false) { // Don't do semantic() until instantiation
		if (defaultAlias)
			defaultAlias = defaultAlias.semantic(loc, sc);
}
	}

	override void print(Object oarg, Object oded)
	{
		printf(" %s\n", ident.toChars());

		Dsymbol sa = isDsymbol(oded);
		assert(sa);

		printf("Parameter alias: %s\n", sa.toChars());
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("alias ");
		if (specType)
		{	HdrGenState hg;
			specType.toCBuffer(buf, ident, &hg);
		}
		else
			buf.writestring(ident.toChars());
		if (specAlias)
		{
			buf.writestring(" : ");
			ObjectToCBuffer(buf, hgs, specAlias);
		}
		if (defaultAlias)
		{
			buf.writestring(" = ");
			ObjectToCBuffer(buf, hgs, defaultAlias);
		}
	}

	override Object specialization()
	{
		return specAlias;
	}

	override Object defaultArg(Loc loc, Scope sc)
	{
		Object o = aliasParameterSemantic(loc, sc, defaultAlias);
		return o;
	}

	override bool overloadMatch(TemplateParameter tp)
	{
		TemplateAliasParameter tap = tp.isTemplateAliasParameter();

		if (tap)
		{
			if (specAlias != tap.specAlias)
				goto Lnomatch;

			return true;			// match
		}

Lnomatch:
		return false;
	}

	override MATCH matchArg(Scope sc, Objects tiargs, int i, TemplateParameters parameters, Objects dedtypes, Declaration* psparam, int flags)
	{
		Object sa;
		Object oarg;
		Expression ea;
		Dsymbol s;

		//printf("TemplateAliasParameter.matchArg()\n");

		if (i < tiargs.dim)
			oarg = tiargs[i];
		else
		{	// Get default argument instead
			oarg = defaultArg(loc, sc);
			if (!oarg)
			{   assert(i < dedtypes.dim);
				// It might have already been deduced
				oarg = dedtypes[i];
				if (!oarg)
					goto Lnomatch;
			}
		}

		sa = getDsymbol(oarg);
		if (sa)
		{
			/* specType means the alias must be a declaration with a type
			 * that matches specType.
			 */
			if (specType)
			{   Declaration d = (cast(Dsymbol)sa).isDeclaration();
					if (!d)
					goto Lnomatch;
					if (!d.type.equals(specType))
					goto Lnomatch;
					}
					}
					else
					{
					sa = oarg;
					ea = isExpression(oarg);
					if (ea)
					{   if (specType)
					{
					if (!ea.type.equals(specType))
					goto Lnomatch;
					}
					}
					else
					goto Lnomatch;
					}
			if (specAlias)
			{
				if (sa is global.sdummy)
					goto Lnomatch;
				if (sa != specAlias)
					goto Lnomatch;
			}
			else if (dedtypes[i])
			{   // Must match already deduced symbol
				Object s_ = dedtypes[i];

				if (!sa || s_ != sa)
					goto Lnomatch;
			}
			dedtypes[i] = sa;

			s = isDsymbol(sa);
			if (s)
				*psparam = new AliasDeclaration(loc, ident, s);
			else
			{
				assert(ea);

				// Declare manifest constant
				Initializer init = new ExpInitializer(loc, ea);
				VarDeclaration v = new VarDeclaration(loc, null, ident, init);
				v.storage_class = STC.STCmanifest;
				v.semantic(sc);
				*psparam = v;
			}
			return MATCHexact;

Lnomatch:
			*psparam = null;
			//printf("\tm = %d\n", MATCHnomatch);
			return MATCHnomatch;
	}

	override Object dummyArg()
	{
		if (!specAlias)
		{
			return global.sdummy;
		}
		return specAlias;
	}
}
