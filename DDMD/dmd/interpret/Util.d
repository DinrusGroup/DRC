module dmd.interpret.Util;

import dmd.common;
import dmd.StructDeclaration;
import dmd.Expression;
import dmd.FuncDeclaration;
import dmd.InterState;
import dmd.ArrayTypes;
import dmd.StringExp;
import dmd.GlobalExpressions;
import dmd.TOK;
import dmd.AssocArrayLiteralExp;
import dmd.IntegerExp;
import dmd.Id;
import dmd.Type;
import dmd.Declaration;
import dmd.Loc;
import dmd.ArrayLiteralExp;
import dmd.TypeAArray;
import dmd.TypeFunction;
import dmd.TypeSArray;
import dmd.TY;
import dmd.STC;
import dmd.SymbolDeclaration;
import dmd.StructLiteralExp;
import dmd.VarDeclaration;
import dmd.Util;

import core.memory;
import core.stdc.string;

version(DMDV1)
{
Expression interpret_aaLen(InterState istate, Expressions arguments)
{
	if (!arguments || arguments.dim != 1)
		return null;
	auto earg = arguments[0];
	earg = earg.interpret(istate);
	if (earg is EXP_CANT_INTERPRET)
		return null;
	if (earg.op != TOKassocarrayliteral)
		return null;
	auto aae = cast(AssocArrayLiteralExp)earg;
	auto e = new IntegerExp(aae.loc, aae.keys.dim, Type.tsize_t);
	return e;
}

Expression interpret_aaKeys(InterState istate, Expressions arguments)
{
version (LOG) {
	writef("interpret_aaKeys()\n");
}
	if (!arguments || arguments.dim != 2)
		return null;
	auto earg = arguments[0];
	earg = earg.interpret(istate);
	if (earg is EXP_CANT_INTERPRET)
		return null;
	if (earg.op != TOKassocarrayliteral)
		return null;
	auto aae = cast(AssocArrayLiteralExp)earg;
	auto e = new ArrayLiteralExp(aae.loc, aae.keys);
	Type elemType = (cast(TypeAArray)aae.type).index;
	e.type = new TypeSArray(elemType, new IntegerExp(arguments ? arguments.dim : 0));
	return e;
}

Expression interpret_aaValues(InterState istate, Expressions arguments)
{
	//writef("interpret_aaValues()\n");
	if (!arguments || arguments.dim != 3)
		return null;
	auto earg = arguments[0];
	earg = earg.interpret(istate);
	if (earg is EXP_CANT_INTERPRET)
		return null;
	if (earg.op != TOKassocarrayliteral)
		return null;
	auto aae = cast(AssocArrayLiteralExp)earg;
	auto e = new ArrayLiteralExp(aae.loc, aae.values);
	Type elemType = (cast(TypeAArray)aae.type).next;
	e.type = new TypeSArray(elemType, new IntegerExp(arguments ? arguments.dim : 0));
	//writef("result is %s\n", e.toChars());
	return e;
}
}
else version(DMDV2)
{
Expression interpret_length(InterState istate, Expression earg)
{
//	writef("interpret_length()\n");
	earg = earg.interpret(istate);
	if (earg == EXP_CANT_INTERPRET)
		return null;
	if (earg.op != TOKassocarrayliteral)
		return null;
	AssocArrayLiteralExp aae = cast(AssocArrayLiteralExp)earg;
	Expression e = new IntegerExp(aae.loc, aae.keys.dim, Type.tsize_t);
	return e;
}

Expression interpret_keys(InterState istate, Expression earg, FuncDeclaration fd)
{
version(LOG)
	writef("interpret_keys()\n");

	earg = earg.interpret(istate);
	if (earg == EXP_CANT_INTERPRET)
	return null;
	if (earg.op != TOKassocarrayliteral)
	return null;
	AssocArrayLiteralExp aae = cast(AssocArrayLiteralExp)earg;
	Expression e = new ArrayLiteralExp(aae.loc, aae.keys);
	assert(fd.type.ty == Tfunction);
	assert(fd.type.nextOf().ty == Tarray);
	Type elemType = (cast(TypeFunction)fd.type).nextOf().nextOf();
	e.type = new TypeSArray(elemType, new IntegerExp(aae.keys.dim));
	return e;
}
Expression interpret_values(InterState istate, Expression earg, FuncDeclaration fd)
{
	//writef("interpret_values()\n");
	earg = earg.interpret(istate);
	if (earg == EXP_CANT_INTERPRET)
		return null;
	if (earg.op != TOKassocarrayliteral)
		return null;
	AssocArrayLiteralExp aae = cast(AssocArrayLiteralExp)earg;
	Expression e = new ArrayLiteralExp(aae.loc, aae.values);
	assert(fd.type.ty == Tfunction);
	assert(fd.type.nextOf().ty == Tarray);
	Type elemType = (cast(TypeFunction)fd.type).nextOf().nextOf();
	e.type = new TypeSArray(elemType, new IntegerExp(aae.values.dim));
	//writef("result is %s\n", e.toChars());
	return e;
}
}

Expression getVarExp(Loc loc, InterState istate, Declaration d)
{
	Expression e = EXP_CANT_INTERPRET;
	VarDeclaration v = d.isVarDeclaration();
	SymbolDeclaration s = d.isSymbolDeclaration();
	if (v)
	{
///version (DMDV2) {
		/* Magic variable __ctfe always returns true when interpreting
		 */
		if (v.ident == Id.ctfe)
			return new IntegerExp(loc, 1, Type.tbool);

		if ((v.isConst() || v.isImmutable() || v.storage_class & STCmanifest) && v.init && !v.value)
///} else {
///	if (v.isConst() && v.init)
///}
		{
			e = v.init.toExpression();
			if (e && !e.type)
				e.type = v.type;
		}
		else if (v.isCTFE() && !v.value)
		{
			if (v.init)
			{
				e = v.init.toExpression();
				e = e.interpret(istate);
			}
			else // This should never happen
				e = v.type.defaultInitLiteral(Loc(0));
		}

		else
		{
			e = v.value;
			if (!v.isCTFE())
			{
				error(loc, "static variable %s cannot be read at compile time", v.toChars());
				e = EXP_CANT_INTERPRET;
			}
			else if (!e)
				error(loc, "variable %s is used before initialization", v.toChars());
			else if (e !is EXP_CANT_INTERPRET)
				e = e.interpret(istate);
		}
		if (!e)
			e = EXP_CANT_INTERPRET;
	}
	else if (s)
	{
		if (s.dsym.toInitializer() == s.sym)
		{
			Expressions exps = new Expressions();
			e = new StructLiteralExp(Loc(0), s.dsym, exps);
			e = e.semantic(null);
		}
	}
	return e;
}

/* Helper functions for BinExp.interpretAssignCommon
 */

/***************************************
 * Duplicate the elements array, then set field 'indexToChange' = newelem.
 */
Expressions changeOneElement(Expressions oldelems, size_t indexToChange, Expression newelem)
{
	auto expsx = new Expressions();
	expsx.setDim(oldelems.dim);
	for (size_t j = 0; j < expsx.dim; j++)
	{
		if (j == indexToChange)
			expsx[j] = newelem;
		else
			expsx[j] = oldelems[j];
	}
	return expsx;
}

/***************************************
 * Returns oldelems[0..insertpoint] ~ newelems ~ oldelems[insertpoint+newelems.length..$]
 */
Expressions spliceElements(Expressions oldelems, Expressions newelems, size_t insertpoint)
{
	auto expsx = new Expressions();
	expsx.setDim(oldelems.dim);
	for (size_t j = 0; j < expsx.dim; j++)
	{
		if (j >= insertpoint && j < insertpoint + newelems.dim)
			expsx[j] = newelems[j - insertpoint];
		else
			expsx[j] = oldelems[j];
	}
	return expsx;
}

/***************************************
 * Returns oldstr[0..insertpoint] ~ newstr ~ oldstr[insertpoint+newlen..$]
 */
StringExp spliceStringExp(StringExp oldstr, StringExp newstr, size_t insertpoint)
{
    assert(oldstr.sz==newstr.sz);
    char* s;
    size_t oldlen = oldstr.len;
    size_t newlen = newstr.len;
    size_t sz = oldstr.sz;
    s = cast(char*)GC.calloc(oldlen + 1, sz);
    memcpy(s, oldstr.string_, oldlen * sz);
    memcpy(s + insertpoint * sz, newstr.string_, newlen * sz);
    StringExp se2 = new StringExp(oldstr.loc, cast(string)s[0..oldlen]);
    se2.committed = oldstr.committed;
    se2.postfix = oldstr.postfix;
    se2.type = oldstr.type;
    return se2;
}

/******************************
 * Create a string literal consisting of 'value' duplicated 'dim' times.
 */
StringExp createBlockDuplicatedStringLiteral(Type type, dchar value, size_t dim, int sz)
{
    char* s;
    s = cast(char*)GC.calloc(dim + 1, sz);
    for (int elemi = 0; elemi < dim; ++elemi)
    {
    	switch (sz)
		{
			case 1:	s[elemi] = cast(char)value; break;
			case 2:	(cast(wchar*)s)[elemi] = cast(wchar)value; break;
			case 4:	(cast(dchar*)s)[elemi] = value; break;
			default:    assert(0);
		}
    }
    StringExp se = new StringExp(Loc(0), cast(string)s[0..dim]);
    se.type = type;
    return se;
}

/******************************
 * Create an array literal consisting of 'elem' duplicated 'dim' times.
 */
ArrayLiteralExp createBlockDuplicatedArrayLiteral(Type type, Expression elem, size_t dim)
{
	auto elements = new Expressions();
	elements.setDim(dim);
	for (size_t i = 0; i < dim; i++) {
		elements[i] = elem;
	}
	
	auto ae = new ArrayLiteralExp(Loc(0), elements);
	ae.type = type;
	return ae;
}


/********************************
 *  Add v to the istate list, unless it already exists there.
 */
void addVarToInterstate(InterState istate, VarDeclaration v)
{
	if (!v.isParameter())
	{
		for (size_t i = 0; 1; i++)
		{
			if (i == istate.vars.dim)
			{   
				istate.vars.push(v);
				//writef("\tadding %s to istate\n", v.toChars());
				break;
			}
			if (v == cast(VarDeclaration)istate.vars[i])
				break;
		}
	}
}