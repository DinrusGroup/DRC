module dmd.Catch;

import dmd.common;
import dmd.Loc;
import dmd.Type;
import dmd.Scope;
import dmd.Identifier;
import dmd.VarDeclaration;
import dmd.Statement;
import dmd.OutBuffer;
import dmd.Id;
import dmd.TypeIdentifier;
import dmd.Util;
import dmd.ScopeDsymbol;
import dmd.HdrGenState;
import dmd.BE;

import dmd.TObject;

import dmd.DDMDExtensions;

class Catch : TObject
{
	mixin insertMemberExtension!(typeof(this));

    Loc loc;
    Type type;
    Identifier ident;
    VarDeclaration var = null;
    Statement handler;

    this(Loc loc, Type t, Identifier id, Statement handler)
	{
		register();

		//printf("Catch(%s, loc = %s)\n", id.toChars(), loc.toChars());
		this.loc = loc;
		this.type = t;
		this.ident = id;
		this.handler = handler;
	}

    Catch syntaxCopy()
	{
		Catch c = new Catch(loc, (type ? type.syntaxCopy() : null), ident, (handler ? handler.syntaxCopy() : null));
		return c;
	}

    void semantic(Scope sc)
	{
		ScopeDsymbol sym;

		//printf("Catch.semantic(%s)\n", ident.toChars());

	version (IN_GCC) {
	} else {
		if (sc.tf)
		{
			/* This is because the _d_local_unwind() gets the stack munged
			 * up on this. The workaround is to place any try-catches into
			 * a separate function, and call that.
			 * To fix, have the compiler automatically convert the finally
			 * body into a nested function.
			 */
			error(loc, "cannot put catch statement inside finally block");
		}
	}

		sym = new ScopeDsymbol();
		sym.parent = sc.scopesym;
		sc = sc.push(sym);

		if (!type)
			type = new TypeIdentifier(Loc(0), Id.Object_);
		type = type.semantic(loc, sc);
		if (!type.toBasetype().isClassHandle())
			error("can only catch class objects, not '%s'", type.toChars());
		else if (ident)
		{
			var = new VarDeclaration(loc, type, ident, null);
			var.parent = sc.parent;
			sc.insert(var);
		}
		handler = handler.semantic(sc);

		sc.pop();
	}

    BE blockExit()
	{
		return handler ? handler.blockExit() : BE.BEfallthru;
	}

    void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("catch");
		if (type)
		{   
			buf.writebyte('(');
			type.toCBuffer(buf, ident, hgs);
			buf.writebyte(')');
		}
		buf.writenl();
		buf.writebyte('{');
		buf.writenl();
		if (handler)
			handler.toCBuffer(buf, hgs);
		buf.writebyte('}');
		buf.writenl();
	}
}