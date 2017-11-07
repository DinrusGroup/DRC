module dmd.TypeReturn;

import dmd.common;
import dmd.Loc;
import dmd.MOD;
import dmd.Type;
import dmd.TypeQualified;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Identifier;
import dmd.TY;

import dmd.DDMDExtensions;

class TypeReturn : TypeQualified
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc)
	{
		register();
		super(TY.Treturn, loc);
	}
	
    override Type syntaxCopy()
	{
		TypeReturn t = new TypeReturn(loc);
		t.syntaxCopyHelper(this);
		t.mod = mod;
		return t;
	}

    override Dsymbol toDsymbol(Scope sc)
	{
		Type t = semantic(Loc(0), sc);
		if (t is this)
			return null;

		return t.toDsymbol(sc);
	}
	
    override Type semantic(Loc loc, Scope sc)
	{
		Type t;
		if (!sc.func)
		{	
			error(loc, "typeof(return) must be inside function");
			goto Lerr;
		}
		t = sc.func.type.nextOf();
        if (!t)
        {
	        error(loc, "cannot use typeof(return) inside function %s with inferred return type", sc.func.toChars());
	        goto Lerr;
        }
		t = t.addMod(mod);

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
		return terror;
	}
	
    override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		buf.writestring("typeof(return)");
		toCBuffer2Helper(buf, hgs);
	}
}
