module dmd.VarExp;

import dmd.common;
import dmd.Expression;
import dmd.Declaration;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.InlineCostState;
import dmd.FuncLiteralDeclaration;
import dmd.VarDeclaration;
import dmd.Dsymbol;
import dmd.FuncDeclaration;
import dmd.InlineDoState;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.TY;
import dmd.STC;
import dmd.SymbolDeclaration;
import dmd.SymbolExp;
import dmd.Type;
import dmd.interpret.Util;
import dmd.backend.Util;
import dmd.backend.dt_t;
import dmd.expression.Util;

import dmd.DDMDExtensions;

//! Variable
class VarExp : SymbolExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Declaration var, bool hasOverloads = false)
	{
		register();
		super(loc, TOK.TOKvar, VarExp.sizeof, var, hasOverloads);
		
		//printf("VarExp(this = %p, '%s', loc = %s)\n", this, var.toChars(), loc.toChars());
		//if (strcmp(var.ident.toChars(), "func") == 0) halt();
		this.type = var.type;
	}

	override bool equals(Object o)
	{
	   VarExp ne;

		if ( this == o ||
			((cast(Expression)o).op == TOKvar &&
			((ne = cast(VarExp)o), type.toHeadMutable().equals(ne.type.toHeadMutable())) &&
			 var == ne.var))
			return true;
		return false;
	}

	override Expression semantic(Scope sc)
	{
		FuncLiteralDeclaration fd;

	version (LOGSEMANTIC) {
		printf("VarExp.semantic(%s)\n", toChars());
	}
		if (!type)
		{
			type = var.type;
static if (false) {
			if (var.storage_class & STC.STClazy)
			{
				TypeFunction tf = new TypeFunction(null, type, 0, LINK.LINKd);
				type = new TypeDelegate(tf);
				type = type.semantic(loc, sc);
			}
}
		}

		/* Fix for 1161 doesn't work because it causes protection
		 * problems when instantiating imported templates passing private
		 * variables as alias template parameters.
		 */
		//accessCheck(loc, sc, null, var);

		VarDeclaration v = var.isVarDeclaration();
		if (v)
		{
static if (false) {
			if ((v.isConst() || v.isImmutable()) && type.toBasetype().ty != TY.Tsarray && v.init)
			{
				ExpInitializer ei = v.init.isExpInitializer();
				if (ei)
				{
					//ei.exp.implicitCastTo(sc, type).print();
					return ei.exp.implicitCastTo(sc, type);
				}
			}
}
			v.checkNestedReference(sc, loc);
version (DMDV2) {
	static if (true) {
			if (sc.func && !sc.intypeof)
			{
				/* Given:
				 * void f()
				 * { int fx;
				 *   pure void g()
				 *   {  int gx;
				 *      void h()
				 *      {  int hx;
				 *         void i() { }
				 *      }
				 *   }
				 * }
				 * i() can modify hx and gx but not fx
				 */
				
				/* Determine if sc.func is pure or if any function that
				 * encloses it is also pure.
				 */
				bool hasPureParent = false;
				for (FuncDeclaration outerfunc = sc.func; outerfunc;)
				{
					if (outerfunc.isPure())
					{
						hasPureParent = true;
						break;
					}
					Dsymbol parent = outerfunc.toParent2();
					if (!parent)
						break;
					outerfunc = parent.isFuncDeclaration();
				}

				/* If ANY of its enclosing functions are pure,
				 * it cannot do anything impure.
				 * If it is pure, it cannot access any mutable variables other
				 * than those inside itself
				 */
				if (hasPureParent && v.isDataseg() && !v.isImmutable())
				{
					error("pure function '%s' cannot access mutable static data '%s'",
						sc.func.toChars(), v.toChars());
				}
				else if (sc.func.isPure() && sc.parent != v.parent && !v.isImmutable() && !(v.storage_class & STC.STCmanifest))
				{
					error("pure nested function '%s' cannot access mutable data '%s'", sc.func.toChars(), v.toChars());
					if (v.isEnumDeclaration())
						error("enum");
				}

				/* Do not allow safe functions to access __gshared data
				 */
				if (sc.func.isSafe() && v.storage_class & STCgshared)
				error("safe function '%s' cannot access __gshared data '%s'",
					sc.func.toChars(), v.toChars());
			}
	} else {
			if (sc.func && sc.func.isPure() && !sc.intypeof)
			{
				if (v.isDataseg() && !v.isImmutable())
					error("pure function '%s' cannot access mutable static data '%s'", sc.func.toChars(), v.toChars());
			}
	}
}
		}
		else
		{
static if (false) {
			if ((fd = var.isFuncLiteralDeclaration()) !is null)
			{	
				Expression e = new FuncExp(loc, fd);
				e.type = type;
				return e;
			}
}
		}

		return this;
	}

	override Expression optimize(int result)
	{
		return fromConstInitializer(result, this);
	}

	override Expression interpret(InterState istate)
	{
version (LOG) {
		printf("VarExp.interpret() %.*s\n", toChars());
}
		return getVarExp(loc, istate, var);
	}

	override void dump(int indent)
	{
		assert(false);
	}

	override string toChars()
	{
		return var.toChars();
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring(var.toChars());
	}

	override void checkEscape()
	{
		VarDeclaration v = var.isVarDeclaration();
		if (v)
		{	
			Type tb = v.type.toBasetype();
			// if reference type
			if (tb.ty == TY.Tarray || tb.ty == TY.Tsarray || tb.ty == TY.Tclass)
			{
				if ((v.isAuto() || v.isScope()) && !v.noauto)
					error("escaping reference to scope local %s", v.toChars());
				else if (v.storage_class & STC.STCvariadic)
					error("escaping reference to variadic parameter %s", v.toChars());
			}
		}
	}
    
    override void checkEscapeRef()
    {
        VarDeclaration v = var.isVarDeclaration();
        if (v)
        {
	    if (!v.isDataseg() && !(v.storage_class & (STCref | STCout)))
	        error("escaping reference to local variable %s", v.toChars());
        }
    }

version (DMDV2)
{
	override bool isLvalue()
	{
		if (var.storage_class & STClazy)
			return false;
		return true;
	}
}
	override Expression toLvalue(Scope sc, Expression e)
	{
static if (false) {
		tym = tybasic(e1.ET.Tty);
		if (!(tyscalar(tym) ||
		  tym == TYM.TYstruct ||
		  tym == TYM.TYarray && e.Eoper == TOK.TOKaddr))
		{
			synerr(EM_lvalue);	// lvalue expected
		}
}
		if (var.storage_class & STC.STClazy)
			error("lazy variables cannot be lvalues");

		return this;
	}

	override Expression modifiableLvalue(Scope sc, Expression e)
	{
		//printf("VarExp::modifiableLvalue('%s')\n", var.toChars());
		//if (type && type.toBasetype().ty == TY.Tsarray)
		//	error("cannot change reference to static array '%s'", var.toChars());

		var.checkModify(loc, sc, type);

		// See if this expression is a modifiable lvalue (i.e. not const)
		return toLvalue(sc, e);
	}

	override dt_t** toDt(dt_t** pdt)
	{
		// writef("VarExp::toDt() %d\n", op);
		for (; *pdt; pdt = &((*pdt).DTnext))
		{}

		VarDeclaration v = var.isVarDeclaration();
		if (v && (v.isConst() || v.isImmutable()) &&
			type.toBasetype().ty != Tsarray && v.init)
		{
			if (v.inuse)
			{
				error("recursive reference %s", toChars());
				return pdt;
			}
			v.inuse++;
			*pdt = v.init.toDt();
			v.inuse--;
			return pdt;
		}
		SymbolDeclaration sd = var.isSymbolDeclaration();
		if (sd && sd.dsym)
		{
			sd.dsym.toDt(pdt);
			return pdt;
		}
		debug writef("VarExp::toDt(), kind = %s\n", var.kind());

		error("non-constant expression %s", toChars());
		pdt = dtnzeros(pdt, 1);
		return pdt;
	}

	version(DMDV1)
	override elem* toElem(IRState* irs)
	{
		assert(false);
	}

	override void scanForNestedRef(Scope sc)
	{
		//printf("VarExp.scanForNestedRef(%s)\n", toChars());
		VarDeclaration v = var.isVarDeclaration();
		if (v)
			v.checkNestedReference(sc, Loc(0));
	}

	override int inlineCost(InlineCostState* ics)
	{
		//printf("VarExp.inlineCost() %s\n", toChars());
		return 1;
	}

	override Expression doInline(InlineDoState ids)
	{
		int i;

		//printf("VarExp.doInline(%s)\n", toChars());
		for (i = 0; i < ids.from.dim; i++)
		{
			if (var == cast(Declaration)ids.from.data[i])
			{
				VarExp ve = cast(VarExp)copy();

				ve.var = cast(Declaration)ids.to.data[i];
				return ve;
			}
		}
		return this;
	}
}

