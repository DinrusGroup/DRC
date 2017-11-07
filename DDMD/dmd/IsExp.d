module dmd.IsExp;

import dmd.common;
import dmd.Expression;
import dmd.Identifier;
import dmd.ArrayTypes;
import dmd.Type;
import dmd.TOK;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.HdrGenState;
import dmd.TY;
import dmd.TypeEnum;
import dmd.STC;
import dmd.TypeClass;
import dmd.TemplateParameter;
import dmd.BaseClass;
import dmd.ClassDeclaration;
import dmd.TypeStruct;
import dmd.TypeTypedef;
import dmd.IntegerExp;
import dmd.AliasDeclaration;
import dmd.Dsymbol;
import dmd.TypeTuple;
import dmd.TypeDelegate;
import dmd.Declaration;
import dmd.TypeFunction;
import dmd.MATCH;
import dmd.TypePointer;
import dmd.Parameter;
import dmd.Token;

import dmd.DDMDExtensions;

class IsExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	/* is(targ id tok tspec)
     * is(targ id == tok2)
     */
    Type targ;
    Identifier id;	// can be null
    TOK tok;	// ':' or '=='
    Type tspec;	// can be null
    TOK tok2;	// 'struct', 'union', 'typedef', etc.
    TemplateParameters parameters;

	this(Loc loc, Type targ, Identifier id, TOK tok, Type tspec, TOK tok2, TemplateParameters parameters)
	{
		register();
		super(loc, TOK.TOKis, IsExp.sizeof);
		
		this.targ = targ;
		this.id = id;
		this.tok = tok;
		this.tspec = tspec;
		this.tok2 = tok2;
		this.parameters = parameters;
	}

	override Expression syntaxCopy()
	{
		// This section is identical to that in TemplateDeclaration.syntaxCopy()
		TemplateParameters p = null;
		if (parameters)
		{
			p = new TemplateParameters();
			p.setDim(parameters.dim);
			for (int i = 0; i < p.dim; i++)
			{   
				auto tp = parameters[i];
				p[i] = tp.syntaxCopy();
			}
		}

		return new IsExp(loc,
		targ.syntaxCopy(),
		id,
		tok,
		tspec ? tspec.syntaxCopy() : null,
		tok2,
		p);
	}

	override Expression semantic(Scope sc)
	{
		Type tded;

		/* is(targ id tok tspec)
		 * is(targ id :  tok2)
		 * is(targ id == tok2)
		 */

		//printf("IsExp.semantic(%s)\n", toChars());
		if (id && !(sc.flags & SCOPE.SCOPEstaticif))
			error("can only declare type aliases within static if conditionals");

		Type t = targ.trySemantic(loc, sc);
		if (!t)
			goto Lno;			// errors, so condition is false
		targ = t;
		if (tok2 != TOK.TOKreserved)
		{
			switch (tok2)
			{
				case TOKtypedef:
					if (targ.ty != Ttypedef)
						goto Lno;
					tded = (cast(TypeTypedef)targ).sym.basetype;
					break;

				case TOKstruct:
					if (targ.ty != Tstruct)
						goto Lno;
					if ((cast(TypeStruct)targ).sym.isUnionDeclaration())
						goto Lno;
					tded = targ;
					break;

				case TOKunion:
					if (targ.ty != Tstruct)
						goto Lno;
					if (!(cast(TypeStruct)targ).sym.isUnionDeclaration())
						goto Lno;
					tded = targ;
					break;

				case TOKclass:
					if (targ.ty != Tclass)
						goto Lno;
					if ((cast(TypeClass)targ).sym.isInterfaceDeclaration())
						goto Lno;
					tded = targ;
					break;

				case TOKinterface:
					if (targ.ty != Tclass)
						goto Lno;
					if (!(cast(TypeClass)targ).sym.isInterfaceDeclaration())
						goto Lno;
					tded = targ;
					break;
		version (DMDV2) {
				case TOKconst:
					if (!targ.isConst())
						goto Lno;
					tded = targ;
					break;

				case TOKinvariant:
				case TOKimmutable:
					if (!targ.isImmutable())
						goto Lno;
					tded = targ;
					break;

				case TOKshared:
					if (!targ.isShared())
            		    goto Lno;
            		tded = targ;
		            break;

        	    case TOKwild:
		            if (!targ.isWild())
						goto Lno;
					tded = targ;
					break;
		}

				case TOKsuper:
					// If class or interface, get the base class and interfaces
					if (targ.ty != Tclass)
						goto Lno;
					else
					{   ClassDeclaration cd = (cast(TypeClass)targ).sym;
						auto args = new Parameters;
						args.reserve(cd.baseclasses.dim);
						foreach (b; cd.baseclasses)
						{	
							args.push(new Parameter(STCin, b.type, null, null));
						}
						tded = new TypeTuple(args);
					}
					break;

				case TOKenum:
					if (targ.ty != Tenum)
						goto Lno;
					tded = (cast(TypeEnum)targ).sym.memtype;
					break;

				case TOKdelegate:
					if (targ.ty != Tdelegate)
						goto Lno;
					tded = (cast(TypeDelegate)targ).next;	// the underlying function type
					break;

				case TOKfunction:
				{
					if (targ.ty != Tfunction)
						goto Lno;
					tded = targ;

					/* Generate tuple from function parameter types.
					 */
					assert(tded.ty == Tfunction);
					auto params = (cast(TypeFunction)tded).parameters;
					size_t dim = Parameter.dim(params);
					auto args = new Parameters;
					args.reserve(dim);
					for (size_t i = 0; i < dim; i++)
					{   
						auto arg = Parameter.getNth(params, i);
						assert(arg && arg.type);
						args.push(new Parameter(arg.storageClass, arg.type, null, null));
					}
					tded = new TypeTuple(args);
					break;
				}
				
				case TOKreturn:
					/* Get the 'return type' for the function,
					 * delegate, or pointer to function.
					 */
					if (targ.ty == Tfunction)
						tded = (cast(TypeFunction)targ).next;
					else if (targ.ty == Tdelegate)
					{   tded = (cast(TypeDelegate)targ).next;
						tded = (cast(TypeFunction)tded).next;
					}
					else if (targ.ty == Tpointer &&
						 (cast(TypePointer)targ).next.ty == Tfunction)
					{   tded = (cast(TypePointer)targ).next;
						tded = (cast(TypeFunction)tded).next;
					}
					else
						goto Lno;
					break;

				default:
					assert(0);
			}
			goto Lyes;
		}
		else if (id && tspec)
		{
			/* Evaluate to true if targ matches tspec.
			 * If true, declare id as an alias for the specialized type.
			 */

			assert(parameters && parameters.dim);

			scope dedtypes = new Objects();
			dedtypes.setDim(parameters.dim);
			dedtypes.zero();

			MATCH m = targ.deduceType(null, tspec, parameters, dedtypes);
			if (m == MATCHnomatch ||
				(m != MATCHexact && tok == TOKequal))
			{
				goto Lno;
			}
			else
			{
				tded = cast(Type)dedtypes[0];
				if (!tded)
				tded = targ;

				scope Objects tiargs = new Objects();
				tiargs.setDim(1);
				tiargs[0] = targ;

				/* Declare trailing parameters
				 */
				for (int i = 1; i < parameters.dim; i++)
				{	
					auto tp = parameters[i];
					Declaration s = null;

					m = tp.matchArg(sc, tiargs, i, parameters, dedtypes, &s);
					if (m == MATCHnomatch)
						goto Lno;
					s.semantic(sc);
					if (!sc.insert(s))
						error("declaration %s is already defined", s.toChars());
		static if (false) {
					Object o = cast(Object)dedtypes.data[i];
					Dsymbol s = TemplateDeclaration.declareParameter(loc, sc, tp, o);
		}
					if (sc.sd)
						s.addMember(sc, sc.sd, true);
				}

				goto Lyes;
			}
		}
		else if (id)
		{
			/* Declare id as an alias for type targ. Evaluate to true
			 */
			tded = targ;
			goto Lyes;
		}
		else if (tspec)
		{
			/* Evaluate to true if targ matches tspec
			 * is(targ == tspec)
			 * is(targ : tspec)
			 */
			tspec = tspec.semantic(loc, sc);
			//printf("targ  = %s\n", targ.toChars());
			//printf("tspec = %s\n", tspec.toChars());
			if (tok == TOKcolon)
			{   
				if (targ.implicitConvTo(tspec))
					goto Lyes;
				else
					goto Lno;
			}
			else /* == */
			{   
				if (targ.equals(tspec))
					goto Lyes;
				else
					goto Lno;
			}
		}

	Lyes:
		if (id)
		{
			Dsymbol s = new AliasDeclaration(loc, id, tded);
			s.semantic(sc);
			if (!sc.insert(s))
				error("declaration %s is already defined", s.toChars());
			if (sc.sd)
				s.addMember(sc, sc.sd, true);
		}
	//printf("Lyes\n");
		return new IntegerExp(loc, 1, Type.tbool);

	Lno:
	//printf("Lno\n");
		return new IntegerExp(loc, 0, Type.tbool);
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		buf.writestring("is(");
		targ.toCBuffer(buf, id, hgs);
		if (tok2 != TOKreserved)
		{
			buf.printf(" %s %s", Token.toChars(tok), Token.toChars(tok2));
		}
		else if (tspec)
		{
			if (tok == TOKcolon)
				buf.writestring(" : ");
			else
				buf.writestring(" == ");
			tspec.toCBuffer(buf, null, hgs);
		}
version (DMDV2) {
		if (parameters)
		{	
			// First parameter is already output, so start with second
			for (int i = 1; i < parameters.dim; i++)
			{
				buf.writeByte(',');
				auto tp = parameters[i];
				tp.toCBuffer(buf, hgs);
			}
		}
}
		buf.writeByte(')');
	}
}

