module dmd.StaticIfCondition;

import dmd.common;
import dmd.Expression;
import dmd.ScopeDsymbol;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.Condition;
import dmd.HdrGenState;
import dmd.WANT;
import dmd.Util;

import dmd.DDMDExtensions;

class StaticIfCondition : Condition
{
	mixin insertMemberExtension!(typeof(this));

	Expression exp;

	this(Loc loc, Expression exp)
	{
		register();
		super(loc);
		this.exp = exp;
	}

	override Condition syntaxCopy()
	{
	    return new StaticIfCondition(loc, exp.syntaxCopy());
	}

	override bool include(Scope sc, ScopeDsymbol s)
	{
	static if (false) {
		printf("StaticIfCondition.include(sc = %p, s = %p)\n", sc, s);
		if (s)
		{
			printf("\ts = '%s', kind = %s\n", s.toChars(), s.kind());
		}
	}
		if (inc == 0)
		{
			if (!sc)
			{
				error(loc, "static if conditional cannot be at global scope");
				inc = 2;
				return 0;
			}

			sc = sc.push(sc.scopesym);
			sc.sd = s;			// s gets any addMember()
			sc.flags |= SCOPE.SCOPEstaticif;
			Expression e = exp.semantic(sc);
			sc.pop();
			e = e.optimize(WANTvalue | WANTinterpret);
			if (e.isBool(true))
				inc = 1;
			else if (e.isBool(false))
				inc = 2;
			else
			{
				e.error("expression %s is not constant or does not evaluate to a bool", e.toChars());
				inc = 2;
			}
		}
		return (inc == 1);
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
}

