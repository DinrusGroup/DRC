module dmd.StaticIfDeclaration;

import dmd.common;
import dmd.ConditionalDeclaration;
import dmd.ScopeDsymbol;
import dmd.AttribDeclaration;
import dmd.Scope;
import dmd.Condition;
import dmd.Array;
import dmd.Dsymbol;

import dmd.DDMDExtensions;

class StaticIfDeclaration : ConditionalDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	ScopeDsymbol sd;
	int addisdone;

	this(Condition condition, Dsymbols decl, Dsymbols elsedecl)
	{
		register();
		super(condition, decl, elsedecl);
		//printf("StaticIfDeclaration::StaticIfDeclaration()\n");
	}
	
	override Dsymbol syntaxCopy(Dsymbol s)
	{
		StaticIfDeclaration dd;

		assert(!s);
		dd = new StaticIfDeclaration(condition.syntaxCopy(),
		Dsymbol.arraySyntaxCopy(decl),
		Dsymbol.arraySyntaxCopy(elsedecl));
		return dd;
	}

	override bool addMember(Scope sc, ScopeDsymbol sd, bool memnum)
	{
		//printf("StaticIfDeclaration.addMember() '%s'\n",toChars());
		/* This is deferred until semantic(), so that
		 * expressions in the condition can refer to declarations
		 * in the same scope, such as:
		 *
		 * template Foo(int i)
		 * {
		 *	 const int j = i + 1;
		 *	 static if (j == 3)
		 *		 const int k;
		 * }
		 */
		this.sd = sd;
		bool m = false;

		if (!memnum)
		{	
			m = AttribDeclaration.addMember(sc, sd, memnum);
			addisdone = 1;
		}
		return m;
	}
	
	override void importAll(Scope sc)
	{
		// do not evaluate condition before semantic pass
	}

	override void setScope(Scope sc)
	{
		// do not evaluate condition before semantic pass
	}

	override void semantic(Scope sc)
	{
		auto d = include(sc, sd);

		//printf("\tStaticIfDeclaration.semantic '%s', d = %p\n",toChars(), d);
		if (d)
		{
			if (!addisdone)
			{   
				AttribDeclaration.addMember(sc, sd, true);
				addisdone = 1;
			}

			foreach(Dsymbol s; d)
				s.semantic(sc);
		}
	}

	override string kind()
	{
		assert(false);
	}
}
