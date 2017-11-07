module dmd.TypePointer;

import dmd.common;
import dmd.Type;
import dmd.Loc;
import dmd.Scope;
import dmd.TypeNext;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.MATCH;
import dmd.Expression;
import dmd.NullExp;
import dmd.TypeInfoDeclaration;
import dmd.TypeInfoPointerDeclaration;
import dmd.CppMangleState;
import dmd.TY;
import dmd.Util;
import dmd.MOD;
import dmd.Global;

import dmd.backend.TYPE;
import dmd.backend.Util;
import dmd.backend.TYM;

import dmd.DDMDExtensions;

class TypePointer : TypeNext
{
	mixin insertMemberExtension!(typeof(this));

    this(Type t)
	{
		register();
		super(TY.Tpointer, t);
	}

    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		if (t == next)
			t = this;
		else
		{	
			t = new TypePointer(t);
			t.mod = mod;
		}
		return t;
	}
	
    override Type semantic(Loc loc, Scope sc)
	{
		//printf("TypePointer.semantic()\n");
		if (deco)
			return this;
		Type n = next.semantic(loc, sc);
		switch (n.toBasetype().ty)
		{
			case TY.Ttuple:
				error(loc, "can't have pointer to %s", n.toChars());
				n = tint32;
				break;
			default:
				break;
		}
		if (n !is next)
		{
			deco = null;
		}
		next = n;
		transitive();
		return merge();
	}
	
    override ulong size(Loc loc)
	{
		return PTRSIZE;
	}
	
    override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		//printf("TypePointer::toCBuffer2() next = %d\n", next->ty);
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		next.toCBuffer2(buf, hgs, this.mod);
		if (next.ty != Tfunction)
			buf.writeByte('*');
	}
	
    override MATCH implicitConvTo(Type to)
	{
		//printf("TypePointer.implicitConvTo(to = %s) %s\n", to.toChars(), toChars());

		if (equals(to))
			return MATCH.MATCHexact;
		if (to.ty == TY.Tpointer)
		{	
			TypePointer tp = cast(TypePointer)to;
			assert(tp.next);

			if (!MODimplicitConv(next.mod, tp.next.mod))
				return MATCH.MATCHnomatch;        // not const-compatible

			/* Alloc conversion to void[]
			 */
			if (next.ty != TY.Tvoid && tp.next.ty == TY.Tvoid)
			{
				return MATCH.MATCHconvert;
			}

			MATCH m = next.constConv(tp.next);
			if (m != MATCH.MATCHnomatch)
			{
				if (m == MATCH.MATCHexact && mod != to.mod)
					m = MATCH.MATCHconst;
				return m;
			}

			/* Conversion of ptr to derived to ptr to base
			 */
			int offset = 0;
			if (tp.next.isBaseOf(next, &offset) && offset == 0)
				return MATCH.MATCHconvert;
		}
		return MATCH.MATCHnomatch;
	}
	
    override bool isscalar()
	{
		return true;
	}
	
    override Expression defaultInit(Loc loc)
	{
	version (LOGDEFAULTINIT) {
		printf("TypePointer::defaultInit() '%s'\n", toChars());
	}
		return new NullExp(loc, this);
	}
	
    override bool isZeroInit(Loc loc)
	{
		return true;
	}
	
    override TypeInfoDeclaration getTypeInfoDeclaration()
	{
		return new TypeInfoPointerDeclaration(this);
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
		type* tn;
		type* t;

		//printf("TypePointer.toCtype() %s\n", toChars());
		if (ctype)
			return ctype;

		if (1 || global.params.symdebug)
		{	/* Need to always do this, otherwise C++ name mangling
			 * goes awry.
			 */
			t = type_alloc(TYM.TYnptr);
			ctype = t;
			tn = next.toCtype();
			t.Tnext = tn;
			tn.Tcount++;
		}
		else
			t = type_fake(totym());

		t.Tcount++;
		ctype = t;
		return t;
	}
}
