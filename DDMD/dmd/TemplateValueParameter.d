module dmd.TemplateValueParameter;

import dmd.common;
import dmd.TemplateParameter;
import dmd.Scope;
import dmd.Declaration;
import dmd.ArrayTypes;
import dmd.Type;
import dmd.Expression;
import dmd.Loc;
import dmd.Identifier;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.MATCH;
import dmd.VarDeclaration;
import dmd.Initializer;
import dmd.ExpInitializer;
import dmd.Global;
import dmd.DefaultInitExp;
import dmd.STC;
import dmd.Util;
import dmd.TY;
import dmd.WANT;
import dmd.TOK;

import dmd.Dsymbol : isExpression;

import dmd.DDMDExtensions;

class TemplateValueParameter : TemplateParameter
{
	mixin insertMemberExtension!(typeof(this));

    /* Syntax:
     *	valType ident : specValue = defaultValue
     */

    Type valType;
    Expression specValue;
    Expression defaultValue;

    this(Loc loc, Identifier ident, Type valType, Expression specValue, Expression defaultValue)
	{
		register();
		super(loc, ident);

		this.valType = valType;
		this.specValue = specValue;
		this.defaultValue = defaultValue;
	}

    override TemplateValueParameter isTemplateValueParameter()
	{
		return this;
	}

    override TemplateParameter syntaxCopy()
	{
		TemplateValueParameter tp = new TemplateValueParameter(loc, ident, valType, specValue, defaultValue);
		tp.valType = valType.syntaxCopy();
		if (specValue)
			tp.specValue = specValue.syntaxCopy();
		if (defaultValue)
			tp.defaultValue = defaultValue.syntaxCopy();
		return tp;
	}

    override void declareParameter(Scope sc)
	{
		VarDeclaration v = new VarDeclaration(loc, valType, ident, null);
		v.storage_class = STC.STCtemplateparameter;
		if (!sc.insert(v))
			error(loc, "parameter '%s' multiply defined", ident.toChars());
		sparam = v;
	}

    override void semantic(Scope sc)
	{
		sparam.semantic(sc);
		valType = valType.semantic(loc, sc);
		if (!(valType.isintegral() || valType.isfloating() || valType.isString()) && valType.ty != TY.Tident)
			error(loc, "arithmetic/string type expected for value-parameter, not %s", valType.toChars());

		if (specValue)
		{
			Expression e = specValue;

			e = e.semantic(sc);
			e = e.implicitCastTo(sc, valType);
			e = e.optimize(WANTvalue | WANTinterpret);
			if (e.op == TOKint64 || e.op == TOKfloat64 ||
				e.op == TOKcomplex80 || e.op == TOKnull || e.op == TOKstring)
				specValue = e;
			//e.toInteger();
		}

static if (false) {	// defer semantic analysis to arg match
		if (defaultValue)
		{
			Expression e = defaultValue;

			e = e.semantic(sc);
			e = e.implicitCastTo(sc, valType);
			e = e.optimize(WANTvalue | WANTinterpret);
			if (e.op == TOKint64)
				defaultValue = e;
			//e.toInteger();
		}
}
	}

    override void print(Object oarg, Object oded)
	{
		assert(false);
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		valType.toCBuffer(buf, ident, hgs);
		if (specValue)
		{
			buf.writestring(" : ");
			specValue.toCBuffer(buf, hgs);
		}
		if (defaultValue)
		{
			buf.writestring(" = ");
			defaultValue.toCBuffer(buf, hgs);
		}
	}

    override Object specialization()
	{
		return specValue;
	}

    override Object defaultArg(Loc loc, Scope sc)
	{
		Expression e = defaultValue;
		if (e)
		{
			e = e.syntaxCopy();
			e = e.semantic(sc);
version (DMDV2) {
            e = e.resolveLoc(loc, sc);
}
		}
		return e;
	}

    override bool overloadMatch(TemplateParameter tp)
	{
		TemplateValueParameter tvp = tp.isTemplateValueParameter();

		if (tvp)
		{
			if (valType != tvp.valType)
				return false;

			if (valType && !valType.equals(tvp.valType))
				return false;

			if (specValue != tvp.specValue)
				return false;

			return true;			// match
		}

		return false;
	}

    override MATCH matchArg(Scope sc, Objects tiargs, int i, TemplateParameters parameters, Objects dedtypes, Declaration* psparam, int flags)
	{
		//printf("TemplateValueParameter.matchArg()\n");

		Initializer init;
		Declaration sparam;
		MATCH m = MATCHexact;
		Expression ei;
		Object oarg;

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
					goto Lnomatch;
			}
		}

		ei = isExpression(oarg);
		Type vt;

		if (!ei && oarg)
			goto Lnomatch;

		if (ei && ei.op == TOKvar)
		{
			// Resolve const variables that we had skipped earlier
			ei = ei.optimize(WANTvalue | WANTinterpret);
		}

		if (specValue)
		{
			if (!ei || ei is global.edummy)
				goto Lnomatch;

			Expression e = specValue;

			e = e.semantic(sc);
			e = e.implicitCastTo(sc, valType);
			e = e.optimize(WANTvalue | WANTinterpret);
			//e.type = e.type.toHeadMutable();

			ei = ei.syntaxCopy();
			ei = ei.semantic(sc);
			ei = ei.optimize(WANTvalue | WANTinterpret);
			//ei.type = ei.type.toHeadMutable();
			//printf("\tei: %s, %s\n", ei.toChars(), ei.type.toChars());
			//printf("\te : %s, %s\n", e.toChars(), e.type.toChars());
			if (!ei.equals(e))
				goto Lnomatch;
		}
		else if (dedtypes[i])
		{   // Must match already deduced value
			auto e = cast(Expression)dedtypes[i];

			if (!ei || !ei.equals(e))
				goto Lnomatch;
		}
	Lmatch:
		//printf("\tvalType: %s, ty = %d\n", valType.toChars(), valType.ty);
		vt = valType.semantic(Loc(0), sc);
		//printf("ei: %s, ei.type: %s\n", ei.toChars(), ei.type.toChars());
		//printf("vt = %s\n", vt.toChars());
		if (ei.type)
		{
			m = cast(MATCH)ei.implicitConvTo(vt);
			//printf("m: %d\n", m);
			if (!m)
				goto Lnomatch;
		}
		dedtypes[i] = ei;

		init = new ExpInitializer(loc, ei);
		sparam = new VarDeclaration(loc, vt, ident, init);
		sparam.storage_class = STCmanifest;
		*psparam = sparam;
		return m;

	Lnomatch:
		//printf("\tno match\n");
		*psparam = null;
		return MATCHnomatch;
	}

    override Object dummyArg()
	{
		if (!specValue)
		{
			return global.edummy;
		}

		return specValue;
	}
}
