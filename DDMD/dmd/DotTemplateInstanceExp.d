module dmd.DotTemplateInstanceExp;

import dmd.common;
import dmd.ArrayTypes;
import dmd.Expression;
import dmd.UnaExp;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.TemplateInstance;
import dmd.HdrGenState;
import dmd.TOK;
import dmd.PREC;
import dmd.Declaration;
import dmd.Global;
import dmd.TypePointer;
import dmd.TypeStruct;
import dmd.TY;
import dmd.ScopeExp;
import dmd.DotExp;
import dmd.Type;
import dmd.Identifier;
import dmd.ErrorExp;
import dmd.DotVarExp;
import dmd.TemplateDeclaration;
import dmd.Dsymbol;
import dmd.DotTemplateExp;
import dmd.DotIdExp;
import dmd.TemplateExp;
import dmd.DsymbolExp;

import dmd.expression.Util;

import dmd.DDMDExtensions;

/* Things like:
 *	foo.bar!(args)
 */
class DotTemplateInstanceExp : UnaExp
{
	mixin insertMemberExtension!(typeof(this));

	TemplateInstance ti;

	this(Loc loc, Expression e, Identifier name, Objects tiargs)
	{
		register();
		super(loc, TOK.TOKdotti, DotTemplateInstanceExp.sizeof, e);
		//printf("DotTemplateInstanceExp()\n");
		this.ti = new TemplateInstance(loc, name);
		this.ti.tiargs = tiargs;
	}

	override Expression syntaxCopy()
	{
		DotTemplateInstanceExp de = new DotTemplateInstanceExp(loc, e1.syntaxCopy(), ti.name, TemplateInstance.arraySyntaxCopy(ti.tiargs));
		return de;
	}

	TemplateDeclaration getTempdecl(Scope sc)
	{
version(LOGSEMANTIC) {
		printf("DotTemplateInstanceExp::getTempdecl('%s')\n", toChars());
}
		if (!ti.tempdecl)
		{
			Expression e = new DotIdExp(loc, e1, ti.name);
			e = e.semantic(sc);
			if (e.op == TOKdottd)
			{
				auto dte = cast(DotTemplateExp)e;
				ti.tempdecl = dte.td;
			}
			else if (e.op == TOKimport)
			{
				auto se = cast(ScopeExp)e;
				ti.tempdecl = se.sds.isTemplateDeclaration();
			}
		}
		return ti.tempdecl;
	}
	
	override Expression semantic(Scope sc)
	{
version (LOGSEMANTIC) {
		printf("DotTemplateInstanceExp.semantic('%s')\n", toChars());
}
		Expression eleft;
		Expression e = new DotIdExp(loc, e1, ti.name);
L1:
		e = e.semantic(sc);
		if (e.op == TOKdottd)
		{
			DotTemplateExp dte = cast(DotTemplateExp )e;
			TemplateDeclaration td = dte.td;
			eleft = dte.e1;
			ti.tempdecl = td;
			ti.semantic(sc);
			Dsymbol s = ti.inst.toAlias();
			Declaration v = s.isDeclaration();
			if (v)
			{
				e = new DotVarExp(loc, eleft, v);
				e = e.semantic(sc);
				return e;
			}
			e = new ScopeExp(loc, ti);
			e = new DotExp(loc, eleft, e);
			e = e.semantic(sc);
			return e;
		}
		else if (e.op == TOKimport)
		{
			auto se = cast(ScopeExp)e;
			TemplateDeclaration td = se.sds.isTemplateDeclaration();
			if (!td)
			{
				error("%s is not a template", e.toChars());
				return new ErrorExp();
			}
			ti.tempdecl = td;
			e = new ScopeExp(loc, ti);
			e = e.semantic(sc);
			return e;
		}
		else if (e.op == TOKdotexp)
		{
			DotExp de = cast(DotExp )e;

			if (de.e2.op == TOKimport)
			{
				// This should *really* be moved to ScopeExp::semantic()
				ScopeExp se = cast(ScopeExp )de.e2;
				de.e2 = new DsymbolExp(loc, se.sds);
				de.e2 = de.e2.semantic(sc);
			}

			if (de.e2.op == TOKtemplate)
			{
				auto te = cast(TemplateExp) de.e2;
				e = new DotTemplateExp(loc,de.e1,te.td);
			}
		goto L1;
		}
		error("%s isn't a template", e.toChars());
		return new ErrorExp();
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		expToCBuffer(buf, hgs, e1, PREC.PREC_primary);
		buf.writeByte('.');
		ti.toCBuffer(buf, hgs);
	}

	override void dump(int indent)
	{
		assert(false);
	}
}

