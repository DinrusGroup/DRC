module dmd.SuperExp;

import dmd.common;
import dmd.Expression;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.InlineCostState;
import dmd.InlineDoState;
import dmd.FuncDeclaration;
import dmd.ClassDeclaration;
import dmd.Dsymbol;
import dmd.HdrGenState;
import dmd.ThisExp;
import dmd.TOK;
import dmd.CSX;
import dmd.Type;

import dmd.DDMDExtensions;

class SuperExp : ThisExp
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc)
	{
		register();
		super(loc);
		op = TOK.TOKsuper;
	}

	override Expression semantic(Scope sc)
	{
		FuncDeclaration fd;
		FuncDeclaration fdthis;

	version (LOGSEMANTIC) {
		printf("SuperExp.semantic('%s')\n", toChars());
	}
		if (type)
			return this;

		/* Special case for typeof(this) and typeof(super) since both
		 * should work even if they are not inside a non-static member function
		 */
		if (sc.intypeof)
		{
			// Find enclosing class
			for (Dsymbol s = sc.parent; 1; s = s.parent)
			{
				ClassDeclaration cd;

				if (!s)
				{
					error("%s is not in a class scope", toChars());
					goto Lerr;
				}
				cd = s.isClassDeclaration();
				if (cd)
				{
					cd = cd.baseClass;
					if (!cd)
					{   
						error("class %s has no 'super'", s.toChars());
						goto Lerr;
					}
					type = cd.type;
					return this;
				}
			}
		}

		fdthis = sc.parent.isFuncDeclaration();
		fd = hasThis(sc);
		if (!fd)
			goto Lerr;
		assert(fd.vthis);
		var = fd.vthis;
		assert(var.parent);

		Dsymbol s = fd.toParent();
		while (s && s.isTemplateInstance())
			s = s.toParent();
		assert(s);
		ClassDeclaration cd = s.isClassDeclaration();
	//printf("parent is %s %s\n", fd.toParent().kind(), fd.toParent().toChars());
		if (!cd)
			goto Lerr;
		if (!cd.baseClass)
		{
			error("no base class for %s", cd.toChars());
			type = fd.vthis.type;
		}
		else
		{
			type = cd.baseClass.type;
		}

		var.isVarDeclaration().checkNestedReference(sc, loc);

		if (!sc.intypeof)
			sc.callSuper |= CSXsuper;
		return this;

	Lerr:
		error("'super' is only allowed in non-static class member functions");
		type = Type.tint32;
		return this;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("super");
	}

	override void scanForNestedRef(Scope sc)
	{
		ThisExp.scanForNestedRef(sc);
	}

	override int inlineCost(InlineCostState* ics)
	{
		assert(false);
	}

	override Expression doInline(InlineDoState ids)
	{
		assert(false);
	}
}

