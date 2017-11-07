module dmd.TypeIdentifier;

import dmd.common;
import dmd.TypeQualified;
import dmd.MOD;
import dmd.Identifier;
import dmd.IdentifierExp;
import dmd.DotIdExp;
import dmd.TypeTypedef;
import dmd.Loc;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.Scope;
import dmd.Type;
import dmd.Dsymbol;
import dmd.MATCH;
import dmd.ArrayTypes;
import dmd.TY;
import dmd.Util;

debug import dmd.Global;

import dmd.DDMDExtensions;

class TypeIdentifier : TypeQualified
{
	mixin insertMemberExtension!(typeof(this));

    Identifier ident;

    this(Loc loc, Identifier ident)
	{
		register();
		super(TY.Tident, loc);
		this.ident = ident;
	}
	
    override Type syntaxCopy()
	{
		TypeIdentifier t = new TypeIdentifier(loc, ident);
		t.syntaxCopyHelper(this);
		t.mod = mod;

		return t;
	}
	
    //char *toChars();
	
    override void toDecoBuffer(OutBuffer buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		string name = ident.toChars();
		buf.printf("%d%s", name.length, name);
	}
	
    override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		buf.writestring(this.ident.toChars());
		toCBuffer2Helper(buf, hgs);
	}

	/*************************************
	 * Takes an array of Identifiers and figures out if
	 * it represents a Type or an Expression.
	 * Output:
	 *	if expression, *pe is set
	 *	if type, *pt is set
	 */
    override void resolve(Loc loc, Scope sc, Expression* pe, Type* pt, Dsymbol* ps)
	{
		Dsymbol scopesym;

		//printf("TypeIdentifier::resolve(sc = %p, idents = '%s')\n", sc, toChars());
		Dsymbol s = sc.search(loc, ident, &scopesym);
		resolveHelper(loc, sc, s, scopesym, pe, pt, ps);
		if (*pt)
			(*pt) = (*pt).addMod(mod);
	}
	
	/*****************************************
	 * See if type resolves to a symbol, if so,
	 * return that symbol.
	 */
    override Dsymbol toDsymbol(Scope sc)
	{
		//printf("TypeIdentifier::toDsymbol('%s')\n", toChars());
		if (!sc)
			return null;
		//printf("ident = '%s'\n", ident.toChars());

		Dsymbol scopesym;
		Dsymbol s = sc.search(loc, ident, &scopesym);
		if (s)
		{
			for (int i = 0; i < idents.dim; i++)
			{
				Identifier id = cast(Identifier)idents.data[i];
				s = s.searchX(loc, sc, id);
				if (!s)                 // failed to find a symbol
				{	
					//printf("\tdidn't find a symbol\n");
					break;
				}
			}
		}

		return s;
	}
	
    override Type semantic(Loc loc, Scope sc)
	{
		Type t;
		Expression e;
		Dsymbol s;

		//printf("TypeIdentifier::semantic(%s)\n", toChars());
		resolve(loc, sc, &e, &t, &s);
		if (t)
		{
			//printf("\tit's a type %d, %s, %s\n", t.ty, t.toChars(), t.deco);

			if (t.ty == TY.Ttypedef)
			{   
				TypeTypedef tt = cast(TypeTypedef)t;

				if (tt.sym.sem == 1)
				error(loc, "circular reference of typedef %s", tt.toChars());
			}
			t = t.addMod(mod);
		}
		else
		{
debug {
		if (!global.gag) {
			writef("1: ");
		}
}
			if (s)
			{
				s.error(loc, "is used as a type");
				//halt();
			}
			else {
				error(loc, "%s is used as a type", toChars());
			}
			t = tvoid;
		}
		//t.print();
		return t;
	}
	
    override MATCH deduceType(Scope sc, Type tparam, TemplateParameters parameters, Objects dedtypes)
	{
	    // Extra check
		if (tparam && tparam.ty == Tident)
		{
			TypeIdentifier tp = cast(TypeIdentifier)tparam;

			for (int i = 0; i < idents.dim; i++)
			{
				Identifier id1 = cast(Identifier)idents.data[i];
				Identifier id2 = cast(Identifier)tp.idents.data[i];

				if (!id1.equals(id2))
					return MATCHnomatch;
			}
		}
		return Type.deduceType(sc, tparam, parameters, dedtypes);
	}
	
    override Type reliesOnTident()
	{
		return this;
	}
	
    override Expression toExpression()
	{
		Expression e = new IdentifierExp(loc, ident);
		for (int i = 0; i < idents.dim; i++)
		{
			Identifier id = cast(Identifier)idents.data[i];
			e = new DotIdExp(loc, e, id);
		}

		return e;
	}
}
