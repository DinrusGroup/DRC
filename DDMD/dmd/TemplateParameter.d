module dmd.TemplateParameter;

import dmd.common;
import dmd.Loc;
import dmd.Identifier;
import dmd.Declaration;
import dmd.TemplateTypeParameter;
import dmd.TemplateValueParameter;
import dmd.TemplateAliasParameter;
import dmd.TemplateThisParameter;
import dmd.TemplateTupleParameter;
import dmd.Scope;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.MATCH;
import dmd.ArrayTypes;
import dmd.Array;

import dmd.TObject;

import dmd.DDMDExtensions;

class TemplateParameter : TObject
{
	mixin insertMemberExtension!(typeof(this));

    /* For type-parameter:
     *	template Foo(ident)		// specType is set to NULL
     *	template Foo(ident : specType)
     * For value-parameter:
     *	template Foo(valType ident)	// specValue is set to NULL
     *	template Foo(valType ident : specValue)
     * For alias-parameter:
     *	template Foo(alias ident)
     * For this-parameter:
     *	template Foo(this ident)
     */

    Loc loc;
    Identifier ident;

    Declaration sparam;

    this(Loc loc, Identifier ident)
	{
		register();
		this.loc = loc;
		this.ident = ident;
	}

    TemplateTypeParameter isTemplateTypeParameter()
	{
		return null;
	}
	
    TemplateValueParameter isTemplateValueParameter()
	{
		return null; 
	}
	
    TemplateAliasParameter isTemplateAliasParameter()
	{
		return null; 
	}
	
version (DMDV2) {
    TemplateThisParameter isTemplateThisParameter()
	{
		return null; 
	}
}
    TemplateTupleParameter isTemplateTupleParameter()
	{
		return null;
	}

    abstract TemplateParameter syntaxCopy();
    abstract void declareParameter(Scope sc);
    abstract void semantic(Scope);
    abstract void print(Object oarg, Object oded);
    abstract void toCBuffer(OutBuffer buf, HdrGenState* hgs);
    abstract Object specialization();
    abstract Object defaultArg(Loc loc, Scope sc);

    /* If TemplateParameter's match as far as overloading goes.
     */
    abstract bool overloadMatch(TemplateParameter);

    /* Match actual argument against parameter.
     */
    abstract MATCH matchArg(Scope sc, Objects tiargs, int i, TemplateParameters parameters, Objects dedtypes, Declaration* psparam, int flags = 0);

    /* Create dummy argument based on parameter.
     */
    abstract Object dummyArg();
}