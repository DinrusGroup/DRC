module dmd.ArrayInitializer;

import dmd.common;
import dmd.ArrayTypes;
import dmd.Type;
import dmd.TypeAArray;
import dmd.TypeNext;
import dmd.Array;
import dmd.Loc;
import dmd.Initializer;
import dmd.WANT;
import dmd.Util;
import dmd.TY;
import dmd.TypeSArray;
import dmd.IntegerExp;
import dmd.Expression;
import dmd.ArrayLiteralExp;
import dmd.AssocArrayLiteralExp;
import dmd.Scope;
import dmd.ErrorExp;
import dmd.OutBuffer;
import dmd.HdrGenState;

import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.codegen.Util;
import dmd.backend.TYM;
import dmd.backend.Symbol;

import dmd.DDMDExtensions;

class ArrayInitializer : Initializer
{
	mixin insertMemberExtension!(typeof(this));

    Expressions index;	// indices
    Initializers value;	// of Initializer *'s
    uint dim = 0;		// length of array being initialized
    Type type = null;	// type that array will be used to initialize
    int sem = 0;		// !=0 if semantic() is run

    this(Loc loc)
	{
		register();
		super(loc);
		index = new Expressions();
		value = new Initializers();
	}
	
    override Initializer syntaxCopy()
	{
		//printf("ArrayInitializer.syntaxCopy()\n");

		ArrayInitializer ai = new ArrayInitializer(loc);

		assert(index.dim == value.dim);
		ai.index.setDim(index.dim);
		ai.value.setDim(value.dim);
		for (int i = 0; i < ai.value.dim; i++)
		{	
			Expression e = index[i];
			if (e)
				e = e.syntaxCopy();
			ai.index[i] = e;

			auto init = value[i];
			init = init.syntaxCopy();
			ai.value[i] = init;
		}
		return ai;
	}
	
    void addInit(Expression index, Initializer value)
	{
		this.index.push(index);
		this.value.push(value);
		dim = 0;
		type = null;
	}
	
    override Initializer semantic(Scope sc, Type t)
	{
		uint length;

		//printf("ArrayInitializer.semantic(%s)\n", t.toChars());
		if (sem)				// if semantic() already run
			return this;

		sem = 1;
		type = t;
		t = t.toBasetype();
		switch (t.ty)
		{
			case Tpointer:
			case Tsarray:
			case Tarray:
				break;

			default:
				error(loc, "cannot use array to initialize %s", type.toChars());
				return this;
		}

		length = 0;
		foreach (size_t i, Expression idx; index)
		{	
			if (idx)
			{   
				idx = idx.semantic(sc);
				idx = idx.optimize(WANTvalue | WANTinterpret);
				index[i] = idx;
				length = cast(uint)idx.toInteger();
			}

			Initializer val = value[i];
			val = val.semantic(sc, t.nextOf());
			value[i] = val;
			length++;
			if (length == 0)
				error(loc, "array dimension overflow");
			if (length > dim)
				dim = length;
		}
		uint amax = 0x80000000;
		if (cast(uint) (dim * t.nextOf().size()) >= amax)
			error(loc, "array dimension %u exceeds max of %ju", dim, amax / t.nextOf().size());

		return this;
	}
	
    int isAssociativeArray()
    {
        for (size_t i = 0; i < value.dim; i++)
        {
	        if (index[i])
	            return 1;
        }
        return 0;
    }
    
    override Type inferType(Scope sc)
	{
		//printf("ArrayInitializer.inferType() %s\n", toChars());
        assert(0);
        return null;
static if (false) {
		type = Type.terror;
		for (size_t i = 0; i < value.dim; i++)
		{
			if (index[i])
				goto Laa;
		}

		foreach (size_t i, Initializer iz; value)
		{
			if (iz)
			{   
				Type t = iz.inferType(sc);
				if (i == 0)
				{	/* BUG: This gets the type from the first element.
        		 * Fix to use all the elements to figure out the type.
	        	 */	
					t = new TypeSArray(t, new IntegerExp(value.dim));
					t = t.semantic(loc, sc);
					type = t;
				}
			}
		}
		return type;

	Laa:
        /* It's possibly an associative array initializer.
         * BUG: inferring type from first member.
         */
	    Initializer iz = value[0];
	    Expression indexinit = index[0];
	    if (iz && indexinit)
		{
			Type t = iz.inferType(sc);
			indexinit = indexinit.semantic(sc);
			Type indext = indexinit.type;
			t = new TypeAArray(t, indext);
			type = t.semantic(loc, sc);
		}
		else
			error(loc, "cannot infer type from this array initializer");
		return type;
}
	}

	/********************************
	 * If possible, convert array initializer to array literal.
	  * Otherwise return null.
	 */	
    override Expression toExpression()
	{
		Expression e;

		//printf("ArrayInitializer.toExpression(), dim = %d\n", dim);
		//static int i; if (++i == 2) halt();

		size_t edim;
		Type t = null;
		if (type)
		{
			if (type == Type.terror)
			    return new ErrorExp();

			t = type.toBasetype();
			switch (t.ty)
			{
				case Tsarray:
					edim = cast(uint)(cast(TypeSArray)t).dim.toInteger();
					break;

				case Tpointer:
				case Tarray:
					edim = dim;
					break;

				default:
					assert(0);
			}
		}
		else
		{
			edim = value.dim;
			for (size_t i = 0, j = 0; i < value.dim; i++, j++)
			{
				if (index[i])
					j = cast(uint)(index[i].toInteger());
				if (j >= edim)
					edim = j + 1;
			}
		}

		auto elements = new Expressions();
		elements.setDim(edim);
		for (size_t i = 0, j = 0; i < value.dim; i++, j++)
		{
			if (index[i])
				j = cast(uint)(index[i].toInteger());
			assert(j < edim);
			Initializer iz = value[i];
			if (!iz)
				goto Lno;
			Expression ex = iz.toExpression();
			if (!ex)
			{
				goto Lno;
			}
			elements[j] = ex;
		}

		/* Fill in any missing elements with the default initializer
		 */
		{
			Expression init = null;
			for (size_t i = 0; i < edim; i++)
			{
				if (!elements[i])
				{
					if (!type)
						goto Lno;
					if (!init)
						init = (cast(TypeNext)t).next.defaultInit(Loc(0));
					elements[i] = init;
				}
			}

			Expression e2 = new ArrayLiteralExp(loc, elements);
			e2.type = type;
			return e2;
		}

	Lno:
	    return null;
	}

	/********************************
	 * If possible, convert array initializer to associative array initializer.
	 */
	Expression toAssocArrayLiteral()
	{
		Expression e;

		// writef("ArrayInitializer::toAssocArrayInitializer()\n");
		// static int i; if (++i == 2) halt();
		Expressions keys = new Expressions();
		keys.setDim(value.dim);
		Expressions values = new Expressions();
		values.setDim(value.dim);

		foreach (size_t i, Initializer iz; value)
		{
			e = index[i];
			if (!e)
				goto Lno;
			keys[i] = e;

			if (!iz)
				goto Lno;
			e = iz.toExpression();
			if (!e)
				goto Lno;
			values[i] = e;
		}
		e = new AssocArrayLiteralExp(loc, keys, values);
		return e;

	Lno:
		delete keys;
		delete values;
		error(loc, "not an associative array initializer");
		return new ErrorExp();
	}
	
	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

    override dt_t* toDt()
	{
		//printf("ArrayInitializer.toDt('%s')\n", toChars());
		Type tb = type.toBasetype();
		Type tn = tb.nextOf().toBasetype();

		scope dts = new Vector!(dt_t*)();
		uint size;
		uint length_;
		uint i;
		dt_t* dt;
		dt_t* d;
		dt_t** pdtend;

		//printf("\tdim = %d\n", dim);
		dts.setDim(dim);
		dts.zero();

		size = cast(uint)tn.size();

		length_ = 0;
		for (i = 0; i < index.dim; i++)
		{
			Expression idx;
			Initializer val;

			idx = index[i];
			if (idx)
				length_ = cast(uint)idx.toInteger();
			//printf("\tindex[%d] = %p, length_ = %u, dim = %u\n", i, idx, length_, dim);

			assert(length_ < dim);
			val = value[i];
			dt = val.toDt();
			if (dts[length_])
				error(loc, "duplicate initializations for index %d", length_);
			dts[length_] = dt;
			length_++;
		}

		Expression edefault = tb.nextOf().defaultInit(Loc(0));

		uint n = 1;
		for (Type tbn = tn; tbn.ty == Tsarray; tbn = tbn.nextOf().toBasetype())
		{	
			TypeSArray tsa = cast(TypeSArray)tbn;
			n *= tsa.dim.toInteger();
		}

		d = null;
		pdtend = &d;
		for (i = 0; i < dim; i++)
		{
			dt = dts[i];
			if (dt)
				pdtend = dtcat(pdtend, dt);
			else
			{
				for (int j = 0; j < n; j++)
					pdtend = edefault.toDt(pdtend);
			}
		}
		switch (tb.ty)
		{
			case Tsarray:
			{   
				uint tadim;
				TypeSArray ta = cast(TypeSArray)tb;

				tadim = cast(uint)ta.dim.toInteger();
				if (dim < tadim)
				{
					if (edefault.isBool(false))
						// pad out end of array
						pdtend = dtnzeros(pdtend, size * (tadim - dim));
					else
					{
						for (i = dim; i < tadim; i++)
						{	
							for (int j = 0; j < n; j++)
								pdtend = edefault.toDt(pdtend);
						}
					}
				}
				else if (dim > tadim)
				{
					debug writef("1: ");
					error(loc, "too many initializers, %d, for array[%d]", dim, tadim);
				}
				break;
			}

			case Tpointer:
			case Tarray:
				// Create symbol, and then refer to it
				Symbol* s = static_sym();
				s.Sdt = d;
				outdata(s);

				d = null;
				if (tb.ty == Tarray)
					dtdword(&d, dim);
				dtxoff(&d, s, 0, TYnptr);
				break;

			default:
				assert(0);
		}
		return d;
	}
	
    dt_t* toDtBit()	// for bit arrays
	{
		assert(false);
	}

    override ArrayInitializer isArrayInitializer() { return this; }
}
