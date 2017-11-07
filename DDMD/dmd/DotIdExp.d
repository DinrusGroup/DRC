module dmd.DotIdExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.IntegerExp;
import dmd.Type;
import dmd.TY;
import dmd.ScopeExp;
import dmd.StringExp;
import dmd.PtrExp;
import dmd.TypePointer;
import dmd.Dsymbol;
import dmd.EnumMember;
import dmd.VarDeclaration;
import dmd.ThisExp;
import dmd.DotVarExp;
import dmd.VarExp;
import dmd.CommaExp;
import dmd.FuncDeclaration;
import dmd.OverloadSet;
import dmd.OverExp;
import dmd.TypeExp;
import dmd.TupleDeclaration;
import dmd.ScopeDsymbol;
import dmd.Import;
import dmd.Id;
import dmd.TupleExp;
import dmd.ArrayTypes;
import dmd.UnaExp;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.TOK;
import dmd.HdrGenState;
import dmd.ClassDeclaration;
import dmd.StructDeclaration;
import dmd.AggregateDeclaration;
import dmd.DotExp;
import dmd.Global;
import dmd.IdentifierExp;
import dmd.CallExp;
import dmd.PREC;

import dmd.expression.Util;

import dmd.DDMDExtensions;

class DotIdExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	Identifier ident;

	this(Loc loc, Expression e, Identifier ident)
	{
		register();
		super(loc, TOK.TOKdot, DotIdExp.sizeof, e);
		this.ident = ident;
	}

	override Expression semantic(Scope sc)
	{
		// Indicate we didn't come from CallExp::semantic()
		return semantic(sc, 0);
	}

	Expression semantic(Scope sc, int flag)
	{
		Expression e;
		Expression eleft;
		Expression eright;

version (LOGSEMANTIC) {
		printf("DotIdExp.semantic(this = %p, '%s')\n", this, toChars());
		//printf("e1.op = %d, '%s'\n", e1.op, Token.toChars(e1.op));
}

	//{ static int z; fflush(stdout); if (++z == 10) *(char*)0=0; }

static if (false) {
		/* Don't do semantic analysis if we'll be converting
		 * it to a string.
		 */
		if (ident == Id.stringof)
		{	
			char *s = e1.toChars();
			e = new StringExp(loc, s, strlen(s), 'c');
			e = e.semantic(sc);
			return e;
		}
}

		/* Special case: rewrite this.id and super.id
		 * to be classtype.id and baseclasstype.id
		 * if we have no this pointer.
		 */
		if ((e1.op == TOK.TOKthis || e1.op == TOK.TOKsuper) && !hasThis(sc))
		{
			ClassDeclaration cd;
			StructDeclaration sd;
			AggregateDeclaration ad;

			ad = sc.getStructClassScope();
			if (ad)
			{
				cd = ad.isClassDeclaration();
				if (cd)
				{
					if (e1.op == TOK.TOKthis)
					{
						e = typeDotIdExp(loc, cd.type, ident);
						return e.semantic(sc);
					}
					else if (cd.baseClass && e1.op == TOK.TOKsuper)
					{
						e = typeDotIdExp(loc, cd.baseClass.type, ident);
						return e.semantic(sc);
					}
				}
				else
				{
					sd = ad.isStructDeclaration();
					if (sd)
					{
						if (e1.op == TOK.TOKthis)
						{
						e = typeDotIdExp(loc, sd.type, ident);
						return e.semantic(sc);
						}
					}
				}
			}
		}

		UnaExp.semantic(sc);

		if (e1.op == TOK.TOKdotexp)
		{
			DotExp de = cast(DotExp)e1;
			eleft = de.e1;
			eright = de.e2;
		}
		else
		{
			e1 = resolveProperties(sc, e1);
			eleft = null;
			eright = e1;
		}
		
version (DMDV2) {
		if (e1.op == TOK.TOKtuple && ident == Id.offsetof)
		{
			/* 'distribute' the .offsetof to each of the tuple elements.
			*/
			TupleExp te = cast(TupleExp)e1;
			Expressions exps = new Expressions();
			exps.setDim(te.exps.dim);
			for (int i = 0; i < exps.dim; i++)
			{   
				auto ee = te.exps[i];
				ee = ee.semantic(sc);
				ee = new DotIdExp(ee.loc, ee, Id.offsetof);
				exps[i] = ee;
			}
			e = new TupleExp(loc, exps);
			e = e.semantic(sc);
			return e;
		}
}

		if (e1.op == TOK.TOKtuple && ident == Id.length)
		{
			TupleExp te = cast(TupleExp)e1;
			e = new IntegerExp(loc, te.exps.dim, Type.tsize_t);
			return e;
		}

		if (e1.op == TOK.TOKdottd)
		{
			error("template %s does not have property %s", e1.toChars(), ident.toChars());
			return e1;
		}

		if (!e1.type)
		{
			error("expression %s does not have property %s", e1.toChars(), ident.toChars());
			return e1;
		}

		Type t1b = e1.type.toBasetype();

		if (eright.op == TOK.TOKimport)	// also used for template alias's
		{
			ScopeExp ie = cast(ScopeExp)eright;

			/* Disable access to another module's private imports.
			 * The check for 'is sds our current module' is because
			 * the current module should have access to its own imports.
			 */
			Dsymbol s = ie.sds.search(loc, ident, //0);
				(ie.sds.isModule() && ie.sds != sc.module_) ? 1 : 0);
			if (s)
			{
				s = s.toAlias();
				checkDeprecated(sc, s);

				EnumMember em = s.isEnumMember();
				if (em)
				{
				e = em.value;
				e = e.semantic(sc);
				return e;
				}

				VarDeclaration v = s.isVarDeclaration();
				if (v)
				{
				//printf("DotIdExp. Identifier '%s' is a variable, type '%s'\n", toChars(), v.type.toChars());
				if (v.inuse)
				{
					error("circular reference to '%s'", v.toChars());
					type = Type.tint32;
					return this;
				}
				type = v.type;
				if (v.needThis())
				{
					if (!eleft)
					eleft = new ThisExp(loc);
					e = new DotVarExp(loc, eleft, v);
					e = e.semantic(sc);
				}
				else
				{
					e = new VarExp(loc, v);
					if (eleft)
					{	
						e = new CommaExp(loc, eleft, e);
						e.type = v.type;
					}
				}
				return e.deref();
				}

				FuncDeclaration f = s.isFuncDeclaration();
				if (f)
				{
					//printf("it's a function\n");
					if (f.needThis())
					{
						if (!eleft)
						eleft = new ThisExp(loc);
						e = new DotVarExp(loc, eleft, f);
						e = e.semantic(sc);
					}
					else
					{
						e = new VarExp(loc, f, 1);
						if (eleft)
						{	e = new CommaExp(loc, eleft, e);
						e.type = f.type;
						}
					}
					return e;
				}
version (DMDV2) {
				OverloadSet o = s.isOverloadSet();
				if (o)
				{   
					//printf("'%s' is an overload set\n", o.toChars());
					return new OverExp(o);
				}
}

				Type t = s.getType();
				if (t)
				{
					return new TypeExp(loc, t);
				}

				TupleDeclaration tup = s.isTupleDeclaration();
				if (tup)
				{
					if (eleft)
						error("cannot have e.tuple");
					e = new TupleExp(loc, tup);
					e = e.semantic(sc);
					return e;
				}

				ScopeDsymbol sds = s.isScopeDsymbol();
				if (sds)
				{
					//printf("it's a ScopeDsymbol\n");
					e = new ScopeExp(loc, sds);
					e = e.semantic(sc);
					if (eleft)
						e = new DotExp(loc, eleft, e);
					return e;
				}

				Import imp = s.isImport();
				if (imp)
				{
					ScopeExp iee = new ScopeExp(loc, imp.pkg);
					return iee.semantic(sc);
				}

				// BUG: handle other cases like in IdentifierExp.semantic()
version (DEBUG) {
				printf("s = '%s', kind = '%s'\n", s.toChars(), s.kind());
}
				assert(0);
			}
			else if (ident is Id.stringof_)
			{  
				string ss = ie.toChars();
				e = new StringExp(loc, ss, 'c');
				e = e.semantic(sc);
				return e;
			}
			error("undefined identifier %s", toChars());
			type = Type.tvoid;
			return this;
		}
		else if (t1b.ty == TY.Tpointer &&
			 ident !is Id.init_ && ident !is Id.__sizeof &&
			 ident !is Id.alignof_ && ident !is Id.offsetof &&
			 ident !is Id.mangleof_ && ident !is Id.stringof_)
		{	/* Rewrite:
			 *   p.ident
			 * as:
			 *   (*p).ident
			 */
		e = new PtrExp(loc, e1);
		e.type = (cast(TypePointer)t1b).next;
		return e.type.dotExp(sc, e, ident);
		}
///version (DMDV2) {
		else if (t1b.ty == TY.Tarray ||
				 t1b.ty == TY.Tsarray ||
			 t1b.ty == TY.Taarray)
		{	
			/* If ident is not a valid property, rewrite:
			 *   e1.ident
			 * as:
			 *   .ident(e1)
			 */
			uint errors = global.errors;
			global.gag++;
			Type t1 = e1.type;
			e = e1.type.dotExp(sc, e1, ident);
			global.gag--;
			if (errors != global.errors)	// if failed to find the property
			{
				global.errors = errors;
				e1.type = t1;		// kludge to restore type
				e = new DotIdExp(loc, new IdentifierExp(loc, Id.empty), ident);
				e = new CallExp(loc, e, e1);
			}
			e = e.semantic(sc);
			return e;
		}
///}
		else
		{
			e = e1.type.dotExp(sc, e1, ident);
			if (!(flag && e.op == TOK.TOKdotti))	// let CallExp::semantic() handle this
				e = e.semantic(sc);
			return e;
		}
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		//printf("DotIdExp.toCBuffer()\n");
		expToCBuffer(buf, hgs, e1, PREC.PREC_primary);
		buf.writeByte('.');
		buf.writestring(ident.toChars());
	}

	override void dump(int i)
	{
		assert(false);
	}
}

