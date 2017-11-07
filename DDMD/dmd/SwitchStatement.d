module dmd.SwitchStatement;

import dmd.common;
import dmd.Statement;
import dmd.Expression;
import dmd.GlobalExpressions;
import dmd.DefaultStatement;
import dmd.TryFinallyStatement;
import dmd.Array;
import dmd.Loc;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.InterState;
import dmd.BE;
import dmd.TY;
import dmd.WANT;
import dmd.GotoCaseStatement;
import dmd.CaseStatement;
import dmd.ArrayTypes;
import dmd.CompoundStatement;
import dmd.Global;
import dmd.SwitchErrorStatement;
import dmd.Type;
import dmd.HaltExp;
import dmd.ExpStatement;
import dmd.BreakStatement;
import dmd.EnumDeclaration;
import dmd.TypeEnum;
import dmd.Dsymbol;
import dmd.EnumMember;
import dmd.TypeTypedef;
import dmd.TOK;
import dmd.StringExp;
import dmd.expression.Equal;

import dmd.backend.Util;
import dmd.backend.block;
import dmd.backend.Blockx;
import dmd.backend.elem;
import dmd.backend.OPER;
import dmd.backend.TYM;
import dmd.backend.BC;
import dmd.backend.dt_t;
import dmd.backend.Symbol;
import dmd.backend.SC;
import dmd.backend.FL;
import dmd.backend.RTLSYM;
import dmd.backend.targ_types;

version (MACHOBJ)
	import dmd.Module;

import core.memory;

import core.stdc.stdlib;

import dmd.DDMDExtensions;

class SwitchStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression condition;
    Statement body_;
    bool isFinal;

    DefaultStatement sdefault = null;
    TryFinallyStatement tf = null;
    Array gotoCases;		// array of unresolved GotoCaseStatement's
    Array cases;		// array of CaseStatement's
    int hasNoDefault = 0;	// !=0 if no default statement
    int hasVars = 0;		// !=0 if has variable case values

    this(Loc loc, Expression c, Statement b, bool isFinal)
	{
		register();
		super(loc);
		
		this.condition = c;
		this.body_ = b;
		this.isFinal = isFinal;
		
		gotoCases = new Array();
	}
	
    override Statement syntaxCopy()
	{
		SwitchStatement s = new SwitchStatement(loc,
			condition.syntaxCopy(), body_.syntaxCopy(), isFinal);
		return s;
	}
	
    override Statement semantic(Scope sc)
	{
		//printf("SwitchStatement.semantic(%p)\n", this);
		tf = sc.tf;
		assert(!cases);		// ensure semantic() is only run once
		condition = condition.semantic(sc);
		condition = resolveProperties(sc, condition);
		if (condition.type.isString())
		{
			// If it's not an array, cast it to one
			if (condition.type.ty != Tarray)
			{
				condition = condition.implicitCastTo(sc, condition.type.nextOf().arrayOf());
			}
			condition.type = condition.type.constOf();
		}
		else
		{	
			condition = condition.integralPromotions(sc);
			condition.checkIntegral();
		}
		condition = condition.optimize(WANTvalue);

		sc = sc.push();
		sc.sbreak = this;
		sc.sw = this;

		cases = new Array();
		sc.noctor++;	// BUG: should use Scope.mergeCallSuper() for each case instead
		body_ = body_.semantic(sc);
		sc.noctor--;

		// Resolve any goto case's with exp
		for (int i = 0; i < gotoCases.dim; i++)
		{
			GotoCaseStatement gcs = cast(GotoCaseStatement)gotoCases.data[i];

			if (!gcs.exp)
			{
				gcs.error("no case statement following goto case;");
				break;
			}

			for (Scope scx = sc; scx; scx = scx.enclosing)
			{
				if (!scx.sw)
					continue;
				for (int j = 0; j < scx.sw.cases.dim; j++)
				{
					CaseStatement cs = cast(CaseStatement)scx.sw.cases.data[j];

					if (cs.exp.equals(gcs.exp))
					{
						gcs.cs = cs;
						goto Lfoundcase;
					}
				}
			}
			gcs.error("case %s not found", gcs.exp.toChars());

		Lfoundcase:
			;
		}

		if (!sc.sw.sdefault && !isFinal)
		{	
			hasNoDefault = 1;

			warning("switch statement has no default");

			// Generate runtime error if the default is hit
			Statements a = new Statements();
			CompoundStatement cs;
			Statement s;

			if (global.params.useSwitchError)
				s = new SwitchErrorStatement(loc);
			else
			{   
				Expression e = new HaltExp(loc);
				s = new ExpStatement(loc, e);
			}

			a.reserve(4);
			a.push(body_);
			a.push(new BreakStatement(loc, null));
			sc.sw.sdefault = new DefaultStatement(loc, s);
			a.push(sc.sw.sdefault);
			cs = new CompoundStatement(loc, a);
			body_ = cs;
		}

	version (DMDV2) {
		if (isFinal)
		{	
			Type t = condition.type;
			while (t.ty == Ttypedef)
			{   
				// Don't use toBasetype() because that will skip past enums
				t = (cast(TypeTypedef)t).sym.basetype;
			}
			if (condition.type.ty == Tenum)
			{   
				TypeEnum te = cast(TypeEnum)condition.type;
				EnumDeclaration ed = te.toDsymbol(sc).isEnumDeclaration();
				assert(ed);
				size_t dim = ed.members.dim;
				foreach (Dsymbol s; ed.members)
				{
					if (auto em = s.isEnumMember())
					{
						for (size_t j = 0; j < cases.dim; j++)
						{   
							CaseStatement cs = cast(CaseStatement)cases.data[j];
							if (cs.exp.equals(em.value))
								goto L1;
						}
						error("enum member %s not represented in final switch", em.toChars());
					}
				L1:
					;
				}
			}
		}
	}

		sc.pop();
		return this;
	}
	
    override bool hasBreak()
	{
		assert(false);
	}
	
    override bool usesEH()
	{
		assert(false);
	}
	
    override BE blockExit()
	{
		BE result = BE.BEnone;
		if (condition.canThrow())
			result |= BE.BEthrow;

		if (body_)
		{	result |= body_.blockExit();
			if (result & BE.BEbreak)
			{   
				result |= BE.BEfallthru;
				result &= ~BE.BEbreak;
			}
		}
		else
			result |= BE.BEfallthru;

		return result;
	}

    override Expression interpret(InterState istate)
	{
version (LOG) {
		printf("SwitchStatement.interpret()\n");
}
		if (istate.start == this)
			istate.start = null;
		Expression e = null;

		if (istate.start)
		{
			e = body_ ? body_.interpret(istate) : null;
			if (istate.start)
				return null;
			if (e is EXP_CANT_INTERPRET)
				return e;
			if (e is EXP_BREAK_INTERPRET)
				return null;
			return e;
		}


		Expression econdition = condition.interpret(istate);
		if (econdition is EXP_CANT_INTERPRET)
			return EXP_CANT_INTERPRET;

		Statement s = null;
		if (cases)
		{
			for (size_t i = 0; i < cases.dim; i++)
			{
				CaseStatement cs = cast(CaseStatement)cases.data[i];
				e = Equal(TOKequal, Type.tint32, econdition, cs.exp);
				if (e is EXP_CANT_INTERPRET)
					return EXP_CANT_INTERPRET;
				if (e.isBool(true))
				{	
					s = cs;
					break;
				}
			}
		}
		if (!s)
		{	
			if (hasNoDefault)
				error("no default or case for %s in switch statement", econdition.toChars());
			s = sdefault;
		}

		assert(s);
		istate.start = s;
		e = body_ ? body_.interpret(istate) : null;
		assert(!istate.start);
		if (e is EXP_BREAK_INTERPRET)
			return null;
		return e;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("switch (");
		condition.toCBuffer(buf, hgs);
		buf.writebyte(')');
		buf.writenl();
		if (body_)
		{
			if (!body_.isScopeStatement())
			{   
				buf.writebyte('{');
				buf.writenl();
				body_.toCBuffer(buf, hgs);
				buf.writebyte('}');
				buf.writenl();
			}
			else
			{
				body_.toCBuffer(buf, hgs);
			}
		}
	}

    override Statement inlineScan(InlineScanState* iss)
	{
		//printf("SwitchStatement.inlineScan()\n");
		condition = condition.inlineScan(iss);
		body_ = body_ ? body_.inlineScan(iss) : null;
		if (sdefault)
			sdefault = cast(DefaultStatement)sdefault.inlineScan(iss);
		if (cases)
		{
			for (int i = 0; i < cases.dim; i++)
			{   
				Statement s = cast(Statement)cases.data[i];
				cases.data[i] = cast(void*)s.inlineScan(iss);
			}
		}
		return this;
	}

    override void toIR(IRState* irs)
	{
		int string;
		Blockx* blx = irs.blx;

		//printf("SwitchStatement.toIR()\n");
		IRState mystate = IRState(irs,this);

		mystate.switchBlock = blx.curblock;

		/* Block for where "break" goes to
		 */
		mystate.breakBlock = block_calloc(blx);

		/* Block for where "default" goes to.
		 * If there is a default statement, then that is where default goes.
		 * If not, then do:
		 *   default: break;
		 * by making the default block the same as the break block.
		 */
		mystate.defaultBlock = sdefault ? block_calloc(blx) : mystate.breakBlock;

		int numcases = 0;
		if (cases)
			numcases = cases.dim;

		incUsage(irs, loc);
		elem* econd = condition.toElem(&mystate);

	version (DMDV2) {
		if (hasVars)
		{	
			/* Generate a sequence of if-then-else blocks for the cases.
			 */
			if (econd.Eoper != OPvar)
			{
				elem* e = exp2_copytotemp(econd);
				block_appendexp(mystate.switchBlock, e);
				econd = e.E2;
			}

			for (int i = 0; i < numcases; i++)
			{   
				CaseStatement cs = cast(CaseStatement)cases.data[i];

				elem* ecase = cs.exp.toElem(&mystate);
				elem* e = el_bin(OPeqeq, TYbool, el_copytree(econd), ecase);
				block* b = blx.curblock;
				block_appendexp(b, e);
				block* bcase = block_calloc(blx);
				cs.cblock = bcase;
				block_next(blx, BCiftrue, null);
				list_append(&b.Bsucc, bcase);
				list_append(&b.Bsucc, blx.curblock);
			}

			/* The final 'else' clause goes to the default
			 */
			block* b = blx.curblock;
			block_next(blx, BCgoto, null);
			list_append(&b.Bsucc, mystate.defaultBlock);

			body_.toIR(&mystate);

			/* Have the end of the switch body fall through to the block
			 * following the switch statement.
			 */
			block_goto(blx, BCgoto, mystate.breakBlock);
			return;
		}
	}

		if (condition.type.isString())
		{
			// Number the cases so we can unscramble things after the sort()
			for (int i = 0; i < numcases; i++)
			{   
				CaseStatement cs = cast(CaseStatement)cases.data[i];
				cs.index = i;
			}

			cases.sort();

			/* Create a sorted array of the case strings, and si
			 * will be the symbol for it.
			 */
			dt_t* dt = null;
			Symbol* si = symbol_generate(SCstatic,type_fake(TYullong));
		version (MACHOBJ) {
			si.Sseg = Segment.DATA;
		}
			dtdword(&dt, numcases);
			dtxoff(&dt, si, 8, TYnptr);

			for (int i = 0; i < numcases; i++)
			{   
				CaseStatement cs = cast(CaseStatement)cases.data[i];

				if (cs.exp.op != TOKstring)
				{	
					error("case '%s' is not a string", cs.exp.toChars());	// BUG: this should be an assert
				}
				else
				{
					StringExp se = cast(StringExp)(cs.exp);
					uint len = se.len;
					dtdword(&dt, len);
					dtabytes(&dt, TYnptr, 0, se.len * se.sz, cast(char*)se.string_);
				}
			}

			si.Sdt = dt;
			si.Sfl = FLdata;
			outdata(si);

			/* Call:
			 *	_d_switch_string(string[] si, string econd)
			 */
			elem* eparam = el_param(econd, el_var(si));
			switch (condition.type.nextOf().ty)
			{
				case Tchar:
					econd = el_bin(OPcall, TYint, el_var(rtlsym[RTLSYM_SWITCH_STRING]), eparam);
					break;
				case Twchar:
					econd = el_bin(OPcall, TYint, el_var(rtlsym[RTLSYM_SWITCH_USTRING]), eparam);
					break;
				case Tdchar:	// BUG: implement
					econd = el_bin(OPcall, TYint, el_var(rtlsym[RTLSYM_SWITCH_DSTRING]), eparam);
					break;
				default:
					assert(0);
			}
			elem_setLoc(econd, loc);
			string = 1;
		}
		else
			string = 0;
		block_appendexp(mystate.switchBlock, econd);
		block_next(blx,BCswitch,null);

        // Corresponding free is in block_free
		targ_llong* pu = cast(targ_llong*) malloc(targ_llong.sizeof * (numcases + 1));
		mystate.switchBlock.Bswitch = pu;
		/* First pair is the number of cases, and the default block
		 */
		*pu++ = numcases;
		list_append(&mystate.switchBlock.Bsucc, mystate.defaultBlock);

		/* Fill in the first entry in each pair, which is the case value.
		 * CaseStatement.toIR() will fill in
		 * the second entry for each pair with the block.
		 */
		for (int i = 0; i < numcases; i++)
		{
			CaseStatement cs = cast(CaseStatement)cases.data[i];
			if (string)
			{
				pu[cs.index] = i;
			}
			else
			{
				pu[i] = cs.exp.toInteger();
			}
		}

		body_.toIR(&mystate);

		/* Have the end of the switch body fall through to the block
		 * following the switch statement.
		 */
		block_goto(blx, BCgoto, mystate.breakBlock);
	}
}
