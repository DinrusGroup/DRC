module dmd.ForeachRangeStatement;

import dmd.common;
import dmd.Statement;
import dmd.TOK;
import dmd.Token;
import dmd.Parameter;
import dmd.Expression;
import dmd.Statement;
import dmd.VarDeclaration;
import dmd.Scope;
import dmd.ExpInitializer;
import dmd.Identifier;
import dmd.Lexer;
import dmd.ArrayTypes;
import dmd.DeclarationStatement;
import dmd.CompoundDeclarationStatement;
import dmd.DeclarationExp;
import dmd.PostExp;
import dmd.VarExp;
import dmd.ForStatement;
import dmd.IntegerExp;
import dmd.AddAssignExp;
import dmd.CmpExp;
import dmd.IRState;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.AddExp;
import dmd.WANT;
import dmd.ScopeDsymbol;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.Loc;
import dmd.BE;

import dmd.DDMDExtensions;

version(DMDV2)
class ForeachRangeStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    TOK op;		// TOK.TOKforeach or TOK.TOKforeach_reverse
    Parameter arg;		// loop index variable
    Expression lwr;
    Expression upr;
    Statement body_;

    VarDeclaration key = null;

    this(Loc loc, TOK op, Parameter arg, Expression lwr, Expression upr, Statement body_)
	{
		register();
		super(loc);
		this.op = op;
		this.arg = arg;
		this.lwr = lwr;
		this.upr = upr;
		this.body_ = body_;
	}
	
    override Statement syntaxCopy()
	{
		ForeachRangeStatement s = new ForeachRangeStatement(loc, op,
			arg.syntaxCopy(),
			lwr.syntaxCopy(),
			upr.syntaxCopy(),
			body_ ? body_.syntaxCopy() : null);

		return s;
	}

    override Statement semantic(Scope sc)
	{
		//printf("ForeachRangeStatement.semantic() %p\n", this);
		ScopeDsymbol sym;
		Statement s = this;

		lwr = lwr.semantic(sc);
		lwr = resolveProperties(sc, lwr);
		lwr = lwr.optimize(WANTvalue);
		if (!lwr.type)
		{
			error("invalid range lower bound %s", lwr.toChars());
			return this;
		}

		upr = upr.semantic(sc);
		upr = resolveProperties(sc, upr);
		upr = upr.optimize(WANTvalue);
		if (!upr.type)
		{
			error("invalid range upper bound %s", upr.toChars());
			return this;
		}

		if (arg.type)
		{
			arg.type = arg.type.semantic(loc, sc);
			lwr = lwr.implicitCastTo(sc, arg.type);
			upr = upr.implicitCastTo(sc, arg.type);
		}
		else
		{
			/* Must infer types from lwr and upr
			 */
			scope AddExp ea = new AddExp(loc, lwr, upr);
			ea.typeCombine(sc);
			arg.type = ea.type.mutableOf();
			lwr = ea.e1;
			upr = ea.e2;
		}
	static if (true) {
		/* Convert to a for loop:
		 *	foreach (key; lwr .. upr) =>
		 *	for (auto key = lwr, auto tmp = upr; key < tmp; ++key)
		 *
		 *	foreach_reverse (key; lwr .. upr) =>
		 *	for (auto tmp = lwr, auto key = upr; key-- > tmp;)
		 */

		ExpInitializer ie = new ExpInitializer(loc, (op == TOKforeach) ? lwr : upr);
		key = new VarDeclaration(loc, arg.type, arg.ident, ie);

		Identifier id = Lexer.uniqueId("__limit");
		ie = new ExpInitializer(loc, (op == TOKforeach) ? upr : lwr);
		VarDeclaration tmp = new VarDeclaration(loc, arg.type, id, ie);

		auto cs = new Statements();
		// Keep order of evaluation as lwr, then upr
		if (op == TOKforeach)
		{
			cs.push(new DeclarationStatement(loc, new DeclarationExp(loc, key)));
			cs.push(new DeclarationStatement(loc, new DeclarationExp(loc, tmp)));
		}
		else
		{
			cs.push(new DeclarationStatement(loc, new DeclarationExp(loc, tmp)));
			cs.push(new DeclarationStatement(loc, new DeclarationExp(loc, key)));
		}
		Statement forinit = new CompoundDeclarationStatement(loc, cs);

		Expression cond;
		if (op == TOKforeach_reverse)
		{	// key-- > tmp
			cond = new PostExp(TOKminusminus, loc, new VarExp(loc, key));
			cond = new CmpExp(TOKgt, loc, cond, new VarExp(loc, tmp));
		}
		else
			// key < tmp
			cond = new CmpExp(TOKlt, loc, new VarExp(loc, key), new VarExp(loc, tmp));

		Expression increment = null;
		if (op == TOKforeach)
			// key += 1
			increment = new AddAssignExp(loc, new VarExp(loc, key), new IntegerExp(1));

		ForStatement fs = new ForStatement(loc, forinit, cond, increment, body_);
		s = fs.semantic(sc);
		return s;
	} else {
		if (!arg.type.isscalar())
			error("%s is not a scalar type", arg.type.toChars());

		sym = new ScopeDsymbol();
		sym.parent = sc.scopesym;
		sc = sc.push(sym);

		sc.noctor++;

		key = new VarDeclaration(loc, arg.type, arg.ident, null);
		DeclarationExp de = new DeclarationExp(loc, key);
		de.semantic(sc);

		if (key.storage_class)
			error("foreach range: key cannot have storage class");

		sc.sbreak = this;
		sc.scontinue = this;
		body_ = body_.semantic(sc);

		sc.noctor--;
		sc.pop();
		return s;
	}
	}
	
	override bool hasBreak()
	{
		return true;
	}
	
	override bool hasContinue()
	{
		return true;
	}
	
	override bool usesEH()
	{
		assert(false); // from dmd
		return body_.usesEH();
	}

	override BE blockExit()
	{
		assert(false); // from dmd
		BE result = BE.BEfallthru;

		if (lwr && lwr.canThrow())
			result |= BE.BEthrow;
		else if (upr && upr.canThrow())
			result |= BE.BEthrow;

		if (body_)
		{
			result |= body_.blockExit() & ~(BE.BEbreak | BE.BEcontinue);
		}
		return result;
	}

	override bool comeFrom()
	{
		assert(false); // from dmd
		if (body_)
			return body_.comeFrom();
		return false;
	}
	
	override Expression interpret(InterState istate)
	{
		assert(false);
	}
	
	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring(Token.toChars(op));
		buf.writestring(" (");

		if (arg.type)
			arg.type.toCBuffer(buf, arg.ident, hgs);
		else
			buf.writestring(arg.ident.toChars());

		buf.writestring("; ");
		lwr.toCBuffer(buf, hgs);
		buf.writestring(" .. ");
		upr.toCBuffer(buf, hgs);
		buf.writebyte(')');
		buf.writenl();
		buf.writebyte('{');
		buf.writenl();
		if (body_)
			body_.toCBuffer(buf, hgs);
		buf.writebyte('}');
		buf.writenl();
	}
	
	override Statement inlineScan(InlineScanState* iss)
	{
		 lwr = lwr.inlineScan(iss);
			upr = upr.inlineScan(iss);
			if (body_)
				body_ = body_.inlineScan(iss);
			return this;
	}
	
    override void toIR(IRState* irs)
	{
		assert(false);
	}
}
