module dmd.EnumMember;

import dmd.common;
import dmd.Dsymbol;
import dmd.Expression;
import dmd.Type;
import dmd.Loc;
import dmd.Identifier;
import dmd.Json;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;

import dmd.DDMDExtensions;

class EnumMember : Dsymbol
{
	mixin insertMemberExtension!(typeof(this));

	Expression value;
	Type type;

	this(Loc loc, Identifier id, Expression value, Type type)
	{
		register();
		super(id);

		this.value = value;
		this.type = type;
		this.loc = loc;
	}

	override Dsymbol syntaxCopy(Dsymbol s)
	{
		Expression e = null;
		if (value)
			e = value.syntaxCopy();

		Type t = null;
		if (type)
			t = type.syntaxCopy();

		EnumMember em;
		if (s)
		{	em = cast(EnumMember)s;
			em.loc = loc;
			em.value = e;
			em.type = t;
		}
		else
			em = new EnumMember(loc, ident, e, t);
		return em;
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		if (type)
			type.toCBuffer(buf, ident, hgs);
		else
			buf.writestring(ident.toChars());
		if (value)
		{
			buf.writestring(" = ");
			value.toCBuffer(buf, hgs);
		}
	}

	override void toJsonBuffer(OutBuffer buf)
	{
		//writef("EnumMember.toJsonBuffer()\n");
		buf.writestring("{\n");

		JsonProperty(buf, Pname, toChars());
		JsonProperty(buf, Pkind, kind());

		if (comment)
			JsonProperty(buf, Pcomment, comment);

		if (loc.linnum)
			JsonProperty(buf, Pline, loc.linnum);

		JsonRemoveComma(buf);
		buf.writestring("}\n");
	}

	override string kind()
	{
		return "enum member";
	}

	override void emitComment(Scope sc)
	{
		assert(false);
	}

	override void toDocBuffer(OutBuffer buf)
	{
		assert(false);
	}

	override EnumMember isEnumMember() { return this; }
}
