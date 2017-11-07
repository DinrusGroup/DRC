module dmd.SynchronizedStatement;

import dmd.common;
import dmd.Statement;
import dmd.IntegerExp;
import dmd.TypeSArray;
import dmd.CompoundStatement;
import dmd.Loc;
import dmd.Scope;
import dmd.Expression;
import dmd.ClassDeclaration;
import dmd.Id;
import dmd.TypeIdentifier;
import dmd.Type;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.InlineScanState;
import dmd.IRState;
import dmd.CastExp;
import dmd.TryFinallyStatement;
import dmd.ExpStatement;
import dmd.CallExp;
import dmd.DeclarationExp;
import dmd.VarExp;
import dmd.DeclarationStatement;
import dmd.ArrayTypes;
import dmd.Statement;
import dmd.VarDeclaration;
import dmd.ExpInitializer;
import dmd.Lexer;
import dmd.Identifier;
import dmd.FuncDeclaration;
import dmd.BE;
import dmd.STC;
import dmd.DotIdExp;

import dmd.backend.elem;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class SynchronizedStatement : Statement
{
	mixin insertMemberExtension!(typeof(this));

    Expression exp;
    Statement body_;

    this(Loc loc, Expression exp, Statement body_)
	{
		register();
		super(loc);
		
		this.exp = exp;
		this.body_ = body_;
		this.esync = null;
	}
	
    override Statement syntaxCopy()
	{
		assert(false);
	}
	
    override Statement semantic(Scope sc)
	{
		if (exp)
		{
			exp = exp.semantic(sc);
			exp = resolveProperties(sc, exp);
			ClassDeclaration cd = exp.type.isClassHandle();
			if (!cd)
				error("can only synchronize on class objects, not '%s'", exp.type.toChars());
			else if (cd.isInterfaceDeclaration())
			{   
				/* Cast the interface to an object, as the object has the monitor,
				 * not the interface.
				 */
				Type t = new TypeIdentifier(Loc(0), Id.Object_);

				t = t.semantic(Loc(0), sc);
				exp = new CastExp(loc, exp, t);
				exp = exp.semantic(sc);
			}

static if (true) {
			/* Rewrite as:
			 *  auto tmp = exp;
			 *  _d_monitorenter(tmp);
			 *  try { body } finally { _d_monitorexit(tmp); }
			 */
			Identifier id = Lexer.uniqueId("__sync");
			ExpInitializer ie = new ExpInitializer(loc, exp);
			VarDeclaration tmp = new VarDeclaration(loc, exp.type, id, ie);

			Statements cs = new Statements();
			cs.push(new DeclarationStatement(loc, new DeclarationExp(loc, tmp)));

			FuncDeclaration fdenter = FuncDeclaration.genCfunc(Type.tvoid, Id.monitorenter);
			Expression e = new CallExp(loc, new VarExp(loc, fdenter), new VarExp(loc, tmp));
			e.type = Type.tvoid;			// do not run semantic on e
			cs.push(new ExpStatement(loc, e));

			FuncDeclaration fdexit = FuncDeclaration.genCfunc(Type.tvoid, Id.monitorexit);
			e = new CallExp(loc, new VarExp(loc, fdexit), new VarExp(loc, tmp));
			e.type = Type.tvoid;			// do not run semantic on e
			Statement s = new ExpStatement(loc, e);
			s = new TryFinallyStatement(loc, body_, s);
			cs.push(s);

			s = new CompoundStatement(loc, cs);
			return s.semantic(sc);
}
		}
///	static if (true) {
		else
		{	
			/* Generate our own critical section, then rewrite as:
			 *  __gshared byte[CriticalSection.sizeof] critsec;
			 *  _d_criticalenter(critsec.ptr);
			 *  try { body } finally { _d_criticalexit(critsec.ptr); }
			 */
			Identifier id = Lexer.uniqueId("__critsec");
			Type t = new TypeSArray(Type.tint8, new IntegerExp(PTRSIZE +  os_critsecsize()));
			VarDeclaration tmp = new VarDeclaration(loc, t, id, null);
			tmp.storage_class |= STCgshared | STCstatic;

			Statements cs = new Statements();
			cs.push(new DeclarationStatement(loc, new DeclarationExp(loc, tmp)));

			FuncDeclaration fdenter = FuncDeclaration.genCfunc(Type.tvoid, Id.criticalenter);
			Expression e = new DotIdExp(loc, new VarExp(loc, tmp), Id.ptr);
			e = e.semantic(sc);
			e = new CallExp(loc, new VarExp(loc, fdenter), e);
			e.type = Type.tvoid;			// do not run semantic on e
			cs.push(new ExpStatement(loc, e));

			FuncDeclaration fdexit = FuncDeclaration.genCfunc(Type.tvoid, Id.criticalexit);
			e = new DotIdExp(loc, new VarExp(loc, tmp), Id.ptr);
			e = e.semantic(sc);
			e = new CallExp(loc, new VarExp(loc, fdexit), e);
			e.type = Type.tvoid;			// do not run semantic on e
			Statement s = new ExpStatement(loc, e);
			s = new TryFinallyStatement(loc, body_, s);
			cs.push(s);

			s = new CompoundStatement(loc, cs);
			return s.semantic(sc);
		}
///	}
		if (body_)
			body_ = body_.semantic(sc);

		return this;
	}
	
    override bool hasBreak()
	{
		assert(false);
	}
	
    override bool hasContinue()
	{
		assert(false);
	}
	
    override bool usesEH()
	{
		assert(false);
	}
	
    override BE blockExit()
	{
		assert(false);
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

    override Statement inlineScan(InlineScanState* iss)
	{
		assert(false);
	}

// Back end
    elem* esync;

	this(Loc loc, elem *esync, Statement body_)
	{
		register();
		assert(false);
		super(loc);
	}
	
    override void toIR(IRState* irs)
	{
		assert(false);
	}
}
