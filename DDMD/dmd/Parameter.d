module dmd.Parameter;

import dmd.common;
import dmd.Type;
import dmd.Identifier;
import dmd.TypeArray;
import dmd.TypeFunction;
import dmd.TypeDelegate;
import dmd.TypeTuple;
import dmd.TY;
import dmd.Expression;
import dmd.OutBuffer;
import dmd.HdrGenState;
import dmd.ArrayTypes;
import dmd.StorageClassDeclaration;
import dmd.Global;
import dmd.MOD;
import dmd.CppMangleState;
import dmd.STC;

import dmd.TObject;

import dmd.DDMDExtensions;

class Parameter : TObject
{
	mixin insertMemberExtension!(typeof(this));

    //enum InOut inout;
    StorageClass storageClass;
    Type type;
    Identifier ident;
    Expression defaultArg;

    this(StorageClass storageClass, Type type, Identifier ident, Expression defaultArg)
	{
		register();
		this.type = type;
		this.ident = ident;
		this.storageClass = storageClass;
		this.defaultArg = defaultArg;
	}
	
	Parameter clone()
	{
		return new Parameter(storageClass, type, ident, defaultArg);
	}
	
    Parameter syntaxCopy()
	{
		return new Parameter(storageClass, type ? type.syntaxCopy() : null, ident, defaultArg ? defaultArg.syntaxCopy() : null);
	}
	
	/****************************************************
	 * Determine if parameter is a lazy array of delegates.
	 * If so, return the return type of those delegates.
	 * If not, return null.
	 */
    Type isLazyArray()
	{
	//    if (inout == Lazy)
		{
			Type tb = type.toBasetype();
			if (tb.ty == Tsarray || tb.ty == Tarray)
			{
				Type tel = (cast(TypeArray)tb).next.toBasetype();
				if (tel.ty == Tdelegate)
				{
					TypeDelegate td = cast(TypeDelegate)tel;
					TypeFunction tf = cast(TypeFunction)td.next;

					if (!tf.varargs && Parameter.dim(tf.parameters) == 0)
					{
						return tf.next;	// return type of delegate
					}
				}
			}
		}
		return null;
	}
	
    void toDecoBuffer(OutBuffer buf)
	{
		if (storageClass & STC.STCscope)
			buf.writeByte('M');
		switch (storageClass & (STC.STCin | STC.STCout | STC.STCref | STC.STClazy))
		{   
			case STC.STCundefined:
			case STC.STCin:
				break;
			case STC.STCout:
				buf.writeByte('J');
				break;
			case STC.STCref:
				buf.writeByte('K');
				break;
			case STC.STClazy:
				buf.writeByte('L');
				break;
			default:
				assert(false);
		}
static if (false) {
		int mod = 0x100;
		if (type.toBasetype().ty == TY.Tclass)
			mod = 0;
		type.toDecoBuffer(buf, mod);
} else {
		//type.toHeadMutable().toDecoBuffer(buf, 0);
		type.toDecoBuffer(buf, 0);
}
	}
	
    static Parameters arraySyntaxCopy(Parameters args)
	{
		typeof(return) a = null;

		if (args)
		{
			a = new Parameters();
			a.setDim(args.dim);

			for (size_t i = 0; i < a.dim; i++)
			{   
				auto arg = args[i];

				arg = arg.syntaxCopy();
				a[i] = arg;
			}
		}
	
		return a;
	}
	
    static string argsTypesToChars(Parameters args, int varargs)
	{
		scope OutBuffer buf = new OutBuffer();

	static if (true) {
		HdrGenState hgs;
		argsToCBuffer(buf, &hgs, args, varargs);
	} else {
		buf.writeByte('(');
		if (args)
		{	
			OutBuffer argbuf = new OutBuffer();
			HdrGenState hgs;

			for (int i = 0; i < args.dim; i++)
			{   
				if (i)
					buf.writeByte(',');
				auto arg = cast(Parameter)args.data[i];
				argbuf.reset();
				arg.type.toCBuffer2(&argbuf, &hgs, 0);
				buf.write(&argbuf);
			}
			if (varargs)
			{
				if (i && varargs == 1)
					buf.writeByte(',');
				buf.writestring("...");
			}
		}
		buf.writeByte(')');
	}
		return buf.toChars();
	}
	
    static void argsCppMangle(OutBuffer buf, CppMangleState* cms, Parameters arguments, int varargs)
	{
		assert(false);
	}
	
    static void argsToCBuffer(OutBuffer buf, HdrGenState* hgs, Parameters arguments, int varargs)
	{
		buf.writeByte('(');
		if (arguments)
		{	
			int i;
			scope OutBuffer argbuf = new OutBuffer();

			for (i = 0; i < arguments.dim; i++)
			{
				if (i)
					buf.writestring(", ");
				auto arg = arguments[i];

	            if (arg.storageClass & STCauto)
		            buf.writestring("auto ");

				if (arg.storageClass & STCout)
					buf.writestring("out ");
				else if (arg.storageClass & STCref)
					buf.writestring((global.params.Dversion == 1) ? "inout " : "ref ");
				else if (arg.storageClass & STCin)
					buf.writestring("in ");
				else if (arg.storageClass & STClazy)
					buf.writestring("lazy ");
				else if (arg.storageClass & STCalias)
					buf.writestring("alias ");

				StorageClass stc = arg.storageClass;
				if (arg.type && arg.type.mod & MODshared)
					stc &= ~STCshared;

				StorageClassDeclaration.stcToCBuffer(buf, stc & (STCconst | STCimmutable | STCshared | STCscope));

				argbuf.reset();
				if (arg.storageClass & STCalias)
				{	
					if (arg.ident)
						argbuf.writestring(arg.ident.toChars());
				}
				else
					arg.type.toCBuffer(argbuf, arg.ident, hgs);
				if (arg.defaultArg)
				{
					argbuf.writestring(" = ");
					arg.defaultArg.toCBuffer(argbuf, hgs);
				}
				buf.write(argbuf);
			}
			if (varargs)
			{
				if (i && varargs == 1)
					buf.writeByte(',');
				buf.writestring("...");
			}
		}
		buf.writeByte(')');
	}
	
    static void argsToDecoBuffer(OutBuffer buf, Parameters arguments)
	{
		//printf("Parameter::argsToDecoBuffer()\n");

		// Write argument types
		if (arguments)
		{
			size_t dim = Parameter.dim(arguments);
			for (size_t i = 0; i < dim; i++)
			{
				auto arg = Parameter.getNth(arguments, i);
				arg.toDecoBuffer(buf);
			}
		}
	}
	
    static int isTPL(Parameters arguments)
	{
		assert(false);
	}

	/***************************************
	 * Determine number of arguments, folding in tuples.
	 */	
    static size_t dim(Parameters args)
	{
		size_t n = 0;
		if (args)
		{
			foreach (arg; args)
			{   
				Type t = arg.type.toBasetype();

				if (t.ty == TY.Ttuple)
				{   
					auto tu = cast(TypeTuple)t;
					n += dim(tu.arguments);
				}
				else
					n++;
			}
		}
		return n;
	}
	
	/***************************************
	 * Get nth Parameter, folding in tuples.
	 * Returns:
	 *	Parameter	nth Parameter
	 *	null		not found, *pn gets incremented by the number
	 *			of Parameters
	 */
    static Parameter getNth(Parameters args, size_t nth, size_t* pn = null)
	{
		if (!args)
			return null;

		size_t n = 0;
		foreach (arg; args)
		{   
			Type t = arg.type.toBasetype();

			if (t.ty == TY.Ttuple)
			{   TypeTuple tu = cast(TypeTuple)t;
				arg = getNth(tu.arguments, nth - n, &n);
				if (arg)
					return arg;
			}
			else if (n == nth)
				return arg;
			else
				n++;
		}

		if (pn)
			*pn += n;

		return null;
	}
}
