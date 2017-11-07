module dmd.TypeAArray;

import dmd.common;
import dmd.TypeArray;
import dmd.MOD;
import dmd.ArrayTypes;
import dmd.TypeInfoDeclaration;
import dmd.TypeInfoAssociativeArrayDeclaration;
import dmd.Expression;
import dmd.Scope;
import dmd.StructDeclaration;
import dmd.Loc;
import dmd.DotTemplateInstanceExp;
import dmd.IdentifierExp;
import dmd.Global;
import dmd.Dsymbol;
import dmd.Type;
import dmd.TypeSArray;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Identifier;
import dmd.MATCH;
import dmd.TY;
import dmd.TemplateInstance;
import dmd.Id;
import dmd.CallExp;
import dmd.IntegerExp;
import dmd.FuncDeclaration;
import dmd.VarExp;
import dmd.TypeFunction;
import dmd.NullExp;
import dmd.Array;

import dmd.backend.Symbol;
import dmd.backend.TYPE;
import dmd.backend.Util;
import dmd.backend.SC;
import dmd.backend.LIST;
import dmd.backend.TYM;
import dmd.backend.TF;
import dmd.backend.Classsym;
import dmd.backend.mTYman;

import dmd.DDMDExtensions;

import core.stdc.stdio;
import core.stdc.stdlib;
version (Bug4054)
	import core.memory;
class TypeAArray : TypeArray
{
	mixin insertMemberExtension!(typeof(this));

    Type	index;		// key type
    Loc		loc;
    Scope	sc;
    StructDeclaration impl;	// implementation

    this(Type t, Type index)
	{
		register();
		super(Taarray, t);
		this.index = index;
	}
	
    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		Type ti = index.syntaxCopy();
		if (t == next && ti == index)
			t = this;
		else
		{	
			t = new TypeAArray(t, ti);
			t.mod = mod;
		}
		return t;
	}

    override ulong size(Loc loc)
	{
		return PTRSIZE /* * 2*/;
	}
	
    override Type semantic(Loc loc, Scope sc)
	{
		//printf("TypeAArray::semantic() %s index.ty = %d\n", toChars(), index.ty);
		this.loc = loc;
		this.sc = sc;
		if (sc)
			sc.setNoFree();
		
		// Deal with the case where we thought the index was a type, but
		// in reality it was an expression.
		if (index.ty == Tident || index.ty == Tinstance || index.ty == Tsarray)
		{
			Expression e;
			Type t;
			Dsymbol s;

			index.resolve(loc, sc, &e, &t, &s);
			if (e)
			{   // It was an expression -
				// Rewrite as a static array
				TypeSArray tsa = new TypeSArray(next, e);
				return tsa.semantic(loc,sc);
			}
			else if (t)
				index = t;
			else
			{
				index.error(loc, "index is not a type or an expression");
				return Type.terror;
			}
		}
		else
			index = index.semantic(loc,sc);

		if (index.nextOf() && !index.nextOf().isImmutable())
		{
			index = index.constOf().mutableOf();
static if (false)
{
			printf("index is %p %s\n", index, index.toChars());
			index.check();
			printf("index.mod = x%x\n", index.mod);
			printf("index.ito = x%x\n", index.ito);
			if (index.ito) {
				printf("index.ito.mod = x%x\n", index.ito.mod);
				printf("index.ito.ito = x%x\n", index.ito.ito);
			}
}
		}

		switch (index.toBasetype().ty)
		{
			case Tbool:
			case Tfunction:
			case Tvoid:
			case Tnone:
			case Ttuple:
				error(loc, "can't have associative array key of %s", index.toBasetype().toChars());
				return Type.terror;
			default:
				break;	///
		}
		next = next.semantic(loc,sc);
		transitive();

		switch (next.toBasetype().ty)
		{
			case Tfunction:
			case Tnone:
				error(loc, "can't have associative array of %s", next.toChars());
				return Type.terror;
			default:
				break;	///
		}
		if (next.isauto())
		{
			error(loc, "cannot have array of auto %s", next.toChars());
			return Type.terror;
		}
		return merge();
	}
	
	StructDeclaration getImpl()
	{
		// Do it lazily
		if (!impl)
		{
			if (!index.reliesOnTident() && !next.reliesOnTident())
			{
				/* This is really a proxy for the template instance AssocArray!(index, next)
				 * But the instantiation can fail if it is a template specialization field
				 * which has Tident's instead of real types.
				 */
				Objects tiargs = new Objects();
				tiargs.push(index);
				tiargs.push(next);

			    // Create .AssociativeArray!(index, next)
				DotTemplateInstanceExp dti = new DotTemplateInstanceExp(loc,
					new IdentifierExp(loc, Id.empty),
					Id.AssociativeArray,
					tiargs);
				dti.semantic(sc);
				TemplateInstance ti = dti.ti;
				
				ti.semantic(sc);
				ti.semantic2(sc);
				ti.semantic3(sc);
				impl = ti.toAlias().isStructDeclaration();
debug
{
				if (!impl)
				{
					Dsymbol s = ti.toAlias();
					writef("%s %s\n", s.kind(), s.toChars());
				}
}
				assert(impl);
			}
		}
		return impl;
	   	
	}
	
    override void resolve(Loc loc, Scope sc, Expression* pe, Type* pt, Dsymbol* ps)
	{
		//printf("TypeAArray.resolve() %s\n", toChars());

		// Deal with the case where we thought the index was a type, but
		// in reality it was an expression.
		if (index.ty == Tident || index.ty == Tinstance || index.ty == Tsarray)
		{
			Expression e;
			Type t;
			Dsymbol s;

			index.resolve(loc, sc, &e, &t, &s);
			if (e)
			{   // It was an expression -
				// Rewrite as a static array

				TypeSArray tsa = new TypeSArray(next, e);
				return tsa.resolve(loc, sc, pe, pt, ps);
			}
			else if (t)
				index = t;
			else
				index.error(loc, "index is not a type or an expression");
		}
		Type.resolve(loc, sc, pe, pt, ps);
	}
	
    override void toDecoBuffer(OutBuffer buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		index.toDecoBuffer(buf);
		next.toDecoBuffer(buf, (flag & 0x100) ? MOD.MODundefined : mod);
	}
	
    override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		next.toCBuffer2(buf, hgs, this.mod);
		buf.writeByte('[');
		index.toCBuffer2(buf, hgs, MODundefined);
		buf.writeByte(']');
	}
	
    override Expression dotExp(Scope sc, Expression e, Identifier ident)
	{
	version (LOGDOTEXP) {
		printf("TypeAArray.dotExp(e = '%s', ident = '%s')\n", e.toChars(), ident.toChars());
	}
static if (false)
{
		if (ident == Id.length)
		{
			Expression ec;
			FuncDeclaration fd;
			Expressions arguments;

			fd = FuncDeclaration.genCfunc(Type.tsize_t, Id.aaLen);
			ec = new VarExp(Loc(0), fd);
			arguments = new Expressions();
			arguments.push(e);
			e = new CallExp(e.loc, ec, arguments);
			e.type = (cast(TypeFunction)fd.type).next;
		}
		else if (ident == Id.keys)
		{
			Expression ec;
			FuncDeclaration fd;
			Expressions arguments;
			int size = cast(int)index.size(e.loc);

			assert(size);
			fd = FuncDeclaration.genCfunc(Type.tindex, Id.aaKeys);
			ec = new VarExp(Loc(0), fd);
			arguments = new Expressions();
			arguments.push(e);
			arguments.push(new IntegerExp(Loc(0), size, Type.tsize_t));
			e = new CallExp(e.loc, ec, arguments);
			e.type = index.arrayOf();
		}
		else if (ident == Id.values)
		{
			Expression ec;
			FuncDeclaration fd;
			Expressions arguments;

			fd = FuncDeclaration.genCfunc(Type.tindex, Id.aaValues);
			ec = new VarExp(Loc(0), fd);
			arguments = new Expressions();
			arguments.push(e);
			size_t keysize = cast(size_t)index.size(e.loc);
			keysize = (keysize + PTRSIZE - 1) & ~(PTRSIZE - 1);
			arguments.push(new IntegerExp(Loc(0), keysize, Type.tsize_t));
			arguments.push(new IntegerExp(Loc(0), next.size(e.loc), Type.tsize_t));
			e = new CallExp(e.loc, ec, arguments);
			e.type = next.arrayOf();
		}
		else if (ident == Id.rehash)
		{
			Expression ec;
			FuncDeclaration fd;
			Expressions arguments;

			fd = FuncDeclaration.genCfunc(Type.tint64, Id.aaRehash);
			ec = new VarExp(Loc(0), fd);
			arguments = new Expressions();
			arguments.push(e.addressOf(sc));
			arguments.push(index.getInternalTypeInfo(sc));
			e = new CallExp(e.loc, ec, arguments);
			e.type = this;
		}
//		else
} // of static if (false)
		{
			e.type = getImpl().type;
			e = e.type.dotExp(sc, e, ident);
			//e = Type.dotExp(sc, e, ident);
		}
		return e;
	}
	
    override Expression defaultInit(Loc loc)
	{
	version (LOGDEFAULTINIT) {
		printf("TypeAArray.defaultInit() '%s'\n", toChars());
	}
		return new NullExp(loc, this);
	}
	
    override MATCH deduceType(Scope sc, Type tparam, TemplateParameters parameters, Objects dedtypes)
	{
static if (false) {
		printf("TypeAArray.deduceType()\n");
		printf("\tthis   = %d, ", ty); print();
		printf("\ttparam = %d, ", tparam.ty); tparam.print();
}

		// Extra check that index type must match
		if (tparam && tparam.ty == Taarray)
		{
			TypeAArray tp = cast(TypeAArray)tparam;
			if (!index.deduceType(sc, tp.index, parameters, dedtypes))
			{
				return MATCHnomatch;
			}
		}
		return Type.deduceType(sc, tparam, parameters, dedtypes);
	}
	
    override bool isZeroInit(Loc loc)
	{
		return true;
	}
	
    override bool checkBoolean()
	{
		return true;
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoAssociativeArrayDeclaration(this);
	}
	
    override bool hasPointers()
	{
		return true;
	}
	
    override MATCH implicitConvTo(Type to)
	{
		//printf("TypeAArray.implicitConvTo(to = %s) this = %s\n", to.toChars(), toChars());
		if (equals(to))
			return MATCHexact;

		if (to.ty == Taarray)
		{	
			TypeAArray ta = cast(TypeAArray)to;

			if (!MODimplicitConv(next.mod, ta.next.mod))
				return MATCHnomatch;	// not const-compatible

			if (!MODimplicitConv(index.mod, ta.index.mod))
				return MATCHnomatch;	// not const-compatible

			MATCH m = next.constConv(ta.next);
			MATCH mi = index.constConv(ta.index);
			if (m != MATCHnomatch && mi != MATCHnomatch)
			{
				if (m == MATCHexact && mod != to.mod)
					m = MATCHconst;
				if (mi < m)
					m = mi;
				return m;
			}
		}
		return Type.implicitConvTo(to);
	}
	
    override MATCH constConv(Type to)
	{
		assert(false);
	}
	
version (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState* cms)
	{
		assert(false);
	}
}

    // Back end
	/********************************************
	 * Determine the right symbol to look up
	 * an associative array element.
	 * Input:
	 *	flags	0	don't add value signature
	 *		1	add value signature
	 */
    Symbol* aaGetSymbol(const(char)* func, int flags)
    in
    {
		assert(func);
		assert((flags & ~1) == 0);
    }
    out (result)
    {
		assert(result);
    }
    body
    {
		int sz;
		char* id;
		type* t;
		Symbol* s;
		int i;

		//printf("aaGetSymbol(func = '%s', flags = %d, key = %p)\n", func, flags, key);
	static if (false) {
		scope OutBuffer buf = new OutBuffer();
		key.toKeyBuffer(buf);

		sz = next.size();		// it's just data, so we only care about the size
		sz = (sz + 3) & ~3;		// reduce proliferation of library routines
		version (Bug4054)
		id = cast(char*)GC.malloc(3 + strlen(func) + buf.offset + sizeof(sz) * 3 + 1);
		else
		id = cast(char*)alloca(3 + strlen(func) + buf.offset + sizeof(sz) * 3 + 1);
		buf.writeByte(0);
		if (flags & 1)
			sprintf(id, "_aa%s%s%d", func, buf.data, sz);
		else
			sprintf(id, "_aa%s%s", func, buf.data);
	} else {
		version (Bug4054)
		id = cast(char*)GC.malloc(3 + strlen(func) + 1);
		else
		id = cast(char*)alloca(3 + strlen(func) + 1);
		sprintf(id, "_aa%s", func);
	}

		// See if symbol is already in sarray
		for (i = 0; i < global.sarray.dim; i++)
		{   
			s = cast(Symbol*)global.sarray.data[i];
			if (strcmp(id, s.Sident.ptr) == 0)
				return s;			// use existing Symbol
		}

		// Create new Symbol

		s = symbol_calloc(id);
		slist_add(s);
		s.Sclass = SCextern;
		s.Ssymnum = -1;
		symbol_func(s);

		t = type_alloc(TYnfunc);
		t.Tflags = TFprototype | TFfixed;
		t.Tmangle = mTYman_c;
		t.Tparamtypes = null;
		t.Tnext = next.toCtype();
		t.Tnext.Tcount++;
		t.Tcount++;
		s.Stype = t;

		global.sarray.push(s);			// remember it
		return s;
    }

    override type* toCtype()
	{
		type* t;

		if (ctype)
			return ctype;

		if (0 && global.params.symdebug)
		{
			/* An associative array is represented by:
			 *	struct AArray { size_t length; void* ptr; }
			 */

			auto s = global.AArray_s;
			if (!s)
			{
				global.AArray_s = s = symbol_calloc("_AArray");
				s.Sclass = SCstruct;
				s.Sstruct = struct_calloc();
				s.Sstruct.Sflags |= 0;
				s.Sstruct.Salignsize = alignsize();
				s.Sstruct.Sstructalign = cast(ubyte)global.structalign;
				s.Sstruct.Sstructsize = cast(uint)size(Loc(0));
				slist_add(s);

				Symbol* s1 = symbol_name("length", SCmember, Type.tsize_t.toCtype());
				list_append(&s.Sstruct.Sfldlst, s1);

				Symbol* s2 = symbol_name("data", SCmember, global.tvoidptr.toCtype());
				s2.Smemoff = cast(uint)Type.tsize_t.size();
				list_append(&s.Sstruct.Sfldlst, s2);
			}

			t = type_alloc(TYstruct);
			t.Ttag = cast(Classsym*)s;		// structure tag name
			t.Tcount++;
			s.Stype = t;
		}
		else
		{
		if (global.params.symdebug == 1)
		{
			/* Generate D symbolic debug info, rather than C
			 *   Tnext: element type
			 *   Tkey: key type
			 */
			t = type_allocn(TYaarray, next.toCtype());
			t.Tkey = index.toCtype();
			t.Tkey.Tcount++;
		}
		else
			t = type_fake(TYaarray);
		}
		t.Tcount++;
		ctype = t;
		return t;
	}
}
