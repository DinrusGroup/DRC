module dmd.TypeTuple;

import dmd.common;
import dmd.Type;
import dmd.ArrayTypes;
import dmd.MOD;
import dmd.TypeInfoTupleDeclaration;
import dmd.TypeInfoDeclaration;
import dmd.Expression;
import dmd.Loc;
import dmd.Identifier;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Scope;
import dmd.TY;
import dmd.Id;
import dmd.STC;
import dmd.Parameter;
import dmd.ErrorExp;
import dmd.IntegerExp;

import dmd.DDMDExtensions;

class TypeTuple : Type
{
	mixin insertMemberExtension!(typeof(this));

	Parameters arguments;	// types making up the tuple

	this(Parameters arguments)
	{
		register();
		super(TY.Ttuple);
		//printf("TypeTuple(this = %p)\n", this);
		this.arguments = arguments;
		//printf("TypeTuple() %p, %s\n", this, toChars());
		debug {
			if (arguments)
			{
				foreach (arg; arguments)
				{
					assert(arg && arg.type);
				}
			}
		}
	}

	/****************
	 * Form TypeTuple from the types of the expressions.
	 * Assume exps[] is already tuple expanded.
	 */
	this(Expressions exps)
	{
		register();
		super(TY.Ttuple);
		auto arguments = new Parameters;
		if (exps)
		{
			arguments.setDim(exps.dim);
			for (size_t i = 0; i < exps.dim; i++)
			{   auto e = exps[i];
				if (e.type.ty == Ttuple)
					e.error("cannot form tuple of tuples");
				auto arg = new Parameter(STCundefined, e.type, null, null);
				arguments[i] = arg;
			}
		}
		this.arguments = arguments;
        //printf("TypeTuple() %p, %s\n", this, toChars());
	}

	override Type syntaxCopy()
	{
		auto args = Parameter.arraySyntaxCopy(arguments);
		auto t = new TypeTuple(args);
		t.mod = mod;
		return t;
	}

	override Type semantic(Loc loc, Scope sc)
	{
		//printf("TypeTuple::semantic(this = %p)\n", this);
		//printf("TypeTuple::semantic() %p, %s\n", this, toChars());
		if (!deco)
			deco = merge().deco;

		/* Don't return merge(), because a tuple with one type has the
		 * same deco as that type.
		 */
		return this;
	}

	override bool equals(Object o)
	{
		Type t;

		t = cast(Type)o;
		//printf("TypeTuple::equals(%s, %s)\n", toChars(), t-cast>toChars());
		if (this == t)
		{
			return 1;
		}
		if (t.ty == Ttuple)
		{	auto tt = cast(TypeTuple)t;

			if (arguments.dim == tt.arguments.dim)
			{
				for (size_t i = 0; i < tt.arguments.dim; i++)
				{   auto arg1 = arguments[i];
					auto arg2 = tt.arguments[i];

					if (!arg1.type.equals(arg2.type))
						return 0;
				}
				return 1;
			}
		}
		return 0;
	}

	override Type reliesOnTident()
	{
		if (arguments)
		{
			foreach (arg; arguments)
			{
				auto t = arg.type.reliesOnTident();
				if (t)
					return t;
			}
		}
		return null;
	}

	override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		Parameter.argsToCBuffer(buf, hgs, arguments, 0);
	}

	override void toDecoBuffer(OutBuffer buf, int flag)
	{
		//printf("TypeTuple::toDecoBuffer() this = %p, %s\n", this, toChars());
		Type.toDecoBuffer(buf, flag);
		OutBuffer buf2 = new OutBuffer();
		Parameter.argsToDecoBuffer(buf2, arguments);
		uint len = buf2.offset;
		//buf.printf("%d%.*s", len, len, cast(char *)buf2.extractData());
		buf.printf("%d%s", len, buf2.extractString());
	}

	override Expression getProperty(Loc loc, Identifier ident)
	{
		Expression e;

		version (LOGDOTEXP) {
			printf("TypeTuple::getProperty(type = '%s', ident = '%s')\n", toChars(), ident.toChars());
		}
		if (ident == Id.length)
		{
			e = new IntegerExp(loc, arguments.dim, Type.tsize_t);
		}
		else
		{
			error(loc, "no property '%s' for tuple '%s'", ident.toChars(), toChars());
			e = new ErrorExp();
		}
		return e;
	}

	override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoTupleDeclaration(this);
	}
}
