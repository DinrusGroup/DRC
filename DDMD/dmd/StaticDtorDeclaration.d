module dmd.StaticDtorDeclaration;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.VarDeclaration;
import dmd.Dsymbol;
import dmd.Loc;
import dmd.Scope;
import dmd.AggregateDeclaration;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.STC;
import dmd.Identifier;
import dmd.ClassDeclaration;
import dmd.Type;
import dmd.TypeFunction;
import dmd.LINK;
import dmd.Lexer;
import dmd.Statement;
import dmd.Expression;
import dmd.EqualExp;
import dmd.ArrayTypes;
import dmd.DeclarationStatement;
import dmd.IdentifierExp;
import dmd.AddAssignExp;
import dmd.IntegerExp;
import dmd.TOK;
import dmd.IfStatement;
import dmd.ReturnStatement;
import dmd.CompoundStatement;
import dmd.Module;

import dmd.DDMDExtensions;

class StaticDtorDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

	VarDeclaration vgate;	// 'gate' variable

    this(Loc loc, Loc endloc, string name = "_staticDtor")
	{
		register();
		super(loc, endloc, Identifier.generateId(name), STCstatic, null);
	    vgate = null;
	}
	
	override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		StaticDtorDeclaration sdd = new StaticDtorDeclaration(loc, endloc);
		return super.syntaxCopy(sdd);
	}
	
	override void semantic(Scope sc)
	{
	    ClassDeclaration cd = sc.scopesym.isClassDeclaration();
		if (!type)
			type = new TypeFunction(null, Type.tvoid, false, LINK.LINKd);

		/* If the static ctor appears within a template instantiation,
		 * it could get called multiple times by the module constructors
		 * for different modules. Thus, protect it with a gate.
		 */
	    if (inTemplateInstance() && semanticRun < PASSsemantic)
		{
			/* Add this prefix to the function:
			 *	static int gate;
			 *	if (--gate != 0) return;
			 * Increment gate during constructor execution.
			 * Note that this is not thread safe; should not have threads
			 * during static destruction.
			 */
			Identifier id = Lexer.idPool("__gate");
			VarDeclaration v = new VarDeclaration(Loc(0), Type.tint32, id, null);
			v.storage_class = isSharedStaticDtorDeclaration() ? STCstatic : STCtls;
			auto sa = new Statements();
			Statement s = new DeclarationStatement(Loc(0), v);
			sa.push(s);
			Expression e = new IdentifierExp(Loc(0), id);
			e = new AddAssignExp(Loc(0), e, new IntegerExp(-1));
			e = new EqualExp(TOKnotequal, Loc(0), e, new IntegerExp(0));
			s = new IfStatement(Loc(0), null, e, new ReturnStatement(Loc(0), null), null);
			sa.push(s);
			if (fbody)
				sa.push(fbody);
			fbody = new CompoundStatement(Loc(0), sa);
			vgate = v;
		}

		FuncDeclaration.semantic(sc);

		// We're going to need ModuleInfo
		Module m = getModule();
		if (!m)
			m = sc.module_;
		if (m)
		{	
			m.needmoduleinfo = 1;
			// writef("module2 %s needs moduleinfo\n", m.toChars());
	version (IN_GCC) {
			m.strictlyneedmoduleinfo = 1;
	}
		}
	}
	
	override AggregateDeclaration isThis()
	{
		return null;
	}
	
	override bool isVirtual()
	{
		return false;
	}
	
	override bool addPreInvariant()
	{
		return false;
	}
	
	override bool addPostInvariant()
	{
		return false;
	}
	
	override void emitComment(Scope sc)
	{
	}
	
	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		if (hgs.hdrgen)
			return;
		buf.writestring("static ~this()");
		bodyToCBuffer(buf, hgs);
	}

	override void toJsonBuffer(OutBuffer buf)
	{
	}

	override StaticDtorDeclaration isStaticDtorDeclaration() { return this; }
}
