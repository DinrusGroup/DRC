module dmd.StructInitializer;

import dmd.common;
import dmd.Initializer;
import dmd.TOK;
import dmd.TypeSArray;
import dmd.FuncLiteralDeclaration;
import dmd.TypeFunction;
import dmd.StructDeclaration;
import dmd.StructLiteralExp;
import dmd.ArrayTypes;
import dmd.Array;
import dmd.Loc;
import dmd.Type;
import dmd.Scope;
import dmd.Identifier;
import dmd.CompoundStatement;
import dmd.AggregateDeclaration;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.TypeStruct;
import dmd.TY;
import dmd.VarDeclaration;
import dmd.Dsymbol;
import dmd.Util;
import dmd.ExpInitializer;
import dmd.FuncExp;
import dmd.LINK;

import dmd.backend.dt_t;
import dmd.backend.Util;

import dmd.DDMDExtensions;

class StructInitializer : Initializer
{
	mixin insertMemberExtension!(typeof(this));

    Identifiers field;	// of Identifier *'s
    Initializers value;	// parallel array of Initializer *'s

    VarDeclarations vars;		// parallel array of VarDeclaration *'s
    AggregateDeclaration ad;	// which aggregate this is for

    this(Loc loc)
	{
		register();
		super(loc);
		ad = null;
		
		field = new Identifiers();
		value = new Initializers();
		
		vars = new VarDeclarations();
	}
	
    override Initializer syntaxCopy()
	{
		auto ai = new StructInitializer(loc);

		assert(field.dim == value.dim);
		ai.field.setDim(field.dim);
		ai.value.setDim(value.dim);
		for (int i = 0; i < field.dim; i++)
		{    
			ai.field[i] = field[i];

			auto init = value[i];
			init = init.syntaxCopy();
			ai.value[i] = init;
		}

		return ai;
	}
	
    void addInit(Identifier field, Initializer value)
	{
		//printf("StructInitializer.addInit(field = %p, value = %p)\n", field, value);
		this.field.push(field);
		this.value.push(value);
	}
	
    override Initializer semantic(Scope sc, Type t)
	{
		int errors = 0;

		//printf("StructInitializer.semantic(t = %s) %s\n", t.toChars(), toChars());
		vars.setDim(field.dim);
		t = t.toBasetype();
		if (t.ty == Tstruct)
		{	
			uint fieldi = 0;

			auto ts = cast(TypeStruct)t;
			ad = ts.sym;
	        if (ad.ctor)
	            error("%s %s has constructors, cannot use { initializers }, use %s( initializers ) instead",
		        ad.kind(), ad.toChars(), ad.toChars());
			for (size_t i = 0; i < field.dim; i++)
			{
				Identifier id = field[i];
				Initializer val = value[i];
				Dsymbol s;
				VarDeclaration v;

				if (id is null)
				{
					if (fieldi >= ad.fields.dim)
					{   
						error(loc, "too many initializers for %s", ad.toChars());
						field.remove(i);
						i--;
						continue;
					}
					else
					{
						s = ad.fields[fieldi];
					}
				}
				else
				{
					//s = ad.symtab.lookup(id);
					s = ad.search(loc, id, 0);
					if (!s)
					{
						error(loc, "'%s' is not a member of '%s'", id.toChars(), t.toChars());
						continue;
					}

					// Find out which field index it is
					for (fieldi = 0; 1; fieldi++)
					{
						if (fieldi >= ad.fields.dim)
						{
							s.error("is not a per-instance initializable field");
							break;
						}
						if (s == ad.fields[fieldi])
							break;
					}
				}
				if (s && (v = s.isVarDeclaration()) !is null)
				{
					val = val.semantic(sc, v.type);
					value[i] = val;
					vars[i] = v;
				}
				else
				{
					error(loc, "%s is not a field of %s", id ? id.toChars() : s.toChars(), ad.toChars());
					errors = 1;
				}
				fieldi++;
			}
		}
		else if (t.ty == Tdelegate && value.dim == 0)
		{	
			/* Rewrite as empty delegate literal { }
			 */
			auto arguments = new Parameters;
			Type tf = new TypeFunction(arguments, null, 0, LINK.LINKd);
			FuncLiteralDeclaration fd = new FuncLiteralDeclaration(loc, Loc(0), tf, TOK.TOKdelegate, null);
			fd.fbody = new CompoundStatement(loc, new Statements());
			fd.endloc = loc;
			Expression e = new FuncExp(loc, fd);
			ExpInitializer ie = new ExpInitializer(loc, e);
			return ie.semantic(sc, t);
		}
		else
		{
			error(loc, "a struct is not a valid initializer for a %s", t.toChars());
			errors = 1;
		}
		if (errors)
		{
			field.setDim(0);
			value.setDim(0);
			vars.setDim(0);
		}
		return this;
	}
	
	/***************************************
	 * This works by transforming a struct initializer into
	 * a struct literal. In the future, the two should be the
	 * same thing.
	 */
    override Expression toExpression()
	{
		Expression e;

		//printf("StructInitializer.toExpression() %s\n", toChars());
		if (!ad)				// if fwd referenced
		{
			return null;
		}
		StructDeclaration sd = ad.isStructDeclaration();
		if (!sd)
			return null;
		Expressions elements = new Expressions();
		for (size_t i = 0; i < value.dim; i++)
		{
			if (field[i])
				goto Lno;
			Initializer iz = value[i];
			if (!iz)
				goto Lno;
			Expression ex = iz.toExpression();
			if (!ex)
				goto Lno;
			elements.push(ex);
		}
		e = new StructLiteralExp(loc, sd, elements);
		e.type = sd.type;
		return e;

	Lno:
		delete elements;
		//error(loc, "struct initializers as expressions are not allowed");
		return null;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		assert(false);
	}

    override dt_t* toDt()
	{
		scope dts = new Vector!(dt_t*);
		uint i;
		uint j;
		dt_t* dt;
		dt_t* d;
		dt_t** pdtend;
		uint offset;

		//printf("StructInitializer.toDt('%s')\n", toChars());
		dts.setDim(ad.fields.dim);
		dts.zero();

		for (i = 0; i < vars.dim; i++)
		{
			VarDeclaration v = vars[i];
			Initializer val = value[i];

			//printf("vars[%d] = %s\n", i, v.toChars());

			for (j = 0; 1; j++)
			{
				assert(j < dts.dim);
				//printf(" adfield[%d] = %s\n", j, ((VarDeclaration *)ad.fields[j]).toChars());
				if (cast(VarDeclaration)ad.fields[j] == v) // TODO: check if 'is' needs to be used here
				{
					if (dts[j])
						error(loc, "field %s of %s already initialized", v.toChars(), ad.toChars());
					dts[j] = val.toDt();
					break;
				}
			}
		}

		dt = null;
		pdtend = &dt;
		offset = 0;
		for (j = 0; j < dts.dim; j++)
		{
			VarDeclaration v = ad.fields[j];

			d = dts[j];
			if (!d)
			{   
				// An instance specific initializer was not provided.
				// Look to see if there's a default initializer from the
				// struct definition
				if (v.init)
				{
					d = v.init.toDt();
				}
				else if (v.offset >= offset)
				{
					uint k;
					uint offset2 = v.offset + cast(uint)v.type.size();
					// Make sure this field does not overlap any explicitly
					// initialized field.
					for (k = j + 1; 1; k++)
					{
						if (k == dts.dim)		// didn't find any overlap
						{
							v.type.toDt(&d);
							break;
						}
						VarDeclaration v2 = ad.fields[k];

						if (v2.offset < offset2 && dts[k])
							break;			// overlap
					}
				}
			}
			if (d)
			{
				if (v.offset < offset)
					error(loc, "duplicate union initialization for %s", v.toChars());
				else
				{	
					uint sz = dt_size(d);
					uint vsz = cast(uint)v.type.size();
					uint voffset = v.offset;

					uint dim = 1;
					for (Type vt = v.type.toBasetype();
						 vt.ty == Tsarray;
						 vt = vt.nextOf().toBasetype())
					{   
						TypeSArray tsa = cast(TypeSArray)vt;
						dim *= tsa.dim.toInteger();
					}
					assert(sz == vsz || sz * dim <= vsz);

					for (size_t k = 0; k < dim; k++)
					{
						if (offset < voffset)
							pdtend = dtnzeros(pdtend, voffset - offset);
						if (!d)
						{
							if (v.init)
								d = v.init.toDt();
							else
								v.type.toDt(&d);
						}
						pdtend = dtcat(pdtend, d);
						d = null;
						offset = voffset + sz;
						voffset += vsz / dim;
						if (sz == vsz)
							break;
					}
				}
			}
		}
		
		if (offset < ad.structsize)
			dtnzeros(pdtend, ad.structsize - offset);

		return dt;
	}

    override StructInitializer isStructInitializer() { return this; }
}
