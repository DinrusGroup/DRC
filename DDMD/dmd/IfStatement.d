module dmd.IfStatement;

import dmd.common;
import dmd.Statement;
import dmd.Parameter;
import dmd.Loc;
import dmd.Expression;
import dmd.VarDeclaration;
import dmd.Scope;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.GlobalExpressions;
import dmd.HdrGenState;
import dmd.InlineCostState;
import dmd.InlineDoState;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.BE;
import dmd.WANT;
import dmd.ScopeDsymbol;
import dmd.Type;
import dmd.CondExp;
import dmd.AndAndExp;
import dmd.OrOrExp;
import dmd.AssignExp;
import dmd.VarExp;

import dmd.backend.elem;
import dmd.backend.Util;
import dmd.backend.block;
import dmd.backend.Blockx;
import dmd.backend.BC;

import dmd.DDMDExtensions;

class IfStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Parameter arg;
    Expression condition;
    Statement ifbody;
    Statement elsebody;

    VarDeclaration match;	// for MatchExpression results

    this(Loc loc, Parameter arg, Expression condition, Statement ifbody, Statement elsebody)
	{
		register();
		super(loc);
		this.arg = arg;
		this.condition = condition;
		this.ifbody = ifbody;
		this.elsebody = elsebody;
	}
		
    override Statement syntaxCopy()
	{
		Statement i = null;
		if (ifbody)
			i = ifbody.syntaxCopy();

		Statement e = null;
		if (elsebody)
			e = elsebody.syntaxCopy();

		Parameter a = arg ? arg.syntaxCopy() : null;
		IfStatement s = new IfStatement(loc, a, condition.syntaxCopy(), i, e);
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		condition = condition.semantic(sc);
		condition = resolveProperties(sc, condition);
		condition = condition.checkToBoolean();

		// If we can short-circuit evaluate the if statement, don't do the
		// semantic analysis of the skipped code.
		// This feature allows a limited form of conditional compilation.
		condition = condition.optimize(WANT.WANTflags);

		// Evaluate at runtime
		uint cs0 = sc.callSuper;
		uint cs1;

		Scope scd;
		if (arg)
		{	
			/* Declare arg, which we will set to be the
			 * result of condition.
			 */
			ScopeDsymbol sym = new ScopeDsymbol();
			sym.parent = sc.scopesym;
			scd = sc.push(sym);

			Type t = arg.type ? arg.type : condition.type;
			match = new VarDeclaration(loc, t, arg.ident, null);
			match.noauto = true;
			match.semantic(scd);
			if (!scd.insert(match))
				assert(0);

			match.parent = sc.func;

			/* Generate:
			 *  (arg = condition)
			 */
			VarExp v = new VarExp(Loc(0), match);
			condition = new AssignExp(loc, v, condition);
			condition = condition.semantic(scd);
		}
		else
			scd = sc.push();

		ifbody = ifbody.semantic(scd);
		scd.pop();

		cs1 = sc.callSuper;
		sc.callSuper = cs0;
		if (elsebody)
			elsebody = elsebody.semanticScope(sc, null, null);

		sc.mergeCallSuper(loc, cs1);

		return this;
	}
	
    override Expression interpret(InterState istate)
	{
version(LOG)
		writef("IfStatement::interpret(%s)\n", condition.toChars());

		if (istate.start is this)
			istate.start = null;
		if (istate.start)
		{
			Expression e = null;
			if (ifbody)
				e = ifbody.interpret(istate);
			if (istate.start && elsebody)
				e = elsebody.interpret(istate);
			return e;
		}

		Expression e = condition.interpret(istate);
		assert(e);
		//if (e is EXP_CANT_INTERPRET) writef("cannot interpret\n");
		if (e !is EXP_CANT_INTERPRET)
		{
			if (e.isBool(true))
				e = ifbody ? ifbody.interpret(istate) : null;
			else if (e.isBool(false))
				e = elsebody ? elsebody.interpret(istate) : null;
			else
			{
				e = EXP_CANT_INTERPRET;
			}
		}
		return e;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("if (");
		if (arg)
		{
			if (arg.type)
				arg.type.toCBuffer(buf, arg.ident, hgs);
			else
			{   
				buf.writestring("auto ");
				buf.writestring(arg.ident.toChars());
			}
			buf.writestring(" = ");
		}
		condition.toCBuffer(buf, hgs);
		buf.writebyte(')');
		buf.writenl();
		ifbody.toCBuffer(buf, hgs);
		if (elsebody)
		{   
			buf.writestring("else");
			buf.writenl();
			elsebody.toCBuffer(buf, hgs);
		}
	}
	
    override bool usesEH()
	{
		assert(false);
	}
	
    override BE blockExit()
	{
		//printf("IfStatement::blockExit(%p)\n", this);

		BE result = BE.BEnone;
		if (condition.canThrow())
			result |= BE.BEthrow;
		if (condition.isBool(true))
		{
			if (ifbody)
				result |= ifbody.blockExit();
			else
				result |= BE.BEfallthru;
		}
		else if (condition.isBool(false))
		{
			if (elsebody)
				result |= elsebody.blockExit();
			else
				result |= BE.BEfallthru;
		}
		else
		{
			if (ifbody)
				result |= ifbody.blockExit();
			else
				result |= BE.BEfallthru;

			if (elsebody)
				result |= elsebody.blockExit();
			else
				result |= BE.BEfallthru;
		}

		//printf("IfStatement::blockExit(%p) = x%x\n", this, result);
		return result;
	}
	
    override IfStatement isIfStatement() { return this; }

    override int inlineCost(InlineCostState* ics)
	{
		int cost;

		/* Can't declare variables inside ?: expressions, so
		 * we cannot inline if a variable is declared.
		 */
		if (arg)
			return COST_MAX;

		cost = condition.inlineCost(ics);

		/* Specifically allow:
		 *	if (condition)
		 *	    return exp1;
		 *	else
		 *	    return exp2;
		 * Otherwise, we can't handle return statements nested in if's.
		 */

		if (elsebody && ifbody &&
			ifbody.isReturnStatement() &&
			elsebody.isReturnStatement())
		{
			cost += ifbody.inlineCost(ics);
			cost += elsebody.inlineCost(ics);
			//printf("cost = %d\n", cost);
		}
		else
		{
			ics.nested += 1;
			if (ifbody)
				cost += ifbody.inlineCost(ics);
			if (elsebody)
				cost += elsebody.inlineCost(ics);
			ics.nested -= 1;
		}
		return cost;
	}
	
    override Expression doInline(InlineDoState ids)
	{
		Expression econd;
		Expression e1;
		Expression e2;
		Expression e;

		assert(!arg);
		econd = condition.doInline(ids);
		assert(econd);
		if (ifbody)
			e1 = ifbody.doInline(ids);
		else
			e1 = null;
		if (elsebody)
			e2 = elsebody.doInline(ids);
		else
			e2 = null;
		if (e1 && e2)
		{
			e = new CondExp(econd.loc, econd, e1, e2);
			e.type = e1.type;
		}
		else if (e1)
		{
			e = new AndAndExp(econd.loc, econd, e1);
			e.type = Type.tvoid;
		}
		else if (e2)
		{
			e = new OrOrExp(econd.loc, econd, e2);
			e.type = Type.tvoid;
		}
		else
		{
			e = econd;
		}
		return e;
	}
	
    override Statement inlineScan(InlineScanState* iss)
	{
		condition = condition.inlineScan(iss);
		if (ifbody)
			ifbody = ifbody.inlineScan(iss);
		if (elsebody)
			elsebody = elsebody.inlineScan(iss);
		return this;
	}

    override void toIR(IRState* irs)
	{
		elem* e;
		Blockx* blx = irs.blx;

		//printf("IfStatement::toIR('%s')\n", condition.toChars());

		IRState mystate = IRState(irs, this);

		// bexit is the block that gets control after this IfStatement is done
		block* bexit = mystate.breakBlock ? mystate.breakBlock : block_calloc();

		incUsage(irs, loc);
static if (false) {
		if (match)
		{	
			/* Generate:
			 *  if (match = RTLSYM_IFMATCH(string, pattern)) ...
			 */
			assert(condition.op == TOK.TOKmatch);
			e = matchexp_toelem(cast(MatchExp)condition, &mystate, RTLSYM.RTLSYM_IFMATCH);
			Symbol *s = match.toSymbol();
			symbol_add(s);
			e = el_bin(OPeq, TYnptr, el_var(s), e);
		}
		else
		{
			e = condition.toElem(&mystate);
		}
} else {
			e = condition.toElem(&mystate);
}
		block_appendexp(blx.curblock, e);
		block* bcond = blx.curblock;
		block_next(blx, BC.BCiftrue, null);

		list_append(&bcond.Bsucc, blx.curblock);
		if (ifbody)
			ifbody.toIR(&mystate);

		list_append(&blx.curblock.Bsucc, bexit);

		if (elsebody)
		{
			block_next(blx, BC.BCgoto, null);
			list_append(&bcond.Bsucc, blx.curblock);
			elsebody.toIR(&mystate);
			list_append(&blx.curblock.Bsucc, bexit);
		}
		else
			list_append(&bcond.Bsucc, bexit);

		block_next(blx, BC.BCgoto, bexit);
	}
}
