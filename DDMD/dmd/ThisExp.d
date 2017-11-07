module dmd.ThisExp;

import dmd.common;
import dmd.Expression;
import dmd.Declaration;
import dmd.StructDeclaration;
import dmd.ClassDeclaration;
import dmd.Dsymbol;
import dmd.FuncDeclaration;
import dmd.backend.elem;
import dmd.CSX;
import dmd.InterState;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.Type;
import dmd.TOK;
import dmd.InlineCostState;
import dmd.InlineDoState;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.VarExp;
import dmd.TY;

import dmd.codegen.Util;
import dmd.backend.TYM;
import dmd.backend.Util;
import dmd.backend.OPER;

import dmd.DDMDExtensions;

class ThisExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Declaration var;

	this(Loc loc)
	{
		register();
		super(loc, TOK.TOKthis, ThisExp.sizeof);
		//printf("ThisExp::ThisExp() loc = %d\n", loc.linnum);
	}

	override Expression semantic(Scope sc)
	{
		FuncDeclaration fd;
		FuncDeclaration fdthis;

	version (LOGSEMANTIC) {
		printf("ThisExp::semantic()\n");
	}
		if (type)
		{	
			//assert(global.errors || var);
			return this;
		}

		/* Special case for typeof(this) and typeof(super) since both
		 * should work even if they are not inside a non-static member function
		 */
		if (sc.intypeof)
		{
			// Find enclosing struct or class
			for (Dsymbol s = sc.parent; 1; s = s.parent)
			{
				if (!s)
				{
					error("%s is not in a class or struct scope", toChars());
					goto Lerr;
				}
				ClassDeclaration cd = s.isClassDeclaration();
				if (cd)
				{
					type = cd.type;
					return this;
				}
				StructDeclaration sd = s.isStructDeclaration();
				if (sd)
				{
		version (STRUCTTHISREF) {
				type = sd.type;
		} else {
				type = sd.type.pointerTo();
		}
				return this;
				}
			}
		}

		fdthis = sc.parent.isFuncDeclaration();
		fd = hasThis(sc);	// fd is the uplevel function with the 'this' variable
		if (!fd)
			goto Lerr;

		assert(fd.vthis);
		var = fd.vthis;
		assert(var.parent);
		type = var.type;
		var.isVarDeclaration().checkNestedReference(sc, loc);
		if (!sc.intypeof)
			sc.callSuper |= CSXthis;
		return this;

	Lerr:
		error("'this' is only defined in non-static member functions, not %s", sc.parent.toChars());
		type = Type.terror;
		return this;
	}

	override Expression interpret(InterState istate)
	{
		assert(false);
	}

	override bool isBool(bool result)
	{
		return result ? true : false;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("this");
	}

version (DMDV2) {
	override bool isLvalue()
	{
		return true;
	}
}
	override Expression toLvalue(Scope sc, Expression e)
	{
		return this;
	}

	override void scanForNestedRef(Scope sc)
	{
		assert(var);
		var.isVarDeclaration().checkNestedReference(sc, Loc(0));
	}

	override int inlineCost(InlineCostState* ics)
	{
		FuncDeclaration fd = ics.fd;
		if (!ics.hdrscan)
			if (fd.isNested() || !ics.hasthis)
				return COST_MAX;

		return 1;
	}

	override Expression doInline(InlineDoState ids)
	{
		//if (!ids.vthis)
		//error("no 'this' when inlining %s", ids.parent.toChars());
		if (!ids.vthis)
		{
			return this;
		}

		VarExp ve = new VarExp(loc, ids.vthis);
		ve.type = type;
		return ve;
	}

	override elem* toElem(IRState* irs)
	{
		elem* ethis;
		FuncDeclaration fd;

		//printf("ThisExp::toElem()\n");
		assert(irs.sthis);

		if (var)
		{
			assert(var.parent);
			fd = var.toParent2().isFuncDeclaration();
			assert(fd);
			ethis = getEthis(loc, irs, fd);
		}
		else
			ethis = el_var(irs.sthis);

	version (STRUCTTHISREF) {
		if (type.ty == Tstruct)
		{	
			ethis = el_una(OPind, TYstruct, ethis);
			ethis.Enumbytes = cast(uint)type.size();
		}
	}
		el_setLoc(ethis,loc);
		return ethis;
	}
}

