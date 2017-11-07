module dmd.ReturnStatement;

import dmd.common;
import dmd.Loc;
import dmd.Statement;
import dmd.GotoStatement;
import dmd.STC;
import dmd.CompoundStatement;
import dmd.Id;
import dmd.AssignExp;
import dmd.ExpStatement;
import dmd.FuncDeclaration;
import dmd.IntegerExp;
import dmd.ThisExp;
import dmd.StructDeclaration;
import dmd.TypeFunction;
import dmd.CSX;
import dmd.RET;
import dmd.TOK;
import dmd.Type;
import dmd.Expression;
import dmd.StructLiteralExp;
import dmd.TypeStruct;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.InterState;
import dmd.InlineCostState;
import dmd.InlineDoState;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.TY;
import dmd.WANT;
import dmd.VarExp;
import dmd.VarDeclaration;
import dmd.GlobalExpressions;
import dmd.BE;
import dmd.Global;

import dmd.codegen.Util;

import dmd.backend.Blockx;
import dmd.backend.elem;
import dmd.backend.TYM;
import dmd.backend.Util;
import dmd.backend.OPER;
import dmd.backend.mTY;
import dmd.backend.BC;

import core.stdc.string;

import dmd.DDMDExtensions;

class ReturnStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;

    this(Loc loc, Expression exp)
	{
		register();
		super(loc);
		this.exp = exp;
	}
	
    override Statement syntaxCopy()
	{
		Expression e = exp ? exp.syntaxCopy() : null;
		return new ReturnStatement(loc, e);
	}
	
	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.printf("return ");
		if (exp)
			exp.toCBuffer(buf, hgs);
		buf.writeByte(';');
		buf.writenl();
	}
	
	override Statement semantic(Scope sc)
	{
		//printf("ReturnStatement.semantic() %s\n", toChars());

		FuncDeclaration fd = sc.parent.isFuncDeclaration();
		Scope scx = sc;
		int implicit0 = 0;

		if (sc.fes)
		{
			// Find scope of function foreach is in
			for (; 1; scx = scx.enclosing)
			{
				assert(scx);
				if (scx.func !is fd)
				{	
					fd = scx.func;		// fd is now function enclosing foreach
					break;
				}
			}
		}

		Type tret = fd.type.nextOf();
		if (fd.tintro) {
			/* We'll be implicitly casting the return expression to tintro
			*/
			tret = fd.tintro.nextOf();
		}

		Type tbret = null;

		if (tret) {
			tbret = tret.toBasetype();
		}

		// main() returns 0, even if it returns void
		if (!exp && (!tbret || tbret.ty == TY.Tvoid) && fd.isMain())
		{	
			implicit0 = 1;
			exp = new IntegerExp(0);
		}

		if (sc.incontract || scx.incontract)
			error("return statements cannot be in contracts");

		if (sc.tf || scx.tf)
			error("return statements cannot be in finally, scope(exit) or scope(success) bodies");

		if (fd.isCtorDeclaration())
		{
			// Constructors implicitly do:
			//	return this;
			if (exp && exp.op != TOK.TOKthis) {
				error("cannot return expression from constructor");
			}

			exp = new ThisExp(Loc(0));
		}

		if (!exp) {
			fd.nrvo_can = 0;
		}

		if (exp)
		{
			fd.hasReturnExp |= 1;

			exp = exp.semantic(sc);
			exp = resolveProperties(sc, exp);
			exp = exp.optimize(WANT.WANTvalue);

			if (fd.nrvo_can && exp.op == TOK.TOKvar) {   
				VarExp ve = cast(VarExp)exp;
				VarDeclaration v = ve.var.isVarDeclaration();

				if ((cast(TypeFunction)fd.type).isref) {
					// Function returns a reference
					fd.nrvo_can = 0;
				} else if (!v || v.isOut() || v.isRef()) {
					fd.nrvo_can = 0;
				} else if (tbret.ty == TY.Tstruct && (cast(TypeStruct)tbret).sym.dtor) {
					// Struct being returned has destructors
					fd.nrvo_can = 0;
				} else if (fd.nrvo_var is null) {
					if (!v.isDataseg() && !v.isParameter() && v.toParent2() == fd) {
						//printf("Setting nrvo to %s\n", v.toChars());
						fd.nrvo_var = v;
					} else {
						fd.nrvo_can = 0;
					}
				} else if (fd.nrvo_var != v) {
					fd.nrvo_can = 0;
				}
			} else {
				fd.nrvo_can = 0;
			}

			if (fd.returnLabel && tbret.ty != TY.Tvoid) {
				//;
			} else if (fd.inferRetType) {
				auto tf = cast(TypeFunction)fd.type;
	            assert(tf.ty == TY.Tfunction);
	            Type tfret = tf.nextOf();
	            if (tfret)
                {
   					if (!exp.type.equals(tfret))
						error("mismatched function return type inference of %s and %s", exp.type.toChars(), tfret.toChars());
		            /* The "refness" is determined by the first return statement,
		             * not all of them. This means:
		             *    return 3; return x;  // ok, x can be a value
		             *    return x; return 3;  // error, 3 is not an lvalue
		             */
				}
				else
				{
		            if (tf.isref)
		            {   /* Determine "refness" of function return:
		                 * if it's an lvalue, return by ref, else return by value
		                 */
		                if (exp.isLvalue())
		                {
			                /* Return by ref
			                 * (but first ensure it doesn't fail the "check for
			                 * escaping reference" test)
			                 */
			                uint errors = global.errors;
			                global.gag++;
			                exp.checkEscapeRef();
			                global.gag--;
			                if (errors != global.errors)
			                {   tf.isref = false;	// return by value
			                    global.errors = errors;
			                }
		                }
		                else
			                tf.isref = false;	// return by value
		            }
		            tf.next = exp.type;
		            fd.type = tf.semantic(loc, sc);

					if (!fd.tintro)
					{   
						tret = fd.type.nextOf();
						tbret = tret.toBasetype();
					}
				}
			} else if (tbret.ty != TY.Tvoid)
			{
				exp = exp.implicitCastTo(sc, tret);
				exp = exp.optimize(WANT.WANTvalue);
			}
		} else if (fd.inferRetType) {
			if (fd.type.nextOf())
			{
				if (fd.type.nextOf().ty != TY.Tvoid) {
					error("mismatched function return type inference of void and %s", fd.type.nextOf().toChars());
				}
			}
			else
			{
				(cast(TypeFunction*)fd.type).next = Type.tvoid;
				fd.type = fd.type.semantic(loc, sc);
				if (!fd.tintro)
				{   
					tret = Type.tvoid;
					tbret = tret;
				}
			}
		}
		else if (tbret.ty != TY.Tvoid)	 {// if non-void return
			error("return expression expected");
		}

		if (sc.fes)
		{
			Statement s;

			if (exp && !implicit0)
			{
				exp = exp.implicitCastTo(sc, tret);
			}
			if (!exp || exp.op == TOK.TOKint64 || exp.op == TOK.TOKfloat64 ||
				exp.op == TOK.TOKimaginary80 || exp.op == TOK.TOKcomplex80 ||
				exp.op == TOK.TOKthis || exp.op == TOK.TOKsuper || exp.op == TOK.TOKnull ||
				exp.op == TOK.TOKstring)
			{
				sc.fes.cases.push(cast(void*)this);
				// Construct: return cases.dim+1;
				s = new ReturnStatement(Loc(0), new IntegerExp(sc.fes.cases.dim + 1));
			}
			else if (fd.type.nextOf().toBasetype() == Type.tvoid)
			{
				s = new ReturnStatement(Loc(0), null);
				sc.fes.cases.push(cast(void*)s);

				// Construct: { exp; return cases.dim + 1; }
				Statement s1 = new ExpStatement(loc, exp);
				Statement s2 = new ReturnStatement(Loc(0), new IntegerExp(sc.fes.cases.dim + 1));
				s = new CompoundStatement(loc, s1, s2);
			}
			else
			{
				// Construct: return vresult;
				if (!fd.vresult)
				{	
					// Declare vresult
					VarDeclaration v = new VarDeclaration(loc, tret, Id.result, null);
					v.noauto = true;
					v.semantic(scx);
					if (!scx.insert(v)) {
						assert(0);
					}
					v.parent = fd;
					fd.vresult = v;
				}

				s = new ReturnStatement(Loc(0), new VarExp(Loc(0), fd.vresult));
				sc.fes.cases.push(cast(void*)s);

				// Construct: { vresult = exp; return cases.dim + 1; }
				exp = new AssignExp(loc, new VarExp(Loc(0), fd.vresult), exp);
				exp.op = TOK.TOKconstruct;
				exp = exp.semantic(sc);
				Statement s1 = new ExpStatement(loc, exp);
				Statement s2 = new ReturnStatement(Loc(0), new IntegerExp(sc.fes.cases.dim + 1));
				s = new CompoundStatement(loc, s1, s2);
			}
			return s;
		}

		if (exp)
		{
			if (fd.returnLabel && tbret.ty != TY.Tvoid)
			{
				assert(fd.vresult);
				VarExp v = new VarExp(Loc(0), fd.vresult);

				exp = new AssignExp(loc, v, exp);
				exp.op = TOK.TOKconstruct;
				exp = exp.semantic(sc);
			}

			if ((cast(TypeFunction)fd.type).isref && !fd.isCtorDeclaration())
			{   // Function returns a reference
				if (tbret.isMutable())
					exp = exp.modifiableLvalue(sc, exp);
				else
					exp = exp.toLvalue(sc, exp);

				exp.checkEscapeRef();
			}
            else
            {
			    //exp.dump(0);
			    //exp.print();
			    exp.checkEscape();
            }
		}

		/* BUG: need to issue an error on:
		 *	this
		 *	{   if (x) return;
		 *	    super();
		 *	}
		 */

		if (sc.callSuper & CSX.CSXany_ctor && !(sc.callSuper & (CSX.CSXthis_ctor | CSX.CSXsuper_ctor))) {
			error("return without calling constructor");
		}

		sc.callSuper |= CSX.CSXreturn;

		// See if all returns are instead to be replaced with a goto returnLabel;
		if (fd.returnLabel)
		{
			GotoStatement gs = new GotoStatement(loc, Id.returnLabel);

			gs.label = fd.returnLabel;
			if (exp)
			{   
				/* Replace: return exp;
				 * with:    exp; goto returnLabel;
				 */
				Statement s = new ExpStatement(Loc(0), exp);
				return new CompoundStatement(loc, s, gs);
			}
			return gs;
		}

		if (exp && tbret.ty == Tvoid && !implicit0)
		{
			/* Replace:
			 *	return exp;
			 * with:
			 *	exp; return;
			 */
			Statement s = new ExpStatement(loc, exp);
			exp = null;
			s = s.semantic(sc);
			loc = Loc();
			return new CompoundStatement(loc, s, this);
		}

		return this;
	}
	
    override BE blockExit()
	{
		BE result = BE.BEreturn;
		if (exp && exp.canThrow())
			result |= BE.BEthrow;

		return result;
	}
	
    override Expression interpret(InterState istate)
	{
version (LOG) {
		printf("ReturnStatement.interpret(%s)\n", exp ? exp.toChars() : "");
}
		mixin(START);
		if (!exp)
			return EXP_VOID_INTERPRET;
version (LOG) {
		Expression e = exp.interpret(istate);
		printf("e = %p\n", e);
		return e;
} else {
		return exp.interpret(istate);
}
	}

    override int inlineCost(InlineCostState* ics)
	{
		// Can't handle return statements nested in if's
		if (ics.nested)
			return COST_MAX;
		return exp ? exp.inlineCost(ics) : 0;
	}
	
    override Expression doInline(InlineDoState ids)
	{
		//printf("ReturnStatement.doInline() '%s'\n", exp ? exp.toChars() : "");
		return exp ? exp.doInline(ids) : null;
	}
	
    override Statement inlineScan(InlineScanState* iss)
	{
		//printf("ReturnStatement.inlineScan()\n");
		if (exp)
		{
			exp = exp.inlineScan(iss);
		}
		return this;
	}

    override void toIR(IRState* irs)
	{
		Blockx* blx = irs.blx;
		
		incUsage(irs, loc);
		if (exp)
		{	
			//printf("%.*s %.*s\n", exp.classinfo.name, exp.toChars());
			elem *e;

			FuncDeclaration func = irs.getFunc();
			assert(func);
			assert(func.type.ty == TY.Tfunction);
			TypeFunction tf = cast(TypeFunction)(func.type);

			RET retmethod = tf.retStyle();
			if (retmethod == RET.RETstack)
			{
				elem* es;

				/* If returning struct literal, write result
				 * directly into return value
				 */
				if (exp.op == TOK.TOKstructliteral)
				{	
					StructLiteralExp se = cast(StructLiteralExp)exp;
					enum objectSize = __traits(classInstanceSize, StructLiteralExp);
					ubyte[objectSize] save;
					memcpy(save.ptr, cast(void*)se, objectSize);
					se.sym = irs.shidden;
					se.soffset = 0;
					se.fillHoles = 1;
					e = exp.toElem(irs);
					memcpy(cast(void*)se, save.ptr, objectSize);
				}
				else
					e = exp.toElem(irs);
				
				assert(e);

				if (exp.op == TOK.TOKstructliteral || (func.nrvo_can && func.nrvo_var))
				{
					// Return value via hidden pointer passed as parameter
					// Write exp; return shidden;
					es = e;
				}
				else
				{
					// Return value via hidden pointer passed as parameter
					// Write *shidden=exp; return shidden;
					int op;
					tym_t ety;

					ety = e.Ety;
					es = el_una(OPER.OPind,ety,el_var(irs.shidden));
					op = (tybasic(ety) == TYM.TYstruct) ? OPER.OPstreq : OPER.OPeq;
					es = el_bin(op, ety, es, e);
					if (op == OPER.OPstreq)
						es.Enumbytes = cast(uint)exp.type.size();
version (DMDV2) {
					/* Call postBlit() on *shidden
					 */
					Type tb = exp.type.toBasetype();
					//if (tb.ty == TY.Tstruct) exp.dump(0);
					if ((exp.op == TOK.TOKvar || exp.op == TOK.TOKdotvar || exp.op == TOK.TOKstar) &&
						tb.ty == TY.Tstruct)
					{   
						StructDeclaration sd = (cast(TypeStruct)tb).sym;
						if (sd.postblit)
						{	
							FuncDeclaration fd = sd.postblit;
							elem* ec = el_var(irs.shidden);
							ec = callfunc(loc, irs, 1, Type.tvoid, ec, tb.pointerTo(), fd, fd.type, null, null);
							es = el_bin(OPER.OPcomma, ec.Ety, es, ec);
						}

static if (false) {
						/* It has been moved, so disable destructor
						 */
						if (exp.op == TOK.TOKvar)
						{	
							VarExp ve = cast(VarExp)exp;
							VarDeclaration v = ve.var.isVarDeclaration();
							if (v && v.rundtor)
							{
								elem* er = el_var(v.rundtor.toSymbol());
								er = el_bin(OPER.OPeq, TYM.TYint, er, el_long(TYM.TYint, 0));
								es = el_bin(OPER.OPcomma, TYM.TYint, es, er);
							}
						}
}
					}
}
				}
				e = el_var(irs.shidden);
				e = el_bin(OPER.OPcomma, e.Ety, es, e);
			}
///version (DMDV2) {
			else if (tf.isref)
			{   // Reference return, so convert to a pointer
				Expression ae = exp.addressOf(null);
				e = ae.toElem(irs);
			}
///}
			else
			{
				e = exp.toElem(irs);
				assert(e);
			}

			block_appendexp(blx.curblock, e);
			block_next(blx, BC.BCretexp, null);
		}
		else
			block_next(blx, BC.BCret, null);
	}

    override ReturnStatement isReturnStatement() { return this; }
}
