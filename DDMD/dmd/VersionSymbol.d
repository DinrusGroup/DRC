module dmd.VersionSymbol;

import dmd.common;
import dmd.Dsymbol;
import dmd.Loc;
import dmd.Identifier;
import dmd.Module;
import dmd.Array;
import dmd.VersionCondition;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.HdrGenState;
import dmd.String;
import dmd.OutBuffer;

import dmd.DDMDExtensions;

/* VersionSymbol's happen for statements like:
 *	version = identifier;
 *	version = integer;
 */
class VersionSymbol : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));

    uint level;

    this(Loc loc, Identifier ident)
	{
		register();
		super(ident);
		this.loc = loc;
	}

    this(Loc loc, uint level)
	{
		register();
		super();

		this.level = level;
		this.loc = loc;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		VersionSymbol ds = new VersionSymbol(loc, ident);
		ds.level = level;
		return ds;
	}

    override bool addMember(Scope sc, ScopeDsymbol s, bool memnum)
	{
		//printf("VersionSymbol::addMember('%s') %s\n", sd->toChars(), toChars());

		// Do not add the member to the symbol table,
		// just make sure subsequent debug declarations work.
		Module m = s.isModule();
		if (ident)
		{
			VersionCondition.checkPredefined(loc, ident.toChars());
			if (!m)
				error("declaration must be at module level");
			else
			{
				if (findCondition(m.versionidsNot, ident))
					error("defined after use");
				m.versionids.push(ident.toChars());
			}
		}
		else
		{
			if (!m)
				error("level declaration must be at module level");
			else
				m.versionlevel = level;
		}

		return false;
	}

    override void semantic(Scope sc)
	{
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("version = ");
		if (ident)
			buf.writestring(ident.toChars());
		else
			buf.printf("%u", level);
		buf.writestring(";");
		buf.writenl();
	}

    override string kind()
	{
		return "version";
	}
}
