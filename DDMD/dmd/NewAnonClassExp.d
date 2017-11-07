module dmd.NewAnonClassExp;

import dmd.common;
import dmd.Expression;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.ClassDeclaration;
import dmd.DeclarationExp;
import dmd.NewExp;
import dmd.CommaExp;
import dmd.PREC;
import dmd.HdrGenState;
import dmd.ArrayTypes;
import dmd.TOK;
import dmd.expression.Util;

import dmd.DDMDExtensions;

class NewAnonClassExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	/* thisexp.new(newargs) class baseclasses { } (arguments)
     */
    Expression thisexp;	// if !NULL, 'this' for class being allocated
    Expressions newargs;	// Array of Expression's to call new operator
    ClassDeclaration cd;	// class being instantiated
    Expressions arguments;	// Array of Expression's to call class constructor

	this(Loc loc, Expression thisexp, Expressions newargs, ClassDeclaration cd, Expressions arguments)
	{
		register();
		super(loc, TOKnewanonclass, NewAnonClassExp.sizeof);
		this.thisexp = thisexp;
		this.newargs = newargs;
		this.cd = cd;
		this.arguments = arguments;
	}

	override Expression syntaxCopy()
	{
		return new NewAnonClassExp(loc, 
			thisexp ? thisexp.syntaxCopy() : null,
			arraySyntaxCopy(newargs),
			cast(ClassDeclaration)cd.syntaxCopy(null),
			arraySyntaxCopy(arguments));
	}
	
	override Expression semantic(Scope sc)
	{
version (LOGSEMANTIC) {
		printf("NewAnonClassExp.semantic() %s\n", toChars());
		//printf("thisexp = %p\n", thisexp);
		//printf("type: %s\n", type.toChars());
}

		Expression d = new DeclarationExp(loc, cd);
		d = d.semantic(sc);

		Expression n = new NewExp(loc, thisexp, newargs, cd.type, arguments);

		Expression c = new CommaExp(loc, d, n);
		return c.semantic(sc);
	}

	override bool checkSideEffect(int flag)
	{
		return true;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		if (thisexp)
		{	
			expToCBuffer(buf, hgs, thisexp, PREC.PREC_primary);
			buf.writeByte('.');
		}
		buf.writestring("new");
		if (newargs && newargs.dim)
		{
			buf.writeByte('(');
			argsToCBuffer(buf, newargs, hgs);
			buf.writeByte(')');
		}
		buf.writestring(" class ");
		if (arguments && arguments.dim)
		{
			buf.writeByte('(');
			argsToCBuffer(buf, arguments, hgs);
			buf.writeByte(')');
		}
		//buf.writestring(" { }");
		if (cd)
		{
			cd.toCBuffer(buf, hgs);
		}
	}

	override bool canThrow()
	{
		return true;
	}
}

