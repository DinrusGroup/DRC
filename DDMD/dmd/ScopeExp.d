module dmd.ScopeExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.ScopeDsymbol;
import dmd.OutBuffer;
import dmd.TemplateInstance;
import dmd.Loc;
import dmd.TOK;
import dmd.Scope;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.Global;
import dmd.Dsymbol;
import dmd.VarExp;
import dmd.DotVarExp;
import dmd.DsymbolExp;
import dmd.Type;

import dmd.DDMDExtensions;

class ScopeExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	ScopeDsymbol sds;

	this(Loc loc, ScopeDsymbol pkg)
	{
		register();
		super(loc, TOK.TOKimport, ScopeExp.sizeof);
		//printf("ScopeExp.ScopeExp(pkg = '%s')\n", pkg.toChars());
		//static int count; if (++count == 38) *(char*)0=0;
		this.sds = pkg;
	}

	override Expression syntaxCopy()
	{
		ScopeExp se = new ScopeExp(loc, cast(ScopeDsymbol)sds.syntaxCopy(null));
		return se;
	}

	override Expression semantic(Scope sc)
	{
		TemplateInstance ti;
		ScopeDsymbol sds2;

	version (LOGSEMANTIC) {
		printf("+ScopeExp.semantic('%s')\n", toChars());
	}
	Lagain:
		ti = sds.isTemplateInstance();
		if (ti && !global.errors)
		{
			Dsymbol s;
			if (!ti.semanticRun)
				ti.semantic(sc);
			s = ti.inst.toAlias();
			sds2 = s.isScopeDsymbol();
			if (!sds2)
			{   
				Expression e;

				//printf("s = %s, '%s'\n", s.kind(), s.toChars());
				if (ti.withsym)
				{
					// Same as wthis.s
					e = new VarExp(loc, ti.withsym.withstate.wthis);
					e = new DotVarExp(loc, e, s.isDeclaration());
				}
				else
					e = new DsymbolExp(loc, s);

				e = e.semantic(sc);
				//printf("-1ScopeExp.semantic()\n");
				return e;
			}
			if (sds2 != sds)
			{
				sds = sds2;
				goto Lagain;
			}
			//printf("sds = %s, '%s'\n", sds.kind(), sds.toChars());
		}
		else
		{
			//printf("sds = %s, '%s'\n", sds.kind(), sds.toChars());
			//printf("\tparent = '%s'\n", sds.parent.toChars());
			sds.semantic(sc);
		}
		type = Type.tvoid;
		//printf("-2ScopeExp.semantic() %s\n", toChars());
		return this;
	}

	override elem* toElem(IRState* irs)
	{
		assert(false);
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		if (sds.isTemplateInstance())
		{
			sds.toCBuffer(buf, hgs);
		}
		else
		{
			buf.writestring(sds.kind());
			buf.writestring(" ");
			buf.writestring(sds.toChars());
		}
	}
}

