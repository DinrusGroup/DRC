module dmd.Identifier;

import dmd.common;
import dmd.TOK;
import dmd.DYNCAST;
import dmd.Lexer;
import dmd.Global;
import dmd.Id;
import dmd.OutBuffer;

import std.string;

import dmd.TObject;

class Identifier : TObject
{
    TOK value;
    string string_;

    this(string string_, TOK value)
	{
		register();
		this.string_ = string_;
		this.value = value;
	}

    bool equals(Object o)
	{
		if (this is o) {
			return true;
		}

		if (auto i = cast(Identifier)o) {
			return string_ == i.string_;
		}

		return false;
	}

    hash_t hashCode()
	{
		assert(false);
	}

    override int opCmp(Object o)
	{
		assert(false);
	}

    void print()
	{
		assert(false);
	}

    string toChars()
	{
		return string_;
	}

version (_DH) {
    char* toHChars()
	{
		assert(false);
	}
}
    string toHChars2()
	{
		string p;

		if (this == Id.ctor) p = "this";
		else if (this == Id.dtor) p = "~this";
		else if (this == Id.classInvariant) p = "invariant";
		else if (this == Id.unitTest) p = "unittest";
		else if (this == Id.dollar) p = "$";
		else if (this == Id.withSym) p = "with";
		else if (this == Id.result) p = "result";
		else if (this == Id.returnLabel) p = "return";
		else
		{
			p = toChars();
			if (p.length != 0 && p[0] == '_')
			{
				if (p.startsWith("_staticCtor"))
                    p = "static this";
				else if (p.startsWith("_staticDtor"))
                    p = "static ~this";
			}
		}

		return p;
	}

    DYNCAST dyncast()
	{
		return DYNCAST.DYNCAST_IDENTIFIER;
	}

	// BUG: these are redundant with Lexer::uniqueId()
    static Identifier generateId(string prefix)
	{
		return generateId(prefix, ++global.i);
	}

    static Identifier generateId(string prefix, size_t i)
	{
		scope OutBuffer buf = new OutBuffer();

		buf.writestring(prefix);
		buf.printf("%d", i);	///<!

		string id = buf.extractString();
		return Lexer.idPool(id);
	}
}
