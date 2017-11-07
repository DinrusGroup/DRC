module dmd.FuncExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.elem;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.InlineCostState;
import dmd.InterState;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.FuncLiteralDeclaration;
import dmd.TOK;
import dmd.TypeFunction;
import dmd.TypeDelegate;
import dmd.TY;
import dmd.Type;
import dmd.Global;

import dmd.backend.Util;
import dmd.codegen.Util;
import dmd.backend.TYM;
import dmd.backend.Symbol;

import dmd.DDMDExtensions;

class FuncExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	FuncLiteralDeclaration fd;

	this(Loc loc, FuncLiteralDeclaration fd)
	{
		register();
		super(loc, TOK.TOKfunction, FuncExp.sizeof);
		this.fd = fd;
	}

	override Expression syntaxCopy()
	{
		return new FuncExp(loc, cast(FuncLiteralDeclaration)fd.syntaxCopy(null));
	}

	override Expression semantic(Scope sc)
	{
version (LOGSEMANTIC) {
		printf("FuncExp.semantic(%s)\n", toChars());
}
		if (!type)
		{
			fd.semantic(sc);

			//fd.parent = sc.parent;
			if (global.errors)
			{
			}
			else
			{
				fd.semantic2(sc);
				if (!global.errors ||
					// need to infer return type
					(fd.type && fd.type.ty == TY.Tfunction && !fd.type.nextOf()))
				{
					fd.semantic3(sc);

					if (!global.errors && global.params.useInline)
						fd.inlineScan();
				}
			}

			// need to infer return type
			if (global.errors && fd.type && fd.type.ty == TY.Tfunction && !fd.type.nextOf())
				(cast(TypeFunction)fd.type).next = Type.terror;

			// Type is a "delegate to" or "pointer to" the function literal
			if (fd.isNested())
			{
				type = new TypeDelegate(fd.type);
				type = type.semantic(loc, sc);
			}
			else
			{
				type = fd.type.pointerTo();
			}

			fd.tookAddressOf++;
		}

		return this;
	}
	
    override Expression interpret(InterState istate)
	{
version (LOG) {
		writef("FuncExp::interpret() %s\n", toChars());
}
		return this;

	}

	override void scanForNestedRef(Scope sc)
	{
		//printf("FuncExp.scanForNestedRef(%s)\n", toChars());
		//fd.parent = sc.parent;
	}

	override string toChars()
	{
		return fd.toChars();
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		fd.toCBuffer(buf, hgs);
		//buf.writestring(fd.toChars());
	}

	override elem* toElem(IRState* irs)
	{
		elem* e;
		Symbol* s;

		//printf("FuncExp::toElem() %s\n", toChars());
		s = fd.toSymbol();
		e = el_ptr(s);
		if (fd.isNested())
		{
			elem* ethis = getEthis(loc, irs, fd);
			e = el_pair(TYM.TYullong, ethis, e);
		}

		irs.deferToObj.push(cast(void*)fd);
		el_setLoc(e,loc);
		return e;
	}

	override int inlineCost(InlineCostState* ics)
	{
		// Right now, this makes the function be output to the .obj file twice.
		return COST_MAX;
	}
}

