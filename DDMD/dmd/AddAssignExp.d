module dmd.AddAssignExp;

import dmd.common;
import dmd.expression.Add;
import dmd.BinExp;
import dmd.Loc;
import dmd.Expression;
import dmd.Scope;
import dmd.InterState;
import dmd.Parameter;
import dmd.STC;
import dmd.OutBuffer;
import dmd.ArrayTypes;
import dmd.Identifier;
import dmd.IRState;
import dmd.TOK;
import dmd.Type;
import dmd.TY;
import dmd.AddExp;
import dmd.CastExp;
import dmd.AssignExp;
import dmd.Global;
import dmd.Id;
import dmd.ArrayLengthExp;

import dmd.backend.OPER;
import dmd.backend.elem;

import dmd.DDMDExtensions;

class AddAssignExp : BinExp
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Expression e1, Expression e2)
	{
		register();
		super(loc, TOK.TOKaddass, AddAssignExp.sizeof, e1, e2);
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

		Type tb1 = e1.type.toBasetype();
		Type tb2 = e2.type.toBasetype();

        if (e1.op == TOKarraylength)
        {
	        e = ArrayLengthExp.rewriteOpAssign(this);
	        e = e.semantic(sc);
	        return e;
        }
        
		if (e1.op == TOK.TOKslice)
		{
			typeCombine(sc);
			type = e1.type;
			return arrayOp(sc);
		}
		else
		{
			e1 = e1.modifiableLvalue(sc, e1);
		}

		if ((tb1.ty == TY.Tarray || tb1.ty == TY.Tsarray) && (tb2.ty == TY.Tarray || tb2.ty == TY.Tsarray) && tb1.nextOf().equals(tb2.nextOf()))
		{
			type = e1.type;
			typeCombine(sc);
			e = this;
		}
		else
		{
			e1.checkScalar();
			e1.checkNoBool();
			if (tb1.ty == TY.Tpointer && tb2.isintegral())
				e = scaleFactor(sc);
			else if (tb1.ty == TY.Tbit || tb1.ty == TY.Tbool)
			{
static if (false) {
				// Need to rethink this
				if (e1.op != TOK.TOKvar)
				{   
					// Rewrite e1+=e2 to (v=&e1),*v=*v+e2
					VarDeclaration v;
					Expression ea;
					Expression ex;

					Identifier id = Lexer.uniqueId("__name");

					v = new VarDeclaration(loc, tb1.pointerTo(), id, null);
					v.semantic(sc);
					if (!sc.insert(v))
						assert(0);

					v.parent = sc.func;

					ea = new AddrExp(loc, e1);
					ea = new AssignExp(loc, new VarExp(loc, v), ea);

					ex = new VarExp(loc, v);
					ex = new PtrExp(loc, ex);
					e = new AddExp(loc, ex, e2);
					e = new CastExp(loc, e, e1.type);
					e = new AssignExp(loc, ex.syntaxCopy(), e);

					e = new CommaExp(loc, ea, e);
				}
				else
				{
					// Rewrite e1+=e2 to e1=e1+e2
					// BUG: doesn't account for side effects in e1
					// BUG: other assignment operators for bits aren't handled at all
					e = new AddExp(loc, e1, e2);
					e = new CastExp(loc, e, e1.type);
					e = new AssignExp(loc, e1.syntaxCopy(), e);
				}
} else {
				// Rewrite e1+=e2 to e1=e1+e2
				// BUG: doesn't account for side effects in e1
				// BUG: other assignment operators for bits aren't handled at all
				e = new AddExp(loc, e1, e2);
				e = new CastExp(loc, e, e1.type);
				e = new AssignExp(loc, e1.syntaxCopy(), e);
}
				e = e.semantic(sc);
			}
			else
			{
				type = e1.type;
				typeCombine(sc);
				e1.checkArithmetic();
				e2.checkArithmetic();
			    checkComplexAddAssign();

				if (type.isreal() || type.isimaginary())
				{
					assert(global.errors || e2.type.isfloating());
					e2 = e2.castTo(sc, e1.type);
				}
				e = this;
			}
		}
		return e;
	}
	
    override Expression interpret(InterState istate)
	{
    	return interpretAssignCommon(istate, &Add);
	}
	
    override void buildArrayIdent(OutBuffer buf, Expressions arguments)
	{
		AssignExp_buildArrayIdent(buf, arguments, "Add");
	}
	
    override Expression buildArrayLoop(Parameters fparams)
	{
		return AssignExp_buildArrayLoop!(typeof(this))(fparams);
	}

    override Identifier opId()    /* For operator overloading */
	{
		return Id.addass;
	}

    override elem* toElem(IRState* irs)
	{
		//printf("AddAssignExp::toElem() %s\n", toChars());
		elem *e;
		Type tb1 = e1.type.toBasetype();
		Type tb2 = e2.type.toBasetype();

		if ((tb1.ty == TY.Tarray || tb1.ty == TY.Tsarray) && (tb2.ty == TY.Tarray || tb2.ty == TY.Tsarray))
		{
			error("Array operations not implemented");
		}
		else
			e = toElemBin(irs, OPER.OPaddass);

		return e;
	}
}
