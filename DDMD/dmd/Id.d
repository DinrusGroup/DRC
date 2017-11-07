module dmd.Id;

import dmd.common;
import dmd.Identifier;
import dmd.Lexer;

private string idgen(T...)(T ts)
{
	string res = "struct Ids\n{\n";

	foreach(entry; ts)
		res ~= "\tstatic __gshared Identifier " ~ entry.ident ~ ";\n";
	
	res ~= "\tstatic void initialize()\n\t{\n";
	string tmp;
	foreach (entry; ts)
	{
		if (entry.name_ is null)
			tmp = entry.ident;
		else
			tmp = entry.name_;
		res ~= "\t\tId." ~ entry.ident ~ ` = Lexer.idPool("` ~ tmp ~ "\");\n";
	}

		res ~= "\t}\n}";
	return res;
}

private struct ID
{
	string ident;		// name to use in DMD source
	string name_;	// name in D executable
}

mixin(idgen(
		ID( "IUnknown" ),
		ID( "Object_", "Object" ),
		ID( "object" ),
		ID( "max" ),
		ID( "min" ),
		ID( "This", "this" ),
		ID( "ctor", "__ctor" ),
		ID( "dtor", "__dtor" ),
		ID( "cpctor", "__cpctor" ),
		ID( "_postblit", "__postblit" ),
		ID( "classInvariant", "__invariant" ),
		ID( "unitTest", "__unitTest" ),
		ID( "require", "__require" ),
		ID( "ensure", "__ensure" ),
		ID( "init_", "init" ),
		ID( "size" ),
		ID( "__sizeof", "sizeof" ),
		ID( "alignof_", "alignof" ),
		ID( "mangleof_", "mangleof" ),
		ID( "stringof_", "stringof" ),
		ID( "tupleof_", "tupleof" ),
		ID( "length" ),
		ID( "remove" ),
		ID( "ptr" ),
		ID( "funcptr" ),
		ID( "dollar", "__dollar" ),
		ID( "ctfe", "__ctfe" ),
		ID( "offset" ),
		ID( "offsetof" ),
		ID( "ModuleInfo" ),
		ID( "ClassInfo" ),
		ID( "classinfo_", "classinfo" ),
		ID( "typeinfo_", "typeinfo" ),
		ID( "outer" ),
		ID( "Exception" ),
		ID( "AssociativeArray" ),
		ID( "Throwable" ),
		ID( "withSym", "__withSym" ),
		ID( "result", "__result" ),
		ID( "returnLabel", "__returnLabel" ),
		ID( "delegate_", "delegate" ),
		ID( "line" ),
		ID( "empty", "" ),
		ID( "p" ),
		ID( "coverage", "__coverage" ),
		ID( "__vptr" ),
		ID( "__monitor" ),

		ID( "TypeInfo" ),
		ID( "TypeInfo_Class" ),
		ID( "TypeInfo_Interface" ),
		ID( "TypeInfo_Struct" ),
		ID( "TypeInfo_Enum" ),
		ID( "TypeInfo_Typedef" ),
		ID( "TypeInfo_Pointer" ),
		ID( "TypeInfo_Array" ),
		ID( "TypeInfo_StaticArray" ),
		ID( "TypeInfo_AssociativeArray" ),
		ID( "TypeInfo_Function" ),
		ID( "TypeInfo_Delegate" ),
		ID( "TypeInfo_Tuple" ),
		ID( "TypeInfo_Const" ),
		ID( "TypeInfo_Invariant" ),
		ID( "TypeInfo_Shared" ),
        ID( "TypeInfo_Wild", "TypeInfo_Inout" ),
            
		ID( "elements" ),
		ID( "_arguments_typeinfo" ),
		ID( "_arguments" ),
		ID( "_argptr" ),
		ID( "_match" ),
		ID( "destroy" ),

		ID( "LINE", "__LINE__" ),
		ID( "FILE", "__FILE__" ),
		ID( "DATE", "__DATE__" ),
		ID( "TIME", "__TIME__" ),
		ID( "TIMESTAMP", "__TIMESTAMP__" ),
		ID( "VENDOR", "__VENDOR__" ),
		ID( "VERSIONX", "__VERSION__" ),
		ID( "EOFX", "__EOF__" ),

		ID( "nan" ),
		ID( "infinity" ),
		ID( "dig" ),
		ID( "epsilon" ),
		ID( "mant_dig" ),
		ID( "max_10_exp" ),
		ID( "max_exp" ),
		ID( "min_10_exp" ),
		ID( "min_exp" ),
		ID( "min_normal" ),
		ID( "re" ),
		ID( "im" ),

		ID( "C" ),
		ID( "D" ),
		ID( "Windows" ),
		ID( "Pascal" ),
		ID( "System" ),

		ID( "exit" ),
		ID( "success" ),
		ID( "failure" ),

		ID( "keys" ),
		ID( "values" ),
		ID( "rehash" ),

		ID( "sort" ),
		ID( "reverse" ),
		ID( "dup" ),
		ID( "idup" ),

		ID( "property" ),
        ID( "safe" ),
        ID( "trusted" ),
        ID( "system" ),
        ID( "disable" ),

		// For inline assembler
		ID( "___out", "out" ),
		ID( "___in", "in" ),
		ID( "__int", "int" ),
		ID( "__dollar", "$" ),
		ID( "__LOCAL_SIZE" ),

		// For operator overloads
		ID( "uadd",	 "opPos" ),
		ID( "neg",	 "opNeg" ),
		ID( "com",	 "opCom" ),
		ID( "add",	 "opAdd" ),
		ID( "add_r",   "opAdd_r" ),
		ID( "sub",	 "opSub" ),
		ID( "sub_r",   "opSub_r" ),
		ID( "mul",	 "opMul" ),
		ID( "mul_r",   "opMul_r" ),
		ID( "div",	 "opDiv" ),
		ID( "div_r",   "opDiv_r" ),
		ID( "mod",	 "opMod" ),
		ID( "mod_r",   "opMod_r" ),
		ID( "eq",	  "opEquals" ),
		ID( "cmp",	 "opCmp" ),
		ID( "iand",	"opAnd" ),
		ID( "iand_r",  "opAnd_r" ),
		ID( "ior",	 "opOr" ),
		ID( "ior_r",   "opOr_r" ),
		ID( "ixor",	"opXor" ),
		ID( "ixor_r",  "opXor_r" ),
		ID( "shl",	 "opShl" ),
		ID( "shl_r",   "opShl_r" ),
		ID( "shr",	 "opShr" ),
		ID( "shr_r",   "opShr_r" ),
		ID( "ushr",	"opUShr" ),
		ID( "ushr_r",  "opUShr_r" ),
		ID( "cat",	 "opCat" ),
		ID( "cat_r",   "opCat_r" ),
		ID( "assign",  "opAssign" ),
		ID( "addass",  "opAddAssign" ),
		ID( "subass",  "opSubAssign" ),
		ID( "mulass",  "opMulAssign" ),
		ID( "divass",  "opDivAssign" ),
		ID( "modass",  "opModAssign" ),
		ID( "andass",  "opAndAssign" ),
		ID( "orass",   "opOrAssign" ),
		ID( "xorass",  "opXorAssign" ),
		ID( "shlass",  "opShlAssign" ),
		ID( "shrass",  "opShrAssign" ),
		ID( "ushrass", "opUShrAssign" ),
		ID( "catass",  "opCatAssign" ),
		ID( "postinc", "opPostInc" ),
		ID( "postdec", "opPostDec" ),
		ID( "index",	 "opIndex" ),
		ID( "indexass", "opIndexAssign" ),
		ID( "slice",	 "opSlice" ),
		ID( "sliceass", "opSliceAssign" ),
		ID( "call",	 "opCall" ),
		ID( "cast_",	 "opCast" ),
		ID( "match",	 "opMatch" ),
		ID( "next",	 "opNext" ),
		ID( "opIn" ),
		ID( "opIn_r" ),
		ID( "opStar" ),
		ID( "opDot" ),
        ID( "opDispatch" ),
		ID( "opImplicitCast" ),
        ID( "pow", "opPow" ),
        ID( "pow_r", "opPow_r" ),
        ID( "powass", "opPowAssign" ),
    
		ID( "classNew", "new" ),
		ID( "classDelete", "delete" ),

		// For foreach
		ID( "apply", "opApply" ),
		ID( "applyReverse", "opApplyReverse" ),

//		#if 1
		ID( "Fempty", "empty" ),
		ID( "Fhead", "front" ),
		ID( "Ftoe", "back" ),
		ID( "Fnext", "popFront" ),
		ID( "Fretreat", "popBack" ),
	/*#else
		ID( "Fempty", "empty" ),
		ID( "Fhead", "head" ),
		ID( "Ftoe", "toe" ),
		ID( "Fnext", "next" ),
		ID( "Fretreat", "retreat" ),
	#endif*/

		ID( "adDup", "_adDupT" ),
		ID( "adReverse", "_adReverse" ),

		// For internal functions
		ID( "aaLen", "_aaLen" ),
		ID( "aaKeys", "_aaKeys" ),
		ID( "aaValues", "_aaValues" ),
		ID( "aaRehash", "_aaRehash" ),
		ID( "monitorenter", "_d_monitorenter" ),
		ID( "monitorexit", "_d_monitorexit" ),
		ID( "criticalenter", "_d_criticalenter" ),
		ID( "criticalexit", "_d_criticalexit" ),

		// For pragma's
		ID( "GNU_asm" ),
		ID( "lib" ),
		ID( "msg" ),
		ID( "startaddress" ),

		// For special functions
		ID( "tohash", "toHash" ),
		ID( "tostring", "toString" ),
		ID( "getmembers", "getMembers" ),

		// Special functions
		ID( "alloca" ),
		ID( "main" ),
		ID( "WinMain" ),
		ID( "DllMain" ),
		ID( "tls_get_addr", "___tls_get_addr" ),

		// Builtin functions
		ID( "std" ),
		ID( "math" ),
		ID( "sin" ),
		ID( "cos" ),
		ID( "tan" ),
		ID( "_sqrt", "sqrt" ),
        ID( "_pow", "pow" ),
		ID( "fabs" ),

		// Traits
		ID( "isAbstractClass" ),
		ID( "isArithmetic" ),
		ID( "isAssociativeArray" ),
		ID( "isFinalClass" ),
		ID( "isFloating" ),
		ID( "isIntegral" ),
		ID( "isScalar" ),
		ID( "isStaticArray" ),
		ID( "isUnsigned" ),
		ID( "isVirtualFunction" ),
		ID( "isAbstractFunction" ),
		ID( "isFinalFunction" ),
		ID( "isStaticFunction" ),
        ID( "isRef" ),
        ID( "isOut" ),
        ID( "isLazy" ),
		ID( "hasMember" ),
		ID( "identifier" ),
		ID( "getMember" ),
		ID( "getOverloads" ),
		ID( "getVirtualFunctions" ),
		ID( "classInstanceSize" ),
		ID( "allMembers" ),
		ID( "derivedMembers" ),
		ID( "isSame" ),
		ID( "compiles" )
	));
	
__gshared Ids Id;