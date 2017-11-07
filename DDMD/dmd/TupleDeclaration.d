module dmd.TupleDeclaration;

import dmd.common;
import dmd.Declaration;
import dmd.Parameter;
import dmd.ArrayTypes;
import dmd.TypeTuple;
import dmd.Loc;
import dmd.STC;
import dmd.TOK;
import dmd.Identifier;
import dmd.Dsymbol;
import dmd.Type;
import dmd.DYNCAST;
import dmd.OutBuffer;
import dmd.Expression;
import dmd.DsymbolExp;

import dmd.DDMDExtensions;

class TupleDeclaration : Declaration
{
	mixin insertMemberExtension!(typeof(this));

	Objects objects;
	int isexp;			// 1: expression tuple

	TypeTuple tupletype;	// !=NULL if this is a type tuple

	this(Loc loc, Identifier ident, Objects objects)
	{
		register();
		super(ident);
		this.type = null;
		this.objects = objects;
		this.isexp = 0;
		this.tupletype = null;
	}

	override Dsymbol syntaxCopy(Dsymbol)
	{
		assert(false);
	}

	override string kind()
	{
		return "tuple";
	}

	override Type getType()
	{
		/* If this tuple represents a type, return that type
		 */

		//printf("TupleDeclaration::getType() %s\n", toChars());
		if (isexp)
			return null;
		if (!tupletype)
		{
			/* It's only a type tuple if all the Object's are types
			 */
			foreach (o; objects)
			{   
				if (cast(Type)o is null)
				{
					//printf("\tnot[%d], %p, %d\n", i, o, o->dyncast());
					return null;
				}
			}

			/* We know it's a type tuple, so build the TypeTuple
			 */
			auto args = new Parameters();
			args.setDim(objects.dim);
			OutBuffer buf = new OutBuffer();
			bool hasdeco = 1;
			for (size_t i = 0; i < objects.dim; i++)
			{   Type t = cast(Type)objects[i];

				//printf("type = %s\n", t->toChars());
static if (false)
{
					buf.printf("_%s_%d", ident.toChars(), i);
					char *name = cast(char *)buf.extractData();
					Identifier id = new Identifier(name, TOKidentifier);
					auto arg = new Parameter(STCin, t, id, null);
} else {
					auto arg = new Parameter(STCundefined, t, null, null);
}
				args[i] = arg;
				if (!t.deco)
					hasdeco = false;
			}

			tupletype = new TypeTuple(args);
			if (hasdeco)
				return tupletype.semantic(Loc(0), null);
		}

		return tupletype;
	}

	override bool needThis()
	{
		//printf("TupleDeclaration::needThis(%s)\n", toChars());
		for (size_t i = 0; i < objects.dim; i++)
		{   
			Object o = objects[i];
			if (auto e = cast(Expression)o)
			{
				if (e.op == TOKdsymbol)
				{	
					DsymbolExp ve = cast(DsymbolExp)e;
					Declaration d = ve.s.isDeclaration();
					if (d && d.needThis())
					{
						return 1;
					}
				}
			}
		}
		return 0;
	}

	override TupleDeclaration isTupleDeclaration() { return this; }
}
