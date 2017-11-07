module dmd.ConditionalDeclaration;

import dmd.common;
import dmd.AttribDeclaration;
import dmd.Condition;
import dmd.Array;
import dmd.Dsymbol;
import dmd.Scope;
import dmd.ScopeDsymbol;
import dmd.OutBuffer;
import dmd.HdrGenState;

import dmd.DDMDExtensions;

class ConditionalDeclaration : AttribDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    Condition condition;
    Dsymbols elsedecl;	// array of Dsymbol's for else block

    this(Condition condition, Dsymbols decl, Dsymbols elsedecl)
	{
		register();
		super(decl);
		//printf("ConditionalDeclaration.ConditionalDeclaration()\n");
		this.condition = condition;
		this.elsedecl = elsedecl;
	}
	
    override Dsymbol syntaxCopy(Dsymbol s)
	{
	    ConditionalDeclaration dd;
	
	    assert(!s);
	    dd = new ConditionalDeclaration(condition.syntaxCopy(),
		Dsymbol.arraySyntaxCopy(decl),
		Dsymbol.arraySyntaxCopy(elsedecl));
	    return dd;
	}
	
    override bool oneMember(Dsymbol* ps)
	{
		//printf("ConditionalDeclaration.oneMember(), inc = %d\n", condition.inc);
		if (condition.inc)
		{
			auto d = condition.include(null, null) ? decl : elsedecl;
			return Dsymbol.oneMembers(d, ps);
		}
		*ps = null;
		return true;
	}
	
    override void emitComment(Scope sc)
	{
	    //printf("ConditionalDeclaration.emitComment(sc = %p)\n", sc);
	    if (condition.inc)
	    {
	    	AttribDeclaration.emitComment(sc);
	    }
	    else if (sc.docbuf)
	    {
			/* If generating doc comment, be careful because if we're inside
			 * a template, then include(NULL, NULL) will fail.
			 */
			auto d = decl ? decl : elsedecl;
			foreach(s; d)
			    s.emitComment(sc);
	    }
	}
	
	// Decide if 'then' or 'else' code should be included

    override Dsymbols include(Scope sc, ScopeDsymbol sd)
	{
		//printf("ConditionalDeclaration.include()\n");
		assert(condition);
		return condition.include(sc, sd) ? decl : elsedecl;
	}
	
    override void addComment(string comment)
	{
		/* Because addComment is called by the parser, if we called
		 * include() it would define a version before it was used.
		 * But it's no problem to drill down to both decl and elsedecl,
		 * so that's the workaround.
		 */

		if (comment)
		{
			auto d = decl;

			for (int j = 0; j < 2; j++)
			{
				if (d)
				{
					foreach(s; d)
						//printf("ConditionalDeclaration::addComment %s\n", s.toChars());
						s.addComment(comment);
				}
				d = elsedecl;
			}
		}
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
	    condition.toCBuffer(buf, hgs);
	    if (decl || elsedecl)
	    {
			buf.writenl();
			buf.writeByte('{');
			buf.writenl();
			if (decl)
			{
			    foreach (Dsymbol s; decl)
			    {
					buf.writestring("    ");
					s.toCBuffer(buf, hgs);
			    }
			}
			buf.writeByte('}');
			if (elsedecl)
			{
			    buf.writenl();
			    buf.writestring("else");
			    buf.writenl();
			    buf.writeByte('{');
			    buf.writenl();
			    foreach (Dsymbol s; elsedecl)
			    {
					buf.writestring("    ");
					s.toCBuffer(buf, hgs);
			    }
			    buf.writeByte('}');
			}
	    }
	    else
		buf.writeByte(':');
	    buf.writenl();
	}

	override void toJsonBuffer(OutBuffer buf)
	{
		// writef("ConditionalDeclaration::toJsonBuffer()\n");
		if (condition.inc)
		{
			super.toJsonBuffer(buf);
		}
	}

    override void importAll(Scope sc)
    {
        Dsymbols d = include(sc, null);

        //writef("\tConditionalDeclaration::importAll '%s', d = %p\n",toChars(), d);
        if (d)
        {
           foreach (s; d)
               s.importAll(sc);
        }
    }
    
    override void setScope(Scope sc)
    {
		Dsymbols d = include(sc, null);
		
		//writef("\tConditionalDeclaration::setScope '%s', d = %p\n",toChars(), d);
		if (d)
		{
			foreach (s; d)
				s.setScope(sc);
		}

    }
}