module dmd.TypeDArray;

import dmd.common;
import dmd.TypeArray;
import dmd.MOD;
import dmd.Id;
import dmd.TOK;
import dmd.StringExp;
import dmd.IntegerExp;
import dmd.ArrayLengthExp;
import dmd.Type;
import dmd.Loc;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.Identifier;
import dmd.MATCH;
import dmd.ArrayTypes;
import dmd.TypeInfoDeclaration;
import dmd.TypeInfoArrayDeclaration;
import dmd.NullExp;
import dmd.TY;
import dmd.TypeStruct;
import dmd.Util;
import dmd.TypePointer;
import dmd.Global;

import dmd.backend.TYPE;
import dmd.backend.Symbol;
import dmd.backend.Classsym;
import dmd.backend.Util;
import dmd.backend.SC;
import dmd.backend.TYM;
import dmd.backend.LIST;

import core.stdc.stdlib;
import core.stdc.stdio;
version (Bug4054) import core.memory;

import dmd.DDMDExtensions;

// Dynamic array, no dimension
class TypeDArray : TypeArray
{
	mixin insertMemberExtension!(typeof(this));

    this(Type t)
	{
		register();
		super(TY.Tarray, t);
		//printf("TypeDArray(t = %p)\n", t);
	}
	
    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		if (t == next)
			t = this;
		else
		{	
			t = new TypeDArray(t);
			t.mod = mod;
		}
		return t;
	}
	
    override ulong size(Loc loc)
	{
		//printf("TypeDArray.size()\n");
		return PTRSIZE * 2;
	}
	
    override uint alignsize()
	{
		// A DArray consists of two ptr-sized values, so align it on pointer size
		// boundary
		return PTRSIZE;
	}
	
    override Type semantic(Loc loc, Scope sc)
	{
		Type tn = next;

		tn = next.semantic(loc,sc);
		Type tbn = tn.toBasetype();
		switch (tbn.ty)
		{
			case TY.Tfunction:
			case TY.Tnone:
			case TY.Ttuple:
				error(loc, "can't have array of %s", tbn.toChars());
				tn = next = tint32;
				break;
			case TY.Tstruct:
			{   
				TypeStruct ts = cast(TypeStruct)tbn;
				if (ts.sym.isnested)
					error(loc, "cannot have array of inner structs %s", ts.toChars());
				break;
			}
			
			default:
				break;	///
		}
		if (tn.isauto())
			error(loc, "cannot have array of auto %s", tn.toChars());

		next = tn;
		transitive();
		return merge();
	}
	
    override void toDecoBuffer(OutBuffer buf, int flag)
	{
		Type.toDecoBuffer(buf, flag);
		if (next)
			next.toDecoBuffer(buf, (flag & 0x100) ? 0 : mod);
	}
	
	override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		if (mod != this.mod)
		{
			toCBuffer3(buf, hgs, mod);
			return;
		}
		if (equals(global.tstring))
			buf.writestring("string");
		else
		{
			next.toCBuffer2(buf, hgs, this.mod);
			buf.writestring("[]");
		}
	}
	
    override Expression dotExp(Scope sc, Expression e, Identifier ident)
	{
version (LOGDOTEXP) {
		printf("TypeDArray.dotExp(e = '%s', ident = '%s')\n", e.toChars(), ident.toChars());
}
		if (ident is Id.length)
		{
			if (e.op == TOK.TOKstring)
			{   
				StringExp se = cast(StringExp)e;

				return new IntegerExp(se.loc, se.len, Type.tindex);
			}
			e = new ArrayLengthExp(e.loc, e);
			e.type = Type.tsize_t;
			return e;
		}
		else if (ident is Id.ptr)
		{
			e = e.castTo(sc, next.pointerTo());
			return e;
		}
		else
		{
			e = TypeArray.dotExp(sc, e, ident);
		}
		return e;
	}
	
    override bool isString()
	{
		TY nty = next.toBasetype().ty;
		return nty == Tchar || nty == Twchar || nty == Tdchar;
	}
	
    override bool isZeroInit(Loc loc)
	{
		return true;
	}
	
    override bool checkBoolean()
	{
		return true;
	}
	
    override MATCH implicitConvTo(Type to)
	{
		//printf("TypeDArray.implicitConvTo(to = %s) this = %s\n", to.toChars(), toChars());
		if (equals(to))
			return MATCHexact;

		// Allow implicit conversion of array to pointer
		if (IMPLICIT_ARRAY_TO_PTR && to.ty == Tpointer)
		{
			TypePointer tp = cast(TypePointer)to;

			/* Allow conversion to void*
			 */
			if (tp.next.ty == Tvoid &&
				MODimplicitConv(next.mod, tp.next.mod))
			{
				return MATCHconvert;
			}

			return next.constConv(to);
		}

		if (to.ty == Tarray)
		{	
			int offset = 0;
			TypeDArray ta = cast(TypeDArray)to;

			if (!MODimplicitConv(next.mod, ta.next.mod))
				return MATCHnomatch;	// not const-compatible

			/* Allow conversion to void[]
			 */
			if (next.ty != Tvoid && ta.next.ty == Tvoid)
			{
				return MATCHconvert;
			}

			MATCH m = next.constConv(ta.next);
			if (m != MATCHnomatch)
			{
				if (m == MATCHexact && mod != to.mod)
				m = MATCHconst;
				return m;
			}

static if(false) {
			/* Allow conversions of T[][] to const(T)[][]
			 */
			if (mod == ta.mod && next.ty == Tarray && ta.next.ty == Tarray)
			{
				m = next.implicitConvTo(ta.next);
				if (m == MATCHconst)
				return m;
			}
}
			/* Conversion of array of derived to array of base
			 */
			if (ta.next.isBaseOf(next, &offset) && offset == 0)
				return MATCHconvert;
		}
		return Type.implicitConvTo(to);
	}
	
    override Expression defaultInit(Loc loc)
	{
	version (LOGDEFAULTINIT) {
		printf("TypeDArray.defaultInit() '%s'\n", toChars());
	}
		return new NullExp(loc, this);
	}
	
    override bool builtinTypeInfo()
	{
	version (DMDV2) {
		return !mod && (next.isTypeBasic() !is null && !next.mod ||
			// strings are so common, make them builtin
			next.ty == Tchar && next.mod == MODimmutable);
	} else {
		return next.isTypeBasic() !is null;
	}
	}
version (DMDV2) {
    override MATCH deduceType(Scope sc, Type tparam, TemplateParameters parameters, Objects dedtypes)
	{
	static if (false) {
		printf("TypeDArray.deduceType()\n");
		printf("\tthis   = %d, ", ty); print();
		printf("\ttparam = %d, ", tparam.ty); tparam.print();
	}
		return Type.deduceType(sc, tparam, parameters, dedtypes);

	  Lnomatch:
		return MATCHnomatch;
	}
}
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoArrayDeclaration(this);
	}

    override bool hasPointers()
	{
		return true;
	}

version (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState* cms)
	{
		assert(false);
	}
}

    override type* toCtype()
	{
		type *t;

		if (ctype)
			return ctype;

		if (0 && global.params.symdebug)
		{
			/* Create a C type out of:
			 *	struct _Array_T { size_t length; T* data; }
			 */
			Symbol* s;
			char *id;

			assert(next.deco);
			version (Bug4054)
			id = cast(char*) GC.malloc(7 + next.deco.length + 1);
			else
			id = cast(char*) alloca(7 + next.deco.length + 1);
			sprintf(id, "_Array_%.*s", next.deco);
			s = symbol_calloc(id);
			s.Sclass = SC.SCstruct;
			s.Sstruct = struct_calloc();
			s.Sstruct.Sflags |= 0;
			s.Sstruct.Salignsize = alignsize();
			s.Sstruct.Sstructalign = cast(ubyte)global.structalign;
			s.Sstruct.Sstructsize = cast(uint)size(Loc(0));
			slist_add(s);

			Symbol* s1 = symbol_name("length", SC.SCmember, Type.tsize_t.toCtype());
			list_append(&s.Sstruct.Sfldlst, s1);

			Symbol* s2 = symbol_name("data", SC.SCmember, next.pointerTo().toCtype());
			s2.Smemoff = cast(uint)Type.tsize_t.size();
			list_append(&s.Sstruct.Sfldlst, s2);

			t = type_alloc(TYM.TYstruct);
			t.Ttag = cast(Classsym*)s;		// structure tag name
			t.Tcount++;
			s.Stype = t;
		}
		else
		{
			if (global.params.symdebug == 1)
			{
				// Generate D symbolic debug info, rather than C
				t = type_allocn(TYM.TYdarray, next.toCtype());
			}
			else
				t = type_fake(TYM.TYdarray);
		}
		t.Tcount++;
		ctype = t;
		return t;
	}
}
