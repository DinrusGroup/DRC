module dmd.TypeDelegate;

import dmd.common;
import dmd.Type;
import dmd.TypeNext;
import dmd.MOD;
import dmd.OutBuffer;
import dmd.Id;
import dmd.AddExp;
import dmd.PtrExp;
import dmd.IntegerExp;
import dmd.MATCH;
import dmd.NullExp;
import dmd.TypeFunction;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.Identifier;
import dmd.CppMangleState;
import dmd.Parameter;
import dmd.Loc;
import dmd.Scope;
import dmd.TypeInfoDeclaration;
import dmd.TypeInfoDelegateDeclaration;
import dmd.TY;
import dmd.Global;

import dmd.backend.TYPE;
import dmd.backend.Symbol;
import dmd.backend.Classsym;
import dmd.backend.TYM;
import dmd.backend.SC;
import dmd.backend.Util;
import dmd.backend.LIST;

import dmd.DDMDExtensions;

class TypeDelegate : TypeNext
{
	mixin insertMemberExtension!(typeof(this));

    // .next is a TypeFunction

    this(Type t)
	{
		register();
		super(TY.Tfunction, t);
		ty = TY.Tdelegate;
	}
	
    override Type syntaxCopy()
	{
		Type t = next.syntaxCopy();
		if (t == next)
			t = this;
		else
		{	
			t = new TypeDelegate(t);
			t.mod = mod;
		}
		return t;
	}
	
    override Type semantic(Loc loc, Scope sc)
	{
		if (deco)			// if semantic() already run
		{
			//printf("already done\n");
			return this;
		}

		next = next.semantic(loc, sc);
		return merge();
	}
	
    override ulong size(Loc loc)
	{
		return PTRSIZE * 2;
	}
	
	override MATCH implicitConvTo(Type to)
	{
		//writef("TypeDelegate::implicitConvTo(this=%p, to=%p)\n", this, to);
		//writef("from: %s\n", toChars());
		//writef("to  : %s\n", to.toChars());
		if (this == to)
			return MATCHexact;
static if (false) // not allowing covariant conversions because it interferes with overriding
{
		if (to.ty == Tdelegate && this.nextOf().covariant(to.nextOf()) == 1)
			return MATCHconvert;
}
		return MATCHnomatch;
	}
    
    override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		if (mod != this.mod)
		{	
			toCBuffer3(buf, hgs, mod);
			return;
		}
		TypeFunction tf = cast(TypeFunction)next;

		tf.next.toCBuffer2(buf, hgs, MODundefined);
		buf.writestring(" delegate");
		Parameter.argsToCBuffer(buf, hgs, tf.parameters, tf.varargs);
	}
	
    override Expression defaultInit(Loc loc)
	{
	version (LOGDEFAULTINIT) {
		printf("TypeDelegate.defaultInit() '%s'\n", toChars());
	}
		return new NullExp(loc, this);
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
		return new TypeInfoDelegateDeclaration(this);
	}
	
    override Expression dotExp(Scope sc, Expression e, Identifier ident)
	{
	version (LOGDOTEXP) {
		printf("TypeDelegate.dotExp(e = '%s', ident = '%s')\n", e.toChars(), ident.toChars());
	}
		auto tvoidptr = global.tvoidptr;
		if (ident == Id.ptr)
		{
			e.type = tvoidptr;
			return e;
		}
		else if (ident == Id.funcptr)
		{
			e = e.addressOf(sc);
			e.type = tvoidptr;
			e = new AddExp(e.loc, e, new IntegerExp(PTRSIZE));
			e.type = tvoidptr;
			e = new PtrExp(e.loc, e);
			e.type = next.pointerTo();
			return e;
		}
		else
		{
			e = Type.dotExp(sc, e, ident);
		}
		return e;
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
		type* t;

		if (ctype)
			return ctype;

		if (0 && global.params.symdebug)
		{
			/* A delegate consists of:
			 *    _Delegate { void* frameptr; Function *funcptr; }
			 */

			auto s = global.Delegate_s;
			if (!s)
			{
				global.Delegate_s = s = symbol_calloc("_Delegate");
				s.Sclass = SC.SCstruct;
				s.Sstruct = struct_calloc();
				s.Sstruct.Sflags |= 0;	/// huh?
				s.Sstruct.Salignsize = alignsize();
				s.Sstruct.Sstructalign = cast(ubyte)global.structalign;
				s.Sstruct.Sstructsize = cast(uint)size(Loc(0));
				slist_add(s);

				auto tvoidptr = global.tvoidptr;
				
				Symbol* s1 = symbol_name("frameptr", SC.SCmember, tvoidptr.toCtype());
				list_append(&s.Sstruct.Sfldlst, s1);

				Symbol* s2 = symbol_name("funcptr", SC.SCmember, tvoidptr.toCtype());
				s2.Smemoff = cast(uint)tvoidptr.size();
				list_append(&s.Sstruct.Sfldlst, s2);
			}

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
				t = type_allocn(TYM.TYdelegate, next.toCtype());
			}
			else
				t = type_fake(TYM.TYdelegate);
		}

		t.Tcount++;
		ctype = t;
		return t;
	}
}
