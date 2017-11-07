module dmd.ConditionalStatement;

import dmd.common;
import dmd.Statement;
import dmd.Condition;
import dmd.Loc;
import dmd.OutBuffer;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.ArrayTypes;
import dmd.BE;

import dmd.DDMDExtensions;

class ConditionalStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Condition condition;
    Statement ifbody;
    Statement elsebody;

    this(Loc loc, Condition condition, Statement ifbody, Statement elsebody)
	{
		register();
		super(loc);
		this.condition = condition;
		this.ifbody = ifbody;
		this.elsebody = elsebody;
	}
	
    override Statement syntaxCopy()
	{
		Statement e = null;
		if (elsebody)
			e = elsebody.syntaxCopy();
		ConditionalStatement s = new ConditionalStatement(loc, condition.syntaxCopy(), ifbody.syntaxCopy(), e);
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		//printf("ConditionalStatement.semantic()\n");

		// If we can short-circuit evaluate the if statement, don't do the
		// semantic analysis of the skipped code.
		// This feature allows a limited form of conditional compilation.
		if (condition.include(sc, null))
		{
			ifbody = ifbody.semantic(sc);
			return ifbody;
		}
		else
		{
			if (elsebody)
				elsebody = elsebody.semantic(sc);
			return elsebody;
		}
	}
	
    override Statements flatten(Scope sc)
	{
		Statement s;

		if (condition.include(sc, null))
			s = ifbody;
		else
			s = elsebody;

		auto a = new Statements();
		a.push(s);

		return a;
	}
	
    override bool usesEH()
	{
		assert(false);
	}
	
    override BE blockExit()
	{
		assert(false);
	}

    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
}
