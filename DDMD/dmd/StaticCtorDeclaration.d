module dmd.StaticCtorDeclaration;

import dmd.common;
import dmd.FuncDeclaration;
import dmd.Loc;
import dmd.Dsymbol;
import dmd.AggregateDeclaration;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.STC;
import dmd.Identifier;
import dmd.TypeFunction;
import dmd.Type;
import dmd.LINK;
import dmd.Lexer;
import dmd.VarDeclaration;
import dmd.ArrayTypes;
import dmd.Expression;
import dmd.Statement;
import dmd.DeclarationStatement;
import dmd.AddAssignExp;
import dmd.EqualExp;
import dmd.TOK;
import dmd.IfStatement;
import dmd.CompoundStatement;
import dmd.Module;
import dmd.IntegerExp;
import dmd.ReturnStatement;
import dmd.IdentifierExp;

import dmd.DDMDExtensions;

class StaticCtorDeclaration : FuncDeclaration
{
	mixin insertMemberExtension!(typeof(this));

    this(Loc loc, Loc endloc, string name = "_staticCtor")
	{
		register();
		super(loc, endloc, Identifier.generateId("_staticCtor"), STCstatic, null);
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		assert(!s);
		StaticCtorDeclaration scd = new StaticCtorDeclaration(loc, endloc);
		return FuncDeclaration.syntaxCopy(scd);
	}
	
	override void semantic(Scope sc)
	{
		//printf("StaticCtorDeclaration.semantic()\n");

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
			 *	if (++gate != 1) return;
			 * Note that this is not thread safe; should not have threads
			 * during static construction.
			 */
			Identifier id = Lexer.idPool("__gate");
			VarDeclaration v = new VarDeclaration(Loc(0), Type.tint32, id, null);
			v.storage_class = isSharedStaticCtorDeclaration() ? STCstatic : STCtls;
			Statements sa = new Statements();
			Statement s = new DeclarationStatement(Loc(0), v);
			sa.push(s);
			Expression e = new IdentifierExp(Loc(0), id);
			e = new AddAssignExp(Loc(0), e, new IntegerExp(1));
			e = new EqualExp(TOKnotequal, Loc(0), e, new IntegerExp(1));
			s = new IfStatement(Loc(0), null, e, new ReturnStatement(Loc(0), null), null);
			sa.push(s);
			if (fbody)
				sa.push(fbody);
			fbody = new CompoundStatement(Loc(0), sa);
		}

		FuncDeclaration.semantic(sc);

		// We're going to need ModuleInfo
		Module m = getModule();
		if (!m)
			m = sc.module_;

		if (m)
		{	
			m.needmoduleinfo = 1;
			// writef("module1 %s needs moduleinfo\n", m.toChars());
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
		{
			buf.writestring("static this();\n");
			return;
		}
		buf.writestring("static this()");
		bodyToCBuffer(buf, hgs);
	}

	override void toJsonBuffer(OutBuffer buf)
	{
	}

	override StaticCtorDeclaration isStaticCtorDeclaration() { return this; }
}
