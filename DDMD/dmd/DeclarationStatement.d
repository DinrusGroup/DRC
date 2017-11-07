module dmd.DeclarationStatement;

import dmd.common;
import dmd.Loc;
import dmd.ExpStatement;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Statement;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Scope;
import dmd.DeclarationExp;
import dmd.TOK;
import dmd.VarDeclaration;

import dmd.DDMDExtensions;

class DeclarationStatement : ExpStatement
{
	mixin insertMemberExtension!(typeof(this));
	
    // Doing declarations as an expression, rather than a statement,
    // makes inlining functions much easier.

    this(Loc loc, Dsymbol declaration)
	{
		register();
		super(loc, new DeclarationExp(loc, declaration));
	}
	
    this(Loc loc, Expression exp)
	{
		register();
		super(loc, exp);
	}
	
    override Statement syntaxCopy()
	{
		DeclarationStatement ds = new DeclarationStatement(loc, exp.syntaxCopy());
		return ds;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		exp.toCBuffer(buf, hgs);
	}
	
    override void scopeCode(Scope sc, Statement* sentry, Statement* sexception, Statement* sfinally)
	{
		//printf("DeclarationStatement.scopeCode()\n");
		//print();

		*sentry = null;
		*sexception = null;
		*sfinally = null;

		if (exp)
		{
			if (exp.op == TOK.TOKdeclaration)
			{
				DeclarationExp de = cast(DeclarationExp)exp;
				VarDeclaration v = de.declaration.isVarDeclaration();
				if (v)
				{	
					Expression e;

					e = v.callAutoDtor(sc);
					if (e)
					{
						//printf("dtor is: "); e.print();
static if (false) {
						if (v.type.toBasetype().ty == Tstruct)
						{	
							/* Need a 'gate' to turn on/off destruction,
							 * in case v gets moved elsewhere.
							 */
							Identifier id = Lexer.uniqueId("__runDtor");
							ExpInitializer ie = new ExpInitializer(loc, new IntegerExp(1));
							VarDeclaration rd = new VarDeclaration(loc, Type.tint32, id, ie);
							*sentry = new DeclarationStatement(loc, rd);
							v.rundtor = rd;

							/* Rewrite e as:
							 *  rundtor && e
							 */
							Expression ve = new VarExp(loc, v.rundtor);
							e = new AndAndExp(loc, ve, e);
							e.type = Type.tbool;
						}
}
						*sfinally = new ExpStatement(loc, e);
					}
				}
			}
		}
	}

    override DeclarationStatement isDeclarationStatement() { return this; }
}
