module dmd.Type;

import dmd.common;
import dmd.TY;
import dmd.Parameter;
import dmd.TOK;
import dmd.STC;
import dmd.TypeArray;
import dmd.DotVarExp;
import dmd.ErrorExp;
import dmd.StringExp;
import dmd.IntegerExp;
import dmd.VarExp;
import dmd.TemplateParameter;
import dmd.TypeInfoSharedDeclaration;
import dmd.TypeInfoConstDeclaration;
import dmd.TypeInfoInvariantDeclaration;
import dmd.Module;
import dmd.Id;
import dmd.Util;
import dmd.VarDeclaration;
import dmd.Loc;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.Identifier;
import dmd.HdrGenState;
import dmd.Expression;
import dmd.Dsymbol;
import dmd.MATCH;
import dmd.TypeInfoDeclaration;
import dmd.ClassDeclaration;
import dmd.StringTable;
import dmd.ArrayTypes;
import dmd.TypeBasic;
import dmd.DYNCAST;
import dmd.MOD;
import dmd.Lexer;
import dmd.TypeSArray;
import dmd.TypeDArray;
import dmd.TypeAArray;
import dmd.TypePointer;
import dmd.TypeReference;
import dmd.TypeFunction;
import dmd.TypeDelegate;
import dmd.TypeIdentifier;
import dmd.TypeInstance;
import dmd.TypeTypeof;
import dmd.TypeReturn;
import dmd.TypeStruct;
import dmd.TypeEnum;
import dmd.TypeTypedef;
import dmd.TypeClass;
import dmd.TypeTuple;
import dmd.TypeSlice;
import dmd.Global;
import dmd.StringValue;
import dmd.TRUST;
import dmd.TemplateDeclaration;
import dmd.DotIdExp;
import dmd.AggregateDeclaration;
import dmd.DotTemplateInstanceExp;
import dmd.Token;
import dmd.TypeInfoWildDeclaration;

import dmd.expression.Util;

import dmd.backend.Symbol;
import dmd.backend.TYPE;
import dmd.backend.dt_t;
import dmd.backend.Util;
import dmd.backend.TYM;
import dmd.backend.mTY;

import core.stdc.stdio;

import core.memory;

import dmd.DDMDExtensions;

/* These have default values for 32 bit code, they get
 * adjusted for 64 bit code.
 */

__gshared int PTRSIZE = 4;

__gshared int Tsize_t;
__gshared int Tptrdiff_t;

/* REALSIZE = size a real consumes in memory
 * REALPAD = 'padding' added to the CPU real size to bring it up to REALSIZE
 * REALALIGNSIZE = alignment for reals
 */
version (TARGET_OSX) {
	extern(C++) __gshared int REALSIZE = 16;
	__gshared int REALPAD = 6;
	__gshared int REALALIGNSIZE = 16;
} else version (POSIX) { /// TARGET_LINUX || TARGET_FREEBSD || TARGET_SOLARIS
	extern(C++) __gshared int REALSIZE = 12;
	__gshared int REALPAD = 2;
	__gshared int REALALIGNSIZE = 4;
} else {
	extern(C++) __gshared int REALSIZE = 10;
	__gshared int REALPAD = 0;
	__gshared int REALALIGNSIZE = 2;
}

/****
 * Given an identifier, figure out which TemplateParameter it is.
 * Return -1 if not found.
 */

int templateIdentifierLookup(Identifier id, TemplateParameters parameters)
{
    foreach (size_t i, TemplateParameter tp; parameters)
    {
		if (tp.ident.equals(id))
			return i;
    }
    return -1;
}

int templateParameterLookup(Type tparam, TemplateParameters parameters)
{
    assert(tparam.ty == Tident);
    TypeIdentifier tident = cast(TypeIdentifier)tparam;
    //printf("\ttident = '%s'\n", tident.toChars());
    if (tident.idents.dim == 0)
    {
		return templateIdentifierLookup(tident.ident, parameters);
    }
    return -1;
}

/***************************
 * Return !=0 if modfrom can be implicitly converted to modto
 */
int MODimplicitConv(MOD modfrom, MOD modto)
{
    if (modfrom == modto)
	return 1;

    //printf("MODimplicitConv(from = %x, to = %x)\n", modfrom, modto);
	static uint X(MOD m, MOD n)
	{
		return (((m) << 4) | (n));
	}
    switch (X(modfrom, modto))
    {
	    case X(MOD.MODundefined, MOD.MODconst):
	    case X(MOD.MODimmutable, MOD.MODconst):
	    case X(MOD.MODwild,      MOD.MODconst):
	    case X(MOD.MODimmutable, MOD.MODconst | MOD.MODshared):
	    case X(MOD.MODshared,    MOD.MODconst | MOD.MODshared):
	    case X(MOD.MODwild | MOD.MODshared,    MOD.MODconst | MOD.MODshared):
	        return 1;

	    default:
	        return 0;
    }
}

/*********************************
 * Mangling for mod.
 */
void MODtoDecoBuffer(OutBuffer buf, MOD mod)
{
    switch (mod)
    {
        case MOD.MODundefined:
	        break;
	    case MOD.MODconst:
	        buf.writeByte('x');
	        break;
	    case MOD.MODimmutable:
	        buf.writeByte('y');
	        break;
	    case MOD.MODshared:
	        buf.writeByte('O');
	        break;
	    case MOD.MODshared | MOD.MODconst:
	        buf.writestring("Ox");
	        break;
	    case MOD.MODwild:
	        buf.writestring("Ng");
	        break;
	    case MOD.MODshared | MOD.MODwild:
	        buf.writestring("ONg");
	        break;
	    default:
	        assert(0);
    }
}

/*********************************
 * Name for mod.
 */
void MODtoBuffer(OutBuffer buf, MOD mod)
{
    switch (mod)
    {
    case MOD.MODundefined:
	    break;

	case MOD.MODimmutable:
	    buf.writestring(Token.tochars[TOK.TOKimmutable]);
	    break;

	case MOD.MODshared:
	    buf.writestring(Token.tochars[TOK.TOKshared]);
	    break;

	case MOD.MODshared | MOD.MODconst:
	    buf.writestring(Token.tochars[TOK.TOKshared]);
	    buf.writeByte(' ');
	case MOD.MODconst:
	    buf.writestring(Token.tochars[TOK.TOKconst]);
	    break;

	case MOD.MODshared | MOD.MODwild:
	    buf.writestring(Token.tochars[TOK.TOKshared]);
	    buf.writeByte(' ');
	case MOD.MODwild:
	    buf.writestring(Token.tochars[TOKwild]);
	    break;
	default:
	    assert(0);
    }
}

import dmd.TObject;

class Type : TObject
{
	mixin insertMemberExtension!(typeof(this));
	
    TY ty;
    MOD mod;	// modifiers MODxxxx
	/* pick this order of numbers so switch statements work better
	 */
///	#define MODconst     1	// type is const
///	#define MODinvariant 4	// type is immutable
///	#define MODimmutable 4  // type is immutable
///	#define MODshared    2	// type is shared
    string deco;

    /* These are cached values that are lazily evaluated by constOf(), invariantOf(), etc.
     * They should not be referenced by anybody but mtype.c.
     * They can be null if not lazily evaluated yet.
     * Note that there is no "shared immutable", because that is just immutable
     * Naked == no MOD bits
     */

    Type cto;		// MODconst ? naked version of this type : const version
    Type ito;		// MODimmutable ? naked version of this type : immutable version
    Type sto;		// MODshared ? naked version of this type : shared mutable version
    Type scto;		// MODshared|MODconst ? naked version of this type : shared const version
    Type wto;		// MODwild ? naked version of this type : wild version
    Type swto;		// MODshared|MODwild ? naked version of this type : shared wild version


    Type pto;		// merged pointer to this type
    Type rto;		// reference to this type
    Type arrayof;	// array of this type
    TypeInfoDeclaration vtinfo;	// TypeInfo object for this Type

    type* ctype;	// for back end

    static __gshared ubyte[TY.TMAX] mangleChar;
    static __gshared ubyte[TY.TMAX] sizeTy;

    // These tables are for implicit conversion of binary ops;
    // the indices are the type of operand one, followed by operand two.
    static __gshared ubyte[TY.TMAX][TY.TMAX] impcnvResult = [
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,23,24,25,29,30,31,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,23,24,25,29,30,31,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,23,24,25,29,30,31,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,23,24,25,29,30,31,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,23,24,25,29,30,31,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,20,20,20,20,20,20,21,22,23,24,25,23,24,25,29,30,31,37,20,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,21,21,21,21,21,21,21,22,23,24,25,23,24,25,29,30,31,37,21,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,22,22,22,22,22,22,22,22,23,24,25,23,24,25,29,30,31,37,22,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,23,23,23,23,23,23,23,23,23,24,25,23,24,25,29,30,31,37,23,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,24,24,24,24,24,24,24,24,24,24,25,24,24,25,30,30,31,37,24,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,25,25,25,25,25,25,25,25,25,25,25,25,25,25,31,31,31,37,25,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,23,23,23,23,23,23,23,23,23,24,25,26,27,28,29,30,31,37,23,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,24,24,24,24,24,24,24,24,24,24,25,27,27,28,30,30,31,37,24,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,25,25,25,25,25,25,25,25,25,25,25,28,28,28,31,31,31,37,25,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,29,29,29,29,29,29,29,29,29,30,31,29,30,31,29,30,31,37,29,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,30,30,30,30,30,30,30,30,30,30,31,30,30,31,30,30,31,37,30,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,37,31,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,23,24,25,29,30,31,37,33,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
	];

    static __gshared ubyte[TY.TMAX][TY.TMAX] impcnvType1 = [
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,23,24,25,23,24,25,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,23,24,25,23,24,25,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,23,24,25,23,24,25,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,23,24,25,23,24,25,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,23,24,25,23,24,25,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,20,20,20,20,20,20,21,22,23,24,25,23,24,25,23,24,25,37,20,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,21,21,21,21,21,21,21,22,23,24,25,23,24,25,23,24,25,37,21,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,22,22,22,22,22,22,22,22,23,24,25,23,24,25,23,24,25,37,22,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,23,23,23,23,23,23,23,23,23,24,25,23,24,25,23,24,25,37,23,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,24,24,24,24,24,24,24,24,24,24,25,24,24,25,24,24,25,37,24,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,25,37,25,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,26,26,26,26,26,26,26,26,26,27,28,26,27,28,26,27,28,37,26,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,27,27,27,27,27,27,27,27,27,27,28,27,27,28,27,27,28,37,27,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,37,28,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,29,29,29,29,29,29,29,29,29,30,31,29,30,31,29,30,31,37,29,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,30,30,30,30,30,30,30,30,30,30,31,30,30,31,30,30,31,37,30,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,31,37,31,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,23,24,25,23,24,25,37,33,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
	];

    static __gshared ubyte[TY.TMAX][TY.TMAX] impcnvType2 = [
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,26,27,28,29,30,31,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,26,27,28,29,30,31,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,26,27,28,29,30,31,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,26,27,28,29,30,31,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,26,27,28,29,30,31,37,19,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,20,20,20,20,20,20,21,22,23,24,25,26,27,28,29,30,31,37,20,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,21,21,21,21,21,21,21,22,23,24,25,26,27,28,29,30,31,37,21,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,22,22,22,22,22,22,22,22,23,24,25,26,27,28,29,30,31,37,22,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,23,23,23,23,23,23,23,23,23,24,25,26,27,28,29,30,31,37,23,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,24,24,24,24,24,24,24,24,24,24,25,27,27,28,30,30,31,37,24,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,25,25,25,25,25,25,25,25,25,25,25,28,28,28,31,31,31,37,25,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,23,23,23,23,23,23,23,23,23,24,25,26,27,28,29,30,31,37,23,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,24,24,24,24,24,24,24,24,24,24,25,27,27,28,30,30,31,37,24,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,25,25,25,25,25,25,25,25,25,25,25,28,28,28,31,31,31,37,25,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,23,23,23,23,23,23,23,23,23,24,25,26,27,28,29,30,31,37,23,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,24,24,24,24,24,24,24,24,24,24,25,27,27,28,30,30,31,37,24,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,25,25,25,25,25,25,25,25,25,25,25,28,28,28,31,31,31,37,25,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,19,19,19,19,19,20,21,22,23,24,25,26,27,28,29,30,31,37,33,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
		[37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37],
	];

    // If !=0, give warning on implicit conversion
    static __gshared const(bool)[TY.TMAX][TY.TMAX] impcnvWarn = [
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
		[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
	];

    this(TY ty)
	{
		register();
		this.ty = ty;
	}

    Type syntaxCopy()
	{
		assert(false);
	}

    bool equals(Object o)
	{
		Type t = cast(Type)o;
		//printf("Type.equals(%s, %s)\n", toChars(), t.toChars());
		if (this is o || (t && deco == t.deco) &&		// deco strings are unique
		 deco !is null)				// and semantic() has been run
		{
			//printf("deco = '%s', t.deco = '%s'\n", deco, t.deco);
			return 1;
		}
		//if (deco && t && t.deco) printf("deco = '%s', t.deco = '%s'\n", deco, t.deco);
		return 0;
	}

    DYNCAST dyncast() { return DYNCAST.DYNCAST_TYPE; } // kludge for template.isType()

	/*******************************
     * Covariant means that 'this' can substitute for 't',
     * i.e. a pure function is a match for an impure type.	 * Returns:
	 *	0	types are distinct
	 *	1	this is covariant with t
	 *	2	arguments match as far as overloading goes,
	 *		but types are not covariant
	 *	3	cannot determine covariance because of forward references
	 */
    int covariant(Type t)
	{
static if (false)
{
		printf("Type.covariant(t = %s) %s\n", t.toChars(), toChars());
		printf("deco = %p, %p\n", deco, t.deco);
	//    printf("ty = %d\n", next.ty);
		printf("mod = %x, %x\n", mod, t.mod);
}

		int inoutmismatch = 0;

		TypeFunction t1;
		TypeFunction t2;

		if (equals(t))
			return 1;			// covariant

		if (ty != TY.Tfunction || t.ty != TY.Tfunction)
			goto Ldistinct;

		t1 = cast(TypeFunction)this;
		t2 = cast(TypeFunction)t;

		if (t1.varargs != t2.varargs)
			goto Ldistinct;

		if (t1.parameters && t2.parameters)
		{
			size_t dim = Parameter.dim(t1.parameters);
			if (dim != Parameter.dim(t2.parameters))
				goto Ldistinct;

			for (size_t i = 0; i < dim; i++)
			{
				auto arg1 = Parameter.getNth(t1.parameters, i);
				auto arg2 = Parameter.getNth(t2.parameters, i);

				if (!arg1.type.equals(arg2.type))
				{
///static if (false) {
///				// turn on this for contravariant argument types, see bugzilla 3075
///				// BUG: cannot convert ref to const to ref to immutable
///				// We can add const, but not subtract it
///				if (arg2.type.implicitConvTo(arg1.type) < MATCH.MATCHconst)
///}
					goto Ldistinct;
				}
                const StorageClass sc = STC.STCref | STC.STCin | STC.STCout | STC.STClazy;
				if ((arg1.storageClass & sc) != (arg2.storageClass & sc))
					inoutmismatch = 1;
				// We can add scope, but not subtract it
				if (!(arg1.storageClass & STC.STCscope) && (arg2.storageClass & STC.STCscope))
					inoutmismatch = 1;
			}
		}
		else if (t1.parameters != t2.parameters)
			goto Ldistinct;

		// The argument lists match
		if (inoutmismatch)
			goto Lnotcovariant;
		if (t1.linkage != t2.linkage)
			goto Lnotcovariant;

	  {
		// Return types
		Type t1n = t1.next;
		Type t2n = t2.next;

		if (t1n is null || t2n is null) // happens with return type inference
			goto Lnotcovariant;

		if (t1n.equals(t2n))
		goto Lcovariant;
		if (t1n.ty == TY.Tclass && t2n.ty == TY.Tclass)
		{
			/* If same class type, but t2n is const, then it's
			 * covariant. Do this test first because it can work on
			 * forward references.
			 */
			if ((cast(TypeClass)t1n).sym == (cast(TypeClass)t2n).sym &&
				MODimplicitConv(t1n.mod, t2n.mod))
				goto Lcovariant;

			// If t1n is forward referenced:
			ClassDeclaration cd = (cast(TypeClass)t1n).sym;
			if (!cd.baseClass && cd.baseclasses.dim && !cd.isInterfaceDeclaration())
			{
				return 3;
			}
		}
		if (t1n.implicitConvTo(t2n))
			goto Lcovariant;
	  }

	goto Lnotcovariant;

	Lcovariant:
		/* Can convert mutable to const
		 */
        if (!MODimplicitConv(t2.mod, t1.mod))
	        goto Lnotcovariant;
static if(false) {
		if (t1.mod != t2.mod)
		{
			if (!(t1.mod & MOD.MODconst) && (t2.mod & MOD.MODconst))
				goto Lnotcovariant;
			if (!(t1.mod & MOD.MODshared) && (t2.mod & MOD.MODshared))
				goto Lnotcovariant;
		}
}
		/* Can convert pure to impure, and nothrow to throw
		 */
		if (!t1.ispure && t2.ispure)
			goto Lnotcovariant;

		if (!t1.isnothrow && t2.isnothrow)
			goto Lnotcovariant;

		if (t1.isref != t2.isref)
	        goto Lnotcovariant;

        /* Can convert safe/trusted to system
         */
        if (t1.trust <= TRUST.TRUSTsystem && t2.trust >= TRUST.TRUSTtrusted)
			goto Lnotcovariant;

		//printf("\tcovaraint: 1\n");
		return 1;

	Ldistinct:
		//printf("\tcovaraint: 0\n");
		return 0;

	Lnotcovariant:
		//printf("\tcovaraint: 2\n");
		return 2;
	}

    string toChars()
	{
		scope OutBuffer buf = new OutBuffer();

		HdrGenState hgs;
		toCBuffer(buf, null, &hgs);
		return buf.toChars();
	}

    static char needThisPrefix()
	{
		return 'M';		// name mangling prefix for functions needing 'this'
	}

    static void init()
	{
		Lexer.initKeywords();

		for (int i = 0; i < TY.TMAX; i++)
			sizeTy[i] = TypeBasic.sizeof;

		sizeTy[TY.Tsarray] = TypeSArray.sizeof;
		sizeTy[TY.Tarray] = TypeDArray.sizeof;
		//sizeTy[TY.Tnarray] = TypeNArray.sizeof;
		sizeTy[TY.Taarray] = TypeAArray.sizeof;
		sizeTy[TY.Tpointer] = TypePointer.sizeof;
		sizeTy[TY.Treference] = TypeReference.sizeof;
		sizeTy[TY.Tfunction] = TypeFunction.sizeof;
		sizeTy[TY.Tdelegate] = TypeDelegate.sizeof;
		sizeTy[TY.Tident] = TypeIdentifier.sizeof;
		sizeTy[TY.Tinstance] = TypeInstance.sizeof;
		sizeTy[TY.Ttypeof] = TypeTypeof.sizeof;
		sizeTy[TY.Tenum] = TypeEnum.sizeof;
		sizeTy[TY.Ttypedef] = TypeTypedef.sizeof;
		sizeTy[TY.Tstruct] = TypeStruct.sizeof;
		sizeTy[TY.Tclass] = TypeClass.sizeof;
		sizeTy[TY.Ttuple] = TypeTuple.sizeof;
		sizeTy[TY.Tslice] = TypeSlice.sizeof;
		sizeTy[TY.Treturn] = TypeReturn.sizeof;

		mangleChar[TY.Tarray] = 'A';
		mangleChar[TY.Tsarray] = 'G';
		mangleChar[TY.Tnarray] = '@';
		mangleChar[TY.Taarray] = 'H';
		mangleChar[TY.Tpointer] = 'P';
		mangleChar[TY.Treference] = 'R';
		mangleChar[TY.Tfunction] = 'F';
		mangleChar[TY.Tident] = 'I';
		mangleChar[TY.Tclass] = 'C';
		mangleChar[TY.Tstruct] = 'S';
		mangleChar[TY.Tenum] = 'E';
		mangleChar[TY.Ttypedef] = 'T';
		mangleChar[TY.Tdelegate] = 'D';

		mangleChar[TY.Tnone] = 'n';
		mangleChar[TY.Tvoid] = 'v';
		mangleChar[TY.Tint8] = 'g';
		mangleChar[TY.Tuns8] = 'h';
		mangleChar[TY.Tint16] = 's';
		mangleChar[TY.Tuns16] = 't';
		mangleChar[TY.Tint32] = 'i';
		mangleChar[TY.Tuns32] = 'k';
		mangleChar[TY.Tint64] = 'l';
		mangleChar[TY.Tuns64] = 'm';
		mangleChar[TY.Tfloat32] = 'f';
		mangleChar[TY.Tfloat64] = 'd';
		mangleChar[TY.Tfloat80] = 'e';

		mangleChar[TY.Timaginary32] = 'o';
		mangleChar[TY.Timaginary64] = 'p';
		mangleChar[TY.Timaginary80] = 'j';
		mangleChar[TY.Tcomplex32] = 'q';
		mangleChar[TY.Tcomplex64] = 'r';
		mangleChar[TY.Tcomplex80] = 'c';

		mangleChar[TY.Tbool] = 'b';
		mangleChar[TY.Tascii] = 'a';
		mangleChar[TY.Twchar] = 'u';
		mangleChar[TY.Tdchar] = 'w';

        // '@' shouldn't appear anywhere in the deco'd names
		mangleChar[TY.Tbit] = '@';
		mangleChar[TY.Tinstance] = '@';
		mangleChar[TY.Terror] = '@';
		mangleChar[TY.Ttypeof] = '@';
		mangleChar[TY.Ttuple] = 'B';
		mangleChar[TY.Tslice] = '@';
		mangleChar[TY.Treturn] = '@';

debug {
		for (int i = 0; i < TY.TMAX; i++) {
			if (!mangleChar[i]) {
				writef("ty = %d\n", i);
			}
			assert(mangleChar[i]);
		}
}
		// Set basic types
		enum TY[] basetab = [
			TY.Tvoid, TY.Tint8, TY.Tuns8, TY.Tint16, TY.Tuns16, TY.Tint32, TY.Tuns32, TY.Tint64, TY.Tuns64,
			TY.Tfloat32, TY.Tfloat64, TY.Tfloat80,
			TY.Timaginary32, TY.Timaginary64, TY.Timaginary80,
			TY.Tcomplex32, TY.Tcomplex64, TY.Tcomplex80,
			TY.Tbool,
			TY.Tascii, TY.Twchar, TY.Tdchar
		];

		foreach (bt; basetab) {
			Type t = new TypeBasic(bt);
			t = t.merge();
			basic[bt] = t;
		}

		basic[TY.Terror] = basic[TY.Tint32];

		global.tvoidptr = tvoid.pointerTo();
		global.tstring = tchar.invariantOf().arrayOf();

		if (global.params.isX86_64) {
			PTRSIZE = 8;
			if (global.params.isLinux || global.params.isFreeBSD || global.params.isSolaris)
				REALSIZE = 10;
			else
				REALSIZE = 8;
			Tsize_t = TY.Tuns64;
			Tptrdiff_t = TY.Tint64;
		}
		else
		{
			PTRSIZE = 4;
version (TARGET_OSX) {
			REALSIZE = 16;
			REALPAD = 6;
} else version (XXX) { //#elif TARGET_LINUX || TARGET_FREEBSD || TARGET_SOLARIS
			REALSIZE = 12;
			REALPAD = 2;
} else {
			REALSIZE = 10;
			REALPAD = 0;
}
			Tsize_t = TY.Tuns32;
			Tptrdiff_t = TY.Tint32;
		}
	}

    ulong size()
	{
		return size(Loc(0));
	}

    ulong size(Loc loc)
	{
		error(loc, "no size for type %s", toChars());
		return 1;
	}

    uint alignsize()
	{
		return cast(uint)size(Loc(0));	///
	}

    Type semantic(Loc loc, Scope sc)
	{
		return merge();
	}

    Type trySemantic(Loc loc, Scope sc)
	{
		uint errors = global.errors;
		global.gag++;			// suppress printing of error messages
		Type t = semantic(loc, sc);
		global.gag--;
		if (errors != global.errors)	// if any errors happened
		{
			global.errors = errors;
			t = null;
		}
		return t;
	}

	/********************************
	 * Name mangling.
	 * Input:
	 *	flag	0x100	do not do const/invariant
	 */
    void toDecoBuffer(OutBuffer buf, int flag = 0)
	{
		if (flag != mod && flag != 0x100)
		{
			MODtoDecoBuffer(buf, mod);
		}
		buf.writeByte(mangleChar[ty]);
	}

    Type merge()
	{
		Type t = this;
		assert(t);

		//printf("merge(%s)\n", toChars());
		if (deco is null)
		{
			OutBuffer buf = new OutBuffer();

			//if (next)
				//next = next.merge();
			toDecoBuffer(buf);
			auto s = buf.extractString();
			Object* sv = global.type_stringtable.update(s);
			if (*sv)
			{
				t = cast(Type) *sv;
debug {
				if (!t.deco)
					writef("t = %s\n", t.toChars());
}
				assert(t.deco);
				//printf("old value, deco = '%s' %p\n", t.deco, t.deco);
			}
			else
			{
				*sv = this;
				deco = s;
				//printf("new value, deco = '%s' %p\n", t.deco, t.deco);
			}
		}
		return t;
	}

	/*************************************
	 * This version does a merge even if the deco is already computed.
	 * Necessary for types that have a deco, but are not merged.
	 */
    Type merge2()
	{
		//printf("merge2(%s)\n", toChars());
		Type t = this;
		assert(t);
		if (!t.deco)
			return t.merge();

		Object* sv = global.type_stringtable.lookup(t.deco);
		if (sv && *sv)
		{
			t = cast(Type)*sv;
			assert(t.deco);
		}
		else
			assert(0);

		return t;
	}

    void toCBuffer(OutBuffer buf, Identifier ident, HdrGenState* hgs)
	{
		toCBuffer2(buf, hgs, MOD.MODundefined);
		if (ident)
		{
			buf.writeByte(' ');
			buf.writestring(ident.toChars());
		}
	}

    void toCBuffer2(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		if (mod != this.mod)
		{
			toCBuffer3(buf, hgs, mod);
			return;
		}
		buf.writestring(toChars());
	}

    void toCBuffer3(OutBuffer buf, HdrGenState* hgs, MOD mod)
	{
		if (mod != this.mod)
		{
			if (this.mod & MOD.MODshared)
	        {
	            MODtoBuffer(buf, this.mod & MOD.MODshared);
	            buf.writeByte('(');
	        }

	        if (this.mod & ~MOD.MODshared)
	        {
	            MODtoBuffer(buf, this.mod & ~MOD.MODshared);
	            buf.writeByte('(');
	            toCBuffer2(buf, hgs, this.mod);
	            buf.writeByte(')');
	        }
	        else
	            toCBuffer2(buf, hgs, this.mod);
	        if (this.mod & MOD.MODshared)
	        {
	            buf.writeByte(')');
	        }
		}
	}

    void modToBuffer(OutBuffer buf)
	{
        if (mod)
        {
    	    buf.writeByte(' ');
	        MODtoBuffer(buf, mod);
        }
	}

version (CPP_MANGLE) {
	import dmd.CppMangleState;

    void toCppMangle(OutBuffer buf, CppMangleState* cms)
	{
		assert(false);
	}
}
    bool isintegral()
	{
		return false;
	}

    bool isfloating()	// real, imaginary, or complex
	{
		return false;
	}

    bool isreal()
	{
		return false;
	}

    bool isimaginary()
	{
		return false;
	}

    bool iscomplex()
	{
		return false;
	}

    bool isscalar()
	{
		return false;
	}

    bool isunsigned()
	{
		return false;
	}

    bool isauto()
	{
		return false;
	}

    bool isString()
	{
		return false;
	}

	/**************************
	 * Given:
	 *	T a, b;
	 * Can we assign:
	 *	a = b;
	 * ?
	 */
    bool isAssignable()
	{
		return true;
	}

    bool checkBoolean()	// if can be converted to boolean value
	{
		return isscalar();
	}

	/*********************************
	 * Check type to see if it is based on a deprecated symbol.
	 */
    void checkDeprecated(Loc loc, Scope sc)
	{
		Dsymbol s = toDsymbol(sc);
		if (s)
			s.checkDeprecated(loc, sc);
	}

    bool isConst()	{ return (mod & MOD.MODconst) != 0; }

	int isImmutable()	{ return mod & MOD.MODimmutable; }

	int isMutable()	{ return !(mod & (MOD.MODconst | MOD.MODimmutable | MOD.MODwild)); }

	int isShared()	{ return mod & MOD.MODshared; }

	int isSharedConst()	{ return mod == (MOD.MODshared | MOD.MODconst); }

    int isWild()	{ return mod & MOD.MODwild; }

    int isSharedWild()	{ return mod == (MOD.MODshared | MOD.MODwild); }

    int isNaked()	{ return mod == 0; }


	/********************************
	 * Convert to 'const'.
	 */
	Type constOf()
	{
		//printf("Type.constOf() %p %s\n", this, toChars());
		if (mod == MOD.MODconst)
			return this;
		if (cto)
		{
			assert(cto.mod == MOD.MODconst);
			return cto;
		}
		Type t = makeConst();
		t = t.merge();
		t.fixTo(this);
		//printf("-Type.constOf() %p %s\n", t, toChars());
		return t;
	}

	/********************************
	 * Convert to 'immutable'.
	 */
    Type invariantOf()
	{
		//printf("Type.invariantOf() %p %s\n", this, toChars());
		if (isImmutable())
		{
			return this;
		}
		if (ito)
		{
			assert(ito.isImmutable());
			return ito;
		}
		Type t = makeInvariant();
		t = t.merge();
		t.fixTo(this);
		//printf("\t%p\n", t);
		return t;
	}

    Type mutableOf()
	{
		//printf("Type.mutableOf() %p, %s\n", this, toChars());
		Type t = this;
		if (isConst())
		{
			if (isShared())
				t = sto;		// shared const => shared
			else
				t = cto;		// const => naked
			assert(!t || t.isMutable());
		}
		else if (isImmutable())
		{
			t = ito;
			assert(!t || (t.isMutable() && !t.isShared()));
		}
        else if (isWild())
        {
	        if (isShared())
	            t = sto;		// shared wild => shared
	        else
	            t = wto;		// wild => naked
	        assert(!t || t.isMutable());
        }
		if (!t)
		{
            t = makeMutable();
			t = t.merge();
			t.fixTo(this);
		}
            assert(t.isMutable());
		return t;
	}

    Type sharedOf()
	{
		//printf("Type.sharedOf() %p, %s\n", this, toChars());
		if (mod == MOD.MODshared)
		{
			return this;
		}
		if (sto)
		{
			assert(sto.isShared());
			return sto;
		}

		Type t = makeShared();
		t = t.merge();
		t.fixTo(this);

		//printf("\t%p\n", t);
		return t;
	}

    Type sharedConstOf()
	{
		//printf("Type.sharedConstOf() %p, %s\n", this, toChars());
		if (mod == (MODshared | MODconst))
		{
			return this;
		}
		if (scto)
		{
			assert(scto.mod == (MODshared | MODconst));
			return scto;
		}

		Type t = makeSharedConst();
		t = t.merge();
		t.fixTo(this);
		//printf("\t%p\n", t);

		return t;
	}

	/********************************
	 * Make type unshared.
     *	0            => 0
     *	const        => const
     *	immutable    => immutable
     *	shared       => 0
     *	shared const => const
     *	wild         => wild
     *	shared wild  => wild
	 */
	Type unSharedOf()
	{
		//writef("Type::unSharedOf() %p, %s\n", this, toChars());
		Type t = this;

		if (isShared())
		{
			if (isConst())
				t = cto;	// shared const => const
	        else if (isWild())
	            t = wto;	// shared wild => wild
			else
				t = sto;
			assert(!t || !t.isShared());
		}

		if (!t)
		{
			t = cloneThis(this);
			t.mod = mod & ~MODshared;
			t.deco = null;
			t.arrayof = null;
			t.pto = null;
			t.rto = null;
			t.cto = null;
			t.ito = null;
			t.sto = null;
			t.scto = null;
	        t.wto = null;
	        t.swto = null;
			t.vtinfo = null;
			t = t.merge();

			t.fixTo(this);
		}
		assert(!t.isShared());
		return t;
	}


    /********************************
     * Convert to 'wild'.
     */

    Type wildOf()
    {
        //printf("Type::wildOf() %p %s\n", this, toChars());
        if (mod == MOD.MODwild)
        {
	        return this;
        }
        if (wto)
        {
    	    assert(wto.isWild());
	        return wto;
        }
        Type t = makeWild();
        t = t.merge();
        t.fixTo(this);
        //printf("\t%p %s\n", t, t->toChars());
        return t;
    }

    Type sharedWildOf()
    {
        //printf("Type::sharedWildOf() %p, %s\n", this, toChars());
        if (mod == (MOD.MODwild))
        {
    	    return this;
        }
        if (swto)
        {
	        assert(swto.mod == (MOD.MODshared | MOD.MODwild));
	        return swto;
        }
        Type t = makeSharedWild();
        t = t.merge();
        t.fixTo(this);
        //printf("\t%p\n", t);
        return t;
    }

	static uint X(MOD m, MOD n)
	{
		return (((m) << 4) | (n));
	}

	/**********************************
	 * For our new type 'this', which is type-constructed from t,
	 * fill in the cto, ito, sto, scto, wto shortcuts.
	 */
    void fixTo(Type t)
	{
		ito = t.ito;
static if (false) {
		/* Cannot do these because these are not fully transitive:
		 * there can be a shared ptr to immutable, for example.
		 * Immutable subtypes are always immutable, though.
		 */
		cto = t.cto;
		sto = t.sto;
		scto = t.scto;
}

		assert(mod != t.mod);

		switch (X(mod, t.mod))
		{
		case X(MOD.MODundefined, MOD.MODconst):
			cto = t;
			break;

		case X(MOD.MODundefined, MOD.MODimmutable):
			ito = t;
			break;

		case X(MOD.MODundefined, MOD.MODshared):
			sto = t;
			break;

		case X(MOD.MODundefined, MOD.MODshared | MOD.MODconst):
			scto = t;
			break;

        case X(MOD.MODundefined, MODwild):
    	    wto = t;
	        break;

	    case X(MOD.MODundefined, MODshared | MODwild):
    	    swto = t;
	        break;


		case X(MOD.MODconst, MOD.MODundefined):
			cto = null;
			goto L2;

		case X(MOD.MODconst, MOD.MODimmutable):
			ito = t;
			goto L2;

		case X(MOD.MODconst, MOD.MODshared):
			sto = t;
			goto L2;

		case X(MOD.MODconst, MOD.MODshared | MOD.MODconst):
			scto = t;
	        goto L2;

	    case X(MOD.MODconst, MOD.MODwild):
	        wto = t;
	        goto L2;

	    case X(MOD.MODconst, MOD.MODshared | MOD.MODwild):
	        swto = t;
		L2:
			t.cto = this;
			break;


		case X(MOD.MODimmutable, MOD.MODundefined):
			ito = null;
			goto L3;

		case X(MOD.MODimmutable, MOD.MODconst):
			cto = t;
			goto L3;

		case X(MOD.MODimmutable, MOD.MODshared):
			sto = t;
			goto L3;

		case X(MOD.MODimmutable, MOD.MODshared | MOD.MODconst):
			scto = t;
	        goto L3;

	    case X(MOD.MODimmutable, MOD.MODwild):
	        wto = t;
	        goto L3;

	    case X(MOD.MODimmutable, MOD.MODshared | MOD.MODwild):
	        swto = t;
		L3:
			t.ito = this;
			if (t.cto) t.cto.ito = this;
			if (t.sto) t.sto.ito = this;
			if (t.scto) t.scto.ito = this;
	        if (t.wto) t.wto.ito = this;
	        if (t.swto) t.swto.ito = this;
			break;


		case X(MOD.MODshared, MOD.MODundefined):
			sto = null;
			goto L4;

		case X(MOD.MODshared, MOD.MODconst):
			cto = t;
			goto L4;

		case X(MOD.MODshared, MOD.MODimmutable):
			ito = t;
			goto L4;

		case X(MOD.MODshared, MOD.MODshared | MOD.MODconst):
			scto = t;
	        goto L4;

	    case X(MOD.MODshared, MOD.MODwild):
	        wto = t;
	        goto L4;

	    case X(MOD.MODshared, MOD.MODshared | MOD.MODwild):
	        swto = t;
		L4:
			t.sto = this;
			break;


		case X(MOD.MODshared | MOD.MODconst, MOD.MODundefined):
			scto = null;
			goto L5;

		case X(MOD.MODshared | MOD.MODconst, MOD.MODconst):
			cto = t;
			goto L5;

		case X(MOD.MODshared | MOD.MODconst, MOD.MODimmutable):
			ito = t;
	        goto L5;

	    case X(MOD.MODshared | MOD.MODconst, MOD.MODwild):
	        wto = t;
	        goto L5;

		case X(MOD.MODshared | MOD.MODconst, MOD.MODshared):
			sto = t;
	        goto L5;

	    case X(MOD.MODshared | MOD.MODconst, MOD.MODshared | MOD.MODwild):
	        swto = t;
		L5:
			t.scto = this;
			break;

	    case X(MOD.MODwild, MOD.MODundefined):
	        wto = null;
	        goto L6;

	    case X(MOD.MODwild, MOD.MODconst):
	        cto = t;
	        goto L6;

	    case X(MOD.MODwild, MOD.MODimmutable):
	        ito = t;
	        goto L6;

	    case X(MOD.MODwild, MOD.MODshared):
	        sto = t;
	        goto L6;

	    case X(MOD.MODwild, MOD.MODshared | MOD.MODconst):
	        scto = t;
	        goto L6;

	    case X(MOD.MODwild, MOD.MODshared | MOD.MODwild):
	        swto = t;
	    L6:
	        t.wto = this;
	        break;


	    case X(MOD.MODshared | MOD.MODwild, MOD.MODundefined):
	        swto = null;
	        goto L7;

	    case X(MOD.MODshared | MOD.MODwild, MOD.MODconst):
	        cto = t;
	        goto L7;

	    case X(MOD.MODshared | MOD.MODwild, MOD.MODimmutable):
	        ito = t;
	        goto L7;

	    case X(MOD.MODshared | MOD.MODwild, MOD.MODshared):
	        sto = t;
	        goto L7;

	    case X(MOD.MODshared | MOD.MODwild, MOD.MODshared | MOD.MODconst):
	        scto = t;
	        goto L7;

	    case X(MOD.MODshared | MOD.MODwild, MOD.MODwild):
	        wto = t;
	    L7:
	        t.swto = this;
	        break;
			
		default:
			assert(false);
		}

		check();
		t.check();
		//printf("fixTo: %s, %s\n", toChars(), t.toChars());
	}

	/***************************
	 * Look for bugs in constructing types.
	 */
    void check()
	{
		switch (mod)
		{
		case MOD.MODundefined:
			if (cto) assert(cto.mod == MOD.MODconst);
			if (ito) assert(ito.mod == MOD.MODimmutable);
			if (sto) assert(sto.mod == MOD.MODshared);
			if (scto) assert(scto.mod == (MOD.MODshared | MOD.MODconst));
	        if (wto) assert(wto.mod == MOD.MODwild);
	        if (swto) assert(swto.mod == (MOD.MODshared | MOD.MODwild));
			break;

		case MOD.MODconst:
			if (cto) assert(cto.mod == MOD.MODundefined);
			if (ito) assert(ito.mod == MOD.MODimmutable);
			if (sto) assert(sto.mod == MOD.MODshared);
			if (scto) assert(scto.mod == (MOD.MODshared | MOD.MODconst));
	        if (wto) assert(wto.mod == MOD.MODwild);
	        if (swto) assert(swto.mod == (MOD.MODshared | MOD.MODwild));
			break;

		case MOD.MODimmutable:
			if (cto) assert(cto.mod == MOD.MODconst);
			if (ito) assert(ito.mod == MOD.MODundefined);
			if (sto) assert(sto.mod == MOD.MODshared);
			if (scto) assert(scto.mod == (MOD.MODshared | MOD.MODconst));
	        if (wto) assert(wto.mod == MOD.MODwild);
	        if (swto) assert(swto.mod == (MOD.MODshared | MOD.MODwild));
			break;

		case MOD.MODshared:
			if (cto) assert(cto.mod == MOD.MODconst);
			if (ito) assert(ito.mod == MOD.MODimmutable);
			if (sto) assert(sto.mod == MOD.MODundefined);
			if (scto) assert(scto.mod == (MOD.MODshared | MOD.MODconst));
	        if (wto) assert(wto.mod == MOD.MODwild);
	        if (swto) assert(swto.mod == (MOD.MODshared | MOD.MODwild));
			break;

		case MOD.MODshared | MOD.MODconst:
			if (cto) assert(cto.mod == MOD.MODconst);
			if (ito) assert(ito.mod == MOD.MODimmutable);
			if (sto) assert(sto.mod == MOD.MODshared);
			if (scto) assert(scto.mod == MOD.MODundefined);
	        if (wto) assert(wto.mod == MOD.MODwild);
	        if (swto) assert(swto.mod == (MOD.MODshared | MOD.MODwild));
			break;

	    case MOD.MODwild:
	        if (cto) assert(cto.mod == MOD.MODconst);
	        if (ito) assert(ito.mod == MOD.MODimmutable);
	        if (sto) assert(sto.mod == MOD.MODshared);
	        if (scto) assert(scto.mod == (MOD.MODshared | MOD.MODconst));
	        if (wto) assert(wto.mod == MOD.MODundefined);
	        if (swto) assert(swto.mod == (MOD.MODshared | MOD.MODwild));
	        break;

	    case MOD.MODshared | MOD.MODwild:
	        if (cto) assert(cto.mod == MOD.MODconst);
	        if (ito) assert(ito.mod == MOD.MODimmutable);
	        if (sto) assert(sto.mod == MOD.MODshared);
	        if (scto) assert(scto.mod == (MOD.MODshared | MOD.MODconst));
	        if (wto) assert(wto.mod == MOD.MODwild);
	        if (swto) assert(swto.mod == MOD.MODundefined);
	        break;
			
		default:
			assert(false);
		}

		Type tn = nextOf();
		if (tn && ty != TY.Tfunction && ty != TY.Tdelegate)
		{
			// Verify transitivity
			switch (mod)
			{
				case MOD.MODundefined:
					break;

				case MOD.MODconst:
					assert(tn.mod & MOD.MODimmutable || tn.mod & MOD.MODconst);
					break;

				case MOD.MODimmutable:
					assert(tn.mod == MOD.MODimmutable);
					break;

				case MOD.MODshared:
					assert(tn.mod & MOD.MODimmutable || tn.mod & MOD.MODshared);
					break;

				case MOD.MODshared | MOD.MODconst:
					assert(tn.mod & MOD.MODimmutable || tn.mod & (MOD.MODshared | MOD.MODconst));
    		        break;

	            case MOD.MODwild:
	    	        assert(tn.mod);
		            break;

	            case MOD.MODshared | MOD.MODwild:
		            assert(tn.mod == MOD.MODimmutable || tn.mod == (MOD.MODshared | MOD.MODconst) || tn.mod == (MOD.MODshared | MOD.MODwild));
					break;
					
				default:
					assert(false);
			}
			tn.check();
		}
	}

	/************************************
	 * Apply MODxxxx bits to existing type.
	 */
    Type castMod(uint mod)
	{
		Type t;

		switch (mod)
		{
		case 0:
			t = unSharedOf().mutableOf();
			break;

		case MODconst:
			t = unSharedOf().constOf();
			break;

		case MODimmutable:
			t = invariantOf();
			break;

		case MODshared:
			t = mutableOf().sharedOf();
			break;

		case MODshared | MODconst:
			t = sharedConstOf();
	        break;

	    case MODwild:
	        t = unSharedOf().wildOf();
	        break;

	    case MODshared | MODwild:
	        t = sharedWildOf();
			break;

		default:
			assert(0);
		}
		return t;
	}

	/************************************
	 * Add MODxxxx bits to existing type.
	 * We're adding, not replacing, so adding const to
	 * a shared type => "shared const"
	 */
    Type addMod(MOD mod)
	{
		Type t = this;

		/* Add anything to immutable, and it remains immutable
		 */
        //printf("addMod(%x) %s\n", mod, toChars());
		if (!t.isImmutable())
		{
			switch (mod)
			{
				case MOD.MODundefined:
					break;

				case MOD.MODconst:
					if (isShared())
						t = sharedConstOf();
					else
						t = constOf();
					break;

				case MOD.MODimmutable:
					t = invariantOf();
					break;

				case MOD.MODshared:
					if (isConst())
						t = sharedConstOf();
		            else if (isWild())
		                t = sharedWildOf();
					else
						t = sharedOf();
					break;

				case MOD.MODshared | MOD.MODconst:
					t = sharedConstOf();
					break;

	            case MOD.MODwild:
		            if (isConst())
                    {}
		            else if (isShared())
		                t = sharedWildOf();
		            else
		                t = wildOf();
		            break;

	            case MOD.MODshared | MOD.MODwild:
		            t = sharedWildOf();
		            break;
					
				default:
					assert(false);
			}
		}
		return t;
	}

    Type addStorageClass(StorageClass stc)
	{
		/* Just translate to MOD bits and let addMod() do the work
		 */
		MOD mod = MOD.MODundefined;

		if (stc & STC.STCimmutable)
			mod = MOD.MODimmutable;
		else
		{
			if (stc & (STC.STCconst | STC.STCin))
				mod = MOD.MODconst;
			if (stc & STC.STCshared)
				mod |= MOD.MODshared;
	        if (stc & STC.STCwild)
	            mod |= MOD.MODwild;
		}

		return addMod(mod);
	}

    Type pointerTo()
	{
		if (pto is null)
		{
			Type t = new TypePointer(this);
			pto = t.merge();
		}

		return pto;
	}

    Type referenceTo()
	{
		assert(false);
	}

	final Type clone()
	{
		return cloneThis(this);
	}

    Type arrayOf()
	{
		if (!arrayof)
		{
			Type t = new TypeDArray(this);
			arrayof = t.merge();
		}
		return arrayof;
	}

    Type makeConst()
	{
		//printf("Type.makeConst() %p, %s\n", this, toChars());
		if (cto)
			return cto;

		Type t = clone();
		t.mod = MOD.MODconst;

		t.deco = null;
		t.arrayof = null;
		t.pto = null;
		t.rto = null;
		t.cto = null;
		t.ito = null;
		t.sto = null;
		t.scto = null;
        t.wto = null;
        t.swto = null;
		t.vtinfo = null;

		//printf("-Type.makeConst() %p, %s\n", t, toChars());
		return t;
	}

    Type makeInvariant()
	{
		if (ito) {
			return ito;
		}

		Type t = clone();
		t.mod = MOD.MODimmutable;

		t.deco = null;
		t.arrayof = null;
		t.pto = null;
		t.rto = null;
		t.cto = null;
		t.ito = null;
		t.sto = null;
		t.scto = null;
        t.wto = null;
        t.swto = null;
		t.vtinfo = null;

		return t;
	}

    Type makeShared()
	{
		if (sto)
			return sto;

		Type t = clone();
		t.mod = MOD.MODshared;

		t.deco = null;
		t.arrayof = null;
		t.pto = null;
		t.rto = null;
		t.cto = null;
		t.ito = null;
		t.sto = null;
		t.scto = null;
        t.wto = null;
        t.swto = null;
		t.vtinfo = null;

		return t;
	}

    Type makeSharedConst()
	{
		if (scto)
			return scto;

		Type t = clone();
		t.mod = MODshared | MODconst;

		t.deco = null;
		t.arrayof = null;
		t.pto = null;
		t.rto = null;
		t.cto = null;
		t.ito = null;
		t.sto = null;
		t.scto = null;
        t.wto = null;
        t.swto = null;
		t.vtinfo = null;

		return t;
	}

    Type makeWild()
    {
        if (wto)
	        return wto;

        Type t = clone();
        t.mod = MOD.MODwild;
        t.deco = null;
        t.arrayof = null;
        t.pto = null;
        t.rto = null;
        t.cto = null;
        t.ito = null;
        t.sto = null;
        t.scto = null;
        t.wto = null;
        t.swto = null;
        t.vtinfo = null;
        return t;
    }

    Type makeSharedWild()
    {
        if (swto)
	        return swto;

        Type t = clone();
        t.mod = MOD.MODshared | MOD.MODwild;
        t.deco = null;
        t.arrayof = null;
        t.pto = null;
        t.rto = null;
        t.cto = null;
        t.ito = null;
        t.sto = null;
        t.scto = null;
        t.wto = null;
        t.swto = null;
        t.vtinfo = null;
        return t;
    }

    Type makeMutable()
    {
        Type t = clone();
        t.mod =  mod & MOD.MODshared;
        t.deco = null;
        t.arrayof = null;
        t.pto = null;
        t.rto = null;
        t.cto = null;
        t.ito = null;
        t.sto = null;
        t.scto = null;
        t.wto = null;
        t.swto = null;
        t.vtinfo = null;
        return t;
    }

    Dsymbol toDsymbol(Scope sc)
	{
		return null;
	}

	/*******************************
	 * If this is a shell around another type,
	 * get that other type.
	 */

    Type toBasetype()
	{
		return this;
	}

	/**************************
	 * Return type with the top level of it being mutable.
	 */
    Type toHeadMutable()
	{
		if (!mod)
			return this;

		return mutableOf();
	}

    bool isBaseOf(Type t, int* poffset)
	{
		return false;		// assume not
	}

	/*******************************
	 * Determine if converting 'this' to 'to' is an identity operation,
	 * a conversion to const operation, or the types aren't the same.
	 * Returns:
	 *	MATCHequal	'this' == 'to'
	 *	MATCHconst	'to' is const
	 *	MATCHnomatch	conversion to mutable or invariant
	 */
    MATCH constConv(Type to)
	{
		if (equals(to))
			return MATCH.MATCHexact;
		if (ty == to.ty && MODimplicitConv(mod, to.mod))
			return MATCH.MATCHconst;
		return MATCH.MATCHnomatch;
	}

	/********************************
	 * Determine if 'this' can be implicitly converted
	 * to type 'to'.
	 * Returns:
	 *	MATCHnomatch, MATCHconvert, MATCHconst, MATCHexact
	 */
    MATCH implicitConvTo(Type to)
	{
		//printf("Type.implicitConvTo(this=%p, to=%p)\n", this, to);
		//printf("from: %s\n", toChars());
		//printf("to  : %s\n", to.toChars());
		if (this is to)
			return MATCHexact;

		return MATCHnomatch;
	}

    ClassDeclaration isClassHandle()
	{
		return null;
	}

    Expression getProperty(Loc loc, Identifier ident)
	{
		Expression e;

version (LOGDOTEXP) {
		printf("Type.getProperty(type = '%s', ident = '%s')\n", toChars(), ident.toChars());
}
		if (ident == Id.__sizeof)
		{
			e = new IntegerExp(loc, size(loc), Type.tsize_t);
		}
		else if (ident == Id.size)
		{
			error(loc, ".size property should be replaced with .sizeof");
			e = new ErrorExp();
		}
		else if (ident is Id.alignof_)
		{
			e = new IntegerExp(loc, alignsize(), Type.tsize_t);
		}
		else if (ident == Id.typeinfo_)
		{
			if (!global.params.useDeprecated)
				error(loc, ".typeinfo deprecated, use typeid(type)");
			e = getTypeInfo(null);
		}
		else if (ident == Id.init_)
		{
			if (ty == TY.Tvoid)
				error(loc, "void does not have an initializer");
			e = defaultInit(loc);
		}
		else if (ident is Id.mangleof_)
		{
			string s;
			if (!deco) {
				s = toChars();
				error(loc, "forward reference of type %s.mangleof", s);
			} else {
				s = deco;
			}

			e = new StringExp(loc, s, 'c');
			scope Scope sc = new Scope();
			e = e.semantic(sc);
		}
		else if (ident is Id.stringof_)
		{
			string s = toChars();
			e = new StringExp(loc, s, 'c');
			scope Scope sc = new Scope();
			e = e.semantic(sc);
		}
		else
		{
			error(loc, "no property '%s' for type '%s'", ident.toChars(), toChars());
			e = new ErrorExp();
		}
		return e;
	}

    Expression dotExp(Scope sc, Expression e, Identifier ident)
	{
		VarDeclaration v = null;

version (LOGDOTEXP) {
		printf("Type.dotExp(e = '%s', ident = '%s')\n", e.toChars(), ident.toChars());
}
		if (e.op == TOK.TOKdotvar)
		{
			DotVarExp dv = cast(DotVarExp)e;
			v = dv.var.isVarDeclaration();
		}
		else if (e.op == TOK.TOKvar)
		{
			VarExp ve = cast(VarExp)e;
			v = ve.var.isVarDeclaration();
		}
		if (v)
		{
			if (ident is Id.offset)
			{
				if (!global.params.useDeprecated)
					error(e.loc, ".offset deprecated, use .offsetof");
				goto Loffset;
			}
			else if (ident is Id.offsetof)
			{
			  Loffset:
				if (v.storage_class & STC.STCfield)
				{
					e = new IntegerExp(e.loc, v.offset, Type.tsize_t);
					return e;
				}
			}
			else if (ident is Id.init_)
			{
static if (false) {
				if (v.init)
				{
					if (v.init.isVoidInitializer())
						error(e.loc, "%s.init is void", v.toChars());
					else
					{   Loc loc = e.loc;
						e = v.init.toExpression();
						if (e.op == TOK.TOKassign || e.op == TOK.TOKconstruct || e.op == TOK.TOKblit)
						{
							e = (cast(AssignExp)e).e2;

							/* Take care of case where we used a 0
							 * to initialize the struct.
							 */
							if (e.type == Type.tint32 &&
								e.isBool(0) &&
								v.type.toBasetype().ty == TY.Tstruct)
							{
								e = v.type.defaultInit(e.loc);
							}
						}
						e = e.optimize(WANTvalue | WANTinterpret);
			//		    if (!e.isConst())
			//			error(loc, ".init cannot be evaluated at compile time");
					}
					goto Lreturn;
				}
}
				e = defaultInit(e.loc);
	            goto Lreturn;
			}
		}
		if (ident is Id.typeinfo_)
		{
			if (!global.params.useDeprecated)
				error(e.loc, ".typeinfo deprecated, use typeid(type)");
			e = getTypeInfo(sc);
		}
		else if (ident is Id.stringof_)
		{
			string s = e.toChars();
			e = new StringExp(e.loc, s, 'c');
		}
        else
    	    e = getProperty(e.loc, ident);

Lreturn:
        e = e.semantic(sc);
        return e;
	}

    /***************************************
     * Figures out what to do with an undefined member reference
     * for classes and structs.
     */
    Expression noMember(Scope sc, Expression e, Identifier ident)
    {
        assert(ty == TY.Tstruct || ty == TY.Tclass);
        AggregateDeclaration sym = toDsymbol(sc).isAggregateDeclaration();
        assert(sym);

        if (ident !is Id.__sizeof &&
	    ident !is Id.alignof_ &&
	    ident !is Id.init_ &&
	    ident !is Id.mangleof_ &&
	    ident !is Id.stringof_ &&
	    ident !is Id.offsetof)
        {
	    /* See if we should forward to the alias this.
	     */
	    if (sym.aliasthis)
	    {   /* Rewrite e.ident as:
	         *	e.aliasthis.ident
	         */
	        e = new DotIdExp(e.loc, e, sym.aliasthis.ident);
	        e = new DotIdExp(e.loc, e, ident);
	        return e.semantic(sc);
	    }

	    /* Look for overloaded opDot() to see if we should forward request
	     * to it.
	     */
	    Dsymbol fd = search_function(sym, Id.opDot);
	    if (fd)
	    {   /* Rewrite e.ident as:
	         *	e.opDot().ident
	         */
	        e = build_overload(e.loc, sc, e, null, fd.ident);
	        e = new DotIdExp(e.loc, e, ident);
	        return e.semantic(sc);
	    }

	    /* Look for overloaded opDispatch to see if we should forward request
	     * to it.
	     */
	    fd = search_function(sym, Id.opDispatch);
	    if (fd)
	    {
	        /* Rewrite e.ident as:
	         *	e.opDispatch!("ident")
	         */
	        TemplateDeclaration td = fd.isTemplateDeclaration();
	        if (!td)
	        {
		    fd.error("must be a template opDispatch(string s), not a %s", fd.kind());
		    return new ErrorExp();
	        }
	        auto se = new StringExp(e.loc, ident.toChars());
	        auto tiargs = new Objects();
	        tiargs.push(se);
	        e = new DotTemplateInstanceExp(e.loc, e, Id.opDispatch, tiargs);
	        (cast(DotTemplateInstanceExp)e).ti.tempdecl = td;
	        return e;
	        //return e.semantic(sc);
	    }
        }

        return Type.dotExp(sc, e, ident);
    }

    uint memalign(uint salign)
	{
		return salign;
	}

    Expression defaultInit(Loc loc)
	{
		version (LOGDEFAULTINIT) {
			printf("Type.defaultInit() '%.*s'\n", toChars());
		}
		return null;
	}

    /***************************************
     * Use when we prefer the default initializer to be a literal,
     * rather than a global immutable variable.
     */
    //Expression defaultInitLiteral(Loc loc = Loc(0))
    Expression defaultInitLiteral(Loc loc)
    {
version(LOGDEFAULTINIT) {
        printf("Type::defaultInitLiteral() '%s'\n", toChars());
}
        return defaultInit(loc);
    }

    ///bool isZeroInit(Loc loc = Loc(0))		// if initializer is 0
	bool isZeroInit(Loc loc)		// if initializer is 0
	{
		assert(false);
	}

    dt_t** toDt(dt_t** pdt)
	{
		//printf("Type.toDt()\n");
		Expression e = defaultInit(Loc(0));
		return e.toDt(pdt);
	}

    Identifier getTypeInfoIdent(int internal)
	{
		// _init_10TypeInfo_%s
		scope OutBuffer buf = new OutBuffer();
		Identifier id;
		char* name;
		int len;

		if (internal)
		{
			buf.writeByte(mangleChar[ty]);
			if (ty == TY.Tarray)
				buf.writeByte(mangleChar[(cast(TypeArray)this).next.ty]);
		}
		else
			toDecoBuffer(buf);

		len = buf.offset;
		version (Bug4054)
		name = cast(char*)GC.malloc(19 + len.sizeof * 3 + len + 1);
		else
		name = cast(char*)alloca(19 + len.sizeof * 3 + len + 1);
		buf.writeByte(0);
	version (TARGET_OSX) {
		// The LINKc will prepend the _
		len = sprintf(name, "D%dTypeInfo_%s6__initZ".ptr, 9 + len, buf.data);
	} else {
		len = sprintf(name, "_D%dTypeInfo_%s6__initZ".ptr, 9 + len, buf.data);
	}
		if (global.params.isWindows)
			name++;			// C mangling will add it back in
		//printf("name = %s\n", name);
		id = Lexer.idPool(name[0..len-1].idup);
		return id;
	}

	/* These form the heart of template argument deduction.
	 * Given 'this' being the type argument to the template instance,
	 * it is matched against the template declaration parameter specialization
	 * 'tparam' to determine the type to be used for the parameter.
	 * Example:
	 *	template Foo(T:T*)	// template declaration
	 *	Foo!(int*)		// template instantiation
	 * Input:
	 *	this = int*
	 *	tparam = T
	 *	parameters = [ T:T* ]	// Array of TemplateParameter's
	 * Output:
	 *	dedtypes = [ int ]	// Array of Expression/Type's
	 */
    MATCH deduceType(Scope sc, Type tparam, TemplateParameters parameters, Objects dedtypes)
	{
	static if (false)
	{
		printf("Type.deduceType()\n");
		printf("\tthis   = %d, ", ty); print();
		printf("\ttparam = %d, ", tparam.ty); tparam.print();
	}
		if (!tparam)
			goto Lnomatch;

		if (this == tparam)
			goto Lexact;

		if (tparam.ty == Tident)
		{
			// Determine which parameter tparam is
			int i = templateParameterLookup(tparam, parameters);
			if (i == -1)
			{
				if (!sc)
					goto Lnomatch;

				/* Need a loc to go with the semantic routine.
				 */
				Loc loc;
				if (parameters.dim)
				{
					auto tp = parameters[0];
					loc = tp.loc;
				}

				/* BUG: what if tparam is a template instance, that
				 * has as an argument another Tident?
				 */
				tparam = tparam.semantic(loc, sc);
				assert(tparam.ty != Tident);
				return deduceType(sc, tparam, parameters, dedtypes);
			}

			auto tp = parameters[i];

			// Found the corresponding parameter tp
			if (!tp.isTemplateTypeParameter())
				goto Lnomatch;
			Type tt = this;
			Type at = cast(Type)dedtypes[i];

			// 5*5 == 25 cases
			static pure int X(int U, int T) { return ((U << 4) | T); }

			switch (X(tparam.mod, mod))
			{
				case X(0, 0):
				case X(0, MODconst):
				case X(0, MODimmutable):
				case X(0, MODshared):
				case X(0, MODconst | MODshared):
	            case X(0, MODwild):
	            case X(0, MODwild | MODshared):
				// foo(U:U) T  							=> T
				// foo(U:U) const(T)					=> const(T)
				// foo(U:U) immutable(T)				=> immutable(T)
				// foo(U:U) shared(T)					=> shared(T)
				// foo(U:U) const(shared(T))			=> const(shared(T))
		        // foo(U:U) wild(T)                        => wild(T)
		        // foo(U:U) wild(shared(T))                => wild(shared(T))
				if (!at)
				{   dedtypes[i] = tt;
					goto Lexact;
				}
				break;

				case X(MODconst, MODconst):
				case X(MODimmutable, MODimmutable):
				case X(MODshared, MODshared):
				case X(MODconst | MODshared, MODconst | MODshared):
	            case X(MODwild, MODwild):
	            case X(MODwild | MODshared, MODwild | MODshared):
	            case X(MODconst, MODwild):
	            case X(MODconst, MODwild | MODshared):
				// foo(U:const(U))			const(T)		=> T
				// foo(U:immutable(U))		immutable(T)	=> T
				// foo(U:shared(U))			shared(T)		=> T
				// foo(U:const(shared(U))	const(shared(T))=> T
		        // foo(U:wild(U))         wild(T)          => T
		        // foo(U:wild(shared(U))  wild(shared(T)) => T
        		// foo(U:const(U)) wild(shared(T))         => shared(T)
				tt = mutableOf().unSharedOf();
				if (!at)
				{
					dedtypes[i] = tt;
					goto Lexact;
				}
				break;

				case X(MODconst, 0):
				case X(MODconst, MODimmutable):
				case X(MODconst, MODconst | MODshared):
				case X(MODconst | MODshared, MODimmutable):
        	    case X(MODshared, MODwild | MODshared):
				// foo(U:const(U))			T					=> T
				// foo(U:const(U))			immutable(T)		=> T
				// foo(U:const(U))			const(shared(T))	=> shared(T)
				// foo(U:const(shared(U))	immutable(T)		=> T
        		// foo(U:shared(U)) wild(shared(T))        => wild(T)
				tt = mutableOf();
				if (!at)
				{   dedtypes[i] = tt;
					goto Lconst;
				}
				break;

				case X(MODshared, MODconst | MODshared):
				case X(MODconst | MODshared, MODshared):
				// foo(U:shared(U))			const(shared(T))	=> const(T)
				// foo(U:const(shared(U))	shared(T)			=> T
				tt = unSharedOf();
				if (!at)
				{   dedtypes[i] = tt;
					goto Lconst;
				}
				break;

				case X(MODimmutable,		 0):
				case X(MODimmutable,		 MODconst):
				case X(MODimmutable,		 MODshared):
				case X(MODimmutable,		 MODconst | MODshared):
				case X(MODconst,			 MODshared):
				case X(MODshared,			0):
				case X(MODshared,			MODconst):
				case X(MODshared,			MODimmutable):
				case X(MODconst | MODshared, 0):
				case X(MODconst | MODshared, MODconst):
	            case X(MODimmutable,	 MODwild):
	            case X(MODshared,		 MODwild):
	            case X(MODconst | MODshared, MODwild):
	            case X(MODwild,		 0):
	            case X(MODwild,		 MODconst):
	            case X(MODwild,		 MODimmutable):
	            case X(MODwild,		 MODshared):
	            case X(MODwild,		 MODconst | MODshared):
	            case X(MODwild | MODshared,	 0):
	            case X(MODwild | MODshared,	 MODconst):
	            case X(MODwild | MODshared,  MODimmutable):
	            case X(MODwild | MODshared,  MODshared):
	            case X(MODwild | MODshared,  MODconst | MODshared):
	            case X(MODwild | MODshared,  MODwild):
	            case X(MODimmutable,	 MODwild | MODshared):
	            case X(MODconst | MODshared, MODwild | MODshared):
	            case X(MODwild,		 MODwild | MODshared):
				// foo(U:immutable(U)) T				   => nomatch
				// foo(U:immutable(U)) const(T)			=> nomatch
				// foo(U:immutable(U)) shared(T)		   => nomatch
				// foo(U:immutable(U)) const(shared(T))	=> nomatch
				// foo(U:const(U)) shared(T)			   => nomatch
				// foo(U:shared(U)) T					  => nomatch
				// foo(U:shared(U)) const(T)			   => nomatch
				// foo(U:shared(U)) immutable(T)		   => nomatch
				// foo(U:const(shared(U)) T				=> nomatch
				// foo(U:const(shared(U)) const(T)		 => nomatch
		        // foo(U:immutable(U)) wild(T)             => nomatch
		        // foo(U:shared(U)) wild(T)                => nomatch
		        // foo(U:const(shared(U)) wild(T)          => nomatch
		        // foo(U:wild(U)) T                        => nomatch
		        // foo(U:wild(U)) const(T)                 => nomatch
		        // foo(U:wild(U)) immutable(T)             => nomatch
		        // foo(U:wild(U)) shared(T)                => nomatch
		        // foo(U:wild(U)) const(shared(T))         => nomatch
		        // foo(U:wild(shared(U)) T 		   => nomatch
		        // foo(U:wild(shared(U)) const(T)	   => nomatch
		        // foo(U:wild(shared(U)) immutable(T)	   => nomatch
		        // foo(U:wild(shared(U)) shared(T)         => nomatch
		        // foo(U:wild(shared(U)) const(shared(T))  => nomatch
		        // foo(U:wild(shared(U)) wild(T)	   => nomatch
		        // foo(U:immutable(U)) wild(shared(T))     => nomatch
		        // foo(U:const(shared(U))) wild(shared(T)) => nomatch
		        // foo(U:wild(U)) wild(shared(T))          => nomatch
				//if (!at)
					goto Lnomatch;
				break;

				default:
				assert(0);
			}

			if (tt.equals(at))
				goto Lexact;
			else if (tt.ty == Tclass && at.ty == Tclass)
			{
				return tt.implicitConvTo(at);
			}
			else if (tt.ty == Tsarray && at.ty == Tarray &&
				tt.nextOf().implicitConvTo(at.nextOf()) >= MATCHconst)
			{
				goto Lexact;
			}
			else
				goto Lnomatch;
		}

		if (ty != tparam.ty)
		return implicitConvTo(tparam);
	//	goto Lnomatch;

		if (nextOf())
			return nextOf().deduceType(sc, tparam.nextOf(), parameters, dedtypes);

	Lexact:
		return MATCHexact;

	Lnomatch:
		return MATCHnomatch;

	version (DMDV2) {
	Lconst:
		return MATCHconst;
	}
	}

    void resolve(Loc loc, Scope sc, Expression* pe, Type* pt, Dsymbol* ps)
	{
		//printf("Type.resolve() %s, %d\n", toChars(), ty);
		Type t = semantic(loc, sc);
		*pt = t;
		*pe = null;
		*ps = null;
	}

	/*******************************************
	 * Get a canonicalized form of the TypeInfo for use with the internal
	 * runtime library routines. Canonicalized in that static arrays are
	 * represented as dynamic arrays, enums are represented by their
	 * underlying type, etc. This reduces the number of TypeInfo's needed,
	 * so we can use the custom internal ones more.
	 */
    Expression getInternalTypeInfo(Scope sc)
	{
		TypeInfoDeclaration tid;
		Expression e;
		Type t;

		//printf("Type.getInternalTypeInfo() %s\n", toChars());
		t = toBasetype();
		switch (t.ty)
		{
			case Tsarray:
		static if (false) {
				// convert to corresponding dynamic array type
				t = t.nextOf().mutableOf().arrayOf();
		}
				break;

			case Tclass:
				if ((cast(TypeClass)t).sym.isInterfaceDeclaration())
					break;
				goto Linternal;

			case Tarray:
				// convert to corresponding dynamic array type
				t = t.nextOf().mutableOf().arrayOf();
				if (t.nextOf().ty != Tclass)
					break;
				goto Linternal;

			case Tfunction:
			case Tdelegate:
			case Tpointer:
			Linternal:
				tid = global.internalTI[t.ty];
				if (!tid)
				{
					tid = new TypeInfoDeclaration(t, 1);
					global.internalTI[t.ty] = tid;
				}
				e = new VarExp(Loc(0), tid);
				e = e.addressOf(sc);
				e.type = tid.type;	// do this so we don't get redundant dereference
				return e;

			default:
				break;
		}
		//printf("\tcalling getTypeInfo() %s\n", t.toChars());
		return t.getTypeInfo(sc);
	}

	/****************************************************
	 * Get the exact TypeInfo.
	 */
    Expression getTypeInfo(Scope sc)
	{
		Expression e;
		Type t;

		//printf("Type.getTypeInfo() %p, %s\n", this, toChars());
		t = merge2();	// do this since not all Type's are merge'd
		if (!t.vtinfo)
		{
version (DMDV2) {
			if (t.isShared())	// does both 'shared' and 'shared const'
				t.vtinfo = new TypeInfoSharedDeclaration(t);
			else if (t.isConst())
				t.vtinfo = new TypeInfoConstDeclaration(t);
			else if (t.isImmutable())
				t.vtinfo = new TypeInfoInvariantDeclaration(t);
    	    else if (t.isWild())
	            t.vtinfo = new TypeInfoWildDeclaration(t);

			else
				t.vtinfo = t.getTypeInfoDeclaration();
} else {
			t.vtinfo = t.getTypeInfoDeclaration();
}
			assert(t.vtinfo);
			vtinfo = t.vtinfo;

			/* If this has a custom implementation in std/typeinfo, then
			 * do not generate a COMDAT for it.
			 */
			if (!t.builtinTypeInfo())
			{
				// Generate COMDAT
				if (sc)			// if in semantic() pass
				{
					// Find module that will go all the way to an object file
					Module m = sc.module_.importedFrom;
					m.members.push(t.vtinfo);
				}
				else			// if in obj generation pass
				{
					t.vtinfo.toObjFile(global.params.multiobj);
				}
			}
		}
		e = new VarExp(Loc(0), t.vtinfo);
		e = e.addressOf(sc);
		e.type = t.vtinfo.type;		// do this so we don't get redundant dereference
		return e;
	}

    TypeInfoDeclaration getTypeInfoDeclaration()
	{
		//printf("Type.getTypeInfoDeclaration() %s\n", toChars());
		return new TypeInfoDeclaration(this, 0);
	}

	/* These decide if there's an instance for them already in std.typeinfo,
	 * because then the compiler doesn't need to build one.
	 */
    bool builtinTypeInfo()
	{
		return false;
	}

	/*******************************
	 * If one of the subtypes of this type is a TypeIdentifier,
	 * i.e. it's an unresolved type, return that type.
	 */
    Type reliesOnTident()
	{
		return null;
	}

    /***************************************
     * Return !=0 if the type or any of its subtypes is wild.
     */

    int hasWild()
    {
        return mod & MOD.MODwild;
    }

    /***************************************
     * Return MOD bits matching argument type (targ) to wild parameter type (this).
     */

    uint wildMatch(Type targ)
    {
        return 0;
    }

    Expression toExpression()
	{
		assert(false);
	}

	/***************************************
	 * Return true if type has pointers that need to
	 * be scanned by the GC during a collection cycle.
	 */
    bool hasPointers()
	{
		return false;
	}

	/*************************************
	 * If this is a type of something, return that something.
	 */
    Type nextOf()
	{
		return null;
	}

	/****************************************
	 * Return the mask that an integral type will
	 * fit into.
	 */
    ulong sizemask()
	{
		ulong m;

		switch (toBasetype().ty)
		{
			case Tbool:	m = 1;				break;
			case Tchar:
			case Tint8:
			case Tuns8:	m = 0xFF;			break;
			case Twchar:
			case Tint16:
			case Tuns16:	m = 0xFFFFUL;			break;
			case Tdchar:
			case Tint32:
			case Tuns32:	m = 0xFFFFFFFFUL;		break;
			case Tint64:
			case Tuns64:	m = 0xFFFFFFFFFFFFFFFFUL;	break;
			default:
				assert(0);
		}
		return m;
	}

    static void error(T...)(Loc loc, string format, T t)
	{
		.error(loc, format, t);
	}

    static void warning(T...)(Loc loc, string format, T t)
	{
		assert(false);
	}

    // For backend
	/*****************************
	 * Return back end type corresponding to D front end type.
	 */
    TYM totym()
	{
		TYM t;

		switch (ty)
		{
		case TY.Tvoid:	t = TYM.TYvoid;	break;
		case TY.Tint8:	t = TYM.TYschar;	break;
		case TY.Tuns8:	t = TYM.TYuchar;	break;
		case TY.Tint16:	t = TYM.TYshort;	break;
		case TY.Tuns16:	t = TYM.TYushort;	break;
		case TY.Tint32:	t = TYM.TYint;	break;
		case TY.Tuns32:	t = TYM.TYuint;	break;
		case TY.Tint64:	t = TYM.TYllong;	break;
		case TY.Tuns64:	t = TYM.TYullong;	break;
		case TY.Tfloat32:	t = TYM.TYfloat;	break;
		case TY.Tfloat64:	t = TYM.TYdouble;	break;
		case TY.Tfloat80:	t = TYM.TYldouble;	break;
		case TY.Timaginary32: t = TYM.TYifloat; break;
		case TY.Timaginary64: t = TYM.TYidouble; break;
		case TY.Timaginary80: t = TYM.TYildouble; break;
		case TY.Tcomplex32: t = TYM.TYcfloat;	break;
		case TY.Tcomplex64: t = TYM.TYcdouble;	break;
		case TY.Tcomplex80: t = TYM.TYcldouble; break;
		//case Tbit:	t = TYM.TYuchar;	break;
		case TY.Tbool:	t = TYM.TYbool;	break;
		case TY.Tchar:	t = TYM.TYchar;	break;
	version (XXX) { ///TARGET_LINUX || TARGET_OSX || TARGET_FREEBSD || TARGET_SOLARIS
		case TY.Twchar:	t = TYM.TYwchar_t;	break;
		case TY.Tdchar:	t = TYM.TYdchar;	break;
	} else {
		case TY.Twchar:	t = TYM.TYwchar_t;	break;
		case TY.Tdchar:
			t = (global.params.symdebug == 1) ? TYM.TYdchar : TYM.TYulong;
			break;
	}

		case TY.Taarray:	t = TYM.TYaarray;	break;
		case TY.Tclass:
		case TY.Treference:
		case TY.Tpointer:	t = TYM.TYnptr;	break;
		case TY.Tdelegate:	t = TYM.TYdelegate;	break;
		case TY.Tarray:	t = TYM.TYdarray;	break;
version(SARRAYVALUE)
{		case TY.Tsarray:	t = TYstruct;	break;}
else
{		case TY.Tsarray:	t = TYM.TYarray;	break;}
		case TY.Tstruct:	t = TYM.TYstruct;	break;

		case TY.Tenum:
		case TY.Ttypedef:
			 t = toBasetype().totym();
			 break;

		case TY.Tident:
		case TY.Ttypeof:
	debug {
			writef("ty = %d, '%s'\n", ty, toChars());
	}
			error (Loc(0), "forward reference of %s", toChars());
			t = TYM.TYint;
			break;

		default:
	debug {
			writef("ty = %d, '%s'\n", ty, toChars());
	}
			assert(0);
		}

	version (DMDV2) {
		// Add modifiers
		switch (mod)
		{
		case MOD.MODundefined:
			break;
		case MOD.MODconst:
	    case MOD.MODwild:
			t |= mTY.mTYconst;
			break;
		case MOD.MODimmutable:
			t |= mTY.mTYimmutable;
			break;
		case MOD.MODshared:
			t |= mTY.mTYshared;
			break;
        case MOD.MODshared | MOD.MODwild:
		case MOD.MODshared | MOD.MODconst:
			t |= mTY.mTYshared | mTY.mTYconst;
			break;
		default:
			assert(0);
		}
	}

		return t;
	}

	/***************************************
	 * Convert from D type to C type.
	 * This is done so C debug info can be generated.
	 */
    type* toCtype()
	{
		if (!ctype)
		{
			ctype = type_fake(totym());
			ctype.Tcount++;
		}
		return ctype;
	}

    type* toCParamtype()
	{
		return toCtype();
	}

    Symbol* toSymbol()
	{
		assert(false);
	}

    // For eliminating dynamic_cast
    TypeBasic isTypeBasic()
	{
		return null;
	}

	@property
	static ref Type[TY.TMAX] basic()
	{
		return global.basic;
	}

	static Type tvoid()
	{
		return basic[TY.Tvoid];
	}

	static Type tint8()
	{
		return basic[TY.Tint8];
	}

	static Type tuns8()
	{
		return basic[TY.Tuns8];
	}

	static Type tint16()
	{
		return basic[TY.Tint16];
	}

	static Type tuns16()
	{
		return basic[TY.Tuns16];
	}

	static Type tint32()
	{
		return basic[TY.Tint32];
	}

	static Type tuns32()
	{
		return basic[TY.Tuns32];
	}

	static Type tint64()
	{
		return basic[TY.Tint64];
	}

	static Type tuns64()
	{
		return basic[TY.Tuns64];
	}

	static Type tfloat32()
	{
		return basic[TY.Tfloat32];
	}

	static Type tfloat64()
	{
		return basic[TY.Tfloat64];
	}

	static Type tfloat80()
	{
		return basic[TY.Tfloat80];
	}

	static Type timaginary32()
	{
		return basic[TY.Timaginary32];
	}

	static Type timaginary64()
	{
		return basic[TY.Timaginary64];
	}

	static Type timaginary80()
	{
		return basic[TY.Timaginary80];
	}

	static Type tcomplex32()
	{
		return basic[TY.Tcomplex32];
	}

	static Type tcomplex64()
	{
		return basic[TY.Tcomplex64];
	}

	static Type tcomplex80()
	{
		return basic[TY.Tcomplex80];
	}

	static Type tbit()
	{
		return basic[TY.Tbit];
	}

	static Type tbool()
	{
		return basic[TY.Tbool];
	}

	static Type tchar()
	{
		return basic[TY.Tchar];
	}

	static Type twchar()
	{
		return basic[TY.Twchar];
	}

	static Type tdchar()
	{
		return basic[TY.Tdchar];
	}

	// Some special types
    static Type tshiftcnt()
	{
		return tint32;		// right side of shift expression
	}

//    #define tboolean	tint32		// result of boolean expression
    static Type tboolean()
	{
		return tbool;		// result of boolean expression
	}

    static Type tindex()
	{
		return tint32;		// array/ptr index
	}

	static Type terror()
	{
		return basic[TY.Terror];	// for error recovery
	}

    static Type tsize_t()
	{
		return basic[Tsize_t];		// matches size_t alias
	}

    static Type tptrdiff_t()
	{
		return basic[Tptrdiff_t];	// matches ptrdiff_t alias
	}

    static Type thash_t()
	{
		return tsize_t;			// matches hash_t alias
	}
}
