module dmd.TypeInstance;

import dmd.common;
import dmd.TypeQualified;
import dmd.TemplateAliasParameter;
import dmd.TemplateDeclaration;
import dmd.TemplateInstance;
import dmd.TemplateParameter;
import dmd.TemplateValueParameter;
import dmd.TemplateTupleParameter;
import dmd.Tuple;
import dmd.VarExp;
import dmd.MOD;
import dmd.MATCH;
import dmd.Loc;
import dmd.Global;
import dmd.Type;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Scope;
import dmd.ArrayTypes;
import dmd.TOK;
import dmd.TY;
import dmd.Util : printf;

import dmd.DDMDExtensions;

/* Similar to TypeIdentifier, but with a TemplateInstance as the root
 */
class TypeInstance : TypeQualified
{
	mixin insertMemberExtension!(typeof(this));

	TemplateInstance tempinst;

	this(Loc loc, TemplateInstance tempinst)
	{
		register();
		super(Tinstance, loc);
		this.tempinst = tempinst;
	}

	override Type syntaxCopy()
	{
		//printf("TypeInstance::syntaxCopy() %s, %d\n", toChars(), idents.dim);
		TypeInstance t;

		t = new TypeInstance(loc, cast(TemplateInstance)tempinst.syntaxCopy(null));
		t.syntaxCopyHelper(this);
		t.mod = mod;
		return t;
	}

	//char *toChars();

	//void toDecoBuffer(OutBuffer *buf, int flag);

	override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		if (mod != this.mod)
		{	toCBuffer3(buf, hgs, mod);
			return;
		}
		tempinst.toCBuffer(buf, hgs);
		toCBuffer2Helper(buf, hgs);
	}

	override void resolve(Loc loc, Scope sc, Expression* pe, Type* pt, Dsymbol* ps)
	{
		// Note close similarity to TypeIdentifier::resolve()
		Dsymbol s;

		*pe = null;
		*pt = null;
		*ps = null;

		static if (false) {
			if (!idents.dim)
			{
				error(loc, "template instance '%s' has no identifier", toChars());
				return;
			}
		}
		//id = (Identifier *)idents.data[0];
		//printf("TypeInstance::resolve(sc = %p, idents = '%s')\n", sc, id->toChars());
		s = tempinst;
		if (s)
			s.semantic(sc);
		resolveHelper(loc, sc, s, null, pe, pt, ps);
		if (*pt)
			*pt = (*pt).addMod(mod);
		//printf("pt = '%s'\n", (*pt)->toChars());
	}

	override Type semantic(Loc loc, Scope sc)
	{
		Type t;
		Expression e;
		Dsymbol s;

		//printf("TypeInstance::semantic(%s)\n", toChars());

		if (sc.parameterSpecialization)
		{
			uint errors = global.errors;
			global.gag++;

			resolve(loc, sc, &e, &t, &s);

			global.gag--;
			if (errors != global.errors)
			{   if (global.gag == 0)
				global.errors = errors;
				return this;
			}
		}
		else
			resolve(loc, sc, &e, &t, &s);

		if (!t)
		{
			debug printf("2: ");
			error(loc, "%s is used as a type", toChars());
			t = tvoid;
		}
		return t;
	}

	override Dsymbol toDsymbol(Scope sc)
	{
		Type t;
		Expression e;
		Dsymbol s;

		//printf("TypeInstance::semantic(%s)\n", toChars());

		if (sc.parameterSpecialization)
		{
			uint errors = global.errors;
			global.gag++;

			resolve(loc, sc, &e, &t, &s);

			global.gag--;
			if (errors != global.errors)
			{   
				if (global.gag == 0)
					global.errors = errors;

				return null;
			}
		}
		else
			resolve(loc, sc, &e, &t, &s);

		return s;
	}

	override MATCH deduceType(Scope sc, Type tparam, TemplateParameters parameters, Objects dedtypes)
	{
static if (0) {
		printf("TypeInstance::deduceType()\n");
		printf("\tthis   = %d, ", ty); print();
		printf("\ttparam = %d, ", tparam.ty); tparam.print();
}

		// Extra check
		if (tparam && tparam.ty == Tinstance)
		{
			TypeInstance tp = cast(TypeInstance)tparam;

			//printf("tempinst->tempdecl = %p\n", tempinst->tempdecl);
			//printf("tp->tempinst->tempdecl = %p\n", tp->tempinst->tempdecl);
			if (!tp.tempinst.tempdecl)
			{   //printf("tp->tempinst->name = '%s'\n", tp->tempinst->name->toChars());
				if (!tp.tempinst.name.equals(tempinst.name))
				{
					/* Handle case of:
					 *  template Foo(T : sa!(T), alias sa)
					 */
					int i = templateIdentifierLookup(tp.tempinst.name, parameters);
					if (i == -1)
					{   /* Didn't find it as a parameter identifier. Try looking
					     * it up and seeing if is an alias. See Bugzilla 1454
					     */
						Dsymbol s = tempinst.tempdecl.scope_.search(Loc(0), tp.tempinst.name, null);
						if (s)
						{
							s = s.toAlias();
							TemplateDeclaration td = s.isTemplateDeclaration();
							if (td && td == tempinst.tempdecl)
								goto L2;
						}
						goto Lnomatch;
					}
					TemplateParameter tpx = parameters[i];
					// This logic duplicates tpx->matchArg()
					TemplateAliasParameter ta = tpx.isTemplateAliasParameter();
					if (!ta)
						goto Lnomatch;
					Object sa = tempinst.tempdecl;
					if (!sa)
						goto Lnomatch;
					if (ta.specAlias && sa != ta.specAlias)
						goto Lnomatch;
					if (dedtypes[i])
					{   // Must match already deduced symbol
						Object s = dedtypes[i];

						if (s != sa)
							goto Lnomatch;
					}
					dedtypes[i] = sa;
				}
			}
			else if (tempinst.tempdecl != tp.tempinst.tempdecl)
				goto Lnomatch;

L2:

			for (int i = 0; 1; i++)
			{
				//printf("\ttest: tempinst->tiargs[%d]\n", i);
				Object o1;
				if (i < tempinst.tiargs.dim)
					o1 = tempinst.tiargs[i];
				else if (i < tempinst.tdtypes.dim && i < tp.tempinst.tiargs.dim)
					// Pick up default arg
					o1 = tempinst.tdtypes[i];
				else
					break;

				if (i >= tp.tempinst.tiargs.dim)
					goto Lnomatch;

				Object o2 = tp.tempinst.tiargs[i];

				Type t1 = isType(o1);
				Type t2 = isType(o2);

				Expression e1 = isExpression(o1);
				Expression e2 = isExpression(o2);

				Dsymbol s1 = isDsymbol(o1);
				Dsymbol s2 = isDsymbol(o2);

				Tuple v1 = isTuple(o1);
				Tuple v2 = isTuple(o2);
static if (0) {
				if (t1)	printf("t1 = %s\n", t1.toChars());
				if (t2)	printf("t2 = %s\n", t2.toChars());
				if (e1)	printf("e1 = %s\n", e1.toChars());
				if (e2)	printf("e2 = %s\n", e2.toChars());
				if (s1)	printf("s1 = %s\n", s1.toChars());
				if (s2)	printf("s2 = %s\n", s2.toChars());
				if (v1)	printf("v1 = %s\n", v1.toChars());
				if (v2)	printf("v2 = %s\n", v2.toChars());
}

				TemplateTupleParameter ttp;
				int j;
				if (t2 &&
						t2.ty == Tident &&
						i == tp.tempinst.tiargs.dim - 1 &&
						i == tempinst.tempdecl.parameters.dim - 1 &&
						(ttp = tempinst.tempdecl.isVariadic()) !is null)
				{
					/* Given:
					 *  struct A(B...) {}
					 *  alias A!(int, float) X;
					 *  static if (!is(X Y == A!(Z), Z))
					 * deduce that Z is a tuple(int, float)
					 */

					j = templateParameterLookup(t2, parameters);
					if (j == -1)
						goto Lnomatch;

					/* Create tuple from remaining args
					 */
					Tuple vt = new Tuple();
					int vtdim = tempinst.tiargs.dim - i;
					vt.objects.setDim(vtdim);
					for (size_t k = 0; k < vtdim; k++)
						vt.objects[k] = tempinst.tiargs[i + k];

					auto v = cast(Tuple)dedtypes[j];
					if (v)
					{
						if (!match(v, vt, tempinst.tempdecl, sc))
							goto Lnomatch;
					}
					else
						dedtypes[j] = vt;
					break; //return MATCHexact;
				}

				if (t1 && t2)
				{
					if (!t1.deduceType(sc, t2, parameters, dedtypes))
						goto Lnomatch;
				}
				else if (e1 && e2)
				{
					if (!e1.equals(e2))
					{   if (e2.op == TOKvar)
						{
							/*
							 * (T:Number!(e2), int e2)
							 */
							j = templateIdentifierLookup((cast(VarExp)e2).var.ident, parameters);
							goto L1;
						}
						goto Lnomatch;
					}
				}
				else if (e1 && t2 && t2.ty == Tident)
				{
					j = templateParameterLookup(t2, parameters);
L1:
					if (j == -1)
						goto Lnomatch;
					auto tp_ = parameters[j];
					// BUG: use tp->matchArg() instead of the following
					TemplateValueParameter tv = tp_.isTemplateValueParameter();
					if (!tv)
						goto Lnomatch;
					Expression e = cast(Expression)dedtypes[j];
					if (e)
					{
						if (!e1.equals(e))
							goto Lnomatch;
					}
					else
					{   Type vt = tv.valType.semantic(Loc(0), sc);
						MATCH m = cast(MATCH)e1.implicitConvTo(vt);
						if (!m)
							goto Lnomatch;
						dedtypes[j] = e1;
					}
				}
				else if (s1 && t2 && t2.ty == Tident)
				{
					j = templateParameterLookup(t2, parameters);
					if (j == -1)
						goto Lnomatch;
					auto tp_ = parameters[j];
					// BUG: use tp->matchArg() instead of the following
					TemplateAliasParameter ta = tp_.isTemplateAliasParameter();
					if (!ta)
						goto Lnomatch;
					auto s = cast(Dsymbol)dedtypes[j];
					if (s)
					{
						if (!s1.equals(s))
							goto Lnomatch;
					}
					else
					{
						dedtypes[j] = s1;
					}
				}
				else if (s1 && s2)
				{
					if (!s1.equals(s2))
						goto Lnomatch;
				}
				// BUG: Need to handle tuple parameters
				else
					goto Lnomatch;
			}
		}
		return Type.deduceType(sc, tparam, parameters, dedtypes);

Lnomatch:
		//printf("no match\n");
		return MATCHnomatch;
	}
}
