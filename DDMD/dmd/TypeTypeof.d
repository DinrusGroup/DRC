module dmd.TypeTypeof;

import dmd.common;
import dmd.TypeFunction;
import dmd.TypeQualified;
import dmd.Expression;
import dmd.Identifier;
import dmd.Scope;
import dmd.Loc;
import dmd.MOD;
import dmd.Type;
import dmd.Dsymbol;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.TY;
import dmd.Util;
import dmd.TOK;

import dmd.DDMDExtensions;

class TypeTypeof : TypeQualified
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;

    this(Loc loc, Expression exp)
	{
		register();
		super(TY.Ttypeof, loc);
		this.exp = exp;
	}
	
    override Type syntaxCopy()
	{
		//printf("TypeTypeof.syntaxCopy() %s\n", toChars());
		TypeTypeof t;

		t = new TypeTypeof(loc, exp.syntaxCopy());
		t.syntaxCopyHelper(this);
		t.mod = mod;
		return t;
	}
	
    override Dsymbol toDsymbol(Scope sc)
	{
		Type t = semantic(loc, sc);
		if (t is this)
			return null;

		return t.toDsymbol(sc);
	}
	
    override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		buf.writestring("typeof(");
		exp.toCBuffer(buf, hgs);
		buf.writeByte(')');
		toCBuffer2Helper(buf, hgs);
	}

    override Type semantic(Loc loc, Scope sc)
	{
		Expression e;
		Type t;

		//printf("TypeTypeof.semantic() %.*s\n", toChars());

		//static int nest; if (++nest == 50) *(char*)0=0;

/+static if (false) {
		/* Special case for typeof(this) and typeof(super) since both
		 * should work even if they are not inside a non-static member function
		 */
		if (exp.op == TOK.TOKthis || exp.op == TOK.TOKsuper)
		{
			/ / Find enclosing struct or class
			for (Dsymbol *s = sc.parent; 1; s = s.parent)
			{
				ClassDeclaration *cd;
				StructDeclaration *sd;

				if (!s)
				{
				error(loc, "%s is not in a struct or class scope", exp.toChars());
				goto Lerr;
				}
				cd = s.isClassDeclaration();
				if (cd)
				{
				if (exp.op == TOK.TOKsuper)
				{
					cd = cd.baseClass;
					if (!cd)
					{	error(loc, "class %s has no 'super'", s.toChars());
					goto Lerr;
					}
				}
				t = cd.type;
				break;
				}
				sd = s.isStructDeclaration();
				if (sd)
				{
				if (exp.op == TOK.TOKsuper)
				{
					error(loc, "struct %s has no 'super'", sd.toChars());
					goto Lerr;
				}
				t = sd.type.pointerTo();
				break;
				}
			}
		}
		else
}+/
		{
			sc.intypeof++;
			exp = exp.semantic(sc);
			if (exp.type && exp.type.ty == Tfunction &&
				(cast(TypeFunction)exp.type).isproperty)
				exp = resolveProperties(sc, exp);
			sc.intypeof--;
			if (exp.op == TOK.TOKtype)
			{
				error(loc, "argument %s to typeof is not an expression", exp.toChars());
	            goto Lerr;
			}
			t = exp.type;
			if (!t)
			{
				error(loc, "expression (%s) has no type", exp.toChars());
				goto Lerr;
			}
			if (t.ty == TY.Ttypeof)
            {
				error(loc, "forward reference to %s", toChars());
               	goto Lerr;
            }

			/* typeof should reflect the true type,
			 * not what 'auto' would have gotten us.
			 */
			//t = t.toHeadMutable();
		}
		if (idents.dim)
		{
			Dsymbol s = t.toDsymbol(sc);
			for (size_t i = 0; i < idents.dim; i++)
			{
				if (!s)
				break;
				Identifier id = cast(Identifier)idents.data[i];
				s = s.searchX(loc, sc, id);
			}

			if (s)
			{
				t = s.getType();
				if (!t)
				{	
					error(loc, "%s is not a type", s.toChars());
					goto Lerr;
				}
			}
			else
			{   
				error(loc, "cannot resolve .property for %s", toChars());
				goto Lerr;
			}
		}
		return t;

	Lerr:
		return tvoid;
	}
	
    override ulong size(Loc loc)
	{
		assert(false);
	}
}
