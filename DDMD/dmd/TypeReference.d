module dmd.TypeReference;

import dmd.common;
import dmd.Type;
import dmd.MOD;
import dmd.TypeNext;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.Identifier;
import dmd.NullExp;
import dmd.CppMangleState;
import dmd.TY;

import dmd.DDMDExtensions;

class TypeReference : TypeNext
{
	mixin insertMemberExtension!(typeof(this));

    this(Type t)
	{
		register();
		super(TY.init, null);
		assert(false);
	}
	
    override Type syntaxCopy()
	{
		assert(false);
	}
	
    override Type semantic(Loc loc, Scope sc)
	{
		assert(false);
	}
	
    override ulong size(Loc loc)
	{
		assert(false);
	}
	
    override void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		assert(false);
	}
	
    override Expression dotExp(Scope sc, Expression e, Identifier ident)
	{
		assert(false);
	}
	
    override Expression defaultInit(Loc loc)
	{
version(LOGDEFAULTINIT) {
    printf("TypeReference::defaultInit() '%s'\n", toChars());
}
		return new NullExp(loc, this);
	}
	
    override bool isZeroInit(Loc loc)
	{
		assert(false);
	}
	
version (CPP_MANGLE) {
    void toCppMangle(OutBuffer buf, CppMangleState* cms)
	{
		assert(false);
	}
}
}
