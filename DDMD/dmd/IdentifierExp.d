module dmd.IdentifierExp;

import dmd.common;
import dmd.Expression;
import dmd.Declaration;
import dmd.TY;
import dmd.TypePointer;
import dmd.FuncDeclaration;
import dmd.TemplateInstance;
import dmd.Id;
import dmd.VarDeclaration;
import dmd.TemplateDeclaration;
import dmd.TemplateExp;
import dmd.DsymbolExp;
import dmd.Identifier;
import dmd.OutBuffer;
import dmd.Loc;
import dmd.Scope;
import dmd.Dsymbol;
import dmd.WithScopeSymbol;
import dmd.VarExp;
import dmd.DotIdExp;
import dmd.Type;
import dmd.HdrGenState;
import dmd.TOK;

import dmd.DDMDExtensions;

class IdentifierExp : Expression
{
	mixin insertMemberExtension!(typeof(this));

	Identifier ident;

	Declaration var;

	this(Loc loc, Identifier ident)
	{
		register();
		super(loc, TOK.TOKidentifier, IdentifierExp.sizeof);
		this.ident = ident;
	}

	this(Loc loc, Declaration var)
	{
		register();
		assert(false);
		super(loc, TOK.init, 0);
	}

	override Expression semantic(Scope sc)
	{
		Dsymbol s;
		Dsymbol scopesym;

version (LOGSEMANTIC) {
		printf("IdentifierExp.semantic('%s')\n", ident.toChars());
}
		s = sc.search(loc, ident, &scopesym);
		if (s)
		{	
			Expression e;
			WithScopeSymbol withsym;

			/* See if the symbol was a member of an enclosing 'with'
			 */
			withsym = scopesym.isWithScopeSymbol();
			if (withsym)
			{
version (DMDV2) {
				/* Disallow shadowing
				 */
				// First find the scope of the with
				Scope scwith = sc;
				while (scwith.scopesym !is scopesym)
				{	
					scwith = scwith.enclosing;
					assert(scwith);
				}

				// Look at enclosing scopes for symbols with the same name,
				// in the same function
				for (Scope scx = scwith; scx && scx.func == scwith.func; scx = scx.enclosing)
				{   
					Dsymbol s2;

					if (scx.scopesym && scx.scopesym.symtab && (s2 = scx.scopesym.symtab.lookup(s.ident)) !is null && s !is s2)
					{
						error("with symbol %s is shadowing local symbol %s", s.toPrettyChars(), s2.toPrettyChars());
					}
				}
}
				s = s.toAlias();

				// Same as wthis.ident
				if (s.needThis() || s.isTemplateDeclaration())
				{
					e = new VarExp(loc, withsym.withstate.wthis);
					e = new DotIdExp(loc, e, ident);
				}
				else
				{	
					Type t = withsym.withstate.wthis.type;
					if (t.ty == TY.Tpointer)
						t = (cast(TypePointer)t).next;
					e = typeDotIdExp(loc, t, ident);
				}
			}
			else
			{
				/* If f is really a function template,
				 * then replace f with the function template declaration.
				 */
				FuncDeclaration f = s.isFuncDeclaration();
				if (f && f.parent)
				{   
					TemplateInstance ti = f.parent.isTemplateInstance();

					if (ti && !ti.isTemplateMixin() &&
						(ti.name == f.ident || ti.toAlias().ident == f.ident) &&
						ti.tempdecl && ti.tempdecl.onemember)
					{
						TemplateDeclaration tempdecl = ti.tempdecl;

						if (tempdecl.overroot)         // if not start of overloaded list of TemplateDeclaration's
							tempdecl = tempdecl.overroot; // then get the start

						e = new TemplateExp(loc, tempdecl);
						e = e.semantic(sc);

						return e;
					}
				}

				// Haven't done overload resolution yet, so pass 1
				e = new DsymbolExp(loc, s, 1);
			}

			return e.semantic(sc);
		}
		
		if (ident == Id.ctfe)
		{  
			// Create the magic __ctfe bool variable
		   VarDeclaration vd = new VarDeclaration(loc, Type.tbool, Id.ctfe, null);
		   Expression e = new VarExp(loc, vd);
		   e = e.semantic(sc);
		   return e;
		}

		error("undefined identifier %s", ident.toChars());
		type = Type.terror;
		return this;
	}

	override string toChars()
	{
		return ident.toChars();
	}

	override void dump(int indent)
	{
		assert(false);
	}

	override void toCBuffer(OutBuffer buf, HdrGenState* hgs)
	{
		if (hgs.hdrgen)
			buf.writestring(ident.toHChars2());
		else
			buf.writestring(ident.toChars());
	}

	override bool isLvalue()
	{
		return true;
	}

	override Expression toLvalue(Scope sc, Expression e)
	{
static if (false) {
		tym = tybasic(e1.ET.Tty);
		if (!(tyscalar(tym) || tym == TYM.TYstruct || tym == TYM.TYarray && e.Eoper == TOK.TOKaddr))
			synerr(EM_lvalue);	// lvalue expected
}
		return this;
	}
}

