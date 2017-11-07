module dmd.Parser;

import dmd.common;
import dmd.Lexer;
import dmd.PostBlitDeclaration;
import dmd.FileInitExp;
import dmd.LineInitExp;
import dmd.SharedStaticCtorDeclaration;
import dmd.SharedStaticDtorDeclaration;
import dmd.EnumMember;
import dmd.CtorDeclaration;
import dmd.ShlAssignExp;
import dmd.ShrAssignExp;
import dmd.UshrAssignExp;
import dmd.CatAssignExp;
import dmd.StaticIfCondition;
import dmd.TraitsExp;
import dmd.TemplateMixin;
import dmd.BaseClass;
import dmd.AssignExp;
import dmd.TemplateInstance;
import dmd.NewExp;
import dmd.ArrayExp;
import dmd.DotTemplateInstanceExp;
import dmd.ClassDeclaration;
import dmd.NewAnonClassExp;
import dmd.InterfaceDeclaration;
import dmd.StructDeclaration;
import dmd.UnionDeclaration;
import dmd.AnonDeclaration;
import dmd.StructInitializer;
import dmd.ArrayInitializer;
import dmd.ExpInitializer;
import dmd.TemplateAliasParameter;
import dmd.TemplateTupleParameter;
import dmd.TemplateThisParameter;
import dmd.TemplateValueParameter;
import dmd.VoidInitializer;
import dmd.VersionCondition;
import dmd.DotIdExp;
import dmd.DebugCondition;
import dmd.PostExp;
import dmd.CallExp;
import dmd.SliceExp;
import dmd.FuncExp;
import dmd.AssocArrayLiteralExp;
import dmd.ArrayLiteralExp;
import dmd.IsExp;
import dmd.FuncLiteralDeclaration;
import dmd.AssertExp;
import dmd.CompileExp;
import dmd.FileExp;
import dmd.TemplateMixin;
import dmd.TemplateParameter;
import dmd.TemplateTypeParameter;
import dmd.TypeidExp;
import dmd.StringExp;
import dmd.ScopeExp;
import dmd.IdentifierExp;
import dmd.DollarExp;
import dmd.ThisExp;
import dmd.SuperExp;
import dmd.NullExp;
import dmd.RealExp;
import dmd.TypeExp;
import dmd.AddrExp;
import dmd.MOD;
import dmd.IntegerExp;
import dmd.CastExp;
import dmd.PtrExp;
import dmd.NegExp;
import dmd.XorAssignExp;
import dmd.OrAssignExp;
import dmd.UAddExp;
import dmd.NotExp;
import dmd.ComExp;
import dmd.DeleteExp;
import dmd.MulAssignExp;
import dmd.ModAssignExp;
import dmd.MinAssignExp;
import dmd.DivAssignExp;
import dmd.AndAssignExp;
import dmd.AddAssignExp;
import dmd.PowAssignExp;
import dmd.ModuleDeclaration;
import dmd.CaseRangeStatement;
import dmd.CommaExp;
import dmd.XorExp;
import dmd.CondExp;
import dmd.CmpExp;
import dmd.InExp;
import dmd.OrOrExp;
import dmd.OrExp;
import dmd.AddExp;
import dmd.MinExp;
import dmd.CatExp;
import dmd.AndAndExp;
import dmd.EqualExp;
import dmd.ShlExp;
import dmd.ShrExp;
import dmd.DivExp;
import dmd.MulExp;
import dmd.ModExp;
import dmd.UshrExp;
import dmd.IdentityExp;
import dmd.AndExp;
import dmd.Id;
import dmd.LabelStatement;
import dmd.ExpStatement;
import dmd.StaticAssertStatement;
import dmd.DeclarationStatement;
import dmd.ScopeStatement;
import dmd.PragmaStatement;
import dmd.WhileStatement;
import dmd.DoStatement;
import dmd.ForStatement;
import dmd.OnScopeStatement;
import dmd.IfStatement;
import dmd.SwitchStatement;
import dmd.CaseStatement;
import dmd.DefaultStatement;
import dmd.GotoDefaultStatement;
import dmd.GotoCaseStatement;
import dmd.GotoStatement;
import dmd.SynchronizedStatement;
import dmd.WithStatement;
import dmd.Catch;
import dmd.TryCatchStatement;
import dmd.TryFinallyStatement;
import dmd.ThrowStatement;
import dmd.VolatileStatement;
import dmd.ReturnStatement;
import dmd.BreakStatement;
import dmd.ContinueStatement;
import dmd.AsmStatement;
import dmd.TypeReturn;
import dmd.TypeTypeof;
import dmd.ForeachRangeStatement;
import dmd.ForeachStatement;
import dmd.CompileStatement;
import dmd.CompoundStatement;
import dmd.ConditionalStatement;
import dmd.CompoundDeclarationStatement;
import dmd.Parameter;
import dmd.ParseStatementFlags;
import dmd.TypeNewArray;
import dmd.TypeNext;
import dmd.TypeInstance;
import dmd.TypePointer;
import dmd.TypeDArray;
import dmd.TypeAArray;
import dmd.TypeSlice;
import dmd.TypeSArray;
import dmd.TemplateInstance;
import dmd.TypeIdentifier;
import dmd.VarDeclaration;
import dmd.TypeFunction;
import dmd.TypeDelegate;
import dmd.TY;
import dmd.LinkDeclaration;
import dmd.Declaration;
import dmd.AggregateDeclaration;
import dmd.TypedefDeclaration;
import dmd.AliasDeclaration;
import dmd.LINK;
import dmd.Loc;
import dmd.Module;
import dmd.Array;
import dmd.Expression;
import dmd.TemplateDeclaration;
import dmd.ArrayTypes;
import dmd.Dsymbol;
import dmd.StaticAssert;
import dmd.TypeQualified;
import dmd.Condition;
import dmd.PostBlitDeclaration;
import dmd.DtorDeclaration;
import dmd.ConditionalDeclaration;
import dmd.StaticCtorDeclaration;
import dmd.StaticDtorDeclaration;
import dmd.InvariantDeclaration;
import dmd.UnitTestDeclaration;
import dmd.NewDeclaration;
import dmd.DeleteDeclaration;
import dmd.EnumDeclaration;
import dmd.Import;
import dmd.Type;
import dmd.Identifier;
import dmd.FuncDeclaration;
import dmd.Statement;
import dmd.Initializer;
import dmd.Token;
import dmd.TOK;
import dmd.ParseStatementFlags;
import dmd.PROT;
import dmd.STC;
import dmd.Util;
import dmd.CompileDeclaration;
import dmd.StaticIfDeclaration;
import dmd.StorageClassDeclaration;
import dmd.LinkDeclaration;
import dmd.ProtDeclaration;
import dmd.AlignDeclaration;
import dmd.PragmaDeclaration;
import dmd.DebugSymbol;
import dmd.VersionSymbol;
import dmd.AliasThis;
import dmd.Global;
import dmd.TRUST;
import dmd.PowExp;

import core.stdc.string : memcpy;

import std.exception;
import core.memory;

class Parser : Lexer
{
    ModuleDeclaration md;
    LINK linkage;
    Loc endloc;			// set to location of last right curly
    int inBrackets;		// inside [] of array index or slice

    this(Module module_, ubyte* base, uint length, int doDocComment)
	{
		register();
		super(module_, base, 0, length, doDocComment, 0);
		//printf("Parser.Parser()\n");
		linkage = LINK.LINKd;
		//nextToken();		// start up the scanner
	}
	
    Dsymbols parseModule()
	{
		typeof(return) decldefs;

		// ModuleDeclation leads off
		if (token.value == TOK.TOKmodule)
		{
			string comment = token.blockComment;
			bool safe = false;

			nextToken();
static if(false) {
version (DMDV2) {
			if (token.value == TOK.TOKlparen)
			{
				nextToken();
				if (token.value != TOK.TOKidentifier)
				{
					error("module (system) identifier expected");
					goto Lerr;
				}
				Identifier id = token.ident;

				if (id is Id.system)
					safe = true;
				else
					error("(safe) expected, not %s", id.toChars());
				nextToken();
				check(TOK.TOKrparen);
			}
}
}

			if (token.value != TOK.TOKidentifier)
			{
				error("Identifier expected following module");
				goto Lerr;
			}
			else
			{
				Identifiers a = null;
				Identifier id = token.ident;
				while (nextToken() == TOK.TOKdot)
				{
					if (!a)
						a = new Identifiers();
					a.push(id);
					nextToken();
					if (token.value != TOK.TOKidentifier)
					{   error("Identifier expected following package");
						goto Lerr;
					}
					id = token.ident;
				}

				md = new ModuleDeclaration(a, id, safe);

				if (token.value != TOK.TOKsemicolon)
					error("';' expected following module declaration instead of %s", token.toChars());

				nextToken();
				addComment(mod, comment);
			}
		}

		decldefs = parseDeclDefs(0);
		if (token.value != TOK.TOKeof)
		{
			error("unrecognized declaration");
			goto Lerr;
		}

		return decldefs;

	Lerr:
		while (token.value != TOK.TOKsemicolon && token.value != TOK.TOKeof)
			nextToken();

		nextToken();
		return new Dsymbols();
	}
	
    Dsymbols parseDeclDefs(int once)
	{
		Dsymbol s;
		Dsymbols decldefs;
		Dsymbols a;
		Dsymbols aelse;
		PROT prot;
		StorageClass stc;
		StorageClass storageClass;
		Condition  condition;
		string comment;

		//printf("Parser.parseDeclDefs()\n");
		decldefs = new Dsymbols();
		do
		{
		comment = token.blockComment;
		storageClass = STC.STCundefined;
		switch (token.value)
		{
			case TOK.TOKenum:
			{	/* Determine if this is a manifest constant declaration,
			 * or a conventional enum.
			 */
			Token *t = peek(&token);
			if (t.value == TOK.TOKlcurly || t.value == TOK.TOKcolon)
				s = parseEnum();
			else if (t.value != TOK.TOKidentifier)
				goto Ldeclaration;
			else
			{
				t = peek(t);
				if (t.value == TOK.TOKlcurly || t.value == TOK.TOKcolon ||
				t.value == TOK.TOKsemicolon)
				s = parseEnum();
				else
				goto Ldeclaration;
			}
			break;
			}

			case TOK.TOKstruct:
			case TOK.TOKunion:
			case TOK.TOKclass:
			case TOK.TOKinterface:
			s = parseAggregate();
			break;

			case TOK.TOKimport:
			s = parseImport(decldefs, 0);
			break;

			case TOK.TOKtemplate:
			s = cast(Dsymbol)parseTemplateDeclaration();
			break;

			case TOK.TOKmixin:
			{	Loc loc = this.loc;
			if (peek(&token).value == TOK.TOKlparen)
			{   // mixin(string)
				nextToken();
				check(TOK.TOKlparen, "mixin");
				Expression e = parseAssignExp();
				check(TOK.TOKrparen);
				check(TOK.TOKsemicolon);
				s = new CompileDeclaration(loc, e);
				break;
			}
			s = parseMixin();
			break;
			}

			case TOK.TOKwchar: case TOK.TOKdchar:
			case TOK.TOKbit: case TOK.TOKbool: case TOK.TOKchar:
			case TOK.TOKint8: case TOK.TOKuns8:
			case TOK.TOKint16: case TOK.TOKuns16:
			case TOK.TOKint32: case TOK.TOKuns32:
			case TOK.TOKint64: case TOK.TOKuns64:
			case TOK.TOKfloat32: case TOK.TOKfloat64: case TOK.TOKfloat80:
			case TOK.TOKimaginary32: case TOK.TOKimaginary64: case TOK.TOKimaginary80:
			case TOK.TOKcomplex32: case TOK.TOKcomplex64: case TOK.TOKcomplex80:
			case TOK.TOKvoid:
			case TOK.TOKalias:
			case TOK.TOKtypedef:
			case TOK.TOKidentifier:
			case TOK.TOKtypeof:
			case TOK.TOKdot:
			Ldeclaration:
			a = parseDeclarations(STC.STCundefined);
			decldefs.append(a);
			continue;

			case TOK.TOKthis:
			s = parseCtor();
			break;

static if (false) { // dead end, use this(this){} instead
			case TOK.TOKassign:
			s = parsePostBlit();
			break;
}
			case TOK.TOKtilde:
			s = parseDtor();
			break;

			case TOK.TOKinvariant:
			{	Token *t;
			t = peek(&token);
			if (t.value == TOK.TOKlparen)
			{
				if (peek(t).value == TOK.TOKrparen)
				// invariant() forms start of class invariant
				s = parseInvariant();
				else
				// invariant(type)
				goto Ldeclaration;
			}
			else
			{
				stc = STC.STCimmutable;
				goto Lstc;
			}
			break;
			}

			case TOK.TOKunittest:
			s = parseUnitTest();
			break;

			case TOK.TOKnew:
			s = parseNew();
			break;

			case TOK.TOKdelete:
			s = parseDelete();
			break;

			case TOK.TOKeof:
			case TOK.TOKrcurly:
			return decldefs;

			case TOK.TOKstatic:
			nextToken();
			if (token.value == TOK.TOKthis)
				s = parseStaticCtor();
			else if (token.value == TOK.TOKtilde)
				s = parseStaticDtor();
			else if (token.value == TOK.TOKassert)
				s = parseStaticAssert();
			else if (token.value == TOK.TOKif)
			{   condition = parseStaticIfCondition();
				a = parseBlock();
				aelse = null;
				if (token.value == TOK.TOKelse)
				{   nextToken();
				aelse = parseBlock();
				}
				s = new StaticIfDeclaration(condition, a, aelse);
				break;
			}
			else if (token.value == TOK.TOKimport)
			{
				s = parseImport(decldefs, 1);
			}
			else
			{   stc = STC.STCstatic;
				goto Lstc2;
			}
			break;

			case TOK.TOKconst:
			if (peekNext() == TOKlparen)
				goto Ldeclaration;
			stc = STC.STCconst;
			goto Lstc;

			case TOK.TOKimmutable:
			if (peekNext() == TOKlparen)
				goto Ldeclaration;
			stc = STC.STCimmutable;
			goto Lstc;

			case TOK.TOKshared:
			{
				TOK next = peekNext();
				if (next == TOKlparen)
					goto Ldeclaration;
				if (next == TOKstatic)
				{   
					TOK next2 = peekNext2();
					if (next2 == TOKthis)
					{	
						s = parseSharedStaticCtor();
						break;
					}
					if (next2 == TOKtilde)
					{	
						s = parseSharedStaticDtor();
						break;
					}
				}
				stc = STCshared;
				goto Lstc;
			}

			case TOKwild:
			if (peekNext() == TOKlparen)
		        goto Ldeclaration;
		    stc = STCwild;
		    goto Lstc;

			case TOK.TOKfinal:	  stc = STC.STCfinal;	 goto Lstc;
			case TOK.TOKauto:	  stc = STC.STCauto;	 goto Lstc;
			case TOK.TOKscope:	  stc = STC.STCscope;	 goto Lstc;
			case TOK.TOKoverride:	  stc = STC.STCoverride;	 goto Lstc;
			case TOK.TOKabstract:	  stc = STC.STCabstract;	 goto Lstc;
			case TOK.TOKsynchronized: stc = STC.STCsynchronized; goto Lstc;
			case TOK.TOKdeprecated:   stc = STC.STCdeprecated;	 goto Lstc;
version (DMDV2) {
			case TOK.TOKnothrow:      stc = STC.STCnothrow;	 goto Lstc;
			case TOK.TOKpure:         stc = STC.STCpure;	 goto Lstc;
			case TOK.TOKref:          stc = STC.STCref;          goto Lstc;
			case TOK.TOKtls:          stc = STC.STCtls;		 goto Lstc;
			case TOK.TOKgshared:      
				stc = STC.STCgshared;	 goto Lstc;
			//case TOK.TOKmanifest:	  stc = STC.STCmanifest;	 goto Lstc;
	        case TOK.TOKat:           stc = parseAttribute(); goto Lstc;
}

			Lstc:
			if (storageClass & stc)
				error("redundant storage class %s", Token.toChars(token.value));
			composeStorageClass(storageClass | stc);
			nextToken();
			Lstc2:
			storageClass |= stc;
			switch (token.value)
			{
				case TOK.TOKconst:
				case TOK.TOKinvariant:
				case TOK.TOKimmutable:
				case TOK.TOKshared:
		        case TOKwild:
				// If followed by a (, it is not a storage class
				if (peek(&token).value == TOK.TOKlparen)
					break;
				if (token.value == TOK.TOKconst)
					stc = STC.STCconst;
				else if (token.value == TOK.TOKshared)
					stc = STC.STCshared;
			    else if (token.value == TOKwild)
			        stc = STC.STCwild;
				else
					stc = STC.STCimmutable;
				goto Lstc;
				case TOK.TOKfinal:	  stc = STC.STCfinal;	 goto Lstc;
				case TOK.TOKauto:	  stc = STC.STCauto;	 goto Lstc;
				case TOK.TOKscope:	  stc = STC.STCscope;	 goto Lstc;
				case TOK.TOKoverride:	  stc = STC.STCoverride;	 goto Lstc;
				case TOK.TOKabstract:	  stc = STC.STCabstract;	 goto Lstc;
				case TOK.TOKsynchronized: stc = STC.STCsynchronized; goto Lstc;
				case TOK.TOKdeprecated:   stc = STC.STCdeprecated;	 goto Lstc;
				case TOK.TOKnothrow:      stc = STC.STCnothrow;	 goto Lstc;
				case TOK.TOKpure:         stc = STC.STCpure;	 goto Lstc;
				case TOK.TOKref:          stc = STC.STCref;          goto Lstc;
				case TOK.TOKtls:          stc = STC.STCtls;		 goto Lstc;
				case TOK.TOKgshared:      stc = STC.STCgshared;	 goto Lstc;
				//case TOK.TOKmanifest:	  stc = STC.STCmanifest;	 goto Lstc;
		        case TOK.TOKat:           stc = parseAttribute(); goto Lstc;
				default:
				break;
			}

			/* Look for auto initializers:
			 *	storage_class identifier = initializer;
			 */
			if (token.value == TOK.TOKidentifier &&
				peek(&token).value == TOK.TOKassign)
			{
				a = parseAutoDeclarations(storageClass, comment);
				decldefs.append(a);
				continue;
			}

			/* Look for return type inference for template functions.
			 */
			Token *tk;
			if (token.value == TOK.TOKidentifier &&
				(tk = peek(&token)).value == TOK.TOKlparen &&
				skipParens(tk, &tk) &&
				(peek(tk).value == TOK.TOKlparen ||
				 peek(tk).value == TOK.TOKlcurly)
			   )
			{
				a = parseDeclarations(storageClass);
				decldefs.append(a);
				continue;
			}
			a = parseBlock();
			s = new StorageClassDeclaration(storageClass, a);
			break;

			case TOK.TOKextern:
				if (peek(&token).value != TOK.TOKlparen)
				{   
					stc = STC.STCextern;
					goto Lstc;
				}
				{
					LINK linksave = linkage;
					linkage = parseLinkage();
					a = parseBlock();
					s = new LinkDeclaration(linkage, a);
					linkage = linksave;
					break;
				}

			case TOK.TOKprivate:	prot = PROT.PROTprivate;	goto Lprot;
			case TOK.TOKpackage:	prot = PROT.PROTpackage;	goto Lprot;
			case TOK.TOKprotected:	prot = PROT.PROTprotected;	goto Lprot;
			case TOK.TOKpublic:		prot = PROT.PROTpublic;		goto Lprot;
			case TOK.TOKexport:		prot = PROT.PROTexport;		goto Lprot;
				Lprot:
				nextToken();
				switch (token.value)
				{
					case TOK.TOKprivate:
					case TOK.TOKpackage:
					case TOK.TOKprotected:
					case TOK.TOKpublic:
					case TOK.TOKexport:
						error("redundant protection attribute");
						break;
					default:
						break;
				}
				a = parseBlock();
				s = new ProtDeclaration(prot, a);
				break;

			case TOK.TOKalign:
			{	uint n;

			s = null;
			nextToken();
			if (token.value == TOK.TOKlparen)
			{
				nextToken();
				if (token.value == TOK.TOKint32v)
				n = cast(uint)token.uns64value;
				else
				{	error("integer expected, not %s", token.toChars());
				n = 1;
				}
				nextToken();
				check(TOK.TOKrparen);
			}
			else
				n = global.structalign;		// default

			a = parseBlock();
			s = new AlignDeclaration(n, a);
			break;
			}

			case TOK.TOKpragma:
			{	Identifier ident;
			Expressions args = null;

			nextToken();
			check(TOK.TOKlparen);
			if (token.value != TOK.TOKidentifier)
			{   error("pragma(identifier expected");
				goto Lerror;
			}
			ident = token.ident;
			nextToken();
			if (token.value == TOK.TOKcomma && peekNext() != TOK.TOKrparen)
				args = parseArguments();	// pragma(identifier, args...)
			else
				check(TOK.TOKrparen);		// pragma(identifier)

			if (token.value == TOK.TOKsemicolon)
				a = null;
			else
				a = parseBlock();
			s = new PragmaDeclaration(loc, ident, args, a);
			break;
			}

			case TOK.TOKdebug:
			nextToken();
			if (token.value == TOK.TOKassign)
			{
				nextToken();
				if (token.value == TOK.TOKidentifier)
				s = new DebugSymbol(loc, token.ident);
				else if (token.value == TOK.TOKint32v)
				s = new DebugSymbol(loc, cast(uint)token.uns64value);
				else
				{	error("identifier or integer expected, not %s", token.toChars());
				s = null;
				}
				nextToken();
				if (token.value != TOK.TOKsemicolon)
				error("semicolon expected");
				nextToken();
				break;
			}

			condition = parseDebugCondition();
			goto Lcondition;

			case TOK.TOKversion:
			nextToken();
			if (token.value == TOK.TOKassign)
			{
				nextToken();
				if (token.value == TOK.TOKidentifier)
				s = new VersionSymbol(loc, token.ident);
				else if (token.value == TOK.TOKint32v)
				s = new VersionSymbol(loc, cast(uint)token.uns64value);
				else
				{	error("identifier or integer expected, not %s", token.toChars());
				s = null;
				}
				nextToken();
				if (token.value != TOK.TOKsemicolon)
				error("semicolon expected");
				nextToken();
				break;
			}
			condition = parseVersionCondition();
			goto Lcondition;

			Lcondition:
			a = parseBlock();
			aelse = null;
			if (token.value == TOK.TOKelse)
			{   nextToken();
				aelse = parseBlock();
			}
			s = new ConditionalDeclaration(condition, a, aelse);
			break;

			case TOK.TOKsemicolon:		// empty declaration
			nextToken();
			continue;

			default:
			error("Declaration expected, not '%s'",token.toChars());
			Lerror:
			while (token.value != TOK.TOKsemicolon && token.value != TOK.TOKeof)
				nextToken();
			nextToken();
			s = null;
			continue;
		}
		if (s)
		{   decldefs.push(s);
			addComment(s, comment);
		}
		} while (!once);
		return decldefs;
	}
	
	/*****************************************
	 * Parse auto declarations of the form:
	 *   storageClass ident = init, ident = init, ... ;
	 * and return the array of them.
	 * Starts with token on the first ident.
	 * Ends with scanner past closing ';'
	 */
version (DMDV2)
{
    Dsymbols parseAutoDeclarations(StorageClass storageClass, const(char)[] comment)
	{
		auto a = new Dsymbols;

		while (true)
		{
			Identifier ident = token.ident;
			nextToken();		// skip over ident
			assert(token.value == TOKassign);
			nextToken();		// skip over '='
			Initializer init = parseInitializer();
			auto v = new VarDeclaration(loc, null, ident, init);
			v.storage_class = storageClass;
			a.push(v);
			if (token.value == TOKsemicolon)
			{
				nextToken();
				addComment(v, comment);
			}
			else if (token.value == TOKcomma)
			{
				nextToken();
				if (token.value == TOKidentifier &&
					peek(&token).value == TOKassign)
				{
					addComment(v, comment);
					continue;
				}
				else
					error("Identifier expected following comma");
			}
			else
				error("semicolon expected following auto declaration, not '%s'", token.toChars());
			break;
		}
		return a;
	}
}
	/********************************************
	 * Parse declarations after an align, protection, or extern decl.
	 */
    Dsymbols parseBlock()
	{
		Dsymbols a = null;
		Dsymbol ss;

		//printf("parseBlock()\n");
		switch (token.value)
		{
		case TOK.TOKsemicolon:
			error("declaration expected following attribute, not ';'");
			nextToken();
			break;

		case TOK.TOKeof:
			error("declaration expected following attribute, not EOF");
			break;

		case TOK.TOKlcurly:
			nextToken();
			a = parseDeclDefs(0);
			if (token.value != TOK.TOKrcurly)
			{   /* { */
				error("matching '}' expected, not %s", token.toChars());
			}
			else
				nextToken();
			break;

		case TOK.TOKcolon:
			nextToken();
static if (false) {
			a = null;
} else {
			a = parseDeclDefs(0);	// grab declarations up to closing curly bracket
}
			break;

		default:
			a = parseDeclDefs(1);
			break;
		}
		return a;
	}
version(DMDV2) {
    void composeStorageClass(StorageClass stc)
	{
		StorageClass u = stc;
		u &= STC.STCconst | STC.STCimmutable | STC.STCmanifest;
		if (u & (u - 1))
			error("conflicting storage class %s", Token.toChars(token.value));

		u = stc;
		u &= STC.STCgshared | STC.STCshared | STC.STCtls;
		if (u & (u - 1))
			error("conflicting storage class %s", Token.toChars(token.value));
        u = stc;
        u &= STCsafe | STCsystem | STCtrusted;
        if (u & (u - 1))
	        error("conflicting attribute @%s", token.toChars());
	}
}
    
/***********************************************
 * Parse storage class, lexer is on '@'
 */

version(DMDV2) {
    StorageClass parseAttribute()
    {
        nextToken();
        StorageClass stc = STCundefined;
        if (token.value != TOKidentifier)
        {
	        error("identifier expected after @, not %s", token.toChars());
        }
        else if (token.ident == Id.property)
	        stc = STCproperty;
        else if (token.ident == Id.safe)
	        stc = STCsafe;
        else if (token.ident == Id.trusted)
	        stc = STCtrusted;
        else if (token.ident == Id.system)
	        stc = STCsystem;
        else if (token.ident == Id.disable)
			stc = STCdisable;
		else
			error("valid attribute identifiers are @property, @safe, @trusted, @system, @disable not @%s", token.toChars());

        return stc;
    }
}
	/**************************************
	 * Parse constraint.
	 * Constraint is of the form:
	 *	if ( ConstraintExpression )
	 */
version (DMDV2) {
    Expression parseConstraint()
	{
		Expression e = null;

		if (token.value == TOKif)
		{
			nextToken();	// skip over 'if'
			check(TOKlparen);
			e = parseExpression();
			check(TOKrparen);
		}
		return e;
	}
}
	/**************************************
	 * Parse a TemplateDeclaration.
	 */
    TemplateDeclaration parseTemplateDeclaration()
	{
		TemplateDeclaration tempdecl;
		Identifier id;
		TemplateParameters tpl;
		Dsymbols decldefs;
		Expression constraint = null;
		Loc loc = this.loc;

		nextToken();
		if (token.value != TOKidentifier)
		{   
			error("TemplateIdentifier expected following template");
			goto Lerr;
		}
		id = token.ident;
		nextToken();
		tpl = parseTemplateParameterList();
		if (!tpl)
			goto Lerr;

		constraint = parseConstraint();

		if (token.value != TOKlcurly)
		{	
			error("members of template declaration expected");
			goto Lerr;
		}
		else
		{
			nextToken();
			decldefs = parseDeclDefs(0);
			if (token.value != TOKrcurly)
			{   
				error("template member expected");
				goto Lerr;
			}
			nextToken();
		}

		tempdecl = new TemplateDeclaration(loc, id, tpl, constraint, decldefs);
		return tempdecl;

	Lerr:
		return null;
	}
	
	/******************************************
	 * Parse template parameter list.
	 * Input:
	 *	flag	0: parsing "( list )"
	 *		1: parsing non-empty "list )"
	 */
    TemplateParameters parseTemplateParameterList(int flag = 0)
	{
		TemplateParameters tpl = new TemplateParameters();

		if (!flag && token.value != TOKlparen)
		{   
			error("parenthesized TemplateParameterList expected following TemplateIdentifier");
			goto Lerr;
		}
		nextToken();

		// Get array of TemplateParameters
		if (flag || token.value != TOKrparen)
		{	
			int isvariadic = 0;

			while (true)
			{   
				TemplateParameter tp;
				Identifier tp_ident = null;
				Type tp_spectype = null;
				Type tp_valtype = null;
				Type tp_defaulttype = null;
				Expression tp_specvalue = null;
				Expression tp_defaultvalue = null;
				Token* t;

				// Get TemplateParameter

				// First, look ahead to see if it is a TypeParameter or a ValueParameter
				t = peek(&token);
				if (token.value == TOKalias)
				{	
					// AliasParameter
					nextToken();
					Type spectype = null;
					if (isDeclaration(&token, 2, TOKreserved, null))
					{
						spectype = parseType(&tp_ident);
					}
					else
					{
						if (token.value != TOKidentifier)
						{
							error("identifier expected for template alias parameter");
							goto Lerr;
						}
						tp_ident = token.ident;
						nextToken();
					}
					Object spec = null;
					if (token.value == TOKcolon)	// : Type
					{
						nextToken();
						if (isDeclaration(&token, 0, TOKreserved, null))
							spec = parseType();
						else
						spec = parseCondExp();
					}
					Object def = null;
					if (token.value == TOKassign)	// = Type
					{
						nextToken();
						if (isDeclaration(&token, 0, TOKreserved, null))
							def = parseType();
						else
							def = parseCondExp();
					}
					tp = new TemplateAliasParameter(loc, tp_ident, spectype, spec, def);
				}
				else if (t.value == TOKcolon || t.value == TOKassign ||
					 t.value == TOKcomma || t.value == TOKrparen)
				{	// TypeParameter
					if (token.value != TOKidentifier)
					{   error("identifier expected for template type parameter");
						goto Lerr;
					}
					tp_ident = token.ident;
					nextToken();
					if (token.value == TOKcolon)	// : Type
					{
						nextToken();
						tp_spectype = parseType();
					}
					if (token.value == TOKassign)	// = Type
					{
						nextToken();
						tp_defaulttype = parseType();
					}
					tp = new TemplateTypeParameter(loc, tp_ident, tp_spectype, tp_defaulttype);
				}
				else if (token.value == TOKidentifier && t.value == TOKdotdotdot)
				{	// ident...
					if (isvariadic)
						error("variadic template parameter must be last");
					isvariadic = 1;
					tp_ident = token.ident;
					nextToken();
					nextToken();
					tp = new TemplateTupleParameter(loc, tp_ident);
				}
///		version (DMDV2) {
				else if (token.value == TOKthis)
				{	// ThisParameter
					nextToken();
					if (token.value != TOKidentifier)
					{   error("identifier expected for template this parameter");
						goto Lerr;
					}
					tp_ident = token.ident;
					nextToken();
					if (token.value == TOKcolon)	// : Type
					{
						nextToken();
						tp_spectype = parseType();
					}
					if (token.value == TOKassign)	// = Type
					{
						nextToken();
						tp_defaulttype = parseType();
					}
					tp = new TemplateThisParameter(loc, tp_ident, tp_spectype, tp_defaulttype);
				}
///		}
				else
				{	// ValueParameter
					tp_valtype = parseType(&tp_ident);
					if (!tp_ident)
					{
						error("identifier expected for template value parameter");
						tp_ident = new Identifier("error", TOKidentifier);
					}
					if (token.value == TOKcolon)	// : CondExpression
					{
						nextToken();
						tp_specvalue = parseCondExp();
					}
					if (token.value == TOKassign)	// = CondExpression
					{
						nextToken();
						tp_defaultvalue = parseDefaultInitExp();
					}
					tp = new TemplateValueParameter(loc, tp_ident, tp_valtype, tp_specvalue, tp_defaultvalue);
				}
				tpl.push(tp);
				if (token.value != TOKcomma)
					break;
				nextToken();
			}
		}
		check(TOKrparen);

	Lerr:
		return tpl;
	}

/******************************************
 * Parse template mixin.
 *	mixin Foo;
 *	mixin Foo!(args);
 *	mixin a.b.c!(args).Foo!(args);
 *	mixin Foo!(args) identifier;
 *	mixin typeof(expr).identifier!(args);
 */

    Dsymbol parseMixin()
	{
		TemplateMixin tm;
		Identifier id;
		Type tqual;
		Objects tiargs;
		Array idents;

		//printf("parseMixin()\n");
		nextToken();
		tqual = null;
		if (token.value == TOKdot)
		{
			id = Id.empty;
		}
		else
		{
			if (token.value == TOKtypeof)
			{
				tqual = parseTypeof();
				check(TOKdot);
			}
			if (token.value != TOKidentifier)
			{
				error("identifier expected, not %s", token.toChars());
				id = Id.empty;
			}
			else
				id = token.ident;
			nextToken();
		}

		idents = new Array();
		while (1)
		{
			tiargs = null;
			if (token.value == TOKnot)
			{
				nextToken();
				if (token.value == TOKlparen)
					tiargs = parseTemplateArgumentList();
				else
					tiargs = parseTemplateArgument();
			}
			if (token.value != TOKdot)
				break;
			if (tiargs)
			{   
				TemplateInstance tempinst = new TemplateInstance(loc, id);
				tempinst.tiargs = tiargs;
				id = cast(Identifier)tempinst;
				tiargs = null;
			}
			idents.push(cast(void*)id);
			nextToken();
			if (token.value != TOKidentifier)
			{   
				error("identifier expected following '.' instead of '%s'", token.toChars());
				break;
			}
			id = token.ident;
			nextToken();
		}
		idents.push(cast(void*)id);
		if (token.value == TOKidentifier)
		{
			id = token.ident;
			nextToken();
		}
		else
			id = null;

		tm = new TemplateMixin(loc, id, tqual, idents, tiargs);
		if (token.value != TOKsemicolon)
			error("';' expected after mixin");
		nextToken();
		return tm;
	}
	
	/******************************************
	 * Parse template argument list.
	 * Input:
	 * 	current token is opening '('
	 * Output:
	 *	current token is one after closing ')'
	 */
    Objects parseTemplateArgumentList()
	{
		//printf("Parser.parseTemplateArgumentList()\n");
		if (token.value != TOKlparen && token.value != TOKlcurly)
		{   
			error("!(TemplateArgumentList) expected following TemplateIdentifier");
			return new Objects();
		}
		return parseTemplateArgumentList2();
	}
	
    Objects parseTemplateArgumentList2()
	{
		//printf("Parser.parseTemplateArgumentList2()\n");
		Objects tiargs = new Objects();
		TOK endtok = TOKrparen;
		nextToken();

		// Get TemplateArgumentList
		if (token.value != endtok)
		{
			while (1)
			{
				// See if it is an Expression or a Type
				if (isDeclaration(&token, 0, TOKreserved, null))
				{	// Template argument is a type
					Type ta = parseType();
					tiargs.push(ta);
				}
				else
				{	// Template argument is an expression
					Expression ea = parseAssignExp();

					if (ea.op == TOKfunction)
					{   
						FuncLiteralDeclaration fd = (cast(FuncExp)ea).fd;
						if (fd.type.ty == Tfunction)
						{
							TypeFunction tf = cast(TypeFunction)fd.type;
							/* If there are parameters that consist of only an identifier,
							 * rather than assuming the identifier is a type, as we would
							 * for regular function declarations, assume the identifier
							 * is the parameter name, and we're building a template with
							 * a deduced type.
							 */
							TemplateParameters tpl = null;
							foreach (param; tf.parameters)
							{   
								if (param.ident is null &&
									param.type &&
									param.type.ty == Tident &&
									(cast(TypeIdentifier)param.type).idents.dim == 0
								   )
								{
									/* Switch parameter type to parameter identifier,
									 * parameterize with template type parameter _T
									 */
									auto pt = cast(TypeIdentifier)param.type;
									param.ident = pt.ident;
									Identifier id = Lexer.uniqueId("__T");
									param.type = new TypeIdentifier(pt.loc, id);
									auto tp = new TemplateTypeParameter(fd.loc, id, null, null);
									if (!tpl)
										tpl = new TemplateParameters();
									tpl.push(tp);
								}
							}

							if (tpl)
							{   
								// Wrap a template around function fd
								auto decldefs = new Dsymbols();
								decldefs.push(fd);
								auto tempdecl = new TemplateDeclaration(fd.loc, fd.ident, tpl, null, decldefs);
								tempdecl.literal = 1;	// it's a template 'literal'
								tiargs.push(tempdecl);
								goto L1;
							}
						}
					}

					tiargs.push(ea);
				}
			 L1:
				if (token.value != TOKcomma)
					break;
				nextToken();
			}
		}
		check(endtok, "template argument list");
		return tiargs;
	}
	
	/*****************************
	 * Parse single template argument, to support the syntax:
	 *	foo!arg
	 * Input:
	 *	current token is the arg
	 */
    Objects parseTemplateArgument()
	{
		//printf("parseTemplateArgument()\n");
		Objects tiargs = new Objects();
		Type ta;
		switch (token.value)
		{
			case TOKidentifier:
				ta = new TypeIdentifier(loc, token.ident);
				goto LabelX;

			case TOKvoid:	 ta = Type.tvoid;  goto LabelX;
			case TOKint8:	 ta = Type.tint8;  goto LabelX;
			case TOKuns8:	 ta = Type.tuns8;  goto LabelX;
			case TOKint16:	 ta = Type.tint16; goto LabelX;
			case TOKuns16:	 ta = Type.tuns16; goto LabelX;
			case TOKint32:	 ta = Type.tint32; goto LabelX;
			case TOKuns32:	 ta = Type.tuns32; goto LabelX;
			case TOKint64:	 ta = Type.tint64; goto LabelX;
			case TOKuns64:	 ta = Type.tuns64; goto LabelX;
			case TOKfloat32: ta = Type.tfloat32; goto LabelX;
			case TOKfloat64: ta = Type.tfloat64; goto LabelX;
			case TOKfloat80: ta = Type.tfloat80; goto LabelX;
			case TOKimaginary32: ta = Type.timaginary32; goto LabelX;
			case TOKimaginary64: ta = Type.timaginary64; goto LabelX;
			case TOKimaginary80: ta = Type.timaginary80; goto LabelX;
			case TOKcomplex32: ta = Type.tcomplex32; goto LabelX;
			case TOKcomplex64: ta = Type.tcomplex64; goto LabelX;
			case TOKcomplex80: ta = Type.tcomplex80; goto LabelX;
			case TOKbit:	 ta = Type.tbit;     goto LabelX;
			case TOKbool:	 ta = Type.tbool;    goto LabelX;
			case TOKchar:	 ta = Type.tchar;    goto LabelX;
			case TOKwchar:	 ta = Type.twchar; goto LabelX;
			case TOKdchar:	 ta = Type.tdchar; goto LabelX;
			LabelX:
				tiargs.push(ta);
				nextToken();
				break;

			case TOKint32v:
			case TOKuns32v:
			case TOKint64v:
			case TOKuns64v:
			case TOKfloat32v:
			case TOKfloat64v:
			case TOKfloat80v:
			case TOKimaginary32v:
			case TOKimaginary64v:
			case TOKimaginary80v:
			case TOKnull:
			case TOKtrue:
			case TOKfalse:
			case TOKcharv:
			case TOKwcharv:
			case TOKdcharv:
			case TOKstring:
			case TOKfile:
			case TOKline:
			{   
				// Template argument is an expression
				Expression ea = parsePrimaryExp();
				tiargs.push(ea);
				break;
			}

			default:
				error("template argument expected following !");
				break;
		}

		if (token.value == TOKnot)
			error("multiple ! arguments are not allowed");
		return tiargs;
	}
	
	/**********************************
	 * Parse a static assertion.
	 */
    StaticAssert parseStaticAssert()
	{
		Loc loc = this.loc;
		Expression exp;
		Expression msg = null;

		//printf("parseStaticAssert()\n");
		nextToken();
		check(TOK.TOKlparen);
		exp = parseAssignExp();
		if (token.value == TOK.TOKcomma)
		{	
			nextToken();
			msg = parseAssignExp();
		}

		check(TOK.TOKrparen);
		check(TOK.TOKsemicolon);
	
		return new StaticAssert(loc, exp, msg);
	}
	
    TypeQualified parseTypeof()
	{
		TypeQualified t;
		Loc loc = this.loc;

		nextToken();
		check(TOK.TOKlparen);
		if (token.value == TOK.TOKreturn)	// typeof(return)
		{
			nextToken();
			t = new TypeReturn(loc);
		}
		else
		{	
			Expression exp = parseExpression();	// typeof(expression)
			t = new TypeTypeof(loc, exp);
		}
		check(TOK.TOKrparen);
		return t;
	}
	
	/***********************************
	 * Parse extern (linkage)
	 * The parser is on the 'extern' token.
	 */
    LINK parseLinkage()
	{
		LINK link = LINK.LINKdefault;
		nextToken();
		assert(token.value == TOK.TOKlparen);
		nextToken();
		if (token.value == TOK.TOKidentifier)
		{   
			Identifier id = token.ident;

			nextToken();
			if (id == Id.Windows)
				link = LINK.LINKwindows;
			else if (id == Id.Pascal)
				link = LINK.LINKpascal;
			else if (id == Id.D)
				link = LINK.LINKd;
			else if (id == Id.C)
			{
				link = LINK.LINKc;
				if (token.value == TOK.TOKplusplus)
				{   
					link = LINK.LINKcpp;
					nextToken();
				}
			}
			else if (id == Id.System)
			{
version (Windows)
{
				link = LINK.LINKwindows;
}
else
{
				link = LINK.LINKc;
}
			}
			else
			{
				error("valid linkage identifiers are D, C, C++, Pascal, Windows, System");
				link = LINK.LINKd;
			}
		}
		else
		{
			link = LINK.LINKd;		// default
		}
		check(TOK.TOKrparen);

		return link;
	}


	/**************************************
	 * Parse a debug conditional
	 */	
    Condition parseDebugCondition()
	{
		Condition c;

		if (token.value == TOK.TOKlparen)
		{
			nextToken();
			uint level = 1;
			Identifier id = null;

			if (token.value == TOK.TOKidentifier)
				id = token.ident;
			else if (token.value == TOK.TOKint32v)
				level = cast(uint)token.uns64value;
			else
				error("identifier or integer expected, not %s", token.toChars());

			nextToken();
			check(TOK.TOKrparen);

			c = new DebugCondition(mod, level, id);
		}
		else
			c = new DebugCondition(mod, 1, null);

		return c;
	}
	
	/**************************************
	 * Parse a version conditional
	 */
    Condition parseVersionCondition()
	{
		Condition c;
		uint level = 1;
		Identifier id = null;

		if (token.value == TOK.TOKlparen)
		{
			nextToken();
			if (token.value == TOK.TOKidentifier)
				id = token.ident;
			else if (token.value == TOK.TOKint32v)
				level = cast(uint)token.uns64value;
			else {
version (DMDV2) {
				/* Allow:
				 *    version (unittest)
				 * even though unittest is a keyword
				 */
				if (token.value == TOK.TOKunittest)
					id = Lexer.idPool(Token.toChars(TOK.TOKunittest));
				else
					error("identifier or integer expected, not %s", token.toChars());
			} else {
				error("identifier or integer expected, not %s", token.toChars());
}
			}
			nextToken();
			check(TOK.TOKrparen);
		}
		else
		   error("(condition) expected following version");

		c = new VersionCondition(mod, level, id);

		return c;
	}

	/***********************************************
	 *	static if (expression)
	 *	    body
	 *	else
	 *	    body
	 */
    Condition parseStaticIfCondition()
	{
		Expression exp;
		Condition condition;
		Array aif;
		Array aelse;
		Loc loc = this.loc;

		nextToken();
		if (token.value == TOKlparen)
		{
			nextToken();
			exp = parseAssignExp();
			check(TOKrparen);
		}
		else
		{   
			error("(expression) expected following static if");
			exp = null;
		}
		condition = new StaticIfCondition(loc, exp);
		return condition;
	}
	
	/*****************************************
	 * Parse a constructor definition:
	 *	this(parameters) { body }
	 * or postblit:
	 *	this(this) { body }
	 * or constructor template:
	 *	this(templateparameters)(parameters) { body }
	 * Current token is 'this'.
	 */
	
    Dsymbol parseCtor()
	{
		Loc loc = this.loc;

		nextToken();
		if (token.value == TOK.TOKlparen && peek(&token).value == TOK.TOKthis)
		{	// this(this) { ... }
			nextToken();
			nextToken();
			check(TOK.TOKrparen);
			auto f = new PostBlitDeclaration(loc, Loc(0));
			parseContracts(f);
			return f;
		}

		/* Look ahead to see if:
		 *   this(...)(...)
		 * which is a constructor template
		 */
		TemplateParameters tpl = null;
		if (token.value == TOK.TOKlparen && peekPastParen(&token).value == TOK.TOKlparen)
		{	tpl = parseTemplateParameterList();

			int varargs;
			auto arguments = parseParameters(&varargs);

			Expression constraint = null;
			if (tpl)
				constraint = parseConstraint();

			CtorDeclaration f = new CtorDeclaration(loc, Loc(0), arguments, varargs);
			parseContracts(f);

			// Wrap a template around it
			auto decldefs = new Dsymbols();
			decldefs.push(f);
			auto tempdecl =	new TemplateDeclaration(loc, f.ident, tpl, constraint, decldefs);
			return tempdecl;
		}

		/* Just a regular constructor
		 */
		int varargs;
		auto arguments = parseParameters(&varargs);
		CtorDeclaration f = new CtorDeclaration(loc, Loc(0), arguments, varargs);
		parseContracts(f);
		return f;
	}
	
    PostBlitDeclaration parsePostBlit()
	{
		assert(false);
	}
	
	/*****************************************
	 * Parse a destructor definition:
	 *	~this() { body }
	 * Current token is '~'.
	 */
    DtorDeclaration parseDtor()
	{
		DtorDeclaration f;
		Loc loc = this.loc;

		nextToken();
		check(TOKthis);
		check(TOKlparen);
		check(TOKrparen);

		f = new DtorDeclaration(loc, Loc(0));
		parseContracts(f);
		return f;
	}
	
	/*****************************************
	 * Parse a static constructor definition:
	 *	static this() { body }
	 * Current token is 'this'.
	 */
    StaticCtorDeclaration parseStaticCtor()
	{
		Loc loc = this.loc;

		nextToken();
		check(TOKlparen);
		check(TOKrparen);

		StaticCtorDeclaration f = new StaticCtorDeclaration(loc, Loc(0));
		parseContracts(f);
		return f;
	}
	
	/*****************************************
	 * Parse a static destructor definition:
	 *	static ~this() { body }
	 * Current token is '~'.
	 */
    StaticDtorDeclaration parseStaticDtor()
	{
		Loc loc = this.loc;

		nextToken();
		check(TOKthis);
		check(TOKlparen);
		check(TOKrparen);

		StaticDtorDeclaration f = new StaticDtorDeclaration(loc, Loc(0));
		parseContracts(f);
		return f;

	}
	
	/*****************************************
	 * Parse a shared static constructor definition:
	 *	shared static this() { body }
	 * Current token is 'shared'.
	 */
    SharedStaticCtorDeclaration parseSharedStaticCtor()
	{
		Loc loc = this.loc;

		nextToken();
		nextToken();
		nextToken();
		check(TOKlparen);
		check(TOKrparen);

		SharedStaticCtorDeclaration f = new SharedStaticCtorDeclaration(loc, Loc(0));
		parseContracts(f);
		return f;
	}
	
	/*****************************************
	 * Parse a shared static destructor definition:
	 *	shared static ~this() { body }
	 * Current token is 'shared'.
	 */
    SharedStaticDtorDeclaration parseSharedStaticDtor()
	{
	    Loc loc = this.loc;

		nextToken();
		nextToken();
		nextToken();
		check(TOKthis);
		check(TOKlparen);
		check(TOKrparen);

		SharedStaticDtorDeclaration f = new SharedStaticDtorDeclaration(loc, Loc(0));
		parseContracts(f);
		return f;
	}
	
	/*****************************************
	 * Parse an invariant definition:
	 *	invariant() { body }
	 * Current token is 'invariant'.
	 */
    InvariantDeclaration parseInvariant()
	{
		InvariantDeclaration f;
		Loc loc = this.loc;

		nextToken();
		if (token.value == TOKlparen)	// optional ()
		{
			nextToken();
			check(TOKrparen);
		}

		f = new InvariantDeclaration(loc, Loc(0));
		f.fbody = parseStatement(ParseStatementFlags.PScurly);
		return f;
	}
	
	/*****************************************
	 * Parse a unittest definition:
	 *	unittest { body }
	 * Current token is 'unittest'.
	 */
    UnitTestDeclaration parseUnitTest()
	{
		Loc loc = this.loc;

		nextToken();

		UnitTestDeclaration f = new UnitTestDeclaration(loc, this.loc);
		f.fbody = parseStatement(ParseStatementFlags.PScurly);

		return f;
	}
	
	/*****************************************
	 * Parse a new definition:
	 *	new(arguments) { body }
	 * Current token is 'new'.
	 */
    NewDeclaration parseNew()
	{
		NewDeclaration f;
		auto arguments = new Parameters();
		int varargs;
		Loc loc = this.loc;

		nextToken();
		arguments = parseParameters(&varargs);
		f = new NewDeclaration(loc, Loc(0), arguments, varargs);
		parseContracts(f);
		return f;
	}
	
	/*****************************************
	 * Parse a delete definition:
	 *	delete(arguments) { body }
	 * Current token is 'delete'.
	 */
    DeleteDeclaration parseDelete()
	{
		DeleteDeclaration f;
		Parameters arguments;
		int varargs;
		Loc loc = this.loc;

		nextToken();
		arguments = parseParameters(&varargs);
		if (varargs)
			error("... not allowed in delete function parameter list");
		f = new DeleteDeclaration(loc, Loc(0), arguments);
		parseContracts(f);
		return f;
	}
	
    Parameters parseParameters(int* pvarargs)
	{
		auto arguments = new Parameters();
		int varargs = 0;
		int hasdefault = 0;

		check(TOK.TOKlparen);
		while (1)
		{   Type *tb;
		Identifier ai = null;
		Type at;
		Parameter a;
		StorageClass storageClass = STC.STCundefined;
		StorageClass stc;
		Expression ae;

		for ( ;1; nextToken())
		{
			switch (token.value)
			{
			case TOK.TOKrparen:
				break;

			case TOK.TOKdotdotdot:
				varargs = 1;
				nextToken();
				break;

			case TOK.TOKconst:
				if (peek(&token).value == TOK.TOKlparen)
				goto Ldefault;
				stc = STC.STCconst;
				goto L2;

			case TOK.TOKinvariant:
			case TOK.TOKimmutable:
				if (peek(&token).value == TOK.TOKlparen)
				goto Ldefault;
				stc = STC.STCimmutable;
				goto L2;

			case TOK.TOKshared:
				if (peek(&token).value == TOK.TOKlparen)
				goto Ldefault;
				stc = STC.STCshared;
				goto L2;
                
		    case TOKwild:
		        if (peek(&token).value == TOK.TOKlparen)
			    goto Ldefault;
		        stc = STCwild;
		        goto L2;

			case TOK.TOKin:	   stc = STC.STCin;		goto L2;
			case TOK.TOKout:	   stc = STC.STCout;	goto L2;
version(D1INOUT) {
			case TOK.TOKinout:
}
			case TOK.TOKref:	   stc = STC.STCref;	goto L2;
			case TOK.TOKlazy:	   stc = STC.STClazy;	goto L2;
			case TOK.TOKscope:	   stc = STC.STCscope;	goto L2;
			case TOK.TOKfinal:	   stc = STC.STCfinal;	goto L2;
		    case TOK.TOKauto:	   stc = STCauto;	    goto L2;
			L2:
				if (storageClass & stc ||
				(storageClass & STC.STCin && stc & (STC.STCconst | STC.STCscope)) ||
				(stc & STC.STCin && storageClass & (STC.STCconst | STC.STCscope))
				   )
				error("redundant storage class %s", Token.toChars(token.value));
				storageClass |= stc;
				composeStorageClass(storageClass);
				continue;

static if (false) {
			case TOK.TOKstatic:	   stc = STC.STCstatic;		goto L2;
			case TOK.TOKauto:   storageClass = STC.STCauto;		goto L4;
			case TOK.TOKalias:  storageClass = STC.STCalias;	goto L4;
			L4:
				nextToken();
				if (token.value == TOK.TOKidentifier)
				{	ai = token.ident;
				nextToken();
				}
				else
				ai = null;
				at = null;		// no type
				ae = null;		// no default argument
				if (token.value == TOK.TOKassign)	// = defaultArg
				{   nextToken();
				ae = parseDefaultInitExp();
				hasdefault = 1;
				}
				else
				{   if (hasdefault)
					error("default argument expected for alias %s",
						ai ? ai.toChars() : "");
				}
				goto L3;
}

			default:
			Ldefault:
				stc = (storageClass & (STC.STCin | STC.STCout | STC.STCref | STC.STClazy));
				if (stc & (stc - 1))	// if stc is not a power of 2
				error("incompatible parameter storage classes");
				if ((storageClass & (STC.STCconst | STC.STCout)) == (STC.STCconst | STC.STCout))
				error("out cannot be const");
				if ((storageClass & (STC.STCimmutable | STC.STCout)) == (STC.STCimmutable | STC.STCout))
				error("out cannot be immutable");
				if ((storageClass & STC.STCscope) &&
				(storageClass & (STC.STCref | STC.STCout)))
				error("scope cannot be ref or out");
				at = parseType(&ai);
				ae = null;
				if (token.value == TOK.TOKassign)	// = defaultArg
				{   nextToken();
				ae = parseDefaultInitExp();
				hasdefault = 1;
				}
				else
				{   if (hasdefault)
					error("default argument expected for %s",
						ai ? ai.toChars() : at.toChars());
				}
				if (token.value == TOK.TOKdotdotdot)
				{   /* This is:
				 *	at ai ...
				 */

				if (storageClass & (STC.STCout | STC.STCref))
					error("variadic argument cannot be out or ref");
				varargs = 2;
				a = new Parameter(storageClass, at, ai, ae);
				arguments.push(a);
				nextToken();
				break;
				}
			L3:
				a = new Parameter(storageClass, at, ai, ae);
				arguments.push(a);
				if (token.value == TOK.TOKcomma)
				{   nextToken();
				goto L1;
				}
				break;
			}
			break;
		}
		break;

		L1:	;
		}
		check(TOK.TOKrparen);
		*pvarargs = varargs;
		return arguments;
	}
	
    EnumDeclaration parseEnum()
	{
		EnumDeclaration e;
		Identifier id;
		Type memtype;
		Loc loc = this.loc;

		//printf("Parser.parseEnum()\n");
		nextToken();
		if (token.value == TOK.TOKidentifier)
		{
			id = token.ident;
			nextToken();
		}
		else
			id = null;

		if (token.value == TOK.TOKcolon)
		{
			nextToken();
			memtype = parseBasicType();
			memtype = parseDeclarator(memtype, null, null);
		}
		else
			memtype = null;

		e = new EnumDeclaration(loc, id, memtype);
		if (token.value == TOK.TOKsemicolon && id)
			nextToken();
		else if (token.value == TOK.TOKlcurly)
		{
			//printf("enum definition\n");
			e.members = new Dsymbols();
			nextToken();
			string comment = token.blockComment;
			while (token.value != TOK.TOKrcurly)
			{
				/* Can take the following forms:
				 *	1. ident
				 *	2. ident = value
				 *	3. type ident = value
				 */

				loc = this.loc;

				Type type = null;
				Identifier ident;
				Token* tp = peek(&token);
				if (token.value == TOK.TOKidentifier &&
					(tp.value == TOK.TOKassign || tp.value == TOK.TOKcomma || tp.value == TOK.TOKrcurly))
				{
					ident = token.ident;
					type = null;
					nextToken();
				}
				else
				{
					type = parseType(&ident, null);
					if (id || memtype)
						error("type only allowed if anonymous enum and no enum type");
				}

				Expression value;
				if (token.value == TOK.TOKassign)
				{
					nextToken();
					value = parseAssignExp();
				}
				else
				{	
					value = null;
					if (type)
						error("if type, there must be an initializer");
				}

				auto em = new EnumMember(loc, ident, value, type);
				e.members.push(em);

				if (token.value == TOK.TOKrcurly) {
					//;
				} else {
					addComment(em, comment);
					comment = null;
					check(TOK.TOKcomma);
				}
				addComment(em, comment);
				comment = token.blockComment;
			}
			nextToken();
		}
		else
			error("enum declaration is invalid");

		//printf("-parseEnum() %s\n", e.toChars());
		return e;
	}
	
    Dsymbol parseAggregate()
	{
		AggregateDeclaration a = null;
		int anon = 0;
		TOK tok;
		Identifier id;
		TemplateParameters tpl = null;
		Expression constraint = null;

		//printf("Parser.parseAggregate()\n");
		tok = token.value;
		nextToken();
		if (token.value != TOK.TOKidentifier)
		{
			id = null;
		}
		else
		{
			id = token.ident;
			nextToken();

			if (token.value == TOK.TOKlparen)
			{   
				// Class template declaration.

				// Gather template parameter list
				tpl = parseTemplateParameterList();
				constraint = parseConstraint();
			}
		}

		Loc loc = this.loc;
		switch (tok)
		{	case TOK.TOKclass:
		case TOK.TOKinterface:
		{
			if (!id)
			error("anonymous classes not allowed");

			// Collect base class(es)
			BaseClasses baseclasses = null;
			if (token.value == TOK.TOKcolon)
			{
				nextToken();
				baseclasses = parseBaseClasses();

				if (token.value != TOK.TOKlcurly)
					error("members expected");
			}

			if (tok == TOK.TOKclass)
				a = new ClassDeclaration(loc, id, baseclasses);
			else
				a = new InterfaceDeclaration(loc, id, baseclasses);
			break;
		}

		case TOK.TOKstruct:
			if (id)
			a = new StructDeclaration(loc, id);
			else
			anon = 1;
			break;

		case TOK.TOKunion:
			if (id)
			a = new UnionDeclaration(loc, id);
			else
			anon = 2;
			break;

		default:
			assert(0);
			break;
		}
		if (a && token.value == TOK.TOKsemicolon)
		{ 	nextToken();
		}
		else if (token.value == TOK.TOKlcurly)
		{
		//printf("aggregate definition\n");
		nextToken();
		auto decl = parseDeclDefs(0);
		if (token.value != TOK.TOKrcurly)
			error("} expected following member declarations in aggregate");
		nextToken();
		if (anon)
		{
			/* Anonymous structs/unions are more like attributes.
			 */
			return new AnonDeclaration(loc, anon - 1, decl);
		}
		else
			a.members = decl;
		}
		else
		{
		error("{ } expected following aggregate declaration");
		a = new StructDeclaration(loc, null);
		}

		if (tpl)
		{	// Wrap a template around the aggregate declaration

		auto decldefs = new Dsymbols();
		decldefs.push(a);
		auto tempdecl =	new TemplateDeclaration(loc, id, tpl, constraint, decldefs);
		return tempdecl;
		}

		return a;
	}
	
    BaseClasses parseBaseClasses()
	{
		BaseClasses baseclasses = new BaseClasses();

		for (; 1; nextToken())
		{
			PROT protection = PROT.PROTpublic;
			switch (token.value)
			{
				case TOK.TOKprivate:
					protection = PROT.PROTprivate;
					nextToken();
					break;
				case TOK.TOKpackage:
					protection = PROT.PROTpackage;
					nextToken();
					break;
				case TOK.TOKprotected:
					protection = PROT.PROTprotected;
					nextToken();
					break;
				case TOK.TOKpublic:
					protection = PROT.PROTpublic;
					nextToken();
					break;
				default:
					break;	///
			}
			if (token.value == TOK.TOKidentifier)
			{
				auto b = new BaseClass(parseBasicType(), protection);
				baseclasses.push(b);
				if (token.value != TOK.TOKcomma)
					break;
			}
			else
			{
				error("base classes expected instead of %s", token.toChars());
				return null;
			}
		}
		return baseclasses;
	}
	
    Import parseImport(Dsymbols decldefs, int isstatic)
	{
		Import s;
		Identifier id;
		Identifier aliasid = null;
		Identifiers a;
		Loc loc;

		//printf("Parser.parseImport()\n");
		do
		{
		 L1:
			nextToken();
			if (token.value != TOK.TOKidentifier)
			{   
				error("Identifier expected following import");
				break;
			}

			loc = this.loc;
			a = null;
			id = token.ident;
			nextToken();
			if (!aliasid && token.value == TOK.TOKassign)
			{
				aliasid = id;
				goto L1;
			}
			while (token.value == TOK.TOKdot)
			{
				if (!a)
					a = new Identifiers();
				a.push(id);
				nextToken();
				if (token.value != TOK.TOKidentifier)
				{   
					error("identifier expected following package");
					break;
				}
				id = token.ident;
				nextToken();
			}

			s = new Import(loc, a, id, aliasid, isstatic);
			decldefs.push(s);

			/* Look for
			 *	: alias=name, alias=name;
			 * syntax.
			 */
			if (token.value == TOK.TOKcolon)
			{
				do
				{	
					Identifier name;

					nextToken();
					if (token.value != TOK.TOKidentifier)
					{   
						error("Identifier expected following :");
						break;
					}
					Identifier alias_ = token.ident;
					nextToken();
					if (token.value == TOK.TOKassign)
					{
						nextToken();
						if (token.value != TOK.TOKidentifier)
						{   
							error("Identifier expected following %s=", alias_.toChars());
							break;
						}
						name = token.ident;
						nextToken();
					}
					else
					{   
						name = alias_;
						alias_ = null;
					}
					s.addAlias(name, alias_);
				} while (token.value == TOK.TOKcomma);

				break;	// no comma-separated imports of this form
			}

			aliasid = null;

		} while (token.value == TOK.TOKcomma);

		if (token.value == TOK.TOKsemicolon)
			nextToken();
		else
		{
			error("';' expected");
			nextToken();
		}

		return null;
	}
	
    Type parseType(Identifier* pident = null, TemplateParameters* tpl = null)
	{
		Type t;

		/* Take care of the storage class prefixes that
		 * serve as type attributes:
		 *  const shared, shared const, const, invariant, shared
		 */
		if (token.value == TOK.TOKconst && peekNext() == TOK.TOKshared && peekNext2() != TOK.TOKlparen ||
			token.value == TOK.TOKshared && peekNext() == TOK.TOKconst && peekNext2() != TOK.TOKlparen)
		{
			nextToken();
			nextToken();
			/* shared const type
			 */
			t = parseType(pident, tpl);
			t = t.makeSharedConst();
			return t;
		}
        else if (token.value == TOKwild && peekNext() == TOKshared && peekNext2() != TOKlparen ||
	             token.value == TOKshared && peekNext() == TOKwild && peekNext2() != TOKlparen)
        {
	        nextToken();
	        nextToken();
	        /* shared wild type
	         */
	        t = parseType(pident, tpl);
	        t = t.makeSharedWild();
	        return t;
        }
		else if (token.value == TOK.TOKconst && peekNext() != TOK.TOKlparen)
		{
			nextToken();
			/* const type
			 */
			t = parseType(pident, tpl);
			t = t.makeConst();
			return t;
		}
		else if ((token.value == TOK.TOKinvariant || token.value == TOK.TOKimmutable) &&
				 peekNext() != TOK.TOKlparen)
		{
			nextToken();
			/* invariant type
			 */
			t = parseType(pident, tpl);
			t = t.makeInvariant();
			return t;
		}
		else if (token.value == TOK.TOKshared && peekNext() != TOK.TOKlparen)
		{
			nextToken();
			/* shared type
			 */
			t = parseType(pident, tpl);
			t = t.makeShared();
			return t;
		}
        else if (token.value == TOKwild && peekNext() != TOKlparen)
        {
	        nextToken();
	        /* wild type
	         */
	        t = parseType(pident, tpl);
	        t = t.makeWild();
	        return t;
        }
		else
			t = parseBasicType();	
		t = parseDeclarator(t, pident, tpl);
		return t;
	}
	
    Type parseBasicType()
	{
		Type t;
		Identifier id;
		TypeQualified tid;

		//printf("parseBasicType()\n");
		switch (token.value)
		{
			case TOK.TOKvoid:	 t = Type.tvoid;  goto LabelX;
			case TOK.TOKint8:	 t = Type.tint8;  goto LabelX;
			case TOK.TOKuns8:	 t = Type.tuns8;  goto LabelX;
			case TOK.TOKint16:	 t = Type.tint16; goto LabelX;
			case TOK.TOKuns16:	 t = Type.tuns16; goto LabelX;
			case TOK.TOKint32:	 t = Type.tint32; goto LabelX;
			case TOK.TOKuns32:	 t = Type.tuns32; goto LabelX;
			case TOK.TOKint64:	 t = Type.tint64; goto LabelX;
			case TOK.TOKuns64:	 t = Type.tuns64; goto LabelX;
			case TOK.TOKfloat32: t = Type.tfloat32; goto LabelX;
			case TOK.TOKfloat64: t = Type.tfloat64; goto LabelX;
			case TOK.TOKfloat80: t = Type.tfloat80; goto LabelX;
			case TOK.TOKimaginary32: t = Type.timaginary32; goto LabelX;
			case TOK.TOKimaginary64: t = Type.timaginary64; goto LabelX;
			case TOK.TOKimaginary80: t = Type.timaginary80; goto LabelX;
			case TOK.TOKcomplex32: t = Type.tcomplex32; goto LabelX;
			case TOK.TOKcomplex64: t = Type.tcomplex64; goto LabelX;
			case TOK.TOKcomplex80: t = Type.tcomplex80; goto LabelX;
			case TOK.TOKbit:	 t = Type.tbit;     goto LabelX;
			case TOK.TOKbool:	 t = Type.tbool;    goto LabelX;
			case TOK.TOKchar:	 t = Type.tchar;    goto LabelX;
			case TOK.TOKwchar:	 t = Type.twchar; goto LabelX;
			case TOK.TOKdchar:	 t = Type.tdchar; goto LabelX;
			LabelX:
				nextToken();
				break;

		case TOK.TOKidentifier:
			id = token.ident;
			nextToken();
			if (token.value == TOK.TOKnot)
			{	// ident!(template_arguments)
			TemplateInstance tempinst = new TemplateInstance(loc, id);
			nextToken();
			if (token.value == TOK.TOKlparen)
				// ident!(template_arguments)
				tempinst.tiargs = parseTemplateArgumentList();
			else
				// ident!template_argument
				tempinst.tiargs = parseTemplateArgument();
			tid = new TypeInstance(loc, tempinst);
			goto Lident2;
			}
		Lident:
			tid = new TypeIdentifier(loc, id);
		Lident2:
			while (token.value == TOK.TOKdot)
			{	nextToken();
			if (token.value != TOK.TOKidentifier)
			{   error("identifier expected following '.' instead of '%s'", token.toChars());
				break;
			}
			id = token.ident;
			nextToken();
			if (token.value == TOK.TOKnot)
			{
				TemplateInstance tempinst = new TemplateInstance(loc, id);
				nextToken();
				if (token.value == TOK.TOKlparen)
				// ident!(template_arguments)
				tempinst.tiargs = parseTemplateArgumentList();
				else
				// ident!template_argument
				tempinst.tiargs = parseTemplateArgument();
				tid.addIdent(tempinst);
			}
			else
				tid.addIdent(id);
			}
			t = tid;
			break;

		case TOK.TOKdot:
			// Leading . as in .foo
			id = Id.empty;
			goto Lident;

		case TOK.TOKtypeof:
			// typeof(expression)
			tid = parseTypeof();
			goto Lident2;

		case TOK.TOKconst:
			// const(type)
			nextToken();
			check(TOK.TOKlparen);
			t = parseType();
			check(TOK.TOKrparen);
			if (t.isShared())
			t = t.makeSharedConst();
			else
			t = t.makeConst();
			break;

		case TOK.TOKinvariant:
		case TOK.TOKimmutable:
			// invariant(type)
			nextToken();
			check(TOK.TOKlparen);
			t = parseType();
			check(TOK.TOKrparen);
			t = t.makeInvariant();
			break;

		case TOK.TOKshared:
			// shared(type)
			nextToken();
			check(TOK.TOKlparen);
			t = parseType();
			check(TOK.TOKrparen);
			if (t.isConst())
			t = t.makeSharedConst();
	        else if (t.isWild())
		    t = t.makeSharedWild();
			else
			t = t.makeShared();
			break;

	    case TOKwild:
	        // wild(type)
	        nextToken();
	        check(TOK.TOKlparen);
	        t = parseType();
	        check(TOK.TOKrparen);
	        if (t.isShared())
		    t = t.makeSharedWild();
	        else
		    t = t.makeWild();
	        break;
            
		default:
			error("basic type expected, not %s", token.toChars());
			t = Type.tint32;
			break;
		}
		return t;
	}
	
    Type parseBasicType2(Type t)
	{
		//writef("parseBasicType2()\n");
		while (1)
		{
			switch (token.value)
			{
				case TOK.TOKmul:
				t = new TypePointer(t);
				nextToken();
				continue;
	
				case TOK.TOKlbracket:
				// Handle []. Make sure things like
				//     int[3][1] a;
				// is (array[1] of array[3] of int)
				nextToken();
				if (token.value == TOK.TOKrbracket)
				{
					t = new TypeDArray(t);			// []
					nextToken();
				}
				else if (token.value == TOKnew && peekNext() == TOKrbracket)
				{
					t = new TypeNewArray(t);			// [new]
					nextToken();
					nextToken();
				}
				else if (isDeclaration(&token, 0, TOK.TOKrbracket, null))
				{   // It's an associative array declaration
	
					//printf("it's an associative array\n");
					Type index = parseType();		// [ type ]
					t = new TypeAArray(t, index);
					check(TOK.TOKrbracket);
				}
				else
				{
					//printf("it's type[expression]\n");
					inBrackets++;
					Expression e = parseAssignExp();		// [ expression ]
					if (token.value == TOK.TOKslice)
					{
					nextToken();
					Expression e2 = parseAssignExp();	// [ exp .. exp ]
					t = new TypeSlice(t, e, e2);
					}
					else
					t = new TypeSArray(t,e);
					inBrackets--;
					check(TOK.TOKrbracket);
				}
				continue;
	
				case TOK.TOKdelegate:
				case TOK.TOKfunction:
				{	// Handle delegate declaration:
				//	t delegate(parameter list) nothrow pure
				//	t function(parameter list) nothrow pure
				Parameters arguments;
				int varargs;
				bool ispure = false;
				bool isnothrow = false;
		        bool isproperty = false;
				TOK save = token.value;
		        TRUST trust = TRUSTdefault;
	
				nextToken();
				arguments = parseParameters(&varargs);
				while (1)
				{   // Postfixes
					if (token.value == TOK.TOKpure)
					    ispure = true;
					else if (token.value == TOK.TOKnothrow)
					    isnothrow = true;
		            else if (token.value == TOKat)
		            {	StorageClass stc = parseAttribute();
			            switch (cast(uint)(stc >> 32))
			            {   case STCproperty >> 32:
				                isproperty = true;
				                break;
			                case STCsafe >> 32:
				                trust = TRUSTsafe;
				                break;
			                case STCsystem >> 32:
				                trust = TRUSTsystem;
				                break;
			                case STCtrusted >> 32:
				                trust = TRUSTtrusted;
				                break;
			                case 0:
				                break;
			                default:
    				            assert(0);
			            }
		            }
					else
					    break;
					nextToken();
				}
				TypeFunction tf = new TypeFunction(arguments, t, varargs, linkage);
				tf.ispure = ispure;
				tf.isnothrow = isnothrow;
		        tf.isproperty = isproperty;
		        tf.trust = trust;
				if (save == TOK.TOKdelegate)
					t = new TypeDelegate(tf);
				else
					t = new TypePointer(tf);	// pointer to function
				continue;
				}
	
				default:
				return t;
			}
			assert(0);
		}
		assert(0);
		return null;
	}
	
    Type parseDeclarator(Type t, Identifier* pident, TemplateParameters* tpl = null)
	{
		Type ts;

		//printf("parseDeclarator(tpl = %p)\n", tpl);
		t = parseBasicType2(t);

		switch (token.value)
		{

		case TOK.TOKidentifier:
			if (pident)
			*pident = token.ident;
			else
			error("unexpected identifer '%s' in declarator", token.ident.toChars());
			ts = t;
			nextToken();
			break;

		case TOK.TOKlparen:
			/* Parse things with parentheses around the identifier, like:
			 *	int (*ident[3])[]
			 * although the D style would be:
			 *	int[]*[3] ident
			 */
			nextToken();
			ts = parseDeclarator(t, pident);
			check(TOK.TOKrparen);
			break;

		default:
			ts = t;
			break;
		}

		// parse DeclaratorSuffixes
		while (1)
		{
		switch (token.value)
		{
version (CARRAYDECL) {
			/* Support C style array syntax:
			 *   int ident[]
			 * as opposed to D-style:
			 *   int[] ident
			 */
			case TOK.TOKlbracket:
			{	// This is the old C-style post [] syntax.
			TypeNext ta;
			nextToken();
			if (token.value == TOK.TOKrbracket)
			{   // It's a dynamic array
				ta = new TypeDArray(t);		// []
				nextToken();
			}
			else if (token.value == TOKnew && peekNext() == TOKrbracket)
			{
				t = new TypeNewArray(t);		// [new]
			    nextToken();
			    nextToken();
			}
			else if (isDeclaration(&token, 0, TOK.TOKrbracket, null))
			{   // It's an associative array

				//printf("it's an associative array\n");
				Type index = parseType();		// [ type ]
				check(TOK.TOKrbracket);
				ta = new TypeAArray(t, index);
			}
			else
			{
				//printf("It's a static array\n");
				Expression e = parseAssignExp();	// [ expression ]
				ta = new TypeSArray(t, e);
				check(TOK.TOKrbracket);
			}

			/* Insert ta into
			 *   ts . ... . t
			 * so that
			 *   ts . ... . ta . t
			 */
			Type* pt;
			for (pt = &ts; *pt !is t; pt = &(cast(TypeNext)*pt).next) {
				//;
			}
			*pt = ta;
			continue;
			}
}
			case TOK.TOKlparen:
			{
			if (tpl)
			{
				/* Look ahead to see if this is (...)(...),
				 * i.e. a function template declaration
				 */
				if (peekPastParen(&token).value == TOK.TOKlparen)
				{
				//printf("function template declaration\n");

				// Gather template parameter list
				*tpl = parseTemplateParameterList();
				}
			}

			int varargs;
			auto arguments = parseParameters(&varargs);
			Type tf = new TypeFunction(arguments, t, varargs, linkage);

			/* Parse const/invariant/nothrow/pure postfix
			 */
			while (1)
			{
				switch (token.value)
				{
					case TOK.TOKconst:
						if (tf.isShared())
						tf = tf.makeSharedConst();
						else
						tf = tf.makeConst();
						nextToken();
						continue;

					case TOK.TOKinvariant:
					case TOK.TOKimmutable:
						tf = tf.makeInvariant();
						nextToken();
						continue;

					case TOK.TOKshared:
						if (tf.isConst())
						tf = tf.makeSharedConst();
						else
						tf = tf.makeShared();
						nextToken();
						continue;

                    case TOKwild:
			            if (tf.isShared())
				        tf = tf.makeSharedWild();
			            else
				        tf = tf.makeWild();
			            nextToken();
			            continue;

					case TOK.TOKnothrow:
						(cast(TypeFunction)tf).isnothrow = 1;
						nextToken();
						continue;

					case TOK.TOKpure:
						(cast(TypeFunction)tf).ispure = 1;
						nextToken();
						continue;

					case TOK.TOKat:
    	            {
                        StorageClass stc = parseAttribute();
	                    auto tfunc = cast(TypeFunction)tf;
		                switch (cast(uint)(stc >> 32))
		                {
                        case STCproperty >> 32:
		                    tfunc.isproperty = 1;
			                break;
			            case STCsafe >> 32:
			                tfunc.trust = TRUSTsafe;
			                break;
			            case STCsystem >> 32:
			                tfunc.trust = TRUSTsystem;
			                break;
			            case STCtrusted >> 32:
			                tfunc.trust = TRUSTtrusted;
			                break;
			            case 0:
			                break;
			            default:
			                assert(0);
					    }
					    nextToken();
					    continue;
                    }
					default:
						break;	///
				}
				break;
			}

			/* Insert tf into
			 *   ts . ... . t
			 * so that
			 *   ts . ... . tf . t
			 */
			Type* pt;
			for (pt = &ts; *pt !is t; pt = &(cast(TypeNext)*pt).next) {
				//;
			}
			*pt = tf;
			break;
			}
			
			default:
				break;	///
		}
		break;
		}

		return ts;
	}
	
    Dsymbols parseDeclarations(StorageClass storage_class)
	{
		StorageClass stc;
		Type ts;
		Type t;
		Type tfirst;
		Identifier ident;
		Dsymbols a;
		TOK tok = TOK.TOKreserved;
		string comment = token.blockComment;
		LINK link = linkage;

		//printf("parseDeclarations() %s\n", token.toChars());
		if (storage_class)
		{	ts = null;		// infer type
		goto L2;
		}

		switch (token.value)
		{
			case TOK.TOKalias:
				/* Look for:
				 *   alias identifier this;
				 */
				tok = token.value;
				nextToken();
				if (token.value == TOK.TOKidentifier && peek(&token).value == TOK.TOKthis)
				{
				AliasThis s = new AliasThis(this.loc, token.ident);
				nextToken();
				check(TOK.TOKthis);
				check(TOK.TOKsemicolon);
				a = new Dsymbols();
				a.push(s);
				addComment(s, comment);
				return a;
				}
				break;
			case TOK.TOKtypedef:
				tok = token.value;
				nextToken();
				break;
			default:
				break;
		}

		storage_class = STC.STCundefined;
		while (1)
		{
		switch (token.value)
		{
			case TOK.TOKconst:
			if (peek(&token).value == TOK.TOKlparen)
				break;		// const as type constructor
			stc = STC.STCconst;		// const as storage class
			goto L1;

			case TOK.TOKinvariant:
			case TOK.TOKimmutable:
			if (peek(&token).value == TOK.TOKlparen)
				break;
			stc = STC.STCimmutable;
			goto L1;

			case TOK.TOKshared:
			if (peek(&token).value == TOK.TOKlparen)
				break;
			stc = STC.STCshared;
		    goto L1;

	        case TOKwild:
		    if (peek(&token).value == TOK.TOKlparen)
		        break;
		    stc = STC.STCwild;
			goto L1;

			case TOK.TOKstatic:	stc = STC.STCstatic;	 goto L1;
			case TOK.TOKfinal:	stc = STC.STCfinal;		 goto L1;
			case TOK.TOKauto:	stc = STC.STCauto;		 goto L1;
			case TOK.TOKscope:	stc = STC.STCscope;		 goto L1;
			case TOK.TOKoverride:	stc = STC.STCoverride;	 goto L1;
			case TOK.TOKabstract:	stc = STC.STCabstract;	 goto L1;
			case TOK.TOKsynchronized: stc = STC.STCsynchronized; goto L1;
			case TOK.TOKdeprecated: stc = STC.STCdeprecated;	 goto L1;
version (DMDV2) {
			case TOK.TOKnothrow:    stc = STC.STCnothrow;	 goto L1;
			case TOK.TOKpure:       stc = STC.STCpure;		 goto L1;
			case TOK.TOKref:        stc = STC.STCref;            goto L1;
			case TOK.TOKtls:        stc = STC.STCtls;		 goto L1;
			case TOK.TOKgshared:    stc = STC.STCgshared;	 goto L1;
			case TOK.TOKenum:	stc = STC.STCmanifest;	 goto L1;
	        case TOK.TOKat:         stc = parseAttribute();  goto L1;
}
			L1:
			if (storage_class & stc)
				error("redundant storage class '%s'", token.toChars());
			storage_class = (storage_class | stc);
			composeStorageClass(storage_class);
			nextToken();
			continue;

			case TOK.TOKextern:
			if (peek(&token).value != TOK.TOKlparen)
			{   stc = STC.STCextern;
				goto L1;
			}

			link = parseLinkage();
			continue;

			default:
			break;
		}
		break;
		}

		/* Look for auto initializers:
		 *	storage_class identifier = initializer;
		 */
		if (storage_class &&
		token.value == TOK.TOKidentifier &&
		peek(&token).value == TOK.TOKassign)
		{
		return parseAutoDeclarations(storage_class, comment);
		}

		if (token.value == TOK.TOKclass)
		{
		AggregateDeclaration s = cast(AggregateDeclaration)parseAggregate();
		s.storage_class |= storage_class;
		a = new Dsymbols();
		a.push(s);
		addComment(s, comment);
		return a;
		}

		/* Look for return type inference for template functions.
		 */
		{
		Token *tk;
		if (storage_class &&
		token.value == TOK.TOKidentifier &&
		(tk = peek(&token)).value == TOK.TOKlparen &&
		skipParens(tk, &tk) &&
		peek(tk).value == TOK.TOKlparen)
		{
		ts = null;
		}
		else
		{
		ts = parseBasicType();
		ts = parseBasicType2(ts);
		}
		}

	L2:
		tfirst = null;
		a = new Dsymbols();

		while (1)
		{
		Loc loc = this.loc;
		TemplateParameters tpl = null;

		ident = null;
		t = parseDeclarator(ts, &ident, &tpl);
		assert(t);
		if (!tfirst)
			tfirst = t;
		else if (t != tfirst)
			error("multiple declarations must have the same type, not %s and %s",
			tfirst.toChars(), t.toChars());
		if (!ident)
			error("no identifier for declarator %s", t.toChars());

		if (tok == TOK.TOKtypedef || tok == TOK.TOKalias)
		{   Declaration v;
			Initializer init = null;

			if (token.value == TOK.TOKassign)
			{
			nextToken();
			init = parseInitializer();
			}
			if (tok == TOK.TOKtypedef)
			v = new TypedefDeclaration(loc, ident, t, init);
			else
			{	if (init)
				error("alias cannot have initializer");
			v = new AliasDeclaration(loc, ident, t);
			}
			v.storage_class = storage_class;
			if (link == linkage)
			a.push(v);
			else
			{
			auto ax = new Dsymbols();
			ax.push(v);
			Dsymbol s = new LinkDeclaration(link, ax);
			a.push(s);
			}
			switch (token.value)
			{   case TOK.TOKsemicolon:
				nextToken();
				addComment(v, comment);
				break;

			case TOK.TOKcomma:
				nextToken();
				addComment(v, comment);
				continue;

			default:
				error("semicolon expected to close %s declaration", Token.toChars(tok));
				break;
			}
		}
		else if (t.ty == TY.Tfunction)
		{
			auto tf = cast(TypeFunction)t;
			Expression constraint = null;
static if (false) {
			if (Parameter.isTPL(tf.parameters))
			{
			if (!tpl)
				tpl = new TemplateParameters();
			}
}
			FuncDeclaration f =
			new FuncDeclaration(loc, Loc(0), ident, storage_class, t);
			addComment(f, comment);
			if (tpl)
			constraint = parseConstraint();
			parseContracts(f);
			addComment(f, null);
			Dsymbol s;
			if (link == linkage)
			{
			s = f;
			}
			else
			{
			auto ax = new Dsymbols();
			ax.push(f);
			s = new LinkDeclaration(link, ax);
			}
			/* A template parameter list means it's a function template
			 */
			if (tpl)
			{
			// Wrap a template around the function declaration
			auto decldefs = new Dsymbols();
			decldefs.push(s);
			auto tempdecl =
				new TemplateDeclaration(loc, s.ident, tpl, constraint, decldefs);
			s = tempdecl;
			}
			addComment(s, comment);
			a.push(s);
		}
		else
		{
			Initializer init = null;
			if (token.value == TOK.TOKassign)
			{
			nextToken();
			init = parseInitializer();
			}

			VarDeclaration v = new VarDeclaration(loc, t, ident, init);
			v.storage_class = storage_class;
			if (link == linkage)
			a.push(v);
			else
			{
			auto ax = new Dsymbols();
			ax.push(v);
			auto s = new LinkDeclaration(link, ax);
			a.push(s);
			}
			switch (token.value)
			{   case TOK.TOKsemicolon:
				nextToken();
				addComment(v, comment);
				break;

			case TOK.TOKcomma:
				nextToken();
				addComment(v, comment);
				continue;

			default:
				error("semicolon expected, not '%s'", token.toChars());
				break;
			}
		}
		break;
		}
		return a;
	}
	
    void parseContracts(FuncDeclaration f)
	{
		LINK linksave = linkage;

		// The following is irrelevant, as it is overridden by sc.linkage in
		// TypeFunction.semantic
		linkage = LINK.LINKd;		// nested functions have D linkage
	L1:
		switch (token.value)
		{
		case TOK.TOKlcurly:
			if (f.frequire || f.fensure)
			error("missing body { ... } after in or out");
			f.fbody = parseStatement(ParseStatementFlags.PSsemi);
			f.endloc = endloc;
			break;

		case TOK.TOKbody:
			nextToken();
			f.fbody = parseStatement(ParseStatementFlags.PScurly);
			f.endloc = endloc;
			break;

		case TOK.TOKsemicolon:
			if (f.frequire || f.fensure)
			error("missing body { ... } after in or out");
			nextToken();
			break;

static if (false) {	// Do we want this for function declarations, so we can do:
		// int x, y, foo(), z;
		case TOK.TOKcomma:
			nextToken();
			continue;
}

static if (false) { // Dumped feature
		case TOK.TOKthrow:
			if (!f.fthrows)
			f.fthrows = new Array();
			nextToken();
			check(TOK.TOKlparen);
			while (1)
			{
			Type tb = parseBasicType();
			f.fthrows.push(tb);
			if (token.value == TOK.TOKcomma)
			{   nextToken();
				continue;
			}
			break;
			}
			check(TOK.TOKrparen);
			goto L1;
}

		case TOK.TOKin:
			nextToken();
			if (f.frequire)
			error("redundant 'in' statement");
			f.frequire = parseStatement(ParseStatementFlags.PScurly | ParseStatementFlags.PSscope);
			goto L1;

		case TOK.TOKout:
			// parse: out (identifier) { statement }
			nextToken();
			if (token.value != TOK.TOKlcurly)
			{
			check(TOK.TOKlparen);
			if (token.value != TOK.TOKidentifier)	   
				error("(identifier) following 'out' expected, not %s", token.toChars());
			f.outId = token.ident;
			nextToken();
			check(TOK.TOKrparen);
			}
			if (f.fensure)
			error("redundant 'out' statement");
			f.fensure = parseStatement(ParseStatementFlags.PScurly | ParseStatementFlags.PSscope);
			goto L1;

		default:
			error("semicolon expected following function declaration");
			break;
		}
		linkage = linksave;
	}
	
    Statement parseStatement(ParseStatementFlags flags)
	{
		Statement s;
		Token* t;
		Condition condition;
		Statement ifbody;
		Statement elsebody;
		bool isfinal;
		Loc loc = this.loc;

		//printf("parseStatement()\n");

		if (flags & ParseStatementFlags.PScurly && token.value != TOK.TOKlcurly)
			error("statement expected to be { }, not %s", token.toChars());

		switch (token.value)
		{
		case TOK.TOKidentifier:
			/* A leading identifier can be a declaration, label, or expression.
			 * The easiest case to check first is label:
			 */
			t = peek(&token);
			if (t.value == TOK.TOKcolon)
			{	// It's a label

			Identifier ident = token.ident;
			nextToken();
			nextToken();
			s = parseStatement(ParseStatementFlags.PSsemi);
			s = new LabelStatement(loc, ident, s);
			break;
			}
			// fallthrough to TOK.TOKdot
		case TOK.TOKdot:
		case TOK.TOKtypeof:
			if (isDeclaration(&token, 2, TOK.TOKreserved, null))
			goto Ldeclaration;
			else
			goto Lexp;
			break;

		case TOK.TOKassert:
		case TOK.TOKthis:
		case TOK.TOKsuper:
		case TOK.TOKint32v:
		case TOK.TOKuns32v:
		case TOK.TOKint64v:
		case TOK.TOKuns64v:
		case TOK.TOKfloat32v:
		case TOK.TOKfloat64v:
		case TOK.TOKfloat80v:
		case TOK.TOKimaginary32v:
		case TOK.TOKimaginary64v:
		case TOK.TOKimaginary80v:
		case TOK.TOKcharv:
		case TOK.TOKwcharv:
		case TOK.TOKdcharv:
		case TOK.TOKnull:
		case TOK.TOKtrue:
		case TOK.TOKfalse:
		case TOK.TOKstring:
		case TOK.TOKlparen:
		case TOK.TOKcast:
		case TOK.TOKmul:
		case TOK.TOKmin:
		case TOK.TOKadd:
		case TOK.TOKplusplus:
		case TOK.TOKminusminus:
		case TOK.TOKnew:
		case TOK.TOKdelete:
		case TOK.TOKdelegate:
		case TOK.TOKfunction:
		case TOK.TOKtypeid:
		case TOK.TOKis:
		case TOK.TOKlbracket:
version (DMDV2) {
		case TOK.TOKtraits:
		case TOK.TOKfile:
		case TOK.TOKline:
}
		Lexp:
		{
			auto exp = parseExpression();
			check(TOK.TOKsemicolon, "statement");
			s = new ExpStatement(loc, exp);
			break;
		}

		case TOK.TOKstatic:
		{   // Look ahead to see if it's static assert() or static if()
			Token *tt;

			tt = peek(&token);
			if (tt.value == TOK.TOKassert)
			{
				nextToken();
				s = new StaticAssertStatement(parseStaticAssert());
				break;
			}
			if (tt.value == TOK.TOKif)
			{
				nextToken();
				condition = parseStaticIfCondition();
				goto Lcondition;
			}
	        if (tt.value == TOK.TOKstruct || tt.value == TOK.TOKunion || tt.value == TOK.TOKclass)
	        {
		        nextToken();
		        auto a = parseBlock();
		        Dsymbol d = new StorageClassDeclaration(STCstatic, a);
		        s = new DeclarationStatement(loc, d);
		        if (flags & ParseStatementFlags.PSscope)
		            s = new ScopeStatement(loc, s);
		        break;
	        }
			goto Ldeclaration;
		}

		case TOK.TOKfinal:
			if (peekNext() == TOK.TOKswitch)
			{
			nextToken();
			isfinal = true;
			goto Lswitch;
			}
			goto Ldeclaration;

		case TOK.TOKwchar: case TOK.TOKdchar:
		case TOK.TOKbit: case TOK.TOKbool: case TOK.TOKchar:
		case TOK.TOKint8: case TOK.TOKuns8:
		case TOK.TOKint16: case TOK.TOKuns16:
		case TOK.TOKint32: case TOK.TOKuns32:
		case TOK.TOKint64: case TOK.TOKuns64:
		case TOK.TOKfloat32: case TOK.TOKfloat64: case TOK.TOKfloat80:
		case TOK.TOKimaginary32: case TOK.TOKimaginary64: case TOK.TOKimaginary80:
		case TOK.TOKcomplex32: case TOK.TOKcomplex64: case TOK.TOKcomplex80:
		case TOK.TOKvoid:
		case TOK.TOKtypedef:
		case TOK.TOKalias:
		case TOK.TOKconst:
		case TOK.TOKauto:
		case TOK.TOKextern:
		case TOK.TOKinvariant:
version (DMDV2) {
		case TOK.TOKimmutable:
		case TOK.TOKshared:
        case TOKwild:
		case TOK.TOKnothrow:
		case TOK.TOKpure:
		case TOK.TOKtls:
		case TOK.TOKgshared:
	    case TOK.TOKat:
}
	//	case TOK.TOKtypeof:
		Ldeclaration:
		{   Dsymbols a;

			a = parseDeclarations(STC.STCundefined);
			if (a.dim > 1)
			{
			Statements as = new Statements();
			as.reserve(a.dim);
			foreach(Dsymbol d; a)
			{
				s = new DeclarationStatement(loc, d);
				as.push(s);
			}
			s = new CompoundDeclarationStatement(loc, as);
			}
			else if (a.dim == 1)
			{
				auto d = a[0];
			s = new DeclarationStatement(loc, d);
			}
			else
			assert(0);
			if (flags & ParseStatementFlags.PSscope)
			s = new ScopeStatement(loc, s);
			break;
		}

		case TOK.TOKstruct:
		case TOK.TOKunion:
		case TOK.TOKclass:
		case TOK.TOKinterface:
		{   Dsymbol d;

			d = parseAggregate();
			s = new DeclarationStatement(loc, d);
			break;
		}

		case TOK.TOKenum:
		{   /* Determine if this is a manifest constant declaration,
			 * or a conventional enum.
			 */
			Dsymbol d;
			Token* tt = peek(&token);
			if (tt.value == TOK.TOKlcurly || tt.value == TOK.TOKcolon)
			d = parseEnum();
			else if (tt.value != TOK.TOKidentifier)
			goto Ldeclaration;
			else
			{
			tt = peek(tt);
			if (tt.value == TOK.TOKlcurly || tt.value == TOK.TOKcolon ||
				tt.value == TOK.TOKsemicolon)
				d = parseEnum();
			else
				goto Ldeclaration;
			}
			s = new DeclarationStatement(loc, d);
			break;
		}

		case TOK.TOKmixin:
		{   t = peek(&token);
			if (t.value == TOK.TOKlparen)
			{	// mixin(string)
			nextToken();
			check(TOK.TOKlparen, "mixin");
			Expression e = parseAssignExp();
			check(TOK.TOKrparen);
			check(TOK.TOKsemicolon);
			s = new CompileStatement(loc, e);
			break;
			}
			Dsymbol d = parseMixin();
			s = new DeclarationStatement(loc, d);
			break;
		}

		case TOK.TOKlcurly:
		{
			nextToken();
			Statements statements = new Statements();
			while (token.value != TOK.TOKrcurly && token.value != TOKeof)
			{
			statements.push(parseStatement(ParseStatementFlags.PSsemi | ParseStatementFlags.PScurlyscope));
			}
			endloc = this.loc;
			s = new CompoundStatement(loc, statements);
			if (flags & (ParseStatementFlags.PSscope | ParseStatementFlags.PScurlyscope))
			s = new ScopeStatement(loc, s);
			nextToken();
			break;
		}

		case TOK.TOKwhile:
		{   Expression condition2;
			Statement body_;

			nextToken();
			check(TOK.TOKlparen);
			condition2 = parseExpression();
			check(TOK.TOKrparen);
			body_ = parseStatement(ParseStatementFlags.PSscope);
			s = new WhileStatement(loc, condition2, body_);
			break;
		}

		case TOK.TOKsemicolon:
			if (!(flags & ParseStatementFlags.PSsemi))
			error("use '{ }' for an empty statement, not a ';'");
			nextToken();
			s = new ExpStatement(loc, null);
			break;

		case TOK.TOKdo:
		{   Statement body_;
			Expression condition2;

			nextToken();
			body_ = parseStatement(ParseStatementFlags.PSscope);
			check(TOK.TOKwhile);
			check(TOK.TOKlparen);
			condition2 = parseExpression();
			check(TOK.TOKrparen);
			s = new DoStatement(loc, body_, condition2);
			break;
		}

		case TOK.TOKfor:
		{
			Statement init;
			Expression condition2;
			Expression increment;
			Statement body_;

			nextToken();
			check(TOK.TOKlparen);
			if (token.value == TOK.TOKsemicolon)
			{	init = null;
			nextToken();
			}
			else
			{	init = parseStatement(cast(ParseStatementFlags)0);
			}
			if (token.value == TOK.TOKsemicolon)
			{
			condition2 = null;
			nextToken();
			}
			else
			{
			condition2 = parseExpression();
			check(TOK.TOKsemicolon, "for condition");
			}
			if (token.value == TOK.TOKrparen)
			{	increment = null;
			nextToken();
			}
			else
			{	increment = parseExpression();
			check(TOK.TOKrparen);
			}
			body_ = parseStatement(ParseStatementFlags.PSscope);
			s = new ForStatement(loc, init, condition2, increment, body_);
			if (init)
			s = new ScopeStatement(loc, s);
			break;
		}

		case TOK.TOKforeach:
		case TOK.TOKforeach_reverse:
		{
			TOK op = token.value;

			nextToken();
			check(TOK.TOKlparen);

			auto arguments = new Parameters();

			while (1)
			{
			Identifier ai = null;
			Type at;
			StorageClass storageClass = STC.STCundefined;

		if (token.value == TOKref
//#if D1INOUT
//			|| token.value == TOKinout
//#endif
		   )
			{   storageClass = STC.STCref;
				nextToken();
			}
			if (token.value == TOK.TOKidentifier)
			{
				Token *tt = peek(&token);
				if (tt.value == TOK.TOKcomma || tt.value == TOK.TOKsemicolon)
				{	ai = token.ident;
				at = null;		// infer argument type
				nextToken();
				goto Larg;
				}
			}
			at = parseType(&ai);
			if (!ai)
				error("no identifier for declarator %s", at.toChars());
			  Larg:
			auto a = new Parameter(storageClass, at, ai, null);
			arguments.push(a);
			if (token.value == TOK.TOKcomma)
			{   nextToken();
				continue;
			}
			break;
			}
			check(TOK.TOKsemicolon);

			Expression aggr = parseExpression();
			if (token.value == TOK.TOKslice && arguments.dim == 1)
			{
			auto a = arguments[0];
			delete arguments;
			nextToken();
			Expression upr = parseExpression();
			check(TOK.TOKrparen);
			auto body_ = parseStatement(cast(ParseStatementFlags)0);
			s = new ForeachRangeStatement(loc, op, a, aggr, upr, body_);
			}
			else
			{
			check(TOK.TOKrparen);
			auto body_ = parseStatement(cast(ParseStatementFlags)0);
			s = new ForeachStatement(loc, op, arguments, aggr, body_);
			}
			break;
		}

		case TOK.TOKif:
		{   Parameter arg = null;
			Expression condition2;
			Statement ifbody2;
			Statement elsebody2;

			nextToken();
			check(TOK.TOKlparen);

			if (token.value == TOK.TOKauto)
			{
			nextToken();
			if (token.value == TOK.TOKidentifier)
			{
				Token *tt = peek(&token);
				if (tt.value == TOK.TOKassign)
				{
					arg = new Parameter(STC.STCundefined, null, token.ident, null);
					nextToken();
					nextToken();
				}
				else
				{   error("= expected following auto identifier");
				goto Lerror;
				}
			}
			else
			{   error("identifier expected following auto");
				goto Lerror;
			}
			}
			else if (isDeclaration(&token, 2, TOK.TOKassign, null))
			{
			Type at;
			Identifier ai;

			at = parseType(&ai);
			check(TOK.TOKassign);
			arg = new Parameter(STC.STCundefined, at, ai, null);
			}

			// Check for " ident;"
			else if (token.value == TOK.TOKidentifier)
			{
			Token *tt = peek(&token);
			if (tt.value == TOK.TOKcomma || tt.value == TOK.TOKsemicolon)
			{
				arg = new Parameter(STC.STCundefined, null, token.ident, null);
				nextToken();
				nextToken();
				if (1 || !global.params.useDeprecated)
				error("if (v; e) is deprecated, use if (auto v = e)");
			}
			}

			condition2 = parseExpression();
			check(TOK.TOKrparen);
			ifbody2 = parseStatement(ParseStatementFlags.PSscope);
			if (token.value == TOK.TOKelse)
			{
			nextToken();
			elsebody2 = parseStatement(ParseStatementFlags.PSscope);
			}
			else
			elsebody2 = null;
			s = new IfStatement(loc, arg, condition2, ifbody2, elsebody2);
			break;
		}

		case TOK.TOKscope:
			if (peek(&token).value != TOK.TOKlparen)
			goto Ldeclaration;		// scope used as storage class
			nextToken();
			check(TOK.TOKlparen);
			if (token.value != TOK.TOKidentifier)
			{	error("scope identifier expected");
			goto Lerror;
			}
			else
			{	TOK tt = TOK.TOKon_scope_exit;
			Identifier id = token.ident;

			if (id == Id.exit)
				tt = TOK.TOKon_scope_exit;
			else if (id == Id.failure)
				tt = TOK.TOKon_scope_failure;
			else if (id == Id.success)
				tt = TOK.TOKon_scope_success;
			else
				error("valid scope identifiers are exit, failure, or success, not %s", id.toChars());
			nextToken();
			check(TOK.TOKrparen);
			Statement st = parseStatement(ParseStatementFlags.PScurlyscope);
			s = new OnScopeStatement(loc, tt, st);
			break;
			}

		case TOK.TOKdebug:
			nextToken();
			condition = parseDebugCondition();
			goto Lcondition;

		case TOK.TOKversion:
			nextToken();
			condition = parseVersionCondition();
			goto Lcondition;

		Lcondition:
			ifbody = parseStatement(cast(ParseStatementFlags)0 /*ParseStatementFlags.PSsemi*/);
			elsebody = null;
			if (token.value == TOK.TOKelse)
			{
			nextToken();
			elsebody = parseStatement(cast(ParseStatementFlags)0 /*ParseStatementFlags.PSsemi*/);
			}
			s = new ConditionalStatement(loc, condition, ifbody, elsebody);
			break;

		case TOK.TOKpragma:
		{   Identifier ident;
			Expressions args = null;
			Statement body_;

			nextToken();
			check(TOK.TOKlparen);
			if (token.value != TOK.TOKidentifier)
			{   error("pragma(identifier expected");
			goto Lerror;
			}
			ident = token.ident;
			nextToken();
			if (token.value == TOK.TOKcomma && peekNext() != TOK.TOKrparen)
			args = parseArguments();	// pragma(identifier, args...);
			else
			check(TOK.TOKrparen);		// pragma(identifier);
			if (token.value == TOK.TOKsemicolon)
			{	nextToken();
			body_ = null;
			}
			else
			body_ = parseStatement(ParseStatementFlags.PSsemi);
			s = new PragmaStatement(loc, ident, args, body_);
			break;
		}

		case TOK.TOKswitch:
			isfinal = false;
			goto Lswitch;

		Lswitch:
		{
			nextToken();
			check(TOK.TOKlparen);
			Expression condition2 = parseExpression();
			check(TOK.TOKrparen);
			Statement body_ = parseStatement(ParseStatementFlags.PSscope);
			s = new SwitchStatement(loc, condition2, body_, isfinal);
			break;
		}

		case TOK.TOKcase:
		{   Expression exp;
			Statements statements;
			scope cases = new Expressions();	// array of Expression's
			Expression last = null;

			while (1)
			{
			nextToken();
			exp = parseAssignExp();
			cases.push(exp);
			if (token.value != TOK.TOKcomma)
				break;
			}
			check(TOK.TOKcolon);

version (DMDV2) {
			/* case exp: .. case last:
			 */
			if (token.value == TOK.TOKslice)
			{
			if (cases.dim > 1)
				error("only one case allowed for start of case range");
			nextToken();
			check(TOK.TOKcase);
			last = parseAssignExp();
			check(TOK.TOKcolon);
			}
}

			statements = new Statements();
			while (token.value != TOK.TOKcase &&
			   token.value != TOK.TOKdefault &&
			   token.value != TOKeof &&
			   token.value != TOK.TOKrcurly)
			{
			statements.push(parseStatement(ParseStatementFlags.PSsemi | ParseStatementFlags.PScurlyscope));
			}
			s = new CompoundStatement(loc, statements);
			s = new ScopeStatement(loc, s);

///version (DMDV2) {
			if (last)
			{
				s = new CaseRangeStatement(loc, exp, last, s);
			}
			else
///}
			{
				// Keep cases in order by building the case statements backwards
				for (int i = cases.dim; i; i--)
				{
					exp = cases[i - 1];
					s = new CaseStatement(loc, exp, s);
				}
			}
			break;
		}

		case TOK.TOKdefault:
		{
			Statements statements;

			nextToken();
			check(TOK.TOKcolon);

			statements = new Statements();
			while (token.value != TOK.TOKcase &&
			   token.value != TOK.TOKdefault &&
			   token.value != TOKeof &&
			   token.value != TOK.TOKrcurly)
			{
			statements.push(parseStatement(ParseStatementFlags.PSsemi | ParseStatementFlags.PScurlyscope));
			}
			s = new CompoundStatement(loc, statements);
			s = new ScopeStatement(loc, s);
			s = new DefaultStatement(loc, s);
			break;
		}

		case TOK.TOKreturn:
		{   Expression exp;

			nextToken();
			if (token.value == TOK.TOKsemicolon)
			exp = null;
			else
			exp = parseExpression();
			check(TOK.TOKsemicolon, "return statement");
			s = new ReturnStatement(loc, exp);
			break;
		}

		case TOK.TOKbreak:
		{   Identifier ident;

			nextToken();
			if (token.value == TOK.TOKidentifier)
			{	ident = token.ident;
			nextToken();
			}
			else
			ident = null;
			check(TOK.TOKsemicolon, "break statement");
			s = new BreakStatement(loc, ident);
			break;
		}

		case TOK.TOKcontinue:
		{   Identifier ident;

			nextToken();
			if (token.value == TOK.TOKidentifier)
			{	ident = token.ident;
			nextToken();
			}
			else
			ident = null;
			check(TOK.TOKsemicolon, "continue statement");
			s = new ContinueStatement(loc, ident);
			break;
		}

		case TOK.TOKgoto:
		{   Identifier ident;

			nextToken();
			if (token.value == TOK.TOKdefault)
			{
			nextToken();
			s = new GotoDefaultStatement(loc);
			}
			else if (token.value == TOK.TOKcase)
			{
			Expression exp = null;

			nextToken();
			if (token.value != TOK.TOKsemicolon)
				exp = parseExpression();
			s = new GotoCaseStatement(loc, exp);
			}
			else
			{
			if (token.value != TOK.TOKidentifier)
			{   error("Identifier expected following goto");
				ident = null;
			}
			else
			{   ident = token.ident;
				nextToken();
			}
			s = new GotoStatement(loc, ident);
			}
			check(TOK.TOKsemicolon, "goto statement");
			break;
		}

		case TOK.TOKsynchronized:
		{   Expression exp;
			Statement body_;

			nextToken();
			if (token.value == TOK.TOKlparen)
			{
			nextToken();
			exp = parseExpression();
			check(TOK.TOKrparen);
			}
			else
			exp = null;
			body_ = parseStatement(ParseStatementFlags.PSscope);
			s = new SynchronizedStatement(loc, exp, body_);
			break;
		}

		case TOK.TOKwith:
		{   Expression exp;
			Statement body_;

			nextToken();
			check(TOK.TOKlparen);
			exp = parseExpression();
			check(TOK.TOKrparen);
			body_ = parseStatement(ParseStatementFlags.PSscope);
			s = new WithStatement(loc, exp, body_);
			break;
		}

		case TOK.TOKtry:
		{   Statement body_;
			Array catches = null;
			Statement finalbody = null;

			nextToken();
			body_ = parseStatement(ParseStatementFlags.PSscope);
			while (token.value == TOK.TOKcatch)
			{
				Statement handler;
				Catch c;
				Type tt;
				Identifier id;
				Loc loc2 = this.loc;

				nextToken();
				if (token.value == TOK.TOKlcurly)
				{
					tt = null;
					id = null;
				}
				else
				{
					check(TOK.TOKlparen);
					id = null;
					tt = parseType(&id);
					check(TOK.TOKrparen);
				}
				handler = parseStatement(cast(ParseStatementFlags)0);
				c = new Catch(loc2, tt, id, handler);
				if (!catches)
					catches = new Array();
				catches.push(cast(void*)c);
			}

			if (token.value == TOK.TOKfinally)
			{	nextToken();
			finalbody = parseStatement(cast(ParseStatementFlags)0);
			}

			s = body_;
			if (!catches && !finalbody)
			error("catch or finally expected following try");
			else
			{	if (catches)
				s = new TryCatchStatement(loc, body_, catches);
			if (finalbody)
				s = new TryFinallyStatement(loc, s, finalbody);
			}
			break;
		}

		case TOK.TOKthrow:
		{   Expression exp;

			nextToken();
			exp = parseExpression();
			check(TOK.TOKsemicolon, "throw statement");
			s = new ThrowStatement(loc, exp);
			break;
		}

		case TOK.TOKvolatile:
			nextToken();
			s = parseStatement(ParseStatementFlags.PSsemi | ParseStatementFlags.PScurlyscope);
version (DMDV2) {
			if (!global.params.useDeprecated)
				error("volatile statements deprecated; used synchronized statements instead");
}
			s = new VolatileStatement(loc, s);
			break;

		case TOK.TOKasm:
		{   Statements statements;
			Identifier label;
			Loc labelloc;
			Token* toklist;
			Token** ptoklist;

			// Parse the asm block into a sequence of AsmStatements,
			// each AsmStatement is one instruction.
			// Separate out labels.
			// Defer parsing of AsmStatements until semantic processing.

			nextToken();
			check(TOK.TOKlcurly);
			toklist = null;
			ptoklist = &toklist;
			label = null;
			statements = new Statements();
			while (1)
			{
			switch (token.value)
			{
				case TOK.TOKidentifier:
				if (!toklist)
				{
					// Look ahead to see if it is a label
					t = peek(&token);
					if (t.value == TOK.TOKcolon)
					{   // It's a label
					label = token.ident;
					labelloc = this.loc;
					nextToken();
					nextToken();
					continue;
					}
				}
				goto Ldefault;

				case TOK.TOKrcurly:
				if (toklist || label)
				{
					error("asm statements must end in ';'");
				}
				break;

				case TOK.TOKsemicolon:
				s = null;
				if (toklist || label)
				{   // Create AsmStatement from list of tokens we've saved
					s = new AsmStatement(this.loc, toklist);
					toklist = null;
					ptoklist = &toklist;
					if (label)
					{   
						s = new LabelStatement(labelloc, label, s);
						label = null;
					}
					statements.push(s);
				}
				nextToken();
				continue;

				case TOK.TOKeof:
				/* { */
				error("matching '}' expected, not end of file");
				break;

				default:
				Ldefault:
				*ptoklist = new Token();
				memcpy(*ptoklist, &token, Token.sizeof);
				ptoklist = &(*ptoklist).next;
				*ptoklist = null;

				nextToken();
				continue;
			}
			break;
			}
			s = new CompoundStatement(loc, statements);
			nextToken();
			break;
		}

		default:
			error("found '%s' instead of statement", token.toChars());
			goto Lerror;

		Lerror:
			while (token.value != TOK.TOKrcurly &&
			   token.value != TOK.TOKsemicolon &&
			   token.value != TOK.TOKeof)
			nextToken();
			if (token.value == TOK.TOKsemicolon)
			nextToken();
			s = null;
			break;
		}

		return s;
	}
	
	/*****************************************
	 * Parse initializer for variable declaration.
	 */
    Initializer parseInitializer()
	{
		StructInitializer is_;
		ArrayInitializer ia;
		ExpInitializer ie;
		Expression e;
		Identifier id;
		Initializer value;
		int comma;
		Loc loc = this.loc;
		Token* t;
		int braces;
		int brackets;

		switch (token.value)
		{
			case TOK.TOKlcurly:
				/* Scan ahead to see if it is a struct initializer or
				 * a function literal.
				 * If it contains a ';', it is a function literal.
				 * Treat { } as a struct initializer.
				 */
				braces = 1;
				for (t = peek(&token); 1; t = peek(t))
				{
					switch (t.value)
					{
						case TOK.TOKsemicolon:
						case TOK.TOKreturn:
							goto Lexpression;

						case TOK.TOKlcurly:
							braces++;
							continue;

						case TOK.TOKrcurly:
							if (--braces == 0)
								break;
							continue;

						case TOK.TOKeof:
							break;

						default:
							continue;
					}
					break;
				}

				is_ = new StructInitializer(loc);
				nextToken();
				comma = 0;
				while (1)
				{
					switch (token.value)
					{
						case TOK.TOKidentifier:
							if (comma == 1)
								error("comma expected separating field initializers");
							t = peek(&token);
							if (t.value == TOK.TOKcolon)
							{
								id = token.ident;
								nextToken();
								nextToken();	// skip over ':'
							}
							else
							{   
								id = null;
							}
							value = parseInitializer();
							is_.addInit(id, value);
							comma = 1;
							continue;

						case TOK.TOKcomma:
							nextToken();
							comma = 2;
							continue;

						case TOK.TOKrcurly:		// allow trailing comma's
							nextToken();
							break;

						case TOK.TOKeof:
							error("found EOF instead of initializer");
							break;

						default:
							value = parseInitializer();
							is_.addInit(null, value);
							comma = 1;
							continue;
							//error("found '%s' instead of field initializer", token.toChars());
							//break;
					}
					break;
				}
				return is_;

			case TOK.TOKlbracket:
				/* Scan ahead to see if it is an array initializer or
				 * an expression.
				 * If it ends with a ';' ',' or '}', it is an array initializer.
				 */
				brackets = 1;
				for (t = peek(&token); 1; t = peek(t))
				{
					switch (t.value)
					{
						case TOK.TOKlbracket:
							brackets++;
							continue;

						case TOK.TOKrbracket:
							if (--brackets == 0)
							{   
								t = peek(t);
								if (t.value != TOK.TOKsemicolon &&
									t.value != TOK.TOKcomma &&
								t.value != TOK.TOKrcurly)
								goto Lexpression;
								break;
							}
							continue;

						case TOK.TOKeof:
							break;

						default:
							continue;
					}
					break;
				}

				ia = new ArrayInitializer(loc);
				nextToken();
				comma = 0;
				while (true)
				{
					switch (token.value)
					{
						default:
							if (comma == 1)
							{   
								error("comma expected separating array initializers, not %s", token.toChars());
								nextToken();
								break;
							}
							e = parseAssignExp();
							if (!e)
								break;
							if (token.value == TOK.TOKcolon)
							{
								nextToken();
								value = parseInitializer();
							}
							else
							{   value = new ExpInitializer(e.loc, e);
								e = null;
							}
							ia.addInit(e, value);
							comma = 1;
							continue;

						case TOK.TOKlcurly:
						case TOK.TOKlbracket:
							if (comma == 1)
								error("comma expected separating array initializers, not %s", token.toChars());
							value = parseInitializer();
							ia.addInit(null, value);
							comma = 1;
							continue;

						case TOK.TOKcomma:
							nextToken();
							comma = 2;
							continue;

						case TOK.TOKrbracket:		// allow trailing comma's
							nextToken();
							break;

						case TOK.TOKeof:
							error("found '%s' instead of array initializer", token.toChars());
							break;
					}
					break;
				}
				return ia;

			case TOK.TOKvoid:
				t = peek(&token);
				if (t.value == TOK.TOKsemicolon || t.value == TOK.TOKcomma)
				{
					nextToken();
					return new VoidInitializer(loc);
				}
				goto Lexpression;

			default:
			Lexpression:
				e = parseAssignExp();
				ie = new ExpInitializer(loc, e);
				return ie;
		}
	}
	
	/*****************************************
	 * Parses default argument initializer expression that is an assign expression,
	 * with special handling for __FILE__ and __LINE__.
	 */
version (DMDV2) {
    Expression parseDefaultInitExp()
	{
		if (token.value == TOK.TOKfile ||
			token.value == TOK.TOKline)
		{
			Token* t = peek(&token);
			if (t.value == TOK.TOKcomma || t.value == TOK.TOKrparen)
			{   
				Expression e;

				if (token.value == TOK.TOKfile)
					e = new FileInitExp(loc);
				else
					e = new LineInitExp(loc);
				nextToken();
				return e;
			}
		}

		Expression e = parseAssignExp();
		return e;
	}
}
    void check(Loc loc, TOK value)
	{
		if (token.value != value)
			error(loc, "found '%s' when expecting '%s'", token.toChars(), Token.toChars(value));
		nextToken();
	}
	
    void check(TOK value)
	{
		check(loc, value);
	}
	
    void check(TOK value, string string_)
	{
		if (token.value != value) {
			error("found '%s' when expecting '%s' following '%s'", token.toChars(), Token.toChars(value), string_);
		}
		nextToken();
	}
	
	/************************************
	 * Determine if the scanner is sitting on the start of a declaration.
	 * Input:
	 *	needId	0	no identifier
	 *		1	identifier optional
	 *		2	must have identifier
	 * Output:
	 *	if *pt is not null, it is set to the ending token, which would be endtok
	 */

    bool isDeclaration(Token* t, int needId, TOK endtok, Token** pt)
	{
		//printf("isDeclaration(needId = %d)\n", needId);
		int haveId = 0;

version (DMDV2) {
		if ((t.value == TOK.TOKconst ||
			t.value == TOK.TOKinvariant ||
			t.value == TOK.TOKimmutable ||
	        t.value == TOKwild ||
			t.value == TOK.TOKshared) &&
			peek(t).value != TOK.TOKlparen)
		{
			/* const type
			* immutable type
			* shared type
	        * wild type
			*/
			t = peek(t);
		}
}

		if (!isBasicType(&t))
		{
			goto Lisnot;
		}
		if (!isDeclarator(&t, &haveId, endtok))
			goto Lisnot;
		if ( needId == 1 ||
			(needId == 0 && !haveId) ||
			(needId == 2 &&  haveId))
		{	
			if (pt)
				*pt = t;
			goto Lis;
		}
		else
			goto Lisnot;

	Lis:
		//printf("\tis declaration, t = %s\n", t.toChars());
		return true;

	Lisnot:
		//printf("\tis not declaration\n");
		return false;
	}
	
    bool isBasicType(Token** pt)
	{
		// This code parallels parseBasicType()
		Token* t = *pt;
		Token* t2;
		int parens;
		int haveId = 0;

		switch (t.value)
		{
		case TOKwchar:
		case TOKdchar:
		case TOKbit:
		case TOKbool:
		case TOKchar:
		case TOKint8:
		case TOKuns8:
		case TOKint16:
		case TOKuns16:
		case TOKint32:
		case TOKuns32:
		case TOKint64:
		case TOKuns64:
		case TOKfloat32:
		case TOKfloat64:
		case TOKfloat80:
		case TOKimaginary32:
		case TOKimaginary64:
		case TOKimaginary80:
		case TOKcomplex32:
		case TOKcomplex64:
		case TOKcomplex80:
		case TOKvoid:
			t = peek(t);
			break;

		case TOK.TOKidentifier:
		L5:
			t = peek(t);
			if (t.value == TOK.TOKnot)
			{
			goto L4;
			}
			goto L3;
			while (1)
			{
		L2:
			t = peek(t);
		L3:
			if (t.value == TOK.TOKdot)
			{
		Ldot:
				t = peek(t);
				if (t.value != TOK.TOKidentifier)
				goto Lfalse;
				t = peek(t);
				if (t.value != TOK.TOKnot)
				goto L3;
		L4:
				/* Seen a !
				 * Look for:
				 * !( args ), !identifier, etc.
				 */
				t = peek(t);
				switch (t.value)
				{	case TOK.TOKidentifier:
					goto L5;
				case TOK.TOKlparen:
					if (!skipParens(t, &t))
					goto Lfalse;
					break;
				case TOK.TOKwchar: case TOK.TOKdchar:
				case TOK.TOKbit: case TOK.TOKbool: case TOK.TOKchar:
				case TOK.TOKint8: case TOK.TOKuns8:
				case TOK.TOKint16: case TOK.TOKuns16:
				case TOK.TOKint32: case TOK.TOKuns32:
				case TOK.TOKint64: case TOK.TOKuns64:
				case TOK.TOKfloat32: case TOK.TOKfloat64: case TOK.TOKfloat80:
				case TOK.TOKimaginary32: case TOK.TOKimaginary64: case TOK.TOKimaginary80:
				case TOK.TOKcomplex32: case TOK.TOKcomplex64: case TOK.TOKcomplex80:
				case TOK.TOKvoid:
				case TOK.TOKint32v:
				case TOK.TOKuns32v:
				case TOK.TOKint64v:
				case TOK.TOKuns64v:
				case TOK.TOKfloat32v:
				case TOK.TOKfloat64v:
				case TOK.TOKfloat80v:
				case TOK.TOKimaginary32v:
				case TOK.TOKimaginary64v:
				case TOK.TOKimaginary80v:
				case TOK.TOKnull:
				case TOK.TOKtrue:
				case TOK.TOKfalse:
				case TOK.TOKcharv:
				case TOK.TOKwcharv:
				case TOK.TOKdcharv:
				case TOK.TOKstring:
				case TOK.TOKfile:
				case TOK.TOKline:
					goto L2;
				default:
					goto Lfalse;
				}
			}
			else
				break;
			}
			break;

		case TOK.TOKdot:
			goto Ldot;

		case TOK.TOKtypeof:
			/* typeof(exp).identifier...
			 */
			t = peek(t);
			if (t.value != TOK.TOKlparen)
			goto Lfalse;
			if (!skipParens(t, &t))
			goto Lfalse;
			goto L2;

		case TOK.TOKconst:
		case TOK.TOKinvariant:
		case TOK.TOKimmutable:
		case TOK.TOKshared:
    	case TOKwild:
			// const(type)  or  immutable(type)  or  shared(type)  or  wild(type)
			t = peek(t);
			if (t.value != TOK.TOKlparen)
			goto Lfalse;
			t = peek(t);
			if (!isDeclaration(t, 0, TOK.TOKrparen, &t))
			{
			goto Lfalse;
			}
			t = peek(t);
			break;

		default:
			goto Lfalse;
		}
		*pt = t;
		//printf("is\n");
		return true;

	Lfalse:
		//printf("is not\n");
		return false;
	}
	
    bool isDeclarator(Token** pt, int* haveId, TOK endtok)
	{
		// This code parallels parseDeclarator()
		Token* t = *pt;
		bool parens;

		//printf("Parser.isDeclarator()\n");
		//t.print();
		if (t.value == TOK.TOKassign)
			return false;

		while (true)
		{
			parens = false;
			switch (t.value)
			{
				case TOK.TOKmul:
				//case TOKand:
					t = peek(t);
					continue;

				case TOK.TOKlbracket:
					t = peek(t);
					if (t.value == TOK.TOKrbracket)
					{
						t = peek(t);
					}
					else if (t.value == TOKnew && peek(t).value == TOKrbracket)
					{
						t = peek(t);
						t = peek(t);
					}
					else if (isDeclaration(t, 0, TOK.TOKrbracket, &t))
					{   
						// It's an associative array declaration
						t = peek(t);
					}
					else
					{
						// [ expression ]
						// [ expression .. expression ]
						if (!isExpression(&t))
							return false;
						if (t.value == TOK.TOKslice)
						{	
							t = peek(t);
							if (!isExpression(&t))
								return false;
						}
						if (t.value != TOK.TOKrbracket)
							return false;
						t = peek(t);
					}
					continue;

				case TOK.TOKidentifier:
					if (*haveId)
						return false;
					*haveId = true;
					t = peek(t);
					break;

				case TOK.TOKlparen:
					t = peek(t);

					if (t.value == TOK.TOKrparen)
						return false;		// () is not a declarator

					/* Regard ( identifier ) as not a declarator
					 * BUG: what about ( *identifier ) in
					 *	f(*p)(x);
					 * where f is a class instance with overloaded () ?
					 * Should we just disallow C-style function pointer declarations?
					 */
					if (t.value == TOK.TOKidentifier)
					{   
						Token *t2 = peek(t);
						if (t2.value == TOK.TOKrparen)
							return false;
					}

					if (!isDeclarator(&t, haveId, TOK.TOKrparen))
						return false;
					t = peek(t);
					parens = true;
					break;

				case TOK.TOKdelegate:
				case TOK.TOKfunction:
					t = peek(t);
					if (!isParameters(&t))
						return false;
					continue;
				default:
					break;	///
			}
			break;
		}

		while (1)
		{
			switch (t.value)
			{
version (CARRAYDECL) {
				case TOK.TOKlbracket:
					parens = false;
					t = peek(t);
					if (t.value == TOK.TOKrbracket)
					{
						t = peek(t);
					}
					else if (isDeclaration(t, 0, TOKrbracket, &t))
					{   
						// It's an associative array declaration
						t = peek(t);
					}
					else
					{
						// [ expression ]
						if (!isExpression(&t))
							return false;
						if (t.value != TOK.TOKrbracket)
							return false;
						t = peek(t);
					}
					continue;
}

				case TOK.TOKlparen:
					parens = false;
					if (!isParameters(&t))
						return false;
version (DMDV2) {
					while (true)
					{
						switch (t.value)
						{
							case TOK.TOKconst:
							case TOK.TOKinvariant:
							case TOK.TOKimmutable:
							case TOK.TOKshared:
                            case TOKwild:
							case TOK.TOKpure:
							case TOK.TOKnothrow:
								t = peek(t);
								continue;
							case TOK.TOKat:
								t = peek(t);	// skip '@'
								t = peek(t);	// skip identifier
								continue;
							default:
								break;
						}
						break;
					}
}
					continue;

				// Valid tokens that follow a declaration
				case TOK.TOKrparen:
				case TOK.TOKrbracket:
				case TOK.TOKassign:
				case TOK.TOKcomma:
				case TOK.TOKsemicolon:
				case TOK.TOKlcurly:
				case TOK.TOKin:
					// The !parens is to disallow unnecessary parentheses
					if (!parens && (endtok == TOK.TOKreserved || endtok == t.value))
					{   
						*pt = t;
						return true;
					}
					return false;

				default:
					return false;
			}
		}
	}
	
    bool isParameters(Token** pt)
	{
		// This code parallels parseParameters()
		Token* t = *pt;

		//printf("isParameters()\n");
		if (t.value != TOKlparen)
			return false;

		t = peek(t);
		for (;1; t = peek(t))
		{
			 L1:
			switch (t.value)
			{
				case TOKrparen:
					break;

				case TOKdotdotdot:
					t = peek(t);
					break;

version(D1INOUT) {
	            case TOKinout:
}
				case TOKin:
				case TOKout:
				case TOKref:
				case TOKlazy:
				case TOKfinal:
	            case TOKauto:
					continue;

				case TOKconst:
				case TOKinvariant:
				case TOKimmutable:
				case TOKshared:
	            case TOKwild:
					t = peek(t);
					if (t.value == TOKlparen)
					{
						t = peek(t);
						if (!isDeclaration(t, 0, TOKrparen, &t))
						return false;
						t = peek(t);	// skip past closing ')'
						goto L2;
					}
					goto L1;

		static if (false) {
				case TOKstatic:
					continue;
				case TOKauto:
				case TOKalias:
					t = peek(t);
					if (t.value == TOKidentifier)
						t = peek(t);
					if (t.value == TOKassign)
					{   t = peek(t);
						if (!isExpression(&t))
						return false;
					}
					goto L3;
		}

				default:
				{	
					if (!isBasicType(&t))
						return false;
					L2:
					int tmp = false;
					if (t.value != TOKdotdotdot &&
						!isDeclarator(&t, &tmp, TOKreserved))
						return false;
					if (t.value == TOKassign)
					{
						t = peek(t);
						if (!isExpression(&t))
							return false;
					}
					if (t.value == TOKdotdotdot)
					{
						t = peek(t);
						break;
					}
				}
				L3:
				if (t.value == TOKcomma)
				{
					continue;
				}
				break;
			}
			break;
		}

		if (t.value != TOKrparen)
			return false;

		t = peek(t);
		*pt = t;
		return true;
	}
	
    bool isExpression(Token** pt)
	{
		// This is supposed to determine if something is an expression.
		// What it actually does is scan until a closing right bracket
		// is found.

		Token* t = *pt;
		int brnest = 0;
		int panest = 0;
		int curlynest = 0;

		for (;; t = peek(t))
		{
			switch (t.value)
			{
				case TOKlbracket:
					brnest++;
					continue;

				case TOKrbracket:
					if (--brnest >= 0)
						continue;
					break;

				case TOKlparen:
					panest++;
					continue;

				case TOKcomma:
					if (brnest || panest)
						continue;
					break;

				case TOKrparen:
					if (--panest >= 0)
						continue;
					break;

				case TOKlcurly:
					curlynest++;
					continue;

				case TOKrcurly:
					if (--curlynest >= 0)
						continue;
					return false;

				case TOKslice:
					if (brnest)
						continue;
					break;

				case TOKsemicolon:
					if (curlynest)
						continue;
					return false;

				case TOKeof:
					return false;

				default:
					continue;
			}
			break;
		}

		*pt = t;
		return true;
	}
	
    int isTemplateInstance(Token t, Token* pt)
	{
		assert(false);
	}
	
	/*******************************************
	 * Skip parens, brackets.
	 * Input:
	 *	t is on opening (
	 * Output:
	 *	*pt is set to closing token, which is ')' on success
	 * Returns:
	 *	!=0	successful
	 *	0	some parsing error
	 */
    bool skipParens(Token* t, Token** pt)
	{
		int parens = 0;

		while (1)
		{
			switch (t.value)
			{
				case TOKlparen:
					parens++;
					break;

				case TOKrparen:
					parens--;
					if (parens < 0)
						goto Lfalse;
					if (parens == 0)
						goto Ldone;
					break;

				case TOKeof:
				case TOKsemicolon:
					goto Lfalse;

				default:
					break;
			}
			t = peek(t);
		}

	  Ldone:
		if (*pt)
			*pt = t;
		return true;

	  Lfalse:
		return false;
	}

    Expression parseExpression()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		//printf("Parser.parseExpression() loc = %d\n", loc.linnum);
		e = parseAssignExp();
		while (token.value == TOK.TOKcomma)
		{
			nextToken();
			e2 = parseAssignExp();
			e = new CommaExp(loc, e, e2);
			loc = this.loc;
		}
		return e;
	}
	
    Expression parsePrimaryExp()
	{
		Expression e;
		Type t;
		Identifier id;
		TOK save;
		Loc loc = this.loc;

		//printf("parsePrimaryExp(): loc = %d\n", loc.linnum);
		switch (token.value)
		{
		case TOK.TOKidentifier:
			id = token.ident;
			nextToken();
			if (token.value == TOK.TOKnot && peekNext() != TOK.TOKis)
			{	// identifier!(template-argument-list)
			TemplateInstance tempinst;

			tempinst = new TemplateInstance(loc, id);
			nextToken();
			if (token.value == TOK.TOKlparen)
				// ident!(template_arguments)
				tempinst.tiargs = parseTemplateArgumentList();
			else
				// ident!template_argument
				tempinst.tiargs = parseTemplateArgument();
			e = new ScopeExp(loc, tempinst);
			}
			else
			e = new IdentifierExp(loc, id);
			break;

		case TOK.TOKdollar:
			if (!inBrackets)
			error("'$' is valid only inside [] of index or slice");
			e = new DollarExp(loc);
			nextToken();
			break;

		case TOK.TOKdot:
			// Signal global scope '.' operator with "" identifier
			e = new IdentifierExp(loc, Id.empty);
			break;

		case TOK.TOKthis:
			e = new ThisExp(loc);
			nextToken();
			break;

		case TOK.TOKsuper:
			e = new SuperExp(loc);
			nextToken();
			break;

		case TOK.TOKint32v:
			e = new IntegerExp(loc, token.int32value, Type.tint32);
			nextToken();
			break;

		case TOK.TOKuns32v:
			e = new IntegerExp(loc, token.uns32value, Type.tuns32);
			nextToken();
			break;

		case TOK.TOKint64v:
			e = new IntegerExp(loc, token.int64value, Type.tint64);
			nextToken();
			break;

		case TOK.TOKuns64v:
			e = new IntegerExp(loc, token.uns64value, Type.tuns64);
			nextToken();
			break;

		case TOK.TOKfloat32v:
			e = new RealExp(loc, token.float80value, Type.tfloat32);
			nextToken();
			break;

		case TOK.TOKfloat64v:
			e = new RealExp(loc, token.float80value, Type.tfloat64);
			nextToken();
			break;

		case TOK.TOKfloat80v:
			e = new RealExp(loc, token.float80value, Type.tfloat80);
			nextToken();
			break;

		case TOK.TOKimaginary32v:
			e = new RealExp(loc, token.float80value, Type.timaginary32);
			nextToken();
			break;

		case TOK.TOKimaginary64v:
			e = new RealExp(loc, token.float80value, Type.timaginary64);
			nextToken();
			break;

		case TOK.TOKimaginary80v:
			e = new RealExp(loc, token.float80value, Type.timaginary80);
			nextToken();
			break;

		case TOK.TOKnull:
			e = new NullExp(loc);
			nextToken();
			break;

version (DMDV2) {
		case TOK.TOKfile:
		{
			string s = loc.filename ? loc.filename : mod.ident.toChars();
			e = new StringExp(loc, s, 0);
			nextToken();
			break;
		}

		case TOK.TOKline:
			e = new IntegerExp(loc, loc.linnum, Type.tint32);
			nextToken();
			break;
}

		case TOK.TOKtrue:
			e = new IntegerExp(loc, 1, Type.tbool);
			nextToken();
			break;

		case TOK.TOKfalse:
			e = new IntegerExp(loc, 0, Type.tbool);
			nextToken();
			break;

		case TOK.TOKcharv:
			e = new IntegerExp(loc, token.uns32value, Type.tchar);
			nextToken();
			break;

		case TOK.TOKwcharv:
			e = new IntegerExp(loc, token.uns32value, Type.twchar);
			nextToken();
			break;

		case TOK.TOKdcharv:
			e = new IntegerExp(loc, token.uns32value, Type.tdchar);
			nextToken();
			break;

		case TOK.TOKstring:
		{  
			const(char)* s;
			uint len;
			ubyte postfix;

			// cat adjacent strings
			s = token.ustring;
			len = token.len;
			postfix = token.postfix;
			while (1)
			{
				nextToken();
				if (token.value == TOK.TOKstring)
				{   uint len1;
					uint len2;
					char* s2;

					if (token.postfix)
					{	if (token.postfix != postfix)
						error("mismatched string literal postfixes '%c' and '%c'", postfix, token.postfix);
					postfix = token.postfix;
					}

					len1 = len;
					len2 = token.len;
					len = len1 + len2;
					s2 = cast(char*)GC.malloc((len + 1) * ubyte.sizeof);
					memcpy(s2, s, len1 * ubyte.sizeof);
					memcpy(s2 + len1, token.ustring, (len2 + 1) * ubyte.sizeof);
					s = s2;
				}
				else
					break;
			}
			e = new StringExp(loc, assumeUnique(s[0..len]), postfix);
			break;
		}

		case TOK.TOKvoid:	 t = Type.tvoid;  goto LabelX;
		case TOK.TOKint8:	 t = Type.tint8;  goto LabelX;
		case TOK.TOKuns8:	 t = Type.tuns8;  goto LabelX;
		case TOK.TOKint16:	 t = Type.tint16; goto LabelX;
		case TOK.TOKuns16:	 t = Type.tuns16; goto LabelX;
		case TOK.TOKint32:	 t = Type.tint32; goto LabelX;
		case TOK.TOKuns32:	 t = Type.tuns32; goto LabelX;
		case TOK.TOKint64:	 t = Type.tint64; goto LabelX;
		case TOK.TOKuns64:	 t = Type.tuns64; goto LabelX;
		case TOK.TOKfloat32: t = Type.tfloat32; goto LabelX;
		case TOK.TOKfloat64: t = Type.tfloat64; goto LabelX;
		case TOK.TOKfloat80: t = Type.tfloat80; goto LabelX;
		case TOK.TOKimaginary32: t = Type.timaginary32; goto LabelX;
		case TOK.TOKimaginary64: t = Type.timaginary64; goto LabelX;
		case TOK.TOKimaginary80: t = Type.timaginary80; goto LabelX;
		case TOK.TOKcomplex32: t = Type.tcomplex32; goto LabelX;
		case TOK.TOKcomplex64: t = Type.tcomplex64; goto LabelX;
		case TOK.TOKcomplex80: t = Type.tcomplex80; goto LabelX;
		case TOK.TOKbit:	 t = Type.tbit;     goto LabelX;
		case TOK.TOKbool:	 t = Type.tbool;    goto LabelX;
		case TOK.TOKchar:	 t = Type.tchar;    goto LabelX;
		case TOK.TOKwchar:	 t = Type.twchar; goto LabelX;
		case TOK.TOKdchar:	 t = Type.tdchar; goto LabelX;
		LabelX:
			nextToken();
		L1:
			check(TOK.TOKdot, t.toChars());
			if (token.value != TOK.TOKidentifier)
			{   error("found '%s' when expecting identifier following '%s.'", token.toChars(), t.toChars());
			goto Lerr;
			}
			e = typeDotIdExp(loc, t, token.ident);
			nextToken();
			break;

		case TOK.TOKtypeof:
		{
			t = parseTypeof();
			e = new TypeExp(loc, t);
			break;
		}

		case TOK.TOKtypeid:
		{
			nextToken();
			check(TOK.TOKlparen, "typeid");
	        Object o;
	        if (isDeclaration(&token, 0, TOKreserved, null))
	        {	// argument is a type
		        o = parseType();
	        }
	        else
	        {	// argument is an expression
		        o = parseAssignExp();
	        }
			check(TOK.TOKrparen);
		    e = new TypeidExp(loc, o);
			break;
		}

version (DMDV2) {
		case TOK.TOKtraits:
		{   /* __traits(identifier, args...)
			 */
			Identifier ident;
			Objects args = null;

			nextToken();
			check(TOK.TOKlparen);
			if (token.value != TOK.TOKidentifier)
			{   error("__traits(identifier, args...) expected");
			goto Lerr;
			}
			ident = token.ident;
			nextToken();
			if (token.value == TOK.TOKcomma)
			args = parseTemplateArgumentList2();	// __traits(identifier, args...)
			else
			check(TOK.TOKrparen);		// __traits(identifier)

			e = new TraitsExp(loc, ident, args);
			break;
		}
}

		case TOK.TOKis:
		{   Type targ;
			Identifier ident = null;
			Type tspec = null;
			TOK tok = TOK.TOKreserved;
			TOK tok2 = TOK.TOKreserved;
			TemplateParameters tpl = null;
			Loc loc2 = this.loc;

			nextToken();
			if (token.value == TOK.TOKlparen)
			{
				nextToken();
				targ = parseType(&ident);
				if (token.value == TOK.TOKcolon || token.value == TOK.TOKequal)
				{
					tok = token.value;
					nextToken();
					if (tok == TOK.TOKequal &&
					(token.value == TOK.TOKtypedef ||
					 token.value == TOK.TOKstruct ||
					 token.value == TOK.TOKunion ||
					 token.value == TOK.TOKclass ||
					 token.value == TOK.TOKsuper ||
					 token.value == TOK.TOKenum ||
					 token.value == TOK.TOKinterface ||
	///version (DMDV2) {
					 token.value == TOK.TOKconst && peek(&token).value == TOK.TOKrparen ||
					 token.value == TOK.TOKinvariant && peek(&token).value == TOK.TOKrparen ||
					 token.value == TOK.TOKimmutable && peek(&token).value == TOK.TOKrparen ||
					 token.value == TOK.TOKshared && peek(&token).value == TOK.TOKrparen ||
                     token.value == TOKwild && peek(&token).value == TOKrparen ||
	///}
					 token.value == TOK.TOKfunction ||
					 token.value == TOK.TOKdelegate ||
					 token.value == TOK.TOKreturn))
					{
					tok2 = token.value;
					nextToken();
					}
					else
					{
					tspec = parseType();
					}
				}
				if (ident && tspec)
				{
					if (token.value == TOK.TOKcomma)
					tpl = parseTemplateParameterList(1);
					else
					{	tpl = new TemplateParameters();
					check(TOK.TOKrparen);
					}
					TemplateParameter tp = new TemplateTypeParameter(loc2, ident, null, null);
					tpl.insert(0, tp);
				}
				else
					check(TOK.TOKrparen);
			}
			else
			{   error("(type identifier : specialization) expected following is");
			goto Lerr;
			}
			e = new IsExp(loc2, targ, ident, tok, tspec, tok2, tpl);
			break;
		}

		case TOK.TOKassert:
		{   
			Expression msg = null;

			nextToken();
			check(TOK.TOKlparen, "assert");
			e = parseAssignExp();
			if (token.value == TOK.TOKcomma)
			{	nextToken();
			msg = parseAssignExp();
			}
			check(TOK.TOKrparen);
			e = new AssertExp(loc, e, msg);
			break;
		}

		case TOK.TOKmixin:
		{
			nextToken();
			check(TOK.TOKlparen, "mixin");
			e = parseAssignExp();
			check(TOK.TOKrparen);
			e = new CompileExp(loc, e);
			break;
		}

		case TOK.TOKimport:
		{
			nextToken();
			check(TOK.TOKlparen, "import");
			e = parseAssignExp();
			check(TOK.TOKrparen);
			e = new FileExp(loc, e);
			break;
		}

		case TOK.TOKlparen:
			if (peekPastParen(&token).value == TOK.TOKlcurly)
			{	// (arguments) { statements... }
			save = TOK.TOKdelegate;
			goto case_delegate;
			}
			// ( expression )
			nextToken();
			e = parseExpression();
			check(loc, TOK.TOKrparen);
			break;

		case TOK.TOKlbracket:
		{   /* Parse array literals and associative array literals:
			 *	[ value, value, value ... ]
			 *	[ key:value, key:value, key:value ... ]
			 */
			Expressions values = new Expressions();
			Expressions keys = null;

			nextToken();
			if (token.value != TOK.TOKrbracket)
			{
			while (token.value != TOK.TOKeof)
			{
				Expression e2 = parseAssignExp();
				if (token.value == TOK.TOKcolon && (keys || values.dim == 0))
				{	
					nextToken();
					if (!keys)
						keys = new Expressions();
					keys.push(e2);
					e2 = parseAssignExp();
				}
				else if (keys)
				{	
					error("'key:value' expected for associative array literal");
					delete keys;
					keys = null;
				}
				values.push(e2);
				if (token.value == TOK.TOKrbracket)
					break;
				check(TOK.TOKcomma);
			}
			}
			check(TOK.TOKrbracket);

			if (keys)
				e = new AssocArrayLiteralExp(loc, keys, values);
			else
				e = new ArrayLiteralExp(loc, values);
			break;
		}

		case TOK.TOKlcurly:
			// { statements... }
			save = TOK.TOKdelegate;
			goto case_delegate;

		case TOK.TOKfunction:
		case TOK.TOKdelegate:
			save = token.value;
			nextToken();
		case_delegate:
		{
			/* function type(parameters) { body } pure nothrow
			 * delegate type(parameters) { body } pure nothrow
			 * (parameters) { body }
			 * { body }
			 */
			Parameters arguments;
			int varargs;
			FuncLiteralDeclaration fd;
			Type tt;
			bool isnothrow = false;
			bool ispure = false;
	        bool isproperty = false;
	        TRUST trust = TRUSTdefault;
            
			if (token.value == TOK.TOKlcurly)
			{
			tt = null;
			varargs = 0;
			arguments = new Parameters();
			}
			else
			{
			if (token.value == TOK.TOKlparen)
				tt = null;
			else
			{
				tt = parseBasicType();
				tt = parseBasicType2(tt);	// function return type
			}
			arguments = parseParameters(&varargs);
			while (1)
			{
				if (token.value == TOK.TOKpure)
				ispure = true;
				else if (token.value == TOK.TOKnothrow)
				isnothrow = true;
		        else if (token.value == TOKat)
		        {
                    StorageClass stc = parseAttribute();
			        switch (cast(uint)(stc >> 32))
			        {
                        case STCproperty >> 32:
				            isproperty = true;
				            break;
			            case STCsafe >> 32:
				            trust = TRUSTsafe;
				            break;
			            case STCsystem >> 32:
				            trust = TRUSTsystem;
				            break;
			            case STCtrusted >> 32:
				            trust = TRUSTtrusted;
				            break;
			            case 0:
				            break;
			            default:
    				        assert(0);
			        }
	            }
				else
	    			break;
				nextToken();
			}
			}

			TypeFunction tf = new TypeFunction(arguments, tt, varargs, linkage);
			tf.ispure = ispure;
			tf.isnothrow = isnothrow;
	        tf.isproperty = isproperty;
	        tf.trust = trust;
			fd = new FuncLiteralDeclaration(loc, Loc(0), tf, save, null);
			parseContracts(fd);
			e = new FuncExp(loc, fd);
			break;
		}

		default:
			error("expression expected, not '%s'", token.toChars());
		Lerr:
			// Anything for e, as long as it's not null
			e = new IntegerExp(loc, 0, Type.tint32);
			nextToken();
			break;
		}
		return e;
	}
	
    Expression parseUnaryExp()
	{
		Expression e;
		Loc loc = this.loc;

		switch (token.value)
		{
		case TOK.TOKand:
			nextToken();
			e = parseUnaryExp();
			e = new AddrExp(loc, e);
			break;

		case TOK.TOKplusplus:
			nextToken();
			e = parseUnaryExp();
			e = new AddAssignExp(loc, e, new IntegerExp(loc, 1, Type.tint32));
			break;

		case TOK.TOKminusminus:
			nextToken();
			e = parseUnaryExp();
			e = new MinAssignExp(loc, e, new IntegerExp(loc, 1, Type.tint32));
			break;

		case TOK.TOKmul:
			nextToken();
			e = parseUnaryExp();
			e = new PtrExp(loc, e);
			break;

		case TOK.TOKmin:
			nextToken();
			e = parseUnaryExp();
			e = new NegExp(loc, e);
			break;

		case TOK.TOKadd:
			nextToken();
			e = parseUnaryExp();
			e = new UAddExp(loc, e);
			break;

		case TOK.TOKnot:
			nextToken();
			e = parseUnaryExp();
			e = new NotExp(loc, e);
			break;

		case TOK.TOKtilde:
			nextToken();
			e = parseUnaryExp();
			e = new ComExp(loc, e);
			break;

		case TOK.TOKdelete:
			nextToken();
			e = parseUnaryExp();
			e = new DeleteExp(loc, e);
			break;

		case TOK.TOKnew:
			e = parseNewExp(null);
			break;

		case TOK.TOKcast:				// cast(type) expression
		{
			nextToken();
			check(TOK.TOKlparen);
			/* Look for cast(), cast(const), cast(immutable),
			 * cast(shared), cast(shared const), cast(wild), cast(shared wild)
			 */
			MOD m;
			if (token.value == TOK.TOKrparen)
			{
			m = MOD.MODundefined;
			goto Lmod1;
			}
			else if (token.value == TOK.TOKconst && peekNext() == TOK.TOKrparen)
			{
			m = MOD.MODconst;
			goto Lmod2;
			}
			else if ((token.value == TOK.TOKimmutable || token.value == TOK.TOKinvariant) && peekNext() == TOK.TOKrparen)
			{
			m = MOD.MODimmutable;
			goto Lmod2;
			}
			else if (token.value == TOK.TOKshared && peekNext() == TOK.TOKrparen)
			{
			m = MOD.MODshared;
			goto Lmod2;
			}
	        else if (token.value == TOKwild && peekNext() == TOK.TOKrparen)
	        {
		    m = MODwild;
		    goto Lmod2;
	        }
	        else if (token.value == TOKwild && peekNext() == TOK.TOKshared && peekNext2() == TOK.TOKrparen ||
		         token.value == TOK.TOKshared && peekNext() == TOKwild && peekNext2() == TOK.TOKrparen)
	        {
		    m = MOD.MODshared | MOD.MODwild;
		    goto Lmod3;
	        }
			else if (token.value == TOK.TOKconst && peekNext() == TOK.TOKshared && peekNext2() == TOK.TOKrparen ||
				 token.value == TOK.TOKshared && peekNext() == TOK.TOKconst && peekNext2() == TOK.TOKrparen)
			{
			m = MOD.MODshared | MOD.MODconst;
	          Lmod3:
			nextToken();
			  Lmod2:
			nextToken();
			  Lmod1:
			nextToken();
			e = parseUnaryExp();
			e = new CastExp(loc, e, m);
			}
			else
			{
			Type t = parseType();		// ( type )
			check(TOK.TOKrparen);
			e = parseUnaryExp();
			e = new CastExp(loc, e, t);
			}
			break;
		}

		case TOK.TOKlparen:
		{   Token *tk;

			tk = peek(&token);
version (CCASTSYNTAX) {
			// If cast
			if (isDeclaration(tk, 0, TOK.TOKrparen, &tk))
			{
				tk = peek(tk);		// skip over right parenthesis
				switch (tk.value)
				{
					case TOK.TOKnot:
						tk = peek(tk);
						if (tk.value == TOK.TOKis)	// !is
							break;
					case TOK.TOKdot:
					case TOK.TOKplusplus:
					case TOK.TOKminusminus:
					case TOK.TOKdelete:
					case TOK.TOKnew:
					case TOK.TOKlparen:
					case TOK.TOKidentifier:
					case TOK.TOKthis:
					case TOK.TOKsuper:
					case TOK.TOKint32v:
					case TOK.TOKuns32v:
					case TOK.TOKint64v:
					case TOK.TOKuns64v:
					case TOK.TOKfloat32v:
					case TOK.TOKfloat64v:
					case TOK.TOKfloat80v:
					case TOK.TOKimaginary32v:
					case TOK.TOKimaginary64v:
					case TOK.TOKimaginary80v:
					case TOK.TOKnull:
					case TOK.TOKtrue:
					case TOK.TOKfalse:
					case TOK.TOKcharv:
					case TOK.TOKwcharv:
					case TOK.TOKdcharv:
					case TOK.TOKstring:
static if (false) {
					case TOK.TOKtilde:
					case TOK.TOKand:
					case TOK.TOKmul:
					case TOK.TOKmin:
					case TOK.TOKadd:
}
					case TOK.TOKfunction:
					case TOK.TOKdelegate:
					case TOK.TOKtypeof:
version (DMDV2) {
					case TOK.TOKfile:
					case TOK.TOKline:
}
					case TOK.TOKwchar: case TOK.TOKdchar:
					case TOK.TOKbit: case TOK.TOKbool: case TOK.TOKchar:
					case TOK.TOKint8: case TOK.TOKuns8:
					case TOK.TOKint16: case TOK.TOKuns16:
					case TOK.TOKint32: case TOK.TOKuns32:
					case TOK.TOKint64: case TOK.TOKuns64:
					case TOK.TOKfloat32: case TOK.TOKfloat64: case TOK.TOKfloat80:
					case TOK.TOKimaginary32: case TOK.TOKimaginary64: case TOK.TOKimaginary80:
					case TOK.TOKcomplex32: case TOK.TOKcomplex64: case TOK.TOKcomplex80:
					case TOK.TOKvoid:		// (type)int.size
					{	
						// (type) una_exp
						nextToken();
						Type t = parseType();
						check(TOK.TOKrparen);

						// if .identifier
						if (token.value == TOK.TOKdot)
						{
							nextToken();
							if (token.value != TOK.TOKidentifier)
							{   
								error("Identifier expected following (type).");
								return null;
							}
							e = typeDotIdExp(loc, t, token.ident);
							nextToken();
							e = parsePostExp(e);
						}
						else
						{
							e = parseUnaryExp();
							e = new CastExp(loc, e, t);
							error("C style cast illegal, use %s", e.toChars());
						}
						return e;
					}
					
					default:
						break;	///
				}
			}
}
			e = parsePrimaryExp();
			e = parsePostExp(e);
			break;
		}
		default:
			e = parsePrimaryExp();
			e = parsePostExp(e);
			break;
		}
		assert(e);

        // ^^ is right associative and has higher precedence than the unary operators
        while (token.value == TOK.TOKpow)
        {
	        nextToken();
	        Expression e2 = parseUnaryExp();
	        e = new PowExp(loc, e, e2);
        }

		return e;
	}
	
    Expression parsePostExp(Expression e)
	{
		Loc loc;

		while (1)
		{
		loc = this.loc;
		switch (token.value)
		{
			case TOK.TOKdot:
			nextToken();
			if (token.value == TOK.TOKidentifier)
			{   Identifier id = token.ident;

				nextToken();
				if (token.value == TOK.TOKnot && peekNext() != TOK.TOKis)
				{   // identifier!(template-argument-list)
				TemplateInstance tempinst = new TemplateInstance(loc, id);
			    Objects tiargs;
				nextToken();
				if (token.value == TOK.TOKlparen)
					// ident!(template_arguments)
					tiargs = parseTemplateArgumentList();
				else
					// ident!template_argument
					tiargs = parseTemplateArgument();
				e = new DotTemplateInstanceExp(loc, e, id, tiargs);
				}
				else
				e = new DotIdExp(loc, e, id);
				continue;
			}
			else if (token.value == TOK.TOKnew)
			{
				e = parseNewExp(e);
				continue;
			}
			else
				error("identifier expected following '.', not '%s'", token.toChars());
			break;

			case TOK.TOKplusplus:
			e = new PostExp(TOK.TOKplusplus, loc, e);
			break;

			case TOK.TOKminusminus:
			e = new PostExp(TOK.TOKminusminus, loc, e);
			break;

			case TOK.TOKlparen:
			e = new CallExp(loc, e, parseArguments());
			continue;

			case TOK.TOKlbracket:
			{	// array dereferences:
			//	array[index]
			//	array[]
			//	array[lwr .. upr]
			Expression index;
			Expression upr;

			inBrackets++;
			nextToken();
			if (token.value == TOK.TOKrbracket)
			{   // array[]
				e = new SliceExp(loc, e, null, null);
				nextToken();
			}
			else
			{
				index = parseAssignExp();
				if (token.value == TOK.TOKslice)
				{	// array[lwr .. upr]
				nextToken();
				upr = parseAssignExp();
				e = new SliceExp(loc, e, index, upr);
				}
				else
				{	// array[index, i2, i3, i4, ...]
				auto arguments = new Expressions();
				arguments.push(index);
				if (token.value == TOK.TOKcomma)
				{
					nextToken();
					while (1)
					{   Expression arg;

					arg = parseAssignExp();
					arguments.push(arg);
					if (token.value == TOK.TOKrbracket)
						break;
					check(TOK.TOKcomma);
					}
				}
				e = new ArrayExp(loc, e, arguments);
				}
				check(TOK.TOKrbracket);
				inBrackets--;
			}
			continue;
			}

			default:
			return e;
		}
		nextToken();
		}
		
		assert(false);
	}
	
    Expression parseMulExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseUnaryExp();
		while (1)
		{
			switch (token.value)
			{
				case TOK.TOKmul: nextToken(); e2 = parseUnaryExp(); e = new MulExp(loc,e,e2); continue;
	            case TOK.TOKdiv: nextToken(); e2 = parseUnaryExp(); e = new DivExp(loc,e,e2); continue;
	            case TOK.TOKmod: nextToken(); e2 = parseUnaryExp(); e = new ModExp(loc,e,e2); continue;

				default:
				break;
			}
			break;
		}
		return e;
	}
	
    Expression parseShiftExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseAddExp();
		while (1)
		{
			switch (token.value)
			{
				case TOK.TOKshl:  nextToken(); e2 = parseAddExp(); e = new ShlExp(loc,e,e2);  continue;
				case TOK.TOKshr:  nextToken(); e2 = parseAddExp(); e = new ShrExp(loc,e,e2);  continue;
				case TOK.TOKushr: nextToken(); e2 = parseAddExp(); e = new UshrExp(loc,e,e2); continue;

				default:
				break;
			}
			break;
		}
		return e;
	}
	
    Expression parseAddExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseMulExp();
		while (1)
		{
			switch (token.value)
			{
				case TOK.TOKadd:    nextToken(); e2 = parseMulExp(); e = new AddExp(loc,e,e2); continue;
				case TOK.TOKmin:    nextToken(); e2 = parseMulExp(); e = new MinExp(loc,e,e2); continue;
				case TOK.TOKtilde:  nextToken(); e2 = parseMulExp(); e = new CatExp(loc,e,e2); continue;

				default:
				break;
			}
			break;
		}
		return e;
	}
	
    Expression parseRelExp()
	{
		assert(false);
	}
	
    Expression parseEqualExp()
	{
		assert(false);
	}
	
    Expression parseCmpExp()
	{
		Expression e;
		Expression e2;
		Token* t;
		Loc loc = this.loc;

		e = parseShiftExp();
		TOK op = token.value;

		switch (op)
		{
		case TOK.TOKequal:
		case TOK.TOKnotequal:
			nextToken();
			e2 = parseShiftExp();
			e = new EqualExp(op, loc, e, e2);
			break;

		case TOK.TOKis:
			op = TOK.TOKidentity;
			goto L1;

		case TOK.TOKnot:
			// Attempt to identify '!is'
			t = peek(&token);
			if (t.value != TOK.TOKis)
			break;
			nextToken();
			op = TOK.TOKnotidentity;
			goto L1;

		L1:
			nextToken();
			e2 = parseShiftExp();
			e = new IdentityExp(op, loc, e, e2);
			break;

		case TOK.TOKlt:
		case TOK.TOKle:
		case TOK.TOKgt:
		case TOK.TOKge:
		case TOK.TOKunord:
		case TOK.TOKlg:
		case TOK.TOKleg:
		case TOK.TOKule:
		case TOK.TOKul:
		case TOK.TOKuge:
		case TOK.TOKug:
		case TOK.TOKue:
			nextToken();
			e2 = parseShiftExp();
			e = new CmpExp(op, loc, e, e2);
			break;

		case TOK.TOKin:
			nextToken();
			e2 = parseShiftExp();
			e = new InExp(loc, e, e2);
			break;

		default:
			break;
		}
		return e;
	}
	
    Expression parseAndExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		if (global.params.Dversion == 1)
		{
			e = parseEqualExp();
			while (token.value == TOK.TOKand)
			{
				nextToken();
				e2 = parseEqualExp();
				e = new AndExp(loc,e,e2);
				loc = this.loc;
			}
		}
		else
		{
			e = parseCmpExp();
			while (token.value == TOK.TOKand)
			{
				nextToken();
				e2 = parseCmpExp();
				e = new AndExp(loc,e,e2);
				loc = this.loc;
			}
		}
		return e;
	}
	
    Expression parseXorExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseAndExp();
		while (token.value == TOK.TOKxor)
		{
			nextToken();
			e2 = parseAndExp();
			e = new XorExp(loc, e, e2);
		}

		return e;
	}

    Expression parseOrExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseXorExp();
		while (token.value == TOK.TOKor)
		{
			nextToken();
			e2 = parseXorExp();
			e = new OrExp(loc, e, e2);
		}
		return e;
	}
	
    Expression parseAndAndExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseOrExp();
		while (token.value == TOK.TOKandand)
		{
			nextToken();
			e2 = parseOrExp();
			e = new AndAndExp(loc, e, e2);
		}
		return e;
	}
	
    Expression parseOrOrExp()
	{
		Expression e;
		Expression e2;
		Loc loc = this.loc;

		e = parseAndAndExp();
		while (token.value == TOK.TOKoror)
		{
			nextToken();
			e2 = parseAndAndExp();
			e = new OrOrExp(loc, e, e2);
		}

		return e;
	}
	
    Expression parseCondExp()
	{
		Expression e;
		Expression e1;
		Expression e2;
		Loc loc = this.loc;

		e = parseOrOrExp();
		if (token.value == TOK.TOKquestion)
		{
			nextToken();
			e1 = parseExpression();
			check(TOK.TOKcolon);
			e2 = parseCondExp();
			e = new CondExp(loc, e, e1, e2);
		}
		return e;
	}
	
    Expression parseAssignExp()
	{
		Expression e;
		Expression e2;
		Loc loc;

		e = parseCondExp();
		while (1)
		{
			loc = this.loc;
			switch (token.value)
			{
				case TOK.TOKassign:  nextToken(); e2 = parseAssignExp(); e = new AssignExp(loc,e,e2); continue;
				case TOK.TOKaddass:  nextToken(); e2 = parseAssignExp(); e = new AddAssignExp(loc,e,e2); continue;
				case TOK.TOKminass:  nextToken(); e2 = parseAssignExp(); e = new MinAssignExp(loc,e,e2); continue;
				case TOK.TOKmulass:  nextToken(); e2 = parseAssignExp(); e = new MulAssignExp(loc,e,e2); continue;
				case TOK.TOKdivass:  nextToken(); e2 = parseAssignExp(); e = new DivAssignExp(loc,e,e2); continue;
				case TOK.TOKmodass:  nextToken(); e2 = parseAssignExp(); e = new ModAssignExp(loc,e,e2); continue;
				case TOK.TOKpowass:  nextToken(); e2 = parseAssignExp(); e = new PowAssignExp(loc,e,e2); continue;
				case TOK.TOKandass:  nextToken(); e2 = parseAssignExp(); e = new AndAssignExp(loc,e,e2); continue;
				case TOK.TOKorass:   nextToken(); e2 = parseAssignExp(); e = new OrAssignExp(loc,e,e2); continue;
				case TOK.TOKxorass:  nextToken(); e2 = parseAssignExp(); e = new XorAssignExp(loc,e,e2); continue;
				case TOK.TOKshlass:  nextToken(); e2 = parseAssignExp(); e = new ShlAssignExp(loc,e,e2); continue;
				case TOK.TOKshrass:  nextToken(); e2 = parseAssignExp(); e = new ShrAssignExp(loc,e,e2); continue;
				case TOK.TOKushrass: nextToken(); e2 = parseAssignExp(); e = new UshrAssignExp(loc,e,e2); continue;
				case TOK.TOKcatass:  nextToken(); e2 = parseAssignExp(); e = new CatAssignExp(loc,e,e2); continue;
				
				default:
					break;
			}
			break;
		}

		return e;
	}
	
	/*************************
	 * Collect argument list.
	 * Assume current token is ',', '(' or '['.
	 */
    Expressions parseArguments()
	{
		// function call
		Expressions arguments = new Expressions();
		Expression arg;
		TOK endtok;
		
		if (token.value == TOK.TOKlbracket)
			endtok = TOK.TOKrbracket;
		else
			endtok = TOK.TOKrparen;

		{
			nextToken();
			if (token.value != endtok)
			{
				while (1)
				{
					arg = parseAssignExp();
					arguments.push(arg);
					if (token.value == endtok)
						break;
					check(TOK.TOKcomma);
				}
			}
			check(endtok);
		}
		return arguments;
	}

    Expression parseNewExp(Expression thisexp)
	{
		Type t;
		Expressions newargs;
		Expressions arguments = null;
		Expression e;
		Loc loc = this.loc;

		nextToken();
		newargs = null;
		if (token.value == TOKlparen)
		{
			newargs = parseArguments();
		}

		// An anonymous nested class starts with "class"
		if (token.value == TOKclass)
		{
			nextToken();
			if (token.value == TOKlparen)
				arguments = parseArguments();

			BaseClasses baseclasses = null;
			if (token.value != TOKlcurly)
				baseclasses = parseBaseClasses();

			Identifier id = null;
			ClassDeclaration cd = new ClassDeclaration(loc, id, baseclasses);

			if (token.value != TOKlcurly)
			{   
				error("{ members } expected for anonymous class");
				cd.members = null;
			}
			else
			{
				nextToken();
				auto decl = parseDeclDefs(0);
				if (token.value != TOKrcurly)
					error("class member expected");
				nextToken();
				cd.members = decl;
			}

			e = new NewAnonClassExp(loc, thisexp, newargs, cd, arguments);

			return e;
		}

		t = parseBasicType();
		t = parseBasicType2(t);
		if (t.ty == Taarray)
		{	
			TypeAArray taa = cast(TypeAArray)t;
			Type index = taa.index;

			Expression e2 = index.toExpression();
			if (e2)
			{   
				arguments = new Expressions();
				arguments.push(e2);
				t = new TypeDArray(taa.next);
			}
			else
			{
				error("need size of rightmost array, not type %s", index.toChars());
				return new NullExp(loc);
			}
		}
		else if (t.ty == Tsarray)
		{
			TypeSArray tsa = cast(TypeSArray)t;
			Expression ee = tsa.dim;

			arguments = new Expressions();
			arguments.push(ee);
			t = new TypeDArray(tsa.next);
		}
		else if (token.value == TOKlparen)
		{
			arguments = parseArguments();
		}

		e = new NewExp(loc, thisexp, newargs, t, arguments);
		return e;
	}
	
    void addComment(Dsymbol s, const(char)[] blockComment)
	{
		s.addComment(combineComments(blockComment, token.lineComment));
		token.lineComment = null;
	}
}
