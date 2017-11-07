module dmd.DebugSymbol;

import dmd.common;
import dmd.Dsymbol;
import dmd.Identifier;
import dmd.Loc;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.Module;
import dmd.HdrGenState;
import dmd.Array;
import dmd.OutBuffer;

import dmd.condition.util.findCondition;

import dmd.DDMDExtensions;

/* DebugSymbol's happen for statements like:
 *	debug = identifier;
 *	debug = integer;
 */
class DebugSymbol : Dsymbol
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
		this.level = level;
		this.loc = loc;
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		DebugSymbol ds = new DebugSymbol(loc, ident);
		ds.level = level;
		return ds;
	}

    override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
	{
		//printf("DebugSymbol.addMember('%s') %s\n", sd.toChars(), toChars());
		Module m;

		// Do not add the member to the symbol table,
		// just make sure subsequent debug declarations work.
		m = sd.isModule();
		if (ident)
		{
			if (!m)
				error("declaration must be at module level");
			else
			{
				if (findCondition(m.debugidsNot, ident))
					error("defined after use");
				if (!m.debugids)
					m.debugids = new Vector!string();
				m.debugids.push(ident.toChars());	///
			}
		}
		else
		{
			if (!m)
				error("level declaration must be at module level");
			else
				m.debuglevel = level;
		}
		
		return false;
	}
	
    override void semantic(Scope sc)
	{
		//printf("DebugSymbol.semantic() %s\n", toChars());
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("debug = ");
		if (ident)
			buf.writestring(ident.toChars());
		else
			buf.printf("%u", level);
		buf.writestring(";");
		buf.writenl();
	}
	
    override string kind()
	{
		return "debug";
	}
}
