module dmd.TemplateThisParameter;

import dmd.common;
import dmd.TemplateTypeParameter;
import dmd.Type;
import dmd.Loc;
import dmd.Identifier;
import dmd.TemplateParameter;
import dmd.OutBuffer;
import dmd.HdrGenState;

import dmd.DDMDExtensions;

class TemplateThisParameter : TemplateTypeParameter
{
	mixin insertMemberExtension!(typeof(this));

    /* Syntax:
     *	this ident : specType = defaultType
     */
    Type specType;	// type parameter: if !=NULL, this is the type specialization
    Type defaultType;

    this(Loc loc, Identifier ident, Type specType, Type defaultType)
	{
		register();
		super(loc, ident, specType, defaultType);
	}

    override TemplateThisParameter isTemplateThisParameter()
	{	
		return this;
	}
	
    override TemplateParameter syntaxCopy()
	{
		TemplateThisParameter tp = new TemplateThisParameter(loc, ident, specType, defaultType);
		if (tp.specType)
			tp.specType = specType.syntaxCopy();
		if (defaultType)
			tp.defaultType = defaultType.syntaxCopy();
		return tp;
	}
	
    override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("this ");
		super.toCBuffer(buf, hgs);
	}
}
