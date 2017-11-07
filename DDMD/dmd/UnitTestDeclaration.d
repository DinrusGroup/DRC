module dmd.UnitTestDeclaration;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.Loc;
import dmd.Dsymbol;
import dmd.AggregateDeclaration;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Type;
import dmd.Scope;
import dmd.Global;
import dmd.LINK;
import dmd.TypeFunction;
import dmd.Module;
import dmd.STC;
import dmd.Lexer;
import dmd.Identifier;

import dmd.DDMDExtensions;

/*******************************
 * Generate unique unittest function Id so we can have multiple
 * instances per module.
 */
Identifier unitTestId()
{
    return Lexer.uniqueId("__unittest");
}

class UnitTestDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Loc endloc)
	{
		register();
		super(loc, endloc, unitTestId(), STC.STCundefined, null);
	}

    override Dsymbol syntaxCopy(Dsymbol s)
	{
		UnitTestDeclaration utd;

		assert(!s);
		utd = new UnitTestDeclaration(loc, endloc);

		return FuncDeclaration.syntaxCopy(utd);
	}

    override void semantic(Scope sc)
	{
		if (global.params.useUnitTests)
		{
			if (!type)
				type = new TypeFunction(null, Type.tvoid, false, LINKd);
			Scope sc2 = sc.push();
			sc2.linkage = LINK.LINKd;
			FuncDeclaration.semantic(sc2);
			sc2.pop();
		}

static if (false)
{
		// We're going to need ModuleInfo even if the unit tests are not
		// compiled in, because other modules may import this module and refer
		// to this ModuleInfo.
		// (This doesn't make sense to me?)
		Module m = getModule();
		if (!m)
			m = sc.module_;
		if (m)
		{
			// writef("module3 %s needs moduleinfo\n", m.toChars());
			m.needmoduleinfo = 1;
		}
}
	}

    override AggregateDeclaration isThis()
	{
		return null;
	}

    override bool isVirtual()
	{
		return false;
	}

    override bool addPreInvariant()
	{
		return false;
	}

    override bool addPostInvariant()
	{
		return false;
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

    override UnitTestDeclaration isUnitTestDeclaration() { return this; }
}
