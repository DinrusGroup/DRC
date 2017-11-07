module dmd.Initializer;

import dmd.common;
import dmd.Loc;
import dmd.Scope;
import dmd.Type;
import dmd.Util;
import dmd.ArrayTypes;
import dmd.Expression;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.VoidInitializer;
import dmd.StructInitializer;
import dmd.ArrayInitializer;
import dmd.ExpInitializer;

import dmd.backend.dt_t;

import dmd.TObject;

import dmd.DDMDExtensions;

class Initializer : TObject
{
	mixin insertMemberExtension!(typeof(this));

    Loc loc;

    this(Loc loc)
	{
		register();
		this.loc = loc;
	}
	
    Initializer syntaxCopy()
	{
		return this;
	}
	
    Initializer semantic(Scope sc, Type t)
	{
		return this;
	}
	
    Type inferType(Scope sc)
	{
    	error(loc, "cannot infer type from initializer");
    	return Type.terror;
	}
	
	abstract Expression toExpression();
	
	abstract void toCBuffer(OutBuffer buf, HdrGenState* hgs);
	
	string toChars()
	{
		OutBuffer buf;
		HdrGenState hgs;

		buf = new OutBuffer();
		toCBuffer(buf, &hgs);
		return buf.toChars();
	}

    static Initializers arraySyntaxCopy(Initializers ai)
	{
		 Initializers a = null;

			if (ai)
			{
			a = new Initializers();
			a.setDim(ai.dim);
			for (int i = 0; i < a.dim; i++)
			{   Initializer e = ai[i];

				e = e.syntaxCopy();
				a[i] =  e;
			}
			}
			return a;
	}

	dt_t* toDt()
	{
		assert(false);
	}

	VoidInitializer isVoidInitializer() { return null; }
	
    StructInitializer isStructInitializer()  { return null; }
    
	ArrayInitializer isArrayInitializer()  { return null; }
    
	ExpInitializer isExpInitializer()  { return null; }
}