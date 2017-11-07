module dmd.DotVarExp;

import dmd.common;
import dmd.Expression;
import dmd.Declaration;
import dmd.backend.elem;
import dmd.UnaExp;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.TupleDeclaration;
import dmd.ArrayTypes;
import dmd.DsymbolExp;
import dmd.TupleExp;
import dmd.Global;
import dmd.Type;
import dmd.Dsymbol;
import dmd.AggregateDeclaration;
import dmd.VarDeclaration;
import dmd.WANT;
import dmd.TY;
import dmd.ErrorExp;
import dmd.FuncDeclaration;
import dmd.STC;
import dmd.GlobalExpressions;
import dmd.VarExp;
import dmd.StructLiteralExp;
import dmd.PREC;

import dmd.expression.Util;
import dmd.codegen.Util;
import dmd.backend.Util;
import dmd.backend.mTY;
import dmd.backend.OPER;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

class DotVarExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	Declaration var;

	bool hasOverloads;

	this(Loc loc, Expression e, Declaration var, bool hasOverloads = false)
	{
		super(loc, TOK.TOKdotvar, DotVarExp.sizeof, e);
		//printf("DotVarExp()\n");
		this.var = var;
		this.hasOverloads = hasOverloads;
	}

	override Expression semantic(Scope sc)
	{
version (LOGSEMANTIC) {
		printf("DotVarExp.semantic('%s')\n", toChars());
}
		if (!type)
		{
			var = var.toAlias().isDeclaration();

			TupleDeclaration tup = var.isTupleDeclaration();
			if (tup)
			{   
				/* Replace:
				 *	e1.tuple(a, b, c)
				 * with:
				 *	tuple(e1.a, e1.b, e1.c)
				 */
				auto exps = new Expressions;

				exps.reserve(tup.objects.dim);
				foreach (o; tup.objects)
				{   
					if (auto e = cast(Expression)o)
					{
						if (e.op != TOK.TOKdsymbol)
							error("%s is not a member", e.toChars());
						else
						{	
							auto ve = cast(DsymbolExp)e;
							e = new DotVarExp(loc, e1, ve.s.isDeclaration());
							exps.push(e);
						}
					} else {
						error("%s is not an expression", o.toString());
					}
				}
				Expression e = new TupleExp(loc, exps);
				e = e.semantic(sc);
				return e;
			}

			e1 = e1.semantic(sc);
			type = var.type;
			if (!type && global.errors)
			{   
				// var is goofed up, just return 0
				return new ErrorExp();
			}
			assert(type);

			if (!var.isFuncDeclaration())	// for functions, do checks after overload resolution
			{
				Type t1 = e1.type;
				if (t1.ty == TY.Tpointer)
					t1 = t1.nextOf();

				type = type.addMod(t1.mod);

				Dsymbol vparent = var.toParent();
				AggregateDeclaration ad = vparent ? vparent.isAggregateDeclaration() : null;
				e1 = getRightThis(loc, sc, ad, e1, var);
				if (!sc.noaccesscheck)
					accessCheck(loc, sc, e1, var);

				VarDeclaration v = var.isVarDeclaration();
				Expression e = expandVar(WANT.WANTvalue, v);
				if (e)
					return e;
			}
		}
		//printf("-DotVarExp.semantic('%s')\n", toChars());
		return this;
	}

	override bool isLvalue()
	{
		return true;
	}

	override Expression toLvalue(Scope sc, Expression e)
	{
		//printf("DotVarExp::toLvalue(%s)\n", toChars());
		return this;
	}

	override Expression modifiableLvalue(Scope sc, Expression e)
	{
static if (false) {
		printf("DotVarExp::modifiableLvalue(%s)\n", toChars());
		printf("e1.type = %s\n", e1.type.toChars());
		printf("var.type = %s\n", var.type.toChars());
}

		if (var.isCtorinit())
		{	
			// It's only modifiable if inside the right constructor
			Dsymbol s = sc.func;
			while (true)
			{
				FuncDeclaration fd = null;
				if (s)
					fd = s.isFuncDeclaration();
				if (fd && ((fd.isCtorDeclaration() && var.storage_class & STC.STCfield) ||
					(fd.isStaticCtorDeclaration() && !(var.storage_class & STC.STCfield))) &&
					fd.toParent() == var.toParent() && e1.op == TOK.TOKthis)
				{
					VarDeclaration v = var.isVarDeclaration();
					assert(v);
					v.ctorinit = 1;
					//printf("setting ctorinit\n");
				}
				else
				{
					if (s)
					{   
						s = s.toParent2();
						continue;
					}
					else
					{
						string p = var.isStatic() ? "static " : "";
						error("can only initialize %sconst member %s inside %sconstructor", p, var.toChars(), p);
					}
				}
				break;
			}
		}
		else
		{
version (DMDV2) {
			Type t1 = e1.type.toBasetype();

			if (!t1.isMutable() || (t1.ty == TY.Tpointer && !t1.nextOf().isMutable()) ||
				!var.type.isMutable() || !var.type.isAssignable() || var.storage_class & STC.STCmanifest)
			{
				error("cannot modify const/immutable/inout expression %s", toChars());
			}
}
		}

		return this;
	}

	override Expression optimize(int result)
	{
		//writef("DotVarExp.optimize(result = x%x) %s\n", result, toChars());
		e1 = e1.optimize(result);

		Expression e = e1;

		if (e1.op == TOK.TOKvar)
		{	
			VarExp ve = cast(VarExp)e1;
			VarDeclaration v = ve.var.isVarDeclaration();
			e = expandVar(result, v);
		}
		if (e && e.op == TOK.TOKstructliteral)
		{
			StructLiteralExp sle = cast(StructLiteralExp) e;
			VarDeclaration vf = var.isVarDeclaration();
			if (vf)
			{
				e = sle.getField(type, vf.offset);
				if (e && e !is EXP_CANT_INTERPRET)
					return e;
			}
		}

		return this;
	}

	override Expression interpret(InterState istate)
	{
		Expression e = EXP_CANT_INTERPRET;

version (LOG) {
		printf("DotVarExp.interpret() %.*s\n", toChars());
}

		Expression ex = e1.interpret(istate);
		if (ex !is EXP_CANT_INTERPRET)
		{
			if (ex.op == TOKstructliteral)
			{   
				StructLiteralExp se = cast(StructLiteralExp)ex;
				VarDeclaration v = var.isVarDeclaration();
				if (v)
				{	
					e = se.getField(type, v.offset);
					if (!e)
		            {
		                error("couldn't find field %s in %s", v.toChars(), type.toChars());
						e = EXP_CANT_INTERPRET;
                    }
					return e;
				}
			}
            else
            {
				error("%s.%s is not yet implemented at compile time", ex.toChars(), var.toChars());
			}
		}

version (LOG) {
		if (e is EXP_CANT_INTERPRET)
			printf("DotVarExp.interpret() %.*s = EXP_CANT_INTERPRET\n", toChars());
}
		return e;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC.PREC_primary);
		buf.writeByte('.');
		buf.writestring(var.toChars());
	}

	override void dump(int indent)
	{
		assert(false);
	}

	override elem* toElem(IRState* irs)
	{
		// *(&e + offset)
		//printf("DotVarExp.toElem('%s')\n", toChars());

		VarDeclaration v = var.isVarDeclaration();
		if (!v)
		{
			error("%s is not a field, but a %s", var.toChars(), var.kind());
		}

		elem* e = e1.toElem(irs);
		Type tb1 = e1.type.toBasetype();

		if (tb1.ty != TY.Tclass && tb1.ty != TY.Tpointer)
			//e = el_una(OPaddr, TYnptr, e);
			e = addressElem(e, tb1);

		e = el_bin(OPER.OPadd, TYM.TYnptr, e, el_long(TYM.TYint, v ? v.offset : 0));
		e = el_una(OPER.OPind, type.totym(), e);
		if (tybasic(e.Ety) == TYM.TYstruct)
		{
			e.Enumbytes = cast(uint)type.size();
		}
		el_setLoc(e,loc);

		return e;
	}
}

