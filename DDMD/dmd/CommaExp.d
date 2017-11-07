module dmd.CommaExp;

import dmd.common;
import dmd.Loc;
import dmd.BinExp;
import dmd.IRState;
import dmd.Scope;
import dmd.IntRange;
import dmd.DeclarationExp;
import dmd.VarExp;
import dmd.VarDeclaration;
import dmd.Expression;
import dmd.GlobalExpressions;
import dmd.MATCH;
import dmd.WANT;
import dmd.TOK;
import dmd.Type;
import dmd.InterState;

import dmd.backend.elem;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class CommaExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		register();

		super(loc, TOK.TOKcomma, CommaExp.sizeof, e1, e2);
	}
	
    override Expression semantic(Scope sc)
	{
		if (!type)
		{	
			BinExp.semanticp(sc);
			type = e2.type;
		}
		return this;
	}
	
    override void checkEscape()
	{
		e2.checkEscape();
	}
	
    override void checkEscapeRef()
    {
        e2.checkEscapeRef();
    }
    
    override IntRange getIntRange()
	{
		assert(false);
	}

version (DMDV2) {
    override bool isLvalue()
	{
		return e2.isLvalue();
	}
}
    override Expression toLvalue(Scope sc, Expression e)
	{
		e2 = e2.toLvalue(sc, null);
		return this;
	}
	
    override Expression modifiableLvalue(Scope sc, Expression e)
	{
		e2 = e2.modifiableLvalue(sc, e);
		return this;
	}
	
    override bool isBool(bool result)
	{
		return e2.isBool(result);
	}
	
    override bool checkSideEffect(int flag)
	{
		if (flag == 2)
			return e1.checkSideEffect(2) || e2.checkSideEffect(2);
		else
		{
			// Don't check e1 until we cast(void) the a,b code generation
			return e2.checkSideEffect(flag);
		}
	}
	
    override MATCH implicitConvTo(Type t)
	{
		return e2.implicitConvTo(t);
	}
	
    override Expression castTo(Scope sc, Type t)
	{
		Expression e2c = e2.castTo(sc, t);
		Expression e;

		if (e2c != e2)
		{
			e = new CommaExp(loc, e1, e2c);
			e.type = e2c.type;
		}
		else
		{	
			e = this;
			e.type = e2.type;
		}
		return e;
	}
	
    override Expression optimize(int result)
	{
		Expression e;

		//printf("CommaExp.optimize(result = %d) %s\n", result, toChars());
		// Comma needs special treatment, because it may
		// contain compiler-generated declarations. We can interpret them, but
		// otherwise we must NOT attempt to constant-fold them.
		// In particular, if the comma returns a temporary variable, it needs
		// to be an lvalue (this is particularly important for struct constructors)

		if (result & WANTinterpret)
		{   
			// Interpreting comma needs special treatment, because it may
			// contain compiler-generated declarations.
			e = interpret(null);
			return (e is EXP_CANT_INTERPRET) ? this : e;
		}
		// Don't constant fold if it is a compiler-generated temporary.
		if (e1.op == TOKdeclaration)
		   return this;

		e1 = e1.optimize(result & WANTinterpret);
		e2 = e2.optimize(result);
		if (!e1 || e1.op == TOKint64 || e1.op == TOKfloat64 || !e1.checkSideEffect(2))
		{
			e = e2;
			if (e)
				e.type = type;
		}
		else
			e = this;
		//printf("-CommaExp.optimize(result = %d) %s\n", result, e.toChars());
		return e;
	}
	
    override Expression interpret(InterState istate)
	{	
version (LOG) {
		printf("CommaExp.interpret() %.*s\n", toChars());
}
		// If the comma returns a temporary variable, it needs to be an lvalue
		// (this is particularly important for struct constructors)
		if (e1.op == TOKdeclaration && e2.op == TOKvar 
		   && (cast(DeclarationExp)e1).declaration == (cast(VarExp)e2).var)
		{
			VarExp ve = cast(VarExp)e2;
			VarDeclaration v = ve.var.isVarDeclaration();
			if (!v.init && !v.value)
				v.value = v.type.defaultInitLiteral(Loc(0));
			if (!v.value)
				v.value = v.init.toExpression();
			v.value = v.value.interpret(istate);	
			return e2;
		}

		Expression e = e1.interpret(istate);
		if (e !is EXP_CANT_INTERPRET)
			e = e2.interpret(istate);
		return e;
	}
	
    override elem* toElem(IRState* irs)
	{
		assert(e1 && e2);
		elem* eleft  = e1.toElem(irs);
		elem* eright = e2.toElem(irs);
		elem* e = el_combine(eleft, eright);
		if (e)
			el_setLoc(e, loc);
		return e;
	}
}
