module dmd.TypeExp;

import dmd.common;
import dmd.Expression;
import dmd.backend.TYM;
import dmd.backend.Util;
import dmd.backend.elem;
import dmd.Type;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.IRState;
import dmd.HdrGenState;
import dmd.TOK;

import dmd.DDMDExtensions;

class TypeExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	this(Loc loc, Type type)
	{
		register();
		super(loc, TOK.TOKtype, TypeExp.sizeof);
		//printf("TypeExp::TypeExp(%s)\n", type->toChars());
		this.type = type;
	}

	override Expression syntaxCopy()
	{
		//printf("TypeExp.syntaxCopy()\n");
		return new TypeExp(loc, type.syntaxCopy());
	}

	override Expression semantic(Scope sc)
	{
		//printf("TypeExp::semantic(%s)\n", type->toChars());
		type = type.semantic(loc, sc);
		return this;
	}

	override void rvalue()
	{
		error("type %s has no value", toChars());
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		type.toCBuffer(buf, null, hgs);
	}

	override Expression optimize(int result)
	{
		return this;
	}

	override elem* toElem(IRState* irs)
	{
		debug
			writef("TypeExp.toElem()\n");

		error("type %s is not an expression", toChars());
		return el_long(TYint, 0);
	}
}

