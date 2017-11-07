module dmd.MinAssignExp;

import dmd.common;
import dmd.expression.Min;
import dmd.BinExp;
import dmd.Loc;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.ArrayTypes;
import dmd.Identifier;
import dmd.IRState;
import dmd.TY;
import dmd.TOK;
import dmd.Id;
import dmd.ArrayLengthExp;

import dmd.backend.elem;
import dmd.backend.Util;
import dmd.backend.OPER;

import dmd.DDMDExtensions;

class MinAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKminass, MinAssignExp.sizeof, e1, e2);
	}
	
    override Expression semantic(Scope sc)
	{
		Expression e;

		if (type)
			return this;

		BinExp.semantic(sc);
		e2 = resolveProperties(sc, e2);

		e = op_overload(sc);
		if (e)
			return e;

        if (e1.op == TOKarraylength)
        {
	        e = ArrayLengthExp.rewriteOpAssign(this);
	        e = e.semantic(sc);
	        return e;
        }

		if (e1.op == TOKslice)
		{	// T[] -= ...
			typeCombine(sc);
			type = e1.type;
			return arrayOp(sc);
		}

		e1 = e1.modifiableLvalue(sc, e1);
		e1.checkScalar();
		e1.checkNoBool();
		if (e1.type.ty == Tpointer && e2.type.isintegral())
			e = scaleFactor(sc);
		else
		{
			e1 = e1.checkArithmetic();
			e2 = e2.checkArithmetic();
			checkComplexAddAssign();
			type = e1.type;
			typeCombine(sc);
			if (type.isreal() || type.isimaginary())
			{
				assert(e2.type.isfloating());
				e2 = e2.castTo(sc, e1.type);
			}
			e = this;
		}
		return e;
	}
	
    override Expression interpret(InterState istate)
	{
    	return interpretAssignCommon(istate, &Min);
	}
	
    override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		AssignExp_buildArrayIdent(buf, arguments, "Min");
	}
	
    override Expression buildArrayLoop(Parameters fparams)
	{
		return AssignExp_buildArrayLoop!(typeof(this))(fparams);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.subass;
	}

    override elem* toElem(IRState* irs)
	{
		return toElemBin(irs,OPminass);
	}
}
