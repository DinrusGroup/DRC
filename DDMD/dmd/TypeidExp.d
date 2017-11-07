module dmd.TypeidExp;

import dmd.common;
import dmd.Expression;
import dmd.Type;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.Dsymbol;
import dmd.TY;
import dmd.Id;
import dmd.ErrorExp;
import dmd.DotIdExp;
import dmd.CommaExp;
import dmd.templates.Util;

import dmd.DDMDExtensions;

class TypeidExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Object obj;

	this(Loc loc, Object o)
	{
		register();
		super(loc, TOK.TOKtypeid, TypeidExp.sizeof);
		this.obj = o;
	}

	override Expression syntaxCopy()
	{
		return new TypeidExp(loc, objectSyntaxCopy(obj));
	}

	override Expression semantic(Scope sc)
	{
		Expression e;

	version (LOGSEMANTIC) {
		printf("TypeidExp.semantic() %s\n", toChars());
	}
		Type ta = isType(obj);
		Expression ea = isExpression(obj);
		Dsymbol sa = isDsymbol(obj);

        //printf("ta %p ea %p sa %p\n", ta, ea, sa);

		if (ta)
		{
			ta.resolve(loc, sc, &ea, &ta, &sa);
		}
        
		if (ea)
		{
			ea = ea.semantic(sc);
			ea = resolveProperties(sc, ea);
			ta = ea.type;
			if (ea.op == TOKtype)
				ea = null;
		}

		if (!ta)
		{	
        	//printf("ta %p ea %p sa %p\n", ta, ea, sa);
            error("no type for typeid(%s)", ea ? ea.toChars() : (sa ? sa.toChars() : ""));
			return new ErrorExp();
		}

		if (ea && ta.toBasetype().ty == TY.Tclass)
		{   /* Get the dynamic type, which is .classinfo
		 */
			e = new DotIdExp(ea.loc, ea, Id.classinfo_);
			e = e.semantic(sc);
		}
		else
		{	/* Get the static type
		 */
			e = ta.getTypeInfo(sc);
			if (e.loc.linnum == 0)
				e.loc = loc;		// so there's at least some line number info
			if (ea)
			{
				e = new CommaExp(loc, ea, e);	// execute ea
				e = e.semantic(sc);
			}
		}
		return e;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
}

