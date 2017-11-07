module dmd.SymOffExp;

import dmd.common;
import dmd.Expression;
import dmd.GlobalExpressions;
import dmd.Declaration;
import dmd.MATCH;
import dmd.Type;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.InlineDoState;
import dmd.HdrGenState;
import dmd.backend.dt_t;
import dmd.SymbolExp;
import dmd.VarDeclaration;
import dmd.DelegateExp;
import dmd.ThisExp;
import dmd.FuncDeclaration;
import dmd.IntegerExp;
import dmd.ErrorExp;
import dmd.TY;
import dmd.TOK;
import dmd.STC;

import dmd.backend.Symbol;
import dmd.backend.Util;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

class SymOffExp : SymbolExp
{
	mixin insertMemberExtension!(typeof(this));

	uint offset;

	this(Loc loc, Declaration var, uint offset, bool hasOverloads = false)
	{
		register();
		super(loc, TOK.TOKsymoff, SymOffExp.sizeof, var, hasOverloads);
		
		this.offset = offset;
		VarDeclaration v = var.isVarDeclaration();
		if (v && v.needThis())
			error("need 'this' for address of %s", v.toChars());
	}

	override Expression semantic(Scope sc)
	{
	version(LOGSEMANTIC) {
		printf("SymOffExp::semantic('%s')\n", toChars());
	}
		//var.semantic(sc);
		if (!type)
			type = var.type.pointerTo();
		VarDeclaration v = var.isVarDeclaration();
		if (v)
			v.checkNestedReference(sc, loc);
		return this;
	}
	
    override Expression interpret(InterState istate)
	{
version (LOG) {
		writef("SymOffExp::interpret() %s\n", toChars());
}
		if (var.isFuncDeclaration() && offset == 0)
		{
			return this;
		}
		error("Cannot interpret %s at compile time", toChars());
		return EXP_CANT_INTERPRET;

	}

	override void checkEscape()
	{
		VarDeclaration v = var.isVarDeclaration();
		if (v)
		{
			if (!v.isDataseg() && !(v.storage_class & (STC.STCref | STC.STCout)))
			{   /* BUG: This should be allowed:
				 *   void foo()
				 *   { int a;
				 *     int* bar() { return &a; }
				 *   }
				 */
				error("escaping reference to local %s", v.toChars());
			}
		}
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		if (offset)
			buf.printf("(& %s+%s)", var.toChars(), offset); ///
		else
			buf.printf("& %s", var.toChars());
	}

	override int isConst()
	{
		return 2;
	}

	override bool isBool(bool result)
	{
		return result;
	}

	override Expression doInline(InlineDoState ids)
	{
		int i;

		//printf("SymOffExp.doInline(%s)\n", toChars());
		for (i = 0; i < ids.from.dim; i++)
		{
			if (var is cast(Declaration)ids.from.data[i])
			{
				SymOffExp se = cast(SymOffExp)copy();

				se.var = cast(Declaration)ids.to.data[i];
				return se;
			}
		}
		return this;
	}

	override MATCH implicitConvTo(Type t)
	{
	static if (false) {
		printf("SymOffExp::implicitConvTo(this=%s, type=%s, t=%s)\n", toChars(), type.toChars(), t.toChars());
	}
		MATCH result = type.implicitConvTo(t);
		//printf("\tresult = %d\n", result);

		if (result == MATCHnomatch)
		{
			// Look for pointers to functions where the functions are overloaded.
			FuncDeclaration f;

			t = t.toBasetype();
			if (type.ty == Tpointer && type.nextOf().ty == Tfunction &&
				(t.ty == Tpointer || t.ty == Tdelegate) && t.nextOf().ty == Tfunction)
			{
				f = var.isFuncDeclaration();
				if (f)
				{	
					f = f.overloadExactMatch(t.nextOf());
					if (f)
					{   
						if ((t.ty == Tdelegate && (f.needThis() || f.isNested())) ||
							(t.ty == Tpointer && !(f.needThis() || f.isNested())))
						{
							result = MATCHexact;
						}
					}
				}
			}
		}
		//printf("\tresult = %d\n", result);
		return result;
	}

	override Expression castTo(Scope sc, Type t)
	{
	static if (false) {
		printf("SymOffExp::castTo(this=%s, type=%s, t=%s)\n", toChars(), type.toChars(), t.toChars());
	}
		if (type == t && !hasOverloads)
			return this;

		Expression e;
		Type tb = t.toBasetype();
		Type typeb = type.toBasetype();

		if (tb != typeb)
		{
			// Look for pointers to functions where the functions are overloaded.
			FuncDeclaration f;

			if (hasOverloads &&
				typeb.ty == Tpointer && typeb.nextOf().ty == Tfunction &&
				(tb.ty == Tpointer || tb.ty == Tdelegate) && tb.nextOf().ty == Tfunction)
			{
				f = var.isFuncDeclaration();
				if (f)
				{
					f = f.overloadExactMatch(tb.nextOf());
					if (f)
					{
						if (tb.ty == Tdelegate)
						{
							if (f.needThis() && hasThis(sc))
							{
								e = new DelegateExp(loc, new ThisExp(loc), f);
								e = e.semantic(sc);
							}
							else if (f.isNested())
							{
								e = new DelegateExp(loc, new IntegerExp(0), f);
								e = e.semantic(sc);
							}
							else if (f.needThis())
							{   
								error("no 'this' to create delegate for %s", f.toChars());
								e = new ErrorExp();
							}
							else
							{   
								error("cannot cast from function pointer to delegate");
								e = new ErrorExp();
							}
						}
						else
						{
							e = new SymOffExp(loc, f, 0);
							e.type = t;
						}
			version (DMDV2) {
						f.tookAddressOf++;
			}
						return e;
					}
				}
			}
			e = Expression.castTo(sc, t);
		}
		else
		{	
			e = copy();
			e.type = t;
			(cast(SymOffExp)e).hasOverloads = false;
		}
		return e;
	}

	override void scanForNestedRef(Scope sc)
	{
		//printf("SymOffExp.scanForNestedRef(%s)\n", toChars());
		VarDeclaration v = var.isVarDeclaration();
		if (v)
			v.checkNestedReference(sc, Loc(0));
	}

	override dt_t** toDt(dt_t** pdt)
	{
		//printf("SymOffExp.toDt('%s')\n", var.toChars());
		assert(var);
		if (!(var.isDataseg() || var.isCodeseg()) ||
			var.needThis() ||
			var.isThreadlocal()
		)
		{
			debug writef("SymOffExp.toDt()\n");
			error("non-constant expression %s", toChars());
			return pdt;
		}

		Symbol* s = var.toSymbol();
		return dtxoff(pdt, s, offset, TYnptr);
	}

static if (false)
{
	override elem* toElem(IRState* irs)
	{
		assert(false); // this function is #if 0'ed out in dmd
	}
}
}

