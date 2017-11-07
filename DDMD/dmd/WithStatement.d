module dmd.WithStatement;

import dmd.common;
import dmd.Statement;
import dmd.Expression;
import dmd.VarDeclaration;
import dmd.Loc;
import dmd.OutBuffer;
import dmd.ScopeDsymbol;
import dmd.TypeExp;
import dmd.TOK;
import dmd.Initializer;
import dmd.ExpInitializer;
import dmd.Id;
import dmd.ScopeExp;
import dmd.WithScopeSymbol;
import dmd.TY;
import dmd.Type;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.Scope;
import dmd.BE;

import dmd.backend.Symbol;
import dmd.backend.block;
import dmd.backend.Blockx;
import dmd.backend.elem;
import dmd.backend.Util;
import dmd.backend.OPER;

import dmd.DDMDExtensions;

class WithStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;
    Statement body_;
    VarDeclaration wthis;

    this(Loc loc, Expression exp, Statement body_)
	{
		register();
		super(loc);
		this.exp = exp;
		this.body_ = body_;
		wthis = null;
	}
	
    override Statement syntaxCopy()
	{
		WithStatement s = new WithStatement(loc, exp.syntaxCopy(), body_ ? body_.syntaxCopy() : null);
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		ScopeDsymbol sym;
		Initializer init;

		//printf("WithStatement.semantic()\n");
		exp = exp.semantic(sc);
		exp = resolveProperties(sc, exp);
		if (exp.op == TOKimport)
		{	
			ScopeExp es = cast(ScopeExp)exp;

			sym = es.sds;
		}
		else if (exp.op == TOKtype)
		{	
			TypeExp es = cast(TypeExp)exp;

			sym = es.type.toDsymbol(sc).isScopeDsymbol();
			if (!sym)
			{   
				error("%s has no members", es.toChars());
				body_ = body_.semantic(sc);
				return this;
			}
		}
		else
		{	
			Type t = exp.type;

			assert(t);
			t = t.toBasetype();
			if (t.isClassHandle())
			{
				init = new ExpInitializer(loc, exp);
				wthis = new VarDeclaration(loc, exp.type, Id.withSym, init);
				wthis.semantic(sc);

				sym = new WithScopeSymbol(this);
				sym.parent = sc.scopesym;
			}
			else if (t.ty == Tstruct)
			{
				Expression e = exp.addressOf(sc);
				init = new ExpInitializer(loc, e);
				wthis = new VarDeclaration(loc, e.type, Id.withSym, init);
				wthis.semantic(sc);
				sym = new WithScopeSymbol(this);
				sym.parent = sc.scopesym;
			}
			else
			{   
				error("with expressions must be class objects, not '%s'", exp.type.toChars());
				return null;
			}
		}
		sc = sc.push(sym);

		if (body_)
			body_ = body_.semantic(sc);

		sc.pop();

		return this;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}
	
    override bool usesEH()
	{
		assert(false);
	}
	
    override BE blockExit()
	{
		BE result = BEnone;
		if (exp.canThrow())
			result = BEthrow;
		if (body_)
			result |= body_.blockExit();
		else
			result |= BEfallthru;
		return result;
	}

    override Statement inlineScan(InlineScanState* iss)
	{
		assert(false);
	}

    override void toIR(IRState* irs)
	{
		Symbol* sp;
		elem* e;
		elem* ei;
		ExpInitializer ie;
		Blockx* blx = irs.blx;

		//printf("WithStatement.toIR()\n");
		if (exp.op == TOKimport || exp.op == TOKtype)
		{
		}
		else
		{
			// Declare with handle
			sp = wthis.toSymbol();
			symbol_add(sp);

			// Perform initialization of with handle
			ie = wthis.init.isExpInitializer();
			assert(ie);
			ei = ie.exp.toElem(irs);
			e = el_var(sp);
			e = el_bin(OPeq,e.Ety, e, ei);
			elem_setLoc(e, loc);
			incUsage(irs, loc);
			block_appendexp(blx.curblock,e);
		}
		// Execute with block
		if (body_)
			body_.toIR(irs);
	}
}
